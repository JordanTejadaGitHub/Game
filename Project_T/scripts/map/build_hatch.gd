class_name BuildHatch
extends Node2D

# In build mode, a faint cold hatch on every half cell a Warden can't go (screens_ui.md "In the world":
# the map's edge must look unbuildable): the island's rim, obstacles, the start and the end, straight
# from MapGenerator.is_buildable_half. Half cells a Warden stands on stay clear (the Warden already says it).
# MapGenerator makes it; it redraws when build mode toggles or the map changes while it's on.

const HATCH_Z := 1  # Over the ground, trees and Wardens (z 0), under the cold multiply (3)
const SPACING := 8  # px between hatch lines
const LINE := 2  # px

@export var color := Color(Palette.DEWLIGHT, 0.22)

var map_generator: Node  # Set these before adding
var tower_container: Node
var tower_placer: Node
# Weak (exit crash hunt, like Fx bb5076e2); this node holds its own `_hatch` for drawing.
static var _texture: WeakRef
var _hatch: Texture2D

func _ready() -> void:
	z_index = HATCH_Z
	_hatch = hatch_texture()  # Held here: draw commands don't keep it alive
	visible = false
	map_generator.path_changed.connect(queue_redraw)
	if tower_placer != null:
		tower_placer.build_mode_changed.connect(set_active)

func set_active(active: bool) -> void:
	visible = active
	queue_redraw()

# Every unbuildable HALF cell, minus the ones Wardens stand on (half_cells.md: a Warden's ground follows its
# 4 halves, so the hatch never cuts across a half-offset plinth). Half cells are on the (size × 2) grid.
func get_hatched_halves() -> Array[Vector2]:
	var taken := {}
	if tower_container != null:
		for tower in tower_container.get_children():
			if tower is Tower and not tower.is_queued_for_deletion():
				for h in tower.get_halves():
					taken[h] = true
	var halves: Array[Vector2] = []
	var size: Vector2 = map_generator.MAP_GRID.size * 2.0
	for x in int(size.x):
		for y in int(size.y):
			var h := Vector2(x, y)
			if not taken.has(h) and not map_generator.is_buildable_half(h):
				halves.append(h)
	return halves

func _draw() -> void:
	if not visible:
		return
	var half := Vector2(map_generator.MAP_GRID.cell_size) / 2.0
	for h in get_hatched_halves():  # A quarter of the 64 px hatch tile each, in step so the lines run on
		var at := h * half
		draw_texture_rect_region(_hatch, Rect2(at, half), Rect2(Vector2(fposmod(at.x, 64.0), fposmod(at.y, 64.0)), half), color)

# A 64×64 cell of diagonal lines that tiles with its neighbours.
static func hatch_texture() -> Texture2D:
	var held: Texture2D = _texture.get_ref() if _texture != null else null
	if held == null:
		var size := 64
		var image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
		for y in size:
			for x in size:
				if posmod(x + y, SPACING) < LINE:
					image.set_pixel(x, y, Color.WHITE)
		held = ImageTexture.create_from_image(image)
		_texture = weakref(held)
	return held
