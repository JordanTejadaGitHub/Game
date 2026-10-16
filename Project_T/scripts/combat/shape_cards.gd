class_name ShapeCards
extends RefCounted

# The Shape cards (dream_design.md e4d17195; numbers balance_simulation.md 60dad611), Tower Code's hooks:
# - Small Hands (rule small_hands): what a Warden sends out (brood sprites, hummingbirds, seeds, patrol birds,
#   swooping birds, lobbed stones) hits +35%; sprites live and hummingbirds peck +1 s longer.
# - Sap Rising (rule sap_rising): support Wardens (walls aside) pulse the 8 cells around them every 2 s, a hit that grows each drift
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
const SAP_FLOOR_SHARE := 0.5  # (Retired by hard cards 2026-10-16; nothing reads it)
const SAP_LASH := 10.0  # …each hitting for 10 × an ordinary nightmare's health scale (a Shade has 100 at drift 1)…
const SAP_CEILING := 0.25  # …never more than a quarter of one nightmare's health in all…
const SAP_BOSS_CEILING := 0.10  # …a tenth for bosses and Deeply Blighted nightmares
const SAP_META := &"batch_sap"  # On a nightmare: sap damage taken (its own counter, not Thorny Walls')
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

# A support Warden for Sap Rising (the design's "non-attacking": auras, catchers, Dreamcatchers; never walls):
# the support auras (Elder Stump, Grove Heart, Grandmother Oak; Acorn attacks), the Dew catchers (Dewcatcher,
# Wellspring) and the Dreamcatchers.
static func is_support(data: TowerData) -> bool:
	if data == null or data.line == "wall":
		return false
	return Tower.SUPPORT_AURA_WARDENS.has(data.get_id()) or data.catch_share > 0.0 or data.caught_bonus > 0.0

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

# Hard cards 2026-10-16 (Thorny Walls' shape): a pulse hits for SAP_LASH × an ordinary nightmare's health scale this
# drift (DriftDirector.ordinary_scale), so it stays a fixed share of a Shade all run. Each nightmare's sap is capped
# by sap_lash (its own ceiling counter, never Thorny Walls').
static func sap_damage(support: Tower) -> float:
	if support == null or support._dream_state == null or support._dream_state.drift_director == null:
		return 0.0
	var director = support._dream_state.drift_director
	return SAP_LASH * float(director.ordinary_scale(maxi(int(director.drifts_started), 1)))

# The part of a `damage` pulse `enemy` may still take from sap (0 = it has taken its ceiling: a quarter of its health,
# bosses and Deeply Blighted a tenth). Books what it returns.
static func sap_lash(enemy: Node2D, damage: float) -> float:
	var heavy: bool = enemy.enemy_data.is_boss or enemy.elite
	var ceiling: float = float(enemy.max_health) * (SAP_BOSS_CEILING if heavy else SAP_CEILING)
	var taken := float(enemy.get_meta(SAP_META, 0.0))
	var lash := minf(damage, ceiling - taken)
	if lash <= 0.0:
		return 0.0
	enemy.set_meta(SAP_META, taken + lash)
	return lash
