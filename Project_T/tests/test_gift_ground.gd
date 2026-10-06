extends SceneTree

# Headless test for Heartwood's Gifts, the Warden side (GiftGround; heartwood_gifts.md 449c7437, numbers in
# spire_difficulty.md Phase 3): Spring, Mushroom Ring, Lightning Tree, Moonwell, Bell Stone, Ancient Stump, Bramble
# Verge, Old Kin, Memory Seed, and the save.
#   godot --headless --path . --script res://tests/test_gift_ground.gd --fixed-fps 60

const CELL := 64.0

var failures := 0
var main: Node
var spawner
var placer: TowerPlacer
var seller: TowerSeller
var container: Node
var map

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	paused = false
	spawner = main.get_node("%EnemyContainer")
	placer = main.get_node("%TowerPlacer")
	seller = main.get_node("%TowerSeller")
	container = main.get_node("%TowerContainer")
	map = main.get_node("%MapGenerator")
	main.get_node("%RunState").dew = 100000
	main.get_node("%DreamState").unlock_everything = true
	for child in spawner.get_children():
		child.queue_free()
	await process_frame
	var gifts := GiftGround.find(main)
	_check(gifts != null and GiftGround.active() == gifts, "the gift ground is made on first use")

	# Spring: a water Warden beside the pond deals +20%; Soaked lasts 1 s longer within 2 cells.
	var wet := _plant("dewdrop", Vector2(4, 4))
	var dry := _plant("dewdrop", Vector2(14, 4))
	var plain := dry.get_damage()
	gifts.add_mark(GiftGround.SPRING, [Vector2(5, 4), Vector2(6, 4), Vector2(5, 5), Vector2(6, 5)])
	_check(is_equal_approx(wet.get_damage(), plain * (1.0 + GiftGround.SPRING_DAMAGE)) and is_equal_approx(dry.get_damage(), plain),
		"Spring: the water Warden beside it +20%% (%.1f vs %.1f), the far one unchanged" % [wet.get_damage(), plain])
	var soaked := _spawn(Vector2(6, 6))
	var far_soaked := _spawn(Vector2(14, 6))
	wet._apply_one_status(soaked, EnemyStatuses.DAMP, 1, 10.0)
	wet._apply_one_status(far_soaked, EnemyStatuses.DAMP, 1, 10.0)
	_check(is_equal_approx(soaked.statuses.time_left(EnemyStatuses.DAMP) - far_soaked.statuses.time_left(EnemyStatuses.DAMP), GiftGround.SPRING_SOAK_SECONDS),
		"Spring: Soaked lasts 1 s longer within 2 cells (%.1f vs %.1f)" % [soaked.statuses.time_left(EnemyStatuses.DAMP), far_soaked.statuses.time_left(EnemyStatuses.DAMP)])
	await _clean()

	# Mushroom Ring: a spore Warden touching it raises the Poisoned cap by 2.
	var ringed := _plant("sporeling", Vector2(4, 8))
	var unringed := _plant("sporeling", Vector2(14, 8))
	gifts.add_mark(GiftGround.MUSHROOM_RING, [Vector2(5, 8), Vector2(6, 8), Vector2(7, 8), Vector2(5, 9), Vector2(6, 9), Vector2(7, 9),
		Vector2(5, 10), Vector2(6, 10), Vector2(7, 10)])
	var a := _spawn(Vector2(9, 12))
	var b := _spawn(Vector2(12, 12))
	for i in 20:
		ringed._apply_one_status(a, EnemyStatuses.SPORED, 1, 10.0)
		unringed._apply_one_status(b, EnemyStatuses.SPORED, 1, 10.0)
	_check(a.statuses.stacks(EnemyStatuses.SPORED) == b.statuses.stacks(EnemyStatuses.SPORED) + GiftGround.RING_SPORED_CAP,
		"Mushroom Ring: +2 Poisoned cap (%d vs %d)" % [a.statuses.stacks(EnemyStatuses.SPORED), b.statuses.stacks(EnemyStatuses.SPORED)])
	await _clean()

	# Lightning Tree: a Charged bolt within 2 cells deals +25%.
	gifts.add_mark(GiftGround.LIGHTNING_TREE, [Vector2(8, 14)])
	var struck := _spawn(Vector2(9, 14))
	var unstruck := _spawn(Vector2(16, 14))
	Reactions.strike_bolt(struck, 100.0, null)
	Reactions.strike_bolt(unstruck, 100.0, null)
	var near_lost: int = struck.max_health - struck.health
	var far_lost: int = unstruck.max_health - unstruck.health
	_check(far_lost > 0 and absf(float(near_lost) / far_lost - (1.0 + GiftGround.LIGHTNING_BOLT)) < 0.03,
		"Lightning Tree: bolts within 2 cells +25%% (%d vs %d)" % [near_lost, far_lost])
	await _clean()

	# Moonwell: the 4 orthogonal cells get +1 range; a diagonal one doesn't.
	gifts.add_mark(GiftGround.MOONWELL, [Vector2(10, 10)])
	var beside := _plant("firefly_jar", Vector2(10, 11))
	var corner := _plant("firefly_jar", Vector2(11, 11))
	_check(is_equal_approx(beside.get_range_cells() - corner.get_range_cells(), GiftGround.MOONWELL_RANGE),
		"Moonwell: +1 range beside it, not on the diagonal (%.1f vs %.1f)" % [beside.get_range_cells(), corner.get_range_cells()])
	await _clean()

	# Bell Stone: a song Warden within 1 cell pulses 15% faster.
	gifts.add_mark(GiftGround.BELL_STONE, [Vector2(3, 14)])
	var ringing := _plant("bellflower", Vector2(4, 15))
	var quiet := _plant("bellflower", Vector2(16, 2))
	_check(is_equal_approx(ringing.get_attacks_per_second(), quiet.get_attacks_per_second() * (1.0 + GiftGround.BELL_SPEED)),
		"Bell Stone: song Wardens within 1 cell 15%% faster (%.2f vs %.2f)" % [ringing.get_attacks_per_second(), quiet.get_attacks_per_second()])
	await _clean()

	# Sow a Ridge: an attacking Warden touching a standing tree is Sheltered (+10%); walls get nothing; a tended
	# tree shelters no one. Fallen Giant: an attacking Warden touching the log gets +0.5 range ("High ground").
	var tree := Vector2(-1, -1)
	var spot := Vector2(-1, -1)
	for c in map.obstacles:
		spot = _open_cell_near(c)
		if spot.x >= 0:
			tree = c
			break
	_check(tree.x >= 0, "a standing tree with an open cell beside it")
	var open_far := _plant("sporeling", Vector2(16, 2))
	var base_damage := open_far.get_damage()
	var base_range := open_far.get_range_cells()
	var sheltered := _plant("sporeling", spot)
	_check(is_equal_approx(sheltered.get_damage(), base_damage), "no shelter before the gift")
	gifts.add_mark(GiftGround.SOW_RIDGE, [tree])
	gifts.add_mark(GiftGround.FALLEN_GIANT, [tree])
	_check(is_equal_approx(sheltered.get_damage(), base_damage * (1.0 + GiftGround.SHELTERED_DAMAGE)),
		"Sow a Ridge: Sheltered +10%% (%.2f vs %.2f)" % [sheltered.get_damage(), base_damage])
	_check(is_equal_approx(sheltered.get_range_cells() - base_range, GiftGround.HIGH_GROUND_RANGE),
		"Fallen Giant: High ground +0.5 range (%.2f vs %.2f)" % [sheltered.get_range_cells(), base_range])
	_check(is_equal_approx(open_far.get_damage(), base_damage), "a Warden away from the tree isn't Sheltered")
	var labels: Array = BuffSources.for_tower(sheltered).map(func(e: Dictionary) -> String: return e.label)
	_check(labels.any(func(l: String) -> bool: return l.begins_with("Gift Sheltered")) and labels.any(func(l: String) -> bool: return l.begins_with("Gift High ground")),
		"both show as buff chips with their source (%s)" % [labels])
	_check(gifts.buff_rows(_plant("thornwall", Vector2(16, 4))).is_empty() and not gifts.sheltered(_tower_at(Vector2(16, 4))),
		"walls get no gift buffs")
	map.clear_obstacle(tree)
	gifts.remove_mark(GiftGround.FALLEN_GIANT, tree)
	_check(is_equal_approx(sheltered.get_damage(), base_damage), "a tended tree shelters no one (%.2f)" % sheltered.get_damage())
	await _clean()

	# Ancient Stump: a Warden planted on one starts at rank I, nothing invested for it.
	var stump := _open_cell()
	gifts.add_mark(GiftGround.STUMP, [stump])
	placer.tower_data = load("res://resource/tower/sporeling.tres")
	var price := placer.get_cost(null, stump)
	_check(placer._try_build(stump), "(setup) a Sporeling planted on the stump")
	var on_stump := _tower_at(stump)
	_check(on_stump != null and on_stump.rank == 1 and on_stump.invested_dew == price,
		"Ancient Stump: it starts at rank I, free (rank %d, invested %d of %d)" % [on_stump.rank if on_stump else -1, on_stump.invested_dew if on_stump else -1, price])
	await _clean()
	gifts.remove_mark(GiftGround.STUMP, stump)

	# Bramble Verge: Thornwalls half price; a nightmare touching one gets +1 Drowsy cap.
	var thorn: TowerData = load("res://resource/tower/thornwall.tres")
	var full := placer.get_cost(thorn)
	gifts.set_bramble_verge()
	_check(placer.get_cost(thorn) == roundi(full * GiftGround.BRAMBLE_COST), "Bramble Verge: Thornwalls cost half (%d of %d)" % [placer.get_cost(thorn), full])
	var wall := _plant("thornwall", Vector2(9, 5))
	var touching := _spawn(Vector2(10, 5))
	var apart := _spawn(Vector2(14, 12))
	_check(Reactions.drowsy_cap_bonus(touching) == GiftGround.BRAMBLE_DROWSY_CAP and Reactions.drowsy_cap_bonus(apart) == 0,
		"Bramble Verge: +1 Drowsy cap touching a Thornwall, none away from it")
	wall.queue_free()
	await _clean()

	# Old Kin: the chosen Kinship jumps a stage; new bonds start a stage up through the given act.
	var director: DriftDirector = main.get_node("%DriftDirector")
	var storm := _plant("stormcap", Vector2(4, 2))
	var moth := _plant("lanternmoth", Vector2(5, 2))
	var kin := Kinships.find(main)
	kin.refresh()
	var pairs: Array = kin.get_pairs(storm)
	_check(pairs.size() == 1 and kin.get_stage(pairs[0]) == 0, "(setup) a Storm Beacon Kinship, a fresh bond")
	if pairs.size() == 1:
		_check(gifts.grant_old_kin(pairs[0].key, director.get_act(maxi(director.drifts_started, 1))) and kin.get_stage(pairs[0]) == 1,
			"Old Kin: the chosen Kinship jumps a stage")
	var storm2 := _plant("stormcap", Vector2(14, 2))
	var moth2 := _plant("lanternmoth", Vector2(15, 2))
	kin.refresh()
	var fresh: Array = kin.get_pairs(storm2)
	_check(fresh.size() == 1 and kin.get_stage(fresh[0]) == 1, "Old Kin: a new bond this act starts a stage up")
	gifts.old_kin_act = 0
	await _clean()
	kin.refresh()

	# Memory Seed: the chosen Warden keeps its ranks and its bond's age through a sale and a replant.
	var seed_cell := _open_cell()
	placer.tower_data = load("res://resource/tower/stormcap.tres")
	placer._try_build(seed_cell)
	var seeded := _tower_at(seed_cell)
	seeded.nurture(0)
	seeded.nurture(0)
	var partner_cell := _open_cell_near(seed_cell)
	placer.tower_data = load("res://resource/tower/lanternmoth.tres")
	placer._try_build(partner_cell)
	kin.refresh()
	var bond: Array = kin.get_pairs(seeded)
	if bond.size() == 1:
		kin.ages[bond[0].key] = 7
	gifts.set_memory_seed(seed_cell, director.get_act(maxi(director.drifts_started, 1)))
	seller.sell(seed_cell)
	await process_frame
	kin.refresh()
	placer.tower_data = load("res://resource/tower/stormcap.tres")
	placer._try_build(seed_cell)
	var replanted := _tower_at(seed_cell)
	kin.refresh()
	var again: Array = kin.get_pairs(replanted) if replanted else []
	_check(replanted != null and replanted.rank == 2, "Memory Seed: replanted, it keeps its ranks (rank %d)" % (replanted.rank if replanted else -1))
	_check(bond.size() == 1 and again.size() == 1 and int(kin.ages.get(again[0].key, 0)) >= 7,
		"Memory Seed: its bond with the old partner keeps its age (%s)" % [kin.ages.get(again[0].key, -1) if not again.is_empty() else "no bond"])

	# Main's HeartwoodGifts: the gifts with no terrain have their Warden effect registered (so they enter the draw);
	# a terrain gift's cells reach the ground from the taken record (Environment Code places the terrain itself).
	for id in [&"bramble_verge", &"old_kin", &"memory_seed"]:
		_check(HeartwoodGifts.has_effect(id), "%s has its Warden effect registered" % id)
	var offerer := HeartwoodGifts.find(main)
	if offerer:
		offerer.taken.append({"id": "moonwell", "act": 1, "placement": {"cells": [[2, 16]]}})
		_check(gifts.has_mark(GiftGround.MOONWELL, Vector2(2, 16)), "a taken Moonwell's cell reaches the gift ground")
	else:
		_check(false, "(setup) the run has its HeartwoodGifts")

	# A taken Lightning Tree (Environment's obstacle) boosts bolts while it stands; tended away, its bonus goes too.
	await _clean()
	gifts.marks.erase(GiftGround.LIGHTNING_TREE)
	var tree_cell := _open_cell()
	if offerer:
		var record := {"id": "lightning_tree", "act": 1, "placement": {"cells": [[tree_cell.x, tree_cell.y]]}}
		offerer.taken.append(record)
		offerer._apply(&"lightning_tree", record.placement, false)
	var by_tree := _spawn(tree_cell + Vector2(1, 0))
	_check(is_equal_approx(gifts.bolt_multiplier(by_tree.global_position), 1.0 + GiftGround.LIGHTNING_BOLT),
		"a taken, standing Lightning Tree boosts bolts beside it")
	map.clear_obstacle(tree_cell)
	_check(is_equal_approx(gifts.bolt_multiplier(by_tree.global_position), 1.0), "tended away, its bolt bonus is gone")

	print("gift ground test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _plant(id: String, cell: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = cell
	tower.position = Tower.MAP_GRID.calculate_map_position(cell)
	container.add_child(tower)
	tower.set_process(false)
	return tower

func _spawn(cell: Vector2) -> Node2D:
	var enemy: Node2D = spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	enemy.set_process(false)
	enemy.global_position = Tower.MAP_GRID.calculate_map_position(cell)
	enemy.max_health = 100000
	enemy.health = 100000
	return enemy

func _open_cell() -> Vector2:
	for x in range(3, 20):
		for y in range(3, 15):
			var cell := Vector2(x, y)
			if map.is_buildable(cell) and map.can_block(cell) and _tower_at(cell) == null:
				return cell
	return Vector2(-1, -1)

func _open_cell_near(cell: Vector2) -> Vector2:
	for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1), Vector2(1, 1), Vector2(-1, -1), Vector2(2, 0), Vector2(0, 2)]:
		var c: Vector2 = cell + d
		if map.is_buildable(c) and map.can_block(c) and _tower_at(c) == null:
			return c
	return Vector2(-1, -1)

func _tower_at(cell: Vector2) -> Tower:
	for tower in container.get_children():
		if tower is Tower and not tower.is_queued_for_deletion() and tower.cell == cell:
			return tower
	return null

func _clean() -> void:
	for child in spawner.get_children():
		child.queue_free()
	for tower in container.get_children():
		if tower is Tower:
			for c in tower.get_cells():
				map.unblock_cell(c)
		tower.queue_free()
	await process_frame

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
