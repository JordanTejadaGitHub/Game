extends SceneTree

# Headless test for which Wardens a picked rule card pulses (CardBloom via DreamState.preview_card_impact, which asks
# Tower.is_reached_by_rule): a nightmare-side card about a status (Heavy Eyelids, Drowsy) reaches only the Wardens
# that apply it, never a Sprout; its Deepened version uses the same filter; a card with no Warden filter reaches none.
# Run from the project folder:
#   godot --headless --path . --script res://tests/test_card_bloom_targets.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var container: Node = main.get_node("%TowerContainer")
	var map: Node = main.get_node("%MapGenerator")
	var sprout := _plant(placer, container, map, load("res://resource/tower/sprout.tres"))
	var bell := _plant(placer, container, map, load("res://resource/tower/bellflower.tres"))
	var spore := _plant(placer, container, map, load("res://resource/tower/sporeling.tres"))
	await process_frame

	var eyelids: UpgradeData = load("res://resource/dream/heavy_eyelids.tres")
	_check(not sprout.is_reached_by_rule(eyelids), "Heavy Eyelids doesn't reach a Sprout")
	_check(not spore.is_reached_by_rule(eyelids), "nor a Sporeling (no Drowsy)")
	_check(bell.is_reached_by_rule(eyelids), "a Bellflower (applies Drowsy) is reached")
	var deeper: UpgradeData = load("res://resource/dream/heavy_eyelids_ii.tres")
	_check(not sprout.is_reached_by_rule(deeper) and bell.is_reached_by_rule(deeper),
		"Heavy Eyelids II uses its base's filter")
	var old_growth: UpgradeData = load("res://resource/dream/old_growth.tres")
	_check(not sprout.is_reached_by_rule(old_growth) and not bell.is_reached_by_rule(old_growth),
		"a card with no Warden filter reaches no Warden by rule")
	var nightbloom: UpgradeData = load("res://resource/dream/endless_night.tres")  # Requires Bloomcap, Rain Lily, Bellflower
	_check(bell.is_reached_by_rule(nightbloom) and spore.is_reached_by_rule(nightbloom) and not sprout.is_reached_by_rule(nightbloom),
		"a Reaction card reaches its ingredients' lines")
	# The real bloom list (Roguelite c25576eb): the Wardens CardBloom pulses when Heavy Eyelids is picked.
	var dreams: DreamState = main.get_node("%DreamState")
	var impact := dreams.preview_card_impact(eyelids)
	_check(not impact.towers.has(sprout) and not impact.towers.has(spore) and impact.towers.has(bell),
		"picking Heavy Eyelids pulses the Bellflower only (%s)" % [impact.towers.map(func(t) -> String: return t.tower_data.get_id())])
	var global_impact := dreams.preview_card_impact(old_growth)
	_check(global_impact.kind == &"stat" or (not global_impact.towers.has(sprout) and not global_impact.towers.has(bell)),
		"a card with no Warden filter pulses no Warden by rule (%s)" % global_impact.kind)
	print("card bloom targets test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _plant(placer: TowerPlacer, container: Node, map: Node, data: TowerData) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = data
	for y in range(1, 17):
		for x in range(1, 22):
			var cell := Vector2(x, y)
			if map.is_buildable(cell) and not container.get_children().any(func(t) -> bool: return t is Tower and t.cell == cell):
				tower.cell = cell
				tower.position = Tower.MAP_GRID.calculate_map_position(cell)
				container.add_child(tower)
				tower.set_process(false)
				return tower
	return tower

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
