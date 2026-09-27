extends Node
class_name GameSpeed

# Pause / 1× / 2× / 3×. Pausing pauses the scene tree: creatures, Wardens, drifts and effects stop,
# while nodes set to PROCESS_MODE_ALWAYS (HUD, build/clear/sell tools, camera) keep working, so you
# can plan and build while paused. Speed-ups use Engine.time_scale.

signal changed(paused: bool, speed: float)

@export var speeds: Array[float] = [1.0, 2.0, 3.0]

var speed := 1.0
var paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply()

func _exit_tree() -> void:
	# Don't leak speed/pause into the next scene (e.g. restarting a run).
	Engine.time_scale = 1.0
	get_tree().paused = false

func set_speed(value: float) -> void:
	speed = value
	paused = false
	_apply()

func set_paused(value: bool) -> void:
	paused = value
	_apply()

func toggle_pause() -> void:
	set_paused(not paused)

# 1× → 2× → 3× → 1×. Unpauses.
func cycle_speed() -> void:
	var index := speeds.find(speed)
	set_speed(speeds[(index + 1) % speeds.size()])

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		toggle_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cycle_speed"):
		cycle_speed()
		get_viewport().set_input_as_handled()

func _apply() -> void:
	Engine.time_scale = speed
	get_tree().paused = paused
	changed.emit(paused, speed)
