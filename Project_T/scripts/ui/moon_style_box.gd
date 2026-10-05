@tool
extends StyleBox
class_name MoonStyleBox

# The Moonlit Thread panel (ui_style.md "Parts"): no border, a radial dark fog behind the content
# (darkest in the middle), and the style's signature, a 1 px inked thread across the top, parted
# around the Heartwood mark (a pixel sprout) at its centre. Dream cards use the FULL thread in their
# rarity colour; Warden bar slots use NONE plus the glowing `underline` when selected.
# Used by the project theme (UiStyle.make_theme) and by UiStyle's helpers.

enum TopLine { NONE, GOLD, FULL }

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
@export var diamond := true:  # The Heartwood mark on the thread (the name is from the old diamond)
	set(v): diamond = v; emit_changed()
@export var side_edges := false:  # Dream cards: faint 1 px sides
	set(v): side_edges = v; emit_changed()
@export var underline := false:  # Selected Warden bar slot: 2 px glowing gold line at the bottom
	set(v): underline = v; emit_changed()
@export var frame_color := Color(0, 0, 0, 0):  # A 1 px frame inside the rect (the primary button); clear = none
	set(v): frame_color = v; emit_changed()
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
			_base.shadow_color = Color(UiStyle.FOG, 0.45)
			_base.shadow_size = shadow_size
			_base.shadow_offset = Vector2(0, shadow_size * 0.6)
	_base.draw(to_canvas_item, rect)
	# The middle: a radial patch on top, so the two together reach center_alpha.
	if center_alpha > edge_alpha:
		var extra := 1.0 - (1.0 - center_alpha) / (1.0 - edge_alpha)
		rs.canvas_item_add_texture_rect(to_canvas_item, rect, _radial_texture().get_rid(), false,
			Color(glow_color if glow_color.a > 0.0 else fog_color, extra))
	if side_edges:
		var edge := Color(UiStyle.INK, 0.05)
		rs.canvas_item_add_line(to_canvas_item, Vector2(rect.position.x + 0.5, rect.position.y),
			Vector2(rect.position.x + 0.5, rect.end.y), edge)
		rs.canvas_item_add_line(to_canvas_item, Vector2(rect.end.x - 0.5, rect.position.y),
			Vector2(rect.end.x - 0.5, rect.end.y), edge)
	if frame_color.a > 0.0:
		# With a thread, the frame runs down the sides and along the bottom; the thread is its top edge.
		var r := rect.grow(-0.5)
		var points := PackedVector2Array([Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position])
		if thread == TopLine.NONE:
			points.append(Vector2(r.end.x, r.position.y))
		RenderingServer.canvas_item_add_polyline(to_canvas_item, points, PackedColorArray([frame_color]), 1.0, false)
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
			draw_thread(to_canvas_item, rect, thread_color, INK_GOLD, diamond)
		TopLine.FULL:
			draw_thread(to_canvas_item, rect, thread_color, INK_RARITY, diamond)  # The mark stays gold

# The light pass (user-approved 2026-10-05, UI Asset's "Moonlit Thread, refined"): an inked thread,
# fading out unevenly at both ends like ink on paper, parted in the middle around the Heartwood mark.
# Stops are [fraction of a half, alpha × the colour's alpha]; the left half runs edge → mark, the right
# mark → edge (mirrored stops from the mock).
const INK_GOLD := [[[0.0, 0.0], [0.065, 0.18], [0.152, 0.62], [0.207, 0.4], [0.326, 0.88], [1.0, 0.95]],
	[[0.0, 0.95], [0.652, 0.9], [0.761, 0.55], [0.826, 0.75], [0.935, 0.22], [1.0, 0.0]]]
const INK_RARITY := [[[0.0, 0.0], [0.087, 0.25], [0.304, 1.0], [1.0, 1.0]],
	[[0.0, 1.0], [0.696, 1.0], [0.848, 0.4], [1.0, 0.0]]]
const MARK_GAP := 11.0  # The thread parts this far either side of the mark's centre
# The Heartwood mark: a two-leaf sprout, 7×4 art px (H = Heartlight, G = Glow, g = Gold), 2 px per art px.
const MARK := ["HG...GH", ".GG.GG.", "...g...", "...g..."]
const MARK_INK := {"H": Color("fff4dc"), "G": Color("fcd47c"), "g": Color("e9a83c")}
const MARK_PX := 2.0

static func draw_thread(ci: RID, rect: Rect2, colour: Color, ink: Array, with_mark: bool) -> void:
	var y := rect.position.y + 0.5
	var mid := rect.get_center().x
	var gap := MARK_GAP if with_mark else 0.0
	_ink_segment(ci, Vector2(rect.position.x, y), Vector2(mid - gap, y), colour, ink[0])
	_ink_segment(ci, Vector2(mid + gap, y), Vector2(rect.end.x, y), colour, ink[1])
	if with_mark:
		draw_mark(ci, Vector2(mid, y))

static func _ink_segment(ci: RID, from: Vector2, to: Vector2, colour: Color, stops: Array) -> void:
	if to.x - from.x < 2.0:
		return
	var points := PackedVector2Array()
	var colours := PackedColorArray()
	for stop in stops:
		points.append(from.lerp(to, float(stop[0])))
		colours.append(Color(colour, colour.a * float(stop[1])))
	RenderingServer.canvas_item_add_polyline(ci, points, colours, 1.0, false)

# The Heartwood mark centred on `centre` (drawn as rects: no texture to keep alive).
static func draw_mark(ci: RID, centre: Vector2) -> void:
	var origin := (centre - Vector2(MARK[0].length(), MARK.size()) * MARK_PX / 2.0).round()
	for j in MARK.size():
		var row: String = MARK[j]
		for i in row.length():
			var ink: String = row[i]
			if MARK_INK.has(ink):
				RenderingServer.canvas_item_add_rect(ci, Rect2(origin + Vector2(i, j) * MARK_PX, Vector2(MARK_PX, MARK_PX)), MARK_INK[ink])

static func _radial_texture() -> GradientTexture2D:
	if _radial == null:
		UiStyle.release_at_exit(func() -> void: _radial = null)
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
