extends SceneTree
var failures := 0
var main: Node
var dreams: DreamState
var placer: TowerPlacer
var spawner: Node
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	dreams = main.get_node("%DreamState")
	placer = main.get_node("%TowerPlacer")
	spawner = main.get_node("%EnemyContainer")
	dreams.unlock_everything = true
	for e in spawner.get_children(): e.queue_free()
	await process_frame
	_take("shared_mycelium")
	var a := _plant("sporeling", Vector2(2, 2))
	var b := _plant("sporeling", Vector2(4, 2))
	var e = _enemy()
	a.hit(e, 1.0, false, Tower.NO_CRIT)
	b.hit(e, 1.0, false, Tower.NO_CRIT)
	_check(e.statuses.stacks(EnemyStatuses.SPORED) == 8, "real hits from two Wardens trigger Shared Mycelium (six extra)")
	var synthetic = _enemy()
	a.hit(synthetic, 1.0, false, Tower.NO_CRIT)
	b._apply_one_status(synthetic, EnemyStatuses.SPORED, 1, b.get_damage(), false)
	a.hit(synthetic, 1.0, false, Tower.NO_CRIT)
	_check(synthetic.statuses.stacks(EnemyStatuses.SPORED) == 3, "Dream-generated stacks cannot qualify as another native Warden")
	_take("crossed_sparks")
	var light_a := _plant("firefly_jar", Vector2(6, 2))
	var light_b := _plant("firefly_jar", Vector2(8, 2))
	var charged = _enemy()
	light_a.hit(charged, 1.0, false, Tower.NO_CRIT)
	light_b.hit(charged, 1.0, false, Tower.NO_CRIT)
	_check(charged.statuses.stacks(EnemyStatuses.STATIC) == 8, "real native Charged hits trigger Crossed Sparks (six extra)")
	_take("quiet_vigil")
	dreams.unique_growth.update_idle(a, 5.0)
	_check(a.get_meta(&"unique_vigil_ready", false), "idle readiness builds without Watchful Rest")
	var vigil = _enemy()
	a.hit(vigil, 1.0, true, Tower.NO_CRIT, &"cloud", false)
	_check(a.get_meta(&"unique_vigil_ready", false) and not vigil.statuses.has(EnemyStatuses.MARKED), "cloud cannot spend Quiet Vigil")
	a.hit(vigil, 1.0, false, Tower.NO_CRIT)
	_check(vigil.statuses.stacks(EnemyStatuses.MARKED) == 3 and not a.get_meta(&"unique_vigil_ready", false), "ordinary primary hit spends readiness on three Exposed stacks")
	_take("passing_thread")
	var donor = _enemy()
	var recipient = _enemy()
	donor.apply_status(EnemyStatuses.DAMP, 4, 2.0, 1.0)
	a.note_primary_target(donor)
	a.note_primary_target(recipient)
	_check(recipient.statuses.stacks(EnemyStatuses.DAMP) == 1, "primary target selection invokes Passing Thread")
	_take("corner_sign")
	var corner = _enemy()
	corner.set_meta(&"unique_bend_serial", 1)
	a.hit(corner, 1.0, false, Tower.NO_CRIT)
	_check(corner.statuses.stacks(EnemyStatuses.SPORED) == 2, "ordinary status hit invokes Corner Sign")
	_take("emergency_reserves")
	var dew: int = dreams.run_state.dew
	dreams.run_state.lose_leaves(1)
	dreams.run_state.lose_leaves(1)
	_check(dreams.run_state.dew == dew + 8, "actual RunState leaf loss pays Emergency Reserves once")
	_take("fresh_beginnings")
	var newest := _plant("sporeling", Vector2(10, 2))
	dreams._on_tower_built(newest)
	dreams.unique_growth.rest(dreams, [])
	_check(newest.banked_ranks == 1, "actual planting hook records Fresh Beginnings candidate")
	_take("afterroot")
	var rooted = _enemy()
	rooted.apply_status(EnemyStatuses.HELD, 1, 0.05, 0.0, 0, "root", a)
	rooted._process(0.2)
	b.hit(rooted, 1.0, false, Tower.NO_CRIT)
	_check(rooted.statuses.stacks(EnemyStatuses.MARKED) == 5, "natural Rooted expiry invokes Afterroot through Enemy processing")
	_take("dream_residue")
	var caught = _enemy()
	caught.statuses.caught_time = 0.05
	caught.set_meta(&"unique_catcher", weakref(a))
	caught._process(0.2)
	_check(caught.statuses.stacks(EnemyStatuses.DROWSY) == 2, "actual Catch exit invokes Dream Residue")
	_take("wake_ripple")
	for existing in spawner.get_children():
		if existing.has_method("apply_status"): existing.position = Vector2(10000, 10000)
	var drowned = _enemy()
	var splash = _enemy()
	splash.position += Vector2(10, 0)
	var under := Reactions.PullUnder.new(drowned, a, 3.0, false)
	main.add_child(under)
	under.set_process(false)
	under._age = under.seconds
	drowned.take_damage(999999.0, "spore", false, false, a, &"hit")
	_check(splash.statuses.stacks(EnemyStatuses.DAMP) == 2, "dispel signal invokes Wake Ripple on Drown's final tick")
	var save := dreams.to_save()
	_check(save.has("unique_growth") and int(save.unique_growth.emergency_block) >= 0, "Dream save preserves successor growth state")
	print("Unique Dream integration: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)
func _take(id: String) -> void:
	for card in dreams.pool:
		if card.id == id:
			dreams.take(card)
			return
	_check(false, "missing card " + id)
func _plant(id: String, cell: Vector2) -> Tower:
	var t: Tower = placer.tower_scene.instantiate()
	t.tower_data = load("res://resource/tower/%s.tres" % id)
	t.cell = cell
	t.position = Tower.MAP_GRID.calculate_map_position(cell)
	main.get_node("%TowerContainer").add_child(t)
	t.set_process(false)
	return t
func _enemy():
	var e = spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	e.set_process(false)
	e.position = Vector2(1600, 1200)
	e.max_health = 100000
	e.health = 100000
	return e
func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + label)