extends SceneTree

# Headless test for the Grove build branches' per-hit parts (dream_design.md "Grove build branches:
# Swift and Wide Reach", GroveRules): Momentum, Quickening, Flurry, Hummingheart, Whirlwind Heart, Broad
# Splash, Lingering Splash, Spillover, Great Ripple. Run from the project folder:
#   godot --headless --path . --script res://tests/test_grove_build_rules.gd --fixed-fps 60

const CELL := 64.0
const RULES := ["momentum", "quickening", "flurry", "hummingheart", "whirlwind_heart", "broad_splash",
	"lingering_splash", "spillover", "great_ripple"]

var failures := 0
var main: Node
var spawner
var placer: TowerPlacer
var container: Node
var dreams: DreamState

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
	main.get_node("%RunState").invulnerable = true
	await _clean()
	dreams.unlock_everything = true
	dreams.grove_cards.assign(RULES)  # Grove cards: allowed into this run

	# Momentum: a streak on one nightmare speeds the Warden up; a new target starts over.
	var jar := _plant("firefly_jar", Vector2(5, 5))
	var base := jar.get_attacks_per_second()
	_take("momentum")
	var a := _spawn(jar.global_position + Vector2(CELL, 0))
	var b := _spawn(jar.global_position + Vector2(0, CELL))
	for i in 3:
		jar.hit(a, 1.0, false, Tower.NO_CRIT)
	var step: Vector2 = dreams.momentum_step()
	_check(absf(jar.get_attacks_per_second() - base * (1.0 + 3 * step.x)) < 0.01, "Momentum: 3 hits on one nightmare +%d%% speed" % roundi(300 * step.x))
	for i in 20:
		jar.hit(a, 1.0, false, Tower.NO_CRIT)
	_check(absf(jar.get_attacks_per_second() - base * (1.0 + step.y)) < 0.01, "capped at +%d%%" % roundi(step.y * 100))
	jar.hit(b, 1.0, false, Tower.NO_CRIT)
	_check(absf(jar.get_attacks_per_second() - base * (1.0 + step.x)) < 0.01, "a new target starts the streak over")
	_drop("momentum")

	# Quickening: a nightmare dispelled in range: +30% attack speed for 4 s.
	_take("quickening")
	jar._grove.clear()
	jar.clear_dream_cache()
	var base_q := jar.get_attacks_per_second()
	a.dispel()
	await process_frame
	_check(absf(jar.get_attacks_per_second() - base_q * (1.0 + DreamState.QUICKENING_SPEED)) < 0.01, "Quickening: +30%% after a dispel in range")
	jar._anim_time += DreamState.QUICKENING_TIME + 0.1
	_check(absf(jar.get_attacks_per_second() - base_q) < 0.01, "for 4 s")
	_drop("quickening")
	await _clean()

	# Flurry: every 5th attack fires twice; the extra never counts.
	_take("flurry")
	var shooter := _plant("sporeling", Vector2(10, 5))
	var shots := [0]
	var target := _spawn(shooter.global_position + Vector2(CELL, 0))
	for i in 10:
		var before := container.get_parent().find_children("*", "Projectile", true, false).size()
		shooter._release()
		shots[0] += container.get_parent().find_children("*", "Projectile", true, false).size() - before
	_check(shots[0] == 12, "Flurry: 10 attacks fire 12 shots (%d)" % shots[0])
	_drop("flurry")
	await _clean()

	# Hummingheart and Whirlwind Heart (on a Warden with bonus speed: rank Swift).
	var swift := _plant("firefly_jar", Vector2(12, 8))
	swift.rank = 3
	swift.rank_choices = [Tower.Focus.SWIFT, Tower.Focus.SWIFT, Tower.Focus.SWIFT]
	swift.clear_dream_cache()
	var speed := swift.get_attacks_per_second()
	var damage := swift.get_damage()
	_take("whirlwind_heart")
	swift.clear_dream_cache()
	var bonus := speed / swift.attack_data.attacks_per_second - 1.0
	_check(absf(swift.get_attacks_per_second() - swift.attack_data.attacks_per_second * (1.0 + 2.0 * bonus)) < 0.01,
		"Whirlwind Heart: the bonus part counts double (%.2f -> %.2f/s)" % [speed, swift.get_attacks_per_second()])
	_drop("whirlwind_heart")
	_take("hummingheart")
	swift.clear_dream_cache()
	var hum := dreams.hummingheart_bonus(bonus)
	_check(hum > 0.0 and absf(swift.get_damage() - damage * (1.0 + hum)) < 0.5, "Hummingheart: +%d%% damage from %d%% bonus speed" % [roundi(hum * 100), roundi(bonus * 100)])
	_drop("hummingheart")

	# Broad Splash: every area attack's radius +0.25 cells per stack.
	var drop := _plant("rain_lily", Vector2(14, 12))
	var splash := drop.get_splash_cells()
	_take("broad_splash")
	_check(is_equal_approx(drop.get_splash_cells(), splash + DreamState.BROAD_SPLASH_PER * dreams.get_splash_multiplier(drop.tower_data)),
		"Broad Splash: splash %.2f -> %.2f cells" % [splash, drop.get_splash_cells()])
	_drop("broad_splash")

	# Lingering Splash: every 3rd area attack leaves a patch.
	_take("lingering_splash")
	var at := Vector2(14, 14) * CELL
	for i in 3:
		drop._splash(at, CELL, 1.0, Tower.NO_CRIT)
	var patches := main.find_children("*", "Node2D", true, false).filter(func(n) -> bool: return n is GroveRules.LingeringPatch)
	_check(patches.size() == 1, "Lingering Splash: the 3rd area attack leaves a patch (%d)" % patches.size())
	_drop("lingering_splash")

	# Spillover: an area hit that dispels splashes the leftover onto nightmares within 1 cell.
	_take("spillover")
	var weak := _spawn(Vector2(3, 14) * CELL)
	weak.health = 1
	var near := _spawn(weak.global_position + Vector2(0.6 * CELL, 0))
	drop.hit(weak, 1.0, true, Tower.NO_CRIT)
	_check(weak.is_cleansed and near.health < near.max_health, "Spillover: the leftover reaches a neighbour")
	_drop("spillover")
	await _clean()

	# Great Ripple: a second hit 1 s later, 1 cell wider, at 50%.
	_take("great_ripple")
	var ring := _spawn(Vector2(20, 14) * CELL + Vector2(1.5 * CELL, 0))
	drop._splash(Vector2(20, 14) * CELL, CELL, 1.0, Tower.NO_CRIT)
	_check(ring.health == ring.max_health, "outside the splash at first")
	await create_timer(DreamState.GREAT_RIPPLE_DELAY + 0.2).timeout
	_check(ring.health < ring.max_health, "Great Ripple: 1 s later the wider ring reaches it")
	_drop("great_ripple")

	print("grove build rules test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _take(id: String) -> void:
	for card in dreams.pool:
		if card.id == id:
			dreams.take(card)
	if not dreams.has_rule(StringName(id)):
		_check(false, "took %s" % id)
	for t in container.get_children():
		if t is Tower:
			t.clear_dream_cache()

func _drop(id: String) -> void:
	dreams.stacks.erase(id)
	dreams.bump_board()
	for t in container.get_children():
		if t is Tower:
			t.clear_dream_cache()

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
	var enemy: Node2D = spawner.get_child(spawner.get_child_count() - 1)
	enemy.set_process(false)
	enemy.global_position = at
	enemy.max_health = 100000
	enemy.health = 100000
	return enemy

func _clean() -> void:
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
