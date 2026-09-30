extends Node2D

# Placement links (screens_ui.md "Combat feedback"): while placing a Warden, a small vine links the
# build ghost to nearby Wardens it combos with, tagged with the combo ("Soaked → Stormcap"), and a
# green-gold one to the Warden it would form a Kinship with ("Forms Kinship: Slumber Rot",
# Kinships.preview). Reads the TowerPlacer's hover state; draws in the world, over the ghost.

const VINE := UiStyle.LIVE
const KIN_VINE := UiStyle.LIVE  # A Kinship: green-gold (a link's optional third element is its colour)

@onready var tower_placer: TowerPlacer = %TowerPlacer
@onready var tower_container: Node2D = %TowerContainer

var _links: Array = []  # [[Tower, description], …] for the hovered cell
var _cell := Vector2(-1, -1)
var _data: TowerData = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Placing works while paused
	z_index = 7

func _process(_delta: float) -> void:
	var cell: Vector2 = tower_placer._hover_cell
	var active := tower_placer.build_mode and tower_placer._hover_valid
	if not active:
		if not _links.is_empty():
			_links = []
			queue_redraw()
		_cell = Vector2(-1, -1)
		return
	if cell != _cell or tower_placer.tower_data != _data:
		_cell = cell
		_data = tower_placer.tower_data
		_links = Synergies.find_links(_data, _cell, tower_container.get_children())
		# Kinships (screens_ui.md "Kinship feedback"): the vine to its kin reads "Forms Kinship: …".
		var kin := get_tree().get_first_node_in_group(&"kinships")
		if kin != null and kin.has_method("preview"):
			var bond: Dictionary = kin.preview(_data, _cell)
			if not bond.is_empty() and is_instance_valid(bond.get("partner")):
				var kin_name: String = bond.get("name", "") if CodexData.is_discovered(bond.get("id", &"")) else "???"
				_links.append([bond.partner, "Forms Kinship: %s" % kin_name, KIN_VINE])  # "???" until discovered
		queue_redraw()

func _draw() -> void:
	if _links.is_empty():
		return
	var grid: Grid = tower_placer.MAP_GRID
	var from := grid.calculate_map_position(_cell)
	for link in _links:
		var tower: Tower = link[0]
		if not is_instance_valid(tower):
			continue
		var to := tower.position
		# A gently curved vine with a leaf in the middle.
		var mid := (from + to) / 2.0 + (to - from).orthogonal().normalized() * 12.0
		var points := PackedVector2Array()
		for i in 13:
			var t := i / 12.0
			points.append(from.lerp(mid, t).lerp(mid.lerp(to, t), t))
		var colour: Color = link[2] if link.size() > 2 else VINE
		draw_polyline(points, Color(colour, 0.8), 3.0, true)
		draw_circle(mid, 4.0, colour)
		WorldLabel.draw_tag(self, mid.x, mid.y - 8.0, link[1], colour)
