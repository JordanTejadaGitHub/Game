class_name SupportLog
extends Node

# Support credit (tower_design.md "Support credit", screens_ui.md "Support and economy feedback",
# 2026-09-29): what the Wardens whose value isn't damage enable, per Warden, per drift / block / run.
#   dew_caught     catchers: Dew caught into the bowl (dispels and drift Dew)
#   dew_paid       catchers: Dew poured at the rest (the Harvest) + Wellspring interest
#   aura_damage    auras: the extra damage their bonus caused (from DamageLog events of boosted Wardens)
#   drowsy         Drowsy stacks applied (Honeysuckle, Scented Hedge Thornwalls, any Drowsy Warden)
#   held_seconds   seconds of Held applied (Rootling line, freezes, snares…)
#   tiles_pulled   tiles nightmares were pulled / pushed back
# Walls' path tiles are live (get_path_tiles), Bramble's damage is DamageLog's.
# Made in the run's scene on first use (find), like Kinships. Main's UI reads the getters below.

const GROUP := &"support_log"
const KEYS: Array[StringName] = [&"dew_caught", &"dew_paid", &"aura_damage", &"drowsy", &"held_seconds", &"tiles_pulled"]
const PERIODS: Array[String] = ["drift", "last_drift", "block", "run"]
const CATCHERS := ["dewcatcher", "wellspring"]
const AURAS := ["acorn", "elder_stump", "grove_heart", "grandmother_oak", "white_stag"]
const WALLS := ["thornwall", "bramble", "honeysuckle"]

# instance id -> {"tower": Tower, "name": String, "drift": {key: float}, "last_drift": {…}, "block": {…},
# "run": {…}, "boosted": {period: {tower id: true}}}
var _rows := {}
var _path_tiles := {}  # Thornwall id -> [board version, tiles]
var _block_open := false  # A rest ended: the next drift starts a new block's totals
var _dispels := {"block": [], "last_block": []}  # World positions of this / last block's dispels

static func find(near: Node) -> SupportLog:
	if near == null or not near.is_inside_tree():
		return null
	var log := near.get_tree().get_first_node_in_group(GROUP) as SupportLog
	if log != null:
		return log
	var scene := near
	while scene.get_parent() != null and scene.get_parent() != near.get_tree().root:
		scene = scene.get_parent()
	if scene.get_node_or_null("%TowerContainer") == null:
		return null  # Not a run
	log = SupportLog.new()
	log.name = "SupportLog"
	scene.add_child(log)
	return log

# Adds `amount` of `key` to `tower`'s credit (no-op outside a run).
static func credit(tower: Node, key: StringName, amount: float) -> void:
	if amount <= 0.0 or tower == null:
		return
	var log := find(tower)
	if log:
		log.add(tower, key, amount)

func _ready() -> void:
	add_to_group(GROUP)
	var director := get_parent().get_node_or_null("%DriftDirector") as DriftDirector
	if director:
		director.drift_started.connect(_on_drift_started)
		director.rest_started.connect(func(_b: int, _boss: bool, _bonus: int, _p: bool) -> void: _block_open = true)
	var spawner := get_parent().get_node_or_null("%EnemyContainer")
	if spawner and spawner.has_signal("enemy_cleansed"):
		spawner.enemy_cleansed.connect(_on_enemy_cleansed)
	var damage := DamageLog.instance if DamageLog.instance else get_parent().get_node_or_null("%DamageLog") as DamageLog
	if damage:
		damage.damage_dealt.connect(_on_damage_dealt)

func add(tower: Node, key: StringName, amount: float) -> void:
	var row := _row(tower)
	for period in PERIODS:
		if period != "last_drift":
			row[period][key] = row[period].get(key, 0.0) + amount

func _row(tower: Node) -> Dictionary:
	var id := tower.get_instance_id()
	if not _rows.has(id):
		var row := {"tower": tower, "name": _name(tower), "boosted": {}}
		for period in PERIODS:
			row[period] = {}
			row.boosted[period] = {}
		_rows[id] = row
	return _rows[id]

static func _name(tower: Node) -> String:
	return tower.tower_data.display_name if tower is Tower else str(tower.name)

func _on_drift_started(_number: int) -> void:
	for row in _rows.values():
		row.last_drift = row.drift
		row.drift = {}
		row.boosted.last_drift = row.boosted.drift
		row.boosted.drift = {}
		if _block_open:
			row.block = {}
			row.boosted.block = {}
	if _block_open:
		_dispels.last_block = _dispels.block
		_dispels.block = []
	_block_open = false

# A boosted Warden dealt damage: its aura's share of it goes to the aura Warden.
func _on_damage_dealt(event: DamageLog.Event) -> void:
	var tower := event.source as Tower
	if tower == null or not is_instance_valid(tower) or event.amount <= 0.0:
		return
	if tower._aura_damage_from == null and tower._aura_speed_from == null:
		return  # Performance: most hits have no aura behind them (this runs for every damage event)
	_credit_aura(tower, tower._aura_damage_from, tower._aura_damage, event.amount)
	_credit_aura(tower, tower._aura_speed_from, tower._aura_speed, event.amount)

func _credit_aura(boosted: Tower, aura: Tower, bonus: float, amount: float) -> void:
	if aura == null or not is_instance_valid(aura) or bonus <= 0.0:
		return
	add(aura, &"aura_damage", amount * bonus / (1.0 + bonus))
	var row := _row(aura)
	for period in PERIODS:
		if period != "last_drift":
			row.boosted[period][boosted.get_instance_id()] = true

# --- Where nightmares are dispelled (the catcher placement preview) ------------------------------

func _on_enemy_cleansed(enemy: Node2D) -> void:
	if is_instance_valid(enemy):
		_dispels.block.append(enemy.global_position)

# The share of dispels last block (this block's while there's no last one) within `radius` cells of
# `at` (world): "~31% of dispels last block happened here". -1 when there's nothing to go on.
func dispel_share_near(at: Vector2, radius: float) -> float:
	var spots: Array = _dispels.last_block if not _dispels.last_block.is_empty() else _dispels.block
	if spots.is_empty():
		return -1.0
	var reach := radius * Tower.MAP_GRID.cell_size.x
	var inside := spots.filter(func(p: Vector2) -> bool: return p.distance_to(at) <= reach).size()
	return float(inside) / spots.size()


# --- Getters (Main's panels, rest report, results) ---------------------------------------------

# `tower`'s credit for `period` ("drift", "last_drift", "block", "run"): every key (0 if none), plus
# "wardens_boosted" (auras), "path_tiles" (Thornwall, live), "paid_back" / "to_pay_back" (catchers:
# Dew paid this run vs the Dew invested in it).
func get_stats(tower: Tower, period: String = "run") -> Dictionary:
	var out := {}
	var row: Dictionary = _rows.get(tower.get_instance_id(), {})
	for key in KEYS:
		out[key] = float(row.get(period, {}).get(key, 0.0)) if not row.is_empty() else 0.0
	out["wardens_boosted"] = row.boosted[period].size() if not row.is_empty() else 0
	out["path_tiles"] = get_path_tiles(tower) if tower.tower_data.get_id() == "thornwall" else 0
	if CATCHERS.has(tower.tower_data.get_id()):
		var paid := float(row.get("run", {}).get(&"dew_paid", 0.0)) if not row.is_empty() else 0.0
		out["paid_back"] = paid >= tower.invested_dew
		out["to_pay_back"] = maxi(tower.invested_dew - int(paid), 0)
	return out

# What kind of support `tower` gives: &"catcher", &"aura", &"wall", &"control" or &"" (none).
static func kind_of(tower: Tower) -> StringName:
	var id := tower.tower_data.get_id()
	if tower.is_catcher() or tower.kin_share(&"old_growth", "a") > 0.0:
		return &"catcher"
	if AURAS.has(id) or tower.tower_data.aura_damage_bonus > 0.0 or tower.tower_data.aura_speed_bonus > 0.0:
		return &"aura"
	if WALLS.has(id):
		return &"wall"
	var data := tower.tower_data
	if data.hold_targets > 0 or data.pull_tiles > 0.0 or data.pulse_hold_every > 0 or data.freeze_duration > 0.0:
		return &"control"
	return &""

# One line for `tower`'s panel ("" = nothing to say): "Caught this run: 240 Dew · paid back ✓", …
func get_panel_line(tower: Tower) -> String:
	var s := get_stats(tower, "run")
	match kind_of(tower):
		&"catcher":
			var line := "Caught this run: %d Dew" % roundi(s.dew_caught)
			return line + (" · paid back ✓" if s.get("paid_back", false) else " · %d Dew to pay back" % s.get("to_pay_back", 0)) \
				if s.has("paid_back") else line
		&"aura":
			return "Added this run: %s damage (to %d Wardens)" % [_big(s.aura_damage), s.wardens_boosted]
		&"wall":
			if tower.tower_data.get_id() == "thornwall":
				return "Adds %d path tiles" % s.path_tiles
			if tower.tower_data.get_id() == "honeysuckle":
				return "Drowsy applied: %d" % roundi(s.drowsy)
			return ""
		&"control":
			return "Held %d s · pulled back %d tiles this run" % [roundi(s.held_seconds), roundi(s.tiles_pulled)]
	return ""

# Every Warden with support credit in `period`: [{tower, name, kind, value, text}], best first.
# `value` is comparable within a kind: Dew (catchers), damage (auras), path tiles + Drowsy (walls),
# seconds held + tiles pulled (control).
func get_support_rows(period: String = "block") -> Array:
	var rows := []
	for row in _rows.values():
		var tower = row.tower
		if not is_instance_valid(tower) or tower.is_queued_for_deletion():
			continue
		var s := get_stats(tower, period)
		var kind := kind_of(tower)
		var value := 0.0
		var text := ""
		match kind:
			&"catcher":
				value = s.dew_caught + s.dew_paid
				text = "%s caught %d Dew" % [row.name, roundi(s.dew_caught)]
			&"aura":
				value = s.aura_damage
				text = "%s added %s damage to %d Wardens" % [row.name, _big(s.aura_damage), s.wardens_boosted]
			&"wall":
				value = s.drowsy
				text = "%s applied %d Drowsy" % [row.name, roundi(s.drowsy)]
			&"control":
				value = s.held_seconds + s.tiles_pulled
				text = "%s held %d s, pulled back %d tiles" % [row.name, roundi(s.held_seconds), roundi(s.tiles_pulled)]
		if value > 0.0:
			rows.append({"tower": tower, "name": row.name, "kind": kind, "value": value, "text": text})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.value > b.value)
	return rows

# The block's top supporter by what it enabled (rest report "Top support: Grove Heart, +9,200 damage
# to 7 Wardens"); {} if none. Auras first (damage), then catchers (Dew), control, walls.
func get_top_support(period: String = "block") -> Dictionary:
	var rows := get_support_rows(period)
	for kind in [&"aura", &"catcher", &"control", &"wall"]:
		for row in rows:
			if row.kind == kind:
				return row
	return {}

# Totals for the rest report / results: {dew_caught, dew_paid, harvest, interest, aura_damage, drowsy,
# held_seconds, tiles_pulled, path_tiles (live)}.
func get_totals(period: String = "block") -> Dictionary:
	var out := {}
	for key in KEYS:
		out[key] = 0.0
	for row in _rows.values():
		for key in KEYS:
			out[key] += float(row.get(period, {}).get(key, 0.0))
	out["path_tiles"] = get_walls_path_tiles()
	return out

# Path tiles all walls add (the route with walls vs without them; Roguelite's Bramble Oath count).
func get_walls_path_tiles() -> int:
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	return dreams.walls_added_tiles() if dreams and dreams.has_method("walls_added_tiles") else 0

# Path tiles one Thornwall adds (the route with it vs without it), cached per board.
func get_path_tiles(wall: Tower) -> int:
	var map = get_parent().get_node_or_null("%MapGenerator")
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	if map == null or dreams == null:
		return 0
	var key := wall.get_instance_id()
	var cached: Array = _path_tiles.get(key, [])
	if not cached.is_empty() and cached[0] == dreams.board_version and cached[2] == wall.cell:
		return cached[1]
	var layer = map.path_layer
	var with_it: int = layer.find_path_from(map.startPath).size()
	layer.set_cell_blocked(wall.cell, false)
	var without: int = layer.find_path_from(map.startPath).size()
	layer.set_cell_blocked(wall.cell, true)
	var tiles := maxi(with_it - without, 0) if without > 0 else 0
	_path_tiles[key] = [dreams.board_version, tiles, wall.cell]
	return tiles

static func _big(value: float) -> String:
	var n := roundi(value)
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out
