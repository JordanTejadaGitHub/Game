extends Node2D
class_name RootNetworkOverlay

# Root Network (card, rule root_network): the roots between connected Sprouts (user 2026-10-13: "root network doesn't
# look right": thin pale lines over the Wardens and the path, stubs, off-centre ends).
# - One root per connected pair, exactly the pairs the rule counts (DreamEffects.root_pairs: footprints sharing an
#   edge; II: corners too), so there are no stubs, no duplicates and nothing across the path.
# - On the ground: z -1 with the other ground effects, under Wardens and nightmares. Connected Sprouts are side by
#   side, so a root never lies on a path tile.
# - An earthy root (Root / Bark / Deadwood tones), 3 px with a slight wobble and a knot at each end. Kinship vines
#   have leaves and family colours; these don't.
# - Quiet while idle, with a brief pulse along the roots when the network grows or shrinks. It redraws only when the
#   pairs change (the board version), when build mode or a selection starts or ends, and while the pulse runs.
# - Full strength in build mode and on selection, fainter otherwise. The build ghost previews its links (set_ghost).

const KNOT := 3.0  # Radius of the knot at each end, px
const WOBBLE := 3.0  # How far the root strays from the straight line, px
const PULSE_TIME := 0.6
const IDLE_ALPHA := 0.55
const SIDE_REACH := 15.0  # How far in from a Sprout's centre a root starts, towards its neighbour
const BASE_Y := 24.0  # The foot of a Sprout's slab, below its centre

var _pairs: Array = []  # [[Sprout, Sprout]]
var _ghost_at := Vector2.ZERO  # World position of the build ghost's Sprout
var _ghost_links: Array = []  # The Sprouts it would connect to
var _board := -1
var _strong := false
var _pulse := 0.0
var _dreams: Node = null

# The board's overlay, made on first use under the scene that holds `container` (the TowerContainer).
static func find(container: Node) -> RootNetworkOverlay:
	var world: Node = container.owner if container.owner else container.get_parent()
	if world == null:
		return null
	var overlay := world.get_node_or_null("RootNetworkOverlay") as RootNetworkOverlay
	if overlay == null:
		overlay = RootNetworkOverlay.new()
		overlay.name = "RootNetworkOverlay"
		overlay.z_index = -1  # A ground effect: after the map in the tree, so over the grass, under everything that stands
		world.add_child(overlay)
	return overlay

func _dream_state() -> Node:
	if not is_instance_valid(_dreams) and is_inside_tree():
		_dreams = get_tree().get_first_node_in_group(DreamState.GROUP)
	return _dreams

# Looks again at who is connected (the Wardens call this when they are planted, sold or grown).
func refresh() -> void:
	var dreams := _dream_state()
	var pairs: Array = []
	if dreams != null and dreams.has_rule(&"root_network"):
		pairs = dreams.effects().root_pairs()
	if pairs.size() != _pairs.size() and not (_pairs.is_empty() and pairs.is_empty()):
		_pulse = PULSE_TIME  # The network grew or shrank
	_pairs = pairs
	_board = int(dreams.board_version) if dreams != null else -1
	queue_redraw()

# The build ghost: a Sprout at world position `at` would connect to these Sprouts ([] = no preview).
func set_ghost(at: Vector2, links: Array) -> void:
	if links.is_empty() and _ghost_links.is_empty():
		return
	_ghost_at = at
	_ghost_links = links
	queue_redraw()

func _process(delta: float) -> void:
	var dreams := _dream_state()
	if dreams != null and int(dreams.board_version) != _board:
		refresh()
	var strong := Tower.badges_visible()  # Build mode or a selection
	if strong != _strong:
		_strong = strong
		queue_redraw()
	if _pulse > 0.0:
		_pulse = maxf(_pulse - delta, 0.0)
		queue_redraw()

# Each root once: [from, to] in world space (tests count these against the connected pairs).
func get_segments() -> Array:
	var segments: Array = []
	for pair in _pairs:
		if is_instance_valid(pair[0]) and is_instance_valid(pair[1]):
			segments.append(_ends(pair[0].global_position, pair[1].global_position))
	return segments

# Where a root leaves one Sprout's slab and reaches the other's: at the feet of both, each end pulled towards its
# neighbour. A root between an upper and a lower Sprout runs down the left of the lower one, where its sprite
# leaves the ground bare.
static func _ends(a: Vector2, b: Vector2) -> Array:
	if a.y > b.y or (is_equal_approx(a.y, b.y) and a.x > b.x):
		var swap := a
		a = b
		b = swap
	var d := b - a
	if absf(d.y) < absf(d.x):  # Side by side
		return [a + Vector2(SIDE_REACH, BASE_Y), b + Vector2(-SIDE_REACH, BASE_Y)]
	if absf(d.x) < 8.0 or absf(d.x) < absf(d.y) * 0.75:  # One above the other
		return [a + Vector2(-SIDE_REACH, BASE_Y + 2.0), b + Vector2(-SIDE_REACH - 6.0, BASE_Y - 10.0)]
	var side := signf(d.x)  # Corner to corner (Root Network II)
	return [a + Vector2(SIDE_REACH * side, BASE_Y + 2.0), b + Vector2(-SIDE_REACH * side, BASE_Y - 8.0)]

func _draw() -> void:
	var alpha := 1.0 if _strong else IDLE_ALPHA
	for segment in get_segments():
		_draw_root(to_local(segment[0]), to_local(segment[1]), alpha, false)
	for sprout in _ghost_links:
		if is_instance_valid(sprout):
			var ends := _ends(_ghost_at, sprout.global_position)
			_draw_root(to_local(ends[0]), to_local(ends[1]), 0.8, true)

# One root: a dark outline, a bark core, a knot at each end; a pale glint runs along it while the pulse lasts.
func _draw_root(from: Vector2, to: Vector2, alpha: float, preview: bool) -> void:
	var points := _wobbly(from, to)
	if preview:
		draw_polyline(points, Color(Palette.DEADWOOD, alpha), 2.0)
		draw_circle(from, KNOT - 1.0, Color(Palette.DEADWOOD, alpha))
		draw_circle(to, KNOT - 1.0, Color(Palette.DEADWOOD, alpha))
		return
	draw_polyline(points, Color(Palette.ROOT, alpha), 5.0)
	draw_polyline(points, Color(Palette.BARK, alpha), 3.0)
	draw_polyline(points, Color(Palette.OAK, alpha * 0.8), 1.0)
	for end in [from, to]:
		draw_circle(end, KNOT + 1.0, Color(Palette.ROOT, alpha))
		draw_circle(end, KNOT, Color(Palette.BARK, alpha))
		draw_circle(end + Vector2(-1, -1), 1.0, Color(Palette.DEADWOOD, alpha * 0.9))
	if _pulse > 0.0:
		var t := 1.0 - _pulse / PULSE_TIME  # 0 -> 1 along the root
		var at := _along(points, t)
		draw_circle(at, 3.0, Color(Palette.DEADWOOD, 0.9 * (1.0 - absf(t - 0.5) * 1.2)))

# The straight line bent a little, the same way every redraw (seeded by where the root is).
static func _wobbly(from: Vector2, to: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array([from])
	var normal := (to - from).orthogonal().normalized()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector4(roundf(from.x), roundf(from.y), roundf(to.x), roundf(to.y)))
	for i in range(1, 4):
		var t := i / 4.0
		points.append(from.lerp(to, t) + normal * rng.randf_range(-WOBBLE, WOBBLE))
	points.append(to)
	return points

static func _along(points: PackedVector2Array, t: float) -> Vector2:
	var scaled := clampf(t, 0.0, 1.0) * (points.size() - 1)
	var i := mini(int(scaled), points.size() - 2)
	return points[i].lerp(points[i + 1], scaled - i)
