extends SceneTree

# Headless test for the Nurture Dream cards (60–68), wide / narrow cards (69–76) and the card
# requirement rules (dream_design.md "Card requirements", "Nurture cards", "Wide and narrow").
#   godot --headless --path . --script res://tests/test_dream_builds.gd --fixed-fps 60

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
	_test_requirements()
	_test_nurture_effects()
	_test_nurture_rules()
	_test_wide_and_narrow()
	_test_direction_weighting()
	_test_reaction_cards()
	_test_family_review_cards()
	_test_seedling_gift()
	_test_peek()
	_test_grove_cards()
	_test_clear_tool()
	print("dream builds test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

# Openers need Dew spent on ranks; follow-ups need a nurture card and ranked Wardens.
func _test_requirements() -> void:
	_reset()
	var tender := _card("tender_care")
	_check(not dreams.is_eligible(tender), "Tender Care needs 30 Dew spent on ranks")
	run_state.rank_dew_spent = 30
	_check(dreams.is_eligible(tender), "…and is offered after that (opener)")
	var kindred := _card("kindred_roots")
	var a := _plant("sporeling", 0, 1)
	var b := _plant("sporeling", 1, 1)
	_check(not dreams.is_eligible(kindred), "Kindred Roots needs a nurture card first (follow-up)")
	dreams.take(tender)
	_check(dreams.is_eligible(kindred), "…then offered with 2 ranked Wardens")
	b.rank = 0
	_check(not dreams.is_eligible(kindred), "…and not with only 1")
	var remembered := _card("remembered_care")
	_check(not dreams.is_eligible(remembered), "Remembered Care needs a rank III Warden")
	a.rank = 3
	_check(dreams.is_eligible(remembered), "…offered once one is rank III")
	var deeper := _card("deeper_rings")
	a.rank = 5
	_check(not dreams.is_eligible(deeper), "Deeper Rings is a Grove card")
	dreams.grove_cards.assign(["deeper_rings"])
	_check(dreams.is_eligible(deeper), "…offered from the Grove with a rank V Warden")
	dreams.take(deeper)
	a.rank = 1
	_check(dreams.has_card("deeper_rings"), "losing a requirement never removes a taken card")
	# requires_any: any one of the listed Wardens is enough
	var any_card := UpgradeData.new()
	any_card.id = "test_requires_any"
	any_card.requires_any.assign(["bloomcap", "frostfern"])
	_check(not dreams.is_eligible(any_card), "requires_any: none owned")
	dreams.unlocked["frostfern"] = true
	_check(dreams.is_eligible(any_card), "requires_any: one owned is enough")
	_clear_towers()

func _test_nurture_effects() -> void:
	_reset()
	var tender := _card("tender_care")
	for i in 4:
		dreams.take(tender)
	_check(is_equal_approx(dreams.get_nurture_cost_multiplier(), 0.55), "Tender Care stacks to −45%, no further")
	dreams.take(_card("warm_hands"))
	_check(is_equal_approx(dreams.get_rank_damage_bonus(), 0.03), "Warm Hands: +3% damage per rank")
	_check(dreams.get_max_rank() == 5 and dreams.get_extra_rank_cost(6) == 0, "rank V is the cap by default")
	dreams.take(_card("deeper_rings"))
	_check(dreams.get_max_rank() == 7 and dreams.get_extra_rank_cost(6) == 130 and dreams.get_extra_rank_cost(7) == 180,
		"Deeper Rings: ranks VI (130) and VII (180)")
	var sprout: TowerData = load("res://resource/tower/sprout.tres")
	var before := dreams.get_build_cost(sprout)
	dreams.take(_card("overgrowth"))
	_check(dreams.get_max_rank() == 1, "Overgrowth caps Nurture at rank I, even with Deeper Rings")
	_check(dreams.get_build_cost(sprout) == roundi(before * 0.7), "Overgrowth: planting 30% cheaper")
	_reset()
	dreams.take(_card("the_old_ones"))
	_check(is_equal_approx(dreams.get_rank_crit_bonus(), 0.02), "The Old Ones: +2% crit per rank")
	var elder := _plant("sporeling", 0, 5)
	var young := _plant("sporeling", 1, 2)
	var far := _plant("sporeling", 6, 2)
	_check(dreams.get_effective_rank(young) == 3 and dreams.get_effective_rank(far) == 2,
		"The Old Ones: touching a rank V Warden counts one rank higher")
	_check(dreams.get_effective_rank(elder) == 5, "…read from real ranks, so it doesn't chain")
	_clear_towers()

func _test_nurture_rules() -> void:
	_reset()
	var centre := _plant("sporeling", 0, 1)
	_plant("sporeling", 1, 3)
	_plant("firefly_jar", 2, 2)  # Not touching the centre
	var base := dreams.get_soothe_multiplier(centre)
	dreams.take(_card("kindred_roots"))
	_check(is_equal_approx(dreams.get_soothe_multiplier(centre) - base, 0.06), "Kindred Roots: +2% per touching rank")
	dreams.take(_card("kindred_roots_ii"))
	_check(is_equal_approx(dreams.get_soothe_multiplier(centre) - base, 0.09), "Kindred Roots II: +3% per touching rank")
	_clear_towers()

	_reset()
	var strong := _plant("sporeling", 0, 5)
	var weak := _plant("sporeling", 3, 1)
	var strong_base := dreams.get_soothe_multiplier(strong)
	var weak_base := dreams.get_soothe_multiplier(weak)
	dreams.take(_card("chosen_few"))
	_check(is_equal_approx(dreams.get_soothe_multiplier(strong) - strong_base, 0.5)
		and is_equal_approx(dreams.get_soothe_multiplier(weak) - weak_base, -0.15), "Chosen Few: +50% at rank V, −15% below III")
	_clear_towers()

	# Remembered Care: sell a ranked Warden, the next one planted starts at that rank
	_reset()
	dreams.take(_card("remembered_care"))
	var sold := _plant("sporeling", 0, 4)
	dreams._on_tower_sold(sold, 0)
	var low := _plant("sporeling", 1, 2)
	dreams._on_tower_sold(low, 0)
	_check(run_state.memory_seeds == [4], "one memory seed, the highest rank kept")
	var fresh := _plant("dewdrop", 2, 0)
	dreams._on_tower_built(fresh)
	_check(fresh.rank == 4 and run_state.memory_seeds.is_empty(), "the next Warden planted starts at rank IV")
	dreams.take(_card("remembered_care_ii"))
	dreams._on_tower_sold(sold, 0)
	dreams._on_tower_sold(low, 0)
	_check(run_state.memory_seeds == [4, 2], "Remembered Care II keeps two seeds")
	run_state.memory_seeds.clear()
	_clear_towers()

	# Sunlit Rest: a free rank for the ranked Warden nearest the Heartwood; rank II waits for a Focus
	_reset()
	dreams.take(_card("sunlit_rest"))
	var path: PackedVector2Array = main.get_node("%MapGenerator").get_path_from(main.get_node("%MapGenerator").startPath)
	var early := _plant_at("sporeling", _beside(path, 5), 1)
	var late := _plant_at("sporeling", _beside(path, path.size() - 6), 1)
	var focus_wait := _plant_at("sporeling", _beside(path, path.size() - 4), 2)
	var raised := dreams.sunlit_rest()
	_check(raised == [late] and late.rank == 2 and early.rank == 1 and focus_wait.rank == 2,
		"Sunlit Rest raises the ranked Warden nearest the Heartwood (skipping rank II)")
	dreams.take(_card("sunlit_rest_ii"))
	late.rank = 1
	_check(dreams.sunlit_rest().size() == 2, "Sunlit Rest II raises two")
	_clear_towers()

func _test_wide_and_narrow() -> void:
	_reset()
	var sprout: TowerData = load("res://resource/tower/sprout.tres")
	dreams.take(_card("seedfall"))
	_check(dreams.get_build_cost(sprout) == 6, "Seedfall: Sprouts cost 6")

	# Counts: only attacking Wardens (Thornwalls never)
	var many := _card("many_hands")
	var few := _card("few_and_mighty")
	for i in 14:
		_plant("sporeling", i * 3, 0)
	_plant("thornwall", 60, 0)
	_check(dreams.count_attackers() == 14, "Thornwalls don't count as attacking Wardens")
	_check(not dreams.is_eligible(many), "Many Hands needs 15+ attacking Wardens")
	_plant("sporeling", 63, 0)
	_plant("sporeling", 66, 0)
	_check(dreams.is_eligible(many) and not dreams.is_eligible(few), "…offered at 16; Few and Mighty isn't (≤12)")
	var one: Tower = dreams._towers()[0]
	var base := dreams.get_soothe_multiplier(one)
	dreams.take(many)
	_check(is_equal_approx(dreams.get_soothe_multiplier(one) - base, 0.04), "Many Hands: +1% per 4 attacking Wardens")
	_clear_towers()

	_reset()
	var lone := _plant("sporeling", 0, 0)
	for i in 6:
		_plant("sporeling", 10 + i * 3, 0)
	_check(dreams.is_eligible(few), "Few and Mighty offered with 7 attacking Wardens")
	base = dreams.get_soothe_multiplier(lone)
	dreams.take(few)
	_check(is_equal_approx(dreams.get_soothe_multiplier(lone) - base, 0.40), "Few and Mighty: 7 Wardens = +40%")
	_check(dreams.get_live_bonus_text(few) == "+40%", "the Dreams row shows the live bonus")
	_plant("sporeling", 40, 0)
	_check(is_equal_approx(dreams.get_soothe_multiplier(lone) - base, 0.32), "…and it updates live")
	_clear_towers()

	# Solitude, Sprout Chorus, The Last Light
	_reset()
	dreams.take(_card("solitude"))
	var alone := _plant("sporeling", 0, 0)
	var pair_a := _plant("sporeling", 10, 0)
	var pair_b := _plant("sporeling", 12, 0)  # 2 cells from pair_a
	_check(dreams.get_tower_range_bonus(alone) == 0.5 and dreams.get_tower_range_bonus(pair_a) == 0.0,
		"Solitude: +0.5 range only with no attacking Warden within 2 cells")
	_plant("thornwall", 1, 0)
	_check(dreams.is_solitary(alone), "…walls don't break Solitude")
	_clear_towers()

	_reset()
	var chorus := _card("sprout_chorus")
	var sprouts: Array[Tower] = []
	for i in 5:
		sprouts.append(_plant("sprout", i, 0))
	_check(not dreams.is_eligible(chorus), "Sprout Chorus needs 6+ Sprouts")
	sprouts.append(_plant("sprout", 5, 0))
	_check(dreams.is_eligible(chorus), "…offered with 6")
	dreams.take(chorus)
	_check(is_equal_approx(dreams.get_tower_attack_speed_bonus(sprouts[2]), 0.20),
		"Sprout Chorus: +5% per other Sprout within 2 cells (4 → +20%)")
	_clear_towers()

	_reset()
	dreams.take(_card("the_last_light"))
	var lights: Array[Tower] = []
	for i in 5:
		lights.append(_plant("sporeling", i * 4, 0))
	_check(is_equal_approx(dreams.get_tower_attack_speed_bonus(lights[0]), 1.0), "The Last Light: ≤5 attacking Wardens attack twice as fast")
	_plant("sporeling", 30, 0)
	_check(dreams.get_tower_attack_speed_bonus(lights[0]) == 0.0, "…not with 6")
	_clear_towers()

	# Canopy: +8% at 20, 30 and 40 attacking Wardens planted this run, for good
	_reset()
	var canopy_tower := _plant("sporeling", 0, 0)
	base = dreams.get_soothe_multiplier(canopy_tower)
	dreams.take(_card("canopy"))
	dreams._attackers_planted = 31
	_check(is_equal_approx(dreams.get_soothe_multiplier(canopy_tower) - base, 0.16), "Canopy: two steps reached = +16%")
	dreams._attackers_planted = 0
	_clear_towers()

# Owning a direction makes its cards likelier (2×) and the opposite direction's half as likely.
func _test_direction_weighting() -> void:
	_reset()
	dreams.take(_card("seedfall"))  # Wide
	var wide := _card("many_hands")
	var narrow := _card("solitude")
	var wide_picks := 0
	for i in 2000:
		if dreams._weighted_pick([wide, narrow]) == wide:
			wide_picks += 1
	# 2× vs 0.5× → 80% wide
	_check(wide_picks > 1500 and wide_picks < 1700, "wide 2×, narrow 0.5× once you've gone wide (%d / 2000)" % wide_picks)


# Reaction cards 79–83: Needs, "own 2 Reaction pairs", and the rule ids the Reaction code reads.
func _test_reaction_cards() -> void:
	_reset()
	var rolling := _card("rolling_thunder")
	_check(not dreams.is_eligible(rolling), "Rolling Thunder needs Stormcap + Dewdrop")
	dreams.unlocked["dewdrop"] = true
	dreams.unlocked["firefly_jar"] = true
	_check(dreams.count_reaction_pairs() == 1, "Dewdrop + Firefly Jar: one Reaction pair (Thunderclap)")
	dreams.unlocked["stormcap"] = true
	_check(dreams.is_eligible(rolling), "…offered once Stormcap is unlocked too")
	dreams.take(rolling)
	_check(dreams.has_rule(&"rolling_thunder") and dreams.rule_level(&"rolling_thunder") == 0, "Rolling Thunder switches on its rule")
	dreams.take(_card("rolling_thunder_ii"))
	_check(dreams.rule_level(&"rolling_thunder") == 1, "Rolling Thunder II deepens it")

	var quick := _card("quick_reactions")
	dreams.grove_cards.assign(["quick_reactions", "dawnbreak", "deep_water", "wildfire_spores"])
	_check(not dreams.is_eligible(quick), "Quick Reactions needs 2 Reaction pairs")
	dreams.unlocked["sporeling"] = true  # + Ignite (Spored + Static), Mushrooming (Spored + Damp)
	_check(dreams.count_reaction_pairs() == 3 and dreams.is_eligible(quick), "…offered with 3")
	_check(dreams.is_eligible(_card("wildfire_spores")) and dreams.is_eligible(_card("deep_water")),
		"Wildfire Spores (Sporeling + Firefly Jar) and Deep Water (Dewdrop) from the Grove")
	_check(not dreams.is_eligible(_card("dawnbreak"), 1) and dreams.is_eligible(_card("dawnbreak"), 2),
		"Dawnbreak is a Legendary: act 2+")
	dreams.unlocked["lanternmoth"] = true  # Marked: + Lightning Rod (Marked + Static)
	_check(dreams.count_reaction_pairs() == 4, "Lanternmoth adds Lightning Rod")
	dreams.unlocked["tangleroot"] = true  # Held: + Shatter, Pinned, Smother
	_check(dreams.count_reaction_pairs() == 7, "Tangleroot's Held adds Shatter, Pinned and Smother (%d)" % dreams.count_reaction_pairs())

# Cards 84–99 (family review): Grove-only, their Needs, stacking rules and Entwined combos.
func _test_family_review_cards() -> void:
	_reset()
	var ids := ["hush", "heavy_eyelids", "bad_dreams", "encore", "loose_stones", "sharp_beaks", "needle_point",
		"charged_feathers", "pollen_beaks", "thousand_cuts", "longer_flight", "backspin", "ricochet",
		"heavy_seed", "windborne_rain", "seed_storm", "heavy_eyelids_ii", "bad_dreams_ii", "ricochet_ii"]
	for id in ids:
		_check(not _card(id).in_start_pool, "%s comes with its Grove node" % id)
	dreams.grove_cards.assign(ids)

	var eyelids := _card("heavy_eyelids")
	_check(not dreams.is_eligible(eyelids), "Heavy Eyelids needs a Drowsy Warden")
	dreams.unlocked["bloomcap"] = true
	_check(dreams.is_eligible(eyelids), "…Bloomcap makes nightmares Drowsy")

	var beaks := _card("sharp_beaks")
	_check(not dreams.is_eligible(beaks), "Sharp Beaks needs Hummingbird Bower or Wren's Nest")
	dreams.unlocked["wrens_nest"] = true
	_check(dreams.is_eligible(beaks), "…Wren's Nest is enough")
	dreams.take(beaks)
	dreams.take(beaks)
	_check(dreams.rule_stacks(&"sharp_beaks") == 2, "stacking rule cards report their stacks")
	dreams.take(beaks)
	_check(not dreams.is_eligible(beaks), "Sharp Beaks stops at +3")

	var encore := _card("encore")
	dreams.unlocked["echo_hollow"] = true
	_check(not dreams.is_eligible(encore), "Encore needs a Reaction card as well as Echo Hollow")
	dreams.take(_card("rolling_thunder"))
	_check(dreams.is_eligible(encore) and dreams.make_offer(10).has(encore), "…then Entwined: guaranteed next offer")

	dreams.unlocked["samara"] = true
	dreams.unlocked["rain_lily"] = true
	_check(dreams.is_eligible(_card("windborne_rain")) and not dreams.is_eligible(_card("seed_storm"), 1)
		and dreams.is_eligible(_card("seed_storm"), 2), "Windborne Rain (Samara + Rain Lily); Seed Storm is act 2+")

# Seedling Gift (#33): a free Sprout charge each rest, used before Dew; Nursery (Entwined with Tender
# Care) makes those Sprouts rank II. Also the Great Dreamcatcher's Dreamlight shards.
func _test_seedling_gift() -> void:
	_reset()
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var map_generator = main.get_node("%MapGenerator")
	var gift := _card("seedling_gift")
	var nursery := _card("nursery")
	dreams.grove_cards.assign(["seedling_gift", "nursery"])
	_check(dreams.is_eligible(gift), "Seedling Gift is offered from the Grove")
	dreams.take(gift)
	run_state.sprout_charges = 0
	dreams._on_rest_started(1, false, 0, true)
	dreams._pending_drifts.clear()
	_check(run_state.sprout_charges == 1, "a free Sprout charge at every rest")

	run_state.dew = 100
	placer.tower_data = load("res://resource/tower/sprout.tres")
	var cell := _free_cell(map_generator)
	_check(placer.get_cost(null, cell) == 0, "a charge makes the next Sprout free")
	_check(placer._try_build(cell) and run_state.dew == 100 and run_state.sprout_charges == 0, "the charge is used before Dew")
	var sprout: Tower = seller.get_tower_at(cell)
	_check(sprout != null and sprout.invested_dew == 0 and seller.get_refund(sprout) == 0, "a charged Sprout refunds nothing")
	_check(sprout.rank == 0, "without Nursery it starts unranked")
	var paid_cell := _free_cell(map_generator)
	placer._try_build(paid_cell)
	_check(run_state.dew < 100, "with no charge left, Sprouts cost Dew again")

	_check(not dreams.is_eligible(nursery), "Nursery needs Tender Care too")
	dreams.take(_card("tender_care"))
	_check(dreams.is_eligible(nursery) and dreams.make_offer(10).has(nursery), "…then Nursery is Entwined: guaranteed")
	dreams.take(nursery)
	_check(is_equal_approx(dreams.get_nurture_cost_multiplier(sprout), 0.85 * 0.5), "Nursery: Sprouts nurture for half price")
	run_state.add_sprout_charges(1)
	var nursery_cell := _free_cell(map_generator)
	placer._try_build(nursery_cell)
	var ranked: Tower = seller.get_tower_at(nursery_cell)
	_check(ranked != null and ranked.rank == 2 and ranked.invested_dew == 0, "with Nursery, a charged Sprout arrives at rank II")
	var saved := dreams.to_save()
	run_state.sprout_charges = 0
	run_state.add_sprout_charges(2)
	saved = dreams.to_save()
	run_state.sprout_charges = 0
	dreams.load_save(saved)
	_check(run_state.sprout_charges == 2, "charges survive the save")
	run_state.sprout_charges = 0
	for c in [cell, paid_cell, nursery_cell]:
		seller.sell(c)

	# Dreamlight shards: 10 = 1 Dreamlight, at most 2 a run
	dreams.dreamlight = 0
	dreams.dreamlight_shards = 0
	for i in 35:
		dreams.add_dreamlight_shard()
	_check(dreams.dreamlight == 2 and dreams.dreamlight_shards == 20, "shards: 10 per Dreamlight, 2 per run at most")

# The Grove's Cards limb (meta_design.md Section 3): 12 cards + Deepened, and Bittersweet Dreams.
func _test_grove_cards() -> void:
	_reset()
	var ids := ["static_bloom", "static_field", "guiding_light", "starlit_aim", "twin_puff", "still_target",
		"shattering_blow", "reckless_bloom", "full_moon", "rootbound", "monoculture", "the_long_walk",
		"deep_sleep", "borrowed_dew", "wild_growth", "overgrown", "restless_dreams", "hungry_roots"]
	for id in ids:
		_check(not _card(id).in_start_pool, "%s waits for its Grove node" % id)
	dreams.grove_cards.assign(ids)
	dreams.allow_bittersweet = true
	_check(dreams.is_eligible(_card("deep_sleep"), 2), "Bittersweet Dreams node opens the bittersweet cards")
	dreams.allow_bittersweet = false

	# Needs
	dreams.unlocked["stormcap"] = true
	_check(not dreams.is_eligible(_card("static_bloom")), "Static Bloom: Entwined, needs Bloomcap too")
	dreams.unlocked["bloomcap"] = true
	_check(dreams.make_offer(10).has(_card("static_bloom")), "…then guaranteed")
	_check(dreams.is_eligible(_card("still_target")), "Still Target: a Drowsy / Held Warden (Bloomcap)")
	_check(not dreams.is_eligible(_card("full_moon"), 2), "Full Moon needs 2 crit cards")
	dreams.take(_card("still_target"))
	dreams.take(_card("shattering_blow"))
	_check(dreams.is_eligible(_card("full_moon"), 2) and not dreams.is_eligible(_card("full_moon"), 1),
		"…offered with 2, act 2+")

	# Crit getters (Tower adds them)
	var tower := _plant("sporeling", 0, 0)
	var sleepy: Node2D = main.get_node("%EnemyContainer").enemy_scene.instantiate()
	sleepy.enemy_data = TestGrove._load_enemy_types()[0]
	main.get_node("%EnemyContainer").add_child(sleepy)
	sleepy.set_process(false)
	_check(dreams.get_crit_chance_bonus(tower, sleepy) == 0.0, "no bonus against an unaffected nightmare")
	sleepy.apply_status(EnemyStatuses.DROWSY, 1, 3.0)
	_check(is_equal_approx(dreams.get_crit_chance_bonus(tower, sleepy), 0.15), "Still Target: +15% vs Drowsy")
	dreams.take(_card("full_moon"))
	_check(is_equal_approx(dreams.get_crit_chance_bonus(tower, sleepy), 0.25)
		and is_equal_approx(dreams.get_crit_overflow_multiplier(1.3), 0.3), "Full Moon: +10%, overflow → crit damage")
	dreams.take(_card("reckless_bloom"))
	_check(is_equal_approx(dreams.get_non_crit_multiplier(), 0.85), "Reckless Bloom: non-crits −15%")
	sleepy.free()
	_clear_towers()

	# The Long Walk, Monoculture, Rootbound
	_reset()
	var a := _plant("sporeling", 0, 0)
	var base := dreams.get_soothe_multiplier(a)
	dreams.take(_card("the_long_walk"))
	_check(is_equal_approx(dreams.get_soothe_multiplier(a) - base, 0.01 * (dreams.path_length / 4)), "The Long Walk: +1% per 4 path tiles")
	_reset()
	a = _plant("sporeling", 0, 0)
	_plant("driftspore", 5, 0)
	base = dreams.get_soothe_multiplier(a)
	dreams.take(_card("monoculture"))
	_check(is_equal_approx(dreams.get_soothe_multiplier(a) - base, 0.6), "Monoculture: one line = +60%")
	_plant("dewdrop", 10, 0)
	_check(is_equal_approx(dreams.get_soothe_multiplier(a) - base, 0.0), "…not with two lines")
	_reset()
	var hub := _plant_at("sporeling", Vector2(100, 100), 0)
	for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP]:
		_plant_at("thornwall", Vector2(100, 100) + offset, 0)
	dreams.take(_card("rootbound"))
	_check(is_equal_approx(dreams.get_tower_attack_speed_bonus(hub), 1.0), "Rootbound: touching 3 Wardens attacks twice")
	_clear_towers()

# The Clear tool (screens_ui.md): clicks clear only while the tool is on; locked until a clearing Dream.
func _test_clear_tool() -> void:
	_reset()
	var clearer: ObstacleClearer = main.get_node("%ObstacleClearer")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var map_generator = main.get_node("%MapGenerator")
	dreams.clearing_open = false
	var refused := []
	clearer.tool_refused.connect(func() -> void: refused.append(true))
	_check(not clearer.set_tool_active(true) and refused.size() == 1, "the tool is refused while clearing is locked")
	var locks := []
	clearer.lock_changed.connect(func(locked: bool) -> void: locks.append(locked))
	dreams.take(_card("tended_forest"))
	_check(locks == [false], "lock_changed(false) when the first clearing Dream unlocks it")

	var cell: Vector2 = map_generator.obstacles.keys()[0]
	clearer._hover_cell = cell
	clearer._refresh_hover()
	run_state.dew = 100
	clearer._unhandled_input(_click())
	_check(map_generator.get_obstacle(cell) != null, "without the tool a click doesn't clear")
	_check(clearer.set_tool_active(true) and clearer.is_tool_active(), "the tool switches on once unlocked")
	clearer._unhandled_input(_click())
	_check(map_generator.get_obstacle(cell) == null and clearer.is_tool_active(), "with the tool a click clears, and it stays on")

	# Touch: tap marks, second tap clears
	clearer.confirm_clears = true
	var second: Vector2 = map_generator.obstacles.keys()[0]
	clearer._hover_cell = second
	clearer._refresh_hover()
	clearer._unhandled_input(_click())
	_check(map_generator.get_obstacle(second) != null and clearer.pending_cell == second, "touch: the first tap only marks it")
	_check(clearer.confirm_pending() and map_generator.get_obstacle(second) == null, "…the ✓ clears it")
	clearer.confirm_clears = false

	var cancel := InputEventAction.new()
	cancel.action = &"cancel_build"
	cancel.pressed = true
	clearer._unhandled_input(cancel)
	_check(not clearer.is_tool_active(), "Esc / right-click puts the tool away")
	clearer.set_tool_active(true)
	placer.select_tower(load("res://resource/tower/sprout.tres"))
	_check(not clearer.is_tool_active(), "picking a Warden puts the tool away")
	placer.set_build_mode(false)
	dreams.clearing_open = true

func _click() -> InputEventAction:
	var click := InputEventAction.new()
	click.action = &"clear_obstacle"
	click.pressed = true
	return click

# The Dream, Omen and Remember screens can be minimised to look at the map (screens_ui.md).
func _test_peek() -> void:
	for name in ["DreamScreen", "OmenScreen", "RememberScreen"]:
		var screen := main.get_node("HUD/" + name) as Control
		var peek: ChoicePeek = screen.peek
		screen.visible = true
		peek.set_peeking(true)
		_check(peek.peeking and screen.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s: peek lets the map through" % name)
		screen.visible = false
		_check(not peek.peeking, "%s: closing the screen ends the peek" % name)

func _free_cell(map_generator) -> Vector2:
	var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	for i in range(3, path.size()):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = path[i] + offset
			if not path.has(cell) and map_generator.can_block(cell) \
					and main.get_node("%TowerSeller").get_tower_at(cell) == null:
				return cell
	return Vector2(-1, -1)

# --- Helpers --------------------------------------------------------------------------------------

func _reset() -> void:
	dreams.stacks.clear()
	dreams.unlocked = {"sprout": true, "thornwall": true}
	dreams.grove_cards.clear()
	dreams.allow_bittersweet = false
	run_state.rank_dew_spent = 0
	run_state.memory_seeds.clear()
	_clear_towers()

func _card(id: String) -> UpgradeData:
	for card in dreams.pool:
		if card.id == id:
			return card
	_check(false, "card %s exists" % id)
	return null

# A Warden placed straight into the container (not on the map): these cards only count Wardens
# and read ranks. Cells are spaced along a row far from the maze.
func _plant(id: String, column: int, rank: int) -> Tower:
	return _plant_at(id, Vector2(100 + column, 100), rank)

func _plant_at(id: String, cell: Vector2, rank: int) -> Tower:
	var tower: Tower = load("res://scenes/tower/tower.tscn").instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = cell
	tower.position = tower.MAP_GRID.calculate_map_position(cell)
	main.get_node("%TowerContainer").add_child(tower)
	tower.set_process(false)
	tower.rank = rank
	return tower

# A cell next to path[i] that isn't on the path.
func _beside(path: PackedVector2Array, i: int) -> Vector2:
	for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		if not path.has(path[i] + offset):
			return path[i] + offset
	return path[i] + Vector2(2, 0)

func _clear_towers() -> void:
	for tower in main.get_node("%TowerContainer").get_children():
		tower.free()

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
