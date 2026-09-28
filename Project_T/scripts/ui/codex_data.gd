extends RefCounted
class_name CodexData

# What the Codex holds (screens_ui.md "The Codex: Glossary and Combos"):
# - GLOSSARY: every term, always listed: [group, [[term, one-line definition, [see also…]], …]].
#   Bosses and late nightmares aren't here; they join the "Nightmares you've met" group once met.
# - The 15 combos: 7 synergies (SYNERGIES, below) + the 8 Reactions (resource/reaction, via
#   Reactions.all()). New Reactions join automatically. ComboFeedback discovers them in play.

const GLOSSARY := [
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
		["Potency", "Effect damage: scales status and spore damage and Reactions the way crit scales hits.", ["Crit", "Spored"]],
		["Clear tool", "Tend withered trees and move boulders to reshape the maze. Opens with a clearing Dream.", ["Dew"]],
		["Ascended", "A family's endgame Warden, from drift 51: 3 Dreamlight, then grown from a final form for 400 Dew. One per family per run.", ["Final form", "Ascension"]],
		["Heartwood Sapling", "A 2×2 offshoot of the Heartwood from drift 51: it yields Dew every drift and Dreamlight every 10 drifts. Rooted.", ["Rooted", "Dreamlight"]],
		["Rooted", "Can't be sold or moved.", ["Heartwood Sapling"]],
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
		["Damp", "Slower, and lightning loves it.", ["Conducted", "Thunderclap"]],
		["Drowsy", "Heavy-eyed and slow; full Drowsy puts it to sleep with the right Warden.", ["Asleep", "Drown"]],
		["Spored", "Spores keep eating at it over time.", ["Popped", "Ignite"]],
		["Marked", "Every Warden hits it harder.", ["Marked Blow", "Lightning Rod"]],
		["Static", "Charges build up to a free lightning bolt.", ["Set Off", "Thunderclap"]],
		["Held", "It can't move. Now's the time.", ["Shatter", "Smother"]],
		["Caught", "Asleep or fully Drowsy near a Dreamcatcher: it takes extra damage from everything.", ["Drowsy", "Asleep"]],
		["Frozen", "Frost stops it for a moment.", ["Damp"]],
	]],
	["Combos", [
		["Reaction", "Two statuses meeting on one nightmare set off a named effect, like Thunderclap (Damp + Static).", ["Chain", "Crowned Reaction"]],
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
	&"conducted": ["Conducted", [&"damp", &"static"], "Lightning jumps further and more often between Damp nightmares.", "Stormcap"],
	&"popped": ["Popped", [&"spored", &"spored"], "10+ Spored bursts over the nightmare and its neighbours.", "Puffball"],
	&"asleep": ["Asleep", [&"drowsy", &"drowsy"], "Full Drowsy: the nightmare falls asleep.", "Dreamshroom"],
	&"fog": ["Spore Fog", [&"spored", &"damp"], "Spores tick harder inside Mistveil fog.", "Mistveil"],
	&"set_off": ["Set Off", [&"static", &"static"], "A pulse sets off a Static bolt.", "Chime Stone, Lullaby Bell"],
	&"marked_blow": ["Marked Blow", [&"marked", &"marked"], "A heavy hit does double damage on Marked nightmares.", "Mossback, Boulderback"],
	&"caught": ["Caught", [&"drowsy", &"drowsy"], "Asleep or full Drowsy near a Dreamcatcher: it takes extra damage from everything.", "Dreamcatcher"],
}

# Crowned Reactions (tower_design.md "Crowned Reactions: three families at once"): a Reaction going
# off on a nightmare that already carries a third status. id -> [name, base Reaction, the third
# status, its three families (Warden ids), what happens]. Hidden in the Codex until found (a
# gold crown frame, "???"), not in the demo, and not part of the 15 combos' count.
const CROWNED := {
	&"tempest": ["Tempest", &"thunderclap", &"spored", ["dewdrop", "firefly_jar", "sporeling"],
		"Every arc also sets off Ignite on Spored nightmares, and the spores carry Static onto wet ones: new Thunderclaps follow."],
	&"still_pool": ["Still Pool", &"drown", &"held", ["dewdrop", "bellflower", "rootling"],
		"The nightmare sinks and leaves a still pool for 5 s: every walker that enters it sleeps for a moment."],
	&"fever_dream": ["Fever Dream", &"smother", &"drowsy", ["sporeling", "rootling", "bellflower"],
		"Its spores all go off at once, and it passes Spored + Drowsy to its neighbours: a sleep plague."],
	&"starfall": ["Starfall", &"pinned", &"static", ["firefly_jar", "rootling", "bellflower"],
		"The crit pulls every Static bolt within 3 cells into it; each bolt crits too, and a column of light falls."],
	&"avalanche": ["Avalanche", &"shatter", &"held", ["dewdrop", "rootling", "pebbling"],
		"A Cairn or Rockslide lob sets off the Shatter on every Damp + Held nightmare under it."],
	&"prismstorm": ["Prismstorm", &"shatter", &"static", ["dewdrop", "rootling", "firefly_jar"],
		"The ice shards carry lightning: each adds Static to what it hits, so wet neighbours Thunderclap."],
	&"nightbloom": ["Nightbloom", &"mushrooming", &"drowsy", ["sporeling", "dewdrop", "bellflower"],
		"The spore cloud glows violet and nothing inside can wake."],
	&"fairy_circle": ["Fairy Circle", &"mushrooming", &"held", ["sporeling", "dewdrop", "rootling"],
		"A ring of mushrooms sprouts around the held nightmare: walkers crossing it get Spored + Damp."],
}
# assets/meta/icons/family_icons.png: 32×32 icons in this order.
const FAMILY_ICON_ORDER := ["sporeling", "firefly_jar", "dewdrop", "pebbling", "rootling", "bellflower",
	"acorn", "nestling", "whirligig"]
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
			"statuses": statuses, "families": c[3], "text": data.description if data else c[4], "by": ""})
	return list

# A combo or a Crowned Reaction by id ({} if neither).
static func get_any(id: StringName) -> Dictionary:
	var found := get_combo(id)
	if found.is_empty():
		for c in crowned():
			if c.id == id:
				return c
	return found

# "Thunderclap + Spored" for a Crowned Reaction.
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
		list.append({"id": id, "name": s[0], "kind": "Synergy", "statuses": s[1], "text": s[2], "by": s[3]})
	var reactions := Reactions.all()
	reactions.sort_custom(func(a: ReactionData, b: ReactionData) -> bool: return a.display_name < b.display_name)
	for data in reactions:
		if CROWNED.has(data.id):
			continue  # Crowned Reactions are their own list (crowned())
		list.append({"id": data.id, "name": data.display_name, "kind": "Reaction", "statuses": data.statuses,
			"text": data.description, "by": ""})
	return list

static func get_combo(id: StringName) -> Dictionary:
	for combo in combos():
		if combo.id == id:
			return combo
	return {}

# "Damp + Static" (a synergy on one status reads just "Spored").
static func ingredients_text(combo: Dictionary) -> String:
	var names: Array[String] = []
	for status in combo.statuses:
		var name := IconInfo.status_name(status)
		if not names.has(name):
			names.append(name)
	return " + ".join(names)

# Glossary entries whose term (or group) contains `query` (case-insensitive); all when empty.
static func search(query: String) -> Array:
	var found: Array = []
	var q := query.strip_edges().to_lower()
	for group in GLOSSARY:
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
	for group in GLOSSARY:
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
