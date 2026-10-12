extends SceneTree

var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func _fixture(id: String, family: bool) -> UpgradeData:
	var c := UpgradeData.new()
	c.id = id
	c.rarity = UpgradeData.Rarity.UNCOMMON
	c.tags.assign(["defining"])
	if family:
		c.requires.assign(["sporeling"])
	return c
func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	var dreams: DreamState = main.get_node("%DreamState")
	dreams.unlock_everything = true
	var first := _fixture("first_role_fixture", true)
	var second := _fixture("second_role_fixture", true)
	var third := _fixture("third_role_fixture", true)
	var plain := _fixture("generic_role_fixture", false)
	dreams.pool.assign([second, plain])
	var second_seen := false
	for seed_value in 40:
		dreams._rng.seed = seed_value
		if dreams._draw_card(1, [first], false) == second:
			second_seen = true
	_check(second_seen, "a second family mechanic can compete in an offer")
	dreams.pool.assign([third, plain])
	for seed_value in 40:
		dreams._rng.seed = seed_value
		_check(dreams._draw_card(1, [first, second], false) == plain, "two family cards retain space for a generic choice")
	dreams.pool.assign([first, second, third, plain])
	var plain_first := false
	var family_first := false
	for seed_value in 40:
		dreams._rng.seed = seed_value
		var card := dreams._draw_card(1, [], false)
		plain_first = plain_first or card == plain
		family_first = family_first or dreams.is_family_card(card)
	_check(plain_first and family_first, "no guaranteed family slot replaces random drawing")
	print("Dream prototype offers: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	paused = false
	main.queue_free()
	for i in RunSaver.QUIT_FRAMES:
		await process_frame
	quit(failures)
