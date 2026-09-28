class_name EnvironmentAmbience
extends Node2D

# The moving atmosphere over the world (art_direction.md; the concept page's ambient layer): dark
# nightmare fog creeping along every map edge, plus the act's own particles: warm dream motes rising
# from the Heartwood (spring dusk), cold wisps (summer night), fog banks and ember leaves (autumn fog),
# snow (winter dark). Numbers are the concept page's, scaled from its 15x9 sample to the map's size.

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const AMBIENCE_Z := 6  # Over attack effects, under Dew popups
const CONCEPT_SIZE := Vector2(960, 576)  # The concept page's sample map, in px
const FOG_COLOR := Color(16 / 255.0, 10 / 255.0, 30 / 255.0)

@export var edge_fog_per_edge_cell := 0.46
@export var particle_scale := 1.0  # Multiplies every act's particle count

var act := 1
var heartwood_position := Vector2.ZERO  # Where act 1's warm motes rise from
var _time := 0.0
var _size: Vector2
var _area_scale: float  # Map area / concept area

func _ready() -> void:
	z_index = AMBIENCE_Z
	_size = MAP_GRID.size * MAP_GRID.cell_size
	_area_scale = (_size.x * _size.y) / (CONCEPT_SIZE.x * CONCEPT_SIZE.y)

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	_draw_edge_fog()
	match act:
		1:
			_draw_warm_motes()
		2:
			_draw_cold_wisps()
		3:
			_draw_autumn_fog()
		_:
			_draw_snow()

# Stable pseudo-random 0..1 per particle.
func _rand(k: int, salt: int) -> float:
	return fposmod(sin(k * 12.9898 + salt * 78.233) * 43758.5453, 1.0)

func _count(concept_count: float) -> int:
	return int(concept_count * _area_scale * particle_scale)

func _ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	draw_set_transform(center, 0.0, Vector2(1.0, radii.y / radii.x))
	draw_circle(Vector2.ZERO, radii.x, color)
	draw_set_transform(Vector2.ZERO)

# Nightmare fog drifting round the map's edge, one side per blob.
func _draw_edge_fog() -> void:
	var edge_cells := 2 * (MAP_GRID.size.x + MAP_GRID.size.y)
	var speed_scale := CONCEPT_SIZE.x / _size.x  # Same px/s as the concept on a bigger map
	for k in int(edge_cells * edge_fog_per_edge_cell):
		var side := k % 4
		var u := fposmod(_rand(k, 1) + _time * (0.012 + (k % 3) * 0.004) * speed_scale, 1.0)
		var at: Vector2
		match side:
			0:
				at = Vector2(u * _size.x, 18)
			1:
				at = Vector2(_size.x - 20, u * _size.y)
			2:
				at = Vector2((1.0 - u) * _size.x, _size.y - 18)
			_:
				at = Vector2(20, (1.0 - u) * _size.y)
		var alpha := 0.22 + 0.1 * sin(_time * 0.8 + k)
		_ellipse(at, Vector2(110, 46), Color(FOG_COLOR, alpha))

func _mote(at: Vector2, rgb: Color, alpha: float) -> void:
	var p := at.floor()
	draw_rect(Rect2(p - Vector2(2, 2), Vector2(5, 5)), Color(rgb, alpha * 0.22))
	draw_rect(Rect2(p, Vector2(2, 2)), Color(rgb, alpha))

func _draw_warm_motes() -> void:
	var rgb := Color(1.0, 214 / 255.0, 130 / 255.0)
	for k in int(18 * particle_scale):
		var ph := fposmod(_rand(k, 3) + _time * 0.05, 1.0)
		var at := heartwood_position + Vector2((_rand(k, 1) - 0.5) * 480 + sin(_time * 0.7 + k) * 16, 60 - ph * 360)
		_mote(at, rgb, maxf(0.0, sin(_time * 1.6 + k * 1.7)) * sin(ph * PI))

func _draw_cold_wisps() -> void:
	var rgb := Color(150 / 255.0, 230 / 255.0, 240 / 255.0)
	for k in _count(18):
		var at := Vector2(_rand(k, 1) * _size.x + sin(_time * 0.7 + k) * 16,
			_rand(k, 2) * _size.y + cos(_time * 0.5 + k * 2) * 12)
		_mote(at, rgb, maxf(0.0, sin(_time * 1.6 + k * 1.7)))

func _draw_autumn_fog() -> void:
	var bands := int(_size.y / 110.0)
	for k in bands:
		var x := fposmod(_rand(k, 1) * _size.x + _time * (8 + k * 2), _size.x + 400) - 200
		_ellipse(Vector2(x, 60 + k * 110), Vector2(220, 40), Color(90 / 255.0, 70 / 255.0, 130 / 255.0, 0.12))
	for k in _count(10):
		var at := Vector2(fposmod(_rand(k, 1) * _size.x + _time * 22, _size.x),
			fposmod(_rand(k, 2) * _size.y + _time * 26, _size.y) + sin(_time * 3 + k) * 6)
		draw_rect(Rect2(at.floor(), Vector2(3, 2)), Color("#4e1e1c") if k % 2 == 0 else Color("#a85a34"))

func _draw_snow() -> void:
	for k in _count(70):
		var at := Vector2(fposmod(_rand(k, 1) * _size.x + sin(_time * 0.8 + k) * 12 + _time * 6, _size.x),
			fposmod(_rand(k, 2) * _size.y + _time * (20 + (k % 5) * 6), _size.y))
		var flake := 2.0 if k % 5 else 3.0
		draw_rect(Rect2(at.floor(), Vector2(flake, flake)), Color(220 / 255.0, 228 / 255.0, 1.0, 0.75 if k % 4 else 0.4))
