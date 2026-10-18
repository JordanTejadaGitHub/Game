extends SceneTree

# Every Warden form has its role line (tower_design.md "Role lines", 164cd0b5: its attack shape first, in plain words, ending with any hard limit; the user: "use more generic wording to
# describe"): non-empty, no full stop, 1–4 comma-separated terms, each from the fixed tower-defence vocabulary.
# Siblings may share a line where they truly play alike, so uniqueness within a family is only a warning. The parked
# Memory Wardens (is_unique) are left out until they return.
#   godot --headless --path . --script res://tests/test_role_lines.gd

# tower_design.md "Role lines" vocabulary (a new term goes there first, then here), as each reads mid-line: sentence
# case, but statuses keep their capital as names in every form (text_pass.md 7e151e86: "Anti-air, Roots").
const VOCABULARY := ["short range", "long range", "longest range", "high damage", "very high damage", "damage over time",
	"ramps up", "finishes off the weak", "fast attacks", "very fast attacks", "slow attacks", "single target", "multi-target",
	"area damage", "chains", "hits a line", "hits a cone", "beam", "seed flies out and back", "lobs over walls", "hits all around it",
	"rains on the path", "leaves trails", "spreads damage", "links to a partner", "grows with walls", "hurts nightmares with Root", "slows",
	"Roots", "Roots the leader", "Roots the leaders", "Freezes", "puts to sleep", "pulls back", "Silences", "stops sprints", "Soaks", "Charges", "Poisons", "Drowses",
	"Exposes", "spreads statuses", "sets up statuses", "anti-air", "boss killer", "crowd clearer", "breaks armour",
	"reveals Hidden", "guards the goal", "removes boosts", "crits", "repeats Reactions", "traps", "summons helpers",
	"plants free Sprouts", "copies a neighbour", "speeds allies", "boosts damage", "grows into any family", "support", "economy", "wall",
	"can't hit up close", "can't hit flyers", "doesn't attack"]

# `term` at `position` in a line reads exactly as the vocabulary has it (the first term with a leading capital).
static func _term_ok(term: String, position: int) -> bool:
	for word in VOCABULARY:
		var expected: String = word if position > 0 else word[0].to_upper() + word.substr(1)
		if term == expected:
			return true
	return false

const HARD_LIMITS := ["can't hit up close", "can't hit flyers", "doesn't attack"]
# Attacks that never touch a flyer: rings on path tiles, sprites bursting on walkers, the whirlpool (no hits_flyers).
const GROUND_ONLY_SPECIALS := [&"brood", &"whirlpool"]

# Every line names the attack's shape (164cd0b5: a form keeps its family's base shape), read from the data: the
# shape terms a form may use. A special's own shape (helpers, the whirlpool's shared hits, a rain cloud…) counts.
const SPECIAL_SHAPES := {&"brood": ["summons helpers"], &"whirlpool": ["spreads damage"], &"cloud": ["rains on the path", "area damage"],
	&"jet": ["hits a line"], &"jarlink": ["hits a line"], &"thrum": ["hits a cone"], &"sparkler": ["area damage"]}

static func shape_terms(data: TowerData) -> Array:
	if SPECIAL_SHAPES.has(data.special):
		return SPECIAL_SHAPES[data.special]
	match data.attack_kind:
		TowerData.AttackKind.PROJECTILE:
			if data.splash_radius > 0.0 or data.lob:
				return ["area damage"]
			return ["single target", "multi-target"]
		TowerData.AttackKind.PULSE, TowerData.AttackKind.CLOUD, TowerData.AttackKind.PATROL:
			return ["area damage"]
		TowerData.AttackKind.CHAIN:
			return ["chains"]
		TowerData.AttackKind.BEAM:
			return ["beam"]
		TowerData.AttackKind.SPIN:
			return ["hits all around it"]
		TowerData.AttackKind.TRAP:
			return ["traps"]
		TowerData.AttackKind.BOOMERANG:
			return ["hits a line"]
		TowerData.AttackKind.SWOOP, TowerData.AttackKind.PECK:
			return ["single target", "multi-target"]
		TowerData.AttackKind.AURA:
			return ["doesn't attack"]
		TowerData.AttackKind.COPY:
			return ["copies a neighbour"]
		TowerData.AttackKind.SPREAD:
			return ["spreads statuses", "multi-target"]
		TowerData.AttackKind.LIGHT:
			return ["support"]
	return []

var failures := 0

# A hard limit the data has is in the line, and comes last (111e5ddf: "drawbacks like 'can't hit up close' must show").
func _check_hard_limits(data: TowerData, terms: PackedStringArray) -> void:
	var lower: Array[String] = []
	for term in terms:
		lower.append(term.to_lower())
	var id := data.get_id()
	_check((data.min_range > 0.0) == lower.has("can't hit up close"), "%s: min_range %.1f ⇔ \"can't hit up close\"" % [id, data.min_range])
	var ground_only := data.attack_kind == TowerData.AttackKind.TRAP or GROUND_ONLY_SPECIALS.has(data.special)
	_check(ground_only == lower.has("can't hit flyers"), "%s: never hits flyers ⇔ \"can't hit flyers\"" % id)
	if lower.has("doesn't attack"):
		_check(not data.can_attack or data.damage <= 0.0, "%s: \"doesn't attack\" only where it deals no damage" % id)
	var seen_limit := false
	for term in lower:
		if HARD_LIMITS.has(term):
			seen_limit = true
		else:
			_check(not seen_limit, "%s: the hard limit comes last" % id)

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
		_check(terms.size() >= 1 and terms.size() <= 4, "%s: 1–4 terms (%d)" % [data.get_id(), terms.size()])
		for i in terms.size():
			_check(_term_ok(terms[i], i), "%s: \"%s\" is in the vocabulary, capitalised as the rules say" % [data.get_id(), terms[i]])
		_check(line == "" or line[0] == line[0].to_upper(), "%s: sentence case" % data.get_id())
		_check_hard_limits(data, terms)
		if data.can_attack and data.damage > 0.0:  # No damage, no shape to name (Honeysuckle: "Wall, Drowses")
			var shapes := shape_terms(data)
			var named := false
			for term in terms:
				named = named or shapes.has(term.to_lower())
			_check(shapes.is_empty() or named, "%s: the line names its attack shape (%s)" % [data.get_id(), " / ".join(shapes)])
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
