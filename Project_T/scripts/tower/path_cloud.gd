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
var _drowsy_time := {}  # Morning Fog: nightmare instance id -> seconds inside since its last Drowsy

func _init(tower: Tower, center: Vector2) -> void:
	_tower = tower
	# attack_data: a Graftling copying a Bloomcap drops the Bloomcap's cloud.
	_radius = tower.attack_data.cloud_radius * Tower.MAP_GRID.cell_size.x
	_duration = tower.attack_data.cloud_duration
	_fog = tower.attack_data.cloud_fog
	_color = tower.attack_data.projectile_color
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
		var data: TowerData = _tower.attack_data if is_instance_valid(_tower) else null
		if data and data.cloud_slow > 0.0:
			enemy.statuses.slow_time = maxf(enemy.statuses.slow_time, TICK * 1.6)
			enemy.statuses.slow_amount = maxf(enemy.statuses.slow_amount, data.cloud_slow)
		if data and data.cloud_drowsy_per_second > 0.0:
			var id: int = enemy.get_instance_id()
			_drowsy_time[id] = _drowsy_time.get(id, 0.0) + TICK
			if _drowsy_time[id] >= 1.0 / data.cloud_drowsy_per_second:
				_drowsy_time[id] = 0.0
				enemy.apply_status(EnemyStatuses.DROWSY, 1, 0.0, 0.0, 0, data.line, _tower)
		# A cloud's soothe per tick is a share of one attack, spread over its lifetime.
		_tower.hit(enemy, TICK / _duration, true, Tower.NO_CRIT, &"cloud")  # Clouds never crit; an effect (Potency)

func _draw() -> void:
	var fade := minf(1.0, (_duration - _age) / 0.5) * minf(1.0, _age / 0.2 + 0.3)
	for i in 5:
		var angle := TAU * i / 5.0 + _age * 0.6
		var offset := Vector2.from_angle(angle) * _radius * 0.45
		draw_circle(offset, _radius * 0.55, Color(_color, 0.14 * fade))
	draw_circle(Vector2.ZERO, _radius * 0.6, Color(_color, 0.18 * fade))
