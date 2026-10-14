extends SceneTree

# Headless test for Tower Code's hooks of the helper Commons 286–303 (dream_design.md ae90720e; numbers
# balance_simulation.md 6075f796; HelperCommons): Weary Feet, Head of the Line, First Among Equals, Stung, Forest Floor,
# Growth Rings, Hobble, Rush, Scatter, Wide Swing, Quick Draw, and the "an area Warden" check. Cards are made here with
# the rule ids (Roguelite Code owns the data).
#   godot --headless --path . --script res://tests/test_helper_commons.gd --fixed-fps 60

var failures := 0
var main: Node
var dreams: DreamState
var placer: TowerPlacer
var spawner: Node
var map

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_helper_commons_%d.json" % OS.get_process_id()
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	dreams = main.get_node("%DreamState")
	placer = main.get_node("%TowerPlacer")
	spawner = main.get_node("%EnemyContainer")
	map = main.get_node("%MapGenerator")
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

	_check(HelperCommons.is_area_attack(_data("rootling")) and HelperCommons.is_area_attack(_data("cairn"))
		and HelperCommons.is_area_attack(_data("bloomcap")) and not HelperCommons.is_area_attack(_data("sporeling"))
		and not HelperCommons.is_area_attack(_data("thornwall")), "area Wardens: pulse, splash, cloud; not a shooter or a wall")

	var spore := _plant("sporeling", Vector2(10, 2))
	_big(spore)
	var a := _walker(spore.global_position + Vector2(60, 0))
	var b := _walker(spore.global_position + Vector2(40, 30))

	# Weary Feet: +1% per 4 tiles walked (route points are half a tile apart), up to +25%.
	a._path_index = 0
	var fresh := _damage(spore, a)
	_take(&"weary_feet")
	a._path_index = 16  # 8 tiles: +2%
	var walked := _damage(spore, a)
	_check(absf(walked / fresh - 1.02) < 0.01, "Weary Feet: +2%% after 8 tiles (%.1f vs %.1f)" % [walked, fresh])
	a._path_index = 1000
	_check(absf(_damage(spore, a) / fresh - (1.0 + HelperCommons.WEARY_MAX)) < 0.01, "Weary Feet: capped at +25%")
	a._path_index = 0
	_clear()

	# Head of the Line: +25% on the nightmare furthest along.
	_take(&"head_of_the_line")
	await process_frame
	var lead: Node2D = a if a.get_remaining_distance() < b.get_remaining_distance() else b
	var other: Node2D = b if lead == a else a
	var on_lead := _damage(spore, lead)
	var on_other := _damage(spore, other)
	_check(absf(on_lead / on_other - (1.0 + HelperCommons.HEAD_OF_THE_LINE)) < 0.02, "Head of the Line: +25%% on the leader (%.1f vs %.1f)" % [on_lead, on_other])
	_clear()

	# First Among Equals: the highest-rank Warden +50%.
	var ranked := _plant("sporeling", Vector2(12, 2))
	_big(ranked)
	ranked.rank = 3
	ranked.rank_choices.assign([Tower.Focus.POWER, Tower.Focus.POWER, Tower.Focus.SWIFT])
	ranked._stats = {}
	var before_first := _damage(ranked, a)
	_take(&"first_among_equals")
	await process_frame
	_check(absf(_damage(ranked, a) / before_first - (1.0 + HelperCommons.FIRST_AMONG_EQUALS)) < 0.02, "First Among Equals: the top-rank Warden +50%")
	_check(absf(_damage(spore, a) / fresh - 1.0) < 0.02, "…the others unchanged")
	_clear()

	# (Growth Rings no longer adds range: it is the "plant nothing this block" free rank, 2026-10-13; test_generic_cards.)
	ranked._stats = {}

	# Stung: +10% per leaf lost this block, up to +30%, not at a rest.
	var director: DriftDirector = main.get_node("%DriftDirector")
	var run_state: RunState = main.get_node("%RunState")
	_take(&"stung")
	director.resting = false
	director.drifts_started = 1
	await process_frame
	var calm := _damage(spore, a)
	run_state.leaves_lost += 2
	await process_frame
	_check(absf(_damage(spore, a) / calm - 1.2) < 0.02, "Stung: +20% after 2 leaves this block")
	director.resting = true
	await process_frame
	_check(absf(_damage(spore, a) / calm - 1.0) < 0.02, "Stung: gone at the rest")
	_clear()

	# Hobble: a crit slows the nightmare.
	_take(&"hobble")
	spore.hit(a, 1.0, false, Tower.CRIT)
	_check(a.statuses.slow_time > 0.0 and is_equal_approx(a.statuses.slow_amount, HelperCommons.HOBBLE_SLOW), "Hobble: a crit slows 30%")
	_clear()

	# Rush: +20% attack speed while 10+ nightmares are on the field.
	var speed := spore.get_attacks_per_second()
	_take(&"rush")
	await process_frame
	_check(is_equal_approx(spore.get_attacks_per_second(), speed), "Rush: not with 2 on the field")
	for i in 10:
		_walker(spore.global_position + Vector2(300, 0))
	await process_frame
	_check(is_equal_approx(spore.get_attacks_per_second(), speed * (1.0 + HelperCommons.RUSH)), "Rush: +20% with 10+ on the field")
	_clear()

	# Scatter and Wide Swing on a Rootling's pulse.
	var rootling := _plant("rootling", Vector2(14, 6))
	var crowd: Array = []
	for i in 3:
		crowd.append(_walker(rootling.global_position + Vector2(20 + 10 * i, 0)))
	_take(&"scatter")
	rootling._release_attack()
	_check(crowd.all(func(e) -> bool: return e.statuses.slow_time > 0.0), "Scatter: a pulse hitting 3+ slows them")
	_clear()
	var edge := _walker(rootling.global_position + Vector2(rootling.get_range_pixels() + 30.0, 0))
	_take(&"wide_swing")
	var hp: float = edge.health
	rootling._release_attack()
	rootling._release_attack()
	_check(is_equal_approx(edge.health, hp), "Wide Swing: the 1st and 2nd pulses don't reach past the range")
	rootling._release_attack()
	await process_frame
	_check(edge.health < hp, "Wide Swing: the 3rd pulse reaches 0.75 cells further")
	_clear()

	# Quick Draw: a nightmare entering its range: the next attack at once.
	_take(&"quick_draw")
	spore._cooldown = 5.0
	spore._qd_seen = {}
	spore._qd_left = 0.0
	spore._quick_draw(0.2)
	_check(spore._cooldown == 0.0, "Quick Draw: a new nightmare in range resets the cooldown")
	spore._cooldown = 5.0
	spore._qd_left = 0.0
	spore._quick_draw(0.2)
	_check(spore._cooldown == 5.0, "Quick Draw: not again for the same ones")
	_clear()

	print("helper commons test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _data(id: String) -> TowerData:
	return load("res://resource/tower/%s.tres" % id)

func _big(tower: Tower) -> void:
	tower.attack_data = tower.attack_data.duplicate()
	tower.attack_data.damage = 400  # Whole-number health: big hits keep the ratios clean
	tower.attack_data.crit_chance = 0.0
	tower._stats = {}

func _damage(tower: Tower, enemy: Node2D) -> float:
	var before: float = enemy.health
	tower.hit(enemy, 1.0, false, Tower.NO_CRIT)
	return before - enemy.health

func _take(rule: StringName) -> void:
	var card := UpgradeData.new()
	card.id = String(rule) + "_test"
	card.rule_id = rule
	card.display_name = String(rule)
	dreams.pool.append(card)
	dreams.take(card)

func _clear() -> void:
	dreams.stacks.clear()
	dreams.bump_board()

func _plant(id: String, at: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = _data(id)
	tower.cell = at
	tower.position = Tower.MAP_GRID.calculate_map_position(at)
	placer.tower_container.add_child(tower)
	tower.set_process(false)
	return tower

func _walker(at: Vector2) -> Node2D:
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"), 50.0)
	var e = spawner.get_child(spawner.get_child_count() - 1)
	e.set_process(false)
	e.global_position = at
	e.max_health = 10000000
	e.health = 10000000
	return e

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + what)
