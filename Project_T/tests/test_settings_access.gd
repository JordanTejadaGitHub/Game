extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	run.call_deferred()
func interactive(node: Node) -> void:
	if node is BaseButton or node is Slider:
		check(node.focus_mode == Control.FOCUS_ALL, "settings control accepts keyboard focus: " + str(node.get_path()))
	for child in node.get_children():
		interactive(child)
func run() -> void:
	HeartwoodMemory.file_path = "user://settings_access_%d.json" % OS.get_process_id()
	HeartwoodMemory.forget()
	HeartwoodMemory.save_data(HeartwoodMemory.defaults())
	var panel := SettingsPanel.new()
	root.add_child(panel)
	await process_frame
	interactive(panel)
	panel._set_value("whispers", false)
	check(not panel._growth_marks.disabled, "Growth marks remains adjustable with Hints off")
	panel._growth_marks.set_pressed(false)
	panel._growth_marks.set_pressed(true)
	check(bool(panel._settings.get(GrowHints.SETTING, false)), "independent Growth marks can be enabled")
	for code in range(KEY_1, KEY_9 + 1):
		panel._set_value("keybinds", {"pause_game": [code]})
		var lines := panel.get_conflict_lines()
		check(lines.any(func(line: String) -> bool: return line.contains("Warden") and line.contains("Pause")), "numeric Warden shortcut conflict: " + OS.get_keycode_string(code))
	panel._discard()
	check(panel.get_conflict_lines().is_empty(), "discard clears numeric conflict")
	panel.queue_free()
	await process_frame
	HeartwoodMemory.preview_settings = {}
	InputMap.load_from_project_settings()
	DirAccess.remove_absolute(HeartwoodMemory.file_path)
	print("settings access: %d failures" % failures)
	quit(1 if failures > 0 else 0)
