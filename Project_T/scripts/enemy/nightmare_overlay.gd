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
const TIME_STEPS := 12  # The time bars shorten in this many steps (rebuilt once a step)
enum { MARK_SOLID, MARK_GLOW, MARK_DOT, MARK_PILL }

var spawner: Node2D
var badge_atlas: ImageTexture

func _ready() -> void:
	z_index = Z
	z_as_relative = false
	badge_atlas = _make_badge_atlas()

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
