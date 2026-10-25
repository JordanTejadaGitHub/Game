extends CanvasLayer
class_name PerfOverlay

# Perf readout (story chat 2026-10-01, user: "pretty laggy"; Perf Booster 2026-10-25: "turn on from settings on phones, so I
# can report real numbers"): FPS, frame time, script time, draw calls, live effects, nightmares and whether effects stepped
# down (Fx.reduced), plus a 10 s summary and the device, so a player can report numbers. Made by TowerSeller in every build;
# shown by the Display setting "Performance readout" (SETTING), or F3 in debug builds. Refreshes 4 times a second.

const SETTING := "perf_readout"
const REFRESH := 0.25
const SUMMARY_SECONDS := 10.0  # The "last 10 s" line: average FPS and the slowest frame in that window

var _label := Label.new()
var _left := 0.0
var _frames := 0
var _worst_ms := 0.0
var _last_usec := 0
var _f3 := false  # Toggled by F3 (debug builds)
# The summary window: frames and real seconds so far, its slowest frame; the last finished window is what's shown
var _window_frames := 0
var _window_seconds := 0.0
var _window_worst := 0.0
var _summary := ""
var _device := ""

func _ready() -> void:
	layer = 120  # Above the HUD and every screen
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = _wanted()
	_label.position = Vector2(8, 8)
	_label.add_theme_color_override("font_color", UiStyle.INK)
	_label.add_theme_color_override("font_outline_color", Palette.DREAD)
	_label.add_theme_constant_override("outline_size", 4)
	_label.add_theme_font_size_override("font_size", 14)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_device = device_line()

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		_f3 = not _f3
		visible = _wanted()
		get_viewport().set_input_as_handled()

# Shown while the setting is on (any build) or F3 toggled it on (debug builds).
func _wanted() -> bool:
	return _f3 or bool(Fx.setting(SETTING, false))

func _process(delta: float) -> void:
	var now := Time.get_ticks_usec()
	var frame_ms := 0.0
	if _last_usec > 0:
		frame_ms = (now - _last_usec) / 1000.0
		_worst_ms = maxf(_worst_ms, frame_ms)
	_last_usec = now
	var real := delta / maxf(Engine.time_scale, 0.001)
	_left -= real
	if not visible:
		if _left <= 0.0:
			_left = REFRESH
			visible = _wanted()  # (The setting, 4 times a second: Fx.setting's cache)
		return
	_frames += 1
	_window_frames += 1
	_window_seconds += real
	_window_worst = maxf(_window_worst, frame_ms)
	if _window_seconds >= SUMMARY_SECONDS:
		_summary = "Last %d s: average %d FPS · slowest frame %.1f ms" % [int(SUMMARY_SECONDS),
			roundi(_window_frames / _window_seconds), _window_worst]
		_window_frames = 0
		_window_seconds = 0.0
		_window_worst = 0.0
	if _left > 0.0:
		return
	visible = _wanted()
	_label.text = text()
	_left = REFRESH
	_worst_ms = 0.0

# The overlay's lines (also for tests).
func text() -> String:
	var fps := Engine.get_frames_per_second()
	var nightmares := get_tree().get_nodes_in_group(&"enemies").size()
	var live_fx := 0
	var scene := get_parent()
	if scene != null:
		live_fx = scene.find_children("Fx_*", "", true, false).size()
	var lines: Array[String] = [
		"FPS %d · %.1f ms (worst %.1f)" % [fps, 1000.0 / maxf(fps, 1.0), _worst_ms],
		"Scripts %.1f ms · draw calls %d · objects %d" % [Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)],
		"Effects %d · nightmares %d · nodes %d" % [live_fx, nightmares, Performance.get_monitor(Performance.OBJECT_NODE_COUNT)],
		"Speed %s×%s" % [str(snappedf(Engine.time_scale, 0.01)), " · effects reduced" if Fx.reduced() else ""],
	]
	if _summary != "":
		lines.append(_summary)
	lines.append(_device)
	return "\n".join(lines)

# The device, for reports: the model (phones; "GenericDevice" on PCs is left out), the processor and the GPU.
static func device_line() -> String:
	var parts: Array[String] = []
	var model := OS.get_model_name()
	if model != "" and model != "GenericDevice":
		parts.append(model)
	var cpu := OS.get_processor_name()
	if cpu != "":
		parts.append(cpu)
	var gpu := RenderingServer.get_video_adapter_name()
	if gpu != "":
		parts.append(gpu)
	return " · ".join(parts)
