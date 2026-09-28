extends SceneTree

# Headless test for Kinships (tower_design.md "Kinships: two branches of one family"): pairing within
# 2 cells (nearest kin, one each), bond stages over drifts (queued to the rest), evolving keeps the bond
# and selling resets it, Harmony strikes, Kindred and Whole Tree, a few borrowed traits, the demo's
# three, and the run save. Run from the project folder:
#   godot --headless --path . --script res://tests/test_kinships.gd --fixed-fps 60

const CELL := 64.0

var failures := 0
var main: Node
var placer: TowerPlacer
var seller: TowerSeller
var container: Node
var spawner

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	Kinships.force_full = true
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	placer = main.get_node("%TowerPlacer")
	seller = main.get_node("%TowerSeller")
	container = main.get_node("%TowerContainer")
	spawner = main.get_node("%EnemyContainer")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var run_state: RunState = main.get_node("%RunState")
	for child in spawner.get_children():
		child.queue_free()

	_check(Kinships.branch_of(load("res://resource/tower/puffball.tres")) == "driftspore", "Puffball belongs to the Driftspore branch")
	_check(Kinships.branch_of(load("res://resource/tower/sporeling.tres")) == "", "a base Warden has no branch")

	# --- Pairing ---
	var drift := _plant("driftspore", Vector2(4, 4))
	var bloom := _plant("bloomcap", Vector2(6, 4))  # 2 cells away
	var far_bloom := _plant("bloomcap", Vector2(12, 12))
	await process_frame
	var kin := Kinships.find(drift)
	_check(kin != null, "the run's Kinships exists once Wardens are planted")
	var formed := []
	kin.kinship_formed.connect(func(id, _a, _b) -> void: formed.append(id))
	kin.refresh()
	_check(kin.get_pair(drift).get("id") == &"slumber_rot" and kin.get_partner(drift) == bloom,
		"Driftspore + Bloomcap within 2 cells: Slumber Rot")
	_check(kin.get_pair(far_bloom).is_empty(), "a kin 8 cells away doesn't bond")
	_check(is_equal_approx(drift.kin_share(&"slumber_rot", "a"), 0.5) and drift.kin_share(&"slumber_rot", "b") == 0.0,
		"Sapling: the Driftspore side borrows 50%")
	_check(is_equal_approx(kin.family_bonus("spore"), Kinships.KINDRED_BONUS), "Kindred: the spore family +10%")
	var base := drift.tower_data.damage * drift.get_rank_damage_multiplier()
	_check(is_equal_approx(drift.get_damage(), base * 1.1), "and the Warden's damage shows it")
	_check(kin.describe(drift).begins_with("Kin: Bloomcap · Slumber Rot · Sapling (5 drifts to Blooming)"),
		"panel line (%s)" % kin.describe(drift))

	# --- Bond stages: counted in drifts, announced at the rest ---
	var grew := []
	kin.kin_stage_grew.connect(func(family, stage, _where) -> void: grew.append([family, stage]))
	kin._resting = false
	for i in 5:
		kin._on_drift_cleared(i + 1, 0, true)
	_check(is_equal_approx(drift.kin_share(&"slumber_rot", "a"), 0.75), "Blooming at 5 drifts: 75%")
	_check(grew.is_empty(), "the stage-up waits for the rest")
	kin._on_rest_started(1, false, 0, true)
	_check(grew == [["spore", 1]], "announced at the rest (%s)" % [grew])

	# --- Evolving keeps the bond; selling resets it ---
	drift.evolve(load("res://resource/tower/puffball.tres"), 0)
	kin.refresh()
	_check(kin.get_pair(drift).get("id") == &"slumber_rot" and is_equal_approx(drift.kin_share(&"slumber_rot", "a"), 0.75),
		"evolving into Puffball keeps the bond and its age")

	# --- Harmony strike ---
	var enemy := _spawn(drift.global_position + Vector2(CELL, 0))
	var harmony := []
	kin.harmony_struck.connect(func(_t, _e) -> void: harmony.append(true))
	var before: int = enemy.health
	drift.hit(enemy, 1.0, false, Tower.NO_CRIT)
	bloom.hit(enemy, 1.0, false, Tower.NO_CRIT)
	_check(harmony.size() == 1 and kin.harmony_run == 1, "both kin hit it within 1 s: a Harmony strike")
	var plain: int = int(drift.get_damage()) + int(bloom.get_damage())
	_check(before - enemy.health > plain, "it deals bonus damage on top of both hits")
	drift.hit(enemy, 1.0, false, Tower.NO_CRIT)
	bloom.hit(enemy, 1.0, false, Tower.NO_CRIT)
	_check(harmony.size() == 1, "not again within the 2 s cooldown")

	# --- Selling resets ---
	seller.sell(bloom.cell)
	await process_frame
	kin.refresh()
	_check(kin.get_pair(drift).get("id") == &"slumber_rot" and kin.get_partner(drift) == far_bloom or kin.get_pair(drift).is_empty(),
		"selling the kin ends that bond")
	var bloom2 := _plant("bloomcap", Vector2(5, 5))
	await process_frame
	kin.refresh()
	_check(kin.get_partner(drift) == bloom2 and is_equal_approx(drift.kin_share(&"slumber_rot", "a"), 0.5),
		"a new kin starts again at Sapling")

	# --- Whole Tree: all three branches, the hidden one included ---
	_plant("fairy_ring", Vector2(8, 8))
	await process_frame
	kin.refresh()
	_check(is_equal_approx(kin.family_bonus("spore"), Kinships.WHOLE_TREE_BONUS), "Whole Tree: +20% (replaces Kindred)")

	# --- A few borrowed traits ---
	var curl := _plant("rootcurl", Vector2(14, 4))
	var tangle := _plant("tangleroot", Vector2(15, 4))
	var stone := _plant("mossback", Vector2(14, 8))
	var standing := _plant("standing_stone", Vector2(16, 8))
	var elder := _plant("elder_stump", Vector2(3, 12))
	var catcher := _plant("dewcatcher", Vector2(4, 12))
	await process_frame
	kin.refresh()
	_check(kin.get_pair(curl).get("id") == &"snare", "Rootcurl + Tangleroot: Snare")
	_check(is_equal_approx(stone.get_raw_crit_chance() - stone.attack_data.crit_chance, 0.05),
		"Hammer and Anvil: the Mossback gets +5% crit at Sapling")
	var dew := run_state.dew
	kin._on_drift_cleared(20, 0, true)
	_check(run_state.dew == dew + 1, "Old Growth: the Elder Stump side gives +1 Dew a drift at Sapling (%d)" % (run_state.dew - dew))
	var near := _plant("sprout", Vector2(5, 13))
	await process_frame
	near._refresh_neighbours()
	_check(near._aura_speed >= 0.05, "Old Growth: the Dewcatcher kin's small aura speeds up its neighbours")

	# --- The run save keeps bond ages ---
	var saved := kin.to_save()
	kin.ages.clear()
	kin.load_save(saved)
	_check(kin.ages.size() == saved.ages.size(), "bond ages survive a save and load")

	# --- The demo has only its three ---
	Kinships.force_full = false
	if ResultsScreen.is_demo():
		_check(not Kinships.is_available(&"snare") and Kinships.is_available(&"slumber_rot"),
			"the demo has Slumber Rot, Rainfog and Storm Beacon only")
	Kinships.force_full = true

	print("kinships test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _plant(id: String, cell: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = cell
	tower.position = Tower.MAP_GRID.calculate_map_position(cell)
	container.add_child(tower)
	tower.set_process(false)
	return tower

func _spawn(at: Vector2) -> Node2D:
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	var enemy = spawner.get_child(spawner.get_child_count() - 1)
	enemy.set_process(false)
	enemy.global_position = at
	enemy.max_health = 1000000
	enemy.health = 1000000
	enemy.coat = 0.0
	return enemy

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
