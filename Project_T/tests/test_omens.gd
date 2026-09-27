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
	_check(omens.pool.size() == 8, "8 Omens in the pool (%d)" % omens.pool.size())
	await _test_flow(main)
	_test_twists(main)
	_test_rewards(main)
	print("omens test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

# Rest after drift 5: no Omen yet. Rest after drift 10: the Dream first, then 2 Omens for 11–15.
func _test_flow(main: Node) -> void:
	var omens: OmenDirector = main.get_node("%OmenDirector")
	var dreams: DreamState = main.get_node("%DreamState")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var offers := []
	omens.offer_ready.connect(func(o: Array, block: int) -> void: offers.append([o, block]))
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
	_check(offers.size() == 1 and offers[0][1] == 3, "Omens offered for block 3 after the Dream closes")
	var offer: Array = offers[0][0] if not offers.is_empty() else []
	_check(offer.size() == 2 and offer[0] != offer[1], "2 different Omens")
	var has_flyers := omens._block_has_flyers(omens.get_block_range(3))
	_check(has_flyers or not offer.any(func(o: OmenData) -> bool: return o.requires_flyers),
		"no Moth Night without flyers in the block")
	_check(paused, "the game pauses for Omens")
	omens.choose(null)
	_check(omens.active == null and not omens.is_offering() and not paused, "Clear Skies: nothing changes")

func _test_twists(main: Node) -> void:
	var omens: OmenDirector = main.get_node("%OmenDirector")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var spawner = main.get_node("%EnemyContainer")
	var bug: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	var stag: EnemyData = load("res://resource/enemy/old_stag.tres")

	_activate(omens, "thick_blight", 3)
	_check(is_equal_approx(director.get_health_scale(bug, 11), pow(director.health_growth_per_drift, 10) * 1.2),
		"Thick Blight: +20% health in its block")
	_check(is_equal_approx(director.get_health_scale(bug, 16), pow(director.health_growth_per_drift, 15)),
		"Thick Blight: only its own block")
	_check(is_equal_approx(director.get_health_scale(stag, 15), director.boss_health_multiplier), "bosses ignore Omens")

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
	_check(omens.is_offering(), "a new Omen offer follows at the same rest")
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

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
