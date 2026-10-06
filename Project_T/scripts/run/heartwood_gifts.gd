extends Node
class_name HeartwoodGifts

# Heartwood's Gifts (heartwood_gifts.md, Spire experiment; replaces the per-rest choices): at each act break (the rests
# after the bosses at 25 / 50 / 75), after the Dream and the family pick and before the Omen, 3 gifts from the pool,
# at least MIN_MAP of them shaping the map, never one already taken this run. Pick one (map gifts are placed with a
# ghost on the gift screen, GiftScreen), or let them pass for PASS_DEW Dew × the act.
# Effects belong to the systems they touch: their owners register a static Callable per gift id
#   HeartwoodGifts.register(&"spring", MyScript.apply_spring)   # apply_spring(main: Node, placement: Dictionary)
# and the same call rebuilds it on a resumed run (placement["restoring"] = true). Only gifts with an effect (built in
# here, or registered) are drawn, so the pool grows as the code chats add theirs. Made by the HUD; saved by RunSaver.

signal offer_ready(gifts: Array[StringName], act: int)
signal offer_closed
signal gift_taken(id: StringName, placement: Dictionary)

const GROUP := &"heartwood_gifts"
const OFFER_SIZE := 3
const MIN_MAP := 2
const PASS_DEW := 30
const THICK_MIST_SPACING := 1.25

# id -> {name, group, text, map: changes the map, place: how it's placed (GiftPlacer), size}.
# place: &"none"; &"chain" (adjacent cells, size [min, max]); &"line" (straight, [min, max]); &"cell" (one);
# &"cells" (size n, anywhere); &"path" (size n connected route cells); &"area" (size Vector2i); &"move" (n obstacles);
# &"warden" (pick a Warden); &"kinship" (pick a bonded Warden); &"rim" (pick 1 of `size` new start spots: Environment's
# MapGifts.start_options / route_from_start).
const POOL := {
	&"sow_ridge": {"name": "Sow a Ridge", "group": "Shape the land", "map": true, "place": &"chain", "size": [3, 5],
		"text": "Draw a ridge of 3–5 Withered Trees, cell by cell. Sheltered: attacking Wardens touching it deal 10% more damage. Clearable later at the normal cost."},
	&"fallen_giant": {"name": "Fallen Giant", "group": "Shape the land", "map": true, "place": &"line", "size": [2, 4],
		"text": "Lay a Fallen Log 2–4 cells long, straight, where you choose. High ground: attacking Wardens touching it get +0.5 range. It can't be cleared this run."},
	&"glade": {"name": "Glade", "group": "Shape the land", "map": true, "place": &"obstacles", "size": 5,
		"text": "Clear up to 5 obstacles of your choice, free. Each still counts as tended."},  # Picked one by one (user)
	&"shift_stones": {"name": "Shift the Stones", "group": "Shape the land", "map": true, "place": &"move", "size": 3,
		"text": "Move up to 3 obstacles to new empty cells. Each one moved pays 20 Dew × the act, and the ground it leaves is fertile: the next Warden planted there costs half."},
	&"mire": {"name": "Mire", "group": "Shape the land", "map": true, "place": &"path", "size": 3,
		"text": "3 connected path cells turn to bog: nightmares move 20% slower there."},
	&"spring": {"name": "Spring", "group": "Living ground", "map": true, "place": &"area", "size": Vector2i(2, 2),
		"text": "A 2×2 pond. Water Wardens beside it deal +20%; {damp} lasts 1 s longer within 2 cells."},
	&"mushroom_ring": {"name": "Mushroom Ring", "group": "Living ground", "map": true, "place": &"area", "size": Vector2i(3, 3),
		"text": "A ring of toadstools on a 3×3 patch. Spore Wardens touching it get +2 {spored} cap."},
	&"lightning_tree": {"name": "Lightning Tree", "group": "Living ground", "map": true, "place": &"cell", "size": 1,
		"text": "A dead tree you place. {static} bolts within 2 cells of it deal +25%."},
	&"moonwell": {"name": "Moonwell", "group": "Living ground", "map": true, "place": &"cell", "size": 1,
		"text": "A lit stone cell. Wardens beside it (not diagonally) get +1 range."},
	&"bell_stone": {"name": "Bell Stone", "group": "Living ground", "map": true, "place": &"cell", "size": 1,
		"text": "A singing stone. Song Wardens within 1 cell pulse 15% faster."},
	&"ancient_stump": {"name": "Ancient Stump", "group": "Living ground", "map": true, "place": &"cells", "size": 3,
		"text": "3 stumps: a Warden planted on one starts at rank I."},
	&"heartwood_roots": {"name": "Heartwood Roots", "group": "The nightmares' way", "map": true, "place": &"none", "size": 0,
		"text": "Roots over the last 4 path cells before the Heartwood: nightmares there take 15% more damage."},
	&"thick_mist": {"name": "Thick Mist", "group": "The nightmares' way", "map": false, "place": &"none", "size": 0,
		"text": "For the next act, nightmares leave the start mist 25% further apart."},
	&"bramble_verge": {"name": "Bramble Verge", "group": "The nightmares' way", "map": false, "place": &"none", "size": 0,
		"text": "Thornwalls cost half this run; nightmares touching one gain +1 {drowsy} cap."},
	&"old_kin": {"name": "Old Kin", "group": "Heartwood and kin", "map": false, "place": &"kinship", "size": 1,
		"text": "One Kinship jumps a stage; new bonds start one stage up for the next act."},
	&"shifting_mist": {"name": "Shifting Mist", "group": "Heartwood and kin", "map": true, "place": &"rim", "size": 3,
		"text": "The start mist moves: pick one of 3 spots on the rim (or keep it). Nightmares come from there for the rest of the run. Fresh ground: this act's Dew pots are +10%."},
	&"waking_root": {"name": "Waking Root", "group": "Heartwood and kin", "map": false, "place": &"none", "size": 0,
		"text": "The next form you unlock costs 1 less Dreamlight."},
	&"memory_seed": {"name": "Memory Seed", "group": "Heartwood and kin", "map": false, "place": &"warden", "size": 1,
		"text": "Choose a Warden: this act, selling and replanting it keeps its ranks and Kinship age."},
}
const BUILT_IN: Array[StringName] = [&"thick_mist"]  # Effects that live here

static var _effects := {}  # Gift id -> Callable(main, placement): registered by the owning systems

static var _release_hooked := false

static func register(id: StringName, apply: Callable) -> void:
	_effects[id] = apply
	_hook_release()

# Callables keep their scripts (and lambdas their owners): let go at quit, or Godot crashes at exit. Owners may
# register from _static_init, before there's a tree: hooked at the first chance (here, or when the node is ready).
static func _hook_release() -> void:
	if _release_hooked:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		UiStyle.release_at_exit(func() -> void: _effects.clear())
		_release_hooked = true

static func has_effect(id: StringName) -> bool:
	return BUILT_IN.has(id) or _effects.has(id)

static func find(node: Node) -> HeartwoodGifts:
	return node.get_tree().get_first_node_in_group(GROUP) as HeartwoodGifts if node.is_inside_tree() else null

var drift_director: DriftDirector
var run_state: RunState
var taken: Array = []  # [{id, act, placement}] in order
var passed: Array = []  # [act, …] acts whose gifts were let pass
var current_offer: Array[StringName] = []
var waiting := false  # An offer is owed at this act break (shown, waiting behind the Dream, or minimised)
var offer_act := 0

func _init(director: DriftDirector = null) -> void:
	drift_director = director

func _ready() -> void:
	name = "HeartwoodGifts"
	add_to_group(GROUP)
	_hook_release()  # Effects registered from _static_init (no tree yet then)
	run_state = drift_director.get_node_or_null("%RunState")
	drift_director.rest_started.connect(_on_rest_started)
	drift_director.rest_ended.connect(func(_block: int) -> void:
		if waiting:
			let_pass()  # Never carried into a drift
	)

# Off in the demo (heartwood_gifts.md); acts 1–3's breaks only (the Hollow Oak's is the win).
func _on_rest_started(_block: int, boss_rest: bool, _bonus: int, _perfect: bool) -> void:
	if not boss_rest or ResultsScreen.is_demo() or not drift_director.has_next_drift():
		return
	var act := drift_director.get_act(drift_director.drifts_started)
	if taken.any(func(t: Dictionary) -> bool: return int(t.act) == act) or passed.has(act):
		return  # Already given this act (a resumed run)
	current_offer = draw(act)
	if current_offer.is_empty():
		return
	offer_act = act
	waiting = true
	offer_ready.emit(current_offer, act)

func is_offering() -> bool:
	return waiting

# 3 gifts with an effect, never taken this run, at least MIN_MAP shaping the map (as many as there are), in a
# seeded order (the map seed and the act: a resumed run draws the same).
func draw(act: int) -> Array[StringName]:
	var rng := RandomNumberGenerator.new()
	var map := drift_director.get_node_or_null("%MapGenerator")
	rng.seed = hash([int(map.map_seed) if map != null else 0, act, "heartwood_gifts"])
	var taken_ids := taken.map(func(t: Dictionary) -> StringName: return StringName(t.id))
	var maps: Array[StringName] = []
	var others: Array[StringName] = []
	for id in POOL:
		if taken_ids.has(id) or not has_effect(id):
			continue
		(maps if POOL[id].map else others).append(id)
	_shuffle(maps, rng)
	_shuffle(others, rng)
	var offer: Array[StringName] = []
	for id in maps.slice(0, MIN_MAP):
		offer.append(id)
	var rest: Array[StringName] = []
	rest.append_array(maps.slice(MIN_MAP))
	rest.append_array(others)
	_shuffle(rest, rng)
	for id in rest:
		if offer.size() >= OFFER_SIZE:
			break
		offer.append(id)
	_shuffle(offer, rng)
	return offer

static func _shuffle(list: Array, rng: RandomNumberGenerator) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = list[i]
		list[i] = list[j]
		list[j] = swap

static func needs_placing(id: StringName) -> bool:
	return POOL.has(id) and POOL[id].place != &"none"

# Takes `id` (placed at `placement`: {cells, from, to, tower, …} as GiftPlacer built it) and applies it.
func choose(id: StringName, placement: Dictionary = {}) -> void:
	if not waiting or not current_offer.has(id):
		return
	var place := placement.duplicate()
	place["tended_before"] = run_state.tended_cells.size()  # Environment: tended before this gift vs after (resume)
	var map := drift_director.get_node_or_null("%MapGenerator")
	if id == &"heartwood_roots" and map != null and map.get("gifts") != null and map.gifts.has_method("roots_cells"):
		place["cells"] = map.gifts.roots_cells()  # The route at pick time (on resume the Wardens come back after)
	var record := {"id": String(id), "act": offer_act, "placement": _plain(place)}
	taken.append(record)
	_apply(id, record.placement, false)
	_payoff(id, place, offer_act)  # Once, at the pick (a resume restores the fertile cells from the run save)
	_close()
	gift_taken.emit(id, placement)

func let_pass() -> void:
	if not waiting:
		return
	passed.append(offer_act)
	var map := drift_director.get_node_or_null("%MapGenerator")
	var at: Vector2 = map.MAP_GRID.calculate_map_position(map.endPath) if map != null else Vector2.ZERO
	run_state.earn_dew_at(pass_dew(), at)
	_close()

func pass_dew() -> int:
	return PASS_DEW * maxi(offer_act, 1)

func _close() -> void:
	waiting = false
	current_offer = []
	offer_closed.emit()

func _apply(id: StringName, placement: Dictionary, restoring: bool) -> void:
	if BUILT_IN.has(id):
		return  # Read where they act (get_spacing_multiplier)
	if _effects.has(id):
		var data := placement.duplicate(true)
		data["restoring"] = restoring
		_effects[id].call(drift_director.owner, data)

# Thick Mist: the act after the one it was taken at leaves the mist further apart (DriftDirector schedule "spacing").
func get_spacing_multiplier(drift: int) -> float:
	var act := drift_director.get_act(drift)
	for t in taken:
		if StringName(t.id) == &"thick_mist" and int(t.act) + 1 == act:
			return THICK_MIST_SPACING
	return 1.0

# Map gifts all pay off (heartwood_gifts.md b3e464e6, user: "everything gives buffs or more resources"). Main's part:
# Shift the Stones pays SHIFT_DEW × act per stone moved and leaves each old spot fertile (RunState.fertile_cells: the
# next Warden planted there costs half, as Reclaimed Earth); Shifting Mist adds MIST_POT_BONUS to the next act's Dew
# pots (the act it opens: gifts come at the act break, `act` is the act that ended). Balancing Discussion sets the numbers.
const SHIFT_DEW := 20
const MIST_POT_BONUS := 0.10

func _payoff(id: StringName, placement: Dictionary, act: int) -> void:
	if id != &"shift_stones":
		return
	var froms := cells_of(placement, "from")
	if froms.is_empty():
		return
	for cell in froms:
		run_state.fertile_cells[cell] = true
	var map := drift_director.get_node_or_null("%MapGenerator")
	var at: Vector2 = map.MAP_GRID.calculate_map_position(froms[0]) if map != null else Vector2.ZERO
	run_state.earn_dew_at(SHIFT_DEW * maxi(act, 1) * froms.size(), at)

# DriftDirector.get_dew_pot_multiplier: Shifting Mist's bonus on the act after the break it was taken at.
func get_dew_pot_multiplier(number: int) -> float:
	var act := drift_director.get_act(number)
	for t in taken:
		if StringName(t.id) == &"shifting_mist" and int(t.act) + 1 == act:
			return 1.0 + MIST_POT_BONUS
	return 1.0

func has_taken(id: StringName) -> bool:
	return taken.any(func(t: Dictionary) -> bool: return StringName(t.id) == id)

# Cells (Vector2) as [x, y] pairs for JSON; back with _cells_of.
static func _plain(placement: Dictionary) -> Dictionary:
	var out := {}
	for key in placement:
		var value = placement[key]
		if value is Array or value is PackedVector2Array:
			var list := []
			for v in value:
				list.append([v.x, v.y] if v is Vector2 else v)
			out[key] = list
		elif value is Vector2:
			out[key] = [value.x, value.y]
		elif value is Object:
			continue  # Nodes (a Warden): owners record what they need by cell
		else:
			out[key] = value
	return out

static func cells_of(placement: Dictionary, key: String = "cells") -> Array[Vector2]:
	var cells: Array[Vector2] = []
	for v in placement.get(key, []):
		cells.append(v if v is Vector2 else Vector2(float(v[0]), float(v[1])))
	return cells

func to_save() -> Dictionary:
	return {"taken": taken.duplicate(true), "passed": passed.duplicate()}

# A resumed run: the gifts come back, and their effects are rebuilt (before the Wardens: RunSaver's order).
func load_save(data: Dictionary) -> void:
	taken = data.get("taken", []).duplicate(true)
	passed = data.get("passed", []).duplicate()
	for t in taken:
		_apply(StringName(t.id), t.get("placement", {}), true)
