@tool
extends StyleBox
class_name MoonStyleBox

# The Moonlit Thread panel (ui_style.md "Parts"): no border, a radial dark fog behind the content
# (darkest in the middle), and the style's signature, a 1 px thread across the top that fades out at
# both ends with a small hollow diamond at its centre. Dream cards use the FULL thread in their
# rarity colour; Warden bar slots use NONE plus the glowing `underline` when selected.
# Used by the project theme (UiStyle.make_theme) and by UiStyle's helpers.

enum TopLine { NONE, GOLD, FULL }

const THREAD_INSET := 0.1  # Of the width, at each end (GOLD)
const DIAMOND_HALF := 5.0  # An 8 px square turned 45°
const DIAMOND_FILL := Color("05050d")  # Void (Heartwood 32)
const UNDERLINE_INSET := 14.0

@export var fog_color := Color("05050d"):  # Void (Heartwood 32)
	set(v): fog_color = v; _changed()
@export_range(0.0, 1.0) var center_alpha := 0.78:  # The middle of the fog
	set(v): center_alpha = v; _changed()
@export_range(0.0, 1.0) var edge_alpha := 0.35:  # The rim (and the corners)
	set(v): edge_alpha = v; _changed()
@export var glow_color := Color(0, 0, 0, 0):  # The lit middle's colour (cards: Night over Void); clear = fog_color
	set(v): glow_color = v; emit_changed()
@export var corner_radius := 4:
	set(v): corner_radius = v; _changed()
@export var thread := TopLine.GOLD:
	set(v): thread = v; emit_changed()
@export var thread_color := Color("fcd47c", 0.8):  # Glow
	set(v): thread_color = v; emit_changed()
@export var diamond := true:  # GOLD threads only
	set(v): diamond = v; emit_changed()
@export var side_edges := false:  # Dream cards: faint 1 px sides
	set(v): side_edges = v; emit_changed()
@export var underline := false:  # Selected Warden bar slot: 2 px glowing gold line at the bottom
	set(v): underline = v; emit_changed()
@export var shadow_size := 0:  # Cards: a soft drop shadow
	set(v): shadow_size = v; _changed()

var _base: StyleBoxFlat
static var _radial: GradientTexture2D

func _changed() -> void:
	_base = null
	emit_changed()

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var rs := RenderingServer
	# The rim: a flat rounded box at the edge alpha (so corners stay soft, never a hard square).
	if _base == null:
		_base = StyleBoxFlat.new()
		_base.bg_color = Color(fog_color, edge_alpha)
		_base.set_corner_radius_all(corner_radius)
		_base.anti_aliasing = corner_radius > 0
		if shadow_size > 0:
			_base.shadow_color = Color(0, 0, 0, 0.45)
			_base.shadow_size = shadow_size
			_base.shadow_offset = Vector2(0, shadow_size * 0.6)
	_base.draw(to_canvas_item, rect)
	# The middle: a radial patch on top, so the two together reach center_alpha.
	if center_alpha > edge_alpha:
		var extra := 1.0 - (1.0 - center_alpha) / (1.0 - edge_alpha)
		rs.canvas_item_add_texture_rect(to_canvas_item, rect, _radial_texture().get_rid(), false,
			Color(glow_color if glow_color.a > 0.0 else fog_color, extra))
	if side_edges:
		var edge := Color(1, 1, 1, 0.05)
		rs.canvas_item_add_line(to_canvas_item, Vector2(rect.position.x + 0.5, rect.position.y),
			Vector2(rect.position.x + 0.5, rect.end.y), edge)
		rs.canvas_item_add_line(to_canvas_item, Vector2(rect.end.x - 0.5, rect.position.y),
			Vector2(rect.end.x - 0.5, rect.end.y), edge)
	if underline:
		var y := rect.end.y - 1.0
		var inset := minf(UNDERLINE_INSET, rect.size.x * 0.18)  # Narrow slots keep most of the line
		var a := Vector2(rect.position.x + inset, y)
		var b := Vector2(rect.end.x - inset, y)
		var gold := UiStyle.GOLD
		rs.canvas_item_add_line(to_canvas_item, a, b, Color(gold, 0.12), 10.0)  # The glow
		rs.canvas_item_add_line(to_canvas_item, a, b, Color(gold, 0.25), 5.0)
		rs.canvas_item_add_line(to_canvas_item, a, b, gold, 2.0)
	match thread:
		TopLine.GOLD:
			draw_thread(to_canvas_item, rect, thread_color, THREAD_INSET, diamond)
		TopLine.FULL:
			draw_thread(to_canvas_item, rect, thread_color, 0.0, false)

# The thread along `rect`'s top edge: transparent at both ends, full colour in the middle.
static func draw_thread(ci: RID, rect: Rect2, colour: Color, inset: float, with_diamond: bool) -> void:
	var y := rect.position.y + 0.5
	var x0 := rect.position.x + rect.size.x * inset
	var x1 := rect.end.x - rect.size.x * inset
	var mid := (x0 + x1) / 2.0
	var clear := Color(colour, 0.0)
	var ends := clear if inset > 0.0 else Color(colour, colour.a * 0.3)  # A card's runs edge to edge
	RenderingServer.canvas_item_add_polyline(ci, PackedVector2Array([Vector2(x0, y), Vector2(mid, y), Vector2(x1, y)]),
		PackedColorArray([ends, colour, ends]), 1.0, false)
	if with_diamond:
		draw_diamond(ci, Vector2(mid, y), Color(colour, 1.0))

# The small hollow diamond: dark fill, 1 px gold outline.
static func draw_diamond(ci: RID, centre: Vector2, colour: Color) -> void:
	var h := DIAMOND_HALF
	var points := PackedVector2Array([centre + Vector2(0, -h), centre + Vector2(h, 0), centre + Vector2(0, h),
		centre + Vector2(-h, 0)])
	RenderingServer.canvas_item_add_polygon(ci, points, PackedColorArray([DIAMOND_FILL]))
	var outline := points.duplicate()
	outline.append(points[0])
	RenderingServer.canvas_item_add_polyline(ci, outline, PackedColorArray([colour]), 1.0, true)

static func _radial_texture() -> GradientTexture2D:
	if _radial == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.7), Color(1, 1, 1, 0)])
		_radial = GradientTexture2D.new()
		_radial.gradient = gradient
		_radial.fill = GradientTexture2D.FILL_RADIAL
		_radial.fill_from = Vector2(0.5, 0.5)
		_radial.fill_to = Vector2(1.0, 0.5)
		_radial.width = 64
		_radial.height = 64
	return _radial
