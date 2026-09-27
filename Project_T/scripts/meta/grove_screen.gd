extends Control

# The Memory Grove (meta_design.md, screens_ui.md "Meta screens"): spend Seeds between runs. Four
# roots (Wardens, Dreams, Perks, Forests); each unlock is a plant: a seed (locked, shows its cost),
# glowing (affordable) or grown (owned). A Memories shelf (1–10) opens the viewer. Start run (with
# the Blight Level picker after the first win), Codex (Reactions) and Back. The first visit with Seeds already banked
# (from the demo) says "The forest remembered you." Full game only. Built in code.

const TITLE_SCENE := "res://scenes/title.tscn"
const GAME_SCENE := "res://scenes/main.tscn"
const ROOT_NAMES := ["Wardens", "Dreams", "Perks", "Forests"]
const ROOT_EMPTY := ["", "New Dream cards grow here.", "", "New forests grow here, after the first playable."]
const GROWN := Color(0.55, 0.9, 0.55)
const GLOWING := Color(1.0, 0.85, 0.45)
const SEED := Color(0.55, 0.55, 0.6)

var _memory: Dictionary
var _seeds_label := Label.new()
var _roots := HBoxContainer.new()
var _shelf := HBoxContainer.new()
var _message := Label.new()
var _viewer := AcceptDialog.new()
var _blight := BlightPicker.new()
var codex: CodexPanel  # The Reaction Codex

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.05, 0.08, 0.07)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = "The Memory Grove"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.85, 1.0, 0.8))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_seeds_label.add_theme_font_size_override("font_size", 22)
	_seeds_label.add_theme_color_override("font_color", Color(0.75, 0.95, 0.6))
	header.add_child(_seeds_label)
	box.add_child(header)
	_message.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
	box.add_child(_message)

	_roots.add_theme_constant_override("separation", 16)
	_roots.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_roots)
	box.add_child(scroll)

	var memories_title := Label.new()
	memories_title.text = "Memories"
	box.add_child(memories_title)
	_shelf.add_theme_constant_override("separation", 6)
	box.add_child(_shelf)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 12)
	box.add_child(footer)
	_button(footer, "Back", func() -> void: get_tree().change_scene_to_file(TITLE_SCENE))
	# The Reaction Codex (screens_ui.md "Reactions"), centred over the Grove.
	var codex_center := CenterContainer.new()
	codex_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	codex_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	codex = CodexPanel.new()
	codex_center.add_child(codex)
	_button(footer, "Codex", codex.open)
	_button(footer, "Start run", _start_run)

	add_child(codex_center)
	_viewer.title = "Memory"
	add_child(_viewer)
	add_child(_blight)
	_blight.picked.connect(func(level: int) -> void:
		MetaRun.blight_level = level
		_go())
	_refresh()
	_welcome()

func _refresh() -> void:
	_memory = HeartwoodMemory.load_data()
	_seeds_label.text = "Seeds %d" % int(_memory.seeds)
	for child in _roots.get_children():
		child.queue_free()
	var by_root := {}
	for unlock in HeartwoodMemory.load_grove():
		if not by_root.has(unlock.root):
			by_root[unlock.root] = []
		by_root[unlock.root].append(unlock)
	for root in ROOT_NAMES.size():
		var column := VBoxContainer.new()
		column.custom_minimum_size = Vector2(250, 0)
		column.add_theme_constant_override("separation", 8)
		var name_label := Label.new()
		name_label.text = ROOT_NAMES[root]
		name_label.add_theme_font_size_override("font_size", 20)
		column.add_child(name_label)
		for unlock in by_root.get(root, []):
			column.add_child(_plant(unlock))
		if not by_root.has(root):
			var empty := Label.new()
			empty.text = ROOT_EMPTY[root]
			empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			empty.add_theme_color_override("font_color", SEED)
			column.add_child(empty)
		_roots.add_child(column)
	for child in _shelf.get_children():
		child.queue_free()
	var revealed := HeartwoodMemory.memories_unlocked(_memory)
	for i in HeartwoodMemory.MEMORIES.size():
		var leaf := Button.new()
		leaf.text = str(i + 1)
		leaf.custom_minimum_size = Vector2(44, 44)
		leaf.focus_mode = Control.FOCUS_NONE
		leaf.disabled = i >= revealed
		leaf.tooltip_text = "Memory %d" % (i + 1) if i < revealed else "Not remembered yet"
		leaf.pressed.connect(_show_memory.bind(i))
		_shelf.add_child(leaf)

# One unlock as a plant: grown / glowing / seed, with the next level's cost and why it's locked.
func _plant(unlock: UnlockData) -> Button:
	var level := HeartwoodMemory.unlock_level(_memory, unlock.id)
	var levels := unlock.get_levels()
	var problem := HeartwoodMemory.buy_problem(_memory, unlock)
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(240, 56)
	var level_text := " %d/%d" % [level, levels] if levels > 1 else ""
	var state := "grown" if problem == "Grown" else ("%d Seeds" % unlock.get_cost(level))
	button.text = "%s%s · %s" % [unlock.display_name, level_text, state]
	button.tooltip_text = unlock.description + ("" if problem == "" or problem == "Grown" else "\n" + problem)
	var colour := GROWN if problem == "Grown" else (GLOWING if problem == "" else SEED)
	button.add_theme_color_override("font_color", colour)
	button.add_theme_color_override("font_disabled_color", colour)
	button.disabled = problem != ""
	button.pressed.connect(func() -> void:
		if HeartwoodMemory.buy(unlock):
			var before := HeartwoodMemory.memories_unlocked(_memory)
			_refresh()
			if HeartwoodMemory.memories_unlocked(_memory) > before:
				_message.text = "A memory returns…"
				_show_memory(HeartwoodMemory.memories_unlocked(_memory) - 1))
	return button

func _show_memory(index: int) -> void:
	_viewer.title = "Memory %d" % (index + 1)
	_viewer.dialog_text = HeartwoodMemory.MEMORIES[index]
	_viewer.popup_centered(Vector2i(520, 200))

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
	button.custom_minimum_size = Vector2(160, 44)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	parent.add_child(button)
