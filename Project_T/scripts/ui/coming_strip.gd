extends VBoxContainer
class_name ComingStrip

# "Coming this block" (screens_ui.md "Nightmare info", added 2026-09-28): at every rest, above the
# Start button, the nightmare kinds of the next block: portraits ("New" if never met, the boss last,
# in a red frame), each with its resist / weak icons underneath. Tap a portrait for its full info
# (NightmareCard); the boss's opens the boss dossier. Made by the DriftPanel.

const FACE := 40.0
const PIP := 16.0
const BOSS_COLOR := Color(0.95, 0.45, 0.4)

var drift_director: DriftDirector
var _row := HFlowContainer.new()
var _card := NightmareCard.new()
var _built_for := -1  # The block shown (-1 = none)

func _init(director: DriftDirector = null) -> void:
	drift_director = director

func _ready() -> void:
	add_theme_constant_override("separation", 2)
	var caption := Label.new()
	caption.text = "Coming this block"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	caption.add_theme_font_size_override("font_size", 13)
	caption.add_theme_color_override("font_color", Color(0.8, 0.85, 0.78))
	caption.add_theme_color_override("font_outline_color", Color(0.08, 0.1, 0.14))
	caption.add_theme_constant_override("outline_size", 5)
	add_child(caption)
	_row.alignment = FlowContainer.ALIGNMENT_END
	_row.add_theme_constant_override("h_separation", 4)
	add_child(_row)
	add_child(_card)
	visible = false

func _process(_delta: float) -> void:
	var show := should_show()
	visible = show
	if not show:
		_card.visible = false
		_built_for = -1
		return
	var block := drift_director.get_block(drift_director.drifts_started + 1)
	if block != _built_for:
		_build(block)

func should_show() -> bool:
	if drift_director == null or not drift_director.is_resting() or not drift_director.has_next_drift():
		return false
	var run_state := drift_director.get_node_or_null("%RunState")  # This node is made in code: no owner of its own
	return not drift_director.awaiting_family_pick and not (run_state != null and run_state.is_over)

# The kinds arriving in block `block` (first appearance order, bosses last) and the drift each first
# comes in: [[EnemyData, drift], …].
static func kinds_in_block(director: DriftDirector, block: int) -> Array:
	var first := (block - 1) * director.drifts_per_block + 1
	var last := mini(block * director.drifts_per_block, director.get_total_drifts())
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

func _build(block: int) -> void:
	_built_for = block
	_card.visible = false
	for child in _row.get_children():
		child.queue_free()
	for pair in kinds_in_block(drift_director, block):
		_row.add_child(_make_item(pair[0], pair[1]))

func _make_item(data: EnemyData, drift: int) -> Control:
	var item := VBoxContainer.new()
	item.add_theme_constant_override("separation", 0)
	var face := Button.new()
	face.icon = NightmareCard.portrait(data)
	face.expand_icon = true
	face.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	face.custom_minimum_size = Vector2(FACE, FACE)
	face.focus_mode = Control.FOCUS_NONE
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.add_theme_color_override("icon_normal_color", data.tint)
	face.tooltip_text = data.display_name + (" · boss: tap for the dossier" if data.is_boss else "")
	if data.is_boss:
		var frame := StyleBoxFlat.new()
		frame.bg_color = Color(0.2, 0.06, 0.06, 0.9)
		frame.border_color = BOSS_COLOR
		frame.set_border_width_all(2)
		frame.set_corner_radius_all(4)
		face.add_theme_stylebox_override("normal", frame)
		face.pressed.connect(func() -> void: BossDossier.open_for(get_tree(), drift))
	else:
		face.pressed.connect(func() -> void: _card.toggle_for(data, drift, drift_director, face))
	item.add_child(face)
	if NightmareCard.is_new(data):
		var tag := Label.new()
		tag.text = "New"
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.add_theme_font_size_override("font_size", 11)
		tag.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
		tag.add_theme_color_override("font_outline_color", Color(0.08, 0.1, 0.14))
		tag.add_theme_constant_override("outline_size", 4)
		item.add_child(tag)
	item.add_child(NightmareIcons.make_rows(data, PIP, true))
	return item
