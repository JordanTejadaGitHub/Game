extends Node2D

# The Walking Wood (Legendary, owner 2026-10-21; D:\Projects\logs\dream_council\legendary_fifth.md 2.1, dream_council_review.md
# end of section 28): swap any two one-cell Wardens' places, free, even during a drift. Both cells are already walls, so the
# route, the path tiles, the maze economy and Restless never change: no path_changed, no probe. In a drift both wait
# SWAP_WAIT s before attacking and the next swap waits SWAP_COOLDOWN s; at a rest, as often as you like. Kinships start
# again. Started from the Warden panel ("Swap places"), then a click (or tap) on the other Warden; Esc / right-click cancels.
# Made by DreamState (like SunlitMark); untyped dream_state (DreamState preloads this script).

const SWAP_WAIT := 2.0  # Seconds both swapped Wardens wait before attacking (in a drift)
const SWAP_COOLDOWN := 10.0  # Seconds between swaps in a drift
const ROOT_LINE_TIME := 1.0  # The faint root line joining the two cells
const DIM := Color(0.6, 0.6, 0.6)  # multiplier: a swapped Warden while it waits

var dream_state: Node
var pending: Tower = null  # The Warden whose Swap button was pressed: the next click picks its partner
var _time := 0.0
var _next_swap := 0.0  # _time when a drift swap is allowed again
var _lines: Array = []  # [from (world), to (world), seconds left]

func _ready() -> void:
	z_index = 2  # Over the Wardens' sprites, under the lighting
	process_mode = Node.PROCESS_MODE_ALWAYS  # Like building: swapping works while paused
	add_to_group(&"walking_wood")

static func find(node: Node) -> Node:
	return node.get_tree().get_first_node_in_group(&"walking_wood") if node != null and node.is_inside_tree() else null

# A Warden that can walk: any Warden, Sprout or Thornwall the size of one cell; not the Heartwood Sapling or a twig wall.
static func eligible(tower) -> bool:
	return tower is Tower and is_instance_valid(tower) and not tower.is_queued_for_deletion() and tower.tower_data != null \
		and tower.get_footprint() <= 1 and not tower.twig and not tower.tower_data.rooted

func _resting() -> bool:
	var director = dream_state.drift_director if dream_state != null else null
	return director == null or director.is_build_phase()

# Seconds until the next drift swap (0 at a rest or when ready).
func cooldown_left() -> float:
	return 0.0 if _resting() else maxf(_next_swap - _time, 0.0)

# Why `a` can't swap with `b` ("" = it can).
func refusal(a, b) -> String:
	if not eligible(a) or not eligible(b):
		return "Only one-cell Wardens and walls can walk (not the Sapling or twig walls)"
	if a == b:
		return "Pick another Warden"
	if cooldown_left() > 0.0:
		return "The Walking Wood: again in %d s" % ceili(cooldown_left())
	return ""

func begin(tower: Tower) -> void:
	if not eligible(tower):
		return
	pending = tower
	queue_redraw()

func cancel() -> void:
	pending = null
	queue_redraw()

func _process(delta: float) -> void:
	if not get_tree().paused:
		_time += delta  # The drift cooldown counts game time, not a pause
	for line in _lines:
		line[2] = float(line[2]) - delta
	_lines = _lines.filter(func(line: Array) -> bool: return float(line[2]) > 0.0)
	if pending != null and not is_instance_valid(pending):
		pending = null
	if pending != null or not _lines.is_empty():
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:  # (Unhandled: a click on the HUD or panel is never taken)
	if pending == null:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			cancel()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var target := _tower_at(get_global_mouse_position())
			if target == null:
				return  # Not on a Warden: the click goes on (the HUD, the panel)
			get_viewport().set_input_as_handled()
			var why := refusal(pending, target)
			if why != "":
				_toast(why)
				return
			swap(pending, target)
			pending = null

func _tower_at(world: Vector2) -> Tower:
	var half := (world / (Tower.MAP_GRID.cell_size / 2.0)).floor()
	for tower in get_tree().get_nodes_in_group(Tower.GROUP):
		if tower is Tower and not tower.is_queued_for_deletion() and tower.get_halves().has(half):
			return tower
	return null

# Swaps `a` and `b` (checked by refusal). Every system that keeps a Warden by its cell follows: Hard-Won Rings and Wild
# Growth counts move with their Warden, Kinships start again, the class nodes (Firefly lights, Puddles water, mushrooms,
# bells) rebuild from the new positions on the board bump, card badges and auras from each Warden's cleared cache.
func swap(a: Tower, b: Tower) -> bool:
	if refusal(a, b) != "":
		return false
	var a_cell := a.cell
	var a_half := a.half_cell
	var a_pos := a.position
	var b_cell := b.cell
	a.cell = b.cell
	a.half_cell = b.half_cell
	a.position = b.position
	b.cell = a_cell
	b.half_cell = a_half
	b.position = a_pos
	if dream_state != null and dream_state.get("batch") != null:
		dream_state.batch.swap_counts(a_cell, b_cell)
	var kin = Kinships.find(a)
	if kin != null:
		kin.forget(a)
		kin.forget(b)
		kin.refresh()
	var spawner = dream_state.get_node_or_null("%EnemyContainer") if dream_state != null else null
	if spawner != null and "_towers_dirty" in spawner:
		spawner._towers_dirty = true  # Its cell -> Warden table (rebuilt on the next look)
	for tower in get_tree().get_nodes_in_group(Tower.GROUP):
		if tower is Tower and tower.has_method(&"_on_map_changed"):
			tower._on_map_changed()  # Ranges, auras, card rows and the trail mask read positions
	var map = dream_state.get("map_generator") if dream_state != null else null
	var lighting = map.get("lighting") if map != null else null
	if lighting != null and lighting.has_method(&"_update_glow"):
		lighting._update_glow(a)  # The Warden glow layer redraws only on plant, sell and grow otherwise
		lighting._update_glow(b)
	if dream_state != null:
		dream_state.bump_board()  # The board changed; the route didn't
		dream_state.note_card(&"walking_wood", a.global_position, 1, a)
	if not _resting():
		_next_swap = _time + SWAP_COOLDOWN
		for tower in [a, b]:
			tower._cooldown = maxf(tower._cooldown, SWAP_WAIT)  # Both wait before attacking
			var dim: Tween = tower.create_tween()
			tower.modulate = DIM
			dim.tween_interval(SWAP_WAIT)
			dim.tween_property(tower, "modulate", Color(1, 1, 1), 0.2)  # multiplier: back to plain
	_lines.append([a.global_position, b.global_position, ROOT_LINE_TIME])
	for at in [a.global_position, b.global_position]:
		Reactions._effect(&"landing_dust", at, self, 0.8)  # A swirl of leaves where each rises
	queue_redraw()
	return true

func _toast(text: String) -> void:
	var hud: Node = dream_state.owner.get_node_or_null("HUD") if dream_state != null and dream_state.owner != null else null
	if hud != null and hud.has_method("show_toast"):
		hud.show_toast(text)

func _draw() -> void:
	for line in _lines:  # A faint root line joins the two cells for a moment
		var fade: float = clampf(float(line[2]) / ROOT_LINE_TIME, 0.0, 1.0)
		draw_line(to_local(line[0]), to_local(line[1]), Color(Palette.NEWLEAF, 0.5 * fade), 2.0)
	if pending == null or not is_instance_valid(pending):
		return
	var cell := Tower.MAP_GRID.cell_size.x
	for tower in get_tree().get_nodes_in_group(Tower.GROUP):  # Who it can walk to
		if tower != pending and eligible(tower):
			draw_arc(to_local(tower.global_position), cell * 0.45, 0.0, TAU, 24, Color(Palette.NEWLEAF, 0.5), 2.0)
	draw_arc(to_local(pending.global_position), cell * 0.5, 0.0, TAU, 24, Palette.GOLD, 2.0)
	draw_line(to_local(pending.global_position), to_local(get_global_mouse_position()), Color(Palette.NEWLEAF, 0.6), 2.0)
