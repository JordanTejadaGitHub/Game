extends SceneTree

# Headless test for random drifts (run_design.md "Random drifts", DriftRoller): same seed → same
# drifts, budgets within ±5%, nightmares only after their intro, fixed drifts untouched, and the
# fairness rules over 200 seeds.
#   godot --headless --path . --script res://tests/test_drift_roller.gd --fixed-fps 60

const SEEDS := 200

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 777
	root.add_child(main)
	await process_frame
	var director: DriftDirector = main.get_node("%DriftDirector")
	# The hook: with random_drifts on (the default), DriftDirector rolled the run from the map seed,
	# and rolling that seed again (a resumed run) gives the same drifts.
	await process_frame
	var rolled_any := false
	for n in range(6, director.drifts.size() + 1):
		rolled_any = rolled_any or DriftRoller.template_of(director, n) != &""
	_check(director.random_drifts and rolled_any, "DriftDirector rolls the drifts at startup")
	var at_start := _describe(director)
	director._roll_drifts()
	_check(_describe(director) == at_start, "rolling the run's seed again (a resume) gives the same drifts")
	DriftRoller.restore(director)
	var hand_made: Array = director.drifts.duplicate()
	_check(DriftRoller.get_roster().size() == 19, "19 rollable nightmare types (%d)" % DriftRoller.get_roster().size())
	_check(DriftRoller.get_templates().size() == 7, "7 templates")

	# Same seed, same drifts; another seed, other drifts.
	DriftRoller.roll_run(director, 1234)
	var first := _describe(director)
	DriftRoller.roll_run(director, 1234)
	_check(_describe(director) == first, "the same seed rolls the same drifts")
	DriftRoller.roll_run(director, 99)
	_check(_describe(director) != first, "another seed rolls other drifts")

	# The rules, over many seeds.
	var rolled_total := 0
	var fallbacks := 0
	var fallback_drifts := {}  # drift -> seeds that fell back
	var template_counts := {}
	var bad := {"budget": 0, "intro": 0, "fixed": 0, "cap": 0, "flyers": 0, "limited": 0, "repeat": 0, "leans": 0, "density": 0, "leaves_cap": 0}
	var phantoms_by_drift := {}  # Drift -> Phantoms over all seeds
	for seed in SEEDS:
		DriftRoller.roll_run(director, seed + 1)
		var previous := &""
		var block_limited := {}
		var block_leans := {}
		for n in range(1, director.drifts.size() + 1):
			var drift: DriftData = director.drifts[n - 1]
			var original: DriftData = hand_made[n - 1]
			var template := DriftRoller.template_of(director, n)
			if not DriftRoller.is_rollable(director, n):
				if drift != original:
					bad.fixed += 1
				previous = &""
				continue
			if template == &"":
				fallbacks += 1  # Nothing fitted: the hand-made drift stays (allowed, but should be rare)
				fallback_drifts[n] = fallback_drifts.get(n, 0) + 1
				previous = &""
				continue
			rolled_total += 1
			template_counts[template] = template_counts.get(template, 0) + 1
			var budget := DriftRoller.get_budget(original)
			var total := 0.0  # The rolled part: the hand-made elites the roller keeps come last
			var weight := 0.0  # …in budget weight (the Phantom ×4)
			var resisted := {}
			var all_flyers := true
			var entries: Array = drift.groups[0].entries
			var rolled_entries := entries.size() - _elite_entries(original)
			for i in entries.size():
				var entry: DriftEntry = entries[i]
				if entry.enemy.intro_drift <= 0 or entry.enemy.intro_drift >= n:
					if not entry.elite or not _in(original, entry.enemy):
						bad.intro += 1
				if i >= rolled_entries:
					continue
				var cost := entry.count * entry.enemy.get_roll_cost() * (DriftRoller.ELITE_COST if entry.elite else 1.0)
				total += cost
				weight += entry.count * entry.enemy.get_roll_weight() * (DriftRoller.ELITE_COST if entry.elite else 1.0)
				for family in entry.enemy.resists:
					resisted[family] = resisted.get(family, 0.0) + cost
				if entry.enemy.trait_kind != EnemyData.Trait.FLYING:
					all_flyers = false
			var rolled_budget := weight
			var rolled_leaves := DriftRoller.get_leaves(_rolled_slots(drift, entries.size() - _elite_entries(original)))
			var hand_leaves := DriftRoller.get_leaves(DriftRoller._slots_of(original, false))
			if rolled_leaves > maxi(ceili(hand_leaves * DriftRoller.LEAVES_SCALE), hand_leaves + DriftRoller.LEAVES_EXTRA):
				bad.leaves_cap += 1
			for entry in entries:
				if entry.enemy.is_through_walls() and not entry.elite:
					phantoms_by_drift[n] = phantoms_by_drift.get(n, 0) + entry.count
			if absf(rolled_budget - budget) > budget * DriftRoller.BUDGET_TOLERANCE + 0.01:
				bad.budget += 1
			if all_flyers:
				bad.flyers += 1
			var cap := DriftRoller.RESIST_CAP_ACT1 if director.get_act(n) <= 1 else DriftRoller.RESIST_CAP
			var block: int = director.get_block(n)
			for family in resisted:
				var share: float = resisted[family] / total
				if share > cap + 0.0001:
					bad.cap += 1
				if share > DriftRoller.LEAN_SHARE and director.get_act(n) >= 2:
					var key := "%d/%s" % [block, family]
					block_leans[key] = block_leans.get(key, 0) + 1
					if block_leans[key] > DriftRoller.MAX_LEANS:
						bad.leans += 1
			if director.get_act(n) <= 1:  # Act 1 density cap
				var small := 0
				for entry in entries:
					if &"small" in entry.enemy.roll_tags:
						small += entry.count
				if template == &"swarm" and small > DriftRoller.ACT1_SWARM_MAX:
					bad.density += 1
				if template != &"swarm" and small > 0 and drift.groups[0].spacing < DriftRoller.ACT1_SMALL_GAP - 0.0001:
					bad.density += 1
			if template in [&"swarm", &"special"]:
				if block_limited.has(block):
					bad.limited += 1
				block_limited[block] = true
			if template == previous:
				bad.repeat += 1
			previous = template
	for n in [28, 29, 30]:
		var average: float = phantoms_by_drift.get(n, 0) / float(SEEDS)
		_check(average <= 8.0, "drift %d: Phantoms stay near the hand-made count (%.1f on average)" % [n, average])
	for rule in bad:
		_check(bad[rule] == 0, "over %d seeds, rule '%s' holds (%d breaks)" % [SEEDS, rule, bad[rule]])
	_check(fallbacks <= rolled_total / 50, "hand-made fallbacks stay rare (%d of %d)" % [fallbacks, rolled_total + fallbacks])
	for id in [&"mixed", &"swarm", &"heavy", &"fast", &"procession", &"special", &"elite_hunt"]:
		_check(template_counts.get(id, 0) > 0, "template %s gets rolled (%d)" % [id, template_counts.get(id, 0)])
	print("  %d rolled drifts over %d seeds; templates %s" % [rolled_total, SEEDS, template_counts])
	if not fallback_drifts.is_empty():
		print("  fallbacks by drift: %s" % fallback_drifts)

	# Omens still apply on top: a rolled drift's schedule scales with the count multiplier.
	DriftRoller.roll_run(director, 5)
	var sample := 0
	for n in range(6, director.drifts.size() + 1):
		if DriftRoller.template_of(director, n) != &"":
			sample = n
			break
	if sample > 0:
		var plain: int = director.drifts[sample - 1].get_schedule().size()
		var doubled: int = director.drifts[sample - 1].get_schedule(2.0).size()
		_check(doubled > plain, "Omens scale rolled drifts too (%d → %d)" % [plain, doubled])
		_check(DriftRoller.template_name(director, sample) != "", "a rolled drift names its template")
	DriftRoller.restore(director)
	_check(director.drifts[29] == hand_made[29], "restore puts the hand-made drifts back")

	print("drift roller test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

# A short text of every drift's kinds and counts (for comparing rolls).
func _describe(director: DriftDirector) -> String:
	var parts: Array[String] = []
	for drift in director.drifts:
		for group in drift.groups:
			for entry in group.entries:
				parts.append("%s%d%s" % [entry.enemy.resource_path.get_file(), entry.count, "E" if entry.elite else ""])
		parts.append("|")
	return "".join(parts)

func _elite_entries(drift: DriftData) -> int:
	var count := 0
	for group in drift.groups:
		for entry in group.entries:
			if entry.elite and entry.enemy != null and not entry.enemy.is_boss:
				count += 1
	return count

func _in(drift: DriftData, data: EnemyData) -> bool:
	for group in drift.groups:
		for entry in group.entries:
			if entry.enemy == data:
				return true
	return false

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

# The rolled entries (before the kept hand-made elites) as [[EnemyData, count, elite], …].
func _rolled_slots(drift: DriftData, rolled_entries: int) -> Array:
	var slots := []
	for i in rolled_entries:
		var entry: DriftEntry = drift.groups[0].entries[i]
		slots.append([entry.enemy, entry.count, entry.elite])
	return slots
