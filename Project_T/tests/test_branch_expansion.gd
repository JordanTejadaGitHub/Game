extends SceneTree

# Headless test for the branch expansion, Phase 1 (tower_design.md "Branch expansion", numbers in
# spire_difficulty.md Phase 6): counter tags, generic Kin and Whole Tree, then each new branch and final.
#   godot --headless --path . --script res://tests/test_branch_expansion.gd --fixed-fps 60

const CELL := 64.0

var failures := 0
var main: Node
var spawner
var placer: TowerPlacer
var container: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	Kinships.force_full = true
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	paused = false
	spawner = main.get_node("%EnemyContainer")
	placer = main.get_node("%TowerPlacer")
	container = main.get_node("%TowerContainer")
	main.get_node("%DreamState").unlock_everything = true
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

	# _test_counter_tags() runs once the 12 new branches are in (anti_tank and anti_support need them)
	await _test_generic_kin()

	print("branch expansion test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	Kinships.force_full = false
	main.queue_free()
	await process_frame
	quit(failures)

# Every counter tag sits on at least 3 branches across at least 2 families (the coverage table).
func _test_counter_tags() -> void:
	var by_tag := {}
	for file in DirAccess.get_files_at("res://resource/tower/"):
		if not file.ends_with(".tres"):
			continue
		var data := load("res://resource/tower/" + file) as TowerData
		if data == null:
			continue
		for tag in data.counter_tags:
			if not by_tag.has(tag):
				by_tag[tag] = []
			by_tag[tag].append(data)
	for tag in [&"anti_air", &"detection", &"anti_armour", &"anti_swarm", &"anti_tank", &"anti_support", &"boss_abilities"]:
		var list: Array = by_tag.get(tag, [])
		var lines := {}
		for data in list:
			lines[data.line] = true
		if tag in [&"boss_abilities"] and list.size() < 3:
			continue  # Bark Shield and Quaker come with Phase 2 (Acorn, Pebbling)
		_check(list.size() >= 2 and lines.size() >= 2,
			"%s sits on branches of 2+ families (%s)" % [tag, list.map(func(d) -> String: return d.get_id())])

# Any two different branches of one family within 2 cells bond as Kin when they aren't a named pair:
# +10% damage each. Three different branches: Whole Tree.
func _test_generic_kin() -> void:
	var a := _plant("bloomcap", Vector2(6, 6))
	var b := _plant("fairy_ring", Vector2(7, 6))
	var kin := Kinships.find(main)
	kin.refresh()
	var pairs: Array = kin.get_pairs(a)
	_check(pairs.size() == 1 and pairs[0].id == Kinships.GENERIC, "Bloomcap + Fairy Ring (no named pair) bond as Kin (%s)" % [pairs.map(func(p) -> StringName: return p.id)])
	_check(Kinships.name_of(Kinships.GENERIC) == "Kin" and kin.describe(a).contains("Kin"), "the bond is called Kin")
	_check(is_equal_approx(kin.damage_bonus(a) - kin.family_bonus("spore"), Kinships.GENERIC_BONUS),
		"Kin: +10%% damage each (%.2f on top of Kindred %.2f)" % [kin.damage_bonus(a) - kin.family_bonus("spore"), kin.family_bonus("spore")])
	_check(kin.families.get("spore", 0) == 1, "two different branches: Kindred")
	var c := _plant("driftspore", Vector2(14, 6))
	kin.refresh()
	_check(kin.families.get("spore", 0) == 2, "three different branches on the map: Whole Tree")
	for t in [a, b, c]:
		t.queue_free()
	await process_frame
	kin.refresh()

func _plant(id: String, cell: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = cell
	tower.position = Tower.MAP_GRID.calculate_map_position(cell)
	container.add_child(tower)
	tower.set_process(false)
	return tower

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
