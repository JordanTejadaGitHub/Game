extends SceneTree

# Headless test for the nightmare card (scripts/ui/nightmare_info.gd, owner 2026-10-25 "update the enemy panel when you
# click or hover one"; UI council): a status chip per status (icons, not words), its words under the row on hover / tap
# with links, a locked chip's Hollow line filled (no raw {const:…}), the portrait, and PC click-to-pin (a click on the
# nightmare pins it, a click on the card keeps it, a click elsewhere lets go).
#   godot --headless --path . --script res://tests/test_nightmare_card.gd --fixed-fps 60

var PROFILE_PATH := "user://test_nightmare_card_profile_%d.json" % OS.get_process_id()  # Per process: parallel sessions share user://

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)

func _frames(n: int) -> void:
	for i in n:
		await process_frame

# A click: a press and its release (at `from` when given: a drag ending at `screen`)
func _release_at(info: Node, screen: Vector2, from: Vector2 = Vector2.INF) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = screen if from == Vector2.INF else from
	info.call("_input", press)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	event.position = screen
	info.call("_input", event)

func _run() -> void:
	HeartwoodMemory.file_path = PROFILE_PATH  # Never the player's profile
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE_PATH))
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _frames(10)
	var spawner: Node = main.get_node("%EnemyContainer")
	var info: Node = main.get_node("%NightmareInfo")
	var shade: Node2D = spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	shade.set_process(false)
	shade.statuses.apply(EnemyStatuses.DAMP, 2, 30.0)
	EnemyStatuses.feeding = true  # A Dream card's stacks: locked (section 36)
	shade.statuses.apply(EnemyStatuses.STATIC, 3, 30.0)
	EnemyStatuses.feeding = false
	info.test_pin = shade
	await _frames(3)

	# Chips, not words
	var damp_chip: Node = info._chips.find_child("Status_damp", false, false)
	var static_chip: Node = info._chips.find_child("Status_static", false, false)
	_check(info.visible and damp_chip != null and static_chip != null, "one chip per status (damp, static)")
	_check(KeywordIcons.pip_color(&"asleep") == Palette.BRUISE, "chips take the pip colours (asleep: Bruise)")
	var status_line := RegEx.create_from_string("\\w+ \\d+/\\d+")  # "Soak 2/8 · 30.0 s" (an Omen's " · " is fine)
	_check(status_line.search(info._body.get_parsed_text()) == null, "no status lines in the body (icons, not words): %s" % info._body.get_parsed_text())
	_check(info._numbers.text.begins_with("Health") and not info._numbers.text.contains("cells/s"), "one numbers line, no units: %s" % info._numbers.text)
	_check(info._portrait.texture != null, "the portrait shows the kind's frame")
	_check(String(info._chip_key).contains("static:3:1"), "the chip key marks the locked status (%s)" % info._chip_key)

	# A chip's words: on hover / tap, under the row, with links; the locked one's Hollow line filled
	info._show_note(EnemyStatuses.DAMP)
	await _frames(2)
	var note: String = info._chip_note.get_parsed_text()
	_check(info._chip_note.visible and note.begins_with(IconInfo.status_name(EnemyStatuses.DAMP)), "the damp chip's words show (%s)" % note)
	info._show_note(EnemyStatuses.STATIC)
	await _frames(2)
	note = info._chip_note.get_parsed_text()
	_check(note.contains("Hollow:") and not note.contains("{"), "the locked chip's words include a filled Hollow line (%s)" % note)
	info._show_note(&"")

	# PC click-to-pin (after the first-run camera glide has settled: the click aims at a fixed screen point)
	await _frames(120)
	info.test_pin = null
	var canvas: Transform2D = main.get_viewport().get_canvas_transform()
	shade.global_position = canvas.affine_inverse() * Vector2(300, 420)  # A fixed spot clear of the card (right) and the HUD
	var on_shade: Vector2 = canvas * shade.global_position
	_release_at(info, on_shade, on_shade + Vector2(40, 0))  # A drag (a camera pan) ending on it
	await _frames(2)
	_check(info._pinned == null, "a drag ending on a nightmare does not pin it")
	_release_at(info, on_shade)
	await _frames(2)
	_check(info._pinned == shade and info.visible, "a click on the nightmare pins the card")
	_release_at(info, (info as Control).get_global_rect().get_center())
	_check(info._pinned == shade, "a click on the card itself keeps the pin")
	_release_at(info, Vector2(300, 150))  # Empty map, clear of the card
	await _frames(2)
	_check(info._pinned == null, "a click elsewhere on the map lets go")
	_release_at(info, canvas * shade.global_position)
	var esc := InputEventAction.new()
	esc.action = &"cancel_build"
	esc.pressed = true
	info.call("_input", esc)
	_check(info._pinned == null, "Esc / right click (cancel_build) lets go of a pin")

	# A pinned nightmare dispelled: the card stays ("Dispelled") until the player lets go
	canvas = main.get_viewport().get_canvas_transform()  # (The camera may have moved since)
	shade.global_position = canvas.affine_inverse() * Vector2(300, 420)
	_release_at(info, canvas * shade.global_position)
	await _frames(2)
	_check(info._pinned == shade, "a click on the nightmare pins it again after Esc")
	var shade_name: String = shade.enemy_data.display_name
	shade.take_damage(shade.max_health * 10.0)
	await _frames(90)  # Longer than the hover card's DISPELLED_TIME
	_check(info.visible and info._title.text == shade_name + " · Dispelled"
		and info._numbers.text == "Health 0 / %d" % info._last_max,
		"a dispelled pinned nightmare's card stays with only what is still true (%s; %s)" % [info._title.text, info._numbers.text])
	info.call("_input", esc)
	await _frames(2)
	_check(not info.visible and info._pinned == null, "letting go of a dispelled pin closes its card")

	# Pinned: hovering another nightmare doesn't move the card (owner: "stay on the pinned until you let go")
	var kind: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	var a: Node2D = spawner.spawn_enemy(kind)
	var b: Node2D = spawner.spawn_enemy(load("res://resource/enemy/crow.tres"))
	for e in [a, b]:
		e.set_process(false)
	canvas = main.get_viewport().get_canvas_transform()  # (The camera may have moved since)
	a.global_position = canvas.affine_inverse() * Vector2(300, 420)
	b.global_position = canvas.affine_inverse() * Vector2(500, 420)
	_release_at(info, canvas * a.global_position)
	info.test_pin = b  # As if the pointer were on the other one
	await _frames(3)
	_check(info._target == a and info._title.text.begins_with(a.enemy_data.display_name), "a pin stays while another nightmare is hovered (%s)" % info._title.text)
	info.test_pin = null

	# A pinned nightmare that leaks (gone without a dispel): the card closes, no "Dispelled"
	a.queue_free()
	await _frames(3)
	_check(not info.visible and not info._has_pin and not info._title.text.contains("Dispelled"),
		"a leaked pinned nightmare closes its card without 'Dispelled' (%s)" % info._title.text)

	# A click on a Warden selects only the Warden (owner 2026-10-25), even with a nightmare right beside it
	var map_generator: Node = main.get_node("%MapGenerator")
	var path: PackedVector2Array = Tower.route_cells(map_generator.get_path_from(map_generator.startPath))
	var warden_cell := Vector2(-1, -1)
	var path_cell := Vector2(-1, -1)
	for i in range(3, path.size()):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			if warden_cell.x < 0 and not path.has(path[i] + offset) and map_generator.can_block(path[i] + offset):
				warden_cell = path[i] + offset
				path_cell = path[i]
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	(main.get_node("%RunState") as RunState).dew = 5000
	placer.select_tower(load("res://resource/tower/bellflower.tres"))
	_check(placer._try_build(warden_cell), "a Warden is built beside the path")
	placer.set_build_mode(false)
	await _frames(2)
	var grid: Grid = b.grid
	var warden_at: Vector2 = grid.calculate_map_position(warden_cell)
	b.global_position = warden_at.lerp(grid.calculate_map_position(path_cell), 0.4)  # Within HOVER_RADIUS of the click
	canvas = main.get_viewport().get_canvas_transform()
	_release_at(info, canvas * warden_at)
	await _frames(2)
	_check(not info._has_pin, "a click on a Warden doesn't pin the nightmare beside it")

	main.queue_free()
	await _frames(2)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE_PATH))
	print("nightmare card test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)
