extends SceneTree

# Balance probe (not a test), the start of the balance simulation (run_design.md "Act 3 probe"): a maze
# a player could really have by drift 60, then drifts 61-70 fought for real.
#   1. Income for drifts 1-60 from the real schedules: every arrival (with its splits and followers)
#      dispelled at RunState._scaled_dispel_dew, the director's rest bonus (perfect blocks, + Dreams),
#      and CALL_EARLY_DEW per drift. Omens: always Clear Skies. Dreamlight (added by DreamState.sim_rest /
#      sim_family_pick): +1 at the first family pick,
#      +3 at each boss, plus cards.
#   2. At every rest a real Dream offer (DreamState.sim_rest / make_offer) with a simple policy: damage
#      and owned-family cards first, never Bittersweet. Family picks after drift 1 and at 25 / 50.
#   3. Greedy spending at each rest through the real TowerPlacer: unlock forms with Dreamlight (finals of
#      owned branches first), plant attacking Wardens on the cell that covers most of the route (and
#      lengthens it), grow the cheapest form, nurture the lowest rank (Power).
#   4. Drifts 61-70 for real (the rest at 65 spends and picks too). Reports damage vs health spawned,
#      leaks, the top Wardens, the Asleep share, and the maze it built.
# Run from the project folder (one seed per run):
#   godot --headless --path . --script res://tools/balance_run.gd --fixed-fps 60 -- --seed=7
# (add --grove=all for a veteran profile: every Grove card and family; without it, final forms that
# need the Memory Grove stay locked, as on a fresh profile).

const FIRST_FIGHT := 61
const LAST_FIGHT := 70
const SPEED := 4.0
const CALL_EARLY_DEW := 5  # Average Dew for calling a drift early (cap 10)
const MAX_ATTACKERS := 16  # Past this the plan grows and nurtures instead of planting
const NO_CELL := Vector2(-1, -1)

var main: Node
var map
var placer: TowerPlacer
var seller: TowerSeller
var dreams: DreamState
var run_state: RunState
var director: DriftDirector
var spawner
var container: Node
var rng := RandomNumberGenerator.new()
var map_seed := 7
var grove_all := false  # --grove=all: a veteran profile (every Grove card and family); default = a fresh one

var families: Array[TowerData] = []  # Base Wardens of the picked families
var cards_taken: Array[String] = []
var spent := {"plant": 0, "grow": 0, "nurture": 0}
var income := {"dispels": 0, "rests": 0, "call_early": 0}
var planted_order := 0

# Fight stats (DamageLog events), as in balance_act3.gd.
var by_tower := {}
var total := 0.0
var on_asleep := 0.0
var spawned_health := 0.0
var leaked_health := 0.0
var leaked := 0
var dispelled := 0
var game_time := 0.0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			map_seed = int(arg.get_slice("=", 1))
		if arg == "--grove=all":
			grove_all = true
	rng.seed = map_seed
	MetaRun.force_all_families = grove_all  # Every family can come up in the picks
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = map_seed
	root.add_child(main)
	await process_frame
	map = main.get_node("%MapGenerator")
	placer = main.get_node("%TowerPlacer")
	seller = main.get_node("%TowerSeller")
	dreams = main.get_node("%DreamState")
	run_state = main.get_node("%RunState")
	director = main.get_node("%DriftDirector")
	spawner = main.get_node("%EnemyContainer")
	container = main.get_node("%TowerContainer")
	dreams._rng.seed = map_seed
	if grove_all:
		for card in dreams.pool:
			if not card.in_start_pool and not dreams.grove_cards.has(card.id):
				dreams.grove_cards.append(card.id)  # Final forms, Ascension and Grove Dreams
	run_state.invulnerable = true

	# --- Drifts 1-60 on paper, building at each rest ---
	_spend()  # The opening: 60 Dew of Sprouts
	for n in range(1, FIRST_FIGHT):
		director.drifts_started = n
		director.drifts_cleared = n
		_earn_drift(n)
		if n == 1:
			_family_pick(&"first")
		if n % director.drifts_per_block == 0:
			if n % director.drifts_per_act == 0:
				_family_pick(&"boss")
			_rest(n)
	_print_maze("maze at drift 60")

	# --- Drifts 61-70 for real ---
	if DamageLog.instance:
		DamageLog.instance.damage_dealt.connect(_on_damage)
	spawner.child_entered_tree.connect(func(n) -> void:
		if n.has_method("take_damage"):
			(func() -> void: spawned_health += n.max_health).call_deferred())
	spawner.enemy_cleansed.connect(func(_e) -> void: dispelled += 1)
	spawner.enemy_reached_goal.connect(func(e) -> void:
		leaked += 1
		leaked_health += e.health)
	director.drifts_started = FIRST_FIGHT - 1
	director.drifts_cleared = FIRST_FIGHT - 1
	Engine.time_scale = SPEED
	var frames := 0
	var rested_at := FIRST_FIGHT - 1
	while director.drifts_cleared < LAST_FIGHT and frames < 60 * 60 * 40:
		paused = false
		if director.is_resting() and director.drifts_started < LAST_FIGHT:
			if director.drifts_cleared > rested_at:
				rested_at = director.drifts_cleared
				Engine.time_scale = 1.0
				await _close_real_offers()
				_spend()
				Engine.time_scale = SPEED
			director.start_next_block()
		await process_frame
		frames += 1
		game_time += SPEED / 60.0
	Engine.time_scale = 1.0
	_report()
	quit(0)

# --- Income --------------------------------------------------------------------------------------------

func _earn_drift(n: int) -> void:
	var mods := director.get_schedule_modifiers(n)
	var schedule: Array = director.drifts[n - 1].get_schedule(mods.get("count", 1.0), mods.get("flyers", 1.0),
		mods.get("spacing", 1.0), director.get_extra_nightmares(n))
	director.add_guaranteed_elite(schedule, n)
	var dew := 0
	for arrival in schedule:
		var elite: bool = arrival.size() > 2 and arrival[2]
		dew += _dispel_dew(arrival[1], elite)
	run_state.add_dew(dew)
	income.dispels += dew
	run_state.add_dew(CALL_EARLY_DEW)
	income.call_early += CALL_EARLY_DEW

# Dew for dispelling one `data` and everything it splits into or brings along.
func _dispel_dew(data: EnemyData, elite: bool) -> int:
	var base: int = data.dew_reward * (2 if elite else 1)  # Enemy.ELITE_DEW (enemy.gd has no class_name)
	var dew := run_state._scaled_dispel_dew(base)
	if data.split_into != null:
		for i in data.split_count:
			dew += _dispel_dew(data.split_into, false)
	if data.followers != null:
		for i in data.follower_count:
			dew += _dispel_dew(data.followers, false)
	return dew

func _rest(n: int) -> void:
	var paid: Array = director._pay_rest_bonus()  # Perfect block (the paper run leaks nothing)
	income.rests += int(paid[0])
	_take_dreams(n)
	_spend()

# --- Dreams and families -------------------------------------------------------------------------------

func _take_dreams(n: int) -> void:
	for card in dreams.sim_rest(n, _pick_card, true):  # Rest rules, the real offer, boss Dreamlight
		cards_taken.append(card.id)

# The policy: damage and speed first, owned families' cards next, rarer is better; never Bittersweet.
func _pick_card(offer: Array):
	var best = null
	var best_score := 0.0
	var lines := {}
	for f in families:
		lines[f.line] = true
	for card in offer:
		if card == null or card.tags.has("bittersweet") or card.creature_health_bonus > 0.0:
			continue
		var score: float = 1.0 + card.rarity
		score += card.soothe_bonus * 20.0 + card.attack_speed_bonus * 15.0 + card.potency_bonus * 8.0 + card.range_bonus * 3.0
		for tag in card.tags:
			if lines.has(tag):
				score += 2.0
		if dreams.has_method("is_in_build") and dreams.is_in_build(card):
			score += 1.5
		if card.stat_line != "" and lines.has(card.stat_line):
			score += 2.0
		score += card.dreamlight_now * 1.5 + card.dew_now * 0.01
		if score > best_score:
			best_score = score
			best = card
	return best

func _family_pick(kind: StringName) -> void:
	var id: StringName = dreams.sim_family_pick(kind, _pick_family_id)  # (&"first" adds its Dreamlight)
	var chosen: TowerData = _tower_data(String(id)) if id != &"" else null
	paused = false
	if chosen != null and not families.has(chosen):
		families.append(chosen)

func _pick_family_id(offered: Array) -> StringName:
	return StringName(offered[rng.randi() % offered.size()]) if not offered.is_empty() else &""

func _tower_data(id: String) -> TowerData:
	var path := "res://resource/tower/%s.tres" % id
	return load(path) if ResourceLoader.exists(path) else null

# The real rest during the fight (drift 65): pick the Dream with the policy, Clear Skies for Omens.
func _close_real_offers() -> void:
	await process_frame
	if dreams.is_offering():
		var pick = _pick_card(dreams.current_offer)
		if pick != null:
			dreams.choose(pick)
			cards_taken.append(pick.id)
		else:
			dreams.skip()
	var omens = main.get_node_or_null("%OmenDirector")
	if omens and omens.is_offering():
		omens.choose(null)

# --- Spending --------------------------------------------------------------------------------------------

func _spend() -> void:
	_unlock_forms()
	for guard in 200:
		if not (_try_plant() or _try_grow() or _try_nurture()):
			return

func _attackers() -> Array:
	return container.get_children().filter(func(t) -> bool:
		return t is Tower and not t.is_queued_for_deletion() and t.tower_data.can_attack)

# Dreamlight: finals of branches on the map first, then branches of the families with most Wardens.
func _unlock_forms() -> void:
	var wanted: Array = []
	for tower in _attackers():
		for form in tower.tower_data.evolves_to:
			if form is TowerData and not dreams.is_unlocked(form.get_id()) and not wanted.has(form):
				wanted.append(form)
	wanted.sort_custom(func(a: TowerData, b: TowerData) -> bool: return a.tier > b.tier)
	for form in wanted:
		dreams.unlock_with_dreamlight(form)

func _try_plant() -> bool:
	# Room grows with the run (4 at the start, the full MAX_ATTACKERS by drift ~48), so later families
	# get planted too; the family with the fewest Wardens goes next.
	var room := mini(MAX_ATTACKERS, 4 + director.drifts_started / 4)
	if _attackers().size() >= room:
		return false
	var options: Array[TowerData] = []
	for f in families:
		if dreams.is_unlocked(f.get_id()):
			options.append(f)
	if options.is_empty():
		options.append(_tower_data("sprout"))
	options.sort_custom(func(a: TowerData, b: TowerData) -> bool: return _family_count(a) < _family_count(b))
	var data: TowerData = options[0]
	placer.tower_data = data
	if not run_state.can_afford(placer.get_cost(data)):
		return false
	var cell := _best_cell(data)
	if cell == NO_CELL:
		return false
	var dew := run_state.dew
	if not placer._try_build(cell):
		return false
	spent.plant += dew - run_state.dew
	planted_order += 1
	return true

# The open cell whose Warden would cover most of the route (and lengthen it: Wardens are walls).
func _best_cell(data: TowerData) -> Vector2:
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var reach := data.attack_range
	var best := NO_CELL
	var best_score := -INF
	for y in Tower.MAP_GRID.size.y:
		for x in Tower.MAP_GRID.size.x:
			var cell := Vector2(x, y)
			if not map.is_buildable(cell):
				continue
			var new_route: PackedVector2Array = map.get_path_if_blocked_cells([cell])
			if new_route.is_empty():
				continue
			var cover := 0
			for at in new_route:
				if at.distance_to(cell) <= reach:
					cover += 1
			var score := cover + 1.5 * (new_route.size() - route.size())
			if score > best_score:
				best_score = score
				best = cell
	return best

# The cheapest affordable form any Warden could grow into (lowest tier first).
func _try_grow() -> bool:
	var best: Array = []
	for tower in _attackers():
		for form in tower.tower_data.evolves_to:
			if not (form is TowerData) or not dreams.is_unlocked(form.get_id()) or placer.ascended_blocker(form) != "":
				continue
			if form.tier >= DreamState.ASCENDED_TIER and placer.get_grow_squares(tower, form).is_empty():
				continue
			var cost: int = tower.get_grow_cost(form).total
			if cost > run_state.dew:
				continue
			var key: Array = [tower.tower_data.tier, cost]
			if best.is_empty() or key < best[0]:
				best = [key, tower, form]
	if best.is_empty():
		return false
	var dew := run_state.dew
	if not placer.evolve(best[1], best[2]):
		return false
	spent.grow += dew - run_state.dew
	return true

func _try_nurture() -> bool:
	var towers := _attackers().filter(func(t) -> bool: return t.can_nurture() and t.get_nurture_cost() <= run_state.dew)
	if towers.is_empty():
		return false
	towers.sort_custom(func(a, b) -> bool: return a.rank < b.rank)
	var tower: Tower = towers[0]
	var dew := run_state.dew
	var focus := Tower.Focus.POWER if tower.needs_focus() else Tower.Focus.NONE
	if not placer.nurture(tower, focus):
		return false
	spent.nurture += dew - run_state.dew
	return true

# --- Reporting -------------------------------------------------------------------------------------------

func _on_damage(event) -> void:
	total += event.amount
	var name: String = event.source_name
	by_tower[name] = by_tower.get(name, 0.0) + event.amount
	if is_instance_valid(event.enemy) and (event.enemy.statuses.is_asleep() or (event.enemy.statuses.has(EnemyStatuses.DROWSY)
			and event.enemy.statuses.stacks(EnemyStatuses.DROWSY) >= event.enemy.statuses.get_max_stacks(EnemyStatuses.DROWSY))):
		on_asleep += event.amount

func _print_maze(title: String) -> void:
	var by_kind := {}
	var tiers := [0, 0, 0, 0, 0]
	var ranks := 0
	for tower in _attackers():
		var key: String = tower.tower_data.display_name
		by_kind[key] = by_kind.get(key, 0) + 1
		tiers[clampi(tower.tower_data.tier, 0, 4)] += 1
		ranks += tower.rank
	var attackers := _attackers().size()
	print("=== %s (map seed %d, %s) ===" % [title, map_seed, "whole Grove" if grove_all else "fresh profile"])
	print("  families: %s" % ", ".join(families.map(func(f: TowerData) -> String: return f.display_name)))
	print("  income: dispels %d, rests %d, call-early %d; spent: plant %d, grow %d, nurture %d; %d Dew left, %d Dreamlight left" % [
		income.dispels, income.rests, income.call_early, spent.plant, spent.grow, spent.nurture, run_state.dew, dreams.dreamlight])
	print("  %d attacking Wardens (tier 1-4: %d / %d / %d / %d), average rank %.1f, route %d tiles" % [attackers,
		tiers[1], tiers[2], tiers[3], tiers[4], float(ranks) / maxf(attackers, 1), map.get_path_from(map.startPath).size()])
	print("  Wardens: %s" % str(by_kind))
	print("  Dreams (%d): %s" % [cards_taken.size(), ", ".join(cards_taken)])

func _report() -> void:
	var drifts := director.drifts_cleared - FIRST_FIGHT + 1
	print("=== drifts %d-%d (map seed %d): %d cleared ===" % [FIRST_FIGHT, LAST_FIGHT, map_seed, drifts])
	var rows := by_tower.keys()
	rows.sort_custom(func(a, b) -> bool: return by_tower[a] > by_tower[b])
	for name in rows.slice(0, 3):
		print("  top: %-22s %10.0f  %5.1f%%" % [name, by_tower[name], 100.0 * by_tower[name] / maxf(total, 1.0)])
	print("  damage %.0f per drift vs %.0f health spawned per drift (x%.2f)" % [total / maxf(drifts, 1),
		spawned_health / maxf(drifts, 1), total / maxf(spawned_health, 1.0)])
	print("  %d dispelled, %d leaked (%.1f%% of the health)" % [dispelled, leaked, 100.0 * leaked_health / maxf(spawned_health, 1.0)])
	print("  damage on Asleep / fully Drowsy nightmares: %.1f%%" % (100.0 * on_asleep / maxf(total, 1.0)))
	_print_maze("maze at drift 70")

# Wardens on the map from `base`'s family (its line).
func _family_count(base: TowerData) -> int:
	return _attackers().filter(func(t) -> bool: return t.tower_data.line == base.line).size()
