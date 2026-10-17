extends Node2D
class_name ReactionCloud

# Mushrooming's spore cloud: sits on one path tile; every nightmare inside takes Reactions.MUSHROOM_ZONE_BONUS more
# effect damage (owner 2026-10-17, council reactions_unique.md: a zone; it no longer adds Poisoned). It marks them
# (EnemyStatuses.mushroom_time, Reactions.effect_multiplier reads it) every TICK, flyers too (a cloud). Nightmares it
# touches in its first second count toward the chain that grew it. Script-only node; the looping ground effect comes
# from Fx.
# (council rx review 2026-10-17) The cloud carries its own Brimming payoff (EnemyStatuses.mushroom_payoff, written beside
# mushroom_time), can cover a second spot (the next path cell: add_spot), and draws a violet glow under every nightmare
# it is boosting, so the zone shows that it works.

const TICK := 0.1

var _radius: float
var _duration: float
var _potency: float
var _line: String
var _source: Node
var _chain: int
var _payoff := 1.0
var _age := 0.0
var _tick := 0.0
var _effect: Node2D = null
var _spots: Array[Vector2] = [Vector2.ZERO]  # Local centres: its own cell, and the next path cell (add_spot)
var _inside: Array[Vector2] = []  # Local feet of the nightmares it boosted at the last mark (the tint cue)

func _init(at: Vector2, radius: float, duration: float, potency: float, line: String, source: Node, chain: int,
		payoff: float = 1.0) -> void:
	position = at
	_radius = radius
	_duration = ShapeCards.ground_time(duration)  # Lingering Ground: x1.5
	_potency = potency
	_line = line
	_source = source
	_chain = chain
	_payoff = payoff
	z_index = -1  # Under the nightmares

# A second centre (world position), e.g. the next path cell ahead: the zone covers both.
func add_spot(world_at: Vector2) -> void:
	var local := world_at - position
	if not _spots.has(local):
		_spots.append(local)
	if is_inside_tree():
		Reactions._effect(&"overgrowth_cloud", world_at, self, 1.0, maxf(_duration - _age, 0.1))

func _ready() -> void:
	_effect = Reactions._effect(&"overgrowth_cloud", global_position, self, 1.0, _duration)
	for i in range(1, _spots.size()):
		Reactions._effect(&"overgrowth_cloud", global_position + _spots[i], self, 1.0, _duration)
	_mark()

func _process(delta: float) -> void:
	_age += delta
	if _age >= _duration:
		queue_free()  # The ground loop was given the same lifetime and fades itself
		return
	_tick += delta
	if _tick >= TICK:
		_tick = 0.0
		_mark()

func _mark() -> void:
	var source: Node = _source if is_instance_valid(_source) else null
	var had := not _inside.is_empty()
	_inside.clear()
	var marked := {}
	for spot in _spots:
		var centre := global_position + spot
		for enemy in Tower.nightmares_near(get_tree(), centre, _radius):  # The shared buckets, not all nightmares
			if not is_instance_valid(enemy) or enemy.is_cleansed or marked.has(enemy) or enemy.global_position.distance_to(centre) > _radius:
				continue
			marked[enemy] = true
			if _age < Reactions.CHAIN_WINDOW:
				enemy.statuses.mark_chain(_chain, [source] if source else [], Reactions.CHAIN_WINDOW)
			var s: EnemyStatuses = enemy.statuses
			s.mushroom_payoff = _payoff if s.mushroom_time <= 0.0 else maxf(s.mushroom_payoff, _payoff)
			s.mushroom_time = maxf(s.mushroom_time, Reactions.MUSHROOM_ZONE_HOLD)
			_inside.append(enemy.global_position - global_position)
	if had or not _inside.is_empty() or _effect == null:
		queue_redraw()

func _draw() -> void:
	var fade := minf(1.0, (_duration - _age) / 0.5)
	if _effect == null:  # Without the effects player: a soft violet puff so the cloud is still visible
		for spot in _spots:
			draw_circle(spot, _radius, Color(Palette.ORCHID, 0.18 * fade))
			draw_arc(spot, _radius, 0.0, TAU, 20, Color(Palette.BLOSSOM, 0.4 * fade), 2.0)
	for feet in _inside:  # The zone's cue: a violet glow under each nightmare it boosts
		draw_circle(feet + Vector2(0, 10), 14.0, Color(Palette.ORCHID, 0.35 * fade))
		draw_arc(feet + Vector2(0, 10), 14.0, 0.0, TAU, 16, Color(Palette.BLOSSOM, 0.6 * fade), 1.5)
