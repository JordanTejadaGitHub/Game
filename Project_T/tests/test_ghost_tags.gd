extends SceneTree

# Headless test: the build ghost's tags (cost, reasons, chips) hang from the hovered cell, never the map's top left
# (user: "text at the top left of the map when placing Wardens"; WorldLabel.draw_tag sets its own transform, so the
# tags must be drawn at the ghost's position, not at 0 under a draw_set_transform). Run from the project folder:
#   godot --headless --path . --script res://tests/test_ghost_tags.gd --fixed-fps 60

const CELL := 64.0

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	for id in ["sprout", "sporeling", "pebbling"]:
		placer.select_tower(load("res://resource/tower/%s.tres" % id))
		for cell in [Vector2(10, 9), Vector2(18, 4), Vector2(4, 14)]:
			placer._hover_cell = cell
			var at := placer.to_global(placer.ghost_tag_origin())
			var want := Tower.footprint_centre(cell, placer.tower_data.footprint)
			_check(at.distance_to(want) < 1.0, "%s at %s: the tags hang from the ghost (%s, want %s)" % [id, cell, at, want])
			_check(at.length() > CELL * 2.0, "%s at %s: not at the map's top left" % [id, cell])
	print("ghost tags test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
