extends SceneTree

# Hints (the Heartwood's whispers) audit (story chat 2026-10-01, user: "fix any Heartwood whispers that got lost"): a
# fresh profile plays drifts 1–6 for real, then each remaining trigger is fired the way the game fires it, and every
# line in Whispers.TEXT must have fired (or be listed in ELSEWHERE, covered by another test). Temp profile.

# Lines whose trigger another test drives (they poll the mouse / need a whole setup): id -> where.
const ELSEWHERE := {&"cage": "test_ui (hover a placement that would close the path)",
	&"dead_wood": "test_ui (hover an obstacle while clearing is locked)", &"tend": "test_ui (clearing opens)",
	&"grow": "test_grow_hints (the first rest a Warden can grow)", &"grow_more": "test_grow_hints (drift 15)"}

var failures := 0

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok: ", what)
	else:
		failures += 1
		push_error("FAIL: " + what)

func _initialize() -> void:
	_run.call_deferred()

func _fired(whispers: Node) -> Array:
	var ids: Array = []
	for id in whispers._seen:
		ids.append(StringName(id))
	for id in whispers._queue:
		if not ids.has(id):
			ids.append(id)
	return ids

func _free_cell(map: Node, from_x: int) -> Vector2:
	for y in range(2, 16):
		for x in range(from_x, 21):
			var cell := Vector2(x, y)
			if map.is_buildable(cell) and not map.get_path_if_blocked(cell).is_empty():
				return cell
	return Vector2(-1, -1)

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_whispers_%d.json" % OS.get_process_id()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var whispers = main.get_node("%Whispers")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var run_state: RunState = main.get_node("%RunState")
	var spawner = main.get_node("%EnemyContainer")
	var family = main.get_node("%FamilyPickScreen")
	var map: Node = main.get_node("%MapGenerator")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	_check(whispers.enabled, "a fresh profile has hints on")
	_check(_fired(whispers).has(&"start") and _fired(whispers).has(&"plant"), "run start: start, plant")

	# Readable, in the Heartwood's place (user: "go back to how it was before, but more readable, and lasting a bit longer
	# no matter the speed"): the italic whisper at 26 px with a dark outline and shadow over a faint feathered mist (no
	# box), top centre; on screen in real time; hover / tap holds, a second tap dismisses; one at a time.
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS  # A real 1280×720 layout (as test_ui)
	root.content_scale_size = UiStyle.LAYOUT_MIN
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(1280, 720)
	for frame in 2:
		await process_frame
	whispers._place()
	for frame in 2:
		await process_frame
	var mist := whispers.get_theme_stylebox("normal") as MoonStyleBox
	_check(whispers.get_theme_font_size("normal_font_size") == 26 and whispers.get_theme_font("normal_font") == UiStyle.whisper_font()
		and whispers.get_theme_constant("outline_size") >= 6 and whispers.get_theme_color("default_color") == UiStyle.GOLD
		and mist != null and mist.edge_alpha == 0.0 and is_equal_approx(mist.center_alpha, 0.7),
		"26 px whisper italic, outlined, over a faint feathered mist (no box)")
	var hint_rect: Rect2 = whispers.get_global_rect()
	_check(hint_rect.position.y < 300.0 and absf(hint_rect.get_center().x - 640.0) < 2.0, "top centre, as before (%s)" % hint_rect)
	_check(is_equal_approx(whispers.show_time("Short."), 7.0) and is_equal_approx(whispers.show_time("x".repeat(100)), 10.0),
		"on screen 7 s at least, 3 s + 0.07 s a character for long lines")
	# Real time: at 3× speed a 7 s hint is still up after 4 real seconds (12 game seconds).
	for id in whispers._queue:  # (Queued ones did fire: kept for the audit below)
		if not whispers._seen.has(String(id)):
			whispers._seen.append(String(id))
	whispers._queue.clear()
	whispers._seen.erase("speed")
	Engine.time_scale = 3.0
	whispers.whisper(&"speed")
	for frame in 60 * 4:
		await process_frame
	_check(whispers.modulate.a > 0.9, "3× speed doesn't shorten it (still showing after 4 real seconds)")
	Engine.time_scale = 1.0
	var showing := String(whispers._queue[0]) if not whispers._queue.is_empty() else ""
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	whispers.term = ""
	whispers._gui_input(click)
	_check(whispers.held, "a tap holds the hint")
	whispers._gui_input(click)
	_check(not whispers.held and (whispers._queue.is_empty() or String(whispers._queue[0]) != showing),
		"a second tap dismisses it, and the next queued one follows (one at a time)")
	# Behind a choice screen (user screenshot: a hint across the family cards): it waits, then shows once it closes.
	for id in whispers._queue:
		if not whispers._seen.has(String(id)):
			whispers._seen.append(String(id))
	whispers._queue.clear()
	whispers._finish()
	whispers._seen.erase("flow")
	var choice_director: DriftDirector = main.get_node("%DriftDirector")
	choice_director.awaiting_family_pick = true
	whispers.whisper(&"flow")
	for frame in 3:
		await process_frame
	_check(not whispers._seen.has("flow") and whispers.modulate.a < 0.1, "a hint waits while a choice screen is open")
	choice_director.awaiting_family_pick = false
	for frame in 3:
		await process_frame
	_check(whispers._seen.has("flow") and whispers.visible, "…and shows once it closes")

	# Drifts 1–6 for real (leaves can't fall: the block ends when the field is clear).
	run_state.invulnerable = true
	run_state.dew = 500
	placer.select_tower(load("res://resource/tower/sprout.tres"))
	placer._try_build(_free_cell(map, 8))
	placer.set_build_mode(false)
	director.set_auto_drift(true)
	Engine.time_scale = 8.0
	director.start_next_drift()
	var rested := [false]  # (A lambda captures a local by value: an array carries the change out)
	var walls_checked := [false]
	director.rest_started.connect(func(_b: int, _boss: bool, _bonus: int, _p: bool) -> void: rested[0] = true, CONNECT_ONE_SHOT)
	for frame in 60 * 400:
		if director.awaiting_family_pick and not family.offer.is_empty():
			if not walls_checked[0]:
				walls_checked[0] = true
				_check(not _fired(whispers).has(&"walls"), "\"Wardens are walls\" waits while the first pick is open")
			family.choose(family.offer[0])
			director.start_next_drift()  # After the pick the run waits for Start (test_run)
		if rested[0]:
			break
		await process_frame
	_check(rested[0], "the first block reaches its rest (drift %d)" % director.drifts_started)
	await process_frame
	var fired := _fired(whispers)
	for id in [&"walls", &"flow", &"speed", &"rest", &"save"]:
		_check(fired.has(id), "drifts 1–5 fire \"%s\"" % id)
	var dreams: DreamState = main.get_node("%DreamState")
	for frame in 30:  # The rest's Dream offer (built deferred) holds Start, as in play: let it pass
		if dreams.is_offering() or dreams.has_pending_offer():
			dreams.skip()
		if director.pending_choice() == &"":
			break
		await process_frame
	director.start_next_drift()
	for frame in 60:
		await process_frame
	_check(director.drifts_started >= 6, "drift 6 starts (%d)" % director.drifts_started)
	Engine.time_scale = 1.0

	# The rest, fired as the game fires them. Each status on its own nightmare (together they'd set off Reactions).
	var shade: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	var enemy: Node2D = null
	for status in EnemyStatuses.ALL:
		enemy = spawner.spawn_enemy(shade, 1.0, {}, false)
		await process_frame
		enemy.apply_status(status, 1, 5.0, 1.0, 5)
		for frame in 2:  # Hints poll the field for statuses
			await process_frame
	enemy.unkillable = false
	enemy.dispel()  # The first dispel
	for frame in 3:
		await process_frame
	run_state.invulnerable = false
	run_state.lose_leaves(1)
	var crow: EnemyData = load("res://resource/enemy/crow.tres")
	var flyer: Node2D = spawner.spawn_enemy(crow, 1.0, {}, false)
	await process_frame
	spawner.enemy_reached_goal.emit(flyer)
	spawner.nightmare_unbound.emit(flyer)
	var tracker := ReactionTracker.new()
	main.add_child(tracker)
	await process_frame
	tracker.chain_reached.emit(3, Vector2.ZERO, [])
	var built := seller.get_tower_at(_free_cell(map, 8))
	for tower in main.get_node("%TowerContainer").get_children():
		if tower is Tower:
			seller.tower_sold.emit(tower, 0)
			break
	run_state.dew = 2000  # (Drifts 1–6 spent some: the two branches always get planted)
	placer.select_tower(load("res://resource/tower/driftspore.tres"))
	placer._try_build(_free_cell(map, 10))
	placer.select_tower(load("res://resource/tower/bloomcap.tres"))
	placer._try_build(_free_cell(map, 16))
	placer.set_build_mode(false)
	director.drifts_started = 20  # The rest before the boss block
	director.rest_started.emit(4, false, 0, false)
	director.family_pick_requested.emit(&"boss")
	# The approved lines (2026-10-02): a rule-breaker warning (Phantoms come at drift 31), the first Omen offer, a boss at
	# the Heartwood, the first rank (Dreamlight and Let it pass came with drifts 1–5 for real).
	director.drifts_started = 30
	director.resting = true
	director.rest_started.emit(6, false, 0, false)
	var no_omens: Array[OmenData] = []
	main.get_node("%OmenDirector").offer_ready.emit(no_omens, 7)
	var stag: Node2D = spawner.spawn_enemy(load("res://resource/enemy/old_stag.tres"), 1.0, {}, false)
	await process_frame
	spawner.enemy_reached_goal.emit(stag)
	for tower in main.get_node("%TowerContainer").get_children():
		if tower is Tower:
			tower.nurtured.emit(tower)
			break
	for frame in 3:
		await process_frame
	fired = _fired(whispers)
	var missing: Array = []
	for id in whispers.TEXT:
		if not fired.has(id) and not ELSEWHERE.has(id) and id != &"again":
			missing.append(id)
	_check(missing.is_empty(), "every hint fires (never fired: %s)" % [missing])
	main.queue_free()
	await process_frame

	# "The Heartwood dreams again": the second run on a profile.
	var memory := HeartwoodMemory.load_data()
	memory.runs_played = 1
	HeartwoodMemory.save_data(memory)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	_check(_fired(main.get_node("%Whispers")).has(&"again"), "a second run: \"The Heartwood dreams again.\"")
	print("  covered elsewhere: %s" % [ELSEWHERE.keys()])
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("PASS" if failures == 0 else "FAILURES: %d" % failures)
	quit(failures)
