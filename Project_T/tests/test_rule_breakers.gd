extends SceneTree

# New rule-breaker warning (screens_ui.md "In the world"; human run 5: lost at drift 35 to Phantoms, the first
# flyers, at drift 31): at the rest before the block that brings them, the Coming strip leads with the Phantom
# (larger, "New", its trait in words), the DriftPanel warns "Flyers in drift 31: they ignore your maze", the map
# shows a dashed line from the start straight to the Heartwood; the first Phantom on the field gets a name plate.
# Once faced this run, none of it again. Tests never write the profile.

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
	var profile_before: Dictionary = HeartwoodMemory.load_data().get(RuleBreakers.PROFILE_KEY, {}).duplicate()

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
	var face: Button = lead.get_child(0) if lead != null else null
	_check(face != null and face.custom_minimum_size.x == ComingStrip.FACE_BIG and items.size() > 1
		and (items[1].get_child(0) as Button).custom_minimum_size.x == ComingStrip.FACE, "…larger than the others")

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
		_check(world.line_shown, "a dashed line shows the Phantom's straight path for the rest")

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
		world._clock = 0.0
		world._process(0.0)
		_check(not world.line_shown, "…and so is the dashed line")
	# During a drift: no warning line.
	director.resting = false
	panel._warning_key = ""
	panel._process(0.0)
	_check(not panel.warning_label.visible, "no warning while a drift walks")

	_check(HeartwoodMemory.load_data().get(RuleBreakers.PROFILE_KEY, {}) == profile_before, "tests never write the profile")
	print("rule breakers test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if condition:
		print("ok  " + label)
	else:
		failures += 1
		printerr("FAIL: " + label)
