extends Node2D
class_name BuffOverlay

# Buff readability on the map (screens_ui.md "Buff readability"), all from BuffSources:
# - Buff pips: a row of small shapes under a Warden, one per local source kind with a count (×3). Shown
#   at rests, while paused, in build mode and with the lens on; otherwise only on the hovered / selected one.
# - Source threads: hovering or selecting a Warden draws a thin line from every Warden buffing it, labelled
#   with its share ("+20%", "+10% (2nd)", "Kindred +26%"); relays through Thornwalls bend at the wall. A
#   selected support Warden draws threads out to everyone it covers, with what it adds there ("—" = nothing).
# - Buff lens (Main's BuffLens: the HUD toggle and V set it; this node joins BuffLens.GROUP): every aura
#   area tinted by kind, every Warden's pips, and Wardens shaded by how boosted they are.
# Made by TowerSeller in the run's scene; drawn on the ground (under Wardens and nightmares).

const GROUP := &"buff_overlay"
const REDRAW_EVERY := 0.5  # Seconds between refreshes of the hovered / selected Warden's threads
const SIGNATURE_EVERY := 1.0  # Seconds between checks that the board's buffs changed (pips at rests)
const PIP_RADIUS := 4.5
const PIP_STEP := 13.0
const PIP_Y := 36.0  # Below the Warden's cell centre
const THREAD_WIDTH := 1.5
const LENS_FILL := 0.1

static var lens := false

signal lens_changed(on: bool)

var seller: TowerSeller
var placer: TowerPlacer
var director: DriftDirector
var container: Node
var _redraw_left := 0.0
var _last_key := []
var _signature := 0
var _signature_left := 0.0

# What the pips depend on, cheaply: each Warden's form, rank and aura sources.
func _board_signature() -> int:
	var parts := []
	for tower in _towers():
		parts.append([tower.tower_data.get_instance_id(), tower.rank, tower._aura_sources.size()])
	return parts.hash()

static func find(near: Node) -> BuffOverlay:
	if near == null or not near.is_inside_tree():
		return null
	return near.get_tree().get_first_node_in_group(GROUP) as BuffOverlay

func _init() -> void:
	add_to_group(GROUP)
	add_to_group(BuffLens.GROUP)  # BuffLens.set_on calls set_lens on every change
	lens = BuffLens.on
	# Pips, threads and the lens markers draw above the Wardens (z 7: over the lighting, 3, and the ambience, 6);
	# under the Wardens the next row's overhanging sprites hid them (Main: "toggling Boosts doesn't change
	# anything"). Only the lens' aura tint stays on the ground (_ground).
	z_index = 7
	_ground.name = "LensGround"
	_ground.z_as_relative = false
	_ground.z_index = -1
	_ground.draw.connect(_draw_ground)
	add_child(_ground)
	process_mode = Node.PROCESS_MODE_ALWAYS  # Paused: the pips show

func set_lens(on: bool) -> void:
	lens = on
	lens_changed.emit(on)
	queue_redraw()
	_ground.queue_redraw()

# Performance (test_perf_stress: redrawing every Warden's pips every 0.2 s cost ~75 ms spikes): redraw when
# what's asked about changes (lens, rest / pause / build mode, hovered / selected Warden, the board), and
# only the hovered / selected Warden's threads refresh on a timer.
func _process(delta: float) -> void:
	_redraw_left -= delta
	var focus := _focus()
	_signature_left -= delta
	if _signature_left <= 0.0:
		_signature_left = SIGNATURE_EVERY
		_signature = _board_signature()
	var key := [lens, _show_all(), focus, _signature]
	if key != _last_key or (_redraw_left <= 0.0 and not focus.is_empty()):
		_last_key = key
		_redraw_left = REDRAW_EVERY
		queue_redraw()
		_ground.queue_redraw()

func _show_all() -> bool:
	return lens or (director != null and director.is_resting()) or get_tree().paused \
		or (placer != null and placer.build_mode)

# The Wardens the player is asking about: the selected one and the hovered one.
func _focus() -> Array:
	var result := []
	if seller == null:
		return result
	if seller.selection.size() == 1 and is_instance_valid(seller.selected):
		result.append(seller.selected)
	if is_instance_valid(seller._hover_tower) and not result.has(seller._hover_tower):
		result.append(seller._hover_tower)
	return result

func _anything_shown() -> bool:
	return _show_all() or not _focus().is_empty()

func _towers() -> Array:
	if container == null:
		return []
	return container.get_children().filter(func(t) -> bool: return t is Tower and not t.is_queued_for_deletion())

var _ground := Node2D.new()
var drawn_pips := 0  # Pip rows and lens markers drawn last frame (tests)
var drawn_markers := 0

func _draw_ground() -> void:
	if lens:
		_draw_lens_areas(_towers())

func _draw() -> void:
	var towers := _towers()
	drawn_pips = 0
	drawn_markers = 0
	if lens:
		_draw_lens(towers)
	var focus := _focus()
	for tower in focus:
		_draw_threads_in(tower)
		if AuraView.is_aura(tower.tower_data):
			_draw_threads_out(tower)
	var with_pips: Array = towers if _show_all() else focus
	for tower in with_pips:
		_draw_pips(tower)

# --- Pips --------------------------------------------------------------------------------------------

func _draw_pips(tower: Tower) -> void:
	var rows := BuffSources.pips(tower)
	if rows.is_empty():
		return
	drawn_pips += 1
	var at := to_local(tower.global_position) + Vector2(-(rows.size() - 1) * PIP_STEP / 2.0, PIP_Y)
	WorldLabel.begin_screen_size(self, at + Vector2((rows.size() - 1) * PIP_STEP / 2.0, 0.0))  # Screen size when zoomed in
	var font := ThemeDB.fallback_font
	for row in rows:
		var colour := BuffSources.color(row[0], row[2])
		draw_pip(self, at, row[0], colour)
		if row[1] > 1:
			draw_stacks(self, at + Vector2(PIP_RADIUS, 1), row[1], colour, font)
		at.x += PIP_STEP
	WorldLabel.end_screen_size(self)

# UI Asset's pip art (c2a2a600, assets/ui/buff_pips.json): 10 px pips, one shape per kind in its colour;
# kinship (a leaf) and penalty (a down chevron) are grey, tinted here (family colour; Bruise). ×1 on the map.
const PIP_SHEET := "res://assets/ui/buff_pips.png"
const STACK_SHEET := "res://assets/ui/buff_stacks.png"
const PIP_FRAMES := {"acorn": 0, "elder_stump": 1, "grove_heart": 2, "grandmother_oak": 3, "old_growth": 4,
	"kinship": 5, "kindred": 6, "whole_tree": 7, "penalty": 8}
const PIP_TINTED := ["kinship", "penalty"]
const PIP_FRAME := 10
const STACK_SIZE := Vector2(9, 7)  # x2..x9 badges, frames 0..7

# One pip: a shape per kind (not only a colour, for accessibility). Shared with the HUD legend. The sheet's
# art when it has the kind; otherwise the drawn shape below.
static func draw_pip(canvas: CanvasItem, at: Vector2, kind: String, colour: Color, r: float = PIP_RADIUS) -> void:
	if PIP_FRAMES.has(kind) and ResourceLoader.exists(PIP_SHEET):
		var scale := maxf(roundf(r * 2.0 / PIP_FRAME), 1.0)  # Whole-pixel scale (r 4.5 = ×1)
		var side := Vector2(PIP_FRAME, PIP_FRAME) * scale
		var tint: Color = colour if PIP_TINTED.has(kind) else Color.WHITE  # A multiplier on the grey art
		canvas.draw_texture_rect_region(load(PIP_SHEET), Rect2(at - side / 2.0, side),
			Rect2(int(PIP_FRAMES[kind]) * PIP_FRAME, 0, PIP_FRAME, PIP_FRAME), tint)
		return
	var dark := Color(Palette.DREAD, 0.85)
	canvas.draw_circle(at, r + 1.5, dark)
	match kind:
		"acorn":
			canvas.draw_circle(at + Vector2(0, 0.8), r * 0.75, colour)
			canvas.draw_rect(Rect2(at + Vector2(-r * 0.8, -r * 0.9), Vector2(r * 1.6, r * 0.6)), colour.darkened(0.3))
		"elder_stump":
			canvas.draw_rect(Rect2(at - Vector2(r, r) * 0.75, Vector2(r, r) * 1.5), colour)
		"grove_heart":
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -r), at + Vector2(r, 0), at + Vector2(0, r),
				at + Vector2(-r, 0)]), colour)
		"grandmother_oak":
			var points := PackedVector2Array()
			for i in 6:
				points.append(at + Vector2.from_angle(TAU * i / 6.0) * r)
			canvas.draw_colored_polygon(points, colour)
		"old_growth":
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -r), at + Vector2(r, r * 0.8),
				at + Vector2(-r, r * 0.8)]), colour)
		"kinship":
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -r), at + Vector2(r * 0.7, 0), at + Vector2(0, r),
				at + Vector2(-r * 0.7, 0)]), colour)
			canvas.draw_line(at + Vector2(0, -r), at + Vector2(0, r), dark, 1.0)
		"whole_tree", "kindred":
			var star := PackedVector2Array()
			for i in 10:
				star.append(at + Vector2.from_angle(-PI / 2.0 + TAU * i / 10.0) * (r if i % 2 == 0 else r * 0.45))
			canvas.draw_colored_polygon(star, colour)
		_:
			canvas.draw_circle(at, r * 0.7, colour)

# A stack badge (x2..x9; 9 or more = x9) to the pip's right, its top-left at `at`; text without the art.
static func draw_stacks(canvas: CanvasItem, at: Vector2, count: int, colour: Color, font: Font) -> void:
	if ResourceLoader.exists(STACK_SHEET):
		var frame := clampi(count, 2, 9) - 2
		canvas.draw_texture_rect_region(load(STACK_SHEET), Rect2(at, STACK_SIZE),
			Rect2(frame * STACK_SIZE.x, 0, STACK_SIZE.x, STACK_SIZE.y))
		return
	canvas.draw_string(font, at + Vector2(0, 8), "×%d" % count, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, colour)

# --- Threads -----------------------------------------------------------------------------------------

# Every Warden buffing `tower`, joined to it and labelled with its share.
func _draw_threads_in(tower: Tower) -> void:
	var seen := {}
	for entry in BuffSources.for_tower(tower):
		var source = entry.source
		if not (source is Tower) or not is_instance_valid(source) or entry.stat == "":
			continue
		if entry.kind == "kinship":
			continue  # Kinships draws the bond itself (the root); a straight thread on top read as "string"
		var key := "%d|%s" % [source.get_instance_id(), entry.kind]
		if seen.has(key):
			seen[key].amount += entry.amount  # Damage and attack speed from one giver: one thread
			continue
		seen[key] = entry.duplicate()
	for key in seen:
		var entry: Dictionary = seen[key]
		_thread(entry.source, tower, BuffSources.color(entry.kind, entry.source), BuffSources.thread_label(entry),
			entry.relayed, 1.0)

# A selected support Warden: threads out to everyone it covers ("—" where it adds nothing).
func _draw_threads_out(support: Tower) -> void:
	for given in BuffSources.given_by(support):
		var amount: float = maxf(given.damage, given.speed)
		var label := "—" if amount <= 0.0 else BuffSources.thread_label({"amount": amount, "position": given.position,
			"kindred": given.kindred})
		_thread(support, given.target, BuffSources.color(support.tower_data.get_id()), label, given.relayed,
			1.0 if amount > 0.0 else 0.35)

func _thread(from: Tower, to: Tower, colour: Color, label: String, relayed: bool, alpha: float) -> void:
	var a := to_local(from.global_position)
	var b := to_local(to.global_position)
	var points := PackedVector2Array([a])
	if relayed:
		var wall := _relay_wall(from, to)
		if wall != null:
			points.append(to_local(wall.global_position))  # Hedgerow Roots: along the wall
	points.append(b)
	var glow := Color(colour, 0.18 * alpha)
	var line := Color(colour, 0.8 * alpha)
	for i in points.size() - 1:
		draw_line(points[i], points[i + 1], glow, THREAD_WIDTH + 3.0)
		draw_line(points[i], points[i + 1], line, THREAD_WIDTH)
	draw_circle(a, 3.0, line)
	var mid := (points[points.size() - 2] + b) / 2.0
	WorldLabel.draw_tag(self, mid.x, mid.y - 4.0, label, Color(colour, maxf(alpha, 0.5)))

# The Thornwall beside `to` that `from`'s aura reaches (the relay it goes through).
func _relay_wall(from: Tower, to: Tower) -> Tower:
	for wall in to._hedge_walls():
		if from.reaches_past([wall]):
			return wall
	return null

# --- Lens --------------------------------------------------------------------------------------------

# The lens on the ground: every aura's area tinted by kind (the only part under the Wardens).
func _draw_lens_areas(towers: Array) -> void:
	for tower in towers:
		if AuraView.is_aura(tower.tower_data):
			var colour := BuffSources.color(tower.tower_data.get_id())
			for cell in AuraView.cells(tower.global_position, tower.get_aura_reach()):
				var c := _ground.to_local(Tower.MAP_GRID.calculate_map_position(cell))
				_ground.draw_rect(Rect2(c - Tower.MAP_GRID.cell_size / 2.0, Tower.MAP_GRID.cell_size), Color(colour, LENS_FILL))

# The lens above the Wardens: a gold halo over every boosted one (brighter the more it gets) and the rest
# dimmed a little, so switching it on visibly changes the map, at rests too. Only local sources light a Warden
# (auras, Kinships, Kindred / Whole Tree): global Dreams and Nurture would make the whole map glow
# (screens_ui.md "The lens button, revised").
const HALO_Y := -20.0  # Over the Warden's body
const DIM_ALPHA := 0.3

func _draw_lens(towers: Array) -> void:
	for tower in towers:
		var at := to_local(tower.global_position)
		var boost := local_boost(tower)
		if boost > 0.001:
			var strength := clampf(boost, 0.25, 0.9)
			draw_arc(at + Vector2(0, HALO_Y), Tower.MAP_GRID.cell_size.x * 0.38, 0.0, TAU, 32, Color(Palette.GLOW, strength), 2.5)
			draw_arc(at + Vector2(0, HALO_Y), Tower.MAP_GRID.cell_size.x * 0.38 + 3.0, 0.0, TAU, 32, Color(Palette.GLOW, strength * 0.35), 2.0)
			drawn_markers += 1
		else:
			draw_circle(at + Vector2(0, HALO_Y * 0.5), Tower.MAP_GRID.cell_size.x * 0.45, Color(Palette.DREAD, DIM_ALPHA))

# The damage + attack speed a Warden gets from local sources (auras, Kindred / Whole Tree).
static func local_boost(tower: Tower) -> float:
	var boost := tower._aura_damage + tower._aura_speed
	var kin := Kinships.find(tower)
	if kin != null:
		boost += kin.family_bonus(tower.tower_data.line)
		if not kin.get_pairs(tower).is_empty():
			boost = maxf(boost, 0.1)  # A Kinship bond (traits, no number) still lights it
	return boost

# For the HUD's Boosts button (Main): true once the map has a local buff source (an aura Warden or a Kinship).
static func has_local_sources(near: Node) -> bool:
	var overlay := find(near)
	if overlay == null:
		return false
	for tower in overlay._towers():
		if AuraView.is_aura(tower.tower_data):
			return true
	var kin := Kinships.find(near)
	return kin != null and not kin.pairs.is_empty()

# The legend under the Boosts button: the local source kinds on the map now, [[kind, colour, name], …].
# Draw each shape with BuffOverlay.draw_pip(canvas, at, kind, colour).
static func legend_kinds(near: Node) -> Array:
	var overlay := find(near)
	if overlay == null:
		return []
	var seen := {}
	var result := []
	for tower in overlay._towers():
		for entry in BuffSources._local_entries(tower):
			if seen.has(entry.kind):
				continue
			seen[entry.kind] = true
			result.append([entry.kind, BuffSources.color(entry.kind, entry.source), LEGEND_NAMES.get(entry.kind, String(entry.kind).capitalize())])
	return result

const LEGEND_NAMES := {"acorn": "Acorn", "elder_stump": "Elder Stump", "grove_heart": "Grove Heart",
	"grandmother_oak": "Grandmother Oak", "old_growth": "Old Growth", "kinship": "Kinship", "kindred": "Kindred",
	"whole_tree": "Whole Tree"}
