extends SceneTree

# Settings → Developer → "Start over as a new profile" (demo_scope.md "Reset to a new profile"): the profile
# becomes a first launch (backed up first), settings stay, the saved run goes, run history stays; "Restore
# last backup" puts it back. Temp files only (every checkout shares user://).

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var dir := "user://test_profile_reset_%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(dir)
	var old_profile := HeartwoodMemory.file_path
	var old_run := RunSaver.file_path
	var old_history := RunHistory.file_path
	HeartwoodMemory.file_path = dir.path_join("heartwood.json")
	RunSaver.file_path = dir.path_join("run.json")
	RunHistory.file_path = dir.path_join("run_history.json")
	HeartwoodMemory.forget()

	# A played profile: Seeds, a Grove node, discoveries, a changed setting; a saved run and run history.
	var data := HeartwoodMemory.load_data()
	data.seeds = 321
	data.runs_played = 7
	data.unlocks = {"slot_4": 1}
	data.combos_seen = ["conducted"]
	data.whispers_seen = ["first_run"]
	data.settings.music_volume = 0.2
	HeartwoodMemory.save_data(data)
	_write(RunSaver.file_path, "{\"drift\": 12}")
	_write(RunHistory.file_path, "[{\"result\": \"lost\"}]")

	SettingsPanel.start_over()
	var fresh := HeartwoodMemory.load_data()
	_check(fresh.seeds == 0 and fresh.runs_played == 0 and fresh.unlocks.is_empty(), "the Grove, Seeds and counts reset")
	_check(not fresh.has("combos_seen") or fresh.combos_seen.is_empty(), "discoveries reset")
	_check(fresh.whispers_seen.is_empty(), "whispers show again (a first launch)")
	_check(is_equal_approx(float(fresh.settings.music_volume), 0.2), "settings stay")
	_check(not FileAccess.file_exists(RunSaver.file_path), "the saved run is deleted")
	_check(FileAccess.file_exists(RunHistory.file_path), "run history stays")
	var backup := HeartwoodMemory.latest_backup()
	_check(backup != "" and backup.get_base_dir() == dir, "a backup sits beside the (temp) profile")

	_check(SettingsPanel.restore_last(), "restore finds the backup")
	var back := HeartwoodMemory.load_data()
	_check(back.seeds == 321 and back.runs_played == 7 and back.unlocks.has("slot_4"), "restoring brings the old profile back")

	# The panel: two steps (Start over → warning + Reset / Cancel), Cancel goes back; Restore is offered.
	var panel := SettingsPanel.new()
	root.add_child(panel)
	await process_frame
	var box := panel.find_child("ProfileReset", true, false)
	_check(box != null, "the Developer tab has the reset box (debug build)")
	if box != null:
		var start: Button = box.find_child("StartOver", true, false)
		var confirm: Control = box.find_child("Confirm", true, false)
		_check(not confirm.visible, "no warning until asked")
		start.pressed.emit()
		_check(confirm.visible and not start.visible, "Start over shows the warning with Reset / Cancel")
		var label: Label = confirm.get_child(0)
		_check(label.text == SettingsPanel.RESET_WARNING, "the warning names what goes and what stays")
		(box.find_child("Cancel", true, false) as Button).pressed.emit()
		_check(not confirm.visible and start.visible, "Cancel goes back")
		_check(not (box.find_child("Restore", true, false) as Button).disabled, "Restore last backup is offered")
	panel.queue_free()
	await process_frame

	for file in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(file))
	DirAccess.remove_absolute(dir)
	HeartwoodMemory.file_path = old_profile
	RunSaver.file_path = old_run
	RunHistory.file_path = old_history
	HeartwoodMemory.forget()
	print("profile reset test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func _check(condition: bool, label: String) -> void:
	if condition:
		print("ok  " + label)
	else:
		failures += 1
		printerr("FAIL: " + label)
