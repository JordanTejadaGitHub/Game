extends SceneTree

# Lessons (onboarding.md "Lessons", LessonCard): each trigger shows its paused card once, with live numbers; the Hints
# setting turns them off; at most one per drift (the rest queue); never over a choice screen; the pause is restored.
# Temp profile; the per-drift limit is off for the trigger checks.
#   godot --headless --path . --script res://tests/test_lessons.gd --fixed-fps 60

var failures := 0
var shown: Array = []

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok: ", what)
	else:
		failures += 1
		push_error("FAIL: " + what)

func _initialize() -> void:
	_run.call_deferred()

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _free_cells(map: Node, count: int) -> Array:
	var out: Array = []
	for y in Tower.MAP_GRID.size.y:
		for x in Tower.MAP_GRID.size.x:
			var cell := Vector2(x, y)
			if map.is_buildable(cell) and map.can_block(cell):
				out.append(cell)
				if out.size() >= count * 4:
					return out
	return out

# Lets the card show, notes it, closes it.
func _take(lessons: LessonCard) -> StringName:
	await _frames(2)
	if not lessons.visible:
		return &""
	var id := lessons.shown_id
	lessons.close()
	await _frames(1)
	return id

func _run() -> void:
	var pid := OS.get_process_id()
	HeartwoodMemory.file_path = "user://test_lessons_%d.json" % pid
	RunSaver.file_path = "user://test_lessons_run_%d.json" % pid
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 4242
	root.add_child(main)
	await _frames(3)
	var lessons := main.get_node("HUD/LessonCard") as LessonCard
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var dreams: DreamState = main.get_node("%DreamState")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var speed: GameSpeed = main.get_node("%GameSpeed")
	var map := main.get_node("%MapGenerator")
	_check(lessons != null, "the HUD makes the Lesson card")
	if lessons == null:
		quit(1)
		return
	lessons.enabled = true
	lessons.one_per_drift = false
	lessons.lesson_shown.connect(func(id: StringName) -> void: shown.append(id))
	dreams.unlock_everything = true
	main.get_node("%RunState").dew = 100000

	# Planting: directly, twice in build mode, copies at 2 and 5.
	var cells := _free_cells(map, 6)
	placer.set_build_mode(true)
	placer.select_tower(load("res://resource/tower/sporeling.tres"))
	var planted := 0
	var ids: Array = []
	for cell in cells:
		if planted >= 5:
			break
		if placer._try_build(cell):
			planted += 1
			var id := await _take(lessons)
			while id != &"":
				ids.append(id)
				id = await _take(lessons)
	_check(planted == 5, "planted 5 Sporelings (%d)" % planted)
	for want in [&"planted_directly", &"build_mode", &"copies", &"copies_five"]:
		_check(ids.has(want), "Lesson %s showed (%s)" % [want, ids])
	_check(ids.count(&"planted_directly") == 1, "each Lesson once (%s)" % [ids])

	# The card pauses the game and gives the pause back.
	lessons.lesson(&"probe", &"dew", "Probe", "Probe text.")
	speed.set_paused(false)
	await _frames(2)
	_check(lessons.visible and lessons.shown_id == &"probe" and speed.paused, "a Lesson pauses the game")
	lessons.close()
	_check(not speed.paused, "…and closing it gives the pause back")

	# One per drift: the second waits for the next drift.
	lessons.one_per_drift = true
	lessons._last_drift = -1  # A fresh drift: nothing shown in it yet
	lessons.lesson(&"probe_a", &"dew", "A", "a")
	lessons.lesson(&"probe_b", &"dew", "B", "b")
	_check(await _take(lessons) == &"probe_a", "one per drift: the first shows")
	_check(await _take(lessons) == &"", "…the second waits")
	lessons._last_drift = -1  # As if the next drift began
	_check(await _take(lessons) == &"probe_b", "…and shows in the next drift")

	# Never over a screen: a Dream offer open keeps it waiting.
	lessons.one_per_drift = false
	var dream_screen := main.get_node("HUD/DreamScreen") as Control
	dream_screen.visible = true
	lessons.lesson(&"probe_c", &"dew", "C", "c")
	_check(await _take(lessons) == &"", "never over a choice screen")
	dream_screen.visible = false
	_check(await _take(lessons) == &"probe_c", "…shows once the screen closes")

	# Hints off: no Lessons.
	lessons.enabled = false
	lessons.queue.clear()
	lessons.lesson(&"probe_d", &"dew", "D", "d")
	_check(await _take(lessons) == &"", "Hints off: no Lessons")
	lessons.enabled = true

	# Selling mid-drift, live refund numbers.
	director.start_next_drift()
	await _frames(2)
	var tower := placer.tower_container.get_child(0) as Tower
	seller.sell(tower.cell)
	await _frames(2)
	var sell_text := lessons._body.text
	var sold := await _take(lessons)
	_check(sold == &"sell_mid_drift" and sell_text.contains("%d%%" % roundi(seller.drift_refund * 100.0)),
		"selling during a drift: the refund Lesson with live numbers (%s: %s)" % [sold, sell_text])

	# Restless and Dreamlight.
	main.get_node("%EnemyContainer").nightmare_restless.emit(Node2D.new(), 1)
	_check(await _take(lessons) == &"restless", "the first Restless nightmare")
	dreams.add_dreamlight(1, &"test")
	_check(await _take(lessons) == &"dreamlight", "the first Dreamlight")

	_check(not HeartwoodMemory.load_data().has(LessonCard.SEEN_KEY), "tests never write the profile")

	main.queue_free()
	await process_frame
	for path in [HeartwoodMemory.file_path, RunSaver.file_path]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("lessons test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)
