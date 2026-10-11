extends SceneTree
# The three role cards (Stone Relay, Stored Rain, Spore Reserve) left the Dream pool on 2026-10-11: their jobs are the
# first family's Callings now (documentation/dream_council_review.md 11; tests/test_callings.gd). Their ids stay readable.
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
	var families = main.get_node("%FamilyPickScreen").families
	var pebbling = load("res://resource/tower/pebbling.tres")
	if not families.has(pebbling): families.append(pebbling)
	dreams.discovery_profile = {"seen": [], "wardens_built": [], "best_chain": 0}
	for family in ["pebbling", "dewdrop", "sporeling"]:
		var card := dreams._card_by_id("blessing_" + family)
		_check(card != null and card.retired, family + " role card is retired but still loads (old saves)")
		_check(card.requires == [family], family + " role card keeps its family requirement for old saves")
		dreams.unlocked = {"sprout": true, "thornwall": true}
		dreams.unlocked[family] = true
		dreams.grown_wardens[family] = true
		dreams.discovery_profile.wardens_built = [family]
		dreams.run_pool_forced = false
		_check(not dreams.is_eligible(card, 1), family + " role card is never offered")
		dreams.run_pool_forced = true
		for seed_value in range(16):
			dreams.map_generator.map_seed = seed_value
			dreams.build_run_pool(seed_value)
			_check(not dreams.in_run_pool(card), family + " role card never enters a run pool")
			dreams._rng.seed = seed_value
			var offer := dreams.make_offer(5)
			_check(offer.size() >= 3, family + " act-one offer remains viable")
			_check(not offer.has(card), family + " role card never appears in an offer")
		_check(DreamState.CALLINGS.title(family) != "", family + " has a Calling in its place")
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
