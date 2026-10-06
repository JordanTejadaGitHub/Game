extends SceneTree

# Headless test for "Potency: effect damage and status strength" (tower_design.md, 2026-10-01): Soaked,
# Exposed, Drowsy and Rooted scale with their strongest applier's Potency (caps +40% / +40% / the slow
# floors / 2 s), never a sum; Tower.status_potency_on false = the old rules. Run from the project folder:
#   godot --headless --path . --script res://tests/test_status_potency.gd --fixed-fps 60

var failures := 0
var _made: Array = []

func _initialize() -> void:
	Tower.status_potency_on = true
	var weak := _warden(1.0)
	var strong := _warden(1.5)
	var mighty := _warden(3.0)

	# Soaked: water hits +20% × Potency, at most +40%.
	var s := EnemyStatuses.new()
	s.apply(EnemyStatuses.DAMP, 1, 0.0, 1.0, 0, "water", strong)
	_check(is_equal_approx(s.soaked_bonus(EnemyStatuses.DAMP_WATER_BONUS), 0.30), "Soaked at Potency 1.5: water hits +30%% (%.2f)" % s.soaked_bonus(0.2))
	s.apply(EnemyStatuses.DAMP, 1, 0.0, 1.0, 0, "water", weak)
	_check(is_equal_approx(s.strength(EnemyStatuses.DAMP), 1.5), "the strongest applier counts, never a sum or the latest")
	s.apply(EnemyStatuses.DAMP, 1, 0.0, 1.0, 0, "water", mighty)
	_check(is_equal_approx(s.soaked_bonus(EnemyStatuses.DAMP_WATER_BONUS), EnemyStatuses.SOAKED_CAP), "capped at +40%")

	# Exposed: +25% × Potency, at most +40%.
	var m := EnemyStatuses.new()
	m.apply(EnemyStatuses.MARKED, 1, 0.0, 1.0, 0, "", strong)
	_check(is_equal_approx(m.get_damage_taken_multiplier(), 1.375), "Exposed at Potency 1.5: +37.5%% (%.3f)" % m.get_damage_taken_multiplier())
	m.apply(EnemyStatuses.MARKED, 1, 0.0, 1.0, 0, "", mighty)
	_check(is_equal_approx(m.get_damage_taken_multiplier(), 1.0 + EnemyStatuses.EXPOSED_CAP), "capped at +40%")

	# Drowsy (rule 3, warden_stats.md b6f44fac): −8% a stack whatever the Potency; Potency lengthens it instead.
	var d := EnemyStatuses.new()
	d.apply(EnemyStatuses.DROWSY, 2, 0.0, 1.0, 0, "", strong)
	_check(is_equal_approx(d.get_speed_multiplier(), 1.0 - 2 * 0.08), "2 Drowsy at Potency 1.5: still −16%% (%.2f)" % d.get_speed_multiplier())
	var base_time: float = EnemyStatuses.DEFAULT_DURATION[EnemyStatuses.DROWSY]
	_check(is_equal_approx(d.time_left(EnemyStatuses.DROWSY), base_time * strong.get_potency()),
		"and lasts ×1.5 (%.2f s)" % d.time_left(EnemyStatuses.DROWSY))
	d.apply(EnemyStatuses.DROWSY, 3, 0.0, 1.0, 0, "", mighty)
	_check(d.time_left(EnemyStatuses.DROWSY) >= base_time * mighty.get_potency() - 0.001, "a stronger applier lengthens it further")

	# Rooted: its length × Potency, at most 2 s.
	var h := EnemyStatuses.new()
	h.apply(EnemyStatuses.HELD, 1, 1.0, 0.0, 0, "", strong)
	_check(is_equal_approx(h.time_left(EnemyStatuses.HELD), 1.5), "a 1 s Hold at Potency 1.5 lasts 1.5 s (%.2f)" % h.time_left(EnemyStatuses.HELD))
	var h2 := EnemyStatuses.new()
	h2.apply(EnemyStatuses.HELD, 1, 1.0, 0.0, 0, "", mighty)
	_check(is_equal_approx(h2.time_left(EnemyStatuses.HELD), EnemyStatuses.HELD_POTENCY_CAP), "capped at 2 s")

	# The panel line next to crit.
	_check(WardenHeaderView.status_strength_text(EnemyStatuses.DAMP, 1.2) == "Soaked: water hits +24%", "the panel's Soaked line")
	_check(WardenHeaderView.status_strength_text(EnemyStatuses.HELD, 1.3, 1.0) == "Rooted 1.3 s", "the panel's Rooted line")
	_check(Tower.FOCUS_TEXT[Tower.Focus.DEEP].begins_with("+25% Potency"), "Deep is only +25% Potency")

	# Off: the old rules (for Balancing's A/B).
	Tower.status_potency_on = false
	_check(is_equal_approx(s.soaked_bonus(EnemyStatuses.DAMP_WATER_BONUS), EnemyStatuses.DAMP_WATER_BONUS), "off: Soaked +20%")
	_check(is_equal_approx(m.get_damage_taken_multiplier(), 1.25), "off: Exposed +25%")
	var h3 := EnemyStatuses.new()
	h3.apply(EnemyStatuses.HELD, 1, 1.0, 0.0, 0, "", mighty)
	_check(is_equal_approx(h3.time_left(EnemyStatuses.HELD), 1.0), "off: a 1 s Hold stays 1 s")
	_check(WardenHeaderView.status_strength_text(EnemyStatuses.DAMP, 1.2) == "", "off: no panel line")
	Tower.status_potency_on = true

	for node in _made:
		node.free()
	print("status potency test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

# A Warden (never in the tree) whose Potency is `potency`.
func _warden(potency: float) -> Tower:
	var tower := Tower.new()
	var data := TowerData.new()
	data.potency = potency
	tower.tower_data = data
	tower.attack_data = data
	_made.append(tower)
	return tower

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
