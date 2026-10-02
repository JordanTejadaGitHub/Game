extends Control
class_name ChoiceArm

# The arm delay of a choice screen (user: "sometimes I click on cards when waves end because I'm trying to place
# towers"): for ARM_TIME after the screen appears, a clear shield over it takes every mouse press, so nothing on the
# screen can be picked; a press that began then (or before the screen opened) never picks either, since its release
# goes to the shield that took the press. Meanwhile the cards fade in (`fade_target`), and a short brighten says
# they're ready. Under reduced motion the delay stays but nothing animates. A click on the map in the frame before
# the screen opens is the map's: placement acts on the press, and the screen is built after it (deferred).
# Keys: screens ask `is_armed()` before acting on a key (Esc = Clear Skies…).
#   var arm := ChoiceArm.attach(self, _cards)   # in _ready, after the screen's other children
#   arm.arm()                                   # each time the screen shows new choices

const ARM_TIME := 0.6  # Real seconds (time scale and pause don't change it)
const START_ALPHA := 0.25  # The cards' alpha as the screen appears
const READY_TIME := 0.25  # The "ready" brighten
const READY_LIFT := 0.14  # How much brighter at its peak (a multiplier on the cards)

signal armed_now

var fade_target: CanvasItem = null
var _left := 0.0
var _ready_left := 0.0

# A shield over `screen` (the last child, so on top), fading `fade_target` in on each arm().
static func attach(screen: Control, target: CanvasItem = null) -> ChoiceArm:
	var arm := ChoiceArm.new()
	arm.name = "ArmShield"
	arm.fade_target = target
	screen.add_child(arm)
	return arm

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP  # Takes the presses while arming
	process_mode = Node.PROCESS_MODE_ALWAYS  # Choice screens pause the game
	visible = false
	set_process(false)

# Starts (or restarts) the delay: call when the screen shows choices.
func arm() -> void:
	_left = ARM_TIME
	_ready_left = 0.0
	visible = true
	get_parent().move_child(self, -1)  # Over anything added since
	_set_look(START_ALPHA if not _still() else 1.0, 1.0)
	set_process(true)

func is_armed() -> bool:
	return _left <= 0.0

func _process(delta: float) -> void:
	var real := delta / Engine.time_scale if Engine.time_scale > 0.0 else delta  # The camera's real-time trick
	if _left > 0.0:
		_left -= real
		if _left > 0.0:
			if not _still():
				var t := 1.0 - _left / ARM_TIME
				_set_look(lerpf(START_ALPHA, 1.0, 1.0 - pow(1.0 - t, 3.0)), 1.0)
			return
		_left = 0.0
		visible = false  # Presses reach the cards again
		_ready_left = READY_TIME if not _still() else 0.0
		_set_look(1.0, 1.0)
		armed_now.emit()
	if _ready_left > 0.0:
		_ready_left -= real
		var k := clampf(_ready_left / READY_TIME, 0.0, 1.0)
		_set_look(1.0, 1.0 + READY_LIFT * sin(k * PI))
		return
	_set_look(1.0, 1.0)
	set_process(false)

func _set_look(alpha: float, lift: float) -> void:
	if fade_target != null and is_instance_valid(fade_target):
		fade_target.modulate = Color(lift, lift, lift, alpha)  # multiplier: the fade in and the ready brighten

static func _still() -> bool:
	return bool(Fx.setting("reduced_motion", false))
