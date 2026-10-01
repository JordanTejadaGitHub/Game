extends Node2D
class_name RuleBreakers

# New rule-breaker warning (screens_ui.md "In the world"; human run 5: lost at drift 35 to Phantoms, the
# first flyers, at drift 31: "I didn't notice they would be coming"). A nightmare whose trait breaks the
# maze (any trait_kind but NONE) that this run hasn't faced yet, coming in the next block:
# - the Coming strip shows it first, larger, with a gold "New" tab and its trait in words (ComingStrip);
# - a warning line under the DriftPanel status ("Flyers in drift 31: they ignore your maze");
# - for flyers that cross walls, a faint dashed line from the start straight to the Heartwood for the rest;
# - the first time one walks onto the field, a short name plate over it ("Phantom · flies").
# Once per run per kind; the dashed line stays off once the profile was warned about a kind on 3 runs.
# Made by the HUD, in the world like StartArrows. The static helpers serve ComingStrip and DriftPanel.

const PROFILE_KEY := "rule_breakers_warned"  # {kind: runs it was warned about}
const QUIET_AFTER := 3  # Runs warned, then no dashed line
const PLATE_TIME := 4.0  # Seconds a first-appearance name plate stays
const PLATE_LIFT := 52.0  # Pixels above the nightmare
const DASH := 18.0
const DASH_GAP := 14.0
const LINE_ALPHA := 0.4
const REFRESH := 0.25  # Seconds between checks (real time)

const VERBS := {EnemyData.Trait.FLYING: "flies", EnemyData.Trait.ROLLING: "sprints", EnemyData.Trait.TRAMPLE: "tramples",
	EnemyData.Trait.LEAP: "leaps", EnemyData.Trait.BURROW: "burrows", EnemyData.Trait.WANDER: "wanders"}
const PLURALS := {EnemyData.Trait.FLYING: "Flyers", EnemyData.Trait.ROLLING: "Sprinters", EnemyData.Trait.TRAMPLE: "Tramplers",
	EnemyData.Trait.LEAP: "Leapers", EnemyData.Trait.BURROW: "Burrowers", EnemyData.Trait.WANDER: "Wanderers"}
const WARNINGS := {EnemyData.Trait.FLYING: "they ignore your maze", EnemyData.Trait.ROLLING: "they race down long straights",
	EnemyData.Trait.TRAMPLE: "they break through walls", EnemyData.Trait.LEAP: "they leap over walls",
	EnemyData.Trait.BURROW: "they tunnel under walls", EnemyData.Trait.WANDER: "they stray from the route"}

var director: DriftDirector
var map: Node
var spawner: Node
var line_shown := false  # The dashed flyer line is up (tests)
var _plates: Array = []  # [enemy, seconds left]
var _plated := {}  # Kind -> true: its first-appearance plate was shown this run
var _warned_run := {}  # Kind -> the runs it had been warned about before this one (counted once per run)
var _clock := 0.0

var _plate_layer := Node2D.new()  # Plates draw over the nightmares; the line stays on the ground

func _init(drift_director: DriftDirector = null) -> void:
	director = drift_director

func _ready() -> void:
	z_index = -1  # The dashed line: the route arrows' layer (over the path tiles, under Wardens and nightmares)
	_plate_layer.z_index = 9  # -1 + 9: over the nightmares, like MistCount
	_plate_layer.draw.connect(_draw_plates)
	add_child(_plate_layer)
	map = director.get_node_or_null("%MapGenerator") if director != null else null
	spawner = director.get_node_or_null("%EnemyContainer") if director != null else null
	if spawner != null:
		spawner.child_entered_tree.connect(_on_spawned)

# --- The static rules (ComingStrip, DriftPanel) -----------------------------------------------------

# Whether `data`'s trait breaks the maze (bosses have their dossier instead).
static func breaks_rules(data: EnemyData) -> bool:
	return data != null and not data.is_boss and data.trait_kind != EnemyData.Trait.NONE

# The rule-breakers coming in drifts `first`..`last` that no earlier drift of this run brought:
# [[EnemyData, its first drift there], …], in order of arrival.
static func new_in(drift_director: DriftDirector, first: int, last: int) -> Array:
	if drift_director == null or first > last:
		return []
	var faced := {}
	if first > 1:
		for kind in ComingStrip.kinds_in_range(drift_director, 1, first - 1):
			faced[kind[0].resource_path] = true
	var result: Array = []
	for kind in ComingStrip.kinds_in_range(drift_director, first, last):
		if breaks_rules(kind[0]) and not faced.has(kind[0].resource_path):
			result.append([kind[0], kind[1]])
	return result

# The next block's new rule-breakers while resting ([] during a drift or with none coming).
static func coming(drift_director: DriftDirector) -> Array:
	if drift_director == null or not drift_director.is_resting() or not drift_director.has_next_drift():
		return []
	var per := drift_director.drifts_per_block
	var block := drift_director.get_block(drift_director.drifts_started + 1)
	return new_in(drift_director, (block - 1) * per + 1, mini(block * per, drift_director.get_total_drifts()))

# "Flyers in drift 31: they ignore your maze" (a flyer that keeps to the route: its own words).
static func warning_line(data: EnemyData, drift: int) -> String:
	var what: String = WARNINGS.get(data.trait_kind, "")
	if data.trait_kind == EnemyData.Trait.FLYING and not data.is_through_walls():
		what = "they fly along the route"
	if what == "":
		what = data.trait_text.trim_suffix(".").to_lower()
	return "%s in drift %d: %s" % [PLURALS.get(data.trait_kind, data.display_name), drift, what]

# "Phantom · flies".
static func plate_text(data: EnemyData) -> String:
	return "%s · %s" % [data.display_name, VERBS.get(data.trait_kind, "breaks the rules")]

static func kind_of(data: EnemyData) -> String:
	return data.resource_path.get_file().get_basename()

# Runs the profile was warned about `data` on (the dashed line goes quiet at QUIET_AFTER).
static func runs_warned(data: EnemyData) -> int:
	return int(HeartwoodMemory.load_data().get(PROFILE_KEY, {}).get(kind_of(data), 0))

# --- The world overlay ---------------------------------------------------------------------------------

func _process(delta: float) -> void:
	var real_delta := delta / maxf(Engine.time_scale, 0.001)
	if not _plates.is_empty():
		for plate in _plates:
			plate[1] -= real_delta
		_plates = _plates.filter(func(p: Array) -> bool: return p[1] > 0.0 and is_instance_valid(p[0]) and not p[0].is_cleansed)
		_plate_layer.queue_redraw()
	_clock -= real_delta
	if _clock > 0.0:
		return
	_clock = REFRESH
	var coming_now := coming(director)
	var show_line := false
	for item in coming_now:
		_note_warned(item[0])
		# The dashed line: flyers that cross walls, until the profile was warned about them on QUIET_AFTER earlier runs
		if item[0].is_through_walls() and int(_warned_run[kind_of(item[0])]) < QUIET_AFTER:
			show_line = true
	if show_line != line_shown:
		line_shown = show_line
		queue_redraw()

# Counts this run once per kind in the profile (the real game only; tests never write). `_warned_run` keeps
# the count from before this run.
func _note_warned(data: EnemyData) -> void:
	var kind := kind_of(data)
	if _warned_run.has(kind):
		return
	_warned_run[kind] = runs_warned(data)
	if not _may_write():
		return
	var profile := HeartwoodMemory.load_data()
	var warned: Dictionary = profile.get(PROFILE_KEY, {})
	warned[kind] = int(warned.get(kind, 0)) + 1
	profile[PROFILE_KEY] = warned
	HeartwoodMemory.save_data(profile)

func _may_write() -> bool:
	return is_inside_tree() and director != null and get_tree().current_scene == director.owner and not MetaRun.is_dev_run()

func _on_spawned(node: Node) -> void:
	var data = node.get("enemy_data")
	if not data is EnemyData:
		return
	(func() -> void:  # Its data is set once it's in
		if not is_instance_valid(node):
			return  # Freed the same frame (tests spawn and clear)
		var real: EnemyData = node.get("enemy_data")
		if real == null or not breaks_rules(real) or _plated.has(kind_of(real)):
			return
		_plated[kind_of(real)] = true
		_plates.append([node, PLATE_TIME])
		_plate_layer.queue_redraw()).call_deferred()

func _draw() -> void:
	if line_shown and map != null:
		var from: Vector2 = map.MAP_GRID.calculate_map_position(map.startPath)
		var to: Vector2 = map.MAP_GRID.calculate_map_position(map.endPath)
		var dir := (to - from).normalized()
		var length := from.distance_to(to)
		var at := 0.0
		var colour := Color(Palette.WRAITHLIGHT, LINE_ALPHA)
		while at < length:
			var end := minf(at + DASH, length)
			draw_line(from + dir * at, from + dir * end, colour, 3.0, true)
			at = end + DASH_GAP

func _draw_plates() -> void:
	for plate in _plates:
		if is_instance_valid(plate[0]):
			var at: Vector2 = _plate_layer.to_local(plate[0].global_position)
			WorldLabel.draw_tag(_plate_layer, at.x, at.y - PLATE_LIFT, plate_text(plate[0].enemy_data), UiStyle.INK)
