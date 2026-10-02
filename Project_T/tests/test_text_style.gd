extends SceneTree

# Text lint (text_style.md "Text lint test"): scans the player-facing text it can reach and fails on
#   - a name in lowercase outside a {token} ("withered trees", "old kin"), names built from the data;
#   - a raw internal id (snake_case, or a line id like "any wing final form");
#   - " - ", " | ", or double spaces around " · ";
#   - a leftover "{token}" after formatting;
#   - "The" capitalised in a boss name mid-sentence ("About The Mire Hag").
# Findings are grouped by owner (text_style.md "First sweep"). Only owners in ENFORCED fail the test;
# the others print as TODO until their sweep is done (then add them). Allowed exceptions: EXCEPTIONS.

const ENFORCED := ["Main", "Meta Game Code", "Tower Code", "Enemy Code", "Roguelite Code"]
# Substrings of a text (lowercase) that may break a rule on purpose.
const EXCEPTIONS := [
	"fall asleep", "falls asleep", "asleep", "the seed a samara throws", "seeds it throws", "its seeds",
	"light up", "lights up", "in the light", "first light", "moonlight", "lantern light", "a still pool",
]
# Single-word names that are also ordinary words: only checked through tokens, not in running text.
const COMMON_WORDS := ["spore", "stone", "water", "light", "root", "song", "talon", "wind", "plain", "sprout",
	"acorn", "seed", "seeds", "dew", "sapling", "blooming", "caught", "hidden", "frozen", "rooted", "asleep",
	"drowsy", "soaked", "charged", "exposed", "poisoned", "held", "marked", "cairn", "beacon", "monsoon",
	"lantern", "shade", "husk", "crow", "crows", "moth", "wisp", "echo", "rest", "act", "drift", "block",
	"family", "kinship", "leaves", "leaf", "grove", "memory", "omen", "dream", "dreams", "codex", "warden", "wardens",
	"bramble", "honeysuckle", "puffball", "thornwall", "hummingbird", "samara", "dewdrop", "firefly", "morning fog",
	"rain", "fog", "bell", "starling", "gust", "whirlwind", "tempest", "dawnburst", "chain", "reaction"]
const LINE_IDS := ["wing", "acorn", "song", "spore", "stone", "water", "light", "root", "wind", "sprout"]
# Internal archetype (resonance) tags: never shown as "wide cards" / "1 tempo card" (text_style.md "Same-tag (resonance) lines
# name the cards", user: "what are wide cards?"). Kinship is a player term, so it isn't here.
const ARCHETYPE_WORDS := ["tall", "overgrowth", "daring", "precision", "affliction", "maze", "tending", "swift", "reach",
	"wide", "narrow", "tempo", "crit", "economy", "nurture", "status", "opener", "clearing"]

var names: Array[String] = []  # Every name, Title Case, longest first
var findings := {}  # Owner -> ["source: problem"]
var _name_regex := {}

func _init() -> void:
	_build_names()
	_scan_resources()
	for group in CodexData.glossary():
		for entry in group[1]:
			_lint("Main", "glossary %s" % entry[0], entry[1])
	for id in IconInfo.STATUSES:
		_lint("Main", "status %s" % id, IconInfo.STATUSES[id][1])
	var whispers: Dictionary = (load("res://scripts/ui/whispers.gd") as Script).get_script_constant_map().get("TEXT", {})
	for id in whispers:
		_lint("Main", "whisper %s" % id, whispers[id])
	_scan_script_strings("res://scripts/ui", "Main")
	_scan_script_strings("res://scripts/run", "Main")
	_self_check()
	var failures := 0
	for owner in findings:
		var list: Array = findings[owner]
		var enforced := ENFORCED.has(owner)
		print("%s %s: %d" % ["FAIL" if enforced else "TODO", owner, list.size()])
		for line in list.slice(0, 40):
			print("  ", line)
		if list.size() > 40:
			print("  … and %d more" % (list.size() - 40))
		if enforced:
			failures += list.size()
	print("text style test: ", "all passed" if failures == 0 else "%d FAILED" % failures)
	quit(mini(failures, 255))

# The names, from the data (text_style.md: Wardens, nightmares, bosses, Dreams, Omens, Reactions,
# families, damage types, statuses, obstacles, currencies, the Heartwood / Memory Grove, Kinships and stages).
func _build_names() -> void:
	var found := {}
	for path in _tres("res://resource"):
		var res := load(path)
		if res == null:
			continue
		var name = res.get("display_name")
		# Dream card names are ordinary phrases in running text ("its sweet scent"): not checked there.
		if name is String and name != "" and not path.contains("/drift/") and not path.contains("/meta/") and not path.contains("/dream/"):
			found[String(name).trim_prefix("The ")] = true
	for family in CodexData.FAMILY_NAMES.values():
		found[family] = true
	for id in IconInfo.STATUSES:
		found[IconInfo.STATUSES[id][0]] = true
	for line in IconInfo.DAMAGE_TYPES:
		found[IconInfo.DAMAGE_TYPES[line][0]] = true
	for kin in CodexData.kinships():
		found[kin.name] = true
	for extra in ["Dew", "Dreamlight", "Seeds", "Heartwood", "Memory Grove", "Sapling", "Blooming", "Old Kin", "Whole Tree",
			"Deeply Blighted", "Withered Tree", "Mossy Boulder"]:
		found[extra] = true
	for name in found:
		names.append(name)
	names.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())

func _tres(dir: String) -> Array[String]:
	var out: Array[String] = []
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".tres"):
			out.append(dir.path_join(file))
	for sub in DirAccess.get_directories_at(dir):
		out.append_array(_tres(dir.path_join(sub)))
	return out

const FIELDS := ["display_name", "description", "trait_text", "hint", "title", "cleanse_line", "whisper",
	"cost_description", "grows_text", "clear_verb", "tips", "sidegrade_description"]

func _scan_resources() -> void:
	for path in _tres("res://resource"):
		if path.contains("/drift/") and not path.contains("template"):
			continue
		var res := load(path)
		if res == null:
			continue
		var owner := _owner_of(path)
		for field in FIELDS:
			var value = res.get(field)
			var texts: Array = value if value is Array else [value]
			for text in texts:
				if text is String and text != "":
					_lint(owner, "%s %s" % [path.trim_prefix("res://resource/"), field], text, field == "title")

func _owner_of(path: String) -> String:
	for pair in [["/tower/", "Tower Code"], ["/reaction/", "Tower Code"], ["/dream/", "Roguelite Code"],
			["/omen/", "Roguelite Code"], ["/drift/", "Roguelite Code"], ["/enemy/", "Enemy Code"], ["/boss/", "Enemy Code"],
			["/meta/", "Meta Game Code"]]:
		if path.contains(pair[0]):
			return pair[1]
	return "Main"

# String literals in the UI scripts: separators and lowercase names only (they're format strings).
func _scan_script_strings(dir: String, owner: String) -> void:
	var literal := RegEx.create_from_string("\"((?:[^\"\\\\]|\\\\.)*)\"")
	for file in DirAccess.get_files_at(dir):
		if not file.ends_with(".gd"):
			continue
		var lines := FileAccess.get_file_as_string(dir.path_join(file)).split("\n")
		for i in lines.size():
			var line := lines[i]
			var code := line.strip_edges()
			if code.begins_with("#") or code.begins_with("print") or code.contains("push_warning") or code.contains("push_error"):
				continue
			for m in literal.search_all(line):
				var text := m.get_string(1)
				if text.contains(" ") and not text.begins_with("res://") and not text.begins_with("user://"):
					_lint(owner, "%s:%d" % [file, i + 1], text, false, true)

func _lint(owner: String, source: String, text: String, is_title := false, is_code := false) -> void:
	var problems: Array[String] = []
	var lower := text.to_lower()
	if text.contains(" - ") or text.contains(" | "):
		problems.append("separator \" - \" or \" | \"")
	if text.contains("  ·") or text.contains("·  "):
		problems.append("double spaces around \" · \"")
	var plain := RegEx.create_from_string("\\{[^}]*\\}").sub(text, "", true)
	if not is_code:
		var formatted := IconInfo.format(text)
		var leftover := RegEx.create_from_string("\\{[A-Za-z_:]+\\}").search(formatted)
		if leftover != null:
			problems.append("leftover %s" % leftover.get_string())
		var snake := RegEx.create_from_string("(?<![A-Za-z_%{])[a-z]+_[a-z_]+(?![A-Za-z_}])").search(plain)
		if snake != null:
			problems.append("raw id \"%s\"" % snake.get_string())
		var line_id := RegEx.create_from_string("\\b(?:[Aa]ny|[Aa]n?|[Tt]he)\\s+(" + "|".join(LINE_IDS) + ")\\s+(?:final form|cards?|family|wardens?|branch)").search(plain)
		if line_id != null:
			problems.append("line id \"%s\"" % line_id.get_string())
		var archetype := RegEx.create_from_string("(?i)\\b(" + "|".join(ARCHETYPE_WORDS) + ")\\s+cards?\\b").search(plain)
		if archetype != null:
			problems.append("archetype tag \"%s\" (name the cards instead)" % archetype.get_string())
		var damage := RegEx.create_from_string("\\b(spore|stone|water|light|root|song|talon|wind|plain) damage\\b").search(plain)
		if damage != null:
			problems.append("\"%s\" (damage types are names)" % damage.get_string())
	var mid_the := RegEx.create_from_string("(?<=[a-z,] )The (?=[A-Z])").search(plain)
	if mid_the != null and not is_title:
		problems.append("\"The\" mid-sentence before a name")
	for name in names:
		if COMMON_WORDS.has(name.to_lower()) or name.length() < 4:
			continue
		var regex: RegEx = _name_regex.get(name)
		if regex == null:
			regex = RegEx.create_from_string("(?i)(?<![A-Za-z])" + _escape(name) + "(?:s|es)?(?![A-Za-z])")
			_name_regex[name] = regex
		for m in regex.search_all(plain):
			var got := m.get_string().left(name.length())
			if got != name and got.to_lower() == name.to_lower() and not _excepted(lower, m.get_string().to_lower()):
				problems.append("\"%s\" should be \"%s\"" % [m.get_string(), name])
				break
	for problem in problems:
		if not findings.has(owner):
			findings[owner] = []
		findings[owner].append("%s: %s  [%s]" % [source, problem, text.left(90).replace("\n", " / ")])

func _excepted(lower_text: String, match_text: String) -> bool:
	for exception in EXCEPTIONS:
		if exception.contains(match_text) and lower_text.contains(exception):
			return true
	return false

func _escape(s: String) -> String:
	var out := ""
	for c in s:
		out += ("\\" + c) if ".^$*+?()[]{}|\\-".contains(c) else c
	return out

# The linter itself catches what it should (kept out of the findings).
func _self_check() -> void:
	var saved := findings.duplicate(true)
	findings.clear()
	_lint("Self", "a", "Tend withered trees and move boulders.")
	_lint("Self", "b", "Old  ·  New")
	_lint("Self", "c", "Any wing final form")
	_lint("Self", "d", "About The Mire Hag")
	_lint("Self", "f", "+20% from 2 wide cards")
	_lint("Self", "e", "Tend Withered Trees and move Mossy Boulders.")
	var hits: Array = findings.get("Self", [])
	var ok := hits.size() == 5 and not hits.any(func(h: String) -> bool: return h.begins_with("e:"))
	findings = saved
	if not ok:
		findings["Main"] = findings.get("Main", []) + ["linter self-check: %s" % [hits]]
