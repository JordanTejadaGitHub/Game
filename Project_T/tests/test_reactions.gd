extends SceneTree

# Headless test for Reactions (tower_design.md "Reactions", dream_design.md "Reaction numbers"):
# each of the eight, the per-nightmare cooldown, chains, Lightning Rod redirecting bolts, and the
# DamageLog / ReactionTracker records. Run from the project folder:
#   godot --headless --path . --script res://tests/test_reactions.gd --fixed-fps 60

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
	_check(Reactions.all().size() == 10, "ten Reactions are defined (Sleepwalk and Night Terror 2026-10-17) (%d)" % Reactions.all().size())

	# Reactions need a grown Warden (tower_design.md "Reactions"): the sources here are branch forms.
	var jar := _plant("stormcap", Vector2(2, 2))
	var sporeling := _plant("driftspore", Vector2(2, 4))
	var pebbling := _plant("pebbling", Vector2(2, 6))
	var base := jar.get_damage()
	var origin := Vector2(12.5, 8.5) * CELL  # A cell centre, where nightmares walk

	# --- Thunderclap: Damp + 3 Static. 4× to it, 2× arcs to wet neighbours (+1 Static each) ---
	var a := _spawn(origin)
	var b := _spawn(origin + Vector2(2, 0) * CELL)
	var far := _spawn(origin + Vector2(6, 0) * CELL)
	for e in [a, b, far]:
		e.apply_status(EnemyStatuses.DAMP, 8)
	b.apply_status(EnemyStatuses.STATIC, 9, 0.0, base, 0, "light", jar)  # One arc from a Thunderclap
	a.apply_status(EnemyStatuses.STATIC, 10, 0.0, base, 0, "light", jar)
	_check(_lost(a) == int(base * 18.0),
		"Thunderclap: 4× to the discharger (and 2× back from the chained arc) (%d)" % _lost(a))
	_check(a.statuses.stacks(EnemyStatuses.STATIC) == 1, "it uses up the Static (b's chained arc added 1 back)")
	_check(_lost(far) == 0, "no arc beyond 2.5 cells")
	var tracker := main.get_tree().get_first_node_in_group(ReactionTracker.GROUP) as ReactionTracker
	_check(tracker != null and tracker.counts.get(&"thunderclap", 0) == 2,
		"the arc's Static set off b's own Thunderclap (%s)" % (tracker.counts if tracker else "no tracker"))
	_check(tracker != null and tracker.longest_chain == 2, "a Thunderclap set off by another is a ×2 chain")
	var before: int = tracker.counts.get(&"thunderclap", 0)
	a.apply_status(EnemyStatuses.STATIC, 10, 0.0, base, 0, "light", jar)
	_check(tracker.counts.get(&"thunderclap", 0) == before, "cooldown: not again on the same nightmare right away")
	var log := DamageLog.instance
	if log:
		_check(log.get_tower_stats(jar).get("combos", {}).get(&"thunderclap", 0.0) > 0.0,
			"the DamageLog credits Thunderclap damage to the Firefly Jar")
	await _clean()

	# --- Base Wardens apply statuses but never react; one grown source is enough ---
	var base_jar := _plant("firefly_jar", Vector2(6, 2))
	var base_spore := _plant("sporeling", Vector2(6, 4))
	var unreacted := _spawn(origin)
	unreacted.apply_status(EnemyStatuses.SPORED, 16, 5.0, 2.0, 0, "spore", base_spore)
	unreacted.apply_status(EnemyStatuses.STATIC, 8, 0.0, base, 0, "light", base_jar)
	_check(unreacted.statuses.burn_time <= 0.0 and unreacted.statuses.has(EnemyStatuses.STATIC), "two base Wardens: no Ignite (the Charged stays)")
	var mixed := _spawn(origin + Vector2(0, 3) * CELL)
	mixed.apply_status(EnemyStatuses.SPORED, 16, 5.0, 2.0, 0, "spore", base_spore)
	mixed.apply_status(EnemyStatuses.STATIC, 8, 0.0, base, 0, "light", jar)
	_check(mixed.statuses.burn_time > 0.0, "a grown Stormcap's Charged on a base Sporeling's spores: Ignite")
	base_jar.queue_free()
	base_spore.queue_free()
	await _clean()

	# --- Ignite (status jobs, 2026-09-29): 3+ Spored + Static. The spores burn 3 s (Spored ticks 3x as
	# fast); each second 1 stack spreads within 1 cell; uses up the Static, not the Spored ---
	var potency := 2.0
	var c := _spawn(origin)
	var beside := _spawn(origin + Vector2(0.8, 0) * CELL)
	var calm := _spawn(origin + Vector2(0, 4) * CELL)
	c.apply_status(EnemyStatuses.SPORED, 16, 5.0, potency, 0, "spore", sporeling)
	calm.apply_status(EnemyStatuses.SPORED, 16, 5.0, potency, 0, "spore", sporeling)
	c.apply_status(EnemyStatuses.STATIC, 8, 0.0, base, 0, "light", jar)
	_check(c.statuses.burn_time > 0.0 and c.statuses.has(EnemyStatuses.SPORED), "Ignite: the spores burn, the Spored stays")
	_check(not c.statuses.has(EnemyStatuses.STATIC), "it uses up the Static")
	var burning: float = c.statuses.tick(1.0)
	var calm_tick: float = calm.statuses.tick(1.0)
	_check(absf(burning - calm_tick * Reactions.BURN_SPORE_RATE) < calm_tick * 0.4, "burning Spored ticks 3x as fast (%.1f vs %.1f)" % [burning, calm_tick])
	# The burn's extra share of a Spored tick is the "ignite" combo (Balancing: the sims couldn't see it),
	# credited to the Spored applier; a calm nightmare's tick has none.
	c.take_damage(30.0, "spore", true, false, sporeling, &"spored")
	var burnt: DamageLog.Event = c.recent_hits.back()
	var share: float = 1.0 - 1.0 / c.statuses.burn_rate
	_check(burnt.combos.has(&"ignite") and burnt.source == sporeling and (burnt.combos.size() > 1 or absf(burnt.combo_amount - burnt.amount * share) < 0.01),
		"a burning Spored tick: its extra share is the ignite combo (%s, %.2f of %.2f)" % [burnt.combos, burnt.combo_amount, burnt.amount])
	calm.take_damage(30.0, "spore", true, false, sporeling, &"spored")
	_check(not calm.recent_hits.back().combos.has(&"ignite"), "a calm Spored tick carries no ignite")
	calm.queue_free()
	await _wait(1.1)
	_check(beside.statuses.stacks(EnemyStatuses.SPORED) >= 1, "after a second, a Spored stack spreads to the neighbour")
	await _clean()

	# --- A Charged bolt is credited to the Warden whose charge it was (story chat: Live Wire seemed to buff
	# spores): a weaker applier adding the last stack doesn't take the bolt (or Live Wire's share of it) ---
	var charged := _spawn(origin)
	charged.apply_status(EnemyStatuses.STATIC, 19, 0.0, base, 0, "light", jar)
	charged.apply_status(EnemyStatuses.STATIC, 8, 0.0, base * 0.25, 0, "light", sporeling)
	var bolts: Array = charged.recent_hits.filter(func(e: DamageLog.Event) -> bool: return e.tag == &"static") if is_instance_valid(charged) else []
	_check(not bolts.is_empty() and bolts.all(func(e: DamageLog.Event) -> bool: return e.source == jar),
		"the 5th Charged from a spore Warden sets off the bolt, credited to the Stormcap that charged it (%s)" % [bolts.map(func(e) -> String: return e.source.name if e.source else "none")])
	await _clean()

	# --- Mushrooming: 12 Spored + 8 Damp. A spore cloud on the tile: a zone, +30% effect damage inside (owner
	# 2026-10-17, council reactions_unique.md: no extra Poisoned, and the cloud adds none); uses up Damp ---
	var m := _spawn(origin)
	m.apply_status(EnemyStatuses.SPORED, 12, 5.0, potency, 0, "spore", sporeling)
	m.apply_status(EnemyStatuses.DAMP, 8)
	_check(not m.statuses.has(EnemyStatuses.DAMP) and m.statuses.mushroom_time > 0.0, "Mushrooming: it stands in the zone, Damp used up")
	var clouds := main.get_children().filter(func(n: Node) -> bool: return n is ReactionCloud)
	_check(clouds.size() == 1, "a spore cloud grows on its tile")
	var walker := _spawn(m.global_position + Vector2(10, 0))
	var outside := _spawn(m.global_position + Vector2(4, 0) * CELL)
	await _wait(1.1)
	_check(not walker.statuses.has(EnemyStatuses.SPORED), "the cloud no longer gives Spored")
	_check(walker.statuses.mushroom_time > 0.0 and outside.statuses.mushroom_time <= 0.0, "a nightmare inside is in the zone, one outside isn't")
	var zone_ratio := Reactions.effect_multiplier(walker, sporeling) / Reactions.effect_multiplier(outside, sporeling)
	_check(is_equal_approx(zone_ratio, 1.0 + Reactions.MUSHROOM_ZONE_BONUS), "inside: +30%% effect damage (x%.2f)" % zone_ratio)
	await _clean()

	# --- Drown (status jobs, 2026-09-29): Damp + full Drowsy. Pulled under 3 s: slowed 60% and drowning
	# damage each second (0.5x, 1x, 1.5x the applier's damage); no sleep; uses up the Drowsy; once ---
	var d := _spawn(origin)
	d.apply_status(EnemyStatuses.DAMP, 8, 0.0, 0.0, 0, "water", sporeling)
	d.apply_status(EnemyStatuses.DROWSY, 20, 0.0, 0.0, 0, "song", sporeling)
	_check(not d.statuses.is_asleep() and not d.statuses.has(EnemyStatuses.DROWSY), "Drown: no sleep, Drowsy used up")
	var drown_hp: int = d.health
	await _wait(0.2)
	_check(d.statuses.slow_time > 0.0 and d.statuses.slow_amount >= 0.59, "pulled under: 60%% slower (%.2f)" % d.statuses.slow_amount)
	await _wait(1.0)
	var first_second: int = drown_hp - d.health
	_check(absi(first_second - roundi(sporeling.get_damage() * 0.5 * sporeling.get_potency())) <= 2,
		"drowning damage in the first second: 0.5x the applier's damage (%d)" % first_second)
	d.statuses.reaction_cooldowns.clear()
	d.apply_status(EnemyStatuses.DROWSY, 20)
	_check(d.statuses.has(EnemyStatuses.DROWSY), "only once per nightmare (the Drowsy stays the second time)")
	await _clean()

	# --- Pinned: Marked + Held. The next hit is a guaranteed ×3 crit that pierces (owner 2026-10-17, council
	# reactions_unique.md): every nightmare in a 3-cell line behind it, away from the Warden, takes half; uses up Marked ---
	var p := _spawn(origin)
	var no_crit: TowerData = sporeling.tower_data.duplicate()
	no_crit.crit_chance = 0.0
	no_crit.applies_status = &""
	var plain := _plant_data(no_crit, Vector2(4, 2))
	var line_dir: Vector2 = (origin - plain.global_position).normalized()
	var behind := _spawn(origin + line_dir * 2.0 * CELL)
	var past := _spawn(origin + line_dir * 4.0 * CELL)
	var off_line := _spawn(origin + line_dir.orthogonal() * 2.0 * CELL)
	var in_front := _spawn(origin - line_dir * 1.5 * CELL)
	p.apply_status(EnemyStatuses.HELD, 4, 5.0)
	p.apply_status(EnemyStatuses.MARKED, 10)
	_check(p.statuses.pinned and not p.statuses.has(EnemyStatuses.MARKED), "Pinned: primed, Marked used up")
	plain.hit(p, 1.0, false, Tower.NO_CRIT)
	var pin_hit := plain.get_damage() * Reactions.PINNED_MULTIPLIER
	_check(_lost(p) == int(pin_hit), "the next hit is a ×3 crit (%d)" % _lost(p))
	_check(absi(_lost(behind) - int(pin_hit * Reactions.PIN_PIERCE_SHARE)) <= 1, "it pierces: a nightmare 2 cells behind takes half (%d)" % _lost(behind))
	_check(_lost(past) == 0 and _lost(off_line) == 0 and _lost(in_front) == 0,
		"not 4 cells behind, beside the line or in front of it (%d, %d, %d)" % [_lost(past), _lost(off_line), _lost(in_front)])
	_check(not p.statuses.pinned, "only one hit")
	await _clean()

	# --- Shatter: Held + Damp, then a heavy (stone) hit: ×2.5, shards 50% within 1 cell ---
	var s := _spawn(origin)
	var shard := _spawn(origin + Vector2(0.7, 0) * CELL)
	s.apply_status(EnemyStatuses.HELD, 4, 5.0)
	s.apply_status(EnemyStatuses.DAMP, 8)
	var heavy: TowerData = pebbling.tower_data.duplicate()
	heavy.crit_chance = 0.0
	var stone := _plant_data(heavy, Vector2(4, 4))
	stone.hit(s, 1.0, false, Tower.NO_CRIT)
	var hit := stone.get_damage() * 4.0
	_check(_lost(s) == int(hit), "Shatter: the heavy hit does ×2.5 (%d)" % _lost(s))
	_check(not s.statuses.is_held(), "and the freeze ends")
	_check(_lost(shard) == int(hit * 0.5), "shards deal half to a neighbour (%d)" % _lost(shard))
	await _clean()

	# --- Smother: Held + Spored. While held its Spored stops ticking and swells; when the Root breaks it all bursts at
	# x2 (owner 2026-10-17, council reactions_unique.md; was x3 ticks) ---
	var sm := _spawn(origin)
	var control := _spawn(origin + Vector2(5, 0) * CELL)
	for e in [sm, control]:
		e.apply_status(EnemyStatuses.SPORED, 12, 5.0, potency, 0, "spore", sporeling)
	sm.apply_status(EnemyStatuses.HELD, 4, 5.0)
	_check(tracker.counts.get(&"smother", 0) >= 1, "Smother fires")
	for e in [sm, control]:
		e.set_process(true)
	await _wait(1.0)
	_check(_lost(sm) == 0 and sm.statuses.smother_stored > 0.0 and _lost(control) > 0,
		"held, its spores don't tick: they swell (%d lost, %.1f stored; the other lost %d)" % [_lost(sm), sm.statuses.smother_stored, _lost(control)])
	var swollen: float = sm.statuses.smother_stored
	var control_lost := _lost(control)
	sm.statuses.remove(EnemyStatuses.HELD)  # The Root breaks
	await process_frame
	await process_frame
	_check(sm.statuses.smother_stored == 0.0 and _lost(sm) >= int(swollen * Reactions.SMOTHER_BURST * 0.9) and _lost(sm) >= int(control_lost * 1.6),
		"the Root breaks: it all bursts at once, x2 (%d lost, %.1f stored, the other %d)" % [_lost(sm), swollen, control_lost])
	await _clean()

	# --- Lightning Rod: Marked + Static. A Static bolt nearby strikes it instead at ×2 ---
	var rod := _spawn(origin)
	var struck := _spawn(origin + Vector2(2, 0) * CELL)
	rod.apply_status(EnemyStatuses.STATIC, 10, 0.0, base, 0, "light", jar)
	rod.apply_status(EnemyStatuses.MARKED, 10)
	var rod_before := _lost(rod)
	struck.apply_status(EnemyStatuses.STATIC, 20, 0.0, base, 0, "light", jar)  # A 5-stack bolt
	var bolt := base * EnemyStatuses.STATIC_BOLT_MULTIPLIER
	_check(_lost(struck) == 0, "the bolt doesn't hit the charged nightmare")
	_check(_lost(rod) - rod_before == int(bolt * 2.0 * (1.0 + EnemyStatuses.MARKED_EXTRA)),
		"the Lightning Rod takes it at ×2 (Marked still applies) (%d)" % (_lost(rod) - rod_before))
	_check(tracker.counts.get(&"lightning_rod", 0) >= 1, "Lightning Rod fires")

	print("reactions test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _wait(seconds: float) -> void:
	await create_timer(seconds, true, true).timeout

func _lost(enemy: Node2D) -> int:
	return enemy.max_health - enemy.health

func _plant(id: String, cell: Vector2) -> Tower:
	return _plant_data(load("res://resource/tower/%s.tres" % id), cell)

func _plant_data(data: TowerData, cell: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = data
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
		if node is ReactionCloud:
			node.queue_free()
	await process_frame
