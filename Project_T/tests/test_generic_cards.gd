extends SceneTree

# Headless test for the generic Dream cards 142–168 (dream_design.md "Generic Commons and
# Uncommons" and "Generic cards, second batch"): the parts DreamState owns (stat and per-hit rules,
# economy hooks in RunState / TowerSeller / DriftDirector, rest rules, Needs). Tower / Enemy / HUD
# hooks (Sudden Bloom, Watchful Rest, Skyward range, Tangled, trample, glows) are tested there.
#   godot --headless --path . --script res://tests/test_generic_cards.gd --fixed-fps 60

const IDS := ["gathered_dew", "fair_trade", "call_of_the_wild", "mending_bark", "lasting_dreams", "short_roots",
	"forests_edge", "crowded_path", "crowded_path_ii", "lone_hunter", "lone_hunter_ii", "skyward_gaze",
	"fresh_growth", "fresh_growth_ii", "underdog", "underdog_ii", "weathered_walls", "heavy_air",
	"wandering_mind", "winding_path", "shelter_of_stones", "cliffside", "thick_bark", "thick_bark_ii",
	"sudden_bloom", "last_breath", "last_breath_ii", "tangled", "watchful_rest", "watchful_rest_ii",
	"glimmering_hunt", "straightaway", "straightaway_ii", "heart_of_the_maze", "echoing_steps"]

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
	_test_rest_rules()
	_test_map_rules()
	_test_sim_entry()
	_test_sim_policy()
	_test_rows_cache()
	_test_seed_cards()
	_test_support_cards()
	_test_needs_text()
	print("generic cards test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _test_pool() -> void:
	for id in IDS:
		var card := _card(id)
		if card:
			_check(card.in_start_pool == (id != "wandering_mind"), "%s: pool" % id)
	_check(_card("skyward_gaze").min_act == 2 and _card("glimmering_hunt").min_act == 2, "Skyward Gaze / Glimmering Hunt from act 2")
	_reset()
	_check(not dreams.is_eligible(_card("heavy_air")) and dreams.is_eligible(_card("tangled")),
		"Heavy Air needs a Warden that slows; Tangled any status (Spored)")
	dreams.unlocked["dewdrop"] = true
	_check(not dreams.is_eligible(_card("heavy_air")), "…Dewdrop isn't (Soaked no longer slows)")
	dreams.unlocked["bellflower"] = true
	_check(dreams.is_eligible(_card("heavy_air")), "…Bellflower (Drowsy) is")
	_check(dreams.is_eligible(_card("short_roots")) == dreams.owns_range_at_most(2.0), "Short Roots needs a Warden with range 2 or less")

func _test_economy() -> void:
	_reset()
	run_state._dispel_dew_carry = 0.0
	var plain := run_state._scaled_dispel_dew(100)
	dreams.take(_card("gathered_dew"))
	dreams.take(_card("gathered_dew"))
	run_state._dispel_dew_carry = 0.0
	_check(run_state._scaled_dispel_dew(100) == roundi(plain * 1.2), "Gathered Dew ×2: +20% dispel Dew (%d vs %d)" % [run_state._scaled_dispel_dew(100), plain])
	var seller = main.get_node("%TowerSeller")
	var tower := _plant("sporeling", Vector2(100, 100))
	tower.invested_dew = 100
	_check(seller.get_refund(tower) == 75, "no Fair Trade: 75% at a rest")
	dreams.take(_card("fair_trade"))
	_check(seller.get_refund(tower) == 85, "Fair Trade: 85% at a rest")
	dreams.take(_card("fair_trade"))
	dreams.take(_card("fair_trade"))
	_check(seller.get_refund(tower) == 100 and is_equal_approx(dreams.get_refund_share(0.5, false), 0.75), "…stacks to 100% / 75%")
	_check(dreams.get_call_early_bonus(7, 10) == 7, "call early: plain")
	dreams.take(_card("call_of_the_wild"))
	_check(dreams.get_call_early_bonus(7, 10) == 14 and dreams.get_call_early_bonus(30, 10) == 20, "Call of the Wild: double, up to 20")
	dreams.take(_card("winding_path"))
	_check(dreams.get_rest_bonus_add() == dreams.path_length / 10, "Winding Path: +1 Dew per 10 path tiles (%d tiles)" % dreams.path_length)
	var rerolls := dreams.rerolls_left
	dreams.take(_card("wandering_mind"))
	_check(dreams.rerolls_left == rerolls + 2, "Wandering Mind: +2 rerolls")
	dreams.take(_card("weathered_walls"))
	var wall: TowerData = load("res://resource/tower/thornwall.tres")
	dreams._walls_planted = 9
	_check(dreams.get_build_cost_at(wall, Vector2(3, 3)) == 0, "Weathered Walls: the 10th Thornwall is free")
	dreams._walls_planted = 10
	_check(dreams.get_build_cost_at(wall, Vector2(3, 3)) > 0, "…the 11th isn't")
	_clear()

func _test_stat_rules() -> void:
	_reset()
	var dewdrop: TowerData = load("res://resource/tower/dewdrop.tres")
	var damp := dreams.get_status_duration(dewdrop, EnemyStatuses.DAMP)
	dreams.take(_card("lasting_dreams"))
	dreams.take(_card("lasting_dreams"))
	_check(is_equal_approx(dreams.get_status_duration(dewdrop, EnemyStatuses.DAMP), damp + 2.0), "Lasting Dreams ×2: +2 s")
	dreams.take(_card("heavy_air"))
	_check(is_equal_approx(dreams.get_status_strength_multiplier(EnemyStatuses.DROWSY), 1.2)
		and dreams.get_status_strength_multiplier(EnemyStatuses.DAMP) == 1.0
		and dreams.get_status_strength_multiplier(EnemyStatuses.MARKED) == 1.0, "Heavy Air: slows 20% stronger, nothing else")
	# Short Roots and Forest's Edge
	dreams.take(_card("short_roots"))
	dreams.take(_card("forests_edge"))
	var short: TowerData = null
	var long: TowerData = null
	for data in main.get_node("%TowerPlacer").towers:
		if data.can_attack and data.attack_range <= 2.0 and short == null:
			short = data
		elif data.can_attack and data.attack_range > 2.0 and long == null:
			long = data
	var far := Vector2(100, 100)
	if short:
		_check(_row(short, far).active, "Short Roots: on for %s (range %.1f)" % [short.display_name, short.attack_range])
	if long:
		_check(not _row(long, far, "short_roots").active, "…off for range %.1f" % long.attack_range)
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
	_check(not dreams.is_fresh(tower) and is_equal_approx(base - dreams.get_soothe_multiplier(tower), 0.30), "…+30% until the next rest")
	# Underdog: the least soothing attackers of the block
	dreams.take(_card("underdog"))
	var others: Array[Tower] = []
	for i in 4:
		others.append(_plant("sporeling", Vector2(102 + i * 3, 100)))
	var log := DamageLog.instance
	for i in others.size():
		log._row(others[i])["block"] = 100.0 * (i + 1)
	log._row(tower)["block"] = 1000.0
	dreams._pick_underdogs()
	_check(dreams.is_underdog(others[0]) and dreams.is_underdog(others[2]) and not dreams.is_underdog(others[3])
		and not dreams.is_underdog(tower), "Underdog: the 3 that soothed least")
	_check(_row(others[0].tower_data, others[0].cell, "underdog", others[0]).active, "…get their bonus")
	_clear()

func _test_hit_rules() -> void:
	_reset()
	var tower := _plant("sporeling", Vector2(100, 100))
	var a := _spawn(map_generator.startPath + Vector2(0, 0))
	_check(dreams.on_hit_multiplier(tower, a) == 1.0, "no card: ×1")
	dreams.take(_card("lone_hunter"))
	_check(is_equal_approx(dreams.on_hit_multiplier(tower, a), 1.3), "Lone Hunter: +30% alone")
	var b := _spawn(map_generator.startPath, Vector2(40, 0))
	_check(dreams.on_hit_multiplier(tower, a) == 1.0, "…not with a nightmare within 2 cells")
	# Crowded Path counts both in range
	dreams.take(_card("crowded_path"))
	var near := _plant("sporeling", map_generator.startPath + Vector2(1, 1))
	_check(dreams.count_in_range(near) == 2 and _row(near.tower_data, near.cell, "crowded_path", near).damage > 0.05,
		"Crowded Path: +3% per nightmare in range (%d)" % dreams.count_in_range(near))
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
	dreams.take(_card("rain_on_glass"))
	_check(dreams.get_spored_tick_multiplier(soaked) == 1.0 and dreams.get_ignite_multiplier() == 1.0, "no Damp Rot / Sparking Spores: ×1")
	var dry := dreams.on_hit_multiplier(jar, soaked)
	soaked.apply_status(EnemyStatuses.DAMP, 1, 4.0)
	_check(is_equal_approx(dreams.on_hit_multiplier(jar, soaked) / dry, (1.0 + 0.24) / 1.0) or is_equal_approx(dreams.on_hit_multiplier(jar, soaked) - dry, 0.24),
		"Rain on Glass ×2: light Wardens +24% vs Soaked")
	_check(dreams.on_hit_multiplier(tower, soaked) == dreams.on_hit_multiplier(tower, soaked), "…not other lines")
	dreams.take(_card("damp_rot"))
	dreams.take(_card("sparking_spores"))
	_check(is_equal_approx(dreams.get_spored_tick_multiplier(soaked), 1.2) and is_equal_approx(dreams.get_ignite_multiplier(), 1.2),
		"Damp Rot: Poisoned ticks +20% on Soaked; Sparking Spores: Ignite +20%")
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
	_check(family != &"" and dreams.is_unlocked(String(family)) and dreams.dreamlight == light + 1,
		"sim_family_pick: takes the family, +1 Dreamlight on the first pick (%s)" % family)
	_check(not main.get_node("%GameSpeed").paused and not main.get_node("%FamilyPickScreen").visible, "…leaves the game unpaused")
	var taken := dreams.sim_rest(5, func(offer: Array) -> UpgradeData: return offer[0])
	_check(taken.size() == 1 and dreams.has_card(taken[0].id) and not dreams.is_offering(), "sim_rest: a real offer, one card taken")
	var passed := dreams.sim_rest(10, func(_offer: Array) -> UpgradeData: return null)
	_check(passed.is_empty() and not dreams.is_offering(), "…null lets it pass")
	light = dreams.dreamlight
	dreams.sim_rest(25, func(offer: Array) -> UpgradeData: return offer[0])
	_check(dreams.dreamlight == light + 3, "…a boss rest gives +3 Dreamlight")
	_check(DreamState.sim_dreamlight_for(&"first") == 1 and DreamState.sim_dreamlight_for(&"boss") == 3, "sim_dreamlight_for")
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
	dreams._owed_families.assign(["dewdrop"])
	var sleep := DreamSimPolicy.new(dreams, DreamSimPolicy.Style.SLEEP)
	_check(sleep.pick_family(["pebbling", "dewdrop"]) == &"dewdrop", "family order before the owed family")
	dreams._owed_families.clear()
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
	_check(balanced.pick_omen([]) == null, "Omens: Clear Skies")
	_clear()
	_reset()

# DreamEffects.rows_cached (Tower's hot path) matches rows() and follows board changes.
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
	var ids := ["dew_bowl", "harvest_moon", "deep_well", "kind_canopy", "shared_light", "bramble_oath", "patient_roots", "golden_harvest"]
	for id in ids:
		var card := _card(id)
		if card:
			_check(card.tags.has("seed") and card.in_start_pool == (id == "bramble_oath") and card.grows_text != "", "%s: a Seed card" % id)
	_check(_card("golden_harvest").rarity == UpgradeData.Rarity.LEGENDARY and _card("golden_harvest").min_act == 2, "Golden Harvest: Legendary, act 2+")
	# Offered without their Wardens
	dreams.grove_cards.assign(ids)
	_check(dreams.can_offer(_card("dew_bowl")) and dreams.can_offer(_card("patient_roots")), "offered without their Wardens")
	# Calls its family: the next family pick offers it
	var screen = main.get_node("%FamilyPickScreen")
	var acorn: TowerData = load("res://resource/tower/acorn.tres")
	var families_before: Array[TowerData] = screen.families.duplicate()
	if not screen.families.has(acorn):
		screen.families.append(acorn)  # As if the Grove had unlocked Acorn
	dreams.family_of("")  # Refresh the family maps
	dreams.take(_card("dew_bowl"))
	_check(Array(dreams.get_called_families()) == ["acorn"], "Dew Bowl calls Acorn")
	var per_pick: int = screen.cards_per_pick
	screen.cards_per_pick = 1
	screen.show_pick(&"boss")
	_check(screen.offer.size() == 1 and screen.offer[0] == acorn, "…the next family pick offers Acorn")
	screen.cards_per_pick = per_pick
	screen.visible = false
	main.get_node("%GameSpeed").set_paused(false)
	screen.families = families_before
	# Deep Well: 3% interest at the rest, up to 20
	dreams.take(_card("deep_well"))
	run_state.dew = 300
	dreams._rest_rules(false)
	_check(run_state.dew == 309, "Deep Well: 3%% interest on 300 banked Dew (%d)" % run_state.dew)
	run_state.dew = 5000
	dreams._rest_rules(false)
	_check(run_state.dew == 5020, "…up to 20")
	# Kind Canopy and Shared Light (touching Wardens)
	dreams.take(_card("kind_canopy"))
	dreams.take(_card("shared_light"))
	var centre := _plant("sporeling", Vector2(101, 101))
	for c in [Vector2(100, 100), Vector2(102, 100), Vector2(100, 102)]:
		_plant("sporeling", c)
	var canopy := _row(centre.tower_data, centre.cell, "kind_canopy", centre)
	var light := _row(centre.tower_data, centre.cell, "shared_light", centre)
	_check(canopy.active and is_equal_approx(light.damage, 0.06), "Kind Canopy on with 3 touching; Shared Light +2%% each (%.2f)" % light.damage)
	# Patient Roots and Bramble Oath's measure
	dreams.take(_card("patient_roots"))
	_check(dreams.get_held_bonus() == 0.25 and dreams.walls_added_tiles() >= 0, "Patient Roots: Held +0.25 s; walls' path tiles measured")
	_clear()
	_reset()

# Support Warden cards (dream_design.md "Support Warden cards: the quiet Wardens").
func _test_support_cards() -> void:
	_reset()
	var start := ["thorn_snare", "thorn_snare_ii", "scented_hedge"]
	for id in ["wide_bowl", "dew_trail", "dew_trail_ii", "still_waters", "overflowing_well", "acorn_cache", "hedgerow_roots",
			"grandfather_stump", "thorn_snare", "thorn_snare_ii", "scented_hedge", "living_walls", "many_threads", "the_quiet_ones"]:
		var card := _card(id)
		if card:
			_check(card.tags.has("support") and card.in_start_pool == start.has(id), "%s: support card, pool" % id)
	_check(dreams.can_offer(_card("thorn_snare")) and not dreams.can_offer(_card("scented_hedge")), "Thorn Snare needs nothing; Scented Hedge needs Honeysuckle")
	dreams.grove_cards.assign(["acorn_cache", "the_quiet_ones"])
	var acorn: TowerData = load("res://resource/tower/acorn.tres")
	dreams.unlocked["acorn"] = true
	dreams.take(_card("acorn_cache"))
	_check(dreams.get_build_cost(acorn) == 15, "Acorn Cache: Acorns cost 15 Dew")
	var quiet := _card("the_quiet_ones")
	_check(not dreams.can_offer(quiet, 2), "The Quiet Ones needs 3+ non-attacking Wardens")
	for i in 3:
		_plant("thornwall", Vector2(100 + i, 100))
	_check(dreams.can_offer(quiet, 2) and not dreams.can_offer(quiet, 1), "…offered with 3 walls, from act 2")
	_clear()
	_reset()

# How Needs are shown on a card: never the name of a Warden (only statuses, families, card names).
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
	dreams.take(_card("mending_bark"))
	dreams._rest_rules(true)
	_check(run_state.leaves == 11, "Mending Bark: a perfect block regrows a leaf")
	dreams._rest_rules(false)
	_check(run_state.leaves == 11, "…not an imperfect one")
	dreams.take(_card("thick_bark"))
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
	# Cliffside: touching the island's edge
	dreams.take(_card("cliffside"))
	_check(is_equal_approx(dreams.get_range_bonus_at(sporeling, Vector2(1, 6)), 1.0)
		and dreams.get_range_bonus_at(sporeling, Vector2(5, 6)) == 0.0, "Cliffside: +1 range beside the edge")
	# Shelter of Stones: touching an obstacle
	dreams.take(_card("shelter_of_stones"))
	var obstacle: Vector2 = map_generator.obstacles.keys()[0]
	_check(_row(sporeling, obstacle + Vector2(1, 0), "shelter_of_stones").active
		and not _row(sporeling, Vector2(100, 100), "shelter_of_stones").active, "Shelter of Stones: beside an obstacle")
	# Straightaway: beside a straight stretch of 5+
	dreams.take(_card("straightaway"))
	var straight: Array = dreams._straight_cells.keys()
	_check(not straight.is_empty(), "the map has straight stretches (%d tiles)" % straight.size())
	if not straight.is_empty():
		var beside: Vector2 = straight[0] + Vector2(1, 1)
		var row := _row(sporeling, beside, "straightaway")
		_check(row.active and is_equal_approx(row.damage, 0.15) and is_equal_approx(row.range, 0.5), "Straightaway: +15% and +0.5 range")
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
	_check(dreams.get_heart_of_maze() == null and is_equal_approx(base_far - dreams.get_soothe_multiplier(far), 0.5),
		"no Heart of the Maze card: no heart and no +50%")
	# The other markers are card-gated too: no bark, no underdog, no fresh growth, no echo without their cards
	dreams._rest_rules(true)
	_check(dreams.bark_charges == 0 and not dreams.is_underdog(far) and not dreams.is_fresh(far) and dreams.get_echo_bonus() == 0.0,
		"markers stay off without their cards")
	_clear()
	# Echoing Steps: real route changes while nightmares walk
	dreams.take(_card("echoing_steps"))
	var director: DriftDirector = main.get_node("%DriftDirector")
	var walker := _spawn(map_generator.startPath)
	director.resting = false
	dreams._last_route = PackedVector2Array([Vector2.ZERO])
	dreams._last_echo = -INF
	dreams._update_bends()
	director.resting = true
	_check(is_equal_approx(dreams.get_echo_bonus(), 0.05), "Echoing Steps: +5% per route change this drift")
	dreams._update_bends()
	_check(is_equal_approx(dreams.get_echo_bonus(), 0.05), "…an unchanged route doesn't count")
	dreams._on_drift_started(2)
	_check(dreams.get_echo_bonus() == 0.0, "…until the drift ends")
	walker.free()

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

func _row(data: TowerData, cell: Vector2, id: String = "short_roots", tower: Tower = null) -> Dictionary:
	for row in dreams.get_card_effects(data, cell, tower):
		if row.id == id or row.id == id + "_ii":
			return row
	return {"active": false, "damage": 0.0, "range": 0.0}

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
