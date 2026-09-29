extends SceneTree

# Headless check of enemy_design.md's act 1 rule: no drift in 1–25 may have more than ~40% of its
# health resistant to one damage type the player can own by then (balance sim 2026-09-28: drift 20's
# all-Mourner Wake wiped one-family Sporeling boards). Health per arrival = the kind's health (×3
# elite) plus what it
# splits into / brings (followers), each counted against its own resistances; counts as scheduled
# (DriftEntry.get_count with the difficulty's extra nightmares). Bosses (drift 25) are left out:
# their resistances are the fight.
#   godot --headless --path . --script res://tests/test_drift_resist_share.gd

const DRIFT_DIR := "res://resource/drift/demo/"
const MAX_SHARE := 0.40
# Only damage types a player can own by then count (the design chat, option a): in act 1 the
# starting three families' types. Plain never counts. Grove families join later acts.
const OWNABLE_ACT_1 := ["spore", "water", "light"]
const EXTRA_FROM := 10  # DriftDirector.extra_nightmares_from
const EXTRA := 1.25  # DriftDirector.extra_nightmares

var failures := 0

func _initialize() -> void:
	for number in range(1, 26):
		var drift := load(DRIFT_DIR + "drift_%02d.tres" % number) as DriftData
		if drift == null:
			_check(false, "drift %d loads" % number)
			continue
		var shares := resist_shares(drift, EXTRA if number >= EXTRA_FROM else 1.0)
		for line in shares:
			if not OWNABLE_ACT_1.has(line):
				continue  # No family of this type can be owned yet (e.g. Stone in act 1)
			_check(shares[line] <= MAX_SHARE, "drift %d: %d%% of its health resists %s (max %d%%)" % [number,
				roundi(shares[line] * 100.0), IconInfo.damage_type_name(line), roundi(MAX_SHARE * 100.0)])
	print("drift resist share test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

# {damage line: share of the drift's (non-boss) health that resists it}.
static func resist_shares(drift: DriftData, extra: float) -> Dictionary:
	var total := 0.0
	var resisted := {}
	for group in drift.groups:
		for entry in group.entries:
			if entry.enemy == null or entry.enemy.is_boss:
				continue
			var count: int = entry.get_count(1.0, 1.0, extra)
			for part in _parts(entry.enemy, 3.0 if entry.elite else 1.0):
				var health: float = part[1] * count
				total += health
				for line in part[0].resists:
					resisted[line] = resisted.get(line, 0.0) + health
	var shares := {}
	for line in resisted:
		shares[line] = resisted[line] / maxf(total, 1.0)
	return shares

# [[EnemyData, health], …] for one arrival of `data`: itself, what it splits into, its followers.
static func _parts(data: EnemyData, scale: float) -> Array:
	var parts: Array = [[data, data.health * scale]]
	if data.split_into != null and data.split_count > 0:
		parts.append([data.split_into, data.split_into.health * data.split_count])
	if data.followers != null and data.follower_count > 0:
		parts.append([data.followers, data.followers.health * data.follower_count])
	return parts

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
