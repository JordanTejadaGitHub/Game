extends SceneTree

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _card(id: String, rarity: UpgradeData.Rarity, act: int = 1) -> UpgradeData:
	var card := UpgradeData.new()
	card.id = id
	card.rarity = rarity
	card.min_act = act
	return card

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	var dreams: DreamState = main.get_node("%DreamState")
	dreams.unlock_everything = true
	dreams.pool.clear()
	var lucid := _card("lucid_fixture", UpgradeData.Rarity.LEGENDARY)
	lucid.rule_id = &"lucid_dreaming"
	dreams.pool.append(lucid)
	dreams.stacks = {lucid.id: 1}
	for i in 8:
		dreams.pool.append(_card("reroll_fixture_%d" % i, UpgradeData.Rarity.UNCOMMON))
	dreams.current_offer_drift = 30
	dreams._before_offer = dreams._offer_counters()
	dreams.current_offer = dreams.make_offer(30)
	_check(dreams.picks_left == 2, "Lucid begins with two picks")
	dreams.choose(dreams.current_offer[0])
	_check(dreams.picks_left == 1 and dreams.is_offering(), "one Lucid pick remains after choosing")
	var taken := dreams._taken_this_offer.duplicate()
	dreams.rerolls_left = 1
	_check(dreams.reroll(), "reroll remains available after the first Lucid pick")
	_check(dreams.picks_left == 1, "reroll preserves the remaining Lucid pick")
	_check(dreams._taken_this_offer == taken, "reroll retains cards already chosen in this Dream")
	dreams.choose(dreams.current_offer[0])
	_check(not dreams.is_offering(), "the final allowed pick closes the rerolled Dream")

	dreams.stacks.clear()
	dreams.pool.clear()
	dreams._banished.clear()
	var removed := _card("boss_removed", UpgradeData.Rarity.RARE)
	var next_act := _card("boss_next_act", UpgradeData.Rarity.RARE, 2)
	dreams.pool.assign([removed, next_act])
	dreams.current_offer.assign([removed])
	dreams.current_offer_drift = 25
	dreams.banishes_left = 1
	_check(dreams.banish(removed), "boss card can be banished")
	_check(dreams.current_offer.has(next_act), "boss banish uses next-act eligibility")

	var common := _card("boss_common", UpgradeData.Rarity.COMMON)
	var rare := _card("boss_rare", UpgradeData.Rarity.RARE)
	for seed_value in 24:
		dreams._banished.clear()
		dreams.pool.assign([removed, common, rare])
		dreams.current_offer.assign([removed])
		dreams.current_offer_drift = 25
		dreams.banishes_left = 1
		dreams._rng.seed = seed_value
		dreams.banish(removed)
		_check(dreams.current_offer.has(rare), "boss banish remains Rare+ (seed %d)" % seed_value)
	print("Dream offer reliability: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	paused = false
	main.queue_free()
	for i in RunSaver.QUIT_FRAMES:
		await process_frame
	quit(failures)
