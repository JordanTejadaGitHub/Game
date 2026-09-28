extends Control
class_name StatusIcon

# A small drawn status icon, one shape per status (screens_ui.md "Status icons"): Damp droplet,
# Drowsy "z", Spored dots, Marked ring, Static bolt, Held vine, in EnemyStatuses.COLORS. Used by the
# Codex (combo ingredients). `dim` draws it greyed (a locked combo's hint stays readable, just quiet).

var status: StringName = &""
var dim := false

func _init(id: StringName = &"", greyed: bool = false) -> void:
	status = id
	dim = greyed
	custom_minimum_size = Vector2(24, 24)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var colour: Color = EnemyStatuses.COLORS.get(status, Color.WHITE)
	if dim:
		colour = colour.lerp(Color(0.5, 0.5, 0.55), 0.5)
	var c := size / 2.0
	draw_circle(c, 11.0, Color(0.05, 0.06, 0.08, 0.85))
	match status:
		&"damp":  # Droplet
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -8), c + Vector2(5, 1), c + Vector2(0, 7),
				c + Vector2(-5, 1)]), colour)
			draw_circle(c + Vector2(0, 2), 5.0, colour)
		&"drowsy":  # "z"
			draw_polyline(PackedVector2Array([c + Vector2(-5, -5), c + Vector2(5, -5), c + Vector2(-5, 5),
				c + Vector2(5, 5)]), colour, 2.5)
		&"spored":  # Dots
			for offset in [Vector2(-4, -3), Vector2(4, -3), Vector2(0, 4)]:
				draw_circle(c + offset, 2.8, colour)
		&"marked":  # Ring
			draw_arc(c, 6.5, 0.0, TAU, 20, colour, 2.5, true)
			draw_circle(c, 2.0, colour)
		&"static":  # Bolt
			draw_polyline(PackedVector2Array([c + Vector2(2, -8), c + Vector2(-3, 1), c + Vector2(3, 0),
				c + Vector2(-2, 8)]), colour, 2.5)
		&"held":  # Vine
			draw_arc(c + Vector2(-2, 0), 6.0, -PI * 0.3, PI * 1.1, 14, colour, 2.5, true)
			draw_circle(c + Vector2(4, -5), 2.5, colour)
		_:
			draw_circle(c, 5.0, colour)
