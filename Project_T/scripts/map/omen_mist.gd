class_name OmenMist
extends Node2D

# The Omen mist (run_design.md "How an Omen looks"): while an Omen twists the current block, a low,
# cool gold-violet mist lies on the island: heaviest at the map's edges and the forest's edge (the
# start), thin over the path. It rolls in over ROLL_TIME when an Omen is picked and lifts at the rest
# that pays its reward; a resumed save with an active Omen brings it back. Clear Skies = no mist.
# It watches OmenDirector.active (group `omens`), so picking, paying, loading and ending all just work.
# Readability first: it draws on the ground (z -1, after the ground and path), under Wardens,
# nightmares, health bars and the build ghost. Reduced motion: still and lighter. Reduced flashes
# (the lite effects mode): half the blobs, lighter.

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const MIST_Z := -1  # Same z as the ground and path, drawn after them (MapGenerator adds it later)
const ROLL_TIME := 3.0  # s to roll in or lift
const BLOBS := 30
const BLOB_SIZE := Vector2(300, 150)  # px, a soft disc stretched flat (low mist)
const PATH_THINNING := 0.25  # Over path cells the mist keeps this share of its density
const DRIFT := 40.0  # px each blob sways around its home

@export var violet := Color(0.66, 0.58, 0.9)
@export var gold := Color(0.95, 0.82, 0.55)
@export var density := 0.26  # Peak alpha of a blob at full strength

var map_generator: Node  # Set before adding
var strength := 0.0  # 0 = gone, 1 = fully rolled in
var _blobs: Array = []  # [home (Vector2), weight (0..1), phase, speed]
var _path_cells := {}
var _time := 0.0

func _ready() -> void:
	z_index = MIST_Z
	visible = false
	_scatter()
	if map_generator != null:
		map_generator.path_changed.connect(_on_path_changed)
		_on_path_changed()

# True when an Omen twists the current block.
func is_wanted() -> bool:
	var omens := get_tree().get_first_node_in_group(&"omens")
	return omens != null and omens.get("active") != null

func _process(delta: float) -> void:
	var target := 1.0 if is_wanted() else 0.0
	strength = move_toward(strength, target, delta / ROLL_TIME)
	visible = strength > 0.0
	if not visible:
		return
	if not _reduced_motion():
		_time += delta
	queue_redraw()

func _draw() -> void:
	var disc := EnvironmentLighting.light_texture()
	var lite := Fx.reduce_flashes()
	var still := _reduced_motion()
	var alpha := density * strength * (0.6 if still else 1.0) * (0.7 if lite else 1.0)
	for i in _blobs.size():
		if lite and i % 2 == 1:
			continue
		var blob: Array = _blobs[i]
		var home: Vector2 = blob[0]
		var sway := Vector2.ZERO if still else Vector2(sin(_time * blob[3] + blob[2]), cos(_time * blob[3] * 0.7 + blob[2]) * 0.4) * DRIFT
		var at := home + sway
		var thin := PATH_THINNING if _path_cells.has(MAP_GRID.calculate_grid_coordinates(at)) else 1.0
		var a: float = alpha * blob[1] * thin
		draw_texture_rect(disc, Rect2(at - BLOB_SIZE / 2.0, BLOB_SIZE), false, Color(violet, a))
		draw_texture_rect(disc, Rect2(at - BLOB_SIZE / 4.0, BLOB_SIZE / 2.0), false, Color(gold, a * 0.35))

# Homes for the blobs, weighted toward the map's edges and the start (where drifts arrive).
func _scatter() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 91  # The same mist every run: it's weather, not map content
	var size: Vector2 = MAP_GRID.size * MAP_GRID.cell_size
	var start := Vector2.ZERO
	if map_generator != null:
		start = MAP_GRID.calculate_map_position(map_generator.startPath)
	for attempt in 400:
		if _blobs.size() >= BLOBS:
			break
		var at := Vector2(rng.randf() * size.x, rng.randf() * size.y)
		var edge := minf(minf(at.x, size.x - at.x), minf(at.y, size.y - at.y)) / (minf(size.x, size.y) / 2.0)
		var weight := clampf(1.0 - edge, 0.0, 1.0)  # 1 at the edge, 0 in the middle
		weight = maxf(weight, 1.0 - at.distance_to(start) / (size.x * 0.4))  # And the forest's edge
		if rng.randf() > weight * weight + 0.15:
			continue
		_blobs.append([at, clampf(weight + 0.2, 0.3, 1.0), rng.randf() * TAU, rng.randf_range(0.08, 0.2)])

func _on_path_changed() -> void:
	_path_cells.clear()
	for cell in map_generator.path_layer.current_path:
		_path_cells[Vector2(cell)] = true

static func _reduced_motion() -> bool:
	return bool(Fx.setting("reduced_motion", false))

func get_blob_count() -> int:
	return _blobs.size()
