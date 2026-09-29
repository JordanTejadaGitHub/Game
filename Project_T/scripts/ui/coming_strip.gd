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
var _row := HFlowContainer.new()
var _built_for := ""  # "mode:first:last" of what's shown ("" = nothing)
var _fog := UiStyle.panel()

func _init(director: DriftDirector = null) -> void:
	drift_director = director

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	offset_top = TOP
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 2)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.caps(_caption, UiStyle.BODY_SIZE)  # At body size
	add_child(_caption)
	_row.alignment = FlowContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("h_separation", 4)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	visible = false
	resized.connect(queue_redraw)

# The strip sits on a fog panel (Moonlit Thread), a little larger than its content.
func _draw() -> void:
	draw_style_box(_fog, Rect2(Vector2(-14, -8), size + Vector2(28, 12)))

func _process(_delta: float) -> void:
	var span := shown_span()
	visible = span.y >= span.x
	if not visible:
		_built_for = ""
		return
	var key := "%s:%d:%d" % [compact, span.x, span.y]
	if key != _built_for:
		_built_for = key
		_build(span)
	if compact:
		_light_next()

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

func _build(span: Vector2i) -> void:
	_caption.text = "Still to come this block" if compact else "Coming this block"
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	for kind in kinds_in_range(drift_director, span.x, span.y):
		_row.add_child(_make_item(kind[0], kind[1], kind[2]))

# Compact: the next drift's kinds lit, the rest dimmed.
func _light_next() -> void:
	var next := drift_director.drifts_started + 1
	var lit := {}
	if next <= drift_director.get_total_drifts():
		for pair in kinds_in_range(drift_director, next, next):
			lit[pair[0]] = true
	for item in _row.get_children():
		item.modulate = Color.WHITE if lit.has(item.get_meta(&"kind")) else DIM

# `count`: how many of the kind come in the span ("×18" under its portrait at rests, with its name).
func _make_item(data: EnemyData, drift: int, count: int = 1) -> Control:
	var item := VBoxContainer.new()
	item.set_meta(&"kind", data)
	item.add_theme_constant_override("separation", 0)
	var side := FACE_SMALL if compact else FACE
	var face := Button.new()
	face.icon = NightmareCard.portrait(data)
	face.expand_icon = true
	face.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	face.custom_minimum_size = Vector2(side, side)
	face.focus_mode = Control.FOCUS_NONE
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.add_theme_color_override("icon_normal_color", data.tint)
	face.tooltip_text = data.display_name + (" · boss: tap for the dossier" if data.is_boss else "")
	var is_new := NightmareCard.is_new(data)
	if not data.is_boss:
		UiStyle.moon_disc_button(face)  # A pale moonlit disc: dark nightmares stay visible on the night sky
	if data.is_boss:
		UiStyle.moon_disc_button(face, BOSS_COLOR)  # The boss: the moon disc rimmed in the boss colour
		face.pressed.connect(func() -> void: BossDossier.open_for(get_tree(), drift))
	else:  # One centred card for every nightmare (user: no small popup beside the portrait, no stacking)
		face.pressed.connect(func() -> void: NightmareIntro.open_for(get_tree(), [data], drift))
	item.add_child(face)
	if is_new:
		var tag := Label.new()
		tag.text = "New"
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiStyle.caps(tag, 11, UiStyle.GOLD)
		item.add_child(tag)
	if not compact:  # Readable on the night sky (screens_ui.md): its name and how many come
		var name := Label.new()
		name.name = "KindName"
		name.text = data.display_name
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiStyle.caps(name, 14, UiStyle.INK)
		item.add_child(name)
		var many := Label.new()
		many.name = "KindCount"
		many.text = "×%d" % count
		many.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiStyle.number(many, 14, UiStyle.GOLD)
		item.add_child(many)
		item.add_child(NightmareIcons.make_rows(data, PIP, true))
	return item
