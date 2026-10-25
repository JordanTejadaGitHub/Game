extends SceneTree

# Headless test for the perf readout: it's in every run, hidden until the Display setting "Performance readout" is on
# (or F3 in debug builds), and its lines carry FPS, frame time, script time, draw calls, effects, nightmares and the device.
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
	_check(overlays.size() == 1, "every run has the perf readout (%d)" % overlays.size())
	if overlays.size() == 1:
		var overlay: PerfOverlay = overlays[0]
		_check(not overlay.visible, "hidden while the setting is off")
		if OS.is_debug_build():
			var press := InputEventKey.new()
			press.physical_keycode = KEY_F3
			press.pressed = true
			overlay._unhandled_input(press)
			_check(overlay.visible, "F3 shows it (debug builds)")
			overlay._unhandled_input(press)
			_check(not overlay.visible, "and F3 again hides it")
		var settings := HeartwoodMemory.get_settings()
		settings[PerfOverlay.SETTING] = true
		HeartwoodMemory.save_settings(settings)
		Fx.reset_run()  # (Fx.setting's cache, as the settings panel does after saving)
		for f in 30:
			await process_frame
		_check(overlay.visible, "the Display setting shows it (phones: no F3)")
		var text := overlay.text()
		_check(text.contains("FPS") and text.contains("Scripts") and text.contains("draw calls") and text.contains("Effects")
			and text.contains("nightmares"), "it reports FPS, script time, draw calls, effects and nightmares (%s)" % text.replace("\n", " | "))
		_check(PerfOverlay.device_line() != "", "and the device (%s)" % PerfOverlay.device_line())
		settings[PerfOverlay.SETTING] = false
		HeartwoodMemory.save_settings(settings)
		Fx.reset_run()
		for f in 30:
			await process_frame
		_check(not overlay.visible, "turning the setting off hides it")
	print("perf overlay test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
