extends SceneTree

# Tower Code's profiler for the Wardens' _process (mobile perf pass, documentation/mobile_plan.md): the board of
# tests/test_perf_stress.gd (every buildable cell filled, 150 nightmares along the route), then each Warden's
# _process is called by hand and timed, summed per Warden kind. Not a test (no pass / fail). Run:
#   godot --headless --path . --script res://tools/perf/prof_wardens.gd --fixed-fps 60

const MAP_SEED := 42
const NIGHTMARES := 150
const WARMUP := 60
const FRAMES := 300
const CARDS := ["root_network", "seedfall", "heart_of_the_maze", "solitude", "thinning_the_herd"]
const MIX := ["sprout", "sprout", "sprout", "sporeling", "firefly_jar", "dewdrop", "pebbling", "acorn", "rootling"]

var main: Node
var map
var spawner
var container: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = MAP_SEED
	root.add_child(main)
	await process_frame
	map = main.get_node("%MapGenerator")
	spawner = main.get_node("%EnemyContainer")
	container = main.get_node("%TowerContainer")
	_fill_map()
	_spawn_spread()
	await process_frame
	var towers: Array = container.get_children().filter(func(t) -> bool: return t is Tower)
	for t in towers:
		t.set_process(false)
	var per_kind := {}  # id -> [usec, count]
	var delta := 1.0 / 60.0
	var total := 0
	for frame in WARMUP + FRAMES:
		await process_frame
		for t in towers:
			if not is_instance_valid(t):
				continue
			var start := Time.get_ticks_usec()
			t._process(delta)
			var spent := Time.get_ticks_usec() - start
			if frame >= WARMUP:
				var id: String = t.tower_data.get_id()
				var row: Array = per_kind.get(id, [0, 0])
				row[0] += spent
				row[1] += 1
				per_kind[id] = row
				total += spent
	print("  %d Wardens, %d frames: %.2f ms a frame in Tower._process" % [towers.size(), FRAMES, total / 1000.0 / FRAMES])
	var ids := per_kind.keys()
	ids.sort_custom(func(a, b) -> bool: return per_kind[a][0] > per_kind[b][0])
	for id in ids:
		var row: Array = per_kind[id]
		var count: int = row[1] / FRAMES
		print("    %-14s x%3d  %6.3f ms a frame  %5.1f us each" % [id, count, row[0] / 1000.0 / FRAMES, float(row[0]) / row[1]])
	quit(0)

func _fill_map() -> void:
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var dreams: DreamState = main.get_node("%DreamState")
	var run_state: RunState = main.get_node("%RunState")
	dreams.unlock_everything = true
	run_state.dew = 10000000
	run_state.invulnerable = true
	for card in dreams.pool:
		if CARDS.has(card.id):
			dreams.take(card)
	var planted := 0
	for y in Tower.MAP_GRID.size.y:
		for x in Tower.MAP_GRID.size.x:
			var cell := Vector2(x, y)
			if not map.is_buildable(cell) or not map.can_block(cell):
				continue
			placer.tower_data = load("res://resource/tower/%s.tres" % MIX[planted % MIX.size()])
			if placer._try_build(cell):
				planted += 1

func _spawn_spread() -> void:
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var shade: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	for i in NIGHTMARES:
		spawner.spawn_enemy(shade, 200.0)
		var enemy = spawner.get_child(spawner.get_child_count() - 1)
		var at := int(float(i) / NIGHTMARES * (route.size() - 2))
		enemy.position = Tower.MAP_GRID.calculate_map_position(route[at])
		enemy._path_index = at + 1
		enemy.unkillable = true
		enemy.loops_route = true
