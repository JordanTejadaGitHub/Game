extends Node2D
class_name DreamMarks

# Small marks for generic Dream cards (Roguelite's DreamState, cards 142–168):
# - Heart of the Maze: a heart over the chosen Warden (DreamState.get_heart_of_maze(); world).
# - Thick Bark: a bark shield left of the leaves counter while leaks can still be saved this block
#   (DreamState.bark_charges / bark_changed), with the number when it's 2. A Control on the HUD,
#   made here too (BarkShield) so both cards' marks live in one place.
# Reached untyped with has_method / has_signal, so it works before and after the cards exist.

const HEART_COLOR := Color(1.0, 0.45, 0.55)
const POLL_TIME := 0.25

var dream_state: Node = null
var _heart: Node2D = null
var _clock := 0.0
var _phase := 0.0

func _ready() -> void:
	z_index = 9
	process_mode = Node.PROCESS_MODE_ALWAYS
	dream_state = get_parent().get_node_or_null("%DreamState")

func _process(delta: float) -> void:
	_phase += delta
	_clock -= delta
	if _clock <= 0.0:
		_clock = POLL_TIME
		var chosen: Node2D = null
		if dream_state != null and dream_state.has_method("get_heart_of_maze"):
			chosen = dream_state.get_heart_of_maze()
		_heart = chosen if is_instance_valid(chosen) else null
	queue_redraw()

func get_heart() -> Node2D:
	return _heart

func _draw() -> void:
	if not is_instance_valid(_heart):
		return
	var beat := 1.0 + 0.08 * sin(_phase * 5.0)
	draw_heart(self, _heart.global_position + Vector2(0, -44), 6.0 * beat, HEART_COLOR)

static func draw_heart(canvas: CanvasItem, at: Vector2, s: float, colour: Color) -> void:
	var points := PackedVector2Array()
	for i in 24:  # The classic heart curve, scaled to `s`
		var t := TAU * i / 24.0
		points.append(at + Vector2(16.0 * pow(sin(t), 3), -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))) * s / 16.0)
	canvas.draw_colored_polygon(points, Color(0.08, 0.05, 0.07, 0.85))
	var inner := PackedVector2Array()
	for p in points:
		inner.append(at + (p - at) * 0.78)
	canvas.draw_colored_polygon(inner, colour)


# Thick Bark's shield beside the leaves counter (a child of the leaves label, right-aligned text).
class BarkShield extends Control:
	const BARK := Color(0.62, 0.45, 0.28)
	const RIM := Color(0.95, 0.8, 0.5)
	var charges := 0
	var _label: Label

	func _init(leaves_label: Label) -> void:
		_label = leaves_label
		custom_minimum_size = Vector2(22, 24)
		size = custom_minimum_size
		mouse_filter = Control.MOUSE_FILTER_PASS
		visible = false
		TapTip.attach(self, "Thick Bark: the next leak this block costs no leaf.")

	func set_charges(n: int) -> void:
		charges = n
		visible = n > 0
		tooltip_text = "Thick Bark: the next %s this block cost%s no leaf." % ["leak" if n == 1 else "%d leaks" % n, "s" if n == 1 else ""]
		for child in get_children():
			if child is TapTip:
				child._label.text = tooltip_text
		_place()
		queue_redraw()

	func _place() -> void:
		var font := _label.get_theme_font("font")
		var font_size := _label.get_theme_font_size("font_size")
		var width := font.get_string_size(_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		position = Vector2(_label.size.x - width - size.x - 8.0, (_label.size.y - size.y) / 2.0)

	func _draw() -> void:
		var c := size / 2.0
		var s := 9.0
		var shield := PackedVector2Array([c + Vector2(-s, -s), c + Vector2(s, -s), c + Vector2(s, 0.2 * s),
			c + Vector2(0, s * 1.25), c + Vector2(-s, 0.2 * s)])
		draw_colored_polygon(shield, BARK)
		draw_polyline(shield + PackedVector2Array([shield[0]]), RIM, 1.5, true)
		for i in 3:  # Bark grain
			var x := -s * 0.5 + i * s * 0.5
			draw_line(c + Vector2(x, -s * 0.7), c + Vector2(x, s * 0.5), Color(0.35, 0.24, 0.14), 1.0)
		if charges > 1:
			var font := ThemeDB.fallback_font
			draw_string_outline(font, c + Vector2(4, s + 4), str(charges), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color(0.08, 0.08, 0.1))
			draw_string(font, c + Vector2(4, s + 4), str(charges), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
