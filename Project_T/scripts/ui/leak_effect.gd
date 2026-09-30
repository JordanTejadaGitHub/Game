extends Node2D

# Leak feedback at the Heartwood (screens_ui.md "In the world"): when a nightmare reaches the goal, a
# dark pulse spreads from it and a blackened leaf falls. Drawn in code; lives in the world.

const PULSE_TIME := 0.7
const LEAF_TIME := 1.4
const PULSE_RADIUS := 90.0

@onready var map_generator = %MapGenerator

var _pulses: Array = []  # [age]
var _leaves: Array = []  # [age, x drift]

func _ready() -> void:
	z_index = 6
	var spawner = %EnemyContainer
	spawner.enemy_reached_goal.connect(func(_enemy: Node2D) -> void:
		_pulses.append(0.0)
		_leaves.append([0.0, randf_range(-1.0, 1.0)]))
	if spawner.has_signal("boss_drained"):  # A boss staying at the Heartwood: each drained leaf falls too
		spawner.boss_drained.connect(func(_enemy: Node2D, leaves: int) -> void:
			_pulses.append(0.0)
			for i in maxi(leaves, 1):
				_leaves.append([0.0, randf_range(-1.0, 1.0)]))

func _process(delta: float) -> void:
	if _pulses.is_empty() and _leaves.is_empty():
		return
	position = map_generator.MAP_GRID.calculate_map_position(map_generator.endPath)
	for i in range(_pulses.size() - 1, -1, -1):
		_pulses[i] += delta
		if _pulses[i] >= PULSE_TIME:
			_pulses.remove_at(i)
	for i in range(_leaves.size() - 1, -1, -1):
		_leaves[i][0] += delta
		if _leaves[i][0] >= LEAF_TIME:
			_leaves.remove_at(i)
	queue_redraw()

func _draw() -> void:
	for age in _pulses:
		var t: float = age / PULSE_TIME
		draw_circle(Vector2.ZERO, PULSE_RADIUS * t, Color(Palette.DREAD, 0.35 * (1.0 - t)))
		draw_arc(Vector2.ZERO, PULSE_RADIUS * t, 0.0, TAU, 40, Color(Palette.BRUISE, 0.8 * (1.0 - t)), 3.0)
	for leaf in _leaves:
		var t: float = leaf[0] / LEAF_TIME
		var at := Vector2(sin(t * 7.0) * 14.0 + leaf[1] * 20.0 * t, -40.0 + 80.0 * t)
		var tilt := sin(t * 7.0) * 0.6
		var points := PackedVector2Array()
		for j in 8:
			var angle := TAU * j / 8.0
			points.append(at + Vector2(cos(angle) * 7.0, sin(angle) * 3.5).rotated(tilt))
		draw_colored_polygon(points, Color(Palette.DREAD, 1.0 - t * t))
