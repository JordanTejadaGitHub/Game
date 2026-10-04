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
var catch_mouse := true  # The screen catches the mouse while not peeking (off for a click-through overlay)
var _screen: Control
var _content: Array
var _back := Button.new()

func _init(screen: Control, content: Array, back_text: String) -> void:
	_screen = screen
	_content = content
	_back.text = back_text
	_back.focus_mode = Control.FOCUS_NONE
	# Mid-screen for every paused screen (choices and pausing cards: one spot; user: "the middle for paused things like
	# that"): never over the drift banner, the Omen line or the Coming strip at the top.
	place_back_centre()
	_back.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_back.visible = false
	_back.pressed.connect(set_peeking.bind(false))
	screen.add_child(_back)
	screen.visibility_changed.connect(func() -> void:
		if not screen.visible:
			set_peeking(false))

# Every paused screen (the Dream / family / Omen choices, the discovery and new-nightmare cards): the "Back" / "Return"
# pill sits in the middle of the screen, a little below centre, solid (user: "just put the placement in the middle for
# paused things like that, since they need to close it before starting or resuming the drift"). Never at the top (it
# covered the Coming strip) or at the edges.
const CENTRE_DROP := 70.0  # Pixels below the middle
func place_back_centre() -> void:
	_back.set_anchors_preset(Control.PRESET_CENTER)
	_back.custom_minimum_size = Vector2(280, 44)
	_back.offset_left = -140
	_back.offset_right = 140
	_back.offset_top = CENTRE_DROP
	_back.offset_bottom = CENTRE_DROP + 44
	UiStyle.primary(_back)  # Solid

func back_button() -> Button:
	return _back

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
	if catch_mouse:
		_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE if on else Control.MOUSE_FILTER_STOP
	changed.emit(on)
