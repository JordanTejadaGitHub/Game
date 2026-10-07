extends SceneTree

# Every Warden form has its role line (tower_design.md "Role lines", 903b99a2: how it attacks, never its weakness; the user: "use more generic wording to
# describe"): non-empty, no full stop, 1–3 comma-separated terms, each from the fixed tower-defence vocabulary.
# Siblings may share a line where they truly play alike, so uniqueness within a family is only a warning. The parked
# Memory Wardens (is_unique) are left out until they return.
#   godot --headless --path . --script res://tests/test_role_lines.gd

# tower_design.md "Role lines" vocabulary (a new term goes there first, then here), as each reads mid-line: sentence
# case, but statuses keep their capital as names in every form (text_pass.md 7e151e86: "Anti-air, Roots").
const VOCABULARY := ["short range", "long range", "longest range", "high damage", "very high damage", "damage over time",
	"ramps up", "finisher", "fast attacks", "very fast attacks", "slow attacks", "single target", "multi-target",
	"area damage", "chains", "hits a line", "cone", "beam", "sniper", "boomerang", "lobs over walls", "crushing blows",
	"spins at bends", "rain cloud", "trails", "shares hits", "links to a partner", "grows with walls", "stacks high",
	"hurts the Rooted", "slows", "Roots", "Freezes", "stuns", "pulls back", "Silences", "stops sprints", "Soaks", "Charges",
	"Poisons", "Drowses", "Exposes", "spreads statuses", "sets up statuses", "anti-air", "boss killer", "crowd clearer",
	"breaks armour", "reveals Hidden", "guards the goal", "strips buffs", "crits", "repeats combos", "traps", "spawns",
	"copies a neighbour", "speeds allies", "boosts damage", "grows into any family", "support", "economy", "wall",
	"can't hit up close", "can't hit flyers", "doesn't attack"]

# `term` at `position` in a line reads exactly as the vocabulary has it (the first term with a leading capital).
static func _term_ok(term: String, position: int) -> bool:
	for word in VOCABULARY:
		var expected: String = word if position > 0 else word[0].to_upper() + word.substr(1)
		if term == expected:
			return true
	return false

var failures := 0

func _initialize() -> void:
	var by_family := {}
	var count := 0
	var shared := 0
	for file in DirAccess.get_files_at("res://resource/tower"):
		if not file.ends_with(".tres"):
			continue
		var data := load("res://resource/tower/" + file) as TowerData
		if data == null or data.is_unique:
			continue
		count += 1
		var line := data.role_line.strip_edges()
		_check(line != "", "%s has a role line" % data.get_id())
		_check(not line.ends_with("."), "%s: no full stop" % data.get_id())
		var terms := line.split(", ")
		_check(terms.size() >= 1 and terms.size() <= 3, "%s: 1–3 terms (%d)" % [data.get_id(), terms.size()])
		for i in terms.size():
			_check(_term_ok(terms[i], i), "%s: \"%s\" is in the vocabulary, capitalised as the rules say" % [data.get_id(), terms[i]])
		_check(line == "" or line[0] == line[0].to_upper(), "%s: sentence case" % data.get_id())
		var seen: Dictionary = by_family.get(data.line, {})
		if seen.has(line):
			shared += 1
			print("  (warning) %s shares its role line with %s in the %s family: \"%s\"" % [data.get_id(), seen[line], data.line, line])
		seen[line] = data.get_id()
		by_family[data.line] = seen
	_check(count >= 100, "every form checked (%d)" % count)
	print("role lines test: %s (%d forms, %d shared lines)" % ["PASS" if failures == 0 else "%d FAILED" % failures, count, shared])
	quit(failures)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + what)
