extends Node2D
class_name PullDragFx

# The look of a pull (tower_design.md "pulls drag, not teleport"): roots grab the nightmare's feet and
# hold on while it's dragged back along its route, kicking up dust and leaving a furrow on the path,
# then sink. Sheets from effects.json: root_grab (frames 0-2 burst, 3-5 wrap, hold_frames looped while
# dragged, release_frames on release; drawn under the nightmare with a front copy at FRONT_ALPHA),
# drag_dust, path_furrow (tiled along the drag). Stand-in drawing where a sheet is missing. Enemy
# drives it; everything goes in the world, never under the nightmare containers.

enum Kind { GRAB, DUST, FURROW }
enum Phase { WRAP, HOLD, RELEASE }

const FURROW_TIME := 1.0
const DUST_TIME := 0.4
const FRONT_ALPHA := 0.8
const FEET := Vector2(0, 14)  # The ground under a nightmare, from its origin
const ROOT_COLOR := Palette.BARK
const ROOT_LIGHT := Palette.OAK
const DUST_COLOR := Color(Palette.DEADWOOD, 0.7)
const FURROW_COLOR := Color(Palette.ROOT, 0.55)

var kind: Kind
var follow: Node2D  # Grab: stays on the nightmare's feet
var front := false  # Grab: the copy drawn over the nightmare
var phase := Phase.WRAP
var _sheet: StringName
var _entry := {}
var _tex: Texture2D
var _age := 0.0
var _phase_age := 0.0
var _front: PullDragFx

# Roots grab `enemy`'s feet and hold until release(). Returns the node (Enemy keeps it).
static func grab(enemy: Node2D) -> PullDragFx:
	var node := _make(Kind.GRAB, &"root_grab", enemy, enemy.global_position + FEET)
	if node:
		node.follow = enemy
		node.z_index = -1  # Under the nightmares (ground effects)
		var copy := PullDragFx.new()
		copy.kind = Kind.GRAB
		copy.front = true
		copy._set_sheet(&"root_grab")
		copy.z_as_relative = false
		copy.z_index = 2  # Over the nightmare
		copy.modulate.a = FRONT_ALPHA
		node.add_child(copy)
		node._front = copy
	return node

static func dust(enemy: Node2D) -> void:
	var node := _make(Kind.DUST, &"drag_dust", enemy, enemy.global_position + FEET)
	if node:
		node.z_index = 2

# A fading furrow on the path cell at `at` (world), running along `along`.
static func furrow(enemy: Node2D, at: Vector2, along: Vector2) -> void:
	var node := _make(Kind.FURROW, &"path_furrow", enemy, at)
	if node:
		node.z_index = -1
		node.rotation = along.angle() if along.length() > 0.01 else 0.0

static func _make(what: Kind, sheet: StringName, enemy: Node2D, at: Vector2) -> PullDragFx:
	var world := Reactions._world(enemy)
	if world == null and enemy.get_parent() != null:
		world = enemy.get_parent().get_parent()  # Before the run's first Reaction made the tracker
	if world == null:
		return null
	var node := PullDragFx.new()
	node.kind = what
	node._set_sheet(sheet)
	world.add_child(node)
	node.global_position = at
	return node

func _set_sheet(sheet: StringName) -> void:
	_sheet = sheet
	_entry = Fx.info(sheet)
	_tex = Fx.texture(sheet) if not _entry.is_empty() else null
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

# The roots let go: the release frames play, then it's gone.
func release() -> void:
	if phase == Phase.RELEASE:
		return
	phase = Phase.RELEASE
	_phase_age = 0.0
	if _front:
		_front.phase = Phase.RELEASE
		_front._phase_age = 0.0

func _fps() -> float:
	return maxf(float(_entry.get("fps", 12.0)), 1.0)

func _process(delta: float) -> void:
	_age += delta
	_phase_age += delta
	if front:
		queue_redraw()
		return  # The parent moves and frees it
	match kind:
		Kind.GRAB:
			if follow != null and is_instance_valid(follow) and phase != Phase.RELEASE:
				global_position = follow.global_position + FEET
			elif follow == null or not is_instance_valid(follow):
				release()
			if phase == Phase.WRAP and _phase_age * _fps() >= _wrap_frames():
				phase = Phase.HOLD
				_phase_age = 0.0
				if _front:
					_front.phase = Phase.HOLD
					_front._phase_age = 0.0
			if phase == Phase.RELEASE and _phase_age * _fps() >= _release_frames().size():
				queue_free()
				return
		Kind.DUST:
			var frames := int(_entry.get("frames", 1))
			if _age >= (frames / _fps() if _tex else DUST_TIME):
				queue_free()
				return
		Kind.FURROW:
			if _age >= FURROW_TIME:
				queue_free()
				return
	queue_redraw()

func _wrap_frames() -> int:
	var hold: Array = _entry.get("hold_frames", [4, 5])
	return int(hold[-1]) + 1 if _tex else 2  # Burst and wrap: up to the last hold frame

func _release_frames() -> Array:
	return _entry.get("release_frames", [6, 7]) if _tex else [0, 1]

func _grab_frame() -> int:
	var step := int(_phase_age * _fps())
	match phase:
		Phase.WRAP:
			return mini(step, _wrap_frames() - 1)
		Phase.HOLD:
			var hold: Array = _entry.get("hold_frames", [4, 5])
			return int(hold[step % hold.size()])
		_:
			var out := _release_frames()
			return int(out[mini(step, out.size() - 1)])

func _draw() -> void:
	if _tex:
		var size := Vector2(_entry.frame_size[0], _entry.frame_size[1])
		var anchor := Vector2(_entry.anchor[0], _entry.anchor[1])
		match kind:
			Kind.GRAB:
				_draw_frame(size, anchor, _grab_frame(), 1.0)
			Kind.DUST:
				_draw_frame(size, anchor, mini(int(_age * _fps()), int(_entry.frames) - 1), 1.0)
			Kind.FURROW:
				# One cell's worth, centred on the cell, fading out over its last half.
				var fade := clampf(2.0 * (1.0 - _age / FURROW_TIME), 0.0, 1.0)
				draw_texture_rect_region(_tex, Rect2(Vector2(-size.x * 0.5, -anchor.y), size), Rect2(Vector2.ZERO, size),
					Color(1, 1, 1, fade))
		return
	_draw_stand_in()

func _draw_frame(size: Vector2, anchor: Vector2, frame: int, alpha: float) -> void:
	draw_texture_rect_region(_tex, Rect2(-anchor, size), Rect2(Vector2(size.x * frame, 0), size), Color(1, 1, 1, alpha))

func _draw_stand_in() -> void:
	match kind:
		Kind.GRAB:
			var rise := 1.0
			if phase == Phase.WRAP:
				rise = clampf(_phase_age / 0.15, 0.0, 1.0)
			elif phase == Phase.RELEASE:
				rise = 1.0 - clampf(_phase_age * _fps() / 2.0, 0.0, 1.0)
			for i in 4:
				var side := -1.0 if i % 2 == 0 else 1.0
				var x := side * (6.0 + 4.0 * float(i / 2))
				var top := Vector2(x * 0.4, -12.0 * rise)
				draw_line(Vector2(x, 2), top, ROOT_COLOR, 2.5)
				draw_line(Vector2(x, 2), top, ROOT_LIGHT, 1.0)
		Kind.DUST:
			var t := clampf(_age / DUST_TIME, 0.0, 1.0)
			var colour := DUST_COLOR
			colour.a *= 1.0 - t
			for i in 3:
				draw_circle(Vector2.from_angle(PI + (float(i) - 1.0) * 0.6) * 10.0 * t, 3.0 + 4.0 * t, colour)
		Kind.FURROW:
			var t := clampf(_age / FURROW_TIME, 0.0, 1.0)
			var colour := FURROW_COLOR
			colour.a *= 1.0 - t * t
			draw_line(Vector2(-26, -3), Vector2(26, -3), colour, 3.0)
			draw_line(Vector2(-26, 4), Vector2(26, 4), colour, 3.0)
