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

	# Planting: directly, twice in build mode, the 2nd copy; then Sprouts until their price steps up.
	var per_step := placer.sprout_per_step()
	var cells := _free_cells(map, 6 + per_step)
	placer.set_build_mode(true)
	var planted := 0
	var ids: Array = []
	for pick in [["sporeling", 3], ["sprout", per_step]]:
		placer.select_tower(load("res://resource/tower/%s.tres" % pick[0]))
		var done := 0
		while done < pick[1] and not cells.is_empty():
			if placer._try_build(cells.pop_front()):
				done += 1
				planted += 1
				var id := await _take(lessons)
				while id != &"":
					ids.append(id)
					id = await _take(lessons)
	_check(planted == 3 + per_step, "planted 3 Sporelings and %d Sprouts (%d)" % [per_step, planted])
	for want in [&"planted_directly", &"build_mode", &"copies", &"sprouts_cost_more"]:
		_check(ids.has(want), "Lesson %s showed (%s)" % [want, ids])
	_check(ids.count(&"planted_directly") == 1 and not ids.has(&"copies_five"), "each Lesson once, no 'five copies' (%s)" % [ids])

	# The user: "first time learning about the Sprouts costing more, a window should appear". At a rest where a Lesson
	# already showed, a Sprout past the step (a drag can skip the exact multiple) still opens the card and pauses.
	lessons.seen.erase("sprouts_cost_more")
	lessons.one_per_drift = true
	lessons._last_drift = director.drifts_started  # A Lesson already showed this rest
	speed.set_paused(false)
	placer.select_tower(load("res://resource/tower/sprout.tres"))
	var extra := _free_cells(map, 2)
	var sprouted := false
	for cell in extra:
		if not sprouted and placer._try_build(cell):
			sprouted = true
	await _frames(2)
	_check(director.is_resting() and lessons.visible and lessons.shown_id == &"sprouts_cost_more" and speed.paused,
		"a Sprout past the step at a rest: the Sprouts Lesson card opens and pauses (%s)" % lessons.shown_id)
	lessons.close()
	lessons.one_per_drift = false

	# The card pauses the game and gives the pause back.
	lessons.lesson(&"probe", &"dew", "Probe", "Probe text.")
	speed.set_paused(false)
	await _frames(2)
	_check(lessons.visible and lessons.shown_id == &"probe" and speed.paused, "a Lesson pauses the game")
	lessons.close()
	_check(not speed.paused, "…and closing it gives the pause back")

	# At a rest Lessons follow one another; during a drift, one per drift (the second waits for the next).
	lessons.one_per_drift = true
	lessons._last_drift = -1
	lessons.lesson(&"probe_r1", &"dew", "R1", "r")
	lessons.lesson(&"probe_r2", &"dew", "R2", "r")
	_check(await _take(lessons) == &"probe_r1" and await _take(lessons) == &"probe_r2", "at a rest: one after another")
	director.resting = false  # As if a drift were on (no nightmares needed)
	lessons._last_drift = -1  # A fresh drift: nothing shown in it yet
	lessons.lesson(&"probe_a", &"dew", "A", "a")
	lessons.lesson(&"probe_b", &"dew", "B", "b")
	_check(await _take(lessons) == &"probe_a", "one per drift: the first shows")
	_check(await _take(lessons) == &"", "…the second waits")
	lessons._last_drift = -1  # As if the next drift began
	_check(await _take(lessons) == &"probe_b", "…and shows in the next drift")
	director.resting = true

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

	# The Lessons that took over from the teaching whispers (onboarding.md "Whisper hints removed", user 2026-10-12).
	lessons.queue.clear()
	lessons.close()
	for id in ["speed_pause", "rests", "discover_damp"]:
		lessons.seen.erase(id)
	# Speed and pause: the first time a drift has run longer than 20 s.
	director.resting = false
	speed.set_paused(false)
	lessons._drift_watched = director.drifts_started
	lessons._drift_time = LessonCard.SPEED_LESSON_AFTER - 1.0
	lessons._watch_field(0.016)
	_check(not lessons.queue.any(func(q: Array) -> bool: return q[0] == &"speed_pause"), "under 20 s of a drift: no Speed and pause Lesson yet")
	lessons._drift_time = LessonCard.SPEED_LESSON_AFTER + 1.0
	lessons._watch_field(0.016)
	await _frames(2)
	_check(lessons.visible and lessons.shown_id == &"speed_pause" and speed.paused and lessons._body.text.contains("build while paused"),
		"a drift running longer than 20 s: the Speed and pause Lesson opens and pauses (%s)" % lessons.shown_id)
	lessons.close()
	await _frames(1)
	# Rests: the first rest (its own handler called alone: the real signal would also open the rest's screens).
	director.resting = true
	var rest_hooks: Array = director.rest_started.get_connections().filter(func(c: Dictionary) -> bool: return (c.callable as Callable).get_object() == lessons)
	_check(rest_hooks.size() == 1, "the Rests Lesson listens for the first rest")
	for hook in rest_hooks:
		(hook.callable as Callable).call(1, false, 0, false)
	speed.set_paused(false)
	await _frames(2)
	_check(lessons.visible and lessons.shown_id == &"rests" and speed.paused and lessons._body.text.contains("forest rests"),
		"the first rest: the Rests Lesson opens and pauses (%s)" % lessons.shown_id)
	lessons.close()
	await _frames(1)
	# A status on a nightmare: its Lesson, noticed by the card itself (the status whispers used to set it off).
	var wet: Node2D = main.get_node("%EnemyContainer").spawn_enemy(load("res://resource/enemy/leaf_bug.tres"), 1.0, {}, false)
	await _frames(1)
	wet.apply_status(EnemyStatuses.DAMP, 1, 5.0, 1.0, 5)
	lessons._watch_left = 0.0
	lessons._watch_field(0.016)
	await _frames(2)
	_check(lessons.visible and lessons.shown_id == &"discover_damp" and speed.paused, "the first Soaked nightmare: its status Lesson (%s)" % lessons.shown_id)
	lessons.close()
	await _frames(1)
	var whisper_node = main.get_node("%Whispers")
	_check(not whisper_node.shown.has(&"damp") and not whisper_node.shown.has(&"rest") and not whisper_node.shown.has(&"speed"), "…and no teaching whisper says any of it")

	# Choice Lessons (onboarding.md "Choice Lessons", user 2026-10-12): each opens over its own choice screen the first
	# time it offers, blocks picking until closed, shows once, and leaves the game paused for the choice.
	lessons.queue.clear()
	lessons.close()
	for id in LessonCard.CHOICE_SCREENS:
		lessons.seen.erase(String(id))
	var hud := main.get_node("HUD")
	# The first family pick.
	var family := hud.get_node("FamilyPickScreen")
	dreams.unlock_everything = false
	speed.set_paused(false)
	family.show_pick(&"first")
	await _frames(3)
	_check(family.visible and lessons.visible and lessons.shown_id == &"choice_family" and lessons._title.text == "Wake a family"
		and lessons._body.text.contains("Calling") and speed.paused and LessonCard.covering(family) and lessons.get_index() > family.get_index(),
		"Wake a family opens over the first family pick, above it, the game paused (%s)" % lessons.shown_id)
	var calling_before: String = dreams.calling
	if not family.offer.is_empty():
		family.choose(family.offer[0])
	_check(family.visible and dreams.calling == calling_before, "…and no family can be picked under it")
	lessons.close()
	await _frames(2)
	_check(not lessons.visible and family.visible and speed.paused and not LessonCard.covering(family) and lessons.get_index() < family.get_index(),
		"Got it closes back onto the pick, still paused, the card back under the screens")
	family.visible = false
	family.show_pick(&"first")
	await _frames(3)
	_check(family.visible and not lessons.visible, "…and it shows once")
	family.visible = false
	# The first Dream offer (it used to show after the pick).
	var offer_cards := dreams.make_offer(5)
	dreams.current_offer = offer_cards
	dreams.offer_ready.emit(offer_cards, 5)
	await _frames(3)
	_check(dream_screen.visible and lessons.visible and lessons.shown_id == &"discover_dream" and lessons._title.text == "A Dream"
		and speed.paused and LessonCard.covering(dream_screen), "A Dream opens over the first Dream offer (%s)" % lessons.shown_id)
	var taken_before: int = dreams.stacks.size()
	if not offer_cards.is_empty():
		dream_screen._pick(offer_cards[0], null)
	_check(dreams.is_offering() and dreams.stacks.size() == taken_before, "…and no card can be taken under it")
	lessons.close()
	await _frames(2)
	_check(not lessons.visible and dream_screen.visible and speed.paused, "Got it closes back onto the offer, still paused")
	dreams.current_offer = [] as Array[UpgradeData]
	dream_screen.visible = false
	# The first Omen offer.
	var omens: OmenDirector = main.get_node("%OmenDirector")
	var omen_screen := hud.get_node("OmenScreen") as Control
	var omen_offer := omens.make_offer(2)
	omens.current_offer = omen_offer
	omens.offer_ready.emit(omen_offer, 2)
	await _frames(3)
	_check(omen_screen.visible and lessons.visible and lessons.shown_id == &"choice_omen" and speed.paused and LessonCard.covering(omen_screen)
		and lessons.get_index() > omen_screen.get_index() and lessons.mouse_filter == Control.MOUSE_FILTER_STOP,
		"An Omen opens over the first Omen offer and takes the mouse (%s)" % lessons.shown_id)
	lessons.close()
	await _frames(2)
	_check(not lessons.visible and omen_screen.visible and speed.paused, "Got it closes back onto the Omens, still paused")
	omens.current_offer = [] as Array[OmenData]
	omen_screen.visible = false
	# Hints off: none of them.
	for id in LessonCard.CHOICE_SCREENS:
		lessons.seen.erase(String(id))
	lessons.set_enabled(false)
	family.show_pick(&"first")
	await _frames(3)
	_check(family.visible and not lessons.visible, "Hints off: no choice Lesson")
	family.visible = false
	lessons.enabled = true
	speed.set_paused(false)

	_check(not HeartwoodMemory.load_data().has(LessonCard.SEEN_KEY), "tests never write the profile")

	main.queue_free()
	await process_frame
	for path in [HeartwoodMemory.file_path, RunSaver.file_path]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("lessons test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)
