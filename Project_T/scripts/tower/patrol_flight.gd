extends Node2D
class_name PatrolFlight

# An Ascended Warden's travelling attack (PATROL): Dawnwing's great bird or The Whirlwind's cyclone.
# It goes back and forth along the stretch of path in the Warden's range and hits every nightmare it
# passes (each at most once per HIT_COOLDOWN). Dawnwing flies faster the more nightmares there are;
# The Whirlwind picks up the statuses of what it touches and leaves them (half stacks) on everything
# else it passes. Script-only, world space; the Warden keeps one alive while it can attack.

const HIT_RADIUS := 36.0  # Pixels
const HIT_COOLDOWN := 0.8  # Seconds before the same nightmare can be hit again
const ROUTE_REFRESH := 1.0  # Seconds between re-reading the path (the maze changes)
const CARRY_TIME := 4.0  # Seconds a carried status stays with the cyclone without being refreshed
const ANIMATION_FPS := 12.0

var _tower: Tower
var _points: PackedVector2Array = PackedVector2Array()
var _index := 0
var _direction := 1
var _route_timer := 0.0
var _recent := {}  # Nightmare instance id -> seconds until it can be hit again
var _carried := {}  # Status id -> {"stacks", "time", "potency", "line", "source", "age"}
var _anim := 0.0
var _facing := 1.0  # 1 = moving right (the art faces right)

func _init(tower: Tower) -> void:
	_tower = tower
	top_level = true
	z_index = 6

func _ready() -> void:
	global_position = _tower.global_position
	_refresh_route()

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()
	if not is_instance_valid(_tower):
		queue_free()
		return
	_route_timer -= delta
	if _route_timer <= 0.0:
		_refresh_route()
	for id in _recent.keys():
		_recent[id] -= delta
		if _recent[id] <= 0.0:
			_recent.erase(id)
	for id in _carried.keys():
		_carried[id].age += delta
		if _carried[id].age > CARRY_TIME:
			_carried.erase(id)
	_move(delta)
	_hit_nearby()

# The path tiles in range, in the order nightmares walk them.
func _refresh_route() -> void:
	_route_timer = ROUTE_REFRESH
	var route: PackedVector2Array = _tower._route()
	var points := PackedVector2Array()
	for cell in route:
		if _tower._is_cell_in_range(cell):
			points.append(Tower.MAP_GRID.calculate_map_position(cell))
	if points.size() != _points.size():
		_index = 0
		_direction = 1
		if not points.is_empty() and _tower.attack_data.patrol_idle_texture == null:
			global_position = points[0]
	_points = points

func _speed() -> float:
	var data: TowerData = _tower.attack_data
	var multiplier := 1.0 + data.patrol_speed_per_nightmare * _tower.get_enemies_in_range().size()
	return data.patrol_speed * minf(multiplier, maxf(data.patrol_speed_max, 1.0))

# Dawnwing: the bird is out while there are nightmares in range, otherwise it perches on the Warden.
func is_out() -> bool:
	return global_position.distance_to(_tower.global_position) > 8.0

func _move(delta: float) -> void:
	var before := global_position
	_step(delta)
	if absf(global_position.x - before.x) > 0.01:
		_facing = signf(global_position.x - before.x)
	# The perched bird is drawn by the Warden's own sprite.
	visible = _tower.attack_data.patrol_idle_texture == null or is_out()

func _step(delta: float) -> void:
	if _tower.attack_data.patrol_idle_texture != null and _tower.get_enemies_in_range().is_empty():
		global_position = global_position.move_toward(_tower.global_position, _speed() * delta)
		return
	if _points.size() < 2:
		global_position = global_position.move_toward(_tower.global_position, _speed() * delta)
		return
	var step := _speed() * delta
	while step > 0.0:
		var goal := _points[_index]
		var distance := global_position.distance_to(goal)
		if distance > step:
			global_position = global_position.move_toward(goal, step)
			return
		global_position = goal
		step -= distance
		if _index + _direction < 0 or _index + _direction >= _points.size():
			_direction = -_direction  # Turn back at either end of the stretch
		_index += _direction

func _hit_nearby() -> void:
	var carries: bool = _tower.attack_data.patrol_carries_statuses
	for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
		var id: int = enemy.get_instance_id()
		if _recent.has(id) or enemy.global_position.distance_to(global_position) > HIT_RADIUS:
			continue
		_recent[id] = HIT_COOLDOWN
		if carries:
			_pick_up(enemy)
			_leave_on(enemy)
		_tower.hit(enemy, 1.0, true)

# The Whirlwind: the strongest version of each status it touches travels with it.
func _pick_up(enemy: Node2D) -> void:
	for status in enemy.statuses.snapshot():
		var have: Dictionary = _carried.get(status.id, {})
		if have.is_empty() or status.stacks >= have.stacks:
			status["age"] = 0.0
			_carried[status.id] = status
		else:
			have.age = 0.0

func _leave_on(enemy: Node2D) -> void:
	for id in _carried:
		if enemy.statuses.has(id):
			continue
		var status: Dictionary = _carried[id]
		enemy.apply_status(id, maxi(ceili(status.stacks / 2.0), 1), maxf(status.time, 1.0), status.potency, 0,
			status.line, status.get("source"))

func _draw() -> void:
	if is_instance_valid(_tower) and _tower.attack_data.patrol_texture != null:
		var data: TowerData = _tower.attack_data
		var sheet := data.patrol_texture
		var frame_size := Vector2(sheet.get_width() / float(data.patrol_frames), sheet.get_height())
		var frame_index := int(_anim * ANIMATION_FPS) % data.patrol_frames
		var origin := -data.patrol_anchor
		if _facing < 0.0:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
		draw_texture_rect_region(sheet, Rect2(origin, frame_size), Rect2(Vector2(frame_size.x * frame_index, 0), frame_size))
		return
	var texture: Texture2D = _tower.attack_data.projectile_texture if is_instance_valid(_tower) else null
	if texture == null:
		if is_instance_valid(_tower) and _tower.attack_data.patrol_carries_statuses:
			# A swirling cyclone.
			for i in 3:
				draw_arc(Vector2(0, -6 * i), 16.0 - 4.0 * i, _anim * 6.0 + i, _anim * 6.0 + i + 4.5, 12,
					Color(Palette.MOONLIGHT, 0.7 - 0.15 * i), 3.0)
		else:
			# A great golden bird.
			var flap := sin(_anim * 10.0) * 6.0
			draw_line(Vector2(-18, -flap), Vector2(0, 0), Palette.GLOW, 4.0)
			draw_line(Vector2(18, -flap), Vector2(0, 0), Palette.GLOW, 4.0)
			draw_circle(Vector2.ZERO, 5.0, Palette.HEARTLIGHT)
		return
	var frames: int = _tower.attack_data.projectile_frames
	var size := Vector2(texture.get_width() / float(frames), texture.get_height()) * 2.0
	var frame := int(_anim * ANIMATION_FPS) % frames
	draw_texture_rect_region(texture, Rect2(-size / 2.0, size),
		Rect2(Vector2(size.x / 2.0 * frame, 0), size / 2.0))
