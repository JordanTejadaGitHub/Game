extends Node2D
class_name NightmareOverlay

# Every nightmare's health bar, blight coat, Restless arrows and status badges, drawn from this one
# canvas item above the field instead of in each Enemy._draw (screens_ui.md "Status icons, clearer";
# perf, 2026-09-30). Each nightmare's own drawing sits in the y-sort among the Wardens and obstacles,
# so it broke the batches: ~5 draw calls a nightmare. Here the kinds are drawn in passes (all bars,
# then all badge discs and arcs, then all icons, then all numbers), so the whole field is a few
# batches. Redrawn every frame while nightmares are out (they move); off-screen ones are skipped.
# Made by EnemyContainer (never a child of it: its children are all nightmares).

const Z := 7  # Above the field, its effects and the edge fog (EnvironmentAmbience is 6)
const EnemyScript := preload("res://scripts/enemy/enemy.gd")

# The status badges' shapes, pre-drawn once into one small texture (so a badge is a few textured quads
# from one texture: the discs pass batches as one draw, and no circle or arc is built per frame):
# the dark disc, the faint rim, the solid rim (max stacks), and the rim arc in ARC_STEPS steps, drawn
# white and tinted per status. Cells of CELL px; `badge_region(kind)` finds one.
const CELL := 32
const ARC_STEPS := 12
enum { BADGE_DISC, BADGE_RIM, BADGE_RIM_FULL, BADGE_ARC }  # BADGE_ARC + k - 1 = k twelfths of the arc
const RIM_SHARE := 0.21  # The faint rim and the arc: 1.5 px of a 7 px badge radius
const RIM_FULL_SHARE := 0.36  # The solid rim at max stacks: 2.5 px of 7

var spawner: Node2D
var badge_atlas: ImageTexture
var _drawn_empty := false

func _ready() -> void:
	z_index = Z
	z_as_relative = false
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR  # Smooth badge rims at any UI scale
	badge_atlas = _make_badge_atlas()

func badge_region(kind: int) -> Rect2:
	return Rect2(kind * CELL, 0, CELL, CELL)

static func _make_badge_atlas() -> ImageTexture:
	var cells := BADGE_ARC + ARC_STEPS
	var image := Image.create(CELL * cells, CELL, false, Image.FORMAT_RGBA8)
	var c := CELL / 2.0
	for y in CELL:
		for x in CELL:
			var dx := x + 0.5 - c
			var dy := y + 0.5 - c
			var d := sqrt(dx * dx + dy * dy)
			var outer := clampf(c - d, 0.0, 1.0)  # Anti-aliased edge of the whole badge
			var rim := minf(outer, clampf(d - c * (1.0 - RIM_SHARE) + 0.5, 0.0, 1.0))
			var rim_full := minf(outer, clampf(d - c * (1.0 - RIM_FULL_SHARE) + 0.5, 0.0, 1.0))
			var angle := fposmod(atan2(dx, -dy), TAU)  # Clockwise from the top
			image.set_pixel(BADGE_DISC * CELL + x, y, Color(Palette.VOID, 0.9 * outer))
			image.set_pixel(BADGE_RIM * CELL + x, y, Color(1, 1, 1, rim))
			image.set_pixel(BADGE_RIM_FULL * CELL + x, y, Color(1, 1, 1, rim_full))
			for k in range(1, ARC_STEPS + 1):
				var inside := clampf((TAU * k / ARC_STEPS - angle) * d, 0.0, 1.0)  # Soft cut at the arc's end
				image.set_pixel((BADGE_ARC + k - 1) * CELL + x, y, Color(1, 1, 1, rim * inside))
	return ImageTexture.create_from_image(image)

func _process(_delta: float) -> void:
	if spawner == null or not is_instance_valid(spawner):
		return
	var empty := spawner.get_child_count() == 0
	if empty and _drawn_empty:
		return  # Nothing out, and the last frame drawn was already empty
	_drawn_empty = empty
	queue_redraw()

func _draw() -> void:
	if spawner == null or not is_instance_valid(spawner):
		return
	var shown: Array = []
	for enemy in spawner.get_children():
		if enemy.is_cleansed or enemy._hidden or not enemy.is_visible_in_tree() or not EnemyScript._on_screen(enemy):
			continue
		shown.append(enemy)
	if shown.is_empty():
		return
	var offset := spawner.global_position - global_position  # Spawner space → this node's space
	var text_scale := WorldLabel.text_scale(self)
	for pass_kind in EnemyScript.HUD_PASSES:
		for enemy in shown:
			enemy.draw_hud(self, enemy.position + offset, pass_kind, text_scale)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
