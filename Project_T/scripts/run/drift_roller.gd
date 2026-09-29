extends RefCounted
class_name DriftRoller

# Random drifts (run_design.md "Random drifts"): every block's drifts are rolled from the run's seed,
# while the difficulty curve, the teaching and the bosses stay fixed.
#
# The hand-made drifts (resource/drift/demo/drift_NN.tres, acts_1_2.md / acts_3_4.md) stay the
# reference: each rolled drift keeps its hand-made drift's health budget (non-elite nightmares, in
# drift-1 health, see EnemyData.get_roll_cost), its arrival window and its elite entries. Drifts
# 1–FIXED_UNTIL, boss drifts and every nightmare type's intro drift (EnemyData.intro_drift) aren't
# rolled. A type joins the pool only after its intro drift.
#
# Per drift: a template (DriftTemplate, weighted by act) picks a lead type and 1–3 more from the
# pool; the budget is shared (each type ≥ MIN_SHARE) and turned into counts, then checked:
#   - total within ±BUDGET_TOLERANCE of the budget,
#   - no family resisted by more than RESIST_CAP_ACT1 (act 1) / RESIST_CAP of the rolled health
#     (the hand-made elites it keeps are a fixed design choice and aren't counted),
#   - acts 2–4: no block leans on the same resisted family (> LEAN_SHARE) in more than MAX_LEANS drifts,
#   - never all flyers / through-walls, at most one limited template (Swarm, Special) per block,
#     never the same template twice in a row.
# A roll that fails is tried again (the hand-made drift stays if nothing fits).
#
# roll_run() rolls the whole run at once (same seed = same drifts; a resumed run rolls again and
# gets them back). Everything reads DriftDirector.drifts[n - 1], so the Coming strip, dossier,
# Omens and saves see the roll. Omens apply on top, at schedule time, as before.

const TEMPLATE_DIR := "res://resource/drift/template"
const ENEMY_DIR := "res://resource/enemy"
const FIXED_UNTIL := 5  # Drifts 1–5 stay hand-made (the first block teaches the basics)
const MIN_SHARE := 0.15
const BUDGET_TOLERANCE := 0.05
const RESIST_CAP_ACT1 := 0.4
const RESIST_CAP := 0.6
const LEAN_SHARE := 0.3  # A drift "leans" on a resisted family above this share
const MAX_LEANS := 2  # …in at most this many drifts of a block
const ATTEMPTS := 40
const ELITE_COST := 3.0  # Deeply Blighted health (Enemy.ELITE_HEALTH)
const DEFAULT_WINDOW := 20.0  # Arrival window (s) when the hand-made drift has a single arrival
const META_HAND_MADE := &"hand_made_drifts"
const META_TEMPLATE := &"roll_template"

static var _roster: Array[EnemyData] = []
static var _templates: Array[DriftTemplate] = []

# Rolls every rollable drift of the run into director.drifts (a DriftDirector). Deterministic for
# a seed; calling it again rolls from the hand-made drifts again.
static func roll_run(director: Node, seed: int) -> void:
	if not director.has_meta(META_HAND_MADE):
		director.set_meta(META_HAND_MADE, director.drifts.duplicate())
	var hand_made: Array = director.get_meta(META_HAND_MADE)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "drifts"])
	var previous := &""
	var blocks := {}  # block -> {"limited": bool, "leans": {family: drifts}}
	for n in range(1, hand_made.size() + 1):
		director.drifts[n - 1] = hand_made[n - 1]
		if not is_rollable(director, n):
			previous = &""
			continue
		var state: Dictionary = blocks.get_or_add(director.get_block(n), {"limited": false, "leans": {}})
		var rolled := _roll_drift(director, n, hand_made[n - 1], rng, previous, state)
		if rolled != null:
			director.drifts[n - 1] = rolled
			previous = rolled.get_meta(META_TEMPLATE)
		else:
			previous = &""

# Puts the hand-made drifts back (tests, or turning the feature off mid-run).
static func restore(director: Node) -> void:
	if director.has_meta(META_HAND_MADE):
		var hand_made: Array = director.get_meta(META_HAND_MADE)
		for n in hand_made.size():
			director.drifts[n] = hand_made[n]

# False for drifts 1–5, bosses and intro drifts (those stay as written).
static func is_rollable(director: Node, number: int) -> bool:
	if number <= FIXED_UNTIL or director.is_boss_drift(number):
		return false
	for data in get_roster():
		if data.intro_drift == number:
			return false
	return true

# The template a drift was rolled from (&"" if it's hand-made), e.g. for "This block: Swarm, Mixed…".
static func template_of(director: Node, number: int) -> StringName:
	if number < 1 or number > director.drifts.size():
		return &""
	return director.drifts[number - 1].get_meta(META_TEMPLATE, &"")

# The template's display name ("Swarm"), or "" for a hand-made drift.
static func template_name(director: Node, number: int) -> String:
	var id := template_of(director, number)
	for template in get_templates():
		if template.id == id:
			return template.display_name
	return ""

# Types that can be rolled at drift `number`: introduced before it.
static func get_pool(number: int) -> Array[EnemyData]:
	var pool: Array[EnemyData] = []
	for data in get_roster():
		if data.intro_drift > 0 and data.intro_drift < number:
			pool.append(data)
	return pool

# A drift's health budget (drift-1 health of its non-elite, non-boss nightmares).
static func get_budget(drift: DriftData) -> float:
	var budget := 0.0
	for group in drift.groups:
		for entry in group.entries:
			if entry.enemy != null and not entry.enemy.is_boss and not entry.elite:
				budget += entry.count * entry.enemy.get_roll_cost()
	return budget

# Every type with an intro drift (the rollable roster), sorted by intro.
static func get_roster() -> Array[EnemyData]:
	if _roster.is_empty():
		for file in ResourceLoader.list_directory(ENEMY_DIR):
			if file.ends_with(".tres") or file.ends_with(".res"):
				var data := load(ENEMY_DIR.path_join(file)) as EnemyData
				if data != null and data.intro_drift > 0:
					_roster.append(data)
		_roster.sort_custom(func(a: EnemyData, b: EnemyData) -> bool:
			return a.intro_drift < b.intro_drift or (a.intro_drift == b.intro_drift and a.resource_path < b.resource_path))
	return _roster

static func get_templates() -> Array[DriftTemplate]:
	if _templates.is_empty():
		for file in ResourceLoader.list_directory(TEMPLATE_DIR):
			if file.ends_with(".tres") or file.ends_with(".res"):
				var template := load(TEMPLATE_DIR.path_join(file)) as DriftTemplate
				if template != null:
					_templates.append(template)
		_templates.sort_custom(func(a: DriftTemplate, b: DriftTemplate) -> bool: return String(a.id) < String(b.id))
	return _templates


# --- One drift ---------------------------------------------------------------------------------

static func _roll_drift(director: Node, number: int, drift: DriftData, rng: RandomNumberGenerator,
		previous: StringName, state: Dictionary) -> DriftData:
	var act: int = director.get_act(number)
	var pool := get_pool(number)
	var budget := get_budget(drift)
	if pool.is_empty() or budget <= 0.0:
		return null
	var kept_elites: Array = []  # [[EnemyData, count, true]] from the hand-made drift
	for group in drift.groups:
		for entry in group.entries:
			if entry.enemy != null and entry.elite and not entry.enemy.is_boss:
				kept_elites.append([entry.enemy, entry.count, true])
	for attempt in ATTEMPTS:
		var template := _pick_template(rng, act, pool, previous, state)
		if template == null:
			return null
		var mix := _mix(rng, template, pool, budget, RESIST_CAP_ACT1 if act <= 1 else RESIST_CAP)
		if mix.is_empty():
			continue
		# Fairness judges the rolled part: the hand-made elites are a fixed design choice (drift 23's
		# first elites are Husks on purpose).
		var leans: Variant = _leans_if_fair(mix, act, state)
		if leans == null:
			continue
		mix.append_array(kept_elites)
		for family in leans:
			state.leans[family] = state.leans.get(family, 0) + 1
		if template.limited:
			state.limited = true
		return _build(drift, mix, template)
	return null

static func _pick_template(rng: RandomNumberGenerator, act: int, pool: Array[EnemyData], previous: StringName,
		state: Dictionary) -> DriftTemplate:
	var candidates: Array[DriftTemplate] = []
	var total := 0.0
	for template in get_templates():
		if template.get_weight(act) <= 0.0 or template.id == previous or (template.limited and state.limited):
			continue
		if not pool.any(template.can_lead):
			continue
		candidates.append(template)
		total += template.get_weight(act)
	if candidates.is_empty():
		return null
	var pick := rng.randf() * total
	for template in candidates:
		pick -= template.get_weight(act)
		if pick <= 0.0:
			return template
	return candidates[candidates.size() - 1]

# [[EnemyData, count, elite], …] sharing `budget`, or [] if the counts can't land close enough.
static func _mix(rng: RandomNumberGenerator, template: DriftTemplate, pool: Array[EnemyData], budget: float,
		cap: float) -> Array:
	var leads := pool.filter(template.can_lead)
	var lead: EnemyData = leads[rng.randi() % leads.size()]
	var max_types := mini(template.max_types, pool.size())
	var types: Array[EnemyData] = [lead]
	var others := pool.filter(func(data: EnemyData) -> bool: return data != lead)
	_shuffle(others, rng)
	var wanted := rng.randi_range(mini(template.min_types, max_types), max_types)
	for data in others:
		if types.size() >= wanted:
			break
		types.append(data)
	# Shares: the lead's, then the rest split so each other type gets at least MIN_SHARE.
	var lead_share := rng.randf_range(template.lead_share_min, template.lead_share_max)
	if not lead.resists.is_empty():
		lead_share = minf(lead_share, cap - 0.05)  # A resisting lead stays under the fairness cap (act 1: Husk-led Heavy)
	while types.size() > 1 and (1.0 - lead_share) / (types.size() - 1) < MIN_SHARE:
		types.pop_back()
	if types.size() == 1:
		lead_share = 1.0
	var shares: Array[float] = [lead_share]
	var others_count := types.size() - 1
	if others_count > 0:
		var spare := (1.0 - lead_share) - MIN_SHARE * others_count
		var weights: Array[float] = []
		var weight_sum := 0.0
		for i in others_count:
			weights.append(rng.randf_range(1.0, 2.0))
			weight_sum += weights[i]
		for i in others_count:
			shares.append(MIN_SHARE + spare * weights[i] / weight_sum)
	# Elite hunt: some of the lead come Deeply Blighted, paid for out of the budget.
	var elites := 0
	var elite_cost := 0.0
	if template.extra_elites > 0 and template.extra_elites * lead.get_roll_cost() * ELITE_COST <= budget * 0.5:
		elites = template.extra_elites
		elite_cost = elites * lead.get_roll_cost() * ELITE_COST
	var normal := budget - elite_cost
	var counts: Array[int] = []
	for i in types.size():
		counts.append(maxi(1, roundi(shares[i] * normal / types[i].get_roll_cost())))
	# Land on the budget: the cheapest type takes up the rounding.
	var cheapest := 0
	for i in types.size():
		if types[i].get_roll_cost() < types[cheapest].get_roll_cost():
			cheapest = i
	var total := elite_cost
	for i in types.size():
		total += counts[i] * types[i].get_roll_cost()
	counts[cheapest] = maxi(1, counts[cheapest] + roundi((budget - total) / types[cheapest].get_roll_cost()))
	total = elite_cost
	for i in types.size():
		total += counts[i] * types[i].get_roll_cost()
	if absf(total - budget) > budget * BUDGET_TOLERANCE:
		return []
	var mix := []
	for i in types.size():
		mix.append([types[i], counts[i], false])
	if elites > 0:
		mix.append([lead, elites, true])
	return mix

# The resisted families this drift leans on (for the block's count), or null if the drift breaks
# a fairness rule: a family resisted by too much of its health, a family the block already leans on
# MAX_LEANS times, or nothing but flyers.
static func _leans_if_fair(mix: Array, act: int, state: Dictionary) -> Variant:
	var total := 0.0
	var resisted := {}
	var all_flyers := true
	for slot in mix:
		var data: EnemyData = slot[0]
		var cost: float = slot[1] * data.get_roll_cost() * (ELITE_COST if slot[2] else 1.0)
		total += cost
		for family in data.resists:
			resisted[family] = resisted.get(family, 0.0) + cost
		if data.trait_kind != EnemyData.Trait.FLYING:
			all_flyers = false
	if all_flyers or total <= 0.0:
		return null
	var cap := RESIST_CAP_ACT1 if act <= 1 else RESIST_CAP
	var leans: Array = []
	for family in resisted:
		var share: float = resisted[family] / total
		if share > cap:
			return null
		if share > LEAN_SHARE and act >= 2:  # The block rule is for acts 2–4 (act 1 has two types)
			if state.leans.get(family, 0) >= MAX_LEANS:
				return null
			leans.append(family)
	return leans

# One group, the kinds mixed evenly over the hand-made drift's arrival window.
static func _build(drift: DriftData, mix: Array, template: DriftTemplate) -> DriftData:
	var schedule := drift.get_schedule()
	var window: float = schedule[schedule.size() - 1][0] if schedule.size() > 1 else DEFAULT_WINDOW
	var arrivals := 0
	for slot in mix:
		arrivals += slot[1]
	var group := DriftGroup.new()
	group.spacing = maxf(0.2, window / maxf(arrivals - 1, 1) * template.spacing_multiplier)
	for slot in mix:
		var entry := DriftEntry.new()
		entry.enemy = slot[0]
		entry.count = slot[1]
		entry.elite = slot[2]
		group.entries.append(entry)
	var rolled := DriftData.new()
	rolled.groups.append(group)
	rolled.set_meta(META_TEMPLATE, template.id)
	return rolled

static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = items[i]
		items[i] = items[j]
		items[j] = swap
