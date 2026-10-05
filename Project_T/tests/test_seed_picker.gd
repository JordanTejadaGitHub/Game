extends SceneTree

# Headless test for Remembered Seed's run-start choice (meta_design.md 952b986e): SeedPicker.ask starts at once without
# the Grove node; past_maps lists the run history's maps newest first, one per seed, never the demo's; a chosen seed
# reaches the next run through RunSaver.next_map_seed (the map is built from it, then it's cleared). Never touches the
# player's saves (temp profile and run history).
#   godot --headless --path . --script res://tests/test_seed_picker.gd --fixed-fps 60

var failures := 0
var PROFILE_PATH := "user://test_seed_picker_%d.json" % OS.get_process_id()
var HISTORY_PATH := "user://test_seed_picker_runs_%d.json" % OS.get_process_id()

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = PROFILE_PATH
	RunHistory.file_path = HISTORY_PATH
	ResultsScreen.demo_override = 0
	HeartwoodMemory.save_data(HeartwoodMemory.defaults())

	# Without the node (or in the demo): straight to the run, no seed.
	var started := []
	SeedPicker.ask(root, func() -> void: started.append(RunSaver.next_map_seed))
	_check(not SeedPicker.available() and started == [0], "without Remembered Seed the run starts at once on a random map")
	ResultsScreen.demo_override = 1
	_check(not SeedPicker.available(), "never in the demo")
	ResultsScreen.demo_override = 0

	# Past maps: newest first, one per seed, no demo runs, no seed 0.
	var runs := [{"seed": 111, "date": "2026-10-05T10:00:00", "result": "lost", "survived": 12},
		{"seed": 222, "date": "2026-10-04T10:00:00", "result": "won", "survived": 100, "demo": true},
		{"seed": 111, "date": "2026-10-03T10:00:00", "result": "lost", "survived": 7},
		{"seed": 0, "date": "2026-10-02T10:00:00", "result": "lost", "survived": 3},
		{"seed": 333, "date": "2026-10-01T10:00:00", "result": "abandoned", "survived": 20}]
	var file := FileAccess.open(HISTORY_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(runs))
	file.close()
	var maps := SeedPicker.past_maps()
	_check(maps.map(func(m: Dictionary) -> int: return int(m.seed)) == [111, 333] and int(maps[0].survived) == 12,
		"past maps: newest first, one per seed, no demo runs (%s)" % [maps])

	# The picker itself (as if the node were planted): a past map's row starts the run on its seed; a typed seed too.
	var picker := SeedPicker.new()
	picker._start = func() -> void: started.append(RunSaver.next_map_seed)
	root.add_child(picker)
	await process_frame
	var row := picker.find_child("Map_333", true, false) as Button
	_check(row != null and picker.find_child("NewMap", true, false) != null, "the picker lists a new map and the past maps")
	if row != null:
		row.pressed.emit()
	_check(started.back() == 333, "a past map's row starts the run on its seed (%s)" % [started])
	var typed := SeedPicker.new()
	typed._start = func() -> void: started.append(RunSaver.next_map_seed)
	root.add_child(typed)
	await process_frame
	typed._typed.text = "abc"
	_check(typed.typed_seed() == 0, "a typed seed must be a number")
	typed._typed.text = " 4242 "
	(typed.find_child("TypedGo", true, false) as Button).pressed.emit()
	_check(started.back() == 4242, "a typed seed starts the run on it (%s)" % [started])

	# The run is built on the chosen seed, once.
	RunSaver.next_map_seed = 4242
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	_check(int(main.get_node("%MapGenerator").map_seed) == 4242 and RunSaver.next_map_seed == 0,
		"the next run's map is built from the chosen seed, and the choice is used once")
	main.queue_free()
	await process_frame

	ResultsScreen.demo_override = -1
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HISTORY_PATH))
	print("seed picker test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
