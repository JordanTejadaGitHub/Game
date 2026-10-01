class_name MapLayout
extends RefCounted

# Where a map's start and Heartwood go, and its one feature (environment_assets.md "Map layouts").
# Rolled per seed from the map rng, so a saved run rebuilds the same layout.
# - CORNER (~40%): near a corner to near the opposite one, any of the 4 mirrors, along either axis.
# - SIDE (~35%): one side to the opposite side, along the long axis (left↔right) or the short one
#   (top↔bottom, which gets an extra ridge so its route stays as long).
# - INLET (~25%): start and Heartwood on the same edge with a spine ridge between them: a U-shaped run.
# Start and end are jittered along their edge, never exact corners or midpoints.

enum Kind { CORNER, SIDE, INLET }
enum Feature { POND, RUIN, GROVE, LOG }
const FEATURE_NAMES: Array[String] = ["pond", "ruin", "grove", "fallen log"]
const CORNER_SHARE := 0.4
const SIDE_SHARE := 0.35  # The rest are INLET
const CORNER_JITTER := 3  # Cells in from the corner along its edge (1 + 0..3)
const SIDE_JITTER := 3  # Cells either side of the edge's middle
const INLET_JITTER := 2

var kind: Kind
var start: Vector2i
var end: Vector2i
var ridge_axis: int  # Ridges run along x (0) or y (1); the route mainly crosses them
var short_side := false  # SIDE along the short axis (top↔bottom)
var feature: Feature

# `force_kind` / `force_feature` (-1 = roll) and `force_short` are for tests; the rolls still happen,
# so everything rolled after the layout stays the same.
static func roll(rng: RandomNumberGenerator, size: Vector2i, force_kind: int = -1, force_short: int = -1,
		force_feature: int = -1) -> MapLayout:
	var layout := MapLayout.new()
	var r := rng.randf()
	layout.kind = Kind.CORNER if r < CORNER_SHARE else (Kind.SIDE if r < CORNER_SHARE + SIDE_SHARE else Kind.INLET)
	if force_kind >= 0:
		layout.kind = force_kind as Kind
	var axis := rng.randi_range(0, 1)  # CORNER: the route crosses along x (0) or y (1)
	var flip_a := rng.randf() < 0.5
	var flip_b := rng.randf() < 0.5
	var short_roll := rng.randf() < 0.5
	var jitters := [rng.randi_range(0, 3), rng.randi_range(-3, 3), rng.randi_range(-3, 3), rng.randi_range(-2, 2),
		rng.randi_range(-2, 2), rng.randi_range(0, 3)]
	var inlet_edge := rng.randi_range(0, 3)
	var feature_roll := rng.randi_range(0, 3)
	layout.feature = (feature_roll if force_feature < 0 else force_feature) as Feature
	var w := size.x
	var h := size.y
	match layout.kind:
		Kind.CORNER:
			if axis == 1:  # Top/bottom edges, ridges along x
				var x0: int = 1 + jitters[0] if flip_b else w - 2 - jitters[0]
				var x1: int = w - 2 - jitters[5] if flip_b else 1 + jitters[5]
				layout.start = Vector2i(x0, 0 if flip_a else h - 1)
				layout.end = Vector2i(x1, h - 1 if flip_a else 0)
				layout.ridge_axis = 0
			else:  # Left/right edges, ridges along y
				var y0: int = 1 + jitters[0] if flip_b else h - 2 - jitters[0]
				var y1: int = h - 2 - jitters[5] if flip_b else 1 + jitters[5]
				layout.start = Vector2i(0 if flip_a else w - 1, y0)
				layout.end = Vector2i(w - 1 if flip_a else 0, y1)
				layout.ridge_axis = 1
		Kind.SIDE:
			layout.short_side = short_roll if force_short < 0 else force_short == 1
			if layout.short_side:  # Top ↔ bottom
				layout.start = Vector2i(w / 2 + jitters[1], 0 if flip_a else h - 1)
				layout.end = Vector2i(w / 2 + jitters[2], h - 1 if flip_a else 0)
				layout.ridge_axis = 0
			else:  # Left ↔ right
				layout.start = Vector2i(0 if flip_a else w - 1, h / 2 + jitters[1])
				layout.end = Vector2i(w - 1 if flip_a else 0, h / 2 + jitters[2])
				layout.ridge_axis = 1
		Kind.INLET:
			# Both on one edge, about a quarter and three quarters along it; the spine runs inward between.
			var along_x := inlet_edge < 2  # Top or bottom edge
			var length := w if along_x else h
			var a: int = roundi(length * 0.25) + jitters[3]
			var b: int = roundi(length * 0.75) + jitters[4]
			if flip_b:
				var swap := a
				a = b
				b = swap
			var fixed := 0 if inlet_edge % 2 == 0 else (h - 1 if along_x else w - 1)
			layout.start = Vector2i(a, fixed) if along_x else Vector2i(fixed, a)
			layout.end = Vector2i(b, fixed) if along_x else Vector2i(fixed, b)
			layout.ridge_axis = 1 if along_x else 0  # The spine runs inward from the shared edge
	return layout

func get_kind_name() -> String:
	match kind:
		Kind.CORNER:
			return "corner"
		Kind.SIDE:
			return "side (short)" if short_side else "side (long)"
	return "inlet"

func get_feature_name() -> String:
	return FEATURE_NAMES[feature]

func describe() -> String:
	return "%s · %s" % [get_kind_name(), get_feature_name()]
