extends Node2D
class_name DrowsyRing

# Bellflower's Drowsy pulse (story chat 2026-10-01): the pulse that makes nightmares Drowsy draws a soft
# pink ring out to its range and a small "z" drifting up from each nightmare it lulled; plain pulses stay
# as they are. Script-only, drawn in the world (never under the Warden / nightmare containers). Effects
# quality "reduced" keeps the ring and drops the motes; reduce flashes makes the ring fainter.

const SECONDS := 0.7
const MAX_MOTES := 6
const RING_COLOR := Palette.BLOSSOM
const RING_WIDTH := 2.0
const MOTE_RISE := 18.0  # Pixels a "z" floats up over its life
const MOTE_SIZE := 5.0

var radius := 64.0
var motes: Array[Vector2] = []  # Local positions
var _age := 0.0
var _strength := 1.0

# Shows the ring around `tower` (radius in pixels) with motes at `hits` (world positions). Returns the node.
static func play(tower: Node2D, ring_radius: float, hits: Array[Vector2]) -> DrowsyRing:
	if tower == null or not tower.is_inside_tree() or not Fx.on_screen(tower.global_position, ring_radius):
		return null
	var world := Reactions._world(tower)
	if world == null:
		return null
	var node := DrowsyRing.new()
	node.radius = ring_radius
	node.z_index = 6
	node._strength = 0.55 if Fx.reduce_flashes() else 1.0
	world.add_child(node)
	node.global_position = tower.global_position
	if not Fx.reduced():
		for at in hits:
			node.motes.append(at - tower.global_position)
	return node

func _process(delta: float) -> void:
	_age += delta
	if _age >= SECONDS:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t := clampf(_age / SECONDS, 0.0, 1.0)
	var ease_out := 1.0 - pow(1.0 - t, 2.0)
	var fade := (1.0 - t) * _strength
	draw_arc(Vector2.ZERO, radius * lerpf(0.35, 1.0, ease_out), 0.0, TAU, 48, Color(RING_COLOR, 0.7 * fade), RING_WIDTH)
	for at in motes:
		_draw_z(at + Vector2(4.0 * t, -10.0 - MOTE_RISE * ease_out), Color(RING_COLOR, fade))

# A little pixel "z": top bar, diagonal, bottom bar.
func _draw_z(at: Vector2, colour: Color) -> void:
	var h := MOTE_SIZE * 0.5
	draw_line(at + Vector2(-h, -h), at + Vector2(h, -h), colour, 1.5)
	draw_line(at + Vector2(h, -h), at + Vector2(-h, h), colour, 1.5)
	draw_line(at + Vector2(-h, h), at + Vector2(h, h), colour, 1.5)
