extends SceneTree

# Spire experiment (spire_difficulty.md): Phase 3 rest choices (Rest / Clear / Forage, Tend, Dream; after the Dream and
# the Omen; holds Start; saved and recorded) and Phase 2's finale line (DriftPanel before it, the rest report after).

var failures := 0

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok: ", what)
	else:
		failures += 1
		push_error("FAIL: " + what)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_spire_rest_%d.json" % OS.get_process_id()
	RunSaver.file_path = "user://test_spire_rest_run_%d.json" % OS.get_process_id()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var director: DriftDirector = main.get_node("%DriftDirector")
	var run_state: RunState = main.get_node("%RunState")
	var dreams: DreamState = main.get_node("%DreamState")
	var screen := main.get_node_or_null("HUD/RestChoiceScreen") as RestChoiceScreen
	_check(screen != null, "the HUD makes the rest-choice screen")
	if screen == null:
		quit(1)
		return

	# A rest: the Dream first, then the choice; Start waits for it.
	director.drifts_started = 5
	director.resting = true
	director.rest_started.emit(1, false, 30, false)
	await process_frame
	await process_frame
	_check(screen.waiting and not screen.visible and director.pending_choice() == &"dream", "the Dream comes first; the choice waits behind it")
	for frame in 10:
		if dreams.is_offering() or dreams.has_pending_offer():
			dreams.skip()
		await process_frame
	_check(screen.visible and director.pending_choice() == &"rest" and not director.can_start_next_drift(),
		"then the rest choice opens and holds Start (pending %s)" % director.pending_choice())
	var panel = main.get_node("HUD/DriftPanel")
	_check(panel.PENDING_TEXT[&"rest"] == "Choose how to rest", "the Start button names it")
	var saver: RunSaver = main.get_node("%RunSaver")
	_check(not saver.can_save_now(), "no save before the choice")
	# Full leaves: Rest becomes Clear (enough obstacles) or Forage.
	_check(screen.offer[0] == &"clear" and screen.offer.has(&"tend") and screen.offer.has(&"dream"), "full leaves: Clear, Tend, Dream (%s)" % [screen.offer])
	var obstacles: Dictionary = main.get_node("%MapGenerator").obstacles
	main.get_node("%MapGenerator").obstacles = {}
	_check(screen.make_offer()[0] == &"forage" and screen.forage_dew() == 20, "few obstacles left: Forage, +20 Dew in act 1")
	main.get_node("%MapGenerator").obstacles = obstacles
	run_state.leaves = run_state.max_leaves - 2
	_check(screen.make_offer()[0] == &"rest", "a leaf missing: Rest")
	_check(screen.dream_available() == dreams.has_method("add_next_offer_cards"), "Dream works once DreamState can add a card")
	var free_before := run_state.free_nurtures
	screen.choose(&"tend")
	await process_frame
	_check(run_state.free_nurtures == free_before + 1 and not screen.visible and director.pending_choice() == &"",
		"Tend: one free Nurture rank; Start is free again")
	_check(run_state.rest_choices.size() == 1 and run_state.rest_choices[0].choice == "tend" and int(run_state.rest_choices[0].block) == 1,
		"recorded for the run save and history (%s)" % [run_state.rest_choices])
	_check(saver.can_save_now(), "saving is fine after the choice")
	# The next rest: Rest regrows a leaf.
	director.rest_started.emit(2, false, 40, false)
	for frame in 10:
		if dreams.is_offering() or dreams.has_pending_offer():
			dreams.skip()
		await process_frame
	var leaves := run_state.leaves
	screen.choose(&"rest")
	_check(run_state.leaves == leaves + 1 and run_state.rest_choices.size() == 2, "Rest: one leaf back")
	director.rest_started.emit(2, false, 40, false)
	_check(not screen.waiting, "one choice per rest (the same rest again doesn't ask twice)")

	# Phase 2: the finale line before and after.
	director.drifts_started = 5
	director.resting = true
	_check(panel.coming_finale(director) == 10, "resting before drifts 6–10: the finale is drift 10")
	panel._update_finale()
	_check(panel.finale_label.visible and panel.finale_label.text == "Finale (drift 10): clear it clean for a Rare dream",
		"the DriftPanel says it (%s)" % panel.finale_label.text)
	var report = main.get_node("HUD/RestReport")
	report._finale_drift = 10
	report._finale_lost_before = run_state.leaves_lost
	if not main.get_node("%DreamState").has_method("finale_result"):
		_check(report.finale_line(2) == "\nFinale cleared clean: a Rare dream waits", "a clean finale: the Rare dream waits")
		run_state.lose_leaves(2)
		_check(report.finale_line(2) == "\nFinale cost 2 leaves", "a costly one says so (%s)" % report.finale_line(2).strip_edges())
	_check(report.finale_line(1) == "", "a block without a finale: no line")

	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RunSaver.file_path))
	print("PASS" if failures == 0 else "FAILURES: %d" % failures)
	quit(failures)
