extends SceneTree
const SUCCESSORS := ["corner_sign", "wake_ripple", "dream_residue", "kins_keepsake", "passing_thread", "crosswind", "opening_fracture", "shared_mycelium", "crossed_sparks", "fresh_beginnings", "afterroot", "emergency_reserves", "hushed_hedge", "quiet_vigil"]
var failures := 0
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	var dreams: DreamState = main.get_node("%DreamState")
	dreams.unlock_everything = true
	dreams.run_pool_forced = true
	dreams.stacks.clear()
	dreams.unlocked = {"sporeling": true, "firefly_jar": true, "rootling": true, "dewdrop": true, "stormcap": true,
		"samara": true, "lanternmoth": true, "driftspore": true, "dreamcatcher": true, "pebbling": true}
	for full_grove in [false, true]:
		dreams.grove_cards.clear()
		if full_grove:
			for card in dreams.pool:
				if not card.in_start_pool: dreams.grove_cards.append(card.id)
		var pools := {}
		var successor_draws := 0
		for seed_value in 24:
			dreams.build_run_pool(seed_value)
			var signature: Array = dreams.run_pool.keys()
			signature.sort()
			pools[hash(signature)] = true
			var before := dreams.run_pool.duplicate()
			dreams.build_run_pool(seed_value)
			_check(dreams.run_pool == before, "same seed produces the same pool")
			for card in dreams.pool:
				_check(not card.retired or not dreams.run_pool.has(card.id), "retired card never sampled")
				if SUCCESSORS.has(card.id) and dreams.run_pool.has(card.id): successor_draws += 1
			for id in ["crosswind", "opening_fracture", "hushed_hedge"]:
				_check(full_grove or not dreams.in_run_pool(load("res://resource/dream/%s.tres" % id)), "Grove successors excluded from fresh profile")
		_check(pools.size() > 1 and successor_draws > 0, "successors join varied seeded pools")
		print("Unique offers: %s Grove, %d/24 distinct pools, %d successor draws" % ["full" if full_grove else "fresh", pools.size(), successor_draws])
	print("Unique Dream offers: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)
func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + label)