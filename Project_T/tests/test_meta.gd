extends SceneTree

# Headless test for the meta (meta_design.md): the Grove tech tree (every grove_layout.json node has
# its UnlockData, costs, prerequisites, levels, start and milestone nodes, old ids migrate), buying,
# Memories, the perk loadout (only carried perks work), every perk at run start, Blight Levels,
# Family Blessings and Early Bloom, milestones at run end, and the Grove screen (tap, plant, canopy). Uses a temp profile and switches the demo setting off for the test only.
#   godot --headless --path . --script res://tests/test_meta.gd --fixed-fps 60

# Per process: every checkout (worktrees, the main folder) shares one user://, and chats run tests at once.
var PROFILE_PATH := "user://test_meta_heartwood_%d.json" % OS.get_process_id()
var SIM_PATH := "user://test_meta_sim_%d.json" % OS.get_process_id()

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
	GrovePresets.file_path = SIM_PATH
	var was_demo: bool = ProjectSettings.get_setting("game/demo", false)
	ProjectSettings.set_setting("game/demo", false)

	# --- Buying ---
	var memory := HeartwoodMemory.defaults()
	memory.seeds = 700
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
	_check(limb == 1390 + 1080 - 470, "the Families limb costs 2,000 Seeds (final-forms nodes removed) (%d)" % limb)
	for family: String in ["sporeling", "firefly_jar", "dewdrop", "pebbling", "rootling", "bellflower", "acorn", "nestling", "whirligig"]:
		_check(HeartwoodMemory.get_unlock(family + "_final") == null, "no final-forms node for %s (finals come with the family)" % family)
	_check(_unlock(grove, "bellflower").requires_any == ["pebbling", "rootling"], "Bellflower needs Pebbling or Rootling")
	for family: String in ["sporeling", "dewdrop", "pebbling", "rootling", "bellflower", "acorn", "nestling", "whirligig"]:
		var hidden := family + "_hidden"
		var node := _unlock(grove, hidden)
		var start := family in ["sporeling", "dewdrop"]
		_check(node != null and node.requires_all == ([] if start else [family]),
			"hidden branch %s needs only its family" % hidden)
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
	_check(int(memory.seeds) == 700 - 50 - 70 - 120 - 20 - 40 - 60, "Seeds spent (%d left)" % int(memory.seeds))
	_check(HeartwoodMemory.memories_unlocked(memory) == 1 + 6 / 3, "Memories: 1 + one per 3 unlocks")
	_check(HeartwoodMemory.buy_problem(HeartwoodMemory.load_data(), _unlock(grove, "early_bloom")) != "", "Early Bloom grows off Second Thoughts")
	_check(HeartwoodMemory.buy(_unlock(grove, "second_thoughts")), "buy Second Thoughts")
	_check(HeartwoodMemory.buy(_unlock(grove, "early_bloom")), "buy Early Bloom")
	_check(HeartwoodMemory.buy(_unlock(grove, "early_light")), "buy Early Light")
	_check(HeartwoodMemory.loadout_slots(HeartwoodMemory.load_data()) == 3, "3 loadout slots are open from the start")
	_check(_unlock(grove, "slot_4").requires_all.is_empty() and _unlock(grove, "slot_5").requires_all == ["slot_4"],
		"slot 4 grows from the limb, slot 5 needs slot 4")
	var wanted: Array[String] = ["morning_stores", "early_light", "seed_pouch", "morning_stores"]
	HeartwoodMemory.save_loadout(wanted)
	_check(HeartwoodMemory.get_loadout(HeartwoodMemory.load_data()) == ["morning_stores", "early_light"],
		"the loadout keeps owned perks once each (%s)" % [HeartwoodMemory.get_loadout(HeartwoodMemory.load_data())])

	# --- Perks and Blight Level 5 at run start ---
	MetaRun.blight_level = 5
	var main := await _new_run()
	var run_state: RunState = main.get_node("%RunState")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var family = main.get_node("%FamilyPickScreen")
	var dreams: DreamState = main.get_node("%DreamState")
	_check(run_state.dew == run_state.starting_dew + 30, "starting Dew: base + Morning Stores 30, Blight takes none (%d)" % run_state.dew)
	_check(dreams_first_pick(main) == 0, "Blight 2+: the first family pick gives no Dreamlight")
	var family_ids: Array = family.families.map(func(d: TowerData) -> String: return d.get_id())
	_check(family_ids.has("pebbling") and family_ids.has("acorn") and family_ids.has("nestling"), "Grove families join the picks (%s)" % [family_ids])
	_check(dreams.grove_cards.has("dream_wrens_nest") and not dreams.grove_cards.has("dream_magpies_hoard"),
		"family nodes bring their branches, not their final forms")
	for line: String in ["sporeling", "firefly_jar", "dewdrop", "pebbling", "rootling", "bellflower", "acorn", "nestling", "whirligig"]:
		var ascension := _unlock(grove, line + "_ascension")
		_check(ascension != null and ascension.costs == [120] and ascension.requires_all == ([] if line == "firefly_jar" else [line + "_hidden"]) and ascension.dream_cards.size() == 1,
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
	# Family Blessings are Rare Dream cards now (meta_design.md "Replaced 2026-09-30"): one per family,
	# offered like any card once you own that family, from act 2 (their old boss-pick timing; design 2026-09-30).
	var blessing: UpgradeData = dreams.pool.filter(func(c: UpgradeData) -> bool: return c.id == "blessing_sporeling").front()
	_check(blessing != null and blessing.in_start_pool and blessing.requires == ["sporeling"] and blessing.rarity == UpgradeData.Rarity.RARE
		and blessing.max_stacks == 1 and blessing.min_act == 2, "a Family Blessing is a Rare Dream card that needs its family, from act 2")
	dreams.take(blessing)
	_check(dreams.card_stacks(blessing.id) == 1, "a Blessing is taken like a card")
	var blessed := MetaRun.load_blessings().map(func(b: UpgradeData) -> String: return b.requires[0] if not b.requires.is_empty() else "")
	blessed.sort()
	_check(blessed == ["acorn", "bellflower", "dewdrop", "firefly_jar", "nestling", "pebbling", "rootling", "sporeling", "whirligig"],
		"one Blessing per family, all 9 (%s)" % [blessed])
	var seeds := run_state.get_seed_breakdown(10, 0, false)
	_check(seeds.any(func(l: Array) -> bool: return l[0].begins_with("Seed bonus")), "the Seed bonus shows in the breakdown")

	# --- Milestones at run end ---
	var meta: MetaRun = main.get_node("%MetaRun")
	meta.records = true
	(main.get_node("%ResultsScreen") as ResultsScreen).bank_in_tests = true  # Counts the win (temp profile)
	var combos_found := HeartwoodMemory.load_data()  # The Codex sets this mid-run
	combos_found.milestones.all_combos = true
	combos_found.milestones.all_dreams = true  # The Dreams Codex sets this mid-run too
	HeartwoodMemory.save_data(combos_found)
	director.bosses_cleansed = 1
	run_state.longest_path = 320
	run_state.end_run(true)
	await process_frame
	memory = HeartwoodMemory.load_data()
	for id in ["first_boss", "first_win", "flawless_win", "path_300", "blight_5"]:
		_check(memory.milestones.has(id), "milestone %s" % id)
	_check(int(memory.highest_blight_won) == 5 and HeartwoodMemory.max_blight_level(memory) == 6, "Blight 5 won: level 6 opens")
	_check(memory.cosmetics.has("golden_leaf"), "a flawless win grows the Golden Leaf")
	_check(memory.cosmetics.has("gilded_pages"), "Discover every combo: the gilded Codex pages")
	_check(memory.cosmetics.has("starlit_backs"), "Dream of everything: the starlit card backs")
	memory.milestones.erase(MetaRun.ALL_DREAMS)  # Its reroll would change the perk checks below
	HeartwoodMemory.save_data(memory)
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
	memory.unlocks.omen_reader = 1
	memory.unlocks.second_thoughts = 1
	_check(HeartwoodMemory.buy_problem(memory, wider) == "Needs another unlock first", "Wider Dreams needs Second Thoughts II")
	memory.unlocks.second_thoughts = 2
	memory.unlocks.erase("omen_reader")
	_check(HeartwoodMemory.buy_problem(memory, wider) == "Needs another unlock first", "…and Omen Reader")
	memory.unlocks.omen_reader = 1
	_check(HeartwoodMemory.buy_problem(memory, wider) == "", "…and opens with both")

	# The Perks limb's three paths (meta_design.md "Section 1: Perks"): Economy, Survival, Choice.
	var paths := {"seed_pouch": "rested_roots", "first_care": "deep_taproot", "clear_sight": "first_care",
		"omen_reader": "let_go", "early_bloom": "second_thoughts", "kindling": "early_light"}
	for id in paths:
		_check(_unlock(grove, id).requires_all.has(paths[id]), "%s grows off %s" % [id, paths[id]])
	var path_data := HeartwoodMemory.defaults()
	path_data.seeds = 1000
	var slot4 := _unlock(grove, "slot_4")
	var slot5 := _unlock(grove, "slot_5")
	_check(HeartwoodMemory.buy_problem(path_data, slot4) != "", "slot 4 needs a second perk")
	path_data.unlocks.first_care = 1
	_check(HeartwoodMemory.buy_problem(path_data, slot4) == "", "…any path's (First Care)")
	path_data.unlocks.slot_4 = 1
	path_data.unlocks.clear_sight = 1
	_check(HeartwoodMemory.buy_problem(path_data, slot5) != "", "slot 5 needs the third perk of 2 paths")
	path_data.unlocks.omen_reader = 1
	_check(HeartwoodMemory.buy_problem(path_data, slot5) == "", "…Clear Sight and Omen Reader")
	# Old profiles keep what they own, even out of the new order (no refunds, no re-locking).
	var legacy := HeartwoodMemory.defaults()
	legacy.unlocks = {"seed_pouch": 1, "kindling": 1}
	legacy.loadout = ["seed_pouch", "kindling"]
	_check(HeartwoodMemory.node_level(legacy, _unlock(grove, "seed_pouch")) == 1 and HeartwoodMemory.get_loadout(legacy) == ["seed_pouch", "kindling"],
		"an old profile keeps and carries Seed Pouch and Kindling without their new parents")

	# --- Every perk, carried: 5 slots, two loadouts ---
	memory = HeartwoodMemory.load_data()
	for id in ["slot_4", "slot_5", "rich_dew", "rested_roots", "sprout_bed", "clear_sight",
			"kindling", "omen_reader", "first_care", "deep_taproot", "second_thoughts", "wider_dreams", "let_go"]:
		memory.unlocks[id] = _unlock(grove, id).get_levels()
	memory.loadout = ["rich_dew", "rested_roots", "sprout_bed", "clear_sight", "kindling"]
	HeartwoodMemory.save_data(memory)
	_check(HeartwoodMemory.loadout_slots(memory) == 5, "3 open + slots 4–5 make 5 loadout slots")
	main = await _new_run()
	run_state = main.get_node("%RunState")
	director = main.get_node("%DriftDirector")
	dreams = main.get_node("%DreamState")
	_check(is_equal_approx(run_state.dew_gain_bonus, 0.15), "Rich Dew III: +15%% Dew (%s)" % run_state.dew_gain_bonus)
	_check(dreams_first_pick(main) == DreamState.FIRST_PICK_DREAMLIGHT, "no Blight: the first family pick gives its Dreamlight")
	_check(is_equal_approx(director.rest_bonus_perk_multiplier, 1.2), "Rested Roots II: rest bonus ×1.2")
	_check(run_state.sprout_charges == 2, "Sprout Bed: 2 free Sprouts (%d)" % run_state.sprout_charges)
	_check(dreams.card_stacks("cleared_ground") >= 1 and dreams.can_clear(), "Clear Sight: clearing opened and Cleared Ground from the start")
	var starting := 0  # Clear Sight's cards (the opener Tend the Forest, once it exists, and Cleared Ground)
	for id in _unlock(grove, "clear_sight").starting_cards:
		if dreams.pool.any(func(c: UpgradeData) -> bool: return c.id == id):
			starting += 1
	var taken := 0
	for id in dreams.stacks:
		taken += dreams.stacks[id]
	_check(taken == starting + 1, "Kindling: one random Common besides Clear Sight's cards (%s)" % [dreams.stacks])
	_check(run_state.free_nurtures == 0 and dreams.rerolls_left == 0, "perks not carried do nothing")
	_check(not dreams.allow_bittersweet, "no Bittersweet Dreams node: no bittersweet cards")
	var dew_before := run_state.dew
	# Act 1 × its multiplier, Rich Dew +15%, and Gathered Dew if Kindling happened to draw it; fractions kept.
	var expected_dew := floori(20 * run_state.act_dew_multipliers[0] * (1.0 + run_state.dew_gain_bonus + dreams.get_dew_gain_bonus()) + 0.0001)
	for i in 20:  # 20 dispels of 1 Dew: the fractions carry over into whole Dew
		var enemy := Node2D.new()
		enemy.set_script(_FakeEnemy)
		main.add_child(enemy)
		run_state._on_enemy_cleansed(enemy)
		enemy.queue_free()
	_check(run_state.dew - dew_before == expected_dew, "Rich Dew carries fractions: 20 Dew becomes %d (%d)" % [expected_dew, run_state.dew - dew_before])
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
	_check(omens.omens_per_offer == 3, "Omen Reader: facing an Omen reveals 3 (%d)" % omens.omens_per_offer)
	_check(run_state.free_nurtures == 3, "First Care: 3 free Nurture ranks (%d)" % run_state.free_nurtures)
	_check(run_state.max_leaves == run_state.starting_leaves + 3, "Deep Taproot III: +3 max leaves")
	_check(dreams.rerolls_left == 2 and dreams.cards_per_offer == 4, "Second Thoughts II and Wider Dreams")
	_check(dreams.banishes_left == 0, "Let Go owned but not carried")
	main.queue_free()
	await process_frame
	memory = HeartwoodMemory.load_data()
	memory.milestones[MetaRun.ALL_DREAMS] = true
	HeartwoodMemory.save_data(memory)
	main = await _new_run()
	dreams = main.get_node("%DreamState")
	_check(dreams.rerolls_left == 3 and MetaRun.starlit_backs(), "Dream of everything: a 3rd reroll on top of Second Thoughts II, starlit backs (%d)" % dreams.rerolls_left)
	var offer_card: UpgradeData = dreams.pool[0]
	_check(main.get_node("HUD/DreamScreen")._make_card(offer_card).has_node("StarlitBack"), "Dream offer cards get the night-sky back")
	memory.milestones.erase(MetaRun.ALL_DREAMS)
	HeartwoodMemory.save_data(memory)
	_check(dreams.allow_bittersweet and dreams.grove_cards.has("deep_sleep"), "the Bittersweet Dreams node lets bittersweet cards be offered")
	main.queue_free()
	await process_frame

	# --- Saves are atomic, and an unreadable profile never turns into a fresh one ---
	var kept := HeartwoodMemory.load_data()
	kept.seeds = 77
	HeartwoodMemory.save_data(kept)
	HeartwoodMemory.save_data(kept)  # Replaces an existing file, keeping the last as .bak
	_check(int(HeartwoodMemory.load_data().seeds) == 77 and FileAccess.file_exists(PROFILE_PATH + ".bak")
		and not FileAccess.file_exists("%s.%d.tmp" % [PROFILE_PATH, OS.get_process_id()]), "a save replaces the profile through a temp file and keeps a backup")
	var torn := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	torn.store_string("{\"version\": 6, \"seeds\": 7")  # Half-written
	torn.close()
	_check(int(HeartwoodMemory.load_data().seeds) == 77, "a half-written profile reads as the last good copy")
	HeartwoodMemory.forget()
	_check(int(HeartwoodMemory.load_data().seeds) == 77 and FileAccess.file_exists(PROFILE_PATH + ".unreadable"),
		"with nothing cached, an unreadable profile reads from its backup and is kept aside")

	# --- Old profiles: version 1 Grove ids move to the layout ids ---
	var old := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	old.store_string(JSON.stringify({"version": 1, "seeds": 5, "unlocks": {"pebbling_line": 1, "cairn": 1, "sporeling_finals": 1, "morning_stores": 2}}))
	old.close()
	HeartwoodMemory.forget()  # Written behind save_data: never read a cached copy
	memory = HeartwoodMemory.load_data()
	var migrated := {}
	for id in memory.unlocks:
		migrated[id] = int(memory.unlocks[id])
	_check(migrated == {"pebbling": 1, "pebbling_hidden": 1, "morning_stores": 2}, "v1 ids migrate, the old final-forms node refunded (%s)" % [migrated])
	_check(memory.loadout == [] and int(memory.seeds) == 5 + 50, "a migrated profile keeps its Seeds and gets the final-forms 50 back (%d)" % int(memory.seeds))
	old = FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	old.store_string(JSON.stringify({"version": 2, "seeds": 10, "unlocks": {"reactions": 1, "kin_lore": 1, "bittersweet_dreams": 1, "spore_lore": 1}}))
	old.close()
	HeartwoodMemory.forget()  # Written behind save_data: never read a cached copy
	memory = HeartwoodMemory.load_data()
	_check(int(memory.seeds) == 10 + 70 + 50 + 8 and not memory.unlocks.has("reactions") and not memory.unlocks.has("kin_lore")
		and memory.unlocks.has("bittersweet_dreams") and memory.unlocks.has("spore_lore"),
		"v2 profiles: removed discovery nodes refund their Seeds, Bittersweet 8 back (%d, %s)" % [int(memory.seeds), memory.unlocks.keys()])

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

	# --- Balance simulation presets (balance_simulation.md "Profiles") ---
	var tree_total := 0
	for unlock in grove:
		tree_total += unlock.get_spent(unlock.get_levels())
	var spent_share := func(data: Dictionary) -> float:
		var spent := 0
		for unlock in grove:
			spent += unlock.get_spent(HeartwoodMemory.unlock_level(data, unlock.id))
		return float(spent) / tree_total
	var fresh := GrovePresets.profile(&"fresh")
	_check(fresh.unlocks.is_empty() and fresh.loadout.is_empty(), "Fresh: nothing grown")
	var early := GrovePresets.profile(&"early")
	_check(early.unlocks.size() == 5 and early.loadout == ["morning_stores", "deep_taproot"] and HeartwoodMemory.loadout_slots(early) == 3,
		"Early: 5 cheap unlocks, 3 slots, its 2 perks carried (%s)" % [early.loadout])
	var half := GrovePresets.profile(&"half")
	var share: float = spent_share.call(half)
	_check(share >= 0.5 and share < 0.56 and HeartwoodMemory.loadout_slots(half) == 3 and half.loadout.size() == 3,
		"Half: about half the tree by Seeds (%.2f), 3 slots, 3 perks carried (%s)" % [share, half.loadout])
	var full := GrovePresets.profile(&"full")
	_check(is_equal_approx(spent_share.call(full), 1.0) and HeartwoodMemory.loadout_slots(full) == 6 and full.loadout.size() == 6
		and full.milestones.has(HeartwoodMemory.FULL_BLOOM)
		and grove.all(func(u: UnlockData) -> bool: return HeartwoodMemory.is_grown(full, u)), "Full: every node grown, in full bloom, 6 perks carried")
	var real_path := HeartwoodMemory.file_path
	MetaRun.load_preset(&"full")
	_check(HeartwoodMemory.file_path == GrovePresets.file_path, "a preset loads from its own temp profile")
	main = await _new_run()
	family = main.get_node("%FamilyPickScreen")
	run_state = main.get_node("%RunState")
	_check(family.families.size() >= 9 and run_state.max_leaves == run_state.starting_leaves + 3,
		"a Full run: every family in the picks, Deep Taproot III carried (%d families)" % family.families.size())
	main.queue_free()
	await process_frame
	_delete(GrovePresets.file_path)
	HeartwoodMemory.file_path = real_path

	# --- Dev Grove (demo_scope.md): runs and the Grove use a preset's dev profile; the real profile
	# (settings aside) is never read or written, and it's a dev run in the full game ---
	var real := HeartwoodMemory.defaults()
	real.seeds = 7
	real.settings.ui_scale = 1.3
	HeartwoodMemory.save_data(real)
	var real_text := FileAccess.get_file_as_string(PROFILE_PATH)
	ProjectSettings.set_setting("game/demo", true)
	DevGrove.force = &"full"
	DevGrove.apply()
	_check(DevGrove.is_active() and HeartwoodMemory.file_path == GrovePresets.file_path and not ResultsScreen.is_demo() and MetaRun.is_dev_run(),
		"Dev Grove Full: the dev profile, the full game, a dev run")
	_check(is_equal_approx(float(HeartwoodMemory.get_settings().ui_scale), 1.3), "settings still come from the real profile")
	_check(DevGrove.tag() == "Dev Grove: Full", "the tag names the level")
	_check(RunSaver.file_path == DevGrove.RUN_PATH, "dev runs save apart from the real run in progress")
	main = await _new_run()
	(main.get_node("%ResultsScreen") as ResultsScreen).bank_in_tests = true
	_check(not (main.get_node("%MetaRun") as MetaRun).records, "a Dev Grove run records nothing")
	_check((main.get_node("%FamilyPickScreen").families as Array).size() >= 9, "a Dev Grove Full run has every family")
	main.get_node("%RunState").end_run(true)
	await process_frame
	main.queue_free()
	await process_frame
	grove_screen = load("res://scenes/grove.tscn").instantiate()
	root.add_child(grove_screen)
	await process_frame
	view = grove_screen.tree_view
	_check(grove.all(func(u: UnlockData) -> bool: return view.state_of(u) == GroveTreeView.State.OWNED), "the Grove shows every node owned")
	grove_screen.queue_free()
	await process_frame
	var dev_profile := HeartwoodMemory.load_data()
	dev_profile.loadout = ["seed_pouch"]
	HeartwoodMemory.save_data(dev_profile)
	DevGrove.apply()  # Same level again (next launch): the dev profile keeps its changes
	_check(HeartwoodMemory.load_data().loadout == ["seed_pouch"], "Dev Grove keeps its loadout at the same level")
	DevGrove.force = &"early"
	DevGrove.apply()
	_check(HeartwoodMemory.load_data().loadout == ["morning_stores", "deep_taproot"], "another level resets the dev profile to its preset")
	DevGrove.force = &"off"
	DevGrove.apply()
	_check(not DevGrove.is_active() and HeartwoodMemory.file_path == PROFILE_PATH and ResultsScreen.demo_override == -1 and RunSaver.file_path == RunSaver.PATH,
		"Dev Grove off: back to the real profile and run save")
	_check(FileAccess.get_file_as_string(PROFILE_PATH) == real_text, "the real profile was never written")
	DevGrove.force = &""
	_delete(GrovePresets.file_path)
	ProjectSettings.set_setting("game/demo", false)

	# --- v3 profiles: the removed slot_2 / slot_3 nodes refund their Seeds (slots 1–3 are free now) ---
	old = FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	old.store_string(JSON.stringify({"version": 3, "seeds": 0, "unlocks": {"slot_2": 1, "slot_3": 1, "slot_4": 1}}))
	old.close()
	HeartwoodMemory.forget()  # Written behind the profile cache's back
	memory = HeartwoodMemory.load_data()
	_check(int(memory.seeds) == 40 + 80 and not memory.unlocks.has("slot_2") and not memory.unlocks.has("slot_3")
		and memory.unlocks.has("slot_4") and HeartwoodMemory.loadout_slots(memory) == 4,
		"v3 profiles: slot 2 and 3 refund 120 Seeds, slot 4 stays (%d, %s)" % [int(memory.seeds), memory.unlocks.keys()])

	# --- v4 profiles: Reckless and Wild Planting (cut in the pool trim) refund their Seeds ---
	old = FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	old.store_string(JSON.stringify({"version": 4, "seeds": 0, "unlocks": {"reckless": 1, "wild_planting": 1, "sharpened": 1}}))
	old.close()
	HeartwoodMemory.forget()
	memory = HeartwoodMemory.load_data()
	_check(int(memory.seeds) == 40 + 50 and not memory.unlocks.has("reckless") and not memory.unlocks.has("wild_planting")
		and memory.unlocks.has("sharpened"), "v4 profiles: Reckless and Wild Planting refund 90 Seeds (%d, %s)" % [int(memory.seeds), memory.unlocks.keys()])
	_check(_unlock(grove, "full_moon").requires_all == ["sharpened"] and _unlock(grove, "rootbound").requires_all == ["seedbed"],
		"Full Moon grows from Sharpened, Rootbound from Seedbed")

	# --- Memory Wardens: a boss's first dispel grows its bloom; later runs offer it after that boss ---
	HeartwoodMemory.save_data(HeartwoodMemory.defaults())
	main = await _new_run()
	var meta_run: MetaRun = main.get_node("%MetaRun")
	_check(meta_run.memory_wardens.is_empty(), "no Memory Warden blooms on a fresh Grove")
	meta_run._on_boss_dispelled("old_stag")
	meta_run.records = true
	(main.get_node("%ResultsScreen") as ResultsScreen).bank_in_tests = true
	main.get_node("%RunState").end_run(false)
	await process_frame
	main.queue_free()
	await process_frame
	memory = HeartwoodMemory.load_data()
	_check(memory.milestones.has("boss_old_stag"), "a boss's first dispel is recorded (kept even while Memory Wardens are parked)")
	main = await _new_run()
	meta_run = main.get_node("%MetaRun")
	family = main.get_node("%FamilyPickScreen")
	dreams = main.get_node("%DreamState")
	meta_run._on_boss_dispelled("old_stag")
	family.show_pick(&"boss")
	if MetaRun.MEMORY_WARDENS_ENABLED:
		var stag_node := HeartwoodMemory.get_unlock("memory_white_stag")
		_check(stag_node != null and HeartwoodMemory.node_level(memory, stag_node) == 1, "dispelling the Hollow Stag grows the White Stag's bloom")
		_check(meta_run.memory_wardens.has("old_stag") and meta_run.memory_wardens.old_stag.get_id() == "white_stag",
			"a grown bloom makes its Warden available after its boss")
		_check(family.offer.size() > 0 and family.offer[0] is TowerData and family.offer[0].get_id() == "white_stag",
			"the pick after the Hollow Stag offers the White Stag (%s)" % [family._ids(family.offer)])
		family.choose(family.offer[0])
		_check(dreams.is_unlocked("white_stag"), "choosing it plants the White Stag in the run")
	else:  # PARKED (user decision 2026-09-29): no bloom on the tree, no Memory Warden in the pick
		_check(HeartwoodMemory.get_unlock("memory_white_stag") == null and meta_run.memory_wardens.is_empty(),
			"Memory Wardens are parked: no bloom on the Grove, none offered")
		_check(not family.offer.any(func(o) -> bool: return o is TowerData and o.line == "memory"),
			"the pick after the Hollow Stag shows only families and Blessings (%s)" % [family._ids(family.offer)])
	main.queue_free()
	await process_frame

	# --- The Heartwood in full bloom: every node grown opens the secret 6th slot and its waystone ---
	var bloom := GrovePresets.profile(&"full")
	bloom.milestones.erase(HeartwoodMemory.FULL_BLOOM)
	_check(HeartwoodMemory.loadout_slots(bloom) == 5 and not HeartwoodMemory.has_sixth_slot(bloom), "no 6th slot before full bloom")
	var partial := bloom.duplicate(true)
	partial.unlocks.erase("slot_5")
	_check(not HeartwoodMemory.check_full_bloom(partial), "one node short keeps the tree unfinished")
	bloom.erase("sixth_stone_risen")
	HeartwoodMemory.save_data(bloom)
	grove_screen = load("res://scenes/grove.tscn").instantiate()
	root.add_child(grove_screen)
	await process_frame
	memory = HeartwoodMemory.load_data()
	_check(memory.milestones.has(HeartwoodMemory.FULL_BLOOM) and HeartwoodMemory.loadout_slots(memory) == 6
		and memory.get("sixth_stone_risen", false), "the Grove records full bloom and the 6th slot opens")
	_check(grove_screen.tree_view.is_sixth_rising(), "the sixth waystone rises at the roots")
	grove_screen.queue_free()
	await process_frame

	# --- Developer "secret 6th slot": the slot, nothing recorded or written ---
	HeartwoodMemory.save_data(HeartwoodMemory.defaults())
	var plain_text := FileAccess.get_file_as_string(PROFILE_PATH)
	MetaRun.force_sixth_slot = true
	memory = HeartwoodMemory.load_data()
	_check(HeartwoodMemory.loadout_slots(memory) == 4 and MetaRun.is_dev_run(), "the dev toggle: 3 open slots + the secret 6th, a dev run")
	main = await _new_run()
	_check(not (main.get_node("%MetaRun") as MetaRun).records, "a secret-slot dev run records nothing")
	main.queue_free()
	await process_frame
	_check(FileAccess.get_file_as_string(PROFILE_PATH) == plain_text, "the secret-slot toggle writes nothing")
	MetaRun.force_sixth_slot = false

	# --- Developer "Dream of everything rewards": both rewards, nothing recorded or written ---
	HeartwoodMemory.save_data(HeartwoodMemory.defaults())
	var fresh_text := FileAccess.get_file_as_string(PROFILE_PATH)
	MetaRun.force_all_dreams = true
	main = await _new_run()
	dreams = main.get_node("%DreamState")
	_check(dreams.rerolls_left == 1 and MetaRun.starlit_backs() and MetaRun.is_dev_run() and not (main.get_node("%MetaRun") as MetaRun).records,
		"the dev toggle: 1 reroll, starlit backs, a dev run")
	(main.get_node("%ResultsScreen") as ResultsScreen).bank_in_tests = true
	main.get_node("%RunState").end_run(true)
	await process_frame
	_check(FileAccess.get_file_as_string(PROFILE_PATH) == fresh_text, "the dev toggle writes nothing (no milestone, no Seeds)")
	main.queue_free()
	await process_frame
	MetaRun.force_all_dreams = false

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
	_delete(SIM_PATH)
	GrovePresets.file_path = GrovePresets.PATH
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
	for file in [path, path + ".bak", path + ".unreadable"]:  # With save_data's backup
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))

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
	var parked := 0 if MetaRun.MEMORY_WARDENS_ENABLED else 3  # Memory Warden blooms: in the layout, off the tree
	_check(nodes.size() == 73 and grove.size() == 73 - parked, "73 Grove spots, %d nodes on the tree (layout %d, data %d)" % [73 - parked, nodes.size(), grove.size()])
	for node in nodes:
		var unlock := HeartwoodMemory.get_unlock(node.id)
		if unlock == null and node.get("memory_row") != null and parked > 0:
			continue  # A parked Memory Warden bloom
		if unlock == null:
			_check(false, "layout node %s has an UnlockData" % node.id)
			continue
		_check(unlock.get_section() == node.section, "%s is on the %s limb" % [node.id, node.section])
		_check(maxi(unlock.get_levels(), 1) == int(node.levels), "%s has %d levels" % [node.id, int(node.levels)])
		_check(unlock.legendary == bool(node.legendary) and unlock.start == bool(node.start), "%s: Legendary / start match" % node.id)
		_check(ResourceLoader.exists("res://assets/meta/grove/branches/%s.png" % node.id), "%s has branch art" % node.id)
		if node.parent != null and node.id != "firefly_jar_ascension":  # Drawn from Sunpetal, needs final forms
			_check(unlock.requires_all.any(func(r: String) -> bool: return r.split(":")[0] == node.parent) or unlock.milestone != "" and unlock.is_free()
				or (unlock.requires_all.is_empty() and unlock.requires_any.is_empty()),  # Drawn off a node it doesn't need (a start family, Stormheart)
				"%s needs its parent %s" % [node.id, node.parent])
	for unlock in grove:
		_check(nodes.any(func(n) -> bool: return n.id == unlock.id), "%s is on the tree" % unlock.id)

func dreams_first_pick(main: Node) -> int:
	return (main.get_node("%DreamState") as DreamState).first_pick_dreamlight
