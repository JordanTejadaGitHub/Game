extends SceneTree

# Regression / stress test for a reported crash tied to the Fairy Ring: rings on path tiles while
# the path re-routes, the Warden is sold / evolved, a Graftling copies it, nightmares are dispelled,
# split, and the field is cleared, and the run is saved. It passes if the run survives with no script
# errors from the ring code. Run from the project folder:
#   godot --headless --path . --script res://tests/test_fairy_ring_stress.gd --fixed-fps 60

const CELL := 64.0
const RUN_SECONDS := 40.0

var failures := 0
var main: Node
var placer: TowerPlacer
var seller: TowerSeller
var spawner
var map_generator
var container: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	placer = main.get_node("%TowerPlacer")
	seller = main.get_node("%TowerSeller")
	spawner = main.get_node("%EnemyContainer")
	map_generator = main.get_node("%MapGenerator")
	container = main.get_node("%TowerContainer")
	var dreams: DreamState = main.get_node("%DreamState")
	var run_state: RunState = main.get_node("%RunState")
	dreams.unlock_everything = true
	run_state.dew = 100000
	run_state.invulnerable = true if "invulnerable" in run_state else false
	paused = false

	var ring := _build("fairy_ring")
	var circle := _build("elf_circle")
	_build("dewdrop")
	_build("rain_lily")
	_build("tangleroot")
	_build("bellflower")
	var graft := _build_beside(ring, "graftling")
	_check(ring != null and circle != null, "planted the ring Wardens")

	var enemies := ["leaf_bug", "bark_beetle", "mother_duck"]
	var time := 0.0
	var step := 0
	var saver = main.get_node("%RunSaver")
	while time < RUN_SECONDS:
		# Keep nightmares coming, including ones that split and lead followers.
		if step % 20 == 0:
			for id in enemies:
				var path := "res://resource/enemy/%s.tres" % id
				if ResourceLoader.exists(path):
					spawner.spawn_enemy(load(path), 3.0)
		# Every few seconds: re-route (plant or sell a wall), evolve / sell ring Wardens, clear the field.
		match step % 240:
			40:
				_build("thornwall")
			80:
				var walls := container.get_children().filter(func(t) -> bool: return t is Tower and t.tower_data.get_id() == "thornwall")
				if not walls.is_empty():
					seller.sell(walls[0].cell)
			120:
				if is_instance_valid(ring) and ring.tower_data.get_id() == "fairy_ring":
					placer.evolve(ring, load("res://resource/tower/elf_circle.tres"))
			160:
				if is_instance_valid(circle):
					seller.sell(circle.cell)  # Its rings go with it
				circle = _build("fairy_ring")
			200:
				for enemy in spawner.get_enemies():
					if is_instance_valid(enemy) and not enemy.is_cleansed:
						enemy.dispel()
			220:
				if saver and saver.has_method("save_now"):
					saver.file_path = OS.get_temp_dir().path_join("fairy_ring_stress.json") if "file_path" in saver else ""
					saver.save_now()
		await process_frame
		time += 1.0 / 60.0
		step += 1
	# The regression itself: once a ring is freed (burst, faded, or its Warden changed), the Warden's
	# ring list must drop it. The old typed filter errored every frame and kept the freed ring.
	var tester := _build("fairy_ring")
	if tester != null:
		tester.set_process(false)
		var planted := FairyRing.new(tester, tester.cell + Vector2(1, 0))
		tester.add_child(planted)
		tester._rings.append(planted)
		planted.free()
		tester._cooldown = 0.0
		tester._attack_time = -1.0
		tester._process(1.0 / 60.0)  # The reported path: _process -> _has_work
		_check(tester._rings.is_empty(), "a freed ring is dropped from the Warden's list (%d left)" % tester._rings.size())
	var rings := 0
	for tower in container.get_children():
		if tower is Tower:
			rings += tower.get_children().filter(func(n) -> bool: return n is FairyRing).size()
	print("fairy ring stress: %d s, %d rings out, graftling %s" % [RUN_SECONDS, rings,
		graft.attack_data.display_name if is_instance_valid(graft) else "gone"])
	print("fairy ring stress test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _build(id: String) -> Tower:
	var data: TowerData = load("res://resource/tower/%s.tres" % id)
	var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	for i in range(3, path.size() - 3):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = path[i] + offset
			if path.has(cell) or not map_generator.can_block(cell):
				continue
			placer.tower_data = data
			var count := container.get_child_count()
			if placer._try_build(cell):
				return container.get_child(count)
	return null

func _build_beside(tower: Tower, id: String) -> Tower:
	if tower == null:
		return null
	placer.tower_data = load("res://resource/tower/%s.tres" % id)
	for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(1, 1), Vector2(-1, -1)]:
		var cell: Vector2 = tower.cell + offset
		if map_generator.can_block(cell):
			var count := container.get_child_count()
			if placer._try_build(cell):
				return container.get_child(count)
	return null

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
