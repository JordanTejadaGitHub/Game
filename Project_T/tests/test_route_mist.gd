extends SceneTree

# Route mist (screens_ui.md "Route mist"): the route previews draw the mist strip with caps, the old route faint where
# it differs, a glint once when the route gets longer; the high-contrast setting keeps its line; clear() hides it all.

var failures := 0

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok: ", what)
	else:
		failures += 1
		push_error("FAIL: " + what)

func _initialize() -> void:
	_run.call_deferred()

func _cells(list: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for c in list:
		out.append(Vector2(c[0], c[1]))
	return out

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_route_mist_%d.json" % OS.get_process_id()
	_check(RouteLine.has_mist(), "the mist art is there")
	var line := Line2D.new()
	root.add_child(line)
	RouteLine._high = 0
	var old := _cells([[1, 1], [2, 1], [3, 1], [4, 1], [5, 1]])
	var longer := _cells([[1, 1], [2, 1], [2, 2], [3, 2], [4, 2], [4, 1], [5, 1]])
	RouteLine.draw_route(line, longer, Color.WHITE, 6.0, old)
	var extras := line.get_node_or_null("MistExtras")
	_check(line.points.size() == longer.size() and line.texture != null and line.texture_mode == Line2D.LINE_TEXTURE_TILE
		and is_equal_approx(line.width, 24.0), "the new route is the tiled mist strip, 24 wide")
	_check(extras != null and extras.visible and extras.get_node("Start").texture != null and extras.get_node("End").texture != null,
		"with its start and end caps")
	var end_cap: Sprite2D = extras.get_node("End")
	_check(end_cap.position.distance_to(line.points[-1]) > 1.0 and is_equal_approx(end_cap.rotation, 0.0),
		"the end cap sits past the last point, facing on (%s, %.2f)" % [end_cap.position, end_cap.rotation])
	_check(extras.get_node("Old").get_child_count() == 1, "the old route shows where it differs (one stretch)")
	var old_wisp: Line2D = extras.get_node("Old").get_child(0)
	_check(old_wisp.points.size() == 3 and old_wisp.default_color.a < 0.5, "faint, joined to the shared cells (%d points)" % old_wisp.points.size())
	_check(extras.get_node("Glint").get_child_count() == 1, "a longer route glints along its new stretch")
	var material := line.material as ShaderMaterial
	_check(material != null and float(material.get_shader_parameter(&"speed")) > 0.0, "the mist flows toward the Heartwood")
	RouteLine.draw_route(line, longer, Color.WHITE, 6.0, old)
	await process_frame
	_check(extras.get_node("Glint").get_child_count() == 1 and line.material == material, "…once (the same route again doesn't re-glint; the material is kept)")
	RouteLine.draw_route(line, old, Color.WHITE, 6.0, old)
	await process_frame
	_check(extras.get_node("Old").get_child_count() == 0 and extras.get_node("Glint").get_child_count() == 0,
		"an unchanged route: no old wisp, no glint")

	RouteLine.clear(line)
	_check(line.points.is_empty() and not extras.visible, "clear() hides the caps and wisps too")

	RouteLine._high = 1
	RouteLine.draw_route(line, longer, Color.WHITE, 6.0, old)
	_check(line.texture == null and line.default_color == RouteLine.CONTRAST_COLOR and line.width == RouteLine.CONTRAST_WIDTH
		and not extras.visible, "high-contrast keeps its bright, thick line")
	RouteLine._high = -1

	line.queue_free()
	await process_frame
	print("PASS" if failures == 0 else "FAILURES: %d" % failures)
	quit(failures)
