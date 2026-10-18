class_name CountTracker
extends Node2D

# The attack tracker over a Warden's head (story chat, the user: "every 4th pulse Roots on the Warden, they need a
# tracker then"). An every-Nth trigger (Tower.get_count_tracker) shows N small pips in an arc: one fills per attack, the
# row glows at N-1 (the next one is the special one), and on the special one they flash in the family's colour and
# empty. A timed trigger (Tower.get_timer_tracker) shows a thin ring that fills toward the next one. Clear of the rank
# pips (base) and the card badges (base, left). Muted while the Warden is idle. Only Wardens with a trigger get one
# (Tower._sync_count_tracker), and it redraws only when something changes.

const PIP_RADIUS := 2.0
const ARC_RADIUS := 13.0
const ARC_STEP := 0.32  # Radians between pips
const RING_RADIUS := 5.0
const FLASH_TIME := 0.45
const IDLE_AFTER := 2.0  # Seconds without an attack before it mutes
const IDLE_ALPHA := 0.45
const TIMER_REDRAW := 0.1  # The ring redraws at most this often

var tower: Tower
var _count := -1
var _every := 0
var _left := 0.0
var _period := 0.0
var _flash := 0.0
var _muted := false
var _redraw_wait := 0.0
var _top := -64.0

func _init(owner_tower: Tower) -> void:
	tower = owner_tower
	name = "CountTracker"
	z_index = 1  # Over the Warden's own sprite

func _ready() -> void:
	_top = _head_top()
	_read(true)

# Where the art's top edge sits (a 64×96 Warden overhangs the cell above).
func _head_top() -> float:
	var sprite := tower.sprite
	if sprite == null or sprite.texture == null:
		return -40.0
	var rect := sprite.get_rect()
	# The frame is as tall as the Warden's tallest frame, attack effects included, so its top edge can sit far
	# above the head (user 2026-10-15: "the ring above is too far above"): measure the idle art's own top row.
	var empty := _empty_rows(tower.tower_data.texture, maxi(tower.tower_data.frame_count, 1))
	return sprite.position.y + (rect.position.y + empty) * sprite.scale.y + 2.0

static var _empty_cache := {}  # texture path -> clear rows above the art in its first frame

static func _empty_rows(texture: Texture2D, frames: int) -> int:
	if texture == null:
		return 0
	var key := texture.resource_path
	if _empty_cache.has(key):
		return _empty_cache[key]
	var rows := 0
	var image := texture.get_image()
	if image != null:
		if image.is_compressed():
			image.decompress()
		var w := image.get_width() / frames
		rows = image.get_height()
		for y in image.get_height():
			for x in w:
				if image.get_pixel(x, y).a > 0.0:
					rows = y
					break
			if rows == y:
				break
	_empty_cache[key] = rows
	return rows

func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(_flash - delta, 0.0)
		queue_redraw()
	_read(false, delta)

func _read(force: bool, delta := 0.0) -> void:
	var muted := tower._anim_time - tower._last_release > IDLE_AFTER
	var counted := tower.get_count_tracker()
	if int(counted[1]) > 0:
		var count := int(counted[0])
		if not force and _every == int(counted[1]) and count < _count:
			_flash = FLASH_TIME  # The special attack: flash, then empty
		if force or count != _count or int(counted[1]) != _every or muted != _muted:
			_count = count
			_every = int(counted[1])
			_muted = muted
			queue_redraw()
		return
	var timed := tower.get_timer_tracker()
	_every = 0
	var left: float = timed[0]
	if not force and left > _left + 0.5:
		_flash = FLASH_TIME  # It fired and started over
	_left = left
	_period = timed[1]
	_redraw_wait -= delta
	if force or _redraw_wait <= 0.0 or muted != _muted:
		_redraw_wait = TIMER_REDRAW
		_muted = muted
		queue_redraw()

func _family_colour() -> Color:
	return Kinships.FAMILY_COLORS.get(tower.tower_data.line, Palette.GOLD)

func _draw() -> void:
	var alpha := IDLE_ALPHA if _muted and _flash <= 0.0 else 1.0
	var family := _family_colour()
	var flash := _flash / FLASH_TIME if not Fx.reduced() else 0.0
	if _every > 0:
		var centre := Vector2(0.0, _top + ARC_RADIUS)
		var ready := _count == _every - 1
		for i in _every:
			var angle := -PI / 2.0 + (i - (_every - 1) / 2.0) * ARC_STEP
			var at := (centre + Vector2.from_angle(angle) * ARC_RADIUS).round()
			var filled := i < _count
			if flash > 0.0:
				draw_circle(at, PIP_RADIUS + 1.5 * flash, Color(family, flash))  # The special attack's flash
				continue
			if ready:
				draw_circle(at, PIP_RADIUS + 1.5, Color(family, 0.35 * alpha))  # Glow: the next one is the special one
			draw_circle(at, PIP_RADIUS + 0.75, Color(Palette.NIGHT, 0.8 * alpha))  # Dark rim so it reads on any ground
			draw_circle(at, PIP_RADIUS, Color(family if filled or ready else Palette.MIST, (1.0 if filled else 0.35) * alpha))
	elif _period > 0.0:
		var at := Vector2(0.0, _top - RING_RADIUS)
		var share := 1.0 - _left / _period
		draw_arc(at, RING_RADIUS, 0.0, TAU, 24, Color(Palette.NIGHT, 0.8 * alpha), 3.0)
		draw_arc(at, RING_RADIUS, 0.0, TAU, 24, Color(Palette.MIST, 0.3 * alpha), 1.0)
		if share > 0.0:
			draw_arc(at, RING_RADIUS, -PI / 2.0, -PI / 2.0 + TAU * share, 24, Color(family, alpha), 1.5)
		if flash > 0.0:
			draw_circle(at, RING_RADIUS * (1.0 + 0.6 * flash), Color(family, 0.6 * flash))
