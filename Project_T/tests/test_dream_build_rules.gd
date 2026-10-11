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
	var stone := _plant("pebbling", Vector2(2, 2))
	var water := _plant("dewdrop", Vector2(3, 2))
	var sprout := _plant("sprout", Vector2(4, 2))
	var spores := _plant("sporeling", Vector2(5, 2))
	_take("blessing_pebbling")
	_take("blessing_dewdrop")
	_take("blessing_sporeling")
	var a := _spawn(Vector2(300, 300))
	var b := _spawn(Vector2(250, 300))
	a._path = PackedVector2Array([Vector2(0,0), Vector2(10,0)])
	b._path = PackedVector2Array([Vector2(0,0), Vector2(10,0)])
	a._path_index = 1
	b._path_index = 1
	var saved_data = stone.attack_data
	stone.attack_data = stone.attack_data.duplicate()
	stone.attack_data.potency = 2.0
	var payload_health: int = b.health
	b.take_damage(80.0, "stone", false, false, stone, &"stone_relay")
	_check(payload_health - b.health == 80, "saved relay payload does not gain Potency a second time")
	payload_health = b.health
	b.take_damage(80.0, "water", false, false, stone, &"stored_rain")
	_check(payload_health - b.health == 80, "saved rain payload does not gain Potency a second time")
	stone.attack_data = saved_data
	var before: int = b.health
	stone.note_primary_target(a)
	stone.hit(a, 1.0, false, Tower.NO_CRIT)
	stone.hit(a, 1.0, false, Tower.NO_CRIT)
	_check(b.health == before, "same family cannot consume relay")
	sprout.note_primary_target(a)
	sprout.hit(a, 1.0, false, Tower.NO_CRIT)
	_check(b.health < before, "different family consumes stone and hits follower")
	before = b.health
	sprout.hit(a, 1.0, false, Tower.NO_CRIT)
	_check(b.health == before, "relay is single use")
	a.statuses.apply(EnemyStatuses.DAMP)
	before = a.health
	water.note_primary_target(a)
	water.projectile_landed(a, a.global_position)
	_check(a.health == before and not a.statuses.has(EnemyStatuses.DAMP), "already damp targeted attack is diverted before damage/status")
	before = b.health
	b.global_position = a.global_position
	await process_frame
	await process_frame
	_check(b.health < before, "different entrant receives stored attack")
	_check(before - b.health >= floori(water.get_damage() * 2.0), "expired-or-overwritten trap gamble pays a doubled base hit when an entrant arrives")
	a.statuses.apply(EnemyStatuses.SPORED, 3, 2.0, 10.0)
	spores.note_primary_target(a)
	spores.note_primary_target(b)
	_check(a.statuses.stacks(EnemyStatuses.SPORED) == 0 and b.statuses.stacks(EnemyStatuses.SPORED) == 3, "primary change moves poison without copies")
	_check(b.statuses.time_left(EnemyStatuses.SPORED) <= 2.0, "remaining poison duration is bounded")
	var rules = stone.DREAM_BUILD_RULES.find(stone)
	# Shared slot per enemy: embedding one nightmare does not replace another.
	rules.reset()
	stone.note_primary_target(a)
	stone.hit(a, 1.0, false, Tower.NO_CRIT)
	stone.note_primary_target(b)
	stone.hit(b, 1.0, false, Tower.NO_CRIT)
	_check(rules.stones.size() == 2, "two enemies retain independent shared stones")
	sprout.note_primary_target(a)
	sprout.hit(a, 1.0, false, Tower.NO_CRIT, &"", false)
	_check(rules.stones.size() == 2, "derived direct hit cannot consume stone")
	sprout.hit(a, 1.0, false, Tower.NO_CRIT)
	sprout.note_primary_target(b)
	sprout.hit(b, 1.0, false, Tower.NO_CRIT)
	_check(rules.stones.is_empty(), "both stones consumed even with no follower")
	# Immunity and existing stack caps do not destroy unaccepted Poisoned stacks.
	a.statuses.remove(EnemyStatuses.SPORED)
	b.statuses.remove(EnemyStatuses.SPORED)
	a.statuses.apply(EnemyStatuses.SPORED, 3, 1.5, 10.0)
	b.statuses.immune.append(EnemyStatuses.SPORED)
	spores.note_primary_target(a)
	spores.note_primary_target(b)
	_check(a.statuses.stacks(EnemyStatuses.SPORED) == 3 and b.statuses.stacks(EnemyStatuses.SPORED) == 0, "immune recipient leaves reserve on donor")
	b.statuses.immune.clear()
	spores.note_primary_target(a)
	a.is_cleansed = true
	spores.note_primary_target(b)
	_check(b.statuses.stacks(EnemyStatuses.SPORED) == 0, "dead donor cannot supply reserve")
	a.is_cleansed = false
	# One puddle per Warden, expiration, and world parenting.
	a.statuses.apply(EnemyStatuses.DAMP)
	water.projectile_landed(a, a.global_position)
	var old = water.get_meta(rules.PUDDLE).get_ref()
	_check(old.get_parent() != container and old.get_parent() != spawner, "puddle belongs to world rather than typed containers")
	a.statuses.apply(EnemyStatuses.DAMP)
	water.projectile_landed(a, a.global_position)
	var fresh = water.get_meta(rules.PUDDLE).get_ref()
	_check(old.is_queued_for_deletion() and old != fresh, "new stored attack replaces old puddle")
	var flyer := _spawn(fresh.global_position + Vector2(100, 0))
	flyer.enemy_data = flyer.enemy_data.duplicate()
	flyer.enemy_data.trait_kind = EnemyData.Trait.FLYING
	var flyer_health: int = flyer.health
	flyer.global_position = fresh.global_position
	fresh._process(0.1)
	_check(flyer.health == flyer_health and not fresh.is_queued_for_deletion(), "flying entrant cannot consume stored rain")
	fresh._process(4.1)
	_check(fresh.is_queued_for_deletion(), "stored puddle expires at four seconds")
	# The primary stone cannot be embedded by a killing hit.
	rules.reset()
	a.health = 1
	stone.note_primary_target(a)
	stone.hit(a, 1.0, false, Tower.NO_CRIT)
	_check(rules.stones.is_empty(), "dying primary cannot retain an embedded stone")
	# A queued original primary keeps its identity after the Warden selects another target.
	dreams.stacks = {"blessing_pebbling": 1}
	dreams.bump_board()
	var queued_primary := _spawn(Vector2(420, 420))
	var next_primary := _spawn(Vector2(460, 420))
	rules.reset()
	stone.note_primary_target(queued_primary)
	var area_queue := AreaHitQueue.find(stone)
	area_queue._frame = Engine.get_process_frames()
	area_queue._count = AreaHitQueue.BUDGET
	stone.hit(queued_primary, 1.0, true, Tower.NO_CRIT)
	stone.note_primary_target(next_primary)
	area_queue._process(0.0)
	_check(rules.stones.has(queued_primary.get_instance_id()) and not rules.stones.has(next_primary.get_instance_id()), "queued primary embeds its own stone after target switch")
	rules.reset()
	area_queue._count = AreaHitQueue.BUDGET
	stone._build_derived_attack = true
	stone.hit(next_primary, 1.0, true, Tower.NO_CRIT)
	stone._build_derived_attack = false
	area_queue._process(0.0)
	_check(rules.stones.is_empty(), "queued Flurry copy cannot embed a stone")
	# Real BranchKit dispatch must contribute to Drumbeat, including its early-return patterns.
	var relay_center := _plant("sprout", Vector2(80, 80))
	var branch := _plant("cloudlet", Vector2(79, 80))
	var relay_right := _plant("sprout", Vector2(81, 80))
	dreams.stacks = {"drumbeat": 1}
	dreams.bump_board()
	relay_center._cooldown = 2.0
	branch._release()
	relay_right._release()
	_check(is_equal_approx(relay_center._cooldown, 2.0 - 0.35 / relay_center.attack_data.attacks_per_second), "actual BranchKit release feeds Drumbeat once")
	dreams.stacks = {"drumbeat": 1, "flurry": 1}
	dreams.bump_board()
	dreams._role_relay.clear()
	relay_center._cooldown = 2.0
	branch._attack_count = DreamState.FLURRY_EVERY - 1
	branch._release()
	relay_right._release()
	_check(is_equal_approx(relay_center._cooldown, 2.0 - 0.35 / relay_center.attack_data.attacks_per_second), "Flurry copy adds no second relay notification")
	_check(dreams._role_relay.get(relay_center.get_instance_id(), {}).is_empty(), "Flurry copy leaves no next-cycle relay credit")
	# Pulse Canopy counts all actual living targets struck, without needing a remembered primary.
	var bell := _plant("bellflower", Vector2(14, 14))
	for cell in [Vector2(13,14), Vector2(15,14), Vector2(13,15), Vector2(14,15), Vector2(15,15)]:
		_plant("sprout", cell)
	for i in 6:
		_spawn(bell.global_position + Vector2(i * 4.0, 0))
	dreams.stacks = {"canopy": 1}
	dreams.bump_board()
	bell._release()
	_check(is_equal_approx(dreams.canopy_range_bonus(bell), 1.0), "actual pulse with six living hits activates Canopy")
	print("Dream build family rules: %d failures" % failures)
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
