extends Node2D
class_name DreamTransfer

# Presentation only: call after an accepted Passing Dream / Hunter's Moon transfer.
const LIFE := 0.38
const MAX_LINKS := 10
const REDUCED_LINKS := 4
const NODE_NAME := "DreamTransferFeedback"
var links: Array[Dictionary] = []

static func play(world: Node, from: Vector2, to: Vector2, status: StringName, hunters := false) -> bool:
	if world == null or not is_instance_valid(world):
		return false
	# A segment crossing the viewport is visible even if both endpoints are outside it.
	if Fx.view_rect.size.x >= 256.0 and Fx.view_rect.size.y >= 256.0:
		var bounds := Rect2(from, Vector2.ZERO).expand(to).grow(8.0)
		if not Fx.view_rect.intersects(bounds):
			return false
	var feedback := world.get_node_or_null(NODE_NAME) as DreamTransfer
	if feedback == null:
		feedback = DreamTransfer.new()
		feedback.name = NODE_NAME
		feedback.top_level = true
		feedback.z_index = Fx.Z
		world.add_child(feedback)
	return feedback.add_transfer(from, to, status, hunters)

func add_transfer(from: Vector2, to: Vector2, status: StringName, hunters := false) -> bool:
	# Different statuses on one recipient coalesce; no burst of motes for one transfer operation.
	for link in links:
		if link.from.distance_squared_to(from) < 16.0 and link.to.distance_squared_to(to) < 16.0 and link.hunters == hunters:
			return false
	var limit := REDUCED_LINKS if Fx.reduced() else MAX_LINKS
	if links.size() >= limit:
		return false
	links.append({"from": from, "to": to, "left": LIFE, "hunters": hunters,
		"colour": status_colour(status), "still": bool(Fx.setting("reduced_motion", false)),
		"soft": Fx.reduce_flashes()})
	set_process(true)
	queue_redraw()
	return true

static func status_colour(status: StringName) -> Color:
	match status:
		EnemyStatuses.DAMP: return Palette.DEWLIGHT
		EnemyStatuses.HELD, EnemyStatuses.SPORED: return Palette.SPRIG
		EnemyStatuses.STATIC, EnemyStatuses.MARKED: return Palette.GOLD
		_: return Palette.MOONLIGHT

func _process(delta: float) -> void:
	for link in links:
		link.left -= delta
	links = links.filter(func(link: Dictionary) -> bool: return link.left > 0.0)
	queue_redraw()
	if links.is_empty():
		set_process(false)

func _draw() -> void:
	for link in links:
		var from := to_local(link.from)
		var to := to_local(link.to)
		var t: float = 1.0 - float(link.left) / LIFE
		var fade := minf(float(link.left) / 0.1, 1.0)
		var strength := (0.35 if link.soft else 0.55) * fade
		var colour: Color = Palette.MOONLIGHT if link.hunters else link.colour
		draw_line(from, to, Color(colour, strength * 0.35), 1.0)
		if link.still:
			draw_circle(from, 2.5, Color(colour, strength))
			draw_circle(to, 3.0, Color(link.colour, strength))
		else:
			var at := from.lerp(to, clampf(t / 0.75, 0.0, 1.0))
			draw_circle(at, 2.5, Color(colour, strength))
			if t > 0.7:
				draw_arc(to, 4.0, 0.0, TAU, 12, Color(link.colour, strength), 1.0)
