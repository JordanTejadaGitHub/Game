extends SceneTree

# Tower.potency_uses (story chat; the user: "Potency hover over Wardens should describe what it does for that Warden,
# like Rootling: what status?"): every form that applies a status names what Potency does with it, and a form where
# Potency does nothing says nothing.
#   godot --headless --path . --script res://tests/test_potency_uses.gd

var failures := 0

func _initialize() -> void:
	var count := 0
	for file in DirAccess.get_files_at("res://resource/tower"):
		if not file.ends_with(".tres"):
			continue
		var data := load("res://resource/tower/" + file) as TowerData
		if data == null or data.is_unique:
			continue
		count += 1
		var uses := Tower.potency_uses(data)
		var applies := data.can_attack and (data.applies_status != &"" or data.extra_status != &"" or data.pulse_hold_every > 0
			or data.hold_targets > 0)
		if applies:
			_check(not uses.is_empty(), "%s applies a status: Potency says what it does there" % data.get_id())
		for line in uses:
			_check(line != "" and not line.ends_with("."), "%s: \"%s\" is a short line" % [data.get_id(), line])
	_check(count >= 100, "every form checked (%d)" % count)
	_check(Tower.potency_uses(load("res://resource/tower/rootling.tres")).has("{held} lasts longer"), "Rootling: {held} lasts longer")
	_check(Tower.potency_uses(load("res://resource/tower/firefly_jar.tres")).has("{static} bolts hit harder"), "Firefly Jar: {static} bolts")
	_check(Tower.potency_uses(load("res://resource/tower/sporeling.tres")).has("{spored} ticks hit harder"), "Sporeling: {spored} ticks")
	_check(Tower.potency_uses(load("res://resource/tower/dewdrop.tres")).has("its Reactions hit harder"), "Dewdrop: its Reactions too")
	_check(Tower.potency_uses(load("res://resource/tower/thornwall.tres")).is_empty(), "Thornwall: nothing")
	print("potency uses test: %s (%d forms)" % ["PASS" if failures == 0 else "%d FAILED" % failures, count])
	quit(failures)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + what)
