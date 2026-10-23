extends SceneTree
# class_kit.calling_hit and dream_hit_cards.preview_multiplier (owner 2026-10-23, dream_council_review.md 33;
# evo_shared_spec.md 3, 4, 9). Written 2026-10-23, parse-checked, NOT RUN (the owner runs tests on request).
#   godot --headless --fixed-fps 60 --path . --script res://tests/test_calling_hit.gd

const CELL := 64.0
var failures := 0
var main: Node
var spawner: Node
var placer: TowerPlacer
var container: Node
var dreams: DreamState

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

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
	var kit = dreams.spore_print
	var jar := _plant("firefly_jar", Vector2(2, 2))
	var enemy := _spawn(jar.global_position + Vector2(CELL, 0))

	# The free-hit base, damage only, no Calling arm
	var statuses_before: int = enemy.statuses.active_ids().size()
	var before: int = enemy.health
	var dealt: float = kit.calling_hit(jar, enemy, 1.0, &"flare", &"lf_test")
	_check(dealt > 0.0 and dealt <= kit.second_of(jar) * jar._form_hit_multiplier() * DreamState.CARD_PRODUCT_CAP + 0.01, "a Calling hit is at most one second of damage (x form, cap) (%.1f)" % dealt)
	_check(before - enemy.health > 0, "it deals damage")
	_check(enemy.statuses.active_ids().size() == statuses_before, "it adds no status")
	_check(DamageLog.calling_next == &"", "it never arms a Calling output")
	# The budget: a second one in the same second is dropped, a base free hit still lands
	_check(kit.calling_hit(jar, enemy, 1.0, &"flare", &"lf_test") == 0.0, "a second Calling hit in 1 s is dropped")
	_check(kit.free_hit(jar, enemy, 1.0), "…but a base free hit in the same second still lands (its own budget)")
	_check(kit.calling_hit(jar, enemy, 1.0, &"flare", &"", false, true, &"") > 0.0, "budget &\"\": the caller throttles itself")
	# Boss share
	enemy.enemy_data = enemy.enemy_data.duplicate()
	enemy.enemy_data.is_boss = true
	var on_boss: float = kit.calling_hit(jar, enemy, 1.0, &"flare", &"", false, true, &"", 0.5)
	enemy.enemy_data.is_boss = false
	var off_boss: float = kit.calling_hit(jar, enemy, 1.0, &"flare", &"", false, true, &"")
	_check(is_equal_approx(on_boss * 2.0, off_boss), "a boss takes the row's share (%.1f vs %.1f)" % [on_boss, off_boss])
	# scaled = false: the amount as given
	_check(is_equal_approx(kit.calling_hit(jar, enemy, 37.0, &"deathcap", &"", false, false, &""), 37.0), "scaled = false deals the amount as given")

	# The preview is side-effect free
	dreams.stacks["bearing_down"] = 1
	dreams.stacks["nowhere_to_run"] = 1
	dreams.bump_board()
	var cards = dreams.hit_cards
	var bearing: Dictionary = cards._bearing.duplicate(true)
	var nowhere: Dictionary = cards._nowhere.duplicate(true)
	var ctx: Array = cards._ctx.duplicate()
	var notes: Dictionary = DamageLog._card_notes.duplicate(true)
	cards.preview_multiplier(jar, enemy, false)
	_check(cards._bearing == bearing and cards._nowhere == nowhere and cards._ctx == ctx, "the preview writes no hit-card state")
	_check(DamageLog._card_notes == notes, "…and notes no card bonus")
	dreams.stacks.erase("bearing_down")
	dreams.stacks.erase("nowhere_to_run")
	dreams.bump_board()

	print("test_calling_hit: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

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
