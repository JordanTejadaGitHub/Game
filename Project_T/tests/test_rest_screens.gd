extends SceneTree

# One paused screen at a time at a rest (user screenshot: a new-nightmare card opened over the Heartwood's Gifts, both
# see-through): an act-break rest with a gift on offer and a new nightmare to introduce opens them one after another,
# never two at once (RestScreens). Paused cards are solid. Full game (the gifts), temp profile.

var failures := 0

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok: ", what)
	else:
		failures += 1
		push_error("FAIL: " + what)

func _initialize() -> void:
	_run.call_deferred()

func _open_screens(hud: Node) -> Array:
	var out: Array = []
	for screen_name in RestScreens.SCREENS:
		var screen := hud.get_node_or_null(screen_name) as CanvasItem
		if screen != null and screen.visible:
			out.append(screen_name)
	return out

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_rest_screens_%d.json" % OS.get_process_id()
	ResultsScreen.demo_override = 0
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3:
		await process_frame
	var hud: Node = main.get_node("HUD")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var gifts = main.get_tree().get_first_node_in_group(&"heartwood_gifts")
	var intro := main.get_tree().get_first_node_in_group(NightmareIntro.GROUP) as NightmareIntro
	_check(gifts != null and intro != null, "the gifts and the intro card exist")
	director.resting = true
	# The act 1 boss rest: a gift is offered; a new nightmare waits for its introduction at the same time.
	gifts._on_rest_started(5, true, 0, false)
	intro._pending = [load("res://resource/enemy/leaf_bug.tres")]
	intro._drift = 26
	intro._wait = 0.0
	var most := 0
	var gift_frames := 0
	var intro_after_gift := false
	var gift_done := false
	for frame in 240:
		await process_frame
		var shown := _open_screens(hud)
		most = maxi(most, shown.size())
		if shown.has("GiftScreen"):
			gift_frames += 1
			if gift_frames == 30:
				gifts.let_pass()  # The player lets the gifts pass
				gift_done = true
		if shown.has("NightmareIntro") and gift_done:
			intro_after_gift = true
			break
	_check(gift_frames > 0, "the gift screen opened first")
	_check(most <= 1, "never two paused screens at once (at most %d)" % most)
	_check(intro_after_gift, "the new nightmare's card opened once the gift was done")
	var panel := intro._panel.get_theme_stylebox("panel") as MoonStyleBox
	_check(panel != null and panel.center_alpha >= 0.9, "the intro card is solid")
	main.queue_free()
	await process_frame
	ResultsScreen.demo_override = -1
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("PASS" if failures == 0 else "FAILURES: %d" % failures)
	quit(failures)
