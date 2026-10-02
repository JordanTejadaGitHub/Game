class_name Heartwood
extends Sprite2D

# The goal tree on the end cell (art_direction.md). It shows leaves lost: each one blackens a patch of
# canopy and dims the hollow (heartwood_stage_N.png: row = leaves lost 0-20, EnvironmentTiles.FRAMES per
# row). Position it at the goal cell's centre; the sprite's bottom centre sits 8 px below the cell's
# bottom. Its warm light (the warm side of art_direction.md's warm-vs-cold) flickers and fades as leaves
# are lost.
# It mirrors the player's Memory Grove (meta_design.md "Carried into the run"), built once at run start:
# the canopy stage from the Grove's grown share (the Grove's own thresholds), a twinkling glint per
# planted Grove node (where the node sits on the Grove tree, coloured by its limb), and a dream-fruit
# per unlocked Memory, darkening one by one as leaves are lost. The demo keeps a young tree (stage 0, no
# glints, 3 fruit); dev runs read their preset's profile.

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

# The Grove mirror (heartwood_stages.json: per stage a crown rect, 10 fruit anchors, the lit glint pixels).
const STAGE_SHEET := "heartwood_stage_%d"
const STAGES_FILE := "heartwood_stages"
const FRUIT_SHEET := "dream_fruit"  # 12 px cells: row 0 lit (4 breathing frames), row 1 dark
const FRUIT_CELL := 12
const MAX_FRUIT := 10
const GROVE_SPACE := Vector2(1280, 960)  # grove_layout.json's tree space
const DEMO_STAGE := 0
const DEMO_FRUIT := 3
const GLINT_SIZE := 2.0  # px
const GLINT_SPACING := 4.5  # px between glints while the crown has room
# Glint colours by Grove limb; a Legendary node is a shade brighter.
const LIMB_COLOURS := {"families": Palette.SPRIG, "cards": Palette.WRAITHLIGHT, "perks": Palette.GOLD}
const LEGENDARY_COLOURS := {"families": Palette.NEWLEAF, "cards": Palette.BLOSSOM, "perks": Palette.GLOW}

var run_state: RunState  # Optional: without one the tree stays whole
# Inland, the canopy overhangs the 3 cells behind it (the row above): when a Warden or nightmare is
# there, the tree fades to BEHIND_ALPHA so it stays visible (environment_assets.md "Inland Heartwood").
# The sprite, its glints and fruit fade, not its light. Taps there still pick the cell (nothing here
# takes input).
const BEHIND_ALPHA := 0.5
const FADE_RATE := 8.0
const BEHIND_CHECK_EVERY := 0.1  # s
var tower_container: Node  # Optional, for the fade
var enemy_container: Node
var stage := 0  # Canopy stage 0-3
var planted: Array[Dictionary] = []  # HeartwoodMemory.planted_nodes(): {id, limb, pos}
var memories := 0  # Dream-fruit, 0-MAX_FRUIT
var _configured := false  # setup() ran before _ready: don't read the profile
var _act := 1
var _leaf_state := 0
var _behind_check := 0.0
var _behind := false
var _warden_behind := false  # A Warden stands behind the canopy (cached)
var _frame_time := 0.0
var _light_time := 0.0
var _light: PointLight2D
var _glow: Sprite2D
var _glints: Node2D  # Draws every glint (one canvas item)
var _glint_points: Array = []  # [local position, colour, twinkle speed, phase]
var _fruit: Node2D
var _fruit_sprites: Array[Sprite2D] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # For the canopy fade; _process skips the rest while paused
	if not _configured:
		_load_profile()
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
	_glints = Node2D.new()
	_glints.name = "Glints"
	_glints.draw.connect(_draw_glints)
	add_child(_glints)
	_fruit = Node2D.new()
	_fruit.name = "Fruit"
	add_child(_fruit)
	_build()
	if run_state != null:
		run_state.leaves_changed.connect(_on_leaves_changed)
		_on_leaves_changed(run_state.leaves, run_state.max_leaves)

# From the player's Grove; the demo keeps a fixed young tree.
func _load_profile() -> void:
	var demo := ResultsScreen.is_demo()
	var tree := tree_from({} if demo else HeartwoodMemory.load_data(), demo)
	stage = tree.stage
	planted = tree.planted
	memories = tree.memories

# The tree a profile grows: {stage (the Grove's thresholds on grown_share), planted, memories}.
static func tree_from(data: Dictionary, demo: bool) -> Dictionary:
	if demo:
		var none: Array[Dictionary] = []
		return {"stage": DEMO_STAGE, "planted": none, "memories": DEMO_FRUIT}
	return {"stage": GroveTreeView.canopy_stage_for(HeartwoodMemory.grown_share(data)),
		"planted": HeartwoodMemory.planted_nodes(data),
		"memories": clampi(HeartwoodMemory.memories_unlocked(data), 0, MAX_FRUIT)}

# Sets the tree directly (tests; before _ready it replaces the profile, after it rebuilds).
func setup(new_stage: int, new_planted: Array[Dictionary], new_memories: int) -> void:
	stage = clampi(new_stage, 0, 3)
	planted = new_planted
	memories = clampi(new_memories, 0, MAX_FRUIT)
	_configured = true
	if is_inside_tree() and _glints != null:
		_build()

func _process(delta: float) -> void:
	_update_fade(delta)
	if get_tree().paused:
		return  # The tree and its light rest with the world
	_frame_time = fmod(_frame_time + delta * EnvironmentTiles.FPS, EnvironmentTiles.FRAMES)
	if int(_frame_time) != frame_coords.x:
		frame_coords.x = int(_frame_time)
		_update_fruit()  # The fruit breathe with the tree's frames
	_light_time += delta
	var flicker := 1.0 + sin(_light_time * 2.3) * 0.04
	_light.scale = Vector2.ONE * flicker
	_glow.scale = Vector2.ONE * flicker * GLOW_RADIUS / (_glow.texture.get_width() / 2.0)
	if not _glint_points.is_empty() and not _reduced_motion():
		_glints.queue_redraw()  # The twinkle: the only per-frame work

# The canopy fade runs while paused too (process_mode ALWAYS): Wardens are planted and sold while paused.
func _update_fade(delta: float) -> void:
	_behind_check -= delta
	if _behind_check <= 0.0:
		_behind_check = BEHIND_CHECK_EVERY
		_behind = is_something_behind()
	self_modulate.a = lerpf(self_modulate.a, BEHIND_ALPHA if _behind else 1.0, 1.0 - exp(-FADE_RATE * delta))
	_glints.modulate.a = self_modulate.a  # Every layer fades with the canopy
	_fruit.modulate.a = self_modulate.a

# --- The Grove mirror -----------------------------------------------------------------------------

func _build() -> void:
	texture = load(EnvironmentTiles.sheet_path(STAGE_SHEET % stage, _act))
	var info := _stage_info(stage)
	_build_glints(info)
	_build_fruit(info)
	_glints.queue_redraw()

# One stage's entry from heartwood_stages.json ({crown, fruit, glints} in 128 px frame pixels).
func _stage_info(which: int) -> Dictionary:
	var path := EnvironmentTiles.sheet_path(STAGES_FILE, _act).get_basename() + ".json"
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	for entry: Dictionary in parsed.get("stages", []):
		if int(entry.get("stage", -1)) == which:
			return entry
	return {}

# A pixel of the 128×128 frame, in this node's local space.
func _frame_to_local(pixel: Vector2) -> Vector2:
	return offset + pixel - Vector2.ONE * EnvironmentTiles.HEARTWOOD_SIZE / 2.0

# Each planted node at its spot on the Grove tree, mapped onto this stage's crown and snapped to the
# nearest lit crown pixel still free.
func _build_glints(info: Dictionary) -> void:
	_glint_points.clear()
	var crown: Array = info.get("crown", [0, 0, 0, 0])
	var free: Array = info.get("glints", []).duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242  # Twinkle speeds and phases: the same every run
	var crowded: Array = []  # Lit pixels beside a taken glint: used only once no spaced one is left
	for node: Dictionary in planted:
		if free.is_empty():
			free = crowded
			crowded = []
		if free.is_empty():
			break
		var t: Vector2 = (node.pos as Vector2) / GROVE_SPACE
		var target := Vector2(lerpf(crown[0], crown[2], t.x), lerpf(crown[1], crown[3], t.y))
		var best := 0
		for i in free.size():
			if Vector2(free[i][0], free[i][1]).distance_squared_to(target) \
					< Vector2(free[best][0], free[best][1]).distance_squared_to(target):
				best = i
		var pixel := Vector2(free[best][0], free[best][1])
		free.remove_at(best)
		for i in range(free.size() - 1, -1, -1):  # Keep glints apart so a dense limb doesn't smear
			if Vector2(free[i][0], free[i][1]).distance_to(pixel) < GLINT_SPACING:
				crowded.append(free[i])
				free.remove_at(i)
		var limb := str(node.limb)
		var unlock: UnlockData = HeartwoodMemory.get_unlock(str(node.id))
		var colours: Dictionary = LEGENDARY_COLOURS if unlock != null and unlock.legendary else LIMB_COLOURS
		_glint_points.append([_frame_to_local(pixel), colours.get(limb, Palette.GLOW),
			rng.randf_range(0.5, 1.1), rng.randf() * TAU])

func _draw_glints() -> void:
	var warmth := 1.0 - _leaf_state / 20.0  # Dim with leaves lost (the rot blackens the crown anyway)
	var still := _reduced_motion()
	for glint: Array in _glint_points:
		var twinkle := 0.85 if still else 0.35 + 0.65 * pow(maxf(0.0, sin(_light_time * glint[2] + glint[3])), 2.0)
		_glints.draw_rect(Rect2(glint[0], Vector2.ONE * GLINT_SIZE), Color(glint[1], twinkle * warmth))

func _build_fruit(info: Dictionary) -> void:
	for sprite in _fruit_sprites:
		sprite.queue_free()
	_fruit_sprites.clear()
	var anchors: Array = info.get("fruit", [])
	var sheet: Texture2D = load(EnvironmentTiles.sheet_path(FRUIT_SHEET, _act))
	for i in mini(memories, anchors.size()):
		var sprite := Sprite2D.new()
		sprite.texture = sheet
		sprite.region_enabled = true
		sprite.position = _frame_to_local(Vector2(anchors[i][0], anchors[i][1]))
		_fruit.add_child(sprite)
		_fruit_sprites.append(sprite)
	_update_fruit()

# Lit fruit breathe; as leaves are lost they darken one by one, the last-grown first.
func _update_fruit() -> void:
	var dark := ceili(_fruit_sprites.size() * _leaf_state / 20.0)
	for i in _fruit_sprites.size():
		var row := 1 if i >= _fruit_sprites.size() - dark else 0
		var frame := 0 if row == 1 else int(_frame_time)
		_fruit_sprites[i].region_rect = Rect2(frame * FRUIT_CELL, row * FRUIT_CELL, FRUIT_CELL, FRUIT_CELL)

func get_glint_count() -> int:
	return _glint_points.size()

func get_fruit_count() -> int:
	return _fruit_sprites.size()

func get_dark_fruit_count() -> int:
	return _fruit_sprites.filter(func(s: Sprite2D) -> bool: return s.region_rect.position.y > 0).size()

static func _reduced_motion() -> bool:
	return bool(Fx.setting("reduced_motion", false))

# --- The canopy fade ------------------------------------------------------------------------------

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

# --- Season and leaves ----------------------------------------------------------------------------

# The tree keeps its warm moss-gold in every act; only its sheets' folder changes.
func set_act(act: int) -> void:
	_act = act
	texture = load(EnvironmentTiles.sheet_path(STAGE_SHEET % stage, act))
	var sheet: Texture2D = load(EnvironmentTiles.sheet_path(FRUIT_SHEET, act))
	for sprite in _fruit_sprites:
		sprite.texture = sheet

func _on_leaves_changed(leaves: int, max_leaves: int) -> void:
	var lost := 1.0 - float(leaves) / maxf(max_leaves, 1)
	var state := clampi(roundi(lost * (EnvironmentTiles.HEARTWOOD_STATES - 1)), 0, EnvironmentTiles.HEARTWOOD_STATES - 1)
	_leaf_state = state
	frame_coords.y = state
	var warmth := 1.0 - state / 26.0  # As on the concept page: dims, never fully dark
	_light.energy = LIGHT_ENERGY * warmth
	_glow.modulate.a = GLOW_ALPHA * warmth
	_update_fruit()
	_glints.queue_redraw()
