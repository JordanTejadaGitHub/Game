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

	_check(Reactions.all().size() == 10, "the base Reactions are ten, Sleepwalk and Night Terror included (%d)" % Reactions.all().size())
	_check(Reactions.crowned().size() == 10, "ten Crowned Reactions have data, Changeling and Wide Awake included (%d)" % Reactions.crowned().size())
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
		e.statuses.apply(EnemyStatuses.DAMP, 8)
	a.statuses.apply(EnemyStatuses.SPORED, 6, 5.0, 2.0, 0, "spore", sporeling)
	# Seed the adjacent target just below Ignite; the arriving arc completes its gate.
	b.statuses.apply(EnemyStatuses.SPORED, 12, 5.0, 2.0, 0, "spore", sporeling)
	b.statuses.apply(EnemyStatuses.STATIC, 7, 0.0, base, 0, "light", jar)
	a.apply_status(EnemyStatuses.STATIC, 10, 0.0, base, 0, "light", jar)
	tracker = main.get_tree().get_first_node_in_group(ReactionTracker.GROUP) as ReactionTracker
	_check(tracker != null and tracker.counts.get(&"tempest", 0) == 1, "Tempest replaces the Thunderclap")
	_check(tracker.counts.get(&"thunderclap", 0) == 0, "no plain Thunderclap alongside it")
	_check(tracker.longest_chain >= 2, "a Crowned Reaction counts as 2 chain links (%d)" % tracker.longest_chain)
	_check(tracker.counts.get(&"ignite", 0) >= 1, "the arc set off Ignite on the Spored neighbour")
	_check(b.statuses.burn_time > 0.0, "the arc set the Spored neighbour burning (status jobs: Ignite burns)")
	await _wait(1.1)
	_check(c.statuses.has(EnemyStatuses.SPORED) and c.statuses.has(EnemyStatuses.STATIC), "its burning spreads carry Static to its neighbour")
	_check(a.statuses.tempest_time > 0.0 and b.statuses.tempest_time > 0.0, "the 2 s Tempest cap is set")
	await _clean()

	# --- Still Pool: Drown on a Held nightmare leaves a pool; the next walker in it sleeps ---
	var d := _spawn(origin)
	d.apply_status(EnemyStatuses.HELD, 4, 5.0)
	d.apply_status(EnemyStatuses.DAMP, 8)
	d.apply_status(EnemyStatuses.DROWSY, 20)
	_check(tracker.counts.get(&"still_pool", 0) == 1, "Still Pool replaces the Drown")
	var pools := _grounds(CrownedGround.Kind.STILL_POOL)
	_check(pools.size() == 1, "a still pool stays on its tile")
	var walker := _spawn(origin)
	if not pools.is_empty():
		pools[0]._tick = 0.0
		pools[0]._process(0.1)
	_check(walker.statuses.sleep_time <= 0.0 and main.get_children().any(func(n) -> bool: return n is Reactions.PullUnder and n.enemy == walker),
		"a walker entering it the first time is pulled under (status jobs: no sleep)")
	await _clean()

	# --- Fever Dream: Smother ends at full Drowsy; Spored resolves, neighbours catch Spored + Drowsy ---
	var f := _spawn(origin)
	var g := _spawn(origin + Vector2(0.8, 0) * CELL)
	f.apply_status(EnemyStatuses.SPORED, 12, 5.0, 2.0, 0, "spore", sporeling)
	f.apply_status(EnemyStatuses.HELD, 4, 5.0)  # Rooted first (Smother): Spored + full Drowsy would be a Sleepwalk (2026-10-17), which uses the Drowsy up
	f.apply_status(EnemyStatuses.DROWSY, 20)
	Reactions.on_smother_ended(f)
	_check(tracker.counts.get(&"fever_dream", 0) == 1, "Fever Dream fires when Smother ends at full Drowsy")
	_check(f.statuses.is_asleep() and f.statuses.has(EnemyStatuses.SPORED), "it falls asleep 2 s, no detonation (status jobs)")
	_check(g.statuses.stacks(EnemyStatuses.SPORED) >= 3 and g.statuses.stacks(EnemyStatuses.DROWSY) >= 2, "the neighbour gets 3 Spored + 2 Drowsy")
	await _clean()

	# --- Starfall (owner 2026-10-17, council reactions_unique.md): the Pinned crit splits into stars. Each Exposed
	# nightmare within 3 cells takes a crit for half the hit. No bolts (council rx review 2026-10-17: Prismstorm's verb) ---
	var h := _spawn(origin)
	var i := _spawn(origin + Vector2(2, 0) * CELL)
	var j := _spawn(origin + Vector2(5, 0) * CELL)
	var lit := _spawn(origin + Vector2(0, 2) * CELL)
	var lit_far := _spawn(origin + Vector2(0, 5) * CELL)
	for e in [h, i, j]:
		e.apply_status(EnemyStatuses.STATIC, 9, 0.0, base, 0, "light", jar)
	for e in [lit, lit_far]:
		e.apply_status(EnemyStatuses.MARKED, 10)
	h.apply_status(EnemyStatuses.MARKED, 10)
	h.apply_status(EnemyStatuses.HELD, 4, 5.0)
	_check(h.statuses.pinned, "Pinned first")
	var h_before := _lost(h)
	jar.hit(h, 1.0, false, Tower.NO_CRIT)
	var pin_dealt := _lost(h) - h_before
	_check(tracker.counts.get(&"starfall", 0) == 1, "Starfall on the Pinned hit")
	_check(i.statuses.has(EnemyStatuses.STATIC) and _lost(i) == 0 and j.statuses.has(EnemyStatuses.STATIC),
		"a Charged (not Exposed) nightmare within 3 cells keeps its Charged and draws no star (%d)" % _lost(i))
	_check(_lost(lit) > 0 and _lost(lit_far) == 0, "an Exposed one within 3 cells is struck by a star, not one beyond (%d of a %d hit)" % [_lost(lit), pin_dealt])
	# The star is half the hit with no second build multiplier (council rx review 2026-10-17); Exposed adds its own share.
	_check(_lost(lit) >= int(pin_dealt * Reactions.STARFALL_SHARE * 0.5) and _lost(lit) <= int(pin_dealt * Reactions.STARFALL_SHARE * 1.6) + 1,
		"a star deals about half the Pinned hit (%d of %d)" % [_lost(lit), pin_dealt])
	_check(not lit.statuses.pinned, "without Falling Stars a star doesn't Pin")
	await _clean()

	# --- Avalanche (owner 2026-10-17): the lob Shatters its target and leaves scree under the stone: walkers slowed 30%
	# and gain 1 Rooted every 0.5 s, up to 4 (no more spread Shatters) ---
	var k := _spawn(origin)
	var l := _spawn(origin + Vector2(0.7, 0) * CELL)
	for e in [k, l]:
		e.apply_status(EnemyStatuses.DAMP, 8)
		e.apply_status(EnemyStatuses.HELD, 4, 5.0)
	cairn.hit(k, 1.0, false, Tower.NO_CRIT)
	_check(tracker.counts.get(&"avalanche", 0) == 1, "a lobbed Shatter is an Avalanche")
	_check(l.statuses.is_held(), "no spread Shatter: the neighbour keeps its Rooted")
	var screes := main.get_children().filter(func(n: Node) -> bool: return n is RubblePatch and n.rooted_every > 0.0)
	_check(screes.size() == 1 and screes[0]._cells.has(Tower.MAP_GRID.calculate_grid_coordinates(origin)), "scree lies on the cell under the stone")
	var on_scree := _spawn(origin + Vector2(0, 0.2) * CELL)
	await _wait(1.15)
	_check(on_scree.statuses.stacks(EnemyStatuses.HELD) >= 2 and on_scree.statuses.slow_time > 0.0,
		"a nightmare on the scree is slowed and builds Rooted (%d)" % on_scree.statuses.stacks(EnemyStatuses.HELD))
	_check(not on_scree.statuses.has(EnemyStatuses.DAMP), "no Soaked without Mountain's Fall")
	await _wait(2.0)
	_check(on_scree.statuses.stacks(EnemyStatuses.HELD) <= Reactions.SCREE_ROOT_MAX, "at most 4 Rooted from the scree")
	await _clean()

	# Overlapping scree never stacks into an endless hold (council rx review 2026-10-17): the count is the nightmare's, so
	# a second patch laid a second later on the same cell gives no more than 4 in all, then the walker rests from scree.
	var scree_cells: Array[Vector2] = [Tower.MAP_GRID.calculate_grid_coordinates(origin)]
	var stuck := _spawn(origin + Vector2(0, 0.2) * CELL)
	for n in 2:
		var patch := RubblePatch.new(scree_cells, Reactions.SCREE_SLOW, Reactions.SCREE_TIME)
		patch.rooted_every = Reactions.SCREE_ROOT_EVERY
		patch.rooted_max = Reactions.SCREE_ROOT_MAX
		patch.rooted_time = Reactions.SCREE_ROOT_TIME
		main.add_child(patch)
		await _wait(1.0)
	await _wait(1.6)
	_check(stuck.statuses.stacks(EnemyStatuses.HELD) <= Reactions.SCREE_ROOT_MAX and stuck.statuses.is_on_cooldown(&"scree"),
		"two overlapping scree patches: 4 Rooted at most in all, then a rest from scree (%d)" % stuck.statuses.stacks(EnemyStatuses.HELD))
	var boss_scree := _spawn(origin + Vector2(0.2, 0) * CELL)
	boss_scree.statuses.is_boss = true
	await _wait(0.6)
	_check(not boss_scree.statuses.has(EnemyStatuses.HELD) and boss_scree.statuses.slow_time > 0.0, "a boss on scree is slowed only")
	await _clean()

	# --- Prismstorm (owner 2026-10-17): a Shatter on a charged nightmare; each shard that hits a nightmare with 8
	# Charged sets off its bolt at once (no Charged spread) ---
	var m := _spawn(origin)
	var n := _spawn(origin + Vector2(0.7, 0) * CELL)
	var dry := _spawn(origin + Vector2(0, 0.7) * CELL)
	m.apply_status(EnemyStatuses.STATIC, 9, 0.0, base, 0, "light", jar)
	n.apply_status(EnemyStatuses.STATIC, 9, 0.0, base, 0, "light", jar)
	m.apply_status(EnemyStatuses.DAMP, 8)
	m.apply_status(EnemyStatuses.HELD, 4, 5.0)
	pebbling.hit(m, 1.0, false, Tower.NO_CRIT)
	_check(tracker.counts.get(&"prismstorm", 0) == 1, "a charged Shatter is a Prismstorm")
	_check(not n.statuses.has(EnemyStatuses.STATIC), "a shard set off the charged neighbour's bolt")
	_check(_lost(dry) > 0 and not dry.statuses.has(EnemyStatuses.STATIC), "the shards no longer add Charged")
	await _clean()

	# --- Nightbloom: Mushrooming at full Drowsy; nothing inside can wake. Crowned precedence (owner 2026-10-17): the
	# Spored that completes both Sleepwalk and Mushrooming at full Drowsy gives the Nightbloom, not a Sleepwalk ---
	var o := _spawn(origin)
	o.statuses.drowned = 1  # Its Drown is spent (Soaked + full Drowsy would Drown first)
	o.apply_status(EnemyStatuses.DROWSY, 20)
	o.apply_status(EnemyStatuses.DAMP, 8)
	var walks: int = tracker.counts.get(&"sleepwalk", 0)
	o.apply_status(EnemyStatuses.SPORED, 12, 5.0, 2.0, 0, "spore", sporeling)
	_check(tracker.counts.get(&"nightbloom", 0) == 1, "Mushrooming at full Drowsy is a Nightbloom")
	_check(tracker.counts.get(&"sleepwalk", 0) == walks and not o.is_sleepwalking() and o.statuses.has(EnemyStatuses.DROWSY),
		"Crowned precedence: no Sleepwalk takes the Drowsy first")
	o.apply_status(EnemyStatuses.SPORED, 1, 5.0, 2.0, 0, "spore", sporeling)
	_check(tracker.counts.get(&"sleepwalk", 0) == walks, "nor later, while the cloud holds it")
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
	q.apply_status(EnemyStatuses.HELD, 4, 5.0)
	q.apply_status(EnemyStatuses.SPORED, 12, 5.0, 2.0, 0, "spore", sporeling)
	q.apply_status(EnemyStatuses.DAMP, 8)
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
	r.apply_status(EnemyStatuses.DAMP, 8)
	var longest := tracker.longest_chain
	tracker.longest_chain = 0
	r.apply_status(EnemyStatuses.STATIC, 10, 0.0, base, 0, "light", jar)
	_check(tracker.longest_chain == 2, "Storm Front: a fresh Thunderclap counts as ×2 (%d)" % tracker.longest_chain)
	tracker.longest_chain = maxi(longest, tracker.longest_chain)
	await _clean()

	# --- Carried Storm: a seed repeats a Reaction at 50% ---
	var samara := _plant("samara", Vector2(4, 2))
	var t := _spawn(origin)
	Reactions.carry(&"thunderclap", t, samara, jar)
	_check(_lost(t) > 0, "Carried Storm repeats a Thunderclap at 50%% (%d)" % _lost(t))
	await _clean()

	# --- The crown mark rides its callout and never stays behind (it's a looping sheet) ---
	await _wait(Fx.CALLOUT_LIFE + 0.3)  # Earlier steps' callouts (and their crowns) are gone
	Fx._callout_cooldown.clear()
	var world_node: Node = main
	Fx.reaction(&"tempest", origin, world_node)
	Fx.reaction(&"tempest", origin + Vector2(0, CELL), world_node)  # Throttled: no callout, so no crown
	var crowns := _find_named(main, "Fx_crowned_crown")
	_check(crowns.size() <= 1, "one crown for one callout, none for a throttled one (%d)" % crowns.size())
	_check(crowns.all(func(c) -> bool: return c.get_parent() is Fx.FxCallout), "the crown belongs to its callout")
	await _wait(Fx.CALLOUT_LIFE + 0.3)
	_check(_find_named(main, "Fx_crowned_crown").is_empty(), "and goes when the callout does")

	# --- Mushroom Rain (card 134): the Mushrooming cloud lasts twice as long and covers the 3×3 ---
	var dreams_node: DreamState = main.get_node("%DreamState")
	var rain_card := UpgradeData.new()
	rain_card.id = "test_mushroom_rain"
	rain_card.rule_id = &"mushroom_rain"
	rain_card.kind = UpgradeData.Kind.RULE
	dreams_node.pool.append(rain_card)
	dreams_node.take(rain_card)
	var rained := _spawn(origin)
	rained.apply_status(EnemyStatuses.SPORED, 12, 5.0, 2.0, 0, "spore", sporeling)
	rained.apply_status(EnemyStatuses.DAMP, 8)
	var rain_clouds := main.get_children().filter(func(n: Node) -> bool: return n is ReactionCloud)
	_check(rain_clouds.size() == 1 and is_equal_approx(rain_clouds[0]._duration, Reactions.MUSHROOM_CLOUD_TIME * Reactions.MUSHROOM_RAIN_TIME)
		and rain_clouds[0]._radius >= CELL * 1.45, "Mushroom Rain: over the 8 tiles around, for half as long")
	dreams_node.stacks.erase(rain_card.id)
	dreams_node.pool.erase(rain_card)
	await _clean()

	# --- A sprinting Night Hound can't be Held: Drown slows it instead of putting it to sleep ---
	var hound := _spawn(origin)
	hound.enemy_data = hound.enemy_data.duplicate()
	hound.enemy_data.immune_while_sprinting = [&"held"] as Array[StringName]
	hound.rolling = true
	_check(Reactions.cant_be_held(hound), "a sprinting Night Hound can't be Held")
	hound.apply_status(EnemyStatuses.DAMP, 8)
	hound.apply_status(EnemyStatuses.DROWSY, 20)
	_check(hound.statuses.sleep_time <= 0.0 and main.get_children().any(func(n) -> bool: return n is Reactions.PullUnder and n.enemy == hound),
		"Drown pulls it under like everyone (status jobs: Drown never sleeps)")
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

	await _test_woven_rules(jar, sporeling, pebbling, cairn, base, origin, tracker)

	print("crowned test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

# The Woven cards' new rules (owner 2026-10-17, council reactions_unique.md: each one changes how its Crowned Reaction
# plays, no number-only cards). Changeling's and Wide Awake's cards are in test_new_reactions.
func _test_woven_rules(jar: Tower, sporeling: Tower, pebbling: Tower, cairn: Tower, base: float, origin: Vector2, tracker: ReactionTracker) -> void:
	# Tempest's Reach: a Tempest's burns also spread 1 Soaked a second.
	var card := _rule_on("eye_of_the_tempest")
	var burner := _spawn(origin)
	var beside := _spawn(origin + Vector2(0.8, 0) * CELL)
	burner.apply_status(EnemyStatuses.SPORED, 12, 5.0, 2.0, 0, "spore", sporeling)
	Reactions.burn(burner, sporeling, 1, base)  # A Tempest burn (it carries Static)
	await _wait(1.1)
	_check(beside.statuses.has(EnemyStatuses.DAMP) and beside.statuses.has(EnemyStatuses.STATIC), "Tempest's Reach: the burn spreads Soaked too")
	_rule_off(card)
	await _clean()
	var plain_burner := _spawn(origin)
	var dry := _spawn(origin + Vector2(0.8, 0) * CELL)
	plain_burner.apply_status(EnemyStatuses.SPORED, 12, 5.0, 2.0, 0, "spore", sporeling)
	Reactions.burn(plain_burner, sporeling, 1, base)
	await _wait(1.1)
	_check(not dry.statuses.has(EnemyStatuses.DAMP), "…not without the card")
	await _clean()

	# Deep Stillness: each nightmare pulled under widens the pool onto the next path cell.
	card = _rule_on("deep_stillness")
	var grid := Tower.MAP_GRID
	var walker := _spawn(origin)
	var point: Vector2 = walker._path[4]
	walker.global_position = grid.calculate_map_position(point)
	walker._path_index = 5
	var cells: Array[Vector2] = [grid.calculate_grid_coordinates(walker.global_position)]
	var pool := CrownedGround.new(CrownedGround.Kind.STILL_POOL, cells, Reactions.STILL_POOL_TIME)
	pool.grows = true
	main.add_child(pool)
	pool._pool(walker)
	_check(pool._cells.size() == 2 and Array(walker._path.slice(5, 13)).map(func(p): return grid.calculate_grid_coordinates(grid.calculate_map_position(p))).has(pool._cells[1]),
		"Deep Stillness: the pool spreads onto the next path cell (%s)" % [pool._cells])
	_rule_off(card)
	await _clean()

	# Endless Night: a sleeper dispelled inside the cloud leaves a new Nightbloom, once per cloud.
	var bloom := CrownedGround.new(CrownedGround.Kind.NIGHTBLOOM, [], Reactions.NIGHTBLOOM_TIME, origin, CELL)
	bloom.chains = true
	main.add_child(bloom)
	var sleeper := _spawn(origin)
	var sleeper2 := _spawn(origin + Vector2(0.3, 0) * CELL)
	for e in [sleeper, sleeper2]:
		e.statuses.sleep_time = 1.0
	bloom._tick = 0.0
	bloom._process(0.1)
	sleeper.dispel()
	sleeper2.dispel()
	bloom._tick = 0.0
	bloom._process(0.1)
	bloom._tick = 0.0
	bloom._process(0.1)
	_check(_grounds(CrownedGround.Kind.NIGHTBLOOM).size() == 2, "Endless Night: a sleeper dispelled inside blooms one new Nightbloom, once per cloud (%d)" % _grounds(CrownedGround.Kind.NIGHTBLOOM).size())
	await _clean()

	# Fever Pitch: the neighbours who catch the fever fall Asleep 1 s too.
	card = _rule_on("fever_pitch")
	var f := _spawn(origin)
	var g := _spawn(origin + Vector2(0.8, 0) * CELL)
	f.apply_status(EnemyStatuses.SPORED, 12, 5.0, 2.0, 0, "spore", sporeling)
	f.apply_status(EnemyStatuses.HELD, 4, 5.0)
	f.apply_status(EnemyStatuses.DROWSY, 20)
	Reactions.on_smother_ended(f)
	_check(g.statuses.is_asleep() and g.statuses.has(EnemyStatuses.SPORED), "Fever Pitch: the neighbour catches the fever and falls Asleep")
	_rule_off(card)
	await _clean()

	# Falling Stars: each nightmare a star hits is Pinned: a x2 crit next, no pierce.
	card = _rule_on("falling_stars")
	var h := _spawn(origin)
	var lit := _spawn(origin + Vector2(0, 2) * CELL)
	lit.apply_status(EnemyStatuses.MARKED, 10)
	h.apply_status(EnemyStatuses.STATIC, 9, 0.0, base, 0, "light", jar)
	h.apply_status(EnemyStatuses.MARKED, 10)
	h.apply_status(EnemyStatuses.HELD, 4, 5.0)
	h.statuses.reaction_cooldowns.clear()
	jar.hit(h, 1.0, false, Tower.NO_CRIT)
	_check(lit.statuses.pinned and lit.statuses.star_pinned, "Falling Stars: the star Pins the nightmare it hits")
	var reaction := Reactions.before_hit(lit, jar, false)
	_check(reaction.crit and is_equal_approx(reaction.crit_multiplier, maxf(Reactions.STAR_PIN_CRIT, jar.attack_data.crit_multiplier)) and not reaction.pierce,
		"…its next hit is a x2 crit that doesn't pierce (x%.2f)" % reaction.crit_multiplier)
	_rule_off(card)
	await _clean()

	# Prism Heart: the shards fly along the path, 3 cells ahead and behind, not to the cells around it.
	card = _rule_on("prism_heart")
	var m := _spawn(origin)
	var route_cells := {}
	for p in m._path:
		route_cells[grid.calculate_grid_coordinates(grid.calculate_map_position(p))] = true
	var at_index := 10
	m.global_position = grid.calculate_map_position(m._path[at_index])
	m._path_index = at_index + 1
	var ahead := _spawn(grid.calculate_map_position(m._path[at_index + 3]))
	var m_cell := grid.calculate_grid_coordinates(m.global_position)
	var off: Node2D = null
	for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		if not route_cells.has(m_cell + d):
			off = _spawn(grid.calculate_map_position(m_cell + d) + Vector2(0, 0))
			break
	m.apply_status(EnemyStatuses.STATIC, 9, 0.0, base, 0, "light", jar)
	m.apply_status(EnemyStatuses.DAMP, 8)
	m.apply_status(EnemyStatuses.HELD, 4, 5.0)
	m.statuses.reaction_cooldowns.clear()
	pebbling.hit(m, 1.0, false, Tower.NO_CRIT)
	_check(_lost(ahead) > 0, "Prism Heart: a nightmare on the path ahead takes a shard (%d)" % _lost(ahead))
	_check(off == null or _lost(off) == 0, "…one beside it off the path doesn't")
	_rule_off(card)
	await _clean()

	# Mountain's Fall: the scree also Soaks the nightmares on it.
	card = _rule_on("mountains_fall")
	var k := _spawn(origin)
	k.apply_status(EnemyStatuses.DAMP, 8)
	k.apply_status(EnemyStatuses.HELD, 4, 5.0)
	k.statuses.reaction_cooldowns.clear()
	cairn.hit(k, 1.0, false, Tower.NO_CRIT)
	var on_scree := _spawn(origin + Vector2(0, 0.2) * CELL)
	await _wait(0.6)
	_check(on_scree.statuses.has(EnemyStatuses.DAMP), "Mountain's Fall: the scree Soaks walkers")
	_rule_off(card)
	await _clean()

func _rule_on(id: String) -> UpgradeData:
	var dreams_node: DreamState = main.get_node("%DreamState")
	var card := UpgradeData.new()
	card.id = "test_" + id
	card.rule_id = StringName(id)
	card.kind = UpgradeData.Kind.RULE
	dreams_node.pool.append(card)
	dreams_node.take(card)
	return card

func _rule_off(card: UpgradeData) -> void:
	var dreams_node: DreamState = main.get_node("%DreamState")
	dreams_node.stacks.erase(card.id)
	dreams_node.pool.erase(card)

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
		if node is ReactionCloud or node is CrownedGround or node is RubblePatch or node is Reactions.WardenWake:
			node.queue_free()
	await process_frame

func _find_named(node: Node, prefix: String) -> Array:
	var found := []
	for child in node.get_children():
		if String(child.name).begins_with(prefix):
			found.append(child)
		found.append_array(_find_named(child, prefix))
	return found

func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout
