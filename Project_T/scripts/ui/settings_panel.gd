extends PanelContainer
class_name SettingsPanel

# Settings (screens_ui.md "Settings"): tabs Audio, Display (fullscreen, window size, V-sync, UI
# scale), Gameplay, Accessibility (reduced motion, flashes, hit-stop, high-contrast route line),
# Controls (rebinding) and, in debug builds, Developer. Changes apply at once and are saved to
# HeartwoodMemory. Used by the title screen and the pause menu.

signal closed

# Rebindable keyboard actions and their labels.
const REBINDABLE := [
	["move_camera_up", "Camera up"], ["move_camera_down", "Camera down"],
	["move_camera_left", "Camera left"], ["move_camera_right", "Camera right"],
	["toggle_build_mode", "Build mode"], ["start_drift", "Start / next drift"],
	["pause_game", "Pause"], ["cycle_speed", "Change speed"], ["sell_tower", "Sell Warden"],
	["grow_warden", "Grow selected Warden"], ["nurture_warden", "Nurture selected Warden"],
	["center_heartwood", "Centre on the Heartwood"],
	["center_start", "Centre on the forest's edge"],
]

const VSYNC_SETTING := "vsync"
const WINDOW_SIZE_SETTING := "window_size"  # Index into WINDOW_SIZES (windowed mode)
const WINDOW_SIZES: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1280, 800), Vector2i(1600, 900),
	Vector2i(1920, 1080), Vector2i(2560, 1440)]

static var _display_applied := false  # The window size is set once at startup, then on request

var tabs := TabContainer.new()
var _settings: Dictionary
var _waiting_action := ""  # Action waiting for a key press
var _key_buttons := {}  # action -> Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_settings = HeartwoodMemory.get_settings()
	custom_minimum_size = Vector2(480, 0)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	add_child(outer)
	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 24)
	outer.add_child(title)
	# Tabs as in screens_ui.md "Settings" (Language comes with translations).
	tabs.custom_minimum_size = Vector2(0, 420)
	outer.add_child(tabs)

	var audio := _tab("Audio")
	_slider(audio, "Volume", "master_volume")
	_slider(audio, "Music", "music_volume")
	_slider(audio, "Sounds", "sfx_volume")

	var display := _tab("Display")
	_toggle(display, "Fullscreen", "fullscreen")
	_choice(display, "Window size", WINDOW_SIZE_SETTING,
		WINDOW_SIZES.map(func(s: Vector2i) -> String: return "%d × %d" % [s.x, s.y]), 0)
	_toggle(display, "V-sync", VSYNC_SETTING, true)
	_slider(display, "UI scale", "ui_scale", 0.75, 1.5, 0.05)

	var gameplay := _tab("Gameplay")
	_toggle(gameplay, "Heartwood whispers (hints)", "whispers")
	_toggle(gameplay, "Auto-drift on by default", "auto_drift")
	_choice(gameplay, "Damage numbers", "damage_numbers", ["Off", "Big hits", "All"])
	_toggle(gameplay, "Confirm selling several Wardens during a drift", "confirm_sell", true)

	var box := _tab("Accessibility")
	_toggle(box, "Reduced motion", "reduced_motion")
	_toggle(box, "Reduce flashes", "reduce_flashes")
	_toggle(box, "Hit-stop on big hits", "hitstop")
	_toggle(box, "High-contrast route line", RouteLine.SETTING, false)

	var controls := _tab("Controls")
	if TestGrove.is_available():  # Debug builds only; never in the demo or release
		box = _tab("Developer")
		var grove := CheckButton.new()
		grove.text = "Test Grove: every Warden unlocked (from the next run)"
		grove.button_pressed = _settings.get(TestGrove.SETTING, false)
		grove.focus_mode = Control.FOCUS_NONE
		grove.toggled.connect(func(on: bool) -> void: _set_value(TestGrove.SETTING, on))
		box.add_child(grove)
		var families := CheckButton.new()
		families.text = "Unlock all families: normal runs, every family in the picks (no Seeds banked)"
		families.tooltip_text = "As if the Memory Grove's Warden root were fully grown, for this and later runs while on.\nYour real Grove unlocks are not changed."
		families.button_pressed = _settings.get(MetaRun.ALL_FAMILIES_SETTING, false)
		families.focus_mode = Control.FOCUS_NONE
		families.toggled.connect(func(on: bool) -> void: _set_value(MetaRun.ALL_FAMILIES_SETTING, on))
		box.add_child(families)

	var keys_title := Label.new()
	keys_title.text = "Keys (click, then press a key)"
	controls.add_child(keys_title)
	var grid := GridContainer.new()
	grid.columns = 2
	controls.add_child(grid)
	for pair in REBINDABLE:
		var label := Label.new()
		label.text = pair[1]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(label)
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(140, 0)
		button.pressed.connect(_listen.bind(pair[0]))
		grid.add_child(button)
		_key_buttons[pair[0]] = button
	_refresh_keys()

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	outer.add_child(row)
	var reset := Button.new()
	reset.text = "Default keys"
	reset.focus_mode = Control.FOCUS_NONE
	reset.pressed.connect(_reset_keys)
	row.add_child(reset)
	var back := Button.new()
	back.text = "Back"
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(func() -> void:
		_waiting_action = ""
		closed.emit())
	row.add_child(back)

# A scrollable tab page.
func _tab(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 8)
	scroll.add_child(page)
	return page

# V-sync, and the window size (windowed only) when `resize` or the first time; also run from
# HeartwoodMemory.apply_settings, which is called on every change, so it only resizes when asked.
static func apply_display(settings: Dictionary, resize: bool = true) -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings.get(VSYNC_SETTING, true)
		else DisplayServer.VSYNC_DISABLED)
	resize = resize or not _display_applied
	_display_applied = true
	if resize and not settings.get("fullscreen", false):
		var index := clampi(int(settings.get(WINDOW_SIZE_SETTING, 0)), 0, WINDOW_SIZES.size() - 1)
		var size: Vector2i = WINDOW_SIZES[index]
		var screen := DisplayServer.screen_get_size()
		if screen.x > 0:
			size = size.min(screen)
		DisplayServer.window_set_size(size)
		DisplayServer.window_set_position(DisplayServer.screen_get_position()
			+ (DisplayServer.screen_get_size() - size) / 2)

func _choice(box: VBoxContainer, text: String, key: String, options: Array, default: int = 1) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(120, 0)
	row.add_child(label)
	var pick := OptionButton.new()
	for option in options:
		pick.add_item(option)
	pick.selected = int(_settings.get(key, default))
	pick.focus_mode = Control.FOCUS_NONE
	pick.item_selected.connect(func(index: int) -> void: _set_value(key, index))
	row.add_child(pick)
	box.add_child(row)

func _slider(box: VBoxContainer, text: String, key: String, min_value: float = 0.0,
		max_value: float = 1.0, step: float = 0.05) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(120, 0)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = _settings[key]
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.focus_mode = Control.FOCUS_NONE
	slider.value_changed.connect(func(value: float) -> void: _set_value(key, value))
	row.add_child(slider)
	box.add_child(row)

func _toggle(box: VBoxContainer, text: String, key: String, default: bool = false) -> void:
	var check := CheckButton.new()
	check.text = text
	check.button_pressed = bool(_settings.get(key, default))
	check.focus_mode = Control.FOCUS_NONE
	check.toggled.connect(func(on: bool) -> void: _set_value(key, on))
	box.add_child(check)

func _set_value(key: String, value) -> void:
	_settings[key] = value
	HeartwoodMemory.save_settings(_settings)
	HeartwoodMemory.apply_settings(_settings)
	RouteLine.reload()
	if key in [VSYNC_SETTING, WINDOW_SIZE_SETTING, "fullscreen"]:
		apply_display(_settings)

func _listen(action: String) -> void:
	_waiting_action = action
	_key_buttons[action].text = "Press a key…"

func _input(event: InputEvent) -> void:
	if _waiting_action == "" or not visible:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	get_viewport().set_input_as_handled()
	if key.physical_keycode != KEY_ESCAPE:  # Esc cancels the rebind
		var binds: Dictionary = _settings.keybinds
		binds[_waiting_action] = [key.physical_keycode]
		_set_value("keybinds", binds)
	_waiting_action = ""
	_refresh_keys()

func _reset_keys() -> void:
	_settings.keybinds = {}
	HeartwoodMemory.save_settings(_settings)
	InputMap.load_from_project_settings()
	HeartwoodMemory.apply_settings(_settings)
	_refresh_keys()

func _refresh_keys() -> void:
	for action in _key_buttons:
		var names: Array[String] = []
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				names.append(OS.get_keycode_string(event.physical_keycode))
		_key_buttons[action].text = ", ".join(names) if not names.is_empty() else "—"
