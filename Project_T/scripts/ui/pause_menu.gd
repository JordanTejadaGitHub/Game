extends Control

# Esc menu during a run (screens_ui.md "Pause"): Resume, Settings, Codex, Save & Quit, Abandon run (confirm;
# still earns Seeds), Quit game, a Heartwood whispers toggle, and a run summary on the side (drift,
# Dreams, families, active Omen, time played). Pauses the game while open. Save & Quit saves right
# away when resting; otherwise the run resumes from its last rest (run_design.md "Mid-run save").
# Esc still cancels build mode / a selection first. Built in code.

const TITLE_SCENE := "res://scenes/title.tscn"
const FAMILY_TIER := 1  # Base Wardens are the families

@onready var game_speed: GameSpeed = %GameSpeed
@onready var run_saver: RunSaver = %RunSaver
@onready var tower_placer: TowerPlacer = %TowerPlacer
@onready var tower_seller: TowerSeller = %TowerSeller
@onready var run_state: RunState = %RunState
@onready var drift_director: DriftDirector = %DriftDirector
@onready var dream_state: DreamState = %DreamState

var _was_paused := false
var _menu := VBoxContainer.new()
var _panel := PanelContainer.new()
var _summary := Label.new()  # The run summary as text (kept for tests and screen readers; hidden)
var _facts := GridContainer.new()  # "This run" as icon rows (light pass): drift, Dreams, Omen, time
var _families := HBoxContainer.new()  # The run's families as their emblems
var _settings: SettingsPanel
var codex: CodexPanel  # The Reaction Codex (screens_ui.md "Reactions")
var _save_button: Button
var _whispers_toggle := CheckButton.new()
var _confirm_abandon := ConfirmationDialog.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(StatusLinks.CODEX_HOST_GROUP)  # Status links' "More in the Codex"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(UiStyle.FOG, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	center.add_child(row)
	codex = CodexPanel.new()
	codex.visibility_changed.connect(func() -> void:
		if not codex.visible:
			row.visible = true)
	center.add_child(codex)
	# Light pass (UI Asset's second page, user-approved): one panel, two columns. Left: the title, Resume the one
	# primary (Esc), Settings / Codex / Save and quit, then Abandon run and Quit game as quiet text. Right: "this run"
	# as icon rows, the families' emblems, and the Hints switch at the bottom.
	row.add_child(_panel)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 28)
	_panel.add_child(columns)
	_menu.add_theme_constant_override("separation", 8)
	_menu.custom_minimum_size = Vector2(250, 0)
	columns.add_child(_menu)
	var title := Label.new()
	title.text = "Paused"
	UiStyle.display(title, 32)
	_menu.add_child(title)
	var resume := _add_button("Resume", close)
	UiStyle.primary(resume)
	var esc := UiStyle.key_chip("Esc")
	esc.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	esc.offset_left = -44
	esc.offset_right = -14
	resume.add_child(esc)
	_add_button("Settings", _show_settings)
	_add_button("Codex", func() -> void:
		row.visible = false
		codex.open())
	_save_button = _add_button("Save and quit", _save_and_quit)
	var quiet_row := GridContainer.new()
	quiet_row.columns = 2
	_menu.add_child(quiet_row)
	for pair in [["Abandon run", func() -> void: _confirm_abandon.popup_centered()], ["Quit game", func() -> void: get_tree().quit()]]:
		var button := _add_button(pair[0], pair[1])
		_menu.remove_child(button)
		UiStyle.quiet(button)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		quiet_row.add_child(button)

	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(240, 0)
	side.add_theme_constant_override("separation", 12)
	columns.add_child(side)
	var head := Label.new()
	head.text = "This run"
	UiStyle.caps(head, 14)
	side.add_child(head)
	_facts.columns = 2
	_facts.add_theme_constant_override("h_separation", 12)
	_facts.add_theme_constant_override("v_separation", 10)
	side.add_child(_facts)
	_families.add_theme_constant_override("separation", 6)
	side.add_child(_families)
	_summary.visible = false
	side.add_child(_summary)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(spacer)
	var hints := HBoxContainer.new()
	hints.custom_minimum_size.y = UiStyle.HUD_BUTTON_H
	var hints_label := Label.new()
	hints_label.text = "Hints"  # The Heartwood's hints (were "Heartwood whispers")
	hints_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hints_label.add_theme_color_override("font_color", UiStyle.INK_DIM)
	hints.add_child(hints_label)
	_whispers_toggle.focus_mode = Control.FOCUS_NONE
	_whispers_toggle.tooltip_text = "The Heartwood's hints"
	_whispers_toggle.toggled.connect(_set_whispers)
	hints.add_child(_whispers_toggle)
	side.add_child(hints)

	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.closed.connect(func() -> void:
		_settings.visible = false
		row.visible = true)
	center.add_child(_settings)
	_settings.set_meta("row", row)

	_confirm_abandon.dialog_text = "Abandon this run? The dream goes dark, but you keep the Seeds you've earned."
	_confirm_abandon.process_mode = Node.PROCESS_MODE_ALWAYS
	_confirm_abandon.confirmed.connect(_abandon)
	add_child(_confirm_abandon)
	visible = false

func _add_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, UiStyle.HUD_BUTTON_H)  # 48: every button a tap target
	button.pressed.connect(action)
	_menu.add_child(button)
	return button

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("open_menu"):
		return
	if visible:
		close()
	elif tower_placer.build_mode or tower_seller.selected != null or run_state.is_over:
		return  # Esc cancels building / deselects first (they handle it)
	else:
		open()
	get_viewport().set_input_as_handled()

func open() -> void:
	_was_paused = game_speed.paused
	game_speed.set_paused(true)
	_save_button.text = "Save and quit"
	_save_button.tooltip_text = "" if run_saver.can_save_now() else "Resumes from the last rest."
	_whispers_toggle.set_pressed_no_signal(HeartwoodMemory.get_settings().whispers)
	_summary.text = get_run_summary()
	_fill_facts()
	visible = true

# "This run" (light pass): icon, label, value per row; the families as emblems (their names when there's no art).
func _fill_facts() -> void:
	for child in _facts.get_children() + _families.get_children():
		child.get_parent().remove_child(child)
		child.queue_free()
	var dreams := 0
	for id in dream_state.stacks:
		dreams += dream_state.stacks[id]
	_fact(&"path_length", "drift", "%d of %d" % [drift_director.drifts_started, drift_director.get_total_drifts()])
	_fact(&"rank", "dreams", str(dreams))
	var omens := get_tree().get_first_node_in_group(&"omens")
	if omens != null and omens.get("active") != null:
		_fact(&"omen", "omen", omens.active.display_name)
	var seconds := int(run_state.play_time)
	_fact(&"", "time", "%d:%02d:%02d" % [seconds / 3600, seconds / 60 % 60, seconds % 60])
	for data in tower_placer.towers:
		if data.tier == FAMILY_TIER and dream_state.is_unlocked(data.get_id()):
			var art := BranchEmblem.family(data)
			if art == null:
				art = data.texture  # No emblem yet: the base Warden's frame
			var emblem := TextureRect.new()
			if art == data.texture and data.texture != null:
				var frame := AtlasTexture.new()
				frame.atlas = data.texture
				frame.region = data.get_frame_rect(0)
				art = frame
			emblem.texture = art
			emblem.custom_minimum_size = Vector2(32, 32)
			emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			emblem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			emblem.tooltip_text = data.display_name
			_families.add_child(emblem)

func _fact(icon_id: StringName, label: String, value: String) -> void:
	var left := HBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	var art: Texture2D = IconInfo.icon(icon_id) if icon_id != &"" else null
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(16, 16)
	icon.texture = art
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	left.add_child(icon)
	var name_label := Label.new()
	name_label.text = label
	name_label.add_theme_color_override("font_color", UiStyle.INK_DIM)
	left.add_child(name_label)
	_facts.add_child(left)
	var value_label := Label.new()
	value_label.name = "Fact_" + label
	value_label.text = value
	UiStyle.number(value_label, 18)
	_facts.add_child(value_label)

# Opens the pause menu straight on the Codex (the HUD "?" button, a tapped discovery card),
# optionally on a tab and entry (CodexPanel.open).
func open_codex(tab: StringName = &"", entry: String = "") -> void:
	if not visible:
		open()
	(_settings.get_meta("row") as Control).visible = false
	codex.open(tab, entry)

func close() -> void:
	visible = false
	_settings.visible = false
	codex.visible = false
	(_settings.get_meta("row") as Control).visible = true
	game_speed.set_paused(_was_paused)

# Drift, Dreams, families, active Omen and time played, for the side panel.
func get_run_summary() -> String:
	var lines: Array[String] = ["This run"]
	lines.append("Drift %d / %d" % [drift_director.drifts_started, drift_director.get_total_drifts()])
	var dreams := 0
	for id in dream_state.stacks:
		dreams += dream_state.stacks[id]
	lines.append("Dreams taken: %d" % dreams)
	var families: Array[String] = []
	for data in tower_placer.towers:
		if data.tier == FAMILY_TIER and dream_state.is_unlocked(data.get_id()):
			families.append(data.display_name)
	lines.append("Families: %s" % (", ".join(families) if not families.is_empty() else "none yet"))
	var omens := get_tree().get_first_node_in_group(&"omens")
	if omens != null and omens.get("active") != null:
		lines.append("Omen: %s" % omens.active.display_name)
	var seconds := int(run_state.play_time)
	lines.append("Time: %d:%02d:%02d" % [seconds / 3600, seconds / 60 % 60, seconds % 60])
	return "\n".join(lines)

func _show_settings() -> void:
	(_settings.get_meta("row") as Control).visible = false
	_settings.visible = true

func _set_whispers(on: bool) -> void:
	var settings := HeartwoodMemory.get_settings()
	settings.whispers = on
	HeartwoodMemory.save_settings(settings)
	var whispers := get_node_or_null("%Whispers")
	if whispers != null:
		whispers.set_enabled(on)

# Ends the run as a loss (Seeds are still earned: the results screen banks them).
func _abandon() -> void:
	close()
	run_state.abandoned = true
	run_state.end_run(false)

func _save_and_quit() -> void:
	if run_saver.can_save_now():
		run_saver.save_now()
	get_tree().change_scene_to_file(TITLE_SCENE)
