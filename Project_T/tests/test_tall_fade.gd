extends SceneTree

# Headless test for tall Wardens' fade (story chat 2026-10-01): a 64x96 Warden's top band (it overhangs the cell
# above) fades to ~50% while a nightmare stands in that cell, and comes back once it leaves. A 64x64 Warden has
# no fade material.
#   godot --headless --path . --script res://tests/test_tall_fade.gd --fixed-fps 60

var failures := 0
var ids_done := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	var spawner = main.get_node("%EnemyContainer")
	for child in spawner.get_children():
		child.queue_free()
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var container: Node = main.get_node("%TowerContainer")
	var tall: Tower = _plant(placer, container, "beacon", Vector2(6, 8))  # Bases are 64 again (2026-10-04); branches big
	var small: Tower = _plant(placer, container, "sprout", Vector2(9, 8))
	await process_frame
	_check(tall.is_tall() and tall.sprite.material != null, "a 64x96 Warden gets the fade material")
	_check(not small.is_tall() and small.sprite.material == null, "a 64x64 Warden doesn't")
	var nightmare: Node2D = spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	nightmare.set_process(false)
	nightmare.global_position = Tower.MAP_GRID.calculate_map_position(tall.cell + Vector2.UP)
	for i in 30:
		tall._update_tall_fade(1.0 / 60.0)
		await process_frame
	_check(tall._tall_alpha < 0.6, "a nightmare behind fades the top band (%.2f)" % tall._tall_alpha)
	nightmare.global_position = Tower.MAP_GRID.calculate_map_position(tall.cell + Vector2(4, 0))
	for i in 40:
		tall._update_tall_fade(1.0 / 60.0)
		await process_frame
	_check(tall._tall_alpha > 0.95, "it comes back once the cell is clear (%.2f)" % tall._tall_alpha)
	# A Warden in the cell above alone never fades it (story chat 2026-10-04: maze columns drawn see-through).
	var above := _plant(placer, container, "sprout", tall.cell + Vector2.UP)
	await process_frame
	for i in 30:
		tall._update_tall_fade(1.0 / 60.0)
		await process_frame
	_check(tall._tall_alpha > 0.95, "a Warden in the cell above doesn't fade it (%.2f)" % tall._tall_alpha)
	above.queue_free()
	# Every tall form is drawn whole in every state (user: "some of the Wardens' top parts being cut off"): the
	# map sprite idle / attacking / channelling and the UI icon are 96 px tall; only multi-cell art (the Sapling)
	# gets the cropped icon.
	for id in ["beacon", "thunderhead", "wellspring", "elf_circle", "starcave", "snugroot", "grafted_elder", "midsummer", "monsoon"]:
		var data: TowerData = load("res://resource/tower/%s.tres" % id)
		var warden := _plant(placer, container, id, Vector2(3 + (ids_done % 8) * 2, 12 + (ids_done / 8) * 3))
		ids_done += 1
		await process_frame
		var heights := [warden.sprite.get_rect().size.y]
		if data.attack_texture != null:
			warden.sprite.texture = data.attack_texture
			warden.sprite.hframes = data.attack_frame_count
			heights.append(warden.sprite.get_rect().size.y)
		if data.beam_sustain_texture != null:
			warden.sprite.texture = data.beam_sustain_texture
			warden.sprite.hframes = data.beam_sustain_frames
			heights.append(warden.sprite.get_rect().size.y)
		heights.append(WardenIcon.region(data).size.y)
		# Bigger art (art_direction.md bcabe980): any height over 80, the same in every state.
		var tall_h: float = data.get_frame_rect(0).size.y
		_check(tall_h > 80.0 and heights.all(func(h: float) -> bool: return is_equal_approx(h, tall_h)) and warden.sprite.offset == data.get_sprite_offset(),
			"%s is drawn whole (%d px) idle / attacking / channelling / as an icon (%s)" % [id, tall_h, heights])
		warden.queue_free()
	var sapling: TowerData = load("res://resource/tower/heartwood_sapling.tres")
	_check(WardenIcon.region(sapling).size == Vector2(64, 64), "the Sapling's big art keeps its cropped 64x64 icon (%s)" % WardenIcon.region(sapling).size)

	print("tall fade test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _plant(placer: TowerPlacer, container: Node, id: String, at: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = at
	tower.position = Tower.MAP_GRID.calculate_map_position(at)
	container.add_child(tower)
	tower.set_process(false)
	return tower

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
