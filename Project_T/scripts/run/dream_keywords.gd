extends RefCounted
# Keyword chips (owner 2026-10-16; council D:\Projects\logs\dream_council\keyword_chips_decisions.md, _draft, _td, _player):
# a small shared vocabulary shown on Dream cards, Calling evolutions and Wardens as "Makes X" / "Uses X" chips, so a
# player finds a combo by reading two chips that match. Data and lookups only: the chip row, popover and Codex section
# are UI work (Main Merger / UI / Mobile UI). Chips never feed an offer (no weighting, no "Combos with").
#
# Ids: the 13 keywords below, and the 7 status words (player words: &"poisoned", &"charged", &"soaked", &"drowsy",
# &"exposed", &"rooted", &"asleep"; the same ids KeywordIcons draws). Each keyword means one code event:
#   Repeat  a hit that lands again reaches Tower.note_repeat_hit (or a real attack / hit() again)
#   Jump    DreamState.note_jump (Firefly forks, chain Wardens' hops, Conductive Soil, Tangled Lightning)
#   Area    a hit through Tower.hit(is_area = true): pulses, splashes, clouds, rings
#   Linger  EnemyStatuses.is_lingering (linger / top_up / pending_linger / note_stretched; the Bound pause)
# Authoring rules (decisions file): at most 2 chips per card, counting the derived ones; a Uses chip names an umbrella
# keyword only if the card accepts everything under it, else the exact status; a card that strengthens X and does
# nothing without X is "Uses X"; Uses that follow from requires_role / requires_status are derived here, never written in
# the card's `uses` (a hand duplicate fails tests/test_keyword_chips.gd).
#
# Preloaded as DreamState.KEYWORDS (no class_name). Use: `const DreamKeywords := preload("res://scripts/run/dream_keywords.gd")`
#   DreamKeywords.chips_for_card(card)      -> [{id, kind: &"uses"|&"makes", label}]  (uses first, then makes)
#   DreamKeywords.chips_for_tower(tower)    -> the same for a planted Warden (its attack_data: a Graftling's copy counts)
#   DreamKeywords.chips_for_warden(data)    -> the same for a TowerData (build ghost, Codex)
#   DreamKeywords.chips_for_calling(id)     -> the same for a Calling evolution id (calling_paths.gd PATHS)
#   DreamKeywords.glossary(id)              -> {name, text} (text uses card tokens; IconInfo.format renders them)
#   DreamKeywords.label(id)                 -> the chip's word ("Jump", "Rooted")

const MAKES := &"makes"
const USES := &"uses"
const MAX_CHIPS := 2

const KEYWORDS: Array[StringName] = [&"stacks", &"linger", &"jump", &"repeat", &"reaction", &"layered", &"slow", &"crit",
	&"area", &"heavy", &"cluster", &"rank", &"maze"]
# Status words -> EnemyStatuses ids (&"asleep" is a state, not a status id: EnemyStatuses.is_asleep()).
const STATUSES := {&"poisoned": &"spored", &"charged": &"static", &"soaked": &"damp", &"drowsy": &"drowsy",
	&"exposed": &"marked", &"rooted": &"held", &"asleep": &"asleep"}
# Umbrella keywords and the status words under them: a maker of a member also makes the umbrella; Slow's users are the
# cards that name the exact state (decisions: "Uses Rooted", "Uses Asleep").
const MEMBERS := {&"slow": [&"rooted", &"asleep"]}

# The glossary: one line each, at most 12 words (decisions file), card tokens allowed.
const WORDS := {
	&"stacks": {"name": "Stacks", "text": "A status gets extra {stacks}, or fills faster."},
	&"linger": {"name": "Duration", "text": "Statuses last longer, or come back after they end."},
	&"jump": {"name": "Jumps", "text": "Damage {jumps} from one nightmare to others nearby."},
	&"repeat": {"name": "Repeats", "text": "A hit, attack or effect happens again."},
	&"reaction": {"name": "Reactions", "text": "Two statuses on one nightmare go off together. Any two can."},
	&"layered": {"name": "Mixed statuses", "text": "One nightmare carrying several different statuses at once."},
	&"slow": {"name": "Slows", "text": "A nightmare is slowed, stopped or pulled back: {held}, {asleep}, {frozen}, {caught}."},
	&"crit": {"name": "Crits", "text": "Hits that sometimes deal much more damage."},
	&"area": {"name": "Area", "text": "Pulses, splashes and clouds: attacks that hit many nightmares."},
	&"heavy": {"name": "Heavy hits", "text": "{heavy} Wardens: slow attacks with big single hits."},
	&"cluster": {"name": "Clusters", "text": "Your Wardens close together: touching, kin, Sprout clusters, auras."},
	&"rank": {"name": "Ranks", "text": "Nurture {ranks}: higher-rank Wardens."},
	&"maze": {"name": "Maze", "text": "The path's length and bends, and the Thornwalls that shape it."},
	&"poisoned": {"name": "Poison", "text": "{spored}: the nightmare takes damage every second."},
	&"charged": {"name": "Charge", "text": "{static}: at {full}, a bolt strikes the nightmare."},
	&"soaked": {"name": "Soak", "text": "{damp}: the nightmare conducts water and lightning."},
	&"drowsy": {"name": "Sleep", "text": "{drowsy}: the nightmare slows, and falls {asleep} at {full}."},
	&"exposed": {"name": "Exposure", "text": "{marked}: built up, the nightmare takes more damage."},
	&"rooted": {"name": "Roots", "text": "{held}: the nightmare cannot move for a moment."},
	&"asleep": {"name": "Asleep", "text": "{asleep}: the nightmare stops until a hit wakes it."},
}

# A Warden's job (WardenRoles) -> the keyword it makes (draft rule 4; TD: chain only now that note_jump exists).
const ROLE_MAKES := {&"heavy": &"heavy", &"area": &"area", &"trap": &"area", &"chain": &"jump", &"hold": &"rooted",
	&"pull": &"slow", &"support": &"cluster"}
# A card's requires_role -> the Uses chip it gets (honesty rule: only roles whose keyword every maker feeds; pull, trap,
# chain, sniper and beam cards read their role only, so they get none).
const ROLE_USES := {&"heavy": &"heavy", &"area": &"area", &"hold": &"rooted", &"support": &"cluster"}
# EnemyStatuses id -> status word.
const STATUS_WORD := {&"spored": &"poisoned", &"static": &"charged", &"damp": &"soaked", &"drowsy": &"drowsy",
	&"marked": &"exposed", &"held": &"rooted", &"asleep": &"asleep"}

static func is_known(id: StringName) -> bool:
	return WORDS.has(id)

static func is_status(id: StringName) -> bool:
	return STATUSES.has(id)

static func label(id: StringName) -> String:
	return String(WORDS[id].name) if WORDS.has(id) else String(id).capitalize()

static func glossary(id: StringName) -> Dictionary:
	var row: Dictionary = WORDS.get(id, {})
	return {"name": row.get("name", label(id)), "text": row.get("text", "")}

# The status word for an EnemyStatuses id (&"" if none).
static func word_for_status(status_id: StringName) -> StringName:
	return STATUS_WORD.get(status_id, &"")

# --- Cards -------------------------------------------------------------------------------------------------------------

# The Uses chips that follow from a card's own Needs (requires_role, requires_status).
static func derived_uses(card: UpgradeData) -> Array[StringName]:
	var out: Array[StringName] = []
	if card == null:
		return out
	if card.requires_role != &"" and ROLE_USES.has(card.requires_role):
		out.append(ROLE_USES[card.requires_role])
	if card.requires_status != &"":
		var word := word_for_status(card.requires_status)
		if word != &"" and not out.has(word):
			out.append(word)
	return out

static func chips_for_card(card: UpgradeData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if card == null:
		return out
	var uses: Array[StringName] = derived_uses(card)
	for id in card.uses:
		if not uses.has(id):
			uses.append(id)
	_add(out, uses, USES)
	_add(out, card.makes, MAKES)
	return out

# --- Wardens -----------------------------------------------------------------------------------------------------------

static func chips_for_tower(tower) -> Array[Dictionary]:
	if tower == null or not is_instance_valid(tower):
		return []
	var data: TowerData = tower.attack_data if tower.attack_data != null else tower.tower_data
	return chips_for_warden(data)

# What a Warden form makes: its role keywords (WardenRoles) and the statuses it applies. Wardens never "use".
static func chips_for_warden(data: TowerData) -> Array[Dictionary]:
	var makes: Array[StringName] = []
	if data == null:
		return []
	for role in WardenRoles.roles(data):
		var id: StringName = ROLE_MAKES.get(role, &"")
		if id != &"" and not makes.has(id):
			makes.append(id)
	for status in [data.applies_status, data.extra_status]:
		var word := word_for_status(status)
		if word != &"" and not makes.has(word):
			makes.append(word)
	var out: Array[Dictionary] = []
	_add(out, makes, MAKES)
	return out

# --- Calling evolutions ------------------------------------------------------------------------------------------------

const CALLING_PATHS := preload("res://scripts/combat/calling_paths.gd")

static func chips_for_calling(id: StringName) -> Array[Dictionary]:
	var row: Dictionary = CALLING_PATHS.PATHS.get(id, {})
	var out: Array[Dictionary] = []
	_add(out, row.get("uses", []), USES)
	_add(out, row.get("makes", []), MAKES)
	return out

# --- Helpers -----------------------------------------------------------------------------------------------------------

static func _add(out: Array[Dictionary], ids: Array, kind: StringName) -> void:
	for id in ids:
		out.append({"id": StringName(id), "kind": kind, "label": label(StringName(id))})

# Whether `id` counts as made by a maker of `made` (Slow is made by a Rooted or Asleep maker too).
static func counts_as(made: StringName, id: StringName) -> bool:
	return made == id or (MEMBERS.has(id) and made in MEMBERS[id])
