class_name MapGifts
extends Node2D

# Heartwood's Gifts, the terrain (heartwood_gifts.md; numbers spire_difficulty.md Phase 3). Made by MapGenerator
# (`map_generator.gifts`). Main's HeartwoodGifts runs the offer, the placement (GiftPlacer checks the cells and
# the route) and the save; the effects registered here (register_effects, from _ready) change the map. On a resumed run the
# map is regenerated from its seed and HeartwoodGifts calls each effect again in order (placement["restoring"]):
# the tended cells are restored before that call, the Wardens after it. Tower Code's GiftGround keeps the
# Warden-side marks and bonuses for the living-ground gifts; this draws their terrain and blocks their cells.
#
# Drawn here (ground overlays: bog, roots, the mushroom ring, stumps; z -1 over the path) and by `GiftProp`
# children of MapGenerator (logs, the Moonwell, the Bell Stone, the Lightning Tree: y-sorted with the trees).
# Art from assets/environment/<act>/ (Environment Assets); a placeholder in palette colours while a sheet is missing.

signal gifts_changed  # Terrain or ground changed
# The arrival (heartwood_gifts.md "Gifts as landmarks" 5): a gift was planted, the Heartwood's roots run along the
# ground `from` the Heartwood `to` the spot (MapGenerator pixels) for `seconds` (0 under reduced motion: it is just
# there), then the landmark rises and gift_arrived fires. For Sound and Main Merger's camera.
signal gift_arriving(id: StringName, from: Vector2, to: Vector2, seconds: float)
signal gift_arrived(id: StringName, at: Vector2)
signal landmark_grew(id: StringName, step: int, at: Vector2)  # An act break's growth: the flourish plays at `at`

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const TREE_DATA := preload("res://resource/obstacle/tree.tres")
const ROCK_DATA := preload("res://resource/obstacle/rock.tres")

const SOW_RIDGE := &"sow_ridge"
const FALLEN_GIANT := &"fallen_giant"
const GLADE := &"glade"
const SHIFT_STONES := &"shift_stones"
const MIRE := &"mire"
const SPRING := &"spring"
const MUSHROOM_RING := &"mushroom_ring"
const LIGHTNING_TREE := &"lightning_tree"
const MOONWELL := &"moonwell"
const BELL_STONE := &"bell_stone"
const ANCIENT_STUMP := &"ancient_stump"
const HEARTWOOD_ROOTS := &"heartwood_roots"
const SHIFTING_MIST := &"shifting_mist"  # Replaced Deeper Glade (heartwood_gifts.md 0c552b28)
const RESHAPE := &"reshape"  # Glade + Shift the Stones in one gift: move or clear (heartwood_gifts.md "Gifts as landmarks")
const TERRAIN_GIFTS: Array[StringName] = [SOW_RIDGE, FALLEN_GIANT, GLADE, SHIFT_STONES, MIRE, SPRING, MUSHROOM_RING,
	LIGHTNING_TREE, MOONWELL, BELL_STONE, ANCIENT_STUMP, HEARTWOOD_ROOTS, SHIFTING_MIST]
# Reshape's effect is here, but a gift is offered as soon as its effect is registered, and the gift screen has no
# "reshape" placing mode yet. Main Merger's GiftPlacer sets this true (before the run's map is made) once it has one.
static var reshape_placer_ready := false

# Numbers: read from HeartwoodGifts (the one source; Balancing tunes them there), never copied here.
static func mire_slow() -> float:  # Through EnemyStatuses' extra slow: the slow floors still hold
	return HeartwoodGifts.stat(MIRE, "slow")

static func sown_tree_seeds() -> int:  # Sow a Ridge: each of its trees tended pays this many Seeds in all (instead of the usual 1)
	return int(HeartwoodGifts.stat(SOW_RIDGE, "tree_seeds"))

# The growth step (1-3) of each gift on the map: from the effect's placement.step and HeartwoodGifts.gift_grew.
var steps := {}

func step(id: StringName) -> int:
	return clampi(int(steps.get(id, 1)), 1, 3)

func roots_count() -> int:  # Path cells Heartwood Roots covers at its step
	return int(HeartwoodGifts.stat(HEARTWOOD_ROOTS, "path_cells", step(HEARTWOOD_ROOTS)))

func roots_taken() -> float:
	return HeartwoodGifts.stat(HEARTWOOD_ROOTS, "damage_taken", step(HEARTWOOD_ROOTS))

const TICK := 0.2  # s between ground checks on the nightmares

# Art (Environment Assets 46525c97): sheet name → [frame size, frames].
const ART := {
	"lightning_tree": [Vector2i(96, 128), 4], "moonwell": [Vector2i(64, 64), 4], "bell_stone": [Vector2i(64, 64), 4],
	"mushroom_ring": [Vector2i(192, 192), 4], "heartwood_roots": [Vector2i(64, 64), 16],
	"bog_path": [Vector2i(64, 64), 16], "ancient_stump": [Vector2i(64, 64), 3],
	"fallen_log": [Vector2i(64, 64), 6],  # Static pieces: 0 W end, 1 E-W middle, 2 E end, 3 N end, 4 N-S middle, 5 S end
}
const ANIMATED: Array[String] = ["lightning_tree", "moonwell", "bell_stone", "mushroom_ring"]

var map: Node  # MapGenerator
var act := 1
var gift_obstacles := {}  # {cell: [kind ("sown" / "tree" / "rock" / "lightning"), tile (Vector2i)]}: obstacles a gift put down
var logs: Array = []  # [[cells…], …]: Fallen Giants (blocked, never clearable)
var spring_cells: Array[Vector2] = []
var moonwells: Array[Vector2] = []
var bell_stones: Array[Vector2] = []
var bog_cells: Array[Vector2] = []
var root_cells: Array[Vector2] = []
var rings: Array[Vector2] = []  # Top-left cells of 3×3 Mushroom Rings
var stumps: Array[Vector2] = []
var _props: Array[Node2D] = []
var _sheets := {}
var _tick := 0.0
var _frame_time := 0.0

# Registered at run time (from _ready, not _static_init: a Callable stored from a static init can crash the
# engine at exit, Tower Code 3af4bb5b). A test's stand-in may already hold the id.
static func register_effects() -> void:
	for id in TERRAIN_GIFTS:
		if not HeartwoodGifts.has_effect(id):
			HeartwoodGifts.register(id, _effect.bind(id))
	if reshape_placer_ready and not HeartwoodGifts.has_effect(RESHAPE):
		HeartwoodGifts.register(RESHAPE, _effect.bind(RESHAPE))

# HeartwoodGifts' call: placement.cells (Shift the Stones: placement.from, pairwise), placement.restoring,
# placement.step (a landmark's growth step, 1-3).
static func _effect(main: Node, placement: Dictionary, id: StringName) -> void:
	var map_generator := main.get_node_or_null("%MapGenerator")
	if map_generator == null or map_generator.gifts == null:
		return
	var run_state := main.get_node_or_null("%RunState")
	var tended: Array = run_state.tended_cells if run_state != null else []
	map_generator.gifts.steps[id] = clampi(int(placement.get("step", 1)), 1, 3)
	if id == RESHAPE:  # "from" (obstacle keys × 2) go to "to" (half origins), pairwise; "cells" (obstacle keys) are cleared
		var moved: Array[Vector2] = []
		moved.assign(HeartwoodGifts.cells_of(placement, "from").map(func(p: Vector2) -> Vector2: return p / 2.0))
		var to: Array[Vector2] = []
		to.assign(HeartwoodGifts.cells_of(placement, "to").map(func(p: Vector2) -> Vector2: return p / 2.0))
		map_generator.gifts.reshape(moved, to, HeartwoodGifts.cells_of(placement), bool(placement.get("restoring", false)),
			int(placement.get("tended_before", -1)), tended)
		return
	# Half cells (heartwood_gifts.md 2554c638): "pieces" are Warden-style half origins (a 2×2 each; key = origin / 2,
	# x.5 when half-offset), "from" the obstacles Shift the Stones picked up (their keys × 2), "halves" the route
	# halves Mire / Heartwood Roots picked. An older placement has whole "cells" (and whole-cell "from").
	var keys: Array[Vector2] = HeartwoodGifts.cells_of(placement)
	var from: Array[Vector2] = HeartwoodGifts.cells_of(placement, "from")
	if placement.has("pieces"):
		keys.assign(HeartwoodGifts.cells_of(placement, "pieces").map(func(p: Vector2) -> Vector2: return p / 2.0))
		from.assign(from.map(func(p: Vector2) -> Vector2: return p / 2.0))
	map_generator.gifts.apply(id, keys, from, bool(placement.get("restoring", false)), int(placement.get("tended_before", -1)),
		tended, HeartwoodGifts.cells_of(placement, "halves"))

func _ready() -> void:
	z_index = -1  # Ground overlays: over the path (added after it), under everything standing
	register_effects()
	map.obstacle_cleared.connect(_on_obstacle_cleared)
	map.path_changed.connect(queue_redraw)
	map.path_changed.connect(_draw_duals)
	_load_sheets()
	_zones = GiftZones.new()
	_zones.name = "GiftZones"
	_zones.gifts = self
	add_child(_zones)  # On the ground with this node (z -1): under everything standing

# The cells Heartwood Roots grows over now: the last roots_count() of the route before the Heartwood (for the
# gift screen's preview; HeartwoodGifts saves them as the placement, since the route moves).
func roots_cells() -> Array[Vector2]:
	var cells: Array[Vector2] = []
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	for i in range(route.size() - 1, 0, -1):  # Back from the Heartwood: the whole cells the route runs through
		var cell := Vector2(FindPath.point_to_node(route[i]) / 2)
		if cell == map.endPath or cell == map.startPath or cells.has(cell):
			continue
		cells.append(cell)
		if cells.size() >= roots_count():
			break
	return cells

# The route halves Heartwood Roots grows over by default: the last roots_count() × 2 of the route before the Heartwood.
func roots_halves() -> Array[Vector2]:
	var halves: Array[Vector2] = []
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	for i in range(route.size() - 1, 0, -1):
		var h := Vector2(FindPath.point_to_node(route[i]))
		var cell := (h / 2.0).floor()
		if cell == map.endPath or cell == map.startPath or halves.has(h):
			continue
		halves.append(h)
		if halves.size() >= roots_count() * 2:
			break
	return halves

# Shifting Mist: up to `count` rim cells the start could move to (MapLayout's rules: on the rim, not by a
# corner, far enough from the Heartwood, a route from it with today's Wardens: they never rule a spot out on their own), spread
# apart and away from today's start. The same for the same map and start (seeded).
func start_options(count: int) -> Array[Vector2]:
	var size := Vector2i(MAP_GRID.size)
	var last := size - Vector2i.ONE
	var reach := Vector2(size).length() * MapLayout.MIN_DISTANCE_SHARE
	var candidates: Array[Vector2] = []
	var far_enough: Array[Vector2] = []
	for x in size.x:
		for y in size.y:
			var cell := Vector2i(x, y)
			var on_rim := x == 0 or y == 0 or x == last.x or y == last.y
			var by_corner := (x <= 1 or x >= last.x - 1) and (y <= 1 or y >= last.y - 1)
			if not on_rim or by_corner or Vector2(cell) == map.startPath or map.path_layer.is_cell_blocked(Vector2(cell)):  # Edge cells are ground now: not under an obstacle or a Warden
				continue
			candidates.append(Vector2(cell))
			if Vector2(cell).distance_to(map.endPath) >= reach:
				far_enough.append(Vector2(cell))
	var pool := far_enough if far_enough.size() >= count else candidates
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([map.map_seed, map.startPath])
	for i in range(pool.size() - 1, 0, -1):  # Seeded shuffle
		var j := rng.randi_range(0, i)
		var swap := pool[i]
		pool[i] = pool[j]
		pool[j] = swap
	var picked: Array[Vector2] = []
	for spread in [6.0, 3.0, 0.0]:  # Apart from each other and the start; relax if the rim is short of room
		for cell in pool:
			if picked.size() >= count:
				return picked
			if picked.has(cell) or cell.distance_to(map.startPath) < spread:
				continue
			if picked.any(func(p: Vector2) -> bool: return p.distance_to(cell) < spread):
				continue
			if route_from_start(cell).is_empty():
				continue
			picked.append(cell)
	return picked

# Shifting Mist's ghost on the gift screen: the rope bridge out from edge cell `cell` on its lane and the nightmare
# fog at its end (StartGate's art, frame 0), drawn on `canvas` (any CanvasItem in the map's space) at `alpha`.
func draw_start_ghost(canvas: CanvasItem, cell: Vector2, alpha: float = 0.6) -> void:
	var tint := Color(1, 1, 1, alpha)  # A multiplier on the art, not a colour
	var half := StartGate.start_half_for(Vector2i(cell), map.endPath)  # The lane the bridge will stand on there
	var lane := StartGate.lane_offset(Vector2i(cell), FindPath.node_to_point(half))
	StartGate.draw_gate(canvas, Vector2i(cell), lane, 0, load(EnvironmentTiles.shared_path("rope_bridge_lane")),
		load(EnvironmentTiles.shared_path("nightmare_fog")), MAP_GRID.calculate_map_position(cell), tint)

# The route nightmares would take from rim cell `spot` (the gift screen's preview). Changes nothing.
func route_from_start(spot: Vector2) -> PackedVector2Array:
	if spot == map.startPath:
		return map.get_path_from(map.startPath)
	var opened: Array[Vector2] = []
	var version: int = map.probe_begin()
	for h in FindPath.halves_of_cell(spot):
		if map.path_layer.is_half_blocked(h):
			opened.append(h)
			map.path_layer.set_half_blocked(h, false)
	var finder: FindPath = map.path_layer.get_finder()
	var real_cell := finder.start_cell
	var real_half := finder.start_half
	finder.start_cell = spot  # From this spot's own start half (its outer half on the bridge's lane), as it will be
	finder.start_half = StartGate.start_half_for(Vector2i(spot), map.endPath)
	var route: PackedVector2Array = finder.straightest_point_path(spot, map.endPath)  # As draw() will
	finder.start_cell = real_cell
	finder.start_half = real_half
	for h in opened:
		map.path_layer.set_half_blocked(h, true)
	map.probe_end(version)
	return route

# Puts `gift` on `cells` (the caller checked them; Shift the Stones moves `from[i]` to `cells[i]`).
# `restoring`: rebuilding a resumed run on the regenerated map. Obstacles a gift put down and the player
# tended later stay gone: `tended` (RunState.tended_cells) from index `tended_before` (the count when the
# gift was taken; -1 = unknown, any tending of the cell counts).
# `cells` are piece positions in full-cell units (x.5 when half-offset: a 2×2 of halves from cell × 2); `halves` the
# route halves Mire / Heartwood Roots picked (else their whole `cells`' halves).
func apply(gift: StringName, cells: Array[Vector2], from: Array[Vector2] = [], restoring := false,
		tended_before := -1, tended: Array = [], halves: Array[Vector2] = []) -> void:
	var tended_later := func(cell: Vector2) -> bool:
		return restoring and tended.slice(maxi(tended_before, 0)).has(cell)
	match gift:
		SOW_RIDGE:
			for cell in cells:
				if not tended_later.call(cell):
					_put_obstacle(cell, "sown", TREE_DATA.tiles[EnvironmentTiles.cell_variant(Vector2i(cell), TREE_DATA.tiles.size())])
		FALLEN_GIANT:
			logs.append(cells.duplicate())
			_block(cells)
		GLADE:  # The obstacles the player picked (up to 5; user: "no control" with a radius)
			for cell in cells:
				_clear(cell, restoring)
		SHIFT_STONES:
			for i in mini(from.size(), cells.size()):
				_move_obstacle(from[i], cells[i], tended_later.call(cells[i]))
		MIRE:
			bog_cells.append_array(_halves_for(halves, cells))
		SPRING:
			spring_cells.append_array(cells)
			_block(cells)
			_draw_spring()  # After _block, which clears the object layer
		MUSHROOM_RING:
			if not cells.is_empty():
				rings.append(Vector2(_min_x(cells), _min_y(cells)))  # Top-left
		LIGHTNING_TREE:
			if not cells.is_empty() and not tended_later.call(cells[0]):
				_put_obstacle(cells[0], "lightning", Vector2i.ZERO)
		MOONWELL:
			moonwells.append_array(cells)
			_block(cells)
		BELL_STONE:
			bell_stones.append_array(cells)
			_block(cells)
		ANCIENT_STUMP:
			stumps.append_array(cells)
		HEARTWOOD_ROOTS:
			root_cells.append_array(_halves_for(halves, cells) if not (halves.is_empty() and cells.is_empty()) else roots_halves())
			_roots_on = true
			# A resumed run at step II / III: the save holds the cells of the pick (step I). The Wardens come back after
			# the gifts, so the longer stretch is taken from the route once they stand (_process).
			_roots_regrow_in = 1.0 if restoring and step(HEARTWOOD_ROOTS) > 1 else -1.0
		SHIFTING_MIST:  # Replayed on a resume: the regenerated map starts at the old start again
			if not cells.is_empty():
				map.move_start(cells[0])
	_rebuild_props()
	map.path_layer.draw()
	map.path_changed.emit()
	queue_redraw()
	if not restoring:
		_arrive(gift, _spot_of(cells, halves), cells)
	gifts_changed.emit()

# Mire / Roots halves: the picked route halves (route points → their half), or a whole cell's 4 (older placements).
func _halves_for(points: Array[Vector2], cells: Array[Vector2]) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for p in points:  # Route points (x.25 / x.75) are turned into their half; whole numbers are taken as halves already
		out.append(p if FindPath.is_whole_cell(p) else Vector2(FindPath.point_to_node(p)))
	if points.is_empty():
		for cell in cells:
			out.append_array(FindPath.halves_of_cell(cell))
	return out

# A whole cell: any of its halves is bog; a route point (x.25 / x.75): its own half.
func is_bog(point: Vector2) -> bool:
	return _covers(bog_cells, point)

func is_rooted(point: Vector2) -> bool:
	return _covers(root_cells, point)

func _covers(halves: Array[Vector2], point: Vector2) -> bool:
	if FindPath.is_whole_cell(point):
		return FindPath.halves_of_cell(point).any(func(h: Vector2) -> bool: return halves.has(h))
	return halves.has(Vector2(FindPath.point_to_node(point)))

# Reshape: the obstacles on `from` go to `to` (pairwise; obstacle keys, full-cell units, x.5 when half-offset), the
# ones on `cleared` are tended away. `restoring` / `tended_before` / `tended` as apply().
func reshape(from: Array[Vector2], to: Array[Vector2], cleared: Array[Vector2], restoring := false, tended_before := -1,
		tended: Array = []) -> void:
	for cell in cleared:
		_clear(cell, restoring)
	for i in mini(from.size(), to.size()):
		_move_obstacle(from[i], to[i], restoring and tended.slice(maxi(tended_before, 0)).has(to[i]))
	_rebuild_props()
	map.path_layer.draw()
	map.path_changed.emit()
	queue_redraw()
	gifts_changed.emit()
	if not restoring:
		var spots: Array[Vector2] = to if not to.is_empty() else cleared
		_arrive(RESHAPE, _spot_of(spots, []), [])

# Whether Reshape may move `from` to `to` (half origins) and clear `cleared` (obstacle keys): every picked key is an
# obstacle, picked once, at most `limit` in all; every landing spot free once the picked ones are gone, and the way
# stays open. refusal() says why not. (GiftPlacer's "reshape" mode asks this.)
func can_reshape(from: Array, to: Array, cleared: Array, limit: int = int(HeartwoodGifts.POOL[RESHAPE].size)) -> bool:
	_refusal = &""
	var picked: Array = from + cleared
	if picked.size() > limit or from.size() < to.size():
		_refusal = &"occupied"
		return false
	for i in picked.size():
		if not map.obstacles.has(picked[i]) or picked.find(picked[i]) != i:
			_refusal = &"occupied"
			return false
	var opened: Array[Vector2] = []  # The picked obstacles' halves, open while the landing spots are checked
	var version: int = map.probe_begin()
	for key: Vector2 in picked:
		for cell in map.get_obstacle_cells(key):
			for h in (FindPath.halves_of_cell(cell) if FindPath.is_whole_cell(cell) else piece_halves(cell * 2.0)):
				if map.path_layer.is_half_blocked(h):
					opened.append(h)
					map.path_layer.set_half_blocked(h, false)
	var ok := can_place(SHIFT_STONES, to)
	var why := _refusal
	for h in opened:
		map.path_layer.set_half_blocked(h, true)
	map.probe_end(version)
	_refusal = why
	return ok

# The fallen log is no Warden: nothing tramples it or burrows under it (both only ever pick Wardens' cells). True for a
# route point or whole cell under a Fallen Giant, for anything new that would break or pass under a blocked cell.
func is_log(point: Vector2) -> bool:
	for l: Array in logs:
		for cell: Vector2 in l:
			if FindPath.is_whole_cell(point):
				if absf(cell.x - point.x) < 1.0 and absf(cell.y - point.y) < 1.0:
					return true
			elif piece_halves(cell * 2.0).has(Vector2(FindPath.point_to_node(point))):
				return true
	return false

# --- Landmarks: zones, growth, the arrival (heartwood_gifts.md "Gifts as landmarks") ------------------------------

const ARRIVAL_ROOTS := 1.0  # s the roots take from the Heartwood to the spot
const ARRIVAL_RISE := 0.5  # s the landmark takes to rise
const GROW_RISE := 0.45  # s of the grow flourish
const ZONE_COLORS := {SPRING: Palette.DEWLIGHT, LIGHTNING_TREE: Palette.GLOW, BELL_STONE: Palette.ORCHID,
	MOONWELL: Palette.MOONLIGHT, MUSHROOM_RING: Palette.SPRIG}
var _zones: GiftZones
var _roots_on := false
var _roots_regrow_in := -1.0
var _hooked := false
var _rise := {}  # Landmark id -> 0..1 while it rises (the arrival, the grow flourish); absent = standing

# Every landmark standing on the map: {id, at (its centre, MapGenerator pixels), extent (px from the centre to its
# edge), radius (px: the edge plus HeartwoodGifts.zone_cells), color}. The zone is the standing glow; Tower Code's
# effects use the same reach.
func landmarks() -> Array:
	var out: Array = []
	var cell := float(MAP_GRID.cell_size.x)
	if not spring_cells.is_empty():
		var top := Vector2(_min_x(spring_cells), _min_y(spring_cells))
		out.append(_landmark(SPRING, MAP_GRID.calculate_map_position(top + Vector2(0.5, 0.5)), cell))
	for at in lightning_trees():
		out.append(_landmark(LIGHTNING_TREE, MAP_GRID.calculate_map_position(at), cell / 2.0))
	for at in bell_stones:
		out.append(_landmark(BELL_STONE, MAP_GRID.calculate_map_position(at), cell / 2.0))
	for at in moonwells:
		out.append(_landmark(MOONWELL, MAP_GRID.calculate_map_position(at), cell / 2.0))
	for top in rings:
		out.append(_landmark(MUSHROOM_RING, MAP_GRID.calculate_map_position(top + Vector2.ONE), cell * 1.5))
	return out

func _landmark(id: StringName, at: Vector2, extent: float) -> Dictionary:
	return {"id": id, "at": at, "extent": extent, "radius": extent + HeartwoodGifts.zone_cells(id) * MAP_GRID.cell_size.x,
		"color": ZONE_COLORS.get(id, Palette.GLOW)}

# The centre (MapGenerator pixels) of what a gift was put on: its pieces, else its route halves.
func _spot_of(cells: Array[Vector2], halves: Array[Vector2]) -> Vector2:
	var sum := Vector2.ZERO
	if not cells.is_empty():
		for cell in cells:
			sum += MAP_GRID.calculate_map_position(cell)
		return sum / cells.size()
	if halves.is_empty():
		return MAP_GRID.calculate_map_position(map.endPath)
	for h in halves:
		sum += (h + Vector2(0.5, 0.5)) * Vector2(MAP_GRID.cell_size) / 2.0
	return sum / halves.size()

# The arrival: roots from the Heartwood to the spot, then the landmark rises. Reduced motion (or no tree yet: a test
# applying gifts by hand): it is just there, and both signals fire at once.
func _arrive(id: StringName, spot: Vector2, _cells: Array) -> void:
	var from := MAP_GRID.calculate_map_position(map.endPath)
	var still := bool(Fx.setting("reduced_motion", false)) or not is_inside_tree() or DisplayServer.get_name() == "headless"
	if still or from.distance_to(spot) < 1.0:
		gift_arriving.emit(id, from, spot, 0.0)
		gift_arrived.emit(id, spot)
		return
	_rise[id] = 0.0
	_redraw_props()
	var arrival := GiftArrival.new()
	arrival.name = "GiftArrival"
	arrival.gifts = self
	arrival.id = id
	arrival.from = from
	arrival.to = spot
	add_child(arrival)
	gift_arriving.emit(id, from, spot, ARRIVAL_ROOTS + ARRIVAL_RISE)

func _set_rise(id: StringName, share: float) -> void:
	if share >= 1.0:
		_rise.erase(id)
	else:
		_rise[id] = share
	_redraw_props()
	queue_redraw()

func rise_of(kind: String) -> float:
	return float(_rise.get(FALLEN_GIANT if kind == "fallen_log" else StringName(kind), 1.0))

func _redraw_props() -> void:
	for prop in _props:
		if is_instance_valid(prop):
			prop.queue_redraw()

# HeartwoodGifts.gift_grew: a landmark gained a step at an act break. Its look and zone follow, with a short flourish.
func _on_gift_grew(id: StringName, new_step: int, _placement: Dictionary) -> void:
	steps[id] = clampi(new_step, 1, 3)
	if id == HEARTWOOD_ROOTS and _roots_on:
		root_cells = roots_halves()  # The longer stretch, on today's route
		_draw_duals()
	_redraw_props()
	queue_redraw()
	if _zones != null:
		_zones.queue_redraw()
	gifts_changed.emit()
	for mark: Dictionary in landmarks():
		if mark.id != id:
			continue
		landmark_grew.emit(id, new_step, mark.at)
		if bool(Fx.setting("reduced_motion", false)) or DisplayServer.get_name() == "headless":
			continue
		var bloom := GiftArrival.new()
		bloom.name = "GiftGrow"
		bloom.gifts = self
		bloom.id = id
		bloom.from = mark.at
		bloom.to = mark.at
		bloom.grow_only = true
		bloom.ring_radius = float(mark.radius)
		bloom.ring_color = mark.color
		add_child(bloom)

func _hook_gifts() -> void:
	var node := HeartwoodGifts.find(map)
	if node == null:
		return
	_hooked = true
	if not node.gift_grew.is_connected(_on_gift_grew):
		node.gift_grew.connect(_on_gift_grew)

# --- Placing pieces (GiftPlacer, Main's gift_screen.gd; heartwood_gifts.md 2554c638) ---------------------------
# A piece is a Warden's footprint: the 2×2 halves from half origin `origin`.
static func piece_halves(origin: Vector2) -> Array[Vector2]:
	return FindPath.halves_of(origin)

const BLOCKING_GIFTS: Array[StringName] = [SOW_RIDGE, FALLEN_GIANT, SHIFT_STONES, SPRING, LIGHTNING_TREE, MOONWELL, BELL_STONE]
const ROUTE_GIFTS: Array[StringName] = [MIRE, HEARTWOOD_ROOTS]
var _refusal := &""

# Whether `gift` can go on `pieces` (half origins; Mire / Roots: route halves). Every half free and off the glade
# (not the start or Heartwood), and a blocking gift leaves every nightmare a way through, like a Warden. Mire / Roots:
# every half on the drawn route. The gift's own shape rules (a line, connected, in pieces) are GiftPlacer's.
func can_place(gift: StringName, pieces: Array) -> bool:
	_refusal = &""
	if ROUTE_GIFTS.has(gift):
		var route: Dictionary = map.path_layer.path_halves()
		for h: Vector2 in pieces:
			if not route.has(Vector2i(h)):
				_refusal = &"off_route"
				return false
		return true
	var halves: Array[Vector2] = []
	var glade: PackedVector2Array = map.get_glade_cells()
	for origin: Vector2 in pieces:
		for h in piece_halves(origin):
			if not map.is_buildable_half(h) or glade.has((h / 2.0).floor()) or halves.has(h):
				_refusal = &"occupied"
				return false
			halves.append(h)
	if BLOCKING_GIFTS.has(gift) and not map.can_block_halves(halves, _walker_points()):
		_refusal = &"closes"
		return false
	return true

# Why the last can_place() said no: &"occupied", &"closes" or &"off_route" (&"" after a yes).
func refusal() -> StringName:
	return _refusal

func _walker_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	var spawner: Node = map.get_node_or_null("%EnemyContainer")
	if spawner != null and spawner.has_method("get_maze_walkers"):
		for enemy in spawner.get_maze_walkers():
			var target: Vector2 = enemy.get_target_cell()
			if map.has_route_from(target):
				points.append(target)
	return points

func lightning_trees() -> Array[Vector2]:
	var cells: Array[Vector2] = []
	for cell in gift_obstacles:
		if gift_obstacles[cell][0] == "lightning":
			cells.append(cell)
	return cells

# --- Effects on nightmares ----------------------------------------------------------------------------

func _process(delta: float) -> void:
	var frame := int(_frame_time)
	_frame_time = fmod(_frame_time + delta * EnvironmentTiles.FPS, EnvironmentTiles.FRAMES)
	if int(_frame_time) != frame:
		if (not rings.is_empty() and step_art("mushroom_ring")[0] != null) or (step(SPRING) > 1 and not spring_cells.is_empty()):
			queue_redraw()
		for prop in _props:
			if _sheets.has(prop.kind) and ANIMATED.has(prop.kind):
				prop.queue_redraw()
	if not _hooked:
		_hook_gifts()
	if _roots_regrow_in > 0.0:
		_roots_regrow_in -= delta
		if _roots_regrow_in <= 0.0 and _roots_on:
			root_cells = roots_halves()  # A resumed run: the grown stretch, now the Wardens stand
			_draw_duals()
			queue_redraw()
	if bog_cells.is_empty() and root_cells.is_empty():
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = TICK
	var spawner: Node = map.get_node_or_null("%EnemyContainer")  # Made in code: no owner of its own for %
	if spawner == null:
		return
	for enemy in spawner.get_enemies():
		var half := Vector2(FindPath.point_to_node(enemy.get_route_point()))  # The half its body is on
		var s: EnemyStatuses = enemy.statuses
		if bog_cells.has(half) and not enemy.is_flying():  # Flyers pass over the bog
			s.slow_time = maxf(s.slow_time, TICK * 1.6)
			s.slow_amount = maxf(s.slow_amount if s.slow_time > 0.0 else 0.0, mire_slow())
		if root_cells.has(half):
			s.ground_taken = roots_taken()
			s.ground_taken_time = maxf(s.ground_taken_time, TICK * 1.6)

# --- Terrain changes ---------------------------------------------------------------------------------

func _put_obstacle(cell: Vector2, kind: String, tile: Vector2i) -> void:
	if map.get_obstacle(cell) != null:  # Restoring over a regenerated obstacle a gift had replaced
		map._remove_obstacle(cell, false)
	var data := _data_for(kind)
	map.place_obstacle(cell, data)
	if kind != "lightning" and FindPath.is_whole_cell(cell):  # place_obstacle picked a random tile: use ours (moves keep their look)
		map.environment_object_layer.set_cell(Vector2i(cell), data.source_id, tile)
	gift_obstacles[cell] = [kind, tile]  # Half-offset ones are drawn by a GiftProp (_rebuild_props)

# Moves the tree / stone on `from` to `to` (not a clear: nothing tended). `gone`: restoring, and the
# player tended it on `to` since.
func _move_obstacle(from: Vector2, to: Vector2, gone: bool) -> void:
	var data: ObstacleData = map.get_obstacle(from)
	if data == null:
		return  # Restoring: already tended away before the move? (the move needs it: nothing to do)
	var kind := "rock" if data.source_id == ROCK_DATA.source_id else "tree"
	var tile: Vector2i = gift_obstacles[from][1] if gift_obstacles.has(from) \
		else map.environment_object_layer.get_cell_atlas_coords(Vector2i(from))
	gift_obstacles.erase(from)
	map._remove_obstacle(from, false)
	if not gone:
		_put_obstacle(to, kind, tile)

# Clears `cell` free. Fresh: through MapGenerator.clear_obstacle, so it counts as tended (RunState listens).
# Restoring: the save's tended cells already did that; anything left goes quietly.
func _clear(cell: Vector2, restoring: bool) -> void:
	gift_obstacles.erase(cell)
	if restoring:
		map._remove_obstacle(cell)
	else:
		map.clear_obstacle(cell)

func _block(cells: Array[Vector2]) -> void:
	for cell in cells:  # Its 2×2 halves (x.5 keys: a half-offset piece)
		map.path_layer.set_cell_blocked(cell, true)
		if FindPath.is_whole_cell(cell):
			map.environment_object_layer.erase_cell(Vector2i(cell))

func _draw_spring() -> void:
	for cell in spring_cells:  # Pond tiles by neighbour mask, banks facing the land (half-offset pieces: _draw)
		if not FindPath.is_whole_cell(cell):
			continue
		map.environment_object_layer.set_cell(Vector2i(cell), EnvironmentTiles.POND,
			Vector2i(_mask(cell, func(c: Vector2) -> bool: return spring_cells.has(c)), 0))

func _data_for(kind: String) -> ObstacleData:
	match kind:
		"rock":
			return ROCK_DATA
		"lightning":
			var data: ObstacleData = TREE_DATA.duplicate()
			data.display_name = "Lightning Tree"
			data.tiles = []  # A GiftProp draws it
			return data
	return TREE_DATA

func _on_obstacle_cleared(cell: Vector2, _data: ObstacleData) -> void:
	if gift_obstacles.has(cell):
		if gift_obstacles[cell][0] == "sown":  # Sow a Ridge's tree: sown_tree_seeds() in all (RunState already counted the usual 1)
			var run_state: Node = map.get_node_or_null("%RunState")
			if run_state != null and not run_state.clearing_without_seeds:
				run_state.obstacles_tended += sown_tree_seeds() - 1
		gift_obstacles.erase(cell)
		_rebuild_props()
		gifts_changed.emit()

func _obstacles_within(centre: Vector2, radius: int) -> Array:
	var cells: Array = []
	for cell: Vector2 in map.obstacles:
		if absf(cell.x - centre.x) <= radius and absf(cell.y - centre.y) <= radius:
			cells.append(cell)
	return cells

static func _min_x(cells: Array) -> float:
	return cells.reduce(func(m: float, c: Vector2) -> float: return minf(m, c.x), INF)

static func _min_y(cells: Array) -> float:
	return cells.reduce(func(m: float, c: Vector2) -> float: return minf(m, c.y), INF)

static func _mask(cell: Vector2, on: Callable) -> int:
	return ((1 if on.call(cell + Vector2.UP) else 0) | (2 if on.call(cell + Vector2.RIGHT) else 0)
		| (4 if on.call(cell + Vector2.DOWN) else 0) | (8 if on.call(cell + Vector2.LEFT) else 0))

# --- Drawing ----------------------------------------------------------------------------------------

func set_act(new_act: int) -> void:
	act = new_act
	_load_sheets()
	queue_redraw()
	for prop in _props:
		prop.queue_redraw()

func _load_sheets() -> void:
	_sheets.clear()
	for sheet: String in ART:
		var path := EnvironmentTiles.sheet_path(sheet, act)
		if ResourceLoader.exists(path):
			_sheets[sheet] = load(path)
	_step_sheets.clear()
	for kind: String in STEP_ART:
		for grown in STEP_ART[kind].size():
			var path := EnvironmentTiles.sheet_path("%s_%d" % [kind, grown + 2], act)
			if ResourceLoader.exists(path):
				_step_sheets["%s_%d" % [kind, grown + 2]] = load(path)
	_load_dual_sheets()

func frame_region(sheet: String, column: int) -> Rect2:
	var size: Vector2i = ART[sheet][0]
	return Rect2(Vector2(column * size.x, 0), Vector2(size))

# Growth looks (heartwood_gifts.md "Landmarks grow": a bigger look at steps II and III). Environment Assets' sheets
# are `<kind>_2.png` and `<kind>_3.png` beside the step I sheet in each act's folder, 4 frames in a row of the frame
# size below (the bottom 64 px on the landmark's cell, the rest overhangs up and to the sides; the ring and the
# Spring's bloom cover their own patch). Until a sheet exists, the step I art is drawn larger from its base
# (STEP_SCALE): a stand-in, not the look.
const STEP_ART := {
	"moonwell": [Vector2i(96, 96), Vector2i(128, 128)], "bell_stone": [Vector2i(64, 96), Vector2i(96, 128)],
	"lightning_tree": [Vector2i(128, 160), Vector2i(160, 192)], "mushroom_ring": [Vector2i(192, 192), Vector2i(192, 192)],
	"spring": [Vector2i(128, 128), Vector2i(128, 128)],  # A bloom over the 2×2 pond (the pond tiles stay)
}
const STEP_SCALE: Array[float] = [1.0, 1.0, 1.25, 1.5]  # By step, without that step's sheet
var _step_sheets := {}  # "<kind>_<step>" -> Texture2D

# What a landmark of `kind` draws at its step: [texture, frame size (Vector2), scale]. The scale is 1 with that
# step's own sheet. [null, …] without any art (the placeholder).
func step_art(kind: String) -> Array:
	var at := step(StringName(kind))
	var own: Texture2D = _step_sheets.get("%s_%d" % [kind, at])
	if own != null:
		return [own, Vector2(STEP_ART[kind][at - 2]), 1.0]
	if _sheets.has(kind):
		return [_sheets[kind], Vector2(ART[kind][0]), STEP_SCALE[at] if STEP_ART.has(kind) else 1.0]
	return [null, Vector2(MAP_GRID.cell_size), STEP_SCALE[at] if STEP_ART.has(kind) else 1.0]

func _draw() -> void:
	var cell_size := Vector2(MAP_GRID.cell_size)
	var half_size := cell_size / 2.0
	for h in bog_cells if not has_dual("bog") else []:  # Without the dual sheets: a placeholder per half
		var at := h * half_size
		draw_rect(Rect2(at + Vector2(3, 3), half_size - Vector2(6, 6)), Color(Palette.ROOT, 0.7))
		draw_circle(at + half_size / 2.0, 5.0, Palette.POOL)
	for h in root_cells if not has_dual("roots") else []:
		var c := h * half_size + half_size / 2.0
		draw_line(c + Vector2(-13, -5), c + Vector2(12, 6), Palette.OAK, 3.0)
		draw_line(c + Vector2(-10, 8), c + Vector2(13, -7), Palette.BARK, 2.0)
	for cell in spring_cells:  # A half-offset Spring piece: its pond tile drawn here (whole ones are object-layer tiles)
		if FindPath.is_whole_cell(cell):
			continue
		var pond := map.tile_set.get_source(EnvironmentTiles.POND) as TileSetAtlasSource
		var mask := _mask(cell, func(c: Vector2) -> bool: return spring_cells.has(c))
		draw_texture_rect_region(pond.texture, Rect2(MAP_GRID.calculate_map_position(cell) - cell_size / 2.0, cell_size),
			pond.get_tile_texture_region(Vector2i(mask, 0)))
	if step(SPRING) > 1 and not spring_cells.is_empty() and _step_sheets.has("spring_%d" % step(SPRING)):
		var bloom: Texture2D = _step_sheets["spring_%d" % step(SPRING)]  # The grown Spring: a bloom over the 2×2 pond
		var size := Vector2(STEP_ART["spring"][step(SPRING) - 2])
		var centre := MAP_GRID.calculate_map_position(Vector2(_min_x(spring_cells), _min_y(spring_cells)) + Vector2(0.5, 0.5))
		draw_texture_rect_region(bloom, Rect2(centre - size / 2.0, size), Rect2(Vector2(int(_frame_time) * size.x, 0), size),
			Color(1, 1, 1, rise_of("spring")))  # multiplier
	for top in rings:
		var at := MAP_GRID.calculate_map_position(top) - cell_size / 2.0
		var ring_art := step_art("mushroom_ring")
		if ring_art[0] != null:  # The same 3×3 patch at every step: a fuller ring, not a wider one
			var frame: Vector2 = ring_art[1]
			draw_texture_rect_region(ring_art[0], Rect2(at, cell_size * 3), Rect2(Vector2(int(_frame_time) * frame.x, 0), frame),
				Color(1, 1, 1, rise_of("mushroom_ring")))  # multiplier
		else:  # Placeholder: a ring of toadstools
			var centre := at + cell_size * 1.5
			for i in 12:
				var p := centre + Vector2.from_angle(TAU * i / 12.0) * cell_size.x * 1.25
				draw_circle(p, 6.0, Palette.EMBER)
				draw_circle(p + Vector2(-2, -2), 2.0, Palette.GLOW)
	for cell in stumps:
		var at := MAP_GRID.calculate_map_position(cell) - cell_size / 2.0
		if _sheets.has("ancient_stump"):
			draw_texture_rect_region(_sheets.ancient_stump, Rect2(at, cell_size),
				frame_region("ancient_stump", EnvironmentTiles.cell_variant(Vector2i(cell), 3)))
		else:  # Placeholder: a wide cut stump with rings
			var c := at + cell_size / 2.0
			draw_circle(c, 20.0, Palette.BARK)
			draw_arc(c, 14.0, 0, TAU, 20, Palette.OAK, 2.0)
			draw_arc(c, 7.0, 0, TAU, 14, Palette.OAK, 2.0)

# Standing props, y-sorted with the trees under MapGenerator.
func _rebuild_props() -> void:
	for prop in _props:
		prop.queue_free()
	_props.clear()
	for l: Array in logs:
		for cell in l:
			_add_prop("fallen_log", cell, l)
	for cell in moonwells:
		_add_prop("moonwell", cell)
	for cell in bell_stones:
		_add_prop("bell_stone", cell)
	for cell in lightning_trees():
		_add_prop("lightning_tree", cell)
	for cell: Vector2 in gift_obstacles:  # Half-offset trees and stones: no tile of their own, a prop draws the tile art
		var entry: Array = gift_obstacles[cell]
		if entry[0] != "lightning" and not FindPath.is_whole_cell(cell):
			var prop := _add_prop("tile", cell)
			prop.source_id = (ROCK_DATA if entry[0] == "rock" else TREE_DATA).source_id
			prop.tile = entry[1]

func _add_prop(kind: String, cell: Vector2, line: Array = []) -> GiftProp:
	var prop := GiftProp.new()
	prop.gifts = self
	prop.kind = kind
	prop.line = line
	prop.piece = _log_piece(cell, line)
	prop.position = MAP_GRID.calculate_map_position(cell)
	map.add_child(prop)
	_props.append(prop)
	return prop

# Which fallen_log.png piece a Fallen Giant cell takes: its ends and middles along the line.
static func _log_piece(cell: Vector2, line: Array) -> int:
	if line.size() < 2:
		return -1
	var vertical: bool = line[0].x == line[1].x
	var along: Array = line.map(func(c: Vector2) -> float: return c.y if vertical else c.x)
	var at := cell.y if vertical else cell.x
	var first := 0 if at == along.min() else (2 if at == along.max() else 1)
	return first + (3 if vertical else 0)

class GiftProp extends Node2D:
	var gifts: MapGifts
	var kind: String
	var line: Array = []
	var piece := -1  # A Fallen Giant cell's piece of fallen_log.png; -1 = the animation frame
	var source_id := -1  # kind "tile": an object-layer tile drawn off the grid (a half-offset tree or stone)
	var tile := Vector2i.ZERO

	func _draw() -> void:
		if kind == "tile":
			var source := gifts.map.tile_set.get_source(source_id) as TileSetAtlasSource
			if source != null and source.has_tile(tile):
				var region := source.get_tile_texture_region(tile)
				var size := Vector2(region.size)
				draw_texture_rect_region(source.texture, Rect2(Vector2(-size.x / 2.0, 32.0 - size.y), size), region)  # Bottom on the piece
			return
		# A landmark draws at its growth step (its own sheet, else the step I art larger) and rises from its base while it
		# arrives or grows: both from the base line (y 32: the bottom of its cell).
		var art := gifts.step_art(kind)
		var rise := gifts.rise_of(kind)
		var grown: float = art[2]
		var lift := 0.35 + 0.65 * rise  # It comes up out of the ground
		draw_set_transform(Vector2(0.0, 32.0 * (1.0 - grown * lift)), 0.0, Vector2(grown, grown * lift))
		modulate.a = clampf(rise * 2.0, 0.0, 1.0)  # multiplier
		var sheet: Texture2D = art[0]
		if sheet != null:
			var size: Vector2 = art[1]
			var at := Vector2(-size.x / 2.0, 32.0 - size.y)  # Tall sprites put their bottom 64 px on the cell
			draw_texture_rect_region(sheet, Rect2(at, size), Rect2(Vector2((piece if piece >= 0 else int(gifts._frame_time)) * size.x, 0), size))
			return
		match kind:  # Placeholders in palette colours
			"fallen_log":
				var along := Vector2.DOWN if line.size() > 1 and line[0].x == line[1].x else Vector2.RIGHT
				var half := along * 32.0
				draw_line(-half, half, Palette.ROOT, 30.0)
				draw_line(-half, half, Palette.BARK, 24.0)
				draw_line(-half + along.orthogonal() * 6, half + along.orthogonal() * 6, Palette.OAK, 4.0)
			"moonwell":
				draw_circle(Vector2.ZERO, 24.0, Palette.STONE)
				draw_circle(Vector2.ZERO, 16.0, Palette.POOL)
				draw_circle(Vector2(-4, -4), 7.0, Palette.MOONLIGHT)
			"bell_stone":
				draw_rect(Rect2(-12, -40, 24, 64), Palette.SLATE)
				draw_circle(Vector2(0, -18), 6.0, Palette.GOLD)
			"lightning_tree":
				draw_line(Vector2(0, 24), Vector2(0, -60), Palette.DEADWOOD, 10.0)
				draw_line(Vector2(0, -30), Vector2(-20, -56), Palette.DEADWOOD, 5.0)
				draw_line(Vector2(0, -40), Vector2(18, -66), Palette.DEADWOOD, 5.0)
				draw_line(Vector2(-6, -64), Vector2(6, -48), Palette.WRAITHLIGHT, 2.0)

# --- Mire and Roots on the half-cell path (dual grid) -------------------------------------------------
# The path is drawn on PathGenerator's dual grid (32 px tiles, 16 px off the half grid). Where the route runs
# through a Mire cell, bog_path_dual.png replaces path_dual.png's tile; over a rooted cell,
# heartwood_roots_dual.png is laid on top. Same corner masks as the path (PathGenerator.dual_mask), on layers
# drawn over the path's own, so the bog and the roots follow the ribbon. Without those sheets: the old
# whole-cell drawing in _draw().
const DUAL_SHEETS := {"bog": "bog_path_dual", "roots": "heartwood_roots_dual"}
var _dual_layers := {}  # "bog" / "roots" -> TileMapLayer

func _load_dual_sheets() -> void:
	for kind: String in DUAL_SHEETS:
		var path := EnvironmentTiles.sheet_path(DUAL_SHEETS[kind], act)
		if not ResourceLoader.exists(path):
			continue
		var layer: TileMapLayer = _dual_layers.get(kind)
		if layer == null:
			layer = TileMapLayer.new()
			layer.name = "Gift" + kind.capitalize() + "Dual"
			layer.position = -Vector2(PathGenerator.DUAL_SIZE) / 2.0
			var tiles := TileSet.new()
			tiles.tile_size = PathGenerator.DUAL_SIZE
			var source := TileSetAtlasSource.new()
			source.texture_region_size = PathGenerator.DUAL_SIZE
			source.texture = load(path)
			for column in source.get_atlas_grid_size().x:
				source.create_tile(Vector2i(column, 0))
			tiles.add_source(source, 0)
			layer.tile_set = tiles
			map.path_layer.add_child(layer)  # Over the path's dual layer and the start's tile
			_dual_layers[kind] = layer
		else:
			(layer.tile_set.get_source(0) as TileSetAtlasSource).texture = load(path)
	_draw_duals()

func has_dual(kind: String) -> bool:
	return _dual_layers.has(kind)

# Bog and roots tiles: every path display tile with a corner on a Mire / rooted cell's halves.
func _draw_duals() -> void:
	if _dual_layers.is_empty() or map == null or map.path_layer == null:
		return
	var halves: Dictionary = map.path_layer.path_halves()
	for kind: String in _dual_layers:
		var layer: TileMapLayer = _dual_layers[kind]
		layer.clear()
		var picked: Array[Vector2] = bog_cells if kind == "bog" else root_cells  # Halves
		if picked.is_empty():
			continue
		var marked := {}
		for h in picked:
			if halves.has(Vector2i(h)):
				marked[Vector2i(h)] = true
		var done := {}
		for h: Vector2i in marked:  # Each marked path half is a corner of 4 display tiles
			for dy in 2:
				for dx in 2:
					var at := h + Vector2i(dx, dy)
					if done.has(at):
						continue
					done[at] = true
					var mask := PathGenerator.dual_mask(halves, at)
					if mask == 15:
						mask = PathGenerator.DUAL_FULL_VARIANTS[EnvironmentTiles.cell_variant(at, PathGenerator.DUAL_FULL_VARIANTS.size(), 7)]
					layer.set_cell(at, 0, Vector2i(mask, 0))

# --- The standing zones -------------------------------------------------------------------------------------------
# Each landmark's reach as a quiet glow on the ground in its colour, so a corner of the maze is built around it. The
# lit paths' rules: on the ground (under everything standing), round and soft (the shared light disc: no squares),
# one disc per landmark so nothing stacks in steps, steady under reduced motion; brighter with a thin rim in build
# mode and while Wardens are selected (Tower.badges_visible), when the player is deciding where to build.
class GiftZones extends Node2D:
	const QUIET := 0.09  # The glow's alpha in play…
	const FULL := 0.2  # …and in build mode / with a selection
	const CHECK := 0.25  # s between looks at the mode
	const BREATH := 0.12  # Share of its alpha the slow breath takes away
	var gifts: MapGifts
	var _disc: Texture2D  # Held here: draw commands don't keep the shared light disc alive
	var _full := false
	var _check := 0.0
	var _time := 0.0
	var _count := -1

	func _ready() -> void:
		_disc = EnvironmentLighting.light_texture()
		gifts.gifts_changed.connect(queue_redraw)

	func _process(delta: float) -> void:
		_time += delta
		_check -= delta
		if _check <= 0.0:
			_check = CHECK
			var full := Tower.badges_visible()
			var count := gifts.landmarks().size()
			if full != _full or count != _count:
				_full = full
				_count = count
				queue_redraw()
		var still := _count <= 0 or bool(Fx.setting("reduced_motion", false))
		modulate.a = 1.0 if still else 1.0 - BREATH * (0.5 + 0.5 * sin(_time * 1.2))  # multiplier (the slow breath: no redraw)

	func _draw() -> void:
		for mark: Dictionary in gifts.landmarks():
			var radius: float = mark.radius
			var colour: Color = mark.color
			var at: Vector2 = mark.at
			var strength := (FULL if _full else QUIET) * clampf(gifts.rise_of(String(mark.id)), 0.0, 1.0)
			# The disc fades to nothing at its rim, so it's drawn a little past the reach and the rim line marks the reach
			var size := Vector2.ONE * radius * 2.3
			draw_texture_rect(_disc, Rect2(at - size / 2.0, size), false, Color(colour, strength * 2.2))
			draw_arc(at, radius, 0.0, TAU, clampi(int(radius / 3.0), 24, 96), Color(colour, strength * (2.0 if _full else 1.0)), 1.5 if _full else 1.0)

# --- The arrival and the grow flourish ----------------------------------------------------------------------------
# The arrival: the Heartwood's roots run along the ground from `from` to `to` (ARRIVAL_ROOTS s), then the landmark
# rises there (ARRIVAL_RISE s; MapGifts._rise) and gift_arrived fires; the roots sink back. Any click or key skips to
# the end. It runs while the game is paused (the gift is taken at a rest). `grow_only`: the act break's flourish, a
# ring out to the zone while the landmark swells into its new step.
class GiftArrival extends Node2D:
	const FADE := 0.6  # s the roots take to sink back
	const WOBBLE := 9.0  # px the root wanders off the straight line
	const STEP := 14.0  # px between the root's points
	var gifts: MapGifts
	var id: StringName
	var from: Vector2
	var to: Vector2
	var grow_only := false
	var ring_radius := 0.0
	var ring_color := Palette.GLOW
	var _time := 0.0
	var _points := PackedVector2Array()
	var _done := false

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		if grow_only:
			gifts._set_rise(id, 0.55)
			return
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([from, to])
		var steps := maxi(int(from.distance_to(to) / STEP), 2)
		var side := (to - from).normalized().orthogonal()
		for i in steps + 1:
			var share := float(i) / steps
			var sway := sin(share * PI) * WOBBLE  # Pinned at both ends
			_points.append(from.lerp(to, share) + side * (sin(share * 11.0 + rng.randf() * 0.6) * sway + rng.randf_range(-2.0, 2.0)))

	func _unhandled_input(event: InputEvent) -> void:
		if grow_only or _done:
			return
		if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed and not event.echo) \
				or (event is InputEventScreenTouch and event.pressed):
			_time = maxf(_time, MapGifts.ARRIVAL_ROOTS + MapGifts.ARRIVAL_RISE)  # Skipped: it stands at once

	func _process(delta: float) -> void:
		_time += delta / maxf(Engine.time_scale, 0.01)  # Real seconds, whatever the game speed
		if grow_only:
			var share := clampf(_time / MapGifts.GROW_RISE, 0.0, 1.0)
			gifts._set_rise(id, 0.55 + 0.45 * share)
			queue_redraw()
			if share >= 1.0:
				gifts._set_rise(id, 1.0)
				queue_free()
			return
		if not _done:
			var rise := clampf((_time - MapGifts.ARRIVAL_ROOTS) / MapGifts.ARRIVAL_RISE, 0.0, 1.0)
			gifts._set_rise(id, rise)
			if rise >= 1.0:
				_done = true
				_time = 0.0
				gifts.gift_arrived.emit(id, to)
		elif _time >= FADE:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		if grow_only:
			var share := clampf(_time / MapGifts.GROW_RISE, 0.0, 1.0)
			draw_arc(to, maxf(ring_radius * share, 4.0), 0.0, TAU, 64, Color(ring_color, 0.7 * (1.0 - share)), 2.0)
			return
		var reach := 1.0 if _done else clampf(_time / MapGifts.ARRIVAL_ROOTS, 0.0, 1.0)
		var alpha := 1.0 - clampf(_time / FADE, 0.0, 1.0) if _done else 1.0
		var shown := maxi(int(_points.size() * reach), 2)
		var line := _points.slice(0, mini(shown, _points.size()))
		if line.size() < 2:
			return
		draw_polyline(line, Color(Palette.ROOT, 0.9 * alpha), 7.0)
		draw_polyline(line, Color(Palette.BARK, alpha), 4.0)
		draw_polyline(line, Color(Palette.OAK, 0.8 * alpha), 1.5)
		if not _done:
			draw_circle(line[line.size() - 1], 5.0, Color(Palette.OAK, alpha))  # The growing tip
