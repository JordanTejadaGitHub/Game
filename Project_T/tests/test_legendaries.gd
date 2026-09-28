extends SceneTree

# Headless test for the Legendary batch (dream_design.md "Legendary rules", "New Legendaries",
# "The Eldest"): the Eldest, the Legendary tag rule, and the DreamState side of cards 113–123.
#   godot --headless --path . --script res://tests/test_legendaries.gd --fixed-fps 60

var failures := 0
var main: Node
var dreams: DreamState
var run_state: RunState

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	dreams = main.get_node("%DreamState")
	run_state = main.get_node("%RunState")
	_test_card_changes()
	_test_eldest()
	_test_court()
	_test_legendary_weighting()
	_test_lucid_dreaming()
	_test_damage_legendaries()
	_test_hunters_and_briar()
	print("legendaries test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _test_card_changes() -> void:
	_reset()
	var ids := ["crossroads", "briar_crown", "menagerie", "restless_night", "last_leaf", "lucid_dreaming",
		"court_of_the_eldest", "hunters_moon", "eternal_static", "rooted_nightmares", "wildwood_reclaimed"]
	for id in ids:
		var card := _card(id)
		_check(card.rarity == UpgradeData.Rarity.LEGENDARY and card.min_act == 2 and card.max_stacks == 1
			and card.in_start_pool and card.requires.is_empty() and card.requires_tag == "",
			"%s: a Start-pool Legendary with no Needs" % id)
		_check(dreams.is_eligible(card, 2) and not dreams.is_eligible(card, 1), "%s is offered from act 2" % id)
	for id in ["thousand_cuts", "seed_storm", "eye_of_the_tempest", "ring_of_rings"]:
		_check(_card(id).rarity == UpgradeData.Rarity.RARE, "%s is now Rare" % id)
	_check(_card("nightshade").potency_bonus == 0.0 and _card("the_old_ones").rank_crit_bonus == 0.0,
		"Nightshade and The Old Ones keep to one archetype")
	dreams.take(_card("wildwood_reclaimed"))
	_check(dreams.can_clear(), "Wildwood Reclaimed unlocks clearing")

# Ranks past V belong to one Warden, the Eldest.
func _test_eldest() -> void:
	_reset()
	var a := _plant("sporeling", Vector2(100, 100), 5)
	var b := _plant("sporeling", Vector2(104, 100), 5)
	_check(dreams.get_max_rank_for(a) == 5 and not dreams.needs_eldest_confirm(a), "no rank VI without Deeper / Endless Rings")
	dreams.take(_card("deeper_rings"))
	_check(dreams.eldest_available() and dreams.needs_eldest_confirm(a), "rank V → VI asks to name the Eldest")
	var changes := []
	dreams.eldest_changed.connect(func(t: Tower) -> void: changes.append(t))
	_check(dreams.make_eldest(a) and dreams.is_eldest(a) and changes == [a], "confirming makes it the Eldest")
	_check(dreams.get_max_rank_for(a) == 7 and dreams.get_max_rank_for(b) == 5, "every other Warden stops at V")
	_check(not dreams.make_eldest(b), "only one Eldest")
	var saved := dreams.to_save()
	dreams.set_eldest(null)
	dreams.load_save(saved)
	_check(dreams.get_eldest() == a, "the Eldest survives the save")
	dreams.take(_card("remembered_care"))
	a.rank = 7
	dreams._on_tower_sold(a, 0)
	_check(dreams.get_eldest() == null and run_state.memory_seeds == [5], "selling it frees the title; the seed holds rank V")
	a.free()
	_check(dreams.needs_eldest_confirm(b), "the next Warden to VI can take the title")
	_clear_towers()

func _test_court() -> void:
	_reset()
	var low := _plant("sporeling", Vector2(100, 100), 2)
	var high := _plant("sporeling", Vector2(110, 100), 4)
	var friend := _plant("dewdrop", Vector2(111, 101), 0)
	dreams.take(_card("court_of_the_eldest"))
	_check(dreams.get_eldest() == high, "Court of the Eldest names the highest-rank Warden")
	_check(is_equal_approx(dreams.get_court_rank_share(friend), 1.0) and dreams.get_court_rank_share(low) == 0.0,
		"Wardens touching the Eldest get 25% of its ranks")
	_clear_towers()
	_reset()
	dreams.take(_card("court_of_the_eldest"))
	var first := _plant("sporeling", Vector2(100, 100), 0)
	dreams._watch_nurture(first)
	first.nurture(0)
	_check(dreams.get_eldest() == first, "with nothing ranked, the next Warden nurtured becomes the Eldest")
	_clear_towers()

# After taking a Legendary its archetype counts as an owned family (2×).
func _test_legendary_weighting() -> void:
	_reset()
	var maze_card := _card("cozy_corners")  # tags: maze
	var plain := _card("quickened_sap")  # no tags
	dreams.take(_card("crossroads"))
	var maze_picks := 0
	for i in 2000:
		if dreams._weighted_pick([maze_card, plain]) == maze_card:
			maze_picks += 1
	_check(maze_picks > 1200, "a taken Legendary's tag is weighted 2× (%d / 2000)" % maze_picks)

func _test_lucid_dreaming() -> void:
	_reset()
	dreams.unlocked["sporeling"] = true
	dreams.take(_card("lucid_dreaming"))
	var offer := dreams.make_offer(30)
	_check(offer.size() == 4 and not offer.any(func(c: UpgradeData) -> bool: return c.rarity == UpgradeData.Rarity.COMMON),
		"Lucid Dreaming: 4 cards, no Commons")
	dreams.current_offer = offer
	var first: UpgradeData = offer[0]
	var second: UpgradeData = offer[1]
	dreams.choose(first)
	_check(dreams.is_offering() and dreams.current_offer.size() == 3 and dreams.has_card(first.id), "take one, the offer stays")
	dreams.choose(second)
	_check(not dreams.is_offering() and dreams.has_card(second.id), "…take a second, then it closes")

func _test_damage_legendaries() -> void:
	# Menagerie: +8% per different attacking kind
	_reset()
	var a := _plant("sporeling", Vector2(100, 100), 0)
	_plant("dewdrop", Vector2(104, 100), 0)
	_plant("firefly_jar", Vector2(108, 100), 0)
	_plant("thornwall", Vector2(112, 100), 0)
	var base := dreams.get_soothe_multiplier(a)
	dreams.take(_card("menagerie"))
	_check(is_equal_approx(dreams.get_soothe_multiplier(a) - base, 0.24), "Menagerie: 3 kinds = +24% (walls don't count)")
	_clear_towers()

	# Last Leaf: +6% per leaf below max
	_reset()
	a = _plant("sporeling", Vector2(100, 100), 0)
	base = dreams.get_soothe_multiplier(a)
	dreams.take(_card("last_leaf"))
	run_state.max_leaves = 15
	run_state.leaves = 11
	_check(is_equal_approx(dreams.get_soothe_multiplier(a) - base, 0.24), "Last Leaf: 4 leaves down = +24%")
	run_state.leaves = 15
	_clear_towers()

	# Restless Night: +8% per early call this block, reset at rest
	_reset()
	a = _plant("sporeling", Vector2(100, 100), 0)
	base = dreams.get_soothe_multiplier(a)
	dreams.take(_card("restless_night"))
	dreams._early_calls = 3
	_check(is_equal_approx(dreams.get_soothe_multiplier(a) - base, 0.24), "Restless Night: 3 early calls = +24%")
	dreams._on_rest_started(1, false, 0, true)
	dreams._pending_drifts.clear()
	_check(dreams._early_calls == 0, "…resets at the rest")
	_clear_towers()

	# Crossroads: touching two route tiles 6+ steps apart
	_reset()
	var path: PackedVector2Array = main.get_node("%MapGenerator").get_path_from(main.get_node("%MapGenerator").startPath)
	var fold := _find_crossroads_cell(path)
	if fold != Vector2(-1, -1):
		var cross := _plant("sporeling", fold, 0)
		base = dreams.get_soothe_multiplier(cross)
		dreams.take(_card("crossroads"))
		_check(is_equal_approx(dreams.get_soothe_multiplier(cross) - base, 0.40), "Crossroads: +40% where the route folds back")
	var plain := _plant("sporeling", Vector2(200, 200), 0)
	_check(dreams.get_crossroads_bonus(plain) == 0.0, "…nothing away from the route")
	_clear_towers()

	# Wildwood Reclaimed: Wardens on cleared cells
	_reset()
	run_state.tended_cells.assign([Vector2(100, 100), Vector2(5, 5), Vector2(6, 6)])
	var on_clear := _plant("sporeling", Vector2(100, 100), 0)
	var off_clear := _plant("sporeling", Vector2(104, 100), 0)
	var on_base := dreams.get_soothe_multiplier(on_clear)
	var off_base := dreams.get_soothe_multiplier(off_clear)
	dreams.take(_card("wildwood_reclaimed"))
	_check(is_equal_approx(dreams.get_soothe_multiplier(on_clear) - on_base, 0.36)
		and is_equal_approx(dreams.get_soothe_multiplier(off_clear), off_base), "Wildwood: +30% +2% per clear, only on cleared cells")
	run_state.tended_cells.clear()
	_clear_towers()

func _test_hunters_and_briar() -> void:
	_reset()
	var spawner = main.get_node("%EnemyContainer")
	var marked := _enemy(Vector2(10, 10), Vector2.ZERO)
	var near := _enemy(Vector2(10, 10), Vector2(64, 0))
	var far := _enemy(Vector2(10, 10), Vector2(64 * 5, 0))
	dreams.take(_card("hunters_moon"))
	marked.apply_status(EnemyStatuses.MARKED)
	dreams._on_enemy_cleansed(marked)  # Hand-added nightmares aren't wired to the spawner's signal
	_check(near.statuses.has(EnemyStatuses.MARKED) and not far.statuses.has(EnemyStatuses.MARKED),
		"Hunter's Moon: a dispelled Marked nightmare Marks those within 3 cells")
	for child in spawner.get_children():
		child.free()

	# Briar Crown: stepping onto a route tile beside a wall hits for 25% of the strongest Warden there
	_reset()
	var map_generator = main.get_node("%MapGenerator")
	var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	var tile := path[8]
	var wall_cell := Vector2(-1, -1)
	for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		if not path.has(tile + offset):
			wall_cell = tile + offset
			break
	var wall := _plant("thornwall", wall_cell, 0)
	var warden := _plant("sporeling", wall_cell + (wall_cell - tile), 0)
	dreams.take(_card("briar_crown"))
	var walker := _enemy(tile, Vector2.ZERO)
	var health: int = walker.health
	dreams._process(0.1)
	_check(walker.health < health, "Briar Crown: a nightmare beside a wall takes damage")
	var after: int = walker.health
	dreams._briar_cells.clear()
	dreams._process(0.1)
	_check(walker.health == after, "…once per wall per second")
	walker.free()
	wall.free()
	warden.free()


# --- Helpers --------------------------------------------------------------------------------------

func _find_crossroads_cell(path: PackedVector2Array) -> Vector2:
	var index := {}
	for i in path.size():
		index[path[i]] = i
	for i in path.size():
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = path[i] + offset
			if index.has(cell):
				continue
			var low := 1 << 30
			var high := -1
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					var step: int = index.get(cell + Vector2(dx, dy), -1)
					if step >= 0:
						low = mini(low, step)
						high = maxi(high, step)
			if high - low >= 6:
				return cell
	return Vector2(-1, -1)

func _reset() -> void:
	dreams.stacks.clear()
	dreams.unlocked = {"sprout": true, "thornwall": true}
	dreams.grove_cards.clear()
	dreams.set_eldest(null)
	dreams._court_pending = false
	dreams._early_calls = 0
	run_state.memory_seeds.clear()
	_clear_towers()

func _card(id: String) -> UpgradeData:
	for card in dreams.pool:
		if card.id == id:
			return card
	_check(false, "card %s exists" % id)
	return null

func _plant(id: String, cell: Vector2, rank: int) -> Tower:
	var tower: Tower = load("res://scenes/tower/tower.tscn").instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = cell
	tower.position = tower.MAP_GRID.calculate_map_position(cell)
	main.get_node("%TowerContainer").add_child(tower)
	tower.set_process(false)
	tower.rank = rank
	return tower

func _enemy(cell: Vector2, offset: Vector2) -> Node2D:
	var spawner = main.get_node("%EnemyContainer")
	var enemy = spawner.enemy_scene.instantiate()
	enemy.enemy_data = TestGrove._load_enemy_types()[0]
	spawner.add_child(enemy)
	enemy.position = enemy.grid.calculate_map_position(cell) + offset
	enemy.set_path(PackedVector2Array([cell]))
	enemy.set_process(false)
	enemy.max_health = 1000000
	enemy.health = enemy.max_health
	return enemy

func _clear_towers() -> void:
	for tower in main.get_node("%TowerContainer").get_children():
		tower.free()

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
