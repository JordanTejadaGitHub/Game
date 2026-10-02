extends SceneTree

# Heartwood's Gifts (heartwood_gifts.md, Spire experiment), Main's parts: the draw (3, at least 2 map gifts, none twice,
# only gifts with an effect), the act-break timing (after the Dream, before the Omen; holds Start), the gift screen and
# its placer (cells refused like a Warden's, the route kept), Let them pass, Thick Mist's spacing, the save round trip
# and the run history. Effects are stand-ins registered here (the owners register the real ones). Temp profile.

var failures := 0
var applied: Array = []  # [id, placement] from the stand-in effects

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok: ", what)
	else:
		failures += 1
		push_error("FAIL: " + what)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_heartwood_gifts_%d.json" % OS.get_process_id()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 4242
	root.add_child(main)
	await process_frame
	await process_frame
	var director: DriftDirector = main.get_node("%DriftDirector")
	var run_state: RunState = main.get_node("%RunState")
	var dreams: DreamState = main.get_node("%DreamState")
	# Stand-ins for every effect, after the scene (its owners register the real ones in their _ready): this tests the
	# draw, the screen and the placement, not the effects.
	for id in HeartwoodGifts.POOL:
		var gift_id: StringName = id
		HeartwoodGifts.register(gift_id, func(_main: Node, placement: Dictionary) -> void: applied.append([gift_id, placement]))
	var gifts := HeartwoodGifts.find(main)
	var screen := main.get_node_or_null("HUD/GiftScreen") as GiftScreen
	_check(gifts != null and screen != null, "the HUD makes the gifts and their screen")
	if gifts == null or screen == null:
		quit(1)
		return

	# The draw.
	var offer := gifts.draw(1)
	var maps := offer.filter(func(id: StringName) -> bool: return HeartwoodGifts.POOL[id].map)
	_check(offer.size() == 3 and maps.size() >= 2 and offer == gifts.draw(1), "3 gifts, at least 2 shaping the map, the same draw for the same act (%s)" % [offer])

	# An act break: after the Dream, before the Omen; Start waits.
	director.drifts_started = 25
	director.resting = true
	director.rest_started.emit(5, true, 0, false)
	_check(gifts.waiting and gifts.current_offer.size() == 3, "the rest after the act 1 boss offers 3 gifts")
	for frame in 10:
		var remember := main.get_node_or_null("%RememberScreen") as RememberScreen
		if remember != null and remember.visible:
			remember.close()  # The boss rest: the Dream waits behind Remember
		if dreams.is_offering() or dreams.has_pending_offer():
			dreams.skip()
		await process_frame
	_check(screen.visible and director.pending_choice() == &"gift" and not director.can_start_next_drift(),
		"after the Dream the gift screen opens and holds Start (%s)" % director.pending_choice())
	_check(main.get_node("HUD/DriftPanel").PENDING_TEXT[&"gift"] == "Choose a gift", "the Start button names it")
	_check(screen.preview != null and screen.preview.get_meta(&"gift", &"") == gifts.current_offer[0], "the first card's mini-scene plays above the cards")
	_check(HeartwoodGifts.POOL.keys().all(func(id: StringName) -> bool: return GiftScreen.SCENES.has(id)), "every gift has a before / after scene")
	for id in GiftScreen.SCENES:
		screen.show_scene(id)
		for frame in 3:
			await process_frame
	_check(screen.preview.get_meta(&"gift", &"") == &"memory_seed", "each of the 18 scenes plays (no errors in the log)")
	screen.show_scene(gifts.current_offer[0])
	var omens = main.get_node("%OmenDirector")
	_check(not omens.is_offering(), "the Omen waits while the gift is up (Roguelite 13aaf91a)")
	_check(not main.get_node("%RunSaver").can_save_now(), "no save while the gift waits")

	# Placing a one-cell gift: the placer refuses the start, takes an empty cell.
	var map = main.get_node("%MapGenerator")
	gifts.current_offer[0] = &"lightning_tree"  # Make sure it's the one placed here
	screen.pick(&"lightning_tree")
	_check(screen.placer != null and screen.placing == &"lightning_tree" and not screen._choose.visible, "a map gift opens the placer, the cards go")
	screen.placer.click(map.startPath)
	_check(not screen.placer.is_complete(), "the start is refused")
	var free := Vector2(-1, -1)
	for y in range(2, 16):
		for x in range(3, 20):
			if free.x < 0 and map.is_buildable(Vector2(x, y)) and not Array(map.get_glade_cells()).has(Vector2(x, y)) \
					and not map.get_path_if_blocked_cells([Vector2(x, y)]).is_empty():
				free = Vector2(x, y)
	screen.placer.click(free)
	_check(screen.placer.is_complete(), "an empty cell is taken (%s)" % free)
	screen.cancel_placing()
	_check(screen._choose.visible and screen.placer == null, "Back returns to the cards")
	screen.pick(&"lightning_tree")
	screen.placer.click(free)
	applied.clear()
	screen.confirm_placing()
	_check(applied.size() == 1 and applied[0][0] == &"lightning_tree" and HeartwoodGifts.cells_of(applied[0][1]) == [free]
		and not applied[0][1].restoring, "Plant: the owner's effect gets the cells")
	_check(not gifts.waiting and not screen.visible and director.pending_choice() != &"gift",
		"the gift is taken; the gift no longer holds Start (next: %s, the Omen's turn)" % director.pending_choice())
	for frame in 5:
		await process_frame
	_check(omens.is_offering() or omens.get_mode() == "never", "then the Omen shows")
	_check(gifts.has_taken(&"lightning_tree") and not gifts.draw(2).has(&"lightning_tree"), "never offered again this run")
	_check(int(gifts.taken[0].placement.get("tended_before", -1)) == run_state.tended_cells.size(), "the record keeps how many cells were tended before it (Environment: resumes)")

	# Let them pass (act 2).
	director.drifts_started = 50
	director.rest_started.emit(10, true, 0, false)
	var dew := run_state.dew
	gifts.let_pass()
	_check(run_state.dew == dew + 60 and gifts.passed == [2], "Let them pass: +30 Dew × act 2")

	# Thick Mist: the next act's arrivals further apart.
	gifts.taken.append({"id": "thick_mist", "act": 1, "placement": {}})
	_check(is_equal_approx(gifts.get_spacing_multiplier(30), 1.25) and is_equal_approx(gifts.get_spacing_multiplier(55), 1.0)
		and is_equal_approx(float(director.get_schedule_modifiers(30).get("spacing", 1.0)), 1.25 * float(main.get_node("%OmenDirector").get_schedule_modifiers(30).get("spacing", 1.0))),
		"Thick Mist taken in act 1: act 2 spaced ×1.25, act 3 not")

	# Deeper Glade: the leaf is ours (the ring Environment's stand-in here).
	var max_before := run_state.max_leaves
	var leaves_before := run_state.leaves
	director.drifts_started = 75
	director.rest_started.emit(15, true, 0, false)
	gifts.current_offer = [&"deeper_glade"]
	gifts.waiting = true
	gifts.choose(&"deeper_glade")
	_check(run_state.max_leaves == max_before + 1 and run_state.leaves == mini(leaves_before + 1, run_state.max_leaves),
		"Deeper Glade: +1 max leaf, and the leaf (%d -> %d)" % [max_before, run_state.max_leaves])

	# Saved and rebuilt.
	var max_now := run_state.max_leaves
	var saved := gifts.to_save()
	applied.clear()
	gifts.load_save(saved)
	_check(gifts.taken.size() == 3 and applied.size() == 2 and applied.all(func(a: Array) -> bool: return a[1].restoring) and run_state.max_leaves == max_now,
		"a resumed run rebuilds the gifts (restoring), and Deeper Glade's leaf isn't added twice")

	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("PASS" if failures == 0 else "FAILURES: %d" % failures)
	quit(failures)
