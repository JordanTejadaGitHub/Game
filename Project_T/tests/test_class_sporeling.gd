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
const LENT := ["mycelium", "overnight", "pass_it_round", "spore_ring", "seeping_in", "mixed_company", "breathe_it_in",
	"gone_to_seed"]  # Card pass 2026-10-16: Sitting Ducks into Breathe It In, Hemmed In retired

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
	klass = dreams.spore_print

# F1 lent × Calling, F7 and F9 (owner 2026-10-18; D:\Projects\logs\dream_council\f1_spec.md, lent_evolution_builds.md).
func _f1_checks(far: Vector2, route: Array) -> void:
	# F1: a dose is the spore Warden's application for ANOTHER family's lent card (Second Verse remembers it), never for
	# Sporeling's own stack cards
	dreams.stacks.clear()
	dreams.calling = "sporeling"
	dreams.calling_path.clear()
	_take("breathe_it_in")
	_take("second_verse")
	var spore := _plant("sporeling", far)
	await _frames(2)
	var own = _spawn(far + Vector2(CELL, 0))  # Inside the spore Warden's range
	klass._apply_dose(spore, own, klass.DOSE)
	_check(own.statuses.stacks(EnemyStatuses.SPORED) == klass.DOSE, "F1: a dose never counts for Sporeling's own stack cards (%d)" % own.statuses.stacks(EnemyStatuses.SPORED))
	_check(dreams._calling_apply == "", "F1: the dose's mark is taken on entry")
	var verse: Array = own.get_meta(dreams.keeping_time.LAST_OTHER_META, [])
	_check(verse.any(func(row) -> bool: return row is Array and StringName(row[0]) == EnemyStatuses.SPORED and int(row[2]) == spore.get_instance_id()),
		"F1: the dose counts as the spore Warden's application for Second Verse (Bellflower)")
	dreams.calling = "dewdrop"  # A later owner: no Calling of its own
	var later = _spawn(far + Vector2(CELL, CELL))
	klass._apply_dose(spore, later, klass.DOSE)
	_check(not later.has_meta(dreams.keeping_time.LAST_OTHER_META), "...only while Spore Print is the Calling")
	await _clean()

	# F7: Settling Spores follows the walker: for 12 steps after a spore Warden's hit, every 6 steps each status gains 3
	dreams.stacks.clear()
	dreams.calling = "firefly_jar"
	_take("seeping_in")
	_check(load("res://resource/dream/seeping_in.tres").description.begins_with("For 12 {steps} after a spore Warden hits"), "F7: the new face")
	var start := 8
	if route.size() > start + 40:
		var ss := _plant("sporeling", route[start] + Vector2(CELL, 0))
		await _frames(2)
		var w = _spawn(route[start])
		w.apply_status(EnemyStatuses.DAMP, 1, 60.0, 1.0, 0, "water", null)
		_check(not w.has_meta(klass.SEEP_META), "(nothing before a spore Warden hits it)")
		ss.hit(w, 1.0, false, Tower.NO_CRIT)
		_check(w.has_meta(klass.SEEP_META), "F7: a spore Warden's hit starts the window")
		var d0: int = w.statuses.stacks(EnemyStatuses.DAMP)
		w.global_position = route[start + int(klass.SEEP_STEPS) * 2]
		klass._seep(w)
		_check(w.statuses.stacks(EnemyStatuses.DAMP) == d0 + klass.SEEP_STACKS, "F7: 6 steps on, anywhere on the path, Soaked gains %d" % klass.SEEP_STACKS)
		w.global_position = route[start + int(klass.SEEP_WINDOW) * 2]
		klass._seep(w)
		_check(w.statuses.stacks(EnemyStatuses.DAMP) == d0 + 2 * klass.SEEP_STACKS and not w.has_meta(klass.SEEP_META), "...12 steps on, once more, and the window ends")
		w.global_position = route[start + int(klass.SEEP_WINDOW) * 2 + 12]
		klass._seep(w)
		_check(w.statuses.stacks(EnemyStatuses.DAMP) == d0 + 2 * klass.SEEP_STACKS, "...nothing past 12 steps")
		await _clean()

	# F9: Gone to Seed also pays when a Warden's stamped application sets off a Reaction near a spore Warden
	dreams.stacks.clear()
	_take("gone_to_seed")
	_check(load("res://resource/dream/gone_to_seed.tres").description.contains("or sets off a {reaction}"), "F9: the new face")
	var g_spore := _plant("sporeling", far)
	await _frames(2)
	var gs = _spawn(far + Vector2(CELL, 0))
	gs.apply_status(EnemyStatuses.DAMP, 1, 20.0, 1.0, 0, "water", null)
	gs.set_meta(klass.SEED_BEFORE_META, [EnemyStatuses.SPORED, 0, Engine.get_process_frames()])
	klass._seed_reaction(&"mushrooming", gs, 1, [])
	await process_frame
	_check(gs.statuses.stacks(EnemyStatuses.DAMP) == 1 + klass.SEED_STACKS, "F9: a Reaction set off by a stamped application: each status left gains %d" % klass.SEED_STACKS)
	gs.set_meta(klass.SEED_BEFORE_META, [EnemyStatuses.SPORED, 0, Engine.get_process_frames()])
	klass._seed_reaction(&"mushrooming", gs, 1, [])
	await process_frame
	_check(gs.statuses.stacks(EnemyStatuses.DAMP) == 1 + klass.SEED_STACKS, "...once per nightmare in %d s" % int(klass.SEED_EVERY))
	var stale = _spawn(far + Vector2(CELL, CELL))
	stale.apply_status(EnemyStatuses.DAMP, 1, 20.0, 1.0, 0, "water", null)
	stale.set_meta(klass.SEED_BEFORE_META, [EnemyStatuses.SPORED, 0, Engine.get_process_frames() - 1])
	klass._seed_reaction(&"mushrooming", stale, 1, [])
	await process_frame
	_check(stale.statuses.stacks(EnemyStatuses.DAMP) == 1, "...a Reaction no application set off this frame: nothing")
	_check(g_spore != null, "(the spore Warden stands near)")
	await _clean()
	dreams.stacks.clear()

func _run() -> void:
	await _setup()
	_check(klass != null and DreamState.CALLINGS.title("sporeling") == "Spore Print", "Sporeling's Calling is Spore Print")
	dreams.calling = "firefly_jar"
	_check_pool("sporeling", LENT, 0)  # No class cards: the Calling evolves instead (owner 2026-10-16; calling_paths.gd)
	dreams.calling = "sporeling"
	_check_pool("sporeling", LENT, 0)
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

	# A later owner (owner 2026-10-14, dream_council_review.md 25-26): lent cards never give mushrooms or doses.
	dreams.calling = "firefly_jar"
	dreams.stacks.clear()
	for id in LENT:
		_take(id)
	klass.mushrooms.clear()
	var q: Vector2 = route[8]
	var s1 := _plant("sporeling", q + Vector2(CELL, 0))
	var killer := _plant("sprout", q + Vector2(CELL * 4, CELL * 4))
	await _frames(3)
	_check(klass.active() and not klass.place_on(), "a later owner holding every lent card: the node wakes, the setup stays off")
	var g = _spawn(q)
	g.apply_status(EnemyStatuses.SPORED, 1, 5.0, 1.0, 0, "spore", s1)
	g.health = 1
	killer.hit(g, 1.0, false, Tower.NO_CRIT)
	await _frames(2)
	_check(klass.mushrooms.is_empty() and klass._regrow.is_empty(), "...a Poisoned dispel leaves no mushroom on a later start")
	await _clean()

	# Each stack card on its own (only that card held), on a later start.
	var far := Vector2(CELL * 30, CELL * 30)  # Away from the route: nothing else touches these nightmares
	dreams.stacks.clear()
	# Breathe It In (trait rework 2026-10-15): any Warden's status landing inside a spore Warden's range, the spore
	# Warden's own included, adds BREATHE_ONE more; once a second per Warden.
	_take("breathe_it_in")
	var b1 := _plant("sporeling", far)
	var b_drop := _plant("dewdrop", far + Vector2(CELL * 6, 0))  # Not touching: only the nightmare's place counts
	var h = _spawn(far + Vector2(CELL, 0))
	b_drop._apply_one_status(h, EnemyStatuses.DAMP, 1, b_drop.get_damage())
	_check(h.statuses.stacks(EnemyStatuses.DAMP) == 1 + klass.BREATHE_ONE, "Breathe It In: another family's 1-stack Soaked inside a spore Warden's range lands %d" % (1 + klass.BREATHE_ONE))
	b_drop._apply_one_status(h, EnemyStatuses.DAMP, 1, b_drop.get_damage())
	_check(h.statuses.stacks(EnemyStatuses.DAMP) == 2 + klass.BREATHE_ONE, "...once a second per Warden")
	b1._apply_one_status(h, EnemyStatuses.SPORED, 1, b1.get_damage())
	_check(h.statuses.stacks(EnemyStatuses.SPORED) == 1 + klass.BREATHE_ONE, "...the spore Warden's own Poisoned counts too")
	b_drop.remove_meta(klass.BREATHE_META)
	var h_out = _spawn(far + Vector2(CELL * 14, CELL * 14))  # Outside every spore Warden's range
	b_drop._apply_one_status(h_out, EnemyStatuses.DAMP, 1, b_drop.get_damage())
	_check(h_out.statuses.stacks(EnemyStatuses.DAMP) == 1, "...outside a spore Warden's range: nothing extra")
	await _clean()

	dreams.stacks.clear()
	_take("hemmed_in")
	var left_spore := _plant("sporeling", far)
	var drop := _plant("dewdrop", far + Vector2(CELL, 0))
	var right_spore := _plant("sporeling", far + Vector2(CELL * 2, 0))
	var k = _spawn(far + Vector2(CELL, CELL))
	drop._apply_one_status(k, EnemyStatuses.DAMP, 1, drop.get_damage())
	_check(k.statuses.stacks(EnemyStatuses.DAMP) == 2, "Hemmed In: a Dewdrop touching two spore Wardens doubles its Soaked (%d)" % k.statuses.stacks(EnemyStatuses.DAMP))
	right_spore.queue_free()
	await process_frame
	var k2 = _spawn(far + Vector2(CELL, CELL))
	drop._apply_one_status(k2, EnemyStatuses.DAMP, 1, drop.get_damage())
	_check(k2.statuses.stacks(EnemyStatuses.DAMP) == 1, "...touching only one: nothing extra")
	left_spore.queue_free()
	await _clean()

	dreams.stacks.clear()
	_take("sitting_ducks")
	var duck_spore := _plant("sporeling", far)
	var duck_drop := _plant("dewdrop", far + Vector2(CELL * 4, 0))
	var held = _spawn(far + Vector2(CELL, CELL))
	var walking = _spawn(far + Vector2(CELL, CELL))
	held.apply_status(EnemyStatuses.HELD, 1, 3.0, 1.0, 0, "root", null)
	duck_drop._apply_one_status(held, EnemyStatuses.DAMP, 1, duck_drop.get_damage())
	duck_drop.remove_meta(klass.DUCKS_META)
	duck_drop._apply_one_status(walking, EnemyStatuses.DAMP, 1, duck_drop.get_damage())
	_check(held.statuses.stacks(EnemyStatuses.DAMP) == 1 + klass.DUCKS_EXTRA and walking.statuses.stacks(EnemyStatuses.DAMP) == 1,
		"Sitting Ducks: a held nightmare near a spore Warden takes %d, a walking one 1" % (1 + klass.DUCKS_EXTRA))
	_check(duck_spore != null, "(the spore Warden stands near)")
	await _clean()

	# (Second Helping is retired, 2026-10-15.)
	# Pass It Round (trait rework): a Warden touching a spore Warden, or a spore Warden itself, adds PASS_STACKS more with
	# its first application on each nightmare.
	dreams.stacks.clear()
	_take("pass_it_round")
	var p_spore := _plant("sporeling", far)
	var p_drop := _plant("dewdrop", far + Vector2(CELL, 0))
	var p_lone := _plant("dewdrop", far + Vector2(CELL * 6, 0))
	var p = _spawn(far + Vector2(CELL, CELL))
	p_drop._apply_one_status(p, EnemyStatuses.DAMP, 1, p_drop.get_damage())
	_check(p.statuses.stacks(EnemyStatuses.DAMP) == 1 + klass.PASS_STACKS, "Pass It Round: a Dewdrop touching a spore Warden: its first Soaked lands %d" % (1 + klass.PASS_STACKS))
	p_drop._apply_one_status(p, EnemyStatuses.DAMP, 1, p_drop.get_damage())
	_check(p.statuses.stacks(EnemyStatuses.DAMP) == 2 + klass.PASS_STACKS, "...only the first application on each nightmare")
	var p2 = _spawn(far + Vector2(CELL * 6, CELL))
	p_lone._apply_one_status(p2, EnemyStatuses.DAMP, 1, p_lone.get_damage())
	_check(p2.statuses.stacks(EnemyStatuses.DAMP) == 1, "...a Warden touching no spore Warden: nothing extra")
	p_spore._apply_one_status(p2, EnemyStatuses.SPORED, 1, p_spore.get_damage())
	_check(p2.statuses.stacks(EnemyStatuses.SPORED) == 1 + klass.PASS_STACKS, "...a spore Warden touches itself")
	await _clean()

	# Mycelium (trait rework): a Sprout touching a spore Warden: its hit adds 1, quietly, to every other status on the nightmare.
	dreams.stacks.clear()
	_take("mycelium")
	_plant("sporeling", far)
	var my_sprout := _plant("sprout", far + Vector2(CELL, 0))
	var my_drop := _plant("dewdrop", far + Vector2(CELL * 6, 0))
	await _frames(2)
	var my = _spawn(far + Vector2(CELL, CELL))
	my_drop._apply_one_status(my, EnemyStatuses.DAMP, 1, my_drop.get_damage())
	my_sprout.hit(my, 1.0, false, Tower.NO_CRIT)
	await _frames(1)
	_check(my.statuses.stacks(EnemyStatuses.DAMP) == 2, "Mycelium: a Sprout touching a spore Warden adds 1 Soaked with its hit (%d)" % my.statuses.stacks(EnemyStatuses.DAMP))
	await _clean()

	# Overnight (trait rework): a spore Warden's hit adds OVERNIGHT_FEED to each status other families put on the nightmare;
	# once a second for each spore Warden and nightmare.
	dreams.stacks.clear()
	_take("overnight")
	var o_spore := _plant("sporeling", far)
	var o_drop := _plant("dewdrop", far + Vector2(CELL * 6, 0))
	await _frames(2)
	var o = _spawn(far + Vector2(CELL, 0))
	o_drop._apply_one_status(o, EnemyStatuses.DAMP, 1, o_drop.get_damage())
	o_spore.hit(o, 1.0, false, Tower.NO_CRIT)
	await _frames(1)
	_check(o.statuses.stacks(EnemyStatuses.DAMP) == 1 + klass.OVERNIGHT_FEED, "Overnight: the spore Warden's hit adds %d to the Dewdrop's Soaked" % klass.OVERNIGHT_FEED)
	o_spore.hit(o, 1.0, false, Tower.NO_CRIT)
	await _frames(1)
	_check(o.statuses.stacks(EnemyStatuses.DAMP) == 1 + klass.OVERNIGHT_FEED, "...once a second")
	await _clean()

	# Gone to Seed (new 2026-10-15): a Warden's status filling on a nightmare near a spore Warden: every other status gains
	# SEED_STACKS, quietly; once per nightmare in SEED_EVERY s.
	dreams.stacks.clear()
	_take("gone_to_seed")
	var g_spore := _plant("sporeling", far)
	var g_drop := _plant("dewdrop", far + Vector2(CELL * 6, 0))
	var sd = _spawn(far + Vector2(CELL, 0))
	g_spore._apply_one_status(sd, EnemyStatuses.SPORED, 1, g_spore.get_damage())
	var full: int = sd.statuses.get_max_stacks(EnemyStatuses.DAMP)
	g_drop._apply_one_status(sd, EnemyStatuses.DAMP, full - 1, g_drop.get_damage())
	_check(sd.statuses.stacks(EnemyStatuses.SPORED) == 1, "Gone to Seed: nothing before a status fills")
	g_drop._apply_one_status(sd, EnemyStatuses.DAMP, 1, g_drop.get_damage())
	_check(sd.statuses.stacks(EnemyStatuses.SPORED) == 1 + klass.SEED_STACKS, "...Soaked fills near a spore Warden: Poisoned gains %d" % klass.SEED_STACKS)
	g_drop._apply_one_status(sd, EnemyStatuses.DAMP, 1, g_drop.get_damage())
	_check(sd.statuses.stacks(EnemyStatuses.SPORED) == 1 + klass.SEED_STACKS, "...once per nightmare in %d s" % int(klass.SEED_EVERY))
	var bare = _spawn(far + Vector2(CELL * 8, CELL * 8))  # Not near a spore Warden
	g_spore._apply_one_status(bare, EnemyStatuses.SPORED, 1, g_spore.get_damage())
	g_drop._apply_one_status(bare, EnemyStatuses.DAMP, full, g_drop.get_damage())
	_check(bare.statuses.stacks(EnemyStatuses.SPORED) == 1, "...far from any spore Warden: nothing")
	_check(g_spore != null, "(the spore Warden stands near the first)")
	await _clean()
	await _f1_checks(far, route)
	print("test_class_sporeling: %d failures" % failures)
	quit(failures)
