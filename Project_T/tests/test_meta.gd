extends SceneTree

# Headless test for the meta (meta_design.md): buying Grove unlocks (costs, prerequisites, levels),
# Memories, perks applied at run start, Blight Levels, Family Blessings and Early Bloom, milestones
# at run end. Uses a temp profile and switches the demo setting off for the test only.
#   godot --headless --path . --script res://tests/test_meta.gd --fixed-fps 60

const PROFILE_PATH := "user://test_meta_heartwood.json"

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = PROFILE_PATH
	_delete(PROFILE_PATH)
	var was_demo: bool = ProjectSettings.get_setting("game/demo", false)
	ProjectSettings.set_setting("game/demo", false)

	# --- Buying ---
	var memory := HeartwoodMemory.defaults()
	memory.seeds = 600
	memory.runs_played = 1
	HeartwoodMemory.save_data(memory)
	var grove := HeartwoodMemory.load_grove()
	_check(grove.size() >= 17, "the Grove has its unlocks (%d)" % grove.size())
	var acorn := _unlock(grove, "acorn_line")
	_check(HeartwoodMemory.buy_problem(HeartwoodMemory.load_data(), acorn) != "", "Acorn needs Pebbling or Rootling first")
	_check(HeartwoodMemory.buy(_unlock(grove, "pebbling_line")), "buy the Pebbling line")
	_check(HeartwoodMemory.buy(acorn), "then Acorn")
	var nestling := _unlock(grove, "nestling_family")
	_check(HeartwoodMemory.buy(nestling), "Nestling: any 2 of Pebbling / Rootling / Acorn")
	var stores := _unlock(grove, "morning_stores")
	for i in 3:
		_check(HeartwoodMemory.buy(stores), "Morning Stores level %d" % (i + 1))
	_check(HeartwoodMemory.buy_problem(HeartwoodMemory.load_data(), stores) == "Grown", "Morning Stores maxes at 3")
	memory = HeartwoodMemory.load_data()
	_check(int(memory.seeds) == 600 - 50 - 70 - 120 - 20 - 40 - 60, "Seeds spent (%d left)" % int(memory.seeds))
	_check(HeartwoodMemory.memories_unlocked(memory) == 1 + 6 / 3, "Memories: 1 + one per 3 unlocks")
	_check(HeartwoodMemory.buy(_unlock(grove, "early_bloom")), "buy Early Bloom")

	# --- Perks and Blight Level 5 at run start ---
	MetaRun.blight_level = 5
	var main := await _new_run()
	var run_state: RunState = main.get_node("%RunState")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var family = main.get_node("%FamilyPickScreen")
	var dreams: DreamState = main.get_node("%DreamState")
	_check(run_state.dew == 60 + 30 - 20, "starting Dew: 60 + Morning Stores 30 − Blight 20 (%d)" % run_state.dew)
	var family_ids: Array = family.families.map(func(d: TowerData) -> String: return d.get_id())
	_check(family_ids.has("pebbling") and family_ids.has("acorn") and family_ids.has("nestling"), "Grove families join the picks (%s)" % [family_ids])
	_check(is_equal_approx(director.blight_health_multiplier, 1.1) and is_equal_approx(director.blight_boss_health_multiplier, 1.25)
		and director.blight_elites_per_drift == 1 and is_equal_approx(director.blight_rest_bonus_multiplier, 0.75),
		"Blight 1–5 modifiers applied")
	_check(is_equal_approx(run_state.seed_bonus, 0.5), "Blight 5: +50% Seeds")
	director.start_next_drift()
	await process_frame
	var elites: int = main.get_node("%EnemyContainer").get_enemies().filter(func(e: Node2D) -> bool: return e.elite).size() \
		+ director._arriving.get(1, {"schedule": []}).schedule.filter(func(a: Array) -> bool: return a.size() > 2 and a[2]).size()
	_check(elites == 1, "one Deeply Blighted nightmare in the drift (%d)" % elites)

	# --- First pick: 3 random from every unlocked family, never the previous offer again ---
	family.offer_all_first = false
	var drawn := {}
	for i in 30:
		var previous: Array = family.previous_first_offer.duplicate()
		family.show_pick(&"first")
		_check(family.offer.size() == 3 and family._ids(family.offer) != previous,
			"the first pick draws 3 and doesn't repeat the last offer (%s after %s)" % [family._ids(family.offer), previous])
		for data in family.offer:
			drawn[data.get_id()] = true
	_check(drawn.size() > 3 and drawn.has("pebbling"), "first picks draw from the Grove families too (%s)" % [drawn.keys()])
	_check(not HeartwoodMemory.load_data().has("last_first_pick"), "tests never write the last offer to the profile")
	family.offer_all_first = true

	# --- Early Bloom and Family Blessings ---
	family.show_pick(&"first")
	_check(family.offer.size() == family.families.size(), "Early Bloom: the first pick offers every family (%d)" % family.offer.size())
	for data in family.families:
		dreams.unlocked[data.get_id()] = true
	family.show_pick(&"boss")
	_check(family.offer.size() == 3 and family.offer.all(func(o) -> bool: return o is UpgradeData), "no new families left: 3 Blessings")
	var blessing: UpgradeData = family.offer[0]
	family.choose(blessing)
	_check(dreams.card_stacks(blessing.id) == 1, "a Blessing is taken like a card")
	var seeds := run_state.get_seed_breakdown(10, 0, false)
	_check(seeds.any(func(l: Array) -> bool: return l[0].begins_with("Seed bonus")), "the Seed bonus shows in the breakdown")

	# --- Milestones at run end ---
	var meta: MetaRun = main.get_node("%MetaRun")
	meta.records = true
	(main.get_node("%ResultsScreen") as ResultsScreen).bank_in_tests = true  # Counts the win (temp profile)
	director.bosses_cleansed = 1
	run_state.longest_path = 320
	run_state.end_run(true)
	await process_frame
	memory = HeartwoodMemory.load_data()
	for id in ["first_boss", "first_win", "flawless_win", "path_300", "blight_5"]:
		_check(memory.milestones.has(id), "milestone %s" % id)
	_check(int(memory.highest_blight_won) == 5 and HeartwoodMemory.max_blight_level(memory) == 6, "Blight 5 won: level 6 opens")
	_check(memory.cosmetics.has("golden_leaf"), "a flawless win grows the Golden Leaf")
	_check(HeartwoodMemory.memories_unlocked(memory) > 1 + 7 / 3, "milestones reveal Memories too")

	main.queue_free()
	await process_frame
	MetaRun.blight_level = 0
	ProjectSettings.set_setting("game/demo", was_demo)
	_delete(PROFILE_PATH)
	print("meta test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _new_run() -> Node:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	return main

func _unlock(grove: Array[UnlockData], id: String) -> UnlockData:
	for unlock in grove:
		if unlock.id == id:
			return unlock
	_check(false, "unlock %s exists" % id)
	return null

func _delete(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
