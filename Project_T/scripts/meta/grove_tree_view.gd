extends Control
class_name GroveTreeView

# The Memory Grove's tree (meta_design.md "The Memory Grove: a tech tree", meta_assets.md): the
# Heartwood at night, from its roots up, in a 1280×960 tree space that pans and zooms (drag, wheel,
# pinch). Every Grove node is a bud on a branch (grove_layout.json): locked buds, affordable ones
# glowing, owned ones in bloom. Planting grows the branch out (frames 1→4) and opens the flower. The
# canopy fills in by the share of the tree grown, Memories hang as dream-fruit, and the five
# waystones at the roots are the perk loadout. Touch-first: everything is a tap, nothing needs hover.
# Draw order: sky, tree, canopy, branches (parents first), fruit, stones, nodes.

signal node_pressed(unlock: UnlockData)
signal fruit_pressed(index: int)
signal stones_pressed
signal background_pressed

const ART := "res://assets/meta/"
const LAYOUT_PATH := ART + "grove/grove_layout.json"
const TREE_SIZE := Vector2(1280, 960)
const NODE_FRAME := 32
const LEGENDARY_FRAME := 48
const FRUIT_FRAME := 48
const ICON := 32
const MAX_ZOOM := 3.0
const TAP_RADIUS := 22.0  # Tree px around a node, fruit or stone that counts as tapping it
const DRAG_THRESHOLD := 8.0  # Screen px before a press becomes a pan
const GROW_STEP := 0.1  # Seconds per branch / bud frame while planting
const CANOPY_FADE := 1.2
const SECTION_ROW := {"perks": 0, "families": 1, "cards": 2}
const SECTION_COLOR := {"perks": Color(1.0, 0.82, 0.4), "families": Color(0.6, 0.95, 0.55), "cards": Color(0.78, 0.62, 1.0)}

enum State { LOCKED, AVAILABLE, AFFORDABLE, OWNED }

static var _layout := {}

var zoom := 1.0
var selected_id := ""

var _memory: Dictionary = {}
var _nodes: Array = []  # Layout entries, parents before children
var _unlocks := {}  # id -> UnlockData
var _plant_started := {}  # id -> time planting began
var _fruit_opening := {}  # index -> time it began opening
var _time := 0.0
var _world := Control.new()
var _layer := Control.new()
var _canopy_back := TextureRect.new()
var _canopy_front := TextureRect.new()
var _canopy_stage := -1
var _press_pos := Vector2.ZERO
var _pressing := false
var _dragging := false
var _touches := {}  # index -> screen position (pinch)
var _pinch_distance := 0.0
var _motes: Array[Vector3] = []  # x, y, phase (dream motes drifting over the tree)
var _reduced_motion := false

var _branch_textures := {}
var _nodes_texture: Texture2D = load(ART + "grove/grove_nodes.png")
var _legendary_texture: Texture2D = load(ART + "grove/grove_legendary.png")
var _memory_nodes_texture: Texture2D = load(ART + "grove/grove_memory_nodes.png")  # Same 11 columns
var _fruit_texture: Texture2D = load(ART + "grove/dream_fruit.png")
var _sixth_rise: Texture2D = load(ART + "grove/waystone_6_rise.png")
var _sixth_idle: Texture2D = load(ART + "grove/waystone_6_idle.png")
var _sixth_rise_started := -1.0
const SIXTH_STONE := 5  # loadout_stones index of the secret 6th waystone
const SIXTH_STONE_ANCHOR := Vector2(48, 60)
const SIXTH_RISE_FPS := 12.0
const SIXTH_IDLE_FPS := 4.0
var _icons := {
	"perks": load(ART + "icons/perk_icons.png") as Texture2D,
	"families": load(ART + "icons/family_icons.png") as Texture2D,
	"cards": load(ART + "icons/card_bundle_icons.png") as Texture2D,
}

static func load_layout() -> Dictionary:
	if _layout.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT_PATH))
		if typeof(parsed) == TYPE_DICTIONARY:
			_layout = parsed
	return _layout

static func vec(value) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))

# The icon for `unlock` (its limb's 32×32 sheet), or null.
func get_icon(unlock: UnlockData) -> Texture2D:
	if unlock.memory_warden != "":  # A Memory Warden bloom: its bloomed frame (column 9) on its row
		for node in load_layout().get("nodes", []):
			if node.id == unlock.id and node.get("memory_row") != null:
				var bloom := AtlasTexture.new()
				bloom.atlas = _memory_nodes_texture
				bloom.region = Rect2(9 * NODE_FRAME, int(node.memory_row) * NODE_FRAME, NODE_FRAME, NODE_FRAME)
				return bloom
	var sheet: Texture2D = _icons.get(unlock.get_section())
	if sheet == null or unlock.icon < 0:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(unlock.icon * ICON, 0, ICON, ICON)
	return atlas

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world.size = TREE_SIZE
	add_child(_world)
	for path in ["grove/grove_sky.png", "grove/grove_tree.png"]:
		_world.add_child(_art(load(ART + path)))
	_world.add_child(_canopy_back)
	_world.add_child(_canopy_front)
	for rect in [_canopy_back, _canopy_front]:
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.size = TREE_SIZE
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.size = TREE_SIZE
	_layer.draw.connect(_draw_layer)
	_world.add_child(_layer)
	var layout := load_layout()
	_nodes = _parents_first(layout.get("nodes", []))
	for unlock in HeartwoodMemory.load_grove():
		_unlocks[unlock.id] = unlock
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 28:
		_motes.append(Vector3(rng.randf_range(80, 1200), rng.randf_range(120, 820), rng.randf() * TAU))
	resized.connect(fit)
	fit.call_deferred()

func _art(texture: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.size = TREE_SIZE
	return rect

func _parents_first(nodes: Array) -> Array:
	var result: Array = []
	var placed := {}
	var remaining := nodes.duplicate()
	while not remaining.is_empty():
		var next: Array = []
		for node in remaining:
			var parent = node.get("parent")
			if parent == null or placed.has(parent) or not nodes.any(func(n) -> bool: return n.id == parent):
				result.append(node)
				placed[node.id] = true
			else:
				next.append(node)
		if next.size() == remaining.size():
			result.append_array(next)  # A parent loop: draw them anyway
			break
		remaining = next
	return result

# New profile data: node states, fruit, stones and the canopy stage follow it.
func refresh(memory: Dictionary) -> void:
	_memory = memory
	_reduced_motion = bool(memory.get("settings", {}).get("reduced_motion", false))
	_set_canopy(canopy_stage_for(HeartwoodMemory.grown_share(memory)), _canopy_stage == -1)
	_layer.queue_redraw()

static func canopy_stage_for(share: float) -> int:
	return clampi(floori(share * 4.0), 0, 3)

func _set_canopy(stage: int, instant: bool) -> void:
	if stage == _canopy_stage:
		return
	var texture: Texture2D = load(ART + "grove/grove_canopy_%d.png" % stage)
	_canopy_back.texture = _canopy_front.texture if _canopy_front.texture else texture
	_canopy_front.texture = texture
	_canopy_stage = stage
	if instant or _reduced_motion:
		_canopy_front.modulate.a = 1.0
		return
	_canopy_front.modulate.a = 0.0
	create_tween().tween_property(_canopy_front, "modulate:a", 1.0, CANOPY_FADE)

func get_canopy_stage() -> int:
	return _canopy_stage

func state_of(unlock: UnlockData) -> State:
	if HeartwoodMemory.node_level(_memory, unlock) > 0:
		return State.OWNED
	if unlock.is_free() or not HeartwoodMemory.requirements_met(_memory, unlock):
		return State.LOCKED
	if int(_memory.seeds) >= unlock.get_cost(0):
		return State.AFFORDABLE
	return State.AVAILABLE

# Planting: the branch grows out, then the bud opens. Call after the node is bought.
func play_plant(id: String) -> void:
	_plant_started[id] = _time

func is_planting() -> bool:
	for id in _plant_started:
		if _time - _plant_started[id] < GROW_STEP * 8:
			return true
	return false

func play_fruit_open(index: int) -> void:
	_fruit_opening[index] = _time

# --- View: pan and zoom ---

func min_zoom() -> float:
	return minf(size.x / TREE_SIZE.x, size.y / TREE_SIZE.y) if size.x > 0 else 1.0

# Fits the whole tree in view.
func fit() -> void:
	zoom = min_zoom()
	_world.scale = Vector2.ONE * zoom
	_world.position = (size - TREE_SIZE * zoom) / 2.0

func zoom_by(factor: float, around: Vector2 = Vector2(-1, -1)) -> void:
	if around.x < 0:
		around = size / 2.0
	var before := to_tree(around)
	zoom = clampf(zoom * factor, min_zoom(), MAX_ZOOM)
	_world.scale = Vector2.ONE * zoom
	_world.position = around - before * zoom
	_clamp_pan()

# Centres the view on a tree point (e.g. the selected node).
func focus_on(tree_point: Vector2) -> void:
	_world.position = size / 2.0 - tree_point * zoom
	_clamp_pan()

func _clamp_pan() -> void:
	var scaled := TREE_SIZE * zoom
	for axis in 2:
		if scaled[axis] <= size[axis]:
			_world.position[axis] = (size[axis] - scaled[axis]) / 2.0
		else:
			_world.position[axis] = clampf(_world.position[axis], size[axis] - scaled[axis], 0.0)

func to_tree(screen_point: Vector2) -> Vector2:
	return (screen_point - _world.position) / zoom

func to_screen(tree_point: Vector2) -> Vector2:
	return _world.position + tree_point * zoom

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
		_pinch_distance = _touch_spread()
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _touches.size() >= 2:
			var spread := _touch_spread()
			if _pinch_distance > 0.0 and spread > 0.0:
				zoom_by(spread / _pinch_distance, _touch_centre())
			_pinch_distance = spread
			_dragging = true  # A pinch is never a tap
	elif event is InputEventMagnifyGesture:
		zoom_by(event.factor, event.position)
	elif event is InputEventPanGesture:
		_world.position -= event.delta * 8.0
		_clamp_pan()
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					zoom_by(1.1, event.position)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					zoom_by(1.0 / 1.1, event.position)
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_pressing = true
					_dragging = false
					_press_pos = event.position
				elif _pressing:
					_pressing = false
					if not _dragging and _touches.size() < 2:
						tap(to_tree(event.position))
		accept_event()
	elif event is InputEventMouseMotion and _pressing and _touches.size() < 2:
		if not _dragging and event.position.distance_to(_press_pos) > DRAG_THRESHOLD:
			_dragging = true
		if _dragging:
			_world.position += event.relative
			_clamp_pan()
		accept_event()

func _touch_spread() -> float:
	if _touches.size() < 2:
		return 0.0
	var points: Array = _touches.values()
	return (points[0] as Vector2).distance_to(points[1])

func _touch_centre() -> Vector2:
	var points: Array = _touches.values()
	return ((points[0] as Vector2) + (points[1] as Vector2)) / 2.0

# What a tap at `point` (tree space) hits: a node, a dream-fruit, the waystones, or nothing.
func tap(point: Vector2) -> void:
	var best_id := ""
	var best := TAP_RADIUS
	for node in _nodes:
		var distance := point.distance_to(vec(node.pos))
		if distance < best and _unlocks.has(node.id):
			best = distance
			best_id = node.id
	if best_id != "":
		selected_id = best_id
		_layer.queue_redraw()
		node_pressed.emit(_unlocks[best_id])
		return
	var spots: Array = load_layout().get("fruit_spots", [])
	for i in mini(fruit_count(), spots.size()):
		if point.distance_to(vec(spots[i]) + Vector2(0, FRUIT_FRAME * 0.6)) < TAP_RADIUS * 1.2:
			fruit_pressed.emit(i)
			return
	var stones: Array = load_layout().get("loadout_stones", [])
	for i in stones.size():
		if i == SIXTH_STONE and not HeartwoodMemory.has_sixth_slot(_memory):
			continue  # The secret stone gives no hint until it has risen
		if point.distance_to(vec(stones[i])) < TAP_RADIUS * 1.5:
			stones_pressed.emit()
			return
	selected_id = ""
	_layer.queue_redraw()
	background_pressed.emit()

func fruit_count() -> int:
	return HeartwoodMemory.memories_unlocked(_memory) if not _memory.is_empty() else 0

# Screen position of a node's flower (for placing its card), or the centre.
func node_screen_position(id: String) -> Vector2:
	for node in _nodes:
		if node.id == id:
			return to_screen(vec(node.pos))
	return size / 2.0

func _process(delta: float) -> void:
	_time += delta
	_layer.queue_redraw()

# --- Drawing (tree space) ---

func _draw_layer() -> void:
	if _memory.is_empty():
		return
	for node in _nodes:
		_draw_branch(node)
	_draw_fruit()
	_draw_stones()
	if not _reduced_motion:
		_draw_motes()
	var font := ThemeDB.fallback_font
	for node in _nodes:
		_draw_node(node, font)

func _branch_texture(id: String) -> Texture2D:
	if not _branch_textures.has(id):
		var path := ART + "grove/branches/%s.png" % id
		_branch_textures[id] = load(path) if ResourceLoader.exists(path) else null
	return _branch_textures[id]

func _plant_step(id: String) -> int:
	# Planting frames since it began (-1 = not planting).
	if not _plant_started.has(id):
		return -1
	var step := floori((_time - _plant_started[id]) / GROW_STEP)
	if step >= 8:
		_plant_started.erase(id)
		return -1
	return step

func _draw_branch(node: Dictionary) -> void:
	var texture := _branch_texture(node.id)
	var unlock: UnlockData = _unlocks.get(node.id)
	if texture == null or unlock == null:
		return
	var branch: Dictionary = node.branch
	var frame_size := vec(branch.frame_size)
	var frame := 0
	var step := _plant_step(node.id)
	if step >= 0:
		frame = mini(step + 1, 4)  # 1..4, then held while the bud opens
	elif state_of(unlock) == State.OWNED:
		frame = 4
	_layer.draw_texture_rect_region(texture, Rect2(vec(branch.offset), frame_size),
		Rect2(frame * frame_size.x, 0, frame_size.x, frame_size.y))

func _draw_node(node: Dictionary, font: Font) -> void:
	var unlock: UnlockData = _unlocks.get(node.id)
	if unlock == null:
		return
	var legendary := bool(node.get("legendary", false))
	var texture := _legendary_texture if legendary else _nodes_texture
	var frame_px := LEGENDARY_FRAME if legendary else NODE_FRAME
	var row := 0 if legendary else int(SECTION_ROW.get(node.section, 0))
	if node.get("memory_row") != null:  # Memory Warden blooms: their own sheet, a row per boss
		texture = _memory_nodes_texture
		row = int(node.memory_row)
	var state := state_of(unlock)
	var column := 0
	var step := _plant_step(node.id)
	if step >= 0:
		column = 5 + clampi(step - 4, 0, 3) if step >= 4 else 0  # Bud opens once the branch is out
	else:
		match state:
			State.AFFORDABLE:
				column = 1 + int(_time * 6.0) % 4
			State.OWNED:
				column = 9 + int(_time * 2.0) % 2
	var pos := vec(node.pos)
	var rect := Rect2(pos - Vector2.ONE * frame_px / 2.0, Vector2.ONE * frame_px)
	var tint := Color(1, 1, 1, 0.55) if state == State.LOCKED else Color.WHITE
	_layer.draw_texture_rect_region(texture, rect, Rect2(column * frame_px, row * frame_px, frame_px, frame_px), tint)
	if node.id == selected_id:
		var colour: Color = SECTION_COLOR.get(node.section, Color.WHITE)
		_layer.draw_arc(pos, frame_px * 0.55, 0.0, TAU, 32, colour, 1.5)
	# Level pips for perks with levels (Morning Stores I–III …).
	var levels := unlock.get_levels()
	if levels > 1:
		var owned := HeartwoodMemory.node_level(_memory, unlock)
		for i in levels:
			var dot := pos + Vector2((i - (levels - 1) / 2.0) * 6.0, frame_px * 0.5 + 3.0)
			_layer.draw_circle(dot, 2.0, Color(1.0, 0.85, 0.45) if i < owned else Color(0.25, 0.22, 0.2))
	# The next cost, under buds you could plant now or once you have the Seeds.
	if state == State.AFFORDABLE or state == State.AVAILABLE or (state == State.OWNED and HeartwoodMemory.buy_problem(_memory, unlock) in ["", "Not enough Seeds"]):
		var cost := unlock.get_cost(HeartwoodMemory.unlock_level(_memory, unlock.id))
		if cost > 0:
			var text := str(cost)
			var colour := Color(1.0, 0.92, 0.6) if int(_memory.seeds) >= cost else Color(0.7, 0.68, 0.65)
			var y := pos.y + frame_px * 0.5 + (11.0 if levels > 1 else 8.0)
			var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 8).x
			_layer.draw_string_outline(font, Vector2(pos.x - width / 2.0, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color(0.05, 0.04, 0.06, 0.9))
			_layer.draw_string(font, Vector2(pos.x - width / 2.0, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, colour)

func _draw_fruit() -> void:
	var spots: Array = load_layout().get("fruit_spots", [])
	var seen := int(_memory.get("memories_seen", 0))
	for i in mini(fruit_count(), spots.size()):
		var frame := 8 if i < seen else int(_time * 5.0 + i) % 4
		if _fruit_opening.has(i):
			var step := floori((_time - _fruit_opening[i]) / GROW_STEP)
			frame = 4 + step if step < 4 else 8
		var top := vec(spots[i])
		_layer.draw_texture_rect_region(_fruit_texture, Rect2(top - Vector2(FRUIT_FRAME / 2.0, 0), Vector2.ONE * FRUIT_FRAME),
			Rect2(frame * FRUIT_FRAME, 0, FRUIT_FRAME, FRUIT_FRAME))

# The waystones at the roots: unlocked slots glow, filled ones hold their perk's icon.
# The waystones at the roots: stones 0–4 are slots 1–5 (painted in the tree; unlocked ones glow),
# stone 5 is the secret 6th (drawn here: it rises once, then idles). Filled ones hold their perk's icon.
func _draw_stones() -> void:
	var stones: Array = load_layout().get("loadout_stones", [])
	var sixth := HeartwoodMemory.has_sixth_slot(_memory)
	var normal := HeartwoodMemory.loadout_slots(_memory) - (1 if sixth else 0)
	var carried := HeartwoodMemory.get_loadout(_memory)
	var lit: Array[int] = []  # Stone index per slot, in loadout order
	for i in mini(normal, SIXTH_STONE):
		lit.append(i)
	if sixth and stones.size() > SIXTH_STONE:
		lit.append(SIXTH_STONE)
		_draw_sixth_stone(vec(stones[SIXTH_STONE]))
	for k in lit.size():
		var i: int = lit[k]
		var centre := vec(stones[i])
		var pulse := 0.5 + 0.5 * sin(_time * 2.0 + i)
		_layer.draw_circle(centre, 16.0, Color(1.0, 0.8, 0.45, 0.10 + 0.06 * pulse))
		_layer.draw_circle(centre, 9.0, Color(1.0, 0.85, 0.5, 0.12 + 0.08 * pulse))
		if k < carried.size() and not (i == SIXTH_STONE and is_sixth_rising()):
			var icon := get_icon(_unlocks[carried[k]])
			if icon:
				_layer.draw_texture_rect(icon, Rect2(centre - Vector2(12, 26), Vector2(24, 24)), false)

# The secret 6th waystone (meta_assets.md): 24-frame rise at 12 fps played once, then a 4-frame idle
# loop; the stone's centre is at (48, 60) in its 96×96 frame.
func _draw_sixth_stone(centre: Vector2) -> void:
	var texture := _sixth_idle
	var frame := int(_time * SIXTH_IDLE_FPS) % 4
	if is_sixth_rising():
		texture = _sixth_rise
		frame = mini(int((_time - _sixth_rise_started) * SIXTH_RISE_FPS), 23)
	_layer.draw_texture_rect_region(texture, Rect2(centre - SIXTH_STONE_ANCHOR, Vector2(96, 96)),
		Rect2(frame * 96, 0, 96, 96))

func play_sixth_rise() -> void:
	_sixth_rise_started = _time

func is_sixth_rising() -> bool:
	return _sixth_rise_started >= 0.0 and _time - _sixth_rise_started < 24.0 / SIXTH_RISE_FPS

func _draw_motes() -> void:
	for mote in _motes:
		var drift := Vector2(sin(_time * 0.3 + mote.z) * 14.0, cos(_time * 0.22 + mote.z * 1.3) * 10.0)
		var alpha := 0.25 + 0.25 * sin(_time * 1.3 + mote.z * 2.0)
		_layer.draw_circle(Vector2(mote.x, mote.y) + drift, 1.2, Color(1.0, 0.9, 0.6, alpha))
