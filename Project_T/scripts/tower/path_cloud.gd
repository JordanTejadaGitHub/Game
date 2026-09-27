extends Node2D
class_name PathCloud

# A lingering cloud on a path tile (Bloomcap's sleepy cloud, Mistveil's fog). Every TICK seconds
# it soothes the creatures inside a little and applies the Warden's status; fog clouds also make
# Spored tick harder. Script-only node, a child of the Warden that dropped it.

const TICK := 0.5

var _tower: Tower
var _radius: float
var _duration: float
var _fog: bool
var _color: Color
var _age := 0.0
var _tick_timer := 0.0

func _init(tower: Tower, center: Vector2) -> void:
	_tower = tower
	_radius = tower.tower_data.cloud_radius * Tower.MAP_GRID.cell_size.x
	_duration = tower.tower_data.cloud_duration
	_fog = tower.tower_data.cloud_fog
	_color = tower.tower_data.projectile_color
	top_level = true
	z_index = 4
	position = center

func _ready() -> void:
	_tick()

func _process(delta: float) -> void:
	_age += delta
	if _age >= _duration:
		queue_free()
		return
	_tick_timer += delta
	while _tick_timer >= TICK:
		_tick_timer -= TICK
		_tick()
	queue_redraw()

func _tick() -> void:
	for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
		if enemy.global_position.distance_to(global_position) > _radius:
			continue
		if _fog:
			enemy.statuses.set_in_fog(TICK * 1.5)
		# A cloud's soothe per tick is a share of one attack, spread over its lifetime.
		_tower.hit(enemy, TICK / _duration, true)

func _draw() -> void:
	var fade := minf(1.0, (_duration - _age) / 0.5) * minf(1.0, _age / 0.2 + 0.3)
	for i in 5:
		var angle := TAU * i / 5.0 + _age * 0.6
		var offset := Vector2.from_angle(angle) * _radius * 0.45
		draw_circle(offset, _radius * 0.55, Color(_color, 0.14 * fade))
	draw_circle(Vector2.ZERO, _radius * 0.6, Color(_color, 0.18 * fade))
