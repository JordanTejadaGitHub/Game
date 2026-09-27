extends RefCounted
class_name Fx

# Plays the combat effect sheets in assets/effects/ (index: effects.json, made by
# tools/effect_art_generator.gd). Static API, so any script can fire an effect without a node in
# the scene. Owns the visual rules from screens_ui.md "Impact tiers": the budget of ~6 full
# Reaction effects per second (the rest swap to their _lite sheet), the reduce-flashes and
# hitstop settings, Reaction callouts and light threads, and chain presentation (badge, surge,
# Dawnburst). Game rules never live here: callers decide what happened, Fx only shows it.
#
#   Fx.play(effect, at, parent, scale, lite_ok, seconds)  one sheet at a world position
#   Fx.segment(effect, from, to, parent, seconds)          arc / light thread / root drag
#   Fx.reaction(reaction, at, parent, towers, seconds)     effect + callout + light threads
#   Fx.chain(count, where, parent, towers)                 x2+ badge, x5 surge + hitstop, x10 Dawnburst
#   Fx.crit(at, parent) / Fx.status_flash(status, at, parent)
#   Fx.rain_sweep(center, radius, parent, seconds)         Monsoon's sheet of rain
#
# `parent`: the run's scene root (world space, scrolls with the map). Never EnemyContainer or
# TowerContainer: other code treats their children as nightmares / Wardens.

const INDEX_PATH := "res://assets/effects/effects.json"
const DIR := "res://assets/effects/"
const FULL_PER_SECOND := 6  # Full Reaction effects per second before the _lite sheets take over
const Z := 20  # Above nightmares and Wardens, under the combat callouts (21)
const SETTINGS_REFRESH_MS := 1000

# Reaction id -> [effect sheet, callout text]. Callout colours come from effects.json.
const REACTIONS := {
	&"thunderclap": [&"thunderclap", "Thunderclap!"],
	&"ignite": [&"ignite", "Ignite!"],
	&"mushrooming": [&"overgrowth", "Mushrooming!"],
	&"shatter": [&"shatter", "Shatter!"],
	&"drown": [&"drown", "Drown!"],
	&"pinned": [&"pinned", "Pinned!"],
	&"smother": [&"smother", "Smother!"],
	&"lightning_rod": [&"lightning_rod", "Lightning Rod!"],
}
# Sheets that peak small in their frame: shown bigger (screens_ui.md "Size check").
const DEFAULT_SCALE := {&"thunderclap": 1.5, &"thunderclap_lite": 1.5, &"ignite": 1.5, &"ignite_lite": 1.5,
	&"pinned": 1.5, &"shatter": 1.5, &"crit_flare": 1.25}
const THREAD_SECONDS := 0.3
const CALLOUT_LIFE := 0.9
const CALLOUT_COOLDOWN := 0.5  # Per reaction, so a chain doesn't wall the screen with words
const MAX_CALLOUTS := 3
const BADGE_OFFSET := Vector2(0, -60)
const HITSTOP_SECONDS := 0.07
const SURGE_SECONDS := 0.5
const DAWNBURST_SCALE := 2.0

static var _index := {}
static var _textures := {}
static var _full_times: Array[int] = []  # msec of recent full Reaction effects
static var _settings := {}
static var _settings_at := -SETTINGS_REFRESH_MS
static var _callout_cooldown := {}  # reaction -> msec it may pop again
static var _callouts_alive: Array = []
static var _badge: Node2D
static var longest_chain := 0  # This run's longest chain (reset with reset_run())

# --- Data ---------------------------------------------------------------------------------------

static func info(effect: StringName) -> Dictionary:
	if _index.is_empty() and FileAccess.file_exists(INDEX_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(INDEX_PATH))
		if typeof(parsed) == TYPE_DICTIONARY:
			_index = parsed.get("effects", {})
	return _index.get(String(effect), {})

static func texture(effect: StringName) -> Texture2D:
	if not _textures.has(effect):
		var entry := info(effect)
		_textures[effect] = load(DIR + entry.file) if not entry.is_empty() else null
	return _textures[effect]

static func setting(key: String, fallback: Variant) -> Variant:
	var now := Time.get_ticks_msec()
	if now - _settings_at >= SETTINGS_REFRESH_MS:
		_settings = HeartwoodMemory.get_settings()
		_settings_at = now
	return _settings.get(key, fallback)

static func reduce_flashes() -> bool:
	return bool(setting("reduce_flashes", false))

# Forgets the cached settings (after the settings panel saves) and the run's chain record.
static func reset_run() -> void:
	_settings_at = -SETTINGS_REFRESH_MS
	longest_chain = 0

# The sheet to actually show: its _lite variant when flashes are reduced or the budget is spent.
static func _pick(effect: StringName, lite_ok: bool) -> StringName:
	var entry := info(effect)
	var lite := StringName(entry.get("lite", ""))
	if lite == &"":
		return effect
	if reduce_flashes():
		return lite
	var now := Time.get_ticks_msec()
	while not _full_times.is_empty() and now - _full_times[0] > 1000:
		_full_times.pop_front()
	if lite_ok and _full_times.size() >= FULL_PER_SECOND:
		return lite
	_full_times.append(now)
	return effect

# --- Playing ------------------------------------------------------------------------------------

# Plays `effect` once at world position `at` under `parent` (anchor respected) and returns its
# node, which frees itself. Looping sheets loop until freed, or for `seconds` if > 0.
static func play(effect: StringName, at: Vector2, parent: Node, scale: float = 1.0, lite_ok: bool = true,
		seconds: float = 0.0) -> Node2D:
	if parent == null or not is_instance_valid(parent):
		return null
	var shown := _pick(effect, lite_ok)
	var entry := info(shown)
	var tex := texture(shown)
	if entry.is_empty() or tex == null:
		push_warning("Fx: no effect '%s'" % shown)
		return null
	var node := FxSprite.new(entry, tex, scale * DEFAULT_SCALE.get(shown, 1.0), seconds)
	node.effect = shown
	node.name = "Fx_" + String(shown)
	parent.add_child(node)
	node.global_position = at
	return node

# Stretches a segment sheet (thunderclap_arc, light_thread, long_way_home_drag) from `from` to `to`
# (world positions), tiling it along the way, for `seconds`, fading out at the end.
static func segment(effect: StringName, from: Vector2, to: Vector2, parent: Node, seconds: float = 0.3) -> Node2D:
	if parent == null or not is_instance_valid(parent) or from.is_equal_approx(to):
		return null
	var entry := info(effect)
	var tex := texture(effect)
	if entry.is_empty() or tex == null:
		push_warning("Fx: no effect '%s'" % effect)
		return null
	var node := FxSegment.new(entry, tex, from.distance_to(to), seconds)
	parent.add_child(node)
	node.global_position = from
	node.rotation = from.angle_to_point(to)
	return node

static func crit(at: Vector2, parent: Node) -> Node2D:
	return play(&"crit_flare", at, parent)

# A quick ring in the status's colour on the nightmare (a combo just used that status).
static func status_flash(status: StringName, at: Vector2, parent: Node) -> Node2D:
	var node := play(&"status_flash", at, parent)
	if node != null:
		var rows: Array = info(&"status_flash").get("rows", [])
		node.row = maxi(rows.find(String(status)), 0)
	return node

# A named Reaction went off at `at`: its effect (budgeted), its callout in its colour, and a light
# thread from each Warden that set it up. Smother loops: pass `seconds` or free the returned node.
static func reaction(reaction: StringName, at: Vector2, parent: Node, towers: Array = [], seconds: float = 0.0) -> Node2D:
	var row: Array = REACTIONS.get(reaction, [reaction, ""])
	var effect: StringName = row[0]
	var node := play(effect, at, parent, 1.0, true, seconds)
	var colour := Color(info(effect).get("callout", "#fff0c0"))
	if row[1] != "":
		callout(row[1], colour, at, parent, reaction)
	for tower in towers:
		if tower is Node2D and is_instance_valid(tower):
			segment(&"light_thread", tower.global_position, at, parent, THREAD_SECONDS)
	_shake(parent, 2.0)
	return node

# A word popping over the nightmare in `colour` (throttled: a few at a time, one per reaction).
static func callout(text: String, colour: Color, at: Vector2, parent: Node, key: StringName = &"") -> void:
	var now := Time.get_ticks_msec()
	_callouts_alive = _callouts_alive.filter(func(c): return is_instance_valid(c))
	if _callouts_alive.size() >= MAX_CALLOUTS or now < _callout_cooldown.get(key, 0):
		return
	_callout_cooldown[key] = now + int(CALLOUT_COOLDOWN * 1000)
	var node := FxCallout.new(text, colour)
	parent.add_child(node)
	node.global_position = at
	_callouts_alive.append(node)

# Monsoon's signature: a sheet of warm-lit rain over a square of `radius` pixels round `center`.
static func rain_sweep(center: Vector2, radius: float, parent: Node, seconds: float = 0.8) -> Node2D:
	var entry := info(&"monsoon_sweep")
	var tex := texture(&"monsoon_sweep")
	if parent == null or entry.is_empty() or tex == null:
		return null
	var node := FxRain.new(entry, tex, radius, seconds)
	parent.add_child(node)
	node.global_position = center
	return node

# --- Chains -------------------------------------------------------------------------------------

# A chain reached `count` at `where`. x2+: badge; x5: hitstop + warm surge; x10: Dawnburst and
# every Warden in `towers` flares. Call once per step of the chain.
static func chain(count: int, where: Vector2, parent: Node, towers: Array = []) -> void:
	if parent == null or not is_instance_valid(parent) or count < 2:
		return
	longest_chain = maxi(longest_chain, count)
	if is_instance_valid(_badge):
		_badge.queue_free()
	var badge_entry := info(&"chain_badge")
	if not badge_entry.is_empty():
		_badge = FxBadge.new(badge_entry, texture(&"chain_badge"), info(&"chain_digits"), texture(&"chain_digits"), count)
		parent.add_child(_badge)
		_badge.global_position = where + BADGE_OFFSET
	if count == 5 or count == 10:
		_hitstop(parent)
		if not reduce_flashes():
			_surge(parent)
	if count == 10:
		play(&"dawnburst", where, parent, DAWNBURST_SCALE, false)
		for tower in towers:
			if tower is Node2D and is_instance_valid(tower):
				play(&"crit_flare", tower.global_position + Vector2(0, -16), parent, 1.6)

static func _hitstop(parent: Node) -> void:
	if not bool(setting("hitstop", true)) or Engine.time_scale <= 0.0:
		return
	var before := Engine.time_scale
	Engine.time_scale = before * 0.05
	parent.get_tree().create_timer(HITSTOP_SECONDS, true, false, true).timeout.connect(func() -> void:
		if is_equal_approx(Engine.time_scale, before * 0.05):
			Engine.time_scale = before)

static func _surge(parent: Node) -> void:
	var tex := texture(&"surge")
	if tex == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 90
	var rect := TextureRect.new()
	rect.texture = tex
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.modulate.a = 0.0
	layer.add_child(rect)
	parent.get_tree().root.add_child(layer)
	var tween := rect.create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(rect, "modulate:a", 0.8, SURGE_SECONDS * 0.3)
	tween.tween_property(rect, "modulate:a", 0.0, SURGE_SECONDS * 0.7)
	tween.tween_callback(layer.queue_free)

# A tiny camera shake for Reactions (off with reduced motion).
static func _shake(parent: Node, pixels: float) -> void:
	if bool(setting("reduced_motion", false)) or not parent.is_inside_tree():
		return
	var camera := parent.get_viewport().get_camera_2d()
	if camera == null:
		return
	var rest := camera.offset
	var tween := camera.create_tween()
	for i in 3:
		tween.tween_property(camera, "offset", rest + Vector2(randf_range(-pixels, pixels), randf_range(-pixels, pixels)), 0.03)
	tween.tween_property(camera, "offset", rest, 0.03)


# --- Nodes --------------------------------------------------------------------------------------

# One sheet playing at its anchor. Frees itself at the end (or after `seconds` when looping).
class FxSprite extends Node2D:
	var effect: StringName  # The sheet shown (the _lite one if it was swapped)
	var row := 0
	var _tex: Texture2D
	var _size: Vector2
	var _frames: int
	var _fps: float
	var _anchor: Vector2
	var _loop: bool
	var _scale: float
	var _seconds: float
	var _age := 0.0

	func _init(entry: Dictionary, tex: Texture2D, scale: float, seconds: float) -> void:
		_tex = tex
		_size = Vector2(entry.frame_size[0], entry.frame_size[1])
		_frames = maxi(int(entry.frames), 1)
		_fps = maxf(float(entry.fps), 1.0)
		_anchor = Vector2(entry.anchor[0], entry.anchor[1])
		_loop = bool(entry.loop)
		_scale = scale
		_seconds = seconds
		z_index = Fx.Z
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _process(delta: float) -> void:
		_age += delta
		var done := _age >= _seconds if (_loop and _seconds > 0.0) else (not _loop and _age * _fps >= _frames)
		if done:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var frame := int(_age * _fps)
		frame = frame % _frames if _loop else mini(frame, _frames - 1)
		var fade := 1.0
		if _loop and _seconds > 0.0:
			fade = clampf((_seconds - _age) / 0.3, 0.0, 1.0)  # Loops fade out over their last 0.3 s
		draw_texture_rect_region(_tex, Rect2(-_anchor * _scale, _size * _scale),
			Rect2(Vector2(_size.x * frame, _size.y * row), _size), Color(1, 1, 1, fade))


# A segment sheet tiled along +x for `length` pixels, fading out over the second half of its life.
class FxSegment extends Node2D:
	var _tex: Texture2D
	var _size: Vector2
	var _frames: int
	var _fps: float
	var _anchor_y: float
	var _length: float
	var _seconds: float
	var _age := 0.0

	func _init(entry: Dictionary, tex: Texture2D, length: float, seconds: float) -> void:
		_tex = tex
		_size = Vector2(entry.frame_size[0], entry.frame_size[1])
		_frames = maxi(int(entry.frames), 1)
		_fps = maxf(float(entry.fps), 1.0)
		_anchor_y = float(entry.anchor[1])
		_length = length
		_seconds = maxf(seconds, 0.05)
		z_index = Fx.Z
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _process(delta: float) -> void:
		_age += delta
		if _age >= _seconds:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var frame := int(_age * _fps) % _frames
		var alpha := clampf(2.0 * (1.0 - _age / _seconds), 0.0, 1.0)
		var x := 0.0
		while x < _length:
			var width := minf(_size.x, _length - x)
			draw_texture_rect_region(_tex, Rect2(x, -_anchor_y, width, _size.y),
				Rect2(_size.x * frame, 0, width, _size.y), Color(1, 1, 1, alpha))
			x += _size.x


# Monsoon's rain: the tiling sheet over a square, fading at the corners and in and out.
class FxRain extends Node2D:
	var _tex: Texture2D
	var _size: Vector2
	var _frames: int
	var _fps: float
	var _radius: float
	var _seconds: float
	var _age := 0.0

	func _init(entry: Dictionary, tex: Texture2D, radius: float, seconds: float) -> void:
		_tex = tex
		_size = Vector2(entry.frame_size[0], entry.frame_size[1])
		_frames = maxi(int(entry.frames), 1)
		_fps = maxf(float(entry.fps), 1.0)
		_radius = radius
		_seconds = maxf(seconds, 0.1)
		z_index = Fx.Z
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _process(delta: float) -> void:
		_age += delta
		if _age >= _seconds:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var frame := int(_age * _fps) % _frames
		var life := minf(_age / 0.15, 1.0) * clampf((_seconds - _age) / 0.25, 0.0, 1.0)
		var tiles := ceili(_radius / _size.x)
		for ty in range(-tiles, tiles):
			for tx in range(-tiles, tiles):
				var at := Vector2(tx, ty) * _size
				var reach := (at + _size / 2.0).length() / _radius
				if reach > 1.1:
					continue
				draw_texture_rect_region(_tex, Rect2(at, _size), Rect2(_size.x * frame, 0, _size.x, _size.y),
					Color(1, 1, 1, life * clampf(1.3 - reach, 0.0, 1.0)))


# A Reaction's name rising over the nightmare in its colour, with a little pop as it appears.
class FxCallout extends Node2D:
	var _text: String
	var _colour: Color
	var _age := 0.0

	func _init(text: String, colour: Color) -> void:
		_text = text
		_colour = colour
		z_index = Fx.Z + 2

	func _process(delta: float) -> void:
		_age += delta
		if _age >= Fx.CALLOUT_LIFE:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := _age / Fx.CALLOUT_LIFE
		var alpha := 1.0 - t * t
		var size := 20 if t > 0.12 else 26
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var at := Vector2(-width / 2.0, -52.0 - 20.0 * t)
		draw_string_outline(font, at, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6, Color(0.05, 0.04, 0.08, alpha))
		draw_string(font, at, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(_colour, alpha))


# The chain badge: pops in, shows "x" + the count in its window, holds, then fades.
class FxBadge extends Node2D:
	const HOLD := 0.9
	var _tex: Texture2D
	var _size: Vector2
	var _frames: int
	var _fps: float
	var _digits: Texture2D
	var _glyph: Vector2
	var _glyphs: String
	var _text: String
	var _age := 0.0

	func _init(entry: Dictionary, tex: Texture2D, digit_entry: Dictionary, digits: Texture2D, count: int) -> void:
		_tex = tex
		_size = Vector2(entry.frame_size[0], entry.frame_size[1])
		_frames = maxi(int(entry.frames), 1)
		_fps = maxf(float(entry.fps), 1.0)
		_digits = digits
		_glyph = Vector2(digit_entry.get("frame_size", [8, 12])[0], digit_entry.get("frame_size", [8, 12])[1])
		_glyphs = digit_entry.get("glyphs", "x0123456789")
		_text = "x" + str(count)
		z_index = Fx.Z + 3
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		scale = Vector2(2, 2)

	func _process(delta: float) -> void:
		_age += delta
		if _age >= HOLD + 0.3:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var frame := mini(int(_age * _fps), _frames - 1)
		var alpha := clampf((HOLD + 0.3 - _age) / 0.3, 0.0, 1.0)
		var tint := Color(1, 1, 1, alpha)
		draw_texture_rect_region(_tex, Rect2(-_size / 2.0, _size), Rect2(_size.x * frame, 0, _size.x, _size.y), tint)
		if frame < 2 or _digits == null:
			return  # Digits appear once the badge has popped open
		var advance := 7.0
		var x := -advance * _text.length() / 2.0 - 0.5
		for ch in _text:
			var index := _glyphs.find(ch)
			if index >= 0:
				draw_texture_rect_region(_digits, Rect2(Vector2(x, -_glyph.y / 2.0 + 1), _glyph),
					Rect2(_glyph.x * index, 0, _glyph.x, _glyph.y), tint)
			x += advance
