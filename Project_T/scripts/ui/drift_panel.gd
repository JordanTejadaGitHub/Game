extends VBoxContainer

# Bottom-right run controls: act/drift label, Start Drift / call-early button (Enter), and
# pause / 1× / 2× / 3× buttons (Space pauses, Tab cycles speed).

const BUTTON_FONT_SIZE := 18

@onready var drift_director: DriftDirector = %DriftDirector
@onready var game_speed: GameSpeed = %GameSpeed
@onready var run_state: RunState = %RunState

var _drift_label := Label.new()
var _start_button := Button.new()
var _pause_button := Button.new()
var _speed_buttons: Array[Button] = []

func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_END
	_drift_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_drift_label.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	_drift_label.add_theme_color_override("font_outline_color", Color(0.08, 0.1, 0.14))
	_drift_label.add_theme_constant_override("outline_size", 6)
	add_child(_drift_label)

	_start_button.focus_mode = Control.FOCUS_NONE
	_start_button.custom_minimum_size = Vector2(260, 44)
	_start_button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	_start_button.pressed.connect(drift_director.start_next_drift)
	add_child(_start_button)

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
	var shown := maxi(latest, 1) if not drift_director.is_build_phase() else latest + 1
	shown = mini(shown, drift_director.get_total_drifts())
	var act := drift_director.get_act(shown)
	_drift_label.text = "Act %d · %s    Drift %d / %d" % [act, drift_director.get_act_name(act),
		latest, drift_director.get_total_drifts()]

	var next := latest + 1
	if not drift_director.has_next_drift():
		_start_button.text = "Final drift"
		_start_button.disabled = true
	elif drift_director.is_build_phase():
		_start_button.text = "Start Drift %d  (Enter)" % next
		_start_button.disabled = false
	elif drift_director.is_arriving():
		_start_button.text = "Drift %d arriving…" % latest
		_start_button.disabled = true
	else:
		var bonus := drift_director.get_call_early_bonus()
		_start_button.text = "Call Drift %d early  +%d Dew" % [next, bonus]
		_start_button.disabled = false

func _on_speed_changed(paused: bool, speed: float) -> void:
	_pause_button.set_pressed_no_signal(paused)
	for i in _speed_buttons.size():
		_speed_buttons[i].set_pressed_no_signal(not paused and game_speed.speeds[i] == speed)
