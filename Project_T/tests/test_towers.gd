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

	var dream_state: DreamState = main.get_node("%DreamState")
	_check(placer.get_buildable_towers().size() == 2, "a run starts with only Sprout and Thornwall")
	_check(main.get_node("%TowerBar").get_child_count() == 2, "the tower bar shows only unlocked Wardens")
	dream_state.unlock_everything = true  # Test the whole roster
	dream_state.unlocks_changed.emit()
	await process_frame
	_check(placer.towers.size() == 11, "all eleven plantable Wardens are in the roster (%d)" % placer.towers.size())
	_check(not placer.towers.any(func(t: TowerData) -> bool: return t.parked), "parked Wardens (the Memory Wardens, cut for now) never are, even with Unlock all")
	placer.tower_data = load("res://resource/tower/white_stag.tres")
	_check(not placer._try_build(Vector2(3, 3)), "and can't be planted")
	placer.tower_data = placer.towers[0]
	_check(main.get_node("%TowerBar").get_child_count() == placer.towers.size(), "one HUD button per Warden")

	for data in placer.towers:
		_check(data.texture != null, "%s has a sprite" % data.display_name)
		_check(data.get_frame_rect(0).size == Vector2(64, 64), "%s frames are 64x64" % data.display_name)
		if data.can_attack and data.projectile_texture != null:
			var side: int = data.projectile_texture.get_width() / data.projectile_frames
			_check(side == data.projectile_texture.get_height() and side >= 16, "%s projectile frames are square (%dpx)" % [data.display_name, side])

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

	# --- Attack animations ---
	for data in placer.towers:
		if data.can_attack and data.attack_kind != TowerData.AttackKind.AURA:  # The White Stag has none
			_check(data.attack_texture != null
				and data.attack_texture.get_width() / data.attack_frame_count == 64,
				"%s has a 64x64 attack sheet" % data.display_name)
	for tower in tower_container.get_children():
		tower.set_process(false)
		tower._cooldown = 0.0
		tower._idle_search = 0.0  # Idle searches wait a jittered time: look right away
	var spawner = main.get_node("%EnemyContainer")
	var leaf_bug: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	# Clear creatures spawned before the spawner was stopped, so only the test's own are targets.
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

	# Projectile: winds up on the attack sheet, fires on the release frame, then idles again.
	var sprout: Tower = tower_container.get_child(0)
	var target = _spawn_still(spawner, leaf_bug, sprout.global_position)
	sprout.set_process(true)
	await process_frame
	await process_frame
	_check(sprout.sprite.texture == sprout.tower_data.attack_texture, "Sprout plays its attack animation")
	_check(target.health == target.max_health, "Sprout doesn't hit before its release frame")
	await _wait(0.8)
	_check(target.health < target.max_health, "Sprout's shot lands after the release frame")
	sprout.set_process(false)
	sprout._attack_time = -1.0
	sprout._show_idle()
	_check(sprout.sprite.texture == sprout.tower_data.texture, "Sprout returns to its idle loop")
	target.queue_free()

	# Pulse: soothes every creature in range at once, no projectile.
	var rootling: Tower = tower_container.get_child(6)
	var no_crit: TowerData = rootling.tower_data.duplicate()
	no_crit.crit_chance = 0.0  # A crit would make the exact-damage check flake
	rootling.tower_data = no_crit
	rootling._apply_data()
	for tower in tower_container.get_children():
		tower.set_process(false)  # Only the pulse below: any Warden's own cooldown could fire too (a timing flake)
	var near_a = _spawn_still(spawner, leaf_bug, rootling.global_position + Vector2(40, 0))
	var near_b = _spawn_still(spawner, leaf_bug, rootling.global_position + Vector2(0, -40))
	var far = _spawn_still(spawner, leaf_bug, rootling.global_position + Vector2(1000, 0))
	await process_frame
	rootling._release()
	var damage := int(rootling.get_damage())  # Its real damage (an Acorn built beside it adds its aura; fractions carry)
	_check(near_a.health == near_a.max_health - damage and near_b.health == near_b.max_health - damage,
		"Rootling's pulse soothes every creature in range")
	_check(far.health == far.max_health, "Rootling's pulse doesn't reach creatures out of range")
	_check(not rootling.get_children().any(func(c: Node) -> bool: return c is Projectile), "a pulse fires no projectile")

	# A beam whose target is dispelled goes back to the idle sheet (it held the 6-frame attack pose, and
	# the idle loop then asked for frames 6 and 7: "Index p_frame out of bounds").
	var midsummer: Tower = placer.tower_scene.instantiate()
	midsummer.tower_data = load("res://resource/tower/midsummer.tres")
	midsummer.cell = Vector2(1, 1)
	midsummer.position = Tower.MAP_GRID.calculate_map_position(Vector2(1, 1))
	tower_container.add_child(midsummer)
	midsummer.set_process(false)
	var beamed = _spawn_still(spawner, leaf_bug, midsummer.global_position + Vector2(40, 0))
	midsummer._update_beam(0.1)
	_check(midsummer.sprite.hframes == midsummer.tower_data.attack_frame_count, "Midsummer holds its attack pose while beaming")
	beamed.dispel()
	await process_frame
	midsummer._update_beam(0.1)
	_check(midsummer.sprite.hframes == midsummer.tower_data.frame_count, "and returns to its idle sheet when the target is gone")

	# --- Swoops fly back to their Warden (they used to fly to the map's top-left corner: the projectile
	# took its home in _ready before fire_at had placed it) ---
	var nest: Tower = placer.tower_scene.instantiate()
	nest.tower_data = load("res://resource/tower/nestling.tres")
	nest.cell = Vector2(8, 8)
	nest.position = Tower.MAP_GRID.calculate_map_position(Vector2(8, 8))
	tower_container.add_child(nest)
	nest.set_process(false)
	var prey = _spawn_still(spawner, leaf_bug, nest.global_position + Vector2(100, 0))
	nest.fire_at(prey)
	var swoop: Projectile = null
	for child in nest.get_children():
		if child is Projectile:
			swoop = child
	var start := nest.global_position + nest.tower_data.get_attack_origin()
	_check(swoop != null and swoop._home.distance_to(start) < 1.0, "a swoop's home is its Warden (%s)" % (swoop._home if swoop else null))
	var last_seen := Vector2.ZERO
	for i in 180:
		if not is_instance_valid(swoop):
			break
		last_seen = swoop.global_position
		await process_frame
	_check(not is_instance_valid(swoop) and last_seen.distance_to(start) < 20.0,
		"it flies back and vanishes at the Warden (last seen %s, Warden %s)" % [last_seen, start])

	_check(TowerPlacer.is_edge_cell(Vector2(0, 5)) and TowerPlacer.is_edge_cell(Vector2(5, Tower.MAP_GRID.size.y - 1))
		and not TowerPlacer.is_edge_cell(Vector2(5, 5)), "the island's rim is \"the dream's edge\"")
	print("towers test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _wait(seconds: float) -> void:
	await create_timer(seconds, true, true).timeout

# A creature standing still at `position` (still targetable, remaining distance from spawn).
func _spawn_still(spawner, data: EnemyData, position: Vector2) -> Node2D:
	spawner.spawn_enemy(data)
	var enemy = spawner.get_child(spawner.get_child_count() - 1)
	enemy.set_process(false)
	enemy.global_position = position
	return enemy

# A buildable cell beside the path that keeps the path open.
func _cell_next_to_path(map_generator, path: PackedVector2Array) -> Vector2:
	for i in range(4, path.size()):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = path[i] + offset
			if not path.has(cell) and map_generator.can_block(cell):
				return cell
	return Vector2(-1, -1)
