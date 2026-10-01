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
	_check(omens.pool.size() == 23, "23 Omens in the pool (%d)" % omens.pool.size())
	await _test_flow(main)
	_test_twists(main)
	_test_rewards(main)
	_test_new_omens(main)
	_test_offer_conditions(main)
	_test_teeth(main)
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
	_check(offer.size() == 2 and offer[0] != offer[1], "2 different Omens drawn (hidden until faced)")
	var has_flyers := omens._block_has_flyers(omens.get_block_range(3))
	_check(has_flyers or not offer.any(func(o: OmenData) -> bool: return o.requires_flyers),
		"no Moth Night without flyers in the block")
	_check(paused, "the game pauses for the Omen screen")
	var screen = main.get_node("HUD/OmenScreen")
	_check(screen._cards.get_child_count() == 2 and screen._cards.get_child(0).name == "FaceAnOmen", "two cards: Face an Omen (face-down) and Clear Skies")
	var names: Array = screen.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
	_check(not offer.any(func(o: OmenData) -> bool: return names.has(o.display_name)), "the drawn Omens stay hidden until faced")
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	screen._unhandled_input(esc)
	_check(omens.active == null and not omens.is_offering() and not paused, "Esc = Clear Skies: nothing changes")
	# Face an Omen: the drawn Omens are revealed, one must be picked (no going back)
	director.drifts_started = 15
	omens._last_offer_ids.clear()
	omens.current_offer = omens.make_offer(4)
	omens.current_offer_block = 4
	var drawn: Array = omens.current_offer.duplicate()
	omens._show_cards()
	await _frames(2)
	(screen._cards.get_child(0) as Button).pressed.emit()
	await _frames(30)
	_check(omens.faced and omens.is_offering() and omens.active == null, "Face an Omen: its Omens are revealed, none picked yet")
	_check(screen._cards.get_child_count() == 2 and screen._cards.get_children().all(func(c: Node) -> bool: return c.name.begins_with("Omen_")),
		"…the card flips to the 2 Omens, Clear Skies is gone")
	screen._unhandled_input(esc)
	omens.choose(null)
	_check(omens.is_offering() and omens.active == null, "…no going back: Esc and Clear Skies do nothing")
	var saved_faced := omens.to_save()
	(screen._cards.get_child(1) as Button).pressed.emit()
	_check(omens.active == drawn[1] and not omens.is_offering() and not paused and not omens.faced, "…a click picks that Omen")
	omens.active = null
	omens.load_save(JSON.parse_string(JSON.stringify(saved_faced)))
	_check(omens.faced and omens.current_offer.size() == 2, "a save made after facing keeps it faced (no Clear Skies on load)")
	omens.current_offer = []
	omens.faced = false
	omens._offer_waiting = false
	omens._last_offer_ids.clear()
	omens.active = null

	# Never: no screen at all
	director.drifts_started = 15
	omens.mode_override = "never"
	omens.current_offer = omens.make_offer(4)
	omens.current_offer_block = 4
	omens._offer_waiting = true
	offers.clear()
	omens._try_show()
	_check(offers.is_empty() and not omens.is_offering(), "Omens: Never = always Clear Skies, no screen")
	# A Blight Level that forces an Omen: the Omens at once, no Clear Skies
	omens.mode_override = "ask"
	omens.force_omen = true
	omens.current_offer = omens.make_offer(4)
	omens._offer_waiting = true
	var forced_offer: Array = omens.current_offer.duplicate()
	omens._try_show()
	await _frames(2)
	omens.choose(null)
	_check(omens.is_offering() and omens.forced and omens.faced and screen._cards.get_child_count() == 2,
		"a forced Omen skips the first screen: its Omens at once, can't be declined")
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
	_check(omens.current_offer.size() == 2 and omens.current_offer_block == 4 and not omens.showing, "the drawn Omens come back after a save (still face-down)")
	omens.load_save({"active": "harvest_moon", "active_block": 4, "last_offer": ["harvest_moon"]})
	_check(omens.active != null and omens.active.id == "bountiful_night" and Array(omens._last_offer_ids) == ["bountiful_night"],
		"an old save's Harvest Moon Omen loads as Bountiful Night")
	omens.active = null
	omens._last_offer_ids.clear()
	omens.current_offer = []
	omens._offer_waiting = false

func _test_twists(main: Node) -> void:
	var omens: OmenDirector = main.get_node("%OmenDirector")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var spawner = main.get_node("%EnemyContainer")
	var bug: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	var stag: EnemyData = load("res://resource/enemy/old_stag.tres")

	_activate(omens, "thick_blight", 3)
	_check(is_equal_approx(director.get_health_scale(bug, 11), pow(director.health_growth_per_drift, 10) * director.get_early_multiplier(11) * 1.3),
		"Thick Blight: +30% health in its block")
	_check(is_equal_approx(director.get_health_scale(bug, 16), pow(director.health_growth_per_drift, 15) * director.get_early_multiplier(16)),
		"Thick Blight: only its own block")
	_check(is_equal_approx(director.get_health_scale(stag, 15), director.act1_boss_health_multiplier), "bosses ignore Omens (act 1: no ramp either)")

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
	_check(is_equal_approx(swift.speed, bug.speed * 1.25), "Swift Stream: +25% speed")
	swift.free()
	_activate(omens, "stubborn_blight", 3)
	var stubborn: Node2D = spawner.spawn_enemy(bug, 1.0, director.get_spawn_modifiers(bug, 12))
	stubborn.apply_status(EnemyStatuses.DAMP)
	_check(is_equal_approx(stubborn.statuses.time_left(EnemyStatuses.DAMP), 4.0 * 0.33), "Stubborn Blight: statuses wear off three times as fast")
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
	_check(run_state.dew == dew + 60 and omens.active == null, "Crowded Paths pays 60 Dew at the rest after its block (act 1)")
	_check(omens.is_offering() or omens._offer_waiting, "a new Omen offer follows at the same rest")
	omens.current_offer = []
	omens._offer_waiting = false

	_activate(omens, "dry_spell", 3)
	dew = run_state.dew
	omens._on_rest_started(3, false, 50, true)
	_check(run_state.dew == dew + 25, "Dry Spell: rest bonus ×1.5 (+25 on a 50 bonus)")
	omens.current_offer = []
	omens._offer_waiting = false

	_activate(omens, "thick_blight", 3)
	omens._on_rest_started(3, false, 50, true)
	omens.current_offer = []
	omens._offer_waiting = false
	dreams.unlocked["firefly_jar"] = true
	_check(dreams.make_offer(15).size() == 5, "Thick Blight: the next Dream offers 5 cards")
	_check(dreams.make_offer(20).size() == 3, "…only the next one")
	dreams.cards_per_offer = 4  # Wider Dreams
	dreams.add_extra_cards(2)
	_check(dreams.make_offer(25).size() == 5, "…at most 5 cards, Wider Dreams included")
	dreams.cards_per_offer = 3

	_activate(omens, "restless_wind", 3)
	var max_leaves := run_state.max_leaves
	omens._on_rest_started(3, false, 50, true)
	_check(run_state.max_leaves == max_leaves + 2, "Restless Wind: +2 max leaves")
	omens.current_offer = []
	omens._offer_waiting = false

	_activate(omens, "hard_bark", 3)
	omens._on_rest_started(4, false, 50, true)
	_check(omens.active != null, "no reward at a rest for a different block")

	# Winning during an Omen's block still pays (Seeds count), scaled by the act
	_activate(omens, "swift_stream", 10)
	director.drifts_started = 50
	run_state.end_run(true)
	_check(run_state.omen_seeds == roundi(5 * OmenDirector.ACT_REWARD_SCALE[1]), "Swift Stream pays Seeds on a win, act 2 ×1.5 (%d)" % run_state.omen_seeds)

func _activate(omens: OmenDirector, id: String, block: int) -> void:
	for omen in omens.pool:
		if omen.id == id:
			omens.active = omen
			omens.active_block = block
			omens._leaves_lost_at_start = omens.run_state.leaves_lost  # A clean block so far
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
	_check(omens.current_offer.size() == 2 and omens.current_offer_block == 4 and not omens.showing, "the drawn Omens come back after a save (still face-down)")
	omens.load_save({"active": "harvest_moon", "active_block": 4, "last_offer": ["harvest_moon"]})
	_check(omens.active != null and omens.active.id == "bountiful_night" and Array(omens._last_offer_ids) == ["bountiful_night"],
		"an old save's Harvest Moon Omen loads as Bountiful Night")
	omens.active = null
	omens._last_offer_ids.clear()
	omens.current_offer = []
	omens._offer_waiting = false
	var previous: Array = []
	var no_repeat := true
	for i in 60:
		var offer := omens.make_offer(11)  # Drifts 51–55: every Omen can show
		if offer.any(func(o: OmenData) -> bool: return previous.has(o.id)):
			no_repeat = false
		previous = offer.map(func(o: OmenData) -> String: return o.id)
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
	_check(is_equal_approx(omens.get_warden_speed_multiplier(), 0.78), "Wilting: −22% attack speed")
	omens.active = by_id["frozen_ground"]
	director.resting = false
	_check(omens.blocks_building(), "Frozen Ground: no building during a drift")
	director.resting = true
	_check(not omens.blocks_building(), "…fine at a rest")
	omens.active = by_id["leaf_fall"]
	_check(omens.get_leak_multiplier() == 2.0, "Leaf Fall: leaks ×2")

	# Lean Season: no rest bonus, the next Dream (act 2+) includes a Legendary
	omens.active = by_id["lean_season"]
	run_state.dew = 200
	omens._pay_reward(100)
	_check(run_state.dew == 100, "Lean Season: the whole 100 rest bonus is lost (%d)" % run_state.dew)
	var offer := dreams.make_offer(51)
	_check(offer.any(func(c: UpgradeData) -> bool: return c.rarity == UpgradeData.Rarity.LEGENDARY), "…the next Dream includes a Legendary")

	# Double-edged and nightmare Omens through the spawn modifiers / schedule
	omens.active = by_id["heavy_rain"]
	omens.active_block = director.get_block(51)
	_check(omens.get_spawn_modifiers(51).get("always_status") == &"damp" and is_equal_approx(omens.get_multiplier(51, "health_multiplier"), 1.5),
		"Heavy Rain: always Soaked, +50% health")
	omens.active = by_id["sleepless"]
	_check(Array(omens.get_spawn_modifiers(51).get("status_immune", [])) == [&"drowsy", &"held"], "Sleepless: immune to Drowsy and Held")
	_check(omens.describe_reward(by_id["blood_moon"], 3) == "" and omens.describe_reward(by_id["bountiful_night"], 3) == "",
		"Blood Moon / Bountiful Night: no separate reward")
	var bug: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	omens.active = by_id["elder_night"]
	var schedule := []
	for i in 5:
		schedule.append([i * 1.0, bug, false])
	omens.shape_schedule(schedule, 51)
	_check(schedule.filter(func(a: Array) -> bool: return a[2]).size() == 2, "Elder Night: +2 elites per drift")
	var flyers := omens._block_flyers(omens.get_block_range(director.get_block(51)))
	if not flyers.is_empty():
		omens.active = by_id["hollow_wind"]
		schedule = [[0.0, bug, false], [1.0, bug, false]]
		omens.shape_schedule(schedule, 51)
		_check(schedule.all(func(a: Array) -> bool: return a[1].trait_kind == EnemyData.Trait.FLYING), "Hollow Wind: the first drifts are all flyers")
		schedule = [[0.0, bug, false]]
		omens.shape_schedule(schedule, 54)
		_check(schedule[0][1] == bug, "…only the first 3")

	# Shifting Ground: 5 trees on free cells away from the route, once; then +1 Seed per tree cleared
	omens.active = by_id["shifting_ground"]
	omens._sprouted_block = 0
	var route_before: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	var obstacles_before: int = map_generator.obstacles.size()
	omens._on_drift_started(51)
	omens._on_drift_started(52)
	_check(map_generator.obstacles.size() == obstacles_before + 5, "Shifting Ground: 5 trees sprout, once (%d)" % (map_generator.obstacles.size() - obstacles_before))
	_check(map_generator.get_path_from(map_generator.startPath) == route_before, "…never changing the route")
	omens._pay_reward(0)
	_check(omens.tree_seed_bonus == 2, "…reward: +2 Seeds per tree cleared")
	var tree_cell: Vector2 = map_generator.obstacles.keys().filter(func(c: Vector2) -> bool:
		return map_generator.obstacles[c] == OmenDirector.TREE)[0]
	var seeds := run_state.omen_seeds
	map_generator.clear_obstacle(tree_cell)
	_check(run_state.omen_seeds == seeds + 2, "…a cleared Withered Tree gives the extra Seeds")
	omens.tree_seed_bonus = 0
	omens.active = null
	director.drifts_started = 0

# Omen audit fixes (run_design.md): Hard Bark only before a block with a coated nightmare; Lean Season only
# while a Legendary can still be offered this run.
func _test_offer_conditions(main: Node) -> void:
	var omens: OmenDirector = main.get_node("%OmenDirector")
	var dreams: DreamState = main.get_node("%DreamState")
	var coated := -1
	var bare := -1
	for block in range(2, 20):
		if omens._block_has_coat(omens.get_block_range(block)):
			coated = block if coated < 0 else coated
		elif bare < 0:
			bare = block
	_check(coated > 0 and bare > 0, "blocks with and without a coated nightmare (%d, %d)" % [coated, bare])
	var offered := func(block: int, id: String) -> bool:
		for i in 80:
			omens._last_offer_ids.clear()
			if omens.make_offer(block).any(func(o: OmenData) -> bool: return o.id == id):
				return true
		return false
	_check(not offered.call(bare, "hard_bark"), "Hard Bark: never offered before a block with no coated nightmare (block %d)" % bare)
	_check(offered.call(coated, "hard_bark"), "…offered before one with a coat (block %d)" % coated)
	# Lean Season (act 2+): needs a Legendary left to give
	var legendaries: Array = dreams.pool.filter(func(c: UpgradeData) -> bool: return c.rarity == UpgradeData.Rarity.LEGENDARY)
	var grove_before := dreams.grove_cards.duplicate()
	for card in legendaries:
		if not card.in_start_pool and not dreams.grove_cards.has(card.id):
			dreams.grove_cards.append(card.id)
	_check(dreams.has_legendary_left(), "a Legendary is left to offer")
	_check(offered.call(11, "lean_season"), "Lean Season: offered while a Legendary can be offered")
	for card in legendaries:
		dreams._banished[card.id] = true
	_check(not dreams.has_legendary_left() and not offered.call(11, "lean_season"), "…never once no Legendary is left")
	for card in legendaries:
		dreams._banished.erase(card.id)
	dreams.grove_cards.assign(grove_before)
	omens._last_offer_ids.clear()

# Omens with teeth (run_design.md): the block decides the reward; the maze Omens; the data fixes.
func _test_teeth(main: Node) -> void:
	var omens: OmenDirector = main.get_node("%OmenDirector")
	var dreams: DreamState = main.get_node("%DreamState")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var run_state: RunState = main.get_node("%RunState")
	var map_generator = main.get_node("%MapGenerator")
	director.drifts_started = 15  # Act 1: rewards ×1
	omens.current_offer = []
	omens._offer_waiting = false
	var paid := []
	omens.omen_rewarded.connect(func(_o: OmenData, summary: String) -> void: paid.append(summary))
	# Crowded Paths (60 Dew): clean = all, 1 leaf lost = 75% (rounded down), 4+ = nothing
	_activate(omens, "crowded_paths", 3)
	_check(omens.get_reward_status() == "Reward · 100% · no leaf lost", "a clean block so far: the full reward (%s)" % omens.get_reward_status())
	run_state.leaves_lost += 1
	_check(omens.get_reward_status() == "Reward · 75% · 1 leaf lost", "…the tag follows the losses (%s)" % omens.get_reward_status())
	var dew := run_state.dew
	omens._pay_reward(0)
	_check(run_state.dew == dew + 45, "1 leaf lost: 75%% of 60 Dew (%d)" % (run_state.dew - dew))
	_check(not paid.is_empty() and paid[-1] == "+45 Dew (75%: 1 leaf lost)", "…and the rest says why (%s)" % [paid[-1] if not paid.is_empty() else ""])
	_activate(omens, "crowded_paths", 3)
	run_state.leaves_lost += 4
	dew = run_state.dew
	omens._pay_reward(0)
	_check(run_state.dew == dew and paid[-1] == "nothing (4 leaves lost)", "4 leaves lost: nothing (%s)" % paid[-1])
	# Leaf Fall (+3 max leaves): 1 lost → +2 (rounded down)
	_activate(omens, "leaf_fall", 3)
	run_state.leaves_lost += 1
	var max_leaves := run_state.max_leaves
	omens._pay_reward(0)
	_check(run_state.max_leaves == max_leaves + 2, "max leaves scale too, rounded down (+%d)" % (run_state.max_leaves - max_leaves))
	# Dream rewards: kept with ≤ 1 leaf lost, gone with 2
	_activate(omens, "hard_bark", 3)
	run_state.leaves_lost += 1
	var rare := dreams._rare_dreams_left
	omens._pay_reward(0)
	_check(dreams._rare_dreams_left == rare + 1, "Hard Bark: 1 leaf lost keeps the Rare+ card")
	_activate(omens, "hard_bark", 3)
	run_state.leaves_lost += 2
	_check(omens.get_reward_status().ends_with("Dream reward gone"), "…the tag says when it's gone (%s)" % omens.get_reward_status())
	rare = dreams._rare_dreams_left
	omens._pay_reward(0)
	_check(dreams._rare_dreams_left == rare, "…2 leaves lost: no Rare+ card")
	dreams._rare_dreams_left = 0
	# Double-edged Omens are their own reward: no tag line, never cut
	_activate(omens, "bountiful_night", 3)
	run_state.leaves_lost += 3
	_check(omens.get_reward_share() == 1.0 and omens.get_reward_status() == "", "double-edged Omens are unchanged")
	omens.active = null
	# The block's losses survive a save
	_activate(omens, "crowded_paths", 3)
	run_state.leaves_lost += 2
	var saved := omens.to_save()
	omens._leaves_lost_at_start = 0
	omens.load_save(JSON.parse_string(JSON.stringify(saved)))
	_check(omens.leaves_lost_in_block() == 2, "the leaves lost in the block come back after a save (%d)" % omens.leaves_lost_in_block())
	omens.active = null
	omens.current_offer = []
	omens._offer_waiting = false
	# Data fixes
	var by_id := {}
	for omen in omens.pool:
		by_id[omen.id] = omen
	_check(is_equal_approx(by_id["leaf_fall"].speed_multiplier, 1.2) and is_equal_approx(by_id["sleepless"].health_multiplier, 1.15)
		and by_id["lean_season"].rest_bonus_multiplier == 0.0 and is_equal_approx(by_id["dry_spell"].reward_rest_bonus_multiplier, 1.5),
		"Leaf Fall +20% speed, Sleepless +15% health, Lean Season no rest bonus, Dry Spell ×1.5")
	var route: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	var beside := omens.get_free_cells(true)
	var away := omens.get_free_cells()
	_check(beside.size() > away.size() and not beside.any(func(c: Vector2) -> bool: return route.has(c)),
		"Shifting Ground: trees may sprout beside the route, never on it (%d vs %d cells)" % [beside.size(), away.size()])
	for id in ["tramplers", "second_path", "burrowers"]:
		_check(by_id.has(id) and by_id[id].kind == OmenData.Kind.MAZE and by_id[id].flavor != "", "%s: a maze Omen with its flavour" % id)
	# Tramplers: one trample per drift
	_activate(omens, "tramplers", director.get_block(51))
	director.drifts_started = 51
	_check(omens.get_spawn_modifiers(51).get("tramples_thornwall", false), "Tramplers: nightmares get tramples_thornwall")
	_check(omens.claim_trample(51) and not omens.claim_trample(51) and omens.claim_trample(52), "…only the first trample each drift")
	_activate(omens, "burrowers", director.get_block(51))
	_check(omens.get_spawn_modifiers(51).get("burrow_tiles", 0) == 2, "Burrowers: nightmares get burrow_tiles 2")
	# Second Path: a Thornwall on the route lengthens it; at the block's start it crumbles (full refund) and locks
	var wall_cell := Vector2(-1, -1)
	for i in range(3, route.size() - 3):
		if map_generator.is_buildable(route[i]) and map_generator.can_block(route[i]) \
				and map_generator.get_path_if_blocked(route[i]).size() > route.size():
			wall_cell = route[i]
			break
	_check(wall_cell.x >= 0, "a route cell a Thornwall can lengthen the route from")
	if wall_cell.x >= 0:
		var wall: Tower = load("res://scenes/tower/tower.tscn").instantiate()
		wall.tower_data = load("res://resource/tower/thornwall.tres")
		wall.cell = wall_cell
		wall.position = wall.MAP_GRID.calculate_map_position(wall_cell)
		main.get_node("%TowerContainer").add_child(wall)
		wall.set_process(false)
		map_generator.block_cell(wall_cell)
		wall.invested_dew = 20
		_check(omens.second_path_target() == wall, "Second Path: the Thornwall that lengthens the route most")
		_activate(omens, "second_path", 4)
		omens._crumbled_block = 0
		dew = run_state.dew
		omens._on_drift_started(16)
		_check(not is_instance_valid(wall) or wall.is_queued_for_deletion() or wall.get_parent() == null, "…crumbles at the block's start")
		_check(run_state.dew == dew + 20 and omens.is_cell_locked(wall_cell), "…full refund (%d), its cell locked" % (run_state.dew - dew))
		_check(map_generator.get_path_from(map_generator.startPath).size() == route.size(), "…the route re-forms")
		omens._on_rest_started(4, false, 0, true)
		_check(not omens.is_cell_locked(wall_cell), "…the rest unlocks it")
		omens.current_offer = []
		omens._offer_waiting = false
	omens.active = null
	director.drifts_started = 0

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
