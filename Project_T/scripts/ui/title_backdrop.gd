class_name TitleBackdrop
extends Control

# The title screen's background (tools/title_art_generator.gd): the 640×360 art covering the window,
# centred and cropped, at a whole-number scale where one fits (3× at 1080p, 2× at 720p) so every art
# pixel stays square (art_scale). It is drawn in the generator's layers (title_layers.json) so it can
# live: the Warden breathes (a slow stretch up from the waterline, in whole art pixels), each nightmare
# breathes at its own pace (the will-o'-wisp bobs), and mist strips drift across. Stacked still, the
# layers are exactly title_background.png. A wash of night on the left keeps the menu readable; motes of
# Heartwood light drift up. Everything holds still under reduced motion.

const ART := preload("res://assets/ui/title/title_background.png")
const DIR := "res://assets/ui/title/"
const LAYOUT := DIR + "title_layers.json"
const ART_SIZE := Vector2(640.0, 360.0)
const WHOLE_SCALE_SLACK := 1.1  # A whole scale may overshoot the cover scale by 10%
const WASH_SHARE := 0.42  # How far the menu's wash of night reaches across
const WASH_ALPHA := 0.55
const MOTE_COUNT := 36
const MOTE_COLOURS: Array[Color] = [Palette.GLOW, Palette.GOLD, Palette.DEWLIGHT, Palette.MOONLIGHT]

var art: Texture2D = ART  # The art to draw; another texture (previews) is drawn flat, without layers
var _layout := {}
var _layers := {}  # back / warden / nightmares / front -> Texture2D
var _mists: Array[Dictionary] = []  # {texture, y, speed}
var _motes: Array[Dictionary] = []  # {pos (art px), speed, sway, phase, colour}
var _time := 0.0
var _still := false
var _rng := RandomNumberGenerator.new()

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)  # Before it enters the tree, like the title's other layers
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	_still = bool(HeartwoodMemory.load_data().get("settings", {}).get("reduced_motion", false))
	_load_layers()
	_rng.randomize()
	for i in MOTE_COUNT:
		_motes.append({
			"pos": Vector2(_rng.randf() * ART_SIZE.x, _rng.randf() * ART_SIZE.y),
			"speed": _rng.randf_range(3.0, 9.0),  # art px per second, upward
			"sway": _rng.randf_range(2.0, 6.0),
			"phase": _rng.randf() * TAU,
			"colour": MOTE_COLOURS[_rng.randi() % MOTE_COLOURS.size()],
		})
	resized.connect(queue_redraw)

# The generator's layers; without them (or with a preview `art`) the flat art is drawn instead.
func _load_layers() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	if not parsed is Dictionary:
		return
	_layout = parsed
	for layer in ["back", "warden", "nightmares", "front"]:
		_layers[layer] = load(DIR + "title_%s.png" % layer)
	for mist: Dictionary in _layout.get("mists", []):
		_mists.append({"texture": load(DIR + str(mist.file)), "y": float(mist.y), "speed": float(mist.speed)})

func has_layers() -> bool:
	return not _layers.is_empty() and art == ART

func _process(delta: float) -> void:
	if _still:
		return
	_time += delta
	for mote in _motes:
		mote.pos.y -= mote.speed * delta
		if mote.pos.y < -2.0:
			mote.pos = Vector2(_rng.randf() * ART_SIZE.x, ART_SIZE.y + 2.0)
	queue_redraw()

# Screen pixels per art pixel, large enough that the art covers the window: whole when that crops
# little (1080p, 720p, 1440p, 4K are exact), else the exact cover scale (16:10, the Steam Deck).
func art_scale() -> float:
	var factor := get_tree().root.content_scale_factor if is_inside_tree() else 1.0
	var pixels := size * factor
	var cover := maxf(1.0, maxf(pixels.x / ART_SIZE.x, pixels.y / ART_SIZE.y))
	return ceilf(cover) if ceilf(cover) <= cover * WHOLE_SCALE_SLACK else cover

# How far a layer has stretched now, in whole art pixels: 0 → amp → 0 over its period.
func breath(amp: float, period: float, phase: float = 0.0) -> int:
	if _still:
		return 0
	return int(round(amp * (0.5 - 0.5 * cos((_time / period + phase) * TAU))))

func _draw() -> void:
	var factor := get_tree().root.content_scale_factor
	var unit := art_scale() / factor  # One art pixel in this control's units
	var origin := ((size - ART_SIZE * unit) * 0.5).floor()
	if has_layers():
		_draw_layers(origin, unit)
	else:
		draw_texture_rect(art, Rect2(origin, ART_SIZE * unit), false)
	# A soft wash of night down the left so the menu reads over the trunks.
	var wash := size.x * WASH_SHARE
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(wash, 0.0), Vector2(wash, size.y), Vector2(0.0, size.y)]),
		PackedColorArray([Color(Palette.VOID, WASH_ALPHA), Color(Palette.VOID, 0.0), Color(Palette.VOID, 0.0), Color(Palette.VOID, WASH_ALPHA)]))
	for mote in _motes:
		var pos: Vector2 = mote.pos
		pos.x += sin(_time * 0.6 + mote.phase) * mote.sway
		var twinkle := 0.45 + 0.55 * absf(sin(_time * 1.3 + mote.phase))
		var cell := (origin + pos.floor() * unit)
		draw_rect(Rect2(cell, Vector2(unit, unit)), Color(mote.colour, twinkle))

func _draw_layers(origin: Vector2, unit: float) -> void:
	draw_texture_rect(_layers.back, Rect2(origin, ART_SIZE * unit), false)
	var warden: Dictionary = _layout.warden
	var top := int(warden.top)
	var pivot := int(warden.pivot)
	_draw_stretched(_layers.warden, Rect2i(0, top, int(ART_SIZE.x), pivot - top), breath(float(warden.amp), float(warden.period)), origin, unit)
	for nm: Dictionary in _layout.nightmares:
		var r: Array = nm.rect
		var rect := Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3]))
		var lift := breath(float(nm.amp), float(nm.period), float(nm.phase))
		if nm.get("floats", false):  # the will-o'-wisp bobs instead
			_draw_region(_layers.nightmares, rect, rect.position - Vector2i(0, lift), origin, unit)
		else:
			_draw_stretched(_layers.nightmares, rect, lift, origin, unit)
	draw_texture_rect(_layers.front, Rect2(origin, ART_SIZE * unit), false)
	for mist in _mists:
		var shift := 0 if _still else int(floor(fposmod(_time * float(mist.speed), ART_SIZE.x)))
		var tex: Texture2D = mist.texture
		var at := origin + Vector2(shift, float(mist.y)) * unit
		var strip := Vector2(tex.get_width(), tex.get_height()) * unit
		draw_texture_rect(tex, Rect2(at, strip), false)
		draw_texture_rect(tex, Rect2(at - Vector2(strip.x, 0.0), strip), false)  # the wrap, seamless

# Draws `rect` of `tex` stretched upward by `grow` whole art pixels, its bottom row (the feet, the
# waterline) fixed. Each screen row samples one source row, so nothing blurs and no gap opens.
func _draw_stretched(tex: Texture2D, rect: Rect2i, grow: int, origin: Vector2, unit: float) -> void:
	if grow <= 0:
		_draw_region(tex, rect, rect.position, origin, unit)
		return
	var bottom := rect.end.y
	var height := float(rect.size.y)
	for dy in range(rect.position.y - grow, bottom):
		var sy := bottom - int(ceil((bottom - dy) * height / (height + grow)))
		if sy < rect.position.y:
			continue
		draw_texture_rect_region(tex, Rect2(origin + Vector2(rect.position.x, dy) * unit, Vector2(rect.size.x, 1.0) * unit),
			Rect2(rect.position.x, sy, rect.size.x, 1.0))

func _draw_region(tex: Texture2D, rect: Rect2i, at: Vector2i, origin: Vector2, unit: float) -> void:
	draw_texture_rect_region(tex, Rect2(origin + Vector2(at) * unit, Vector2(rect.size) * unit), Rect2(rect))
