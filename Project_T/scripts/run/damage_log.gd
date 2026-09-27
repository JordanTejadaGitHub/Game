extends Node2D
class_name DamageLog

# Who dealt what (screens_ui.md "Combat feedback"; demo_scope.md "Test tools v2"). Every soothe a
# nightmare takes is reported here by Enemy.take_damage as an Event: the source Warden, how much
# health it took, what kind (hit / status tick / bolt) and which combos boosted it, with the share
# of the damage those combos added. Keeps per-Warden totals (this run, and since the latest drift
# started) and a few seconds of recent events for damage-per-second. Also draws damage numbers.
# The Test Grove tools read it now; the Warden panel, rest report and results screen can later.

signal damage_dealt(event: Event)

const DPS_WINDOW := 5.0  # Seconds of recent events kept for damage-per-second

# Combo tags (combo_amount = the part of the hit the combo added):
#   crit       a critical hit (× the Warden's crit multiplier)
#   weak       the nightmare is weak to the Warden's family (× EnemyData.WEAK_MULTIPLIER)
#   marked     Marked (+25% taken)
#   fog        Spored tick inside Mistveil fog (+50%)
#   conducted  lightning that only reached it through Damp (whole hit)
#   static     a Static bolt (whole hit)
#   popped     a Puffball pop bursting built-up Spored stacks (whole hit; kind "pop")
#   thunderclap, ignite, shatter, pinned, lightning_rod, dawnbreak: Reactions (whole hit; kind
#              "reaction"; see Reactions and Enemy.REACTION_TAGS)
const COMBO_NAMES := {&"crit": "crits", &"weak": "weakness", &"marked": "Marked", &"fog": "fog",
	&"conducted": "through Damp", &"static": "Static bolts", &"popped": "pops",
	&"thunderclap": "Thunderclaps", &"ignite": "Ignites", &"shatter": "Shatters", &"pinned": "Pinned hits",
	&"lightning_rod": "Lightning Rods", &"dawnbreak": "Dawnbreak"}
# Whole-hit combo tags: the entire hit is the combo's (see _combo_share).
const WHOLE_HIT_COMBOS: Array[StringName] = [&"conducted", &"static", &"popped", &"thunderclap", &"ignite",
	&"shatter", &"pinned", &"lightning_rod", &"dawnbreak"]

enum NumbersMode { OFF, BIG, ALL }

class Event:
	extends RefCounted
	var source: Node  # The Warden (Tower), or null (unknown / gone)
	var source_name := "Unknown"
	var enemy: Node2D
	var kind := &"hit"  # hit, status (Spored tick), bolt (Static)
	var amount := 0.0  # Soothe dealt, after every multiplier and the blight coat
	var combos: Array[StringName] = []
	var combo_amount := 0.0  # Part of `amount` that combos added
	# Breakdown for Inspect: base × family/shape × taken (Marked, White Stag), crit already in base.
	var base := 0.0
	var family_multiplier := 1.0
	var taken_multiplier := 1.0
	var crit_multiplier := 1.0
	var coat_soaked := 0.0
	var time := 0.0

	func describe() -> String:
		var text := "%s: %.1f" % [source_name, base / crit_multiplier]
		if crit_multiplier != 1.0:
			text += " × crit %.2f" % crit_multiplier
		if family_multiplier != 1.0:
			text += " × family %.2f" % family_multiplier
		if taken_multiplier != 1.0:
			text += " × taken %.2f" % taken_multiplier
		if coat_soaked > 0.0:
			text += " − coat %.1f" % coat_soaked
		text += " = %.1f" % amount
		if kind != &"hit":
			text += " (%s)" % kind
		return text

# The log in the running scene (enemies report without a tree lookup per hit).
static var instance: DamageLog = null

var numbers_mode := NumbersMode.OFF
# Per Warden: {tower instance id: {"name", "tower", "run", "run_combo", "drift", "drift_status",
# "drift_combo", "combos": {tag: amount}}}.
var _stats := {}
var _recent: Array[Event] = []
var _clock := 0.0
var drift_label := 0  # The drift the "drift" totals started at

func _ready() -> void:
	instance = self
	z_index = 20  # Numbers over nightmares and effects
	# The player's setting (Test Grove can override it later with set_numbers_mode).
	numbers_mode = clampi(int(HeartwoodMemory.get_settings().get("damage_numbers", NumbersMode.BIG)),
		NumbersMode.OFF, NumbersMode.ALL) as NumbersMode
	var director := get_node_or_null("%DriftDirector") as DriftDirector
	if director:
		director.drift_started.connect(func(number: int) -> void: reset_drift(number))
		director.rest_ended.connect(func(_block: int) -> void: reset_block())

# --- Block and run reports (rest report, results) -------------------------------------------------

# Combos triggered: {tag: times} this block (since the last rest) and this run.
var combo_counts_block := {}
var combo_counts_run := {}

func reset_block() -> void:
	combo_counts_block = {}
	for id in _stats:
		_stats[id]["block"] = 0.0

# The `count` Wardens with the most damage, this block (`period` = "block") or run ("run"):
# [{"name", "tower", "amount"}], most first.
func get_top_towers(period: String = "run", count: int = 3) -> Array:
	var rows := []
	for id in _stats:
		var row: Dictionary = _stats[id]
		var amount: float = row.get(period, 0.0)
		if amount > 0.0:
			rows.append({"name": row.name, "tower": row.tower if is_instance_valid(row.tower) else null, "amount": amount})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.amount > b.amount)
	return rows.slice(0, count)

# The combo triggered most this run: [tag, times], or [] if none.
func get_top_combo(counts: Dictionary = combo_counts_run) -> Array:
	var best := []
	for tag in counts:
		if best.is_empty() or counts[tag] > best[1]:
			best = [tag, counts[tag]]
	return best

func _exit_tree() -> void:
	if instance == self:
		instance = null

func _process(delta: float) -> void:
	_clock += delta
	while not _recent.is_empty() and _recent[0].time < _clock - DPS_WINDOW:
		_recent.pop_front()

func report(event: Event) -> void:
	event.time = _clock
	if is_instance_valid(event.source):
		var tower := event.source as Tower
		event.source_name = tower.tower_data.display_name if tower else str(event.source.name)
		var row: Dictionary = _row(event.source)
		row.run += event.amount
		row.run_combo += event.combo_amount
		row.drift += event.amount
		row["block"] = row.get("block", 0.0) + event.amount
		row.drift_combo += event.combo_amount
		if event.kind != &"hit":
			row.drift_status += event.amount
		for tag in event.combos:
			row.combos[tag] = row.combos.get(tag, 0.0) + _combo_share(event, tag)
	for tag in event.combos:
		combo_counts_block[tag] = combo_counts_block.get(tag, 0) + 1
		combo_counts_run[tag] = combo_counts_run.get(tag, 0) + 1
	_recent.append(event)
	damage_dealt.emit(event)
	_show_number(event)

# Starts the "this drift" totals over (at every drift start, or by hand in the tools).
func reset_drift(number: int = drift_label) -> void:
	drift_label = number
	for id in _stats:
		var row: Dictionary = _stats[id]
		row.drift = 0.0
		row.drift_status = 0.0
		row.drift_combo = 0.0
		row.combos = {}

# Totals for one Warden: {"run", "run_combo", "drift", "drift_status", "drift_combo", "combos"}.
func get_tower_stats(tower: Node) -> Dictionary:
	return _stats.get(tower.get_instance_id(), {})

# Damage per second over the last DPS_WINDOW seconds: by `source` if given, onto `enemy` if given.
func get_dps(source: Node = null, enemy: Node = null) -> float:
	var total := 0.0
	for event in _recent:
		if (source == null or event.source == source) and (enemy == null or event.enemy == enemy):
			total += event.amount
	return total / DPS_WINDOW

# Recent damage onto `enemy`, by source name: {name: dps}, highest first when iterated via keys().
func get_dps_by_source(enemy: Node) -> Dictionary:
	var by := {}
	for event in _recent:
		if event.enemy == enemy:
			by[event.source_name] = by.get(event.source_name, 0.0) + event.amount / DPS_WINDOW
	var names := by.keys()
	names.sort_custom(func(a: String, b: String) -> bool: return by[a] > by[b])
	var sorted := {}
	for name in names:
		sorted[name] = by[name]
	return sorted

# Rows for the damage meter, most damage this drift first:
# [{"tower", "name", "drift", "dps", "status_share", "combo_share", "combos": {tag: share}}].
func get_meter_rows() -> Array:
	var rows := []
	for id in _stats:
		var row: Dictionary = _stats[id]
		if row.drift <= 0.0:
			continue
		var tower: Node = row.tower if is_instance_valid(row.tower) else null
		var combos := {}
		for tag in row.combos:
			combos[tag] = row.combos[tag] / row.drift
		rows.append({"tower": tower, "name": row.name, "drift": row.drift,
			"dps": get_dps(tower) if tower else 0.0, "status_share": row.drift_status / row.drift,
			"combo_share": row.drift_combo / row.drift, "combos": combos})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.drift > b.drift)
	return rows

func _row(source: Node) -> Dictionary:
	var id := source.get_instance_id()
	if not _stats.has(id):
		var tower := source as Tower
		var name := tower.tower_data.display_name if tower else str(source.name)
		_stats[id] = {"name": name, "tower": source, "run": 0.0, "run_combo": 0.0, "drift": 0.0,
			"drift_status": 0.0, "drift_combo": 0.0, "combos": {}}
	var row: Dictionary = _stats[id]
	if source is Tower:
		row.name = source.tower_data.display_name  # Evolving renames it
	return row

# One combo's part of an event's combo damage (whole-hit combos take it all; multiplicative ones
# split it by the log of their factor, so the parts add up to combo_amount).
func _combo_share(event: Event, tag: StringName) -> float:
	if event.combos.size() == 1:
		return event.combo_amount
	if tag in WHOLE_HIT_COMBOS:
		return event.combo_amount
	var factors := {&"crit": event.crit_multiplier, &"weak": EnemyData.WEAK_MULTIPLIER,
		&"marked": 1.0 + EnemyStatuses.MARKED_EXTRA, &"fog": 1.0 + EnemyStatuses.FOG_SPORE_BONUS}
	var total_log := 0.0
	for other in event.combos:
		total_log += log(factors.get(other, 1.0))
	return event.combo_amount * log(factors.get(tag, 1.0)) / total_log if total_log > 0.0 else 0.0


# --- Damage numbers ---------------------------------------------------------------------------------

func _show_number(event: Event) -> void:
	if numbers_mode == NumbersMode.OFF or not is_instance_valid(event.enemy) or event.amount < 0.5:
		return
	var big: bool = event.combos.has(&"crit") or event.combos.has(&"weak") or event.combos.has(&"conducted") \
		or event.combos.has(&"popped") or event.kind == &"reaction" \
		or event.amount >= event.enemy.max_health * 0.1
	if numbers_mode == NumbersMode.BIG and not big:
		return
	var color := Color(1, 1, 1)
	var size := 14
	if event.combos.has(&"crit"):
		color = Color(1.0, 0.85, 0.3)
		size = 20
	elif event.combos.has(&"weak") or event.combos.has(&"conducted") or event.combos.has(&"popped"):
		color = Color(1.0, 1.0, 0.6)
		size = 17
	elif event.family_multiplier < 1.0:
		color = Color(0.65, 0.65, 0.7)
		size = 12
	if event.kind == &"status":
		size = 11
		color = color.darkened(0.15)
	add_child(FloatingNumber.new(event.enemy.global_position + Vector2(randf_range(-10, 10), -30),
		str(roundi(event.amount)), color, size))

# A number that rises and fades (world space).
class FloatingNumber:
	extends Node2D
	const LIFE := 0.8
	var _text: String
	var _color: Color
	var _size: int
	var _age := 0.0

	func _init(at: Vector2, text: String, color: Color, size: int) -> void:
		global_position = at
		_text = text
		_color = color
		_size = size

	func _process(delta: float) -> void:
		_age += delta
		position.y -= 30.0 * delta
		if _age >= LIFE:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var alpha := 1.0 - _age / LIFE
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, _size).x
		draw_string_outline(font, Vector2(-width / 2, 0), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, _size, 4,
			Color(0.05, 0.05, 0.08, alpha))
		draw_string(font, Vector2(-width / 2, 0), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, _size,
			Color(_color, alpha))
