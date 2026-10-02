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
	# Undiscovered combos are "???" everywhere (screens_ui.md): the link stands for Conducted.
	_check(Synergies.link_combo(dewdrop, stormcap).get("id") == &"conducted", "Dewdrop + Stormcap is the Conducted combo")
	_check(Synergies.link_text(dewdrop, stormcap, ["nothing"]) == "???" and Synergies.link_text(dewdrop, stormcap, ["conducted"]) == "Soaked → Stormcap",
		"the link reads ??? until Conducted is discovered")
	_check(CodexData.combo_name(CodexData.get_any(&"thunderclap"), ["nothing"]) == "???" and CodexData.combo_name(CodexData.get_any(&"thunderclap"), ["thunderclap"]) == "Thunderclap",
		"CodexData.combo_name: ??? before, the name after")
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
	for side in [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var beside: Vector2 = storm_cell + side  # Right beside it (a random map's next free cell can be far away)
		if map_generator.is_buildable(beside) and not map_generator.get_path_if_blocked(beside).is_empty():
			placer._hover_cell = beside
			break
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
	_check(report.visible == RestReport.auto_show() and report.last_block_text.contains("Stormcap") and report._label.get_parsed_text().contains("Stormcap") and report._label.get_parsed_text().contains("Lightning through Soaked: 2 times"),
		"the rest report shows the top Warden and the combos (%s)" % report._label.get_parsed_text())
	# The Omen paid at this rest, and why it was cut ("Omens with teeth"): the summary from omen_rewarded.
	var omens: OmenDirector = main.get_node("%OmenDirector")
	var hard_bark := OmenData.new()
	hard_bark.display_name = "Hard Bark"
	omens.omen_rewarded.emit(hard_bark, "+18 Dew (75%: 1 leaf lost)")
	report.show_report(2)
	_check(report.last_block_text.contains("Omen · Hard Bark · +18 Dew (75%: 1 leaf lost)"), "the rest report says what the Omen paid, and why")
	report.show_report(3)
	_check(not report.last_block_text.contains("Hard Bark"), "…once (the next rest has no Omen line)")

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
	feedback._chains_seen = ["3", "5", "10"]  # Chain discoveries are checked on their own below
	var tracker := ReactionTracker.find(main)
	tracker.record(&"thunderclap", shade, 1, [storm])
	tracker.record(&"thunderclap", shade, 3, [storm])
	_check(whispers._queue.has(&"chain"), "the first chain ever whispers what a chain is")
	_check(shown == [&"chain"], "whispered fires when it's shown (%s)" % [shown])
	whispers.set_enabled(false)
	_check(feedback._card.visible and feedback.card_text.begins_with("Combo discovered: Set Off"),
		"the first Set Off shows a discovery card (%s)" % feedback.card_text)
	var card_layer := feedback._card.get_canvas_layer_node()
	var card_centre := feedback._card.get_global_rect().get_center()
	var screen_centre := feedback._card.get_viewport_rect().size / 2.0
	_check(card_layer != null and card_layer.layer > (feedback.get_canvas_layer_node() as CanvasLayer).layer
			and card_centre.distance_to(screen_centre) < 2.0,
		"the discovery card sits in the screen centre above the HUD (%s vs %s)" % [card_centre, screen_centre])
	_check(feedback._queue == [&"thunderclap"], "Thunderclap waits its turn (%s)" % [feedback._queue])
	_check(ComboFeedback.discovery_text(&"thunderclap").contains("Soaked + Charged") and ComboFeedback.discovery_text(&"thunderclap").ends_with("Added to the Codex."),
		"the card names the ingredients and says it's in the Codex")
	_check(feedback.block_counts.get(&"thunderclap", 0) == 2 and feedback.block_longest_chain == 3, "Reactions are counted per block")
	feedback.continue_on()
	_check(feedback._card.visible and feedback.card_text.begins_with("Combo discovered: Thunderclap") and game_speed.paused,
		"Continue shows the next discovery, still paused")
	# Peek at the map (screens_ui.md "The discovery card can be minimised"): the card and the dim go, the
	# game stays paused, the world pans; a solid "Return to Thunderclap" pill mid-screen reopens it (pausing cards).
	feedback.peek.set_peeking(true)
	var tab := feedback.peek.back_button()
	_check(not feedback._card.visible and not feedback._dim.visible and tab.visible and tab.text == "Return to Thunderclap"
		and game_speed.paused and feedback.showing(), "Peek hides the card and the dim; still paused, the pill says Return to Thunderclap (%s)" % tab.text)
	_check(tab.anchor_top == 0.5 and tab.anchor_left == 0.5 and tab.offset_top > 0.0, "…in the middle of the screen, a little below centre")
	feedback._queue.append(&"conducted")
	_check(feedback.return_text() == "Return (2)", "several waiting: one pill, Return (2)")
	feedback._queue.pop_back()
	_check((tab.get_parent() as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE, "…the overlay lets the world take the mouse (hover, pan)")
	var camera := main.get_node("GameCameraNode") as Node2D
	var before: Vector2 = camera.target_position
	Input.action_press("move_camera_right")
	for i in 10:
		await process_frame
	Input.action_release("move_camera_right")
	_check(camera.target_position.x > before.x, "…and the camera pans while peeking (%s -> %s)" % [before, camera.target_position])
	_check(not feedback._card.visible and feedback._queue.is_empty(), "…without the next card popping up meanwhile")
	tab.pressed.emit()
	_check(feedback._card.visible and feedback._dim.visible and not tab.visible and game_speed.paused, "the tab reopens the card")
	feedback.peek.set_peeking(true)
	var enter := InputEventAction.new()
	enter.action = &"ui_accept"
	enter.pressed = true
	feedback._unhandled_input(enter)  # Enter (or Space) while peeking continues
	_check(not feedback.peek.peeking and not game_speed.paused, "Enter while peeking continues and resumes")
	# The Thunderclap card was the last: back to it for the checks below.
	feedback._queue.clear()
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
	# Chains are discovered too (screens_ui.md): the first Chain 3 ever pauses with its Reactions in order.
	feedback._chains_seen = []
	for id in ["ignite", "mushrooming"]:
		if not feedback._seen.has(id):
			feedback._seen.append(id)
	tracker.record(&"thunderclap", shade, 1, [storm])
	tracker.record(&"ignite", shade, 2, [storm])
	tracker.record(&"mushrooming", shade, 3, [storm])
	_check(feedback._card.visible and game_speed.paused
		and feedback.card_text.begins_with("Chain discovered: Chain 3\nThunderclap → Ignite → Mushrooming\n" + ComboFeedback.CHAIN_LINE)
		and feedback.card_text.contains("Your longest: Chain 3"),
		"a first Chain 3 is the one chain discovery: its Reactions in order, what a chain does, the longest (%s)" % feedback.card_text)
	_check(ComboFeedback.chain_text(3, [], 7).contains("Your longest: Chain 7"), "…the longest can be past the tier")
	# It stands out in combat: a solid panel, the title in display gold, its Reactions in the icons row,
	# the world dimmed behind it.
	var card_style := feedback._card.get_theme_stylebox("panel") as MoonStyleBox
	var words: Array = feedback._card_icons.get_children().filter(func(c: Node) -> bool: return c is Label).map(func(l: Label) -> String: return l.text)
	_check(card_style != null and card_style.center_alpha >= 0.9 and feedback._card_title.text == "Chain discovered: Chain 3"
		and words == ["Thunderclap", "→", "Ignite", "→", "Mushrooming"] and feedback._dim.visible,
		"the discovery card is solid, titled, shows the chain in its icons row and dims the world (%s)" % [words])
	tracker.record(&"thunderclap", shade, 3, [storm])
	feedback._on_chain(10, Vector2.ZERO, [])
	_check(feedback._queue.is_empty(), "chains are discovered once: no card at Chain 3 again, nor at Chain 10")
	feedback.continue_on()
	_check(not game_speed.paused, "resumed after the chain card")
	# A profile that saw only an old tier (5) before this change isn't shown the chain card again.
	feedback._chains_seen = ["5"]
	feedback._on_chain(4, Vector2.ZERO, [])
	_check(feedback._queue.is_empty() and not feedback._card.visible, "an older profile that saw a tier gets no chain card")
	# Dawnbreak's first Dawnburst is its own discovery: its gem, what it did, Added to the Codex; once.
	ComboFeedback.pause_in_tests = true
	var dawn := DamageLog.Event.new()
	dawn.tag = ComboFeedback.DAWNBREAK_ID
	dawn.enemy = shade
	feedback._on_damage(dawn)
	_check(feedback._card.visible and feedback.card_text == ComboFeedback.DAWNBREAK_TEXT and feedback.card_text.contains("10% of max health")
		and feedback._card_icons.get_child_count() == 1, "Dawnbreak's first Dawnburst shows its discovery card with its gem (%s)" % feedback.card_text)
	feedback.continue_on()
	feedback._on_damage(dawn)
	_check(not feedback._card.visible and feedback._queue.is_empty(), "…once")
	ComboFeedback.pause_in_tests = false
	report.show_report(1)
	_check(report._label.get_parsed_text().contains("Reactions: Thunderclap 4 · Ignite 1 · Mushrooming 1 · longest chain: 3") and report._label.get_parsed_text().contains("New combos: Set Off, Thunderclap") and report._label.get_parsed_text().contains("New chain: Chain 3"),
		"the rest report shows Reactions and new combos (%s)" % report._label.get_parsed_text())
	var profile_after: Dictionary = HeartwoodMemory.load_data()
	_check(profile_after.get("combos_seen", []) == profile_before.get("combos_seen", [])
		and profile_after.get("combo_counts", {}) == profile_before.get("combo_counts", {}), "tests never write discoveries")
	# The Codex: Glossary (search, see-also jumps) and Combos (15, "???" until discovered).
	var codex: CodexPanel = main.get_node("%PauseMenu").codex
	ResultsScreen.demo_override = 0  # The full game: every combo in scope (the scope itself: test_codex_scope)
	codex.open(&"combos")
	_check(codex.visible and codex.tabs.current_tab == 1 and CodexData.combos().filter(CodexData.in_build).all(func(c: Dictionary) -> bool: return codex._entries.has(String(c.id)))
		and CodexData.combos().size() == 14, "the Codex lists every combo in scope, of 14 (Popped retired: spores no longer pop)")
	ResultsScreen.demo_override = -1
	# Locked entries are just "???": no ingredient icons or text (they'd give the answer away).
	var seen_now := ComboFeedback.load_seen()
	for combo in CodexData.combos():
		if not seen_now.has(String(combo.id)) and codex._entries.has(String(combo.id)):
			var locked_card: Control = codex._entries[String(combo.id)]
			var labels := locked_card.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
			_check(locked_card.find_children("*", "StatusIcon", true, false).is_empty() and labels.filter(func(t: String) -> bool: return t != "New from the Grove") == ["???"],
				"a locked combo shows only ??? (%s: %s)" % [combo.id, labels])
			break
	codex._search.text = "dreamlight"
	codex._build_glossary()
	await process_frame
	var term_shown := func(term: String) -> bool: return codex._entries.has(term) and codex._entries[term].visible and codex._entries[term].get_parent().visible
	_check(term_shown.call("Dreamlight") and not term_shown.call("Seeds"), "the glossary search filters terms")
	# Typing only filters (user: "the glossary seems to lag a lot when typing"): no cards made, 120 ms debounce.
	codex.tabs.current_tab = 0
	codex._search.text = ""
	codex._filter_glossary()
	codex._search.text = "e"  # A wide search: most groups' cards made once
	codex._filter_glossary()
	var built: int = codex.glossary_cards_built
	var typing_ms := 0.0
	var query := "dreamlight"
	for i in query.length():
		codex._search.text = query.substr(0, i + 1)
		codex._search.text_changed.emit(codex._search.text)
		var t0 := Time.get_ticks_usec()
		codex._filter_glossary()  # What the debounce runs, timed per keystroke
		typing_ms = maxf(typing_ms, (Time.get_ticks_usec() - t0) / 1000.0)
	_check(codex.glossary_cards_built == built, "typing 10 characters makes no cards (%d → %d)" % [built, codex.glossary_cards_built])
	print("  glossary: %.2f ms per keystroke, %d cards" % [typing_ms, built])
	_check(typing_ms < 2.0, "a keystroke filters in under 2 ms (%.2f ms)" % typing_ms)
	_check(not codex._search_timer.is_stopped() and is_equal_approx(codex._search_timer.wait_time, CodexPanel.SEARCH_DELAY),
		"typing waits for a %d ms pause" % int(CodexPanel.SEARCH_DELAY * 1000))
	codex._search.text = ""
	codex._search_timer.stop()
	codex._filter_glossary()
	_check(term_shown.call("Dreamlight") or term_shown.call("Dew"), "an empty search shows the chosen group again")
	codex.jump("Thunderclap")
	_check(codex.tabs.current_tab == 1, "a see-also to a combo jumps to the Combos tab")
	_check(CodexData.find_term("Tend the forest, and it will remember you.") == "" and CodexData.find_term("Wardens are walls.") == "Warden",
		"in-game text finds whole-word terms only")
	_check(main.get_node("HUD/CodexButton") != null, "a ? button on the HUD opens the Codex")
	# Kinships: a discovery card the first time ever, a Codex section, counts for the rest report.
	if ResourceLoader.exists(CodexData.KINSHIPS_SCRIPT):
		_check(CodexData.kinships().size() == 18 and CodexData.get_any(&"slumber_rot").get("a") == "Driftspore",
			"the 18 Kinships (9 hidden), with their pairs")
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
		# Support and economy lines (SupportLog): the walls line from a Thornwall that lengthens the route,
		# and the results' Dew harvested.
		RestReport.support_text(report, "block")  # Runs without a support Warden on the map
		_check(SupportLog.find(report) != null, "the rest report reaches SupportLog")
		var results = main.get_node("%ResultsScreen")
		main.get_node("%RunState").dew_harvested = 126
		_check(results.support_lines().contains("Dew harvested: 126"), "results: Dew harvested (" + results.support_lines() + ")")
		main.get_node("%RunState").dew_harvested = 0
		feedback._queue.clear()
		feedback._card.visible = false
		whispers.enabled = true
		whispers._seen = []
		whispers._queue.clear()
		whispers._process(0.0)
		_check(whispers._seen.has("kin") or whispers._queue.has(&"kin"), "the Kinship whisper, once two branches of a family are planted")
		whispers._queue.clear()
		whispers.set_enabled(false)
		# No maze juggling: the Unbound whisper, the rest report's "Unbound: N", the info's Restless line.
		var juggled: Node2D = spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
		juggled.set_process(false)
		if spawner.has_signal("nightmare_unbound"):
			whispers.enabled = true
			whispers._seen = []
			whispers._queue.clear()
			report.unbound_block = 0
			spawner.nightmare_unbound.emit(juggled)
			_check(whispers._seen.has("unbound") or whispers._queue.has(&"unbound"), "the first Unbound whispers")
			report.show_report(2)
			_check(report._label.get_parsed_text().contains("Unbound: 1"), "the rest report counts Unbound nightmares")
			whispers._queue.clear()
			whispers.set_enabled(false)
			juggled.restless = 2
			var restless_line: String = load("res://scripts/ui/nightmare_info.gd").restless_text(juggled)
			_check(restless_line == "Restless ×2: +40% speed (Unbound at 3)", "the nightmare info's Restless line (" + restless_line + ")")
			# Omens that change a live nightmare (Sleepless, Heavy Rain) show on its info.
			var info_script = load("res://scripts/ui/nightmare_info.gd")
			_check(info_script.omen_text(juggled) == "", "no Omen line for a plain nightmare")
			juggled.statuses.immune.append(&"drowsy")
			juggled.modifiers["always_status"] = &"damp"
			var omen_line: String = info_script.omen_text(juggled)
			_check(omen_line.begins_with("Omen") and omen_line.contains("immune to Drowsy") and omen_line.contains("always Soaked"),
				"the Omen's extra traits (" + omen_line + ")")
		juggled.queue_free()
	# Crowned Reactions: their own discovery card, a hidden entry until found, outside the 15.
	_check(CodexData.crowned().size() == 8 and CodexData.combos().size() == 14, "8 Crowned Reactions, apart from the 14 combos")
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
