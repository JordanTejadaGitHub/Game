extends Node2D
class_name ChargedBolt

# A Charged bolt striking (screens_ui.md "In the world", row "Charged bolt"; user: "should there be a visual
# when the charged pops"): a short jagged bolt drops onto the nightmare from about 1.5 cells above (warm
# gold-white core, 2–3 px, 0.15 s), a small flash and spark burst at the strike (about half a cell); with
# Static Field, a faint ring to its reach. Budget: BUDGET bolts per WINDOW seconds, then the flash only;
# reduce flashes = no flash and a half-bright bolt. Script-only, in the world (Reactions._world), never
# under %EnemyContainer. Lightning Rod keeps its own effect.

const LIFE := 0.15  # The bolt
const FLASH_LIFE := 0.22  # The flash, sparks and Static Field ring
const DROP := 96.0  # 1.5 cells above the strike
const SPARK_REACH := 32.0  # About half a cell
const SPARKS := 6
const BUDGET := 6
const WINDOW := 0.25  # Real seconds

static var _window_start := -1.0
static var _in_window := 0

var _points := PackedVector2Array()
var _sparks: Array[Vector2] = []
var _age := 0.0
var _bolt := true
var _flash := true
var _dim := false
var _field := 0.0

# Plays a strike at `at` in `world`. Returns the effect, or null when there's nothing to show.
static func strike(at: Vector2, world: Node, field_reach: float = 0.0) -> ChargedBolt:
	if world == null or not is_instance_valid(world):
		return null
	var now := Time.get_ticks_msec() / 1000.0
	if now - _window_start > WINDOW:
		_window_start = now
		_in_window = 0
	_in_window += 1
	var reduce := Fx.reduce_flashes()
	var node := ChargedBolt.new()
	node._bolt = _in_window <= BUDGET  # Past the budget: the flash only
	node._flash = not reduce
	node._dim = reduce
	node._field = field_reach
	if not node._bolt and not node._flash and field_reach <= 0.0:
		node.free()
		return null
	node.name = "ChargedBolt"
	node.z_index = 5  # Above the nightmares
	world.add_child(node)
	node.global_position = at
	return node

static func in_window() -> int:
	return _in_window

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_points.append(Vector2(rng.randf_range(-6.0, 6.0), -DROP))
	for i in range(1, 5):
		_points.append(Vector2(rng.randf_range(-8.0, 8.0), -DROP * (1.0 - i / 5.0)))
	_points.append(Vector2.ZERO)
	for i in SPARKS:
		_sparks.append(Vector2.from_angle(TAU * i / SPARKS + rng.randf_range(-0.3, 0.3)) * rng.randf_range(0.7, 1.0))

func _process(delta: float) -> void:
	_age += delta
	if _age >= maxf(LIFE, FLASH_LIFE):
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	if _bolt and _age < LIFE:
		var fade := (1.0 - _age / LIFE) * (0.5 if _dim else 1.0)
		draw_polyline(_points, Color(Palette.GOLD, 0.55 * fade), 5.0)  # The warm glow
		draw_polyline(_points, Color(Palette.HEARTLIGHT, fade), 2.0)  # The gold-white core
	var t := _age / FLASH_LIFE
	if t >= 1.0:
		return
	if _flash:
		draw_circle(Vector2.ZERO, 3.0 + 9.0 * (1.0 - t), Color(Palette.HEARTLIGHT, 0.8 * (1.0 - t)))
		for spark in _sparks:
			draw_line(spark * SPARK_REACH * t * 0.55, spark * SPARK_REACH * t, Color(Palette.GLOW, 1.0 - t), 1.5)
	if _field > 0.0:
		draw_arc(Vector2.ZERO, _field, 0.0, TAU, 40, Color(Palette.GLOW, 0.3 * (1.0 - t)), 1.5)
