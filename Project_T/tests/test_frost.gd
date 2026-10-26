extends SceneTree

# Headless test for Frost's Reaction side (dream_council_review.md 37; numbers Balancing 2026-10-25, balance_simulation.md
# "Frost: numbers"; Reaction Code bd8ae9af): the Frostburst chain (4 nearest within 1 cell, the 2.25x chain hit, 1 quiet
# Frost that stops at cap - 2, 3 links at x0.75, the 2 s lock, 8 chain bursts a second, 2 area hits per 0.5 s) and the
# three Frost Reactions at a Warden-completed burst (Brittle, Frostbite, Flash Freeze; never a chain's, never under
# Undiluted; one per burst in that order).
# Adds main.tscn under root by hand (never the current scene), so nothing touches the player's saves.
#   godot --headless --path . --script res://tests/test_frost.gd --fixed-fps 60

const CELL := 64.0
const POTENCY := 10.0

var failures := 0
var main: Node
var spawner
var placer: TowerPlacer
var container: Node
var tracker: ReactionTracker
var fern: Tower

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
	fern = _plant("frostfern", Vector2(2, 2))
	var origin := Vector2(12.5, 8.5) * CELL

	# --- Data ---
	_check(Reactions.all().size() == 13, "13 base Reactions with the three Frost ones (%d)" % Reactions.all().size())
	for id in Reactions.FROST_REACTIONS:
		var data := Reactions.get_data(id)
		_check(data != null and data.statuses.has(Reactions.FROST), "%s has data with Frost" % id)
		_check(data != null and not IconInfo.format(data.description).contains("{"), "%s: its description formats" % id)
	_check(Reactions.ready_need(EnemyStatuses.FROST, EnemyStatuses.new()) == Reactions.need(Reactions.FROST_NEEDED),
		"the Reaction-ready frame lights Frost at %d" % Reactions.need(Reactions.FROST_NEEDED))

	# --- A burst: the nightmare, its 4 nearest within 1 cell; never a 5th or one further ---
	var target := _spawn(origin)
	var near: Array = []
	for offset in [Vector2(0.4, 0), Vector2(-0.5, 0), Vector2(0, 0.6), Vector2(0, -0.7), Vector2(0.65, 0.65)]:
		near.append(_spawn(origin + offset * CELL))
	var far := _spawn(origin + Vector2(1.6, 0) * CELL)
	tracker = ReactionTracker.find(target)
	_check(tracker != null, "a ReactionTracker is there")
	_frost(target, _cap(target))
	_check(_lost(target) > 0 and not target.statuses.has(EnemyStatuses.FROST) and target.statuses.burst_pending == 0.0,
		"full Frost bursts: it takes damage and its Frost is spent (%d lost)" % _lost(target))
	var hit := near.filter(func(e: Node2D) -> bool: return _lost(e) > 0)
	_check(hit.size() == Reactions.FROST_NEIGHBOURS, "the %d nearest within 1 cell are hit (%d)" % [Reactions.FROST_NEIGHBOURS, hit.size()])
	_check(_lost(near[4]) == 0, "the 5th nearest is not")
	_check(_lost(far) == 0, "one 1.6 cells away is not")
	_check(_lost(near[0]) < _lost(target), "a neighbour takes the smaller chain hit (%d vs %d)" % [_lost(near[0]), _lost(target)])
	_check(near[0].statuses.stacks(EnemyStatuses.FROST) == 0, "the chain's Frost waits for the next frame (never inline)")
	await process_frame
	await process_frame
	_check(near[0].statuses.stacks(EnemyStatuses.FROST) == Reactions.FROST_CHAIN_STACKS,
		"next frame each neighbour gains %d Frost (%d)" % [Reactions.FROST_CHAIN_STACKS, near[0].statuses.stacks(EnemyStatuses.FROST)])
	_check(near[4].statuses.stacks(EnemyStatuses.FROST) == 0 and far.statuses.stacks(EnemyStatuses.FROST) == 0, "…and only they do")
	await _clean()

	# --- Chain Frost is quiet: it stops at the cap - 2 and never bursts on its own ---
	var full_one := _spawn(origin)
	var at_short := _spawn(origin + Vector2(0.5, 0) * CELL)
	var below := _spawn(origin + Vector2(-0.5, 0) * CELL)
	var stop := _cap(at_short) - EnemyStatuses.FROST_QUIET_SHORT
	_frost(at_short, stop)
	_frost(below, stop - 1)
	_frost(full_one, _cap(full_one))
	await process_frame
	await process_frame
	_check(below.statuses.stacks(EnemyStatuses.FROST) == stop, "chain Frost tops one up to %d (%d)" % [stop, below.statuses.stacks(EnemyStatuses.FROST)])
	_check(at_short.statuses.stacks(EnemyStatuses.FROST) == stop and at_short.statuses.burst_pending == 0.0,
		"…but never past it, so no burst nobody dealt (%d)" % at_short.statuses.stacks(EnemyStatuses.FROST))
	await _clean()

	# --- Links: each link x0.75; the 3rd link passes no Frost on ---
	var link0 := _spawn(origin)
	var link1 := _spawn(origin + Vector2(4, 0) * CELL)
	Reactions.frostburst(link0, 100.0, fern)
	Reactions._frost_gen = 1
	Reactions.frostburst(link1, 100.0, fern)
	Reactions._frost_gen = 0
	var ratio := float(_lost(link1)) / maxf(1.0, float(_lost(link0)))
	_check(absf(ratio - Reactions.FROST_CHAIN_FALLOFF) < 0.02, "a link-1 burst deals x%.2f of a Warden's (%.3f)" % [Reactions.FROST_CHAIN_FALLOFF, ratio])
	await _clean()
	for gen in [Reactions.FROST_CHAIN_LINKS - 1, Reactions.FROST_CHAIN_LINKS]:
		var burst := _spawn(origin)
		var beside := _spawn(origin + Vector2(0.5, 0) * CELL)
		tracker._frost_queue.clear()
		Reactions._frost_gen = gen
		Reactions.frostburst(burst, 100.0, fern)
		Reactions._frost_gen = 0
		var queued := tracker._frost_queue.filter(func(entry: Array) -> bool: return entry[0] == beside)
		if gen < Reactions.FROST_CHAIN_LINKS:
			_check(queued.size() == 1 and int(queued[0][3]) == gen + 1, "a link-%d burst passes Frost on as link %d" % [gen, gen + 1])
		else:
			_check(queued.is_empty(), "the link-%d burst passes no Frost on" % gen)
		await _clean()

	# --- The lock: a nightmare that just burst takes no burst-given Frost for 2 s ---
	var burst_a := _spawn(origin)
	var burst_b := _spawn(origin + Vector2(0.5, 0) * CELL)
	Reactions.frostburst(burst_a, 100.0, fern)
	tracker._frost_queue.clear()
	Reactions.frostburst(burst_b, 100.0, fern)
	var to_a := tracker._frost_queue.filter(func(entry: Array) -> bool: return entry[0] == burst_a)
	_check(to_a.is_empty(), "a burst next to one that burst a moment ago passes it by")
	_check(float(burst_a.get_meta(Reactions.FROST_LOCK_META, -INF)) - tracker._clock <= Reactions.FROST_LOCK + 0.01, "the lock lasts %.1f s" % Reactions.FROST_LOCK)
	await _clean()

	# --- Area hits: at most 2 per 0.5 s on one nightmare ---
	var middle := _spawn(origin)
	for offset in [Vector2(0.5, 0), Vector2(-0.5, 0), Vector2(0, 0.5)]:
		Reactions.frostburst(_spawn(origin + offset * CELL), 100.0, fern)
	var area_hits: Array = middle.recent_hits.filter(func(e: DamageLog.Event) -> bool: return e.tag == Reactions.FROSTBURST_TAG)
	_check(area_hits.size() == Reactions.FROST_AREA_HITS, "three bursts around one nightmare hit it %d times (%d)" % [Reactions.FROST_AREA_HITS, area_hits.size()])
	await _clean()

	# --- At most 8 chain bursts a second: the rest wait in the queue, never dropped ---
	var waiting := _spawn(origin)
	_frost(waiting, _cap(waiting) - 1)
	tracker._frost_queue.clear()
	tracker._chain_bursts.clear()
	for n in Reactions.FROST_BURSTS_PER_SECOND:
		tracker.note_chain_burst()
	tracker.queue_frost(waiting, Reactions.FLASH_FREEZE_FROST, fern, 1, true)
	await process_frame
	_check(_lost(waiting) == 0 and tracker._frost_queue.size() == 1, "a 9th chain burst in a second waits in the queue")
	tracker._chain_bursts.clear()
	await process_frame
	_check(_lost(waiting) > 0 and tracker._frost_queue.is_empty(), "…and bursts once there's room")
	await _clean()

	# --- Brittle: Frost + Exposed at its need; the Exposed spent; 3 s / elites 2 s / bosses 1 s; 8 s cooldown ---
	var brittle_before: int = tracker.counts.get(&"brittle", 0)
	var plain := _spawn(origin)
	var elite := _spawn(origin + Vector2(4, 0) * CELL)
	elite.elite = true
	var boss := _spawn(origin + Vector2(0, 4) * CELL, "great_toad")
	for enemy in [plain, elite, boss]:
		enemy.apply_status(EnemyStatuses.MARKED, Reactions.need(Reactions.EXPOSED_NEEDED), 0.0, 0.0, 0, "light", fern)
		enemy.apply_status(EnemyStatuses.SPORED, Reactions.need(Reactions.FROSTBITE_MIN_SPORES), 5.0, 0.0, 0, "spore", fern)
		_frost(enemy, _cap(enemy))
	_check(tracker.counts.get(&"brittle", 0) == brittle_before + 3, "Brittle fires at a burst with %d Exposed" % Reactions.need(Reactions.EXPOSED_NEEDED))
	_check(plain.statuses.stacks(EnemyStatuses.MARKED) < Reactions.need(Reactions.EXPOSED_NEEDED), "it uses up the Exposed")
	_check(Reactions.is_brittle(plain), "the nightmare is Brittle")
	_check(absf(plain.statuses.reaction_cooldowns.get(Reactions.BRITTLE_ON, 0.0) - Reactions.BRITTLE_TIME) < 0.05, "for %.0f s" % Reactions.BRITTLE_TIME)
	_check(absf(elite.statuses.reaction_cooldowns.get(Reactions.BRITTLE_ON, 0.0) - Reactions.BRITTLE_ELITE_TIME) < 0.05, "an elite for %.0f s" % Reactions.BRITTLE_ELITE_TIME)
	_check(absf(boss.statuses.reaction_cooldowns.get(Reactions.BRITTLE_ON, 0.0) - Reactions.BRITTLE_BOSS_TIME) < 0.05, "a boss for %.0f s" % Reactions.BRITTLE_BOSS_TIME)
	_check(plain.statuses.stacks(EnemyStatuses.SPORED) == Reactions.need(Reactions.FROSTBITE_MIN_SPORES), "one Frost Reaction a burst: Brittle first, the Poisoned stays")
	_check(absf(float(plain.BRITTLE_SHELL) - Reactions.BRITTLE_SHELL_SHARE) < 0.001 and plain.BRITTLE_KEY == Reactions.BRITTLE_ON, "Enemy's Brittle mirror is in step")
	await process_frame
	plain.statuses.remove(EnemyStatuses.SPORED)
	plain.apply_status(EnemyStatuses.MARKED, Reactions.need(Reactions.EXPOSED_NEEDED), 0.0, 0.0, 0, "light", fern)
	brittle_before = tracker.counts.get(&"brittle", 0)
	_frost(plain, _cap(plain))
	_check(tracker.counts.get(&"brittle", 0) == brittle_before, "no second Brittle inside its 8 s cooldown")
	await _clean()

	# --- Frostbite: Frost + Poisoned at its need; 2% max health (elites 1.5%, bosses 0.5% on 10 s); oldest half spent ---
	var bite_before: int = tracker.counts.get(&"frostbite", 0)
	var bitten := _spawn(origin)
	var bitten_elite := _spawn(origin + Vector2(4, 0) * CELL)
	bitten_elite.elite = true
	var bitten_boss := _spawn(origin + Vector2(0, 4) * CELL, "great_toad")
	var spores := Reactions.need(Reactions.FROSTBITE_MIN_SPORES)
	for enemy in [bitten, bitten_elite, bitten_boss]:
		enemy.apply_status(EnemyStatuses.SPORED, spores, 5.0, 0.0, 0, "spore", fern)
		_frost(enemy, _cap(enemy))
	_check(tracker.counts.get(&"frostbite", 0) == bite_before + 3, "Frostbite fires at a burst with %d Poisoned" % spores)
	_check(bitten.statuses.stacks(EnemyStatuses.SPORED) <= spores - spores / 2, "it uses up the oldest half of the Poisoned (%d left)" % bitten.statuses.stacks(EnemyStatuses.SPORED))
	for row in [[bitten, Reactions.FROSTBITE_SHARE, "a nightmare"], [bitten_elite, Reactions.FROSTBITE_ELITE_SHARE, "an elite"],
			[bitten_boss, Reactions.FROSTBITE_BOSS_SHARE, "a boss"]]:
		var bite: Array = row[0].recent_hits.filter(func(e: DamageLog.Event) -> bool: return e.tag == &"frostbite")
		var dealt := 0.0
		for e in bite:
			dealt += e.amount
		var share: float = row[1]
		_check(bite.size() == 1 and absf(dealt / (row[0].max_health * share) - 1.0) < 0.35,
			"%s loses about %.1f%% of its max health (%.0f of %.0f)" % [row[2], share * 100.0, dealt, row[0].max_health * share])
	_check(absf(bitten_boss.statuses.reaction_cooldowns.get(&"frostbite", 0.0) - Reactions.FROSTBITE_BOSS_COOLDOWN) < 0.05, "a boss waits %.0f s for the next" % Reactions.FROSTBITE_BOSS_COOLDOWN)
	await _clean()

	# --- Flash Freeze: Frost + Soaked; the burst reaches 2 cells, hits up to 6, gives each 2 Frost (a real application) ---
	var flash_before: int = tracker.counts.get(&"flash_freeze", 0)
	var soaked := _spawn(origin)
	var ring: Array = []
	for n in 7:
		var angle := TAU * n / 7.0
		ring.append(_spawn(origin + Vector2.from_angle(angle) * 1.5 * CELL))
	soaked.apply_status(EnemyStatuses.DAMP, Reactions.need(Reactions.SOAKED_NEEDED), 0.0, 0.0, 0, "water", fern)
	_frost(soaked, _cap(soaked))
	_check(tracker.counts.get(&"flash_freeze", 0) == flash_before + 1, "Flash Freeze fires at a burst with %d Soaked" % Reactions.need(Reactions.SOAKED_NEEDED))
	_check(not soaked.statuses.has(EnemyStatuses.DAMP), "it uses up the Soaked")
	var frozen_hit := ring.filter(func(e: Node2D) -> bool: return _lost(e) > 0)
	_check(frozen_hit.size() == Reactions.FLASH_FREEZE_NEIGHBOURS, "the burst reaches 1.5 cells and hits %d of 7 (%d)" % [Reactions.FLASH_FREEZE_NEIGHBOURS, frozen_hit.size()])
	await process_frame
	await process_frame
	_check(frozen_hit.all(func(e: Node2D) -> bool: return e.statuses.stacks(EnemyStatuses.FROST) == Reactions.FLASH_FREEZE_FROST),
		"next frame each gains %d Frost" % Reactions.FLASH_FREEZE_FROST)
	await _clean()

	# --- Never at a chain's burst, never under Undiluted ---
	var chained := _spawn(origin)
	chained.apply_status(EnemyStatuses.DAMP, Reactions.need(Reactions.SOAKED_NEEDED), 0.0, 0.0, 0, "water", fern)
	flash_before = tracker.counts.get(&"flash_freeze", 0)
	Reactions._frost_gen = 1
	Reactions.frostburst(chained, 100.0, fern)
	Reactions._frost_gen = 0
	_check(tracker.counts.get(&"flash_freeze", 0) == flash_before and chained.statuses.has(EnemyStatuses.DAMP), "a chain's burst sets off no Frost Reaction")
	DreamState.undiluted_on = true
	var diluted := _spawn(origin + Vector2(4, 0) * CELL)
	diluted.apply_status(EnemyStatuses.DAMP, Reactions.need(Reactions.SOAKED_NEEDED), 0.0, 0.0, 0, "water", fern)
	Reactions.frostburst(diluted, 100.0, fern)
	DreamState.undiluted_on = false
	_check(tracker.counts.get(&"flash_freeze", 0) == flash_before, "Undiluted: no Frost Reaction")
	await _clean()

	main.queue_free()
	await process_frame
	print("test_frost: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(failures)

func _frost(enemy: Node2D, stacks: int) -> void:
	enemy.apply_status(EnemyStatuses.FROST, stacks, 0.0, POTENCY, 0, "water", fern)

func _cap(enemy: Node2D) -> int:
	return enemy.statuses.get_max_stacks(EnemyStatuses.FROST)

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

func _spawn(at: Vector2, kind: String = "leaf_bug") -> Node2D:
	spawner.spawn_enemy(load("res://resource/enemy/%s.tres" % kind))
	var enemy = spawner.get_child(spawner.get_child_count() - 1)
	enemy.set_process(false)
	enemy.global_position = at
	enemy.max_health = 1000000
	enemy.health = 1000000
	return enemy

func _clean() -> void:
	for child in spawner.get_children():
		child.queue_free()
	if tracker != null:
		tracker._frost_queue.clear()
		tracker._chain_bursts.clear()
	await process_frame
