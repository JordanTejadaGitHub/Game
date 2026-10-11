extends Node2D
# Transient world-owned state for family and universal combat patterns.
const GROUP := &"dream_build_rules"
const PRIMARY := &"dream_build_primary"
const PUDDLE := &"dream_build_puddle"
var stones := {}
var beats := {}
var crossfire := {}
var echoes: Array[Dictionary] = []
var clock := 0.0
const BURST := preload("res://scripts/fx/dream_burst.gd")
var prune_time := 0.0

func _process(delta: float) -> void:
	clock += delta
	for index in range(echoes.size() - 1, -1, -1):
		var echo: Dictionary = echoes[index]
		if clock < echo.at:
			continue
		echoes.remove_at(index)
		var target = echo.target.get_ref()
		var source = echo.source.get_ref()
		if living(target) and is_instance_valid(source) and not source.is_queued_for_deletion():
			target.take_damage(echo.damage, source.tower_data.line, false, false, source, &"fifth_beat")
			cue(target.global_position, Palette.MOONPATH)
	prune_time -= delta
	if prune_time <= 0.0:
		prune_time = 1.0
		for key in beats.keys():
			if not is_instance_valid(beats[key].source.get_ref()) or not living(beats[key].target.get_ref()):
				beats.erase(key)
		for key in crossfire.keys():
			if not living(crossfire[key].target.get_ref()) or clock > maxf(crossfire[key].until, crossfire[key].at + 1.0):
				crossfire.erase(key)
		for key in stones.keys():
			if not living(stones[key].target.get_ref()) or not is_instance_valid(stones[key].source.get_ref()):
				stones.erase(key)

static func find(near: Node) -> Node:
	var existing := near.get_tree().get_first_node_in_group(GROUP)
	if existing != null:
		return existing
	var world := Reactions._world(near)
	if world == null:
		return null
	var rules := new()
	world.add_child(rules)
	rules.add_to_group(GROUP)
	return rules

static func living(enemy) -> bool:
	return is_instance_valid(enemy) and not enemy.is_cleansed and enemy.health > 0

static func primary(tower):
	var ref = tower.get_meta(PRIMARY) if tower.has_meta(PRIMARY) else null
	return ref.get_ref() if ref is WeakRef else null

func note_primary(tower, target: Node2D) -> void:
	if not living(target):
		return
	var previous = primary(tower)
	if previous != target:
		beats.erase(tower.get_instance_id())
	if previous != target and living(previous) and tower._dream_state != null and tower._dream_state.has_card("blessing_sporeling") and tower.tower_data.line == "spore":
		if previous.statuses.transfer_spores_to(target.statuses, 3) > 0:
			cue(target.global_position, Palette.SPRIG)
	tower.set_meta(PRIMARY, weakref(target))

func direct_damage(tower, enemy, damage: float, is_primary: bool, actual_damage: float = -1.0) -> void:
	if damage <= 0.0:
		return
	if is_primary:
		pattern_hit(tower, enemy, damage if actual_damage < 0.0 else actual_damage)
	var key: int = enemy.get_instance_id()
	var entry: Dictionary = stones.get(key, {})
	var source = entry.source.get_ref() if not entry.is_empty() else null
	if not entry.is_empty() and not is_instance_valid(source):
		stones.erase(key)
	if not entry.is_empty() and is_instance_valid(source) and tower.tower_data.line != "stone":
		var saved: float = entry.damage
		stones.erase(key)
		var follower = null
		var distance := INF
		var ahead: float = enemy.get_remaining_distance()
		for other in get_tree().get_nodes_in_group("enemies"):
			if other == enemy or not living(other) or other.is_flying():
				continue
			var behind: float = other.get_remaining_distance() - ahead
			if behind > 0.0 and behind < distance:
				distance = behind
				follower = other
		if follower != null:
			follower.take_damage(saved * 0.75, "stone", false, false, source, &"stone_relay")
			cue(follower.global_position, Palette.MOONPATH)
	if is_primary and living(enemy) and tower.tower_data.line == "stone" and tower._dream_state != null and tower._dream_state.has_card("blessing_pebbling"):
		stones[key] = {"target": weakref(enemy), "source": weakref(tower), "damage": damage}
		cue(enemy.global_position, Palette.MOONPATH)


# Saved payloads bypass Tower.hit: no copied statuses, crit rolls, reactions, or hit recursion.
# Recipient defenses still apply, matching Stone Relay; Potency is not applied twice.
func pattern_hit(tower, enemy, damage: float) -> void:
	if damage <= 0.0 or tower._dream_state == null:
		return
	if tower._has_rule(&"rhythm"):
		var id: int = tower.get_instance_id()
		var beat: Dictionary = beats.get(id, {})
		var count: int = int(beat.count) + 1 if not beat.is_empty() and beat.target.get_ref() == enemy else 1
		beats[id] = {"source": weakref(tower), "target": weakref(enemy), "count": count % 5}
		if count == 5:
			echoes.append({"source": weakref(tower), "target": weakref(enemy), "damage": damage, "at": clock + 0.25})
	if not tower._has_rule(&"crossfire"):
		return
	var key: int = enemy.get_instance_id()
	var entry: Dictionary = crossfire.get(key, {})
	if not entry.is_empty() and clock < entry.until:
		return
	var first = entry.source.get_ref() if not entry.is_empty() else null
	if is_instance_valid(first) and not first.is_queued_for_deletion() and first != tower and clock - entry.at <= 1.0:
		# A rendezvous is spent even if the route has no eligible follower.
		crossfire[key] = {"target": weakref(enemy), "source": weakref(tower), "damage": damage, "at": clock, "until": clock + 3.0}
		var follower = null
		var nearest := INF
		var ahead: float = enemy.get_remaining_distance()
		for other in get_tree().get_nodes_in_group("enemies"):
			if other == enemy or not living(other) or other.is_flying():
				continue
			var behind: float = other.get_remaining_distance() - ahead
			if behind > 0.0 and behind <= tower.MAP_GRID.cell_size.x * 2.0 and behind < nearest:
				nearest = behind
				follower = other
		if follower != null:
			follower.take_damage(minf(damage, entry.damage) * 0.40, tower.tower_data.line, false, false, tower, &"crossfire")
			cue(follower.global_position, Palette.MOONPATH)
	else:
		crossfire[key] = {"target": weakref(enemy), "source": weakref(tower), "damage": damage, "at": clock, "until": 0.0}

func store_rain(tower, target, damage: float, radius: float) -> bool:
	if not living(target) or damage <= 0.0 or tower.tower_data.line != "water" or tower._dream_state == null or not tower._dream_state.has_card("blessing_dewdrop") or not target.statuses.has(EnemyStatuses.DAMP):
		return false
	target.statuses.remove(EnemyStatuses.DAMP)
	var previous = tower.get_meta(PUDDLE) if tower.has_meta(PUDDLE) else null
	if previous is WeakRef and is_instance_valid(previous.get_ref()):
		previous.get_ref().set_process(false)
		previous.get_ref().queue_free()
	var puddle := RainPuddle.new()
	puddle.position = target.global_position
	puddle.source = weakref(tower)
	puddle.excluded = target.get_instance_id()
	puddle.damage = damage * 2.0
	puddle.radius = maxf(radius, 24.0)
	get_parent().add_child(puddle)
	tower.set_meta(PUDDLE, weakref(puddle))
	return true

func reset() -> void:
	stones.clear()
	beats.clear()
	crossfire.clear()
	echoes.clear()
	clock = 0.0
	for child in get_parent().get_children():
		if child is RainPuddle:
			child.queue_free()

func cue(at: Vector2, _colour: Color) -> void:
	BURST.play(&"overlap", at, 18.0, get_parent())

class RainPuddle extends Node2D:
	var source: WeakRef
	var excluded := 0
	var damage := 0.0
	var radius := 24.0
	var age := 0.0
	var inside := {}
	func _ready() -> void:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.global_position.distance_to(global_position) <= radius:
				inside[enemy.get_instance_id()] = true
		queue_redraw()
	func _process(delta: float) -> void:
		age += delta
		var tower = source.get_ref()
		if age >= 4.0 or not is_instance_valid(tower):
			queue_free()
			return
		for enemy in get_tree().get_nodes_in_group("enemies"):
			var id: int = enemy.get_instance_id()
			var here: bool = enemy.global_position.distance_to(global_position) <= radius
			if here and not inside.has(id) and id != excluded and not enemy.is_flying() and not enemy.is_cleansed and enemy.health > 0:
				enemy.take_damage(damage, "water", false, false, tower, &"stored_rain")
				queue_free()
				return
			if here:
				inside[id] = true
			else:
				inside.erase(id)
	func _draw() -> void:
		draw_circle(Vector2.ZERO, radius, Color(Palette.DEW, 0.22))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(Palette.DEWLIGHT, 0.65), 2.0)
