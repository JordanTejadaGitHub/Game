extends SceneTree

# Headless test for the branch expansion's run offer (tower_design.md "Branch expansion: 5 branches, 2 per run",
# Spire branch; DreamState): 2 of a family's 5 regular branches per run, seeded, never last run's pair, the smart
# draw adding an uncovered counter tag, the rest "not in this dream" (their finals too), the Dreamlight call-back
# once per family, Remembered Path's free call, card gating (Entwined ingredients too), the run save, small families
# offering all, and the demo keeping today's branches. Never touches the player's saves.
#   godot --headless --path . --script res://tests/test_branch_offer.gd --fixed-fps 60

var failures := 0
var dreams: DreamState

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var real_profile := HeartwoodMemory.file_path
	HeartwoodMemory.file_path = "user://test_branch_offer_%d.json" % OS.get_process_id()  # Per process
	ResultsScreen.demo_override = 0  # The full game (tests read the project's demo setting otherwise)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 777
	root.add_child(main)
	for i in 3:
		await process_frame
	dreams = main.get_node("%DreamState")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var has_tags := "counter_tags" in TowerData.new()
	var has_phase := "expansion_phase" in TowerData.new()

	# A family of 5 regular branches (each with a final); b3 alone counters flyers
	var base := _form("test_base", 1)
	base.buildable_directly = true
	var branches: Array[TowerData] = []
	for i in 5:
		var branch := _form("test_b%d" % (i + 1), 2)
		branch.evolves_to.append(_form("test_f%d" % (i + 1), 3))
		if has_tags and i == 2:
			branch.set("counter_tags", [&"anti_air"] as Array[StringName])
		if has_tags and i == 4:
			branch.set("counter_tags", [&"anti_tank"] as Array[StringName])  # Rarer, and counting double
		branches.append(branch)
		base.evolves_to.append(branch)
	placer.towers.append(base)
	dreams.unlocked[base.get_id()] = true
	dreams.unlocks_changed.emit()  # A family pick
	var offer: Array = dreams.get_branch_offer(base)
	_check(offer.size() == 2 and dreams.branch_offers.has(base.get_id()), "a family pick draws 2 of its 5 branches (%s)" % [offer])
	_check(dreams.not_offered_branches(base).size() == 3, "…the other 3 are not in this dream")
	if has_tags:
		_check(offer.has("test_b5") or offer.has("test_b3"), "the smart draw adds an uncovered counter tag (%s)" % [offer])
		var with_tank := 0
		for s in 40:
			main.get_node("MapGenerator").map_seed = 900 + s
			dreams.branch_offers.erase(base.get_id())
			if dreams.get_branch_offer(base).has("test_b5"):
				with_tank += 1
		main.get_node("MapGenerator").map_seed = 777
		dreams.branch_offers.erase(base.get_id())
		offer = dreams.get_branch_offer(base)
		_check(with_tank >= 22, "the weighted draw favours the missing anti_tank (%d of 40 runs; a plain draw: 16)" % with_tank)
	else:
		print("  (smart draw check skipped: TowerData.counter_tags isn't on this branch yet)")
	# Seeded: the same map and family draw the same pair
	dreams.branch_offers.clear()
	_check(dreams.get_branch_offer(base) == offer, "a resume (the same seed) draws the same pair")
	# Never last run's pair for this family
	var memory := HeartwoodMemory.load_data()
	var sorted := offer.duplicate()
	sorted.sort()
	memory["last_branch_offer"] = {base.get_id(): sorted}
	HeartwoodMemory.save_data(memory)
	dreams.branch_offers.clear()
	var again := dreams.get_branch_offer(base).duplicate()
	again.sort()
	_check(again != sorted, "never the same 2 as that family's last run (%s, last %s)" % [again, sorted])
	_check(HeartwoodMemory.load_data().get("last_branch_offer", {}).get(base.get_id(), []) == sorted,
		"…and a test never writes the profile's last offer")
	offer = dreams.get_branch_offer(base)

	# Not in this dream: the branch and its final can't be unlocked; the offered ones can
	var off: TowerData = dreams.not_offered_branches(base)[0]
	var on: TowerData = _form_by_id(branches, offer[0])
	_check(dreams.get_unlock_blocker(off) == DreamState.NOT_IN_DREAM and dreams.get_unlock_blocker(off.evolves_to[0]) == DreamState.NOT_IN_DREAM,
		"a branch not offered and its final are \"%s\"" % DreamState.NOT_IN_DREAM)
	_check(dreams.get_unlock_blocker(on) == "", "an offered branch unlocks as before")

	# The Dreamlight call-back: 3, once per family; the unlock comes with it
	dreams.dreamlight = DreamState.CALL_BACK_DREAMLIGHT - 1
	_check(dreams.call_back_problem(off) == "Not enough Dreamlight", "the call-back costs %d Dreamlight" % DreamState.CALL_BACK_DREAMLIGHT)
	dreams.dreamlight = DreamState.CALL_BACK_DREAMLIGHT + 4
	_check(dreams.call_back(off) and dreams.is_unlocked(off.get_id()) and dreams.is_branch_offered(off)
		and dreams.dreamlight == 4, "calling it back pays %d and unlocks it" % DreamState.CALL_BACK_DREAMLIGHT)
	_check(dreams.get_unlock_blocker(off.evolves_to[0]) == "" and dreams.get_unlock_cost(off.evolves_to[0]) == DreamState.FINAL_DREAMLIGHT,
		"…its final then unlocks for %d as usual" % DreamState.FINAL_DREAMLIGHT)
	var second: TowerData = dreams.not_offered_branches(base)[0]
	_check(dreams.call_back_problem(second).begins_with("already called"), "…once per family per run")
	# Remembered Path: a free call, past the once
	var lucid: UpgradeData = load("res://resource/dream/lucid_dream.tres")
	_check(lucid.rarity == UpgradeData.Rarity.RARE and dreams.can_offer(lucid, 2) == dreams.in_run_pool(lucid), "Remembered Path is a Rare card, offered while a branch is missing")
	dreams.take(lucid)
	_check(dreams.free_calls == 1 and dreams.call_back(second) and dreams.dreamlight == 4 and dreams.free_calls == 0,
		"Remembered Path calls one more back, free")
	_check(not dreams.can_offer(lucid, 2) or dreams.has_branch_to_call(), "…and it isn't offered with nothing left to call")

	# Card gating: a card naming a branch not in this run waits; an Entwined card needing it too
	var last_off: TowerData = dreams.not_offered_branches(base)[0]
	var branch_card := UpgradeData.new()
	branch_card.id = "test_branch_card"
	branch_card.requires = [last_off.get_id()] as Array[String]
	var entwined := UpgradeData.new()
	entwined.id = "test_entwined"
	entwined.requires = ["test_branch_card"] as Array[String]
	dreams.pool.append(branch_card)
	_check(not dreams.branch_cards_open(branch_card), "a card needing a branch not in this run isn't offered")
	_check(not dreams.branch_cards_open(entwined), "…nor an Entwined card with it as an ingredient")
	var final_card := UpgradeData.new()
	final_card.id = "test_final_card"
	final_card.requires = [last_off.evolves_to[0].get_id()] as Array[String]
	_check(not dreams.branch_cards_open(final_card), "…nor one needing its final")
	var open_card := UpgradeData.new()
	open_card.requires = [offer[0]] as Array[String]
	_check(dreams.branch_cards_open(open_card), "a card needing an offered branch is open")
	dreams.pool.erase(branch_card)

	# The run save keeps the offer and the calls
	var saved := JSON.parse_string(JSON.stringify(dreams.to_save())) as Dictionary
	var offer_before: Array = dreams.get_branch_offer(base).duplicate()
	dreams.branch_offers.clear()
	dreams.called_families.clear()
	dreams.load_save(saved)
	_check(dreams.get_branch_offer(base) == offer_before and dreams.called_families.has(base.get_id()), "the offer and the call survive the save")

	# The Remember screen: the last branch not in this dream is a misty silhouette at the root's level, its final
	# hidden; the side panel says so and calls it back (once per family: here only Remembered Path's free call can)
	var screen := main.get_node("%RememberScreen") as RememberScreen
	var misty: TowerData = dreams.not_offered_branches(base)[0]
	screen.open(base)
	await process_frame
	var nodes: Dictionary = screen._canvas.nodes
	var shown_branch: TowerData = _form_by_id(branches, offer[0])
	_check(nodes.has(misty) and screen.state_of(misty) == RememberScreen.State.NOT_IN_DREAM, "Remember shows it \"not in this dream\"")
	_check(not nodes.has(misty.evolves_to[0]) and nodes.has(shown_branch.evolves_to[0]), "…without its final (offered branches keep theirs)")
	_check(nodes.has(misty) and nodes.has(shown_branch) and nodes[misty].position.y > nodes[shown_branch].position.y,
		"…lower in the tree than the offered branches")
	_check(nodes.has(misty) and nodes[misty].modulate.a < 1.0, "…faint")
	screen._select(misty)
	var call: Button = screen._side_box.find_child("CallBackButton", true, false)
	var side_text := " ".join(screen._side_box.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text))
	_check(side_text.contains(RememberScreen.NOT_IN_DREAM_LINE), "the side panel: \"%s\"" % RememberScreen.NOT_IN_DREAM_LINE)
	_check(call != null and call.disabled and side_text.contains("Already called"), "…the call-back is spent for this family")
	dreams.free_calls = 1
	screen._select(misty)
	call = screen._side_box.find_child("CallBackButton", true, false)
	_check(call != null and not call.disabled and call.text.contains("free"), "…a Remembered Path call is free (\"%s\")" % (call.text if call else ""))
	if call != null:
		call.pressed.emit()
	_check(dreams.is_unlocked(misty.get_id()) and screen.state_of(misty) == RememberScreen.State.UNLOCKED, "…and calling it unlocks it there")
	screen.close()

	# A family with 2 regular branches offers both
	var sporeling: TowerData = load("res://resource/tower/sporeling.tres")
	var regular := dreams.regular_branches(sporeling)
	if regular.size() <= 2:
		dreams.unlocked[sporeling.get_id()] = true
		_check(dreams.get_branch_offer(sporeling).size() == regular.size(), "a family with %d regular branches offers them all" % regular.size())

	# The demo keeps today's branches: no draw, the expansion's forms not in it
	ResultsScreen.demo_override = 1
	_check(dreams.is_branch_offered(dreams.not_offered_branches(base)[0] if not dreams.not_offered_branches(base).is_empty() else off),
		"the demo: every branch as today")
	if has_phase:
		var new_branch := _form("test_new", 2)
		new_branch.set("expansion_phase", 1)
		base.evolves_to.append(new_branch)
		_check(dreams.get_unlock_blocker(new_branch) == "not in the demo" and not dreams.regular_branches(base).has(new_branch),
			"…and the expansion's new branches aren't in it")
	else:
		print("  (demo phase check skipped: TowerData.expansion_phase isn't on this branch yet)")
	ResultsScreen.demo_override = 0

	placer.towers.erase(base)
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	HeartwoodMemory.file_path = real_profile
	ResultsScreen.demo_override = -1
	print("branch offer test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _form(id: String, tier: int) -> TowerData:
	var data := TowerData.new()
	data.id = id
	data.display_name = id
	data.tier = tier
	data.buildable_directly = tier == 1  # Branches and finals are grown, not planted
	data.line = "spore"
	return data

func _form_by_id(forms: Array[TowerData], id: String) -> TowerData:
	for form in forms:
		if form.get_id() == id:
			return form
	return null

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
