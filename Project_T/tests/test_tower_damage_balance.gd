extends SceneTree

var failures := 0
func _initialize() -> void:
	# Power budget (Balancing, owner review 2026-10-16): tier 1 x0.90, tier 2 x0.75 (was 18.2, 8.4, 55.2, 16.8).
	for sample in [["firefly_jar", 16.38, 1.5], ["sporeling", 7.56, 2.0], ["pebbling", 49.68, 0.75], ["driftspore", 12.6, 2.0]]:
		var data: TowerData = load("res://resource/tower/%s.tres" % sample[0])
		_check(is_equal_approx(data.damage, sample[1]), "%s preserves its approved fractional damage" % sample[0])
		_check(is_equal_approx(data.attacks_per_second, sample[2]), "%s retains its buildup rate" % sample[0])
	print("tower damage balance test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + label)