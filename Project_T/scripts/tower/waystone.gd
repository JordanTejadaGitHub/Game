extends Node

# Old Waystone (environment_assets.md "Landmarks", 6fd3dccf): a one-cell Warden standing on the map's Waystone (not a wall,
# not the Sapling) earns DEW_PER_DISPEL for each nightmare it dispels (the killing blow, any of its damage: hits, Poisoned,
# Charged), with the "+1" popping there (RunState.earn_dew_at). Read by position on every dispel, so selling or moving
# the Warden (Walking Wood) frees the stone. One listener per run (on DamageLog.damage_dealt), made by the first Warden
# planted on a map with a Waystone (Tower._ready). MapGenerator's landmark_kind / landmark_cell are Environment Code's.

const GROUP := &"waystone_bonus"
const KIND := &"waystone"  # MapGenerator.landmark_kind for the Old Waystone
const DEW_PER_DISPEL := 1  # Balancing to confirm
const PAID_META := &"waystone_paid"
const PANEL_LINE := "Old Waystone: +1 Dew per dispel"

static func is_waystone_map(map) -> bool:
	return is_instance_valid(map) and str(map.get("landmark_kind")) == String(KIND)

static func _map_of(near: Node) -> Node:
	if not is_instance_valid(near) or not near.is_inside_tree():
		return null
	var dreams := near.get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	return dreams.map_generator if dreams != null else null

# True if `tower` stands on the Waystone now and can earn its Dew.
static func on_stone(tower: Node) -> bool:
	if not (is_instance_valid(tower) and tower is Tower):
		return false
	var map := _map_of(tower)
	if not is_waystone_map(map):
		return false
	var data: TowerData = tower.tower_data
	if data == null or data.line == "wall" or data.footprint > 1 or data.rooted:
		return false
	var at = map.get("landmark_cell")
	return (at is Vector2 or at is Vector2i) and Vector2(at) == tower.cell

# Makes the run's listener once a Warden is planted on a map with a Waystone.
static func ensure(near: Node) -> void:
	if DamageLog.instance == null or not is_waystone_map(_map_of(near)):
		return
	if near.get_tree().get_first_node_in_group(GROUP) != null:
		return
	DamageLog.instance.add_child(load("res://scripts/tower/waystone.gd").new())  # Goes away with the run

func _ready() -> void:
	add_to_group(GROUP)
	var log := get_parent() as DamageLog
	if log != null:
		log.damage_dealt.connect(_on_damage)

# The event that took a nightmare to 0: its Warden on the stone gets the Dew, once per nightmare.
func _on_damage(event) -> void:
	var enemy: Node2D = event.enemy
	if not is_instance_valid(enemy) or enemy.health > 0 or enemy.get_meta(PAID_META, false) or enemy.get("is_echo") == true:
		return
	if not on_stone(event.source):
		return
	enemy.set_meta(PAID_META, true)
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	if dreams != null and dreams.run_state != null:
		dreams.run_state.earn_dew_at(DEW_PER_DISPEL, enemy.global_position)
