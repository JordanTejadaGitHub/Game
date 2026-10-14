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
	_check_pool("dewdrop", ["run_off", "caught_wading", "across_the_water", "wash_away", "deep_pool", "the_water_remembers", "riptide"], 3)
	dreams.calling = "dewdrop"
	_check_pool("dewdrop", ["run_off", "caught_wading", "across_the_water", "wash_away", "deep_pool", "the_water_remembers", "riptide"], 3)
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

	# (Backwash and There and Back are retired from offers: Dewdrop keeps 3 class cards, 2026-10-13.)
	# A second-pick owner gets the water but not the ripple (the Calling stays with the first pick).
	dreams.calling = "sporeling"
	_take("across_the_water")
	klass.on_board()
	_check(not klass.waters.is_empty(), "a later Dewdrop owner with a water card still has water")
	var dry = _spawn(route[12])
	drop.hit(a, 1.0, false, Tower.NO_CRIT)
	await _frames(2)
	_check(not dry.statuses.has(EnemyStatuses.DAMP), "...but no ripple: that is the Calling, first pick only")
	dreams.calling = "dewdrop"
	var sprout := _plant("sprout", at + Vector2(-CELL, 0))
	await _frames(2)
	klass.on_board()
	_check(sprout != null and not klass.is_lone(drop), "a Warden planted on the bank ends lone")

	# Wash Away: half the family resistance, for Wardens touching the water, on a Soaked nightmare in it.
	_take("wash_away")
	_check(is_equal_approx(klass.damage_multiplier(far, drop), 1.0), "Wash Away does nothing outside the water")
	await _clean()
	print("test_class_dewdrop: %d failures" % failures)
	quit(failures)
