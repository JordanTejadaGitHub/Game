@tool
extends StyleBox
class_name MoonDivider

# Divider inside a panel (ui_style.md "Parts"): a 1 px gold line across the middle of the rect,
# fading out at both ends. The theme's HSeparator uses it.

@export var colour := Color("fcd47c", 0.5):  # Glow (Heartwood 32)
	set(v): colour = v; emit_changed()

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var y := floorf(rect.get_center().y) + 0.5
	var clear := Color(colour, 0.0)
	RenderingServer.canvas_item_add_polyline(to_canvas_item, PackedVector2Array([Vector2(rect.position.x, y),
		Vector2(rect.get_center().x, y), Vector2(rect.end.x, y)]), PackedColorArray([clear, colour, clear]), 1.0, false)
