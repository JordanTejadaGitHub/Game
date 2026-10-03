extends SceneTree

# New rule-breaker warning (screens_ui.md "In the world"; human run 5: lost at drift 35 to Phantoms, the first
# flyers, at drift 31): at the rest before the block that brings them, the Coming strip leads with the Phantom
# (larger, "New", its trait in words), the DriftPanel warns "Flyers in drift 31: they ignore your maze", the map
# shows a thin mist line from the start straight to the Heartwood (every run: information, never retired), faint while they
# fly; the first Phantom on the field gets a name plate.
# Once faced this run the New tab, DriftPanel line and plate don't come again; the mist line follows the schedule.

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	await process_frame
	var director: DriftDirector = main.get_node("%DriftDirector")
	var phantom: EnemyData = load("res://resource/enemy/dandelion_seed.tres")
	# A 4th run: the profile was warned about Phantoms on 3 runs (the old rule retired the line then).
	var memory := HeartwoodMemory.load_data()
	memory["rule_breakers_warned"] = {"dandelion_seed": 3}
	HeartwoodMemory.save_data(memory)

	# The rest before drift 31's block.
	director.drifts_started = 30
	director.resting = true
	var coming := RuleBreakers.coming(director)
	_check(coming.any(func(item: Array) -> bool: return item[0] == phantom and item[1] == 31),
		"the Phantom is a new rule-breaker for drifts 31–35 (%s)" % [coming.map(func(i: Array) -> String: return "%s@%d" % [i[0].display_name, i[1]])])
	_check(RuleBreakers.warning_line(phantom, 31) == "Flyers in drift 31: they ignore your maze", "the warning line's words")
	_check(RuleBreakers.plate_text(phantom) == "Phantom · flies", "the name plate's words")

	# The Coming strip leads with it: larger, "New", its trait in words.
	var strip: ComingStrip = null
	for child in main.get_node("HUD").get_children():
		if child is ComingStrip:
			strip = child
	strip._built_for = ""
	strip._clock = 0.0
	strip._process(0.0)
	var items: Array = strip.items()
	var lead: Control = items[0] if not items.is_empty() else null
	_check(lead != null and lead.get_meta(&"kind") == phantom and lead.get_meta(&"breaks_rules", false)
		and lead.find_child("TraitWords", true, false) != null and lead.find_child("New", true, false) != null,
		"the Coming strip shows the Phantom first, with \"New\" and its trait in words")
	var face: Button = lead.find_child("Face", true, false) if lead != null else null
	_check(face != null and face.custom_minimum_size.x == ComingStrip.FACE_BIG and items.size() > 1
		and (items[1].find_child("Face", true, false) as Button).custom_minimum_size.x == ComingStrip.FACE, "…larger than the others")

	# Nothing clipped (user screenshot: "EW" for New, "×1?" for counts): at 1280×720 virtual (the largest UI
	# size) and 1920×1080 at 100%, every badge sits inside the strip's fog panel and clear of the next disc.
	var scale_was := [root.content_scale_mode, root.content_scale_size, root.content_scale_aspect, root.content_scale_factor, root.size]
	for case in [[Vector2i(2560, 1440), 1.0], [Vector2i(1920, 1080), 0.0]]:
		if case[1] > 0.0:
			root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
			root.content_scale_size = UiStyle.LAYOUT_MIN
			root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
			root.content_scale_factor = case[1]
		else:
			root.content_scale_mode = scale_was[0]
			root.content_scale_size = scale_was[1]
			root.content_scale_aspect = scale_was[2]
			root.content_scale_factor = scale_was[3]
		root.size = case[0]
		strip._built_for = ""
		strip._clock = 0.0
		strip._process(0.0)
		for f in 3:
			await process_frame
		var fog := strip.get_global_rect().grow_individual(14, 8, 14, 4)
		var discs: Array = strip.items().map(func(it: Control) -> Rect2: return (it.find_child("Disc", true, false) as Control).get_global_rect())
		var clean := true
		var where := ""
		for i in strip.items().size():
			var disc_node := strip.items()[i].find_child("Disc", true, false) as Control
			for badge in disc_node.get_children():
				if not badge is Label:
					continue
				var r: Rect2 = (badge as Label).get_global_rect()
				var hits_other := false
				for j in discs.size():
					if j != i and r.intersects(discs[j].grow(-1.0)):
						hits_other = true
				if not fog.encloses(r) or hits_other:
					clean = false
					where = "%s on %s" % [badge.name, strip.items()[i].get_meta(&"kind").display_name]
		_check(clean, "at %s (UI share %s) every New tab and count is inside the strip and clear of the next disc (%s)" % [case[0], case[1], where])
		_check(strip.get_combined_minimum_size().y <= 140.0, "…and the strip stays low (%.0f px)" % strip.get_combined_minimum_size().y)
	root.content_scale_mode = scale_was[0]
	root.content_scale_size = scale_was[1]
	root.content_scale_aspect = scale_was[2]
	root.content_scale_factor = scale_was[3]
	root.size = scale_was[4]
	await process_frame

	# The DriftPanel line and the dashed line on the map.
	var panel = main.get_node("HUD/DriftPanel")
	panel._warning_key = ""
	panel._process(0.0)
	_check(panel.warning_label.visible and panel.warning_label.text.begins_with("Flyers in drift 31"),
		"the DriftPanel warns: %s" % panel.warning_label.text)
	var world: RuleBreakers = main.get_node_or_null("RuleBreakers")
	_check(world != null, "the HUD makes the RuleBreakers world node")
	if world != null:
		world._clock = 0.0
		world._process(0.0)
		_check(world.line_shown and world.line.visible and is_equal_approx(world.line.default_color.a, RuleBreakers.LINE_ALPHA)
			and world.line.texture != null and world.line.width < 24.0 and world.line.points.size() == 2,
			"a thin mist line shows the Phantom's straight path for the rest, in a 4th run too (width %.0f)" % world.line.width)

	# The first Phantom on the field gets a name plate, once.
	var spawner = main.get_node("%EnemyContainer")
	if world != null:
		var first: Node2D = spawner.spawn_enemy(phantom)
		await process_frame
		await process_frame
		_check(world._plates.size() == 1 and world._plates[0][0] == first, "the first Phantom gets its name plate")
		spawner.spawn_enemy(phantom)
		await process_frame
		await process_frame
		_check(world._plates.size() == 1, "…only the first one this run")

	# Faced this run: the next blocks don't warn again.
	director.drifts_started = 35
	director.resting = true
	_check(not RuleBreakers.coming(director).any(func(item: Array) -> bool: return item[0] == phantom), "once faced, no warning in later blocks")
	panel._warning_key = ""
	panel._process(0.0)
	_check(not panel.warning_label.text.contains("Flyers in drift 31"), "…and the DriftPanel line is gone")
	if world != null:
		for enemy in main.get_node("%EnemyContainer").get_children():
			enemy.queue_free()  # The plate test's Phantoms: none on the field now
		await process_frame
		world._clock = 0.0
		world._process(0.0)
		_check(world.line_shown == RuleBreakers.wall_flyers_coming(director),
			"…but the mist line follows the schedule (Phantoms next block: %s)" % RuleBreakers.wall_flyers_coming(director))
	# During a drift: no warning line; the mist line faint while Phantoms fly.
	director.resting = false
	panel._warning_key = ""
	panel._process(0.0)
	_check(not panel.warning_label.visible, "no warning while a drift walks")
	if world != null:
		world._clock = 0.0
		world._process(0.0)
		_check(not world.line_shown, "a drift with no flyers on the field: no line")
		main.get_node("%EnemyContainer").spawn_enemy(phantom)
		await process_frame
		world._clock = 0.0
		world._process(0.0)
		_check(world.line_shown and is_equal_approx(world.line.default_color.a, RuleBreakers.LINE_ALPHA_FIELD),
			"a Phantom on the field: the line, faint")

	memory = HeartwoodMemory.load_data()
	memory.erase("rule_breakers_warned")
	HeartwoodMemory.save_data(memory)
	print("rule breakers test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if condition:
		print("ok  " + label)
	else:
		failures += 1
		printerr("FAIL: " + label)
