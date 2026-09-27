extends Node2D
class_name Tower

@export var tower_data: TowerData
@onready var sprite: Sprite2D = $Sprite2D

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const ENEMY_GROUP := "enemies"

# The grid cell this tower occupies (set by TowerPlacer).
var cell: Vector2
# All Dew put into this Warden (build cost, later evolutions). Selling refunds a share of it.
var invested_dew := 0

var _cooldown := 0.0  # Seconds until the tower can attack again
var _anim_time := 0.0
var _attack_time := -1.0  # Seconds into the attack animation; negative while idling
var _attack_fps := 0.0
var _released := false  # The current attack's shot / pulse has happened

func _ready() -> void:
	_show_idle()
	# Start each tower at a random point in its idle loop so neighbours don't breathe in sync.
	_anim_time = randf() * tower_data.frame_count / tower_data.animation_fps
	# Play the attack faster if it wouldn't finish before the next one is due.
	if tower_data.can_attack:
		_attack_fps = maxf(tower_data.attack_animation_fps,
			tower_data.attack_frame_count * tower_data.attacks_per_second)
	queue_redraw()

func _process(delta: float) -> void:
	_anim_time += delta
	if _attack_time >= 0.0:
		_advance_attack(delta)
	else:
		sprite.frame = int(_anim_time * tower_data.animation_fps) % tower_data.frame_count
	if not tower_data.can_attack:
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _cooldown > 0.0 or _attack_time >= 0.0 or find_target() == null:
		return
	_start_attack()

# Winds up the attack animation; the shot / pulse happens on its release frame.
func _start_attack() -> void:
	_cooldown = 1.0 / tower_data.attacks_per_second
	if tower_data.attack_texture == null:
		_release()
		return
	_attack_time = 0.0
	_released = false
	sprite.texture = tower_data.attack_texture
	sprite.hframes = tower_data.attack_frame_count
	sprite.frame = 0

func _advance_attack(delta: float) -> void:
	_attack_time += delta
	var frame := int(_attack_time * _attack_fps)
	if not _released and frame >= tower_data.attack_release_frame:
		_released = true
		_release()
	if frame >= tower_data.attack_frame_count:
		_attack_time = -1.0
		_show_idle()
		return
	sprite.frame = frame

func _show_idle() -> void:
	sprite.texture = tower_data.texture
	sprite.hframes = tower_data.frame_count
	sprite.frame = int(_anim_time * tower_data.animation_fps) % tower_data.frame_count

# Fires at the current "first" target, or soothes everything in range for a pulse. A projectile
# attack whose target left range during the wind-up is wasted.
func _release() -> void:
	match tower_data.attack_kind:
		TowerData.AttackKind.PULSE:
			for enemy in get_enemies_in_range():
				enemy.take_damage(tower_data.damage)
		_:
			var target := find_target()
			if target != null:
				fire_at(target)

func _draw() -> void:
	if tower_data.texture == null:
		draw_placeholder(self, tower_data.placeholder_color)

# Attack reach in pixels.
func get_range_pixels() -> float:
	return range_to_pixels(tower_data.attack_range)

# The blighted enemy in range that is closest to the goal ("first"), or null.
func find_target() -> Node2D:
	var best: Node2D = null
	var best_remaining := INF
	for enemy in get_enemies_in_range():
		var remaining: float = enemy.get_remaining_distance()
		if remaining < best_remaining:
			best_remaining = remaining
			best = enemy
	return best

# Blighted enemies within attack range.
func get_enemies_in_range() -> Array[Node2D]:
	var range_squared := get_range_pixels() ** 2
	var result: Array[Node2D] = []
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if global_position.distance_squared_to(enemy.global_position) <= range_squared:
			result.append(enemy)
	return result

func fire_at(target: Node2D) -> void:
	var projectile := Projectile.new(target, tower_data)
	add_child(projectile)
	projectile.global_position = global_position + tower_data.attack_origin

# Converts a range in cells to pixels. Shared with the build-mode ghost preview.
static func range_to_pixels(range_cells: float) -> float:
	return range_cells * MAP_GRID.cell_size.x

# Draws a simple stone block centred on the origin. Shared with the build-mode ghost preview.
static func draw_placeholder(canvas: CanvasItem, color: Color) -> void:
	var block := Rect2(-24, -24, 48, 48)
	canvas.draw_rect(block, color.darkened(0.45))
	canvas.draw_rect(block.grow(-4), color)
	canvas.draw_circle(Vector2.ZERO, 10, color.lightened(0.35))
