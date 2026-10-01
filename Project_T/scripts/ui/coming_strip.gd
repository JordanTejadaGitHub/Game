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
const PIP := 16.0
const TOP := 72.0  # Just under the drift banner
const BOSS_COLOR := UiStyle.BOSS  # Heartwood 32 (ui_style.md)
const DIM := Color(1, 1, 1, 0.4)

var drift_director: DriftDirector
var compact := false  # A drift is walking: the small row
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
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", CAPTION_GAP)  # Caption → discs: the "New" badge sits 6 px above a disc
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.caps(_caption, UiStyle.BODY_SIZE)  # At body size
	add_child(_caption)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 4)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	visible = false
	resized.connect(queue_redraw)

# The strip sits on a fog panel (Moonlit Thread), a little larger than its content.
func _draw() -> void:
	draw_style_box(_fog, Rect2(Vector2(-14, -8), size + Vector2(28, 12)))

const REFRESH := 0.2  # Seconds (real time) between checks: the span, the boss scan and the stack (perf)
var _clock := 0.0

func _process(delta: float) -> void:
	_clock -= delta / maxf(Engine.time_scale, 0.001)
	if _clock > 0.0:
		return
	_clock = REFRESH
	_stack()
	var span := shown_span()
	var pause := get_parent().get_node_or_null("PauseMenu") as Control if get_parent() != null else null  # A sibling (made in code: no % owner)
	# Hidden under the pause menu: its panels (Settings, Codex) are tall enough to reach the strip at 1280×720
	# virtual (user screenshot at the largest UI size).
	visible = span.y >= span.x and not (pause != null and pause.visible)
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
	_caption.text = "Still to come this block" if compact else "Coming this block"
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	var kinds := kinds_in_range(drift_director, span.x, span.y)
	var shown := kinds
	var rest: Array = []
	if kinds.size() > PER_ROW * 2:  # The last slot becomes "+N"
		shown = kinds.slice(0, PER_ROW * 2 - 1)
		rest = kinds.slice(PER_ROW * 2 - 1)
	var line: HBoxContainer = null
	for i in shown.size():
		if i % PER_ROW == 0:
			line = HBoxContainer.new()
			line.alignment = BoxContainer.ALIGNMENT_CENTER
			line.add_theme_constant_override("separation", 6)
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_row.add_child(line)
		line.add_child(_make_item(shown[i][0], shown[i][1], shown[i][2]))
	if not rest.is_empty():
		line.add_child(_more_chip(rest))

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
func _make_item(data: EnemyData, drift: int, count: int = 1) -> Control:
	var item := VBoxContainer.new()
	item.set_meta(&"kind", data)
	item.add_theme_constant_override("separation", 1)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var side := FACE_SMALL if compact else FACE
	var face := Button.new()
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
	item.add_child(face)
	var badge := Label.new()  # How many come: a badge on the disc's lower-right corner
	badge.name = "KindCount"
	badge.text = "×%d" % count
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.number(badge, 13, UiStyle.GOLD)
	badge.add_theme_color_override("font_outline_color", UiStyle.FOG)
	badge.add_theme_constant_override("outline_size", 5)
	badge.position = Vector2(side - 14, side - 16)
	face.add_child(badge)
	if NightmareCard.is_new(data):  # "New": a small gold badge on the upper-left corner
		var tag := Label.new()
		tag.name = "New"
		tag.text = "New"
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiStyle.caps(tag, 11, UiStyle.GOLD)
		tag.add_theme_color_override("font_outline_color", UiStyle.FOG)
		tag.add_theme_constant_override("outline_size", 5)
		tag.position = Vector2(-4, -6)
		face.add_child(tag)
	if not compact:
		var icons := NightmareIcons.make_rows(data, 14.0, true)
		icons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		item.add_child(icons)
	return item

# "+N": the kinds that didn't fit; a tap opens their cards in turn.
func _more_chip(rest: Array) -> Control:
	var chip := Button.new()
	chip.name = "More"
	chip.text = "+%d" % rest.size()
	chip.focus_mode = Control.FOCUS_NONE
	chip.custom_minimum_size = Vector2(FACE_SMALL if compact else FACE, FACE_SMALL if compact else FACE)
	chip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	chip.tooltip_text = ", ".join(rest.map(func(k: Array) -> String: return k[0].display_name))
	var kinds: Array = rest.filter(func(k: Array) -> bool: return not k[0].is_boss).map(func(k: Array) -> EnemyData: return k[0])
	chip.pressed.connect(func() -> void: NightmareIntro.open_for(get_tree(), kinds, drift_director.drifts_started + 1))
	return chip
