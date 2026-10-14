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
	ResultsScreen.demo_override = 0  # The full game: the demo has no gifts
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
	# Gifts as landmarks (heartwood_gifts.md, approved 2026-10-13): one gift of each kind, never a retired one.
	var kinds: Array = offer.map(func(id: StringName) -> StringName: return HeartwoodGifts.kind_of(id))
	_check(offer.size() == 3 and kinds == [HeartwoodGifts.KIND_LAND, HeartwoodGifts.KIND_LANDMARK, HeartwoodGifts.KIND_BOON] and offer == gifts.draw(1),
		"3 gifts, one of each kind (land, landmark, boon), the same draw for the same act (%s)" % [offer])
	_check(not gifts.can_offer(&"thick_mist") and not gifts.can_offer(&"glade") and not gifts.can_offer(&"shift_stones") and gifts.can_offer(&"reshape"),
		"Thick Mist, Glade and Shift the Stones are retired; Reshape replaces the two")
	# Every gift is generic: no landmark needs a family. Old Kin needs a Kinship on the map.
	var kin_before: int = dreams.sim_kinships
	dreams.sim_kinships = 0
	_check(gifts.can_offer(&"bell_stone") and gifts.can_offer(&"spring") and gifts.can_offer(&"moonwell") and not gifts.can_offer(&"old_kin"),
		"landmarks are offered whatever the families; Old Kin is not offered with no Kinship on the map")
	dreams.sim_kinships = 1
	_check(gifts.can_offer(&"old_kin") == HeartwoodGifts.has_effect(&"old_kin"), "...and is offered once the map has one")
	dreams.sim_kinships = kin_before
	for gift_id in HeartwoodGifts.POOL:
		var gift_text := String(HeartwoodGifts.POOL[gift_id].text)
		var names_family := false
		for word in ["{damp}", "{spored}", "{static}", "{drowsy}", "{marked}", "Water Wardens", "Song Wardens", "Spore Wardens"]:
			names_family = names_family or gift_text.contains(word)
		_check(HeartwoodGifts.is_retired(gift_id) or (not names_family and HeartwoodGifts.family_of(gift_id) == HeartwoodGifts.ANY_FAMILY),
			"%s names no family and no family status" % gift_id)
	# Landmarks grow one step at each later act break, up to III; the numbers come from one place.
	gifts.taken.append({"id": "moonwell", "act": 1, "placement": {}, "step": 1, "grown_act": 1})
	gifts.grow_landmarks(1)
	_check(gifts.step_of(&"moonwell") == 1, "a landmark doesn't grow at the act break it was taken at")
	gifts.grow_landmarks(2)
	gifts.grow_landmarks(2)
	_check(gifts.step_of(&"moonwell") == 2, "one step at the next act break, once (a resumed run doesn't grow it twice)")
	gifts.grow_landmarks(3)
	gifts.grow_landmarks(4)
	_check(gifts.step_of(&"moonwell") == HeartwoodGifts.MAX_STEP and is_equal_approx(gifts.value(&"moonwell", "range"), 3.0)
		and is_equal_approx(HeartwoodGifts.stat(&"moonwell", "range", 1), 1.5) and gifts.step_of(&"spring") == 0, "III is the top; value() reads the step's number")
	gifts.taken.pop_back()

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
	_check(HeartwoodGifts.POOL.keys().all(func(id: StringName) -> bool: return GiftScreen.SCENES.has(id) or id == &"thick_mist"), "every gift has a before / after scene (Reshape too; retired Thick Mist has none)")
	# Gifts as landmarks (heartwood_gifts.md, approved 2026-10-13): the card names its kind; a landmark says that
	# it grows (no family line: every gift is generic, 8c8a8cb0); its scene shows it acting in its zone, with its step's numbers.
	var spring_card: Button = screen._card(&"spring")
	root.add_child(spring_card)
	_check((spring_card.find_child("Category", true, false) as Label).text.to_lower() == "landmark" and spring_card.find_child("Fits", true, false) == null
		and spring_card.find_child("Grows", true, false) != null, "the Spring's card: Landmark, no family line, and that it grows")
	spring_card.queue_free()
	var ridge_card: Button = screen._card(&"sow_ridge")
	root.add_child(ridge_card)
	_check((ridge_card.find_child("Category", true, false) as Label).text.to_lower() == "shape the land" and ridge_card.find_child("Grows", true, false) == null,
		"Sow a Ridge's card: Shape the land, no growth line")
	ridge_card.queue_free()
	var bell: Array = screen.scene_for(&"bell_stone")
	_check(bell[2].get("zone") is Dictionary and is_equal_approx(float(bell[2].zone.cells), HeartwoodGifts.zone_cells(&"bell_stone"))
		and String(bell[2].zone.word) == "%d%% slower" % roundi(HeartwoodGifts.stat(&"bell_stone", "slow", 1) * 100.0) and float(bell[2].zone.every) > 0.0,
		"the Bell Stone's scene rings in its zone with its step's numbers (%s)" % [bell[2]])
	_check(GiftScreen.growth_line(&"spring", 2) == "The Spring grows: Wardens near it now attack %d%% faster." % roundi(HeartwoodGifts.stat(&"spring", "attack_speed", 2) * 100.0) and HeartwoodGifts.stat(&"spring", "attack_speed", 2) > 0.0,
		"a landmark's growth line reads its new step (%s)" % GiftScreen.growth_line(&"spring", 2))
	_check(RestReport.landmark_lines(null, {&"bell_stone": 212, &"lightning_tree": 38, &"moonwell": 0}) == "\nBell Stone: slowed 212 nightmares\nLightning Tree: struck 38 times",
		"the rest report credits each landmark in one line")
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
		"the gift is taken; the gift no longer holds Start (next: %s)" % director.pending_choice())
	for frame in 5:
		await process_frame
	# No Omen at an act break (user, 2026-10-03; OmenDirector c115eac4): the act's start is "What's coming" instead.
	_check(not omens.is_offering(), "no Omen follows at an act break")
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

	# Shifting Mist (replaced Deeper Glade): the placer offers rim spots (Environment's start_options) and takes the
	# old start as "keep"; the effect gets the picked spot.
	director.drifts_started = 75
	director.rest_started.emit(15, true, 0, false)
	gifts.current_offer = [&"shifting_mist"]
	gifts.waiting = true
	_check(not HeartwoodGifts.POOL.has(&"deeper_glade") and HeartwoodGifts.POOL[&"shifting_mist"].place == &"rim", "Shifting Mist replaces Deeper Glade")
	var mist := GiftScreen.GiftPlacer.new(director, &"shifting_mist", false)
	main.add_child(mist)
	mist.click(map.startPath)
	_check(mist.is_complete() and mist.placement().cells == [map.startPath] and mist.status().begins_with("Keep the start"),
		"Shifting Mist: clicking the old start keeps it (%s)" % mist.status())
	applied.clear()
	gifts.choose(&"shifting_mist", mist.placement())
	_check(applied.size() == 1 and applied[0][0] == &"shifting_mist" and HeartwoodGifts.cells_of(applied[0][1]) == [map.startPath],
		"Shifting Mist: the effect gets the picked spot")
	mist.queue_free()

	# Half cells (heartwood_gifts.md 2554c638, user: "should be going by half a cell like Wardens"): a piece snaps like a
	# Warden and may sit half-offset; each piece put down plays the plant sound, a refused click the refusal; Mire takes
	# route halves.
	var ridge := GiftScreen.GiftPlacer.new(director, &"sow_ridge", true)
	main.add_child(ridge)
	var heard: Array = []
	ridge.on_placed = func(at: Vector2) -> void: heard.append(at)
	var refused: Array = []
	var refuse_hook := func(c: Vector2) -> void: refused.append(c)
	main.get_node("%TowerPlacer").build_rejected.connect(refuse_hook)
	var offset_spot := Vector2(-1, -1)
	for y in range(1, 17):
		for x in range(1, 22):
			if offset_spot == Vector2(-1, -1) and ridge._cell_ok(Vector2(x + 0.5, y)):
				offset_spot = Vector2(x + 0.5, y)
	ridge.click(offset_spot)
	_check(offset_spot != Vector2(-1, -1) and ridge.placement().pieces == [offset_spot * 2.0] and heard.size() == 1,
		"a half-offset ridge piece: origin %s, the plant sound (%d)" % [offset_spot * 2.0, heard.size()])
	ridge.click(map.startPath)
	_check(ridge.placement().pieces.size() == 1 and refused.size() == 1, "a piece on the start is refused, with the refusal sound")
	main.get_node("%TowerPlacer").build_rejected.disconnect(refuse_hook)
	ridge.queue_free()
	# A log's line with half-offset hovers (the user's Fallen Giant crash: the old loop never met `to` and ran out of
	# memory): only whole pieces in one row or column, always bounded.
	# The line follows the pointer's main direction in whole pieces (user: "doesn't plant half cells and the image
	# disappears"), bounded; a click past the limit plants up to it (heartwood_gifts.md 52d11575).
	var log_placer := GiftScreen.GiftPlacer.new(director, &"fallen_giant", true)
	_check(log_placer._line(Vector2(3, 4), Vector2(5.5, 4)).size() == 4 and log_placer._line(Vector2(3, 4), Vector2(5, 4.5)).size() == 3
		and log_placer._line(Vector2(3, 4), Vector2(5, 4.5)).all(func(c: Vector2) -> bool: return c.y == 4.0)
		and log_placer._line(Vector2(3, 4), Vector2(3, 1)).size() == 4 and log_placer._line(Vector2(0, 0), Vector2(1000, 0)).size() == 65
		and log_placer._line_fit(Vector2(3, 4), Vector2(9, 4)).size() == int(log_placer.size[1]),
		"a log line: the main direction in whole pieces, half-offset pointers too, bounded; a far click fits the limit")
	log_placer.free()
	var mire := GiftScreen.GiftPlacer.new(director, &"mire", false)
	main.add_child(mire)
	var route_half := Vector2(FindPath.point_to_node(map.get_path_from(map.startPath)[6]))
	mire.click(route_half)
	_check(mire.placement().halves == [route_half], "Mire takes a route half (%s)" % [mire.placement().get("halves")])
	mire.queue_free()

	# Saved and rebuilt.
	var max_now := run_state.max_leaves
	var saved := gifts.to_save()
	applied.clear()
	gifts.load_save(saved)
	_check(gifts.taken.size() == 3 and applied.size() == 2 and applied.all(func(a: Array) -> bool: return a[1].restoring) and run_state.max_leaves == max_now,
		"a resumed run rebuilds the gifts (restoring) and the max leaves stay")
	# Three ways out of placing (heartwood_gifts.md 42f5da78): Undo takes back the last pick, Clear empties them, Back
	# returns to the cards with nothing spent; "Plant it" commits. Plus the length tag (52d11575).
	gifts.current_offer = [&"fallen_giant", &"mire", &"spring"]
	gifts.waiting = true
	screen.open()
	screen.pick(&"fallen_giant")
	var lp: GiftScreen.GiftPlacer = screen.placer
	var log_start := Vector2(-1, -1)
	for y in range(2, 16):
		for x in range(2, 18):
			if log_start == Vector2(-1, -1) and lp._cell_ok(Vector2(x, y)) and lp._line(Vector2(x, y), Vector2(x + int(lp.size[1]) - 1, y)).all(lp._cell_ok):
				log_start = Vector2(x, y)
	lp.click(log_start)
	_check(lp.cells == [log_start], "the log's start is picked")
	lp.hover = log_start + Vector2(9, 0)
	_check(lp.length_tag().begins_with("%d / %d · max" % [int(lp.size[1]), int(lp.size[1])]), "past the limit the tag says max (%s)" % lp.length_tag())
	lp.hover = log_start
	_check(lp.length_tag().contains("%d more" % (int(lp.size[0]) - 1)), "too short: the tag counts what's missing (%s)" % lp.length_tag())
	lp.undo()
	_check(lp.cells.is_empty() and screen.placing == &"fallen_giant", "Undo takes back the start; still placing")
	lp.click(log_start)
	lp.clear()
	_check(lp.cells.is_empty() and screen.placing == &"fallen_giant", "Clear empties the picks; still placing")
	var taken_before := gifts.taken.size()
	screen.cancel_placing()
	_check(screen.placing == &"" and screen._choose.visible and gifts.waiting and gifts.taken.size() == taken_before,
		"Back returns to the cards with nothing spent")
	screen.pick(&"fallen_giant")
	screen.placer.click(log_start)
	screen.placer.click(log_start + Vector2(9, 0))  # Past the limit: plants up to it
	_check(screen.placer.is_complete() and screen.placer.placement().pieces.size() == int(screen.placer.size[1]),
		"a click past the limit plants a full-length log")
	screen.confirm_placing()
	_check(gifts.taken.size() == taken_before + 1 and not screen.visible and not gifts.waiting, "Plant it commits; the choice is gone")


	# Payoffs (heartwood_gifts.md b3e464e6): Shifting Mist's Dew pots +10% for the act it opens; Shift the Stones pays
	# 30 Dew × act per stone moved (Dew only since 8f46c6ac).
	var mist_act := int(gifts.taken.filter(func(t: Dictionary) -> bool: return StringName(t.id) == &"shifting_mist")[0].act)
	var first_of := func(act: int) -> int: return (act - 1) * director.drifts_per_act + 1
	_check(is_equal_approx(gifts.get_dew_pot_multiplier(first_of.call(mist_act + 1)), 1.0 + HeartwoodGifts.MIST_POT_BONUS)
		and is_equal_approx(gifts.get_dew_pot_multiplier(first_of.call(mist_act)), 1.0)
		and is_equal_approx(gifts.get_dew_pot_multiplier(first_of.call(mist_act + 2)), 1.0),
		"Shifting Mist: only the next act's Dew pots get +10%")
	var pot_with := director.get_dew_pot_multiplier(first_of.call(mist_act + 1))
	gifts.taken = gifts.taken.filter(func(t: Dictionary) -> bool: return StringName(t.id) != &"shifting_mist")
	_check(is_equal_approx(pot_with / director.get_dew_pot_multiplier(first_of.call(mist_act + 1)), 1.0 + HeartwoodGifts.MIST_POT_BONUS),
		"DriftDirector's Dew pot reads the gift")
	gifts.current_offer = [&"shift_stones"]
	gifts.waiting = true
	gifts.offer_act = 2
	var dew_before := run_state.dew
	var froms := [Vector2(3, 3), Vector2(4, 3)]
	gifts.choose(&"shift_stones", {"cells": [Vector2(6, 6), Vector2(7, 6)], "from": froms})
	_check(run_state.dew - dew_before == HeartwoodGifts.SHIFT_DEW * 2 * 2, "Shift the Stones: 30 Dew × act 2 × 2 stones (%d)" % (run_state.dew - dew_before))
	_check(not froms.any(func(c: Vector2) -> bool: return run_state.fertile_cells.has(c)), "Shift the Stones: Dew only, no fertile spots")

	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("PASS" if failures == 0 else "FAILURES: %d" % failures)
	quit(failures)
