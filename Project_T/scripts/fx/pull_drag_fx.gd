extends Node2D
class_name PullDragFx

# The look of a pull (tower_design.md "pulls drag, not teleport"): roots grab the nightmare's feet, it's
# dragged back along its route kicking up dust and leaving a furrow on the path, then the roots sink.
# Plays the root_grab / drag_dust / path_furrow sheets from effects.json once they exist; until then
# draws a simple stand-in. Enemy.push_back drives it; everything goes in the world, never under the
# nightmare containers.

enum Kind { GRAB, RELEASE, DUST, FURROW }

const GRAB_TIME := 0.15
const RELEASE_TIME := 0.15
const DUST_TIME := 0.4
const FURROW_TIME := 1.0
const ROOT_COLOR := Color(0.36, 0.25, 0.16)
const ROOT_LIGHT := Color(0.55, 0.42, 0.26)
const DUST_COLOR := Color(0.72, 0.62, 0.46, 0.7)
const FURROW_COLOR := Color(0.2, 0.14, 0.09, 0.55)
const FEET := Vector2(0, 14)  # Roots wrap this far below the nightmare's origin

var kind: Kind
var follow: Node2D  # Grab / release stay on the nightmare's feet
var direction := Vector2.RIGHT  # Furrow: along the drag
var _age := 0.0
var _life := 0.0

static func grab(enemy: Node2D) -> void:
	_make(Kind.GRAB, &"root_grab", enemy, enemy.global_position + FEET)

static func release(enemy: Node2D) -> void:
	_make(Kind.RELEASE, &"root_grab", enemy, enemy.global_position + FEET)

static func dust(enemy: Node2D) -> void:
	_make(Kind.DUST, &"drag_dust", enemy, enemy.global_position + FEET)

# A fading furrow on the path cell at `at` (world), running along `along`.
static func furrow(enemy: Node2D, at: Vector2, along: Vector2) -> void:
	var node := _make(Kind.FURROW, &"path_furrow", enemy, at)
	if node:
		node.direction = along.normalized() if along.length() > 0.01 else Vector2.RIGHT
		node.rotation = node.direction.angle()

static func _make(what: Kind, sheet: StringName, enemy: Node2D, at: Vector2) -> PullDragFx:
	var world := Reactions._world(enemy)
	if world == null:
		world = enemy.get_parent().get_parent() if enemy.get_parent() else null  # Before the first Reaction
	if world == null:
		return null
	if not Fx.info(sheet).is_empty() and what != Kind.RELEASE:
		var played := Fx.play(sheet, at, world)
		if played and what == Kind.FURROW:
			played.z_index = -1
		return null
	var node := PullDragFx.new()
	node.kind = what
	node.follow = enemy if what in [Kind.GRAB, Kind.RELEASE] else null
	node._life = {Kind.GRAB: GRAB_TIME, Kind.RELEASE: RELEASE_TIME, Kind.DUST: DUST_TIME, Kind.FURROW: FURROW_TIME}[what]
	node.z_index = -1 if what == Kind.FURROW else 2
	world.add_child(node)
	node.global_position = at
	return node

func _process(delta: float) -> void:
	_age += delta
	if _age >= _life:
		queue_free()
		return
	if follow != null and is_instance_valid(follow):
		global_position = follow.global_position + FEET
	queue_redraw()

func _draw() -> void:
	var t := clampf(_age / _life, 0.0, 1.0)
	match kind:
		Kind.GRAB, Kind.RELEASE:
			var rise := t if kind == Kind.GRAB else 1.0 - t  # Roots come up, or sink back
			for i in 4:
				var side := -1.0 if i % 2 == 0 else 1.0
				var x := side * (6.0 + 4.0 * float(i / 2))
				var top := Vector2(x * 0.4, -12.0 * rise)
				draw_line(Vector2(x, 2), top, ROOT_COLOR, 2.5)
				draw_line(Vector2(x, 2), top, ROOT_LIGHT, 1.0)
		Kind.DUST:
			var colour := DUST_COLOR
			colour.a *= 1.0 - t
			for i in 3:
				var angle := PI + (float(i) - 1.0) * 0.6
				draw_circle(Vector2.from_angle(angle) * 10.0 * t, 3.0 + 4.0 * t, colour)
		Kind.FURROW:
			var colour := FURROW_COLOR
			colour.a *= 1.0 - t * t
			draw_line(Vector2(-26, -3), Vector2(26, -3), colour, 3.0)
			draw_line(Vector2(-26, 4), Vector2(26, 4), colour, 3.0)
