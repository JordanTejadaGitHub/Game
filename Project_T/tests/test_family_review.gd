extends SceneTree

# Headless test for the family review's Wardens (tower_design.md 7e574e0, warden_stats.md): the
# Bellflower family (Bellflower, Chime Stone, Lullaby Bell, Dreamcatcher, Great Dreamcatcher, Echo
# Hollow, Whispering Hollow), Cairn / Rockslide's lob and rubble, Hummingbird Bower / Jewelwing
# Court's pecks, Samara / Autumn Gale's boomerang seeds, and the data (art, cards, evolution links,
# Standing Stone no longer hidden). Run from the project folder:
#   godot --headless --path . --script res://tests/test_family_review.gd --fixed-fps 60

const CELL := 64.0
const NEW := ["bellflower", "chime_stone", "lullaby_bell", "dreamcatcher", "great_dreamcatcher", "echo_hollow",
	"whispering_hollow", "cairn", "rockslide", "hummingbird_bower", "jewelwing_court", "samara", "autumn_gale"]
const HIDDEN := ["echo_hollow", "whispering_hollow", "cairn", "rockslide", "hummingbird_bower", "jewelwing_court",
	"samara", "autumn_gale"]

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
	dreams.unlock_everything = true
	await _clean()

	_test_data()
	await _test_bellflower_pulses()
	await _test_dreamcatcher()
	await _test_echo()
	await _test_lob()
	await _test_pecks()
	await _test_seeds()

	print("family review test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)


func _test_data() -> void:
	var reachable := {}
	var stack: Array = placer.towers.duplicate()
	while not stack.is_empty():
		var data: TowerData = stack.pop_back()
		if reachable.has(data.get_id()):
			continue
		reachable[data.get_id()] = true
		stack.append_array(data.evolves_to)
	for id in NEW:
		var data := load("res://resource/tower/%s.tres" % id) as TowerData
		_check(data != null and data.texture != null and data.attack_texture != null, "%s has its art" % id)
		_check(reachable.has(id), "%s can be reached" % id)
		var card := load("res://resource/dream/dream_%s.tres" % id) as UpgradeData
		_check(card != null and card.unlocks == data, "%s has an unlock card" % id)
		if card:
			_check(card.in_start_pool == not (id in HIDDEN or id == "bellflower"), "%s's card pool is right" % id)
	var bell: TowerData = load("res://resource/tower/bellflower.tres")
	_check(bell.line == "song" and bell.applies_status == EnemyStatuses.DROWSY, "Bellflower is the song family and applies Drowsy")
	for id in ["chime_stone", "lullaby_bell"]:
		_check(load("res://resource/tower/%s.tres" % id).line == "song", "%s moved to the song family" % id)
	for id in ["standing_stone", "moonstone"]:
		var card := load("res://resource/dream/dream_%s.tres" % id) as UpgradeData
		_check(card.in_start_pool and dreams.get_unlock_blocker(card.unlocks) != "Memory Grove", "%s is no longer hidden" % id)


# --- Bellflower, Chime Stone, Lullaby Bell -----------------------------------------------------------

func _test_bellflower_pulses() -> void:
	var bell := _plant("bellflower", Vector2(5, 5))
	var sleepy := _spawn(bell.global_position + Vector2(CELL, 0))
	bell._release()
	_check(not sleepy.statuses.has(EnemyStatuses.DROWSY) and _lost(sleepy) > 0, "Bellflower's 1st pulse: damage, no Drowsy")
	bell._release()
	_check(sleepy.statuses.stacks(EnemyStatuses.DROWSY) == 1, "its 2nd pulse adds Drowsy")
	_check(_rings() == 1, "the Drowsy pulse draws its pink ring (%d)" % _rings())
	_clear_rings()
	# Counted per nightmare (story chat 2026-10-01): one walking in on an odd pulse still gets it on its 2nd hit.
	var late := _spawn(bell.global_position + Vector2(0, CELL))
	bell._release()  # Pulse 3: late's 1st hit
	_check(not late.statuses.has(EnemyStatuses.DROWSY), "a nightmare's 1st hit (the Warden's 3rd pulse): no Drowsy")
	_check(_rings() == 0, "a pulse that brings no Drowsy draws no Drowsy ring")
	bell._release()  # Pulse 4: late's 2nd hit
	_check(late.statuses.stacks(EnemyStatuses.DROWSY) == 1, "its 2nd hit makes it Drowsy, though the Warden is on an odd count")
	_check(_rings() == 1, "the Drowsy pulse draws its pink ring (%d)" % _rings())
	await _clean()

	var chime := _plant("chime_stone", Vector2(5, 5))
	var charged := _spawn(chime.global_position + Vector2(CELL, 0))
	charged.apply_status(EnemyStatuses.STATIC, 2, 0.0, 10.0, 0, "light", chime)
	var before := _lost(charged)
	chime._release()  # +1 Static = 3: sets off a bolt
	_check(not charged.statuses.has(EnemyStatuses.STATIC), "Chime Stone sets off a bolt at 3 Static")
	_check(_lost(charged) - before > int(chime.get_damage()), "the bolt deals extra damage")
	await _clean()

	var lullaby := _plant("lullaby_bell", Vector2(5, 5))
	var both := _spawn(lullaby.global_position + Vector2(CELL, 0))
	lullaby._release()
	_check(both.statuses.has(EnemyStatuses.STATIC) and both.statuses.has(EnemyStatuses.DROWSY), "Lullaby Bell: Static and Drowsy")
	await _clean()


# --- Dreamcatcher --------------------------------------------------------------------------------------

func _test_dreamcatcher() -> void:
	var catcher := _plant("dreamcatcher", Vector2(5, 5))
	var drowsy := _spawn(catcher.global_position + Vector2(CELL, 0))
	var plain := _spawn(catcher.global_position + Vector2(0, CELL))
	drowsy.apply_status(EnemyStatuses.DROWSY, 5)
	catcher._update_catch(1.0)
	_check(drowsy.statuses.is_caught() and not plain.statuses.is_caught(), "full Drowsy in range is Caught")
	# Status jobs (2026-09-29): Caught gives no damage bonus any more; its statuses stop wearing off.
	_check(is_equal_approx(drowsy.statuses.get_damage_taken_multiplier(), 1.0), "Caught: no damage bonus")
	await _clean()

	var great := _plant("great_dreamcatcher", Vector2(5, 5))
	var sleeper := _spawn(great.global_position + Vector2(CELL, 0))
	sleeper.statuses.sleep_time = 2.0
	great._update_catch(1.0)
	_check(sleeper.statuses.is_caught() and is_equal_approx(sleeper.statuses.caught_bonus, great.tower_data.caught_bonus), "Great: asleep is Caught at its caught_bonus")
	_check(is_equal_approx(sleeper.statuses.sleep_time, 3.0), "sleep in its range lasts 1 s longer")
	great._catch_tick = 0.0
	great._update_catch(1.0)
	_check(is_equal_approx(sleeper.statuses.sleep_time, 3.0), "only once per nightmare")
	var shards_before: int = dreams.get("dreamlight_shards") if "dreamlight_shards" in dreams else -1
	sleeper.dispel()
	if shards_before >= 0:
		_check(dreams.dreamlight_shards == shards_before + 1, "a Caught nightmare dispelled drops a Dreamlight shard")
	await _clean()


# --- Echo Hollow ---------------------------------------------------------------------------------------

func _test_echo() -> void:
	var hollow := _plant("echo_hollow", Vector2(5, 5))
	var jar := _plant("firefly_jar", Vector2(1, 1))
	await process_frame  # The Hollow listens once it's in the tree
	var wet := _spawn(hollow.global_position + Vector2(CELL, 0))
	wet.apply_status(EnemyStatuses.DAMP)
	wet.apply_status(EnemyStatuses.STATIC, 3, 0.0, jar.get_damage(), 0, "light", jar)  # Thunderclap
	var after_clap := _lost(wet)
	_check(after_clap > 0, "a Thunderclap goes off next to the Hollow")
	await _wait(1.2)
	var echo := _lost(wet) - after_clap
	var expected := int(Reactions.ECHO_DAMAGE[&"thunderclap"] * jar.get_damage() * hollow.tower_data.echo_share * hollow.get_potency())  # Echoes are effects: × Potency
	_check(absi(echo - expected) <= 1, "1 s later it echoes at its echo_share (%d, expected %d)" % [echo, expected])
	var tracker := main.get_tree().get_first_node_in_group(ReactionTracker.GROUP) as ReactionTracker
	var claps: int = tracker.counts.get(&"thunderclap", 0)
	await _wait(1.2)
	_check(tracker.counts.get(&"thunderclap", 0) == claps and _lost(wet) - after_clap == echo, "echoes don't echo")
	await _clean()

	var whisper := _plant("whispering_hollow", Vector2(5, 5))
	var jar2 := _plant("firefly_jar", Vector2(1, 1))
	await process_frame
	var wet2 := _spawn(whisper.global_position + Vector2(CELL, 0))
	wet2.apply_status(EnemyStatuses.DAMP)
	var longest := tracker.longest_chain
	wet2.apply_status(EnemyStatuses.STATIC, 3, 0.0, jar2.get_damage(), 0, "light", jar2)
	await _wait(1.2)
	_check(tracker.longest_chain >= maxi(longest, 2), "Whispering Hollow's echo counts as a chain link")
	await _clean()

	# The echo follows the nightmare (tower_design.md 369de303; Balancing: echoes on the old spot missed every
	# walking nightmare): a walking Shade is hit 1 s later though it moved more than a cell; one dispelled in
	# the meantime echoes where it died.
	var walker: Node2D = spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	walker.max_health = 100000
	walker.health = 100000
	await _wait(2.0)  # Onto the map, walking
	var listener := _plant("whispering_hollow", Tower.MAP_GRID.calculate_grid_coordinates(walker.global_position) + Vector2(0, 1))
	listener.position = walker.global_position + Vector2(0, CELL)
	var charger := _plant("firefly_jar", Vector2(1, 1))
	await process_frame
	walker.apply_status(EnemyStatuses.DAMP)
	walker.apply_status(EnemyStatuses.STATIC, 3, 0.0, charger.get_damage(), 0, "light", charger)  # Thunderclap
	var clap_at := walker.global_position
	await _wait(1.25)
	var echoed: Array = walker.recent_hits.filter(func(e) -> bool: return e.tag == &"echo" and e.source == listener)
	_check(walker.global_position.distance_to(clap_at) > CELL and echoed.size() == 1,
		"a walking Shade (moved %.0f px) still takes the echo 1 s later (%d echo hits)" % [walker.global_position.distance_to(clap_at), echoed.size()])
	var doomed := _spawn(listener.global_position + Vector2(CELL, 0))
	doomed.apply_status(EnemyStatuses.DAMP)
	doomed.apply_status(EnemyStatuses.STATIC, 3, 0.0, charger.get_damage(), 0, "light", charger)
	var died_at := doomed.global_position + Vector2(0, CELL * 2.0)  # Walked 2 cells on before it was dispelled
	doomed.global_position = died_at
	doomed.dispel()
	var mourner := _spawn(died_at)
	await _wait(1.25)
	_check(mourner.recent_hits.any(func(e) -> bool: return e.tag == &"echo"), "one dispelled before its echo echoes where it died")
	await _clean()


# --- Cairn / Rockslide ---------------------------------------------------------------------------------

func _test_lob() -> void:
	var cairn := _plant("cairn", Vector2(3, 5))
	var close := _spawn(cairn.global_position + Vector2(CELL, 0))
	var far := _spawn(cairn.global_position + Vector2(5 * CELL, 0))
	var beside := _spawn(far.global_position + Vector2(0, 0.8 * CELL))
	var lob_target := cairn.find_target()
	_check(lob_target != close and (lob_target == far or lob_target == beside), "Cairn can't lob at nightmares within 2 cells (it picks one further out)")
	cairn.fire_at(far)
	await _wait(2.0)
	_check(_lost(far) > 0 and _lost(beside) > 0, "the stone splashes everything within 1 cell of where it lands")
	_check(_lost(close) == 0, "not the nightmare right beside the Cairn")
	await _clean()

	var slide := _plant("rockslide", Vector2(3, 5))
	var route: PackedVector2Array = main.get_node("%MapGenerator").get_path_from(main.get_node("%MapGenerator").startPath)
	var spot: Vector2 = route[mini(12, route.size() - 1)]
	var on_path := _spawn(Tower.MAP_GRID.calculate_map_position(spot))
	slide.position = Tower.MAP_GRID.calculate_map_position(spot + Vector2(4, 0))
	slide.global_position = slide.position
	slide._lob_landed(on_path.global_position, 1.25 * CELL)
	var patches := main.get_children().filter(func(n: Node) -> bool: return n is RubblePatch)
	_check(patches.size() == 1, "Rockslide leaves rubble on the path")
	await _wait(0.4)
	_check(on_path.statuses.slow_time > 0.0 and is_equal_approx(on_path.statuses.slow_amount, slide.tower_data.rubble_slow),
		"nightmares on the rubble are slowed by its rubble_slow")
	await _clean()


# --- Hummingbird Bower / Jewelwing Court -----------------------------------------------------------------

func _test_pecks() -> void:
	var bower := _plant("hummingbird_bower", Vector2(5, 5))
	bower.tower_data = bower.tower_data.duplicate()
	bower.tower_data.crit_chance = 0.0
	bower._apply_data()
	var prey := _spawn(bower.global_position + Vector2(2 * CELL, 0))
	var hits := [0]
	bower.hit_landed.connect(func(_t, _e, _a, _c) -> void: hits[0] += 1)
	bower._release()
	_check(not bower._has_work(), "no new attack while the bird is out")
	await _wait(2.5)
	_check(hits[0] == 6, "a hummingbird pecks 6 times, each a full hit (%d)" % hits[0])
	_check(_lost(prey) == 6 * int(bower.get_damage()), "6 × its damage")
	_check(bower._has_work(), "the bird came home")
	await _clean()

	var court := _plant("jewelwing_court", Vector2(5, 5))
	court.tower_data = court.tower_data.duplicate()
	court.tower_data.crit_chance = 0.0
	court._apply_data()
	var a := _spawn(court.global_position + Vector2(2 * CELL, 0))
	var b := _spawn(court.global_position + Vector2(-2 * CELL, 0))
	var crits := [0]
	court.crit_landed.connect(func(_t, _e) -> void: crits[0] += 1)
	court._release()
	await _wait(3.5)
	_check(_lost(a) > 0 and _lost(b) > 0, "Jewelwing's birds spread over several nightmares")
	var pecks: int = court.tower_data.peck_birds * court.tower_data.pecks
	_check(crits[0] == pecks / court.tower_data.flurry_every, "Flurry: every 6th of the %d pecks crits (%d)" % [pecks, crits[0]])
	court.focus_strongest = true
	a.health = a.max_health * 2  # The strongest now
	var b_before := _lost(b)
	court._release()
	await _wait(2.5)
	_check(_lost(b) == b_before, "focused: every bird on the strongest")
	await _clean()


# --- Samara / Autumn Gale -------------------------------------------------------------------------------

func _test_seeds() -> void:
	var samara := _plant("samara", Vector2(5, 5))
	samara.tower_data = samara.tower_data.duplicate()
	samara.tower_data.crit_chance = 0.0
	samara._apply_data()
	var first := _spawn(samara.global_position + Vector2(1.5 * CELL, 0))
	var second := _spawn(samara.global_position + Vector2(3 * CELL, 0))
	var aside := _spawn(samara.global_position + Vector2(2 * CELL, 2 * CELL))
	samara.set_target_mode(TowerData.TargetMode.CLOSEST)  # Fresh nightmares tie on progress: aim down the line on purpose
	first.apply_status(EnemyStatuses.SPORED, 4, 10.0, 1.0)
	samara._release()
	await _wait(0.6)
	_check(not samara._has_work(), "can't throw again until it catches the seed")
	await _wait(2.0)
	var per_pass := int(samara.get_damage())
	_check(_lost(second) >= 2 * per_pass, "the seed hits each nightmare on the line twice (out and back)")
	_check(_lost(aside) == 0, "and nothing off the line")
	_check(second.statuses.stacks(EnemyStatuses.SPORED) >= 2, "it carries the first nightmare's statuses down the line")
	_check(samara._has_work(), "caught: ready to throw again")
	await _clean()

	var gale := _plant("autumn_gale", Vector2(5, 5))
	for offset in [Vector2(2, 0), Vector2(3, 0), Vector2(0, 2), Vector2(0, 3), Vector2(-2, -2)]:
		_spawn(gale.global_position + offset * CELL)
	gale._release()
	var seeds := main.get_children().filter(func(n: Node) -> bool: return n is SeedBoomerang)
	_check(seeds.size() == gale.tower_data.boomerang_seeds, "Autumn Gale throws its boomerang_seeds (%d)" % seeds.size())
	await _wait(3.0)
	_check(is_equal_approx(gale._catch_streak, 0.1), "a caught throw that hit makes the next throw +10%")
	gale._seeds_thrown = 1
	gale.catch_seed(false)
	_check(gale._catch_streak == 0.0, "a throw that hits nothing resets it")
	await _clean()


# --- Helpers ----------------------------------------------------------------------------------------------

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _wait(seconds: float) -> void:
	await create_timer(seconds, true, true).timeout

func _rings() -> int:
	return root.find_children("*", "Node2D", true, false).filter(func(n: Node) -> bool: return n is DrowsyRing and not n.is_queued_for_deletion()).size()

func _clear_rings() -> void:
	for node in root.find_children("*", "Node2D", true, false):
		if node is DrowsyRing:
			node.queue_free()

func _lost(enemy: Node2D) -> int:
	return enemy.max_health - enemy.health if is_instance_valid(enemy) else 0

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
	enemy.max_health = 100000
	enemy.health = 100000
	return enemy

func _clean() -> void:
	for child in spawner.get_children():
		child.queue_free()
	for tower in container.get_children():
		tower.queue_free()
	for node in main.get_children():
		if node is ReactionCloud or node is RubblePatch or node is SeedBoomerang:
			node.queue_free()
	await process_frame
