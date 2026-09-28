extends SceneTree

# Headless test for Crowned Reactions (tower_design.md "Crowned Reactions", dream_design.md "Crowned
# Reaction numbers"): each of the eight, 2 chain links, the delivery rules (Grafted Harmony, Storm
# Front, Carried Storm). Run from the project folder:
#   godot --headless --path . --script res://tests/test_crowned.gd --fixed-fps 60

const CELL := 64.0


var failures := 0
var main: Node
var spawner
var placer: TowerPlacer
var container: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	spawner = main.get_node("%EnemyContainer")
	placer = main.get_node("%TowerPlacer")
	container = main.get_node("%TowerContainer")
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

	_check(Reactions.all().size() == 8, "the base Reactions stay eight (%d)" % Reactions.all().size())
	_check(Reactions.crowned().size() == 8, "eight Crowned Reactions have data (%d)" % Reactions.crowned().size())
	for data in Reactions.crowned():
		_check(data.display_name != "" and data.effect != &"", "%s has a name and an effect" % data.id)

	var jar := _plant("firefly_jar", Vector2(2, 2))
	var sporeling := _plant("sporeling", Vector2(2, 4))
	var pebbling := _plant("pebbling", Vector2(2, 6))
	var cairn := _plant("cairn", Vector2(2, 8))
	var base := jar.get_damage()
	var origin := Vector2(12.5, 8.5) * CELL
	var tracker: ReactionTracker

	# --- Tempest: Thunderclap on a Spored nightmare; arcs Ignite Spored targets, spores carry Static ---
	var a := _spawn(origin)
	var b := _spawn(origin + Vector2(2, 0) * CELL)
	var c := _spawn(origin + Vector2(2.8, 0) * CELL)
	for e in [a, b]:
		e.apply_status(EnemyStatuses.DAMP)
		e.apply_status(EnemyStatuses.SPORED, 2, 5.0, 2.0, 0, "spore", sporeling)
	a.apply_status(EnemyStatuses.STATIC, 3, 0.0, base, 0, "light", jar)
	tracker = main.get_tree().get_first_node_in_group(ReactionTracker.GROUP) as ReactionTracker
	_check(tracker != null and tracker.counts.get(&"tempest", 0) == 1, "Tempest replaces the Thunderclap")
	_check(tracker.counts.get(&"thunderclap", 0) == 0, "no plain Thunderclap alongside it")
	_check(tracker.longest_chain >= 2, "a Crowned Reaction counts as 2 chain links (%d)" % tracker.longest_chain)
	_check(tracker.counts.get(&"ignite", 0) >= 1, "the arc set off Ignite on the Spored neighbour")
	_check(c.statuses.has(EnemyStatuses.SPORED) and c.statuses.has(EnemyStatuses.STATIC), "Ignite's spread spores carried Static")
	_check(a.statuses.tempest_time > 0.0 and b.statuses.tempest_time > 0.0, "the 2 s Tempest cap is set")
	await _clean()

	# --- Still Pool: Drown on a Held nightmare leaves a pool; the next walker in it sleeps ---
	var d := _spawn(origin)
	d.apply_status(EnemyStatuses.HELD, 1, 5.0)
	d.apply_status(EnemyStatuses.DAMP)
	d.apply_status(EnemyStatuses.DROWSY, 5)
	_check(tracker.counts.get(&"still_pool", 0) == 1, "Still Pool replaces the Drown")
	var pools := _grounds(CrownedGround.Kind.STILL_POOL)
	_check(pools.size() == 1, "a still pool stays on its tile")
	var walker := _spawn(origin)
	if not pools.is_empty():
		pools[0]._tick = 0.0
		pools[0]._process(0.1)
	_check(walker.statuses.sleep_time >= 1.0 - 0.01, "a walker entering it the first time sleeps 1 s")
	await _clean()

	# --- Fever Dream: Smother ends at full Drowsy; Spored resolves, neighbours catch Spored + Drowsy ---
	var f := _spawn(origin)
	var g := _spawn(origin + Vector2(0.8, 0) * CELL)
	f.apply_status(EnemyStatuses.SPORED, 2, 5.0, 2.0, 0, "spore", sporeling)
	f.apply_status(EnemyStatuses.DROWSY, 5)
	Reactions.on_smother_ended(f)
	_check(tracker.counts.get(&"fever_dream", 0) == 1, "Fever Dream fires when Smother ends at full Drowsy")
	_check(_lost(f) > 0 and not f.statuses.has(EnemyStatuses.SPORED), "its Spored resolves at once (%d)" % _lost(f))
	_check(g.statuses.stacks(EnemyStatuses.SPORED) >= 3 and g.statuses.stacks(EnemyStatuses.DROWSY) >= 2, "the neighbour gets 3 Spored + 2 Drowsy")
	await _clean()

	# --- Starfall: a Pinned hit on a charged nightmare pulls Static bolts within 3 cells into it ---
	var h := _spawn(origin)
	var i := _spawn(origin + Vector2(2, 0) * CELL)
	var j := _spawn(origin + Vector2(5, 0) * CELL)
	for e in [h, i, j]:
		e.apply_status(EnemyStatuses.STATIC, 2, 0.0, base, 0, "light", jar)
	h.apply_status(EnemyStatuses.MARKED)
	h.apply_status(EnemyStatuses.HELD, 1, 5.0)
	_check(h.statuses.pinned, "Pinned first")
	jar.hit(h, 1.0, false, Tower.NO_CRIT)
	_check(tracker.counts.get(&"starfall", 0) == 1, "Starfall on the Pinned hit")
	_check(not i.statuses.has(EnemyStatuses.STATIC) and j.statuses.has(EnemyStatuses.STATIC), "bolts within 3 cells were pulled in, not beyond")
	await _clean()

	# --- Avalanche: a lob's Shatter spreads to every Damp + Held nightmare under it ---
	var k := _spawn(origin)
	var l := _spawn(origin + Vector2(0.7, 0) * CELL)
	for e in [k, l]:
		e.apply_status(EnemyStatuses.DAMP)
		e.apply_status(EnemyStatuses.HELD, 1, 5.0)
	cairn.hit(k, 1.0, false, Tower.NO_CRIT)
	_check(tracker.counts.get(&"avalanche", 0) == 1, "a lobbed Shatter is an Avalanche")
	_check(not l.statuses.is_held() and _lost(l) > 0, "it shattered the Damp + Held neighbour too")
	await _clean()

	# --- Prismstorm: a Shatter on a charged nightmare; shards add 2 Static ---
	var m := _spawn(origin)
	var n := _spawn(origin + Vector2(0.7, 0) * CELL)
	m.apply_status(EnemyStatuses.STATIC, 2, 0.0, base, 0, "light", jar)
	m.apply_status(EnemyStatuses.DAMP)
	m.apply_status(EnemyStatuses.HELD, 1, 5.0)
	pebbling.hit(m, 1.0, false, Tower.NO_CRIT)
	_check(tracker.counts.get(&"prismstorm", 0) == 1, "a charged Shatter is a Prismstorm")
	_check(n.statuses.stacks(EnemyStatuses.STATIC) >= 2, "the shards gave the neighbour 2 Static")
	await _clean()

	# --- Nightbloom: Mushrooming at full Drowsy; nothing inside can wake ---
	var o := _spawn(origin)
	o.apply_status(EnemyStatuses.DROWSY, 5)
	o.apply_status(EnemyStatuses.SPORED, 3, 5.0, 2.0, 0, "spore", sporeling)
	o.apply_status(EnemyStatuses.DAMP)
	_check(tracker.counts.get(&"nightbloom", 0) == 1, "Mushrooming at full Drowsy is a Nightbloom")
	var blooms := _grounds(CrownedGround.Kind.NIGHTBLOOM)
	_check(blooms.size() == 1, "its violet cloud grows")
	o.statuses.sleep_time = 0.05
	if not blooms.is_empty():
		blooms[0]._tick = 0.0
		blooms[0]._process(0.1)
	_check(o.statuses.sleep_time >= 0.1, "a sleeper inside can't wake")
	await _clean()

	# --- Fairy Circle: Mushrooming on a Held nightmare; rings on the path tiles around it ---
	var map = main.get_node("%MapGenerator")
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var q := _spawn(Tower.MAP_GRID.calculate_map_position(route[6]))
	q.apply_status(EnemyStatuses.HELD, 1, 5.0)
	q.apply_status(EnemyStatuses.SPORED, 3, 5.0, 2.0, 0, "spore", sporeling)
	q.apply_status(EnemyStatuses.DAMP)
	_check(tracker.counts.get(&"fairy_circle", 0) == 1, "Mushrooming on a Held nightmare is a Fairy Circle")
	var rings := _grounds(CrownedGround.Kind.FAIRY_RING)
	_check(rings.size() == 1 and rings[0]._cells.size() >= 2, "mushroom rings on the path tiles around it")
	if not rings.is_empty() and not rings[0]._cells.is_empty():
		var ring_cell: Vector2 = rings[0]._cells[0]
		var stepper := _spawn(Tower.MAP_GRID.calculate_map_position(ring_cell))
		rings[0]._tick = 0.0
		rings[0]._process(0.1)
		_check(stepper.statuses.stacks(EnemyStatuses.SPORED) >= 2, "the first walker on a ring gets Spored")
	await _clean()

	# --- Storm Front: a Reaction completed by a Gust-copied status counts one more link ---
	var r := _spawn(origin)
	r.statuses.gust_time = 0.5
	r.apply_status(EnemyStatuses.DAMP)
	var longest := tracker.longest_chain
	tracker.longest_chain = 0
	r.apply_status(EnemyStatuses.STATIC, 3, 0.0, base, 0, "light", jar)
	_check(tracker.longest_chain == 2, "Storm Front: a fresh Thunderclap counts as ×2 (%d)" % tracker.longest_chain)
	tracker.longest_chain = maxi(longest, tracker.longest_chain)
	await _clean()

	# --- Carried Storm: a seed repeats a Reaction at 50% ---
	var samara := _plant("samara", Vector2(4, 2))
	var t := _spawn(origin)
	Reactions.carry(&"thunderclap", t, samara, jar)
	_check(_lost(t) > 0, "Carried Storm repeats a Thunderclap at 50%% (%d)" % _lost(t))
	await _clean()

	# --- A sprinting Night Hound can't be Held: Drown slows it instead of putting it to sleep ---
	var hound := _spawn(origin)
	hound.enemy_data = hound.enemy_data.duplicate()
	hound.enemy_data.immune_while_sprinting = [&"held"] as Array[StringName]
	hound.rolling = true
	_check(Reactions.cant_be_held(hound), "a sprinting Night Hound can't be Held")
	hound.apply_status(EnemyStatuses.DAMP)
	hound.apply_status(EnemyStatuses.DROWSY, 5)
	_check(hound.statuses.sleep_time <= 0.0 and hound.statuses.slow_time > 0.0,
		"so Drown slows it instead of putting it to sleep")
	hound.rolling = false
	_check(not Reactions.cant_be_held(hound), "once it stops sprinting it can be Held again")
	await _clean()

	# --- Grafted Harmony: a Graftling touching two status families applies both at half ---
	var graft := _plant("graftling", Vector2(8, 3))
	var jar2 := _plant("firefly_jar", Vector2(8, 4))
	var spore2 := _plant("sporeling", Vector2(9, 3))
	graft._refresh_neighbours()
	_check(graft._harmony.size() == 2, "Grafted Harmony: Static and Spored (%s)" % graft._harmony)
	var u := _spawn(origin)
	graft.hit(u, 1.0, false, Tower.NO_CRIT)
	_check(u.statuses.has(EnemyStatuses.SPORED) and u.statuses.has(EnemyStatuses.STATIC), "its hits apply both statuses")
	for tower in [jar2, spore2, graft]:
		tower.queue_free()

	print("crowned test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _grounds(kind: CrownedGround.Kind) -> Array:
	return main.get_children().filter(func(n: Node) -> bool: return n is CrownedGround and n.kind == kind)

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

# A sturdy, still nightmare.
func _spawn(at: Vector2) -> Node2D:
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	var enemy = spawner.get_child(spawner.get_child_count() - 1)
	enemy.set_process(false)
	enemy.global_position = at
	enemy.max_health = 1000000
	enemy.health = 1000000
	return enemy

func _clean() -> void:
	for child in spawner.get_children():
		child.queue_free()
	for node in main.get_children():
		if node is ReactionCloud or node is CrownedGround:
			node.queue_free()
	await process_frame
