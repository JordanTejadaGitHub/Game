extends Node2D
class_name CloseCalls

# Close calls (run_design.md, the "spend or save" goal): when a nightmare passes 85% of its route, the
# Heartwood's leaves tremble and the last stretch of the route glows faintly cold for a moment
# (throttled: one effect per EFFECT_COOLDOWN, but every close call counts). The rest report shows the
# block's count ("Close calls: 3"). `close_call(enemy)` is for Sound's tension cue. Made by the HUD;
# drawn at the ground's z so the glow sits on the path, under nightmares and Wardens.

signal close_call(enemy: Node2D)

const GROUP := &"close_calls"
const SHARE := 0.85  # Of its route walked
const MIN_ROUTE_CELLS := 4  # Shorter routes (a nightmare spawned near the goal) never count
const CHECK_EVERY := 0.1  # Game seconds
const EFFECT_COOLDOWN := 2.0  # Game seconds between two trembles / glows
const GLOW_TIME := 1.1
const GLOW_COLOR := Color(0.55, 0.75, 1.0, 0.28)  # Faint cold light
const TREMBLE_TIME := 0.6
const TREMBLE_SKEW := 0.05  # Radians

var block_count := 0
var run_count := 0
var _longest := {}  # Enemy instance id -> the most route (px) it had left (= its route's length)
var _called := {}  # Enemy instance id -> true once it has been a close call
var _clock := 0.0
var _cooldown := 0.0
var _glow_age := -1.0  # < 0 = no glow
var _glow_cells: PackedVector2Array = []
var _map: Node
var _spawner: Node
var _tween: Tween

static func find(near: Node) -> CloseCalls:
	return near.get_tree().get_first_node_in_group(GROUP) as CloseCalls

func _ready() -> void:
	add_to_group(GROUP)
	z_index = -1
	var main := get_parent()
	_map = main.get_node_or_null("%MapGenerator")
	_spawner = main.get_node_or_null("%EnemyContainer")
	var director := main.get_node_or_null("%DriftDirector")
	if director != null:
		director.rest_ended.connect(_on_rest_ended)

# A new block: the report has read the count; the last block's nightmares are gone.
func _on_rest_ended(_block: int) -> void:
	block_count = 0
	_called.clear()
	_longest.clear()

func _process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _glow_age >= 0.0:
		_glow_age += delta
		if _glow_age >= GLOW_TIME:
			_glow_age = -1.0
		queue_redraw()
	_clock -= delta
	if _clock > 0.0 or _spawner == null:
		return
	_clock = CHECK_EVERY
	for enemy in _spawner.get_enemies():
		_check(enemy)

func _check(enemy: Node) -> void:
	if enemy.get("is_cleansed") or not enemy.has_method("get_remaining_distance"):
		return
	var id := enemy.get_instance_id()
	if _called.has(id):
		return
	var left: float = enemy.get_remaining_distance()
	var longest: float = maxf(_longest.get(id, 0.0), left)  # Re-routes can lengthen it
	_longest[id] = longest
	var cell: float = _map.MAP_GRID.cell_size.x if _map != null else 64.0
	if longest < MIN_ROUTE_CELLS * cell or left > longest * (1.0 - SHARE):
		return
	_called[id] = true
	_longest.erase(id)
	block_count += 1
	run_count += 1
	close_call.emit(enemy)
	if _cooldown <= 0.0:
		_cooldown = EFFECT_COOLDOWN
		_tremble()
		_glow()

# The Heartwood's leaves tremble: a short skew wobble (none with reduced motion).
func _tremble() -> void:
	var tree: Node2D = _map.get("heartwood") if _map != null else null
	if tree == null or bool(Fx.setting("reduced_motion", false)):
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = tree.create_tween()
	var steps := 6
	for i in steps:
		var side := TREMBLE_SKEW * (1.0 - float(i) / steps) * (1.0 if i % 2 == 0 else -1.0)
		_tween.tween_property(tree, "skew", side, TREMBLE_TIME / (steps + 1))
	_tween.tween_property(tree, "skew", 0.0, TREMBLE_TIME / (steps + 1))

# The last stretch of the route (its final 15%) glows faintly cold.
func _glow() -> void:
	if _map == null:
		return
	var route: PackedVector2Array = _map.get_path_from(_map.startPath)
	var count := maxi(ceili(route.size() * (1.0 - SHARE)), 1)
	_glow_cells = route.slice(maxi(route.size() - count, 0))
	_glow_age = 0.0
	queue_redraw()

func _draw() -> void:
	if _glow_age < 0.0 or _glow_cells.is_empty():
		return
	var t := _glow_age / GLOW_TIME
	var fade := sin(PI * t)  # Rises and fades
	var grid = _map.MAP_GRID
	var radius: float = grid.cell_size.x * 0.42
	for i in _glow_cells.size():
		var at: Vector2 = grid.calculate_map_position(_glow_cells[i])
		var near_goal := float(i + 1) / _glow_cells.size()  # Brighter towards the Heartwood
		draw_circle(at, radius, Color(GLOW_COLOR, GLOW_COLOR.a * fade * (0.5 + 0.5 * near_goal)))
