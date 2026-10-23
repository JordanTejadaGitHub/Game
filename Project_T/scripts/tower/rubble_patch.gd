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
# Avalanche's scree (owner 2026-10-17, council reactions_unique.md; set by Reactions._avalanche, 0 = plain rubble):
# walkers on it gain 1 Rooted every `rooted_every` s (each holding `rooted_time` s), up to `rooted_max` per walker, and with
# Mountain's Fall `soak_stacks` Soaked every `soak_every` s. Through Enemy.apply_status (immunities and caps hold); never bosses' Rooted.
var rooted_every := 0.0
var rooted_max := 0
var rooted_time := 0.6
var soak_every := 0.0
var soak_stacks := 1
var source: Node = null
var _given := {}  # Nightmare instance id -> [time to its next Rooted, time to its next Soaked] (the Rooted count is the nightmare's: council rx review 2026-10-17)

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
				if rooted_every > 0.0 or soak_every > 0.0:
					_scree(enemy)
	if not _drawn_by_fx:
		queue_redraw()

# Scree (Avalanche): one walker on it this TICK. The first Rooted and Soaked come at once, then every rooted_every /
# soak_every seconds while it stays on the scree.
func _scree(enemy: Node2D) -> void:
	var key: int = enemy.get_instance_id()
	var row: Array = _given.get(key, [0.0, 0.0])
	row[0] = float(row[0]) - TICK
	row[1] = float(row[1]) - TICK
	var by: Node = source if is_instance_valid(source) else null
	# (council rx review 2026-10-17) The count is the nightmare's, not this patch's: overlapping patches add to one
	# scree_given, and a walker that reached rooted_max rests from all scree Rooted for the scree's time + its Hold
	# breather (&"scree" cooldown), so patches never stack into an endless hold.
	var s: EnemyStatuses = enemy.statuses
	if rooted_every > 0.0 and float(row[0]) <= 0.0 and not s.is_boss and not s.is_on_cooldown(&"scree"):
		row[0] = rooted_every
		s.scree_given += 1
		if s.scree_given >= rooted_max:
			s.scree_given = 0
			s.start_cooldown(&"scree", _duration + EnemyStatuses.HOLD_COOLDOWN)
		Reactions._in_reaction += 1  # Scree is a Reaction's (Avalanche): its statuses never crown late (owner 2026-10-22)
		enemy.apply_status(EnemyStatuses.HELD, 1, rooted_time, 0.0, 0, "stone", by)
		Reactions._in_reaction -= 1
	if soak_every > 0.0 and float(row[1]) <= 0.0 and is_instance_valid(enemy) and not enemy.is_cleansed:
		row[1] = soak_every
		Reactions._in_reaction += 1
		enemy.apply_status(EnemyStatuses.DAMP, soak_stacks, 0.0, 0.0, 0, "water", by)
		Reactions._in_reaction -= 1
	_given[key] = row

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
