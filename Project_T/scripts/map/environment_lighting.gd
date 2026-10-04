class_name EnvironmentLighting
extends Node2D

# The lighting pass over the unlit night tiles (art_direction.md, "Warm centre, cold edge"): a cold
# multiply that deepens toward the map's edges, and a small warm glow on every attacking Warden, added
# over the multiply so their light pushes back the dark (the Heartwood carries its own, heartwood.gd).

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const VIGNETTE_Z := 3  # Over the map, Wardens and creatures; under attack effects (4-5) and popups (10)
const GLOW_Z := 4  # Additive glows (Wardens', the Heartwood's) go over the cold multiply
const MARGIN_CELLS := 12  # The multiply also covers the forest outside the wall
const SQRT2 := 1.41421356

# Multiply colours from the map's centre (0) to its corners (1); edge midpoints sit at ~0.71.
@export var edge_offsets := PackedFloat32Array([0.0, 0.32, 0.6, 1.0])
@export var edge_colors := PackedColorArray([Color("#fff2d8"), Color("#e6e0ee"), Color("#a8a6cc"), Color("#50507e")])
@export var warden_glow_color := Color(1.0, 0.85, 0.59)
@export var warden_glow_alpha := 0.22
@export var warden_glow_radius := 80.0  # px

# Weak (exit crash hunt, like Fx bb5076e2): a static Texture2D outliving the scene can crash on quit.
# Users hold their own reference: lights keep their texture, this node keeps `_disc` for its glows.
static var _light_texture: WeakRef
var _disc: Texture2D

var tower_container: Node  # Set before adding; every Warden added to it glows
var _wardens: Dictionary = {}  # {Tower: glows (bool)}
var _glow: Node2D  # Draws every Warden glow (additive, over the multiply)

func _ready() -> void:
	z_index = VIGNETTE_Z
	_disc = light_texture()  # Held for the glows: draw commands don't keep it alive
	add_child(_make_vignette())
	_glow = Node2D.new()
	_glow.name = "WardenGlow"
	_glow.z_index = GLOW_Z - VIGNETTE_Z  # Relative: lands on GLOW_Z
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = additive
	_glow.draw.connect(_draw_glows)
	add_child(_glow)
	if tower_container != null:
		tower_container.child_entered_tree.connect(_on_tower_added)
		for tower in tower_container.get_children():
			_on_tower_added(tower)

# A soft white disc that fades out at its rim: the shape of every warm light.
static func light_texture() -> Texture2D:
	var held: Texture2D = _light_texture.get_ref() if _light_texture != null else null
	if held == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 1))
		gradient.set_color(1, Color(1, 1, 1, 0))
		gradient.add_point(0.4, Color(1, 1, 1, 0.55))
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.width = 256
		texture.height = 256
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(1.0, 0.5)
		_light_texture = weakref(texture)
		held = texture
	return held

# A warm PointLight2D of `radius` px.
static func make_light(color: Color, energy: float, radius: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = light_texture()
	light.texture_scale = radius / (light.texture.get_width() / 2.0)
	light.color = color
	light.energy = energy
	return light

func _make_vignette() -> Sprite2D:
	var map_size: Vector2 = MAP_GRID.size * MAP_GRID.cell_size
	var cover := map_size + Vector2.ONE * MARGIN_CELLS * 2 * MAP_GRID.cell_size.x
	# Keep the map's share of the sprite equal on both axes, so its corners sit on one gradient ring.
	var share := minf(map_size.x / cover.x, map_size.y / cover.y)
	cover = map_size / share
	var gradient := Gradient.new()
	gradient.offsets = edge_offsets
	gradient.colors = edge_colors
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5 + 0.5 * share * SQRT2, 0.5)  # Gradient 1.0 at the map's corners
	var vignette := Sprite2D.new()
	vignette.texture = texture
	vignette.position = map_size / 2.0
	vignette.scale = cover / 256.0
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	vignette.material = material
	return vignette

func _on_tower_added(node: Node) -> void:
	if not node is Tower or _wardens.has(node):
		return
	node.evolved.connect(_update_glow)
	node.tree_exiting.connect(func() -> void:
		_wardens.erase(node)
		_glow.queue_redraw())
	_update_glow(node)

# Wardens that attack glow; walls (Thornwall) stay dark. Re-checked when a Warden grows.
func _update_glow(tower: Tower) -> void:
	_wardens[tower] = tower.tower_data == null or tower.tower_data.can_attack
	_glow.queue_redraw()

# One additive disc per glowing Warden, all on one canvas item: a board full of Wardens costs one
# batch instead of a PointLight2D pass each (platforms.md performance budget: ~200 Wardens).
# Wardens don't move, so it only redraws when one is planted, sold or grows.
func _draw_glows() -> void:
	var texture := _disc
	var size := Vector2.ONE * warden_glow_radius * 2.0
	var color := Color(warden_glow_color, warden_glow_alpha)
	for tower: Tower in _wardens:
		if _wardens[tower] and is_instance_valid(tower):
			var at := _glow.to_local(tower.global_position) + Vector2(0, -2)
			_glow.draw_texture_rect(texture, Rect2(at - size / 2.0, size), false, color)

func get_glowing_warden_count() -> int:
	return _wardens.values().count(true)
