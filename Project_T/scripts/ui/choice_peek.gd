extends RefCounted
class_name ChoicePeek

# "Peek" for choice screens (screens_ui.md "Choice screens"): a button that minimises the screen so
# the player can look at the map (time stays stopped; the camera still pans and zooms), and a
# "Back to …" button that reopens it. Works for any full-screen choice Control:
#   var peek := ChoicePeek.new(self, [dim, center], "Back to the family pick")
#   box.add_child(peek.make_peek_button())
# `content` are the children to hide while peeking; the screen stops catching the mouse meanwhile.

signal changed(peeking: bool)

var peeking := false
var _screen: Control
var _content: Array
var _back := Button.new()

func _init(screen: Control, content: Array, back_text: String) -> void:
	_screen = screen
	_content = content
	_back.text = back_text
	_back.focus_mode = Control.FOCUS_NONE
	_back.custom_minimum_size = Vector2(260, 48)
	# Bottom centre, just above the Warden bar: never over the drift banner, the Omen line or the Coming
	# strip at the top (user playtest: it covered the strip's portraits).
	_back.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_back.offset_left = -130
	_back.offset_right = 130
	_back.offset_top = -158
	_back.offset_bottom = -110
	_back.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_back.visible = false
	_back.pressed.connect(set_peeking.bind(false))
	screen.add_child(_back)
	screen.visibility_changed.connect(func() -> void:
		if not screen.visible:
			set_peeking(false))

# Just above the Warden bar's top, which moves: the bar can wrap into two rows (hud.gd _fit_tower_bar).
func _place_back() -> void:
	var bar := _screen.get_parent().get_node_or_null("TowerBar") as Control if _screen.get_parent() != null else null
	if bar == null:
		return
	_back.offset_bottom = minf(bar.offset_top, -76.0) - 12.0
	_back.offset_top = _back.offset_bottom - 48.0

# A "Peek at the map" button for the choice screen's own layout.
func make_peek_button(text: String = "Peek at the map") -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(200, 48)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(set_peeking.bind(true))
	return button

func set_peeking(on: bool) -> void:
	if on == peeking:
		return
	peeking = on
	for node in _content:
		node.visible = not on
	_back.visible = on
	if on:
		_place_back()
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE if on else Control.MOUSE_FILTER_STOP
	changed.emit(on)
