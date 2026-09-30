class_name BuildHatch
extends Node2D

# In build mode, a faint cold hatch on every cell a Warden can't go (screens_ui.md "In the world":
# the map's edge must look unbuildable): the island's rim, obstacles, the start and the end, straight
# from MapGenerator.is_buildable. Cells a Warden stands on stay clear (the Warden already says it).
# MapGenerator makes it; it redraws when build mode toggles or the map changes while it's on.

const HATCH_Z := 1  # Over the ground, trees and Wardens (z 0), under the cold multiply (3)
const SPACING := 8  # px between hatch lines
const LINE := 2  # px

@export var color := Color(Palette.DEWLIGHT, 0.22)

var map_generator: Node  # Set these before adding
var tower_container: Node
var tower_placer: Node
static var _texture: Texture2D

func _ready() -> void:
	z_index = HATCH_Z
	visible = false
	map_generator.path_changed.connect(queue_redraw)
	if tower_placer != null:
		tower_placer.build_mode_changed.connect(set_active)

func set_active(active: bool) -> void:
	visible = active
	queue_redraw()

# Every unbuildable cell, minus the ones Wardens stand on.
func get_hatched_cells() -> Array[Vector2]:
	var taken := {}
	if tower_container != null:
		for tower in tower_container.get_children():
			if tower is Tower and not tower.is_queued_for_deletion():
				taken[tower.cell] = true
				for c in tower.get_cells():
					taken[c] = true
	var cells: Array[Vector2] = []
	var size: Vector2 = map_generator.MAP_GRID.size
	for x in int(size.x):
		for y in int(size.y):
			var cell := Vector2(x, y)
			if not taken.has(cell) and not map_generator.is_buildable(cell):
				cells.append(cell)
	return cells

func _draw() -> void:
	if not visible:
		return
	var tile := Vector2(map_generator.MAP_GRID.cell_size)
	for cell in get_hatched_cells():
		draw_texture(hatch_texture(), cell * tile, color)

# A 64×64 cell of diagonal lines that tiles with its neighbours.
static func hatch_texture() -> Texture2D:
	if _texture == null:
		var size := 64
		var image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
		for y in size:
			for x in size:
				if posmod(x + y, SPACING) < LINE:
					image.set_pixel(x, y, Color.WHITE)
		_texture = ImageTexture.create_from_image(image)
	return _texture
