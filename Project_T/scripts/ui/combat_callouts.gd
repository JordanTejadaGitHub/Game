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
const WORDS := {&"conducted": "Conducted!", &"asleep": "Asleep!",
	&"crit": "Critical!", &"weak": "Weak!", &"marked": "", &"fog": "", &"static": ""}
# Combo tag -> the status it used (flashes on the nightmare).
const USES_STATUS := {&"conducted": &"damp", &"asleep": &"drowsy",
	&"marked": &"marked", &"fog": &"spored", &"static": &"static"}
const PRIORITY: Array[StringName] = [&"asleep", &"conducted", &"crit", &"weak"]

var _cooldowns := {}  # tag -> seconds left
var _alive: Array = []  # [age, text, colour, enemy (weak ref target), offset]
var _weak_shown := {}  # enemy instance id -> true ("Weak!" once per nightmare)
var _drawn := false  # Words were on screen last frame

func _ready() -> void:
	z_index = 21  # Over the damage numbers
	_connect.call_deferred()  # DamageLog readies later in the scene

func _connect() -> void:
	var log := DamageLog.instance
	if log != null:
		log.damage_dealt.connect(_on_damage)

# Trigger cards (screens_ui.md "Dream" ecbea61a): a taken card whose own damage just landed (its rule's tag, as
# DreamState credits it) pops its name over the nightmare, no numbers, at most every CARD_COOLDOWN per card.
const CARD_COOLDOWN := 6.0
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
	_alive.append([0.0, name, UiStyle.GOLD, event.enemy, event.enemy.global_position])

func _on_damage(event: DamageLog.Event) -> void:
	_card_callout(event)
	if event.combos.is_empty() or not is_instance_valid(event.enemy):
		return
	for tag in event.combos:
		var status: StringName = USES_STATUS.get(tag, &"")
		if status != &"" and event.enemy.has_method("flash_status"):
			event.enemy.flash_status(status)
	var tag := _pick(event)
	var reduced := Fx.reduced()  # Effects quality Reduced, or Fx stepped down on long frames: one at a time, slower repeats
	if tag == &"" or _alive.size() >= (REDUCED_MAX_ALIVE if reduced else MAX_ALIVE) or _cooldowns.get(tag, 0.0) > 0.0:
		return
	if tag == &"weak":
		var id := event.enemy.get_instance_id()
		if _weak_shown.has(id):
			return
		_weak_shown[id] = true
	for callout in _alive:
		if callout[3] == event.enemy:
			return  # One callout per nightmare at a time
	_cooldowns[tag] = REDUCED_COOLDOWN if reduced else TAG_COOLDOWN
	_alive.append([0.0, WORDS[tag], _colour(event.source), event.enemy, event.enemy.global_position])
	_note_seen(tag)

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

func _draw() -> void:
	var font := ThemeDB.fallback_font
	for callout in _alive:
		var t: float = callout[0] / LIFE
		var alpha := 1.0 - t * t
		var size := 18 if t > 0.12 else 22  # A little pop as it appears
		var text: String = callout[1]
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var at: Vector2 = callout[4] + Vector2(-width / 2.0, -46.0 - 18.0 * t)
		WorldLabel.begin_screen_size(self, callout[4])  # Keeps its screen size when zoomed in
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 5, Color(Palette.DREAD, alpha))
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(callout[2], alpha))
		WorldLabel.end_screen_size(self)
