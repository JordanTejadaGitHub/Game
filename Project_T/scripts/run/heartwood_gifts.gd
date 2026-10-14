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
# The two signals the other systems hook (the API note at the end of heartwood_gifts.md):
signal gift_placed(id: StringName, placement: Dictionary, step: int)  # A gift was taken and applied (step 1)
signal gift_grew(id: StringName, step: int, placement: Dictionary)  # A landmark gained a step at an act break

const GROUP := &"heartwood_gifts"
const OFFER_SIZE := 3
const MIN_MAP := 2
const PASS_DEW := 60  # Dew x2 second pass (was 30)
const THICK_MIST_SPACING := 1.25

# --- Gifts as landmarks (heartwood_gifts.md "Gifts as landmarks", approved by the user 2026-10-13) -------------------
# Every gift has a kind. The offer is one of each (draw):
#   land      reshapes the map
#   landmark  a zone that acts by itself, and grows
# Every gift is generic (the amendment, user 2026-10-13): no effect or text names a family, a family's status or an
# attacking Warden, and no gift needs a family. `family` is "any" on every gift (kept for the screens that read it).
#   boon      a bonus for the run
const KIND_LAND := &"land"
const KIND_LANDMARK := &"landmark"
const KIND_BOON := &"boon"
const KINDS: Array[StringName] = [KIND_LAND, KIND_LANDMARK, KIND_BOON]
const ANY_FAMILY := "any"
const MAX_STEP := 3  # Landmarks grow I -> II -> III, one step at each later act break
const STEP_NAMES: Array[String] = ["", "I", "II", "III"]
const GROWS_LINE := "It grows at each later {act} break."  # Shown under a landmark's text (the gift screen)

# id -> {name, kind, family, group, text, map: changes the map, place: how it's placed (GiftPlacer), size, retired}.
# place: &"none"; &"chain" (adjacent cells, size [min, max]); &"line" (straight, [min, max]); &"cell" (one);
# &"cells" (size n, anywhere); &"path" (size n connected route cells); &"area" (size Vector2i); &"move" (n obstacles);
# &"obstacles" (clear n); &"reshape" (move OR clear up to n obstacles: placement "from" / "to" for the moved ones and
# "cells" for the cleared ones); &"warden"; &"kinship" (pick a bonded Warden); &"rim" (pick 1 of `size` new start
# spots: Environment's MapGifts.start_options / route_from_start).
# `text` is the step I text (its numbers are NUMBERS at step 1). `retired`: never offered, kept so a saved run that
# took it still loads and still works.
const POOL := {
	&"sow_ridge": {"name": "Sow a Ridge", "kind": KIND_LAND, "family": ANY_FAMILY, "group": "Shape the land", "map": true, "place": &"chain", "size": [4, 7],
		"text": "Draw a wall of 4–7 Withered Trees, cell by cell. Attacking Wardens touching it deal 30% more damage. Clearing one of its trees later gives {seeds:2} instead of {seeds:1}."},
	&"fallen_giant": {"name": "Fallen Giant", "kind": KIND_LAND, "family": ANY_FAMILY, "group": "Shape the land", "map": true, "place": &"line", "size": [3, 5],
		"text": "Place a Fallen Log 3–5 cells long, in a straight line. Nothing can trample it or burrow under it. Attacking Wardens touching it get +20% crit chance, even ones that never crit."},
	&"mire": {"name": "Mire", "kind": KIND_LAND, "family": ANY_FAMILY, "group": "Shape the land", "map": true, "place": &"path", "size": 5,
		"text": "Place a bog on 5 connected cells of path. Nightmares walk 35% slower there, and {held} lasts twice as long."},
	&"reshape": {"name": "Reshape", "kind": KIND_LAND, "family": ANY_FAMILY, "group": "Shape the land", "map": true, "place": &"reshape", "size": 6,
		"text": "Move or clear up to 6 obstacles. Each one pays {dew:60} × the {act}."},
	&"ancient_stump": {"name": "Elder Stumps", "kind": KIND_LAND, "family": ANY_FAMILY, "group": "Shape the land", "map": true, "place": &"cells", "size": 3,
		"text": "Place 3 stumps. A Warden planted on one gets 2 free {ranks}, and you choose each bonus."},
	&"shifting_mist": {"name": "Shifting Mist", "kind": KIND_LAND, "family": ANY_FAMILY, "group": "Shape the land", "map": true, "place": &"rim", "size": 3,
		"text": "Move where nightmares come from: pick one of 3 spots on the edge of the map, or keep the current one. They come from there for the rest of the run. This {act}'s {drifts} give 25% more {dew}."},
	&"spring": {"name": "Spring", "kind": KIND_LANDMARK, "family": ANY_FAMILY, "group": "Landmarks", "map": true, "place": &"area", "size": Vector2i(2, 2),
		"text": "Place a 2×2 pond. Attacking Wardens within 2 cells of it attack 25% faster."},
	&"lightning_tree": {"name": "Lightning Tree", "kind": KIND_LANDMARK, "family": ANY_FAMILY, "group": "Landmarks", "map": true, "place": &"cell", "size": 1,
		"text": "Place a dead tree on one empty cell. Every 4 s it strikes the strongest nightmare within 3 cells for heavy damage. The strike grows as nightmares get tougher."},
	&"bell_stone": {"name": "Bell Stone", "kind": KIND_LANDMARK, "family": ANY_FAMILY, "group": "Landmarks", "map": true, "place": &"cell", "size": 1,
		"text": "Place a singing stone on one empty cell. It rings every 6 s: nightmares within 3 cells walk 30% slower for 2 s (bosses half as much)."},
	&"mushroom_ring": {"name": "Mushroom Ring", "kind": KIND_LANDMARK, "family": ANY_FAMILY, "group": "Landmarks", "map": true, "place": &"area", "size": Vector2i(3, 3),
		"text": "Place a ring of toadstools on a 3×3 patch. Any status a Warden puts on a nightmare standing in it lands with half again as many {stacks}."},
	&"moonwell": {"name": "Moonwell", "kind": KIND_LANDMARK, "family": ANY_FAMILY, "group": "Landmarks", "map": true, "place": &"cell", "size": 1,
		"text": "Place a lit stone on one empty cell. Wardens within 2 cells get +1.5 range and see {hidden} nightmares."},
	&"heartwood_roots": {"name": "Heartwood Roots", "kind": KIND_LANDMARK, "family": ANY_FAMILY, "group": "Landmarks", "map": true, "place": &"none", "size": 0,
		"text": "Roots cover the last 6 cells of path before the Heartwood. Nightmares are {held} for 1 s on entering (bosses half) and take 30% more damage there."},
	&"bramble_verge": {"name": "Bramble Verge", "kind": KIND_BOON, "family": ANY_FAMILY, "group": "For the run", "map": false, "place": &"none", "size": 0,
		"text": "Thornwalls {grow} into {warden:bramble} for free this run ({warden:bramble} is unlocked if it wasn't). Nightmares beside a {warden:bramble} walk 20% slower."},
	&"old_kin": {"name": "Old Kin", "kind": KIND_BOON, "family": ANY_FAMILY, "group": "For the run", "map": false, "place": &"kinship", "size": 1,
		"text": "Pick two bonded Wardens: their bond grows one step now. Bonds formed next {act} start one step stronger."},
	&"memory_seed": {"name": "Memory Seed", "kind": KIND_BOON, "family": ANY_FAMILY, "group": "For the run", "map": false, "place": &"none", "size": 0,
		"text": "This {act}, any Warden you sell and plant again keeps its {ranks} and its {kinship} age."},
	&"waking_root": {"name": "Waking Root", "kind": KIND_BOON, "family": ANY_FAMILY, "group": "For the run", "map": false, "place": &"none", "size": 0,
		"text": "The next form you unlock is free, and you gain {dreamlight:+1}."},
	# Retired (never offered; a saved run that took one still loads and works). Reshape replaced Glade and Shift the Stones.
	&"glade": {"name": "Glade", "kind": KIND_LAND, "family": ANY_FAMILY, "group": "Shape the land", "map": true, "place": &"obstacles", "size": 5, "retired": true,
		"text": "Clear up to 5 obstacles of your choice, free. Each still counts as cleared."},
	&"shift_stones": {"name": "Shift the Stones", "kind": KIND_LAND, "family": ANY_FAMILY, "group": "Shape the land", "map": true, "place": &"move", "size": 3, "retired": true,
		"text": "Move up to 3 obstacles to empty cells. Each one moved pays {dew:60} × the {act}."},
	&"thick_mist": {"name": "Thick Mist", "kind": KIND_BOON, "family": ANY_FAMILY, "group": "For the run", "map": false, "place": &"none", "size": 0, "retired": true,
		"text": "For the next {act}, nightmares arrive 25% further apart."},
}
const BUILT_IN: Array[StringName] = [&"thick_mist"]  # Effects that live here

# The numbers behind the texts, in ONE place: Tower Code (gift_ground.gd), Environment Code (map_gifts.gd) and the
# screens read them here (HeartwoodGifts.number, or value() for the step the player's gift has reached), never a copy.
# A landmark's numbers are [step I, II, III] (about +50% a step); a single number never grows. Balancing sets the
# final values.
const NUMBERS := {
	&"spring": {"attack_speed": [0.25, 0.375, 0.50]},
	# strike_damage is x the drift's health growth x the health trial (gift_ground.gd), so it keeps pace with the run.
	&"lightning_tree": {"strike_every": 4.0, "strike_damage": [150.0, 225.0, 300.0]},
	&"bell_stone": {"ring_every": 6.0, "slow": [0.30, 0.45, 0.60], "slow_seconds": 2.0, "boss_share": 0.5},
	&"mushroom_ring": {"status_stacks_share": [0.50, 0.75, 1.00]},
	&"moonwell": {"range": [1.5, 2.25, 3.0], "reveals_hidden": 1.0},
	&"heartwood_roots": {"path_cells": [6.0, 8.0, 10.0], "root_time": 1.0, "damage_taken": [0.30, 0.45, 0.60], "boss_share": 0.5},
	&"sow_ridge": {"damage": 0.30, "tree_seeds": 2.0},
	&"fallen_giant": {"crit_chance": 0.20},
	&"mire": {"slow": 0.35, "rooted_multiplier": 2.0},
	&"reshape": {"dew_per_obstacle": 60.0},
	&"ancient_stump": {"free_ranks": 2.0},
	&"shifting_mist": {"dew": 0.25},
	&"bramble_verge": {"slow": 0.20},
	&"waking_root": {"free_unlocks": 1.0, "dreamlight": 1.0},
}
# A landmark's zone: how far from its edge it acts, in cells. The standing glow on the ground is this big.
# 0 = the gift's own ground is the zone (the ring's patch, the rooted path cells).
const ZONE_CELLS := {&"spring": 2.0, &"lightning_tree": 3.0, &"bell_stone": 3.0, &"mushroom_ring": 0.0, &"moonwell": 2.0,
	&"heartwood_roots": 0.0}

static func kind_of(id: StringName) -> StringName:
	return POOL[id].kind if POOL.has(id) else &""

# Always "any" since every gift is generic (kept for callers).
static func family_of(id: StringName) -> String:
	return String(POOL[id].family) if POOL.has(id) else ANY_FAMILY

static func is_retired(id: StringName) -> bool:
	return POOL.has(id) and bool(POOL[id].get("retired", false))

static func zone_cells(id: StringName) -> float:
	return float(ZONE_CELLS.get(id, 0.0))

# One of a gift's numbers at growth step `step` (1-3; a number that never grows is the same at every step).
static func stat(id: StringName, key: String, step: int = 1) -> float:
	var found = NUMBERS.get(id, {}).get(key, 0.0)
	if found is Array:
		return float(found[clampi(step, 1, found.size()) - 1])
	return float(found)

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

# Every act break but the last (the run's end is the win): the demo's drift 25 too (demo_scope.md e5ce233d: the demo plays by the current rules).
func _on_rest_started(_block: int, boss_rest: bool, _bonus: int, _perfect: bool) -> void:
	if not boss_rest or not drift_director.has_next_drift():
		return
	var act := drift_director.get_act(drift_director.drifts_started)
	grow_landmarks(act)  # Before the new offer: the landmarks from earlier act breaks each gain a step
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

# Landmarks grow (heartwood_gifts.md "Gifts as landmarks" 3): at every act break after the one a landmark was taken at,
# it gains one step, up to MAX_STEP. The step is kept on the gift's record ("step", saved) with the act it last grew
# at ("grown_act"), so a resumed run never grows it twice. gift_grew tells the owners to rebuild their numbers and look.
func grow_landmarks(act: int) -> void:
	for record in taken:
		var id := StringName(record.id)
		if kind_of(id) != KIND_LANDMARK or is_retired(id):
			continue
		var step := int(record.get("step", 1))
		if step >= MAX_STEP or int(record.get("grown_act", record.act)) >= act:
			continue
		record["step"] = step + 1
		record["grown_act"] = act
		gift_grew.emit(id, step + 1, record.get("placement", {}))

# The growth step of gift `id` (1-3; 0 = not taken). Tower Code and Environment Code read this, never a copy.
func step_of(id: StringName) -> int:
	for record in taken:
		if StringName(record.id) == id:
			return int(record.get("step", 1))
	return 0

# One of the player's gift's numbers at the step it has reached (0.0 when the gift isn't taken).
func value(id: StringName, key: String) -> float:
	var step := step_of(id)
	return stat(id, key, step) if step > 0 else 0.0

# Whether `id` can be offered now: it has an effect, isn't retired and wasn't taken this run. No gift needs a family.
# Old Kin needs a Kinship on the map (it grows a bond: with none it would do nothing).
func can_offer(id: StringName) -> bool:
	if not POOL.has(id) or is_retired(id) or not has_effect(id) or has_taken(id):
		return false
	if id != &"old_kin":
		return true
	var dreams := drift_director.get_node_or_null("%DreamState")
	return dreams != null and dreams.has_method("count_kinships") and int(dreams.count_kinships()) > 0

# One gift of each kind (land, landmark, boon), never one taken this run, in a seeded order (the map seed and the
# act: a resumed run draws the same). A kind with nothing to offer gives
# its slot to another kind, so the offer is 3 while the pool can fill it.
func draw(act: int) -> Array[StringName]:
	var rng := RandomNumberGenerator.new()
	var map := drift_director.get_node_or_null("%MapGenerator")
	rng.seed = hash([int(map.map_seed) if map != null else 0, act, "heartwood_gifts"])
	var by_kind := {}
	for kind in KINDS:
		by_kind[kind] = []
	for id in POOL:
		if can_offer(id):
			by_kind[kind_of(id)].append(id)
	var offer: Array[StringName] = []
	var spare: Array = []
	for kind in KINDS:
		var options: Array = by_kind[kind]
		_shuffle(options, rng)
		if not options.is_empty():
			offer.append(options[0])
		spare.append_array(options.slice(1))
	_shuffle(spare, rng)
	for id in spare:
		if offer.size() >= OFFER_SIZE:
			break
		offer.append(id)
	return offer  # In kind order: land, landmark, boon

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
		if map.gifts.has_method("roots_halves"):
			place["halves"] = map.gifts.roots_halves()  # Half precision (heartwood_gifts.md 2554c638)
	var record := {"id": String(id), "act": offer_act, "placement": _plain(place), "step": 1, "grown_act": offer_act}
	taken.append(record)
	_apply(id, record.placement, false)
	_payoff(id, place, offer_act)  # Once, at the pick (the Dew is in the run save's total)
	_close()
	gift_taken.emit(id, placement)
	gift_placed.emit(id, placement, 1)

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
		data["step"] = maxi(step_of(id), 1)  # A landmark's growth step (a resumed run rebuilds it at the step it had)
		_effects[id].call(drift_director.owner, data)

# Thick Mist: the act after the one it was taken at leaves the mist further apart (DriftDirector schedule "spacing").
func get_spacing_multiplier(drift: int) -> float:
	var act := drift_director.get_act(drift)
	for t in taken:
		if StringName(t.id) == &"thick_mist" and int(t.act) + 1 == act:
			return THICK_MIST_SPACING
	return 1.0

# Map gifts all pay off (heartwood_gifts.md b3e464e6, user: "everything gives buffs or more resources"). Main's part:
# Reshape (and the retired Shift the Stones) pays SHIFT_DEW × act per obstacle moved or cleared (Dew only: the fertile spot overlapped Ancient Stump, 8f46c6ac); Shifting Mist adds MIST_POT_BONUS to the next act's Dew
# pots (the act it opens: gifts come at the act break, `act` is the act that ended). Balancing Discussion sets the numbers.
const SHIFT_DEW := 60  # Dew x2 second pass (was 30)
const MIST_POT_BONUS := 0.25  # (= NUMBERS shifting_mist dew; was 0.10)

func _payoff(id: StringName, placement: Dictionary, act: int) -> void:
	if id != &"shift_stones" and id != &"reshape":
		return
	var froms := cells_of(placement, "from")
	if id == &"reshape":
		froms.append_array(cells_of(placement, "cells"))  # Reshape pays for every obstacle moved or cleared
	if froms.is_empty():
		return
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
