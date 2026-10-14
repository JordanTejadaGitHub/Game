class_name LessonDemo
extends Control

# Small looping explanations, drawn with the same palette as the paused lesson. Everything is laid out inside this
# control's own rect (user 2026-10-13: "words come out of the card": the maze counters sat right of the path, against
# the card's edge): pictures on top, their numbers on a line under them, measured, never past the right edge. The
# control clips its drawing and reports what it drew (drawn_bounds) so a test can check it.
var topic := &""
var clock := 0.0
var drawn_bounds := Rect2()  # What the last _draw covered, in this control's space

const PAD := 12.0  # Left and right, inside the rect
const HEIGHTS := {&"nurture": 96.0, &"maze": 112.0, &"catch": 96.0}

func _init() -> void:
	custom_minimum_size = Vector2(420, 96)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	clip_contents = true

func _process(delta: float) -> void:
	if is_visible_in_tree():
		custom_minimum_size.y = HEIGHTS.get(topic, 96.0)
		clock = fmod(clock + delta / maxf(Engine.time_scale, 0.001), 4.0)
		queue_redraw()

# A string, noted in drawn_bounds. `right`: its right end sits at `at.x`.
func _text(font: Font, at: Vector2, text: String, font_size: int, colour: Color, right: bool = false) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var from := Vector2(at.x - width if right else at.x, at.y)
	draw_string(font, from, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)
	_note(Rect2(from.x, from.y - font_size, width, font_size * 1.3))

func _note(rect: Rect2) -> void:
	drawn_bounds = rect if drawn_bounds.size == Vector2.ZERO else drawn_bounds.merge(rect)

func _draw() -> void:
	drawn_bounds = Rect2()
	var font := UiStyle.with_glyphs(UiStyle.body_font())
	var left := PAD
	var right := size.x - PAD
	if topic == &"nurture":
		for i in 5:
			var at := Vector2(left + 14.0 + i * 42.0, 22.0)
			draw_circle(at, 13, UiStyle.GOLD if i < mini(int(clock * 1.5), 4) else UiStyle.INK_DIM)
			_note(Rect2(at - Vector2(13, 13), Vector2(26, 26)))
			draw_string(font, at + Vector2(-4, 5), "P" if i < 4 else "S", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UiStyle.FOG)
		_text(font, Vector2(left, 56.0), "P = a Power rank, S = a Swift rank", 12, UiStyle.INK_DIM)  # The legend
		_text(font, Vector2(left, 74.0), "Four Power → signature", 14, UiStyle.INK)
		_text(font, Vector2(left, 92.0), "Mixed ranks → All-Rounder: 20% stronger", 14, UiStyle.GOLD)
	elif topic == &"maze":
		# Path length only (maze_economy.md, user 2026-10-11): no Wardens in the picture. The forest's straight path
		# (faint), then a wall each second bending the path around it: each bend is CELLS_PER_DEW cells longer. The
		# path spans the rect's width; the two counters sit on one line under it, the rate under that.
		var cells: int = DriftDirector.MAZE_ECONOMY.CELLS_PER_DEW
		var walls := mini(int(clock), 2)  # 0, 1, then 2 walls (held for the loop's last 2 s)
		var span := right - left
		draw_line(Vector2(left, 20), Vector2(right, 20), Color(UiStyle.INK_DIM, 0.3), 2.0)
		var road := PackedVector2Array([Vector2(left, 20)])
		for wall in walls:
			var x := left + span * (0.33 + 0.34 * wall)
			road.append_array(PackedVector2Array([Vector2(x - 20, 20), Vector2(x - 20, 46), Vector2(x + 20, 46), Vector2(x + 20, 20)]))
			draw_rect(Rect2(x - 9, 11, 18, 18), UiStyle.INK_DIM)  # The wall, on the old path
			draw_rect(Rect2(x - 9, 11, 18, 18), UiStyle.INK, false, 1.0)
		road.append(Vector2(right, 20))
		draw_polyline(road, UiStyle.INK_DIM, 8)
		_note(Rect2(left, 7, span, 46))
		var length := 0.0
		for i in road.size() - 1:
			length += road[i].distance_to(road[i + 1])
		var distance := (clock - floorf(clock)) * length  # A nightmare walks the path as it is now
		for i in road.size() - 1:
			var segment := road[i].distance_to(road[i + 1])
			if distance <= segment:
				draw_circle(road[i].lerp(road[i + 1], distance / segment), 5, UiStyle.INK)
				break
			distance -= segment
		_text(font, Vector2(left, 76.0), "+%d cells" % (walls * cells), 14, UiStyle.INK)
		_text(font, Vector2(right, 76.0), "Maze bonus %s" % UiStyle.dew_amount(walls, true), 14, UiStyle.GOLD if walls > 0 else UiStyle.INK_DIM, true)
		_text(font, Vector2(left, 100.0), "%s per %d extra cells" % [UiStyle.dew_amount(1, true), cells], 13, UiStyle.INK_DIM)
	elif topic == &"catch":
		var steps := ["Dispelled", "Dew collected", "Paid at rest", "Wellsprings"]
		var gap := 6.0
		var box_width := (right - left - gap * 3.0) / 4.0
		for i in 4:
			var x := left + i * (box_width + gap)
			draw_rect(Rect2(x, 10, box_width, 34), Color(UiStyle.GOLD if i == int(clock) else UiStyle.INK_DIM, 0.2))
			_note(Rect2(x, 10, box_width, 34))
			draw_string(font, Vector2(x + 4, 32), steps[i], HORIZONTAL_ALIGNMENT_LEFT, box_width - 8.0, 12, UiStyle.INK)  # Trimmed to its box
		_text(font, Vector2(left, 66.0), "The strongest catcher in range counts.", 13, UiStyle.INK_DIM)
		_text(font, Vector2(left, 86.0), "All Wellsprings together pay at most %s a rest." % UiStyle.dew_amount(DewCatch.INTEREST_CAP), 13, UiStyle.GOLD)
