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
			_one_name("Main", "glossary %s" % entry[0], entry[1])
	_keywords()
	for id in IconInfo.STATUSES:
		_lint("Main", "status %s" % id, IconInfo.STATUSES[id][1])
		_one_name("Main", "status %s" % id, IconInfo.STATUSES[id][1])
	var whispers: Dictionary = (load("res://scripts/ui/whispers.gd") as Script).get_script_constant_map().get("TEXT", {})
	for id in whispers:
		_lint("Main", "whisper %s" % id, whispers[id], false, false, true)  # Shown through UiStyle.whisper(): flavour
	_scan_script_strings("res://scripts/ui", "Main")
	_scan_script_strings("res://scripts/run", "Main")
	# Card wording (text_style.md "Card wording, one way each", story chat 2026-10-02: all player-facing text, not just
	# cards): the other owners' script strings for those rules only (stat tips, Reactions, nightmare text, the Grove).
	_scan_script_strings("res://scripts/tower", "Tower Code", true)
	_scan_script_strings("res://scripts/combat", "Tower Code", true)
	_scan_script_strings("res://scripts/enemy", "Enemy Code", true)
	_scan_script_strings("res://scripts/meta", "Meta Game Code", true)
	_self_check()
	_link_checks()
	var failures := 0
	for owner in findings:
		var list: Array = findings[owner]
		var enforced: bool = WORDING_ENFORCED.has(owner.trim_suffix(" wording")) if owner.ends_with(" wording") \
				else GLYPHS_ENFORCED.has(owner.trim_suffix(" glyphs")) if owner.ends_with(" glyphs") \
				else CAPS_ENFORCED.has(owner.trim_suffix(" caps")) if owner.ends_with(" caps") else ENFORCED.has(owner)
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

# Scripts in a folder another chat owns most of (scripts/run is Main's run flow; the Dream and Omen code is Roguelite's).
const FILE_OWNERS := {"dream_state.gd": "Roguelite Code", "dream_effects.gd": "Roguelite Code", "omen_director.gd": "Roguelite Code",
	"dream_sim_policy.gd": "Roguelite Code"}

# String literals in the UI scripts: separators and lowercase names only (they're format strings).
func _scan_script_strings(dir: String, owner: String, wording_only := false) -> void:
	var literal := RegEx.create_from_string("\"((?:[^\"\\\\]|\\\\.)*)\"")
	for file in DirAccess.get_files_at(dir):
		if not file.ends_with(".gd"):
			continue
		var lines := FileAccess.get_file_as_string(dir.path_join(file)).split("\n")
		for i in lines.size():
			var line := lines[i]
			var code := line.strip_edges()
			# Italic flavour (UiStyle.whisper(), *flavo(u)r* fields) is prose: exempt from the status-name rule (text_pass.md da416134).
			var flavour := FLAVOUR_FILES.has(file) or code.contains("whisper(") or code.to_lower().contains("flavo")
			_caps_off = CAPS_SKIP_LINES.any(func(s: String) -> bool: return code.contains(s))
			if code.begins_with("#") or code.begins_with("print") or code.contains("push_warning") or code.contains("push_error"):
				continue
			for m in literal.search_all(line):
				var text := m.get_string(1)
				if text.contains(" ") and not text.begins_with("res://") and not text.begins_with("user://"):
					var file_owner: String = FILE_OWNERS.get(file, owner)
					if wording_only:
						_wording(file_owner, "%s:%d" % [file, i + 1], text)
						_glyphs(file_owner, "%s:%d" % [file, i + 1], text)
						_caps(file_owner, "%s:%d" % [file, i + 1], text, flavour)
					else:
						_lint(file_owner, "%s:%d" % [file, i + 1], text, false, true, flavour)
	_caps_off = false

# Keywords are always links (text_pass.md "Keywords are always links", user 2026-10-13): every keyword has a token and a
# glossary entry of at most 30 words, and the ones linked as plain words (StatusLinks.PLAIN_TERMS) really are: a link
# the first time in a block, plain after that, plain inside their own entry, never inside a longer keyword. A keyword
# that is also an ordinary word (full, grow, act, stack…) links through its token only, so a plain-word check on
# those would flag ordinary English: there is none.
const ENTRY_WORDS := 30
func _keywords() -> void:
	var problems: Array[String] = []
	for id in IconInfo.TERMS:
		var entry_name: String = IconInfo.TERMS[id][2]
		var entry := CodexData.definition(entry_name)
		if entry == "":
			problems.append("keyword %s: no glossary entry \"%s\"" % [id, entry_name])
		if StatusLinks.bbcode("a {%s} b" % id).count("[url=term:%s]" % id) != 1:
			problems.append("keyword %s: its token is not a link" % id)
	for id in StatusLinks.PLAIN_TERMS:
		var word: String = IconInfo.TERMS[id][0]
		var entry_name: String = IconInfo.TERMS[id][2]
		var entry := IconInfo.format(CodexData.definition(entry_name))
		if entry.split(" ", false).size() > ENTRY_WORDS and not [&"potency", &"reaction", &"dread_shell", &"thornwall", &"eldest", &"legendary"].has(id):
			problems.append("keyword %s: its entry is over %d words" % [id, ENTRY_WORDS])
		var twice := StatusLinks.bbcode("The %s here, the %s there." % [word, word])
		if twice.count("[url=term:%s]" % id) != 1:
			problems.append("keyword %s: the plain word links %d times in a block (once)" % [id, twice.count("[url=term:%s]" % id)])
		StatusLinks.own_term = entry_name
		if StatusLinks.bbcode("The %s here." % word).contains("[url=term:%s]" % id):
			problems.append("keyword %s: linked inside its own entry" % id)
		StatusLinks.own_term = ""
	if StatusLinks.bbcode("A Crowned Reaction and a Reaction.").count("[url=term:reaction]") != 1:
		problems.append("Reaction links inside Crowned Reaction")
	if StatusLinks.bbcode("Calling early pays Dew.").contains("term:calling") or StatusLinks.bbcode("Dream Oak grows.").contains("term:dream"):
		problems.append("a keyword links inside a name or a verb (Calling early, Dream Oak)")
	var named := StatusLinks.bbcode("Beside a {warden:sporeling}.")
	if not named.contains("[url=warden:sporeling]") or StatusLinks.card_tip("warden:sporeling").get("text", "") == "":
		problems.append("{warden:id} is not a name link with a tip (%s)" % named)
	for problem in problems:
		if not findings.has("Main"):
			findings["Main"] = []
		findings["Main"].append(problem)

# One name per thing (wording_review_2026-10-13.md section 1): the reference texts (glossary, statuses) never use the
# old names. Only those texts: card and Warden text have their own owners and reviews.
const OLD_NAMES := "(?i)\\b(road|roads|route|routes|leak|leaks|leaked|loadout|buff|buffs|tower bar|maze dew)\\b"
func _one_name(owner: String, source: String, text: String) -> void:
	var found := RegEx.create_from_string(OLD_NAMES).search(RegEx.create_from_string("\\{[^}]*\\}").sub(text, "", true))
	if found != null:
		if not findings.has(owner):
			findings[owner] = []
		findings[owner].append("%s: old name \"%s\" (path, reaches the Heartwood, perk slot, boost, Warden bar, Maze bonus)  [%s]" % [source, found.get_string(), text.left(90).replace("\n", " / ")])

func _lint(owner: String, source: String, text: String, is_title := false, is_code := false, is_flavour := false) -> void:
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
	_wording(owner, source, text)
	_glyphs(owner, source, text)
	_caps(owner, source, text, is_flavour)

# Capitalisation (text_pass.md "Capitalisation", user 2026-10-07: "let's be consistent with capitalisation"): statuses
# in every form (Soaked / Soaks) and the currencies (Dew, Dreamlight, Seeds) are names, so never lower case; drift and
# rest are common words, so never capitalised mid-sentence ("Start drift 1", "at the next rest"). Findings go under
# "<owner> caps": TODO until the owner's sweep, then the owner joins CAPS_ENFORCED.
const CAPS_ENFORCED: Array[String] = ["Main", "Roguelite Code", "Enemy Code", "Tower Code"]  # Main's sweep, Roguelite's, Enemy Code's, Tower Code's (2026-10-07)
# Status verbs as role lines and descriptions use them ("Anti-air, Roots"); the nouns come from IconInfo.STATUSES.
const STATUS_VERBS := ["roots", "soaks", "charges", "poisons", "drowses", "exposes", "silences", "freezes"]
# Substrings of a text (lowercase) that use one of those words in its ordinary sense on purpose.
const CAPS_EXCEPTIONS := [
	# Literal seeds (a Samara's, the Grove Keeper's), not the Seeds currency (text_pass.md da416134).
	"the seed a samara throws", "seeds it throws", "its seeds", "samara's seeds", "seeds in a fan", "5 seeds", "three seeds",
	"seeds come", "birds, seeds", "rings and seeds", "seeds down",
	"sprout charges", "five charges", "5 charges", "charges down",  # charges as a count, or a stag's charge
	"heartwood's roots", "their roots", "its roots", "roots went", "roots that", "glowing roots", "roots erupt",  # roots of a tree
	"caught seed", "when caught", "caught %d", "caught this run",  # caught as in catching, not the Caught status
	"fall asleep", "falls asleep", "not charged", "rooted for good", "hidden one", "hidden branch",  # ordinary words
	"sunlit rest", "watchful rest",  # Dream card names
	"crowned reaction discovered",  # Small caps (lower-cased on purpose)
]
# Code lines whose strings are lookup keys, not text.
const CAPS_SKIP_LINES := ["const ROLE_TERMS", "\"reveals hidden\": &"]
# Scripts whose every string is italic flavour (shown through UiStyle.whisper()).
const FLAVOUR_FILES := ["whispers.gd"]
var _caps_rules: Array = []
var _caps_off := false  # A CAPS_SKIP_LINES line is being scanned
func _caps(owner: String, source: String, text: String, is_flavour := false) -> void:
	if _caps_off:
		return
	if _caps_rules.is_empty():
		var statuses: Array[String] = []
		for id in IconInfo.STATUSES:
			var word := String(IconInfo.STATUSES[id][0]).to_lower()
			if not word.contains(" "):  # Deeply Blighted is a name the main lint checks
				statuses.append(word)
		statuses.append_array(STATUS_VERBS)
		statuses.append_array(["reactions", "reaction"])  # A Reaction is a name too (user 2026-10-12); flavour is exempt like the statuses
		_caps_rules = [
			[RegEx.create_from_string("(?<![A-Za-z_%{])(" + "|".join(statuses) + ")(?![A-Za-z_])"), "a status or Reaction in lower case (they are names)"],
			[RegEx.create_from_string("(?<![A-Za-z_%{])(dew|dreamlight|seeds)(?![A-Za-z_])"), "a currency in lower case (Dew, Dreamlight, Seeds)"],
			[RegEx.create_from_string("(?<=[a-z0-9,;] )(?:Drifts?|Rests?)(?![A-Za-z])"), "\"Drift\" / \"Rest\" capitalised mid-sentence"],
		]
	# Tokens, BBCode tags and <icon> tags ("<dew>240") hold ids, not words.
	var plain := RegEx.create_from_string("\\{[^}]*\\}|\\[[^\\]]*\\]|<[a-z_]+>").sub(text, " ", true)
	var lower := text.to_lower()
	for i in _caps_rules.size():
		var rule: Array = _caps_rules[i]
		if is_flavour and i == 0:
			continue  # Flavour prose may say "Rain soaks everything."
		for hit in (rule[0] as RegEx).search_all(plain):
			if _caps_excepted(lower, hit.get_string().to_lower()):
				continue
			findings.get_or_add(owner + " caps", []).append("%s: %s \"%s\"  [%s]"
				% [source, rule[1], hit.get_string(), text.left(90).replace("\n", " / ")])
			break

func _caps_excepted(lower_text: String, word: String) -> bool:
	for exception in CAPS_EXCEPTIONS:
		if exception.contains(word) and lower_text.contains(exception):
			return true
	return false

# Prices and rewards as the resource icon and the number (user via Main Merger 2026-10-06): "15 Dew", "%d Dew",
# "+1 Dreamlight", "{plant_cost:x} Seeds" should be UiStyle.dew_amount(15) / "{dew:15}". Findings go under
# "<owner> glyphs": TODO until the owner's sweep, then the owner joins GLYPHS_ENFORCED.
const GLYPHS_ENFORCED: Array[String] = ["Main", "Roguelite Code"]  # Sweeps: Main 41982196, Roguelite e8bc7105 (2026-10-07)
# Texts that keep the word on purpose: the plain-text run report (a glyph would paste as a box) and a block index.
# "+%d Dew" is DewPopup's until it switches to UiStyle.dew_amount (WorldLabel draws the glyphs since UI Code's with_glyphs).
const GLYPH_EXCEPTIONS := ["%d drifts · %d Dew", "Block %d Dew by route", "+%d Dew"]
var _glyph_rule := RegEx.create_from_string("(?:\\d+|%[-+.\\d]*[ds]|\\{[a-z_]+:[^}]*\\})\\s+(?:Dew|Dreamlight|Seeds?)\\b")
func _glyphs(owner: String, source: String, text: String) -> void:
	var found := _glyph_rule.search(text)
	if found != null and not GLYPH_EXCEPTIONS.any(func(e: String) -> bool: return text.contains(e)):
		findings.get_or_add(owner + " glyphs", []).append("%s: \"%s\" (the icon and the number: UiStyle.dew_amount / {dew:N})  [%s]"
			% [source, found.get_string(), text.left(90).replace("\n", " / ")])
	# The gold star once stood for Dreamlight (user 2026-10-12: "Dreamlight icon looks different on some things"): never now.
	if text.contains("✦"):
		findings.get_or_add(owner + " glyphs", []).append("%s: the star stands for Dreamlight (UiStyle.dreamlight_amount / DREAMLIGHT_GLYPH)  [%s]"
			% [source, text.left(90).replace("\n", " / ")])

# Card wording, one way each (text_style.md, 2026-10-02): distances in cells, caps as "up to", Warden bonuses as
# verbs. Its findings go under "<owner> wording": enforced for WORDING_ENFORCED, TODO for the rest until their sweep.
const WORDING_ENFORCED := ["Main", "Roguelite Code", "Tower Code", "Enemy Code", "Meta Game Code"]  # Every owner swept (2026-10-02)
var _wording_rules: Array = []
func _wording(owner: String, source: String, text: String) -> void:
	if _wording_rules.is_empty():
		_wording_rules = [
			# "4.5 tiles", "%.1f tiles", "3+ tiles"; "5+ path tiles" counts path squares and is fine.
			[RegEx.create_from_string("(?i)(?:\\d+(?:\\.\\d+)?|%[-+.\\d]*[dfs])\\+?\\s+tiles?\\b"), "a distance in tiles (say cells)"],
			# A cap: "(max +45%)", "max 3"; "+3 max leaves" names a stat and is fine.
			[RegEx.create_from_string("(?i)\\bmax\\.?\\s*(?=[+\\d]|%[-+.\\d]*[df])"), "\"max\" for a cap (say \"up to\")"],
			# A Warden's bonus; the nightmare side ("+25% damage taken") is fine.
			[RegEx.create_from_string("(?i)(?:\\+\\d+(?:\\.\\d+)?|\\+%[-+.\\d]*[dfs])%%?\\s+(?:damage|attack speed)\\b(?!\\s+taken)"),
				"a Warden bonus as \"+N% damage\" (say \"deal N% more damage\" / \"attack N% faster\")"],
		]
	var plain := RegEx.create_from_string("\\{[^}]*\\}").sub(text, "", true)
	plain = RegEx.create_from_string("(?i)longest path: [^\\s]+ tiles").sub(plain, "", true)  # A path's length in path tiles
	for rule in _wording_rules:
		var hit: RegExMatch = rule[0].search(plain)
		if hit != null:
			var key := owner + " wording"
			if not findings.has(key):
				findings[key] = []
			findings[key].append("%s: %s \"%s\"  [%s]" % [source, rule[1], hit.get_string(), text.left(90).replace("\n", " / ")])

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
# Dread shell as a link (user: "dread shell should have an underline with the nightmare linked"): the {dread_shell}
# token and the plain words (any case, plural) link the term, and the glossary's line names its wearers as nightmare
# links, read from the data. Failures go to Main (enforced).
func _link_checks() -> void:
	var term := "[url=term:dread_shell]"
	var cases := {
		"token": StatusLinks.bbcode("Wears a {dread_shell} away."),
		"plain words": StatusLinks.bbcode("A dread shell shrugs off small hits."),
		"capitalised plural": StatusLinks.bbcode("Dread shells crack."),
		"Lichenling": StatusLinks.bbcode((load("res://resource/tower/lichenling.tres") as TowerData).description),
		"Old Lichen": StatusLinks.bbcode((load("res://resource/tower/old_lichen.tres") as TowerData).description),
		"Crusted Brood": StatusLinks.bbcode(CodexData.KINSHIP_TEXT[&"crusted_brood"]),
	}
	for name in cases:
		if not String(cases[name]).contains(term):
			findings.get_or_add("Main", []).append("links: %s shows dread shell without its link" % name)
	if not StatusLinks.bbcode("Dread shells crack.").contains("]Dread shells[/color]"):
		findings.get_or_add("Main", []).append("links: a plain term keeps its written form")
	var line := CodexData.nightmares_line("Dread shell")
	if not line.contains("{nightmare:shellbound}"):
		findings.get_or_add("Main", []).append("links: the dread shell glossary line names Shellbound from its data (%s)" % line)
	if not StatusLinks.bbcode(line).contains("[url=nightmare:shellbound]"):
		findings.get_or_add("Main", []).append("links: wearers are nightmare links")
	if IconInfo.format(line).contains("{"):
		findings.get_or_add("Main", []).append("links: nightmare tokens format to names (%s)" % IconInfo.format(line))

func _self_check() -> void:
	var saved := findings.duplicate(true)
	findings.clear()
	_lint("Self", "a", "Tend withered trees and move boulders.")
	_lint("Self", "b", "Old  ·  New")
	_lint("Self", "c", "Any wing final form")
	_lint("Self", "d", "About The Mire Hag")
	_lint("Self", "f", "+20% from 2 wide cards")
	_lint("Self", "e", "Tend Withered Trees and move Mossy Boulders.")
	_caps("Self", "g", "It roots nightmares.")
	_caps("Self", "h", "Earn dew each drift.")
	_caps("Self", "i", "Wait for the next Rest.")
	_caps("Self", "j", "Rain soaks everything.", true)  # Flavour
	_caps("Self", "k", "Rest bonus. Soaked nightmares pay [color=gold]Dew[/color]; a Samara's seeds fly.")
	var caps_hits: Array = findings.get("Self caps", [])
	var hits: Array = findings.get("Self", [])
	var ok := hits.size() == 5 and not hits.any(func(h: String) -> bool: return h.begins_with("e:")) \
			and caps_hits.size() == 3 and not caps_hits.any(func(h: String) -> bool: return h.begins_with("j:") or h.begins_with("k:"))
	hits = hits + caps_hits
	findings = saved
	if not ok:
		findings["Main"] = findings.get("Main", []) + ["linter self-check: %s" % [hits]]
