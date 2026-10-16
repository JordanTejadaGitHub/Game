extends SceneTree
class Target extends Node2D:
	var health := 100
	var statuses := EnemyStatuses.new()
var failures := 0
func _plant(main: Node, cell: Vector2) -> Tower:
	var tower: Tower = load("res://scenes/tower/tower.tscn").instantiate()
	tower.tower_data = load("res://resource/tower/sprout.tres")
	tower.cell = cell
	main.get_node("%TowerContainer").add_child(tower)
	tower.set_process(false)
	return tower

func _initialize() -> void:
	_run.call_deferred()
func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func _run() -> void:
	var s := EnemyStatuses.new()
	s.apply(EnemyStatuses.DAMP, 1, 4.0)
	_check(s.has_method("preserve_other_statuses"), "Grand Tour needs bounded preservation")
	if s.has_method("preserve_other_statuses"):
		s.preserve_other_statuses(EnemyStatuses.MARKED)
		s.preserve_other_statuses(EnemyStatuses.STATIC)
		_check(is_equal_approx(s.time_left(EnemyStatuses.DAMP), 5.0), "per-status extension capped at one second")
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	var dreams: DreamState = main.get_node("%DreamState")
	dreams.set_process(false)
	var center := _plant(main, Vector2(80, 80))
	var left := _plant(main, Vector2(79, 80))
	var right := _plant(main, Vector2(81, 80))
	dreams.stacks = {"drumbeat": 1}
	dreams.bump_board()
	center._cooldown = 2.0
	dreams.on_original_attack_released(left)
	dreams.on_original_attack_released(left)
	_check(is_equal_approx(center._cooldown, 2.0), "one fast neighbor cannot feed relay")
	dreams.on_original_attack_released(right)
	_check(is_equal_approx(center._cooldown, maxf(0.0, 2.0 - 0.35 / center.attack_data.attacks_per_second)), "two distinct neighbors advance base cooldown once")
	# One trigger per attack of the recipient (card_review_2026-10-12.md 1)
	center._cooldown = 2.0
	dreams.on_original_attack_released(left)
	dreams.on_original_attack_released(right)
	_check(is_equal_approx(center._cooldown, 2.0), "a second relay before its own attack shortens nothing")
	dreams.on_original_attack_released(center)
	dreams.on_original_attack_released(left)
	dreams.on_original_attack_released(right)
	_check(center._cooldown < 2.0, "after its own attack the neighbours can hurry it again")
	_check(is_zero_approx(dreams.get_tower_attack_speed_bonus(center)), "Drumbeat has no passive speed")
	var target := Target.new()
	var other := Target.new()
	root.add_child(target)
	root.add_child(other)
	dreams.stacks = {"old_growth": 1}
	dreams.bump_board()
	center.set_meta(&"drifts_stood", 4)
	dreams.on_original_primary_hit(center, target)
	_check(not target.statuses.has(EnemyStatuses.HELD), "young Warden cannot pin")
	center.set_meta(&"drifts_stood", 5)
	dreams.on_original_primary_hit(center, other)
	_check(is_equal_approx(other.statuses.time_left(EnemyStatuses.HELD), 0.4), "aged Warden pins first new target exactly 0.4 seconds")
	other.statuses.tick(0.5)
	left.set_meta(&"drifts_stood", 5)
	dreams.on_original_primary_hit(left, other)
	_check(not other.statuses.has(EnemyStatuses.HELD), "pin cooldown shared across Wardens")
	_check(is_zero_approx(dreams.get_old_growth_bonus(center)), "Steadfast has no standing damage")
	var towers := [center, left, right]
	for i in range(3):
		towers.append(_plant(main, Vector2(79 + i, 81)))
	dreams.stacks = {"canopy": 1}
	dreams.bump_board()
	# Keyword chips 2026-10-16: Canopy = 6 or more touching attacking Wardens (never Sprouts), +0.75 range, no "busy" gate.
	dreams._update_canopy_roles()
	_check(is_zero_approx(dreams.get_tower_range_bonus(center)), "six Sprouts are no Canopy group")
	for tower in towers:
		tower.tower_data = load("res://resource/tower/sporeling.tres")
	dreams.bump_board()
	dreams._update_canopy_roles()
	_check(is_equal_approx(dreams.get_tower_range_bonus(center), DreamState.CANOPY_RANGE), "six touching attackers gain +0.75 range")
	_check(is_equal_approx(dreams.get_soothe_multiplier(center), 1.0), "Canopy has no milestone damage")
	dreams.stacks = {"grand_tour": 1}
	dreams.bump_board()
	# Grand Tour, reworked (30d7a265, card_review_2026-10-12.md 10): a nightmare carrying 3 or more different statuses
	# takes 30% more hit damage from every Warden. It no longer extends other statuses.
	var toured := Target.new()
	root.add_child(toured)
	toured.statuses.apply(EnemyStatuses.DAMP, 1, 4.0, 0.0, 0, "", center)
	toured.statuses.apply(EnemyStatuses.MARKED, 1, 5.0, 0.0, 0, "", center)
	_check(is_equal_approx(dreams.on_hit_multiplier(center, toured), 1.0), "Grand Tour: 2 statuses give no bonus")
	_check(is_equal_approx(toured.statuses.time_left(EnemyStatuses.DAMP), 4.0), "Grand Tour no longer extends the other statuses")
	toured.statuses.apply(EnemyStatuses.SPORED, 1, 3.0, 1.0, 0, "", center)
	_check(is_equal_approx(dreams.on_hit_multiplier(center, toured), 1.0 + DreamState.GRAND_TOUR_DAMAGE), "Grand Tour: 3 different statuses, hits deal 30% more")
	_check(is_equal_approx(dreams.on_hit_multiplier(left, toured), 1.3), "...from any Warden, not only the one that applied them")
	_check(is_equal_approx(dreams.get_soothe_multiplier(center), 1.0), "Grand Tour is hit damage on the nightmare, not a passive Warden bonus")
	toured.free()
	var donor := EnemyStatuses.new()
	var receiver := EnemyStatuses.new()
	donor.apply(EnemyStatuses.SPORED, 5, 2.0, 7.0)
	_check(donor.transfer_spores_to(receiver, 3) == 3 and donor.stacks(EnemyStatuses.SPORED) == 2, "spore transfer moves three accepted stacks")
	_check(is_equal_approx(receiver.time_left(EnemyStatuses.SPORED), 2.0), "spore transfer preserves remaining duration")
	receiver.immune.append(EnemyStatuses.SPORED)
	_check(donor.transfer_spores_to(receiver) == 0 and donor.stacks(EnemyStatuses.SPORED) == 2, "immune recipient loses no donor stacks")
	dreams.clear_build_role_state()
	_check(dreams._role_recent.is_empty() and dreams._role_relay.is_empty() and dreams._role_primary.is_empty(), "drift/load clear transient roles")
	target.free()
	other.free()
	main.queue_free()
	await process_frame
	await process_frame

	print("PASS dream build roles" if failures == 0 else "FAIL dream build roles: %d" % failures)
	quit(failures)
