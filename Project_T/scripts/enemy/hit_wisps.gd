extends Node2D

# Hit reactions (enemy_design.md "Hit reactions", owner 2026-10-25: "more enemy reactions on hit"; visual only): the cold
# wisps torn off a hit nightmare, the smoke a frayed one trails and an Armoured kind's shell flakes, for the whole field
# in one node (no node per wisp). It lives in the run's world at z -1 (behind the bodies, above the ground), never under
# %EnemyContainer; a wisp's first FRONT_TIME s draws on a child at z +1, so it shows at the silhouette's edge before it
# slips behind. Art council 2026-10-25: whole-pixel squares (3x3, then 2x2, then 1x1) in ALPHA_STEPS, Wraithlight with a
# Bruise edge (the dark Bruise alone vanished on dark nightmares); at most WISPS_PER_FRAME new bits a frame (flakes and
# smoke count too; WISPS_PER_FRAME_REDUCED at reduced effects) and LIVE_MAX alive. None under reduced motion (Enemy asks
# first). Palette colours only. Enemy finds it with layer(world) (made on first use); preloaded, no class_name.

const META := &"hit_wisps"
const WISPS_PER_FRAME := 24
const WISPS_PER_FRAME_REDUCED := 12
const LIVE_MAX := 160
const FRONT_TIME := 0.12
const ALPHA_STEPS: Array[float] = [0.8, 0.55, 0.3]  # Thirds of its life (no smooth fade: it reads as pixel art)
const SIZE_STEPS: Array[int] = [3, 2, 1]  # Its square, px, by the same thirds
const WISP_LIFE := Vector2(0.4, 0.55)  # Seconds
const WISP_SPEED := Vector2(18.0, 34.0)  # px / s, away from the hit
const WISP_RISE := 14.0  # px / s upward drift
const SMOKE_LIFE := 0.7  # A frayed nightmare's trail: slower and longer
const SMOKE_SPEED := 8.0
const FLAKE_LIFE := 0.45
const FLAKE_SPEED := Vector2(30.0, 55.0)
const FLAKE_GRAVITY := 140.0
const FLAKE_SIZE := 3
enum Kind { WISP, SMOKE, FLAKE }

# Each: [kind, position, velocity, age, life]
var _bits: Array = []
var _frame := -1
var _made_this_frame := 0
var _rng := RandomNumberGenerator.new()
var _front: Node2D = null

static func layer(world: Node) -> Node2D:
	if world == null:
		return null
	if world.has_meta(META):
		var found = world.get_meta(META)
		if is_instance_valid(found):
			return found
	var made: Node2D = (load("res://scripts/enemy/hit_wisps.gd") as GDScript).new()
	made.name = &"HitWisps"
	made.z_index = -1
	world.add_child(made)
	world.set_meta(META, made)
	return made

# Room for `count` more bits this frame (the field-wide cap and LIVE_MAX); returns how many may be made.
func room(count: int) -> int:
	var frame := Engine.get_process_frames()
	if frame != _frame:
		_frame = frame
		_made_this_frame = 0
	var cap := WISPS_PER_FRAME_REDUCED if Fx.reduced() else WISPS_PER_FRAME
	var allowed := clampi(mini(cap - _made_this_frame, LIVE_MAX - _bits.size()), 0, count)
	_made_this_frame += allowed
	return allowed

# `count` cold wisps from `at` (the silhouette's edge), flying along `away` (normalised), spread a little.
func tear(at: Vector2, away: Vector2, count: int) -> void:
	for i in room(count):
		var dir := away.rotated(_rng.randf_range(-0.6, 0.6))
		var vel := dir * _rng.randf_range(WISP_SPEED.x, WISP_SPEED.y) + Vector2(0, -WISP_RISE)
		_bits.append([Kind.WISP, at, vel, 0.0, _rng.randf_range(WISP_LIFE.x, WISP_LIFE.y)])
	_wake()

# One slow smoke wisp off a frayed nightmare.
func smoke(at: Vector2) -> void:
	if room(1) <= 0:
		return
	_bits.append([Kind.SMOKE, at, Vector2(_rng.randf_range(-SMOKE_SPEED, SMOKE_SPEED), -SMOKE_SPEED * 1.5), 0.0, SMOKE_LIFE])
	_wake()

# `count` shell flakes falling away from the hit along `away`.
func flakes(at: Vector2, away: Vector2, count: int) -> void:
	for i in room(count):
		var dir := away.rotated(_rng.randf_range(-0.8, 0.8))
		_bits.append([Kind.FLAKE, at, dir * _rng.randf_range(FLAKE_SPEED.x, FLAKE_SPEED.y) + Vector2(0, -20.0), 0.0, FLAKE_LIFE])
	_wake()

func _wake() -> void:
	set_process(true)
	queue_redraw()
	_front.queue_redraw()

func _ready() -> void:
	_rng.randomize()
	_front = Node2D.new()
	_front.name = &"Front"
	_front.z_index = 2  # (Relative to this layer's -1: +1 in the world)
	_front.draw.connect(_draw_bits.bind(_front, true))
	add_child(_front)
	set_process(false)

func _process(delta: float) -> void:
	var i := _bits.size() - 1
	while i >= 0:  # In place, from the end (no new array a frame)
		var bit: Array = _bits[i]
		bit[3] += delta
		if bit[3] >= bit[4]:
			_bits.remove_at(i)
		else:
			bit[1] += bit[2] * delta
			if bit[0] == Kind.FLAKE:
				bit[2].y += FLAKE_GRAVITY * delta
			else:
				bit[2] *= 1.0 - minf(2.5 * delta, 1.0)  # Wisps slow as they thin
		i -= 1
	queue_redraw()
	_front.queue_redraw()
	if _bits.is_empty():
		set_process(false)

func _draw() -> void:
	_draw_bits(self, false)

# The bits on `canvas`: the young ones (front) or the rest (behind the bodies).
func _draw_bits(canvas: CanvasItem, front: bool) -> void:
	for bit in _bits:
		if (bit[3] < FRONT_TIME) != front:
			continue
		var step := mini(int(3.0 * bit[3] / bit[4]), 2)
		var alpha: float = ALPHA_STEPS[step]
		var at: Vector2 = (bit[1] as Vector2).round()
		if bit[0] == Kind.FLAKE:
			var f := float(FLAKE_SIZE)
			canvas.draw_rect(Rect2(at - Vector2(f, f) / 2.0, Vector2(f, f)).abs(), Color(Palette.DEADWOOD, alpha))
			continue
		var s := float(SIZE_STEPS[step] + (1 if bit[0] == Kind.SMOKE else 0))
		var corner := (at - Vector2(s, s) / 2.0).floor()
		canvas.draw_rect(Rect2(corner - Vector2.ONE, Vector2(s + 2.0, s + 2.0)), Color(Palette.BRUISE, alpha * 0.8))  # The edge
		canvas.draw_rect(Rect2(corner, Vector2(s, s)), Color(Palette.WRAITHLIGHT, alpha))
