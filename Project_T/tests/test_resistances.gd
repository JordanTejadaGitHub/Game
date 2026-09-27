extends SceneTree

# Headless test of creature resistances (documentation/enemy_design.md, "Resistances"). Run:
#   godot --headless --path . --script res://tests/test_resistances.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var spawner = main.get_node("%EnemyContainer")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

	# --- Family resistance / weakness (Bark Beetle: resists stone, weak to spore) ---
	var beetle = _spawn(spawner, _sturdy("res://resource/enemy/bark_beetle.tres"))
	_check(_loss(beetle, 100.0, "stone") == 65, "resisted family soothes ×0.65")
	_check(_loss(beetle, 100.0, "spore") == 135, "weak family soothes ×1.35")
	_check(_loss(beetle, 100.0, "water") == 100, "other families soothe normally")
	_check(_loss(beetle, 100.0, "sprout") == 100, "neutral lines (Sprout) are never resisted")
	_check(_loss(beetle, 100.0) == 100, "unsourced soothe is unchanged")
	_check(beetle._hit_mark == 1, "a weak hit shows the sparkle")
	beetle.take_damage(10.0, "stone")
	_check(beetle._hit_mark == -1, "a resisted hit shows the grey puff")

	# --- Marked stacks multiplicatively with the family multiplier ---
	beetle.apply_status(EnemyStatuses.MARKED)
	_check(_loss(beetle, 100.0, "spore") == floori(100 * 1.35 * 1.25), "Marked × weakness")

	# --- Attack shape (Bee Swarm): single-target halved, area full ---
	var swarm_data := _sturdy("res://resource/enemy/leaf_bug.tres")
	swarm_data.single_target_multiplier = 0.5
	var swarm = _spawn(spawner, swarm_data)
	_check(_loss(swarm, 100.0, "light", false) == 50, "single-target hit on a swarm ×0.5")
	_check(_loss(swarm, 100.0, "light", true) == 100, "area hit on a swarm is full")

	# --- Blight coat (Badger): −6 per hit, soaks 100, keeps at least 1, then crumbles ---
	var badger_data := _sturdy("res://resource/enemy/leaf_bug.tres")
	badger_data.coat_per_hit = 6
	badger_data.coat_total = 100
	var badger = _spawn(spawner, badger_data)
	_check(_loss(badger, 3.0) == 1, "chip damage bounces off the coat (keeps 1)")
	_check(is_equal_approx(badger.coat, 98.0), "the coat soaks what it takes off")
	_check(_loss(badger, 40.0) == 34, "heavy hits lose only the flat amount")
	while badger.coat > 0.0:
		badger.take_damage(40.0)
	_check(_loss(badger, 40.0) == 40, "once crumbled, the coat is gone for good")
	var scaled_data := badger_data.duplicate()
	var scaled = spawner.enemy_scene.instantiate()
	scaled.enemy_data = scaled_data
	scaled.health_scale = 2.0
	spawner.add_child(scaled)
	_check(is_equal_approx(scaled.coat, 200.0) and _loss(scaled, 40.0) == 28, "the coat grows with health_scale")

	# --- Status resistance ---
	var sleepless_data := _sturdy("res://resource/enemy/leaf_bug.tres")
	sleepless_data.status_immune = [&"drowsy"] as Array[StringName]
	sleepless_data.status_duration_multipliers = {&"damp": 0.5}
	var sleepless = _spawn(spawner, sleepless_data)
	sleepless.apply_status(EnemyStatuses.DROWSY, 3)
	_check(not sleepless.statuses.has(EnemyStatuses.DROWSY), "immune statuses don't take")
	sleepless.apply_status(EnemyStatuses.DAMP)
	_check(is_equal_approx(sleepless.statuses.time_left(EnemyStatuses.DAMP), EnemyStatuses.DEFAULT_DURATION[EnemyStatuses.DAMP] * 0.5),
		"duration multipliers shorten statuses")
	var seed_data: EnemyData = load("res://resource/enemy/dandelion_seed.tres")
	_check(&"held" in seed_data.status_immune, "Dandelion Seed can't be Held")

	# --- Spored ticks count as the applier's family (and as area); Static bolts count as light ---
	var weak_to_spores = _spawn(spawner, _sturdy("res://resource/enemy/bark_beetle.tres"))
	weak_to_spores.speed = 0.0  # Tick statuses in place instead of walking off the one-cell path
	weak_to_spores.apply_status(EnemyStatuses.SPORED, 1, 10.0, 10.0, 0, "spore")
	_check(weak_to_spores.statuses.spore_line() == "spore", "Spored remembers the applier's family")
	var before: int = weak_to_spores.health
	weak_to_spores._process(1.0)  # One second: two Spored ticks
	var ticked: int = before - weak_to_spores.health
	_check(ticked == floori(10.0 * 1.35), "Spored ticks get the spore weakness (%d from 10/s × 1.35)" % ticked)
	var moth = _spawn(spawner, _sturdy("res://resource/enemy/dusk_moth.tres"))
	before = moth.health
	for i in EnemyStatuses.DEFAULT_MAX_STACKS[EnemyStatuses.STATIC]:
		moth.apply_status(EnemyStatuses.STATIC, 1, 0.0, 10.0)
	_check(before - moth.health == floori(10.0 * EnemyStatuses.STATIC_BOLT_MULTIPLIER * 1.35), "Static bolts count as light")

	# --- A real Warden passes its family ---
	var stone_data: TowerData = load("res://resource/tower/pebbling.tres").duplicate()
	stone_data.damage = 100
	var warden := Tower.new()
	warden.tower_data = stone_data
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	warden.add_child(sprite)
	main.get_node("%TowerContainer").add_child(warden)
	warden.set_process(false)
	var target = _spawn(spawner, _sturdy("res://resource/enemy/bark_beetle.tres"))
	before = target.health
	warden.hit(target)
	_check(before - target.health == floori(warden.get_damage() * 0.65), "a Pebbling's hit is resisted by the Bark Beetle")

	print("resistance test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

# A copy of a creature with lots of health, so hits never cleanse it.
func _sturdy(path: String) -> EnemyData:
	var data: EnemyData = load(path).duplicate()
	data.health = 100000
	return data

func _spawn(spawner, data: EnemyData) -> Node2D:
	var enemy = spawner.enemy_scene.instantiate()
	enemy.enemy_data = data
	spawner.add_child(enemy)
	enemy.set_path(PackedVector2Array([Vector2(1, 1)]))
	enemy.set_process(false)
	return enemy

func _loss(enemy: Node2D, amount: float, line: String = "", is_area: bool = false) -> int:
	enemy._soothe_carry = 0.0
	var before: int = enemy.health
	enemy.take_damage(amount, line, is_area)
	return before - enemy.health

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _wait(seconds: float) -> void:
	await create_timer(seconds, true, true).timeout
