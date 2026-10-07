extends SceneTree

# Every Warden form has its role line (tower_design.md "Role lines", 8c737201; the user: the family pick's short lines
# "should be a bit more unique for the branch"): non-empty, unique within its family (TowerData.line). The parked
# Memory Wardens (is_unique) are left out until they return.
#   godot --headless --path . --script res://tests/test_role_lines.gd

var failures := 0

func _initialize() -> void:
	var by_family := {}
	var count := 0
	for file in DirAccess.get_files_at("res://resource/tower"):
		if not file.ends_with(".tres"):
			continue
		var data := load("res://resource/tower/" + file) as TowerData
		if data == null or data.is_unique:
			continue
		count += 1
		_check(data.role_line.strip_edges() != "", "%s has a role line" % data.get_id())
		_check(not data.role_line.ends_with("."), "%s: no full stop" % data.get_id())
		var seen: Dictionary = by_family.get(data.line, {})
		_check(not seen.has(data.role_line), "%s's role line is unique in the %s family (\"%s\", also %s)" % [data.get_id(), data.line,
			data.role_line, seen.get(data.role_line, "")])
		seen[data.role_line] = data.get_id()
		by_family[data.line] = seen
	_check(count >= 100, "every form checked (%d)" % count)
	print("role lines test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + what)
