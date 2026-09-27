extends Node2D
class_name ChainBolt

# A lightning strike through `points` (world space) that flickers and fades. Script-only node.

const LIFETIME := 0.25
const JAG := 6.0  # Pixels of zig-zag per segment
const COLOR := Color(1.0, 0.95, 0.55)

var _points: PackedVector2Array
var _age := 0.0

func _init(points: PackedVector2Array) -> void:
	_points = points
	top_level = true
	z_index = 5

func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var alpha := 1.0 - _age / LIFETIME
	for i in _points.size() - 1:
		var a := _points[i]
		var b := _points[i + 1]
		var normal := (b - a).orthogonal().normalized()
		var mid := (a + b) / 2.0 + normal * randf_range(-JAG, JAG)
		var line := PackedVector2Array([a, mid, b])
		draw_polyline(line, Color(COLOR, alpha * 0.4), 6.0)
		draw_polyline(line, Color(COLOR, alpha), 2.0)
