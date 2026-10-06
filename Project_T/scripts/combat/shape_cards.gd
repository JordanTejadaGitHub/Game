class_name ShapeCards
extends RefCounted

# The Shape cards (dream_design.md e4d17195; numbers balance_simulation.md 60dad611), Tower Code's hooks:
# - Small Hands (rule small_hands): what a Warden sends out (brood sprites, hummingbirds, seeds, patrol birds,
#   swooping birds, lobbed stones) hits +35%; sprites live and hummingbirds peck +1 s longer.
# - Sap Rising (rule sap_rising): non-attacking Wardens (walls aside) pulse the 8 cells around them every 2 s
#   (Tower._update_sap; damage in sap_damage).
# - Lingering Ground (rule lingering_ground): ground effects (clouds, trails, rings, rubble, pools, cracks, fog,
#   lit tiles) last x1.5 (ground_time at each effect's start).
# The group tests are static so the balance bot's card-value table (dream_sim_policy.gd) reads the same ones.

const SMALL_HANDS := &"small_hands"
const SAP_RISING := &"sap_rising"
const LINGERING_GROUND := &"lingering_ground"

const SMALL_HANDS_DAMAGE := 0.35  # Sent-out things hit +35%…
const SMALL_HANDS_SECONDS := 1.0  # …and last +1 s (brood sprites live, hummingbirds peck)
const SAP_EVERY := 2.0  # Sap Rising: a pulse every 2 s…
const SAP_FLOOR_SHARE := 0.5  # …at least 2 s x 50% of the median attacking Warden's DPS
const SAP_REACH := 1.5  # The 8 cells around (cells from the Warden's edge to the far side of the ring)
const LINGERING_MULTIPLIER := 1.5  # Lingering Ground: ground effects last x1.5

const SENT_OUT_KINDS := [TowerData.AttackKind.SWOOP, TowerData.AttackKind.SWEEP, TowerData.AttackKind.PECK,
	TowerData.AttackKind.BOOMERANG, TowerData.AttackKind.PATROL]
const GROUND_KINDS := [TowerData.AttackKind.CLOUD, TowerData.AttackKind.TRAP, TowerData.AttackKind.LIGHT]
const GROUND_SPECIALS := [&"cloud", &"whirlpool", &"jet", &"inkcap", &"quaker"]  # BranchKit: rain, whirlpool, wet trail, ink, cracks

# --- Groups (static: Wardens and the bot) -----------------------------------------------------------------

# Whether `data`'s attack sends something out that does the hitting (Small Hands).
static func sends_things_out(data: TowerData) -> bool:
	if data == null:
		return false
	return data.attack_kind in SENT_OUT_KINDS or data.projectile_returns or data.lob or data.special == &"brood"

# Whether `data` leaves timed ground effects (Lingering Ground).
static func makes_ground_effects(data: TowerData) -> bool:
	if data == null:
		return false
	return data.attack_kind in GROUND_KINDS or data.lob or data.special in GROUND_SPECIALS

# A support Warden for Sap Rising: doesn't attack and isn't a wall.
static func is_support(data: TowerData) -> bool:
	return data != null and not data.can_attack and data.line != "wall"

# --- Card state ----------------------------------------------------------------------------------------------

static func _dreams() -> DreamState:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.get_first_node_in_group(DreamState.GROUP) as DreamState if tree != null else null

static func has(rule: StringName) -> bool:
	var dreams := _dreams()
	return dreams != null and dreams.has_rule(rule)

# Small Hands: the hit multiplier for what `tower` sent out (1.0 without the card).
static func hands(tower: Tower) -> float:
	if tower == null or tower._dream_state == null or not tower._dream_state.has_rule(SMALL_HANDS):
		return 1.0
	return 1.0 + SMALL_HANDS_DAMAGE

# Small Hands: extra seconds a sent-out thing lasts.
static func hands_seconds(tower: Tower) -> float:
	return SMALL_HANDS_SECONDS if hands(tower) > 1.0 else 0.0

# Lingering Ground: `seconds` for a ground effect starting now (0 stays 0: "until stepped on").
static func ground_time(seconds: float) -> float:
	return seconds * LINGERING_MULTIPLIER if seconds > 0.0 and has(LINGERING_GROUND) else seconds

# --- Sap Rising ----------------------------------------------------------------------------------------------

static var _median_frame := -1
static var _median_dps := 0.0

static func dps_of(tower: Tower) -> float:
	return tower.get_damage() * tower.get_attacks_per_second()

# The median DPS of the board's attacking Wardens (walls and supports aside), once a frame.
static func median_dps(tree: SceneTree) -> float:
	var frame := Engine.get_process_frames()
	if frame == _median_frame:
		return _median_dps
	_median_frame = frame
	var all: Array[float] = []
	for t in tree.get_nodes_in_group(Tower.GROUP):
		if t is Tower and t.tower_data != null and t.tower_data.can_attack and t.attack_data != null:
			all.append(dps_of(t))
	all.sort()
	if all.is_empty():
		_median_dps = 0.0
	elif all.size() % 2 == 1:
		_median_dps = all[all.size() / 2]
	else:
		_median_dps = (all[all.size() / 2 - 1] + all[all.size() / 2]) / 2.0
	return _median_dps

# A pulse's damage: 2 s x the DPS its aura adds to the attacking Wardens inside it (bonus x their DPS), at least
# 2 s x 50% of the board's median attacking DPS (catchers and Dreamcatchers, with no damage aura, get the floor).
static func sap_damage(support: Tower) -> float:
	var added := 0.0
	for row in BuffSources.given_by(support):
		var target: Tower = row.target
		if target.tower_data.can_attack:
			added += (float(row.damage) + float(row.speed)) * dps_of(target)
	return SAP_EVERY * maxf(added, SAP_FLOOR_SHARE * median_dps(support.get_tree()))
