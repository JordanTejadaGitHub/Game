extends Node2D
class_name Projectile

# A projectile (spore puff, pebble, spark, ...) that homes in on its target. On arrival it calls
# `on_land(target_or_null, position)` (the tower soothes the target, or splashes around the
# position). If the target is cleansed or gone first, it finishes its flight to the last known
# position (a splash still lands there). Uses the tower's projectile sheet, rotated to face travel,
# or draws a coloured puff when the tower has none.

const RADIUS := 6.0
const ANIMATION_FPS := 12.0
const TRAIL_POINTS := 7
const DREAM_GLOW := preload("res://scripts/fx/dream_glow.gd")

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
var return_multiplier := 1.0  # (Homing Instinct's old return speed: retired 2026-10-16, always 1 now)
# Homing Instinct (card pass 2026-10-16): "A bird whose swoop dispels its target swoops again at once at the nearest
# nightmare." Re-swoops left on this bird (the Warden sets it), to the nearest nightmare within HOMING_REACH of it.
const HOMING_RESWOOPS := 1
const HOMING_REACH := 3.0  # Cells
var reswoops := 0
var _home := Vector2.ZERO
var _returning := false
# Lob (Cairn): flies over walls in a high arc to the tile the target was on when fired, and lands
# there even if the target has moved on.
var _lob := false
var _lob_height := 0.0
var _lob_distance := 1.0
var trail := Color(0, 0, 0, 0)  # Borrowed looks: a bonded Warden's shots trail its kin's colour
var _trail: Array[Vector2] = []  # Recent world positions for the trail
var _drawn_frame := -1
# Boosted-attack glow (visual feedback spec B2; set by the Warden, Tower.dream_glow_tier): a warm ember-edged trail, 3
# samples at tier 1, 5 from tier 2 (+ a soft halo on the head), GLOW at tier 3. A lob's shadow gets a warm rim.
var dream_tier := 0
var _dream_dir := Vector2.RIGHT  # Its flight direction (world), for the trail drawn behind the head

func _init(target: Node2D, data: TowerData, on_land: Callable) -> void:
	_target = target
	_target_position = Tower.aim_at(target)
	_on_land = on_land
	speed = data.projectile_speed
	color = data.projectile_color
	texture = data.projectile_texture
	frame_count = data.projectile_frames
	_returns = data.projectile_returns
	_lob = data.lob
	_lob_height = data.lob_height
	if _lob:
		_target_position = Tower.MAP_GRID.calculate_map_position(target.get_current_cell())
	top_level = true  # Fly in world space, independent of the tower that fired it

func _ready() -> void:
	_home = global_position
	_lob_distance = maxf(global_position.distance_to(_target_position), 1.0)

func is_returning() -> bool:
	return _returning

func _process(delta: float) -> void:
	var step := speed * delta
	if trail.a > 0.0:
		_trail.append(global_position + Vector2(0, -_lob_lift()))
		if _trail.size() > TRAIL_POINTS:
			_trail.pop_front()
	if _returning:
		if global_position.distance_to(_home) <= step:
			queue_free()
			return
		_fly_toward(_home, step * return_multiplier, delta)
		return

	var target_alive: bool = is_instance_valid(_target) and not _target.is_cleansed
	if target_alive and not _lob:
		_target_position = Tower.aim_at(_target)  # Fly at the drawn body (feet on the route point)

	if global_position.distance_to(_target_position) <= step:
		_on_land.call(_target if target_alive else null, _target.global_position if target_alive and not _lob else _target_position)  # Lands at the logical spot (splash)
		if _returns and reswoops > 0 and target_alive and (not is_instance_valid(_target) or _target.is_cleansed):
			var next := _nearest_nightmare()
			if next != null:
				reswoops -= 1  # Homing Instinct: its swoop dispelled the target, so it swoops on at once
				_target = next
				_target_position = Tower.aim_at(next)
				return
		if _returns:
			_returning = true
			return
		queue_free()
		return
	_fly_toward(_target_position, step, delta)

# The nearest live nightmare within HOMING_REACH cells of the bird (flyers too: a swoop reaches them), or null.
func _nearest_nightmare() -> Node2D:
	var best: Node2D = null
	var best_d := HOMING_REACH * Tower.MAP_GRID.cell_size.x
	for other in Tower.nightmares_near(get_tree(), global_position, best_d):
		if is_instance_valid(other) and not other.is_cleansed and other.global_position.distance_to(global_position) <= best_d:
			best_d = other.global_position.distance_to(global_position)
			best = other
	return best

func _fly_toward(to: Vector2, step: float, delta: float) -> void:
	_anim_time += delta
	if dream_tier > 0 and global_position != to:
		_dream_dir = global_position.direction_to(to)
	if texture != null and not _lob:
		rotation = global_position.direction_to(to).angle()
	# Performance: redraw only when the drawing changes (a new sheet frame, a lob's arc, a trail); moving and
	# rotating the node doesn't need one.
	var frame := int(_anim_time * ANIMATION_FPS)
	if _lob or not _trail.is_empty() or frame != _drawn_frame:
		_drawn_frame = frame
		queue_redraw()
	global_position = global_position.move_toward(to, step)

# How high a lobbed stone is above the ground right now (0 at both ends of the arc).
func _lob_lift() -> float:
	if not _lob:
		return 0.0
	var t := 1.0 - global_position.distance_to(_target_position) / _lob_distance
	return sin(clampf(t, 0.0, 1.0) * PI) * _lob_height

func _draw() -> void:
	var lift := _lob_lift()
	for i in _trail.size():  # Borrowed looks: a fading trail in the kin's colour, oldest faintest
		var t := float(i + 1) / (_trail.size() + 1)
		draw_circle(to_local(_trail[i]), 1.5 + 2.0 * t, Color(trail, trail.a * 0.55 * t))
	if dream_tier > 0:  # Drawn behind the head along its flight: no redraw beyond the sheet's own (test_perf_stress)
		DREAM_GLOW.trail_behind(self, Vector2(0, -lift), _dream_dir.rotated(-global_rotation), dream_tier)
	if _lob:
		var shadow := RADIUS * (1.0 - lift / (_lob_height * 2.0))
		draw_circle(Vector2.ZERO, shadow, Color(Palette.VOID, 0.25))  # Its shadow
		if dream_tier > 0:
			draw_arc(Vector2.ZERO, shadow + 0.5, 0.0, TAU, 16, Color(DREAM_GLOW.core(dream_tier), DREAM_GLOW.alpha(dream_tier)), 1.0)
	var at := Vector2(0, -lift)
	if dream_tier >= 2:
		DREAM_GLOW.dot(self, at, RADIUS * 0.6, dream_tier, 0.6)  # The soft halo on the head
	if texture == null:
		draw_circle(at, RADIUS, color.darkened(0.3))
		draw_circle(at, RADIUS - 2.0, color)
		return
	var frame := int(_anim_time * ANIMATION_FPS) % frame_count
	var size := Vector2(texture.get_width() / float(frame_count), texture.get_height())
	draw_texture_rect_region(texture, Rect2(at - size / 2.0, size), Rect2(Vector2(size.x * frame, 0), size))
