extends SceneTree

# Headless test for the dev perf overlay (debug builds): it's in the run, hidden until F3, and its lines carry
# FPS, frame time, draw calls, effects and nightmares.
#   godot --headless --path . --script res://tests/test_perf_overlay.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_perf_overlay_%d.json" % OS.get_process_id()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var overlays := main.find_children("*", "PerfOverlay", false, false)
	_check(OS.is_debug_build() == (overlays.size() == 1), "a debug build's run has the perf overlay (%d)" % overlays.size())
	if overlays.size() == 1:
		var overlay: PerfOverlay = overlays[0]
		_check(not overlay.visible, "hidden until F3")
		var press := InputEventKey.new()
		press.physical_keycode = KEY_F3
		press.pressed = true
		overlay._unhandled_input(press)
		_check(overlay.visible, "F3 shows it")
		var text := overlay.text()
		_check(text.contains("FPS") and text.contains("Draw calls") and text.contains("Effects") and text.contains("nightmares"),
			"it reports FPS, draw calls, effects and nightmares (%s)" % text.replace("\n", " | "))
	print("perf overlay test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
