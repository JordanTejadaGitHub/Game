extends Node2D

# Sunlit Rest's mark (story chat, user: "should have an icon of which Warden would get the free Nurture upgrade"):
# a small, quiet sun at the base of the Warden(s) the next rest gives a free rank, shown during drifts and rests
# (the player plans around it). It follows DreamState.sunlit_targets (the rule's own order and ties), polled a few
# times a second, so it moves when planting or selling changes who is nearest the Heartwood. When the rest banks the
# rank, a soft ring opens on that Warden. Reduced motion: no breathing, no ring.

const POLL := 0.25  # Seconds between looks at the targets
const RING_TIME := 0.9

var dream_state: Node  # DreamState (untyped: DreamState preloads this script)
var _targets: Array[Tower] = []
var _wait := 0.0
var _time := 0.0
var _rings: Array = []  # [world position, seconds left]
var _waiting: Array = []  # [Tower, ranks banked]: a small "+N" over each Warden with free ranks waiting to be Nurtured
const WAITING_SIZE := 13
const WAITING_LIFT := 16.0  # px above the sun's spot
var _wild: Array = []  # [Tower, share filled 0..1]: Wild Growth's ring at each Warden's base (a bud when ripe)
const WILD_RING_R := 9.0

func _ready() -> void:
	z_index = 2  # Over the Wardens' sprites (y-sorted at 0), under the lighting (3)
	if dream_state:
		dream_state.sunlit_granted.connect(_on_granted)

func _process(delta: float) -> void:
	_time += delta
	_wait -= delta
	if _wait <= 0.0:
		_wait = POLL
		var now: Array[Tower] = []
		if dream_state and dream_state.has_rule(&"sunlit_rest"):
			now = dream_state.sunlit_targets()
		if now != _targets:
			_targets = now
			queue_redraw()
		var wild := _wild_now()
		if wild != _wild:
			_wild = wild
			queue_redraw()
		var waiting := _banked_now()
		if waiting != _waiting:
			_waiting = waiting
			queue_redraw()
	for ring in _rings:
		ring[1] -= delta
	_rings = _rings.filter(func(ring: Array) -> bool: return ring[1] > 0.0)
	if not _targets.is_empty() and not _reduced() or not _rings.is_empty():
		queue_redraw()

func _reduced() -> bool:
	return bool(Fx.setting("reduced_motion", false))

# Where the sun sits on a Warden: its tile's right edge, above the Nurture dew hint (GrowHints, y 6–22: at y 12 the
# sun sat on top of it) and below the target pip (Tower Code, the user 2026-10-12: one slot per mark; the card badges
# run up the left edge).
static func spot_on(tower: Tower) -> Vector2:
	var half := Vector2(Tower.MAP_GRID.cell_size) / 2.0
	return tower.global_position + Vector2(half.x - 9.0, -4.0)

# Every Warden with ranks banked and not yet Nurtured (Hard-Won Rings, Sunlit Rest, Growth Rings…; owner 2026-10-20: banked
# ranks stack, "make that visible").
# Wild Growth (Legendary): every Warden it applies to, with how full its count is.
func _wild_now() -> Array:
	var out: Array = []
	if dream_state == null or not dream_state.has_rule(&"wild_growth"):
		return out
	for tower in get_tree().get_nodes_in_group(Tower.GROUP):
		if dream_state.batch.wild_applies(tower):
			var need: int = dream_state.batch.wild_need(tower)
			out.append([tower, snappedf(minf(float(dream_state.batch.wild_of(tower)) / maxf(need, 1), 1.0), 0.01)])
	return out

func _banked_now() -> Array:
	var out: Array = []
	for tower in get_tree().get_nodes_in_group(Tower.GROUP):
		if tower is Tower and is_instance_valid(tower) and tower.banked_ranks > 0:
			out.append([tower, tower.banked_ranks])
	return out

func get_targets() -> Array[Tower]:
	return _targets

func _on_granted(towers: Array) -> void:
	if _reduced():
		return
	for tower in towers:
		if is_instance_valid(tower):
			_rings.append([spot_on(tower), RING_TIME])

func _draw() -> void:
	var breath := 1.0 if _reduced() else 0.85 + 0.15 * sin(_time * 1.6)
	for tower in _targets:
		if not is_instance_valid(tower):
			continue
		var at := to_local(spot_on(tower))
		for i in 8:  # Short rays
			var dir := Vector2.RIGHT.rotated(TAU * i / 8.0)
			draw_line(at + dir * 4.5, at + dir * 6.5, Color(Palette.GLOW, 0.6 * breath), 1.0)
		draw_circle(at, 3.5, Color(Palette.GOLD, 0.85 * breath))
		draw_circle(at, 2.0, Color(Palette.HEARTLIGHT, 0.7 * breath))
	for row in _wild:  # Wild Growth: a thin ring at the base fills with its count; ripe, a bud
		if not is_instance_valid(row[0]):
			continue
		var base := to_local(row[0].global_position) + Vector2(0.0, Tower.MAP_GRID.cell_size.y * 0.32)
		var fill: float = row[1]
		draw_arc(base, WILD_RING_R, 0.0, TAU, 24, Color(Palette.DEEPMOSS, 0.6), 2.0)
		if fill > 0.0:
			draw_arc(base, WILD_RING_R, -PI / 2.0, -PI / 2.0 + TAU * fill, 24, Color(Palette.NEWLEAF, 0.9), 2.0)
		if fill >= 1.0:
			draw_circle(base, 4.0, Palette.NEWLEAF)
			draw_circle(base + Vector2(-1.0, -1.0), 1.5, Palette.HEARTLIGHT)
	var font := UiStyle.number_font()
	for row in _waiting:
		if not is_instance_valid(row[0]):
			continue
		var text := "+%d" % int(row[1])
		var at := to_local(spot_on(row[0])) + Vector2(-4.0, -WAITING_LIFT)
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, WAITING_SIZE, 3, Palette.NIGHT)
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, WAITING_SIZE, Palette.GOLD)
	for ring in _rings:
		var t: float = 1.0 - ring[1] / RING_TIME
		draw_arc(to_local(ring[0]), 6.0 + 22.0 * t, 0.0, TAU, 24, Color(Palette.GLOW, 0.8 * (1.0 - t)), 2.0)
