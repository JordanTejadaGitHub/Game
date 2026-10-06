extends Node2D
class_name RubblePatch

# Rockslide's rubble: the path tiles a stone came down on slow nightmares walking over them. Uses the
# nightmare's extra-slow timer (EnemyStatuses.slow_time / slow_amount), refreshed while it's on the
# rubble. Script-only, drawn on the ground under the nightmares.

const TICK := 0.25

var _cells: Array[Vector2] = []
var _slow: float
var _duration: float
var _age := 0.0
var _tick := 0.0
var _drawn_by_fx := false

func _init(cells: Array[Vector2], slow: float, duration: float) -> void:
	_cells = cells
	_slow = slow
	_duration = ShapeCards.ground_time(duration)  # Lingering Ground: x1.5

func _ready() -> void:
	# Drawn here, not with the effects player's rubble tile (art_direction.md "They must read on the pale path": that
	# tile was a dark blob the size of a nightmare). Light pebbles, scattered, so a nightmare is always darker.
	_drawn_by_fx = false

func _process(delta: float) -> void:
	_age += delta
	if _age >= _duration:
		queue_free()
		return
	_tick -= delta
	if _tick <= 0.0:
		_tick = TICK
		for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
			# The whole cell under its feet (half cells: route points step by half a cell). Ground only: flyers
			# (Phantoms, the Moth Queen) pass over.
			if _cells.has(Tower.MAP_GRID.calculate_grid_coordinates(enemy.global_position)) and not enemy.is_flying():
				var s: EnemyStatuses = enemy.statuses
				s.slow_time = maxf(s.slow_time, TICK * 1.6)
				s.slow_amount = maxf(s.slow_amount if s.slow_time > 0.0 else 0.0, _slow)
	if not _drawn_by_fx:
		queue_redraw()

# Without the effects player's rubble tile: a scatter of stones.
func _draw() -> void:
	if _drawn_by_fx:
		return
	# Light pebbles on the pale path (Stone / Mist, a Slate shadow pixel on some), scattered over the tile, in whole
	# pixels; it fades out in hard alpha steps, never a soft dark smear.
	var fade := ceilf(clampf((_duration - _age) / 0.5, 0.0, 1.0) * 3.0) / 3.0
	if fade <= 0.0:
		return
	for cell in _cells:
		var centre: Vector2 = Tower.MAP_GRID.calculate_map_position(cell)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(cell)  # The same stones every frame
		for i in 11:
			var at := (centre + Vector2(rng.randf_range(-26, 26), rng.randf_range(-24, 24))).floor()
			var size := Vector2(rng.randi_range(2, 4), rng.randi_range(2, 3))
			var tone: Color = Palette.MIST if rng.randf() < 0.45 else Palette.STONE
			if rng.randf() < 0.5:
				draw_rect(Rect2(at + Vector2(1, size.y), Vector2(size.x, 1)), Color(Palette.SLATE, fade))  # A shadow pixel row
			draw_rect(Rect2(at, size), Color(tone, fade))
