extends RefCounted
# Setup credit (Balancing Discussion with the owner, 2026-10-16; balance_simulation.md "Setup cards"). Preloaded as
# DreamState.SETUP (no class_name; Tower and the class nodes preload it too). Static helpers and one static context only.
#
# The ledger: one Dictionary per nightmare, in its meta META: {status id: {card or evolution id: stacks added}}, plus
# TOTAL ("*") under Poisoned and Charged = every stack applied to it (any source), for the status-damage share below.
# At most MAX_SOURCES ids per status (later ones are dropped). It dies with the nightmare.
#   Written by: Tower._apply_one_status (Bitter Sap, the role cards' extra stacks, any application made while `acting`
#   names a card), note() at the quiet adds (EnemyStatuses.add_quiet's return), apply() at direct Enemy.apply_status
#   calls, note_linger() at the Linger cards (stack-equivalent: stacks x seconds / the status's default duration).
#   Card amounts are what the card asked for, clamped to the room left on the nightmare (never measured after: the
#   application that completes a Reaction fires it inside apply_status, so the ledger is written before it).
#
# The split (DreamState._credit_hit): a payoff's own damage (a card or evolution whose Uses name statuses) goes 50% to it
# ("damage") and 50% ("setup") to the ids in the ledger for those statuses whose Makes match (the status word, its
# umbrella, or Stacks / Linger / Layered), in proportion to their stacks; a payoff never sets itself up; no setup stacks
# on that nightmare = the payoff keeps 100%. A Reaction's own damage (event.reaction_amount less what payoff cards'
# multipliers already took) gives 50% to its feeders the same way; the Reaction itself keeps all of it in DamageLog.
# Poisoned ticks and Charged bolts: each id's share of TOTAL is its own "damage" (doses, Clump, Season, Bitter Sap…).

const KEYWORDS := preload("res://scripts/run/dream_keywords.gd")
const CALLING_PATHS := preload("res://scripts/combat/calling_paths.gd")

const META := &"setup_ledger"
const TOTAL := "*"
const MAX_SOURCES := 9  # (TOTAL takes one slot under Poisoned and Charged)
const SETUP_SHARE := 0.5
# Words that make every status (a Stacks / Linger / Layered maker sets up any status payoff).
const ANY_STATUS_MAKES: Array[StringName] = [&"stacks", &"linger", &"layered"]
# Uses words that read every status.
const ANY_STATUS_USES: Array[StringName] = [&"stacks", &"linger", &"layered"]

# The card (or evolution) whose application is being made right now (Tower._apply_one_status notes it); &"" = none.
# Set with begin() / end() around a non-native application.
static var acting: StringName = &""
static var _uses := {}  # id -> [statuses: Array, uses_reaction: bool]
static var _makes := {}  # id -> Array of makes words
static var _rule_cards := {}  # rule or id -> card id (rebuilt with DreamState.rules_stamp)
static var _rule_stamp := -1
static var _rule_owner := 0  # DreamState instance id: a new run never reads the last run's map

static func begin(id: StringName) -> void:
	acting = id

static func end() -> void:
	acting = &""

# --- Writing the ledger -----------------------------------------------------------------------------------------------

# `id` added `stacks` of `status` to `enemy`. `count_total`: also add them to TOTAL (adds that never pass through
# Tower._apply_one_status: quiet adds, direct apply_status calls).
static func note(enemy, id, status: StringName, stacks: float, count_total: bool = false) -> void:
	if stacks <= 0.0 or String(id) == "" or not is_instance_valid(enemy) or not (enemy is Node):
		return
	var ledger: Dictionary
	if enemy.has_meta(META):
		ledger = enemy.get_meta(META)
	else:
		ledger = {}
		enemy.set_meta(META, ledger)
	if not ledger.has(status):
		ledger[status] = {}
	var row: Dictionary = ledger[status]
	var key := String(id)
	if row.has(key) or row.size() < MAX_SOURCES:
		row[key] = float(row.get(key, 0.0)) + stacks
	if count_total and (status == EnemyStatuses.SPORED or status == EnemyStatuses.STATIC):
		row[TOTAL] = float(row.get(TOTAL, 0.0)) + stacks

# Every Tower._apply_one_status, just before Enemy.apply_status: TOTAL, the acting card, Bitter Sap (`sap`) and the role
# cards' extra stacks (`role_rows` = [[card id, stacks], …], usually empty). `requested` = all the stacks asked for.
static func before_apply(dreams, enemy, status: StringName, requested: int, max_stacks: int, sap: int, role_rows: Array) -> void:
	if requested <= 0 or not is_instance_valid(enemy):
		return
	var room: int = enemy.statuses.get_max_stacks(status, max_stacks) - enemy.statuses.stacks(status)
	if room <= 0 and status != EnemyStatuses.SPORED:
		return  # Nothing lands (Poisoned batches may refresh past the cap: counted below as asked)
	var landing: int = requested if status == EnemyStatuses.SPORED else mini(requested, room)
	if status == EnemyStatuses.SPORED or status == EnemyStatuses.STATIC:
		var ledger: Dictionary
		if enemy.has_meta(META):
			ledger = enemy.get_meta(META)
		else:
			ledger = {}
			enemy.set_meta(META, ledger)
		if not ledger.has(status):
			ledger[status] = {}
		ledger[status][TOTAL] = float(ledger[status].get(TOTAL, 0.0)) + landing
	if acting != &"":
		note(enemy, acting, status, landing)
	if sap > 0 and dreams != null:
		note(enemy, rule_card(dreams, &"bitter_sap"), status, mini(sap, landing))
	for row in role_rows:
		note(enemy, rule_card(dreams, StringName(row[0])), status, mini(int(row[1]), landing))

# A direct Enemy.apply_status made by card or evolution `id` (Moth to Flame, Constellation, Mother Spore, Shared Spark,
# Ebb): the ledger first (it may complete a Reaction), then the application.
static func apply(enemy, id, status: StringName, stacks: int, duration: float, potency: float, max_stacks: int,
		line: String, source) -> void:
	if not is_instance_valid(enemy):
		return
	var room: int = enemy.statuses.get_max_stacks(status, max_stacks) - enemy.statuses.stacks(status)
	note(enemy, id, status, mini(stacks, maxi(room, 0)), true)
	enemy.apply_status(status, stacks, duration, potency, max_stacks, line, source)

# A Linger card added `seconds` to `status` on `enemy`: stack-equivalent setup = stacks x seconds / default duration
# (a 5 s Poisoned of 10 stacks kept 2 s longer counts as 4 stacks).
static func note_linger(enemy, id, status: StringName, seconds: float) -> void:
	if seconds <= 0.0 or not is_instance_valid(enemy) or not enemy.statuses.has(status):
		return
	var base: float = float(EnemyStatuses.DEFAULT_DURATION.get(status, 1.0))
	note(enemy, id, status, float(enemy.statuses.stacks(status)) * seconds / maxf(base, 0.1))

# Seconds a status has left (0 if none): for top_up callers, which return nothing.
static func time_left(enemy, status: StringName) -> float:
	return enemy.statuses.time_left(status) if is_instance_valid(enemy) and enemy.statuses.has(status) else 0.0

# --- Control (seconds of slow or hold a card or evolution added) ------------------------------------------------------

# Full-stop seconds: a hold, sleep or grounding counts its seconds; a slow counts seconds x its strength (0.5 for 2 s =
# 1 s); a pull back counts the pixels over the nightmare's speed (the walking time it lost).
static func control(dreams, id, seconds: float) -> void:
	if dreams != null and seconds > 0.0:
		dreams._credit(rule_card(dreams, StringName(id)), "control", seconds)

static func control_slow(dreams, id, amount: float, seconds: float) -> void:
	control(dreams, id, clampf(amount, 0.0, 1.0) * seconds)

static func control_pull(dreams, id, enemy, pixels: float) -> void:
	if pixels <= 0.0 or not is_instance_valid(enemy):
		return
	var speed: float = float(enemy.get("speed")) if enemy.get("speed") != null else 0.0
	if speed > 0.0:
		control(dreams, id, pixels / speed)

# --- Ids --------------------------------------------------------------------------------------------------------------

# The taken card granting `rule` (its id, rule_id or extra_rules); the rule itself when no card says so (lent / role
# cards whose rule is their id, evolution ids).
static func rule_card(dreams, rule: StringName) -> String:
	if dreams == null:
		return String(rule)
	if _rule_stamp != dreams.rules_stamp or _rule_owner != dreams.get_instance_id() or _rule_cards.is_empty():
		_rule_stamp = dreams.rules_stamp
		_rule_owner = dreams.get_instance_id()
		_rule_cards.clear()
		for card in dreams._taken_cards():
			_rule_cards[StringName(card.id)] = card.id
			if card.rule_id != &"":
				_rule_cards[card.rule_id] = card.id
			for extra in card.extra_rules:
				if not _rule_cards.has(StringName(extra)):
					_rule_cards[StringName(extra)] = card.id
		if _rule_cards.is_empty():
			_rule_cards[&""] = ""  # Not empty: rebuilt only when the stamp moves
	return String(_rule_cards.get(rule, String(rule)))

static func _chips(dreams, id: String) -> void:
	if _makes.has(id):
		return
	var makes: Array = []
	var uses: Array = []
	var row: Dictionary = CALLING_PATHS.PATHS.get(StringName(id), {})
	if not row.is_empty():
		makes = row.get("makes", [])
		uses = row.get("uses", [])
	elif dreams != null:
		var card: UpgradeData = dreams._card_by_id(id)
		if card != null:
			makes = card.makes.duplicate()
			uses = KEYWORDS.derived_uses(card)
			for word in card.uses:
				if not uses.has(word):
					uses.append(word)
	_makes[id] = makes
	var statuses: Array = []
	var reaction := false
	for word in uses:
		var w := StringName(word)
		if w == &"reaction":
			reaction = true
		elif ANY_STATUS_USES.has(w):
			for s in EnemyStatuses.ALL:
				if not statuses.has(s):
					statuses.append(s)
		elif w == &"slow":
			for s in [EnemyStatuses.HELD, EnemyStatuses.DROWSY]:
				if not statuses.has(s):
					statuses.append(s)
		elif KEYWORDS.STATUSES.has(w):
			var s: StringName = KEYWORDS.STATUSES[w]
			if s == &"asleep":
				s = EnemyStatuses.DROWSY  # Sleep comes from Drowsy
			if not statuses.has(s):
				statuses.append(s)
	_uses[id] = [statuses, reaction]

# Whether `id` makes something that feeds `statuses` (its Makes chips: the status word, its umbrella, or Stacks / Linger
# / Layered).
static func makes_for(dreams, id: String, statuses: Array) -> bool:
	_chips(dreams, id)
	for word in _makes[id]:
		var w := StringName(word)
		if ANY_STATUS_MAKES.has(w):
			return true
		for s in statuses:
			var sw: StringName = KEYWORDS.word_for_status(s)
			if sw != &"" and (w == sw or KEYWORDS.counts_as(sw, w) or (s == EnemyStatuses.DROWSY and w == &"asleep")):
				return true
			if w == &"slow" and (s == EnemyStatuses.HELD or s == EnemyStatuses.DROWSY):
				return true
	return false

# --- The split --------------------------------------------------------------------------------------------------------

# The statuses of the Reaction this event is (its tag, or Ignite's burn on a Spored tick); [] if none.
static func reaction_statuses(event) -> Array:
	if Reactions.REACTION_STATUSES.has(event.tag):
		return Reactions.REACTION_STATUSES[event.tag]
	if event.combos.has(&"ignite"):
		return Reactions.REACTION_STATUSES[&"ignite"]
	return []

# Payoff `id` dealt `amount` on event's nightmare: its own share as "damage", the rest as "setup" to who set it up.
static func credit_own(dreams, id: String, amount: float, event) -> void:
	if amount <= 0.0 or id == "":
		return
	_chips(dreams, id)
	var info: Array = _uses[id]
	var statuses: Array = info[0]
	if bool(info[1]):
		var rx := reaction_statuses(event)
		statuses = rx if not rx.is_empty() else EnemyStatuses.ALL
	if statuses.is_empty() or not _split(dreams, event.enemy, statuses, amount * SETUP_SHARE, id):
		dreams._credit(id, "damage", amount)
		return
	dreams._credit(id, "damage", amount * (1.0 - SETUP_SHARE))

# A Reaction's own damage: half to its feeders by their stacks on this nightmare (the Reaction keeps its DamageLog credit).
static func credit_reaction(dreams, event) -> void:
	if event.reaction_amount <= 0.0:
		return
	var statuses := reaction_statuses(event)
	if statuses.is_empty():
		return
	var own: float = event.reaction_amount
	for id in event.card_damage:
		own -= float(event.card_damage[id])  # What payoff cards' multipliers took is split by credit_own
	if own > 0.0:
		_split(dreams, event.enemy, statuses, own * SETUP_SHARE, "")

# Poisoned ticks and Charged bolts: the stacks' own damage, by each id's share of everything applied of that status.
static func credit_status_damage(dreams, event) -> void:
	var status: StringName = &""
	if event.tag == &"spored":
		status = EnemyStatuses.SPORED
	elif event.tag == &"static" and event.kind == &"bolt":
		status = EnemyStatuses.STATIC
	else:
		return
	if not is_instance_valid(event.enemy) or not event.enemy.has_meta(META):
		return
	var row: Dictionary = (event.enemy.get_meta(META) as Dictionary).get(status, {})
	var total: float = float(row.get(TOTAL, 0.0))
	if total <= 0.0 or row.size() < 2:
		return
	var own: float = event.amount
	for id in event.card_damage:
		own -= float(event.card_damage[id])
	if own <= 0.0:
		return
	for id in row:
		if id != TOTAL:
			dreams._credit(id, "damage", own * minf(float(row[id]) / total, 1.0))

# Splits `amount` as "setup" between the ids that put `statuses` on `enemy` and make them (never `skip`). False = none.
static func _split(dreams, enemy, statuses: Array, amount: float, skip: String) -> bool:
	if amount <= 0.0 or not is_instance_valid(enemy) or not enemy.has_meta(META):
		return false
	var ledger: Dictionary = enemy.get_meta(META)
	var weights := {}
	var total := 0.0
	for s in statuses:
		var row: Dictionary = ledger.get(s, {})
		for id in row:
			if id == TOTAL or id == skip or not makes_for(dreams, id, statuses):
				continue
			weights[id] = float(weights.get(id, 0.0)) + float(row[id])
			total += float(row[id])
	if total <= 0.0:
		return false
	for id in weights:
		dreams._credit(id, "setup", amount * float(weights[id]) / total)
	return true

# --- Maze (route cells covered) ---------------------------------------------------------------------------------------

# At each rest: for every taken card with a Maze chip, the route cells inside the reach of a Warden its row is active on
# (DreamState.get_card_effects; a wall's reach is the cells around it). Credited as "maze", once per block.
static func credit_maze(dreams) -> void:
	var route: Array = dreams._path_index.keys()
	if route.is_empty():
		return
	var covered := {}  # card id -> {cell: true}
	for tower in dreams._towers():
		var ids: Array = []
		for row in dreams.get_card_effects(tower.tower_data, tower.cell, tower):
			if not row.active:
				continue
			var id: String = DreamState._row_card_id(row)
			if id != "" and not ids.has(id) and _is_maze(dreams, id):
				ids.append(id)
		if ids.is_empty():
			continue
		var cell_px: float = tower.MAP_GRID.cell_size.x
		var reach: float = maxf(tower.get_range_pixels(), cell_px * 1.5)
		for cell in route:
			if tower.global_position.distance_to(tower.MAP_GRID.calculate_map_position(cell)) > reach:
				continue
			for id in ids:
				if not covered.has(id):
					covered[id] = {}
				covered[id][cell] = true
	for id in covered:
		dreams._credit(id, "maze", float(covered[id].size()))

static func _is_maze(dreams, id: String) -> bool:
	_chips(dreams, id)
	if _makes[id].has(&"maze"):
		return true
	var card: UpgradeData = dreams._card_by_id(id)
	return card != null and (card.uses.has(&"maze") or KEYWORDS.derived_uses(card).has(&"maze"))
