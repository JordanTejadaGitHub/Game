extends SceneTree
# Grove cards in a run (Grove card council 2026-10-20, D:\Projects\logs\dream_council\grove_cards_*.md): a carried Grove
# card is always in the run's pool, on top of the draw (planting never pushes start cards out), and a card from a node
# planted since the last run (DreamState.fresh_grove_cards, filled by MetaRun) is in the first offer it can show in, once.

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var dreams: DreamState = main.get_node("%DreamState")
	dreams.run_pool_forced = true
	var locked := "shared_light"  # A generic Grove card (Uncommon)
	_check(not load("res://resource/dream/%s.tres" % locked).in_start_pool, "Shared Light is a Grove card")
	dreams.grove_cards.clear()
	dreams.build_run_pool(7)
	var before := dreams.run_pool.keys().filter(func(id) -> bool: return id != locked)
	_check(not dreams.run_pool.has(locked), "not carried: not in the pool")
	dreams.grove_cards.assign([locked])
	dreams.build_run_pool(7)
	_check(dreams.run_pool.has(locked), "carried: always in the run's pool")
	var after := dreams.run_pool.keys().filter(func(id) -> bool: return id != locked)
	before.sort()
	after.sort()
	_check(before == after, "...on top of the draw: the same start cards as without it (%d vs %d)" % [before.size(), after.size()])

	# Freshly planted: the first offer holds it, once
	dreams.fresh_grove_cards.assign([locked])
	var first := dreams.make_offer(10)
	_check(first.any(func(c: UpgradeData) -> bool: return c.id == locked), "a freshly planted card is in the first offer")
	var shown_again := false
	for i in 6:
		dreams.stacks.erase(locked)
		var offer := dreams.make_offer(15 + i * 5)
		if offer.any(func(c: UpgradeData) -> bool: return c.id == locked) and dreams._fresh_shown == false:
			shown_again = true
	_check(dreams._fresh_shown and not shown_again, "...only once a run")
	_check(bool(dreams.to_save().get("fresh_shown", false)), "...saved with the run")

	print("test_grove_pool: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	main.queue_free()
	await process_frame
	quit(failures)
