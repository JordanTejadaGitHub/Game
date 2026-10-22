extends VBoxContainer

# The live Reaction chain counter (screens_ui.md 801d7ae8; user: "should add a chain count somewhere on the UI"): top
# centre under the drift banner, in the Coming strip's spot (just below the strip whenever the strip shows, so they never
# overlap); phones compact in the same spot. "Chain ×N" (with the chain icon when the sheet has one) from a 2-link chain,
# a pop on each new link (none under reduced motion), a flare at ×5 and ×10 (the moment Fx plays its surge / Dawnburst),
# and "Best ×N" for this run under it. Fades HOLD seconds after the last link (links come within a second; the tracker has
# no end signal, so a quiet HOLD is the chain's end). Hidden while nothing chains. Made by the HUD.

const TOP := 72.0  # ComingStrip.TOP: just under the banner
const STRIP_GAP := 8.0  # Below the Coming strip's fog when it shows
const HOLD := 2.0  # Seconds after the last link before it fades
const FADE := 0.4
const FLARES: Array[int] = [5, 10]  # Fx.chain: surge at ×5, Dawnburst at ×10
const MIN_LINKS := 2

var _row := HBoxContainer.new()
var _icon := TextureRect.new()
var _count := Label.new()
var _best := Label.new()
var _tracker: ReactionTracker
var _left := 0.0  # Seconds until the fade starts
var _shown := 0  # The chain on screen
var _find_clock := 0.0
var _phone := false

func _ready() -> void:
	name = "ChainCounter"
	_phone = UiStyle.is_phone()
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	offset_top = TOP
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 0)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 6)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	_icon.texture = IconInfo.icon(&"chain")
	_icon.visible = _icon.texture != null
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.custom_minimum_size = Vector2(20, 20) if _phone else Vector2(24, 24)
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(_icon)
	_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.display(_count, 20 if _phone else 26)
	_count.add_theme_color_override("font_color", UiStyle.GOLD)
	_count.add_theme_color_override("font_outline_color", UiStyle.FOG)
	_count.add_theme_constant_override("outline_size", 6)
	_row.add_child(_count)
	_best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_best.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.number(_best, 12 if _phone else 14, UiStyle.INK_DIM)
	_best.add_theme_color_override("font_outline_color", UiStyle.FOG)
	_best.add_theme_constant_override("outline_size", 4)
	add_child(_best)
	visible = false
	resized.connect(func() -> void: pivot_offset = size / 2.0)

func _process(delta: float) -> void:
	if _tracker == null or not is_instance_valid(_tracker):
		_find_clock -= delta
		if _find_clock <= 0.0:
			_find_clock = 0.5
			_hook(get_tree().get_first_node_in_group(ReactionTracker.GROUP) as ReactionTracker)
	_place()
	if not visible:
		return
	_left -= delta / maxf(Engine.time_scale, 0.001)  # Real seconds: the fade reads the same at 3×
	if _left <= 0.0:
		modulate.a = clampf(1.0 + _left / FADE, 0.0, 1.0)  # multiplier
		if _left <= -FADE:
			visible = false
			_shown = 0

func _hook(tracker: ReactionTracker) -> void:
	if tracker == null:
		return
	_tracker = tracker
	if not tracker.chain_reached.is_connected(_on_chain):
		tracker.chain_reached.connect(_on_chain)

# Under the banner, below the Coming strip when it shows (the strip moves down for an Omen line; this follows it).
func _place() -> void:
	var top := TOP
	var parent := get_parent()
	if parent != null:
		for child in parent.get_children():
			if child is ComingStrip and (child as Control).visible and not UiStyle.is_phone():  # (Phones: the strip is bottom right)
				top = maxf(top, (child as Control).offset_top + (child as Control).size.y + STRIP_GAP)
	offset_top = top

func _on_chain(count: int, _where: Vector2, _towers: Array) -> void:
	if count < MIN_LINKS:
		return
	var grew := count > _shown or not visible
	_shown = count if (count > _shown or _left <= 0.0) else _shown  # A second chain going on doesn't drop the number
	_count.text = "Chain ×%d" % _shown
	_best.text = "Best ×%d" % maxi(_tracker.longest_chain if _tracker != null else count, _shown)
	visible = true
	modulate.a = 1.0  # multiplier
	_left = HOLD
	if grew and not bool(Fx.setting("reduced_motion", false)):
		_pop(count in FLARES)

# A pop on a new link; at ×5 / ×10 a bigger one with a warm flash, timed with Fx's surge / Dawnburst.
func _pop(flare: bool) -> void:
	var tween := create_tween()
	tween.set_ignore_time_scale(true)
	scale = Vector2.ONE * (1.35 if flare else 1.15)
	tween.tween_property(self, "scale", Vector2.ONE, 0.25 if flare else 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if flare:
		_count.add_theme_color_override("font_color", Palette.GLOW)
		tween.parallel().tween_callback(func() -> void: _count.add_theme_color_override("font_color", UiStyle.GOLD)).set_delay(0.35)
