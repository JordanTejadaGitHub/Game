extends RefCounted
class_name AuraView

# Shows exactly who gets an aura (screens_ui.md "Support and economy feedback" → "Show exactly who gets
# the aura"): the aura's real shape (the cells whose centre is within its reach: a 3×3 square for Acorn
# and Elder Stump) as a soft leaf-green fill with a gold edge, and only the Wardens it really boosts, with
# a live "+5%" chip and their tile lit. Drawn by TowerSeller (a selected aura Warden, lines from a boosted
# one back to its boosters) and TowerPlacer (the build ghost). Separate from the thin attack circle.

const FILL := Color(0.56, 0.78, 0.4, 0.13)
const EDGE := Color(0.95, 0.8, 0.45, 0.8)
const LIT := Color(0.56, 0.78, 0.4, 0.3)
const CHIP := Color(0.72, 0.9, 0.52)
const LINK := Color(0.72, 0.9, 0.52, 0.55)
const MAP_GRID: Grid = preload("res://resource/map/map_grid.tres")

static func is_aura(data: TowerData) -> bool:
	return data != null and (data.aura_damage_bonus > 0.0 or data.aura_speed_bonus > 0.0)

# The grid cells an aura of `reach` cells around `centre` (world position) covers, as Tower's aura check
# does (centre to centre).
static func cells(centre: Vector2, reach: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var at := MAP_GRID.calculate_grid_coordinates(centre)
	var span := ceili(reach)
	for dx in range(-span, span + 1):
		for dy in range(-span, span + 1):
			var cell := at + Vector2(dx, dy)
			if MAP_GRID.is_within_bounds(cell) \
					and MAP_GRID.calculate_map_position(cell).distance_to(centre) / MAP_GRID.cell_size.x <= reach + 0.001:
				result.append(cell)
	return result

# The soft shape: every covered cell filled, a gold line where the region ends.
static func draw_shape(canvas: CanvasItem, covered: Array[Vector2]) -> void:
	var half := MAP_GRID.cell_size / 2.0
	for cell in covered:
		var c := (canvas as Node2D).to_local(MAP_GRID.calculate_map_position(cell))
		canvas.draw_rect(Rect2(c - half, MAP_GRID.cell_size), FILL)
		for side in [[Vector2.LEFT, Vector2(-1, -1), Vector2(-1, 1)], [Vector2.RIGHT, Vector2(1, -1), Vector2(1, 1)],
				[Vector2.UP, Vector2(-1, -1), Vector2(1, -1)], [Vector2.DOWN, Vector2(-1, 1), Vector2(1, 1)]]:
			if not covered.has(cell + side[0]):
				canvas.draw_line(c + half * side[1], c + half * side[2], EDGE, 2.0)

# The Wardens `aura` really boosts right now (auras don't stack: each Warden takes its strongest).
static func boosted_by(aura: Tower) -> Array[Tower]:
	var result: Array[Tower] = []
	for other in aura.get_parent().get_children():
		if other is Tower and other != aura and (other._aura_damage_from == aura or other._aura_speed_from == aura):
			result.append(other)
	return result

# "+5%", "+20% speed" or "+15% · +15% speed": what `tower` gets from `aura`.
static func chip(tower: Tower, aura: Tower) -> String:
	var parts: Array[String] = []
	if tower._aura_damage_from == aura and tower._aura_damage > 0.0:
		parts.append("+%d%%" % roundi(tower._aura_damage * 100.0))
	if tower._aura_speed_from == aura and tower._aura_speed > 0.0:
		parts.append("+%d%% speed" % roundi(tower._aura_speed * 100.0))
	return " · ".join(parts)

# A selected aura Warden: its shape, then each Warden it boosts lit with its chip.
static func draw_selected(canvas: CanvasItem, aura: Tower) -> void:
	draw_shape(canvas, cells(aura.global_position, aura.get_aura_reach()))
	for tower in boosted_by(aura):
		_draw_boosted(canvas, tower.global_position, chip(tower, aura))

# A selected Warden that's boosted: thin lines back to its booster(s).
static func draw_links(canvas: CanvasItem, tower: Tower) -> void:
	var from := (canvas as Node2D).to_local(tower.global_position)
	var boosters := {}
	for aura in [tower._aura_damage_from, tower._aura_speed_from]:
		if is_instance_valid(aura) and not boosters.has(aura):
			boosters[aura] = true
			var to := (canvas as Node2D).to_local(aura.global_position)
			canvas.draw_line(from, to, LINK, 1.5)
			canvas.draw_circle(to, 3.0, LINK)

# The build ghost of an aura Warden at `centre`: its shape, and the Wardens it would boost (where its
# bonus beats what they have now) with the chip they'd get.
static func draw_ghost(canvas: CanvasItem, data: TowerData, centre: Vector2, towers: Array) -> void:
	var reach := data.aura_radius if data.aura_radius > 0.0 else data.attack_range
	draw_shape(canvas, cells(centre, reach))
	for tower in towers:
		if not (tower is Tower) or tower.global_position.distance_to(centre) / MAP_GRID.cell_size.x > reach + 0.001:
			continue
		var parts: Array[String] = []
		if data.aura_damage_bonus > tower._aura_damage:
			parts.append("+%d%%" % roundi(data.aura_damage_bonus * 100.0))
		if data.aura_speed_bonus > tower._aura_speed:
			parts.append("+%d%% speed" % roundi(data.aura_speed_bonus * 100.0))
		if not parts.is_empty():
			_draw_boosted(canvas, tower.global_position, " · ".join(parts))

static func _draw_boosted(canvas: CanvasItem, world: Vector2, text: String) -> void:
	var c := (canvas as Node2D).to_local(world)
	canvas.draw_rect(Rect2(c - MAP_GRID.cell_size / 2.0, MAP_GRID.cell_size).grow(-3), LIT)
	if text != "":
		WorldLabel.draw_tag(canvas, c.x, c.y - MAP_GRID.cell_size.y / 2.0 - 6.0, text, CHIP)
