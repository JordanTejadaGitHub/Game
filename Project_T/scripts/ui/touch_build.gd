extends HBoxContainer
class_name TouchBuild

# Touch for drag to build (screens_ui.md "Planting several Wardens: drag to build", Touch) and the
# map's two-finger gestures:
# - On touch, strokes don't plant on release (TowerPlacer.confirm_on_release = false): while one is
#   pending (TowerPlacer.stroke_changed) a Plant button ("Plant 6 · 30 Dew") and Cancel show above the
#   Warden bar. The mouse keeps release-to-plant.
# - Two fingers drag the map (and pinch zooms), in and out of build mode; a stroke the first finger
#   started is dropped, so a pan never plants.
# Touch mode turns on with the first screen touch and off with real mouse movement. Made by the HUD.

const BUTTON_HEIGHT := 52.0

var tower_placer: Node
var camera: Node
var touch_mode := false
var _plant := Button.new()
var _cancel := Button.new()
var _touches := {}  # Finger index -> screen position

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
	for pair in [[_plant, "Plant", _on_plant], [_cancel, "Cancel", _on_cancel]]:
		var button: Button = pair[0]
		button.text = pair[1]
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(150 if button == _plant else 110, BUTTON_HEIGHT)
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(pair[2])
		add_child(button)
	visible = false
	if tower_placer != null and tower_placer.has_signal("stroke_changed"):
		tower_placer.stroke_changed.connect(func(_active: bool) -> void: _refresh())

func set_touch_mode(on: bool) -> void:
	if touch_mode == on:
		return
	touch_mode = on
	if tower_placer != null and "confirm_on_release" in tower_placer:
		tower_placer.confirm_on_release = not on
	_refresh()

func _refresh() -> void:
	var pending: bool = tower_placer != null and bool(tower_placer.get("stroking"))
	visible = touch_mode and pending
	if visible and tower_placer.has_method("get_stroke_tag"):
		var plan: Dictionary = tower_placer.get_stroke_plan()
		_plant.text = "Plant %d" % plan.values().count("")
		_plant.tooltip_text = tower_placer.get_stroke_tag()
		_plant.disabled = plan.values().count("") == 0

func _process(_delta: float) -> void:
	if visible:
		_refresh()  # The plan changes as the stroke grows

func _on_plant() -> void:
	tower_placer.plant_stroke()
	_refresh()

func _on_cancel() -> void:
	tower_placer.cancel_stroke()
	_refresh()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		set_touch_mode(true)
		if event.pressed:
			_touches[event.index] = event.position
			if _touches.size() == 2 and tower_placer != null and bool(tower_placer.get("stroking")):
				tower_placer.cancel_stroke()  # Two fingers pan: never a stroke
		else:
			_touches.erase(event.index)
	elif event is InputEventScreenDrag:
		set_touch_mode(true)
		if _touches.size() >= 2 and _touches.has(event.index):
			var before: Vector2 = _touches[event.index]
			var other := _other_touch(event.index)
			_touches[event.index] = event.position
			if camera != null:
				camera.pan_screen(event.relative / _touches.size())  # Each finger moves the map its share
				var span_before := before.distance_to(other)
				var span_after: float = event.position.distance_to(other)
				if span_before > 8.0:
					camera.zoom_by(span_after / span_before)
			get_viewport().set_input_as_handled()  # Not a stroke, not a drag box
		elif _touches.has(event.index):
			_touches[event.index] = event.position
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		set_touch_mode(false)  # A real mouse

func _other_touch(index: int) -> Vector2:
	for i in _touches:
		if i != index:
			return _touches[i]
	return Vector2.ZERO

func is_two_finger() -> bool:
	return _touches.size() >= 2
