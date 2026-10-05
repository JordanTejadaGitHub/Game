extends SceneTree

# Headless test for the Legendary rules Tower Code reads (dream_design.md "New Legendaries", "The
# Eldest"): Hunter's Moon, Eternal Charge, Rooted Nightmares, the reworked Nightshade, the Eldest's
# rank cap and confirm, Court of the Eldest's shared ranks, and rank names past VII. Run from the
# project folder:
#   godot --headless --path . --script res://tests/test_legendary_hits.gd --fixed-fps 60

const CELL := 64.0

var failures := 0
var main: Node
var spawner
var placer: TowerPlacer
var container: Node
var dreams: DreamState

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	spawner = main.get_node("%EnemyContainer")
	placer = main.get_node("%TowerPlacer")
	container = main.get_node("%TowerContainer")
	dreams = main.get_node("%DreamState")
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

	_check(Tower.rank_name(5) == "V" and Tower.rank_name(8) == "VIII" and Tower.rank_name(14) == "XIV"
		and Tower.rank_name(99) == "XCIX", "rank names past VII are worked out")

	var sprout := _plant("sprout", Vector2(2, 2))

	# --- Hunter's Moon: a Warden's first hit Exposes, and it never runs out ---
	_take("hunters_moon")
	var a := _spawn(sprout.global_position + Vector2(CELL, 0))
	sprout.hit(a, 1.0, false, Tower.NO_CRIT)
	_check(a.statuses.has(EnemyStatuses.MARKED), "Hunter's Moon: the first hit Exposes it")
	a.statuses.tick(30.0)
	_check(a.statuses.has(EnemyStatuses.MARKED), "and it never runs out")
	await _clean()

	# --- Eternal Charge: every 4th hit adds a Charge; Charges never decay ---
	_take("eternal_static")
	var b := _spawn(sprout.global_position + Vector2(CELL, 0))
	sprout._hits_landed = 0
	for i in 4:
		sprout.hit(b, 0.0, false, Tower.NO_CRIT)
	_check(b.statuses.stacks(EnemyStatuses.STATIC) == 1, "Eternal Charge: the 4th hit adds a Charge (%d)" % b.statuses.stacks(EnemyStatuses.STATIC))
	b.statuses.tick(30.0)
	_check(b.statuses.stacks(EnemyStatuses.STATIC) == 1, "and it never decays")
	await _clean()

	# --- Rooted Nightmares: every 8th hit Roots for 1 s ---
	_take("rooted_nightmares")
	var c := _spawn(sprout.global_position + Vector2(CELL, 0))
	sprout._hits_landed = 0
	for i in 7:
		sprout.hit(c, 0.0, false, Tower.NO_CRIT)
	_check(not c.statuses.is_held(), "not before the 8th hit")
	sprout.hit(c, 0.0, false, Tower.NO_CRIT)
	_check(c.statuses.is_held(), "Rooted Nightmares: the 8th hit Roots it")
	await _clean()

	# --- Nightshade (dream_design.md e1e39b56): effect damage ×2 on a nightmare with 4+ statuses (hits get nothing) ---
	_take("nightshade")
	var d := _spawn(sprout.global_position + Vector2(CELL, 0))
	d.apply_status(EnemyStatuses.SPORED, 2, 5.0, 1.0, 0, "spore", sprout)
	d.apply_status(EnemyStatuses.DAMP)
	d.apply_status(EnemyStatuses.STATIC, 1, 0.0, 1.0, 0, "light", sprout)
	_check(Reactions.nightshade_bonus(d) == 0.0, "Nightshade: nothing under 4 statuses (%d)" % d.statuses.active_ids().size())
	d.apply_status(EnemyStatuses.DROWSY, 1, 5.0, 1.0, 0, "song", sprout)  # A 4th status that changes no damage
	var count: int = d.statuses.active_ids().size()
	_check(count >= 4 and is_equal_approx(Reactions.nightshade_bonus(d), 1.0), "Nightshade: ×2 at 4+ statuses (%d statuses)" % count)
	var before: int = d.health
	d.take_damage(100.0, "", true, false, sprout, &"static")
	var expected := int(100.0 * sprout.get_potency() * Reactions.NIGHTSHADE_MULTIPLIER)
	_check(absi((before - d.health) - expected) <= 1, "a Charged bolt gets it (%d, expected %d)" % [before - d.health, expected])
	before = d.health
	d.take_damage(100.0, "", false, false, sprout, &"")
	_check(before - d.health == 100, "a hit gets nothing (%d)" % (before - d.health))
	await _clean()

	# --- Generic Rares: First Light (×3 first hit, via on_hit_multiplier) and Root Network's glow ---
	_take("first_light")
	var fresh := _spawn(sprout.global_position + Vector2(CELL, 0))
	var before_first: int = fresh.health
	sprout.hit(fresh, 1.0, false, Tower.NO_CRIT)
	var first_hit: int = before_first - fresh.health
	var before_second: int = fresh.health
	sprout.hit(fresh, 1.0, false, Tower.NO_CRIT)
	var second_hit: int = before_second - fresh.health
	_check(first_hit > second_hit * 2, "First Light: the first hit on a nightmare lands much harder (%d vs %d)" % [first_hit, second_hit])
	await _clean()
	_take("root_network")
	var root_a := _plant("sprout", Vector2(10, 14))
	var root_b := _plant("sprout", Vector2(11, 14))
	var root_c := _plant("sprout", Vector2(12, 15))  # Only diagonal to root_b
	for t in [root_a, root_b, root_c]:
		t._refresh_neighbours()
	_check(root_a._root_links == [Vector2(1, 0)] and root_b._root_links.has(Vector2(-1, 0)),
		"Root Network: Sprouts side by side glow along their shared edge")
	# A vertical pair: drawn once, by the board's overlay, between the slab fronts (a user bug: each
	# Sprout drew half a link under its own sprite, so vertical links were hidden).
	var root_top := _plant("sprout", Vector2(3, 12))
	var root_under := _plant("sprout", Vector2(3, 13))
	for t in [root_top, root_under]:
		t._refresh_neighbours()
	var overlay := RootNetworkOverlay.find(container)
	var vertical := overlay.get_segments().filter(func(s) -> bool:
		return s[0] == root_top.global_position + RootNetworkOverlay.SLAB_FRONT \
			and s[1] == root_under.global_position + RootNetworkOverlay.SLAB_FRONT)
	_check(vertical.size() == 1, "a vertical pair has one link in the overlay, slab front to slab front")
	_check(overlay.z_index == 1 and overlay.get_index() == 0, "the overlay draws over the Wardens' bodies, under their pips")
	var pairs := overlay.get_segments().size()
	_check(pairs == 2, "each link is drawn once (%d links for the two pairs)" % pairs)
	root_top.queue_free()
	root_under.queue_free()
	_check(root_c._root_links.is_empty(), "a diagonal one doesn't (only with Root Network II)")

	# --- Generic cards 142-168: Watchful Rest, Skyward Gaze (now in Hunter's Patience), Heavy Air ---
	_take("watchful_rest")
	var watcher := _plant("sprout", Vector2(4, 12))
	watcher._update_watch(DreamState.WATCHFUL_REST_TIME[0] + 0.5)
	watcher._update_watch(0.5)
	_check(watcher.watch_charged, "Watchful Rest: an idle Warden stores a charge")
	_check(watcher._take_empowered() == 2.0 and not watcher.watch_charged, "its next attack deals ×2 and spends it")
	_take("hunters_patience")  # Absorbed Skyward Gaze (pool trim): rule alias
	var edge := sprout.get_range_pixels() + CELL * 0.5
	spawner.spawn_enemy(load("res://resource/enemy/dandelion_seed.tres"))
	var flyer = spawner.get_child(spawner.get_child_count() - 1)
	flyer.set_process(false)
	flyer.global_position = sprout.global_position + Vector2(edge, 0)
	var walker := _spawn(sprout.global_position + Vector2(0, edge))
	var seen := sprout.get_enemies_in_range()
	_check(seen.has(flyer) and not seen.has(walker), "Skyward Gaze: +1 range against flyers only")
	await _clean()
	_take("heavy_air")
	_check(is_equal_approx(sprout.get_slow_multiplier(), 1.0 + DreamState.HEAVY_AIR_BONUS), "Heavy Air: cloud and rubble slows ×1.2")
	_check(Reactions.is_effect(&"last_breath"), "Last Breath counts as an effect")

	# --- The Eldest and its Court ---
	_take("endless_rings")
	var elder := _plant("sprout", Vector2(6, 6))
	var friend := _plant("sprout", Vector2(7, 6))
	for t in [elder, friend]:
		t.rank = 5
		t.focus = Tower.Focus.POWER  # Ranks III+ come with a Focus
	var run_state: RunState = main.get_node("%RunState")
	run_state.dew = 100000
	_check(dreams.needs_eldest_confirm(elder), "rank VI would make it the Eldest")
	_check(not placer.nurture(elder), "the placer won't buy VI without the confirm")
	_check(dreams.make_eldest(elder) and placer.nurture(elder) and elder.rank == 6, "confirmed: it grows to VI")
	_check(friend.get_max_rank() == 5 and not friend.can_nurture(), "everyone else stops at V")
	# Endless Rings carries Court of the Eldest (pool trim)
	var alone := _plant("sprout", Vector2(12, 12))
	alone.rank = 5
	alone.focus = Tower.Focus.POWER
	_check(friend.get_court_ranks() > 0.0 and alone.get_court_ranks() == 0.0, "Court: only Wardens touching the Eldest share its ranks")
	_check(friend.get_damage() > alone.get_damage(), "and hit harder for it")

	print("legendary hits test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _take(card_id: String) -> void:
	for card in dreams.pool:
		if card.id == card_id:
			dreams.take(card)
			return
	for file in DirAccess.get_files_at("res://resource/dream"):
		var card = load("res://resource/dream/" + file.trim_suffix(".remap"))
		if card is UpgradeData and card.id == card_id:
			dreams.take(card)
			return
	_check(false, "card %s exists" % card_id)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

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
	enemy.coat = 0.0
	return enemy

func _clean() -> void:
	for child in spawner.get_children():
		child.queue_free()
	await process_frame
