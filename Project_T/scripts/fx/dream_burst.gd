extends Node2D

# Selective Dream bursts: source footprint only, no damage or callouts. Existing cues coalesce
# without resetting their lifetime so dense cascades cannot keep a permanent ring on the field.
const GROUP := &"dream_burst_fx"
const LIFE := 0.42
const MAX_ACTIVE := 12
const REDUCED_MAX_ACTIVE := 4
const COALESCE_DISTANCE := 24.0
var _kind: StringName
var _radius: float
var _age := 0.0
var _still := false
var _reduced := false
var _soft := false

static func play(kind: StringName, at: Vector2, radius: float, world: Node) -> Node2D:
	if not is_instance_valid(world) or not world.is_inside_tree() or radius <= 0.0 or not Fx.on_screen(at, radius):
		return null
	var active := world.get_tree().get_nodes_in_group(GROUP)
	for cue in active:
		if cue.get_parent() == world and not cue.is_queued_for_deletion() and cue._kind == kind \
				and cue.global_position.distance_to(at) <= COALESCE_DISTANCE and is_equal_approx(cue._radius, radius):
			return cue
	var cap := REDUCED_MAX_ACTIVE if Fx.reduced() else MAX_ACTIVE
	if active.size() >= cap:
		return null
	var cue := new(kind, radius)
	world.add_child(cue)
	cue.global_position = at
	return cue

func _init(kind: StringName, radius: float) -> void:
	_kind = kind
	_radius = radius
	top_level = true
	z_index = -1
	_still = bool(Fx.setting("reduced_motion", false))
	_reduced = Fx.reduced()
	_soft = Fx.reduce_flashes()

func _ready() -> void:
	add_to_group(GROUP)

func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFE:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var progress := clampf(_age / LIFE, 0.0, 1.0)
	var alpha := (0.35 if _soft else 0.55) * (1.0 - progress)
	var colour := Palette.GLOW
	match _kind:
		&"spillover": colour = Palette.SPRIG
		&"shattering_blow": colour = Palette.MOONLIGHT
		&"last_breath": colour = Palette.BLOSSOM
		&"overlap": colour = Palette.HEARTLIGHT
	var radius := _radius if _still else lerpf(_radius * 0.45, _radius, 1.0 - pow(1.0 - progress, 3.0))
	if _kind == &"shattering_blow":
		# Broken arcs read as shards, distinct from the continuous ripple / dispel halo.
		for i in range(6):
			draw_arc(Vector2.ZERO, radius, TAU * i / 6.0, TAU * (i + 0.65) / 6.0, 8, Color(colour, alpha), 2.0)
	else:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(colour, alpha), 2.0)
	if _reduced:
		return
	if _kind == &"dawnbreak":
		for i in range(8):
			var direction := Vector2.from_angle(TAU * i / 8.0)
			draw_line(direction * radius * 0.8, direction * radius, Color(colour, alpha), 2.0)
	elif _kind == &"overlap":
		draw_arc(Vector2(-4, 0), radius * 0.65, -PI / 2.0, PI / 2.0, 24, Color(colour, alpha), 2.0)
		draw_arc(Vector2(4, 0), radius * 0.65, PI / 2.0, PI * 1.5, 24, Color(colour, alpha), 2.0)
	elif _kind == &"last_breath":
		draw_arc(Vector2.ZERO, radius * 0.82, 0.0, TAU, 48, Color(colour, alpha * 0.45), 1.0)
	elif _kind == &"spillover":
		for i in range(4):
			draw_circle(Vector2.from_angle(TAU * i / 4.0) * radius, 2.0, Color(colour, alpha))
