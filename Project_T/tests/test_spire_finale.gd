extends SceneTree

# Spire experiment (spire_difficulty.md Phase 2): the block finale's line on the DriftPanel before and during it, and
# the rest report's "cleared clean" / "cost N leaves" after it. (Phase 3's per-rest choices were replaced by Heartwood's
# Gifts, heartwood_gifts.md.)

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
	HeartwoodMemory.file_path = "user://test_spire_finale_%d.json" % OS.get_process_id()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var director: DriftDirector = main.get_node("%DriftDirector")
	var run_state: RunState = main.get_node("%RunState")
	var panel = main.get_node("HUD/DriftPanel")
	director.drifts_started = 5
	director.resting = true
	_check(panel.coming_finale(director) == 10, "resting before drifts 6–10: the finale is drift 10")
	panel._update_finale()
	_check(panel.finale_label.visible and panel.finale_label.text == "Finale (drift 10): clear it clean for a Rare dream",
		"the DriftPanel says it (%s)" % panel.finale_label.text)
	director.drifts_started = 0
	_check(panel.coming_finale(director) == 0, "block 1 has no finale")
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
	print("PASS" if failures == 0 else "FAILURES: %d" % failures)
	quit(failures)
