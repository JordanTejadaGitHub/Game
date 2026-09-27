extends Node2D
class_name Tower

@export var tower_data: TowerData
@onready var sprite: Sprite2D = $Sprite2D

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const ENEMY_GROUP := "enemies"

# The grid cell this tower occupies (set by TowerPlacer).
var cell: Vector2

var _cooldown := 0.0  # Seconds until the tower can fire again
var _anim_time := 0.0

func _ready() -> void:
	sprite.texture = tower_data.texture
	sprite.hframes = tower_data.frame_count
	# Start each tower at a random point in its idle loop so neighbours don't breathe in sync.
	_anim_time = randf() * tower_data.frame_count / tower_data.animation_fps
	queue_redraw()

func _process(delta: float) -> void:
	_anim_time += delta
	sprite.frame = int(_anim_time * tower_data.animation_fps) % tower_data.frame_count
	if not tower_data.can_attack:
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _cooldown > 0.0:
		return
	var target := find_target()
	if target == null:
		return
	fire_at(target)
	_cooldown = 1.0 / tower_data.attacks_per_second

func _draw() -> void:
	if tower_data.texture == null:
		draw_placeholder(self, tower_data.placeholder_color)

# Attack reach in pixels.
func get_range_pixels() -> float:
	return range_to_pixels(tower_data.attack_range)

# The blighted enemy in range that is closest to the goal ("first"), or null.
func find_target() -> Node2D:
	var range_squared := get_range_pixels() ** 2
	var best: Node2D = null
	var best_remaining := INF
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if global_position.distance_squared_to(enemy.global_position) > range_squared:
			continue
		var remaining: float = enemy.get_remaining_distance()
		if remaining < best_remaining:
			best_remaining = remaining
			best = enemy
	return best

func fire_at(target: Node2D) -> void:
	var projectile := Projectile.new(target, tower_data)
	add_child(projectile)
	projectile.global_position = global_position

# Converts a range in cells to pixels. Shared with the build-mode ghost preview.
static func range_to_pixels(range_cells: float) -> float:
	return range_cells * MAP_GRID.cell_size.x

# Draws a simple stone block centred on the origin. Shared with the build-mode ghost preview.
static func draw_placeholder(canvas: CanvasItem, color: Color) -> void:
	var block := Rect2(-24, -24, 48, 48)
	canvas.draw_rect(block, color.darkened(0.45))
	canvas.draw_rect(block.grow(-4), color)
	canvas.draw_circle(Vector2.ZERO, 10, color.lightened(0.35))
