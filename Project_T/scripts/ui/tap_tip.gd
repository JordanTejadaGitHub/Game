extends PanelContainer
class_name TapTip

# Tooltips that also work by tap (screens_ui.md "Stat and status icons", platforms.md: no
# hover-only information). TapTip.attach(control, text) sets the hover tooltip and, on a tap or
# click, shows the same text in a small popup by the pointer for a few seconds. Tapping again
# hides it. Tips are opaque and draw on their own top layer (UiStyle.tip_layer), above every panel,
# above-right of the pointer so they never cover what's being pointed at ("tips are opaque").

const SHOW_TIME := 3.0

var _label := Label.new()
var _timer := 0.0
var _host: Control = null

# Gives `control` a tooltip that also opens on tap. Returns the popup (for tests).
static func attach(control: Control, text: String) -> TapTip:
	control.tooltip_text = text
	if control.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		control.mouse_filter = Control.MOUSE_FILTER_PASS
	var tip := TapTip.new()
	tip._label.text = text
	tip._host = control
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
	add_theme_stylebox_override("panel", UiStyle.tip_panel())
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.tip_body(_label)  # Tip size (screens_ui.md playtest fixes 2026-09-30)
	add_child(_label)
	process_mode = Node.PROCESS_MODE_ALWAYS

func toggle() -> void:
	if visible:
		visible = false
		return
	var host := _host if is_instance_valid(_host) else get_parent() as Control
	var pointer := host.get_global_mouse_position() if host != null else Vector2.ZERO
	UiStyle.lift_tip(self, host)  # Above every panel and screen
	visible = true
	reset_size()
	global_position = UiStyle.tip_position(pointer, size, get_viewport_rect().size)
	_timer = SHOW_TIME

func _process(delta: float) -> void:
	if visible:
		_timer -= delta / maxf(Engine.time_scale, 0.001)
		if _timer <= 0.0:
			visible = false
