extends SceneTree

# Headless test: a click on a hit number selects its Warden (screens_ui.md "Damage that means
# something"; DamageLog.number_at → DriftMeter.focus_tower). Never touches the player's saves.
#   godot --headless --path . --script res://tests/test_damage_numbers.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	var log := main.get_node("%DamageLog") as DamageLog
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	main.get_node("%RunState").dew = 10000
	placer.tower_data = load("res://resource/tower/sporeling.tres")
	var map_generator = main.get_node("%MapGenerator")
	var cell := Vector2.ZERO
	for x in range(2, 20):
		for y in range(2, 15):
			if cell == Vector2.ZERO and map_generator.is_buildable(Vector2(x, y)) and placer._try_build(Vector2(x, y)):
				cell = Vector2(x, y)
	var tower: Tower = seller.get_tower_at(cell)
	_check(tower != null, "a Sporeling is planted")
	seller.set_selection([])
	var number := DamageLog.FloatingNumber.new(Vector2(300, 300), 42, Color.WHITE, 14)
	number.source = tower
	log.add_child(number)
	_check(log.number_at(Vector2(300, 295)) == number, "a point on the number finds it")
	_check(log.number_at(Vector2(400, 400)) == null, "a point away from it finds nothing")
	DriftMeter.focus_tower(log.number_at(Vector2(300, 295)).source)
	_check(seller.selected == tower, "focusing the number's Warden selects it")
	tower.queue_free()
	await process_frame
	_check(log.number_at(Vector2(300, 295)) == null, "a sold Warden's number isn't clickable")
	print("damage numbers test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
