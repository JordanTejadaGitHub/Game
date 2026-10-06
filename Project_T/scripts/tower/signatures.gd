class_name Signatures
extends Node

# Rank V signatures (warden_stats.md "Rank V signatures", 96d728dd; numbers balance_simulation.md 43496006): a
# Warden at rank V with 3+ of its ranks I–V on one choice gains that choice's signature. Shared Training
# (dream_design.md 1269ed84): two kin with 3 of ranks I–IV on the same choice get it at rank IV.
# Tower asks Tower.signature() (cached with its stats) and calls the static helpers here; this node (made in the
# run's scene on first use) carries Spreading's statuses off dispelled nightmares.

const CRUSHING := &"crushing"
const RELENTLESS := &"relentless"
const WATCHTOWER := &"watchtower"
const SPREADING := &"spreading"
const EXECUTIONER := &"executioner"
const FIRSTBORN := &"firstborn"
const SHELTER := &"shelter"
const SURGE := &"surge"

# Choice -> signature (Kindred has none).
const BY_CHOICE := {Tower.Focus.POWER: CRUSHING, Tower.Focus.SWIFT: RELENTLESS, Tower.Focus.REACH: WATCHTOWER,
	Tower.Focus.DEEP: SPREADING, Tower.Focus.KEEN: EXECUTIONER, Tower.Focus.YIELD: FIRSTBORN,
	Tower.Focus.WIDE: SHELTER, Tower.Focus.STRONG: SURGE}
const NAMES := {CRUSHING: "Crushing", RELENTLESS: "Relentless", WATCHTOWER: "Watchtower", SPREADING: "Spreading",
	EXECUTIONER: "Executioner", FIRSTBORN: "Firstborn", SHELTER: "Shelter", SURGE: "Surge"}
const TEXT := {
	CRUSHING: "every 5th hit lands x2 and strips 25% of the dread shell",
	RELENTLESS: "a dispel starts its next cycle at once (at most every 0.5 s)",
	WATCHTOWER: "reveals hidden nightmares in its range",
	SPREADING: "when a nightmare carrying its statuses is dispelled, half the stacks jump to the nearest one within 2 cells",
	EXECUTIONER: "a crit on a nightmare under 20% health dispels it (bosses and elites: the crit x1.5)",
	FIRSTBORN: "what it makes arrives one step better",
	SHELTER: "Wardens in its aura can't be withered, dimmed or trampled",
	SURGE: "every 10 s its aura doubles for 2 s",
}

# No signature where nothing fits the choice (signature audit a09297af); the choice itself still helps.
const NONE_FOR := {
	"jarlink": [Tower.Focus.SWIFT], "lightning_fence": [Tower.Focus.SWIFT],  # 0.25 s ticks: no cycle to restart
	"thorncoil": [Tower.Focus.SWIFT], "crown_of_thorns": [Tower.Focus.SWIFT],
	"seedbearer": [Tower.Focus.SWIFT], "grove_keeper": [Tower.Focus.SWIFT],  # Its cycle counts drifts
	"nurse_log": [Tower.Focus.STRONG], "mother_log": [Tower.Focus.STRONG],  # A discount has no moment to surge
	"gust": [Tower.Focus.DEEP], "zephyr": [Tower.Focus.DEEP], "whirligig": [Tower.Focus.DEEP],  # Already the live spreaders
}

# Whether a Warden of `data` can have the signature of `which`.
static func fits(data: TowerData, which: int) -> bool:
	return BY_CHOICE.has(which) and not (data != null and NONE_FOR.get(data.get_id(), []).has(which))

const NEEDED := 3  # Ranks on one choice
const RANK := 5  # The signature's rank (Shared Training: SHARED_RANK)
const SHARED_RANK := 4
const SHARED_TRAINING := &"shared_training"

# Numbers (Balancing 43496006).
const CRUSH_EVERY := 5
const CRUSH_MULTIPLIER := 2.0
const CRUSH_SHELL := 0.25  # Share of coat_max stripped
const RELENTLESS_GAP := 0.5
const WATCH_TICK := 0.25
const WATCH_REVEAL := 2.0  # Seconds a reveal lasts: refreshed while inside, so it stays 2 s after leaving (audit a09297af)
const SPREAD_REACH := 2.0  # Cells
const EXECUTE_BELOW := 0.2
const EXECUTE_BIG := 1.5  # Bosses and elites: the crit x1.5 instead
const FIRSTBORN_RANKS := 1  # Seedbearer's Sprouts one rank up (I; Grove Keeper's III)
const FIRSTBORN_BURST := 1.5  # Brood sprites burst +50%
const FIRSTBORN_SHARDS := 1.5  # Dream Oak shards x1.5
const SURGE_EVERY := 10.0
const SURGE_TIME := 2.0
const SURGE_MULTIPLIER := 2.0

# --- Which signature -------------------------------------------------------------------------------------------

# The choice held 3+ times among the first `ranks` entries of `choices` (Tower.Focus.NONE if none).
static func majority(choices: Array, ranks: int) -> int:
	var counts := {}
	for i in mini(ranks, choices.size()):
		counts[choices[i]] = int(counts.get(choices[i], 0)) + 1
	for which in counts:
		if counts[which] >= NEEDED and BY_CHOICE.has(which):
			return which
	return Tower.Focus.NONE

# The signature `tower` has now (&"" for none). Tower.signature() caches it.
static func compute(tower: Tower) -> StringName:
	var choices: Array = tower.rank_choices
	if tower.rank >= RANK:
		var which := majority(choices, RANK)
		if which != Tower.Focus.NONE and fits(tower.tower_data, which):
			return BY_CHOICE[which]
	if tower.rank >= SHARED_RANK and tower._has_rule(SHARED_TRAINING):
		var which := majority(choices, SHARED_RANK)
		if which != Tower.Focus.NONE and fits(tower.tower_data, which) and is_instance_valid(tower._kin):
			for pair in tower._kin.get_pairs(tower):
				var partner: Tower = pair.b if pair.a == tower else pair.a
				if is_instance_valid(partner) and partner.rank >= SHARED_RANK and majority(partner.rank_choices, SHARED_RANK) == which:
					return BY_CHOICE[which]
	return &""

# The rank this Warden's signature arrives at (4 with Shared Training and a matching kin, else 5).
static func signature_rank(tower: Tower) -> int:
	if tower.rank >= SHARED_RANK and tower.rank < RANK and compute(tower) != &"":
		return SHARED_RANK
	return RANK

# The panel's hint from rank III: "2 more Power ranks: Crushing at rank V" ("" when there's nothing to say).
static func hint(tower: Tower) -> String:
	if tower.rank < 3 or tower.rank >= RANK:
		return ""
	var counts := {}
	for which in tower.rank_choices:
		counts[which] = int(counts.get(which, 0)) + 1
	var best := Tower.Focus.NONE
	for which in counts:
		if fits(tower.tower_data, which) and (best == Tower.Focus.NONE or counts[which] > counts[best]):
			best = which
	if best == Tower.Focus.NONE:
		return ""
	var more := maxi(NEEDED - int(counts[best]), 0)
	if more > RANK - tower.rank:
		return ""  # Can't get there any more
	var name: String = Tower.FOCUS_NAMES[best]
	if more == 0:
		return "%s at rank V" % NAMES[BY_CHOICE[best]]
	return "%d more %s rank%s: %s at rank V" % [more, name, "" if more == 1 else "s", NAMES[BY_CHOICE[best]]]

# --- Spreading -----------------------------------------------------------------------------------------------

const GROUP := &"signatures"
const JUMPED := &"spread_jumped"  # Meta on a nightmare: the status ids that jumped onto it (never jump again)

static func find(near: Node) -> Signatures:
	if near == null or not near.is_inside_tree():
		return null
	var found := near.get_tree().get_first_node_in_group(GROUP) as Signatures
	if found != null:
		return found
	var scene := near
	while scene.get_parent() != null and scene.get_parent() != near.get_tree().root:
		scene = scene.get_parent()
	found = Signatures.new()
	found.name = "Signatures"
	scene.add_child(found)
	return found

func _enter_tree() -> void:
	add_to_group(GROUP)
	var spawner := get_parent().get_node_or_null("%EnemyContainer") if get_parent() else null
	if spawner and spawner.has_signal("enemy_cleansed") and not spawner.enemy_cleansed.is_connected(_on_dispelled):
		spawner.enemy_cleansed.connect(_on_dispelled)

func _on_dispelled(enemy: Node2D) -> void:
	if not is_instance_valid(enemy) or enemy.statuses == null:
		return
	# Relentless: any dispel credited to the Warden (the last damage on it, status ticks included).
	var hits: Array = enemy.recent_hits if "recent_hits" in enemy else []
	if not hits.is_empty():
		var credited = hits[-1].source
		if credited is Tower and is_instance_valid(credited) and credited.signature() == RELENTLESS:
			credited._relentless()
	var jumped: Array = enemy.get_meta(JUMPED, [])
	var reach := SPREAD_REACH * Tower.MAP_GRID.cell_size.x
	var nearest: Node2D = null
	for id in enemy.statuses.active_ids():
		if jumped.has(id):
			continue
		var source = enemy.statuses.source(id)
		if not (source is Tower) or not is_instance_valid(source) or source.signature() != SPREADING:
			continue
		if nearest == null:
			nearest = _nearest(enemy, reach)
			if nearest == null:
				return
		var stacks := maxi(enemy.statuses.stacks(id) / 2, 1)
		var seconds: float = enemy.statuses.time_left(id) / 2.0
		nearest.apply_status(id, stacks, seconds, enemy.statuses.potency(id), 0, source.tower_data.line, source)
		var marks: Array = nearest.get_meta(JUMPED, [])
		marks.append(id)
		nearest.set_meta(JUMPED, marks)
		source.signature_fired.emit(source, SPREADING)

func _nearest(from: Node2D, reach: float) -> Node2D:
	var best: Node2D = null
	var best_d := reach
	for other in Tower.nightmares_near(get_tree(), from.global_position, reach):
		if other == from or not is_instance_valid(other) or other.is_cleansed:
			continue
		var d: float = other.global_position.distance_to(from.global_position)
		if d <= best_d:
			best_d = d
			best = other
	return best
