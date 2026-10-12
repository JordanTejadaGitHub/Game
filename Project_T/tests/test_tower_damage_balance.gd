extends SceneTree

var failures := 0
func _initialize() -> void:
	for sample in [["firefly_jar", 18.2, 1.5], ["sporeling", 8.4, 2.0], ["pebbling", 55.2, 0.75], ["driftspore", 16.8, 2.0]]:
		var data: TowerData = load("res://resource/tower/%s.tres" % sample[0])
		_check(is_equal_approx(data.damage, sample[1]), "%s preserves its approved fractional damage" % sample[0])
		_check(is_equal_approx(data.attacks_per_second, sample[2]), "%s retains its buildup rate" % sample[0])
	print("tower damage balance test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + label)