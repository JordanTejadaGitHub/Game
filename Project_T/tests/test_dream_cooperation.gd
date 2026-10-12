extends SceneTree

var failures := 0
var helper
var main: Node
var dreams

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if not ResourceLoader.exists("res://scripts/run/dream_cooperation.gd"):
		_check(false, "cooperation helper implements the successor effects")
		quit(failures)
		return
	helper = load("res://scripts/run/dream_cooperation.gd")
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	dreams = main.get_node("%DreamState")
	dreams.stacks = {"crosswind": 1, "opening_fracture": 1, "shared_mycelium": 1, "crossed_sparks": 1, "afterroot": 1}
	dreams.bump_board()
	var a := _tower("samara")
	var b := _tower("sprout")
	var e = main.get_node("%EnemyContainer").spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	e.set_process(false)
	e.health = 100000
	e.max_health = 100000
	a.set_meta("unique_throw_serial", 1)
	_check(helper.before_hit(a, e, true, 0.0) == 1.0, "lone Samara gains no Crosswind")
	helper.after_hit(a, e, false, true, 0.0)
	_check(helper.before_hit(a, e, true, 0.1) == 1.0, "same Warden cannot qualify")
	helper.after_hit(b, e, false, true, 0.2)
	_check(helper.before_hit(a, e, true, 0.3) == 1.25, "another Warden enables Crosswind")
	_check(helper.before_hit(a, e, true, 0.4) == 1.0, "one bonus per enemy and throw")
	a.set_meta("unique_throw_serial", 2)
	_check(helper.before_hit(a, e, false, 0.5) == 1.0, "persistent damage cannot consume cooperation")
	_check(helper.before_hit(a, e, true, 0.6) == 1.25, "new throw can cooperate")
	a.set_meta("unique_throw_serial", 1)
	_check(helper.before_hit(a, e, true, 0.7) == 1.0, "older in-flight throw cannot repeat after a newer throw")
	helper.after_hit(b, e, true, true, 2.0)
	_check(helper.before_hit(b, e, true, 2.1) == 1.0, "primer source cannot consume itself")
	_check(helper.before_hit(a, e, true, 2.2) >= 1.4, "another Warden consumes Opening Fracture")
	helper.after_hit(a, e, true, true, 2.2)
	_check(helper.before_hit(b, e, true, 2.3) == 1.0, "payoff crit cannot re-prime")
	e.statuses.remove(EnemyStatuses.SPORED)
	_native(a, e, EnemyStatuses.SPORED, 10.0)
	_native(a, e, EnemyStatuses.SPORED, 10.1)
	_check(e.statuses.stacks(EnemyStatuses.SPORED) == 2, "same native source grants no bonus")
	_native(b, e, EnemyStatuses.SPORED, 10.2)
	_check(e.statuses.stacks(EnemyStatuses.SPORED) == 9, "two native sources add six Spored (card_review_2026-10-12.md 10; was two)")
	_native(a, e, EnemyStatuses.SPORED, 10.3)
	_check(e.statuses.stacks(EnemyStatuses.SPORED) == 10, "shared cooldown prevents immediate repeat")
	e.statuses.remove(EnemyStatuses.SPORED)
	_native(b, e, EnemyStatuses.SPORED, 14.0)
	_check(e.statuses.stacks(EnemyStatuses.SPORED) == 1, "removal clears cooperation history")
	e.statuses.remove(EnemyStatuses.SPORED)
	_native(a, e, EnemyStatuses.SPORED, 16.0)
	e.statuses.remove(EnemyStatuses.SPORED)
	e.apply_status(EnemyStatuses.SPORED, 1, 5.0, 1.0, 0, "", b)
	_native(b, e, EnemyStatuses.SPORED, 16.2)
	_check(e.statuses.stacks(EnemyStatuses.SPORED) == 2, "synthetic reapplication starts a new lifecycle")
	e.statuses.remove(EnemyStatuses.SPORED)
	_native(a, e, EnemyStatuses.SPORED, 18.0)
	e.apply_status(EnemyStatuses.SPORED, 30, 5.0, 1.0, 0, "", a)
	_native(b, e, EnemyStatuses.SPORED, 18.1)
	_check(e.statuses.stacks(EnemyStatuses.SPORED) == e.statuses.get_max_stacks(EnemyStatuses.SPORED), "bonus respects ordinary Spored cap")
	e.statuses.remove(EnemyStatuses.SPORED)
	e.statuses.duration_multipliers[EnemyStatuses.SPORED] = 0.5
	_native(a, e, EnemyStatuses.SPORED, 22.0)
	_native(b, e, EnemyStatuses.SPORED, 22.1)
	_check(is_equal_approx(e.statuses.time_left(EnemyStatuses.SPORED), 2.5), "bonus preserves effective native duration")
	e.statuses.remove(EnemyStatuses.SPORED)
	e.statuses.immune.append(EnemyStatuses.STATIC)
	_native(a, e, EnemyStatuses.STATIC, 20.0)
	_native(b, e, EnemyStatuses.STATIC, 20.1)
	_check(not e.statuses.has(EnemyStatuses.STATIC), "immune applications cannot cooperate")
	e.statuses.immune.erase(EnemyStatuses.STATIC)
	_native(a, e, EnemyStatuses.STATIC, 24.0)
	_native(b, e, EnemyStatuses.STATIC, 24.1)
	_check(e.statuses.stacks(EnemyStatuses.STATIC) == 8, "Crossed Sparks adds six ordinary charges")
	e.apply_status(EnemyStatuses.STATIC, 9, 5.0, 1.0, 0, "", a)  # 8 + 9 + 2 natives = 19; the six bonus charges fill it
	_native(b, e, EnemyStatuses.STATIC, 26.0)
	_native(a, e, EnemyStatuses.STATIC, 26.2)
	_check(not e.statuses.has(EnemyStatuses.STATIC), "bonus charges trigger the ordinary full-charge bolt")
	dreams.stacks["brimming"] = 1
	dreams.bump_board()
	await process_frame
	_check(e.statuses.get_max_stacks(EnemyStatuses.STATIC) == 40, "Brimming doubles native charge threshold")
	_native(a, e, EnemyStatuses.STATIC, 29.0)
	e.apply_status(EnemyStatuses.STATIC, 36, 5.0, 1.0, 0, "", a)
	_native(b, e, EnemyStatuses.STATIC, 29.1)
	_check(not e.statuses.has(EnemyStatuses.STATIC), "cooperation uses Brimming full-charge threshold")
	helper.hold_expired(dreams, e, a, 30.0)
	helper.before_hit(a, e, true, 30.1)
	_check(e.statuses.stacks(EnemyStatuses.MARKED) == 0, "Afterroot excludes original rooter")
	helper.before_hit(b, e, false, 30.2)
	_check(e.statuses.stacks(EnemyStatuses.MARKED) == 0, "Afterroot excludes persistent damage")
	helper.before_hit(b, e, true, 30.3)
	_check(e.statuses.stacks(EnemyStatuses.MARKED) == Reactions.buildup_threshold(5), "Afterroot grants half of what Exposed needs (5; 10 here, Brimming is on; card_review_2026-10-12.md 3)")
	helper.hold_expired(dreams, e, a, 31.0)
	helper.before_hit(b, e, true, 31.1)
	_check(e.statuses.stacks(EnemyStatuses.MARKED) == Reactions.buildup_threshold(5), "Afterroot shares four second cooldown")
	e.statuses.remove(EnemyStatuses.SPORED)
	e.apply_status(EnemyStatuses.SPORED, 1, 10.0, 1.0, 0, "", b)
	_native(a, e, EnemyStatuses.SPORED, 40.0, 0.25)
	e.statuses.tick(0.5)
	_native(b, e, EnemyStatuses.SPORED, 40.5)
	_check(e.statuses.stacks(EnemyStatuses.SPORED) == 2, "expired short native batch cannot cooperate through a long synthetic cohort")
	e.statuses.remove(EnemyStatuses.SPORED)
	_native(a, e, EnemyStatuses.SPORED, 50.0)
	e.apply_status(EnemyStatuses.SPORED, e.statuses.get_max_stacks(EnemyStatuses.SPORED), 5.0, 1.0, 0, "", b)
	var displaced_before: int = e.statuses.applications
	_native(b, e, EnemyStatuses.SPORED, 50.1)
	_check(e.statuses.applications == displaced_before + 1, "displaced native source cohort cannot cooperate")
	e.statuses.remove(EnemyStatuses.SPORED)
	e.apply_status(EnemyStatuses.SPORED, 1, 10.0, 1.0, 0, "", b)
	_native(a, e, EnemyStatuses.SPORED, 60.0, 0.25)
	e.statuses.tick(0.5)
	e.apply_status(EnemyStatuses.SPORED, 1, 5.0, 1.0, 0, "", a)
	_native(b, e, EnemyStatuses.SPORED, 60.5)
	_check(e.statuses.stacks(EnemyStatuses.SPORED) == 3, "same-applier synthetic cohort cannot resurrect expired native history")
	e.statuses.remove(EnemyStatuses.SPORED)
	e.statuses.caught_time = 5.0
	_native(a, e, EnemyStatuses.SPORED, 70.0, 0.25)
	e.statuses.tick(0.5)
	_native(b, e, EnemyStatuses.SPORED, 70.5)
	_check(e.statuses.stacks(EnemyStatuses.SPORED) == 8, "Caught preserves a short native cohort for cooperation")
	main.queue_free()
	main = null
	await process_frame
	await process_frame
	print("dream cooperation: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _tower(id: String) -> Tower:
	var t: Tower = main.get_node("%TowerPlacer").tower_scene.instantiate()
	t.tower_data = load("res://resource/tower/%s.tres" % id)
	main.get_node("%TowerContainer").add_child(t)
	t.set_process(false)
	return t

func _native(t, e, id: StringName, now: float, duration: float = 5.0) -> void:
	var present: bool = e.statuses.has(id)
	var before: int = e.statuses.applications
	e.apply_status(id, 1, duration, 1.0, 0, t.tower_data.line, t)
	t.set_meta("unique_native_status_context", [1.0, duration, 0])
	helper.native_status(t, e, id, e.statuses.applications > before, present, now)
	t.remove_meta("unique_native_status_context")

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", label)
