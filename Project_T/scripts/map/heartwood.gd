class_name Heartwood
extends Sprite2D

# The goal tree on the end cell (art_direction.md). It shows leaves lost: each one blackens a patch of
# canopy and dims the hollow (heartwood.png: row = leaves lost 0-20, EnvironmentTiles.FRAMES per row).
# Position it at the goal cell's centre; the sprite's bottom centre sits 8 px below the cell's bottom.
# Its warm light (the warm side of art_direction.md's warm-vs-cold) flickers and fades as leaves are lost.

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const BASE_BELOW_CELL := 8.0
const LIGHT_COLOR := Palette.GLOW
const LIGHT_ENERGY := 0.5
const LIGHT_RADIUS := 230.0  # px
# Its glow is added on top of the cold edge multiply (lights only lift what's there, and the goal sits
# in a cold corner), like the concept page's screen-blended glow.
const GLOW_ALPHA := 0.42
const GLOW_RADIUS := 230.0  # px
const LIGHT_OFFSET := Vector2(0, -16)

var run_state: RunState  # Optional: without one the tree stays whole
# Inland, the canopy overhangs the 3 cells behind it (the row above): when a Warden or nightmare is
# there, the tree fades to BEHIND_ALPHA so it stays visible (environment_assets.md "Inland Heartwood").
# Only the sprite fades (self_modulate), not its light. Taps there still pick the cell (nothing here
# takes input).
const BEHIND_ALPHA := 0.5
const FADE_RATE := 8.0
const BEHIND_CHECK_EVERY := 0.1  # s
var tower_container: Node  # Optional, for the fade
var enemy_container: Node
var _behind_check := 0.0
var _behind := false
var _warden_behind := false  # A Warden stands behind the canopy (cached)
var _frame_time := 0.0
var _light_time := 0.0
var _light: PointLight2D
var _glow: Sprite2D

func _ready() -> void:
	texture = load(EnvironmentTiles.sheet_path(EnvironmentTiles.HEARTWOOD, 1))
	if tower_container != null:  # Recheck the Wardens only when one joins or leaves
		tower_container.child_entered_tree.connect(func(_n: Node) -> void: _refresh_wardens_behind.call_deferred())
		tower_container.child_exiting_tree.connect(func(_n: Node) -> void: _refresh_wardens_behind.call_deferred())
		_refresh_wardens_behind()
	hframes = EnvironmentTiles.FRAMES
	vframes = EnvironmentTiles.HEARTWOOD_STATES
	var half_cell := EnvironmentTiles.SIZE.y / 2.0
	offset = Vector2(0, half_cell + BASE_BELOW_CELL - EnvironmentTiles.HEARTWOOD_SIZE / 2.0)
	_light = EnvironmentLighting.make_light(LIGHT_COLOR, LIGHT_ENERGY, LIGHT_RADIUS)
	_light.position = LIGHT_OFFSET
	add_child(_light)
	_glow = Sprite2D.new()
	_glow.texture = EnvironmentLighting.light_texture()
	_glow.position = LIGHT_OFFSET
	_glow.scale = Vector2.ONE * GLOW_RADIUS / (_glow.texture.get_width() / 2.0)
	_glow.modulate = Color(LIGHT_COLOR, GLOW_ALPHA)
	_glow.z_index = EnvironmentLighting.GLOW_Z
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = additive
	add_child(_glow)
	if run_state != null:
		run_state.leaves_changed.connect(_on_leaves_changed)
		_on_leaves_changed(run_state.leaves, run_state.max_leaves)

func _process(delta: float) -> void:
	_frame_time = fmod(_frame_time + delta * EnvironmentTiles.FPS, EnvironmentTiles.FRAMES)
	frame_coords.x = int(_frame_time)
	_light_time += delta
	var flicker := 1.0 + sin(_light_time * 2.3) * 0.04
	_light.scale = Vector2.ONE * flicker
	_glow.scale = Vector2.ONE * flicker * GLOW_RADIUS / (_glow.texture.get_width() / 2.0)
	_behind_check -= delta
	if _behind_check <= 0.0:
		_behind_check = BEHIND_CHECK_EVERY
		_behind = is_something_behind()
	self_modulate.a = lerpf(self_modulate.a, BEHIND_ALPHA if _behind else 1.0, 1.0 - exp(-FADE_RATE * delta))

# True when a Warden or a nightmare stands on one of the 3 cells the canopy covers (the row above).
# Wardens are cached (`_warden_behind`, refreshed when one joins or leaves the TowerContainer: plant,
# sell, a save restore; growing keeps its cells); each check only looks at the nightmares, against the
# canopy's rectangle.
func is_something_behind() -> bool:
	if _warden_behind:
		return true
	if enemy_container != null and enemy_container.has_method("get_enemies"):
		var canopy := _canopy_rect()
		for enemy: Node2D in enemy_container.get_enemies():
			if canopy.has_point(enemy.position):
				return true
	return false

# The 3 cells behind the Heartwood (the row above, one either side), in pixels.
func _canopy_rect() -> Rect2:
	var cell := Vector2(MAP_GRID.cell_size)
	var centre := MAP_GRID.calculate_map_position(MAP_GRID.calculate_grid_coordinates(position))
	return Rect2(centre - cell * Vector2(1.5, 1.5), cell * Vector2(3, 1))

func _refresh_wardens_behind() -> void:
	_warden_behind = false
	if tower_container == null:
		return
	var cell := MAP_GRID.calculate_grid_coordinates(position)
	var behind: Array[Vector2] = [cell + Vector2(-1, -1), cell + Vector2(0, -1), cell + Vector2(1, -1)]
	for tower in tower_container.get_children():
		if tower is Tower and not tower.is_queued_for_deletion() \
				and (behind.has(tower.cell) or tower.get_cells().any(func(c: Vector2) -> bool: return behind.has(c))):
			_warden_behind = true
			return

# The tree is the same warm moss-gold in every act; only its sheet's folder changes.
func set_act(act: int) -> void:
	texture = load(EnvironmentTiles.sheet_path(EnvironmentTiles.HEARTWOOD, act))

func _on_leaves_changed(leaves: int, max_leaves: int) -> void:
	var lost := 1.0 - float(leaves) / maxf(max_leaves, 1)
	var state := clampi(roundi(lost * (EnvironmentTiles.HEARTWOOD_STATES - 1)), 0, EnvironmentTiles.HEARTWOOD_STATES - 1)
	frame_coords.y = state
	var warmth := 1.0 - state / 26.0  # As on the concept page: dims, never fully dark
	_light.energy = LIGHT_ENERGY * warmth
	_glow.modulate.a = GLOW_ALPHA * warmth
