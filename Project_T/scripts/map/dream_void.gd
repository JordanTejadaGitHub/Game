class_name DreamVoid
extends Node2D

# The starry void the island of dream drifts in (environment_assets.md, "The dream's outer layer"):
# two parallax layers behind the map (the sky, then brighter stars), a small islet at the far end of
# the rope bridge where nightmares come from, and a few more islets scattered around. The same in
# every act. MapGenerator makes it and moves it behind the tile layers.

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const VOID_Z := -10  # Behind the map
const TILE := 256.0  # void_sky / void_stars are seamless 256x256
const REPEATS := 16  # Copies each way, enough for a fully zoomed-out wide screen

@export var sky_scroll := 0.25  # How far the sky moves as the camera pans (1 = with the map)
@export var stars_scroll := 0.5
@export var stars_drift := Vector2(-3, 1)  # px/s: the stars wheel slowly
@export var scattered_islets := 7
@export var islet_distance := Vector2(2.0, 6.0)  # Cells out from the island's edge

var bridge_end := Vector2i(-1, -1)  # Cell for the bridge's islet (set before adding)
var map_seed := 0  # Scatter is reproducible per map

func _ready() -> void:
	z_index = VOID_Z
	add_child(_layer("void_sky", sky_scroll, Vector2.ZERO))
	add_child(_layer("void_stars", stars_scroll, stars_drift))
	var islets: Texture2D = load(EnvironmentTiles.shared_path("void_islets"))
	var count := islets.get_width() / EnvironmentTiles.SIZE.x
	if bridge_end != Vector2i(-1, -1):
		add_child(_islet(islets, 2, MAP_GRID.calculate_map_position(Vector2(bridge_end))))  # The biggest one
	var rng := RandomNumberGenerator.new()
	rng.seed = map_seed + 7
	var map_rect := Rect2(Vector2.ZERO, MAP_GRID.size * MAP_GRID.cell_size)
	var placed: Array[Vector2] = []
	for attempt in 60:
		if placed.size() >= scattered_islets:
			break
		var at := _around(rng, map_rect)
		if _too_close(at, placed) or at.distance_to(MAP_GRID.calculate_map_position(Vector2(bridge_end))) < 160:
			continue
		placed.append(at)
		var islet := _islet(islets, rng.randi_range(0, count - 1), at)
		islet.scale = Vector2.ONE * rng.randf_range(0.6, 1.0)  # Farther away
		islet.modulate = Color(0.75, 0.75, 0.9)  # A multiplier on the islet art, not a colour
		add_child(islet)

func _layer(sheet: String, scroll: float, drift: Vector2) -> Parallax2D:
	var layer := Parallax2D.new()
	layer.scroll_scale = Vector2.ONE * scroll
	layer.repeat_size = Vector2(TILE, TILE)
	layer.repeat_times = REPEATS
	layer.autoscroll = drift
	var sprite := Sprite2D.new()
	sprite.texture = load(EnvironmentTiles.shared_path(sheet))
	sprite.centered = false
	layer.add_child(sprite)
	return layer

func _islet(texture: Texture2D, index: int, at: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2(index * EnvironmentTiles.SIZE.x, 0), Vector2(EnvironmentTiles.SIZE))
	sprite.position = at
	return sprite

# A point in the void a few cells out from one side of the island.
func _around(rng: RandomNumberGenerator, map_rect: Rect2) -> Vector2:
	var cell := MAP_GRID.cell_size.x
	var out := rng.randf_range(islet_distance.x, islet_distance.y) * cell
	match rng.randi_range(0, 3):
		0:
			return Vector2(rng.randf_range(0, map_rect.size.x), -out)
		1:
			return Vector2(map_rect.size.x + out, rng.randf_range(0, map_rect.size.y))
		2:
			return Vector2(rng.randf_range(0, map_rect.size.x), map_rect.size.y + cell + out)  # Past the cliffs
		_:
			return Vector2(-out, rng.randf_range(0, map_rect.size.y))

func _too_close(at: Vector2, placed: Array[Vector2]) -> bool:
	for other in placed:
		if at.distance_to(other) < 200.0:
			return true
	return false
