extends PanelContainer
class_name DiscoveryCard

# Discoveries you can read (screens_ui.md 44fe84d9; user 2026-10-22: "some of the hints that come from the screen are
# not intuitive and can barely read, like discovering the Executioner"). Every first-time discovery (a signature, a
# Kinship, a Reaction or Crowned Reaction, a Dream card's or a Calling evolution's first fire) shows here instead of a
# toast: a small card at the right edge (phones: above the Warden bar), never over the field's middle, with the icon
# or the Warden's portrait, the name large, one plain sentence at body size and the Warden that did it. 8 s of real
# time or until tapped (a tap opens its Codex entry); it never pauses; one at a time, the rest queue; never alongside a
# Lesson (the Lesson first). Made by the HUD; anyone posts through DiscoveryCard.post().

const GROUP := &"discovery_card"
const SHOW_TIME := 8.0  # Real seconds
const WIDTH := 340.0
const EDGE := 16.0  # From the screen's right edge
const PC_TOP_SHARE := 0.36  # PC: its top at about a third of the screen, clear of the top-right row and the Warden panel
const PHONE_BOTTOM := 132.0  # Phones: its foot above the Warden bar and the drift buttons
const ICON := 44.0

var _queue: Array = []  # Dictionaries: {title, line, icon, by, tab, entry}
var _left := 0.0
var _now: Dictionary = {}
var _icon := TextureRect.new()
var _caps := Label.new()
var _title := Label.new()
var _line := Label.new()
var _by := Label.new()

# Posts a discovery: `line` is one plain sentence; `by` the Warden that did it (its portrait and name), or null with
# `icon`; `tab` / `entry` open its Codex entry on a tap ("" = the Codex's front).
static func post(tree: SceneTree, title: String, line: String, icon: Texture2D = null, by: Node = null,
		tab: StringName = &"", entry: String = "") -> void:
	if tree == null:
		return
	var card := tree.get_first_node_in_group(GROUP) as DiscoveryCard
	if card != null:
		card.add({"title": title, "line": line, "icon": icon, "by": by, "tab": tab, "entry": entry})

# The first sentence of `text`, plain (the card says one thing; the rest is in the Codex).
static func first_sentence(text: String) -> String:
	var plain := IconInfo.format(text).replace("\n", " ").strip_edges()
	var regex := RegEx.create_from_string("\\[[^\\]]*\\]")  # Any bbcode left
	plain = regex.sub(plain, "", true)
	var stop := plain.find(". ")
	return plain.substr(0, stop + 1) if stop > 0 else plain

func _ready() -> void:
	name = "DiscoveryCard"
	add_to_group(GROUP)
	process_mode = Node.PROCESS_MODE_ALWAYS  # Real time; it shows over a paused game too
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 20  # Over the HUD's panels at the right edge (the damage meter drew over it); under choice screens' overlays
	visible = false
	add_theme_stylebox_override("panel", UiStyle.panel(14.0, 12.0))
	custom_minimum_size.x = WIDTH
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	_icon.custom_minimum_size = Vector2(ICON, ICON)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_icon)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 2)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(words)
	for label: Label in [_caps, _title, _line, _by]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		words.add_child(label)
	_caps.text = "Discovered"
	UiStyle.caps(_caps, 12, UiStyle.INK_DIM)
	UiStyle.title(_title, 22)
	_line.add_theme_font_size_override("font_size", UiStyle.BODY_SIZE)  # Body size, never toast-small
	_line.add_theme_color_override("font_color", UiStyle.INK)
	_by.add_theme_font_size_override("font_size", 13)
	_by.add_theme_color_override("font_color", UiStyle.INK_DIM)
	tooltip_text = "Tap to read it in the Codex"

func add(item: Dictionary) -> void:
	for queued in _queue:  # The same discovery twice in a moment: once
		if queued.title == item.title:
			return
	if not _now.is_empty() and _now.title == item.title:
		return
	_queue.append(item)
	if not visible:
		_next()

func _process(delta: float) -> void:
	if _now.is_empty():
		if not _queue.is_empty():
			_next()
		return
	if _lesson_up():  # Lessons first: the card steps aside and waits
		visible = false
		return
	if not visible:
		visible = true
		_place()
	_left -= delta / maxf(Engine.time_scale, 0.001)
	modulate.a = clampf(_left / 0.4, 0.0, 1.0) if _left < 0.4 else 1.0  # multiplier: a short fade at the end
	if _left <= 0.0:
		_finish()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		var item := _now
		_finish()
		_open_codex(item)

func _lesson_up() -> bool:
	for lesson in get_tree().get_nodes_in_group(LessonCard.GROUP):
		if (lesson as CanvasItem).visible:
			return true
	return false

func _next() -> void:
	if _queue.is_empty():
		_now = {}
		visible = false
		return
	_now = _queue.pop_front()
	var by = _now.get("by")
	var tower := by as Tower if is_instance_valid(by) else null
	var texture: Texture2D = _now.get("icon")
	if texture == null and tower != null:
		texture = WardenIcon.make_centred(tower.tower_data)
	_icon.texture = texture
	_icon.visible = texture != null
	_title.text = String(_now.title)
	_line.text = String(_now.line)
	_line.visible = _line.text != ""
	_by.text = ("By your %s" % tower.tower_data.display_name) if tower != null else ""
	_by.visible = _by.text != ""
	_left = SHOW_TIME
	modulate.a = 1.0  # multiplier
	visible = not _lesson_up()
	reset_size()
	_place()

func _finish() -> void:
	_now = {}
	_next()

func _place() -> void:
	_place_now()
	_refit.call_deferred()  # Again once its wrapping lines know their width

# Measured at the card's own width (user 2026-10-22 screenshot: measured before its wrapping lines had a width, every
# word counted as a line and the card ran down the whole screen, under the damage meter).
func _refit() -> void:
	await get_tree().process_frame
	if is_instance_valid(self) and visible:
		size = Vector2(WIDTH, 0.0)  # Shrinks to its content
		_place_now()

func _place_now() -> void:
	var view := get_viewport_rect().size
	var height := get_combined_minimum_size().y
	var top := view.y * PC_TOP_SHARE
	if UiStyle.is_phone():
		top = view.y - PHONE_BOTTOM - height
	position = Vector2(view.x - EDGE - WIDTH, maxf(top, EDGE))
	size = Vector2(WIDTH, height)

func _open_codex(item: Dictionary) -> void:
	var pause := get_tree().get_first_node_in_group(&"pause_menu")
	if pause == null:
		var hud := get_parent()
		pause = hud.get_node_or_null("%PauseMenu") if hud != null else null
	if pause != null and pause.has_method("open_codex"):
		pause.open_codex(StringName(item.get("tab", &"")), String(item.get("entry", "")))

# Showing or waiting (tests).
func busy() -> bool:
	return not _now.is_empty() or not _queue.is_empty()
