extends RefCounted
# Synthetic stacks go through Enemy.apply_status directly, never the Warden's native hook.
const STACKABLE: Array[StringName] = [EnemyStatuses.DAMP, EnemyStatuses.DROWSY,
	EnemyStatuses.SPORED, EnemyStatuses.MARKED, EnemyStatuses.STATIC]

static func _live(enemy: Node) -> bool:
	return is_instance_valid(enemy) and not enemy.is_cleansed and not enemy.is_queued_for_deletion()

static func _dreams(tower: Node) -> DreamState:
	return tower._dream_state if is_instance_valid(tower) else null

static func _enabled(dreams: DreamState, id: StringName) -> bool:
	return is_instance_valid(dreams) and dreams.has_rule(id)

static func _line(_source: Node, statuses: EnemyStatuses, id: StringName) -> String:
	return statuses._active.get(id, {}).get("line", "")

static func native_status(tower: Node, enemy: Node, id: StringName, accepted: bool, direct: bool, now: float) -> void:
	if not accepted or not direct or not is_instance_valid(tower) or not tower.tower_data.can_attack or id not in EnemyStatuses.ALL or not _live(enemy) \
			or not _enabled(_dreams(tower), &"corner_sign"):
		return
	var bend: int = enemy.get_meta(&"unique_bend_serial", 0)
	if bend <= 0:
		return
	var ledger: Dictionary = enemy.get_meta(&"unique_corner_sign", {})
	var key: int = tower.get_instance_id()
	var entry: Array = ledger.get(key, [-1, -INF])
	if entry[0] == bend or now - float(entry[1]) < 3.0:
		return
	ledger[key] = [bend, now]
	enemy.set_meta(&"unique_corner_sign", ledger)
	var s: EnemyStatuses = enemy.statuses
	var context: Array = tower.get_meta(&"unique_native_status_context", [s.potency(id), 0.0, 0])
	var extra: int = maxi(int(context[3]), 1) if context.size() > 3 else 1  # Double stacks: as many again as the hit applied (card_review_2026-10-12.md 10)
	enemy.apply_status(id, extra, float(context[1]), float(context[0]), int(context[2]), tower.tower_data.line, tower)

static func target_changed(tower: Node, old_target: Node, new_target: Node, now: float) -> void:
	if old_target == new_target or not _live(old_target) or not _live(new_target) \
			or not _enabled(_dreams(tower), &"passing_thread_carry"):
		return  # (Passing Thread is the second-pass card now, dream_batch_rules.gd; no live card grants this carry rule)
	if now - float(tower.get_meta(&"unique_passing_thread_time", -INF)) < 2.0:
		return
	var donor: EnemyStatuses = old_target.statuses
	var chosen := &""
	for id in STACKABLE:
		if donor.stacks(id) > 0 and (chosen == &"" or donor.stacks(id) > donor.stacks(chosen)):
			chosen = id
	if chosen == &"":
		return
	var remaining := donor.copy_duration(chosen)
	if remaining <= 0.0:
		return
	var source := donor.source(chosen)
	var recipient: EnemyStatuses = new_target.statuses
	# apply_status applies resistance and potency duration factors again. Cancel only extensions,
	# retaining shorter resistant durations while never rejuvenating the donor's application.
	var multiplier: float = recipient.duration_multipliers.get(chosen, 1.0) * recipient.duration_multiplier_all \
		* recipient._potency_stretch(chosen, recipient._applier_potency(source))
	var duration := remaining / maxf(multiplier, 1.0)
	tower.set_meta(&"unique_passing_thread_time", now)
	new_target.apply_status(chosen, 1, duration, donor.potency(chosen), 0, _line(source, donor, chosen), source)

static func caught_exited(dreams: DreamState, enemy: Node, catcher: Node, now: float) -> void:
	if not _live(enemy) or not _enabled(dreams, &"dream_residue"):
		return
	var key: int = catcher.get_instance_id() if is_instance_valid(catcher) else 0
	var ledger: Dictionary = enemy.get_meta(&"unique_dream_residue", {})
	if now - float(ledger.get(key, -INF)) < 3.0:
		return
	ledger[key] = now
	enemy.set_meta(&"unique_dream_residue", ledger)
	var source: Node = catcher if is_instance_valid(catcher) else null
	enemy.apply_status(EnemyStatuses.DROWSY, 2, 0.0, 0.0, 0,
		source.tower_data.line if source is Tower else "", source)

# PullUnder increments age before damage delivery; its final tick remains active until queued free.
static func _active_drown(world: Node, enemy: Node) -> Node:
	if world == null:
		return null
	for child in world.get_children():
		if child is Reactions.PullUnder and child.enemy == enemy \
				and not child.is_queued_for_deletion():
			return child
		var found := _active_drown(child, enemy)
		if found != null:
			return found
	return null

static func dispelled(dreams: DreamState, enemy: Node, _now: float) -> void:
	if not is_instance_valid(enemy) or not enemy.is_inside_tree() or not _enabled(dreams, &"wake_ripple"):
		return
	var under := _active_drown(Reactions._world(enemy), enemy)
	if under == null:
		return
	var reach: float = enemy.grid.cell_size.x
	var nearby: Array = []
	for other in enemy.get_tree().get_nodes_in_group("enemies"):
		if other != enemy and _live(other) and enemy.global_position.distance_to(other.global_position) <= reach:
			nearby.append(other)
	nearby.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		var da: float = enemy.global_position.distance_squared_to(a.global_position)
		var db: float = enemy.global_position.distance_squared_to(b.global_position)
		return da < db if not is_equal_approx(da, db) else a.get_instance_id() < b.get_instance_id())
	var source: Node = under.applier if is_instance_valid(under.applier) else null
	for i in mini(nearby.size(), 3):
		nearby[i].apply_status(EnemyStatuses.DAMP, 2, 0.0, 0.0, 0,
			source.tower_data.line if source is Tower else "", source)

static func harmony(dreams: DreamState, a: Node, b: Node, enemy: Node, drift: int) -> void:
	if true:
		return  # Kin's Keepsake now pays at the rest (DreamState.get_rest_bonus_add); the per-Harmony Dew is gone
	if not _enabled(dreams, &"kins_keepsake") or not is_instance_valid(a) or not is_instance_valid(b) or a == b \
			or not is_instance_valid(enemy) or dreams.run_state == null:
		return
	var ledger: Dictionary = dreams.get_meta(&"unique_kins_keepsake", {})
	if int(ledger.get("drift", -1)) != drift:
		ledger = {"drift": drift, "pairs": {}, "paid": 0}
	var low: int = mini(a.get_instance_id(), b.get_instance_id())
	var high: int = maxi(a.get_instance_id(), b.get_instance_id())
	var key := "%d:%d" % [low, high]
	if ledger.pairs.has(key) or int(ledger.paid) >= 6:
		return
	ledger.pairs[key] = true
	ledger.paid += 1
	dreams.set_meta(&"unique_kins_keepsake", ledger)
	dreams.run_state.earn_dew_at(1, enemy.global_position)
