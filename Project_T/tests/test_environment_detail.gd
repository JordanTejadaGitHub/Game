extends SceneTree
# The environment's detail tiers (EnvironmentTiles.low_detail, mobile_plan.md performance pass): Full redraws the
# fog, mist and cloud shadows every frame; Low draws them once and holds them still, keeps the particles moving,
# halves the edge fog, holds the void's stars still and shrinks the Warden glows. Auto = Low only on phones.
# Run:  Godot --headless --path . --script res://tests/test_environment_detail.gd --fixed-fps 60

var failures := 0

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_environment_detail_%d.json" % OS.get_process_id()
	EnvironmentTiles.force_detail = -1
	_check(EnvironmentTiles.low_detail() == OS.has_feature("mobile"), "Auto: Low only on phones and tablets")
	for tier: int in [0, 1]:
		EnvironmentTiles.force_detail = tier
		var low: bool = tier == 1
		var main: Node = load("res://scenes/main.tscn").instantiate()
		main.get_node("MapGenerator").map_seed = 1207
		root.add_child(main)
		for f in 5:
			await process_frame
		var map = main.get_node("%MapGenerator")
		var amb: EnvironmentAmbience = map.ambience
		var counts := {amb: 0, amb._fog: 0, amb._mist_layer: 0, amb._shadows: 0}
		for canvas: CanvasItem in counts:
			canvas.draw.connect(func() -> void: counts[canvas] += 1)
		for f in 30:
			await process_frame
		var name := "Low" if low else "Full"
		_check(amb._low == low, "%s: the ambience reads the tier" % name)
		_check(counts[amb] >= 25, "%s: the particles move every frame (%d of 30)" % [name, counts[amb]])
		var still: int = counts[amb._fog] + counts[amb._mist_layer] + counts[amb._shadows]
		if low:
			_check(still == 0, "Low: the fog, mist and cloud shadows hold still (%d redraws)" % still)
		else:
			_check(counts[amb._fog] >= 25 and counts[amb._mist_layer] >= 25, "Full: the fog and mist drift every frame")
		var stars: Parallax2D = map.dream_void.get_child(1)
		_check((stars.autoscroll == Vector2.ZERO) == low, "%s: the void's stars %s" % [name, "hold still" if low else "drift"])
		main.free()
		await process_frame
	EnvironmentTiles.force_detail = -2
	print("environment detail test: %d failure(s)" % failures)
	quit(failures)
