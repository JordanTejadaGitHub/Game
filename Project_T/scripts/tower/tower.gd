extends Node2D
class_name Tower

@export var tower_data: TowerData
@onready var sprite: Sprite2D = $Sprite2D

# The grid cell this tower occupies (set by TowerPlacer).
var cell: Vector2

func _ready() -> void:
	sprite.texture = tower_data.texture
	queue_redraw()

func _draw() -> void:
	if tower_data.texture == null:
		draw_placeholder(self, tower_data.placeholder_color)

# Draws a simple stone block centred on the origin. Shared with the build-mode ghost preview.
static func draw_placeholder(canvas: CanvasItem, color: Color) -> void:
	var block := Rect2(-24, -24, 48, 48)
	canvas.draw_rect(block, color.darkened(0.45))
	canvas.draw_rect(block.grow(-4), color)
	canvas.draw_circle(Vector2.ZERO, 10, color.lightened(0.35))
