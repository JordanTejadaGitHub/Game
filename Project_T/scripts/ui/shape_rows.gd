extends VBoxContainer

# Drift shapes in the Coming strip (enemy_design.md "Drift shapes", owner 2026-10-24; Enemy Code's DriftShapes): at a
# rest, one row per drift of the next block: the shape's glyph, its fact line and where the Deeply Blighted ride:
#   "Drift 31 · Packs: 4 × 7, 6 s apart · Deeply Blighted in a pack"
#   "Drift 32 · Single file: 18, 1.6 s apart · Deeply Blighted last in line"
# Numbers only once the rest's Omen is picked (the Omen changes them); before that just the shape. Hover a row (PC) or
# tap it (phones) for its arrival timeline: one dot per nightmare, sized by health. Facts only: never "good against",
# grades or build hints. Built by ComingStrip (preloaded: no class_name).

const ROW_TEXT := 14
const GLYPH := Vector2(26, 14)
const TIMELINE := Vector2(300, 46)

var _director: DriftDirector
var _timeline := PanelContainer.new()
var _dots := Control.new()
var _shown_for := -1  # The drift whose timeline is open (-1 = none)
var _schedules := {}  # Drift -> its previewed schedule (DriftDirector.preview_schedule)

func _ready() -> void:
	name = "ShapeRows"
	add_theme_constant_override("separation", 2)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_timeline.name = "Timeline"
	_timeline.add_theme_stylebox_override("panel", UiStyle.plate_box(8.0, 6.0))
	_timeline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timeline.visible = false
	_dots.custom_minimum_size = TIMELINE
	_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dots.draw.connect(_draw_timeline)
	_timeline.add_child(_dots)

# "pending:omen id": the rows rebuild when the Omen is picked (ComingStrip folds this into its build key).
static func omen_key(director: DriftDirector) -> String:
	if director == null:
		return ""
	var omens := director.get_tree().get_first_node_in_group(OmenDirector.GROUP) if director.is_inside_tree() else null
	var active = omens.get("active") if omens != null else null
	return "%s:%s" % [director.pending_choice(), active.resource_path if active is Resource else ""]

func has_rows() -> bool:
	return get_child_count() > 1

# The rows for drifts `span` (a rest: the next block); none in a drift (`compact`).
func build(director: DriftDirector, span: Vector2i, compact: bool) -> void:
	_director = director
	for child in get_children():
		if child != _timeline:
			remove_child(child)
			child.queue_free()
	_schedules.clear()
	_shown_for = -1
	_timeline.visible = false
	if _timeline.get_parent() == null:
		add_child(_timeline)
	if compact or director == null or span.y < span.x:
		return
	var numbers := director.pending_choice() != &"omen"  # The Omen changes the counts: numbers once it's chosen
	for number in range(span.x, span.y + 1):
		var preview := director.preview_schedule(number)
		if preview.is_empty():
			continue
		var schedule: Array = preview.schedule
		_schedules[number] = schedule
		var boss := schedule.any(func(a: Array) -> bool: return a[1].is_boss)
		var text := "Drift %d · %s" % [number, "Boss" if boss else (fact_line(preview.facts) if numbers else DriftShapes.display_name(preview.shape))]
		var where := elite_line(preview.facts) if numbers and not boss else ""
		if where != "":
			text += " · " + where
		add_child(_row(number, StringName(preview.shape) if not boss else &"", text))
	move_child(_timeline, get_child_count() - 1)

# "Stream: 30", "Packs: 4 × 7, 6 s apart", "Single file: 18, 1.6 s apart", "Few and tough: 9, 4 Deeply Blighted".
static func fact_line(facts: Dictionary) -> String:
	var count := int(facts.get("count", 0))
	match StringName(facts.get("shape", DriftShapes.STREAM)):
		DriftShapes.PACKS:
			return "Packs: %d × %d, %d s apart" % [int(facts.packs), int(facts.pack_size), roundi(float(facts.gap_s))]
		DriftShapes.SINGLE_FILE:
			return "Single file: %d, %.1f s apart" % [count, float(facts.gap_s)]
		DriftShapes.FEW_AND_TOUGH:
			return "Few and tough: %d, %d Deeply Blighted" % [count, int(facts.elites)]
	return "Stream: %d" % count

# Act `act`'s shapes as they will arrive, as facts (the drift 45 capstone screen; enemy_design.md "Drift shapes"): "Act 3: 4 Packs,
# 4 Single file, 4 Few and tough, finales Packs / Single file / Few and tough". Finales = each ordinary block's 5th drift.
# "" before any shape is rolled.
static func act_line(director: DriftDirector, act: int) -> String:
	if director == null or not director.has_method("shape_of"):
		return ""
	var per_act := director.drifts_per_act
	var first := (act - 1) * per_act + 1
	var last := mini(act * per_act, director.get_total_drifts())
	var counts := {}
	var finales: Array[String] = []
	for number in range(first, last + 1):
		if director.is_boss_drift(number):
			continue
		var shape := StringName(director.preview_schedule(number).get("shape", DriftShapes.STREAM))  # As it really arrives (Enemy Code c7bde1ee: a Packs drift too crowded for packs is a Stream)
		if shape != DriftShapes.STREAM:
			counts[shape] = int(counts.get(shape, 0)) + 1
		if number % director.drifts_per_block == 0:  # An ordinary block's 5th drift (boss drifts are skipped above)
			finales.append(DriftShapes.display_name(shape))
	if counts.is_empty():
		return ""
	var parts: Array[String] = []
	for shape in [DriftShapes.PACKS, DriftShapes.SINGLE_FILE, DriftShapes.FEW_AND_TOUGH]:
		parts.append("%d %s" % [int(counts.get(shape, 0)), DriftShapes.display_name(shape)])
	return "Act %d: %s%s" % [act, ", ".join(parts), (", finales " + " / ".join(finales)) if not finales.is_empty() else ""]

# Where the Deeply Blighted ride: "Deeply Blighted in a pack" / "last in line" / "first"; "" with none (or anywhere).
static func elite_line(facts: Dictionary) -> String:
	if int(facts.get("elites", 0)) <= 0:
		return ""
	match String(facts.get("elite_place", "")):
		"pack":
			return "Deeply Blighted in a pack"
		"last":
			return "Deeply Blighted last in line"
		"first":
			return "Deeply Blighted first"
	return ""

func _row(number: int, shape: StringName, text: String) -> Control:
	var row := HBoxContainer.new()
	row.name = "Drift%d" % number
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.set_meta(&"drift", number)
	var glyph := Control.new()
	glyph.custom_minimum_size = GLYPH
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.draw.connect(draw_glyph.bind(glyph, shape))
	row.add_child(glyph)
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", ROW_TEXT)
	label.add_theme_color_override("font_color", UiStyle.INK)
	row.add_child(label)
	row.tooltip_text = ""  # The timeline is its own popup
	row.mouse_entered.connect(func() -> void:
		if not TouchBuild.is_touch():
			_show_timeline(number))
	row.mouse_exited.connect(func() -> void:
		if not TouchBuild.is_touch() and _shown_for == number:
			_show_timeline(-1))
	row.gui_input.connect(func(event: InputEvent) -> void:  # A tap (phones, or a click) opens or closes it
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_show_timeline(-1 if _shown_for == number else number)
			row.accept_event())
	return row

# The shape's glyph (no art yet: dots): Stream evenly spaced, Packs in clumps, Single file wide apart, Few and tough big.
static func draw_glyph(canvas: Control, shape: StringName) -> void:
	var h := canvas.size.y / 2.0
	var ink := UiStyle.INK_DIM
	match shape:
		DriftShapes.PACKS:
			for x in [3.0, 6.5, 10.0, 16.0, 19.5, 23.0]:
				canvas.draw_circle(Vector2(x, h), 1.8, ink)
		DriftShapes.SINGLE_FILE:
			for x in [3.0, 13.0, 23.0]:
				canvas.draw_circle(Vector2(x, h), 1.8, ink)
		DriftShapes.FEW_AND_TOUGH:
			for x in [6.0, 19.0]:
				canvas.draw_circle(Vector2(x, h), 4.0, ink)
		&"":  # A boss drift: one big dot
			canvas.draw_circle(Vector2(13.0, h), 5.0, UiStyle.BOSS)
		_:  # Stream
			for x in [3.0, 8.0, 13.0, 18.0, 23.0]:
				canvas.draw_circle(Vector2(x, h), 1.8, ink)

func _show_timeline(number: int) -> void:
	_shown_for = number if _schedules.has(number) else -1
	_timeline.visible = _shown_for >= 0
	if _shown_for >= 0:
		var row := get_node_or_null("Drift%d" % number)
		if row != null:
			move_child(_timeline, row.get_index() + 1)  # Right under its row
		_dots.queue_redraw()

# One dot per nightmare along the drift's arrival, x by its time, radius by its health (the Deeply Blighted ×3 and
# ringed), on a thin line from the first arrival to the last.
func _draw_timeline() -> void:
	var schedule: Array = _schedules.get(_shown_for, [])
	if schedule.is_empty():
		return
	var first := float(schedule[0][0])
	var span := maxf(float(schedule[-1][0]) - first, 0.001)
	var most := 1.0
	for arrival in schedule:
		most = maxf(most, _health(arrival))
	var y := TIMELINE.y / 2.0
	var pad := 8.0
	_dots.draw_line(Vector2(pad, y), Vector2(TIMELINE.x - pad, y), Color(UiStyle.INK_DIM, 0.4), 1.0)
	for arrival in schedule:
		var x := pad + (float(arrival[0]) - first) / span * (TIMELINE.x - pad * 2.0)
		var r := 2.0 + 6.0 * sqrt(_health(arrival) / most)
		var elite: bool = arrival.size() > 2 and bool(arrival[2])
		_dots.draw_circle(Vector2(x, y), r, UiStyle.BOSS if arrival[1].is_boss else UiStyle.INK)
		if elite:
			_dots.draw_arc(Vector2(x, y), r + 1.5, 0.0, TAU, 16, UiStyle.POOR, 1.5)  # Deeply Blighted: a ring

static func _health(arrival: Array) -> float:
	var data: EnemyData = arrival[1]
	return float(data.health) * (3.0 if arrival.size() > 2 and bool(arrival[2]) else 1.0)  # Deeply Blighted: ×3
