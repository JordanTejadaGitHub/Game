extends SceneTree

# Headless test for "Pick any card" (demo_scope.md): in a dev run of a debug build, the Dream screen's
# "Dev: any card…" opens a grid of every Dream card with filters and "needs …" notes; taking one is
# this Dream's pick; the Remember screen's "Dev: unlock free" unlocks forms without Dreamlight.
#   godot --headless --path . --script res://tests/test_dev_cards.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	TestGrove.force_on = true  # A dev run
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	var dreams: DreamState = main.get_node("%DreamState")
	_check(DreamState.dev_tools_on(), "dev tools are on in a dev run of a debug build")

	# The Dream screen's button and the grid
	dreams.unlock_everything = false
	dreams.unlocked = {"sprout": true, "thornwall": true, "sporeling": true}
	dreams.current_offer = dreams.make_offer(10)
	dreams.offer_ready.emit(dreams.current_offer, 10)
	await process_frame
	var screen = main.get_node("HUD/DreamScreen")
	_check(screen._dev_any.visible, "the Dream screen shows \"Dev: any card…\"")
	var picker := DevCardPicker.open(screen, dreams, dreams.choose_any)
	await process_frame
	var all := picker.matching()
	_check(all.size() >= DreamState.load_pool().size(), "the grid lists every card (%d)" % all.size())
	var grove_card: UpgradeData = null
	for card in all:
		if not card.in_start_pool and card.rarity == UpgradeData.Rarity.LEGENDARY:
			grove_card = card
			break
	_check(grove_card != null and dreams.needs_note(grove_card, 1).begins_with("not normally offered: needs"),
		"a Grove Legendary says what it needs (%s)" % (dreams.needs_note(grove_card, 1) if grove_card else "none"))
	picker._rarity.select(UpgradeData.Rarity.LEGENDARY + 1)
	_check(picker.matching().all(func(c: UpgradeData) -> bool: return c.rarity == UpgradeData.Rarity.LEGENDARY),
		"the rarity filter")
	picker._rarity.select(0)
	picker._search.text = grove_card.display_name
	_check(picker.matching().has(grove_card), "the name search")
	# Taking it is this Dream's pick
	picker.on_pick.call(grove_card)
	picker.queue_free()
	_check(dreams.has_card(grove_card.id) and not dreams.is_offering(), "taking it counts as this Dream's pick")

	# Remember: Dev: unlock free
	var remember := main.get_node("%RememberScreen") as RememberScreen
	var sporeling: TowerData = load("res://resource/tower/sporeling.tres")
	dreams.add_dreamlight(-dreams.dreamlight)
	remember.open(sporeling)
	_check(remember._dev_free.visible, "Remember shows \"Dev: unlock free\"")
	var final_form: TowerData = sporeling.evolves_to[0].evolves_to[0]
	_check(dreams.dev_unlock(final_form) and dreams.is_unlocked(final_form.get_id()) and dreams.dreamlight == 0,
		"dev unlock: a final form, no Dreamlight, no branch needed")
	remember.close()
	TestGrove.force_on = false
	print("dev cards test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
