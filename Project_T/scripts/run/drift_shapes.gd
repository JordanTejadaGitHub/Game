extends RefCounted
class_name DriftShapes

# Drift shapes (enemy_design.md "Drift shapes", owner 2026-10-24): templates choose WHAT comes, the
# shape chooses HOW it arrives. Rolled with the map (DriftRoller.roll_run, DriftData.shape / META_SHAPE);
# apply() re-times and re-orders a drift's schedule at its start. It never adds, removes or changes a
# nightmare, and keeps the first and last arrival times (arrival_left, call-early Dew, Auto-drift and
# the needed-DPS meter don't move).
#
# Order at a drift's start: schedule (Omen counts / spacing) → guaranteed, Blight and Omen elites →
# OmenDirector.shape_for → apply() → Headlong's _compress → pot_shares.
#
# After apply every arrival is [time, EnemyData, elite, pack]: pack = the pack's index in the drift
# (0, 1, …) or -1. A spawned pack member carries PACK_META (pack_key); a leaked pack costs at most
# PACK_LEAVES leaves together (cap_pack_leak, RunState).

const STREAM := &"stream"
const PACKS := &"packs"
const SINGLE_FILE := &"single_file"
const FEW_AND_TOUGH := &"few_and_tough"
const ALL: Array[StringName] = [STREAM, PACKS, SINGLE_FILE, FEW_AND_TOUGH]
const NAMES := {STREAM: "Stream", PACKS: "Packs", SINGLE_FILE: "Single file", FEW_AND_TOUGH: "Few and tough"}
const GLYPHS := {STREAM: &"shape_stream", PACKS: &"shape_packs", SINGLE_FILE: &"shape_single_file",
	FEW_AND_TOUGH: &"shape_few_and_tough"}

const PACK_SIZE := Vector2i(6, 8)  # Nightmares per pack (splitters count their children)
const PACK_SIZE_ACT1 := Vector2i(4, 5)
const PACK_MIN := 3  # Fewer of a kind than this ride loose, as in a Stream
const PACK_SHARE := 1.0 / 3.0  # A pack is at most a third of the drift
const PACK_GAP := 5.0  # At least this many seconds between packs (Restless Wind: × pack_gap)
const PACK_CELLS := 0.5  # In-pack gap: half a cell at the kind's speed
const PACK_GAP_FLOOR := 0.2
const CELL_PX := 64.0
const CROWD_MAX := 8  # Never more than this many arrivals inside CROWD_SECONDS (only Headlong)
const CROWD_SECONDS := 3.0
const SINGLE_GAP := 1.5  # Single file: at least this far apart (the roll makes it fit)
const PACK_LEAVES := 3  # A leaked pack costs at most this many leaves in all…
const PACK_LEAVES_PER := 8  # …per this many nightmares in it, rounded up (a pack of 40: 15; Balancing 2026-10-24)
# Big late drifts (Balancing 2026-10-24): a Packs drift with more than PACKS_BIG_COUNT × PACK_SIZE.y nightmares
# makes PACKS_BIG_COUNT packs of about count / PACKS_BIG_COUNT, each arriving within PACK_SPAN_MAX s, at least
# PACK_GAP_BIG_FLOOR s apart (× Restless Wind's pack_gap); the CROWD_MAX rule is waived for them.
const PACKS_BIG_COUNT := 6
const PACK_SPAN_MAX := 3.0
const PACK_GAP_BIG_FLOOR := 2.0
const PACK_LIMIT_META := &"drift_pack_leaves"
const PACK_META := &"drift_pack"
# Kinds that leave a pack by design: never packed.
const LOOSE_TRAITS := [EnemyData.Trait.FLYING, EnemyData.Trait.ROLLING, EnemyData.Trait.LEAP,
	EnemyData.Trait.BURROW, EnemyData.Trait.WANDER]

static func display_name(shape: StringName) -> String:
	return NAMES.get(shape if shape != &"" else STREAM, "Stream")

static func glyph(shape: StringName) -> StringName:
	return GLYPHS.get(shape if shape != &"" else STREAM, GLYPHS[STREAM])

# The pack index of a schedule arrival (-1 = not in a pack).
static func pack_of(arrival: Array) -> int:
	return int(arrival[3]) if arrival.size() > 3 else -1

# A run-wide pack id for drift `number`'s pack `pack` (PACK_META on its nightmares).
static func pack_key(number: int, pack: int) -> int:
	return number * 1000 + pack

# Tag a spawned nightmare with its pack (DriftDirector._spawn) and the pack's leaf limit; split children and
# followers inherit both.
static func tag_enemy(enemy: Node, number: int, arrival: Array) -> void:
	if enemy == null:
		return
	var tagged: Array = [enemy]
	tagged.append_array(enemy.get("dew_followers") if enemy.get("dew_followers") != null else [])  # Spawned with it, before the tag
	var width := lane_of(arrival)
	if width >= 0.0:
		for node in tagged:
			if is_instance_valid(node) and node.get("lane_width") != null:
				node.lane_width = width  # Walking lanes: Single file close to the line
	if pack_of(arrival) < 0:
		return
	var limit := pack_leaf_limit(pack_size_of(arrival))
	for node in tagged:
		if is_instance_valid(node):
			node.set_meta(PACK_META, pack_key(number, pack_of(arrival)))
			node.set_meta(PACK_LIMIT_META, limit)

# Leaves a leak of `enemy` costs once its pack's cap is counted: `charged` (RunState) holds the leaves
# each pack lost so far; the cap is PACK_LEAVES per PACK_LEAVES_PER nightmares in the pack. Outside a pack:
# `leaves` unchanged.
static func cap_pack_leak(enemy: Node, leaves: int, charged: Dictionary) -> int:
	if enemy == null or not enemy.has_meta(PACK_META) or leaves <= 0:
		return leaves
	var key: int = enemy.get_meta(PACK_META)
	var paid: int = charged.get(key, 0)
	var limit: int = enemy.get_meta(PACK_LIMIT_META, PACK_LEAVES)
	var cost := clampi(leaves, 0, maxi(limit - paid, 0))
	charged[key] = paid + cost
	return cost

# Whether `data` may ride in a pack.
static func is_packable(data: EnemyData) -> bool:
	return data != null and not data.is_boss and not LOOSE_TRAITS.has(data.trait_kind)

# Re-times and re-orders `schedule` (in place) for `shape`. `rng`: the drift's seeded rng (drift_rng),
# so a replay of the seed places everything the same. `act` sets the pack size; `mods` =
# DriftDirector.get_schedule_modifiers (Omens: "pack_fill", "pack_gap"). A schedule with a boss is left
# alone (the boss keeps its own escort); a shape that can't fit falls back to a Stream (unchanged).
# Returns the shape the drift really arrives in: STREAM when it fell back (a boss drift, packs that don't fit),
# so the banner and the Coming strip never name a shape the drift doesn't have.
static func apply(schedule: Array, shape: StringName, rng: RandomNumberGenerator, act: int, mods: Dictionary = {}) -> StringName:
	for arrival in schedule:
		while arrival.size() < 3:
			arrival.append(false)
		if arrival.size() < 4:
			arrival.append(-1)
	cap_flyers(schedule, rng, act)
	if schedule.size() < 2 or shape == STREAM or shape == &"":
		return STREAM
	for arrival in schedule:
		if arrival[1].is_boss:
			return STREAM
	match shape:
		PACKS:
			_packs(schedule, rng, act, mods)
			return PACKS if schedule.any(func(a: Array) -> bool: return pack_of(a) >= 0) else STREAM
		SINGLE_FILE:
			_single_file(schedule, rng)
			for arrival in schedule:
				_set_lane(arrival, LANE_SINGLE)
		FEW_AND_TOUGH:
			_few_and_tough(schedule, rng)
			for arrival in schedule:
				if arrival[2]:
					_set_lane(arrival, LANE_TOUGH)
		_:
			return STREAM
	return shape

# Walking lanes (enemy_design.md): an arrival's lane width in cells, arrival[5] (Enemy.lane_width via tag_enemy).
const LANE_SINGLE := 0.1  # Single file walks close to the centre line
const LANE_TOUGH := 0.15  # Few and tough's Deeply Blighted

static func _set_lane(arrival: Array, width: float) -> void:
	while arrival.size() < 6:
		arrival.append(0)
	arrival[5] = width

static func lane_of(arrival: Array) -> float:
	return float(arrival[5]) if arrival.size() > 5 else -1.0

# Flyer caps (enemy_design.md "Flyers", council 2026-10-24), checked after the Omens: flyers of every kind at most
# FLYER_CAPS[act] a drift and never more than a third of its arrivals, Phantoms (through-wall flyers) at most
# PHANTOM_CAP within that; the extra ones become the drift's most common walker. A flyer is never Deeply Blighted:
# its elite flag moves to a walker. Bosses (the Moth Queen) never count.
const FLYER_CAPS := {1: 4, 2: 4, 3: 5, 4: 6}
const PHANTOM_CAP := 4

static func cap_flyers(schedule: Array, rng: RandomNumberGenerator, act: int) -> void:
	var walkers := {}  # EnemyData -> count
	var flyers: Array = []
	var phantoms: Array = []
	for arrival in schedule:
		var data: EnemyData = arrival[1]
		if data.is_boss:
			continue
		if data.trait_kind == EnemyData.Trait.FLYING:
			flyers.append(arrival)
			if not data.flies_along_route:
				phantoms.append(arrival)
		else:
			walkers[data] = walkers.get(data, 0) + 1
	if flyers.is_empty():
		return
	var common: EnemyData = null
	for data in walkers:
		if common == null or walkers[data] > walkers[common]:
			common = data
	if common != null:
		var most: int = mini(FLYER_CAPS.get(clampi(act, 1, 4), 4), floori(schedule.size() / 3.0))
		_shuffle(phantoms, rng)
		while phantoms.size() > PHANTOM_CAP:
			var extra: Array = phantoms.pop_back()
			extra[1] = common
			flyers.erase(extra)
		_shuffle(flyers, rng)
		while flyers.size() > most:
			flyers.pop_back()[1] = common
	# Never a Deeply Blighted flyer: the flag goes to a walker that isn't one yet
	for arrival in flyers:
		if arrival.size() > 2 and arrival[2]:
			arrival[2] = false
			var plain: Array = schedule.filter(func(a: Array) -> bool: return not a[1].is_boss and not a[2] \
				and a[1].trait_kind != EnemyData.Trait.FLYING)
			if not plain.is_empty():
				plain[rng.randi_range(0, plain.size() - 1)][2] = true

# A drift's seeded rng for apply / add_guaranteed_elite: same map seed + drift = same placement.
static func drift_rng(map_seed: int, number: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([map_seed, number, "shape"])
	return rng

# --- Shapes -------------------------------------------------------------------------------------------

static func _first_last(schedule: Array) -> Vector2:
	return Vector2(float(schedule[0][0]), float(schedule[-1][0]))

# Spreads `arrivals` evenly from first to last.
static func _even(schedule: Array, arrivals: Array, span: Vector2) -> void:
	var gap := (span.y - span.x) / maxf(arrivals.size() - 1, 1)
	for i in arrivals.size():
		arrivals[i][0] = span.x + gap * i
		arrivals[i][3] = -1
	schedule.assign(arrivals)

# Single file: no kind twice in a row (where the mix allows), any Deeply Blighted last, even spacing.
static func _single_file(schedule: Array, rng: RandomNumberGenerator) -> void:
	var span := _first_last(schedule)
	var elites: Array = schedule.filter(func(a: Array) -> bool: return a[2])
	var by_kind := {}
	for arrival in schedule:
		if not arrival[2]:
			by_kind.get_or_add(arrival[1], []).append(arrival)
	var line: Array = []
	var last: EnemyData = null
	while not by_kind.is_empty():
		# The kind with the most left goes next (ties seeded), never the one just placed if another is left.
		var kinds: Array = by_kind.keys()
		_shuffle(kinds, rng)
		kinds.sort_custom(func(a: EnemyData, b: EnemyData) -> bool: return by_kind[a].size() > by_kind[b].size())
		var pick: EnemyData = kinds[0]
		if pick == last and kinds.size() > 1:
			pick = kinds[1]
		line.append(by_kind[pick].pop_front())
		if by_kind[pick].is_empty():
			by_kind.erase(pick)
		last = pick
	_shuffle(elites, rng)
	line.append_array(elites)
	_even(schedule, line, span)

# Few and tough: the Deeply Blighted first, then the rest, even spacing.
static func _few_and_tough(schedule: Array, rng: RandomNumberGenerator) -> void:
	var span := _first_last(schedule)
	var elites: Array = schedule.filter(func(a: Array) -> bool: return a[2])
	var rest: Array = schedule.filter(func(a: Array) -> bool: return not a[2])
	_shuffle(elites, rng)
	elites.append_array(rest)
	_even(schedule, elites, span)

# Nightmares a packed arrival counts as (a splitter brings its children).
static func _weight(data: EnemyData) -> int:
	return 1 + (maxi(data.split_count, 0) if data.split_into != null else 0) \
		+ (maxi(data.follower_count, 0) if data.followers != null else 0)  # …and a leader its followers

# The in-pack gap of `pack`: half a cell at its kind's speed; a big drift's pack also arrives within PACK_SPAN_MAX.
static func _pack_step(pack: Array, big: bool) -> float:
	var step := _in_pack_gap(pack[0][1])
	if big:
		step = minf(PACK_CELLS * CELL_PX / maxf(pack[0][1].speed, 1.0), PACK_SPAN_MAX / maxf(pack.size() - 1, 1))
	return step

# Leaves a pack of `size` may cost when it leaks.
static func pack_leaf_limit(size: int) -> int:
	return PACK_LEAVES * maxi(ceili(float(size) / PACK_LEAVES_PER), 1)

# The size of the pack an arrival rides in (0 = none).
static func pack_size_of(arrival: Array) -> int:
	return int(arrival[4]) if arrival.size() > 4 and pack_of(arrival) >= 0 else 0

static func _in_pack_gap(data: EnemyData) -> float:
	return maxf(PACK_CELLS * CELL_PX / maxf(data.speed, 1.0), PACK_GAP_FLOOR)

# Packs: one kind each, half a cell apart, PACK_GAP between packs; loose kinds (flyers, Rolling, Leap,
# Burrow, Wander, and kinds too few to pack) ride between the packs as in a Stream.
static func _packs(schedule: Array, rng: RandomNumberGenerator, act: int, mods: Dictionary) -> void:
	var original: Array = []
	for arrival in schedule:
		original.append(arrival.duplicate())
	var span := _first_last(schedule)
	var big := schedule.size() > PACKS_BIG_COUNT * PACK_SIZE.y  # A big late drift: PACKS_BIG_COUNT bigger packs
	var size := PACK_SIZE_ACT1 if act <= 1 else PACK_SIZE
	var fill := int(mods.get("pack_fill", 0))
	if fill > 0:
		size = Vector2i(fill, fill)  # Swarming Night / Crowded Paths: fill each pack before the next
	size.y = mini(size.y, int(floor(schedule.size() * PACK_SHARE)))
	size.x = mini(size.x, size.y)
	if size.y < PACK_MIN and not big:
		return
	var gap_floor := (PACK_GAP_BIG_FLOOR if big else PACK_GAP) * float(mods.get("pack_gap", 1.0))
	var by_kind := {}
	var loose: Array = []
	for arrival in schedule:
		if is_packable(arrival[1]):
			by_kind.get_or_add(arrival[1], []).append(arrival)
		else:
			loose.append(arrival)
	var packs: Array = []  # [[arrival, …], …]
	var kinds: Array = by_kind.keys()
	kinds.sort_custom(func(a: EnemyData, b: EnemyData) -> bool: return a.resource_path < b.resource_path)
	var big_counts := _big_pack_counts(kinds, by_kind) if big else {}
	if big and big_counts.is_empty():
		return  # Can't make PACKS_BIG_COUNT one-kind packs: a Stream
	for kind in kinds:
		var members: Array = by_kind[kind]
		var total := 0
		for arrival in members:
			total += _weight(kind)
		if total < PACK_MIN or (big and int(big_counts.get(kind, 0)) <= 0):
			loose.append_array(members)
			continue
		var target := rng.randi_range(size.x, size.y)
		var elites: Array = members.filter(func(a: Array) -> bool: return a[2])
		var count: int = big_counts[kind] if big else maxi(ceili(float(total) / size.y), maxi(roundi(float(total) / target), 1))
		count = clampi(maxi(count, elites.size()), 1, members.size())  # One Deeply Blighted per pack
		var kind_packs: Array = []
		for p in count:
			kind_packs.append([])
		for e in elites.size():
			kind_packs[e % count].append(elites[e])
		var weights: Array = []
		for pack in kind_packs:
			weights.append(pack.size() * _weight(kind))
		for arrival in members:
			if arrival[2]:
				continue
			var lightest := 0  # Fill the lightest pack: they come out even
			for p in count:
				if weights[p] < weights[lightest]:
					lightest = p
			kind_packs[lightest].append(arrival)
			weights[lightest] += _weight(kind)
		for pack in kind_packs:
			if pack.size() * _weight(kind) >= PACK_MIN or pack.any(func(a: Array) -> bool: return a[2]):
				packs.append(pack)
			else:
				loose.append_array(pack)
	# Too many packs for the window: the smallest go loose until the gaps between packs fit.
	while not big and packs.size() >= 2 and _pack_gap(packs, span) < gap_floor:
		var smallest := -1  # A pack with a Deeply Blighted stays
		for p in packs.size():
			if not _has_elite(packs[p]) and (smallest < 0 or packs[p].size() < packs[smallest].size()):
				smallest = p
		if smallest < 0:
			break
		loose.append_array(packs.pop_at(smallest))
	if packs.size() < (PACKS_BIG_COUNT if big else 2) or _pack_gap(packs, span, big) < gap_floor:
		return  # Doesn't fit: a Stream
	_order_packs(packs, rng)
	loose.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var loose_elites: Array = loose.filter(func(a: Array) -> bool: return a[2])
	var loose_rest: Array = loose.filter(func(a: Array) -> bool: return not a[2])
	# Loose arrivals share the gaps between packs, a loose Deeply Blighted in the middle gap.
	var gaps: Array = []
	for g in packs.size() - 1:
		gaps.append([])
	for i in loose_rest.size():
		gaps[i * gaps.size() / maxi(loose_rest.size(), 1)].append(loose_rest[i])
	for e in loose_elites:
		var middle: Array = gaps[(gaps.size() - 1) / 2]
		middle.insert(middle.size() / 2, e)
	var gap := _pack_gap(packs, span, big)
	var result: Array = []
	var time := span.x
	for p in packs.size():
		var step := _pack_step(packs[p], big)
		for i in packs[p].size():
			packs[p][i][0] = time + step * i
			packs[p][i][3] = p
			while packs[p][i].size() < 5:
				packs[p][i].append(0)
			packs[p][i][4] = packs[p].size()  # Its pack's size (the pack's leaf limit)
			result.append(packs[p][i])
		time += step * (packs[p].size() - 1)
		if p < gaps.size():
			var between: Array = gaps[p]
			for i in between.size():
				between[i][0] = time + gap * (i + 1) / (between.size() + 1)
				between[i][3] = -1
				result.append(between[i])
			time += gap
	result.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	if not big and _crowded(result):
		schedule.assign(original)  # Never more than CROWD_MAX inside CROWD_SECONDS: a Stream
		return
	schedule.assign(result)

# A big drift's packs per kind ({EnemyData: packs}, PACKS_BIG_COUNT in all, shared by size, largest remainder),
# or {} if its packable kinds can't fill them (a kind needs PACK_MIN a pack).
static func _big_pack_counts(kinds: Array, by_kind: Dictionary) -> Dictionary:
	var total := 0
	for kind in kinds:
		if by_kind[kind].size() >= PACK_MIN:
			total += by_kind[kind].size()
	if total < PACKS_BIG_COUNT * PACK_MIN:
		return {}
	var counts := {}
	var remainders := []
	var given := 0
	for kind in kinds:
		var n: int = by_kind[kind].size()
		if n < PACK_MIN:
			continue
		var share := float(PACKS_BIG_COUNT) * n / total
		counts[kind] = mini(floori(share), n / PACK_MIN)
		given += counts[kind]
		remainders.append([share - counts[kind], kind])
	remainders.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var i := 0
	while given < PACKS_BIG_COUNT and i < remainders.size() * 4:
		var kind: EnemyData = remainders[i % remainders.size()][1]
		if (counts[kind] + 1) * PACK_MIN <= by_kind[kind].size():
			counts[kind] += 1
			given += 1
		i += 1
	return counts if given == PACKS_BIG_COUNT else {}

static func _has_elite(pack: Array) -> bool:
	return pack.any(func(a: Array) -> bool: return a[2])

# The gap between packs if they fill the window end to end.
static func _pack_gap(packs: Array, span: Vector2, big: bool = false) -> float:
	var used := 0.0
	for pack in packs:
		used += _pack_step(pack, big) * (pack.size() - 1)
	return (span.y - span.x - used) / maxf(packs.size() - 1, 1)

# Seeded order; packs with a Deeply Blighted take the middle places (one: the middle pack).
static func _order_packs(packs: Array, rng: RandomNumberGenerator) -> void:
	var plain: Array = packs.filter(func(pack: Array) -> bool: return not _has_elite(pack))
	var elite: Array = packs.filter(func(pack: Array) -> bool: return _has_elite(pack))
	_shuffle(plain, rng)
	_shuffle(elite, rng)
	var places: Array = range(packs.size())
	var middle := (packs.size() - 1) / 2.0
	places.sort_custom(_nearer_middle.bind(middle))
	var ordered: Array = []
	ordered.resize(packs.size())
	for i in elite.size():
		ordered[places[i]] = elite[i]
	var next := 0
	for i in ordered.size():
		if ordered[i] == null:
			ordered[i] = plain[next]
			next += 1
	packs.assign(ordered)

static func _nearer_middle(a: int, b: int, middle: float) -> bool:
	if absf(a - middle) != absf(b - middle):
		return absf(a - middle) < absf(b - middle)
	return a < b

static func _crowded(schedule: Array) -> bool:
	var start := 0
	for i in schedule.size():
		while float(schedule[i][0]) - float(schedule[start][0]) > CROWD_SECONDS:
			start += 1
		if i - start + 1 > CROWD_MAX:
			return true
	return false

static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = items[i]
		items[i] = items[j]
		items[j] = swap

# --- Facts (Coming strip, banner, rest report) ----------------------------------------------------------

# From a shaped schedule: {shape, count, packs, pack_size (largest), gap_s (between packs, or between
# arrivals for the other shapes), elites, elite_place ("pack" / "last" / "first" / "")}.
static func describe(schedule: Array, shape: StringName) -> Dictionary:
	var facts := {"shape": shape if shape != &"" else STREAM, "count": schedule.size(), "packs": 0,
		"pack_size": 0, "gap_s": 0.0, "elites": 0, "elite_place": ""}
	var sizes := {}
	var ends := {}  # pack -> Vector2(first time, last time)
	for arrival in schedule:
		if arrival.size() > 2 and arrival[2]:
			facts.elites += 1
		var pack := pack_of(arrival)
		if pack >= 0:
			sizes[pack] = sizes.get(pack, 0) + 1
			var t := float(arrival[0])
			ends[pack] = Vector2(minf(ends[pack].x, t), maxf(ends[pack].y, t)) if ends.has(pack) else Vector2(t, t)
	facts.packs = sizes.size()
	for pack in sizes:
		facts.pack_size = maxi(facts.pack_size, sizes[pack])
	if sizes.size() >= 2:
		var gaps := 0.0
		for p in sizes.size() - 1:
			if ends.has(p) and ends.has(p + 1):
				gaps += ends[p + 1].x - ends[p].y
		facts.gap_s = gaps / (sizes.size() - 1)
	elif schedule.size() >= 2:
		facts.gap_s = (float(schedule[-1][0]) - float(schedule[0][0])) / (schedule.size() - 1)
	if facts.elites > 0:
		match facts.shape:
			PACKS:
				facts.elite_place = "pack" if schedule.any(func(a: Array) -> bool: return a[2] and pack_of(a) >= 0) else ""
			SINGLE_FILE:
				facts.elite_place = "last"
			FEW_AND_TOUGH:
				facts.elite_place = "first"
	return facts
