extends RefCounted
class_name IconInfo

# One place for the names and plain-words tooltips of every status, Warden stat and resource
# (screens_ui.md "Stat and status icons": every icon explains itself on hover and on tap). Status
# names are under review (e.g. Static → Charged), so every screen reads them from here:
# status_name(id), status_tooltip(id), stat_tooltip(id), resource_tooltip(id). The icon sheet from
# Tower Assets plugs in beside these ids when it lands.

const STATUSES := {
	&"damp": ["Damp", "10% slower. Lightning jumps further between Damp nightmares."],
	&"drowsy": ["Drowsy", "8% slower per stack. Fully Drowsy nightmares can be put to sleep."],
	&"spored": ["Spored", "Spores eat at it over time, more with every stack."],
	&"marked": ["Marked", "Takes 25% more from every Warden."],
	&"static": ["Static", "Charges build up; at 5, a free lightning bolt strikes it."],
	&"held": ["Held", "Can't move for a moment."],
	&"caught": ["Caught", "Asleep or fully Drowsy near a Dreamcatcher: takes extra damage from everything."],
	&"frozen": ["Frozen", "Frost stops it for a moment."],
	&"elite": ["Deeply Blighted", "An elite: 3× health, 2× Dew, and it takes 2 leaves."],
	&"hidden": ["Hidden", "Can't be seen or targeted until something reveals it, or it comes close."],
}
const STATS := {
	&"damage": ["Damage", "How much each hit soothes."],
	&"attack_speed": ["Attack speed", "Attacks per second."],
	&"range": ["Range", "How far it reaches, in tiles."],
	&"crit_chance": ["Crit chance", "The chance a hit is a critical hit."],
	&"crit_damage": ["Crit damage", "How much harder a critical hit lands."],
	&"potency": ["Potency", "Effect damage: scales status and spore damage and Reactions."],
	&"rank": ["Rank", "How nurtured it is (I–V): each rank adds damage, speed and range."],
	&"focus": ["Focus", "Chosen at rank III: Power, Swift, Reach or Deep."],
	&"dew_cost": ["Dew cost", "Dew to plant, grow or nurture it."],
	&"dreamlight_cost": ["Dreamlight cost", "Dreamlight to unlock this form for the run."],
}
const RESOURCES := {
	&"dew": ["Dew", "Spent on Wardens, growth, Nurture and clearing. Earned by dispelling nightmares and at rests."],
	&"dreamlight": ["Dreamlight", "Unlocks branches and final forms on the Remember screen (at rests)."],
	&"leaves": ["Leaves", "The Heartwood's life: a nightmare that reaches it takes leaves. Lose them all and the dream goes dark."],
	&"seeds": ["Seeds", "Earned every run, win or lose; spent in the Memory Grove."],
	&"path": ["Path length", "How many tiles nightmares walk to the Heartwood. Longer is better."],
}

static func status_name(id: StringName) -> String:
	return STATUSES[id][0] if STATUSES.has(id) else String(id).capitalize()

static func status_tooltip(id: StringName) -> String:
	return _tip(STATUSES, id)

static func stat_tooltip(id: StringName) -> String:
	return _tip(STATS, id)

static func resource_tooltip(id: StringName) -> String:
	return _tip(RESOURCES, id)

# "Damp: 10% slower. …"
static func _tip(table: Dictionary, id: StringName) -> String:
	return "%s: %s" % table[id] if table.has(id) else ""
