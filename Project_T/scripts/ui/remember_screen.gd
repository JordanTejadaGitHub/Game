extends Control
class_name RememberScreen

# Remember (run_design.md "Dreamlight"): a tree per owned family (base → branches → final forms, plus
# Thornwall's wall growths). Each form shows whether it's unlocked, what it costs in Dreamlight and
# why it's locked; clicking an affordable one unlocks it for the run. Opens after each boss's
# family pick (the Dream waits for it) and on request (rest panel, Warden panel). Pauses while
# open. Built in code.

const MOTE := "✦"  # Dreamlight
const COLUMN_WIDTH := 230.0
const UNLOCKED_COLOR := Color(0.6, 0.95, 0.6)
const AFFORDABLE_COLOR := Color(1.0, 0.9, 0.55)
const LOCKED_COLOR := Color(0.62, 0.62, 0.66)
const FOCUS_COLOR := Color(1.0, 0.85, 0.4)

@onready var dream_state: DreamState = %DreamState
@onready var game_speed: GameSpeed = %GameSpeed

var focus: TowerData = null
var _was_paused := false
var _title := Label.new()
var _trees := HBoxContainer.new()
var peek: ChoicePeek  # Minimise to look at the map (screens_ui.md "Choice screens")

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.04, 0.09, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_color", Color(0.85, 0.85, 1.0))
	box.add_child(_title)
	var hint := Label.new()
	hint.text = "Unlock a form for this run with Dreamlight. Growing each Warden still costs Dew."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	box.add_child(hint)
	_trees.add_theme_constant_override("separation", 18)
	_trees.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_trees)
	var done := Button.new()
	done.text = "Done"
	done.focus_mode = Control.FOCUS_NONE
	done.custom_minimum_size = Vector2(160, 40)
	done.pressed.connect(close)
	var row := CenterContainer.new()
	row.add_child(done)
	box.add_child(row)
	peek = ChoicePeek.new(self, [dim, center], "Back to Remember")
	box.add_child(peek.make_peek_button())
	visible = false
	dream_state.remember_requested.connect(open)
	dream_state.dreamlight_changed.connect(func(_n: int) -> void:
		if visible:
			_rebuild())
	dream_state.unlocks_changed.connect(func() -> void:
		if visible:
			_rebuild())

func open(focus_form: TowerData = null) -> void:
	focus = focus_form
	if not visible:
		_was_paused = game_speed.paused
	game_speed.set_paused(true)
	visible = true
	_rebuild()

func close() -> void:
	visible = false
	game_speed.set_paused(_was_paused)
	dream_state.remember_closed()

# Unlocks `data` (from a button). Returns whether it worked.
func unlock(data: TowerData) -> bool:
	return dream_state.unlock_with_dreamlight(data)

func _rebuild() -> void:
	_title.text = "Remember  ·  %d %s Dreamlight" % [dream_state.dreamlight, MOTE]
	for child in _trees.get_children():
		_trees.remove_child(child)
		child.queue_free()
	var trees := dream_state.get_remember_trees()
	if trees.is_empty():
		var none := Label.new()
		none.text = "No family to remember yet."
		_trees.add_child(none)
	for tree in trees:
		_trees.add_child(_make_tree(tree[0], tree[1]))

func _make_tree(root: TowerData, branches: Array) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.16, 0.95)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(COLUMN_WIDTH, 0)
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var name_label := Label.new()
	name_label.text = root.display_name
	name_label.add_theme_font_size_override("font_size", 20)
	column.add_child(name_label)
	for branch in branches:
		column.add_child(_make_form(branch[0], 0))
		for final in branch[1]:
			column.add_child(_make_form(final, 1))
	return panel

# One form: "Stormcap · 1 ✦" (affordable), "✓ Stormcap" (unlocked), or greyed with why it's locked.
func _make_form(data: TowerData, depth: int) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.tooltip_text = data.description
	var indent := "      ".repeat(depth) + ("└ " if depth > 0 else "")
	var cost := dream_state.get_unlock_cost(data)
	var blocker := dream_state.get_unlock_blocker(data)
	var color := LOCKED_COLOR
	if cost == 0:
		button.text = "%s✓ %s" % [indent, data.display_name]
		button.disabled = true
		color = UNLOCKED_COLOR
	elif blocker != "":
		button.text = "%s%s · %d %s · %s" % [indent, data.display_name, cost, MOTE, blocker]
		button.disabled = true
	else:
		button.text = "%s%s · %d %s" % [indent, data.display_name, cost, MOTE]
		button.disabled = cost > dream_state.dreamlight
		if not button.disabled:
			color = AFFORDABLE_COLOR
		button.pressed.connect(unlock.bind(data))
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_disabled_color", color)
	if data == focus:
		var outline := StyleBoxFlat.new()
		outline.bg_color = Color(0.2, 0.18, 0.1, 0.9)
		outline.border_color = FOCUS_COLOR
		outline.set_border_width_all(2)
		outline.set_corner_radius_all(4)
		for state in ["normal", "disabled", "hover"]:
			button.add_theme_stylebox_override(state, outline)
	return button
