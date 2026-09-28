extends PanelContainer
class_name TapTip

# Tooltips that also work by tap (screens_ui.md "Stat and status icons", platforms.md: no
# hover-only information). TapTip.attach(control, text) sets the hover tooltip and, on a tap or
# click, shows the same text in a small popup above the control for a few seconds. Tapping again
# hides it.

const SHOW_TIME := 3.0

var _label := Label.new()
var _timer := 0.0

# Gives `control` a tooltip that also opens on tap. Returns the popup (for tests).
static func attach(control: Control, text: String) -> TapTip:
	control.tooltip_text = text
	if control.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		control.mouse_filter = Control.MOUSE_FILTER_PASS
	var tip := TapTip.new()
	tip._label.text = text
	control.add_child(tip)
	control.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			tip.toggle())
	return tip

func _init() -> void:
	top_level = true  # Drawn above the layout, positioned by hand
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(240, 0)
	_label.add_theme_font_size_override("font_size", 15)
	add_child(_label)
	process_mode = Node.PROCESS_MODE_ALWAYS

func toggle() -> void:
	if visible:
		visible = false
		return
	var host := get_parent() as Control
	visible = true
	reset_size()
	var at := host.global_position + Vector2(0, -size.y - 6)
	var screen := get_viewport_rect().size
	global_position = Vector2(clampf(at.x, 4, screen.x - size.x - 4), maxf(at.y, 4))
	_timer = SHOW_TIME

func _process(delta: float) -> void:
	if visible:
		_timer -= delta / maxf(Engine.time_scale, 0.001)
		if _timer <= 0.0:
			visible = false
