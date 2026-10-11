extends PanelContainer
class_name TapTip

# Attached icon help uses native hover tooltips. Clicking never opens a popup.
# Keep the text holder for live tooltip updates and explicit non-icon popups.

const SHOW_TIME := 3.0

var _label := Label.new()
var _timer := 0.0
var _host: Control = null

# Gives control hover-only help. Returns its text holder for live updates.
static func attach(control: Control, text: String) -> TapTip:
	control.tooltip_text = text
	if control.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		control.mouse_filter = Control.MOUSE_FILTER_PASS
	var tip := TapTip.new()
	tip._label.text = text
	tip._host = control
	control.add_child(tip)
	control.mouse_entered.connect(func() -> void:
		control.tooltip_text = tip._label.text)
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
	# Anchored to the control it explains: above it, flipped below, clamped (UiStyle.tip_beside).
	if host != null:
		global_position = UiStyle.tip_beside(UiStyle.canvas_rect(host), size, get_viewport_rect().size)
	else:
		global_position = UiStyle.tip_position(pointer, size, get_viewport_rect().size)
	_timer = SHOW_TIME

func _process(delta: float) -> void:
	if visible:
		_timer -= delta / maxf(Engine.time_scale, 0.001)
		if _timer <= 0.0:
			visible = false
