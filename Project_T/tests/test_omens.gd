extends SceneTree

# Headless test for Omens (run_design.md, "Omens"): offers at rests from drift 10, after the Dream;
# the chosen Omen twists only the next block (not bosses); rewards at the rest after it.
#   godot --headless --path . --script res://tests/test_omens.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	var omens: OmenDirector = main.get_node("%OmenDirector")
	_check(omens.pool.size() == 20, "20 Omens in the pool (%d)" % omens.pool.size())
	await _test_flow(main)
	_test_twists(main)
	_test_rewards(main)
	_test_new_omens(main)
	print("omens test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

# Rest after drift 5: no Omen yet. Rest after drift 10: the Dream first, then 2 Omens for 11–15.
func _test_flow(main: Node) -> void:
	var omens: OmenDirector = main.get_node("%OmenDirector")
	var dreams: DreamState = main.get_node("%DreamState")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var offers := []
	omens.offer_ready.connect(func(o: Array, block: int) -> void: offers.append([o, block]))
	omens.mode_override = "ask"  # Not the player's setting
	director.drifts_started = 5
	director.rest_started.emit(1, false, 30, true)
	await _frames(2)
	_check(offers.is_empty(), "no Omens before drift 10")
	if dreams.is_offering():
		dreams.skip()
	await _frames(2)

	director.drifts_started = 10
	director.rest_started.emit(2, false, 40, true)
	await _frames(2)
	_check(dreams.is_offering() and offers.is_empty(), "the Dream comes before the Omens")
	dreams.skip()
	await _frames(2)
	# Shown like a Dream: the Omen screen opens right after the Dream, with a third Clear Skies card
	_check(offers.size() == 1 and offers[0][1] == 3 and omens.is_offering(), "after the Dream: the Omen screen for block 3")
	var offer: Array = offers[0][0] if not offers.is_empty() else []
	_check(offer.size() == 2 and offer[0] != offer[1], "2 different Omens")
	var has_flyers := omens._block_has_flyers(omens.get_block_range(3))
	_check(has_flyers or not offer.any(func(o: OmenData) -> bool: return o.requires_flyers),
		"no Moth Night without flyers in the block")
	_check(paused, "the game pauses for the Omen screen")
	var screen = main.get_node("HUD/OmenScreen")
	_check(screen._cards.get_child_count() == 3, "three cards: two Omens and Clear Skies")
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	screen._unhandled_input(esc)
	_check(omens.active == null and not omens.is_offering() and not paused, "Esc = Clear Skies: nothing changes")

	# Never: no screen at all
	director.drifts_started = 15
	omens.mode_override = "never"
	omens.current_offer = omens.make_offer(4)
	omens.current_offer_block = 4
	omens._offer_waiting = true
	offers.clear()
	omens._try_show()
	_check(offers.is_empty() and not omens.is_offering(), "Omens: Never = always Clear Skies, no screen")
	# A Blight Level that forces an Omen: the cards at once, no Clear Skies
	omens.mode_override = "ask"
	omens.force_omen = true
	omens.current_offer = omens.make_offer(4)
	omens._offer_waiting = true
	omens._try_show()
	var forced_offer: Array = omens.current_offer.duplicate()
	omens.choose(null)
	_check(omens.is_offering() and omens.forced, "a forced Omen can't be declined")
	omens.choose(forced_offer[0])
	_check(omens.active == forced_offer[0] and not omens.is_offering(), "…one is faced")
	omens.force_omen = false
	omens.active = null
	omens._last_offer_ids.clear()
	# An open Omen offer comes back after a save (as the Omen screen)
	omens.current_offer = omens.make_offer(4)
	omens.current_offer_block = 4
	var saved := omens.to_save()
	omens.current_offer = []
	omens.load_save(JSON.parse_string(JSON.stringify(saved)))
	_check(omens.current_offer.size() == 2 and omens.current_offer_block == 4 and not omens.showing, "an open Omen offer comes back after a save")
	omens.current_offer = []
	omens._offer_waiting = false

func _test_twists(main: Node) -> void:
	var omens: OmenDirector = main.get_node("%OmenDirector")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var spawner = main.get_node("%EnemyContainer")
	var bug: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	var stag: EnemyData = load("res://resource/enemy/old_stag.tres")

	_activate(omens, "thick_blight", 3)
	_check(is_equal_approx(director.get_health_scale(bug, 11), pow(director.health_growth_per_drift, 10) * director.get_early_multiplier(11) * 1.2),
		"Thick Blight: +20% health in its block")
	_check(is_equal_approx(director.get_health_scale(bug, 16), pow(director.health_growth_per_drift, 15) * director.get_early_multiplier(16)),
		"Thick Blight: only its own block")
	_check(is_equal_approx(director.get_health_scale(stag, 15), director.boss_health_multiplier * director.get_early_multiplier(15)), "bosses ignore Omens")

	_activate(omens, "crowded_paths", 3)
	var drift: DriftData = director.drifts[10]
	var plain := drift.get_schedule().size()
	var mods := director.get_schedule_modifiers(11)
	var crowded := drift.get_schedule(mods.count, mods.flyers, mods.spacing).size()
	_check(crowded > plain, "Crowded Paths: more creatures (%d → %d)" % [plain, crowded])

	_activate(omens, "restless_wind", 3)
	mods = director.get_schedule_modifiers(11)
	var closer := drift.get_schedule(mods.count, mods.flyers, mods.spacing)
	_check(closer[-1][0] < drift.get_schedule()[-1][0] * 0.71, "Restless Wind: arrivals 30% closer together")

	_activate(omens, "dry_spell", 3)
	var dry: Node2D = spawner.spawn_enemy(bug, 1.0, director.get_spawn_modifiers(bug, 12))
	_check(dry.get_dew_reward() == 0, "Dry Spell: creatures give no Dew")
	dry.free()
	_activate(omens, "swift_stream", 3)
	var swift: Node2D = spawner.spawn_enemy(bug, 1.0, director.get_spawn_modifiers(bug, 12))
	_check(is_equal_approx(swift.speed, bug.speed * 1.15), "Swift Stream: +15% speed")
	swift.free()
	_activate(omens, "stubborn_blight", 3)
	var stubborn: Node2D = spawner.spawn_enemy(bug, 1.0, director.get_spawn_modifiers(bug, 12))
	stubborn.apply_status(EnemyStatuses.DAMP)
	_check(is_equal_approx(stubborn.statuses.time_left(EnemyStatuses.DAMP), 2.0), "Stubborn Blight: statuses last half as long")
	stubborn.free()
	_check(director.get_spawn_modifiers(stag, 15).is_empty(), "bosses get no Omen modifiers")
	omens.active = null

func _test_rewards(main: Node) -> void:
	var omens: OmenDirector = main.get_node("%OmenDirector")
	var dreams: DreamState = main.get_node("%DreamState")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var run_state: RunState = main.get_node("%RunState")
	director.drifts_started = 15

	_activate(omens, "crowded_paths", 3)
	var dew := run_state.dew
	omens._on_rest_started(3, false, 50, true)
	_check(run_state.dew == dew + 40 and omens.active == null, "Crowded Paths pays 40 Dew at the rest after its block (act 1)")
	_check(omens.is_offering() or omens._offer_waiting, "a new Omen offer follows at the same rest")
	omens.current_offer = []
	omens._offer_waiting = false

	_activate(omens, "dry_spell", 3)
	dew = run_state.dew
	omens._on_rest_started(3, false, 50, true)
	_check(run_state.dew == dew + 50, "Dry Spell: rest bonus ×2 (+50 on a 50 bonus)")
	omens.current_offer = []
	omens._offer_waiting = false

	_activate(omens, "thick_blight", 3)
	omens._on_rest_started(3, false, 50, true)
	omens.current_offer = []
	omens._offer_waiting = false
	dreams.unlocked["firefly_jar"] = true
	_check(dreams.make_offer(15).size() == 4, "Thick Blight: the next Dream offers 4 cards")
	_check(dreams.make_offer(20).size() == 3, "…only the next one")

	_activate(omens, "restless_wind", 3)
	var max_leaves := run_state.max_leaves
	omens._on_rest_started(3, false, 50, true)
	_check(run_state.max_leaves == max_leaves + 1, "Restless Wind: +1 max leaf")
	omens.current_offer = []
	omens._offer_waiting = false

	_activate(omens, "hard_bark", 3)
	omens._on_rest_started(4, false, 50, true)
	_check(omens.active != null, "no reward at a rest for a different block")

	# Winning during an Omen's block still pays (Seeds count), scaled by the act
	_activate(omens, "swift_stream", 10)
	director.drifts_started = 50
	run_state.end_run(true)
	_check(run_state.omen_seeds == roundi(3 * OmenDirector.ACT_REWARD_SCALE[1]), "Swift Stream pays Seeds on a win, act 2 ×1.5 (%d)" % run_state.omen_seeds)

func _activate(omens: OmenDirector, id: String, block: int) -> void:
	for omen in omens.pool:
		if omen.id == id:
			omens.active = omen
			omens.active_block = block
			return
	_check(false, "Omen %s exists" % id)

# The 12 Omens from "More Omens" (run_design.md): offer rules, and each twist / reward on our side.
func _test_new_omens(main: Node) -> void:
	var omens: OmenDirector = main.get_node("%OmenDirector")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var dreams: DreamState = main.get_node("%DreamState")
	var run_state: RunState = main.get_node("%RunState")
	var map_generator = main.get_node("%MapGenerator")
	var by_id := {}
	for omen in omens.pool:
		by_id[omen.id] = omen
	# Offer rules: two different kinds, never an Omen from the previous rest
	omens._last_offer_ids.clear()
	# An open Omen offer comes back after a save (as the Omen screen)
	omens.current_offer = omens.make_offer(4)
	omens.current_offer_block = 4
	var saved := omens.to_save()
	omens.current_offer = []
	omens.load_save(JSON.parse_string(JSON.stringify(saved)))
	_check(omens.current_offer.size() == 2 and omens.current_offer_block == 4 and not omens.showing, "an open Omen offer comes back after a save")
	omens.current_offer = []
	omens._offer_waiting = false
	var previous: Array = []
	var ok_kinds := true
	var no_repeat := true
	for i in 60:
		var offer := omens.make_offer(11)  # Drifts 51–55: every Omen can show
		if offer.size() == 2 and offer[0].kind == offer[1].kind:
			ok_kinds = false
		if offer.any(func(o: OmenData) -> bool: return previous.has(o.id)):
			no_repeat = false
		previous = offer.map(func(o: OmenData) -> String: return o.id)
	_check(ok_kinds, "each offer's 2 Omens are of different kinds")
	_check(no_repeat, "an Omen never repeats from the previous rest")
	var waiting: Array = omens.pool.filter(func(o: OmenData) -> bool: return o.waiting_for_hook)
	var ever := {}
	for i in 60:
		for o in omens.make_offer(11):
			ever[o.id] = true
	_check(not waiting.any(func(o: OmenData) -> bool: return ever.has(o.id)), "Omens waiting for their Tower / Enemy hooks are never offered (%d waiting)" % waiting.size())
	_check(not omens.make_offer(3).any(func(o: OmenData) -> bool: return o.min_drift > 11), "act 2 Omens wait for act 2")

	# Your side: Fog Bank, Wilting, Frozen Ground, Leaf Fall (the queries Tower / TowerPlacer / RunState ask)
	director.drifts_started = 51
	omens.active_block = director.get_block(51)
	omens.active = by_id["fog_bank"]
	_check(omens.get_warden_range_add() == -1.0, "Fog Bank: −1 range")
	omens.active = by_id["wilting"]
	_check(is_equal_approx(omens.get_warden_speed_multiplier(), 0.85), "Wilting: −15% attack speed")
	omens.active = by_id["frozen_ground"]
	director.resting = false
	_check(omens.blocks_building(), "Frozen Ground: no building during a drift")
	director.resting = true
	_check(not omens.blocks_building(), "…fine at a rest")
	omens.active = by_id["leaf_fall"]
	_check(omens.get_leak_multiplier() == 2.0, "Leaf Fall: leaks ×2")

	# Lean Season: the rest bonus is halved, the next Dream (act 2+) includes a Legendary
	omens.active = by_id["lean_season"]
	run_state.dew = 200
	omens._pay_reward(100)
	_check(run_state.dew == 150, "Lean Season: half the 100 rest bonus is lost (%d)" % run_state.dew)
	var offer := dreams.make_offer(51)
	_check(offer.any(func(c: UpgradeData) -> bool: return c.rarity == UpgradeData.Rarity.LEGENDARY), "…the next Dream includes a Legendary")

	# Double-edged and nightmare Omens through the spawn modifiers / schedule
	omens.active = by_id["heavy_rain"]
	omens.active_block = director.get_block(51)
	_check(omens.get_spawn_modifiers(51).get("always_status") == &"damp" and is_equal_approx(omens.get_multiplier(51, "health_multiplier"), 1.35),
		"Heavy Rain: always Soaked, +35% health")
	omens.active = by_id["sleepless"]
	_check(Array(omens.get_spawn_modifiers(51).get("status_immune", [])) == [&"drowsy", &"held"], "Sleepless: immune to Drowsy and Held")
	_check(omens.describe_reward(by_id["blood_moon"], 3) == "" and omens.describe_reward(by_id["harvest_moon"], 3) == "",
		"Blood Moon / Harvest Moon: no separate reward")
	var bug: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	omens.active = by_id["elder_night"]
	var schedule := []
	for i in 5:
		schedule.append([i * 1.0, bug, false])
	omens.shape_schedule(schedule, 51)
	_check(schedule.filter(func(a: Array) -> bool: return a[2]).size() == 1, "Elder Night: +1 elite per drift")
	var flyers := omens._block_flyers(omens.get_block_range(director.get_block(51)))
	if not flyers.is_empty():
		omens.active = by_id["hollow_wind"]
		schedule = [[0.0, bug, false], [1.0, bug, false]]
		omens.shape_schedule(schedule, 51)
		_check(schedule.all(func(a: Array) -> bool: return a[1].trait_kind == EnemyData.Trait.FLYING), "Hollow Wind: the first drifts are all flyers")
		schedule = [[0.0, bug, false]]
		omens.shape_schedule(schedule, 53)
		_check(schedule[0][1] == bug, "…only the first 2")

	# Shifting Ground: 3 trees on free cells away from the route, once; then +1 Seed per tree cleared
	omens.active = by_id["shifting_ground"]
	omens._sprouted_block = 0
	var route_before: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	var obstacles_before: int = map_generator.obstacles.size()
	omens._on_drift_started(51)
	omens._on_drift_started(52)
	_check(map_generator.obstacles.size() == obstacles_before + 3, "Shifting Ground: 3 trees sprout, once (%d)" % (map_generator.obstacles.size() - obstacles_before))
	_check(map_generator.get_path_from(map_generator.startPath) == route_before, "…never changing the route")
	omens._pay_reward(0)
	_check(omens.tree_seed_bonus == 1, "…reward: +1 Seed per tree cleared")
	var tree_cell: Vector2 = map_generator.obstacles.keys().filter(func(c: Vector2) -> bool:
		return map_generator.obstacles[c] == OmenDirector.TREE)[0]
	var seeds := run_state.omen_seeds
	map_generator.clear_obstacle(tree_cell)
	_check(run_state.omen_seeds == seeds + 1, "…a cleared Withered Tree gives the extra Seed")
	omens.tree_seed_bonus = 0
	omens.active = null
	director.drifts_started = 0

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
