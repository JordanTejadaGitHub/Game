extends Control

# Esc menu during a run: Resume, Settings, Save & Quit, Quit game. Pauses the game while open.
# Save & Quit saves right away when resting; otherwise the run resumes from its last rest
# (run_design.md "Mid-run save"). Esc still cancels build mode / a selection first. Built in code.

const TITLE_SCENE := "res://scenes/title.tscn"

@onready var game_speed: GameSpeed = %GameSpeed
@onready var run_saver: RunSaver = %RunSaver
@onready var tower_placer: TowerPlacer = %TowerPlacer
@onready var tower_seller: TowerSeller = %TowerSeller
@onready var run_state: RunState = %RunState

var _was_paused := false
var _menu := VBoxContainer.new()
var _settings: SettingsPanel
var _save_button: Button

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
	var panel := PanelContainer.new()
	center.add_child(panel)
	_menu.add_theme_constant_override("separation", 10)
	_menu.custom_minimum_size = Vector2(300, 0)
	panel.add_child(_menu)
	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	_menu.add_child(title)
	_add_button("Resume", close)
	_add_button("Settings", _show_settings)
	_save_button = _add_button("Save & Quit", _save_and_quit)
	_add_button("Quit game", func() -> void: get_tree().quit())
	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.closed.connect(func() -> void:
		_settings.visible = false
		panel.visible = true)
	center.add_child(_settings)
	_settings.set_meta("panel", panel)
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
	visible = true

func close() -> void:
	visible = false
	_settings.visible = false
	(_settings.get_meta("panel") as Control).visible = true
	game_speed.set_paused(_was_paused)

func _show_settings() -> void:
	(_settings.get_meta("panel") as Control).visible = false
	_settings.visible = true

func _save_and_quit() -> void:
	if run_saver.can_save_now():
		run_saver.save_now()
	get_tree().change_scene_to_file(TITLE_SCENE)
