extends SceneTree

# Headless test: a Warden that doesn't attack (Thornwall) takes no damage or speed aura (user: a selected Thornwall
# showed "+30% speed" and "+5% dmg" threads), so BuffSources lists nothing for it and it shows no buff pips; an attacker
# beside the same supports still gets both; and a wall doesn't count toward Grove Heart's per-Warden bonus. Run:
#   godot --headless --path . --script res://tests/test_wall_auras.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var container: Node = main.get_node("%TowerContainer")
	var plant := func(id: String, cell: Vector2) -> Tower:
		var tower: Tower = placer.tower_scene.instantiate()
		tower.tower_data = load("res://resource/tower/%s.tres" % id)
		tower.cell = cell
		tower.position = Tower.MAP_GRID.calculate_map_position(cell)
		container.add_child(tower)
		tower.set_process(false)
		return tower
	plant.call("elder_stump", Vector2(10, 9))
	plant.call("acorn", Vector2(10, 10))
	var wall: Tower = plant.call("thornwall", Vector2(11, 9))
	var attacker: Tower = plant.call("sporeling", Vector2(9, 9))
	await process_frame
	for tower in [wall, attacker]:
		tower._refresh_neighbours()
	_check(wall._aura_speed == 0.0 and wall._aura_damage == 0.0 and wall._aura_sources.is_empty(),
		"a Thornwall takes no aura (speed %.2f, damage %.2f)" % [wall._aura_speed, wall._aura_damage])
	_check(BuffSources.for_tower(wall).filter(func(e) -> bool: return e.stat in ["damage", "attack_speed"]).is_empty(),
		"no Buffs rows for the wall")
	_check(BuffSources.pips(wall).is_empty(), "no buff pips under the wall")
	_check(attacker._aura_speed > 0.0 and attacker._aura_damage > 0.0, "an attacker beside them still gets both")

	var heart: Tower = plant.call("grove_heart", Vector2(14, 12))
	plant.call("thornwall", Vector2(15, 12))
	plant.call("thornwall", Vector2(14, 13))
	await process_frame
	heart._refresh_neighbours()
	_check(heart._aura_count == 0, "walls don't count toward Grove Heart's bonus (%d)" % heart._aura_count)

	print("wall auras test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
