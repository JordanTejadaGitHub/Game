extends Node2D

# Emitted when the enemy walks off the end of its path (reaches the goal), right before it's freed.
signal reached_goal(enemy: Node2D)
# Emitted when health hits 0. The enemy stops being a target and plays its cleanse effect.
signal cleansed(enemy: Node2D)
# TRAMPLE (Old Stag): wants to knock down a Thornwall next to it. The spawner calls
# `trampled()` back if it did.
signal trample_requested(enemy: Node2D)
# LEAP (Great Toad) landed at its new position.
signal leaped(enemy: Node2D)

# Deeply Blighted elites (acts_1_2.md): ×3 health, ×3 Dew, 2 leaves, 20% bigger and darker.
const ELITE_HEALTH := 3.0
const ELITE_DEW := 3
const ELITE_LEAVES := 2
const ELITE_SCALE := 1.2
const ELITE_DARKEN := 0.35
const LEAP_TIME := 0.45  # Seconds in the air

# Group of enemies that are still blighted (walking, targetable). Cleansed enemies leave it.
const GROUP := "enemies"
const BLIGHT_SHADER := preload("res://shaders/blight.gdshader")
const HEALTH_BAR_SIZE := Vector2(40, 5)
const HEALTH_BAR_OFFSET := Vector2(0, -38)  # Bar centre, relative to the enemy's origin
const CLEANSE_TIME := 0.8

@export var enemy_data: EnemyData
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var grid: Grid = preload("res://resource/map/map_grid.tres") # Reference to the shared Grid resource

var health: int
var max_health: int
var speed: float
var is_cleansed := false
# Multiplies `enemy_data.health` (set before adding to the tree; drifts grow creatures this way).
var health_scale := 1.0
# Damp, Drowsy, Spored, Marked, Static (see EnemyStatuses). Wardens apply them via apply_status().
var statuses := EnemyStatuses.new()

const STATUS_DOT_RADIUS := 3.0
const BOLT_FLASH_TIME := 0.2
const HIT_MARK_TIME := 0.35  # Grey puff (resisted) / sparkle (weak) after a hit
const COAT_COLOR := Color(0.62, 0.6, 0.66)

var _soothe_carry := 0.0  # Fractional soothe (Spored ticks, multipliers) waiting to add up to 1
var _bolt_flash := 0.0
var _hit_mark := 0  # -1 resisted, +1 weak, 0 none
var _hit_mark_time := 0.0
# Blight coat left to soak up, and soothe it takes off each hit (both already health-scaled).
var coat := 0.0
var coat_max := 0.0
var _coat_per_hit := 0.0
# Omen modifiers for this creature's drift (set before adding to the tree; bosses get none):
# {"speed", "coat", "dew", "status_duration": multiplier}. Split-off creatures inherit them.
var modifiers := {}

var elite := false  # Deeply Blighted (set before adding to the tree)
var hold_time := 0.0  # Seconds to stand still before setting off (Ducklings in single file)
var rolling := false  # Hedgehog curled up
var lost := false  # Duckling whose Mother Duck was cleansed first
var _straight_steps := 0
var _last_step := Vector2.ZERO
var _trait_timer := 0.0
var _trampled := 0
var _startled := false
var _charge_left := 0.0
var _leaping := false

# Cells to walk through, in grid coordinates. `_path_index` is the cell we're currently walking toward.
var _path: PackedVector2Array
var _path_index: int = 0

func _ready() -> void:
	add_to_group(GROUP)

	# Initialize attributes
	max_health = maxi(roundi(enemy_data.health * health_scale * (ELITE_HEALTH if elite else 1.0)), 1)
	health = max_health
	speed = enemy_data.speed * modifiers.get("speed", 1.0)
	statuses.is_boss = enemy_data.is_boss
	statuses.immune = enemy_data.status_immune
	statuses.duration_multipliers = enemy_data.status_duration_multipliers
	statuses.duration_multiplier_all = modifiers.get("status_duration", 1.0)
	coat_max = enemy_data.coat_total * health_scale * modifiers.get("coat", 1.0)
	coat = coat_max
	_coat_per_hit = enemy_data.coat_per_hit * health_scale * modifiers.get("coat", 1.0)

	# Set up animations
	sprite.sprite_frames = enemy_data.sprite_frames
	sprite.scale = Vector2.ONE * enemy_data.sprite_scale * (ELITE_SCALE if elite else 1.0)
	sprite.modulate = enemy_data.tint.darkened(ELITE_DARKEN) if elite else enemy_data.tint
	sprite.play("walk_side")

	# Blighted look: per-enemy material so each one can be cleansed on its own
	var blight_material := ShaderMaterial.new()
	blight_material.shader = BLIGHT_SHADER
	sprite.material = blight_material

func _process(delta: float) -> void:
	if is_cleansed or _path_index >= _path.size():
		return

	var spore_soothe := statuses.tick(delta)
	if spore_soothe > 0.0:
		take_damage(spore_soothe, statuses.spore_line(), true)
		if is_cleansed:
			return
	_bolt_flash = maxf(_bolt_flash - delta, 0.0)
	_hit_mark_time = maxf(_hit_mark_time - delta, 0.0)
	if not statuses.active_ids().is_empty() or _bolt_flash > 0.0 or _hit_mark_time > 0.0 or elite:
		queue_redraw()

	if hold_time > 0.0:
		hold_time -= delta
		return
	_charge_left = maxf(_charge_left - delta, 0.0)
	_update_trait(delta)
	if _leaping:
		return

	var previous_position := position
	# Walk toward the next cell centre; carry leftover distance into the following cell so speed
	# stays constant through corners.
	var remaining := get_move_speed() * delta
	while remaining > 0.0 and _path_index < _path.size():
		var target := grid.calculate_map_position(_path[_path_index])
		var to_target := target - position
		var distance := to_target.length()
		if distance <= remaining:
			position = target
			remaining -= distance
			_path_index += 1
			_on_cell_reached()
		else:
			position += to_target / distance * remaining
			remaining = 0.0

	# Update animation based on movement direction
	update_animation(position - previous_position)

	if _path_index >= _path.size():
		reached_goal.emit(self)
		queue_free()

func _draw() -> void:
	if is_cleansed:
		return
	if _bolt_flash > 0.0:
		var t := _bolt_flash / BOLT_FLASH_TIME
		draw_circle(Vector2.ZERO, 26.0 * (1.5 - t), Color(1.0, 1.0, 0.6, 0.5 * t))
	if _hit_mark_time > 0.0:
		_draw_hit_mark(_hit_mark_time / HIT_MARK_TIME)
	# One coloured dot per status, just above where the health bar sits
	var ids := statuses.active_ids()
	var x := -(ids.size() - 1) * STATUS_DOT_RADIUS * 1.5
	for id in ids:
		var dot := HEALTH_BAR_OFFSET + Vector2(x, -8)
		draw_circle(dot, STATUS_DOT_RADIUS + 1, Color(0.1, 0.1, 0.12, 0.8))
		draw_circle(dot, STATUS_DOT_RADIUS, EnemyStatuses.COLORS[id])
		x += STATUS_DOT_RADIUS * 3.0
	# Health bar once the enemy has been hit, with the blight coat as a grey bar on top of it
	var bar := Rect2(HEALTH_BAR_OFFSET - HEALTH_BAR_SIZE / 2, HEALTH_BAR_SIZE)
	if health < max_health:
		draw_rect(bar.grow(1), Color(0.1, 0.1, 0.12, 0.8))
		var fill := bar
		fill.size.x *= float(health) / max_health
		draw_rect(fill, Color(0.55, 0.9, 0.5))
	if coat > 0.0:
		var crust := Rect2(bar.position - Vector2(0, 4), Vector2(bar.size.x * coat / maxf(coat_max, 1.0), 3))
		draw_rect(crust.grow(1), Color(0.1, 0.1, 0.12, 0.8))
		draw_rect(crust, COAT_COLOR)

# A small grey puff for a resisted hit, a little sparkle for a weak one. `t` fades 1 -> 0.
func _draw_hit_mark(t: float) -> void:
	var at := Vector2(10, -20)
	if _hit_mark < 0:
		for i in 3:
			var puff := at + Vector2.from_angle(TAU * i / 3.0) * 4.0 * (1.6 - t)
			draw_circle(puff, 3.5 * t + 1.0, Color(0.75, 0.75, 0.78, 0.7 * t))
	else:
		var r := 7.0 * (1.4 - t)
		var col := Color(1.0, 0.95, 0.6, t)
		draw_line(at + Vector2(-r, 0), at + Vector2(r, 0), col, 2.0)
		draw_line(at + Vector2(0, -r), at + Vector2(0, r), col, 2.0)

func update_animation(velocity: Vector2) -> void:
	# Keep the current animation when not moving (e.g. end of path)
	if velocity.is_zero_approx():
		return
	if rolling and sprite.sprite_frames.has_animation("roll"):
		sprite.play("roll")
		sprite.flip_h = velocity.x < 0
	elif abs(velocity.x) >= abs(velocity.y):  # Moving horizontally
		sprite.play("walk_side")
		sprite.flip_h = velocity.x < 0  # Flip horizontally if moving left
	elif velocity.y > 0:  # Moving down
		sprite.play("walk_down")
		sprite.flip_h = false
	else:  # Moving up
		sprite.play("walk_up")
		sprite.flip_h = false

# Dew for cleansing this creature (Omens can change it, e.g. Dry Spell = 0).
func get_dew_reward() -> int:
	return roundi(enemy_data.dew_reward * modifiers.get("dew", 1.0)) * (ELITE_DEW if elite else 1)

# Leaves lost when this creature reaches the Heartwood (Deeply Blighted cost at least 2).
func get_leaf_cost() -> int:
	return maxi(enemy_data.leaf_cost, ELITE_LEAVES) if elite else enemy_data.leaf_cost

func is_flying() -> bool:
	return enemy_data.trait_kind == EnemyData.Trait.FLYING

# Pixels per second right now: base speed, rolling / lost / startled, then slows.
func get_move_speed() -> float:
	var base := speed
	if rolling:
		base = enemy_data.roll_speed * modifiers.get("speed", 1.0)
	elif lost:
		base = minf(base, enemy_data.lost_speed)
	if _charge_left > 0.0:
		base *= enemy_data.charge_speed_multiplier
	return base * statuses.get_speed_multiplier()

# A Duckling whose Mother Duck was cleansed first wanders on, slowly.
func set_lost() -> void:
	if not is_cleansed:
		lost = true

# The spawner knocked down a Thornwall for this creature (TRAMPLE).
func trampled() -> void:
	_trampled += 1
	_trait_timer = 0.0


# --- Traits (acts_1_2.md) ---------------------------------------------------------------------

func _update_trait(delta: float) -> void:
	match enemy_data.trait_kind:
		EnemyData.Trait.TRAMPLE:
			if _trampled >= enemy_data.trample_max:
				return
			_trait_timer += delta
			if _trait_timer >= enemy_data.trample_interval:
				_trait_timer = enemy_data.trample_interval - 0.25  # No wall in reach: look again soon
				trample_requested.emit(self)
		EnemyData.Trait.LEAP:
			_trait_timer += delta
			var hurt := health <= max_health / 2
			var interval := enemy_data.leap_interval_hurt if hurt else enemy_data.leap_interval
			if _trait_timer >= interval:
				_trait_timer = 0.0
				_leap()

# Called each time the creature reaches a cell centre on its path.
func _on_cell_reached() -> void:
	if enemy_data.trait_kind != EnemyData.Trait.ROLLING or _path_index < 1:
		return
	var step := _path[_path_index - 1] - (_path[_path_index - 2] if _path_index >= 2 else get_current_cell())
	_straight_steps = _straight_steps + 1 if step == _last_step else 1
	_last_step = step
	# Keeps rolling only while the next step goes the same way; stops at the turn.
	var next_same := _path_index < _path.size() and _path[_path_index] - _path[_path_index - 1] == step
	rolling = _straight_steps >= enemy_data.roll_after_tiles and next_same

# Great Toad: hops `leap_tiles` ahead along its path, then makes creatures near the landing Damp.
func _leap() -> void:
	if _path_index >= _path.size():
		return
	var landing_index := mini(_path_index + enemy_data.leap_tiles - 1, _path.size() - 1)
	var landing := grid.calculate_map_position(_path[landing_index])
	_leaping = true
	var tween := create_tween()
	tween.tween_property(self, "position", landing, LEAP_TIME).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "position:y", -28.0, LEAP_TIME / 2).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "position:y", 0.0, LEAP_TIME / 2).set_delay(LEAP_TIME / 2).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		_leaping = false
		_path_index = landing_index + 1
		var reach := enemy_data.leap_splash_radius * grid.cell_size.x
		for creature in get_tree().get_nodes_in_group(GROUP):
			if creature.global_position.distance_to(global_position) <= reach:
				creature.apply_status(EnemyStatuses.DAMP)
		leaped.emit(self)
		if _path_index >= _path.size():
			reached_goal.emit(self)
			queue_free())

# Soothes the blight away. `line` is the Warden family that soothed it ("" = neutral) and `is_area`
# whether it was an area hit (splash, pulse, cloud, Spored). Soothe = amount × family × shape ×
# Marked, then the blight coat takes its bite. At 0 health the enemy is cleansed.
func take_damage(amount: float, line: String = "", is_area: bool = false) -> void:
	if is_cleansed:
		return
	var soothe := amount * enemy_data.get_soothe_multiplier(line, is_area) * statuses.get_damage_taken_multiplier()
	if line in enemy_data.resists:
		_mark_hit(-1)
	elif line in enemy_data.weak_to:
		_mark_hit(1)
	if coat > 0.0 and soothe > 0.0:
		# Each hit loses up to _coat_per_hit (always keeping at least 1), never more than the coat has left.
		var soaked := minf(minf(_coat_per_hit, coat), soothe - minf(soothe, 1.0))
		coat -= soaked
		soothe -= soaked
		if coat <= 0.0:
			coat = 0.0
			_mark_hit(-1)  # The crust crumbles off in a puff
	_soothe_carry += soothe
	var whole := int(_soothe_carry)
	_soothe_carry -= whole
	health = maxi(health - whole, 0)
	queue_redraw()
	if health == 0:
		_cleanse()
	elif enemy_data.trait_kind == EnemyData.Trait.TRAMPLE and not _startled and health <= max_health / 2:
		_startled = true  # Old Stag panics and charges
		_charge_left = enemy_data.charge_time

# Applies a status from a Warden (`potency` = its soothe, see EnemyStatuses). A Static charge that
# fills up sets off a free bolt right away.
func apply_status(id: StringName, stacks: int = 1, duration: float = 0.0, potency: float = 0.0,
		max_stacks: int = 0, line: String = "") -> void:
	if is_cleansed:
		return
	var bolt := statuses.apply(id, stacks, duration, potency, max_stacks, line)
	queue_redraw()
	if bolt > 0.0:
		_bolt_flash = BOLT_FLASH_TIME
		take_damage(bolt, "light")  # Static bolts count as light

func _mark_hit(kind: int) -> void:
	_hit_mark = kind
	_hit_mark_time = HIT_MARK_TIME

# Colour returns, the creature hops happily and fades out. It no longer blocks building or re-routes.
func _cleanse() -> void:
	is_cleansed = true
	remove_from_group(GROUP)
	cleansed.emit(self)
	queue_redraw()

	var tween := create_tween()
	tween.tween_method(_set_blight, 1.0, 0.0, CLEANSE_TIME * 0.4)
	tween.parallel().tween_property(sprite, "scale", Vector2(1.25, 1.25), CLEANSE_TIME * 0.2)
	tween.tween_property(sprite, "scale", Vector2.ONE, CLEANSE_TIME * 0.2)
	tween.tween_property(sprite, "position:y", -24.0, CLEANSE_TIME * 0.6)
	tween.parallel().tween_property(self, "modulate:a", 0.0, CLEANSE_TIME * 0.6)
	tween.tween_callback(queue_free)

# 1 = fully blighted (grey), 0 = cleansed (full colour).
func _set_blight(amount: float) -> void:
	(sprite.material as ShaderMaterial).set_shader_parameter("blight", amount)


# Sets the cells to walk through (grid coordinates). The enemy heads to points[0] first.
func set_path(points: PackedVector2Array) -> void:
	_path = points
	_path_index = 0

# The cell the enemy is currently walking toward. New paths should start from here so the enemy
# never cuts diagonally through a cell mid-step.
func get_target_cell() -> Vector2:
	if _path_index < _path.size():
		return _path[_path_index]
	return grid.calculate_grid_coordinates(position)

# The cell the enemy is standing in right now.
func get_current_cell() -> Vector2:
	return grid.calculate_grid_coordinates(position)

# Pixels left to walk before reaching the goal. Lower = further ahead (used for "first" targeting).
func get_remaining_distance() -> float:
	if _path_index >= _path.size():
		return 0.0
	var to_next := position.distance_to(grid.calculate_map_position(_path[_path_index]))
	# Paths step one cell at a time, so every remaining step is one cell long.
	return to_next + (_path.size() - 1 - _path_index) * grid.cell_size.x
