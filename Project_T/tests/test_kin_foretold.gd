extends SceneTree

# Headless test for Kin Foretold (Grove node, meta_design.md b585bec5): a family pick also shows, below the cards, the
# families the next boss pick will offer; they're drawn ahead (never a card on screen) and really come; the last pick of
# the run (drift 75) foretells nothing; without the node, nothing shows. Never touches the player's saves.
#   godot --headless --path . --script res://tests/test_kin_foretold.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	ResultsScreen.demo_override = 0
	MetaRun.force_all_families = true  # Every family in the picks: enough to foretell
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var screen = main.get_node("%FamilyPickScreen")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var line: Label = screen.find_child("Foretold", true, false)

	# Without the node: nothing below the cards.
	director.drifts_started = 1
	screen.show_pick(&"first")
	_check(line != null and not line.visible and screen.foretold.is_empty(), "without Kin Foretold nothing is foretold")
	screen.choose(screen.offer[0])

	# With it: the first pick shows drift 25's families, none of them on screen now.
	screen.get_script().force_kin_foretold = true
	director.drifts_started = 1
	screen.show_pick(&"first")
	var on_screen: Array = screen._ids(screen.offer)
	var promised: Array = screen.foretold.duplicate()
	_check(line.visible and line.text.begins_with("Next pick (drift 25): ") and not promised.is_empty()
		and promised.all(func(id: String) -> bool: return not on_screen.has(id)),
		"the first pick foretells drift 25's families, none of the cards shown (%s / %s)" % [line.text, on_screen])
	screen.choose(screen.offer[0])

	# Drift 25: exactly those families come, and drift 50's are foretold.
	director.drifts_started = 25
	screen.show_pick(&"boss")
	var came: Array = screen.offer.map(func(d) -> String: return d.get_id())
	_check(came.slice(0, promised.size()) == promised, "the boss pick offers the foretold families (%s vs %s)" % [came, promised])
	_check(line.visible and line.text.begins_with("Next pick (drift 50): "), "…and foretells drift 50's (%s)" % line.text)
	screen.choose(screen.offer[0])

	# Drift 75 is the run's last pick: nothing left to foretell.
	director.drifts_started = 75
	screen.foretold = []
	screen.show_pick(&"boss")
	_check(not line.visible, "the last pick foretells nothing")
	if not screen.offer.is_empty():
		screen.choose(screen.offer[0])

	screen.get_script().force_kin_foretold = false
	MetaRun.force_all_families = false
	ResultsScreen.demo_override = -1
	main.queue_free()
	await process_frame
	print("kin foretold test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
