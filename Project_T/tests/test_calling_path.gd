extends SceneTree
# Calling evolutions (scripts/combat/calling_paths.gd, DreamState.calling_path; owner 2026-10-16). Written 2026-10-16 and
# NOT RUN (the owner runs tests on request). The offers at the drift 5 / 25 / 50 / 75 rests, the pick, no reroll or skip,
# the save, and old saves that took class cards.
var failures := 0
var main: Node
var dreams: DreamState
const PATHS := preload("res://scripts/combat/calling_paths.gd")

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	dreams = main.get_node("%DreamState")

	# The table: 3 styles, 2 follow-ups each, a capstone under each follow-up
	var styles := PATHS.next_ids("sporeling", [])
	_check(styles.size() == 3, "Spore Print offers 3 styles (%d)" % styles.size())
	for style in styles:
		var follow := PATHS.children(style)
		_check(follow.size() == 2, "%s has 2 follow-ups" % style)
		for f in follow:
			_check(PATHS.children(f).size() == 1, "%s has 1 capstone" % f)
	for family in ["sporeling", "firefly_jar", "dewdrop", "bellflower"]:
		_check(PATHS.next_ids(family, []).size() == 3, "%s has 3 styles" % family)
	_check(PATHS.next_ids("sporeling", [&"sp_clump", &"sp_rot", &"sp_rotburst"]) == [&"sp_sticky"], "Drift 75: the style's other follow-up")
	_check(PATHS.stage_of(5) == 0 and PATHS.stage_of(45) == 2 and PATHS.stage_of(50) < 0 and PATHS.stage_of(75) == 3 and PATHS.stage_of(10) < 0, "Calling drifts are 5, 25, 45, 75")
	# Owner 2026-10-17: Riverside, Stagnant Water, Show the Way and Chime of Many use their own family's trait; faces stay short
	# and their capstones keep their parents.
	for id in [&"dw_riverside", &"dw_stagnant_water", &"lf_show_the_way", &"kt_evo_chime_of_many"]:
		var row: Dictionary = PATHS.PATHS[id]
		_check(String(row.text).split(" ", false).size() <= 25 and String(row.tip).split(" ", false).size() <= 30, "%s: face at most 25 words, tip at most 30" % id)
		_check(not row.makes.has(&"stacks"), "%s no longer makes stacks" % id)
	_check(PATHS.children(&"dw_stagnant_water") == [&"dw_drowned_hands"] and PATHS.children(&"lf_lantern_wake") == [&"lf_show_the_way"]
		and PATHS.children(&"kt_evo_chime_of_many") == [&"kt_evo_last_chord"], "the reworked follow-ups keep their capstones")
	# F3 (owner 2026-10-18; lent_evolution_builds.md): Lantern Wake is Borrowed Light's follow-up (drift 25), Show the Way
	# its capstone (drift 45), so Firefly's status link arrives inside the demo.
	_check(int(PATHS.PATHS[&"lf_lantern_wake"].tier) == PATHS.FOLLOW_UP and PATHS.PATHS[&"lf_lantern_wake"].parent == &"lf_borrowed_light",
		"F3: Lantern Wake is a follow-up under Borrowed Light")
	_check(int(PATHS.PATHS[&"lf_show_the_way"].tier) == PATHS.CAPSTONE and PATHS.PATHS[&"lf_show_the_way"].parent == &"lf_lantern_wake",
		"F3: Show the Way is the capstone under Lantern Wake")
	var borrowed_next := PATHS.next_ids("firefly_jar", [&"lf_borrowed_light"])
	_check(borrowed_next.size() == 2 and borrowed_next.has(&"lf_lantern_wake") and borrowed_next.has(&"lf_sightline"),
		"F3: drift 25 after Borrowed Light offers Lantern Wake and Sightline")
	_check(PATHS.next_ids("firefly_jar", [&"lf_borrowed_light", &"lf_lantern_wake"]) == [&"lf_show_the_way"], "F3: drift 50 then offers Show the Way")
	_check(PATHS.next_ids("firefly_jar", [&"lf_borrowed_light", &"lf_lantern_wake", &"lf_show_the_way"]) == [&"lf_sightline"],
		"F3: drift 75 the style's other follow-up (Sightline)")
	for id in [&"dw_riverside", &"dw_stagnant_water"]:
		_check(String(PATHS.PATHS[id].tip).contains("on top of cards that do the same"), "F2: %s's tip says its linger adds on top" % id)
	_check(String(PATHS.PATHS[&"dw_rain_on_the_bank"].tip).contains("{drowsy} stops 1 short of {full}"), "F5: Rain on the Bank's tip")

	# The offer at the drift 5 rest replaces the Dream; at 25 it comes first and the Dream follows
	dreams.calling = "sporeling"
	var offer := dreams._calling_offer_for(5)
	_check(offer.size() == 3 and offer[0].tags.has("calling_evolution"), "Drift 5 offers the 3 styles as cards")
	_check(dreams._calling_offer_for(10).is_empty(), "No Calling offer at drift 10")
	dreams.current_offer = offer
	dreams.offering_calling = true
	_check(not dreams.can_skip() and not dreams.reroll(), "A Calling pick can't be passed or rerolled")
	var stacks_before := dreams.stacks.size()
	dreams.choose(offer[1])
	_check(dreams.calling_path == [StringName(offer[1].id)], "Choosing adds the style to the path")
	_check(dreams.stacks.size() == stacks_before, "An evolution is never taken as a card")
	_check(not dreams.offering_calling, "The Calling offer closed")
	_check(dreams.calling_path_text().begins_with("Spore Print → "), "The path reads 'Spore Print → …'")
	_check(dreams._calling_offer_for(25).size() == 2, "Drift 25 offers the style's 2 follow-ups")

	# The save keeps the path
	var saved: Dictionary = dreams.to_save()
	dreams.calling_path.clear()
	dreams.load_save(saved)
	_check(dreams.calling_path == [StringName(offer[1].id)], "The path survives a save")

	# An old save that took a Sporeling class card keeps it and never evolves
	dreams.calling_path.clear()
	dreams._calling_offered.clear()
	dreams.stacks["mushroom_bed"] = 1
	_check(dreams._calling_offer_for(25).is_empty(), "A run holding class cards never evolves")
	dreams.stacks.erase("mushroom_bed")

	print("test_calling_path: %d failures" % failures)
	quit(failures)
