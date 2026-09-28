extends SceneTree

# Balance probe (not a test): drifts 61-70 with a maze of final forms, once with one Great Bell and
# once with the Lullaby Bell it grew from. Prints per-Warden damage (DamageLog events), the Bell's
# split (its hits, Charged bolts its toll set off, damage landing on Asleep nightmares) and how much of
# the field's health was dispelled vs leaked. Run from the project folder:
#   godot --headless --path . --script res://tools/balance_act3.gd --fixed-fps 60 -- --bell=1
# (--bell=0 for the comparison maze).

const FIRST := 61
const LAST := 70
const SPEED := 4.0
const RANK := 4
const MAZE := ["puffball", "dreamshroom", "hoarfrost", "thunderhead", "boulderback", "moonstone",
	"starcave", "great_dreamcatcher", "midsummer", "rockslide", "elf_circle", "magpies_hoard"]

var main: Node
var bell: Tower = null
var toll_frame := -1
var by_tower := {}  # name -> damage
var bell_split := {"hits": 0.0, "toll_setoffs": 0.0, "other": 0.0}
var on_asleep := 0.0
var total := 0.0
var spawned_health := 0.0
var leaked_health := 0.0
var dispelled := 0
var game_time := 0.0
var leaked := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var with_bell := true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--bell="):
			with_bell = arg.get_slice("=", 1) == "1"
	Kinships.force_full = true
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var dreams: DreamState = main.get_node("%DreamState")
	var run_state: RunState = main.get_node("%RunState")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var spawner = main.get_node("%EnemyContainer")
	dreams.unlock_everything = true
	run_state.dew = 1000000
	run_state.invulnerable = true
	# The Bell first, so both runs have it in the same spot (the maze can fill every cell by the path).
	bell = _build(placer, "great_bell" if with_bell else "lullaby_bell")
	for id in MAZE:
		_build(placer, id)
	bell.attack_released.connect(func(_t) -> void: toll_frame = Engine.get_process_frames())
	for tower in main.get_node("%TowerContainer").get_children():
		if tower is Tower:
			tower.rank = RANK
			tower.focus = Tower.Focus.POWER
	if DamageLog.instance:
		DamageLog.instance.damage_dealt.connect(_on_damage)
	spawner.child_entered_tree.connect(func(n) -> void:
		if n.has_method("take_damage"):
			(func() -> void: spawned_health += n.max_health).call_deferred())
	spawner.enemy_cleansed.connect(func(_e) -> void: dispelled += 1)
	spawner.enemy_reached_goal.connect(func(e) -> void:
		leaked += 1
		leaked_health += e.health)
	director.drifts_started = FIRST - 1
	director.drifts_cleared = FIRST - 1
	Engine.time_scale = SPEED
	var frames := 0

	director.drift_started.connect(func(n) -> void: print("  drift %d starts at %.0f s" % [n, game_time]))
	director.drift_cleared.connect(func(n, _b, _p) -> void: print("  drift %d cleared at %.0f s (%d on the field)" % [n, game_time, spawner.get_enemies().size()]))
	var last_cleared := director.drifts_cleared
	var stuck_frames := 0
	while director.drifts_cleared < LAST and frames < 60 * 60 * 30:
		paused = false
		if director.is_resting() and director.drifts_started < LAST:
			director.start_next_block()
		await process_frame
		frames += 1
		game_time += SPEED / 60.0  # --fixed-fps 60, scaled by time_scale (a member: lambdas copy locals)
		# Watchdog: no drift cleared for 3 game minutes = say why (who is still on the field).
		stuck_frames = 0 if director.drifts_cleared != last_cleared else stuck_frames + 1
		last_cleared = director.drifts_cleared
		if stuck_frames == int(90.0 * 60.0 / SPEED):
			_report_stall(director, spawner)
	Engine.time_scale = 1.0
	_report(with_bell, director)
	quit(0)

func _on_damage(event) -> void:
	total += event.amount
	var name: String = event.source_name
	by_tower[name] = by_tower.get(name, 0.0) + event.amount
	if is_instance_valid(event.enemy) and (event.enemy.statuses.is_asleep() or (event.enemy.statuses.has(EnemyStatuses.DROWSY)
			and event.enemy.statuses.stacks(EnemyStatuses.DROWSY) >= event.enemy.statuses.get_max_stacks(EnemyStatuses.DROWSY))):
		on_asleep += event.amount
	if event.source == bell and event.tag == &"":
		bell_split.hits += event.amount
	elif (event.tag == &"static" or event.tag == &"lightning_rod") and Engine.get_process_frames() == toll_frame:
		bell_split.toll_setoffs += event.amount
	elif event.source == bell:
		bell_split.other += event.amount

func _report(with_bell: bool, director: DriftDirector) -> void:
	print("=== drifts %d-%d, %s, finals at rank %d, drifts cleared %d ===" % [FIRST, LAST,
		"with The Great Bell" if with_bell else "with a Lullaby Bell instead", RANK, director.drifts_cleared])
	var rows := by_tower.keys()
	rows.sort_custom(func(a, b) -> bool: return by_tower[a] > by_tower[b])
	for name in rows:
		print("  %-22s %10.0f  %5.1f%%" % [name, by_tower[name], 100.0 * by_tower[name] / maxf(total, 1.0)])
	print("  total damage %.0f (%.0f per drift cleared)" % [total, total / maxf(director.drifts_cleared - FIRST + 1, 1)])
	print("  bell: hits %.0f, toll set-offs (Charged bolts) %.0f, other %.0f" % [bell_split.hits,
		bell_split.toll_setoffs, bell_split.other])
	print("  damage landing on Asleep / fully Drowsy nightmares: %.0f (%.1f%%)" % [on_asleep, 100.0 * on_asleep / maxf(total, 1.0)])
	print("  field: %.0f health spawned over %d drifts (%.0f per drift), %d dispelled, %d leaked (%.1f%% of the health leaked)" % [
		spawned_health, LAST - FIRST + 1, spawned_health / (LAST - FIRST + 1), dispelled, leaked,
		100.0 * leaked_health / maxf(spawned_health, 1.0)])

func _build(placer: TowerPlacer, id: String) -> Tower:
	var map = main.get_node("%MapGenerator")
	var container: Node = main.get_node("%TowerContainer")
	var path: PackedVector2Array = map.get_path_from(map.startPath)
	placer.tower_data = load("res://resource/tower/%s.tres" % id)
	for i in range(4, path.size() - 2):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = path[i] + offset
			if path.has(cell) or not map.can_block(cell):
				continue
			var count := container.get_child_count()
			if placer._try_build(cell):
				return container.get_child(count)
	return null

# Why no drift has cleared for a while: the director's state and every nightmare still on the field.
func _report_stall(director: DriftDirector, spawner) -> void:
	print("  STALL at drifts started %d / cleared %d: resting %s, arriving %s, awaiting family pick %s, paused %s" % [
		director.drifts_started, director.drifts_cleared, director.is_resting(), director._arriving.keys(),
		director.awaiting_family_pick, paused])
	for enemy in spawner.get_children():
		if not enemy.has_method("take_damage"):
			continue
		var s: EnemyStatuses = enemy.statuses
		print("    %s hp %d/%d cleansed %s cell %s target %s sleep %.1f held %s statuses %s processing %s speed %.1f (x%.2f) slow_time %.1f amount %.2f" % [
			enemy.enemy_data.display_name, enemy.health, enemy.max_health, enemy.is_cleansed,
			enemy.get_current_cell(), enemy.get_target_cell(), s.sleep_time, s.is_held(), s.active_ids(),
			enemy.is_processing(), enemy.get_move_speed(), s.get_speed_multiplier(), s.slow_time, s.slow_amount])
