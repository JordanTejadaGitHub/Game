extends CanvasLayer
class_name PerfOverlay

# Dev perf overlay (story chat 2026-10-01, user: "pretty laggy"): F3 in debug builds shows FPS, frame time,
# draw calls, live effects, nightmares and whether effects stepped down (Fx.reduced), so a player can
# report numbers. Made by TowerSeller in debug builds; hidden until F3. Refreshes 4 times a second.

const REFRESH := 0.25

var _label := Label.new()
var _left := 0.0
var _frames := 0
var _worst_ms := 0.0
var _last_usec := 0

func _ready() -> void:
	layer = 120  # Above the HUD and every screen
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_label.position = Vector2(8, 8)
	_label.add_theme_color_override("font_color", UiStyle.INK)
	_label.add_theme_color_override("font_outline_color", Palette.DREAD)
	_label.add_theme_constant_override("outline_size", 4)
	_label.add_theme_font_size_override("font_size", 14)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		visible = not visible
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	var now := Time.get_ticks_usec()
	if _last_usec > 0:
		_worst_ms = maxf(_worst_ms, (now - _last_usec) / 1000.0)
	_last_usec = now
	if not visible:
		return
	_frames += 1
	_left -= delta / maxf(Engine.time_scale, 0.001)
	if _left > 0.0:
		return
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
		"Draw calls %d · objects %d" % [Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)],
		"Effects %d · nightmares %d · nodes %d" % [live_fx, nightmares, Performance.get_monitor(Performance.OBJECT_NODE_COUNT)],
		"Speed %s×%s" % [str(snappedf(Engine.time_scale, 0.01)), " · effects reduced" if Fx.reduced() else ""],
	]
	return "\n".join(lines)
