extends VBoxContainer

# The HUD's Dreams row (screens_ui.md "Under resources: Dreams"): one small icon per Dream taken
# this run, its shape and colour by rarity (circle, diamond, hexagon, star), the stack count, and the
# card's live bonus under it (`DreamState.get_live_bonus_text`: Few and Mighty, The Last Light, Many
# Hands, Canopy change as Wardens are planted, sold or grown). Hover for the card; click / tap opens
# "Dreams this run" (every card with its stacks and text, so nothing is hover-only: platforms.md).
# Built in code.

const ICON_SIZE := Vector2(30, 30)
const REFRESH_TIME := 0.25  # Live bonuses are re-read this often (real time, also while paused)
const TEXT_COLOR := Color(0.9, 0.92, 0.85)
const LIVE_COLOR := Color(0.75, 0.95, 0.6)
const OFF_COLOR := Color(0.6, 0.6, 0.6)

@onready var dream_state: DreamState = %DreamState

var _row := HFlowContainer.new()
var _list := PanelContainer.new()
var _list_label := Label.new()
var _icons: Array[DreamIcon] = []
var _shown_key := ""  # Which cards / stacks the icons were built for
var _clock := 0.0
var _fog := UiStyle.fog_patch()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_theme_constant_override("h_separation", 4)
	_row.add_theme_constant_override("v_separation", 2)
	add_child(_row)
	_list.visible = false
	_list.mouse_filter = Control.MOUSE_FILTER_STOP
	_list_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_list_label.custom_minimum_size = Vector2(340, 0)
	_list_label.add_theme_font_size_override("font_size", 14)
	_list.add_child(_list_label)
	_list.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_list.visible = false)
	add_child(_list)
	dream_state.card_taken.connect(func(_card: UpgradeData) -> void: refresh())
	refresh.call_deferred()  # After a resumed run has loaded its Dreams

func _process(delta: float) -> void:
	_clock += delta / maxf(Engine.time_scale, 0.001)
	if _clock < REFRESH_TIME:
		return
	_clock = 0.0
	refresh()

# Rebuilds the icons when the cards changed, and updates every live bonus.
func refresh() -> void:
	var cards := dream_state.get_taken_cards()
	var key := ",".join(cards.map(func(c: UpgradeData) -> String: return "%s:%d:%s" % [c.id, dream_state.card_stacks(c.id), _dormant(c)]))
	if key != _shown_key:
		_shown_key = key
		for icon in _icons:
			icon.queue_free()
		_icons.clear()
		for card in cards:
			var icon := DreamIcon.new()
			icon.card = card
			icon.stacks = dream_state.card_stacks(card.id)
			icon.dormant = _dormant(card)
			icon.modulate = Color(0.6, 0.6, 0.65, 0.6) if icon.dormant else Color.WHITE
			icon.custom_minimum_size = ICON_SIZE + Vector2(0, 12)
			icon.pressed.connect(_toggle_list)
			_row.add_child(icon)
			_icons.append(icon)
		if _list.visible:
			_list_label.text = get_list_text()
	for icon in _icons:
		icon.set_live(dream_state.get_live_bonus_text(icon.card))
	queue_redraw()

# A fog patch behind the icons (ui_style.md: the Dreams row has fog, no thread).
func _draw() -> void:
	if _icons.is_empty():
		return
	var width := 0.0
	for icon in _icons:
		width = maxf(width, icon.position.x + icon.size.x)
	draw_style_box(_fog, Rect2(_row.position - Vector2(10, 6), Vector2(width, _row.size.y) + Vector2(20, 12)))

# "Dreams this run": every card, its stacks and live bonus.
func get_list_text() -> String:
	var lines: Array[String] = ["Dreams this run"]
	for icon in _icons:
		var line := icon.card.display_name
		if icon.stacks > 1:
			line += " ×%d" % icon.stacks
		if icon.dormant:
			line += "  (half-dreamed: waits for a family)"
		elif icon.live != "":
			line += "  (%s)" % icon.live
		lines.append("%s: %s" % [line, icon.card.description])
	if _icons.is_empty():
		lines.append("None yet. Dreams come at every rest.")
	return "\n".join(lines)

# A half-dreamed card still asleep (dream_design.md "Adapt, don't get handed"): shown greyed.
func _dormant(card: UpgradeData) -> bool:
	return dream_state.has_method("is_dormant") and dream_state.is_dormant(card)

func _toggle_list() -> void:
	_list.visible = not _list.visible
	if _list.visible:
		_list_label.text = get_list_text()

class DreamIcon extends Control:
	signal pressed

	var card: UpgradeData
	var stacks := 1
	var live := ""  # The live bonus under the icon ("" = none)
	var dormant := false  # Half-dreamed and still asleep: greyed, "Half-dreamed" in the tooltip

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		set_live(live)

	func set_live(text: String) -> void:
		if text == live and tooltip_text != "":
			return
		live = text
		tooltip_text = "%s (%s%s)\n%s%s" % [card.display_name, UpgradeData.rarity_name(card.rarity),
			" ×%d" % stacks if stacks > 1 else "", card.description,
			"\nHalf-dreamed: it works once you own every family it needs." if dormant else ("\nNow: " + live if live != "" else "")]
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit()
			accept_event()

	func _draw() -> void:
		var centre := Vector2(size.x / 2.0, 15.0)
		UiStyle.draw_gem(self, centre, 12.0, card.rarity)
		var font := UiStyle.number_font()
		if stacks > 1:
			var count := str(stacks)
			draw_string_outline(font, centre + Vector2(4, 11), count, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 4, Color(0.05, 0.06, 0.08))
			draw_string(font, centre + Vector2(4, 11), count, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, TEXT_COLOR)
		if live != "":
			var width := font.get_string_size(live, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			var at := Vector2((size.x - width) / 2.0, size.y)
			var tint := OFF_COLOR if live == "off" else LIVE_COLOR
			draw_string_outline(font, at, live, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 4, Color(0.05, 0.06, 0.08))
			draw_string(font, at, live, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, tint)
