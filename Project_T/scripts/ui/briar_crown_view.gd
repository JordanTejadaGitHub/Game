extends Node2D
class_name BriarCrownView

# Quiet persistent empowerment marks; short strikes occur only when Briar attacks.
const REFRESH := 0.25
const STRIKE_TIME := 0.22
const MAX_STRIKES := 12
var dreams: DreamState
var seller: TowerSeller
var placer: TowerPlacer
var empowered: Array = []
var strikes: Array = []
var _clock := 0.0

func _ready() -> void:
	z_index = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	dreams = get_parent().get_node_or_null("%DreamState")
	seller = get_parent().get_node_or_null("%TowerSeller")
	placer = get_parent().get_node_or_null("%TowerPlacer")
	if dreams != null:
		dreams.wall_struck.connect(_strike)

func _strike(wall: Tower, _source: Tower, at: Vector2) -> void:
	if not Fx.on_screen(at):
		return
	var limit := 4 if Fx.reduced() else MAX_STRIKES
	if strikes.size() >= limit:
		return
	# A dense wall corridor can proc many times; one cue per wall at a time suffices.
	for strike: Dictionary in strikes:
		if strike.wall == wall.get_instance_id():
			return
	strikes.append({"from": wall.global_position, "to": at, "left": STRIKE_TIME, "wall": wall.get_instance_id()})
	queue_redraw()

func refresh() -> void:
	empowered.clear()
	if dreams == null or not dreams.has_rule(&"briar_crown"):
		return
	for wall in dreams._towers():
		if wall.tower_data.line != "wall" or not Fx.on_screen(wall.global_position):
			continue
		var source := dreams.briar_source(wall)
		if source != null:
			empowered.append({"wall": wall, "source": source})

func _process(delta: float) -> void:
	var had_strikes := not strikes.is_empty()
	if not get_tree().paused:
		for strike: Dictionary in strikes:
			strike.left -= delta
		strikes = strikes.filter(func(s: Dictionary) -> bool: return s.left > 0.0)
	_clock -= delta / maxf(Engine.time_scale, 0.001)
	if _clock <= 0.0:
		_clock = REFRESH
		refresh()
		queue_redraw()
	if had_strikes or not strikes.is_empty():
		queue_redraw()

func _draw() -> void:
	for entry: Dictionary in empowered:
		var wall: Tower = entry.wall
		var source: Tower = entry.source
		if not is_instance_valid(wall) or not is_instance_valid(source):
			continue
		var at := to_local(wall.global_position) + Vector2(0, -36)
		var crown := PackedVector2Array([at + Vector2(-6, 3), at + Vector2(-7, -3), at + Vector2(-3, 0), at + Vector2(0, -6), at + Vector2(3, 0), at + Vector2(7, -3), at + Vector2(6, 3)])
		draw_colored_polygon(crown, Color(Palette.SPRIG, 0.75))
		draw_polyline(crown + PackedVector2Array([crown[0]]), Color(Palette.GOLD, 0.7), 1.0, true)
		var inspect := wall.is_selected or source.is_selected
		if seller != null:
			inspect = inspect or seller._hover_tower == wall or seller._hover_tower == source
		if placer != null:
			inspect = inspect or placer.build_mode
		if inspect:
			draw_line(to_local(source.global_position), to_local(wall.global_position), Color(Palette.SPRIG, 0.45), 1.5, true)
	for strike: Dictionary in strikes:
		var start := to_local(strike.from)
		var end := to_local(strike.to)
		var alpha: float = float(strike.left) / STRIKE_TIME * (0.4 if Fx.reduce_flashes() else 0.7)
		var colour := Color(Palette.SPRIG, alpha)
		draw_line(start, end, colour, 2.0, true)
		var side := (end - start).normalized().orthogonal() * 4.0
		var middle := start.lerp(end, 0.7)
		draw_line(middle - side, end, colour, 1.5, true)
		draw_line(middle + side, end, colour, 1.5, true)
