extends SceneTree

# Headless test: every Warden with an attack sheet (`TowerData.attack_texture`) plays it when it acts. Each one is
# planted alone beside a sturdy nightmare (at its minimum range for snipers) and run for a few seconds; its sprite must
# show the attack sheet at least once. Catches attack kinds or specials whose path skips _start_attack (the old BEAM
# bug; the user's "Hushbell has no attack animation"). Beams channel on their sustain loop by design (they must beam
# and never flash the sheet); Graftlings get a neighbour to copy; patrols play the sheet as a cast pose. Run from the
# project folder:
#   godot --headless --path . --script res://tests/test_attack_sheets.gd --fixed-fps 60

const STEP := 1.0 / 60.0
const SECONDS := 6.0

var failures := 0
var main: Node
var spawner: Node
var placer: TowerPlacer
var container: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	paused = false
	spawner = main.get_node("%EnemyContainer")
	placer = main.get_node("%TowerPlacer")
	container = main.get_node("%TowerContainer")
	main.get_node("%DreamState").unlock_everything = true
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

	var checked := 0
	var dir := DirAccess.open("res://resource/tower")
	for file in dir.get_files():
		if not file.ends_with(".tres"):
			continue
		var data = load("res://resource/tower/" + file)
		if not (data is TowerData) or data.attack_texture == null:
			continue
		checked += 1
		if not await _plays_attack(data):
			failures += 1
			printerr("FAIL: %s (%s) never shows its attack sheet" % [data.display_name, data.get_id()])
	_check(checked >= 20, "checked %d Wardens with attack sheets" % checked)

	print("attack sheets test: %s (%d Wardens)" % ["PASS" if failures == 0 else "%d FAILED" % failures, checked])
	main.queue_free()
	await process_frame
	quit(failures)

func _plays_attack(data: TowerData) -> bool:
	var map = main.get_node("%MapGenerator")
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var at := route[mini(6, route.size() - 1)]
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = data
	tower.cell = at
	tower.position = Tower.MAP_GRID.calculate_map_position(at)
	container.add_child(tower)
	tower.set_process(false)
	var helpers: Array = []
	if data.attack_kind == TowerData.AttackKind.COPY:
		# A Graftling attacks with its neighbour's attack: give it one to copy.
		var buddy: Tower = placer.tower_scene.instantiate()
		buddy.tower_data = load("res://resource/tower/sporeling.tres")
		buddy.cell = at + Vector2(1, 0) if not route.has(at + Vector2(1, 0)) else at + Vector2(-1, 0)
		buddy.position = Tower.MAP_GRID.calculate_map_position(buddy.cell)
		container.add_child(buddy)
		buddy.set_process(false)
		helpers.append(buddy)
		await process_frame
		tower._refresh_neighbours()
	# One nightmare on the tile next to it, and one at its minimum range (snipers), both on the route.
	var targets: Array = []
	for offset in [1, maxi(1, ceili(data.min_range)) + 1]:
		var cell := route[mini(6 + offset, route.size() - 1)]
		var enemy: Node2D = spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
		enemy.set_process(false)
		enemy.global_position = Tower.MAP_GRID.calculate_map_position(cell)
		enemy.max_health = 1000000
		enemy.health = 1000000
		targets.append(enemy)
	await process_frame
	var seen := false
	var time := 0.0
	while time < SECONDS and not seen:
		tower._process(STEP)
		time += STEP
		if data.attack_kind == TowerData.AttackKind.BEAM:
			# By design a beam channels on its sustain loop (or idle), never the attack sheet (its baked ray fought
			# the real beam): it must beam, and must not flash the sheet.
			seen = tower._beam_target != null and tower.sprite.texture != data.attack_texture
		else:
			seen = tower.sprite.texture == data.attack_texture
		if int(time / STEP) % 30 == 0:
			await process_frame  # Let effects and deferred calls run now and then
	tower.queue_free()
	for helper in helpers:
		helper.queue_free()
	for enemy in targets:
		if is_instance_valid(enemy):
			enemy.queue_free()
	for node in main.get_children():
		if node is BranchKit.GroundZone or node is BranchKit.BroodSprite or node is BranchKit.LineFlash or node is BranchKit.ConeFlash:
			node.queue_free()
	await process_frame
	return seen

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
