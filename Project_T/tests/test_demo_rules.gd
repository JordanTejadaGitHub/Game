extends SceneTree

# The demo plays by the current rules and ends at drift 50 (demo_scope.md "Decisions 2026-10-06", e5ce233d; DEMO_RULES
# retired): the same health curve, Dew pots and block finales as the full game, Heartwood's Gifts at the drift 25
# break, the Mire Hag (great_toad) as the last drift. Only the content is limited. The full game keeps its 100.
# Temp profile.

var failures := 0

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok: ", what)
	else:
		failures += 1
		push_error("FAIL: " + what)

func _initialize() -> void:
	_run.call_deferred()

func _director(demo: int) -> DriftDirector:
	ResultsScreen.demo_override = demo
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	return main.get_node("%DriftDirector")

func _boss_of(director: DriftDirector, number: int) -> String:
	for group in director.drifts[number - 1].groups:
		for entry in group.entries:
			if entry.enemy != null and entry.enemy.is_boss:
				return entry.enemy.resource_path.get_file().get_basename()
	return ""

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_demo_rules_%d.json" % OS.get_process_id()
	var full := await _director(0)
	var curve := [full.act1_ramp_from, full.act1_health_multiplier, full.act2_start_health_multiplier,
		full.act2_steep_value, full.extra_nightmares_from, full.dew_pot_bosses[1], full.get_block_finale_elites(10)]
	_check(full.get_total_drifts() == 100 and _boss_of(full, 100) != "", "full game: 100 drifts, a boss at 100")
	full.owner.queue_free()
	await process_frame

	var demo := await _director(1)
	_check(demo.get_total_drifts() == DriftDirector.DEMO_LAST_DRIFT and DriftDirector.DEMO_LAST_DRIFT == 50,
		"demo: 50 drifts (%d)" % demo.get_total_drifts())
	_check(_boss_of(demo, 50) == "great_toad" and _boss_of(demo, 25) == "old_stag",
		"demo: the Hollow Stag at 25, the Mire Hag last (%s, %s)" % [_boss_of(demo, 25), _boss_of(demo, 50)])
	var demo_curve := [demo.act1_ramp_from, demo.act1_health_multiplier, demo.act2_start_health_multiplier,
		demo.act2_steep_value, demo.extra_nightmares_from, demo.dew_pot_bosses[1], demo.get_block_finale_elites(10)]
	_check(demo_curve == curve, "demo: the full game's curve, Dew pots and block finales (%s vs %s)" % [demo_curve, curve])
	var gifts := HeartwoodGifts.find(demo)
	if gifts != null:
		demo.drifts_started = 25
		gifts._on_rest_started(5, true, 0, false)  # The act 1 boss rest
		_check(gifts.is_offering(), "demo: Heartwood's Gifts at the drift 25 break")
	demo.owner.queue_free()
	await process_frame
	ResultsScreen.demo_override = -1
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("PASS" if failures == 0 else "FAILURES: %d" % failures)
	quit(failures)
