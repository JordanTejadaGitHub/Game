extends SceneTree

# Headless test for the Restless Omens (run_design.md "Restless Omens: four Grove Omens"): only with the Grove node
# restless_omens; Swarming Night (×2 count, ×0.6 health), Giants' Walk (×0.5 count, ×2.4 health, +1 leaf a leak; act 2+,
# never a boss block), Brittle Night (×0.75 health, double leaks; never a boss block), Crackling Sky (always Charged, +30%
# speed; once something applies Charged). Never touches the player's saves: the node comes from force_grove.
#   godot --headless --path . --script res://tests/test_restless_omens.gd --fixed-fps 60

const IDS := ["swarming_night", "giants_walk", "brittle_night", "static_sky"]

class FakeLeak extends Node2D:
	func get_leaf_cost() -> int:
		return 1

var failures := 0
var main: Node
var dreams: DreamState
var director: DriftDirector
var omens: OmenDirector
var run_state: RunState

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	dreams = main.get_node("%DreamState")
	director = main.get_node("%DriftDirector")
	omens = main.get_node("%OmenDirector")
	run_state = main.get_node("%RunState")
	dreams.unlock_everything = false
	dreams.unlocked = {"sprout": true, "thornwall": true, "sporeling": true}
	_test_data()
	_test_gates()
	_test_twists()
	OmenDirector.force_grove.clear()
	print("restless omens test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _omen(id: String) -> OmenData:
	for omen in omens.pool:
		if omen.id == id:
			return omen
	_check(false, "Omen %s exists" % id)
	return null

func _test_data() -> void:
	for id in IDS:
		var omen := _omen(id)
		if omen != null:
			_check(omen.requires_grove == "restless_omens" and omen.kind == OmenData.Kind.DOUBLE_EDGED and omen.flavor != "",
				"%s: needs the Restless Omens node, double-edged, has its flavour line" % id)
	var swarm := _omen("swarming_night")
	var giants := _omen("giants_walk")
	var brittle := _omen("brittle_night")
	var sky := _omen("static_sky")
	_check(swarm.count_multiplier == 2.0 and swarm.health_multiplier == 0.6 and swarm.reward_seeds == 5, "Swarming Night: ×2 count, ×0.6 health, +5 Seeds")
	_check(giants.count_multiplier == 0.5 and giants.health_multiplier == 2.4 and giants.leak_add == 1 and giants.reward_dew == 25
		and giants.reward_rare_dreams == 1, "Giants' Walk: ×0.5 count, ×2.4 health, +1 leaf a leak, +25 Dew and a Rare+")
	_check(brittle.health_multiplier == 0.75 and brittle.leak_multiplier == 2.0 and brittle.reward_dew == 45, "Brittle Night: ×0.75 health, double leaks, +45 Dew")
	_check(sky.always_status == EnemyStatuses.STATIC and sky.speed_multiplier == 1.3 and sky.reward_dew == 40, "Crackling Sky: always Charged, +30% speed, +40 Dew")

# The ids offered over many rests for `block`.
func _seen(block: int, rests: int = 60) -> Dictionary:
	var seen := {}
	for i in rests:
		omens._last_offer_ids.clear()
		for omen in omens.make_offer(block):
			seen[omen.id] = true
	return seen

func _test_gates() -> void:
	OmenDirector.force_grove.clear()
	var without := _seen(3)
	_check(not IDS.any(func(id: String) -> bool: return without.has(id)), "without the Grove node none of them is offered (%s)" % [without.keys()])
	OmenDirector.force_grove.assign(["restless_omens"])
	var together := 0  # Brittle Night and Leaf Fall both double leaks: never in one offer
	for i in 200:
		omens._last_offer_ids.clear()
		var ids: Array = omens.make_offer(3).map(func(o: OmenData) -> String: return o.id)
		if ids.has("brittle_night") and ids.has("leaf_fall"):
			together += 1
	_check(together == 0, "Brittle Night and Leaf Fall are never offered together (%d times in 200)" % together)
	var act_one := _seen(3)  # Drifts 11–15
	_check(act_one.has("swarming_night") and act_one.has("brittle_night"), "with it: Swarming Night and Brittle Night in act 1 (%s)" % [act_one.keys()])
	_check(not act_one.has("giants_walk"), "Giants' Walk waits for act 2")
	_check(not act_one.has("static_sky"), "Crackling Sky waits for something that applies Charged")
	dreams.unlocked["firefly_jar"] = true  # Its line applies Charged
	_check(omens.has_charged_source() and _seen(3).has("static_sky"), "…then it can be offered")
	dreams.unlocked.erase("firefly_jar")
	var act_two := _seen(6)  # Drifts 26–30
	_check(act_two.has("giants_walk"), "Giants' Walk from act 2 (%s)" % [act_two.keys()])
	var boss_block := _seen(10)  # Drifts 46–50: the act 2 boss
	_check(not boss_block.has("giants_walk") and not boss_block.has("brittle_night"), "never a boss block for Giants' Walk or Brittle Night (%s)" % [boss_block.keys()])
	omens._last_offer_ids.clear()

func _test_twists() -> void:
	director.drifts_started = 31  # In block 7
	omens.active_block = 7
	omens.active = _omen("swarming_night")
	_check(omens.get_schedule_modifiers(31).get("count") == 2.0 and omens.get_multiplier(31, "health_multiplier") == 0.6,
		"Swarming Night: twice the nightmares at 0.6× health")
	omens.active = _omen("giants_walk")
	var leak := FakeLeak.new()
	var leaves := run_state.leaves
	run_state._on_enemy_reached_goal(leak)
	_check(leaves - run_state.leaves == 2, "Giants' Walk: a 1-leaf leak costs 2 (%d)" % (leaves - run_state.leaves))
	omens.active = _omen("brittle_night")
	leaves = run_state.leaves
	run_state._on_enemy_reached_goal(leak)
	_check(leaves - run_state.leaves == 2 and omens.get_multiplier(31, "health_multiplier") == 0.75, "Brittle Night: 0.75× health, a 1-leaf leak costs 2")
	omens.active = _omen("static_sky")
	var mods := omens.get_spawn_modifiers(31)
	_check(mods.get("always_status") == EnemyStatuses.STATIC and mods.get("speed") == 1.3, "Crackling Sky: always Charged, 30% faster")
	leak.free()
	omens.active = null
	director.drifts_started = 0
	run_state.leaves = run_state.max_leaves

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
