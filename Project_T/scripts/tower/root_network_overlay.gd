extends Node2D
class_name RootNetworkOverlay

# Root Network (card, rule root_network): the glowing roots between touching Sprouts, drawn once per
# pair on one node per board. Each Sprout used to draw half a link in its own _draw, under its own
# sprite, so a vertical pair (y-sorted: the upper slab under the lower one) was hidden completely.
# Links run between the slab fronts (the ground-contact point at the bottom of each tile), so a
# vertical link shows as a root climbing between the slabs. z 1 over the Wardens' bodies, and first
# in the world's draw order so the rank pips (also z 1, drawn later) stay on top.

const SLAB_FRONT := Vector2(0, 24)  # From a Warden's position to the bottom middle of its tile

# The board's overlay, made on first use under the scene that holds `container` (the TowerContainer).
static func find(container: Node) -> RootNetworkOverlay:
	var world: Node = container.owner if container.owner else container.get_parent()
	if world == null:
		return null
	var overlay := world.get_node_or_null("RootNetworkOverlay") as RootNetworkOverlay
	if overlay == null:
		overlay = RootNetworkOverlay.new()
		overlay.name = "RootNetworkOverlay"
		overlay.z_index = 1
		world.add_child(overlay)
		world.move_child(overlay, 0)
	return overlay

# Each link once: [from, to] in world space, from every Sprout to the neighbours after it (a positive
# direction: right, down, down-right, down-left), between their slab fronts.
func get_segments() -> Array:
	var segments: Array = []
	for tower in get_tree().get_nodes_in_group(Tower.GROUP):
		if not (tower is Tower) or tower.is_queued_for_deletion():
			continue
		for d in tower._root_links:
			if d.y > 0.0 or (d.y == 0.0 and d.x > 0.0):
				var from: Vector2 = tower.global_position + SLAB_FRONT
				var to: Vector2 = from + d * Tower.MAP_GRID.cell_size
				segments.append([from, to])
	return segments

func _draw() -> void:
	for segment in get_segments():
		var from: Vector2 = to_local(segment[0])
		var to: Vector2 = to_local(segment[1])
		draw_line(from, to, Color(Tower.ROOT_GLOW, 0.25), 7.0)
		draw_line(from, to, Color(Tower.ROOT_GLOW, 0.8), 2.0)
