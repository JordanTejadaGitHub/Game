extends SceneTree

# Headless test for area attacks you can see (story chat; art Tower Assets a15e9b9b): a PULSE release plays
# area_pulse_<style> scaled to the live range (not capped like a flash), a spark per nightmare touched, and the faint
# range ring; Tower.attack_shape() names the attack's shape for the UI.
#   godot --headless --path . --script res://tests/test_area_pulse.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_area_pulse_%d.json" % OS.get_process_id()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var spawner = main.get_node("%EnemyContainer")
	var map = main.get_node("%MapGenerator")
	for child in spawner.get_children():
		child.queue_free()
	await process_frame
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var on_route: Vector2 = Tower.route_cells(route)[6]
	var beside := _beside(map, Tower.route_cells(route))
	var rootling: Tower = placer.tower_scene.instantiate()
	rootling.tower_data = load("res://resource/tower/rootling.tres")
	rootling.cell = beside
	rootling.position = Tower.MAP_GRID.calculate_map_position(beside)
	placer.tower_container.add_child(rootling)
	rootling.set_process(false)
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"), 50.0)
	var enemy = spawner.get_child(spawner.get_child_count() - 1)
	enemy.set_process(false)
	enemy.global_position = rootling.global_position + Vector2(40, 0)
	await process_frame

	var world := Reactions._world(rootling)
	var before := world.get_children().size()
	rootling._release_attack()
	var ring: Node2D = null
	var sparks := 0
	var flash := false
	for n in world.get_children():
		if String(n.name).begins_with("Fx_area_pulse_root"):
			ring = n
		elif String(n.name).begins_with("Fx_root_snap"):
			sparks += 1
		elif n is Tower.RangeFlash:
			flash = true
	_check(world.get_children().size() > before and ring != null, "a Rootling's pulse plays the root ring")
	var drawn: float = ring._scale if ring != null else 0.0  # FxSprite keeps its scale itself
	_check(is_equal_approx(drawn * Tower.PULSE_ART_RADIUS, rootling.get_range_pixels()),
		"…scaled to its range, not capped like a flash (scale %.2f, range %.0f px)" % [drawn, rootling.get_range_pixels()])
	_check(sparks >= 1, "a spark on the nightmare it touched (%d)" % sparks)
	_check(flash, "the range ring flashes faintly")

	# The shape the UI shows.
	_check(Tower.attack_shape(load("res://resource/tower/rootling.tres")) == &"area", "Rootling: area")
	_check(Tower.attack_shape(load("res://resource/tower/sporeling.tres")) == &"single", "Sporeling: single target")
	_check(Tower.attack_shape(load("res://resource/tower/cairn.tres")) == &"splash", "Cairn: splash")
	_check(Tower.attack_shape(load("res://resource/tower/thornwall.tres")) == &"none", "Thornwall: no attack")
	_check(Tower.ATTACK_SHAPE_NAMES.has(Tower.attack_shape(load("res://resource/tower/bloomcap.tres"))), "every shape has a name")

	print("area pulse test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _beside(map, cells: PackedVector2Array) -> Vector2:
	for c in cells.slice(4, cells.size() - 4):
		for side in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			if not cells.has(c + side) and map.is_buildable(c + side):
				return c + side
	return Vector2(5, 5)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + what)
