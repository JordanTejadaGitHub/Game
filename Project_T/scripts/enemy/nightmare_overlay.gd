extends Node2D
class_name NightmareOverlay

# What the nightmares' HUDs share (screens_ui.md "Status icons, revised"; perf, 2026-09-30). Every
# nightmare keeps its health bar, blight coat, Restless arrows and status icons in canvas items of its
# own (Enemy._update_hud), not in its _draw: that sits in the y-sort among the Wardens and obstacles
# and broke the batches (~5 draw calls a nightmare). Each HUD kind has its own absolute z layer
# (Z + Enemy.HUD_*): all bars, then all marks (time bars, stack pips, glows: the atlas below),
# all icons, all number pills, all numbers: the whole field is a few batches. Made by EnemyContainer (never a child
# of it: its children are all nightmares).

const Z := 7  # Above the field, its effects and the edge fog (EnvironmentAmbience is 6); up to Z + 4

# The marks under and behind the status icons, pre-drawn once into one small texture (so the marks
# layer is textured quads from one texture and batches as one draw): a solid white cell (the time
# bars, tinted), a soft round glow (behind an icon at max stacks), a round dot (the stack pips) and a
# rounded pill (behind a stack count). Cells of CELL px.
const CELL := 32
const TIME_STEPS := 8  # The time bars shorten in this many steps (rebuilt once a step; was 12: perf 2026-10-19, 2 px a step)
enum { MARK_SOLID, MARK_GLOW, MARK_DOT, MARK_PILL }

# A camera "trauma" kick for boss moments (screens_ui.md a8471922: one decaying shake, back to centre, off under
# reduced motion): Tower Code's Fx.add_trauma(amount) once it exists, else Fx's small camera shake (`fallback_px`, which
# also skips reduced motion). Callers keep it to the real game (EnemySpawner.in_game).
static var _trauma_known := false
static var _has_trauma := false
static func rumble(world: Node, trauma: float, fallback_px: float) -> void:
	if bool(Fx.setting("reduced_motion", false)):
		return
	if not _trauma_known:
		_trauma_known = true
		for method in (Fx as Script).get_script_method_list():
			if method.name == "add_trauma":
				_has_trauma = true
	if _has_trauma:
		(Fx as Script).call("add_trauma", trauma)  # (Through the script: it parses before add_trauma exists)
	elif world != null:
		Fx._shake(world, fallback_px)

var spawner: Node2D
var badge_atlas: ImageTexture
# Kept here, not in statics, so they're freed with the run (a font or texture held by a static is
# freed after the servers at exit, and crashes): the stack-count font and the status icons.
var stack_font: FontVariation
var _icons := {}  # {status id: Texture2D or null}

func _ready() -> void:
	z_index = Z
	z_as_relative = false
	badge_atlas = _make_badge_atlas()
	stack_font = FontVariation.new()
	stack_font.base_font = UiStyle.body_medium_font()
	stack_font.variation_embolden = 0.9

# A status's pixel-art icon (IconInfo's sheet), cached; null if the sheet has none.
func icon(id: StringName) -> Texture2D:
	if not _icons.has(id):
		_icons[id] = IconInfo.icon(id)
	return _icons[id]

func badge_region(kind: int) -> Rect2:
	if kind == MARK_SOLID:
		return Rect2(CELL / 2 - 1, CELL / 2 - 1, 2, 2)  # The middle of the solid cell: no soft edge
	if kind == MARK_PILL:
		return Rect2(kind * CELL, PILL_TOP, CELL, CELL - PILL_TOP * 2)  # Just the pill, no empty rows
	return Rect2(kind * CELL, 0, CELL, CELL)

const PILL_TOP := 8  # The pill cell's shape fills rows PILL_TOP .. CELL - PILL_TOP

static func _make_badge_atlas() -> ImageTexture:
	var image := Image.create(CELL * 4, CELL, false, Image.FORMAT_RGBA8)
	var c := CELL / 2.0
	var pill_r := c - PILL_TOP  # The pill's end radius (a stadium CELL wide)
	for y in CELL:
		for x in CELL:
			image.set_pixel(MARK_SOLID * CELL + x, y, Color.WHITE)
			var p := Vector2(x + 0.5 - c, y + 0.5 - c)
			var glow := clampf(1.0 - p.length() / c, 0.0, 1.0)
			image.set_pixel(MARK_GLOW * CELL + x, y, Color(1, 1, 1, glow * glow))
			image.set_pixel(MARK_DOT * CELL + x, y, Color(1, 1, 1, clampf(c - p.length(), 0.0, 1.0)))
			var along := maxf(absf(p.x) - (c - pill_r), 0.0)  # Distance past the straight middle
			var pill := clampf(pill_r - Vector2(along, p.y).length(), 0.0, 1.0)
			image.set_pixel(MARK_PILL * CELL + x, y, Color(1, 1, 1, pill))
	return ImageTexture.create_from_image(image)
