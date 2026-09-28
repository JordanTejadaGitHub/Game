extends VBoxContainer

# Bottom-right run controls: a status line (resting / next drift in N s / rest ahead) with the
# Remember button during rests (Dreamlight: DreamState.open_remember), the Start /
# call-early button (Enter), the Auto-drift toggle, and pause / 1× / 2× / 3× buttons (Space pauses,
# Tab cycles speed). The act / drift line is the top-centre DriftBanner.

const BUTTON_FONT_SIZE := 16

@onready var drift_director: DriftDirector = %DriftDirector
@onready var game_speed: GameSpeed = %GameSpeed
@onready var run_state: RunState = %RunState
@onready var tower_seller: TowerSeller = %TowerSeller
@onready var tower_placer = %TowerPlacer  # Untyped: the Sapling API is guarded with has_method

@onready var dream_state: DreamState = %DreamState

var _status_label := Label.new()
var _remember_button := Button.new()
var _sapling_button := Button.new()
var _start_button := Button.new()
var _auto_toggle := CheckButton.new()
var _pause_button := Button.new()
var _speed_buttons: Array[Button] = []

func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_END
	# Status line, with the Remember button (run_design.md "Dreamlight") beside it during rests.
	var status_row := HBoxContainer.new()
	add_child(status_row)
	_remember_button.text = "Remember"
	_remember_button.tooltip_text = "Spend Dreamlight on branches and final forms of your families."
	_remember_button.focus_mode = Control.FOCUS_NONE
	_remember_button.custom_minimum_size = Vector2(0, 32)
	_remember_button.pressed.connect(func() -> void: dream_state.open_remember())
	status_row.add_child(_remember_button)
	# The Heartwood Sapling (run_design.md): plant it later if it was declined, or place it if taken.
	_sapling_button.text = "Sapling"
	_sapling_button.tooltip_text = "Plant the Heartwood Sapling: free, 2×2, rooted; yields Dew after every drift."
	_sapling_button.focus_mode = Control.FOCUS_NONE
	_sapling_button.custom_minimum_size = Vector2(0, 32)
	_sapling_button.visible = false
	_sapling_button.pressed.connect(plant_sapling)
	status_row.add_child(_sapling_button)
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_color_override("font_outline_color", Color(0.08, 0.1, 0.14))
	_status_label.add_theme_constant_override("outline_size", 6)
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.8))
	status_row.add_child(_status_label)

	_start_button.focus_mode = Control.FOCUS_NONE
	_start_button.custom_minimum_size = Vector2(272, 48)
	_start_button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	_start_button.pressed.connect(drift_director.start_next_drift)
	add_child(_start_button)

	# Kept compact (screens_ui.md principle 5): Auto-drift shares the speed row.
	var speed_row := HBoxContainer.new()
	speed_row.alignment = BoxContainer.ALIGNMENT_END
	speed_row.add_theme_constant_override("separation", 2)
	add_child(speed_row)
	_auto_toggle.text = "Auto"
	_auto_toggle.tooltip_text = "Auto-drift: drifts in a block start by themselves a few seconds after the last one arrived."
	_auto_toggle.focus_mode = Control.FOCUS_NONE
	_auto_toggle.button_pressed = drift_director.auto_drift
	_auto_toggle.toggled.connect(drift_director.set_auto_drift)
	speed_row.add_child(_auto_toggle)
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

# The Sapling was declined (still takeable) or taken but not planted yet.
func _sapling_waiting() -> bool:
	if not tower_placer.has_method("can_take_sapling"):
		return false
	return tower_placer.can_take_sapling() or tower_placer.has_unplanted_sapling()

# Takes the Sapling if it was declined, then selects it to place (TowerPlacer's Sapling API).
func plant_sapling() -> void:
	if tower_placer.can_take_sapling():
		tower_placer.take_sapling()  # Selects it too
	elif tower_placer.has_unplanted_sapling():
		tower_placer.select_tower(tower_placer.sapling)

func _add_speed_button(row: HBoxContainer, button: Button) -> void:
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(44, 40)
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
	# Remember reopens at any rest once a family is owned (after the first pick).
	_remember_button.visible = drift_director.is_resting() and not drift_director.awaiting_family_pick \
		and latest > 0 and not run_state.is_over
	_remember_button.text = "Remember (%d)" % dream_state.dreamlight
	_sapling_button.visible = _remember_button.visible and _sapling_waiting()
	var block_end := drift_director.get_block(maxi(latest, 1)) * drift_director.drifts_per_block
	if drift_director.awaiting_family_pick:
		_status_label.text = "Choose a Warden family…"
		_start_button.text = "Start Drift %d" % next
	elif not drift_director.has_next_drift():
		_status_label.text = "The last drift is walking"
		_start_button.text = "Final drift"
	elif drift_director.is_resting():
		_status_label.text = "Resting: rearrange (%d%% refunds)" % roundi(tower_seller.build_phase_refund * 100)
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
