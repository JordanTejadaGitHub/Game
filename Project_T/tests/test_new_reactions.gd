extends SceneTree

# Headless test for the two Drowsy Reactions (Roguelite Code for the owner, 2026-10-17; council uniqueness review the
# same day): Sleepwalk (Poisoned + full Drowsy: walks back up the route, and turns round who it bumps) and Night Terror
# (Charged + full Drowsy: a normal Charged bolt, and the nightmares around it Rooted in fear). Also the one-full-Drowsy
# rule: Drown, Night Terror, Sleepwalk, Pinned in that order, the first to fire uses the Drowsy up.
# Adds main.tscn under root by hand (never the current scene), so nothing touches the player's saves.
#   godot --headless --path . --script res://tests/test_new_reactions.gd --fixed-fps 60

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

	_check(Reactions.get_data(&"sleepwalk") != null and Reactions.get_data(&"night_terror") != null, "both Reactions have data")
	for id in [&"sleepwalk", &"night_terror"]:
		var data := Reactions.get_data(id)
		_check(data != null and not IconInfo.format(data.description).contains("{"), "%s: its description formats" % id)

	# Grown sources (Reactions need a branch form): a Stormcap's Charged, a Driftspore's Poisoned and Drowsy.
	var jar := _plant("stormcap", Vector2(2, 2))
	var spore := _plant("driftspore", Vector2(2, 4))
	var base := jar.get_damage()
	var origin := Vector2(12.5, 8.5) * CELL

	# --- Night Terror: Charged at its need + full Drowsy ---
	var a := _spawn(origin)
	var near := _spawn(origin + Vector2(1.5, 0) * CELL)
	var far := _spawn(origin + Vector2(3.0, 0) * CELL)
	var toad := _spawn(origin + Vector2(0, 1.5) * CELL, "great_toad")
	var king := _spawn(origin + Vector2(-1.5, 0) * CELL, "barrow_king")
	a.apply_status(EnemyStatuses.STATIC, Reactions.IGNITE_MIN_STATIC, 0.0, base, 0, "light", jar)
	var stored: float = a.statuses.stored_bolt_damage()
	a.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", spore)
	var tracker := main.get_tree().get_first_node_in_group(ReactionTracker.GROUP) as ReactionTracker
	_check(tracker != null and tracker.counts.get(&"night_terror", 0) == 1, "Night Terror fires at %d Charged + full Drowsy (%s)" % [Reactions.IGNITE_MIN_STATIC, tracker.counts if tracker else "no tracker"])
	_check(not a.statuses.has(EnemyStatuses.STATIC) and not a.statuses.has(EnemyStatuses.DROWSY), "it spends the Charged and uses up the Drowsy")
	var bolts: Array = a.recent_hits.filter(func(e: DamageLog.Event) -> bool: return e.tag == &"static")
	_check(_lost(a) > 0 and not bolts.is_empty() and _lost(a) <= stored * 1.6 + 1.0,
		"its Charged goes off as one normal bolt, no x2 (%d lost, stored bolt %.1f)" % [_lost(a), stored])
	_check(near.statuses.is_held() and near.statuses.stacks(EnemyStatuses.HELD) >= Reactions.NIGHT_TERROR_ROOT_STACKS
		and absf(near.statuses.time_left(EnemyStatuses.HELD) - Reactions.NIGHT_TERROR_ROOT) < 0.05,
		"a nightmare 1.5 cells away is Rooted 1 s with 2 stacks (%d stacks, %.2f s)" % [near.statuses.stacks(EnemyStatuses.HELD), near.statuses.time_left(EnemyStatuses.HELD)])
	_check(not far.statuses.is_held(), "one 3 cells away is not")
	_check(toad.statuses.is_held() and absf(toad.statuses.time_left(EnemyStatuses.HELD) - Reactions.NIGHT_TERROR_BOSS_ROOT) < 0.05,
		"a boss is Rooted half as long (%.2f s)" % toad.statuses.time_left(EnemyStatuses.HELD))
	_check(not king.statuses.is_held(), "a boss immune to Rooted stays immune")
	await _clean()

	# Below the need: no Night Terror, the Drowsy stays.
	var low := _spawn(origin)
	var before: int = tracker.counts.get(&"night_terror", 0)
	low.apply_status(EnemyStatuses.STATIC, Reactions.IGNITE_MIN_STATIC - 1, 0.0, base, 0, "light", jar)
	low.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", spore)
	_check(tracker.counts.get(&"night_terror", 0) == before and low.statuses.has(EnemyStatuses.DROWSY), "one Charged short: no Night Terror")
	await _clean()

	# --- Sleepwalk: Poisoned at its need + full Drowsy (still nightmares: the timer and who it turns) ---
	var sw := _spawn(origin)
	var bumped := _spawn(origin + Vector2(0.5, 0) * CELL)
	var boss_near := _spawn(origin + Vector2(-0.5, 0) * CELL, "great_toad")
	var crow := _spawn(origin + Vector2(0, 0.5) * CELL, "crow")
	before = tracker.counts.get(&"sleepwalk", 0)
	sw.apply_status(EnemyStatuses.SPORED, Reactions.IGNITE_MIN_SPORES, 5.0, 2.0, 0, "spore", spore)
	sw.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", spore)
	_check(tracker.counts.get(&"sleepwalk", 0) == before + 1, "Sleepwalk fires at %d Poisoned + full Drowsy" % Reactions.IGNITE_MIN_SPORES)
	_check(is_equal_approx(sw.sleepwalk_left, Reactions.SLEEPWALK_TIME) and not sw.statuses.has(EnemyStatuses.DROWSY),
		"it sleepwalks 2 s and the Drowsy is used up (%.2f)" % sw.sleepwalk_left)
	# (council rx review 2026-10-17) It bumps only on searches where it moved: standing still, nobody turns.
	await _wait(0.25)
	_check(bumped.sleepwalk_left <= 0.0, "a sleepwalker standing still turns nobody")
	sw.global_position += Vector2(-2, 0)  # (A still test nightmare: moved by hand)
	await _wait(0.15)
	_check(is_equal_approx(bumped.sleepwalk_left, Reactions.SLEEPWALK_TURN_TIME), "a nightmare it touches turns round for 0.5 s (%.2f)" % bumped.sleepwalk_left)
	_check(boss_near.sleepwalk_left <= 0.0, "a boss it touches is never turned")
	_check(crow.sleepwalk_left <= 0.0, "a flyer it touches is never turned")
	bumped.sleepwalk_left = 0.0
	sw.global_position += Vector2(-2, 0)
	await _wait(0.15)
	_check(bumped.sleepwalk_left <= 0.0, "each nightmare is turned once per sleepwalk")
	# A hard lifetime: the Sleepwalker node never outlives its walk by more than SLEEPWALKER_EXTRA_LIFE.
	var walkers: Array = main.get_children().filter(func(n: Node) -> bool: return n is Reactions.Sleepwalker and n.enemy == sw)
	_check(walkers.size() == 1 and walkers[0]._life <= Reactions.SLEEPWALK_TIME + Reactions.SLEEPWALKER_EXTRA_LIFE,
		"its Sleepwalker has a hard lifetime (%s)" % (str(walkers[0]._life) if walkers.size() == 1 else "none"))
	await _clean()

	# --- Sleepwalk can't repeat forever (council rx review 2026-10-17): twice per nightmare, bosses once; the cooldown
	# starts when the walk ends ---
	var again := _spawn(origin)
	before = tracker.counts.get(&"sleepwalk", 0)
	for n in 3:
		await process_frame  # (Reactions skip a repeat of the same check in one frame)
		again.sleepwalk_left = 0.0
		again.statuses.reaction_cooldowns.clear()
		again.apply_status(EnemyStatuses.SPORED, Reactions.IGNITE_MIN_SPORES, 5.0, 2.0, 0, "spore", spore)
		again.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", spore)
	_check(tracker.counts.get(&"sleepwalk", 0) == before + Reactions.SLEEPWALK_TIMES and again.statuses.sleepwalked == Reactions.SLEEPWALK_TIMES
		and again.statuses.has(EnemyStatuses.DROWSY), "a nightmare sleepwalks twice at most; the third full Drowsy stays (%d)" % (tracker.counts.get(&"sleepwalk", 0) - before))
	again.sleepwalk_left = 0.0
	Reactions.start_sleepwalk(again)
	_check(not again.is_sleepwalking(), "…an echo or copy can't give it a third walk either")
	var boss_once := _spawn(origin + Vector2(0, 4) * CELL, "great_toad")
	before = tracker.counts.get(&"sleepwalk", 0)
	for n in 2:
		await process_frame
		boss_once.sleepwalk_left = 0.0
		boss_once.statuses.reaction_cooldowns.clear()
		boss_once.apply_status(EnemyStatuses.SPORED, Reactions.IGNITE_MIN_SPORES, 5.0, 2.0, 0, "spore", spore)
		boss_once.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", spore)
	_check(tracker.counts.get(&"sleepwalk", 0) == before + Reactions.SLEEPWALK_BOSS_TIMES, "a boss sleepwalks once")
	var rest := _spawn(origin + Vector2(4, 0) * CELL)
	_on_route(rest, 10)
	Reactions.start_sleepwalk(rest)
	rest.statuses.reaction_cooldowns.clear()
	rest._walk_back(Reactions.SLEEPWALK_TIME + 0.1)
	_check(not rest.is_sleepwalking() and rest.statuses.is_on_cooldown(&"sleepwalk"), "Sleepwalk's cooldown starts when the walk ends")
	await _clean()

	# --- Never at the Heartwood (council rx review 2026-10-17): a nightmare there (or past its route's end) can't sleepwalk ---
	var home := _spawn(origin)
	home._path_index = home._path.size()
	home.at_heartwood = true
	before = tracker.counts.get(&"sleepwalk", 0)
	home.apply_status(EnemyStatuses.SPORED, Reactions.IGNITE_MIN_SPORES, 5.0, 2.0, 0, "spore", spore)
	home.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", spore)
	_check(tracker.counts.get(&"sleepwalk", 0) == before and not home.is_sleepwalking(), "a nightmare at the Heartwood never sleepwalks")
	home.sleepwalk(1.0, 0.5)
	_check(not home.is_sleepwalking(), "…nor is it turned round there")
	await _clean()

	var short := _spawn(origin)
	before = tracker.counts.get(&"sleepwalk", 0)
	short.apply_status(EnemyStatuses.SPORED, Reactions.IGNITE_MIN_SPORES - 1, 5.0, 2.0, 0, "spore", spore)
	short.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", spore)
	_check(tracker.counts.get(&"sleepwalk", 0) == before and short.statuses.has(EnemyStatuses.DROWSY), "one Poisoned short: no Sleepwalk")
	var flyer := _spawn(origin + Vector2(4, 0) * CELL, "crow")
	flyer.apply_status(EnemyStatuses.SPORED, Reactions.IGNITE_MIN_SPORES, 5.0, 2.0, 0, "spore", spore)
	flyer.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", spore)
	_check(tracker.counts.get(&"sleepwalk", 0) == before and flyer.sleepwalk_left <= 0.0, "a flyer never sleepwalks")
	var boss := _spawn(origin + Vector2(0, 4) * CELL, "great_toad")
	boss.apply_status(EnemyStatuses.SPORED, Reactions.IGNITE_MIN_SPORES, 5.0, 2.0, 0, "spore", spore)
	boss.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", spore)
	_check(is_equal_approx(boss.sleepwalk_left, Reactions.SLEEPWALK_BOSS_TIME), "a boss sleepwalks half as long (%.2f)" % boss.sleepwalk_left)
	await _clean()

	# --- One full Drowsy, one Reaction: Drown before Night Terror, Night Terror before Pinned ---
	var both := _spawn(origin)
	var drowns: int = tracker.counts.get(&"drown", 0)
	before = tracker.counts.get(&"night_terror", 0)
	both.apply_status(EnemyStatuses.DAMP, Reactions.SOAKED_NEEDED, 0.0, 0.0, 0, "water", spore)
	both.apply_status(EnemyStatuses.STATIC, Reactions.IGNITE_MIN_STATIC, 0.0, base, 0, "light", jar)
	both.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", spore)
	_check(tracker.counts.get(&"drown", 0) == drowns + 1 and tracker.counts.get(&"night_terror", 0) == before
		and both.statuses.has(EnemyStatuses.STATIC), "Drown and Night Terror both ready: only Drown fires (the Charged stays)")
	# Crowned precedence (owner 2026-10-17, council reactions_unique.md): Exposed + Charged + full Drowsy is Starfall's
	# set (Pinned by the Drowsy, then the Pinned hit on a charged nightmare), so Night Terror waits for it.
	var marked := _spawn(origin + Vector2(0, 4) * CELL)
	marked.apply_status(EnemyStatuses.MARKED, Reactions.EXPOSED_NEEDED, 0.0, 0.0, 0, "", jar)
	marked.apply_status(EnemyStatuses.STATIC, Reactions.IGNITE_MIN_STATIC, 0.0, base, 0, "light", jar)
	marked.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", spore)
	_check(tracker.counts.get(&"night_terror", 0) == before and marked.statuses.pinned and not marked.statuses.has(EnemyStatuses.DROWSY)
		and marked.statuses.has(EnemyStatuses.STATIC), "Starfall's set: no Night Terror, Pinned takes the Drowsy and the Charged stays")
	var stars: int = tracker.counts.get(&"starfall", 0)
	jar.hit(marked, 1.0, false, Tower.NO_CRIT)
	_check(tracker.counts.get(&"starfall", 0) == stars + 1, "…and the Pinned hit is a Starfall")
	await _clean()

	# --- Changeling (Crowned Sleepwalk on an Exposed nightmare, owner 2026-10-17): it trades places with the nightmare
	# furthest along within 3 cells, then sleepwalks back from there ---
	var changer := _spawn(origin)
	var leader := _spawn(origin)
	var behind := _spawn(origin)
	var far_ahead := _spawn(origin)
	var grid := Tower.MAP_GRID
	_on_route(changer, 8)
	_on_route(leader, 12)
	_on_route(behind, 6)
	_on_route(far_ahead, 30)
	var changer_at: Vector2 = changer.global_position
	var leader_at: Vector2 = leader.global_position
	var leader_left: float = leader.get_remaining_distance()
	changer.apply_status(EnemyStatuses.MARKED, Reactions.EXPOSED_NEEDED, 0.0, 0.0, 0, "", jar)
	changer.apply_status(EnemyStatuses.SPORED, Reactions.IGNITE_MIN_SPORES, 5.0, 2.0, 0, "spore", spore)
	var swaps: int = tracker.counts.get(&"changeling", 0)
	var walks: int = tracker.counts.get(&"sleepwalk", 0)
	changer.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", spore)
	_check(tracker.counts.get(&"changeling", 0) == swaps + 1 and tracker.counts.get(&"sleepwalk", 0) == walks,
		"Sleepwalk on an Exposed nightmare is a Changeling (%s)" % tracker.counts)
	_check(changer.global_position.distance_to(leader_at) < 1.0 and leader.global_position.distance_to(changer_at) < 1.0,
		"it trades places with the nightmare furthest along within 3 cells")
	_check(is_equal_approx(changer.get_remaining_distance(), leader_left) and changer.is_sleepwalking(), "…takes its place on the route, then sleepwalks back")
	_check(not leader.is_sleepwalking() and not changer.statuses.pinned, "the leader doesn't walk back without Stolen Away; no Pinned from the Drowsy")
	_check(far_ahead.global_position.distance_to(grid.calculate_map_position(far_ahead._path[30])) < 1.0, "one beyond 3 cells stays put")
	await _clean()

	# Stolen Away (its Woven card): the one it traded with sleepwalks back 1 s too.
	var stolen := _rule_on("stolen_away")
	var changer2 := _spawn(origin)
	var leader2 := _spawn(origin)
	_on_route(changer2, 8)
	_on_route(leader2, 11)
	changer2.apply_status(EnemyStatuses.MARKED, Reactions.EXPOSED_NEEDED, 0.0, 0.0, 0, "", jar)
	changer2.apply_status(EnemyStatuses.SPORED, Reactions.IGNITE_MIN_SPORES, 5.0, 2.0, 0, "spore", spore)
	changer2.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", spore)
	_check(is_equal_approx(leader2.sleepwalk_left, Reactions.STOLEN_WALK), "Stolen Away: the traded one sleepwalks back 1 s (%.2f)" % leader2.sleepwalk_left)
	_rule_off(stolen)
	await _clean()

	# (council rx review 2026-10-17) Never a boss Changeling: an Exposed boss only Sleepwalks, and stays where it is.
	var boss_changer := _spawn(origin, "great_toad")
	var boss_leader := _spawn(origin)
	_on_route(boss_changer, 8)
	_on_route(boss_leader, 11)
	var boss_at: Vector2 = boss_changer.global_position
	swaps = tracker.counts.get(&"changeling", 0)
	boss_changer.apply_status(EnemyStatuses.MARKED, Reactions.EXPOSED_NEEDED, 0.0, 0.0, 0, "", jar)
	boss_changer.apply_status(EnemyStatuses.SPORED, Reactions.IGNITE_MIN_SPORES, 5.0, 2.0, 0, "spore", spore)
	boss_changer.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", spore)
	_check(tracker.counts.get(&"changeling", 0) == swaps and boss_changer.global_position.distance_to(boss_at) < 1.0 and boss_changer.is_sleepwalking(),
		"an Exposed boss never trades places: it only Sleepwalks")
	await _clean()

	# (council rx review 2026-10-17) By route, never across walls: a nightmare close in a straight line but standing on
	# a later stretch of the route (another corridor) is never the partner.
	var walled := _spawn(origin)
	var corridor := _spawn(origin)
	_on_route(walled, 8)
	var far_index: int = mini(40, corridor._path.size() - 2)
	_on_route(corridor, far_index)
	corridor.global_position = walled.global_position + Vector2(0, 1.5) * CELL  # Close by straight line, far along the route
	corridor._path_index = far_index + 1
	var walled_at: Vector2 = walled.global_position
	swaps = tracker.counts.get(&"changeling", 0)
	walled.apply_status(EnemyStatuses.MARKED, Reactions.EXPOSED_NEEDED, 0.0, 0.0, 0, "", jar)
	walled.apply_status(EnemyStatuses.SPORED, Reactions.IGNITE_MIN_SPORES, 5.0, 2.0, 0, "spore", spore)
	walled.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", spore)
	_check(tracker.counts.get(&"changeling", 0) == swaps + 1 and walled.global_position.distance_to(walled_at) < 1.0,
		"a nightmare in another corridor (close, but not on its route ahead) is never traded with")
	await _clean()

	# --- Drowsy vs sleep and Catch (council rx review 2026-10-17) ---
	# Asleep: Sleepwalk and Night Terror wait (the Drowsy stays) until it wakes.
	var sleeper := _spawn(origin)
	var sleeper2 := _spawn(origin + Vector2(0, 4) * CELL)
	sleeper.statuses.sleep(3.0)
	sleeper2.statuses.sleep(3.0)
	before = tracker.counts.get(&"night_terror", 0)
	walks = tracker.counts.get(&"sleepwalk", 0)
	sleeper.apply_status(EnemyStatuses.STATIC, Reactions.IGNITE_MIN_STATIC, 0.0, base, 0, "light", jar)
	sleeper.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", spore)
	sleeper2.apply_status(EnemyStatuses.SPORED, Reactions.IGNITE_MIN_SPORES, 5.0, 2.0, 0, "spore", spore)
	sleeper2.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", spore)
	_check(tracker.counts.get(&"night_terror", 0) == before and tracker.counts.get(&"sleepwalk", 0) == walks and sleeper.statuses.is_asleep()
		and sleeper.statuses.has(EnemyStatuses.DROWSY) and sleeper2.statuses.has(EnemyStatuses.DROWSY),
		"an Asleep nightmare: no Night Terror or Sleepwalk, it stays asleep and keeps the Drowsy")
	await _clean()
	# Dreamshroom's own sleep lands before the Drowsy Reactions spend the Drowsy.
	var shroom := _plant("dreamshroom", Vector2(2, 6))
	var dozer := _spawn(origin)
	walks = tracker.counts.get(&"sleepwalk", 0)
	dozer.apply_status(EnemyStatuses.SPORED, Reactions.IGNITE_MIN_SPORES, 5.0, 2.0, 0, "spore", spore)
	dozer.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", shroom)
	_check(dozer.statuses.is_asleep() and tracker.counts.get(&"sleepwalk", 0) == walks, "Dreamshroom's full Drowsy: it falls Asleep first, no Sleepwalk")
	shroom.queue_free()
	await _clean()
	# Inside a Dreamcatcher's range they wait too, so the Catch works.
	var catcher := _plant("dreamcatcher", Vector2(12, 8))
	var caught := _spawn(origin)
	walks = tracker.counts.get(&"sleepwalk", 0)
	caught.apply_status(EnemyStatuses.SPORED, Reactions.IGNITE_MIN_SPORES, 5.0, 2.0, 0, "spore", spore)
	caught.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", spore)
	_check(tracker.counts.get(&"sleepwalk", 0) == walks and caught.statuses.is_catchable(), "in a Dreamcatcher's range: no Sleepwalk, still catchable")
	catcher.queue_free()
	await _clean()
	# Fever Dream: no Sleepwalk while a Smother is running (Rooted + Poisoned); the Drowsy stays for the Fever Dream.
	var fevered := _spawn(origin)
	walks = tracker.counts.get(&"sleepwalk", 0)
	fevered.apply_status(EnemyStatuses.SPORED, Reactions.IGNITE_MIN_SPORES, 5.0, 2.0, 0, "spore", spore)
	fevered.apply_status(EnemyStatuses.HELD, Reactions.ROOTED_NEEDED, 5.0)
	fevered.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", spore)
	_check(tracker.counts.get(&"sleepwalk", 0) == walks and fevered.statuses.has(EnemyStatuses.DROWSY), "a Smother running: Sleepwalk waits, the Drowsy stays")
	await _clean()

	# Night Terror's wait for a Starfall ends: a Pinned, Charged nightmare no Warden can reach still screams.
	var lonely := _spawn(origin)
	lonely.statuses.pinned = true
	before = tracker.counts.get(&"night_terror", 0)
	lonely.apply_status(EnemyStatuses.STATIC, Reactions.IGNITE_MIN_STATIC, 0.0, base, 0, "light", jar)
	lonely.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", spore)
	_check(tracker.counts.get(&"night_terror", 0) == before + 1, "a Pin out of every Warden's reach doesn't hold Night Terror back")
	await _clean()

	# Heavy Heart's copy of Night Terror strikes the stored bolt and spends the Drowsy (council rx review 2026-10-17).
	var copied := _spawn(origin)
	copied.apply_status(EnemyStatuses.STATIC, Reactions.IGNITE_MIN_STATIC - 1, 0.0, base, 0, "light", jar)
	copied.apply_status(EnemyStatuses.DROWSY, 3, 0.0, 0.0, 0, "song", spore)
	var copy_bolt: float = copied.statuses.stored_bolt_damage()
	main.get_node("%DreamState").role_cards._copy_effect(copied, &"night_terror", &"night_terror", jar)
	_check(not copied.statuses.has(EnemyStatuses.STATIC) and not copied.statuses.has(EnemyStatuses.DROWSY) and _lost(copied) > 0,
		"Heavy Heart's Night Terror copy: its bolt strikes (%d lost of a %.1f bolt), Charged and Drowsy spent" % [_lost(copied), copy_bolt])
	await _clean()

	# --- Wide Awake (Crowned Night Terror on a Rooted nightmare, owner 2026-10-17): the scream wakes the Wardens within
	# 3 cells: they attack 40% faster for 3 s ---
	var near_warden := _plant("stormcap", Vector2(14, 8))
	var far_warden := _plant("stormcap", Vector2(17, 8))
	var touching_warden := _plant("stormcap", Vector2(15, 9))
	var speed_before := near_warden.get_attacks_per_second()
	var awake := _spawn(origin)
	awake.apply_status(EnemyStatuses.HELD, 4, 5.0)
	awake.apply_status(EnemyStatuses.STATIC, Reactions.IGNITE_MIN_STATIC, 0.0, base, 0, "light", jar)
	var wakes: int = tracker.counts.get(&"wide_awake", 0)
	awake.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", spore)
	_check(tracker.counts.get(&"wide_awake", 0) == wakes + 1, "Night Terror on a Rooted nightmare is Wide Awake")
	_check(not awake.statuses.has(EnemyStatuses.STATIC) and not awake.statuses.has(EnemyStatuses.DROWSY), "…still Night Terror's bolt, and the Drowsy used up")
	_check(is_equal_approx(near_warden.reaction_haste, Reactions.WIDE_AWAKE_SPEED) and far_warden.reaction_haste == 0.0 and touching_warden.reaction_haste == 0.0,
		"a Warden within 3 cells is woken, one further isn't, nor one only touching a woken one")
	_check(near_warden.get_attacks_per_second() > speed_before * 1.35, "the woken Warden attacks 40%% faster (%.2f -> %.2f)" % [speed_before, near_warden.get_attacks_per_second()])
	await _wait(Reactions.WIDE_AWAKE_TIME + 0.3)
	_check(near_warden.reaction_haste == 0.0, "after 3 s it calms down")
	await _clean()

	# Alarm Bells (its Woven card): every Warden touching a woken one wakes too (one step).
	var bells := _rule_on("alarm_bells")
	var awake2 := _spawn(origin)
	awake2.apply_status(EnemyStatuses.HELD, 4, 5.0)
	awake2.apply_status(EnemyStatuses.STATIC, Reactions.IGNITE_MIN_STATIC, 0.0, base, 0, "light", jar)
	awake2.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", spore)
	_check(touching_warden.reaction_haste > 0.0 and far_warden.reaction_haste == 0.0,
		"Alarm Bells: a Warden touching a woken one wakes too, one only touching that one doesn't")
	_rule_off(bells)
	for tower in [near_warden, far_warden, touching_warden]:
		tower.queue_free()
	await _clean()

	# --- Brimming (council rx review 2026-10-17): Night Terror's fear stays 2 Rooted, Wide Awake's haste stays 40% ---
	var dreams_node: DreamState = main.get_node("%DreamState")
	var brim_card: UpgradeData = load("res://resource/dream/brimming.tres")
	dreams_node.take(brim_card)
	await process_frame
	var brim_warden := _plant("stormcap", Vector2(14, 8))
	var screamer := _spawn(origin)
	var neighbour := _spawn(origin + Vector2(1.5, 0) * CELL)
	screamer.apply_status(EnemyStatuses.HELD, 8, 5.0)
	screamer.apply_status(EnemyStatuses.STATIC, Reactions.IGNITE_MIN_STATIC * 2, 0.0, base, 0, "light", jar)
	wakes = tracker.counts.get(&"wide_awake", 0)
	screamer.apply_status(EnemyStatuses.DROWSY, 80, 0.0, 0.0, 0, "song", spore)
	_check(tracker.counts.get(&"wide_awake", 0) == wakes + 1, "Brimming: a doubled Wide Awake fires")
	_check(neighbour.statuses.stacks(EnemyStatuses.HELD) == Reactions.NIGHT_TERROR_ROOT_STACKS,
		"Brimming: the fear still gives 2 Rooted, not x2.2 (%d)" % neighbour.statuses.stacks(EnemyStatuses.HELD))
	_check(is_equal_approx(brim_warden.reaction_haste, Reactions.WIDE_AWAKE_SPEED), "Brimming: the haste stays 40%% (%.2f)" % brim_warden.reaction_haste)
	dreams_node.stacks.erase(brim_card.id)
	brim_warden.queue_free()
	await _clean()

	# --- Sleepwalk moves a walking nightmare back toward the start, then it carries on ---
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	var walker = spawner.get_child(spawner.get_child_count() - 1)
	walker.max_health = 1000000
	walker.health = 1000000
	await _wait(4.0)
	var at_index: int = walker.get_route_index()
	walker.apply_status(EnemyStatuses.SPORED, Reactions.IGNITE_MIN_SPORES, 5.0, 2.0, 0, "spore", spore)
	walker.apply_status(EnemyStatuses.DROWSY, 40, 0.0, 0.0, 0, "song", spore)
	_check(walker.is_sleepwalking(), "the walker sleepwalks")
	await _wait(1.5)
	var back_index: int = walker.get_route_index()
	_check(back_index < at_index, "it walked back up the route (index %d -> %d)" % [at_index, back_index])
	await _wait(2.0)
	_check(not walker.is_sleepwalking() and walker.get_route_index() > back_index, "then it turns again and carries on (index %d)" % walker.get_route_index())
	await _clean()

	print("new reactions test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
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
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = cell
	tower.position = cell * CELL + Vector2(CELL, CELL) / 2
	container.add_child(tower)
	tower.set_process(false)
	return tower

# A sturdy, still nightmare.
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
	for node in main.get_children():
		if node is Reactions.WardenWake or node is Reactions.Sleepwalker:
			node.queue_free()
	await process_frame

# Stands a still nightmare on its own route at point `index` (as if it had walked there).
func _on_route(enemy: Node2D, index: int) -> void:
	enemy.global_position = Tower.MAP_GRID.calculate_map_position(enemy._path[index])
	enemy._path_index = index + 1

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
