class_name MapLayout
extends RefCounted

# Where a map's start and Heartwood go, and its one feature (environment_assets.md "Map layouts" and
# "Inland Heartwood"). Rolled per seed from the map rng, so a saved run rebuilds the same layout.
# - The start is on the island's edge: CORNER (~50%: 1-4 cells in from a corner, any of the four,
#   along either edge) or SIDE (~50%: an edge's middle ±3, any of the four edges).
# - The Heartwood is inland: a random cell at least EDGE_MARGIN from every edge, in the half of the map
#   away from the start (split by the line through the centre perpendicular to start→centre), at least
#   half the map's diagonal from the start (else among the farthest), uniform among those that qualify.

enum Kind { CORNER, SIDE }
enum Feature { POND, RUIN, GROVE, LOG }
const FEATURE_NAMES: Array[String] = ["pond", "ruin", "grove", "fallen log"]
const CORNER_SHARE := 0.5  # The rest are SIDE starts
const CORNER_JITTER := 3  # Cells in from the corner along its edge (1 + 0..3)
const SIDE_JITTER := 3  # Cells either side of the edge's middle
const EDGE_MARGIN := 2  # The Heartwood keeps this many cells from every edge
const MIN_DISTANCE_SHARE := 0.5  # Of the map's diagonal, from the start
const FALLBACK_COUNT := 6  # If no cell is far enough: one of this many farthest
const BEND_REACH_SHARE := 0.75  # The bend spur's longest reach across (EnvironmentObjectGenerator reads it)
const BEND_EXTRA := 10  # The opening route's floor over the start→Heartwood Manhattan distance (Balancing 2026-10-05: was 4)

var kind: Kind
var start: Vector2i
var end: Vector2i  # The Heartwood's cell (inland)
var ridge_axis: int  # Ridges run along x (0) or y (1); the route mainly crosses them, start → Heartwood
var short_side := false  # The start is on the top or bottom edge
var heartwood_fallback := false  # No cell was far enough; the Heartwood is among the farthest
var feature: Feature

# `force_kind` / `force_feature` (-1 = roll) and `force_short` (1 = a top/bottom start, 0 = left/right)
# are for tests; the rolls still happen, so everything rolled after the layout stays the same.
static func roll(rng: RandomNumberGenerator, size: Vector2i, force_kind: int = -1, force_short: int = -1,
		force_feature: int = -1) -> MapLayout:
	var layout := MapLayout.new()
	layout.kind = Kind.CORNER if rng.randf() < CORNER_SHARE else Kind.SIDE
	if force_kind >= 0:
		layout.kind = force_kind as Kind
	var edge := rng.randi_range(0, 3)  # 0 top, 1 bottom, 2 left, 3 right
	var flip := rng.randf() < 0.5  # Which end of the edge a corner start is near
	var corner_in := rng.randi_range(0, CORNER_JITTER)
	var side_offset := rng.randi_range(-SIDE_JITTER, SIDE_JITTER)
	var feature_roll := rng.randi_range(0, 3)
	layout.feature = (feature_roll if force_feature < 0 else force_feature) as Feature
	if force_short >= 0:
		edge = edge % 2 + (0 if force_short == 1 else 2)
	var along_x := edge < 2  # The start's edge runs along x (top or bottom)
	var length := size.x if along_x else size.y
	var along: int = length / 2 + side_offset
	if layout.kind == Kind.CORNER:
		along = 1 + corner_in if flip else length - 2 - corner_in
	var fixed := 0 if edge % 2 == 0 else (size.y - 1 if along_x else size.x - 1)
	layout.start = Vector2i(along, fixed) if along_x else Vector2i(fixed, along)
	layout.short_side = along_x
	layout.end = layout._pick_heartwood(rng, size)
	var travel := layout.end - layout.start
	layout.ridge_axis = 1 if absi(travel.x) >= absi(travel.y) else 0
	return layout

# One random inland cell in the far half, far enough from the start (else one of the farthest).
func _pick_heartwood(rng: RandomNumberGenerator, size: Vector2i) -> Vector2i:
	var centre := Vector2(size - Vector2i.ONE) / 2.0
	var away := centre - Vector2(start)
	var reach := Vector2(size).length() * MIN_DISTANCE_SHARE
	var candidates: Array[Vector2i] = []
	var far: Array[Vector2i] = []
	for x in range(EDGE_MARGIN, size.x - EDGE_MARGIN):
		for y in range(EDGE_MARGIN, size.y - EDGE_MARGIN):
			var cell := Vector2i(x, y)
			if (Vector2(cell) - centre).dot(away) <= 0.0:
				continue  # The start's half
			candidates.append(cell)
			if Vector2(cell - start).length() >= reach:
				far.append(cell)
	if far.is_empty():
		heartwood_fallback = true
		candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return Vector2(a - start).length() > Vector2(b - start).length())
		far = candidates.slice(0, FALLBACK_COUNT)
	var pick := far[rng.randi_range(0, far.size() - 1)]
	if not bend_fits(start, pick, size):
		# Room to maze (environment_assets.md): the opening route's one bend spur must be able to cut the
		# start→Heartwood box. Only the rare corner-to-near-corner rolls land here; they re-roll among the
		# spots where it fits (every other map keeps its Heartwood).
		var fits := far.filter(func(c: Vector2i) -> bool: return bend_fits(start, c, size))
		if fits.is_empty():
			fits = candidates.filter(func(c: Vector2i) -> bool: return bend_fits(start, c, size))
		if not fits.is_empty():
			pick = fits[rng.randi_range(0, fits.size() - 1)]
	return pick

# True if a bend spur from one wall, at most BEND_REACH_SHARE across, can cut the start→`end` box with its
# tip BEND_EXTRA / 2 cells past it (EnvironmentObjectGenerator._generate_ridges: the opening route bends at +BEND_EXTRA or more).
static func bend_fits(start_cell: Vector2i, end_cell: Vector2i, size: Vector2i) -> bool:
	var travel := end_cell - start_cell
	var axis := 1 if absi(travel.x) >= absi(travel.y) else 0  # As ridge_axis: the spurs run along u
	var lo := mini(start_cell.x, end_cell.x) if axis == 0 else mini(start_cell.y, end_cell.y)
	var hi := maxi(start_cell.x, end_cell.x) if axis == 0 else maxi(start_cell.y, end_cell.y)
	var inner := (size.x if axis == 0 else size.y) - 2
	var k := BEND_EXTRA / 2  # The tip sits k cells past the box: a way round it costs 2k
	return mini(hi + k - 1, inner - lo + k) <= roundi(inner * BEND_REACH_SHARE)

func get_kind_name() -> String:
	return "corner" if kind == Kind.CORNER else "side"

func get_feature_name() -> String:
	return FEATURE_NAMES[feature]

func describe() -> String:
	return "%s · %s" % [get_kind_name(), get_feature_name()]
