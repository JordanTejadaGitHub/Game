extends SceneTree

# Headless test for Tower Code's hooks of the Shape cards (dream_design.md e4d17195; numbers balance_simulation.md
# 60dad611; ShapeCards): Small Hands (sent-out things +35%, brood sprites +1 s), Lingering Ground (ground effects
# x1.5, clouds keep their per-tick share), Sap Rising (support Wardens pulse the 8 cells around every 2 s) and the
# group tests the balance bot reads. Cards are made here with the rule ids (Roguelite Code owns the card data).
#   godot --headless --path . --script res://tests/test_shape_cards.gd --fixed-fps 60

var failures := 0
var main: Node
var dreams: DreamState
var placer: TowerPlacer
var spawner: Node
var map: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_shape_cards_%d.json" % OS.get_process_id()
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	dreams = main.get_node("%DreamState")
	placer = main.get_node("%TowerPlacer")
	spawner = main.get_node("%EnemyContainer")
	map = main.get_node("%MapGenerator")
	dreams.unlock_everything = true
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

	# Groups (the bot's card-value table calls these).
	_check(ShapeCards.sends_things_out(_data("nestling")) and ShapeCards.sends_things_out(_data("cairn"))
		and ShapeCards.sends_things_out(_data("brood_cap")) and not ShapeCards.sends_things_out(_data("sporeling")),
		"sent-out: swoops, lobs and brood; not a plain shooter")
	_check(ShapeCards.makes_ground_effects(_data("cairn")) and not ShapeCards.makes_ground_effects(_data("sporeling")),
		"ground: lobs (rubble); not a plain shooter")
	_check(ShapeCards.is_support(_data("elder_stump")) and ShapeCards.is_support(_data("dewcatcher"))
		and ShapeCards.is_support(_data("dreamcatcher")) and not ShapeCards.is_support(_data("thornwall"))
		and not ShapeCards.is_support(_data("acorn")), "support: auras, catchers, Dreamcatchers; never walls or the Acorn")

	# Small Hands: a swooping bird's landing hits +35%; a brood sprite lives +1 s.
	var nest := _plant("nestling", Vector2(16, 2))
	nest.attack_data = nest.attack_data.duplicate()
	nest.attack_data.crit_chance = 0.0
	var target := _walker(Vector2(16, 4))
	var before: float = target.health
	nest.projectile_landed(target, target.global_position)
	var plain: float = before - target.health
	_take(ShapeCards.SMALL_HANDS)
	nest.clear_dream_cache()
	before = target.health
	nest.projectile_landed(target, target.global_position)
	var handed: float = before - target.health
	_check(plain > 0.0 and absf(handed / plain - (1.0 + ShapeCards.SMALL_HANDS_DAMAGE)) < 0.02,
		"Small Hands: a swoop lands +35%% (%.2f -> %.2f)" % [plain, handed])
	var brood := _plant("brood_cap", Vector2(4, 2))
	BranchKit.BroodSprite.spawn(brood, false)
	var sprite: Node = null
	for n in BranchKit.world(brood).get_children():
		if n is BranchKit.BroodSprite and n.tower == brood:
			sprite = n
	_check(sprite != null and is_equal_approx(sprite.life, 8.0 + ShapeCards.SMALL_HANDS_SECONDS),
		"Small Hands: a brood sprite lives +1 s (%.1f)" % (sprite.life if sprite else -1.0))
	_clear_cards()

	# Lingering Ground: ground effects x1.5; a cloud keeps its per-tick share, so it deals x1.5 in all.
	var bloom := _plant("bloomcap", Vector2(4, 4))
	var base_cloud := PathCloud.new(bloom, Vector2.ZERO)
	_take(ShapeCards.LINGERING_GROUND)
	var long_cloud := PathCloud.new(bloom, Vector2.ZERO)
	_check(is_equal_approx(long_cloud._duration, base_cloud._duration * ShapeCards.LINGERING_MULTIPLIER)
		and is_equal_approx(long_cloud._tick_share, base_cloud._tick_share),
		"Lingering Ground: a cloud lasts x1.5 (%.1f -> %.1f s), same share a tick" % [base_cloud._duration, long_cloud._duration])
	_check(is_equal_approx(ShapeCards.ground_time(2.0), 3.0) and ShapeCards.ground_time(0.0) == 0.0,
		"Lingering Ground: 2 s -> 3 s, 'until stepped on' stays")
	base_cloud.free()
	long_cloud.free()
	_clear_cards()
	_check(is_equal_approx(ShapeCards.ground_time(2.0), 2.0), "without the card, ground effects keep their time")

	# Sap Rising: an Elder Stump pulses the 8 cells around it for 2 s x the DPS its aura adds (or the floor).
	var stump := _plant("elder_stump", Vector2(10, 10))
	var friend := _plant("sporeling", Vector2(11, 10))
	stump.set_process(false)
	await process_frame
	var beside := _walker(Vector2(10, 11))
	var far := _walker(Vector2(10, 14))
	var hp: float = beside.health
	var far_hp: float = far.health
	stump._sap_left = 0.0
	stump._update_sap(0.01)
	_take(ShapeCards.SAP_RISING)
	var expected := ShapeCards.sap_damage(stump)
	var floor_damage := ShapeCards.SAP_EVERY * ShapeCards.SAP_FLOOR_SHARE * ShapeCards.median_dps(self)
	_check(expected >= floor_damage - 0.001 and expected > 0.0, "Sap Rising: at least the floor (%.1f >= %.1f)" % [expected, floor_damage])
	hp = beside.health
	stump._sap_left = 0.0
	stump._update_sap(0.01)
	_check(beside.health < hp and is_equal_approx(far.health, far_hp),
		"Sap Rising: the nightmare beside it is hit (%.1f -> %.1f), the far one isn't" % [hp, beside.health])
	var kinds: Array = DamageLog.instance.get_tower_stats(stump).keys() if DamageLog.instance and DamageLog.instance.has_method("get_tower_stats") else []
	_check(DamageLog.instance == null or not kinds.is_empty(), "Sap Rising: logged under the Elder Stump")
	hp = beside.health
	stump._update_sap(1.0)
	_check(is_equal_approx(beside.health, hp), "Sap Rising: only every 2 s")
	_check(not ShapeCards.is_support(friend.tower_data), "(the Sporeling attacks: no sap)")
	_clear_cards()

	print("shape cards test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _data(id: String) -> TowerData:
	return load("res://resource/tower/%s.tres" % id)

func _take(rule: StringName) -> void:
	var card := UpgradeData.new()
	card.id = String(rule) + "_test"
	card.rule_id = rule
	card.display_name = String(rule)
	dreams.pool.append(card)
	dreams.take(card)

func _clear_cards() -> void:
	dreams.stacks.clear()
	dreams.bump_board()

func _plant(id: String, at: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = _data(id)
	tower.cell = at
	tower.position = Tower.MAP_GRID.calculate_map_position(at)
	placer.tower_container.add_child(tower)
	tower.set_process(false)
	return tower

func _walker(cell: Vector2) -> Node2D:
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"), 50.0)
	var e = spawner.get_child(spawner.get_child_count() - 1)
	e.set_process(false)
	e.global_position = Tower.MAP_GRID.calculate_map_position(cell)
	e.max_health = 100000
	e.health = 100000
	return e

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + what)
