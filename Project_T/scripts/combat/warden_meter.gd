class_name WardenMeter
extends Node

# "Damage that means something" (screens_ui.md, 2026-09-29): the numbers behind the drift benchmark,
# the Warden DPS tags, the drift meter and the rest report's Carrying / Underused / Most improved.
# Main builds the UI; this only measures, from DamageLog events (damage per Warden, resisted share,
# overkill), SupportLog (support credit) and the DriftDirector (needed DPS).
# Made in the run's scene on first use (find), like SupportLog and Kinships.
#
# Periods: "drift" (since the latest drift started), "last_drift", "block" (since the block's first
# drift), "last_block". DPS = damage ÷ the seconds nightmares were on the field in that period.

const GROUP := &"warden_meter"
const PERIODS: Array[String] = ["drift", "last_drift", "block", "last_block"]
const SAMPLE := 0.5  # Seconds between "any nightmare in range?" samples per Warden
const CARRYING := 1.5  # Rating at or above: gold, carrying
const UNDERUSED := 0.75  # Rating below: dim blue, underused
const PAYBACK_DRIFTS := 10.0  # Catchers: rated on Dew caught vs paying back their Dew in this many drifts
const FEW_IN_RANGE := 0.35  # Underused because nightmares were in range less than this share of the time
const MOSTLY_RESISTED := 0.35  # …or more than this share of its damage was resisted
const OVERKILL := 0.3  # …or more than this share landed past a nightmare's last health
const MIN_DPS_FOR_CHANGE := 1.0  # ↑↓ only when last drift did at least this much
const ELITE_HEALTH := 3.0  # Enemy.ELITE_HEALTH (Deeply Blighted: ×3 health)

# instance id -> {"tower": Tower, "name": String, period: {damage, credit, in_range, alive, resisted, overkill}}
var _rows := {}
var _maze := {}  # period -> {damage, seconds}
var _last_health := {}  # Nightmare instance id -> health after its last logged hit (for overkill)
var _sample := 0.0
var _sample_carry := 0.0  # Wardens owed a sample (fractional, carried frame to frame)
var _sample_index := -1  # The last Warden sampled (round robin)
var _block_open := true  # The next drift starts a new block (the run starts resting)
var _director: DriftDirector

static func find(near: Node) -> WardenMeter:
	if near == null or not near.is_inside_tree():
		return null
	var meter := near.get_tree().get_first_node_in_group(GROUP) as WardenMeter
	if meter != null:
		return meter
	var scene := near
	while scene.get_parent() != null and scene.get_parent() != near.get_tree().root:
		scene = scene.get_parent()
	if scene.get_node_or_null("%TowerContainer") == null:
		return null  # Not a run
	meter = WardenMeter.new()
	meter.name = "WardenMeter"
	scene.add_child(meter)
	return meter

func _ready() -> void:
	add_to_group(GROUP)
	for period in PERIODS:
		_maze[period] = _blank()
	_director = get_parent().get_node_or_null("%DriftDirector") as DriftDirector
	if _director:
		_director.drift_started.connect(_on_drift_started)
		_director.rest_started.connect(func(_b: int, _boss: bool, _bonus: int, _p: bool) -> void: _block_open = true)
	var damage := DamageLog.instance if DamageLog.instance else get_parent().get_node_or_null("%DamageLog") as DamageLog
	if damage:
		damage.damage_dealt.connect(_on_damage_dealt)

static func _blank() -> Dictionary:
	return {"damage": 0.0, "credit": 0.0, "seconds": 0.0, "in_range": 0.0, "alive": 0.0, "resisted": 0.0,
		"overkill": 0.0}

func _row(tower: Tower) -> Dictionary:
	var id := tower.get_instance_id()
	if not _rows.has(id):
		var row := {"tower": tower, "name": tower.tower_data.display_name}  # The name at first sight; rows read the live one
		for period in PERIODS:
			row[period] = _blank()
		_rows[id] = row
	return _rows[id]

func _on_drift_started(_number: int) -> void:
	var rows := _rows.values() + [_maze_row()]
	for row in rows:
		row.last_drift = row.drift
		row.drift = _blank()
		if _block_open:
			row.last_block = row.block
			row.block = _blank()
	_block_open = false
	_last_health.clear()

func _maze_row() -> Dictionary:
	return _maze

# --- Measuring ---------------------------------------------------------------------------------

# Performance: this runs for every damage event (hits and ticks, several a frame at 3x), so no throwaway
# arrays and no string-keyed property reads.
func _on_damage_dealt(event: DamageLog.Event) -> void:
	var amount := event.amount
	if amount <= 0.0:
		return
	var overkill := 0.0
	var enemy := event.enemy
	if is_instance_valid(enemy):
		var id := enemy.get_instance_id()
		var after: float = enemy.health
		var before: float = _last_health.get(id, float(enemy.max_health))
		overkill = maxf(amount - maxf(before - after, 0.0), 0.0)
		_last_health[id] = after
	var family := event.family_multiplier
	var resisted := amount * (1.0 / family - 1.0) if family > 0.0 and family < 1.0 else 0.0
	_maze.drift.damage += amount
	_maze.block.damage += amount
	var tower := event.source as Tower
	if tower == null or not is_instance_valid(tower):
		return
	var row := _row(tower)
	var drift: Dictionary = row.drift
	var block: Dictionary = row.block
	drift.damage += amount
	block.damage += amount
	if resisted > 0.0:
		drift.resisted += resisted
		block.resisted += resisted
	if overkill > 0.0:
		drift.overkill += overkill
		block.overkill += overkill
	# Support credit: the aura that boosted this hit is credited its share (as SupportLog does).
	if tower._aura_damage_from != null:
		_credit(tower._aura_damage_from, tower._aura_damage, amount)
	if tower._aura_speed_from != null:
		_credit(tower._aura_speed_from, tower._aura_speed, amount)

func _credit(aura: Tower, bonus: float, amount: float) -> void:
	if not is_instance_valid(aura) or bonus <= 0.0:
		return
	var share := amount * bonus / (1.0 + bonus)
	var aura_row := _row(aura)
	aura_row.drift.credit += share
	aura_row.block.credit += share

func _process(delta: float) -> void:
	if _director == null or _director.is_resting() or get_tree().paused:
		return
	var field := get_tree().get_nodes_in_group(Tower.ENEMY_GROUP).size() > 0
	if not field:
		return
	for period in ["drift", "block"]:
		_maze[period].seconds += delta
	# Every Warden is sampled once per SAMPLE seconds, a slice of them each frame (perf: all ~230 at once
	# was an 8 ms spike every 0.5 s in the stacked-drift case), with the early-exit range check.
	var towers := get_tree().get_nodes_in_group(Tower.GROUP)
	if towers.is_empty():
		return
	_sample_carry += towers.size() * delta / SAMPLE
	var count := mini(int(_sample_carry), towers.size())
	_sample_carry -= count
	for i in count:
		_sample_index = (_sample_index + 1) % towers.size()
		var tower = towers[_sample_index]
		if not tower is Tower or tower.is_queued_for_deletion() or not tower.tower_data.can_attack:
			continue
		var row := _row(tower)
		var busy := SAMPLE if tower.has_enemy_in_range() else 0.0
		for period in ["drift", "block"]:
			row[period].alive += SAMPLE
			row[period].in_range += busy

# --- The drift benchmark -----------------------------------------------------------------------

# The maze's DPS in `period` (damage ÷ seconds with nightmares on the field).
func get_maze_dps(period: String = "drift") -> float:
	var m: Dictionary = _maze[period]
	return m.damage / m.seconds if m.seconds > 0.5 else 0.0

# Needed DPS for drift `number`: its nightmares' total health (health scaling, elites, bosses) ÷ the
# time the maze has to deal it: the drift's arrival span + how long an average nightmare walks the
# current path (path length ÷ average speed). An estimate (flyers, splits and leaks aren't exact).
func get_needed_dps(number: int) -> float:
	if _director == null or number < 1 or number > _director.drifts.size():
		return 0.0
	var mods := _director.get_schedule_modifiers(number)
	var schedule: Array = _director.drifts[number - 1].get_schedule(mods.get("count", 1.0), mods.get("flyers", 1.0),
		mods.get("spacing", 1.0), _director.get_extra_nightmares(number))
	if schedule.is_empty():
		return 0.0
	var health := 0.0
	var speed := 0.0
	var span := 0.0
	for entry in schedule:
		var data: EnemyData = entry[1]
		var elite: bool = entry[2] if entry.size() > 2 else false
		health += data.health * _director.get_health_scale(data, number) * (ELITE_HEALTH if elite else 1.0)
		speed += data.speed
		span = maxf(span, entry[0])
	speed /= schedule.size()
	var map = get_parent().get_node_or_null("%MapGenerator")
	var tiles: int = map.get_path_from(map.startPath).size() if map else 30
	var walk := tiles * Tower.MAP_GRID.cell_size.x / maxf(speed, 1.0)
	return health / maxf(span + walk, 1.0)

# The DriftPanel line. During a drift: {maze_dps, needed_dps, ratio, forecast: false, drift}; at a rest,
# the forecast for the next drift: {maze_dps: last drift's, needed_dps: the next drift's, ratio,
# forecast: true, drift: next}. ratio = maze ÷ needed (1.1+ green, 0.9–1.1 amber, under 0.9 red).
func get_benchmark() -> Dictionary:
	var resting := _director == null or _director.is_resting()
	var number := (_director.drifts_started + 1 if resting else _director.drifts_started) if _director else 0
	# "drift" rolls over only when the next drift starts, so at a rest it still holds the drift just played.
	var last := get_maze_dps("drift" if resting else "last_drift")
	var maze := get_maze_dps("drift")
	var needed := get_needed_dps(number)
	return {"maze_dps": maze, "needed_dps": needed, "ratio": maze / needed if needed > 0.0 else 0.0,
		"forecast": resting, "drift": number, "last_dps": last,
		"change": _change(maze, last) if not resting else null}

# --- Per Warden --------------------------------------------------------------------------------

# One row per attacking (or credited support) Warden for `period` ("drift" or "block"), by DPS:
# {tower, name, dps, last_dps, change (fraction, or null), share (of the maze's damage), dew_invested,
# rating (float, or -1 = not rated), rating_label (&"carrying" / &"fine" / &"underused" / &""),
# reason ("" or why it's underused), most_improved (bool), support (credit counted, damage)}.
func get_meter_rows(period: String = "drift") -> Array:
	var last := "last_drift" if period == "drift" else "last_block"
	var maze: Dictionary = _maze[period]
	var seconds: float = maxf(maze.seconds, 0.5)
	var towers := get_tree().get_nodes_in_group(Tower.GROUP).filter(func(t: Node) -> bool:
		return t is Tower and not t.is_queued_for_deletion() and t.tower_data.can_attack or (t is Tower and _rows.has(t.get_instance_id())))
	var total_value := 0.0
	var total_dew := 0.0
	var rows := []
	var support := SupportLog.find(self)
	for tower in towers:
		var row := _row(tower)
		var now: Dictionary = row[period]
		var value: float = now.damage + now.credit
		total_value += value
		total_dew += tower.invested_dew
		var dps: float = now.damage / seconds
		var last_seconds: float = maxf(_maze[last].seconds, 0.5)
		var last_dps: float = row[last].damage / last_seconds
		rows.append({"tower": tower, "name": tower.tower_data.display_name, "dps": dps, "last_dps": last_dps,
			"change": _change(dps, last_dps), "value": value, "support": now.credit,
			"dew_invested": tower.invested_dew, "stats": now, "catcher": tower.is_catcher(),
			"caught": support.get_stats(tower, period).dew_caught if support and tower.is_catcher() else 0.0})
	var best_change := 0.0
	var improved = null
	for r in rows:
		var dew_share: float = r.dew_invested / total_dew if total_dew > 0.0 else 0.0
		r["share"] = r.value / total_value if total_value > 0.0 else 0.0
		var rating := -1.0
		if r.catcher:
			rating = r.caught * PAYBACK_DRIFTS / maxf(r.dew_invested, 1.0)  # Dew caught vs paying back in 10 drifts
		elif dew_share > 0.0 and total_value > 0.0:
			rating = r.share / dew_share
		r["rating"] = rating
		r["rating_label"] = &"" if rating < 0.0 else (&"carrying" if rating >= CARRYING else (&"underused" if rating < UNDERUSED else &"fine"))
		r["reason"] = _reason(r.stats) if r.rating_label == &"underused" else ""
		r["most_improved"] = false
		if r.change != null and r.change > best_change and r.last_dps >= MIN_DPS_FOR_CHANGE:
			best_change = r.change
			improved = r
		r.erase("stats")
		r.erase("value")
	if improved != null:
		improved.most_improved = true
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.dps > b.dps)
	return rows

# One Warden's row ({} if it has none), e.g. for its DPS tag.
func get_tower_row(tower: Tower, period: String = "drift") -> Dictionary:
	for r in get_meter_rows(period):
		if r.tower == tower:
			return r
	return {}

# The rest report's block summary: {maze_dps, last_block_dps, change, needed_dps (next drift),
# carrying: [rows], underused: [rows, each with its reason], most_improved: row or {}}.
func get_block_summary() -> Dictionary:
	var rows := get_meter_rows("block")
	var improved := {}
	for r in rows:
		if r.most_improved:
			improved = r
	var next := _director.drifts_started + 1 if _director else 0
	return {"maze_dps": get_maze_dps("block"), "last_block_dps": get_maze_dps("last_block"),
		"change": _change(get_maze_dps("block"), get_maze_dps("last_block")), "needed_dps": get_needed_dps(next),
		"carrying": rows.filter(func(r) -> bool: return r.rating_label == &"carrying"),
		"underused": rows.filter(func(r) -> bool: return r.rating_label == &"underused"),
		"most_improved": improved}

# Why an underused Warden did little, when the numbers say ("" if they don't).
static func _reason(s: Dictionary) -> String:
	if s.alive > 0.0 and s.in_range / s.alive < FEW_IN_RANGE:
		return "few nightmares in range"
	var dealt: float = s.damage + s.resisted
	if dealt > 0.0 and s.resisted / dealt > MOSTLY_RESISTED:
		return "mostly resisted"
	if s.damage > 0.0 and s.overkill / s.damage > OVERKILL:
		return "overkill: its hits land on nearly-dispelled nightmares"
	return ""

static func _change(now: float, before: float):
	if before < MIN_DPS_FOR_CHANGE:
		return null
	return now / before - 1.0
