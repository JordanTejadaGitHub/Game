extends SceneTree
# The Sporeling class: Spore Print, mushrooms and doses (documentation/dream_council_review.md 20 to 21). Written 2026-10-13 and NOT RUN: the owner has paused
# tests. The numbers come from the class script's constants, so retuning does not break it.
var failures := 0
var main: Node
var spawner
var placer: TowerPlacer
var container: Node
var dreams: DreamState
var klass  # The class node (DreamState.spore_print)
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
		_check(card.rule_id != &"" and card.description != "" and card.tip.begins_with("Works for:"), "%s says who it works for" % card.id)
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
	klass = dreams.spore_print

func _run() -> void:
	await _setup()
	_check(klass != null and DreamState.CALLINGS.title("sporeling") == "Spore Print", "Sporeling's Calling is Spore Print")
	dreams.calling = "firefly_jar"
	_check_pool("sporeling", ["mycelium", "overnight", "pass_it_round", "second_helping", "narrows", "seeping_in", "mixed_company"], 3)
	dreams.calling = "sporeling"
	_check_pool("sporeling", ["mycelium", "overnight", "pass_it_round", "second_helping", "narrows", "seeping_in", "mixed_company"], 3)
	await _frames(3)
	var route: Array = klass._route_px
	_check(route.size() > 12, "the class node knows the route")
	var at: Vector2 = route[8]

	# Spore Print: a Poisoned nightmare dispelled by any Warden leaves a mushroom; the next walker to step on it takes a dose.
	var spore := _plant("sporeling", at + Vector2(CELL, 0))
	var sprout := _plant("sprout", at + Vector2(CELL * 4, CELL * 4))
	await _frames(2)
	var a = _spawn(at)
	a.apply_status(EnemyStatuses.SPORED, 1, 5.0, 1.0, 0, "spore", spore)
	a.health = 1
	sprout.hit(a, 1.0, false, Tower.NO_CRIT)
	await _frames(2)
	_check(klass.mushrooms.size() == 1, "a Poisoned nightmare's dispel leaves one mushroom (%d)" % klass.mushrooms.size())
	var clean = _spawn(route[20])
	clean.health = 1
	sprout.hit(clean, 1.0, false, Tower.NO_CRIT)
	await _frames(2)
	_check(klass.mushrooms.size() == 1, "a nightmare that was not Poisoned leaves none")
	var point: Vector2 = klass.mushrooms.keys()[0]
	var b = _spawn(route[int(klass._index[point])])
	klass._stepped(point, b)
	_check(b.statuses.stacks(EnemyStatuses.SPORED) == klass.DOSE, "stepping on it gives a dose of %d Poisoned" % klass.DOSE)
	_check(klass.mushrooms.is_empty(), "one step, one dose, gone")

	# Mushrooms survive a save; the limit is 40.
	klass.leave_mushroom(route[8], spore)
	var saved: Array = klass.to_save()
	klass.mushrooms.clear()
	klass.saved = saved
	klass.on_board()
	_check(klass.mushrooms.size() == 1, "mushrooms come back from the run save")
	for i in range(0, mini(route.size(), 120)):
		klass._grow(klass._route[i], false, spore)
	_check(klass.mushrooms.size() <= klass.MUSHROOM_MAX, "at most %d mushrooms on the map" % klass.MUSHROOM_MAX)
	klass.mushrooms.clear()

	# It Grows on You: each dose a nightmare steps on is 1 bigger, up to 6. Twin Caps: two different nightmares.
	_take("it_grows_on_you")
	var c = _spawn(at)
	for n in 5:
		klass._grow(klass._route[8], false, spore)
		c.statuses.remove(EnemyStatuses.SPORED)
		klass._stepped(klass._route[8], c)
		_check(c.statuses.stacks(EnemyStatuses.SPORED) == mini(klass.DOSE + n, klass.GROWS_MAX), "dose %d is %d" % [n + 1, mini(klass.DOSE + n, klass.GROWS_MAX)])
	_take("twin_caps")
	klass._grow(klass._route[8], false, spore)
	var d = _spawn(at)
	klass._stepped(klass._route[8], d)
	klass._stepped(klass._route[8], d)
	_check(klass.mushrooms.size() == 1, "Twin Caps: the same nightmare never takes both caps")
	klass._stepped(klass._route[8], c)
	_check(klass.mushrooms.is_empty(), "Twin Caps: a second nightmare uses it up")

	# Narrows: a status hit on a nightmare touching a spore Warden and another kind of Warden adds 3 at once.
	_take("narrows")
	var second := _plant("sprout", at + Vector2(-CELL, 0))
	await _frames(2)
	var n = _spawn(at)
	spore._apply_one_status(n, EnemyStatuses.SPORED, 1, spore.get_damage())
	_check(n.statuses.stacks(EnemyStatuses.SPORED) == 1 + klass.NARROWS_EXTRA, "Narrows: a 1-stack hit lands %d" % (1 + klass.NARROWS_EXTRA))
	spore._apply_one_status(n, EnemyStatuses.SPORED, 1, spore.get_damage())
	_check(n.statuses.stacks(EnemyStatuses.SPORED) == 2 + klass.NARROWS_EXTRA, "...once a second per Warden")

	# The quiet add: no new status, no clock change, Charged one short of a bolt.
	var e = _spawn(at)
	_check(e.statuses.add_quiet(EnemyStatuses.DAMP, 3) == 0, "a quiet add never starts a status")
	e.apply_status(EnemyStatuses.DAMP, 1, 5.0, 1.0, 0, "water", second)
	var left: float = e.statuses.time_left(EnemyStatuses.DAMP)
	_check(e.statuses.add_quiet(EnemyStatuses.DAMP, 2) == 2 and is_equal_approx(e.statuses.time_left(EnemyStatuses.DAMP), left), "stacks go up, the clock does not")
	e.apply_status(EnemyStatuses.STATIC, 1, 5.0, 1.0, 0, "light", second)
	e.statuses.add_quiet(EnemyStatuses.STATIC, 99)
	_check(e.statuses.has(EnemyStatuses.STATIC) and e.statuses.stacks(EnemyStatuses.STATIC) == e.statuses.get_max_stacks(EnemyStatuses.STATIC) - 1, "Charged stops one short of a bolt")
	await _clean()
	print("test_class_sporeling: %d failures" % failures)
	quit(failures)
