extends SceneTree

# Headless test for the touch controls (platforms.md "Touch controls", TouchBuild; user 2026-10-06: one finger
# scrolls, two fingers zoom, taps place pending Wardens and Confirm builds them). Real screen touches go through
# Input (mouse emulation on, as on a phone). Never touches the player's saves.
#   godot --headless --path . --script res://tests/test_touch_controls.gd --fixed-fps 60

var failures := 0
var main: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	TouchBuild.force_mobile = true  # The phone controls (mobile only)
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	root.size = Vector2i(1280, 720)
	var map_generator = main.get_node("%MapGenerator")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var container: Node = main.get_node("%TowerContainer")
	var camera = main.get_node("GameCameraNode")
	var touch: TouchBuild = main.get_node("HUD").get_children().filter(func(c: Node) -> bool: return c is TouchBuild).front()
	main.get_node("%RunState").dew = 500
	for child in main.get_node("%EnemyContainer").get_children():
		child.queue_free()
	for i in 10:
		await process_frame  # The first rest's screens open by themselves
	_close_screens()
	await process_frame
	_check(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch", true), "touches emulate the mouse (taps press buttons)")
	var start_button: Button = main.get_node("HUD/DriftPanel").find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text.begins_with("Start")).front()
	_check(not start_button.text.contains("(Enter)") and not UiStyle.key_chip("Q").visible, "phones show no keyboard hints (%s)" % start_button.text)

	# Build mode by touch: taps add pending Wardens, nothing is planted yet
	_close_screens()
	touch.set_touch_mode(true)  # As the first screen touch does
	_check(TouchBuild.is_touch() and placer.tap_to_place, "a touch switches to tap-to-place")
	placer.select_tower(load("res://resource/tower/thornwall.tres"))
	var cells := _free_cells(map_generator, 3)
	_check(cells.size() == 3, "three free cells beside the route")
	var before: int = container.get_child_count()
	for cell in cells:
		await _tap(_screen_of(MAP_GRID_CELL(cell)))
	_check(placer.stroking and placer.get_stroke_cells().size() == 3 and container.get_child_count() == before,
		"three taps: three pending Wardens, none planted yet (%d pending)" % placer.get_stroke_cells().size())
	touch._refresh()
	_check(touch.visible and touch._plant.visible and touch._plant.text == "Confirm (3)", "Confirm shows the count (%s)" % touch._plant.text)
	await _tap(_screen_of(MAP_GRID_CELL(cells[1])))
	_check(placer.get_stroke_cells().size() == 2, "a tap on a pending Warden takes it back")

	# One finger pans (and adds nothing); two fingers pinch zoom (and keep the pending ones)
	var cam_before: Vector2 = camera.target_position
	await _drag(_screen_of(MAP_GRID_CELL(cells[1])), Vector2(-120, -60))
	var moved: Vector2 = camera.target_position - cam_before
	_check(moved.x > 20.0 and moved.y > 10.0, "one finger drags the map the other way, as a page (%s → %s)" % [cam_before, camera.target_position])
	_check(placer.get_stroke_cells().size() == 2, "…and a pan never adds a pending Warden")
	_close_screens()  # The boss dossier opens by itself a few seconds into the first rest
	await process_frame
	var zoom_before: Vector2 = camera.target_zoom
	await _pinch(Vector2(640, 360), 240.0, 120.0)
	_check(camera.target_zoom.x < zoom_before.x, "pinching two fingers together zooms out (%s → %s)" % [zoom_before, camera.target_zoom])
	zoom_before = camera.target_zoom
	await _pinch(Vector2(640, 360), 120.0, 240.0)
	_check(camera.target_zoom.x > zoom_before.x, "spreading two fingers zooms in (%s → %s)" % [zoom_before, camera.target_zoom])
	_check(placer.stroking and placer.get_stroke_cells().size() == 2, "…the pending Wardens stay")

	# Confirm plants them all; build mode stays on (user 2026-10-06, the one-shot reversed)
	touch._plant.pressed.emit()
	_check(container.get_child_count() == before + 2 and not placer.stroking and placer.build_mode,
		"Confirm builds the two, build mode stays on (%d planted)" % (container.get_child_count() - before))
	_check(touch._done.visible, "Done shows while building with nothing pending")

	placer.select_tower(load("res://resource/tower/thornwall.tres"))
	await _tap(_screen_of(MAP_GRID_CELL(_free_cells(map_generator, 1)[0])))
	touch._cancel.pressed.emit()
	_check(not placer.stroking, "Cancel drops the pending Wardens")
	touch._done.pressed.emit()
	_check(not placer.build_mode, "Done stops building")
	placer.set_build_mode(false)
	await process_frame

	_close_screens()
	await process_frame
	# Outside build mode: a tap selects a Warden, a one-finger drag pans and never box-selects
	var planted: Tower = container.get_children().filter(func(t: Node) -> bool: return t is Tower).back()
	await _tap(_screen_of(planted.global_position))
	_check(seller.selection.has(planted), "a tap selects a Warden")
	await _tap(_screen_of(MAP_GRID_CELL(_free_cells(map_generator, 1)[0])))
	_check(seller.selection.is_empty(), "a tap on empty ground clears the selection")
	await _drag(_screen_of(planted.global_position), Vector2(-200, -150))
	_check(seller.selection.is_empty() and not seller._dragging, "a drag pans: no drag box, nothing selected")

	# A touch that starts on the HUD never pans the map
	var bar: Control = main.get_node("%TowerBar")
	cam_before = camera.target_position
	var slot: Control = bar.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.is_visible_in_tree()).front()
	await _drag(slot.get_global_rect().get_center(), Vector2(-150, 0))
	_check(camera.target_position.distance_to(cam_before) < 1.0, "a drag that starts on the Warden bar doesn't move the map")

	# Sell (phones, Tower Code's sell mode): the toggle beside Done; a tap sells, a pan never does; off = building again
	_close_screens()
	await process_frame
	placer.select_tower(load("res://resource/tower/thornwall.tres"))
	touch._refresh()
	_check(touch._sell.visible and touch._done.visible, "building: Sell and Done on the touch bar")
	touch._sell.button_pressed = true
	_check(seller.sell_mode and not placer.build_mode and touch.visible and touch._sell.button_pressed, "Sell turns sell mode on (the bar stays)")
	var victim: Tower = container.get_children().filter(func(t: Node) -> bool: return t is Tower and not t.is_queued_for_deletion()).back()
	var count_before: int = container.get_children().filter(func(t: Node) -> bool: return t is Tower and not t.is_queued_for_deletion()).size()
	await _drag(_screen_of(victim.global_position), Vector2(-90, 0))
	_check(is_instance_valid(victim) and not victim.is_queued_for_deletion(), "sell mode: a pan that starts on a Warden never sells it")
	victim = container.get_children().filter(func(t: Node) -> bool: return t is Tower and not t.is_queued_for_deletion()).back()
	await _tap(_screen_of(victim.global_position))
	var count_after: int = container.get_children().filter(func(t: Node) -> bool: return t is Tower and not t.is_queued_for_deletion()).size()
	_check(count_after == count_before - 1, "sell mode: a tap sells the Warden (%d → %d)" % [count_before, count_after])
	touch._sell.button_pressed = false
	_check(not seller.sell_mode and placer.build_mode, "Sell off: back to building")
	touch._sell.button_pressed = true
	touch._done.pressed.emit()
	_check(not seller.sell_mode and not placer.build_mode, "Done in sell mode leaves it")

	main.queue_free()
	await process_frame
	print("FAILURES: %d" % failures if failures > 0 else "PASS")
	quit(failures)

static func MAP_GRID_CELL(cell: Vector2) -> Vector2:
	return preload("res://resource/map/map_grid.tres").calculate_map_position(cell)

func _screen_of(world: Vector2) -> Vector2:
	return root.get_canvas_transform() * world if main.get_viewport() == root else world

func _close_screens() -> void:
	var pause_menu := main.get_node_or_null("HUD/PauseMenu")
	if pause_menu != null and pause_menu.visible:
		pause_menu.close()
	var whispers := main.get_node_or_null("HUD/Whispers") as CanvasItem
	if whispers != null:
		whispers.visible = false  # The first run's whisper card takes taps (a tap opens the Codex)
	for path in ["HUD/BossDossier", "HUD/FamilyPickScreen", "HUD/DreamScreen", "HUD/OmenScreen", "HUD/RememberScreen", "HUD/NightmareIntro"]:
		var screen := main.get_node_or_null(path) as CanvasItem
		if screen != null and screen.visible:
			if screen.has_method("close_dossier"):
				screen.close_dossier()
			else:
				screen.visible = false
	main.get_node("%GameSpeed").set_paused(false)

# Headless Godot doesn't route Input.parse_input_event to the window, so the events go in as a phone sends them: the
# first finger's emulated mouse event first (DEVICE_ID_EMULATION), then the touch itself.
func _send(event: InputEvent) -> void:
	root.push_input(event)

func _touch(index: int, at: Vector2, pressed: bool) -> void:
	if index == 0:
		var mouse := InputEventMouseButton.new()
		mouse.device = InputEvent.DEVICE_ID_EMULATION
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		mouse.pressed = pressed
		mouse.position = at
		mouse.global_position = at
		_send(mouse)
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = pressed
	_send(event)

func _move(index: int, at: Vector2, relative: Vector2) -> void:
	if index == 0:
		var mouse := InputEventMouseMotion.new()
		mouse.device = InputEvent.DEVICE_ID_EMULATION
		mouse.button_mask = MOUSE_BUTTON_MASK_LEFT
		mouse.position = at
		mouse.global_position = at
		mouse.relative = relative
		_send(mouse)
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = at
	event.relative = relative
	_send(event)

func _tap(at: Vector2) -> void:
	_touch(0, at, true)
	await process_frame
	_touch(0, at, false)
	await process_frame

func _drag(from: Vector2, by: Vector2) -> void:
	_touch(0, from, true)
	await process_frame
	var steps := 6
	for i in steps:
		_move(0, from + by * (i + 1) / float(steps), by / float(steps))
		await process_frame
	_touch(0, from + by, false)
	await process_frame

func _pinch(centre: Vector2, gap_from: float, gap_to: float) -> void:
	_touch(0, centre - Vector2(gap_from / 2.0, 0), true)
	_touch(1, centre + Vector2(gap_from / 2.0, 0), true)
	await process_frame
	var steps := 5
	for i in steps:
		var gap := lerpf(gap_from, gap_to, (i + 1) / float(steps))
		var last := lerpf(gap_from, gap_to, i / float(steps))
		_move(1, centre + Vector2(gap / 2.0, 0), Vector2((gap - last) / 2.0, 0))
		await process_frame
	_touch(0, centre - Vector2(gap_from / 2.0, 0), false)
	_touch(1, centre + Vector2(gap_to / 2.0, 0), false)
	await process_frame

# `count` buildable cells beside the route, apart from each other, that leave the route open together.
func _free_cells(map_generator, count: int) -> Array[Vector2]:
	var found: Array[Vector2] = []
	var path: PackedVector2Array = Tower.route_cells(map_generator.get_path_from(map_generator.startPath))
	for i in range(3, path.size(), 3):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = path[i] + offset
			if path.has(cell) or found.has(cell) or not map_generator.can_block(cell):
				continue
			if found.any(func(f: Vector2) -> bool: return f.distance_to(cell) < 2.5):
				continue
			found.append(cell)
			break
		if found.size() == count:
			break
	return found

func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   " + label)
	else:
		print("  FAIL " + label)
		failures += 1
