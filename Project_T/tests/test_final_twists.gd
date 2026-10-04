extends SceneTree

# Headless test for the final forms' signature twists (tower_design.md "Signature twists for the other
# finals", FinalTwists): each sets up its case and checks the rule. Logjam's queue and Veil's no-heal
# live in Enemy Code's movement / heal code; here they check the Warden's side (the jam mark, veil_time).
# Run from the project folder:
#   godot --headless --path . --script res://tests/test_final_twists.gd --fixed-fps 60

const CELL := 64.0

var failures := 0
var main: Node
var spawner
var placer: TowerPlacer
var container: Node
var run_state: RunState
var dreams: DreamState
var route: PackedVector2Array
var per := 1  # Route points per whole cell (half-step routes: 2)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	spawner = main.get_node("%EnemyContainer")
	placer = main.get_node("%TowerPlacer")
	container = main.get_node("%TowerContainer")
	run_state = main.get_node("%RunState")
	dreams = main.get_node("%DreamState")
	run_state.invulnerable = true
	await _clean()
	var map = main.get_node("%MapGenerator")
	route = map.get_path_from(map.startPath)
	per = FinalTwists._per_cell(route)

	for id in FinalTwists.TWISTS:
		var data: TowerData = load("res://resource/tower/%s.tres" % id)
		_check(data != null and data.tier == 3, "%s is a final form with a twist" % id)

	await _snugroot()
	await _dreamshroom()
	await _boulderback()
	await _lullaby_bell()
	await _morning_fog()
	await _hoarfrost()
	await _beacon()
	await _midsummer()
	await _starcave()
	await _great_dreamcatcher()
	await _grafted_elder()
	await _starling()
	await _zephyr()
	await _windmill()
	await _elf_circle()

	print("final twists test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

# Snugroot, Logjam: a walker it Holds is marked to jam its cell (the spawner queues those behind it);
# flyers aren't.
func _snugroot() -> void:
	var snug := _plant("snugroot", route[8] + Vector2(0, 1))
	snug.position = _at(route[8]) + Vector2(0, CELL)
	var walker := _walker(8)
	var flyer := _spawn(_at(route[9]), "dandelion_seed")
	snug._update_ability(0.1)
	_check(walker.statuses.is_held() and walker.get_meta(FinalTwists.LOGJAM_META, false), "Logjam: a walker Snugroot Holds jams its cell")
	_check(not flyer.get_meta(FinalTwists.LOGJAM_META, false), "flyers never jam")
	# The queue (Enemy Code's spawner + _is_blocked_ahead): the walker behind waits, it doesn't path around.
	var behind := _walker(8 - per)  # A body behind (one whole cell)
	var route_before: PackedVector2Array = behind._path.duplicate()
	behind.set_process(true)
	for i in 30:
		await process_frame
	_check(behind.get_current_cell() == _cell_of(route[8 - per]) and behind.waiting, "the nightmare behind a jammed cell waits there (%s)" % behind.get_current_cell())
	_check(behind._path == route_before, "and doesn't path around (the route is unchanged)")
	behind.set_process(false)
	snug.queue_free()
	await _clean()

# Dreamshroom, Dream spores: an asleep nightmare in its range gives those within 1 cell 1 Spored a second.
func _dreamshroom() -> void:
	var shroom := _plant("dreamshroom", Vector2(5, 5))
	var sleeper := _spawn(shroom.global_position + Vector2(CELL, 0))
	var near := _spawn(sleeper.global_position + Vector2(0.8 * CELL, 0))
	var far := _spawn(sleeper.global_position + Vector2(0, 1.6 * CELL))
	sleeper.statuses.sleep_time = 5.0
	FinalTwists.update(shroom, FinalTwists.DREAM_SPORES_EVERY)
	_check(near.statuses.stacks(EnemyStatuses.SPORED) == 1, "Dream spores: a sleeper's neighbour gets 1 Spored")
	_check(not far.statuses.has(EnemyStatuses.SPORED), "not 1.6 cells away")
	FinalTwists.update(shroom, 0.5)
	_check(near.statuses.stacks(EnemyStatuses.SPORED) == 1, "…once a second, not every frame")
	# Balancing's nerf: stacks at half Dreamshroom's soothe, and shared, so a second Dreamshroom doesn't double it.
	_check(absf(near.statuses.potency(EnemyStatuses.SPORED) - shroom.get_damage() * FinalTwists.DREAM_SPORES_SOOTHE * Tower.SPORE_POTENCY)
		< 0.01 * maxf(near.statuses.potency(EnemyStatuses.SPORED), 1.0), "Dream spores apply at half Dreamshroom's soothe (%.2f)" % near.statuses.potency(EnemyStatuses.SPORED))
	var second := _plant("dreamshroom", Vector2(5, 6))
	FinalTwists.update(second, FinalTwists.DREAM_SPORES_EVERY)
	_check(near.statuses.stacks(EnemyStatuses.SPORED) == 1, "a second Dreamshroom on the same sleeper doesn't puff again (shared)")
	sleeper.statuses.tick(FinalTwists.DREAM_SPORES_EVERY)
	FinalTwists.update(second, FinalTwists.DREAM_SPORES_EVERY)
	_check(near.statuses.stacks(EnemyStatuses.SPORED) == 2, "a second later the sleeper puffs again")
	second.queue_free()
	sleeper.statuses.sleep_time = 0.0
	near.statuses.remove(EnemyStatuses.SPORED)
	FinalTwists.update(shroom, FinalTwists.DREAM_SPORES_EVERY)
	_check(not near.statuses.has(EnemyStatuses.SPORED), "awake nightmares don't breathe spores")
	shroom.queue_free()
	await _clean()

# Boulderback, Landslide: every 4th hit also hits nightmares on the 2 path tiles behind the target (60%).
func _boulderback() -> void:
	var boulder := _plant("boulderback", route[12] + Vector2(1, 0))
	boulder.tower_data = boulder.tower_data.duplicate()
	boulder.tower_data.crit_chance = 0.0
	boulder.tower_data.id = "boulderback"  # A duplicate has no path to take its id from
	boulder._apply_data()
	var target := _walker(12)
	var behind := _walker(12 - 2 * per)  # 2 path tiles back
	var ahead := _walker(12 + 2 * per)
	for i in 3:
		boulder.projectile_landed(target, target.global_position)
	_check(_lost(behind) == 0, "no boulder for the first 3 hits")
	boulder.projectile_landed(target, target.global_position)
	_check(_lost(behind) > 0 and absi(_lost(behind) - int(boulder.get_damage() * FinalTwists.LANDSLIDE_SHARE)) <= 1,
		"the 4th rolls a boulder: 60%% to a nightmare 2 tiles back (%d)" % _lost(behind))
	_check(_lost(ahead) == 0, "only toward the start")
	boulder.queue_free()
	await _clean()

# Lullaby Bell, Chorus: +10% per other Bellflower-family Warden within 3 cells, max +40%.
func _lullaby_bell() -> void:
	var bell := _plant("lullaby_bell", Vector2(10, 10))
	bell._refresh_neighbours()
	var alone := bell.get_damage()
	var singers: Array[Tower] = []
	for at in [Vector2(11, 10), Vector2(9, 10), Vector2(10, 12), Vector2(12, 12), Vector2(8, 8), Vector2(10, 8)]:
		singers.append(_plant("bellflower", at))
	var far := _plant("chime_stone", Vector2(15, 10))  # 5 cells away: no voice
	bell._refresh_neighbours()
	_check(is_equal_approx(bell._chorus, FinalTwists.CHORUS_MAX), "Chorus caps at +40%% with 6 voices (%.2f)" % bell._chorus)
	_check(absf(bell.get_damage() - alone * (1.0 + FinalTwists.CHORUS_MAX)) < 0.5, "and its damage shows it")
	for s in singers.slice(2):
		s.queue_free()
	await process_frame
	bell._refresh_neighbours()
	_check(is_equal_approx(bell._chorus, 2 * FinalTwists.CHORUS_PER), "2 voices: +20%% (%.2f)" % bell._chorus)
	for t in [bell, far] + singers.slice(0, 2):
		t.queue_free()
	await _clean()

# Morning Fog, Veil: inside its fog Lurkers are revealed and nothing can be healed (veil_time).
func _morning_fog() -> void:
	var fog_warden := _plant("morning_fog", Vector2(3, 3))
	var at := fog_warden.global_position + Vector2(2 * CELL, 0)
	var inside := _spawn(at)
	var outside := _spawn(at + Vector2(4 * CELL, 0))
	inside._set_hidden(true)
	var cloud := PathCloud.new(fog_warden, at)
	main.add_child(cloud)
	await process_frame
	_check(not inside.is_hidden(), "Veil: a Lurker inside the fog is revealed")
	_check(inside.statuses.veil_time > 0.0 and is_zero_approx(outside.statuses.veil_time), "and can't be healed there (veil_time)")
	for e in [inside, outside]:
		e.health = e.max_health / 2
		e.heal(1000.0)
	_check(inside.health == inside.max_health / 2 and outside.health > outside.max_health / 2, "Veil: mending does nothing inside the fog, but works outside")
	cloud.queue_free()
	fog_warden.queue_free()
	await _clean()

# Hoarfrost, Shatter chain: a frozen nightmare dispelled freezes those within 1 cell for 0.5 s; those
# shard-frozen don't chain again.
func _hoarfrost() -> void:
	var frost := _plant("hoarfrost", Vector2(5, 5))
	frost.set_process(true)
	await process_frame
	var victim := _spawn(frost.global_position + Vector2(CELL, 0))
	var neighbour := _spawn(victim.global_position + Vector2(0.8 * CELL, 0))
	var second := _spawn(neighbour.global_position + Vector2(0.8 * CELL, 0))
	var far := _spawn(victim.global_position + Vector2(0, 3 * CELL))
	victim.statuses.apply(EnemyStatuses.DAMP, 2)
	victim.freeze_cooldown = 0.0
	frost.apply_status_to(victim, frost.get_damage())
	frost.hit(victim, 1.0, false, Tower.NO_CRIT)
	_check(victim.statuses.is_held() and victim.get_meta(&"hoar_frozen", false), "Hoarfrost freezes a twice-Soaked nightmare")
	victim.dispel()
	await process_frame
	_check(neighbour.statuses.is_held(), "Shatter chain: its shards freeze a nightmare within 1 cell")
	_check(neighbour.statuses.time_left(EnemyStatuses.HELD) <= FinalTwists.SHATTER_FREEZE + 0.01, "for 0.5 s")
	_check(not far.statuses.is_held(), "not further away")
	neighbour.dispel()
	await process_frame
	_check(not second.statuses.is_held(), "a shard-frozen nightmare doesn't chain again")
	frost.queue_free()
	await _clean()

# Beacon, Flare: every 8 s the whole map is revealed for 2 s and the 5 furthest along are Marked.
func _beacon() -> void:
	var beacon := _plant("beacon", Vector2(20, 2))
	var walkers: Array[Node2D] = []
	for i in 7:
		walkers.append(_walker(4 + i * 3))
	walkers[0]._set_hidden(true)
	FinalTwists.update(beacon, 0.1)  # The first flare goes as soon as there's something out there
	var marked := walkers.filter(func(w: Node2D) -> bool: return w.statuses.has(EnemyStatuses.MARKED))
	_check(marked.size() == FinalTwists.FLARE_MARKS, "Flare: 5 nightmares Marked, anywhere (%d)" % marked.size())
	_check(not walkers[0].statuses.has(EnemyStatuses.MARKED) and walkers[6].statuses.has(EnemyStatuses.MARKED),
		"the furthest along, not the rest")
	_check(not walkers[0].is_hidden(), "and the map is revealed")
	_check(beacon._twist_state[&"flare"] > FinalTwists.FLARE_EVERY - 0.2, "then waits 8 s")
	beacon.queue_free()
	await _clean()

# Midsummer, Solstice: at full ramp the beam also hits a second target for 2 s.
func _midsummer() -> void:
	var sun := _plant("midsummer", Vector2(5, 5))
	var first := _spawn(sun.global_position + Vector2(CELL, 0))
	var second := _spawn(sun.global_position + Vector2(0, 2 * CELL))
	sun._beam_target = first
	sun._beam_ramp = 1.0
	FinalTwists.solstice_tick(sun, 1.0)
	_check(_lost(second) == 0, "below full ramp: one target")
	sun._beam_ramp = sun.attack_data.beam_ramp_max
	FinalTwists.solstice_tick(sun, 1.0)
	_check(_lost(second) > 0, "Solstice: at full ramp the beam forks onto a second target")
	_check(is_equal_approx(sun._beam_ramp, sun.attack_data.beam_ramp_max), "the ramp is kept")
	FinalTwists.update(sun, FinalTwists.SOLSTICE_TIME + 0.1)
	var before := _lost(second)
	FinalTwists.solstice_tick(sun, 1.0)
	_check(_lost(second) == before, "after 2 s it's one beam again (until the next full ramp)")
	sun.queue_free()
	await _clean()

# Starcave, Starlit snare: each lit tile Holds the first walker to step on it each drift for 0.5 s.
func _starcave() -> void:
	var cave := _plant("starcave", route[10] + Vector2(1, 0))
	cave.position = _at(route[10]) + Vector2(CELL, 0)
	cave._light()
	_check(not cave._lit_cells.is_empty(), "Starcave lights path tiles")
	var lit: Vector2 = cave._lit_cells[0]
	for c in cave._lit_cells:  # The lit tile nearest the cave (a half-cell route point sits off the tile centre)
		if _at(c).distance_to(cave.global_position) < _at(lit).distance_to(cave.global_position):
			lit = c
	var first := _walker(_index_of_cell(lit))
	FinalTwists.update(cave, FinalTwists.SNARE_CHECK)
	_check(first.statuses.is_held(), "Starlit snare: the first walker on a lit tile is Held")
	first.statuses.remove(EnemyStatuses.HELD)
	var next := _walker(_index_of_cell(lit))
	FinalTwists.update(cave, FinalTwists.SNARE_CHECK)
	_check(not next.statuses.is_held(), "only the first each drift")
	cave.queue_free()
	await _clean()

# Great Dreamcatcher, Mended leaves: every 25 Caught dispels in its range restore a leaf (bosses count
# 5), at most 3 a run.
func _great_dreamcatcher() -> void:
	var catcher := _plant("great_dreamcatcher", Vector2(5, 5))
	FinalTwists.update(catcher, 0.1)  # Starts listening
	run_state.max_leaves = 15
	run_state.leaves = 5
	for i in 24:
		var caught := _spawn(catcher.global_position + Vector2(CELL, 0))
		caught.statuses.caught_time = 5.0
		caught.dispel()
	await process_frame
	_check(run_state.leaves == 5, "24 Caught dispels: no leaf yet (%d)" % run_state.leaves)
	var last := _spawn(catcher.global_position + Vector2(CELL, 0))
	last.statuses.caught_time = 5.0
	last.dispel()
	await process_frame
	_check(run_state.leaves == 6, "the 25th restores a leaf (%d)" % run_state.leaves)
	var plain := _spawn(catcher.global_position + Vector2(CELL, 0))
	plain.dispel()
	await process_frame
	for i in 100:
		var more := _spawn(catcher.global_position + Vector2(CELL, 0))
		more.statuses.caught_time = 5.0
		more.dispel()
	await process_frame
	_check(run_state.leaves == 5 + FinalTwists.MENDED_MAX, "at most 3 a run (%d)" % run_state.leaves)
	catcher.queue_free()
	await _clean()

# Grafted Elder, Double graft: alternates between its two strongest neighbours' attacks.
func _grafted_elder() -> void:
	var elder := _plant("grafted_elder", Vector2(10, 10))
	var a := _plant("moonstone", Vector2(11, 10))
	var b := _plant("rockslide", Vector2(9, 10))
	_plant("sporeling", Vector2(10, 11))
	elder._refresh_neighbours()
	var pair: Array = elder._twist_state.get(&"graft_pair", [])
	_check(pair.size() == 2 and pair.has(a.tower_data) and pair.has(b.tower_data), "Double graft: its two strongest neighbours")
	var seen := {}
	for i in 4:
		FinalTwists.next_graft(elder)
		seen[elder.attack_data] = true
	_check(seen.size() == 2, "and it alternates between their attacks")
	for t in container.get_children():
		t.queue_free()
	await _clean()

# Starling Murmuration, Dark swirl: every 6 s a swirl on the busiest path tile in range for 2 s; Phantoms
# (flyers) gliding through it are Held 0.5 s, once each.
func _starling() -> void:
	var flock := _plant("starling_murmuration", route[12] + Vector2(1, 0))
	flock.position = _at(route[12]) + Vector2(CELL, 0)
	var crowd: Array[Node2D] = []
	for i in 3:
		crowd.append(_walker(12))
	var phantom := _spawn(_at(route[12]), "dandelion_seed")
	FinalTwists.update(flock, 0.1)
	_check(flock._twist_state.get(&"swirl_left", 0.0) > 0.0 and flock._twist_state[&"swirl_at"].distance_to(_at(route[12])) < 1.0,
		"Dark swirl forms on the busiest path tile")
	_check(phantom.hold_time > 0.0 and not phantom.statuses.is_held(), "a Phantom gliding through it stops (a pause, not Held)")
	_check(not crowd[0].statuses.is_held(), "walkers aren't")
	phantom.hold_time = 0.0
	FinalTwists.update(flock, 0.1)
	_check(is_zero_approx(phantom.hold_time), "once each")
	flock.queue_free()
	await _clean()

# Zephyr, Gale lane: every 10 s copies the most afflicted nightmare's statuses (half stacks) onto
# everything on 3 path tiles in range.
func _zephyr() -> void:
	var zephyr := _plant("zephyr", route[12] + Vector2(1, 0))
	zephyr.position = _at(route[12]) + Vector2(CELL, 0)
	var sick := _walker(11)
	sick.statuses.apply(EnemyStatuses.SPORED, 6, 5.0, 1.0)
	var lane: Array[Node2D] = []
	var tiles: Array = []  # The 3 whole path tiles in range nearest the Heartwood (as the gale picks them)
	var cells := Tower.route_cells(route)
	for i in range(cells.size() - 1, -1, -1):
		if zephyr._is_cell_in_range(cells[i]):
			tiles.append(_index_of_cell(cells[i]))
			if tiles.size() == FinalTwists.GALE_TILES:
				break
	for i in tiles:
		lane.append(_walker(i))
	FinalTwists.update(zephyr, 0.1)
	_check(lane.all(func(e: Node2D) -> bool: return e == sick or e.statuses.stacks(EnemyStatuses.SPORED) == 3),
		"Gale lane: half the stacks on everything on 3 path tiles (%s)" % [lane.map(func(e: Node2D) -> int: return e.statuses.stacks(EnemyStatuses.SPORED))])
	_check(zephyr._twist_state[&"gale"] > FinalTwists.GALE_EVERY - 0.2, "then waits 10 s")
	zephyr.queue_free()
	await _clean()

# Windmill, Momentum: +5% attack speed a second with nightmares in reach, max +50%, back to 0 after 2 s idle.
func _windmill() -> void:
	var mill := _plant("windmill", Vector2(5, 5))
	var base := mill.get_attacks_per_second()
	var pest := _spawn(mill.global_position + Vector2(CELL, 0))
	for i in 4:
		FinalTwists.update(mill, 1.0)
	_check(absf(mill.get_attacks_per_second() - base * 1.2) < 0.01, "Momentum: +20%% after 4 s (%.2f vs %.2f)" % [mill.get_attacks_per_second(), base])
	for i in 20:
		FinalTwists.update(mill, 1.0)
	_check(absf(mill.get_attacks_per_second() - base * 1.5) < 0.01, "capped at +50%")
	pest.queue_free()
	await process_frame
	FinalTwists.update(mill, 1.0)
	_check(mill.get_attacks_per_second() > base, "still spun up after 1 s idle")
	FinalTwists.update(mill, 1.5)
	_check(is_equal_approx(mill.get_attacks_per_second(), base), "back to its base after 2 s idle")
	mill.queue_free()
	await _clean()

# Elf Circle, Fairy dance: setting off 3 of its rings in one walk Holds a nightmare 1 s, once.
func _elf_circle() -> void:
	var circle := _plant("elf_circle", Vector2(5, 5))
	var dancer := _spawn(circle.global_position + Vector2(CELL, 0))
	for i in 2:
		FinalTwists.ring_stepped(circle, dancer)
	_check(not dancer.statuses.is_held(), "two rings: no dance yet")
	FinalTwists.ring_stepped(circle, dancer)
	_check(dancer.statuses.is_held(), "Fairy dance: the 3rd ring Holds it")
	dancer.statuses.remove(EnemyStatuses.HELD)
	for i in 3:
		FinalTwists.ring_stepped(circle, dancer)
	_check(not dancer.statuses.is_held(), "once per nightmare")
	circle.queue_free()
	await _clean()

# --- Helpers ------------------------------------------------------------------------------------------

func _at(cell: Vector2) -> Vector2:
	return Tower.MAP_GRID.calculate_map_position(cell)

# Half-cell routes: the whole cell a route point is in, and the first route point inside whole cell `c`.
func _cell_of(point: Vector2) -> Vector2:
	return Tower.MAP_GRID.calculate_grid_coordinates(_at(point))

func _index_of_cell(c: Vector2) -> int:
	for i in route.size():
		if _cell_of(route[i]) == c:
			return i
	return -1

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

func _spawn(at: Vector2, kind := "leaf_bug") -> Node2D:
	spawner.spawn_enemy(load("res://resource/enemy/%s.tres" % kind))
	var enemy = spawner.get_child(spawner.get_child_count() - 1)
	enemy.set_process(false)
	enemy.global_position = at
	enemy.max_health = 1000000
	enemy.health = 1000000
	return enemy

# A nightmare walking the route, standing on route cell `index`.
func _walker(index: int) -> Node2D:
	var enemy := _spawn(_at(route[0]))
	enemy.set_path(route)
	enemy._path_index = index + 1
	enemy.global_position = _at(route[index])
	return enemy

func _clean() -> void:
	for child in spawner.get_children():
		child.queue_free()
	await process_frame
