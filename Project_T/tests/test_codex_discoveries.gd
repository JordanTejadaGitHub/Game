extends SceneTree

# Headless test for Codex discoveries (screens_ui.md "The Codex", "Saved in the profile"):
# - a normal run's discoveries (a base combo and a Crowned Reaction) show in the Codex right after,
#   mid-run from the pause menu and from the Memory Grove;
# - a developer run's (Unlock all families) are saved too, with a hidden dev flag that keeps them out
#   of the milestone; a later normal-run find clears it.
# Uses temp profile / run-save files; never the player's.
#   godot --headless --path . --script res://tests/test_codex_discoveries.gd --fixed-fps 60

var PROFILE_PATH := "user://test_codex_discoveries_profile_%d.json" % OS.get_process_id()  # Per process: parallel sessions share user://
var RUN_PATH := "user://test_codex_discoveries_run_%d.json" % OS.get_process_id()  # Per process: parallel sessions share user://

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = PROFILE_PATH
	RunSaver.file_path = RUN_PATH
	_clean()
	ResultsScreen.demo_override = 0  # Full game: the Codex lists Crowned Reactions

	# --- A normal run: found mid-run, shown in the pause menu's Codex at once ---------------------
	var main := await _start_run()
	var feedback := root.get_tree().get_first_node_in_group(ComboFeedback.GROUP) as ComboFeedback
	_check(not MetaRun.is_dev_run(), "a normal run")
	feedback.record(&"thunderclap")
	feedback.record(&"tempest")
	var saved := ComboFeedback.profile_seen()
	_check(saved.has("thunderclap") and saved.has("tempest"), "normal-run discoveries are saved (%s)" % str(saved))
	var pause_menu = main.get_node("%PauseMenu")
	pause_menu.open_codex(&"combos")
	await process_frame
	var codex: CodexPanel = pause_menu.codex
	_check(_shown(codex, "thunderclap", "Thunderclap"), "the pause menu's Codex shows Thunderclap right away")
	_check(_shown(codex, "tempest", "Tempest"), "…and the Crowned Tempest")
	# Discovery unlocks: a discovered Reaction lists the Dreams it let in; the discovery card says so.
	_check(CodexData.dreams_for("reaction:thunderclap").size() >= 1, "Thunderclap unlocks Dreams (" + str(CodexData.dreams_for("reaction:thunderclap")) + ")")
	_check(CodexData.discovery_key(CodexData.get_any(&"thunderclap")) == "reaction:thunderclap" and CodexData.discovery_key(CodexData.get_any(&"conducted")) == "",
		"entries map to their discovery keys (synergies have none)")
	var probe_card := VBoxContainer.new()
	codex._add_dreams_line(probe_card, CodexData.get_any(&"thunderclap"))
	_check(probe_card.get_node_or_null("Dreams") != null and probe_card.get_node("Dreams").text.begins_with("Dreams: "), "a discovered Reaction's card lists its Dreams")
	probe_card.free()
	_check(not _has_dev_mark(codex, "thunderclap"), "no dev mark")
	pause_menu.close()
	await _end_run(main)

	# --- The Memory Grove's Codex --------------------------------------------------------------
	var grove: Node = load("res://scenes/grove.tscn").instantiate()
	root.add_child(grove)
	await process_frame
	await process_frame
	var grove_codex: CodexPanel = grove.get("codex")
	_check(grove_codex != null, "the Grove has a Codex")
	if grove_codex != null:
		grove_codex.open(&"combos")
		_check(_shown(grove_codex, "thunderclap", "Thunderclap") and _shown(grove_codex, "tempest", "Tempest"),
			"the Grove's Codex shows them too")
	grove.queue_free()
	await process_frame

	# --- A developer run: saved to the account too, with the hidden dev flag ------------------------
	MetaRun.force_all_families = true
	main = await _start_run()
	feedback = root.get_tree().get_first_node_in_group(ComboFeedback.GROUP) as ComboFeedback
	_check(MetaRun.is_dev_run(), "Unlock all families is a dev run")
	feedback.record(&"ignite")
	_check(ComboFeedback.profile_seen().has("ignite"), "a dev-run discovery is saved to the account")
	_check(ComboFeedback.dev_seen().has("ignite") and not ComboFeedback.dev_seen().has("thunderclap"),
		"…with the hidden dev flag (normal finds have none)")
	pause_menu = main.get_node("%PauseMenu")
	pause_menu.open_codex(&"combos")
	await process_frame
	codex = pause_menu.codex
	_check(_shown(codex, "ignite", "Ignite") and not _has_dev_mark(codex, "ignite"), "the Codex shows it, with no mark")
	pause_menu.close()
	await _end_run(main)
	MetaRun.force_all_families = false
	# Found again in a normal run: the flag clears (it now counts), no second discovery card.
	main = await _start_run()
	feedback = root.get_tree().get_first_node_in_group(ComboFeedback.GROUP) as ComboFeedback
	var before: int = feedback.block_new.size()
	feedback.record(&"ignite")
	_check(feedback.block_new.size() == before and not ComboFeedback.dev_seen().has("ignite"),
		"a normal-run find clears the dev flag without a second discovery")
	await _end_run(main)

	# The milestone counts normal-run finds only: every combo found, one of them only in a dev run.
	var profile := HeartwoodMemory.load_data()
	profile[ComboFeedback.SEEN_KEY] = CodexData.combos().map(func(c: Dictionary) -> String: return String(c.id))
	profile[ComboFeedback.DEV_KEY] = ["ignite"]
	profile.milestones.erase(ComboFeedback.MILESTONE)
	HeartwoodMemory.save_data(profile)
	main = await _start_run()
	feedback = root.get_tree().get_first_node_in_group(ComboFeedback.GROUP) as ComboFeedback
	var probe := HeartwoodMemory.load_data()
	feedback._check_milestone(probe)
	_check(not probe.milestones.has(ComboFeedback.MILESTONE), "a dev-flagged combo keeps the milestone locked")
	probe[ComboFeedback.DEV_KEY] = []
	feedback._check_milestone(probe)
	_check(probe.milestones.has(ComboFeedback.MILESTONE), "all found in normal runs: the milestone")
	await _end_run(main)


	# --- The Codex's Dreams: an offered card is seen on the account; the rest stay "???" ------------
	main = await _start_run()
	var dreams: DreamState = main.get_node("%DreamState")
	var all_cards := DreamCodex.all_cards()
	var offered: Array[UpgradeData] = [all_cards[0], all_cards[1]]
	dreams.offer_ready.emit(offered, 1)
	var seen_now := DreamCodex.seen()
	_check(seen_now.has(all_cards[0].id) and seen_now.has(all_cards[1].id) and not seen_now.has(all_cards[2].id),
		"offered cards are seen on the account, others not")
	dreams.card_taken.emit(all_cards[0])
	_check(int(HeartwoodMemory.load_data().get(DreamCodex.TAKEN_KEY, {}).get(all_cards[0].id, 0)) == 1, "taking one counts it")
	pause_menu = main.get_node("%PauseMenu")
	pause_menu.open_codex(&"combos")
	await process_frame
	codex = pause_menu.codex
	var seen_entry: Control = codex.dream_entries.get(all_cards[0].id)
	var unseen_entry: Control = codex.dream_entries.get(all_cards[2].id)
	_check(seen_entry != null and _labels(seen_entry).has(all_cards[0].display_name) and seen_entry.find_child("New", true, false) != null,
		"a seen card shows in full, with New")
	_check(unseen_entry != null and _labels(unseen_entry) == ["???"], "an unseen card is just ???")
	_check(codex._dreams_count.text == "2 / %d Dreams seen" % all_cards.size(), "the Dreams count (" + codex._dreams_count.text + ")")
	pause_menu.close()
	await _end_run(main)
	ResultsScreen.demo_override = -1
	_clean()
	print("codex discoveries test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _start_run() -> Node:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main  # The real game's writes are on (to the temp files above)
	await process_frame
	await process_frame
	return main

func _end_run(main: Node) -> void:
	current_scene = null
	main.queue_free()
	await process_frame
	await process_frame

# The Codex card for `id` is discovered: it shows `name` (locked cards show only "???").
func _shown(codex: CodexPanel, id: String, name: String) -> bool:
	var card: Control = codex._entries.get(id)
	if card == null:
		return false
	for child in card.find_children("*", "Label", true, false):
		if (child as Label).text.begins_with(name):
			return true
	return false

func _has_dev_mark(codex: CodexPanel, id: String) -> bool:
	var card: Control = codex._entries.get(id)
	return card != null and card.get_node_or_null("DevMark") != null

func _clean() -> void:
	for path in [PROFILE_PATH, RUN_PATH]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _labels(node: Node) -> Array:
	return node.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
