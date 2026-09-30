class_name TitleBackdrop
extends Control

# The title screen's background (tools/title_art_generator.gd): the 640×360 art covering the window,
# centred and cropped, at a whole-number scale where one fits (3× at 1080p, 2× at 720p) so every art
# pixel stays square (art_scale). A wash of night on the left keeps the menu readable. Motes of Heartwood light drift up through it, one art pixel each; they hold
# still under reduced motion.

const ART := preload("res://assets/ui/title/title_background.png")
const ART_SIZE := Vector2(640.0, 360.0)
const WHOLE_SCALE_SLACK := 1.1  # A whole scale may overshoot the cover scale by 10%
const WASH_SHARE := 0.42  # How far the menu's wash of night reaches across
const WASH_ALPHA := 0.55
const MOTE_COUNT := 36
const MOTE_COLOURS: Array[Color] = [Palette.GLOW, Palette.GOLD, Palette.DEWLIGHT, Palette.MOONLIGHT]

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

func _draw() -> void:
	var factor := get_tree().root.content_scale_factor
	var unit := art_scale() / factor  # One art pixel in this control's units
	var origin := ((size - ART_SIZE * unit) * 0.5).floor()
	draw_texture_rect(ART, Rect2(origin, ART_SIZE * unit), false)
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
