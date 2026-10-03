extends SceneTree

# Headless test for branch expansion Phase 2 (tower_design.md "The new branches": Pebbling, Rootling, Acorn; BranchKit).
# Whetstone finishes worn-down nightmares and Edgestone spills the overkill; Rampart grows with its walls and turns them
# to stone (no trampling), Bastion drops rocks; Quaker stops sprints and Earthshaker cracks the path; Groundroot
# grounds flyers; Deeproot roots near the Heartwood and Heartroot drags the first leak back; Thorncoil's thorns hurt held
# nightmares and Crown spreads them; Nurse Log cheapens Nurture and Mother Log remembers a sold rank; Seedbearer's
# seeds become free Sprouts beside it (Grove Keeper's at rank II); Dream Oak gathers shards from a mixed grove. Run from
# the project folder:
#   godot --headless --path . --script res://tests/test_branch_phase2.gd --fixed-fps 60

const CELL := 64.0
const BRANCHES := {"pebbling": ["whetstone", "rampart", "quaker"], "rootling": ["groundroot", "deeproot", "thorncoil"],
	"acorn": ["seedbearer", "nurse_log", "dream_oak"]}
const FINALS := {"whetstone": "edgestone", "rampart": "bastion", "quaker": "earthshaker", "groundroot": "earthbind",
	"deeproot": "heartroot", "thorncoil": "crown_of_thorns", "seedbearer": "grove_keeper", "nurse_log": "mother_log",
	"dream_oak": "dreamroot"}

var failures := 0
var main: Node
var spawner: Node
var placer: TowerPlacer
var seller: TowerSeller
var container: Node
var map: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	Kinships.force_full = true
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	paused = false
	spawner = main.get_node("%EnemyContainer")
	placer = main.get_node("%TowerPlacer")
	seller = main.get_node("%TowerSeller")
	container = main.get_node("%TowerContainer")
	map = main.get_node("%MapGenerator")
	main.get_node("%DreamState").unlock_everything = true
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

	_test_data()
	await _test_whetstone()
	await _test_rampart()
	await _test_quaker()
	await _test_groundroot()
	await _test_deeproot()
	await _test_thorncoil()
	await _test_logs()
	await _test_seedbearer()
	await _test_dream_oak()

	print("branch phase 2 test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	Kinships.force_full = false
	main.queue_free()
	await process_frame
	quit(failures)

func _test_data() -> void:
	for base_id in BRANCHES:
		var base: TowerData = load("res://resource/tower/%s.tres" % base_id)
		var ids: Array = base.evolves_to.map(func(f) -> String: return f.get_id())
		for branch in BRANCHES[base_id]:
			_check(ids.has(branch), "%s grows into %s" % [base_id, branch])
			for id in [branch, FINALS[branch]]:
				var form: TowerData = load("res://resource/tower/%s.tres" % id)
				_check(form.expansion_phase == 2 and form.special != &"", "%s: Phase 2 with a special" % id)
				_check(not form.counter_tags.is_empty() or form.role_tag != &"", "%s shows a role" % id)
				_check(ResourceLoader.exists("res://resource/dream/dream_%s.tres" % id), "%s has an unlock card" % id)
			var final: TowerData = load("res://resource/tower/%s.tres" % FINALS[branch])
			_check(final.special_final and final.evolves_to.size() == 1 and final.evolves_to[0].tier == DreamState.ASCENDED_TIER,
				"%s is a final that ascends" % FINALS[branch])
			_check(not load("res://resource/dream/dream_%s.tres" % FINALS[branch]).in_start_pool, "%s's card is not in the start pool" % FINALS[branch])
	for id in [&"fault_line", &"bramble_bed", &"nursery_bond"]:
		_check(Kinships.KINSHIPS.has(id), "Kinship %s exists" % id)

# Whetstone ×2.5 below 30% (bosses ×1.5); Edgestone spills the overkill onto the nearest nightmare.
func _test_whetstone() -> void:
	var stone := _plant("whetstone", _open_cell())
	var e = _spawn(_route_cell(4))
	e.health = e.max_health
	_check(is_equal_approx(BranchKit.hit_multiplier(stone, e), 1.0), "Whetstone: no bonus on a healthy nightmare")
	e.health = int(e.max_health * 0.2)
	_check(is_equal_approx(BranchKit.hit_multiplier(stone, e), 2.5), "Whetstone: ×2.5 below 30%")
	var boss = _spawn(_route_cell(5), "res://resource/enemy/barrow_king.tres")
	if boss != null:
		boss.health = int(boss.max_health * 0.2)
		_check(is_equal_approx(BranchKit.hit_multiplier(stone, boss), 1.5), "Whetstone: bosses ×1.5")
	await _clean()
	var edge := _plant("edgestone", _open_cell())
	var dead = _spawn(_route_cell(4))
	var next = _spawn(_route_cell(5))
	var before: int = next.health
	BranchKit.on_finish(edge, dead, 500.0)
	_check(next.health < before, "Edgestone: the overkill spills onto the next nightmare (%d -> %d)" % [before, next.health])
	await _clean()

# Rampart: +15% per wall on its sides, the walls are stone (no trample); Bastion's rock lands on the path.
func _test_rampart() -> void:
	var spot := _wall_spot()
	_check(not spot.is_empty(), "found a Rampart spot beside the path")
	if spot.is_empty():
		return
	var rampart := _plant("rampart", spot.rampart)
	var wall := _plant("thornwall", spot.wall)
	_check(is_equal_approx(BranchKit.damage_multiplier(rampart), 1.15), "Rampart: +15%% for one wall (%.2f)" % BranchKit.damage_multiplier(rampart))
	_check(BranchKit.is_stone(wall) and BranchKit.is_stone_cell(main, spot.wall), "the wall touching it is stone")
	var stag = _spawn(spot.path, "res://resource/enemy/old_stag.tres")
	if stag != null:
		spawner._on_trample_requested(stag)
		await process_frame
		_check(is_instance_valid(wall) and wall.is_inside_tree(), "a stone wall isn't trampled")
	await _clean()
	var bastion := _plant("bastion", spot.rampart)
	_plant("thornwall", spot.wall)
	var e = _spawn(spot.path)
	var before: int = e.health
	BranchKit._update_rockfall(bastion, 6.5)
	await process_frame
	await process_frame  # Area hits may land a frame later
	_check(e.health < before, "Bastion: the rock lands on the path beside the wall (%d -> %d)" % [before, e.health])
	await _clean()

# Quaker's hit ends a sprint; Earthshaker's slam cracks the path in reach.
func _test_quaker() -> void:
	var at := _route_cell(6)
	var quaker := _plant("quaker", _open_cell_near(at))
	var e = _spawn(at)
	e.rolling = true
	quaker.hit(e)
	_check(not e.rolling, "Quaker: a sprint stops")
	await _clean()
	var shaker := _plant("earthshaker", _open_cell_near(at))
	BranchKit._quake(shaker)
	var cracked := false
	for cell in shaker._route():
		cracked = cracked or BranchKit.is_cracked(main, cell)
	_check(cracked, "Earthshaker: the path in reach is cracked")
	await _clean()

# Groundroot grounds a flyer in reach.
func _test_groundroot() -> void:
	var at := _route_cell(6)
	var root_tower := _plant("groundroot", _open_cell_near(at))
	var flyer = _spawn(at, "res://resource/enemy/crow.tres")
	_check(flyer != null and flyer.is_flying(), "a flyer to ground")
	if flyer == null:
		return
	BranchKit._update_grounding(root_tower, 0.1)
	_check(flyer.has_method("is_grounded") and flyer.is_grounded() and not flyer.is_flying(), "Groundroot: the flyer walks the maze")
	await _clean()

# Deeproot roots a nightmare near the Heartwood (once); Heartroot drags the drift's first leak back.
func _test_deeproot() -> void:
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var deep := _plant("deeproot", _open_cell())
	var e = _spawn(route[route.size() - 2])
	BranchKit._update_goal_guard(deep, 0.3)
	_check(e.statuses.is_held() or e.hold_time > 0.0, "Deeproot: Rooted near the Heartwood")
	_check(e.has_meta(&"deeproot_held"), "once each")
	await _clean()
	_plant("heartroot", _open_cell())
	var leak = _spawn(route[route.size() - 1])
	leak._path_index = route.size()
	_check(BranchKit.before_goal(leak), "Heartroot: Not yet drags the first leak back")
	var second = _spawn(route[route.size() - 1])
	second._path_index = route.size()
	_check(not BranchKit.before_goal(second), "only once per drift")
	await _clean()

# Thorns on held nightmares; Crown spreads to the one beside.
func _test_thorncoil() -> void:
	var at := _route_cell(6)
	var coil := _plant("crown_of_thorns", _open_cell_near(at))
	var held = _spawn(at)
	var beside = _spawn(_route_cell(7))
	var free = _spawn(_route_cell(12))
	held.apply_status(EnemyStatuses.HELD, 1, 5.0, 0.0, 0, "root", coil)
	var held_before: int = held.health
	var beside_before: int = beside.health
	var free_before: int = free.health
	BranchKit._update_thorns(coil, 0.3)
	_check(held.health < held_before, "Thorncoil: a held nightmare takes thorns")
	_check(beside.health < beside_before, "Crown of Thorns: the nightmare beside it too")
	_check(free.health == free_before, "a free nightmare away from any held one doesn't")
	await _clean()

# Nurse Log: Nurture 25% cheaper beside it. Mother Log: a sold Warden's rank waits for the next on its cell.
func _test_logs() -> void:
	var cell := _open_cell()
	var ward := _plant("sporeling", cell)
	var price: int = ward.get_nurture_price()
	var log_tower := _plant("nurse_log", _open_cell_near(cell))
	_check(ward.get_nurture_price() == maxi(roundi(price * 0.75), 1) or ward.get_nurture_price() < price,
		"Nurse Log: Nurture cheaper beside it (%d -> %d)" % [price, ward.get_nurture_price()])
	await _clean()
	var run_state = main.get_node("%RunState")
	run_state.add_dew(5000)
	var home := _open_cell()
	var mother := _plant("mother_log", _open_cell_near(home))
	var ranked := _plant("sporeling", home)
	BranchKit._grant_ranks(ranked, 2)
	_check(ranked.rank == 2, "a rank II Warden to sell")
	map.block_cells([home])
	seller.sell(home)
	await process_frame
	_check(mother.has_meta(&"rings") and mother.get_meta(&"rings").has(home), "Mother Log remembers the rank")
	placer.select_tower(load("res://resource/tower/sporeling.tres"))
	_check(placer._try_build(home), "a new Warden on that cell")
	var fresh = seller.get_tower_at(home)
	_check(fresh != null and fresh.rank == 2, "it starts at rank II (%s)" % (fresh.rank if fresh else -1))
	await _clean()

# Seedbearer: a seed every 3 drifts, planted at the rest beside it; Grove Keeper's at rank II.
func _test_seedbearer() -> void:
	var was := Tower.resting
	Tower.resting = true
	var keeper := _plant("grove_keeper", _open_cell())
	for i in 2:
		BranchKit.on_drift_cleared(keeper)
	_check(BranchKit.seeds_ready(keeper) == 1, "Grove Keeper: a seed after 2 drifts")
	_check(placer.begin_seed_choice(keeper), "the rest: pick a cell beside it")
	var cells: Array = placer.seed_cells_open(keeper)
	var sprout: Tower = placer.plant_seed(keeper, cells[0]) if not cells.is_empty() else null
	placer.cancel_seed_choice()
	_check(sprout != null and sprout.tower_data.get_id() == "sprout" and sprout.invested_dew == 0, "a free Sprout beside it")
	_check(sprout != null and sprout.rank == 2, "Grove Keeper's Sprouts arrive at rank II")
	_check(BranchKit.seeds_ready(keeper) == 0 and BranchKit.seeds_alive(keeper) == 1, "the seed is used")
	Tower.resting = was
	await _clean()

# Dream Oak: 1 shard + 1 per different family within 2 cells.
func _test_dream_oak() -> void:
	var dreams: DreamState = main.get_node("%DreamState")
	var cell := _open_cell()
	var oak := _plant("dream_oak", cell)
	_plant("sporeling", _open_cell_near(cell))
	_plant("pebbling", _open_cell_near(cell))
	var before: int = dreams.dreamlight_shards
	var source_before: int = _source_shards(dreams)
	BranchKit.on_drift_cleared(oak)
	var gained: int = dreams.dreamlight_shards - before + _source_shards(dreams) - source_before
	_check(gained == 3, "Dream Oak: 1 + 2 families = 3 shards (%d)" % gained)
	await _clean()

func _source_shards(dreams: DreamState) -> int:
	var shards = dreams.get("source_shards")
	return int(shards.get(&"dream_oak", 0)) if shards is Dictionary else 0

# --- Helpers ---------------------------------------------------------------------------------------------------

func _route_cell(index: int) -> Vector2:
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	return route[mini(index, route.size() - 1)]

func _taken(cell: Vector2) -> bool:
	return container.get_children().any(func(t) -> bool: return t is Tower and not t.is_queued_for_deletion() and t.get_cells().has(cell))

func _open_cell() -> Vector2:
	for y in range(2, 16):
		for x in range(2, 21):
			var cell := Vector2(x, y)
			if map.is_buildable(cell) and not _taken(cell) and _neighbours_open(cell) >= 3:
				return cell
	return Vector2(3, 3)

func _neighbours_open(cell: Vector2) -> int:
	var count := 0
	for d in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		if map.is_buildable(cell + d) and not _taken(cell + d):
			count += 1
	return count

# An open cell next to `cell` (8 around), off the route.
func _open_cell_near(cell: Vector2) -> Vector2:
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	for d in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
		var at: Vector2 = cell + d
		if map.is_buildable(at) and not _taken(at) and not route.has(at):
			return at
	return _open_cell()

# A route cell `path`, an off-route wall cell beside it, and a Rampart cell on another side of the wall.
func _wall_spot() -> Dictionary:
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	for i in range(3, route.size() - 3):
		var path: Vector2 = route[i]
		for d in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var wall: Vector2 = path + d
			if route.has(wall) or not map.is_buildable(wall) or _taken(wall):
				continue
			for d2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
				var rampart: Vector2 = wall + d2
				if rampart != path and not route.has(rampart) and map.is_buildable(rampart) and not _taken(rampart):
					return {"path": path, "wall": wall, "rampart": rampart}
	return {}

func _spawn(cell: Vector2, path: String = "res://resource/enemy/leaf_bug.tres"):
	if not ResourceLoader.exists(path):
		return null
	var enemy: Node2D = spawner.spawn_enemy(load(path))
	if enemy == null:
		return null
	enemy.set_process(false)
	enemy.global_position = Tower.MAP_GRID.calculate_map_position(cell)
	enemy.max_health = 100000
	enemy.health = 100000
	return enemy

func _clean() -> void:
	for child in spawner.get_children():
		child.queue_free()
	for tower in container.get_children():
		if tower is Tower:
			for c in tower.get_cells():
				map.unblock_cell(c)
		tower.queue_free()
	for node in main.get_children():
		if node is BranchKit.GroundZone or node is BranchKit.BroodSprite or node is BranchKit.LineFlash \
				or node is BranchKit.ConeFlash or node is BranchKit.CrackField:
			node.queue_free()
	await process_frame

func _plant(id: String, cell: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = cell
	tower.position = Tower.MAP_GRID.calculate_map_position(cell)
	container.add_child(tower)
	tower.set_process(false)
	return tower

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
