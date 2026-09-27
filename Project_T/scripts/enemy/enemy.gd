extends Node2D

# Emitted when the enemy walks off the end of its path (reaches the goal), right before it's freed.
signal reached_goal(enemy: Node2D)
# Emitted when health hits 0 (the nightmare is dispelled). It stops being a target and plays its
# dispel effect.
signal cleansed(enemy: Node2D)
# TRAMPLE (The Hollow Stag): wants to knock down a Thornwall next to it. The spawner calls
# `trampled()` back if it did.
signal trample_requested(enemy: Node2D)
# LEAP (The Mire Hag) rose at her new position.
signal leaped(enemy: Node2D)
# Boss abilities the spawner carries out (acts_3_4.md): the Moth Queen drops a brood nightmare and
# starts the Eclipse; the Hollow Oak plants a thorn-sapling and grieves (Mourners rise around it).
signal brood_requested(enemy: Node2D)
signal eclipse_started(enemy: Node2D, seconds: float)
signal sapling_requested(enemy: Node2D)
signal grief_requested(enemy: Node2D)
# The Hollow Oak (Blight Level 10) rose again at half health instead of being dispelled.
signal rose_again(enemy: Node2D)

# Deeply Blighted elites (acts_1_2.md): ×3 health, ×3 Dew, 2 leaves, 20% bigger, wrapped in a slow
# haze with a swirl mark by the health bar (not darkened: the nightmare art is already dark).
const ELITE_HEALTH := 3.0
const ELITE_DEW := 3
const ELITE_LEAVES := 2
const ELITE_SCALE := 1.2
const ELITE_HAZE_PUFFS := 6
const ELITE_HAZE_SPEED := 0.6  # Radians per second the haze drifts round
const ELITE_HAZE_COLOR := Color(0.1, 0.08, 0.14, 0.32)
const ELITE_HAZE_RIM := Color(0.62, 0.58, 0.72, 0.16)  # Keeps the haze visible on dark ground
const ELITE_SWIRL_COLOR := Color(0.78, 0.7, 0.95)
const LEAP_TIME := 0.45  # Seconds to sink, move under the mire and rise again

# Group of nightmares that are still walking and targetable. Dispelled ones leave it.
const GROUP := "enemies"
const BLIGHT_SHADER := preload("res://shaders/blight.gdshader")
const HEALTH_BAR_SIZE := Vector2(40, 5)
const HEALTH_BAR_OFFSET := Vector2(0, -38)  # Bar centre, relative to the enemy's origin
# Dispel: shriek, crack with light, burst, then the motes drift up (about 1.2 s in all).
const SHRIEK_TIME := 0.12
const CRACK_TIME := 0.25
const BURST_TIME := 0.12
const MOTE_LIFETIME := 0.7
const MOTE_COLOR := Color(1.0, 0.92, 0.62)

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
const STATUS_FLASH_TIME := 0.3  # A status icon flashes when a combo uses it (see flash_status)
const COAT_COLOR := Color(0.62, 0.6, 0.66)
const CRIT_FLASH_TIME := 0.3  # Gold starburst after a critical hit
const CRIT_COLOR := Color(1.0, 0.82, 0.3)

var _crit_flash := 0.0
# Extra Dew when dispelled (Magpie Perch: +1 once it's been hit by a magpie).
var bonus_dew := 0
# Seconds before this nightmare can be frozen (Frostfern) / pushed back (Whirligig) again.
var freeze_cooldown := 0.0
var push_cooldown := 0.0
# Test Grove's Target Dummy: never drops below 1 health, and walks the route again instead of
# reaching the Heartwood.
var unkillable := false
var loops_route := false
# The last few damage events (DamageLog.Event) for Inspect.
var recent_hits: Array = []
const RECENT_HITS := 6

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
var _haze_phase := 0.0
var _status_flash := {}  # {status id: seconds left} for icons a combo just used
var hold_time := 0.0  # Seconds to stand still before setting off (Wraiths in single file)
var rolling := false  # Night Hound sprinting down a straight
var lost := false  # Wraith whose Lantern Bearer was dispelled first
var _straight_steps := 0
var _last_step := Vector2.ZERO
var _trait_timer := 0.0
var _trampled := 0
var _startled := false
var _charge_left := 0.0
var _leaping := false  # Sinking / underground / rising (Mire Hag, Gravecrawler): not walking
var _leap_tween: Tween
var _burrows := 0
var _wander_cooldown := 0

# Presence (acts_3_4.md): hiding, revealing, waking, mending, the ash trail and boss timers, checked
# every PRESENCE_TICK seconds rather than every frame.
const PRESENCE_TICK := 0.1
const CLOSE_REVEAL_CELLS := 1.5  # Any Warden this close sees a hidden nightmare
const HIDDEN_ALPHA := 0.22
const ALWAYS_DAMP_TIME := 3600.0
const ASH_COLOR := Color(1.0, 0.45, 0.15, 0.5)
const DIRECTIONS: Array[Vector2] = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
var _hidden := false
var _presence_elapsed := 0.0
var _ash_cells := {}  # {cell: seconds the ash still burns}
var _heal_carry := 0.0
var _brood_timer := 0.0
var _sapling_timer := 0.0
var _sapling_speed := 1.0
var _eclipsed := false
var _griefs := 0  # grief_at thresholds already passed
var _has_risen := false

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
	statuses.ignores_slows = enemy_data.ignores_slows
	statuses.immune = enemy_data.status_immune
	statuses.duration_multipliers = enemy_data.status_duration_multipliers
	statuses.duration_multiplier_all = modifiers.get("status_duration", 1.0)
	coat_max = enemy_data.coat_total * health_scale * modifiers.get("coat", 1.0)
	coat = coat_max
	_coat_per_hit = enemy_data.coat_per_hit * health_scale * modifiers.get("coat", 1.0)

	# Set up animations
	sprite.sprite_frames = enemy_data.sprite_frames
	sprite.scale = Vector2.ONE * enemy_data.sprite_scale * (ELITE_SCALE if elite else 1.0)
	sprite.modulate = enemy_data.tint
	sprite.play("walk_side")

	# Nightmare look: per-enemy material so each one can crack apart on its own
	var blight_material := ShaderMaterial.new()
	blight_material.shader = BLIGHT_SHADER
	sprite.material = blight_material

	if enemy_data.always_damp:
		statuses.apply(EnemyStatuses.DAMP, 1, ALWAYS_DAMP_TIME)
	if enemy_data.hidden:
		_set_hidden(true)  # Revealed on the first presence tick if something sees it

func _process(delta: float) -> void:
	if is_cleansed or _path_index >= _path.size():
		return

	var spore_soothe := statuses.tick(delta)
	if spore_soothe > 0.0:
		take_damage(spore_soothe, statuses.spore_line(), true, false, statuses.source(EnemyStatuses.SPORED),
			&"spored")
		if is_cleansed:
			return
	_bolt_flash = maxf(_bolt_flash - delta, 0.0)
	if elite:
		_haze_phase += ELITE_HAZE_SPEED * delta
	_hit_mark_time = maxf(_hit_mark_time - delta, 0.0)
	for id: StringName in _status_flash.keys():
		_status_flash[id] -= delta
		if _status_flash[id] <= 0.0:
			_status_flash.erase(id)
	_crit_flash = maxf(_crit_flash - delta, 0.0)
	freeze_cooldown = maxf(freeze_cooldown - delta, 0.0)
	push_cooldown = maxf(push_cooldown - delta, 0.0)
	if not statuses.active_ids().is_empty() or _bolt_flash > 0.0 or _hit_mark_time > 0.0 or elite \
			or _crit_flash > 0.0 or statuses.is_in_stag_aura() or not _ash_cells.is_empty():
		queue_redraw()
	_update_presence(delta)

	if hold_time > 0.0:
		hold_time -= delta
		return
	if statuses.is_held():
		return  # Frozen / rooted in place
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
			if _leaping:
				return  # Started burrowing: the tween moves it now
		else:
			position += to_target / distance * remaining
			remaining = 0.0

	# Update animation based on movement direction
	update_animation(position - previous_position)

	if _path_index >= _path.size():
		if loops_route:
			_restart_route()
			return
		reached_goal.emit(self)
		queue_free()

# A combo just used this status (e.g. lightning jumped through Damp): its icon flashes briefly.
# Called by the HUD's combat callouts. Does nothing if the status isn't on this nightmare.
func flash_status(id: StringName) -> void:
	if statuses.active_ids().has(id):
		_status_flash[id] = STATUS_FLASH_TIME
		queue_redraw()

# Target Dummy: back to the forest's edge to walk the maze again.
func _restart_route() -> void:
	var map_generator = get_parent().get("map_generator")  # The EnemyContainer's
	var start: Vector2 = _path[0] if map_generator == null else map_generator.startPath
	var route: PackedVector2Array = _path if map_generator == null else map_generator.get_path_from(start)
	position = grid.calculate_map_position(start)
	set_path(route)

func _draw() -> void:
	if is_cleansed:
		return
	for cell: Vector2 in _ash_cells:  # Ash Crawler: embers on the cells it just crossed
		var t: float = _ash_cells[cell] / enemy_data.ash_trail_time
		var at := to_local(grid.calculate_map_position(cell))
		for i in 3:
			draw_circle(at + Vector2(-10 + 10 * i, 6 - 5 * (i % 2)), 2.0 + 1.5 * t, Color(ASH_COLOR, ASH_COLOR.a * t))
	if _hidden:
		return  # Only the faint sprite shows: no bars, no status icons
	if elite:
		_draw_elite_haze()  # Drawn before the sprite (a child), so it sits behind it
	if _bolt_flash > 0.0:
		var t := _bolt_flash / BOLT_FLASH_TIME
		draw_circle(Vector2.ZERO, 26.0 * (1.5 - t), Color(1.0, 1.0, 0.6, 0.5 * t))
	if _hit_mark_time > 0.0:
		_draw_hit_mark(_hit_mark_time / HIT_MARK_TIME)
	if _crit_flash > 0.0:
		_draw_crit_flare(_crit_flash / CRIT_FLASH_TIME)
	if statuses.is_in_stag_aura():
		draw_arc(Vector2(0, 6), 18.0, 0.0, TAU, 24, Color(0.9, 0.95, 1.0, 0.35), 2.0)
	# One coloured dot per status, just above where the health bar sits
	var ids := statuses.active_ids()
	var x := -(ids.size() - 1) * STATUS_DOT_RADIUS * 1.5
	for id in ids:
		var dot := HEALTH_BAR_OFFSET + Vector2(x, -8)
		draw_circle(dot, STATUS_DOT_RADIUS + 1, Color(0.1, 0.1, 0.12, 0.8))
		draw_circle(dot, STATUS_DOT_RADIUS, EnemyStatuses.COLORS[id])
		if _status_flash.has(id):
			var f: float = _status_flash[id] / STATUS_FLASH_TIME  # 1 -> 0
			draw_circle(dot, STATUS_DOT_RADIUS, Color(1, 1, 1, 0.7 * f))
			draw_arc(dot, STATUS_DOT_RADIUS + 1.0 + 4.0 * (1.0 - f), 0.0, TAU, 12, Color(EnemyStatuses.COLORS[id], f), 1.5)
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

# Deeply Blighted: soft puffs drifting slowly round the nightmare, and a swirl left of the health bar.
func _draw_elite_haze() -> void:
	var r := 18.0 * sprite.scale.x
	for i in ELITE_HAZE_PUFFS:
		var a := _haze_phase + TAU * i / ELITE_HAZE_PUFFS
		var at := Vector2(cos(a) * r, sin(a) * r * 0.5 - 8.0)  # Flattened ring round the body
		var size := (9.0 + 3.0 * sin(_haze_phase * 1.7 + i)) * sprite.scale.x
		draw_circle(at, size + 2.0, ELITE_HAZE_RIM)
		draw_circle(at, size, ELITE_HAZE_COLOR)
	var centre := HEALTH_BAR_OFFSET + Vector2(-HEALTH_BAR_SIZE.x / 2 - 8.0, 0)
	var swirl := PackedVector2Array()
	for s in 14:
		var t := s / 13.0
		swirl.append(centre + Vector2.from_angle(t * TAU * 1.6 + _haze_phase) * (1.0 + 4.0 * t))
	draw_circle(centre, 6.0, Color(0.1, 0.1, 0.12, 0.8))
	draw_polyline(swirl, ELITE_SWIRL_COLOR, 1.5)

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

# A critical hit: a bright gold starburst. `t` fades 1 -> 0.
func _draw_crit_flare(t: float) -> void:
	var r := 22.0 * (1.3 - t * 0.5)
	for i in 8:
		var dir := Vector2.from_angle(TAU * i / 8.0 + 0.2)
		var length := r if i % 2 == 0 else r * 0.6
		draw_line(dir * 6.0, dir * length, Color(CRIT_COLOR, t), 3.0 if i % 2 == 0 else 2.0)
	draw_circle(Vector2.ZERO, 8.0 * t, Color(1.0, 0.97, 0.8, 0.8 * t))

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

# Dew for dispelling this nightmare (Omens can change it, e.g. Dry Spell = 0).
func get_dew_reward() -> int:
	return roundi(enemy_data.dew_reward * modifiers.get("dew", 1.0)) * (ELITE_DEW if elite else 1) + bonus_dew

# Leaves lost when this nightmare reaches the Heartwood (Deeply Blighted cost at least 2).
func get_leaf_cost() -> int:
	return maxi(enemy_data.leaf_cost, ELITE_LEAVES) if elite else enemy_data.leaf_cost

func is_flying() -> bool:
	return enemy_data.trait_kind == EnemyData.Trait.FLYING

# Pixels per second right now: base speed, sprinting / lost / charging, then slows.
func get_move_speed() -> float:
	var base := speed
	if rolling:
		base = enemy_data.roll_speed * modifiers.get("speed", 1.0)
	elif lost:
		base = minf(base, enemy_data.lost_speed)
	if _charge_left > 0.0:
		base *= enemy_data.charge_speed_multiplier
	return base * statuses.get_speed_multiplier()

# A Wraith whose Lantern Bearer was dispelled first loses the way and slows down.
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
	if enemy_data.ash_trail_time > 0.0:
		_ash_cells[get_current_cell()] = enemy_data.ash_trail_time
	match enemy_data.trait_kind:
		EnemyData.Trait.ROLLING:
			_update_rolling()
		EnemyData.Trait.BURROW:
			_try_burrow()
		EnemyData.Trait.WANDER:
			_try_wander()

# Night Hound: sprints once it has gone `roll_after_tiles` in a straight line.
func _update_rolling() -> void:
	if _path_index < 1:
		return
	var step := _path[_path_index - 1] - (_path[_path_index - 2] if _path_index >= 2 else get_current_cell())
	_straight_steps = _straight_steps + 1 if step == _last_step else 1
	_last_step = step
	# Keeps rolling only while the next step goes the same way; stops at the turn.
	var next_same := _path_index < _path.size() and _path[_path_index] - _path[_path_index - 1] == step
	rolling = _straight_steps >= enemy_data.roll_after_tiles and next_same

# Mire Hag: sinks into the mire and rises `leap_tiles` ahead along her path, then makes nightmares
# near where she rose Damp.
func _leap() -> void:
	if _path_index >= _path.size():
		return
	var landing_index := mini(_path_index + enemy_data.leap_tiles - 1, _path.size() - 1)
	var landing := grid.calculate_map_position(_path[landing_index])
	_sink_and_rise(landing, func() -> void:
		_path_index = landing_index + 1
		var reach := enemy_data.leap_splash_radius * grid.cell_size.x
		for creature in get_tree().get_nodes_in_group(GROUP):
			if creature.global_position.distance_to(global_position) <= reach:
				creature.apply_status(EnemyStatuses.DAMP)
		leaped.emit(self)
		if _path_index >= _path.size():
			reached_goal.emit(self)
			queue_free())

# Squashes flat into the ground and fades, moves to `landing` (pixels) while under, rises the same
# way back up, then calls `on_risen`. Not walking meanwhile (Mire Hag, Gravecrawler).
func _sink_and_rise(landing: Vector2, on_risen: Callable) -> void:
	_leaping = true
	var base_scale := sprite.scale
	var sunk_scale := Vector2(base_scale.x * 1.3, base_scale.y * 0.1)
	var tween := create_tween()
	_leap_tween = tween
	tween.tween_property(sprite, "scale", sunk_scale, LEAP_TIME * 0.4).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "position:y", 10.0, LEAP_TIME * 0.4).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, LEAP_TIME * 0.4)
	tween.tween_property(self, "position", landing, LEAP_TIME * 0.2)
	tween.tween_property(sprite, "scale", base_scale, LEAP_TIME * 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(sprite, "position:y", 0.0, LEAP_TIME * 0.4).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate:a", 1.0, LEAP_TIME * 0.4)
	tween.tween_callback(func() -> void:
		_leaping = false
		on_risen.call())

# Gravecrawler: if a Warden or wall is right beside it and the cell past it leads to the Heartwood by
# a route at least `burrow_min_saving` cells shorter, it sinks under and surfaces there.
func _try_burrow() -> void:
	var map_generator = _map_generator()
	if _burrows >= enemy_data.burrow_max or _path_index >= _path.size() or map_generator == null:
		return
	var walls := _tower_cells()
	var here := get_current_cell()
	var best_route := PackedVector2Array()
	var best_length := _path.size() - _path_index - enemy_data.burrow_min_saving  # Cells to beat
	for direction in DIRECTIONS:
		var beyond := here + direction * 2
		if not walls.has(here + direction) or not _is_walkable(beyond, map_generator):
			continue
		var route: PackedVector2Array = map_generator.get_path_from(beyond)
		if not route.is_empty() and route.size() + 1 <= best_length:  # +1: the tunnel under the wall
			best_route = route
			best_length = route.size() + 1
	if best_route.is_empty():
		return
	_burrows += 1
	var surface := grid.calculate_map_position(best_route[0])
	_sink_and_rise(surface, func() -> void: set_path(best_route))

# Sleepwalker: sometimes steps into a dead-end pocket beside it, walks to the end and comes back.
func _try_wander() -> void:
	if _wander_cooldown > 0:
		_wander_cooldown -= 1
		return
	var map_generator = _map_generator()
	if map_generator == null or _path_index >= _path.size() or randf() >= enemy_data.wander_chance:
		return
	var here := get_current_cell()
	var pocket := _find_dead_end(here, map_generator)
	if pocket.is_empty():
		return
	var detour := pocket.duplicate()
	for i in range(pocket.size() - 2, -1, -1):
		detour.append(pocket[i])
	detour.append(here)
	detour.append_array(_path.slice(_path_index))
	set_path(detour)
	_wander_cooldown = enemy_data.wander_cooldown_cells

# Cells of a dead-end pocket starting next to `here` (off the route, one way in, at most
# `wander_depth` deep), from the entrance to the end. Empty if there's none.
func _find_dead_end(here: Vector2, map_generator: Node) -> PackedVector2Array:
	var on_route := {}
	for cell in _path:
		on_route[cell] = true
	var starts := DIRECTIONS.duplicate()
	starts.shuffle()
	for direction: Vector2 in starts:
		var cells := PackedVector2Array([here + direction])
		if on_route.has(cells[0]) or not _is_walkable(cells[0], map_generator):
			continue
		var visited := {here: true, cells[0]: true}
		while cells.size() <= enemy_data.wander_depth:
			var onward: Array[Vector2] = []
			for step in DIRECTIONS:
				var next: Vector2 = cells[cells.size() - 1] + step
				if not visited.has(next) and not on_route.has(next) and _is_walkable(next, map_generator):
					onward.append(next)
			if onward.is_empty():
				return cells  # The end of the pocket
			if onward.size() > 1:
				break  # It opens up: not a dead end
			visited[onward[0]] = true
			cells.append(onward[0])
	return PackedVector2Array()

func _is_walkable(cell: Vector2, map_generator: Node) -> bool:
	return grid.is_within_bounds(cell) and not map_generator.path_layer.is_cell_blocked(cell)

# The map (through the EnemyContainer), or null outside the main scene.
func _map_generator() -> Node:
	return get_parent().get("map_generator") if get_parent() else null

# Cells with a Warden or wall on them.
func _tower_cells() -> Dictionary:
	var cells := {}
	var towers = get_parent().get("tower_container") if get_parent() else null
	if towers:
		for tower in towers.get_children():
			if tower is Tower:
				cells[tower.cell] = true
	return cells


# --- Presence (acts_3_4.md) ---------------------------------------------------------------------

# True while the nightmare can't be seen or targeted (Lurker in fog, the Moth Queen's Eclipse).
func is_hidden() -> bool:
	return _hidden

func _update_presence(delta: float) -> void:
	if enemy_data.always_damp and not statuses.has(EnemyStatuses.DAMP):
		statuses.apply(EnemyStatuses.DAMP, 1, ALWAYS_DAMP_TIME)
	for cell: Vector2 in _ash_cells.keys():
		_ash_cells[cell] -= delta
		if _ash_cells[cell] <= 0.0:
			_ash_cells.erase(cell)
	_presence_elapsed += delta
	if _presence_elapsed < PRESENCE_TICK:
		return
	var elapsed := _presence_elapsed
	_presence_elapsed = 0.0

	var hide := (enemy_data.hidden or _is_eclipsed()) and not _is_revealed()
	if hide != _hidden:
		_set_hidden(hide)
	if enemy_data.wake_radius > 0.0:  # Watcher
		for other in _others_within(enemy_data.wake_radius):
			if other.statuses.has(EnemyStatuses.DROWSY):
				other.statuses.remove(EnemyStatuses.DROWSY)
				other.queue_redraw()
	if enemy_data.mend_radius > 0.0:  # Weeper
		for other in _others_within(enemy_data.mend_radius):
			other.heal(other.max_health * enemy_data.mend_rate * elapsed)
	if not _ash_cells.is_empty():  # Ash Crawler
		for other in _field():
			if other != self and other.statuses.has(EnemyStatuses.SPORED) and _ash_cells.has(other.get_current_cell()):
				other.statuses.remove(EnemyStatuses.SPORED)
				other.queue_redraw()
	if enemy_data.brood != null:  # Moth Queen
		_brood_timer += elapsed
		if _brood_timer >= enemy_data.brood_interval:
			_brood_timer = 0.0
			brood_requested.emit(self)
	if enemy_data.sapling != null:  # Hollow Oak
		_sapling_timer += elapsed * _sapling_speed
		if _sapling_timer >= enemy_data.sapling_interval:
			_sapling_timer = 0.0
			sapling_requested.emit(self)

func _set_hidden(value: bool) -> void:
	_hidden = value
	if value:
		remove_from_group(GROUP)
	else:
		add_to_group(GROUP)
	sprite.self_modulate.a = HIDDEN_ALPHA if value else 1.0
	queue_redraw()

# The Moth Queen's Eclipse hides every nightmare but bosses.
func _is_eclipsed() -> bool:
	return not enemy_data.is_boss and get_parent() != null and get_parent().get("eclipse_left") != null \
		and get_parent().eclipse_left > 0.0

# Seen by a Warden within CLOSE_REVEAL_CELLS, a Marking Warden (Lanternmoth, Moon Moth, Rootlight)
# that has it in range, or a Will-o'-Wisp's glow.
func _is_revealed() -> bool:
	var towers = get_parent().get("tower_container") if get_parent() else null
	if towers:
		for tower in towers.get_children():
			if not tower is Tower or tower.attack_data == null:
				continue
			var distance := global_position.distance_to(tower.global_position)
			if distance <= CLOSE_REVEAL_CELLS * grid.cell_size.x:
				return true
			if tower.attack_data.applies_status == EnemyStatuses.MARKED and distance <= tower.get_range_pixels():
				return true
	for other in _field():
		if other != self and other.enemy_data.reveal_radius > 0.0 and not other.is_hidden() \
				and global_position.distance_to(other.global_position) <= other.enemy_data.reveal_radius * grid.cell_size.x:
			return true
	return false

# Every nightmare still on the field, hidden or not.
func _field() -> Array:
	var parent := get_parent()
	return parent.get_enemies() if parent and parent.has_method("get_enemies") else get_tree().get_nodes_in_group(GROUP)

func _others_within(cells: float) -> Array:
	var reach := cells * grid.cell_size.x
	return _field().filter(func(other: Node2D) -> bool:
		return other != self and global_position.distance_to(other.global_position) <= reach)

# Weeper's mending: restores up to `amount` health (fractions add up over time).
func heal(amount: float) -> void:
	if is_cleansed or health >= max_health:
		return
	_heal_carry += amount
	var whole := int(_heal_carry)
	_heal_carry -= whole
	health = mini(health + whole, max_health)
	queue_redraw()

# Boss moments that happen at a share of health: the Moth Queen's Eclipse, the Hollow Oak's Grief.
func _check_health_thresholds() -> void:
	if enemy_data.eclipse_time > 0.0 and not _eclipsed and health <= max_health / 2:
		_eclipsed = true
		eclipse_started.emit(self, enemy_data.eclipse_time)
	while _griefs < enemy_data.grief_at.size() and health <= max_health * enemy_data.grief_at[_griefs]:
		_griefs += 1
		hold_time = maxf(hold_time, enemy_data.grief_pause)  # It stops and wails
		grief_requested.emit(self)

# Blight Level `rises_from_blight`+ (the Hollow Oak remembers): the first dispel doesn't take; it
# rises again at half health with saplings twice as fast. True if it rose.
func _try_rise() -> bool:
	if _has_risen or enemy_data.rises_from_blight <= 0 or MetaRun.blight_level < enemy_data.rises_from_blight:
		return false
	_has_risen = true
	health = max_health / 2
	_sapling_speed = 2.0
	var tween := create_tween()
	tween.tween_method(_set_crack, 0.0, 0.7, CRACK_TIME)
	tween.tween_method(_set_crack, 0.7, 0.0, CRACK_TIME * 2)
	rose_again.emit(self)
	return true

# Soothes the blight away. `line` is the Warden family that soothed it ("" = neutral) and `is_area`
# whether it was an area hit (splash, pulse, cloud, Spored). Soothe = amount × family × shape ×
# Marked, then the blight coat takes its bite. At 0 health the enemy is cleansed.
# `source` (the Warden) and `tag` (&"spored" tick, &"static" bolt, &"conducted" lightning through
# Damp) feed the DamageLog; crit/weak/Marked/fog combos are worked out here.
func take_damage(amount: float, line: String = "", is_area: bool = false, is_crit: bool = false,
		source: Node = null, tag: StringName = &"") -> void:
	if is_cleansed:
		return
	if is_crit:
		_crit_flash = CRIT_FLASH_TIME
	var family := enemy_data.get_soothe_multiplier(line, is_area)
	var taken := statuses.get_damage_taken_multiplier()
	var soothe := amount * family * taken
	var soothe_before_coat := soothe
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
	health = maxi(health - whole, 1 if unkillable else 0)
	queue_redraw()
	_report_damage(amount, family, taken, soothe_before_coat - soothe, soothe, line, is_crit, source, tag)
	if health == 0 and not _try_rise():
		_cleanse()
		return
	_check_health_thresholds()
	if enemy_data.trait_kind == EnemyData.Trait.TRAMPLE and not _startled and health <= max_health / 2:
		_startled = true  # The Hollow Stag's antlers flare and it charges
		_charge_left = enemy_data.charge_time

# Applies a status from a Warden (`potency` = its soothe, see EnemyStatuses). A Static charge that
# fills up sets off a free bolt right away.
func apply_status(id: StringName, stacks: int = 1, duration: float = 0.0, potency: float = 0.0,
		max_stacks: int = 0, line: String = "", source: Node = null) -> void:
	if is_cleansed:
		return
	var bolt := statuses.apply(id, stacks, duration, potency, max_stacks, line, source)
	queue_redraw()
	if bolt > 0.0:
		_bolt_flash = BOLT_FLASH_TIME
		take_damage(bolt, "light", false, false, source, &"static")  # Static bolts count as light

# Tells the DamageLog what this hit did, with the combos that boosted it (see DamageLog).
func _report_damage(amount: float, family: float, taken: float, soaked: float, dealt: float, line: String,
		is_crit: bool, source: Node, tag: StringName) -> void:
	var damage_log := DamageLog.instance
	if damage_log == null:
		return
	var event := DamageLog.Event.new()
	event.source = source
	event.enemy = self
	event.kind = &"status" if tag == &"spored" else (&"bolt" if tag == &"static" else (&"pop" if tag == &"popped" else &"hit"))
	event.amount = dealt
	event.base = amount
	event.family_multiplier = family
	event.taken_multiplier = taken
	event.coat_soaked = soaked
	var factor := 1.0  # Multiplicative combos
	if is_crit and source is Tower:
		event.crit_multiplier = source.attack_data.crit_multiplier
		event.combos.append(&"crit")
		factor *= event.crit_multiplier
	if line in enemy_data.weak_to:
		event.combos.append(&"weak")
		factor *= EnemyData.WEAK_MULTIPLIER
	if statuses.has(EnemyStatuses.MARKED):
		event.combos.append(&"marked")
		factor *= taken / (taken - EnemyStatuses.MARKED_EXTRA)
	if tag == &"spored" and statuses.is_in_fog():
		event.combos.append(&"fog")
		factor *= 1.0 + EnemyStatuses.FOG_SPORE_BONUS
	if tag == &"conducted" or tag == &"static" or tag == &"popped":
		event.combos.append(tag)
		event.combo_amount = dealt  # The whole hit only happened thanks to the combo
	else:
		event.combo_amount = dealt * (1.0 - 1.0 / factor)
	recent_hits.append(event)
	if recent_hits.size() > RECENT_HITS:
		recent_hits.pop_front()
	damage_log.report(event)

# Removes the nightmare as if dispelled (Test Grove's "clear the field").
func dispel() -> void:
	if is_cleansed:
		return
	unkillable = false
	health = 0
	_cleanse()

func _mark_hit(kind: int) -> void:
	_hit_mark = kind
	_hit_mark_time = HIT_MARK_TIME

# Dispelled (story.md): a short shriek, the shape cracks with light, then bursts into motes that
# drift up (the Dew popup rises with them). It no longer blocks building or re-routes. Code keeps
# the old "cleanse" names; players only ever see "dispel".
func _cleanse() -> void:
	is_cleansed = true
	remove_from_group(GROUP)
	cleansed.emit(self)
	queue_redraw()
	sprite.self_modulate.a = 1.0  # A hidden nightmare shows itself as it cracks apart

	if _leap_tween:
		_leap_tween.kill()  # Dispelled mid-sink: surface right here to crack apart
		sprite.modulate.a = 1.0
		sprite.position.y = 0.0
	var base_scale := Vector2.ONE * enemy_data.sprite_scale * (ELITE_SCALE if elite else 1.0)
	sprite.scale = base_scale
	_shriek()
	var tween := create_tween()
	tween.tween_interval(SHRIEK_TIME)
	tween.tween_method(_set_crack, 0.0, 1.0, CRACK_TIME).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "scale", base_scale * 1.12, CRACK_TIME)
	tween.tween_callback(_burst_into_motes)
	tween.tween_property(sprite, "scale", base_scale * 1.35, BURST_TIME).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, BURST_TIME)
	tween.tween_interval(MOTE_LIFETIME)
	tween.tween_callback(queue_free)

# Hook for the dispel shriek / hiss sound (none yet). Visually: a quick, violent shudder.
func _shriek() -> void:
	var tween := create_tween()
	for i in 4:
		tween.tween_property(sprite, "position:x", 2.5 if i % 2 == 0 else -2.5, SHRIEK_TIME / 5)
	tween.tween_property(sprite, "position:x", 0.0, SHRIEK_TIME / 5)

# The motes of light a dispelled nightmare breaks into. Bigger nightmares make more.
func _burst_into_motes() -> void:
	var motes := CPUParticles2D.new()
	motes.one_shot = true
	motes.explosiveness = 0.9
	motes.amount = roundi(14 * maxf(sprite.scale.x, 1.0))
	motes.lifetime = MOTE_LIFETIME
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	motes.emission_sphere_radius = 12.0 * sprite.scale.x
	motes.direction = Vector2.UP
	motes.spread = 180.0
	motes.initial_velocity_min = 30.0
	motes.initial_velocity_max = 75.0
	motes.gravity = Vector2(0, -70)  # Motes drift up
	motes.damping_min = 40.0
	motes.damping_max = 60.0
	motes.scale_amount_min = 2.0
	motes.scale_amount_max = 3.5
	var fade := Gradient.new()
	fade.set_color(0, MOTE_COLOR)
	fade.set_color(1, Color(MOTE_COLOR, 0.0))
	motes.color_ramp = fade
	add_child(motes)
	motes.emitting = true

# 0 = whole, 1 = cracked through with light (see shaders/blight.gdshader).
func _set_crack(amount: float) -> void:
	(sprite.material as ShaderMaterial).set_shader_parameter("crack", amount)


# Sets the cells to walk through (grid coordinates). The enemy heads to points[0] first.
func set_path(points: PackedVector2Array) -> void:
	_path = points
	_path_index = 0

# Moves the nightmare back along the way it came by `pixels` (Whirligig gusts, Pond Keeper). It can't
# go back past the start of its current route (routes restart at each re-route). Returns the pixels
# actually moved.
func push_back(pixels: float) -> float:
	if is_cleansed or _leaping or _path.is_empty():
		return 0.0
	var moved := 0.0
	while pixels > 0.0 and _path_index > 0:
		var previous := grid.calculate_map_position(_path[_path_index - 1])
		var distance := position.distance_to(previous)
		if distance > pixels:
			position = position.move_toward(previous, pixels)
			return moved + pixels
		position = previous
		moved += distance
		pixels -= distance
		_path_index -= 1  # Now walking back toward the cell it just stood on
	return moved

# Index into the current route of the cell the nightmare last stood on (or is standing on).
func get_route_index() -> int:
	return maxi(_path_index - 1, 0)

# The next `count` route cells the nightmare will walk through (Hollow Oak plants beside these).
func get_cells_ahead(count: int) -> PackedVector2Array:
	return _path.slice(_path_index, _path_index + count)

# Route cells behind the nightmare (the ones it already walked through on this route), oldest first.
func get_cells_behind() -> PackedVector2Array:
	return _path.slice(0, maxi(_path_index, 0))

# Sends the nightmare back to route cell `index` (must be behind it). Pond Keeper's grab.
func pull_back_to(index: int) -> void:
	if is_cleansed or _leaping or index < 0 or index >= _path_index:
		return
	position = grid.calculate_map_position(_path[index])
	_path_index = index + 1
	queue_redraw()

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
