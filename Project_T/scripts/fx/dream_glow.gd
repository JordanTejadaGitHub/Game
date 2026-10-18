extends RefCounted
# Boosted-attack glow (visual feedback spec B, owner-approved 2026-10-18; D:\Projects\logs\dream_council\
# visual_feedback_spec.md): a Warden's Dream card power (DreamState.boost_tier, Roguelite Code: 0..3, cached there per
# board / card change) adds a warm trace to its attack, on top of the family's own look and never replacing it.
# Per kind: a trail on projectiles, a rim line on pulses, a bright core on chains and beams, motes in clouds, glints on
# traps. Tier 3 adds a launch flare (dream_flare, or a drawn bloom until the sheet exists) and a steady glow under the
# Warden (EnvironmentLighting). Colour: HEARTLIGHT, GLOW only at tier 3, always over a darker EMBER / DUSK edge so it
# reads on the pale sand path (owner). Also the cue set's Reaction accent (C5: Fx.reaction) and reach ring (C6).
# Preloaded as DREAM_GLOW (no class_name). Nothing here runs per frame: the tier is read once per attack (Tower._release,
# a beam's start) and the drawing rides on redraws the effects already do.

const CORE := Palette.HEARTLIGHT
const GOLD_CORE := Palette.GLOW  # Tier 3 only (gold already means crits and the Acorn aura)
const EDGE := Palette.EMBER  # The darker ember edge under every trace: pale-on-pale vanished on the act 1 path (owner)
const DUSK_EDGE := Palette.DUSK  # The outer dusk line under the ember on the brightest traces
const FLARE_EVERY_MS := 500  # Tier 3's launch flare: once per Warden per 0.5 s (spec B6), and Fx.bright_flash_ok
const FLARE_EFFECT := &"dream_flare"  # Tower Assets' sheet (spec D); a drawn bloom stands in until it exists
const TRAIL_SAMPLES: Array[int] = [0, 3, 5, 5]
const ALPHA: Array[float] = [0.0, 0.35, 0.6, 0.8]
const FORCE_META := &"dream_glow_force"  # A test sets this meta on a Warden to force its tier

# The tier this Warden's attacks show now (0..3), the setting and quality applied: "Dream effects on attacks"
# (`dream_effects` 0 Full / 1 Subtle = tier 1 at most / 2 Off) and Reduced effects quality (tier 1 at most).
static func tier_for(tower) -> int:
	if tower == null or not is_instance_valid(tower):
		return 0
	if tower.has_meta(FORCE_META):  # Tests (test_perf_stress: 40 tier-3 Wardens)
		return int(tower.get_meta(FORCE_META))
	var dreams = tower._dream_state
	if dreams == null or not dreams.has_method(&"boost_tier"):
		return 0
	var mode := int(Fx.setting("dream_effects", 0))
	if mode == 2:
		return 0
	var tier: int = dreams.boost_tier(tower)
	if mode == 1 or Fx.reduced():
		tier = mini(tier, 1)
	return clampi(tier, 0, 3)

static func core(tier: int) -> Color:
	return GOLD_CORE if tier >= 3 else CORE

static func alpha(tier: int) -> float:
	return ALPHA[clampi(tier, 0, 3)]

# A line with the trace: dusk + ember edge under a 1-2 px warm core. `width` = the core's.
static func line(canvas: CanvasItem, a: Vector2, b: Vector2, tier: int, fade: float = 1.0, width: float = 1.0) -> void:
	if tier <= 0:
		return
	var al := alpha(tier) * fade
	if tier >= 2:
		canvas.draw_line(a, b, Color(DUSK_EDGE, 0.45 * al), width + 4.0)
	canvas.draw_line(a, b, Color(EDGE, 0.8 * al), width + 2.0)
	canvas.draw_line(a, b, Color(core(tier), minf(al * 1.3, 1.0)), width)

static func polyline(canvas: CanvasItem, points: PackedVector2Array, tier: int, fade: float = 1.0, width: float = 1.0) -> void:
	if tier <= 0 or points.size() < 2:
		return
	var al := alpha(tier) * fade
	if tier >= 2:
		canvas.draw_polyline(points, Color(DUSK_EDGE, 0.45 * al), width + 4.0)
	canvas.draw_polyline(points, Color(EDGE, 0.8 * al), width + 2.0)
	canvas.draw_polyline(points, Color(core(tier), minf(al * 1.3, 1.0)), width)

# A warm dot with its ember edge (motes, trail samples, sparkles).
static func dot(canvas: CanvasItem, at: Vector2, radius: float, tier: int, fade: float = 1.0) -> void:
	if tier <= 0:
		return
	var al := alpha(tier) * fade
	canvas.draw_circle(at, radius + 1.0, Color(EDGE, 0.75 * al))
	canvas.draw_circle(at, radius, Color(core(tier), minf(al * 1.3, 1.0)))

# A ring rim (pulses: one inner line on the ring).
static func rim(canvas: CanvasItem, centre: Vector2, radius: float, tier: int, fade: float = 1.0) -> void:
	if tier <= 0 or radius <= 2.0:
		return
	var points := clampi(int(radius / 3.0), 24, 160)
	var al := alpha(tier) * fade
	canvas.draw_arc(centre, radius, 0.0, TAU, points, Color(EDGE, 0.8 * al), 3.0, false)
	canvas.draw_arc(centre, radius, 0.0, TAU, points, Color(core(tier), minf(al * 1.3, 1.0)), 1.0, false)

# A projectile's trail drawn behind its head (`head` local, `dir` its flight direction in local space): TRAIL_SAMPLES dots
# back along the flight, fading. Drawn in one go, so the projectile needs no redraw beyond its sheet's frames.
const TRAIL_STEP := 4.0  # px between dots
static func trail_behind(canvas: CanvasItem, head: Vector2, dir: Vector2, tier: int) -> void:
	var samples: int = TRAIL_SAMPLES[clampi(tier, 0, 3)]
	for i in samples:
		var t := 1.0 - float(i + 1) / (samples + 1)
		dot(canvas, head - dir * TRAIL_STEP * (i + 1), 1.0 + 1.5 * t, tier, t)

# Motes: `count` warm dots spread over a radius at time `t` (s), slowly turning (clouds, a pulse's tier 2 fling).
static func motes(canvas: CanvasItem, centre: Vector2, radius: float, count: int, tier: int, t: float, fade: float = 1.0) -> void:
	for i in count:
		var angle := TAU * i / count + t * 0.7 + i * 1.3
		var r := radius * (0.35 + 0.45 * fposmod(i * 0.618 + t * 0.15, 1.0))
		dot(canvas, centre + Vector2.from_angle(angle) * Vector2(r, r * 0.7) + Vector2(0, sin(t * 2.0 + i) * 2.0), 1.0, tier, fade)

# Glints: `count` short warm sparks passing round a radius (traps, a cloud's edge at tier 2).
static func glints(canvas: CanvasItem, centre: Vector2, radius: float, count: int, tier: int, t: float, fade: float = 1.0) -> void:
	if tier <= 0:
		return
	for i in count:
		var angle := TAU * i / count + t * 1.1
		var at := centre + Vector2.from_angle(angle) * radius
		var dir := Vector2.from_angle(angle + PI / 2.0) * 2.5
		line(canvas, at - dir, at + dir, tier, fade)

# Tier 3's launch flare at `at` (world): once per Warden per FLARE_EVERY_MS, counted as a bright flash; none under
# Reduce flashes or off screen.
static func flare(tower: Node2D, at: Vector2, tier: int) -> void:
	if tier < 3 or tower == null or not is_instance_valid(tower) or Fx.reduce_flashes() or not Fx.on_screen(at):
		return
	var now := Time.get_ticks_msec()
	if now - int(tower.get_meta(&"dream_flare_at", -FLARE_EVERY_MS)) < FLARE_EVERY_MS:
		return
	if not Fx.bright_flash_ok():
		return
	tower.set_meta(&"dream_flare_at", now)
	var world := Reactions._world(tower)
	if world == null:
		return
	if Fx.has_effect(FLARE_EFFECT):
		Fx.play(FLARE_EFFECT, at, world)
		return
	var bloom := Bloom.new()
	world.add_child(bloom)
	bloom.global_position = at

# The stand-in flare: a soft four-point warm bloom (never star-shaped like crit_flare), 0.25 s.
class Bloom extends Node2D:
	const LIFE := 0.25
	var _age := 0.0

	func _init() -> void:
		z_index = Fx.Z + 1

	func _process(delta: float) -> void:
		_age += delta
		if _age >= LIFE:
			queue_free()
		else:
			queue_redraw()

	func _draw() -> void:
		var t := _age / LIFE
		var fade := 1.0 - t
		var r := 5.0 + 7.0 * t
		draw_circle(Vector2.ZERO, r + 2.0, Color(EDGE, 0.5 * fade))
		draw_circle(Vector2.ZERO, r, Color(GOLD_CORE, 0.55 * fade))
		draw_circle(Vector2.ZERO, r * 0.45, Color(CORE, 0.9 * fade))
		for i in 4:
			var dir := Vector2.from_angle(TAU * i / 4.0 + PI / 4.0) * (r + 4.0)
			draw_line(dir * 0.3, dir, Color(EDGE, 0.6 * fade), 3.0)
			draw_line(dir * 0.3, dir, Color(CORE, 0.85 * fade), 1.0)

# --- C6 Reach ring: the real range shown once (a range or aura card taken, and each drift start) --------------------

const RING_LIFE := 0.6
const RING_ALPHA := 0.25

# Every Warden whose range Dream cards widen (DreamState.get_range_bonus), or only `tower` when given.
static func reach_rings(tree: SceneTree, tower: Node = null) -> void:
	if tree == null or int(Fx.setting("dream_effects", 0)) == 2:
		return
	var towers: Array = [tower] if tower is Tower else tree.get_nodes_in_group(Tower.GROUP)
	for t in towers:
		if not (t is Tower) or not is_instance_valid(t) or t.tower_data == null or not t.tower_data.can_attack:
			continue
		if tower == null and (t._dream_state == null or t._dream_state.get_range_bonus(t.tower_data) <= 0.0):
			continue
		if not Fx.on_screen(t.global_position, t.get_range_pixels()):
			continue
		var world := Reactions._world(t)
		if world == null:
			continue
		var ring := ReachRing.new(t.get_range_pixels())
		world.add_child(ring)
		ring.global_position = t.global_position

class ReachRing extends Node2D:
	var _radius := 0.0
	var _age := 0.0

	func _init(radius: float) -> void:
		_radius = radius
		z_index = -1  # On the ground, like the range rings

	func _process(delta: float) -> void:
		_age += delta
		if _age >= RING_LIFE:
			queue_free()
		else:
			queue_redraw()

	func _draw() -> void:
		var t := _age / RING_LIFE
		var fade := sin(t * PI)  # In and out
		var points := clampi(int(_radius / 3.0), 32, 160)
		draw_arc(Vector2.ZERO, _radius, 0.0, TAU, points, Color(EDGE, RING_ALPHA * 1.6 * fade), 3.0, false)
		draw_arc(Vector2.ZERO, _radius, 0.0, TAU, points, Color(CORE, RING_ALPHA * 2.4 * fade), 1.0, false)
