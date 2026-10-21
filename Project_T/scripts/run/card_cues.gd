extends RefCounted
## The card -> field cue table (visual feedback spec, owner 2026-10-18; D:\Projects\logs\dream_council\visual_feedback_spec.md
## section C). One list so the visual language stays one list: Roguelite Code owns the table and the event
## (DreamState.card_cue); Tower Code / Enemy Code / UI / Fx draw the cues. Preloaded as DreamState.CARD_CUES (no class_name).
## Keys are card ids (UpgradeData.id). Every live card is in CUES, or is an unlock card (dream_<warden>: visible as the
## new Warden), or is listed in NATURAL (its effect already shows) or OFFER_ONLY (it changes the Dream screen / HUD only).
## tests/test_card_cues.gd checks that.

# The 10 shared cues (spec C1). Colour language: Dream = HEARTLIGHT, GLOW only at tier 3 (owner 2026-10-18).
const DREAM_GLOW := &"dream_glow"  # C1: part B tiers on the Warden's attacks (DreamState.boost_tier)
const DREAM_FLECK := &"dream_fleck"  # C2: a 3 px HEARTLIGHT fleck on a hit a card boosted (Event.card_damage)
const STATUS_POP := &"status_pop"  # C3: the status badge on the nightmare bumps; LINGER cards: the linger rim variant
const SLOW_RIPPLE := &"slow_ripple"  # C4: a low ground ripple when a card slows, holds, sleeps or pulls
const REACTION_ACCENT := &"reaction_accent"  # C5: a HEARTLIGHT card pip beside the Reaction word, effect x1.15
const REACH_RING := &"reach_ring"  # C6: the affected Wardens show their real range once (taken, and each drift start)
const DEW_SPARKLE := &"dew_sparkle"  # C7: DewPopup with a Dream-leaf glyph; the rest report names the card
const LEAF_REGROW := &"leaf_regrow"  # C8: mended_leaf at the Heartwood + the leaves counter pulse
const RANK_SHIMMER := &"rank_shimmer"  # C9: rising HEARTLIGHT motes + rank art flash
const DREAM_THREAD := &"dream_thread"  # C10: a thin warm thread between the two things a card links

const CUE_IDS: Array[StringName] = [DREAM_GLOW, DREAM_FLECK, STATUS_POP, SLOW_RIPPLE, REACTION_ACCENT, REACH_RING,
	DEW_SPARKLE, LEAF_REGROW, RANK_SHIMMER, DREAM_THREAD]

const CUES := {
	# Flat or positional damage multipliers -> C1 (static tier)
	&"blood_is_thicker": DREAM_GLOW, &"chosen_few": DREAM_GLOW, &"few_and_mighty": DREAM_GLOW,
	&"forest_floor": DREAM_GLOW, &"hedge_maze": DREAM_GLOW, &"odd_one_out": DREAM_GLOW, &"mixed_grove": DREAM_GLOW, &"mixed_grove_ii": DREAM_GLOW,
	&"monoculture": DREAM_GLOW, &"thin_bark": DREAM_GLOW, &"kind_canopy": DREAM_GLOW,
	&"solitude": DREAM_GLOW, &"straightaway": DREAM_GLOW, &"narrow_way": DREAM_GLOW, &"tended_stumps": DREAM_GLOW,
	&"wildwood_reclaimed": DREAM_GLOW, &"crossroads": DREAM_GLOW, &"cozy_corners": DREAM_GLOW,
	&"forests_edge": DREAM_GLOW, &"endless_rings": DREAM_GLOW, &"last_leaf": DREAM_GLOW, &"venom_bloom": DREAM_GLOW,
	&"the_quiet_ones": DREAM_GLOW, &"crowd_breaker": DREAM_GLOW, &"root_network": DREAM_GLOW,
	&"root_network_ii": DREAM_GLOW, &"one_bough": DREAM_GLOW,
	# Timed damage or speed boosts -> C1 surge (SURGE below: tier +1 while on)
	&"thinning_the_herd": DREAM_GLOW, &"hot_on_their_heels": DREAM_GLOW, &"restless_night": DREAM_GLOW,
	&"shiny_things": DREAM_GLOW, &"quickening": DREAM_GLOW, &"quickening_ii": DREAM_GLOW, &"close_shave": DREAM_GLOW, &"fresh_growth": DREAM_GLOW,
	&"quick_step": DREAM_GLOW, &"desperate_bloom": DREAM_GLOW, &"momentum": DREAM_GLOW,
	# Attack speed -> C1
	&"the_last_light": DREAM_GLOW, &"rootbound": DREAM_GLOW, &"sprout_chorus": DREAM_GLOW,
	&"spinning_corners": DREAM_GLOW, &"hairpin_winds": DREAM_GLOW, &"close_quarters": DREAM_GLOW,
	&"whirlwind_heart": DREAM_GLOW, &"quick_draw": DREAM_GLOW,
	# Conditional per-hit damage -> C2 (each calls DamageLog.note_card_bonus)
	&"bright_marks": DREAM_FLECK, &"crosswind": DREAM_FLECK, &"deep_frost": DREAM_FLECK, &"deep_sleep": DREAM_FLECK,
	&"falling_weight": DREAM_FLECK, &"heavy_seed": DREAM_FLECK, &"hunters_patience": DREAM_FLECK,
	&"last_stand": DREAM_FLECK, &"murmur": DREAM_FLECK, &"steady_aim": DREAM_FLECK, &"sharpened_light": DREAM_FLECK,
	&"bitter_hedges": DREAM_FLECK, &"nightshade": DREAM_FLECK, &"ill_wind": DREAM_FLECK, &"damp_rot": DREAM_FLECK,
	&"first_light": DREAM_FLECK, &"front_line": DREAM_FLECK, &"passing_thread": DREAM_FLECK,
	&"shared_light": DREAM_FLECK, &"fruiting": DREAM_FLECK, &"heavy_going": DREAM_FLECK, &"parting_puff": DREAM_THREAD,  # Non-status builds 2026-10-19
	&"long_way_round": DREAM_FLECK, &"high_tide": DREAM_FLECK, &"seeping": DREAM_FLECK, &"slow_burn": DREAM_FLECK,
	&"rain_on_glass": DREAM_FLECK, &"thousand_cuts": DREAM_FLECK, &"head_start": DREAM_FLECK,
	&"kindled_gaze": DREAM_FLECK, &"millstone": DREAM_FLECK, &"needle_point": DREAM_FLECK,
	&"opening_fracture": DREAM_FLECK, &"sap_rising": DREAM_FLECK, &"wash_away": DREAM_FLECK, &"last_drop": DREAM_FLECK,
	# Reaction modifiers -> C5
	&"brimming": REACTION_ACCENT, &"sparking_spores": REACTION_ACCENT, &"wildfire_spores": REACTION_ACCENT,
	&"rolling_thunder": REACTION_ACCENT, &"rolling_thunder_ii": REACTION_ACCENT, &"deep_water": REACTION_ACCENT,
	&"sweet_harmony": REACTION_ACCENT, &"kin_and_kindling": REACTION_ACCENT, &"crown_of_leaves": REACTION_ACCENT,
	&"ember_count": REACTION_ACCENT,
	&"old_rain": REACTION_ACCENT, &"never_quite_dry": REACTION_ACCENT,
	&"eye_of_the_tempest": REACTION_ACCENT, &"mountains_fall": REACTION_ACCENT, &"endless_night": REACTION_ACCENT,
	&"alarm_bells": REACTION_ACCENT, &"old_heart": REACTION_ACCENT, &"ring_of_rings": REACTION_ACCENT,
	&"quick_reactions": REACTION_ACCENT, &"called_from_afar": REACTION_ACCENT,
	# Extra stacks or statuses -> C3 (pop)
	&"breathe_it_in": STATUS_POP, &"mixed_company": STATUS_POP, &"pass_it_round": STATUS_POP,
	&"spore_ring": STATUS_POP, &"mothers_hand": STATUS_POP, &"deep_grain": STATUS_POP, &"resonance": STATUS_POP,
	&"static_bloom": STATUS_POP, &"windborne_rain": STATUS_POP, &"mycelium": STATUS_POP, &"overnight": STATUS_POP,
	&"seeping_in": STATUS_POP, &"gone_to_seed": STATUS_POP, &"eternal_static": STATUS_POP,
	&"heavy_eyelids": STATUS_POP, &"dream_residue": STATUS_POP, &"afterroot": STATUS_POP,
	&"graft_of_dreams": STATUS_POP, &"charged_feathers": STATUS_POP, &"pollen_beaks": STATUS_POP,
	&"shared_fever": STATUS_POP, &"snare_line": STATUS_POP, &"bad_dreams": STATUS_POP, &"many_threads": STATUS_POP,
	# Statuses last longer or don't wear off -> C3 linger rim (LINGER below)
	&"lingering_ground": STATUS_POP, &"long_light": STATUS_POP, &"lullaby": STATUS_POP,
	&"bound_and_burning": STATUS_POP, &"steeped": STATUS_POP, &"ebb": STATUS_POP,
	&"homesick": STATUS_POP, &"topped_up": STATUS_POP, &"patient_roots": STATUS_POP, &"sodden": STATUS_POP,
	# Slow, hold, sleep, pull -> C4
	&"switchback": SLOW_RIPPLE, &"hobble": SLOW_RIPPLE, &"root_web": SLOW_RIPPLE, &"snag": SLOW_RIPPLE,
	&"thorn_snare": SLOW_RIPPLE, &"hushed_hedge": SLOW_RIPPLE, &"scented_hedge": SLOW_RIPPLE,
	&"sweet_scent": SLOW_RIPPLE, &"first_frost": SLOW_RIPPLE, &"old_growth": SLOW_RIPPLE,
	&"rooted_nightmares": SLOW_RIPPLE,
	# Range and aura reach -> C6
	&"long_shadows": REACH_RING, &"longer_roots": REACH_RING, &"undergrowth": REACH_RING, &"hush": REACH_RING,
	&"wide_petals": REACH_RING, &"hollow_ground": REACH_RING, &"close_kin": REACH_RING,
	&"grandfather_stump": REACH_RING, &"warm_hearth": REACH_RING, &"canopy": REACH_RING,
	&"dew_trail": REACH_RING,
	# Links between things -> C10
	&"tangled_lightning": DREAM_THREAD, &"carried_on_the_wind": DREAM_THREAD, &"eddy": DREAM_THREAD,
	&"hedgerow_roots": DREAM_THREAD, &"extended_family": DREAM_THREAD, &"spent_light": DREAM_THREAD,
	&"guiding_light": DREAM_THREAD, &"guiding_light_ii": DREAM_THREAD, &"sparks_fly": DREAM_THREAD,
	&"hammerfall": DREAM_THREAD, &"thunderstruck": DREAM_THREAD, &"chain_of_lanterns": DREAM_THREAD,
	&"brushfire": DREAM_THREAD, &"flashover": DREAM_THREAD, &"gathering_storm": DREAM_THREAD,
	&"nothing_wasted": DREAM_THREAD, &"struck_twice": DREAM_FLECK, &"conductive_soil": DREAM_THREAD, &"stolen_away": DREAM_THREAD,
	&"briar_crown": DREAM_THREAD,  # (Not in the spec's tables: a wall relay, as Hedgerow Roots)
	# Dew and Dreamlight -> C7
	&"winding_path": DEW_SPARKLE, &"scarred_bark": DEW_SPARKLE, &"held_breath": DEW_SPARKLE,
	&"wild_dew": DEW_SPARKLE, &"cheap_seeds": DEW_SPARKLE,
	&"evergreen": DEW_SPARKLE, &"morning_dew": DEW_SPARKLE, &"seedfall": DEW_SPARKLE, &"dew_bowl": DEW_SPARKLE,
	&"burn_back": DEW_SPARKLE, &"heartwoods_reach": DEW_SPARKLE, &"reclaimed_earth": DEW_SPARKLE,
	&"kins_keepsake": DEW_SPARKLE, &"headlong": DEW_SPARKLE,
	&"glimmering_hunt": DEW_SPARKLE, &"sudden_insight": DEW_SPARKLE,
	# Leaves -> C8
	&"deep_roots": LEAF_REGROW, &"thick_bark": LEAF_REGROW, &"press_on": LEAF_REGROW,
	# Ranks and Nurture -> C9
	&"clean_night": RANK_SHIMMER, &"wild_growth": RANK_SHIMMER, &"tender_care": RANK_SHIMMER, &"tender_care_ii": RANK_SHIMMER,
	&"nursery": RANK_SHIMMER, &"specialist": RANK_SHIMMER, &"shared_training": RANK_SHIMMER,
	&"elder_kin": RANK_SHIMMER, &"the_old_ones": RANK_SHIMMER, &"old_friends": RANK_SHIMMER,
	&"deeper_rings": RANK_SHIMMER, &"sunlit_rest": RANK_SHIMMER, &"growth_rings": RANK_SHIMMER,
	&"seedling_gift": RANK_SHIMMER, &"towering": RANK_SHIMMER,
}

# A second cue the same moment also shows ("+C3", "+C10", "+C9" in the spec).
const EXTRA_CUES := {
	&"thousand_cuts": [STATUS_POP], &"brimming": [STATUS_POP], &"kin_and_kindling": [STATUS_POP],
	&"never_quite_dry": [STATUS_POP], &"shared_fever": [DREAM_THREAD], &"spent_light": [STATUS_POP],
	&"living_walls": [RANK_SHIMMER], &"hunters_moon": [STATUS_POP], &"spore_cascade": [STATUS_POP],
	&"one_bough": [RANK_SHIMMER], &"sodden": [DREAM_FLECK],
}

# STATUS_POP cards that hold a status: the linger rim variant (DEWLIGHT rim on the time bar; never_quite_dry's extra too).
const LINGER: Array[StringName] = [&"lingering_ground", &"long_light", &"lullaby", &"bound_and_burning",
	&"steeped", &"ebb", &"homesick", &"topped_up", &"patient_roots", &"never_quite_dry", &"sodden"]

# Timed speed / damage cards: while one is on for a Warden its boost tier is +1 (spec B1 dream_surge; DreamState.boost_tier).
# Rule ids (the Dream rows carry card.rule_id).
const SURGE: Array[StringName] = [&"thinning_the_herd", &"hot_on_their_heels", &"restless_night", &"shiny_things",
	&"quickening", &"close_shave", &"fresh_growth", &"quick_step", &"desperate_bloom", &"momentum"]

# Already visible by nature (spec C2): no cue, only the badge pop (credit with the source Warden).
const NATURAL: Array[StringName] = [&"great_ripple", &"loose_stones", &"seed_storm", &"sharp_beaks",
	&"homing_instinct", &"ring_dance", &"encore", &"witching_bend", &"heavy_heart", &"reprise", &"chain_bloom",
	&"thorny_walls", &"twig_walls", &"living_walls", &"tangled_release", &"nod_off", &"fever_pitch", &"hunters_moon",
	&"spore_cascade", &"prism_heart", &"mushroom_rain", &"deep_stillness", &"old_hand", &"full_moon",
	&"still_target", &"patient_aim", &"falling_stars", &"called_shot", &"starlit_aim",
	&"lingering_splash",
	# Bell repeats keep their own chime / double flash / pulse (d168b7e6) and add the badge pop
	&"in_time", &"refrain", &"knell", &"on_the_beat", &"da_capo", &"second_verse", &"rude_awakening",
	# Signature looks (DreamBurst colours: the card's look is the card)
	&"afterglow", &"dawnbreak", &"spillover", &"shattering_blow"]

# Dream-screen only: they change offers / rerolls / the Dew roll (the Dream screen or HUD already shows it).
const OFFER_ONLY: Array[StringName] = [&"wandering_mind", &"lucid_dreaming", &"lucid_dream", &"mystery_dream",
	&"restless_dreams", &"second_wind", &"double_or_nothing"]

# Rule ids that differ from their card id (callers may credit by rule id).
const ALIASES := {&"back_row_roots": &"longer_roots", &"last_light": &"the_last_light", &"old_ones": &"the_old_ones"}

static func card_of(id: StringName) -> StringName:
	return ALIASES.get(id, id)

# The card's main cue (&"" = none: unlock cards, NATURAL, OFFER_ONLY, Calling evolutions).
static func cue_for(id: StringName) -> StringName:
	return CUES.get(card_of(id), &"")

# Every cue the card shows when it fires: its main cue, then any extra (empty for none).
static func cues_for(id: StringName) -> Array:
	var card := card_of(id)
	var out: Array = []
	var main: StringName = CUES.get(card, &"")
	if main != &"":
		out.append(main)
	for cue in EXTRA_CUES.get(card, []):
		if not out.has(cue):
			out.append(cue)
	return out

static func is_linger(id: StringName) -> bool:
	return LINGER.has(card_of(id))

static func needs_no_cue(id: StringName) -> bool:
	var card := card_of(id)
	return NATURAL.has(card) or OFFER_ONLY.has(card)
