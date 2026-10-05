extends RefCounted

# The card text audit's shared logic (Roguelite Mechanic Discussion, 2026-10-02: "check every card's text"): used by
# tools/card_text_audit.gd (writes documentation/card_text_audit.csv) and tests/test_card_text.gd (fails on a stat card
# whose description numbers match none of its fields).
#   const Check := preload("res://tools/card_text_check.gd")
# Cards: resource/dream/*.tres and resource/meta/blessing/*.tres. Rule constants come from the code itself: every line
# naming a rule id (&"rule_id") in scripts/, the UPPER_CASE constants on it, their `const` values.

const CARD_DIRS: Array[String] = ["res://resource/dream/", "res://resource/meta/blessing/"]
const CODE_DIRS: Array[String] = ["res://scripts/"]
# Fields that are bookkeeping, not effect numbers (listed in the row, never matched against the text)
const NOT_EFFECT := ["rarity", "kind", "max_stacks", "min_act", "requires_tag_count", "weight"]
# Small counts the text uses as words ("a", "one", "1 leaf") match any field; numbers at most this are not flagged
const SMALL := 1.0

static func load_cards() -> Array[UpgradeData]:
	var out: Array[UpgradeData] = []
	for dir in CARD_DIRS:
		for file in DirAccess.get_files_at(dir):
			var name := file.trim_suffix(".remap")
			if name.ends_with(".tres"):
				var card := load(dir + name) as UpgradeData
				if card != null:
					out.append(card)
	out.sort_custom(func(a: UpgradeData, b: UpgradeData) -> bool: return a.id < b.id)
	return out

# {name: value} for every numeric (int / float) field of `card` that differs from a fresh UpgradeData's.
static func numeric_fields(card: UpgradeData) -> Dictionary:
	var blank := UpgradeData.new()
	var out := {}
	for prop in card.get_property_list():
		if not (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		if prop.type != TYPE_INT and prop.type != TYPE_FLOAT:
			continue
		var value = card.get(prop.name)
		if value != blank.get(prop.name):
			out[prop.name] = value
	return out

# The Need fields of `card` that are set: "requires=[a, b]; min_obstacles=8"…
static func needs_text(card: UpgradeData) -> String:
	var blank := UpgradeData.new()
	var bits: Array[String] = []
	for prop in card.get_property_list():
		if not (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var n: String = prop.name
		if not (n.begins_with("requires") or n.begins_with("min_") or n.begins_with("needs") or n == "deepens" or n == "entwined"):
			continue
		var value = card.get(n)
		if value != blank.get(n) and not (value is Array and value.is_empty()):
			bits.append("%s=%s" % [n, value])
	return "; ".join(bits)

# --- Rule constants from the code --------------------------------------------------------------------------

# Every `const NAME := value` in scripts/: {NAME: "value text"} (first declaration wins).
static func code_constants() -> Dictionary:
	var consts := {}
	var const_re := RegEx.create_from_string("^\\s*const\\s+([A-Z][A-Z0-9_]*)\\s*(?::[^=]*)?:?=\\s*(.+?)\\s*(?:#.*)?$")
	for path in _scripts():
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		for line in file.get_as_text().split("\n"):
			var c := const_re.search(line)
			if c != null and not consts.has(c.get_string(1)):
				consts[c.get_string(1)] = c.get_string(2)
	return consts

# The constants for `card`'s rules: those used on the lines naming its rule id or extra rules (`by_rule`, from
# rule_constants), plus every constant named after them (RULE_ID or RULE_ID_*: HERD_*, PULL_UNDER_*, FURY_*…).
static func constants_for(card: UpgradeData, by_rule: Dictionary, consts: Dictionary) -> Dictionary:
	var out := {}
	for rule in [card.rule_id] + Array(card.extra_rules):
		var id := String(rule)
		if id == "":
			continue
		out.merge(by_rule.get(id, {}))
		var prefix := id.to_upper()
		for name in consts:
			if name == prefix or String(name).begins_with(prefix + "_"):
				out[name] = consts[name]
	return out

# {rule id: {CONST: "value text"}} for every rule id named in the code, with the constants used on those lines.
static func rule_constants() -> Dictionary:
	var consts := {}  # NAME -> value text (first declaration wins)
	var lines_by_rule := {}  # rule -> [line text]
	var const_re := RegEx.create_from_string("^\\s*const\\s+([A-Z][A-Z0-9_]*)\\s*(?::[^=]*)?:?=\\s*(.+?)\\s*(?:#.*)?$")
	var rule_re := RegEx.create_from_string("&\"([a-z0-9_]+)\"")
	for path in _scripts():
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		for line in file.get_as_text().split("\n"):
			var c := const_re.search(line)
			if c != null and not consts.has(c.get_string(1)):
				consts[c.get_string(1)] = c.get_string(2)
			for m in rule_re.search_all(line):
				var rule := m.get_string(1)
				if not lines_by_rule.has(rule):
					lines_by_rule[rule] = []
				lines_by_rule[rule].append(line)
	var name_re := RegEx.create_from_string("\\b([A-Z][A-Z0-9_]{2,})\\b")
	var out := {}
	for rule in lines_by_rule:
		var used := {}
		for line in lines_by_rule[rule]:
			for m in name_re.search_all(String(line).split("#")[0]):
				var name := m.get_string(1)
				if consts.has(name):
					used[name] = consts[name]
		out[rule] = used
	return out

static func _scripts() -> Array[String]:
	var out: Array[String] = []
	var stack: Array[String] = CODE_DIRS.duplicate()
	while not stack.is_empty():
		var dir: String = stack.pop_back()
		for sub in DirAccess.get_directories_at(dir):
			stack.append(dir + sub + "/")
		for file in DirAccess.get_files_at(dir):
			if file.ends_with(".gd"):
				out.append(dir + file)
	return out

# Every number a Warden's TowerData holds: its int / float fields and the numbers in its dictionaries (special_params).
static func warden_numbers(data: TowerData) -> Array[float]:
	var out: Array[float] = []
	for prop in data.get_property_list():
		if not (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var value = data.get(prop.name)
		if value is int or value is float:
			out.append(float(value))
		elif value is Dictionary or value is Array:
			out.append_array(numbers_in(str(value)))
	return out

# Warden fields that are art or bookkeeping, never a number a grow card quotes.
const NOT_WARDEN_NUMBER := ["frame_count", "attack_frame_count", "attack_release_frame", "tier", "footprint", "sprite_offset",
	"attack_origin", "evolve_cost", "cost", "order"]

# A grow / unlock card's numbers typed by hand that its Warden's own fields carry (text_pass.md 797758fe: they drift when
# the Warden changes): each should be a {field:<id>.<field>[:format]} token. Small counts (≤ SMALL) are words, not flagged.
static func typed_warden_numbers(card: UpgradeData) -> Array[String]:
	var data := card.unlocks
	if data == null:
		return []
	var values: Array[float] = []
	var defaults := TowerData.new()  # Only the fields this Warden sets (a default it never uses is no claim)
	for prop in data.get_property_list():
		if not (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) or NOT_WARDEN_NUMBER.has(prop.name) \
				or "frame" in prop.name or "fps" in prop.name or prop.name.ends_with("kind"):
			continue
		var value = data.get(prop.name)
		if (value is int or value is float) and absf(float(value)) > 0.0 and value != defaults.get(prop.name):
			values.append_array(forms_of(float(value)))
	var out: Array[String] = []
	var text := RegEx.create_from_string("\\{[^}]*\\}").sub(card.description, "", true)
	for m in RegEx.create_from_string("\\d+(?:\\.\\d+)?").search_all(text):
		var n := float(m.get_string())
		if n > SMALL and values.any(func(v: float) -> bool: return is_equal_approx(v, n)):
			out.append(m.get_string())
	return out

# Every number in a constant's value text ("0.25", "[0.30, 0.50]", "{1: 2}").
static func numbers_in(text: String) -> Array[float]:
	var out: Array[float] = []
	for m in RegEx.create_from_string("-?\\d+(?:\\.\\d+)?").search_all(text):
		out.append(float(m.get_string()))
	return out

# --- The number check ---------------------------------------------------------------------------------------

# The numbers a description states ("25%", "0.5", "3 s", "×2"), {text} tokens and the card's own name left out.
static func text_numbers(card: UpgradeData) -> Array[String]:
	var text := RegEx.create_from_string("\\{[^}]*\\}").sub(card.description, "", true)
	text = text.replace(card.display_name, "")
	var out: Array[String] = []
	for m in RegEx.create_from_string("[×x]?\\d+(?:\\.\\d+)?%?").search_all(text):
		var s := m.get_string()
		if s.begins_with("x") and not s.substr(1).is_valid_float() and not s.ends_with("%"):
			continue
		out.append(s)
	return out

# The values a number in the text could stand for, from a field or constant value `v`: itself, as a percent
# (0.25 ↔ 25%), as a multiplier's bonus (1.25 ↔ 25%, 0.8 ↔ 20% less) and its inverse share (0.75 ↔ 25% less).
static func forms_of(v: float) -> Array[float]:
	return [v, v * 100.0, absf(v - 1.0) * 100.0, (1.0 - v) * 100.0, absf(v)]

# The text's numbers that match no field (or, with `constants`, no rule constant either). "" = all matched.
static func unmatched(card: UpgradeData, constants: Dictionary = {}) -> Array[String]:
	var values: Array[float] = []
	var fields := numeric_fields(card)
	for name in fields:
		if not NOT_EFFECT.has(name):
			values.append(float(fields[name]))
	for name in constants:
		values.append_array(numbers_in(String(constants[name])))
	if card.unlocks != null:  # An unlock card quotes its Warden's own numbers (Beacon's +35%, Elder Stump's 20%…)
		values.append_array(warden_numbers(card.unlocks))
	if card.max_stacks > 1:  # "(stacks, up to +45%)": each value at every copy
		for v in values.duplicate():
			values.append(v * card.max_stacks)
	var out: Array[String] = []
	for s in text_numbers(card):
		var n := float(s.trim_prefix("×").trim_prefix("x").trim_suffix("%"))
		if n <= SMALL:
			continue
		var hit := false
		for v in values:
			for f in forms_of(v):
				if absf(f - n) <= maxf(0.011 * n, 0.011):
					hit = true
		if not hit:
			out.append(s)
	return out

# text_style.md "Card wording, one way each" (e2176ea3): the wording breaks in `text` ([] = none). Distances in cells
# ("within 2 cells"; path squares stay "path tiles"), "up to" never "max", Warden bonuses as verbs ("deal 30% more
# damage", "attack 20% faster"; "+0.5 range" and nightmares' "take X% more" stay).
static func wording_breaks(text: String) -> Array[String]:
	var out: Array[String] = []
	var rules := [
		["\\b(within|reach(?:es)?|cover|over) \\d+(?:\\.\\d+)? tiles?\\b|\\b\\d+(?:\\.\\d+)? tiles? (away|further|around)\\b", "a distance in tiles (cells)"],
		["\\(max \\+", "\"(max +\" (up to)"],
		["\\+\\d+(?:\\.\\d+)?% (damage|attack speed)\\b", "\"+N% damage / attack speed\" (deal N% more damage / attack N% faster)"],
	]
	for rule in rules:
		var m := RegEx.create_from_string(rule[0]).search(text)
		if m != null:
			out.append("%s: \"%s\"" % [rule[1], m.get_string()])
	return out

# A stacking card says so: "(stacks)" without a limit, "(stacks, up to …)" with one; a one-copy card never says "(stacks".
static func stacking_break(card: UpgradeData) -> String:
	var says := card.description.contains("(stacks")
	if card.max_stacks == 1:
		return "a one-copy card says it stacks" if says else ""
	if not says:
		return "a stacking card (max_stacks %d) doesn't say \"(stacks…)\"" % card.max_stacks
	if card.max_stacks > 1 and not card.description.contains("(stacks, up to"):
		return "a stacking card with a limit (%d) needs \"(stacks, up to …)\"" % card.max_stacks
	return ""

# An unlock card stating a Dew price by hand ("(120 Dew)") instead of {grow_cost:id} / {plant_cost:id} (they went stale).
static func has_written_price(card: UpgradeData) -> bool:
	if card.kind != UpgradeData.Kind.UNLOCK_EVOLUTION and card.kind != UpgradeData.Kind.UNLOCK_WARDEN:
		return false
	return RegEx.create_from_string("\\(\\+?\\d+ Dew").search(card.description) != null  # Prices sit in brackets; "gives 10 Dew" is an effect

# A stat-field card: no rule id, at least one effect number in its fields (the test's scope).
static func is_stat_card(card: UpgradeData) -> bool:
	if card.rule_id != &"" or not card.extra_rules.is_empty():
		return false
	for name in numeric_fields(card):
		if not NOT_EFFECT.has(name):
			return true
	return false

# --- The CSV ------------------------------------------------------------------------------------------------

# Cards whose flagged numbers Roguelite Mechanic Discussion checked by hand against the code and found correct
# (card_text_audit.md "Verified by hand and correct", 2026-10-02). "X / II" covers both. The CSV says "verified".
const VERIFIED_ON := "2026-10-02"
const VERIFIED := ["Bitter Hedges", "Briar Crown", "Canopy", "Chosen Few", "Cozy Corners / II", "Crossroads", "Crowd Breaker",
	"In the Thick / II", "Soaked Rot", "Dawnbreak", "Deep Stillness", "Deep Water / II", "Deeper Rings", "Desperate Bloom",
	"Endless Night", "Endless Rings", "Falling Stars", "Fever Pitch", "Few and Mighty", "Glimmering Hunt", "Grandfather Stump",
	"Heavy Eyelids", "Hedge Maze / II", "Kindred Roots / II", "Last Stand", "Loose Stones", "Lucid Dreaming", "Overflowing Well",
	"Quick Reactions", "Reclaimed Earth", "Impatient Night", "Ricochet / II", "Rolling Thunder / II", "Scarred Bark / II",
	"Second Wind", "Seed Storm", "Seeping / II", "Shattering Blow / II", "Solitude", "Thicket", "Static Field II",
	"Straightaway / II", "Sweet Harmony", "The Long Walk", "Thinning the Herd", "Thousand Cuts", "Twin Puff II",
	"Watchful Rest / II", "Whirlwind Heart", "Wildfire Spores", "Wildwood Reclaimed", "Bad Dreams II", "Bramble Oath"]

static func is_verified(card: UpgradeData) -> bool:
	for entry: String in VERIFIED:
		var base := entry.trim_suffix(" / II")
		if card.display_name == base or (entry.ends_with(" / II") and card.display_name == base + " II"):
			return true
	return false

const COLUMNS: Array[String] = ["id", "display_name", "rarity", "max_stacks", "deepens", "min_act", "in_start_pool", "tags",
	"needs", "rule_id", "description", "cost_description", "fields", "rule_constants", "number_check"]

static func csv_rows() -> Array[PackedStringArray]:
	var rules := rule_constants()
	var consts := code_constants()
	var rows: Array[PackedStringArray] = [PackedStringArray(COLUMNS)]
	for card in load_cards():
		var fields := numeric_fields(card)
		var field_text: Array[String] = []
		for name in fields:
			field_text.append("%s=%s" % [name, fields[name]])
		var constants := constants_for(card, rules, consts)
		var const_text: Array[String] = []
		for name in constants:
			const_text.append("%s=%s" % [name, constants[name]])
		var missing := unmatched(card, constants)
		rows.append(PackedStringArray([card.id, card.display_name, UpgradeData.Rarity.keys()[card.rarity].to_lower(),
			str(card.max_stacks), card.deepens, str(card.min_act), str(card.in_start_pool), ", ".join(card.tags),
			needs_text(card), String(card.rule_id), card.description, card.cost_description, "; ".join(field_text),
			"; ".join(const_text), _check_text(card, missing)]))
	return rows

# The number_check cell: "ok", "verified 2026-10-02 (… by hand)" or "unmatched: …".
static func _check_text(card: UpgradeData, missing: Array[String]) -> String:
	if missing.is_empty():
		return "ok"
	if is_verified(card):
		return "verified %s (by hand: %s)" % [VERIFIED_ON, ", ".join(missing)]
	return "unmatched: " + ", ".join(missing)

static func to_csv(rows: Array[PackedStringArray]) -> String:
	var lines: Array[String] = []
	for row in rows:
		var cells: Array[String] = []
		for cell in row:
			var text := String(cell).replace("\n", " ")
			if text.contains(",") or text.contains("\"") or text.contains(";"):
				text = "\"" + text.replace("\"", "\"\"") + "\""
			cells.append(text)
		lines.append(",".join(cells))
	return "\n".join(lines) + "\n"
