extends SceneTree

var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func _frames(n := 3) -> void:
	for i in n:
		await process_frame
func _run() -> void:
	root.size = Vector2i(1280, 720)
	HeartwoodMemory.file_path = "user://test_initial_lessons_%d.json" % OS.get_process_id()
	RunSaver.file_path = "user://test_initial_run_%d.json" % OS.get_process_id()
	var main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 4242
	main.get_node("%RunSaver").autosave = false
	root.add_child(main)
	current_scene = main
	await _frames()
	var lessons = main.get_node("HUD/LessonCard")
	var speed = main.get_node("%GameSpeed")
	if not lessons.has_method("start_intro"):
		_check(false, "new players automatically get opening lesson panels")
	else:
		_check(lessons.visible and lessons.shown_id == &"intro_heartwood" and speed.paused and paused, "first opening panel appears and pauses the actual game")
		for id in [&"intro_maze", &"intro_dew"]:
			lessons.close()
			_check(lessons.visible and lessons.shown_id == id and speed.paused, "Next advances to %s without unpausing" % id)
		lessons.close()
		_check(not lessons.visible and not speed.paused, "finishing opening panels restores running state")
		lessons.start_intro()
		await _frames()
		_check(not lessons.visible, "opening panels do not repeat on the same profile")
		_check(HeartwoodMemory.load_data().get("lessons_seen", []).has("intro_dew"), "opening completion is saved to the temporary profile")
		lessons.one_per_drift = false
		var choice := main.get_node("HUD/DreamScreen") as Control
		choice.visible = true
		lessons.discovery(&"dream")
		await _frames()
		_check(not lessons.visible, "a discovery lesson waits behind a choice screen")
		choice.visible = false
		await _frames()
		_check(lessons.visible and lessons.shown_id == &"discover_dream" and speed.paused, "a discovery lesson opens and pauses after the choice closes")
		lessons.close()
		lessons.discovery(&"grow")
		await _frames()
		_check(lessons.visible and lessons.shown_id == &"discover_grow" and speed.paused, "a discovered growth lesson appears and pauses")
		speed.set_paused(false)
		_check(speed.paused and paused, "a lesson cannot be unpaused underneath its panel")
		lessons.close()
		speed.set_paused(true)
		lessons.discovery(&"nurture")
		await _frames()
		_check(lessons.visible and lessons.shown_id == &"discover_nurture", "a discovered nurture lesson appears")
		lessons.close()
		_check(speed.paused, "closing a discovery lesson preserves a prior manual pause")
		lessons.discovery(&"spored")
		await _frames()
		_check(lessons.visible and lessons.shown_id == &"discover_spored" and speed.paused, "discovering a status shows its paused definition")
		var panel := lessons.find_child("Card", true, false) as Control
		_check(panel.get_global_rect().position.x >= 0 and panel.get_global_rect().end.x <= root.get_visible_rect().size.x and panel.get_global_rect().position.y >= 0 and panel.get_global_rect().end.y <= root.get_visible_rect().size.y, "lesson panel fits the viewport: %s in %s" % [panel.get_global_rect(), root.get_visible_rect()])
		lessons.close()
		speed.set_paused(false)
		lessons.discovery(&"static")
		await _frames()
		var menu = main.get_node("HUD/PauseMenu")
		speed.set_paused(true)
		menu.open()
		var settings := HeartwoodMemory.get_settings()
		settings.whispers = false
		HeartwoodMemory.apply_settings(settings)
		await _frames()
		_check(not lessons.visible and lessons.queue.is_empty(), "Hints off clears pending discovery panels")
		_check(speed.paused, "turning Hints off keeps the open pause menu paused")
		menu.close()
		await _frames()
		_check(not speed.paused, "closing the menu releases the lesson-owned pause")
		lessons.set_enabled(true)
		speed.set_paused(false)
		lessons.seen.clear()
		lessons.start_intro()
		await _frames()
		lessons.skip_intro()
		_check(not lessons.visible and not speed.paused, "Skip tutorial dismisses all opening panels and restores pause")
		lessons.start_intro()
		await _frames()
		_check(not lessons.visible, "skipped opening panels stay skipped")
		lessons.set_enabled(false)
		speed.set_paused(false)
		for screen_name in RestScreens.SCREENS:
			var screen := main.get_node_or_null("HUD/" + screen_name) as CanvasItem
			if screen != null and screen != lessons:
				screen.visible = false
		var seen_before: int = lessons.seen.size()
		lessons.replay_guides()
		_check(lessons.visible and speed.paused and lessons._demo.visible and lessons._demo.topic == &"nurture", "explicit replay opens the animated nurture guide even with Hints off")
		lessons.close()
		_check(lessons.visible and speed.paused and lessons._demo.topic == &"maze", "replay advances to animated maze guide without unpausing")
		lessons.close()
		_check(lessons.visible and speed.paused and lessons._demo.topic == &"catch", "replay advances to animated catcher guide")
		lessons.close()
		_check(not lessons.visible and not speed.paused and not lessons.enabled and lessons.seen.size() == seen_before, "finishing replay: visible=%s paused=%s enabled=%s seen=%s/%s pending=%s" % [lessons.visible, speed.paused, lessons.enabled, lessons.seen.size(), seen_before, lessons._resume_pending])
	main.queue_free()
	await _frames()
	# Production wiring: start with Hints off, enable them, then a real flyer reaches the goal.
	var saved_settings := HeartwoodMemory.get_settings()
	saved_settings.whispers = false
	HeartwoodMemory.save_settings(saved_settings)
	var second = load("res://scenes/main.tscn").instantiate()
	second.get_node("%MapGenerator").map_seed = 4242
	second.get_node("%RunSaver").autosave = false
	root.add_child(second)
	current_scene = second
	await _frames()
	saved_settings.whispers = true
	HeartwoodMemory.apply_settings(saved_settings)
	var spawner = second.get_node("%EnemyContainer")
	spawner.spawn_enemy(load("res://resource/enemy/dandelion_seed.tres"))
	var flyer = spawner.get_child(spawner.get_child_count() - 1)
	flyer.set_process(false)
	spawner.enemy_reached_goal.emit(flyer)
	# The Lesson card watches the field itself now (the flyer whisper that used to set it off is gone, user 2026-10-12).
	var discovered = second.get_node("HUD/LessonCard")
	_check(discovered.shown_id == &"discover_flyer" or discovered.queue.any(func(q: Array) -> bool: return q[0] == &"discover_flyer"),
		"enabling Hints after startup still detects a flying leak")
	var whispers = second.get_node("%Whispers")
	_check(not whispers._queue.has(&"flyer") and not whispers.TEXT.has(&"flyer"), "…and no teaching whisper says it")
	while discovered.visible and discovered.shown_id != &"discover_flyer":
		discovered.close()  # Any Lesson queued ahead of it
		await _frames()
	await _frames()
	_check(discovered.visible and discovered.shown_id == &"discover_flyer" and paused, "the real flyer discovery opens a paused panel")
	second.queue_free()
	await _frames()
	for path in [HeartwoodMemory.file_path, RunSaver.file_path]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("initial lessons: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)