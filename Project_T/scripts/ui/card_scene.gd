extends PanelContainer
class_name CardScene

# A placement card's living mini-scene (dream_design.md "Revised: a living mini-scene", user: "can it be like a
# mini video of gameplay?"): the card's `diagram` (legend on UpgradeData.diagram) built with the real tiles and
# sprites in a small SubViewport, looping a few seconds. Nightmares walk the diagram's path (from S, or an open
# end; a diagram without a path gets one along its emptiest row); the qualifying Warden (W, Q) attacks with the
# card's boosted numbers in gold (EFFECTS: "+30% · 13"), the others (a, w) with plain numbers in white; a nightmare
# passing a marked Thornwall (X) shows the card's effect on it in gold. Range cells (*) and route steps (+, 1–9)
# are marked; stumps (U) and hollows (Q) use their real tiles. Puppets only: no Tower / Enemy AI, no DamageLog,
# nothing in the run. One instance is pooled by the Dream screen (`show_card`, `stop`); reduced motion keeps the
# still CardDiagram.
# Heartwood's Gifts (Spire branch, heartwood_gifts.md): `show_scene(before, after, effect, caption)` loops a
# before → after pair of diagrams (the changed cells fade in and glow gold; walkers re-route along the new path).
# Gift terrain letters, drawn with MapGifts' art (act 1 sheets; palette shapes without them): L fallen log, ~ spring
# pond, m moonwell, b bell stone, z lightning tree, u ancient stump (all off the path), k mushroom ring (its art
# covers 3×3 from the k cells' top-left), B bog path (walked at BOG_SPEED), r root-covered path (hits there show the
# effect's text in gold). Under reduced motion the scene is the still after-diagram.

const CELL := 64.0
const COLS := 7
const ROWS := 5
const VIEW_SCALE := 0.7  # 448×320 world px shown at ~314×224
const WALK_SPEED := 135.0  # World px per second: S to H in ~5 s (the loop the spec asks for)
const SPAWN_EVERY := 1.2  # Seconds between nightmares
const NIGHTMARES := 3
const ATTACK_EVERY := 0.8  # Seconds between a puppet Warden's attacks
const RANGE_CELLS := 2.2
const BASE_HIT := 10  # The number a plain hit shows
const PUFF_SPEED := 420.0
const NUMBER_RISE := 26.0
const NUMBER_TIME := 0.8
const HITS_TO_DISPEL := 7  # Most reach the favoured Warden, whose double hits finish them
const WARDEN := preload("res://resource/tower/sporeling.tres")  # The puppet attacker (the first family most players have)
const SPROUT := preload("res://resource/tower/sprout.tres")  # Sprout cards show Sprouts
const THORNWALL := preload("res://resource/tower/thornwall.tres")
const NIGHTMARE := preload("res://resource/enemy/leaf_bug.tres")  # A Shade
const QUALIFYING := "WQ"
const OTHERS := "aw"
const WALLS := "TX"
const SPROUT_CARDS: Array[String] = ["root_network", "root_network_ii", "sprout_chorus"]
# What each card shows in gold (the numbers from its caption): `text` on the favoured Warden's hits, its damage /
# attack speed multipliers and extra range; `proc` pops on a nightmare passing a marked Thornwall (X).
const EFFECTS := {
	"bitter_hedges": {"proc": "+8% taken"},
	"briar_crown": {"text": "", "proc": "+25%"},
	"cozy_corners": {"text": "+30%", "damage": 1.3},
	"cozy_corners_ii": {"text": "+50%", "damage": 1.5},
	"crossroads": {"text": "+40%", "damage": 1.4},
	"drumbeat": {"text": "+30% speed", "speed": 1.3},
	"forests_edge": {"text": "+35%", "damage": 1.35},
	"heart_of_the_maze": {"text": "×2", "damage": 2.0},
	"hedgerow_roots": {"text": "aura through the wall", "damage": 1.2},
	"hollow_ground": {"text": "+1 range", "range": 1.0},
	"hollow_ground_ii": {"text": "+1.5 range", "range": 1.5},
	"kind_canopy": {"text": "+20%", "damage": 1.2},
	"last_stand": {"text": "+35%", "damage": 1.35},
	"overlap": {"text": "+40%", "damage": 1.4},
	"root_network": {"text": "+18%", "damage": 1.18},
	"root_network_ii": {"text": "+32%", "damage": 1.32},
	"rootbound": {"text": "×2 speed", "speed": 2.0},
	"shared_light": {"text": "+12%", "damage": 1.12},
	"solitude": {"text": "+45%", "damage": 1.45, "range": 0.5},
	"sprout_chorus": {"text": "+24% speed", "speed": 1.24},
	"straightaway": {"text": "+30%", "damage": 1.3, "range": 0.5},
	"straightaway_ii": {"text": "+50%", "damage": 1.5, "range": 0.5},
	"tended_stumps": {"text": "+25%", "damage": 1.25},
	"tended_stumps_ii": {"text": "+40%", "damage": 1.4},
	"wildwood_reclaimed": {"text": "+30%", "damage": 1.3},
}

var card: UpgradeData
var _viewport := SubViewport.new()
var _world: Node2D = null
var _caption := Label.new()
var _legend := Label.new()
var _path: Array[Vector2] = []  # World centres from S to H
var _wardens: Array[Dictionary] = []  # {sprite, cell, boosted, cooldown, attack_time}
var _walkers: Array[Dictionary] = []  # {sprite, distance, hits, fade}
var _effects: Array[Dictionary] = []  # Puffs and numbers: {node, from, to, time, kind}
var _spawn_left := 0.0
var _spawned := 0
var _walls: Array[Vector2] = []  # Marked Thornwalls (X): a nightmare passing one shows the card's `proc`
var _effect := {}  # EFFECTS[card.id]
var _rows := PackedStringArray()  # The diagram being shown (with its added path)

# Gift scenes (show_scene)
const BEFORE_TIME := 2.2  # Seconds on the before-diagram, then the after one
const AFTER_TIME := 4.5
const SWAP_FADE := 0.4  # The new diagram fades in over this
const PULSE_TIME := 1.2  # The changed cells glow gold for this long after the swap
const BOG_SPEED := 0.8
const PROP_FPS := 4.0
var _in_scene := false
var _before := ""
var _after := ""
var _showing_after := false
var _phase_left := 0.0
var _fade_left := 0.0
var _pulse_left := 0.0
var _changed: Array[Vector2i] = []
var _overlay: Node2D = null  # The gold pulse on changed cells, and the Before / After tag
var _props: Array[Node2D] = []
var _anim := 0.0
var _sheets := {}  # MapGifts sheet name -> Texture2D (act 1), loaded on first use (never static: exit crash)

# Reduced motion keeps the still diagram (CardDiagram) instead.
static func wants_motion() -> bool:
	return not bool(Fx.setting("reduced_motion", false))

static func can_show(for_card: UpgradeData) -> bool:
	return CardDiagram.has_diagram(for_card) and wants_motion()

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS  # The Dream screen pauses the game

func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.panel_in(Palette.GOLD))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	var frame := SubViewportContainer.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.custom_minimum_size = Vector2(COLS * CELL, ROWS * CELL) * VIEW_SCALE
	frame.stretch = true
	box.add_child(frame)
	_viewport.transparent_bg = false
	_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	frame.add_child(_viewport)
	for label in [_caption, _legend]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(COLS * CELL * VIEW_SCALE, 0)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(label)
	_caption.name = "Caption"
	_caption.add_theme_font_size_override("font_size", 15)
	_caption.add_theme_color_override("font_color", UiStyle.INK)
	_legend.name = "Legend"
	_legend.add_theme_font_size_override("font_size", 13)
	_legend.add_theme_color_override("font_color", UiStyle.INK_DIM)
	visible = false
	set_process(false)

# Builds and plays `for_card`'s scene (the pooled view is reused from card to card).
func show_card(for_card: UpgradeData) -> void:
	card = for_card
	_in_scene = false
	_effect = EFFECTS.get(card.id, {})
	_build(card.diagram)
	_caption.text = IconInfo.format(card.diagram_caption)
	var has_favoured := card.diagram.contains("W") or card.diagram.contains("Q")
	_legend.text = "Gold numbers: the Warden the card favours · White: the others" if has_favoured \
		else "Gold: what the card does to nightmares passing the marked Thornwalls"
	visible = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	set_process(true)

# Whether a gift scene moves (reduced motion: show_scene shows the still after-diagram instead).
static func can_show_scene() -> bool:
	return wants_motion()

# A Heartwood's Gift card's scene: `before` for BEFORE_TIME, then `after` (the changed cells fade in and glow gold,
# the nightmares re-route along its path) for AFTER_TIME, looping. Diagrams are 7×5 rows as UpgradeData.diagram plus
# the gift letters above; `effect` takes EFFECTS' keys (text / damage / speed / range / proc).
func show_scene(before: String, after: String, effect: Dictionary, caption: String) -> void:
	card = null
	_in_scene = true
	_effect = effect
	_before = before
	_after = after
	_caption.text = IconInfo.format(caption)
	_legend.text = "Before, then after: what the gift changes glows gold"
	visible = true
	_showing_after = not can_show_scene()
	_build(_after if _showing_after else _before)
	_phase_left = BEFORE_TIME
	if can_show_scene():
		_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		set_process(true)
	else:  # Reduced motion: one still frame of the after-diagram
		set_process(false)
		_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

# Hover ended: nothing runs or draws until the next card.
func stop() -> void:
	visible = false
	set_process(false)
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_clear_world()

func _clear_world() -> void:
	if _world != null:
		_world.queue_free()
		_world = null
	_wardens.clear()
	_walkers.clear()
	_effects.clear()
	_walls.clear()
	_props.clear()
	_overlay = null

func _cell_at(rows: PackedStringArray, x: int, y: int) -> String:
	return rows[y][x] if y < rows.size() and x < rows[y].length() else "."

func _centre(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL + Vector2(CELL, CELL) / 2.0

static func _is_path(c: String) -> bool:
	return c == "P" or c == "+" or c == "S" or c == "H" or c == "B" or c == "r" or c.is_valid_int()

# The diagram letter under world position `at`.
func _letter_at(at: Vector2) -> String:
	var cell := Vector2i((at / CELL).floor())
	return _cell_at(_rows, cell.x, cell.y) if cell.x >= 0 and cell.y >= 0 else "."

func _build(diagram: String) -> void:
	_clear_world()
	_world = Node2D.new()
	_world.y_sort_enabled = true
	_viewport.add_child(_world)
	var camera := Camera2D.new()
	camera.position = Vector2(COLS, ROWS) * CELL / 2.0
	camera.zoom = Vector2(VIEW_SCALE, VIEW_SCALE)
	_world.add_child(camera)
	var rows := _with_path(diagram.strip_edges().split("\n"))
	_rows = rows
	var tiles := EnvironmentTiles.create_tile_set(1)
	var ground := TileMapLayer.new()
	ground.tile_set = tiles
	ground.z_index = -1
	_world.add_child(ground)
	var objects := TileMapLayer.new()  # Boulders over the grass
	objects.tile_set = tiles
	_world.add_child(objects)
	var start := Vector2i(-1, -1)
	for y in ROWS:
		for x in COLS:
			var cell := Vector2i(x, y)
			var c := _cell_at(rows, x, y)
			ground.set_cell(cell, EnvironmentTiles.GRASS, Vector2i(EnvironmentTiles.cell_variant(cell, 8), 0))
			if _is_path(c):
				var mask := 0
				for i in 4:
					var n: Vector2i = cell + [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT][i]
					if n.x >= 0 and n.y >= 0 and n.x < COLS and n.y < ROWS and _is_path(_cell_at(rows, n.x, n.y)):
						mask |= 1 << i
				ground.set_cell(cell, EnvironmentTiles.PATH, EnvironmentTiles.path_tile(mask))
			if c == "S":
				start = cell
			elif c == "H":
				var tree := Heartwood.new()
				tree.position = _centre(cell)
				_world.add_child(tree)
			elif c == "O":
				objects.set_cell(cell, EnvironmentTiles.MOSSY_BOULDER, Vector2i(EnvironmentTiles.cell_variant(cell, 9), 0))
			elif c == "U":
				objects.set_cell(cell, EnvironmentTiles.TENDED_STUMP, Vector2i.ZERO)
			if c == "Q":  # A Warden standing in a moved hollow
				ground.set_cell(cell, EnvironmentTiles.MOVED_HOLLOW, Vector2i.ZERO)
			if QUALIFYING.contains(c) or OTHERS.contains(c) or WALLS.contains(c):
				_add_warden(cell, c)
			elif c == "~":  # Spring: pond tiles by neighbour mask
				objects.set_cell(cell, EnvironmentTiles.POND, Vector2i(MapGifts._mask(Vector2(cell), _letter_is.bind("~")), 0))
			elif c == "L":
				_add_prop("fallen_log", cell, _log_line(cell))
			elif c == "m":
				_add_prop("moonwell", cell)
			elif c == "b":
				_add_prop("bell_stone", cell)
			elif c == "z":
				_add_prop("lightning_tree", cell)
	if bool(_effect.get("kin", false)):  # Kinship bonds between neighbouring Wardens, under them (Old Kin)
		var kin := Node2D.new()
		kin.name = "KinBond"
		kin.z_index = -1  # Over the ground, under the Wardens
		kin.draw.connect(_draw_kin.bind(kin))
		_world.add_child(kin)
	var gift_ground := Node2D.new()  # Bog, roots, ancient stumps and the mushroom ring, over the path tiles
	gift_ground.z_index = -1
	gift_ground.draw.connect(_draw_gift_ground.bind(gift_ground))
	_world.add_child(gift_ground)
	var marks := Node2D.new()  # Range cells (*) and outlined route steps (+, 1–9), drawn over the ground
	marks.z_index = -1
	marks.draw.connect(_draw_marks.bind(marks, rows))
	_world.add_child(marks)
	if _in_scene:
		_overlay = Node2D.new()  # The swap's gold pulse and the Before / After tag, over everything
		_overlay.z_index = 6
		_overlay.draw.connect(_draw_overlay.bind(_overlay))
		_world.add_child(_overlay)
	_path = _walk_order(rows, start if start.x >= 0 else _open_end(rows))
	_spawn_left = 0.0
	_spawned = 0

# --- Gift terrain (MapGifts' art) ---------------------------------------------------------------------------

func _letter_is(cell: Vector2, letter: String) -> bool:
	return cell.x >= 0 and cell.y >= 0 and _cell_at(_rows, int(cell.x), int(cell.y)) == letter

func _sheet(sheet: String) -> Texture2D:
	if not _sheets.has(sheet):
		var path := EnvironmentTiles.sheet_path(sheet, 1)
		_sheets[sheet] = load(path) if ResourceLoader.exists(path) else null
	return _sheets[sheet]

static func _frame_rect(sheet: String, column: int) -> Rect2:
	var size: Vector2i = MapGifts.ART[sheet][0]
	return Rect2(Vector2(column * size.x, 0), Vector2(size))

# The run of L cells `cell` belongs to (along the row if it has an L beside it, else down the column).
func _log_line(cell: Vector2i) -> Array:
	var step := Vector2i.RIGHT if _letter_is(Vector2(cell + Vector2i.LEFT), "L") or _letter_is(Vector2(cell + Vector2i.RIGHT), "L") \
		else Vector2i.DOWN
	var first := cell
	while _letter_is(Vector2(first - step), "L"):
		first -= step
	var line: Array = []
	var at := first
	while _letter_is(Vector2(at), "L"):
		line.append(Vector2(at))
		at += step
	return line

# A standing gift prop (y-sorted with the Wardens): log pieces, moonwell, bell stone, lightning tree.
func _add_prop(kind: String, cell: Vector2i, line: Array = []) -> void:
	var prop := Node2D.new()
	prop.position = _centre(cell)
	var piece := MapGifts._log_piece(Vector2(cell), line) if kind == "fallen_log" else -1
	prop.draw.connect(_draw_prop.bind(prop, kind, piece, line))
	_world.add_child(prop)
	_props.append(prop)

func _draw_prop(canvas: Node2D, kind: String, piece: int, line: Array) -> void:
	var sheet := _sheet(kind)
	if sheet != null:
		var size := Vector2(MapGifts.ART[kind][0])
		var frames: int = MapGifts.ART[kind][1]
		var column := piece if piece >= 0 else int(_anim * PROP_FPS) % frames
		canvas.draw_texture_rect_region(sheet, Rect2(Vector2(-size.x / 2.0, 32.0 - size.y), size), _frame_rect(kind, column))
		return
	match kind:  # Placeholders in palette colours (as MapGifts')
		"fallen_log":
			var along := Vector2.DOWN if line.size() > 1 and line[0].x == line[1].x else Vector2.RIGHT
			canvas.draw_line(-along * 32.0, along * 32.0, Palette.ROOT, 30.0)
			canvas.draw_line(-along * 32.0, along * 32.0, Palette.BARK, 24.0)
		"moonwell":
			canvas.draw_circle(Vector2.ZERO, 24.0, Palette.STONE)
			canvas.draw_circle(Vector2.ZERO, 16.0, Palette.POOL)
			canvas.draw_circle(Vector2(-4, -4), 7.0, Palette.MOONLIGHT)
		"bell_stone":
			canvas.draw_rect(Rect2(-12, -40, 24, 64), Palette.SLATE)
			canvas.draw_circle(Vector2(0, -18), 6.0, Palette.GOLD)
		"lightning_tree":
			canvas.draw_line(Vector2(0, 24), Vector2(0, -60), Palette.DEADWOOD, 10.0)

# Bog (B) and roots (r) by neighbour mask over the path, ancient stumps (u), and one mushroom ring over the 3×3 from
# the k cells' top-left.
# The Kinship bond ({"kin": true}, Old Kin: "a Kinship grows a stage at once"): a vine between each two neighbouring
# Wardens' feet; one stage before, a stage brighter and fuller after (the gift scene's After half).
func _draw_kin(canvas: Node2D) -> void:
	var stage := 2 if _in_scene and _showing_after else 1
	var feet: Array[Vector2] = []
	for warden in _wardens:
		feet.append(warden.sprite.position + Vector2(0, 18))
	for i in feet.size():
		for j in range(i + 1, feet.size()):
			if feet[i].distance_to(feet[j]) > CELL * 1.5:
				continue
			var a := feet[i]
			var b := feet[j]
			if stage >= 2:
				canvas.draw_line(a, b, Color(Palette.GLOW, 0.3), 10.0, true)  # The grown bond glows
			canvas.draw_line(a, b, Palette.MOSS, 4.0 + 2.0 * (stage - 1), true)
			canvas.draw_line(a, b, Palette.SPRIG, 2.0 + (stage - 1), true)
			var leaves := 2 + stage  # More leaves on the grown bond
			for k in leaves:
				var at := a.lerp(b, (k + 1.0) / (leaves + 1.0))
				var side := Vector2(0, -5 if k % 2 == 0 else 5)
				canvas.draw_circle(at + side, 3.0 + stage, Palette.SPRIG if stage < 2 else Palette.GLOW)

func _draw_gift_ground(canvas: Node2D) -> void:
	var cell_size := Vector2(CELL, CELL)
	var ring_top := Vector2i(COLS, ROWS)
	for y in ROWS:
		for x in COLS:
			var c := _cell_at(_rows, x, y)
			var cell := Vector2(x, y)
			var rect := Rect2(cell * CELL, cell_size)
			match c:
				"B":
					var bog := _sheet("bog_path")
					if bog != null:
						var mask := MapGifts._mask(cell, func(n: Vector2) -> bool: return n.x >= 0 and n.y >= 0 and _is_path(_cell_at(_rows, int(n.x), int(n.y))))
						canvas.draw_texture_rect_region(bog, rect, _frame_rect("bog_path", mask))
					else:
						canvas.draw_rect(rect.grow(-6), Color(Palette.ROOT, 0.7))
						canvas.draw_circle(rect.position + Vector2(22, 26), 7.0, Palette.POOL)
				"r":
					var roots := _sheet("heartwood_roots")
					if roots != null:
						var mask := MapGifts._mask(cell, func(n: Vector2) -> bool: return n.x >= 0 and n.y >= 0 and _is_path(_cell_at(_rows, int(n.x), int(n.y))))
						canvas.draw_texture_rect_region(roots, rect, _frame_rect("heartwood_roots", mask))
					else:
						var c2 := rect.get_center()
						canvas.draw_line(c2 + Vector2(-26, -10), c2 + Vector2(24, 12), Palette.OAK, 4.0)
						canvas.draw_line(c2 + Vector2(-20, 16), c2 + Vector2(26, -14), Palette.BARK, 3.0)
				"u":
					var stump := _sheet("ancient_stump")
					if stump != null:
						canvas.draw_texture_rect_region(stump, rect, _frame_rect("ancient_stump", EnvironmentTiles.cell_variant(Vector2i(x, y), 3)))
					else:
						canvas.draw_circle(rect.get_center(), 20.0, Palette.BARK)
						canvas.draw_arc(rect.get_center(), 14.0, 0, TAU, 20, Palette.OAK, 2.0)
				"k":
					ring_top = Vector2i(mini(ring_top.x, x), mini(ring_top.y, y))
	if ring_top.x < COLS:
		var at := Vector2(ring_top) * CELL
		var ring := _sheet("mushroom_ring")
		if ring != null:
			canvas.draw_texture_rect_region(ring, Rect2(at, cell_size * 3), _frame_rect("mushroom_ring", int(_anim * PROP_FPS) % 4))
		else:
			for i in 12:
				canvas.draw_circle(at + cell_size * 1.5 + Vector2.from_angle(TAU * i / 12.0) * CELL * 1.25, 6.0, Palette.EMBER)

# The swap's gold pulse on the changed cells, and the Before / After tag in the corner.
func _draw_overlay(canvas: Node2D) -> void:
	if _pulse_left > 0.0:
		var a := _pulse_left / PULSE_TIME
		for cell in _changed:
			var rect := Rect2(Vector2(cell) * CELL, Vector2(CELL, CELL)).grow(-3.0)
			canvas.draw_rect(rect, Color(Palette.GOLD, 0.28 * a))
			canvas.draw_rect(rect, Color(Palette.GOLD, 0.9 * a), false, 3.0)
	var font := UiStyle.caps_font()
	var tag := "After" if _showing_after else "Before"
	canvas.draw_string_outline(font, Vector2(10, 30), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 6, Palette.DREAD)
	canvas.draw_string(font, Vector2(10, 30), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, UiStyle.GOLD if _showing_after else UiStyle.INK)

# The cells that differ between the before and after diagrams.
static func diff_cells(before: String, after: String) -> Array[Vector2i]:
	var a := before.strip_edges().split("\n")
	var b := after.strip_edges().split("\n")
	var out: Array[Vector2i] = []
	for y in ROWS:
		for x in COLS:
			var ca: String = a[y][x] if y < a.size() and x < a[y].length() else "."
			var cb: String = b[y][x] if y < b.size() and x < b[y].length() else "."
			if ca != cb:
				out.append(Vector2i(x, y))
	return out

# Before ↔ after: the other diagram, faded in; the walkers keep their places, moved onto the new path.
func _swap() -> void:
	var places: Array[Vector2] = []
	for walker in _walkers:
		if walker.fade < 0.0 and is_instance_valid(walker.sprite):
			places.append(walker.sprite.position)
	_showing_after = not _showing_after
	_build(_after if _showing_after else _before)
	_changed = diff_cells(_before, _after)
	_pulse_left = PULSE_TIME if _showing_after else 0.0
	_fade_left = SWAP_FADE
	_world.modulate.a = 0.35  # multiplier: the fade in
	_phase_left = AFTER_TIME if _showing_after else BEFORE_TIME
	if _path.size() >= 2:
		for place in places:
			_spawn_walker(_closest_distance(place))
		_spawn_left = SPAWN_EVERY

# How far along the path the point nearest `at` is.
func _closest_distance(at: Vector2) -> float:
	var best := 0.0
	var best_gap := INF
	var walked := 0.0
	for i in _path.size() - 1:
		var a := _path[i]
		var b := _path[i + 1]
		var point := Geometry2D.get_closest_point_to_segment(at, a, b)
		var gap := point.distance_to(at)
		if gap < best_gap:
			best_gap = gap
			best = walked + a.distance_to(point)
		walked += a.distance_to(b)
	return best

func _draw_marks(canvas: Node2D, rows: PackedStringArray) -> void:
	for y in ROWS:
		for x in COLS:
			var c := _cell_at(rows, x, y)
			var rect := Rect2(Vector2(x, y) * CELL, Vector2(CELL, CELL)).grow(-3.0)
			if c == "*":
				canvas.draw_rect(rect, Color(Palette.GOLD, 0.16))
				canvas.draw_rect(rect, Color(Palette.GOLD, 0.45), false, 2.0)
			elif c == "+" or c.is_valid_int() or c == "X" or c == "Q" or c == "U":
				canvas.draw_rect(rect, Color(Palette.GOLD, 0.8), false, 3.0)

# A diagram with no path gets one along its emptiest row (no Wardens, walls, obstacles or stumps on it), the one
# nearest the Wardens, so the nightmares walk past them.
func _with_path(rows: PackedStringArray) -> PackedStringArray:
	for y in ROWS:
		for x in COLS:
			if _is_path(_cell_at(rows, x, y)):
				return rows
	var warden_rows: Array[int] = []
	for y in ROWS:
		for x in COLS:
			if (QUALIFYING + OTHERS + WALLS).contains(_cell_at(rows, x, y)):
				warden_rows.append(y)
	var best := -1
	var best_cost := INF
	for y in ROWS:
		var empty := true
		for x in COLS:
			if not ".*".contains(_cell_at(rows, x, y)):
				empty = false
		if not empty:
			continue
		var cost := 0.0
		for r in warden_rows:
			cost += absf(r - y)
		if cost < best_cost:
			best_cost = cost
			best = y
	if best < 0:
		return rows
	var out := PackedStringArray(rows)
	while out.size() < ROWS:
		out.append(".".repeat(COLS))
	out[best] = "P".repeat(COLS)
	return out

# Where nightmares enter when there's no S: a path end on the map's edge (one path neighbour), else any end.
func _open_end(rows: PackedStringArray) -> Vector2i:
	var any_end := Vector2i(-1, -1)
	for y in ROWS:
		for x in COLS:
			if not _is_path(_cell_at(rows, x, y)) or _cell_at(rows, x, y) == "H":
				continue
			var neighbours := 0
			for d in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
				var n: Vector2i = Vector2i(x, y) + d
				if n.x >= 0 and n.y >= 0 and n.x < COLS and n.y < ROWS and _is_path(_cell_at(rows, n.x, n.y)):
					neighbours += 1
			if neighbours <= 1:
				if x == 0 or y == 0:
					return Vector2i(x, y)  # Prefer the left / top edge: they walk in from there
				if any_end.x < 0:
					any_end = Vector2i(x, y)
	return any_end

# The path cells in walking order: from the start, each step to the one path neighbour not yet walked.
func _walk_order(rows: PackedStringArray, start: Vector2i) -> Array[Vector2]:
	var order: Array[Vector2] = []
	if start.x < 0:
		return order
	var seen := {start: true}
	var at := start
	order.append(_centre(at))
	while true:
		var next := Vector2i(-1, -1)
		for d in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
			var n: Vector2i = at + d
			if n.x >= 0 and n.y >= 0 and n.x < COLS and n.y < ROWS and not seen.has(n) and _is_path(_cell_at(rows, n.x, n.y)):
				next = n
				break
		if next.x < 0:
			break
		seen[next] = true
		order.append(_centre(next))
		at = next
	return order

func _add_warden(cell: Vector2i, c: String) -> void:
	var wall := WALLS.contains(c)
	var data: TowerData = THORNWALL if wall else (SPROUT if card != null and SPROUT_CARDS.has(card.id) else WARDEN)
	if c == "X":
		_walls.append(_centre(cell))
	var sprite := Sprite2D.new()
	sprite.texture = data.texture
	sprite.hframes = maxi(data.frame_count, 1)
	sprite.offset = Vector2(0, -16) + data.get_sprite_offset()  # 64×96: the bottom 64 px on the cell
	sprite.position = _centre(cell)
	sprite.z_index = 1  # Over the Heartwood's canopy (the favoured Warden often stands beside it)
	if c == "w":
		sprite.modulate = Color(1, 1, 1, 0.7)  # multiplier: the one that doesn't qualify reads dimmer
	_world.add_child(sprite)
	if not wall:
		var boosted := QUALIFYING.contains(c)
		_wardens.append({"sprite": sprite, "data": data, "boosted": boosted, "cooldown": randf() * ATTACK_EVERY,
			"attack_time": -1.0, "anim": randf() * 3.0,
			"every": ATTACK_EVERY / (float(_effect.get("speed", 1.0)) if boosted else 1.0),
			"range": RANGE_CELLS + (float(_effect.get("range", 0.0)) if boosted else 0.0)})

func _process(delta: float) -> void:
	if _world == null or _path.size() < 2:
		return
	delta = real_delta(delta)  # Real time (user: "make sure the video previews aren't sped up"): 1×, 2×, 3× or paused alike
	var sprite_speed := 1.0 / maxf(Engine.time_scale, 0.001)  # AnimatedSprite2D frames run on scaled time
	for walker in _walkers:
		if is_instance_valid(walker.sprite):
			walker.sprite.speed_scale = sprite_speed
	if _in_scene and _tick_scene(delta):
		return  # Swapped: the new diagram starts next frame
	_spawn_left -= delta
	if _spawn_left <= 0.0 and _walkers.size() < NIGHTMARES:
		_spawn_left = SPAWN_EVERY
		_spawn_walker()
	_move_walkers(delta)
	for warden in _wardens:
		_animate_warden(warden, delta)
	_tick_effects(delta)

# Gift scenes: the phase clock, the swap's fade and pulse, the props' frames. True when it just swapped.
func _tick_scene(delta: float) -> bool:
	_anim += delta
	for prop in _props:
		prop.queue_redraw()
	if _fade_left > 0.0:
		_fade_left = maxf(_fade_left - delta, 0.0)
		_world.modulate.a = 1.0 - 0.65 * _fade_left / SWAP_FADE  # multiplier: the fade in
	if _pulse_left > 0.0:
		_pulse_left = maxf(_pulse_left - delta, 0.0)
	if _overlay != null:
		_overlay.queue_redraw()
	_phase_left -= delta
	if _phase_left <= 0.0:
		_swap()
		return true
	return false

# A frame's delta in real seconds, whatever the game speed (capped, so a hitch doesn't jump the scene). Previews use it.
static func real_delta(delta: float) -> float:
	return minf(delta / maxf(Engine.time_scale, 0.001), 0.1)

func _spawn_walker(distance: float = 0.0) -> void:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = NIGHTMARE.sprite_frames
	sprite.speed_scale = 1.0 / maxf(Engine.time_scale, 0.001)  # Real time
	sprite.scale = Vector2.ONE * NIGHTMARE.sprite_scale
	sprite.play(&"walk_side")
	sprite.position = _along(distance)[0]
	_world.add_child(sprite)
	_walkers.append({"sprite": sprite, "distance": distance, "hits": 0.0, "fade": -1.0, "procs": {}})
	_spawned += 1

# Position `distance` px along the path, and the direction there.
func _along(distance: float) -> Array:
	for i in _path.size() - 1:
		var step := _path[i].distance_to(_path[i + 1])
		if distance <= step:
			return [_path[i].lerp(_path[i + 1], distance / step), _path[i + 1] - _path[i]]
		distance -= step
	return [_path[-1], Vector2.ZERO]

func _move_walkers(delta: float) -> void:
	for walker in _walkers.duplicate():
		var sprite: AnimatedSprite2D = walker.sprite
		if walker.fade >= 0.0:  # Dispelled: it cracks with light and fades
			walker.fade += delta
			sprite.modulate = Color(1.6, 1.6, 1.4, 1.0 - walker.fade / 0.4)  # multiplier: the dispel flash
			if walker.fade >= 0.4:
				sprite.queue_free()
				_walkers.erase(walker)
			continue
		walker.distance += WALK_SPEED * delta * (BOG_SPEED if _letter_at(sprite.position) == "B" else 1.0)  # Bog (gift scenes)
		var at: Array = _along(walker.distance)
		sprite.position = at[0]
		var dir: Vector2 = at[1]
		var animation := &"walk_side" if absf(dir.x) >= absf(dir.y) else (&"walk_down" if dir.y > 0 else &"walk_up")
		if sprite.animation != animation:
			sprite.play(animation)
		sprite.flip_h = dir.x < 0
		var proc: String = _effect.get("proc", "")
		if proc != "":  # Passing a marked Thornwall: the card's effect on it, once per wall per pass
			for i in _walls.size():
				if not walker.procs.has(i) and sprite.position.distance_to(_walls[i]) <= CELL * 1.05:
					walker.procs[i] = true
					_float_text(proc, sprite.position, true)
					walker.hits += 1.0
		if dir == Vector2.ZERO:  # Reached the end: back to the start (the loop)
			walker.distance = 0.0
			walker.hits = 0.0
			walker.procs = {}

func _animate_warden(warden: Dictionary, delta: float) -> void:
	var sprite: Sprite2D = warden.sprite
	var data: TowerData = warden.data
	warden.anim += delta
	if warden.attack_time >= 0.0 and data.attack_texture != null:
		warden.attack_time += delta
		var frame := int(warden.attack_time * data.attack_animation_fps)
		if frame >= data.attack_frame_count:
			warden.attack_time = -1.0
		else:
			sprite.texture = data.attack_texture
			sprite.hframes = data.attack_frame_count
			sprite.frame = frame
			if frame == data.attack_release_frame and not warden.get("released", false):
				warden.released = true
				_release(warden)
			return
	sprite.texture = data.texture
	sprite.hframes = maxi(data.frame_count, 1)
	sprite.frame = int(warden.anim * data.animation_fps) % maxi(data.frame_count, 1)
	warden.cooldown -= delta
	if warden.cooldown <= 0.0 and _target(warden) != null:
		warden.cooldown = warden.every
		warden.attack_time = 0.0
		warden.released = false
		if data.attack_texture == null:
			_release(warden)

# The nightmare in range furthest along (the real targeting rule), or null.
func _target(warden: Dictionary) -> Variant:
	var best := {}
	for walker in _walkers:
		if walker.fade < 0.0 and warden.sprite.position.distance_to(walker.sprite.position) <= warden.range * CELL \
				and (best.is_empty() or walker.distance > best.distance):
			best = walker
	return best if not best.is_empty() else null

func _release(warden: Dictionary) -> void:
	var walker = _target(warden)
	if walker == null:
		return
	var puff := Sprite2D.new()
	puff.texture = warden.data.projectile_texture
	if puff.texture != null:
		puff.hframes = maxi(puff.texture.get_width() / 16, 1)
	puff.position = warden.sprite.position + Vector2(0, -24)
	_world.add_child(puff)
	_effects.append({"node": puff, "walker": walker, "kind": "puff", "boosted": warden.boosted, "time": 0.0})

func _tick_effects(delta: float) -> void:
	for effect in _effects.duplicate():
		effect.time += delta
		var node = effect.node  # A puff (Sprite2D) or a number (Label)
		if effect.kind == "puff":
			var walker: Dictionary = effect.walker
			var target: Vector2 = walker.sprite.position if is_instance_valid(walker.sprite) else node.position
			var step := PUFF_SPEED * delta
			if node.position.distance_to(target) <= step or not is_instance_valid(walker.sprite):
				node.queue_free()
				_effects.erase(effect)
				if is_instance_valid(walker.sprite) and walker.fade < 0.0:
					_hit(walker, effect.boosted)
			else:
				node.rotation = (target - node.position).angle()
				node.position = node.position.move_toward(target, step)
				if node is Sprite2D and node.hframes > 1:
					node.frame = int(effect.time * 12.0) % node.hframes
		else:  # A floating number
			node.position.y -= NUMBER_RISE * delta / NUMBER_TIME
			node.modulate.a = clampf(1.5 - effect.time / NUMBER_TIME * 1.5, 0.0, 1.0)
			if effect.time >= NUMBER_TIME:
				node.queue_free()
				_effects.erase(effect)

# A hit: the number floats up (gold with the card's bonus for the favoured Warden, "+30% · 13"; white "10" for the
# rest), the nightmare flinches, and enough hits dispel it.
func _hit(walker: Dictionary, boosted: bool) -> void:
	boosted = boosted or _letter_at(walker.sprite.position) == "r"  # Root-covered path (gift scenes): the effect shows on hits there
	var damage: float = float(_effect.get("damage", 1.0)) if boosted else 1.0
	walker.hits += damage
	_float_text(hit_text(boosted), walker.sprite.position, boosted)

# What a hit shows: "×2 · 20", "+30% · 13", "+30% speed · 10", or plain "10".
func hit_text(boosted: bool) -> String:
	if not boosted:
		return str(BASE_HIT)
	var number := roundi(BASE_HIT * float(_effect.get("damage", 1.0)))
	var text: String = _effect.get("text", "")
	return "%s · %d" % [text, number] if text != "" else str(number)

func _float_text(text: String, at: Vector2, gold: bool) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", UiStyle.number_font())
	label.add_theme_font_size_override("font_size", 24 if gold else 20)
	label.add_theme_color_override("font_color", UiStyle.GOLD if gold else UiStyle.INK)
	label.add_theme_color_override("font_outline_color", Palette.DREAD)
	label.add_theme_constant_override("outline_size", 6)
	label.position = at + Vector2(-20, -60)
	label.z_index = 5
	_world.add_child(label)
	_effects.append({"node": label, "kind": "number", "time": 0.0})
	if _walkers.any(func(w: Dictionary) -> bool: return w.fade < 0.0 and w.hits >= HITS_TO_DISPEL):
		for w in _walkers:
			if w.fade < 0.0 and w.hits >= HITS_TO_DISPEL:
				w.fade = 0.0
