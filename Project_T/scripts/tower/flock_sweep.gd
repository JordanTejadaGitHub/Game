extends Node2D
class_name FlockSweep

# Starling Murmuration's flock: a handful of birds that stream along `points` (world space, a stretch
# of path) and vanish. Purely visual; the Warden deals the damage when it sends them. Script-only.

const DURATION := 0.55
const BIRDS := 7
const SPREAD := 10.0  # Pixels the birds scatter either side of the path
const ANIMATION_FPS := 14.0

var _points: PackedVector2Array
var _texture: Texture2D
var _frames: int
var _length := 0.0
var _age := 0.0
var _offsets: Array[Vector2] = []

func _init(points: PackedVector2Array, texture: Texture2D, frames: int) -> void:
	_points = points
	_texture = texture
	_frames = maxi(frames, 1)
	top_level = true
	z_index = 5
	for i in _points.size() - 1:
		_length += _points[i].distance_to(_points[i + 1])
	for i in BIRDS:
		_offsets.append(Vector2(randf_range(-SPREAD, SPREAD), randf_range(-SPREAD, SPREAD)))

func _process(delta: float) -> void:
	_age += delta
	if _age >= DURATION:
		queue_free()
		return
	queue_redraw()

# Point `distance` pixels along the stretch, and the direction of travel there.
func _along(distance: float) -> Array:
	for i in _points.size() - 1:
		var segment := _points[i].distance_to(_points[i + 1])
		if distance <= segment or i == _points.size() - 2:
			var t := clampf(distance / maxf(segment, 0.001), 0.0, 1.0)
			return [_points[i].lerp(_points[i + 1], t), _points[i].direction_to(_points[i + 1])]
		distance -= segment
	return [_points[-1], Vector2.RIGHT]

func _draw() -> void:
	if _points.size() < 2:
		return
	var progress := _age / DURATION
	var fade := minf(1.0, (1.0 - progress) * 4.0)
	for i in BIRDS:
		# Birds trail one another along the stretch.
		var at_distance := (progress * 1.4 - i * 0.06) * _length
		if at_distance < 0.0:
			continue
		var place: Array = _along(minf(at_distance, _length))
		var at: Vector2 = place[0] + _offsets[i]
		var dir: Vector2 = place[1]
		draw_set_transform(at, dir.angle())
		if _texture == null:
			draw_circle(Vector2.ZERO, 4.0, Color(0.2, 0.2, 0.25, fade))
		else:
			var size := Vector2(_texture.get_width() / float(_frames), _texture.get_height())
			var frame := (int(_age * ANIMATION_FPS) + i) % _frames
			draw_texture_rect_region(_texture, Rect2(-size / 2.0, size),
				Rect2(Vector2(size.x * frame, 0), size), Color(1, 1, 1, fade))
	draw_set_transform(Vector2.ZERO)
