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

	# Spring (landmark): a water Warden touching the pond deals more; nightmares within 2 cells are Soaked by the pond
	# itself, 2 stacks a second; one far away isn't.
	var wet := _plant("dewdrop", Vector2(4, 4))
	var dry := _plant("dewdrop", Vector2(14, 4))
	var plain := dry.get_damage()
	gifts.add_mark(GiftGround.SPRING, [Vector2(5, 4), Vector2(6, 4), Vector2(5, 5), Vector2(6, 5)])
	_check(is_equal_approx(wet.get_damage(), plain * (1.0 + HeartwoodGifts.stat(&"spring", "water_damage"))) and is_equal_approx(dry.get_damage(), plain),
		"Spring: the water Warden touching it +40%% (%.1f vs %.1f), the far one unchanged" % [wet.get_damage(), plain])
	var soaked := _spawn(Vector2(6, 7))
	var far_soaked := _spawn(Vector2(14, 6))
	for i in 4:
		_tick(gifts)
	_check(soaked.statuses.stacks(EnemyStatuses.DAMP) == int(HeartwoodGifts.stat(&"spring", "soak_stacks_per_second")) and not far_soaked.statuses.has(EnemyStatuses.DAMP),
		"Spring: a second within 2 cells Soaks 2 stacks (%d), none far away" % soaked.statuses.stacks(EnemyStatuses.DAMP))
	_check(int(gifts.counts.get(GiftGround.SPRING, 0)) == 1, "…counted once for the rest report")
	await _clean()
	gifts.marks.erase(GiftGround.SPRING)
	gifts._changed()

	# Mushroom Ring (landmark): a spore Warden touching it can stack half again as much Poisoned; a nightmare crossing
	# the ring is Poisoned once per crossing.
	var ringed := _plant("sporeling", Vector2(4, 8))
	var unringed := _plant("sporeling", Vector2(14, 8))
	gifts.add_mark(GiftGround.MUSHROOM_RING, [Vector2(5, 8), Vector2(6, 8), Vector2(7, 8), Vector2(5, 9), Vector2(6, 9), Vector2(7, 9),
		Vector2(5, 10), Vector2(6, 10), Vector2(7, 10)])
	var a := _spawn(Vector2(9, 12))
	var b := _spawn(Vector2(12, 12))
	var base_cap: int = EnemyStatuses.DEFAULT_MAX_STACKS[EnemyStatuses.SPORED]
	var ring_cap := base_cap + roundi(base_cap * HeartwoodGifts.stat(&"mushroom_ring", "spore_cap_share"))
	for i in ring_cap + 4:
		ringed._apply_one_status(a, EnemyStatuses.SPORED, 1, 10.0)
		unringed._apply_one_status(b, EnemyStatuses.SPORED, 1, 10.0)
	_check(a.statuses.stacks(EnemyStatuses.SPORED) == ring_cap and b.statuses.stacks(EnemyStatuses.SPORED) == base_cap,
		"Mushroom Ring: half again the Poisoned cap (%d vs %d)" % [a.statuses.stacks(EnemyStatuses.SPORED), b.statuses.stacks(EnemyStatuses.SPORED)])
	var crosser := _spawn(Vector2(6, 9))
	_tick(gifts)
	var ring_stacks := int(HeartwoodGifts.stat(&"mushroom_ring", "spored_stacks"))
	_check(crosser.statuses.stacks(EnemyStatuses.SPORED) == ring_stacks, "Mushroom Ring: crossing it Poisons 6 (%d)" % crosser.statuses.stacks(EnemyStatuses.SPORED))
	_tick(gifts)
	_check(crosser.statuses.stacks(EnemyStatuses.SPORED) == ring_stacks, "…once per crossing")
	crosser.global_position = Tower.MAP_GRID.calculate_map_position(Vector2(12, 9))
	_tick(gifts)
	crosser.global_position = Tower.MAP_GRID.calculate_map_position(Vector2(6, 9))
	_tick(gifts)
	_check(crosser.statuses.stacks(EnemyStatuses.SPORED) == ring_stacks * 2, "…and again on the next crossing (%d)" % crosser.statuses.stacks(EnemyStatuses.SPORED))
	await _clean()
	gifts.marks.erase(GiftGround.MUSHROOM_RING)
	gifts._changed()

	# Lightning Tree (landmark): a Charged bolt within 3 cells strikes a second time at half damage; the tree throws
	# its own bolt every 6 s, credited to the gift.
	gifts.add_mark(GiftGround.LIGHTNING_TREE, [Vector2(8, 14)])
	gifts._tree_left = 999.0  # (Its own bolt is checked after)
	var struck := _spawn(Vector2(10, 14))
	var unstruck := _spawn(Vector2(16, 14))
	Reactions.strike_bolt(struck, 100.0, null)
	Reactions.strike_bolt(unstruck, 100.0, null)
	var near_lost: int = struck.max_health - struck.health
	var far_lost: int = unstruck.max_health - unstruck.health
	_check(far_lost > 0 and absf(float(near_lost) / far_lost - (1.0 + HeartwoodGifts.stat(&"lightning_tree", "second_strike_share"))) < 0.03,
		"Lightning Tree: bolts within 3 cells strike twice, the second at half (%d vs %d)" % [near_lost, far_lost])
	var before_own: int = struck.health
	var far_before: int = unstruck.health
	gifts._tree_left = 0.0
	_tick(gifts)
	_check(struck.health < before_own and unstruck.health == far_before and is_equal_approx(gifts._tree_left, HeartwoodGifts.stat(&"lightning_tree", "bolt_every")),
		"Lightning Tree: it throws its own bolt at a nightmare in its zone, then waits 6 s")
	_check(gifts.source_of(GiftGround.LIGHTNING_TREE).name == "Lightning Tree", "…credited to the gift by name")
	await _clean()

	# Moonwell (landmark): Wardens within 2 cells get +1.5 range (the diagonal too), one 3 cells away doesn't; they
	# reveal Hidden nightmares in their range.
	gifts.add_mark(GiftGround.MOONWELL, [Vector2(10, 10)])
	var beside := _plant("firefly_jar", Vector2(11, 12))
	var corner := _plant("firefly_jar", Vector2(13, 10))
	_check(is_equal_approx(beside.get_range_cells() - corner.get_range_cells(), HeartwoodGifts.stat(&"moonwell", "range")),
		"Moonwell: +1.5 range within 2 cells, not 3 away (%.1f vs %.1f)" % [beside.get_range_cells(), corner.get_range_cells()])
	var lurker := _spawn(Vector2(11, 13))
	lurker._revealed_time = 0.0
	lurker._hidden = true
	_tick(gifts)
	_check(lurker._revealed_time > 0.0, "Moonwell: its Wardens reveal a Hidden nightmare in their range")
	await _clean()
	gifts.marks.erase(GiftGround.MOONWELL)
	gifts._changed()

	# Bell Stone (landmark): a song Warden touching it pulses faster; every 5 s nightmares within 3 cells gain 4 Drowsy.
	gifts.add_mark(GiftGround.BELL_STONE, [Vector2(3, 14)])
	var ringing := _plant("bellflower", Vector2(4, 15))
	var quiet := _plant("bellflower", Vector2(16, 2))
	_check(is_equal_approx(ringing.get_attacks_per_second(), quiet.get_attacks_per_second() * (1.0 + HeartwoodGifts.stat(&"bell_stone", "song_pulse_speed"))),
		"Bell Stone: song Wardens touching it 30%% faster (%.2f vs %.2f)" % [ringing.get_attacks_per_second(), quiet.get_attacks_per_second()])
	var hearer := _spawn(Vector2(5, 12))
	var deaf := _spawn(Vector2(12, 14))
	gifts._bell_left = 0.0
	_tick(gifts)
	_check(hearer.statuses.stacks(EnemyStatuses.DROWSY) == int(HeartwoodGifts.stat(&"bell_stone", "drowsy_stacks")) and not deaf.statuses.has(EnemyStatuses.DROWSY),
		"Bell Stone: its ring gives 4 Drowsy within 3 cells (%d)" % hearer.statuses.stacks(EnemyStatuses.DROWSY))
	_tick(gifts)
	_check(hearer.statuses.stacks(EnemyStatuses.DROWSY) == int(HeartwoodGifts.stat(&"bell_stone", "drowsy_stacks")), "…and not again before the next ring")
	await _clean()
	gifts.marks.erase(GiftGround.BELL_STONE)
	gifts._changed()

	# Sow a Ridge: an attacking Warden touching a standing tree is Sheltered (+10%); walls get nothing; a tended
	# tree shelters no one. Fallen Giant: an attacking Warden touching the log gets +15% crit ("Lookout").
	var tree := Vector2(-1, -1)
	var spot := Vector2(-1, -1)
	for c in map.obstacles:  # A free cell right beside it ("touching" is by halves, side by side; not diagonal or 2 away)
		for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			if map.is_buildable(c + d) and map.can_block(c + d) and _tower_at(c + d) == null:
				spot = c + d
				break
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
	_check(is_equal_approx(sheltered.get_damage(), base_damage * (1.0 + HeartwoodGifts.stat(&"sow_ridge", "damage"))),
		"Sow a Ridge: Sheltered +30%% (%.2f vs %.2f)" % [sheltered.get_damage(), base_damage])
	_check(is_equal_approx(sheltered.get_range_cells(), base_range), "Fallen Giant: no range now (%.2f)" % sheltered.get_range_cells())
	_check(is_equal_approx(sheltered.get_raw_crit_chance() - open_far.get_raw_crit_chance(), HeartwoodGifts.stat(&"fallen_giant", "crit_chance")) and is_equal_approx(gifts.crit_damage_bonus(sheltered), HeartwoodGifts.stat(&"fallen_giant", "crit_damage")) and gifts.crit_damage_bonus(open_far) == 0.0,
		"Fallen Giant: Lookout +30%% crit and harder crits (%.2f vs %.2f)" % [sheltered.get_raw_crit_chance(), open_far.get_raw_crit_chance()])
	_check(is_equal_approx(open_far.get_damage(), base_damage), "a Warden away from the tree isn't Sheltered")
	var labels: Array = BuffSources.for_tower(sheltered).map(func(e: Dictionary) -> String: return e.label)
	_check(labels.any(func(l: String) -> bool: return l.begins_with("Gift Sheltered")) and labels.any(func(l: String) -> bool: return l.begins_with("Gift Lookout")),
		"both show as buff chips with their source (%s)" % [labels])
	_check(gifts.buff_rows(_plant("thornwall", Vector2(16, 4))).is_empty() and not gifts.sheltered(_tower_at(Vector2(16, 4))),
		"walls get no gift buffs")
	map.clear_obstacle(tree)
	gifts.remove_mark(GiftGround.FALLEN_GIANT, tree)
	_check(is_equal_approx(sheltered.get_damage(), base_damage), "a tended tree shelters no one (%.2f)" % sheltered.get_damage())
	await _clean()

	# Half-cell gift placement (heartwood_gifts.md 2554c638): a piece at a half offset marks origin / 2, and touching
	# reads exactly its halves (origin .. origin + 1): the half beside it touches, two halves away doesn't.
	var piece := Vector2(9, 7)  # Half origin, odd: half-offset
	_check(GiftGround.mark_cells({"pieces": [[9, 7]], "cells": [[4, 3]]}) == [Vector2(4.5, 3.5)], "a half-offset piece marks origin / 2 (not its home cell)")
	gifts.add_mark(GiftGround.FALLEN_GIANT, [piece / 2.0])
	_check(gifts.touching(GiftGround.FALLEN_GIANT, [piece + Vector2(2, 0)]) and not gifts.touching(GiftGround.FALLEN_GIANT, [piece + Vector2(3, 0)]),
		"touching reads the piece's own halves")
	gifts.remove_mark(GiftGround.FALLEN_GIANT, piece / 2.0)

	# Ancient Stump: a Warden planted on one gets a banked rank (the user: no auto upgrades), spent through Nurture
	# for free and free through growth.
	var stump := _open_cell()
	gifts.add_mark(GiftGround.STUMP, [stump])
	placer.tower_data = load("res://resource/tower/sporeling.tres")
	var price := placer.get_cost(null, stump)
	_check(placer._try_build(stump), "(setup) a Sporeling planted on the stump")
	var on_stump := _tower_at(stump)
	_check(on_stump != null and on_stump.rank == 0 and on_stump.banked_ranks == int(HeartwoodGifts.stat(&"ancient_stump", "free_ranks")) and on_stump.get_nurture_cost() == 0,
		"Elder Stumps: 2 banked ranks, free to spend (rank %d, banked %d)" % [on_stump.rank if on_stump else -1, on_stump.banked_ranks if on_stump else -1])
	var dew_before: int = main.get_node("%RunState").dew
	_check(placer.nurture(on_stump) and on_stump.rank == 1 and on_stump.banked_ranks == 1 and on_stump.paid_ranks.is_empty()
		and main.get_node("%RunState").dew == dew_before and on_stump.invested_dew == price,
		"…Nurture spends it: rank I, no Dew, not a paid rank (invested %d of %d)" % [on_stump.invested_dew, price])
	await _clean()
	gifts.remove_mark(GiftGround.STUMP, stump)

	# Bramble Verge (8f46c6ac): Thornwall -> Bramble grows free, Bramble unlocked, Thornwalls keep their price;
	# a nightmare touching a Bramble gets +1 Drowsy cap (a Thornwall no longer counts).
	var thorn: TowerData = load("res://resource/tower/thornwall.tres")
	var bramble_data: TowerData = load("res://resource/tower/bramble.tres")
	var full := placer.get_cost(thorn)
	var grower := _plant("thornwall", Vector2(16, 12))
	var paid: int = grower.get_grow_cost(bramble_data).total
	gifts.set_bramble_verge()
	var dreams: DreamState = main.get_node("%DreamState")
	_check(dreams.unlocked.has(GiftGround.BRAMBLE), "Bramble Verge: Bramble unlocked")
	_check(placer.get_cost(thorn) == full, "Bramble Verge: Thornwalls keep their price (%d of %d)" % [placer.get_cost(thorn), full])
	_check(paid > 0 and grower.get_grow_cost(bramble_data).total == 0,
		"Bramble Verge: Thornwall -> Bramble is free (%d -> %d)" % [paid, grower.get_grow_cost(bramble_data).total])
	# Brambles make nightmares Drowsy twice as fast (the +1 Drowsy cap is gone); a Thornwall doesn't.
	var briar := _plant("bramble", Vector2(9, 5))
	_check(is_equal_approx(gifts.bramble_drowsy_rate(briar), HeartwoodGifts.stat(&"bramble_verge", "drowsy_rate")) and is_equal_approx(gifts.bramble_drowsy_rate(grower), 1.0)
		and Reactions.drowsy_cap_bonus(_spawn(Vector2(10, 5))) == 0, "Bramble Verge: Brambles apply Drowsy at twice the rate, no cap bonus")
	briar.queue_free()
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

	# Memory Seed: any Warden keeps its ranks and its bond's age through a sale and a replant.
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
	gifts.set_memory_seed(GiftGround.NO_CELL, director.get_act(maxi(director.drifts_started, 1)))
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
	_check(gifts.in_zone(GiftGround.LIGHTNING_TREE, by_tree.global_position), "a taken, standing Lightning Tree's zone covers the cell beside it")
	map.clear_obstacle(tree_cell)
	_check(not gifts.in_zone(GiftGround.LIGHTNING_TREE, by_tree.global_position), "tended away, its zone is gone")

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

# One landmark check now (the ground checks every GiftGround.TICK).
func _tick(gifts: GiftGround) -> void:
	gifts._tick = GiftGround.TICK
	gifts._process(GiftGround.TICK)

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
