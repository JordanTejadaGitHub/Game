extends RefCounted

# UI Asset's Dream pick art (assets/ui/dream_fx/, 37afcbf5; layout in dream_fx.json) for DreamScreen: the rarity
# flare as a card turns in (an animated 9-slice around the card), the pulse ring as the picked card lifts, and the
# spark trail on its flight into the Dreams row. Everything runs on PAUSE_PROCESS tweens (the rest is paused) and
# frees itself. Textures are loaded per call through ResourceLoader's cache (never held in a static: exit crash).

const DIR := "res://assets/ui/dream_fx/"
const ROWS := {UpgradeData.Rarity.COMMON: 0, UpgradeData.Rarity.UNCOMMON: 1, UpgradeData.Rarity.RARE: 2,
	UpgradeData.Rarity.LEGENDARY: 3}
const ENTWINED_ROW := 4
const FLARE_FRAME := 48
const FLARE_FRAMES := 5
const FLARE_MARGIN := 16
const FLARE_INSET := 8  # Art px the frame sits outside the card
const SCALE := 2
const FRAME_TIME := 0.06
const RING_FRAME := 32
const RING_FRAMES := 5
const SPARK_FRAME := 7
const SPARK_FRAMES := 4

static func _texture(name: String) -> Texture2D:
	var path := DIR + name
	return load(path) if ResourceLoader.exists(path) else null

static func _frame(sheet: Texture2D, size: int, column: int, row: int = 0) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(column * size, row * size, size, size)
	return atlas

# The flare around `card_box` (a card's Control) in `card`'s rarity, played once over its 5 frames.
static func flare(card_box: Control, card: UpgradeData) -> void:
	var sheet := _texture("flare.png")
	if sheet == null or card == null or not is_instance_valid(card_box):
		return
	var row: int = ENTWINED_ROW if card.entwined else int(ROWS.get(card.rarity, 0))
	var patch := NinePatchRect.new()
	patch.name = "Flare"
	patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	patch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	patch.texture = _frame(sheet, FLARE_FRAME, 0, row)
	patch.patch_margin_left = FLARE_MARGIN
	patch.patch_margin_top = FLARE_MARGIN
	patch.patch_margin_right = FLARE_MARGIN
	patch.patch_margin_bottom = FLARE_MARGIN
	patch.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	patch.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE
	var grow := float(FLARE_INSET * SCALE)
	patch.position = Vector2(-grow, -grow)
	patch.size = (card_box.size + Vector2(grow, grow) * 2.0) / SCALE  # Drawn at ×2: whole art pixels
	patch.scale = Vector2(SCALE, SCALE)
	patch.z_index = 1
	card_box.add_child(patch)
	var tween := patch.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	for f in range(1, FLARE_FRAMES):
		tween.tween_interval(FRAME_TIME)
		tween.tween_callback(func() -> void: patch.texture = _frame(sheet, FLARE_FRAME, f, row))
	tween.tween_interval(FRAME_TIME)
	tween.tween_callback(patch.queue_free)

# The pulse ring at `at` (global), tinted `colour`, on `parent` (a CanvasLayer's Control: drawn top level).
static func pulse(parent: Control, at: Vector2, colour: Color) -> void:
	var sheet := _texture("pulse_ring.png")
	if sheet == null or not is_instance_valid(parent):
		return
	var ring := _sprite(parent, _frame(sheet, RING_FRAME, 0), RING_FRAME, at, colour)
	var tween := ring.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	for f in range(1, RING_FRAMES):
		tween.tween_interval(FRAME_TIME)
		tween.tween_callback(func() -> void: ring.texture = _frame(sheet, RING_FRAME, f))
	tween.tween_interval(FRAME_TIME)
	tween.tween_callback(ring.queue_free)

# One spark at `at` (global), tinted `colour`, `shrink` 0..1 of its size (it shrinks with the flying card).
static func spark(parent: Control, at: Vector2, colour: Color, shrink: float = 1.0) -> void:
	var sheet := _texture("spark.png")
	if sheet == null or not is_instance_valid(parent):
		return
	var dot := _sprite(parent, _frame(sheet, SPARK_FRAME, 0), SPARK_FRAME, at, colour)
	dot.scale = Vector2.ONE * maxf(shrink, 0.5)
	var tween := dot.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	for f in range(1, SPARK_FRAMES):
		tween.tween_interval(FRAME_TIME)
		tween.tween_callback(func() -> void: dot.texture = _frame(sheet, SPARK_FRAME, f))
	tween.tween_interval(FRAME_TIME)
	tween.tween_callback(dot.queue_free)

static func _sprite(parent: Control, texture: Texture2D, size: int, at: Vector2, colour: Color) -> TextureRect:
	var rect := TextureRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.size = Vector2(size, size) * SCALE
	rect.pivot_offset = rect.size / 2.0
	rect.top_level = true
	rect.modulate = colour  # multiplier: neutral light tinted by rarity
	parent.add_child(rect)
	rect.global_position = at - rect.size / 2.0
	return rect
