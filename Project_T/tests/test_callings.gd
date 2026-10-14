extends SceneTree
# Callings (documentation/dream_council_review.md 11): the first family's built-in rule.
var failures := 0
var main: Node
var spawner
var placer: TowerPlacer
var container: Node
var dreams: DreamState
const CELL := 64.0
const CALLINGS := preload("res://scripts/combat/callings.gd")

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

	# The first pick sets it; nothing changes it afterwards; unknown ids are ignored; it is saved.
	_check(dreams.calling == "", "a run starts with no Calling")
	dreams.set_calling("thornwall")
	_check(dreams.calling == "", "a Warden that is no family root brings no Calling")
	dreams.set_calling("sporeling")
	dreams.set_calling("dewdrop")
	_check(dreams.calling == "sporeling", "only the first family brings its Calling")
	_check(dreams.calling_title() == "Spore Print" and dreams.calling_text() != "", "the Calling has a name and a rule text")
	var saved: Dictionary = dreams.to_save()
	dreams.calling = ""
	dreams.load_save(saved)
	_check(dreams.calling == "sporeling", "the Calling survives a save and load")
	for family in CALLINGS.LINES:
		_check(CALLINGS.title(family) != "" and CALLINGS.text(family) != "", "%s has a Calling name and text" % family)
		_check(ResourceLoader.exists("res://resource/tower/%s.tres" % family), "%s is a Warden" % family)

	# (Take Root and Splashback, the first Sporeling and Dewdrop Callings, are retired: Spore Print and Puddles are
	# tested in test_class_sporeling.gd and test_class_dewdrop.gd.)
	var spore := _plant("sporeling", Vector2(2, 2))
	var sprout := _plant("sprout", Vector2(3, 2))
	var a: Node2D
	var b: Node2D
	var far: Node2D
	var b_health := 0

	# Lantern Light (the Firefly class prototype, dream_council_review.md 20; it replaced Lantern Ring): nightmares in a
	# Firefly Warden's glow are Lit, and any Warden's dispel of a Lit nightmare forks half its hit to the nearest Lit one.
	dreams.calling = "firefly_jar"
	var jar := _plant("firefly_jar", Vector2(6, 2))
	dreams.bump_board()
	var lights = dreams.firefly_lights
	await process_frame
	await process_frame
	a = _spawn(jar.global_position + Vector2(40, 0))
	b = _spawn(jar.global_position + Vector2(80, 0))
	far = _spawn(Vector2(1200, 1000))
	_check(lights != null and lights.is_lit(a) and lights.is_lit(b) and not lights.is_lit(far), "Lantern Light: nightmares in the Jar's glow are Lit")
	sprout.hit(a, 1.0, false, Tower.NO_CRIT)
	_check(a.statuses.stacks(EnemyStatuses.STATIC) == 0, "Lantern Ring is gone: another Warden's hit in the glow adds no Charged")
	var thrown: int = lights.forks_thrown
	b_health = b.health
	a.health = 1
	sprout.hit(a, 1.0, false, Tower.NO_CRIT)  # The Sprout dispels a Lit nightmare
	await process_frame
	await process_frame
	_check(lights.forks_thrown == thrown + 1 and b.health < b_health, "Lantern Light: a dispel in the glow forks to the nearest Lit nightmare")
	_check(b_health - b.health <= ceili(sprout.get_damage() * lights.CALLING_SHARE) + 1, "...for half the dispelling Warden's hit")
	_check(b.statuses.stacks(EnemyStatuses.STATIC) == 0 and far.health == far.max_health, "a fork adds no status, and nothing outside the glow is struck")
	await _clean()

	# Ringing: a Bellflower pulse deepens every stacking status already there.
	dreams.calling = "bellflower"
	var bell := _plant("bellflower", Vector2(8, 2))
	a = _spawn(bell.global_position + Vector2(30, 0))
	spore._apply_one_status(a, EnemyStatuses.SPORED, 4, 1.0)
	var spored: int = a.statuses.stacks(EnemyStatuses.SPORED)
	CALLINGS._ringing(a)
	var more := maxi(roundi(a.statuses.get_max_stacks(EnemyStatuses.SPORED) * CALLINGS.RINGING_SHARE), 1)
	_check(a.statuses.stacks(EnemyStatuses.SPORED) == spored + more, "Ringing: a tenth of the cap is added")
	_check(a.statuses.source(EnemyStatuses.SPORED) == spore, "Ringing: the status keeps its own applier")
	await _clean()

	# Anvil: aim turns to a Rooted nightmare, and status hits on it add double stacks.
	dreams.calling = "rootling"
	a = _spawn(spore.global_position + Vector2(60, 0))
	b = _spawn(spore.global_position + Vector2(100, 0))
	a._path = PackedVector2Array([Vector2(0, 0), Vector2(2000, 0)])
	b._path = a._path
	a._path_index = 1
	b._path_index = 1
	var first: Node2D = spore.find_target()
	var other: Node2D = b if first == a else a
	spore.hold(other, 2.0)
	_check(other.statuses.is_held() and spore.find_target() == other, "Anvil: a Rooted nightmare in reach is aimed at first")
	spore.target_chosen = true
	_check(spore.find_target() == first, "Anvil: a target mode the player chose is left alone")
	spore.target_chosen = false
	spore._apply_one_status(other, EnemyStatuses.SPORED, 1, 1.0)
	spore._apply_one_status(first, EnemyStatuses.SPORED, 1, 1.0)
	_check(other.statuses.stacks(EnemyStatuses.SPORED) == 2 * first.statuses.stacks(EnemyStatuses.SPORED), "Anvil: double stacks on the Rooted one")
	await _clean()

	# Volley: every 5th attack of an aura Acorn, the Wardens in its aura attack at once.
	dreams.calling = "acorn"
	var acorn := _plant("acorn", Vector2(4, 4))
	var near := _plant("sprout", Vector2(5, 4))
	var away := _plant("sprout", Vector2(12, 12))
	a = _spawn(acorn.global_position + Vector2(60, 0))
	near._cooldown = 9.0
	away._cooldown = 9.0
	for i in 4:
		CALLINGS.volley_release(acorn, a)
	_check(near._cooldown == 9.0, "Volley: four throws change nothing")
	CALLINGS.volley_release(acorn, a)
	_check(near._cooldown == 0.0 and away._cooldown == 9.0, "Volley: the fifth throw makes the Wardens in the aura attack at once")
	_check(near.find_target() == a, "Volley: the forced attack aims at the Acorn's target")
	near._cooldown = 9.0
	CALLINGS.volley_release(near, a)
	_check(acorn._cooldown >= 0.0, "Volley: a Warden without an aura conducts nothing")
	await _clean()

	# Tailwind: a shot through another wind Warden's reach flies on; pulses inside it spread wider.
	dreams.calling = "whirligig"
	CALLINGS._zone_frame = -1000
	var wind := _plant("whirligig", Vector2(10, 4))
	CALLINGS._zone_frame = -1000
	var through := CALLINGS.shot_in_tailwind(sprout, wind.global_position + Vector2(-300, 0), wind.global_position + Vector2(300, 0))
	_check(through, "Tailwind: a shot crossing the Whirligig's reach is carried")
	_check(not CALLINGS.shot_in_tailwind(sprout, Vector2(0, 1500), Vector2(100, 1500)), "Tailwind: a shot elsewhere is not")
	_check(not CALLINGS.shot_in_tailwind(wind, wind.global_position, wind.global_position + Vector2(50, 0)), "Tailwind: never its own shots")
	var beside := _plant("bellflower", Vector2(11, 4))
	_check(CALLINGS.tailwind_wider(beside) == CALLINGS.TAILWIND_WIDER, "Tailwind: a pulse inside the reach spreads wider")
	_check(CALLINGS.tailwind_wider(away) == 0.0, "Tailwind: outside the reach it doesn't")
	a = _spawn(Vector2(900, 900))
	b = _spawn(Vector2(950, 900))
	_check(CALLINGS.tailwind_next(sprout, a, a.global_position) == b, "Tailwind: the shot flies on to the nearest other nightmare")
	await _clean()

	# Perches: a bird reaches nightmares from another Warden within 3 cells, and adds that Warden's status.
	dreams.calling = "nestling"
	var nest := _plant("nestling", Vector2(2, 8))
	var perch := _plant("sporeling", Vector2(5, 8))
	a = _spawn(perch.global_position + Vector2(120, 0))
	_check(not nest.get_enemies_in_range().has(a), "Perches: the nightmare is beyond the nest's own reach")
	_check(CALLINGS.uses_perches(nest) and CALLINGS.perch_targets(nest).has(a), "Perches: it is reached from the perch")
	_check(CALLINGS.perch_for(nest, a) == perch, "Perches: the bird launches from that Warden")
	_check(nest.find_target() == a, "Perches: the nest aims at it")
	nest.hit(a, 1.0, false, Tower.NO_CRIT)
	_check(a.statuses.stacks(EnemyStatuses.SPORED) >= 1, "Perches: the hit adds the perch's status")
	await _clean()

	# Lodged Stone: a stone lodges; another kind of Warden knocks it into the nightmare behind.
	dreams.calling = "pebbling"
	var stone := _plant("pebbling", Vector2(2, 11))
	a = _spawn(stone.global_position + Vector2(60, 0))
	b = _spawn(stone.global_position + Vector2(30, 0))
	a._path = PackedVector2Array([Vector2(0, 0), Vector2(3000, 0)])
	b._path = a._path
	a._path_index = 1
	b._path_index = 1
	var rules = stone.DREAM_BUILD_RULES.find(stone)
	rules.set_process(false)
	rules.reset()
	var front: Node2D = a if a.get_remaining_distance() < b.get_remaining_distance() else b
	var behind: Node2D = b if front == a else a
	stone.note_primary_target(front)
	stone.hit(front, 1.0, false, Tower.NO_CRIT)
	_check(rules.stones.has(front.get_instance_id()), "Lodged Stone: the stone lodges with the Calling alone (no card)")
	var behind_health: int = behind.health
	sprout.hit(front, 1.0, false, Tower.NO_CRIT)
	_check(behind.health < behind_health and not rules.stones.has(front.get_instance_id()), "Lodged Stone: another kind of Warden knocks it into the one behind")

	print("Callings: %d failures" % failures)
	main.queue_free()
	await process_frame
	quit(failures)

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
