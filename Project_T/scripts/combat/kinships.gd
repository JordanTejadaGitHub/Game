extends Node2D
class_name Kinships

# Kinships (tower_design.md "Kinships: two branches of one family"; feedback in screens_ui.md
# "Kinship feedback"). A Warden of one branch and a Warden of a different branch of the same family
# (branch or final form) within 2 cells bond; each borrows a trait from the other. One Kinship per
# Warden (the nearest kin bonds). Bonds grow with drifts together (Sapling 50%, Blooming 75% at 5,
# Old Kin 100% at 10); moving or selling resets, evolving keeps. Harmony strike: both kin hit the
# same nightmare within 1 s = bonus effect damage, never a Reaction chain link. Kindred (2 branches of
# a family on the map) +10% damage; Whole Tree (all 3, full game) +20%.
#
# One per run, made on first use in the run's scene (like ReactionTracker), drawn under the Wardens.
# Traits are read by the Warden code through share(tower, kinship_id, side).

signal kinship_formed(kinship: StringName, a: Tower, b: Tower)  # A bond formed (discovery card, Codex)
# Sound (SoundHooks connects these by name). `family` = TowerData.line.
signal kin_bonded(family: String, where: Vector2)  # The two-note chord
signal kin_stage_grew(family: String, stage: int, where: Vector2)  # Blooming / Old Kin, at the rest after
signal harmony_struck(tower: Tower, enemy: Node2D)
signal family_whole(family: String)  # Whole Tree, at the rest after it happened (once per family per run)

const GROUP := &"kinships"
const REACH := 2.0  # Cells (square: Chebyshev)
const REFRESH := 0.5  # Seconds between pairings
const STAGE_DRIFTS: Array[int] = [0, 5, 10]  # Sapling, Blooming, Old Kin
const STAGE_SHARE: Array[float] = [0.5, 0.75, 1.0]
const STAGE_NAMES: Array[String] = ["Sapling", "Blooming", "Old Kin"]
const HARMONY_WINDOW := 1.0  # Seconds between the two kin's hits
const HARMONY_COOLDOWN := 2.0  # Per pair
const HARMONY_OLD_KIN := 1.5
const KINDRED_BONUS := 0.10
const WHOLE_TREE_BONUS := 0.20
const DIM_ALPHA := 0.5  # Vines during drifts (playtest: 0.3 was easy to miss)
# Kinship cards (dream_design.md "Kinship cards: going deep")
const FAMILY_TIES_PER := 0.20  # Family Ties: Wardens in a Kinship, per stack (dream_audit.md)
const BLOOD_BONDED := 0.50  # Blood is Thicker (bittersweet): in a Kinship… (dream_audit.md)
const BLOOD_UNBONDED := 0.15  # …and the cost for attacking Wardens not in one
const GROVE_OF_KIN_PER := 0.05  # Grove of Kin: every Warden, per Kinship on the map… (dream_audit.md)
const GROVE_OF_KIN_MAX := 0.50
const SWEET_BONUS: Array[float] = [0.5, 1.0]  # Sweet Harmony (II)
const SWEET_COOLDOWN: Array[float] = [1.5, 1.0]
const BEAD_COOLDOWN := 0.6  # Seconds between light beads on one vine
const VINE_REDRAW_FPS := 8.0  # The vine sheets sway at 4 fps; the Old Kin arch too

# id -> [name, family line, branch A, branch B, in the demo]
const KINSHIPS := {
	&"slumber_rot": ["Slumber Rot", "spore", "driftspore", "bloomcap", true],
	&"rainfog": ["Rainfog", "water", "rain_lily", "mistveil", true],
	&"storm_beacon": ["Storm Beacon", "light", "stormcap", "lanternmoth", true],
	&"hammer_and_anvil": ["Hammer and Anvil", "stone", "mossback", "standing_stone", false],
	&"snare": ["Snare", "root", "rootcurl", "tangleroot", false],
	&"night_chimes": ["Night Chimes", "song", "chime_stone", "dreamcatcher", false],
	&"old_growth": ["Old Growth", "acorn", "elder_stump", "dewcatcher", false],
	&"flock_together": ["Flock Together", "wing", "wrens_nest", "magpie_perch", false],
	&"dust_devil": ["Dust Devil", "wind", "gust", "pinwheel", false],
	# The 9 hidden Kinships: the hidden branch is A (full game only; a final form counts as its branch).
	&"spore_nursery": ["Spore Nursery", "spore", "fairy_ring", "driftspore", false],
	&"hoar_fog": ["Hoar Fog", "water", "frostfern", "mistveil", false],
	&"sunspot": ["Sunspot", "light", "sunpetal", "lanternmoth", false],
	&"spotter": ["Spotter", "stone", "cairn", "standing_stone", false],
	&"lantern_roots": ["Lantern Roots", "root", "rootlight", "tangleroot", false],
	&"resonant_hollow": ["Resonant Hollow", "song", "echo_hollow", "chime_stone", false],
	&"true_graft": ["True Graft", "acorn", "graftling", "elder_stump", false],
	&"jewel_thieves": ["Jewel Thieves", "wing", "hummingbird_bower", "magpie_perch", false],
	&"tailwind": ["Tailwind", "wind", "samara", "gust", false],
}
# The colours of each family, for vines and Harmony sparks.
const FAMILY_COLORS := {"spore": Palette.NEWLEAF, "water": Palette.DEWLIGHT,  # One palette colour each
	"light": Palette.GLOW, "stone": Palette.DEADWOOD, "root": Palette.SPRIG,
	"song": Palette.BLOSSOM, "acorn": Palette.GOLD, "wing": Palette.HEARTLIGHT,
	"wind": Palette.MOONLIGHT}

# Each branch's own colour: a bonded Warden's attacks carry its kin's (borrowed looks, 2026-09-29).
const BRANCH_COLORS := {"driftspore": Palette.SPRIG, "bloomcap": Palette.BLOSSOM,
	"rain_lily": Palette.DEWLIGHT, "mistveil": Palette.MOONLIGHT, "stormcap": Palette.DEWLIGHT,
	"lanternmoth": Palette.GLOW, "mossback": Palette.SPRIG, "standing_stone": Palette.MIST,
	"rootcurl": Palette.DEADWOOD, "tangleroot": Palette.SPRIG, "chime_stone": Palette.BLOSSOM,
	"dreamcatcher": Palette.ORCHID, "elder_stump": Palette.DEADWOOD, "dewcatcher": Palette.GLOW,
	"wrens_nest": Palette.GOLD, "magpie_perch": Palette.DEWLIGHT, "gust": Palette.MOONLIGHT,
	"pinwheel": Palette.GOLD, "fairy_ring": Palette.NEWLEAF, "frostfern": Palette.MOONLIGHT,
	"sunpetal": Palette.GLOW, "cairn": Palette.DEADWOOD, "rootlight": Palette.GLOW,
	"echo_hollow": Palette.BLOSSOM, "graftling": Palette.SPRIG, "hummingbird_bower": Palette.DEWLIGHT,
	"samara": Palette.GOLD}
const ARCH_ALPHA := 0.6  # The Old Kin arch over a pair
const ARCH_FOOT := Vector2(0, 24)  # Where a Warden's base (its slab's front) is, from its centre
const HARMONY_GOLD := Palette.GLOW  # Old Kin beams lean 30% toward this

static var _branch_of := {}  # Warden id -> its branch's id (tier 2 forms and their final forms)
static var _branches_by_family := {}  # line -> [branch ids] (the hidden one included)
static var force_full := false  # Tests: every Kinship and Whole Tree, as in the full game

var pairs: Array = []  # [{id, a: Tower, b: Tower, key}]
var ages := {}  # Pair key -> drifts stood together
var families := {}  # line -> 0 none, 1 Kindred, 2 Whole Tree
var version := 0  # Bumped when the pairs or the families change (Tower._stats_fresh reads it, not the dictionaries)
var formed_block := 0
var formed_run := 0
var harmony_block := 0
var harmony_run := 0
var whole_families: Array[String] = []  # Celebrated this run
var kindred_shown := false  # The run's first Kindred was called out
var _partner := {}  # Tower instance id -> pair
var _refresh_timer := 0.0
var _clock := 0.0
var _harmony_ready := {}  # Pair key -> clock time it can strike again
var _queued: Array = []  # Stage-ups and Whole Trees waiting for the rest
var _remembered := {}  # Rooted Bond: partner instance id -> the sold kin's bond age, until the rest ends
var _bead_ready := {}  # Pair key -> clock time the vine can carry another bead
var _synced := {}  # Pair keys whose idle animations were synced
var _drawn_key := []  # What the vines were last drawn for (see _process)
var _resting := true
var _placer: TowerPlacer
var _seller: TowerSeller

# The run's Kinships, made on first use inside the scene `near` belongs to.
static func find(near: Node) -> Kinships:
	if near == null or not near.is_inside_tree():
		return null
	var kin := near.get_tree().get_first_node_in_group(GROUP) as Kinships
	if kin != null:
		return kin
	var scene := near
	while scene.get_parent() != null and scene.get_parent() != near.get_tree().root:
		scene = scene.get_parent()
	var container := scene.get_node_or_null("%TowerContainer")
	if container == null:
		return null  # Not a run (a test scene without Wardens)
	kin = Kinships.new()
	kin.name = "Kinships"
	scene.add_child(kin)
	return kin

func _ready() -> void:
	add_to_group(GROUP)
	z_index = -1  # With the ground and path (drawn after them), under the y-sorted Wardens and nightmares
	# Kin knots: a small glowing knot at each partner's base, above the sprites (a bond reads even when the
	# vine is covered; user: "can't see the visual root if they're above each other").
	_knots.name = "KinKnots"
	_knots.z_as_relative = false
	_knots.z_index = 1  # Above the y-sorted Wardens (z 0), under the lighting pass (z 3)
	_knots.draw.connect(_draw_knots)
	add_child(_knots)
	var scene := get_parent()
	_placer = scene.get_node_or_null("%TowerPlacer")
	_seller = scene.get_node_or_null("%TowerSeller")
	# Re-pair right away when the map changes (a sale then a new kin in one moment stay in order).
	if _seller:
		_seller.tower_sold.connect(func(_t, _r) -> void: refresh())
	if _placer:
		_placer.tower_built.connect(func(_t) -> void: refresh.call_deferred())
	var director: DriftDirector = scene.get_node_or_null("%DriftDirector")
	if director:
		director.drift_cleared.connect(_on_drift_cleared)
		director.rest_started.connect(_on_rest_started)
		director.rest_ended.connect(func(_block) -> void:
			_resting = false
			_remembered.clear())  # Rooted Bond: a remembered stage lasts only for that rest
		_resting = director.is_resting()
	refresh()

func _process(delta: float) -> void:
	_clock += delta
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		refresh()
	# Performance: redraw only when the vines' frame or brightness changes (it redrew every frame, vines
	# or not).
	var key := [pairs.size(), int(_clock * VINE_REDRAW_FPS), _resting, _placer != null and _placer.build_mode,
		_seller.selection.size() if _seller else 0, _effects()]
	if key != _drawn_key:
		_drawn_key = key
		queue_redraw()


# --- Who belongs to which branch ---------------------------------------------------------------------

static func _load_branches() -> void:
	if not _branch_of.is_empty():
		return
	var dir := "res://resource/tower/"
	for file in DirAccess.get_files_at(dir):
		var path := dir + file.trim_suffix(".remap")
		if not path.ends_with(".tres"):
			continue
		var data := load(path) as TowerData
		if data == null or data.tier != 2:
			continue
		var id := data.get_id()
		_branch_of[id] = id
		for next in data.evolves_to:
			if next is TowerData and next.tier == 3:
				_branch_of[next.get_id()] = id
		if not _branches_by_family.has(data.line):
			_branches_by_family[data.line] = []
		if not _branches_by_family[data.line].has(id):
			_branches_by_family[data.line].append(id)

# The branch a Warden belongs to ("" for bases, walls, Ascended and Memory Wardens).
static func branch_of(data: TowerData) -> String:
	_load_branches()
	return _branch_of.get(data.get_id(), "")

# A planted Warden's branch: its form's, or for an Ascended form the branch it grew from.
static func branch_for(tower: Tower) -> String:
	if tower._branch_form == tower.tower_data:
		return tower._branch_cached  # Perf: refresh asks for every Warden twice a second
	var branch := branch_of(tower.tower_data)
	if branch == "" and tower.tower_data.tier >= DreamState.ASCENDED_TIER:
		return tower.kin_branch  # Not cached: kin_branch can change while the form stays
	tower._branch_form = tower.tower_data
	tower._branch_cached = branch
	return branch

# The Kinship two branches form ("" if none).
static func kinship_for(branch_a: String, branch_b: String) -> StringName:
	for id in KINSHIPS:
		var row: Array = KINSHIPS[id]
		if (row[2] == branch_a and row[3] == branch_b) or (row[2] == branch_b and row[3] == branch_a):
			return id
	return &""

static func _demo() -> bool:
	return ResultsScreen.is_demo() and not force_full

static func is_available(id: StringName) -> bool:
	return KINSHIPS[id][4] or not _demo()


# --- Pairing -----------------------------------------------------------------------------------------

func _towers() -> Array:
	return get_tree().get_nodes_in_group(Tower.GROUP).filter(func(t) -> bool:
		return is_instance_valid(t) and not t.is_queued_for_deletion() and t.is_inside_tree())

static func _cheb(a: Vector2, b: Vector2) -> float:
	return maxf(absf(a.x - b.x), absf(a.y - b.y))

# Kinship distance is from the nearest footprint cells (a 2×2 Ascended form reaches from any of its four).
static func _distance(a: Tower, b: Tower) -> float:
	var best := INF
	for ca in a.get_cells():
		for cb in b.get_cells():
			best = minf(best, _cheb(ca, cb))
	return best

static func _distance_to_cell(tower: Tower, cell: Vector2) -> float:
	var best := INF
	for c in tower.get_cells():
		best = minf(best, _cheb(c, cell))
	return best

# A Warden's origin cell moved (growing into a 2×2 form): its bonds keep their age.
func note_moved(tower: Tower, old_cell: Vector2) -> void:
	var old := "%d,%d" % [old_cell.x, old_cell.y]
	var now := "%d,%d" % [tower.cell.x, tower.cell.y]
	for pair in pairs:
		if pair.a != tower and pair.b != tower:
			continue
		var parts: PackedStringArray = String(pair.key).split(":")
		if parts.size() != 3:
			continue  # Rooted Bond keys by the Wardens: nothing to move
		for i in [1, 2]:
			if parts[i] == old:
				parts[i] = now
		var key := ":".join(parts)
		if key != pair.key and ages.has(pair.key):
			ages[key] = ages[pair.key]
			ages.erase(pair.key)
			pair.key = key

# Re-pairs every Warden (nearest kin first) and recounts the family bonuses.
func refresh() -> void:
	_refresh_timer = REFRESH
	var towers := _towers()
	# Perf (stacked drifts: 0.7 ms a call with 200+ Wardens): branch_for once per Warden, then pairs only
	# within a family; Sprouts and walls (no branch) never enter the pair loop.
	var by_line := {}
	for tower in towers:
		var branch := branch_for(tower)
		if branch != "":
			var line: String = tower.tower_data.line
			if not by_line.has(line):
				by_line[line] = []
			by_line[line].append([tower, branch])
	var edges := []
	for line in by_line:
		var kin: Array = by_line[line]
		for i in kin.size():
			var ta: Tower = kin[i][0]
			var ba: String = kin[i][1]
			for j in range(i + 1, kin.size()):
				var tb: Tower = kin[j][0]
				var bb: String = kin[j][1]
				if bb == ba:
					continue
				var id := kinship_for(ba, bb)
				if id == &"" or not is_available(id):
					continue
				var distance := _distance(ta, tb)
				if distance <= get_reach():
					# Side A is the Warden from the table's first branch.
					var first: bool = KINSHIPS[id][2] == ba
					edges.append([distance, id, ta if first else tb, tb if first else ta])
	edges.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	# Bonds are sticky (tower_design.md): a bond still in reach is kept before anyone else pairs, so a
	# nearer newcomer never takes it over; nearest-first only matches the Wardens still unbonded.
	var held := {}
	for pair in pairs:
		if is_instance_valid(pair.a) and is_instance_valid(pair.b):
			held["%d:%d" % [pair.a.get_instance_id(), pair.b.get_instance_id()]] = pair.id
	var kept := []
	var rest := []
	for edge in edges:
		var pair_id := "%d:%d" % [edge[2].get_instance_id(), edge[3].get_instance_id()]
		(kept if held.get(pair_id, &"") == edge[1] else rest).append(edge)
	edges = kept + rest
	var taken := {}  # Tower instance id -> bonds so far
	var capacity := 2 if _has(&"extended_family") else 1  # Extended Family: two kin each
	var new_pairs := []
	for edge in edges:
		var a: Tower = edge[2]
		var b: Tower = edge[3]
		if taken.get(a.get_instance_id(), 0) >= capacity or taken.get(b.get_instance_id(), 0) >= capacity:
			continue
		taken[a.get_instance_id()] = taken.get(a.get_instance_id(), 0) + 1
		taken[b.get_instance_id()] = taken.get(b.get_instance_id(), 0) + 1
		new_pairs.append({"id": edge[1], "a": a, "b": b, "key": _key(edge[1], a, b)})
	# Bonds that ended lose their age (moving or selling resets; evolving keeps the cells).
	var keys := {}
	for pair in new_pairs:
		keys[pair.key] = true
	# Rooted Bond: a bond ended by selling one Warden during a rest is remembered by its partner.
	if _has(&"rooted_bond") and _resting:
		for old in pairs:
			if keys.has(old.key):
				continue
			var a_gone: bool = not is_instance_valid(old.a) or old.a.is_queued_for_deletion()
			var b_gone: bool = not is_instance_valid(old.b) or old.b.is_queued_for_deletion()
			if a_gone != b_gone:
				var survivor: Tower = old.b if a_gone else old.a
				var standing := {}  # Wardens already planted: only a kin planted after the sale inherits
				for tower in towers:
					standing[tower.get_instance_id()] = true
				_remembered[survivor.get_instance_id()] = {"age": ages.get(old.key, 0), "standing": standing}
	for pair in new_pairs:
		if not ages.has(pair.key):
			ages[pair.key] = _start_age()
			# …and a new kin planted in reach of that partner during the same rest bonds at the old stage.
			for tower in [pair.a, pair.b]:
				var kin: Tower = pair.b if tower == pair.a else pair.a
				var memory: Dictionary = _remembered.get(tower.get_instance_id(), {})
				if not memory.is_empty() and not memory.standing.has(kin.get_instance_id()):
					ages[pair.key] = maxi(ages[pair.key], memory.age)
					_remembered.erase(tower.get_instance_id())
			_on_formed(pair)
	for key in ages.keys():
		if not keys.has(key):
			ages.erase(key)
	var changed := pairs.size() != new_pairs.size() or pairs.any(func(p) -> bool: return not keys.has(p.key))
	pairs = new_pairs
	if changed:
		version += 1
		for tower in towers:
			tower.queue_redraw()  # Their leaf badges come and go
	_partner.clear()
	for pair in pairs:
		for tower in [pair.a, pair.b]:
			if not _partner.has(tower.get_instance_id()):
				_partner[tower.get_instance_id()] = []
			_partner[tower.get_instance_id()].append(pair)
		_breathe_together(pair)
	_count_families(towers, by_line)

# Breathing together: a bonded pair's idle animations sync (the Warden planted later takes its kin's
# phase), once per bond. Kept in Subtle, off when Kinship effects are Off.
func _breathe_together(pair: Dictionary) -> void:
	if _effects() == 2 or _synced.has(pair.key) or not is_instance_valid(pair.a) or not is_instance_valid(pair.b):
		return
	_synced[pair.key] = true
	var later: Tower = pair.b if pair.b.get_instance_id() > pair.a.get_instance_id() else pair.a
	var first: Tower = pair.a if later == pair.b else pair.b
	later._anim_time = first._anim_time * first.tower_data.animation_fps / maxf(later.tower_data.animation_fps, 0.01)

# A bond's identity: the two Wardens' cells (moving or selling resets), or with Rooted Bond the two
# Wardens themselves (moving keeps it; selling still ends it).
func _key(id: StringName, a: Tower, b: Tower) -> String:
	if _has(&"rooted_bond"):
		return "%s:#%d:#%d" % [id, a.get_instance_id(), b.get_instance_id()]
	return "%s:%d,%d:%d,%d" % [id, a.cell.x, a.cell.y, b.cell.x, b.cell.y]


# --- Kinship cards (dream_design.md "Kinship cards: going deep"), read by rule id ---

func _dreams() -> DreamState:
	return get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState if is_inside_tree() else null

func _has(rule: StringName) -> bool:
	var dreams := _dreams()
	return dreams != null and dreams.has_rule(rule)

func _level(rule: StringName) -> int:
	var dreams := _dreams()
	return dreams.rule_level(rule) if dreams else 0

func _stacks(rule: StringName) -> int:
	var dreams := _dreams()
	return dreams.rule_stacks(rule) if dreams else 0

# Tag resonance (dream_audit.md): the card's numbers scale with owned cards sharing its tags.
func _power(rule: StringName) -> float:
	var dreams := _dreams()
	return dreams.rule_power(rule) if dreams and dreams.has_method("rule_power") else 1.0

# Close Kin: bonds reach 3 cells (II: 4).
func get_reach() -> float:
	if _has(&"close_kin"):
		return 4.0 if _level(&"close_kin") > 0 else 3.0
	return REACH

# Drifts together for each stage; Old Friends (either level) takes 1 off (Quick Bonds merged into it,
# dream_audit.md).
func get_stage_drifts() -> Array[int]:
	var cut := 1 if _has(&"old_friends") else 0
	var result: Array[int] = [0]
	for i in range(1, STAGE_DRIFTS.size()):
		result.append(maxi(STAGE_DRIFTS[i] - cut, 1))
	return result

# Old Friends: new bonds start at Blooming (II: Old Kin), counting on from there.
func _start_age() -> int:
	if not _has(&"old_friends"):
		return 0
	return get_stage_drifts()[2 if _level(&"old_friends") > 0 else 1]

# Kinships on the map (card prerequisites at offer time).
func count() -> int:
	return pairs.size()

static func count_on_map(near: Node) -> int:
	var kin := find(near)
	return kin.count() if kin else 0

# Every damage bonus Kinships give `tower`: Kindred / Whole Tree, Family Ties (+8% per stack in a
# Kinship), Blood is Thicker (+30% in one, −15% not), Grove of Kin (+3% per Kinship, max +30%).
func damage_bonus(tower: Tower) -> float:
	var bonus := family_bonus(tower.tower_data.line)
	var bonded := not get_pairs(tower).is_empty()
	if bonded:
		bonus += FAMILY_TIES_PER * _stacks(&"family_ties") * _power(&"family_ties")
	if _has(&"blood_is_thicker") and tower.tower_data.can_attack:
		bonus += BLOOD_BONDED * _power(&"blood_is_thicker") if bonded else -BLOOD_UNBONDED
	if _has(&"grove_of_kin"):
		bonus += minf(GROVE_OF_KIN_PER * _power(&"grove_of_kin") * pairs.size(), GROVE_OF_KIN_MAX * _power(&"grove_of_kin"))
	return bonus

# `by_line` ({line: [[tower, branch], …]}, from refresh) saves looking every branch up again.
func _count_families(towers: Array, by_line = null) -> void:
	var present := {}
	if by_line is Dictionary:
		for line in by_line:
			present[line] = {}
			for entry in by_line[line]:
				present[line][entry[1]] = true
	else:
		for tower in towers:
			var branch := branch_for(tower)
			if branch == "":
				continue
			var line: String = tower.tower_data.line
			if not present.has(line):
				present[line] = {}
			present[line][branch] = true
	var before := families.duplicate()
	families.clear()
	for line in present:
		var count: int = present[line].size()
		if count >= 3 and not _demo():
			families[line] = 2
		elif count >= 2:
			families[line] = 1
	if families != before:
		version += 1
	for line in families:
		if not kindred_shown and before.get(line, 0) == 0:
			kindred_shown = true  # The first Kindred of the run gets one quiet callout
			_queue(["kindred", line])
	for line in families:
		if families[line] == 2 and before.get(line, 0) < 2 and not whole_families.has(line):
			whole_families.append(line)
			_queue(["whole_tree", line])


# --- Queries for the Warden code ---------------------------------------------------------------------

# The pairs `tower` is in (one; two with Extended Family).
func get_pairs(tower: Tower) -> Array:
	return _partner.get(tower.get_instance_id(), [])

# The first pair `tower` is in ({} = none).
func get_pair(tower: Tower) -> Dictionary:
	var list := get_pairs(tower)
	return list[0] if not list.is_empty() else {}

# The share (0.5 / 0.75 / 1.0) of Kinship `id`'s trait `tower` borrows on `side` ("a": the table's
# first branch borrows from the second; "b": the other way), or 0.
func share(tower: Tower, id: StringName, side: String) -> float:
	var best := 0.0
	for pair in get_pairs(tower):
		if pair.id != id or not is_instance_valid(pair.a) or not is_instance_valid(pair.b):
			continue
		if (side == "a") != (pair.a == tower):
			continue
		best = maxf(best, STAGE_SHARE[get_stage(pair)])
	return best

func get_partner(tower: Tower) -> Tower:
	var pair := get_pair(tower)
	if pair.is_empty():
		return null
	return pair.b if pair.a == tower else pair.a

func get_stage(pair: Dictionary) -> int:
	var drifts: int = ages.get(pair.key, 0)
	var thresholds := get_stage_drifts()
	var stage := 0
	for i in thresholds.size():
		if drifts >= thresholds[i]:
			stage = i
	return stage

# Kindred / Whole Tree: the damage bonus for Wardens of family `line`.
func family_bonus(line: String) -> float:
	match families.get(line, 0):
		1:
			return KINDRED_BONUS
		2:
			return WHOLE_TREE_BONUS
	return 0.0

# "Slumber Rot · Blooming (3 drifts to Old Kin)" for the Warden panel ("" = not in a Kinship).
func describe(tower: Tower) -> String:
	var lines: Array[String] = []
	var thresholds := get_stage_drifts()
	for pair in get_pairs(tower):
		var partner: Tower = pair.b if pair.a == tower else pair.a
		var stage := get_stage(pair)
		var text := "Kin: %s · %s · %s" % [partner.tower_data.display_name if is_instance_valid(partner) else "?",
			KINSHIPS[pair.id][0], STAGE_NAMES[stage]]
		if stage < thresholds.size() - 1:
			var left: int = thresholds[stage + 1] - ages.get(pair.key, 0)
			text += " (%d drift%s to %s)" % [left, "" if left == 1 else "s", STAGE_NAMES[stage + 1]]
		lines.append(text)
	return "\n".join(lines)

# For a branch Warden with no kin, what would bond it: "No kin. A Chime Stone within 2 cells would form
# Night Chimes." (+ "(unlock Chime Stone with Dreamlight)" if that branch is locked). "" otherwise.
func no_kin_hint(tower: Tower) -> String:
	if not get_pairs(tower).is_empty():
		return ""
	var branch := branch_for(tower)
	if branch == "":
		return ""
	for id in KINSHIPS:
		var row: Array = KINSHIPS[id]
		if not is_available(id) or (row[2] != branch and row[3] != branch):
			continue
		var other: String = row[3] if row[2] == branch else row[2]
		var other_data := load("res://resource/tower/%s.tres" % other) as TowerData
		var name := other_data.display_name if other_data else other.capitalize()
		var text := "No kin. A %s within %d cells would form %s." % [name, int(get_reach()), row[0]]
		var dreams := _dreams()
		if dreams and not dreams.is_unlocked(other):
			text += " (unlock %s with Dreamlight)" % name
		return text
	return ""

# Cells where a Warden of `data` would find a kin: within reach of an unbonded Warden of its family's
# other branch (for the build ghost's leaf outlines). {cell: Kinship id}.
func kin_spots(data: TowerData) -> Dictionary:
	var branch := branch_of(data)
	var spots := {}
	if branch == "":
		return spots
	var reach := int(get_reach())
	var capacity := 2 if _has(&"extended_family") else 1
	for tower in _towers():
		if tower.tower_data.line != data.line or get_pairs(tower).size() >= capacity:
			continue
		var other := branch_for(tower)
		var id := kinship_for(branch, other) if other != "" and other != branch else &""
		if id == &"" or not is_available(id):
			continue
		var own: Array[Vector2] = tower.get_cells()
		for base in own:
			for dx in range(-reach, reach + 1):
				for dy in range(-reach, reach + 1):
					var cell: Vector2 = base + Vector2(dx, dy)
					if not own.has(cell):
						spots[cell] = id
	return spots

# The Kinship a Warden of `data` planted on `cell` would form ({} = none): {id, name, partner}. For the
# build ghost's PlacementLinks ("Forms Kinship: Slumber Rot").
func preview(data: TowerData, cell: Vector2) -> Dictionary:
	var branch := branch_of(data)
	if branch == "":
		return {}
	var best := {}
	var best_distance := INF
	for tower in _towers():
		if tower.tower_data.line != data.line or get_pairs(tower).size() >= (2 if _has(&"extended_family") else 1):
			continue
		var other := branch_for(tower)
		if other == "" or other == branch:
			continue
		var id := kinship_for(branch, other)
		var distance := _distance_to_cell(tower, cell)
		if id != &"" and is_available(id) and distance <= REACH and distance < best_distance:
			best_distance = distance
			best = {"id": id, "name": KINSHIPS[id][0], "partner": tower}
	return best


# --- Harmony strike ----------------------------------------------------------------------------------

# `tower` just hit `enemy` for `dealt`. If its kin hit the same nightmare within 1 s, a Harmony strike
# bursts: 1× the weaker Warden's hit (×1.5 at Old Kin), effect damage, no crit, 2 s per pair.
func note_hit(tower: Tower, enemy: Node2D, dealt: float) -> void:
	if get_pairs(tower).is_empty() or not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	var hits: Dictionary = enemy.get_meta(&"kin_hits", {})
	hits[tower.get_instance_id()] = [_clock, dealt]
	enemy.set_meta(&"kin_hits", hits)
	for pair in get_pairs(tower):
		var partner: Tower = pair.b if pair.a == tower else pair.a
		if not is_instance_valid(partner) or not hits.has(partner.get_instance_id()):
			continue
		var theirs: Array = hits[partner.get_instance_id()]
		if _clock - theirs[0] > HARMONY_WINDOW or _clock < _harmony_ready.get(pair.key, 0.0):
			continue
		# Sweet Harmony: +50% and a 1.5 s cooldown (II: +100%, 1 s).
		var sweet := -1
		if _has(&"sweet_harmony"):
			sweet = _level(&"sweet_harmony")
		_harmony_ready[pair.key] = _clock + (SWEET_COOLDOWN[sweet] if sweet >= 0 else HARMONY_COOLDOWN)
		var weaker: Tower = tower if tower.get_damage() <= partner.get_damage() else partner
		var damage := weaker.get_damage() * (HARMONY_OLD_KIN if get_stage(pair) == 2 else 1.0)
		if sweet >= 0:
			damage *= 1.0 + SWEET_BONUS[sweet]
		harmony_block += 1
		harmony_run += 1
		_harmony_look(enemy.global_position, pair)
		harmony_struck.emit(tower, enemy)
		# Credited to the Warden whose hit just landed, so DamageLog merges it into that hit's number (green).
		enemy.take_damage(damage, tower.tower_data.line, true, false, tower, &"harmony")
		# Spore Kin (Dream): a Sporeling-line pair's Harmony strike also poisons.
		if _has(&"spore_kin") and tower.tower_data.line == "spore" and is_instance_valid(enemy) and not enemy.is_cleansed:
			tower._apply_one_status(enemy, EnemyStatuses.SPORED, roundi(DreamState.SPORE_KIN_SPORED * _power(&"spore_kin")), weaker.get_damage())
		# Kin and Kindling: the strike also applies both Wardens' statuses (1 stack each); they can
		# complete Reactions, but the strike itself is never a chain link.
		if _has(&"kin_and_kindling"):
			for kin_warden in [pair.a, pair.b]:
				if is_instance_valid(kin_warden) and is_instance_valid(enemy) and not enemy.is_cleansed \
						and kin_warden.attack_data.applies_status != &"":
					kin_warden._apply_one_status(enemy, kin_warden.attack_data.applies_status, 1, kin_warden.get_damage())
		if not is_instance_valid(enemy) or enemy.is_cleansed:
			return

# --- Bond moments ------------------------------------------------------------------------------------

func _on_formed(pair: Dictionary) -> void:
	formed_block += 1
	formed_run += 1
	var mid: Vector2 = (pair.a.global_position + pair.b.global_position) / 2.0
	kinship_formed.emit(pair.id, pair.a, pair.b)
	kin_bonded.emit(KINSHIPS[pair.id][1], mid)
	if _effects() == 0:
		Fx.callout("Kinship: %s" % KINSHIPS[pair.id][0], _colour(pair), mid, get_parent(), &"kinship")
		if not Fx.reduce_flashes():
			_burst(pair.a.global_position, pair)
			_burst(pair.b.global_position, pair)
			# The vine grows from one to the other, ending on a flower.
			var grow := Fx.segment(&"kin_vine_grow", pair.a.global_position, pair.b.global_position, get_parent(), 0.8)
			if grow:
				grow.modulate = _colour(pair)

func _on_drift_cleared(_number: int, _bonus: int, _perfect: bool) -> void:
	for pair in pairs:
		var before := get_stage(pair)
		ages[pair.key] = ages.get(pair.key, 0) + 1
		var after := get_stage(pair)
		if after > before:
			_queue(["grew", pair, after])  # Stage-ups wait for the rest

func _queue(event: Array) -> void:
	if _resting:
		_announce(event)
	else:
		_queued.append(event)

func _on_rest_started(_block: int, _boss: bool, _bonus: int, _perfect: bool) -> void:
	_resting = true
	for event in _queued:
		_announce(event)
	_queued.clear()
	formed_block = 0
	harmony_block = 0

func _announce(event: Array) -> void:
	match event[0]:
		"grew":
			var pair: Dictionary = event[1]
			if not is_instance_valid(pair.a) or not is_instance_valid(pair.b):
				return
			var mid: Vector2 = (pair.a.global_position + pair.b.global_position) / 2.0
			kin_stage_grew.emit(KINSHIPS[pair.id][1], event[2], mid)
			if _effects() == 0:
				Fx.callout("%s: %s" % [KINSHIPS[pair.id][0], STAGE_NAMES[event[2]]], _colour(pair), mid,
					get_parent(), &"kinship")
				for tower in [pair.a, pair.b]:
					var up := Fx.play(&"kin_stage_up", tower.global_position, get_parent())
					if up:
						up.modulate = _colour(pair)
		"kindred":
			var line: String = event[1]
			var kin_towers := _towers().filter(func(t: Tower) -> bool: return t.tower_data.line == line and branch_for(t) != "")
			if _effects() != 2 and not kin_towers.is_empty():
				var at: Vector2 = kin_towers[-1].global_position + Vector2(0, -40)
				Fx.callout("Kindred: the %s family +%d%%" % [NightmareIcons.family_name(line), roundi(KINDRED_BONUS * 100)],
					FAMILY_COLORS.get(line, Palette.NEWLEAF), at, get_parent(), &"kinship")
		"whole_tree":
			family_whole.emit(event[1])
			var map = get_parent().get_node_or_null("%MapGenerator")
			if _effects() == 0 and map and map.heartwood:
				var sigil := Fx.play(&"whole_tree_sigil", map.heartwood.global_position, get_parent())
				if sigil:
					sigil.modulate = FAMILY_COLORS.get(event[1], Palette.NEWLEAF)

# 0 Full, 1 Subtle, 2 Off (settings "Kinship effects").
static func _effects() -> int:
	return int(Fx.setting("kinship_effects", 0))  # Cached (get_settings reads the profile from disk)

func _colour(pair: Dictionary) -> Color:
	return FAMILY_COLORS.get(KINSHIPS[pair.id][1], Palette.NEWLEAF)


# --- Drawing -----------------------------------------------------------------------------------------

# Vines under each pair: dim and still in combat, full in build mode, when one of the pair is
# selected, or at a rest. Thicker and leafier with each bond stage.
func _draw() -> void:
	var mode := _effects()
	if mode == 2:
		return
	var bright_all: bool = _resting or (_placer != null and _placer.build_mode)
	for pair in pairs:
		if not is_instance_valid(pair.a) or not is_instance_valid(pair.b):
			continue
		var selected: bool = _seller != null and (_seller.selection.has(pair.a) or _seller.selection.has(pair.b))
		var bright := (bright_all or selected) and mode == 0 and not Fx.reduce_flashes()
		var alpha := 1.0 if bright else DIM_ALPHA
		var stage := get_stage(pair)
		var from := to_local(pair.a.global_position)
		var to := to_local(pair.b.global_position)
		# Start and end the vine at each Warden's edge, not under its sprite (Ascended art is big).
		var direction := (to - from).normalized()
		from += direction * _edge(pair.a)
		to -= direction * _edge(pair.b)
		if from.distance_to(to) < 8.0:
			continue
		_draw_vine(pair, stage, mode, alpha)
	_knots.queue_redraw()

var _knots := Node2D.new()
const KNOT_RADIUS := 3.0

# One knot per bonded Warden, at its base's front edge, in the family colour (Subtle: fainter; Off: none).
func _draw_knots() -> void:
	var mode := _effects()
	if mode == 2:
		return
	var alpha := 0.9 if mode == 0 else 0.55
	var seen := {}
	for pair in pairs:
		if not is_instance_valid(pair.a) or not is_instance_valid(pair.b):
			continue
		for tower in [pair.a, pair.b]:
			if seen.has(tower):
				continue
			seen[tower] = true
			var at := _knots.to_local(tower.global_position + ARCH_FOOT)
			draw_knot(_knots, at, _colour(pair), alpha)

static func draw_knot(canvas: CanvasItem, at: Vector2, colour: Color, alpha: float) -> void:
	canvas.draw_circle(at, KNOT_RADIUS + 1.5, Color(Palette.DEEPMOSS, 0.7 * alpha))
	canvas.draw_circle(at, KNOT_RADIUS, Color(colour, alpha))
	canvas.draw_circle(at + Vector2(-0.8, -0.8), 1.2, Color(Palette.HEARTLIGHT, 0.8 * alpha))  # Its glint

# The Kinship vine (tower_design.md / screens_ui.md, playtest "kinship" 2026-10-01): a thin, slightly
# wavy vine in the family colour on the ground, base to base (it was a tinted 32x10 strip at body
# height, which read as a debug bar). Sapling: a bare vine; Blooming: leaves and buds; Old Kin: flowers.
# Fainter over path tiles (nightmares walk there). Subtle mode: fainter, no leaves or flowers.
const VINE_WIDTH := 3.0
const VINE_WAVE := 2.5  # px either side
const VINE_WAVELENGTH := 26.0
const VINE_PATH_ALPHA := 0.45  # Its share of the vine's alpha over path tiles

func _draw_vine(pair: Dictionary, stage: int, mode: int, alpha: float) -> void:
	var from: Vector2 = to_local(pair.a.global_position + ARCH_FOOT)
	var to: Vector2 = to_local(pair.b.global_position + ARCH_FOOT)
	var length := from.distance_to(to)
	if length < 8.0:
		return
	if mode == 1:
		alpha *= 0.6
	var dir := (to - from) / length
	var side := dir.orthogonal()
	var bow := bow_offset(pair)  # A hidden bond (vertical / short) bows out beside the sprites
	var path := {}
	for cell in _route_cells_cached():
		path[cell] = true
	var steps := maxi(int(length / 4.0), 4)
	var points := PackedVector2Array()
	var shades: Array[float] = []
	for i in steps + 1:
		var t := float(i) / steps
		var d := length * t
		var p := from + dir * d + bow * 4.0 * t * (1.0 - t) \
			+ side * sin(d / VINE_WAVELENGTH * TAU + pair.a.cell.x) * VINE_WAVE * sin(t * PI)
		points.append(p)
		var on_path: bool = path.has(Tower.MAP_GRID.calculate_grid_coordinates(to_global(p)))
		shades.append(VINE_PATH_ALPHA if on_path else 1.0)
	var colour := _colour(pair)
	for i in steps:
		var a := alpha * shades[i]
		draw_line(points[i], points[i + 1], Color(Palette.DEEPMOSS, 0.55 * a), VINE_WIDTH + 1.5)
		draw_line(points[i], points[i + 1], Color(colour, a), VINE_WIDTH)
	if mode != 0:
		return
	# Leaves (Blooming on), buds (Blooming), flowers (Old Kin): along the vine, off its path tiles.
	var spacing := 14.0
	var n := int(length / spacing)
	for k in range(1, n):
		var i := clampi(int(float(k) / n * steps), 0, steps)
		if shades[i] < 1.0:
			continue
		var p := points[i]
		var out := side * (1.0 if k % 2 == 0 else -1.0)
		if stage >= 1:
			var leaf := p + out * 3.0
			draw_colored_polygon(PackedVector2Array([p, leaf + dir * 2.0, leaf + out * 2.0, leaf - dir * 2.0]),
				Color(Palette.SPRIG, alpha * 0.9))
		if stage == 1 and k % 3 == 1:
			draw_circle(p - out * 2.0, 1.5, Color(Palette.BLOSSOM, alpha * 0.8))  # A bud
		if stage >= 2 and k % 2 == 1:
			draw_circle(p - out * 2.5, 2.5, Color(Palette.BLOSSOM, alpha))  # A flower
			draw_circle(p - out * 2.5, 1.0, Color(Palette.GLOW, alpha))

# A bond whose straight vine the sprites cover (user: "can't see the visual root if they're above each other"):
# a vertical bond, or any shorter than BOW_UNDER, bows out BOW cells to the side with more free ground
# (a horizontal one bows down, in front of the sprites). Returns the offset at the vine's middle (zero = straight).
const BOW := 0.45  # Cells
const BOW_UNDER := 1.5  # Cells: shorter bonds are mostly under the sprites

func bow_offset(pair: Dictionary) -> Vector2:
	if not is_instance_valid(pair.a) or not is_instance_valid(pair.b):
		return Vector2.ZERO
	var delta: Vector2 = pair.b.global_position - pair.a.global_position
	var cell_size: float = Tower.MAP_GRID.cell_size.x
	var vertical := absf(delta.normalized().y) > 0.8
	if not vertical and delta.length() >= BOW_UNDER * cell_size:
		return Vector2.ZERO  # Diagonal and horizontal bonds stay straight
	if not vertical:
		return Vector2(0, BOW * cell_size)  # Short and level: down, in front of the sprites
	return Vector2(_freer_side(pair) * BOW * cell_size, 0)

# -1 (left) or 1 (right): the side of a vertical pair with fewer Wardens beside it.
func _freer_side(pair: Dictionary) -> float:
	var taken := {}
	for tower in _towers():
		for cell in tower.get_cells():
			taken[cell] = true
	var score := 0
	for tower in [pair.a, pair.b]:
		score += int(taken.has(tower.cell + Vector2.LEFT)) - int(taken.has(tower.cell + Vector2.RIGHT))
	return 1.0 if score >= 0 else -1.0  # Left busier (or a tie): bow right

var _route_cache: Array = []
var _route_cache_at := -1.0
func _route_cells_cached() -> Array:
	if _route_cache_at < 0.0 or _clock - _route_cache_at > 1.0:
		_route_cache = Reactions._route_cells(self)
		_route_cache_at = _clock
	return _route_cache

# Old Kin: a small flowering arch (kin_oldkin_arch, 64x32, feet at (0,31) and (63,31)) spans the pair's
# bases, stretched along x only, never upside down. Full effects only.
func _draw_arch(pair: Dictionary) -> void:
	var tex := Fx.texture(&"kin_oldkin_arch")
	if tex == null:
		return
	var entry := Fx.info(&"kin_oldkin_arch")
	var frames: int = maxi(int(entry.get("frames", 4)), 1)
	var frame := int(_clock * float(entry.get("fps", 4.0))) % frames
	var size := Vector2(tex.get_width() / float(frames), tex.get_height())
	var left: Vector2 = to_local(pair.a.global_position + ARCH_FOOT)
	var right: Vector2 = to_local(pair.b.global_position + ARCH_FOOT)
	if left.x > right.x:
		var swap := left
		left = right
		right = swap
	var length := left.distance_to(right)
	if length < 8.0:
		return
	draw_set_transform(left, left.angle_to_point(right), Vector2(length / (size.x - 1.0), 1.0))
	draw_texture_rect_region(tex, Rect2(Vector2(0, -(size.y - 1.0)), size), Rect2(Vector2(size.x * frame, 0), size),
		Color(branch_colour(pair.a).lerp(branch_colour(pair.b), 0.5).lightened(0.4), ARCH_ALPHA))
	draw_set_transform(Vector2.ZERO)

# How far from a Warden's centre its vine starts: past the slab, and past an Ascended form's big art.
static func _edge(tower: Tower) -> float:
	return 34.0 if tower.tower_data.tier >= DreamState.ASCENDED_TIER else 20.0

func _burst(at: Vector2, pair: Dictionary) -> void:
	var burst := Fx.play(&"kin_bond_burst", at, get_parent())
	if burst:
		burst.modulate = _colour(pair)
		return
	var fallback := KinBurst.new(_colour(pair), 0.5, 26.0)
	get_parent().add_child(fallback)
	fallback.global_position = at

# A Harmony strike's look grows with the bond (2026-09-29): Sapling = the tiny spark; Blooming = petals
# spiral in from both Wardens' sides in their colours; Old Kin = two warm beams from both Wardens
# meeting on the nightmare, a bloom in both colours, then the petals. Subtle / reduce flashes: the spark.
func _harmony_look(at: Vector2, pair: Dictionary) -> void:
	var stage := get_stage(pair)
	if stage == 0 or _effects() != 0 or Fx.reduce_flashes():
		_spark(at, pair)
		return
	var left: Tower = pair.a if pair.a.global_position.x <= pair.b.global_position.x else pair.b
	var right: Tower = pair.b if left == pair.a else pair.a
	var left_colour := branch_colour(left)
	var right_colour := branch_colour(right)
	var shown := false
	if stage == 2:
		for side in [[left, left_colour], [right, right_colour]]:
			var beam := Fx.segment(&"harmony_beam", side[0].global_position + side[0].tower_data.get_attack_origin(), at,
				get_parent(), 0.35)
			if beam:
				beam.modulate = side[1].lerp(HARMONY_GOLD, 0.3)
				shown = true
		var bloom := Fx.play(&"harmony_bloom", at, get_parent())
		if bloom:
			bloom.modulate = left_colour.lerp(right_colour, 0.5)
	for side in [[&"harmony_petals_a", left_colour], [&"harmony_petals_b", right_colour]]:
		var petals := Fx.play(side[0], at, get_parent())
		if petals:
			petals.modulate = side[1]
			shown = true
	if not shown:
		_spark(at, pair)

# A Warden's own branch colour (BRANCH_COLORS; its family's when the branch has none).
static func branch_colour(tower: Tower) -> Color:
	return BRANCH_COLORS.get(branch_for(tower), FAMILY_COLORS.get(tower.tower_data.line, Palette.NEWLEAF))

# A tiny two-colour spark (the harmony_spark sheets; lite when Subtle). Never a callout.
func _spark(at: Vector2, pair: Dictionary) -> void:
	if _effects() == 2:
		return
	var colour := _colour(pair)
	if _effects() == 1:
		var lite := Fx.play(&"harmony_spark_lite", at, get_parent())
		if lite:
			lite.modulate = colour
		return
	var a := Fx.play(&"harmony_spark_a", at, get_parent())
	var b := Fx.play(&"harmony_spark_b", at, get_parent())
	if a:
		a.modulate = colour
	if b:
		b.modulate = colour.lightened(0.4)
	if a == null and b == null:
		var fallback := KinBurst.new(colour, 0.25, 10.0)
		get_parent().add_child(fallback)
		fallback.global_position = at

# Borrowed looks: the colour `tower`'s attacks carry while it's bonded (its kin's branch colour), or a
# transparent colour (not bonded, or Kinship effects Off).
func look_for(tower: Tower) -> Color:
	if _effects() == 2:
		return Color(0, 0, 0, 0)
	var partner := get_partner(tower)
	if partner == null:
		return Color(0, 0, 0, 0)
	return branch_colour(partner)

# A borrowed trait went off on `learner` (Tower._kin_fired): a small bead of light runs along the vine
# from its kin (the teacher) to it. Full effects only, at most one per pair every BEAD_COOLDOWN.
func trait_fired(learner: Tower, id: StringName) -> void:
	if _effects() != 0 or Fx.reduce_flashes():
		return
	for pair in get_pairs(learner):
		if pair.id != id or not is_instance_valid(pair.a) or not is_instance_valid(pair.b):
			continue
		if _clock < _bead_ready.get(pair.key, 0.0):
			return
		_bead_ready[pair.key] = _clock + BEAD_COOLDOWN
		var teacher: Tower = pair.b if pair.a == learner else pair.a
		var direction := (learner.global_position - teacher.global_position).normalized()
		var bead := KinBead.new(teacher.global_position + direction * _edge(teacher),
			learner.global_position - direction * _edge(learner), _colour(pair))
		get_parent().add_child(bead)
		return

# Rainfog (Rain Lily line): a fog patch where a splash landed (1 tile, `seconds`).
func fog_patch(at: Vector2, seconds: float) -> void:
	if seconds <= 0.0:
		return
	var fog := KinFog.new(seconds)
	get_parent().add_child(fog)
	fog.global_position = at


# --- Save ----------------------------------------------------------------------------------------------

func to_save() -> Dictionary:
	return {"ages": ages.duplicate(), "whole": whole_families.duplicate(), "formed": formed_run,
		"harmony": harmony_run, "kindred": kindred_shown}

func load_save(data: Dictionary) -> void:
	ages = data.get("ages", {}).duplicate()
	whole_families.assign(data.get("whole", []))
	formed_run = int(data.get("formed", 0))
	harmony_run = int(data.get("harmony", 0))
	kindred_shown = bool(data.get("kindred", false))
	refresh()  # Saved pairs keep their age and aren't announced again


# Rainfog's fog patch: nightmares within half a tile are in fog (Spored ticks harder) while it lasts.
class KinFog extends Node2D:
	const TICK := 0.25
	var _life: float
	var _age := 0.0
	var _tick := 0.0

	func _init(life: float) -> void:
		_life = life
		z_index = -1

	func _process(delta: float) -> void:
		_age += delta
		if _age >= _life:
			queue_free()
			return
		_tick -= delta
		if _tick <= 0.0:
			_tick = TICK
			for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
				if enemy.global_position.distance_to(global_position) <= Tower.MAP_GRID.cell_size.x * 0.5:
					enemy.statuses.set_in_fog(TICK * 1.5)
		queue_redraw()

	func _draw() -> void:
		var fade := minf(1.0, (_life - _age) / 0.4)
		draw_circle(Vector2.ZERO, Tower.MAP_GRID.cell_size.x * 0.45, Color(Palette.MOONLIGHT, 0.22 * fade))


# A small petal burst or two-colour spark, used when the effect sheets are missing.
class KinBurst extends Node2D:
	var _colour: Color
	var _life: float
	var _size: float
	var _age := 0.0

	func _init(colour: Color, life: float, size: float) -> void:
		_colour = colour
		_life = life
		_size = size
		z_index = 5

	func _process(delta: float) -> void:
		_age += delta
		if _age >= _life:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := _age / _life
		for i in 6:
			var dir := Vector2.from_angle(TAU * i / 6.0 + t * 2.0)
			var colour := _colour if i % 2 == 0 else Palette.HEARTLIGHT
			draw_circle(dir * _size * t, 3.0 * (1.0 - t) + 1.0, Color(colour, 1.0 - t))


# A bead of light (kin_vine_bead, tinted) running along a vine, then gone. Drawn over the vines.
class KinBead extends Node2D:
	const TIME := 0.35
	var _from: Vector2
	var _to: Vector2
	var _age := 0.0

	func _init(from: Vector2, to: Vector2, colour: Color) -> void:
		_from = from
		_to = to
		modulate = colour.lightened(0.3)
		z_index = 2
		rotation = from.angle_to_point(to)

	func _ready() -> void:
		global_position = _from
		if Fx.play(&"kin_vine_bead", _from, self) == null:
			var dot := KinBurst.new(modulate, TIME, 2.0)
			add_child(dot)

	func _process(delta: float) -> void:
		_age += delta
		global_position = _from.lerp(_to, minf(_age / TIME, 1.0))
		if _age >= TIME:
			queue_free()
