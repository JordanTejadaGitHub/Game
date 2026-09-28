extends SceneTree

# Headless test for Codex discoveries (screens_ui.md "The Codex", "Saved in the profile"):
# - a normal run's discoveries (a base combo and a Crowned Reaction) show in the Codex right after,
#   mid-run from the pause menu and from the Memory Grove;
# - a developer run's (Unlock all families) are kept for the session only: shown with a "dev" mark,
#   the header says they aren't saved, nothing reaches the profile, and they don't pause twice.
# Uses temp profile / run-save files; never the player's.
#   godot --headless --path . --script res://tests/test_codex_discoveries.gd --fixed-fps 60

const PROFILE_PATH := "user://test_codex_discoveries_profile.json"
const RUN_PATH := "user://test_codex_discoveries_run.json"

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
	_check(not _has_dev_mark(codex, "thunderclap") and not codex._dev_note.visible, "no dev mark or note in a normal run")
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

	# --- A developer run: session only, "dev" mark, nothing saved ---------------------------------
	MetaRun.force_all_families = true
	main = await _start_run()
	feedback = root.get_tree().get_first_node_in_group(ComboFeedback.GROUP) as ComboFeedback
	_check(MetaRun.is_dev_run(), "Unlock all families is a dev run")
	feedback.record(&"ignite")
	_check(not ComboFeedback.profile_seen().has("ignite"), "a dev discovery never reaches the profile")
	_check(ComboFeedback.session_seen.has("ignite") and ComboFeedback.load_seen().has("ignite"), "…but is kept for the session")
	pause_menu = main.get_node("%PauseMenu")
	pause_menu.open_codex(&"combos")
	await process_frame
	codex = pause_menu.codex
	_check(_shown(codex, "ignite", "Ignite") and _has_dev_mark(codex, "ignite"), "the Codex shows it with a dev mark")
	_check(not _has_dev_mark(codex, "thunderclap"), "saved discoveries have no dev mark")
	_check(codex._dev_note.visible and codex._dev_note.text == "Developer run: discoveries aren't saved", "the header note")
	pause_menu.close()
	await _end_run(main)
	# A later run the same session: already discovered (it doesn't pause again).
	main = await _start_run()
	feedback = root.get_tree().get_first_node_in_group(ComboFeedback.GROUP) as ComboFeedback
	var before: int = feedback.block_new.size()
	feedback.record(&"ignite")
	_check(feedback.block_new.size() == before, "a dev discovery doesn't pause twice in a session")
	await _end_run(main)
	MetaRun.force_all_families = false

	# The milestone never counts dev discoveries.
	_check(not HeartwoodMemory.load_data().milestones.has(ComboFeedback.MILESTONE), "no milestone from dev finds")

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
