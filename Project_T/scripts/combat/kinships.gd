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
const DIM_ALPHA := 0.3  # Vines in combat

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
}
# The colours of each family, for vines and Harmony sparks.
const FAMILY_COLORS := {"spore": Color(0.7, 0.9, 0.4), "water": Color(0.45, 0.7, 1.0),
	"light": Color(1.0, 0.95, 0.55), "stone": Color(0.8, 0.75, 0.65), "root": Color(0.65, 0.85, 0.45),
	"song": Color(0.8, 0.65, 1.0), "acorn": Color(0.85, 0.7, 0.45), "wing": Color(1.0, 0.8, 0.55),
	"wind": Color(0.8, 0.95, 0.95)}

static var _branch_of := {}  # Warden id -> its branch's id (tier 2 forms and their final forms)
static var _branches_by_family := {}  # line -> [branch ids] (the hidden one included)
static var force_full := false  # Tests: every Kinship and Whole Tree, as in the full game

var pairs: Array = []  # [{id, a: Tower, b: Tower, key}]
var ages := {}  # Pair key -> drifts stood together
var families := {}  # line -> 0 none, 1 Kindred, 2 Whole Tree
var formed_block := 0
var formed_run := 0
var harmony_block := 0
var harmony_run := 0
var whole_families: Array[String] = []  # Celebrated this run
var _partner := {}  # Tower instance id -> pair
var _refresh_timer := 0.0
var _clock := 0.0
var _harmony_ready := {}  # Pair key -> clock time it can strike again
var _queued: Array = []  # Stage-ups and Whole Trees waiting for the rest
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
	scene.move_child(kin, container.get_index())  # Drawn under the Wardens
	return kin

func _ready() -> void:
	add_to_group(GROUP)
	z_index = -1
	var scene := get_parent()
	_placer = scene.get_node_or_null("%TowerPlacer")
	_seller = scene.get_node_or_null("%TowerSeller")
	var director: DriftDirector = scene.get_node_or_null("%DriftDirector")
	if director:
		director.drift_cleared.connect(_on_drift_cleared)
		director.rest_started.connect(_on_rest_started)
		director.rest_ended.connect(func(_block) -> void: _resting = false)
		_resting = director.is_resting()
	refresh()

func _process(delta: float) -> void:
	_clock += delta
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		refresh()
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

# Re-pairs every Warden (nearest kin first) and recounts the family bonuses.
func refresh() -> void:
	_refresh_timer = REFRESH
	var towers := _towers()
	var edges := []
	for i in towers.size():
		var ta: Tower = towers[i]
		var ba := branch_of(ta.tower_data)
		if ba == "":
			continue
		for j in range(i + 1, towers.size()):
			var tb: Tower = towers[j]
			if tb.tower_data.line != ta.tower_data.line:
				continue
			var bb := branch_of(tb.tower_data)
			if bb == "" or bb == ba:
				continue
			var id := kinship_for(ba, bb)
			if id == &"" or not is_available(id):
				continue
			var distance := _cheb(ta.cell, tb.cell)
			if distance <= REACH:
				# Side A is the Warden from the table's first branch.
				var first: bool = KINSHIPS[id][2] == ba
				edges.append([distance, id, ta if first else tb, tb if first else ta])
	edges.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	var taken := {}
	var new_pairs := []
	for edge in edges:
		var a: Tower = edge[2]
		var b: Tower = edge[3]
		if taken.has(a.get_instance_id()) or taken.has(b.get_instance_id()):
			continue
		taken[a.get_instance_id()] = true
		taken[b.get_instance_id()] = true
		new_pairs.append({"id": edge[1], "a": a, "b": b, "key": _key(edge[1], a.cell, b.cell)})
	# Bonds that ended lose their age (moving or selling resets; evolving keeps the cells).
	var keys := {}
	for pair in new_pairs:
		keys[pair.key] = true
		if not ages.has(pair.key):
			ages[pair.key] = 0
			_on_formed(pair)
	for key in ages.keys():
		if not keys.has(key):
			ages.erase(key)
	pairs = new_pairs
	_partner.clear()
	for pair in pairs:
		_partner[pair.a.get_instance_id()] = pair
		_partner[pair.b.get_instance_id()] = pair
	_count_families(towers)

static func _key(id: StringName, a: Vector2, b: Vector2) -> String:
	return "%s:%d,%d:%d,%d" % [id, a.x, a.y, b.x, b.y]

func _count_families(towers: Array) -> void:
	var present := {}
	for tower in towers:
		var branch := branch_of(tower.tower_data)
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
	for line in families:
		if families[line] == 2 and before.get(line, 0) < 2 and not whole_families.has(line):
			whole_families.append(line)
			_queue(["whole_tree", line])


# --- Queries for the Warden code ---------------------------------------------------------------------

# The pair `tower` is in ({} = none).
func get_pair(tower: Tower) -> Dictionary:
	return _partner.get(tower.get_instance_id(), {})

# The share (0.5 / 0.75 / 1.0) of Kinship `id`'s trait `tower` borrows on `side` ("a": the table's
# first branch borrows from the second; "b": the other way), or 0.
func share(tower: Tower, id: StringName, side: String) -> float:
	var pair := get_pair(tower)
	if pair.is_empty() or pair.id != id or not is_instance_valid(pair.a) or not is_instance_valid(pair.b):
		return 0.0
	if (side == "a") != (pair.a == tower):
		return 0.0
	return STAGE_SHARE[get_stage(pair)]

func get_partner(tower: Tower) -> Tower:
	var pair := get_pair(tower)
	if pair.is_empty():
		return null
	return pair.b if pair.a == tower else pair.a

func get_stage(pair: Dictionary) -> int:
	var drifts: int = ages.get(pair.key, 0)
	var stage := 0
	for i in STAGE_DRIFTS.size():
		if drifts >= STAGE_DRIFTS[i]:
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
	var pair := get_pair(tower)
	if pair.is_empty():
		return ""
	var partner := get_partner(tower)
	var stage := get_stage(pair)
	var text := "Kin: %s · %s · %s" % [partner.tower_data.display_name if partner else "?",
		KINSHIPS[pair.id][0], STAGE_NAMES[stage]]
	if stage < STAGE_DRIFTS.size() - 1:
		var left: int = STAGE_DRIFTS[stage + 1] - ages.get(pair.key, 0)
		text += " (%d drift%s to %s)" % [left, "" if left == 1 else "s", STAGE_NAMES[stage + 1]]
	return text

# The Kinship a Warden of `data` planted on `cell` would form ({} = none): {id, name, partner}. For the
# build ghost's PlacementLinks ("Forms Kinship: Slumber Rot").
func preview(data: TowerData, cell: Vector2) -> Dictionary:
	var branch := branch_of(data)
	if branch == "":
		return {}
	var best := {}
	var best_distance := INF
	for tower in _towers():
		if tower.tower_data.line != data.line or not get_pair(tower).is_empty():
			continue
		var other := branch_of(tower.tower_data)
		if other == "" or other == branch:
			continue
		var id := kinship_for(branch, other)
		var distance := _cheb(tower.cell, cell)
		if id != &"" and is_available(id) and distance <= REACH and distance < best_distance:
			best_distance = distance
			best = {"id": id, "name": KINSHIPS[id][0], "partner": tower}
	return best


# --- Harmony strike ----------------------------------------------------------------------------------

# `tower` just hit `enemy` for `dealt`. If its kin hit the same nightmare within 1 s, a Harmony strike
# bursts: 1× the weaker Warden's hit (×1.5 at Old Kin), effect damage, no crit, 2 s per pair.
func note_hit(tower: Tower, enemy: Node2D, dealt: float) -> void:
	var pair := get_pair(tower)
	if pair.is_empty() or not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	var hits: Dictionary = enemy.get_meta(&"kin_hits", {})
	hits[tower.get_instance_id()] = [_clock, dealt]
	enemy.set_meta(&"kin_hits", hits)
	var partner := get_partner(tower)
	if partner == null or not hits.has(partner.get_instance_id()):
		return
	var theirs: Array = hits[partner.get_instance_id()]
	if _clock - theirs[0] > HARMONY_WINDOW or _clock < _harmony_ready.get(pair.key, 0.0):
		return
	_harmony_ready[pair.key] = _clock + HARMONY_COOLDOWN
	var weaker: Tower = tower if tower.get_damage() <= partner.get_damage() else partner
	var damage := weaker.get_damage() * (HARMONY_OLD_KIN if get_stage(pair) == 2 else 1.0)
	harmony_block += 1
	harmony_run += 1
	_spark(enemy.global_position, pair)
	harmony_struck.emit(tower, enemy)
	# Credited to the Warden whose hit just landed, so DamageLog merges it into that hit's number (green).
	enemy.take_damage(damage, tower.tower_data.line, true, false, tower, &"harmony")


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
	# Old Growth (Elder Stump line): +2 Dew per drift, at the bond's share.
	var run_state: RunState = get_parent().get_node_or_null("%RunState")
	for pair in pairs:
		if pair.id == &"old_growth" and is_instance_valid(pair.a) and run_state:
			var dew := roundi(2.0 * share(pair.a, &"old_growth", "a"))
			if dew > 0:
				run_state.earn_dew_at(dew, pair.a.global_position)
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
		"whole_tree":
			family_whole.emit(event[1])
			var map = get_parent().get_node_or_null("%MapGenerator")
			if _effects() == 0 and map and map.heartwood:
				var sigil := Fx.play(&"whole_tree_sigil", map.heartwood.global_position, get_parent())
				if sigil:
					sigil.modulate = FAMILY_COLORS.get(event[1], Color(0.85, 0.9, 0.55))

# 0 Full, 1 Subtle, 2 Off (settings "Kinship effects").
static func _effects() -> int:
	return int(HeartwoodMemory.get_settings().get("kinship_effects", 0))

func _colour(pair: Dictionary) -> Color:
	return FAMILY_COLORS.get(KINSHIPS[pair.id][1], Color(0.8, 0.95, 0.6))


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
		var colour := Color(_colour(pair), alpha)
		var sheet: StringName = [&"kin_vine_sapling", &"kin_vine_blooming", &"kin_vine_oldkin"][stage]
		var tex := Fx.texture(sheet)
		if tex != null:
			# Tile the 32×10 swaying segment along the pair (anchored at its middle row).
			var entry := Fx.info(sheet)
			var frames: int = int(entry.get("frames", 4))
			var fps: float = float(entry.get("fps", 4.0))
			var frame := int(_clock * fps) % maxi(frames, 1)
			var seg := Vector2(tex.get_width() / float(frames), tex.get_height())
			var length := from.distance_to(to)
			draw_set_transform(from, from.angle_to_point(to))
			var x := 0.0
			while x < length:
				var w := minf(seg.x, length - x)
				draw_texture_rect_region(tex, Rect2(x, -seg.y / 2.0, w, seg.y),
					Rect2(seg.x * frame, 0, w, seg.y), colour)
				x += seg.x
			draw_set_transform(Vector2.ZERO)
			continue
		var bend := (to - from).orthogonal().normalized() * 6.0
		var points := PackedVector2Array()
		for i in 9:
			var t := i / 8.0
			points.append(from.lerp(to, t) + bend * sin(t * TAU))
		draw_polyline(points, Color(0.2, 0.35, 0.15, alpha * 0.8), 2.0 + stage * 1.5)
		draw_polyline(points, colour, 1.0 + stage)
		if stage >= 1:
			for i in [2, 6]:  # Leaves
				draw_circle(points[i] + bend.normalized() * 3.0, 2.0 + stage, Color(0.45, 0.75, 0.35, alpha))
		if stage >= 2:
			draw_circle(points[4], 3.5, Color(1.0, 0.85, 0.9, alpha))  # A flower (Old Kin)

func _burst(at: Vector2, pair: Dictionary) -> void:
	var burst := Fx.play(&"kin_bond_burst", at, get_parent())
	if burst:
		burst.modulate = _colour(pair)
		return
	var fallback := KinBurst.new(_colour(pair), 0.5, 26.0)
	get_parent().add_child(fallback)
	fallback.global_position = at

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
		"harmony": harmony_run}

func load_save(data: Dictionary) -> void:
	ages = data.get("ages", {}).duplicate()
	whole_families.assign(data.get("whole", []))
	formed_run = int(data.get("formed", 0))
	harmony_run = int(data.get("harmony", 0))
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
		draw_circle(Vector2.ZERO, Tower.MAP_GRID.cell_size.x * 0.45, Color(0.8, 0.88, 0.95, 0.22 * fade))


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
			var colour := _colour if i % 2 == 0 else Color(1.0, 0.92, 0.95)
			draw_circle(dir * _size * t, 3.0 * (1.0 - t) + 1.0, Color(colour, 1.0 - t))
