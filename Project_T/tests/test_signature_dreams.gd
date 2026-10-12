extends SceneTree

var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func _plant(main: Node, id: String, cell: Vector2) -> Tower:
	var tower: Tower = load("res://scenes/tower/tower.tscn").instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = cell
	tower.position = Tower.MAP_GRID.calculate_map_position(cell)
	main.get_node("%TowerContainer").add_child(tower)
	tower.set_process(false)
	return tower
func _run() -> void:
	var statuses := EnemyStatuses.new()
	statuses.apply(EnemyStatuses.STATIC, statuses.get_max_stacks(EnemyStatuses.STATIC), 2.0, 1.0)
	_check(statuses.applications == 1 and not statuses.has(EnemyStatuses.STATIC), "accepted charge is recorded even when immediately consumed by bolt")
	statuses.immune.append(EnemyStatuses.MARKED)
	statuses.apply(EnemyStatuses.MARKED)
	_check(statuses.applications == 1, "rejected immune transfer is not recorded as accepted")
	statuses.hold_cooldown = 1.0
	statuses.apply(EnemyStatuses.HELD)
	_check(statuses.applications == 1, "hold cooldown rejection is not a transfer")
	var partial := EnemyStatuses.new()
	var cap := partial.get_max_stacks(EnemyStatuses.STATIC)
	var early_bolt := partial.apply(EnemyStatuses.STATIC, cap - 1, 2.0, 1.0)
	_check(early_bolt == 0.0 and partial.has(EnemyStatuses.STATIC), "charge below current cap remains stored")
	var completed_bolt := partial.apply(EnemyStatuses.STATIC, 1, 2.0, 1.0)
	_check(completed_bolt > 0.0 and partial.applications == 2 and not partial.has(EnemyStatuses.STATIC),
		"final accepted charge triggers bolt and retains accepted application record")
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	await process_frame
	var dreams: DreamState = main.get_node("%DreamState")
	var wall := _plant(main, "thornwall", Vector2(80, 80))
	var weak := _plant(main, "sprout", Vector2(79, 79))
	var strong := _plant(main, "sporeling", Vector2(81, 80))
	strong.rank = 4
	dreams.stacks = {"briar_crown": 1}
	dreams.bump_board()
	_check(dreams.briar_source(wall) == strong, "crown source is strongest touching attacker, including diagonal contacts")
	strong._turnover_until = strong._anim_time + 2.0
	dreams.stacks = {"quickened_sap": 1, "momentum": 1}
	dreams.bump_board()
	strong._grove[&"streak"] = 3
	var tempo := DreamTempoView.tempo_text(strong, dreams)
	_check(tempo.contains("Turnover +35%") and tempo.contains("Momentum +18%"), "selected tempo reports live sources separately")
	strong._turnover_until = -1.0
	strong._grove[&"streak"] = 0
	_check(DreamTempoView.tempo_text(strong, dreams) == "", "expired tempo cues leave no stale bonus")
	dreams.stacks = {"briar_crown": 1}
	dreams.bump_board()
	strong.free()
	_check(dreams.briar_source(wall) == weak, "source follows sales without retaining a freed Warden")
	weak.free()
	_check(dreams.briar_source(wall) == null, "unpowered wall has no source")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var panel: Node = main.get_node("HUD/DriftPanel")
	dreams.stacks = {"restless_night": 1}
	dreams.bump_board()
	director._active = {1: {"called_early": true, "remaining": 1}, 2: {"called_early": true, "remaining": 1}}
	director._refresh_early_overlap()
	_check(panel.impatient_label.visible, "overlap signal immediately shows active bonus")
	_check(panel.impatient_label.text.contains("100%"), "active cue reports actual bonus")
	director._active[2].remaining = 0
	director._refresh_early_overlap()
	_check(not panel.impatient_label.visible, "cue ends immediately when overlap ends")
	dreams.stacks.clear()
	director._active[2].remaining = 1
	director._refresh_early_overlap()
	_check(not panel.impatient_label.visible, "overlap alone cannot show an unowned Dream")
	dreams.stacks = {"last_breath": 1, "passing_dream": 1}
	dreams.bump_board()
	Fx.view_rect = Rect2()
	var container := main.get_node("%EnemyContainer")
	var origin := _spawn(main, Vector2(80, 80))
	var recipient := _spawn(main, Vector2(81, 80))
	origin.apply_status(EnemyStatuses.MARKED)
	dreams._passing_dream(origin)
	dreams._last_breath(origin)
	_check(container.get_enemies().size() == 2, "burst and transfer feedback never enters the enemy-only container")
	var transfer := main.get_node_or_null("DreamTransferFeedback")
	_check(transfer != null and transfer.links.size() == 1, "accepted transfer gets a world-owned cue")
	transfer.links.clear()
	recipient.statuses.immune.append(EnemyStatuses.MARKED)
	dreams._passing_dream(origin)
	_check(transfer.links.is_empty(), "existing Mark does not produce a false cue for a refused transfer")
	main.queue_free()
	await process_frame
	await process_frame
	print("Signature Dreams: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _spawn(main: Node, cell: Vector2) -> Node2D:
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
