extends SceneTree
var failures := 0
const PATTERNS := ["rhythm", "crossfire", "drumbeat", "thorny_walls", "sprout_chorus", "switchback"]
func _initialize() -> void:
	_run.call_deferred()
func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var dreams: DreamState = main.get_node("%DreamState")
	dreams.grove_cards.clear()
	dreams.unlocked = {"sprout": true, "thornwall": true}
	dreams.grown_wardens.clear()
	dreams.discovery_profile = {"seen": [], "wardens_built": [], "best_chain": 0}
	dreams.run_pool_forced = true
	for index in 5:
		var tower: Tower = load("res://scenes/tower/tower.tscn").instantiate()
		tower.tower_data = load("res://resource/tower/sprout.tres")
		tower.cell = Vector2(2 + index, 2)
		tower.position = tower.cell * 64.0 + Vector2(32, 32)
		main.get_node("%TowerContainer").add_child(tower)
		tower.set_process(false)
	var seen := {}
	var layouts := {}
	var pattern_offers := 0
	var plain_offers := 0
	for seed_value in 32:
		dreams.map_generator.map_seed = seed_value
		dreams.build_run_pool(seed_value)
		for drift in [5, 10, 15, 20]:
			dreams._rng.seed = seed_value * 500 + drift
			var offer := dreams.make_offer(drift)
			_check(offer.size() >= 3, "starter board keeps viable Act 1 offers")
			var ids: Array = []
			var has_pattern := false
			for card in offer:
				ids.append(card.id)
				_check(card.in_start_pool and not card.retired, "fresh board cannot offer Grove or retired cards")
				if card.id in PATTERNS:
					seen[card.id] = true
					has_pattern = true
			ids.sort()
			layouts[str(ids)] = true
			if has_pattern: pattern_offers += 1
			else: plain_offers += 1
	_check(seen.has("rhythm") and seen.has("crossfire"), "both universal patterns appear in real Act 1 offers")
	_check(seen.size() >= 3, "starter board sees several different mechanics")
	_check(pattern_offers > 0 and plain_offers > 0, "mechanical opportunities are possible, never guaranteed")
	_check(layouts.size() > 16, "seeded early offer variety remains")
	print("Early variety: ", pattern_offers, "/128 offers with patterns; ", plain_offers, " without; ", seen.keys(), "; ", layouts.size(), " distinct offers")
	print("Dream early variety: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	paused = false
	main.queue_free()
	for i in RunSaver.QUIT_FRAMES:
		await process_frame
	quit(failures)
