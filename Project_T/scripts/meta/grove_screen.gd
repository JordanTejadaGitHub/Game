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
const CARD_WIDTH := 320

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
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.DREAD, 0.94)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(14)
	_card.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	_card_icon.custom_minimum_size = Vector2(48, 48)
	_card_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_card_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(_card_icon)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_card_name.add_theme_font_size_override("font_size", 20)
	_card_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	names.add_child(_card_name)
	_card_section.add_theme_font_size_override("font_size", 13)
	names.add_child(_card_section)
	head.add_child(names)
	var close := Button.new()
	close.text = "×"
	close.flat = true
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(40, 40)
	close.pressed.connect(func() -> void: _select(null))
	head.add_child(close)
	box.add_child(head)
	_card_text.bbcode_enabled = true
	_card_text.fit_content = true
	_card_text.scroll_active = false
	_card_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_text.custom_minimum_size = Vector2(CARD_WIDTH - 28, 0)
	box.add_child(_card_text)
	StatusLinks.hook(_card_text)
	_card_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_status.custom_minimum_size = Vector2(CARD_WIDTH - 28, 0)
	_card_status.add_theme_font_size_override("font_size", 14)
	box.add_child(_card_status)
	_plant.custom_minimum_size = Vector2(0, 48)
	_plant.focus_mode = Control.FOCUS_NONE
	_plant.pressed.connect(_plant_selected)
	box.add_child(_plant)
	_carry.custom_minimum_size = Vector2(0, 44)
	_carry.focus_mode = Control.FOCUS_NONE
	_carry.pressed.connect(_toggle_carry)
	box.add_child(_carry)
	add_child(_card)
	_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT, Control.PRESET_MODE_MINSIZE, 20)

func _build_footer() -> void:
	# Stacked in the bottom-right corner so the waystones at the roots stay clear.
	var footer := VBoxContainer.new()
	footer.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	footer.grow_vertical = Control.GROW_DIRECTION_BEGIN
	footer.add_theme_constant_override("separation", 10)
	_button(footer, "Start run", _start_run)
	_button(footer, "Carry", func() -> void: _open_loadout(false))
	_button(footer, "Codex", func() -> void: codex.open())
	_button(footer, "Back", func() -> void: get_tree().change_scene_to_file(TITLE_SCENE))
	add_child(footer)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 20)
	# Zoom buttons (touch: pinch works too, but buttons are always there).
	var zoom := HBoxContainer.new()
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
	var colour: Color = GroveTreeView.SECTION_COLOR.get(section, Palette.HEARTLIGHT)
	(_card.get_theme_stylebox("panel") as StyleBoxFlat).border_color = colour
	_card_icon.texture = tree_view.get_icon(selected)
	_card_name.text = selected.display_name
	var level := HeartwoodMemory.node_level(_memory, selected)
	var levels := selected.get_levels()
	var tags: Array[String] = [SECTION_NAMES.get(section, "")]
	if selected.legendary:
		tags.append("Legendary")
	if levels > 1:
		tags.append("Level %d of %d" % [level, levels])
	_card_section.text = " · ".join(tags)
	_card_section.add_theme_color_override("font_color", colour)
	_card_text.text = StatusLinks.bbcode(selected.get_description() + family_branches_text(selected))
	var problem := HeartwoodMemory.buy_problem(_memory, selected)
	var cost := selected.get_cost(HeartwoodMemory.unlock_level(_memory, selected.id))
	_plant.visible = problem != "Grown" and not selected.is_free()
	_plant.disabled = problem != ""
	_plant.text = ("Grow level %d · %d Seeds" % [level + 1, cost] if level > 0 else "Plant · %d Seeds" % cost)
	match problem:
		"Grown":
			_card_status.text = "In bloom" if not selected.start else "Grown from the start"
		"Grows by itself":  # A Memory Warden bloom (parked): grown by its boss's first dispel
			_card_status.text = "Grows by itself."
		"Needs another unlock first":
			_card_status.text = "Needs " + _needs_text(selected) + "."
		"Not enough Seeds":
			_card_status.text = "You need %d more Seeds." % (cost - int(_memory.seeds))
		_:
			_card_status.text = ""
	_card_status.visible = _card_status.text != ""
	_card_status.add_theme_color_override("font_color", Palette.NEWLEAF if problem == "Grown" else Palette.MOONPATH)
	var carried := HeartwoodMemory.get_loadout(_memory).has(selected.id)
	_carry.visible = selected.is_perk() and level > 0
	_carry.text = "Put back" if carried else "Carry into the dream"
	_carry.disabled = not carried and HeartwoodMemory.get_loadout(_memory).size() >= HeartwoodMemory.loadout_slots(_memory)
	if _carry.disabled:
		_carry.text = "Loadout full"
	# Shrink to the content (a card with fewer lines than the last one), still centred on the right.
	_fit_card.call_deferred()  # After the labels have re-measured

func _fit_card() -> void:
	_card.reset_size()
	_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT, Control.PRESET_MODE_MINSIZE, 20)

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

# First visit with Seeds already waiting (e.g. from the demo): "The forest remembered you."
func _welcome() -> void:
	if _memory.grove_welcome_shown:
		return
	if _memory.seeds > 0:
		_message.text = "The forest remembered you. Your %d Seeds were waiting." % int(_memory.seeds)
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
	if _has_perks():
		_open_loadout(true)
	else:
		_pick_blight()

func _pick_blight() -> void:
	var max_level := HeartwoodMemory.max_blight_level(_memory)
	if max_level > 0:
		_blight.open(max_level)
	else:
		MetaRun.blight_level = 0
		_go()

func _go() -> void:
	RunSaver.delete_save()
	RunSaver.resume_next = false
	get_tree().change_scene_to_file(GAME_SCENE)

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
