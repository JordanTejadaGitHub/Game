extends RefCounted
class_name IconInfo

# One place for the names and plain-words tooltips of every status, Warden stat and resource
# (screens_ui.md "Stat and status icons": every icon explains itself on hover and on tap). Status
# display names can change (they did: Static became Charged, then Charge), so every screen reads them here:
# status_name(id), status_tooltip(id), stat_tooltip(id), resource_tooltip(id). Icons from Tower
# Assets' sheet: icon(id) / make_icon(id, scale) (the sheet's ids; "elite" maps to deeply_blighted).

# Display names (story.md "Status display names", screens_ui.md): the code ids never change, only
# these names. Text anywhere can say {damp} / {static} …; format() puts in the current names, and
# StatusLinks turns them into links.
# The six buildup statuses name {reactions} (a glossary link, user 2026-10-12: "the wet tutorial card should have the
# underline explaining reactions") and read their stack numbers live ({stacks:need_damp} …: stack_number, below), so
# Brimming's doubling shows.
const STATUSES := {
	# Nouns since 2026-10-17 (owner: "rename all"; they match the keyword chips and read as stack counts: "8 Soak"). Text
	# says "nightmares with {damp}", never "{damp} nightmares".
	&"damp": ["Soak", "Water hits deal 20% more damage to a nightmare with it. At {stacks:need_damp} stacks it can set off {reactions}."],
	&"drowsy": ["Sleep", "A nightmare with it walks 2% slower per stack. At {stacks:cap_drowsy} stacks ({stacks:bosscap_drowsy} on bosses) the nightmare can fall {asleep} and set off {reactions}."],
	&"spored": ["Poison", "A nightmare with it takes damage every second, more per stack. Every new stack keeps the whole pile going; it wears off 5 s after the last one. At {stacks:need_spored} stacks it can set off {reactions}."],
	&"marked": ["Exposure", "Does nothing until {stacks:need_marked} stacks; then a nightmare with it takes 25% more damage from every Warden and can set off {reactions}."],
	&"static": ["Charge", "Lightning built up on a nightmare. At {stacks:cap_static} stacks ({stacks:bosscap_static} on bosses) it goes off as a strong bolt (16× the stored Charge). At {stacks:need_static} stacks it can set off {reactions}."],
	&"held": ["Root", "Builds up to {stacks:cap_held} stacks; a nightmare with Root can't move while it lasts. At {stacks:need_held} stacks it can set off {reactions}."],
	&"asleep": ["Asleep", "Stopped for 3 s, long but fragile: a big hit (10%+ of its health) wakes it."],
	&"caught": ["Caught", "{asleep}, or at {full} {drowsy}, near a Dreamcatcher: its statuses stop wearing off."],
	&"frozen": ["Frozen", "Frost stops it for a moment."],
	&"elite": ["Deeply Blighted", "A stronger nightmare: 3× health, a triple share of the Dew, and it takes 2 leaves."],
	&"hidden": ["Hidden", "Can't be seen or targeted until something reveals it, or it comes close."],
	# Hushbell's silence (BranchKit.silence; EnemyStatuses.silence_time): the numbers are checked against the data in
	# test_text_style (Silence's linger, the Vespers toll, Enemy.BOSS_SILENCE_SPEED).
	# User: "Silenced still doesn't make sense from the Codex": what it does first, the edge cases after.
	&"silenced": ["Silenced", "It can't use its abilities. A Watcher can't wake, a Weeper can't heal, and a Lantern Bearer's lantern goes dark, so its Wraiths lose their way. Bosses still fight, but their timed abilities come at half speed.\nLasts while a Hushbell's song reaches it. A Silence (Hushbell's next form) or a Vespers toll keeps it 2 s longer."],
}
const STATS := {
	&"damage": ["Damage", "How much each hit deals."],
	&"attack_speed": ["Attack speed", "Attacks per second."],
	&"range": ["Range", "How far it attacks, in cells."],
	&"crit_chance": ["Crit chance", "The chance a hit is a critical hit."],
	&"crit_damage": ["Crit damage", "How much harder a critical hit lands."],
	&"potency": ["Potency", "How strong this Warden's statuses are. Higher Potency: harder {spored} and {static}, stronger slows, longer {held}. Raise it with the Deep choice."],
	&"rank": ["Rank", "How nurtured it is (I and up; past V with the Eldest). Each rank adds damage and attack speed, and you choose one improvement."],
	&"focus": ["Nurture choice", "Each rank you choose one improvement. Attacking Wardens: Power, Swift, Reach or Deep. Support Wardens have their own."],
	&"focus_power": ["Power", "Hits harder: deals 18% more damage."],
	&"focus_swift": ["Swift", "Attacks faster: +12%."],
	&"focus_reach": ["Reach", "More range: +0.3 cells."],
	&"focus_deep": ["Deep", "Stronger statuses: +25% Potency."],
	&"dew_cost": ["Dew cost", "Dew to plant, grow or nurture it."],
	&"dreamlight_cost": ["Dreamlight cost", "Dreamlight to unlock this form for the run."],
}
const RESOURCES := {
	&"dew": ["Dew", "Spent on Wardens, growth, Nurture and clearing. Earned by dispelling nightmares and at rests."],
	&"dreamlight": ["Dreamlight", "Unlocks branches, final forms and Ascended forms on the Remember screen (open it any time; a drift pauses)."],
	&"leaves": ["Leaves", "The Heartwood's life: a nightmare that reaches the Heartwood takes leaves. Lose them all and the run ends."],
	&"seeds": ["Seeds", "Earned every run, win or lose; spent in the Memory Grove."],
	&"path": ["Path length", "How many cells the nightmares walk. Longer is better."],
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

# A Warden form's role and counters from its counter tags (TowerData.counter_tags, Tower Code): one place for the family
# pick's routes, the Codex Families page and the hover cards.
const COUNTER_WORDS := {&"anti_air": "flyers", &"anti_tank": "tanks", &"anti_armour": "armour", &"anti_swarm": "swarms",
	&"anti_support": "support nightmares", &"detection": "Hidden nightmares", &"boss_abilities": "boss abilities"}
const ROLE_WORDS := {&"anti_air": "hits flyers", &"anti_tank": "tank killer", &"anti_armour": "cracks armour",
	&"anti_swarm": "thins swarms", &"anti_support": "quiets support", &"detection": "reveals Hidden",
	&"boss_abilities": "answers bosses"}

static func _counter_tags(form: TowerData) -> Array:
	var tags = form.get("counter_tags") if form != null else null
	return tags if tags is Array else []

# A Warden's job when it counters nothing (TowerData.role_tag, Tower Code / Tower Discussion): the fallback role.
const ROLE_TAG_WORDS := {&"control": "holds the line", &"setup": "sets up combos", &"support": "strengthens Wardens",
	&"economy": "earns Dew"}

# Its role line (TowerData.role_line, tower_design.md "Role lines", Tower Code 7824a02e), else "tank killer, hits flyers"
# (the first two counter tags), else its role tag's words, else "".
static func role_text(form: TowerData) -> String:
	if form != null and form.role_line != "":
		return ("Heavy, " if form.heavy else "") + form.role_line  # The Heavy tag (Firefly class prototype): bar, panel, grow list
	var words: Array = _counter_tags(form).map(func(tag: StringName) -> String: return ROLE_WORDS.get(tag, "")).filter(func(w: String) -> bool: return w != "")
	if words.is_empty() and form != null:
		var tag = form.get("role_tag")
		if tag != null and ROLE_TAG_WORDS.has(StringName(tag)):
			return ROLE_TAG_WORDS[StringName(tag)]
		if tag != null and ROLE_WORDS.has(StringName(tag)):
			return ROLE_WORDS[StringName(tag)]  # A counter job named as a role only (it doesn't weight the branch draw)
	return ", ".join(words.slice(0, 2))

# A role line as points (user, 2026-10-07: "can you make it point form"): its comma-separated terms (test_role_lines: no
# comma inside a term), each with a capital first letter: ["Long range", "High damage", "Can't hit up close"].
static func role_terms(role: String) -> Array[String]:
	var terms: Array[String] = []
	for term in role.split(", ", false):
		term = term.strip_edges()
		if term != "":
			terms.append(term.left(1).to_upper() + term.substr(1))
	return terms

const ROLE_BULLET := "•"

# "• Long range\n• High damage": one point per line, where there's room (plain text: tips).
static func role_points(role: String) -> String:
	return "\n".join(role_terms(role).map(func(t: String) -> String: return ROLE_BULLET + " " + t))

# "Long range · High damage": inline, where space is tight.
static func role_inline(role: String) -> String:
	return " · ".join(role_terms(role))

# "Counters flyers, tanks", "" without tags.
static func counters_text(form: TowerData) -> String:
	var words: Array = _counter_tags(form).map(func(tag: StringName) -> String: return COUNTER_WORDS.get(tag, "")).filter(func(w: String) -> bool: return w != "")
	return "Counters " + ", ".join(words) if not words.is_empty() else ""

static func status_name(id: StringName) -> String:
	return STATUSES[id][0] if STATUSES.has(id) else String(id).capitalize()

static func status_tooltip(id: StringName) -> String:
	return _tip(STATUSES, id)

static func stat_tooltip(id: StringName) -> String:
	return _tip(STATS, id)

static func resource_tooltip(id: StringName) -> String:
	return _tip(RESOURCES, id)

# "Soak: water hits deal 20% more …" (a sheet id like deeply_blighted finds its IconInfo entry, elite).
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
	&"potency": ["Potency", "Potency", "Potency"],  # Also linked as a plain word (StatusLinks.PLAIN_TERMS: card text says "Potency")
	&"reaction": ["Reaction", "Reactions", "Reaction"],  # {reaction} / {reactions}: always a capital, always a link (user 2026-10-12); also a plain word
	# Branch effects of the 12 new branches (Tower Code's BranchKit; glossary "Branch effects"): {current}, {erosion}, …
	&"current": ["Current", "Currents", "Current"],
	&"erosion": ["Erosion", "Erosion", "Erosion"],
	&"arc": ["arc", "arcs", "Arc"],
	&"ink": ["ink", "ink", "Ink", "inks"],
	&"spore_sprite": ["spore-sprite", "spore-sprites", "Spore-sprite"],
	&"whole_tree": ["Whole Tree", "Whole Tree", "Whole Tree"],
	# Keywords are always links (text_pass.md "Keywords are always links", user 2026-10-13): every word with a meaning
	# special to this game has a token here and an entry in the Codex glossary (the third word is the entry's name).
	# {id} / {plural} / {Id} as above. StatusLinks.AUTO_TERMS lists the ones also linked as plain words.
	&"warden": ["Warden", "Wardens", "Warden"],
	&"nightmare": ["nightmare", "nightmares", "Nightmare"],
	&"heartwood": ["Heartwood", "Heartwood", "Heartwood"],
	&"dispel": ["dispel", "dispels", "Dispel"],
	&"sprout": ["Sprout", "Sprouts", "Sprout"],
	&"family": ["family", "families", "Family", "families"],
	&"grow": ["grow", "grows", "Grow"],
	&"branch": ["branch", "branches", "Branch", "branches"],
	&"final_form": ["final form", "final forms", "Final form"],
	&"grove_branch": ["Grove branch", "Grove branches", "Grove branch", "grove_branches"],
	&"ascended": ["Ascended", "Ascended", "Ascended", "ascendeds"],
	&"nurture": ["Nurture", "Nurture", "Nurture"],
	&"rank": ["rank", "ranks", "Rank"],
	&"nurture_choice": ["Nurture choice", "Nurture choices", "Nurture choice"],
	&"signature": ["signature", "signatures", "Signature"],
	&"mastery": ["Mastery", "Mastery", "Mastery", "masteries"],
	&"all_rounder": ["All-Rounder", "All-Rounder", "All-Rounder"],
	&"wide": ["Wide", "Wide", "Wide, Strong, Attuned", "wides"],
	&"strong": ["Strong", "Strong", "Wide, Strong, Attuned", "strongs"],
	&"attuned": ["Attuned", "Attuned", "Wide, Strong, Attuned", "attuneds"],
	&"eldest": ["Eldest", "Eldest", "Eldest", "eldests"],
	&"thornwall": ["Thornwall", "Thornwalls", "Thornwall"],
	&"stack": ["stack", "stacks", "Stack"],
	&"full": ["full", "full", "Full"],
	&"crowned_reaction": ["Crowned Reaction", "Crowned Reactions", "Crowned Reaction"],
	&"chain": ["Chain", "Chains", "Chain"],
	&"calling": ["Calling", "Callings", "Calling"],
	&"dream": ["Dream", "Dreams", "Dream"],
	&"rarity": ["rarity", "rarities", "Rarity", "rarities"],
	&"legendary": ["Legendary", "Legendaries", "Legendary", "legendaries"],
	&"bittersweet": ["Bittersweet", "Bittersweet", "Bittersweet"],
	&"upgrade": ["Upgrade", "Upgrades", "Upgrade"],
	&"woven": ["Woven", "Woven", "Woven"],
	&"new_cards": ["New cards", "New cards", "New cards", "new_cardss"],
	&"banish": ["Banish", "Banishes", "Banish", "banishes"],
	&"omen": ["Omen", "Omens", "Omen"],
	&"gift": ["gift", "gifts", "Gift"],
	&"act": ["act", "acts", "Act"],
	&"call_early": ["call early", "call early", "Call early", "call_earlys"],
	&"maze_bonus": ["Maze bonus", "Maze bonus", "Maze bonus"],
	&"catcher": ["catcher", "catchers", "Catcher"],
	&"interest": ["interest", "interest", "Interest"],
	&"aura": ["aura", "auras", "Aura"],
	&"crit": ["crit", "crits", "Crit"],
	&"critical_hit": ["critical hit", "critical hits", "Crit"],
	&"flyer": ["flyer", "flyers", "Flying"],
	# Nightmare Kinds (enemy_design.md ed6f573b): each links to its Kind's glossary entry (CodexData.kind_entries); the
	# Kind badge and the Warden tags that answer it (StatusLinks.ROLE_KIND_TERMS) link here.
	&"kind": ["Kind", "Kinds", "Nightmare Kind"],
	&"kind_armoured": ["Armoured", "Armoured", "Armoured", "kind_armoureds"],
	&"kind_flying": ["Flying", "Flying", "Flying", "kind_flyings"],
	&"kind_hidden": ["Hidden", "Hidden", "Hidden", "kind_hiddens"],
	&"kind_swarm": ["Swarm", "Swarms", "Swarm"],
	&"kind_fast": ["Fast", "Fast", "Fast", "kind_fasts"],
	&"kind_plain": ["Plain", "Plain", "Plain", "kind_plains"],
	&"restless": ["restless", "restless", "Restless", "restlesss"],
	&"remember": ["Remember", "Remember", "Remember screen"],
	&"memory_grove": ["Memory Grove", "Memory Grove", "Memory Grove"],
	&"node": ["node", "nodes", "Node"],
	&"perk": ["perk", "perks", "Perks"],
	&"blight_level": ["Blight Level", "Blight Levels", "Blight Levels"],
	&"memory": ["Memory", "Memories", "Memories", "memories"],
	&"dew": ["Dew", "Dew", "Dew", "dews"],
	&"seeds": ["Seeds", "Seeds", "Seeds", "seedss"],
	&"leaves": ["leaves", "leaves", "Leaves", "leavess"],
	&"leaf": ["leaf", "leaves", "Leaves", "leafs"],
	# The starter classes' words (Roguelite Code 2026-10-14; the council's "words still unclear" list): each links to its
	# glossary line under "Classes" (CodexData).
	&"mushroom": ["mushroom", "mushrooms", "Mushroom"],
	&"dose": ["dose", "doses", "Dose"],
	&"lit": ["Lit", "Lit", "Lit", "lits"],
	&"jump": ["jump", "jumps", "Jump"],
	&"water": ["water", "water", "Water", "waters"],
	&"toll": ["Toll", "Tolls", "Toll"],
	&"free_hit": ["free hit", "free hits", "Free hit"],
	&"heavy": ["heavy", "heavy", "Heavy Warden", "heavys"],
	&"step": ["step", "steps", "Step"],
	&"touching": ["touching", "touching", "Touching", "touchings"],
	&"near": ["near", "near", "Near", "nears"],
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

# Puts the current status names and term words into `text`: "{damp} + {static}" -> "Soak +
# Charge", "each {block}" -> "each block". Unknown tokens stay as they are.
# A status text's stack number, live (user 2026-10-12: never typed in): "need_<status>" = the stacks its Reactions
# need (Reactions' thresholds: the lowest one for that status), "cap_<status>" = its full buildup, "bosscap_<status>"
# = the same on a boss. All include Brimming's doubling (EnemyStatuses.cap_multiplier).
static func stack_number(key: String) -> int:
	var kind := key.get_slice("_", 0)
	var status := StringName(key.substr(kind.length() + 1))
	if kind == "need":
		var needs := {&"damp": Reactions.SOAKED_NEEDED, &"held": Reactions.ROOTED_NEEDED, &"marked": Reactions.EXPOSED_NEEDED,
			&"spored": Reactions.IGNITE_MIN_SPORES, &"static": Reactions.IGNITE_MIN_STATIC}
		return Reactions.need(int(needs.get(status, 0)))  # A Reaction's need: the normal amount, Brimming or not (owner 2026-10-16)
	if kind == "cap" or kind == "bosscap":
		var probe := EnemyStatuses.new()  # Its caps, as a nightmare (or a boss) carries them
		probe.is_boss = kind == "bosscap"
		return probe.get_max_stacks(status)
	return 0

static func format(text: String) -> String:
	if not text.contains("{"):
		return keep_units(text)
	for id in STATUSES:
		text = text.replace("{%s}" % id, STATUSES[id][0])
	for token in term_tokens():
		text = text.replace(token[0], token[2])
	while text.contains("{stacks:"):  # Live stack numbers: "{stacks:need_damp}" -> "8" (16 with Brimming)
		var from := text.find("{stacks:")
		var to := text.find("}", from)
		if to < 0:
			break
		text = text.substr(0, from) + str(stack_number(text.substr(from + 8, to - from - 8))) + text.substr(to + 1)
	if text.contains("{family:"):
		for found in family_pattern().search_all(text):
			var data := family_data(found.get_string(1))
			text = text.replace(found.get_string(), data.display_name if data != null else found.get_string(1).capitalize())
	if text.contains("{card:") or text.contains("{omen:") or text.contains("{warden:"):  # A Dream card, Omen or Warden: its name, plain
		for found in card_pattern().search_all(text):
			text = text.replace(found.get_string(), card_name(found.get_string(2), found.get_string(1)))
	if text.contains("{nightmare:"):  # A nightmare: its name, or ??? until met
		for found in nightmare_pattern().search_all(text):
			text = text.replace(found.get_string(), nightmare_name(found.get_string(1)))
	if text.contains("combo:"):  # A combo (or Crowned Reaction): its name, or ??? until discovered ({named_combo:x} always named)
		for found in _combo_pattern().search_all(text):
			var id := StringName(found.get_string(1))
			var combo := CodexData.get_any(id)
			var named := found.get_string().begins_with("{named_") or CodexData.is_discovered(id)  # A Dream card always names its combo
			text = text.replace(found.get_string(), combo.get("name", String(id).capitalize()) if named and not combo.is_empty() else "???")
	if text.contains("{echo:"):  # An echo Warden's echo_share, so a retune updates its texts: "75%", or "full"
		for found in _echo_pattern().search_all(text):
			text = text.replace(found.get_string(), echo_text(found.get_string(1)))
	if text.contains("{grow_cost:") or text.contains("{plant_cost:"):  # A Warden's Dew price from its TowerData (card text audit:
		for found in _cost_pattern().search_all(text):  # hand-written prices went stale)
			text = text.replace(found.get_string(), cost_text(found.get_string(1), found.get_string(2)))
	if text.contains("{pct:"):  # A Warden's share field as a percent: "{pct:beacon.marked_bonus}" -> "50%" (texts follow the data)
		for found in _pct_pattern().search_all(text):
			text = text.replace(found.get_string(), pct_text(found.get_string(1), found.get_string(2)))
	if text.contains("{field:"):  # Any Warden number: "{field:thunderhead.storm_every}", "{field:graftling.copy_share:pct}"
		for found in _field_pattern().search_all(text):
			text = text.replace(found.get_string(), field_text(found.get_string(1), found.get_string(2), found.get_string(3)))
	if text.contains("{dew:") or text.contains("{dreamlight:") or text.contains("{seeds:"):  # An amount: the icon and the number
		for found in _amount_pattern().search_all(text):
			text = text.replace(found.get_string(), amount_text(found.get_string(1), found.get_string(2)))
	return keep_units(text)

# "{dew:15}", "{dreamlight:+2}", "{seeds:30}" -> the resource's glyph and the number (UiStyle.dew_amount; user via
# Main Merger 2026-10-06: prices and rewards are the icon and the number, never "15 Dew"). A "+" stays. They wrap the
# number tokens, which resolve first: "({dew:{grow_cost:magpies_hoard}})", "+{dew:{field:magpies_hoard.crit_dew:count}}".
static func amount_text(resource: String, amount: String) -> String:
	var glyph: String = {"dew": UiStyle.DEW_GLYPH, "dreamlight": UiStyle.DREAMLIGHT_GLYPH, "seeds": UiStyle.SEEDS_GLYPH}.get(resource, "")
	return glyph + amount

static var _amount_regex: RegEx = null
static func _amount_pattern() -> RegEx:
	if _amount_regex == null:
		_amount_regex = RegEx.create_from_string("\\{(dew|dreamlight|seeds):([-+]?\\d+(?:\\.\\d+)?)\\}")
	return _amount_regex

# "{pct:beacon.marked_bonus}" -> "50%": TowerData field `field` of Warden `warden_id`, × 100 ("full strength" at 1.0).
static func pct_text(warden_id: String, field: String) -> String:
	var path := "res://resource/tower/%s.tres" % warden_id
	var data := load(path) as TowerData if ResourceLoader.exists(path) else null
	if data == null or not (field in data):
		return "%s.%s" % [warden_id, field]
	var value := float(data.get(field))
	return "full strength" if is_equal_approx(value, 1.0) else "%d%%" % roundi(value * 100.0)  # Like {echo:}: 1.0 reads "full"

# Any TowerData number in text (text_pass.md 797758fe: 17 Warden cards quoted stale numbers): "{field:snugroot.hold_targets}"
# -> "5", one Dictionary key deep ("{field:nimbus.special_params.burst_every}"), with an optional format: ":count"
# (whole number), ":seconds" ("1.5 s"), ":every" (a per-second rate as its period: "5 s"), ":pct" (× 100, "80%"), ":cells"
# ("2.5 cells"), ":times" ("×1.5"). No format: a whole number when it is one, else up to 2 decimals.
static func field_text(warden_id: String, field: String, style: String = "") -> String:
	var path := "res://resource/tower/%s.tres" % warden_id
	var data := load(path) as TowerData if ResourceLoader.exists(path) else null
	var parts := field.split(".")  # "special_params.key": a key inside a Dictionary field (BranchKit specials)
	if data == null or not (parts[0] in data):
		return "%s.%s" % [warden_id, field]
	var raw = data.get(parts[0])
	if parts.size() > 1:
		if not (raw is Dictionary) or not raw.has(parts[1]):
			return "%s.%s" % [warden_id, field]
		raw = raw[parts[1]]
	if not (raw is float or raw is int):
		return "%s.%s" % [warden_id, field]
	var value := float(raw)
	match style:
		"every":  # A rate per second as its period: attacks_per_second 0.2 -> "5 s"
			return "%s s" % _number(1.0 / value) if value > 0.0 else "%s.%s" % [warden_id, field]
		"count":
			return str(roundi(value))
		"pct":
			return "%d%%" % roundi(value * 100.0)
		"seconds":
			return "%s s" % _number(value)
		"cells":
			return "%s cell%s" % [_number(value), "" if is_equal_approx(value, 1.0) else "s"]
		"times":
			return "×%s" % _number(value)
	return _number(value)

# 3 -> "3", 1.5 -> "1.5", 0.333 -> "0.33".
static func _number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(roundi(value))
	return str(snappedf(value, 0.01))

static var _field_regex: RegEx = null
static func _field_pattern() -> RegEx:
	if _field_regex == null:
		UiStyle.release_at_exit(func() -> void: _field_regex = null)
		_field_regex = RegEx.create_from_string("\\{field:([a-z_0-9]+)\\.([a-z_0-9]+(?:\\.[a-z_0-9]+)?)(?::([a-z]+))?\\}")
	return _field_regex

static var _pct_regex: RegEx = null
static func _pct_pattern() -> RegEx:
	if _pct_regex == null:
		UiStyle.release_at_exit(func() -> void: _pct_regex = null)
		_pct_regex = RegEx.create_from_string("\\{pct:([a-z_0-9]+)\\.([a-z_0-9]+)\\}")
	return _pct_regex

# "{echo:echo_hollow}" -> "75%" ("full" at 1.0), read from that Warden's echo_share (Tower Discussion: the
# texts follow Balancing's numbers).
static func echo_text(warden_id: String) -> String:
	var path := "res://resource/tower/%s.tres" % warden_id
	var data := load(path) as TowerData if ResourceLoader.exists(path) else null
	if data == null:
		return warden_id
	return "full" if is_equal_approx(data.echo_share, 1.0) else "%d%%" % roundi(data.echo_share * 100.0)

# "{grow_cost:beacon}" -> its evolve_cost, "{plant_cost:acorn}" -> its cost (as a number: the text says "Dew").
static func cost_text(kind: String, warden_id: String) -> String:
	var path := "res://resource/tower/%s.tres" % warden_id
	var data := load(path) as TowerData if ResourceLoader.exists(path) else null
	if data == null:
		return warden_id
	return str(data.get_grow_price() if kind == "grow_cost" else data.cost)

static var _cost_regex: RegEx = null
static func _cost_pattern() -> RegEx:
	if _cost_regex == null:
		UiStyle.release_at_exit(func() -> void: _cost_regex = null)
		_cost_regex = RegEx.create_from_string("\\{(grow_cost|plant_cost):([a-z_0-9]+)\\}")
	return _cost_regex

static var _echo_regex: RegEx = null
static func _echo_pattern() -> RegEx:
	if _echo_regex == null:
		UiStyle.release_at_exit(func() -> void: _echo_regex = null)
		_echo_regex = RegEx.create_from_string("\\{echo:([a-z_]+)\\}")
	return _echo_regex

static var _combo_regex: RegEx = null
static func _combo_pattern() -> RegEx:
	if _combo_regex == null:
		UiStyle.release_at_exit(func() -> void: _combo_regex = null)
		_combo_regex = RegEx.create_from_string("\\{(?:named_)?combo:([a-z_]+)\\}")  # {named_combo:x}: always named (Dream cards)
	return _combo_regex

# Family names as links (screens_ui.md "remove Half-dreamed"): "{family:dewdrop}" is the family's
# name, a link (StatusLinks) whose popup is its emblem, damage type and identity.
# A number and its unit never split across lines (user, Groundroot's panel: "every 3" / "s"): the space between them
# becomes a non-breaking one ("3 s", "3.5 cells", "+0.3 link", "×1.5 range"). format() runs every text through it.
const NBSP := " "  # Non-breaking space
static var _unit_pattern: RegEx = null

static func keep_units(text: String) -> String:
	if _unit_pattern == null:
		UiStyle.release_at_exit(func() -> void: _unit_pattern = null)
		_unit_pattern = RegEx.create_from_string(
			"(\\d%?) (s|sec|seconds?|cells?|tiles?|link|range|Dew|drifts?|Seeds?|leaf|leaves|Dreamlight|stacks?|ranks?|nightmares?|Wardens?|hits?|times?|damage|%)(?![A-Za-z])")
	return _unit_pattern.sub(text, "$1" + NBSP + "$2", true)

static var _family_pattern: RegEx = null
static func family_pattern() -> RegEx:
	if _family_pattern == null:
		UiStyle.release_at_exit(func() -> void: _family_pattern = null)
		_family_pattern = RegEx.create_from_string("\\{family:([a-z_]+)\\}")
	return _family_pattern

# "{card:charged_feathers}" -> "Charged Feathers", "{omen:static_sky}" -> "Crackling Sky": a Dream card or Omen named in text, always plain (story chat, user: the
# "Charged" in a card name was linked as the status). StatusLinks keeps it out of the status links.
static var _card_pattern: RegEx = null
static func card_pattern() -> RegEx:
	if _card_pattern == null:
		UiStyle.release_at_exit(func() -> void: _card_pattern = null)
		_card_pattern = RegEx.create_from_string("\\{(card|omen|warden):([a-z0-9_]+)\\}")  # 1: kind, 2: id ({warden:graftling}: the tower file's name; a plural is plain text after it)
	return _card_pattern

static func card_name(id: String, kind: String = "card") -> String:
	var path := ("res://resource/omen/%s.tres" if kind == "omen" else ("res://resource/tower/%s.tres" if kind == "warden" else "res://resource/dream/%s.tres")) % id
	if ResourceLoader.exists(path):
		var card = load(path)
		if card is UpgradeData or card is OmenData or card is TowerData:
			return card.display_name
	return id.capitalize()

# The family's base Warden (resource/tower/<id>.tres), or null.
static func family_data(id: String) -> TowerData:
	var path := "res://resource/tower/%s.tres" % id
	return load(path) as TowerData if ResourceLoader.exists(path) else null

# Nightmare names ({nightmare:shellbound}; user: "dread shell should have an underline with the nightmare linked"): the
# kind's name once met on this profile, ??? until then (the Codex's rule). StatusLinks makes them links to its card.
static var _nightmare_pattern: RegEx = null
static func nightmare_pattern() -> RegEx:
	if _nightmare_pattern == null:
		UiStyle.release_at_exit(func() -> void: _nightmare_pattern = null)
		_nightmare_pattern = RegEx.create_from_string("\\{nightmare:([a-z0-9_]+)\\}")
	return _nightmare_pattern

# The kind's EnemyData (resource/enemy/<kind>.tres), or null.
static func nightmare_data(kind: String) -> EnemyData:
	var path := NightmareCodex.DIR + kind + ".tres"
	return load(path) as EnemyData if ResourceLoader.exists(path) else null

static func nightmare_met(kind: String) -> bool:
	return NightmareCodex.seen().has(kind)

static func nightmare_name(kind: String) -> String:
	var data := nightmare_data(kind)
	if data == null:
		return kind.capitalize()
	return data.display_name if nightmare_met(kind) else "???"

# The status id for a display name ("Soak" -> &"damp"), or &"" (StatusLinks uses it).
static func status_id(name: String) -> StringName:
	for id in STATUSES:
		if STATUSES[id][0].to_lower() == name.to_lower():
			return id
	return &""
