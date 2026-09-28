extends SceneTree

# Headless test for the meta (meta_design.md): the Grove tech tree (every grove_layout.json node has
# its UnlockData, costs, prerequisites, levels, start and milestone nodes, old ids migrate), buying,
# Memories, the perk loadout (only carried perks work), every perk at run start, Blight Levels,
# Family Blessings and Early Bloom, milestones at run end, and the Grove screen (tap, plant, canopy). Uses a temp profile and switches the demo setting off for the test only.
#   godot --headless --path . --script res://tests/test_meta.gd --fixed-fps 60

const PROFILE_PATH := "user://test_meta_heartwood.json"

var failures := 0
var _FakeEnemy := GDScript.new()  # A dispelled nightmare worth 1 Dew (Rich Dew)

func _initialize() -> void:
	_FakeEnemy.source_code = "extends Node2D
func get_dew_reward() -> int:
	return 1
"
	_FakeEnemy.reload()
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
	_check_layout(grove)
	# The Families limb (meta_design.md): 6 bought families + final forms + hidden branches ≈ 1,390
	# Seeds, plus 9 Ascension nodes at 120 = 1,080.
	var limb := 0
	for unlock in grove:
		if unlock.root == UnlockData.Root.WARDENS and not unlock.costs.is_empty():
			limb += unlock.costs[0]
	_check(limb == 1390 + 1080, "the Families limb costs 2,470 Seeds (%d)" % limb)
	_check(_unlock(grove, "bellflower").requires_any == ["pebbling", "rootling"], "Bellflower needs Pebbling or Rootling")
	for family: String in ["sporeling", "dewdrop", "pebbling", "rootling", "bellflower", "acorn", "nestling", "whirligig"]:
		var hidden := family + "_hidden"
		var node := _unlock(grove, hidden)
		_check(node != null and node.requires_all.size() == 1 and node.requires_all[0] == family + "_final",
			"hidden branch %s needs its family's final forms" % hidden)
	_check(_unlock(grove, "nestling").requires_any.has("bellflower") and _unlock(grove, "nestling").requires_any_count == 2,
		"Nestling needs 2 of Pebbling / Rootling / Bellflower / Acorn")
	var acorn := _unlock(grove, "acorn")
	_check(HeartwoodMemory.buy_problem(HeartwoodMemory.load_data(), acorn) != "", "Acorn needs Pebbling or Rootling first")
	_check(HeartwoodMemory.buy(_unlock(grove, "pebbling")), "buy the Pebbling line")
	_check(HeartwoodMemory.buy(acorn), "then Acorn")
	var nestling := _unlock(grove, "nestling")
	_check(HeartwoodMemory.buy(nestling), "Nestling: any 2 of Pebbling / Rootling / Acorn")
	var stores := _unlock(grove, "morning_stores")
	for i in 3:
		_check(HeartwoodMemory.buy(stores), "Morning Stores level %d" % (i + 1))
	_check(HeartwoodMemory.buy_problem(HeartwoodMemory.load_data(), stores) == "Grown", "Morning Stores maxes at 3")
	memory = HeartwoodMemory.load_data()
	_check(int(memory.seeds) == 600 - 50 - 70 - 120 - 20 - 40 - 60, "Seeds spent (%d left)" % int(memory.seeds))
	_check(HeartwoodMemory.memories_unlocked(memory) == 1 + 6 / 3, "Memories: 1 + one per 3 unlocks")
	_check(HeartwoodMemory.buy(_unlock(grove, "early_bloom")), "buy Early Bloom")
	_check(HeartwoodMemory.buy(_unlock(grove, "early_light")), "buy Early Light")
	_check(HeartwoodMemory.buy_problem(HeartwoodMemory.load_data(), _unlock(grove, "slot_3")) != "", "loadout slot 3 needs slot 2")
	_check(HeartwoodMemory.buy(_unlock(grove, "slot_2")), "buy loadout slot 2")
	var wanted: Array[String] = ["morning_stores", "early_light", "early_bloom"]
	HeartwoodMemory.save_loadout(wanted)
	_check(HeartwoodMemory.get_loadout(HeartwoodMemory.load_data()) == ["morning_stores", "early_light"],
		"the loadout holds one perk per slot (%s)" % [HeartwoodMemory.get_loadout(HeartwoodMemory.load_data())])

	# --- Perks and Blight Level 5 at run start ---
	MetaRun.blight_level = 5
	var main := await _new_run()
	var run_state: RunState = main.get_node("%RunState")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var family = main.get_node("%FamilyPickScreen")
	var dreams: DreamState = main.get_node("%DreamState")
	_check(run_state.dew == run_state.starting_dew + 30 - 20, "starting Dew: base + Morning Stores 30 − Blight 20 (%d)" % run_state.dew)
	var family_ids: Array = family.families.map(func(d: TowerData) -> String: return d.get_id())
	_check(family_ids.has("pebbling") and family_ids.has("acorn") and family_ids.has("nestling"), "Grove families join the picks (%s)" % [family_ids])
	_check(dreams.grove_cards.has("dream_wrens_nest") and not dreams.grove_cards.has("dream_magpies_hoard"),
		"family nodes bring their branches, not their final forms")
	for line: String in ["sporeling", "firefly_jar", "dewdrop", "pebbling", "rootling", "bellflower", "acorn", "nestling", "whirligig"]:
		var ascension := _unlock(grove, line + "_ascension")
		_check(ascension != null and ascension.costs == [120] and ascension.requires_all == [line + ("_final" if line == "firefly_jar" else "_hidden")] and ascension.dream_cards.size() == 1,
			"%s Ascension: 120 Seeds, needs the hidden branch (Firefly Jar: final forms, Sunpetal is milestone-only), opens the Ascended Warden" % line)
	_check(_unlock(grove, "pebbling_hidden").dream_cards.has("dream_cairn") and _unlock(grove, "whirligig_hidden").dream_cards.has("dream_autumn_gale"),
		"hidden nodes open their hidden Wardens")
	_check(is_equal_approx(director.blight_health_multiplier, 1.1) and is_equal_approx(director.blight_boss_health_multiplier, 1.25)
		and director.blight_elites_per_drift == 1 and is_equal_approx(director.blight_rest_bonus_multiplier, 0.75),
		"Blight 1–5 modifiers applied")
	_check(is_equal_approx(run_state.seed_bonus, 0.5), "Blight 5: +50% Seeds")
	_check(dreams.dreamlight == 1, "Early Light: the run starts with 1 Dreamlight (%d)" % dreams.dreamlight)
	_check(not family.offer_all_first, "Early Bloom is owned but not carried: it does nothing")
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

	# --- Milestone nodes: Sunpetal grows with 500 Shades; One Line's Seeds come back when its
	# milestone grows it after it was bought ---
	memory = HeartwoodMemory.load_data()
	var sunpetal := _unlock(grove, "firefly_jar_hidden")
	_check(sunpetal.is_free() and HeartwoodMemory.buy_problem(memory, sunpetal) == "Grows by itself", "Sunpetal can't be bought")
	memory.milestones.shades_500 = true
	_check(HeartwoodMemory.node_level(memory, sunpetal) == 1, "500 Shades grows Sunpetal's node")
	memory.seeds = 80
	HeartwoodMemory.save_data(memory)
	_check(HeartwoodMemory.buy(_unlock(grove, "one_line")), "One Line can also be bought")
	memory = HeartwoodMemory.load_data()
	memory.milestones.one_line_win = true
	HeartwoodMemory.grow_milestone_nodes(memory, "one_line_win")
	_check(int(memory.seeds) == 80, "One Line bought, then its milestone: the 80 Seeds come back (%d)" % int(memory.seeds))
	HeartwoodMemory.save_data(memory)
	_check(_unlock(grove, "sporeling").start and HeartwoodMemory.node_level(memory, _unlock(grove, "sporeling")) == 1,
		"Sporeling is grown from the start")
	var wider := _unlock(grove, "wider_dreams")
	memory.seeds = 1000
	memory.unlocks.second_thoughts = 1
	_check(HeartwoodMemory.buy_problem(memory, wider) == "Needs another unlock first", "Wider Dreams needs Second Thoughts II")
	memory.unlocks.second_thoughts = 2
	_check(HeartwoodMemory.buy_problem(memory, wider) == "", "…and opens with it")

	# --- Every perk, carried: 5 slots, two loadouts ---
	memory = HeartwoodMemory.load_data()
	for id in ["slot_2", "slot_3", "slot_4", "slot_5", "rich_dew", "rested_roots", "sprout_bed", "clear_sight",
			"kindling", "omen_reader", "first_care", "deep_taproot", "second_thoughts", "wider_dreams", "let_go"]:
		memory.unlocks[id] = _unlock(grove, id).get_levels()
	memory.loadout = ["rich_dew", "rested_roots", "sprout_bed", "clear_sight", "kindling"]
	HeartwoodMemory.save_data(memory)
	_check(HeartwoodMemory.loadout_slots(memory) == 5, "slots 2–5 make 5 loadout slots")
	main = await _new_run()
	run_state = main.get_node("%RunState")
	director = main.get_node("%DriftDirector")
	dreams = main.get_node("%DreamState")
	_check(is_equal_approx(run_state.dew_gain_bonus, 0.15), "Rich Dew III: +15%% Dew (%s)" % run_state.dew_gain_bonus)
	_check(is_equal_approx(director.rest_bonus_perk_multiplier, 1.2), "Rested Roots II: rest bonus ×1.2")
	_check(run_state.sprout_charges == 2, "Sprout Bed: 2 free Sprouts (%d)" % run_state.sprout_charges)
	_check(dreams.card_stacks("cleared_ground") >= 1 and dreams.can_clear(), "Clear Sight: Cleared Ground from the start")
	var taken := 0
	for id in dreams.stacks:
		taken += dreams.stacks[id]
	_check(taken == 2, "Kindling: one random Common besides Cleared Ground (%s)" % [dreams.stacks])
	_check(run_state.free_nurtures == 0 and dreams.rerolls_left == 0, "perks not carried do nothing")
	_check(not dreams.allow_bittersweet, "no Bittersweet Dreams node: no bittersweet cards")
	var dew_before := run_state.dew
	for i in 20:  # 20 dispels of 1 Dew at +15%: 3 whole Dew carried over
		var enemy := Node2D.new()
		enemy.set_script(_FakeEnemy)
		main.add_child(enemy)
		run_state._on_enemy_cleansed(enemy)
		enemy.queue_free()
	_check(run_state.dew - dew_before == 23, "Rich Dew carries fractions: 20 Dew becomes 23 (%d)" % (run_state.dew - dew_before))
	main.queue_free()
	await process_frame
	memory = HeartwoodMemory.load_data()
	memory.loadout = ["omen_reader", "first_care", "deep_taproot", "second_thoughts", "wider_dreams"]
	memory.unlocks.bittersweet_dreams = 1
	HeartwoodMemory.save_data(memory)
	main = await _new_run()
	run_state = main.get_node("%RunState")
	dreams = main.get_node("%DreamState")
	var omens: OmenDirector = main.get_node("%OmenDirector")
	_check(omens.omens_per_offer == 3, "Omen Reader: 3 Omens (%d)" % omens.omens_per_offer)
	_check(run_state.free_nurtures == 3, "First Care: 3 free Nurture ranks (%d)" % run_state.free_nurtures)
	_check(run_state.max_leaves == run_state.starting_leaves + 3, "Deep Taproot III: +3 max leaves")
	_check(dreams.rerolls_left == 2 and dreams.cards_per_offer == 4, "Second Thoughts II and Wider Dreams")
	_check(dreams.banishes_left == 0, "Let Go owned but not carried")
	_check(dreams.allow_bittersweet and dreams.grove_cards.has("deep_sleep"), "the Bittersweet Dreams node lets bittersweet cards be offered")
	main.queue_free()
	await process_frame

	# --- Old profiles: version 1 Grove ids move to the layout ids ---
	var old := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	old.store_string(JSON.stringify({"version": 1, "seeds": 5, "unlocks": {"pebbling_line": 1, "cairn": 1, "sporeling_finals": 1, "morning_stores": 2}}))
	old.close()
	memory = HeartwoodMemory.load_data()
	var migrated := {}
	for id in memory.unlocks:
		migrated[id] = int(memory.unlocks[id])
	_check(migrated == {"pebbling": 1, "pebbling_hidden": 1, "sporeling_final": 1, "morning_stores": 2}, "v1 ids migrate (%s)" % [migrated])
	_check(memory.loadout == [] and int(memory.seeds) == 5, "a migrated profile keeps its Seeds, empty loadout")

	# --- The Grove screen: the tree, tapping a bud, planting, the canopy ---
	memory = HeartwoodMemory.defaults()
	memory.seeds = 100
	memory.runs_played = 1
	HeartwoodMemory.save_data(memory)
	var grove_screen: Control = load("res://scenes/grove.tscn").instantiate()
	root.add_child(grove_screen)
	await process_frame
	await process_frame
	var view: GroveTreeView = grove_screen.tree_view
	_check(view.get_canopy_stage() == 0, "a new Grove shows the first canopy stage")
	var stores_node := _layout_node("morning_stores")
	view.tap(GroveTreeView.vec(stores_node.pos))
	_check(grove_screen.selected != null and grove_screen.selected.id == "morning_stores", "tapping a bud selects its node")
	_check(view.state_of(_unlock(grove, "morning_stores")) == GroveTreeView.State.AFFORDABLE, "Morning Stores glows (affordable)")
	_check(view.state_of(_unlock(grove, "rich_dew")) == GroveTreeView.State.LOCKED, "Rich Dew stays a bare twig until its parent grows")
	grove_screen._plant_selected()
	memory = HeartwoodMemory.load_data()
	_check(int(memory.seeds) == 80 and HeartwoodMemory.unlock_level(memory, "morning_stores") == 1, "Plant buys the node (%d Seeds left)" % int(memory.seeds))
	_check(view.is_planting(), "planting plays the branch growing")
	_check(HeartwoodMemory.get_loadout(memory) == ["morning_stores"], "a new perk goes into a free loadout slot")
	_check(view.state_of(_unlock(grove, "rich_dew")) == GroveTreeView.State.AFFORDABLE, "…and Rich Dew can now be planted")
	view.tap(Vector2(640, 20))
	_check(grove_screen.selected == null, "tapping the sky closes the card")
	_check(GroveTreeView.canopy_stage_for(0.3) == 1 and GroveTreeView.canopy_stage_for(1.0) == 3, "canopy stages by the share grown")
	grove_screen.queue_free()
	await process_frame

	# --- Developer "Unlock all families": a fresh profile, even in the demo, gets every family and
	# their Grove Dream cards, without touching the profile, and banks nothing ---
	HeartwoodMemory.save_data(HeartwoodMemory.defaults())
	ProjectSettings.set_setting("game/demo", true)
	MetaRun.force_all_families = true
	main = await _new_run()
	family = main.get_node("%FamilyPickScreen")
	dreams = main.get_node("%DreamState")
	family_ids = family.families.map(func(d: TowerData) -> String: return d.get_id())
	for id in ["sporeling", "firefly_jar", "dewdrop", "pebbling", "rootling", "acorn", "nestling", "whirligig"]:
		_check(family_ids.has(id), "Unlock all families: %s joins the picks (%s)" % [id, family_ids])
	_check(dreams.grove_cards.has("dream_gust") and dreams.grove_cards.has("dream_wrens_nest"), "their Grove Dream cards join the pool")
	_check(not (main.get_node("%MetaRun") as MetaRun).records, "a developer run records nothing")
	var results := main.get_node("%ResultsScreen") as ResultsScreen
	results.bank_in_tests = true  # Would bank, but it's a developer run
	main.get_node("%RunState").end_run(true)
	await process_frame
	memory = HeartwoodMemory.load_data()
	_check(results.not_banked and int(memory.seeds) == 0 and int(memory.runs_played) == 0 and memory.unlocks.is_empty(),
		"the profile is untouched: no Seeds, runs or unlocks")
	main.queue_free()
	await process_frame
	MetaRun.force_all_families = false
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

func _layout_node(id: String) -> Dictionary:
	for node in GroveTreeView.load_layout().nodes:
		if node.id == id:
			return node
	_check(false, "layout node %s exists" % id)
	return {}

# Every grove_layout.json node has its UnlockData (same limb, levels, Legendary, start) and branch
# art, and every UnlockData is on the tree.
func _check_layout(grove: Array[UnlockData]) -> void:
	var nodes: Array = GroveTreeView.load_layout().nodes
	_check(nodes.size() == 82 and grove.size() == 82, "82 Grove nodes (layout %d, data %d)" % [nodes.size(), grove.size()])
	for node in nodes:
		var unlock := HeartwoodMemory.get_unlock(node.id)
		if unlock == null:
			_check(false, "layout node %s has an UnlockData" % node.id)
			continue
		_check(unlock.get_section() == node.section, "%s is on the %s limb" % [node.id, node.section])
		_check(maxi(unlock.get_levels(), 1) == int(node.levels), "%s has %d levels" % [node.id, int(node.levels)])
		_check(unlock.legendary == bool(node.legendary) and unlock.start == bool(node.start), "%s: Legendary / start match" % node.id)
		_check(ResourceLoader.exists("res://assets/meta/grove/branches/%s.png" % node.id), "%s has branch art" % node.id)
		if node.parent != null and node.id != "firefly_jar_ascension":  # Drawn from Sunpetal, needs final forms
			_check(unlock.requires_all.any(func(r: String) -> bool: return r.split(":")[0] == node.parent) or unlock.milestone != "" and unlock.is_free(),
				"%s needs its parent %s" % [node.id, node.parent])
	for unlock in grove:
		_check(nodes.any(func(n) -> bool: return n.id == unlock.id), "%s is on the tree" % unlock.id)
