extends SceneTree

# Nurture labels (story chat; the user, comparing Rootling and Thorncoil: "why is Swift different for Thorncoil?"):
# Swift always reads as a percentage, never seconds saved ("acts 0.03 s sooner"), and Reach only names an area the
# form really has (every TowerData carries default cloud / chain numbers: Rootling read "+0.3 cloud").
#   godot --headless --path . --script res://tests/test_focus_labels.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_focus_labels_%d.json" % OS.get_process_id()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/rootling.tres")
	tower.cell = Vector2(3, 3)
	tower.position = Tower.MAP_GRID.calculate_map_position(tower.cell)
	placer.tower_container.add_child(tower)
	tower.set_process(false)
	await process_frame

	var seconds := RegEx.create_from_string("\\d\\.\\d\\d s")
	var count := 0
	for file in DirAccess.get_files_at("res://resource/tower"):
		if not file.ends_with(".tres"):
			continue
		var data := load("res://resource/tower/" + file) as TowerData
		if data == null or data.is_unique or not data.can_attack:
			continue
		tower.tower_data = data
		tower._apply_data()
		count += 1
		var id := data.get_id()
		for text: String in [tower.focus_short(Tower.Focus.SWIFT), tower.focus_text(Tower.Focus.SWIFT)]:
			_check(not text.contains("sooner") and seconds.search(text) == null, "%s: Swift reads as a percentage (\"%s\")" % [id, text])
		var kind := tower.attack_data.attack_kind
		for text: String in [tower.focus_short(Tower.Focus.REACH), tower.focus_text(Tower.Focus.REACH)]:
			var cloud := text.contains("cloud") and not text.contains("rain cloud")
			_check(not cloud or kind == TowerData.AttackKind.CLOUD, "%s: Reach says cloud only with a cloud (\"%s\")" % [id, text])
			_check(not text.contains("chain jumps") or kind == TowerData.AttackKind.CHAIN, "%s: chain jumps only on a chain (\"%s\")" % [id, text])
	_check(count >= 90, "every attacking form checked (%d)" % count)
	tower.tower_data = load("res://resource/tower/thorncoil.tres")
	tower._apply_data()
	var thorns := tower.focus_short(Tower.Focus.SWIFT)
	_check(thorns.begins_with("+") and thorns.ends_with("% faster thorns"), "Thorncoil: \"%s\"" % thorns)
	tower.tower_data = load("res://resource/tower/rootling.tres")
	tower._apply_data()
	_check(not tower.focus_text(Tower.Focus.REACH).contains("cloud"), "Rootling's Reach is its range (\"%s\")" % tower.focus_text(Tower.Focus.REACH))

	print("focus labels test: %s (%d forms)" % ["PASS" if failures == 0 else "%d FAILED" % failures, count])
	main.queue_free()
	await process_frame
	quit(failures)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + what)
