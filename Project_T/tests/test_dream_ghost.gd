extends SceneTree

# Headless test for the build ghost's Dream bonuses (screens_ui.md "Dream bonuses on Wardens", Build
# ghost and On the map), with Solitude: the ghost's range includes the card's +0.5, a chip says
# whether it would be on and why not, planted Wardens it would switch off are listed, and Wardens
# with an active position card get a badge in build mode or while selected. Run from the project
# folder:
#   godot --headless --path . --script res://tests/test_dream_ghost.gd --fixed-fps 60

const CELL := 64.0

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var container: Node = main.get_node("%TowerContainer")
	var dreams: DreamState = main.get_node("%DreamState")
	dreams.unlock_everything = true
	for card in dreams.pool:
		if card.id == "solitude":
			dreams.take(card)
	_check(dreams.has_rule(&"solitude"), "Solitude taken")

	var sprout: TowerData = load("res://resource/tower/sprout.tres")
	placer.select_tower(sprout)
	var open := _open_cell(main.get_node("%MapGenerator"), container)
	placer._hover_cell = open
	placer._refresh_hover()
	var chips := placer.get_ghost_chips()
	_check(chips.size() == 1 and chips[0][1] and chips[0][0].begins_with("Solitude ✓"),
		"alone: a green Solitude chip (%s)" % [chips])
	_check(is_equal_approx(placer._range_gain, DreamState.SOLITUDE_RANGE), "the ghost's range gains +0.5 there")

	# Plant a Warden right there, then hover next to it: the ghost's chip is off, with the reason, and
	# the planted Warden would lose Solitude.
	var planted: Tower = placer.tower_scene.instantiate()
	planted.tower_data = sprout
	planted.cell = open
	planted.position = Tower.MAP_GRID.calculate_map_position(open)
	container.add_child(planted)
	planted.set_process(false)
	await process_frame
	planted._refresh_neighbours()
	placer._hover_cell = open + Vector2(1, 0)
	placer._refresh_hover()
	chips = placer.get_ghost_chips()
	_check(chips.size() == 1 and not chips[0][1] and chips[0][0].contains("Sprout"),
		"next to it: a grey chip saying why (%s)" % [chips])
	_check(is_equal_approx(placer._range_gain, 0.0), "and no range gain")
	var changes := placer.get_neighbour_changes()
	_check(changes.size() == 1 and changes[0][0] == planted and changes[0][1] == "Solitude" and not changes[0][2],
		"the planted Sprout would lose Solitude (%s)" % [changes])

	# Badges: the planted Sprout has Solitude on; its badge shows in build mode or while selected.
	_check(planted.get_badge_cards().size() == 1, "the planted Warden's active position card is known")
	_check(Tower.badges_visible(), "badges show in build mode")
	placer.set_build_mode(false)
	_check(not Tower.badges_visible(), "hidden outside build mode with nothing selected")
	seller.select(planted)
	_check(Tower.badges_visible(), "and shown while a Warden is selected")
	seller.select(null)

	# Heart of the Maze: the ghost says when the Warden planted there would become the heart (the one
	# furthest along the route from every other attacker).
	for card in dreams.pool:
		if card.id == "heart_of_the_maze":
			dreams.take(card)
	var map_generator = main.get_node("%MapGenerator")
	var route: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	var near_planted: Vector2 = planted.cell + Vector2(0, 1)
	var far_cell := Vector2(-1, -1)
	for i in range(route.size() - 3, 0, -1):  # A buildable cell beside the far end of the route
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var c: Vector2 = route[i] + offset
			if not route.has(c) and map_generator.can_block(c) and c.distance_to(planted.cell) > 6.0:
				far_cell = c
				break
		if far_cell != Vector2(-1, -1):
			break
	placer.set_build_mode(true)
	placer.select_tower(sprout)
	_check(placer.becomes_heart(far_cell, map_generator.get_path_if_blocked_cells([far_cell])),
		"far along the route from the other Warden: it becomes the Heart of the Maze")
	placer._hover_cell = far_cell
	placer._refresh_hover()
	_check(placer._heart_here, "and the ghost tag says so")
	var wall: TowerData = load("res://resource/tower/thornwall.tres")
	placer.select_tower(wall)
	_check(not placer.becomes_heart(far_cell, map_generator.get_path_if_blocked_cells([far_cell])), "a Thornwall never does")
	placer.select_tower(sprout)
	var second: Tower = placer.tower_scene.instantiate()
	second.tower_data = sprout
	second.cell = far_cell
	second.position = Tower.MAP_GRID.calculate_map_position(far_cell)
	container.add_child(second)
	second.set_process(false)
	_check(not placer.becomes_heart(near_planted, map_generator.get_path_if_blocked_cells([near_planted])),
		"right next to another Warden: it doesn't")

	print("dream ghost test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

# A free cell with nothing within 3 cells (so Solitude would be on), away from the route.
func _open_cell(map_generator, container: Node) -> Vector2:
	var route: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	for y in range(2, Tower.MAP_GRID.size.y - 2):
		for x in range(2, Tower.MAP_GRID.size.x - 3):
			var cell := Vector2(x, y)
			if route.has(cell) or not map_generator.is_buildable(cell) or not map_generator.is_buildable(cell + Vector2(1, 0)):
				continue
			if container.get_children().any(func(t) -> bool: return t is Tower and maxf(absf(t.cell.x - x), absf(t.cell.y - y)) <= 3):
				continue
			return cell
	return Vector2(3, 3)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
