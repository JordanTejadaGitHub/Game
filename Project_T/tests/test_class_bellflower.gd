extends SceneTree
# The Bellflower class: Keeping Time, rings and Tolls (documentation/dream_council_review.md 20 to 21). Written 2026-10-13 and NOT RUN: the owner has paused
# tests. The numbers come from the class script's constants, so retuning does not break it.
var failures := 0
var main: Node
var spawner
var placer: TowerPlacer
var container: Node
var dreams: DreamState
var klass  # The class node (DreamState.keeping_time)
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
	klass = dreams.keeping_time

func _run() -> void:
	await _setup()
	_check(klass != null and DreamState.CALLINGS.title("bellflower") == "Keeping Time", "Bellflower's Calling is Keeping Time")
	dreams.calling = "dewdrop"
	_check_pool("bellflower", ["knell", "on_the_beat", "join_in", "nod_off", "rude_awakening", "sleep_no_more", "refrain"], 3)
	dreams.calling = "bellflower"
	_check_pool("bellflower", ["knell", "on_the_beat", "join_in", "nod_off", "rude_awakening", "sleep_no_more", "refrain"], 3)
	await _frames(3)
	var route: Array = klass._route_px
	var at: Vector2 = route[10]
	var bell := _plant("bellflower", at + Vector2(CELL, 0))
	await _frames(2)
	klass.on_board()

	# Keeping Time: 2 of 4 pips filled, so the 2nd ring is a Toll; it lands again at half; then 4 more rings.
	var a = _spawn(at)
	klass.ring(a, bell, 10.0)
	_check(klass.tolls == 0 and int(a.get_meta(klass.PIPS_META)) == klass.PIPS_FILLED + 1, "the first ring fills a third pip")
	klass.ring(a, bell, 10.0)
	_check(klass.tolls == 0, "rings closer than half a second count as one")
	a.set_meta(klass.RING_META, -INF)
	var health: int = a.health
	klass.ring(a, bell, 10.0)
	_check(klass.tolls == 1 and a.health < health, "the second ring is a Toll: it lands again")
	_check(int(a.get_meta(klass.PIPS_META)) == 0, "the pips start over")
	for n in klass.TOLL_EVERY:
		a.set_meta(klass.RING_META, -INF)
		klass.ring(a, bell, 10.0)
	_check(klass.tolls == 1, "one Toll a second for each nightmare")
	a.set_meta(klass.TOLL_META, -INF)
	a.set_meta(klass.RING_META, -INF)
	klass.ring(a, bell, 10.0)
	_check(klass.tolls == 2, "...and it Tolls once the second is up")

	# Nod Off: a nightmare's first Toll puts it to sleep for 1 s; the nap never lands on a sleeper.
	_take("nod_off")
	var b = _spawn(at)
	b.set_meta(klass.PIPS_META, klass.TOLL_EVERY - 1)
	klass.ring(b, bell, 10.0)
	_check(b.statuses.is_asleep() and b.statuses.sleep_time <= klass.NAP_SECONDS + 0.01, "Nod Off: asleep for %s s" % klass.NAP_SECONDS)
	_check(not klass.nap(b), "the nap never lands on a sleeper")
	var c = _spawn(at)
	c.set_meta(klass.PIPS_META, klass.TOLL_EVERY - 1)
	klass.ring(c, bell, 10.0)
	_check(not c.statuses.is_asleep(), "one sleeper for each bell")

	# Rising Song: each pulse that Tolls makes the landing bigger, up to double.
	_take("rising_song")
	bell.set_meta(klass.RISING_META, 100)
	var d = _spawn(at)
	d.set_meta(klass.PIPS_META, klass.TOLL_EVERY - 1)
	health = d.health
	klass.ring(d, bell, 100.0)
	_check(health - d.health <= ceili(100.0 * klass.RISING_MAX) + 1, "Rising Song: a Toll's landing is at most double the ring")

	# Join In: another Warden touching the bell fills pips with its hits, once a second.
	_take("join_in")
	var sprout := _plant("sprout", at + Vector2(CELL, CELL))
	await _frames(2)
	var e = _spawn(at)
	sprout.hit(e, 1.0, false, Tower.NO_CRIT)
	await _frames(2)
	_check(int(e.get_meta(klass.PIPS_META, klass.PIPS_FILLED)) == klass.PIPS_FILLED + 1, "Join In: a touching Warden's hit counts as a ring")

	# A later Bellflower owner counts rings from 0 pips: the head start is the Calling's.
	dreams.calling = "dewdrop"
	_check(klass._start_pips() == 0, "no Calling: Tolls count from 0 pips")
	dreams.calling = "bellflower"
	await _clean()
	print("test_class_bellflower: %d failures" % failures)
	quit(failures)
