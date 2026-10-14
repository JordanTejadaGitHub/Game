extends Node
class_name GiftGround

# Heartwood's Gifts, the Warden side (heartwood_gifts.md 449c7437; numbers spire_difficulty.md Phase 3, Balancing
# Discussion). Main's HeartwoodGifts runs the offer, the placement and the save; the effects registered here
# (_static_init) put each placed gift's cells into `marks` (the terrain itself is Environment Code's), and
# Wardens, statuses and bolts read them through the queries below. Run-long Bramble Verge and act-long Old Kin
# and Memory Seed live here too. On a resumed run HeartwoodGifts calls the effects again (restoring) before the
# Wardens come back, so nothing here needs its own save. Made in the run's scene on first use (find).

const GROUP := &"gift_ground"

# Terrain marks (cells), by gift id.
const SPRING := &"spring"  # The 2×2 pond
const MUSHROOM_RING := &"mushroom_ring"  # The 3×3 ring of toadstools
const LIGHTNING_TREE := &"lightning_tree"
const MOONWELL := &"moonwell"
const BELL_STONE := &"bell_stone"
const STUMP := &"ancient_stump"  # 3 stumps
const MARK_GIFTS: Array[StringName] = [SPRING, MUSHROOM_RING, LIGHTNING_TREE, MOONWELL, BELL_STONE, STUMP, SOW_RIDGE, FALLEN_GIANT]
# Every gift gives a buff or a resource (heartwood_gifts.md b3e464e6; Balancing f32488cd). Attacking Wardens only
# (walls get no boosts); "touching" = one of its halves beside one of the gift's (MapGifts' cells, by halves).
const SOW_RIDGE := &"sow_ridge"
const FALLEN_GIANT := &"fallen_giant"
const HEARTWOOD_ROOTS := &"heartwood_roots"
const MIRE := &"mire"
const BRAMBLE_VERGE := &"bramble_verge"

# --- Gifts as landmarks (heartwood_gifts.md "Gifts as landmarks", approved by the user 2026-10-13) ---------------
# Every number comes from HeartwoodGifts (num: the step the player's gift has reached), never a copy here. Landmarks
# act by themselves in a zone (HeartwoodGifts.zone_cells from the gift's edge): _process checks the nightmares every
# TICK and only tests the ones inside a zone's rectangle. Control is bounded: one Bell Stone ring and one Roots hold
# however the gift is laid out, bosses take `boss_share` of the stacks and of the Root time. Gift statuses carry no
# Warden (source null, as Omens' do); the Lightning Tree's strike is credited to the gift in the DamageLog (a
# source node named after it) under the "gift" tag. `counts` feeds the rest report.
# Amendment "every gift is generic" (b08a3a27, the user 2026-10-13: "make sure the new gifts are generic so they help
# all families"): no gift names a family, a family's status or a Warden. Spring = attack speed in its zone; Lightning
# Tree = its own strike; Bell Stone = a plain slow; Mushroom Ring = more stacks of any Warden status on a nightmare
# inside it; Fallen Giant = crit chance for anyone; Bramble Verge = a plain slow beside Brambles.
const TICK := 0.25
const GIFT_TAG := &"gift"  # The Lightning Tree's damage (not a hit, not a status tick, not a Reaction)
# The amendment's numbers until HeartwoodGifts.NUMBERS carries these keys (Roguelite Code's pool update): read from
# there the moment they exist (num), [step I, II, III] or one value. Nothing here once they land.
const PENDING := {
	&"spring": {"attack_speed": [0.25, 0.375, 0.5]},
	&"lightning_tree": {"strike_every": 4.0, "strike_damage": [150.0, 225.0, 300.0]},
	&"bell_stone": {"slow": [0.30, 0.45, 0.60], "slow_seconds": 2.0},
	&"mushroom_ring": {"status_stacks_share": [0.5, 0.75, 1.0]},
	&"bramble_verge": {"slow": 0.20},
}
var counts := {}  # Gift id -> what it did this run (strikes, nightmares slowed by a ring, Rooted)
var counts_block := {}  # …since the last rest (Main's rest report reads and clears it: take_block_counts)
var _tick := 0.0
var _bell_left := 0.0
var _tree_left := 0.0
var _zone_rects := {}  # Gift id -> Array[Rect2] (px), rebuilt with the marks
var _sources := {}  # Gift id -> Node named after the gift (DamageLog credit)
var _gifts_ref: HeartwoodGifts = null

func _gifts() -> HeartwoodGifts:
	if not is_instance_valid(_gifts_ref) and is_inside_tree():
		_gifts_ref = HeartwoodGifts.find(self)
		if _gifts_ref != null and not _gifts_ref.gift_grew.is_connected(_on_gift_grew):
			_gifts_ref.gift_grew.connect(_on_gift_grew)
	return _gifts_ref

# A landmark grew a step: every number read through num() is new.
func _on_gift_grew(_id: StringName, _step: int, _placement: Dictionary) -> void:
	_synced_taken = -1
	_changed()

# One of gift `id`'s numbers at the step the player's has reached (step I when it's only marked: tests).
func num(id: StringName, key: String) -> float:
	var gifts := _gifts()
	var step := maxi(gifts.step_of(id) if gifts else 0, 1)
	if not HeartwoodGifts.NUMBERS.get(id, {}).has(key) and PENDING.get(id, {}).has(key):
		var found = PENDING[id][key]  # Not in the pool yet (see PENDING)
		return float(found[clampi(step, 1, found.size()) - 1]) if found is Array else float(found)
	return HeartwoodGifts.stat(id, key, step)

func _zone(id: StringName) -> int:
	return int(HeartwoodGifts.zone_cells(id))

func _count(id: StringName, amount: int = 1) -> void:
	counts[id] = int(counts.get(id, 0)) + amount
	counts_block[id] = int(counts_block.get(id, 0)) + amount

# What each landmark did since the last call (the rest report: "Spring: Soaked 212 nightmares").
func take_block_counts() -> Dictionary:
	var out := counts_block
	counts_block = {}
	return out

# The node the DamageLog credits a gift's own damage to (named after the gift).
func source_of(id: StringName) -> Node:
	if not _sources.has(id) or not is_instance_valid(_sources[id]):
		var node := Node.new()
		node.name = String(HeartwoodGifts.POOL[id].name) if HeartwoodGifts.POOL.has(id) else String(id)
		add_child(node)
		_sources[id] = node
	return _sources[id]

# Whether any of `halves` is beside (or on) a half of a `kind` cell; Sow a Ridge counts only trees still standing.
func touching(kind: StringName, halves: Array) -> bool:
	_sync_taken()
	var list: Array = marks.get(kind, [])
	if list.is_empty():
		return false
	var map = get_parent().get_node_or_null("%MapGenerator") if get_parent() else null
	for mark in list:
		if kind == SOW_RIDGE and map != null and map.has_method("get_obstacle") and map.get_obstacle(mark) == null:
			continue  # Tended away: no shelter
		var lo: Vector2 = mark * 2.0 - Vector2.ONE  # The mark cell's halves, grown by one half on every side
		var hi: Vector2 = mark * 2.0 + Vector2(2, 2)
		for h in halves:
			if h.x >= lo.x and h.x <= hi.x and h.y >= lo.y and h.y <= hi.y:
				return true
	return false

func sheltered(tower: Tower) -> bool:
	return tower.tower_data.can_attack and touching(SOW_RIDGE, tower.get_halves())

func lookout(tower: Tower) -> bool:
	return tower.tower_data.can_attack and touching(FALLEN_GIANT, tower.get_halves())

# The gift buffs on `tower` as [label, stat, amount] (BuffSources shows them with their source).
func buff_rows(tower: Tower) -> Array:
	var rows: Array = []
	if not tower.tower_data.can_attack:
		return rows
	if speed_bonus(tower) > 0.0:
		rows.append(["Spring", "attack_speed", speed_bonus(tower)])
	if sheltered(tower):
		rows.append(["Sheltered (Sow a Ridge)", "damage", num(SOW_RIDGE, "damage")])
	if moonlit(tower):
		rows.append(["Moonwell (sees Hidden)", "range", num(MOONWELL, "range")])
	if lookout(tower):
		rows.append(["Lookout (Fallen Giant)", "crit", num(FALLEN_GIANT, "crit_chance")])
	return rows

const BRAMBLE := "bramble"  # Bramble Verge: Thornwall -> Bramble grows free this run (Bramble unlocked), and Brambles make nightmares Drowsy twice as fast
const THORNWALL := "thornwall"
const NO_CELL := Vector2(-1, -1)

var marks := {}  # Gift id -> Array[Vector2] (cells)
var bramble_verge := false
var old_kin_act := 0  # New Kinship bonds start one stage up while the run is in this act (0 = none)
var memory_act := 0  # Memory Seed: the act it holds through (0 = none)
var memory_cell := NO_CELL  # (Older saves: the one Warden it was placed on; now every Warden is remembered)
# …each sold Warden's {"rank", "choices", "focus", "paid", "partners": {partner instance id: bond age}} by form id,
# newest last, until one of that form is planted again (not saved).
var memory_states := {}
var version := 0  # Bumped on any change (Tower._stats_fresh reads it)

static var _ref: WeakRef = null
var _director: DriftDirector
var _thorn_cells := {}
var _thorn_key := -1

# Registered with Main's HeartwoodGifts when this script loads (Tower loads it with the run).
# The terrain gifts' effects are Environment Code's (MapGifts places the pond, the stones…); their cells reach
# `marks` from HeartwoodGifts.taken (_sync_taken). Only the gifts with no terrain register here. An id that already
# has an effect keeps it (tests register stand-ins first). Called by TowerPlacer._ready, not _static_init: a Callable
# made during a static init and kept in HeartwoodGifts' static registry crashed the engine at exit.
static func register_effects() -> void:
	_register(&"bramble_verge", _bramble_effect)
	_register(&"old_kin", _old_kin_effect)
	_register(&"memory_seed", _memory_seed_effect)

static func _register(id: StringName, effect: Callable) -> void:
	if not HeartwoodGifts.has_effect(id):
		HeartwoodGifts.register(id, effect)

static func _bramble_effect(main: Node, _placement: Dictionary) -> void:
	var ground := find(main)
	if ground:
		ground.set_bramble_verge()

# placement.cells = [the picked Warden's cell] (in a Kinship). Restoring: the stage-up is already in Kinships' save.
static func _old_kin_effect(main: Node, placement: Dictionary) -> void:
	var ground := find(main)
	if ground == null:
		return
	var act := ground._next_act_of(main, &"old_kin")
	var cells := HeartwoodGifts.cells_of(placement)
	if placement.get("restoring", false) or cells.is_empty():
		ground.old_kin_act = act
		return
	var kin := Kinships.find(main)
	var tower := ground._tower_at(cells[0])
	var pairs: Array = kin.get_pairs(tower) if kin and tower else []
	ground.grant_old_kin(pairs[0].key if not pairs.is_empty() else "", act)

# Every Warden, for the act after the break it was taken at (no placement any more; an older save's cell is ignored).
static func _memory_seed_effect(main: Node, _placement: Dictionary) -> void:
	var ground := find(main)
	if ground:
		ground.set_memory_seed(NO_CELL, ground._next_act_of(main, &"memory_seed"))

# The act a gift taken at an act break holds for: the one after the break it was taken at.
func _next_act_of(main: Node, id: StringName) -> int:
	var gifts := HeartwoodGifts.find(main)
	if gifts:
		for i in range(gifts.taken.size() - 1, -1, -1):
			if StringName(gifts.taken[i].id) == id:
				return int(gifts.taken[i].act) + 1
	return _director.get_act(_director.drifts_started + 1) if _director else 0

# The run's gift ground, made on first use inside the scene `near` belongs to.
static func find(near: Node) -> GiftGround:
	var found := active()
	if found != null or near == null or not near.is_inside_tree():
		return found
	found = near.get_tree().get_first_node_in_group(GROUP) as GiftGround
	if found == null:
		found = GiftGround.new()
		found.name = "GiftGround"
		var scene := near
		while scene.get_parent() != null and scene.get_parent() != near.get_tree().root:
			scene = scene.get_parent()
		scene.add_child(found)
	return found

# The gift ground if there is one (never makes one).
static func active() -> GiftGround:
	var node: GiftGround = _ref.get_ref() if _ref != null else null
	return node if is_instance_valid(node) and node.is_inside_tree() else null

# For the hot paths (hits, statuses, bolts, stats): the gift ground, made once the run has taken any gift
# (looked for at most once a frame while there's none).
static var _looked_frame := -1

static func active_for(near: Node) -> GiftGround:
	var node := active()
	if node != null:
		return node
	var frame := Engine.get_process_frames()
	if frame == _looked_frame or near == null or not near.is_inside_tree():
		return null
	_looked_frame = frame
	var gifts := HeartwoodGifts.find(near)
	return find(near) if gifts != null and not gifts.taken.is_empty() else null

# The version Tower's stat cache keys on (a gift taken since shows up here).
func get_version() -> int:
	_sync_taken()
	return version

func _enter_tree() -> void:
	add_to_group(GROUP)
	_ref = weakref(self)
	var scene := get_parent()
	_director = scene.get_node_or_null("%DriftDirector") as DriftDirector if scene else null
	var placer: TowerPlacer = scene.get_node_or_null("%TowerPlacer") as TowerPlacer if scene else null
	var seller: TowerSeller = scene.get_node_or_null("%TowerSeller") as TowerSeller if scene else null
	if placer and not placer.tower_built.is_connected(_on_tower_built):
		placer.tower_built.connect(_on_tower_built)
	if seller and not seller.tower_sold.is_connected(_on_tower_sold):
		seller.tower_sold.connect(_on_tower_sold)

# --- Marks -------------------------------------------------------------------------------------------------

func add_mark(kind: StringName, cells: Array) -> void:
	var list: Array = marks.get(kind, [])
	for cell in cells:
		if not list.has(Vector2(cell)):
			list.append(Vector2(cell))
	marks[kind] = list
	_changed()

func remove_mark(kind: StringName, cell: Vector2) -> void:
	if marks.has(kind):
		marks[kind].erase(cell)
		_changed()

func cells_of(kind: StringName) -> Array:
	_sync_taken()
	return marks.get(kind, [])

func has_mark(kind: StringName, cell: Vector2) -> bool:
	_sync_taken()
	return marks.has(kind) and marks[kind].has(cell)

# The placed terrain gifts' cells, from HeartwoodGifts.taken (taken at an act break, or restored on a resumed
# run): read again whenever a gift was taken since.
var _synced_taken := -1
var _taken_marks := {}  # Gift id -> cells, from taken gifts (added to `marks`)

func _sync_taken() -> void:
	var gifts := _gifts()
	var count: int = gifts.taken.size() if gifts else 0
	if count == _synced_taken:
		return
	_synced_taken = count
	_zone_rects = {}
	var terrain := _map_gifts()
	for kind in _taken_marks:
		for cell in _taken_marks[kind]:
			if marks.has(kind):
				marks[kind].erase(cell)
	_taken_marks = {}
	for t in (gifts.taken if gifts else []):
		var id := StringName(t.id)
		if MARK_GIFTS.has(id):
			var cells: Array = mark_cells(t.get("placement", {}))
			if id == LIGHTNING_TREE and terrain != null:
				var standing := terrain.lightning_trees()  # A tended Lightning Tree is gone, and its bonus with it
				cells = cells.filter(func(c: Vector2) -> bool: return standing.has(c))
			_taken_marks[id] = _taken_marks.get(id, []) + cells
			add_mark(id, cells)
	_changed()

# The mark cells of a gift's placement. Half-cell placement (heartwood_gifts.md 2554c638; Main's GiftPlacer): each
# 2×2 piece's half origin / 2 (x.5 when half-offset), which is also its obstacle key (map.get_obstacle) and puts
# touching()'s halves exactly on the piece's own; older placements keep their "cells".
static func mark_cells(placement: Dictionary) -> Array:
	if placement.has("pieces"):
		var marks_out: Array = []
		for o in HeartwoodGifts.cells_of(placement, "pieces"):
			marks_out.append(o / 2.0)
		return marks_out
	return Array(HeartwoodGifts.cells_of(placement))

# Environment Code's terrain (map_generator.gifts), followed so a gift's terrain that changes (a Lightning Tree
# tended away) is read again.
func _map_gifts() -> MapGifts:
	var map := get_parent().get_node_or_null("%MapGenerator") if get_parent() else null
	var terrain: MapGifts = map.gifts if map != null and "gifts" in map else null
	if terrain != null and not terrain.gifts_changed.is_connected(_on_terrain_changed):
		terrain.gifts_changed.connect(_on_terrain_changed)
	return terrain

func _on_terrain_changed() -> void:
	_synced_taken = -1  # Read the taken gifts and the standing terrain again on the next query

# Whether any `kind` cell is within `reach` cells of one of `cells` (8 neighbours; `orthogonal`: only the 4).
func near(kind: StringName, cells: Array, reach: int, orthogonal := false) -> bool:
	_sync_taken()
	var list: Array = marks.get(kind, [])
	if list.is_empty():
		return false
	for cell in cells:
		for mark in list:
			var d: Vector2 = (mark - Vector2(cell)).abs()
			if (d.x + d.y <= reach) if orthogonal else (maxf(d.x, d.y) <= reach):
				return true
	return false

func _changed() -> void:
	version += 1
	_zone_rects = {}
	for tower in get_tree().get_nodes_in_group(Tower.GROUP):
		tower.clear_dream_cache()

# --- What the gifts do (Tower, Reactions, TowerPlacer read these) ------------------------------------------

# Sow a Ridge: a Warden touching one of its standing trees.
func damage_bonus(tower: Tower) -> float:
	return num(SOW_RIDGE, "damage") if sheltered(tower) else 0.0

# Moonwell: an attacking Warden within its zone (2 cells, all 8 directions).
func moonlit(tower: Tower) -> bool:
	return tower.tower_data.can_attack and near(MOONWELL, tower.get_cells(), _zone(MOONWELL))

func range_bonus(tower: Tower) -> float:
	return num(MOONWELL, "range") if moonlit(tower) else 0.0

# Fallen Giant (Lookout): an attacking Warden touching the log has this much crit chance on top of its own, a Warden
# that never crits too (its crits use the usual multiplier: Tower.hit).
func crit_bonus(tower: Tower) -> float:
	return num(FALLEN_GIANT, "crit_chance") if lookout(tower) else 0.0

# Spring: every attacking Warden within its zone (2 cells) attacks faster.
func speed_bonus(tower: Tower) -> float:
	return num(SPRING, "attack_speed") if tower.tower_data.can_attack and near(SPRING, tower.get_cells(), _zone(SPRING)) else 0.0

# Mushroom Ring: `stacks` of a status a Warden puts on a nightmare standing at `at`: half again as many inside the
# ring (rounded up; the status's own cap still holds). Rooted is a duration, not stacks: unchanged.
func ring_stacks(status: StringName, stacks: int, at: Vector2) -> int:
	if stacks <= 0 or status == EnemyStatuses.HELD or not in_zone(MUSHROOM_RING, at):
		return stacks
	return ceili(stacks * (1.0 + num(MUSHROOM_RING, "status_stacks_share")))

# --- Zones (px) ---------------------------------------------------------------------------------------------

# The rectangles gift `id` acts in: each mark cell grown by its zone (cells from the gift's edge).
func zone_rects(id: StringName) -> Array:
	_sync_taken()
	if not _zone_rects.has(id):
		var rects: Array = []
		var size: Vector2 = Tower.MAP_GRID.cell_size
		var grow := float(_zone(id)) * size.x
		for mark in marks.get(id, []):
			var centre: Vector2 = Tower.MAP_GRID.calculate_map_position(mark)  # (A half-offset mark is x.5: the same line)
			rects.append(Rect2(centre - size / 2.0, size).grow(grow))
		if id == MUSHROOM_RING and rects.is_empty():
			var terrain := _map_gifts()
			for corner in (terrain.rings if terrain != null else []):
				rects.append(Rect2(Tower.MAP_GRID.calculate_map_position(corner) - size / 2.0, size * 3.0))  # Its 3×3 patch
		_zone_rects[id] = rects
	return _zone_rects[id]

func in_zone(id: StringName, at: Vector2) -> bool:
	for rect in zone_rects(id):
		if rect.has_point(at):
			return true
	return false

# --- The landmarks act (every TICK) ------------------------------------------------------------------------

func _process(delta: float) -> void:
	_tick -= delta
	if _tick > 0.0:
		return
	var step := TICK - _tick  # The time since the last check
	_tick = TICK
	_sync_taken()
	var terrain := _map_gifts()
	var roots: bool = terrain != null and not terrain.root_cells.is_empty()
	var bog: bool = terrain != null and not terrain.bog_cells.is_empty()
	var tree := zone_rects(LIGHTNING_TREE)
	var bell := zone_rects(BELL_STONE)
	var moon: bool = not marks.get(MOONWELL, []).is_empty()
	var brambles: Dictionary = _bramble_cells() if bramble_verge else {}
	if tree.is_empty() and bell.is_empty() and brambles.is_empty() and not moon and not roots and not bog:
		return
	var spawner: Node = get_parent().get_node_or_null("%EnemyContainer") if get_parent() else null
	if spawner == null or spawner.get_child_count() == 0:
		return
	var ringing := false
	if not bell.is_empty():
		_bell_left -= step
		if _bell_left <= 0.0:
			_bell_left = num(BELL_STONE, "ring_every")
			ringing = true
	var striking := false
	if not tree.is_empty():
		_tree_left -= step
		striking = _tree_left <= 0.0
	var bell_slow := num(BELL_STONE, "slow") if ringing else 0.0
	var bell_seconds := num(BELL_STONE, "slow_seconds") if ringing else 0.0
	var bramble_slow := num(BRAMBLE_VERGE, "slow") if not brambles.is_empty() else 0.0
	var rung := 0
	var strongest: Node2D = null
	var revealers: Array = _moonlit_wardens() if moon else []
	for enemy in spawner.get_enemies():
		var at: Vector2 = enemy.global_position
		var boss: bool = enemy.enemy_data.is_boss
		if ringing and _inside(bell, at):
			# Bell Stone: one ring however many stones stand; a plain slow (bosses a share of it), never a status.
			_slow(enemy, bell_slow * (num(BELL_STONE, "boss_share") if boss else 1.0), bell_seconds)
			rung += 1
		if bramble_slow > 0.0 and not enemy.is_flying():
			# Bramble Verge: a plain slow while it walks beside a Bramble (one of the 8 cells around it).
			var cell := Tower.MAP_GRID.calculate_grid_coordinates(at)
			var beside := false
			for x in range(-1, 2):
				for y in range(-1, 2):
					if brambles.has(cell + Vector2(x, y)):
						beside = true
			if beside:
				_slow(enemy, bramble_slow * (num(BELL_STONE, "boss_share") if boss else 1.0), TICK * 1.6)
		if striking and not enemy.is_hidden() and _inside(tree, at) and (strongest == null or enemy.health > strongest.health):
			strongest = enemy  # The Lightning Tree picks the strongest in its zone
		if roots or bog:
			_ground(enemy, terrain, roots, bog, boss)
		if not revealers.is_empty() and (enemy.enemy_data.hidden or enemy.is_hidden()):
			for warden in revealers:
				if warden.global_position.distance_to(at) <= warden.get_range_pixels():
					enemy.reveal_for(TICK * 3.0)  # Moonwell: its Wardens see Hidden nightmares in their range
					break
	if rung > 0:
		_count(BELL_STONE, rung)
	if strongest != null:
		# Lightning Tree: its own strike, heavy and growing with the run's health (so with the act), credited to the gift.
		_tree_left = num(LIGHTNING_TREE, "strike_every")
		strongest.take_damage(num(LIGHTNING_TREE, "strike_damage") * _health_scale(), "", false, false, source_of(LIGHTNING_TREE), GIFT_TAG)
		_count(LIGHTNING_TREE)

# A plain slow (EnemyStatuses' extra slow, as the Mire's: the strongest one counts, the slow floors still hold).
static func _slow(enemy: Node2D, amount: float, seconds: float) -> void:
	var s: EnemyStatuses = enemy.statuses
	s.slow_amount = maxf(s.slow_amount if s.slow_time > 0.0 else 0.0, amount)
	s.slow_time = maxf(s.slow_time, seconds)

# How much tougher this drift's nightmares are than the first drift's (the growth per drift and the health trial).
func _health_scale() -> float:
	if _director == null:
		return 1.0
	return _director.get_growth(maxi(_director.drifts_started, 1)) * _director.trial_health_multiplier

# The Brambles' cells, kept until a Warden is planted, sold or grown.
func _bramble_cells() -> Dictionary:
	var towers := get_tree().get_nodes_in_group(Tower.GROUP)
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	var key: int = towers.size() * 100003 + (dreams.board_version if dreams else 0)
	if key != _thorn_key:
		_thorn_key = key
		_thorn_cells = {}
		for tower in towers:
			if tower is Tower and tower.tower_data != null and tower.tower_data.get_id() == BRAMBLE:
				for c in tower.get_cells():
					_thorn_cells[c] = true
	return _thorn_cells

static func _inside(rects: Array, at: Vector2) -> bool:
	for rect in rects:
		if rect.has_point(at):
			return true
	return false

# Heartwood Roots: Rooted once on entering (bosses a share of the time), and Mire: Rooted lasts longer on the bog.
# The slow and the extra damage taken on those cells are MapGifts' (it reads the same numbers).
func _ground(enemy: Node2D, terrain: MapGifts, roots: bool, bog: bool, boss: bool) -> void:
	var half := Vector2(FindPath.point_to_node(enemy.get_route_point()))
	if roots and not enemy.has_meta(&"gift_rooted") and terrain.root_cells.has(half):
		enemy.set_meta(&"gift_rooted", true)  # Once each: the roots never hold the same nightmare twice
		var seconds := num(HEARTWOOD_ROOTS, "root_time") * (num(HEARTWOOD_ROOTS, "boss_share") if boss else 1.0)
		enemy.apply_status(EnemyStatuses.HELD, 1, seconds, 0.0, 0, "root")
		_count(HEARTWOOD_ROOTS)
	if bog:
		var on_bog: bool = terrain.bog_cells.has(half) and not enemy.is_flying()
		var s: EnemyStatuses = enemy.statuses
		if on_bog and not enemy.has_meta(&"gift_mire"):
			enemy.set_meta(&"gift_mire", float(s.duration_multipliers.get(EnemyStatuses.HELD, 1.0)))
			s.duration_multipliers[EnemyStatuses.HELD] = float(enemy.get_meta(&"gift_mire")) * num(MIRE, "rooted_multiplier")
		elif not on_bog and enemy.has_meta(&"gift_mire"):
			s.duration_multipliers[EnemyStatuses.HELD] = float(enemy.get_meta(&"gift_mire"))  # Off the bog: as it was
			enemy.remove_meta(&"gift_mire")

# The attacking Wardens the Moonwell lights.
func _moonlit_wardens() -> Array:
	var out: Array = []
	for tower in get_tree().get_nodes_in_group(Tower.GROUP):
		if tower is Tower and not tower.is_queued_for_deletion() and moonlit(tower):
			out.append(tower)
	return out

# Bramble Verge: Thornwalls cost half.
func cost_multiplier(_data: TowerData) -> float:
	return 1.0  # No gift changes planting prices now (Bramble Verge was "Thornwalls half price" until 8f46c6ac)

# Bramble Verge: growing a Thornwall into a Bramble costs no Dew this run.
func free_growth(from: TowerData, into: TowerData) -> bool:
	return bramble_verge and from != null and into != null and from.get_id() == THORNWALL and into.get_id() == BRAMBLE

# (Bramble Verge gives no Drowsy cap: Brambles slow the nightmares beside them, a plain slow, in _process.
# Kept at 0 for Reactions.drowsy_cap_bonus.)
func drowsy_cap_bonus(_enemy: Node2D) -> int:
	return 0

# --- Heartwood and kin ------------------------------------------------------------------------------------

func set_bramble_verge() -> void:
	bramble_verge = true
	var dreams: DreamState = get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState if is_inside_tree() else null
	if dreams and not dreams.unlocked.has(BRAMBLE):
		dreams.unlocked[BRAMBLE] = true  # Bramble unlocked if it wasn't
		dreams.unlocks_changed.emit()
	_changed()

# Old Kin: `pair_key` (a Kinship on the map) jumps a stage now, and new bonds start a stage up through `act`.
func grant_old_kin(pair_key: String, act: int) -> bool:
	old_kin_act = act
	_changed()
	var kin := Kinships.find(self)
	return pair_key != "" and kin != null and kin.raise_stage(pair_key)

# Stages new bonds start up (Kinships._start_age): 1 while Old Kin's act runs.
func kin_start_stages() -> int:
	if old_kin_act <= 0 or _director == null:
		return 0
	return 1 if _current_act() == old_kin_act else 0

# Memory Seed: any Warden keeps its ranks and Kinship ages through a sale and a replant, through `act`.
# (`cell` is unused now: the gift was one chosen Warden until "Gifts as landmarks".)
func set_memory_seed(cell: Vector2, act: int) -> void:
	memory_cell = cell
	memory_act = act
	memory_states = {}
	_changed()

func _current_act() -> int:
	return _director.get_act(maxi(_director.drifts_started, 1)) if _director else 1

func _memory_holds() -> bool:
	return memory_act > 0 and _current_act() <= memory_act

func _tower_at(cell: Vector2) -> Tower:
	for tower in get_tree().get_nodes_in_group(Tower.GROUP):
		if tower is Tower and not tower.is_queued_for_deletion() and tower.get_cells().has(cell):
			return tower
	return null

func _on_tower_sold(tower: Tower, _refund: int) -> void:
	if not _memory_holds() or not tower.can_nurture():
		return
	var partners := {}
	var kin := Kinships.find(self)
	if kin:
		partners = kin.ended_bonds(tower).duplicate()  # Its bonds ended as it left the tree (before this signal)
		for pair in kin.get_pairs(tower):
			var other: Tower = pair.b if pair.a == tower else pair.a
			if is_instance_valid(other):
				partners[other.get_instance_id()] = int(kin.ages.get(pair.key, 0))
	if tower.rank <= 0 and partners.is_empty():
		return  # Nothing to remember
	var kind: String = tower.tower_data.get_id()
	var held: Array = memory_states.get(kind, [])
	held.append({"rank": tower.rank, "choices": tower.rank_choices.duplicate(), "focus": tower.focus, "partners": partners,
		"paid": Array(tower.paid_ranks)})
	memory_states[kind] = held

func _on_tower_built(tower: Tower) -> void:
	# Elder Stumps: a Warden planted on a stump gets free ranks (banked: the player spends them through Nurture and
	# chooses each bonus).
	var stump_ranks := int(num(STUMP, "free_ranks"))
	if tower.rank < stump_ranks and tower.can_nurture() and tower.get_cells().any(func(c) -> bool: return has_mark(STUMP, c)):
		tower.bank_rank(stump_ranks - tower.rank)
	# Memory Seed: the next Warden of a remembered form takes back the latest one's ranks and its bonds' ages.
	var kind: String = tower.tower_data.get_id()
	var held: Array = memory_states.get(kind, [])
	if not held.is_empty() and _memory_holds():
		var state: Dictionary = held.pop_back()
		tower.rank = maxi(tower.rank, int(state.get("rank", 0)))
		tower.rank_choices.assign(state.get("choices", []))
		tower.paid_ranks.assign(state.get("paid", []))  # Free ranks stay free through the move
		tower.focus = state.get("focus", tower.focus)
		tower.clear_dream_cache()
		var kin := Kinships.find(self)
		if kin:
			kin.inherit_ages(tower, state.get("partners", {}))
