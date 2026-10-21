@tool
extends StyleBox
class_name MoonStyleBox

# Every panel, card, button, slot and tooltip. Moon-glass (ui_style.md "Moon-glass", chosen 2026-10-20; it wins over the
# old fog-and-thread rules): `frame` names a cut moon-glass plate in a pewter or brass rim, a pixel-art 9-slice from
# assets/ui/moonglass/ (moonglass.json margins, drawn at ×2, nearest). Plates cast a soft drop shadow (none when
# pressed); brass keeps the old soft gold glow instead. The one main panel per screen carries the rim sprout on its
# top rim (`diamond` with a top line: the one-per-screen rule in UiStyle still switches it). No diamond, no gold thread.
# `frame` empty keeps the old soft fog (FogPatch: backings behind map text, the whisper mist).
# Used by the project theme (UiStyle.make_theme) and by UiStyle's helpers.

enum TopLine { NONE, GOLD, FULL }

const UNDERLINE_INSET := 14.0
const FRAMES_DIR := "res://assets/ui/moonglass/"
const SCALE := 2  # Art px → screen px
const FRAME_MARGINS := {&"panel_main": 14, &"panel_main_yours": 14, &"plate": 8, &"plate_hover": 8,
	&"plate_pressed": 8, &"plate_yours": 8, &"plate_danger": 8, &"plate_dim": 8, &"divider": 1}  # moonglass.json
const BRASS := [&"panel_main_yours", &"plate_hover", &"plate_pressed", &"plate_yours"]
const SPROUT_SINK := 4.0  # The sprout's foot stands this far into the top rim

@export var frame := &"":  # A moon-glass frame (FRAME_MARGINS); empty = the old fog patch
	set(v): frame = v; _changed()
@export var glow := false:  # Brass: the soft gold glow round the plate (instead of the drop shadow)
	set(v): glow = v; _changed()
@export var drop_shadow := true:  # Off for a pressed plate
	set(v): drop_shadow = v; _changed()
@export var accent := Color(0, 0, 0, 0):  # A 2 px line along the top of the glass (a card's rarity, a boss panel); clear = none
	set(v): accent = v; emit_changed()
@export var fog_color := Color("05050d"):  # Void (Heartwood 32)
	set(v): fog_color = v; _changed()
@export_range(0.0, 1.0) var center_alpha := 0.78:  # The middle of the fog
	set(v): center_alpha = v; _changed()
@export_range(0.0, 1.0) var edge_alpha := 0.35:  # The rim (and the corners)
	set(v): edge_alpha = v; _changed()
@export var glow_color := Color(0, 0, 0, 0):  # The fog's lit middle (frame-less boxes only); clear = fog_color
	set(v): glow_color = v; emit_changed()
@export var corner_radius := 4:
	set(v): corner_radius = v; _changed()
@export var thread := TopLine.GOLD:  # NONE = no sprout; FULL = the accent in thread_color (cards' rarity)
	set(v): thread = v; emit_changed()
@export var thread_color := Color("fcd47c", 0.8):  # Glow
	set(v): thread_color = v; emit_changed()
@export var diamond := true:  # The rim sprout (on main panels; the name is from the old diamond)
	set(v): diamond = v; emit_changed()
@export var side_edges := false:  # (Fog cards only; the rim does it now)
	set(v): side_edges = v; emit_changed()
@export var underline := false:  # A glowing gold line along the foot (Woven cards)
	set(v): underline = v; emit_changed()
@export var frame_color := Color(0, 0, 0, 0):  # (Fog boxes only) a 1 px frame inside the rect; clear = none
	set(v): frame_color = v; emit_changed()
@export var shadow_size := 0:  # (Fog boxes only) a soft drop shadow
	set(v): shadow_size = v; _changed()
@export var shadow_color := Color(0, 0, 0, 0):  # (Fog boxes only) the shadow's colour; clear = dark Void
	set(v): shadow_color = v; _changed()

var _base: StyleBoxFlat
var _halo: StyleBoxFlat
static var _radial: GradientTexture2D
static var _textures := {}  # frame -> its ×2 ImageTexture (released at exit: a static texture crashes the exit)

func _changed() -> void:
	_base = null
	_halo = null
	emit_changed()

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var texture := texture_for(frame) if frame != &"" else null
	if texture == null:
		_draw_fog(to_canvas_item, rect)
		return
	var rs := RenderingServer
	if _halo == null:
		_halo = StyleBoxFlat.new()
		_halo.draw_center = false
		_halo.set_corner_radius_all(6)
		if glow:  # The old soft gold glow, all round
			_halo.shadow_color = Color(UiStyle.GOLD, 0.26)
			_halo.shadow_size = 12
		elif drop_shadow:  # A soft dark drop shadow, a little down
			_halo.shadow_color = Color(UiStyle.FOG, 0.5)
			_halo.shadow_size = 10
			_halo.shadow_offset = Vector2(0, 4)
	if _halo.shadow_size > 0:
		_halo.draw(to_canvas_item, rect.grow(-2.0))
	var m := float(FRAME_MARGINS.get(frame, 8) * SCALE)
	rs.canvas_item_add_nine_patch(to_canvas_item, rect, Rect2(Vector2.ZERO, texture.get_size()), texture.get_rid(),
		Vector2(m, m), Vector2(m, m))
	var rim := float(SCALE * (3 if frame.begins_with("panel") else 2))  # The bevel's width
	var line := accent if accent.a > 0.0 else (thread_color if thread == TopLine.FULL else Color(0, 0, 0, 0))
	if line.a > 0.0:  # Inside the rim, across the top of the glass, short of the chamfers
		var inset := m * 0.6
		rs.canvas_item_add_rect(to_canvas_item, Rect2(rect.position.x + inset, rect.position.y + rim + SCALE,
			maxf(rect.size.x - inset * 2.0, 0.0), 2.0), line)
	if underline:
		_draw_underline(to_canvas_item, rect, rim + SCALE)
	if diamond and thread != TopLine.NONE and frame.begins_with("panel"):
		var sprout := texture_for(&"rim_sprout")
		if sprout != null:
			var at := Vector2(roundf(rect.get_center().x - sprout.get_width() / 2.0), rect.position.y - sprout.get_height() + SPROUT_SINK)
			rs.canvas_item_add_texture_rect(to_canvas_item, Rect2(at, sprout.get_size()), sprout.get_rid())

# The frame's texture at ×2 (whole art pixels, nearest), cached; null when the art is missing.
static func texture_for(id: StringName) -> Texture2D:
	if _textures.has(id):
		return _textures[id]
	var path := FRAMES_DIR + String(id) + ".png"
	var art: Texture2D = load(path) if ResourceLoader.exists(path) else null
	var texture: Texture2D = null
	if art != null:
		var image := art.get_image()
		if image != null:
			image = image.duplicate() as Image
			image.decompress()
			image.resize(image.get_width() * SCALE, image.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
			texture = ImageTexture.create_from_image(image)
	if _textures.is_empty():
		UiStyle.release_at_exit(func() -> void: _textures.clear())
	_textures[id] = texture
	return texture

# The plate's margins in screen px (the rim the content stays inside).
static func frame_margin(id: StringName) -> float:
	return float(FRAME_MARGINS.get(id, 8) * SCALE)

func _draw_underline(ci: RID, rect: Rect2, up: float) -> void:
	var rs := RenderingServer
	var y := rect.end.y - up
	var inset := minf(UNDERLINE_INSET, rect.size.x * 0.18)  # Narrow slots keep most of the line
	var a := Vector2(rect.position.x + inset, y)
	var b := Vector2(rect.end.x - inset, y)
	var gold := UiStyle.GOLD
	rs.canvas_item_add_line(ci, a, b, Color(gold, 0.12), 10.0)  # The glow
	rs.canvas_item_add_line(ci, a, b, Color(gold, 0.25), 5.0)
	rs.canvas_item_add_line(ci, a, b, gold, 2.0)

# The old soft fog (no frame): a rounded box at the edge alpha with a radial patch on top, so the two reach center_alpha.
func _draw_fog(to_canvas_item: RID, rect: Rect2) -> void:
	var rs := RenderingServer
	if _base == null:
		_base = StyleBoxFlat.new()
		_base.bg_color = Color(fog_color, edge_alpha)
		_base.set_corner_radius_all(corner_radius)
		_base.anti_aliasing = corner_radius > 0
		if shadow_size > 0:
			_base.shadow_color = shadow_color if shadow_color.a > 0.0 else Color(UiStyle.FOG, 0.45)
			_base.shadow_size = shadow_size
			_base.shadow_offset = Vector2(0, shadow_size * 0.6)
	_base.draw(to_canvas_item, rect)
	if center_alpha > edge_alpha:
		var extra := 1.0 - (1.0 - center_alpha) / (1.0 - edge_alpha)
		rs.canvas_item_add_texture_rect(to_canvas_item, rect, _radial_texture().get_rid(), false,
			Color(glow_color if glow_color.a > 0.0 else fog_color, extra))
	if frame_color.a > 0.0:
		var r := rect.grow(-0.5)
		var points := PackedVector2Array([Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position,
			Vector2(r.end.x, r.position.y)])
		rs.canvas_item_add_polyline(to_canvas_item, points, PackedColorArray([frame_color]), 1.0, false)
	if underline:
		_draw_underline(to_canvas_item, rect, 1.0)

# The Heartwood sprout, 7×4 art px (H = Heartlight, G = Glow, g = Gold), 2 px per art px: the rim sprout's drawing, also
# drawn on its own (the DPS tags) as rects, so there's no texture to keep alive.
const MARK := ["HG...GH", ".GG.GG.", "...g...", "...g..."]
const MARK_INK := {"H": Color("fff4dc"), "G": Color("fcd47c"), "g": Color("e9a83c")}
const MARK_PX := 2.0

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
