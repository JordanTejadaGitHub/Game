extends Node2D
class_name Projectile

# A spore puff that homes in on its target and soothes it on arrival. If the target is cleansed or
# gone first, the puff finishes its flight to the last known position and fizzles.

const RADIUS := 6.0

var damage: int
var speed: float
var color: Color

var _target: Node2D
var _target_position: Vector2

func _init(target: Node2D, p_damage: int, p_speed: float, p_color: Color) -> void:
	_target = target
	_target_position = target.global_position
	damage = p_damage
	speed = p_speed
	color = p_color
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
	global_position = global_position.move_toward(_target_position, step)

func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, color.darkened(0.3))
	draw_circle(Vector2.ZERO, RADIUS - 2.0, color)
