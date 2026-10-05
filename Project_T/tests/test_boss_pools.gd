extends SceneTree

# Headless test for boss pools (enemy_design.md, "Bosses: a pool of 3 per act", "The Hollow Oak's
# three variations"): the pools and the draw, the draw replacing the boss drifts, and each new boss's
# ability (Night Mare laps, Scarecrow crows, Huntsman's pack, Lamplighter's lanterns, Barrow King's
# shrug, Mourning Mother's Sorrow, Withering and Remembering Oak).
#   godot --headless --path . --script res://tests/test_boss_pools.gd --fixed-fps 60

const DAMAGE_LINES := ["spore", "stone", "water", "light", "root", "song", "wing", "wind"]

var failures := 0
var spawner: Node
var map_generator: Node
var tower_container: Node
var placer: TowerPlacer
var director: DriftDirector
var run_state: RunState
var route: PackedVector2Array

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	# --- The pools ---
	for act in range(1, 5):
		var pool := BossPool.get_pool(act)
		_check(pool.size() == 3, "act %d has 3 bosses (%d)" % [act, pool.size()])
		_check(BossPool.get_default(act) != null and BossPool.get_default(act).is_default, "act %d has a default" % act)
		for data in pool:
			var boss := data.boss
			_check(boss.is_boss and data.act == act, "%s is a boss of act %d" % [data.get_id(), act])
			_check(_drift_has(data.drift, boss), "%s's drift brings it" % data.get_id())
			# Its dossier reads fully (like test_acts_3_4's check for the first four)
			_check(boss.title != "" and boss.abilities.size() >= 2 and boss.tips.size() >= 2 and boss.whisper != "",
				"%s has a title, whisper, abilities and tips" % data.get_id())
			for i in boss.abilities.size():
				var ability := boss.get_ability(i)
				_check(not IconInfo.format(ability.text + " " + ability.when).contains("{"), "%s ability %d reads fully" % [data.get_id(), i])
			_check(boss.weak_to.size() == 1 and boss.resists.size() <= 2, "%s: one weakness, at most two resistances" % data.get_id())
			for line in boss.resists + boss.weak_to:  # Damage line ids (TowerData.line), not display names ("wing", never "talon")
				_check(line in DAMAGE_LINES, "%s: \"%s\" is a damage line" % [data.get_id(), line])
	_check(BossPool.get_default(1).get_id() == "hollow_stag", "act 1's default is the Hollow Stag")
	_check(BossPool.get_default(4).get_id() == "hollow_oak_thorned", "act 4's default is the Thorned Oak")

	# --- The draw ---
	var defaults := BossPool.ids(BossPool.draw(123, true))
	_check(defaults == ["hollow_stag", "mire_hag", "moth_queen", "hollow_oak_thorned"], "a first run meets the defaults")
	_check(BossPool.ids(BossPool.draw(99)) == BossPool.ids(BossPool.draw(99)), "the same seed draws the same bosses")
	var seen := {}
	var demo_fixed := true
	for s in 200:
		var drawn := BossPool.draw(s)
		for data in drawn:
			seen[data.get_id()] = true
		var demo := BossPool.ids(BossPool.draw(s, false, true))
		demo_fixed = demo_fixed and demo[0] == "hollow_stag" and demo[1] == "mire_hag"
	_check(seen.size() == 12, "over 200 runs every boss is drawn (%d of 12)" % seen.size())
	_check(demo_fixed, "the demo always meets the Stag and the Hag")
	var repeats := 0
	for s in 600:
		if BossPool.draw(s, false, false, ["night_mare"])[0].get_id() == "night_mare":
			repeats += 1
	_check(repeats > 60 and repeats < 180, "last run's boss is half as likely (%d of 600, ~120)" % repeats)
	_check(BossPool.ids(BossPool.from_ids(["scarecrow", "huntsman", "barrow_king", "hollow_oak_withering"])) \
		== ["scarecrow", "huntsman", "barrow_king", "hollow_oak_withering"], "saved ids come back")

	# --- In a run ---
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 777
	root.add_child(main)
	await process_frame
	await process_frame
	spawner = main.get_node("%EnemyContainer")
	map_generator = main.get_node("%MapGenerator")
	tower_container = main.get_node("%TowerContainer")
	placer = main.get_node("%TowerPlacer")
	director = main.get_node("%DriftDirector")
	run_state = main.get_node("%RunState")
	for tower in tower_container.get_children():
		tower.free()
	route = map_generator.get_path_from(map_generator.startPath)
	_check(BossPool.ids(director.bosses) == defaults, "tests meet the defaults")
	_check(_drift_has(director.drifts[24], load("res://resource/enemy/old_stag.tres")), "drift 25 is the Hollow Stag's")
	director.preset_bosses = ["night_mare", "huntsman", "mourning_mother", "hollow_oak_remembering"]
	director._draw_bosses()
	_check(_drift_has(director.drifts[24], load("res://resource/enemy/night_mare.tres")), "a drawn Night Mare takes drift 25")
	_check(_drift_has(director.drifts[49], load("res://resource/enemy/huntsman.tres")), "a drawn Huntsman takes drift 50")
	_check(_drift_has(director.drifts[74], load("res://resource/enemy/mourning_mother.tres")), "a drawn Mourning Mother takes drift 75")
	_check(_drift_has(director.drifts[99], load("res://resource/enemy/hollow_oak_remembering.tres")), "the Remembering Oak takes drift 100")
	_check(director.get_drawn_boss(2).get_id() == "huntsman", "get_drawn_boss reads the draw")

	# --- Chosen Hunt (Grove node): at an act's start the player picks its boss from the pool ---
	var dossier := main.get_tree().get_first_node_in_group(BossDossier.GROUP) as BossDossier
	_check(dossier != null, "the HUD made the boss dossier")
	if dossier != null:
		BossPool.force_chosen_hunt = true
		var act2_pool := BossPool.get_pool(2)
		_check(dossier.offers_hunt(50), "with Chosen Hunt planted, act 2's start offers the hunt")
		dossier.open_hunt(50)
		var choices := dossier.find_child("HuntChoices", true, false)
		_check(dossier.is_hunting() and choices != null and choices.get_child_count() == act2_pool.size(),
			"it shows the act's whole pool (%d)" % (choices.get_child_count() if choices != null else 0))
		dossier.close_dossier()
		_check(dossier.is_open() and dossier.is_hunting(), "no closing it without a pick")
		var picked: BossData = act2_pool[0] if act2_pool[0].get_id() != "huntsman" else act2_pool[1]
		dossier.choose_hunt(picked)
		_check(director.get_drawn_boss(2) == picked and director.drifts[49] == picked.drift,
			"the pick is act 2's boss and its drift is drift 50 (%s)" % picked.get_id())
		_check(BossPool.ids(director.bosses)[1] == picked.get_id(), "the run save keeps it (bosses)")
		_check(not dossier.is_hunting() and dossier.is_open() and dossier.shown_drift == 50, "then its card opens")
		dossier.close_dossier()
		BossPool.force_chosen_hunt = false
		BossPool.choose(director, 2, BossPool.find(2, "huntsman"))  # Back to the preset draw for the checks below
		_check(not dossier.offers_hunt(50) or BossPool.chosen_hunt_active(), "without the node, the drawn boss comes")

	# --- Hollow Stag (sharpened): charges down straights of 4+ tiles, bellows 6 Husks at half health ---
	var stag := _still("old_stag", route[0])
	var stag_speed: float = stag.get_move_speed()
	stag.set_path(PackedVector2Array([Vector2(1, 1), Vector2(2, 1), Vector2(3, 1), Vector2(4, 1), Vector2(4, 2), Vector2(4, 3), Vector2(5, 3)]))
	stag._path_index = 1
	stag._update_straight_charge()
	_check(stag.straight_charging and is_equal_approx(stag.get_move_speed(), stag_speed * 2.5),
		"a straight of 4 tiles: it charges at 2.5× (%.1f vs %.1f)" % [stag.get_move_speed(), stag_speed])
	stag._path_index = 4
	stag._update_straight_charge()
	_check(not stag.straight_charging, "stops at the turn")
	stag._path_index = 5
	stag._update_straight_charge()
	_check(not stag.straight_charging, "a straight of 3 tiles: no charge")
	var husk_data: EnemyData = load("res://resource/enemy/bark_beetle.tres")
	stag.take_damage(stag.max_health * 0.4)
	_check(_count(husk_data) == 0, "no bellow above half health")
	stag.take_damage(stag.max_health * 0.2)
	_check(_count(husk_data) == 6, "at half health it bellows: 6 Husks (%d)" % _count(husk_data))
	_check(stag._charge_left == 0.0, "no half-health charge any more (the straights replace it)")
	stag.take_damage(stag.max_health * 0.1)
	_check(_count(husk_data) == 6, "once")
	_clear_enemies()

	# --- Act bosses take a flat bite and leave; only the Hollow Oak stays and drains (balance 538b85b7) ---
	var drains := []
	spawner.boss_drained.connect(func(e: Node2D, n: int) -> void: drains.append(n))
	var leaks := [0]
	spawner.enemy_reached_goal.connect(func(_e: Node2D) -> void: leaks[0] += 1)
	var through := _still("old_stag", route[-1])
	through.set_path(PackedVector2Array([route[-1]]))
	var before_leaves := run_state.leaves
	_check(through.get_leaf_cost() == spawner.get_boss_bite(1) and spawner.get_boss_bite(1) == 10
		and spawner.get_boss_bite(2) == 10 and spawner.get_boss_bite(3) == 12, "an act boss bites 10 / 10 / 12 by act")
	through._process(0.016)
	_check(not is_instance_valid(through) or through.is_queued_for_deletion(), "an act boss that gets through is gone")
	_check(run_state.leaves == before_leaves - 10 and leaks[0] == 1 and drains.is_empty(),
		"it takes its bite as a leak (%d → %d, %d leak)" % [before_leaves, run_state.leaves, leaks[0]])
	_clear_enemies()
	var staying_oak := _still("hollow_oak", route[-1])
	staying_oak.set_path(PackedVector2Array([route[-1]]))
	before_leaves = run_state.leaves
	staying_oak._process(0.016)
	staying_oak._process(0.016)
	_check(is_instance_valid(staying_oak) and not staying_oak.is_queued_for_deletion() and staying_oak.at_heartwood,
		"the Hollow Oak that gets through stays at the Heartwood")
	_check(run_state.leaves == before_leaves - 1 and drains == [1], "it takes one leaf at once (%d → %d)" % [before_leaves, run_state.leaves])
	for f in 60:
		staying_oak._process(1.0 / 30.0)  # 2 s
	_check(run_state.leaves == before_leaves - 2 and drains.size() == 2, "and one more every 2 s (%d)" % drains.size())
	var staying_oak_hp: int = staying_oak.health
	staying_oak.take_damage(100.0)
	_check(staying_oak.health < staying_oak_hp and staying_oak.is_in_group(staying_oak.GROUP), "Wardens can still hit it there")
	_clear_enemies()
	run_state.leaves = run_state.max_leaves  # (The bite and the drain above took most of them)

	# --- Night Mare: it lingers at the Heartwood, draining, then laps (10 s, 14 s, 18 s…) ---
	var mare := _still("night_mare", route[-1])
	mare.set_path(PackedVector2Array([route[-1]]))
	var leaves := run_state.leaves
	var mare_speed: float = mare.speed
	mare._process(0.016)  # Arrives
	mare._process(0.016)  # Its first leaf (the frame after it arrives, as for every boss)
	_check(is_instance_valid(mare) and mare.at_heartwood and mare.laps == 0, "the Night Mare stays at the Heartwood")
	_check(run_state.leaves == leaves - 1 and is_equal_approx(mare.linger_left(), 10.0 - 0.016),
		"drains a leaf at once and lingers 10 s (%d → %d, %.2f s)" % [leaves, run_state.leaves, mare.linger_left()])
	var lingering_hp: int = mare.health
	mare.take_damage(500.0)
	mare.apply_status(EnemyStatuses.MARKED, 1, 5.0, 1.0)
	_check(mare.is_untouchable() and not mare.is_in_group(mare.GROUP) and mare.health == lingering_hp
		and mare.statuses.count() == 0, "while it lingers it can't be hit, given statuses or targeted")
	for f in 300:
		mare._process(1.0 / 30.0)
	_check(run_state.leaves == leaves - 5, "5 leaves in its first 10 s (%d → %d)" % [leaves, run_state.leaves])
	_check(not mare.is_untouchable() and mare.is_in_group(mare.GROUP) and mare.sprite.self_modulate.a == 1.0,
		"back on the path it can be hit again")
	_check(mare.laps == 1 and not mare.at_heartwood and is_equal_approx(mare.speed, mare_speed * 1.3),
		"then it goes round again 30% faster")
	_check(mare.get_target_cell() == route[0] or mare.grid.calculate_grid_coordinates(mare.position) == map_generator.startPath,
		"back at the start")
	var shade_data: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	_check(_count(shade_data) == 4, "each lap drops 4 Shades in behind it (%d)" % _count(shade_data))
	_check(spawner.get_children().filter(func(e) -> bool: return e.enemy_data == shade_data)[0]._bar_offset.y == -38.0, "an everyday nightmare keeps its bar at the usual -38")
	var mare_start: Vector2 = mare.grid.calculate_map_position(map_generator.startPath)
	var lined_up := true
	for shade in spawner.get_children().filter(func(e) -> bool: return e.enemy_data == shade_data):
		lined_up = lined_up and shade.position.distance_to(mare_start) <= 4.5 * spawner.SPLIT_SPACING + 1.0 \
			and shade._path[0] == route[0]
	_check(lined_up, "lined up behind the start, walking the maze")
	var after_first := run_state.leaves
	mare.position = mare.grid.calculate_map_position(route[-1])
	mare.set_path(PackedVector2Array([route[-1]]))
	mare._process(0.016)
	mare._process(0.016)
	_check(mare.at_heartwood and is_equal_approx(mare.linger_left(), 14.0 - 0.016), "its second visit lingers 14 s (%.2f)" % mare.linger_left())
	for f in 420:
		mare._process(1.0 / 30.0)
	_check(mare.laps == 2 and run_state.leaves == after_first - 7, "7 leaves on its second visit (%d → %d)" % [after_first, run_state.leaves])
	mare.take_damage(mare.max_health * 0.55)
	_check(mare._charge_left > 0.0, "it bolts at half health")
	_clear_enemies()

	# --- Scarecrow: crows at every 20% ---
	var crow_data: EnemyData = load("res://resource/enemy/crow.tres")
	var scarecrow := _still("scarecrow", route[8])
	scarecrow._path_index = 9  # Walking from route[8] to route[9] (its target cell)
	scarecrow.take_damage(scarecrow.max_health * 0.21)
	_check(_count(crow_data) == 4, "4 Crows burst out at 80%% (%d)" % _count(crow_data))
	_check(scarecrow.sprite.animation == &"burst", "and its coat flies open (the burst pose)")
	scarecrow.take_damage(scarecrow.max_health * 0.4)
	_check(_count(crow_data) == 12, "4 more at 60%% and 40%% (%d)" % _count(crow_data))
	_check(crow_data.leaf_cost == 1, "each Crow that gets through takes 1 leaf (human run 12)")
	var crows := spawner.get_children().filter(func(e) -> bool: return e.enemy_data == crow_data)
	var airborne := true
	for crow in crows:
		airborne = airborne and crow.is_flying() and crow._path.size() > 2 and (crow._path[-1] + Vector2(0.5, 0.5)).floor() == map_generator.endPath \
			and crow._path[0].distance_to(route[8]) <= 1.0 and crow._path == map_generator.get_path_from(crow._path[0])
	_check(airborne, "the Crows take to the air: they fly the route from where they burst (Wardens along it reach them)")
	_check(not spawner.get_maze_walkers().any(func(e) -> bool: return e.enemy_data == crow_data), "flyers: not maze walkers")
	var walk: float = scarecrow.get_move_speed()
	_check(is_equal_approx(walk, scarecrow.speed * 1.25), "Stitched: faster below 40% health")
	_clear_enemies()

	# --- Huntsman: the pack shields him ---
	var huntsman := _still("huntsman", route[8])
	_check(huntsman.pack_alive() == 4, "4 Night Hounds run with him (%d)" % huntsman.pack_alive())
	for hound in huntsman.pack:
		hound.position = huntsman.position  # (_still moved only him: the pack runs with him)
	var before: int = huntsman.health
	huntsman.take_damage(100.0)
	_check(before - huntsman.health == 50, "half damage while a hound hunts (%d)" % (before - huntsman.health))
	var hound_away := Vector2(5 * 64, 0)  # 5 tiles: past the shield's 3
	for hound in huntsman.pack:
		hound.position += hound_away
	before = huntsman.health
	huntsman.take_damage(100.0)
	_check(before - huntsman.health == 100, "full damage when no hound is within 3 tiles (Human run 4; %d)" % (before - huntsman.health))
	for hound in huntsman.pack:
		hound.position -= hound_away
	for hound in huntsman.pack:
		hound.dispel()
	before = huntsman.health
	huntsman.take_damage(100.0)
	_check(before - huntsman.health == 100, "full damage once the pack is gone")
	spawner._on_brood_requested(huntsman)
	_check(huntsman.pack_alive() == 1, "the horn calls one hound while the pack is short")
	_check(huntsman.sprite.animation == &"horn", "he blows the horn as a hound joins")
	_check(huntsman._bar_offset.y < -60.0, "his bar sits over his tall art, not at the usual -38 (%.0f)" % huntsman._bar_offset.y)
	huntsman.take_damage(huntsman.max_health)  # Down past half (halved: the new hound shields him)
	_check(huntsman.pack_alive() == 4 and huntsman.is_regrouped(), "The Kill: the whole pack returns at half health")
	spawner._on_brood_requested(huntsman)
	_check(huntsman.pack_alive() == 4, "and the horn is silent after")
	_clear_enemies()

	# --- Lamplighter: cold lanterns slow Wardens near them ---
	var lamplighter := _still("lamplighter", route[10])
	lamplighter.set_path(route)
	lamplighter._path_index = 10
	spawner._on_lantern_requested(lamplighter)
	_check(spawner._lanterns.size() == 1, "it lights a lantern beside the route")
	_check(lamplighter.sprite.animation == &"light", "it lowers the pole to light it")
	if spawner._lanterns.size() == 1:
		var lantern: ColdLantern = spawner._lanterns[0]
		_check(lantern._sprite != null and lantern._sprite.animation == &"ignite", "the lantern kindles (its sheet)")
		_check(not route.has(lantern.cell) and map_generator.is_buildable(lantern.cell), "on an empty cell off the route")
		var warden := _plant("sprout", _free_neighbour_of(lantern.cell))
		var far := _plant("sprout", _far_cell(lantern.cell))
		spawner._update_lantern_light()
		_check(is_equal_approx(warden.dim_multiplier, 0.6), "a Warden in its light attacks 40% slower")
		_check(far == null or is_equal_approx(far.dim_multiplier, 1.0), "a Warden out of it doesn't")
		var dew := run_state.dew
		lantern.snuff(true)
		spawner._update_lantern_light()
		_check(is_equal_approx(warden.dim_multiplier, 1.0), "snuffed: the Warden is back to full speed")
		_check(run_state.dew == dew + 2, "snuffing one by hand pays 2 Dew")
		for i in 8:  # Walking on, so there's always room beside the route
			lamplighter._path_index = mini(12 + i * 3, route.size() - 1)
			spawner._on_lantern_requested(lamplighter)
		_check(spawner._lanterns.size() == 4, "at most 4 lanterns at once (%d)" % spawner._lanterns.size())
		lamplighter.dispel()
		_check(spawner._lanterns.is_empty(), "they go out when it's dispelled")
		warden.free()
		if far:
			far.free()
	_clear_enemies()

	# --- Silence (Hushbell, tower_design.md 279ebb63): a boss's timed abilities run at half speed ---
	var queen := _still("moth_queen", route[10])
	queen.statuses.silence_time = 100.0
	queen._brood_timer = 0.0
	queen._update_presence(0.2)
	_check(is_equal_approx(queen._brood_timer, 0.1), "a silenced boss's timers run at half speed (%.2f of 0.2 s)" % queen._brood_timer)
	queen.statuses.silence_time = 0.0
	queen._update_presence(0.2)
	_check(is_equal_approx(queen._brood_timer, 0.3), "full speed again once the silence ends (%.2f)" % queen._brood_timer)
	# A deep Hushbell (Nurture rework e2631f54) slows it further, down to the 0.35 floor
	queen.statuses.silence_time = 100.0
	queen.set_meta(&"silence_boss_speed", 0.4)
	queen._brood_timer = 0.0
	queen._update_presence(0.2)
	_check(is_equal_approx(queen._brood_timer, 0.08), "a deeper silence: its speed from the Hushbell (%.3f)" % queen._brood_timer)
	queen.set_meta(&"silence_boss_speed", 0.1)
	queen._brood_timer = 0.0
	queen._update_presence(0.2)
	_check(is_equal_approx(queen._brood_timer, 0.07), "never below the 0.35 floor (%.3f)" % queen._brood_timer)
	queen.statuses.silence_time = 0.0
	queen._update_presence(0.2)
	_check(not queen.has_meta(&"silence_boss_speed"), "the silence's speed is forgotten when it ends")
	_clear_enemies()

	# --- Barrow King: Iron Will and the Shrug ---
	var king := _still("barrow_king", route[8])
	var near := _still("leaf_bug", route[9])
	king.apply_status(EnemyStatuses.HELD)
	_check(not king.statuses.is_held(), "the Barrow King can't be Held")
	king.apply_status(EnemyStatuses.DROWSY, 5)
	_check(king.get_move_speed() >= king.speed * 0.7 - 0.01, "slows never take him below 70%")
	near.apply_status(EnemyStatuses.DAMP)
	king.shrug()
	_check(king.statuses.active_ids().is_empty() and near.statuses.active_ids().is_empty(), "the Shrug clears his statuses and his neighbours'")
	_check(king.sprite.animation == &"shrug", "his shoulders heave (the shrug pose)")
	_clear_enemies()

	# --- Mourning Mother: Sorrow ---
	var mother := _still("mourning_mother", route[8])
	mother.take_damage(mother.max_health * 0.3)
	var hurt: int = mother.health
	mother._update_boss_pool_abilities(1.0)
	_check(mother.health == hurt, "no mending right after a hit")
	mother._update_boss_pool_abilities(1.0)
	_check(mother.health > hurt, "she mends once left alone (%d → %d)" % [hurt, mother.health])
	mother.update_animation(Vector2(1, 0))
	_check(mother.sorrowing and mother.sprite.animation == &"sorrow", "while she mends, the sorrow loop plays")
	mother.take_damage(10.0)
	mother.update_animation(Vector2(1, 0))
	_check(not mother.sorrowing and mother.sprite.animation == &"walk_side", "a hit brings her walk back at once")
	for i in 60:
		mother._update_boss_pool_abilities(1.0)
	_check(mother.health <= roundi(mother.max_health * 0.7 + mother.max_health * 0.25) + 1, "never more than 25% of her health in all")
	_clear_enemies()

	# --- Withering Oak: withers the strongest Warden near it ---
	var oak := _still("hollow_oak_withering", route[10])
	var weak := _plant("sprout", _free_neighbour_of(route[10]))
	var strong := _plant("dewdrop", _free_neighbour_of(route[11], [weak.cell]))
	spawner._on_wither_requested(oak, 1)
	_check(strong.is_withered() and not weak.is_withered(), "the strongest Warden in reach withers")
	strong._process(7.0)
	_check(not strong.is_withered(), "and comes back on its own")
	spawner._on_wither_requested(oak, 1)
	_check(weak.is_withered(), "never the same one twice in a row")
	weak.free()
	strong.free()
	oak.take_damage(oak.max_health * 0.4)  # Past its first Drought burst
	_check(oak.sprite.animation == &"wither", "Drought: two roots lift and stab down (the wither pose)")
	_clear_enemies()

	# --- Remembering Oak: echoes of this run's bosses ---
	var remembering := _still("hollow_oak_remembering", route[10])
	remembering.set_path(route)
	remembering._path_index = 10
	remembering.take_damage(remembering.max_health * 0.26)
	var echo: Node2D = null
	for enemy in spawner.get_children():
		if enemy.is_echo:
			echo = enemy
	_check(echo != null and echo.enemy_data.resource_path.ends_with("night_mare.tres"), "at 75% the echo of act 1's boss (the Night Mare) rises")
	_check(remembering.sprite.animation == &"echo", "a pale bark face lights as the echo rises (the echo pose)")
	if echo:
		var full := roundi(echo.enemy_data.health * director.get_health_scale(echo.enemy_data, maxi(director.drifts_started, 1)))
		_check(absi(echo.max_health - roundi(full * 0.2)) <= 1, "with 20%% of its health (%d of %d)" % [echo.max_health, full])
		var cleansed := director.bosses_cleansed
		echo.dispel()
		_check(director.bosses_cleansed == cleansed, "an echo doesn't count as a boss dispelled")
	remembering.take_damage(remembering.max_health * 0.5)
	var echoes := spawner.get_children().filter(func(e) -> bool: return e.is_echo and not e.is_cleansed)
	_check(echoes.size() == 2, "two more at 50%% and 25%% (%d)" % echoes.size())
	_clear_enemies()

	print("test_boss_pools: %s" % ("ok" if failures == 0 else "%d failures" % failures))
	quit(failures)

func _drift_has(drift: DriftData, boss: EnemyData) -> bool:
	for group in drift.groups:
		for entry in group.entries:
			if entry.enemy == boss:
				return true
	return false

func _count(data: EnemyData) -> int:
	return spawner.get_children().filter(func(e) -> bool: return e.enemy_data == data and not e.is_cleansed).size()

func _still(kind: String, cell: Vector2) -> Node2D:
	var enemy: Node2D = spawner.spawn_enemy(load("res://resource/enemy/%s.tres" % kind))
	enemy.set_process(false)
	enemy.position = enemy.grid.calculate_map_position(cell)
	return enemy

func _clear_enemies() -> void:
	for enemy in spawner.get_children():
		enemy.free()

func _plant(kind: String, cell: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % kind)
	tower.cell = cell
	tower.position = map_generator.MAP_GRID.calculate_map_position(cell)
	tower_container.add_child(tower)
	return tower

func _free_neighbour_of(cell: Vector2, avoid: Array = []) -> Vector2:
	for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var next: Vector2 = cell + offset
		if not route.has(next) and not avoid.has(next) and map_generator.is_buildable(next):
			return next
	return cell

func _far_cell(from: Vector2) -> Vector2:
	for x in range(1, 22):
		for y in range(1, 17):
			var cell := Vector2(x, y)
			if cell.distance_to(from) > 4.0 and not route.has(cell) and map_generator.is_buildable(cell):
				return cell
	return from

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
