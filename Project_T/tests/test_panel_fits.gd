extends SceneTree

# Headless test for the Warden panel staying on screen (screens_ui.md "The Warden panel never fills the
# screen"; the "can't upgrade my Warden" bug): with a Sprout selected (Grow options, Nurture, Sell) and
# many Dreams taken, every action button is inside the viewport at 1920×1080, 1280×800 and 1280×720.
# Run from the project folder:
#   godot --headless --path . --script res://tests/test_panel_fits.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var dreams: DreamState = main.get_node("%DreamState")
	var map = main.get_node("%MapGenerator")
	var panel: Node = main.find_child("WardenPanel", true, false)
	main.get_node("%RunState").dew = 10000
	dreams.unlock_everything = true
	var taken := 0
	for card in dreams.pool:  # A long run's worth of Dreams (long "Dreams on this Warden" rows)
		if taken < 16 and card.rarity == UpgradeData.Rarity.COMMON and card.requires.is_empty():
			dreams.take(card)
			taken += 1
	placer.tower_data = load("res://resource/tower/sprout.tres")
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var sprout: Tower = null
	for i in range(3, route.size()):
		for off in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			if sprout == null and map.is_buildable(route[i] + off) and placer._try_build(route[i] + off):
				var towers: Node = main.get_node("%TowerContainer")
				sprout = towers.get_child(towers.get_child_count() - 1)
	_check(sprout != null, "planted a Sprout")
	for case in [[Vector2i(1920, 1080), 1.0], [Vector2i(1280, 800), 1.0], [Vector2i(1280, 720), 1.0], [Vector2i(1920, 1080), 1.5]]:
		var screen: Vector2i = case[0]
		root.size = screen
		root.content_scale_factor = case[1]  # UI scale (UiStyle.apply_ui_scale): 1.5 is the largest at 1080p
		seller.select(null)
		await process_frame
		seller.select(sprout)
		for i in 4:
			await process_frame
		var view: Rect2 = panel.get_viewport().get_visible_rect()
		var buttons: Array = panel.find_children("*", "Button", true, false).filter(func(b: Button) -> bool:
			return b.is_visible_in_tree() and (b.text.begins_with("Grow") or b.text.begins_with("Nurture")
				or b.text.begins_with("Sell") or b.text == "Close"))
		_check(buttons.any(func(b: Button) -> bool: return b.text.begins_with("Grow")) and buttons.any(func(b: Button) -> bool: return b.text.begins_with("Sell")),
			"%s: Grow and Sell buttons are there (%s)" % [screen, buttons.map(func(b: Button) -> String: return b.text)])
		for b in buttons:
			var rect: Rect2 = b.get_global_rect()
			_check(view.encloses(rect), "%s: \"%s\" is on screen (%s in %s)" % [screen, b.text, rect, view])
		var panel_rect: Rect2 = panel.get_global_rect()
		_check(view.encloses(panel_rect), "%s: the whole panel is on screen (%s)" % [screen, panel_rect])
	print("panel fits test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
