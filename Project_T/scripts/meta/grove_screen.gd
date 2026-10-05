extends Control

# The Memory Grove (meta_design.md "The Memory Grove: a tech tree", screens_ui.md "Meta screens"):
# spend Seeds between runs on the Heartwood itself (GroveTreeView). Tap a bud for its card and a
# Plant button; planting grows the branch and opens the flower. Dream-fruit are the Memories (tap to
# read), the waystones at the roots are the perk loadout (LoadoutPanel). Start run opens the loadout
# first when there are perks to carry, then the Blight Level picker after the first win. Codex
# (Reactions) and Back. The first visit with Seeds already banked (from the demo) says "The forest
# remembered you." Full game only. Built in code.

const TITLE_SCENE := "res://scenes/title.tscn"
const GAME_SCENE := "res://scenes/main.tscn"
const MEMORY_ART := "res://assets/meta/memories/memory_%02d.png"
const SECTION_NAMES := {"perks": "Perks", "families": "Families", "cards": "Cards"}
const CARD_WIDTH := 360  # The node card (UI Asset's approved page "Memory Grove: the node card")

var tree_view := GroveTreeView.new()
var loadout := LoadoutPanel.new(tree_view)
var codex: CodexPanel  # The Reaction Codex
var selected: UnlockData

var _memory: Dictionary
var _seeds_label := Label.new()
var _message := Label.new()
var _card := PanelContainer.new()
var _card_icon := TextureRect.new()
var _card_name := Label.new()
var _card_section := Label.new()
var _card_text := RichTextLabel.new()  # The description, with status / term / family links (StatusLinks)
var _card_status := Label.new()
var _plant := Button.new()
var _carry := Button.new()
var _card_levels := HBoxContainer.new()  # Small bars, then "+5% now, +10% next"
var _card_level_bars := HBoxContainer.new()
var _card_level_text := Label.new()
var _card_needs := VBoxContainer.new()  # "needs" in caps, then a chip per requirement
var _card_chips := HFlowContainer.new()
var _card_cost := HBoxContainer.new()  # The Seeds glyph, the price, "of N Seeds"
var _card_price := Label.new()
var _card_wallet := Label.new()
var _footer := VBoxContainer.new()  # The button column, bottom right (the card keeps clear of it)
var _zoom_row := HBoxContainer.new()  # The zoom buttons, bottom left
var _backdrop := ColorRect.new()
var _viewer := PanelContainer.new()
var _viewer_art := TextureRect.new()
var _viewer_title := Label.new()
var _viewer_text := Label.new()
var _viewer_index := 0
var _blight := BlightPicker.new()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Palette.VOID
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	tree_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(tree_view)
	tree_view.node_pressed.connect(_select)
	tree_view.fruit_pressed.connect(_open_fruit)
	tree_view.stones_pressed.connect(func() -> void: _open_loadout(false))
	tree_view.background_pressed.connect(func() -> void: _select(null))

	_build_header()
	_build_card()
	_build_footer()

	_backdrop.color = Color(Palette.VOID, 0.55)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.visible = false
	_backdrop.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and _viewer.visible:
			_close_viewer())
	add_child(_backdrop)
	_add_centred(loadout)
	loadout.closed.connect(_on_loadout_closed)
	_build_viewer()
	# The Reaction Codex (screens_ui.md "Reactions"), centred over the Grove.
	codex = CodexPanel.new()
	_add_centred(codex)
	add_child(_blight)
	_blight.picked.connect(func(level: int) -> void:
		MetaRun.blight_level = level
		_go())
	_refresh()
	_welcome()
	_check_crown()

func _build_header() -> void:
	var header := VBoxContainer.new()
	header.position = Vector2(20, 14)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := Label.new()
	title.text = "The Memory Grove"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Palette.HEARTLIGHT)
	title.add_theme_color_override("font_outline_color", Palette.VOID)
	title.add_theme_constant_override("outline_size", 6)
	header.add_child(title)
	_seeds_label.add_theme_font_size_override("font_size", 22)
	_seeds_label.add_theme_color_override("font_color", Palette.NEWLEAF)
	_seeds_label.add_theme_color_override("font_outline_color", Palette.VOID)
	_seeds_label.add_theme_constant_override("outline_size", 6)
	header.add_child(_seeds_label)
	if DevGrove.is_active():  # A dev profile, not the player's
		var dev := Label.new()
		dev.text = DevGrove.tag()
		dev.add_theme_font_size_override("font_size", 14)
		dev.add_theme_color_override("font_color", Palette.GOLD)
		header.add_child(dev)
	add_child(header)
	_message.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_message.add_theme_font_size_override("font_size", 18)
	_message.add_theme_color_override("font_color", Palette.MOONLIGHT)
	_message.add_theme_color_override("font_outline_color", Palette.VOID)
	_message.add_theme_constant_override("outline_size", 6)
	add_child(_message)
	_message.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 18)

func _build_card() -> void:
	_card.visible = false
	_card.custom_minimum_size = Vector2(CARD_WIDTH, 0)
	_card.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_card.grow_vertical = Control.GROW_DIRECTION_BOTH
	# The node card (UI Asset's approved page "Memory Grove: the node card"): the theme's moonlit panel, a
	# moon-disc header, one line of what it does, level bars, "needs" chips, the cost row, Plant as the one
	# primary and Close as quiet text. No " · " separators anywhere on it.
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_card.add_child(box)
	var inner := CARD_WIDTH - 32  # Text width inside the panel's margins
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	_card_icon.custom_minimum_size = Vector2(40, 40)
	_card_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_card_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_card_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_card_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var disc := UiStyle.on_moon_disc(_card_icon)
	disc.custom_minimum_size = Vector2(64, 64)
	head.add_child(disc)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	UiStyle.title(_card_name, 26)
	_card_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	names.add_child(_card_name)
	UiStyle.caps(_card_section)
	names.add_child(_card_section)
	head.add_child(names)
	box.add_child(head)
	_card_text.bbcode_enabled = true
	_card_text.fit_content = true
	_card_text.scroll_active = false
	_card_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_text.custom_minimum_size = Vector2(inner, 0)
	_card_text.add_theme_font_size_override("normal_font_size", 15)
	_card_text.add_theme_color_override("default_color", Palette.MIST)
	box.add_child(_card_text)
	StatusLinks.hook(_card_text)
	_card_levels.add_theme_constant_override("separation", 10)
	_card_level_bars.add_theme_constant_override("separation", 4)
	_card_level_bars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_card_levels.add_child(_card_level_bars)
	_card_level_text.add_theme_font_size_override("font_size", 14)
	_card_level_text.add_theme_color_override("font_color", Palette.MIST)
	_card_levels.add_child(_card_level_text)
	box.add_child(_card_levels)
	var needs_title := Label.new()
	needs_title.text = "needs"
	UiStyle.caps(needs_title)
	_card_needs.add_child(needs_title)
	_card_chips.add_theme_constant_override("h_separation", 6)
	_card_chips.add_theme_constant_override("v_separation", 6)
	_card_needs.add_child(_card_chips)
	box.add_child(_card_needs)
	_card_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_status.custom_minimum_size = Vector2(inner, 0)
	_card_status.add_theme_font_size_override("font_size", 14)
	box.add_child(_card_status)
	_card_cost.add_theme_constant_override("separation", 8)
	var glyph := TextureRect.new()
	glyph.texture = IconInfo.icon(&"seeds")
	glyph.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyph.custom_minimum_size = Vector2(32, 32)  # The 16 px glyph at 2×
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_card_cost.add_child(glyph)
	UiStyle.number(_card_price, UiStyle.NUMBER_SIZE, Palette.SPRIG)
	_card_cost.add_child(_card_price)
	_card_wallet.add_theme_font_size_override("font_size", 14)
	_card_wallet.add_theme_color_override("font_color", Palette.MIST)
	_card_wallet.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_card_cost.add_child(_card_wallet)
	box.add_child(_card_cost)
	_plant.custom_minimum_size = Vector2(0, 48)
	_plant.focus_mode = Control.FOCUS_NONE
	UiStyle.primary(_plant)
	_plant.pressed.connect(_plant_selected)
	box.add_child(_plant)
	_carry.custom_minimum_size = Vector2(0, 48)
	_carry.focus_mode = Control.FOCUS_NONE
	_carry.pressed.connect(_toggle_carry)
	box.add_child(_carry)
	var close := Button.new()
	close.text = "Close"
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 48)
	UiStyle.quiet(close)
	close.pressed.connect(func() -> void: _select(null))
	box.add_child(close)
	add_child(_card)
	_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT, Control.PRESET_MODE_MINSIZE, 20)

func _build_footer() -> void:
	# Stacked in the bottom-right corner so the waystones at the roots stay clear.
	var footer := _footer
	footer.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	footer.grow_vertical = Control.GROW_DIRECTION_BEGIN
	footer.add_theme_constant_override("separation", 10)
	_button(footer, "Start run", _start_run)
	_button(footer, "Carry", func() -> void: _open_loadout(false))
	_button(footer, "Codex", func() -> void: codex.open())
	_button(footer, "Keepsakes", open_keepsakes)
	_button(footer, "Back", func() -> void: get_tree().change_scene_to_file(TITLE_SCENE))
	add_child(footer)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 20)
	# Zoom buttons (touch: pinch works too, but buttons are always there).
	var zoom := _zoom_row
	zoom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	zoom.add_theme_constant_override("separation", 8)
	for spec in [["−", 1.0 / 1.25], ["+", 1.25]]:
		var button := Button.new()
		button.text = spec[0]
		button.custom_minimum_size = Vector2(48, 48)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(tree_view.zoom_by.bind(spec[1]))
		zoom.add_child(button)
	var whole := Button.new()
	whole.text = "Show all"  # Fits the whole Heartwood in view (not "Whole Tree": that's a Kinship name)
	whole.custom_minimum_size = Vector2(0, 48)
	whole.focus_mode = Control.FOCUS_NONE
	whole.pressed.connect(tree_view.fit)
	zoom.add_child(whole)
	add_child(zoom)
	zoom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 20)

func _build_viewer() -> void:
	_viewer.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.DREAD, 0.97)
	style.border_color = Palette.DEWLIGHT
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(16)
	_viewer.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_viewer.add_child(box)
	_viewer_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_viewer_title.add_theme_font_size_override("font_size", 20)
	_viewer_title.add_theme_color_override("font_color", Palette.MOONLIGHT)
	box.add_child(_viewer_title)
	_viewer_art.custom_minimum_size = Vector2(640, 360)
	_viewer_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_viewer_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(_viewer_art)
	_viewer_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_viewer_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_viewer_text.custom_minimum_size = Vector2(640, 0)
	_viewer_text.add_theme_font_size_override("font_size", 18)
	box.add_child(_viewer_text)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	_button(row, "‹ Before", func() -> void: _show_memory(_viewer_index - 1))
	_button(row, "Close", _close_viewer)
	_button(row, "After ›", func() -> void: _show_memory(_viewer_index + 1))
	box.add_child(row)
	_add_centred(_viewer)

func _add_centred(panel: Control) -> void:
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(panel)
	add_child(centre)

func _refresh() -> void:
	_memory = HeartwoodMemory.load_data()
	_seeds_label.text = "Seeds %d" % int(_memory.seeds)
	tree_view.refresh(_memory)
	_update_card()
	_backdrop.visible = loadout.visible or _viewer.visible

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _viewer.visible:
			_close_viewer()
		elif loadout.visible:
			loadout.close(false)
		elif selected != null:
			_select(null)
		else:
			return
		get_viewport().set_input_as_handled()

# --- The node card ---

func _select(unlock: UnlockData) -> void:
	selected = unlock
	tree_view.selected_id = unlock.id if unlock else ""
	_update_card()

func _update_card() -> void:
	_card.visible = selected != null
	if selected == null:
		return
	var section := selected.get_section()
	_card_icon.texture = tree_view.get_icon(selected)
	_card_name.text = selected.display_name
	var level := HeartwoodMemory.node_level(_memory, selected)
	var levels := selected.get_levels()
	# "perk, level 1 of 3", "legendary card", "family" (small caps; a comma, never " · ").
	var kind: String = {"perks": "perk", "families": "family", "cards": "card"}.get(section, "")
	if selected.legendary:
		kind = "legendary " + kind
	_card_section.text = "%s, level %d of %d" % [kind, level, levels] if levels > 1 else kind
	_card_text.text = StatusLinks.bbcode(selected.get_description() + family_branches_text(selected))
	# Levels as small bars: Glow for the ones grown, dim for the rest, then the effect now and next.
	for bar in _card_level_bars.get_children():
		bar.queue_free()
	for i in levels:
		var bar := ColorRect.new()
		bar.color = Palette.GLOW if i < level else Color(Palette.MIST, 0.25)
		bar.custom_minimum_size = Vector2(22, 6)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_card_level_bars.add_child(bar)
	_card_level_text.text = _level_effect_text(selected, level)
	_card_levels.visible = levels > 1
	# "needs" chips: met ones in a Sprig outline with a ✓, the rest in Mist.
	for chip in _card_chips.get_children():
		chip.queue_free()
	for requirement in _requirement_chips(selected):
		_card_chips.add_child(_chip(requirement[0], requirement[1]))
	_card_needs.visible = _card_chips.get_child_count() > 0 and not HeartwoodMemory.is_grown(_memory, selected)
	var problem := HeartwoodMemory.buy_problem(_memory, selected)
	var cost := selected.get_cost(HeartwoodMemory.unlock_level(_memory, selected.id))
	var buyable := problem != "Grown" and not selected.is_free()
	_card_cost.visible = buyable
	_card_price.text = str(cost)
	_card_wallet.text = "of %d Seeds" % int(_memory.seeds)
	_plant.visible = buyable
	_plant.disabled = problem != ""
	_plant.text = "Grow to level %d" % (level + 1) if level > 0 else "Plant"
	match problem:
		"Grown":
			_card_status.text = "In bloom" if not selected.start else "Grown from the start"
		"Grows by itself":  # A parked Memory Warden bloom: grown by its boss's first dispel
			_card_status.text = "Grows by itself."
		"Not enough Seeds":
			_card_status.text = "You need %d more Seeds." % (cost - int(_memory.seeds))
		_:
			_card_status.text = ""  # Unmet needs show as chips
	_card_status.visible = _card_status.text != ""
	_card_status.add_theme_color_override("font_color", Palette.SPRIG if problem == "Grown" else Palette.MIST)
	var carried := HeartwoodMemory.get_loadout(_memory).has(selected.id)
	_carry.visible = selected.is_perk() and level > 0
	_carry.text = "Put back" if carried else "Carry into the dream"
	_carry.disabled = not carried and HeartwoodMemory.get_loadout(_memory).size() >= HeartwoodMemory.loadout_slots(_memory)
	if _carry.disabled:
		_carry.text = "Loadout full"
	# Shrink to the content (a card with fewer lines than the last one), still centred on the right.
	_fit_card.call_deferred()  # After the labels have re-measured

# "+5% now, +10% next" for a node with levels, from its per-level perk numbers ("" at 0 / when nothing scales).
static func _level_effect_text(unlock: UnlockData, level: int) -> String:
	var per_level: Array = []  # [format, value per level]
	if unlock.starting_dew != 0:
		per_level = ["+%d Dew", unlock.starting_dew]
	elif unlock.dew_gain != 0.0:
		per_level = ["+%d%%", unlock.dew_gain * 100.0]
	elif unlock.rest_bonus != 0.0:
		per_level = ["+%d%%", unlock.rest_bonus * 100.0]
	elif unlock.max_leaves != 0:
		per_level = ["+%d leaves", unlock.max_leaves]
	elif unlock.dream_rerolls != 0:
		per_level = ["%d rerolls", unlock.dream_rerolls]
	if per_level.is_empty():
		return ""
	var at := func(n: int) -> String: return per_level[0] % roundi(float(per_level[1]) * n)
	var parts: Array[String] = []
	if level > 0:
		parts.append("%s now" % at.call(level))
	if level < unlock.get_levels():
		parts.append("%s next" % at.call(level + 1))
	return ", ".join(parts)

# Each requirement as [name, met]: every requires_all, then the requires_any group as one chip.
func _requirement_chips(unlock: UnlockData) -> Array:
	var chips: Array = []
	for requirement in unlock.requires_all:
		chips.append([_requirement_name(requirement), HeartwoodMemory._meets(_memory, requirement)])
	if not unlock.requires_any.is_empty():
		var owned := unlock.requires_any.filter(func(id: String) -> bool: return HeartwoodMemory._meets(_memory, id)).size()
		var names: Array[String] = []
		for id in unlock.requires_any:
			names.append(_requirement_name(id))
		var text := " or ".join(names) if unlock.requires_any_count <= 1 \
			else ("%d of %s" % [unlock.requires_any_count, ", ".join(names)] if names.size() <= 5
				else "any %d other %s nodes" % [unlock.requires_any_count, SECTION_NAMES.get(unlock.get_section(), "").to_lower()])
		chips.append([text, owned >= unlock.requires_any_count])
	if unlock.crown:
		chips.append(["every other node grown", HeartwoodMemory.tree_complete(_memory)])
	return chips

func _chip(text: String, met: bool) -> PanelContainer:
	var chip := PanelContainer.new()
	var box := StyleBoxFlat.new()  # A small outline chip (no panel fill), Sprig when met
	box.bg_color = Color(Palette.VOID, 0.0)
	box.border_color = Palette.SPRIG if met else Color(Palette.MIST, 0.5)
	box.set_border_width_all(1)
	box.set_corner_radius_all(10)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 2
	box.content_margin_bottom = 2
	chip.add_theme_stylebox_override("panel", box)
	var label := Label.new()
	label.text = ("✓ " + text) if met else text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Palette.SPRIG if met else Palette.MIST)
	chip.add_child(label)
	return chip

# Placement (UI Asset's rule): the card's right edge sits CARD_GAP left of the button column, measured; its top stays
# under the moon; its height stops CARD_GAP above the zoom row (a long description scrolls instead). When the
# selected node would sit under the card, it flips to the left of the tree. Sizes are the screen's own, so the
# 1.5× UI scale at 1920 follows by itself.
const CARD_GAP := 16.0
const CARD_TOP_SHARE := 0.27  # The card's top, as a share of the screen height (under the moon)

func _fit_card() -> void:
	_card_text.fit_content = true
	_card_text.scroll_active = false
	_card_text.custom_minimum_size.y = 0
	_card.reset_size()
	var top := size.y * CARD_TOP_SHARE
	var bottom := _zoom_row.position.y - CARD_GAP
	if _card.size.y > bottom - top:  # Long text: the description scrolls, the card keeps its place
		var over := _card.size.y - (bottom - top)
		_card_text.fit_content = false
		_card_text.scroll_active = true
		_card_text.custom_minimum_size.y = maxf(_card_text.size.y - over, 48.0)
		_card.reset_size()
	var rect := Rect2(Vector2(_footer.position.x - CARD_GAP - _card.size.x, top), _card.size)
	if selected != null and rect.grow(CARD_GAP).has_point(_node_screen_position(selected.id)):
		rect.position.x = _zoom_row.position.x + CARD_GAP  # The other side, clear of the left HUD's margin
	_card.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_card.position = rect.position

# Where node `id` is drawn now (screen space of this screen), or off-screen when it isn't on the tree.
func _node_screen_position(id: String) -> Vector2:
	for node in GroveTreeView.load_layout().get("nodes", []):
		if node.id == id:
			return tree_view.to_screen(GroveTreeView.vec(node.pos))
	return Vector2(-1000, -1000)

# "Pebbling or Rootling", "Second Thoughts II", "2 of …"
func _needs_text(unlock: UnlockData) -> String:
	var parts: Array[String] = []
	for requirement in unlock.requires_all:
		if not HeartwoodMemory._meets(_memory, requirement):
			parts.append(_requirement_name(requirement))
	if not unlock.requires_any.is_empty():
		var names: Array[String] = []
		for id in unlock.requires_any:
			names.append(_requirement_name(id))
		if unlock.requires_any_count <= 1:
			parts.append(" or ".join(names))
		elif names.size() <= 5:
			parts.append("%d of %s" % [unlock.requires_any_count, ", ".join(names)])
		else:
			parts.append("any %d other %s nodes" % [unlock.requires_any_count, SECTION_NAMES.get(unlock.get_section(), "")])
	return " and ".join(parts)

func _requirement_name(requirement: String) -> String:
	var parts := requirement.split(":")
	var unlock := HeartwoodMemory.get_unlock(parts[0])
	var name := unlock.display_name.trim_suffix(" family") if unlock else parts[0]
	if parts.size() > 1:
		name += " " + ["", "I", "II", "III"][clampi(int(parts[1]), 0, 3)]
	return name

func _plant_selected() -> void:
	if selected == null:
		return
	var before := HeartwoodMemory.memories_unlocked(_memory)
	var first_level := HeartwoodMemory.unlock_level(_memory, selected.id) == 0
	if not HeartwoodMemory.buy(selected):
		return
	if first_level:
		tree_view.play_plant(selected.id)
	# A new perk goes straight into the loadout when there's room.
	if selected.is_perk() and first_level:
		var carried := HeartwoodMemory.get_loadout(HeartwoodMemory.load_data())
		if carried.size() < HeartwoodMemory.loadout_slots(_memory):
			carried.append(selected.id)
			HeartwoodMemory.save_loadout(carried)
	_refresh()
	if HeartwoodMemory.memories_unlocked(_memory) > before:
		_message.text = "A Memory returns: a dream-fruit ripens on the Heartwood."
	else:
		_message.text = ""
	_check_crown()

# The Heartwood's Crown (meta_design.md "Milestones"): planting it raises the secret sixth waystone at the roots,
# once (this visit or the next; the profile remembers it has risen). The developer toggle shows the stone without it.
func _check_crown() -> void:
	var data := HeartwoodMemory.load_data()
	var crown := HeartwoodMemory.get_unlock(HeartwoodMemory.CROWN)
	var changed := false
	if crown != null and HeartwoodMemory.node_level(data, crown) > 0 and not data.get("sixth_stone_risen", false):
		data.sixth_stone_risen = true
		changed = true
		tree_view.play_sixth_rise()
		_message.text = "The Heartwood wears its crown. A sixth waystone rises from its roots."
	if changed:
		HeartwoodMemory.save_data(data)
		_refresh()

func _toggle_carry() -> void:
	if selected == null:
		return
	var carried := HeartwoodMemory.get_loadout(_memory)
	if carried.has(selected.id):
		carried.erase(selected.id)
	elif carried.size() < HeartwoodMemory.loadout_slots(_memory):
		carried.append(selected.id)
	HeartwoodMemory.save_loadout(carried)
	_refresh()

# --- Memories (dream-fruit) ---

func _open_fruit(index: int) -> void:
	if index >= int(_memory.get("memories_seen", 0)):
		tree_view.play_fruit_open(index)
		_memory = HeartwoodMemory.load_data()
		_memory.memories_seen = index + 1
		HeartwoodMemory.save_data(_memory)
		_message.text = ""
		get_tree().create_timer(GroveTreeView.GROW_STEP * 4).timeout.connect(_show_memory.bind(index))
	else:
		_show_memory(index)

func _show_memory(index: int) -> void:
	var revealed := HeartwoodMemory.memories_unlocked(_memory)
	if index < 0 or index >= revealed:
		return
	_viewer_index = index
	_viewer_title.text = "Memory %d" % (index + 1)
	var path := MEMORY_ART % (index + 1)
	_viewer_art.texture = load(path) if ResourceLoader.exists(path) else null
	_viewer_text.text = HeartwoodMemory.MEMORIES[index]
	_viewer.visible = true
	_refresh()

func _close_viewer() -> void:
	_viewer.visible = false
	_refresh()

# --- Loadout and starting a run ---

func _has_perks() -> bool:
	for unlock in HeartwoodMemory.load_grove():
		if unlock.is_perk() and HeartwoodMemory.node_level(_memory, unlock) > 0:
			return true
	return false

func _open_loadout(start_run: bool) -> void:
	_select(null)
	loadout.open(_memory, start_run)
	_refresh()

func _on_loadout_closed(start: bool) -> void:
	_refresh()
	if start:
		_pick_blight()

# First visit with Seeds already waiting (e.g. from the demo): "Back again. Good." (text_pass.md)
func _welcome() -> void:
	if _memory.grove_welcome_shown:
		return
	if _memory.seeds > 0:
		_message.text = "Back again. Good. Your %d Seeds were waiting." % int(_memory.seeds)
	_memory.grove_welcome_shown = true
	HeartwoodMemory.save_data(_memory)

func _start_run() -> void:
	if RunSaver.has_save():  # One run in progress at a time
		var confirm := ConfirmationDialog.new()
		confirm.dialog_text = "Start a new run? The run in progress will be lost."
		confirm.confirmed.connect(func() -> void:
			RunSaver.delete_save()
			_start_run())
		add_child(confirm)
		confirm.popup_centered()
		return
	MetaRun.leaf_dew_trade = 0
	if MetaRun.leaf_or_dew_available():
		open_leaf_dew()  # Its Continue goes on to the loadout / Blight steps
	else:
		_after_leaf_dew()

func _after_leaf_dew() -> void:
	if _has_perks():
		_open_loadout(true)
	else:
		_pick_blight()

# Leaf or Dew (Grove option node): a −3…+3 stepper before the run, applied once at run start (MetaRun).
var leaf_dew_step := PanelContainer.new()
var _leaf_dew_label := Label.new()

func open_leaf_dew() -> void:
	if leaf_dew_step.get_parent() == null:
		leaf_dew_step.custom_minimum_size = Vector2(440, 0)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 12)
		leaf_dew_step.add_child(box)
		var title := Label.new()
		title.text = "Leaf or Dew"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 24)
		title.add_theme_color_override("font_color", Palette.GLOW)
		box.add_child(title)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 12)
		box.add_child(row)
		_leaf_dew_button(row, "More Dew", "MoreDew", 1)
		_leaf_dew_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_leaf_dew_label.custom_minimum_size = Vector2(190, 0)
		_leaf_dew_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(_leaf_dew_label)
		_leaf_dew_button(row, "More leaves", "MoreLeaves", -1)
		row.move_child(_leaf_dew_label, 1)
		var footer := HBoxContainer.new()
		footer.alignment = BoxContainer.ALIGNMENT_END
		footer.add_theme_constant_override("separation", 12)
		box.add_child(footer)
		var back := Button.new()
		back.text = "Back"
		back.focus_mode = Control.FOCUS_NONE
		back.custom_minimum_size = Vector2(130, 48)
		back.pressed.connect(func() -> void:
			MetaRun.leaf_dew_trade = 0
			leaf_dew_step.visible = false)
		footer.add_child(back)
		var go := Button.new()
		go.name = "Continue"
		go.text = "Continue"
		go.focus_mode = Control.FOCUS_NONE
		go.custom_minimum_size = Vector2(130, 48)
		go.pressed.connect(func() -> void:
			leaf_dew_step.visible = false
			_after_leaf_dew())
		footer.add_child(go)
		add_child(leaf_dew_step)
	_show_leaf_dew()
	leaf_dew_step.visible = true
	leaf_dew_step.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)

func _leaf_dew_button(row: HBoxContainer, text: String, button_name: String, step: int) -> void:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(110, 48)
	button.pressed.connect(func() -> void:
		MetaRun.leaf_dew_trade = clampi(MetaRun.leaf_dew_trade + step, -MetaRun.LEAF_DEW_MAX, MetaRun.LEAF_DEW_MAX)
		_show_leaf_dew())
	row.add_child(button)

func _show_leaf_dew() -> void:
	var trade := MetaRun.leaf_dew_trade
	var rate := MetaRun.LEAF_DEW_RATE
	if trade > 0:
		_leaf_dew_label.text = "%d fewer leaves (max too)\n+%d Dew" % [trade, trade * rate]
	elif trade < 0:
		_leaf_dew_label.text = "%d more leaves (max too)\n−%d Dew" % [-trade, -trade * rate]
	else:
		_leaf_dew_label.text = "No trade"

func _pick_blight() -> void:
	var max_level := HeartwoodMemory.max_blight_level(_memory)
	if max_level > 0:
		_blight.open(max_level)
	else:
		MetaRun.blight_level = 0
		_go()

func _go() -> void:
	# Remembered Seed (Grove node): the picker asks which map first; without the node it starts at once.
	SeedPicker.ask(self, func() -> void:
		RunSaver.delete_save()
		RunSaver.resume_next = false
		get_tree().change_scene_to_file(GAME_SCENE))

# The Keepsakes shelf (meta_design.md Section 1, user 2026-10-05): the four cosmetics, each earned by its milestone.
# Earned ones get a Show / Hide switch (the same setting as Settings → Display → Keepsakes); unearned ones are
# greyed with their milestone. Art (Meta Game Asset f6fb233c): four niches standing on a mossy shelf, drawn at 2×.
const SHELF_TEXTURE := preload("res://assets/meta/ui/keepsake_shelf.png")  # 208×40
const NICHE_TEXTURE := preload("res://assets/meta/ui/keepsake_slots.png")  # 40×40 frames: 0–3 earned, 4–7 not yet
const NICHE := 40
const SHELF_SCALE := 2
const NICHE_GAP := 12  # Art px between niches, so four sit across the shelf's 208
var keepsakes_shelf := PanelContainer.new()
var _niche_row := HBoxContainer.new()
var _shelf_rows := HBoxContainer.new()  # Under the shelf: one column per keepsake (named by its id): name, line, switch

func open_keepsakes() -> void:
	if keepsakes_shelf.get_parent() == null:
		keepsakes_shelf.custom_minimum_size = Vector2(SHELF_TEXTURE.get_width() * SHELF_SCALE + 40, 0)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 10)
		keepsakes_shelf.add_child(box)
		var title := Label.new()
		title.text = "Keepsakes"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 24)
		title.add_theme_color_override("font_color", Palette.GLOW)
		box.add_child(title)
		var stand := VBoxContainer.new()  # The niches stand on the shelf's top moss
		stand.add_theme_constant_override("separation", -(SHELF_TEXTURE.get_height() - 16) * SHELF_SCALE)
		stand.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_niche_row.alignment = BoxContainer.ALIGNMENT_CENTER
		_niche_row.add_theme_constant_override("separation", NICHE_GAP * SHELF_SCALE)
		stand.add_child(_niche_row)
		var shelf := TextureRect.new()
		shelf.texture = SHELF_TEXTURE
		shelf.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		shelf.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shelf.custom_minimum_size = SHELF_TEXTURE.get_size() * SHELF_SCALE
		shelf.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stand.add_child(shelf)
		stand.move_child(shelf, 0)  # Drawn first, so the niches sit in front of it
		box.add_child(stand)
		_shelf_rows.alignment = BoxContainer.ALIGNMENT_CENTER
		_shelf_rows.add_theme_constant_override("separation", 8)
		box.add_child(_shelf_rows)
		var close := Button.new()
		close.text = "Close"
		close.focus_mode = Control.FOCUS_NONE
		close.custom_minimum_size = Vector2(130, 48)
		close.size_flags_horizontal = Control.SIZE_SHRINK_END
		close.pressed.connect(func() -> void: keepsakes_shelf.visible = false)
		box.add_child(close)
		add_child(keepsakes_shelf)
	_rebuild_shelf()
	keepsakes_shelf.visible = true
	keepsakes_shelf.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)

func _rebuild_shelf() -> void:
	for child in _shelf_rows.get_children() + _niche_row.get_children():
		child.get_parent().remove_child(child)  # Gone now, so a rebuild's new rows can take the same names
		child.queue_free()
	for i in MetaRun.KEEPSAKES.size():
		var id: String = MetaRun.KEEPSAKES[i]
		var owned := MetaRun.keepsake_owned(id)
		var niche := TextureRect.new()
		var frame := AtlasTexture.new()
		frame.atlas = NICHE_TEXTURE
		frame.region = Rect2((i + (0 if owned else 4)) * NICHE, 0, NICHE, NICHE)
		niche.texture = frame
		niche.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		niche.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		niche.custom_minimum_size = Vector2.ONE * NICHE * SHELF_SCALE
		niche.tooltip_text = MetaRun.KEEPSAKE_TEXT[id][0]
		_niche_row.add_child(niche)
		var row := VBoxContainer.new()
		row.name = id
		row.custom_minimum_size = Vector2((NICHE + NICHE_GAP) * SHELF_SCALE - 8, 0)
		row.add_theme_constant_override("separation", 4)
		var words := Label.new()
		var milestone: Array = MetaRun.MILESTONE_SEEDS.get(MetaRun.KEEPSAKE_MILESTONES[id], [0, ""])
		words.text = "%s\n%s" % [MetaRun.KEEPSAKE_TEXT[id][0], MetaRun.KEEPSAKE_TEXT[id][1] if owned else "Earned by: %s." % milestone[1]]
		words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.add_theme_font_size_override("font_size", 13)
		words.add_theme_color_override("font_color", Palette.HEARTLIGHT if owned else Palette.MOONPATH)
		if not owned:
			words.modulate = Color(1, 1, 1, 0.6)  # multiplier: greyed until earned
		row.add_child(words)
		if owned:
			var toggle := Button.new()
			toggle.name = "Toggle"
			toggle.focus_mode = Control.FOCUS_NONE
			toggle.custom_minimum_size = Vector2(88, 44)
			toggle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			toggle.text = "Hide" if MetaRun.keepsake_on(id) else "Show"
			toggle.pressed.connect(func() -> void:
				MetaRun.set_keepsake_shown(id, not MetaRun.keepsake_on(id))
				_rebuild_shelf())
			row.add_child(toggle)
		_shelf_rows.add_child(row)

func _button(parent: Control, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(130, 48)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	parent.add_child(button)

# A family node's branches for its card (meta_design.md "Branch expansion in the Grove"), read from the Warden data
# so it follows each expansion phase: every regular branch with its one-line job and final forms, then how many a
# run's dreams offer. The hidden branch (its own node) and parked forms aren't listed. "" for other nodes.
static func family_branches_text(unlock: UnlockData) -> String:
	if unlock == null or unlock.root != UnlockData.Root.WARDENS or unlock.memory_warden != "":
		return ""
	var families: Array[String] = unlock.families.duplicate()
	if families.is_empty() and unlock.start:  # Starting families are in every run, so their nodes list none
		families.append(unlock.id)
	var hidden := HeartwoodMemory.get_unlock(unlock.id + "_hidden")
	var lines: Array[String] = []
	for family in families:
		var path := "res://resource/tower/%s.tres" % family
		var base := load(path) as TowerData if ResourceLoader.exists(path) else null
		if base == null:
			continue
		for branch in base.evolves_to:
			if not (branch is TowerData) or branch.tier != 2 or branch.parked:
				continue
			if hidden != null and hidden.dream_cards.has("dream_" + branch.get_id()):
				continue  # The hidden branch: its own node
			var finals: Array[String] = []
			for final in branch.evolves_to:
				if final is TowerData and final.tier == 3 and not final.parked:
					finals.append(final.display_name)
			var job: String = branch.description.strip_edges()
			lines.append("• %s%s%s" % [branch.display_name, ": " + job if job != "" else "",
				" → " + ", ".join(finals) if not finals.is_empty() else ""])
	if lines.is_empty():
		return ""
	var dreams := "\nIn your dreams: %d a run." % DreamState.BRANCH_OFFER_SIZE if lines.size() > DreamState.BRANCH_OFFER_SIZE else ""
	return "\n\nBranches:\n" + "\n".join(lines) + dreams
