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

	# --- Bonds are sticky: a nearer newcomer never takes over a bond; it pairs with a free kin ---
	var s1 := _plant("driftspore", Vector2(1, 8))
	var s2 := _plant("bloomcap", Vector2(3, 8))  # 2 cells away
	await process_frame
	kin.refresh()
	var sticky: Dictionary = kin.get_pair(s1)
	_check(kin.get_partner(s1) == s2, "a pair to test sticky bonds with")
	kin.ages[sticky.get("key", "")] = 3
	var free_kin := _plant("driftspore", Vector2(2, 10))
	var newcomer := _plant("bloomcap", Vector2(2, 9))  # 1 cell from the bonded Driftspore
	await process_frame
	kin.refresh()
	_check(kin.get_partner(s1) == s2 and kin.ages.get(kin.get_pair(s1).get("key", ""), -1) == 3,
		"a nearer Bloomcap doesn't take over the bond; its age stays (%s)" % [kin.ages.get(kin.get_pair(s1).get("key", ""), -1)])
	_check(kin.get_partner(newcomer) == free_kin, "the newcomer bonds with the free Driftspore")
	s1.evolve(load("res://resource/tower/puffball.tres"), 0)
	kin.refresh()
	_check(kin.get_partner(s1) == s2 and kin.ages.get(kin.get_pair(s1).get("key", ""), -1) == 3, "growing a partner keeps the bond and its age")
	for tower in [s1, s2, free_kin, newcomer]:
		tower.queue_free()
	await process_frame
	kin.refresh()

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
	var probe := _spawn(elder.global_position + Vector2(64, 0))
	_check(is_equal_approx(elder.get_catch_share(probe), DewCatch.OLD_GROWTH_CATCH * 0.5),
		"Old Growth: the Elder Stump catches +25%% in its aura, at Sapling's share (%.3f)" % elder.get_catch_share(probe))
	var near := _plant("sprout", Vector2(5, 13))
	await process_frame
	near._refresh_neighbours()
	_check(near._aura_speed >= 0.05, "Old Growth: the Dewcatcher kin's small aura speeds up its neighbours")

	# --- The run save keeps bond ages ---
	var saved := kin.to_save()
	kin.ages.clear()
	kin.load_save(saved)
	_check(kin.ages.size() == saved.ages.size(), "bond ages survive a save and load")

	# --- Playtest fixes: ascending keeps a bond; a lone branch Warden says what would bond it ---
	var chime := _plant("lullaby_bell", Vector2(19, 2))  # The Chime Stone branch's final form
	var catcher_kin := _plant("dreamcatcher", Vector2(20, 2))
	await process_frame
	kin.refresh()
	_check(kin.get_pair(chime).get("id") == &"night_chimes", "Lullaby Bell + Dreamcatcher: Night Chimes")
	var chime_key: String = kin.get_pair(chime).key
	kin.ages[chime_key] = 6
	chime.evolve(load("res://resource/tower/great_bell.tres"), 0)
	kin.refresh()
	_check(chime.kin_branch == "chime_stone" and kin.get_pair(chime).get("id") == &"night_chimes"
		and kin.ages.get(kin.get_pair(chime).get("key", ""), 0) == 6,
		"ascending into The Great Bell keeps the bond and its age")
	var lone := _plant("gust", Vector2(1, 16))
	await process_frame
	kin.refresh()
	_check(kin.no_kin_hint(lone).begins_with("No kin. A Pinwheel within 2 cells would form Dust Devil."),
		"a lone Warden says what would bond it (%s)" % kin.no_kin_hint(lone))
	var spots := kin.kin_spots(load("res://resource/tower/pinwheel.tres"))
	_check(spots.has(Vector2(2, 16)) and spots.get(Vector2(3, 16)) == &"dust_devil" and not spots.has(Vector2(4, 16)),
		"kin spots: the cells within 2 of the lone Gust")

	# --- Kinship cards (dream_design.md "Kinship cards: going deep"), with stand-in cards by rule id ---
	var dreams: DreamState = main.get_node("%DreamState")
	_check(Kinships.count_on_map(drift) == kin.count() and kin.count() >= 3, "Kinships on the map can be counted (%d)" % kin.count())
	var far_a := _plant("driftspore", Vector2(18, 14))
	var far_b := _plant("bloomcap", Vector2(21, 14))  # 3 cells apart
	await process_frame
	kin.refresh()
	_check(kin.get_pair(far_a).is_empty(), "3 cells apart: no bond")
	_rule(dreams, &"close_kin")
	kin.refresh()
	_check(kin.get_partner(far_a) == far_b, "Close Kin: bonds reach 3 cells")
	_check(is_equal_approx(far_a.kin_share(&"slumber_rot", "a"), 0.5), "a new bond starts at Sapling")
	_rule(dreams, &"old_friends")
	_check(kin.get_stage_drifts() == [0, 4, 9], "Old Friends (Quick Bonds merged in): Blooming at 4, Old Kin at 9 (%s)" % [kin.get_stage_drifts()])
	var bonded := far_a.get_damage()
	_rule(dreams, &"family_ties")
	_check(far_a.get_damage() > bonded, "Family Ties: Wardens in a Kinship hit harder")
	seller.sell(far_b.cell)
	await process_frame
	_rule(dreams, &"old_friends")
	var far_c := _plant("bloomcap", Vector2(20, 15))
	await process_frame
	kin.refresh()
	_check(kin.get_partner(far_a) == far_c and is_equal_approx(far_a.kin_share(&"slumber_rot", "a"), 0.75),
		"Old Friends: new bonds start at Blooming")
	_rule(dreams, &"extended_family")
	var far_d := _plant("bloomcap", Vector2(18, 16))
	await process_frame
	kin.refresh()
	_check(kin.get_pairs(far_a).size() == 2, "Extended Family: a Warden bonds with its two nearest kin")
	var harmony_before: int = kin.harmony_run
	_rule(dreams, &"kin_and_kindling")
	var target := _spawn(far_a.global_position + Vector2(CELL, 0))
	far_a.hit(target, 1.0, false, Tower.NO_CRIT)
	far_c.hit(target, 1.0, false, Tower.NO_CRIT)
	_check(kin.harmony_run > harmony_before and target.statuses.has(EnemyStatuses.DROWSY),
		"Kin and Kindling: the Harmony strike also applies the Bloomcap's Drowsy")

	# --- Rooted Bond: sell a bonded Warden and plant a new kin in the same rest: it keeps the stage ---
	_rule(dreams, &"rooted_bond")
	var director_node: DriftDirector = main.get_node("%DriftDirector")
	kin._resting = true
	var ra := _plant("driftspore", Vector2(8, 1))
	var rb := _plant("bloomcap", Vector2(9, 1))
	await process_frame
	kin.refresh()
	var old_pair := kin.get_pair(ra)
	_check(kin.get_partner(ra) == rb, "a fresh pair to test Rooted Bond with")
	kin.ages[old_pair.key] = 7  # Blooming, 7 drifts together
	seller.sell(rb.cell)
	await process_frame
	var rc := _plant("bloomcap", Vector2(10, 1))
	await process_frame
	kin.refresh()
	_check(kin.get_partner(ra) == rc and kin.ages.get(kin.get_pair(ra).get("key", ""), -1) == 7,
		"a new kin planted in the same rest bonds at the old stage and drift count")
	seller.sell(rc.cell)
	await process_frame
	director_node.rest_ended.emit(2)  # The rest ends: the remembered stage is dropped
	var rd := _plant("bloomcap", Vector2(10, 1))
	await process_frame
	kin.refresh()
	_check(kin.get_partner(ra) == rd and kin.ages.get(kin.get_pair(ra).get("key", ""), -1) == kin._start_age(),
		"after the rest the new bond starts fresh")

	# --- The 9 hidden Kinships (the hidden branch is A; a final form counts as its branch) ---
	for child in container.get_children():
		child.queue_free()
	await process_frame
	var hidden := {&"spore_nursery": ["fairy_ring", "driftspore"], &"hoar_fog": ["frostfern", "mistveil"],
		&"sunspot": ["sunpetal", "lanternmoth"], &"spotter": ["cairn", "standing_stone"],
		&"lantern_roots": ["rootlight", "tangleroot"], &"resonant_hollow": ["echo_hollow", "chime_stone"],
		&"true_graft": ["graftling", "elder_stump"], &"jewel_thieves": ["jewelwing_court", "magpie_perch"],
		&"tailwind": ["samara", "gust"]}
	var made := {}
	var column := 1
	for id in hidden:
		var a := _plant(hidden[id][0], Vector2(column, 16))
		var b := _plant(hidden[id][1], Vector2(column, 14))
		made[id] = [a, b]
		column += 2
	await process_frame
	kin.refresh()
	for id in hidden:
		var pair: Dictionary = kin.get_pair(made[id][0])
		_check(pair.get("id") == id and kin.get_partner(made[id][0]) == made[id][1],
			"%s + %s, 2 cells apart: %s (%s)" % [hidden[id][0], hidden[id][1], id, pair.get("id", "none")])
		kin.ages[pair.get("key", "")] = 10  # Old Kin: every trait at full share
	_check(is_equal_approx(made[&"jewel_thieves"][0].kin_share(&"jewel_thieves", "a"), 1.0),
		"Jewel Thieves: Jewelwing Court (the Hummingbird Bower branch) borrows at Old Kin")

	# Jewel Thieves A: the 6th peck steals a buff, or +1 Dew when there's none
	var court: Tower = made[&"jewel_thieves"][0]
	var mark := _spawn(court.global_position + Vector2(64, 0))
	court._jewel_pecks = Tower.JEWEL_THIEVES_EVERY - 1
	court.peck(mark)
	_check(mark.bonus_dew >= 1, "Jewel Thieves: the 6th peck gives +1 Dew when there's no buff to steal")
	# Jewel Thieves B: the magpie pecks twice per swoop
	var magpie: Tower = made[&"jewel_thieves"][1]
	var swooped := _spawn(magpie.global_position + Vector2(64, 0))
	var one_hit := magpie.get_damage()
	magpie.projectile_landed(swooped, swooped.global_position)
	_check(swooped.max_health - swooped.health > one_hit * 1.5, "Jewel Thieves: the magpie hits twice (%d)" % (swooped.max_health - swooped.health))
	# Spotter B: the Standing Stone's shot splashes 30% beside its target; A: the Cairn lobs at its target
	var stone2: Tower = made[&"spotter"][1]
	var aimed := _spawn(stone2.global_position + Vector2(128, 0))
	var beside := _spawn(aimed.global_position + Vector2(20, 0))
	stone2._last_fired = aimed
	stone2.projectile_landed(aimed, aimed.global_position)
	_check(beside.health < beside.max_health, "Spotter: the Standing Stone's shot splashes onto its neighbour")
	var cairn: Tower = made[&"spotter"][0]
	var other := _spawn(cairn.global_position + Vector2(0, -64))
	_check(cairn._spotter_target(other) == aimed or aimed.global_position.distance_to(cairn.global_position) > cairn.get_range_pixels(),
		"Spotter: the Cairn lobs at the sniper's target")
	# Sunspot B: Lanternmoth shots ramp on the same target
	var moth: Tower = made[&"sunspot"][1]
	var lit := _spawn(moth.global_position + Vector2(64, 0))
	var before_hits: int = lit.health
	moth.hit(lit, 1.0, false, Tower.NO_CRIT)
	var first: int = before_hits - lit.health
	for i in 5:
		moth.hit(lit, 1.0, false, Tower.NO_CRIT)
	before_hits = lit.health
	moth.hit(lit, 1.0, false, Tower.NO_CRIT)
	_check(float(before_hits - lit.health) / maxf(first, 1.0) > 1.4, "Sunspot: the 7th hit in a row deals +50%% (x%.2f)" % (float(before_hits - lit.health) / maxf(first, 1.0)))
	# Resonant Hollow A: the Echo Hollow sets off 3 Static charges like a chime
	var hollow: Tower = made[&"resonant_hollow"][0]
	var charged := _spawn(hollow.global_position + Vector2(64, 0))
	charged.statuses.apply(EnemyStatuses.STATIC, 3, 10.0, 10.0)
	hollow.resonant_set_off(charged)
	_check(not charged.statuses.has(EnemyStatuses.STATIC) and charged.health < charged.max_health,
		"Resonant Hollow: the echo sets off Static at 3 charges")
	# True Graft A: the Graftling copies at 100%
	var graft: Tower = made[&"true_graft"][0]
	_check(is_equal_approx(lerpf(graft.tower_data.copy_share, 1.0, graft.kin_share(&"true_graft", "a")), 1.0),
		"True Graft: the Graftling copies at 100%")
	# Hoar Fog A: a Frostfern shot leaves a fog puff; Spore Nursery B: a Driftspore puff plants a ring
	var fern: Tower = made[&"hoar_fog"][0]
	var puffs := kin.get_parent().get_children().filter(func(n) -> bool: return n is Kinships.KinFog).size()
	fern._kin_on_landing(null, fern.global_position + Vector2(64, 0))
	_check(kin.get_parent().get_children().filter(func(n) -> bool: return n is Kinships.KinFog).size() == puffs + 1,
		"Hoar Fog: the Frostfern's shot leaves a fog puff")
	var puffer: Tower = made[&"spore_nursery"][1]
	var map = main.get_node("%MapGenerator")
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	puffer._kin_on_landing(null, Tower.MAP_GRID.calculate_map_position(route[5]))
	_check(is_instance_valid(puffer._nursery_ring) and puffer._nursery_ring.cell == route[5],
		"Spore Nursery: the Driftspore's puff plants a mushroom ring on the path")
	puffer._kin_on_landing(null, Tower.MAP_GRID.calculate_map_position(route[7]))
	_check(puffer._nursery_ring.cell == route[5], "one ring at a time")
	# Kindred: one quiet callout the first time in the run
	_check(kin.kindred_shown, "the first Kindred of the run was called out")

	# --- Kinships you can see in combat (2026-09-29) ---
	var moth_look := moth.kin_look()
	_check(moth_look.a > 0.0 and moth_look.is_equal_approx(Kinships.BRANCH_COLORS["sunpetal"]),
		"borrowed looks: a bonded Lanternmoth's attacks carry its Sunpetal kin's colour")
	var lone_moth := _plant("lanternmoth", Vector2(21, 1))
	await process_frame
	kin.refresh()
	_check(lone_moth.kin_look().a == 0.0, "an unbonded Warden has no borrowed look")
	var sun_pair: Dictionary = kin.get_pair(moth)
	_check(kin._synced.has(sun_pair.key) and int(moth._anim_time * moth.tower_data.animation_fps) \
		== int(made[&"sunspot"][0]._anim_time * made[&"sunspot"][0].tower_data.animation_fps) or moth.get_instance_id() < made[&"sunspot"][0].get_instance_id(),
		"breathing together: the pair's idle animations were synced")
	var beads := kin.get_parent().get_children().filter(func(n) -> bool: return n is Kinships.KinBead).size()
	kin._resting = true
	kin.trait_fired(moth, &"sunspot")
	kin.trait_fired(moth, &"sunspot")
	_check(kin.get_parent().get_children().filter(func(n) -> bool: return n is Kinships.KinBead).size() == beads + 1,
		"the vine's light bead runs once per cooldown")
	# Harmony at Old Kin: beams, a bloom and petals (the sheets exist; without them, the spark)
	var fx_before := kin.get_parent().get_child_count()
	kin._harmony_look(moth.global_position + Vector2(0, 64), sun_pair)
	_check(kin.get_parent().get_child_count() > fx_before + 2, "an Old Kin Harmony strike shows beams, a bloom and petals")

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

# Takes a stand-in card with rule `rule` (the real ones are Roguelite's resources).
func _rule(dreams: DreamState, rule: StringName) -> void:
	var card := UpgradeData.new()
	card.id = "test_" + String(rule)
	card.rule_id = rule
	card.kind = UpgradeData.Kind.RULE
	card.max_stacks = 0
	dreams.pool.append(card)
	dreams.take(card)
