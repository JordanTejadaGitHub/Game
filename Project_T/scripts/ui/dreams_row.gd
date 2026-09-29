extends VBoxContainer
class_name DreamsRow

# The HUD's Dreams row (screens_ui.md "Under resources: Dreams"): one small icon per Dream taken
# this run, its shape and colour by rarity (circle, diamond, hexagon, star), the stack count, and the
# card's live bonus under it (`DreamState.get_live_bonus_text`: Few and Mighty, The Last Light, Many
# Hands, Canopy change as Wardens are planted, sold or grown). Hover for the card; click / tap opens
# "Dreams this run" (every card with its stacks and text, so nothing is hover-only: platforms.md).
# Built in code.

const ICON_SIZE := Vector2(30, 30)
const REFRESH_TIME := 0.25  # Live bonuses are re-read this often (real time, also while paused)
const TEXT_COLOR := UiStyle.INK
const LIVE_COLOR := UiStyle.LIVE
const OFF_COLOR := UiStyle.OFF

@onready var dream_state: DreamState = %DreamState

var _row := HFlowContainer.new()
var _list := PanelContainer.new()

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
	_list.add_theme_stylebox_override("panel", UiStyle.panel())
	var list_column := VBoxContainer.new()
	_list.add_child(list_column)
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list_box.custom_minimum_size = Vector2(LIST_WIDTH - 16.0, 0)
	_list_box.add_theme_constant_override("separation", 4)
	_list_scroll.add_child(_list_box)
	list_column.add_child(_list_scroll)
	var close := Button.new()
	close.text = "Close"
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 40)
	close.pressed.connect(func() -> void: _list.visible = false)
	list_column.add_child(close)
	add_child(_list)
	_card_tip = DreamMarks.MarkTip.new()
	add_child(_card_tip)
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
			_build_list()
	for icon in _icons:
		icon.set_live(dream_state.get_live_bonus_text(icon.card))
		if _live_labels.has(icon.card.id) and is_instance_valid(_live_labels[icon.card.id]):
			_live_labels[icon.card.id].text = icon.live
	queue_redraw()

# A fog patch behind the icons (ui_style.md: the Dreams row has fog, no thread).
func _draw() -> void:
	if _icons.is_empty():
		return
	var width := 0.0
	for icon in _icons:
		width = maxf(width, icon.position.x + icon.size.x)
	draw_style_box(_fog, Rect2(_row.position - Vector2(10, 6), Vector2(width, _row.size.y) + Vector2(20, 12)))

# --- "Dreams this run" (screens_ui.md "Dreams this run panel", redesigned 2026-09-28) --------------
# One row per card: rarity gem, the name in its rarity colour, a stack badge, the effect with status
# links (IconInfo tokens filled in, never raw "{spored}"), and the live value in gold on the right.
# Grouped under Damage and stats · Wardens and maze · Combos and statuses · Economy · Legendary;
# Legendaries get a gold rim, sleeping half-dreamed cards are dimmed with their "needs" line. Tap a
# row for the full card (DreamMarks.MarkTip). Scrolls when long.

const GROUPS := ["Damage and stats", "Wardens and maze", "Combos and statuses", "Economy", "Legendary"]
const LIST_WIDTH := 420.0
const LIST_MAX_HEIGHT := 460.0

var _list_scroll := ScrollContainer.new()
var _list_box := VBoxContainer.new()
var _card_tip: DreamMarks.MarkTip = null
var _live_labels := {}  # Card id -> its row's live value (updated with the icons)

# Which group a card is listed under.
static func group_of(card: UpgradeData) -> String:
	if card.rarity == UpgradeData.Rarity.LEGENDARY:
		return "Legendary"
	if card.kind == UpgradeData.Kind.ECONOMY or card.dew_now != 0 or card.dew_per_clear != 0 \
			or card.rest_bonus_add != 0 or card.evolve_discount > 0.0 or card.set_cost_warden != "" \
			or card.max_leaves_add != 0 or card.leaves_now != 0 or card.dreamlight_now != 0:
		return "Economy"
	if card.status_id != &"" or card.min_reaction_pairs > 0 or card.requires_status != &"" \
			or card.entwined or card.min_owned_statuses > 0:
		return "Combos and statuses"
	if card.kind == UpgradeData.Kind.STAT:
		return "Damage and stats"
	return "Wardens and maze"

# Plain text of the list (tests, and the pause menu's run summary).
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
		lines.append("%s: %s" % [line, IconInfo.format(icon.card.description)])
	if _icons.is_empty():
		lines.append("None yet. Dreams come at every rest.")
	return "\n".join(lines)

func _build_list() -> void:
	_live_labels.clear()
	for child in _list_box.get_children():
		_list_box.remove_child(child)
		child.queue_free()
	var title := Label.new()
	title.text = "Dreams this run"
	UiStyle.title(title, 20)
	_list_box.add_child(title)
	if _icons.is_empty():
		var none := Label.new()
		none.text = "None yet. Dreams come at every rest."
		UiStyle.caps(none)
		_list_box.add_child(none)
	for group in GROUPS:
		var icons := _icons.filter(func(i: DreamIcon) -> bool: return group_of(i.card) == group)
		if icons.is_empty():
			continue
		var header := Label.new()
		header.text = group
		UiStyle.caps(header)
		_list_box.add_child(header)
		var line := HSeparator.new()
		line.modulate = Color(UiStyle.GOLD, 0.35)
		_list_box.add_child(line)
		for icon in icons:
			_list_box.add_child(_card_row(icon))
	_list_scroll.custom_minimum_size = Vector2(LIST_WIDTH, minf(_list_box.get_combined_minimum_size().y, LIST_MAX_HEIGHT))

func _card_row(source: DreamIcon) -> Control:
	var card := source.card
	var frame := PanelContainer.new()
	frame.name = "Row_" + card.id
	frame.mouse_filter = Control.MOUSE_FILTER_STOP
	var legendary := card.rarity == UpgradeData.Rarity.LEGENDARY
	# Legendaries get a card of their own (Moonlit Thread: solid fog, the thread in Legendary gold); the
	# others sit flat on the panel.
	var style: StyleBox = UiStyle.card(UiStyle.rarity_color(card.rarity)) if legendary else StyleBoxEmpty.new()
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	if legendary:
		(style as MoonStyleBox).shadow_size = 0
	frame.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(row)
	var gem := DreamIcon.new()
	gem.card = card
	gem.stacks = 1  # The badge is in the name line
	gem.custom_minimum_size = ICON_SIZE
	gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(gem)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name := Label.new()
	name.text = card.display_name + (("  ×%d" % source.stacks) if source.stacks > 1 else "")
	UiStyle.title(name, 16, UpgradeData.rarity_color(card.rarity))
	text.add_child(name)
	var body := StatusLinks.make_label(card.description, 14, UiStyle.INK)
	body.mouse_filter = Control.MOUSE_FILTER_PASS
	text.add_child(body)
	if source.dormant:  # Half-dreamed and asleep: what it waits for
		var needs := Label.new()
		needs.text = "Half-dreamed: needs " + _missing_text(card)
		needs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiStyle.caps(needs, 13)
		text.add_child(needs)
		frame.modulate = Color(1, 1, 1, 0.55)
	row.add_child(text)
	var live := Label.new()
	_live_labels[card.id] = live
	live.text = source.live
	live.custom_minimum_size = Vector2(70, 0)
	live.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	live.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiStyle.number(live, 15, UiStyle.INK_DIM if source.live.begins_with("off") else UiStyle.GOLD)
	row.add_child(live)
	frame.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_card_tip.show_card(frame, card, frame.get_global_rect().get_center(), DreamMarks.MarkTip.TAP_TIME)
			frame.accept_event())
	return frame

# "Dewdrop (a family pick after the next boss)" for a sleeping half-dreamed card.
func _missing_text(card: UpgradeData) -> String:
	if dream_state.has_method("half_dreamed_missing"):
		var missing: Array = dream_state.half_dreamed_missing(card)
		if not missing.is_empty():
			return ", ".join(missing.map(func(id: String) -> String: return CodexData.FAMILY_NAMES.get(id, id.capitalize())))
	return "a family you don't have yet"

# A half-dreamed card still asleep (dream_design.md "Adapt, don't get handed"): shown greyed.
func _dormant(card: UpgradeData) -> bool:
	return dream_state.has_method("is_dormant") and dream_state.is_dormant(card)

func _toggle_list() -> void:
	_list.visible = not _list.visible
	if _list.visible:
		_build_list()

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
			" ×%d" % stacks if stacks > 1 else "", IconInfo.format(card.description),
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
			draw_string_outline(font, centre + Vector2(4, 11), count, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 4, UiStyle.FOG)
			draw_string(font, centre + Vector2(4, 11), count, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, TEXT_COLOR)
		if live != "":
			var width := font.get_string_size(live, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			var at := Vector2((size.x - width) / 2.0, size.y)
			var tint := OFF_COLOR if live == "off" else LIVE_COLOR
			draw_string_outline(font, at, live, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 4, UiStyle.FOG)
			draw_string(font, at, live, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, tint)
