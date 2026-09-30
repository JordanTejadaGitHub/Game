extends SceneTree

# The Sprout price rule on the Warden bar (warden_stats.md "The rule is shown"): the tooltip explains
# it, a "↑ 5/10" tag counts to the next rise, and the first rise in a run toasts once.

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var map_generator = main.get_node("%MapGenerator")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var run_state: RunState = main.get_node("%RunState")
	var hud = main.get_node("HUD")
	run_state.dew = 1000
	var sprout: TowerData = load("res://resource/tower/sprout.tres")
	var toasts := []
	var planted := 0
	var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	for i in range(3, path.size() - 3):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = path[i] + offset
			if planted >= 6 or path.has(cell) or not map_generator.can_block(cell):
				continue
			placer.tower_data = sprout
			if placer._try_build(cell):
				planted += 1
				await process_frame
				await process_frame
				if hud.toast_label.visible and hud.toast_label.text.begins_with("Sprouts now cost"):
					toasts.append(hud.toast_label.text)
	_check(planted == 6, "planted 6 Sprouts (%d)" % planted)
	var button: Button = hud.tower_bar.get_node("Warden_sprout")
	var tag := button.get_node_or_null("SproutRise") as Label
	_check(tag != null and tag.visible and tag.text == "↑ 6/10", "the tag counts to the next rise (%s)" % (tag.text if tag else "none"))
	_check(button.tooltip_text.contains("Every 5 Sprouts on the map add +3 Dew") and button.tooltip_text.contains("next rise at 10 Sprouts"),
		"the tooltip states the rule (%s)" % button.tooltip_text)
	_check(toasts.size() >= 1 and hud._sprout_rise_told, "the first rise toasts (%s)" % [toasts])
	_check(button.text == str(placer.get_cost(sprout)), "the button shows the current price")
	print("sprout price ui test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
