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

	# Combos: the first firing ever shows a discovery card (queued when several), counts go to the rest
	# report ("Reactions: …", "New combos: …"), the Codex lists all 15, and a test writes nothing.
	var feedback: ComboFeedback = main.get_node("%ComboFeedback")
	feedback._seen.clear()  # As if never discovered
	feedback._queue.clear()
	feedback.block_new.clear()
	feedback._card.visible = false
	var profile_before: Dictionary = HeartwoodMemory.load_data()
	ComboFeedback.report(&"set_off", main)  # A synergy reported from game code
	var whispers = main.get_node("%Whispers")
	whispers.enabled = true
	whispers._seen = []
	whispers.set_process(false)
	var tracker := ReactionTracker.find(main)
	tracker.record(&"thunderclap", shade, 1, [storm])
	tracker.record(&"thunderclap", shade, 3, [storm])
	_check(whispers._queue.has(&"chain"), "the first chain ever whispers what a chain is")
	whispers.set_enabled(false)
	_check(feedback._card.visible and feedback._card_label.text.begins_with("Combo discovered: Set Off"),
		"the first Set Off shows a discovery card (%s)" % feedback._card_label.text)
	_check(feedback._queue == [&"thunderclap"], "Thunderclap waits its turn (%s)" % [feedback._queue])
	_check(ComboFeedback.discovery_text(&"thunderclap").contains("Damp + Static") and ComboFeedback.discovery_text(&"thunderclap").ends_with("Added to the Codex."),
		"the card names the ingredients and says it's in the Codex")
	_check(feedback.block_counts.get(&"thunderclap", 0) == 2 and feedback.block_longest_chain == 3, "Reactions are counted per block")
	report.show_report(1)
	_check(report._label.text.contains("Reactions: Thunderclap 2 · longest chain: 3") and report._label.text.contains("New combos: Set Off, Thunderclap"),
		"the rest report shows Reactions and new combos (%s)" % report._label.text)
	var profile_after: Dictionary = HeartwoodMemory.load_data()
	_check(profile_after.get("combos_seen", []) == profile_before.get("combos_seen", [])
		and profile_after.get("combo_counts", {}) == profile_before.get("combo_counts", {}), "tests never write discoveries")
	# The Codex: Glossary (search, see-also jumps) and Combos (15, "???" until discovered).
	var codex: CodexPanel = main.get_node("%PauseMenu").codex
	codex.open(&"combos")
	_check(codex.visible and codex.tabs.current_tab == 1 and codex._combos.get_child_count() == CodexData.combos().size()
		and CodexData.combos().size() == 15, "the Codex lists all 15 combos")
	# Locked entries are just "???": no ingredient icons or text (they'd give the answer away).
	var seen_now := ComboFeedback.load_seen()
	for combo in CodexData.combos():
		if not seen_now.has(String(combo.id)):
			var locked_card: Control = codex._entries[String(combo.id)]
			var labels := locked_card.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
			_check(locked_card.find_children("*", "StatusIcon", true, false).is_empty() and labels == ["???"],
				"a locked combo shows only ??? (%s: %s)" % [combo.id, labels])
			break
	codex._search.text = "dreamlight"
	codex._build_glossary()
	await process_frame
	_check(codex._entries.has("Dreamlight") and not codex._entries.has("Seeds"), "the glossary search filters terms")
	codex.jump("Thunderclap")
	_check(codex.tabs.current_tab == 1, "a see-also to a combo jumps to the Combos tab")
	_check(CodexData.find_term("Tend the forest, and it will remember you.") == "" and CodexData.find_term("Wardens are walls.") == "Warden",
		"in-game text finds whole-word terms only")
	_check(main.get_node("HUD/CodexButton") != null, "a ? button on the HUD opens the Codex")
	# Crowned Reactions: their own discovery card, a hidden entry until found, outside the 15.
	_check(CodexData.crowned().size() == 8 and CodexData.combos().size() == 15, "8 Crowned Reactions, apart from the 15 combos")
	_check(ComboFeedback.discovery_text(&"tempest").begins_with("Crowned Reaction discovered: Tempest")
		and ComboFeedback.discovery_text(&"tempest").contains("Thunderclap + Spored"), "a Crowned discovery card names its recipe")
	var was_demo = ProjectSettings.get_setting("game/demo", false)
	ProjectSettings.set_setting("game/demo", false)
	codex.open(&"combos")
	_check(codex._entries.has("tempest"), "the full game's Codex lists the Crowned Reactions")
	ProjectSettings.set_setting("game/demo", true)
	codex.open(&"combos")
	await process_frame
	_check(not codex._entries.has("tempest") or not is_instance_valid(codex._entries["tempest"]) or codex._entries["tempest"].is_queued_for_deletion(),
		"the demo's Codex leaves them out")
	ProjectSettings.set_setting("game/demo", was_demo)

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
