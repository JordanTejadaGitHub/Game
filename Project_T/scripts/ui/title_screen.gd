extends Control

# Title screen: Continue (when a run is saved), New run, Settings, Quit, and the Seeds banked so
# far. Applies the saved settings on start. Built in code.

const GAME_SCENE := "res://scenes/main.tscn"
const TITLE := "The Heartwood Remembers"

var _menu := VBoxContainer.new()
var _settings: SettingsPanel
var _confirm: ConfirmationDialog

func _ready() -> void:
	HeartwoodMemory.apply_settings()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.07, 0.11, 0.09)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_menu.add_theme_constant_override("separation", 12)
	_menu.custom_minimum_size = Vector2(320, 0)
	center.add_child(_menu)
	var title := Label.new()
	title.text = TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.85, 1.0, 0.8))
	_menu.add_child(title)
	if ResultsScreen.is_demo():
		var demo := Label.new()
		demo.text = "Demo"
		demo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		demo.add_theme_color_override("font_color", Color(0.7, 0.8, 0.7))
		_menu.add_child(demo)
	_menu.add_child(HSeparator.new())

	if RunSaver.has_save():
		_add_button("Continue", _continue)
	_add_button("New run", _new_run)
	_add_button("Settings", _show_settings)
	_add_button("Credits", _show_credits)
	_add_button("Quit", func() -> void: get_tree().quit())

	var seeds := Label.new()
	var memory := HeartwoodMemory.load_data()
	seeds.text = "Seeds banked: %d" % memory.seeds if memory.runs_played > 0 else ""
	seeds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	seeds.add_theme_color_override("font_color", Color(0.75, 0.95, 0.6))
	_menu.add_child(seeds)

	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.closed.connect(func() -> void:
		_settings.visible = false
		_menu.visible = true)
	center.add_child(_settings)

	_confirm = ConfirmationDialog.new()
	_confirm.dialog_text = "Start a new run? The run in progress will be lost."
	_confirm.confirmed.connect(_start_new)
	add_child(_confirm)

func _add_button(text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 44)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	_menu.add_child(button)

func _continue() -> void:
	RunSaver.resume_next = true
	get_tree().change_scene_to_file(GAME_SCENE)

func _new_run() -> void:
	if RunSaver.has_save():
		_confirm.popup_centered()  # One run in progress at a time
	else:
		_start_new()

func _start_new() -> void:
	RunSaver.delete_save()
	RunSaver.resume_next = false
	get_tree().change_scene_to_file(GAME_SCENE)

func _show_settings() -> void:
	_menu.visible = false
	_settings.visible = true

# Credits with Godot's licence notice (required when shipping; demo_scope.md "Credits").
func _show_credits() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Credits"
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 420)
	var text := Label.new()
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(590, 0)
	text.text = "%s\n\nMade with the Godot Engine (godotengine.org).\n\n%s\n\nThird-party components in Godot:\n%s" % [
		TITLE, Engine.get_license_text(), _godot_components()]
	scroll.add_child(text)
	dialog.add_child(scroll)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()

func _godot_components() -> String:
	var lines: Array[String] = []
	for info in Engine.get_copyright_info():
		lines.append("• %s" % info.name)
	return "\n".join(lines)
