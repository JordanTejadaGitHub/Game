extends Node2D
class_name DreamMarks

# Small marks for generic Dream cards (Roguelite's DreamState, cards 142–168; screens_ui.md "Dream
# bonuses on Wardens", "Marks that are always on the map"):
# - Heart of the Maze: a heart over the chosen Warden (DreamState.get_heart_of_maze(); world). It
#   glides to a new Warden instead of popping.
# - Thick Bark: a bark shield left of the leaves counter while leaks can still be saved this block
#   (DreamState.bark_charges / bark_changed), with the number when it's 2. A Control on the HUD,
#   made here too (BarkShield) so both cards' marks live in one place.
# Both explain themselves on hover and tap (MarkTip: the card's icon, name and text), and the first
# time one appears in a run it pulses once with the card's name under it (INTRO_TIME).
# Reached untyped with has_method / has_signal, so it works before and after the cards exist.

const HEART_COLOR := Color(1.0, 0.45, 0.55)
const POLL_TIME := 0.25
const INTRO_TIME := 2.0
const HEART_OFFSET := Vector2(0, -44)
const HEART_HIT := 16.0  # World px around the heart that hover / tap it
const HEART_CARD := "heart_of_the_maze"

var dream_state: Node = null
var tip: MarkTip = null
var _heart: Node2D = null
var _heart_at := Vector2.ZERO  # Where the heart is drawn (glides after a new Warden)
var _heart_shown := false
var _intro := 0.0  # Seconds left of the first-appearance pulse
var _intro_done := false
var _pinned := false  # Opened by a tap (stays until tapped again or the timer)
var _clock := 0.0
var _phase := 0.0

func _ready() -> void:
	z_index = 9
	process_mode = Node.PROCESS_MODE_ALWAYS
	dream_state = get_parent().get_node_or_null("%DreamState")
	var layer := CanvasLayer.new()  # The tip is screen-space, above the HUD
	layer.layer = 5
	add_child(layer)
	tip = MarkTip.new()
	layer.add_child(tip)

func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.001)
	_phase += real
	_clock -= real
	if _clock <= 0.0:
		_clock = POLL_TIME
		var chosen: Node2D = null
		if dream_state != null and dream_state.has_method("get_heart_of_maze"):
			chosen = dream_state.get_heart_of_maze()
		_heart = chosen if is_instance_valid(chosen) else null
	if is_instance_valid(_heart):
		var target := _heart.global_position + HEART_OFFSET
		if not _heart_shown:
			_heart_at = target  # Appears in place; glides after that
			_heart_shown = true
			if not _intro_done:
				_intro_done = true
				_intro = INTRO_TIME
		else:
			_heart_at = _heart_at.lerp(target, 1.0 - exp(-8.0 * real))
	else:
		_heart_shown = false
		if not _pinned:
			tip.hide_tip(self)
	_intro = maxf(_intro - real, 0.0)
	# Hover: the tip follows the mouse near the heart.
	if _heart_shown and not _pinned:
		if get_global_mouse_position().distance_to(_heart_at) <= HEART_HIT:
			tip.show_card(self, _card(HEART_CARD), get_viewport().get_mouse_position())
		else:
			tip.hide_tip(self)
	queue_redraw()

# A tap / click on the heart pins its tip (again closes it).
func _input(event: InputEvent) -> void:
	if not _heart_shown or not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if get_global_mouse_position().distance_to(_heart_at) > HEART_HIT:
		return
	_pinned = not _pinned
	if _pinned:
		tip.show_card(self, _card(HEART_CARD), get_viewport().get_mouse_position(), MarkTip.TAP_TIME)
	else:
		tip.hide_tip(self)
	get_viewport().set_input_as_handled()

func _card(id: String) -> Resource:
	if dream_state == null:
		return null
	for card in dream_state.get("pool"):
		if card.id == id:
			return card
	return null

func get_heart() -> Node2D:
	return _heart

func _draw() -> void:
	if not _heart_shown:
		return
	var beat := 1.0 + 0.08 * sin(_phase * 5.0)
	if _intro > 0.0:  # First appearance: one big pulse and the card's name under it
		var t := 1.0 - _intro / INTRO_TIME
		draw_arc(_heart_at, 10.0 + 22.0 * t, 0.0, TAU, 32, Color(HEART_COLOR, 0.8 * (1.0 - t)), 2.0, true)
		beat *= 1.0 + 0.5 * (1.0 - t) * absf(sin(t * PI * 3.0))
		var card := _card(HEART_CARD)
		var words: String = card.display_name if card != null else "Heart of the Maze"
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		var at := _heart_at + Vector2(-width / 2.0, -14.0)
		var alpha := minf(_intro / 0.4, 1.0)
		draw_string_outline(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color(0.06, 0.04, 0.06, alpha))
		draw_string(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(HEART_COLOR.lightened(0.3), alpha))
	draw_heart(self, _heart_at, 6.0 * beat, HEART_COLOR)

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
	var tip: MarkTip = null
	var _label: Label
	var _intro := 0.0  # The first appearance's pulse and name (INTRO_TIME)
	var _intro_done := false
	var _pinned := false

	func _init(leaves_label: Label) -> void:
		_label = leaves_label
		custom_minimum_size = Vector2(22, 24)
		size = custom_minimum_size
		mouse_filter = Control.MOUSE_FILTER_STOP
		visible = false
		process_mode = Node.PROCESS_MODE_ALWAYS
		tip = MarkTip.new()
		add_child(tip)
		mouse_entered.connect(func() -> void: tip.show_card(self, card(), get_global_mouse_position()))
		mouse_exited.connect(func() -> void:
			if not _pinned:
				tip.hide_tip(self))

	# Thick Bark II when taken, else Thick Bark (the card whose text the tip shows).
	func card() -> Resource:
		var dreams := _label.get_node_or_null("%DreamState")
		if dreams == null:
			return null
		var found: Resource = null
		for c in dreams.get("pool"):
			if c.id == "thick_bark_ii" and dreams.has_card("thick_bark_ii"):
				return c
			if c.id == "thick_bark":
				found = c
		return found

	func set_charges(n: int) -> void:
		charges = n
		visible = n > 0
		if n > 0 and not _intro_done:
			_intro_done = true
			_intro = DreamMarks.INTRO_TIME
		if n <= 0:
			tip.hide_tip(self)
		_place()
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_pinned = not _pinned
			if _pinned:
				tip.show_card(self, card(), get_global_mouse_position(), MarkTip.TAP_TIME)
			else:
				tip.hide_tip(self)
			accept_event()

	func _process(delta: float) -> void:
		if _intro > 0.0:
			_intro = maxf(_intro - delta / maxf(Engine.time_scale, 0.001), 0.0)
			queue_redraw()
		if _pinned and not tip.visible:
			_pinned = false

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
		if _intro > 0.0:  # First appearance: a ring pulse and the card's name under the shield
			var t := 1.0 - _intro / DreamMarks.INTRO_TIME
			draw_arc(c, 10.0 + 16.0 * t, 0.0, TAU, 28, Color(RIM, 0.8 * (1.0 - t)), 2.0, true)
			var picked := card()
			var words: String = picked.display_name if picked != null else "Thick Bark"
			var font := ThemeDB.fallback_font
			var width := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			var at := Vector2(c.x - width / 2.0, size.y + 16.0)
			var alpha := minf(_intro / 0.4, 1.0)
			draw_string_outline(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color(0.06, 0.05, 0.04, alpha))
			draw_string(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(RIM, alpha))


# A mark's explanation (hover / tap): the card's rarity icon (DreamsRow.DreamIcon), its name and its
# text. One per mark; `owner_mark` is whoever showed it last (only it hides it).
class MarkTip extends PanelContainer:
	const TAP_TIME := 4.0
	var _icon_box := HBoxContainer.new()
	var _name := Label.new()
	var _text := Label.new()
	var _shown_by: Object = null
	var _timer := -1.0

	func _init() -> void:
		top_level = true
		visible = false
		z_index = 60
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		process_mode = Node.PROCESS_MODE_ALWAYS
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(row)
		row.add_child(_icon_box)
		var box := VBoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(box)
		_name.add_theme_font_size_override("font_size", 16)
		box.add_child(_name)
		_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_text.custom_minimum_size = Vector2(240, 0)
		_text.add_theme_font_size_override("font_size", 14)
		box.add_child(_text)

	# Shows `card` near `at` (screen px); `seconds` > 0 hides it after that long (a tap).
	func show_card(by: Object, card: Resource, at: Vector2, seconds: float = -1.0) -> void:
		if card == null:
			return
		if not (visible and _shown_by == by and _name.text == card.display_name):
			for child in _icon_box.get_children():
				_icon_box.remove_child(child)
				child.queue_free()
			var icon := DreamsRow.DreamIcon.new()
			icon.card = card
			icon.custom_minimum_size = DreamsRow.ICON_SIZE + Vector2(0, 12)
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_icon_box.add_child(icon)
			_name.text = card.display_name
			_text.text = IconInfo.format(card.description)
		_shown_by = by
		_timer = seconds
		visible = true
		reset_size()
		var screen := get_viewport_rect().size
		global_position = Vector2(clampf(at.x - size.x / 2.0, 4, screen.x - size.x - 4),
			at.y - size.y - 16 if at.y - size.y - 16 > 4 else at.y + 24)

	func hide_tip(by: Object) -> void:
		if _shown_by == by:
			visible = false

	func _process(delta: float) -> void:
		if visible and _timer > 0.0:
			_timer -= delta / maxf(Engine.time_scale, 0.001)
			if _timer <= 0.0:
				visible = false
