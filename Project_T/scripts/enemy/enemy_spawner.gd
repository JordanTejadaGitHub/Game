extends Node2D

# Spawns creatures and re-emits their signals, so listeners (RunState, DriftDirector) don't track
# individual enemies. When a creature that splits is cleansed, `enemy_split` fires for each child
# BEFORE `enemy_cleansed` fires for the parent, so drift bookkeeping never sees an empty drift early.
# Followers (a Mother Duck's Ducklings) are announced through `enemy_split` too: any creature that
# comes from another belongs to the same drift.
signal enemy_cleansed(enemy: Node2D)
signal enemy_reached_goal(enemy: Node2D)
signal enemy_split(parent: Node2D, child: Node2D)
# The Old Stag knocked a Thornwall down (it's gone for good; the path re-routes).
signal wall_trampled(cell: Vector2, by: Node2D)

const SPLIT_SPACING := 14.0  # Pixels between creatures that pop out of a split
const GRIEF_RING := 40.0  # Pixels from the Hollow Oak that its Grief Mourners rise
const SAPLING_REACH := 10  # Route cells ahead of the Hollow Oak it may plant beside

# Seconds left of the Moth Queen's Eclipse (every nightmare but bosses hidden unless revealed).
var eclipse_left := 0.0
# Health scale of the latest drift's (non-boss) arrivals: what boss spawns (brood, Grief) grow by,
# since bosses themselves have a fixed health scale.
var drift_health_scale := 1.0
const ROOTED_RULE := &"rooted_nightmares"
var rooted_cells := {}  # {cell: Held nightmare} (Rooted Nightmares; see _update_rooted_cells)
var waiting_cells := {}  # {cell: nightmare waiting behind a rooted one}
var _saplings := {}  # {Hollow Oak: [cells it planted]}
var _sapling_sprites := {}  # {cell: AnimatedSprite2D} the saplings' grow / idle / wither animation

@export var enemy_scene: PackedScene = preload("res://scenes/enemy/enemy.tscn")  # The enemy scene to spawn

# Node references
@onready var map_generator = %MapGenerator
@onready var tower_container: Node2D = %TowerContainer

func _ready() -> void:
	map_generator.path_changed.connect(_on_path_changed)
	map_generator.obstacle_cleared.connect(func(cell: Vector2, _data: ObstacleData) -> void: _wither_sprite(cell))

# Spawns a creature at the start of the maze. Returns it, or null if there's no route.
# `modifiers`: Omen multipliers for the creature (see Enemy.modifiers). `elite`: Deeply Blighted.
# Flyers float straight at the Heartwood; a Mother Duck brings her Ducklings in single file.
func spawn_enemy(enemy_data: EnemyData, health_scale: float = 1.0, modifiers: Dictionary = {},
		elite: bool = false) -> Node2D:
	var path_points: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	if path_points.is_empty():
		return null
	if not enemy_data.is_boss:
		drift_health_scale = health_scale
	if enemy_data.trait_kind == EnemyData.Trait.FLYING:
		path_points = _flight_path(enemy_data.flight_weave)
	var enemy := _create(enemy_data, health_scale, modifiers, elite)
	enemy.position = enemy.grid.calculate_map_position(path_points[0])  # Start at the first waypoint (pixels)
	enemy.set_path(path_points)
	_spawn_followers(enemy, path_points)
	return enemy

func _create(enemy_data: EnemyData, health_scale: float, modifiers: Dictionary = {},
		elite: bool = false) -> Node2D:
	var enemy = enemy_scene.instantiate()
	enemy.enemy_data = enemy_data
	enemy.health_scale = health_scale
	enemy.modifiers = modifiers
	enemy.elite = elite
	enemy.cleansed.connect(_on_enemy_cleansed)
	enemy.reached_goal.connect(_on_enemy_reached_goal)
	enemy.trample_requested.connect(_on_trample_requested)
	enemy.brood_requested.connect(_on_brood_requested)
	enemy.eclipse_started.connect(func(_by: Node2D, seconds: float) -> void: eclipse_left = maxf(eclipse_left, seconds))
	enemy.sapling_requested.connect(_on_sapling_requested)
	enemy.grief_requested.connect(_on_grief_requested)
	add_child(enemy)
	return enemy

# A Mother Duck's Ducklings set off one after another right behind her. If she's cleansed while
# they're still walking, they get lost and slow down.
func _spawn_followers(leader: Node2D, path: PackedVector2Array) -> void:
	var data: EnemyData = leader.enemy_data
	if data.followers == null or data.follower_count <= 0:
		return
	var followers: Array[Node2D] = []
	for i in data.follower_count:
		var follower := _create(data.followers, leader.health_scale, leader.modifiers)
		follower.position = leader.position
		follower.set_path(path)
		follower.hold_time = data.follower_spacing * (i + 1)
		followers.append(follower)
		enemy_split.emit(leader, follower)
	leader.cleansed.connect(func(_leader: Node2D) -> void:
		for follower in followers:
			if is_instance_valid(follower):
				follower.set_lost())

# Enemies still walking the maze. Cleansing enemies are excluded: they don't block building or re-route.
func get_enemies() -> Array[Node]:
	var enemies: Array[Node] = []
	for enemy in get_children():
		if not enemy.is_cleansed:
			enemies.append(enemy)
	return enemies

# Walking creatures that follow the maze (flyers float over it): these are the ones building must
# never cut off, and the ones that re-route.
func get_maze_walkers() -> Array[Node]:
	return get_enemies().filter(func(enemy: Node) -> bool: return not enemy.is_flying())

func _process(delta: float) -> void:
	eclipse_left = maxf(eclipse_left - delta, 0.0)
	_update_rooted_cells()

# Rooted Nightmares (Dream card 122): with the card, every Held maze walker blocks its cell for the
# others ({cell: nightmare}), and walkers waiting behind one block theirs so nobody stacks up. Rebuilt
# every frame before the nightmares move (they're this node's children). Empty without the card.
func _update_rooted_cells() -> void:
	rooted_cells.clear()
	waiting_cells.clear()
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	if dreams == null or not dreams.has_rule(ROOTED_RULE):
		return
	for enemy in get_maze_walkers():
		if enemy.statuses.is_held():
			rooted_cells[enemy.get_current_cell()] = enemy
		elif enemy.waiting:
			waiting_cells[enemy.get_current_cell()] = enemy

# A route from `from` to the Heartwood that avoids every rooted cell (except `from` itself), without
# changing the map. Empty if the Held nightmares close every way (then the walker waits).
func route_around(from: Vector2) -> PackedVector2Array:
	var closed: Array[Vector2] = []
	for cell: Vector2 in rooted_cells:
		if cell != from and not map_generator.path_layer.is_cell_blocked(cell):
			map_generator.path_layer.set_cell_blocked(cell, true)
			closed.append(cell)
	var route: PackedVector2Array = map_generator.get_path_from(from)
	for cell in closed:
		map_generator.path_layer.set_cell_blocked(cell, false)
	return route

func _on_enemy_cleansed(enemy: Node2D) -> void:
	_wither_saplings(enemy)
	_split(enemy)
	enemy_cleansed.emit(enemy)

# Pops `split_count` `split_into` creatures out where `parent` was, lined up behind it on its route.
func _split(parent: Node2D) -> void:
	var data: EnemyData = parent.enemy_data
	if data.split_into == null or data.split_count <= 0:
		return
	var path: PackedVector2Array = map_generator.get_path_from(parent.get_target_cell())
	if path.is_empty():
		return
	var ahead: Vector2 = parent.grid.calculate_map_position(path[0]) - parent.position
	var back := -ahead.normalized() if not ahead.is_zero_approx() else Vector2.ZERO
	for i in data.split_count:
		var child := _create(data.split_into, parent.health_scale, parent.modifiers)
		child.position = parent.position + back * SPLIT_SPACING * i
		child.set_path(path)
		enemy_split.emit(parent, child)

# Old Stag: knocks down a Thornwall (or Bramble) next to it. The wall is gone for good, with no
# refund; opening a cell never breaks the path rule, and everyone re-routes.
func _on_trample_requested(enemy: Node2D) -> void:
	var here: Vector2 = enemy.get_current_cell()
	for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var cell: Vector2 = here + offset
		for tower in tower_container.get_children():
			if tower is Tower and tower.cell == cell and tower.tower_data.line == "wall" \
					and not tower.is_queued_for_deletion():
				tower_container.remove_child(tower)
				tower.queue_free()
				map_generator.unblock_cell(cell)
				enemy.trampled()
				wall_trampled.emit(cell, enemy)
				return

# The maze changed: every enemy re-routes from the cell it's currently walking toward.
func _on_path_changed() -> void:
	for enemy in get_maze_walkers():
		var new_path: PackedVector2Array = map_generator.get_path_from(enemy.get_target_cell())
		if not new_path.is_empty():
			enemy.set_path(new_path)

# Dream Thief: takes steals_dew Dew (as much as there is) on its way in, then the leaf is lost as usual.
func _on_enemy_reached_goal(enemy: Node2D) -> void:
	var run_state = get_node_or_null("%RunState")
	if enemy.enemy_data.steals_dew > 0 and run_state != null:
		var stolen: int = mini(enemy.enemy_data.steals_dew, run_state.dew)
		if stolen > 0:
			run_state.spend_dew(stolen)
	enemy_reached_goal.emit(enemy)

# A flyer's line from the forest's edge to the Heartwood (grid coordinates), weaving up to weave
# cells either side (the Moth Queen), gently at the ends so it still starts and ends on target.
func _flight_path(weave: float) -> PackedVector2Array:
	var from: Vector2 = map_generator.startPath
	var to: Vector2 = map_generator.endPath
	if weave <= 0.0:
		return PackedVector2Array([from, to])
	var across := (to - from).orthogonal().normalized()
	var steps := maxi(ceili(from.distance_to(to) / 2.0), 2)
	var points := PackedVector2Array()
	for i in steps + 1:
		var t := float(i) / steps
		var point := from.lerp(to, t) + across * sin(t * TAU * 1.5) * weave * sin(t * PI)
		var bounds: Vector2 = Vector2(map_generator.MAP_GRID.size) - Vector2.ONE
		points.append(point.clamp(Vector2.ZERO, bounds))
	return points

# Moth Queen: a brood nightmare lands on the route cell nearest her and walks the maze from there.
func _on_brood_requested(queen: Node2D) -> void:
	var route: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	if route.is_empty():
		return
	var nearest := 0
	for i in route.size():
		if queen.grid.calculate_map_position(route[i]).distance_squared_to(queen.position) \
				< queen.grid.calculate_map_position(route[nearest]).distance_squared_to(queen.position):
			nearest = i
	var path := route.slice(nearest)
	var child := _create(queen.enemy_data.brood, drift_health_scale)
	child.position = child.grid.calculate_map_position(path[0])
	child.set_path(path)
	enemy_split.emit(queen, child)

# Hollow Oak Grief: grief_count nightmares rise in a ring around it and walk on from its cell.
func _on_grief_requested(oak: Node2D) -> void:
	var data: EnemyData = oak.enemy_data
	var path: PackedVector2Array = map_generator.get_path_from(oak.get_target_cell())
	if data.grief_spawn == null or path.is_empty():
		return
	for i in data.grief_count:
		var child := _create(data.grief_spawn, drift_health_scale)
		child.position = oak.position + Vector2.from_angle(TAU * i / data.grief_count) * GRIEF_RING
		child.set_path(path)
		enemy_split.emit(oak, child)

# Hollow Oak: plants a thorn-sapling on an empty cell beside its route ahead. Never on a Warden, the
# start / end or a nightmare, and never where it would cut anyone off (the path rule).
func _on_sapling_requested(oak: Node2D) -> void:
	var walkers := get_maze_walkers()
	var taken := {}
	var also_from := PackedVector2Array()
	for walker in walkers:
		taken[walker.get_current_cell()] = true
		taken[walker.get_target_cell()] = true
		also_from.append(walker.get_target_cell())
	var ahead: PackedVector2Array = oak.get_cells_ahead(SAPLING_REACH)
	var on_route := {}
	for cell in ahead:
		on_route[cell] = true
	var candidates: Array[Vector2] = []
	for cell in ahead:
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var beside: Vector2 = cell + offset
			if not on_route.has(beside) and not taken.has(beside) and not candidates.has(beside) \
					and map_generator.is_buildable(beside):
				candidates.append(beside)
	candidates.shuffle()
	for cell in candidates:
		if map_generator.can_block(cell, also_from):
			map_generator.place_obstacle(cell, oak.enemy_data.sapling)
			_saplings.get_or_add(oak, []).append(cell)
			_grow_sprite(cell, oak.enemy_data.sapling_frames)
			return

# The Hollow Oak is dispelled: the saplings it planted (and the player hasn't cleared) crumble.
func _wither_saplings(oak: Node2D) -> void:
	if not _saplings.has(oak):
		return
	for cell: Vector2 in _saplings[oak]:
		if map_generator.get_obstacle(cell) == oak.enemy_data.sapling:
			map_generator.remove_obstacle(cell)
			_wither_sprite(cell)
	_saplings.erase(oak)
# A sapling springs up on cell ("grow", then "idle"). Drawn on the map, under the nightmares.
func _grow_sprite(cell: Vector2, frames: SpriteFrames) -> void:
	if frames == null:
		return
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.position = map_generator.MAP_GRID.calculate_map_position(cell)
	map_generator.add_child(sprite)
	sprite.animation_finished.connect(func() -> void:
		if sprite.animation == &"grow":
			sprite.play(&"idle"))
	sprite.play(&"grow")
	_sapling_sprites[cell] = sprite

# The sapling on cell crumbles to ash ("wither"), then goes (the Oak fell, or the player cleared it).
func _wither_sprite(cell: Vector2) -> void:
	var sprite: AnimatedSprite2D = _sapling_sprites.get(cell)
	if sprite == null:
		return
	_sapling_sprites.erase(cell)
	if not is_instance_valid(sprite):
		return
	sprite.animation_finished.connect(sprite.queue_free)
	sprite.play(&"wither")