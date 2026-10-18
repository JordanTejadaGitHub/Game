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
# The run's Calling (screens_ui.md "Where to recheck your Calling", user 2026-10-13: "nowhere to recheck your Calling
# after you choose"): the first icon, the family's base Warden in a gold frame (not a rarity gem); its tip is the
# name and the rule. Nothing when the run has none (dev runs, old saves).
var _calling_frame: PanelContainer = null
var _calling_shown := ""  # The family the frame was built for

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	TouchBuild.grow_taps(self)  # Phones: the list's buttons at least 44 tall (Mobile UI 2026-10-17)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_theme_constant_override("h_separation", 4)
	_row.add_theme_constant_override("v_separation", 2)
	add_child(_row)
	_list.visible = false
	_list.mouse_filter = Control.MOUSE_FILTER_STOP
	_list.add_theme_stylebox_override("panel", UiStyle.panel())
	var list_column := _list_column
	_list.add_child(list_column)
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list_box.custom_minimum_size = Vector2(LIST_WIDTH - 16.0, 0)
	_list_box.add_theme_constant_override("separation", 4)
	_list_scroll.add_child(_list_box)
	list_column.add_child(_list_scroll)
	var close := _list_close
	close.text = "Close"
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 48 if UiStyle.is_phone() else 40)
	close.pressed.connect(close_list)
	list_column.add_child(close)
	add_child(_list)
	_card_tip = DreamMarks.MarkTip.new()
	add_child(_card_tip)
	dream_state.card_taken.connect(func(_card: UpgradeData) -> void: refresh())
	dream_state.calling_changed.connect(func(_family: String) -> void: refresh())
	if dream_state.has_signal("calling_grew"):  # A Calling evolution taken: the badge shows the new path
		dream_state.calling_grew.connect(func(_id: StringName) -> void: refresh())
	refresh.call_deferred()  # After a resumed run has loaded its Dreams

func _process(delta: float) -> void:
	_clock += delta / maxf(Engine.time_scale, 0.001)
	if _clock < REFRESH_TIME:
		return
	_clock = 0.0
	refresh()

# Rebuilds the icons when the cards changed, and updates every live bonus.
# "Lantern Ring" / "Firefly Jar" / the rule with its tokens as words: {} when the run has no Calling. "path" = the
# Calling and the evolutions taken ("Spore Print → Fairy Ring → …", DreamState.calling_path_text; Roguelite Code
# 3f058f07), the name where nothing has grown yet.
func calling_info() -> Dictionary:
	if dream_state == null or dream_state.calling == "" or dream_state.calling_title() == "":
		return {}
	var family := IconInfo.family_data(dream_state.calling)
	var path: String = dream_state.calling_path_text() if dream_state.has_method("calling_path_text") else ""
	var text: String = DreamState.CALLINGS.tooltip(dream_state.calling)
	var evolutions: String = dream_state.calling_evolutions_text() if dream_state.has_method("calling_evolutions_text") else ""
	if evolutions != "":
		text += "\n\n" + evolutions  # Each evolution's effect under the Calling's (Roguelite Code 2026-10-17)
	return {"name": dream_state.calling_title(), "family": family.display_name if family != null else dream_state.calling.capitalize(),
		"text": text, "data": family, "path": path if path != "" else dream_state.calling_title()}

func _refresh_calling() -> void:
	var info_now := calling_info()
	var family: String = (dream_state.calling + "|" + String(info_now.path)) if not info_now.is_empty() else ""  # Rebuilt when it grows
	if family == _calling_shown:
		return
	_calling_shown = family
	if _calling_frame != null:
		_calling_frame.queue_free()
		_calling_frame = null
	if family == "":
		return
	var info := calling_info()
	_calling_frame = PanelContainer.new()
	_calling_frame.name = "Calling"
	var frame := UiStyle.card(UiStyle.GOLD)  # Moonlit Thread: fog with the gold thread, where Dreams wear a rarity gem
	frame.shadow_size = 0
	for side in ["left", "right", "top", "bottom"]:
		frame.set("content_margin_" + side, 2.0)
	_calling_frame.add_theme_stylebox_override("panel", frame)
	_calling_frame.custom_minimum_size = ICON_SIZE + Vector2(4, 4)
	_calling_frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_calling_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	var face := TextureRect.new()
	face.texture = WardenIcon.make(info.data)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_calling_frame.add_child(face)
	TapTip.attach(_calling_frame, "Calling · %s\n%s" % [info.path, IconInfo.format(info.text)])  # Its path as it grows
	_row.add_child(_calling_frame)
	_row.move_child(_calling_frame, 0)  # Before the Dream cards
	if _list.visible:
		_build_list()

# Phones: the icon strip goes (the HUD's Dreams button opens "Dreams this run" instead; Mobile UI).
var strip_hidden := false:
	set(value):
		strip_hidden = value
		_row.visible = not value
		if value:
			_list.set_meta(&"tips_beside", true)  # Word tips (StatusLinks) open beside the list, never over its text
			_make_phone_page()  # The list becomes a whole screen
		queue_redraw()

func refresh() -> void:
	_refresh_calling()
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
			icon.sleeping_text = _sleeping_text(card) if icon.dormant else ""
			icon.modulate = Color(0.6, 0.6, 0.65, 0.6) if icon.dormant else Color.WHITE  # A multiplier (dormant fade)
			icon.custom_minimum_size = ICON_SIZE + Vector2(0, 12)
			icon.pressed.connect(_toggle_list)
			_row.add_child(icon)
			_icons.append(icon)
		if _list.visible:
			_build_list()
	for icon in _icons:
		icon.credit = credit_text(icon.card)
		icon.set_live(dream_state.get_live_bonus_text(icon.card))
		if _live_labels.has(icon.card.id) and is_instance_valid(_live_labels[icon.card.id]):
			_live_labels[icon.card.id].text = icon.live
	queue_redraw()

# A fog patch behind the icons (ui_style.md: the Dreams row has fog, no thread).
func _draw() -> void:
	if strip_hidden or (_icons.is_empty() and _calling_frame == null):
		return
	var width := 0.0
	if _calling_frame != null:
		width = _calling_frame.position.x + _calling_frame.size.x
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
	var calling := calling_info()
	if not calling.is_empty():
		lines.append("Calling: %s (%s): %s" % [calling.path, calling.family, IconInfo.format(calling.text)])
	if dream_state.supply_line() != "":
		lines.append(dream_state.supply_line())
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
	if _phone_page:  # The page's header holds the title and the count
		_count_label.text = "%d Dream%s" % [_icons.size(), "" if _icons.size() == 1 else "s"]
	else:
		var title := Label.new()
		title.text = "Dreams this run"
		UiStyle.title(title, 20)
		_list_box.add_child(title)
	var calling := calling_info()
	if not calling.is_empty():  # The run's standing rule, above the cards
		var calling_head := Label.new()
		calling_head.text = "Calling"
		UiStyle.caps(calling_head, PHONE_CAPS_SIZE if _phone_page else UiStyle.LABEL_SIZE)
		_list_box.add_child(calling_head)
		var calling_line := HSeparator.new()
		calling_line.modulate = Color(UiStyle.GOLD, 0.35)
		_list_box.add_child(calling_line)
		var calling_name := Label.new()
		calling_name.name = "CallingName"
		calling_name.text = "%s · %s family" % [calling.path, calling.family]
		UiStyle.title(calling_name, PHONE_NAME_SIZE if _phone_page else 16, UiStyle.GOLD)
		_list_box.add_child(calling_name)
		var calling_rule := StatusLinks.make_label(calling.text, PHONE_BODY_SIZE if _phone_page else 14, UiStyle.INK)
		calling_rule.name = "CallingRule"
		_list_box.add_child(calling_rule)
	if dream_state.supply_line() != "":  # Rerolls and let-gos are a run-long supply (DreamState)
		var supply := Label.new()
		supply.name = "Supply"
		supply.text = dream_state.supply_line()
		UiStyle.caps(supply, PHONE_CAPS_SIZE if _phone_page else UiStyle.LABEL_SIZE)
		_list_box.add_child(supply)
	if _icons.is_empty():
		var none := Label.new()
		none.text = "None yet. Dreams come at every rest."
		UiStyle.caps(none, PHONE_SMALL_SIZE if _phone_page else UiStyle.LABEL_SIZE)
		_list_box.add_child(none)
	for group in GROUPS:
		var icons := _icons.filter(func(i: DreamIcon) -> bool: return group_of(i.card) == group)
		if icons.is_empty():
			continue
		var header := Label.new()
		header.text = group
		UiStyle.caps(header, PHONE_CAPS_SIZE if _phone_page else UiStyle.LABEL_SIZE)
		_list_box.add_child(header)
		var line := HSeparator.new()
		line.modulate = Color(UiStyle.GOLD, 0.35)
		_list_box.add_child(line)
		if _phone_page:
			_add_phone_rows(icons)
			continue
		for icon in icons:
			_list_box.add_child(_card_row(icon))
	if _phone_page:
		return  # The scroll fills the page
	var cap := LIST_MAX_HEIGHT
	if strip_hidden:  # Phones: the list (and its Close) end above the Warden dock (user screenshot 2026-10-15)
		cap = maxf(minf(cap, get_viewport_rect().size.y - 300.0), 140.0)
	_list_scroll.custom_minimum_size = Vector2(LIST_WIDTH, minf(_list_box.get_combined_minimum_size().y, cap))

func _card_row(source: DreamIcon) -> Control:
	var card := source.card
	var frame := PanelContainer.new()
	frame.name = "Row_" + card.id
	frame.mouse_filter = Control.MOUSE_FILTER_STOP
	var legendary := card.rarity == UpgradeData.Rarity.LEGENDARY
	# Legendaries get a card of their own (Moonlit Thread: solid fog, the thread in Legendary gold); the
	# others sit flat on the panel.
	var style: StyleBox = UiStyle.card(UiStyle.rarity_color(card.rarity)) if legendary else StyleBoxEmpty.new()
	var pad := 8 if _phone_page else 6
	style.content_margin_left = pad
	style.content_margin_right = pad
	style.content_margin_top = pad
	style.content_margin_bottom = pad
	if legendary:
		(style as MoonStyleBox).shadow_size = 0
	frame.add_theme_stylebox_override("panel", style)
	if _phone_page:
		frame.custom_minimum_size.y = UiStyle.HUD_BUTTON_H  # A tap target's height at least
		frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(row)
	var gem := DreamIcon.new()
	gem.card = card
	gem.stacks = 1  # The badge is in the name line
	gem.custom_minimum_size = PHONE_GEM if _phone_page else ICON_SIZE
	if _phone_page:
		gem.radius = PHONE_GEM_RADIUS
		gem.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(gem)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name := Label.new()
	name.text = card.display_name + (("  ×%d" % source.stacks) if source.stacks > 1 else "")
	UiStyle.title(name, PHONE_NAME_SIZE if _phone_page else 16, UpgradeData.rarity_color(card.rarity))
	text.add_child(name)
	if dream_state.has_method("opened_clearing") and dream_state.opened_clearing(card):
		var opened := Label.new()
		opened.text = DreamState.OPENED_CLEARING_LINE  # dream_design.md "Make the unlock obvious"
		UiStyle.caps(opened, PHONE_CAPS_SIZE if _phone_page else 13, UiStyle.GOLD)
		text.add_child(opened)
	var body := StatusLinks.make_label(card.description, PHONE_BODY_SIZE if _phone_page else 14, UiStyle.INK)
	body.mouse_filter = Control.MOUSE_FILTER_PASS
	text.add_child(body)
	if CardDiagram.has_diagram(card):  # Placement cards show their diagram (dream_design.md)
		text.add_child(CardDiagram.make(card))
	if source.credit != "":  # Feeling the cards: what it did this run
		var credit := Label.new()
		credit.name = "Credit"
		credit.text = source.credit
		UiStyle.number(credit, PHONE_SMALL_SIZE if _phone_page else 14, UiStyle.GOLD)
		text.add_child(credit)
	if source.dormant:  # Not active yet: dimmed, and why ("Not active yet: needs a Water Warden"; no NeedsRow)
		var needs := Label.new()
		needs.text = _sleeping_text(card)
		needs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		needs.add_theme_font_size_override("font_size", PHONE_SMALL_SIZE if _phone_page else 13)
		needs.add_theme_color_override("font_color", UiStyle.INK_DIM)
		text.add_child(needs)
		frame.modulate = Color(1, 1, 1, 0.55)
	# Keyword chips (2026-10-16) at the entry's foot, quiet in the rarity colour, as on the Dream card (screens_ui.md
	# 844fa70a: the name and text read first)
	var keyword_row := KeywordRow.make(DreamState.KEYWORDS.chips_for_card(card), UiStyle.CHIP_ICON,
		UpgradeData.rarity_color(card.rarity), PHONE_CAPS_SIZE if _phone_page else 12)
	if keyword_row != null:
		text.add_child(keyword_row)
	row.add_child(text)
	var live := Label.new()
	_live_labels[card.id] = live
	live.text = source.live
	live.custom_minimum_size = Vector2(96 if _phone_page else 70, 0)
	live.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	live.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiStyle.number(live, PHONE_SMALL_SIZE + 1 if _phone_page else 15,UiStyle.INK_DIM if source.live.begins_with("off") else UiStyle.GOLD)
	row.add_child(live)
	frame.gui_input.connect(func(event: InputEvent) -> void:
		if strip_hidden:
			return  # Phones: the row already shows the whole card; its tip only covered the list (user screenshot)
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_card_tip.show_card(frame, card, frame.get_global_rect().get_center(), DreamMarks.MarkTip.TAP_TIME)
			frame.accept_event())
	return frame

# "Needs: Soaked + Charged" / "Needs: Nestling family" (DreamState.needs_text, dream_design.md "How
# Needs are shown on a card": never the name of a Warden you don't have).
func _needs_text(card: UpgradeData) -> String:
	if dream_state.has_method("needs_text"):
		var text: String = dream_state.needs_text(card)
		if text != "":
			return IconInfo.format(text)
	return "Needs: " + _missing_text(card)

# "Dewdrop (a family pick after the next boss)" for a sleeping half-dreamed card.
func _missing_text(card: UpgradeData) -> String:
	if dream_state.has_method("half_dreamed_missing"):
		var missing: Array = dream_state.half_dreamed_missing(card)
		if not missing.is_empty():
			return ", ".join(missing.map(func(id: String) -> String: return CodexData.FAMILY_NAMES.get(id, id.capitalize())))
	return "a family you don't have yet"

# "Needs Dewdrop" for a sleeping card (dream_design.md half-dreamed "Card face"; no "Half-dreamed" label).
func _sleeping_text(card: UpgradeData) -> String:
	var reason: String = dream_state.not_active_reason(card) if dream_state.has_method("not_active_reason") else ""
	if reason != "":
		return reason  # "Not active yet: needs a Water Warden" (dream_design.md 2026-10-01)
	var needs: Array = dream_state.missing_needs(card) if dream_state.has_method("missing_needs") else []
	var text := NeedsRow.text(needs)  # By family, never a damage type (Nightmare Kinds)
	return text if text != "" else _needs_text(card)

# A card still asleep until its families are yours (dream_design.md "Adapt, don't get handed"), or not active yet
# (needs a Warden you don't have): shown greyed, its hover says why.
func _dormant(card: UpgradeData) -> bool:
	return (dream_state.has_method("is_dormant") and dream_state.is_dormant(card)) \
		or (dream_state.has_method("not_active_reason") and dream_state.not_active_reason(card) != "")  # Or waiting on a Warden it needs

# "This run: +1,840" / "This run: +60 Dew" (dream_design.md "Feeling the cards"; DreamState's credit), "" before any.
func credit_text(card: UpgradeData) -> String:
	if not dream_state.has_method("get_card_credit"):
		return ""
	var credit: Dictionary = dream_state.get_card_credit(card.id, &"run")
	if float(credit.get("amount", 0.0)) <= 0.0 and float(credit.get("damage", 0.0)) <= 0.0:
		return ""
	var text := String(credit.get("text", ""))
	var at := text.find(" · ")
	return "This run: " + (text.substr(at + 3) if at >= 0 else text)

# One left panel at a time (screens_ui.md principle 5; user screenshot: "Dreams this run" over the Warden panel, its
# Close over the panel's header): opening the list clears the Warden selection (its panel and name tag go), and picking
# a Warden closes the list.
func _toggle_list() -> void:
	_list.visible = not _list.visible
	if _list.visible and _phone_page:
		_raise_page()
	var seller := get_node_or_null("%TowerSeller") as TowerSeller
	if seller != null and not seller.selection_changed.is_connected(_on_selection):
		seller.selection_changed.connect(_on_selection)
	if _list.visible:
		if seller != null and seller.selected != null:
			seller.select(null)
		_build_list()

func _on_selection(towers: Array[Tower]) -> void:
	if not towers.is_empty() and _list.visible:
		_list.visible = false

func close_list() -> void:
	_list.visible = false

# --- Phones: "Dreams this run" is a whole screen (user 2026-10-17: "make it a whole screen UI … buttons appropriate sizes
# … text readable"), in the phone Remember screen's / pause menu's look: the card background over the whole screen with one
# sprout on its thread, a header (title, the count, a square Close), the Calling, then the Dreams in a scroll that fills the
# rest, two columns on wide screens. Nothing under 15 px; rows at least 48 tall. The PC keeps its panel.
const PHONE_TITLE_SIZE := 28
const PHONE_NAME_SIZE := 21
const PHONE_BODY_SIZE := 17
const PHONE_SMALL_SIZE := 16  # Live values, credits and "needs" lines
const PHONE_CAPS_SIZE := 15  # Headers, keyword chips: the smallest text on the page
const PHONE_GEM := Vector2(44, 44)
const PHONE_GEM_RADIUS := 18.0
const PHONE_TWO_COLUMNS := 900.0  # Pages at least this wide list the Dreams in two columns
const PHONE_CENTER_ALPHA := 0.97  # A solid page: the map doesn't read through
const PHONE_EDGE_ALPHA := 0.95

var _list_column := VBoxContainer.new()
var _list_close := Button.new()
var _phone_page := false
var _count_label: Label = null

func _make_phone_page() -> void:
	if _phone_page:
		return
	_phone_page = true
	_list.name = "DreamsPage"
	_list.top_level = true  # Out of the row's layout: the page fills the HUD layer's rect
	_list.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame := UiStyle.panel(16, 12)
	frame.fog_color = UiStyle.FOG
	frame.glow_color = UiStyle.CARD_BG
	frame.center_alpha = PHONE_CENTER_ALPHA
	frame.edge_alpha = PHONE_EDGE_ALPHA
	frame.thread = MoonStyleBox.TopLine.FULL  # The one sprout, on the outer thread
	frame.diamond = true
	frame.side_edges = false
	_list.add_theme_stylebox_override("panel", frame)
	_list_column.add_theme_constant_override("separation", 8)
	_list_column.remove_child(_list_close)
	_list_close.queue_free()
	var header := HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 14)
	var title := Label.new()
	title.text = "Dreams this run"
	UiStyle.title(title, PHONE_TITLE_SIZE)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(title)
	_count_label = Label.new()
	_count_label.name = "Count"
	UiStyle.caps(_count_label, PHONE_SMALL_SIZE)
	_count_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_count_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var close := Button.new()
	close.name = "PhoneClose"
	close.theme_type_variation = &"HudButton"  # Square, like the Warden drawer's
	close.focus_mode = Control.FOCUS_NONE
	close.tooltip_text = "Close"
	close.custom_minimum_size = Vector2(UiStyle.HUD_BUTTON_H, UiStyle.HUD_BUTTON_H)
	close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close.draw.connect(_draw_close.bind(close))
	close.pressed.connect(close_list)
	header.add_child(close)
	_list_column.add_child(header)
	_list_column.move_child(header, 0)
	_list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list_scroll.custom_minimum_size = Vector2.ZERO
	_list_box.custom_minimum_size = Vector2.ZERO
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", 6)
	_list.visibility_changed.connect(_sync_hud_button)
	if _list.visible:
		_build_list()

# The HUD's Dreams button follows the page at once (Close, Back, a Warden picked), not at its next throttled sync.
func _sync_hud_button() -> void:
	var hud := get_parent()
	if hud != null and hud.has_method("_sync_phone_buttons"):
		hud.call("_sync_phone_buttons")

func _draw_close(button: Button) -> void:
	var centre := (button.size / 2.0).floor()
	var colour := UiStyle.GOLD if button.is_hovered() else UiStyle.INK_DIM
	var s := 7.0
	button.draw_line(centre + Vector2(-s, -s), centre + Vector2(s, s), colour, 2.0, true)
	button.draw_line(centre + Vector2(s, -s), centre + Vector2(-s, s), colour, 2.0, true)

# One group's rows: two columns side by side on a wide page (reading order: left, then right), else one.
func _add_phone_rows(icons: Array) -> void:
	if get_viewport_rect().size.x < PHONE_TWO_COLUMNS or icons.size() < 2:
		for icon in icons:
			_list_box.add_child(_card_row(icon))
		return
	var pair := HBoxContainer.new()
	pair.add_theme_constant_override("separation", 20)
	var columns: Array[VBoxContainer] = []
	for i in 2:
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 6)
		pair.add_child(column)
		columns.append(column)
	for i in icons.size():
		columns[i % 2].add_child(_card_row(icons[i]))
	_list_box.add_child(pair)

# The page draws over the HUD's top-right row and the Warden dock: the row goes to the HUD's end, then the HUD puts its
# full-screen overlays (the pause menu …) back above it (hud.gd _raise_overlays keeps the open page under them).
func _raise_page() -> void:
	var hud := get_parent()
	if hud == null:
		return
	hud.move_child(self, hud.get_child_count() - 1)
	if hud.has_method("_raise_overlays"):
		hud.call("_raise_overlays")

# Android Back (open_menu) closes the page first (before the pause menu would open).
func _input(event: InputEvent) -> void:
	if _phone_page and _list.visible and InputMap.has_action("open_menu") and event.is_action_pressed("open_menu"):
		close_list()
		get_viewport().set_input_as_handled()

class DreamIcon extends Control:
	signal pressed

	var card: UpgradeData
	var stacks := 1
	var radius := 12.0  # The gem's (phones' list rows draw it bigger)
	var live := ""  # The live bonus under the icon ("" = none)
	var dormant := false  # Asleep until its families are yours: greyed, "Needs Dewdrop" in the tooltip
	var sleeping_text := ""
	var credit := ""  # "This run: +1,840" (DreamsRow.credit_text)

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		set_live(live)

	var _tip_credit := ""

	func set_live(text: String) -> void:
		if text == live and credit == _tip_credit and tooltip_text != "":
			return
		live = text
		_tip_credit = credit
		tooltip_text = "%s (%s%s)\n%s%s%s%s" % [card.display_name, UpgradeData.rarity_name(card.rarity),
			" ×%d" % stacks if stacks > 1 else "", IconInfo.format(card.description),
			("\n" + IconInfo.format(card.tip)) if card.tip != "" else "",  # The card's detail (Sunlit Rest: which rank, who)
			"\n" + sleeping_text if dormant else ("\nNow: " + live if live != "" else ""),
			"\n" + credit if credit != "" else ""]
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit()
			accept_event()

	func _draw() -> void:
		var centre := Vector2(size.x / 2.0, radius + 3.0)
		UiStyle.draw_gem(self, centre, radius, card.rarity, UiStyle.dream_glyph(card))  # The card's glyph in its gem
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
