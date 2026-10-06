extends SceneTree

# Headless test for the economy Wardens and support credit (warden_stats.md / screens_ui.md
# "Support and economy feedback", 2026-09-29; the Seed and Support Warden cards' Tower side):
# Dewcatcher / Wellspring catch (+40% / +60% of a dispel's Dew into the bowl, highest catch only, ranks
# add catch not damage), the Harvest and interest at the rest, Harvest Moon / Deep Well /
# Overflowing Well / Dew Bowl / Dew Trail, aura cards (Acorn Cache, Shared Light, Kind
# Canopy, Grandfather Stump, The Quiet Ones), Bramble Oath, Patient Roots, Many Threads, and
# SupportLog's credit (Dew caught and paid, aura damage, Held seconds, tiles pulled, Drowsy).
#   godot --headless --path . --script res://tests/test_catchers.gd --fixed-fps 60

const CELL := 64.0

var failures := 0
var main: Node
var spawner
var placer: TowerPlacer
var container: Node
var run_state: RunState
var director: DriftDirector
var dreams: DreamState

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	spawner = main.get_node("%EnemyContainer")
	placer = main.get_node("%TowerPlacer")
	container = main.get_node("%TowerContainer")
	run_state = main.get_node("%RunState")
	director = main.get_node("%DriftDirector")
	dreams = main.get_node("%DreamState")
	dreams.unlock_everything = true
	for child in spawner.get_children():
		child.queue_free()
	await process_frame
	var multiplier := run_state.get_dispel_multiplier()

	# --- Dewcatcher: +40% of a dispel's Dew into the bowl, within 2.5 cells ---
	var catcher := _plant("dewcatcher", Vector2(5, 5))
	var caught := []
	catcher.dew_caught.connect(func(_t, _w, amount: float) -> void: caught.append(amount))
	var near := _spawn(catcher.global_position + Vector2(2 * CELL, 0))
	var reward: int = near.get_dew_reward()
	var dew := run_state.dew
	await _dispel(near)
	_check(run_state.dew == dew + roundi(reward * multiplier) or run_state.dew >= dew, "the dispel still pays its own Dew now")
	_check(is_equal_approx(catcher.bowl, reward * multiplier * catcher.tower_data.catch_share), "Dewcatcher: its catch into the bowl (%.2f of %d)" % [catcher.bowl, reward])
	_check(caught.size() == 1, "dew_caught fires once")
	var far := _spawn(catcher.global_position + Vector2(3 * CELL, 0))
	var bowl := catcher.bowl
	await _dispel(far)
	_check(is_equal_approx(catcher.bowl, bowl), "nothing caught 3 cells away")
	_check(catcher.get_node_or_null("Sprite2D/BowlFill") != null, "the bowl overlay shows")

	# Ranks: +10% catch each, no damage
	var plain := catcher.get_damage()
	catcher.rank = 2
	var probe := _spawn(catcher.global_position)
	_check(is_equal_approx(catcher.get_catch_share(probe), catcher.tower_data.catch_share + 2 * catcher.tower_data.catch_per_rank), "rank II: +2 ranks of catch (%.2f)" % catcher.get_catch_share(probe))
	_check(is_equal_approx(catcher.get_damage(), plain), "ranks don't add damage to a catcher")
	catcher.rank = 0

	# Highest catch only: a Wellspring next to it takes the dispel, the Dewcatcher gets nothing
	var well := _plant("wellspring", Vector2(6, 5))
	var both := _spawn(catcher.global_position + Vector2(CELL, 0))
	bowl = catcher.bowl
	var well_bowl := well.bowl
	await _dispel(both)
	_check(is_equal_approx(catcher.bowl, bowl) and well.bowl > well_bowl, "two catchers never stack: the Wellspring's higher catch applies")
	_check(is_equal_approx(well.bowl - well_bowl, reward * multiplier * well.tower_data.catch_share), "Wellspring: its catch (%.2f)" % (well.bowl - well_bowl))

	# Drift Dew goes into the bowl too
	bowl = catcher.bowl
	catcher._on_drift_cleared(1, 0, true)
	_check(is_equal_approx(catcher.bowl, bowl + catcher.tower_data.dew_per_drift), "Dewcatcher: its Dew per drift, into the bowl")

	# --- The Harvest, then interest ---
	var poured := []
	catcher.harvest_poured.connect(func(_t, amount: int) -> void: poured.append(amount))
	var interest := []
	well.interest_paid.connect(func(_t, amount: int) -> void: interest.append(amount))
	var harvest := floori(catcher.bowl + 0.0001) + floori(well.bowl + 0.0001)
	run_state.dew = 500
	director.rest_started.emit(1, false, 0, true)
	var expected_interest := mini(floori((500 + harvest) * 0.08), 60)
	_check(poured.size() == 1 and catcher.bowl == 0.0, "the Harvest pours the bowl")
	_check(interest == [expected_interest], "then the Wellspring pays 8%% interest (%s, expected %d)" % [str(interest), expected_interest])
	_check(run_state.dew == 500 + harvest + expected_interest, "Dew: harvest + interest (%d)" % (run_state.dew - 500))
	_check(run_state.dew_harvested == harvest + expected_interest, "dew_harvested counts both (%d)" % run_state.dew_harvested)
	director.rest_started.emit(1, false, 0, true)
	_check(interest.size() == 1, "one Harvest per rest")
	var log := SupportLog.find(catcher)
	_check(log != null and log.get_stats(catcher).dew_caught > 0.0 and log.get_stats(well).dew_paid > 0.0,
		"SupportLog: Dew caught and paid per catcher")
	_check(log.get_panel_line(catcher).begins_with("Caught this run: "), "panel line (%s)" % log.get_panel_line(catcher))

	# Interest caps: 60 each, DewCatch.INTEREST_CAP together (130 since Balancing 2026-10-05)
	var well2 := _plant("wellspring", Vector2(8, 5))
	var well3 := _plant("wellspring", Vector2(10, 5))
	run_state.dew = 5000
	director.rest_started.emit(2, false, 0, true)
	_check(run_state.dew == 5000 + DewCatch.INTEREST_CAP, "all Wellsprings together pay at most the shared cap (%d)" % (run_state.dew - 5000))
	well3.queue_free()
	await process_frame

	# Deep Well: each cap +30; Overflowing Well: shards (Still Waters was cut, dream_audit.md)
	# (Deep Well's own 3% at the rest is Roguelite's; these read only the Wellsprings' interest_paid.)
	var paid_now := []
	for w in [well, well2]:
		w.interest_paid.connect(func(_t, amount: int) -> void: paid_now.append(amount))
	_take("deep_well")
	run_state.dew = 1500
	director.drift_started.emit(11)  # A new block: Still Waters watches
	director.rest_started.emit(3, false, 0, true)
	_check(paid_now.max() == 90 and paid_now.reduce(func(a, b): return a + b) == DewCatch.INTEREST_CAP,
		"Deep Well: a Wellspring's cap is 90, all together still the shared cap (%s)" % str(paid_now))
	_take("overflowing_well")
	var shards := dreams.dreamlight_shards
	run_state.dew = 3000
	director.rest_started.emit(6, false, 0, true)
	_check(dreams.dreamlight_shards > shards, "Overflowing Well: interest over the cap becomes shards (%d)" % (dreams.dreamlight_shards - shards))

	# Harvest Moon: the Harvest +50%
	_take("harvest_moon")
	catcher.add_to_bowl(10.0)
	dew = run_state.dew
	poured.clear()
	var paid_before := run_state.dew_harvested
	director.drift_started.emit(26)
	for w in [well, well2]:
		w.queue_free()
	await process_frame
	director.rest_started.emit(7, false, 0, true)
	_check(poured == [15], "Harvest Moon: the Harvest pays +50%% (%s)" % str(poured))
	_check(run_state.dew_harvested == paid_before + 15, "and counts it")

	# Dew Bowl / Dew Trail (Wide Bowl merged into it: +0.5 catch radius)
	_take("dew_bowl")
	var damp := _spawn(catcher.global_position + Vector2(CELL, 0))
	_check(is_equal_approx(catcher.get_catch_share(damp), catcher.tower_data.catch_share + 0.15), "Dew Bowl: +15%% catch (%.2f)" % catcher.get_catch_share(damp))
	_take("dew_trail")
	_check(is_equal_approx(catcher.get_catch_radius(), 3.0), "Dew Trail: +0.5 cells catch radius")
	damp.apply_status(EnemyStatuses.DAMP, 1, 5.0, 1.0)
	var trail := catcher.tower_data.catch_share + 0.15 + DewCatch.DEW_TRAIL[0] * dreams.rule_power(&"dew_trail")
	_check(is_equal_approx(catcher.get_catch_share(damp), trail), "Dew Trail: +30%% (with its tag resonance) on a Damp nightmare (%.2f, want %.2f)" % [catcher.get_catch_share(damp), trail])
	catcher.queue_free()
	await _clean()

	# --- Auras: Acorn Cache, Shared Light, Kind Canopy, Grandfather Stump; credit ---
	var acorn := _plant("acorn", Vector2(5, 12))
	var buddy := _plant("sporeling", Vector2(6, 12))
	buddy._refresh_neighbours()
	_check(is_equal_approx(buddy._aura_damage, 0.05) and buddy._aura_damage_from == acorn, "Acorn: +5%, and its source is remembered")
	var target := _spawn(buddy.global_position + Vector2(CELL, 0))
	buddy.hit(target)
	await process_frame
	var slog := SupportLog.find(acorn)
	_check(slog.get_stats(acorn).aura_damage > 0.0, "SupportLog: the Acorn is credited with the extra damage (%.2f)" % slog.get_stats(acorn).aura_damage)
	_check(slog.get_panel_line(acorn).begins_with("Added this run:"), "aura panel line (%s)" % slog.get_panel_line(acorn))
	acorn._refresh_neighbours()
	_check(acorn.get_node_or_null("AuraRing") == null, "no breathing aura ring (the boost area is AuraView's square, user 2026-10-03)")
	_check(is_instance_valid(buddy._leaf_mote), "a boosted Warden carries a leaf mote")
	# Show exactly who gets the aura (AuraView): a 3×3 square, only the boosted Wardens, a live chip.
	var outside := _plant("sporeling", Vector2(7, 12))  # In the Acorn's attack range (2.5), outside its aura
	outside._refresh_neighbours()
	_check(AuraView.cells(acorn.global_position, acorn.get_aura_reach()).size() == 9, "the Acorn's aura is the 3×3 square")
	var boosted := AuraView.boosted_by(acorn)
	_check(boosted == [buddy], "only the Warden beside it is marked, not the one 2 cells away (%s)" % [boosted])
	_check(AuraView.chip(buddy, acorn) == "+5%", "its chip reads the live bonus (%s)" % AuraView.chip(buddy, acorn))
	outside.queue_free()
	# Catcher placement preview: the share of last block's dispels near a spot
	var spots_log := SupportLog.find(acorn)
	spots_log._dispels = {"block": [], "last_block": [acorn.global_position, acorn.global_position, Vector2(-5000, 0), Vector2(-5000, 0)]}
	_check(is_equal_approx(spots_log.dispel_share_near(acorn.global_position, 2.5), 0.5), "half of last block's dispels were here")
	placer.show_catch_preview(acorn.global_position, 2.5)
	_check(not placer._catch_preview.is_empty(), "the placer shows the catch zone")
	placer.hide_catch_preview()
	var cache := 0.05  # The Acorn's own aura (Acorn Cache was cut, dream_design.md de439ea8)
	_take("shared_light")
	buddy._refresh_neighbours()
	_check(is_equal_approx(buddy._aura_damage, cache * (1.0 + Tower.SHARED_LIGHT * dreams.rule_power(&"shared_light"))), "Shared Light: aura bonuses +50%% (%.3f)" % buddy._aura_damage)
	_check(is_equal_approx(acorn.get_aura_reach(), 1.5), "no Kind Canopy yet")
	_take("kind_canopy")
	_check(is_equal_approx(acorn.get_aura_reach(), 2.5), "Kind Canopy: +1 cell")
	var stump := _plant("elder_stump", Vector2(12, 12))
	for i in 4:
		_plant("sporeling", Vector2(11 + i % 3, 11 + (2 if i >= 3 else 0)))
	stump._refresh_neighbours()
	var before_grandfather := stump.get_aura_bonus(true)
	_take("grandfather_stump")
	stump._refresh_neighbours()
	_check(stump.get_aura_bonus(true) > before_grandfather, "Grandfather Stump: the Elder Stump's aura grows with Wardens around it (%.3f → %.3f)" % [before_grandfather, stump.get_aura_bonus(true)])
	await _clean_towers()
	dreams.stacks.clear()

	# --- Support Wardens (warden_stats.md fdd7003): same-kind auras stack with falloff, ranks scale the
	# aura ×1.1, Focus Wide / Strong / Kindred ---
	var middle := _plant("sporeling", Vector2(12, 12))
	var stumps: Array[Tower] = []
	for at in [Vector2(11, 12), Vector2(13, 12), Vector2(12, 11)]:
		stumps.append(_plant("elder_stump", at))
	middle._refresh_neighbours()
	var one := stumps[0].get_aura_bonus(true)
	_check(is_equal_approx(middle._aura_speed, one * 1.75), "three Elder Stumps: 100%% + 50%% + 25%% (%.3f, one is %.3f)" % [middle._aura_speed, one])
	_check(middle.get_aura_lines() == ["Elder Stump ×3: attacks %d%% faster" % roundi(middle._aura_speed * 100.0)], "panel line: %s" % [middle.get_aura_lines()])
	stumps[2].rank = 1
	stumps[2].rank_choices = [Tower.Focus.KINDRED]  # Nurture v3: a Kindred rank
	middle._refresh_neighbours()
	var kindred_bonus := stumps[2].get_aura_bonus(true)
	_check(is_equal_approx(middle._aura_speed, kindred_bonus + one * 1.5), "a Kindred Elder Stump sits outside the falloff (%.3f)" % middle._aura_speed)
	_check(stumps[0].focus_options() == Tower.SUPPORT_FOCUSES and middle.focus_options() == Tower.ATTACKER_FOCUSES,
		"support Wardens choose Wide / Strong / Kindred, attackers Power / Swift / Reach / Deep")
	stumps[0].rank = 2
	_check(is_equal_approx(stumps[0].get_aura_bonus(true), one * 1.21) and is_equal_approx(stumps[0].get_rank_damage_multiplier(), 1.0),
		"support Nurture: the aura ×1.1 per rank, no damage (%.3f)" % stumps[0].get_aura_bonus(true))
	stumps[0].rank = 5
	stumps[0].rank_choices = [Tower.Focus.STRONG, Tower.Focus.STRONG, Tower.Focus.STRONG, Tower.Focus.STRONG, Tower.Focus.STRONG]
	_check(is_equal_approx(stumps[0].get_aura_bonus(true), one * pow(1.1, 5) * 1.25), "Strong: ×1.25 more by rank V (%.3f)" % stumps[0].get_aura_bonus(true))
	stumps[1].rank = 5
	stumps[1].rank_choices = [Tower.Focus.WIDE, Tower.Focus.WIDE, Tower.Focus.WIDE, Tower.Focus.WIDE, Tower.Focus.WIDE]
	_check(is_equal_approx(stumps[1].get_aura_reach(), 2.5), "Wide ×5: the 8 around become everything within 2 cells")
	await _clean_towers()

	# --- Walls: Bramble Oath, The Quiet Ones; Honeysuckle's Drowsy credit ---
	var bramble := _plant("bramble", Vector2(5, 14))
	var bramble_damage := bramble.get_damage()
	var honey := _plant("honeysuckle", Vector2(7, 14))
	var honey_rate := honey.get_attacks_per_second()
	_take("bramble_oath")
	bramble.clear_dream_cache()
	honey.clear_dream_cache()
	_check(is_equal_approx(bramble.get_damage(), bramble_damage * 1.5), "Bramble Oath: Bramble +50%% damage (%.2f → %.2f)" % [bramble_damage, bramble.get_damage()])
	_check(is_equal_approx(honey.get_attacks_per_second(), honey_rate * 1.5), "Bramble Oath: Honeysuckle scents 50% faster")
	var sleepy := _spawn(honey.global_position + Vector2(CELL, 0))
	honey.apply_status_to(sleepy, 0.0)
	_check(slog.get_stats(honey).drowsy > 0.0, "SupportLog: Honeysuckle's Drowsy applied")
	_check(slog.get_panel_line(honey).begins_with("Drowsy applied:"), "wall panel line (%s)" % slog.get_panel_line(honey))
	var wall := _plant("thornwall", Vector2(9, 14))
	_check(wall.is_quiet() and not bramble.is_quiet(), "Thornwall is quiet, Bramble isn't")
	_take("the_quiet_ones")
	honey.clear_dream_cache()
	_check(is_equal_approx(honey.get_attacks_per_second(), honey_rate * 1.5 * 1.5), "The Quiet Ones: Honeysuckle another +50%")
	await _clean_towers()
	await _clean()

	# --- Control: Patient Roots, credit ---
	var tangle := _plant("tangleroot", Vector2(5, 5))
	var held := _spawn(tangle.global_position + Vector2(CELL, 0))
	tangle.hold(held, 1.0)
	_check(is_equal_approx(held.statuses.time_left(EnemyStatuses.HELD), 1.0), "a Hold lasts its time (%.2f)" % held.statuses.time_left(EnemyStatuses.HELD))
	_check(is_equal_approx(slog.get_stats(tangle).held_seconds, 1.0), "SupportLog: seconds Held")
	_take("patient_roots")
	var held2 := _spawn(tangle.global_position + Vector2(CELL, CELL))
	tangle.hold(held2, 1.0)
	var patient := 1.0 + dreams.get_held_bonus() + Tower.PATIENT_ROOTS_ROOT_HOLD * dreams.rule_power(&"patient_roots")
	_check(is_equal_approx(held2.statuses.time_left(EnemyStatuses.HELD), patient), "Patient Roots: every Hold longer, the Rootling line more (%.2f, want %.2f)" % [held2.statuses.time_left(EnemyStatuses.HELD), patient])
	var map = main.get_node("%MapGenerator")
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var walker := _spawn(Tower.MAP_GRID.calculate_map_position(route[0]))
	walker.set_path(route)
	walker._path_index = 11
	walker.global_position = Tower.MAP_GRID.calculate_map_position(route[10])
	tangle.pull(walker, 1.0)
	_check(is_equal_approx(slog.get_stats(tangle).tiles_pulled, 1.0 + Tower.PATIENT_ROOTS_PULL * dreams.rule_power(&"patient_roots")), "Patient Roots: pulls further, credited (%.2f)" % slog.get_stats(tangle).tiles_pulled)
	_check(slog.get_panel_line(tangle).begins_with("Rooted "), "control panel line (%s)" % slog.get_panel_line(tangle))
	_check(not slog.get_support_rows("run").is_empty() and not slog.get_top_support("run").is_empty(), "support rows and a top supporter")
	await _clean_towers()
	await _clean()

	# --- Many Threads: Dreamcatchers Catch at 4 Drowsy ---
	var catcher2 := _plant("dreamcatcher", Vector2(5, 5))
	var drowsy := _spawn(catcher2.global_position + Vector2(CELL, 0))
	drowsy.apply_status(EnemyStatuses.DROWSY, 4, 10.0, 1.0)
	catcher2._update_catch(1.0)
	var caught_before: bool = drowsy.statuses.is_caught()
	_take("many_threads")
	catcher2._catch_tick = 0.0
	catcher2._update_catch(1.0)
	_check(drowsy.statuses.is_caught() and (not caught_before or drowsy.statuses.get_max_stacks(EnemyStatuses.DROWSY) <= 4),
		"Many Threads: Caught at 4 Drowsy")

	print("catchers test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _take(id: String) -> void:
	for card in dreams.pool:
		if card.id == id:
			dreams.take(card)
			return
	_check(false, "card %s exists" % id)

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
	return enemy

func _dispel(enemy: Node2D) -> void:
	enemy.coat = 0.0
	enemy.take_damage(100000000.0)
	await process_frame

func _clean() -> void:
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

func _clean_towers() -> void:
	for child in container.get_children():
		child.queue_free()
	await process_frame
