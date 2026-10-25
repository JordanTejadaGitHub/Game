extends Node2D
class_name DewPopup

# "+3" with the Dew drop, floating up from where Dew was earned and fading out. Script-only node.
# UI Asset's Dew popups (2026-10-07, artifact 3k6Xa3cvGTGFSvvHhuVZSd "Dew popups"): no box and no "Dew" word, the
# blue drop then "+N" in the number font with a 1 px Dread outline. Normal Dew: "+N" in Dewlight, 18 px. Caught Dew
# (DewCatch, `color` GOLD): "+N" in Glow (the drop stays blue). The Harvest / Interest at a rest (`text` given): its
# word in small caps first, then the drop and "+N" in Glow at 20 px. Keeps its screen size when zoomed.

const RISE := 36.0  # Pixels it floats up
const DURATION := 0.9
const COLOR := Palette.DEWLIGHT
const BASELINE := -32.0  # Where the line sits above the earning point (as the old tag)
const NUMBER_SIZE := 18
const WORD_NUMBER_SIZE := 20
const WORD_SIZE := 15
const ICON := 16.0
const GAP := 2.0  # Between the drop and the number
const WORD_GAP := 5.0  # Between the word and the drop
const OUTLINE := 2  # draw_string_outline's width: 1 px each side

var _amount: int
var _word := ""  # "harvest" / "interest": a rest payout
var _number_color := COLOR
var _resource := &"dew"  # &"dew", or &"seeds" ("+1" Seed at a clear)
var _card: UpgradeData = null  # The Dream card that paid it (its small glyph first: Weed Puller, Groundskeeper…)
# The icons, kept on the popup: IconInfo.icon makes a temporary AtlasTexture, and one made inside _draw was freed before the
# frame drew, so every popup read as a bare "+1" (user 2026-10-24: "what's the +1 after I clear an obstacle").
var _drop: Texture2D = null
var _card_icon: Texture2D = null

# `color` / `text`: caught Dew is gold (DewCatch.GOLD); the Harvest and Interest pass their line ("Harvest +40 Dew").
# `resource`: &"seeds" for a clear's Seed. `card`: the Dream card that paid it, if one did.
func _init(amount: int, world_position: Vector2, color: Color = COLOR, text: String = "", resource: StringName = &"dew",
		card: UpgradeData = null) -> void:
	_amount = amount
	_resource = resource
	_card = card
	if text != "":
		_word = text.get_slice(" +", 0).strip_edges().to_lower()
	_number_color = Palette.GLOW if _word != "" or color.is_equal_approx(Palette.GLOW) else COLOR
	if resource == &"seeds":
		_number_color = Palette.SPRIG  # Seeds read green, apart from Dew's blue
	position = world_position
	z_index = 10  # Above creatures and Wardens
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # The drop at ×1, crisp

var _tween: Tween

func _ready() -> void:
	_drop = IconInfo.icon(_resource)
	if _card != null:
		_card_icon = UiStyle.dream_glyph_texture(UiStyle.dream_glyph(_card))
	_rise()

func _rise() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	modulate.a = 1.0
	_tween = create_tween()
	_tween.tween_property(self, "position:y", position.y - RISE, DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "modulate:a", 0.0, DURATION * 0.5).set_delay(DURATION * 0.5)
	_tween.tween_callback(queue_free)

# A pack's one popup (owner 2026-10-24, enemy_council_review.md 2026-10-24c: "the feel of a big group being wiped"):
# another member's Dew counts up on it, from that member's spot, and it rises again. Never bonus Dew: just one number.
func add_more(amount: int, world_position: Vector2) -> void:
	_amount += amount
	position = world_position
	_rise()
	queue_redraw()

func is_live() -> bool:
	return is_inside_tree() and not is_queued_for_deletion() and modulate.a > 0.05

func _process(_delta: float) -> void:
	queue_redraw()  # Its screen size follows the camera's zoom

func _draw() -> void:
	WorldLabel.begin_screen_size(self, Vector2.ZERO)
	var number_font := UiStyle.number_font()
	var number_size := WORD_NUMBER_SIZE if _word != "" else NUMBER_SIZE
	var number := "+%d" % _amount
	if _drop == null:  # No icon texture: the resource's font glyph before the number instead (text_pass.md: icon and number)
		number_font = UiStyle.with_glyphs(number_font)
		number = (UiStyle.SEEDS_GLYPH if _resource == &"seeds" else UiStyle.DEW_GLYPH) + number
	var number_width := number_font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size).x
	var word_font := UiStyle.caps_font()
	var word_width := word_font.get_string_size(_word, HORIZONTAL_ALIGNMENT_LEFT, -1, WORD_SIZE).x if _word != "" else 0.0
	var card_w := ICON + GAP if _card_icon != null else 0.0
	var drop_w := ICON + GAP if _drop != null else 0.0
	var width := (word_width + WORD_GAP if _word != "" else 0.0) + card_w + drop_w + number_width
	var x := -width / 2.0
	if _word != "":
		_outlined(word_font, Vector2(x, BASELINE), _word, WORD_SIZE, Palette.GLOW)
		x += word_width + WORD_GAP
	if _card_icon != null:  # The paying card's glyph, small, before the drop
		draw_texture_rect(_card_icon, Rect2(Vector2(x, BASELINE - ICON + 2.0), Vector2(ICON, ICON)), false)
		x += card_w
	if _drop != null:
		draw_texture_rect(_drop, Rect2(Vector2(x, BASELINE - ICON + 2.0), Vector2(ICON, ICON)), false)
		x += drop_w
	_outlined(number_font, Vector2(x, BASELINE), number, number_size, _number_color)
	WorldLabel.end_screen_size(self)

# Text with a 1 px Dread outline under it (no box, no halo: they're frequent).
func _outlined(font: Font, at: Vector2, text: String, size: int, colour: Color) -> void:
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, OUTLINE, Palette.DREAD)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colour)
