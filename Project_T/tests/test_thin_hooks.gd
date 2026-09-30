extends SceneTree

# Headless test for Tower Code's side of the thin-family cards (dream_design.md "Thin-family cards"):
# Called Shot (first hit on a Marked nightmare crits, once), Chorus (a Bellflower pulse pulls a ready
# neighbour of its line in, both +30%), Homing Instinct (swoops fly home faster), Long Light (lit tiles
# linger after the light moves on). Run from the project folder:
#   godot --headless --path . --script res://tests/test_thin_hooks.gd --fixed-fps 60

const CELL := 64.0

var failures := 0
var placer: TowerPlacer
var container: Node
var spawner
var dreams: DreamState

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	placer = main.get_node("%TowerPlacer")
	container = main.get_node("%TowerContainer")
	spawner = main.get_node("%EnemyContainer")
	dreams = main.get_node("%DreamState")
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

	# Called Shot.
	_take("called_shot")
	var shooter := _plant("firefly_jar", Vector2(5, 5))
	var marked := _spawn(shooter.global_position + Vector2(CELL, 0))
	marked.apply_status(EnemyStatuses.MARKED, 1, 4.0)
	var crits := [0]
	shooter.crit_landed.connect(func(_t, _e) -> void: crits[0] += 1)
	shooter.hit(marked, 1.0, false, Tower.NO_CRIT)
	shooter.hit(marked, 1.0, false, Tower.NO_CRIT)
	_check(crits[0] == 1, "Called Shot: the first hit on a Marked nightmare crits, only once (%d)" % crits[0])

	# Chorus.
	_take("chorus")
	var bell := _plant("bellflower", Vector2(10, 10))
	var partner := _plant("bellflower", Vector2(11, 10))
	var ringer := _spawn(bell.global_position + Vector2(0, CELL * 0.5))
	partner._cooldown = 0.1
	partner._attack_time = -1.0
	var released := [0]
	partner.attack_released.connect(func(_t) -> void: released[0] += 1)
	bell._release()
	_check(released[0] == 1 and partner._cooldown > DreamState.CHORUS_SYNC_WINDOW, "Chorus: a ready Bellflower nearby pulses with it")
	partner._cooldown = 5.0
	released[0] = 0
	bell._release()
	_check(released[0] == 0, "one that isn't ready stays out")
	ringer.queue_free()

	# Homing Instinct.
	_take("homing_instinct")
	var wren := _plant("nestling", Vector2(14, 5))
	var bird := _spawn(wren.global_position + Vector2(CELL, 0))
	wren.fire_at(bird)
	var swoops := wren.get_children().filter(func(c) -> bool: return c is Projectile)
	_check(not swoops.is_empty() and swoops[0].return_multiplier > 1.0,
		"Homing Instinct: the swoop flies home faster (%s)" % [swoops.map(func(p) -> float: return p.return_multiplier)])

	# Long Light.
	_take("long_light")
	var light := _plant("rootlight", Vector2(8, 8))
	light._lit_cells = [Vector2(1, 1)]
	light._light()
	_check(light._lit_cells.has(Vector2(1, 1)), "Long Light: a tile the light moved on from stays lit")
	light._anim_time += 10.0
	light._light()
	_check(not light._lit_cells.has(Vector2(1, 1)), "…for a while, not forever")

	print("thin hooks test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _take(id: String) -> void:
	for card in dreams.pool:
		if card.id == id:
			dreams.take(card)
			return
	failures += 1
	printerr("FAIL: no card " + id)

func _plant(id: String, cell: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = cell
	tower.position = cell * CELL + Vector2(CELL, CELL) / 2
	container.add_child(tower)
	tower.set_process(false)
	return tower

func _spawn(at: Vector2) -> Node2D:
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	var enemy = spawner.get_child(spawner.get_child_count() - 1)
	enemy.set_process(false)
	enemy.global_position = at
	enemy.max_health = 1000000
	enemy.health = 1000000
	return enemy

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
