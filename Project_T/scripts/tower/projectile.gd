extends Node2D
class_name Projectile

# A projectile (spore puff, pebble, spark, ...) that homes in on its target and soothes it on
# arrival. If the target is cleansed or gone first, it finishes its flight to the last known
# position and fizzles. Uses the tower's projectile sheet, rotated to face travel, or draws a
# coloured puff when the tower has none.

const RADIUS := 6.0
const ANIMATION_FPS := 12.0

var damage: int
var speed: float
var color: Color
var texture: Texture2D
var frame_count: int

var _target: Node2D
var _target_position: Vector2
var _anim_time := 0.0

func _init(target: Node2D, data: TowerData) -> void:
	_target = target
	_target_position = target.global_position
	damage = data.damage
	speed = data.projectile_speed
	color = data.projectile_color
	texture = data.projectile_texture
	frame_count = data.projectile_frames
	top_level = true  # Fly in world space, independent of the tower that fired it

func _process(delta: float) -> void:
	var target_alive: bool = is_instance_valid(_target) and not _target.is_cleansed
	if target_alive:
		_target_position = _target.global_position

	var step := speed * delta
	if global_position.distance_to(_target_position) <= step:
		if target_alive:
			_target.take_damage(damage)
		queue_free()
		return
	if texture != null:
		rotation = global_position.direction_to(_target_position).angle()
		_anim_time += delta
		queue_redraw()
	global_position = global_position.move_toward(_target_position, step)

func _draw() -> void:
	if texture == null:
		draw_circle(Vector2.ZERO, RADIUS, color.darkened(0.3))
		draw_circle(Vector2.ZERO, RADIUS - 2.0, color)
		return
	var frame := int(_anim_time * ANIMATION_FPS) % frame_count
	var size := Vector2(texture.get_width() / float(frame_count), texture.get_height())
	draw_texture_rect_region(texture, Rect2(-size / 2.0, size), Rect2(Vector2(size.x * frame, 0), size))
