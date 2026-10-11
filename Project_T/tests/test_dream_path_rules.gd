extends SceneTree
var failures := 0
var main: Node
var dreams: DreamState
var rules: Script
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	rules = load("res://scripts/run/dream_path_rules.gd")
	if rules == null:
		_check(false, "path transition helper exists")
		quit(failures)
		return
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	dreams = main.get_node("%DreamState")
	var tower := _plant()
	var donor := _spawn(Vector2(80, 80))
	var receiver := _spawn(Vector2(81, 80))
	dreams.stacks = {"corner_sign": 1}
	donor.set_meta(&"unique_bend_serial", 1)
	donor.apply_status(EnemyStatuses.SPORED, 1, 5.0, 7.0, 0, "mushroom", tower)
	rules.native_status(tower, donor, EnemyStatuses.SPORED, false, true, 0.0)
	rules.native_status(tower, donor, EnemyStatuses.SPORED, true, false, 0.0)
	_check(donor.statuses.stacks(EnemyStatuses.SPORED) == 1, "refused and synthetic hits cannot spend bend")
	rules.native_status(tower, donor, EnemyStatuses.SPORED, true, true, 0.0)
	_check(donor.statuses.stacks(EnemyStatuses.SPORED) == 2, "first direct native stack after bend gains one")
	rules.native_status(tower, donor, EnemyStatuses.SPORED, true, true, 5.0)
	_check(donor.statuses.stacks(EnemyStatuses.SPORED) == 2, "same bend only pays once")
	donor.set_meta(&"unique_bend_serial", 2)
	rules.native_status(tower, donor, EnemyStatuses.SPORED, true, true, 1.0)
	_check(donor.statuses.stacks(EnemyStatuses.SPORED) == 2, "new bend respects pair cooldown")
	rules.native_status(tower, donor, EnemyStatuses.SPORED, true, true, 3.0)
	_check(donor.statuses.stacks(EnemyStatuses.SPORED) == 3, "later native hit can pay cooled new bend")
	dreams.stacks = {"passing_thread": 1}
	donor.statuses = EnemyStatuses.new()
	donor.apply_status(EnemyStatuses.SPORED, 4, 5.0, 7.0, 0, "mushroom", tower)
	donor.statuses.tick(2.0)
	donor.apply_status(EnemyStatuses.SPORED, 2, 5.0, 7.0, 0, "mushroom", tower)
	donor.apply_status(EnemyStatuses.HELD, 4)
	receiver.statuses.duration_multiplier_all = 2.0
	rules.target_changed(tower, donor, receiver, 0.0)
	_check(receiver.statuses.stacks(EnemyStatuses.SPORED) == 1, "switch copies one strongest stackable status")
	_check(is_equal_approx(receiver.statuses.copy_duration(EnemyStatuses.SPORED), 3.0), "copied poison preserves oldest remaining duration without multiplier extension")
	_check(receiver.statuses.source(EnemyStatuses.SPORED) == tower and receiver.statuses.spore_line() == "mushroom" and receiver.statuses.potency(EnemyStatuses.SPORED) == 7.0, "copy preserves source family potency")
	rules.target_changed(tower, donor, receiver, 1.0)
	_check(receiver.statuses.stacks(EnemyStatuses.SPORED) == 1, "switch has two second tower cooldown")
	dreams.stacks = {"dream_residue": 1}
	receiver.statuses = EnemyStatuses.new()
	rules.caught_exited(dreams, receiver, tower, 0.0)
	rules.caught_exited(dreams, receiver, tower, 1.0)
	_check(receiver.statuses.stacks(EnemyStatuses.DROWSY) == 2, "true Catch exit pays two once per catcher cooldown")
	rules.caught_exited(dreams, receiver, tower, 3.0)
	_check(receiver.statuses.stacks(EnemyStatuses.DROWSY) == 4, "Catch exit pays after cooldown")
	dreams.stacks = {"kins_keepsake": 1}
	var partner := _plant()
	var before := dreams.run_state.dew
	rules.harmony(dreams, tower, partner, donor, 1)
	rules.harmony(dreams, partner, tower, donor, 1)
	_check(dreams.run_state.dew == before + 1, "same stable unordered kin pair pays once per drift")
	rules.harmony(dreams, partner, tower, donor, 2)
	_check(dreams.run_state.dew == before + 2, "new drift resets kin ledger")
	dreams.stacks = {"wake_ripple": 1}
	receiver.statuses = EnemyStatuses.new()
	donor.statuses.drowned = 1
	rules.dispelled(dreams, donor, 0.0)
	_check(receiver.statuses.stacks(EnemyStatuses.DAMP) == 0, "historical Drown cannot ripple")
	var under := Reactions.PullUnder.new(donor, tower, 3.0, false)
	main.add_child(under)
	under.set_process(false)
	rules.dispelled(dreams, donor, 0.0)
	_check(receiver.statuses.stacks(EnemyStatuses.DAMP) == 2, "active Drown ripples two ordinary Soaked")
	_check(receiver.statuses.drowned == 0, "ripple does not force Drown")
	under._age = under.seconds
	receiver.statuses = EnemyStatuses.new()
	rules.dispelled(dreams, donor, 3.0)
	_check(receiver.statuses.stacks(EnemyStatuses.DAMP) == 2, "final Drown tick remains active while its node is delivering damage")
	under._age = 0.0
	# Wake Ripple chooses at most three nearest living neighbors and obeys immunity.
	var close := _spawn(Vector2(80.25, 80))
	var middle := _spawn(Vector2(80.5, 80))
	var far := _spawn(Vector2(80.75, 80))
	var dead := _spawn(Vector2(80.1, 80))
	dead.is_cleansed = true
	receiver.statuses = EnemyStatuses.new()
	middle.statuses.immune.append(EnemyStatuses.DAMP)
	rules.dispelled(dreams, donor, 0.0)
	_check(close.statuses.stacks(EnemyStatuses.DAMP) == 2 and far.statuses.stacks(EnemyStatuses.DAMP) == 2, "ripple chooses nearest living neighbors")
	_check(receiver.statuses.stacks(EnemyStatuses.DAMP) == 0 and dead.statuses.stacks(EnemyStatuses.DAMP) == 0, "ripple excludes fourth neighbor and dead nightmares")
	_check(middle.statuses.stacks(EnemyStatuses.DAMP) == 0, "ripple respects ordinary immunity")
	dreams.stacks = {"kins_keepsake": 1}
	before = dreams.run_state.dew
	for i in 7:
		var kin := _plant()
		rules.harmony(dreams, tower, kin, donor, 3)
	_check(dreams.run_state.dew == before + 6, "kin reward globally caps at six per drift")
	dreams.stacks = {"corner_sign": 1}
	donor.statuses = EnemyStatuses.new()
	donor.apply_status(EnemyStatuses.MARKED, 10)
	donor.set_meta(&"unique_bend_serial", 3)
	rules.native_status(tower, donor, EnemyStatuses.MARKED, true, true, 6.0)
	_check(donor.statuses.stacks(EnemyStatuses.MARKED) == 10, "Corner Sign respects normal status cap")
	dreams.stacks = {"passing_thread": 1}
	donor.statuses = EnemyStatuses.new()
	donor.apply_status(EnemyStatuses.HELD, 4)
	receiver.statuses = EnemyStatuses.new()
	rules.target_changed(tower, donor, receiver, 5.0)
	_check(not receiver.statuses.is_held(), "Passing Thread cannot copy freeze")
	donor.apply_status(EnemyStatuses.MARKED, 2, 4.0, 3.0, 0, "water", null)
	rules.target_changed(tower, donor, receiver, 6.0)
	_check(receiver.statuses._active.get(EnemyStatuses.MARKED, {}).get("line", "") == "water", "copy preserves original family even without live source")
	dreams.stacks = {"corner_sign": 1}
	donor.statuses = EnemyStatuses.new()
	donor.set_meta(&"unique_bend_serial", 4)
	tower.set_meta(&"unique_native_status_context", [6.0, 4.0, 0])
	rules.native_status(tower, donor, EnemyStatuses.STATIC, true, true, 9.0)
	tower.remove_meta(&"unique_native_status_context")
	_check(donor.statuses.stacks(EnemyStatuses.STATIC) == 1 and donor.statuses.potency(EnemyStatuses.STATIC) == 6.0, "Corner Sign retains native potency after native charge is consumed")
	donor.statuses = EnemyStatuses.new()
	donor.set_meta(&"unique_bend_serial", 5)
	donor.apply_status(EnemyStatuses.HELD, 1)
	rules.native_status(tower, donor, EnemyStatuses.HELD, true, true, 12.0)
	_check(donor.statuses.stacks(EnemyStatuses.HELD) == 2, "Corner Sign includes ordinary native Rooted buildup")
	var wall := _plant()
	wall.tower_data = load("res://resource/tower/thornwall.tres")
	donor.statuses = EnemyStatuses.new()
	donor.apply_status(EnemyStatuses.DROWSY, Tower.WALL_DROWSY_CAP)
	rules.native_status(wall, donor, EnemyStatuses.DROWSY, true, true, 12.0)
	_check(donor.statuses.stacks(EnemyStatuses.DROWSY) == Tower.WALL_DROWSY_CAP, "wall cannot obtain direct Corner Sign bonus even with synthetic direct flag")
	print("Dream path rules: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.free()
	await process_frame
	await process_frame
	quit(failures)
func _plant() -> Tower:
	var tower: Tower = load("res://scenes/tower/tower.tscn").instantiate()
	tower.tower_data = load("res://resource/tower/sporeling.tres")
	tower.cell = Vector2(80, 80)
	main.get_node("%TowerContainer").add_child(tower)
	tower.set_process(false)
	return tower
func _spawn(cell: Vector2) -> Node2D:
	var container := main.get_node("%EnemyContainer")
	var enemy: Node2D = container.enemy_scene.instantiate()
	enemy.enemy_data = TestGrove._load_enemy_types()[0]
	container.add_child(enemy)
	enemy.position = enemy.grid.calculate_map_position(cell)
	enemy.set_path(PackedVector2Array([cell]))
	enemy.set_process(false)
	enemy.health = 100000
	enemy.max_health = 100000
	return enemy
func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
