extends SceneTree
# Non-status builds (owner 2026-10-19; council D:\Projects\logs\dream_council\nonstatus_*.md): hit payoffs that read no
# status. Heavy Going (Dewdrop lent), Fruiting and Parting Puff (Sporeling lent), Stomping Ground (Spore Print), the
# Midnight Toll's triple blow (Keeping Time), the Overnight / Slow Burn / Bright Marks offer gates, and the data.

var failures := 0
var main: Node
var spawner: Node
var placer: Node
var container: Node
var dreams: DreamState
const CELL := 64.0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _plant(id: String, at: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = (at / CELL).floor()
	tower.position = at
	container.add_child(tower)
	tower.set_process(false)
	dreams.bump_board()
	return tower

func _spawn(at: Vector2, health: int = 1000000) -> Node2D:
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	var enemy = spawner.get_child(spawner.get_child_count() - 1)
	enemy.set_process(false)
	enemy.global_position = at
	enemy.max_health = health
	enemy.health = health
	enemy.coat = 0.0
	return enemy

func _take(id: String) -> void:
	dreams.take(load("res://resource/dream/%s.tres" % id))

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _clean() -> void:
	for child in spawner.get_children():
		child.queue_free()
	for child in container.get_children():
		child.queue_free()
	await process_frame
	dreams.stacks.clear()
	dreams.calling = ""
	dreams.calling_path.clear()
	dreams.bump_board()

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _frames(2)
	spawner = main.get_node("%EnemyContainer")
	placer = main.get_node("%TowerPlacer")
	container = main.get_node("%TowerContainer")
	dreams = main.get_node("%DreamState")
	var spot := Vector2(CELL * 6.5, CELL * 14.5)

	# --- Data -----------------------------------------------------------------------------------------------------
	for row in [["fruiting", "sporeling", dreams.spore_print], ["parting_puff", "sporeling", dreams.spore_print],
			["heavy_going", "dewdrop", dreams.puddles]]:
		var card: UpgradeData = load("res://resource/dream/%s.tres" % row[0])
		_check(card.tags.has(DreamState.LENT_TAG) and card.requires.has(row[1]) and not card.retired, "%s is a live lent %s card" % [row[0], row[1]])
		_check(row[2]._lent_rules().has(card.rule_id), "%s's rule is read by its class script" % row[0])
		_check(card.tip.contains("Works for:"), "%s says who it works for" % row[0])
	_check(load("res://resource/dream/waterlogged.tres").retired, "Slow to Dry is retired (Heavy Going takes its place)")
	var paths: Dictionary = DreamState.CALLING_PATHS.PATHS
	_check(paths.has(&"sp_stomping") and paths[&"sp_stomping"].parent == &"sp_borrowed", "Stomping Ground follows Borrowed Spores")
	_check(paths.has(&"sp_second_crop") and paths[&"sp_second_crop"].parent == &"sp_stomping", "Second Crop caps Stomping Ground")
	_check(not paths.has(&"sp_catching") and not paths.has(&"sp_outbreak"), "Catching and Outbreak are no longer offered")
	for word in ["mushroom", "dose", "water", "splash", "pond", "Lit", "glow", "Toll", "ring"]:
		for id in ["fruiting", "parting_puff", "heavy_going"]:
			var card: UpgradeData = load("res://resource/dream/%s.tres" % id)
			_check(not (card.description + " " + card.tip).contains(word), "%s uses no Calling word (%s)" % [id, word])

	# --- Heavy Going ----------------------------------------------------------------------------------------------
	_take("heavy_going")
	var drop := _plant("dewdrop", spot)
	var near_spore := _plant("sporeling", spot + Vector2(CELL, 0))
	var far_spore := _plant("sporeling", spot + Vector2(CELL * 8, 0))
	await _frames(2)
	var puddles = dreams.puddles
	var n = _spawn(spot + Vector2(0, CELL))
	_check(is_equal_approx(puddles.damage_multiplier(n, drop), 1.0), "Heavy Going: not slowed, no bonus")
	n.statuses.add_slow(0.25, 3.0)
	_check(is_equal_approx(puddles.damage_multiplier(n, drop), puddles.HEAVY_GOING_BONUS), "...slowed: a Dewdrop deals +25%")
	_check(is_equal_approx(puddles.damage_multiplier(n, near_spore), puddles.HEAVY_GOING_BONUS), "...a Warden near a Dewdrop too")
	_check(is_equal_approx(puddles.damage_multiplier(n, far_spore), 1.0), "...a Warden far from every Dewdrop: nothing")
	_check(is_equal_approx(puddles.damage_multiplier(n, drop, &"spored"), 1.0), "...hits only")
	var sleepy = _spawn(spot + Vector2(CELL, CELL))
	sleepy.apply_status(EnemyStatuses.DROWSY, 2, 5.0, 1.0, 0, "song", null)
	_check(is_equal_approx(puddles.damage_multiplier(sleepy, drop), 1.0), "...Sleep's slow doesn't count")
	await _clean()

	# --- Fruiting -------------------------------------------------------------------------------------------------
	_take("fruiting")
	var spore := _plant("sporeling", spot)
	var friend := _plant("firefly_jar", spot + Vector2(CELL, 0))
	var far_jar := _plant("firefly_jar", spot + Vector2(CELL * 8, 0))
	await _frames(2)
	var sp = dreams.spore_print
	n = _spawn(spot + Vector2(0, CELL))
	_check(is_equal_approx(sp.damage_multiplier(n, spore), 1.0), "Fruiting: no other Warden hit it: nothing (not flat)")
	sp._note_hitter(spore, n)
	_check(is_equal_approx(sp.damage_multiplier(n, spore), 1.0), "...its own earlier hit doesn't count")
	sp._note_hitter(friend, n)
	_check(is_equal_approx(sp.damage_multiplier(n, spore), 1.0 + sp.FRUIT_PER_WARDEN), "...one other Warden: +6%")
	_check(is_equal_approx(sp.damage_multiplier(n, friend), 1.0 + sp.FRUIT_PER_WARDEN), "...a Warden near a Sporeling gets it too")
	sp._note_hitter(far_jar, n)
	_check(is_equal_approx(sp.damage_multiplier(n, far_jar), 1.0), "...a Warden far from every Sporeling: nothing")
	var crowd: Array = []
	for i in 7:
		crowd.append(_plant("sprout", spot + Vector2(CELL * (i - 3), -CELL)))
	for t in crowd:
		sp._note_hitter(t, n)
	_check(is_equal_approx(sp.damage_multiplier(n, spore), 1.0 + sp.FRUIT_MAX), "...capped at +30%")
	_check(is_equal_approx(sp.damage_multiplier(n, spore, &"spored"), 1.0), "...hits only")
	await _clean()

	# --- Parting Puff ---------------------------------------------------------------------------------------------
	_take("parting_puff")
	spore = _plant("sporeling", spot)
	await _frames(2)
	var victim = _spawn(spot + Vector2(0, CELL), 1)
	var neighbour = _spawn(spot + Vector2(CELL * 0.5, CELL))
	var before: float = neighbour.health
	spore.hit(victim, 1.0, false, Tower.NO_CRIT)
	await _frames(2)
	_check(neighbour.health < before, "Parting Puff: a Sporeling's dispelling hit puffs onto the nightmare beside it")
	await _clean()

	# --- Stomping Ground ------------------------------------------------------------------------------------------
	dreams.calling = "sporeling"
	dreams.calling_path.assign([&"sp_borrowed", &"sp_stomping"])
	dreams.bump_board()
	var stomper := _plant("firefly_jar", spot)
	var bell := _plant("bellflower", spot + Vector2(-CELL, 0))
	await _frames(2)
	n = _spawn(spot + Vector2(0, CELL))
	before = n.health
	sp._stomp(spot + Vector2(0, CELL * 0.5), n)
	_check(n.health < before, "Stomping Ground: Wardens touching the step strike the stepper")
	await _clean()

	# --- Midnight Toll --------------------------------------------------------------------------------------------
	dreams.calling = "bellflower"
	dreams.calling_path.assign([&"kt_evo_steady_beat", &"kt_evo_crescendo", &"kt_evo_midnight_bell"])
	dreams.bump_board()
	bell = _plant("bellflower", spot)
	await _frames(2)
	n = _spawn(spot + Vector2(0, CELL))
	before = n.health
	dreams.keeping_time._midnight(n, bell)
	# A Calling hit since section 33: the free-hit base min(hit, one second of damage), so slow bells deal less than 3 hits
	_check(before - n.health >= minf(bell.get_damage(), dreams.keeping_time.second_of(bell)) * dreams.keeping_time.MIDNIGHT_TRIPLE * 0.5,
		"Midnight Toll: the bell hits for triple with no status on the nightmare (%.1f)" % (before - n.health))
	await _clean()

	# --- Offer gates ----------------------------------------------------------------------------------------------
	var overnight: UpgradeData = load("res://resource/dream/overnight.tres")
	if dreams._families_owned() < 2:
		_check(not dreams.card_needs_met(overnight), "Overnight waits for a second family")
	var slow_burn: UpgradeData = load("res://resource/dream/slow_burn.tres")
	dreams.calling = "dewdrop"
	dreams.calling_path.assign([])
	_check(dreams.card_needs_met(slow_burn) and not DreamState.CARD_NEEDS.has("slow_burn"),
		"Slow Burn needs no other card or evolution (section 36: it reads the status's age)")
	dreams.calling = "firefly_jar"
	dreams.calling_path.assign([&"lf_bonfire", &"lf_moth_to_flame"])
	_check(dreams.owns("lanternmoth") or not dreams._requires_met(load("res://resource/dream/bright_marks.tres")),
		"Bright Marks no longer comes with Moth to Flame (it builds crits, not Exposure, since the 2026-10-23 rebuild)")
	await _clean()

	print("test_nonstatus_builds: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	main.queue_free()
	await _frames(2)
	quit(failures)
