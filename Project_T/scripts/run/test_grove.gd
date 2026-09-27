extends CanvasLayer
class_name TestGrove

# Test Grove (demo_scope.md): a developer playtest mode, never in release builds. A normal run with
# every Warden family in the bar from drift 1 (so the family picks have nothing left to offer),
# every branch / final form / hidden branch / Memory Warden growable without its Dream (Dew still
# applies), plus tools: F9 = +500 Dew, and "Skip to drift N" at a rest.
# On with the settings "Developer" toggle or the launch flag `-- --test-grove`; only in debug builds.

const SETTING := "test_grove"
const LAUNCH_FLAG := "--test-grove"
const DEW_GIFT := 500

# Tests (and the settings toggle, within one session) can switch it on without the saved setting.
static var force_on := false

@onready var dream_state: DreamState = %DreamState
@onready var drift_director: DriftDirector = %DriftDirector
@onready var run_state: RunState = %RunState

var _skip_to := SpinBox.new()

# Debug builds only: exported release/demo builds never show or allow it.
static func is_available() -> bool:
	return OS.is_debug_build()

static func is_active() -> bool:
	if not is_available():
		return false
	return force_on or OS.get_cmdline_user_args().has(LAUNCH_FLAG) \
		or bool(HeartwoodMemory.get_settings().get(SETTING, false))

func _ready() -> void:
	if not is_active():
		queue_free()
		return
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	dream_state.unlock_everything = true
	dream_state.unlocks_changed.emit()  # Tower bar shows every family
	_build_panel()

func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_F9:
		give_dew()
		get_viewport().set_input_as_handled()

func give_dew() -> void:
	run_state.add_dew(DEW_GIFT)

# Jumps ahead so the next Start begins drift `number`. Only at a rest (nothing on the field).
# Skipped drifts pay nothing and offer no Dreams; health scaling follows the new drift number.
func skip_to(number: int) -> bool:
	if not drift_director.is_resting() or drift_director.awaiting_family_pick:
		return false
	number = clampi(number, drift_director.drifts_started + 1, drift_director.get_total_drifts())
	drift_director.drifts_started = number - 1
	drift_director.drifts_cleared = number - 1
	return true

func _build_panel() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	panel.offset_left = 16
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "Test Grove (dev)"
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
	box.add_child(title)
	var dew := Button.new()
	dew.text = "+%d Dew  (F9)" % DEW_GIFT
	dew.focus_mode = Control.FOCUS_NONE
	dew.pressed.connect(give_dew)
	box.add_child(dew)
	var row := HBoxContainer.new()
	box.add_child(row)
	_skip_to.min_value = 1
	_skip_to.max_value = maxi(drift_director.get_total_drifts(), 1)
	_skip_to.value = 25
	row.add_child(_skip_to)
	var skip := Button.new()
	skip.text = "Skip to drift"
	skip.focus_mode = Control.FOCUS_NONE
	skip.tooltip_text = "At a rest: the next Start begins this drift."
	skip.pressed.connect(func() -> void: skip_to(int(_skip_to.value)))
	row.add_child(skip)
