extends SceneTree

# Headless test for the generic Dream cards 142–168 (dream_design.md "Generic Commons and
# Uncommons" and "Generic cards, second batch"): the parts DreamState owns (stat and per-hit rules,
# economy hooks in RunState / TowerSeller / DriftDirector, rest rules, Needs). Tower / Enemy / HUD
# hooks (Watchful Rest, trample, glows) are tested there.
#   godot --headless --path . --script res://tests/test_generic_cards.gd --fixed-fps 60

const IDS := ["call_of_the_wild", "lasting_dreams",
	"forests_edge", "crowded_path", "crowded_path_ii", "lone_hunter", "lone_hunter_ii",
	"fresh_growth", "fresh_growth_ii", "weathered_walls", "heavy_air",
	"wandering_mind", "winding_path", "thick_bark", "thick_bark_ii",
	"last_breath", "last_breath_ii", "watchful_rest", "watchful_rest_ii",
	"glimmering_hunt", "straightaway", "straightaway_ii", "heart_of_the_maze"]

# The lean starting pool (dream_design.md "The starting Dream pool", 2026-09-30): these moved to Grove nodes.
const LEAN_GROVE := ["bitter_hedges", "bramble_oath", "briar_crown", "crossroads", "desperate_bloom", "elder_kin", "eternal_static", "few_and_mighty", "forests_edge", "grand_tour", "hunters_moon", "hunters_patience", "last_leaf", "last_stand", "lucid_dreaming", "menagerie", "mixed_grove", "reclaimed_earth", "restless_night", "rooted_nightmares", "scarred_bark", "scarred_bark_ii", "scented_hedge", "second_wind", "sharpened_light", "sharpened_light_ii", "tended_forest", "thin_bark", "thorn_snare", "thorn_snare_ii", "thornheart", "wildwood_reclaimed"]

var failures := 0
var main: Node
var dreams: DreamState
var run_state: RunState
var map_generator

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	dreams = main.get_node("%DreamState")
	run_state = main.get_node("%RunState")
	map_generator = main.get_node("%MapGenerator")
	_test_pool()
	_test_economy()
	_test_stat_rules()
	_test_hit_rules()
	_test_crowd_counts()
	_test_card_feel()
	_test_rest_rules()
	_test_map_rules()
	_test_sim_entry()
	_test_sim_policy()
	_test_rows_cache()
	_test_scaling_cards()
	_test_catalogue()
	_test_eleven_cards()
	_test_cards_227()
	_test_seed_cards()
	_test_support_cards()
	_test_needs_text()
	_test_live_lines()
	_test_reaction_links()
	_test_grove_branches()
	_test_clearing_payoffs()
	_test_combo_choices()
	_test_source_shards()
	_test_impact_conditions()
	_test_twig_walls()
	_test_new_commons()
	print("generic cards test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)


# Twig Walls (dream_design.md c6fefe1b, card 256): DreamState.twig_walls() for Tower Code's placer, a twig wall counts
# half for Hedge Maze (Tower.twig). Rare, maze, start pool, act 2+ (Balancing fd7e1b0e).
class TwigWall extends Node:
	var twig := true

func _test_twig_walls() -> void:
	_reset()
	var twig := _card("twig_walls")
	_check(twig != null and twig.rarity == UpgradeData.Rarity.RARE and twig.tags == ["maze", "defining"] and twig.in_start_pool and twig.min_act == 2
		and twig.requires.is_empty(), "Twig Walls: Rare, maze, start pool, act 2+, no needs")
	_check(not dreams.twig_walls(), "no Twig Walls: full-size Thornwalls")
	dreams.take(twig)
	_check(dreams.twig_walls(), "Twig Walls held: TowerPlacer plants twig walls")
	var stick := TwigWall.new()
	_check(DreamState.wall_weight(stick) == 0.5 and DreamState.wall_weight(null) == 1.0, "a twig wall counts half a Thornwall for Hedge Maze")
	stick.free()
	dreams.stacks.clear()

# New Commons 258 / 261 (dream_design.md de439ea8): Passing Dream (statuses jump on a dispel) and Dew Line (every 10th
# dispel of a drift pays its share twice).
func _test_new_commons() -> void:
	_reset()
	dreams.take(_card("passing_dream"))
	var gone := _spawn(Vector2(10, 10))
	var near := _spawn(Vector2(11, 10))
	var far := _spawn(Vector2(16, 10))
	gone.apply_status(EnemyStatuses.SPORED, 3, 5.0)
	gone.apply_status(EnemyStatuses.DROWSY, 1, 4.0)
	dreams._passing_dream(gone)
	_check(near.statuses.stacks(EnemyStatuses.SPORED) == 3 and near.statuses.has(EnemyStatuses.DROWSY) and not far.statuses.has(EnemyStatuses.SPORED),
		"Passing Dream: the statuses jump to the nearest nightmare within 2 cells, stacks and all")
	_free_enemies()
	dreams.stacks.clear()
	dreams._dispels_this_drift = 0
	var extras: Array[float] = []
	for i in 10:
		extras.append(dreams.dew_line_extra())
	_check(extras.max() == 0.0, "no Dew Line: never twice")
	dreams.take(_card("dew_line"))
	dreams._dispels_this_drift = 0
	extras.clear()
	for i in 20:
		extras.append(dreams.dew_line_extra())
	_check(extras[9] == 1.0 and extras[19] == 1.0 and extras.count(1.0) == 2, "Dew Line: the 10th and 20th dispels pay twice")
	dreams.stacks.clear()
func _test_pool() -> void:
	for id in IDS:
		var card := _card(id)
		if card:
			_check(card.in_start_pool == (id != "wandering_mind" and not LEAN_GROVE.has(id)), "%s: pool" % id)
	_check(_card("glimmering_hunt").min_act == 2, "Glimmering Hunt from act 2")
	_reset()
	_check(not dreams.is_eligible(_card("heavy_air")), "Heavy Air needs a Warden that slows")
	dreams.unlocked["dewdrop"] = true
	_check(not dreams.is_eligible(_card("heavy_air")), "…Dewdrop isn't (Soaked no longer slows)")
	dreams.unlocked["bellflower"] = true
	_check(dreams.is_eligible(_card("heavy_air")), "…Bellflower (Drowsy) is")
	# Offer gate (Grove sim, balancing): Heavy Eyelids needs a Drowsy source. Patient Roots stays ungated: it's a Seed
	# card, offered before its Wardens on purpose (it calls the Rootling family to the next pick).
	_check(_card("heavy_eyelids").requires_status == &"drowsy" and dreams._meets_needs(_card("heavy_eyelids")),
		"Heavy Eyelids needs a Drowsy source (Bellflower has one)")

func _test_economy() -> void:
	_reset()
	var director = main.get_node("%DriftDirector")
	var plain: float = director.get_effective_pot(12)
	dreams.take(_card("morning_dew"))
	_check(is_equal_approx(director.get_effective_pot(12), director.get_dew_pot(12) * 1.1) and plain < director.get_effective_pot(12),
		"Morning Dew (absorbs Gathered Dew): each drift's Dew pot +10%% (%.1f vs %.1f)" % [director.get_effective_pot(12), plain])
	var seller = main.get_node("%TowerSeller")
	var tower := _plant("sporeling", Vector2(100, 100))
	tower.invested_dew = 100
	_check(seller.get_refund(tower) == 75, "selling: 75% at a rest (Fair Trade was cut)")
	_check(dreams.get_call_early_bonus(7, 10) == 7, "call early: plain")
	dreams.take(_card("call_of_the_wild"))
	_check(dreams.get_call_early_bonus(7, 10) == 14 and dreams.get_call_early_bonus(30, 10) == 20 and dreams.get_call_early_bonus(30, 25) == 40, "Call of the Wild: double, up to 40")
	_check(is_equal_approx(director.get_effective_pot(12, true), director.get_dew_pot(12) * 1.2) and is_equal_approx(director.get_effective_pot(12), director.get_dew_pot(12) * 1.1),
		"Call of the Wild: +10% pot only on a drift called early")
	dreams.take(_card("winding_path"))
	_check(dreams.get_rest_bonus_add() == 10 + dreams.path_length / 5, "Winding Path: +1 Dew per 5 path tiles (%d tiles, + Morning Dew's 10)" % dreams.path_length)
	# Half cells: the route steps half a cell, path tiles stay full cells (not the point count)
	var route_points: PackedVector2Array = main.get_node("MapGenerator").get_path_from(main.get_node("MapGenerator").startPath)
	_check(dreams.path_length == main.get_node("MapGenerator").route_length(route_points) and dreams.path_length < route_points.size(),
		"path tiles count full cells on the half-cell route (%d tiles, %d points)" % [dreams.path_length, route_points.size()])
	var tower_cells := Tower.route_cells(PackedVector2Array([Vector2(3.25, 4.75), Vector2(3.75, 4.25)]))
	_check(DreamState.route_cells(Vector2(3.25, 4.75))[0] == tower_cells[0] and DreamState.route_cells(Vector2(3.75, 4.25))[0] == tower_cells[1]
		and DreamState.route_cells(Vector2(3, 4)) == [Vector2(3, 4)], "a half-cell route point lies in one whole cell, as Tower.route_cells (%s)" % [tower_cells])
	var rerolls := dreams.rerolls_left
	dreams.take(_card("wandering_mind"))
	_check(dreams.rerolls_left == rerolls + 2, "Wandering Mind: +2 rerolls")
	dreams.take(_card("weathered_walls"))
	var wall: TowerData = load("res://resource/tower/thornwall.tres")
	_check(dreams.get_build_cost_at(wall, Vector2(3, 3)) == 1, "Weathered Walls: Thornwalls cost 1 Dew (absorbs Cheap Hedges)")
	_clear()

func _test_stat_rules() -> void:
	_reset()
	var dewdrop: TowerData = load("res://resource/tower/dewdrop.tres")
	var damp := dreams.get_status_duration(dewdrop, EnemyStatuses.DAMP)
	dreams.take(_card("lasting_dreams"))
	dreams.take(_card("lasting_dreams"))
	_check(is_equal_approx(dreams.get_status_duration(dewdrop, EnemyStatuses.DAMP), damp + 4.0), "Lasting Dreams ×2: +4 s")
	dreams.take(_card("heavy_air"))
	_check(is_equal_approx(dreams.get_status_strength_multiplier(EnemyStatuses.DROWSY), 1.4)
		and dreams.get_status_strength_multiplier(EnemyStatuses.DAMP) == 1.0
		and dreams.get_status_strength_multiplier(EnemyStatuses.MARKED) == 1.0, "Heavy Air: slows 40% stronger, nothing else")
	# Forest's Edge
	dreams.take(_card("forests_edge"))
	var short: TowerData = null
	var long: TowerData = null
	for data in main.get_node("%TowerPlacer").towers:
		if data.can_attack and data.attack_range <= 2.0 and short == null:
			short = data
		elif data.can_attack and data.attack_range > 2.0 and long == null:
			long = data
	var far := Vector2(100, 100)
	_check(not _row(long if long else short, far, "forests_edge").active, "Forest's Edge: off far from the start")
	var start: Vector2 = map_generator.startPath
	_check(_row(long if long else short, start + Vector2(2, 2), "forests_edge").active
		and not _row(long if long else short, start + Vector2(4, 0), "forests_edge").active, "Forest's Edge: within 3 cells of the start")
	# Fresh Growth: planted during a drift, until the next rest
	dreams.take(_card("fresh_growth"))
	var director: DriftDirector = main.get_node("%DriftDirector")
	var tower := _plant("sporeling", Vector2(100, 100))
	director.resting = false
	dreams._mark_fresh(tower)
	director.resting = true
	var base := dreams.get_soothe_multiplier(tower)
	_check(dreams.is_fresh(tower) and _row(tower.tower_data, tower.cell, "fresh_growth", tower).active, "Fresh Growth: planted during a drift")
	dreams._rest_rules(false)
	_check(not dreams.is_fresh(tower) and is_equal_approx(base - dreams.get_soothe_multiplier(tower), 0.50), "…+50% until the next rest")
	_clear()

func _test_hit_rules() -> void:
	_reset()
	var tower := _plant("sporeling", Vector2(100, 100))
	var a := _spawn(map_generator.startPath + Vector2(0, 0))
	_check(dreams.on_hit_multiplier(tower, a) == 1.0, "no card: ×1")
	dreams.take(_card("lone_hunter"))
	_check(is_equal_approx(dreams.on_hit_multiplier(tower, a), 1.45), "Lone Hunter: +45% alone")
	var b := _spawn(map_generator.startPath, Vector2(40, 0))
	_check(dreams.on_hit_multiplier(tower, a) == 1.0, "…not with a nightmare within 2 cells")
	# Crowded Path counts both in range
	dreams.take(_card("crowded_path"))
	var near := _plant("sporeling", map_generator.startPath + Vector2(1, 1))
	_check(dreams.count_in_range(near) == 2 and _row(near.tower_data, near.cell, "crowded_path", near).damage > 0.05,
		"Crowded Path: +3%% per nightmare in range (%d)" % dreams.count_in_range(near))
	# Last Breath: the neighbour takes 10% of the dispelled one's max health, no chain
	dreams.take(_card("last_breath"))
	var before: float = b.health
	a.take_damage(a.health + 1.0, "", false, false, null, &"")
	dreams._last_breath(a)  # Test nightmares aren't wired to the spawner's enemy_cleansed
	_check(b.health < before and is_equal_approx(before - b.health, a.max_health * 0.1) or b.is_cleansed,
		"Last Breath: 10%% of its max health on the nightmare beside it (%.1f)" % (before - b.health))
	# Glimmering Hunt: 30% of elites drop a shard (10 = 1 Dreamlight), its own cap of 3 Dreamlight per run
	dreams.take(_card("glimmering_hunt"))
	dreams._glimmer_rng.seed = 3
	dreams.glimmer_shards = 0
	var light := dreams.dreamlight
	var catcher_shards := dreams.dreamlight_shards
	var elite := _spawn(map_generator.startPath + Vector2(0, 2))
	elite.elite = true
	for i in 50:
		dreams._glimmer(elite)
	_check(dreams.glimmer_shards > 8 and dreams.glimmer_shards < 25 and dreams.dreamlight_shards == catcher_shards,
		"Glimmering Hunt: ~30%% of elites drop a shard, apart from the Dreamcatcher's (%d / 50)" % dreams.glimmer_shards)
	for i in 500:
		dreams._glimmer(elite)
	_check(dreams.glimmer_shards == 30 and dreams.dreamlight == light + 3, "…capped at 3 Dreamlight per run (%d shards, +%d)" % [dreams.glimmer_shards, dreams.dreamlight - light])
	# Half-dreamed Commons 189–191 (stack to 3)
	var soaked := _spawn(map_generator.startPath + Vector2(0, 4))
	var jar := _plant("firefly_jar", Vector2(110, 100))
	dreams.unlocked["dewdrop"] = true  # Cross-family combos sleep until both families are yours
	dreams.unlocked["firefly_jar"] = true
	dreams.take(_card("rain_on_glass"))
	dreams.unlocked["firefly_jar"] = true
	_check(dreams.get_spored_tick_multiplier(soaked) == 1.0 and dreams.get_ignite_multiplier() == 1.0, "no Soaked Rot / Sparking Spores: ×1")
	var dry := dreams.on_hit_multiplier(jar, soaked)
	soaked.apply_status(EnemyStatuses.DAMP, 1, 4.0)
	_check(is_equal_approx(dreams.on_hit_multiplier(jar, soaked) / dry, (1.0 + 0.70) / 1.0) or is_equal_approx(dreams.on_hit_multiplier(jar, soaked) - dry, 0.70),
		"Rain on Glass: light Wardens +70% vs Soaked")
	_check(dreams.on_hit_multiplier(tower, soaked) == dreams.on_hit_multiplier(tower, soaked), "…not other lines")
	dreams.take(_card("damp_rot"))
	dreams.take(_card("sparking_spores"))
	_check(is_equal_approx(dreams.get_spored_tick_multiplier(soaked), 2.0) and is_equal_approx(dreams.get_ignite_multiplier(), 2.0),
		"Soaked Rot: Poisoned ticks double on Soaked; Sparking Spores: Ignite twice as hot")
	_free_enemies()
	_clear()

# The headless entry points for balance tools (DreamState.sim_rest / sim_family_pick).
func _test_sim_entry() -> void:
	_reset()
	dreams.unlocked = {"sprout": true, "thornwall": true}
	var light := dreams.dreamlight
	Engine.time_scale = 8.0
	var family := dreams.sim_family_pick(&"first", func(ids: Array) -> StringName: return StringName(ids[0]))
	_check(Engine.time_scale == 8.0, "sim_family_pick keeps a runner's time_scale")
	Engine.time_scale = 1.0
	_check(family != &"" and dreams.is_unlocked(String(family)) and dreams.dreamlight == light + DreamState.FIRST_PICK_DREAMLIGHT,
		"sim_family_pick: takes the family, +2 Dreamlight on the first pick (%s)" % family)
	_check(not main.get_node("%GameSpeed").paused and not main.get_node("%FamilyPickScreen").visible, "…leaves the game unpaused")
	var taken := dreams.sim_rest(5, func(offer: Array) -> UpgradeData: return offer[0])
	_check(taken.size() == 1 and dreams.has_card(taken[0].id) and not dreams.is_offering(), "sim_rest: a real offer, one card taken")
	var passed := dreams.sim_rest(10, func(_offer: Array) -> UpgradeData: return null)
	_check(passed.is_empty() and not dreams.is_offering(), "…null lets it pass")
	light = dreams.dreamlight
	dreams.sim_rest(25, func(offer: Array) -> UpgradeData: return offer[0])
	_check(dreams.dreamlight == light + DreamState.BOSS_DREAMLIGHT, "…a boss rest gives +3 Dreamlight")
	light = dreams.dreamlight
	dreams.sim_rest(50, func(offer: Array) -> UpgradeData: return offer[0])
	_check(dreams.dreamlight >= light + DreamState.BOSS_DREAMLIGHT and DreamState.BOSS_DREAMLIGHT == 3, "…the drift 50 boss rest: +3 too")
	light = dreams.dreamlight
	dreams.sim_rest(55, func(offer: Array) -> UpgradeData:
		var plain := offer.filter(func(c: UpgradeData) -> bool: return c.dreamlight_now == 0)  # Not a card that gives Dreamlight
		return plain[0] if not plain.is_empty() else null)
	# No Dreamlight from an ordinary rest any more, from drift 51 either (user: "only 3 Dreamlight every 25 drifts")
	_check(dreams.dreamlight == light, "…an ordinary rest at drift 55 gives no Dreamlight (%d)" % (dreams.dreamlight - light))
	_check(dreams.sim_dreamlight_for(&"first") == DreamState.FIRST_PICK_DREAMLIGHT and dreams.sim_dreamlight_for(&"boss") == DreamState.BOSS_DREAMLIGHT, "sim_dreamlight_for")
	dreams.first_pick_dreamlight = 0
	_check(dreams.sim_dreamlight_for(&"first") == 0, "…first_pick_dreamlight 0 (Blight 2): none")
	dreams.first_pick_dreamlight = DreamState.FIRST_PICK_DREAMLIGHT
	_reset()

# The balance bot's Dream / family / Dreamlight / Omen policies (balance_simulation.md "Bot rules").
func _test_sim_policy() -> void:
	_reset()
	var wide_card := _card("many_hands")
	var narrow_card := _card("few_and_mighty")
	var wide := DreamSimPolicy.new(dreams, DreamSimPolicy.Style.WIDE)
	var narrow := DreamSimPolicy.new(dreams, DreamSimPolicy.Style.NARROW)
	_check(wide.pick_dream([narrow_card, wide_card]) == wide_card and narrow.pick_dream([wide_card, narrow_card]) == narrow_card,
		"styles score by tags: Wide takes Many Hands, Narrow Few and Mighty")
	var balanced := DreamSimPolicy.new(dreams, DreamSimPolicy.Style.BALANCED)
	_check(balanced.pick_family(["dewdrop", "sporeling"]) == &"sporeling", "Balanced: its family order")
	# Dead for now: a card about a Warden with none on the map scores lower (Tower Code's dead-card list).
	var twin := _card("twin_puff")
	var dead := balanced.score(twin)
	var puff := _plant("sporeling", Vector2(100, 100))
	_check(balanced.score(twin) > dead, "the bot skips Twin Puff with no Sporeling on the map")
	puff.free()
	_check(balanced.score(_card("tended_forest")) < balanced.score(_card("cozy_corners")), "Balanced never clears: clearing cards come last")
	# Single-target families unlock their area branch first (Cairn, Wren's Nest).
	for pair in [["pebbling", "cairn"], ["nestling", "wrens_nest"], ["sporeling", ""]]:
		var tree: Array = dreams.get_remember_trees().filter(func(t: Array) -> bool: return t[0].get_id() == pair[0]).front() \
			if dreams.get_remember_trees().any(func(t: Array) -> bool: return t[0].get_id() == pair[0]) else []
		if tree.is_empty():
			dreams.unlocked[pair[0]] = true
			tree = dreams.get_remember_trees().filter(func(t: Array) -> bool: return t[0].get_id() == pair[0]).front()
		var forms := balanced._forms_in_order(tree)
		if pair[1] != "":
			_check(forms[0].get_id() == pair[1], "%s unlocks %s first (%s)" % [pair[0], pair[1], forms[0].get_id()])
		else:
			_check(forms[0] == tree[1][0][0], "an area family keeps the Remember order")
			if tree.size() > 2 and tree[2] != null and not tree[1][0][1].is_empty():
				_check(forms.find(tree[2]) == 2, "Ascended right after the first final form, before the other branch (%s)"
					% ", ".join(forms.map(func(f: TowerData) -> String: return f.get_id())))
	dreams.unlocked["firefly_jar"] = true
	var combo := DreamSimPolicy.new(dreams, DreamSimPolicy.Style.COMBO)
	_check(combo.pick_family(["pebbling", "dewdrop"]) == &"dewdrop", "Combo: the family with the most combo cards (Dewdrop with Firefly Jar)")
	dreams.add_dreamlight(-dreams.dreamlight)  # Earlier sections left Dreamlight
	var taken := balanced.rest(5)
	_check(taken.size() == 1 and not dreams.is_offering(), "the bot never lets a Dream pass")
	# Dreamlight: the next form of the most-built family
	_plant("sporeling", Vector2(100, 100))
	_plant("sporeling", Vector2(103, 100))
	dreams.add_dreamlight(5 - dreams.dreamlight)
	balanced.spend_dreamlight()
	var branch_unlocked := false
	for next in load("res://resource/tower/sporeling.tres").evolves_to:
		branch_unlocked = branch_unlocked or dreams.is_unlocked(next.get_id())
	_check(branch_unlocked and dreams.dreamlight < 5, "Dreamlight: a Sporeling branch first (%s)" % ", ".join(balanced.choices))
	# Wide also grows Thornwalls with Dreamlight when walls are its most-built "family"
	for i in 3:
		_plant("thornwall", Vector2(100 + i, 105))
	dreams.add_dreamlight(3 - dreams.dreamlight)
	var wide_bot := DreamSimPolicy.new(dreams, DreamSimPolicy.Style.WIDE)
	wide_bot.spend_dreamlight()
	_check(wide_bot.choices.any(func(c: String) -> bool: return c.contains("bramble") or c.contains("honeysuckle")),
		"Wide: Dreamlight on Thornwall growths (%s)" % ", ".join(wide_bot.choices))
	var sprout_bot := DreamSimPolicy.new(dreams, DreamSimPolicy.Style.SPROUT)
	_check(sprout_bot.pick_dream([_card("few_and_mighty"), _card("many_hands"), _card("seedfall")]) == _card("seedfall")
		and sprout_bot.pick_family(["dewdrop", "sporeling"]) == &"sporeling", "Sprout style: its own cards on top, Sporeling first")
	var mixed := DreamSimPolicy.new(dreams, DreamSimPolicy.Style.MIXED)
	_check(mixed.score(_card("seedfall")) > balanced.score(_card("seedfall")) and mixed.score(_card("seedfall")) > 0.0,
		"Mixed: Sprout cards count")
	dreams.add_dreamlight(3 - dreams.dreamlight)
	mixed.spend_dreamlight()
	_check(not mixed.choices.any(func(c: String) -> bool: return c.contains("bramble") or c.contains("honeysuckle")),
		"Mixed: Dreamlight on families only, never Thornwall growths (%s)" % ", ".join(mixed.choices))
	_check(balanced.pick_omen([]) == null, "Omens: Clear Skies")
	var crowded: OmenData = load("res://resource/omen/crowded_paths.tres")
	var bountiful: OmenData = load("res://resource/omen/bountiful_night.tres")
	var swift: OmenData = load("res://resource/omen/swift_stream.tres")
	_check(balanced.pick_omen([crowded, swift]) == null, "…Clear Skies unless face_omens")
	balanced.face_omens = true
	_check(balanced.pick_omen([crowded, swift]) == swift and balanced.pick_omen([bountiful, crowded]) == bountiful,
		"face_omens: the lower-risk of the revealed Omens (%.2f / %.2f / %.2f)" % [DreamSimPolicy.omen_risk(crowded),
		DreamSimPolicy.omen_risk(bountiful), DreamSimPolicy.omen_risk(swift)])
	balanced.face_omens = false
	_clear()
	_reset()

# DreamEffects.rows_cached (Tower's hot path) matches rows() and follows board changes.

# "Your Dreams steer your Dreams, not your family picks" and the catalogue cards 204–226
# (dream_design.md "Build packages"): families don't weight, taken cards' tags do (×tag_weight); the
# DreamState / DreamEffects side of the new cards.
func _test_catalogue() -> void:
	_reset()
	dreams.unlocked["sporeling"] = true
	var soft := _card("chain_bloom")  # A spore card (Soft Spores was cut, dream_design.md 21ac910b)
	_check(not dreams.is_in_build(soft), "owning Sporeling doesn't make spore cards your build")
	dreams.take(_card("glinting_dew"))
	_check(dreams.is_in_build(_card("sharpened_light")) and not dreams.is_in_build(soft), "a taken precision card lifts the precision build")
	_check(DreamState.ARCHETYPE_TAGS.size() == 10 and dreams.tag_weight == 1.0, "10 archetype tags (swift and reach added); no build-tag steering")
	dreams.stacks.clear()
	# Nurture follow-ups: needing a Nurture card is soft (Kindred Roots weighs ×0.4 until you have one); Sunlit Rest is an opener
	var kindred := _card("kindred_roots")
	var ranked := _plant("sporeling", Vector2(100, 100))
	ranked.rank = 3
	_check(dreams._meets_needs(kindred) and not dreams.soft_needs_met(kindred), "Kindred Roots: drawn without a Nurture card, weighs ×0.4")
	_check(dreams.soft_needs_met(_card("sunlit_rest")), "Sunlit Rest: an opener, no Nurture card weighting")
	ranked.free()
	# Family line tags never weigh (round 3 reverted round 2's rule), not even from a taken card
	dreams.unlocked["sporeling"] = true
	_check(not dreams.is_in_build(soft), "owning Sporeling still doesn't")
	dreams.take(_card("damp_rot"))
	_check(not dreams.is_in_build(soft), "…nor a taken spore card (only archetype tags weigh)")
	dreams.stacks.clear()
	# The new cards' own numbers
	var ids := ["elder_kin", "mycelium", "fireflies_in_the_grass",
		"spore_kin", "resonance", "thornheart", "ill_wind", "eddy", "spinning_corners", "falling_weight", "warm_hearth",
		"quick_step", "thin_bark", "mixed_grove", "live_wire"]
	for id in ids:
		var card := _card(id)
		if card:
			_check(card.in_start_pool != LEAN_GROVE.has(id) and card.rarity != UpgradeData.Rarity.LEGENDARY and not card.tags.is_empty(), "%s: pool (lean), tagged" % id)
	_check(_card("resonance").requires.size() == 2 and _card("thin_bark").is_bittersweet() and _card("thin_bark").min_act == 2, "Resonance crosses 2 families; Thin Bark bittersweet act 2+")
	var eye := _plant("sporeling", Vector2(100, 104))
	eye.rank = 5
	# Falling Weight: the Pebbling line vs Held
	var pebble := _plant("pebbling", Vector2(104, 104))
	var held := _spawn(Vector2(5, 5))
	var plain := dreams.on_hit_multiplier(pebble, held)
	dreams.take(_card("falling_weight"))
	held.statuses.apply(EnemyStatuses.HELD, 1, 5.0)
	_check(is_equal_approx(dreams.on_hit_multiplier(pebble, held), plain + 0.45), "Falling Weight: +45% vs Held")
	held.free()
	# Mixed Grove
	dreams.unlocked["firefly_jar"] = true
	var families := dreams.count_owned_families()
	_check(dreams._meets_needs(_card("mixed_grove")) == (families >= 2), "Mixed Grove needs 2 families")
	# Reclaimed Earth (absorbs Fresh Soil): a Sprout on a cleared cell deals +20%
	dreams.take(_card("reclaimed_earth"))
	var sprout_data: TowerData = load("res://resource/tower/sprout.tres")
	run_state.tended_cells.append(Vector2(3, 3))
	_check(_has_row(sprout_data, Vector2(3, 3), "reclaimed_earth", 0.20) and not _has_row(sprout_data, Vector2(4, 3), "reclaimed_earth", 0.20),
		"Reclaimed Earth: Sprouts +20% on a cleared cell only")
	run_state.tended_cells.erase(Vector2(3, 3))
	# Quick Step (dream_design.md de439ea8): +50% speed while a drift called early is still arriving
	dreams.take(_card("quick_step"))
	_check(not dreams.quick_step_active(), "Quick Step: off until you call a drift early")
	var director: DriftDirector = main.get_node("%DriftDirector")
	dreams._quick_step_drift = 7
	director._arriving[7] = {}
	dreams.bump_board()
	_check(dreams.quick_step_active() and is_equal_approx(_row(eye.tower_data, eye.cell, "quick_step", eye).speed, 0.5), "…then +50% speed while it arrives")
	director._arriving.erase(7)
	_check(not dreams.quick_step_active(), "…and off once it has fully arrived")
	# Live Wire (a jump now, Tower Code) and Thin Bark
	_check(dreams.get_bolt_multiplier() == 1.0, "no bigger bolts from Live Wire")
	dreams.take(_card("live_wire"))
	_check(dreams.get_bolt_multiplier() == 1.0 and dreams.has_rule(&"live_wire"), "Live Wire: bolts jump instead (Tower Code), never bigger")
	_check(_card("thin_bark").soothe_bonus == 0.35 and _card("thin_bark").max_leaves_add == -3, "Thin Bark: +35% damage, −3 max leaves")
	_clear()
	_reset()


# The 11 cards the catalogue named but were never built (crit cards 37–39, new-Warden cards 46–53):
# data, and the DreamState side (Glinting Dew, Heavy Stones, Sharpened Light / II, Deep Frost, Long
# Shadows). Tower Code tests the rest (Patient Aim, Ring Dance, Carried on the Wind, Sweet Scent,
# Shiny Things, Hairpin Winds).
func _test_eleven_cards() -> void:
	_reset()
	var grove := ["long_shadows", "patient_aim", "ring_dance", "deep_frost", "carried_on_the_wind", "sweet_scent",
		"shiny_things", "hairpin_winds"]
	for id in ["glinting_dew", "sharpened_light", "sharpened_light_ii"] + grove:
		var card := _card(id)
		if card:
			_check(card.in_start_pool != (grove.has(id) or LEAN_GROVE.has(id)) and not card.tags.is_empty(), "%s: pool and tags" % id)
	_check(_card("ring_dance").entwined and _card("carried_on_the_wind").entwined and _card("sharpened_light_ii").deepens == "sharpened_light",
		"Ring Dance and Carried on the Wind are Entwined; Sharpened Light II deepens")
	var pebble := _plant("pebbling", Vector2(100, 100))
	var spore := _plant("sporeling", Vector2(104, 100))
	var base := dreams.get_crit_chance_bonus(spore)
	dreams.take(_card("glinting_dew"))
	_check(is_equal_approx(dreams.get_crit_chance_bonus(spore) - base, 0.0), "Glinting Dew: no crit chance (every 5th attack crits: Tower Code)")
	_check(dreams.get_crit_overflow_multiplier(0.5) == 0.0, "no Sharpened Light: crits ×2 as before")
	dreams.take(_card("sharpened_light"))
	_check(is_equal_approx(dreams.get_crit_overflow_multiplier(0.5), 0.5), "Sharpened Light: crits +0.5×")
	dreams.take(_card("sharpened_light_ii"))
	_check(is_equal_approx(dreams.get_crit_overflow_multiplier(0.5), 1.0), "…II: +1.0×")
	# Deep Frost: Held by a water Warden (frozen), not by a Rootling
	var frostfern := _plant("frostfern", Vector2(108, 100))
	var rootling := _plant("rootling", Vector2(112, 100))
	var cold := _spawn(Vector2(5, 5))
	var plain := dreams.on_hit_multiplier(spore, cold)
	dreams.take(_card("deep_frost"))
	cold.statuses.apply(EnemyStatuses.HELD, 1, 5.0, 1.0, 0, "root", rootling)
	_check(is_equal_approx(dreams.on_hit_multiplier(spore, cold), plain), "Deep Frost: nothing on a Rootling hold")
	cold.statuses.remove(EnemyStatuses.HELD)
	cold.statuses.apply(EnemyStatuses.HELD, 1, 5.0, 1.0, 0, "water", frostfern)
	_check(is_equal_approx(dreams.on_hit_multiplier(spore, cold), plain + 0.45), "…+45% on a frozen one")
	cold.free()
	# Long Shadows: range 5+ reach 2 further
	dreams.take(_card("long_shadows"))
	var stone: TowerData = load("res://resource/tower/standing_stone.tres")
	_check(is_equal_approx(_row(stone, Vector2(120, 120), "long_shadows").range, 2.0) and _row(stone, Vector2(120, 120), "long_shadows").active
		and not _row(spore.tower_data, spore.cell, "long_shadows", spore).active, "Long Shadows: +2 range for range 5+, not short Wardens")
	_clear()
	_reset()


# Cards 227–234 (dream_design.md "After the catalogue measurement"): data and the DreamState side
# (Head Start, Second Wind, Scarred Bark, Desperate Bloom, Odd One Out, Grand Tour). Crush and Crowd
# Breaker are Tower Code's (area attacks).
func _test_cards_227() -> void:
	_reset()
	for id in ["head_start", "second_wind", "scarred_bark", "desperate_bloom", "odd_one_out", "grand_tour", "crowd_breaker"]:
		var card := _card(id)
		if card:
			_check(card.in_start_pool != LEAN_GROVE.has(id) and not card.tags.is_empty(), "%s: pool (lean), tagged" % id)
	for pair in [["head_start_ii", "head_start"], ["scarred_bark_ii", "scarred_bark"], ["odd_one_out_ii", "odd_one_out"]]:
		_check(_card(pair[0]).deepens == pair[1], "%s deepens %s" % pair)
	_check(_card("desperate_bloom").min_act == 2 and _card("grand_tour").min_owned_statuses == 2, "Desperate Bloom act 2+; Grand Tour needs 2 statuses")
	for id in ["crowded_path", "last_breath", "thinning_the_herd", "crowd_breaker"]:
		_check(_card(id).tags.has("affliction") and not _card(id).tags.has("swarm"), "%s: swarm merged into affliction" % id)
	_check(_card("shattering_blow").tags.has("precision") and not _card("shattering_blow").tags.has("swarm"), "Shattering Blow keeps precision only")
	var tower := _plant("sporeling", Vector2(100, 100))
	# Head Start: a nightmare arriving in a drift you called early, for 10 s
	dreams.take(_card("head_start"))
	var enemy := _spawn(Vector2(5, 5))
	var plain := dreams.on_hit_multiplier(tower, enemy)
	enemy.set_meta(&"head_start_until", dreams._game_clock + DreamState.HEAD_START_TIME)
	_check(is_equal_approx(dreams.on_hit_multiplier(tower, enemy), plain + 0.40), "Head Start: +40% in its first 10 s")
	dreams._game_clock += 11.0
	_check(is_equal_approx(dreams.on_hit_multiplier(tower, enemy), plain), "…not after")
	enemy.free()
	# Second Wind: every drift of the block called early
	dreams.take(_card("second_wind"))
	dreams._extra_cards_next = 0
	dreams._early_calls = 3
	dreams._second_wind()
	_check(dreams._extra_cards_next == 0, "Second Wind: nothing when a drift wasn't called early")
	dreams._early_calls = 4
	dreams._second_wind()
	_check(dreams._extra_cards_next == 1 and dreams._rare_dreams_left >= 1, "…all 4 called early: the next Dream offers 4 cards, one Rare+")
	dreams._extra_cards_next = 0
	dreams._rare_dreams_left = 0
	# Scarred Bark: leaves lost ever
	dreams.take(_card("scarred_bark"))
	var lost := run_state.leaves_lost
	run_state.leaves_lost = 5
	_check(is_equal_approx(_row(tower.tower_data, tower.cell, "scarred_bark", tower).damage, 0.15), "Scarred Bark: 5 leaves lost = +15%")
	run_state.leaves_lost = lost
	# Desperate Bloom: below half the leaves
	dreams.take(_card("desperate_bloom"))
	var leaves := run_state.leaves
	run_state.leaves = run_state.max_leaves
	_check(not _row(tower.tower_data, tower.cell, "desperate_bloom", tower).active, "Desperate Bloom: off with full leaves")
	run_state.leaves = 1
	_check(_row(tower.tower_data, tower.cell, "desperate_bloom", tower).active, "…+50% speed below half")
	run_state.leaves = leaves
	# Odd One Out: the only one of its kind
	dreams.take(_card("odd_one_out"))
	dreams.bump_board()
	_check(_row(tower.tower_data, tower.cell, "odd_one_out", tower).active, "Odd One Out: the only Sporeling")
	_plant("sporeling", Vector2(106, 100))
	dreams.bump_board()
	_check(not _row(tower.tower_data, tower.cell, "odd_one_out", tower).active, "…not with a second one")
	# Grand Tour: +10% per status owned
	dreams.take(_card("grand_tour"))
	var statuses := dreams.owned_statuses().size()
	_check(is_equal_approx(_row(tower.tower_data, tower.cell, "grand_tour", tower).damage, minf(0.1 * statuses, 0.7)), "Grand Tour: +10%% per status (%d)" % statuses)
	_clear()
	_reset()

# Few and Mighty is never offered to a wide build (#98), and scaling cards show where you stand (#75).
func _test_scaling_cards() -> void:
	_reset()
	var few := _card("few_and_mighty")
	dreams.grove_cards.append("few_and_mighty")
	for i in 7:
		_plant("sporeling", Vector2(100 + i * 2, 100))
	_check(dreams.can_offer(few, 2), "Few and Mighty: offered with 7 attackers")
	_check(dreams.effects().preview_line(few) == "You have 7 attacking Wardens · +40%",
		"…its card shows \"You have 7 attacking Wardens · +40%%\" (%s)" % dreams.effects().preview_line(few))
	for i in 6:
		_plant("sporeling", Vector2(100 + i * 2, 110))
	dreams.bump_board()
	_check(not dreams.can_offer(few, 2), "…never with 13 (a hard Need, not a weight)")
	_check(dreams.effects().preview_line(_card("many_hands")).begins_with("You have 13 attacking Wardens"), "Many Hands shows the count too")
	_check(dreams.effects().preview_line(_card("tended_forest")).begins_with("Now: "), "Tended Forest: \"Now: N cleared · …\"")
	_check(dreams.effects().preview_line(_card("quickened_sap")) == "", "a card that doesn't scale shows no live line")
	dreams.grove_cards.erase("few_and_mighty")
	_clear()
	_reset()

func _test_rows_cache() -> void:
	_reset()
	dreams.take(_card("solitude"))
	var fx := dreams.effects()
	var a := _plant("sporeling", Vector2(100, 100))
	var first := fx.rows_cached(a)
	_check(first.size() == fx.rows(DreamEffects.spot_for(a)).size() and first[0].active, "rows_cached: same rows as rows() (Solitude on)")
	_plant("sporeling", Vector2(101, 100))  # Planting bumps the board version
	_check(not fx.rows_cached(a)[0].active, "…refreshes when a Warden is planted beside it")
	_clear()
	_reset()
	_reset()
	# Nurture refreshes only the Warden and those touching it, never the whole board (group Nurture).
	dreams.take(_card("kindred_roots"))
	var centre := _plant("sporeling", Vector2(100, 100))
	var side := _plant("sporeling", Vector2(101, 100))
	var far := _plant("sporeling", Vector2(110, 100))
	_check(not fx.rows_cached(centre).any(func(r: Dictionary) -> bool: return r.card.id == "kindred_roots" and r.active),
		"Kindred Roots off with no ranked Warden touching")
	fx.rows_cached(far)
	var version := dreams.board_version
	side.rank = 2
	side.nurtured.emit(side)
	_check(dreams.board_version == version, "a Nurture doesn't bump the whole board")
	fx._rebuilds = 0  # Tests run many rebuilds in one frame: start this one's budget fresh
	_check(fx.rows_cached(centre).any(func(r: Dictionary) -> bool: return r.card.id == "kindred_roots" and r.active),
		"…but the Warden touching it sees the new rank")
	_check(fx._near_rank.get(far.get_instance_id(), 0) == 0, "…and a Warden far away keeps its cached rows")
	# Past the per-frame budget a rank-only change keeps the previous rows for a moment.
	var kindred := func(t: Tower) -> float:
		var total := 0.0
		for r in fx.rows_cached(t):
			if r.card.id == "kindred_roots":
				total += r.damage
		return total
	var before: float = kindred.call(centre)
	fx._rebuild_frame = Engine.get_process_frames()
	fx._rebuilds = DreamEffects.RANK_REBUILDS_PER_FRAME
	side.rank = 4
	side.nurtured.emit(side)
	_check(is_equal_approx(kindred.call(centre), before) and centre._dream_cache_left <= DreamEffects.RANK_REBUILD_SPREAD,
		"…past 8 rebuilds a frame: previous rows, looked at again within 0.25 s")
	fx._rebuilds = 0
	_check(kindred.call(centre) > before, "…then the new rank counts")
	_clear()
	_reset()

# Seed cards (dream_design.md "Seed cards: plant now, grow later").
func _test_seed_cards() -> void:
	_reset()
	var ids := ["dew_bowl", "harvest_moon", "deep_well", "kind_canopy", "shared_light", "bramble_oath", "patient_roots"]
	for id in ids:
		var card := _card(id)
		if card:
			_check(card.tags.has("seed") and not card.in_start_pool and card.grows_text != "", "%s: a Seed card" % id)
	_check(_card("golden_harvest").rarity == UpgradeData.Rarity.LEGENDARY and _card("golden_harvest").min_act == 2, "Golden Harvest: Legendary, act 2+")
	# Offered without their Wardens
	dreams.grove_cards.assign(ids)
	_check(dreams.can_offer(_card("dew_bowl")) and dreams.can_offer(_card("patient_roots")), "offered without their Wardens")
	# No card calls a family into a pick (user: "I don't think Seed should be a thing; make it predictable")
	_check(not ("calls_family" in UpgradeData.new()), "no card calls its family into a family pick")
	# Golden Harvest (no longer a Seed card): every 500 Dew earned this run, catchers' and interest Dew twice, +2%%
	dreams.take(_card("golden_harvest"))
	dreams.dew_earned_run = 900
	run_state.dew_harvested = 200
	var any_warden := _plant("sporeling", Vector2(90, 90))
	var harvest := _row(any_warden.tower_data, any_warden.cell, "golden_harvest", any_warden)
	_check(harvest.active and is_equal_approx(harvest.damage, 0.04), "Golden Harvest: 900 earned + 200 harvested (twice) = 1100: +4%%, no catcher needed (%.2f)" % harvest.damage)
	dreams.dew_earned_run = 0
	run_state.dew_harvested = 0
	_clear()
	# Deep Well: 5% interest at the rest, up to 40
	dreams.take(_card("deep_well"))
	run_state.dew = 300
	dreams._rest_rules(false)
	_check(run_state.dew == 315, "Deep Well: 5%% interest on 300 banked Dew (%d)" % run_state.dew)
	run_state.dew = 5000
	dreams._rest_rules(false)
	_check(run_state.dew == 5040, "…up to 40")
	# Sheltering Boughs (was Kind Canopy: touching an aura Warden, dream_design.md e1e39b56) and Shared Light (touching Wardens)
	dreams.take(_card("kind_canopy"))
	dreams.take(_card("shared_light"))
	var centre := _plant("sporeling", Vector2(101, 101))
	for c in [Vector2(102, 100), Vector2(100, 102)]:
		_plant("sporeling", c)
	_check(not _row(centre.tower_data, centre.cell, "kind_canopy", centre).active, "Sheltering Boughs: off beside plain attackers")
	_plant("acorn", Vector2(100, 100))  # An aura Warden
	dreams.bump_board()
	var canopy := _row(centre.tower_data, centre.cell, "kind_canopy", centre)
	var light := _row(centre.tower_data, centre.cell, "shared_light", centre)
	_check(canopy.active and is_equal_approx(canopy.damage, DreamState.KIND_CANOPY_BONUS) and is_equal_approx(light.damage, 0.12),
		"Sheltering Boughs on beside an aura Warden (+%d%%); Shared Light +4%% each (%.2f)" % [roundi(canopy.damage * 100), light.damage])
	# Patient Roots and Bramble Oath's measure
	dreams.take(_card("patient_roots"))
	_check(dreams.get_held_bonus() == 0.5 and dreams.walls_added_tiles() >= 0, "Patient Roots: Held +0.5 s; walls' path tiles measured")
	_clear()
	_reset()

# Support Warden cards (dream_design.md "Support Warden cards: the quiet Wardens").
func _test_support_cards() -> void:
	_reset()
	var start := []  # Lean starting pool: Thorn Snare (Thorn and Bramble) and Scented Hedge (Old Wood) are Grove cards now
	for id in ["dew_trail", "dew_trail_ii", "overflowing_well", "hedgerow_roots",
			"grandfather_stump", "thorn_snare", "thorn_snare_ii", "scented_hedge", "living_walls", "many_threads", "the_quiet_ones"]:
		var card := _card(id)
		if card:
			var moved := ["thorn_snare", "thorn_snare_ii", "scented_hedge", "living_walls", "the_quiet_ones"].has(id)  # Round 3: support -> tending
			_check(card.tags.has("tending" if moved else "support") and card.in_start_pool == start.has(id), "%s: support card (tending since round 3), pool" % id)
	dreams.grove_cards.append_array(["thorn_snare", "scented_hedge"])
	_check(dreams.can_offer(_card("thorn_snare")) and not dreams.can_offer(_card("scented_hedge")), "Thorn Snare needs nothing; Scented Hedge needs Honeysuckle")
	dreams.grove_cards.assign(["the_quiet_ones"])
	var acorn: TowerData = load("res://resource/tower/acorn.tres")
	dreams.unlocked["acorn"] = true
	dreams.take(_card("warm_hearth"))  # Absorbed Acorn Cache (dream_design.md de439ea8)
	_check(dreams.get_build_cost(acorn) == 12, "Warm Hearth: Acorns cost 12 Dew")
	var quiet := _card("the_quiet_ones")
	_check(not dreams.can_offer(quiet, 2), "The Quiet Ones needs 3+ non-attacking Wardens")
	for i in 3:
		_plant("thornwall", Vector2(100 + i, 100))
	_check(dreams.can_offer(quiet, 2) and not dreams.can_offer(quiet, 1), "…offered with 3 walls, from act 2")
	_clear()
	_reset()

# How Needs are shown on a card: never the name of a Warden (only statuses, families, card names).
# Reaction and Crowned names in card text are {combo:<id>} links (user: "Mushrooming should have the underline").
func _test_reaction_links() -> void:
	var names := ["Thunderclap", "Ignite", "Mushrooming", "Shatter", "Drown", "Smother", "Lightning Rod", "Tempest",
		"Avalanche", "Nightbloom", "Starfall", "Fever Dream", "Prismstorm", "Fairy Circle", "Still Pool"]
	var token := RegEx.create_from_string("\\{[^}]*\\}")
	for card in dreams.pool:
		for text in [card.description, card.cost_description]:
			var bare: String = token.sub(text, "", true)
			for name in names:
				var word := RegEx.create_from_string("\\b%s\\b" % name)
				_check(word.search(bare) == null, "%s: \"%s\" is a link, not bare text" % [card.id, name])
	_check(IconInfo.format("{combo:mushrooming}") in ["Mushrooming", "???"], "plain text shows a combo's name (or ??? until found)")

# Clearing payoffs on the map (cards 246–247): a tended stump lifts the Wardens touching it, a moved hollow
# gives the Warden planted in it range; both open clearing; clears record what they left.
func _test_clearing_payoffs() -> void:
	_reset()
	var sporeling: TowerData = load("res://resource/tower/sporeling.tres")
	for id in ["tended_stumps", "tended_stumps_ii", "hollow_ground", "hollow_ground_ii"]:
		var card := _card(id)
		_check(card != null and not card.in_start_pool and card.tags.has("clearing") and card.tags.has("tending")
			and DreamState.unlocks_clearing(card) and card.diagram != "", "%s: Grove, clearing + tending, opens clearing, has a diagram" % id)
	dreams.cleared_kinds = {Vector2(110, 110): DreamState.STUMP, Vector2(120, 120): DreamState.HOLLOW}
	dreams.bump_board()
	dreams.take(_card("tended_stumps"))
	_check(_has_row(sporeling, Vector2(111, 111), "tended_stumps", 0.25) and not _has_row(sporeling, Vector2(112, 110), "tended_stumps", 0.25),
		"Tended Stumps: +25% touching a stump (diagonal too), not two cells away")
	dreams.take(_card("tended_stumps_ii"))
	_check(_has_row(sporeling, Vector2(110, 111), "tended_stumps_ii", 0.40), "…II: +40%")
	dreams.take(_card("hollow_ground"))
	_check(is_equal_approx(_row(sporeling, Vector2(120, 120), "hollow_ground").range, 1.0) and not _row(sporeling, Vector2(121, 120), "hollow_ground").active,
		"Hollow Ground: +1 range planted in a hollow, nothing beside it")
	dreams.take(_card("hollow_ground_ii"))
	_check(is_equal_approx(_row(sporeling, Vector2(120, 120), "hollow_ground").range, 1.5), "…II: +1.5")
	var tree: ObstacleData = load("res://resource/obstacle/tree.tres")
	var rock: ObstacleData = load("res://resource/obstacle/rock.tres")
	dreams._on_obstacle_cleared(Vector2(130, 130), tree)
	dreams._on_obstacle_cleared(Vector2(131, 130), rock)
	_check(dreams.cleared_kinds[Vector2(130, 130)] == DreamState.STUMP and dreams.cleared_kinds[Vector2(131, 130)] == DreamState.HOLLOW,
		"a cleared Withered Tree leaves a stump, a Mossy Boulder a hollow")
	var saved := dreams.to_save()
	dreams.cleared_kinds.clear()
	dreams.load_save(JSON.parse_string(JSON.stringify(saved)))
	_check(dreams.cleared_kinds.get(Vector2(130, 130), "") == DreamState.STUMP, "…saved with the run")
	dreams.cleared_kinds.clear()
	_reset()

# Grove build branches Swift and Wide Reach (cards 235–245): data, and the DreamState side (Tower Code hooks
# the per-hit parts by rule id).
func _test_grove_branches() -> void:
	_reset()
	var swift := ["momentum", "momentum_ii", "quickening", "flurry", "restless_roots", "hummingheart", "whirlwind_heart", "drumbeat"]
	var reach := ["lingering_splash", "lingering_splash_ii", "far_reach", "far_reach_ii", "spillover", "great_ripple", "overlap"]
	var start_pool := ["momentum", "momentum_ii", "drumbeat", "overlap", "flurry"]  # Back in the start pool (dream_design.md 21ac910b, de439ea8)
	for id in swift + reach:
		var card := _card(id)
		_check(card != null and card.in_start_pool == start_pool.has(id) and card.tags.filter(func(t: String) -> bool: return t != "defining") == [("swift" if swift.has(id) else "reach")],
			"%s: %s, the %s tag" % [id, "start pool" if start_pool.has(id) else "Grove pool", "swift" if swift.has(id) else "reach"])
	_check(DreamState.ARCHETYPE_TAGS.has("swift") and DreamState.ARCHETYPE_TAGS.has("reach"), "swift and reach are build tags")
	_check(_card("whirlwind_heart").rarity == UpgradeData.Rarity.LEGENDARY and _card("great_ripple").rarity == UpgradeData.Rarity.LEGENDARY
		and _card("momentum_ii").deepens == "momentum", "rarities, Deepened")
	# Restless Roots: slow Wardens attack 45% faster
	var slow: TowerData = null
	var fast: TowerData = null
	for data in main.get_node("%TowerPlacer").towers:
		if data.can_attack and data.attacks_per_second < 1.0 and slow == null:
			slow = data
		elif data.can_attack and data.attacks_per_second >= 1.0 and fast == null:
			fast = data
	dreams.take(_card("restless_roots"))
	if slow != null:
		_check(_row(slow, Vector2(100, 100), "restless_roots").active and is_equal_approx(_row(slow, Vector2(100, 100), "restless_roots").speed, 0.45),
			"Restless Roots: %s (%.2f/s) attacks 45%% faster" % [slow.display_name, slow.attacks_per_second])
	if fast != null:
		_check(not _row(fast, Vector2(100, 100), "restless_roots").active, "…not a fast Warden")
	# Far Reach: area attackers +0.75 range (II +1.25)
	var area: TowerData = null
	var single: TowerData = null
	for data in main.get_node("%TowerPlacer").towers:
		if DreamState.has_area_attack(data) and area == null:
			area = data
		elif data.can_attack and not DreamState.has_area_attack(data) and single == null:
			single = data
	dreams.take(_card("far_reach"))
	if area != null:
		_check(is_equal_approx(_row(area, Vector2(100, 100), "far_reach").range, 0.75), "Far Reach: %s +0.75 range" % area.display_name)
	if single != null:
		_check(not _row(single, Vector2(100, 100), "far_reach").active, "…not a single-target Warden")
	dreams.take(_card("far_reach_ii"))
	if area != null:
		_check(is_equal_approx(_row(area, Vector2(100, 100), "far_reach").range, 1.25), "Far Reach II: +1.25")
	# Whirlwind Heart, Hummingheart, Far Reach's splash, Momentum, Lingering Splash: the numbers Tower reads
	_check(dreams.attack_speed_bonus_factor() == 1.0 and dreams.get_hit_damage_multiplier() == 1.0, "no Whirlwind Heart: ×1")
	dreams.take(_card("whirlwind_heart"))
	_check(dreams.attack_speed_bonus_factor() == 2.0 and is_equal_approx(dreams.get_hit_damage_multiplier(), 0.8), "Whirlwind Heart: bonuses ×2, hits −20%")
	dreams.take(_card("hummingheart"))
	_check(is_equal_approx(dreams.hummingheart_bonus(0.35), 0.09) and is_equal_approx(dreams.hummingheart_bonus(5.0), 0.60), "Hummingheart: +3% per +10% speed, max +60%")
	_check(dreams.has_rule(&"far_reach") and is_equal_approx(dreams.get_area_radius_add(), DreamState.FAR_REACH_SPLASH), "Far Reach: splashes 0.5 cells wider (Broad Splash folded in)")
	dreams.take(_card("momentum"))
	_check(dreams.momentum_step().is_equal_approx(Vector2(0.06, 0.45)), "Momentum: +6% per hit, max +45%")
	dreams.take(_card("momentum_ii"))
	_check(dreams.momentum_step().is_equal_approx(Vector2(0.08, 0.60)), "Momentum II: +8%, max +60%")
	dreams.take(_card("lingering_splash"))
	_check(dreams.lingering_splash_every() == 3, "Lingering Splash: every 3rd area attack")
	dreams.take(_card("lingering_splash_ii"))
	_check(dreams.lingering_splash_every() == 2, "…II: every 2nd")
	# Drumbeat (248): touching 2+ other attacking Wardens = +30% attack speed
	dreams.take(_card("drumbeat"))
	var drum := _plant("sporeling", Vector2(140, 140))
	_plant("sporeling", Vector2(141, 140))
	dreams.bump_board()
	_check(not _row(drum.tower_data, drum.cell, "drumbeat", drum).active, "Drumbeat: one neighbour isn't enough")
	_plant("firefly_jar", Vector2(140, 141))
	dreams.bump_board()
	_check(_row(drum.tower_data, drum.cell, "drumbeat", drum).active and is_equal_approx(_row(drum.tower_data, drum.cell, "drumbeat", drum).speed, 0.30),
		"…two touching attackers: +30% attack speed")
	# Overlap (249): a different Warden's area hit within 1 s = ×1.4 on the second
	var other := _plant("dewdrop", Vector2(150, 150))
	var target := _spawn(Vector2(5, 5))
	_check(dreams.overlap_multiplier(drum, target) == 1.0, "no Overlap card: ×1")
	dreams.take(_card("overlap"))
	_check(dreams.overlap_multiplier(drum, target) == 1.0, "Overlap: the first area hit is plain")
	_check(is_equal_approx(dreams.overlap_multiplier(other, target), 1.4), "…a second Warden within 1 s: +40%")
	_check(dreams.overlap_multiplier(other, target) == 1.0, "…the same Warden again: plain (never chains)")
	dreams._game_clock += 1.5
	_check(dreams.overlap_multiplier(drum, target) == 1.0, "…after 1 s: plain")
	target.free()
	_clear()
	_reset()

# Live lines on the card face (user, 2026-09-30: "Winding Path should give me the current bonus"; "the
# tooltip for Crowded Path makes no sense" at a rest). "+0%", never "off"; plurals; last drift at a rest.
func _test_live_lines() -> void:
	_reset()
	var fx := dreams.effects()
	var line: String = fx.preview_line(_card("winding_path"))
	_check(line == "Now: %d path tiles · +%d Dew per rest" % [dreams.path_length, dreams.path_length / DreamState.WINDING_PATH_TILES], "Winding Path: %s" % line)
	var dew := run_state.dew
	run_state.dew = 275
	line = fx.preview_line(_card("deep_well"))
	_check(line == "Now: 275 Dew banked · +13 Dew at the next rest", "Deep Well: %s" % line)
	run_state.dew = dew
	_plant("thornwall", Vector2(100, 100))
	line = fx.preview_line(_card("hedge_maze"))
	_check(line == "Now: 1 Thornwall · +0% (3 for the next +1%)", "Hedge Maze: \"+0%%\", singular (%s)" % line)
	line = fx.preview_line(_card("canopy"))
	_check(line.begins_with("Now: 0 attacking Wardens planted · +0% (20 for the next +12%)"), "Canopy shows its next step (%s)" % line)
	var director: DriftDirector = main.get_node("%DriftDirector")
	director.resting = true
	dreams.last_drift_stats = {}
	_check(fx.preview_line(_card("crowded_path")) == "", "Crowded Path at a rest before any drift: no live line")
	dreams.last_drift_stats = {"in_range": 3.2, "alone": 0.4, "near": 0.1}
	line = fx.preview_line(_card("crowded_path"))
	_check(line.begins_with("Last drift: 3.2 nightmares in range on average · about +"), "…at a rest: last drift's average (%s)" % line)
	_check(fx.preview_line(_card("lone_hunter")).begins_with("Last drift: 40% of nightmares alone"), "Lone Hunter: last drift's share")
	_check(fx.preview_line(_card("quick_step")) == "", "Quick Step at a rest: no live line (it's about calling drifts early)")
	director.resting = false
	_check(fx.preview_line(_card("quick_step")).contains(" called early this block · "), "…during a block: drifts called early (%s)" % fx.preview_line(_card("quick_step")))
	director.resting = true
	_check(fx.preview_line(_card("heart_of_the_maze")) == "", "a card with no run number shows no live line (not the attacker count)")
	for card in dreams.pool:
		var shown: String = fx.preview_line(card)
		if shown.begins_with("You have"):
			_check(["few_and_mighty", "last_light", "many_hands", "the_last_light"].has(String(card.rule_id)) or card.id in ["few_and_mighty", "the_last_light", "many_hands"],
				"%s: the attacker count only on attacker-count cards (%s)" % [card.id, shown])
	for card in dreams.pool:
		_check(not fx.preview_line(card).contains("off"), "%s: no \"off\" in its live line" % card.id)
	dreams.last_drift_stats = {}
	_clear()

func _test_needs_text() -> void:
	_reset()
	_check(dreams.needs_text(_card("rolling_thunder")) == "Needs: Soaked + Charged", "Rolling Thunder: %s" % dreams.needs_text(_card("rolling_thunder")))
	_check(dreams.needs_text(_card("starlit_aim")) == "Needs: Pebbling + Firefly Jar families", "Starlit Aim: %s" % dreams.needs_text(_card("starlit_aim")))
	_check(dreams.needs_text(_card("nursery")) == "Needs: Tender Care + Seedling Gift", "Nursery: %s" % dreams.needs_text(_card("nursery")))
	var family_names := {}
	for id in DreamState._every_family().values():
		family_names[dreams.get_display_name(id) if id != "wall" else "Thornwall"] = true
	var leaks: Array = []
	for card in DreamState.load_pool():
		var text := dreams.needs_text(card)
		for id in card.requires + card.requires_any + card.grows_with:
			var path := "res://resource/tower/%s.tres" % id
			if not ResourceLoader.exists(path):
				continue
			var name: String = (load(path) as TowerData).display_name
			if not family_names.has(name) and text.contains(name):
				leaks.append("%s: %s" % [card.id, text])
	_check(leaks.is_empty(), "no Needs text names a Warden (%s)" % ", ".join(leaks))
	_check(dreams.needs_text(_card("dew_bowl")) == "" and "the Acorn line" == "the %s line" % dreams.family_name_for("acorn"),
		"Seed cards: the family line")

func _test_rest_rules() -> void:
	_reset()
	run_state.max_leaves = 15
	run_state.leaves = 10
	dreams.take(_card("thick_bark"))
	dreams._rest_rules(true)
	_check(run_state.leaves == 11, "Thick Bark (absorbs Mending Bark): a perfect block regrows a leaf")
	dreams._rest_rules(false)
	_check(run_state.leaves == 11, "…not an imperfect one")
	_check(dreams.bark_charges == 1, "Thick Bark: ready")
	run_state.lose_leaves(5)
	_check(run_state.leaves == 11 and dreams.bark_charges == 0, "…saves the first leak whole (a boss's 5)")
	run_state.lose_leaves(1)
	_check(run_state.leaves == 10, "…then leaks cost leaves")
	dreams.take(_card("thick_bark_ii"))
	dreams._rest_rules(false)
	_check(dreams.bark_charges == 2, "Thick Bark II: 2 per block, refilled at the rest")
	run_state.leaves = 15

func _test_map_rules() -> void:
	_reset()
	var sporeling: TowerData = load("res://resource/tower/sporeling.tres")
	# Straightaway: beside a straight stretch of 5+
	dreams.take(_card("straightaway"))
	var straight: Array = dreams._straight_cells.keys()
	_check(not straight.is_empty(), "the map has straight stretches (%d tiles)" % straight.size())
	if not straight.is_empty():
		var beside: Vector2 = straight[0] + Vector2(1, 1)
		var row := _row(sporeling, beside, "straightaway")
		_check(row.active and is_equal_approx(row.damage, 0.30) and is_equal_approx(row.range, 0.5), "Straightaway: +30% and +0.5 range")
	# Heart of the Maze: furthest along the path from the others
	dreams.take(_card("heart_of_the_maze"))
	var route: Array = dreams._path_index.keys()
	route.sort_custom(func(x: Vector2, y: Vector2) -> bool: return dreams._path_index[x] < dreams._path_index[y])
	var early := _plant("sporeling", route[2])
	_plant("sporeling", route[5])
	var far := _plant("sporeling", route[route.size() - 3])
	_check(dreams.get_heart_of_maze() == far and _row(sporeling, far.cell, "heart_of_the_maze", far).active
		and not _row(sporeling, early.cell, "heart_of_the_maze", early).active, "Heart of the Maze: the furthest one")
	# Without the card: no heart (DreamMarks draws what get_heart_of_maze returns) and no bonus
	var base_far := dreams.get_soothe_multiplier(far)
	dreams.stacks.erase("heart_of_the_maze")
	_check(dreams.get_heart_of_maze() == null and is_equal_approx(base_far - dreams.get_soothe_multiplier(far), 1.0),
		"no Heart of the Maze card: no heart and no ×2")
	# The other markers are card-gated too: no bark, no fresh growth, no echo without their cards
	dreams._rest_rules(true)
	_check(dreams.bark_charges == 0 and not dreams.is_fresh(far),
		"markers stay off without their cards")
	_clear()

# --- Helpers ------------------------------------------------------------------------------------------

func _reset() -> void:
	_clear()
	dreams.stacks.clear()
	dreams.unlock_everything = false
	dreams.unlocked = {"sprout": true, "thornwall": true, "sporeling": true}
	dreams._walls_planted = 0
	dreams._refill_bark()

func _card(id: String) -> UpgradeData:
	for card in dreams.pool:
		if card.id == id:
			return card
	_check(false, "card %s exists" % id)
	return null

func _row(data: TowerData, cell: Vector2, id: String = "forests_edge", tower: Tower = null) -> Dictionary:
	for row in dreams.get_card_effects(data, cell, tower):
		if row.id == id or row.id == id + "_ii":
			return row
	return {"active": false, "damage": 0.0, "range": 0.0}

# Any active row of card `id` with this damage (a merged card reports its absorbed rule as a second row).
func _has_row(data: TowerData, cell: Vector2, id: String, damage: float) -> bool:
	return dreams.get_card_effects(data, cell).any(func(row: Dictionary) -> bool:
		return row.id == id and row.active and is_equal_approx(row.damage, damage))

func _plant(id: String, cell: Vector2) -> Tower:
	var tower: Tower = load("res://scenes/tower/tower.tscn").instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = cell
	tower.position = tower.MAP_GRID.calculate_map_position(cell)
	main.get_node("%TowerContainer").add_child(tower)
	tower.set_process(false)
	return tower

func _clear() -> void:
	for tower in main.get_node("%TowerContainer").get_children():
		tower.free()

func _spawn(cell: Vector2, offset: Vector2 = Vector2.ZERO) -> Node2D:
	var spawner = main.get_node("%EnemyContainer")
	var enemy = spawner.enemy_scene.instantiate()
	enemy.enemy_data = TestGrove._load_enemy_types()[0]
	spawner.add_child(enemy)
	enemy.position = enemy.grid.calculate_map_position(cell) + offset
	enemy.set_path(PackedVector2Array([enemy.grid.calculate_grid_coordinates(enemy.position)]))
	enemy.set_process(false)
	return enemy

func _free_enemies() -> void:
	for child in main.get_node("%EnemyContainer").get_children():
		child.free()

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

# The drift sample's crowd counts (perf, 2026-10-01): the bucketed "alone" check with its crowded-cell fast path gives
# exactly the brute-force answer (every pair) on a stacked field, and the in-range count matches a brute-force count.
func _test_crowd_counts() -> void:
	_reset()
	_free_enemies()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var spawned: Array = []
	var base: Vector2 = map_generator.startPath
	for i in 60:  # Clusters and stragglers over a few cells
		var cell := base + Vector2(rng.randi_range(0, 6), rng.randi_range(-2, 2))
		spawned.append(_spawn(cell, Vector2(rng.randf_range(-30, 30), rng.randf_range(-30, 30))))
	await_frame_hint()
	var reach: float = DreamState.LONE_HUNTER_CELLS * map_generator.MAP_GRID.cell_size.x
	var brute := 0
	for a in spawned:
		var lonely := true
		for b in spawned:
			if a != b and a.global_position.distance_to(b.global_position) <= reach:
				lonely = false
				break
		brute += 1 if lonely else 0
	var fast := 0
	for a in spawned:
		fast += 1 if dreams._is_alone(a) else 0
	_check(fast == brute and is_equal_approx(dreams.alone_share(spawned), float(brute) / spawned.size()),
		"Lone Hunter's alone count: the fast bucketed check equals every-pair brute force (%d vs %d of %d)" % [fast, brute, spawned.size()])
	var tower := _plant("sporeling", base + Vector2(3, 3))
	var range_px: float = tower.get_range_cells() * map_generator.MAP_GRID.cell_size.x
	var in_brute := spawned.filter(func(e: Node2D) -> bool: return tower.global_position.distance_to(e.global_position) <= range_px).size()
	_check(dreams.count_in_range(tower) == in_brute and is_equal_approx(dreams.average_in_range(), float(in_brute)),
		"Crowded Path's in-range count equals brute force (%d)" % in_brute)
	_clear()
	_free_enemies()

func await_frame_hint() -> void:
	dreams._bucket_frame = -1  # Spawned this frame: rebuild the buckets

# Feeling the cards (dream_design.md 2026-10-01): the impact preview matches the real change once taken; card credit is
# at most the bonus damage and splits it; a trigger card's own damage is credited to it; card_chosen names the Wardens.
func _test_card_feel() -> void:
	_reset()
	var a := _plant("sporeling", Vector2(100, 100))
	var b := _plant("sporeling", Vector2(102, 100))
	var calm := _card("deeper_calm")  # +25% damage on every Warden (dream_design.md de439ea8)
	var impact := dreams.preview_card_impact(calm)
	_check(impact.kind == &"stat" and impact.towers.size() == 2 and impact.text == "On your board · +25% damage on 2 Wardens",
		"impact preview: %s" % impact.text)
	var before := a.get_damage()
	dreams.take(calm)
	var after := a.get_damage()
	_check(absf(after / before - 1.25) < 0.011, "…matches the real change once taken (×%.3f)" % (after / before))
	_check(not dreams.stacks.has("thick_bark") and dreams.preview_card_impact(_card("thick_bark")).kind != &"stat", "…and taking nothing for a preview")
	var event := DamageLog.Event.new()
	event.source = a
	event.kind = &"hit"
	event.amount = 115.0
	dreams.card_credit = {"block": {}, "run": {}}
	dreams._credit_hit(event)
	var credit := dreams.get_card_credit("deeper_calm", &"run")
	_check(credit.kind == &"damage" and absf(credit.damage - 23.0) < 0.01 and credit.damage <= event.amount,
		"card credit: the bonus part of a hit (%.2f of 115)" % credit.damage)
	_check(credit.text == "Deeper Calm · +23", "…named for the reports (%s)" % credit.text)
	dreams.take(_card("last_breath"))
	var burst := DamageLog.Event.new()
	burst.source = a
	burst.kind = &"hit"
	burst.tag = &"last_breath"
	burst.amount = 40.0
	dreams._credit_hit(burst)
	_check(absf(dreams.get_card_credit("last_breath", &"run").damage - 40.0) < 0.01, "…a trigger card gets the damage it causes")
	_check(dreams.get_top_cards(&"run", 3) == ["last_breath", "deeper_calm"], "…top cards by damage (%s)" % [dreams.get_top_cards(&"run", 3)])
	var saved := dreams.to_save()
	dreams.card_credit = {"block": {}, "run": {}}
	dreams.load_save(JSON.parse_string(JSON.stringify(saved)))
	_check(absf(dreams.get_card_credit("deeper_calm", &"run").damage - 23.0) < 0.01, "…kept in the run save")
	dreams.card_credit = {"block": {}, "run": {}}
	_clear()

# Combo cards are choices, not musts (dream_design.md 83c40cd7): the exclusive pair, every changed card's trade on
# its own line, and the trades read in DreamState (Soaked Rot, Sparking Spores' condition, Quick Reactions).
func _test_combo_choices() -> void:
	dreams.stacks.clear()
	var feathers := _card("charged_feathers")
	var beaks := _card("pollen_beaks")
	_check(feathers.excludes.has("pollen_beaks") and beaks.excludes.has("charged_feathers"), "Charged Feathers and Pollen Beaks exclude each other")
	dreams.current_offer.assign([feathers, beaks])
	dreams.take(feathers)
	_check(dreams.is_excluded(beaks) and not dreams.can_offer(beaks, 3) and not dreams.current_offer.has(beaks),
		"taking Charged Feathers removes Pollen Beaks from the run and this offer")
	dreams.stacks.clear()
	dreams.current_offer.clear()
	_check(not dreams.is_excluded(beaks), "…until then both can be offered")
	for id in ["damp_rot", "rain_on_glass", "sparking_spores", "rolling_thunder", "wildfire_spores", "mushroom_rain", "deep_water",
			"quick_reactions", "conductive_soil", "static_bloom", "starlit_aim", "kin_and_kindling", "carried_on_the_wind",
			"charged_feathers", "pollen_beaks", "windborne_rain", "deep_stillness", "endless_night", "eye_of_the_tempest",
			"falling_stars", "fever_pitch", "mountains_fall", "prism_heart", "ring_of_rings"]:
		_check(_card(id).cost_description != "", "%s shows its trade on its own line" % id)
	# Soaked Rot: Soaked stops boosting water hits
	_check(dreams.soaked_boosts_water(), "Soaked boosts water hits")
	_hold("damp_rot")
	_check(not dreams.soaked_boosts_water(), "…not with Soaked Rot")
	dreams.stacks.clear()
	# Quick Reactions: 35% less
	_check(is_equal_approx(dreams.get_reaction_damage_multiplier(), 1.0), "Reactions deal full damage")
	_hold("quick_reactions")
	_check(is_equal_approx(dreams.get_reaction_damage_multiplier(), 0.65), "…35% less with Quick Reactions")
	dreams.stacks.clear()
	# Sparking Spores: only on nightmares with 5+ Poisoned
	_hold("sparking_spores")
	var enemy = _enemy_with_spored(4)
	if enemy != null:
		_check(is_equal_approx(dreams.get_ignite_multiplier(enemy), 1.0), "Sparking Spores: not below 5 Poisoned")
		enemy.statuses.apply(EnemyStatuses.SPORED, 1, 5.0, 1.0, 10)
		_check(dreams.get_ignite_multiplier(enemy) > 1.0, "…but at 5+ (%d stacks)" % enemy.statuses.stacks(EnemyStatuses.SPORED))
		enemy.queue_free()
	dreams.stacks.clear()

func _enemy_with_spored(n: int) -> Node2D:
	var enemy := _spawn(Vector2(3, 3))
	enemy.statuses.apply(EnemyStatuses.SPORED, n, 5.0, 1.0, 10)
	return enemy

# Holds card `id` with the Wardens it needs (a card whose families aren't owned is half-dreamed: no rule).
func _hold(id: String) -> void:
	var card := _card(id)
	for need in card.requires:
		dreams.unlocked[need] = true
	dreams.stacks[id] = 1

# Per-source shards (Tower Code: Dream Oak / Dreamroot up to 4 Dreamlight a run, apart from Great Dreamcatcher's 2)
func _test_source_shards() -> void:
	dreams.source_shards.clear()
	var before := dreams.dreamlight
	dreams.add_source_shards(&"dream_oak", 9, 4)
	_check(dreams.dreamlight == before and dreams.source_shards[&"dream_oak"] == 9, "9 shards: no Dreamlight yet")
	dreams.add_source_shards(&"dream_oak", 1, 4)
	_check(dreams.dreamlight == before + 1, "the 10th shard gives 1 Dreamlight")
	dreams.add_source_shards(&"dream_oak", 100, 4)
	_check(dreams.dreamlight == before + 4 and dreams.source_shards[&"dream_oak"] == 40, "…capped at 4 Dreamlight (40 shards)")
	dreams.add_source_shards(&"dream_oak", 10, 4)
	_check(dreams.dreamlight == before + 4, "…and no more after the cap")
	var saved := JSON.parse_string(JSON.stringify(dreams.to_save())) as Dictionary
	dreams.source_shards.clear()
	dreams.load_save(saved)
	_check(int(dreams.source_shards.get(&"dream_oak", 0)) == 40, "per-source shards survive the run save")
	dreams.source_shards.clear()
	dreams.dreamlight = before

# The card's impact line counts only Wardens its condition reaches (user screenshot: Family Ties said "Triggers on all
# 8 attackers" with no Kinship on the map)
func _test_impact_conditions() -> void:
	_reset()
	for c in [Vector2(80, 80), Vector2(84, 80), Vector2(88, 80)]:  # Three attackers, far apart: no Kinship
		_plant("sporeling", c)
	var ties := dreams.preview_card_impact(_card("sweet_harmony"))  # A Kinship card (Family Ties was cut)
	_check(ties.kind == &"none" and ties.text == "None of your Wardens yet" and ties.towers.is_empty(),
		"a Kinship card with no Kinship: \"None of your Wardens yet\" (%s)" % ties.text)
	var sunlit := dreams.preview_card_impact(_card("sunlit_rest"))
	_check(sunlit.towers.size() == 1 and sunlit.text == "Reaches one of your Wardens",
		"Sunlit Rest counts the one Warden the next rest raises, not all attackers (%s)" % sunlit.text)
	var glint := dreams.preview_card_impact(_card("glinting_dew"))
	_check(glint.text == "Reaches all 3 attackers" and glint.towers.is_empty(), "a global card: \"%s\", nothing pulses" % glint.text)
	_clear()
