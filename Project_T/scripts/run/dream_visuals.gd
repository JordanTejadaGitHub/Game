extends RefCounted
## Dream feedback data for the visuals (visual feedback spec, owner 2026-10-18; D:\Projects\logs\dream_council\
## visual_feedback_spec.md B1 / B5). Roguelite Code provides the numbers and events; Tower Code / UI draw them.
## Preloaded as DreamState.VISUALS, instance DreamState.visuals (no class_name). Nothing here runs per frame: the boost tier
## is cached per Warden and rebuilt on a board / card change (or after LIVE_REFRESH s, for the live-field rows).

const CARD_CUES := preload("res://scripts/run/card_cues.gd")

# --- B1: the boosted-attack tier ---------------------------------------------------------------------------------------
# dream_power = Dream damage x (1 + Dream attack speed, inside the +150% cap) - 1. Dream card power only: never ranks,
# auras, Kinships, Omens or Gifts (they have their own looks).
const TIER_POWER: Array[float] = [0.20, 0.60, 1.50]  # Tier 1 Warm from +20%, 2 Bright from +60%, 3 Gold from +150%
const MAX_TIER := 3
const SPROUT_MAX_TIER := 1  # Dozens of Sprouts: tier 1 at most (spec B2)
const LIVE_REFRESH := 0.5  # Seconds a cached tier stands while the board is unchanged (live-field rows: Crowded Path…)
const PAST_CAP_HOLD := 1.0  # A hit past the x4 card line (DreamState.card_cap_factor) shows tier 3 for this long
const SPROUT_ID := "sprout"

var _cache := {}  # Warden id -> [board_version, rules_stamp, clock, static tier, surge row on, power]
var _surge_until := {}  # Warden id -> clock (note_surge: timed cards outside the Dream rows, e.g. Shiny Things)
var _past_cap_at := {}  # Warden id -> clock of its last hit past the card line

# The tier for a Dream power (0..3). Static so the thresholds can be tested alone.
static func tier_for_power(power: float) -> int:
	var tier := 0
	for i in TIER_POWER.size():
		if power >= TIER_POWER[i] - 0.000001:
			tier = i + 1
	return tier

# The shown tier: the static tier, +1 while a timed card surges, 3 after a hit past the card line; Sprouts at most 1.
static func tier_with(static_tier: int, surge: bool, past_cap: bool, sprout: bool = false) -> int:
	var tier := static_tier + (1 if surge else 0)
	if past_cap:
		tier = MAX_TIER
	tier = mini(tier, MAX_TIER)
	return mini(tier, SPROUT_MAX_TIER) if sprout else tier

func boost_tier(ds, tower) -> int:
	if not _valid(tower):
		return 0
	var entry := _entry(ds, tower)
	var id: int = tower.get_instance_id()
	var surge: bool = bool(entry[4]) or float(_surge_until.get(id, -1.0)) > ds._game_clock or _live_surge(ds, tower)
	var capped: bool = ds._game_clock - float(_past_cap_at.get(id, -INF)) <= PAST_CAP_HOLD
	return tier_with(int(entry[3]), surge, capped, tower.tower_data.get_id() == SPROUT_ID)

func dream_power(ds, tower) -> float:
	return float(_entry(ds, tower)[5]) if _valid(tower) else 0.0

# A timed card turned on for `tower` for `seconds` (for timed rules outside the Dream rows; Tower Code: Shiny Things).
func note_surge(ds, tower, seconds: float) -> void:
	if _valid(tower):
		var id: int = tower.get_instance_id()
		_surge_until[id] = maxf(float(_surge_until.get(id, -1.0)), ds._game_clock + seconds)
		if _surge_until.size() > 1024:
			_surge_until.clear()

func note_past_cap(ds, tower) -> void:
	if _valid(tower):
		_past_cap_at[tower.get_instance_id()] = ds._game_clock
		if _past_cap_at.size() > 1024:
			_past_cap_at.clear()

func clear() -> void:
	_cache.clear()
	_surge_until.clear()
	_past_cap_at.clear()

static func _valid(tower) -> bool:
	return tower != null and is_instance_valid(tower) and tower is Tower and tower.tower_data != null

func _entry(ds, tower) -> Array:
	var id: int = tower.get_instance_id()
	var entry: Array = _cache.get(id, [])
	if entry.is_empty() or int(entry[0]) != ds.board_version or int(entry[1]) != ds.rules_stamp \
			or ds._game_clock - float(entry[2]) > LIVE_REFRESH or ds._game_clock < float(entry[2]):
		var power_surge := _power(ds, tower)
		entry = [ds.board_version, ds.rules_stamp, ds._game_clock, tier_for_power(power_surge[0]), power_surge[1],
			power_surge[0]]
		if _cache.size() > 1024:
			_cache.clear()  # Forget sold Wardens now and then
		_cache[id] = entry
	return entry

# [dream power without the surge rows, whether a surge row is on]. Mirrors Tower._refresh_dream_rows and
# Tower._compute_attacks_per_second (the Dream parts only); a surge row's damage and speed go to the +1 instead.
func _power(ds, tower) -> Array:
	var data: TowerData = tower.tower_data
	if not data.can_attack:
		return [0.0, false]
	var plain: float = ds.get_stat_bonus(data, "soothe_bonus")
	var synergy := 1.0
	var speed: float = ds.get_attack_speed_multiplier(data) - 1.0
	var surge := false
	var effects = ds.effects()
	var rows: Array = effects.rows_cached(tower) if effects != null and effects.has_method("rows_cached") else []
	for row in rows:
		if not row.active or row.get("plain", false):
			continue
		var card = row.get("card")
		var rule: StringName = StringName(card.rule_id) if card != null else &""
		if CARD_CUES.SURGE.has(rule):
			surge = surge or row.get("damage", 0.0) > 0.0 or row.get("speed", 0.0) > 0.0
			continue
		if row.get("bucket", &"plain") == &"synergy":
			synergy *= 1.0 + row.get("damage", 0.0)
		else:
			plain += row.get("damage", 0.0)
		speed += row.get("speed", 0.0)
	if tower.attack_data != null and tower.attack_data.attack_kind == TowerData.AttackKind.SPIN:
		speed += ds.hairpin_speed(tower)
	speed = clampf(speed, 0.0, DreamState.DREAM_SPEED_CAP)
	var damage: float = Tower.soothe_from_buckets(plain, synergy)
	damage = maxf(damage, 1.0 + ds.get_potency_bonus(data))  # Venom Bloom: potency counts as damage power
	return [damage * (1.0 + speed) - 1.0, surge]

# Timed cards outside the Dream rows, read live (cheap): Momentum / Quickening (GroveRules), Hot on Their Heels.
func _live_surge(ds, tower) -> bool:
	if (ds.has_rule(&"momentum") or ds.has_rule(&"quickening")) and GroveRules.speed_bonus(tower) > 0.0:
		return true
	return ds.batch.heels_bonus(ds) > 0.0

# --- B5: the badge pop on the Warden a card fired from -----------------------------------------------------------------
const BADGE_POP_EVERY := 4.0  # Once per card per Warden every 4 s (game time). UI keeps the alive cap and build mode.

var _badge_at := {}  # "warden id:card id" -> clock of its last pop

func badge_pop_ok(ds, id: StringName, source) -> bool:
	if source == null or not is_instance_valid(source) or not source is Tower:
		return false
	var row: Dictionary = _badge_at.get(id, {})  # card id -> {Warden instance id: last pop} (no string keys: perf, 2026-10-18)
	if row.is_empty():
		_badge_at[id] = row
	var who: int = source.get_instance_id()
	var last: float = float(row.get(who, -INF))
	if ds._game_clock - last < BADGE_POP_EVERY and ds._game_clock >= last:
		return false
	if row.size() > 256:
		row.clear()
	row[who] = ds._game_clock
	return true

# A card banked a free rank on `tower` (Hard-Won Rings; owner 2026-10-20: "don't know who gets the free rank from
# hard-won rings"): "Rank earned!" pops over it and its rank art flashes, so the player sees which Warden got it.
const RANK_FLASH := Color(1.8, 1.6, 1.1)  # multiplier: the rank art's brief flash
const RANK_FLASH_TIME := 0.5

static func rank_earned(tower) -> void:
	if not _valid(tower):
		return
	var world: Node = Reactions._world(tower)
	if world != null:
		Fx.callout("Rank earned!", Palette.GOLD, tower.global_position + Vector2(0.0, -40.0), world, &"rank_earned")
	if Fx.reduce_flashes():
		return
	for name in [&"RankUnder", &"RankOver", &"RankOverlay"]:
		var art := tower.get_node_or_null(NodePath(name)) as CanvasItem
		if art == null or not art.visible:
			continue
		var tween := art.create_tween()
		tween.tween_property(art, "self_modulate", RANK_FLASH, RANK_FLASH_TIME * 0.3)
		tween.tween_property(art, "self_modulate", Color(1, 1, 1), RANK_FLASH_TIME * 0.7)  # multiplier: back to plain
