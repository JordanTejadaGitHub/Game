extends Node2D
class_name RuleBreakers

# New rule-breaker warning (screens_ui.md "In the world"; human run 5: lost at drift 35 to Phantoms, the
# first flyers, at drift 31: "I didn't notice they would be coming"). A nightmare whose trait breaks the
# maze (any trait_kind but NONE) that this run hasn't faced yet, coming in the next block:
# - the Coming strip shows it first, larger, with a gold "New" tab and its trait in words (ComingStrip);
# - a warning line under the DriftPanel status ("Flyers in drift 31: they ignore your maze");
# - for flyers that cross walls, a thin cold-mist line from the start straight to the Heartwood (RouteLine's mist at
#   half width): at every rest before a block that brings them, and faintly while they're on the field. Information,
#   not a tutorial (user: "there's no more arrows for flying units?"): every run, never retired;
# - the first time one walks onto the field, a short name plate over it ("Phantom · flies").
# The "New" tab, the DriftPanel line and the plate are once per run per kind; the mist line follows the schedule.
# Made by the HUD, in the world like StartArrows. The static helpers serve ComingStrip and DriftPanel.

const PLATE_TIME := 4.0  # Seconds a first-appearance name plate stays
const PLATE_LIFT := 52.0  # Pixels above the nightmare
const LINE_WIDTH := 19.0  # User: "a bit more visible" (it was half the route mist's width, 12)
const LINE_ALPHA := 0.7  # At a rest before them
const LINE_ALPHA_FIELD := 0.35  # While they're on the field
const CORE_WIDTH := 4.0  # A brighter Wraithlight thread down its middle
const CORE_ALPHA := 0.45  # × the line's alpha
const WISPS := 3  # Small wisps drifting along it toward the Heartwood, like the run-start route mist
const WISP_SPEED := 0.12  # Of the line's length per second
const WISP_RADIUS := 5.0
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
var line_shown := false  # The flyer mist line is up (tests)
var line := Line2D.new()  # Start → Heartwood, in RouteLine's mist style
var _core := Line2D.new()  # Its brighter thread
var _wisps := Node2D.new()  # The drifting wisps (drawn while the line shows)
var _wisp_clock := 0.0
var _line_alpha := 0.0
var _plates: Array = []  # [enemy, seconds left]
var _plated := {}  # Kind -> true: its first-appearance plate was shown this run
var _clock := 0.0

var _plate_layer := Node2D.new()  # Plates draw over the nightmares; the line stays on the ground

func _init(drift_director: DriftDirector = null) -> void:
	director = drift_director

func _ready() -> void:
	z_index = -1  # The mist line: the route arrows' layer (over the path tiles, under Wardens and nightmares)
	line.name = "FlyerLine"
	line.visible = false
	add_child(line)
	_core.name = "Core"
	_core.width = CORE_WIDTH
	_core.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_core.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.add_child(_core)  # Shown and hidden with the line
	_wisps.name = "Wisps"
	_wisps.draw.connect(_draw_wisps)
	line.add_child(_wisps)
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

# Whether the next block brings flyers that cross walls (any kind, faced or not: the mist line is information).
static func wall_flyers_coming(drift_director: DriftDirector) -> bool:
	if drift_director == null or not drift_director.is_resting() or not drift_director.has_next_drift():
		return false
	var per := drift_director.drifts_per_block
	var block := drift_director.get_block(drift_director.drifts_started + 1)
	for kind in ComingStrip.kinds_in_range(drift_director, (block - 1) * per + 1, mini(block * per, drift_director.get_total_drifts())):
		if breaks_rules(kind[0]) and kind[0].is_through_walls():
			return true
	return false

# --- The world overlay ---------------------------------------------------------------------------------

func _process(delta: float) -> void:
	var real_delta := delta / maxf(Engine.time_scale, 0.001)
	if line.visible and not bool(Fx.setting("reduced_motion", false)):
		_wisp_clock += real_delta
		_wisps.queue_redraw()  # Only while the line shows
	if not _plates.is_empty():
		for plate in _plates:
			plate[1] -= real_delta
		_plates = _plates.filter(func(p: Array) -> bool: return p[1] > 0.0 and is_instance_valid(p[0]) and not p[0].is_cleansed)
		_plate_layer.queue_redraw()
	_clock -= real_delta
	if _clock > 0.0:
		return
	_clock = REFRESH
	var alpha := 0.0
	if wall_flyers_coming(director):
		alpha = LINE_ALPHA
	elif _wall_flyers_on_field():
		alpha = LINE_ALPHA_FIELD
	line_shown = alpha > 0.0
	_show_line(alpha)

func _wall_flyers_on_field() -> bool:
	if spawner == null or not spawner.has_method("get_enemies"):
		return false
	for enemy in spawner.get_enemies():
		var data = enemy.get("enemy_data")
		if data is EnemyData and breaks_rules(data) and data.is_through_walls() and not enemy.get("is_cleansed"):
			return true
	return false

# The mist line from the start straight to the Heartwood at `alpha` (0 = hidden); RouteLine's mist at half width.
func _show_line(alpha: float) -> void:
	line.visible = alpha > 0.0 and map != null and RouteLine.has_mist()
	if not line.visible:
		return
	if line.points.is_empty():
		line.points = PackedVector2Array([map.MAP_GRID.calculate_map_position(map.startPath),
			map.MAP_GRID.calculate_map_position(map.endPath)])
		RouteLine.style_mist(line, alpha)
		line.width = LINE_WIDTH
		_core.points = line.points
	line.default_color = Color(1, 1, 1, alpha)  # multiplier: the art carries the colour
	_core.default_color = Color(Palette.WRAITHLIGHT, CORE_ALPHA * alpha)  # A child: the line's colour doesn't reach it
	_line_alpha = alpha
	_wisps.queue_redraw()

# Wisps drifting from the start toward the Heartwood along the line: soft cold dots, evenly spaced, fading in and out
# at the ends. Still (evenly placed) under reduced motion.
func _draw_wisps() -> void:
	if line.points.size() < 2:
		return
	var a: Vector2 = line.points[0]
	var b: Vector2 = line.points[1]
	for i in WISPS:
		var t := fposmod(_wisp_clock * WISP_SPEED + float(i) / WISPS, 1.0)
		var fade := minf(t, 1.0 - t) * 4.0 * _line_alpha / LINE_ALPHA  # In at the start, out at the Heartwood; fainter on the field
		var at := a.lerp(b, t)
		var colour := Palette.WRAITHLIGHT
		_wisps.draw_circle(at, WISP_RADIUS * 1.8, Color(colour, 0.12 * clampf(fade, 0.0, 1.0)))
		_wisps.draw_circle(at, WISP_RADIUS, Color(colour, 0.35 * clampf(fade, 0.0, 1.0)))

func _on_spawned(node: Node) -> void:
	var data = node.get("enemy_data")
	if not data is EnemyData:
		return
	_plate_spawned.call_deferred(node.get_instance_id())  # Its data is set once it's in

# By instance id (a captured node freed the same frame logs "Lambda capture … was freed").
func _plate_spawned(id: int) -> void:
	var node := instance_from_id(id) as Node
	if node == null:
		return  # Freed the same frame (tests spawn and clear)
	var real: EnemyData = node.get("enemy_data")
	if real == null or not breaks_rules(real) or _plated.has(kind_of(real)):
		return
	_plated[kind_of(real)] = true
	_plates.append([node, PLATE_TIME])
	_plate_layer.queue_redraw()

func _draw_plates() -> void:
	for plate in _plates:
		if is_instance_valid(plate[0]):
			var at: Vector2 = _plate_layer.to_local(plate[0].global_position)
			WorldLabel.draw_tag(_plate_layer, at.x, at.y - PLATE_LIFT, plate_text(plate[0].enemy_data), UiStyle.INK)
