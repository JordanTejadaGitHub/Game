extends VBoxContainer
class_name ComingStrip

# "Coming this block" (screens_ui.md "Nightmare info"): the nightmare kinds still to come, top centre
# right under the drift banner (moved 2026-09-28 from the bottom right: "hard to see and notice").
# - At rests: full size, the next block's kinds (portraits ~40 px, "New" if never met, the boss last
#   in a red frame), each with its resist / weak damage-type icons underneath.
# - During a drift: a compact row of small portraits for the rest of the current block, the next
#   drift's kinds lit and the others dimmed. Hidden in a boss drift (the boss bar has the spot).
# Tap a portrait: its centred card (NightmareIntro; one card at a time), the boss: the dossier.
# Made by the HUD.

const FACE := 48.0  # screens_ui.md "Readable on the night sky": 48 px at rests, 36 in drifts
const FACE_SMALL := 36.0
const FACE_BIG := 64.0  # A new rule-breaker at a rest (RuleBreakers)
const PIP := 16.0
const TOP := 72.0  # Just under the drift banner
# Phones (user 2026-10-17: "Coming this block is taking up a space"): no caption, one row of small discs on a tight fog,
# right under the banner. A tap on a disc still opens its card.
const PHONE_FACE := 40.0
const PHONE_PER_ROW := 8
var _phone := false
const BOSS_COLOR := UiStyle.BOSS  # Heartwood 32 (ui_style.md)
const DIM := Color(1, 1, 1, 0.4)

var drift_director: DriftDirector
var compact := false  # A drift is walking: the small row
var next_after_rest := false  # Compact in a block's last drift: the next block's first drift ("After the rest")
var _caption := Label.new()
var _row := VBoxContainer.new()  # Rows of up to PER_ROW kinds (each an HBoxContainer)
var _built_for := ""  # "mode:first:last" of what's shown ("" = nothing)
var _fog := UiStyle.panel()

func _init(director: DriftDirector = null) -> void:
	drift_director = director

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	offset_top = TOP
	mouse_filter = Control.MOUSE_FILTER_STOP  # A panel: the map's hover tags never show through it (user screenshot)
	add_theme_constant_override("separation", CAPTION_GAP)  # Caption → discs: the "New" badge sits 6 px above a disc
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.caps(_caption, UiStyle.BODY_SIZE)  # At body size
	add_child(_caption)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 4)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	_kind_words.name = "KindWords"
	_kind_words.add_theme_constant_override("separation", 0)
	_kind_words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_kind_words)
	move_child(_kind_words, 1)  # In the caption's place, over the discs
	_phone = UiStyle.is_phone()
	if _phone:
		_caption.visible = false
		add_theme_constant_override("separation", 0)
	# The panel's padding is part of the strip's own rect (user screenshot, Moon-glass: a portrait and its "×30" hung
	# over the frame's bottom border), so everything placed under it clears the frame too: an empty spacer at the top and
	# the foot; on PC the separation adds CAPTION_GAP on each side, on phones the spacers carry PHONE_PAD.
	for pad: Control in [_pad_top, _pad_foot]:
		pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pad.custom_minimum_size.y = PHONE_PAD if _phone else 0.0
	add_child(_pad_top)
	move_child(_pad_top, 0)
	add_child(_pad_foot)
	visible = false
	resized.connect(queue_redraw)

const PHONE_PAD := 8.0
const SIDE_PAD := 16.0  # The frame's sides beyond the widest row (6 on phones)
var _pad_top := Control.new()
var _pad_foot := Control.new()

# The strip sits on its panel, the padding inside its own rect (the spacers above): portraits and badges stay inside.
func _draw() -> void:
	if _phone:
		draw_style_box(_fog, Rect2(Vector2(-6, 0), size + Vector2(12, 0)))  # Tight on phones
		return
	draw_style_box(_fog, Rect2(Vector2(-SIDE_PAD, 0), size + Vector2(SIDE_PAD * 2.0, 0)))

const REFRESH := 0.2  # Seconds (real time) between checks: the span, the boss scan and the stack (perf)
var _clock := 0.0

func _process(delta: float) -> void:
	_clock -= delta / maxf(Engine.time_scale, 0.001)
	if _clock > 0.0:
		return
	_clock = REFRESH
	_stack()
	var span := shown_span()
	# Hidden, steadily, while a screen covers the map (RestScreens.covering: a choice, Remember, a Lesson, the pause menu…;
	# "Peek at the map" shows it again). Only this line sets the strip's visibility (it flickered behind the Dream screen
	# when the phone HUD hid it too, user screenshot 2026-10-17).
	visible = span.y >= span.x and not RestScreens.covering(get_parent())
	if not visible:
		_built_for = ""
		return
	var key := "%s:%d:%d" % [compact, span.x, span.y]
	if key != _built_for:
		_built_for = key
		_build(span)
		_lit_for = -1  # New items: light them again
	if compact:
		_light_next()

# The top-centre stack (playtest 2026-09-30: the strip overlapped the Omen line): the drift banner,
# then the active Omen's line (Roguelite's OmenScreen tag "ActiveOmen"), then this strip.
const OMEN_TOP := 68.0  # Just under the banner's boss row
func _stack() -> void:
	var top := TOP
	var omen := get_parent().get_node_or_null("ActiveOmen") as Control if get_parent() != null else null
	if omen != null and omen.visible:
		omen.offset_top = OMEN_TOP
		if omen is Label and omen.autowrap_mode == TextServer.AUTOWRAP_OFF:  # Long Omens wrap to 2 lines, never clipped
			omen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			omen.offset_left = -OMEN_WIDTH / 2.0
			omen.offset_right = OMEN_WIDTH / 2.0
		top = maxf(top, OMEN_TOP + omen.size.y + 14.0)  # Clear of the strip's fog panel too
	offset_top = top
const OMEN_WIDTH := 640.0

# The drifts whose kinds show now (x > y = none): the next block at a rest, the rest of the current
# block during a drift (none in a boss drift or after the run).
func shown_span() -> Vector2i:
	if drift_director == null or not drift_director.has_next_drift() or drift_director.awaiting_family_pick:
		return Vector2i(1, 0)
	var run_state := drift_director.get_node_or_null("%RunState")  # Made in code: no owner of its own
	if run_state != null and run_state.is_over:
		return Vector2i(1, 0)
	var started := drift_director.drifts_started
	var per := drift_director.drifts_per_block
	compact = not drift_director.is_resting()
	if not compact:
		var block := drift_director.get_block(started + 1)
		return Vector2i((block - 1) * per + 1, mini(block * per, drift_director.get_total_drifts()))
	if drift_director.is_boss_drift(started) or _boss_walking():
		return Vector2i(1, 0)
	var block_end := drift_director.get_block(maxi(started, 1)) * per
	next_after_rest = started >= block_end
	if next_after_rest:  # The block's last drift walks: the next drift (after the rest), so the strip never vanishes mid-drift
		return Vector2i(started + 1, started + 1)
	return Vector2i(started + 1, mini(block_end, drift_director.get_total_drifts()))

func _boss_walking() -> bool:
	for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
		if enemy.get("enemy_data") != null and enemy.enemy_data.is_boss and not enemy.is_cleansed:
			return true
	return false

# Kinds arriving in drifts `first`..`last` (first appearance order, bosses last) with the drift
# each first comes in and how many come in all (the difficulty's extra nightmares and the Omen's
# count changes included, as DriftDirector schedules them): [[EnemyData, drift, count], …].
static func kinds_in_range(director: DriftDirector, first: int, last: int) -> Array:
	var kinds: Array = []
	var bosses: Array = []
	var by_kind := {}  # resource path -> its [data, drift, count]
	for number in range(first, last + 1):
		var extra := director.get_extra_nightmares(number)
		var mods: Dictionary = director.get_schedule_modifiers(number)
		for group in director.drifts[number - 1].groups:
			for entry in group.entries:
				var data: EnemyData = entry.enemy
				if data == null:
					continue
				var count: int = entry.get_count(mods.get("count", 1.0), mods.get("flyers", 1.0), extra)
				if by_kind.has(data.resource_path):
					by_kind[data.resource_path][2] += count
					continue
				var item := [data, number, count]
				by_kind[data.resource_path] = item
				(bosses if data.is_boss else kinds).append(item)
	return kinds + bosses

static func kinds_in_block(director: DriftDirector, block: int) -> Array:
	var first := (block - 1) * director.drifts_per_block + 1
	return kinds_in_range(director, first, mini(block * director.drifts_per_block, director.get_total_drifts()))

# Laid out low and wide (screens_ui.md "Coming this block" → "Too tall": six kinds stacked five rows
# deep): one centred row of equal round discs, a second row only past PER_ROW kinds, and past two rows
# a "+N" chip that opens the rest on tap. About 90 px tall at rests.
const PER_ROW := 6
const CAPTION_GAP := 14  # ~8 px clear between the caption and the disc row, "New" badges included (user)

func _build(span: Vector2i) -> void:
	_caption.text = ("After the rest" if next_after_rest else "Still to come this block") if compact else "Coming this block"
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	var kinds := kinds_in_range(drift_director, span.x, span.y)
	# New rule-breakers (RuleBreakers: a flyer, sprinter… this run hasn't faced) lead at rests, larger, with their trait in words.
	var breaking := {}
	if not compact:
		for item in RuleBreakers.new_in(drift_director, span.x, span.y):
			breaking[item[0].resource_path] = true
		if not breaking.is_empty():
			var first_ones := kinds.filter(func(k: Array) -> bool: return breaking.has(k[0].resource_path))
			kinds = first_ones + kinds.filter(func(k: Array) -> bool: return not breaking.has(k[0].resource_path))
	var shown := kinds
	var rest: Array = []
	var per_row := PHONE_PER_ROW if _phone else PER_ROW
	var cap := per_row if _phone else PER_ROW * 2  # Phones: one row
	if kinds.size() > cap:  # The last slot becomes "+N"
		shown = kinds.slice(0, cap - 1)
		rest = kinds.slice(cap - 1)
	var line: HBoxContainer = null
	for i in shown.size():
		if i % per_row == 0:
			line = HBoxContainer.new()
			line.alignment = BoxContainer.ALIGNMENT_CENTER
			line.add_theme_constant_override("separation", 6)
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_row.add_child(line)
		line.add_child(_make_item(shown[i][0], shown[i][1], shown[i][2], breaking.has(shown[i][0].resource_path)))
	if not rest.is_empty():
		line.add_child(_more_chip(rest))
	_build_kind_words(span)

# A Kind's first drift this run, in words on the strip itself (Balancing Discussion, owner 2026-10-19: "warning 1 drift
# earlier is better"; human run lost to drift 31's Phantoms). Only the very next drift, at a rest and mid-block alike
# (owner 2026-10-19: "should just be the 1 drift earlier"): the drift 30 rest names drift 31's Phantoms ("Drift 31 · Flying:
# flies over your maze"); a Kind first coming at drift 33 shows once drift 32 is under way. Plain text, no hover or tap
# needed (phones too). Kinds from EnemyData.Kind.
const KIND_WORDS := {EnemyData.Kind.ARMOURED: "heavy hits crack its shell", EnemyData.Kind.FLYING: "flies over your maze",
	EnemyData.Kind.HIDDEN: "can't be targeted until a Warden reveals it", EnemyData.Kind.SWARM: "comes as a crowd; area attacks catch them all",
	EnemyData.Kind.FAST: "outruns a thin maze; slows and holds keep it in reach"}
const KIND_WORDS_WIDTH := 560.0  # One line for the longest (Fast) at 15 px
var _kind_words := VBoxContainer.new()

# [[Kind, EnemyData, drift], …]: the Kinds (not Plain, never bosses) first arriving in drifts `first`..`last` this run.
static func new_kinds(director: DriftDirector, first: int, last: int) -> Array:
	if director == null or first > last:
		return []
	var faced := {}
	if first > 1:
		for item in kinds_in_range(director, 1, first - 1):
			if not item[0].is_boss:  # A boss has its dossier; it doesn't teach the Kind
				faced[item[0].kind] = true
	var result: Array = []
	for item in kinds_in_range(director, first, last):
		var data: EnemyData = item[0]
		if data.is_boss or data.kind == EnemyData.Kind.PLAIN or faced.has(data.kind):
			continue
		faced[data.kind] = true
		result.append([data.kind, data, item[1]])
	return result

static func kind_words(data: EnemyData) -> String:
	var what: String = KIND_WORDS.get(data.kind, "")
	if data.kind == EnemyData.Kind.FLYING and not data.is_through_walls():
		what = "flies along your path"
	return "%s: %s" % [data.get_kind_name(), what]

func _build_kind_words(_span: Vector2i) -> void:
	for child in _kind_words.get_children():
		_kind_words.remove_child(child)
		child.queue_free()
	var next := drift_director.drifts_started + 1  # Only the very next drift, at a rest and mid-block alike
	for entry in new_kinds(drift_director, next, next):
		var words := Label.new()
		words.name = "Kind%d" % entry[0]
		words.text = "Drift %d · %s" % [entry[2], kind_words(entry[1])]
		words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.custom_minimum_size.x = minf(KIND_WORDS_WIDTH, get_viewport_rect().size.x - 32.0) if _phone else KIND_WORDS_WIDTH
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		words.add_theme_font_size_override("font_size", 14 if _phone else 15)
		words.add_theme_color_override("font_color", UiStyle.GOLD)
		_kind_words.add_child(words)
	_kind_words.visible = _kind_words.get_child_count() > 0
	if not _phone:  # The line takes the caption's place, so the strip stays low (test_rule_breakers: 140 px)
		_caption.visible = not _kind_words.visible

# The kind items, whichever row they're on.
func items() -> Array:
	var all: Array = []
	for line in _row.get_children():
		for item in line.get_children():
			if item.has_meta(&"kind"):
				all.append(item)
	return all

# Compact: the next drift's kinds lit, the rest dimmed.
var _lit_for := -1  # The drift the lit set was built for (rebuilt only when a drift starts; perf)

func _light_next() -> void:
	var next := drift_director.drifts_started + 1
	if next == _lit_for:
		return
	_lit_for = next
	var lit := {}
	if next <= drift_director.get_total_drifts():
		for pair in kinds_in_range(drift_director, next, next):
			lit[pair[0]] = true
	for item in items():
		item.modulate = Color.WHITE if lit.has(item.get_meta(&"kind")) else DIM

# One kind: the same round disc for every kind (the art fitted inside, whatever its shape), "New" and
# the count as badges on its corners, the resist / weak row under it (14 px). Its name on hover / tap.
func _make_item(data: EnemyData, drift: int, count: int = 1, breaks_rules: bool = false) -> Control:
	var item := VBoxContainer.new()
	item.set_meta(&"kind", data)
	item.set_meta(&"breaks_rules", breaks_rules)
	item.add_theme_constant_override("separation", 1)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var side := FACE_SMALL if compact else (FACE_BIG if breaks_rules else FACE)
	if _phone:
		side = PHONE_FACE  # Phones: one small row (user 2026-10-17: "Coming this block is taking up a space")
	# The disc and its badges as siblings in a holder: the disc clips its art, the badges must not be clipped
	# (user screenshot: "New" showed as "EW", the counts as "×1?").
	var holder := Control.new()
	holder.name = "Disc"
	holder.custom_minimum_size = Vector2(side, side)
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(holder)
	var face := Button.new()
	face.name = "Face"
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face.icon = NightmareCard.portrait(data)
	face.expand_icon = true
	face.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	face.custom_minimum_size = Vector2(side, side)
	face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Never stretched into a wide pill
	face.clip_contents = true
	face.focus_mode = Control.FOCUS_NONE
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.add_theme_color_override("icon_normal_color", data.tint)
	face.add_theme_constant_override("icon_max_width", int(side - 10))
	face.tooltip_text = "%s · ×%d" % [data.display_name, count]
	UiStyle.moon_disc_button(face, BOSS_COLOR if data.is_boss else UiStyle.OFF)  # Pale disc: readable on the night sky
	if data.is_boss:
		face.pressed.connect(func() -> void: BossDossier.open_for(get_tree(), drift))
	else:  # One centred card for every nightmare (its name, what it does)
		face.pressed.connect(func() -> void: NightmareIntro.open_for(get_tree(), [data], drift))
	holder.add_child(face)
	var badge := Label.new()  # How many come: on a dark pill inside the disc's lower-right corner
	badge.name = "KindCount"
	badge.text = "×%d" % count
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.number(badge, 13, UiStyle.GOLD)
	_badge_look(badge)
	badge.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	badge.grow_vertical = Control.GROW_DIRECTION_BEGIN
	holder.add_child(badge)
	if breaks_rules or NightmareCard.is_new(data):  # "New": a gold tab over the disc's top edge (a new rule-breaker: always)
		var tag := Label.new()
		tag.name = "New"
		tag.text = "New"
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiStyle.caps(tag, 11, UiStyle.GOLD)
		_badge_look(tag)
		tag.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		tag.grow_horizontal = Control.GROW_DIRECTION_BOTH
		tag.offset_top = -6.0
		holder.add_child(tag)
	if not compact:
		var icons := NightmareIcons.make_rows(data, 14.0, true)
		# The item's full width (the flow centres them): shrunk to one icon, a flow wrapped every icon onto its own line
		# (a Phantom resisting one family and weak to another stood 113 px tall, Spire 2026-10-02).
		icons.size_flags_horizontal = Control.SIZE_FILL
		item.add_child(icons)
	if breaks_rules:  # Just its verb ("Flies"): the DriftPanel's warning line has the sentence
		var words := Label.new()
		words.name = "TraitWords"
		words.text = String(RuleBreakers.VERBS.get(data.trait_kind, "Breaks the rules")).capitalize()
		words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		words.add_theme_font_size_override("font_size", 14)
		words.add_theme_color_override("font_color", UiStyle.GOLD)
		item.add_child(words)
	return item

# A badge over a portrait ("×22", "New"): a crisp Void outline round the letters keeps it readable on the pale disc, no
# dark pill under it (user 2026-10-21: "why is it dark underneath the 22 and 4").
func _badge_look(label: Label) -> void:
	var room := StyleBoxEmpty.new()
	room.content_margin_left = 3.0
	room.content_margin_right = 3.0
	label.add_theme_stylebox_override("normal", room)
	label.add_theme_color_override("font_outline_color", Palette.VOID)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_shadow_color", Color(Palette.VOID, 0.0))  # The theme's soft shadow would smear it

# "+N": the kinds that didn't fit; a tap opens their cards in turn.
func _more_chip(rest: Array) -> Control:
	var chip := Button.new()
	chip.name = "More"
	chip.text = "+%d" % rest.size()
	chip.focus_mode = Control.FOCUS_NONE
	var chip_side := PHONE_FACE if _phone else (FACE_SMALL if compact else FACE)
	chip.custom_minimum_size = Vector2(chip_side, chip_side)
	chip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	chip.tooltip_text = ", ".join(rest.map(func(k: Array) -> String: return k[0].display_name))
	var kinds: Array = rest.filter(func(k: Array) -> bool: return not k[0].is_boss).map(func(k: Array) -> EnemyData: return k[0])
	chip.pressed.connect(func() -> void: NightmareIntro.open_for(get_tree(), kinds, drift_director.drifts_started + 1))
	return chip
