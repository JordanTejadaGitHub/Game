extends Node2D
class_name Projectile

# A projectile (spore puff, pebble, spark, ...) that homes in on its target. On arrival it calls
# `on_land(target_or_null, position)` (the tower soothes the target, or splashes around the
# position). If the target is cleansed or gone first, it finishes its flight to the last known
# position (a splash still lands there). Uses the tower's projectile sheet, rotated to face travel,
# or draws a coloured puff when the tower has none.

const RADIUS := 6.0
const ANIMATION_FPS := 12.0

var speed: float
var color: Color
var texture: Texture2D
var frame_count: int

var _target: Node2D
var _target_position: Vector2
var _on_land: Callable
var _anim_time := 0.0
# Swoop (Nestling line): after landing, fly back to `_home` (world position) and then vanish.
var _returns := false
var _home := Vector2.ZERO
var _returning := false

func _init(target: Node2D, data: TowerData, on_land: Callable) -> void:
	_target = target
	_target_position = target.global_position
	_on_land = on_land
	speed = data.projectile_speed
	color = data.projectile_color
	texture = data.projectile_texture
	frame_count = data.projectile_frames
	_returns = data.projectile_returns
	top_level = true  # Fly in world space, independent of the tower that fired it

func _ready() -> void:
	_home = global_position

func is_returning() -> bool:
	return _returning

func _process(delta: float) -> void:
	var step := speed * delta
	if _returning:
		if global_position.distance_to(_home) <= step:
			queue_free()
			return
		_fly_toward(_home, step, delta)
		return

	var target_alive: bool = is_instance_valid(_target) and not _target.is_cleansed
	if target_alive:
		_target_position = _target.global_position

	if global_position.distance_to(_target_position) <= step:
		_on_land.call(_target if target_alive else null, _target_position)
		if _returns:
			_returning = true
			return
		queue_free()
		return
	_fly_toward(_target_position, step, delta)

func _fly_toward(to: Vector2, step: float, delta: float) -> void:
	if texture != null:
		rotation = global_position.direction_to(to).angle()
		_anim_time += delta
		queue_redraw()
	global_position = global_position.move_toward(to, step)

func _draw() -> void:
	if texture == null:
		draw_circle(Vector2.ZERO, RADIUS, color.darkened(0.3))
		draw_circle(Vector2.ZERO, RADIUS - 2.0, color)
		return
	var frame := int(_anim_time * ANIMATION_FPS) % frame_count
	var size := Vector2(texture.get_width() / float(frame_count), texture.get_height())
	draw_texture_rect_region(texture, Rect2(-size / 2.0, size), Rect2(Vector2(size.x * frame, 0), size))
