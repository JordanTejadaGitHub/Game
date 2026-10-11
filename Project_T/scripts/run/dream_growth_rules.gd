extends RefCounted
# Distinct successors to the rest, leak, wall and idle II cards.
var plant_order := 0
var rest_serial := 0
var emergency_block := -1
func planted(_dreams: DreamState, tower: Tower) -> void:
	plant_order += 1
	tower.set_meta(&"unique_plant_order", plant_order)
	tower.set_meta(&"unique_plant_rest", rest_serial)
func rest(dreams: DreamState, excluded: Array) -> void:
	if dreams.has_rule(&"fresh_beginnings"):
		var newest: Tower = null
		for tower: Tower in dreams._towers():
			if not tower.tower_data.can_attack or not tower.can_nurture() or excluded.has(tower):
				continue
			if int(tower.get_meta(&"unique_plant_rest", -1)) != rest_serial:
				continue
			if DreamState.ranks_with_banked(tower) >= mini(DreamState.FREE_RANK_MAX, dreams.get_max_rank_for(tower)):
				continue
			if newest == null or int(tower.get_meta(&"unique_plant_order", 0)) > int(newest.get_meta(&"unique_plant_order", 0)):
				newest = tower
		if newest != null:
			newest.bank_rank()
			dreams._credit("fresh_beginnings", "dew", float(Tower.RANK_COSTS[mini(newest.rank + newest.banked_ranks - 1, Tower.RANK_COSTS.size() - 1)]))
			dreams.sunlit_granted.emit([newest])
	rest_serial += 1
func actual_leak(dreams: DreamState, lost: int) -> void:
	if lost <= 0 or not dreams.has_rule(&"emergency_reserves"):
		return
	var drift: int = dreams.drift_director.drifts_started if dreams.drift_director != null else 1
	var block := maxi(drift - 1, 0) / 5
	if emergency_block == block:
		return
	emergency_block = block
	dreams.run_state.add_dew(8)
	dreams._credit("emergency_reserves", "dew", 8.0)
func wall(dreams: DreamState, tower: Tower, enemy: Node2D, drift: int) -> void:
	if not dreams.has_rule(&"hushed_hedge") or not is_instance_valid(enemy) or enemy.is_cleansed or enemy.is_flying():
		return
	if int(tower.get_meta(&"unique_hedge_drift", -1)) == drift:
		return
	tower.set_meta(&"unique_hedge_drift", drift)
	var added := tower._wall_drowsy_room(enemy, 2)
	if added > 0:
		enemy.apply_status(EnemyStatuses.DROWSY, added, 0.0, 1.0, 0, tower.tower_data.line, tower)
		SupportLog.credit(tower, &"drowsy", added)
func update_idle(tower: Tower, delta: float) -> void:
	if tower._dream_state == null or not tower._has_rule(&"quiet_vigil") or bool(tower.get_meta(&"unique_vigil_ready", false)):
		return
	var idle := float(tower.get_meta(&"unique_vigil_idle", 0.0))
	idle = 0.0 if tower.has_enemy_in_range() else idle + delta
	tower.set_meta(&"unique_vigil_idle", idle)
	if idle >= 5.0:
		tower.set_meta(&"unique_vigil_ready", true)
func before_primary(tower: Tower, enemy: Node2D, direct: bool) -> void:
	if not direct or tower._dream_state == null or not tower._has_rule(&"quiet_vigil") \
			or not bool(tower.get_meta(&"unique_vigil_ready", false)) or not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	tower.set_meta(&"unique_vigil_ready", false)
	tower.set_meta(&"unique_vigil_idle", 0.0)
	enemy.apply_status(EnemyStatuses.MARKED, 3, 0.0, 0.0, 0, tower.tower_data.line, tower)
func to_save() -> Dictionary:
	return {"plant_order": plant_order, "rest_serial": rest_serial, "emergency_block": emergency_block}
func load_save(data: Dictionary) -> void:
	plant_order = int(data.get("plant_order", 0))
	rest_serial = int(data.get("rest_serial", 0))
	emergency_block = int(data.get("emergency_block", -1))