extends SceneTree

# Balance simulation runner (documentation/balance_simulation.md): a bot plays one whole run (drifts
# 1-100, fought for real, leaves and all) on the real game, buying everything from the Dew the run
# earns. Roguelite Code's DreamSimPolicy makes the Dream, family-pick and Dreamlight choices (Omens:
# Clear Skies); this runner owns the maze and spending bot and writes a CSV per run.
#
#   godot --headless --path . --script res://tools/balance_sim.gd --fixed-fps 60 -- --seed=1 \
#       [--profile=fresh] [--style=balanced] [--speed=8] [--last=100] [--out=res://tools/balance_out]
#
# Output: <out>/<profile>_<style>_seed<N>.csv (one row per cleared drift) and a line appended to
# <out>/runs.csv (the run's summary; tools/balance_summary.gd turns those into the batch table and the
# pass/fail checks).
#
# Bot (shared rules, "Bot rules" in the spec): the planned maze grows with the run (attackers and
# Thornwalls); Thornwalls go where they add the most path, attackers where the most path is in range
# (plus what they add); then grow the Warden with the most path in range, then Nurture (per style).
# Spends at each rest and mid-drift whenever the next item is affordable; keeps nothing in reserve;
# never sells.

const NO_CELL := Vector2(-1, -1)
const SPEND_EVERY := 2.0  # Game seconds between mid-drift spending checks
const STYLES := {"balanced": 0, "wide": 1, "narrow": 2, "combo": 3, "sleep": 4, "sprout": 5}  # DreamSimPolicy.Style
const COLUMNS := ["drift", "act", "seconds", "health_spawned", "damage", "leaks", "leaves_lost", "leaves_left",
	"dew_rest", "dew_other", "spent_plant", "spent_walls", "spent_grow", "spent_nurture", "banked",
	"attackers", "walls", "tier1", "tier2", "tier3", "tier4", "avg_rank", "route", "families", "cards",
	"dreamlight", "top_warden", "top_share", "asleep_share", "reaction_share", "crit_share", "restless", "trampled"]

# Per style: [attacker room at drift 0, + per drift, cap], walls per attacker, nurture weight.
const STYLE_PLAN := {
	"balanced": {"room": [5, 1.0 / 3.0, 16], "walls": 1.0},  # 5 Sprouts: the opening rule (test_opening)
	"wide": {"room": [6, 0.5, 24], "walls": 2.0},
	"narrow": {"room": [4, 0.15, 8], "walls": 0.5},
	"combo": {"room": [5, 1.0 / 3.0, 16], "walls": 1.0},
	"sleep": {"room": [5, 1.0 / 3.0, 16], "walls": 1.0},
	# Sprout spam (a build): Sprouts are the walls and the attackers, planted where they add the most path.
	"sprout": {"room": [8, 3.0, 150], "walls": 0.0, "plant": "sprout", "growth_weight": 1.5},
}

var map_seed := 1
var profile := "fresh"
var style := "balanced"
var speed := 8.0
var last_drift := 100
var out_dir := "res://tools/balance_out"

var main: Node
var map
var placer: TowerPlacer
var dreams: DreamState
var run_state: RunState
var director: DriftDirector
var spawner
var container: Node
var policy
var reaction_tags := {}

var game_time := 0.0
var _spend_timer := 0.0
var _busy := false  # A family pick / rest is being handled
var rows: Array = []
var d := {}  # The current drift window's counters
var run := {"sprout_cards_25": -1, "first_leak": 0, "lost_by": {25: -1, 50: -1, 75: -1}, "banked_at_act": {}, "rest_banked": [],
	"rest_bonus": [], "top_wardens": {}, "max_top_share": 0.0, "max_top_warden": "", "max_asleep": 0.0}
var _last_dew := 0
var _spent_now := 0
const SPROUT_CARDS := ["seedfall", "sprout_surge", "sprout_chorus", "root_network", "root_network_ii", "seedling_gift", "nursery"]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		var value := arg.get_slice("=", 1)
		match arg.get_slice("=", 0):
			"--seed": map_seed = int(value)
			"--profile": profile = value
			"--style": style = value
			"--speed": speed = float(value)
			"--last": last_drift = int(value)
			"--out": out_dir = value
	if profile != "fresh":
		var meta: Script = load("res://scripts/meta/meta_run.gd")
		if not meta.get_script_method_list().any(func(m: Dictionary) -> bool: return m.name == "load_preset"):
			printerr("profile %s needs MetaRun.load_preset (Meta Game Code's presets)" % profile)
			quit(1)
			return
		ProjectSettings.set_setting("game/demo", false)  # Meta applies only in the full game
		meta.call("load_preset", StringName(profile))
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = map_seed
	root.add_child(main)
	await process_frame
	map = main.get_node("%MapGenerator")
	placer = main.get_node("%TowerPlacer")
	dreams = main.get_node("%DreamState")
	run_state = main.get_node("%RunState")
	director = main.get_node("%DriftDirector")
	spawner = main.get_node("%EnemyContainer")
	container = main.get_node("%TowerContainer")
	dreams._rng.seed = map_seed
	policy = DreamSimPolicy.new(dreams, STYLES.get(style, 0))
	for r in Reactions.all() + Reactions.crowned():
		reaction_tags[r.id] = true
	_take_over_choices()
	director.set_auto_drift(true)  # Drifts in a block flow (the HUD applies the player's own default)
	_hook_stats()
	_new_window()
	_last_dew = run_state.dew
	_spend()  # The opening
	Engine.time_scale = speed
	var frames := 0
	# Effects in lite mode and no hitstops (they slow time); nothing else may change the sim's speed.
	Fx._settings = {"hitstop": false, "reduce_flashes": true, "reduced_motion": true}
	Fx._settings_at = Time.get_ticks_msec() + 3600000 * 24
	while not run_state.is_over and director.drifts_cleared < last_drift and frames < 60 * 60 * 60 * 3:
		paused = false
		Engine.time_scale = speed
		if not _busy and director.is_resting() and not director.awaiting_family_pick:
			director.start_next_block()
		await process_frame
		frames += 1
		game_time += speed / 60.0
		_spend_timer -= speed / 60.0
		if _spend_timer <= 0.0 and not _busy:
			_spend_timer = SPEND_EVERY
			_spend()
	Engine.time_scale = 1.0
	_finish()
	if profile != "fresh" and ResourceLoader.exists("res://scripts/meta/grove_presets.gd"):
		load("res://scripts/meta/grove_presets.gd").call("unload")  # Back to the real profile path
	quit(0)

# The real rest and family pick open screens and offers; the bot answers them through the policy
# instead (DreamSimPolicy wraps sim_rest / sim_family_pick, which do the rest rules and Dreamlight).
func _take_over_choices() -> void:
	for c in director.rest_started.get_connections():
		var target: Object = c.callable.get_object()
		if target == dreams or target is OmenDirector:
			director.rest_started.disconnect(c.callable)
	for c in director.family_pick_requested.get_connections():
		var target: Object = c.callable.get_object()
		if target == dreams or (target is Node and target.name == "FamilyPickScreen"):
			director.family_pick_requested.disconnect(c.callable)
	director.rest_started.connect(func(_block: int, _boss: bool, bonus: int, perfect: bool) -> void:
		d.dew_rest += bonus
		_on_rest.call_deferred(perfect))
	director.family_pick_requested.connect(func(kind: StringName) -> void: _on_family_pick.call_deferred(kind))

func _on_family_pick(kind: StringName) -> void:
	_busy = true
	policy.family_pick(kind)
	paused = false
	director.family_picked()
	_busy = false

func _on_rest(perfect: bool) -> void:
	_busy = true
	var n := director.drifts_started
	policy.rest(n, perfect)
	paused = false
	var bonus := director.get_rest_bonus(director.get_block(n))
	run.rest_banked.append(run_state.dew)
	run.rest_bonus.append(bonus)
	if n % director.drifts_per_act == 0:
		run.banked_at_act[n / director.drifts_per_act + 1] = run_state.dew
	_spend()
	_busy = false

# --- Spending ------------------------------------------------------------------------------------------

func _spend() -> void:
	for guard in 60:
		var dew := run_state.dew
		var kind := _next_buy()
		if kind == "":
			return
		_spent_now = dew - run_state.dew
		d["spent_" + kind] += maxi(_spent_now, 0)

# One purchase by the plan's order; returns what it bought ("plant", "walls", "grow", "nurture") or "".
func _next_buy() -> String:
	var plan: Dictionary = STYLE_PLAN.get(style, STYLE_PLAN.balanced)
	var room: Array = plan.room
	var attackers := _attackers().size()
	var target := mini(int(room[2]), int(room[0] + room[1] * director.drifts_started))
	var walls := _walls().size()
	if attackers < target and _plant_attacker():
		return "plant"
	if walls < int(attackers * plan.walls) and _plant_wall():
		return "walls"
	if _grow():
		return "grow"
	# A sensible player saves up for an unlocked growth (a branch is 80 Dew) instead of spending every
	# Dew on ranks; Narrow nurtures anyway.
	var saving := _cheapest_growth()
	if style != "narrow" and saving > 0 and saving <= 3 * director.get_rest_bonus(director.get_block(maxi(director.drifts_started, 1))):
		return ""
	if _nurture():
		return "nurture"
	# Keep nothing in reserve (the spec): nothing else to buy (ranks capped at II without a Nurture
	# Dream, growths locked), so plant one more attacker past the planned room.
	if run_state.dew >= 2 * director.get_rest_bonus(director.get_block(maxi(director.drifts_started, 1))) \
			and _plant_attacker():
		return "plant"
	return ""

# Dew for the cheapest growth open to a Warden on the map (0 = none).
func _cheapest_growth() -> int:
	var cheapest := 0
	for tower in _attackers():
		if style == "sprout" and tower.tower_data.get_id() == "sprout":
			continue
		for form in tower.tower_data.evolves_to:
			if form is TowerData and dreams.is_unlocked(form.get_id()) and placer.ascended_blocker(form) == "" \
					and (form.footprint <= tower.get_footprint() or not placer.get_grow_squares(tower, form).is_empty()):
				var cost: int = tower.get_grow_cost(form).total
				if cheapest == 0 or cost < cheapest:
					cheapest = cost
	return cheapest

func _attackers() -> Array:
	return container.get_children().filter(func(t) -> bool:
		return t is Tower and not t.is_queued_for_deletion() and t.tower_data.can_attack)

func _walls() -> Array:
	return container.get_children().filter(func(t) -> bool:
		return t is Tower and not t.is_queued_for_deletion() and not t.tower_data.can_attack)

func _plant_attacker() -> bool:
	var plan: Dictionary = STYLE_PLAN.get(style, STYLE_PLAN.balanced)
	if plan.has("plant"):
		var only: TowerData = load("res://resource/tower/%s.tres" % plan.plant)
		if not run_state.can_afford(placer.get_cost(only)):
			return false
		var at := _best_cell(only.attack_range, plan.get("growth_weight", 0.5))
		return at != NO_CELL and _build(only, at)
	var options: Array = placer.get_buildable_towers().filter(func(t: TowerData) -> bool:
		return t.can_attack and t.buildable_directly and t.get_id() != "sprout" and t.footprint == 1 and not t.is_unique)
	if options.is_empty():
		options = [load("res://resource/tower/sprout.tres")]
	options.sort_custom(func(a: TowerData, b: TowerData) -> bool: return _family_count(a) < _family_count(b))
	var data: TowerData = options[0]
	if not run_state.can_afford(placer.get_cost(data)):
		return false
	var cell := _best_cell(data.attack_range, 0.5)
	return cell != NO_CELL and _build(data, cell)

func _plant_wall() -> bool:
	var wall: TowerData = load("res://resource/tower/thornwall.tres")
	if not run_state.can_afford(placer.get_cost(wall)):
		return false
	var cell := _best_cell(0.0, 1.0)
	return cell != NO_CELL and _build(wall, cell)

func _build(data: TowerData, cell: Vector2) -> bool:
	placer.tower_data = data
	return placer._try_build(cell)

# The open cell scoring best: path cells within `reach` + `growth_weight` × the path it adds. Walls
# (reach 0) only count if they add path.
func _best_cell(reach: float, growth_weight: float) -> Vector2:
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var enemy_cells := PackedVector2Array()
	for enemy in spawner.get_maze_walkers():
		enemy_cells.append(enemy.get_target_cell())
	var best := NO_CELL
	var best_score := 0.0 if reach <= 0.0 else -INF
	for y in Tower.MAP_GRID.size.y:
		for x in Tower.MAP_GRID.size.x:
			var cell := Vector2(x, y)
			if not map.is_buildable(cell) or placer.settling_left([cell]) > 0.0 or placer._cells_occupied([cell]):
				continue
			var new_route: PackedVector2Array = map.get_path_if_blocked_cells([cell])
			if new_route.is_empty() or not map.can_block_cells([cell], enemy_cells):
				continue
			var cover := 0
			if reach > 0.0:
				for at in new_route:
					if at.distance_to(cell) <= reach:
						cover += 1
			var score := cover + growth_weight * (new_route.size() - route.size())
			if score > best_score:
				best_score = score
				best = cell
	return best

func _coverage(tower: Tower) -> int:
	var reach := tower.get_range_cells()
	var count := 0
	for at in map.get_path_from(map.startPath):
		if at.distance_to(tower.cell) <= reach:
			count += 1
	return count

# Grow the Warden with the most path in range (spec), into its first unlocked form it can afford.
func _grow() -> bool:
	var best: Array = []
	for tower in _attackers():
		if style == "sprout" and tower.tower_data.get_id() == "sprout":
			continue  # The swarm stays Sprouts
		for form in tower.tower_data.evolves_to:
			if not (form is TowerData) or not dreams.is_unlocked(form.get_id()) or placer.ascended_blocker(form) != "":
				continue
			if form.footprint > tower.get_footprint() and placer.get_grow_squares(tower, form).is_empty():
				continue
			if tower.get_grow_cost(form).total > run_state.dew:
				continue
			var cover := _coverage(tower)
			if best.is_empty() or cover > best[0]:
				best = [cover, tower, form]
			break
	return not best.is_empty() and placer.evolve(best[1], best[2])

# Balanced: the lowest rank first, most path in range among those; Narrow the same but it plants few.
func _nurture() -> bool:
	var towers := _attackers().filter(func(t) -> bool: return t.can_nurture() and t.get_nurture_cost() <= run_state.dew)
	if towers.is_empty():
		return false
	towers.sort_custom(func(a, b) -> bool:
		return a.rank < b.rank or (a.rank == b.rank and _coverage(a) > _coverage(b)))
	var tower: Tower = towers[0]
	return placer.nurture(tower, Tower.Focus.POWER if tower.needs_focus() else Tower.Focus.NONE)

func _family_count(base: TowerData) -> int:
	return _attackers().filter(func(t) -> bool: return t.tower_data.line == base.line).size()

# --- Recording -----------------------------------------------------------------------------------------

func _hook_stats() -> void:
	if DamageLog.instance:
		DamageLog.instance.damage_dealt.connect(_on_damage)
	spawner.child_entered_tree.connect(func(n) -> void:
		if n.has_method("take_damage"):
			(func() -> void: d.health_spawned += n.max_health).call_deferred())
	spawner.enemy_reached_goal.connect(func(_e) -> void:
		d.leaks += 1
		if run.first_leak == 0:
			run.first_leak = maxi(director.drifts_started, 1))
	if spawner.has_signal("nightmare_restless"):
		spawner.nightmare_restless.connect(func(_e, _stacks) -> void: d.restless += 1)
	if spawner.has_signal("wall_trampled"):
		spawner.wall_trampled.connect(func(_cell, _by) -> void: d.trampled += 1)
	run_state.leaves_changed.connect(func(leaves: int, _max: int) -> void: d.leaves_left = leaves)
	run_state.dew_changed.connect(func(dew: int) -> void:
		var delta := dew - _last_dew
		_last_dew = dew
		if delta > 0:
			d.dew_other += delta)  # Rest bonuses are moved out of this in _close_window
	director.drift_cleared.connect(func(n, _b, _p) -> void: _close_window(n))

func _new_window() -> void:
	d = {"start": game_time, "health_spawned": 0.0, "damage": 0.0, "leaks": 0, "leaves_left": run_state.leaves,
		"leaves_before": run_state.leaves, "dew_rest": 0, "dew_other": 0, "spent_plant": 0, "spent_walls": 0,
		"spent_grow": 0, "spent_nurture": 0, "by_tower": {}, "asleep": 0.0, "reaction": 0.0, "crit": 0.0,
		"restless": 0, "trampled": 0}

func _on_damage(event) -> void:
	d.damage += event.amount
	d.by_tower[event.source_name] = d.by_tower.get(event.source_name, 0.0) + event.amount
	if reaction_tags.has(event.tag):
		d.reaction += event.amount
	if event.crit_multiplier > 1.0:
		d.crit += event.amount
	var e = event.enemy
	if is_instance_valid(e) and (e.statuses.is_asleep() or (e.statuses.has(EnemyStatuses.DROWSY)
			and e.statuses.stacks(EnemyStatuses.DROWSY) >= e.statuses.get_max_stacks(EnemyStatuses.DROWSY))):
		d.asleep += event.amount

func _close_window(n: int) -> void:
	var tiers := [0, 0, 0, 0, 0]
	var ranks := 0
	var lines := {}
	for t in _attackers():
		tiers[clampi(t.tower_data.tier, 0, 4)] += 1
		ranks += t.rank
		lines[t.tower_data.line] = true
	var top := ""
	var top_amount := 0.0
	for name in d.by_tower:
		if d.by_tower[name] > top_amount:
			top_amount = d.by_tower[name]
			top = name
	var damage := maxf(d.damage, 1.0)

	var row := {"drift": n, "act": director.get_act(n), "seconds": snappedf(game_time - d.start, 0.1),
		"health_spawned": roundi(d.health_spawned), "damage": roundi(d.damage), "leaks": d.leaks,
		"leaves_lost": run_state.leaves_lost, "leaves_left": run_state.leaves,
		"dew_rest": d.dew_rest, "dew_other": maxi(d.dew_other - d.dew_rest, 0),
		"spent_plant": d.spent_plant, "spent_walls": d.spent_walls, "spent_grow": d.spent_grow,
		"spent_nurture": d.spent_nurture, "banked": run_state.dew, "attackers": _attackers().size(),
		"walls": _walls().size(), "tier1": tiers[1], "tier2": tiers[2], "tier3": tiers[3], "tier4": tiers[4],
		"avg_rank": snappedf(float(ranks) / maxf(_attackers().size(), 1), 0.1),
		"route": map.get_path_from(map.startPath).size(), "families": lines.size(), "cards": dreams.stacks.size(),
		"dreamlight": dreams.dreamlight, "top_warden": top, "top_share": snappedf(top_amount / damage, 0.001),
		"asleep_share": snappedf(d.asleep / damage, 0.001), "reaction_share": snappedf(d.reaction / damage, 0.001),
		"crit_share": snappedf(d.crit / damage, 0.001), "restless": d.restless, "trampled": d.trampled}
	rows.append(row)
	if n == 25:
		run.sprout_cards_25 = SPROUT_CARDS.filter(func(id: String) -> bool: return dreams.stacks.has(id)).size()
	for mark in run.lost_by:
		if n == mark:
			run.lost_by[mark] = row.leaves_lost
	if n >= 10 and top != "":
		run.top_wardens[top] = run.top_wardens.get(top, 0) + 1
		if row.top_share > run.max_top_share:
			run.max_top_share = row.top_share
			run.max_top_warden = top
	if n >= 10:
		run.max_asleep = maxf(run.max_asleep, row.asleep_share)
	_new_window()

func _finish() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var name := "%s_%s_seed%d" % [profile, style, map_seed]
	var file := FileAccess.open(out_dir.path_join(name + ".csv"), FileAccess.WRITE)
	file.store_line(",".join(COLUMNS))
	for row in rows:
		file.store_line(",".join(COLUMNS.map(func(c: String) -> String: return str(row.get(c, "")))))
	file.close()
	var survived := director.drifts_cleared
	var won := survived >= 100 and run_state.leaves > 0
	var top := ""
	for w in run.top_wardens:
		if top == "" or run.top_wardens[w] > run.top_wardens[top]:
			top = w
	var hoard := 0.0
	var count := 0
	for i in run.rest_banked.size():
		if i >= 5:  # After act 1 (rests 25+)
			hoard += float(run.rest_banked[i]) / maxf(run.rest_bonus[i], 1.0)
			count += 1
	var summary := {"profile": profile, "style": style, "seed": map_seed, "survived": survived, "won": won,
		"first_leak": run.first_leak, "lost_25": run.lost_by[25], "lost_50": run.lost_by[50], "lost_75": run.lost_by[75],
		"bank_act2": run.banked_at_act.get(2, -1), "bank_act3": run.banked_at_act.get(3, -1), "bank_act4": run.banked_at_act.get(4, -1),
		"hoard_rests": snappedf(hoard / maxf(count, 1), 0.01), "top_warden": top, "max_top_share": run.max_top_share,
		"max_top_warden": run.max_top_warden, "max_asleep": snappedf(run.max_asleep, 0.001), "cards": dreams.stacks.size(),
		"sprout_cards_25": run.sprout_cards_25,
		"seconds": snappedf(game_time, 1.0)}
	var runs_path := out_dir.path_join("runs.csv")
	var keys := summary.keys()
	var new_file := not FileAccess.file_exists(runs_path)
	var runs := FileAccess.open(runs_path, FileAccess.READ_WRITE if not new_file else FileAccess.WRITE)
	if new_file:
		runs.store_line(",".join(keys))
	runs.seek_end()
	runs.store_line(",".join(keys.map(func(k) -> String: return str(summary[k]))))
	runs.close()
	print("RUN %s" % JSON.stringify(summary))
	print("CHOICES %s" % " | ".join(policy.choices))
