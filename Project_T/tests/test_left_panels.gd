extends SceneTree

# One left panel at a time (screens_ui.md principle 5; user screenshot: "Dreams this run" drawn over the Warden panel):
# opening the Dreams list clears the Warden selection, and selecting a Warden closes the list. Temp profile.

var failures := 0

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok: ", what)
	else:
		failures += 1
		push_error("FAIL: " + what)

func _initialize() -> void:
	_run.call_deferred()

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_left_panels_%d.json" % OS.get_process_id()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 4242
	root.add_child(main)
	await _frames(3)
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var row = main.get_node("HUD/DreamsRow")
	var map = main.get_node("%MapGenerator")
	main.get_node("%RunState").dew = 1000
	placer.select_tower(load("res://resource/tower/sprout.tres"))
	var tower: Tower = null
	for y in range(2, 16):
		for x in range(2, 20):
			if tower == null and map.is_buildable(Vector2(x, y)) and placer._try_build(Vector2(x, y)):
				tower = placer.tower_container.get_child(placer.tower_container.get_child_count() - 1)
	placer.set_build_mode(false)
	seller.select(tower)
	await _frames(2)
	_check(tower != null and seller.selected == tower, "a Warden is selected (its panel open)")
	row._toggle_list()
	await _frames(2)
	_check(row._list.visible and seller.selected == null, "opening Dreams this run clears the Warden selection")
	seller.select(tower)
	await _frames(2)
	_check(not row._list.visible and seller.selected == tower, "selecting a Warden closes the Dreams list")
	main.queue_free()
	await _frames(1)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("left panels test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)
