extends SceneTree
# The path is at least half a cell of pale earth everywhere (art_direction.md 6929292c, user rule): the dual path
# (PathGenerator.dual_mask + path_dual.png) drawn for one-half ribbons with the tricky shapes (an L turn, a single
# jog, an S of two jogs, a pinch between staggered Wardens, a T), then the pale-earth width measured across the
# route through every route half's centre (a scan perpendicular to each way the ribbon runs there). >= 30 px.
# Every act's sheet. Run:  Godot --headless --path . --script res://tests/test_path_width.gd

const MIN_WIDTH := 30
const PALE := 0.55  # Luminance: path earth ~0.73; banks, grass and patches well below
const MARGIN := 64

var failures := 0

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)

func _init() -> void:
	var shapes := {
		"L turn": _line(Vector2i(2, 4), Vector2i(8, 4)) + _line(Vector2i(8, 5), Vector2i(8, 10)),
		"single jog": _line(Vector2i(2, 4), Vector2i(6, 4)) + _line(Vector2i(6, 5), Vector2i(11, 5)),
		"S of two jogs": _line(Vector2i(2, 4), Vector2i(5, 4)) + _line(Vector2i(5, 5), Vector2i(8, 5)) + _line(Vector2i(8, 6), Vector2i(12, 6)),
		"pinch between staggered Wardens": _line(Vector2i(2, 4), Vector2i(5, 4)) + _line(Vector2i(5, 5), Vector2i(7, 5))
			+ _line(Vector2i(7, 4), Vector2i(7, 4)) + _line(Vector2i(8, 4), Vector2i(12, 4)),
		"T": _line(Vector2i(2, 4), Vector2i(12, 4)) + _line(Vector2i(7, 5), Vector2i(7, 10)),
	}
	var overall := INF
	var worst := ""
	for act in range(1, 5):
		var sheet: Image = load(EnvironmentTiles.sheet_path("path_dual", act)).get_image()
		sheet.decompress()
		sheet.convert(Image.FORMAT_RGBA8)
		for shape: String in shapes:
			var halves := {}
			for h: Vector2i in shapes[shape]:
				halves[h] = true
			var image := _draw(halves, sheet)
			for h: Vector2i in halves:
				var width := _width(image, halves, h)
				if width < overall:
					overall = width
					worst = "act %d, %s, half %s" % [act, shape, h]
				if width < MIN_WIDTH:
					_check(false, "act %d, %s: half %s is only %d px of pale earth (masks around it: %s)"
						% [act, shape, h, width, _masks_around(halves, h)])
	print("  path width: minimum %d px of pale earth (%s)" % [overall, worst])
	print("test_path_width: %d failure(s)" % failures)
	quit(failures)

func _line(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var step := (b - a).sign()
	var at := a
	cells.append(at)
	while at != b:
		at += step
		cells.append(at)
	return cells

# The dual tiles as the game draws them: tile `at` at pixel at * 32 - 16, column = its corner mask.
func _draw(halves: Dictionary, sheet: Image) -> Image:
	var image := Image.create_empty(16 * 32 + MARGIN * 2, 14 * 32 + MARGIN * 2, false, Image.FORMAT_RGBA8)
	var tile := PathGenerator.DUAL_SIZE
	var done := {}
	for h: Vector2i in halves:
		for dy in 2:
			for dx in 2:
				var at := h + Vector2i(dx, dy)
				if done.has(at):
					continue
				done[at] = true
				var mask := PathGenerator.dual_mask(halves, at)
				image.blend_rect(sheet, Rect2i(Vector2i(mask * tile.x, 0), tile), at * tile.x - tile / 2 + Vector2i.ONE * MARGIN)
	return image

func _pale(image: Image, p: Vector2i) -> bool:
	if p.x < 0 or p.y < 0 or p.x >= image.get_width() or p.y >= image.get_height():
		return false
	var c := image.get_pixelv(p)
	return c.a > 0.5 and c.get_luminance() >= PALE

# Pale-earth pixels in a straight line through half `h`'s centre, across each way the ribbon runs there
# (a horizontal neighbour: measure up-down; a vertical one: left-right). The smaller one counts.
func _width(image: Image, halves: Dictionary, h: Vector2i) -> int:
	var centre := h * 32 + Vector2i(16, 16) + Vector2i.ONE * MARGIN
	var across: Array[Vector2i] = []
	if halves.has(h + Vector2i.LEFT) or halves.has(h + Vector2i.RIGHT):
		across.append(Vector2i.DOWN)
	if halves.has(h + Vector2i.UP) or halves.has(h + Vector2i.DOWN):
		across.append(Vector2i.RIGHT)
	var best := 9999
	for axis in across:
		var count := 1 if _pale(image, centre) else 0
		for sign: int in [-1, 1]:
			var p: Vector2i = centre + axis * sign
			while _pale(image, p):
				count += 1
				p += axis * sign
		best = mini(best, count)
	return best

func _masks_around(halves: Dictionary, h: Vector2i) -> Array:
	var masks := []
	for dy in 2:
		for dx in 2:
			masks.append(PathGenerator.dual_mask(halves, h + Vector2i(dx, dy)))
	return masks
