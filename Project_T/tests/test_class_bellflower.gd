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
const LENT := ["on_the_beat", "in_time", "nod_off", "refrain", "second_verse", "knell", "reprise",
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

# What one Toll on `enemy` deals (its pips one short; the ring's hit `amount`).
func _toll_loss(enemy, bell, amount: float) -> float:
	enemy.set_meta(klass.PIPS_META, klass.TOLL_EVERY - 1)
	enemy.set_meta(klass.RING_META, -INF)
	enemy.set_meta(klass.TOLL_META, -INF)
	var was: float = enemy.health
	klass.ring(enemy, bell, amount)
	return was - float(enemy.health)

# F1 lent × Calling (owner 2026-10-18; D:\Projects\logs\dream_council\f1_spec.md): a Toll counts as its bell's hit for
# another family's lent card (Sodden), never for Bellflower's own (In Time), and Hush-a-bye's Drowsy never naps (Nod Off).
func _f1_checks(_at: Vector2, spot: Vector2) -> void:
	dreams.stacks.clear()
	dreams.calling = "bellflower"
	dreams.calling_path.clear()
	_take("sodden")
	_take("in_time")
	var bell := _plant("bellflower", spot)
	var drop := _plant("dewdrop", spot + Vector2(CELL, 0))  # Near the bell: Sodden's Wardens
	await _frames(3)
	var dry = _spawn(spot + Vector2(0, CELL))
	var wet = _spawn(spot + Vector2(0, CELL))
	wet.apply_status(EnemyStatuses.DAMP, 1, 30.0, 1.0, 0, "water", drop)
	wet.statuses.tick(5.0)  # Soaked for 5 s: Sodden at its most
	await process_frame
	klass._later.clear()
	var plain := _toll_loss(dry, bell, 1000.0)
	_toll_loss(wet, bell, 1000.0)
	# evo_shared_spec.md 2-3 and R1 (2026-10-23): the Toll is a Calling hit, damage only, never an F1 output (was "a Toll is
	# its bell's hit for Sodden"; Sodden's own reading of a Calling hit is Dewdrop's to check).
	_check(plain > 0.0, "a Toll lands (%.0f)" % plain)
	_check(int(wet.get_meta(klass.IN_TIME_META, {}).get(bell.get_instance_id(), 0)) == 0 and klass._later.is_empty(),
		"F1: never for its own family (a Toll is no hit for In Time)")
	_check(DamageLog.calling_next == &"" and DamageLog.calling_now == &"", "F1: nothing stays armed after a Toll")
	await _clean()

	# Another family's Calling application of a bell's Drowsy (Rain on the Bank on a Dewdrop start) never sets Nod Off
	dreams.stacks.clear()
	dreams.calling = "dewdrop"
	_take("nod_off")
	bell = _plant("bellflower", spot)
	await _frames(2)
	var h = _spawn(spot + Vector2(CELL, 0))
	dreams.arm_apply("dewdrop", true)
	bell._apply_one_status(h, EnemyStatuses.DROWSY, 1, bell.get_damage(), false)
	_check(h.statuses.has(EnemyStatuses.DROWSY) and not h.statuses.is_asleep() and not h.has_meta(klass.DROWSED_META),
		"F1: a Calling application's Drowsy never sets Nod Off (control stays bounded)")
	var native = _spawn(spot + Vector2(CELL, CELL * 0.5))
	bell._apply_one_status(native, EnemyStatuses.DROWSY, 1, bell.get_damage())
	_check(native.statuses.is_asleep(), "(the bell's own Drowsy still naps)")
	dreams.calling = "bellflower"
	dreams.stacks.clear()
	await _clean()
	_check(load("res://resource/dream/rude_awakening.tres").tip.contains("Wardens and cards that make nightmares {asleep} or {held}")
		and not load("res://resource/dream/rude_awakening.tres").tip.contains("{card:"), "F8: Rude Awakening's tip names no card")
	_check(not load("res://resource/dream/old_rain.tres").tip.contains("{card:"), "F8: Old Rain's tip names no card")

# Sets the Calling path and rebuilds what reads it (keeps_out, the bell groups, walls, joined Wardens).
func _path(ids: Array) -> void:
	dreams.calling = "bellflower"
	dreams.calling_path.assign(ids)
	dreams._rebuild_calling_flags()
	klass.on_board()

func _ready_to_ring(enemy) -> void:
	enemy.set_meta(klass.RING_META, -INF)
	enemy.set_meta(klass.TOLL_META, -INF)

# Calling evolutions rebuilt 2026-10-23 (dream_council_review.md 33; evo_fixed_bellflower.md, evo_shared_spec.md 2 and 9):
# one "old effect gone" check per kept id whose meaning changed, and a check per new row where practical.
func _evolution_checks(spot: Vector2) -> void:
	dreams.stacks.clear()
	var route: Array = klass._route_px
	var bell := _plant("bellflower", spot)  # Far from the route: it reaches no route point
	await _frames(2)

	# Carrying Tune (old: the carried ring also struck at half): the ring only, the bell's whole hit
	_path([&"kt_evo_carrying_tune"])
	var target = _spawn(route[20])
	var ahead = _spawn(route[24])
	var ahead0: float = ahead.health
	klass._carry_from(bell, target, 100.0)
	_check(is_equal_approx(float(ahead.health), ahead0), "Carrying Tune: the carried ring deals nothing (old half strike gone)")
	_check(int(ahead.get_meta(klass.PIPS_META, 0)) == klass.PIPS_FILLED + 1, "...and fills a pip")
	_check(klass.TUNE_STEPS == 6 and String(DreamState.CALLING_PATHS.PATHS[&"kt_evo_carrying_tune"].text).contains("6 {steps}"), "Carrying Tune: 6 steps (Balancing 2026-10-23)")
	await _clean()

	# Steady Beat (old: 3 starting pips where 2+ bells' ranges overlap, full Tolls there): one group, need 3, in full
	bell = _plant("bellflower", spot)
	var far_bell := _plant("bellflower", spot + Vector2(CELL * 6, 0))  # Not touching: another group
	await _frames(2)
	_path([&"kt_evo_steady_beat"])
	_check(not klass.has_method("_bells_reaching") and klass._start_for(null) == klass.PIPS_FILLED, "Steady Beat: the old overlap start pips are gone")
	var s = _spawn(spot + Vector2(0, CELL))
	var tolls0: int = klass.tolls
	klass.ring(s, bell, 10.0)
	_check(klass.tolls == tolls0 + 1, "Steady Beat: one group's first ring Tolls (2 starting pips + 1 = %d)" % klass.STEADY_NEED)
	var mixed = _spawn(spot + Vector2(0, CELL * 1.5))
	klass.ring(mixed, far_bell, 10.0)  # A Toll at once (its group's first ring)…
	_ready_to_ring(mixed)
	klass.ring(mixed, far_bell, 10.0)
	_ready_to_ring(mixed)
	klass.ring(mixed, bell, 10.0)  # …then a second group rings it
	_check(klass._toll_need(mixed) == klass.TOLL_EVERY, "...another group's ring puts it back to every %dth" % klass.TOLL_EVERY)
	await _clean()

	# Deep Tone / Double Time: a rank III bell's own hit rings twice; a rank IV bell's Toll leaves 2 rings
	bell = _plant("bellflower", spot)
	await _frames(2)
	_path([&"kt_evo_steady_beat", &"kt_evo_deep_tone", &"kt_evo_double_time"])
	var other_group := _plant("bellflower", spot + Vector2(CELL * 6, 0))
	await _frames(2)
	klass.on_board()
	var d = _spawn(spot + Vector2(0, CELL))
	d.set_meta(klass.GROUP_META, -1)  # Mixed: the need stays 4
	d.set_meta(klass.PIPS_META, 0)
	bell.rank = 3
	klass._groups[bell.get_instance_id()] = 99  # (its own group, so _note_group keeps it mixed)
	klass.ring(d, bell, 10.0)
	_check(int(d.get_meta(klass.PIPS_META)) == klass.DEEP_PIPS, "Deep Tone: a rank III bell's hit fills %d pips" % klass.DEEP_PIPS)
	bell.rank = 4
	var dt = _spawn(spot + Vector2(0, CELL * 1.5))
	dt.set_meta(klass.GROUP_META, -1)
	dt.set_meta(klass.PIPS_META, klass.TOLL_EVERY - 1)
	_ready_to_ring(dt)
	tolls0 = klass.tolls
	klass.ring(dt, bell, 10.0)
	_check(klass.tolls == tolls0 + 1 and int(dt.get_meta(klass.PIPS_META)) == klass.DOUBLE_PIPS, "Double Time: a rank IV Toll leaves %d rings" % klass.DOUBLE_PIPS)
	other_group.queue_free()
	await _clean()

	# Midnight Bell (old: Poisoned / Charged / Soaked paid out too): only the bell's triple
	bell = _plant("bellflower", spot)
	var spore := _plant("sporeling", spot + Vector2(CELL * 6, 0))
	await _frames(2)
	_path([&"kt_evo_steady_beat", &"kt_evo_crescendo", &"kt_evo_midnight_bell"])
	var plain = _spawn(spot + Vector2(0, CELL))
	var poisoned = _spawn(spot + Vector2(0, CELL * 1.5))
	spore._apply_one_status(poisoned, EnemyStatuses.SPORED, 10, spore.get_damage())
	var p0: float = plain.health
	var q0: float = poisoned.health
	klass._midnight(plain, bell)
	klass._midnight(poisoned, bell)
	_check(p0 - plain.health > 0.0 and absf((q0 - poisoned.health) - (p0 - plain.health)) <= 2.0,
		"Midnight Bell: a Poisoned nightmare takes the same Midnight (status payoffs gone: %.0f vs %.0f)" % [q0 - poisoned.health, p0 - plain.health])

	# Twelfth Hour: a Midnight sets off up to TWELFTH_OTHERS others in the bell's range with TWELFTH_RINGS rings
	_path([&"kt_evo_steady_beat", &"kt_evo_crescendo", &"kt_evo_midnight_bell", &"kt_evo_twelfth_hour"])
	var first = _spawn(spot + Vector2(0, CELL))
	var crowd: Array = []
	for k in klass.TWELFTH_OTHERS + 1:
		var c = _spawn(spot + Vector2(CELL * 0.2 * k, CELL))
		c.set_meta(klass.RINGS_META, klass.TWELFTH_RINGS)
		crowd.append(c)
	var short = _spawn(spot + Vector2(0, CELL * 0.8))
	short.set_meta(klass.RINGS_META, klass.TWELFTH_RINGS - 1)
	klass._later.clear()
	klass._midnight(first, bell)
	var queued: int = klass._later.filter(func(row) -> bool: return bool(row.get("midnight", false))).size()
	_check(queued == klass.TWELFTH_OTHERS and klass.TWELFTH_OTHERS == 3, "Twelfth Hour: %d others strike their Midnight (%d)" % [klass.TWELFTH_OTHERS, queued])
	_check(not short.has_meta(klass.MIDNIGHT_META), "...not one with fewer than %d rings" % klass.TWELFTH_RINGS)
	klass._later.clear()
	await _clean()

	# Accompaniment (old: the partner struck the Toll and its status came again): the bell's Toll + a damage-only repeat
	bell = _plant("bellflower", spot)
	var partner := _plant("sporeling", spot + Vector2(CELL, 0))
	var bell_b := _plant("bellflower", spot + Vector2(CELL * 3, 0))
	await _frames(2)
	_path([&"kt_evo_accompaniment", &"kt_evo_counterpoint"])
	var a = _spawn(spot + Vector2(0, CELL))
	a.set_meta(klass.PIPS_META, klass.TOLL_EVERY - 1)
	_ready_to_ring(a)
	klass._last_hit_of[partner.get_instance_id()] = 50.0
	var a0: float = a.health
	tolls0 = klass.tolls
	klass.ring(a, bell, klass._bell_base(bell), true, partner)
	_check(klass.tolls == tolls0 + 1 and a.health < a0, "Accompaniment: the partner's ring makes the bell's Toll")
	_check(not a.statuses.has(EnemyStatuses.SPORED), "...and its status never comes again (old calling_apply gone)")
	# Counterpoint (old: the nearest bell answered with a free hit): no other bell strikes
	_check(not bell_b.has_meta(klass.FREE_META), "Counterpoint: no bell answers with a free hit (old branch gone)")
	_check(dreams.calling_keeps_out(load("res://resource/dream/in_time.tres")) and dreams.calling_keeps_out(load("res://resource/dream/refrain.tres")),
		"Accompaniment keeps In Time and Refrain out of the offers")
	# Tenor Bell: a slow form repeats in full
	_path([&"kt_evo_accompaniment", &"kt_evo_tenor_bell"])
	var slow: bool = partner.attack_data.attacks_per_second <= klass.TENOR_RATE
	var t = _spawn(spot + Vector2(0, CELL * 1.5))
	var t0: float = t.health
	var dealt: float = klass._repeat(partner, t, klass.EVO_ACCOMP, klass.ACCOMP_SHARE)
	var full_hit: float = minf(50.0, klass.second_of(partner))
	_check(is_equal_approx(dealt, full_hit if slow else full_hit * klass.ACCOMP_SHARE) and t.health < t0,
		"Tenor Bell: %s (%.1f of %.1f)" % ["a slow form repeats in full" if slow else "a fast form repeats at half", dealt, full_hit])
	await _clean()

	# Symphony (now a Calling hit, never armed) and Coda
	bell = _plant("bellflower", spot)
	await _frames(2)
	_path([&"kt_evo_accompaniment", &"kt_evo_counterpoint", &"kt_evo_symphony", &"kt_evo_coda"])
	var roster: Array = []
	var singers: Array = []
	for k in klass.SYMPHONY_WARDENS:
		var w := _plant("sprout", spot + Vector2(CELL * (k - 1), CELL * 2))
		klass._last_hit_of[w.get_instance_id()] = 20.0
		roster.append([w.get_instance_id(), true])
		singers.append(w)
	var y = _spawn(spot + Vector2(0, CELL))
	var y0: float = y.health
	klass._symphony(y, roster, y.global_position)
	_check(y.health < y0 and DamageLog.calling_next == &"" and DamageLog.calling_now == &"", "Symphony: the repeats land, never armed")
	_check(singers.all(func(w) -> bool: return w.has_meta(klass.CODA_META)), "Coda: each Warden in the Symphony keeps its note")
	var z = _spawn(spot + Vector2(0, CELL * 1.5))
	var z0: float = z.health
	klass._coda(singers[0], z, 20.0)
	_check(z.health < z0 and not singers[0].has_meta(klass.CODA_META), "...its next hit lands again, once")
	_check(dreams.calling_keeps_out(load("res://resource/dream/rude_awakening.tres")) and dreams.calling_keeps_out(load("res://resource/dream/refrain.tres")),
		"Symphony keeps Rude Awakening out, Coda Refrain")
	await _clean()

	# Down the Line: a Toll primes the walker behind it; that one's next ring counts 2
	bell = _plant("bellflower", spot)
	await _frames(2)
	_path([&"kt_evo_carrying_tune", &"kt_evo_humming_walls", &"kt_evo_down_the_line"])
	var lead = _spawn(route[24])
	var behind = _spawn(route[22])
	var i_lead: int = klass.index_of(lead)
	var i_behind: int = klass.index_of(behind)
	if i_lead >= 0 and i_behind >= 0 and i_lead - i_behind <= klass.PRIME_STEPS * 2 and i_behind < i_lead:
		klass._prime(lead, lead.global_position, {})
		_check((behind.get_meta(klass.PRIMED_META, {}) as Dictionary).get(klass.BACK, 0) == 1, "Down the Line: the walker behind is primed")
		behind.set_meta(klass.PIPS_META, 0)
		_ready_to_ring(behind)
		klass.ring(behind, bell, 10.0)
		_check(int(behind.get_meta(klass.PIPS_META)) == 2 and not behind.has_meta(klass.PRIMED_META), "...its next ring counts 2")
	# Humming Walls: each WALL_STEPS steps beside walls fills one pip, once between Tolls
	var walker = _spawn(route[12])
	klass._wall_side.clear()
	for k in 30:
		klass._wall_side[k] = true
	walker.set_meta(klass.WALL_SEEN_META, 0)
	walker.set_meta(klass.WALL_LAPS_META, int(walker.laps))
	walker.set_meta(klass.PIPS_META, 0)
	if klass.index_of(walker) >= klass.WALL_STEPS * 2:
		klass._walk_walls(walker)
		_check(int(walker.get_meta(klass.PIPS_META)) == 1 and walker.has_meta(klass.WALL_DONE_META), "Humming Walls: %d wall-side steps fill a pip" % klass.WALL_STEPS)
		walker.global_position = route[mini(28, route.size() - 1)]
		klass._walk_walls(walker)
		_check(int(walker.get_meta(klass.PIPS_META)) == 1, "...once between its Tolls")
	await _clean()
	dreams.calling_path.clear()
	dreams._rebuild_calling_flags()

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

	# Knell (hard cards 2026-10-16; owner 2026-10-18, bell_lent_review.md): a bell's hit lands again once per status on the
	# nightmare (its own too, never Rooted), up to 3, 0.2 s apart, each adding 1 of the bell's status; once per nightmare
	# every 6 s. Repeats never advance In Time.
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
	_check(klass._later.size() == 2, "Knell: Poisoned and the bell's own Drowsy queue 2 repeats (%d)" % klass._later.size())
	var in_time_count := int(k.get_meta(klass.IN_TIME_META, {}).get(k_bell.get_instance_id(), 0))
	var k_health: float = k.health
	var drowsy: int = k.statuses.stacks(EnemyStatuses.DROWSY)
	for i in 120:
		if klass._later.is_empty():
			break
		await process_frame
	_check(klass._later.is_empty() and k.health < k_health, "...the hit lands again, %.1f s apart" % klass.KNELL_REPEAT_GAP)
	_check(k.statuses.stacks(EnemyStatuses.DROWSY) > drowsy, "...and adds the bell's Drowsy (%d -> %d)" % [drowsy, k.statuses.stacks(EnemyStatuses.DROWSY)])
	_check(k.statuses.stacks(EnemyStatuses.SPORED) >= poisoned, "...nothing is used up")
	_check(int(k.get_meta(klass.IN_TIME_META, {}).get(k_bell.get_instance_id(), 0)) == in_time_count, "...a repeat never counts for In Time")
	await process_frame
	k_bell.hit(k, 1.0, false, Tower.NO_CRIT)
	_check(klass._later.is_empty(), "...once per nightmare every %d s" % int(klass.KNELL_EVERY))
	dreams.stacks.erase("in_time")
	dreams.calling = "bellflower"
	await _clean()

	# Knell alone (owner 2026-10-18, bell_lent_review.md): a lone bell's own status counts, even before its hit's lands.
	dreams.stacks.clear()
	_take("knell")
	var kl_bell := _plant("bellflower", spot)
	await _frames(2)
	var kl = _spawn(spot + Vector2(CELL, 0))
	klass._later.clear()
	kl_bell.hit(kl, 1.0, false, Tower.NO_CRIT)
	_check(klass._later.size() == 1, "Knell alone: the bell's own Drowsy counts, 1 repeat (%d)" % klass._later.size())
	var kl_root = _spawn(spot + Vector2(CELL, CELL * 0.5))
	kl_root.apply_status(EnemyStatuses.HELD, 1, 1.0, 1.0, 0, "root", null)
	klass._later.clear()
	kl_bell.hit(kl_root, 1.0, false, Tower.NO_CRIT)
	_check(klass._later.size() == 1, "...Rooted never counts (%d)" % klass._later.size())
	klass._later.clear()
	await _clean()

	# Second Verse (owner 2026-10-18, bell_lent_review.md): leaving a bell's range, the last status another Warden gave the
	# nightmare lands again; other bells count, so Bellflower alone works with two bells. The leaving bell's own never.
	dreams.stacks.clear()
	_take("second_verse")
	var sv_bell := _plant("bellflower", spot)
	var sv_other := _plant("bellflower", spot + Vector2(CELL * 6, 0))
	await _frames(2)
	var sv = _spawn(spot + Vector2(CELL, 0))
	sv_bell.hit(sv, 1.0, false, Tower.NO_CRIT)
	await process_frame
	var sv_alone = _spawn(spot + Vector2(CELL, CELL * 0.5))
	sv_bell.hit(sv_alone, 1.0, false, Tower.NO_CRIT)
	await process_frame
	sv_other._apply_one_status(sv, EnemyStatuses.DROWSY, 2, sv_other.get_damage())
	for i in 3:
		sv_bell._apply_one_status(sv, EnemyStatuses.DROWSY, 1, sv_bell.get_damage())  # The leaving bell's own hits never hide it
	var sv_drowsy: int = sv.statuses.stacks(EnemyStatuses.DROWSY)
	klass._second_verse(sv, sv_bell)
	_check(sv.statuses.stacks(EnemyStatuses.DROWSY) == sv_drowsy + 2, "Second Verse: another bell's Drowsy x2 lands again (%d -> %d)" % [sv_drowsy, sv.statuses.stacks(EnemyStatuses.DROWSY)])
	var sv_again: int = sv.statuses.stacks(EnemyStatuses.DROWSY)
	klass._second_verse(sv, sv_bell)
	_check(sv.statuses.stacks(EnemyStatuses.DROWSY) == sv_again, "...once for each bell and nightmare")
	var alone_drowsy: int = sv_alone.statuses.stacks(EnemyStatuses.DROWSY)
	klass._second_verse(sv_alone, sv_bell)
	_check(sv_alone.statuses.stacks(EnemyStatuses.DROWSY) == alone_drowsy, "...only that bell's own status: nothing lands again")
	await _clean()

	# Da Capo (owner 2026-10-18, bell_lent_review.md): every DA_CAPO_EVERY s of drift time, a bell's next attack happens
	# twice (its wait is reset), never more often than every DA_CAPO_MIN_ATTACKS of its own attacks; the clock runs only
	# during a drift and starts over at a rest. Nothing repeats a repeat (In Time, Refrain, Knell held too).
	dreams.stacks.clear()
	_take("da_capo")
	var dc_bell := _plant("bellflower", spot)
	await _frames(2)
	var dc = _spawn(spot + Vector2(CELL, 0))
	var director = dreams.drift_director
	var was_resting: bool = director.resting
	director.resting = true
	var clock0: float = klass._drift_clock
	await _frames(10)
	_check(is_equal_approx(klass._drift_clock, clock0), "Da Capo: the clock stands still at a rest")
	dc_bell._cooldown = 5.0
	dc_bell.hit(dc, 1.0, false, Tower.NO_CRIT)
	_check(klass._da_capo_due.is_empty() and is_equal_approx(dc_bell._cooldown, 5.0), "...and a bell's hit at a rest starts nothing")
	director.resting = false
	await _frames(10)
	_check(klass._drift_clock > clock0, "...it runs during a drift")
	dc_bell.hit(dc, 1.0, false, Tower.NO_CRIT)
	_check(klass._da_capo_due.has(dc_bell.get_instance_id()) and is_equal_approx(dc_bell._cooldown, 5.0), "...the bell's first attack starts its clock")
	var wait: float = maxf(klass.DA_CAPO_EVERY, klass.DA_CAPO_MIN_ATTACKS / maxf(dc_bell.get_attacks_per_second(), 0.01))
	klass._drift_clock = float(klass._da_capo_due[dc_bell.get_instance_id()])
	dc_bell.hit(dc, 1.0, false, Tower.NO_CRIT)
	_check(is_equal_approx(dc_bell._cooldown, 0.0), "...when it is due, the bell's next attack comes at once")
	_check(is_equal_approx(float(klass._da_capo_due[dc_bell.get_instance_id()]) - klass._drift_clock, wait), "...next due in %.1f s" % wait)
	dc_bell._cooldown = 5.0
	dc_bell.hit(dc, 1.0, false, Tower.NO_CRIT)
	_check(is_equal_approx(dc_bell._cooldown, 5.0), "...and not again before then")
	var slow := 0.1  # A slow bell's 3 attacks take longer than 6 s
	_check(maxf(klass.DA_CAPO_EVERY, klass.DA_CAPO_MIN_ATTACKS / slow) > klass.DA_CAPO_EVERY, "(a slow bell waits for its 3 attacks)")
	# No repeat of a repeat: Da Capo's third hit is gone; a repeated hit never sets Da Capo or another repeat off.
	_take("in_time")
	_take("refrain")
	_take("knell")
	klass._later.clear()
	klass._drift_clock = float(klass._da_capo_due[dc_bell.get_instance_id()]) + 1.0
	var due_before: float = float(klass._da_capo_due[dc_bell.get_instance_id()])
	klass._again(dc_bell, dc, 5.0, &"refrain")
	klass._again(dc_bell, dc, 5.0, &"knell", &"none")
	_check(klass._later.is_empty(), "no repeat of a repeat: a repeated hit queues nothing (%d)" % klass._later.size())
	_check(is_equal_approx(dc_bell._cooldown, 5.0) and is_equal_approx(float(klass._da_capo_due[dc_bell.get_instance_id()]), due_before),
		"...and never sets Da Capo off")
	klass.on_rest()
	_check(klass._da_capo_due.is_empty(), "Da Capo: every bell's clock starts over at a rest")
	director.resting = was_resting
	dreams.stacks.clear()
	await _clean()

	# Chime of Many (owner 2026-10-17: Bellflower's own trait, Repeats; was +1 stack): a Toll repeats the nightmare's last
	# status hit (that Warden's status and stacks) on up to CHIME_OTHERS nightmares touching it; never Drowsy.
	dreams.stacks.clear()
	dreams.calling_path.clear()
	dreams.calling_path.append(&"kt_evo_accompaniment")
	dreams.calling_path.append(&"kt_evo_chime_of_many")
	_plant("bellflower", at + Vector2(CELL, 0))
	var c_spore := _plant("sporeling", at + Vector2(-CELL, 0))
	var c_bell := _plant("bellflower", at + Vector2(CELL * 6, 0))
	await _frames(2)
	klass.on_board()
	var x = _spawn(at)
	var near_a = _spawn(at + Vector2(CELL * 0.5, 0))
	var near_b = _spawn(at + Vector2(0, CELL * 0.5))
	var away = _spawn(at + Vector2(CELL * 3, 0))
	c_spore._apply_one_status(x, EnemyStatuses.SPORED, 2, c_spore.get_damage())
	c_bell._apply_one_status(x, EnemyStatuses.DROWSY, 1, c_bell.get_damage())  # A later Drowsy hit is never the one repeated
	_check(x.has_meta(klass.CHIME_META) and StringName(x.get_meta(klass.CHIME_META)[1]) == EnemyStatuses.SPORED, "Chime of Many remembers the last status hit (never Drowsy)")
	klass._chime(x, x.global_position)
	_check(near_a.statuses.stacks(EnemyStatuses.SPORED) == 2 and near_b.statuses.stacks(EnemyStatuses.SPORED) == 2,
		"Chime of Many: the Toll repeats Poisoned x2 on the nightmares touching it")
	_check(not away.statuses.has(EnemyStatuses.SPORED), "...not on one further away")
	_check(not near_a.statuses.has(EnemyStatuses.DROWSY), "...and never repeats Drowsy")
	dreams.calling_path.clear()
	await _clean()
	await _evolution_checks(spot)
	await _f1_checks(at, spot)
	print("test_class_bellflower: %d failures" % failures)
	quit(failures)
