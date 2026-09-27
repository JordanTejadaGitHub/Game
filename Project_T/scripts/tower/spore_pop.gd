extends Node2D
class_name SporePop

# A Puffball pop: a soft green-violet ring and a scatter of spores that fade out. Purely visual; the
# Warden deals the damage. Script-only node, world space.

const LIFETIME := 0.45
const SPORES := 10
const COLOR := Color(0.78, 0.9, 0.45)
const RIM := Color(0.85, 0.65, 1.0)

var _radius: float
var _age := 0.0
var _dirs: Array[Vector2] = []

func _init(at: Vector2, radius: float) -> void:
	top_level = true
	z_index = 5
	position = at
	_radius = radius
	for i in SPORES:
		_dirs.append(Vector2.from_angle(TAU * i / SPORES + randf_range(-0.2, 0.2)) * randf_range(0.6, 1.0))

func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t := _age / LIFETIME
	var fade := 1.0 - t
	draw_circle(Vector2.ZERO, _radius * (0.3 + 0.7 * t), Color(COLOR, 0.25 * fade))
	draw_arc(Vector2.ZERO, _radius * (0.3 + 0.7 * t), 0.0, TAU, 32, Color(RIM, 0.7 * fade), 3.0)
	for dir in _dirs:
		draw_circle(dir * _radius * t, 3.5 * fade + 1.0, Color(COLOR, fade))
