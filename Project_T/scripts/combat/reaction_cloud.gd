extends Node2D
class_name ReactionCloud

# Mushrooming's spore cloud: sits on one path tile and gives every nightmare inside 1 Spored stack
# per second (credited to the Warden whose spores grew it). Nightmares it touches in its first second
# count toward the chain that grew it. Script-only node; the looping ground effect comes from Fx.

const TICK := 1.0

var _radius: float
var _duration: float
var _potency: float
var _line: String
var _source: Node
var _chain: int
var _age := 0.0
var _tick := 0.0
var _effect: Node2D = null

func _init(at: Vector2, radius: float, duration: float, potency: float, line: String, source: Node, chain: int) -> void:
	position = at
	_radius = radius
	_duration = duration
	_potency = potency
	_line = line
	_source = source
	_chain = chain
	z_index = -1  # Under the nightmares

func _ready() -> void:
	_effect = Reactions._effect(&"overgrowth_cloud", global_position, self, 1.0, _duration)
	_spread()

func _process(delta: float) -> void:
	_age += delta
	if _age >= _duration:
		queue_free()  # The ground loop was given the same lifetime and fades itself
		return
	_tick += delta
	while _tick >= TICK:
		_tick -= TICK
		_spread()
	if _effect == null:
		queue_redraw()

func _spread() -> void:
	var source: Node = _source if is_instance_valid(_source) else null
	for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
		if enemy.global_position.distance_to(global_position) > _radius:
			continue
		if _age < Reactions.CHAIN_WINDOW:
			enemy.statuses.mark_chain(_chain, [source] if source else [], Reactions.CHAIN_WINDOW)
		enemy.apply_status(EnemyStatuses.SPORED, 1, 0.0, _potency, 0, _line, source)

# Without the effects player: a soft violet puff so the cloud is still visible.
func _draw() -> void:
	if _effect != null:
		return
	var fade := minf(1.0, (_duration - _age) / 0.5)
	draw_circle(Vector2.ZERO, _radius, Color(0.75, 0.5, 1.0, 0.18 * fade))
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 20, Color(0.8, 0.6, 1.0, 0.4 * fade), 2.0)
