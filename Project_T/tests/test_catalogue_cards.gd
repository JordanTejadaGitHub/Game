extends SceneTree

# Headless test for Tower Code's side of the catalogue cards 204–226 (dream_design.md "New cards for the
# catalogue"): Elder Kin, Big Family, Mycelium, Fireflies in the Grass, Spore Kin, Resonance, Thornheart,
# Ill Wind, Eddy, Warm Hearth, Live Wire. Rules are set directly (like test_kinships). Run from the project
# folder:
#   godot --headless --path . --script res://tests/test_catalogue_cards.gd --fixed-fps 60

const CELL := 64.0

var failures := 0
var placer: TowerPlacer
var container: Node
var spawner
var dreams: DreamState

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	placer = main.get_node("%TowerPlacer")
	container = main.get_node("%TowerContainer")
	spawner = main.get_node("%EnemyContainer")
	dreams = main.get_node("%DreamState")
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

	# A Kinship pair to work with (Driftspore + Bloomcap within 2 cells: Slumber Rot).
	var drift := _plant("driftspore", Vector2(4, 4))
	var bloom := _plant("bloomcap", Vector2(6, 4))
	await process_frame
	var kin := Kinships.find(drift)
	kin.refresh()
	_check(kin.get_partner(drift) == bloom, "a Kinship pair to test with")

	# Elder Kin: a ranked kin shares 25% of its ranks.
	bloom.rank = 4
	var court_before := drift.get_court_ranks()
	_rule(&"elder_kin")
	_check(is_equal_approx(drift.get_court_ranks() - court_before, DreamState.ELDER_KIN_SHARE * dreams.rule_power(&"elder_kin") * 4),
		"Elder Kin: +%.2f rank-equivalents from its rank IV kin" % (drift.get_court_ranks() - court_before))

	# Big Family, Warm Hearth, Mycelium, Fireflies: a Sprout beside a Sporeling and a Firefly Jar, near the pair.
	var sprout := _plant("sprout", Vector2(5, 5))
	var spore := _plant("sporeling", Vector2(5, 6))
	var jar := _plant("firefly_jar", Vector2(4, 6))
	var acorn := _plant("acorn", Vector2(6, 6))
	sprout._refresh_neighbours()
	var speed := sprout.get_attacks_per_second()
	var aura := sprout._aura_damage
	_rule(&"big_family")
	_rule(&"warm_hearth")
	sprout._refresh_neighbours()
	sprout.clear_dream_cache()
	_check(sprout._big_family and sprout.get_attacks_per_second() > speed, "Big Family: a Sprout near a Kinship pair attacks faster")
	_check(is_equal_approx(sprout._aura_damage, aura * (1.0 + DreamState.WARM_HEARTH_SPROUTS * dreams.rule_power(&"warm_hearth"))),
		"Warm Hearth: the Acorn's aura +50%% on a Sprout (%.3f)" % sprout._aura_damage)
	_rule(&"fireflies_in_the_grass")
	var target := _spawn(sprout.global_position + Vector2(CELL, 0))
	for i in DreamState.FIREFLIES_EVERY:
		sprout.hit(target, 1.0, false, Tower.NO_CRIT)
	_check(target.statuses.has(EnemyStatuses.STATIC), "Fireflies in the Grass: every 3rd hit adds 1 Charged")
	_rule(&"mycelium")  # (After: its Poisoned plus that Charged would Ignite and use the Charged up)
	var poisoned := _spawn(sprout.global_position + Vector2(0, CELL))
	sprout.hit(poisoned, 1.0, false, Tower.NO_CRIT)
	_check(poisoned.statuses.has(EnemyStatuses.SPORED), "Mycelium: the Sprout's hits poison")
	for t in [spore, jar, acorn]:
		t.queue_free()

	# Spore Kin: the pair's Harmony strike poisons.
	_rule(&"spore_kin")
	var harmony_target := _spawn(drift.global_position + Vector2(CELL, 0))
	kin.note_hit(bloom, harmony_target, 1.0)
	kin.note_hit(drift, harmony_target, 1.0)
	_check(harmony_target.statuses.has(EnemyStatuses.SPORED), "Spore Kin: a Sporeling-line Harmony strike poisons")

	# Resonance: a Chime Stone's hits count as lightning and add Charged.
	_rule(&"resonance")
	var chime := _plant("chime_stone", Vector2(12, 12))
	var rung := _spawn(chime.global_position + Vector2(CELL, 0))
	var before: int = rung.statuses.stacks(EnemyStatuses.STATIC)
	chime.hit(rung, 1.0, true, Tower.NO_CRIT)
	_check(rung.statuses.stacks(EnemyStatuses.STATIC) > before, "Resonance: a Chime Stone pulse adds Charged")

	# Thornheart: Bramble thorns grow with the Brambles owned.
	var bramble := _plant("bramble", Vector2(15, 3))
	_plant("bramble", Vector2(17, 3))
	var thorns := bramble.get_wall_multiplier()
	_rule(&"thornheart")
	_check(is_equal_approx(bramble.get_wall_multiplier(), thorns * (1.0 + 2 * DreamState.THORNHEART_PER * dreams.rule_power(&"thornheart"))),
		"Thornheart: +5%% per Bramble (%.3f)" % bramble.get_wall_multiplier())

	# Live Wire: Charged bolts hit harder.
	var bolt_before: float = dreams.get_bolt_multiplier()
	_rule(&"live_wire")
	_check(dreams.get_bolt_multiplier() > bolt_before, "Live Wire: the bolt multiplier grows (%.2f)" % dreams.get_bolt_multiplier())

	print("catalogue cards test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _rule(rule: StringName) -> void:
	var card := UpgradeData.new()
	card.id = "test_" + String(rule)
	card.rule_id = rule
	card.kind = UpgradeData.Kind.RULE
	card.max_stacks = 0
	dreams.pool.append(card)
	dreams.take(card)

func _plant(id: String, cell: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = cell
	tower.position = cell * CELL + Vector2(CELL, CELL) / 2
	container.add_child(tower)
	tower.set_process(false)
	return tower

func _spawn(at: Vector2) -> Node2D:
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	var enemy = spawner.get_child(spawner.get_child_count() - 1)
	enemy.set_process(false)
	enemy.global_position = at
	enemy.max_health = 1000000
	enemy.health = 1000000
	return enemy

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
