extends PanelContainer
class_name SettingsPanel

# Settings (demo_scope.md "Basics"): audio, display, Heartwood whispers, key rebinding. Changes
# apply at once and are saved to HeartwoodMemory. Used by the title screen and the pause menu.

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

var _settings: Dictionary
var _waiting_action := ""  # Action waiting for a key press
var _key_buttons := {}  # action -> Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_settings = HeartwoodMemory.get_settings()
	custom_minimum_size = Vector2(440, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)

	_slider(box, "Volume", "master_volume")
	_slider(box, "Music", "music_volume")
	_slider(box, "Sounds", "sfx_volume")
	_toggle(box, "Fullscreen", "fullscreen")
	_slider(box, "UI scale", "ui_scale", 0.75, 1.5, 0.05)
	_toggle(box, "Heartwood whispers (hints)", "whispers")
	_toggle(box, "Auto-drift on by default", "auto_drift")
	_toggle(box, "Reduced motion", "reduced_motion")
	_choice(box, "Damage numbers", "damage_numbers", ["Off", "Big hits", "All"])
	if TestGrove.is_available():  # Debug builds only; never in the demo or release
		var dev := Label.new()
		dev.text = "Developer"
		box.add_child(dev)
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
	box.add_child(keys_title)
	var grid := GridContainer.new()
	grid.columns = 2
	box.add_child(grid)
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
	box.add_child(row)
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

func _choice(box: VBoxContainer, text: String, key: String, options: Array) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(120, 0)
	row.add_child(label)
	var pick := OptionButton.new()
	for option in options:
		pick.add_item(option)
	pick.selected = int(_settings.get(key, 1))
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

func _toggle(box: VBoxContainer, text: String, key: String) -> void:
	var check := CheckButton.new()
	check.text = text
	check.button_pressed = _settings[key]
	check.focus_mode = Control.FOCUS_NONE
	check.toggled.connect(func(on: bool) -> void: _set_value(key, on))
	box.add_child(check)

func _set_value(key: String, value) -> void:
	_settings[key] = value
	HeartwoodMemory.save_settings(_settings)
	HeartwoodMemory.apply_settings(_settings)

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
