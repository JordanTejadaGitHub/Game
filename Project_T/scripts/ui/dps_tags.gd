extends Node2D
class_name DpsTags

# Warden DPS tags (screens_ui.md "Damage that means something"): a small "124 DPS ↑12%" under each
# attacking Warden, coloured by its rating (gold carrying, white fine, dim blue underused) with a star
# on the most improved. Setting "dps_tags": 0 = rests only (default: at rests, while paused and in build
# mode; during a drift only on the selected or hovered Warden), 1 = always, 2 = off. Clicking a tag
# selects that Warden and glides the camera to it. Numbers from Tower Code's WardenMeter. Made by the HUD.

const SETTING := "dps_tags"
const REFRESH := 0.5
const OFFSET := Vector2(0, 40)  # Under the Warden
const FONT_SIZE := 13
const TAG_SIZE := Vector2(96, 18)

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
		return _rows.values().map(func(r: Dictionary) -> Node: return r.tower)
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
	queue_redraw()

func tag_text(r: Dictionary) -> String:
	var change := DriftMeter.change_text(r.get("change"))
	return "%s DPS%s%s" % [DriftMeter.fmt(r.dps), " " + change if change != "" else "",
		" ★" if r.get("most_improved", false) else ""]

func _draw() -> void:
	var font := ThemeDB.fallback_font
	for tower in _shown_towers():
		if not is_instance_valid(tower) or not _rows.has(tower.get_instance_id()):
			continue
		var r: Dictionary = _rows[tower.get_instance_id()]
		var text := tag_text(r)
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		var at: Vector2 = tower.global_position + OFFSET + Vector2(-width / 2.0, 0)
		draw_rect(Rect2(at + Vector2(-4, -FONT_SIZE), Vector2(width + 8, FONT_SIZE + 5)), Color(0.02, 0.02, 0.05, 0.6))
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, DriftMeter.rating_color(r.get("rating_label", &"")))

# A click on a tag: select that Warden and glide to it.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var world := get_global_mouse_position()
	for tower in _shown_towers():
		if not is_instance_valid(tower):
			continue
		var centre: Vector2 = tower.global_position + OFFSET + Vector2(0, -FONT_SIZE / 2.0)
		if Rect2(centre - TAG_SIZE / 2.0, TAG_SIZE).has_point(world):
			DriftMeter.focus_tower(tower)
			get_viewport().set_input_as_handled()
			return
