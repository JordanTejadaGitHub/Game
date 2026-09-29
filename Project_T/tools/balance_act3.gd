extends SceneTree

# Balance probe (not a test): drifts 61-70 with a maze of final forms, once with one Great Bell and
# once with the Lullaby Bell it grew from. Prints per-Warden damage (DamageLog events), the Bell's
# split (its hits, Charged bolts its toll set off, damage landing on Asleep nightmares) and how much of
# the field's health was dispelled vs leaked. Run from the project folder:
#   godot --headless --path . --script res://tools/balance_act3.gd --fixed-fps 60 -- --bell=1
# (--bell=0 for the comparison maze; --seed=N picks the map, default 7). The Great Bell is grown from the
# Lullaby Bell, so it keeps the Lullaby's pulse (legacy).

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
var map_seed := 7
# --maze=bell / storm (design chat b061d29): a Bellflower-led board vs a Firefly / Dewdrop board, the
# same six other finals in both, no Great Bell. Reports each family's share of the damage.
const OTHERS := ["puffball", "elf_circle", "boulderback", "moonstone", "rockslide", "starcave"]
const MAZES := {
	"bell": ["lullaby_bell", "great_dreamcatcher", "whispering_hollow", "lullaby_bell", "great_dreamcatcher", "whispering_hollow"],
	"storm": ["thunderhead", "hoarfrost", "midsummer", "monsoon", "beacon", "morning_fog"],
}
var maze := ""
var by_line := {}  # Warden line -> damage

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var with_bell := true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--bell="):
			with_bell = arg.get_slice("=", 1) == "1"
		if arg.begins_with("--seed="):
			map_seed = int(arg.get_slice("=", 1))
		if arg.begins_with("--maze="):
			maze = arg.get_slice("=", 1)
	Kinships.force_full = true
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = map_seed  # The same map for both bells (--seed=N)
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
	if maze != "":
		for id in MAZES[maze] + OTHERS:  # The family's Wardens first: the best spots by the path
			_build(placer, id)
	else:
		bell = _build(placer, "lullaby_bell")
		if with_bell:
			bell.evolve(load("res://resource/tower/great_bell.tres"), 0)  # Grown, so it keeps the Lullaby (legacy)
		for id in MAZE:
			_build(placer, id)
		bell.attack_released.connect(func(_t) -> void: toll_frame = Engine.get_process_frames())
	for tower in main.get_node("%TowerContainer").get_children():
		if tower is Tower:
			tower.rank = RANK
			tower.focus = Tower.Focus.POWER
	if DamageLog.instance:
		DamageLog.instance.damage_dealt.connect(_on_damage)
	var tracker_hook := func(n) -> void:
		if n is ReactionTracker:
			n.reaction_fired.connect(func(id, _e, _chain, towers) -> void:
				_reaction_towers[id] = [Engine.get_process_frames(), towers])
	main.child_entered_tree.connect(tracker_hook)
	for n in main.get_children():
		tracker_hook.call(n)
	spawner.child_entered_tree.connect(func(n) -> void:
		if n.has_method("take_damage"):
			(func() -> void: spawned_health += n.max_health).call_deferred())
	spawner.enemy_cleansed.connect(func(_e) -> void: dispelled += 1)
	if spawner.has_signal("wall_trampled"):
		spawner.wall_trampled.connect(func(cell, by) -> void:
			print("  TRAMPLED %s at %.0f s by %s" % [cell, game_time, by.enemy_data.display_name if is_instance_valid(by) else "?"]))
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
		# Watchdog: no drift cleared for 90 game seconds after the last one finished arriving = say why
		# (who is still on the field). Act 3 drifts can arrive for 3+ minutes; that isn't a stall.
		var arriving := not director._arriving.is_empty()
		stuck_frames = 0 if director.drifts_cleared != last_cleared or arriving else stuck_frames + 1
		last_cleared = director.drifts_cleared
		if stuck_frames == int(90.0 * 60.0 / SPEED):
			_report_stall(director, spawner)
	Engine.time_scale = 1.0
	_report(with_bell, director)
	quit(0)

func _on_damage(event) -> void:
	total += event.amount
	_contribute(event)
	var name: String = event.source_name
	by_tower[name] = by_tower.get(name, 0.0) + event.amount
	if is_instance_valid(event.source) and event.source is Tower:
		var line: String = event.source.tower_data.line
		by_line[line] = by_line.get(line, 0.0) + event.amount
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
	print("=== map seed %d, drifts %d-%d, %s, finals at rank %d, drifts cleared %d ===" % [map_seed, FIRST, LAST,
		("board " + maze) if maze != "" else ("with The Great Bell" if with_bell else "with a Lullaby Bell instead"), RANK, director.drifts_cleared])
	var rows := by_tower.keys()
	rows.sort_custom(func(a, b) -> bool: return by_tower[a] > by_tower[b])
	print("  %-22s %10s  %6s  %s" % ["Warden", "damage", "share", "contribution"])
	for name in rows:
		print("  %-22s %10.0f  %5.1f%%  %5.1f%%" % [name, by_tower[name], 100.0 * by_tower[name] / maxf(total, 1.0),
			100.0 * by_contrib.get(name, 0.0) / maxf(total, 1.0)])
	if maze != "":
		print("  board: %s (%s-led)" % [maze, "Bellflower" if maze == "bell" else "Firefly / Dewdrop"])
		for line in by_line:
			print("  family %-8s %5.1f%%" % [line, 100.0 * by_line[line] / maxf(total, 1.0)])
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

# --- Contribution (design chat: credit support, not only direct damage) --------------------------------
# Each damage event starts as its dealer's; parts of it move to the Warden that made it possible:
# - Exposed (Marked): the extra damage-taken share -> the Marked applier.
# - Caught: the extra share -> the nearest Dreamcatcher line Warden.
# - Reactions: damage tagged with a Reaction -> split evenly among the Wardens that set it up
#   (ReactionTracker.reaction_fired's towers).
# - Slows: a slowed nightmare stays in range 1/speed longer, so (1 - speed) of the damage it takes ->
#   whoever slows it, split by slow strength: Damp / Drowsy appliers, the PathCloud it stands in
#   (Morning Fog), the rubble (the nearest Rockslide).
# - Held / Asleep: half the damage taken meanwhile -> the Held / Drowsy applier (a stand-in for the
#   extra time the hold buys).
var by_contrib := {}  # Warden name -> contribution
var _reaction_towers := {}  # Reaction id -> [frame, towers] (the last one that fired)

func _contribute(event) -> void:
	var source_name: String = event.source_name
	var parts := {}  # name -> amount moved to it
	var amount: float = event.amount
	var e = event.enemy
	if is_instance_valid(e) and not e.is_cleansed:
		var s: EnemyStatuses = e.statuses
		var taken: float = maxf(event.taken_multiplier, 1.0)
		if s.has(EnemyStatuses.MARKED) and _is_tower(s.source(EnemyStatuses.MARKED)):
			var extra := maxf(EnemyStatuses.MARKED_EXTRA, s.marked_extra)
			_move(parts, s.source(EnemyStatuses.MARKED), amount * extra / taken)
		if s.is_caught() and s.caught_bonus > 0.0:
			var catcher := _nearest_tower(e.global_position, func(t: Tower) -> bool: return t.tower_data.caught_bonus > 0.0)
			if catcher:
				_move(parts, catcher, amount * (1.0 - 1.0 / (1.0 + s.caught_bonus)))
		if s.is_held() or s.is_asleep():
			var holder = s.source(EnemyStatuses.HELD) if s.is_held() else s.source(EnemyStatuses.DROWSY)
			if _is_tower(holder):
				_move(parts, holder, amount * 0.5)
		else:
			var slows := {}  # Tower -> slow strength
			if s.has(EnemyStatuses.DAMP) and _is_tower(s.source(EnemyStatuses.DAMP)):
				slows[s.source(EnemyStatuses.DAMP)] = EnemyStatuses.DAMP_SLOW * maxf(s.potency(EnemyStatuses.DAMP), 1.0)
			if s.has(EnemyStatuses.DROWSY) and _is_tower(s.source(EnemyStatuses.DROWSY)):
				var drowsy = s.source(EnemyStatuses.DROWSY)
				slows[drowsy] = slows.get(drowsy, 0.0) + EnemyStatuses.DROWSY_SLOW_PER_STACK * s.stacks(EnemyStatuses.DROWSY)
			if s.slow_time > 0.0 and s.slow_amount > 0.0:
				var slower := _cloud_or_rubble_tower(e.global_position)
				if slower:
					slows[slower] = slows.get(slower, 0.0) + s.slow_amount
			var total_slow := 0.0
			for t in slows:
				total_slow += slows[t]
			if total_slow > 0.0:
				var share := amount * (1.0 - s.get_speed_multiplier())
				for t in slows:
					_move(parts, t, share * slows[t] / total_slow)
	if _reaction_towers.has(event.tag):
		var towers: Array = _reaction_towers[event.tag][1].filter(func(t) -> bool: return _is_tower(t))
		for t in towers:
			_move(parts, t, amount / towers.size())
	var moved := 0.0
	for name in parts:
		moved += parts[name]
	var scale := minf(1.0, amount / moved) if moved > 0.0 else 1.0  # Several supports never give more than the hit
	for name in parts:
		by_contrib[name] = by_contrib.get(name, 0.0) + parts[name] * scale
	by_contrib[source_name] = by_contrib.get(source_name, 0.0) + amount - moved * scale

func _move(parts: Dictionary, tower, amount: float) -> void:
	var name: String = tower.tower_data.display_name
	parts[name] = parts.get(name, 0.0) + amount

static func _is_tower(node) -> bool:
	return is_instance_valid(node) and node is Tower

func _nearest_tower(at: Vector2, want: Callable) -> Tower:
	var best: Tower = null
	for t in main.get_node("%TowerContainer").get_children():
		if t is Tower and want.call(t) and (best == null or t.global_position.distance_to(at) < best.global_position.distance_to(at)):
			best = t
	return best

# The Warden whose cloud (PathCloud) covers `at`, else the nearest Warden that makes rubble.
func _cloud_or_rubble_tower(at: Vector2) -> Tower:
	for node in main.get_children():
		if node is PathCloud and is_instance_valid(node._tower) and node.global_position.distance_to(at) <= node._radius:
			return node._tower
	return _nearest_tower(at, func(t: Tower) -> bool: return t.attack_data.rubble_slow > 0.0)
