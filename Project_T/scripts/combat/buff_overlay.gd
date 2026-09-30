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
const REDRAW_EVERY := 0.2  # Seconds between redraws while something shows (buffs change slowly)
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

static func find(near: Node) -> BuffOverlay:
	if near == null or not near.is_inside_tree():
		return null
	return near.get_tree().get_first_node_in_group(GROUP) as BuffOverlay

func _init() -> void:
	add_to_group(GROUP)
	add_to_group(BuffLens.GROUP)  # BuffLens.set_on calls set_lens on every change
	lens = BuffLens.on
	z_index = -1  # On the ground, under Wardens and nightmares
	process_mode = Node.PROCESS_MODE_ALWAYS  # Paused: the pips show

func set_lens(on: bool) -> void:
	lens = on
	lens_changed.emit(on)
	queue_redraw()

func _process(delta: float) -> void:
	_redraw_left -= delta
	var key := [lens, _show_all(), _focus()]
	if key != _last_key or (_redraw_left <= 0.0 and _anything_shown()):
		_last_key = key
		_redraw_left = REDRAW_EVERY
		queue_redraw()

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

func _draw() -> void:
	var towers := _towers()
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
	var at := to_local(tower.global_position) + Vector2(-(rows.size() - 1) * PIP_STEP / 2.0, PIP_Y)
	WorldLabel.begin_screen_size(self, at + Vector2((rows.size() - 1) * PIP_STEP / 2.0, 0.0))  # Screen size when zoomed in
	var font := ThemeDB.fallback_font
	for row in rows:
		var colour := BuffSources.color(row[0], row[2])
		draw_pip(self, at, row[0], colour)
		if row[1] > 1:
			draw_string(font, at + Vector2(PIP_RADIUS, 9), "×%d" % row[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, colour)
		at.x += PIP_STEP
	WorldLabel.end_screen_size(self)

# One pip: a shape per kind (not only a colour, for accessibility). Shared with the Warden panel.
static func draw_pip(canvas: CanvasItem, at: Vector2, kind: String, colour: Color, r: float = PIP_RADIUS) -> void:
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

# --- Threads -----------------------------------------------------------------------------------------

# Every Warden buffing `tower`, joined to it and labelled with its share.
func _draw_threads_in(tower: Tower) -> void:
	var seen := {}
	for entry in BuffSources.for_tower(tower):
		var source = entry.source
		if not (source is Tower) or not is_instance_valid(source) or entry.stat == "":
			continue
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

func _draw_lens(towers: Array) -> void:
	for tower in towers:
		if AuraView.is_aura(tower.tower_data):
			var colour := BuffSources.color(tower.tower_data.get_id())
			for cell in AuraView.cells(tower.global_position, tower.get_aura_reach()):
				var c := to_local(Tower.MAP_GRID.calculate_map_position(cell))
				draw_rect(Rect2(c - Tower.MAP_GRID.cell_size / 2.0, Tower.MAP_GRID.cell_size), Color(colour, LENS_FILL))
	for tower in towers:
		var boost := 0.0
		for entry in BuffSources.for_tower(tower):
			if entry.stat == "damage" or entry.stat == "attack_speed":
				boost += entry.amount
		if absf(boost) > 0.001:
			var shade := BuffSources.COLORS.penalty if boost < 0.0 else Palette.GLOW
			draw_circle(to_local(tower.global_position), Tower.MAP_GRID.cell_size.x * 0.42,
				Color(shade, clampf(absf(boost), 0.08, 0.6)))
