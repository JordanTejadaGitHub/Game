extends SceneTree

var failures := 0

func _initialize() -> void:
	var s := EnemyStatuses.new()
	s.apply(EnemyStatuses.SPORED, 8, 0.0, 2.0)
	_check(is_equal_approx(Tower.SPORE_POTENCY, 0.20), "Poisoned uses 20% of hit damage per stack")
	s.tick(1.0)
	s.apply(EnemyStatuses.SPORED, 8, 0.0, 2.0)
	_check(s.stacks(EnemyStatuses.SPORED) == 16, "a second tower can contribute beyond the old eight-stack cap")
	for i in 41:
		s.tick(0.1)
	_check(s.stacks(EnemyStatuses.SPORED) == 8, "older stacks expire without removing newer applications")
	for i in 11:
		s.tick(0.1)
	_check(not s.has(EnemyStatuses.SPORED), "new stacks expire instead of refreshing the entire pile")
	var staggered := EnemyStatuses.new()
	staggered.apply(EnemyStatuses.SPORED, 4)
	staggered.tick(1.0)
	staggered.apply(EnemyStatuses.SPORED, 4)
	for i in 41:
		staggered.tick(0.1)
	_check(staggered.stacks(EnemyStatuses.SPORED) == 4, "reapplication does not extend older stacks")
	_check(load("res://resource/tower/driftspore.tres").status_max_stacks == 48, "Driftspore retains larger capacity")
	var brimming = load("res://resource/dream/brimming.tres")
	_check(EnemyStatuses.STATIC in brimming.requires_any_status, "Brimming supports larger Charged buildup and payoff")
	var copied := EnemyStatuses.new()
	copied.apply(EnemyStatuses.SPORED, 4)
	copied.tick(1.0)
	copied.apply(EnemyStatuses.SPORED, 4)
	_check(is_equal_approx(copied.copy_duration(EnemyStatuses.SPORED), 4.0), "copies cannot refresh older stacks to the newest lifetime")
	var capped := EnemyStatuses.new()
	capped.apply(EnemyStatuses.SPORED, 16)
	capped.tick(1.0)
	capped.apply(EnemyStatuses.SPORED, 1)
	for i in 41:
		capped.tick(0.1)
	_check(capped.stacks(EnemyStatuses.SPORED) == 1, "at capacity only the replaced stack receives a fresh lifetime")
	var caught := EnemyStatuses.new()
	caught.apply(EnemyStatuses.SPORED, 4)
	caught.caught_time = 10.0
	for i in 60:
		caught.tick(0.1)
	_check(caught.stacks(EnemyStatuses.SPORED) == 4, "Caught preserves each poison application")
	caught.remove(EnemyStatuses.SPORED)
	caught.apply(EnemyStatuses.SPORED, 1)
	_check(caught.stacks(EnemyStatuses.SPORED) == 1, "consumed poison leaves no old stack batches")
	var d := EnemyStatuses.new()
	d.is_boss = true
	d.apply(EnemyStatuses.DROWSY, 50)
	_check(d.stacks(EnemyStatuses.DROWSY) == 12 and d.get_speed_multiplier() >= 0.7, "boss control remains bounded")
	var charge := EnemyStatuses.new()
	var bolts := 0.0
	for i in 40:
		bolts += charge.apply(EnemyStatuses.STATIC, 1, 0.0, 2.0)
	_check(is_equal_approx(bolts, 64.0) and not charge.has(EnemyStatuses.STATIC), "more charge applications still trigger repeated bolts")
	print("status stacking test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + label)