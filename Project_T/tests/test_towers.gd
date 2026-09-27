extends SceneTree

# Headless Warden roster test. Run from the project folder:
#   godot --headless --path . --script res://tests/test_towers.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var map_generator = main.get_node("%MapGenerator")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var tower_container: Node = main.get_node("%TowerContainer")
	var run_state = main.get_node("%RunState")
	main.get_node("%EnemyContainer")._auto_spawn_data = null  # Stop the temporary endless spawner

	_check(placer.towers.size() == 8, "all eight Wardens are buildable")
	_check(main.get_node("%TowerBar").get_child_count() == placer.towers.size(), "one HUD button per Warden")

	for data in placer.towers:
		_check(data.texture != null, "%s has a sprite" % data.display_name)
		_check(data.get_frame_rect(0).size == Vector2(64, 64), "%s frames are 64x64" % data.display_name)
		if data.can_attack and data.projectile_texture != null:
			_check(data.projectile_texture.get_width() / data.projectile_frames == 16,
				"%s projectile frames are 16x16" % data.display_name)

		run_state.dew = 1000  # Test the roster, not the economy
		placer.select_tower(data)
		_check(placer.build_mode and placer.tower_data == data, "selecting %s enters build mode" % data.display_name)
		var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
		var cell := _cell_next_to_path(map_generator, path)
		var count := tower_container.get_child_count()
		placer._try_build(cell)
		_check(tower_container.get_child_count() == count + 1, "%s can be built" % data.display_name)
		var tower: Tower = tower_container.get_child(count)
		_check(tower.tower_data == data and tower.sprite.hframes == data.frame_count,
			"%s tower uses its sheet" % data.display_name)

	await _wait(0.5)
	var thornwall: Tower = tower_container.get_child(1)
	_check(thornwall.tower_data.display_name == "Thornwall" and thornwall.get_child_count() == 1,
		"Thornwall never fires (only its sprite as a child)")

	print("towers test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _wait(seconds: float) -> void:
	await create_timer(seconds, true, true).timeout

# A buildable cell beside the path that keeps the path open.
func _cell_next_to_path(map_generator, path: PackedVector2Array) -> Vector2:
	for i in range(4, path.size()):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = path[i] + offset
			if not path.has(cell) and map_generator.can_block(cell):
				return cell
	return Vector2(-1, -1)
