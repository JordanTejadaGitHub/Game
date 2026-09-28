extends RefCounted
class_name DreamSimPolicy

# The balance bot's choices for Dreams, family picks, Dreamlight and Omens
# (documentation/balance_simulation.md "Bot rules"), on top of DreamState.sim_rest / sim_family_pick.
# Tower Code's runner owns the maze and spending; this only chooses.
#
#   var policy := DreamSimPolicy.new(dream_state, DreamSimPolicy.Style.BALANCED)
#   policy.family_pick(&"first")        # after drift 1, and &"boss" before each boss rest
#   policy.rest(drift, perfect)         # each rest: the Dream, then Dreamlight
#
# Dreams: the highest style score (tag match first, then rarity); never lets one pass.
# Family picks: the style's families in order, then the owed half-dreamed family, then any.
# Dreamlight: the next form (branch → its finals → the other branch → Ascended) of the family with
# the most Wardens on the map (Wide also counts its Thornwalls and may grow them). Omens: Clear Skies.

enum Style { BALANCED, WIDE, NARROW, COMBO, SLEEP }

# Tag scores per style (a card sums its tags; in-build cards get IN_BUILD on top).
const TAG_SCORES := {
	Style.BALANCED: {"maze": 1.0, "reaction": 1.0, "crit": 1.0, "economy": 0.5},
	Style.WIDE: {"wide": 3.0, "sprout": 2.0, "wall": 2.0, "maze": 1.0, "economy": 1.0, "narrow": -3.0, "nurture": -2.0},
	Style.NARROW: {"narrow": 3.0, "nurture": 3.0, "crit": 1.0, "wide": -3.0, "sprout": -1.0},
	Style.COMBO: {"reaction": 3.0, "kinship": 1.0, "potency": 1.0, "status": 1.0},
	Style.SLEEP: {"sleep": 3.0, "song": 3.0, "status": 1.0, "reaction": 1.0},
}
const IN_BUILD := 2.0
const COMBO_ENTWINED := 3.0  # Combo: Entwined / Woven cards
const COMBO_HALF_DREAMED := 2.0  # Combo: a half-dreamed card is a lead, not a dead pick
const HALF_DREAMED := -1.0  # Other styles: a card that sleeps for now
# Family order per style (the first offered one is taken); Combo picks by combo cards instead.
const FAMILIES := {
	Style.BALANCED: ["sporeling", "firefly_jar", "dewdrop", "pebbling", "acorn", "rootling", "nestling", "samara", "bellflower"],
	Style.WIDE: ["sporeling", "acorn", "rootling", "samara", "dewdrop", "firefly_jar", "pebbling", "nestling", "bellflower"],
	Style.NARROW: ["firefly_jar", "pebbling", "nestling", "dewdrop", "sporeling", "acorn", "rootling", "samara", "bellflower"],
	Style.COMBO: [],
	Style.SLEEP: ["bellflower", "dewdrop", "sporeling", "firefly_jar", "pebbling", "acorn", "rootling", "nestling", "samara"],
}

var dreams: DreamState
var style: Style
var choices: Array[String] = []  # What the bot chose, one line each (for the runner's CSV / summary)

func _init(dream_state: DreamState, play_style: Style = Style.BALANCED) -> void:
	dreams = dream_state
	style = play_style

# --- Dreams ---------------------------------------------------------------------------------------

func score(card: UpgradeData) -> float:
	var tags: Dictionary = TAG_SCORES[style]
	var value := 0.0
	for tag in card.tags:
		value += tags.get(tag, 0.0)
	if dreams.is_in_build(card):
		value += IN_BUILD
	if dreams.is_half_dreamed(card):
		value += COMBO_HALF_DREAMED if style == Style.COMBO else HALF_DREAMED
	if style == Style.COMBO and card.entwined:
		value += COMBO_ENTWINED
	return value * 10.0 + card.rarity  # Tag match first, then rarity

# The card to take from `offer` (never null: the bot never lets a Dream pass).
func pick_dream(offer: Array) -> UpgradeData:
	var best: UpgradeData = null
	for card in offer:
		if best == null or score(card) > score(best):
			best = card
	return best

# The rest after `drift`: its Dream, then Dreamlight. Returns the cards taken.
func rest(drift: int, perfect: bool = true) -> Array[UpgradeData]:
	var taken := dreams.sim_rest(drift, pick_dream, perfect)
	for card in taken:
		choices.append("drift %d: Dream %s" % [drift, card.id])
	spend_dreamlight()
	return taken

# --- Family picks -----------------------------------------------------------------------------------

func pick_family(offered: Array) -> StringName:
	var owed: Array[String] = dreams._owed_families
	if style == Style.COMBO:
		var best := ""
		var best_count := -1
		for id in offered:
			var count := _combo_cards_with(id)
			if count > best_count:
				best_count = count
				best = id
		return StringName(best)
	for id in FAMILIES[style]:
		if offered.has(id):
			return StringName(id)
	for id in owed:
		if offered.has(id):
			return StringName(id)
	return StringName(offered[0]) if not offered.is_empty() else &""

func family_pick(kind: StringName) -> StringName:
	var chosen := dreams.sim_family_pick(kind, pick_family)
	choices.append("family pick (%s): %s" % [kind, chosen])
	spend_dreamlight()
	return chosen

# Combo cards (cross-family `requires`) that `family` would complete with a family already owned.
func _combo_cards_with(family: String) -> int:
	var count := 0
	for card in dreams.pool:
		var families := dreams._combo_families(card)
		if families.size() >= 2 and families.has(family) \
				and families.keys().any(func(f: String) -> bool: return f != family and dreams.is_unlocked(f)):
			count += 1
	return count

# --- Dreamlight ---------------------------------------------------------------------------------------

# Unlocks forms while Dreamlight lasts: the next form of the family with the most Wardens on the map
# (ties: the first owned family in the Remember order).
func spend_dreamlight() -> void:
	var trees := dreams.get_remember_trees().filter(func(tree: Array) -> bool:
		return dreams.family_of(tree[0].get_id()) != "" \
			or (style == Style.WIDE and tree[0].get_id() == "thornwall"))  # Families; Wide also grows its walls
	if trees.is_empty():
		return
	var counts := {}
	for tower in dreams._towers():
		var family := dreams.family_of(tower.tower_data.get_id())
		if family == "" and tower.tower_data.line == "wall":
			family = "thornwall"  # Wide: Thornwall growths compete by how many walls stand
		if family != "":
			counts[family] = int(counts.get(family, 0)) + 1
	trees.sort_custom(func(a: Array, b: Array) -> bool:
		return int(counts.get(a[0].get_id(), 0)) > int(counts.get(b[0].get_id(), 0)))
	for tree in trees:
		for form in _forms_in_order(tree):
			var cost := dreams.get_unlock_cost(form)
			if cost == 0 or dreams.get_unlock_blocker(form) != "":
				continue  # Owned, or not open yet (Memory Grove, Ascended before drift 51…)
			if dreams.dreamlight < cost or not dreams.unlock_with_dreamlight(form):
				return  # Save up for the next form of this family
			choices.append("Dreamlight: %s" % form.get_id())

# A Remember tree's forms, cheapest path first: each branch then its finals, then Ascended.
func _forms_in_order(tree: Array) -> Array[TowerData]:
	var forms: Array[TowerData] = []
	for branch in tree[1]:
		forms.append(branch[0])
		for final in branch[1]:
			forms.append(final)
	if tree.size() > 2 and tree[2] != null:
		forms.append(tree[2])
	return forms

# --- Omens ------------------------------------------------------------------------------------------

# The baseline takes Clear Skies (no Omen).
func pick_omen(_offer: Array) -> OmenData:
	return null
