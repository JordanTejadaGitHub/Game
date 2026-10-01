extends SceneTree

# Settings → Display → "Effects quality: Full / Reduced" (the story chat, 2026-10-01: performance shouldn't need the
# accessibility toggles). Reduced thins the damage numbers and the combat callouts (Main's), and Fx lite mode, the
# Kinship pulses and off-screen idle animation (Tower Code's) read the same setting. On a temp profile: never the
# player's own settings.

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var real_path := HeartwoodMemory.file_path
	HeartwoodMemory.file_path = "user://test_effects_quality_%d.json" % OS.get_process_id()
	HeartwoodMemory.forget()
	_apply(0)
	_check(not SettingsPanel.effects_reduced(), "the default is Full")

	# The Settings panel offers it under Display.
	var panel := SettingsPanel.new()
	root.add_child(panel)
	await process_frame
	var display := panel.tabs.get_node_or_null("Display")
	var found := false
	if display != null:
		for label in display.find_children("*", "Label", true, false):
			if (label as Label).text == "Effects quality":
				found = true
	_check(found, "Settings → Display has Effects quality")
	panel.queue_free()

	_apply(1)
	_check(SettingsPanel.effects_reduced(), "Reduced reads back through Fx.setting")

	# Callouts: one at a time when Reduced (three when Full).
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var callouts = main.find_child("CombatCallouts", true, false)
	_check(callouts != null, "the run has its combat callouts")
	if callouts != null:
		var spawner = main.get_node("%EnemyContainer")
		var shade: EnemyData = load("res://resource/enemy/leaf_bug.tres")
		for tag in [&"conducted", &"asleep", &"crit"]:
			var enemy: Node2D = spawner.spawn_enemy(shade)
			var event := DamageLog.Event.new()
			event.enemy = enemy
			event.combos.append(tag)
			callouts._on_damage(event)
		_check(callouts._alive.size() == callouts.REDUCED_MAX_ALIVE,
			"Reduced: one callout at a time (%d alive)" % callouts._alive.size())

	var temp := HeartwoodMemory.file_path
	HeartwoodMemory.file_path = real_path
	HeartwoodMemory.forget()
	for suffix in ["", ".bak", ".tmp"]:  # The temp profile and its atomic-save companions
		if FileAccess.file_exists(temp + suffix):
			DirAccess.remove_absolute(temp + suffix)
	Fx._settings_at = -Fx.SETTINGS_REFRESH_MS
	print("effects quality test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

# Writes the setting to the temp profile and drops Fx's cached copy.
func _apply(value: int) -> void:
	var data := HeartwoodMemory.load_data()
	data.settings[SettingsPanel.EFFECTS_SETTING] = value
	HeartwoodMemory.save_data(data)
	HeartwoodMemory.forget()
	Fx._settings_at = -Fx.SETTINGS_REFRESH_MS

func _check(condition: bool, label: String) -> void:
	if condition:
		print("ok  " + label)
	else:
		failures += 1
		printerr("FAIL: " + label)
