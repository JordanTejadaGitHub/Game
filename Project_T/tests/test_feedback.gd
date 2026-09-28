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
	_check(Synergies.link(dewdrop, stormcap) == "Soaked → Stormcap", "Dewdrop and Stormcap combo through Soaked (%s)" % Synergies.link(dewdrop, stormcap))
	_check(Synergies.link(stormcap, dewdrop) == "Soaked → Stormcap", "the link works both ways")
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
	_check(report.visible and report._label.get_parsed_text().contains("Stormcap") and report._label.get_parsed_text().contains("Lightning through Soaked: 2 times"),
		"the rest report shows the top Warden and the combos (%s)" % report._label.get_parsed_text())

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
	ComboFeedback.pause_in_tests = true  # A discovery pauses the game (screens_ui.md)
	var game_speed: GameSpeed = main.get_node("%GameSpeed")
	game_speed.set_paused(false)
	ComboFeedback.report(&"set_off", main, shade)  # A synergy reported from game code, on a nightmare
	_check(game_speed.paused and feedback._buttons.visible and is_instance_valid(feedback._ring),
		"a first discovery pauses the game, with Continue and the nightmare ringed")
	var whispers = main.get_node("%Whispers")
	whispers.enabled = true
	whispers._seen = []
	whispers.set_process(false)
	whispers._queue.clear()
	var shown := []
	whispers.whispered.connect(func(id: StringName) -> void: shown.append(id))
	var tracker := ReactionTracker.find(main)
	tracker.record(&"thunderclap", shade, 1, [storm])
	tracker.record(&"thunderclap", shade, 3, [storm])
	_check(whispers._queue.has(&"chain"), "the first chain ever whispers what a chain is")
	_check(shown == [&"chain"], "whispered fires when it's shown (%s)" % [shown])
	whispers.set_enabled(false)
	_check(feedback._card.visible and feedback._card_label.text.begins_with("Combo discovered: Set Off"),
		"the first Set Off shows a discovery card (%s)" % feedback._card_label.text)
	_check(feedback._queue == [&"thunderclap"], "Thunderclap waits its turn (%s)" % [feedback._queue])
	_check(ComboFeedback.discovery_text(&"thunderclap").contains("Soaked + Charged") and ComboFeedback.discovery_text(&"thunderclap").ends_with("Added to the Codex."),
		"the card names the ingredients and says it's in the Codex")
	_check(feedback.block_counts.get(&"thunderclap", 0) == 2 and feedback.block_longest_chain == 3, "Reactions are counted per block")
	feedback.continue_on()
	_check(feedback._card.visible and feedback._card_label.text.begins_with("Combo discovered: Thunderclap") and game_speed.paused,
		"Continue shows the next discovery, still paused")
	feedback.continue_on()
	_check(not feedback._card.visible and not game_speed.paused and not is_instance_valid(feedback._ring),
		"the last Continue resumes at the previous speed")
	# While the pause menu is open, a discovery waits; it shows once the menu closes.
	var pause_menu = main.get_node("%PauseMenu")
	pause_menu.open()
	feedback._seen.erase("caught")
	ComboFeedback.report(&"caught", main)
	_check(not feedback._card.visible and feedback._queue == [&"caught"], "a discovery waits behind the pause menu")
	pause_menu.close()
	await process_frame
	_check(feedback._card.visible and game_speed.paused, "and pauses once the menu closes")
	feedback.continue_on()
	_check(not game_speed.paused, "resumed")
	ComboFeedback.pause_in_tests = false
	report.show_report(1)
	_check(report._label.get_parsed_text().contains("Reactions: Thunderclap 2 · longest chain: 3") and report._label.get_parsed_text().contains("New combos: Set Off, Thunderclap"),
		"the rest report shows Reactions and new combos (%s)" % report._label.get_parsed_text())
	var profile_after: Dictionary = HeartwoodMemory.load_data()
	_check(profile_after.get("combos_seen", []) == profile_before.get("combos_seen", [])
		and profile_after.get("combo_counts", {}) == profile_before.get("combo_counts", {}), "tests never write discoveries")
	# The Codex: Glossary (search, see-also jumps) and Combos (15, "???" until discovered).
	var codex: CodexPanel = main.get_node("%PauseMenu").codex
	codex.open(&"combos")
	_check(codex.visible and codex.tabs.current_tab == 1 and CodexData.combos().all(func(c: Dictionary) -> bool: return codex._entries.has(String(c.id)))
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
	# Kinships: a discovery card the first time ever, a Codex section, counts for the rest report.
	if ResourceLoader.exists(CodexData.KINSHIPS_SCRIPT):
		_check(CodexData.kinships().size() == 9 and CodexData.get_any(&"slumber_rot").get("a") == "Driftspore",
			"the 9 Kinships, with their pairs")
		_check(ComboFeedback.discovery_text(&"slumber_rot").begins_with("Kinship discovered: Slumber Rot\nDriftspore + Bloomcap"),
			"a Kinship discovery card names the pair (%s)" % ComboFeedback.discovery_text(&"slumber_rot"))
		feedback._seen.erase("slumber_rot")
		feedback._on_kinship(&"slumber_rot", null, null)
		_check(feedback.kin_formed_block == 1 and feedback._queue.has(&"slumber_rot") or feedback._card_id == &"slumber_rot",
			"a first bond is discovered and counted")
		_check(RestReport.kinship_text(2, 84, ["spore"]) == "\nKinships formed: 2 · Harmony strikes: 84\nThe Sporeling line is whole.",
			"the rest report's Kinship lines")
		feedback._queue.clear()
		feedback._card.visible = false
		# Playtest fix: a line per Kinship formed, the once-per-run hint, the once-ever whisper.
		var kin_seller: TowerSeller = main.get_node("%TowerSeller")
		placer.select_tower(load("res://resource/tower/driftspore.tres"))
		var drift_cell := _free_cell(map_generator, 10)
		placer._try_build(drift_cell)
		placer.select_tower(load("res://resource/tower/bloomcap.tres"))
		var bloom_cell := _free_cell(map_generator, 16)
		placer._try_build(bloom_cell)
		placer.set_build_mode(false)
		var drift_tower := kin_seller.get_tower_at(drift_cell)
		var bloom_tower := kin_seller.get_tower_at(bloom_cell)
		_check(RestReport.two_branch_family([drift_tower, bloom_tower]) == "spore", "two spore branches planted")
		report._kin_hint_shown = false
		var kin_count := Kinships.count_on_map(report)
		report.show_report(2)
		if kin_count == 0:
			_check(report._label.get_parsed_text().contains("No Kinships yet: two branches of one family within 2 cells"),
				"the no-Kinship hint at the first rest with two branches")
			report.show_report(2)
			_check(not report._label.get_parsed_text().contains("No Kinships yet"), "…once per run")
		feedback.kin_names_block.clear()
		feedback._on_kinship(&"slumber_rot", drift_tower, bloom_tower)
		report.show_report(2)
		_check(report._label.get_parsed_text().contains("Kinship: Slumber Rot (Driftspore + Bloomcap)"),
			"a rest report line per Kinship formed (%s)" % report._label.get_parsed_text())
		feedback._queue.clear()
		feedback._card.visible = false
		whispers.enabled = true
		whispers._seen = []
		whispers._queue.clear()
		whispers._process(0.0)
		_check(whispers._seen.has("kin") or whispers._queue.has(&"kin"), "the Kinship whisper, once two branches of a family are planted")
		whispers._queue.clear()
		whispers.set_enabled(false)
	# Crowned Reactions: their own discovery card, a hidden entry until found, outside the 15.
	_check(CodexData.crowned().size() == 8 and CodexData.combos().size() == 15, "8 Crowned Reactions, apart from the 15 combos")
	_check(ComboFeedback.discovery_text(&"tempest").begins_with("Crowned Reaction discovered: Tempest")
		and ComboFeedback.discovery_text(&"tempest").contains("Thunderclap + Poisoned"), "a Crowned discovery card names its recipe")
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
