extends Control
class_name BlightPicker

# Pick a Blight Level before a run (meta_design.md "Blight Levels"): opens after the first win, each
# level adds its modifier on top of the ones below it, +10% Seeds per level. Emits `picked(level)`.
# A styled dialog like the pause menu's (ui_style.md "one primary per dialog"): the screen dimmed, a solid
# moonlit panel, the title in the display face, Start as the one primary and Cancel framed. Every button 48 px.

signal picked(level: int)

const LEVELS: Array[String] = [
	"No Blight",
	"Nightmares +10% health",
	"The first family pick gives no Dreamlight",
	"Bosses +25% health",
	"Rest bonus −25%",
	"One nightmare per drift is Deeply Blighted",
	"No leaves regrow at act breaks",
	"Nightmares +10% speed",
	"Let it pass gives no Dew; Dreams lean Common",
	"Clearing obstacles costs twice as much",
	"The Hollow Oak Remembers",
]

var _pick := OptionButton.new()
var _detail := Label.new()
var _start := Button.new()

func _init() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP  # The dialog is modal
	var dim := ColorRect.new()
	dim.color = Color(UiStyle.FOG, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := Label.new()
	title.text = "Blight Level"
	UiStyle.display(title, 28)
	box.add_child(title)
	_pick.focus_mode = Control.FOCUS_NONE
	_pick.custom_minimum_size.y = UiStyle.HUD_BUTTON_H
	_pick.item_selected.connect(_describe)
	box.add_child(_pick)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size.x = 400
	_detail.add_theme_color_override("font_color", UiStyle.INK_DIM)
	box.add_child(_detail)
	var gap := Control.new()  # The text never touches the primary's thread
	gap.custom_minimum_size.y = 12
	box.add_child(gap)
	_start.name = "Start"
	_start.text = "Start"
	_start.focus_mode = Control.FOCUS_NONE
	_start.custom_minimum_size.y = UiStyle.HUD_BUTTON_H
	UiStyle.primary(_start)
	_start.pressed.connect(func() -> void:
		visible = false
		picked.emit(_pick.selected))
	box.add_child(_start)
	var cancel := Button.new()
	cancel.name = "Cancel"
	cancel.text = "Cancel"
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.custom_minimum_size.y = UiStyle.HUD_BUTTON_H
	cancel.pressed.connect(func() -> void: visible = false)
	box.add_child(cancel)

func _ready() -> void:
	# A solid fill behind the text, like the pause menu's dialogs (the theme's panel, made opaque).
	var panel := (get_child(1) as Control).get_child(0) as PanelContainer
	var fill := panel.get_theme_stylebox("panel")
	if fill is MoonStyleBox:
		var solid := (fill as MoonStyleBox).duplicate() as MoonStyleBox
		solid.center_alpha = UiStyle.TIP_ALPHA
		solid.edge_alpha = UiStyle.TIP_ALPHA
		panel.add_theme_stylebox_override("panel", solid)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):  # Esc closes it, like Cancel
		visible = false
		get_viewport().set_input_as_handled()

# Shows levels 0..`max_level` (the highest you may pick).
func open(max_level: int) -> void:
	_pick.clear()
	for level in max_level + 1:
		_pick.add_item("Level %d" % level if level > 0 else "No Blight")
	_pick.selected = mini(MetaRun.blight_level, max_level)
	_describe(_pick.selected)
	visible = true
	move_to_front()

func _describe(level: int) -> void:
	var lines: Array[String] = []
	for i in range(1, level + 1):
		lines.append("%d. %s" % [i, LEVELS[i]])
	_detail.text = ("\n".join(lines) + "\n\n+%d%% Seeds" % (level * 10)) if level > 0 else "The forest as it is."
