extends SceneTree

# Headless test for the Legendary rules Tower Code reads (dream_design.md "New Legendaries", "The
# Eldest"): Hunter's Moon, Eternal Charge, Rooted Nightmares, the reworked Nightshade, the Eldest's
# rank cap and confirm, Court of the Eldest's shared ranks, and rank names past VII. Run from the
# project folder:
#   godot --headless --path . --script res://tests/test_legendary_hits.gd --fixed-fps 60

const CELL := 64.0

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
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

	_check(Tower.rank_name(5) == "V" and Tower.rank_name(8) == "VIII" and Tower.rank_name(14) == "XIV"
		and Tower.rank_name(99) == "XCIX", "rank names past VII are worked out")

	var sprout := _plant("sprout", Vector2(2, 2))

	# --- Hunter's Moon: a Warden's first hit Exposes, and it never runs out ---
	_take("hunters_moon")
	var a := _spawn(sprout.global_position + Vector2(CELL, 0))
	sprout.hit(a, 1.0, false, Tower.NO_CRIT)
	_check(a.statuses.has(EnemyStatuses.MARKED), "Hunter's Moon: the first hit Exposes it")
	a.statuses.tick(30.0)
	_check(a.statuses.has(EnemyStatuses.MARKED), "and it never runs out")
	await _clean()

	# --- Eternal Charge: every 4th hit adds a Charge; Charges never decay ---
	_take("eternal_static")
	var b := _spawn(sprout.global_position + Vector2(CELL, 0))
	sprout._hits_landed = 0
	for i in 4:
		sprout.hit(b, 0.0, false, Tower.NO_CRIT)
	_check(b.statuses.stacks(EnemyStatuses.STATIC) == 1, "Eternal Charge: the 4th hit adds a Charge (%d)" % b.statuses.stacks(EnemyStatuses.STATIC))
	b.statuses.tick(30.0)
	_check(b.statuses.stacks(EnemyStatuses.STATIC) == 1, "and it never decays")
	await _clean()

	# --- Rooted Nightmares: every 8th hit Roots for 1 s ---
	_take("rooted_nightmares")
	var c := _spawn(sprout.global_position + Vector2(CELL, 0))
	sprout._hits_landed = 0
	for i in 7:
		sprout.hit(c, 0.0, false, Tower.NO_CRIT)
	_check(not c.statuses.is_held(), "not before the 8th hit")
	sprout.hit(c, 0.0, false, Tower.NO_CRIT)
	_check(c.statuses.is_held(), "Rooted Nightmares: the 8th hit Roots it")
	await _clean()

	# --- Nightshade: an effect's damage makes the other effects deal 25% of their tick ---
	_take("nightshade")
	var d := _spawn(sprout.global_position + Vector2(CELL, 0))
	d.apply_status(EnemyStatuses.SPORED, 4, 5.0, 10.0, 0, "spore", sprout)
	var before: int = d.health
	d.take_damage(1.0, "light", true, false, sprout, &"static")
	await process_frame  # Nightshade lands right after the damage that set it off
	var expected := 1.0 + 4 * 10.0 * Reactions.NIGHTSHADE_TICK * Reactions.NIGHTSHADE_SHARE
	_check(absi((before - d.health) - int(expected)) <= 1,
		"Nightshade: a Charged bolt makes the Poison tick at 25%% (%d, expected ~%d)" % [before - d.health, int(expected)])
	await _clean()

	# --- The Eldest and its Court ---
	_take("endless_rings")
	var elder := _plant("sprout", Vector2(6, 6))
	var friend := _plant("sprout", Vector2(7, 6))
	for t in [elder, friend]:
		t.rank = 5
		t.focus = Tower.Focus.POWER  # Ranks III+ come with a Focus
	var run_state: RunState = main.get_node("%RunState")
	run_state.dew = 100000
	_check(dreams.needs_eldest_confirm(elder), "rank VI would make it the Eldest")
	_check(not placer.nurture(elder), "the placer won't buy VI without the confirm")
	_check(dreams.make_eldest(elder) and placer.nurture(elder) and elder.rank == 6, "confirmed: it grows to VI")
	_check(friend.get_max_rank() == 5 and not friend.can_nurture(), "everyone else stops at V")
	_take("court_of_the_eldest")
	var alone := _plant("sprout", Vector2(12, 12))
	alone.rank = 5
	alone.focus = Tower.Focus.POWER
	_check(friend.get_court_ranks() > 0.0 and alone.get_court_ranks() == 0.0, "Court: only Wardens touching the Eldest share its ranks")
	_check(friend.get_damage() > alone.get_damage(), "and hit harder for it")

	print("legendary hits test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
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
