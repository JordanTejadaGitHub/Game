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
var _summary := Label.new()
var _settings: SettingsPanel
var codex: CodexPanel  # The Reaction Codex (screens_ui.md "Reactions")
var _save_button: Button
var _whispers_toggle := CheckButton.new()
var _confirm_abandon := ConfirmationDialog.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.05, 0.06, 0.6)
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
	row.add_child(_panel)
	_menu.add_theme_constant_override("separation", 10)
	_menu.custom_minimum_size = Vector2(300, 0)
	_panel.add_child(_menu)
	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	_menu.add_child(title)
	_add_button("Resume", close)
	_add_button("Settings", _show_settings)
	_add_button("Codex", func() -> void:
		row.visible = false
		codex.open())
	_save_button = _add_button("Save & Quit", _save_and_quit)
	_add_button("Abandon run", func() -> void: _confirm_abandon.popup_centered())
	_add_button("Quit game", func() -> void: get_tree().quit())
	_whispers_toggle.text = "Heartwood whispers"
	_whispers_toggle.focus_mode = Control.FOCUS_NONE
	_whispers_toggle.toggled.connect(_set_whispers)
	_menu.add_child(_whispers_toggle)

	var summary_panel := PanelContainer.new()
	summary_panel.custom_minimum_size = Vector2(260, 0)
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_panel.add_child(_summary)
	row.add_child(summary_panel)
	_panel.set_meta("summary", summary_panel)

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
	button.custom_minimum_size = Vector2(0, 40)
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
	_save_button.text = "Save & Quit" if run_saver.can_save_now() \
		else "Save & Quit (resumes from the last rest)"
	_whispers_toggle.set_pressed_no_signal(HeartwoodMemory.get_settings().whispers)
	_summary.text = get_run_summary()
	visible = true

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
	run_state.end_run(false)

func _save_and_quit() -> void:
	if run_saver.can_save_now():
		run_saver.save_now()
	get_tree().change_scene_to_file(TITLE_SCENE)
