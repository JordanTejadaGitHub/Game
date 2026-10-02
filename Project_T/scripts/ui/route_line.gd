extends RefCounted
class_name RouteLine

# The route previews (building, clearing) follow the "High-contrast route line" accessibility setting
# (screens_ui.md "Settings"): thicker, opaque and bright instead of the soft translucent line.
# The setting is cached (previews restyle often); SettingsPanel calls reload() when it changes.
# Route mist (screens_ui.md "Route mist", 2026-10-01): normally the preview is a ribbon of cold mist (MIST_TEXTURE
# tiled along the line, start / end caps) flowing toward the Heartwood (still under reduced motion); draw_route also
# shows the old route as a faint wisp where it differs, and glints once along a stretch that lengthens the route.

const SETTING := "high_contrast_route"
const CONTRAST_COLOR := Color(1.0, 0.92, 0.2)  # Accessibility (high-contrast route): may stay off-palette
const CONTRAST_WIDTH := 10.0
const MAP_GRID = preload("res://resource/map/map_grid.tres")
const MIST_TEXTURE := "res://assets/environment/dream/route_mist.png"
const MIST_START := "res://assets/environment/dream/route_mist_start.png"
const MIST_END := "res://assets/environment/dream/route_mist_end.png"
const FLOW_CELLS := 0.5  # Cells a second the mist drifts toward the Heartwood
const OLD_WIDTH := 14.0  # The old route's wisp
const OLD_ALPHA := 0.35
const GLINT_TIME := 0.7  # Seconds the added stretch glints

static var _high := -1  # -1 = not read yet, 0 / 1

static func reload() -> void:
	_high = 1 if bool(HeartwoodMemory.get_settings().get(SETTING, false)) else 0

static func is_high_contrast() -> bool:
	if _high < 0:
		reload()
	return _high == 1

# Styles `line` for the current setting; `normal_color` / `normal_width` are its usual look.
static func apply(line: Line2D, normal_color: Color, normal_width: float = 6.0) -> void:
	var high := is_high_contrast()
	line.default_color = CONTRAST_COLOR if high else normal_color
	line.width = CONTRAST_WIDTH if high else normal_width

# Mist art is there (the soft line stays as the fallback).
static func has_mist() -> bool:
	return ResourceLoader.exists(MIST_TEXTURE)

# Shows `cells` (the route, start to Heartwood) on `line`: mist normally, the high-contrast line with that setting,
# else `normal_color`. `old_cells` (the route now) adds the faint old wisp where it differs, and a glint once along the
# new stretch when the route gets longer. Children of `line`, so they show and hide with it.
static func draw_route(line: Line2D, cells: PackedVector2Array, normal_color: Color, normal_width: float = 6.0,
		old_cells: PackedVector2Array = PackedVector2Array()) -> void:
	line.clear_points()
	for cell in cells:
		line.add_point(MAP_GRID.calculate_map_position(cell))
	var mist := has_mist() and not is_high_contrast()
	_extras(line).visible = mist and cells.size() >= 2
	if not mist:
		apply(line, normal_color, normal_width)
		line.texture = null
		line.material = null
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		return
	_mist_style(line, 1.0)
	line.begin_cap_mode = Line2D.LINE_CAP_NONE  # The cap sprites end it
	line.end_cap_mode = Line2D.LINE_CAP_NONE
	var extras := _extras(line)
	if cells.size() < 2:
		return
	_place_cap(extras.get_node("Start") as Sprite2D, line.points[0], line.points[1])
	_place_cap(extras.get_node("End") as Sprite2D, line.points[-1], line.points[-2])
	# The old route, faint, where it differs (each stretch joined to the shared cells around it).
	var old_box := extras.get_node("Old")
	for child in old_box.get_children():
		child.queue_free()
	var on_new := {}
	for cell in cells:
		on_new[cell] = true
	var on_old := {}
	for cell in old_cells:
		on_old[cell] = true
	for run in _runs(old_cells, on_new):
		var wisp := Line2D.new()
		for cell in run:
			wisp.add_point(MAP_GRID.calculate_map_position(cell))
		_mist_style(wisp, OLD_ALPHA)
		wisp.width = OLD_WIDTH
		old_box.add_child(wisp)
	# A longer route: the new stretch glints once (once per route shown).
	var glint_box := extras.get_node("Glint")
	var key := hash(cells)
	if old_cells.is_empty() or cells.size() <= old_cells.size() or int(glint_box.get_meta(&"key", 0)) == key:
		if int(glint_box.get_meta(&"key", 0)) != key:
			for child in glint_box.get_children():
				child.queue_free()
		return
	glint_box.set_meta(&"key", key)
	for child in glint_box.get_children():
		child.queue_free()
	for run in _runs(cells, on_old):
		var glint := Line2D.new()
		for cell in run:
			glint.add_point(MAP_GRID.calculate_map_position(cell))
		_mist_style(glint, 1.0)
		var shine := CanvasItemMaterial.new()
		shine.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glint.material = shine
		glint.modulate = Color(Palette.MOONLIGHT, 0.0)
		glint_box.add_child(glint)
		var tween := glint.create_tween()
		tween.tween_property(glint, "modulate:a", 0.9, GLINT_TIME * 0.35)
		tween.tween_property(glint, "modulate:a", 0.0, GLINT_TIME * 0.65)

# No route shown (the caps and wisps go too).
static func clear(line: Line2D) -> void:
	line.clear_points()
	var extras := line.get_node_or_null("MistExtras") as Node2D
	if extras != null:
		extras.visible = false

# Stretches of `cells` not in `skip`, each with the neighbouring kept cells so it joins the rest of the route.
static func _runs(cells: PackedVector2Array, skip: Dictionary) -> Array:
	var runs: Array = []
	var current: Array = []
	for i in cells.size():
		if skip.has(cells[i]):
			if not current.is_empty():
				current.append(cells[i])
				runs.append(current)
				current = []
			continue
		if current.is_empty() and i > 0:
			current.append(cells[i - 1])
		current.append(cells[i])
	if current.size() >= 2:
		runs.append(current)
	return runs.filter(func(run: Array) -> bool: return run.size() >= 2)

static func _mist_style(line: Line2D, alpha: float) -> void:
	var texture: Texture2D = load(MIST_TEXTURE)
	line.texture = texture
	line.texture_mode = Line2D.LINE_TEXTURE_TILE
	line.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	line.width = float(texture.get_height())
	line.default_color = Color(1, 1, 1, alpha)  # multiplier: the art carries the colour
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	var material := line.material as ShaderMaterial
	if material == null or not material.has_meta(&"route_mist"):  # Made once per line (never a static: exit crash)
		material = ShaderMaterial.new()
		material.shader = _flow_shader()
		material.set_meta(&"route_mist", true)
	var still := bool(Fx.setting("reduced_motion", false))
	# Tile = the strip's width at this line width: FLOW_CELLS cells a second in tiles.
	material.set_shader_parameter(&"speed", 0.0 if still else FLOW_CELLS * MAP_GRID.cell_size.x / float(texture.get_width()))
	line.material = material

# The cap sprites and the old / glint lines, made once under `line`.
static func _extras(line: Line2D) -> Node2D:
	var extras := line.get_node_or_null("MistExtras") as Node2D
	if extras != null:
		return extras
	extras = Node2D.new()
	extras.name = "MistExtras"
	extras.show_behind_parent = true  # The old wisp under the new route
	line.add_child(extras)
	var old_box := Node2D.new()
	old_box.name = "Old"
	extras.add_child(old_box)
	for cap in [["Start", MIST_START], ["End", MIST_END]]:
		var sprite := Sprite2D.new()
		sprite.name = cap[0]
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if ResourceLoader.exists(cap[1]):
			sprite.texture = load(cap[1])
		extras.add_child(sprite)
	var glint_box := Node2D.new()
	glint_box.name = "Glint"
	glint_box.z_index = 1
	extras.add_child(glint_box)
	return extras

# A cap beside the line's end at `at` (the next point inward is `inner`): the start cap's right edge and the end cap's
# left edge meet the strip, both drawn facing the way the route runs (forward = +x in the art).
static func _place_cap(sprite: Sprite2D, at: Vector2, inner: Vector2) -> void:
	if sprite.texture == null:
		return
	var outward := (at - inner).normalized()
	var forward := -outward if sprite.name == "Start" else outward
	sprite.rotation = forward.angle()
	sprite.position = at + outward * sprite.texture.get_width() * 0.5
	sprite.modulate = Color.WHITE  # multiplier

static func _flow_shader() -> Shader:
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nuniform float speed = 0.0;\nvoid fragment() {\n\tCOLOR = texture(TEXTURE, vec2(UV.x - TIME * speed, UV.y)) * COLOR;\n}\n"
	return shader
