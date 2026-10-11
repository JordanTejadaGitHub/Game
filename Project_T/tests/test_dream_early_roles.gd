extends SceneTree
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 421901
	root.add_child(main)
	await process_frame
	var dreams: DreamState = main.get_node("%DreamState")
	dreams.grove_cards.clear()
	# A Grove-unlocked Pebbling is a valid early family choice.
	var families = main.get_node("%FamilyPickScreen").families
	var pebbling = load("res://resource/tower/pebbling.tres")
	if not families.has(pebbling): families.append(pebbling)
	dreams.discovery_profile = {"seen": [], "wardens_built": [], "best_chain": 0}
	for family in ["pebbling", "dewdrop", "sporeling"]:
		var card := dreams._card_by_id("blessing_" + family)
		_check(card.rarity == UpgradeData.Rarity.UNCOMMON and card.min_act == 1, family + " role is Uncommon act one")
		_check(card.in_start_pool and card.requires == [family], family + " retains its family requirement")
		dreams.unlocked = {"sprout": true, "thornwall": true}
		dreams.grown_wardens.clear()
		dreams.run_pool_forced = false
		_check(not dreams.is_eligible(card, 1), family + " cannot serve the wrong family")
		dreams.unlocked[family] = true
		dreams.grown_wardens[family] = true
		dreams.discovery_profile.wardens_built = [family]
		_check(dreams.is_eligible(card, 1), family + " role is eligible after its family is built in act one")
		dreams.run_pool_forced = true
		var sampled := 0
		var offered := 0
		for seed_value in range(64):
			dreams.map_generator.map_seed = seed_value
			dreams.build_run_pool(seed_value)
			if dreams.in_run_pool(card): sampled += 1
			else: _check(not dreams.is_eligible(card, 1), family + " sampled-out role stays unavailable")
			dreams._rng.seed = seed_value
			var offer := dreams.make_offer(5)
			_check(offer.size() >= 3, family + " act-one offer remains viable")
			if offer.has(card): offered += 1
		_check(sampled > 0 and sampled < 64, family + " role can enter or miss the 60% family sample")
		_check(offered > 0 and offered < 64, family + " role can appear without a guaranteed slot")
		print(family, ": sampled ", sampled, "/64; offered ", offered, "/64")
	for id in ["canopy", "grand_tour"]:
		var card := dreams._card_by_id(id)
		_check(not card.in_start_pool and not dreams.is_eligible(card, 4), id + " retains fresh-profile Grove gate")
	print("Dream early roles: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	paused = false
	main.queue_free()
	for i in RunSaver.QUIT_FRAMES:
		await process_frame
	quit(0 if failures == 0 else 1)
func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
