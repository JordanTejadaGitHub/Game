extends Control

# Title screen (screens_ui.md): Continue (when a run is saved), New run (with the Blight Level
# picker after the first win), Memory Grove (full game; a greyed teaser in the demo, plus Wishlist),
# Settings, Credits, Quit, the Seeds banked and the highest Blight Level won. Applies the saved
# settings on start. Built in code.

const GAME_SCENE := "res://scenes/main.tscn"
const GROVE_SCENE := "res://scenes/grove.tscn"
const TITLE := "Heartwood TD"  # The game's title (project.godot config/name too)

var _menu := VBoxContainer.new()  # The left column: the title over the menu panel
var _buttons := VBoxContainer.new()
var _settings: SettingsPanel
var _codex: CodexPanel
var _confirm: ConfirmationDialog
var _blight := BlightPicker.new()

# The game was renamed from "Project_T" to "Heartwood TD" (project.godot config/name), which moves
# Godot's user:// folder. Once, copy the profile and run save across if the new folder has none.
const OLD_USER_DIR := "Project_T"
const SAVE_FILES := ["heartwood.json", "run.json"]

static func migrate_old_saves() -> void:
	var new_dir := OS.get_user_data_dir()
	var old_dir := new_dir.get_base_dir().path_join(OLD_USER_DIR)
	if old_dir == new_dir or not DirAccess.dir_exists_absolute(old_dir):
		return
	for file in SAVE_FILES:
		var target := new_dir.path_join(file)
		var source := old_dir.path_join(file)
		if not FileAccess.file_exists(target) and FileAccess.file_exists(source):
			DirAccess.make_dir_recursive_absolute(new_dir)
			DirAccess.copy_absolute(source, target)

const GROUP := &"title_screen"
const MENU_LEFT := 72.0  # The menu sits in the art's calm left side
const MENU_WIDTH := 340.0

func _ready() -> void:
	if CaptureDirector.begin(get_tree()):
		return  # A marketing capture (-- --capture=…): its own profile, straight into the run
	UiStyle.install_tooltip_wrap(get_tree())  # Long tooltips wrap at the tip width
	migrate_old_saves()
	DevGrove.apply()  # Dev Grove (debug builds): the dev profile, before anything reads the profile
	HeartwoodMemory.apply_settings()
	add_to_group(GROUP)
	add_to_group(StatusLinks.CODEX_HOST_GROUP)  # Status links' "More in the Codex"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(TitleBackdrop.new())  # The art (tools/title_art_generator.gd)
	var center := CenterContainer.new()  # Settings and the Codex open in the middle
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	if OS.is_debug_build():  # The exact build on disk ("Sep 30 21:14 · 3f9a2c"; balance_simulation.md)
		_add_build_label()

	# The left column, in the art's calm side: the title over a Moon panel with the menu.
	var column := MarginContainer.new()
	column.anchor_bottom = 1.0
	column.offset_left = MENU_LEFT
	column.offset_right = MENU_LEFT + MENU_WIDTH
	add_child(column)
	_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	_menu.add_theme_constant_override("separation", 14)
	column.add_child(_menu)
	var title := Label.new()
	title.text = TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.display(title, 56)
	title.add_theme_color_override("font_color", UiStyle.INK)
	title.add_theme_color_override("font_outline_color", Palette.VOID)
	title.add_theme_constant_override("outline_size", 12)
	_menu.add_child(title)
	if ResultsScreen.is_demo():
		var demo := Label.new()
		demo.text = "Demo"
		demo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiStyle.caps(demo, 18, UiStyle.WHISPER)
		demo.add_theme_color_override("font_outline_color", Palette.VOID)
		demo.add_theme_constant_override("outline_size", 8)
		_menu.add_child(demo)
	# A fog patch behind the column, no thread of its own: the primary carries the one mark (UI light pass).
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.fog_patch(20.0, 18.0))
	_menu.add_child(panel)
	_buttons.add_theme_constant_override("separation", 10)
	panel.add_child(_buttons)

	# The first choice takes the primary look; every other entry keeps its border (ui_style.md "Buttons").
	if RunSaver.has_save():
		UiStyle.primary(_add_button("Continue", _continue))
	var new_run := _add_button("New run", _new_run)
	if not RunSaver.has_save():
		UiStyle.primary(new_run)
	if ResultsScreen.is_demo():
		var grove := _add_button("Memory Grove", func() -> void: pass)
		grove.disabled = true
		grove.tooltip_text = "In the full game."
		var url: String = ProjectSettings.get_setting(ResultsScreen.WISHLIST_SETTING, "")
		var wishlist := _add_button("Wishlist on Steam", func() -> void: OS.shell_open(url))
		wishlist.disabled = url == ""
		wishlist.tooltip_text = "Store page coming soon." if url == "" else url
	else:
		_add_button("Memory Grove", func() -> void: get_tree().change_scene_to_file(GROVE_SCENE))
	_add_button("Settings", _show_settings)
	_add_button("Codex", func() -> void:  # screens_ui.md "The Codex"
		_menu.visible = false
		_codex.open())
	_add_button("Credits", _show_credits)
	var quit := _add_button("Quit", func() -> void: get_tree().quit())
	quit.add_theme_color_override("font_color", UiStyle.INK_DIM)  # Last, in Mist

	var memory := HeartwoodMemory.load_data()
	if memory.runs_played > 0:  # Seeds banked: the Seeds glyph and the number, in Sprig
		_buttons.add_child(_seeds_row(int(memory.seeds)))
	if int(memory.highest_blight_won) > 0:  # A blossom per Blight Level won (text until the art exists)
		var blight := Label.new()
		blight.text = "✿".repeat(int(memory.highest_blight_won)) + "  Blight Level %d won" % int(memory.highest_blight_won)
		blight.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiStyle.caps(blight, UiStyle.LABEL_SIZE, UiStyle.LIVE)
		_buttons.add_child(blight)

	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.closed.connect(func() -> void:
		_settings.visible = false
		_menu.visible = true)
	center.add_child(_settings)
	_codex = CodexPanel.new()
	_codex.visibility_changed.connect(func() -> void:
		if not _codex.visible:
			_menu.visible = true)
	center.add_child(_codex)

	_confirm = ConfirmationDialog.new()
	_confirm.dialog_text = "Start a new run? The run in progress will be lost."
	_confirm.confirmed.connect(_start_new)
	add_child(_confirm)
	add_child(_blight)
	_blight.picked.connect(func(level: int) -> void:
		MetaRun.blight_level = level
		_go())

# Rebuilds the title (Continue, the Memory Grove button, Seeds) after a developer setting changes.
func refresh() -> void:
	get_tree().reload_current_scene.call_deferred()

# The Codex on a tab / entry (a status link's "More in the Codex").
func open_codex(tab: StringName = &"", entry: String = "") -> void:
	_menu.visible = false
	_settings.visible = false
	_codex.open(tab, entry)

# A menu entry: the secondary button (Gold outline, fog fill, ink text), full column width, 48 px tall.
# The primary choice is restyled by the caller.
func _add_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 48)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	_buttons.add_child(button)
	return button

# "Seeds banked" as an icon row: the Seeds glyph at 2× and the number in the number font, Sprig.
func _seeds_row(seeds: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.tooltip_text = "Seeds banked"
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var glyph := IconInfo.icon(&"seeds")
	if glyph:
		var icon := TextureRect.new()
		icon.texture = glyph
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = glyph.get_size() * 2.0
		row.add_child(icon)
	var count := Label.new()
	count.text = str(seeds)
	UiStyle.number(count, UiStyle.NUMBER_SIZE, UiStyle.LIVE)
	row.add_child(count)
	return row

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
	var max_level := HeartwoodMemory.max_blight_level(HeartwoodMemory.load_data())
	if max_level > 0 and not ResultsScreen.is_demo():
		_blight.open(max_level)  # Blight Levels open after the first win
	else:
		MetaRun.blight_level = 0
		_go()

func _go() -> void:
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

# Bottom right, small: the build id, filled in once BuildInfo's thread is done.
func _add_build_label() -> void:
	BuildInfo.start()
	var label := Label.new()
	label.name = "BuildLabel"
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	label.offset_right = -12
	label.offset_bottom = -8
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", UiStyle.INK_DIM)
	add_child(label)
	var timer := Timer.new()
	timer.wait_time = 0.25
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(func() -> void:
		var text := BuildInfo.label_if_ready()
		if text != "":
			label.text = "Build " + text
			timer.queue_free())
