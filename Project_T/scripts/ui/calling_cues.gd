extends Node2D
class_name CallingCues

# World cues for the rebuilt Calling evolutions (Roguelite Code, 2026-10-23 and the section 33 final pass, 2026-10-24),
# drawn by the UI so the class scripts keep no UI. Made by the HUD. Each one is inert until its API is in (has_method /
# get), so it parses and runs before then. The look (art council 2026-10-24): whole pixels, a 1 px Void outline, no
# fills; rings stay inside the Warden's cell (flat ellipses at its foot); gold only for the player's own marks (the
# throne, gold dispels), moon tones and bronze for the rest, told apart by shape too; any number sits on a small
# pewter plate (ui_style.md "No floating text over the map"); at most one cue on each side of a nightmare.
# - Shared Caps (Spore Print): a capped Warden (spore_print.is_capped) wears a spore-green ring at its foot.
# - Sightline (Lantern Light): while placing a Warden, the pale path (Lit route cells in range of 3+ Wardens that aren't
#   Fireflies; firefly_lights.pale_cells with the ghost as one more Warden) washes pale Heartlight: where it would lie.
# - Toadstool Throne: gold growth rings at the throne Warden's foot, one more for every 10 drifts it has stood (to 3).
#   Before any throne, the would-be holder (spore_print.throne_progress) wears a dim ring whose gold fills toward
#   THRONE_AGE, clockwise from the top.
# - Moth to Flame / Pyre: a gold-dispel plate in the Warden's cell (firefly_lights.gold_dispels_total): a gold flame
#   diamond and the count; the Moth holder's flame has a white core; with Pyre "N/50" (phones: "N") until 50.
# - Halfway Bell: the halfway bell wears a moonlit half-moon (10 px) in its cell.
# Over each nightmare (the overhead layer, with the Toll rings):
# - Deathcap (left of the health bar): its bursts left this walk (spore_print.bursts_left), up to 3 pips, 3×3 each.
# - Lantern Light (right of the bar): the lantern it carries (firefly_lights.lantern_level; its glass dims as it
#   fades); from 2 glows Lantern Alley's streak (streak_of) joins it on one plate: lantern, "×N".
# - Keeping Time (right of the bar): Last Bell's tally as a small bronze bell and 6 ticks (5 rings each); with Halfway
#   Bell an 8 px notch between the 3rd and 4th tick, bright until the halfway Toll has landed.
# The Spore Season counter sits on the Calling's frame (DreamsRow) and the "+N%" / Dewdrop "kept" cues on the status
# dots (Enemy).

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const PLATE := "res://assets/ui/moonglass/plate.png"
const REFRESH := 0.2  # Seconds (real time) between looks
const CAP_COLOR := Palette.SPRIG
const PALE_COLOR := Palette.HEARTLIGHT
const OVER_Z := 6  # The overhead layer: 2 + 6 = keeping_time's PIP_Z (8), over the nightmares
const BAR_HALF_W := 20.0  # Half of Enemy.HEALTH_BAR_SIZE.x
const BAR_OFFSET := Vector2(0, -38)  # Enemy.HEALTH_BAR_OFFSET's fallback
# Evolution ids and metas the cues read (Roguelite Code's; literals so this parses before they land)
const DEATHCAP := &"sp_deathcap_field"
const THRONE := &"sp_throne"
const EARLY_LAMPS := &"lf_early_lamps"
const ALLEY := &"lf_lantern_alley"
const MOTH := &"lf_moth_to_flame"
const PYRE := &"lf_pyre"
const LAST_BELL := &"kt_evo_last_bell"
const HALFWAY := &"kt_evo_halfway_bell"
const REMEMBER_META := &"kt_evo_remember"
const LAST_DONE_META := &"kt_evo_last_done"
const HALFWAY_DONE_META := &"kt_evo_halfway_done"
const SIDE_GAP := 3.0  # From the health bar's end to a side cue
const PIP_STEP := 5.0  # Deathcap: 3 px pips with a shared 1 px outline
const TALLY_TICKS := 6
const TICK_STEP := 2.0  # 1 px ticks with a shared 1 px outline
const NUMBER_SIZE := 14  # Plate numbers: digits 9 px and more
const PLATE_PAD := Vector2(4, 2)
const PLATE_MARGIN := 4  # plate.png's rim corner at ×1
const FOOT := 18.0  # A Warden's foot ring: its centre below the cell centre…
const RING := Vector2(26, 9)  # …and its half-axes (inside the 64 px cell, outline included)
const THRONE_RING_DRIFTS := 10  # One more growth ring per this many drifts past the throne's age…
const THRONE_RINGS := 3  # …up to this many
const RING_STEP := Vector2(5, 2)  # Each inner growth ring this much smaller
# Pixel glyphs (k = Void outline): the lantern (G frame, w glass, W its lit middle) and the bronze bell.
const LANTERN := ["..k..", ".kGk.", "kGGGk", "kwWwk", "kwWwk", "kwwwk", "kGGGk", ".kkk."]
const BELL := ["...k...", "..kok..", ".korok.", ".korok.", "korrrok", "kkkkkkk", "...k..."]

var _dreams: Node = null
var _placer: Node = null
var _over := Node2D.new()  # Over the nightmares
var _plate: StyleBoxTexture = null  # plate.png as a ×1 nine-slice (kept on the instance: never a static texture)
var _capped: Array = []  # Wardens wearing a cap now
var _pale: Array = []  # World centres of pale path cells (while building)
var _thrones: Array = []  # [Warden, rings, share]: rings 0 = the would-be holder, share of THRONE_AGE grown
var _gold: Array = []  # [Warden, text, holder, lit]
var _halfway_bell: Node2D = null
var _over_on := false  # Any overhead cue's evolution taken
var _clock := 0.0

func _ready() -> void:
	z_index = 2  # Over the ground, under the lighting and the Wardens' tags
	process_mode = Node.PROCESS_MODE_ALWAYS  # Building happens paused too
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_over.name = "Overhead"
	_over.z_index = OVER_Z
	_over.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_over.draw.connect(_draw_over)
	add_child(_over)
	if ResourceLoader.exists(PLATE):
		_plate = StyleBoxTexture.new()
		_plate.texture = load(PLATE)
		_plate.set_texture_margin_all(PLATE_MARGIN)
	_connect.call_deferred()

func _connect() -> void:
	_dreams = get_tree().get_first_node_in_group(DreamState.GROUP)
	var root := get_parent()
	_placer = root.get_node_or_null("%TowerPlacer") if root != null else null

func _process(delta: float) -> void:
	if _over_on:
		_over.queue_redraw()  # The nightmares move: every frame while a cue is on
	_clock -= delta / maxf(Engine.time_scale, 0.001)
	if _clock > 0.0:
		return
	_clock = REFRESH
	_over_on = _evo(&"spore_print", DEATHCAP) or _evo(&"firefly_lights", EARLY_LAMPS) or _evo(&"firefly_lights", ALLEY) \
		or _evo(&"keeping_time", LAST_BELL)
	if not _over_on:
		_over.queue_redraw()  # Clears the last frame's marks
	var capped := _find_capped()
	var pale := _find_pale()
	var thrones := _find_thrones()
	var gold := _find_gold()
	var halfway := _find_halfway_bell()
	if capped != _capped or pale != _pale or thrones != _thrones or gold != _gold or halfway != _halfway_bell:
		_capped = capped
		_pale = pale
		_thrones = thrones
		_gold = gold
		_halfway_bell = halfway
		queue_redraw()

# The class node `node_name` on DreamState (spore_print, firefly_lights, keeping_time), or null.
func _node(node_name: StringName) -> Node:
	return _dreams.get(node_name) as Node if _dreams != null else null

func _evo(node_name: StringName, id: StringName) -> bool:
	var node := _node(node_name)
	return node != null and node.has_method(&"evo") and bool(node.evo(id))

# A constant of a class script (THRONE_AGE, PYRE_DISPELS, LAST_RINGS), else `fallback`.
static func _const(node: Node, key: String, fallback: int) -> int:
	var script: Script = node.get_script() if node != null else null
	return int(script.get_script_constant_map().get(key, fallback)) if script != null else fallback

func _find_capped() -> Array:
	var spores := _node(&"spore_print")
	if spores == null or not spores.has_method(&"is_capped"):
		return []
	return get_tree().get_nodes_in_group(Tower.GROUP).filter(func(t: Node) -> bool: return spores.is_capped(t))

func _find_pale() -> Array:
	var building: bool = _placer != null and bool(_placer.get("build_mode"))
	var lights := _node(&"firefly_lights")
	if not building or lights == null:
		return []
	var cells: Array = []
	if lights.has_method(&"pale_cells"):  # Roguelite e9c87724: the ghost counts as one more Warden in range (not a Firefly or wall)
		var data: TowerData = _placer.get("tower_data") as TowerData
		var hover = _placer.get("_hover_cell")
		var cell: Vector2i = hover if hover is Vector2i else Vector2i(-1, -1)
		cells = lights.pale_cells(data, cell)
	return cells.map(func(cell: Vector2i) -> Vector2: return MAP_GRID.calculate_map_position(cell))

# Toadstool Throne: the mushroom marked "throne" names its Warden ("king"); its age is drifts since it was planted.
func _find_thrones() -> Array:
	var spores := _node(&"spore_print")
	if not _evo(&"spore_print", THRONE) or not (spores.get("mushrooms") is Dictionary):
		return []
	var drift: int = int(spores._current_drift()) if spores.has_method(&"_current_drift") else 0
	var need := _const(spores, "THRONE_AGE", 10)
	var out: Array = []
	for m: Dictionary in (spores.mushrooms as Dictionary).values():
		var king = m.get("king") if bool(m.get("throne", false)) else null
		var tower = king.get_ref() if king is WeakRef else null
		if is_instance_valid(tower):
			var age: int = drift - int(tower.get("planted_drift") if tower.get("planted_drift") != null else 1)
			out.append([tower, clampi(1 + (age - need) / THRONE_RING_DRIFTS, 1, THRONE_RINGS), 1.0])
	if out.is_empty() and spores.has_method(&"throne_progress"):  # No throne yet: the would-be holder's ring fills toward it
		var progress: Array = spores.throne_progress()
		if progress.size() >= 2 and is_instance_valid(progress[0]):
			out.append([progress[0], 0, clampf(float(progress[1]) / maxf(need, 1.0), 0.0, 1.0)])
	return out

# Moth to Flame / Pyre: every Warden with a gold dispel; the Moth holder lit; Pyre counts toward PYRE_DISPELS.
func _find_gold() -> Array:
	var lights := _node(&"firefly_lights")
	var pyre := _evo(&"firefly_lights", PYRE)
	if not (pyre or _evo(&"firefly_lights", MOTH)) or not lights.has_method(&"gold_dispels_total"):
		return []
	var need := _const(lights, "PYRE_DISPELS", 50)
	var held = lights.get("_moth_holder")
	var holder = held.get_ref() if held is WeakRef else null
	var phone := TouchBuild.mobile_controls()  # No "/50" on phones (art council 2026-10-24)
	var out: Array = []
	for tower in get_tree().get_nodes_in_group(Tower.GROUP):
		var count := int(lights.gold_dispels_total(tower))
		if count > 0:
			var text := "%d/%d" % [count, need] if pyre and count < need and not phone else str(count)
			out.append([tower, text, tower == holder, pyre and count >= need])
	return out

func _find_halfway_bell() -> Node2D:
	var time := _node(&"keeping_time")
	if not _evo(&"keeping_time", HALFWAY):
		return null
	var id := int(time.get("_halfway_id")) if time.get("_halfway_id") != null else 0
	return instance_from_id(id) as Node2D if id != 0 and is_instance_id_valid(id) else null

# --- Drawing helpers (whole pixels) ---------------------------------------------------------------

# A pixel glyph: `rows` of ink letters from `inks`, its top-left at `origin`.
static func _pixels(c: CanvasItem, origin: Vector2, rows: Array, inks: Dictionary) -> void:
	origin = origin.round()
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if inks.has(row[x]):
				c.draw_rect(Rect2(origin + Vector2(x, y), Vector2.ONE), inks[row[x]])

# A flat ring at a Warden's foot (an ellipse, `t` of it clockwise from the top): `width` px of `colour` on a 1 px Void
# edge each side; no antialiasing.
static func _foot_ring(c: CanvasItem, centre: Vector2, radii: Vector2, colour: Color, width: float = 2.0, t: float = 1.0) -> void:
	var steps := maxi(4, roundi(40 * t))
	var points := PackedVector2Array()
	for i in steps + 1:
		var a := -PI / 2.0 + TAU * t * i / steps
		points.append((centre + Vector2(cos(a) * radii.x, sin(a) * radii.y)).round() + Vector2(0.5, 0.5))
	c.draw_polyline(points, Palette.VOID, width + 2.0)
	c.draw_polyline(points, colour, width)

# A pewter plate behind `size` px of content at `origin` (the plate's top-left); returns the content's top-left.
func _plate_at(c: CanvasItem, origin: Vector2, size: Vector2) -> Vector2:
	var rect := Rect2(origin.round(), (size + PLATE_PAD * 2.0).round())
	if _plate != null:
		c.draw_style_box(_plate, rect)
	else:
		c.draw_rect(rect, Palette.DREAD)
	return rect.position + PLATE_PAD

# A 5 px pixel diamond (a flame) on a 1 px Void outline; `core` lights its middle pixel.
static func _flame(c: CanvasItem, centre: Vector2, colour: Color, core := false) -> void:
	var at := centre.round()
	for k in 4:  # Outline rows 7 wide at the middle, then the fill rows 5
		var w := 7 - 2 * k
		c.draw_rect(Rect2(at + Vector2(-(w - 1) / 2.0, k), Vector2(w, 1)), Palette.VOID)
		c.draw_rect(Rect2(at + Vector2(-(w - 1) / 2.0, -k), Vector2(w, 1)), Palette.VOID)
	for k in 3:
		var w := 5 - 2 * k
		c.draw_rect(Rect2(at + Vector2(-(w - 1) / 2.0, k), Vector2(w, 1)), colour)
		c.draw_rect(Rect2(at + Vector2(-(w - 1) / 2.0, -k), Vector2(w, 1)), colour)
	if core:
		c.draw_rect(Rect2(at, Vector2.ONE), Palette.HEARTLIGHT)

# --- The cells ------------------------------------------------------------------------------------

func _draw() -> void:
	var side: Vector2 = MAP_GRID.cell_size
	for at: Vector2 in _pale:  # A soft pale wash on each cell, a little inside it
		draw_rect(Rect2(to_local(at) - side / 2.0 + Vector2(4, 4), side - Vector2(8, 8)), Color(PALE_COLOR, 0.16))
	for tower in _capped:  # Shared Caps: a spore-green ring at its foot
		if is_instance_valid(tower):
			_foot_ring(self, to_local((tower as Node2D).global_position) + Vector2(0, FOOT), RING, CAP_COLOR)
	for row in _thrones:  # Gold growth rings inside the cap ring; or the would-be throne's ring filling
		if not is_instance_valid(row[0]):
			continue
		var foot: Vector2 = to_local((row[0] as Node2D).global_position) + Vector2(0, FOOT)
		var inner := RING - RING_STEP
		if int(row[1]) == 0:
			_foot_ring(self, foot, inner, Palette.SLATE, 1.0)  # Moon-grey until gold fills it (OAK read as gold)
			if float(row[2]) > 0.0:
				_foot_ring(self, foot, inner, Palette.GOLD, 2.0, float(row[2]))
			continue
		for i in int(row[1]):
			_foot_ring(self, foot, inner - RING_STEP * i, Palette.GOLD, 2.0 if i == 0 else 1.0)
	if is_instance_valid(_halfway_bell):  # A moonlit half-moon in the bell's cell, bottom left
		var at: Vector2 = (to_local(_halfway_bell.global_position) + Vector2(-side.x / 2.0 + 9.0, side.y / 2.0 - 9.0)).round()
		draw_circle(at, 5.0, Palette.VOID, true, -1.0, false)
		draw_circle(at, 4.0, Palette.SLATE, true, -1.0, false)
		draw_rect(Rect2(at + Vector2(-4, 0), Vector2(8, 4)), Palette.MOONLIGHT)  # The lit lower half…
		draw_rect(Rect2(at + Vector2(-3, 3), Vector2(6, 1)), Palette.VOID)  # …cut round at its foot
		draw_rect(Rect2(at + Vector2(-4, 3), Vector2(1, 1)), Palette.VOID)
		draw_rect(Rect2(at + Vector2(3, 3), Vector2(1, 1)), Palette.VOID)
	for row in _gold:  # A plate in the cell's bottom right: the flame, the count
		if is_instance_valid(row[0]):
			var font := UiStyle.number_font()
			var text_w := font.get_string_size(row[1], HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_SIZE).x
			var size := Vector2(7.0 + 2.0 + text_w, NUMBER_SIZE)
			var corner: Vector2 = to_local((row[0] as Node2D).global_position) + side / 2.0 - Vector2(2, 2)
			var at := _plate_at(self, corner - size - PLATE_PAD * 2.0, size)
			_flame(self, at + Vector2(3, size.y / 2.0), Palette.GLOW if row[3] else Palette.GOLD, row[2])
			_number(self, at + Vector2(9, 0), row[1], Palette.GLOW if row[3] else Palette.GOLD)

# A plate number: Vollkorn Medium with lining figures (UiStyle.number_font), its box's top-left at `at`.
static func _number(c: CanvasItem, at: Vector2, text: String, colour: Color) -> void:
	var font := UiStyle.number_font()
	var base := (at + Vector2(0, font.get_ascent(NUMBER_SIZE) - (font.get_height(NUMBER_SIZE) - NUMBER_SIZE) / 2.0)).round()
	c.draw_string_outline(font, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_SIZE, 2, Palette.VOID)
	c.draw_string(font, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_SIZE, colour)

# --- Over the nightmares --------------------------------------------------------------------------

func _draw_over() -> void:
	if not _over_on:
		return
	var spores := _node(&"spore_print")
	var lights := _node(&"firefly_lights")
	var time := _node(&"keeping_time")
	var deathcap := _evo(&"spore_print", DEATHCAP) and spores.has_method(&"bursts_left")
	var lamps := _evo(&"firefly_lights", EARLY_LAMPS) and lights.has_method(&"lantern_level")
	var alley := _evo(&"firefly_lights", ALLEY) and lights.has_method(&"streak_of")
	var tally := _evo(&"keeping_time", LAST_BELL)
	var halfway := _evo(&"keeping_time", HALFWAY)
	var last_rings := _const(time, "LAST_RINGS", 30)
	for enemy in get_tree().get_nodes_in_group(&"enemies"):
		if not is_instance_valid(enemy) or not enemy.visible:
			continue
		var bar = enemy.get("_bar_offset")
		var body: Vector2 = enemy._body_offset() if enemy.has_method(&"_body_offset") else Vector2.ZERO
		var centre := _over.to_local(enemy.global_position + body + (bar if bar is Vector2 else BAR_OFFSET))
		if deathcap:
			draw_deathcap(_over, centre, int(spores.bursts_left(enemy)))
		var level := float(lights.lantern_level(enemy)) if lamps else 0.0
		var streak := int(lights.streak_of(enemy)) if alley else 0
		if level > 0.0 or streak >= 2:
			draw_lantern_cue(_over, centre, level, streak)
		if tally and enemy.has_meta(REMEMBER_META) and not enemy.has_meta(LAST_DONE_META):
			var share := clampf(float(enemy.get_meta(REMEMBER_META)) / maxf(last_rings, 1.0), 0.0, 1.0)
			draw_tally(_over, centre, share, (0 if not halfway else (2 if enemy.has_meta(HALFWAY_DONE_META) else 1)))

# Deathcap (left of the bar `centre`): a 3×3 pip per burst left, from the bar outward.
static func draw_deathcap(c: CanvasItem, centre: Vector2, left: int) -> void:
	var right := (centre + Vector2(-BAR_HALF_W - SIDE_GAP, 0)).round()
	for k in mini(left, 3):
		var at := right + Vector2(-PIP_STEP * (k + 1), -2.0)
		c.draw_rect(Rect2(at, Vector2(5, 5)), Palette.VOID)
		c.draw_rect(Rect2(at + Vector2.ONE, Vector2(3, 3)), Palette.NEWLEAF)

# Lantern Light (right of the bar): the lantern, its glass dimming with `level` (0: an empty frame); with a streak of
# 2+ glows lantern and "×N" share one plate.
func draw_lantern_cue(c: CanvasItem, centre: Vector2, level: float, streak: int) -> void:
	var glass := Palette.SLATE.lerp(Palette.MOONLIGHT, level)
	var lit := Palette.SLATE.lerp(Palette.HEARTLIGHT, level)
	var inks := {"k": Palette.VOID, "G": Palette.MIST, "w": glass, "W": lit}
	var left := (centre + Vector2(BAR_HALF_W + SIDE_GAP, 0)).round()
	if streak < 2:
		_pixels(c, left + Vector2(0, -4), LANTERN, inks)
		return
	var text := "×%d" % streak
	var text_w := UiStyle.number_font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_SIZE).x
	var size := Vector2(5.0 + 2.0 + text_w, NUMBER_SIZE)
	var at := _plate_at(c, left + Vector2(0, -size.y / 2.0 - PLATE_PAD.y), size)
	_pixels(c, at + Vector2(0, (size.y - 8.0) / 2.0), LANTERN, inks)
	_number(c, at + Vector2(7, 0), text, Palette.MOONLIGHT)

# Last Bell (right of the bar): a bronze bell and TALLY_TICKS ticks lit by the share remembered (the bell lights when
# full); halfway 1: Halfway Bell's 8 px notch after the 3rd tick, bright (its Toll still to come); 2: dim (taken).
static func draw_tally(c: CanvasItem, centre: Vector2, share: float, halfway: int) -> void:
	var lit := int(floor(share * TALLY_TICKS + 0.0001))
	var full := lit >= TALLY_TICKS
	var left := (centre + Vector2(BAR_HALF_W + SIDE_GAP, 0)).round()
	_pixels(c, left + Vector2(0, -4), BELL, {"k": Palette.VOID, "o": Palette.OAK, "r": Palette.HEARTLIGHT if full else Palette.EMBER})
	var x := left.x + 8.0
	var top := left.y - 3.0
	var notch_after := TALLY_TICKS / 2
	for i in TALLY_TICKS:
		c.draw_rect(Rect2(Vector2(x, top), Vector2(3, 6)), Palette.VOID)
		c.draw_rect(Rect2(Vector2(x + 1, top + 1), Vector2(1, 4)), Palette.EMBER if i < lit else Palette.OAK)
		x += TICK_STEP
		if halfway > 0 and i == notch_after - 1:  # The notch: one taller post between the halves
			x += 1.0
			c.draw_rect(Rect2(Vector2(x, top - 2), Vector2(3, 10)), Palette.VOID)
			c.draw_rect(Rect2(Vector2(x + 1, top - 1), Vector2(1, 8)), Palette.MOONLIGHT if halfway == 1 else Palette.SLATE)
			x += TICK_STEP + 1.0
