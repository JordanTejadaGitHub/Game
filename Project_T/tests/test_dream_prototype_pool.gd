extends SceneTree
var failures := 0
const RETIRED = ["small_hands", "many_talents", "first_among_equals", "menagerie", "seasoned", "many_hands", "golden_harvest", "tended_forest", "nimble_twigs", "restless_roots", "hummingheart", "grove_of_kin", "kindred_roots", "thornheart", "deep_grip", "blessing_acorn", "blessing_bellflower", "blessing_firefly_jar", "blessing_nestling", "blessing_rootling", "blessing_whirligig",
	# Section 36 (owner card pass 2026-10-25)
	"close_shave", "deep_roots", "quick_step", "cheap_seeds", "fresh_growth", "head_start", "press_on", "hot_on_their_heels", "heavy_eyelids", "kindled_gaze", "ring_of_rings", "stolen_away", "reclaimed_earth", "desperate_bloom", "restless_night", "second_wind", "alarm_bells", "deep_stillness", "endless_night", "eye_of_the_tempest", "falling_stars", "fever_pitch", "mountains_fall", "prism_heart"]
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 421901
	root.add_child(main)
	await process_frame
	var dreams: DreamState = main.get_node("%DreamState")
	dreams.run_pool.clear()
	for id in RETIRED:
		var card = dreams._card_by_id(id)
		_check(card != null, "legacy resource remains readable: " + id)
		if card != null:
			_check(card.retired and not dreams.can_offer(card, 4), "retired from offers: " + id)
	for pair in [["pebbling", "Stone Relay"], ["dewdrop", "Stored Rain"], ["sporeling", "Spore Reserve"]]:
		var card = dreams._card_by_id("blessing_" + pair[0])
		_check(card != null and card.display_name == pair[1], "role identity: " + pair[0])
		# Retired by the Callings (67940fac, dream_council_review.md 12): the first family's Calling carries the rule now;
		# the ids and effects stay for old saves, never offered.
		_check(card.retired, "role Blessing retired (its rule is the family's Calling): " + pair[0])
		dreams.unlocked[pair[0]] = true
		dreams.grown_wardens[pair[0]] = true
		_check(not dreams.can_offer(card, 2), "retired role never offered, even after its family grows: " + pair[0])
		_check(not dreams.can_offer(card, 1) and not dreams.can_offer(card, 4), "retired role never offered in any act: " + pair[0])
		_check(card.soothe_bonus == 0.0 and card.evolve_discount == 0.0, "no passive family package: " + pair[0])
	for id in ["full_moon", "chosen_few", "falling_weight", "seedfall", "sprout_chorus", "switchback"]:  # (deeper_calm retired 2026-10-13; cheap_seeds section 36)
		_check(not dreams._card_by_id(id).retired, "preserved meaningful choice: " + id)
	for id in ["canopy", "grand_tour"]:
		var card = dreams._card_by_id(id)
		_check(not card.in_start_pool and not dreams.can_offer(card, 4), "Grove placement retained: " + id)
	dreams.unlocked = {"sprout": true, "thornwall": true}
	dreams.grown_wardens.clear()
	for seed_value in range(12):
		dreams.build_run_pool(seed_value)
		for id in RETIRED:
			_check(not dreams.run_pool.has(id), "retired absent from sample: " + id)
		var available := 0
		for card in dreams.pool:
			if dreams.can_offer(card, 1): available += 1
		_check(available >= 3, "fresh act-one offer remains viable: seed " + str(seed_value))
	print("Dream prototype pool: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	main.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures == 0 else 1)
func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
