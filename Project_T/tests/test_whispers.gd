extends SceneTree

# The Heartwood's voice after "Whisper hints removed" (onboarding.md, user 2026-10-12: "remove the whisper hints,
# they're redundant with the tutorial popups"): the teaching whispers no longer fire; the story beats (the run's first
# line, a boss coming / dispelled / its toll, the first leaf lost in a run), the rule-breaker warning (every time) and
# the refusal toast's text stay. The line's look and timing are as before. Temp profile.

# Teaching whispers that are gone: asking for one does nothing.
const REMOVED: Array[StringName] = [&"plant", &"keep_placing", &"first_cleanse", &"walls", &"flow", &"speed", &"rest",
	&"save", &"cage", &"grow", &"grow_more", &"kin", &"unbound", &"dead_wood", &"tend", &"chain", &"flyer", &"sell",
	&"damp", &"drowsy", &"spored", &"marked", &"static", &"held", &"omen", &"dreamlight", &"nurture", &"let_pass"]
const KEPT: Array[StringName] = [&"start", &"again", &"leaf", &"boss", &"after_boss", &"boss_toll", &"rule_breaker"]

var failures := 0

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok: ", what)
	else:
		failures += 1
		push_error("FAIL: " + what)

func _initialize() -> void:
	_run.call_deferred()

# Every line shown or waiting.
func _fired(whispers: Node) -> Array:
	var ids: Array = whispers.shown.duplicate()
	for id in whispers._queue:
		if not ids.has(id):
			ids.append(id)
	return ids

# Ends whatever shows or waits, so the next line can be seen on its own.
func _clear(whispers: Node) -> void:
	whispers._queue.clear()
	whispers._finish()

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
	_check(_fired(whispers).has(&"start"), "run start: the story's first line")
	var texts: Array = whispers.TEXT.keys()
	_check(KEPT.all(func(id: StringName) -> bool: return texts.has(id)) and texts.size() == KEPT.size(),
		"only the story beats and the warning have a line (%s)" % [texts])
	for id in REMOVED:
		whispers.whisper(id)
	_check(REMOVED.all(func(id: StringName) -> bool: return not _fired(whispers).has(id)), "the teaching whispers are gone: asking for one does nothing")
	# Hints off switches Lessons, not these lines.
	whispers.set_enabled(false)
	_check(whispers.enabled and whispers.is_processing(), "the Hints setting doesn't switch the Heartwood's story lines and warnings")

	# Readable, in the Heartwood's place: the italic whisper at 26 px with a dark outline and shadow over a faint
	# feathered mist (no box), top centre; on screen in real time; hover / tap holds, a second tap dismisses.
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
		and mist != null and mist.frame == &"" and mist.edge_alpha == 0.0 and mist.center_alpha >= 0.7,
		"26 px whisper italic, outlined, over a feathered mist (no frame; its core darkened to %.2f by UI council round 7)" % (mist.center_alpha if mist != null else -1.0))
	var hint_rect: Rect2 = whispers.get_global_rect()
	_check(hint_rect.position.y < 300.0 and absf(hint_rect.get_center().x - 640.0) < 2.0, "top centre, as before (%s)" % hint_rect)
	_check(is_equal_approx(whispers.show_time("Short."), 7.0) and is_equal_approx(whispers.show_time("x".repeat(100)), 10.0),
		"on screen 7 s at least, 3 s + 0.07 s a character for long lines")
	# Real time: at 3× speed a 7 s line is still up after 4 real seconds (12 game seconds).
	var dossier: BossDossier = main.get_node("HUD/BossDossier")
	var dossier_processing := dossier.is_processing()
	dossier.set_process(false)  # Its startup auto-open is a rest screen: lines wait behind those
	dossier.visible = false
	_clear(whispers)
	Engine.time_scale = 3.0
	whispers.whisper(&"boss")
	for frame in 60 * 4:
		await process_frame
	_check(whispers.modulate.a > 0.9 and whispers.shown.has(&"boss"), "3× speed doesn't shorten it (still showing after 4 real seconds)")
	Engine.time_scale = 1.0
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	whispers.term = ""
	whispers._gui_input(click)
	_check(whispers.held, "a tap holds the line")
	whispers._gui_input(click)
	_check(not whispers.held and whispers._queue.is_empty(), "a second tap dismisses it")

	# Behind a choice screen: a line waits, then shows once it closes.
	_clear(whispers)
	director.awaiting_family_pick = true
	whispers.whisper(&"after_boss")
	for frame in 3:
		await process_frame
	_check(not whispers.shown.has(&"after_boss") and whispers.modulate.a < 0.1, "a line waits while a choice screen is open")
	director.awaiting_family_pick = false
	for frame in 3:
		await process_frame
	_check(whispers.shown.has(&"after_boss") and whispers.visible, "…and shows once it closes")

	# A line already on screen when the first family pick opens (user 2026-10-13: "still see whispers when clicking first
	# family"): hidden at once, nothing new shown while the pick is open, back once it closes. The same under a Lesson card.
	_clear(whispers)
	whispers._run_seen.erase(&"boss")
	whispers.whisper(&"boss")
	for frame in 3:
		await process_frame
	_check(whispers.shown.has(&"boss") and whispers.visible and whispers._showing == &"boss", "a story line is on screen")
	var shown_before: int = whispers.shown.size()
	director.awaiting_family_pick = true
	whispers.whisper(&"rule_breaker")
	for frame in 3:
		await process_frame
	_check(not whispers.visible and whispers.shown.size() == shown_before, "the family pick opens: the line is hidden, and no other is shown behind it")
	director.awaiting_family_pick = false
	for frame in 3:
		await process_frame
	_check(whispers.visible, "…and it comes back once the pick closes")
	var lesson_card := main.get_node("HUD/LessonCard") as Control
	lesson_card.visible = true
	for frame in 3:
		await process_frame
	_check(not whispers.visible, "a Lesson card up: the line is hidden under it too")
	lesson_card.visible = false
	for frame in 3:
		await process_frame
	_check(whispers.visible, "…and back when the card closes")
	_check(not whispers.TEXT.values().any(func(line: String) -> bool: return line.contains("old friend") or line.contains("the long way")),
		"the old first-pick lines are gone")
	# Story beats, once a run each. The first leaf lost:
	_clear(whispers)
	run_state.invulnerable = false
	run_state.lose_leaves(1)
	_check(_fired(whispers).has(&"leaf"), "the first leaf lost in a run: the Heartwood says so")
	_clear(whispers)
	run_state.lose_leaves(1)
	_check(not whispers._queue.has(&"leaf") and whispers.shown.count(&"leaf") == 1, "…once a run, not for every leaf")
	# No boss brings a family since 2026-10-22: a later family pick never whispers "after_boss" (its own screen says it).
	director.family_pick_requested.emit(&"second")
	_check(not whispers._queue.has(&"after_boss") and whispers.shown.count(&"after_boss") == 1, "a family pick whispers nothing more")
	# A boss's toll at the Heartwood.
	var stag: Node2D = spawner.spawn_enemy(load("res://resource/enemy/old_stag.tres"), 1.0, {}, false)
	await process_frame
	spawner.enemy_reached_goal.emit(stag)
	_check(_fired(whispers).has(&"boss_toll"), "a boss reaching the Heartwood: its toll")
	# A flyer reaching the goal teaches nothing here any more (the flyer Lesson does).
	var flyer: Node2D = spawner.spawn_enemy(load("res://resource/enemy/crow.tres"), 1.0, {}, false)
	await process_frame
	spawner.enemy_reached_goal.emit(flyer)
	_check(not _fired(whispers).has(&"flyer"), "a flyer's leak whispers nothing")

	# The rule-breaker warning: every time one is coming, never "once per profile" (Phantoms come at drift 31).
	_clear(whispers)
	whispers.shown.clear()
	director.drifts_started = 30
	director.resting = true
	if not RuleBreakers.coming(director).is_empty():
		director.rest_started.emit(6, false, 0, false)
		_check(_fired(whispers).has(&"rule_breaker"), "a rule-breaker block coming: the warning line")
		_clear(whispers)
		director.rest_started.emit(6, false, 0, false)
		_check(whispers._queue.has(&"rule_breaker") or whispers.shown.count(&"rule_breaker") >= 2, "…again the next time: a warning, not a one-off hint")
		_check(not whispers._seen.has("rule_breaker"), "the warning isn't written to the profile's once-only list")
	else:
		_check(false, "drift 31 brings a rule-breaker (the fixture this check needs)")
	# The rest before a boss block.
	_clear(whispers)
	whispers._run_seen.erase(&"boss")
	director.drifts_started = 20
	director.rest_started.emit(4, false, 0, false)
	_check(_fired(whispers).has(&"boss"), "the rest before a boss block: something old has found the dream")
	# The blocked-placement refusal is a toast (its trigger needs a hovered cell: test_ui / play).
	_check(whispers.REFUSAL.ends_with("A dream can bend, but never close.") and whispers.REFUSAL.begins_with("Leave nightmares a way") and main.get_node("%TowerPlacer").build_rejected.get_connections().any(
		func(c: Dictionary) -> bool: return (c.callable as Callable).get_object() == whispers),
		"the refusal line is wired to build_rejected, as a toast")
	dossier.set_process(dossier_processing)
	main.queue_free()
	await process_frame

	# "I'm dreaming again": the second run on a profile. An old profile's whispers_seen (with removed ids) loads as it is.
	var memory := HeartwoodMemory.load_data()
	memory.runs_played = 1
	memory["whispers_seen"] = ["start", "plant", "walls", "damp"]
	HeartwoodMemory.save_data(memory)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var second = main.get_node("%Whispers")
	_check(_fired(second).has(&"again") and not _fired(second).has(&"start"), "a second run: \"I'm dreaming again.\", and the first line stays once per profile")
	_check(second._seen.has("plant") and second._seen.has("damp"), "an old profile's seen list is kept as it is")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("PASS" if failures == 0 else "FAILURES: %d" % failures)
	quit(failures)
