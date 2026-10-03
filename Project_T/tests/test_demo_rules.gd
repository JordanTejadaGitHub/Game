extends SceneTree

# The Spire merge (2026-10-02, Balancing Discussion): the demo keeps the rules from before it, the full game gets
# the Spire rules. Demo: the old curve (ramp from drift 9, act 2 from x1.7, x3.3 at 37, no act 4 extra), the full
# Dew pots, no block finales, no branch expansion, no Heartwood's Gifts. Temp profile.

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

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_demo_rules_%d.json" % OS.get_process_id()
	var demo := await _director(1)
	_check(demo.act1_ramp_from == 9 and is_equal_approx(demo.act2_start_health_multiplier, 1.7)
		and is_equal_approx(demo.act2_steep_value, 3.3) and is_equal_approx(demo.act4_health_multiplier, 1.0),
		"demo: the old health curve")
	_check(demo.dew_pot_acts[1] == Vector2(115, 135) and is_equal_approx(demo.dew_pot_bosses[1], 270.0) and is_equal_approx(demo.dew_pot_bosses[2], 320.0),
		"demo: the full Dew pots")
	_check(demo.get_block_finale_elites(10) == -1 and demo.get_block_finale_elites(15) == -1, "demo: no block finales")
	_check(not DreamState.branch_expansion_on(), "demo: no branch expansion")
	var gifts := HeartwoodGifts.find(demo)
	if gifts != null:
		gifts._on_rest_started(5, true, 0, false)  # The act 1 boss rest
		_check(not gifts.is_offering(), "demo: no Heartwood's Gifts at the act break")
	demo.owner.queue_free()
	await process_frame

	var full := await _director(0)
	_check(full.act1_ramp_from == 3 and is_equal_approx(full.act4_health_multiplier, 1.2) and is_equal_approx(full.dew_pot_bosses[1], 243.0),
		"full game: the Spire curve and pots")
	_check(full.get_block_finale_elites(10) >= 0, "full game: block finales")
	_check(DreamState.branch_expansion_on(), "full game: branch expansion")
	full.owner.queue_free()
	await process_frame
	ResultsScreen.demo_override = -1
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("PASS" if failures == 0 else "FAILURES: %d" % failures)
	quit(failures)
