extends Node2D
class_name Tower

# A Warden. Plays its idle loop, and when a creature is in range winds up its attack animation and
# releases on the release frame: a projectile (optionally splashing), a pulse around itself, chain
# lightning, or a lingering cloud on the path. Hits soothe and apply the Warden's status.
# Stats go through DreamState (group "dream_state") so Dreams can modify them.

signal evolved(tower: Tower)

@export var tower_data: TowerData
@onready var sprite: Sprite2D = $Sprite2D

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const ENEMY_GROUP := "enemies"
const SPORE_POTENCY := 0.25  # Spored soothes this share of the Warden's soothe per second per stack
const CHAIN_DAMP_EXTRA_JUMPS := 2
const CHAIN_DAMP_EXTRA_RANGE := 1.0  # Cells

# The grid cell this tower occupies (set by TowerPlacer).
var cell: Vector2
# All Dew put into this Warden (build cost, evolutions). Selling refunds a share of it.
var invested_dew := 0

var _cooldown := 0.0  # Seconds until the tower can attack again
var _anim_time := 0.0
var _attack_time := -1.0  # Seconds into the attack animation; negative while idling
var _attack_fps := 0.0
var _released := false  # The current attack's shot / pulse has happened
var _attack_count := 0  # For "every Nth attack" effects (Thunderhead)
var _dream_state: DreamState

func _ready() -> void:
	_dream_state = get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	_apply_data()
	# Start each tower at a random point in its idle loop so neighbours don't breathe in sync.
	_anim_time = randf() * tower_data.frame_count / tower_data.animation_fps

func _apply_data() -> void:
	_attack_time = -1.0
	_show_idle()
	queue_redraw()

# Grows into `data` in place (the cell and path don't change). `cost` is added to invested Dew.
func evolve(data: TowerData, cost: int) -> void:
	tower_data = data
	invested_dew += cost
	_apply_data()
	evolved.emit(self)

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


# --- Effective stats (base × Dreams) ----------------------------------------------------------------

func get_damage() -> float:
	return tower_data.damage * (_dream_state.get_soothe_multiplier(self) if _dream_state else 1.0)

func get_attacks_per_second() -> float:
	return tower_data.attacks_per_second * (_dream_state.get_attack_speed_multiplier(tower_data) if _dream_state else 1.0)

func get_range_cells() -> float:
	return get_range_for(tower_data, _dream_state)

func get_splash_cells() -> float:
	return tower_data.splash_radius * (_dream_state.get_splash_multiplier(tower_data) if _dream_state else 1.0)

# Range in cells for `data` including Dreams (shared with the build ghost).
static func get_range_for(data: TowerData, dream_state: DreamState) -> float:
	return data.attack_range + (dream_state.get_range_bonus(data) if dream_state else 0.0)


# --- Attacking ----------------------------------------------------------------------------------------

# Winds up the attack animation; the shot / pulse happens on its release frame.
func _start_attack() -> void:
	_cooldown = 1.0 / get_attacks_per_second()
	if tower_data.attack_texture == null:
		_release()
		return
	# Play the attack faster if it wouldn't finish before the next one is due.
	_attack_fps = maxf(tower_data.attack_animation_fps, tower_data.attack_frame_count * get_attacks_per_second())
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

# The attack lands. A target that left range during the wind-up wastes a projectile/chain/cloud.
func _release() -> void:
	_attack_count += 1
	match tower_data.attack_kind:
		TowerData.AttackKind.PULSE:
			for enemy in get_enemies_in_range():
				hit(enemy, 1.0, true)
		TowerData.AttackKind.CHAIN:
			var target := find_target()
			if target != null:
				_chain_strike(target)
		TowerData.AttackKind.CLOUD:
			var target := find_target()
			if target != null:
				_drop_cloud(target)
		_:
			var target := find_target()
			if target != null:
				fire_at(target)

# Soothes `enemy` and applies this Warden's status. `is_area`: splash, pulse and cloud hits (creatures
# with an attack-shape resistance, like the Bee Swarm, take these differently). The creature's
# family resistance or weakness to this Warden's line is applied in Enemy.take_damage.
func hit(enemy: Node2D, soothe_multiplier: float = 1.0, is_area: bool = false) -> void:
	if not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	var soothe := get_damage() * soothe_multiplier
	enemy.take_damage(soothe, tower_data.line, is_area)
	apply_status_to(enemy, soothe)

func apply_status_to(enemy: Node2D, soothe: float) -> void:
	var status := tower_data.applies_status
	if status == &"" or not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	var potency := soothe
	if status == EnemyStatuses.SPORED:
		potency = soothe * SPORE_POTENCY
	var duration := tower_data.status_duration
	if _dream_state:
		potency *= _dream_state.get_status_strength_multiplier(status)
		duration = _dream_state.get_status_duration(tower_data, status)
	enemy.apply_status(status, tower_data.status_stacks, duration, potency, tower_data.status_max_stacks, tower_data.line)

# Projectile landed at `where` (on `target` if it's still there): soothe it, or everything in the
# splash radius.
func projectile_landed(target: Node2D, where: Vector2) -> void:
	var splash := get_splash_cells() * MAP_GRID.cell_size.x
	if splash <= 0.0:
		hit(target)
		return
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if enemy.global_position.distance_to(where) <= splash:
			hit(enemy, 1.0, true)

func fire_at(target: Node2D) -> void:
	var projectile := Projectile.new(target, tower_data, projectile_landed)
	add_child(projectile)
	projectile.global_position = global_position + tower_data.get_attack_origin()

# Lightning: jumps from creature to creature (further between Damp ones). Thunderhead's every Nth
# strike and the Conductive Soil Dream also hit every Damp creature in range.
func _chain_strike(first: Node2D) -> void:
	var hits: Array[Node2D] = [first]
	var max_hits := tower_data.chain_targets
	if first.statuses.has(EnemyStatuses.DAMP):
		max_hits += CHAIN_DAMP_EXTRA_JUMPS
	while hits.size() < max_hits:
		var next := _nearest_jump(hits)
		if next == null:
			break
		hits.append(next)

	var storm := tower_data.storm_every > 0 and _attack_count % tower_data.storm_every == 0
	if storm or (_dream_state and _dream_state.has_rule(&"conductive_soil")):
		for enemy in get_enemies_in_range():
			if enemy.statuses.has(EnemyStatuses.DAMP) and not hits.has(enemy):
				hits.append(enemy)

	var points := PackedVector2Array([global_position + tower_data.get_attack_origin()])
	for enemy in hits:
		points.append(enemy.global_position)
		hit(enemy)
	var bolt := ChainBolt.new(points)
	add_child(bolt)

# The unstruck creature closest to any creature already struck, within jump range (longer between
# two Damp creatures). Lightning spreads through a group rather than running off in one direction.
func _nearest_jump(struck: Array[Node2D]) -> Node2D:
	var best: Node2D = null
	var best_distance := INF
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if struck.has(enemy):
			continue
		for from in struck:
			var reach := tower_data.chain_jump_range
			if from.statuses.has(EnemyStatuses.DAMP) and enemy.statuses.has(EnemyStatuses.DAMP):
				reach += CHAIN_DAMP_EXTRA_RANGE
			var distance := from.global_position.distance_to(enemy.global_position)
			if distance <= reach * MAP_GRID.cell_size.x and distance < best_distance:
				best_distance = distance
				best = enemy
	return best

# A lingering cloud on the path tile the target is walking through.
func _drop_cloud(target: Node2D) -> void:
	var center: Vector2 = MAP_GRID.calculate_map_position(target.get_current_cell())
	var cloud := PathCloud.new(self, center)
	add_child(cloud)

func _draw() -> void:
	if tower_data.texture == null:
		draw_placeholder(self, tower_data.placeholder_color)

# Attack reach in pixels.
func get_range_pixels() -> float:
	return range_to_pixels(get_range_cells())

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

# Converts a range in cells to pixels. Shared with the build-mode ghost preview.
static func range_to_pixels(range_cells: float) -> float:
	return range_cells * MAP_GRID.cell_size.x

# Draws a simple stone block centred on the origin. Shared with the build-mode ghost preview.
static func draw_placeholder(canvas: CanvasItem, color: Color) -> void:
	var block := Rect2(-24, -24, 48, 48)
	canvas.draw_rect(block, color.darkened(0.45))
	canvas.draw_rect(block.grow(-4), color)
	canvas.draw_circle(Vector2.ZERO, 10, color.lightened(0.35))
