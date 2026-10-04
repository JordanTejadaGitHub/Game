extends SceneTree

# The Sprout price rule on the Warden bar (warden_stats.md "The rule is shown"): the tooltip explains
# it, a "↑ 5/10" tag counts to the next rise, and the first rise in a run toasts once.

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.size = Vector2i(1280, 800)  # A real screen (headless windows start tiny)
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
	_check(tag != null and tag.visible and tag.text == "↑ 6/%d" % (TowerPlacer.SPROUTS_PER_STEP * 2), "the tag counts to the next rise (%s)" % (tag.text if tag else "none"))
	var price_line := String(button.get_meta(&"price_line", ""))
	_check(price_line.contains("Every %d Sprouts on the map add +%d Dew" % [TowerPlacer.SPROUTS_PER_STEP, TowerPlacer.SPROUT_STEP_DEW]) and price_line.contains("next rise at %d Sprouts" % (TowerPlacer.SPROUTS_PER_STEP * 2)),
		"the hover card's price line states the rule (%s)" % price_line)
	_check(toasts.size() >= 1 and hud._sprout_rise_told, "the first rise toasts (%s)" % [toasts])
	_check(button.text == str(placer.get_cost(sprout)), "the button shows the current price")
	# Hovering a slot shows the Warden card (the panel's top half, WardenHeaderView) with its price line.
	hud._show_hover_card(button, sprout)
	await process_frame
	await process_frame
	var card: Control = hud.hover_card
	_check(card != null and card.visible and card.find_children("*", "WardenHeaderView", true, false).size() == 1
		and hud._hover_price.text.begins_with("Sprout · "), "hovering a slot shows its Warden card and price line")
	_check(card != null and card.get_global_rect().end.y <= button.get_global_rect().position.y + 1.0,
		"the card sits above the slot (%s vs %s)" % [card.get_global_rect() if card else Rect2(), button.get_global_rect()])
	hud._hide_hover_card(button)
	_check(card != null and not card.visible, "and hides when the pointer leaves")
	print("sprout price ui test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
