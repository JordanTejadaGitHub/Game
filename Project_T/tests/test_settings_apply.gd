extends SceneTree

# Settings "Apply and Cancel" (screens_ui.md "Settings", 2026-10-01): changes preview live but save only on Apply;
# Cancel restores, Defaults resets the tab, closing with changes asks, risky display changes revert unless kept,
# keybind conflicts show before Apply. Temp profile.

var failures := 0

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok: ", what)
	else:
		failures += 1
		push_error("FAIL: " + what)

func _initialize() -> void:
	_run.call_deferred()

func _saved() -> Dictionary:
	HeartwoodMemory.preview_settings = {}
	var settings := HeartwoodMemory.get_settings()
	return settings

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_settings_apply_%d.json" % OS.get_process_id()
	HeartwoodMemory.forget()
	HeartwoodMemory.save_data(HeartwoodMemory.defaults())
	var panel := SettingsPanel.new()
	root.add_child(panel)
	await process_frame
	_check(not panel.has_changes() and panel.apply_button.disabled and panel.cancel_button.disabled,
		"opens with nothing changed: Apply and Cancel greyed")

	# A change previews (readers see it) but isn't saved.
	panel._set_value("reduce_flashes", true)
	_check(bool(HeartwoodMemory.get_settings().reduce_flashes), "the change previews live (get_settings sees it)")
	_check(not bool(_saved().reduce_flashes), "…but isn't saved")
	panel._preview()
	_check(panel.is_changed("reduce_flashes") and panel._dots["reduce_flashes"].modulate.a > 0.5, "a gold dot marks it")
	var access := panel.tabs.get_node("Accessibility")
	_check(panel.tabs.get_tab_title(access.get_index()).ends_with("•"), "and its tab")
	_check(not panel.apply_button.disabled, "Apply is live")

	# Cancel restores.
	panel.cancel()
	_check(not panel.has_changes() and not bool(HeartwoodMemory.get_settings().reduce_flashes), "Cancel puts the saved value back")
	_check(HeartwoodMemory.preview_settings.is_empty(), "…and ends the preview")

	# Apply saves.
	panel._set_value("music_volume", 0.2)
	panel.apply()
	_check(is_equal_approx(float(_saved().music_volume), 0.2) and not panel.has_changes(), "Apply saves")
	_check(not panel.keep_prompt.visible, "a volume change doesn't ask to be kept")

	# Defaults: the current tab only, still needs Apply.
	panel.tabs.current_tab = panel.tabs.get_node("Audio").get_index()
	panel._set_value("reduce_flashes", true)
	panel.reset_tab()
	_check(is_equal_approx(float(panel._settings.music_volume), 0.55), "Defaults resets the tab's settings")
	_check(bool(panel._settings.reduce_flashes), "…not other tabs'")
	_check(is_equal_approx(float(_saved().music_volume), 0.2), "…and needs Apply")
	panel.cancel()

	# Closing with changes asks: Keep editing, Discard, Apply.
	var closes := [0]
	panel.closed.connect(func() -> void: closes[0] += 1)
	panel.request_close()
	_check(closes[0] == 1, "nothing changed: Back closes at once")
	panel._set_value("hitstop", false)
	panel.request_close()
	_check(panel.close_prompt.visible and closes[0] == 1, "unapplied changes: Back asks first")
	panel._hide_prompts()
	_check(panel.has_changes() and closes[0] == 1, "Keep editing keeps the change and the panel")
	panel.request_close()
	panel._close_discard()
	_check(closes[0] == 2 and not panel.has_changes() and bool(_saved().hitstop), "Discard drops it and closes")
	panel._set_value("hitstop", false)
	panel.request_close()
	panel._close_apply()
	_check(closes[0] == 3 and not bool(_saved().hitstop), "Apply in the question saves and closes")

	# Risky display changes: "Keep these settings?", no answer reverts (the rest of that Apply stays).
	panel.revert_seconds = 0.3
	panel._set_value("ui_scale", 0.75)
	panel._set_value("whispers", false)
	panel.apply()
	_check(panel.keep_prompt.visible and is_equal_approx(float(_saved().ui_scale), 0.75), "a UI scale change asks to be kept")
	var start := Time.get_ticks_msec()
	while panel.keep_prompt.visible and Time.get_ticks_msec() - start < 3000:
		await process_frame
	_check(not panel.keep_prompt.visible and is_equal_approx(float(_saved().ui_scale), 1.0), "no answer reverts it")
	_check(not bool(_saved().whispers), "…and keeps the rest of the Apply")
	panel._set_value(SettingsPanel.VSYNC_SETTING, false)
	panel.apply()
	panel.keep()
	await create_timer(0.5).timeout
	_check(not bool(_saved().vsync) and not panel.keep_prompt.visible, "Keep keeps it")

	# Keybind conflicts show before Apply.
	var build_key := KEY_B
	for event in InputMap.action_get_events("toggle_build_mode"):
		if event is InputEventKey:
			build_key = SettingsPanel._keycode(event)
	panel._set_value("keybinds", {"pause_game": [build_key]})
	_check(not panel.get_conflict_lines().is_empty() and panel.conflict_label.visible,
		"a rebind onto Build mode's key shows the conflict (%s)" % [panel.get_conflict_lines()])
	_check(panel._key_dots["pause_game"].modulate.a > 0.5, "the rebound key has its dot")
	panel.cancel()
	_check(panel.get_conflict_lines().is_empty() and not panel.conflict_label.visible, "Cancel clears it")

	# Hidden mid-change (the pause menu closing): the change is dropped.
	panel._set_value("reduced_motion", true)
	panel.visible = false
	_check(not bool(HeartwoodMemory.get_settings().reduced_motion) and HeartwoodMemory.preview_settings.is_empty(),
		"hiding the panel drops unapplied changes")

	panel.queue_free()
	await process_frame
	HeartwoodMemory.preview_settings = {}
	InputMap.load_from_project_settings()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("PASS" if failures == 0 else "FAILURES: %d" % failures)
	quit(failures)
