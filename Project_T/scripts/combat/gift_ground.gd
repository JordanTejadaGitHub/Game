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
const MARK_GIFTS: Array[StringName] = [SPRING, MUSHROOM_RING, LIGHTNING_TREE, MOONWELL, BELL_STONE, STUMP]

# Numbers (Balancing Discussion's starting values).
const SPRING_DAMAGE := 0.20  # Water Wardens beside the Spring
const SPRING_SOAK_SECONDS := 1.0  # Soaked lasts longer on nightmares…
const SPRING_SOAK_REACH := 2  # …within this many cells of it
const RING_SPORED_CAP := 2  # Spore Wardens touching the ring: +2 Poisoned cap
const LIGHTNING_BOLT := 0.25  # Charged bolts…
const LIGHTNING_REACH := 2  # …within this many cells of the tree
const MOONWELL_RANGE := 1.0  # Wardens in its 4 orthogonal cells (not all 8: too much)
const BELL_SPEED := 0.15  # Song Wardens within 1 cell pulse faster
const STUMP_RANK := 1  # A Warden planted on a stump starts at rank I
const BRAMBLE_COST := 0.5  # Thornwalls cost half this run…
const BRAMBLE_DROWSY_CAP := 1  # …and nightmares touching one get +1 Drowsy cap
const THORNWALL := "thornwall"
const NO_CELL := Vector2(-1, -1)

var marks := {}  # Gift id -> Array[Vector2] (cells)
var bramble_verge := false
var old_kin_act := 0  # New Kinship bonds start one stage up while the run is in this act (0 = none)
var memory_act := 0  # Memory Seed: the act it holds through (0 = none)
var memory_cell := NO_CELL  # …where the chosen Warden stands (by cell: a resumed run restores gifts before Wardens)
var memory_kind := ""  # …its form, remembered once it's sold, until one of that form is planted again
var memory_state := {}  # …{"rank", "choices", "focus", "partners": {partner instance id: bond age}} (not saved)
var version := 0  # Bumped on any change (Tower._stats_fresh reads it)

static var _ref: WeakRef = null
var _director: DriftDirector
var _thorn_cells := {}
var _thorn_key := -1

# Registered with Main's HeartwoodGifts when this script loads (Tower loads it with the run).
# The terrain gifts' effects are Environment Code's (MapGifts places the pond, the stones…); their cells reach
# `marks` from HeartwoodGifts.taken (_sync_taken). Only the gifts with no terrain register here. An id that already
# has an effect keeps it (tests register stand-ins first).
static func _static_init() -> void:
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

# placement.cells = [the chosen Warden's cell].
static func _memory_seed_effect(main: Node, placement: Dictionary) -> void:
	var ground := find(main)
	var cells := HeartwoodGifts.cells_of(placement)
	if ground and not cells.is_empty():
		ground.set_memory_seed(cells[0], ground._next_act_of(main, &"memory_seed"))

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
	var gifts := HeartwoodGifts.find(self) if is_inside_tree() else null
	var count: int = gifts.taken.size() if gifts else 0
	if count == _synced_taken:
		return
	_synced_taken = count
	for kind in _taken_marks:
		for cell in _taken_marks[kind]:
			if marks.has(kind):
				marks[kind].erase(cell)
	_taken_marks = {}
	for t in (gifts.taken if gifts else []):
		var id := StringName(t.id)
		if MARK_GIFTS.has(id):
			var cells := HeartwoodGifts.cells_of(t.get("placement", {}))
			_taken_marks[id] = _taken_marks.get(id, []) + Array(cells)
			add_mark(id, cells)
	_changed()

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
	for tower in get_tree().get_nodes_in_group(Tower.GROUP):
		tower.clear_dream_cache()

# --- What the gifts do (Tower, Reactions, TowerPlacer read these) ------------------------------------------

# Spring: a water Warden beside the pond deals +20%.
func damage_bonus(tower: Tower) -> float:
	return SPRING_DAMAGE if tower.tower_data.line == "water" and near(SPRING, tower.get_cells(), 1) else 0.0

# Moonwell: a Warden in one of its 4 orthogonal cells gets +1 range.
func range_bonus(tower: Tower) -> float:
	return MOONWELL_RANGE if tower.tower_data.can_attack and near(MOONWELL, tower.get_cells(), 1, true) else 0.0

# Bell Stone: a song Warden within 1 cell pulses 15% faster.
func speed_bonus(tower: Tower) -> float:
	return BELL_SPEED if tower.tower_data.line == "song" and near(BELL_STONE, tower.get_cells(), 1) else 0.0

# Mushroom Ring: a spore Warden touching it raises the Poisoned (Spored) cap of what it applies.
func spored_cap_bonus(tower: Tower) -> int:
	return RING_SPORED_CAP if tower.tower_data.line == "spore" and near(MUSHROOM_RING, tower.get_cells(), 1) else 0

# Spring: Soaked lasts 1 s longer on a nightmare within 2 cells of it.
func soak_extra(at: Vector2) -> float:
	_sync_taken()
	if not marks.has(SPRING):
		return 0.0
	return SPRING_SOAK_SECONDS if near(SPRING, [Tower.MAP_GRID.calculate_grid_coordinates(at)], SPRING_SOAK_REACH) else 0.0

# Lightning Tree: a Charged bolt struck within 2 cells of it deals +25%.
func bolt_multiplier(at: Vector2) -> float:
	_sync_taken()
	if not marks.has(LIGHTNING_TREE):
		return 1.0
	return 1.0 + LIGHTNING_BOLT if near(LIGHTNING_TREE, [Tower.MAP_GRID.calculate_grid_coordinates(at)], LIGHTNING_REACH) else 1.0

# Bramble Verge: Thornwalls cost half.
func cost_multiplier(data: TowerData) -> float:
	return BRAMBLE_COST if bramble_verge and data != null and data.get_id() == THORNWALL else 1.0

# Bramble Verge: a nightmare touching a Thornwall (one of the 8 cells around it) has +1 Drowsy cap.
func drowsy_cap_bonus(enemy: Node2D) -> int:
	if not bramble_verge or not is_instance_valid(enemy):
		return 0
	var cell := Tower.MAP_GRID.calculate_grid_coordinates(enemy.global_position)
	var thorns := _thornwalls()
	for x in range(-1, 2):
		for y in range(-1, 2):
			if thorns.has(cell + Vector2(x, y)):
				return BRAMBLE_DROWSY_CAP
	return 0

# The Thornwalls' cells, kept until a Warden is planted, sold or grown (the Wardens group changes size or the
# board version moves).
func _thornwalls() -> Dictionary:
	var towers := get_tree().get_nodes_in_group(Tower.GROUP)
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	var key: int = towers.size() * 100003 + (dreams.board_version if dreams else 0)
	if key != _thorn_key:
		_thorn_key = key
		_thorn_cells = {}
		for tower in towers:
			if tower is Tower and tower.tower_data != null and tower.tower_data.get_id() == THORNWALL:
				for c in tower.get_cells():
					_thorn_cells[c] = true
	return _thorn_cells

# --- Heartwood and kin ------------------------------------------------------------------------------------

func set_bramble_verge() -> void:
	bramble_verge = true
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

# Memory Seed: the Warden on `cell` keeps its ranks and Kinship ages through a sale and a replant, through `act`.
func set_memory_seed(cell: Vector2, act: int) -> void:
	memory_cell = cell
	memory_act = act
	memory_kind = ""
	memory_state = {}
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
	if memory_cell == NO_CELL or tower.cell != memory_cell or not _memory_holds():
		return
	var partners := {}
	var kin := Kinships.find(self)
	if kin:
		partners = kin.ended_bonds(tower).duplicate()  # Its bonds ended as it left the tree (before this signal)
		for pair in kin.get_pairs(tower):
			var other: Tower = pair.b if pair.a == tower else pair.a
			if is_instance_valid(other):
				partners[other.get_instance_id()] = int(kin.ages.get(pair.key, 0))
	memory_kind = tower.tower_data.get_id()
	memory_state = {"rank": tower.rank, "choices": tower.rank_choices.duplicate(), "focus": tower.focus, "partners": partners}
	memory_cell = NO_CELL

func _on_tower_built(tower: Tower) -> void:
	# Ancient Stump: planted on a stump, a Warden starts at rank I (free: nothing invested).
	if tower.rank < STUMP_RANK and tower.can_nurture() and tower.get_cells().any(func(c) -> bool: return has_mark(STUMP, c)):
		tower.nurture(0)
	# Memory Seed: the next Warden of the remembered form takes back its ranks and its bonds' ages.
	if memory_kind != "" and tower.tower_data.get_id() == memory_kind and _memory_holds():
		tower.rank = maxi(tower.rank, int(memory_state.get("rank", 0)))
		tower.rank_choices.assign(memory_state.get("choices", []))
		tower.focus = memory_state.get("focus", tower.focus)
		tower.clear_dream_cache()
		var kin := Kinships.find(self)
		if kin:
			kin.inherit_ages(tower, memory_state.get("partners", {}))
		memory_cell = tower.cell
		memory_kind = ""
		memory_state = {}
