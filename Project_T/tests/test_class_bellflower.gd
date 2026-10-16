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
const LENT := ["on_the_beat", "in_time", "nod_off", "refrain", "second_verse", "knell", "curtain_call", "reprise",
	"rude_awakening", "da_capo"]  # Trait rework 2026-10-15: things happen again

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
	klass = dreams.keeping_time

func _run() -> void:
	await _setup()
	_check(klass != null and DreamState.CALLINGS.title("bellflower") == "Keeping Time", "Bellflower's Calling is Keeping Time")
	dreams.calling = "dewdrop"
	_check_pool("bellflower", LENT, 0)  # No class cards: the Calling evolves instead (owner 2026-10-16; calling_paths.gd)
	dreams.calling = "bellflower"
	_check_pool("bellflower", LENT, 0)
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

	# Nod Off (2026-10-14): the first time a bell makes a nightmare Drowsy it naps 1 s; never on a sleeper; one per bell.
	_take("nod_off")
	var b = _spawn(at)
	bell._apply_one_status(b, EnemyStatuses.DROWSY, 1, bell.get_damage())
	_check(b.statuses.is_asleep() and b.statuses.sleep_time <= klass.NAP_SECONDS + 0.01, "Nod Off: a bell's first Drowsy, asleep for %s s" % klass.NAP_SECONDS)
	_check(not klass.nap(b), "the nap never lands on a sleeper")
	var c = _spawn(at)
	bell._apply_one_status(c, EnemyStatuses.DROWSY, 1, bell.get_damage())
	_check(not c.statuses.is_asleep(), "one sleeper for each bell")
	var immune = _spawn(at)
	immune.statuses.immune.append(EnemyStatuses.DROWSY)
	var other_bell := _plant("bellflower", at + Vector2(CELL * 8, 0))
	other_bell._apply_one_status(immune, EnemyStatuses.DROWSY, 1, other_bell.get_damage())
	_check(not immune.statuses.is_asleep(), "Nod Off: a Drowsy-immune nightmare never naps (only an accepted status counts)")

	# Rising Song: each pulse that Tolls makes the landing bigger, up to double.
	_take("rising_song")
	bell.set_meta(klass.RISING_META, 100)
	var d = _spawn(at)
	d.set_meta(klass.PIPS_META, klass.TOLL_EVERY - 1)
	health = d.health
	klass.ring(d, bell, 100.0)
	_check(health - d.health <= ceili(100.0 * klass.RISING_MAX) + 1, "Rising Song: a Toll's landing is at most double the ring")

	# Join In (class-only since 2026-10-14): another Warden touching the bell fills pips with its hits, once a second.
	_take("join_in")
	var sprout := _plant("sprout", at + Vector2(CELL, CELL))
	await _frames(2)
	var e = _spawn(at)
	sprout.hit(e, 1.0, false, Tower.NO_CRIT)
	await _frames(2)
	_check(int(e.get_meta(klass.PIPS_META, klass.PIPS_FILLED)) == klass.PIPS_FILLED + 1, "Join In: a touching Warden's hit counts as a ring")
	await _clean()

	# A later owner (owner 2026-10-14, dream_council_review.md 25-26): no rings, pips or Tolls, whatever lent cards are held.
	dreams.calling = "dewdrop"
	dreams.stacks.clear()
	for id in LENT:
		_take(id)
	var later_bell := _plant("bellflower", at + Vector2(CELL, 0))
	await _frames(2)
	_check(klass._start_pips() == 0 and klass.active() and not klass.tolls_on(), "a later Bellflower owner holding every lent card has no Tolls")
	var f = _spawn(at)
	klass.ring(f, later_bell, 10.0)
	_check(not f.has_meta(klass.PIPS_META), "...and rings fill no pips")
	await _clean()

	# (Hum Along, Ringing Ears, Sleep No More and Clashing Notes are retired, 2026-10-15.)
	var spot := Vector2(CELL * 30, CELL * 30)

	# In Time: every IN_TIME_EVERY-th hit a Warden touching a bell lands on one nightmare lands again IN_TIME_DELAY s later.
	dreams.stacks.clear()
	_take("in_time")
	_plant("bellflower", spot)
	var t_sprout := _plant("sprout", spot + Vector2(CELL, 0))
	var t_far := _plant("sprout", spot + Vector2(CELL * 6, 0))  # Touching no bell
	await _frames(2)
	var t = _spawn(spot + Vector2(CELL * 2, 0))
	klass._later.clear()
	for i in klass.IN_TIME_EVERY - 1:
		t_sprout.hit(t, 1.0, false, Tower.NO_CRIT)
		await process_frame  # An attack counts once a frame
	_check(klass._later.is_empty(), "In Time: nothing before hit %d" % klass.IN_TIME_EVERY)
	t_sprout.hit(t, 1.0, false, Tower.NO_CRIT)
	_check(klass._later.size() == 1, "...hit %d of a Warden touching a bell waits to land again" % klass.IN_TIME_EVERY)
	var t_health: float = t.health
	for i in 240:
		if klass._later.is_empty():
			break
		await process_frame
	_check(klass._later.is_empty() and t.health < t_health, "...and lands again %.2f s later" % klass.IN_TIME_DELAY)
	for i in klass.IN_TIME_EVERY:
		t_far.hit(t, 1.0, false, Tower.NO_CRIT)
		await process_frame
	_check(klass._later.is_empty(), "...a Warden touching no bell never counts")
	await _clean()

	# Refrain (trait rework): after a bell hits a nightmare, the next hit on it from another Warden within REFRAIN_SECONDS
	# lands twice; each Warden once every REFRAIN_EVERY s.
	dreams.stacks.clear()
	_take("refrain")
	var r_bell := _plant("bellflower", spot)
	var r_rock := _plant("pebbling", spot + Vector2(CELL * 6, 0))
	await _frames(2)
	var r = _spawn(spot + Vector2(CELL, 0))
	var r0: float = r.health
	r_rock.hit(r, 1.0, false, Tower.NO_CRIT)
	await process_frame
	var single: float = r0 - r.health
	_check(single > 0.0, "(the partner's hit lands)")
	r_bell.hit(r, 1.0, false, Tower.NO_CRIT)
	await process_frame
	var r1: float = r.health
	r_rock.hit(r, 1.0, false, Tower.NO_CRIT)
	await process_frame
	_check(absf((r1 - r.health) - 2.0 * single) <= 2.0, "Refrain: after the bell's hit, the partner's next hit lands twice (%.0f, one hit %.0f)" % [r1 - r.health, single])
	r_bell.hit(r, 1.0, false, Tower.NO_CRIT)
	await process_frame
	var r2: float = r.health
	r_rock.hit(r, 1.0, false, Tower.NO_CRIT)
	await process_frame
	_check(absf((r2 - r.health) - single) <= 2.0, "...each Warden once every %.0f s" % klass.REFRAIN_EVERY)
	await _clean()

	# Rude Awakening (trait rework): waking (or let go), the last hits of up to RUDE_WARDENS Wardens land again.
	dreams.stacks.clear()
	_take("rude_awakening")
	var ra_rock := _plant("pebbling", spot)
	await _frames(2)
	var ra = _spawn(spot + Vector2(CELL, 0))
	var ra0: float = ra.health
	ra_rock.hit(ra, 1.0, false, Tower.NO_CRIT)
	await process_frame
	var ra_hit: float = ra0 - ra.health
	_check(ra.statuses.sleep(1.0), "(it falls asleep)")
	klass.on_poll()  # Seen asleep
	ra.statuses.sleep_time = 0.0
	var ra1: float = ra.health
	klass.on_poll()  # Seen awake: the last hit lands again
	_check(ra_hit > 0.0 and absf((ra1 - ra.health) - ra_hit) <= 2.0, "Rude Awakening: waking, the last hit lands again (%.0f of %.0f)" % [ra1 - ra.health, ra_hit])
	await _clean()

	# Knell (hard cards 2026-10-16): a bell's hit lands again once per status other families put on the nightmare, up to
	# 3, 0.2 s apart, each adding 1 of the bell's status; once per nightmare every 6 s. Repeats never advance In Time.
	dreams.stacks.clear()
	_take("knell")
	_take("in_time")
	var k_bell := _plant("bellflower", spot)
	var k_spore := _plant("sporeling", spot + Vector2(CELL * 6, 0))
	await _frames(2)
	var k = _spawn(spot + Vector2(CELL, 0))
	k.max_health = 900000
	k.health = 900000
	k_spore._apply_one_status(k, EnemyStatuses.SPORED, 10, k_spore.get_damage())
	klass._later.clear()
	var poisoned: int = k.statuses.stacks(EnemyStatuses.SPORED)
	k_bell.hit(k, 1.0, false, Tower.NO_CRIT)
	_check(klass._later.size() == 1, "Knell: one other-family status queues 1 repeat (%d)" % klass._later.size())
	var in_time_count := int(k.get_meta(klass.IN_TIME_META, {}).get(k_bell.get_instance_id(), 0))
	var k_health: float = k.health
	var drowsy: int = k.statuses.stacks(EnemyStatuses.DROWSY)
	for i in 120:
		if klass._later.is_empty():
			break
		await process_frame
	_check(klass._later.is_empty() and k.health < k_health, "...the hit lands again %.1f s later" % klass.KNELL_REPEAT_GAP)
	_check(k.statuses.stacks(EnemyStatuses.DROWSY) > drowsy, "...and adds the bell's Drowsy (%d -> %d)" % [drowsy, k.statuses.stacks(EnemyStatuses.DROWSY)])
	_check(k.statuses.stacks(EnemyStatuses.SPORED) >= poisoned, "...nothing is used up")
	_check(int(k.get_meta(klass.IN_TIME_META, {}).get(k_bell.get_instance_id(), 0)) == in_time_count, "...a repeat never counts for In Time")
	await process_frame
	k_bell.hit(k, 1.0, false, Tower.NO_CRIT)
	_check(klass._later.is_empty(), "...once per nightmare every %d s" % int(klass.KNELL_EVERY))
	dreams.stacks.erase("in_time")
	dreams.calling = "bellflower"
	await _clean()
	print("test_class_bellflower: %d failures" % failures)
	quit(failures)
