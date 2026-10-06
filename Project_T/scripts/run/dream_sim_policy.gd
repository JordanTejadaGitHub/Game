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

enum Style { BALANCED, WIDE, NARROW, COMBO, SLEEP, SPROUT, MIXED }  # Append only

# Tag scores per style (a card sums its tags; in-build cards get IN_BUILD on top).
const TAG_SCORES := {
	# Balanced keeps its 5 opening Sprouts and never clears obstacles: Sprout and clearing cards are last.
	Style.BALANCED: {"maze": 1.0, "reaction": 1.0, "crit": 1.0, "economy": 0.5, "sprout": -1.5, "clearing": -2.0},
	Style.WIDE: {"wide": 3.0, "sprout": 2.0, "wall": 2.0, "maze": 1.0, "economy": 1.0, "narrow": -3.0, "nurture": -2.0},
	Style.NARROW: {"narrow": 3.0, "nurture": 3.0, "crit": 1.0, "wide": -3.0, "sprout": -1.0},
	Style.COMBO: {"reaction": 3.0, "kinship": 1.0, "potency": 1.0, "status": 1.0},
	Style.SLEEP: {"sleep": 3.0, "song": 3.0, "status": 1.0, "reaction": 1.0},
	Style.SPROUT: {"sprout": 3.0, "wide": 2.0, "wall": 1.0, "narrow": -3.0, "nurture": -1.0},
	# Mixed opening: a family plus ~40% Sprouts on Thornwall walls; Balanced, but Sprout cards count.
	Style.MIXED: {"maze": 1.0, "reaction": 1.0, "crit": 1.0, "economy": 0.5, "sprout": 1.5, "clearing": -2.0},
}
const IN_BUILD := 2.0
const COMBO_ENTWINED := 3.0  # Combo: Entwined / Woven cards
# Sprout: the Sprout build's own cards come first (balance_simulation.md "Sprout spam should be a build").
const SPROUT_CARDS: Array[String] = ["seedfall", "sprout_surge", "sprout_chorus", "root_network", "root_network_ii", "seedling_gift", "nursery"]
const SPROUT_TOP := 10.0
const COMBO_HALF_DREAMED := 2.0  # Combo: a half-dreamed card is a lead, not a dead pick
const HALF_DREAMED := -1.0  # Other styles: a card that sleeps for now
# A card whose effect needs what the run doesn't have yet (an unmet soft Need: none of its Warden on
# the map; a Kinship card with no Kinship): a wasted pick for now.
const DEAD_FOR_NOW := -2.0
# Family order per style (the first offered one is taken); Combo picks by combo cards instead.
const FAMILIES := {
	Style.BALANCED: ["sporeling", "firefly_jar", "dewdrop", "pebbling", "acorn", "rootling", "nestling", "whirligig", "bellflower"],
	Style.WIDE: ["sporeling", "acorn", "rootling", "whirligig", "dewdrop", "firefly_jar", "pebbling", "nestling", "bellflower"],
	Style.NARROW: ["firefly_jar", "pebbling", "nestling", "dewdrop", "sporeling", "acorn", "rootling", "whirligig", "bellflower"],
	Style.COMBO: [],
	Style.SLEEP: ["bellflower", "dewdrop", "sporeling", "firefly_jar", "pebbling", "acorn", "rootling", "nestling", "whirligig"],
	Style.SPROUT: ["sporeling", "acorn", "rootling", "whirligig", "dewdrop", "firefly_jar", "pebbling", "nestling", "bellflower"],
	Style.MIXED: ["sporeling", "firefly_jar", "dewdrop", "pebbling", "acorn", "rootling", "nestling", "whirligig", "bellflower"],
}

var dreams: DreamState
var style: Style
var choices: Array[String] = []  # What the bot chose, one line each (for the runner's CSV / summary)

func _init(dream_state: DreamState, play_style: Style = Style.BALANCED) -> void:
	dreams = dream_state
	style = play_style

# --- Dreams ---------------------------------------------------------------------------------------

var score_overrides := {}  # Card id -> fixed score (the runner's --card-score=id=value; e.g. a card scored like an untagged Common = 0)
# --card-value (Balancing 2026-10-06): the score also counts the card's size as a damage-equivalent % (DE) × DE_WEIGHT.
# DE_WEIGHT puts Deeper Calm (+25%) at +30, level with an in-build tagged card ((1 tag + IN_BUILD 2) × 10). Tag terms stay.
var card_value := false
const DE_WEIGHT := 1.2
const DEW_PER_DE := 10.0  # Economy: ~10 Dew = 1% damage
const DEW_HORIZON := 10  # Economy cards count the Dew of the next 10 drifts
# Rule cards without stat fields: a first estimate of their DE on the balanced bot's board, before the board share
# (the share is applied in card_de). Unlisted rule cards = 0 (tags only, as before).
const RULE_DE := {
	"old_growth": 25.0, "first_light": 20.0, "heart_of_the_maze": 5.0, "thinning_the_herd": 10.0,
	"lantern_glow": 12.0, "lone_hunter": 13.0, "cozy_corners": 12.0, "momentum": 15.0, "head_start": 0.0,
	"last_breath": 8.0, "glinting_dew": 20.0, "flurry": 20.0, "first_frost": 1.0, "quick_step": 0.0, "call_of_the_wild": 0.0,
	"deep_roots": 5.0, "thick_bark": 5.0, "lucid_dream": 10.0, "heartwoods_reach": 0.0,
	# × a board share in card_de:
	"odd_one_out": 45.0, "solitude": 45.0, "crowd_breaker": 20.0, "overlap": 40.0, "root_network": 30.0,
	"lasting_dreams": 15.0, "passing_dream": 8.0, "bitter_sap": 15.0, "sparking_spores": 10.0, "wildfire_spores": 10.0,
	"live_wire": 10.0, "static_field": 10.0, "mycelium": 10.0,
}

func score(card: UpgradeData) -> float:
	if score_overrides.has(card.id):
		return score_overrides[card.id]
	return _tag_score(card) + (DE_WEIGHT * card_de(card) if card_value else 0.0)

# The card's damage-equivalent % on the board as it stands (--card-value).
func card_de(card: UpgradeData) -> float:
	var attackers := dreams._towers().filter(func(t: Tower) -> bool: return t.tower_data.can_attack)
	var n := maxf(attackers.size(), 1.0)
	var share := func(pred: Callable) -> float: return attackers.filter(pred).size() / n
	var de := 100.0 * (card.soothe_bonus + card.attack_speed_bonus) + 30.0 * card.range_bonus + 30.0 * card.potency_bonus \
		+ 20.0 * card.splash_bonus
	if card.stat_warden != "":
		de *= share.call(func(t: Tower) -> bool: return t.tower_data.get_id() == card.stat_warden)
	elif card.stat_line != "":
		de *= share.call(func(t: Tower) -> bool: return t.tower_data.line == card.stat_line)
	# Economy: Dew over the next DEW_HORIZON drifts (about 2 rests), ÷ DEW_PER_DE
	var dew := card.dew_now + 2.0 * card.rest_bonus_add + card.evolve_discount * 150.0 + card.nurture_discount * 100.0 \
		+ card.plant_discount * 100.0
	match card.id:
		"morning_dew": dew += 60.0  # +10% of ~600 Dew of pots
		"dew_line": dew += 60.0
		"winding_path": dew += 30.0
		"weathered_walls": dew += 20.0
		"tender_care": dew += 25.0 * n  # Every Warden's first rank (25 Dew) free
		"sudden_insight": de += 10.0  # 2 Dreamlight ≈ a branch soon
	de += dew / DEW_PER_DE
	var rule: float = RULE_DE.get(card.id, 0.0)
	match card.id:
		"thorny_walls":  # A Sprout's damage (~5 per 2 s) per wall with a nightmare beside it about half the time
			rule = 1.0 * dreams._towers().filter(func(t: Tower) -> bool: return t.tower_data.line == "wall").size()
		"odd_one_out":
			var kinds := {}
			for t in attackers:
				kinds[t.tower_data.get_id()] = int(kinds.get(t.tower_data.get_id(), 0)) + 1
			rule *= share.call(func(t: Tower) -> bool: return kinds[t.tower_data.get_id()] == 1)
		"solitude":
			rule *= share.call(func(t: Tower) -> bool: return not attackers.any(func(o: Tower) -> bool:
				return o != t and o.cell.distance_to(t.cell) <= 2.0))
		"crowd_breaker", "overlap":
			rule *= share.call(func(t: Tower) -> bool: return t.tower_data.splash_radius > 0.0 \
				or t.tower_data.attack_kind in [TowerData.AttackKind.PULSE, TowerData.AttackKind.CLOUD, TowerData.AttackKind.SPIN, TowerData.AttackKind.SWEEP])
		"root_network":
			rule *= share.call(func(t: Tower) -> bool: return t.tower_data.get_id() == "sprout")
		"lasting_dreams", "passing_dream", "bitter_sap":
			rule *= share.call(func(t: Tower) -> bool: return t.tower_data.applies_status != &"")
		"sparking_spores", "wildfire_spores", "mycelium":
			rule *= share.call(func(t: Tower) -> bool: return t.tower_data.line == "spore")
		"live_wire", "static_field":
			rule *= share.call(func(t: Tower) -> bool: return t.tower_data.applies_status == &"static")
	return de + rule

func _tag_score(card: UpgradeData) -> float:
	var tags: Dictionary = TAG_SCORES[style]
	var value := 0.0
	for tag in card.tags:
		value += tags.get(tag, 0.0)
	if dreams.is_in_build(card):
		value += IN_BUILD
	if dreams.is_half_dreamed(card):
		value += COMBO_HALF_DREAMED if style == Style.COMBO else HALF_DREAMED
	if not dreams.soft_needs_met(card) or (card.tags.has("kinship") and dreams.count_kinships() == 0):
		value += DEAD_FOR_NOW
	if style == Style.SPROUT and SPROUT_CARDS.has(card.id):
		value += SPROUT_TOP
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
	_last_block_clean = perfect
	var taken := dreams.sim_rest(drift, pick_dream, perfect)
	for card in taken:
		choices.append("drift %d: Dream %s" % [drift, card.id])
	spend_dreamlight()
	return taken

# --- Family picks -----------------------------------------------------------------------------------

func pick_family(offered: Array) -> StringName:
	var owed: Array[String] = []  # The families the bot's half-dreamed cards still miss (picks no longer include them)
	for card in dreams._taken_cards(true):
		for family in dreams.half_dreamed_missing(card):
			if not owed.has(family):
				owed.append(family)
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
			or (style in [Style.WIDE, Style.SPROUT] and tree[0].get_id() == "thornwall"))  # Families; Wide / Sprout also grow walls
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
			cost = dreams.get_unlock_price(form)  # Waking Root's discount (Spire branch)
			if dreams.dreamlight < cost and form.tier >= DreamState.ASCENDED_TIER:
				continue  # Ascended only when affordable: never saved for (it would hold every other form back)
			if dreams.dreamlight < cost or not dreams.unlock_with_dreamlight(form):
				return  # Save up for the next form of this family
			choices.append("Dreamlight: %s" % form.get_id())

# A Remember tree's forms, cheapest path first: each branch then its finals, then Ascended.
# Single-target families unlock their area branch first (design: Mossback / Magpie-first families died
# to act 1 swarms); every other family keeps the Remember order.
func _forms_in_order(tree: Array) -> Array[TowerData]:
	var forms: Array[TowerData] = []
	var branches: Array = tree[1].duplicate()
	var first: String = AREA_FIRST.get(tree[0].get_id(), "")
	for i in branches.size():
		if branches[i][0].get_id() == first:
			branches.push_front(branches.pop_at(i))
			break
	# Ascended right after the first final form (design 0d0642d): while it's still closed (Grove, drift
	# 51) spend_dreamlight skips it and goes on; once open, the family saves up for it first.
	if carry_first:  # The carry branch first (a stable sort: the rest keep their order)
		var carry := branches.filter(func(b: Array) -> bool: return DreamState.is_carry(b[0]))
		branches = carry + branches.filter(func(b: Array) -> bool: return not DreamState.is_carry(b[0]))
	var ascended: TowerData = tree[2] if tree.size() > 2 else null
	if branches_first:  # Kinship placement: two branches before any final form (a Kinship needs two)
		for branch in branches.slice(0, 2):
			forms.append(branch[0])
	for branch in branches:
		if not forms.has(branch[0]):
			forms.append(branch[0])
		for final in branch[1]:
			forms.append(final)
			if ascended != null and not forms.has(ascended):
				forms.append(ascended)
	if ascended != null and not forms.has(ascended):
		forms.append(ascended)
	return forms

const AREA_FIRST := {"pebbling": "cairn", "nestling": "wrens_nest"}  # Cairn's lob splash, Wren's second strike
var branches_first := false  # The runner sets it with Kinship placement on (balance_sim.gd --no-kin keeps the old order)
var carry_first := false  # The runner sets it (--no-carry-pref clears it): the carry branch (DreamState.is_carry) is unlocked first

# --- Omens ------------------------------------------------------------------------------------------

# The baseline takes Clear Skies (no Omen); `face_omens` faces every one and picks the lower-risk of
# the revealed Omens (omen_risk). Pass the result to OmenDirector.choose().
var face_omens := false
# Omens with teeth (run_design.md, the three-way measurement): "clear" Clear Skies always; "always" faces
# every Omen and takes the first revealed; "clean" faces only after a clean block (no leaf lost), taking
# the first revealed. "" = face_omens (the older "face": every Omen, the lower-risk one).
var omen_mode := ""
var _last_block_clean := true  # The block before this rest lost no leaf (rest's `perfect`)

func pick_omen(offer: Array) -> OmenData:
	if offer.is_empty():
		return null
	match omen_mode:
		"clear":
			return null
		"always":
			return offer[0]
		"clean":
			return offer[0] if _last_block_clean else null
	if not face_omens:
		return null
	var best: OmenData = offer[0]
	for omen in offer:
		if omen_risk(omen) < omen_risk(best):
			best = omen
	return best

# A rough danger score for an Omen's twist (0 = harmless): the extra nightmare strength it adds.
static func omen_risk(omen: OmenData) -> float:
	var risk := (omen.health_multiplier - 1.0) + (omen.speed_multiplier - 1.0) * 1.5 + (omen.count_multiplier - 1.0)
	risk += (omen.flyer_count_multiplier - 1.0) * 0.5 + (omen.coat_multiplier - 1.0) * 0.5
	risk += (1.0 - omen.arrival_spacing_multiplier) + (1.0 - omen.warden_attack_speed_multiplier) * 1.5
	risk += (1.0 - omen.status_duration_multiplier) * 0.4 + maxf(1.0 - omen.creature_dew_multiplier, 0.0) * 0.3  # More Dew is no danger
	risk += (1.0 - omen.rest_bonus_multiplier) * 0.2 + (omen.leak_multiplier - 1.0) * 0.5
	risk += -omen.warden_range_add * 0.4 + omen.extra_elites * 0.25 + omen.all_flyer_drifts * 0.1 + omen.sprout_obstacles * 0.03
	risk += 0.3 if omen.no_build_during_drift else 0.0
	risk += 0.1 * omen.status_immune.size() + (0.2 if omen.always_status != &"" else 0.0)
	# Swift Stream (364d8f2f): faster only on straights of straight_speed_cells+, so half the weight of a full speed-up
	var straight = omen.get("straight_speed_multiplier")
	if straight != null:
		risk += (float(straight) - 1.0) * 0.75
	return risk
