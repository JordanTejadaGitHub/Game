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
const LENT := ["caught_wading", "shallows", "knee_deep", "across_the_water", "deep_pool", "the_water_remembers", "run_off",
	"wash_away", "riptide", "waterlogged"]

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
		_check(card.tags.has(DreamState.LENT_TAG) and card.calling == "" and card.requires.has(family), "%s is a lent %s card" % [id, family])
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

	# Wash Away (2026-10-15, resistances gone): a Soaked nightmare's shell takes double from Wardens near a Dewdrop; nothing unless both.
	var spot := Vector2(CELL * 30, CELL * 30)
	var w_drop := _plant("dewdrop", spot)
	var w_near := _plant("sprout", spot + Vector2(CELL, 0))
	var w_far := _plant("sprout", spot + Vector2(CELL * 6, 0))
	await _frames(2)
	var shelled = _spawn(spot + Vector2(CELL, CELL))
	_check(is_equal_approx(klass.shell_multiplier(shelled, w_near), 1.0), "Wash Away: nothing on a dry nightmare")
	w_drop._apply_one_status(shelled, EnemyStatuses.DAMP, 1, w_drop.get_damage())
	_check(is_equal_approx(klass.shell_multiplier(shelled, w_near), klass.WASH_AWAY_SHELL), "...Soaked, hit by a Warden near a Dewdrop: its shell takes double")
	_check(is_equal_approx(klass.shell_multiplier(shelled, w_far), 1.0), "...a Warden far from any Dewdrop gets nothing")
	await _clean()

	# Shallows: a hit from another Warden touching a Dewdrop adds 1 Soaked, once a second.
	var s_drop := _plant("dewdrop", spot)
	var s_sprout := _plant("sprout", spot + Vector2(CELL, 0))
	await _frames(2)
	var wet = _spawn(spot + Vector2(CELL * 2, 0))
	s_sprout.hit(wet, 1.0, false, Tower.NO_CRIT)
	await _frames(1)
	_check(wet.statuses.stacks(EnemyStatuses.DAMP) == 1 and s_drop != null, "Shallows: the Sprout's hit beside a Dewdrop adds 1 Soaked")
	s_sprout.hit(wet, 1.0, false, Tower.NO_CRIT)
	await _frames(1)
	_check(wet.statuses.stacks(EnemyStatuses.DAMP) == 1, "...once a second per Warden")
	await _clean()

	# Knee-Deep and the slow fix (fix 7): Knee-Deep's repeated small slow never keeps a bigger one alive.
	var k_drop := _plant("dewdrop", spot)
	await _frames(2)
	var wader = _spawn(spot + Vector2(CELL, 0))
	k_drop._apply_one_status(wader, EnemyStatuses.DAMP, 1, k_drop.get_damage())
	HelperCommons.slow(wader, klass.RIPTIDE_SLOW, 0.3)
	for i in 6:
		klass.on_poll()
		wader.statuses._tick_timers(0.1)
	_check(is_equal_approx(wader.statuses.timed_slow(), klass.KNEE_SLOW), "Knee-Deep keeps its 10%%; the 50%% slow ran out on time (%.2f)" % wader.statuses.timed_slow())
	await _clean()

	# Waterlogged: another family's status near a Dewdrop on a Soaked nightmare lasts x1.5; never Drowsy.
	var l_drop := _plant("dewdrop", spot)
	var l_spore := _plant("sporeling", spot + Vector2(CELL, 0))
	await _frames(2)
	var logged = _spawn(spot + Vector2(CELL, CELL))
	l_drop._apply_one_status(logged, EnemyStatuses.DAMP, 1, l_drop.get_damage())
	_check(is_equal_approx(klass.status_duration(l_spore, logged, EnemyStatuses.SPORED, 5.0), 5.0 * klass.WATERLOGGED_FACTOR), "Waterlogged: Poisoned lasts x%.1f" % klass.WATERLOGGED_FACTOR)
	_check(is_equal_approx(klass.status_duration(l_spore, logged, EnemyStatuses.DROWSY, 3.0), 3.0), "...never Drowsy")
	await _clean()
	print("test_class_dewdrop: %d failures" % failures)
	quit(failures)
