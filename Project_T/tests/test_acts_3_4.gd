extends SceneTree

# Headless test for the acts 3–4 nightmares and bosses (acts_3_4.md, enemy_design.md): Lurkers hidden
# until revealed, Will-o'-Wisps, the Gravecrawler burrowing, the Sleepwalker wandering into dead ends,
# the Drowned One, Barrow Wight, Watcher, Ash Crawler, Shellbound, Whisper Swarm, Dream Thief, Weeper,
# the Moth Queen (weaving flight, brood, Eclipse) and the Hollow Oak (saplings, Grief, rising again).
#   godot --headless --path . --script res://tests/test_acts_3_4.gd --fixed-fps 60

var failures := 0
var spawner: Node
var map_generator: Node
var tower_container: Node
var placer: TowerPlacer
var route: PackedVector2Array

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 777
	root.add_child(main)
	await process_frame
	spawner = main.get_node("%EnemyContainer")
	map_generator = main.get_node("%MapGenerator")
	tower_container = main.get_node("%TowerContainer")
	placer = main.get_node("%TowerPlacer")
	var run_state = main.get_node("%RunState")
	for tower in tower_container.get_children():
		tower.free()
	route = map_generator.get_path_from(map_generator.startPath)

	# --- Lurker: hidden until a Warden is close, a Marking Warden has it in range, or a Wisp is near ---
	var lurker := _still("dusk_moth", route[10])
	lurker._update_presence(0.2)
	_check(lurker.is_hidden() and not lurker.is_in_group("enemies"), "a Lurker is hidden and untargetable")
	var near := _plant("sprout", _free_neighbour(route[10]))
	lurker._update_presence(0.2)
	_check(not lurker.is_hidden() and lurker.is_in_group("enemies"), "a Warden right beside it sees it")
	near.free()
	lurker._update_presence(0.2)
	_check(lurker.is_hidden(), "hidden again once the Warden is gone")
	var lantern := _plant_at_distance("lanternmoth", route[10], 3.0)
	_check(lantern != null, "found a spot 3 cells from the Lurker for a Lanternmoth")
	if lantern:
		lurker._update_presence(0.2)
		_check(not lurker.is_hidden(), "a Lanternmoth (Marks) reveals it from range")
		lantern.free()
	lurker._update_presence(0.2)
	lurker.reveal_for(1.0)
	_check(not lurker.is_hidden(), "Lantern Roots: reveal_for shows it at once")
	lurker._update_presence(0.5)
	_check(not lurker.is_hidden(), "and keeps it shown for the time")
	lurker._update_presence(0.6)
	_check(lurker.is_hidden(), "then it hides again")
	var wisp := _still("will_o_wisp", route[11])
	lurker._update_presence(0.2)
	_check(not lurker.is_hidden(), "a Will-o'-Wisp one cell away reveals it")
	_clear_enemies()

	# --- Drowned One: always Damp, never slowed, can't be Held or made Drowsy ---
	var drowned := _still("drowned_one", route[5])
	drowned.apply_status(EnemyStatuses.DROWSY, 3)
	drowned.apply_status(EnemyStatuses.HELD)
	_check(drowned.statuses.has(EnemyStatuses.DAMP), "the Drowned One is always Damp")
	drowned.statuses.remove(EnemyStatuses.DAMP)
	drowned._update_presence(0.0)
	_check(drowned.statuses.has(EnemyStatuses.DAMP), "and gets soaked again at once")
	_check(not drowned.statuses.has(EnemyStatuses.DROWSY) and not drowned.statuses.is_held(), "no Drowsy, no Held")
	_check(is_equal_approx(drowned.get_move_speed(), drowned.speed), "Damp doesn't slow it")

	# --- Barrow Wight: can't be Held, Drowsy lasts half as long ---
	var wight := _still("barrow_wight", route[6])
	wight.apply_status(EnemyStatuses.HELD)
	wight.apply_status(EnemyStatuses.DROWSY)
	_check(not wight.statuses.is_held(), "the Barrow Wight can't be Held")
	_check(is_equal_approx(wight.statuses.time_left(EnemyStatuses.DROWSY), 1.5), "Drowsy lasts half as long on it")

	# --- Watcher: immune to Drowsy, wakes Drowsy nightmares within 1.5 cells ---
	var sleeper := _still("leaf_bug", route[12])
	sleeper.apply_status(EnemyStatuses.DROWSY, 2)
	var far_sleeper := _still("leaf_bug", route[18])
	far_sleeper.apply_status(EnemyStatuses.DROWSY, 2)
	var watcher := _still("watcher", route[13])
	watcher.apply_status(EnemyStatuses.DROWSY)
	watcher._update_presence(0.2)
	_check(not watcher.statuses.has(EnemyStatuses.DROWSY), "the Watcher never sleeps")
	_check(not sleeper.statuses.has(EnemyStatuses.DROWSY), "it wakes a Drowsy Shade beside it")
	_check(far_sleeper.statuses.has(EnemyStatuses.DROWSY), "but not one far away")
	_clear_enemies()

	# --- Ash Crawler: its trail clears Spored from nightmares on it ---
	var crawler := _still("ash_crawler", route[8])
	crawler._on_cell_reached()
	var spored := _still("leaf_bug", route[8])
	spored.apply_status(EnemyStatuses.SPORED, 2, 5.0, 3.0)
	crawler._update_presence(0.2)
	_check(not spored.statuses.has(EnemyStatuses.SPORED), "the Ash Crawler's ash clears Spored")
	crawler._update_presence(3.5)
	_check(crawler._ash_cells.is_empty(), "the ash burns out after 3 s")
	_clear_enemies()

	# --- Shellbound's dread shell, the Whisper Swarm's shape ---
	var shell := _still("shellbound", route[5])
	_check(is_equal_approx(shell.coat_max, 100.0), "the Shellbound's shell soaks 100")
	var before: int = shell.health
	shell.take_damage(5.0)
	_check(before - shell.health == 1, "a small hit mostly bounces off the shell (%d)" % (before - shell.health))
	shell.max_health = 100000
	shell.health = 100000
	for i in 20:  # −6 per hit until it has soaked 100
		shell.take_damage(50.0)
	_check(shell.coat == 0.0 and shell.sprite.sprite_frames == shell.enemy_data.cracked_frames, "a broken shell shows the cracked art")
	var swarm := _still("whisper_swarm", route[6])
	before = swarm.health
	swarm.take_damage(100.0)
	_check(before - swarm.health == 50, "single-target hits do half to the Whisper Swarm")
	before = swarm.health
	swarm.take_damage(100.0, "", true)
	_check(before - swarm.health == 100, "area hits do full damage")

	# --- Dream Thief: steals 5 Dew on reaching the Heartwood; double Dew when dispelled ---
	var thief := _still("dream_thief", route[7])
	_check(thief.get_dew_reward() == 6, "the Dream Thief drops double Dew (6)")
	run_state.dew = 20
	run_state.invulnerable = true
	spawner._on_enemy_reached_goal(thief)
	_check(run_state.dew == 15, "it steals 5 Dew on the way in (%d left)" % run_state.dew)
	run_state.dew = 3
	spawner._on_enemy_reached_goal(thief)
	_check(run_state.dew == 0, "never more than there is")

	# --- Weeper: mends nightmares within 1.5 cells for 2% of their max health a second ---
	var hurt := _still("leaf_bug", route[9])
	hurt.health = 50
	var weeper := _still("weeper", route[9])
	weeper.health = 10
	weeper._update_presence(1.0)
	_check(hurt.health == 52, "the Weeper mends the Shade beside it (%d)" % hurt.health)
	_check(weeper.health == 10, "but not itself")
	_clear_enemies()

	# --- Gravecrawler burrows under a wall when that's shorter ---
	var burrow := _burrow_setup()
	_check(not burrow.is_empty(), "found a wall to burrow under")
	if not burrow.is_empty():
		var grave := _still("gravecrawler", burrow.here)
		var long_way := PackedVector2Array([burrow.here])
		for i in 60:
			long_way.append(burrow.here)  # A made-up long way round
		grave.set_path(long_way)
		grave._path_index = 1
		grave.set_process(true)
		grave._try_burrow()
		_check(grave._leaping, "the Gravecrawler sinks under the wall")
		await _wait(1.8)
		_check(grave.get_current_cell() == burrow.beyond and grave._burrows == 1,
			"and surfaces on the other side (%s)" % grave.get_current_cell())
		grave._leaping = false
		grave._path_index = 1
		var path_before: PackedVector2Array = grave._path.duplicate()
		grave._try_burrow()
		_check(not grave._leaping and grave._path == path_before, "only once per trip")
		var held_grave := _still("gravecrawler", burrow.here)
		held_grave.set_path(long_way)
		held_grave._path_index = 1
		held_grave.stop_burrowing()
		held_grave._try_burrow()
		_check(not held_grave._leaping, "Lantern Roots: stop_burrowing keeps it from burrowing this trip")
		_clear_enemies()

	# --- Sleepwalker wanders into a dead end and back ---
	var pocket := _dead_end_setup()
	_check(not pocket.is_empty(), "built a one-cell dead end beside the route")
	if not pocket.is_empty():
		var data: EnemyData = load("res://resource/enemy/wandering_hare.tres").duplicate()
		data.wander_chance = 1.0
		spawner.spawn_enemy(data)
		var walker: Node2D = spawner.get_child(spawner.get_child_count() - 1)
		walker.set_process(false)
		var from := route.slice(pocket.index)
		walker.position = walker.grid.calculate_map_position(from[0])
		walker.set_path(from)
		walker._path_index = 1
		walker._try_wander()
		_check(walker._path.size() >= 2 and walker._path[0] == pocket.cell and walker._path[1] == from[0],
			"the Sleepwalker steps into the dead end and back")
		_check(walker._path[walker._path.size() - 1] == map_generator.endPath, "then goes on to the Heartwood")
		_clear_enemies()

	# --- The Moth Queen: weaving flight, brood, Eclipse ---
	spawner.drift_health_scale = 3.0
	var queen: Node2D = spawner.spawn_enemy(load("res://resource/enemy/moth_queen.tres"))
	queen.set_process(false)
	var maze_route: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	_check(queen.is_flying() and queen._path == maze_route, "the Moth Queen flies along the nightmares' route")
	_check(not spawner.get_maze_walkers().has(queen), "as a flyer: the path rule and re-routes leave her alone")
	var queen_route: PackedVector2Array = queen._path.duplicate()
	spawner._on_path_changed()
	_check(queen._path == queen_route, "a path change doesn't re-route her")
	queen.apply_status(EnemyStatuses.HELD)
	_check(not queen.statuses.is_held(), "nothing on the ground holds her (Held / Rooted)")
	_check(spawner.drift_health_scale == 3.0, "bosses don't change the drift's health scale")
	var brood := []
	var on_brood := func(parent: Node2D, child: Node2D) -> void:
		if parent == queen:
			brood.append(child)
	spawner.enemy_split.connect(on_brood)
	queen._update_presence(4.1)
	_check(brood.size() == 1 and brood[0].enemy_data.resource_path.get_file() == "dusk_moth.tres",
		"she drops a Lurker every 4 s")
	if brood.size() == 1:
		_check(brood[0].max_health == 210, "grown like the drift's other nightmares (%d)" % brood[0].max_health)
		_check(brood[0]._path[brood[0]._path.size() - 1] == map_generator.endPath, "it walks the maze from there")
	var bystander := _still("leaf_bug", route[25])
	queen.take_damage(queen.max_health / 2 + 1)
	_check(spawner.eclipse_left > 4.9, "half health: the Eclipse")
	_check(queen.sprite.animation == &"eclipse", "her wings close (eclipse pose)")
	bystander._update_presence(0.2)
	queen._update_presence(0.2)
	_check(bystander.is_hidden() and not queen.is_hidden(), "every nightmare but the Queen is hidden")
	spawner.eclipse_left = 0.0
	bystander._update_presence(0.2)
	_check(not bystander.is_hidden(), "and seen again when it ends")
	spawner.enemy_split.disconnect(on_brood)
	_clear_enemies()

	# --- The Hollow Oak: saplings, Grief, Blight Level 10 rising, saplings wither ---
	var oak: Node2D = spawner.spawn_enemy(load("res://resource/enemy/hollow_oak.tres"))
	oak.set_process(false)
	var sapling: ObstacleData = oak.enemy_data.sapling
	oak._update_presence(8.1)
	var planted: Array = map_generator.obstacles.keys().filter(func(c: Vector2) -> bool:
		return map_generator.obstacles[c] == sapling)
	_check(planted.size() == 1, "the Hollow Oak plants a thorn-sapling")
	var sapling_sprites: Array = spawner._sapling_sprites.values()
	_check(sapling_sprites.size() == 1 and sapling_sprites[0].animation == &"grow", "the sapling grows in")
	_check(not map_generator.get_path_from(map_generator.startPath).is_empty(), "the path stays open")
	var grief := []
	spawner.enemy_split.connect(func(parent: Node2D, child: Node2D) -> void:
		if parent == oak:
			grief.append(child))
	oak.take_damage(oak.max_health * 0.34 + 1)
	_check(grief.size() == 6 and oak.hold_time > 0.0, "two-thirds health: it stops, and 6 Mourners rise")
	_check(oak.sprite.animation == &"grief", "and wails (grief animation)")
	oak.take_damage(oak.max_health * 0.34)
	_check(grief.size() == 12, "and again at one third")
	MetaRun.blight_level = 10
	oak.take_damage(1e9)
	_check(not oak.is_cleansed and oak.health == oak.max_health / 2, "Blight Level 10: it rises again at half health")
	_check(is_equal_approx(oak._sapling_speed, 2.0), "planting twice as fast")
	oak.take_damage(1e9)
	MetaRun.blight_level = 0
	_check(oak.is_cleansed, "the second time it's dispelled")
	_check(planted.all(func(c: Vector2) -> bool: return map_generator.get_obstacle(c) == null), "its saplings wither")
	_check(sapling_sprites.size() == 1 and sapling_sprites[0].animation == &"wither", "crumbling to ash (wither animation)")

	# --- Rooted Nightmares (Dream 122): a Held nightmare blocks its cell for other walkers ---
	_clear_enemies()
	route = map_generator.get_path_from(map_generator.startPath)
	var holder := _still("leaf_bug", route[9])
	holder.apply_status(EnemyStatuses.HELD, 1, 30.0)
	var walker := _still("leaf_bug", route[8])
	walker.set_path(route.slice(8))
	walker._path_index = 1
	spawner._update_rooted_cells()
	_check(not walker._is_blocked_ahead(1.0) and walker._path[1] == route[9], "without the card, Held nightmares don't block")
	var dreams: DreamState = main.get_node("%DreamState")
	for card in dreams.pool:
		if card.id == "rooted_nightmares":
			dreams.take(card)
	_check(dreams.has_rule(&"rooted_nightmares"), "took Rooted Nightmares")
	spawner._update_rooted_cells()
	_check(spawner.rooted_cells.get(route[9]) == holder, "with it, the Held nightmare's cell is rooted")
	var blocked: bool = walker._is_blocked_ahead(1.0)
	_check((blocked and walker.waiting) or (not blocked and walker._path[1] != route[9]),
		"the walker behind goes round it or waits (%s)" % ("waits" if blocked else "goes round"))
	_check(walker.position == walker.grid.calculate_map_position(route[8]), "it never steps into the Held one's cell")
	walker.waiting = true  # Waiting at route[8]: the next walker queues behind, not in the same cell
	var follower := _still("leaf_bug", route[7])
	follower.set_path(route.slice(7))
	follower._path_index = 1
	spawner._update_rooted_cells()
	_check(follower._is_blocked_ahead(1.0), "a walker behind a waiting one queues")
	var phantom := _still("dandelion_seed", route[8])
	phantom.set_path(PackedVector2Array([route[8], route[9]]))
	phantom._path_index = 1
	_check(not phantom._is_blocked_ahead(1.0), "flyers ignore rooted cells")
	holder.statuses.remove(EnemyStatuses.HELD)
	walker.waiting = false
	spawner._update_rooted_cells()
	_check(spawner.rooted_cells.is_empty(), "once the Hold ends the cell opens again")

	# --- Boss dossier data, defences, immune feedback ---
	for kind in ["old_stag", "great_toad", "moth_queen", "hollow_oak"]:
		var boss: EnemyData = load("res://resource/enemy/%s.tres" % kind)
		_check(boss.title != "" and boss.abilities.size() >= 2 and boss.tips.size() >= 2, "%s has a title, abilities and tips" % kind)
		for i in boss.abilities.size():
			var ability := boss.get_ability(i)
			var shown := IconInfo.format(ability.text + " " + ability.when)
			_check(not shown.contains("{") and ability.name != "", "%s ability %d reads fully: %s" % [kind, i, shown])
		for tip in boss.tips:
			_check(not IconInfo.format(tip).contains("{"), "%s tip reads fully" % kind)
	# New nightmare introduction: every non-boss nightmare has 1–2 intro lines and a hint that read fully.
	for file in DirAccess.get_files_at("res://resource/enemy"):
		if not file.ends_with(".tres"):
			continue
		var kind_data: EnemyData = load("res://resource/enemy/" + file)
		if kind_data.is_boss:
			continue
		var intro := kind_data.get_intro_lines()
		_check(intro.size() in [1, 2] and kind_data.hint != "", "%s has intro lines and a hint" % file)
		for line in intro + [kind_data.hint]:
			_check(not IconInfo.format(line).contains("{"), "%s reads fully: %s" % [file, IconInfo.format(line)])
	var mourner_intro: String = load("res://resource/enemy/puffcap.tres").get_intro_lines()[0]
	_check(mourner_intro == "Breaks into 3 Sobs when dispelled.", "intro numbers come from the data (%s)" % mourner_intro)
	var weeper_intro: String = load("res://resource/enemy/weeper.tres").get_intro_lines()[0]
	_check(weeper_intro.contains("1.5 tiles") and weeper_intro.contains("2%"), "Weeper intro: %s" % weeper_intro)
	var stag_charge: Dictionary = load("res://resource/enemy/old_stag.tres").get_ability(1)
	_check(stag_charge.text.contains("2.5×") and stag_charge.when.contains("4+ tiles"), "numbers come from the data (%s / %s)" % [stag_charge.when, stag_charge.text])
	var oak_grief: Dictionary = load("res://resource/enemy/hollow_oak.tres").get_ability(1)
	_check(oak_grief.when == "at 67% and 33% health" and oak_grief.text.contains("6 Mourners"), "Grief: %s / %s" % [oak_grief.when, oak_grief.text])
	var summons: Array = load("res://resource/enemy/moth_queen.tres").get_summons()
	_check(summons.size() == 1 and summons[0].data.display_name == "Lurker" and summons[0].how == "every 4 s", "the Moth Queen brings Lurkers")
	var wight_defences: Dictionary = load("res://resource/enemy/barrow_wight.tres").get_defences()
	_check(wight_defences.immune.has(&"held") and is_equal_approx(wight_defences.shorter[&"drowsy"], 0.5), "Barrow Wight: immune to Held, Drowsy ×0.5")
	_check(load("res://resource/enemy/dandelion_seed.tres").get_defences().traits.has(&"through_walls"), "the Phantom passes through walls")
	_check(load("res://resource/enemy/moth_queen.tres").get_defences().traits.has(&"flying"), "the Moth Queen flies")
	_check(load("res://resource/enemy/shellbound.tres").get_defences().traits.has(&"dread_shell"), "the Shellbound has a dread shell")
	_check(load("res://resource/enemy/dusk_moth.tres").get_defences().traits.has(&"hidden"), "the Lurker is hidden")
	_check(is_equal_approx(load("res://resource/enemy/old_stag.tres").get_defences().shorter[&"held"], 0.5), "bosses: Held lasts half as long")
	_clear_enemies()
	var refused := []
	spawner.status_refused.connect(func(_e: Node2D, status: StringName) -> void: refused.append(status))
	var wight2 := _still("barrow_wight", route[5])
	wight2.apply_status(EnemyStatuses.HELD)
	wight2.apply_status(EnemyStatuses.HELD)
	_check(refused == [&"held"], "an immune status is refused with one signal, throttled (%s)" % [refused])
	var hound_data: EnemyData = load("res://resource/enemy/hedgehog.tres")
	_check(hound_data.get_defences().conditional.get(&"held") == "while sprinting" and not hound_data.get_defences().immune.has(&"held"),
		"the Night Hound shows Held immunity as 'while sprinting'")
	var hound := _still("hedgehog", route[6])
	hound.rolling = true
	hound.apply_status(EnemyStatuses.HELD)
	_check(not hound.statuses.is_held() and refused.size() == 2 and refused[1] == &"held", "a sprinting Night Hound can't be Held")
	hound.rolling = false
	hound.apply_status(EnemyStatuses.HELD)
	_check(hound.statuses.is_held(), "a walking one can")
	_clear_enemies()

	# --- Weathered Walls (no trampling; Tangled was cut in the pool trim) ---
	_clear_enemies()
	var stag_wall := _free_neighbour(route[12])
	var wall_tower := _plant("thornwall", stag_wall)
	var walker_stag := _still("old_stag", route[12])
	_take_card(dreams, "weathered_walls")
	spawner._on_trample_requested(walker_stag)
	_check(is_instance_valid(wall_tower) and not wall_tower.is_queued_for_deletion(), "Weathered Walls: the Stag can't trample a Thornwall")
	wall_tower.free()
	_clear_enemies()

	# --- Damp Rot (Dream 169): Poisoned ticks +20% per stack on Soaked nightmares ---
	_clear_enemies()
	var rot_dry := _still("leaf_bug", route[5])
	var rot_wet := _still("leaf_bug", route[5])
	rot_wet.apply_status(EnemyStatuses.DAMP)
	for rotting in [rot_dry, rot_wet]:
		rotting.max_health = 100000
		rotting.health = 100000
		rotting.apply_status(EnemyStatuses.SPORED, 1, 10.0, 100.0)
	dreams.unlocked["sporeling"] = true  # Damp Rot needs both families, or it lies dormant
	dreams.unlocked["dewdrop"] = true
	_take_card(dreams, "damp_rot")
	for rotting in [rot_dry, rot_wet]:
		rotting._process(0.5)  # One Poisoned tick
	var dry_loss: int = 100000 - rot_dry.health
	var wet_loss: int = 100000 - rot_wet.health
	_check(dry_loss > 0 and is_equal_approx(float(wet_loss) / dry_loss, 1.0 + DreamState.DAMP_ROT_PER),
		"Damp Rot: a Soaked nightmare's Poisoned tick is +50%% (%d vs %d)" % [wet_loss, dry_loss])
	_clear_enemies()

	# --- Status jobs (tower_design.md, 2026-09-29) ---
	_clear_enemies()
	var soaked := _still("leaf_bug", route[5])
	soaked.max_health = 100000
	soaked.health = 100000
	soaked.apply_status(EnemyStatuses.DAMP)
	_check(is_equal_approx(soaked.get_move_speed(), soaked.speed), "Soaked no longer slows")
	var before_water: int = soaked.health
	soaked.take_damage(100.0, "water")
	_check(before_water - soaked.health == 120, "water hits on Soaked +20%% (%d)" % (before_water - soaked.health))
	before_water = soaked.health
	soaked.take_damage(100.0, "stone")
	_check(before_water - soaked.health == 100, "other families aren't boosted")
	soaked.apply_status(EnemyStatuses.DAMP, 1, 0.0, 1.5)  # Soaked Through II: Damp at potency 1.5
	before_water = soaked.health
	soaked.take_damage(100.0, "water")
	_check(before_water - soaked.health == 130, "Soaked Through II: water hits +30%% (%d)" % (before_water - soaked.health))
	var hit_sleeper := _still("leaf_bug", route[6])
	hit_sleeper.statuses.sleep_time = 3.0
	hit_sleeper.take_damage(5.0, "", false, false, null, &"spored")
	_check(hit_sleeper.statuses.is_asleep(), "an effect tick doesn't wake it")
	hit_sleeper.take_damage(5.0)
	_check(hit_sleeper.statuses.is_asleep(), "a small hit doesn't wake it")
	hit_sleeper.take_damage(hit_sleeper.max_health * 0.1 + 1)
	_check(not hit_sleeper.statuses.is_asleep(), "a hit of 10%+ of max health wakes it")
	var locked := _still("leaf_bug", route[7])
	locked.max_health = 1000
	locked.health = 1000
	locked.statuses.sleep_time = 1.0
	locked.statuses.sleep_locked_time = 5.0
	locked.take_damage(500.0)
	locked.statuses.tick(2.0)
	_check(locked.statuses.is_asleep(), "Nightbloom's lock: sleep neither breaks nor ends")
	var sleepy_watcher := _still("watcher", route[8])
	var near_sleeper := _still("leaf_bug", route[8])
	near_sleeper.statuses.sleep_time = 3.0
	sleepy_watcher._update_presence(0.2)
	_check(not near_sleeper.statuses.is_asleep(), "the Watcher wakes sleepers near it")
	var boss_sleep := _still("old_stag", route[9])
	boss_sleep.statuses.sleep_time = 3.0
	boss_sleep.statuses.tick(0.1)
	_check(not boss_sleep.statuses.is_asleep(), "bosses never sleep")
	var caught := _still("leaf_bug", route[10])
	caught.apply_status(EnemyStatuses.MARKED)
	caught.apply_status(EnemyStatuses.STATIC, 3)
	caught.statuses.caught_time = 10.0
	caught.statuses.caught_bonus = 0.6
	_check(is_equal_approx(caught.statuses.get_damage_taken_multiplier(), 1.0 + EnemyStatuses.MARKED_EXTRA), "Caught adds no damage")
	caught.statuses.tick(8.0)
	_check(caught.statuses.has(EnemyStatuses.MARKED) and caught.statuses.stacks(EnemyStatuses.STATIC) == 3,
		"Caught: statuses stop wearing off")
	caught.statuses.caught_shard = true
	_check(is_equal_approx(caught.statuses.get_caught_tick_bonus(), 0.25), "Great Dreamcatcher: Caught statuses tick +25 percent")
	# Magpies strip buffs
	var shell_data: EnemyData = load("res://resource/enemy/shellbound.tres")
	var shared_mods := {"status_immune": [&"drowsy"], "coat": 1.5, "omen_speed": 1.25, "speed": 1.25, "status_duration": 0.5}
	var robbed: Node2D = spawner.spawn_enemy(shell_data, 1.0, shared_mods)
	robbed.set_process(false)
	var shell_before: float = robbed.coat
	_check(robbed.strip_buff(null), "strip_buff reports it stripped something")
	_check(is_equal_approx(robbed.coat, (shell_before - 9.0) / 1.5), "shell: an extra chunk, and Hard Bark's thicker shell gone (%.1f)" % robbed.coat)
	_check(robbed.statuses.immune.is_empty() and is_equal_approx(robbed.statuses.duration_multiplier_all, 1.0),
		"Omen immunities and shorter statuses gone")
	_check(is_equal_approx(robbed.speed, shell_data.speed), "the Omen's speed gone")
	_check(shared_mods.has("status_immune"), "the shared modifiers aren't touched (split-offs keep theirs)")
	var weeper_robbed := _still("weeper", route[11])
	var weeper_patient := _still("leaf_bug", route[11])
	weeper_patient.health = 50
	weeper_robbed.strip_buff(null)
	weeper_robbed._update_presence(1.0)
	_check(weeper_patient.health == 50, "a robbed Weeper stops mending")
	weeper_robbed._update_presence(2.5)
	weeper_robbed._update_presence(1.0)
	_check(weeper_patient.health > 50, "for 3 s")
	_check(not _still("leaf_bug", route[12]).strip_buff(null), "nothing to steal from a plain Shade")
	_clear_enemies()

	# --- Thin-family cards (dream_design.md 2026-09-30): Bright Marks, Root Web, Tangled Release, Lullaby ---
	_clear_enemies()
	for card_id in ["bright_marks", "root_web", "tangled_release", "lullaby"]:
		_take_card(dreams, card_id)
	spawner._process(0.0)
	var bright := _still("leaf_bug", route[5])
	bright.apply_status(EnemyStatuses.MARKED)
	bright._process(0.0)
	_check(is_equal_approx(bright.statuses.get_damage_taken_multiplier(), 1.0 + EnemyStatuses.MARKED_EXTRA + DreamState.BRIGHT_MARKS_PER),
		"Bright Marks: Marked +20 percent more (%.2f)" % bright.statuses.get_damage_taken_multiplier())
	var web_a := _still("leaf_bug", route[8])
	var web_b := _still("leaf_bug", route[8])
	var web_far := _still("leaf_bug", route[20])
	web_a.apply_status(EnemyStatuses.HELD, 1, 2.0)
	_check(web_b.statuses.is_held() and is_equal_approx(web_b.statuses.time_left(EnemyStatuses.HELD), 1.0),
		"Root Web: a touching nightmare is Held for half as long (%.2f s)" % web_b.statuses.time_left(EnemyStatuses.HELD))
	_check(not web_far.statuses.is_held(), "…but not one far away")
	web_b.statuses.remove(EnemyStatuses.HELD)
	web_a.statuses.remove(EnemyStatuses.HELD)
	web_a.apply_status(EnemyStatuses.HELD, 1, 2.0)
	_check(not web_b.statuses.is_held(), "at most once a second per nightmare")
	var freed := _still("leaf_bug", route[12])
	freed.set_path(route.slice(8))
	freed._path_index = 5
	freed.apply_status(EnemyStatuses.HELD, 1, 0.3)
	freed._process(0.5)
	_check(freed.is_dragged() or freed._path_index < 5, "Tangled Release: freed from a hold, it's pulled back")
	var lulled := _still("leaf_bug", route[15])
	lulled.statuses.caught_time = 0.1
	lulled._process(0.0)
	lulled._process(0.2)
	_check(lulled.statuses.is_caught() and is_equal_approx(lulled.statuses.caught_time, 1.0), "Lullaby: Caught lingers 1 s after it lapses")
	lulled._process(1.1)
	_check(not lulled.statuses.is_caught(), "…once, then it ends")
	# Tangled Release + Snare (ruling 2026-09-30): hold → release pull → Snare hold → done.
	var snare_holder := SnareHolder.new()
	snare_holder.tower_data = load("res://resource/tower/rootling.tres")
	var holder_sprite := Sprite2D.new()
	holder_sprite.name = "Sprite2D"
	snare_holder.add_child(holder_sprite)
	tower_container.add_child(snare_holder)
	snare_holder.set_process(false)
	var snared := _still("leaf_bug", route[12])
	snared.set_path(route.slice(8))
	snared._path_index = 5
	snared.apply_status(EnemyStatuses.HELD, 1, 0.3, 0.0, 0, "", snare_holder)
	snared._process(0.0)
	snared._process(0.5)  # The hold ends: the release pull, and Snare holds it again
	_check(snare_holder.pulls == 1 and snared.statuses.is_held(), "the release pull sets off Snare's hold (%d pull)" % snare_holder.pulls)
	snared._process(1.0)  # That Snare hold ends: no second release pull
	_check(snare_holder.pulls == 1 and not snared.statuses.is_held(), "…and it stops there, after one cycle (%d pulls)" % snare_holder.pulls)
	snare_holder.free()
	_clear_enemies()

	# --- Omens: Sleepless (immune to Drowsy and Held), Heavy Rain (always Soaked) ---
	var omened: Node2D = spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"), 1.0,
		{"status_immune": [&"drowsy", &"held"], "always_status": &"damp"})
	omened.set_process(false)
	omened.apply_status(EnemyStatuses.DROWSY)
	omened.apply_status(EnemyStatuses.HELD)
	_check(not omened.statuses.has(EnemyStatuses.DROWSY) and not omened.statuses.is_held(), "Sleepless: no Drowsy, no Held")
	_check(omened.statuses.has(EnemyStatuses.DAMP), "Heavy Rain: Soaked from the start")
	omened.statuses.remove(EnemyStatuses.DAMP)
	omened._update_presence(0.0)
	_check(omened.statuses.has(EnemyStatuses.DAMP), "and soaked again at once")
	_check(load("res://resource/enemy/leaf_bug.tres").status_immune.is_empty(), "the Omen doesn't change the Shade's data")
	var plain_shade := _still("leaf_bug", route[5])
	plain_shade.apply_status(EnemyStatuses.DROWSY)
	_check(plain_shade.statuses.has(EnemyStatuses.DROWSY) and not plain_shade.statuses.has(EnemyStatuses.DAMP), "other Shades are unaffected")
	_clear_enemies()

	# --- No maze juggling: Restless and Unbound ---
	_clear_enemies()
	route = map_generator.get_path_from(map_generator.startPath)
	var restless_seen := []
	var unbound_seen := []
	spawner.nightmare_restless.connect(func(e: Node2D, stacks: int) -> void: restless_seen.append(stacks))
	spawner.nightmare_unbound.connect(func(e: Node2D) -> void: unbound_seen.append(e))
	var crowd := []
	for i in 3:
		crowd.append(_still("leaf_bug", route[10]))
	for walker_n in crowd:
		_walk_backwards(walker_n, 10)
	spawner._on_path_changed()
	_check(crowd.all(func(e: Node2D) -> bool: return e.get_restless() == 1), "a crowd turned around once: 1 Restless each")
	_check(restless_seen == [1, 1, 1], "one nightmare_restless each (%s)" % [restless_seen])
	_check(is_equal_approx(crowd[0].get_move_speed(), crowd[0].speed * 1.2), "Restless: +20% speed")
	var normal_walker := _still("leaf_bug", route[10])
	normal_walker.set_path(route.slice(10))
	normal_walker._path_index = 1
	normal_walker._last_cell = route[10]
	spawner._on_path_changed()
	_check(normal_walker.get_restless() == 0, "a re-route that doesn't turn it back gives nothing")
	_clear_enemies()
	var juggled := _still("leaf_bug", route[10])
	for flip in 3:
		_walk_backwards(juggled, 10)
		spawner._on_path_changed()
	_check(juggled.get_restless() == 3 and juggled.is_unbound() and unbound_seen == [juggled], "turned back 3 times: Unbound")
	var kept: PackedVector2Array = juggled._path.duplicate()
	spawner._on_path_changed()
	_check(juggled._path == kept, "an Unbound nightmare ignores re-routes")
	var trampled_cells := []
	spawner.wall_trampled.connect(func(cell: Vector2, _by: Node2D) -> void: trampled_cells.append(cell))
	var on_route := _plant("thornwall", route[13])
	juggled.position = juggled.grid.calculate_map_position(route[12])
	juggled.set_path(route.slice(12))
	juggled._path_index = 1
	juggled._trample_ahead()
	_check(on_route.is_queued_for_deletion() and trampled_cells == [route[13]], "it tramples a Warden planted on its route")
	_check(juggled.get_restless_info().unbound and juggled.get_restless_info().stacks == 3, "get_restless_info reports it")
	_clear_enemies()
	var boss_walker := _still("old_stag", route[10])
	for flip in 3:
		_walk_backwards(boss_walker, 10)
		spawner._on_path_changed()
	_check(boss_walker.get_restless() == 3 and not boss_walker.is_unbound(), "a boss gains Restless but never turns Unbound")
	_clear_enemies()

	# --- Status badges (screens_ui.md "Status icons, clearer") ---
	_clear_enemies()
	var badged := _still("leaf_bug", route[6])
	for id in [&"damp", &"drowsy", &"spored", &"marked", &"held"]:
		badged.statuses.apply(id, 1, 4.0, 1.0)
	badged.statuses.apply(&"static", 4, 0.0, 1.0)
	_check(badged.get_badge_ids() == [&"static", &"held", &"marked", &"spored"],
		"4 badges, the most important first (%s)" % [badged.get_badge_ids()])
	_check(badged.get_status_order().size() == 6, "the info panel still lists all 6")
	_check(badged.statuses.describe(&"static") == "Charged 4/5 · 2.0 s", "info line: %s" % badged.statuses.describe(&"static"))
	_check(badged.statuses.describe(&"damp") == "Soaked · 4.0 s", "no stack count for a status that can't stack (%s)" % badged.statuses.describe(&"damp"))
	badged.statuses.tick(1.0)
	_check(is_equal_approx(badged.statuses.time_share(&"damp"), 0.75), "the rim drains with the time left (%.2f)" % badged.statuses.time_share(&"damp"))
	badged.statuses.apply(&"damp", 1, 4.0, 1.0)
	_check(is_equal_approx(badged.statuses.time_share(&"damp"), 1.0), "a fresh Damp fills it again")
	_check(badged.get_badge_size() == badged.STATUS_BADGE and _still("old_stag", route[7]).get_badge_size() == badged.STATUS_BADGE_BIG,
		"20 px status icons, 24 px on bosses")
	# Bars and badges are the HUD's own canvas items under one NightmareOverlay (batched by kind),
	# rebuilt only when what they show changes; not each nightmare's own _draw.
	var overlay: Node2D = spawner.overlay
	_check(overlay != null and overlay.is_inside_tree() and overlay.get_parent() != spawner,
		"one NightmareOverlay holds the bars and badges (outside the EnemyContainer)")
	badged.statuses.remove(&"spored")  # Its ticks hurt, and hits and combo flashes redraw on their own
	badged.statuses.remove(&"marked")
	badged.set_process(true)
	badged.hold_time = 100.0  # Stands still
	for f in 3:
		await process_frame
	_check(badged._hud_root.is_valid() and badged._hud_items.size() == 4, "its HUD items exist once it's shown")
	var redraws := [0]
	badged.draw.connect(func() -> void: redraws[0] += 1)
	var builds: int = badged.hud_builds
	for f in 30:
		await process_frame
	_check(badged.hud_builds - builds <= 4,
		"its HUD is rebuilt only when something changes (the arcs step; %d in 30 frames)" % (badged.hud_builds - builds))
	builds = badged.hud_builds
	badged.take_damage(5.0)
	await process_frame
	var bar_px := int(badged.HEALTH_BAR_SIZE.x * badged.health / badged.max_health)
	_check(badged.hud_builds > builds and badged._hud_health == bar_px,
		"a hit rebuilds the bars at their new width (%d px, %d builds)" % [badged._hud_health, badged.hud_builds - builds])
	_check(redraws[0] == 0, "a nightmare doesn't redraw itself for statuses or hits (%d in 30 frames)" % redraws[0])
	_clear_enemies()

	# --- Display settings: health bars "always", the Deeply Blighted outline ---
	_clear_enemies()
	Fx._settings = {}  # Defaults, whatever the player's profile says
	Fx._settings_at = Time.get_ticks_msec()
	var plain: Node2D = spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"), 1.0, {}, true)
	_check(not plain._bars_always and plain._outline_alpha() == 0.0, "by default: bars once hit, no outline")
	Fx._settings = {"health_bars": 1, "blight_outline": true}
	Fx._settings_at = Time.get_ticks_msec()
	var shown: Node2D = spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"), 1.0, {}, true)
	var normal: Node2D = spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	_check(shown._bars_always and shown._outline_alpha() > 0.0, "settings on: bars always, elites outlined")
	_check(normal._outline_alpha() == 0.0, "only Deeply Blighted nightmares get the outline")
	plain._update_presence(0.6)  # Display settings are re-read every 0.5 s
	_check(plain._bars_always and plain._outline_alpha() > 0.0, "a nightmare already out picks the change up")
	Fx.reset_run()
	_clear_enemies()

	print("acts 3-4 test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

# A nightmare of `kind` standing still on `cell`.
func _still(kind: String, cell: Vector2) -> Node2D:
	var enemy: Node2D = spawner.spawn_enemy(load("res://resource/enemy/%s.tres" % kind))
	enemy.set_process(false)
	enemy.position = enemy.grid.calculate_map_position(cell)
	return enemy

# Sets `enemy` up standing on route[k + 1] and heading back to route[k]: the map's route from there
# leads forward again, so the next re-route turns it back onto the tile it just left.
func _walk_backwards(enemy: Node2D, k: int) -> void:
	enemy.position = enemy.grid.calculate_map_position(route[k + 1])
	enemy.set_path(PackedVector2Array([route[k + 1], route[k]]))
	enemy._path_index = 1
	enemy._last_cell = route[k + 1]

func _take_card(dreams: DreamState, id: String) -> void:
	for card in dreams.pool:
		if card.id == id:
			dreams.take(card)
			return
	_check(false, "card %s exists" % id)

func _clear_enemies() -> void:
	for enemy in spawner.get_children():
		enemy.free()

# A Warden of `kind` on `cell`, added straight to the map (it doesn't block the path).
func _plant(kind: String, cell: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % kind)
	tower.cell = cell
	tower.position = map_generator.MAP_GRID.calculate_map_position(cell)
	tower_container.add_child(tower)
	return tower

# A Warden of `kind` about `cells` cells from `target`, still with `target` in range.
func _plant_at_distance(kind: String, target: Vector2, cells: float) -> Tower:
	for x in range(-4, 5):
		for y in range(-4, 5):
			var cell := target + Vector2(x, y)
			if absf(Vector2(x, y).length() - cells) < 0.5 and map_generator.is_buildable(cell) and not route.has(cell):
				var tower := _plant(kind, cell)
				if tower.global_position.distance_to(map_generator.MAP_GRID.calculate_map_position(target)) <= tower.get_range_pixels():
					return tower
				tower.free()
	return null

func _free_neighbour(cell: Vector2) -> Vector2:
	for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		if not route.has(cell + offset) and map_generator.is_buildable(cell + offset):
			return cell + offset
	return cell

# A Thornwall beside a route cell, with walkable ground past it that leads to the Heartwood:
# {here, beyond}, or {} if the map has no such spot.
func _burrow_setup() -> Dictionary:
	for i in range(5, route.size() - 5):
		var here := route[i]
		for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var wall: Vector2 = here + direction
			var beyond: Vector2 = here + direction * 2
			if route.has(wall) or not map_generator.can_block(wall) or not map_generator.is_buildable(beyond):
				continue
			map_generator.block_cell(wall)
			if map_generator.get_path_from(beyond).is_empty():
				map_generator.unblock_cell(wall)
				continue
			_plant("thornwall", wall)
			route = map_generator.get_path_from(map_generator.startPath)
			return {"here": here, "beyond": beyond}
	return {}

# Walls in a single open cell beside the route so it's a dead end: {index (route), cell}, or {}.
func _dead_end_setup() -> Dictionary:
	for i in range(5, route.size() - 5):
		for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var side: Vector2 = route[i] + direction
			if route.has(side) or not map_generator.is_buildable(side):
				continue
			var walls: Array[Vector2] = []
			var ok := true
			for step in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
				var around: Vector2 = side + step
				if around == route[i] or route.has(around) or not map_generator.is_buildable(around):
					continue
				if not map_generator.can_block(around):
					ok = false
					break
				map_generator.block_cell(around)
				walls.append(around)
			if ok and map_generator.get_path_from(map_generator.startPath) == route:
				return {"index": i, "cell": side}
			for wall in walls:
				map_generator.unblock_cell(wall)
	return {}

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _wait(seconds: float) -> void:
	await create_timer(seconds, true, true).timeout

# A Rootling bonded for Snare (kin_share reports it), counting its pulls: for the release-pull cycle.
class SnareHolder extends Tower:
	var pulls := 0
	func kin_share(id: StringName, side: String) -> float:
		return 1.0 if id == &"snare" and side == "a" else 0.0
	func pull(enemy: Node2D, tiles: float) -> void:
		pulls += 1
		super(enemy, tiles)
