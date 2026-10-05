extends Node2D
class_name DpsTags

# Warden DPS tags (screens_ui.md "Damage that means something"): a small "124 DPS ↑12%" under each
# attacking Warden, coloured by its rank on the board (top ~20% gold, middle white, bottom ~20% dim) with a star
# on the most improved. Setting "dps_tags": 0 = rests only (default: at rests, while paused and in build
# mode; during a drift only on the selected or hovered Warden), 1 = always, 2 = off. Clicking a tag
# selects that Warden and glides the camera to it. Numbers from Tower Code's WardenMeter. Made by the HUD.

const SETTING := "dps_tags"
const REFRESH := 0.5
const FOOT_GAP := 2.0  # Screen px between the footprint and the tag
const FONT_SIZE := 15

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

# Every shown tag is drawn (user: "sometimes the maze DPS disappear": dense half-cell mazes skipped any tag that
# overlapped one already placed, so tags blinked as the ranking changed). Focus first (always in full, in place), then
# the rest in a fixed order (by cell, not by DPS, so nothing reshuffles when the numbers refresh). A tag that would
# overlap is nudged down or sideways (up to one tag height); still overlapping, it shrinks to its number ("124") and
# takes the spot that overlaps least. Only a tag under the open Warden panel is left out.
func _draw() -> void:
	var font := UiStyle.number_font()  # Moonlit Thread: numbers in Cormorant, lining figures
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
	for tower in towers:
		var r: Dictionary = _rows[tower.get_instance_id()]
		var in_focus := focus.has(tower)
		# The tag's top sits just under the footprint's bottom edge (user: "4 DPS" over a Sprout's plinth): the baseline
		# is a text height lower, at screen size. Bigger footprints (2×2) reach further down.
		var bottom: float = tower.global_position.y + 32.0 * maxi(int(tower.tower_data.footprint), 1)
		var base := Vector2(tower.global_position.x, bottom + (FOOT_GAP + FONT_SIZE) * s)
		var place := _place(font, s, base, tag_text(r, full_all or in_focus), in_focus)
		if place.is_empty():
			continue  # Under the open Warden panel
		var text: String = place.text
		var width: float = place.width
		var anchor: Vector2 = place.anchor
		drawn.append([tower, place.rect, text])
		var at: Vector2 = anchor + Vector2(-width / 2.0, 0)
		WorldLabel.begin_screen_size(self, anchor)  # Keeps its screen size when zoomed in
		draw_rect(Rect2(at + Vector2(-4, -FONT_SIZE), Vector2(width + 8, TAG_H)), Color(UiStyle.FOG, 0.65))
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, r.get("tag_color", DriftMeter.FINE_COLOR))
		WorldLabel.end_screen_size(self)

# Where a tag goes: {text, width, anchor, rect (world)}, or {} under the Warden panel. The focus tag stays in place.
func _place(font: Font, s: float, base: Vector2, text: String, in_focus: bool) -> Dictionary:
	var texts: Array[String] = [text]
	var number := text.split(" ")[0]
	if not in_focus and number != text:
		texts.append(number)  # The number alone ("124"): a smaller tag
	var best := {}
	var best_overlap := INF
	for candidate in texts:
		var width := font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
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
			var place := {"text": candidate, "width": width, "anchor": anchor, "rect": rect}
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
