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
const LENT := ["steeped", "topped_up", "ebb", "the_water_remembers", "waterlogged", "high_tide",
	"old_rain", "never_quite_dry"]  # Card pass 2026-10-16: Dripping and Pooling folded into Steeped

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

func _run() -> void:
	await _setup()
	_check(klass != null and DreamState.CALLINGS.title("dewdrop") == "Puddles", "Dewdrop's Calling is Puddles")
	dreams.calling = "sporeling"
	_check_pool("dewdrop", LENT, 5)  # 5 class-only and 10 lent (owner 2026-10-14)
	dreams.calling = "dewdrop"
	_check_pool("dewdrop", LENT, 5)
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
	print("test_class_dewdrop: %d failures" % failures)
	quit(failures)
