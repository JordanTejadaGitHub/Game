extends RefCounted
class_name CodexData

# What the Codex holds (screens_ui.md "The Codex: Glossary and Combos"):
# - glossary(): every term, always listed: [group, [[term, one-line definition, [see also…]], …]],
#   from GLOSSARY_SOURCE with the status names filled in ({damp}, and {tip:damp} = its IconInfo text).
#   Bosses and late nightmares aren't here; they join the "Nightmares you've met" group once met.
# - The 15 combos: 7 synergies (SYNERGIES, below) + the 8 Reactions (resource/reaction, via
#   Reactions.all()). New Reactions join automatically. ComboFeedback discovers them in play.

const GLOSSARY_SOURCE := [
	["Resources", [
		["Dew", "The run's currency: earned by dispelling nightmares and at rests, spent on Wardens, growth, Nurture and clearing.", ["Rest", "Nurture"]],
		["Dreamlight", "Freed by great nightmares (bosses, the first family pick): unlocks branches and final forms on the Remember screen.", ["Remember screen", "Branch", "Final form"]],
		["Leaves", "The Heartwood's life. A nightmare that reaches it takes leaves; lose them all and the dream goes dark.", ["Act"]],
		["Seeds", "Earned every run, win or lose; spent in the Memory Grove between runs.", ["Memory Grove"]],
		["Dreamlight shard", "Dreamcatchers gather shards from caught nightmares: 10 shards make 1 Dreamlight (at most 2 per run this way).", ["Dreamlight", "Caught"]],
		["The thinning dream", "Each act, nightmares leave less Dew: all of it in act 1, then 80%, 65% and half.", ["Dew", "Act"]],
	]],
	["The run", [
		["Drift", "A wave of nightmares. A run is 100 drifts in 4 acts.", ["Block", "Act"]],
		["Block", "Five drifts that flow into each other, followed by a rest.", ["Drift", "Rest"]],
		["Rest", "The pause after a block: a Dew bonus, a Dream, rebuild freely at a 75% refund, then Start.", ["Dream", "Omen"]],
		["Act", "25 drifts ending in a boss. Between acts the season changes and the Heartwood regrows a leaf.", ["Boss", "Leaves"]],
		["Boss", "A great nightmare at the end of each act. Dispelling it brings a family pick, Dreamlight and a rare Dream.", ["Family pick", "Dreamlight"]],
		["Family pick", "After drift 1 and after each boss: choose a new Warden family for this run.", ["Family", "Family Blessing"]],
		["Family Blessing", "When fewer than three new families are left, the empty slots of a family pick are boons for families you own.", ["Family pick"]],
		["Dream", "A card chosen at each rest: a lasting change to your Wardens, nightmares or economy for this run.", ["Rarity", "Let it pass"]],
		["Omen", "From drift 10: a twist for the next block with a reward if you survive it. Clear Skies skips it.", ["Rest"]],
		["Call early", "Starting the next drift while the current one is still arriving, for a little extra Dew.", ["Auto-drift"]],
		["Auto-drift", "Drifts in a block start by themselves a few seconds after the last one arrived.", ["Call early", "Block"]],
		["Remember screen", "Spend Dreamlight on a family's branches and final forms. Opens after each boss, and from the rest panel.", ["Dreamlight"]],
	]],
	["Wardens", [
		["Warden", "A guardian spirit you plant on the map. Wardens are walls: nightmares walk around them.", ["Family", "Thornwall"]],
		["Family", "A Warden line (Sporeling, Dewdrop, …) with its own statuses, branches and final forms.", ["Branch", "Family pick"]],
		["Branch", "A Warden a family grows into. Unlocked with Dreamlight, then grown with Dew.", ["Grow", "Final form"]],
		["Final form", "The last step of a branch. Needs the Memory Grove, Dreamlight and Dew.", ["Branch", "Memory Grove"]],
		["Hidden branch", "A secret branch the Memory Grove can open late, after the family's final forms.", ["Memory Grove"]],
		["Memory Warden", "A unique Warden a boss leaves behind the first time it is dispelled. One on the map at a time.", ["Boss"]],
		["Grow", "Evolve a Warden into an unlocked next form in place, for Dew.", ["Branch", "Nurture"]],
		["Nurture", "Spend Dew to raise a Warden's rank: more damage, speed and range. Ranks survive growing.", ["Rank", "Focus"]],
		["Rank", "How nurtured a Warden is (I to V): each rank adds damage, speed and range.", ["Nurture"]],
		["Focus", "At rank III a Warden takes a focus: Power, Swift, Reach or Deep.", ["Rank"]],
		["Thornwall", "A cheap wall that doesn't attack; grows into Bramble or Honeysuckle.", ["Warden"]],
		["Crit", "A critical hit: some Wardens sometimes hit much harder.", ["Pinned", "Potency"]],
		["Potency", "Effect damage: scales status and poison damage and Reactions the way crit scales hits.", ["Crit", "{spored}"]],
		["Clear tool", "Tend withered trees and move boulders to reshape the maze. Opens with a clearing Dream.", ["Dew"]],
		["Ascended", "A family's endgame Warden, from drift 51: 3 Dreamlight, then grown from a final form for 400 Dew. One per family per run.", ["Final form", "Ascension"]],
		["Heartwood Sapling", "A 2×2 offshoot of the Heartwood from drift 51: it yields Dew every drift and Dreamlight every 10 drifts. Permanent.", ["Permanent", "Dreamlight"]],
		["Permanent", "Can't be sold or moved.", ["Heartwood Sapling"]],
	]],
	["Nightmares", [
		["Nightmare", "The Hollow's dreams turned cruel, hunting the Heartwood's dream. Dispel them before they reach it.", ["Dispel"]],
		["Dispel", "Breaking a nightmare apart with your Wardens' light. It leaves Dew behind.", ["Nightmare"]],
		["Deeply Blighted", "An elite nightmare: three times the health and Dew, and it takes two leaves.", ["Leaves"]],
		["Resists and Weak to", "Some nightmares take less from certain Warden families and more from others.", ["Family"]],
		["Dread shell", "A shell that soaks chip damage: heavy hits break through.", ["Crit"]],
		["Hidden", "Lurkers can't be seen or targeted until revealed or close.", ["Nightmare"]],
		["Flying", "Flies straight over the maze, ignoring walls.", ["Nightmare"]],
	]],
	["Statuses", [
		["{damp}", "{tip:damp}", ["Conducted", "Thunderclap"]],
		["{drowsy}", "{tip:drowsy}", ["{asleep}", "Drown"]],
		["{asleep}", "{tip:asleep}", ["{drowsy}", "Caught"]],
		["{spored}", "{tip:spored}", ["Popped", "Ignite"]],
		["{marked}", "{tip:marked}", ["Exposed Blow", "Lightning Rod"]],
		["{static}", "{tip:static}", ["Set Off", "Thunderclap"]],
		["{held}", "{tip:held}", ["Shatter", "Smother"]],
		["{caught}", "{tip:caught}", ["{drowsy}", "{asleep}"]],
		["{frozen}", "{tip:frozen}", ["{damp}"]],
	]],
	["Combos", [
		["Reaction", "Two statuses meeting on one nightmare set off a named effect, like Thunderclap ({damp} + {static}).", ["Chain", "Crowned Reaction"]],
		["Crowned Reaction", "A Reaction going off on a nightmare that already carries a third status: a bigger, named version.", ["Reaction", "Woven"]],
		["Chain", "Reactions setting each other off within 1 s. Shown as Chain 5, not a damage multiplier; Chain 10 is a Dawnburst.", ["Reaction", "Dawnburst"]],
		["Dawnburst", "A Chain 10: a flash of dawn over the whole fight. With the Dawnbreak Legendary it also takes a tenth of the health of every nightmare within 4 cells (bosses: 2%).", ["Chain", "Dawnbreak"]],
		["Dawnbreak", "The Legendary Dream that gives a Dawnburst its bite (grown in the Memory Grove).", ["Dawnburst", "Legendary"]],
	]],
	["Dreams", [
		["Rarity", "Common, Uncommon, Rare, Legendary: the shape and colour of a Dream card's gem.", ["Legendary"]],
		["Deepened", "A stronger \"II\" version of a rule card you already own. It replaces the first.", ["Dream"]],
		["Entwined", "A combo card offered once you own all its ingredients (cards or Wardens); guaranteed a slot the first time.", ["Dream"]],
		["Bittersweet", "A strong Dream with a cost written on it.", ["Dream"]],
		["Legendary", "The rarest Dreams, grown in the Memory Grove.", ["Memory Grove"]],
		["Let it pass", "Skip a Dream offer for a little Dew.", ["Dream"]],
		["Reroll", "Redraw a Dream offer (a Memory Grove perk).", ["Loadout"]],
		["Banish", "Remove a card from this run's pool (a Memory Grove perk).", ["Loadout"]],
		["Woven", "A three-ingredient Legendary that strengthens a Crowned Reaction.", ["Crowned Reaction", "Entwined"]],
	]],
	["The Memory Grove", [
		["Memory Grove", "The Heartwood's tree of lasting unlocks, grown with Seeds between runs.", ["Seeds", "Loadout"]],
		["Memories", "The Hollow's story, told in ten Memories that ripen as the Grove grows.", ["Memory Grove"]],
		["Loadout", "The perks you carry into a run, set on the waystones at the Heartwood's roots: one at first, up to five as the Grove grows.", ["Memory Grove"]],
		["Ascension", "The Grove node that lets a family's Ascended Warden appear in runs.", ["Ascended", "Memory Grove"]],
		["Blight Levels", "Harder runs for more Seeds, opened by your first win.", ["Seeds"]],
		["Milestones", "Feats that unlock things for free (and are Steam achievements).", ["Memory Grove"]],
	]],
]

# The 7 synergies: id -> [name, ingredient statuses, what it does, which Wardens set it off].
# The id is also the DamageLog combo tag where one exists (conducted, popped, fog); the rest are
# reported with ComboFeedback.report(id, …) where they happen.
const SYNERGIES := {
	&"conducted": ["Conducted", [&"damp", &"static"], "Lightning jumps further and more often between {damp} nightmares.", "Stormcap"],
	&"popped": ["Popped", [&"spored", &"spored"], "10+ {spored} bursts over the nightmare and its neighbours.", "Puffball"],
	&"asleep": ["Asleep", [&"drowsy", &"drowsy"], "Full {drowsy}: the nightmare falls {asleep}.", "Dreamshroom"],
	&"fog": ["Spore Fog", [&"spored", &"damp"], "{spored} ticks harder inside Mistveil fog.", "Mistveil"],
	&"set_off": ["Set Off", [&"static", &"static"], "A pulse sets off a {static} bolt.", "Chime Stone, Lullaby Bell"],
	&"marked_blow": ["Exposed Blow", [&"marked", &"marked"], "A heavy hit does double damage on {marked} nightmares.", "Mossback, Boulderback"],
	&"caught": ["Caught", [&"drowsy", &"drowsy"], "{asleep} or full {drowsy} near a Dreamcatcher: it takes extra damage from everything.", "Dreamcatcher"],
}

# Crowned Reactions (tower_design.md "Crowned Reactions: three families at once"): a Reaction going
# off on a nightmare that already carries a third status. id -> [name, base Reaction, the third
# status, its three families (Warden ids), what happens]. Hidden in the Codex until found (a
# gold crown frame, "???"), not in the demo, and not part of the 15 combos' count.
const CROWNED := {
	&"tempest": ["Tempest", &"thunderclap", &"spored", ["dewdrop", "firefly_jar", "sporeling"],
		"Every arc also sets off Ignite on {spored} nightmares, and the spores carry {static} onto {damp} ones: new Thunderclaps follow."],
	&"still_pool": ["Still Pool", &"drown", &"held", ["dewdrop", "bellflower", "rootling"],
		"The nightmare sinks and leaves a still pool for 5 s: every walker that enters it sleeps for a moment."],
	&"fever_dream": ["Fever Dream", &"smother", &"drowsy", ["sporeling", "rootling", "bellflower"],
		"Its spores all go off at once, and it passes {spored} + {drowsy} to its neighbours: a sleep plague."],
	&"starfall": ["Starfall", &"pinned", &"static", ["firefly_jar", "rootling", "bellflower"],
		"The crit pulls every {static} bolt within 3 cells into it; each bolt crits too, and a column of light falls."],
	&"avalanche": ["Avalanche", &"shatter", &"held", ["dewdrop", "rootling", "pebbling"],
		"A Cairn or Rockslide lob sets off the Shatter on every {damp} + {held} nightmare under it."],
	&"prismstorm": ["Prismstorm", &"shatter", &"static", ["dewdrop", "rootling", "firefly_jar"],
		"The ice shards carry lightning: each adds {static} to what it hits, so {damp} neighbours Thunderclap."],
	&"nightbloom": ["Nightbloom", &"mushrooming", &"drowsy", ["sporeling", "dewdrop", "bellflower"],
		"The spore cloud glows violet and nothing inside can wake."],
	&"fairy_circle": ["Fairy Circle", &"mushrooming", &"held", ["sporeling", "dewdrop", "rootling"],
		"A ring of mushrooms sprouts around the held nightmare: walkers crossing it get {spored} + {damp}."],
}
# assets/meta/icons/family_icons.png: 32×32 icons in this order.
const FAMILY_ICON_ORDER := ["sporeling", "firefly_jar", "dewdrop", "pebbling", "rootling", "bellflower",
	"acorn", "nestling", "whirligig"]
# TowerData.line -> family id (Kinships' signals pass the line: family_whole("spore")).
const LINE_FAMILIES := {"spore": "sporeling", "water": "dewdrop", "light": "firefly_jar", "stone": "pebbling",
	"root": "rootling", "song": "bellflower", "acorn": "acorn", "wing": "nestling", "wind": "whirligig"}
const FAMILY_NAMES := {"sporeling": "Sporeling", "firefly_jar": "Firefly Jar", "dewdrop": "Dewdrop",
	"pebbling": "Pebbling", "rootling": "Rootling", "bellflower": "Bellflower", "acorn": "Acorn",
	"nestling": "Nestling", "whirligig": "Whirligig"}

# The Crowned Reactions: [{id, name, kind "Crowned", base, statuses (base's + the third), families, text}].
# A ReactionData of the same id (if Tower Code adds one) supplies the name and text.
static func crowned() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for id in CROWNED:
		var c: Array = CROWNED[id]
		var base := Reactions.get_data(c[1])
		var statuses: Array = (base.statuses.duplicate() if base else []) + [c[2]]
		var data := Reactions.get_data(id)
		list.append({"id": id, "name": data.display_name if data else c[0], "kind": "Crowned", "base": c[1],
			"statuses": statuses, "families": c[3], "text": IconInfo.format(data.description if data else c[4]), "by": ""})
	return list

# A combo, a Crowned Reaction or a Kinship by id ({} if none).
static func get_any(id: StringName) -> Dictionary:
	var found := get_combo(id)
	if found.is_empty():
		for c in crowned() + kinships():
			if c.id == id:
				return c
	return found

# Kinships (tower_design.md "Kinships"; Tower Code's Kinships.KINSHIPS: id -> [name, line, branch A,
# branch B, …]): two branches of one family side by side, each borrowing a trait from the other.
# What they borrow, in the players' words ({tokens} = status names):
const KINSHIP_TEXT := {
	&"slumber_rot": "Driftspore's puffs add 1 {drowsy}; Bloomcap's clouds add 1 {spored} per tick.",
	&"rainfog": "Rain Lily's splashes leave a fog patch; the fog deals Rain Lily's splash damage to nightmares entering it.",
	&"storm_beacon": "Stormcap's jumps leave nightmares {marked} for 2 s; Lanternmoth's shots add 1 {static}.",
	&"hammer_and_anvil": "Mossback gains the sniper's eye (+10% crit chance at ×2.5); Standing Stone deals ×2 to {marked} nightmares.",
	&"snare": "Rootcurl's pulls end in a 0.5 s hold; Tangleroot's holds drag the nightmare back half a tile.",
	&"night_chimes": "Chime Stone's pulses deal +40% to {caught} nightmares; Dreamcatcher's threads set off {static} at 3 stacks.",
	&"old_growth": "Elder Stump yields +2 Dew per drift; Dewcatcher gains a small aura: neighbours +10% attack speed.",
	&"flock_together": "Nightmares Wren's Nest hits drop +1 Dew; Magpie Perch hunts the fastest nightmare, +25% vs Phantoms.",
	&"dust_devil": "Gust's copies also deal a blade hit; Pinwheel's blades copy statuses (half stacks) onto what they hit.",
}
const KINSHIPS_SCRIPT := "res://scripts/combat/kinships.gd"
const KINSHIP_GROWTH := "Within 2 cells they bond; the bond grows (Blooming at 5 drifts, Old Kin at 10) and both strike in Harmony."

# [{id, name, kind "Kinship", line, a, b (Warden names), text}], or [] before Kinships exist.
static func kinships() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	if not ResourceLoader.exists(KINSHIPS_SCRIPT):
		return list
	var table = (load(KINSHIPS_SCRIPT) as Script).get_script_constant_map().get("KINSHIPS")
	if not table is Dictionary:
		return list
	for id in table:
		var k: Array = table[id]
		list.append({"id": id, "name": k[0], "kind": "Kinship", "line": k[1], "a": _warden_name(k[2]),
			"b": _warden_name(k[3]), "statuses": [],
			"text": IconInfo.format(KINSHIP_TEXT.get(id, "")) + " " + KINSHIP_GROWTH, "by": ""})
	return list

static func _warden_name(id: String) -> String:
	var path := "res://resource/tower/%s.tres" % id
	var data := load(path) as TowerData if ResourceLoader.exists(path) else null
	return data.display_name if data != null else id.capitalize()

# "Thunderclap + Poisoned" for a Crowned Reaction.
static func crowned_recipe(c: Dictionary) -> String:
	var base := Reactions.get_data(c.base)
	return "%s + %s" % [base.display_name if base else String(c.base).capitalize(),
		IconInfo.status_name(c.statuses[-1])]

static func family_icon(family: String) -> Texture2D:
	var index := FAMILY_ICON_ORDER.find(family)
	if index < 0 or not ResourceLoader.exists(FAMILY_ICONS):
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = load(FAMILY_ICONS)
	atlas.region = Rect2(index * 32, 0, 32, 32)
	return atlas

const FAMILY_ICONS := "res://assets/meta/icons/family_icons.png"

# Every combo: [{id, name, kind ("Synergy" / "Reaction"), statuses, text, by}], synergies first.
static func combos() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for id in SYNERGIES:
		var s: Array = SYNERGIES[id]
		list.append({"id": id, "name": s[0], "kind": "Synergy", "statuses": s[1], "text": IconInfo.format(s[2]), "by": s[3]})
	var reactions := Reactions.all()
	reactions.sort_custom(func(a: ReactionData, b: ReactionData) -> bool: return a.display_name < b.display_name)
	for data in reactions:
		if CROWNED.has(data.id):
			continue  # Crowned Reactions are their own list (crowned())
		list.append({"id": data.id, "name": data.display_name, "kind": "Reaction", "statuses": data.statuses,
			"text": IconInfo.format(data.description), "by": ""})
	return list

static func get_combo(id: StringName) -> Dictionary:
	for combo in combos():
		if combo.id == id:
			return combo
	return {}

# "Soaked + Charged" (a synergy on one status reads just "Poisoned").
static func ingredients_text(combo: Dictionary) -> String:
	var names: Array[String] = []
	for status in combo.statuses:
		var name := IconInfo.status_name(status)
		if not names.has(name):
			names.append(name)
	return " + ".join(names)

# Glossary entries whose term (or group) contains `query` (case-insensitive); all when empty.
static var _glossary: Array = []
static var _glossary_sapling := false  # TowerPlacer.sapling_enabled when it was built
# Terms only while the Heartwood Sapling is in runs (TowerPlacer.sapling_enabled; run_design.md).
const SAPLING_TERMS := ["Heartwood Sapling", "Permanent"]

# The glossary with today's status names and IconInfo's definitions filled in (built once, again
# if the Sapling is switched on or off).
static func glossary() -> Array:
	if _glossary_sapling != TowerPlacer.sapling_enabled:
		_glossary = []
		_glossary_sapling = TowerPlacer.sapling_enabled
	if _glossary.is_empty():
		for group in GLOSSARY_SOURCE:
			var entries: Array = []
			for entry in group[1]:
				if not TowerPlacer.sapling_enabled and SAPLING_TERMS.has(entry[0]):
					continue
				var text: String = entry[1]
				if text.begins_with("{tip:"):
					text = IconInfo.STATUSES.get(StringName(text.trim_prefix("{tip:").trim_suffix("}")), ["", ""])[1]
				entries.append([IconInfo.format(entry[0]), IconInfo.format(text),
					entry[2].map(func(s: String) -> String: return IconInfo.format(s))])
			_glossary.append([group[0], entries])
	return _glossary

static func search(query: String) -> Array:
	var found: Array = []
	var q := query.strip_edges().to_lower()
	for group in glossary():
		for entry in group[1]:
			if q == "" or entry[0].to_lower().contains(q) or entry[1].to_lower().contains(q):
				found.append([group[0], entry])
	return found

static var _term_patterns := {}  # Term -> RegEx matching it as whole words (plurals too)

# The first glossary term mentioned in `text` as a whole word ("" if none): tapping in-game text
# opens it. "forest" doesn't count as "Rest", nor "Dewdrop" as "Dew"; "Wardens" counts as "Warden".
static func find_term(text: String) -> String:
	var best := ""
	var best_at := 1 << 30
	for group in glossary():
		for entry in group[1]:
			if not _term_patterns.has(entry[0]):
				var regex := RegEx.new()
				regex.compile("(?i)\\b" + _escape(entry[0]) + "s?\\b")
				_term_patterns[entry[0]] = regex
			var found: RegExMatch = _term_patterns[entry[0]].search(text)
			if found != null and found.get_start() < best_at:
				best = entry[0]
				best_at = found.get_start()
	return best

static func _escape(term: String) -> String:
	var out := ""
	for c in term:
		out += ("\\" + c) if "\\.^$|?*+()[]{}".contains(c) else c
	return out
