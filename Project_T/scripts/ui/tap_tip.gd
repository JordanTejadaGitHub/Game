extends PanelContainer
class_name TapTip

# Icon help: hover or tap, one tip at a time (screens_ui.md "Icon help update", user 2026-10-11; platforms.md: no
# hover-only information). TapTip.attach(control, text) gives `control` its native hover tooltip; a click or tap
# pins the same text in a popup beside it until the next click anywhere, Esc, or another icon. The two never show
# together: while a tip is pinned its icon's hover tooltip is off, and hovering or opening another icon closes the
# pinned one. The text holder (_label) is live: update it and the hover tooltip and the pinned tip both follow.
# Tips are opaque and draw on their own top layer (UiStyle.lift_tip), above every panel.

const SHOW_TIME := 3.0  # Kept for callers: a pinned tip no longer times out

static var _open_id := 0  # The pinned tip's instance id (0 = none). An id, never a node, in a static

var _label := Label.new()
var _host: Control = null
var _attached := false  # Made by attach(): it follows an icon (the others are opened by hand, e.g. the boss bar's marker)

# Gives `control` hover help that also pins on a click or tap. Returns the tip (its _label is the live text).
static func attach(control: Control, text: String) -> TapTip:
	control.tooltip_text = text
	if control.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		control.mouse_filter = Control.MOUSE_FILTER_PASS
	var tip := TapTip.new()
	tip._label.text = text
	tip._host = control
	tip._attached = true
	control.add_child(tip)
	control.mouse_entered.connect(func() -> void:
		var open := TapTip.pinned()
		if open != null and open != tip:
			open.close()  # Hovering another icon swaps: the pinned tip goes, this icon's hover tooltip shows
		if not tip.visible:
			control.tooltip_text = tip._label.text)  # Current text on every hover
	control.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			tip.toggle())
	return tip

# The tip pinned open now, or null.
static func pinned() -> TapTip:
	if _open_id == 0 or not is_instance_id_valid(_open_id):
		return null
	return instance_from_id(_open_id) as TapTip

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

# Pins the tip beside its control, or closes it when it's open. Any other pinned tip closes first.
func toggle() -> void:
	if visible:
		close()
		return
	var other := TapTip.pinned()
	if other != null and other != self:
		other.close()
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
	_open_id = get_instance_id()
	if is_instance_valid(_host):
		_host.tooltip_text = ""  # No hover tooltip beside the pinned tip: never two at once

func close() -> void:
	visible = false
	if _open_id == get_instance_id():
		_open_id = 0
	if is_instance_valid(_host):
		_host.tooltip_text = _label.text  # Hover help again

# While pinned: the next click anywhere, or Esc, closes it. A click on its own icon is left to that icon (it toggles).
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed:
		var on_host := is_instance_valid(_host) and _host.is_visible_in_tree() \
			and _host.get_global_rect().has_point(_host.get_global_mouse_position())
		if not (on_host and event.button_index == MOUSE_BUTTON_LEFT):
			close()  # Not consumed: the click still does what it was for
	elif event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()  # Esc closes only the tip

func _process(_delta: float) -> void:
	if visible and _attached and (not is_instance_valid(_host) or not _host.is_visible_in_tree()):
		close()  # Its icon went away

func _exit_tree() -> void:
	if _open_id == get_instance_id():
		_open_id = 0
