extends SceneTree
# The Dewdrop class: Puddles, water and free hits (documentation/dream_council_review.md 20 to 21). Written 2026-10-13 and NOT RUN: the owner has paused
# tests. The numbers come from the class script's constants, so retuning does not break it.
var failures := 0
var main: Node
var spawner
var placer: TowerPlacer
var container: Node
var dreams: DreamState
var klass  # The class node (DreamState.puddles)
const CELL := 64.0
const LENT := ["steeped", "topped_up", "ebb", "heavy_going", "high_tide",
	"never_quite_dry", "sodden", "wash_away", "last_drop"]  # Card pass 2026-10-16: Dripping and Pooling folded into Steeped; The Tide Remembers retired (hard cards 2026-10-16). Dewdrop helping itself (owner 2026-10-18): Sodden, Wash Away (revived), Last Drop. Old Rain retired (dream_council_review.md 33)

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _plant(id: String, at: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = (at / CELL).floor()
	tower.position = at
	container.add_child(tower)
	tower.set_process(false)
	dreams.bump_board()
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

func _take(id: String) -> void:
	dreams.take(load("res://resource/dream/%s.tres" % id))

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _clean() -> void:
	for child in spawner.get_children():
		child.queue_free()
	for child in container.get_children():
		child.queue_free()
	await process_frame
	dreams.bump_board()

# The class's cards: 12 with its Calling, offered only on that start; its lent cards for any owner of the family.
func _check_pool(family: String, lent: Array, class_count: int = 12) -> void:
	var class_cards: Array = dreams.pool.filter(func(c: UpgradeData) -> bool: return c.calling == family and not c.retired)
	_check(class_cards.size() == class_count, "%s has %d class cards (%d)" % [family, class_count, class_cards.size()])
	for card in class_cards:
		_check(card.rule_id != &"" and card.description != "" and card.tip.contains("Works for:"), "%s says who it works for" % card.id)
		_check(dreams.in_run_pool(card) == (dreams.calling == family), "%s is in the pool only on a %s start" % [card.id, family])
	for id in lent:
		var card: UpgradeData = load("res://resource/dream/%s.tres" % id)
		_check(card.tags.has(DreamState.LENT_TAG) and card.calling == "" and card.requires.has(family) and not card.retired, "%s is a lent %s card" % [id, family])
		_check(klass._lent_rules().has(card.rule_id), "%s's rule (%s) is one the class script reads" % [id, card.rule_id])
		_check(dreams.in_run_pool(card), "%s is in the pool whatever the first pick" % id)

func _setup() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	spawner = main.get_node("%EnemyContainer")
	placer = main.get_node("%TowerPlacer")
	container = main.get_node("%TowerContainer")
	dreams = main.get_node("%DreamState")
	klass = dreams.puddles

# Last Drop on a fresh nightmare: the health a run-out of `status` (its peak `peak`, added by `source`) takes off it.
func _drop_lost(spot: Vector2, source, peak: int, status: StringName = EnemyStatuses.DAMP) -> int:
	var e = _spawn(spot + Vector2(CELL, CELL))
	var before: int = e.health
	klass._last_drop(status, peak, source, e)
	return before - e.health

# Dewdrop helping itself (owner 2026-10-18; dream_council\dewdrop_self.md): Sodden, Wash Away and Last Drop work for Dewdrop
# Wardens (a Dewdrop alone) and Wardens near them (2 cells), never for a Warden far from every Dewdrop.
func _self_help_checks(spot: Vector2) -> void:
	dreams.calling = "sporeling"  # A later owner: lent cards need no water
	dreams.calling_path.clear()
	dreams.stacks.clear()
	_take("sodden")
	var drop := _plant("dewdrop", spot)
	var near_spore := _plant("sporeling", spot + Vector2(CELL, 0))
	var far_spore := _plant("sporeling", spot + Vector2(CELL * 8, 0))
	await _frames(2)
	klass.on_board()
	var n = _spawn(spot + Vector2(0, CELL))
	_check(is_equal_approx(klass.damage_multiplier(n, drop), 1.0), "Sodden: no Soaked, no bonus")
	n.apply_status(EnemyStatuses.DAMP, 1, 20.0, 1.0, 0, "water", drop)
	_check(is_equal_approx(klass.damage_multiplier(n, drop), 1.0), "...Soaked just landed: +0%")
	n.statuses.tick(2.5)
	var two: float = 1.0 + klass.SODDEN_PER * 2.0
	_check(is_equal_approx(klass.damage_multiplier(n, drop), two), "Sodden: a Dewdrop alone deals +%d%% after 2 s of Soaked (%.3f)" % [roundi((two - 1.0) * 100.0), klass.damage_multiplier(n, drop)])
	_check(is_equal_approx(klass.damage_multiplier(n, near_spore), two), "...a Warden near a Dewdrop too")
	_check(is_equal_approx(klass.damage_multiplier(n, far_spore), 1.0), "...a Warden far from every Dewdrop: nothing")
	_check(is_equal_approx(klass.damage_multiplier(n, drop, &"spored"), 1.0), "...hits only, never status damage")
	n.statuses.tick(5.0)
	_check(is_equal_approx(klass.damage_multiplier(n, drop), 1.0 + klass.SODDEN_MAX), "...up to +%d%%" % roundi(klass.SODDEN_MAX * 100.0))
	dreams.batch_damage_multiplier(n, drop, &"")  # (The frame's hook check sees Sodden)
	_check(dreams._hook_water, "...DreamState hooks the Dewdrop hit bonuses for Sodden")
	# F6 (owner 2026-10-18): it counts from the first Soaked this walk; a gap of SODDEN_GAP s or less doesn't reset it
	klass._sodden_walk(n)  # (The poll sees it Soaked)
	n.statuses.remove(EnemyStatuses.DAMP)
	n.apply_status(EnemyStatuses.DAMP, 1, 20.0, 1.0, 0, "water", drop)
	_check(is_equal_approx(klass.damage_multiplier(n, drop), 1.0 + klass.SODDEN_MAX), "F6 Sodden: Soaked running out and coming back within %.0f s keeps the count" % klass.SODDEN_GAP)
	var walk: Array = n.get_meta(klass.SODDEN_WALK_META)
	walk[1] = float(walk[1]) - klass.SODDEN_GAP - 0.5
	n.set_meta(klass.SODDEN_WALK_META, walk)
	_check(is_equal_approx(klass.damage_multiplier(n, drop), 1.0), "...after a longer gap the count starts again")
	_check(load("res://resource/dream/sodden.tres").description.contains("since it was first given {damp}"), "...the new face")

	# Wash Away (revived): hits from a Dewdrop or a Warden near one on a Soaked nightmare wear its shell twice as fast.
	dreams.stacks.clear()
	_take("wash_away")
	var w = _spawn(spot + Vector2(0, -CELL))
	_check(is_equal_approx(klass.shell_multiplier(w, drop), 1.0), "Wash Away: before any Soaked, nothing")
	w.apply_status(EnemyStatuses.DAMP, 1, 20.0, 1.0, 0, "water", drop)
	_check(is_equal_approx(klass.shell_multiplier(w, drop), klass.WASH_AWAY_SHELL), "Wash Away: a Dewdrop alone wears the shell x%.0f" % klass.WASH_AWAY_SHELL)
	_check(is_equal_approx(klass.shell_multiplier(w, near_spore), klass.WASH_AWAY_SHELL), "...a Warden near a Dewdrop too")
	_check(is_equal_approx(klass.shell_multiplier(w, far_spore), 1.0), "...a Warden far from every Dewdrop: nothing")
	w.statuses.is_boss = true
	_check(is_equal_approx(klass.shell_multiplier(w, drop), 1.0), "...never bosses")
	w.statuses.is_boss = false
	_check(is_equal_approx(dreams.shell_multiplier(w, drop), klass.WASH_AWAY_SHELL), "...DreamState asks it")
	w.max_health = 1000
	w.health = 1000
	w.coat = 40.0
	w._coat_per_hit = 10.0
	w.take_damage(30.0, "spore", false, false, near_spore, &"")
	_check(is_equal_approx(w.coat, 20.0), "...a 10-shell hit takes 20 off the shell (%.1f left)" % w.coat)

	# Last Drop: Soaked running out, the Warden that added it (a Dewdrop or a Warden near one) hits for 40% of its hit for
	# each stack it had, up to 3 hits; each nightmare once every 6 s; never for another status.
	dreams.stacks.clear()
	_take("last_drop")
	var one: int = _drop_lost(spot, drop, 1)
	var full: int = _drop_lost(spot, drop, 8)
	_check(one > 0, "Last Drop: a Dewdrop alone: Soaked running out deals a drop (%d)" % one)
	_check(absf(float(full) - float(one) * klass.LAST_DROP_HITS / klass.LAST_DROP_SHARE) <= klass.LAST_DROP_HITS / klass.LAST_DROP_SHARE + 1.0,
		"...40%% for each stack, up to 3 hits (1 stack %d, 8 stacks %d)" % [one, full])
	_check(_drop_lost(spot, near_spore, 4) > 0, "...a Warden near a Dewdrop that added Soaked too")
	_check(_drop_lost(spot, far_spore, 4) == 0, "...a Warden far from every Dewdrop: nothing")
	_check(_drop_lost(spot, drop, 4, EnemyStatuses.SPORED) == 0, "...only Soaked")
	var twice = _spawn(spot + Vector2(-CELL, CELL))
	var t0: int = twice.health
	klass._last_drop(EnemyStatuses.DAMP, 4, drop, twice)
	var t1: int = twice.health
	klass._last_drop(EnemyStatuses.DAMP, 4, drop, twice)
	_check(t1 < t0 and twice.health == t1, "...each nightmare once every %.0f s" % klass.LAST_DROP_EVERY)
	# The real run-out (status_ran_out, hooked on the poll): time running out drops; a Reaction spending it never does
	var real = _spawn(spot + Vector2(-CELL, -CELL))
	real.apply_status(EnemyStatuses.DAMP, 1, 0.5, 1.0, 0, "water", drop)
	klass.on_poll()
	var r0: int = real.health
	for i in 20:
		real.statuses.tick(0.5)
	_check(not real.statuses.has(EnemyStatuses.DAMP) and real.health < r0, "...Soaked running out of time drops on it")
	var spent = _spawn(spot + Vector2(0, CELL * 2))
	spent.apply_status(EnemyStatuses.DAMP, 1, 0.5, 1.0, 0, "water", drop)
	klass.on_poll()
	var s0: int = spent.health
	spent.statuses.remove(EnemyStatuses.DAMP)
	_check(spent.health == s0, "...spent Soaked never drops")
	_check(klass.CLASS_TAGS.has(klass.LAST_DROP_TAG), "...never setting a card off again")
	await _clean()
	dreams.stacks.clear()

# The rebuilt Puddles evolutions (owner 2026-10-23, dream_council_review.md 33; evo_fixed_dewdrop.md). One "old effect
# gone" check for each kept id whose meaning changed (Stream, Black Pond, Riverside, Wet Footprints; evo_shared_spec.md 2),
# and the new rows where a headless check is practical. Written 2026-10-23 and NOT RUN.
func _path(ids: Array) -> void:
	dreams.calling_path.clear()
	for id in ids:
		dreams.calling_path.append(StringName(id))
	dreams._rebuild_calling_flags()

func _has_const(name: String) -> bool:
	return klass.get_script().get_script_constant_map().has(name)

# The one Calling slow this node asked for on `enemy` (0 = none): a poll's requests, applied as class_kit does.
func _calling_slow_on(enemy) -> float:
	enemy.statuses.timed_slows.clear()
	klass._evolutions_poll()
	klass._apply_calling_slows()
	return enemy.statuses.timed_slow()

func _evolution_checks(at: Vector2, route: Array) -> void:
	dreams.stacks.clear()
	dreams.calling = "dewdrop"
	# --- Riverside (kept id, new meaning): other families' statuses in water last SIDE_SECONDS longer; Dewdrops add no time;
	# the old Sprout +25% is gone
	_path([&"dw_riverside"])
	var drop := _plant("dewdrop", at + Vector2(CELL, 0))
	var spore := _plant("sporeling", at + Vector2(-CELL, 0))
	var sprout := _plant("sprout", at + Vector2(0, CELL))
	await _frames(2)
	klass.on_board()
	var r = _spawn(at)
	var dry = _spawn(route[mini(60, route.size() - 1)])
	_check(klass.water_of(r) >= 0 and klass.water_of(dry) < 0, "(one nightmare in the water, one out of it)")
	_check(klass.touches_water(spore, klass.water_of(r)), "(the Sporeling touches the water)")
	spore._apply_one_status(r, EnemyStatuses.SPORED, 1, spore.get_damage())
	spore._apply_one_status(dry, EnemyStatuses.SPORED, 1, spore.get_damage())
	var gained: float = r.statuses.time_left(EnemyStatuses.SPORED) - dry.statuses.time_left(EnemyStatuses.SPORED)
	_check(absf(gained - klass.SIDE_SECONDS) < 0.01, "Riverside: another family's status added in the water lasts %.0f s longer (%.2f)" % [klass.SIDE_SECONDS, gained])
	_check(r.statuses.stacks(EnemyStatuses.SPORED) == dry.statuses.stacks(EnemyStatuses.SPORED), "...and adds no stack")
	var soak_dry = _spawn(dry.global_position)
	drop._apply_one_status(soak_dry, EnemyStatuses.DAMP, 1, drop.get_damage())
	var soak_wet = _spawn(at)
	drop._apply_one_status(soak_wet, EnemyStatuses.DAMP, 1, drop.get_damage())
	_check(absf(soak_wet.statuses.time_left(EnemyStatuses.DAMP) - soak_dry.statuses.time_left(EnemyStatuses.DAMP) - klass.SIDE_DAMP_SECONDS) < 0.01,
		"Riverside (final pass 2026-10-24): a Dewdrop's own Soaked in water lasts %.0f s longer" % klass.SIDE_DAMP_SECONDS)
	r.apply_status(EnemyStatuses.DROWSY, 1, 0.0, 1.0, 0, "song", null)
	var drowsy_left: float = r.statuses.time_left(EnemyStatuses.DROWSY)
	klass._evo_status(spore, r, EnemyStatuses.DROWSY)
	_check(is_equal_approx(r.statuses.time_left(EnemyStatuses.DROWSY), drowsy_left), "...never Drowsy")
	r.apply_status(EnemyStatuses.DAMP, 1, 10.0, 1.0, 0, "water", drop)
	_check(klass.touches_water(sprout, klass.water_of(r)), "(the Sprout touches the water)")
	_check(is_equal_approx(klass.damage_multiplier(r, sprout), 1.0), "Riverside, old effect gone: no +25% for Sprouts on a Soaked nightmare")
	# The Sprout part is gone (final pass 2026-10-24, S1): Sprouts count toward no Dewdrop Warden count
	_check(not _has_const("SIDE_SPROUT_SECONDS") and not klass.has_method("_sprout_side"), "Riverside, old effect gone: no Sprout part")
	_check(DreamState.CALLING_PATHS.keeps_out(&"dw_riverside").has(&"steeped") and dreams._calling_keeps_out.has("steeped"), "Riverside keeps Steeped out of the offers")
	# Open Water: a Warden far from the water counts too
	var far_spore := _plant("sporeling", at + Vector2(CELL * 6, CELL * 6))
	await _frames(1)
	klass.on_board()
	var o = _spawn(at)
	var o_dry = _spawn(dry.global_position)
	far_spore._apply_one_status(o, EnemyStatuses.SPORED, 1, far_spore.get_damage())
	far_spore._apply_one_status(o_dry, EnemyStatuses.SPORED, 1, far_spore.get_damage())
	_check(is_equal_approx(o.statuses.time_left(EnemyStatuses.SPORED), o_dry.statuses.time_left(EnemyStatuses.SPORED)), "Riverside alone: a Warden off the bank adds no time")
	_path([&"dw_riverside", &"dw_open_water"])
	var o2 = _spawn(at)
	far_spore._apply_one_status(o2, EnemyStatuses.SPORED, 1, far_spore.get_damage())
	_check(absf(o2.statuses.time_left(EnemyStatuses.SPORED) - o_dry.statuses.time_left(EnemyStatuses.SPORED) - klass.SIDE_SECONDS) < 0.05,
		"Open Water: a status from a Warden anywhere lasts %.0f s longer in the water" % klass.SIDE_SECONDS)
	await _clean()

	# --- Stream (kept id, new meaning): 15% slower in water (the one capped Calling slow); the old +30% next hit is gone
	_path([&"dw_stream"])
	var s_drop := _plant("dewdrop", at + Vector2(CELL, 0))
	await _frames(2)
	klass.on_board()
	var sa = _spawn(at)
	var sb = _spawn(at)
	var sc = _spawn(at)
	s_drop.hit(sa, 1.0, false, Tower.NO_CRIT)
	await _frames(2)
	_check(is_equal_approx(klass.damage_multiplier(sb, s_drop), 1.0), "Stream, old effect gone: a splash reaching 3 nightmares readies no +30% hit")
	_check(not _has_const("STREAM_META") and not _has_const("STREAM_BONUS"), "...its old constants are gone")
	_check(is_equal_approx(_calling_slow_on(sc), klass.STREAM_SLOW), "Stream: a nightmare in water walks %d%% slower (%.2f)" % [roundi(klass.STREAM_SLOW * 100.0), sc.statuses.timed_slow()])
	var s_dry = _spawn(route[mini(60, route.size() - 1)])
	_check(klass.water_of(s_dry) < 0 and is_zero_approx(_calling_slow_on(s_dry)), "...out of the water no slow")
	sc.statuses.is_boss = true
	var boss_slow := _calling_slow_on(sc)
	_check(boss_slow > 0.0 and boss_slow <= klass.CALLING_SLOW_MAX * 0.5 + 0.001, "...bosses half (%.3f)" % boss_slow)
	sc.statuses.is_boss = false
	# Heavy Going counts only slows not from the Calling
	sc.statuses.timed_slows.clear()
	klass._evolutions_poll()
	klass._apply_calling_slows()
	_check(not klass.walking_slowed(sc), "Heavy Going: the Calling slow alone doesn't count")
	sc.statuses.add_slow(0.2, 2.0)
	_check(klass.walking_slowed(sc), "...another slow does")
	# Flash Flood (one Calling slow, never a second): the splash reaches far nightmares in the water, 30% for 2 s
	_path([&"dw_stream", &"dw_reed_bed", &"dw_flash_flood"])
	klass.on_board()
	var ff = _spawn(at)
	klass._set_timed_slow(ff, klass.CAPSTONE_SLOW, klass.FLASH_SECONDS, klass.EVO_FLASH)
	_check(is_equal_approx(_calling_slow_on(ff), klass.CAPSTONE_SLOW), "Flash Flood: its slow replaces Stream's, never adds (%.2f)" % ff.statuses.timed_slow())
	_check(ff.statuses.timed_slows.size() == 1, "...one Calling slow entry per nightmare")
	# Final pass 2026-10-24: Mudflats' own STEADY_SLOW; Floodgate's surge (a timed slow, each water once in SURGE_COOLDOWN)
	_path([&"dw_stream", &"dw_backwaters", &"dw_mudflats"])
	klass.on_board()
	var mf = _spawn(at)
	_check(is_equal_approx(_calling_slow_on(mf), klass.STEADY_SLOW), "Mudflats: %d%% in water (%.2f)" % [roundi(klass.STEADY_SLOW * 100.0), mf.statuses.timed_slow()])
	_path([&"dw_stream", &"dw_floodgate"])
	klass.on_board()
	var fg_dead = _spawn(at)
	var fg = _spawn(at)
	klass._floodgate(fg_dead)
	var surge: Array = fg.get_meta(klass.TIMED_META, [])
	_check(surge.size() >= 3 and is_equal_approx(float(surge[1]), klass.SURGE_SLOW) and StringName(surge[2]) == klass.EVO_FLOODGATE,
		"Floodgate: a dispel in water slows every nightmare in it %d%%" % roundi(klass.SURGE_SLOW * 100.0))
	fg.remove_meta(klass.TIMED_META)
	klass._floodgate(fg_dead)
	_check(not fg.has_meta(klass.TIMED_META), "...each water once every %.0f s" % klass.SURGE_COOLDOWN)
	await _clean()

	# --- Black Pond (kept id, new meaning): the highest-rank Dewdrop's water is the pond; its hits spill 25% onto up to 4
	# others there. The old pond slow and +25% Dewdrop hits are gone.
	_path([&"dw_black_pond"])
	var pond_drop := _plant("dewdrop", at + Vector2(CELL, 0))
	await _frames(2)
	klass.on_board()
	var p = _spawn(at)
	var q = _spawn(at)
	_check(klass._is_pond(klass.water_of(p)) and klass._pond_dewdrops == [pond_drop], "Black Pond: one Dewdrop's water is the pond (no second Dewdrop needed)")
	_check(is_equal_approx(klass.damage_multiplier(p, pond_drop), 1.0), "Black Pond, old effect gone: no +25% on Dewdrop hits")
	_check(is_zero_approx(_calling_slow_on(p)), "Black Pond, old effect gone: no pond slow")
	_check(not _has_const("POND_BONUS") and not _has_const("POND_SLOW"), "...its old constants are gone")
	var q_before: int = q.health
	pond_drop.hit(p, 1.0, false, Tower.NO_CRIT)
	await _frames(2)
	_check(q.health < q_before, "Black Pond: the hit spills onto another nightmare in the pond (%d)" % (q_before - q.health))
	_check(not q.statuses.has(EnemyStatuses.MARKED) and not q.statuses.has(EnemyStatuses.SPORED), "...damage only")
	_check(klass.CLASS_TAGS.has(&"pond_spill") and DreamState.REPEAT_TAGS.has(&"pond_spill"), "...a class tag that skips the batch cards")
	_check(is_equal_approx(klass._spill_amount(pond_drop, 100.0), 100.0 * klass.SPILL_SHARE), "...25%% of the hit (%.1f)" % klass._spill_amount(pond_drop, 100.0))
	_path([&"dw_black_pond", &"dw_deep_end"])
	pond_drop.rank = 5
	_check(is_equal_approx(klass._spill_amount(pond_drop, 100.0), 100.0 * (klass.SPILL_SHARE + klass.DEEP_END_PER_RANK * 5)), "Deep End: +3% a rank")
	pond_drop.rank = 0
	_check(not _has_const("KING_BOSS_COUNT"), "King Tide, old effect gone: no boss count or shell pass")
	# Final pass 2026-10-24, Focus line B: Undertow (+10% per missing spill target) and Fathoms (+10% a second waded) add
	_path([&"dw_black_pond", &"dw_undertow", &"dw_fathoms"])
	klass.on_board()
	q.queue_free()
	await _frames(1)
	p.set_meta(klass.POND_SINCE_META, klass.now() - 3.0)
	var deep: float = klass.hit_multiplier(pond_drop, p, false, false, &"")
	_check(absf(deep - (1.0 + klass.UNDERTOW_PER * klass.SPILL_MAX + klass.FATHOM_PER * 3.0)) < 0.02,
		"Undertow + Fathoms: alone in the pond after 3 s (%.2f)" % deep)
	await _clean()

	# --- Wet Footprints (kept id, new meaning): footprints are never water; for 2 s after leaving water other families'
	# statuses don't run down (Poisoned within the shared room)
	_path([&"dw_riverside", &"dw_wet_footprints"])
	_check(not ("_wet" in klass) and not ("_wet_touch" in klass), "Wet Footprints, old effect gone: no wet steps that count as water")
	var w_spore := _plant("sporeling", at + Vector2(CELL * 6, CELL * 6))
	await _frames(1)
	var wf = _spawn(route[mini(60, route.size() - 1)])
	w_spore._apply_one_status(wf, EnemyStatuses.SPORED, 1, w_spore.get_damage())
	wf.set_meta(klass.WET_FOOT_META, klass.now() + klass.WET_FOOT_SECONDS)
	klass._wet_footprints(wf)
	var wf_left: float = wf.statuses.time_left(EnemyStatuses.SPORED)
	wf.statuses.tick(0.5)
	klass._wet_footprints(wf)
	_check(absf(wf.statuses.time_left(EnemyStatuses.SPORED) - wf_left) < 0.01, "Wet Footprints: just out of the water, Poisoned doesn't run down")
	_check(wf.statuses.is_kept(EnemyStatuses.SPORED), "...and is kept (Low Tide counts it)")
	# Low Tide: other families' direct hits +10% for each kept status; never a Dewdrop's; via DreamState's Calling branch
	_path([&"dw_riverside", &"dw_wet_footprints", &"dw_low_tide"])
	_check(DreamState.calling_mult_on and DreamState.calling_tide_on, "Low Tide switches the Calling hit branch on")
	_check(is_equal_approx(klass.hit_multiplier(w_spore, wf, false, false, &""), 1.0 + klass.LOW_TIDE_PER), "Low Tide: +10% for 1 kept status")
	_check(is_equal_approx(dreams._calling_hit_multiplier(w_spore, wf, false, false, &""), 1.0 + klass.LOW_TIDE_PER), "...through DreamState._calling_hit_multiplier")
	var wf_drop := _plant("dewdrop", at + Vector2(CELL * 7, CELL * 6))
	await _frames(1)
	_check(is_equal_approx(klass.hit_multiplier(wf_drop, wf, false, false, &""), 1.0), "...never a Dewdrop's hit")
	_check(is_equal_approx(klass.hit_multiplier(w_spore, wf, false, false, &"shatter"), 1.0), "...direct hits only")
	var plain = _spawn(at + Vector2(CELL * 9, CELL * 9))
	w_spore._apply_one_status(plain, EnemyStatuses.SPORED, 1, w_spore.get_damage())
	_check(is_equal_approx(klass.hit_multiplier(w_spore, plain, false, false, &""), 1.0), "...a status nothing keeps counts for nothing")
	# Final pass 2026-10-24, River Mouth: the first other-family direct hit within 6 steps of leaving water, +20% per
	# lingering status (Soaked left out, owner pick), once per nightmare per water; Sprouts neither take nor spend it
	_path([&"dw_riverside", &"dw_river_mouth"])
	_check(DreamState.calling_tide_on, "River Mouth switches the Calling hit branch on")
	var rm = _spawn(route[mini(60, route.size() - 1)])
	w_spore._apply_one_status(rm, EnemyStatuses.SPORED, 1, w_spore.get_damage())
	rm.statuses.linger(EnemyStatuses.SPORED, 1.0)
	rm.apply_status(EnemyStatuses.DAMP, 1, 0.0, 1.0, 0, "water", null)
	rm.statuses.linger(EnemyStatuses.DAMP, 1.0)
	rm.set_meta(klass.MOUTH_WIN_META, [klass.index_of(rm), bool(rm.get("passed_waymark")), "test"])
	var rm_sprout := _plant("sprout", at + Vector2(CELL * 8, CELL * 6))
	await _frames(1)
	_check(is_equal_approx(klass.hit_multiplier(rm_sprout, rm, false, false, &""), 1.0), "River Mouth: a Sprout's hit takes nothing...")
	_check(is_equal_approx(klass.hit_multiplier(w_spore, rm, false, false, &""), 1.0 + klass.MOUTH_PER),
		"...and spends nothing: the first other-family hit gets +20% for 1 lingering status (Soaked doesn't count)")
	_check(is_equal_approx(klass.hit_multiplier(w_spore, rm, false, false, &""), 1.0), "...once per nightmare per water")
	_path([])
	_check(not DreamState.calling_tide_on, "(no Calling hit branch without the rows)")
	await _clean()

	# --- Stagnant Water (retired 2026-10-23, kept for an old save's path): a status in the pond does not run down
	_path([&"dw_black_pond", &"dw_stagnant_water"])
	_plant("dewdrop", at + Vector2(CELL, 0))
	await _frames(2)
	klass.on_board()
	var st = _spawn(at)
	_check(klass._is_pond(klass.water_of(st)), "(the nightmare stands in the pond)")
	st.apply_status(EnemyStatuses.MARKED, 2, 0.0, 1.0, 0, "light", null)
	klass._in_pond(st)
	var landed: float = st.statuses.time_left(EnemyStatuses.MARKED)
	st.statuses.tick(1.0)
	klass._in_pond(st)
	_check(absf(st.statuses.time_left(EnemyStatuses.MARKED) - landed) < 0.01, "Stagnant Water (old save): a status in the pond does not run down")
	_check(not DreamState.CALLING_PATHS.is_live(&"dw_stagnant_water") and DreamState.CALLING_PATHS.next_ids("dewdrop", dreams.calling_path, 2).is_empty(),
		"...it is retired: that path offers nothing more")
	_path([])
	await _clean()

# F1 lent × Calling, F2 and F5 (owner 2026-10-18; D:\Projects\logs\dream_council\f1_spec.md).
func _f1_checks(at: Vector2, route: Array, spot: Vector2) -> void:
	# F1: the Calling's ripple Soaks as that Dewdrop's application for another family's stack card (Pass It Round: +3,
	# held to at most 2 extra on a 1-stack application)
	dreams.stacks.clear()
	dreams.calling = "dewdrop"
	dreams.calling_path.clear()
	_take("pass_it_round")
	var drop := _plant("dewdrop", at + Vector2(CELL, 0))
	_plant("sporeling", at + Vector2(CELL, CELL))  # Touching the Dewdrop
	await _frames(2)
	klass.on_board()
	var a = _spawn(at)
	var b_at: Vector2 = route[12]
	var w: int = klass.water_of(a)
	if w >= 0:
		for i in klass.waters[w].points:
			if int(i) != klass.index_of(a) and absi(int(i) - klass.index_of(a)) <= klass.RIPPLE_STEPS * 2:
				b_at = route[int(i)]
				break
	var b = _spawn(b_at)
	drop.hit(a, 1.0, false, Tower.NO_CRIT)
	await _frames(2)
	_check(b.statuses.stacks(EnemyStatuses.DAMP) == 1 + mini(DreamState.SPORE_PRINT.PASS_STACKS, 2),
		"F1: the ripple's Soaked is the Dewdrop's application: Pass It Round adds, at most 2 extra on 1 stack (%d)" % b.statuses.stacks(EnemyStatuses.DAMP))
	_check(dreams._calling_apply == "" and DamageLog.calling_next == &"", "F1: nothing is left armed")
	var plain = _spawn(at + Vector2(CELL * 8, CELL * 8))
	drop._apply_one_status(plain, EnemyStatuses.DAMP, 1, drop.get_damage(), false)
	_check(plain.statuses.stacks(EnemyStatuses.DAMP) == 1, "F1: an unmarked carried application gets no extras")
	await _clean()

	# F1: another family's Calling hit counts for High Tide; its own family's never does (a Reflection on a Dewdrop start)
	dreams.stacks.clear()
	_take("high_tide")
	var ht_drop := _plant("dewdrop", spot)
	await _frames(2)
	var ht = _spawn(spot + Vector2(CELL, 0))
	ht.apply_status(EnemyStatuses.DAMP, 1, 10.0, 1.0, 0, "water", ht_drop)
	ht.apply_status(EnemyStatuses.SPORED, 1, 10.0, 1.0, 0, "spore", null)
	var tide: float = 1.0 + minf(klass.HIGH_TIDE_PER * ht.statuses.count(), klass.HIGH_TIDE_MAX)
	DamageLog.calling_now = &"bellflower"
	var other_family: float = klass.damage_multiplier(ht, ht_drop, &"toll")
	DamageLog.calling_now = &"dewdrop"
	var own_family: float = klass.damage_multiplier(ht, ht_drop, &"both_banks")
	DamageLog.calling_now = &""
	var tagged: float = klass.damage_multiplier(ht, ht_drop, &"toll")
	_check(is_equal_approx(other_family, tide), "F1: a Toll (Bellflower's Calling) gets High Tide like a hit (%.2f)" % other_family)
	_check(is_equal_approx(own_family, 1.0), "F1: never for its own family (the Dewdrop Calling's output)")
	_check(is_equal_approx(tagged, 1.0), "...an unmarked tagged strike gets nothing")
	await _clean()

	# F2: one linger total for every source (LINGER_MAX 6 s, Balancing 2026-10-23); the Calling's linger (Riverside,
	# Stagnant Water) keeps its own CALLING_LINGER_MAX inside it, and the lent cards fill the rest
	var lg = _spawn(spot + Vector2(CELL * 3, 0))
	lg.apply_status(EnemyStatuses.DAMP, 1, 0.0, 1.0, 0, "water", null)
	var left0: float = lg.statuses.time_left(EnemyStatuses.DAMP)
	_check(is_equal_approx(lg.statuses.linger_calling(EnemyStatuses.DAMP, 100.0), EnemyStatuses.CALLING_LINGER_MAX),
		"F2: the Calling's linger takes its own %.0f s" % EnemyStatuses.CALLING_LINGER_MAX)
	_check(is_equal_approx(lg.statuses.linger(EnemyStatuses.DAMP, 100.0), EnemyStatuses.LINGER_MAX - EnemyStatuses.CALLING_LINGER_MAX),
		"...the lent cards fill the rest of the %.0f s total" % EnemyStatuses.LINGER_MAX)
	_check(is_zero_approx(lg.statuses.linger(EnemyStatuses.DAMP, 1.0)) and is_zero_approx(lg.statuses.linger_calling(EnemyStatuses.DAMP, 1.0)), "...the total holds")
	_check(is_equal_approx(lg.statuses.time_left(EnemyStatuses.DAMP), left0 + EnemyStatuses.LINGER_MAX), "...at most %.0f s past landing" % EnemyStatuses.LINGER_MAX)
	lg.apply_status(EnemyStatuses.STATIC, 1, 2.0, 1.0, 0, "light", null)
	_check(is_equal_approx(lg.statuses.linger_calling(EnemyStatuses.STATIC, 100.0), EnemyStatuses.CALLING_LINGER_MAX_STATIC), "...Charged %.0f s" % EnemyStatuses.CALLING_LINGER_MAX_STATIC)
	_check(is_zero_approx(lg.statuses.linger_calling(EnemyStatuses.DROWSY, 5.0)), "...never Drowsy")
	await _clean()

	# F5: Rain on the Bank carries Drowsy, 1 short of full (never Drown, Night Terror, Sleepwalk or Pinned), with no extras
	dreams.stacks.clear()
	dreams.calling_path.clear()
	dreams.calling_path.append(&"dw_riverside")
	dreams.calling_path.append(&"dw_rain_on_the_bank")
	_take("breathe_it_in")
	var bell := _plant("bellflower", spot)
	_plant("sporeling", spot + Vector2(CELL, 0))
	await _frames(2)
	var dz = _spawn(spot + Vector2(0, CELL))
	var full: int = mini(dz.statuses.normal_cap(EnemyStatuses.DROWSY), dz.statuses.get_max_stacks(EnemyStatuses.DROWSY))
	_check(klass._carry(dz, EnemyStatuses.DROWSY, 1, bell, klass.EVO_RAIN) and dz.statuses.stacks(EnemyStatuses.DROWSY) == 1,
		"F5: a carry starting Drowsy adds its 1 stack, no stack-card extras (%d)" % dz.statuses.stacks(EnemyStatuses.DROWSY))
	klass._carry(dz, EnemyStatuses.DROWSY, full + 5, bell, klass.EVO_RAIN)
	_check(dz.statuses.stacks(EnemyStatuses.DROWSY) == full - 1, "F5: Drowsy stops 1 short of full (%d of %d)" % [dz.statuses.stacks(EnemyStatuses.DROWSY), full])
	_check(not klass._carry(dz, EnemyStatuses.DROWSY, 1, bell, klass.EVO_RAIN) and dz.statuses.stacks(EnemyStatuses.DROWSY) == full - 1, "...and never fills it")
	_check(not dz.statuses.is_asleep(), "...never asleep from it")
	_check(klass._bank_of(-1).is_empty(), "(no water here)")
	dreams.calling_path.clear()
	dreams.stacks.clear()
	await _clean()

func _run() -> void:
	await _setup()
	_check(klass != null and DreamState.CALLINGS.title("dewdrop") == "Puddles", "Dewdrop's Calling is Puddles")
	dreams.calling = "sporeling"
	_check_pool("dewdrop", LENT, 0)  # No class cards: the Calling evolves instead (owner 2026-10-16; calling_paths.gd)
	dreams.calling = "dewdrop"
	_check_pool("dewdrop", LENT, 0)
	await _frames(3)
	var route: Array = klass._route_px
	var at: Vector2 = route[10]

	# Puddles: the path touching a Dewdrop is water; a lone Dewdrop is lone until another attacker touches its water.
	var drop := _plant("dewdrop", at + Vector2(CELL, 0))
	await _frames(2)
	klass.on_board()
	_check(not klass.waters.is_empty(), "the path touching a Dewdrop is water")
	_check(klass.is_lone(drop), "a Dewdrop with nothing else on its water is lone")
	var a = _spawn(at)
	var b_at: Vector2 = route[12]
	var water_a: int = klass.water_of(a)
	if water_a >= 0:
		for i in klass.waters[water_a].points:
			if int(i) != klass.index_of(a) and absi(int(i) - klass.index_of(a)) <= klass.RIPPLE_STEPS * 2:
				b_at = route[int(i)]  # Another point in the same water (the map is random: route[12] may have left it)
				break
	var b = _spawn(b_at)
	var far = _spawn(route[mini(60, route.size() - 1)])
	_check(klass.water_of(a) >= 0 and klass.water_of(far) < 0, "a nightmare on that path stands in the water")
	drop.hit(a, 1.0, false, Tower.NO_CRIT)
	await _frames(2)
	_check(b.statuses.has(EnemyStatuses.DAMP), "the ripple Soaks nightmares within %d steps in that water" % klass.RIPPLE_STEPS)
	_check(not far.statuses.has(EnemyStatuses.DAMP), "nothing outside the water is Soaked by the ripple")

	# Free hits: one per Warden a second, never more than a second of its damage.
	drop.set_meta(klass.FREE_META, -INF)
	var health: int = b.health
	_check(klass.free_hit(drop, b), "a free hit lands")
	_check(health - b.health <= ceili(maxf(drop.get_damage(), klass.second_of(drop))) + 1, "a free hit is at most the Warden's hit")
	_check(not klass.free_hit(drop, b), "one free hit per Warden a second")

	# (Backwash and There and Back are retired from offers.)
	var sprout := _plant("sprout", at + Vector2(-CELL, 0))
	await _frames(2)
	klass.on_board()
	_check(sprout != null and not klass.is_lone(drop), "a Warden planted on the bank ends lone")

	# A later owner (owner 2026-10-14, dream_council_review.md 25-26): no water and no ripple, whatever lent cards are held.
	dreams.calling = "sporeling"
	for id in LENT:
		_take(id)
	klass.on_board()
	_check(klass.active() and not klass.place_on() and klass.waters.is_empty(), "a later Dewdrop owner holding every lent card has no water")
	var dry = _spawn(route[12])
	drop.hit(a, 1.0, false, Tower.NO_CRIT)
	await _frames(2)
	_check(not dry.statuses.has(EnemyStatuses.DAMP) or klass.index_of(dry) == klass.index_of(a), "...and no ripple")
	await _clean()

	# (Wash Away, Shallows, Knee-Deep, Caught Wading, Across the Water, Deep Pool, Riptide and Run-Off are retired, 2026-10-15.)
	# Steeped and Pooling (Enemy.apply_status asks status_duration): Steeped, a Warden touching a Dewdrop (a Dewdrop touches
	# itself) lands STEEPED_SHARE longer; Pooling, inside two Dewdrops' ranges POOLING_SHARE longer; together within LINGER_MAX;
	# never Drowsy or Rooted.
	var spot := Vector2(CELL * 30, CELL * 30)
	dreams.stacks.clear()
	_take("steeped")
	var s_drop := _plant("dewdrop", spot)
	var s_spore := _plant("sporeling", spot + Vector2(CELL, 0))
	var s_far := _plant("sporeling", spot + Vector2(CELL * 8, 0))
	await _frames(2)
	var st = _spawn(spot + Vector2(CELL * 8, CELL * 6))  # Inside no Dewdrop's range
	var spore_base: float = EnemyStatuses.DEFAULT_DURATION[EnemyStatuses.SPORED]
	var damp_base: float = EnemyStatuses.DEFAULT_DURATION[EnemyStatuses.DAMP]
	_check(is_equal_approx(klass.status_duration(s_spore, st, EnemyStatuses.SPORED, 0.0), spore_base + minf(spore_base * klass.STEEPED_SHARE, EnemyStatuses.LINGER_MAX)),
		"Steeped: Poisoned from a spore Warden touching a Dewdrop lasts %d%% longer" % roundi(klass.STEEPED_SHARE * 100.0))
	_check(is_equal_approx(klass.status_duration(s_drop, st, EnemyStatuses.DAMP, 0.0), damp_base + minf(damp_base * klass.STEEPED_SHARE, EnemyStatuses.LINGER_MAX)),
		"...a Dewdrop touches itself")
	_check(is_equal_approx(klass.status_duration(s_far, st, EnemyStatuses.SPORED, 5.0), 5.0), "...a Warden touching no Dewdrop: as it was")
	_check(is_equal_approx(klass.status_duration(s_spore, st, EnemyStatuses.DROWSY, 3.0), 3.0), "...never Drowsy")
	st.statuses.pending_linger.clear()
	s_spore._apply_one_status(st, EnemyStatuses.SPORED, 1, s_spore.get_damage())
	_check(st.statuses.is_lingering(EnemyStatuses.SPORED), "...the landing shows it lingers")
	# Steeped absorbed Pooling (card pass 2026-10-16): inside two Dewdrops' ranges counts too, one 40% either way
	var s_drop2 := _plant("dewdrop", spot + Vector2(0, CELL * 2))
	await _frames(2)
	var pool = _spawn(spot + Vector2(0, CELL))  # Inside both Dewdrops' ranges
	_check(is_equal_approx(klass.status_duration(s_far, pool, EnemyStatuses.SPORED, 5.0), 5.0 + minf(5.0 * klass.STEEPED_SHARE, EnemyStatuses.LINGER_MAX)),
		"Steeped: inside two Dewdrops' ranges a status lasts %d%% longer" % roundi(klass.STEEPED_SHARE * 100.0))
	_check(is_equal_approx(klass.status_duration(s_spore, pool, EnemyStatuses.SPORED, 10.0), 10.0 + minf(10.0 * klass.STEEPED_SHARE, EnemyStatuses.LINGER_MAX)),
		"...both ways at once still only 40%")
	pool.statuses.pending_linger.clear()
	_check(s_drop2 != null, "(the second Dewdrop stands)")
	await _clean()

	# The linger cap (EnemyStatuses.linger): everything that adds time after a landing adds at most LINGER_MAX (Charged
	# LINGER_MAX_STATIC); never Rooted or Drowsy.
	dreams.stacks.clear()
	var lg_drop := _plant("dewdrop", spot)
	await _frames(2)
	var lg = _spawn(spot + Vector2(CELL, 0))
	lg_drop._apply_one_status(lg, EnemyStatuses.DAMP, 1, lg_drop.get_damage())
	var lg_left: float = lg.statuses.time_left(EnemyStatuses.DAMP)
	_check(is_equal_approx(lg.statuses.linger(EnemyStatuses.DAMP, 100.0), EnemyStatuses.LINGER_MAX), "linger: at most %.0f s on one landing" % EnemyStatuses.LINGER_MAX)
	_check(is_equal_approx(lg.statuses.time_left(EnemyStatuses.DAMP), lg_left + EnemyStatuses.LINGER_MAX) and lg.statuses.is_lingering(EnemyStatuses.DAMP), "...the time left grows by it")
	_check(is_zero_approx(lg.statuses.linger(EnemyStatuses.DAMP, 1.0)), "...and no more after that")
	lg.apply_status(EnemyStatuses.STATIC, 1, 2.0, 1.0, 0, "light", null)
	_check(is_equal_approx(lg.statuses.linger(EnemyStatuses.STATIC, 100.0), EnemyStatuses.LINGER_MAX_STATIC), "...Charged at most %.0f s" % EnemyStatuses.LINGER_MAX_STATIC)
	_check(not EnemyStatuses.can_linger(EnemyStatuses.HELD) and not EnemyStatuses.can_linger(EnemyStatuses.DROWSY), "...never Rooted or Drowsy")
	await _clean()

	# Dripping: leaving a Dewdrop's range, every status keeps DRIPPING_SECONDS longer.
	dreams.stacks.clear()
	_take("dripping")
	var d_drop := _plant("dewdrop", at + Vector2(CELL, 0))
	await _frames(2)
	var dr = _spawn(at)
	d_drop._apply_one_status(dr, EnemyStatuses.DAMP, 1, d_drop.get_damage())
	klass._track_ranges(dr, [d_drop])  # Inside
	var wet_left: float = dr.statuses.time_left(EnemyStatuses.DAMP)
	var out_i := -1
	for i in range(11, route.size()):
		var point: Vector2 = route[i]
		if point.distance_to(d_drop.global_position) > d_drop.get_range_pixels() + CELL:
			out_i = i
			break
	_check(out_i >= 0, "(the route leaves the Dewdrop's range)")
	if out_i >= 0:
		dr.global_position = route[out_i]
		klass._track_ranges(dr, [d_drop])  # Left
		_check(is_equal_approx(dr.statuses.time_left(EnemyStatuses.DAMP), wet_left + klass.DRIPPING_SECONDS), "Dripping: leaving the range, Soaked keeps %.0f s longer" % klass.DRIPPING_SECONDS)
	await _clean()

	# Topped Up: a Dewdrop's hit puts every status back to its time at landing; once a second per nightmare.
	dreams.stacks.clear()
	_take("topped_up")
	var t_drop := _plant("dewdrop", spot)
	var t_spore := _plant("sporeling", spot + Vector2(CELL * 6, 0))
	await _frames(2)
	var tu = _spawn(spot + Vector2(CELL, 0))
	t_spore._apply_one_status(tu, EnemyStatuses.SPORED, 1, t_spore.get_damage())
	var landed: float = tu.statuses.time_left(EnemyStatuses.SPORED)
	tu.statuses.tick(1.5)
	_check(tu.statuses.time_left(EnemyStatuses.SPORED) < landed - 1.0, "(its time runs down)")
	t_drop.hit(tu, 1.0, false, Tower.NO_CRIT)
	await _frames(1)
	_check(absf(tu.statuses.time_left(EnemyStatuses.SPORED) - landed) < 0.01, "Topped Up: the Dewdrop's hit puts Poisoned back to its landing time")
	tu.statuses.tick(1.5)
	t_drop.hit(tu, 1.0, false, Tower.NO_CRIT)
	await _frames(1)
	_check(tu.statuses.time_left(EnemyStatuses.SPORED) < landed - 1.0, "...once a second per nightmare")
	await _clean()

	# Slow to Dry (rule id waterlogged): on a Soaked nightmare near a Dewdrop, another family's status can't run out before
	# its Soaked does (it lingers to match, within the linger cap).
	dreams.stacks.clear()
	_take("waterlogged")
	var l_drop := _plant("dewdrop", spot)
	var l_spore := _plant("sporeling", spot + Vector2(CELL * 6, 0))
	await _frames(2)
	var logged = _spawn(spot + Vector2(CELL, 0))
	logged.apply_status(EnemyStatuses.DAMP, 1, 8.0, 1.0, 0, "water", l_drop)
	l_spore._apply_one_status(logged, EnemyStatuses.SPORED, 1, l_spore.get_damage())
	var sp_left: float = logged.statuses.time_left(EnemyStatuses.SPORED)
	var soak_left: float = logged.statuses.time_left(EnemyStatuses.DAMP)
	_check(sp_left < soak_left, "(Poisoned would dry first)")
	klass._slow_to_dry(logged)
	_check(is_equal_approx(logged.statuses.time_left(EnemyStatuses.SPORED), sp_left + minf(soak_left - sp_left, EnemyStatuses.LINGER_MAX)),
		"Slow to Dry: Poisoned lingers to match its Soaked")
	var dry_far = _spawn(spot + Vector2(CELL * 12, CELL * 12))  # Near no Dewdrop
	dry_far.apply_status(EnemyStatuses.DAMP, 1, 8.0, 1.0, 0, "water", l_drop)
	l_spore._apply_one_status(dry_far, EnemyStatuses.SPORED, 1, l_spore.get_damage())
	var far_left: float = dry_far.statuses.time_left(EnemyStatuses.SPORED)
	klass._slow_to_dry(dry_far)
	_check(is_equal_approx(dry_far.statuses.time_left(EnemyStatuses.SPORED), far_left), "...near no Dewdrop: nothing")
	await _clean()

	# Ebb (EnemyStatuses.status_ran_out): a status running out in a Dewdrop's range comes back at half its most stacks, for
	# EBB_SECONDS; once per status and nightmare; never Drowsy.
	dreams.stacks.clear()
	_take("ebb")
	var e_drop := _plant("dewdrop", spot)
	var e_spore := _plant("sporeling", spot + Vector2(CELL * 6, 0))
	await _frames(2)
	var eb = _spawn(spot + Vector2(CELL, 0))
	var peak := 8
	klass._ebb(EnemyStatuses.SPORED, peak, e_spore, 1.0, "spore", eb)
	_check(eb.statuses.stacks(EnemyStatuses.SPORED) == maxi(int(peak / 2.0), 1), "Ebb: a status that ran out comes back at half its most (%d)" % eb.statuses.stacks(EnemyStatuses.SPORED))
	eb.statuses.remove(EnemyStatuses.SPORED)
	klass._ebb(EnemyStatuses.SPORED, peak, e_spore, 1.0, "spore", eb)
	_check(not eb.statuses.has(EnemyStatuses.SPORED), "...once per status and nightmare")
	klass._ebb(EnemyStatuses.DROWSY, peak, e_spore, 1.0, "song", eb)
	_check(not eb.statuses.has(EnemyStatuses.DROWSY), "...never Drowsy")
	var ebb_far = _spawn(spot + Vector2(CELL * 12, CELL * 12))  # In no Dewdrop's range
	klass._ebb(EnemyStatuses.SPORED, peak, e_spore, 1.0, "spore", ebb_far)
	_check(not ebb_far.statuses.has(EnemyStatuses.SPORED), "...outside a Dewdrop's range: gone for good")
	_check(e_drop != null, "(the Dewdrop stands)")
	await _clean()
	await _self_help_checks(spot)
	await _evolution_checks(at, route)
	await _f1_checks(at, route, spot)
	print("test_class_dewdrop: %d failures" % failures)
	quit(failures)
