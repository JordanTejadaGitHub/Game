class_name LessonDemo
extends Control

# Small looping explanations, drawn with the same palette as the paused lesson.
var topic := &""
var clock := 0.0

func _init() -> void:
	custom_minimum_size = Vector2(420, 82)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if is_visible_in_tree():
		clock = fmod(clock + delta / maxf(Engine.time_scale, 0.001), 4.0)
		queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	if topic == &"nurture":
		for i in 5:
			var at := Vector2(36 + i * 42, 26)
			draw_circle(at, 13, UiStyle.GOLD if i < mini(int(clock * 1.5), 4) else UiStyle.INK_DIM)
			draw_string(font, at + Vector2(-4, 5), "P" if i < 4 else "S", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UiStyle.FOG)
		draw_string(font, Vector2(252, 30), "4 matching → signature", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UiStyle.INK)
		draw_string(font, Vector2(22, 68), "Mixed picks → All-Rounder: main job +20%", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UiStyle.GOLD)
	elif topic == &"maze":
		# Path length only (maze_economy.md, user 2026-10-11): no Wardens in the picture. The forest's straight path
		# (faint), then a wall each second bending the road around it: each bend is CELLS_PER_DEW cells longer, and
		# the count beside it ticks up.
		var cells: int = DriftDirector.MAZE_ECONOMY.CELLS_PER_DEW
		var walls := mini(int(clock), 2)  # 0, 1, then 2 walls (held for the loop's last 2 s)
		draw_line(Vector2(22, 24), Vector2(350, 24), Color(UiStyle.INK_DIM, 0.3), 2.0)
		var road := PackedVector2Array([Vector2(22, 24)])
		for wall in walls:
			var x := 120.0 + wall * 120.0
			road.append_array(PackedVector2Array([Vector2(x - 20, 24), Vector2(x - 20, 50), Vector2(x + 20, 50), Vector2(x + 20, 24)]))
			draw_rect(Rect2(x - 9, 15, 18, 18), UiStyle.INK_DIM)  # The wall, on the old path
			draw_rect(Rect2(x - 9, 15, 18, 18), UiStyle.INK, false, 1.0)
		road.append(Vector2(350, 24))
		draw_polyline(road, UiStyle.INK_DIM, 8)
		var length := 0.0
		for i in road.size() - 1:
			length += road[i].distance_to(road[i + 1])
		draw_string(font, Vector2(360, 22), "+%d cells" % (walls * cells), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiStyle.INK)
		draw_string(font, Vector2(360, 42), "Dew +%d" % walls, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UiStyle.GOLD if walls > 0 else UiStyle.INK_DIM)
		var distance := (clock - floorf(clock)) * length  # A nightmare walks the road as it is now
		for i in road.size() - 1:
			var segment := road[i].distance_to(road[i + 1])
			if distance <= segment:
				draw_circle(road[i].lerp(road[i + 1], distance / segment), 5, UiStyle.INK)
				break
			distance -= segment
		draw_string(UiStyle.with_glyphs(font), Vector2(22, 78), "%s / %d extra cells · cap %d / block" % [UiStyle.dew_amount(1, true), DriftDirector.MAZE_ECONOMY.CELLS_PER_DEW, DriftDirector.MAZE_ECONOMY.BLOCK_CAP], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UiStyle.GOLD)
	elif topic == &"catch":
		var steps := ["Dispel", "Catch bowl", "Rest harvest", "Bank interest"]
		for i in 4:
			var x := 12 + i * 104
			draw_rect(Rect2(x, 12, 96, 36), Color(UiStyle.GOLD if i == int(clock) else UiStyle.INK_DIM, 0.2))
			draw_string(font, Vector2(x + 4, 34), steps[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiStyle.INK)
		draw_string(UiStyle.with_glyphs(font), Vector2(14, 76), "Best catcher counts · shared interest cap %s" % UiStyle.dew_amount(DewCatch.INTEREST_CAP), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UiStyle.GOLD)