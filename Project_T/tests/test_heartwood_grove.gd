extends SceneTree

# The in-run Heartwood mirrors the Memory Grove (meta_design.md "Carried into the run"): canopy stage
# from grown_share, a glint per planted node, a dream-fruit per Memory darkening with leaves lost, and a
# fixed young tree in the demo. Profiles come from GrovePresets in memory: no file is touched.

var failures := 0

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok  ", what)
	else:
		failures += 1
		print("  FAIL ", what)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	print("test_heartwood_grove")
	# Stage pick: the Grove's thresholds on grown_share.
	for preset in GrovePresets.PRESETS:
		var data := GrovePresets.profile(preset)
		var tree := Heartwood.tree_from(data, false)
		var share := HeartwoodMemory.grown_share(data)
		_check(tree.stage == GroveTreeView.canopy_stage_for(share), "%s: stage %d from share %.2f" % [preset, tree.stage, share])
		_check(tree.planted.size() == HeartwoodMemory.planted_nodes(data).size(), "%s: %d planted nodes" % [preset, tree.planted.size()])
		_check(tree.memories == mini(HeartwoodMemory.memories_unlocked(data), Heartwood.MAX_FRUIT), "%s: %d Memories" % [preset, tree.memories])
	var full := Heartwood.tree_from(GrovePresets.profile(&"full"), false)
	_check(full.stage == 3, "the full Grove is stage 3")
	var demo := Heartwood.tree_from(GrovePresets.profile(&"full"), true)
	_check(demo.stage == 0 and demo.planted.is_empty() and demo.memories == 3, "the demo: stage 0, no glints, 3 fruit")

	# Built: one glint per planted node, one fruit per Memory, darkening with leaves lost.
	var heartwood := Heartwood.new()
	var planted: Array[Dictionary] = full.planted.slice(0, 12)
	heartwood.setup(3, planted, 7)
	root.add_child(heartwood)
	await process_frame
	_check(heartwood.texture != null and heartwood.texture.resource_path.ends_with("heartwood_stage_3.png"), "stage 3 sheet")
	_check(heartwood.get_glint_count() == 12, "12 planted nodes = 12 glints (%d)" % heartwood.get_glint_count())
	_check(heartwood.get_fruit_count() == 7, "7 Memories = 7 fruit (%d)" % heartwood.get_fruit_count())
	_check(heartwood.get_dark_fruit_count() == 0, "a whole tree: every fruit lit")
	heartwood._on_leaves_changed(8, 15)  # Leaves as RunState reports them
	var dark_half := heartwood.get_dark_fruit_count()
	_check(dark_half > 0 and dark_half < 7, "half the leaves lost: some fruit dark (%d)" % dark_half)
	heartwood._on_leaves_changed(1, 15)
	_check(heartwood.get_dark_fruit_count() >= dark_half, "more leaves lost: more dark (%d)" % heartwood.get_dark_fruit_count())
	# Every node of the full Grove gets a glint (the crown has a lit pixel for each).
	var all_planted: Array[Dictionary] = full.planted
	heartwood.setup(3, all_planted, 10)
	_check(heartwood.get_glint_count() == all_planted.size(), "full Grove: %d glints for %d nodes" % [heartwood.get_glint_count(), all_planted.size()])
	_check(heartwood.get_fruit_count() == 10, "10 Memories = 10 fruit")
	var none: Array[Dictionary] = []
	heartwood.setup(0, none, 3)
	_check(heartwood.texture.resource_path.ends_with("heartwood_stage_0.png") and heartwood.get_glint_count() == 0
		and heartwood.get_fruit_count() == 3, "demo tree: stage 0, no glints, 3 fruit")
	# The Golden Leaf keepsake: a palette swap on the crown; off means no material.
	heartwood.set_golden(true)
	_check(heartwood.material is ShaderMaterial, "golden leaf: the swap is on")
	heartwood.set_golden(false)
	_check(heartwood.material == null, "golden leaf off: the tree as drawn")
	var art: Image = load(EnvironmentTiles.sheet_path("heartwood_stage_3", 1)).get_image()
	art.decompress()
	var found := 0
	for green: Color in Heartwood.GOLDEN_FROM:
		var hit := false
		for y in range(0, 70, 2):
			for x in range(0, 128, 2):
				var c := art.get_pixel(x, y)
				if c.a > 0.5 and Vector3(c.r - green.r, c.g - green.g, c.b - green.b).length() < 0.02:
					hit = true
		if hit:
			found += 1
	_check(found >= 3, "golden leaf: %d of its colours are in the stage-3 crown" % found)
	heartwood.queue_free()
	await process_frame
	print("failures: ", failures)
	quit(failures)
