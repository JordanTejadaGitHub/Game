extends SceneTree

# Headless test for the Rootling, Acorn, Dewdrop and Firefly Jar branches and finals built from
# warden_stats.md: Rootcurl / Long Way Home (pull back), Tangleroot / Snugroot (Hold), Elder Stump /
# Grove Heart (auras), Dewcatcher / Wellspring (Dew), Monsoon (rain), Morning Fog (fog), Beacon (Mark
# everything, +35%). Run from the project folder:
#   godot --headless --path . --script res://tests/test_family_finals.gd --fixed-fps 60

const CELL := 64.0
const TREES := {
	"rootling": [["rootcurl", "long_way_home"], ["tangleroot", "snugroot"]],
	"acorn": [["elder_stump", "grove_heart"], ["dewcatcher", "wellspring"]],
	"rain_lily": [["monsoon"]],
	"mistveil": [["morning_fog"]],
	"lanternmoth": [["beacon"]],
}
const ASCEND := {"long_way_home": "world_root", "snugroot": "world_root", "grove_heart": "grandmother_oak",
	"wellspring": "grandmother_oak", "monsoon": "tidecaller", "morning_fog": "tidecaller", "beacon": "stormheart"}

var failures := 0
var main: Node
var spawner
var placer: TowerPlacer
var container: Node
var run_state: RunState
var director: DriftDirector

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_family_finals_%d.json" % OS.get_process_id()  # Not the player's settings (reduced motion shortens drags)
	Fx.reset_run()
	_check_data()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	spawner = main.get_node("%EnemyContainer")
	placer = main.get_node("%TowerPlacer")
	container = main.get_node("%TowerContainer")
	run_state = main.get_node("%RunState")
	director = main.get_node("%DriftDirector")
	for child in spawner.get_children():
		child.queue_free()
	await process_frame
	var map = main.get_node("%MapGenerator")
	var route: PackedVector2Array = map.get_path_from(map.startPath)

	# --- Rootcurl: pulls the nightmare furthest along back a tile every 4 s ---
	var near: Vector2 = route[10]
	var curl := _plant("rootcurl", near + Vector2(0, 0))
	curl.position = Tower.MAP_GRID.calculate_map_position(route[10]) + Vector2(0, CELL)
	var walker := _walker(route, 10)
	var before: int = walker.get_route_index()
	curl._update_ability(0.1)
	_check(not walker.is_dragged(), "the pull waits for the lash (the attack's release frame)")
	curl._advance_attack(1.0)
	_check(walker.is_dragged() and walker.get_route_index() == before, "the pull drags over time, not a jump")
	await _wait_drag(walker)
	_check(walker.get_route_index() < before, "Rootcurl pulls the nightmare back along its route (%d -> %d)" % [before, walker.get_route_index()])
	_check(curl._ability_timer > 3.9, "then waits 4 s")
	curl.queue_free()
	await _clean()

	# --- Long Way Home: 3 tiles, each nightmare once ---
	var home := _plant("long_way_home", route[12])
	home.position = Tower.MAP_GRID.calculate_map_position(route[12]) + Vector2(0, CELL)
	var w2 := _walker(route, 12)
	var start_index: int = w2.get_route_index()
	home._update_ability(0.1)
	home._advance_attack(1.0)
	var seconds := await _wait_drag(w2)
	_check(seconds > 0.7 and seconds < 1.3, "3 tiles take ~0.95 s: grab, then the drag (%.2f s)" % seconds)
	var after_first: int = w2.get_route_index()
	_check(start_index - after_first >= 2, "Long Way Home drags it back about 3 tiles (%d -> %d)" % [start_index, after_first])
	w2.global_position = Tower.MAP_GRID.calculate_map_position(route[12])
	home._ability_timer = 0.0
	home._update_ability(0.1)
	_check(w2.has_meta(&"pulled_home"), "and remembers it (only once per nightmare)")
	home.queue_free()
	await _clean()

	# --- A pull during a drag extends it (same total tiles); a re-route or dispel ends it ---
	var w3 := _walker(route, 14)
	var starts := [0]
	w3.drag_started.connect(func(_e: Node2D, _t: float) -> void: starts[0] += 1)
	var cell_px := Tower.MAP_GRID.cell_size.x
	w3.push_back(cell_px)
	for i in 20:
		w3._update_drag(1.0 / 60.0)
	w3.push_back(cell_px)
	await _wait_drag(w3)
	_check(starts[0] == 1 and w3.global_position.is_equal_approx(Tower.MAP_GRID.calculate_map_position(route[12])),
		"two pulls = one drag, 2 tiles back (%d drags, at %s)" % [starts[0], w3.global_position])
	w3.push_back(cell_px)
	w3.set_path(route)
	_check(not w3.is_dragged(), "a re-route ends the drag")
	w3._path_index = 5
	w3.push_back(cell_px)
	w3._cleanse()
	_check(not w3.is_dragged(), "a dispel ends the drag")
	await _clean()

	# --- Tangleroot / Snugroot: Hold the ones furthest along ---
	var snug := _plant("snugroot", Vector2(2, 2))
	snug.position = Tower.MAP_GRID.calculate_map_position(route[8]) + Vector2(0, CELL)
	var held := []
	for i in 4:
		held.append(_walker(route, 7 + i))
	snug._update_ability(0.1)
	var count := held.filter(func(e) -> bool: return e.statuses.is_held()).size()
	var reachable := held.filter(func(e) -> bool: return snug.get_enemies_in_range().has(e)).size()
	_check(count == mini(reachable, snug.tower_data.hold_targets) and count > 0, "Snugroot Holds up to its hold_targets (%d of %d in range)" % [count, reachable])
	snug.queue_free()
	await _clean()

	# --- Beacon: Marks everything in range at +35% ---
	var beacon := _plant("beacon", Vector2(2, 2))
	var a := _spawn(beacon.global_position + Vector2(CELL, 0))
	var b := _spawn(beacon.global_position + Vector2(0, 2 * CELL))
	beacon._update_ability(0.1)
	_check(a.statuses.has(EnemyStatuses.MARKED) and b.statuses.has(EnemyStatuses.MARKED), "Beacon Marks everything in range")
	_check(is_equal_approx(a.statuses.get_damage_taken_multiplier(), 1.0 + beacon.tower_data.marked_bonus), "its Marked is +marked_bonus (%.2f)" % a.statuses.get_damage_taken_multiplier())
	beacon.queue_free()
	await _clean()

	# --- Elder Stump / Grove Heart / Acorn auras ---
	var stump := _plant("elder_stump", Vector2(5, 5))
	var friend := _plant("sprout", Vector2(6, 5))
	var far_friend := _plant("sprout", Vector2(8, 5))
	friend._refresh_neighbours()
	far_friend._refresh_neighbours()
	var speed := far_friend.get_attacks_per_second()  # 3 tiles away: no aura
	_check(is_equal_approx(friend.get_attacks_per_second(), speed * (1.0 + load("res://resource/tower/elder_stump.tres").aura_speed_bonus)), "Elder Stump: its attack-speed aura beside it")
	stump.evolve(load("res://resource/tower/grove_heart.tres"), 0)
	var extra := _plant("sprout", Vector2(5, 6))
	for t in [stump, friend, extra]:
		t._refresh_neighbours()
	var base_damage := far_friend.get_damage()
	_check(is_equal_approx(friend.get_damage(), base_damage * (1.15 + 0.03 * stump._aura_count)),
		"Grove Heart: +15%%, +3%% per Warden around it (%d around)" % stump._aura_count)
	for t in [stump, friend, far_friend, extra]:
		t.queue_free()
	var acorn := _plant("acorn", Vector2(5, 8))
	var buddy := _plant("sprout", Vector2(6, 8))
	var lone := _plant("sprout", Vector2(9, 8))
	buddy._refresh_neighbours()
	lone._refresh_neighbours()
	var plain := lone.get_damage()
	_check(is_equal_approx(buddy.get_damage(), plain * 1.05), "Acorn: +5% damage beside it")
	for t in [acorn, buddy, lone]:
		t.queue_free()
	await process_frame

	# --- Dewcatcher / Wellspring: the catch, the Harvest and interest are in test_catchers.gd ---
	var catcher := _plant("dewcatcher", Vector2(3, 10))
	await process_frame
	var dew := run_state.dew
	director.drift_cleared.emit(5, 0, true)
	_check(run_state.dew == dew and is_equal_approx(catcher.bowl, float(catcher.tower_data.dew_per_drift)), "Dewcatcher: its Dew per drift, into the bowl (%.1f)" % catcher.bowl)
	catcher.queue_free()
	await process_frame
	paused = false

	# --- Monsoon: soothes every nightmare in range and soaks them ---
	var monsoon := _plant("monsoon", Vector2(4, 4))
	var r1 := _spawn(monsoon.global_position + Vector2(CELL, 0))
	var r2 := _spawn(monsoon.global_position + Vector2(-2 * CELL, CELL))
	monsoon._release()
	_check(_lost(r1) > 0 and _lost(r2) > 0, "Monsoon's rain soothes everything in range")
	_check(r1.statuses.has(EnemyStatuses.DAMP) and r1.statuses.time_left(EnemyStatuses.DAMP) > 5.0, "and leaves 6 s of Damp")
	monsoon.queue_free()
	await _clean()

	# --- Morning Fog: slow and Drowsy inside ---
	var fog_warden := _plant("morning_fog", Vector2(4, 4))
	var fog := PathCloud.new(fog_warden, fog_warden.global_position + Vector2(CELL, 0))
	main.add_child(fog)
	var f1 := _spawn(fog_warden.global_position + Vector2(CELL, 0))
	for i in 3:
		fog._tick()
	_check(f1.statuses.slow_time <= 0.0 and f1.statuses.stacks(EnemyStatuses.DROWSY) == 0, "Morning Fog neither slows nor makes Drowsy (status jobs, 2026-09-29)")
	_check(f1.statuses.has(EnemyStatuses.DAMP) and f1.statuses.time_left(EnemyStatuses.DAMP) >= 2.5, "its Soak lingers ~3 s after the fog (%.1f s)" % f1.statuses.time_left(EnemyStatuses.DAMP))
	_check(f1.statuses.is_in_fog(), "it's fog (Spored ticks harder)")
	fog.queue_free()
	fog_warden.queue_free()
	await _clean()

	# --- Hoarfrost buff (design chat): each hit Soaks (up to 2); a nightmare Soaked twice freezes ---
	var frost := _plant("hoarfrost", Vector2(16, 12))
	var chilled := _spawn(frost.global_position + Vector2(CELL, 0))
	frost.hit(chilled, 1.0, false, Tower.NO_CRIT)
	_check(chilled.statuses.stacks(EnemyStatuses.DAMP) == 1 and not chilled.statuses.is_held(), "Hoarfrost: the first hit Soaks, no freeze yet")
	frost.hit(chilled, 1.0, false, Tower.NO_CRIT)
	_check(chilled.statuses.stacks(EnemyStatuses.DAMP) == 2 and chilled.statuses.is_held(), "the second hit (2 Soaked) freezes it")
	frost.queue_free()
	await _clean()

	# --- Midsummer buff: switching target within 1 s keeps half the ramp ---
	var sun := _plant("midsummer", Vector2(16, 14))
	var first := _spawn(sun.global_position + Vector2(CELL, 0))
	sun._update_beam(0.1)
	sun._beam_ramp = 3.0  # Ramped up on the first one
	first.dispel()
	await process_frame
	sun._update_beam(0.1)  # The target is gone: the beam stops
	var second := _spawn(sun.global_position + Vector2(0, CELL))
	sun._update_beam(0.0)
	_check(is_equal_approx(sun._beam_ramp, 2.0), "Midsummer: a new target soon after keeps half the ramp (%.2f)" % sun._beam_ramp)
	sun._stop_beam()
	sun._anim_time += 2.0  # Over a second later
	sun._update_beam(0.0)
	_check(is_equal_approx(sun._beam_ramp, 1.0), "over a second later it starts from scratch (%.2f)" % sun._beam_ramp)
	second.queue_free()
	sun.queue_free()
	await _clean()

	# --- Sunpetal: the beam holds its target until it's dispelled or leaves range (Balancing: switching to each
	# new front-runner kept resetting the ramp) ---
	var petal := _plant("sunpetal", Vector2(16, 14))
	petal.target_chosen = true
	petal.target_mode = TowerData.TargetMode.STRONGEST
	var beamed := _spawn(petal.global_position + Vector2(CELL, 0))
	petal._update_beam(0.1)
	petal._beam_ramp = 2.5
	var stronger := _spawn(petal.global_position + Vector2(0, CELL))
	stronger.max_health = 5000000
	stronger.health = 5000000
	_check(petal.find_target() == stronger, "(setup) targeting alone would switch to the stronger one")
	petal._update_beam(0.1)
	_check(petal._beam_target == beamed and petal._beam_ramp > 2.5, "the beam keeps its target and its ramp (%.2f)" % petal._beam_ramp)
	beamed.global_position = petal.global_position + Vector2(20, 0) * CELL  # Out of range
	await process_frame  # (the in-range list is kept for the frame)
	petal._update_beam(0.1)
	_check(petal._beam_target == stronger and petal._beam_ramp < 1.5, "once it leaves range the beam takes a new one, ramp from scratch (%.2f)" % petal._beam_ramp)
	beamed.queue_free()
	stronger.queue_free()
	petal.queue_free()
	await _clean()

	# --- Thunderclap arcs reach at most the 8 nearest Soaked nightmares ---
	var clapper := _plant("thunderhead", Vector2(4, 14))
	var centre := _spawn(clapper.global_position)
	var soaked: Array = []
	for i in 12:
		var e := _spawn(clapper.global_position + Vector2(20 + 4 * i, 10))
		e.apply_status(EnemyStatuses.DAMP)
		soaked.append(e)
	centre.apply_status(EnemyStatuses.DAMP)
	var before_hp: Array = soaked.map(func(e) -> int: return e.health)
	centre.apply_status(EnemyStatuses.STATIC, 5, 0.0, 10.0, 0, "light", clapper)
	var arced := 0
	for i in soaked.size():
		if soaked[i].health < before_hp[i]:
			arced += 1
	_check(arced >= 1 and arced <= Reactions.THUNDERCLAP_MAX_ARCS, "Thunderclap: at most 8 arcs from one clap (%d struck)" % arced)
	clapper.queue_free()
	await _clean()

	# --- Status jobs (2026-09-29): Rootling's 4th pulse Holds; water hits on Damp +20% ---
	var roots := _plant("rootling", Vector2(18, 4))
	var rooted := _spawn(roots.global_position + Vector2(CELL * 0.5, 0))
	roots._attack_count = 2
	roots._release()  # The 3rd pulse
	_check(not rooted.statuses.is_held(), "Rootling: the 3rd pulse doesn't Hold")
	roots._release()  # The 4th
	_check(rooted.statuses.is_held(), "the 4th pulse Holds the nightmare furthest along")
	roots.queue_free()
	await _clean()
	var drop := _plant("dewdrop", Vector2(18, 8))
	var dry := _spawn(drop.global_position + Vector2(CELL, 0))
	var wet := _spawn(drop.global_position + Vector2(0, CELL))
	wet.apply_status(EnemyStatuses.DAMP, 1, 0.0, 1.0)
	var dry_before: int = dry.health
	var wet_before: int = wet.health
	drop.hit(dry, 10.0, false, Tower.NO_CRIT)
	drop.hit(wet, 10.0, false, Tower.NO_CRIT)
	var ratio := float(wet_before - wet.health) / maxf(dry_before - dry.health, 1.0)
	_check(absf(ratio - 1.2) < 0.03, "water hits on a Damp nightmare deal +20%% (x%.2f)" % ratio)
	drop.queue_free()
	await _clean()

	print("family finals test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check_data() -> void:
	for parent in TREES:
		var p: TowerData = load("res://resource/tower/%s.tres" % parent)
		for line in TREES[parent]:
			var branch: TowerData = load("res://resource/tower/%s.tres" % line[0])
			_check(p.evolves_to.has(branch), "%s grows into %s" % [parent, line[0]])
			_check(branch.texture != null, "%s has art" % line[0])
			var card: UpgradeData = load("res://resource/dream/dream_%s.tres" % line[0])
			_check(card != null and card.unlocks == branch, "%s has its card" % line[0])
			if line.size() > 1:
				var final: TowerData = load("res://resource/tower/%s.tres" % line[1])
				_check(branch.evolves_to.has(final) and final.tier == 3 and final.evolve_cost == 300,
					"%s grows into %s (final, 300 Dew)" % [line[0], line[1]])
				_check(load("res://resource/dream/dream_%s.tres" % line[1]) != null, "%s has its card" % line[1])
			else:
				_check(branch.tier == 3 and branch.evolve_cost == 300, "%s is a final form (300 Dew)" % line[0])
	for final in ASCEND:
		var data: TowerData = load("res://resource/tower/%s.tres" % final)
		_check(data.evolves_to.has(load("res://resource/tower/%s.tres" % ASCEND[final])),
			"%s can ascend into %s" % [final, ASCEND[final]])

# Runs a pull's drag to the end (the test's nightmares don't process); returns its seconds.
func _wait_drag(enemy: Node2D) -> float:
	var frames := 0
	while is_instance_valid(enemy) and enemy.is_dragged() and frames < 300:
		enemy._update_drag(1.0 / 60.0)
		frames += 1
	return frames / 60.0

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _lost(enemy: Node2D) -> int:
	return enemy.max_health - enemy.health

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

# A nightmare walking the route, standing on route cell `index`.
func _walker(route: PackedVector2Array, index: int) -> Node2D:
	var enemy := _spawn(Tower.MAP_GRID.calculate_map_position(route[0]))
	enemy.set_path(route)
	enemy._path_index = index + 1
	enemy.global_position = Tower.MAP_GRID.calculate_map_position(route[index])
	return enemy

func _clean() -> void:
	for child in spawner.get_children():
		child.queue_free()
	await process_frame
