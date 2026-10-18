extends SceneTree

var failures := 0
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var enemy = main.get_node("%EnemyContainer").spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	enemy.set_process(false)
	enemy.statuses.apply(EnemyStatuses.STATIC, 159, 5.0, 0.0, 160)
	enemy.statuses.apply(EnemyStatuses.SPORED, 160, 5.0, 0.0, 160)
	enemy.statuses.apply(EnemyStatuses.DROWSY, 128, 5.0, 0.0, 160)
	enemy._update_hud_layout()
	for i in range(1, enemy._hud_ids.size()):
		var previous: Rect2 = enemy._stack_pill(i - 1)
		var current: Rect2 = enemy._stack_pill(i)
		_check(previous.end.x + enemy.STATUS_BADGE_GAP <= current.position.x, "three-digit stack pills have space between them")
	var corner: Vector2 = enemy._badge_centre(0) + Vector2(enemy.get_badge_size() / 2.0 + 2.0, enemy.get_badge_size() / 2.0 + 1.0)
	_check(enemy._stack_pill(0).end.is_equal_approx(corner), "count labels sit on the icon bottom-right corner")
	_check(enemy.statuses.describe(EnemyStatuses.SPORED).contains("160/160"), "enemy details retain exact current/max counts")
	var low = main.get_node("%EnemyContainer").spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	low.set_process(false)
	low.statuses.apply(EnemyStatuses.DAMP, 4)
	low.statuses.apply(EnemyStatuses.HELD, 3)  # (3: below Root's Reaction need of 4, so no Reaction-ready room)
	low._update_hud_layout()
	var compact: float = low._badge_centre(1).x - low._badge_centre(0).x
	_check(compact <= 36.0, "small counts retain a compact badge row")
	low.statuses.apply(EnemyStatuses.HELD, 1)  # 4 Root: Reaction-ready
	low._update_hud_layout()
	# (Root shows before Soak, so its room on the right is what moves Soak along)
	_check(low._hud_ids == [&"held", &"damp"] and low._hud_primed == [true, false] \
		and is_equal_approx(low._badge_centre(1).x - low._badge_centre(0).x, compact + low.READY_PAD_RIGHT),
		"a Reaction-ready badge gets room for its corner brackets, and only that")
	if "--capture" in OS.get_cmdline_user_args():
		main.hide()
		for layer in main.find_children("*", "CanvasLayer", true, false):
			layer.visible = false
		main.process_mode = Node.PROCESS_MODE_DISABLED
		var camera := root.get_camera_2d()
		if camera:
			camera.enabled = false
		var showcase := Node2D.new()
		root.add_child(showcase)
		RenderingServer.set_default_clear_color(Color("#182125"))
		enemy.reparent(showcase)
		low.reparent(showcase)
		enemy.position = Vector2(390, 180)
		low.position = Vector2(390, 340)
		enemy._hud_pops.clear()
		low._hud_pops.clear()
		enemy._spawner.hud_text_scale = 1.0
		enemy._update_hud(0.0)
		low._update_hud(0.0)
		var labels := CanvasLayer.new()
		root.add_child(labels)
		for row in [["High caps: 128–160 stacks", 40], ["Small caps: individual pips", 200]]:
			var label := Label.new()
			label.text = row[0]
			label.position = Vector2(220, row[1])
			label.add_theme_font_size_override("font_size", 22)
			labels.add_child(label)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tools/balance_out/status_badge_preview.png")
		showcase.queue_free()
		labels.queue_free()
	print("status badge UI test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + label)