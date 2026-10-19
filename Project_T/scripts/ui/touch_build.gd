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
const PHONE_BUTTON_W := 150.0  # Phones: Confirm, Cancel and Done the same width
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
var _sell := Button.new()  # Phones: sell mode (TowerSeller.set_sell_mode; desktop: X while building)
var _sell_marks := Button.new()  # Phones in sell mode: "Sell N  +X" sells the marked Wardens (TowerSeller.sell_marked_now)
var seller: Node = null
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
	if UiStyle.is_phone():
		offset_bottom = -32.0  # Phones: level with the Warden dock, in the bottom centre it leaves free (hud.gd PHONE_CENTRE_RESERVE)
	offset_top = offset_bottom - BUTTON_HEIGHT
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for pair in [[_plant, "Confirm", _on_plant], [_cancel, "Cancel", _on_cancel]]:
		var button: Button = pair[0]
		button.text = pair[1]
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(170 if button == _plant else 110, BUTTON_HEIGHT)
		if UiStyle.is_phone():
			button.custom_minimum_size.x = PHONE_BUTTON_W  # Confirm / Cancel / Done one size (UI Asset review 2026-10-15)
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(pair[2])
		if button == _plant:
			UiStyle.primary(button)  # The default (button rule)
		add_child(button)
	# Phones, sell confirm (user 2026-10-17): the primary beside Cancel while Wardens are marked to sell.
	_sell_marks.name = "SellMarked"
	_sell_marks.focus_mode = Control.FOCUS_NONE
	_sell_marks.custom_minimum_size = Vector2(PHONE_BUTTON_W, BUTTON_HEIGHT)
	_sell_marks.add_theme_font_size_override("font_size", 18)
	_sell_marks.tooltip_text = "Sell the marked Wardens."
	_sell_marks.pressed.connect(_on_sell_marks)
	_sell_marks.visible = false
	UiStyle.primary(_sell_marks)
	add_child(_sell_marks)
	move_child(_sell_marks, _cancel.get_index())  # Confirm / Sell N, then Cancel
	# Build mode stays on after each placement (user 2026-10-06, the one-shot reversed): touch stops it here.
	_done.text = "Done"
	_done.focus_mode = Control.FOCUS_NONE
	_done.custom_minimum_size = Vector2(110, BUTTON_HEIGHT)
	_done.add_theme_font_size_override("font_size", 18)
	if UiStyle.is_phone():
		_done.custom_minimum_size.x = PHONE_BUTTON_W
		UiStyle.primary(_done)  # Phones: Done is the primary when it shows instead of Confirm (it never shows beside it)
	_done.tooltip_text = "Stop building."
	_done.pressed.connect(_on_done)
	add_child(_done)
	# Phones: Sell beside Done (Tower Code a5d16d5f). On, a tap on a Warden sells it on release (a pan never does);
	# off again, building resumes with the same Warden. Picking a Warden on the bar ends it by itself.
	_sell.name = "SellToggle"
	_sell.text = "Sell"
	_sell.toggle_mode = true
	_sell.focus_mode = Control.FOCUS_NONE
	_sell.custom_minimum_size = Vector2(110, BUTTON_HEIGHT)
	_sell.add_theme_font_size_override("font_size", 18)
	_sell.tooltip_text = "Tap a Warden to sell it."
	_sell.toggled.connect(_on_sell_toggled)
	add_child(_sell)
	move_child(_sell, _done.get_index())  # Sell, Done
	if tower_placer != null:
		seller = tower_placer.get_node_or_null("%TowerSeller")
	if seller != null and seller.has_signal("sell_mode_changed"):
		seller.sell_mode_changed.connect(func(on: bool) -> void:
			_sell.set_pressed_no_signal(on)
			_refresh())
	if seller != null and seller.has_signal("select_mode_changed"):
		seller.select_mode_changed.connect(func(_on: bool) -> void: _refresh())
	if seller != null and seller.has_signal("sell_marks_changed"):
		seller.sell_marks_changed.connect(_refresh)
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
	var selling: bool = mobile_controls() and seller != null and bool(seller.get("sell_mode"))
	var selecting: bool = mobile_controls() and seller != null and bool(seller.get("select_mode"))  # Done ends it (user 2026-10-18)
	var marks: Array = _marks()
	var marked := selling and not marks.is_empty()
	visible = touch_mode and (pending or building or selling or selecting)  # Done all through build (and sell) mode, Confirm / Cancel with pending Wardens
	# Not under a full-screen screen (a Dream, the pause menu …): it showed through the Dream screen's bottom row (user
	# screenshot 2026-10-16). It comes back when the screen closes (_process).
	_under_modal = visible and camera != null and camera.has_method("modal_open") and camera.modal_open()
	if _under_modal:
		visible = false
	_plant.visible = pending
	_sell_marks.visible = marked and not pending
	_cancel.visible = pending or marked
	_done.visible = (building or selling or selecting) and not pending and not marked
	if marked:
		_sell_marks.text = "Sell %d  %s" % [marks.size(), UiStyle.dew_amount(seller.get_marked_refund(), true)]
	# (Phone layouts: Sell is the Warden dock's last slot, hud.gd sell_slot.)
	_sell.visible = mobile_controls() and not UiStyle.is_phone() and seller != null and seller.has_method("set_sell_mode") \
		and (building or selling) and not pending
	if visible and tower_placer.has_method("get_stroke_tag"):
		var plan: Dictionary = tower_placer.get_stroke_plan()
		var count: int = plan.values().count("")
		_plant.text = ("Confirm (%d)" if mobile_controls() else "Plant %d") % count
		_plant.tooltip_text = tower_placer.get_stroke_tag()
		_plant.disabled = plan.values().count("") == 0

var _under_modal := false  # Hidden only because a full-screen screen is up

func _process(_delta: float) -> void:
	if visible or _under_modal:
		_refresh()  # The plan changes as Dew and the board change

func _on_plant() -> void:
	var planted: int = tower_placer.plant_stroke()
	if tower_placer.has_method("after_player_placement"):
		tower_placer.after_player_placement(planted > 0)  # TowerPlacer's hook (build mode now stays on: Done stops it)
	if mobile_controls():
		tower_placer.set_build_mode(false)  # Phones: Confirm ends building (user 2026-10-16); pick a Warden to build again
	_refresh()

# Done: out of sell mode, Select mode, or build mode.
func _on_done() -> void:
	if seller != null and bool(seller.get("sell_mode")):
		seller.set_sell_mode(false)
	elif seller != null and bool(seller.get("select_mode")):
		seller.set_select_mode(false)
	elif tower_placer != null:
		tower_placer.set_build_mode(false)
	_refresh()

func _on_sell_toggled(on: bool) -> void:
	if seller == null or not seller.has_method("set_sell_mode"):
		return
	if on:
		seller.set_sell_mode(true)
	else:
		seller.set_sell_mode(false)
		if tower_placer != null and tower_placer.get("tower_data") != null:
			tower_placer.set_build_mode(true)  # Back to building the same Warden
	_refresh()

func _on_cancel() -> void:
	if not _marks().is_empty() and not bool(tower_placer.get("stroking")):
		seller.clear_sell_marks()  # Sell confirm: Cancel drops the marks (sell mode stays)
	else:
		tower_placer.cancel_stroke()
	_refresh()

# The touch bar's Sell N: sells the marked Wardens (TowerSeller's rules and refunds).
func _on_sell_marks() -> void:
	if seller != null and seller.has_method("sell_marked_now"):
		seller.sell_marked_now()
	_refresh()

# The Wardens marked to sell (phones' sell confirm).
func _marks() -> Array:
	if seller == null or not seller.has_method("get_sell_marks"):
		return []
	return seller.get_sell_marks()

func _input(event: InputEvent) -> void:
	# Before the pause menu's _unhandled_input (it would open from sell mode, where build mode is off)
	if mobile_controls() and event.is_action_pressed("open_menu") and _back():
		get_viewport().set_input_as_handled()
		return
	if mobile_controls() and _scroll_input(event):
		get_viewport().set_input_as_handled()
		return
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

# --- Phones: one finger scrolls any list it lands on (user 2026-10-17: "how to scroll on phone for codex and dreams") ---
# Godot's ScrollContainer only drag-scrolls when the drag starts on itself; on a phone a finger lands on a row, a button or
# a text label, which keep the drag. So: a single finger that goes down over a ScrollContainer able to scroll, and moves
# PAN_SLOP, scrolls the smallest such container under it; the row it started on gets a release far away, so the drag never
# presses it.
var _scroll: ScrollContainer = null
var _scroll_finger := -1
var _scroll_from := Vector2.ZERO
var _scrolling := false

func _scroll_input(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		if event.pressed and _touches.is_empty():
			_scroll = _scroll_under(event.position)
			_scroll_finger = event.index if _scroll != null else -1
			_scroll_from = event.position
			_scrolling = false
		elif not event.pressed and event.index == _scroll_finger:
			_scroll = null  # (The release still reaches TouchBuild's own bookkeeping below)
			_scroll_finger = -1
			_scrolling = false
		elif event.pressed:
			_scroll_finger = -1  # A second finger: a pinch, not a scroll
			_scroll = null
		return false
	if not (event is InputEventScreenDrag) or event.index != _scroll_finger or not is_instance_valid(_scroll):
		return false
	if not _scrolling:
		if event.position.distance_to(_scroll_from) < PAN_SLOP:
			return false
		_scrolling = true
		_cancel_press()
	var scale := _scroll.get_global_transform_with_canvas().get_scale()
	var by: Vector2 = event.relative / Vector2(maxf(scale.x, 0.01), maxf(scale.y, 0.01))
	if _scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		_scroll.scroll_vertical -= roundi(by.y)
	if _scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		_scroll.scroll_horizontal -= roundi(by.x)
	_moved = true  # Not a tap, never a map pan
	return true

# Phones: every button inside `root` (now and added later) at least `min_h` tall (user 2026-10-17: "some buttons are too
# small" in the Codex and the Dreams list). Cheap: one type check per node added.
static func grow_taps(root: Control, min_h: float = 44.0) -> void:
	if root == null or not UiStyle.is_phone() or not root.is_inside_tree():
		return
	for node in root.find_children("*", "BaseButton", true, false):
		_grow_tap(node as Control, min_h)
	_tap_roots.append([weakref(root), min_h])
	if not root.get_tree().node_added.is_connected(_on_node_added):  # One connection for every root (a bind per root
		root.get_tree().node_added.connect(_on_node_added)  # read as the same callable: "already connected")

static var _tap_roots: Array = []  # [WeakRef to the root, min_h]

static func _on_node_added(node: Node) -> void:
	if not (node is BaseButton):
		return
	_tap_roots = _tap_roots.filter(func(entry: Array) -> bool: return entry[0].get_ref() != null)
	for entry in _tap_roots:
		var root: Control = entry[0].get_ref()
		if root.is_ancestor_of(node):
			_grow_tap(node as Control, entry[1])
			return

static func _grow_tap(button: Control, min_h: float) -> void:
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, min_h)

# The smallest visible ScrollContainer under `at` (screen px) whose content is bigger than it, or null.
func _scroll_under(at: Vector2) -> ScrollContainer:
	var best: ScrollContainer = null
	var best_area := INF
	for node in get_tree().root.find_children("*", "ScrollContainer", true, false):
		var sc := node as ScrollContainer
		if sc == null or not sc.is_visible_in_tree():
			continue
		var rect: Rect2 = sc.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, sc.size)
		if not rect.has_point(at) or not _can_scroll(sc):
			continue
		var area := rect.size.x * rect.size.y
		if area < best_area:
			best_area = area
			best = sc
	return best

func _can_scroll(sc: ScrollContainer) -> bool:
	var v := sc.get_v_scroll_bar()
	var h := sc.get_h_scroll_bar()
	var vertical := sc.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED and v != null and v.max_value > v.page + 0.5
	var horizontal := sc.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED and h != null and h.max_value > h.page + 0.5
	return vertical or horizontal

# The control the finger went down on was pressed by the emulated mouse: release it far away, so it never fires.
func _cancel_press() -> void:
	var release := InputEventMouseButton.new()
	release.device = InputEvent.DEVICE_ID_EMULATION
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(-10000, -10000)
	release.global_position = release.position
	get_viewport().push_input.call_deferred(release)

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
		if tower_placer != null and tower_placer.has_method("touch_claims") and tower_placer.touch_claims():
			return  # The finger moves a pending Warden or draws a line
		if seller != null and seller.has_method("select_claims") and seller.select_claims():
			return  # Select mode: one finger draws the selection box (TowerSeller)
		if not _moved and event.position.distance_to(_map_from) >= PAN_SLOP:
			_moved = true
			if camera != null:
				camera.pan_screen(event.position - event.relative - _map_from)  # Catch up the slop: the map stays under the finger
		if _moved:
			if camera != null:
				camera.pan_screen(event.relative)
			get_viewport().set_input_as_handled()

# Android Back (open_menu, Mobile code 36d73487) while building, one step at a time: drop the pending Wardens, then the
# Wardens marked to sell, then leave sell mode, then Select mode, then stop building (the pause menu ignores it in build
# mode). Returns whether it did something.
func _back() -> bool:
	if tower_placer == null or (camera != null and camera.has_method("modal_open") and camera.modal_open()):
		return false  # A screen is up: Back is its own
	if bool(tower_placer.get("stroking")):
		tower_placer.cancel_stroke()
	elif not _marks().is_empty():
		seller.clear_sell_marks()
	elif seller != null and bool(seller.get("sell_mode")):
		_on_sell_toggled(false)  # Back to building the same Warden, as the Sell toggle does
	elif seller != null and bool(seller.get("select_mode")):
		seller.set_select_mode(false)
	elif bool(tower_placer.get("build_mode")):
		tower_placer.set_build_mode(false)
	else:
		return false
	_refresh()
	return true

func _other_touch(index: int) -> Vector2:
	for i in _touches:
		if i != index:
			return _touches[i]
	return Vector2.ZERO

func is_two_finger() -> bool:
	return _touches.size() >= 2
