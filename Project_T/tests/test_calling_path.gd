extends SceneTree
# Calling evolutions (scripts/combat/calling_paths.gd, DreamState.calling_path; owner 2026-10-16). Written 2026-10-16 and
# NOT RUN (the owner runs tests on request). The offers at the drift 20 / 45 / 60 / 75 rests, the pick, no reroll or skip,
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
	_check(PATHS.next_ids("sporeling", [&"sp_clump", &"sp_trampled", &"sp_pile_on"]) == [&"sp_trodden", &"sp_throne"],
		"Drift 75: the capstone's Deepen first, then the style's other follow-up (Spore Print rebuilt 2026-10-23)")
	_check(PATHS.next_ids("sporeling", [&"sp_clump", &"sp_rot", &"sp_rotburst"]).is_empty(), "An old save's retired Spore Print path offers nothing")
	# Keeping Time final pass 2026-10-24 (evo_fixed_bellflower.md): Humming Walls' line retired, Last Bell -> Curfew -> Halfway Bell
	_check(not PATHS.is_live(&"kt_evo_humming_walls") and not PATHS.is_live(&"kt_evo_down_the_line") and not PATHS.is_live(&"kt_evo_both_ways"),
		"Keeping Time: the Humming Walls line is retired")
	_check(PATHS.next_ids("bellflower", [&"kt_evo_carrying_tune"]) == [&"kt_evo_hand_to_hand", &"kt_evo_last_bell"] \
			or PATHS.next_ids("bellflower", [&"kt_evo_carrying_tune"]) == [&"kt_evo_last_bell", &"kt_evo_hand_to_hand"],
		"Keeping Time: drift 45 after Carrying Tune offers Hand to Hand and Last Bell")
	_check(PATHS.next_ids("bellflower", [&"kt_evo_carrying_tune", &"kt_evo_last_bell", &"kt_evo_curfew"]) == [&"kt_evo_halfway_bell", &"kt_evo_hand_to_hand"],
		"Keeping Time: drift 75 Curfew's Deepen (Halfway Bell) first, then Hand to Hand")
	_check(PATHS.next_ids("bellflower", [&"kt_evo_carrying_tune", &"kt_evo_humming_walls"]).is_empty(), "...an old save holding Humming Walls is offered nothing more")
	var bell_live := 0
	for id in PATHS.PATHS:
		if PATHS.PATHS[id].calling == "bellflower" and PATHS.is_live(id):
			bell_live += 1
	_check(bell_live == 21, "Keeping Time: 21 live rows (%d)" % bell_live)
	_check(PATHS.stage_of(20) == 0 and PATHS.stage_of(45) == 1 and PATHS.stage_of(60) == 2 and PATHS.stage_of(75) == 3 and PATHS.stage_of(5) < 0 and PATHS.stage_of(25) < 0 and PATHS.stage_of(35) < 0, "Calling drifts are 20, 45, 60, 75 (owner playtest 2026-10-25)")
	# Owner 2026-10-17: Riverside, Stagnant Water, Show the Way and Chime of Many use their own family's trait; faces stay short
	# and their capstones keep their parents.
	for id in [&"dw_riverside", &"dw_stagnant_water", &"lf_show_the_way"]:  # (Chime of Many retired with the Keeping Time rebuild, section 33)
		var row: Dictionary = PATHS.PATHS[id]
		_check(String(row.text).split(" ", false).size() <= 25 and String(row.tip).split(" ", false).size() <= 30, "%s: face at most 25 words, tip at most 30" % id)
		_check(not row.makes.has(&"stacks"), "%s no longer makes stacks" % id)
	_check(PATHS.children(&"lf_lantern_wake") == [&"lf_show_the_way"], "the reworked follow-ups keep their capstones")
	# Puddles rebuilt 2026-10-23 (evo_fixed_dewdrop.md): Stagnant Water and Drowned Hands are retired (children skip them)
	_check(PATHS.children(&"dw_stagnant_water").is_empty() and not PATHS.is_live(&"dw_stagnant_water"), "Stagnant Water is retired")
	# F3 (owner 2026-10-18; lent_evolution_builds.md): Lantern Wake is Borrowed Light's follow-up (drift 45), Show the Way
	# its capstone (drift 60; the demo, ending at 50, stops before it since 2026-10-25).
	_check(int(PATHS.PATHS[&"lf_lantern_wake"].tier) == PATHS.FOLLOW_UP and PATHS.PATHS[&"lf_lantern_wake"].parent == &"lf_borrowed_light",
		"F3: Lantern Wake is a follow-up under Borrowed Light")
	_check(int(PATHS.PATHS[&"lf_show_the_way"].tier) == PATHS.CAPSTONE and PATHS.PATHS[&"lf_show_the_way"].parent == &"lf_lantern_wake",
		"F3: Show the Way is the capstone under Lantern Wake")
	var borrowed_next := PATHS.next_ids("firefly_jar", [&"lf_borrowed_light"])
	_check(borrowed_next.size() == 2 and borrowed_next.has(&"lf_lantern_wake") and borrowed_next.has(&"lf_sightline"),
		"F3: drift 45 after Borrowed Light offers Lantern Wake and Sightline")
	_check(PATHS.next_ids("firefly_jar", [&"lf_borrowed_light", &"lf_lantern_wake"]) == [&"lf_show_the_way"], "F3: drift 50 then offers Show the Way")
	_check(PATHS.next_ids("firefly_jar", [&"lf_borrowed_light", &"lf_lantern_wake", &"lf_show_the_way"]) == [&"lf_full_glow", &"lf_sightline"],
		"F3: drift 75 Show the Way's Deepen (Full Glow) first, then the style's other follow-up (Sightline) (rebuilt 2026-10-23)")
	_check(String(PATHS.PATHS[&"dw_stagnant_water"].tip).contains("on top of cards that do the same"), "F2: Stagnant Water's tip (retired, kept) says its linger adds on top")
	_check(String(PATHS.PATHS[&"dw_riverside"].tip).contains("Up to 4 s past landing in all"), "Riverside's tip says the one room")
	_check(String(PATHS.PATHS[&"dw_rain_on_the_bank"].tip).contains("{drowsy} stops 1 short of {full}"), "F5: Rain on the Bank's tip")
	# Puddles (rebuilt 2026-10-23): 21 live rows; the three lines; keeps_out per the spec's final list
	var dw_live := PATHS.PATHS.keys().filter(func(i) -> bool: return PATHS.PATHS[i].calling == "dewdrop" and PATHS.is_live(i))
	_check(dw_live.size() == 21, "Puddles has 21 live rows (%d)" % dw_live.size())
	# Final pass 2026-10-24: Spread burst (Floodgate), Focus bosses (Undertow), Support mouth (River Mouth) lines
	_check(PATHS.next_ids("dewdrop", [&"dw_stream", &"dw_floodgate", &"dw_spate"], 3) == [&"dw_silt", &"dw_backwaters"],
		"Puddles drift 75: Silt (Deepen) first, then Backwaters (Cross over)")
	_check(PATHS.next_ids("dewdrop", [&"dw_black_pond", &"dw_undertow", &"dw_fathoms"], 3) == [&"dw_crushing_depth", &"dw_deep_end"],
		"Puddles drift 75: Crushing Depth, then Deep End")
	_check(PATHS.next_ids("dewdrop", [&"dw_riverside", &"dw_river_mouth", &"dw_delta"], 3) == [&"dw_rapids", &"dw_open_water"],
		"Puddles drift 75: Rapids, then Open Water")
	_check(PATHS.next_ids("dewdrop", [&"dw_stream", &"dw_backwaters", &"dw_mudflats"], 3) == [&"dw_sinking_mud", &"dw_floodgate"],
		"Puddles drift 75: Sinking Mud, then Floodgate")
	for old in [&"dw_reed_bed", &"dw_flash_flood", &"dw_long_current", &"dw_twin_springs", &"dw_churning_water", &"dw_three_springs",
			&"dw_wet_footprints", &"dw_low_tide", &"dw_outflow"]:
		_check(PATHS.PATHS.has(old) and not PATHS.is_live(old), "%s is retired, kept for old saves" % old)
	_check(PATHS.next_ids("dewdrop", [&"dw_riverside", &"dw_wet_footprints", &"dw_low_tide"], 3).is_empty(), "An old Wet Footprints path offers nothing")
	_check(PATHS.keeps_out(&"dw_riverside") == [&"steeped"] and PATHS.keeps_out(&"dw_still_water") == [&"topped_up"]
		and PATHS.keeps_out(&"dw_river_mouth") == [&"high_tide"] and PATHS.keeps_out(&"dw_low_tide") == [&"high_tide"],
		"Puddles keeps_out: Steeped, Topped Up, High Tide (River Mouth; retired Low Tide still for old saves)")
	_check(PATHS.next_ids("dewdrop", [&"dw_stream", &"dw_millrace"], 2).is_empty(), "An old save's retired Puddles path offers nothing")

	# The offer at the drift 20 rest comes first and that rest's Dream follows (owner playtest 2026-10-25: was drift 5)
	dreams.calling = "sporeling"
	_check(dreams._calling_offer_for(5).is_empty() and dreams._calling_offer_for(25).is_empty(), "Drifts 5 and 25 have no Calling offer (their normal Dreams)")
	var offer := dreams._calling_offer_for(20)
	_check(offer.size() == 3 and offer[0].tags.has("calling_evolution"), "Drift 20 offers the 3 styles as cards")
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
	_check(dreams._calling_offer_for(45).size() == 2, "Drift 45 offers the style's 2 follow-ups")

	# The save keeps the path
	var saved: Dictionary = dreams.to_save()
	dreams.calling_path.clear()
	dreams.load_save(saved)
	_check(dreams.calling_path == [StringName(offer[1].id)], "The path survives a save")

	# An old save that took a Sporeling class card keeps it and never evolves
	dreams.calling_path.clear()
	dreams._calling_offered.clear()
	dreams.stacks["mushroom_bed"] = 1
	_check(dreams._calling_offer_for(45).is_empty(), "A run holding class cards never evolves")
	dreams.stacks.erase("mushroom_bed")

	_split_builds()
	print("test_calling_path: %d failures" % failures)
	quit(failures)

# Calling evolutions that split into builds (owner 2026-10-23, dream_council_review.md 33; evo_shared_spec.md 1, 7, 9).
func _split_builds() -> void:
	var styles := PATHS.next_ids("sporeling", [], 0)
	_check(not styles.is_empty(), "Stage 0 offers the styles")
	_check(PATHS.next_ids("sporeling", [], 1).is_empty(), "A stage that doesn't match the path's length offers nothing")
	_check(PATHS.next_ids("sporeling", [styles[0]], 0).is_empty(), "A repeated stage offers nothing")
	_check(PATHS.next_ids("sporeling", [&"not_a_row"], 1).is_empty(), "An unknown id in the path offers nothing")
	# Every live row: its parent is live and one tier up; the styles' makes are disjoint per Calling
	var makes_by_calling := {}
	for id in PATHS.PATHS:
		if not PATHS.is_live(id):
			continue
		var row: Dictionary = PATHS.PATHS[id]
		if int(row.tier) == PATHS.STYLE:
			var seen: Dictionary = makes_by_calling.get(row.calling, {})
			for m in row.get("makes", []):
				_check(not seen.has(m), "%s: styles share no makes chip (%s)" % [id, m])
				seen[m] = true
			makes_by_calling[row.calling] = seen
			continue
		_check(PATHS.is_live(row.parent), "%s: its parent %s is live" % [id, row.parent])
		if PATHS.PATHS.has(row.parent):
			_check(int(row.tier) == int(PATHS.PATHS[row.parent].tier) + 1, "%s: one tier below its parent" % id)
	# Drift 75: a capstone's Deepen first, then the style's other follow-up
	for style in styles:
		var follow := PATHS.children(style)
		if follow.is_empty() or PATHS.children(follow[0]).is_empty():
			continue
		var cap: StringName = PATHS.children(follow[0])[0]
		var at_75 := PATHS.next_ids("sporeling", [style, follow[0], cap], 3)
		var deepens := PATHS.children(cap).filter(func(i: StringName) -> bool: return int(PATHS.PATHS[i].tier) == PATHS.DEEPEN)
		_check(at_75.slice(0, deepens.size()) == deepens, "%s: Deepen first at drift 75" % style)
		_check(follow.size() < 2 or at_75.has(follow[1]), "%s: the other follow-up is the Cross over" % style)
	# A save keeps every id, an unknown one as a placeholder (no effect, length kept)
	dreams.calling_path.assign([styles[0], &"retired_or_unknown", &"another_unknown"])
	var saved := dreams.to_save()
	dreams.calling_path.clear()
	dreams.load_save(saved)
	_check(dreams.calling_path.size() == 3 and dreams.calling_path[1] == &"retired_or_unknown", "Unknown ids survive a save, length kept")
	_check(PATHS.next_ids("sporeling", dreams.calling_path, 3).is_empty(), "…and the path offers nothing after them")
	_check(not dreams.calling_evolutions_text().contains("retired_or_unknown"), "…and never shows")
	# keeps_out: a held row keeps a card out of offers and the new family's lent slot; a card already taken stays
	var card: UpgradeData = dreams.pool[0]
	dreams._calling_keeps_out[card.id] = true
	_check(not dreams.can_offer(card), "keeps_out blocks can_offer")
	_check(not dreams._new_family_can_show(card, 3), "…and the new family's lent card")
	dreams.stacks[card.id] = 1
	_check(dreams.has_card(card.id), "…never retroactive: a held card stays")
	dreams.stacks.erase(card.id)
	dreams.calling_path.clear()
	dreams._rebuild_calling_flags()
	_check(not dreams._calling_keeps_out.has(card.id), "Rebuilt from the path: nothing kept out with no rows held")
