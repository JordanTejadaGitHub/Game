extends VBoxContainer
class_name ComingStrip

# "Coming this block" (screens_ui.md "Nightmare info"): the nightmare kinds still to come, top centre
# right under the drift banner (moved 2026-09-28 from the bottom right: "hard to see and notice").
# - At rests: full size, the next block's kinds (portraits ~40 px, "New" if never met, the boss last
#   in a red frame), each with its resist / weak damage-type icons underneath.
# - During a drift: a compact row of small portraits for the rest of the current block, the next
#   drift's kinds lit and the others dimmed. Hidden in a boss drift (the boss bar has the spot).
# Tap a portrait: a new kind reopens its introduction (NightmareIntro), a known one shows its info
# (NightmareCard), the boss opens the boss dossier. Made by the HUD.

const FACE := 40.0
const FACE_SMALL := 26.0
const PIP := 16.0
const TOP := 72.0  # Just under the drift banner
const BOSS_COLOR := UiStyle.BOSS  # Heartwood 32 (ui_style.md)
const DIM := Color(1, 1, 1, 0.4)

var drift_director: DriftDirector
var compact := false  # A drift is walking: the small row
var _caption := Label.new()
var _row := HFlowContainer.new()
var _card := NightmareCard.new()
var _built_for := ""  # "mode:first:last" of what's shown ("" = nothing)

func _init(director: DriftDirector = null) -> void:
	drift_director = director

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	offset_top = TOP
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 2)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.caps(_caption, 13)
	add_child(_caption)
	_row.alignment = FlowContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("h_separation", 4)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	add_child(_card)
	visible = false

func _process(_delta: float) -> void:
	var span := shown_span()
	visible = span.y >= span.x
	if not visible:
		_card.visible = false
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
# each first comes in: [[EnemyData, drift], …].
static func kinds_in_range(director: DriftDirector, first: int, last: int) -> Array:
	var kinds: Array = []
	var bosses: Array = []
	var seen := {}
	for number in range(first, last + 1):
		for group in director.drifts[number - 1].groups:
			for entry in group.entries:
				var data: EnemyData = entry.enemy
				if data == null or seen.has(data.resource_path):
					continue
				seen[data.resource_path] = true
				(bosses if data.is_boss else kinds).append([data, number])
	return kinds + bosses

static func kinds_in_block(director: DriftDirector, block: int) -> Array:
	var first := (block - 1) * director.drifts_per_block + 1
	return kinds_in_range(director, first, mini(block * director.drifts_per_block, director.get_total_drifts()))

func _build(span: Vector2i) -> void:
	_card.visible = false
	_caption.text = "Still to come this block" if compact else "Coming this block"
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	for pair in kinds_in_range(drift_director, span.x, span.y):
		_row.add_child(_make_item(pair[0], pair[1]))

# Compact: the next drift's kinds lit, the rest dimmed.
func _light_next() -> void:
	var next := drift_director.drifts_started + 1
	var lit := {}
	if next <= drift_director.get_total_drifts():
		for pair in kinds_in_range(drift_director, next, next):
			lit[pair[0]] = true
	for item in _row.get_children():
		item.modulate = Color.WHITE if lit.has(item.get_meta(&"kind")) else DIM

func _make_item(data: EnemyData, drift: int) -> Control:
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
	if data.is_boss:
		var frame := UiStyle.button_box()  # The boss face: a button outlined in the boss colour
		frame.border_color = BOSS_COLOR
		frame.set_border_width_all(2)
		face.add_theme_stylebox_override("normal", frame)
		face.pressed.connect(func() -> void: BossDossier.open_for(get_tree(), drift))
	elif is_new:
		face.pressed.connect(func() -> void: NightmareIntro.open_for(get_tree(), [data], drift))
	else:
		face.pressed.connect(func() -> void: _card.toggle_for(data, drift, drift_director, face))
	item.add_child(face)
	if is_new:
		var tag := Label.new()
		tag.text = "New"
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiStyle.caps(tag, 11, UiStyle.GOLD)
		item.add_child(tag)
	if not compact:
		item.add_child(NightmareIcons.make_rows(data, PIP, true))
	return item
