extends SceneTree

# Headless test for targeting modes (screens_ui.md "Targeting"): First / Strongest / Closest pick the
# right nightmare, the switch is hidden for pulses and Thornwalls, a group can be set at once, T cycles,
# the choice is kept through growing and in the run save. Run:
#   godot --headless --path . --script res://tests/test_targeting.gd --fixed-fps 60

const CELL := 64.0

var failures := 0
var main: Node
var spawner
var placer: TowerPlacer
var seller: TowerSeller
var container: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	spawner = main.get_node("%EnemyContainer")
	placer = main.get_node("%TowerPlacer")
	seller = main.get_node("%TowerSeller")
	container = main.get_node("%TowerContainer")
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

	var shooter := _plant("sporeling", Vector2(6, 6))
	_check(shooter.can_choose_target() and shooter.get_target_mode() == TowerData.TargetMode.FIRST, "First by default")
	var far := _spawn(shooter.global_position + Vector2(CELL * 1.5, 0))
	far._path_index = far._path.size() - 2  # Nearly at the Heartwood
	var strong := _spawn(shooter.global_position + Vector2(0, CELL * 1.5))
	strong.health = strong.max_health * 10
	strong.max_health *= 10
	var near := _spawn(shooter.global_position + Vector2(CELL * 0.6, 0))
	_check(shooter.find_target() == far, "First: the one furthest along")
	shooter.set_target_mode(TowerData.TargetMode.STRONGEST)
	_check(shooter.find_target() == strong, "Strongest: the most health left")
	shooter.set_target_mode(TowerData.TargetMode.CLOSEST)
	_check(shooter.find_target() == near, "Closest: the nearest to the Warden")
	shooter.set_target_mode(TowerData.TargetMode.LAST)
	var back: Node2D = null
	for e in [far, strong, near]:
		if back == null or e.get_remaining_distance() > back.get_remaining_distance():
			back = e
	_check(back != far and shooter.find_target() == back, "Last: the one furthest back (the newest arrival)")
	_check(Tower.PLAYER_TARGET_MODES == [TowerData.TargetMode.FIRST, TowerData.TargetMode.LAST,
		TowerData.TargetMode.STRONGEST, TowerData.TargetMode.CLOSEST], "the switch reads First, Last, Strongest, Closest")

	# --- Hidden for pulses and Thornwalls ---
	_check(not _plant("rootling", Vector2(10, 10)).can_choose_target(), "no switch for pulses")
	_check(not _plant("thornwall", Vector2(12, 10)).can_choose_target(), "no switch for Thornwalls")

	# --- Group set and T ---
	var other := _plant("sporeling", Vector2(8, 12))
	seller.set_selection([shooter, other])
	_check(shooter.is_selected and other.is_selected, "selected Wardens show the mode pip")
	seller.set_target_group(seller.selection, TowerData.TargetMode.STRONGEST)
	_check(shooter.get_target_mode() == TowerData.TargetMode.STRONGEST and other.get_target_mode() == TowerData.TargetMode.STRONGEST,
		"a group is set at once")
	var press := InputEventAction.new()
	press.action = &"cycle_target"
	press.pressed = true
	seller._unhandled_input(press)
	_check(shooter.get_target_mode() == TowerData.TargetMode.CLOSEST and other.get_target_mode() == TowerData.TargetMode.CLOSEST,
		"T cycles the selection (Strongest -> Closest)")
	seller.select(null)
	_check(not shooter.is_selected, "no pip once deselected")

	# --- Kept through growing and in the save ---
	var grown: TowerData = shooter.tower_data.evolves_to[0]
	shooter.evolve(grown, 0)
	_check(shooter.get_target_mode() == TowerData.TargetMode.CLOSEST, "kept through growing")
	var saver = main.get_node("%RunSaver")
	saver.file_path = OS.get_user_data_dir().path_join("test_targeting_run.json")  # Never the player's save
	_check(saver.save_now(), "the run saves")
	var saved: Dictionary = saver._read()
	DirAccess.remove_absolute(saver.file_path)
	if _check_has(saved):
		var row: Dictionary = saved.towers.filter(func(r: Dictionary) -> bool: return r.cell == [shooter.cell.x, shooter.cell.y])[0]
		_check(row.target_chosen and int(row.target_mode) == TowerData.TargetMode.CLOSEST, "saved with the run")

	print("targeting test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

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
	enemy.max_health = 100000
	enemy.health = 100000
	return enemy

func _check_has(saved: Dictionary) -> bool:
	_check(saved.has("towers"), "the save lists the Wardens")
	return saved.has("towers")
