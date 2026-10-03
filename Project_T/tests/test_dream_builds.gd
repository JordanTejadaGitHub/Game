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
	_test_new_forms()
	_test_ascended()
	_test_woven()
	_test_potency_and_endless()
	_test_card_effects()
	_test_kinship_cards()
	_test_generic_rares()
	print("dream builds test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

# Openers need Dew spent on ranks; follow-ups need a nurture card and ranked Wardens.
func _test_requirements() -> void:
	_reset()
	var tender := _card("tender_care")
	_check(dreams.is_eligible(tender), "Tender Care has no Needs (round 3: the Tall opener)")
	var kindred := _card("kindred_roots")
	var a := _plant("sporeling", 0, 1)
	var b := _plant("sporeling", 1, 1)
	_check(not dreams.is_eligible(kindred), "Kindred Roots needs a nurture card first (follow-up)")
	dreams.take(tender)
	b.rank = 0
	_check(dreams.is_eligible(kindred), "…then offered with 1 ranked Warden (round 2: was 2)")
	a.rank = 0
	_check(not dreams.is_eligible(kindred), "…and not with none")
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
	_own("frostfern")
	_check(dreams.is_eligible(any_card), "requires_any: one owned is enough")
	_clear_towers()

func _test_nurture_effects() -> void:
	_reset()
	# Tender Care (rework 2026-09-30): rank I free on every Warden, not stackable; II: ranks II–V 20% less
	var tender := _card("tender_care")
	_check(tender.max_stacks == 1 and not tender.tags.has("economy") and tender.tags.has("nurture") and tender.tags.has("tall"),
		"Tender Care: one stack, nurture + tall (no economy tag)")
	_check(dreams.rank_cost_factor(1) == 1.0, "no card: rank I at full price")
	dreams.take(tender)
	_check(dreams.rank_cost_factor(1) == 0.0 and dreams.rank_cost_factor(2) == 1.0, "Tender Care: rank I free, rank II full price")
	_check(is_equal_approx(dreams.get_nurture_cost_multiplier(), 1.0) and dreams.get_rank_damage_bonus() == 0.0,
		"…and nothing else (the old −15% and +3% per rank are gone)")
	dreams.take(_card("tender_care_ii"))
	_check(dreams.rank_cost_factor(1) == 0.0 and is_equal_approx(dreams.rank_cost_factor(2), 0.8)
		and is_equal_approx(dreams.rank_cost_factor(5), 0.8) and dreams.rank_cost_factor(6) == 1.0, "Tender Care II: ranks II–V 20% less")
	var old := dreams.to_save()
	old.stacks = {"tender_care": 4}
	dreams.load_save(old)
	_check(dreams.card_stacks("tender_care") == 1, "an old save with 4 stacks owns it once")
	_reset()
	_check(dreams.get_max_rank() == 5 and dreams.get_extra_rank_cost(6) == 0, "rank V is the cap by default")
	dreams.take(_card("deeper_rings"))
	_check(dreams.get_max_rank() == 7 and dreams.get_extra_rank_cost(6) == 130 and dreams.get_extra_rank_cost(7) == 180,
		"Deeper Rings: ranks VI (130) and VII (180)")
	_reset()
	dreams.take(_card("the_old_ones"))
	_check(is_equal_approx(dreams.get_rank_crit_bonus(), 0.0), "The Old Ones no longer adds crit (one archetype)")
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

	# Sunlit Rest: a free rank for the Warden nearest the Heartwood
	_reset()
	dreams.take(_card("sunlit_rest"))
	var path: PackedVector2Array = main.get_node("%MapGenerator").get_path_from(main.get_node("%MapGenerator").startPath)
	var early := _plant_at("sporeling", _beside(path, 5), 1)
	var late := _plant_at("sporeling", _beside(path, path.size() - 6), 1)
	var nearest := _plant_at("sporeling", _beside(path, path.size() - 4), 2)
	var raised := dreams.sunlit_rest()
	_check(raised == [nearest] and nearest.rank == 3 and late.rank == 1 and early.rank == 1,
		"Sunlit Rest raises the Warden nearest the Heartwood (%s)" % [raised])
	dreams.take(_card("sunlit_rest_ii"))
	late.rank = 1
	_check(dreams.sunlit_rest().size() == 2, "Sunlit Rest II raises two")
	_clear_towers()
	# Round 2: an opener. With no ranked Warden, rank I goes to the attacking Warden nearest the Heartwood
	_reset()
	dreams.take(_card("sunlit_rest"))
	var first := _plant_at("sporeling", _beside(path, 5), 0)
	var last := _plant_at("sporeling", _beside(path, path.size() - 6), 0)
	_plant_at("thornwall", _beside(path, path.size() - 4), 0)
	_check(dreams.sunlit_rest() == [last] and last.rank == 1 and first.rank == 0,
		"Sunlit Rest with no ranked Warden: rank I to the attacking one nearest the Heartwood (not a wall)")
	_check(last.rank_choices == [Tower.Focus.POWER], "…its first free rank is Power (no choice of its own yet)")
	_check(_card("sunlit_rest").requires_tag == "", "…and it needs no Nurture card")
	_clear_towers()
	# The simplified rule (dream_design.md 06143ab9, user: "confusing"): nearest the Heartwood, ranked or not; at max
	# rank it passes to the next-nearest; the rank repeats the Warden's last choice
	_reset()
	dreams.take(_card("sunlit_rest"))
	var ranked_far := _plant_at("sporeling", _beside(path, 5), 2)
	var unranked_near := _plant_at("sporeling", _beside(path, path.size() - 4), 0)
	_check(dreams.sunlit_rest() == [unranked_near] and ranked_far.rank == 2, "the nearest gets it, ranked or not")
	unranked_near.rank = unranked_near.get_max_rank()
	ranked_far.rank_choices = [Tower.Focus.SWIFT, Tower.Focus.REACH]
	_check(dreams.sunlit_rest() == [ranked_far] and ranked_far.rank == 3 and ranked_far.rank_choices[-1] == Tower.Focus.REACH,
		"…at max rank it passes to the next-nearest, which repeats its last choice (Reach)")
	_check(dreams.preview_card_impact(_card("sunlit_rest")).towers.size() == 1, "its impact counts the one Warden it raises")
	_clear_towers()

func _test_wide_and_narrow() -> void:
	_reset()
	var sprout: TowerData = load("res://resource/tower/sprout.tres")
	dreams.take(_card("seedfall"))
	_check(dreams.get_build_cost(sprout) == 8, "Seedfall: Sprouts start at 8")

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
	_check(is_equal_approx(dreams.get_soothe_multiplier(one) - base, 0.08), "Many Hands: +1% per 2 attacking Wardens")
	_clear_towers()

	_reset()
	var lone := _plant("sporeling", 0, 0)
	for i in 6:
		_plant("sporeling", 10 + i * 3, 0)
	dreams.grove_cards.append("few_and_mighty")  # A Grove card since the lean starting pool (Elders node)
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
	_check(is_equal_approx(dreams.get_tower_attack_speed_bonus(sprouts[2]), 0.32),
		"Sprout Chorus: +8% per other Sprout within 2 cells (4 → +32%)")
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

	# Canopy: +12% at 20, 30 and 40 attacking Wardens planted this run, for good
	_reset()
	var canopy_tower := _plant("sporeling", 0, 0)
	base = dreams.get_soothe_multiplier(canopy_tower)
	dreams.take(_card("canopy"))
	dreams._attackers_planted = 31
	_check(is_equal_approx(dreams.get_soothe_multiplier(canopy_tower) - base, 0.24), "Canopy: two steps reached = +24%")
	dreams._attackers_planted = 0
	_clear_towers()

# Build-tag steering is off (2026-09-30): owning overgrowth cards neither lifts overgrowth nor pushes tall away;
# only Needs shape the weights.
func _test_direction_weighting() -> void:
	_reset()
	dreams.take(_card("seedfall"))  # Overgrowth
	var wide := _card("many_hands")
	var narrow := _card("solitude")
	dreams.take(_card("sprout_chorus"))  # Two overgrowth cards
	_check(dreams.tag_weight == 1.0, "tag_weight is 1.0 (steering off)")
	for i in 15:  # Many Hands' soft Need (15 attacking Wardens) met, so only the tags count
		_plant("sporeling", 60 + i * 3, 0)
	var wide_picks := 0
	for i in 2000:
		if dreams._weighted_pick([wide, narrow]) == wide:
			wide_picks += 1
	var expected := 1000.0  # No boost for overgrowth, no penalty for tall
	_check(absf(wide_picks - expected) < 110, "an overgrowth card and a tall card are equally likely (%d / 2000)" % wide_picks)
	# Unmet soft Need: ×0.4 on top
	_clear_towers()
	wide_picks = 0
	for i in 2000:
		if dreams._weighted_pick([wide, narrow]) == wide:
			wide_picks += 1
	expected = 2000.0 * 0.4 / (0.4 + 1.0)
	_check(absf(wide_picks - expected) < 110, "…an unmet soft Need weighs ×0.4 (%d / 2000, expected %d)" % [wide_picks, expected])
	_check(dreams.can_offer(wide) and not dreams.is_eligible(wide), "…but never blocks the card (can_offer)")
	_clear_towers()


# Reaction cards 79–83: Needs, "own 2 Reaction pairs", and the rule ids the Reaction code reads.
func _test_reaction_cards() -> void:
	_reset()
	var rolling := _card("rolling_thunder")
	_check(not dreams.is_eligible(rolling), "Rolling Thunder needs Stormcap + Dewdrop")
	_own("dewdrop")
	_own("firefly_jar")
	_check(dreams.count_reaction_pairs() == 1, "Dewdrop + Firefly Jar: one Reaction pair (Thunderclap)")
	_own("stormcap")
	_check(dreams.is_eligible(rolling), "…offered once Stormcap is unlocked too")
	dreams.take(rolling)
	_check(dreams.has_rule(&"rolling_thunder") and dreams.rule_level(&"rolling_thunder") == 0, "Rolling Thunder switches on its rule")
	dreams.take(_card("rolling_thunder_ii"))
	_check(dreams.rule_level(&"rolling_thunder") == 1, "Rolling Thunder II deepens it")

	var quick := _card("quick_reactions")
	dreams.grove_cards.assign(["quick_reactions", "dawnbreak", "deep_water", "wildfire_spores"])
	_check(not dreams.is_eligible(quick), "Quick Reactions needs 2 Reaction pairs")
	_own("sporeling")  # + Ignite (Spored + Static), Mushrooming (Spored + Damp)
	_check(dreams.count_reaction_pairs() == 3 and dreams.is_eligible(quick), "…offered with 3")
	_check(dreams.is_eligible(_card("wildfire_spores")) and dreams.is_eligible(_card("deep_water")),
		"Wildfire Spores (Sporeling + Firefly Jar) and Deep Water (Dewdrop) from the Grove")
	_check(not dreams.is_eligible(_card("dawnbreak"), 1) and dreams.is_eligible(_card("dawnbreak"), 2),
		"Dawnbreak is a Legendary: act 2+")
	_own("lanternmoth")  # Marked: + Lightning Rod (Marked + Static)
	_check(dreams.count_reaction_pairs() == 4, "Lanternmoth adds Lightning Rod")
	_own("tangleroot")  # Held: + Shatter, Pinned, Smother
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
	_own("bloomcap")
	_check(dreams.is_eligible(eyelids), "…Bloomcap makes nightmares Drowsy")

	var beaks := _card("sharp_beaks")
	_check(not dreams.is_eligible(beaks), "Sharp Beaks needs Hummingbird Bower or Wren's Nest")
	_own("wrens_nest")
	_check(dreams.is_eligible(beaks), "…Wren's Nest is enough")
	dreams.take(beaks)
	dreams.take(beaks)
	_check(dreams.rule_stacks(&"sharp_beaks") == 2, "stacking rule cards report their stacks")
	dreams.take(beaks)
	_check(not dreams.is_eligible(beaks), "Sharp Beaks stops at +3")

	var encore := _card("encore")
	_own("echo_hollow")
	_check(not dreams.is_eligible(encore), "Encore needs a Reaction card as well as Echo Hollow")
	_own("stormcap")  # Rolling Thunder's Wardens (else it sleeps: half-dreamed)
	_own("dewdrop")
	dreams.take(_card("rolling_thunder"))
	_check(dreams.is_eligible(encore), "…then Entwined: offered at normal odds")

	_own("samara")
	_own("rain_lily")
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
	_check(dreams.is_eligible(nursery), "…then Nursery is Entwined: offered at normal odds")
	dreams.take(nursery)
	_check(is_equal_approx(dreams.get_nurture_cost_multiplier(sprout), 0.5), "Nursery: Sprouts nurture for half price")
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
	# Charged Bloom, Charged Field, Guiding Light, Starlit Aim and Twin Puff left the Grove (2026-09-30: start pool, discovery-gated)
	var ids := ["still_target",
		"shattering_blow", "full_moon", "rootbound", "monoculture", "the_long_walk",
		"deep_sleep", "restless_dreams"]
	for id in ids:
		_check(not _card(id).in_start_pool, "%s waits for its Grove node" % id)
	dreams.grove_cards.assign(ids)
	dreams.allow_bittersweet = true
	_check(dreams.is_eligible(_card("deep_sleep"), 2), "Bittersweet Dreams node opens the bittersweet cards")
	dreams.allow_bittersweet = false

	# Needs
	_own("stormcap")
	_check(not dreams.is_eligible(_card("static_bloom")), "Static Bloom: Entwined, needs Bloomcap too")
	_own("bloomcap")
	_check(dreams.is_eligible(_card("static_bloom")), "…then offered at normal odds")
	_check(dreams.is_eligible(_card("still_target")), "Still Target: a Drowsy / Held Warden (Bloomcap)")
	_check(dreams.is_eligible(_card("full_moon"), 2) and not dreams.is_eligible(_card("full_moon"), 1),
		"Full Moon: a Legendary with no Needs, act 2+")
	dreams.take(_card("still_target"))
	dreams.take(_card("shattering_blow"))

	# Crit getters (Tower adds them)
	var tower := _plant("sporeling", 0, 0)
	var sleepy: Node2D = main.get_node("%EnemyContainer").enemy_scene.instantiate()
	sleepy.enemy_data = TestGrove._load_enemy_types()[0]
	main.get_node("%EnemyContainer").add_child(sleepy)
	sleepy.set_process(false)
	_check(dreams.get_crit_chance_bonus(tower, sleepy) == 0.0, "no bonus against an unaffected nightmare")
	sleepy.apply_status(EnemyStatuses.DROWSY, 1, 3.0)
	_check(is_equal_approx(dreams.get_crit_chance_bonus(tower, sleepy), 0.25), "Still Target: +25% vs Drowsy")
	dreams.take(_card("full_moon"))
	_check(is_equal_approx(dreams.get_crit_chance_bonus(tower, sleepy), 0.35)
		and is_equal_approx(dreams.get_crit_overflow_multiplier(1.3), 0.3), "Full Moon: +10%, overflow → crit damage")
	sleepy.free()
	_clear_towers()

	# The Long Walk, Monoculture, Rootbound
	_reset()
	var a := _plant("sporeling", 0, 0)
	var base := dreams.get_soothe_multiplier(a)
	dreams.take(_card("the_long_walk"))
	_check(is_equal_approx(dreams.get_soothe_multiplier(a) - base, 0.01 * (dreams.path_length / 2)), "The Long Walk: +1% per 2 path tiles")
	_reset()
	a = _plant("sporeling", 0, 0)
	_plant("driftspore", 5, 0)
	base = dreams.get_soothe_multiplier(a)
	dreams.take(_card("monoculture"))
	_check(is_equal_approx(dreams.get_soothe_multiplier(a) - base, 1.0), "Monoculture: one line = +100%")
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
	dreams.take(_card("heartwoods_reach"))  # The opener (absorbed Tend the Forest)
	_check(locks == [false], "lock_changed(false) when the opener unlocks clearing")

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

# Mossback / Boulderback / Dreamshroom (403c0f8): Dreamlight unlocks only, never Dream offers.
func _test_new_forms() -> void:
	_reset()
	for id in ["dream_mossback", "dream_boulderback", "dream_dreamshroom"]:
		dreams.grove_cards.append(id)
		_check(not dreams.is_eligible(_card(id), 2), "%s is never offered as a Dream" % id)
	dreams.grove_cards.clear()
	var mossback: TowerData = load("res://resource/tower/mossback.tres")
	var boulderback: TowerData = load("res://resource/tower/boulderback.tres")
	var dreamshroom: TowerData = load("res://resource/tower/dreamshroom.tres")
	_own("pebbling")
	_own("sporeling")
	_own("bloomcap")
	dreams.branch_offers["pebbling"] = ["mossback", "standing_stone"]  # Phase 2: Pebbling draws 2 of 5; this test is about Mossback
	_check(dreams.get_unlock_cost(mossback) == 1 and dreams.get_unlock_blocker(mossback) == "", "Mossback: a branch for 1 Dreamlight")
	_check(dreams.get_unlock_cost(boulderback) == 2 and dreams.get_unlock_cost(dreamshroom) == 2, "Boulderback and Dreamshroom: final forms for 2")
	_check(dreams.get_unlock_blocker(dreamshroom) == "", "Dreamshroom needs no Grove node (finals come with the family, 2026-09-30)")
	dreams.grove_cards.assign(["dream_boulderback", "dream_dreamshroom"])
	_check(dreams.get_unlock_blocker(boulderback) == "needs Mossback" and dreams.get_unlock_blocker(dreamshroom) == "",
		"with the Grove nodes: Boulderback needs Mossback, Dreamshroom is ready")
	var trees := dreams.get_remember_trees()
	var pebbling_tree: Array = trees.filter(func(t: Array) -> bool: return t[0].get_id() == "pebbling")
	_check(not pebbling_tree.is_empty() and pebbling_tree[0][1].any(func(b: Array) -> bool:
		return b[0] == mossback and b[1].has(boulderback)), "Remember shows Pebbling → Mossback → Boulderback")

# Ascended forms: tier 4 above the finals, 3 Dreamlight, from drift 51, needs a final form and the
# Grove's Ascension node. Uses the real Stormheart (Thunderhead and Midsummer grow into it).
func _test_ascended() -> void:
	_reset()
	var director: DriftDirector = main.get_node("%DriftDirector")
	var thunderhead: TowerData = load("res://resource/tower/thunderhead.tres")
	var stormheart: TowerData = load("res://resource/tower/stormheart.tres")
	dreams.grove_cards.clear()
	_own("firefly_jar")
	dreams.dreamlight = 5
	director.drifts_started = 40
	_check(dreams.get_unlock_cost(stormheart) == 3, "Ascended: 3 Dreamlight")
	_check(dreams.get_unlock_blocker(stormheart) == "from drift 51", "not before drift 51")
	director.drifts_started = 50
	_check(dreams.get_unlock_blocker(stormheart) == "needs a final form", "needs a final form of the family")
	_own("thunderhead")
	_check(dreams.get_unlock_blocker(stormheart) == "Memory Grove", "needs the Grove's Ascension node")
	dreams.grove_cards.assign(["dream_stormheart"])
	_check(dreams.can_unlock(stormheart), "unlockable at the rest before drift 51")
	var tree: Array = dreams.get_remember_trees().filter(func(t: Array) -> bool: return t[0].get_id() == "firefly_jar")
	_check(not tree.is_empty() and tree[0][2] == stormheart, "Remember shows it as the family's Ascended row")
	_check(dreams.unlock_with_dreamlight(stormheart) and dreams.dreamlight == 2, "unlocking spends 3")
	dreams.unlocked.erase("stormheart")
	director.drifts_started = 0

# Woven cards 100–107: three ingredients, then offered at normal odds (no guaranteed slot), Rare.
func _test_woven() -> void:
	_reset()
	var ids := ["eye_of_the_tempest", "deep_stillness", "fever_pitch", "falling_stars", "mountains_fall",
		"prism_heart", "endless_night", "ring_of_rings"]
	for id in ids:
		var card := _card(id)
		_check(card.woven and card.entwined and card.rarity == UpgradeData.Rarity.RARE and card.in_start_pool
				and card.discovered_by.size() == 1 and card.discovered_by[0].begins_with("crowned:"),
			"%s is a Woven Rare in the start pool, discovered by its Crowned Reaction" % id)
	dreams.grove_cards.assign(ids)
	var stars := _card("falling_stars")
	_own("firefly_jar")
	_own("tangleroot")
	_check(not dreams.is_eligible(stars, 2), "Falling Stars needs its third vine")
	_own("chime_stone")
	_check(dreams.is_eligible(stars, 2) and not dreams.is_eligible(stars, 1), "…Chime Stone (or Bellflower) completes it, act 2+")
	_check(dreams.is_eligible(stars, 3), "a Woven card is offered at normal odds once all three are owned")

# Potency cards 109–112 and Endless Rings (108).
func _test_potency_and_endless() -> void:
	_reset()
	var sporeling: TowerData = load("res://resource/tower/sporeling.tres")
	dreams.take(_card("bitter_sap"))
	dreams.take(_card("bitter_sap"))
	_check(is_equal_approx(dreams.get_potency_bonus(sporeling), 0.40), "Bitter Sap stacks: +20% Potency each")
	var seeping := _card("seeping")
	dreams.grove_cards.assign(["seeping", "seeping_ii", "venom_bloom", "nightshade", "endless_rings", "deeper_rings"])
	_check(not dreams.is_eligible(seeping), "Seeping needs 2 status families")
	_own("sporeling")
	_own("dewdrop")
	_check(dreams.is_eligible(seeping), "…Spored + Damp is enough")
	dreams.take(seeping)
	var target: Node2D = main.get_node("%EnemyContainer").enemy_scene.instantiate()
	target.enemy_data = TestGrove._load_enemy_types()[0]
	main.get_node("%EnemyContainer").add_child(target)
	target.set_process(false)
	target.apply_status(EnemyStatuses.DAMP)
	target.apply_status(EnemyStatuses.MARKED)
	_check(is_equal_approx(dreams.get_effect_bonus(target), 0.16), "Seeping: +8% per status (2 → +16%)")
	dreams.take(_card("seeping_ii"))
	_check(is_equal_approx(dreams.get_effect_bonus(target), 0.24), "Seeping II: +12% per status")
	target.free()
	dreams.take(_card("venom_bloom"))
	_check(is_equal_approx(dreams.get_hit_damage_multiplier(), 0.85), "Venom Bloom: hits −15%")

	# Endless Rings: no max rank, ×1.2 per rank past VII; free ranks stop at VII
	_reset()
	dreams.grove_cards.assign(["deeper_rings", "endless_rings"])
	var endless := _card("endless_rings")
	dreams.take(_card("tender_care"))
	var tall := _plant("sporeling", 0, 6)
	_check(dreams.is_eligible(endless, 2), "Endless Rings: a Legendary with no Needs")
	dreams.take(endless)
	dreams.make_eldest(tall)  # Ranks past V are the Eldest's
	_check(dreams.get_max_rank() > 20, "no max rank")
	_check(dreams.get_extra_rank_cost(7) == 180 and dreams.get_extra_rank_cost(8) == 216
		and dreams.get_extra_rank_cost(9) == 259 and dreams.get_extra_rank_cost(10) == 311, "VIII 216, IX 259, X 311")
	tall.rank = 7
	dreams.take(_card("sunlit_rest"))
	_check(dreams.sunlit_rest().is_empty() and tall.rank == 7, "Sunlit Rest never lifts past VII")
	_clear_towers()

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

# "Dream bonuses on Wardens": get_card_effects rows for planted and hypothetical Wardens, ghosts,
# and that the real stat getters equal the active rows.
func _test_card_effects() -> void:
	_reset()
	var spore: TowerData = load("res://resource/tower/sporeling.tres")
	dreams.take(_card("solitude"))
	dreams.take(_card("many_hands"))
	var alone := _plant("sporeling", 0, 0)
	var rows := dreams.get_card_effects(spore, alone.cell, alone)
	var solitude := _row(rows, "solitude")
	_check(not solitude.is_empty() and solitude.active and solitude.positional and solitude.radius == 2.0,
		"card effects: Solitude on, positional, radius 2")
	_check(_row(rows, "many_hands").run_wide and not _row(rows, "many_hands").active
		and _row(rows, "many_hands").reason != "", "…Many Hands off with a reason")
	_check(is_equal_approx(dreams.get_soothe_multiplier(alone), 1.0 + solitude.damage),
		"…the real damage equals the active rows")
	var near := Vector2(alone.cell.x + 2, alone.cell.y)
	var hypo := _row(dreams.get_card_effects(spore, near), "solitude")
	_check(not hypo.active and "away" in hypo.reason, "…a hypothetical Warden 2 cells away: off, says why")
	_check(not dreams.is_solitary_at(spore, near) and dreams.is_solitary_at(spore, Vector2(alone.cell.x + 5, 100)),
		"is_solitary_at for a Warden type at a cell")
	var ghosted := _row(dreams.get_card_effects(spore, alone.cell, alone, {"cell": near, "data": spore}), "solitude")
	_check(not ghosted.active, "…a ghost beside a planted Warden turns its Solitude off")
	_check(dreams.get_range_bonus_at(spore, Vector2(alone.cell.x + 5, 100)) == 0.5
		and dreams.get_range_bonus_at(spore, near) == 0.0, "get_range_bonus_at: Solitude's range for the ghost")
	_check(dreams.max_card_radius() == 2.0, "max_card_radius")
	var parts := dreams.get_stat_parts(spore, alone.cell, "damage", alone)
	_check(parts.parts.size() == 1 and is_equal_approx(parts.final, spore.damage * 1.45), "get_stat_parts: damage")
	_clear_towers()

	# Plain stat cards report from their fields
	_reset()
	var plain: UpgradeData = null
	for card in dreams.pool:
		if card.rule_id == &"" and card.soothe_bonus > 0.0 and card.stat_line == "" and card.stat_warden == "":
			plain = card
			break
	if plain:
		dreams.take(plain)
		var row := _row(dreams.get_card_effects(spore, Vector2(100, 100)), plain.id)
		_check(row.plain and row.active and is_equal_approx(row.damage, plain.soothe_bonus) and row.effect != "",
			"a plain stat card reports itself (%s)" % plain.id)

func _row(rows: Array[Dictionary], id: String) -> Dictionary:
	for row in rows:
		if row.id == id:
			return row
	return {}

# Kinship cards 124–133 (dream_design.md "Kinship cards: going deep"): pools, the "Kinships on the
# map" Need, Entwined Kin and Kindling, and the kinship tag counting as your build.
func _test_kinship_cards() -> void:
	_reset()
	for id in ["family_ties", "sweet_harmony", "sweet_harmony_ii",
			"old_friends", "old_friends_ii", "rooted_bond", "extended_family", "kin_and_kindling", "grove_of_kin",
			"blood_is_thicker"]:
		var card := _card(id)
		if card:
			# Discovery unlocks: every Kinship card, the Legendary Grove of Kin too (2026-09-30), is in the start pool
			# and waits for any Kinship.
			_check(card.in_start_pool and card.tags.has("kinship") and Array(card.discovered_by) == ["kinship:any"],
				"Kinship card %s: pool, tag and discovery" % id)
	_check(_card("family_ties").max_stacks == 0, "Family Ties stacks (Quick Bonds merged into Old Friends)")
	var kin := Kinships.find(dreams)
	_check(kin != null, "Kinships found in the run")
	if kin == null:
		return
	var harmony := _card("sweet_harmony")
	var grove := _card("grove_of_kin")
	var kindling := _card("kin_and_kindling")
	var saved: Array = kin.pairs
	kin.pairs = []
	_check(dreams.count_kinships() == 0 and not dreams.is_eligible(harmony), "Sweet Harmony needs a Kinship on the map")
	_check(not dreams.is_in_build(harmony), "…and kinship cards aren't your build yet")
	kin.pairs = [{}]
	_check(dreams.is_eligible(harmony) and not dreams.is_in_build(harmony), "…offered with one, but not weighted up until you take a Kinship card")
	dreams.grove_cards.assign(["grove_of_kin", "kin_and_kindling"])
	_check(not dreams.is_eligible(grove, 2), "Grove of Kin needs 2 Kinships")
	kin.pairs = [{}, {}]
	_check(dreams.is_eligible(grove, 2) and not dreams.is_eligible(grove, 1), "…offered with 2, from act 2")
	_check(not dreams.is_eligible(kindling), "Kin and Kindling needs a Reaction card too")
	dreams.take(_card("seeping"))  # A Reaction card
	_check(dreams.is_eligible(kindling), "…Entwined once a Kinship and a Reaction card are both there")
	kin.pairs = saved
	_reset()

# Generic Rares 135–141 (dream_design.md "Generic Rares").
func _test_generic_rares() -> void:
	_reset()
	var sprout: TowerData = load("res://resource/tower/sprout.tres")
	# Root Network: sides only; II adds diagonals
	var network := _card("root_network")
	_check(dreams.can_offer(network) and not dreams.is_eligible(network), "Root Network: 4+ Sprouts is a soft Need")
	dreams.take(network)
	var a := _plant("sprout", 0, 0)
	_plant("sprout", 1, 0)
	_plant("sprout", 2, 0)
	var alone := _plant_at("sprout", Vector2(100, 102), 0)
	var diagonal := _plant_at("sprout", Vector2(103, 101), 0)
	var row := _find(dreams.get_card_effects(sprout, a.cell, a), "root_network")
	_check(row.active and is_equal_approx(row.damage, 0.18) and row.note == "network of 3", "Root Network: 3 in a row = +18%% each (%s)" % row)
	_check(is_equal_approx(dreams.get_soothe_multiplier(a), 1.18), "…and it's real damage")
	_check(not _find(dreams.get_card_effects(sprout, alone.cell, alone), "root_network").active, "…a lone Sprout has no network")
	_check(not _find(dreams.get_card_effects(sprout, diagonal.cell, diagonal), "root_network").active, "…diagonals don't join")
	dreams.take(_card("root_network_ii"))
	row = _find(dreams.get_card_effects(sprout, a.cell, a), "root_network_ii")
	_check(row.active and is_equal_approx(row.damage, 0.32), "Root Network II: diagonals join, +8%% each (%s)" % row)
	_clear_towers()

	# Old Growth and Thinning the Herd (per-Warden damage)
	_reset()
	dreams.take(_card("old_growth"))
	dreams.take(_card("thinning_the_herd"))
	var warden := _plant("sporeling", 0, 0)
	var base := dreams.get_soothe_multiplier(warden)
	warden.set_meta(&"drifts_stood", 5)
	_check(is_equal_approx(dreams.get_soothe_multiplier(warden) - base, 0.20), "Old Growth: 5 drifts = +20%")
	warden.set_meta(&"drifts_stood", 15)
	_check(is_equal_approx(dreams.get_soothe_multiplier(warden) - base, 0.40), "…15 drifts = +40%")
	var victim := Node2D.new()
	main.add_child(victim)
	victim.global_position = warden.global_position
	dreams._count_herd(victim)
	dreams._count_herd(victim)
	_check(is_equal_approx(dreams.get_herd_bonus(warden), 0.04), "Thinning the Herd: +2% per dispel in range")
	dreams._on_drift_started(1)
	_check(dreams.get_herd_bonus(warden) == 0.0 and DreamState.drifts_stood(warden) == 16, "…until the drift ends; a drift start counts a drift stood")

	# First Light and Bitter Hedges (per hit)
	dreams.take(_card("first_light"))
	_check(dreams.on_hit_multiplier(warden, victim) == 3.0 and dreams.on_hit_multiplier(warden, victim) == 1.0,
		"First Light: ×3 on a Warden's first hit on a nightmare only")
	dreams.take(_card("bitter_hedges"))
	var wall := _plant_at("thornwall", Vector2(105, 101), 0)
	_plant_at("thornwall", Vector2(106, 101), 0)
	dreams._bitter_pass(victim, Vector2(105, 100))
	_check(is_equal_approx(dreams.get_bitter_bonus(victim), 0.08), "Bitter Hedges: +8% after passing a wall")
	dreams._bitter_pass(victim, Vector2(106, 100))
	_check(is_equal_approx(dreams.on_hit_multiplier(warden, victim), 1.16), "…+8% per wall, on every hit")
	dreams._briar_clock += 2.5
	_check(dreams.get_bitter_bonus(victim) == 0.0, "…for 2 s")
	_check(wall != null, "walls planted")
	victim.free()
	_clear_towers()

func _find(rows: Array[Dictionary], id: String) -> Dictionary:
	for row in rows:
		if row.id == id:
			return row
	return {"active": false, "damage": 0.0, "note": ""}

# Owning a Warden for a card's Needs: unlocked and grown this run (round 5: unlocked alone isn't enough).
func _own(id: String) -> void:
	dreams.unlocked[id] = true
	dreams.grown_wardens[id] = true

func _reset() -> void:
	dreams.stacks.clear()
	dreams.unlocked = {"sprout": true, "thornwall": true}
	dreams.grown_wardens.clear()
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
