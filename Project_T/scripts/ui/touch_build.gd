extends HBoxContainer
class_name TouchBuild

# Touch controls (platforms.md "Touch controls"; user 2026-10-06: "one finger should be scrolling and two fingers is
# zooming in. … tapping should momentarily place it so that you can place multiple down, then a confirm button
# actually places it and builds it"):
# - One finger on the map drags it, in and out of build mode; two fingers pinch to zoom (and drag). A touch that moved
#   past PAN_SLOP is a pan, never a tap: gesture_moved() tells TowerPlacer, TowerSeller and ObstacleClearer.
# - In build mode each tap adds a pending Warden (a ghost) or takes one back (TowerPlacer.tap_to_place); Confirm
#   ("Confirm (3)") plants them all and Cancel drops them. No drag-to-build and no drag box on touch.
# - The Pin keeps build mode on after a Confirm (touch has no Shift).
# Those are the phone controls, mobile only (user, 2026-10-06: the Mobile chat's controls never change the PC game).
# A PC touch screen keeps the older touch flow: drag a line to build, Plant / Cancel, two fingers pan and pinch.
# Touch mode turns on with the first screen touch and off with real mouse movement. Made by the HUD.

const BUTTON_HEIGHT := 52.0
const PAN_SLOP := 14.0  # Screen pixels a finger moves before a touch is a pan instead of a tap

# The current gesture, for the map tools (static: there is one touch screen).
static var _touch := false
static var _moved := false
static var force_mobile := false  # Tests; a desktop run takes the launch flag `-- --mobile` instead

# The phone controls: Android / iOS builds (or force_mobile / `--mobile` for testing on a PC).
static func mobile_controls() -> bool:
	return force_mobile or OS.has_feature("mobile") or OS.get_cmdline_user_args().has("--mobile")

# Whether the phone controls are in use right now (a touch on mobile; a real mouse turns it off).
static func is_touch() -> bool:
	return _touch and mobile_controls()

# Whether the touch going on (or just lifted) panned or pinched: its release is not a tap.
static func gesture_moved() -> bool:
	return _touch and _moved

var tower_placer: Node
var camera: Node
var touch_mode := false
var _plant := Button.new()
var _cancel := Button.new()
var _done := Button.new()  # Stops build mode (it stays on after each placement; desktop: right-click or Esc)
var _touches := {}  # Finger index -> screen position
var _map_finger := -1  # The one finger that went down on the map (no HUD control took it): it pans
var _map_from := Vector2.ZERO

func _init(placer: Node = null, camera_node: Node = null) -> void:
	tower_placer = placer
	camera = camera_node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Building works while paused
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 12)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_bottom = -120.0  # Above the Warden bar
	offset_top = offset_bottom - BUTTON_HEIGHT
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for pair in [[_plant, "Confirm", _on_plant], [_cancel, "Cancel", _on_cancel]]:
		var button: Button = pair[0]
		button.text = pair[1]
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(170 if button == _plant else 110, BUTTON_HEIGHT)
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(pair[2])
		if button == _plant:
			UiStyle.primary(button)  # The default (button rule)
		add_child(button)
	# Build mode stays on after each placement (user 2026-10-06, the one-shot reversed): touch stops it here.
	_done.text = "Done"
	_done.focus_mode = Control.FOCUS_NONE
	_done.custom_minimum_size = Vector2(110, BUTTON_HEIGHT)
	_done.add_theme_font_size_override("font_size", 18)
	_done.tooltip_text = "Stop building."
	_done.pressed.connect(func() -> void:
		if tower_placer != null:
			tower_placer.set_build_mode(false))
	add_child(_done)
	visible = false
	if tower_placer != null and tower_placer.has_signal("stroke_changed"):
		tower_placer.stroke_changed.connect(func(_active: bool) -> void: _refresh())
	if tower_placer != null and tower_placer.has_signal("build_mode_changed"):
		tower_placer.build_mode_changed.connect(func(_on: bool) -> void: _refresh())

func set_touch_mode(on: bool) -> void:
	_touch = on
	if touch_mode == on:
		return
	touch_mode = on
	if tower_placer != null and "confirm_on_release" in tower_placer:
		tower_placer.confirm_on_release = not on
	if tower_placer != null and "tap_to_place" in tower_placer:
		tower_placer.tap_to_place = on and mobile_controls()
	_refresh()

func _refresh() -> void:
	var pending: bool = tower_placer != null and bool(tower_placer.get("stroking"))
	var building: bool = tower_placer != null and bool(tower_placer.get("build_mode"))
	visible = touch_mode and (pending or building)  # Done all through build mode, Confirm / Cancel with pending Wardens
	_plant.visible = pending
	_cancel.visible = pending
	_done.visible = building and not pending
	if visible and tower_placer.has_method("get_stroke_tag"):
		var plan: Dictionary = tower_placer.get_stroke_plan()
		var count: int = plan.values().count("")
		_plant.text = ("Confirm (%d)" if mobile_controls() else "Plant %d") % count
		_plant.tooltip_text = tower_placer.get_stroke_tag()
		_plant.disabled = plan.values().count("") == 0

func _process(_delta: float) -> void:
	if visible:
		_refresh()  # The plan changes as Dew and the board change

func _on_plant() -> void:
	var planted: int = tower_placer.plant_stroke()
	if tower_placer.has_method("after_player_placement"):
		tower_placer.after_player_placement(planted > 0)  # TowerPlacer's hook (build mode now stays on: Done stops it)
	_refresh()

func _on_cancel() -> void:
	tower_placer.cancel_stroke()
	_refresh()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		set_touch_mode(true)
		if event.pressed:
			if _touches.is_empty():
				_moved = false  # A new gesture
				_map_finger = -1
			_touches[event.index] = event.position
			if _touches.size() >= 2:
				_moved = true  # Two fingers: a pinch, never a tap
				if not mobile_controls() and tower_placer != null and bool(tower_placer.get("stroking")):
					tower_placer.cancel_stroke()  # PC touch: two fingers pan, never a dragged line
		else:
			_touches.erase(event.index)
			if event.index == _map_finger:
				_map_finger = -1
	elif event is InputEventScreenDrag:
		set_touch_mode(true)
		if _touches.size() >= 2 and _touches.has(event.index) and camera != null and camera.has_method("modal_open") \
				and camera.modal_open():
			_touches[event.index] = event.position  # A screen is up: its own scrolling, not the map
		elif _touches.size() >= 2 and _touches.has(event.index):
			var before: Vector2 = _touches[event.index]
			var other := _other_touch(event.index)
			_touches[event.index] = event.position
			if camera != null:
				camera.pan_screen(event.relative / _touches.size())  # Each finger moves the map its share
				var span_before := before.distance_to(other)
				var span_after: float = event.position.distance_to(other)
				if span_before > 8.0:
					camera.zoom_by(span_after / span_before)
			get_viewport().set_input_as_handled()  # Not a tap, not a pan of one finger
		elif _touches.has(event.index):
			_touches[event.index] = event.position
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		set_touch_mode(false)  # A real mouse

# One finger on the map (the touch reached here, so no HUD control took it) drags the view once it moved PAN_SLOP.
func _unhandled_input(event: InputEvent) -> void:
	if not mobile_controls():
		return  # PC touch: one finger draws build lines and drag boxes
	if event is InputEventScreenTouch and event.pressed and _touches.size() == 1:
		_map_finger = event.index
		_map_from = event.position
	elif event is InputEventScreenDrag and event.index == _map_finger and _touches.size() == 1:
		if camera != null and camera.has_method("modal_open") and camera.modal_open():
			return
		if not _moved and event.position.distance_to(_map_from) >= PAN_SLOP:
			_moved = true
			if camera != null:
				camera.pan_screen(event.position - event.relative - _map_from)  # Catch up the slop: the map stays under the finger
		if _moved:
			if camera != null:
				camera.pan_screen(event.relative)
			get_viewport().set_input_as_handled()

func _other_touch(index: int) -> Vector2:
	for i in _touches:
		if i != index:
			return _touches[i]
	return Vector2.ZERO

func is_two_finger() -> bool:
	return _touches.size() >= 2
