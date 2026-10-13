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
	for ring in _rings:
		var t: float = 1.0 - ring[1] / RING_TIME
		draw_arc(to_local(ring[0]), 6.0 + 22.0 * t, 0.0, TAU, 24, Color(Palette.GLOW, 0.8 * (1.0 - t)), 2.0)
