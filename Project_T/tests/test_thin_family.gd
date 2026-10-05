extends SceneTree

# Headless test for the thin-family cards 192–203 (dream_design.md "Thin-family cards (2026-09-30)"):
# data, Needs and discovery, and the parts DreamState owns (Deep Grip, Murmur, Called Shot, the
# queries Tower / Enemy Code read, Clear Tones, Lingering Mark, Chorus's soft Need). Never touches
# the player's saves.
#   godot --headless --path . --script res://tests/test_thin_family.gd --fixed-fps 60

const CARDS := {
	"deep_grip": "rootling", "tangled_release": "rootling", "tangled_release_ii": "rootling",
	"long_light": "rootlight", "root_web": "rootling", "lullaby": "dreamcatcher",
	"lullaby_ii": "dreamcatcher", "chorus": "bellflower", "bright_marks": "lanternmoth",
	"called_shot": "lanternmoth",
	"homing_instinct": "nestling", "homing_instinct_ii": "nestling", "murmur": "nestling",
}

var failures := 0
var main: Node
var dreams: DreamState

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	dreams = main.get_node("%DreamState")
	dreams.unlock_everything = false
	_test_data()
	_test_hits()
	_test_queries()
	print("thin family test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _test_data() -> void:
	for id in CARDS:
		var card := _card(id)
		if card == null:
			continue
		_check(card.in_start_pool and Array(card.requires) == [CARDS[id]], "%s: Start pool, needs %s" % [id, CARDS[id]])
		dreams.discovery_profile = {"seen": [], "wardens_built": [], "best_chain": 0}
		_check(dreams.discovery_keys(card).has("warden:" + CARDS[id]) and not dreams.discovery_met(card),
			"%s: joins the pool when its Warden is first built" % id)
		dreams.discovery_profile["wardens_built"] = [CARDS[id]]
		_check(dreams.discovery_met(card), "%s: …then it can come" % id)
		dreams.discovery_profile = null
	_check(_card("deep_grip").max_stacks == 1 and _card("bright_marks").max_stacks == 1,
		"Deep Grip and Bright Marks once (power pass)")
	for pair in [["tangled_release_ii", "tangled_release"], ["lullaby_ii", "lullaby"],
			["homing_instinct_ii", "homing_instinct"]]:
		_check(_card(pair[0]).deepens == pair[1], "%s deepens %s" % pair)
	# Chorus: a soft Need of 2 Bellflower-line Wardens
	dreams.unlocked["bellflower"] = true
	var chorus := _card("chorus")
	var one := _plant("bellflower", Vector2(100, 100))
	_check(not dreams.soft_needs_met(chorus), "Chorus: one Bellflower isn't enough (soft)")
	var two := _plant("dreamcatcher", Vector2(103, 100))
	_check(dreams.soft_needs_met(chorus), "…two Bellflower-line Wardens are")
	one.free()
	two.free()

func _test_hits() -> void:
	var rootling := _plant("rootling", Vector2(100, 100))
	var enemy := _spawn(Vector2(5, 5))
	var base := dreams.on_hit_multiplier(rootling, enemy)
	dreams.take(_card("deep_grip"))
	_check(is_equal_approx(dreams.on_hit_multiplier(rootling, enemy), base), "Deep Grip: nothing on a free nightmare")
	enemy.statuses.apply(EnemyStatuses.HELD, 1, 5.0)
	_check(is_equal_approx(dreams.on_hit_multiplier(rootling, enemy), base + 0.50), "Deep Grip: +50% on a Held one")
	rootling.free()
	dreams.stacks.clear()

	# Murmur: a bird's hit after another bird's within 1 s
	var a := _plant("nestling", Vector2(100, 102))
	var b := _plant("nestling", Vector2(103, 102))
	var bird := _spawn(Vector2(6, 6))
	var plain := dreams.on_hit_multiplier(a, bird)
	dreams.take(_card("murmur"))
	dreams._bird_hits.clear()
	dreams.on_hit_multiplier(a, bird)
	_check(is_equal_approx(dreams.on_hit_multiplier(a, bird), plain), "Murmur: the same bird again gives nothing")
	_check(is_equal_approx(dreams.on_hit_multiplier(b, bird), plain + 0.30), "…another bird within 1 s: +30%")
	dreams._game_clock += 1.5
	_check(is_equal_approx(dreams.on_hit_multiplier(a, bird), plain), "…not after 1 s")
	dreams.stacks.clear()

	# Called Shot: the first hit on a Marked nightmare, once per Warden
	var moth := _plant("lanternmoth", Vector2(100, 104))
	dreams.take(_card("called_shot"))
	_check(not dreams.called_shot(moth, bird), "Called Shot: not on an unmarked nightmare")
	bird.statuses.apply(EnemyStatuses.MARKED, 1, 5.0)
	_check(dreams.called_shot(moth, bird) and not dreams.called_shot(moth, bird), "…a crit on the first hit on a Marked one, once")
	_check(dreams.called_shot(a, bird), "…each Warden gets its own")
	dreams.stacks.clear()
	for node in [a, b, moth]:
		node.free()
	enemy.free()
	bird.free()

func _test_queries() -> void:
	_check(dreams.get_release_pull() == 0.0 and dreams.get_caught_linger() == 0.0 and dreams.get_lit_linger() == 0.0
		and dreams.get_root_web_share(false) == 0.0 and not dreams.has_chorus() and dreams.get_marked_bonus() == 0.0
		and dreams.get_swoop_return_multiplier() == 1.0, "no cards: every query is off")
	dreams.take(_card("tangled_release"))
	_check(dreams.get_release_pull() == 0.5, "Tangled Release: 0.5 tiles")
	dreams.take(_card("tangled_release_ii"))
	_check(dreams.get_release_pull() == 1.0, "…II: 1 tile")
	dreams.take(_card("lullaby"))
	_check(dreams.get_caught_linger() == 1.0, "Lullaby: 1 s")
	dreams.take(_card("lullaby_ii"))
	_check(dreams.get_caught_linger() == 2.0, "…II: 2 s")
	dreams.take(_card("long_light"))
	_check(dreams.get_lit_linger() == 3.0, "Long Light: 3 s")
	dreams.take(_card("root_web"))
	_check(dreams.get_root_web_share(false) == 0.5 and dreams.get_root_web_share(true) == 0.25, "Root Web: half, a quarter on bosses")
	dreams.take(_card("chorus"))
	_check(dreams.has_chorus(), "Chorus: on")
	dreams.take(_card("bright_marks"))
	_check(is_equal_approx(dreams.get_marked_bonus(), 0.20), "Bright Marks: +20%")
	dreams.take(_card("homing_instinct"))
	_check(is_equal_approx(dreams.get_swoop_return_multiplier(), 1.5), "Homing Instinct: 50% faster")
	dreams.take(_card("homing_instinct_ii"))
	_check(is_equal_approx(dreams.get_swoop_return_multiplier(), 1.9), "…II: 90%")
	dreams.stacks.clear()

func _card(id: String) -> UpgradeData:
	for card in dreams.pool:
		if card.id == id:
			return card
	_check(false, "card %s exists" % id)
	return null

func _plant(id: String, cell: Vector2) -> Tower:
	var tower: Tower = load("res://scenes/tower/tower.tscn").instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = cell
	tower.position = tower.MAP_GRID.calculate_map_position(cell)
	main.get_node("%TowerContainer").add_child(tower)
	tower.set_process(false)
	return tower

func _spawn(cell: Vector2) -> Node2D:
	var spawner = main.get_node("%EnemyContainer")
	var enemy = spawner.enemy_scene.instantiate()
	enemy.enemy_data = TestGrove._load_enemy_types()[0]
	spawner.add_child(enemy)
	enemy.position = enemy.grid.calculate_map_position(cell)
	enemy.set_path(PackedVector2Array([cell]))
	enemy.set_process(false)
	return enemy

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
