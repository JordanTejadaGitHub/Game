extends Node2D

# Combo callouts (screens_ui.md "Combat feedback: seeing what works"): a short word pops over the
# nightmare when a synergy fires, in the triggering Warden's colour, so players see why Wardens
# belong together. Reads DamageLog's combo tags. Throttled: a few at a time, each word on a
# cooldown, one per nightmare. Also asks the nightmare to flash the status the combo used.

const MAX_ALIVE := 3
const TAG_COOLDOWN := 0.7  # Seconds before the same word can pop again
const REDUCED_MAX_ALIVE := 1  # Effects quality Reduced
const REDUCED_COOLDOWN := 2.0
const LIFE := 0.9
# Combo tag -> the word shown ("" = no word, only the status flash).
const WORDS := {&"conducted": "Conducted", &"asleep": "Asleep",  # No exclamation marks (wording review 2026-10-13)
	&"crit": "Crit", &"weak": "Weak", &"marked": "", &"fog": "", &"static": ""}
# Combo tag -> the status it used (flashes on the nightmare).
const USES_STATUS := {&"conducted": &"damp", &"asleep": &"drowsy",
	&"marked": &"marked", &"fog": &"spored", &"static": &"static"}
const PRIORITY: Array[StringName] = [&"asleep", &"conducted", &"crit"]
# Matchups (user 2026-10-07): every hit from a family the nightmare is weak to pops "Weak!", every hit
# from one it resists "Strong!", but never stacked: a new hit re-pops the nightmare's word in place.
# Combo words above win and replace it. Ids match CodexData.CALLOUT_ENTRIES (&"resisted" = "Strong!").
const MATCHUP_WORDS := {&"weak": "Weak", &"resisted": "Resisted"}
const MAX_MATCHUPS := 8  # Matchup words on screen at once (their own budget, so combos still show)
const REDUCED_MAX_MATCHUPS := 3
const WEAK_COLOUR := Palette.NEWLEAF
const STRONG_COLOUR := Palette.WRAITHLIGHT  # cold violet: Mist was the same value as the pale path and hard to see (user 2026-10-07)

var _cooldowns := {}  # tag -> seconds left
var _alive: Array = []  # [age, text, colour, enemy (weak ref target), offset, matchup tag or &""]
var _drawn := false  # Words were on screen last frame

func _ready() -> void:
	z_index = 21  # Over the damage numbers
	add_to_group(&"combat_callouts")  # SoundHooks finds it for card_called
	_connect.call_deferred()  # DamageLog readies later in the scene
	_hook_towers.call_deferred()

func _connect() -> void:
	var log := DamageLog.instance
	if log != null:
		log.damage_dealt.connect(_on_damage)

# Trigger cards (screens_ui.md "Dream" ecbea61a): a taken card whose own damage just landed (its rule's tag, as
# DreamState credits it) pops its name over the nightmare, no numbers, at most every CARD_COOLDOWN per card.
const CARD_COOLDOWN := 6.0
signal card_called(card_id: String, at: Vector2)  # A trigger card's name popped (for Sound: its trigger sound)
var _card_tags := {}  # Damage tag -> card id (DreamState._credit_rule_map), refreshed once a second
var _card_tags_age := INF

func _card_callout(event: DamageLog.Event) -> void:
	if event.tag == &"" or not is_instance_valid(event.enemy):
		return
	if _card_tags_age > 1.0:
		_card_tags_age = 0.0
		var dreams := get_tree().get_first_node_in_group(DreamState.GROUP)
		_card_tags = dreams.call("_credit_rule_map") if dreams != null and dreams.has_method("_credit_rule_map") else {}
	var id: String = _card_tags.get(event.tag, "")
	if id == "":
		return
	var key := StringName("card:" + id)
	var reduced := Fx.reduced()
	if _cooldowns.get(key, 0.0) > 0.0 or _alive.size() >= (REDUCED_MAX_ALIVE if reduced else MAX_ALIVE):
		return
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP)
	var name: String = dreams.get_display_name(id) if dreams != null and dreams.has_method("get_display_name") else id.capitalize()
	_cooldowns[key] = CARD_COOLDOWN * (2.0 if reduced else 1.0)
	_alive.append([0.0, name, UiStyle.GOLD, event.enemy, event.enemy.global_position, &""])
	card_called.emit(id, event.enemy.global_position)

func _on_damage(event: DamageLog.Event) -> void:
	_card_callout(event)
	if not is_instance_valid(event.enemy):
		return
	for tag in event.combos:
		var status: StringName = USES_STATUS.get(tag, &"")
		if status != &"" and event.enemy.has_method("flash_status"):
			event.enemy.flash_status(status)
	var tag := _pick(event)
	var reduced := Fx.reduced()  # Effects quality Reduced, or Fx stepped down on long frames: one at a time, slower repeats
	if tag == &"" or _combo_count() >= (REDUCED_MAX_ALIVE if reduced else MAX_ALIVE) or _cooldowns.get(tag, 0.0) > 0.0:
		_matchup_callout(event)
		return
	var existing: Variant = _callout_for(event.enemy)
	if existing != null and existing[5] == &"":
		return  # One callout per nightmare at a time
	if existing != null:
		_alive.erase(existing)  # A combo word replaces the nightmare's Weak / Strong
	_cooldowns[tag] = REDUCED_COOLDOWN if reduced else TAG_COOLDOWN
	_alive.append([0.0, WORDS[tag], _colour(event.source), event.enemy, event.enemy.global_position, &""])
	_note_seen(tag)

# "Weak!" / "Strong!" on every weak / resisted hit, one per nightmare: a new hit re-pops it in place.
func _matchup_callout(event: DamageLog.Event) -> void:
	var tag := &""
	if event.combos.has(&"weak"):
		tag = &"weak"
	elif event.family_multiplier > 0.0 and event.family_multiplier < 1.0:
		tag = &"resisted"
	if tag == &"":
		return
	var colour: Color = WEAK_COLOUR if tag == &"weak" else STRONG_COLOUR
	var existing: Variant = _callout_for(event.enemy)
	if existing != null:
		if existing[5] != &"":  # Its Weak / Strong: pop it again
			existing[0] = 0.0
			existing[1] = MATCHUP_WORDS[tag]
			existing[2] = colour
			existing[5] = tag
		return  # A combo word is showing: leave it
	var matchups := _alive.size() - _combo_count()
	if matchups >= (REDUCED_MAX_MATCHUPS if Fx.reduced() else MAX_MATCHUPS):
		return
	_alive.append([0.0, MATCHUP_WORDS[tag], colour, event.enemy, event.enemy.global_position, tag])
	_note_seen(tag)

func _callout_for(enemy: Node) -> Variant:
	for callout in _alive:
		if callout[3] == enemy:
			return callout
	return null

func _combo_count() -> int:
	var n := 0
	for callout in _alive:
		if callout[5] == &"":
			n += 1
	return n

# The glossary explains a callout once it has been seen (CodexData.callout_entries): remembered on the
# profile the first time each word shows (real game only; account knowledge).
static var _noted := {}
func _note_seen(tag: StringName) -> void:
	if _noted.has(tag) or owner == null or get_tree().current_scene != owner:
		return
	_noted[tag] = true
	var profile := HeartwoodMemory.load_data()
	var seen: Array = profile.get(CodexData.CALLOUT_SEEN_KEY, [])
	if not seen.has(String(tag)):
		seen.append(String(tag))
		profile[CodexData.CALLOUT_SEEN_KEY] = seen
		HeartwoodMemory.save_data(profile)

# Rank V signatures (warden_stats.md 96d728dd, Tower.signature_fired): its name pops in gold over the Warden (at most
# every SIGNATURE_COOLDOWN per signature), and the first time ever a signature fires on this profile the HUD says what
# it does (a discovery callout; profile SIGNATURES_SEEN_KEY, real game only; `discovered` for tests and Sound).
const SIGNATURE_COOLDOWN := 8.0
const SIGNATURES_SEEN_KEY := CodexData.SIGNATURES_SEEN_KEY
signal signature_discovered(id: StringName, tower: Node2D)
var discovered: Array[StringName] = []  # Signatures discovered this session (profile or not)
var _signatures_seen: Array = []  # The profile's, loaded once

func _hook_towers() -> void:
	_signatures_seen = HeartwoodMemory.load_data().get(SIGNATURES_SEEN_KEY, []).duplicate()
	get_tree().node_added.connect(_on_node_added)
	for tower in get_tree().get_nodes_in_group(Tower.GROUP):
		_on_node_added(tower)

func _on_node_added(node: Node) -> void:
	if node is Tower and node.has_signal("signature_fired") and not node.signature_fired.is_connected(_on_signature):
		node.signature_fired.connect(_on_signature)

func _on_signature(tower: Tower, id: StringName) -> void:
	if not is_instance_valid(tower):
		return
	var first := not _signatures_seen.has(String(id)) and not discovered.has(id)
	var key := StringName("signature:" + String(id))
	if first or (_cooldowns.get(key, 0.0) <= 0.0 and _alive.size() < (REDUCED_MAX_ALIVE if Fx.reduced() else MAX_ALIVE)):
		_cooldowns[key] = SIGNATURE_COOLDOWN
		_alive.append([0.0, String(Signatures.NAMES.get(id, String(id).capitalize())), UiStyle.GOLD, tower, tower.global_position, &""])
	if not first:
		return
	discovered.append(id)
	var hud := owner.get_node_or_null("HUD") if owner != null else null
	if hud != null and hud.has_method("show_toast"):
		hud.show_toast("Signature discovered: %s (%s): %s." % [Signatures.NAMES.get(id, id), tower.tower_data.display_name,
			Signatures.TEXT.get(id, "")])
	signature_discovered.emit(id, tower)
	if owner == null or get_tree().current_scene != owner:
		return  # Tests and previews never write the profile
	var profile := HeartwoodMemory.load_data()
	var seen: Array = profile.get(SIGNATURES_SEEN_KEY, [])
	if not seen.has(String(id)):
		seen.append(String(id))
		profile[SIGNATURES_SEEN_KEY] = seen
		HeartwoodMemory.save_data(profile)

func _pick(event: DamageLog.Event) -> StringName:
	for tag in PRIORITY:
		if event.combos.has(tag) and WORDS.get(tag, "") != "":
			return tag
	return &""

func _colour(source: Node) -> Color:
	var tower := source as Tower
	if tower == null or not is_instance_valid(tower):
		return UiStyle.INK
	return tower.tower_data.projectile_color.lightened(0.25)

func _process(delta: float) -> void:
	_card_tags_age += delta
	for tag in _cooldowns.keys():
		_cooldowns[tag] = maxf(_cooldowns[tag] - delta, 0.0)
	for i in range(_alive.size() - 1, -1, -1):
		var callout: Array = _alive[i]
		callout[0] += delta
		if is_instance_valid(callout[3]):
			callout[4] = callout[3].global_position
		if callout[0] >= LIFE:
			_alive.remove_at(i)
	if not _alive.is_empty() or _drawn:  # Once more after the last word goes, then idle
		queue_redraw()
		_drawn = not _alive.is_empty()

# The look (UI Asset's "Combo moments", approved 2026-10-07): a combo word is its status icon and the word in
# Cormorant SemiBold 17 px with a 1 px Dread outline, no pill; a matchup is a small triangle and "weak" /
# "strong" in Cormorant SC 14 px (Newleaf / Mist). Both pop from 125% to 100% over POP_TIME, rise RISE px
# and fade over LIFE. (The Reaction tier's pill is Fx.reaction's.)
const WORD_SIZE := 17
const MATCHUP_SIZE := 14
const POP_TIME := 0.12
const POP_FROM := 1.25
const RISE := 18.0
const LIFT := 46.0  # The word's middle above the nightmare's centre
const ICON_GAP := 6.0
const MATCHUP_LABELS := {&"weak": "weak", &"resisted": "strong"}
# The status icon drawn before a combo word (16 px art ×1).
const WORD_ICONS := {"Conducted": &"damp", "Asleep": &"drowsy", "Crit": &"crit_chance"}
var _display_font: Font
var _caps_font: Font
var _icons := {}  # Icon id -> Texture2D (or null)

func _word_icon(text: String) -> Texture2D:
	var id: StringName = WORD_ICONS.get(text, &"")
	if id == &"":
		return null
	if not _icons.has(id):
		_icons[id] = IconInfo.icon(id)
	return _icons[id]

func _draw() -> void:
	if _display_font == null:
		_display_font = UiStyle.display_font()
		_caps_font = UiStyle.caps_font()
	var screen_scale := WorldLabel.text_scale(self)  # Keeps its screen size when zoomed in (as begin_screen_size)
	for callout in _alive:
		var age: float = callout[0]
		var t := age / LIFE
		var alpha := 1.0 - t * t
		var pop := lerpf(POP_FROM, 1.0, clampf(age / POP_TIME, 0.0, 1.0))
		var anchor: Vector2 = callout[4]
		var centre := anchor + Vector2(0.0, -LIFT - RISE * t)  # The word's middle, in world px
		# Screen size around the nightmare, then the pop around the word's own middle.
		draw_set_transform(anchor + (centre - anchor) * screen_scale, 0.0, Vector2.ONE * screen_scale * pop)
		if callout[5] != &"":
			_draw_matchup(callout[5], callout[2], alpha)
		else:
			_draw_word(String(callout[1]).trim_suffix("!"), _word_icon(callout[1]), callout[2], alpha)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# A combo word centred on the origin: its status icon, then the word.
func _draw_word(text: String, icon: Texture2D, colour: Color, alpha: float) -> void:
	var font := _display_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, WORD_SIZE).x
	var icon_w := 16.0 + ICON_GAP if icon != null else 0.0
	var x := -(width + icon_w) / 2.0
	if icon != null:
		draw_texture_rect(icon, Rect2(x, -8.0, 16.0, 16.0), false, Color(Color.WHITE, alpha))  # multiplier (modulate)
		x += icon_w
	var baseline := font.get_ascent(WORD_SIZE) - font.get_height(WORD_SIZE) / 2.0
	var at := Vector2(x, baseline)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, WORD_SIZE, 2, Color(Palette.DREAD, alpha))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, WORD_SIZE, Color(colour, alpha))

# "▲ weak" / "▼ strong" centred on the origin (the triangle is drawn: the fonts have no arrow glyphs).
func _draw_matchup(tag: StringName, colour: Color, alpha: float) -> void:
	var font := _caps_font
	var text: String = MATCHUP_LABELS.get(tag, "")
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, MATCHUP_SIZE).x
	var x := -(width + 12.0) / 2.0
	var tip := -3.5 if tag == &"weak" else 3.5  # Up for weak, down for strong
	var points := PackedVector2Array([Vector2(x, -tip), Vector2(x + 8.0, -tip), Vector2(x + 4.0, tip)])
	var outline := Color(Palette.DREAD, alpha)
	draw_colored_polygon(points, Color(colour, alpha))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), outline, 1.0, true)
	var baseline := font.get_ascent(MATCHUP_SIZE) - font.get_height(MATCHUP_SIZE) / 2.0
	var at := Vector2(x + 12.0, baseline)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, MATCHUP_SIZE, 3, outline)  # 3 px: reads on the pale path too
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, MATCHUP_SIZE, Color(colour, alpha))
