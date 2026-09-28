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
	&"damp": ["Soaked", "10% slower. Lightning jumps further between {damp} nightmares."],
	&"drowsy": ["Drowsy", "8% slower per stack. At full stacks it's {asleep}."],
	&"spored": ["Poisoned", "Poison eats at it over time, more with every stack."],
	&"marked": ["Exposed", "Takes 25% more from every Warden."],
	&"static": ["Charged", "Charges build up; at 5, a free lightning bolt strikes it."],
	&"held": ["Rooted", "Can't move for a moment."],
	&"asleep": ["Asleep", "Fully {drowsy}: it stops moving until it wakes."],
	&"caught": ["Caught", "{asleep} or fully {drowsy} near a Dreamcatcher: takes extra damage from everything."],
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
	"spore": ["Spore", Color(0.72, 0.86, 0.45)],
	"stone": ["Stone", Color(0.72, 0.7, 0.66)],
	"water": ["Water", Color(0.45, 0.72, 1.0)],
	"light": ["Light", Color(1.0, 0.9, 0.45)],
	"root": ["Root", Color(0.7, 0.52, 0.34)],
	"song": ["Song", Color(0.85, 0.65, 1.0)],
	"wing": ["Talon", Color(0.95, 0.62, 0.45)],
	"wind": ["Wind", Color(0.7, 0.95, 0.9)],
}
const PLAIN_TYPE := ["Plain", Color(0.75, 0.75, 0.75)]

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

# Puts the current status names into `text`: "{damp} + {static}" -> "Soaked + Charged". Unknown
# tokens stay as they are.
static func format(text: String) -> String:
	if not text.contains("{"):
		return text
	for id in STATUSES:
		text = text.replace("{%s}" % id, STATUSES[id][0])
	return text

# The status id for a display name ("Soaked" -> &"damp"), or &"" (StatusLinks uses it).
static func status_id(name: String) -> StringName:
	for id in STATUSES:
		if STATUSES[id][0].to_lower() == name.to_lower():
			return id
	return &""
