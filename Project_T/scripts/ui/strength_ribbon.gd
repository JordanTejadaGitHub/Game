extends VBoxContainer
class_name StrengthRibbon

# The strength gauge's ribbon (card pass slice 1, council card_pass_power.md section 4; owner approved 2026-10-16): the
# route in 10 segments, start at the left and the Heartwood at the right, each shaded by the health dispelled there this
# block (GOLD early, Mist mid, Ember late), a tick at one third, a leaf at the Heartwood per leak, the median marked
# under it, the tag and the median as words. Tap (or click) to open what carried the block: the damage lanes, overkill
# and the top cards. At least 48 px tall. Fed RestReport.gauge(); hidden when it's empty. Used by the rest report card
# and the damage meter's "Last block" tab.

const BAR_H := 48.0
const SEGMENTS := 10
const LEAF_ROOM := 34.0  # Right of the bar: the Heartwood's leaves
const TAG_COLORS := {"Overpowered": UiStyle.LIVE, "Strong": UiStyle.GOLD, "Holding": UiStyle.INK_DIM, "Struggling": UiStyle.POOR}

var gauge := {}
var _bar := Control.new()
var _detail: RichTextLabel = StatusLinks.make_label("", UiStyle.TIP_SIZE, UiStyle.INK_DIM)

func _init() -> void:
	name = "StrengthRibbon"
	add_theme_constant_override("separation", 4)
	_bar.name = "Bar"
	_bar.custom_minimum_size = Vector2(0, BAR_H)
	_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_bar.tooltip_text = "Tap for what carried this block"
	_bar.draw.connect(_draw_bar)
	_bar.gui_input.connect(_on_bar_input)
	add_child(_bar)
	_detail.name = "Detail"
	_detail.visible = false
	add_child(_detail)
	visible = false

func set_gauge(value: Dictionary) -> void:
	gauge = value
	visible = not gauge.is_empty()
	_detail.text = StatusLinks.bbcode(String(gauge.get("detail", "")))
	_bar.queue_redraw()

func _on_bar_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	if pressed and not gauge.is_empty():
		_detail.visible = not _detail.visible
		_bar.accept_event()

static func zone_color(share: float) -> Color:
	if share < 1.0 / 3.0:
		return UiStyle.GOLD
	return UiStyle.INK_DIM if share < 0.65 else UiStyle.POOR

func _draw_bar() -> void:
	if gauge.is_empty():
		return
	var font := UiStyle.with_glyphs(UiStyle.body_font())
	var width := maxf(_bar.size.x - LEAF_ROOM, 40.0)
	var seg := width / SEGMENTS
	var top := 2.0
	var height := 20.0
	var bins: Array = gauge.get("bins", [])
	var most := 0.0
	for share in bins:
		most = maxf(most, float(share))
	for i in SEGMENTS:
		var share := float(bins[i]) if i < bins.size() else 0.0
		var colour := zone_color((i + 0.5) / SEGMENTS)
		var rect := Rect2(i * seg + 1.0, top, seg - 2.0, height)
		_bar.draw_rect(rect, Color(colour, 0.12))  # The empty route, faint
		if share > 0.0 and most > 0.0:
			var fill := share / most
			_bar.draw_rect(Rect2(rect.position.x, top + height * (1.0 - fill), rect.size.x, height * fill), Color(colour, 0.85))
	var tick := width / 3.0  # One third of the route: Overpowered dispels before it
	_bar.draw_line(Vector2(tick, 0.0), Vector2(tick, top + height + 3.0), UiStyle.INK, 1.5)
	var median := float(gauge.get("median", 0.0))
	var at := clampf(median, 0.0, 1.0) * width
	_bar.draw_colored_polygon(PackedVector2Array([Vector2(at, top + height + 1.0), Vector2(at - 5.0, top + height + 8.0),
		Vector2(at + 5.0, top + height + 8.0)]), UiStyle.INK)
	var leaks := int(gauge.get("leaked", 0))
	for i in mini(leaks, 3):  # A leaf per leak at the Heartwood end (three, then the count)
		_draw_leaf(Vector2(width + 10.0 + i * 8.0, top + height * 0.5))
	if leaks > 3:
		_bar.draw_string(font, Vector2(width + 6.0, top + height + 12.0), "×%d" % leaks, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiStyle.POOR)
	var tag := String(gauge.get("tag", ""))
	var words := "%s · %d%% along the route" % [tag, roundi(median * 100.0)]
	_bar.draw_string(font, Vector2(0.0, BAR_H - 3.0), words, HORIZONTAL_ALIGNMENT_LEFT, width, 14, TAG_COLORS.get(tag, UiStyle.INK))

func _draw_leaf(centre: Vector2) -> void:
	var points := PackedVector2Array()
	for i in 12:
		var angle := TAU * i / 12.0
		points.append(centre + Vector2(cos(angle) * 3.0, sin(angle) * 6.0).rotated(0.5))
	_bar.draw_colored_polygon(points, UiStyle.POOR)
