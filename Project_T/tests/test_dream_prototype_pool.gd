extends SceneTree
var failures := 0
const RETIRED = ["small_hands", "many_talents", "first_among_equals", "menagerie", "the_long_walk", "seasoned", "many_hands", "golden_harvest", "tended_forest", "nimble_twigs", "restless_roots", "hummingheart", "grove_of_kin", "kindred_roots", "thornheart", "deep_grip", "blessing_acorn", "blessing_bellflower", "blessing_firefly_jar", "blessing_nestling", "blessing_rootling", "blessing_whirligig"]
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
		_check(not card.retired and card.rarity == UpgradeData.Rarity.UNCOMMON and card.min_act == 1 and card.in_start_pool, "ordinary Act 1 role placement: " + pair[0])
		dreams.unlocked[pair[0]] = true
		dreams.grown_wardens[pair[0]] = true
		_check(dreams.can_offer(card, 2), "mechanical family role eligible after family grows: " + pair[0])
		_check(dreams.can_offer(card, 1), "act-one access corrected: " + pair[0])
		_check(card.soothe_bonus == 0.0 and card.evolve_discount == 0.0, "no passive family package: " + pair[0])
	for id in ["full_moon", "chosen_few", "falling_weight", "cheap_seeds", "seedfall", "deeper_calm", "sprout_chorus", "switchback"]:
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
