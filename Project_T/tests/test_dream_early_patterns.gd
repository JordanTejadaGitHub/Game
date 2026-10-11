extends SceneTree
var failures := 0
var main: Node
var spawner
var placer: TowerPlacer
var container: Node
var dreams: DreamState
const CELL := 64.0
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
	var one := _plant("sprout", Vector2(2, 2))
	var two := _plant("sprout", Vector2(3, 2))
	var a = _spawn(Vector2(300, 300))
	var b = _spawn(Vector2(250, 300))
	a._path = PackedVector2Array([Vector2(0,0), Vector2(500,300)])
	b._path = a._path
	a._path_index = 1
	b._path_index = 1
	var rules = one.DREAM_BUILD_RULES.find(one)
	rules.set_process(false)
	one.note_primary_target(a)
	var baseline_health: int = a.health
	var baseline_carry: float = a._soothe_carry
	one.hit(a, 1.0, false, Tower.NO_CRIT)
	var baseline: float = baseline_health - a.health + a._soothe_carry - baseline_carry
	var spores := _plant("sporeling", Vector2(5,2))
	spores.note_primary_target(a)
	spores.hit(a, 1.0, false, Tower.NO_CRIT)
	var native_spore_potency: float = a.statuses.potency(EnemyStatuses.SPORED)
	a.statuses.remove(EnemyStatuses.SPORED)
	_take("rhythm")
	spores.hit(a, 1.0, false, Tower.NO_CRIT)
	_check(is_equal_approx(a.statuses.potency(EnemyStatuses.SPORED), native_spore_potency), "direct hit price preserves native Spored potency")
	a.statuses.remove(EnemyStatuses.SPORED)
	baseline_health = a.health
	baseline_carry = a._soothe_carry
	one.hit(a, 1.0, false, Tower.NO_CRIT)
	var priced: float = baseline_health - a.health + a._soothe_carry - baseline_carry
	_check(is_equal_approx(priced, baseline * 0.90), "original direct hits pay exactly ten percent")
	rules.reset()
	one.note_primary_target(a)
	var speed: float = one.get_attacks_per_second()
	one.attack_data = one.attack_data.duplicate()
	one.attack_data.potency = 2.0
	var health: int = a.health
	for i in range(4):
		one.hit(a, 1.0, false, Tower.NO_CRIT)
	_check(rules.echoes.is_empty(), "four originals do not echo")
	one.hit(a, 1.0, false, Tower.NO_CRIT, &"", false)
	_check(rules.beats[one.get_instance_id()].count == 4, "derived hit cannot progress Fifth Beat")
	one.hit(a, 1.0, false, Tower.NO_CRIT)
	_check(rules.echoes.size() == 1, "fifth hit schedules one echo")
	_check(is_equal_approx(one.get_attacks_per_second(), speed), "Fifth Beat never changes attack speed")
	health = a.health
	var echo_carry: float = a._soothe_carry
	var echo_payload: float = rules.echoes[0].damage
	_check(is_equal_approx(echo_payload, priced), "Fifth Beat echo stores full triggering hit")
	rules._process(0.24)
	_check(a.health == health, "echo waits its quarter second")
	rules._process(0.02)
	_check(a.health < health and rules.echoes.is_empty(), "echo lands after delay without recursion")
	_check(is_equal_approx(health - a.health + a._soothe_carry - echo_carry, echo_payload), "echo saved payload receives no second Potency scaling")
	for i in range(5):
		one.hit(a, 1.0, false, Tower.NO_CRIT)
	_check(rules.echoes.size() == 1, "every five hits repeats")
	a.is_cleansed = true
	health = a.health
	rules._process(0.26)
	_check(a.health == health, "dead target wastes echo")
	a.is_cleansed = false
	rules.reset()
	for i in range(4):
		one.hit(a, 1.0, false, Tower.NO_CRIT)
	one.note_primary_target(b)
	one.note_primary_target(a)
	one.hit(a, 1.0, false, Tower.NO_CRIT)
	_check(rules.echoes.is_empty(), "target selection switch without a hit resets Fifth Beat")
	one.note_primary_target(b)
	one.hit(b, 1.0, false, Tower.NO_CRIT)
	_check(rules.echoes.is_empty() and rules.beats[one.get_instance_id()].count == 1, "target switch restarts count")
	_take("crossfire")
	rules.reset()
	one.note_primary_target(a)
	two.note_primary_target(a)
	health = b.health
	one.hit(a, 1.0, false, Tower.NO_CRIT)
	one.hit(a, 1.0, false, Tower.NO_CRIT)
	_check(b.health == health, "same Warden cannot trigger Crossfire")
	two.hit(a, 1.0, false, Tower.NO_CRIT, &"", false)
	_check(b.health == health, "derived hit cannot trigger Crossfire")
	var first_payload: float = rules.crossfire[a.get_instance_id()].damage
	var second_health: int = a.health
	var second_carry: float = a._soothe_carry
	var follower_carry: float = b._soothe_carry
	two.attack_data = two.attack_data.duplicate()
	two.attack_data.potency = 2.0
	two.hit(a, 0.50, false, Tower.NO_CRIT)
	var second_payload: float = second_health - a.health + a._soothe_carry - second_carry
	_check(b.health < health, "two same-family Wardens hit route follower")
	_check(is_equal_approx(health - b.health + b._soothe_carry - follower_carry, minf(first_payload, second_payload) * 0.40), "Crossfire uses forty percent of lower dealt hit without second Potency")
	health = b.health
	one.hit(a, 1.0, false, Tower.NO_CRIT)
	two.hit(a, 1.0, false, Tower.NO_CRIT)
	_check(b.health == health, "shared cooldown suppresses further bolts")
	rules.reset()
	one.hit(a, 1.0, false, Tower.NO_CRIT)
	rules._process(1.01)
	two.hit(a, 1.0, false, Tower.NO_CRIT)
	_check(b.health == health, "expired one second rendezvous does not fire")
	rules.reset()
	b.global_position = Vector2(-1000,300)
	one.hit(a, 1.0, false, Tower.NO_CRIT)
	two.hit(a, 1.0, false, Tower.NO_CRIT)
	b.global_position = Vector2(250,300)
	one.hit(a, 1.0, false, Tower.NO_CRIT)
	_check(b.health == health, "missing follower does not bank trigger")
	rules._process(3.01)
	one.hit(a, 1.0, false, Tower.NO_CRIT)
	two.hit(a, 1.0, false, Tower.NO_CRIT)
	_check(b.health < health, "cooldown expires and permits a new rendezvous")
	rules.reset()
	health = b.health
	var follower_data = b.enemy_data
	b.enemy_data = b.enemy_data.duplicate()
	b.enemy_data.trait_kind = EnemyData.Trait.FLYING
	one.hit(a, 1.0, false, Tower.NO_CRIT)
	two.hit(a, 1.0, false, Tower.NO_CRIT)
	_check(b.health == health, "flying follower is excluded")
	b.enemy_data = follower_data
	rules.reset()
	var doomed := _plant("sprout", Vector2(4,2))
	doomed.note_primary_target(a)
	for i in range(5):
		doomed.hit(a, 1.0, false, Tower.NO_CRIT)
	_check(not rules.echoes.is_empty(), "source disappearance fixture schedules echo")
	health = a.health
	doomed.queue_free()
	await process_frame
	rules._process(0.26)
	_check(a.health == health, "gone source wastes echo")
	rules.reset()
	_check(rules.crossfire.is_empty() and rules.beats.is_empty() and rules.echoes.is_empty(), "reset clears transient combat patterns")
	print("Early combat patterns: %d failures" % failures)
	main.queue_free()
	await process_frame
	quit(failures)

func _take(card_id: String) -> void:
	for card in dreams.pool:
		if card.id == card_id:
			dreams.take(card)
			return
	for file in DirAccess.get_files_at("res://resource/dream"):
		var card = load("res://resource/dream/" + file.trim_suffix(".remap"))
		if card is UpgradeData and card.id == card_id:
			dreams.take(card)
			return
	_check(false, "card %s exists" % card_id)

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
