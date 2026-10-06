extends SceneTree

# Headless test for Tower Code's hooks of "Fewer, bigger cards" (dream_design.md de439ea8; Balancing e32b882d):
# Glinting Dew (every 5th attack crits), Lantern Glow (+15% hits), First Frost (first 5 of a drift Held 1.5 s),
# Briar Trap (each Thornwall holds the first walker beside it each drift), Thorny Walls (a wall lashes a walker beside it
# every 2 s for 5) and Live Wire (a Charged bolt jumps once to a second nightmare). Cards are made here with the rule
# ids (Roguelite Code owns the real card data). Run from the project folder:
#   godot --headless --path . --script res://tests/test_card_hooks.gd --fixed-fps 60

var failures := 0
var main: Node
var dreams: DreamState
var placer: TowerPlacer
var spawner: Node
var map: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_card_hooks_%d.json" % OS.get_process_id()
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	dreams = main.get_node("%DreamState")
	placer = main.get_node("%TowerPlacer")
	spawner = main.get_node("%EnemyContainer")
	map = main.get_node("%MapGenerator")
	dreams.unlock_everything = true
	main.get_node("%RunState").dew = 100000
	for child in spawner.get_children():
		child.queue_free()
	await process_frame
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var cells := Tower.route_cells(route)
	var beside := _beside_route(cells)

	# Glinting Dew: the 5th attack crits, the 4th doesn't.
	var spore := _plant("sporeling", beside)
	var target := _walker(cells[cells.size() / 2])
	_take(&"glinting_dew")
	spore._attack_count = 4
	var dealt: Array = []
	spore.crit_landed.connect(func(_t, _e) -> void: dealt.append(1))
	spore.hit(target)
	_check(dealt.is_empty(), "the 4th attack is a plain hit")
	spore._attack_count = 5
	spore.hit(target)
	_check(dealt.size() == 1, "the 5th attack crits (Glinting Dew)")
	_clear_cards()

	# Lantern Glow: +15% on a Warden's hits.
	var before: float = target.health
	spore._attack_count = 1
	spore.hit(target, 1.0, false, Tower.NO_CRIT)
	var plain: float = before - target.health
	_take(&"lantern_glow")
	before = target.health
	spore.hit(target, 1.0, false, Tower.NO_CRIT)
	var glowing: float = before - target.health
	_check(plain > 0.0 and absf(glowing / plain - 1.15) < 0.02, "Lantern Glow: hits +15%% (%.2f -> %.2f)" % [plain, glowing])
	_clear_cards()
	spore.queue_free()
	target.queue_free()
	await process_frame

	# First Frost: the first 5 nightmares a Warden meets this drift are Held, the 6th isn't, bosses never.
	_take(&"first_frost")
	var frost := _plant("sporeling", beside)
	var walkers: Array = []
	for i in 6:
		walkers.append(_walker(_near_route(cells, frost.cell)))
	Tower._frost_drift = -1
	frost._card_tick = 0.0
	frost._update_card_watch(0.01)
	var held := walkers.filter(func(w) -> bool: return w.statuses.is_held()).size()
	_check(held == Tower.FROST_COUNT, "First Frost: %d of 6 Held (first 5)" % held)
	_clear_cards()
	frost.queue_free()
	for w in walkers:
		w.queue_free()
	await process_frame

	# Briar Trap: a Thornwall holds the first walker beside it once a drift; Thorny Walls lash it.
	_take(&"thorn_snare")
	_take(&"thorny_walls")
	var wall := _plant("thornwall", beside)
	var passer := _walker(wall.cell)
	passer.global_position = wall.global_position + Vector2(48, 0)  # Beside it
	var hp: float = passer.health
	wall._wall_tick = 0.0
	wall._thorny_left = 0.0
	wall._update_wall(0.01)
	_check(passer.statuses.is_held(), "Briar Trap: the first walker beside the wall is Held")
	_check(passer.health < hp, "Thorny Walls: the wall lashes it (%.1f -> %.1f)" % [hp, passer.health])
	var second := _walker(wall.cell)
	second.global_position = wall.global_position + Vector2(-48, 0)
	wall._wall_tick = 0.0
	wall._update_wall(0.01)
	_check(not second.statuses.is_held(), "only the first one this drift")
	_clear_cards()
	wall.queue_free()
	passer.queue_free()
	second.queue_free()
	await process_frame

	# Live Wire: a Charged bolt also strikes the nearest other nightmare at full damage.
	_take(&"live_wire")
	var a := _walker(cells[cells.size() / 2])
	var b := _walker(cells[cells.size() / 2])
	b.global_position = a.global_position + Vector2(40, 0)
	var b_before: float = b.health
	Reactions.strike_bolt(a, 20.0, null)
	_check(b.health < b_before, "Live Wire: the bolt jumps to a second nightmare (%.1f -> %.1f)" % [b_before, b.health])
	_clear_cards()

	print("card hooks test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _take(rule: StringName) -> void:
	var card := UpgradeData.new()
	card.id = String(rule) + "_test"
	card.rule_id = rule
	card.display_name = String(rule)
	dreams.pool.append(card)
	dreams.take(card)

func _clear_cards() -> void:
	dreams.stacks.clear()
	dreams.bump_board()

func _plant(id: String, at: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = at
	tower.position = Tower.MAP_GRID.calculate_map_position(at)
	placer.tower_container.add_child(tower)
	tower.set_process(false)
	return tower

func _walker(cell: Vector2) -> Node2D:
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"), 50.0)
	var e = spawner.get_child(spawner.get_child_count() - 1)
	e.set_process(false)
	e.global_position = Tower.MAP_GRID.calculate_map_position(cell)
	return e

func _beside_route(cells: PackedVector2Array) -> Vector2:
	for c in cells.slice(4, cells.size() - 4):
		for side in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			if not cells.has(c + side) and map.is_buildable(c + side):
				return c + side
	return Vector2(5, 5)

func _near_route(cells: PackedVector2Array, near: Vector2) -> Vector2:
	var best := cells[0]
	for c in cells:
		if c.distance_to(near) < best.distance_to(near):
			best = c
	return best

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + what)
