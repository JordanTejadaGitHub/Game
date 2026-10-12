extends Node2D

# Visual timing is released by the damage timer, never by a second gameplay clock.
const GROUP := &"great_ripple_fx"
const MAX_ACTIVE := 12
const REDUCED_MAX_ACTIVE := 4
const AFTERSHOCK_TIME := 0.4
const SAFETY_MARGIN := 0.5
var _radius: float
var _delay: float
var _age := 0.0
var _released := false
var _still := false
var _soft := false
var _reduced := false

static func play(radius: float, delay: float, at: Vector2, world: Node) -> Node2D:
	if not is_instance_valid(world) or not world.is_inside_tree() or not Fx.on_screen(at, radius):
		return null
	var cap := REDUCED_MAX_ACTIVE if Fx.reduced() else MAX_ACTIVE
	if world.get_tree().get_nodes_in_group(GROUP).size() >= cap:
		return null
	var cue := new(radius, delay)
	world.add_child(cue)
	cue.global_position = at
	return cue

func _ready() -> void:
	add_to_group(GROUP)

func _init(radius: float, delay: float) -> void:
	_radius = radius
	_delay = delay
	top_level = true
	z_index = -1
	_still = bool(Fx.setting("reduced_motion", false))
	_soft = Fx.reduce_flashes()
	_reduced = Fx.reduced()

func release() -> void:
	_released = true
	_age = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	_age += delta
	if _age >= (AFTERSHOCK_TIME if _released else _delay + SAFETY_MARGIN):
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	if not _released:
		var progress := clampf(_age / maxf(_delay, 0.001), 0.0, 1.0)
		draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 64, Color(Palette.DEWLIGHT, 0.22), 1.5)
		if not _still and not _reduced:
			draw_arc(Vector2.ZERO, _radius, -PI / 2.0, -PI / 2.0 + TAU * progress, 64, Color(Palette.DEWLIGHT, 0.4), 2.0)
	else:
		var progress := clampf(_age / AFTERSHOCK_TIME, 0.0, 1.0)
		var fade := 1.0 - progress
		var alpha := (0.4 if _soft else 0.65) * fade
		draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 64, Color(Palette.DEWLIGHT, alpha), 3.0)
		if _reduced:
			return
		var inner := _radius if _still else lerpf(_radius * 0.65, _radius, progress)
		draw_arc(Vector2.ZERO, inner, 0.0, TAU, 64, Color(Palette.MOONLIGHT, alpha * 0.5), 1.5)
