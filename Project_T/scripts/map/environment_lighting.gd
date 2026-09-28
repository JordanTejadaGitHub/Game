class_name EnvironmentLighting
extends Node2D

# The lighting pass over the unlit night tiles (art_direction.md, "Warm centre, cold edge"): a cold
# multiply that deepens toward the map's edges, and a small warm light on every Warden (the
# Heartwood carries its own, see heartwood.gd). Lights are additive PointLight2Ds, so they also lift
# the cold multiply around them: the Wardens' light pushes back the dark.

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const VIGNETTE_Z := 3  # Over the map, Wardens and creatures; under attack effects (4-5) and popups (10)
const GLOW_Z := 4  # Additive glows (the Heartwood's) go over the cold multiply
const MARGIN_CELLS := 12  # The multiply also covers the forest outside the wall
const SQRT2 := 1.41421356

# Multiply colours from the map's centre (0) to its corners (1); edge midpoints sit at ~0.71.
@export var edge_offsets := PackedFloat32Array([0.0, 0.32, 0.6, 1.0])
@export var edge_colors := PackedColorArray([Color("#fff2d8"), Color("#e6e0ee"), Color("#a8a6cc"), Color("#50507e")])
@export var warden_light_color := Color(1.0, 0.85, 0.59)
@export var warden_light_energy := 0.35
@export var warden_light_radius := 80.0  # px

static var _light_texture: Texture2D

var tower_container: Node  # Set before adding; every Warden added to it gets a light
var _warden_lights: Dictionary = {}  # {Tower: PointLight2D or null}

func _ready() -> void:
	z_index = VIGNETTE_Z
	add_child(_make_vignette())
	if tower_container != null:
		tower_container.child_entered_tree.connect(_on_tower_added)
		for tower in tower_container.get_children():
			_on_tower_added(tower)

# A soft white disc that fades out at its rim: the shape of every warm light.
static func light_texture() -> Texture2D:
	if _light_texture == null:
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
		_light_texture = texture
	return _light_texture

# A warm PointLight2D of `radius` px.
static func make_light(color: Color, energy: float, radius: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = light_texture()
	light.texture_scale = radius / (light_texture().get_width() / 2.0)
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
	if not node is Tower or _warden_lights.has(node):
		return
	_warden_lights[node] = null
	node.evolved.connect(_update_light)
	node.tree_exiting.connect(func() -> void:
		var light: PointLight2D = _warden_lights.get(node)
		if light != null:
			light.queue_free()
		_warden_lights.erase(node))
	_update_light(node)

# Wardens that attack glow; walls (Thornwall) stay dark. Re-checked when a Warden grows. The lights
# live here, not under the Warden (Wardens don't move), so a Warden's own children stay its own.
func _update_light(tower: Tower) -> void:
	var light: PointLight2D = _warden_lights.get(tower)
	var lit := tower.tower_data == null or tower.tower_data.can_attack
	if lit and light == null:
		light = make_light(warden_light_color, warden_light_energy, warden_light_radius)
		light.position = to_local(tower.global_position) + Vector2(0, -2)
		add_child(light)
		_warden_lights[tower] = light
	elif not lit and light != null:
		light.queue_free()
		_warden_lights[tower] = null
