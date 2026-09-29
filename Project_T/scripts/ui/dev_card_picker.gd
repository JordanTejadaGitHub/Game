extends Control
class_name DevCardPicker

# Developer card grid (demo_scope.md "Pick any card"): every Dream card in the game (all rarities,
# Grove-only, Legendary, Deepened), filtered by name, tag, rarity and family, each with its full text
# and a "not normally offered: needs …" note. Picking one calls `on_pick(card)` and closes. Opened
# by the Dream screen's "Dev: any card…" and the Test Grove panel; dev runs of debug builds only.
# Built in code; UI Code does the look.

const CARD_SIZE := Vector2(230, 150)
const COLUMNS := 4

var dream_state: DreamState
var on_pick: Callable
var _search := LineEdit.new()
var _rarity := OptionButton.new()
var _tag := OptionButton.new()
var _family := OptionButton.new()
var _grid := GridContainer.new()
var _tags: Array[String] = []
var _families: Array[TowerData] = []

# Opens the grid over `parent`. `pick` receives the chosen card; the grid closes itself after.
static func open(parent: Node, dreams: DreamState, pick: Callable) -> DevCardPicker:
	var picker := DevCardPicker.new()
	picker.dream_state = dreams
	picker.on_pick = pick
	parent.add_child(picker)
	return picker

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(UiStyle.FOG, 0.9)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	var title := Label.new()
	title.text = "Dev: any card"
	UiStyle.display(title, 26)
	box.add_child(title)

	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 8)
	box.add_child(filters)
	_search.placeholder_text = "Search name or text…"
	_search.custom_minimum_size = Vector2(260, 40)
	_search.text_changed.connect(func(_t: String) -> void: _refresh())
	filters.add_child(_search)
	_rarity.add_item("Any rarity")
	for rarity in UpgradeData.Rarity.size():
		_rarity.add_item(UpgradeData.rarity_name(rarity))
	_tag.add_item("Any tag")
	for card in dreams_pool():
		for tag in card.tags:
			if not _tags.has(tag):
				_tags.append(tag)
	_tags.sort()
	for tag in _tags:
		_tag.add_item(tag)
	_family.add_item("Any family")
	for root in _family_roots():
		_families.append(root)
		_family.add_item(root.display_name)
	for option in [_rarity, _tag, _family]:
		option.focus_mode = Control.FOCUS_NONE
		option.custom_minimum_size = Vector2(0, 40)
		option.item_selected.connect(func(_i: int) -> void: _refresh())
		filters.add_child(option)
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.custom_minimum_size = Vector2(100, 40)
	close_button.pressed.connect(queue_free)
	filters.add_child(close_button)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(_grid)
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		queue_free()
		get_viewport().set_input_as_handled()

func dreams_pool() -> Array[UpgradeData]:
	var cards: Array[UpgradeData] = DreamState.load_pool()  # Every card in the game, not just this run's pool
	for card in dream_state.pool:
		if not cards.any(func(c: UpgradeData) -> bool: return c.id == card.id):
			cards.append(card)  # Blessings and other cards MetaRun added
	cards.sort_custom(func(a: UpgradeData, b: UpgradeData) -> bool: return a.display_name < b.display_name)
	return cards

func _family_roots() -> Array[TowerData]:
	var roots: Array[TowerData] = []
	for root in dream_state._family_roots():
		roots.append(root)
	return roots

# The cards matching the filters.
func matching() -> Array[UpgradeData]:
	var query := _search.text.strip_edges().to_lower()
	var out: Array[UpgradeData] = []
	for card in dreams_pool():
		if query != "" and not (card.display_name.to_lower().contains(query) or card.description.to_lower().contains(query)):
			continue
		if _rarity.selected > 0 and card.rarity != _rarity.selected - 1:
			continue
		if _tag.selected > 0 and not card.tags.has(_tags[_tag.selected - 1]):
			continue
		if _family.selected > 0 and not _of_family(card, _families[_family.selected - 1]):
			continue
		out.append(card)
	return out

# A card belongs to a family by its line tag or a Warden of that family in its Needs.
func _of_family(card: UpgradeData, root: TowerData) -> bool:
	if card.tags.has(root.line):
		return true
	for id in card.requires + card.requires_any:
		if dream_state.family_of(id) == root.get_id():
			return true
	return false

func _refresh() -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	for card in matching():
		_grid.add_child(_make_card(card))

func _make_card(card: UpgradeData) -> Button:
	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.focus_mode = Control.FOCUS_NONE
	UiStyle.card_button(button, UpgradeData.rarity_color(card.rarity))
	button.pressed.connect(func() -> void:
		if on_pick.is_valid():
			on_pick.call(card)
		queue_free())
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 10
	box.offset_top = 8
	box.offset_right = -10
	box.offset_bottom = -8
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	var stacks := dream_state.card_stacks(card.id)
	_label(box, "%s · %s%s" % [UpgradeData.rarity_name(card.rarity), card.display_name,
		" (×%d)" % stacks if stacks > 0 else ""], UiStyle.INK, 15)
	var text := _label(box, IconInfo.format(card.description) + (("\n" + IconInfo.format(card.cost_description)) if card.cost_description != "" else ""),
		UiStyle.INK_DIM, 12)
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var note := dream_state.needs_note(card)
	if note != "":
		_label(box, note, UiStyle.POOR, 11)
	return button

func _label(box: VBoxContainer, text: String, colour: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", colour)
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	return label
