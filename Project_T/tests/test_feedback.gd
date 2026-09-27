extends SceneTree

# Headless test for the combat feedback (screens_ui.md "Combat feedback: seeing what works"): synergy
# links, placement links, combo callouts and their throttle, combo counts, the rest report and the
# Warden panel's damage / combo lines.
#   godot --headless --path . --script res://tests/test_feedback.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var dewdrop: TowerData = load("res://resource/tower/dewdrop.tres")
	var stormcap: TowerData = load("res://resource/tower/stormcap.tres")
	var sprout: TowerData = load("res://resource/tower/sprout.tres")
	_check(Synergies.link(dewdrop, stormcap) == "Damp → Stormcap", "Dewdrop and Stormcap combo through Damp (%s)" % Synergies.link(dewdrop, stormcap))
	_check(Synergies.link(stormcap, dewdrop) == "Damp → Stormcap", "the link works both ways")
	_check(Synergies.link(sprout, stormcap) == "", "a Sprout doesn't combo with Stormcap")

	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var map_generator = main.get_node("%MapGenerator")
	var dreams: DreamState = main.get_node("%DreamState")
	var log := DamageLog.instance
	_check(log != null, "the damage log exists")
	dreams.unlock_everything = true
	main.get_node("%RunState").dew = 1000

	# Build a Stormcap, then hover a Dewdrop ghost next to it: a vine links them.
	placer.tower_data = stormcap
	var storm_cell := _free_cell(map_generator, 4)
	placer._try_build(storm_cell)
	var storm: Tower = main.get_node("%TowerSeller").get_tower_at(storm_cell)
	placer.select_tower(dewdrop)
	placer.set_process(false)  # Its hover follows the mouse each frame; hold it on our cell
	placer._hover_cell = _free_cell(map_generator, 5)
	placer._refresh_hover()
	var links = main.get_node("%PlacementLinks")
	await process_frame
	_check(not links._links.is_empty() and links._links[0][0] == storm, "the Dewdrop ghost links to the Stormcap")
	placer.set_build_mode(false)
	placer.set_process(true)

	# A combo event: a callout pops once, the throttle holds a second one back, counts go up.
	var spawner = main.get_node("%EnemyContainer")
	var shade: Node2D = spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	shade.set_process(false)
	var callouts = main.get_node("%CombatCallouts")
	for i in 2:
		var event := DamageLog.Event.new()
		event.source = storm
		event.enemy = shade
		event.amount = 12.0
		event.combos.assign([&"conducted"])
		event.combo_amount = 12.0
		log.report(event)
	_check(callouts._alive.size() == 1 and callouts._alive[0][1] == "Conducted!", "one Conducted! callout (throttled)")
	_check(log.combo_counts_block.get(&"conducted", 0) == 2 and log.combo_counts_run.get(&"conducted", 0) == 2, "combos are counted")
	var top := log.get_top_towers("block", 3)
	_check(not top.is_empty() and top[0].tower == storm and roundi(top[0].amount) == 24, "Stormcap tops the block report")

	# Rest report card
	var report: RestReport = main.get_node("%RestReport")
	report.show_report(1)
	_check(report.visible and report._label.text.contains("Stormcap") and report._label.text.contains("Lightning through Damp: 2 times"),
		"the rest report shows the top Warden and the combos (%s)" % report._label.text)

	# Warden panel lines
	var seller: TowerSeller = main.get_node("%TowerSeller")
	seller.select(storm)
	await process_frame
	var panel = main.get_node("HUD/WardenPanel")
	panel._refresh()
	_check(panel._body.text.contains("This run: 24 damage") and panel._body.text.contains("from combos 100%"),
		"the Warden panel shows run damage and the combo share (%s)" % panel._body.text)

	# Reactions: the first one ever shows a discovery card, counts go to the rest report, the Codex
	# lists them all, and nothing is written to the profile from a test.
	var feedback: ReactionFeedback = main.get_node("%ReactionFeedback")
	feedback._seen.clear()  # As if never discovered
	var profile_before: Array = HeartwoodMemory.load_data().get("reactions_seen", []).duplicate()
	var tracker := ReactionTracker.find(main)
	tracker.record(&"thunderclap", shade, 1, [storm])
	tracker.record(&"thunderclap", shade, 3, [storm])
	_check(feedback._card.visible and feedback._card_label.text.begins_with("Reaction discovered: Thunderclap")
		and feedback._card_label.text.contains("Damp + Static"), "the first Thunderclap shows a discovery card (%s)" % feedback._card_label.text)
	_check(feedback.block_counts.get(&"thunderclap", 0) == 2 and feedback.block_longest_chain == 3, "Reactions are counted per block")
	report.show_report(1)
	_check(report._label.text.contains("Reactions: Thunderclap 2 · longest chain ×3"), "the rest report shows Reactions (%s)" % report._label.text)
	_check(HeartwoodMemory.load_data().get("reactions_seen", []) == profile_before, "tests never write discoveries")
	var codex: CodexPanel = main.get_node("%PauseMenu").codex
	codex.open()
	_check(codex.visible and codex._list.get_child_count() == Reactions.all().size() + 1, "the Codex lists every Reaction")

	main.queue_free()
	await process_frame
	print("feedback test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _free_cell(map_generator, from_index: int) -> Vector2:
	var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	for i in range(from_index, path.size()):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = path[i] + offset
			if not path.has(cell) and map_generator.can_block(cell):
				return cell
	return Vector2(-1, -1)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
