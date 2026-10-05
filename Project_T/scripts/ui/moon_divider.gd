@tool
extends StyleBox
class_name MoonDivider

# Divider inside a panel: the same inked gold thread as a panel's top, across the middle of the rect,
# parted around the Heartwood mark (the light pass, 2026-10-05). The theme's HSeparator uses it.

@export var colour := Color("fcd47c", 0.75):  # Glow (Heartwood 32)
	set(v): colour = v; emit_changed()

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var line := Rect2(rect.position.x, floorf(rect.get_center().y), rect.size.x, 1.0)
	MoonStyleBox.draw_thread(to_canvas_item, line, colour, MoonStyleBox.INK_GOLD, true)
