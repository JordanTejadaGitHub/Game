extends Node2D
class_name DpsTags

# Warden DPS tags (screens_ui.md "Damage that means something"): a small "124 dps ▲12%" under each
# attacking Warden, the number coloured by its rank on the board (top ~20% gold, middle white, bottom ~20% dim) with
# the Heartwood sprout on the most improved. No box: outlined text over a faint halo. Setting "dps_tags": 0 = rests only (default: at rests, while paused and in build
# mode; during a drift only on the selected or hovered Warden), 1 = always, 2 = off. Clicking a tag
# selects that Warden and glides the camera to it. Numbers from Tower Code's WardenMeter. Made by the HUD.

const SETTING := "dps_tags"
const REFRESH := 0.5
const FOOT_GAP := 2.0  # Screen px between the footprint and the tag
const FONT_SIZE := 16  # The number; "dps" and the change are smaller (below)

var drift_director: DriftDirector
var _rows := {}  # Tower instance id -> its meter row
var _clock := 0.0
var _placer: Node
var _seller: Node
var _speed: Node

func _ready() -> void:
	z_index = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	var main := get_parent()
	drift_director = main.get_node_or_null("%DriftDirector")
	_placer = main.get_node_or_null("%TowerPlacer")
	_seller = main.get_node_or_null("%TowerSeller")
	_speed = main.get_node_or_null("%GameSpeed")

static func mode() -> int:
	return int(Fx.setting(SETTING, 0))

# All tags show now (a rest, paused, build mode), or only the selected / hovered Warden's.
func all_shown() -> bool:
	if mode() == 1:
		return true
	return (drift_director != null and drift_director.is_resting()) or (_speed != null and _speed.paused) \
		or (_placer != null and _placer.build_mode)

func _shown_towers() -> Array:
	if mode() == 2 or drift_director == null or drift_director.drifts_started == 0:
		return []
	if all_shown():
		var all: Array = []
		for r in _rows.values():  # A sold Warden stays in _rows until the next refresh
			if is_instance_valid(r.tower):
				all.append(r.tower)
		return all
	var only: Array = []
	if _seller != null:
		for tower in _seller.selection:
			only.append(tower)
		var hovered = _seller.get("_hover_tower")
		if hovered != null and not only.has(hovered):
			only.append(hovered)
	return only

func _process(delta: float) -> void:
	_clock -= delta / maxf(Engine.time_scale, 0.001)
	if _clock <= 0.0:
		_clock = REFRESH
		_rows.clear()
		var meter := WardenMeter.find(self) if mode() != 2 else null
		if meter != null:
			var period := "drift" if not drift_director.is_resting() else "block"
			for r in meter.get_meter_rows(period):
				if is_instance_valid(r.tower) and not r.get("catcher", false):
					_rows[r.tower.get_instance_id()] = r
			# Rank on the board (highest DPS first) sets each tag's colour.
			var ranked := _rows.values()
			ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.dps > b.dps)
			for i in ranked.size():
				ranked[i]["tag_color"] = DriftMeter.rank_color(i, ranked.size())
	queue_redraw()

# Short ("182 DPS") unless `full`: the change vs last drift only on the selected / hovered Warden or with the
# damage meter open (user screenshot: dense clusters overlapped).
func tag_text(r: Dictionary, full: bool = true) -> String:
	var change := DriftMeter.change_text(r.get("change")) if full else ""
	return "%s DPS%s%s" % [DriftMeter.fmt(r.dps), " " + change if change != "" else "",
		" ★" if r.get("most_improved", false) else ""]

var drawn: Array = []  # [tower, world rect, text] of the tags drawn this frame (clicks, tests)

# The selected / hovered Wardens (their tags win a clash, and show the change).
func _focus() -> Array:
	var result: Array = []
	if _seller != null:
		result.append_array(_seller.selection)
		var hovered = _seller.get("_hover_tower")
		if hovered != null and not result.has(hovered):
			result.append(hovered)
	return result

# The damage meter is open with its rows: every tag shows its change.
func _meter_open() -> bool:
	var meter = get_parent().get_node_or_null("HUD/DriftMeter") if get_parent() != null else null
	return meter != null and meter.visible and bool(meter.get("_user_open")) and not bool(meter.get("collapsed"))

const TAG_H := FONT_SIZE + 5.0  # A tag's height, screen px
const UNIT_SIZE := 12  # "dps", small caps
const UNIT_GAP := 3.0
const CHANGE_SIZE := 13
const CHANGE_GAP := 6.0  # Before the arrow
const ARROW := Vector2(7.0, 6.0)
const ARROW_GAP := 2.0  # Arrow to its number
const MARK_GAP := 5.0  # Before the most-improved sprout
const MARK_SIZE := Vector2(7.0, 4.0) * MoonStyleBox.MARK_PX
const UP_COLOR := Palette.SPRIG
const DOWN_COLOR := Palette.EMBER
const UNIT_COLOR := Palette.MIST

# What a tag draws, left to right: the number, "dps", then (in full) the change and the most-improved sprout.
# `short` = the number alone. {number, unit, change (signed share, 0 = none), percent, star, width}
func tag_parts(r: Dictionary, full: bool, short: bool = false) -> Dictionary:
	var parts := {"number": DriftMeter.fmt(r.dps), "unit": not short, "change": 0.0, "percent": "", "star": false}
	var width := UiStyle.number_font().get_string_size(parts.number, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	if not short:
		width += UNIT_GAP + UiStyle.caps_font().get_string_size("dps", HORIZONTAL_ALIGNMENT_LEFT, -1, UNIT_SIZE).x
		var change = r.get("change")
		if full and change != null and absf(float(change)) >= 0.005:
			parts.change = float(change)
			parts.percent = "%d%%" % roundi(absf(float(change)) * 100.0)
			width += CHANGE_GAP + ARROW.x + ARROW_GAP \
				+ UiStyle.body_medium_font().get_string_size(parts.percent, HORIZONTAL_ALIGNMENT_LEFT, -1, CHANGE_SIZE).x
		if r.get("most_improved", false):
			parts.star = true
			width += MARK_GAP + MARK_SIZE.x
	parts["width"] = width
	return parts

# Every shown tag is drawn (user: "sometimes the maze DPS disappear": dense half-cell mazes skipped any tag that
# overlapped one already placed, so tags blinked as the ranking changed). Focus first (always in full, in place), then
# the rest in a fixed order (by cell, not by DPS, so nothing reshuffles when the numbers refresh). A tag that would
# overlap is nudged down or sideways (up to one tag height); still overlapping, it shrinks to its number ("124") and
# takes the spot that overlaps least. Only a tag under the open Warden panel is left out.
# The look (user-approved "Warden labels" redo, 2026-10-12): no box. The number in the rank colour, "dps" in small
# caps, both outlined, over a faint halo; the change as a drawn arrow and a percent; the Heartwood sprout on the most
# improved.
func _draw() -> void:
	var focus := _focus()
	var full_all := _meter_open()
	var s := WorldLabel.text_scale(self)
	var towers: Array = _shown_towers().filter(func(t) -> bool: return is_instance_valid(t) and _rows.has(t.get_instance_id()))
	towers.sort_custom(func(a, b) -> bool:
		var fa := focus.has(a)
		var fb := focus.has(b)
		if fa != fb:
			return fa
		var pa: Vector2 = a.global_position
		var pb: Vector2 = b.global_position
		return pa.y < pb.y if not is_equal_approx(pa.y, pb.y) else pa.x < pb.x)
	drawn.clear()
	var places: Array = []
	for tower in towers:
		var r: Dictionary = _rows[tower.get_instance_id()]
		var in_focus := focus.has(tower)
		# The tag's top sits just under the footprint's bottom edge (user: "4 DPS" over a Sprout's plinth): the baseline
		# is a text height lower, at screen size. Bigger footprints (2×2) reach further down.
		var bottom: float = tower.global_position.y + 32.0 * maxi(int(tower.tower_data.footprint), 1)
		var base := Vector2(tower.global_position.x, bottom + (FOOT_GAP + FONT_SIZE) * s)
		var place := _place(s, base, r, full_all or in_focus, in_focus)
		if place.is_empty():
			continue  # Under the open Warden panel
		drawn.append([tower, place.rect, place.text])
		place["color"] = r.get("tag_color", DriftMeter.FINE_COLOR)
		places.append(place)
	# Every halo first: a neighbour's halo never dims a tag's text.
	for place in places:
		var at: Vector2 = place.anchor + Vector2(-place.width / 2.0, 0)
		WorldLabel.begin_screen_size(self, place.anchor)  # Keeps its screen size when zoomed in
		WorldLabel.draw_halo(self, Rect2(at + Vector2(0, -FONT_SIZE + 3.0), Vector2(place.width, FONT_SIZE)))
		WorldLabel.end_screen_size(self)
	for place in places:
		WorldLabel.begin_screen_size(self, place.anchor)
		_draw_parts(place.anchor + Vector2(-place.width / 2.0, 0), place.parts, place.color)
		WorldLabel.end_screen_size(self)

# One tag's parts from `at` (left end, on the baseline).
func _draw_parts(at: Vector2, parts: Dictionary, color: Color) -> void:
	var number_font := UiStyle.number_font()  # Moonlit Thread: numbers in Cormorant, lining figures
	WorldLabel.draw_outlined(self, number_font, at, parts.number, FONT_SIZE, color)
	var x := at.x + number_font.get_string_size(parts.number, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	if not parts.unit:
		return
	var caps := UiStyle.caps_font()
	x += UNIT_GAP
	WorldLabel.draw_outlined(self, caps, Vector2(x, at.y), "dps", UNIT_SIZE, UNIT_COLOR)
	x += caps.get_string_size("dps", HORIZONTAL_ALIGNMENT_LEFT, -1, UNIT_SIZE).x
	if parts.percent != "":
		var up: bool = parts.change > 0.0
		var ink: Color = UP_COLOR if up else DOWN_COLOR
		x += CHANGE_GAP
		# The arrow sits on the figures' middle: ▲ up, ▼ down.
		var top := at.y - 8.0
		var arrow := PackedVector2Array([Vector2(x, top + ARROW.y), Vector2(x + ARROW.x / 2.0, top), Vector2(x + ARROW.x, top + ARROW.y)]) if up \
			else PackedVector2Array([Vector2(x, top), Vector2(x + ARROW.x, top), Vector2(x + ARROW.x / 2.0, top + ARROW.y)])
		var edge := arrow.duplicate()
		edge.append(arrow[0])
		draw_polyline(edge, WorldLabel.OUTLINE, 2.0)
		draw_colored_polygon(arrow, ink)
		x += ARROW.x + ARROW_GAP
		var bold := UiStyle.body_medium_font()
		WorldLabel.draw_outlined(self, bold, Vector2(x, at.y), parts.percent, CHANGE_SIZE, ink)
		x += bold.get_string_size(parts.percent, HORIZONTAL_ALIGNMENT_LEFT, -1, CHANGE_SIZE).x
	if parts.star:
		x += MARK_GAP
		MoonStyleBox.draw_mark(get_canvas_item(), Vector2(x + MARK_SIZE.x / 2.0, at.y - 5.0))  # The 7×4 Heartwood sprout

# Where a tag goes: {text, parts, width, anchor, rect (world)}, or {} under the Warden panel. The focus tag stays in place.
func _place(s: float, base: Vector2, r: Dictionary, full: bool, in_focus: bool) -> Dictionary:
	var text := tag_text(r, full)
	var candidates: Array = [[text, tag_parts(r, full)]]
	if not in_focus:
		candidates.append([text.split(" ")[0], tag_parts(r, full, true)])  # The number alone ("124"): a smaller tag
	var best := {}
	var best_overlap := INF
	for candidate in candidates:
		var width: float = candidate[1].width
		var side := (width / 2.0 + 6.0) * s
		var nudges: Array = [Vector2.ZERO] if in_focus else [Vector2.ZERO, Vector2(0, TAG_H * s), Vector2(-side, 0), Vector2(side, 0),
			Vector2(-side, TAG_H * s), Vector2(side, TAG_H * s)]
		for nudge in nudges:
			var anchor: Vector2 = base + nudge
			# Its rect in world units (drawn at screen size: the text scale shrinks it as the camera zooms in)
			var rect := Rect2(anchor + Vector2(-width / 2.0 - 4.0, -FONT_SIZE) * s, Vector2(width + 8.0, TAG_H) * s)
			if nudge == Vector2.ZERO and WorldLabel.covered(self, Rect2(to_local(rect.position), rect.size)):
				return {}  # Under the open Warden panel (it's see-through: the tag read through its text)
			var overlap := 0.0
			for d in drawn:
				var other := (d[1] as Rect2).intersection(rect)
				overlap += other.get_area() if other.has_area() else 0.0
			var place := {"text": candidate[0], "parts": candidate[1], "width": width, "anchor": anchor, "rect": rect}
			if overlap <= 0.0:
				return place
			if overlap < best_overlap:
				best_overlap = overlap
				best = place
	return best  # Crowded all round: the number alone where it overlaps least, never hidden

# A click on a tag: select that Warden and glide to it.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var world := get_global_mouse_position()
	for d in drawn:  # The tags actually drawn (a skipped one can't be clicked)
		var tower = d[0]
		if is_instance_valid(tower) and (d[1] as Rect2).has_point(world):
			DriftMeter.focus_tower(tower)
			get_viewport().set_input_as_handled()
			return
