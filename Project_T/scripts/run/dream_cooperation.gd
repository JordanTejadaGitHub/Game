extends RefCounted
## Cooperative successor effects. Only native hooks record application history.

static func before_hit(tower, enemy, direct: bool, now: float) -> float:
	if not direct or not _live(tower) or not _enemy_live(enemy):
		return 1.0
	var multiplier := 1.0
	var hits: Dictionary = enemy.get_meta("unique_direct_hits", {})
	if _rule(tower, &"crosswind") and tower.attack_data.attack_kind == TowerData.AttackKind.BOOMERANG:
		var serial: int = tower.get_meta("unique_throw_serial", -1)
		var throws: Dictionary = enemy.get_meta("unique_crosswind_throws", {})
		var throw_key := "%d:%d" % [tower.get_instance_id(), serial]
		if serial >= 0 and not throws.has(throw_key):
			for key in hits:
				var entry: Dictionary = hits[key]
				if key != tower.get_instance_id() and _live(entry.source.get_ref()) and now - entry.time <= 1.0:
					multiplier *= 1.25
					throws[throw_key] = true
					enemy.set_meta("unique_crosswind_throws", throws)
					break
	var primer: Dictionary = enemy.get_meta("unique_fracture_primer", {})
	if _rule(tower, &"opening_fracture") and not primer.is_empty():
		var source = primer.source.get_ref()
		if now > primer.until or not _live(source):
			enemy.remove_meta("unique_fracture_primer")
		elif source != tower:
			multiplier *= 1.4
			enemy.remove_meta("unique_fracture_primer")
			enemy.set_meta("unique_fracture_cooldown", now + 3.0)
			enemy.set_meta("unique_fracture_payoff", {"source": tower.get_instance_id(), "time": now})
	var root: Dictionary = enemy.get_meta("unique_afterroot_ready", {})
	if _rule(tower, &"afterroot") and not root.is_empty():
		var source = root.source.get_ref()
		if now > root.until or not _live(source):
			enemy.remove_meta("unique_afterroot_ready")
		elif source != tower:
			enemy.remove_meta("unique_afterroot_ready")
			enemy.set_meta("unique_afterroot_cooldown", now + 4.0)
			enemy.apply_status(EnemyStatuses.MARKED, 2, 0.0, 0.0, 0, tower.tower_data.line, tower)
	return multiplier

static func after_hit(tower, enemy, is_crit: bool, direct: bool, now: float) -> void:
	if not direct or not _live(tower) or not _enemy_live(enemy):
		return
	var hits: Dictionary = enemy.get_meta("unique_direct_hits", {})
	for key in hits.keys():
		if now - hits[key].time > 1.0 or not _live(hits[key].source.get_ref()):
			hits.erase(key)
	hits[tower.get_instance_id()] = {"source": weakref(tower), "time": now}
	enemy.set_meta("unique_direct_hits", hits)
	var payoff: Dictionary = enemy.get_meta("unique_fracture_payoff", {})
	if payoff.get("source", 0) == tower.get_instance_id() and payoff.get("time", -1.0) == now:
		enemy.remove_meta("unique_fracture_payoff")
		return
	if is_crit and _rule(tower, &"opening_fracture") and now >= float(enemy.get_meta("unique_fracture_cooldown", -1.0)):
		enemy.set_meta("unique_fracture_primer", {"source": weakref(tower), "until": now + 2.0})

static func native_status(tower, enemy, id: StringName, accepted: bool, was_present: bool, now: float) -> void:
	if not _live(tower) or not _enemy_live(enemy):
		return
	var rule: StringName = &"shared_mycelium" if id == EnemyStatuses.SPORED else &"crossed_sparks" if id == EnemyStatuses.STATIC else &""
	if rule == &"" or not _rule(tower, rule):
		return
	var key := "unique_native_" + String(id)
	var history: Dictionary = enemy.get_meta(key, {})
	var serial: int = enemy.statuses.lifecycle_serial(id) if enemy.statuses.has_method("lifecycle_serial") else 0
	if not was_present or not enemy.statuses.has(id) or int(history.get("serial", serial)) != serial:
		history.clear()
	if not accepted or not enemy.statuses.has(id):
		enemy.set_meta(key, history)
		return
	var native_batch: Array = []
	if id == EnemyStatuses.SPORED:
		for i in range(enemy.statuses._spore_batches.size() - 1, -1, -1):
			var batch: Array = enemy.statuses._spore_batches[i]
			if batch[2] == tower:
				native_batch = batch
				break
	var entries: Dictionary = history.get("entries", {})
	for source_id in entries.keys():
		var entry: Dictionary = entries[source_id]
		if now - entry.time > 2.0 or not _live(entry.source.get_ref()) or (id == EnemyStatuses.SPORED and not _has_spore_batch(enemy.statuses, entry.get("batch", []))):
			entries.erase(source_id)
	var partner := false
	for source_id in entries:
		if source_id != tower.get_instance_id():
			partner = true
	var cooldown_key := key + "_cooldown"
	if partner and now >= float(enemy.get_meta(cooldown_key, -1.0)):
		enemy.set_meta(cooldown_key, now + 2.0)
		# Enemy.apply_status owns ordinary caps, immunity, reactions and Brimming.
		var original_source = enemy.statuses.source(id)
		var scale: float = enemy.statuses.duration_multipliers.get(id, 1.0) * enemy.statuses.duration_multiplier_all * enemy.statuses._potency_stretch(id, enemy.statuses._applier_potency(original_source))
		var duration: float = enemy.statuses.time_left(id) / maxf(scale, 0.0001)
		enemy.apply_status(id, 2, duration, enemy.statuses.potency(id), 0,
			original_source.tower_data.line if _live(original_source) else tower.tower_data.line, original_source)
	entries[tower.get_instance_id()] = {"source": weakref(tower), "time": now, "batch": native_batch}
	enemy.set_meta(key, {"serial": serial, "entries": entries} if enemy.statuses.has(id) else {})

static func hold_expired(dreams, enemy, source, now: float) -> void:
	if dreams == null or not dreams.has_rule(&"afterroot") or not _enemy_live(enemy) or not _live(source):
		return
	if now < float(enemy.get_meta("unique_afterroot_cooldown", -1.0)):
		return
	enemy.set_meta("unique_afterroot_ready", {"source": weakref(source), "until": now + 2.0})

static func _rule(tower, rule: StringName) -> bool:
	return tower._dream_state != null and tower._dream_state.has_rule(rule)

static func _live(tower) -> bool:
	return is_instance_valid(tower) and tower is Tower and not tower.is_queued_for_deletion() and tower.is_inside_tree()

static func _enemy_live(enemy) -> bool:
	return is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and not enemy.is_cleansed




static func _has_spore_batch(statuses, recorded: Array) -> bool:
	for batch in statuses._spore_batches:
		if is_same(batch, recorded) and batch[0] > 0.0 and batch[1] > 0:
			return true
	return false
