extends VBoxContainer
class_name GroveCardList

# The node card's list of what a Grove node adds to the pool (meta_design.md 95e464a4 / 46fde401, user: "need to add
# more description of the cards being added to the pool"): one row per Dream card: rarity gem, name, the card's
# effect with status links, small tags "defining" / "+ II" (a Deepened card on the same node folds into its base's
# row). Restless Omens lists its Omens the same way: name, twist, reward. Every row is a button (48 px+, touch):
# tapping it emits `card_pressed` / `omen_pressed` for the full face. Sleeping nodes in the demo list theirs too.

signal card_pressed(card: UpgradeData)
signal omen_pressed(omen: OmenData)

const DREAM_DIR := "res://resource/dream/"
const OMEN_DIR := "res://resource/omen/"
const ROW_TEXT_SIZE := 14
const TAG_SIZE := 12

var inner_width := 300.0  # Text width inside a row

func _init() -> void:
	add_theme_constant_override("separation", 6)

# Rows for `unlock` (none when it adds no cards or Omens).
func show_for(unlock: UnlockData) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if unlock == null:
		return
	for card in cards_of(unlock):
		add_child(_card_row(card, unlock.dream_cards.has(card.id + "_ii")))
	for omen in omens_of(unlock):
		add_child(_omen_row(omen))

func is_empty() -> bool:
	return get_child_count() == 0

# The node's Dream cards, a Deepened II left out when its base is on the same node (its row says "+ II").
static func cards_of(unlock: UnlockData) -> Array[UpgradeData]:
	var result: Array[UpgradeData] = []
	for id in unlock.dream_cards:
		if id.ends_with("_ii") and unlock.dream_cards.has(id.trim_suffix("_ii")):
			continue
		var card := load_card(id)
		if card != null:
			result.append(card)
	return result

static func load_card(id: String) -> UpgradeData:
	var path := DREAM_DIR + id + ".tres"
	return load(path) as UpgradeData if ResourceLoader.exists(path) else null

# The Omens this node opens (OmenData.requires_grove), in name order.
static func omens_of(unlock: UnlockData) -> Array[OmenData]:
	var result: Array[OmenData] = []
	for file in ResourceLoader.list_directory(OMEN_DIR):
		if not file.ends_with(".tres"):
			continue
		var omen := load(OMEN_DIR + file) as OmenData
		if omen != null and omen.requires_grove == unlock.id:
			result.append(omen)
	result.sort_custom(func(a: OmenData, b: OmenData) -> bool: return a.display_name < b.display_name)
	return result

# The reward in plain words, from the Omen's base numbers (they grow with the act in the run).
static func omen_reward_text(omen: OmenData) -> String:
	var parts: Array[String] = []
	if omen.reward_dew > 0:
		parts.append("%s at the rest" % UiStyle.dew_amount(omen.reward_dew, true))
	if omen.reward_pot_multiplier > 0.0:
		parts.append("the block's Dew back, and more")
	if omen.reward_seeds > 0:
		parts.append(UiStyle.seeds_amount(omen.reward_seeds, true))
	if omen.reward_extra_dream_cards > 0:
		parts.append("%d more %s in the next Dream" % [omen.reward_extra_dream_cards, "card" if omen.reward_extra_dream_cards == 1 else "cards"])
	elif omen.reward_rare_dreams > 0:
		parts.append("a Rare or better card in the next Dream")
	if omen.reward_rest_bonus_multiplier > 1.0:
		parts.append("the rest bonus ×%s" % str(omen.reward_rest_bonus_multiplier).trim_suffix(".0"))
	if parts.is_empty():
		return ""
	return "Reward: " + ", ".join(parts) + "; less for each leaf you lose."

func _card_row(card: UpgradeData, deepens: bool) -> Button:
	var row := _row_button(UpgradeData.rarity_color(card.rarity))
	row.name = card.id
	row.pressed.connect(func() -> void: card_pressed.emit(card))
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gem := Control.new()
	gem.custom_minimum_size = Vector2(24, 24)
	gem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gem.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var glyph := UiStyle.dream_glyph(card)
	gem.draw.connect(func() -> void: UiStyle.draw_gem(gem, gem.size / 2.0, 11.0, card.rarity, glyph))
	line.add_child(gem)
	var name_label := Label.new()
	name_label.text = card.display_name
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.title(name_label, 17)
	line.add_child(name_label)
	if card.tags.has("defining") or card.rarity == UpgradeData.Rarity.LEGENDARY:  # DreamState.is_defining's rule
		line.add_child(_tag("defining", UpgradeData.rarity_color(card.rarity)))
	if deepens:
		line.add_child(_tag("+ II", UiStyle.GOLD))
	_box(row).add_child(line)
	var text := StatusLinks.make_label(card.description, ROW_TEXT_SIZE, UiStyle.INK)
	text.custom_minimum_size.x = inner_width
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box(row).add_child(text)
	return row

func _omen_row(omen: OmenData) -> Button:
	var row := _row_button(Palette.WRAITHLIGHT)  # Omens are the nightmares' side: cold
	row.name = omen.id if omen.id != "" else omen.resource_path.get_file().get_basename()
	row.pressed.connect(func() -> void: omen_pressed.emit(omen))
	var name_label := Label.new()
	name_label.text = omen.display_name
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.title(name_label, 17)
	_box(row).add_child(name_label)
	var twist := StatusLinks.make_label(omen.description, ROW_TEXT_SIZE, UiStyle.INK)
	twist.custom_minimum_size.x = inner_width
	twist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box(row).add_child(twist)
	var reward := omen_reward_text(omen)
	if reward != "":
		var label := Label.new()
		label.text = reward
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = inner_width
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", TAG_SIZE + 1)
		label.add_theme_color_override("font_color", UiStyle.GOLD)
		_box(row).add_child(label)
	return row

# A row: the Moonlit card frame in the rarity colour (thin), its content in a margin box.
func _row_button(colour: Color) -> Button:
	var row := Button.new()
	row.focus_mode = Control.FOCUS_NONE
	row.custom_minimum_size = Vector2(0, 48)
	UiStyle.card_button(row, colour)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10 if side in ["left", "right"] else 8)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	row.add_child(margin)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	# A Button doesn't size to its children: follow the content's height.
	box.minimum_size_changed.connect(func() -> void: row.custom_minimum_size.y = maxf(48.0, margin.get_combined_minimum_size().y))
	return row

func _box(row: Button) -> VBoxContainer:
	return row.get_node("Margin/Box")

func _tag(text: String, colour: Color) -> Label:
	var tag := Label.new()
	tag.text = text
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiStyle.caps(tag, TAG_SIZE, colour)
	tag.text = text  # As written: caps() lowercases, and "+ II" keeps its capital numeral
	return tag
