@tool
extends StyleBox
class_name MoonDivider

# Divider inside a panel (Moon-glass, ui_style.md): the engraved line cut into the glass (divider.png: Dread over Dusk,
# 2 art px tall, drawn at ×2), across the middle of the rect, stopping short of the rim. Never a gold thread. The theme's
# HSeparator uses it.

const INSET := 10.0  # Short of the panel's rim at both ends

@export var colour := Color(1, 1, 1, 1):  # A multiplier on the engraving
	set(v): colour = v; emit_changed()
@export var mark := true:  # (Kept for old callers: no mark on dividers now)
	set(v): mark = v; emit_changed()

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var texture := MoonStyleBox.texture_for(&"divider")
	var width := rect.size.x - INSET * 2.0
	if width <= 0.0:
		return
	if texture == null:
		RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(rect.position.x + INSET, floorf(rect.get_center().y), width, 2.0),
			Color(UiStyle.FOG, 0.8))
		return
	var h := texture.get_height()
	var line := Rect2(rect.position.x + INSET, floorf(rect.get_center().y - h / 2.0), width, h)
	var m := MoonStyleBox.frame_margin(&"divider")
	RenderingServer.canvas_item_add_nine_patch(to_canvas_item, line, Rect2(Vector2.ZERO, texture.get_size()), texture.get_rid(),
		Vector2(m, 0.0), Vector2(m, 0.0), RenderingServer.NINE_PATCH_STRETCH, RenderingServer.NINE_PATCH_STRETCH, true, colour)
