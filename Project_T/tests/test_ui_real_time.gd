extends SceneTree

# Game speed is for the field only (user 2026-10-07: "make sure speed only changes gameplay speed, it shouldn't change
# everything else like Dream pick animations"; screens_ui.md 80fc4c25): at ×3 the Dream pick's flight takes as long as
# at ×1. Headless with --fixed-fps 60 each frame is 1/60 s of real time (UiTime tweens ignore Engine.time_scale), so a
# real-time flight needs FLY_TIME × 60 frames at ×3 too, where a game-time one would be done in a third of that.
# Never touches the player's saves.
#   godot --headless --path . --script res://tests/test_ui_real_time.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _run() -> void:
	var pid := OS.get_process_id()
	HeartwoodMemory.file_path = "user://test_ui_real_time_%d.json" % pid
	RunSaver.file_path = "user://test_ui_real_time_run_%d.json" % pid
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 4242
	root.add_child(main)
	root.size = Vector2i(1280, 800)
	await _frames(3)
	var dreams: DreamState = main.get_node("%DreamState")
	var screen = main.get_node("HUD/DreamScreen")

	var offer: Array[UpgradeData] = []
	for card in dreams.pool:
		if offer.size() < 3 and card.kind == UpgradeData.Kind.STAT and not dreams.stacks.has(card.id):
			offer.append(card)
	_check(offer.size() == 3, "three plain cards to offer")
	dreams.current_offer = offer
	dreams.current_offer_drift = 50
	dreams.picks_left = 1
	Engine.time_scale = 3.0
	screen._show_offer(offer, 50)
	await _frames(int(ChoiceArm.ARM_TIME * 60.0) + 30)  # Armed and faded in (real time too)
	_check(screen.arm.is_armed(), "armed after %.1f s of real time at ×3" % ChoiceArm.ARM_TIME)
	var column := screen._cards.get_child(0) as Control
	screen._pick(offer[0], column)
	# A game-time flight (FLY_TIME + the 0.1 s fade) would end after (FLY_TIME + 0.1) × 60 / 3 frames; past that it isn't
	var early := int(screen.FLY_TIME * 60.0 / 3.0) + 8
	await _frames(early)
	_check(not dreams.stacks.has(offer[0].id), "at ×3 the flight isn't done after %d frames (a third of its real time)" % early)
	await _frames(int(screen.FLY_TIME * 60.0) + 15 - early)
	_check(dreams.stacks.has(offer[0].id), "…and is done after FLY_TIME of real time, as at ×1")

	Engine.time_scale = 1.0
	main.queue_free()
	await process_frame
	for path in [HeartwoodMemory.file_path, RunSaver.file_path]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("ui real time test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
