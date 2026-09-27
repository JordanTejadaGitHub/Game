extends VBoxContainer

# Bottom-right run controls: a status line (resting / next drift in N s / rest ahead), the Start /
# call-early button (Enter), the Auto-drift toggle, and pause / 1× / 2× / 3× buttons (Space pauses,
# Tab cycles speed). The act / drift line is the top-centre DriftBanner.

const BUTTON_FONT_SIZE := 18

@onready var drift_director: DriftDirector = %DriftDirector
@onready var game_speed: GameSpeed = %GameSpeed
@onready var run_state: RunState = %RunState

var _status_label := Label.new()
var _start_button := Button.new()
var _auto_toggle := CheckButton.new()
var _pause_button := Button.new()
var _speed_buttons: Array[Button] = []

func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_END
	for label in [_status_label]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.add_theme_color_override("font_outline_color", Color(0.08, 0.1, 0.14))
		label.add_theme_constant_override("outline_size", 6)
		add_child(label)
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.8))

	_start_button.focus_mode = Control.FOCUS_NONE
	_start_button.custom_minimum_size = Vector2(280, 44)
	_start_button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	_start_button.pressed.connect(drift_director.start_next_drift)
	add_child(_start_button)

	_auto_toggle.text = "Auto-drift"
	_auto_toggle.tooltip_text = "Drifts in a block start by themselves a few seconds after the last one arrived."
	_auto_toggle.focus_mode = Control.FOCUS_NONE
	_auto_toggle.button_pressed = drift_director.auto_drift
	_auto_toggle.toggled.connect(drift_director.set_auto_drift)
	_auto_toggle.size_flags_horizontal = Control.SIZE_SHRINK_END
	add_child(_auto_toggle)

	var speed_row := HBoxContainer.new()
	speed_row.alignment = BoxContainer.ALIGNMENT_END
	add_child(speed_row)
	_pause_button.text = "II"
	_pause_button.tooltip_text = "Pause (Space). You can still build while paused."
	_pause_button.pressed.connect(game_speed.toggle_pause)
	_add_speed_button(speed_row, _pause_button)
	for speed in game_speed.speeds:
		var button := Button.new()
		button.text = "%d×" % speed
		button.tooltip_text = "Speed %d× (Tab cycles)" % speed
		button.pressed.connect(game_speed.set_speed.bind(speed))
		_add_speed_button(speed_row, button)
		_speed_buttons.append(button)

	game_speed.changed.connect(_on_speed_changed)
	_on_speed_changed(game_speed.paused, game_speed.speed)
	run_state.run_ended.connect(func(_won: bool) -> void: _start_button.visible = false)

func _add_speed_button(row: HBoxContainer, button: Button) -> void:
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(52, 36)
	row.add_child(button)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start_drift"):
		drift_director.start_next_drift()
		get_viewport().set_input_as_handled()

# The call-early bonus changes every frame as creatures walk, so refresh continuously.
func _process(_delta: float) -> void:
	var latest := drift_director.drifts_started
	var next := latest + 1

	_start_button.disabled = not drift_director.can_start_next_drift()
	var block_end := drift_director.get_block(maxi(latest, 1)) * drift_director.drifts_per_block
	if drift_director.awaiting_family_pick:
		_status_label.text = "Choose a Warden family…"
		_start_button.text = "Start Drift %d" % next
	elif not drift_director.has_next_drift():
		_status_label.text = "The last drift is walking"
		_start_button.text = "Final drift"
	elif drift_director.is_resting():
		_status_label.text = "Resting: rearrange freely (full refunds)"
		var boss := " (boss)" if drift_director.is_boss_drift(next) else ""
		_start_button.text = "Start Drift %d%s  (Enter)" % [next, boss]
	elif drift_director.can_start_next_drift():
		var countdown := drift_director.get_auto_countdown()
		_status_label.text = "Drift %d in %d s" % [next, ceili(countdown)] if countdown >= 0.0 \
			else "Rest after drift %d" % block_end
		var bonus := drift_director.get_call_early_bonus()
		_start_button.text = "Call Drift %d early  +%d Dew" % [next, bonus] if bonus > 0 \
			else "Start Drift %d now" % next
	else:
		_status_label.text = "Rest once the field is clear"
		_start_button.text = "Rest after drift %d" % block_end

func _on_speed_changed(paused: bool, speed: float) -> void:
	_pause_button.set_pressed_no_signal(paused)
	for i in _speed_buttons.size():
		_speed_buttons[i].set_pressed_no_signal(not paused and game_speed.speeds[i] == speed)
