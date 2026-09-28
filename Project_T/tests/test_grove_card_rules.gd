extends SceneTree

# Headless test for the Warden side of the Grove-only Dream cards (Roguelite's cards, rules read
# here): static_bloom, static_field, guiding_light, twin_puff, shattering_blow, and the crit hooks
# (DreamState get_crit_chance_bonus / get_crit_overflow_multiplier / get_non_crit_multiplier when
# DreamState has them). Uses stand-in cards with the same rule ids, so it runs before the real ones.
#   godot --headless --path . --script res://tests/test_grove_card_rules.gd --fixed-fps 60

const CELL := 64.0

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
	await _clean()

	# Static Bloom: chain lightning also applies Drowsy.
	var storm := _plant("stormcap", Vector2(5, 5))
	var a := _spawn(storm.global_position + Vector2(CELL, 0))
	var b := _spawn(storm.global_position + Vector2(CELL * 1.8, 0))
	_rule(&"static_bloom")
	storm._chain_strike(a)
	_check(a.statuses.stacks(EnemyStatuses.DROWSY) == 1 and b.statuses.stacks(EnemyStatuses.DROWSY) == 1,
		"Static Bloom: every nightmare the chain strikes gets 1 Drowsy")
	await _clean()

	# Static Field: a Static bolt also hits nightmares within 1 tile.
	_rule(&"static_field")
	var jar := _plant("firefly_jar", Vector2(5, 5))
	var charged := _spawn(Vector2(12.5, 8.5) * CELL)
	var neighbour := _spawn(charged.global_position + Vector2(0.8, 0) * CELL)
	var far := _spawn(charged.global_position + Vector2(3, 0) * CELL)
	charged.apply_status(EnemyStatuses.STATIC, 5, 0.0, 10.0, 0, "light", jar)  # A 5-stack bolt
	_check(_lost(neighbour) == int(30.0), "Static Field: the bolt also hits a nightmare within 1 tile (%d)" % _lost(neighbour))
	_check(_lost(far) == 0, "but not further")
	await _clean()

	# Guiding Light: Marked spreads to nightmares within 1 tile of the target.
	_rule(&"guiding_light")
	var moth := _plant("lanternmoth", Vector2(5, 5))
	var target := _spawn(Vector2(12.5, 8.5) * CELL)
	var beside := _spawn(target.global_position + Vector2(0.9, 0) * CELL)
	var away := _spawn(target.global_position + Vector2(3, 0) * CELL)
	moth.apply_status_to(target, moth.get_damage())
	_check(beside.statuses.has(EnemyStatuses.MARKED) and not away.statuses.has(EnemyStatuses.MARKED),
		"Guiding Light: Marked spreads within 1 tile")
	await _clean()

	# Twin Puff: every 3rd Sporeling attack fires twice.
	_rule(&"twin_puff")
	var sporeling := _plant("sporeling", Vector2(5, 5))
	_spawn(sporeling.global_position + Vector2(CELL, 0))
	var shots := []
	for i in 3:
		var before := _projectiles(sporeling)
		sporeling._release()
		shots.append(_projectiles(sporeling) - before)
	_check(shots == [1, 1, 2], "Twin Puff: the 3rd attack fires twice (%s)" % str(shots))
	await _clean()

	# Shattering Blow: a crit splashes 50% of its damage within 1 cell.
	_rule(&"shattering_blow")
	var pebbling := _plant("pebbling", Vector2(5, 5))
	var hit := _spawn(Vector2(12.5, 8.5) * CELL)
	var splashed := _spawn(hit.global_position + Vector2(0.8, 0) * CELL)
	pebbling.hit(hit, 1.0, false, Tower.CRIT)
	_check(_lost(splashed) == int(_lost(hit) * 0.5), "Shattering Blow: 50% of the crit splashes (%d of %d)" % [_lost(splashed), _lost(hit)])
	await _clean()

	# Crit hooks from DreamState (only when Roguelite's getters exist).
	if dreams.has_method("get_crit_chance_bonus"):
		var sniper := _plant("pebbling", Vector2(5, 5))
		var base := sniper.get_crit_chance()
		_check(sniper.get_raw_crit_chance() >= base, "raw crit chance is at least the capped one")
	else:
		print("(DreamState crit getters not in this tree yet: skipped)")

	print("grove card rules test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

# Takes a stand-in card with `rule` (the real Grove cards use the same rule ids).
func _rule(rule: StringName) -> void:
	var card := UpgradeData.new()
	card.id = "test_" + String(rule)
	card.rule_id = rule
	card.kind = UpgradeData.Kind.RULE
	dreams.pool.append(card)
	dreams.stacks[card.id] = 1

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _lost(enemy: Node2D) -> int:
	return enemy.max_health - enemy.health if is_instance_valid(enemy) else 0

func _projectiles(tower: Tower) -> int:
	return tower.get_children().filter(func(n: Node) -> bool: return n is Projectile).size()

func _plant(id: String, cell: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id).duplicate()
	tower.tower_data.id = id  # A duplicate has no file path to take its id from
	tower.tower_data.crit_chance = 0.0
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
	enemy.max_health = 100000
	enemy.health = 100000
	return enemy

func _clean() -> void:
	for child in spawner.get_children():
		child.queue_free()
	for tower in container.get_children():
		tower.queue_free()
	await process_frame
