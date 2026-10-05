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
	main.get_node("%Whispers").set_enabled(false)  # The act 1 dossier waits for onboarding hints (up to 8 s): none here
	# The act 1 boss rest: a gift is offered; a new nightmare waits for its introduction at the same time.
	gifts._on_rest_started(5, true, 0, false)
	intro._pending = [load("res://resource/enemy/leaf_bug.tres")]
	intro._drift = 26
	intro._wait = 0.0
	# An act's start (user, 2026-10-03): family pick → Dream → gift → "What's coming", one page with the boss as the
	# hero and the block's new nightmares listed under it: no separate card for them.
	var most := 0
	var gift_frames := 0
	var gift_done := false
	var coming_rows := 0
	var intro_seen := false
	var dossier := main.get_tree().get_first_node_in_group(BossDossier.GROUP) as BossDossier
	var shade: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	for frame in 400:
		await process_frame
		var shown := _open_screens(hud)
		most = maxi(most, shown.size())
		intro_seen = intro_seen or shown.has("NightmareIntro")
		if shown.has("GiftScreen"):
			gift_frames += 1
			if gift_frames == 30:
				gifts.let_pass()  # The player lets the gifts pass
				gift_done = true
		if shown.has("BossDossier") and gift_done:
			var list := dossier._content.get_node_or_null("WhatsComing")
			coming_rows = list.find_children("New_*", "", false, false).size() if list != null else 0
			_check(dossier._close_button.text == "Continue", "\"What's coming\" ends in Continue")
			dossier.close_dossier()
			break
	_check(gift_frames > 0, "the gift screen opened first")
	_check(most <= 1, "never two paused screens at once (at most %d)" % most)
	_check(coming_rows >= 1, "\"What's coming\" lists the block's new nightmares under the boss (%d)" % coming_rows)
	for i in 30:
		await process_frame
	_check(not intro_seen and not intro.visible, "no separate new-nightmare page at an act's start")
	_check(NightmareIntro.session_seen.has(NightmareIntro.kind_of(shade)), "listed there counts as introduced")

	# A normal rest: one "New this block" page for every new kind (not a card each); a row opens the full card in place.
	var kinds := [load("res://resource/enemy/crow.tres"), load("res://resource/enemy/old_stag.tres")]
	intro.open_list(kinds, 11)
	await process_frame
	var rows := intro._content.find_children("New_*", "", false, false)
	_check(intro.visible and rows.size() == 2 and intro._next.text == "Continue", "one page lists both new kinds (%d rows)" % rows.size())
	var head: Button = rows[0].get_node("Head")
	var details: Control = rows[0].get_node("Details")
	head.pressed.emit()
	_check(details.visible, "tapping a row opens its full card in place")
	var panel := intro._panel.get_theme_stylebox("panel") as MoonStyleBox
	_check(panel != null and panel.center_alpha >= 0.9, "the page is solid")
	intro.close()
	main.queue_free()
	await process_frame
	ResultsScreen.demo_override = -1
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("PASS" if failures == 0 else "FAILURES: %d" % failures)
	quit(failures)
