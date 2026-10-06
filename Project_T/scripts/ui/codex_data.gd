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
		["Dreamlight shard", "Shards gather into Dreamlight: 10 shards make 1. Each source keeps its own cap: Dreamcatchers' shards from caught nightmares make at most 2 Dreamlight a run; other sources (Glimmering Hunt and the like) say theirs on their card.", ["Dreamlight", "Caught"]],
		["The Dew pot", "Each drift pays a set pot of Dew, shared out among its nightmares as they are dispelled. A nightmare that leaks takes its share with it.", ["Dew", "Act"]],
	]],
	["The run", [
		["Drift", "A wave of nightmares. A run is 100 drifts in 4 acts.", ["Block", "Act"]],
		["Block", "The 5 drifts between two rests; they flow into each other.", ["Drift", "Rest"]],
		["Perfect block", "A block in which no nightmare reached the Heartwood: no leaf lost. Its rest pays +10 Dew.", ["Block", "Rest", "Leaves"]],
		["Rest", "The pause after a block: a Dew bonus, a Dream, rebuild freely at a 75% refund, then Start.", ["Dream", "Omen"]],
		["Act", "25 drifts ending in a boss. Between acts the season changes and the Heartwood regrows a leaf.", ["Boss", "Leaves"]],
		["Boss", "A great nightmare at the end of each act. Dispelling it brings a family pick, Dreamlight and a rare Dream.", ["Family pick", "Dreamlight"]],
		["Family pick", "After drift 1 and after each boss: choose a new Warden family for this run. With none left, the Heartwood gives Dreamlight instead.", ["Family", "Dreamlight"]],
		["Dream", "A card chosen at each rest: a lasting change to your Wardens, nightmares or economy for this run.", ["Rarity", "Let it pass"]],
		["Omen", "From drift 10: a twist for the next block with a reward if you survive it. Clear Skies skips it.", ["Rest"]],
		["Call early", "Starting the next drift while the current one is still arriving, for a little extra Dew.", ["Auto-drift"]],
		["Auto-drift", "Drifts in a block start by themselves a few seconds after the last one arrived.", ["Call early", "Block"]],
		["Mist", "Where nightmares enter. With the path full it holds the rest back until there's room; a \"+N\" over it counts them. While it holds any, the next drift can't be called early.", ["Call early"]],
		["Remember screen", "Spend Dreamlight on a family's branches and final forms. The Remember button at the top right opens it any time (a drift pauses).", ["Dreamlight"]],
		["Close call", "A nightmare past 85% of its route: the Heartwood trembles and its last stretch glows cold.", ["Leaves"], "Three close calls in a block: time to lengthen the maze."],
		["Chain", "Reactions setting each other off within 1 s. Shown as Chain 5, not a damage multiplier; Chain 10 is a Dawnburst.", ["Reaction", "Dawnburst"], "Thunderclap → Lightning Rod → Mushrooming is a Chain 3."],
	]],
	["Wardens", [
		["Warden", "A small spirit that guards one spot. It's also a wall: nightmares walk around them.", ["Family", "Thornwall"]],
		["Family", "A Warden line (Sporeling, Dewdrop, …) with its own statuses, branches and final forms.", ["Branch", "Family pick"]],
		["Branch", "A Warden a family grows into. Unlocked with Dreamlight, then grown with Dew.", ["Grow", "Final form"], "A Sporeling grows into a branch such as Driftspore, and Driftspore into its final form, Puffball."],
		["Final form", "The last step of a branch, unlocked with Dreamlight and grown with Dew.", ["Branch", "Ascended"]],
		["Hidden branch", "A secret branch the Memory Grove can open late, once you own the family.", ["Memory Grove"]],
		["Grow", "Grow a Warden into an unlocked next form in place, for Dew. Its ranks come along.", ["Branch", "Nurture"]],
		["Nurture", "Spend Dew to raise a Warden's rank: more damage, speed and range, plus one choice per rank.", ["Rank", "Nurture choice"]],
		["Rank", "How nurtured a Warden is (I and up; the Eldest goes past V): each rank adds damage, speed and range.", ["Nurture", "Eldest"]],
		["Eldest", "A Legendary Dream lets one Warden a run grow past rank V; it wears a crown.", ["Rank", "Nurture"]],
		["Sprout", "The cheapest Warden: plant it anywhere as a wall, then grow it into one of your families once you've picked one.", ["Family pick", "Warden"]],
		["Aura", "A Warden that strengthens the Wardens around it instead of (or as well as) attacking: the 8 cells around it, or its range.", ["Boosts"]],
		["Harvest and interest", "Some Wardens make Dew: a Dewcatcher's line pours Dew after each drift (its harvest); a Wellspring adds interest on your Dew at each rest, at most 120 a rest for all of them together.", ["Dew", "Rest"]],
		["Nurture choice", "Each rank you pick how it grows: Power, Swift, Reach or Deep.", ["Nurture", "Potency"]],
		["Thornwall", "A cheap wall that doesn't attack; grows into Bramble or Honeysuckle.", ["Warden"]],
		["Clear tool", "Tend Withered Trees and move Mossy Boulders to reshape the maze. Opens with a clearing Dream.", ["Dew"]],
		["Ascended", "A family's endgame Warden, from drift 51: unlocked with Dreamlight, grown from a final form for Dew. One per family per run.", ["Final form", "Ascension"]],
		["Kinship", "Two branches of the same family within 2 cells of each other bond and grow stronger the longer they stand together.", ["Harmony strike", "Boosts"], "Blooming at 5 drifts, Old Kin at 10."],
		["Blooming and Old Kin", "A Kinship's stages: it bonds young, is Blooming after 5 drifts together and Old Kin after 10, each stage stronger.", ["Kinship"]],
		["Harmony strike", "When two Wardens in a Kinship hit the same nightmare within 1 s, petals burst on it for extra damage (at most every 2 s per pair).", ["Kinship"]],
		["Boosts", "Wardens that strengthen others near them: auras, Kinship bonds, and Kindred / Whole Tree. The Boosts button shows who's boosted, and by what.", ["Kinship"]],
		["Kindred", "Two different branches of one family on the map: that family's Wardens deal 10% more damage.", ["Whole Tree", "Kinship"]],
		["Whole Tree", "Three different branches of one family on the map at once (a branch or its final form each): that family's Wardens deal 20% more damage, in place of Kindred's 10%. Announced at the next rest.", ["Kindred"]],
		["Not in this dream", "A family has five branches and each run offers two of them (plus the Grove's hidden one). The others are not in this dream: misty on the Remember screen, where you can call one in for 3 Dreamlight, once per family.", ["Branch", "Remember screen"]],
	]],
	["Branch effects", [
		["Current", "Undercurrent opens a whirlpool on the path for 3 s that links up to 6 nightmares in it: 25% of any hit on one reaches each of the others. Maelstrom's is wider and links up to 8 at 45%, and its current also carries {static} bolts to the others at half.", ["Erosion"], "Shared damage is an effect: no crits, never shared twice, never part of a Reaction."],
		["Erosion", "Jetreed's jet wears its target down: each hit also takes 2% of the nightmare's max health (bosses 0.5%), never more than 4× the hit itself. Torrent's takes 3% (bosses 0.75%).", ["Current"]],
		["Arc", "Two Jarlinks within 4 cells join with an arc: nightmares touching it take damage every moment and gain 1 {static} each second, and a flyer crossing it takes 3 {static} at once. A Lightning Fence's arc hits much harder and catches Phantoms gliding through.", ["{static}"]],
		["Ink", "An Inkcap shot on a {spored} nightmare inks every path tile it walks for 2 s; a nightmare standing in ink gains 1 {spored} each second. A nightmare Deliquescent inked melts, when dispelled, into a pool over 2 path tiles for 4 s that adds {spored} twice a second.", ["{spored}"]],
		["Spore-sprite", "Brood Cap hatches little sprites (up to 4 at once) that walk up the path and burst on the first nightmare they touch: a full hit and 2 {spored} (Hatchery 3), and a {hidden} nightmare they bump shows itself. Every 5th Hatchery sprite is a big one that splits into 3.", ["{spored}", "{hidden}"]],
	]],
	["Damage types", [
		["Damage type", "Every Warden deals one type of damage: Spore, Stone, Water, Light, Root, Song, Talon, Wind, or Plain. The Warden panel and the Warden bar say which (\"Light damage\").", ["Resists and Weak to", "Plain damage"]],
		["Resists and Weak to", "A nightmare that resists a damage type takes half from it (×0.5); one weak to it takes 50% more (×1.5). It's the type that counts, not which Warden deals it.", ["Damage type"]],
		["Effect damage type", "Effects keep their source's type: {spored} ticks deal the type of the Warden that applied them, {static} bolts deal Light, clouds, rings and seeds deal their maker's type, and Reactions the type of the Warden that set them off.", ["Damage type"]],
		["Plain damage", "Sprouts, Thornwalls and Acorns deal Plain damage: never resisted, never weak.", ["Damage type"]],
		["Talon", "The Nestling family's damage type: beaks and claws.", ["Damage type"]],
	]],
	["Nightmares", [
		["Nightmare", "The Hollow's dreams turned cruel, hunting the Heartwood's dream. Dispel them before they reach it.", ["Dispel"]],
		["Dispel", "Breaking a nightmare apart with your Wardens' light. It leaves Dew behind.", ["Nightmare"]],
		["Deeply Blighted", "An elite nightmare: three times the health, a triple share of the Dew, and it takes two leaves.", ["Leaves"]],
		["Leak", "A nightmare that reaches the Heartwood: it takes leaves (most take 1, elites 2, bosses more) and its share of the Dew with it.", ["Leaves", "The Dew pot"]],
		["Dread shell", "A shell that soaks part of every hit: chip damage barely gets through, heavy hits mostly do. Each hit wears it down until it cracks for good.", ["Crit"], "Crits and big single hits get through it best."],  # Who wears one: nightmares_line (from the data)
		["Hidden", "Lurkers can't be seen or targeted until revealed or close.", ["Nightmare"]],
		["Flying", "Flies straight over the maze, ignoring walls.", ["Nightmare"]],
		["Restless", "A nightmare turned back by a change of route: +20% speed per stack, for good. Three make it Unbound. Not a status.", ["Unbound"]],
		["Unbound", "Turned back three times, it stops listening to the maze: it keeps its route and tramples any Warden planted on it (no refund). Bosses never become Unbound.", ["Restless"]],
		# EnemyData BURROW (burrow_max, burrow_min_saving) and laps() (lap_linger …): who has them is nightmares_line.
		["Burrow", "Sinks under a Warden or wall beside it and comes up on the other side, when that cuts its route short. Only a set number of times per trip.", ["Nightmare"]],
		["Laps", "Reaching the Heartwood, it stays and drains leaves, and can't be hit while it's there. Then it gallops back to the start and comes again, staying a little longer each lap.", ["Leak", "Leaves"]],
	]],
	["Statuses", [
		["{damp}", "{tip:damp}", ["Conducted", "Thunderclap"]],
		["{drowsy}", "{tip:drowsy}", ["{asleep}", "Drown"]],
		["{spored}", "{tip:spored}", ["Ignite", "Mushrooming"]],
		["{marked}", "{tip:marked}", ["Exposed Blow", "Lightning Rod"]],
		["{static}", "{tip:static}", ["Set Off", "Thunderclap"]],
		["{held}", "{tip:held}", ["Shatter", "Smother"]],
		["{asleep}", "{tip:asleep}", ["{drowsy}", "Caught"]],
		["{caught}", "{tip:caught}", ["{drowsy}", "{asleep}"]],
		["{frozen}", "{tip:frozen}", ["{damp}"]],
		["{silenced}", "{tip:silenced}", []],
	]],
	["Combat", [
		["Crit", "A critical hit: some Wardens sometimes hit much harder.", ["Pinned", "Potency"]],
		["Area attack", "An attack that hits every nightmare in a space (a pulse, a splash, a cloud) rather than one target. Some nightmares shrug off area attacks; others take more.", ["Effect"]],
		["Effect", "Damage that isn't a Warden's own hit: status ticks ({spored}, {static} bolts), clouds, rings, Reactions. Effects grow with Potency and never crit.", ["Potency", "Area attack"]],
		["Potency", "How strong a Warden's statuses and effects are: higher Potency means more damage from {spored}, {static} and Reactions, a stronger slow from {drowsy}, a bigger bonus from {damp} and {marked}, and longer {held}.", ["Crit", "{spored}"]],
		["Reaction", "Two statuses meeting on one nightmare set off a named effect, like Thunderclap ({damp} + {static}).", ["Chain", "Crowned Reaction"]],
		["Crowned Reaction", "A Reaction going off on a nightmare that already carries a third status: a bigger, named version.", ["Reaction", "Woven"]],
		["Dawnburst", "A Chain 10: a flash of dawn over the whole fight. With the Dawnbreak Legendary it also takes a tenth of the health of every nightmare within 4 cells (bosses: 2%).", ["Chain", "Dawnbreak"]],
		["Dawnbreak", "The Legendary Dream that gives a Dawnburst its bite (grown in the Memory Grove).", ["Dawnburst", "Legendary"]],
	]],
	["Dreams", [
		["Rarity", "Common, Uncommon, Rare, Legendary: the shape and color of a Dream card's gem.", ["Legendary"]],
		["Deepened", "A stronger \"II\" version of a rule card you already own. It replaces the first.", ["Dream"]],
		["Bittersweet", "A strong Dream with a cost written on it.", ["Dream"]],
		["Legendary", "The rarest Dreams, grown in the Memory Grove.", ["Memory Grove"]],
		["Let it pass", "Skip a Dream offer for a little Dew.", ["Dream"]],
		["Reroll", "Redraw a Dream offer (a Memory Grove perk).", ["Loadout"]],
		["Banish", "Remove a card from this run's pool (a Memory Grove perk).", ["Loadout"]],
		["Woven", "A three-ingredient Legendary that strengthens a Crowned Reaction.", ["Crowned Reaction", "Legendary"]],
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
# The id is also the DamageLog combo tag where one exists (conducted, fog); the rest are
# reported with ComboFeedback.report(id, …) where they happen.
const SYNERGIES := {
	&"conducted": ["Conducted", [&"damp", &"static"], "Lightning jumps farther and more often between {damp} nightmares.", "Stormcap"],
	&"asleep": ["Asleep", [&"drowsy", &"drowsy"], "Full {drowsy}: the nightmare falls {asleep} for 3 s; a big hit (10%+ of its health) wakes it.", "Dreamshroom"],
	&"fog": ["Spore Fog", [&"spored", &"damp"], "{spored} ticks harder inside Mistveil fog.", "Mistveil"],
	&"set_off": ["Set Off", [&"static", &"static"], "A pulse makes a nightmare with 3 or more {static} (4 for Lullaby Bell) release its bolt at once.", "Chime Stone, Lullaby Bell"],
	&"marked_blow": ["Exposed Blow", [&"marked", &"marked"], "A heavy hit does double damage on {marked} nightmares.", "Mossback, Boulderback"],
	&"caught": ["Caught", [&"drowsy", &"drowsy"], "{asleep} or full {drowsy} near a Dreamcatcher: the nightmare's statuses stop wearing off.", "Dreamcatcher"],
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
		"Its spores all go off at once, and it passes {spored} + {drowsy} to its neighbors: a sleep plague."],
	&"starfall": ["Starfall", &"pinned", &"static", ["firefly_jar", "rootling", "bellflower"],
		"The crit pulls every {static} bolt within 3 cells into it; each bolt crits too, and a column of light falls."],
	&"avalanche": ["Avalanche", &"shatter", &"held", ["dewdrop", "rootling", "pebbling"],
		"A Cairn or Rockslide lob sets off the Shatter on every {damp} + {held} nightmare under it."],
	&"prismstorm": ["Prismstorm", &"shatter", &"static", ["dewdrop", "rootling", "firefly_jar"],
		"The ice shards carry lightning: each adds {static} to what it hits, so {damp} neighbors Thunderclap."],
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
# Perf (Tower's lag probe: combat looked these up per chain link, and each call rebuilt every list): the lists are
# built once per session from fixed data (Reactions, Kinships.KINSHIPS, SYNERGIES: no {combo:} tokens) and copied
# out; get_any / get_combo read one index. Plain dictionaries only (no resources in statics).
static var _crowned_list: Array[Dictionary] = []
static var _kinship_list: Array[Dictionary] = []
static var _combo_list: Array[Dictionary] = []
static var _index := {}  # id -> its dictionary (combos first, then Crowned, then Kinships)

static func crowned() -> Array[Dictionary]:
	if _crowned_list.is_empty():
		_crowned_list = _build_crowned()
	return _crowned_list.duplicate()

static func _build_crowned() -> Array[Dictionary]:
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
	if _index.is_empty():
		for c in combos() + crowned() + kinships():
			if not _index.has(c.id):
				_index[c.id] = c
	return _index.get(id, {})

# Kinships (tower_design.md "Kinships"; Tower Code's Kinships.KINSHIPS: id -> [name, line, branch A,
# branch B, …]): two branches of one family side by side, each borrowing a trait from the other.
# What they borrow, in the players' words ({tokens} = status names):
const KINSHIP_TEXT := {
	&"slumber_rot": "Driftspore's puffs add 1 {drowsy}; Bloomcap's clouds add 1 {spored} per tick.",
	&"rainfog": "Rain Lily's splashes leave a fog patch; the fog deals Rain Lily's splash damage to nightmares entering it.",
	&"storm_beacon": "Stormcap's jumps leave nightmares {marked} for 2 s; Lanternmoth's shots add 1 {static}.",
	&"hammer_and_anvil": "Mossback gains the sniper's eye (+10% crit chance at ×2.5); Standing Stone deals ×2 to {marked} nightmares.",
	&"snare": "Rootcurl's pulls end in a 0.5 s hold; Tangleroot's holds drag the nightmare back half a tile.",
	&"night_chimes": "Chime Stone's pulses Catch nightmares at full {drowsy}, as if a Dreamcatcher stood by; Dreamcatcher's threads set off {static} at 3 stacks.",
	&"old_growth": "Nightmares dispelled inside Elder Stump's aura drop +25% Dew; Dewcatcher gains a small aura: neighbors attack 10% faster.",
	&"flock_together": "Wren's Nest hits strip a buff (a shell chips twice as fast, a Weeper stops mending, Omen boosts fall away) and the robbed nightmare drops +1 Dew; Magpie Perch hunts the fastest nightmare, +25% vs Phantoms.",
	# Branch expansion's named pairs (Phase 1 and 2; full game only), checked against BranchKit.
	&"crusted_brood": "1 in 4 of Lichenling's shots also hatches a {spore_sprite} on its target (half a burst); Brood Cap's {spore_sprites} also chip 5% of a {dread_shell}.",
	&"eye_of_the_storm": "Nightmares under Cloudlet's cloud are linked by a {current} at 10% (up to 6); Undercurrent's whirlpool is rained on and leaves nightmares {damp}.",
	&"fireworks_fence": "Every 2 s a nightmare on the Jarlinks' {arc} sets off a 2-spark burst at half spark damage; a Sparkler burst landing on an {arc} bursts once more, at half.",
	&"vespers": "Silver Bell's toll also leaves its target {silenced} for 2 s; a nightmare a Hushbell leaves {silenced} gains 1 {drowsy}.",
	&"fault_line": "Rampart's blows and Bastion's rocks crack the path (no sprints there for 3 s); Quaker's slam runs along the stone walls touching the Rampart, hitting the path beside each.",
	&"bramble_bed": "Flyers Groundroot drags down land in thorns (one thorn tick); Thorncoil's thorns reach flyers passing over its range.",
	&"nursery_bond": "A Sprout from the Seedbearer planted beside the Nurse Log arrives at rank I; Wardens beside the Nurse Log also grow 10% cheaper.",
	# The 9 hidden Kinships (a hidden branch first; full game only, Tower Code 6ba79b8).
	&"spore_nursery": "Fairy Ring's rings apply double {spored}; Driftspore's puffs plant a mushroom ring where they land (one at a time).",
	&"hoar_fog": "Frostfern's shots leave a fog puff; Mistveil's fog freezes nightmares that stay in it 2 s.",
	&"sunspot": "Sunpetal's beam makes its target {marked}; Lanternmoth's shots grow +10% per hit on the same target (up to +50%).",
	&"spotter": "Cairn lobs at the Standing Stone's target and the landing crits; Standing Stone's shots splash 30% beside the target.",
	&"lantern_roots": "Rootlight's lit tiles hold a nightmare stepping on them for 0.3 s (once); Tangleroot's holds reveal {hidden} nightmares and stop burrowing.",
	&"resonant_hollow": "Echo Hollow's echoes set off {static} like a chime; Chime Stone's pulses echo once at 30%.",
	&"true_graft": "Graftling copies at 100%; Elder Stump's pulse adds its strongest neighbor's status.",
	&"jewel_thieves": "Every 6th peck steals a nightmare's buff (+1 Dew if there's none); the Magpie pecks twice per swoop.",
	&"tailwind": "Samara's seed carries full stacks; Gust's copies reach nightmares up to 3 cells away.",
	&"dust_devil": "Gust's copies also deal a blade hit; Pinwheel's blades copy statuses (half stacks) onto what they hit.",
}
const KINSHIPS_SCRIPT := "res://scripts/combat/kinships.gd"
const KINSHIP_GROWTH := "Within 2 cells they bond; the bond grows (Blooming at 5 drifts, Old Kin at 10) and both strike in Harmony."

# [{id, name, kind "Kinship", line, a, b (Warden names), text}], or [] before Kinships exist.
static func kinships() -> Array[Dictionary]:
	if _kinship_list.is_empty():
		_kinship_list = _build_kinships()
	return _kinship_list.duplicate()

static func _build_kinships() -> Array[Dictionary]:
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
	if _combo_list.is_empty():
		_combo_list = _build_combos()
	return _combo_list.duplicate()

static func _build_combos() -> Array[Dictionary]:
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

# --- What the Codex covers (screens_ui.md "What the Codex covers") ---------------------------------
# The families you can get in a run: the starting four plus every family planted in the Memory Grove;
# a form a Grove node unlocks (hidden branches, finals, Ascended) only once that node is planted.
# The demo covers its four families' trees (demo_scope.md "Wardens"); dev runs cover everything.
# Combos, Crowned and Kinships are listed once all they need is in scope (in_build).

const DEMO_FAMILIES := ["sporeling", "firefly_jar", "dewdrop", "bellflower"]  # Also the full game's starting four (Bellflower joined 2026-10-01, meta_design.md a3375108)
const TOWER_DIR := "res://resource/tower/"
const DREAM_DIR := "res://resource/dream/"
static var _grove_forms := {}  # Warden id -> the Grove node id whose Dream card unlocks it

static func demo_limited() -> bool:
	return ResultsScreen.is_demo() and not MetaRun.is_dev_run()

# {"all": bool, "families": [base ids], "wardens": {id: true}, "names": {display name: true},
# "statuses": {id: true}} from the profile (`profile` = HeartwoodMemory.load_data(), for tests).
static func scope(profile: Dictionary = {}) -> Dictionary:
	if not demo_limited() and MetaRun.is_dev_run():
		return {"all": true, "families": [], "wardens": {}, "names": {}, "statuses": {}}
	var demo := demo_limited()
	if profile.is_empty() and not demo:
		profile = HeartwoodMemory.load_data()
	var families: Array = DEMO_FAMILIES.duplicate()
	var planted := {}
	if not demo:
		for unlock in HeartwoodMemory.load_grove():
			if HeartwoodMemory.node_level(profile, unlock) > 0:
				planted[unlock.id] = true
				for id in unlock.families:
					if not families.has(id):
						families.append(id)
	var forms := grove_forms()
	var wardens := {}
	var names := {}
	var statuses := {}
	var todo: Array = families.map(func(id: String) -> Resource: return load(TOWER_DIR + id + ".tres") if ResourceLoader.exists(TOWER_DIR + id + ".tres") else null)
	while not todo.is_empty():
		var data := todo.pop_back() as TowerData
		if data == null or wardens.has(data.get_id()):
			continue
		if not demo and forms.has(data.get_id()) and not planted.has(forms[data.get_id()]):
			continue  # A form its Grove node still keeps (hidden branch, final, Ascended)
		wardens[data.get_id()] = true
		names[data.display_name] = true
		for status in [data.applies_status, data.extra_status]:
			if status != &"":
				statuses[status] = true
		if int(data.get("hold_targets")) > 0:
			statuses[&"held"] = true
		if float(data.get("marked_bonus")) > 0.0:
			statuses[&"marked"] = true
		todo.append_array(data.evolves_to)
	return {"all": false, "families": families, "wardens": wardens, "names": names, "statuses": statuses}

# Warden id -> the Grove node whose Dream card ("dream_<warden>") unlocks it.
static func grove_forms() -> Dictionary:
	if _grove_forms.is_empty():
		for unlock in HeartwoodMemory.load_grove():
			for card_id in unlock.dream_cards:
				var path := DREAM_DIR + card_id + ".tres"
				var card := load(path) as UpgradeData if ResourceLoader.exists(path) else null
				if card != null and card.unlocks != null:
					_grove_forms[card.unlocks.get_id()] = unlock.id
	return _grove_forms

# Whether a combo / Crowned / Kinship entry is covered by `in_scope` (default: the current scope).
static func in_build(entry: Dictionary, in_scope: Dictionary = {}) -> bool:
	var s := in_scope if not in_scope.is_empty() else scope()
	if s.all:
		return true
	match entry.get("kind", ""):
		"Kinship":
			return (not demo_limited() or Kinships.is_available(entry.id)) and s.names.has(entry.a) and s.names.has(entry.b)
		"Crowned":
			if not entry.get("families", []).all(func(id: String) -> bool: return s.families.has(id)):
				return false
	if String(entry.get("by", "")) != "":  # A synergy: one of its Wardens is in scope
		return Array(String(entry.by).split(", ")).any(func(name: String) -> bool: return s.names.has(name))
	return entry.get("statuses", []).all(func(status: StringName) -> bool: return s.statuses.has(status))

static func get_combo(id: StringName) -> Dictionary:
	var found := get_any(id)  # The one index (combos come first in it)
	return found if found.get("kind", "") in ["Synergy", "Reaction"] else {}

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
# The full game's branch expansion (the demo has its old branches and no Whole Tree): left out of the demo's glossary.
const EXPANSION_TERMS := ["Whole Tree", "Not in this dream", "Current", "Erosion", "Arc", "Ink", "Spore-sprite"]
static var _glossary_expansion := true

# The glossary with today's status names and IconInfo's definitions filled in (built once, again
# if the Sapling is switched on or off).
static func glossary() -> Array:
	if _glossary_sapling != TowerPlacer.sapling_enabled or _glossary_expansion != DreamState.branch_expansion_on():
		_glossary = []
		_glossary_sapling = TowerPlacer.sapling_enabled
		_glossary_expansion = DreamState.branch_expansion_on()
	if _glossary.is_empty():
		for group in GLOSSARY_SOURCE:
			var entries: Array = []
			for entry in group[1]:
				if not TowerPlacer.sapling_enabled and SAPLING_TERMS.has(entry[0]):
					continue
				if not _glossary_expansion and EXPANSION_TERMS.has(entry[0]):
					continue  # The demo keeps today's branches: no branch-expansion terms
				var text: String = entry[1]
				if text.begins_with("{tip:"):
					text = IconInfo.STATUSES.get(StringName(text.trim_prefix("{tip:").trim_suffix("}")), ["", ""])[1]
				entries.append([IconInfo.format(entry[0]), IconInfo.format(text),
					entry[2].map(func(s: String) -> String: return IconInfo.format(s)),
					_example(entry)])  # [3]: one muted example line
			if group[0] == "Damage types":
				entries.append_array(damage_type_entries(entries))
			if not entries.is_empty():  # The demo's "Branch effects" is empty
				_glossary.append([group[0], entries])
	var out: Array = _glossary
	var signatures := signature_entries()
	if not signatures.is_empty():
		out = out + [["Signatures", signatures]]
	var callouts := callout_entries()
	if not callouts.is_empty():
		out = out + [["Combat callouts", callouts]]
	return out

# Rank V signatures (warden_stats.md 96d728dd; 8e32e3f8, user: "don't hint towards signatures"): nothing in the
# glossary until the profile's first discovery (CombatCallouts writes SIGNATURES_SEEN_KEY); then what a signature is,
# and each one by name once found, "???" until then (like undiscovered combos).
const SIGNATURES_SEEN_KEY := "signatures_seen"
# What each signature answers, for its found entry (warden_stats.md ff93b498).
const SIGNATURE_ANSWERS := {&"crushing": "armour", &"watchtower": "hidden nightmares", &"relentless": "swarms",
	&"spreading": "dense waves", &"executioner": "big crowds of normal nightmares (its price: all its hits deal 15% less)",
	&"firstborn": "long drifts and the economy", &"shelter": "bosses that wither, dim or trample", &"surge": "burst moments"}

static func signature_entries() -> Array:
	var seen: Array = HeartwoodMemory.load_data().get(SIGNATURES_SEEN_KEY, [])
	if seen.is_empty():
		return []
	var out: Array = [["Signature", "A Warden at rank V with 3 or more of its ranks I–V on one Nurture choice gains that choice's signature, a new behaviour (the gold mark after its picks).",
		["Nurture choice", "Rank"], ""]]
	for sig in Signatures.NAMES:
		if not seen.has(String(sig)):
			out.append(["???", "Not discovered yet.", ["Signature"], ""])
			continue
		var choice = Signatures.BY_CHOICE.find_key(sig)
		var by: String = Tower.FOCUS_NAMES.get(choice, "?") if choice != null else "?"
		var text: String = Signatures.TEXT.get(sig, "")
		var answers: String = SIGNATURE_ANSWERS.get(sig, "")
		out.append([String(Signatures.NAMES[sig]), "%s majority: %s.%s" % [by, text.left(1).to_upper() + text.substr(1),
			(" Answers %s." % answers) if answers != "" else ""], ["Signature", "Nurture choice"], ""])
	return out

# One entry per damage type, with who deals it, from the data (IconInfo.DAMAGE_TYPES + LINE_FAMILIES):
# "Spore: the Sporeling family's damage." Types already written by hand (Talon) are kept as they are.
static func damage_type_entries(existing: Array) -> Array:
	var out: Array = []
	for line in IconInfo.DAMAGE_TYPES:
		var name := IconInfo.damage_type_name(line)
		if existing.any(func(e: Array) -> bool: return e[0] == name):
			continue
		var family: String = LINE_FAMILIES.get(line, "")
		var who := "the %s family" % FAMILY_NAMES.get(family, family.capitalize()) if family != "" else "some Wardens"
		out.append([name, "%s damage, dealt by %s. Some nightmares resist it, others are weak to it." % [name, who],
			["Damage type", "Resists and Weak to"], ""])
	return out

# Combat callouts (screens_ui.md, user: "been seeing 'Shattered' but don't know what it means"): every
# word that pops over nightmares gets a plain line, linking to its Codex combo. An entry shows once
# its callout has been seen on this profile (callouts_seen; Reactions: combos_seen), so it never
# spoils a "???" combo. "Resisted" and "Weak" are basics: always there.
const CALLOUT_SEEN_KEY := "callouts_seen"
const CALLOUT_ENTRIES := [
	# [callout id, entry name, line, related]
	[&"crit", "Critical", "A critical hit: the Warden's hit landed for extra damage (its crit chance is on the Warden panel). Not the Shatter Reaction (\"Shatter!\").", ["Crit"]],
	[&"conducted", "Conducted", "Lightning through {damp}: bolts jump farther and more often between {damp} nightmares (the Conducted combo).", ["Conducted"]],
	[&"asleep", "Asleep", "Full {drowsy}: the nightmare falls asleep for a moment; a big hit wakes it (the Asleep combo).", ["Asleep"]],
	[&"weak", "Weak", "A hit from a family this nightmare is weak to: ×1.5 damage (the sparkle).", []],
	[&"resisted", "Resisted", "A hit from a family this nightmare resists: ×0.5 damage (the gray puff).", []],
]
const ALWAYS_SHOWN := [&"weak", &"resisted"]

static func callout_entries() -> Array:
	var profile := HeartwoodMemory.load_data()
	var seen: Array = profile.get(CALLOUT_SEEN_KEY, [])
	var combos: Array = profile.get("combos_seen", []) + profile.get("reactions_seen", [])
	var entries: Array = []
	for entry in CALLOUT_ENTRIES:
		if ALWAYS_SHOWN.has(entry[0]) or seen.has(String(entry[0])) or combos.has(String(entry[0])):
			entries.append([entry[1], IconInfo.format(entry[2]), entry[3]])
	# Each Reaction's callout, once that Reaction has been discovered.
	for reaction in Reactions.all() + Reactions.crowned():
		if combos.has(String(reaction.id)):
			entries.append([reaction.display_name, IconInfo.format(reaction.description), [reaction.display_name]])
	return entries

# The glossary's one-line definition of `term` ("" if it has none): the popup of a linked game term.
# A glossary entry's muted line: the nightmares that carry the term ({nightmare:} tokens, linked where it's shown), then
# its own example.
static func _example(entry: Array) -> String:
	var parts: Array[String] = []
	var carried := nightmares_line(entry[0])
	if carried != "":
		parts.append(carried)
	if entry.size() > 3 and entry[3] != "":
		parts.append(IconInfo.format(entry[3]))
	return " ".join(parts)

# Terms some nightmares carry (user: "the nightmares that wear a dread shell" as links, read from the data, never typed):
# glossary name -> the line's wording. term_nightmares() reads each kind's EnemyData.
const NIGHTMARE_TERMS := {"dread shell": "Worn by %s.", "flying": "Nightmares: %s.", "hidden": "Nightmares: %s.", "burrow": "Nightmares: %s.",
	"laps": "Nightmares: %s."}

static func term_nightmares(term: String) -> Array[String]:
	var kinds: Array[String] = []
	var key := term.to_lower()
	if not NIGHTMARE_TERMS.has(key):
		return kinds
	for data in NightmareCodex.all_kinds():
		var has := false
		match key:
			"dread shell":
				has = data.coat_total > 0 or data.coat_per_hit > 0
			"flying":
				has = data.trait_kind == EnemyData.Trait.FLYING
			"hidden":
				has = data.hidden
			"burrow":
				has = data.trait_kind == EnemyData.Trait.BURROW
			"laps":
				has = data.laps()
		if has:
			kinds.append(NightmareCodex.kind_of(data))
	return kinds

# "Worn by {nightmare:shellbound}." for a term in NIGHTMARE_TERMS ("" otherwise): tokens, so StatusLinks links them.
static func nightmares_line(term: String) -> String:
	var kinds := term_nightmares(term)
	if kinds.is_empty():
		return ""
	return NIGHTMARE_TERMS[term.to_lower()] % ", ".join(kinds.map(func(kind: String) -> String: return "{nightmare:%s}" % kind))

static func definition(term: String) -> String:
	for group in glossary():
		for entry in group[1]:
			if entry[0].to_lower() == term.to_lower():
				return entry[1]
	return ""

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
				if _term_patterns.is_empty():
					UiStyle.release_at_exit(func() -> void: _term_patterns.clear())
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

# --- Discovered or "???" everywhere (screens_ui.md "Undiscovered combos are ??? everywhere") -------
# Any list of a Warden's or family's combos (Codex Families, Remember side panel, Warden panel,
# placement links, Grove node cards, rest report) shows an undiscovered combo as "???": no name,
# statuses or hints. Discovered = in the profile or found this session (ComboFeedback.load_seen).

static func is_discovered(id: StringName, seen: Array = []) -> bool:
	var list := seen if not seen.is_empty() else ComboFeedback.load_seen()
	return list.has(String(id))

# The entry's name once discovered, "???" before (for lists; the Codex has its own locked cards).
static func combo_name(entry: Dictionary, seen: Array = []) -> String:
	return String(entry.get("name", "")) if is_discovered(entry.get("id", &""), seen) else "???"

# The combo (synergy or Reaction) a status → payoff Warden link stands for, or {}.
static func combo_for_link(status: StringName, payoff: TowerData) -> Dictionary:
	for entry in combos():
		if String(entry.get("by", "")) != "":
			if Array(String(entry.by).split(", ")).has(payoff.display_name) and entry.statuses.has(status):
				return entry
	for entry in combos():
		if entry.kind == "Reaction" and entry.statuses.has(status) and payoff.applies_status != &"" \
				and entry.statuses.has(payoff.applies_status):
			return entry
	return {}

# --- Discovery unlocks (dream_design.md "Discovery unlocks") ---------------------------------------
# The Dream cards a discovery lets into the pool, by their `discovered_by` key ("reaction:thunderclap",
# "crowned:tempest", "kinship:any"). The Codex lists them under a discovered entry; an undiscovered one
# stays "???" (it names nothing).
static var _dreams_by_key := {}

static func dreams_for(key: String) -> Array[String]:
	if _dreams_by_key.is_empty():
		for file in ResourceLoader.list_directory(DREAM_DIR):
			if not file.ends_with(".tres"):
				continue
			var card := load(DREAM_DIR + file) as UpgradeData
			if card == null:
				continue
			for k in card.get("discovered_by") if card.get("discovered_by") != null else []:
				if not _dreams_by_key.has(k):
					_dreams_by_key[k] = []
				_dreams_by_key[k].append(card.display_name)
	var names: Array[String] = []
	names.assign(_dreams_by_key.get(key, []))
	return names

# The key an entry's discovery counts as ("" for synergies: no cards wait on them).
static func discovery_key(entry: Dictionary) -> String:
	match entry.get("kind", ""):
		"Reaction": return "reaction:" + String(entry.id)
		"Crowned": return "crowned:" + String(entry.id)
		"Kinship": return "kinship:any"
	return ""
