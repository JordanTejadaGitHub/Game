extends SceneTree

# Deterministic sustained-target probe, not a full run or win-rate simulation.
# Uses current tower resources, 60 Hz, no Dreams, no movement/resistance/reactions.
var failures := 0

func _initialize() -> void:
	var results := []
	for count in [1, 2, 4]:
		var row := _probe("sporeling", count)
		results.append(row)
		print(JSON.stringify(row))
	_check(absf(results[0].poison_dps - 16.8) < 0.6, "single Sporeling gains the approved 20% damage while retaining ten sustained stacks")
	_check(results[1].poison_dps > results[0].poison_dps * 1.45, "a second Sporeling adds substantial poison output")
	print(JSON.stringify(_probe("sporeling", 4, 64)))
	# Same 80-Dew allowance: three base towers spend75, two grown towers spend80.
	print(JSON.stringify(_probe("sporeling", 3)))
	print(JSON.stringify(_probe("driftspore", 2)))
	print("status balance probe: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _probe(id: String, count: int, override_cap: int = 0) -> Dictionary:
	var data: TowerData = load("res://resource/tower/%s.tres" % id)
	var status := EnemyStatuses.new()
	var damage := 0.0
	var maximum := 0
	var interval := 1.0 / data.attacks_per_second
	var next_hit := 0.0
	var cap := override_cap if override_cap > 0 else data.status_max_stacks
	for frame in 1800:
		var seconds := frame / 60.0
		if seconds + 0.00001 >= next_hit:
			for tower in count:
				status.apply(EnemyStatuses.SPORED, data.status_stacks, data.status_duration,
					data.damage * Tower.SPORE_POTENCY, cap)
			next_hit += interval
		var tick := status.tick(1.0 / 60.0)
		if frame >= 600:
			damage += tick * data.potency
		maximum = maxi(maximum, status.stacks(EnemyStatuses.SPORED))
	var cost := data.cost
	if id == "driftspore":
		var base: TowerData = load("res://resource/tower/sporeling.tres")
		cost = base.cost + base.evolve_cost
	return {"tower": id, "count": count, "spent_dew": cost * count,
		"capacity": status.get_max_stacks(EnemyStatuses.SPORED), "peak_stacks": maximum,
		"poison_dps": snappedf(damage / 20.0, 0.01),
		"direct_dps": data.damage * data.attacks_per_second * count}

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + label)