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
	_duration = duration

func _ready() -> void:
	# The rubble ground tile from the effects player, held for the rubble's lifetime (it fades itself).
	for cell in _cells:
		if Fx.play(&"rubble", Tower.MAP_GRID.calculate_map_position(cell), self, 1.0, true, _duration) != null:
			_drawn_by_fx = true

func _process(delta: float) -> void:
	_age += delta
	if _age >= _duration:
		queue_free()
		return
	_tick -= delta
	if _tick <= 0.0:
		_tick = TICK
		for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
			if _cells.has(enemy.get_current_cell()) and not enemy.is_flying():  # Ground: flyers (Phantoms, the Moth Queen) pass over
				var s: EnemyStatuses = enemy.statuses
				s.slow_time = maxf(s.slow_time, TICK * 1.6)
				s.slow_amount = maxf(s.slow_amount if s.slow_time > 0.0 else 0.0, _slow)
	if not _drawn_by_fx:
		queue_redraw()

# Without the effects player's rubble tile: a scatter of stones.
func _draw() -> void:
	if _drawn_by_fx:
		return
	var fade := minf(1.0, (_duration - _age) / 0.5)
	for cell in _cells:
		var centre: Vector2 = Tower.MAP_GRID.calculate_map_position(cell)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(cell)  # The same stones every frame
		for i in 7:
			var at := centre + Vector2(rng.randf_range(-22, 22), rng.randf_range(-18, 18))
			var size := rng.randf_range(3.0, 6.0)
			draw_circle(at + Vector2(1, 1.5), size, Color(0.1, 0.08, 0.08, 0.35 * fade))
			draw_circle(at, size, Color(0.55, 0.52, 0.5, 0.9 * fade))
