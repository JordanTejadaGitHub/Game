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
# A nightmare shrugged off a status it's immune to (throttled per nightmare; see Enemy.status_refused).
signal status_refused(enemy: Node2D, status: StringName)
# No maze juggling (run_design.md): a re-route turned a nightmare back (stacks = its Restless now),
# and one reached 3 and turned Unbound (it ignores re-routes and tramples Wardens on its route).
signal nightmare_restless(enemy: Node2D, stacks: int)
signal nightmare_unbound(enemy: Node2D)

const SPLIT_SPACING := 14.0  # Pixels between creatures that pop out of a split
const GRIEF_RING := 40.0  # Pixels from the Hollow Oak that its Grief Mourners rise
const SAPLING_REACH := 10  # Route cells ahead of the Hollow Oak it may plant beside

# Seconds left of the Moth Queen's Eclipse (every nightmare but bosses hidden unless revealed).
var eclipse_left := 0.0
# Health scale of the latest drift's (non-boss) arrivals: what boss spawns (brood, Grief) grow by,
# since bosses themselves have a fixed health scale.
var drift_health_scale := 1.0
const ROOTED_RULE := &"rooted_nightmares"
const WEATHERED_WALLS_RULE := &"weathered_walls"  # Thornwalls can't be trampled
var root_web_share := 0.0  # Root Web: touching nightmares are Held for this share of a hold
var root_web_boss_share := 0.0  # …and bosses for this share
var release_pull := 0.0  # Tangled Release: tiles pulled back when a hold ends
var caught_linger := 0.0  # Lullaby: seconds Caught lasts after leaving a Dreamcatcher
var marked_bonus := 0.0  # Bright Marks: added to Marked's extra damage taken
var overlay: NightmareOverlay  # Draws every nightmare's health bar and status badges (see NightmareOverlay)
var blight_materials := {}  # {outlined: ShaderMaterial} shared by the nightmares (Enemy._blight_material)
var thin_cards := false  # Any of the above owned (else nightmares skip their per-frame bookkeeping)
var rooted_cells := {}  # {cell: Held nightmare} (Rooted Nightmares; see _update_rooted_cells)
var waiting_cells := {}  # {cell: nightmare waiting behind a rooted one}
# Boss pools (enemy_design.md): the Night Mare galloped round again (it took `leaves`); a Warden
# withered; a lantern was lit / snuffed.
signal enemy_lapped(enemy: Node2D, leaves: int)
# A boss staying at the Heartwood took `leaves` (every Enemy.HEARTWOOD_DRAIN_EVERY s until dispelled):
# for the boss bar ("At the Heartwood"), LeakEffect, the Heartwood's tremble, Sound and the drift's leak.
signal boss_drained(enemy: Node2D, leaves: int)
signal tower_withered(tower: Node2D, by: Node2D)
signal lantern_lit(lantern: Node2D)
signal lantern_snuffed(lantern: Node2D, by_player: bool)
var _lanterns: Array[ColdLantern] = []
var _dimmed := {}  # {Tower: true} Wardens a lantern slowed last frame (reset when out of the light)
var _last_withered := {}  # {Withering Oak: Tower it withered last}
var _saplings := {}  # {Hollow Oak: [cells it planted]}
var _sapling_sprites := {}  # {cell: AnimatedSprite2D} the saplings' grow / idle / wither animation

@export var enemy_scene: PackedScene = preload("res://scenes/enemy/enemy.tscn")  # The enemy scene to spawn

# Node references
@onready var map_generator = %MapGenerator
@onready var tower_container: Node2D = %TowerContainer

func _ready() -> void:
	# Every nightmare's bars and badges, from one canvas item (never a child of this node: its
	# children are all nightmares)
	overlay = NightmareOverlay.new()
	overlay.name = "NightmareOverlay"
	overlay.spawner = self
	(owner if owner != null else get_parent()).add_child.call_deferred(overlay)
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
	if enemy_data.trait_kind == EnemyData.Trait.FLYING and not enemy_data.flies_along_route:  # Moth Queen keeps the route
		path_points = _flight_path(enemy_data.flight_weave)
	var enemy := _create(enemy_data, health_scale, modifiers, elite)
	enemy.position = enemy.grid.calculate_map_position(path_points[0])  # Start at the first waypoint (pixels)
	enemy.set_path(path_points)
	_spawn_followers(enemy, path_points)
	return enemy

func _create(enemy_data: EnemyData, health_scale: float, modifiers: Dictionary = {},
		elite: bool = false) -> Node2D:
	return _create_prepared(enemy_scene.instantiate(), enemy_data, health_scale, modifiers, elite)

# _create for an enemy already instantiated (so flags like is_echo are set before its _ready).
func _create_prepared(enemy, enemy_data: EnemyData, health_scale: float, modifiers: Dictionary = {},
		elite: bool = false) -> Node2D:
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
	enemy.status_refused.connect(status_refused.emit)
	enemy.trample_cell_requested.connect(_on_trample_cell_requested)
	enemy.lapped.connect(_on_lapped)
	enemy.heartwood_drained.connect(_on_heartwood_drained)
	enemy.bellow_requested.connect(_on_bellow_requested)
	enemy.lantern_requested.connect(_on_lantern_requested)
	enemy.wither_requested.connect(_on_wither_requested)
	enemy.echo_requested.connect(_on_echo_requested)
	add_child(enemy)
	return enemy

# A Mother Duck's Ducklings set off one after another right behind her. If she's cleansed while
# they're still walking, they get lost and slow down.
func _spawn_followers(leader: Node2D, path: PackedVector2Array) -> void:
	var data: EnemyData = leader.enemy_data
	if data.followers == null or data.follower_count <= 0:
		return
	var followers: Array[Node2D] = []
	# A boss's followers (the Huntsman's hounds) grow with the drift like its escort, not its fixed scale.
	var scale: float = drift_health_scale if data.is_boss else leader.health_scale
	for i in data.follower_count:
		var follower := _create(data.followers, scale, leader.modifiers)
		follower.position = leader.position
		follower.set_path(path)
		follower.hold_time = data.follower_spacing * (i + 1)
		followers.append(follower)
		enemy_split.emit(leader, follower)
	if data.pack_shield < 1.0:
		leader.pack.append_array(followers)  # Huntsman: they shield him while they hunt
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
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	# Thin-family cards (dream_design.md 2026-09-30), read once a frame for every nightmare.
	root_web_share = dreams.get_root_web_share(false) if dreams != null else 0.0
	root_web_boss_share = dreams.get_root_web_share(true) if dreams != null else 0.0
	release_pull = dreams.get_release_pull() if dreams != null else 0.0
	caught_linger = dreams.get_caught_linger() if dreams != null else 0.0
	marked_bonus = dreams.get_marked_bonus() if dreams != null else 0.0
	thin_cards = root_web_share > 0.0 or root_web_boss_share > 0.0 or release_pull > 0.0 \
			or caught_linger > 0.0 or marked_bonus > 0.0
	_update_rooted_cells(dreams)
	_update_lantern_light()

# Rooted Nightmares (Dream card 122): with the card, every Held maze walker blocks its cell for the
# others ({cell: nightmare}), and walkers waiting behind one block theirs so nobody stacks up. Rebuilt
# every frame before the nightmares move (they're this node's children). Empty without the card.
func _update_rooted_cells(dreams: DreamState = null) -> void:
	rooted_cells.clear()
	waiting_cells.clear()
	if dreams == null:
		dreams = get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	var rooted_rule := dreams != null and dreams.has_rule(ROOTED_RULE)
	# Also without the card: a walker Snugroot holds (Logjam, a final-form twist; FinalTwists marks it
	# FinalTwists.LOGJAM_META) blocks its cell, and the ones behind it queue (Enemy._is_blocked_ahead).
	for enemy in get_children():
		if enemy.is_cleansed or enemy.is_flying():
			continue
		if enemy.statuses.is_held():
			if rooted_rule or enemy.has_meta(FinalTwists.LOGJAM_META):
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
	_snuff_lanterns_of(enemy)
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
		child.set_path(_flight_from(child) if _flies_straight(data.split_into) else path)
		enemy_split.emit(parent, child)

# Flyers that burst out mid-maze (the Scarecrow's Crows) fly straight at the Heartwood from there.
func _flies_straight(data: EnemyData) -> bool:
	return data.trait_kind == EnemyData.Trait.FLYING and not data.flies_along_route

func _flight_from(enemy: Node2D) -> PackedVector2Array:
	return PackedVector2Array([enemy.grid.calculate_grid_coordinates(enemy.position), map_generator.endPath])

# `count` `data` lined up behind the start, walking in one after another (the Hollow Stag's bellow,
# the Night Mare's Shades).
func _run_from_start(data: EnemyData, count: int, parent: Node2D) -> void:
	var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	if data == null or count <= 0 or path.is_empty():
		return
	var first: Vector2 = parent.grid.calculate_map_position(path[0])
	var ahead: Vector2 = parent.grid.calculate_map_position(path[1]) - first if path.size() > 1 else Vector2.RIGHT
	var back := -ahead.normalized()
	for i in count:
		var child := _create(data, drift_health_scale, parent.modifiers)
		child.position = first + back * SPLIT_SPACING * (i + 1)
		child.set_path(path)
		enemy_split.emit(parent, child)

# Hollow Stag at half health: it bellows and its bellow_spawn run from the start.
func _on_bellow_requested(stag: Node2D) -> void:
	_run_from_start(stag.enemy_data.bellow_spawn, stag.enemy_data.bellow_count, stag)

# Old Stag: knocks down a Thornwall (or Bramble) next to it. The wall is gone for good, with no
# refund; opening a cell never breaks the path rule, and everyone re-routes.
func _on_trample_requested(enemy: Node2D) -> void:
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	if dreams != null and dreams.has_rule(WEATHERED_WALLS_RULE):
		return  # Weathered Walls: Thornwalls stand like any other wall
	var here: Vector2 = enemy.get_current_cell()
	for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var tower := _tower_on(here + offset)
		if tower != null and tower.tower_data.line == "wall":
			_trample_tower(tower, here + offset, enemy)
			enemy.trampled()
			return

# An Unbound nightmare walks into a Warden on its route: any Warden, trampled (Weathered Walls
# doesn't save it; nothing blocks an Unbound nightmare).
func _on_trample_cell_requested(enemy: Node2D, cell: Vector2) -> void:
	var tower := _tower_on(cell)
	if tower != null:
		_trample_tower(tower, cell, enemy)

func _tower_on(cell: Vector2) -> Tower:
	for tower in tower_container.get_children():
		if tower is Tower and not tower.is_queued_for_deletion() and tower.get_cells().has(cell):
			return tower
	return null

# The Warden is gone for good, with no refund; opening its cells never breaks the path rule, and
# everyone else re-routes.
func _trample_tower(tower: Tower, cell: Vector2, by: Node2D) -> void:
	tower_container.remove_child(tower)
	tower.queue_free()
	for c in tower.get_cells():
		map_generator.unblock_cell(c)
	wall_trampled.emit(cell, by)

# The maze changed: every enemy re-routes from the cell it's currently walking toward. One whose next
# step would take it back to the cell it just left turns around: +1 Restless (No maze juggling).
# Unbound nightmares keep their route.
func _on_path_changed() -> void:
	for enemy in get_maze_walkers():
		if enemy.is_unbound():
			continue
		var new_path: PackedVector2Array = map_generator.get_path_from(enemy.get_target_cell())
		if new_path.is_empty():
			continue
		var turned_back: bool = new_path.size() > 1 and new_path[1] == enemy.get_last_cell() \
			and enemy.get_target_cell() != enemy.get_last_cell()
		enemy.set_path(new_path)
		if turned_back:
			var became_unbound: bool = enemy.add_restless()
			nightmare_restless.emit(enemy, enemy.get_restless())
			if became_unbound:
				nightmare_unbound.emit(enemy)

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
# Huntsman: his horn calls a hound only while the pack is short (the whole pack at once when he
# regroups at half health, then never again); it runs from his cell and joins the pack.
func _on_brood_requested(queen: Node2D) -> void:
	var data: EnemyData = queen.enemy_data
	if data.pack_shield < 1.0:
		_call_pack(queen)
		return
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
		child.set_path(_flight_from(child) if _flies_straight(data.grief_spawn) else path)
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
		if walker.is_unbound():  # It won't re-route: keep its whole route clear
			for cell in walker.get_cells_ahead(1000):
				taken[cell] = true
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

# --- Boss pools (enemy_design.md, 2026-09-29) --------------------------------------------------------

# Huntsman: calls hounds until the pack is back to full (follower_count). The regroup at half health
# is the last call.
func _call_pack(huntsman: Node2D) -> void:
	var data: EnemyData = huntsman.enemy_data
	if huntsman.is_regrouped():
		if huntsman.has_meta(&"regroup_called"):
			return  # The horn fell silent after The Kill
		huntsman.set_meta(&"regroup_called", true)
	var missing: int = data.follower_count - huntsman.pack_alive()
	if missing <= 0 or data.brood == null:
		return
	var path: PackedVector2Array = map_generator.get_path_from(huntsman.get_target_cell())
	if path.is_empty():
		return
	var count := missing if huntsman.is_regrouped() else 1
	for i in count:
		var hound := _create(data.brood, drift_health_scale, huntsman.modifiers)
		hound.position = huntsman.position + Vector2.from_angle(TAU * i / maxi(count, 1)) * SPLIT_SPACING
		hound.set_path(path)
		huntsman.pack.append(hound)
		enemy_split.emit(huntsman, hound)

# Night Mare: every lap takes its lap leaves (Leaf Fall doubles them, as for any leak).
func _on_heartwood_drained(enemy: Node2D) -> void:
	var leaves := 1
	var omens := get_tree().get_first_node_in_group(OmenDirector.GROUP) as OmenDirector
	if omens:
		leaves = roundi(leaves * omens.get_leak_multiplier())  # Leaf Fall doubles it, as for any leak
	var run_state = get_node_or_null("%RunState")
	if run_state != null:
		run_state.lose_leaves(leaves)
	boss_drained.emit(enemy, leaves)

func _on_lapped(enemy: Node2D) -> void:
	var leaves: int = enemy.enemy_data.lap_leaves
	var omens := get_tree().get_first_node_in_group(OmenDirector.GROUP) as OmenDirector
	if omens:
		leaves = roundi(leaves * omens.get_leak_multiplier())
	var run_state = get_node_or_null("%RunState")
	if run_state != null:
		run_state.lose_leaves(leaves)
	enemy_lapped.emit(enemy, leaves)
	_run_from_start(enemy.enemy_data.lap_spawn, enemy.enemy_data.lap_spawn_count, enemy)  # Shades behind it

# Lamplighter: lights a cold lantern on an empty cell beside its route, near it (up to lantern_max).
func _on_lantern_requested(lamplighter: Node2D) -> void:
	var data: EnemyData = lamplighter.enemy_data
	var own := _lanterns.filter(func(l: ColdLantern) -> bool: return l.is_lit() and l.owner_boss == lamplighter)
	if own.size() >= data.lantern_max:
		return
	var taken := {}
	for lantern in _lanterns:
		taken[lantern.cell] = true
	var near: PackedVector2Array = lamplighter.get_cells_ahead(3)
	near.append_array(lamplighter.get_cells_behind().slice(-2))
	var on_route := {}  # The whole route (a maze doubles back past itself), never lit on
	for cell in lamplighter.get_cells_behind() + lamplighter.get_cells_ahead(1000):
		on_route[cell] = true
	var candidates: Array[Vector2] = []
	for cell in near:
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var beside: Vector2 = cell + offset
			if not on_route.has(beside) and not taken.has(beside) and not candidates.has(beside) \
					and map_generator.is_buildable(beside):
				candidates.append(beside)
	if candidates.is_empty():
		return
	var lantern := ColdLantern.new()
	lantern.cell = candidates.pick_random()
	lantern.radius = data.lantern_radius
	lantern.life = data.lantern_life
	lantern.snuff_dew = data.lantern_snuff_dew
	lantern.owner_boss = lamplighter
	lantern.cell_size = map_generator.MAP_GRID.cell_size.x
	lantern.position = map_generator.MAP_GRID.calculate_map_position(lantern.cell)
	lantern.snuffed.connect(_on_lantern_snuffed)
	map_generator.add_child(lantern)  # In the world, never under this node (its children are nightmares)
	_lanterns.append(lantern)
	lantern_lit.emit(lantern)

func _on_lantern_snuffed(lantern: ColdLantern, by_player: bool) -> void:
	_lanterns.erase(lantern)
	if by_player and lantern.snuff_dew > 0:
		var run_state = get_node_or_null("%RunState")
		if run_state != null:
			run_state.earn_dew_at(lantern.snuff_dew, lantern.global_position)
	lantern_snuffed.emit(lantern, by_player)

# The Lamplighter is dispelled: its lanterns go out.
func _snuff_lanterns_of(boss: Node2D) -> void:
	for lantern in _lanterns.duplicate():
		if lantern.owner_boss == boss:
			lantern.snuff(false)

# Wardens in a lantern's cold light attack slower (the strongest slow if several reach one).
func _update_lantern_light() -> void:
	if _lanterns.is_empty() and _dimmed.is_empty():
		return
	var now := {}
	for lantern in _lanterns:
		if not is_instance_valid(lantern) or not lantern.is_lit():
			continue
		var slow: float = lantern.owner_boss.enemy_data.lantern_slow if is_instance_valid(lantern.owner_boss) else 0.4
		for tower in tower_container.get_children():
			if tower is Tower and tower.global_position.distance_to(lantern.global_position) <= lantern.get_reach():
				now[tower] = minf(now.get(tower, 1.0), 1.0 - slow)
	for tower in _dimmed:
		if is_instance_valid(tower) and not now.has(tower):
			tower.dim_multiplier = 1.0
	for tower in now:
		tower.dim_multiplier = now[tower]
	_dimmed = now

# Withering Oak: roots wither the `count` strongest Wardens within reach (never the one it withered
# last time, when there's another choice) for wither_time seconds.
func _on_wither_requested(oak: Node2D, count: int) -> void:
	var data: EnemyData = oak.enemy_data
	var reach: float = data.wither_reach * map_generator.MAP_GRID.cell_size.x
	var candidates: Array = []
	for tower in tower_container.get_children():
		if tower is Tower and not tower.is_queued_for_deletion() and tower.tower_data.can_attack \
				and not tower.is_withered() and tower.global_position.distance_to(oak.global_position) <= reach:
			candidates.append(tower)
	var last = _last_withered.get(oak)
	if candidates.size() > count and last in candidates:
		candidates.erase(last)
	candidates.sort_custom(func(a: Tower, b: Tower) -> bool:
		return a.get_damage() * a.get_attacks_per_second() > b.get_damage() * b.get_attacks_per_second())
	for tower in candidates.slice(0, count):
		tower.wither(data.wither_time)
		_last_withered[oak] = tower
		tower_withered.emit(tower, oak)

# Remembering Oak: the echo of the boss this run drew for `act` rises beside it with echo_share of
# that boss's health, and walks on from the Oak's cell with its full trait.
func _on_echo_requested(oak: Node2D, act: int) -> void:
	var director := get_node_or_null("%DriftDirector") as DriftDirector
	var drawn: BossData = director.get_drawn_boss(act) if director else null
	var boss: EnemyData = drawn.boss if drawn != null else null
	if boss == null or boss.echo_at.size() > 0:
		return  # No boss drawn for that act (or it's an Oak itself)
	var path: PackedVector2Array = map_generator.get_path_from(oak.get_target_cell())
	if path.is_empty():
		return
	var scale: float = director.get_health_scale(boss, maxi(director.drifts_started, 1)) * oak.enemy_data.echo_share
	var echo = enemy_scene.instantiate()
	echo.is_echo = true
	var created := _create_prepared(echo, boss, scale)
	if boss.trait_kind == EnemyData.Trait.FLYING and not boss.flies_along_route:
		path = PackedVector2Array([oak.get_target_cell(), map_generator.endPath])
	created.position = oak.position + Vector2(GRIEF_RING, 0).rotated(TAU * act / 3.0)
	created.set_path(path)
	_spawn_followers(created, path)
	enemy_split.emit(oak, created)
