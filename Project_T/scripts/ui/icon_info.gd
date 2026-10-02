extends RefCounted
class_name IconInfo

# One place for the names and plain-words tooltips of every status, Warden stat and resource
# (screens_ui.md "Stat and status icons": every icon explains itself on hover and on tap). Status
# display names can change (they did: Static became Charged), so every screen reads them here:
# status_name(id), status_tooltip(id), stat_tooltip(id), resource_tooltip(id). Icons from Tower
# Assets' sheet: icon(id) / make_icon(id, scale) (the sheet's ids; "elite" maps to deeply_blighted).

# Display names (story.md "Status display names", screens_ui.md): the code ids never change, only
# these names. Text anywhere can say {damp} / {static} …; format() puts in the current names, and
# StatusLinks turns them into links.
const STATUSES := {
	&"damp": ["Soaked", "Water hits deal 20% more. Lightning jumps farther between {damp} nightmares."],
	&"drowsy": ["Drowsy", "8% slower per stack. At full stacks it's {asleep}."],
	&"spored": ["Poisoned", "Poison eats at it over time, more with every stack."],
	&"marked": ["Exposed", "Takes 25% more from every Warden."],
	&"static": ["Charged", "At 5 stacks (8 on bosses) it releases a bolt: 3× its charge as damage. Some Wardens release it sooner."],
	&"held": ["Rooted", "Can't move for a moment."],
	&"asleep": ["Asleep", "Stopped for 3 s, long but fragile: a big hit (10%+ of its health) wakes it."],
	&"caught": ["Caught", "{asleep} or fully {drowsy} near a Dreamcatcher: its statuses stop wearing off."],
	&"frozen": ["Frozen", "Frost stops it for a moment."],
	&"elite": ["Deeply Blighted", "An elite: 3× health, 2× Dew, and it takes 2 leaves."],
	&"hidden": ["Hidden", "Can't be seen or targeted until something reveals it, or it comes close."],
}
const STATS := {
	&"damage": ["Damage", "How much each hit deals."],
	&"attack_speed": ["Attack speed", "Attacks per second."],
	&"range": ["Range", "How far it reaches, in tiles."],
	&"crit_chance": ["Crit chance", "The chance a hit is a critical hit."],
	&"crit_damage": ["Crit damage", "How much harder a critical hit lands."],
	&"potency": ["Potency", "Effect damage: scales status and poison damage and Reactions."],
	&"rank": ["Rank", "How nurtured it is (I–V): each rank adds damage, speed and range."],
	&"focus": ["Focus", "Chosen at rank III: Power, Swift, Reach or Deep."],
	&"focus_power": ["Power focus", "+8% damage."],
	&"focus_swift": ["Swift focus", "+6% attack speed."],
	&"focus_reach": ["Reach focus", "+0.2 range."],
	&"focus_deep": ["Deep focus", "+10% status strength and duration."],
	&"dew_cost": ["Dew cost", "Dew to plant, grow or nurture it."],
	&"dreamlight_cost": ["Dreamlight cost", "Dreamlight to unlock this form for the run."],
}
const RESOURCES := {
	&"dew": ["Dew", "Spent on Wardens, growth, Nurture and clearing. Earned by dispelling nightmares and at rests."],
	&"dreamlight": ["Dreamlight", "Unlocks branches, final forms and Ascended forms on the Remember screen (at rests)."],
	&"leaves": ["Leaves", "The Heartwood's life: a nightmare that reaches it takes leaves. Lose them all and the dream goes dark."],
	&"seeds": ["Seeds", "Earned every run, win or lose; spent in the Memory Grove."],
	&"path": ["Path length", "How many tiles nightmares walk to the Heartwood. Longer is better."],
}

# Damage types (enemy_design.md "Damage types"): what nightmares resist or fear, shown everywhere as a
# type icon + name, never a Warden's face. TowerData.line -> [name, colour (icon fallback)]. Any other
# line (sprout, wall, acorn, memory, heartwood) is Plain: never resisted, never weak.
const DAMAGE_TYPES := {
	"spore": ["Spore", UiStyle.LIVE],
	"stone": ["Stone", UiStyle.INK_DIM],
	"water": ["Water", Palette.DEWLIGHT],
	"light": ["Light", UiStyle.GOLD],
	"root": ["Root", Palette.DEADWOOD],
	"song": ["Song", Palette.BLOSSOM],
	"wing": ["Talon", Palette.GOLD],
	"wind": ["Wind", UiStyle.MOONLIGHT],
}
const PLAIN_TYPE := ["Plain", UiStyle.OFF]

static func damage_type_name(line: String) -> String:
	return DAMAGE_TYPES.get(line, PLAIN_TYPE)[0]

static func damage_type_color(line: String) -> Color:
	return DAMAGE_TYPES.get(line, PLAIN_TYPE)[1]

# "Light damage" for a Warden (its TowerData.line).
static func damage_type_text(line: String) -> String:
	return "%s damage" % damage_type_name(line)

# The type's icon from the sheet ("damage_type" group: spore … wind, plain; "wing" = Talon), or null
# while the art isn't in (callers draw a coloured disc with the initial).
static func damage_type_icon(line: String) -> Texture2D:
	return icon(StringName(line if DAMAGE_TYPES.has(line) else "plain"))

# --- Icons (assets/ui/icons.png, one row of 16×16; icons.json maps id -> column) -------------------

const ICON_SHEET := "res://assets/ui/icons.png"
const ICON_MANIFEST := "res://assets/ui/icons.json"
# HUD-size icons (UI Asset, hud_icons.json): 12 px counters and 10 px button glyphs, drawn for exactly ×2.
const HUD_MANIFEST := "res://assets/ui/hud_icons.json"
static var _hud_sets := {}  # Parsed hud_icons.json (plain data)

# A HUD icon by id ("dew_hud", "menu_hud"…) from its set's sheet, or null. `frame_size` gives its pixel size.
static func hud_icon(id: StringName) -> Texture2D:
	if _hud_sets.is_empty():
		var data = JSON.parse_string(FileAccess.get_file_as_string(HUD_MANIFEST)) if FileAccess.file_exists(HUD_MANIFEST) else null
		_hud_sets = data if data is Dictionary else {"_": {}}
	for set_name in _hud_sets:
		var entry = _hud_sets[set_name]
		if not entry is Dictionary or not entry.get("icons", {}).has(String(id)):
			continue
		var sheet := "res://assets/ui/" + String(entry.image)
		if not ResourceLoader.exists(sheet):
			return null
		var frame := int(entry.frame_size)
		var atlas := AtlasTexture.new()
		atlas.atlas = load(sheet)
		atlas.region = Rect2(int(entry.icons[String(id)]) * frame, 0, frame, frame)
		return atlas
	return null
const ICON_ALIASES := {&"elite": &"deeply_blighted"}  # IconInfo id -> sheet id
static var _columns := {}
static var _frame := 16

# The 16×16 icon for a status or stat id (null if the sheet has none, e.g. combos: never).
# Scale it by whole numbers with nearest filtering (TextureRect.texture_filter = NEAREST).
static func icon(id: StringName) -> Texture2D:
	if _columns.is_empty():
		_load_manifest()
	var key := String(ICON_ALIASES.get(id, id))
	if not _columns.has(key) or not ResourceLoader.exists(ICON_SHEET):
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = load(ICON_SHEET)
	atlas.region = Rect2(int(_columns[key]) * _frame, 0, _frame, _frame)
	return atlas

static func _load_manifest() -> void:
	if not FileAccess.file_exists(ICON_MANIFEST):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(ICON_MANIFEST))
	if data is Dictionary:
		_frame = int(data.get("frame_size", 16))
		_columns = data.get("icons", {})

# A TextureRect showing `id`'s icon at `scale` × 16 px (crisp), explaining itself on hover and tap.
static func make_icon(id: StringName, scale: int = 1) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = icon(id)
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(16, 16) * scale
	var tip := status_tooltip(id)
	if tip == "":
		tip = stat_tooltip(id)
	if tip != "":
		TapTip.attach(rect, tip)
	return rect

static func status_name(id: StringName) -> String:
	return STATUSES[id][0] if STATUSES.has(id) else String(id).capitalize()

static func status_tooltip(id: StringName) -> String:
	return _tip(STATUSES, id)

static func stat_tooltip(id: StringName) -> String:
	return _tip(STATS, id)

static func resource_tooltip(id: StringName) -> String:
	return _tip(RESOURCES, id)

# "Soaked: 10% slower. …" (a sheet id like deeply_blighted finds its IconInfo entry, elite).
static func _tip(table: Dictionary, id: StringName) -> String:
	if not table.has(id):
		for key in ICON_ALIASES:
			if ICON_ALIASES[key] == id:
				id = key
	return format("%s: %s" % table[id]) if table.has(id) else ""

# Game terms (screens_ui.md "Playtest fixes" 2026-09-30: "what's a perfect block, what's a block?"):
# written as tokens in card text and tooltips, shown as links (StatusLinks) whose popup is the Codex
# glossary's line. id -> [word, plural, glossary name, plural token id (optional; default id + "s")]. Tokens: {drift} "drift", {drifts} "drifts",
# {Drift} / {Drifts} capitalised (sentence starts). Plain text (format) just gets the word.
const TERMS := {
	&"drift": ["drift", "drifts", "Drift"],
	&"block": ["block", "blocks", "Block"],
	&"rest": ["rest", "rests", "Rest"],
	&"perfect_block": ["perfect block", "perfect blocks", "Perfect block"],
	&"dreamlight": ["Dreamlight", "Dreamlight", "Dreamlight"],
	&"family_pick": ["family pick", "family picks", "Family pick"],
	&"deeply_blighted": ["Deeply Blighted", "Deeply Blighted", "Deeply Blighted"],
	&"dread_shell": ["dread shell", "dread shells", "Dread shell"],
	&"kinship": ["Kinship", "Kinships", "Kinship"],
	&"harmony": ["Harmony strike", "Harmony strikes", "Harmony strike", "harmonies"],  # {harmonies}: the plural
}

# Every term token form: [token text, term id, word shown]. Longest tokens first.
static func term_tokens() -> Array:
	if _term_tokens.is_empty():
		for id in TERMS:
			var entry: Array = TERMS[id]
			var plural_id: String = entry[3] if entry.size() > 3 else String(id) + ("s" if not String(id).ends_with("s") else "")
			for form in [[String(id), entry[0]], [plural_id, entry[1]]]:
				_term_tokens.append(["{%s}" % form[0], id, form[1]])
				_term_tokens.append(["{%s}" % _upper_first(form[0]), id, _upper_first(form[1])])
		_term_tokens.sort_custom(func(a: Array, b: Array) -> bool: return a[0].length() > b[0].length())
	return _term_tokens
static var _term_tokens: Array = []

static func _upper_first(s: String) -> String:
	return s.left(1).to_upper() + s.substr(1)

# A name as it reads mid-sentence (text_style.md): a leading "The" is lowercase ("About the Mire
# Hag"); at a line start or on a name plate use the name as is.
static func name_in_sentence(name: String) -> String:
	return "the " + name.substr(4) if name.begins_with("The ") else name

# "the X" for a nightmare in a sentence, whether or not its name carries "The"; `start` capitalises it.
static func the_name(name: String, start := false) -> String:
	var text := name_in_sentence(name)
	if not text.begins_with("the "):
		text = "the " + text
	return _upper_first(text) if start else text

# Puts the current status names and term words into `text`: "{damp} + {static}" -> "Soaked +
# Charged", "each {block}" -> "each block". Unknown tokens stay as they are.
static func format(text: String) -> String:
	if not text.contains("{"):
		return text
	for id in STATUSES:
		text = text.replace("{%s}" % id, STATUSES[id][0])
	for token in term_tokens():
		text = text.replace(token[0], token[2])
	if text.contains("{family:"):
		for found in family_pattern().search_all(text):
			var data := family_data(found.get_string(1))
			text = text.replace(found.get_string(), data.display_name if data != null else found.get_string(1).capitalize())
	if text.contains("{combo:"):  # A combo (or Crowned Reaction): its name, or ??? until discovered
		for found in _combo_pattern().search_all(text):
			var id := StringName(found.get_string(1))
			var combo := CodexData.get_any(id)
			text = text.replace(found.get_string(), combo.get("name", "???") if not combo.is_empty() and CodexData.is_discovered(id) else "???")
	return text

static var _combo_regex: RegEx = null
static func _combo_pattern() -> RegEx:
	if _combo_regex == null:
		UiStyle.release_at_exit(func() -> void: _combo_regex = null)
		_combo_regex = RegEx.create_from_string("\\{combo:([a-z_]+)\\}")
	return _combo_regex

# Family names as links (screens_ui.md "remove Half-dreamed"): "{family:dewdrop}" is the family's
# name, a link (StatusLinks) whose popup is its emblem, damage type and identity.
static var _family_pattern: RegEx = null
static func family_pattern() -> RegEx:
	if _family_pattern == null:
		UiStyle.release_at_exit(func() -> void: _family_pattern = null)
		_family_pattern = RegEx.create_from_string("\\{family:([a-z_]+)\\}")
	return _family_pattern

# The family's base Warden (resource/tower/<id>.tres), or null.
static func family_data(id: String) -> TowerData:
	var path := "res://resource/tower/%s.tres" % id
	return load(path) as TowerData if ResourceLoader.exists(path) else null

# The status id for a display name ("Soaked" -> &"damp"), or &"" (StatusLinks uses it).
static func status_id(name: String) -> StringName:
	for id in STATUSES:
		if STATUSES[id][0].to_lower() == name.to_lower():
			return id
	return &""
