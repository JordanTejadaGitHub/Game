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
#   - (the resisted-family caps and the block's leans went with damage types: Nightmare Kinds, 2026-10-15;
#     RESIST_CAP*, LEAN_SHARE and MAX_LEANS stay, unread, for old callers),
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
const ELITE_LEAVES := 2  # …and leaves (Enemy.ELITE_LEAVES)
# Leaves at stake: a rolled drift may put at most LEAVES_SCALE × (or + LEAVES_EXTRA) the hand-made
# drift's leaves at stake. Budgets weigh nightmares by EnemyData.get_roll_weight (the Phantom ×4).
const LEAVES_SCALE := 1.5
const LEAVES_EXTRA := 8
const EASE_IN := 5  # For this many drifts after its intro, a type comes at most as many as at its intro
const DEFAULT_WINDOW := 20.0  # Arrival window (s) when the hand-made drift has a single arrival
const META_HAND_MADE := &"hand_made_drifts"
const META_TEMPLATE := &"roll_template"
# Act 1 density cap (acts_1_2.md, balance 2026-09-29): outside a Swarm, small nightmares arrive at
# least ACT1_SMALL_GAP s apart; an act 1 Swarm has at most ACT1_SWARM_MAX small ones (the rest of its
# budget goes to a bigger type). Single-target families died on denser act 1 drifts.
const ACT1_SMALL_GAP := 0.9
const ACT1_SWARM_MAX := 20

# The roster's and templates' resource paths (sorted). Only paths: a static holding the resources
# themselves keeps them alive into the engine's teardown, which can crash on quit; load() hits the
# resource cache, so loading them again per call is cheap.
static var _roster_paths := PackedStringArray()
static var _template_paths := PackedStringArray()

# Rolls every rollable drift of the run into director.drifts (a DriftDirector). Deterministic for
# a seed; calling it again rolls from the hand-made drifts again.
static func roll_run(director: Node, seed: int) -> void:
	if not director.has_meta(META_HAND_MADE):
		director.set_meta(META_HAND_MADE, director.drifts.duplicate())
	var hand_made: Array = director.get_meta(META_HAND_MADE)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "drifts"])
	var shapes := plan_shapes(director, seed, hand_made)
	var previous := &""
	var blocks := {}  # block -> {"limited": bool, "leans": {family: drifts}}
	for n in range(1, hand_made.size() + 1):
		director.drifts[n - 1] = hand_made[n - 1]
		if not is_rollable(director, n):
			previous = &""
			continue
		var state: Dictionary = blocks.get_or_add(director.get_block(n), {"limited": false, "leans": {}})
		var rolled := _roll_drift(director, n, hand_made[n - 1], hand_made, rng, previous, state, shapes.get(n, &""))
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

# Drift `number`'s shape (DriftShapes ids; a hand-made or unshaped drift is a Stream).
static func shape_of(director: Node, number: int) -> StringName:
	if number < 1 or number > director.drifts.size():
		return DriftShapes.STREAM
	var shape: StringName = director.drifts[number - 1].shape
	return shape if shape != &"" else DriftShapes.STREAM

# --- Shapes (enemy_design.md "Drift shapes") ----------------------------------------------------------

const SHAPE_FROM := 11  # Drifts 1–10 are Streams
const SHAPE_TEMPLATES := {  # The templates each shape is rolled with (Stream: any)
	&"packs": [&"mixed", &"swarm", &"fast"],
	&"single_file": [&"mixed", &"heavy", &"special"],
	&"few_and_tough": [&"heavy", &"elite_hunt"],
}
const META_SHAPE := &"roll_shape"
const FEW_ELITES := Vector2i(3, 5)  # Few and tough: this many Deeply Blighted of a heavy kind…
const FEW_SHARE := Vector2(0.4, 0.7)  # …holding this share of the budget
const FEW_ELITE_CAP := 0.7  # The roller's elite cap for Few and tough (others: 0.5)

# {drift: shape} for the run, on its own salted rng (the kinds keep theirs). Fixed drifts (1–5,
# intro drifts, bosses, the drift before a boss) are Streams and count as their block's Streams.
static func plan_shapes(director: Node, seed: int, hand_made: Array) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "shapes"])
	var plan := {}
	var per_block: int = director.drifts_per_block
	var finales_seen := {}  # act -> {shape: true}
	for first in range(1, hand_made.size() + 1, per_block):
		var last := mini(first + per_block - 1, hand_made.size())
		var act: int = director.get_act(first)
		var boss_block := false
		var free: Array = []
		for n in range(first, last + 1):
			plan[n] = DriftShapes.STREAM
			if director.is_boss_drift(n):
				boss_block = true
		for n in range(first, last + 1):
			if n >= SHAPE_FROM and is_rollable(director, n) and not director.is_boss_drift(n + 1):
				free.append(n)
		if act <= 1:
			# Act 1, blocks 3–5: one Packs or Single file a block (the boss block: drifts 21–23 only)
			if first < SHAPE_FROM or free.is_empty():
				continue
			if boss_block:
				free = free.filter(func(n: int) -> bool: return n - first < 3)
				if free.is_empty():
					continue
			plan[free[rng.randi_range(0, free.size() - 1)]] = DriftShapes.PACKS if rng.randf() < 0.5 else DriftShapes.SINGLE_FILE
		elif boss_block:
			# The first three drifts: one of each shape; the drift before the boss and the boss: Streams
			free = free.filter(func(n: int) -> bool: return n - first < 3)
			var shapes := _shapes_fitting(free.size())
			_shuffle(shapes, rng)
			for i in shapes.size():
				plan[free[i]] = shapes[i]
		else:
			# Two Streams plus each shape once; the finale is never a Stream
			var shapes := _shapes_fitting(free.size())
			var slots: Array = shapes.duplicate()
			while slots.size() < free.size():
				slots.append(DriftShapes.STREAM)
			_shuffle(slots, rng)
			if free.has(last) and not shapes.is_empty():
				var seen: Dictionary = finales_seen.get_or_add(act, {})
				var unseen := shapes.filter(func(s: StringName) -> bool: return not seen.has(s))
				var pool: Array = unseen if not unseen.is_empty() else shapes
				var finale: StringName = pool[rng.randi_range(0, pool.size() - 1)]
				slots.erase(finale)
				slots.insert(free.find(last), finale)
				seen[finale] = true
			for i in free.size():
				plan[free[i]] = slots[i]
		# Never two Few and tough in a row (across blocks too): swap with another free drift, or a Stream
		for n in free:
			if plan[n] == DriftShapes.FEW_AND_TOUGH and plan.get(n - 1, &"") == DriftShapes.FEW_AND_TOUGH:
				var fixed := false
				for other in free:
					if other != n and plan[other] != DriftShapes.FEW_AND_TOUGH and plan.get(other - 1, &"") != DriftShapes.FEW_AND_TOUGH \
							and plan.get(other + 1, &"") != DriftShapes.FEW_AND_TOUGH and not (n == last and plan[other] == DriftShapes.STREAM):
						plan[n] = plan[other]
						plan[other] = DriftShapes.FEW_AND_TOUGH
						fixed = true
						break
				if not fixed:
					plan[n] = DriftShapes.STREAM
	for n in plan.keys():  # A shape set by hand on a drift is pinned
		if hand_made[n - 1].shape != &"":
			plan[n] = hand_made[n - 1].shape
	return plan

# The block's shapes for `free` drifts: each once, dropping Few and tough, then Single file.
static func _shapes_fitting(free: int) -> Array:
	var shapes: Array = [DriftShapes.PACKS, DriftShapes.SINGLE_FILE, DriftShapes.FEW_AND_TOUGH]
	if free < 3:
		shapes.erase(DriftShapes.FEW_AND_TOUGH)
	if free < 2:
		shapes.erase(DriftShapes.SINGLE_FILE)
	if free < 1:
		shapes.clear()
	return shapes

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
				budget += entry.count * entry.enemy.get_roll_weight()
	return budget

# Every type with an intro drift (the rollable roster), sorted by intro.
static func get_roster() -> Array[EnemyData]:
	if _roster_paths.is_empty():
		var found: Array[EnemyData] = []
		for file in ResourceLoader.list_directory(ENEMY_DIR):
			if file.ends_with(".tres") or file.ends_with(".res"):
				var data := load(ENEMY_DIR.path_join(file)) as EnemyData
				if data != null and data.intro_drift > 0:
					found.append(data)
		found.sort_custom(func(a: EnemyData, b: EnemyData) -> bool:
			return a.intro_drift < b.intro_drift or (a.intro_drift == b.intro_drift and a.resource_path < b.resource_path))
		for data in found:
			_roster_paths.append(data.resource_path)
	var roster: Array[EnemyData] = []
	for path in _roster_paths:
		roster.append(load(path) as EnemyData)
	return roster

static func get_templates() -> Array[DriftTemplate]:
	if _template_paths.is_empty():
		var found: Array[DriftTemplate] = []
		for file in ResourceLoader.list_directory(TEMPLATE_DIR):
			if file.ends_with(".tres") or file.ends_with(".res"):
				var template := load(TEMPLATE_DIR.path_join(file)) as DriftTemplate
				if template != null:
					found.append(template)
		found.sort_custom(func(a: DriftTemplate, b: DriftTemplate) -> bool: return String(a.id) < String(b.id))
		for template in found:
			_template_paths.append(template.resource_path)
	var templates: Array[DriftTemplate] = []
	for path in _template_paths:
		templates.append(load(path) as DriftTemplate)
	return templates


# --- One drift ---------------------------------------------------------------------------------

static func _roll_drift(director: Node, number: int, drift: DriftData, hand_made: Array, rng: RandomNumberGenerator,
		previous: StringName, state: Dictionary, shape: StringName = &"") -> DriftData:
	var act: int = director.get_act(number)
	var pool := get_pool(number)
	var budget := get_budget(drift)
	if pool.is_empty() or budget <= 0.0:
		return null
	var hand_leaves := get_leaves(_slots_of(drift, false))
	var fresh_caps := {}  # EnemyData -> most per drift while it eases in
	for data in pool:
		if number - data.intro_drift <= EASE_IN and data.intro_drift <= hand_made.size():
			var at_intro := 0
			for slot in _slots_of(hand_made[data.intro_drift - 1], false):
				if slot[0] == data:
					at_intro += slot[1]
			fresh_caps[data] = maxi(at_intro, 1)
	for data in pool:  # A kind's drift_max (the Phantom: 4) caps it like an easing-in type: the rest spills to known ones
		if data.drift_max > 0:
			fresh_caps[data] = mini(fresh_caps.get(data, data.drift_max), data.drift_max)
	var kept_elites: Array = []  # [[EnemyData, count, true]] from the hand-made drift
	for group in drift.groups:
		for entry in group.entries:
			if entry.enemy != null and entry.elite and not entry.enemy.is_boss:
				kept_elites.append([entry.enemy, entry.count, true])
	for attempt in ATTEMPTS:
		var template := _pick_template(rng, act, pool, previous, state, shape)
		if template == null and shape != &"":
			shape = &""  # No template fits the planned shape: a Stream
			template = _pick_template(rng, act, pool, previous, state)
		if template == null:
			return null
		var mix := _mix(rng, template, pool, budget, RESIST_CAP_ACT1 if act <= 1 else RESIST_CAP, act, fresh_caps, shape)
		if mix.is_empty():
			continue
		if shape == DriftShapes.SINGLE_FILE:
			mix = _fit_single_file(mix, drift, kept_elites, director.get_extra_nightmares(number))
			if mix.is_empty() or absf(_mix_cost(mix) - budget) > budget * BUDGET_TOLERANCE:
				continue
		# Fairness judges the rolled part: the hand-made elites are a fixed design choice (drift 23's
		# first elites are Husks on purpose).
		if get_leaves(mix) > maxi(ceili(hand_leaves * LEAVES_SCALE), hand_leaves + LEAVES_EXTRA):
			continue  # More leaves at stake than the drift was made for (many cheap Phantoms)
		var leans: Variant = _leans_if_fair(mix, act, state)
		if leans == null:
			continue
		mix.append_array(kept_elites)
		for family in leans:
			state.leans[family] = state.leans.get(family, 0) + 1
		if template.limited:
			state.limited = true
		return _build(drift, mix, template, act, shape)
	return null

static func _pick_template(rng: RandomNumberGenerator, act: int, pool: Array[EnemyData], previous: StringName,
		state: Dictionary, shape: StringName = &"") -> DriftTemplate:
	var candidates: Array[DriftTemplate] = []
	var total := 0.0
	var fits: Array = SHAPE_TEMPLATES.get(shape, [])
	for repeat in [false, true]:  # A shape's few templates may repeat the last drift's rather than fail
		for template in get_templates():
			if template.get_weight(act) <= 0.0 or (template.id == previous and not repeat) or (template.limited and state.limited):
				continue
			if not fits.is_empty() and not fits.has(template.id):
				continue
			if not pool.any(func(data: EnemyData) -> bool: return template.can_lead(data) and _leads_shape(data, shape)):
				continue
			candidates.append(template)
			total += template.get_weight(act)
		if not candidates.is_empty() or fits.is_empty():
			break
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
		cap: float, act: int = 2, fresh_caps: Dictionary = {}, shape: StringName = &"") -> Array:
	# A capped kind (drift_max: the Phantom) leads only Special drifts; elsewhere it's a minority type
	var leads := pool.filter(func(data: EnemyData) -> bool:
		return template.can_lead(data) and (data.drift_max <= 0 or &"special" in template.lead_tags) and _leads_shape(data, shape))
	if leads.is_empty():
		return []
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
	if shape == DriftShapes.FEW_AND_TOUGH:
		# 3–5 Deeply Blighted of the (heavy) lead holding 40–70% of the budget; none fits = this lead doesn't
		var fitting: Array[int] = []
		for n in range(FEW_ELITES.x, FEW_ELITES.y + 1):
			var share := n * lead.get_roll_weight() * ELITE_COST / budget
			if share >= FEW_SHARE.x and share <= minf(FEW_SHARE.y, FEW_ELITE_CAP):
				fitting.append(n)
		if fitting.is_empty():
			return []
		elites = fitting[rng.randi_range(0, fitting.size() - 1)]
		elite_cost = elites * lead.get_roll_weight() * ELITE_COST
	elif template.extra_elites > 0 and template.extra_elites * lead.get_roll_weight() * ELITE_COST <= budget * 0.5:
		elites = template.extra_elites
		elite_cost = elites * lead.get_roll_weight() * ELITE_COST
	var normal := budget - elite_cost
	var counts: Array[int] = []
	for i in types.size():
		counts.append(maxi(1, roundi(shares[i] * normal / types[i].get_roll_weight())))
	# Land on the budget: the cheapest type takes up the rounding.
	var cheapest := 0
	for i in types.size():
		if types[i].get_roll_weight() < types[cheapest].get_roll_weight():
			cheapest = i
	var total := elite_cost
	for i in types.size():
		total += counts[i] * types[i].get_roll_weight()
	counts[cheapest] = maxi(1, counts[cheapest] + roundi((budget - total) / types[cheapest].get_roll_weight()))
	# Act 1 Swarm: at most ACT1_SWARM_MAX small nightmares; the rest of the budget goes to a bigger type.
	if act <= 1 and template.id == &"swarm":
		var small := 0
		for i in types.size():
			if &"small" in types[i].roll_tags:
				small += counts[i]
		var excess := 0.0
		for i in types.size():
			if small > ACT1_SWARM_MAX and &"small" in types[i].roll_tags:
				var cut := mini(small - ACT1_SWARM_MAX, counts[i] - 1)
				counts[i] -= cut
				small -= cut
				excess += cut * types[i].get_roll_weight()
		if excess > 0.0:
			var bulky := -1
			for i in types.size():
				if not &"small" in types[i].roll_tags:
					bulky = i
			if bulky < 0:
				var bigger := pool.filter(func(data: EnemyData) -> bool: return not &"small" in data.roll_tags)
				if bigger.is_empty():
					return []
				types.append(bigger[rng.randi() % bigger.size()])
				counts.append(0)
				bulky = types.size() - 1
			counts[bulky] += maxi(1, roundi(excess / types[bulky].get_roll_weight()))
	# New types ease in (acts_1_2.md "Introduce, then mix"): for EASE_IN drifts after its intro, a type
	# comes at most as many as at its intro; the rest of its share goes to a type the player knows.
	var spill := 0.0
	for i in types.size():
		if fresh_caps.has(types[i]) and counts[i] > fresh_caps[types[i]]:
			spill += (counts[i] - fresh_caps[types[i]]) * types[i].get_roll_weight()
			counts[i] = fresh_caps[types[i]]
	if spill > 0.0:
		var known := -1
		for i in types.size():
			if not fresh_caps.has(types[i]) and (known < 0 or types[i].get_roll_weight() < types[known].get_roll_weight()):
				known = i
		if known < 0:
			var settled := pool.filter(func(data: EnemyData) -> bool: return not fresh_caps.has(data))
			if settled.is_empty():
				return []
			types.append(settled[rng.randi() % settled.size()])
			counts.append(0)
			known = types.size() - 1
		counts[known] += maxi(1, roundi(spill / types[known].get_roll_weight()))
	# The spills can undo each other (a Swarm's excess onto a new type, or a new type's onto Shades):
	# then this template doesn't fit this drift.
	var small_total := 0
	for i in types.size():
		if fresh_caps.has(types[i]) and counts[i] > fresh_caps[types[i]]:
			return []
		if &"small" in types[i].roll_tags:
			small_total += counts[i]
	if act <= 1 and template.id == &"swarm" and small_total > ACT1_SWARM_MAX:
		return []
	total = elite_cost
	for i in types.size():
		total += counts[i] * types[i].get_roll_weight()
	if absf(total - budget) > budget * BUDGET_TOLERANCE:
		return []
	var mix := []
	for i in types.size():
		mix.append([types[i], counts[i], false])
	if elites > 0:
		mix.append([lead, elites, true])
	return mix

# The resisted families this drift leans on (always none since damage types went: Nightmare Kinds, 2026-10-15),
# or null if the drift breaks the one fairness rule left here: nothing but flyers.
static func _leans_if_fair(mix: Array, _act: int, _state: Dictionary) -> Variant:
	var total := 0.0
	var all_flyers := true
	for slot in mix:
		var data: EnemyData = slot[0]
		total += slot[1] * data.get_roll_cost() * (ELITE_COST if slot[2] else 1.0)
		if data.trait_kind != EnemyData.Trait.FLYING:
			all_flyers = false
	if all_flyers or total <= 0.0:
		return null
	return []

# One group, the kinds mixed evenly over the hand-made drift's arrival window.
# Whether `data` may lead a drift of `shape`: Packs a packable kind, Single file and Few and tough a heavy
# kind (Few and tough never a splitter: a hidden crowd).
static func _leads_shape(data: EnemyData, shape: StringName) -> bool:
	match shape:
		DriftShapes.PACKS:
			return DriftShapes.is_packable(data)
		DriftShapes.SINGLE_FILE:
			return &"heavy" in data.roll_tags
		DriftShapes.FEW_AND_TOUGH:
			return &"heavy" in data.roll_tags and not (data.split_into != null and data.split_count > 0)
	return true

# Health budget of a mix (elites at ELITE_COST).
static func _mix_cost(mix: Array) -> float:
	var total := 0.0
	for slot in mix:
		total += slot[1] * slot[0].get_roll_weight() * (ELITE_COST if slot[2] else 1.0)
	return total

# Single file: at most window / SINGLE_GAP + 1 arrivals (after the difficulty's extra nightmares), so the
# lighter kinds give their budget to the (heavy) lead, first slot of `mix`. [] if it can't fit.
static func _fit_single_file(mix: Array, drift: DriftData, kept_elites: Array, extra: float) -> Array:
	var schedule := drift.get_schedule()
	var window: float = schedule[schedule.size() - 1][0] if schedule.size() > 1 else DEFAULT_WINDOW
	var most := floori((floori(window / DriftShapes.SINGLE_GAP) + 1) / maxf(extra, 1.0))
	var count := 0
	for slot in mix + kept_elites:
		count += slot[1]
	var lead: EnemyData = mix[0][0]
	var spare := 0.0
	while count > most:
		var cheapest := -1
		for i in range(1, mix.size()):
			if not mix[i][2] and mix[i][1] > 1 and (cheapest < 0 or mix[i][0].get_roll_weight() < mix[cheapest][0].get_roll_weight()):
				cheapest = i
		if cheapest < 0:
			return []
		mix[cheapest][1] -= 1
		count -= 1
		spare += mix[cheapest][0].get_roll_weight()
		if spare >= lead.get_roll_weight():
			if count + 1 > most:
				continue  # No room for another lead yet: keep thinning
			mix[0][1] += 1
			count += 1
			spare -= lead.get_roll_weight()
	while spare >= lead.get_roll_weight() * 0.5 and count < most:  # The rest of the spare budget, rounded
		mix[0][1] += 1
		count += 1
		spare -= lead.get_roll_weight()
	return mix

static func _build(drift: DriftData, mix: Array, template: DriftTemplate, act: int = 2, shape: StringName = &"") -> DriftData:
	var schedule := drift.get_schedule()
	var window: float = schedule[schedule.size() - 1][0] if schedule.size() > 1 else DEFAULT_WINDOW
	var arrivals := 0
	for slot in mix:
		arrivals += slot[1]
	var group := DriftGroup.new()
	group.spacing = maxf(0.2, window / maxf(arrivals - 1, 1) * template.spacing_multiplier)
	if act <= 1 and template.id != &"swarm" and mix.any(func(slot: Array) -> bool: return &"small" in slot[0].roll_tags):
		group.spacing = maxf(group.spacing, ACT1_SMALL_GAP)  # Kinds mix evenly, so two small ones can be neighbours
	for slot in mix:
		var entry := DriftEntry.new()
		entry.enemy = slot[0]
		entry.count = slot[1]
		entry.elite = slot[2]
		group.entries.append(entry)
	var rolled := DriftData.new()
	rolled.groups.append(group)
	rolled.set_meta(META_TEMPLATE, template.id)
	rolled.shape = shape if shape != &"" else DriftShapes.STREAM
	rolled.set_meta(META_SHAPE, rolled.shape)
	return rolled

# Leaves at stake in [[EnemyData, count, elite], …] if all of it reached the Heartwood (an elite
# costs at least Enemy.ELITE_LEAVES).
static func get_leaves(mix: Array) -> int:
	var leaves := 0
	for slot in mix:
		var data: EnemyData = slot[0]
		leaves += slot[1] * (maxi(data.get_roll_leaves(), ELITE_LEAVES) if slot[2] else data.get_roll_leaves())
	return leaves

# A drift's non-boss entries as [[EnemyData, count, elite], …] (`elites`: include the elite ones).
static func _slots_of(drift: DriftData, elites: bool) -> Array:
	var slots := []
	for group in drift.groups:
		for entry in group.entries:
			if entry.enemy != null and not entry.enemy.is_boss and (elites or not entry.elite):
				slots.append([entry.enemy, entry.count, entry.elite])
	return slots

static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = items[i]
		items[i] = items[j]
		items[j] = swap
