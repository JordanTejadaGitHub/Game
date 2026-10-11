extends SceneTree
var main: Node
var dreams: DreamState
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	dreams = main.get_node("%DreamState")
	dreams.stacks = {"cheap_seeds": 1}
	var sprout: TowerData = load("res://resource/tower/sprout.tres")
	_check(dreams.get_build_cost(sprout) == sprout.cost, "isolation discount needs a planting position")
	_check(dreams.get_build_cost_at(sprout, Vector2(80, 80)) == sprout.cost - 4, "isolated planting saves four Dew")
	var neighbor := _plant("sprout", Vector2(81, 81))
	_check(dreams.get_build_cost_at(sprout, Vector2(80, 80)) == sprout.cost, "diagonal Sprout removes discount")
	neighbor.free()
	dreams.stacks = {"scarred_bark": 1}
	dreams.run_state.leaves_lost = 0
	dreams.run_state.leaves = 20
	dreams.run_state.max_leaves = 20
	dreams.run_state.lose_leaves(3)
	dreams.run_state.regrow_leaves(3)
	_check(dreams.run_state.leaves_lost == 3, "healing never erases actual leaf losses")
	dreams.run_state.max_leaves = 18
	dreams.run_state.regrow_leaves(0)
	_check(dreams.run_state.leaves_lost == 3, "maximum-leaf clamps never add actual losses")
	_check(dreams.effects().preview_line(load("res://resource/dream/scarred_bark.tres")) == "Now: 3 leaves actually lost · +6% future Dew pots", "live economy line reports the pot bonus")
	_check(is_equal_approx(dreams.get_dew_pot_multiplier(1, false), 1.06), "losses improve future pots")
	dreams.run_state.leaves_lost = 30
	_check(is_equal_approx(dreams.get_dew_pot_multiplier(1, false), 1.2), "pot bonus caps at twenty percent")
	dreams.stacks.clear()
	var attacker := _plant("sporeling", Vector2(80, 80))
	attacker.rank = 1
	var specialist: UpgradeData = load("res://resource/dream/specialist.tres")
	_check(not dreams.can_offer(specialist, 1), "rank I cannot open Specialist in act one")
	_check(dreams.can_offer(specialist, 2), "rank I opens speculative Specialist in act two")
	dreams.stacks = {"few_and_mighty": 1}
	_check(dreams.get_card_effects(attacker.tower_data, attacker.cell, attacker).any(func(row: Dictionary) -> bool:
		return row.id == "few_and_mighty" and is_equal_approx(row.damage, 0.8)), "small-board bonus is capped")
	_combat_and_positions(attacker)
	_special_turnover()
	_canopy_milestones()
	_remaining_design_fixes()
	_impatient_overlap()
	_council_corrections()
	print("Dream rework: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.free()
	quit(failures)
func _plant(id: String, cell: Vector2) -> Tower:
	var tower: Tower = load("res://scenes/tower/tower.tscn").instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = cell
	tower.position = tower.MAP_GRID.calculate_map_position(cell)
	main.get_node("%TowerContainer").add_child(tower)
	tower.set_process(false)
	return tower
func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _spawn(cell: Vector2) -> Node2D:
	var container := main.get_node("%EnemyContainer")
	var enemy = container.enemy_scene.instantiate()
	enemy.enemy_data = TestGrove._load_enemy_types()[0]
	container.add_child(enemy)
	enemy.position = enemy.grid.calculate_map_position(cell)
	enemy.set_path(PackedVector2Array([cell]))
	enemy.set_process(false)
	enemy.health = 100000
	enemy.max_health = 100000
	return enemy

func _combat_and_positions(attacker: Tower) -> void:
	var first := _spawn(attacker.cell)
	var second := _spawn(attacker.cell)
	attacker.rank = 0
	attacker.attack_data = attacker.attack_data.duplicate()
	attacker.attack_data.damage = 100
	dreams.stacks.clear()
	dreams.bump_board()
	attacker.clear_dream_cache()
	attacker.hit(first, 1.0, false, Tower.NO_CRIT)
	var plain: int = 100000 - first.health
	first.health = 100000
	first.statuses = EnemyStatuses.new()
	dreams.stacks = {"deeper_calm": 1}
	dreams.bump_board()
	attacker.clear_dream_cache()
	_check(is_equal_approx(attacker.get_damage(), 100.0), "Clear Minds leaves unconditional damage unchanged")
	dreams.card_credit = {"block": {}, "run": {}}
	attacker.hit(first, 1.0, false, Tower.NO_CRIT)
	_check(dreams.get_card_credit("deeper_calm", &"run").damage > 0.0, "conditional hit bonus appears in card credit")
	var clean: int = 100000 - first.health
	_check(absf(clean - plain * 1.35) <= 1.0, "status-free first hit gets conditional damage before applying its status")
	_check(not first.statuses.active_ids().is_empty(), "the hit still applies the Warden's own status")
	first.health = 100000
	attacker.hit(first, 1.0, false, Tower.NO_CRIT)
	_check(absf((100000 - first.health) - plain) <= 1.0, "already-afflicted target does not receive Clear Minds bonus")
	first.health = 100000
	first.statuses = EnemyStatuses.new()
	attacker.hit(first, 1.0, true, Tower.NO_CRIT, &"cloud")
	_check(absf((100000 - first.health) - plain) <= 1.0, "persistent cloud damage cannot earn Clear Minds bonus")
	first.health = 100000
	first.statuses = EnemyStatuses.new()
	var queue := AreaHitQueue.find(attacker)
	queue._frame = Engine.get_process_frames()
	queue._count = AreaHitQueue.BUDGET
	attacker.hit(first, 1.0, true, Tower.NO_CRIT, &"", false)
	_check(queue.pending() == 1, "effect hit can wait in the area queue")
	queue._process(0.0)
	_check(absf((100000 - first.health) - plain) <= 1.0, "queued ground effect preserves its effect flag and cannot gain Clear Minds")

	dreams.stacks = {"quickened_sap": 1}
	dreams.bump_board()
	attacker.clear_dream_cache()
	var normal := attacker.get_attacks_per_second()
	attacker.note_primary_target(first)
	_check(not attacker.turnover_active(), "first primary target is not a switch")
	attacker.note_primary_target(second)
	_check(is_equal_approx(attacker.get_attacks_per_second(), normal * 1.35), "a switch activates speed immediately")
	attacker._anim_time += 2.0
	attacker.note_primary_target(second)
	attacker._anim_time += 1.01
	_check(is_equal_approx(attacker.get_attacks_per_second(), normal), "same target does not refresh; expiry invalidates cached speed")
	attacker.note_primary_target(first)
	attacker._anim_time += 2.0
	attacker.note_primary_target(second)
	_check(is_equal_approx(attacker.get_attacks_per_second(), normal * 1.35), "another switch refreshes rather than stacks speed")
	dreams.stacks["quickened_sap_ii"] = 1
	dreams.bump_board()
	attacker.note_primary_target(first)
	attacker._anim_time += 3.1
	_check(attacker.turnover_active(), "II replaces the base with a five-second duration")
	attacker._anim_time += 1.91
	_check(not attacker.turnover_active(), "Deepened duration expires normally")

	dreams.stacks = {"longer_roots": 1}
	dreams._path_index = {attacker.cell + Vector2(1, 1): 0}
	dreams.board_version += 1
	attacker.clear_dream_cache()
	_check(is_equal_approx(attacker.get_range_cells(), attacker.attack_data.attack_range), "diagonal route adjacency prevents back-row range")
	dreams._path_index.clear()
	dreams.board_version += 1
	attacker.clear_dream_cache()
	_check(is_equal_approx(attacker.get_range_cells(), attacker.attack_data.attack_range + 1.0), "back row gains one range")
	_check(is_equal_approx(dreams.get_range_bonus_at(attacker.tower_data, attacker.cell), 1.0), "planting preview uses the same back-row rule")

	var a := _plant("sprout", Vector2(85, 85))
	var b := _plant("sprout", Vector2(86, 86))
	dreams.stacks = {"sprout_chorus": 1}
	dreams._path_index = {Vector2(84, 85): 0, Vector2(85, 84): 1}
	dreams.board_version += 1
	var rows := dreams.get_card_effects(a.tower_data, a.cell, a)
	_check(rows.any(func(row: Dictionary) -> bool: return row.id == "sprout_chorus" and row.active and is_equal_approx(row.speed, 0.3)), "Thicket needs a touching Sprout and two distinct route cells")
	dreams._path_index.erase(Vector2(85, 84))
	dreams.board_version += 1
	_check(not dreams.get_card_effects(a.tower_data, a.cell, a).any(func(row: Dictionary) -> bool: return row.id == "sprout_chorus" and row.active), "one route cell is not enough for Thicket")

	dreams.stacks = {"switchback": 1}
	dreams._game_clock = 10.0
	first.statuses = EnemyStatuses.new()
	dreams.switchback_at(first, attacker.cell)
	_check(is_equal_approx(first.statuses.slow_amount, 0.25) and is_equal_approx(first.statuses.slow_time, 1.0), "covered bend crossing slows the nightmare")
	first.statuses.slow_time = 0.0
	dreams.switchback_at(first, attacker.cell)
	_check(is_zero_approx(first.statuses.slow_time), "overlapping coverage cannot refresh within cooldown")
	dreams._game_clock = 13.0
	dreams.switchback_at(first, attacker.cell)
	_check(is_equal_approx(first.statuses.slow_time, 1.0), "another bend can trigger after three seconds")

	dreams.stacks.clear()
	dreams.build_run_pool(424242)
	for id in ["deeper_calm", "quickened_sap", "longer_roots"]:
		_check(dreams.run_pool.has(id), "core inclusion retained: " + id)
	for card in dreams.pool:
		if card.retired:
			_check(not dreams.can_offer(card, 4) and not dreams.run_pool.has(card.id), "retired II absent from offers and core: " + card.id)
	dreams.stacks = {"specialist": 1}
	dreams.run_pool.clear()
	dreams.tag_weight = 10.0
	dreams._rng.seed = 424242
	var in_build: UpgradeData = load("res://resource/dream/old_growth.tres")
	var outside: UpgradeData = load("res://resource/dream/menagerie.tres")
	var in_count := 0
	for i in 1000:
		if dreams._weighted_pick([in_build, outside], true) == in_build:
			in_count += 1
	_check(in_count > 400 and in_count < 600, "Stray keeps randomness without penalizing build tags")
	dreams.tag_weight = 1.0
	first.free()
	second.free()
	a.free()
	b.free()

# Special branch releases must use the selected primary, not an echo or a secondary cone/jet hit.
func _special_turnover() -> void:
	for id in ["jetreed", "silver_bell", "thrum"]:
		dreams.stacks = {"quickened_sap": 1}
		dreams.bump_board()
		var tower := _plant(id, Vector2(80, 80))
		var first := _spawn(tower.cell + Vector2(1, 0))
		var second := _spawn(tower.cell + Vector2(1, 0))
		second.health = 80000
		second.max_health = 80000
		tower._release()
		_check(not tower.turnover_active(), id + ": first primary does not activate turnover")
		first.is_cleansed = true
		tower._release()
		_check(tower.turnover_active(), id + ": actual special primary switch activates turnover")
		first.free()
		second.free()
		tower.free()

func _canopy_milestones() -> void:
	for tower in main.get_node("%TowerContainer").get_children():
		tower.free()
	dreams.stacks = {"canopy": 1}
	dreams._canopy_peak = 0
	dreams.bump_board()
	for i in 45:
		var recycled := _plant("sprout", Vector2(80, 80))
		dreams._on_tower_built(recycled)
		recycled.free()
	_check(dreams.canopy_steps_reached() == 0, "Canopy: recycled plants earn no permanent legacy milestones")
	var attackers: Array[Tower] = []
	for i in 40:
		attackers.append(_plant("sprout", Vector2(80 + i, 80)))
	dreams._on_drift_started(1)
	_check(dreams.canopy_steps_reached() == 0, "Canopy: drift start no longer awards numerical milestones")
	_check(is_equal_approx(dreams.get_soothe_multiplier(attackers[0]), 1.0), "Canopy: a large connected board grants no passive damage")
	_check(is_zero_approx(dreams.get_tower_range_bonus(attackers[0])), "Canopy: a connected board needs six recent distinct living targets for reach")
	var targets: Array[Node2D] = []
	for i in 6:
		var enemy := _spawn(attackers[0].cell)
		targets.append(enemy)
		attackers[0].hit(enemy, 1.0, false, Tower.NO_CRIT)
		_check(is_equal_approx(dreams.get_tower_range_bonus(attackers[0]), 1.0 if i == 5 else 0.0), "Canopy: only six actual distinct living hits activate connected reach")
	dreams._game_clock += 3.1
	dreams._update_canopy_roles()
	_check(is_zero_approx(dreams.get_tower_range_bonus(attackers[0])), "Canopy: actual-hit reach expires after three seconds")
	for enemy in targets:
		enemy.free()
	# Old saves keep their field readable, but it cannot turn into old or permanent bonuses.
	dreams._canopy_peak = 40
	var saved := dreams.to_save()
	_check(int(saved.get("canopy_peak", -1)) == 40, "Canopy: legacy save field remains readable")
	dreams._role_recent[attackers[0].get_instance_id()] = {123: [null, 0.0]}
	dreams._role_relay[attackers[0].get_instance_id()] = {124: true}
	dreams._role_canopy_on[attackers[0].get_instance_id()] = true
	dreams.load_save(saved)
	_check(dreams._canopy_peak == 40, "Canopy: loading preserves the legacy field")
	_check(dreams._role_recent.is_empty() and dreams._role_relay.is_empty() and dreams._role_canopy_on.is_empty(), "Load clears role target histories, relay partial cycles and temporary reach")
	_check(is_equal_approx(dreams.get_soothe_multiplier(attackers[0]), 1.0), "Canopy: loaded legacy peak grants no numerical damage")
	_check(is_zero_approx(dreams.get_tower_range_bonus(attackers[0])), "Canopy: loaded legacy peak grants no permanent range")
	for tower in attackers:
		tower.free()

func _remaining_design_fixes() -> void:
	for tower in main.get_node("%TowerContainer").get_children():
		tower.free()
	dreams.stacks.clear()
	dreams.grove_cards.assign(["the_quiet_ones", "monoculture"])
	var quiet: UpgradeData = load("res://resource/dream/the_quiet_ones.tres")
	for i in 3:
		_plant("thornwall", Vector2(80 + i, 80))
	_check(not dreams.can_offer(quiet, 2), "Quiet Ones: plain walls cannot satisfy the prerequisite")
	for i in 2:
		_plant("honeysuckle", Vector2(80 + i, 82))
	_check(not dreams.can_offer(quiet, 2), "Quiet Ones: two benefiting walls are insufficient")
	var scent := _plant("honeysuckle", Vector2(82, 82))
	_check(dreams.can_offer(quiet, 2), "Quiet Ones: three benefiting walls qualify")
	var speed := scent.get_attacks_per_second()
	dreams.take(quiet)
	_check(is_equal_approx(scent.get_attacks_per_second(), speed * 1.5), "Quiet Ones: qualifying scent actually benefits")
	for tower in main.get_node("%TowerContainer").get_children():
		tower.free()
	dreams.stacks.clear()
	var spore := _plant("sporeling", Vector2(80, 80))
	var sprout := _plant("sprout", Vector2(82, 80))
	var baseline := dreams.get_soothe_multiplier(spore)
	var sprout_baseline := dreams.get_soothe_multiplier(sprout)
	dreams.take(load("res://resource/dream/monoculture.tres"))
	_check(dreams.is_monoculture(), "Monoculture: Sprouts do not break a single other line")
	_check(is_equal_approx(dreams.get_soothe_multiplier(spore), baseline + 1.0), "Monoculture: non-Sprout line receives bonus")
	_check(is_equal_approx(dreams.get_soothe_multiplier(sprout), sprout_baseline), "Monoculture: Sprouts receive no bonus")
	var water := _plant("dewdrop", Vector2(84, 80))
	_check(not dreams.is_monoculture() and is_equal_approx(dreams.get_soothe_multiplier(spore), baseline), "Monoculture: second non-Sprout line breaks bonus")
	water.free()
	spore.free()
	_check(not dreams.is_monoculture(), "Monoculture: Sprouts alone are not a qualifying line")
	var guide: UpgradeData = load("res://resource/dream/guiding_light.tres")
	dreams.unlocked["firefly_jar"] = true
	dreams.unlocked["lanternmoth"] = true
	_plant("lanternmoth", Vector2(86, 80))
	dreams.stacks.erase("cozy_corners")
	_check(dreams.can_offer(guide, 2), "Guiding Light: Lanternmoth qualifies without Cozy Corners")

func _impatient_overlap() -> void:
	for tower in main.get_node("%TowerContainer").get_children():
		tower.free()
	var attacker := _plant("sporeling", Vector2(80, 80))
	dreams.stacks.clear()
	dreams.bump_board()
	var baseline := attacker.get_damage()
	dreams.take(load("res://resource/dream/restless_night.tres"))
	var director: DriftDirector = main.get_node("%DriftDirector")
	var old_active := director._active.duplicate(true)
	var old_sources := director._drift_of.duplicate()
	director._active = {}
	director._drift_of = {}
	var data: EnemyData = TestGrove._load_enemy_types()[0]
	var enemies: Array[Node2D] = []
	for number in [2, 3, 4, 5]:
		director._active[number] = {"remaining": 0, "arriving": true, "leaked": false, "called_early": number != 3}
		_check(is_equal_approx(attacker.get_damage(), baseline * (1.4 if number == 5 else 1.0)), "Impatient Night: scheduled drifts alone do not activate the bonus")
		director._spawn(data, number)
		var enemy: Node2D = director._drift_of.keys().filter(func(e: Node2D) -> bool: return director._drift_of[e] == number)[0]
		enemies.append(enemy)
		_check(is_equal_approx(attacker.get_damage(), baseline * (1.4 if number >= 4 else 1.0)), "Impatient Night: only distinct early-called drifts count, without stacking")
	# Ending one of three early-called drifts retains the bonus; ending another removes it.
	director._resolve(enemies[0], false)
	_check(is_equal_approx(attacker.get_damage(), baseline * 1.4), "Impatient Night: two early-called drifts remain")
	director._resolve(enemies[2], false)
	_check(is_equal_approx(attacker.get_damage(), baseline), "Impatient Night: damage cache loses bonus immediately when overlap ends")
	for enemy in enemies:
		enemy.free()
	director._active = old_active
	director._drift_of = old_sources
	dreams.bump_board()

func _council_corrections() -> void:
	for tower in main.get_node("%TowerContainer").get_children():
		tower.free()
	dreams.stacks.clear()
	var old_unlocked := dreams.unlocked.duplicate()
	var old_offer := dreams._offer_drift
	dreams.unlocked = {"firefly_jar": true, "stormcap": true}
	var woven: UpgradeData = load("res://resource/dream/eye_of_the_tempest.tres")
	dreams._offer_drift = 60
	_check(dreams.half_dreamed_missing(woven).is_empty(), "Half-Dreamed: two missing families with one pick left is impossible")
	dreams._offer_drift = 35
	_check(dreams.half_dreamed_missing(woven).size() == 2, "Half-Dreamed: two remaining picks preserve the two-family gamble")
	dreams._offer_drift = 60
	dreams.unlocked["dewdrop"] = true
	_check(dreams.half_dreamed_missing(woven).size() == 1, "Half-Dreamed: one missing family and one pick remains speculative")
	dreams.unlocked = old_unlocked
	dreams._offer_drift = old_offer
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var sprout: TowerData = load("res://resource/tower/sprout.tres")
	for i in placer.sprout_per_step():
		var planted := _plant("sprout", Vector2(80 + i, 80))
		planted.invested_dew = sprout.cost
		planted.plant_dew = sprout.cost
	var cell := Vector2(80, 84)
	var full_price := placer.get_cost(sprout, cell)
	dreams.run_state.fertile_cells[cell] = true
	_check(placer.get_cost(sprout, cell) == roundi(full_price * DreamState.FERTILE_DISCOUNT), "Reclaimed Earth: final Sprout price including escalation is halved")
	_check(dreams.get_stat_parts(sprout, cell, "cost").final == placer.get_cost(sprout, cell), "Reclaimed Earth: ghost price matches final planting price")
	dreams.run_state.sprout_charges = 1
	_check(placer.get_cost(sprout, cell) == 0, "Reclaimed Earth: free charge remains free")
	dreams.run_state.sprout_charges = 0
	dreams.run_state.fertile_cells.erase(cell)
	var attacker := _plant("sporeling", Vector2(80, 86))
	var enemy := _spawn(attacker.cell)
	dreams.stacks = {"called_shot": 1, "shattering_blow": 1}
	dreams.bump_board()
	enemy.apply_status(EnemyStatuses.MARKED, 10, 10.0, 0.0)
	enemy.statuses.pinned = true
	_check(not attacker.hit(enemy, 1.0, true, Tower.NO_CRIT, &"cloud"), "Cloud tick cannot crit through Called Shot or Pinned")
	_check(enemy.statuses.pinned, "Cloud tick preserves hit-only Pinned reaction")
	_check(enemy.statuses.has(EnemyStatuses.SPORED), "Cloud still applies native Warden statuses")
	_check(dreams.called_shot(attacker, enemy), "Cloud tick does not consume Called Shot's direct-hit opportunity")
	enemy.statuses = EnemyStatuses.new()
	enemy.apply_status(EnemyStatuses.SPORED, 11, 10.0, 1.0)
	enemy.apply_status(EnemyStatuses.STATIC, 8, 10.0, 1.0)
	attacker.hit(enemy, 1.0, true, Tower.NO_CRIT, &"cloud", false)
	_check(enemy.statuses.burn_time > 0.0, "Cloud's native status application can still trigger Ignite")
	enemy.free()
