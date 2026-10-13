extends SceneTree

# The Jarlink link is one ground segment (the user's playtest, 2026-10-13: "the visible link doesn't match what's
# actually being hit on the path"): nightmares stood on a grid around a link take the arc's damage exactly where the
# shared function (BranchKit.on_link) says the segment covers, at whole and half offsets, horizontal, vertical and
# diagonal; the drawn arc runs along that segment; the marked path is BranchKit.link_points; a sold jar's mark goes.
#   godot --headless --path . --script res://tests/test_jarlink_link.gd --fixed-fps 60

var failures := 0
var main: Node
var placer: TowerPlacer
var spawner

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_jarlink_link_%d.json" % OS.get_process_id()
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	placer = main.get_node("%TowerPlacer")
	spawner = main.get_node("%EnemyContainer")
	var map = main.get_node("%MapGenerator")
	main.get_node("%DreamState").unlock_everything = true

	var cell := Tower.MAP_GRID.cell_size.x
	# [name, the first jar's px, the second jar's px]: whole cells and half offsets (16 / 32 px off a cell centre).
	var base := Tower.MAP_GRID.calculate_map_position(Vector2(6, 6))
	var layouts := [
		["horizontal, whole cells", base, base + Vector2(3, 0) * cell],
		["vertical, whole cells", base, base + Vector2(0, 3) * cell],
		["diagonal, whole cells", base, base + Vector2(3, 2) * cell],
		["horizontal, half offset", base + Vector2(32, 0), base + Vector2(3, 0) * cell + Vector2(32, 0)],
		["vertical, half offset", base + Vector2(0, 32), base + Vector2(0, 3) * cell + Vector2(0, 32)],
		["diagonal, half offsets", base + Vector2(32, 0), base + Vector2(2, 3) * cell + Vector2(0, 32)],
	]
	for layout in layouts:
		await _layout(layout[0], layout[1], layout[2])

	# Jars side by side make no link; a Warden standing between two jars doesn't block it.
	_check(not BranchKit.link_spans(base, base + Vector2(cell, 0)), "jars side by side make no link")
	_check(BranchKit.link_spans(base, base + Vector2(cell * 1.5, 0)), "…a half cell apart they do")

	# The standing mark: the linked pair's marked halves are the route points the link strikes; selling one removes it.
	var on_route := Tower.route_cells(map.get_path_from(map.startPath))
	var across: Array = []
	for i in range(3, on_route.size() - 3):
		for side in [Vector2.UP, Vector2.LEFT]:
			var one_side: Vector2 = on_route[i] + side
			var far_side: Vector2 = on_route[i] - side
			if across.is_empty() and not on_route.has(one_side) and not on_route.has(far_side) and map.is_buildable(one_side) and map.is_buildable(far_side):
				across = [one_side, far_side]
	_check(across.size() == 2, "found two open cells across the path")
	if across.size() == 2:
		var a := _jar(Tower.MAP_GRID.calculate_map_position(across[0]), across[0])
		var b := _jar(Tower.MAP_GRID.calculate_map_position(across[1]), across[1])
		await process_frame
		for jar in [a, b]:
			BranchKit._update_fence(jar, 0.0)
		var layer := BranchKit.FenceLayer.find(a)
		var struck := BranchKit.link_points(BranchKit.link_end(a), BranchKit.link_end(b), map.get_path_from(map.startPath))
		var want := {}
		for point in struck:
			want[FindPath.point_to_node(point)] = true
		var marked: Dictionary = layer.marked_halves()
		_check(not struck.is_empty() and marked.size() == want.size() and want.keys().all(func(h) -> bool: return marked.has(h)),
			"two linked Jarlinks: the marked path is the path the arc strikes (%d halves)" % marked.size())
		var ground: Node2D = layer.get_node_or_null("LinkGround")
		_check(ground != null and not ground.z_as_relative and ground.z_index == -1, "…drawn on the ground layer")
		a.queue_free()
		for i in 4:
			await process_frame
			if is_instance_valid(b):
				BranchKit._update_fence(b, 0.0)
		_check(layer.marked_halves().is_empty(), "one jar sold: the mark is gone")
		b.queue_free()

	print("jarlink link test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

# Two jars at `from` / `to` (px), nightmares on a 16 px grid around the link: one arc tick hits exactly those the
# shared function says the segment covers, and the drawn arc lies on that segment.
func _layout(label: String, from: Vector2, to: Vector2) -> void:
	for child in spawner.get_children():
		child.queue_free()
	await process_frame
	var a := _jar(from, Tower.MAP_GRID.calculate_grid_coordinates(from))
	var b := _jar(to, Tower.MAP_GRID.calculate_grid_coordinates(to))
	await process_frame
	var low := Vector2(minf(from.x, to.x) - 48.0, minf(from.y, to.y) - 48.0)
	var high := Vector2(maxf(from.x, to.x) + 48.0, maxf(from.y, to.y) + 48.0)
	var stood: Array = []
	var y := low.y
	while y <= high.y:
		var x := low.x
		while x <= high.x:
			var enemy: Node2D = spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
			enemy.set_process(false)
			enemy.global_position = Vector2(x, y)
			enemy.max_health = 1000000
			enemy.health = 1000000
			stood.append(enemy)
			x += 16.0
		y += 16.0
	_check(BranchKit._fence_partner(a) == b, "%s: the two jars link" % label)
	for jar in [a, b]:
		BranchKit._update_fence(jar, 0.0)  # One tick, by the side that does the work
	# The arc as it is drawn now (the layer drops a pair it isn't told about for 2 frames; these jars are frozen).
	var layer := BranchKit.FenceLayer.find(a)
	var drawn := false
	for key in layer.arcs:
		var arc: Array = layer.arcs[key]
		var mid: Vector2 = (arc[0] + arc[1]) / 2.0
		# Both drawn ends and the middle lie on the link's own segment (dead centre: inside its width with no body).
		drawn = _on_centre(arc[0], from, to) and _on_centre(arc[1], from, to) and _on_centre(mid, from, to)
	for i in 8:
		await process_frame  # A dense burst of area hits lands over a few frames (Tower's AreaHitQueue: 24 a frame)
	var wrong := 0
	var hit := 0
	for enemy in stood:
		var covered := BranchKit.on_link(enemy.global_position, BranchKit.link_end(a), BranchKit.link_end(b))
		var damaged: bool = enemy.health < 1000000
		hit += 1 if damaged else 0
		if covered != damaged:
			wrong += 1
	_check(hit > 0 and wrong == 0, "%s: exactly the nightmares the segment covers are hit (%d hit of %d, %d wrong)" % [label, hit, stood.size(), wrong])
	_check(drawn, "%s: the drawn arc runs along the same segment" % label)
	a.queue_free()
	b.queue_free()
	for enemy in stood:
		enemy.queue_free()
	await process_frame
	await process_frame
	await process_frame

func _on_centre(point: Vector2, from: Vector2, to: Vector2) -> bool:
	var seg := to - from
	var t := clampf((point - from).dot(seg) / maxf(seg.length_squared(), 1.0), 0.0, 1.0)
	return point.distance_to(from + seg * t) < 1.0

func _jar(at: Vector2, cell: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/jarlink.tres")
	tower.cell = cell
	tower.position = at
	placer.get_node("%TowerContainer").add_child(tower)
	tower.set_process(false)
	return tower

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + what)
