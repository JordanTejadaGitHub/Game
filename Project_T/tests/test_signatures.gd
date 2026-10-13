extends SceneTree

# Headless test for the rank V signatures (Signatures; warden_stats.md 96d728dd, Balancing 43496006): which
# signature a Warden has (4+ of ranks I–V on one choice; Shared Training at rank IV with a matching kin), the panel
# hint, Crushing, Executioner, Relentless, Spreading, Shelter and Surge.
#   godot --headless --path . --script res://tests/test_signatures.gd --fixed-fps 60

const P := Tower.Focus.POWER
const S := Tower.Focus.SWIFT
const R := Tower.Focus.REACH
const D := Tower.Focus.DEEP
const K := Tower.Focus.KEEN
const W := Tower.Focus.WIDE
const ST := Tower.Focus.STRONG

var failures := 0
var main: Node
var dreams: DreamState
var placer: TowerPlacer
var spawner: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_signatures_%d.json" % OS.get_process_id()
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	dreams = main.get_node("%DreamState")
	placer = main.get_node("%TowerPlacer")
	spawner = main.get_node("%EnemyContainer")
	dreams.unlock_everything = true
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

	# Which signature.
	var striker := _plant("sporeling", Vector2(4, 2), [P, P, P, P, R])
	_check(striker.signature() == Signatures.CRUSHING, "4 Power of I–V at rank V: Crushing (%s)" % striker.signature())
	var mixed := _plant("sporeling", Vector2(6, 2), [P, P, S, S, R])
	_check(mixed.signature() == &"all_rounder", "a mixed Warden: All-Rounder")
	var young := _plant("sporeling", Vector2(8, 2), [P, P, P, P])
	_check(young.signature() == &"", "rank IV without Shared Training: none yet")
	var growing := _plant("sporeling", Vector2(10, 2), [P, P, S])
	_check(growing.signature_hint() == "2 more Power ranks: Crushing at rank V", "the hint at rank III (%s)" % growing.signature_hint())
	_check(mixed.signature_hint() == "", "no hint at rank V")
	_check(Signatures.majority([W, W, W, W, ST], 5) == W and Signatures.BY_CHOICE[W] == Signatures.SHELTER, "Wide majority: Shelter")
	_check(Signatures.majority([Tower.Focus.KINDRED, Tower.Focus.KINDRED, Tower.Focus.KINDRED], 3) == Tower.Focus.NONE, "Kindred: none")

	# Crushing: the 5th hit lands x2 and strips 25% of the shell.
	_no_crits(striker)
	var target := _walker(Vector2(4, 4))
	var hits: Array[float] = []
	for i in 5:
		var before: float = target.health
		striker.hit(target, 1.0, false, Tower.NO_CRIT)
		hits.append(before - target.health)
	var plain := (hits[0] + hits[1] + hits[2] + hits[3]) / 4.0  # (Whole numbers: the fraction carries hit to hit)
	_check(absf(hits[4] / plain - 1.0) < 0.1, "Crushing: an unarmoured nightmare's 5th hit is plain (%.1f vs %.1f; ff93b498)" % [hits[4], plain])
	_check(striker._crush_hits == 5, "…and the count still moves on")
	var shelled := _walker(Vector2(4, 5))
	shelled.coat_max = 1000.0
	shelled.coat = 1000.0
	striker._crush_hits = 4
	striker.hit(shelled, 1.0, false, Tower.NO_CRIT)
	_check(shelled.coat <= 1000.0 * (1.0 - Signatures.CRUSH_SHELL) + 0.01, "Crushing: strips 25%% of the shell (%.0f left)" % shelled.coat)

	# Executioner: a crit under 20% health dispels a normal nightmare; a boss only takes the crit x1.5.
	var keen := _plant("sporeling", Vector2(12, 2), [K, K, K, K, S])
	var low := _walker(Vector2(12, 4))
	low.health = int(low.max_health * 0.15)
	keen.hit(low, 0.01, false, Tower.CRIT)
	_check(low.is_cleansed, "Executioner: a crit at 15% health dispels it")
	_no_crits(keen)
	var dull := _walker(Vector2(12, 6))
	var dull_before: float = dull.health
	for i in 10:
		keen.hit(dull, 1.0, false, Tower.NO_CRIT)
	var keen_avg: float = (dull_before - dull.health) / 10.0
	var base_hit: float = keen.get_damage()
	_check(absf(keen_avg / base_hit - Signatures.EXECUTE_PRICE) < 0.05,
		"Executioner: its hits deal 15%% less (%.2f of %.2f)" % [keen_avg, base_hit])
	var still := _walker(Vector2(12, 5))
	still.health = int(still.max_health * 0.5)
	keen.hit(still, 0.01, false, Tower.CRIT)
	_check(not still.is_cleansed, "Executioner: not at 50% health")

	# Relentless: a dispel starts the next cycle at once (at most every 0.5 s).
	var swift := _plant("sporeling", Vector2(14, 2), [S, S, S, S, P])
	var last := _walker(Vector2(14, 4))
	last.max_health = 5
	last.health = 1
	swift._cooldown = 3.0
	swift.hit(last, 1.0, false, Tower.NO_CRIT)
	_check(last.is_cleansed and swift._cooldown == 0.0, "Relentless: the dispel resets its cooldown (%.2f)" % swift._cooldown)
	# Audit a09297af: any dispel credited to it counts, a status tick too.
	var ticked := _walker(Vector2(14, 5))
	ticked.max_health = 5
	ticked.health = 1
	swift._cooldown = 3.0
	swift._relentless_at = -100.0
	ticked.take_damage(10.0, "spore", true, false, swift, &"spored")
	_check(ticked.is_cleansed and swift._cooldown == 0.0, "Relentless: a status-tick dispel credited to it counts too (%.2f)" % swift._cooldown)

	# Crushing counts ticks (audit a09297af): the 5th tick x2, the shell strip x the tick's share of a hit.
	var ticking := _walker(Vector2(4, 6))
	ticking.coat_max = 1000.0
	ticking.coat = 1000.0
	striker._crush_hits = 4
	striker.hit(ticking, 0.2, false, Tower.NO_CRIT, &"cloud")
	var stripped: float = 1000.0 - ticking.coat
	_check(stripped >= 1000.0 * Signatures.CRUSH_SHELL * 0.2 - 0.5 and stripped < 1000.0 * Signatures.CRUSH_SHELL * 0.5,
		"Crushing: a 20%% tick strips about 5%% of the shell (%.0f)" % stripped)
	striker._crush_hits = 4
	_check(is_equal_approx(striker.crush_tick(ticking, striker.get_damage() * 0.5), Signatures.CRUSH_MULTIPLIER), "Crushing: thorns / rain count (crush_tick)")

	# Spreading: half the stacks jump to the nearest nightmare within 2 cells when the carrier is dispelled.
	var deep := _plant("sporeling", Vector2(16, 2), [D, D, D, D, S])
	_check(deep.signature() == Signatures.SPREADING and get_first_node_in_group(Signatures.GROUP) != null, "Spreading: its watcher is made")
	var carrier := _walker(Vector2(16, 6))
	var next := _walker(Vector2(16, 6))
	next.global_position = carrier.global_position + Vector2(40, 0)
	carrier.apply_status(EnemyStatuses.SPORED, 6, 5.0, 10.0, 0, "spore", deep)
	var stacks: int = carrier.statuses.stacks(EnemyStatuses.SPORED)
	carrier.dispel()
	await process_frame
	_check(next.statuses.stacks(EnemyStatuses.SPORED) == stacks / 2, "Spreading: half the stacks jump (%d of %d)" % [next.statuses.stacks(EnemyStatuses.SPORED), stacks])
	_check(next.get_meta(Signatures.JUMPED, []).has(EnemyStatuses.SPORED), "…marked so they never jump again")

	# Spreading, audit a09297af: a hold's time left jumps whole; a puller's pull repeats on the nearest.
	var held_one := _walker(Vector2(18, 6))
	var held_next := _walker(Vector2(18, 6))
	held_next.global_position = held_one.global_position + Vector2(40, 0)
	held_one.apply_status(EnemyStatuses.HELD, 1, 2.0, 0.0, 0, "spore", deep)
	var hold_left: float = held_one.statuses.time_left(EnemyStatuses.HELD)
	held_one.dispel()
	await process_frame
	_check(absf(held_next.statuses.time_left(EnemyStatuses.HELD) - hold_left) < 0.1,
		"Spreading: a hold jumps whole (%.2f of %.2f)" % [held_next.statuses.time_left(EnemyStatuses.HELD), hold_left])
	# No signature where it would only fill a cell (c9de9302): a puller's Deep, a catcher's Wide / Strong, a beam's Swift.
	_check(_plant("rootcurl", Vector2(18, 2), [D, D, D, D, S]).signature() == &"mastery", "Rootcurl's Deep: no Spreading")
	_check(_plant("dewcatcher", Vector2(14, 12), [W, W, W, W, ST]).signature() == &"mastery", "Dewcatcher's Wide: no Shelter")
	_check(_plant("dewcatcher", Vector2(16, 14), [ST, ST, ST, ST, W]).signature() == &"mastery", "Dewcatcher's Strong: no Surge")
	_check(_plant("sunpetal", Vector2(18, 12), [S, S, S, S, P]).signature() == &"mastery", "Sunpetal's Swift: no Relentless")
	_check(Signatures.fits(_plant("prism_jar", Vector2(2, 14), []).tower_data, W), "Prism Jar keeps Shelter")

	# Shelter and Surge (aura supports).
	var shelter := _plant("elder_stump", Vector2(10, 10), [W, W, W, W, ST])
	var guarded := _plant("sporeling", Vector2(11, 10), [])
	_check(shelter.signature() == Signatures.SHELTER and guarded.is_sheltered(), "Shelter: the Warden in its aura is sheltered")
	guarded.wither(5.0)
	_check(not guarded.is_withered(), "Shelter: it can't be withered")
	var surge := _plant("elder_stump", Vector2(4, 12), [ST, ST, ST, ST, W])
	var calm := surge.get_aura_bonus(true)
	surge._update_surge(Signatures.SURGE_EVERY - Signatures.SURGE_TIME + 0.1)
	_check(surge._surging and is_equal_approx(surge.get_aura_bonus(true), calm * Signatures.SURGE_MULTIPLIER),
		"Surge: the aura doubles (%.3f -> %.3f)" % [calm, surge.get_aura_bonus(true)])
	surge._update_surge(Signatures.SURGE_TIME)
	_check(not surge._surging, "Surge: …for 2 s")

	# Actual stat payoffs, rather than only checking the signature name.
	mixed.rank = 4
	mixed._stats.clear()
	var plain_damage := mixed.get_damage() / mixed.get_rank_damage_multiplier()
	mixed.rank = 5
	mixed._stats.clear()
	_check(is_equal_approx(mixed.get_damage() / mixed.get_rank_damage_multiplier(), plain_damage * 1.2), "All-Rounder: damage really increases 20% without a speed bonus")
	var well := _plant("wellspring", Vector2(32, 32), [ST, ST, ST, ST, W])
	var caught := _walker(Vector2(32, 32))
	well.rank = 4
	well._stats.clear()
	var catch_before := well.get_catch_share(caught)
	well.rank = 5
	well._stats.clear()
	var expected_catch := (well.tower_data.catch_share + well.tower_data.catch_per_rank * well.get_effective_rank() + Tower.FOCUS_STRONG_CATCH * 4) * 1.2
	_check(well.signature() == Signatures.MASTERY and is_equal_approx(well.get_catch_share(caught), expected_catch) and well.get_catch_share(caught) > catch_before, "Wellspring Strong mastery: meaningful live catch bonus")
	var nurse := _plant("nurse_log", Vector2(36, 32), [ST, ST, ST, ST, W])
	nurse.rank = 4
	nurse._stats.clear()
	var reach_before := nurse._wide_radius()
	nurse.rank = 5
	nurse._stats.clear()
	_check(is_equal_approx(nurse._wide_radius(), reach_before * 1.2), "Nurse mastery adds reach even at the discount cap")
	var seed := _plant("seedbearer", Vector2(40, 32), [S, S, S, S, Tower.Focus.KINDRED])
	var child := _plant("sprout", Vector2(42, 32), [])
	child.set_meta(&"seeded_by", seed.get_instance_id())
	_check(is_equal_approx(BranchKit.damage_multiplier(child), (1.0 + NurtureChoices.SEED_KINDRED) * 1.2), "Seedbearer Swift mastery strengthens offspring despite the minimum drift timer")
	var control := _plant("rootcurl", Vector2(44, 32), [D, D, D, D, S])
	control.rank = 4
	control._stats.clear()
	var control_reach := control.get_range_cells()
	control.rank = 5
	control._stats.clear()
	_check(is_equal_approx(control.get_range_cells(), control_reach * 1.2), "Deep control mastery increases live reach")
	_check(Signatures.majority([Tower.Focus.KINDRED, Tower.Focus.KINDRED, Tower.Focus.KINDRED, Tower.Focus.KINDRED, W], 5) == Tower.Focus.KINDRED, "repeatable Kindred now qualifies for mastery")

	var sapling := _plant("heartwood_sapling", Vector2(52, 32), [P, P, P, P, S])
	_check(sapling.signature() == Signatures.MASTERY and is_equal_approx(sapling.get_drift_yield_exact(), (16.0 + 8.0 * 5) * 1.2), "Sapling: a specialised automatic economy form gets yield mastery, never a combat signature")
	var catcher := _plant("dreamcatcher", Vector2(56, 32), [ST, ST, ST, ST, D])
	_check(is_equal_approx(1.0 + catcher.get_caught_tick_bonus(), (1.0 + NurtureChoices.CAUGHT_STRONG * 4) * 1.2), "Dreamcatcher mastery: actual Caught tick rate x1.2, not projectile damage")

	var legacy := _plant("sporeling", Vector2(60, 32), [])
	legacy.rank = 5
	legacy.focus = Tower.Focus.POWER
	legacy._stats.clear()
	_check(Signatures.compute(legacy) == Signatures.CRUSHING and legacy.rank_choices.size() == 5, "legacy missing choices migrate before selecting a bonus, avoiding an incorrect first-frame All-Rounder multiplier")

	# Shared Training grants no rank-IV bonus for three matching picks.
	dreams.take(load("res://resource/dream/shared_training.tres"))
	var kin := Kinships.new()
	main.add_child(kin)
	young._kin = kin
	var partner := _plant("sporeling", Vector2(48, 32), [P, P, P, P])
	var pair := {"a": young, "b": partner}
	kin._partner[young.get_instance_id()] = [pair]
	_check(Signatures.compute(young) == Signatures.CRUSHING, "Shared Training: both rank-IV kin have four Power picks")
	partner.rank_choices.assign([P, P, P, S])
	_check(Signatures.compute(young) == &"", "Shared Training rejects a partner with only three matching picks")
	young._kin = null
	kin.free()
	print("signatures test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _plant(id: String, at: Vector2, choices: Array) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = at
	tower.position = Tower.MAP_GRID.calculate_map_position(at)
	placer.tower_container.add_child(tower)
	tower.set_process(false)
	tower.rank = choices.size()
	tower.rank_choices.assign(choices)
	tower._stats = {}
	return tower

func _no_crits(tower: Tower) -> void:
	tower.attack_data = tower.attack_data.duplicate()
	tower.attack_data.crit_chance = 0.0
	tower._stats = {}

func _walker(cell: Vector2) -> Node2D:
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"), 50.0)
	var e = spawner.get_child(spawner.get_child_count() - 1)
	e.set_process(false)
	e.global_position = Tower.MAP_GRID.calculate_map_position(cell)
	e.max_health = 100000
	e.health = 100000
	return e

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + what)
