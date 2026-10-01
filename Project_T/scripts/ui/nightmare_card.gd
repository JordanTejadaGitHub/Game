extends PanelContainer
class_name NightmareCard

# Full info for a nightmare kind that isn't on the field yet (screens_ui.md "Coming this block": tap
# a portrait): portrait, name ("New" if never met), its trait line, health at that drift, speed,
# leaves, and the Resists / Weak to / Immune / Traits rows. A popup above the tapped control; tap it
# (or the same portrait) again to close. Also the portrait and "New" helpers the strip and the boss
# dossier share.

const WIDTH := 300.0

var shown_for: EnemyData = null

func _init() -> void:
	top_level = true
	visible = false
	z_index = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(WIDTH, 0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		visible = false

# Shows `data` as met in drift `drift` above `anchor`; the same kind again closes it.
func toggle_for(data: EnemyData, drift: int, director: DriftDirector, anchor: Control) -> void:
	if visible and shown_for == data:
		visible = false
		return
	shown_for = data
	for child in get_children():
		child.queue_free()
	add_child(build(data, drift, director))
	visible = true
	reset_size()
	var screen := get_viewport_rect().size
	var at := anchor.global_position + Vector2(anchor.size.x / 2.0 - WIDTH / 2.0, -size.y - 8.0)
	if at.y < 4.0:  # No room above (the strip sits at the top): open below the anchor
		at.y = anchor.global_position.y + anchor.size.y + 8.0
	global_position = Vector2(clampf(at.x, 4, screen.x - WIDTH - 4), at.y)

static func build(data: EnemyData, drift: int, director: DriftDirector) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var head := HBoxContainer.new()
	var face := TextureRect.new()
	face.texture = portrait(data)
	face.modulate = data.tint
	face.custom_minimum_size = Vector2(48, 48)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(UiStyle.on_moon_disc(face))  # Readable on the night sky (screens_ui.md)
	var name := Label.new()
	name.text = data.display_name + (" · New" if is_new(data) else "")
	name.add_theme_font_size_override("font_size", 18)
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(name)
	box.add_child(head)
	var lines: Array[String] = []
	if data.trait_text != "":
		lines.append(data.trait_text)
	lines.append(numbers_text(data, drift, director))
	box.add_child(StatusLinks.make_label("\n".join(lines), 15))
	box.add_child(NightmareIcons.make_rows(data, 26.0))
	return box

# "Health 240 · Speed 1.2 tiles/s · Leaves 1" as it would arrive in drift `drift` (this run's growth,
# Blight, Dreams and the Omen on that block).
static func numbers_text(data: EnemyData, drift: int, director: DriftDirector) -> String:
	return "Health %d   Speed %.1f tiles/s   Leaves %d" % [health_at(data, drift, director), data.speed / 64.0,
		data.leaf_cost]

static func health_at(data: EnemyData, drift: int, director: DriftDirector) -> int:
	var scale := director.get_health_scale(data, drift) if director != null else 1.0
	return maxi(roundi(data.health * scale), 1)

# Frame 0 of the kind's walk-down (or first) animation, for portraits.
static var _portraits := {}  # EnemyData path -> its cropped portrait

# The frame cropped to its visible pixels (the 64 px frames carry padding), so the nightmare fills
# the moon disc behind it (UI Code). Cached per kind.
static func portrait(data: EnemyData) -> Texture2D:
	if _portraits.has(data.resource_path):
		return _portraits[data.resource_path]
	if _portraits.is_empty():
		UiStyle.release_at_exit(func() -> void: _portraits.clear())
	var frame := _first_frame(data)
	var cropped := _crop(frame) if frame != null else null
	_portraits[data.resource_path] = cropped
	return cropped

static func _first_frame(data: EnemyData) -> Texture2D:
	var frames := data.sprite_frames
	if frames == null:
		return null
	for animation in [&"idle", &"walk_down", &"walk_side"]:
		if frames.has_animation(animation) and frames.get_frame_count(animation) > 0:
			return frames.get_frame_texture(animation, 0)
	var names := frames.get_animation_names()
	return frames.get_frame_texture(names[0], 0) if not names.is_empty() and frames.get_frame_count(names[0]) > 0 else null

static func _crop(frame: Texture2D) -> Texture2D:
	var image := frame.get_image()
	if image == null or image.is_empty():
		return frame
	if image.is_compressed():
		image.decompress()
	var used := image.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0 or used.size == image.get_size():
		return frame
	var atlas := AtlasTexture.new()
	if frame is AtlasTexture:  # A frame of a sheet: crop inside its region
		atlas.atlas = frame.atlas
		atlas.region = Rect2(frame.region.position + Vector2(used.position), Vector2(used.size))
	else:
		atlas.atlas = frame
		atlas.region = Rect2(used)
	return atlas

# Never met in any run (profile nightmares_seen, which the nightmare info writes on first sight).
static func is_new(data: EnemyData) -> bool:
	var profile := HeartwoodMemory.load_data()  # Met on the field, or read on its intro card
	var kind := kind_of(data)
	return not profile.get("nightmares_seen", []).has(kind) and not profile.get(NightmareIntro.SEEN_KEY, []).has(kind)

static func kind_of(data: EnemyData) -> String:
	return data.resource_path.get_file().get_basename()
