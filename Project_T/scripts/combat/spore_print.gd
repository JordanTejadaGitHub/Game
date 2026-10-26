extends "res://scripts/combat/class_kit.gd"
# The Sporeling class (dream_council_review.md 20 "Sporeling: spores pile on fast", rulings in 21).
# Calling, Spore Print: a Poisoned nightmare dispelled by any Warden leaves a mushroom on the path; the next walking
# nightmare to step on it takes a dose (3 Poisoned at once). Mushrooms are objects on route points: one per step, no
# timer, they survive rests (saved with the run), 40 on the map at most. Mushrooms and doses are the first pick's only
# (place_on, 2026-10-14); the 5 class cards use them. The 10 lent cards never do: they stack statuses from spore
# Wardens, where Wardens stand and Poisoned, for any Sporeling owner.
# Every number is a paper starting value.

const GROUP := &"spore_print"
const FAMILY := "sporeling"
const LINE := "spore"

const DOSE := 3  # Poisoned a dose adds
const MUSHROOM_MAX := 40  # On the map; over that the oldest goes, mushrooms no card regrows first
const FALL_CELLS := 1.0  # A nightmare that falls further than this from the route leaves no mushroom
const STEP_CELLS := 0.3  # A walker's centre this close to a mushroom's point has stepped on it
const BED_EVERY := 5.0  # Mushroom Bed: a step touching 2 spore Wardens grows one this long after it is emptied
const BED_WARDENS := 2
const KEPT_EVERY := 6.0  # Kept Ground: a mushroom touching only one spore Warden grows back
const SIDE_EVERY := 3.0  # Side by Side: a step touching a spore Warden and another family's Warden
const TWIN_CAPS := 2  # Twin Caps: doses per mushroom…
const TWIN_SLOWER := 2.0  # …and every regrow this much slower
const OPEN_SEASON_EVERY := 2.0  # Open Season: once per Warden and nightmare
const OPEN_SEASON_WINDOW := 4.0  # …and the dose waits this long for that Warden's next attack
const HAZE_MUSHROOMS := 4  # Spore Haze: mushrooms near a single-target spore Warden
const HAZE_OTHERS := 4
const KICKED_OTHERS := 4  # Kicked Up
const GROWS_MAX := 6  # It Grows on You: a dose is at most this big
const HELPING_STACKS := 3  # Second Helping: the partner's next status application adds this many
const EVERYTHING_STACKS := 3  # Everything Grows
const HOTHOUSE_AT := 6  # Hothouse: at this much Poisoned (Brimming does not change it)…
const HOTHOUSE_ADD := 5  # …each other status gains this many, quietly, once per nightmare
const OVERNIGHT_STACKS := 3  # Overnight: a spore Warden's attack adds this many to a nightmare carrying another family's status
const OVERNIGHT_EVERY := 1.0
const SINGLE_TARGET := ["sporeling", "driftspore", "inkcap", "lichenling", "old_lichen", "deliquescent"]  # Spore Haze

# Card rule ids
const MUSHROOM_BED := &"mushroom_bed"
const OPEN_SEASON := &"open_season"
const SPORE_HAZE := &"spore_haze"
const KEPT_GROUND := &"kept_ground"
const KICKED_UP := &"kicked_up"
const IT_GROWS := &"it_grows_on_you"
const PASS_IT_ROUND := &"pass_it_round"
const SECOND_HELPING := &"second_helping"
const EVERYTHING_GROWS := &"everything_grows"
const TWIN := &"twin_caps"
const SIDE_BY_SIDE := &"side_by_side"
const LEAF_LITTER := &"leaf_litter"
const HOTHOUSE := &"hothouse"  # Lent
const OVERNIGHT := &"overnight"  # Lent
# Stack cards (lent, 2026-10-13; sporeling_stack_cards.md with the council's fixes, new_lent_td.md)
const NARROWS := &"narrows"
const NARROWS_EXTRA := 2  # Narrows: a status hit adds this many more (3 at once for a 1-stack hit)…
const NARROWS_SMALL := 1  # …only this many on Charged and Exposed (more made bolts 3x as often / Exposed near-permanent)
const SEEPING_IN := &"seeping_in"
const SEEP_STEPS := 6.0  # Seeping In: every this many steps walked in a spore Warden's range…
const SEEP_STACKS := 3  # …each status it carries gains this many (quietly: never starts one)
const MIXED_COMPANY := &"mixed_company"
const MIXED_OTHERS := 2  # (Retired by hard cards 2026-10-16: Mixed Company now scales; nothing reads it)
const MIXED_PER_STATUS := 1  # Mixed Company (hard cards 2026-10-16): 1 more stack for each status the nightmare carries…
const MIXED_MAX := 4  # …up to 4 more…
const MIXED_SMALL_MAX := 2  # …at most 2 on Charged and Exposed (TD)…
const MIXED_DROWSY_MAX := 1  # …and 1 on Drowsy (bounded control)
const STACK_EVERY := 1.0  # Narrows and Mixed Company: once a second per Warden each
const NARROWS_META := &"sp_narrows_next"  # On a Warden
const MIXED_META := &"sp_mixed_next"  # On a Warden
const SEEP_META := &"sp_seep"  # On a nightmare: [furthest route index counted, steps so far]
# Lent, 2026-10-14 (lent_noplace_sporeling_firefly.md; dream_council_review.md 26). Every stack card on one hit adds
# together, within the caps (ruling 6).
const BREATHE_IN := &"breathe_it_in"
const BREATHE_EXTRA := 2  # Breathe It In: a spore Warden's Poisoned hit inside another spore Warden's range adds this many
const BREATHE_META := &"sp_breathe_next"  # On a Warden
const SITTING_DUCKS := &"sitting_ducks"
const DUCKS_EXTRA := 2  # Sitting Ducks: a status hit on a held or sleeping nightmare near a spore Warden adds this many…
const DUCKS_SMALL := 1  # …this many on Charged and Exposed
const DUCKS_META := &"sp_ducks_next"  # On a Warden
const HEMMED_IN := &"hemmed_in"
const HEMMED_SPORES := 2  # Hemmed In: another family's Warden touching this many spore Wardens doubles its status hits
const HEMMED_META := &"sp_hemmed_next"  # On a Warden: Charged and Exposed extra at most once a second
# Trait rework (owner 2026-10-15, trait_lent_proposal.js): the lent cards make ANY family's status stack faster, the
# spore Wardens' own Poisoned included. Drowsy counts too, within its normal cap (the owner asked about a bigger Drowsy
# cap; answer: no, include it in the stacking instead; STACK_DROWSY switches it off).
const STACK_DROWSY := true
const BREATHE_ONE := 1  # Breathe It In: any Warden's status landing inside a spore Warden's range: 1 more, once a second per Warden…
const BREATHE_SLEEPER := 3  # …3 more on a nightmare asleep or Held (card pass 2026-10-16: absorbs Sitting Ducks)
const PASS_STACKS := 3  # Pass It Round: a Warden touching a spore Warden (a spore Warden touches itself): 3 more with its first application on each nightmare
const PASS_META := &"sp_pass"  # On a nightmare: {Warden id: true}
const MYCELIUM := &"mycelium"
const MYCELIUM_SPROUTS := 3  # Mycelium: at most this many Sprouts feed one nightmare a second
const MYCELIUM_META := &"sp_mycelium"  # On a nightmare: [second started, Sprouts counted]
const OVERNIGHT_FEED := 2  # Overnight: a spore Warden's hit adds this many to each status other families put on the nightmare
const GONE_TO_SEED := &"gone_to_seed"
const SEED_STACKS := 5  # Gone to Seed: a Warden's hit fills a status near a spore Warden: every other status on it gains this many
const SEED_EVERY := 2.0  # …once per nightmare in this long
const SEED_META := &"sp_seed_next"  # On a nightmare
const SEED_BEFORE_META := &"sp_seed_before"  # On a nightmare: [status, stacks] just before a Warden's own application (Gone to Seed: only the hit that fills it)
const SPORE_RING := &"spore_ring"
const SPORE_RING_MAX := 3  # Spore Ring (replaced Narrows, council 2026-10-15): a spore Warden's Poisoned +1 per spore Warden touching it, up to 3
# (No per-hit limit on extra stacks: owner 2026-10-16. Each status's maximum is the ceiling, and extra stacks never
# complete a Charged bolt: only a Warden's own hit does.)
# --- Calling evolutions (scripts/combat/calling_paths.gd; council calling_evolution_*.md, owner 2026-10-16) -----------
# Read with evo(id). Every number is a paper starting value (Balancing). Each one shows itself: a puff, a thread, a
# glow or a flash, and credits its id (DreamState.note_card).
# Rebuilt 2026-10-23 (owner, dream_council_review.md 33; D:\Projects\logs\dream_council\evo_fixed_sporeling.md,
# evo_shared_spec.md): Spread = the trail wears them down (Poisoned grows with the steps walked), Focus = extra free hits
# (class_kit.calling_hit, damage only), Support = other families' statuses stack faster (their own slot) and Host Grove's
# Potency. Rows dropped from the table are "retired" there; their code below stays for an old save's path.
const EVO_WINDBLOWN := &"sp_windblown"
const SEED_STEPS := 3  # Windblown: the seed lands this many steps further down the walker's own leg
const EVO_DRIFTING := &"sp_drifting"  # Final pass 2026-10-24: a nightmare's Poisoned +1% per step since its first dose…
const DRIFT_PER_STEP := 0.01
const DRIFT_MAX := 0.30  # …up to +30%…
const DRIFT_BOSS_MAX := 0.15  # …bosses +15% (its old "more mushrooms" limit is gone: MUSHROOM_MAX 40 always)
const GEN_FELL := 0  # A mushroom's "gen": left where a nightmare fell (or regrown)…
const GEN_PLANTED := 1  # …planted by a dose (Windblown), Windfall or Sporefall…
const GEN_AGAIN := 2  # …planted again by a planted one (Drifting Spores). Higher gens go first when there are too many.
const EVO_SEASON := &"sp_season"
const SEASON_AT := 15  # Spore Season: while this many mushrooms grow (planted ones too), Drifting Spores counts from the
const SEASON_PER_STEP := 0.01  # nightmare's first step on its route, not its first dose…
const SEASON_MAX := 0.60  # …up to this…
const SEASON_BOSS_MAX := 0.30  # …bosses up to this
const SEASON_LAP_POINTS := 24  # A nightmare this many route points behind its furthest has started its route again: it counts again
const SEASON_META := &"sp_season_walk"  # On a nightmare: [first index seen, furthest index, passed_waymark, haze bursts paid, first dose index (-1: none)]
const EVO_HEAVY_AIR := &"sp_heavy_air"  # Heavy Air (Spore Season's Deepen): a nightmare at Season's +60% doses without eating
const HEAVY_SEEN := "heavy_seen"  # On a mushroom it left: {nightmare id: true}, each nightmare dosed there once
const HEAVY_GLOW := "heavy_glow"  # On a mushroom: when its glow (a full-haze nightmare on it) ends
const SEASON_CREDIT_META := &"sp_season_credit"  # On a nightmare: when Spore Season may be credited again (once a second)
const EVO_THICK_HAZE := &"sp_thick_haze"
const HAZE_EVERY_POINTS := 20  # Thick Haze: past Spore Season's limit, every 10 steps (20 route points)…
const HAZE_SECONDS := 1.0  # …1 s of its Poisoned damage at once…
const HAZE_BOSS := 0.5  # …bosses take half
const HAZE_TAG := &"haze"  # In CLASS_TAGS and Reactions.EFFECT_TAGS: Potency, Seeping and Nightshade once in take_damage
const EVO_FAIRY_PATH := &"sp_fairy_path"
const FAIRY_EVERY := 10.0  # Fairy Path: each Sprout's bed step grows its mushroom back this long after it is used
const EVO_DEATHCAP := &"sp_deathcap"
const DEATHCAP_SECONDS := 2.0  # Deathcap: a Poisoned nightmare stepping on a mushroom takes this many seconds of its poison at once…
const DEATHCAP_EVERY := 1.0  # …each nightmare once a second (Rot Ground shares it)…
const DEATHCAP_BOSS := 0.5  # …bosses take half
const DEATHCAP_TAG := &"deathcap"  # In CLASS_TAGS and Reactions.EFFECT_TAGS
const DEATHCAP_META := &"sp_deathcap_next"  # On a nightmare
const EVO_ROT_GROUND := &"sp_witch_ground"  # Rot Ground (id kept from the draft "Witch Ground"): a bed step bursts without its cap
# Final pass 2026-10-24 (evo_fixed_sporeling.md): Fairy Path, Deathcap and Rot Ground retired (code above kept for old saves)
const EVO_DEATHCAP_FIELD := &"sp_deathcap_field"  # Deathcap (follow-up): each of the first 3 mushrooms a nightmare steps on bursts…
const FIELD_BURSTS := 3  # …this many a walk (laps and the Waymark start it again), after the dose, no throttle…
const FIELD_SECONDS := 2.0  # …this many seconds of its Poisoned at once (bosses DEATHCAP_BOSS)
const BURSTS_META := &"sp_field_bursts"  # On a nightmare: [bursts this walk, furthest index, passed_waymark]
const EVO_ROT_BLOOM := &"sp_rot_bloom"  # Rot Bloom (capstone): the 3rd burst of a walk…
const ROT_BLOOM_SECONDS := 6.0  # …is this many seconds…
const ROT_BLOOM_TAG := &"rot_bloom"  # …tagged rot_bloom (CLASS_TAGS, Reactions.EFFECT_TAGS)
const EVO_SPROUT_BEDS := &"sp_sprout_beds"  # Sprout Beds (Rot Bloom's Deepen): Fairy Path's beds on the nearest step within…
const BED_CELLS := 2.0  # …this many cells of the Sprout (FAIRY_EVERY to grow back)
# Focus (every free hit: class_kit.calling_hit, tag free_hit, damage only; its own budget, never FREE_META)
const EVO_CLUMP := &"sp_clump"
const CLUMP_STEPS := 3  # Clump: a new mushroom joins one within this many steps…
const CLUMP_MAX := 4  # …up to this many in a clump
const CLUMP_WARDENS := 3  # …a step on it: a free hit from each attacking Warden touching it, the strongest first, at most this many…
const FOCUS_BOSS := 0.5  # …bosses take half
const FOCUS_META := &"sp_focus"  # On a Warden: [second started, free hits given in it] (Clump 1 a second, Trampled Ground 2)
const EVO_TRAMPLED := &"sp_trampled"
const TRAMPLE_RANK := 3  # Trampled Ground: a rank III+ Warden touching a clump…
const TRAMPLE_HITS := 2  # …gives this many free hits to each stepper, up to this many a second…
const TRAMPLE_SECOND := 0.5  # …the second at half
const EVO_THRONE := &"sp_throne"  # Toadstool Throne (final pass 2026-10-24): one throne, the clump of the Warden at a clump
const THRONE_AGE := 10  # planted earliest, once it was planted this many drifts ago; it keeps its last mushroom
const FINAL_TIER := 3  # A final form (Ascended too)
const EVO_PILE_ON := &"sp_pile_on"
const PILE_RANK := 3  # Pile-On: a rank III+ Warden's hit within 2 steps of a clump it touches…
const PILE_POINTS := 4  # …(2 steps = 4 route points) calls a free hit from each other rank III+ Warden there
const EVO_ELDER := &"sp_elder_cap"  # Elder Cap: the throne's final form gives a free hit there for each of its own attacks
const ATTACK_META := &"sp_attack_ready"  # On a Warden: one free hit waiting from its last attack (Elder Cap, Retinue)
const EVO_TRODDEN := &"sp_trodden"
const TRODDEN_POINTS := 2  # Trodden Path: the route points up to 1 step either side of a clump count as it…
const TRODDEN_EVERY := 1.0  # …with its own +1 free hit a second per Warden there…
const TRODDEN_META := &"sp_trodden_next"  # …(on a Warden: when the next may land)
const TRODDEN_SEEN_META := &"sp_trodden_seen"  # On a nightmare: {"point:side": true}: each side of each clump once
const EVO_RETINUE := &"sp_retinue"  # Retinue (final pass 2026-10-24): the other Wardens at a throne (Clump's set), any rank…
const RETINUE_MAX := 2
const RETINUE_SHARE := 0.5  # …at half their hit, once for each of their own attacks
# Support (their extra stacks: one slot of their own in _stack_cards)
const SUPPORT_MAX := 2  # Balancing 2026-10-23: at most 2 extra per hit from Feeding Ground and Host Trees together…
const SUPPORT_SMALL := 1  # …Charged and Exposed at most 1…
const SUPPORT_SMALL_EVERY := 1.0  # …once a second per Warden…
const SUPPORT_SMALL_META := &"sp_support_small"  # (on a Warden)
const SUPPORT_HIT_FLOOR := 3  # …still inside the per-hit extra cap: max(2 x the hit's stacks, 3)…
const SUPPORT_HIT_SMALL := 2  # …Charged / Exposed 2 (Balancing 2026-10-23)
const EVO_BORROWED := &"sp_borrowed"  # Shared Caps (id kept)
const SHARED_STACKS := 2  # Shared Caps: a dose adds this many to the status the highest-rank other-family Warden touching it put on…
const SHARED_SMALL := 1  # …Charged and Exposed this many
const EVO_FEEDING := &"sp_feeding"
const FEED_POINTS := 12  # Feeding Ground: a dose turns the next 6 steps (12 route points) into fed ground…
const FEED_SECONDS := 8.0  # …for this long…
const FEED_STACKS := 1  # …other families' status hits on nightmares there add this many more
const FEED_MAX_STRETCHES := 40  # (at most this many stretches of fed ground at once; the oldest go first)
const EVO_HOST_TREES := &"sp_host_trees"  # Host Trees (final pass 2026-10-24): the Warden Shared Caps picks at each mushroom wears a cap…
const HOST_TREES_POTENCY := 1.15  # …its effect damage this much (or its direct hits on Poisoned, if its status deals none)…
const HOST_LINGER := 8.0  # …and its cap stays this long after it stops being picked
const EVO_WINDFALL := &"sp_windfall"  # Windfall: a dispel on fed ground leaves a (pale) mushroom, Poisoned or not
const EVO_HOST_GROVE := &"sp_host_grove"
const HOST_GROVE_AT := 3  # Host Grove: while this many Wardens of other families wear caps…
const HOST_GROVE_POTENCY := 1.30  # …Host Trees' part is this instead of 1.15 (DreamState.calling_potency; every Reactions.EFFECT_TAGS tag)
const HOST_CREDIT_META := &"sp_host_credit"  # On a Warden: when Host Grove may be credited again (once a second)
const EVO_SPOREFALL := &"sp_sporefall"
const SPOREFALL_POINTS := 6  # Sporefall: a status another family's Warden fills on fed ground plants a mushroom 3 steps ahead…
const SPOREFALL_META := &"sp_sporefall"  # …once per status per nightmare (on a nightmare: {status: true})
const EVO_SPREADING := &"sp_spreading_caps"  # Spreading Caps: another family's Warden within SPREAD_CELLS of a capped Warden wears a cap too (one link)
const SPREAD_CELLS := 2.0
# Retired 2026-10-23 (old saves only)
const EVO_WITCH_RING := &"sp_witch_ring"
const RING_STEPS := 3  # Witch Ring: this many mushrooms…
const RING_WINDOW := 4.0  # …within this long…
const RING_HOLD := 1.0  # …Held this long (bosses half)…
const RING_EVERY := 10.0  # …each nightmare once in this long
const RING_META := &"sp_ring"  # On a nightmare: [step times], and RING_NEXT_META: when it may be Held again
const RING_NEXT_META := &"sp_ring_next"
const EVO_STICKY := &"sp_sticky"
const STICKY_SLOW := 0.5  # Sticky Caps: half speed…
const STICKY_SECONDS := 1.0  # …this long for each mushroom in the clump…
const STICKY_MAX := 3.0  # …at most this long (bosses half)
const STICKY_META := &"sp_sticky"  # On a nightmare: {mushroom point: true}: once per clump
const EVO_MIRE := &"sp_mire_mouth"
const MIRE_OTHERS := 2  # Mire-Mouth: the nightmares behind it…
const MIRE_CELLS := 2.0  # …within this many cells…
const MIRE_SHARE := 0.5  # …stuck this share as long (never bosses)
const EVO_ROT := &"sp_rot"
const ROT_STACKS := 2  # Rot: per mushroom in the clump, to every other status
const EVO_ROTBURST := &"sp_rotburst"
const BURST_CELLS := 1.5  # Rotburst: a clump's last mushroom bursts over this many cells…
const BURST_MAX := 6  # …on up to this many nightmares…
const BURST_STACKS := 2  # …each status the eater had, this many
# Catching / Outbreak: replaced by Stomping Ground / Second Crop (non-status builds, owner 2026-10-19); code kept for an old save
const EVO_CATCHING := &"sp_catching"
const CATCH_SHARE := 0.5  # Catching: half the dose…
const CATCH_WINDOW := 2.0  # …to the first nightmare it touches within this long
const CATCH_META := &"sp_catch"  # On a nightmare: [until, stacks, hops, WeakRef tower]
const EVO_OUTBREAK := &"sp_outbreak"
const OUTBREAK_HOPS := 3  # Outbreak: passed on again up to this many times, halving
const EVO_STOMPING := &"sp_stomping"  # Stomping Ground (non-status builds, council nonstatus_*.md 2026-10-19)
const STOMP_WARDENS := 3  # A step on a mushroom: a free hit from each attacking Warden touching that step, the strongest first, at most this many
const STOMP_BOSS := 0.5  # Bosses take half
const EVO_SECOND_CROP := &"sp_second_crop"  # Second Crop: a dispel within 2 steps of a mushroom leaves one, Poison or not
const CROP_STEPS := 2
const CROP_ALPHA := 0.65  # Its cap is drawn pale (Second Crop's, Windfall's)
const EVO_MOTHER := &"sp_mother"
const MOTHER_STATUSES := 4  # Mother Spore: a dispel's mushroom remembers up to this many statuses…
const MOTHER_STACKS := 2  # …and its dose gives this many of each
const FIRST_HIT_META := &"sp_first_hit"  # On a nightmare: {spore Warden id: true}: it has hit it (Second Helping)
const FRUITING := &"fruiting"  # Lent (non-status builds, owner 2026-10-19): hits stack, the way statuses do
const FRUIT_PER_WARDEN := 0.06  # +6% for each other Warden that hit the nightmare in the last…
const FRUIT_WINDOW := 2.0  # …this long…
const FRUIT_MAX := 0.30  # …up to this
const FRUIT_META := &"sp_fruit"  # On a nightmare: {Warden id: last hit time}
const PARTING_PUFF := &"parting_puff"  # Lent ("Parting Puff": Puffball is a Warden): a dispel puffs a quarter of that hit onto nightmares within 1 cell
const PUFF_SHARE := 0.25
const PUFF_MAX := 4
const PUFF_BOSS := 0.5
const PUFF_TAG := &"parting_puff"  # In class_kit.CLASS_TAGS: a puff is never a hit, and a puff that dispels does not puff again

const DOSES_META := &"sp_doses"  # On a nightmare: doses it stepped on (It Grows on You)
const OPEN_META := &"sp_open"  # On a nightmare: until when each spore Warden's next attack is a dose
const OPEN_BY_META := &"sp_open_by"  # On a nightmare: {Warden id: next time}
const HELPING_META := &"sp_helping"  # On a nightmare: the dose serial a partner may answer
const HELPED_META := &"sp_helped"  # On a nightmare: {Warden id: dose serial}
const KINDS_META := &"sp_kinds"  # On a nightmare: {Warden form id: true} (Pass It Round)
const HOT_META := &"sp_hothouse"
const NIGHT_META := &"sp_overnight"  # On a nightmare: {Warden id: next time}

# Mushrooms: route point -> {tower: WeakRef (whose dose), caps: int, grown: bool (a card regrows it), age: int,
# last: int (the last nightmare dosed: Twin Caps doses two different ones), colour: WeakRef (Everything Grows)}
var mushrooms := {}
var _regrow := {}  # Route point -> seconds left (Kept Ground, Mushroom Bed, Side by Side), run only during a drift
var _bed := {}  # Route point -> regrow seconds (the steps Mushroom Bed / Side by Side grow on), rebuilt with the board
var _touch_one := {}  # Route point -> true: touching exactly one spore Warden (Kept Ground)
var _age := 0
var _dose_serial := 0
var _haze := {}  # Warden id -> true: Spore Haze is on (counted each second)
var _haze_in := 0.0
var saved: Array = []  # From the run save; applied once the route is known
var doses_given := 0  # This run (tests and the owner's eye)
# Calling evolutions (rebuilt 2026-10-23)
var _fairy := {}  # Route point -> true: a Fairy Path bed (the nearest step a Sprout touches), rebuilt with the board
var _fed: Array = []  # Feeding Ground's fed ground: [from index, to index, until], indices on the route (leg-aware via index_of)
var _capped := {}  # Host Trees: Warden instance id -> [WeakRef, until (INF while it touches a mushroom), passed (Spreading Caps)]
var _dirty := true  # Mushrooms grew or went: caps and thrones are worked out again at the next poll
var _host_frame := -1  # Host Grove: the frame _host_on was worked out in
var _host_on := false
var _attack_hooked := {}  # Warden instance id -> true: its attack_released is connected (Elder Cap, Retinue)

func _family() -> String:
	return FAMILY

func _line() -> String:
	return LINE

# Lent cards never give the Calling's setup (owner 2026-10-14, dream_council_review.md 25-26): mushrooms and doses are
# the first pick's only (place_on). The lent cards work from spore Wardens, where they stand and Poisoned.
func _lent_rules() -> Array:
	return [OVERNIGHT, PASS_IT_ROUND, MYCELIUM, SPORE_RING, SEEPING_IN, MIXED_COMPANY, BREATHE_IN, SITTING_DUCKS, HEMMED_IN, GONE_TO_SEED,
		FRUITING, PARTING_PUFF,
		NARROWS, SECOND_HELPING, HOTHOUSE]  # Narrows, Second Helping (2026-10-15), Hothouse: retired; an old save keeps them

# Retired lent cards that grew or read mushrooms: an old save holding one keeps the mushrooms on Continue.
func _legacy_rules() -> Array:
	return [LEAF_LITTER, SIDE_BY_SIDE, EVERYTHING_GROWS]

func _ready() -> void:
	super._ready()
	add_to_group(GROUP)
	sprouts_count = true  # Sporeling lines count Sprouts as Wardens (final_pass_shared.md 6)
	if dream_state != null and dream_state.get("drift_director") != null:
		dream_state.drift_director.drift_started.connect(_on_drift_started.unbind(1))

# Toadstool Throne reads drifts since planting: recount at each drift start too.
func _on_drift_started() -> void:
	_dirty = true

# The drift a Warden was planted on (Tower.planted_drift, Tower Code; a Warden without one counts from drift 1).
static func _planted_drift(tower) -> int:
	var drift = tower.get("planted_drift")
	return int(drift) if drift != null else 1

func _current_drift() -> int:
	return int(dream_state.drift_director.drifts_started) if dream_state != null and dream_state.get("drift_director") != null else 0

func _caps() -> int:
	return TWIN_CAPS if rule(TWIN) else 1

func _slower() -> float:
	return TWIN_SLOWER if rule(TWIN) else 0.0

# --- The board: which steps grow, which are kept --------------------------------------------------------------------

func on_board() -> void:
	_spots.clear()  # Where mushrooms are drawn follows the corridor (a plant or sale changes it)
	_bed.clear()
	_touch_one.clear()
	if not place_on():
		return
	if not saved.is_empty():
		_load_saved()
	var spores := own_towers()
	var others: Array = towers().filter(is_other_family)
	var old_fairy := _fairy
	_fairy = {}
	if evo(EVO_FAIRY_PATH) or evo(EVO_SPROUT_BEDS):  # Fairy Path (old saves): the nearest step touching each Sprout; Sprout Beds: the nearest within 2 cells (only while it stays a Sprout)
		for sprout in towers().filter(_is_sprout):
			var bed := _nearest_touched(sprout) if evo(EVO_FAIRY_PATH) else _nearest_within(sprout, BED_CELLS * cell())
			if bed >= 0:
				_fairy[_route[bed]] = true
	for i in _route.size():
		var at: Vector2 = _route_px[i]
		var count := 0
		for tower in spores:
			if touches_point(tower, at):
				count += 1
		if count == 1:
			_touch_one[_route[i]] = true
		var every := INF
		if count >= BED_WARDENS and rule(MUSHROOM_BED):
			every = BED_EVERY
		if count >= 1 and rule(SIDE_BY_SIDE) and others.any(func(t) -> bool: return touches_point(t, at)):
			every = minf(every, SIDE_EVERY)  # A step that qualifies for both grows one mushroom on the faster clock
		if _fairy.has(_route[i]):
			every = minf(every, FAIRY_EVERY)
		if every < INF:
			_bed[_route[i]] = every
	# A mushroom goes when its step leaves the route (a Warden planted on it re-routes the path)
	for point in mushrooms.keys():
		if not _index.has(point):
			mushrooms.erase(point)
	for point in _regrow.keys():
		if not _index.has(point) or (old_fairy.has(point) and not _bed.has(point)):
			_regrow.erase(point)  # (A Fairy Path bed whose Sprout was grown, sold or moved stops regrowing)
	_dirty = true  # Caps (Host Trees) and thrones follow the board
	if evo(EVO_ELDER) or evo(EVO_RETINUE):  # Their per-attack free hits
		_hook_attacks()
	# Bed steps with no mushroom and no clock start one (regrow clocks start empty: nothing for selling and replanting)
	for point in _bed:
		if not mushrooms.has(point) and not _regrow.has(point):
			_regrow[point] = float(_bed[point]) + _slower()
	for k in _route.size():  # Where each mushroom is drawn: once per board or route change
		_spots[_route[k]] = _work_out_spot(k)
	queue_redraw()

# Nothing grows by waiting (owner ruling, section 21): when a rest starts, every step that can grow a mushroom is
# filled at once; the clocks only run during a drift.
func on_rest() -> void:
	if not place_on():
		return
	for point in _regrow.keys():
		_grow(point, true)
	_regrow.clear()
	for point in _bed:
		if not mushrooms.has(point):
			_grow(point, true)
	queue_redraw()

func _owner_for(at: Vector2):
	var best = null
	var best_d := INF
	for tower in own_towers():
		var d: float = tower.global_position.distance_squared_to(at)
		if d < best_d:
			best_d = d
			best = tower
	return best

func _grow(point: Vector2, grown: bool, tower = null, gen: int = GEN_FELL) -> void:
	if not _index.has(point):
		return
	if tower == null:
		tower = _owner_for(_route_px[int(_index[point])])
	if tower == null:
		return  # With no spore Warden left it withers
	_age += 1
	mushrooms[point] = {"tower": weakref(tower), "caps": _caps(), "grown": grown, "age": _age, "last": 0, "seeded": false,
		"most": _caps(), "mother": [], "gen": gen}
	_dirty = true
	_evict()
	queue_redraw()

static func _is_sprout(tower) -> bool:
	return tower is Tower and tower.tower_data != null and tower.tower_data.get_id() == "sprout"

static func _is_final(tower) -> bool:
	return tower is Tower and tower.tower_data != null and tower.tower_data.can_attack and int(tower.tower_data.tier) >= FINAL_TIER

# The route index nearest `tower` among those it touches (-1: none).
func _nearest_touched(tower) -> int:
	var best := -1
	var best_d := INF
	for i in _route_px.size():
		var at: Vector2 = _route_px[i]
		if touches_point(tower, at):
			var d: float = tower.global_position.distance_squared_to(at)
			if d < best_d:
				best_d = d
				best = i
	return best

# The route index nearest `tower` within `reach` px (-1: none). Sprout Beds' bed step.
func _nearest_within(tower, reach: float) -> int:
	var best := -1
	var best_d := reach * reach
	for i in _route_px.size():
		var d: float = tower.global_position.distance_squared_to(_route_px[i])
		if d <= best_d:
			best_d = d
			best = i
	return best

# How many mushrooms grow (Spore Season). Windblown's seeded ones count since the builds doc (owner 2026-10-19): Spore
# Season is the capstone of Windblown's own line, so its seedlings fill the count.
func _rooted_count() -> int:
	return mushrooms.size()

func season_on() -> bool:
	return evo(EVO_SEASON) and _rooted_count() >= SEASON_AT

# Spore Season's count for the Calling's badge ("13/15"; UI reads it with SEASON_AT).
func season_count() -> int:
	return _rooted_count()

# The most mushrooms on the map: 40 (Drifting Spores' old 40-80 limit is gone, final pass 2026-10-24).
func mushroom_max() -> int:
	return MUSHROOM_MAX

func _evict() -> void:
	var most := mushroom_max()
	while mushrooms.size() > most:
		var oldest = null
		for point in mushrooms:
			if oldest == null or _goes_before(mushrooms[point], mushrooms[oldest]):
				oldest = point
		mushrooms.erase(oldest)
		_dirty = true

# Which of two mushrooms goes first when there are too many: a throne last; then the higher gen (planted ones before
# fallen ones: Windblown, Drifting Spores, Windfall, Sporefall); then one no card regrows; then the older.
func _goes_before(m: Dictionary, o: Dictionary) -> bool:
	var m_throne := bool(m.get("throne", false))
	if m_throne != bool(o.get("throne", false)):
		return not m_throne
	var m_gen := _gen_of(m)
	var o_gen := _gen_of(o)
	if m_gen != o_gen:
		return m_gen > o_gen
	if bool(m.grown) != bool(o.grown):
		return not bool(m.grown)
	return int(m.age) < int(o.age)

static func _gen_of(m: Dictionary) -> int:
	return int(m.get("gen", GEN_PLANTED if bool(m.get("seeded", false)) else GEN_FELL))

# Leaves a mushroom on the step nearest where a nightmare fell (none further than 1 cell from the route).
func leave_mushroom(at: Vector2, tower = null, statuses: Array = []) -> bool:
	var i := nearest_point(at, FALL_CELLS)
	if i < 0:
		return false
	if evo(EVO_CLUMP):  # Clump: it joins the nearest mushroom within 3 steps that has room
		var best := -1
		for k in range(maxi(i - CLUMP_STEPS * 2, 0), mini(i + CLUMP_STEPS * 2, _route.size() - 1) + 1):
			if mushrooms.has(_route[k]) and int(mushrooms[_route[k]].caps) < CLUMP_MAX and (best < 0 or absi(k - i) < absi(best - i)):
				best = k
		if best >= 0:
			var m: Dictionary = mushrooms[_route[best]]
			m.caps = int(m.caps) + 1
			m.most = maxi(int(m.get("most", 1)), int(m.caps))
			_remember(m, statuses)
			_dirty = true
			Reactions._effect(&"landing_dust", _route_px[best], self, 0.5)
			credit(EVO_CLUMP, _route_px[best])
			queue_redraw()
			return true
	if mushrooms.has(_route[i]):
		return false
	_grow(_route[i], false, tower if is_own(tower) else null)
	if mushrooms.has(_route[i]):
		_remember(mushrooms[_route[i]], statuses)
	return mushrooms.has(_route[i])

# Mother Spore: the mushroom keeps up to 4 of the fallen nightmare's statuses ([id, potency, line]), never Drowsy or Rooted.
func _remember(m: Dictionary, statuses: Array) -> void:
	if not evo(EVO_MOTHER) or statuses.is_empty():
		return
	var kept: Array = m.get("mother", [])
	for row in statuses:
		if kept.size() >= MOTHER_STATUSES:
			break
		if not kept.any(func(k) -> bool: return k[0] == row[0]):
			kept.append(row)
	m["mother"] = kept

# --- Damage events --------------------------------------------------------------------------------------------------

func on_damage(event, source, enemy, is_hit: bool, dispel: bool, _tagged: bool) -> void:
	if active():
		if evo(EVO_HOST_TREES) and (is_hit or Reactions.is_effect(event.tag)):
			_host_fleck(source, enemy)
		if dispel:
			if place_on():
				_fell(enemy)
			if is_hit and rule(PARTING_PUFF):
				_puff(event, source, enemy)
		elif is_hit:
			if rule(FRUITING):
				_note_hitter(source, enemy)
			if evo(EVO_PILE_ON) and not _in_calling_event:
				_pile_on(source, enemy)  # A Warden's own direct hit only: a free hit never calls another (its tag)
			if rule(MYCELIUM) and source.tower_data.get_id() == "sprout":
				_mycelium(source, enemy)
			if rule(OVERNIGHT) and is_own(source):
				_overnight(source, enemy)
			if rule(SECOND_HELPING) and is_own(source):
				_first_spore_hit(source, enemy)
			if rule(SEEPING_IN) and is_own(source) and not _in_calling_event:
				_seep_start(enemy)  # F7: a spore Warden's plain hit starts (or refreshes) the 12-step window
			if rule(SPORE_HAZE) and _haze.has(source.get_instance_id()):
				_haze_hit(event, source, enemy)

# Second Helping: a spore Warden's first hit on a nightmare (once for each spore Warden and nightmare).
func _first_spore_hit(spore, enemy) -> void:
	var hit: Dictionary = enemy.get_meta(FIRST_HIT_META, {})
	if not hit.has(spore.get_instance_id()):
		hit[spore.get_instance_id()] = true
		enemy.set_meta(FIRST_HIT_META, hit)

func _fell(enemy) -> void:
	if enemy.is_flying() and nearest_point(enemy.global_position, FALL_CELLS) < 0:
		return
	var poisoned: bool = enemy.statuses.has(EnemyStatuses.SPORED)
	var at: Vector2 = enemy.global_position
	if poisoned and class_on():  # The Calling: the first pick only
		var kept: Array = []
		if evo(EVO_MOTHER):
			for id in enemy.statuses.active_ids():
				if id != EnemyStatuses.SPORED and id != EnemyStatuses.HELD and id != EnemyStatuses.DROWSY and id != DreamState.FROST:
					kept.append([String(id), enemy.statuses.potency(id), String(enemy.statuses._active[id].get("line", ""))])
		leave_mushroom(at, enemy.statuses.source(EnemyStatuses.SPORED), kept)  # Mycelium Sprouts' Poisoned counts too
	elif class_on() and evo(EVO_WINDFALL) and _fed_at(index_of(enemy)):
		_windfall(at)  # Windfall: a dispel on fed ground leaves a pale mushroom, Poisoned or not
	elif class_on() and evo(EVO_SECOND_CROP) and _crop_near(at):
		if leave_mushroom(at):  # Second Crop: a dispel beside a mushroom leaves one, Poisoned or not
			var i := nearest_point(at, FALL_CELLS)
			if i >= 0 and mushrooms.has(_route[i]):
				mushrooms[_route[i]]["crop"] = true
			credit(EVO_SECOND_CROP, at)
	elif rule(LEAF_LITTER) and strongest_near(at, is_own) != null:
		leave_mushroom(at)  # Leaf Litter: dispelled near a spore Warden, Poisoned or not

# Mycelium (trait rework): a Sprout touching a spore Warden: its hit adds 1 to every status the nightmare already has besides
# the Poisoned it puffs (Tower._catalogue_hit), quietly. At most 3 Sprouts on one nightmare a second.
func _mycelium(sprout, enemy) -> void:
	if not living(enemy) or not own_towers().any(func(t) -> bool: return touching(t, sprout)):
		return
	var count: Array = enemy.get_meta(MYCELIUM_META, [-INF, 0])
	if now() - float(count[0]) >= 1.0:
		count = [now(), 0]
	if int(count[1]) >= MYCELIUM_SPROUTS:
		return
	count[1] = int(count[1]) + 1
	enemy.set_meta(MYCELIUM_META, count)
	for id in enemy.statuses.active_ids():
		if _stackable(id) and id != EnemyStatuses.SPORED:
			setup_quiet(enemy, MYCELIUM, id, _feed(enemy, id, 1))  # (setup credit 2026-10-16: the ledger)

# Overnight (trait rework; was +3 Poisoned): a spore Warden's hit adds 2 to each status other families put on the nightmare,
# quietly. Once a second for each spore Warden and nightmare.
func _overnight(spore, enemy) -> void:
	if not living(enemy):
		return
	var next: Dictionary = enemy.get_meta(NIGHT_META, {})
	if now() < float(next.get(-1, -INF)):
		return  # Once a second for each nightmare, however many spore Wardens hit it (council 2026-10-15)
	var fed := false
	for id in enemy.statuses.active_ids():
		if _stackable(id) and is_other_family(enemy.statuses.source(id)):
			var added := _feed(enemy, id, OVERNIGHT_FEED)
			setup_quiet(enemy, OVERNIGHT, id, added)  # (setup credit 2026-10-16)
			fed = added > 0 or fed
	if fed:
		next[-1] = now() + OVERNIGHT_EVERY
		enemy.set_meta(NIGHT_META, next)

# Whether the stack cards may add to `id` (never Rooted; Drowsy only with STACK_DROWSY, within its normal cap).
# Whether a held row reads a place on the path (Feeding Ground's fed steps, Fairy Path's / Sprout Beds' spots): only then
# does a hovered or selected Sporeling-family Warden keep its path highlight (TowerPlacer.draw_placement; owner
# 2026-10-25: Spore Print's effect is its mushrooms, which already show).
func reads_path_places() -> bool:
	return place_on() and (evo(EVO_FEEDING) or evo(EVO_FAIRY_PATH) or evo(EVO_SPROUT_BEDS))

func _stackable(id: StringName) -> bool:
	return id != EnemyStatuses.HELD and id != DreamState.FROST and (STACK_DROWSY or id != EnemyStatuses.DROWSY)  # Frost only from Frost Wardens (section 37)

# Adds `stacks` to `id` quietly (no clock, strength or source change). Charged stops one short of a bolt.
func _feed(enemy, id: StringName, stacks: int) -> int:
	if id == EnemyStatuses.STATIC:
		stacks = mini(stacks, enemy.statuses.get_max_stacks(id) - 1 - enemy.statuses.stacks(id))
	return enemy.statuses.add_quiet(id, stacks) if stacks > 0 else 0

# Gone to Seed (DreamState.class_status: a Warden's own accepted application): a status filled on a nightmare near a
# spore Warden: every other status on it gains 5, quietly (so it never sets off another fill). Once per nightmare in 2 s.
func status_applied(tower, enemy, status: StringName, stacks: int) -> void:
	if evo(EVO_SPOREFALL) and living(enemy) and status != EnemyStatuses.HELD:
		_sporefall(tower, enemy, status)
	if not rule(GONE_TO_SEED) or not living(enemy) or status == EnemyStatuses.HELD:
		return
	var statuses: EnemyStatuses = enemy.statuses
	var most: int = statuses.get_max_stacks(status)
	var before: Array = enemy.get_meta(SEED_BEFORE_META, [&"", 0])
	var was: int = int(before[1]) if StringName(before[0]) == status else 0
	if statuses.stacks(status) < most or was >= most or now() < float(enemy.get_meta(SEED_META, -INF)):
		return  # Only the hit that fills it: one landing on a status already full never counts
	if strongest_near(enemy.global_position, is_own) == null:
		return
	var fed := false
	for id in statuses.active_ids():
		if id != status and _stackable(id):
			var added := _feed(enemy, id, SEED_STACKS)
			setup_quiet(enemy, GONE_TO_SEED, id, added)  # (setup credit 2026-10-16)
			fed = added > 0 or fed
	if fed:
		enemy.set_meta(SEED_META, now() + SEED_EVERY)
		Reactions._effect(&"landing_dust", enemy.global_position, self, 0.8)

# Gone to Seed and Reactions (F9, owner 2026-10-18; lent_evolution_builds.md P9: Ignite, Mushrooming and Thunderclap spend
# statuses before they fill): a Reaction set off this frame by a Warden's stamped application, on a nightmare near a spore
# Warden, gives each status left on it SEED_STACKS, quietly. The same once-in-2-s clock as the fill. ready_need unchanged.
var _seed_tracker: Object = null

func _hook_seed_tracker() -> void:
	if is_instance_valid(_seed_tracker) or not is_inside_tree():
		return
	var tracker := get_tree().get_first_node_in_group(ReactionTracker.GROUP)
	if tracker != null:
		_seed_tracker = tracker
		tracker.reaction_fired.connect(_seed_reaction)

func _seed_reaction(_id: StringName, enemy: Node2D, _chain: int, _towers: Array) -> void:
	if dream_state == null or not rule(GONE_TO_SEED) or not living(enemy):
		return
	var before: Array = enemy.get_meta(SEED_BEFORE_META, [])
	if before.size() < 3 or int(before[2]) != Engine.get_process_frames() or now() < float(enemy.get_meta(SEED_META, -INF)):
		return
	if strongest_near(enemy.global_position, is_own) == null:
		return
	enemy.set_meta(SEED_META, now() + SEED_EVERY)  # Claimed now: a chain in this frame pays once
	_seed_after_reaction.call_deferred(weakref(enemy))  # The statuses LEFT once the Reaction has spent its own

func _seed_after_reaction(ref: WeakRef) -> void:
	var enemy = ref.get_ref()
	if not living(enemy):
		return
	var fed := false
	for id in enemy.statuses.active_ids():
		if _stackable(id):
			var added := _feed(enemy, id, SEED_STACKS)
			setup_quiet(enemy, GONE_TO_SEED, id, added)
			fed = added > 0 or fed
	if fed:
		Reactions._effect(&"landing_dust", enemy.global_position, self, 0.8)

# (Unused since 2026-10-15: Pass It Round adds stacks in _stack_cards.) Pass It Round: each different kind of attacking Warden touching a spore Warden gives a dose with its first hit on
# each nightmare (one per kind per nightmare; spore forms and walls don't count; needs no mushroom, so flyers too).
func _pass_it_round(source, enemy) -> void:
	if not is_other(source) or not living(enemy):
		return
	var kinds: Dictionary = enemy.get_meta(KINDS_META, {})
	var kind: String = source.tower_data.get_id()
	if kinds.has(kind):
		return
	var spore = null
	for tower in own_towers():
		if touching(tower, source):
			spore = tower
			break
	if spore == null:
		return
	kinds[kind] = true
	enemy.set_meta(KINDS_META, kinds)
	_line_fx(body(spore), body(source), 2.0, Palette.MOSS)
	_apply_dose(spore, enemy, DOSE)  # 3 Poisoned at once from the spore Warden (not a mushroom's dose: no place needed)

# Spore Haze: a single-target spore Warden with 4 mushrooms near it attacks in clouds: stacks and puff damage also
# land on up to 4 nightmares touching its target.
func _haze_hit(event, source, enemy) -> void:
	for other in nightmares_touching(enemy, HAZE_OTHERS):
		strike(source, other, event.base, &"spore_haze", true)
		if living(other):
			setup_apply(SPORE_HAZE, source, other, EnemyStatuses.SPORED, maxi(int(source.attack_data.status_stacks), 1), source.get_damage())

# --- Doses ----------------------------------------------------------------------------------------------------------

# One dose: an ordinary Poisoned application from `tower` (one batch, the normal clock, the normal limit).
# `credit_id` (setup credit 2026-10-16): the card or evolution the whole dose belongs to in the ledger (&"" = the Calling's).
func _apply_dose(tower, enemy, amount: int, credit_id: StringName = &"") -> void:
	if not is_instance_valid(tower) or not living(enemy):
		return
	doses_given += 1
	var statuses: EnemyStatuses = enemy.statuses
	var cap: int = statuses.get_max_stacks(EnemyStatuses.SPORED) if statuses.has(EnemyStatuses.SPORED) else 0
	if credit_id != &"":
		SETUP.begin(StringName(card_id(credit_id)))
	var calling := credit_id != KICKED_UP  # F1 (f1_spec.md): a dose is one Poisoned application by its Warden for other families' lent cards
	if calling:
		_arm_apply()
	tower._apply_one_status(enemy, EnemyStatuses.SPORED, amount, tower.get_damage(), false)
	if calling:
		_disarm_apply()
	if credit_id != &"":
		SETUP.end()
	if cap > 0 and living(enemy):
		statuses.keep_spore_cap(cap)  # A dose never raises the limit: a full nightmare stays full

func _stepped(point: Vector2, enemy) -> void:
	var m: Dictionary = mushrooms[point]
	if int(m.last) == enemy.get_instance_id():
		return  # Twin Caps: two different nightmares
	if (m.get(HEAVY_SEEN, {}) as Dictionary).has(enemy.get_instance_id()):
		return  # Heavy Air: a mushroom it left doses each nightmare once (laps, Waymark legs, bends)
	var tower = m.tower.get_ref()
	if (not is_own(tower) or not is_instance_valid(tower)) and bool(m.get("throne", false)):
		tower = _owner_for(_route_px[int(_index[point])])  # A throne's dose comes from the nearest spore Warden
		if tower != null:
			m.tower = weakref(tower)
	if not is_own(tower) or not is_instance_valid(tower):
		mushrooms.erase(point)  # Its Warden is gone: it withers (council, lent_td.md: no inheriting a sold bed)
		_dirty = true
		queue_redraw()
		return
	if evo(EVO_DEATHCAP):
		_deathcap(tower, enemy)  # Before the dose: 2 s of the Poisoned it already carries
		if not living(enemy):
			return
	var amount := DOSE
	var grows := rule(IT_GROWS) or evo(EVO_WINDBLOWN)  # Windblown (2026-10-23) took It Grows on You's growth
	if grows:  # Each dose a nightmare steps on is 1 bigger than its last, up to 6
		var taken := int(enemy.get_meta(DOSES_META, 0))
		amount = mini(DOSE + taken, GROWS_MAX)
		enemy.set_meta(DOSES_META, taken + 1)
		_setup_part(enemy, EVO_WINDBLOWN if evo(EVO_WINDBLOWN) else IT_GROWS, EnemyStatuses.SPORED, amount - DOSE)  # (setup credit 2026-10-16: each part's stacks)
	var caps_here := int(m.caps)
	var placed := _placed_by(point, m)  # A planted seedling or Fairy Path's regrowth: the dose's base is its (owner 2026-10-19)
	if placed != &"":
		_setup_part(enemy, placed, EnemyStatuses.SPORED, DOSE)
	var heavy := evo(EVO_HEAVY_AIR) and _at_haze_cap(enemy)  # Before the dose: Season's +60% reached
	_apply_dose(tower, enemy, amount)
	_dose_serial += 1
	if _walk_on():
		_season_start(enemy)
	if evo(EVO_DEATHCAP_FIELD):
		_field_burst(tower, enemy)  # After the dose (the built sp_deathcap above stays before it, for old saves)
	_evolved_step(point, m, tower, enemy, amount, caps_here, not heavy)
	if rule(KICKED_UP):  # Up to 4 touching it take a fresh dose of 3; a received dose counts for nothing else
		for other in nightmares_touching(enemy, KICKED_OTHERS):
			_apply_dose(tower, other, DOSE, KICKED_UP)
	if rule(OPEN_SEASON):
		enemy.set_meta(OPEN_META, now() + OPEN_SEASON_WINDOW)
	if rule(EVERYTHING_GROWS):  # The nearest other-family Warden touching the mushroom adds 3 of its own status
		var at: Vector2 = _route_px[int(_index[point])]
		var partner = null
		var best := INF
		for other in towers():
			if is_other_family(other) and status_of(other) != &"" and touches_point(other, at) \
					and other.global_position.distance_squared_to(at) < best:
				best = other.global_position.distance_squared_to(at)
				partner = other
		if partner != null and living(enemy):
			setup_apply(EVERYTHING_GROWS, partner, enemy, status_of(partner), EVERYTHING_STACKS, partner.get_damage())
	m.last = enemy.get_instance_id()
	if heavy:  # Heavy Air: the dose landed, the mushroom stays (and planted no seedling); each nightmare once here
		var seen: Dictionary = m.get(HEAVY_SEEN, {})
		seen[enemy.get_instance_id()] = true
		m[HEAVY_SEEN] = seen
		m[HEAVY_GLOW] = now() + 0.5
		credit(EVO_HEAVY_AIR, enemy.global_position, tower)
		queue_redraw()
		return
	if bool(m.get("throne", false)) and int(m.caps) <= 1:
		queue_redraw()
		return  # Toadstool Throne: its last mushroom is never eaten
	# The eaten cap pops (Tower Assets eaed6c74) where it stood and under the nightmare's feet (owner 2026-10-22: "it
	# teleports on the enemy"): its anchor (the stem's foot) on the mushroom's own foot (it was 8 px up, so the cap
	# jumped and its stub floated over the path), and in the mushrooms' y-sort (_layer), not over everything (a world Fx
	# is at Fx.Z, over the nightmares, so the cap seemed to land on the one stepping on it).
	# The dose lands now; the cap stays drawn and its pop waits until the nightmare's feet reach it (HeldCap; owner
	# 2026-10-23: "the mushrooms teleport to the enemy when hit": the step counts from the route point, the cap is drawn on
	# the path's middle line up to half a cell away)
	_hold_pop(point, m, enemy)
	m.caps = int(m.caps) - 1
	if int(m.caps) > 0:
		queue_redraw()
		return
	if evo(EVO_ROTBURST) and int(m.get("most", 1)) >= 2 and living(enemy):
		_rotburst(point, tower, enemy)
	mushrooms.erase(point)
	_dirty = true
	# Grows back: a bed step on its clock; Kept Ground where only one spore Warden touches the step
	if _bed.has(point):
		_regrow[point] = float(_bed[point]) + _slower()
	elif rule(KEPT_GROUND) and _touch_one.has(point):
		_regrow[point] = KEPT_EVERY + _slower()
	queue_redraw()

# The evolution that put this mushroom here (&"": the Calling's own): Windblown's seedling, or one Fairy Path's clock grew
# (a bed step on FAIRY_EVERY). Damage credit (owner 2026-10-19): the dose's base stacks are that evolution's.
func _placed_by(point: Vector2, m: Dictionary) -> StringName:
	if bool(m.get("seeded", false)):
		if bool(m.get("sporefall", false)) and evo(EVO_SPOREFALL):
			return EVO_SPOREFALL
		if evo(EVO_WINDBLOWN):
			return EVO_WINDBLOWN
	if bool(m.get("crop", false)) and evo(EVO_WINDFALL):
		return EVO_WINDFALL
	if bool(m.get("grown", false)) and _fairy.has(point):
		if evo(EVO_SPROUT_BEDS):
			return EVO_SPROUT_BEDS
		if evo(EVO_FAIRY_PATH):
			return EVO_FAIRY_PATH
	return &""

# Everything an evolution adds to a step on a mushroom (after its dose). `caps_here`: the mushrooms in it before one is eaten.
# `plant` false: Heavy Air's uneaten dose plants no Windblown seedling.
func _evolved_step(point: Vector2, m: Dictionary, tower, enemy, amount: int, caps_here: int, plant: bool = true) -> void:
	if not class_on() or dream_state.calling_path.is_empty() or not living(enemy):
		return
	var at: Vector2 = _route_px[int(_index[point])]
	if evo(EVO_CLUMP):
		_clump_hits(point, enemy)  # Clump (2026-10-23; its old dose for each cap is gone): free hits from the Wardens around it
	if evo(EVO_BORROWED):
		_shared_caps(at, tower, enemy)  # Shared Caps (2026-10-23; Borrowed Spores' copied status is gone)
	if evo(EVO_FEEDING):
		_feed_ground(enemy, point)  # Feeding Ground (2026-10-23; its old 4 s per-nightmare window is gone)
	if evo(EVO_ROT) and caps_here >= 2:
		var rotted := 0
		for id in enemy.statuses.active_ids():
			if id != EnemyStatuses.SPORED and _stackable(id):
				var added := _feed(enemy, id, ROT_STACKS * caps_here)
				setup_quiet(enemy, EVO_ROT, id, added)  # (setup credit 2026-10-16)
				rotted += added
		if rotted > 0:
			Reactions._effect(&"landing_dust", enemy.global_position, self, 0.6)
			credit(EVO_ROT, enemy.global_position, tower)
	if evo(EVO_STICKY) and caps_here >= 1:
		var stuck: Dictionary = enemy.get_meta(STICKY_META, {})
		if not stuck.has(point):
			stuck[point] = true
			enemy.set_meta(STICKY_META, stuck)
			var seconds := minf(STICKY_SECONDS * caps_here, STICKY_MAX) * (0.5 if enemy.statuses.is_boss else 1.0)
			HelperCommons.slow(enemy, STICKY_SLOW, seconds)
			control_slow(EVO_STICKY, STICKY_SLOW, seconds)  # (setup credit 2026-10-16)
			credit(EVO_STICKY, enemy.global_position, tower)
			if evo(EVO_MIRE):
				_mire(enemy, seconds * MIRE_SHARE)
	if evo(EVO_WITCH_RING):
		_witch_ring(tower, enemy)
	if evo(EVO_CATCHING):
		enemy.set_meta(CATCH_META, [now() + CATCH_WINDOW, maxi(int(amount * CATCH_SHARE), 1), 0, weakref(tower)])
	if evo(EVO_STOMPING):
		_stomp(at, enemy)
	if evo(EVO_MOTHER) and not (m.get("mother", []) as Array).is_empty():
		for row in m.mother:
			var id := StringName(row[0])
			if enemy.statuses.has(id):
				setup_quiet(enemy, EVO_MOTHER, id, _feed(enemy, id, MOTHER_STACKS))  # (setup credit 2026-10-16)
			elif id != EnemyStatuses.STATIC or MOTHER_STACKS < enemy.statuses.get_max_stacks(id):
				SETUP.apply(enemy, card_id(EVO_MOTHER), id, MOTHER_STACKS, 0.0, float(row[1]), 0, String(row[2]), null)
		Reactions._effect(&"landing_dust", enemy.global_position, self, 0.7)
		credit(EVO_MOTHER, enemy.global_position, tower)
	# Windblown: a fallen (or regrown) mushroom's dose plants one 3 steps on (Drifting Spores' second plant is gone, final pass)
	var gen := _gen_of(m)
	if plant and evo(EVO_WINDBLOWN) and gen == GEN_FELL:
		var from := index_of(enemy)  # Along the walker's own leg (Waymark)
		if from < 0:
			from = int(_index[point])
		var i := from + SEED_STEPS * 2
		if _plant(i, tower, gen + 1, enemy):
			_line_fx(at, _route_px[i], 1.5, Palette.MOSS)
			credit(EVO_WINDBLOWN, _route_px[i], tower)

# A planted mushroom at route index `i` (Windblown, Drifting Spores, Sporefall): a seedling of `gen`, never for `walker`
# (the nightmare that planted it). False when the step is taken or off the route.
func _plant(i: int, tower, gen: int, walker = null) -> bool:
	if i < 0 or i >= _route.size() or mushrooms.has(_route[i]):
		return false
	_grow(_route[i], false, tower, gen)
	if not mushrooms.has(_route[i]):
		return false
	mushrooms[_route[i]].seeded = true
	if walker != null and is_instance_valid(walker):
		mushrooms[_route[i]].last = walker.get_instance_id()  # For the next nightmare, never the one that planted it
	return true

# Witch Ring: 3 mushrooms within 4 s Hold the nightmare 1 s (bosses half), each nightmare once in 10 s.
func _witch_ring(tower, enemy) -> void:
	var times: Array = enemy.get_meta(RING_META, [])
	times.append(now())
	times = times.filter(func(t) -> bool: return now() - float(t) <= RING_WINDOW)
	enemy.set_meta(RING_META, times)
	if times.size() < RING_STEPS or now() < float(enemy.get_meta(RING_NEXT_META, -INF)) or not is_instance_valid(tower):
		return
	enemy.set_meta(RING_NEXT_META, now() + RING_EVERY)
	enemy.set_meta(RING_META, [])
	tower.hold(enemy, RING_HOLD * (0.5 if enemy.statuses.is_boss else 1.0))
	if living(enemy) and enemy.statuses.is_held():
		control(EVO_WITCH_RING, RING_HOLD * (0.5 if enemy.statuses.is_boss else 1.0))  # (setup credit 2026-10-16)
	Reactions._effect(&"landing_dust", enemy.global_position, self, 1.2)
	credit(EVO_WITCH_RING, enemy.global_position, tower)

# Mire-Mouth: the 2 nightmares behind a stuck one (further back on the route, within 2 cells) are stuck too. Never bosses.
func _mire(enemy, seconds: float) -> void:
	var mine := index_of(enemy)
	var behind: Array = []
	for other in Tower.nightmares_near(get_tree(), enemy.global_position, MIRE_CELLS * cell()):
		if other != enemy and living(other) and not other.statuses.is_boss and not other.is_flying() and index_of(other) <= mine:
			behind.append(other)
	behind.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(enemy.global_position) < b.global_position.distance_squared_to(enemy.global_position))
	for other in behind.slice(0, MIRE_OTHERS):
		HelperCommons.slow(other, STICKY_SLOW, seconds)
		control_slow(EVO_MIRE, STICKY_SLOW, seconds)  # (setup credit 2026-10-16)
		_line_fx(body(enemy), body(other), 2.0, Palette.MOSS)
	if not behind.is_empty():
		credit(EVO_MIRE, enemy.global_position)

# Rotburst: a clump's last mushroom bursts on up to 6 nightmares within 1.5 cells: a dose, and 2 of each status the eater had.
func _rotburst(point: Vector2, tower, eater) -> void:
	var at: Vector2 = _route_px[int(_index[point])]
	var carried: Array = []
	for id in eater.statuses.active_ids():
		if id != EnemyStatuses.SPORED and id != EnemyStatuses.HELD and id != EnemyStatuses.DROWSY and id != DreamState.FROST:
			carried.append([id, eater.statuses.source(id)])
	var hit := 0
	for other in Tower.nightmares_near(get_tree(), at, BURST_CELLS * cell()):
		if hit >= BURST_MAX:
			break
		if other == eater or not living(other) or other.global_position.distance_to(at) > BURST_CELLS * cell():
			continue
		hit += 1
		_apply_dose(tower, other, DOSE, EVO_ROTBURST)
		for row in carried:
			if not living(other):
				break
			if other.statuses.has(row[0]):
				setup_quiet(other, EVO_ROTBURST, row[0], _feed(other, row[0], BURST_STACKS))  # (setup credit 2026-10-16)
			elif row[1] is Tower and is_instance_valid(row[1]):
				calling_apply(EVO_ROTBURST, row[1], other, row[0], BURST_STACKS, row[1].get_damage())
	Reactions._effect(&"landing_dust", at, self, 1.6)
	credit(EVO_ROTBURST, at, tower)

# --- Calling evolutions, rebuilt 2026-10-23 -----------------------------------------------------------------------------

# 1 s of `enemy`'s own Poisoned damage, raw (its stacks x the applier's strength; Potency, Seeping and Nightshade are
# applied once in take_damage, on the deathcap / haze effect tags).
static func _poison_second(enemy) -> float:
	if not enemy.statuses.has(EnemyStatuses.SPORED):
		return 0.0
	return float(enemy.statuses.stacks(EnemyStatuses.SPORED)) * float(enemy.statuses.potency(EnemyStatuses.SPORED))

# Deathcap (Spread capstone): a Poisoned nightmare stepping on a mushroom (or, with Rot Ground, on a Sprout bed while its
# cap regrows) takes 2 s of its Poisoned damage at once. Each nightmare once a second; bosses half. Damage only (R1).
func _deathcap(tower, enemy, own: StringName = EVO_DEATHCAP) -> void:
	if not living(enemy) or not is_instance_valid(tower) or now() < float(enemy.get_meta(DEATHCAP_META, -INF)):
		return
	var amount := _poison_second(enemy) * DEATHCAP_SECONDS
	if amount <= 0.0:
		return
	enemy.set_meta(DEATHCAP_META, now() + DEATHCAP_EVERY)
	var at: Vector2 = enemy.global_position
	if calling_hit(tower, enemy, amount, DEATHCAP_TAG, own, false, false, &"", DEATHCAP_BOSS) > 0.0:
		Reactions._effect(&"landing_dust", at, self, 1.0)  # The dark burst under its foot

# Rot Ground (Deathcap's Deepen): a walker on a Sprout bed's step whose mushroom is regrowing: Deathcap's burst, no dose.
func _rot_step(point: Vector2, enemy) -> void:
	if not _bed.has(point) or not living(enemy):
		return
	var tower = _owner_for(_route_px[int(_index[point])])
	if tower != null:
		_deathcap(tower, enemy, EVO_ROT_GROUND)

# Drifting Spores / Spore Season / Thick Haze (final pass 2026-10-24): the walk is counted forward on the nightmare's own
# leg from the first route point it is seen on (the poll), with its first dose's index; Drifting counts from that dose,
# Spore Season (15+ mushrooms) from the first point. Never flyers. Laps and a Waymark leg change start it again.
func _walk_on() -> bool:
	return evo(EVO_DRIFTING) or evo(EVO_SEASON) or evo(EVO_THICK_HAZE)

func _season_start(enemy) -> void:  # Its first dose
	if not enemy.on_route():  # Route flyers count at the route point below them (Phantoms never)
		return
	var i := index_of(enemy)
	if i < 0:
		return
	if not enemy.has_meta(SEASON_META):
		enemy.set_meta(SEASON_META, [i, i, bool(enemy.get("passed_waymark")), 0, i])
		return
	var walk: Array = enemy.get_meta(SEASON_META)
	if walk.size() < 5:
		walk.append(i)
	elif int(walk[4]) < 0:
		walk[4] = i
	enemy.set_meta(SEASON_META, walk)

func _season_walk(enemy) -> void:
	if not enemy.on_route():
		return
	var i := index_of(enemy)
	if i < 0:
		return
	if not enemy.has_meta(SEASON_META):
		enemy.set_meta(SEASON_META, [i, i, bool(enemy.get("passed_waymark")), 0, -1])
		return
	var walk: Array = enemy.get_meta(SEASON_META)
	if i + SEASON_LAP_POINTS < int(walk[1]) or (bool(walk[2]) and not bool(enemy.get("passed_waymark"))):
		enemy.set_meta(SEASON_META, [i, i, bool(enemy.get("passed_waymark")), 0, -1])  # It started its route again: it counts again
		return
	if i > int(walk[1]):
		walk[1] = i
	walk[2] = bool(enemy.get("passed_waymark"))
	enemy.set_meta(SEASON_META, walk)
	if evo(EVO_THICK_HAZE):
		_thick_haze(enemy, walk)

# Steps the active count has (Spore Season on: since the first point seen; else Drifting: since the first dose; 0 without).
func season_steps(enemy) -> float:
	if not is_instance_valid(enemy) or not enemy.has_meta(SEASON_META):
		return 0.0
	var walk: Array = enemy.get_meta(SEASON_META)
	var start := int(walk[0])
	if not season_on():
		start = int(walk[4]) if walk.size() > 4 else int(walk[0])
		if start < 0:
			return 0.0
	return maxf(float(int(walk[1]) - start) * 0.5, 0.0)

func _season_cap(enemy) -> float:
	if season_on():
		return SEASON_BOSS_MAX if enemy.statuses.is_boss else SEASON_MAX
	return DRIFT_BOSS_MAX if enemy.statuses.is_boss else DRIFT_MAX

# The walk bonus on this nightmare's Poisoned (0.25 = +25%): Drifting Spores' up to +30%, or Spore Season's up to +60%
# while 15+ mushrooms grow. The status-dot row's "+N%" tag reads it.
func season_bonus(enemy) -> float:
	if not (evo(EVO_DRIFTING) or season_on()) or not is_instance_valid(enemy) or not enemy.on_route():
		return 0.0
	return minf(season_steps(enemy) * (SEASON_PER_STEP if season_on() else DRIFT_PER_STEP), _season_cap(enemy))

# Heavy Air's gate: Spore Season on and this nightmare at its +60% (bosses +30%).
func _at_haze_cap(enemy) -> bool:
	return season_on() and is_instance_valid(enemy) and season_bonus(enemy) >= _season_cap(enemy) - 0.0001

# Deathcap (Spread follow-up, final pass): each of the first 3 mushrooms a nightmare steps on bursts, after the dose: 2 s
# of its Poisoned at once (Rot Bloom: the 3rd is 6 s, tag rot_bloom). Bosses half. Counted only when it dealt damage; laps
# and the Waymark start the count again (_burst_walk). Unscaled, damage only (R1); at most 3 a walk, no throttle.
func _field_burst(tower, enemy) -> void:
	if not living(enemy) or not is_instance_valid(tower):
		return
	var row: Array = enemy.get_meta(BURSTS_META, [0, index_of(enemy), bool(enemy.get("passed_waymark"))])
	if int(row[0]) >= FIELD_BURSTS:
		return
	var bloom: bool = int(row[0]) == FIELD_BURSTS - 1 and evo(EVO_ROT_BLOOM)
	var amount := _poison_second(enemy) * (ROT_BLOOM_SECONDS if bloom else FIELD_SECONDS)
	if amount <= 0.0:
		return
	var at: Vector2 = enemy.global_position
	var dealt := calling_hit(tower, enemy, amount, ROT_BLOOM_TAG if bloom else DEATHCAP_TAG, EVO_ROT_BLOOM if bloom else EVO_DEATHCAP_FIELD,
		false, false, &"", DEATHCAP_BOSS)
	if dealt <= 0.0:
		return
	row[0] = int(row[0]) + 1
	if is_instance_valid(enemy):
		enemy.set_meta(BURSTS_META, row)
	# Rot Bloom's 3rd burst: sp_rot_bloom opens on the ground where its feet were (33af7bec; it stays there, never follows)
	if bloom and _flecks.size() < FLECKS_MAX and evo_art_tex(evo_art, ART_ROT_BLOOM) != null:
		_flecks.append([ART_ROT_BLOOM, to_local(at), 0.0, false])
		queue_redraw()
		return
	Reactions._effect(&"landing_dust", at, self, 1.6 if bloom else 1.0)  # The dark burst under its foot (a rot flower: bigger)

# Laps and the Waymark start Deathcap's count of 3 again (polled).
func _burst_walk(enemy) -> void:
	var row: Array = enemy.get_meta(BURSTS_META)
	var i := index_of(enemy)
	if i < 0:
		return
	var passed := bool(enemy.get("passed_waymark"))
	if i + SEASON_LAP_POINTS < int(row[1]) or passed != bool(row[2]):
		enemy.set_meta(BURSTS_META, [0, i, passed])
	elif i > int(row[1]):
		row[1] = i
		enemy.set_meta(BURSTS_META, row)

# Deathcap's bursts left this walk (UI: the three pips over the nightmare). 0 without the row.
func bursts_left(enemy) -> int:
	if not evo(EVO_DEATHCAP_FIELD) or not is_instance_valid(enemy):
		return 0
	return FIELD_BURSTS - int((enemy.get_meta(BURSTS_META, [0]) as Array)[0])

# Thick Haze (Spore Season's Deepen): once a nightmare reaches the limit, every further 10 steps 1 s of its Poisoned at once.
func _thick_haze(enemy, walk: Array) -> void:
	if not season_on():
		return
	var limit_points := int(round(_season_cap(enemy) / SEASON_PER_STEP)) * 2
	var past: int = int(walk[1]) - int(walk[0]) - limit_points
	if past < HAZE_EVERY_POINTS:
		return
	var due := past / HAZE_EVERY_POINTS
	if due <= int(walk[3]):
		return
	walk[3] = due
	enemy.set_meta(SEASON_META, walk)
	var tower = enemy.statuses.source(EnemyStatuses.SPORED)
	if not is_own(tower):
		tower = _owner_for(enemy.global_position)
	var amount := _poison_second(enemy) * HAZE_SECONDS
	if tower == null or amount <= 0.0:
		return
	var at: Vector2 = enemy.global_position
	if calling_hit(tower, enemy, amount, HAZE_TAG, EVO_THICK_HAZE, false, false, &"", HAZE_BOSS) > 0.0:
		Reactions._effect(&"landing_dust", at, self, 0.9)  # The green puff on it

# Focus: how many of `want` free hits `tower` may give now (Clump 1 a second; Trampled Ground 2 for a rank III+ Warden).
func _focus_take(tower, want: int) -> int:
	var limit := TRAMPLE_HITS if evo(EVO_TRAMPLED) and gate_rank(tower) >= TRAMPLE_RANK else 1
	var row: Array = tower.get_meta(FOCUS_META, [-INF, 0])
	if now() - float(row[0]) >= 1.0:
		row = [now(), 0]
	var granted := clampi(limit - int(row[1]), 0, want)
	row[1] = int(row[1]) + granted
	tower.set_meta(FOCUS_META, row)
	return granted

# The attacking Wardens touching `at`, the strongest first; `king` (a throne's Warden) always first.
func _focus_wardens(at: Vector2, king = null) -> Array:
	var out: Array = towers().filter(func(t) -> bool: return t is Tower and t.tower_data.can_attack and touches_point(t, at))
	out.sort_custom(func(a, b) -> bool: return second_of(a) > second_of(b))
	if king != null and out.has(king):
		out.erase(king)
		out.push_front(king)
	return out

# Clump (Focus style): a step on a clump draws a free hit from each attacking Warden touching it (the 3 strongest, a
# throne's Warden first, each once a second; period 1 s); Trampled Ground: a rank III+ one gives 2, the second at half
# (period 1 s); Elder Cap: the throne's Warden one for each of its own attacks instead (per own attack: no cap); Retinue:
# the other Wardens at the throne, any rank, at half, one for each of their attacks (no cap). `trodden` (Trodden Path): a
# step beside the clump, with its own +1 a second per Warden (period 1 s). Rank gates read gate_rank (The Old Ones).
func _clump_hits(point: Vector2, enemy, trodden: bool = false) -> void:
	if not mushrooms.has(point):
		return
	var m: Dictionary = mushrooms[point]
	var at: Vector2 = _route_px[int(_index[point])]
	var king = m.get("king").get_ref() if m.get("king") is WeakRef else null
	var struck := false
	var picks: Array = _focus_wardens(at, king).slice(0, CLUMP_WARDENS)
	for tower in picks:
		if not living(enemy):
			return
		if tower == king and evo(EVO_ELDER):
			if bool(tower.get_meta(ATTACK_META, false)):
				tower.set_meta(ATTACK_META, false)
				struck = calling_hit(tower, enemy, 1.0, FREE_HIT_TAG, EVO_ELDER, false, true, &"", FOCUS_BOSS, INF) > 0.0 or struck
		else:
			var want := TRAMPLE_HITS if evo(EVO_TRAMPLED) and gate_rank(tower) >= TRAMPLE_RANK else 1
			var given := _focus_take(tower, want)
			for k in given:
				var own := EVO_CLUMP if k == 0 else EVO_TRAMPLED
				struck = calling_hit(tower, enemy, 1.0 if k == 0 else TRAMPLE_SECOND, FREE_HIT_TAG, own, false, true, &"", FOCUS_BOSS) > 0.0 or struck
		if trodden and living(enemy) and now() >= float(tower.get_meta(TRODDEN_META, -INF)):
			tower.set_meta(TRODDEN_META, now() + TRODDEN_EVERY)
			struck = calling_hit(tower, enemy, 1.0, FREE_HIT_TAG, EVO_TRODDEN, false, true, &"", FOCUS_BOSS) > 0.0 or struck
	if evo(EVO_RETINUE) and bool(m.get("throne", false)):  # The ring round the throne: Clump's set without its holder
		var attendants: Array = picks.filter(func(t) -> bool: return t != king)
		for tower in attendants.slice(0, RETINUE_MAX):
			if living(enemy) and bool(tower.get_meta(ATTACK_META, false)):
				tower.set_meta(ATTACK_META, false)
				struck = calling_hit(tower, enemy, RETINUE_SHARE, FREE_HIT_TAG, EVO_RETINUE, false, true, &"", FOCUS_BOSS, INF) > 0.0 or struck
	if struck:
		for tower in picks:
			_line_fx(body(tower), body(enemy), 3.0)

# Trodden Path (Pile-On's Deepen): a walker on the step just before or after a clump (1 step = 2 route points) counts as
# stepping on it: no mushroom eaten, no dose. Each side of each clump once per nightmare.
func _trodden_step(point: Vector2, enemy) -> void:
	var i := int(_index[point])
	var seen: Dictionary = enemy.get_meta(TRODDEN_SEEN_META, {})
	for off in [-TRODDEN_POINTS, -1, 1, TRODDEN_POINTS]:
		var k: int = i + off
		if k < 0 or k >= _route.size() or not mushrooms.has(_route[k]) or mushrooms.has(point):
			continue
		var key := "%s:%d" % [str(_route[k]), signi(off)]
		if seen.has(key):
			continue
		seen[key] = true
		enemy.set_meta(TRODDEN_SEEN_META, seen)
		_clump_hits(_route[k], enemy, true)
		return

# Pile-On (Trampled Ground's capstone): a direct hit by a rank III+ Warden touching a clump, on a nightmare within 2 steps
# of it, calls a free hit from each other rank III+ Warden touching that clump (Trampled's 2 a second). Never from a free hit.
func _pile_on(source, enemy) -> void:
	if not (source is Tower) or gate_rank(source) < PILE_RANK or not living(enemy):
		return
	var i := index_of(enemy)
	if i < 0:
		return
	for k in range(maxi(i - PILE_POINTS, 0), mini(i + PILE_POINTS, _route.size() - 1) + 1):
		if not mushrooms.has(_route[k]) or not touches_point(source, _route_px[k]):
			continue
		var struck := false
		for tower in _focus_wardens(_route_px[k]):
			if tower == source or gate_rank(tower) < PILE_RANK or not living(enemy):
				continue
			if _focus_take(tower, 1) > 0:
				struck = calling_hit(tower, enemy, 1.0, FREE_HIT_TAG, EVO_PILE_ON, false, true, &"", FOCUS_BOSS) > 0.0 or struck
				_line_fx(body(tower), body(enemy), 3.0)
		if struck:
			_line_fx(body(source), body(enemy), 3.0)
		return  # One clump per hit

# Elder Cap and Retinue: each of a Warden's own attacks readies one free hit at the throne.
func _hook_attacks() -> void:
	for tower in towers():
		var id: int = tower.get_instance_id()
		if tower is Tower and tower.tower_data.can_attack and not _attack_hooked.has(id):
			_attack_hooked[id] = true
			tower.attack_released.connect(_on_attack_released)

func _on_attack_released(tower) -> void:
	if is_instance_valid(tower) and (evo(EVO_ELDER) or evo(EVO_RETINUE)):
		tower.set_meta(ATTACK_META, true)

# Toadstool Throne (final pass 2026-10-24: by age, not form): one throne on the board. Its Warden is the attacking Warden
# at a clump (Clump's set: the 3 strongest touching it) planted earliest, once THRONE_AGE drifts ago (ties: the higher rank,
# then the nearest to its clump); the throne is that Warden's clump (the fullest, then the nearest). Worked out from
# positions (a Walking Wood swap moves it) whenever the board or the mushrooms change, and at each drift start.
func _refresh_thrones() -> void:
	for point in mushrooms:
		mushrooms[point].erase("throne")
		mushrooms[point].erase("king")
	if not evo(EVO_THRONE):
		return
	var drift := _current_drift()
	var best_tower = null
	var best_point = null
	for point in mushrooms:
		var m: Dictionary = mushrooms[point]
		var at: Vector2 = _route_px[int(_index[point])]
		for tower in _focus_wardens(at).slice(0, CLUMP_WARDENS):
			if drift - _planted_drift(tower) < THRONE_AGE:
				continue
			if best_tower == null or _older_holder(tower, at, m, best_tower, best_point):
				best_tower = tower
				best_point = point
	if best_point != null:
		mushrooms[best_point]["throne"] = true
		mushrooms[best_point]["king"] = weakref(best_tower)

# Whether `tower` at the clump on `at` beats the holder found so far: planted earlier, then the higher rank, then (the same
# Warden at two clumps) the fuller clump, then the nearer.
func _older_holder(tower, at: Vector2, m: Dictionary, best, best_point) -> bool:
	var a := _planted_drift(tower)
	var b := _planted_drift(best)
	if a != b:
		return a < b
	if tower != best:
		if int(tower.rank) != int(best.rank):
			return int(tower.rank) > int(best.rank)
	var o: Dictionary = mushrooms[best_point]
	if int(m.caps) != int(o.caps):
		return int(m.caps) > int(o.caps)
	var best_at: Vector2 = _route_px[int(_index[best_point])]
	return tower.global_position.distance_squared_to(at) < best.global_position.distance_squared_to(best_at)

# The would-be throne holder before any throne exists (UI's age ring fills toward THRONE_AGE): [Warden, drifts of age] for
# the Warden _refresh_thrones would pick with no age gate, or [] with no clump Warden. (UI Code, CallingCues.)
func throne_progress() -> Array:
	if not evo(EVO_THRONE):
		return []
	var best_tower = null
	var best_point = null
	for point in mushrooms:
		var at: Vector2 = _route_px[int(_index[point])]
		for tower in _focus_wardens(at).slice(0, CLUMP_WARDENS):
			if best_tower == null or _older_holder(tower, at, mushrooms[point], best_tower, best_point):
				best_tower = tower
				best_point = point
	return [best_tower, _current_drift() - _planted_drift(best_tower)] if best_tower != null else []

# Shared Caps (Support style): a dose also adds 2 stacks (Charged / Exposed 1) to the status the highest-rank other-family
# Warden touching that mushroom (Sprouts count; ties to the nearest) already put on the nightmare; for a Sprout, the
# Poisoned the dose just put on. Quietly: never starts or copies a status, never Rooted, Drowsy within its limit.
func _shared_caps(at: Vector2, tower, enemy) -> void:
	var best = _shared_pick(at)
	if best == null or not living(enemy):
		return
	var status := EnemyStatuses.SPORED if _is_sprout(best) else status_of(best)
	if status == &"" or not _stackable(status) or not enemy.statuses.has(status):
		return
	if not _is_sprout(best) and enemy.statuses.source(status) != best:
		return  # Only a status that Warden itself put on it (no copying)
	var small := status == EnemyStatuses.STATIC or status == EnemyStatuses.MARKED
	var added := _feed(enemy, status, SHARED_SMALL if small else SHARED_STACKS)
	if added > 0:
		setup_quiet(enemy, EVO_BORROWED, status, added)
		_line_fx(body(best), body(enemy), 1.5, EnemyStatuses.COLORS.get(status, Palette.MOSS))
		credit(EVO_BORROWED, enemy.global_position, tower)

# Shared Caps' pick at a mushroom on `at` (also Host Trees' host): the highest-rank other-family Warden touching it
# (Sprouts count), ties to the nearest; null if none.
func _shared_pick(at: Vector2):
	var best = null
	for other in towers():
		if not is_other(other) or not touches_point(other, at):
			continue
		if best == null or int(other.rank) > int(best.rank) or (int(other.rank) == int(best.rank) \
				and other.global_position.distance_squared_to(at) < best.global_position.distance_squared_to(at)):
			best = other
	return best

# Feeding Ground (Support follow-up): each dose turns the next 6 steps of the walker's own leg into fed ground for 8 s.
func _feed_ground(enemy, point: Vector2) -> void:
	var from := index_of(enemy)
	if from < 0:
		from = int(_index[point])
	_fed.append([from, mini(from + FEED_POINTS, _route.size() - 1), now() + FEED_SECONDS])
	while _fed.size() > FEED_MAX_STRETCHES:
		_fed.pop_front()
	credit(EVO_FEEDING, _route_px[from])
	queue_redraw()

func _fed_at(i: int) -> bool:
	if i < 0:
		return false
	for stretch in _fed:
		if int(stretch[0]) <= i and i <= int(stretch[1]) and now() < float(stretch[2]):
			return true
	return false

# Windfall (Feeding Ground's capstone): a nightmare dispelled on fed ground leaves a pale mushroom where it fell.
func _windfall(at: Vector2) -> void:
	var i := nearest_point(at, FALL_CELLS)
	if i < 0 or mushrooms.has(_route[i]):
		return
	_grow(_route[i], false, null, GEN_PLANTED)
	if mushrooms.has(_route[i]):
		mushrooms[_route[i]]["crop"] = true
		credit(EVO_WINDFALL, _route_px[i])

# Sporefall (Windfall's Deepen): a status another family's Warden fills on a nightmare on fed ground plants a mushroom 3
# steps ahead of it, on its own leg. Once for each status on each nightmare.
func _sporefall(tower, enemy, status: StringName) -> void:
	if not is_other(tower):
		return
	var statuses: EnemyStatuses = enemy.statuses
	var most: int = statuses.get_max_stacks(status)
	var before: Array = enemy.get_meta(SEED_BEFORE_META, [&"", 0])
	var was: int = int(before[1]) if StringName(before[0]) == status else 0
	if statuses.stacks(status) < most or was >= most:
		return  # Only the hit that fills it
	var done: Dictionary = enemy.get_meta(SPOREFALL_META, {})
	var i := index_of(enemy)
	if done.has(status) or not _fed_at(i):
		return
	done[status] = true
	enemy.set_meta(SPOREFALL_META, done)
	if _plant(i + SPOREFALL_POINTS, _owner_for(enemy.global_position), GEN_PLANTED, enemy):
		mushrooms[_route[i + SPOREFALL_POINTS]]["sporefall"] = true
		Reactions._effect(&"landing_dust", _route_px[i + SPOREFALL_POINTS], self, 0.6)
		credit(EVO_SPOREFALL, _route_px[i + SPOREFALL_POINTS], tower)

# Host Trees (Support follow-up, final pass 2026-10-24): the Warden Shared Caps picks at each mushroom wears a cap (Sprouts
# too); one no longer picked keeps it HOST_LINGER s. Spreading Caps: another family's Warden within SPREAD_CELLS of a capped
# Warden wears one too, as long as that one's (one link only). Worked out when mushrooms grow or go and when the board
# changes, never polled.
func _recount_caps() -> void:
	if not evo(EVO_HOST_TREES):
		_capped.clear()
		return
	var next := {}
	var others: Array = towers().filter(is_other)
	for point in mushrooms:
		var host = _shared_pick(_route_px[int(_index[point])])
		if host != null:
			next[host.get_instance_id()] = [weakref(host), INF, false]
	for id in _capped:  # Lost its mushroom: the cap stays 8 s more
		var row: Array = _capped[id]
		if next.has(id) or bool(row[2]) or row[0].get_ref() == null:
			continue
		var until: float = now() + HOST_LINGER if float(row[1]) == INF else float(row[1])
		if until > now():
			next[id] = [row[0], until, false]
	if evo(EVO_SPREADING):
		var sources: Array = next.values()
		for tower in others:
			var id: int = tower.get_instance_id()
			if next.has(id):
				continue
			var until := -INF
			for row in sources:
				var from = row[0].get_ref()
				if from != null and from.global_position.distance_to(tower.global_position) <= SPREAD_CELLS * cell():
					until = maxf(until, float(row[1]))
			if until > now():
				next[id] = [weakref(tower), until, true]
	_capped = next
	queue_redraw()

# Whether `tower` wears a cap right now (Host Trees, Spreading Caps).
func is_capped(tower) -> bool:
	if not (tower is Tower) or not is_instance_valid(tower):
		return false
	var row: Array = _capped.get(tower.get_instance_id(), [])
	return not row.is_empty() and float(row[1]) > now()

func capped_count() -> int:
	var n := 0
	for id in _capped:
		var row: Array = _capped[id]
		if row[0].get_ref() != null and float(row[1]) > now():
			n += 1
	return n

# Host Trees' part (1.15) or, while Host Grove's 3+ capped Wardens stand, 1.30: a replacement, never a product.
func _host_part() -> float:
	var frame := Engine.get_process_frames()
	if frame != _host_frame:
		_host_frame = frame
		_host_on = evo(EVO_HOST_GROVE) and capped_count() >= HOST_GROVE_AT
	return HOST_GROVE_POTENCY if _host_on else HOST_TREES_POTENCY

func _host_credit(source) -> void:
	if now() >= float(source.get_meta(HOST_CREDIT_META, -INF)):
		source.set_meta(HOST_CREDIT_META, now() + 1.0)
		credit(EVO_HOST_GROVE if _host_on else EVO_HOST_TREES, source.global_position, source)

# Host Trees' direct-hit part (DreamState._calling_hit_multiplier's Spore Print branch): a capped Warden of another family
# whose own status deals no damage (not Poisoned or Charged, or none) hitting a Poisoned nightmare: 1.15 (Host Grove 1.30).
# A Warden's real hit only (never a Calling output, R1). Noted inside the x4 card cap (X5).
func host_hit_multiplier(source, enemy) -> float:
	if not evo(EVO_HOST_TREES) or DamageLog.calling_now != &"" or not is_capped(source) or is_own(source) \
			or not is_instance_valid(enemy) or not enemy.statuses.has(EnemyStatuses.SPORED):
		return 1.0
	var status := status_of(source)
	if _is_sprout(source) or status == EnemyStatuses.SPORED or status == EnemyStatuses.STATIC:
		return 1.0  # Its status deals damage: Host Trees raises that instead (host_potency)
	var part := _host_part()
	DamageLog.note_card_bonus(String(EVO_HOST_GROVE if _host_on else EVO_HOST_TREES), part)
	_host_credit(source)
	return part

# Host Trees / Host Grove's Potency part (DreamState.calling_potency): a capped Warden of another family's effect damage, every
# Reactions.EFFECT_TAGS tag (never a Reaction's damage: the caller checks), 1.15 (Host Grove 1.30). Reactions._host_grove takes
# max(host, undiluted) / undiluted with Undiluted on the tag.
func host_potency(source, tag: StringName) -> float:
	if not evo(EVO_HOST_TREES) or not Reactions.is_effect(tag) or not is_capped(source) or is_own(source):
		return 1.0
	var part := _host_part()
	# X5: inside the x4 card cap, noted and credited only for the factor actually used: a larger Undiluted leaves Host
	# Trees nothing (build_review_td.md 3: it noted 1.30 into the cap anyway).
	var undiluted := 1.0
	if DreamState.undiluted_on:
		undiluted = DreamState.UNDILUTED_POISONED if tag == &"spored" else (DreamState.UNDILUTED_CHARGED if tag == &"static" else 1.0)
	var used := maxf(part, undiluted) / undiluted
	if used <= 1.0:
		return part
	DamageLog.note_card_bonus(String(EVO_HOST_GROVE if _host_on else EVO_HOST_TREES), used)
	_host_credit(source)
	return part

# Sporeling Support's extra stacks (Feeding Ground; Host Trees' +1 is gone, final pass 2026-10-24): their own slot, outside
# the lent cards' (Balancing 2026-10-23): at most 2 a hit (Charged / Exposed 1, once a second per Warden), within max(2 x the
# hit's stacks, 3) (Charged / Exposed 2). Other families' Wardens only, Sprouts too; never Rooted.
func _support_stacks(tower, enemy, status: StringName, base: int) -> int:
	if not is_other(tower) or not _stackable(status) or not evo(EVO_FEEDING):
		return 0
	var fed := _fed_at(index_of(enemy))
	var extra := FEED_STACKS if fed else 0
	if extra <= 0:
		return 0
	var small := status == EnemyStatuses.STATIC or status == EnemyStatuses.MARKED
	extra = mini(extra, SUPPORT_MAX)
	if small:
		if now() < float(tower.get_meta(SUPPORT_SMALL_META, -INF)):
			return 0
		tower.set_meta(SUPPORT_SMALL_META, now() + SUPPORT_SMALL_EVERY)
		extra = mini(extra, SUPPORT_SMALL)
	extra = mini(extra, SUPPORT_HIT_SMALL if small else maxi(2 * base, SUPPORT_HIT_FLOOR))
	if extra > 0:
		_setup_part(enemy, EVO_FEEDING, status, extra)
		credit(EVO_FEEDING, enemy.global_position, tower)
	return extra

# Stomping Ground (non-status builds, owner 2026-10-19): a step on a mushroom takes a free hit from each attacking Warden
# touching that step, any family, the strongest first, at most STOMP_WARDENS; each Warden once a second (the free-hit
# rule). A Calling output, so other families' lent cards read it as that Warden's hit. Bosses take half.
func _stomp(at: Vector2, enemy) -> void:
	var stompers: Array = towers().filter(func(t) -> bool: return t is Tower and t.tower_data.can_attack and touches_point(t, at))
	if stompers.is_empty():
		return
	stompers.sort_custom(func(a, b) -> bool: return second_of(a) > second_of(b))
	var scale := STOMP_BOSS if enemy.statuses.is_boss else 1.0
	var struck := false
	for tower in stompers.slice(0, STOMP_WARDENS):
		if not living(enemy):
			break
		if calling_free_hit(tower, enemy, scale, FREE_HIT_TAG, INF, EVO_STOMPING):
			struck = true
	if struck:
		credit(EVO_STOMPING, enemy.global_position)

# Second Crop: a nightmare dispelled within CROP_STEPS steps of a mushroom leaves one too, Poisoned or not (a pale cap).
func _crop_near(at: Vector2) -> bool:
	var i := nearest_point(at, FALL_CELLS)
	if i < 0:
		return false
	for k in range(maxi(i - CROP_STEPS * 2, 0), mini(i + CROP_STEPS * 2, _route.size() - 1) + 1):
		if mushrooms.has(_route[k]):
			return true
	return false

# Fruiting (lent; non-status builds): Sporeling Wardens and Wardens near them deal FRUIT_PER_WARDEN more to a nightmare
# for each other Warden that hit it in the last FRUIT_WINDOW s, up to FRUIT_MAX. Hits only.
func _note_hitter(source, enemy) -> void:
	var hitters: Dictionary = enemy.get_meta(FRUIT_META, {})
	hitters[source.get_instance_id()] = now()
	enemy.set_meta(FRUIT_META, hitters)

func _fruit_count(source, enemy) -> int:
	var hitters: Dictionary = enemy.get_meta(FRUIT_META, {})
	var n := 0  # Other Wardens only: one Warden alone gets nothing (not a flat boost)
	var stale: Array = []
	var me: int = source.get_instance_id()
	for id in hitters:
		if now() - float(hitters[id]) <= FRUIT_WINDOW:
			if id != me:
				n += 1
		else:
			stale.append(id)
	for id in stale:
		hitters.erase(id)
	return n

func wants_damage_hook() -> bool:
	return rule(FRUITING) or evo(EVO_DRIFTING) or evo(EVO_SEASON)

# DreamState.batch_damage_multiplier: Drifting Spores / Spore Season on Poisoned ticks, Fruiting on hits (1.0 with neither).
func damage_multiplier(enemy, source, tag: StringName = &"") -> float:
	var out := 1.0
	if tag == &"spored" and (evo(EVO_DRIFTING) or evo(EVO_SEASON)) and is_instance_valid(enemy):
		out *= _season_multiplier(enemy)
	return out * _fruiting_multiplier(enemy, source, tag)

# Drifting Spores: a nightmare's Poisoned deals 1% more for each step it has walked since its first dose, up to +30%
# (bosses +15%); Spore Season (15+ mushrooms): from its first step, up to +60% (bosses +30%). Damage only; noted inside
# the x4 card cap (X5) under the row that set it.
func _season_multiplier(enemy) -> float:
	var bonus := season_bonus(enemy)
	if bonus <= 0.0:
		return 1.0
	var row := EVO_SEASON if season_on() else EVO_DRIFTING
	DamageLog.note_card_bonus(String(row), 1.0 + bonus)
	if now() >= float(enemy.get_meta(SEASON_CREDIT_META, -INF)):
		enemy.set_meta(SEASON_CREDIT_META, now() + 1.0)
		credit(row, enemy.global_position)
	return 1.0 + bonus

func _fruiting_multiplier(enemy, source, tag: StringName) -> float:
	var calling: bool = DamageLog.calling_now != &"" and String(DamageLog.calling_now) != FAMILY  # F1: another family's Calling output is a hit
	if not rule(FRUITING) or (tag != &"" and not calling) or not (source is Tower) or not is_instance_valid(source) \
			or not is_instance_valid(enemy) or not source.tower_data.can_attack:
		return 1.0
	if not is_own(source) and not own_towers().any(func(t) -> bool: return near(t.global_position, source.global_position)):
		return 1.0
	var n := _fruit_count(source, enemy)
	if n < 1:
		return 1.0
	var bonus := 1.0 + minf(FRUIT_PER_WARDEN * n, FRUIT_MAX)
	DamageLog.note_card_bonus(String(FRUITING), bonus)
	credit(FRUITING, enemy.global_position, source)
	return bonus

# Parting Puff (lent; non-status builds): a hit by a Sporeling Warden or a Warden near one that dispels a nightmare puffs:
# up to PUFF_MAX nightmares within 1 cell take PUFF_SHARE of that hit (bosses half). Puffs never puff again.
func _puff(event, source, enemy) -> void:
	if event.tag == PUFF_TAG or not (is_own(source) or own_towers().any(func(t) -> bool: return near(t.global_position, source.global_position))):
		return
	var amount := float(event.amount) * PUFF_SHARE
	if amount <= 0.0:
		return
	var at: Vector2 = enemy.global_position
	for other in nightmares_touching(enemy, PUFF_MAX):
		strike(source, other, amount * (PUFF_BOSS if other.statuses.is_boss else 1.0), PUFF_TAG, true, PARTING_PUFF)
		if source is Tower and is_instance_valid(other) and not other.is_cleansed:
			source.spatter(other, true)  # Spattered (section 37): a card's splash gives 1 stack of the Warden's status
	Reactions._effect(&"landing_dust", at, self, 0.8)  # The grey-green puff
	credit(PARTING_PUFF, at, source)


# Catching / Outbreak (polled): a nightmare carrying a caught dose passes it to the first nightmare it touches.
func _catching() -> void:
	for enemy in enemies():
		if not enemy.has_meta(CATCH_META):
			continue
		var c: Array = enemy.get_meta(CATCH_META)
		var tower = c[3].get_ref()
		if now() > float(c[0]) or not is_instance_valid(tower):
			enemy.remove_meta(CATCH_META)
			continue
		var touching_now := nightmares_touching(enemy, 1)
		if touching_now.is_empty():
			continue
		enemy.remove_meta(CATCH_META)
		var other = touching_now[0]
		_apply_dose(tower, other, int(c[1]), EVO_OUTBREAK if int(c[2]) > 0 else EVO_CATCHING)  # (setup credit 2026-10-16)
		_line_fx(body(enemy), body(other), 2.0, Palette.MOSS)
		credit(EVO_OUTBREAK if int(c[2]) > 0 else EVO_CATCHING, other.global_position)
		var next := int(c[1]) / 2
		if evo(EVO_OUTBREAK) and int(c[2]) < OUTBREAK_HOPS and next >= 1 and living(other):
			other.set_meta(CATCH_META, [now() + CATCH_WINDOW, next, int(c[2]) + 1, weakref(tower)])

# --- The poll -------------------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	super._process(delta)
	if not _flecks.is_empty() and not get_tree().paused:
		_age_flecks(delta)
	if dream_state == null or not place_on() or get_tree().paused:
		return
	var breathe := int(Time.get_ticks_msec() / 1000.0 * MUSHROOM_FPS) % MUSHROOM_FRAMES  # The mushrooms breathe (4 fps)
	if breathe != _breathe_frame:
		_breathe_frame = breathe
		if not mushrooms.is_empty() or not _regrow.is_empty():
			queue_redraw()
	var rot_on := evo(EVO_ROT_GROUND) and not _fairy.is_empty()
	if rot_on or not _fed.is_empty():  # The rot ring and fed ground sheets loop on their own clocks
		var stamp := evo_art_stamp(evo_art, [ART_ROT if rot_on else &"", ART_FED if not _fed.is_empty() else &""])
		if stamp != _art_stamp:
			_art_stamp = stamp
			queue_redraw()
	if season_on() != _haze_shown or (_haze_shown and evo_art_frame(evo_art, ART_HAZE) != _haze_frame):
		_haze_shown = season_on()  # Spore Season's haze: lit or out, and its own 3 fps loop
		_haze_frame = evo_art_frame(evo_art, ART_HAZE)
		queue_redraw()
	# The regrow clocks run only during a drift
	if not resting() and not _regrow.is_empty():
		for point in _regrow.keys():
			_regrow[point] = float(_regrow[point]) - delta
			if float(_regrow[point]) <= 0.0:
				_regrow.erase(point)
				if not mushrooms.has(point):
					_grow(point, true)
					_fairy_grew(point)
	# Steps: a walker's centre reaching a mushroom's route point (every frame: a fast nightmare must not skip one). Rot
	# Ground's bare beds and Trodden Path's steps beside a clump count too.
	var rot := evo(EVO_ROT_GROUND) and not _fairy.is_empty()
	var trodden := evo(EVO_TRODDEN)
	if mushrooms.is_empty() and not rot:
		return
	var reach := (STEP_CELLS * cell()) ** 2
	for enemy in enemies():
		if not enemy.on_route():  # A route flyer steps on the mushrooms under its route (enemy_design.md "Flyers")
			continue
		var point: Vector2 = enemy.get_target_cell()
		if not _index.has(point) or enemy.global_position.distance_squared_to(_route_px[int(_index[point])]) > reach:
			continue
		if mushrooms.has(point):
			_stepped(point, enemy)
		elif rot and _fairy.has(point):
			_rot_step(point, enemy)
		if trodden and living(enemy):
			_trodden_step(point, enemy)

# Sprout Beds (Fairy Path on an old save) shows itself: a puff and its credit when its clock grows a mushroom.
func _fairy_grew(point: Vector2) -> void:
	if not (evo(EVO_SPROUT_BEDS) or evo(EVO_FAIRY_PATH)) or not mushrooms.has(point) or not _fairy.has(point):
		return
	var at: Vector2 = _route_px[int(_index[point])]
	Reactions._effect(&"landing_dust", at, self, 0.5)
	credit(EVO_SPROUT_BEDS if evo(EVO_SPROUT_BEDS) else EVO_FAIRY_PATH, at)

func on_poll() -> void:
	if rule(GONE_TO_SEED):
		_hook_seed_tracker()
	if _dirty:
		_dirty = false
		_recount_caps()
		_refresh_thrones()
	if _walk_on():  # Every walker's walk (Spore Season counts from its first point seen)
		for enemy in enemies():
			_season_walk(enemy)
	if evo(EVO_DEATHCAP_FIELD):
		for enemy in enemies():
			if enemy.has_meta(BURSTS_META):
				_burst_walk(enemy)
	if not _fed.is_empty():
		_fed = _fed.filter(func(stretch) -> bool: return now() < float(stretch[2]))
		queue_redraw()  # Fed ground fades as its 8 s run out
	elif not _capped.is_empty():
		for id in _capped.keys():
			if float(_capped[id][1]) <= now() or _capped[id][0].get_ref() == null:
				_capped.erase(id)
		queue_redraw()  # Caps fade after their mushroom goes
	if evo(EVO_CATCHING):
		_catching()
	if rule(SPORE_HAZE):
		_haze_in -= POLL
		if _haze_in <= 0.0:
			_haze_in = 1.0  # Counted each second
			_haze.clear()
			for tower in own_towers():
				if not SINGLE_TARGET.has(tower.tower_data.get_id()):
					continue
				var count := 0
				for point in mushrooms:
					if near(tower.global_position, _route_px[int(_index[point])]):
						count += 1
				if count >= HAZE_MUSHROOMS:
					_haze[tower.get_instance_id()] = true
	if rule(HOTHOUSE):
		for enemy in enemies():
			_hothouse(enemy)
	if rule(SEEPING_IN):
		for enemy in enemies():
			_seep(enemy)

# Hothouse (lent, a bet): when a nightmare's Poisoned reaches 6, each other status on it gains 5 at once, quietly
# (no clock, strength or source change; never starts a status; never Rooted). Once per nightmare.
func _hothouse(enemy) -> void:
	var statuses: EnemyStatuses = enemy.statuses
	if enemy.has_meta(HOT_META) or statuses.stacks(EnemyStatuses.SPORED) < HOTHOUSE_AT:
		return
	var any := false
	for id in statuses.active_ids():
		if id == EnemyStatuses.SPORED or id == DreamState.FROST:
			continue
		var added := statuses.add_quiet(id, HOTHOUSE_ADD)
		setup_quiet(enemy, HOTHOUSE, id, added)  # (setup credit 2026-10-16)
		if added > 0:
			any = true
	if any:
		enemy.set_meta(HOT_META, true)
		Reactions._effect(&"landing_dust", enemy.global_position, self, 0.6)

# --- A Warden's own next application (Tower._apply_one_status asks through DreamState.class_stacks) ------------------

# The stacks `tower`'s own application of `status` adds to `enemy` (never fewer than `stacks`).
func own_stacks(tower, enemy, status: StringName, stacks: int) -> int:
	if (rule(GONE_TO_SEED) or evo(EVO_SPOREFALL)) and living(enemy):  # (Sporefall reads it too: only the hit that fills a status)
		enemy.set_meta(SEED_BEFORE_META, [status, enemy.statuses.stacks(status), Engine.get_process_frames()])  # (F9: the frame)
	if stacks <= 0 or not living(enemy) or status == EnemyStatuses.HELD:
		return stacks
	var id: int = tower.get_instance_id()
	if is_own(tower) and status == EnemyStatuses.SPORED:
		# Open Season: after a nightmare steps on a mushroom, each spore Warden's next attack on it is a dose too
		if rule(OPEN_SEASON) and now() <= float(enemy.get_meta(OPEN_META, -INF)):
			var by: Dictionary = enemy.get_meta(OPEN_BY_META, {})
			if now() >= float(by.get(id, -INF)):
				by[id] = now() + OPEN_SEASON_EVERY
				enemy.set_meta(OPEN_BY_META, by)
				_setup_part(enemy, OPEN_SEASON, status, DOSE - stacks)  # (setup credit 2026-10-16)
				stacks = maxi(stacks, DOSE)
		# Overnight (lent): 3 at once on a nightmare carrying another family's status, once a second each
		if false and rule(OVERNIGHT) and stacks < OVERNIGHT_STACKS and _carries_other(enemy):  # (Its old +3 Poisoned: _overnight since 2026-10-15)
			var next: Dictionary = enemy.get_meta(NIGHT_META, {})
			if now() >= float(next.get(id, -INF)):
				next[id] = now() + OVERNIGHT_EVERY
				enemy.set_meta(NIGHT_META, next)
				stacks = OVERNIGHT_STACKS
	elif rule(SECOND_HELPING) and is_other_family(tower) and enemy.has_meta(FIRST_HIT_META):
		# Second Helping (2026-10-14): after a spore Warden first hits a nightmare, the next hit on it from another family's
		# Warden touching that spore Warden adds 3 of its own status. Once per nightmare for each spore Warden touching it.
		var hit: Dictionary = enemy.get_meta(FIRST_HIT_META)
		var helped: Dictionary = enemy.get_meta(HELPED_META, {})
		for spore in own_towers():
			var key := "%d:%d" % [id, spore.get_instance_id()]
			if hit.has(spore.get_instance_id()) and not helped.has(key) and touching(spore, tower):
				helped[key] = true
				enemy.set_meta(HELPED_META, helped)
				_setup_part(enemy, SECOND_HELPING, status, HELPING_STACKS - stacks)  # (setup credit 2026-10-16)
				stacks = maxi(stacks, HELPING_STACKS)
				break
	return _stack_cards(tower, enemy, status, stacks)

# F1 lent × Calling (owner 2026-10-18; f1_spec.md): another family's Calling application (a ripple's Soaked, Hush-a-bye's
# Drowsy, a carry that starts a status…) as the stack cards see it: Gone to Seed's before-stamp, then the stack cards'
# extras, at most max(2 x its stacks, 2) (Charged / Exposed at most 2; Charged still stops one short). `bare`: the stamp
# only (Rain on the Bank's Drowsy).
const CALLING_EXTRA_SMALL := 2

func calling_stacks(tower, enemy, status: StringName, stacks: int, bare: bool = false) -> int:
	if (rule(GONE_TO_SEED) or evo(EVO_SPOREFALL)) and living(enemy):
		enemy.set_meta(SEED_BEFORE_META, [status, enemy.statuses.stacks(status), Engine.get_process_frames()])
	if bare or stacks <= 0 or not living(enemy) or status == EnemyStatuses.HELD or not (tower is Tower):
		return stacks
	var extra: int = _stack_cards(tower, enemy, status, stacks) - stacks
	var most: int = CALLING_EXTRA_SMALL if status == EnemyStatuses.STATIC or status == EnemyStatuses.MARKED else maxi(2 * stacks, 2)
	return stacks + clampi(extra, 0, most)

# Setup credit 2026-10-16: card or evolution `rule`'s extra stacks inside a Warden's own application, as asked (the
# Warden's application counts them into the ledger's total; Charged's one-short clamp below is not taken off).
func _setup_part(enemy, rule_id: StringName, status: StringName, stacks: int) -> void:
	if stacks > 0:
		SETUP.note(enemy, card_id(rule_id), status, float(stacks))
		_status_pop(rule_id, enemy, status)  # C3: the stack card's extra shows on the badge (visual feedback spec)

# Narrows and Mixed Company: a Warden's own status hit adds more (never Rooted; Charged stops one short of a bolt).
func _stack_cards(tower, enemy, status: StringName, base: int) -> int:
	var extra := 0
	if rule(NARROWS) and now() >= float(tower.get_meta(NARROWS_META, -INF)) and _in_narrows(tower, enemy):
		tower.set_meta(NARROWS_META, now() + STACK_EVERY)
		extra += NARROWS_SMALL if status == EnemyStatuses.STATIC or status == EnemyStatuses.MARKED else NARROWS_EXTRA
		_setup_part(enemy, NARROWS, status, extra)  # (setup credit 2026-10-16: each card's extra stacks, as asked)
	var mixed_count := 0
	if rule(MIXED_COMPANY) and (_stackable(status) or status == DreamState.FROST) and now() >= float(tower.get_meta(MIXED_META, -INF)):
		mixed_count = _mixed(enemy)  # After the clock: strongest_near at most once a second per Warden
	if mixed_count > 0:
		tower.set_meta(MIXED_META, now() + STACK_EVERY)
		# Hard cards 2026-10-16: 1 more per status it carries, up to 4 (Charged / Exposed 2, Drowsy 1)
		var mixed_cap := MIXED_MAX
		if status == EnemyStatuses.STATIC or status == EnemyStatuses.MARKED or status == DreamState.FROST:  # Frost: small (section 37)
			mixed_cap = MIXED_SMALL_MAX
		elif status == EnemyStatuses.DROWSY:
			mixed_cap = MIXED_DROWSY_MAX
		extra += mini(mixed_count * MIXED_PER_STATUS, mixed_cap)
		_setup_part(enemy, MIXED_COMPANY, status, mini(mixed_count * MIXED_PER_STATUS, mixed_cap))
	var small: bool = status == EnemyStatuses.STATIC or status == EnemyStatuses.MARKED or status == DreamState.FROST  # Frost: small (section 37)
	# Breathe It In (trait rework; was spore-on-spore Poisoned): any Warden's status landing on a nightmare inside a spore
	# Warden's range (its own included) adds 1 more. Once a second per Warden
	if rule(BREATHE_IN) and _stackable(status) and now() >= float(tower.get_meta(BREATHE_META, -INF)) \
			and own_towers().any(func(t) -> bool: return t.global_position.distance_to(enemy.global_position) <= t.get_range_pixels()):
		tower.set_meta(BREATHE_META, now() + STACK_EVERY)
		var breathed: int = BREATHE_SLEEPER if (enemy.statuses.is_held() or enemy.statuses.is_asleep()) and status != EnemyStatuses.DROWSY else BREATHE_ONE
		extra += breathed
		_setup_part(enemy, BREATHE_IN, status, breathed)
	# Pass It Round (trait rework; was a Poisoned dose): a Warden touching a spore Warden (a spore Warden touches itself) adds
	# 3 more of its own status with its first application on each nightmare
	if rule(PASS_IT_ROUND) and _stackable(status) and (is_own(tower) or own_towers().any(func(t) -> bool: return touching(t, tower))):
		var passed: Dictionary = enemy.get_meta(PASS_META, {})
		if not passed.has(tower.get_instance_id()):
			passed[tower.get_instance_id()] = true
			enemy.set_meta(PASS_META, passed)
			extra += PASS_STACKS
			_setup_part(enemy, PASS_IT_ROUND, status, PASS_STACKS)
	# Sitting Ducks: any status hit on a held or sleeping nightmare near a spore Warden (never Drowsy: it would lengthen sleep)
	if rule(SITTING_DUCKS) and status != EnemyStatuses.DROWSY and now() >= float(tower.get_meta(DUCKS_META, -INF)) \
			and (enemy.statuses.is_held() or enemy.statuses.is_asleep()) and strongest_near(enemy.global_position, is_own) != null:
		tower.set_meta(DUCKS_META, now() + STACK_EVERY)
		extra += DUCKS_SMALL if small else DUCKS_EXTRA
		_setup_part(enemy, SITTING_DUCKS, status, DUCKS_SMALL if small else DUCKS_EXTRA)
	# Hemmed In: another family's Warden touching two spore Wardens doubles its status hits (Charged and Exposed once a second)
	if rule(HEMMED_IN) and status != EnemyStatuses.DROWSY and is_other_family(tower) \
			and (not small or now() >= float(tower.get_meta(HEMMED_META, -INF))) \
			and own_towers().filter(func(t) -> bool: return touching(t, tower)).size() >= HEMMED_SPORES:
		if small:
			tower.set_meta(HEMMED_META, now() + STACK_EVERY)
		extra += base
		_setup_part(enemy, HEMMED_IN, status, base)
	# Spore Ring: a spore Warden's Poisoned hit adds 1 more for each other spore Warden touching it, up to 3
	if rule(SPORE_RING) and is_own(tower) and status == EnemyStatuses.SPORED:
		var ringed: int = mini(own_towers().filter(func(t) -> bool: return t != tower and touching(t, tower)).size(), SPORE_RING_MAX)
		extra += ringed
		_setup_part(enemy, SPORE_RING, status, ringed)
	# Sporeling Support (Feeding Ground, Host Trees): their own slot, outside the lent cards' (Balancing 2026-10-23)
	extra += _support_stacks(tower, enemy, status, base)
	if extra <= 0:
		return base

	if status == EnemyStatuses.STATIC:
		var room: int = enemy.statuses.get_max_stacks(status) - 1 - enemy.statuses.stacks(status) - base
		extra = clampi(extra, 0, maxi(room, 0))
	return base + extra

# Narrows: the nightmare is touching a spore Warden and another kind of attacking Warden (Sprouts count; a second
# spore Warden does not).
func _in_narrows(_tower, enemy) -> bool:
	var at: Vector2 = enemy.global_position
	var spore := false
	var other := false
	for warden in towers():
		if not warden.tower_data.can_attack or not touches_point(warden, at):
			continue
		if is_own(warden):
			spore = true
		elif is_other(warden):
			other = true
	return spore and other

# Mixed Company (hard cards 2026-10-16): how many statuses it carries before the hit, any family's, any stacks (never
# Rooted); 0 when no spore Warden is near it.
func _mixed(enemy) -> int:
	var count := 0
	for id in enemy.statuses.active_ids():
		if id != EnemyStatuses.HELD:
			count += 1
	if count <= 0 or strongest_near(enemy.global_position, is_own) == null:
		return 0
	return count

# Settling Spores (rule id seeping_in; F7, owner 2026-10-18, lent_evolution_builds.md: it follows the walker, not the
# range): for SEEP_WINDOW steps after a spore Warden's plain hit, each status gains SEEP_STACKS every SEEP_STEPS steps,
# anywhere on the path. A new hit gives back the whole window (its progress toward the next 6 steps is kept). Counted
# forward only: a pull-back or push never counts twice. SEEP_META on a nightmare: [furthest route index counted, steps
# toward the next gain, steps left in the window].
const SEEP_WINDOW := 12.0

func _seep_start(enemy) -> void:
	var i := index_of(enemy)
	if i < 0:
		return  # Flyers walk no steps
	var seep: Array = enemy.get_meta(SEEP_META, [])
	if seep.size() < 3:
		seep = [i, 0.0, SEEP_WINDOW]
	else:
		seep = [maxi(int(seep[0]), i), float(seep[1]), SEEP_WINDOW]
	enemy.set_meta(SEEP_META, seep)

func _seep(enemy) -> void:
	if not enemy.has_meta(SEEP_META):
		return
	var seep: Array = enemy.get_meta(SEEP_META)
	if seep.size() < 3:
		enemy.remove_meta(SEEP_META)  # (An older [index, steps] record: in range only)
		return
	var i := index_of(enemy)
	if i <= int(seep[0]):
		return
	var walked := minf((i - int(seep[0])) * 0.5, float(seep[2]))
	var left: float = float(seep[2]) - walked
	var steps: float = float(seep[1]) + walked
	while steps >= SEEP_STEPS:
		steps -= SEEP_STEPS
		for id in enemy.statuses.active_ids():
			if id != EnemyStatuses.HELD and id != DreamState.FROST:
				setup_quiet(enemy, SEEPING_IN, id, enemy.statuses.add_quiet(id, SEEP_STACKS))  # (setup credit 2026-10-16)
	if left <= 0.0:
		enemy.remove_meta(SEEP_META)
	else:
		enemy.set_meta(SEEP_META, [i, steps, left])

func _carries_other(enemy) -> bool:
	var statuses: EnemyStatuses = enemy.statuses
	for id in statuses.active_ids():
		if id != EnemyStatuses.SPORED and id != EnemyStatuses.HELD and is_other_family(statuses.source(id)):
			return true
	return false

# --- Save (mushrooms survive rests) -----------------------------------------------------------------------------------

func to_save() -> Array:
	var out: Array = []
	for point in mushrooms:
		var m: Dictionary = mushrooms[point]
		out.append([point.x, point.y, int(m.caps), bool(m.grown), bool(m.get("seeded", false)), int(m.get("most", 1)), m.get("mother", []),
			_gen_of(m), bool(m.get("crop", false))])  # gen (2026-10-23): a loaded planted mushroom never plants again
	return out

func _load_saved() -> void:
	var rows := saved
	saved = []
	for row in rows:
		if not (row is Array) or row.size() < 2:
			continue
		var point := Vector2(float(row[0]), float(row[1]))
		_grow(point, bool(row[3]) if row.size() > 3 else false)
		if mushrooms.has(point) and row.size() > 2:
			mushrooms[point].caps = clampi(int(row[2]), 1, maxi(TWIN_CAPS, CLUMP_MAX))
		if mushrooms.has(point) and row.size() > 6:  # Calling evolutions (2026-10-16)
			mushrooms[point].seeded = bool(row[4])
			mushrooms[point].most = int(row[5])
			mushrooms[point].mother = Array(row[6])
			mushrooms[point].gen = int(row[7]) if row.size() > 7 else (GEN_PLANTED if bool(row[4]) else GEN_FELL)
		if mushrooms.has(point) and row.size() > 8:
			mushrooms[point].crop = bool(row[8])

# --- Drawing: mushrooms are objects you can count, never a tint on the path -------------------------------------------

# Each mushroom stands in the map's y-sort (owner 2026-10-22: "make sure all the assets make sense like the ink should
# be on the ground, therefore below the mushroom"; and a mushroom further down the path had the one above's stem drawn
# over it). They were all drawn by this node at z -1 with the ground, so ground marks added later (Inkcap's ink, wet
# trails, whirlpools: z -1 too) landed on top of them. Now each one is a small Stand on a y-sorted layer in the
# MapGenerator (with the trees, rocks, Wardens and nightmares), its origin on its foot: everything flat on the ground
# stays under it, and whatever is lower on screen (a Warden, a nightmare, another mushroom) draws in front. This node's
# own _draw only has the stands catch up (deferred: never changes the tree while drawing).
var _layer: Node2D = null  # The y-sorted "Mushrooms" layer in the MapGenerator
var _stands := {}  # Route point -> its Stand

func _draw() -> void:
	_sync_stands.call_deferred()
	# Spore Season: a low spore haze on every route point while it is lit (sp_season_haze, every other tile flipped so the
	# trail doesn't repeat; on the ground, under the nightmares). No drawn stand-in: the badge already says it is lit.
	if _haze_shown and place_on():
		for k in _route_px.size():
			evo_mark(self, ART_HAZE, _route_px[k], 1.0, k % 2 == 1)
	for fleck in _flecks:  # One-shot marks (Host Trees' spore fleck), over the haze, whatever else is on
		evo_mark(self, fleck[0], fleck[1], 1.0, bool(fleck[3]), evo_art_frame(evo_art, fleck[0], float(fleck[2])))
	if not place_on() or _route_px.is_empty():
		return
	# Feeding Ground: fed ground glows green on the path and fades as its 8 s run out (flat on the ground, under the caps)
	# (sp_fed_ground on each fed point, every other one flipped, alpha = the time left; the soft dot without the sheet)
	for stretch in _fed:
		var left := clampf((float(stretch[2]) - now()) / FEED_SECONDS, 0.0, 1.0)
		for k in range(int(stretch[0]), mini(int(stretch[1]), _route_px.size() - 1) + 1):
			if not evo_mark(self, ART_FED, _route_px[k], left, k % 2 == 1):
				draw_circle(_route_px[k], FED_RADIUS, Color(Palette.SPRIG, FED_ALPHA * left))
	# Rot Ground: a dark rot ring on each Sprout bed's step that never goes out (sp_rot_ring; the drawn ring without it)
	if evo(EVO_ROT_GROUND):
		for point in _fairy:
			if _index.has(point):
				var at: Vector2 = _route_px[int(_index[point])]
				if not evo_mark(self, ART_ROT, at):
					draw_arc(at, ROT_RING_RADIUS, 0.0, TAU, 16, Color(Palette.DEEPMOSS, 0.8), 2.0)
	# Host Grove: spore threads join the capped Wardens while 3 or more wear caps
	if evo(EVO_HOST_GROVE) and capped_count() >= HOST_GROVE_AT:
		var feet: Array = []
		for id in _capped:
			var tower = _capped[id][0].get_ref()
			if is_capped(tower):
				feet.append(to_local(tower.global_position))
		for a in feet.size():
			var best := -1
			for b in feet.size():
				if b != a and (best < 0 or feet[a].distance_squared_to(feet[b]) < feet[a].distance_squared_to(feet[best])):
					best = b
			if best >= 0:
				draw_line(feet[a], feet[best], Color(Palette.SPRIG, 0.5), 1.0)

const FED_RADIUS := 7.0  # Fed ground: a soft green dot on each route point…
const FED_ALPHA := 0.28  # …this strong when fresh
const ROT_RING_RADIUS := 9.0
# Calling evolution marks (assets/effects/calling_evo/, class_kit.evo_mark); each falls back to the drawn shape
const ART_FED := &"sp_fed_ground"
const ART_ROT := &"sp_rot_ring"
const ART_THRONE := &"sp_throne_rim"
var _art_stamp := -1  # The ground marks' frames last drawn (redraw only when they change)
const ART_HAZE := &"sp_season_haze"
const ART_FLECK := &"sp_spore_fleck"
const ART_ROT_BLOOM := &"sp_rot_bloom"  # Rot Bloom's 3rd burst: a rot flower opening on the ground (one shot, in _flecks)
const FLECK_EVERY := 0.25  # Host Trees' fleck: at most this often per capped Warden (ticks come fast)
const FLECKS_MAX := 32
var _haze_shown := false
var _haze_frame := -1
var _flecks: Array = []  # One-shot marks: [mark, local point, age, flip]

# Host Trees: a pink spore fleck where a capped Warden of another family's tick or hit lands (sp_spore_fleck, one shot).
func _host_fleck(source, enemy) -> void:
	if not is_capped(source) or is_own(source) or not is_instance_valid(enemy) or _flecks.size() >= FLECKS_MAX \
			or now() < float(source.get_meta(FLECK_META, -INF)):
		return
	source.set_meta(FLECK_META, now() + FLECK_EVERY)
	_flecks.append([ART_FLECK, to_local(enemy.global_position), 0.0, false])
	queue_redraw()
const FLECK_META := &"sp_fleck_next"  # On a Warden: when it may fleck again

# Ages the one-shots; each ends after its sheet's frames (fps from calling_evo.json); redraws only on a frame change.
func _age_flecks(delta: float) -> void:
	var changed := false
	for i in range(_flecks.size() - 1, -1, -1):
		var fleck: Array = _flecks[i]
		var meta := evo_art_meta(evo_art, fleck[0])
		var length := float(maxi(int(meta.get("frames", 1)), 1)) / maxf(float(meta.get("fps", 12.0)), 1.0)
		var before := evo_art_frame(evo_art, fleck[0], float(fleck[2]))
		fleck[2] = float(fleck[2]) + delta
		if float(fleck[2]) >= length:
			_flecks.remove_at(i)
			changed = true
		elif evo_art_frame(evo_art, fleck[0], float(fleck[2])) != before:
			changed = true
	if changed:
		queue_redraw()

func _exit_tree() -> void:
	if is_instance_valid(_layer):
		_layer.queue_free()  # It lives in the map, not under this node
	_layer = null
	_stands.clear()
	_badges.clear()

func _sync_stands() -> void:
	if not is_inside_tree():
		return
	if not place_on():
		if is_instance_valid(_layer):
			_layer.visible = false
		return
	if not is_instance_valid(_layer):
		var map = dream_state.get("map_generator") if dream_state != null else null
		if map == null or not is_instance_valid(map) or not map is Node2D:
			return  # A bare DreamState (tools, some tests): no map to stand in
		_layer = Node2D.new()
		_layer.name = "Mushrooms"
		_layer.y_sort_enabled = true
		map.add_child(_layer)
		_stands.clear()
		_badges.clear()
	_layer.visible = is_visible_in_tree()
	var want := {}  # Route point -> regrowing
	for point in mushrooms:
		if _index.has(point):
			want[point] = false
	for point in _regrow:
		if _index.has(point) and not mushrooms.has(point):
			want[point] = true
	for point in _stands.keys():
		if not want.has(point) or not is_instance_valid(_stands[point]):
			if is_instance_valid(_stands[point]):
				_stands[point].queue_free()
			_stands.erase(point)
	for point in want:
		var stand: Stand = _stands.get(point)
		if stand == null:
			stand = Stand.new(self, point)
			_layer.add_child(stand)
			_stands[point] = stand
		stand.regrowing = bool(want[point])
		stand.global_position = to_global(_spot(point)[0])
		stand.queue_redraw()
	# Host Trees: a little cap on each capped Warden, fading in its last seconds (in the y-sort, just in front of it)
	var worn := {}
	for id in _capped:
		var tower = _capped[id][0].get_ref()
		if is_capped(tower):
			worn[id] = tower
	for id in _badges.keys():
		if not worn.has(id) or not is_instance_valid(_badges[id]):
			if is_instance_valid(_badges[id]):
				_badges[id].queue_free()
			_badges.erase(id)
	var glowing := evo(EVO_HOST_GROVE) and worn.size() >= HOST_GROVE_AT
	for id in worn:
		var badge: CapBadge = _badges.get(id)
		if badge == null:
			badge = CapBadge.new()
			badge.art = self
			_layer.add_child(badge)
			_badges[id] = badge
		var until := float(_capped[id][1])
		badge.alpha = 1.0 if until == INF else clampf((until - now()) / HOST_LINGER, BADGE_MIN_ALPHA, 1.0)
		badge.glow = glowing
		badge.passed = bool(_capped[id][2])
		badge.global_position = worn[id].global_position + BADGE_OFFSET
		badge.queue_redraw()

var _badges := {}  # Warden instance id -> its CapBadge
const BADGE_OFFSET := Vector2(14.0, 2.0)  # By the Warden's foot, a touch lower so it sorts in front of it
const BADGE_MIN_ALPHA := 0.25
const THRONE_RIM := 11.0

# Host Trees' cap on a Warden: a tiny palette toadstool (Spreading Caps' passed ones paler); Host Grove makes them glow.
class CapBadge extends Node2D:
	var alpha := 1.0
	var glow := false
	var passed := false
	var art = null  # The SporePrint node: its evo_mark draws sp_cap_badge (frame 0 its own cap, 1 a passed-on one)
	func _init() -> void:
		name = "CapBadge"
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	func _draw() -> void:
		if glow:
			draw_circle(Vector2(0.0, -4.0), 6.0, Color(Palette.SPRIG, 0.35 * alpha))
		if is_instance_valid(art) and art.evo_mark(self, &"sp_cap_badge", Vector2.ZERO, alpha, false, 1 if passed else 0):
			return  # The stem's foot on the badge's origin, where the drawn cap stands
		draw_rect(Rect2(-1.0, -3.0, 2.0, 3.0), Color(Palette.DEADWOOD, alpha))  # The stem
		draw_circle(Vector2(0.0, -4.0), 3.0, Color(Palette.BLOSSOM if not passed else Palette.MIST, alpha))  # The cap

# One mushroom (or a regrowing sprout), drawn by its Stand with the foot at the Stand's origin.
func _draw_stand(c: CanvasItem, point: Vector2, regrowing: bool) -> void:
	if regrowing:  # A small, faint one where a mushroom is growing back
		_draw_mushroom(c, Vector2.ZERO, _sheet("spore_mushroom_small"), 0.5, false)
		return
	if not mushrooms.has(point):
		return
	var caps := int(mushrooms[point].caps) + int(_held_caps.get(point, 0))  # Eaten caps still on their way (HeldCap)
	if season_on():
		c.draw_circle(Vector2(0.0, -6.0), 9.0, Color(Palette.MOSS, 0.35))  # Spore Season: the mushrooms glow
	var m: Dictionary = mushrooms[point]
	if now() < float(m.get(HEAVY_GLOW, -INF)):  # Heavy Air: a full-haze nightmare on it; the cap glows instead of going
		c.draw_circle(Vector2(0.0, -8.0), 11.0, Color(Palette.GLOW, 0.4))
	if bool(m.get("throne", false)):  # Toadstool Throne: a gold rim under the toadstool that never goes away (sp_throne_rim)
		if not evo_mark(c, ART_THRONE, Vector2.ZERO):
			c.draw_arc(Vector2(0.0, -2.0), THRONE_RIM, 0.0, TAU, 20, Color(Palette.GOLD, 0.9), 1.5)
	_draw_caps(c, point, m, caps)

# A mushroom's look (by its evolution and caps), its foot at the canvas origin: the stand's, and a HeldCap's last cap.
func _draw_caps(c: CanvasItem, point: Vector2, m: Dictionary, caps: int) -> void:
	var phase := int(point.x * 2.0 + point.y * 2.0)
	var flip := int(point.x * 2.0) % 2 == 1
	var mother: Array = m.get("mother", [])
	if not mother.is_empty():  # Mother Spore: its cap, the speckles in the stored statuses' colours (one a frame)
		_draw_mushroom(c, Vector2.ZERO, _sheet("spore_mushroom_mother"), 1.0, flip, phase)
		var status: StringName = mother[(maxi(_breathe_frame, 0) + phase) % mother.size()][0]
		_draw_mushroom(c, Vector2.ZERO, _sheet("spore_mushroom_mother_specks"), 1.0, flip, phase,
			EnemyStatuses.COLORS.get(status, Palette.HEARTLIGHT))
	elif bool(m.get("seeded", false)):  # Windblown's planted ones: a thin seedling (they don't plant again)
		_draw_mushroom(c, Vector2.ZERO, _sheet("spore_mushroom_seedling"), 1.0, flip, phase)
	elif caps >= 2:  # A clump: 2-4 caps grown together in one stack, one fewer per bite
		_draw_mushroom(c, Vector2.ZERO, _sheet("spore_mushroom_clump_%d" % mini(caps, 4)), 1.0, flip, phase)
	elif evo(EVO_STICKY):  # Sticky Caps: a drooping, dripping cap (it slows walkers)
		_draw_mushroom(c, Vector2.ZERO, _sheet("spore_mushroom_sticky"), 1.0, flip, phase)
	elif bool(m.get("crop", false)):  # Second Crop's: a pale cap
		_draw_mushroom(c, Vector2.ZERO, _sheet("spore_mushroom"), CROP_ALPHA, flip, phase)
	else:
		_draw_mushroom(c, Vector2.ZERO, _sheet("spore_mushroom"), 1.0, flip, phase)

# An eaten cap waits for the feet (Roguelite asset chat, owner 2026-10-23): the step and its dose count from the route
# point, but the cap is drawn at _spot (up to half a cell away), so it vanished and popped before the nightmare got there.
# Now it stays drawn (a clump keeps its count in _held_caps; a last cap is drawn by its HeldCap) and pops on its foot,
# in the mushrooms' y-sort, once the stepper's feet are within HOLD_REACH px, start to walk away, or HOLD_MAX s pass.
# Gone or dead first, or reduced motion: at once.
const HOLD_REACH := 4.0
const HOLD_MAX := 0.25
var _held_caps := {}  # Route point -> eaten caps of a clump still drawn

func _hold_pop(point: Vector2, m: Dictionary, enemy) -> void:
	var at := to_global(_spot(point)[0])
	var parent: Node = _layer if is_instance_valid(_layer) else self
	var last := int(m.caps) <= 1
	if motion_still() or not living(enemy):
		_pop_at(at, parent)
		return
	if not last:
		_held_caps[point] = int(_held_caps.get(point, 0)) + 1
	var held := HeldCap.new(self, point, m.duplicate() if last else {}, enemy, at)
	parent.add_child(held)

func _release_held(point: Vector2, clump: bool, at: Vector2, parent: Node) -> void:
	if clump and _held_caps.has(point):
		_held_caps[point] = int(_held_caps[point]) - 1
		if int(_held_caps[point]) <= 0:
			_held_caps.erase(point)
		var stand = _stands.get(point)
		if is_instance_valid(stand):
			stand.queue_redraw()
	_pop_at(at, parent)

func _pop_at(at: Vector2, parent: Node) -> void:
	var pop := Fx.play(MUSHROOM_POP, at, parent, 1.0)
	if pop != null:
		pop.z_index = 0

class HeldCap extends Node2D:
	var _print
	var _point: Vector2
	var _look: Dictionary  # A last cap's mushroom (drawn here); empty for a clump's (the stand draws it)
	var _enemy: WeakRef
	var _left := HOLD_MAX
	var _gap := INF

	func _init(print_node, point: Vector2, look: Dictionary, enemy: Node2D, at: Vector2) -> void:
		_print = print_node
		_point = point
		_look = look
		_enemy = weakref(enemy)
		name = "HeldCap"
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		global_position = at

	func _process(delta: float) -> void:
		var enemy = _enemy.get_ref()
		_left -= delta
		var gap: float = global_position.distance_to(enemy.global_position) if is_instance_valid(enemy) else INF
		if _left <= 0.0 or not is_instance_valid(_print) or not _print.living(enemy) or gap <= HOLD_REACH or gap > _gap + 0.01:
			if is_instance_valid(_print):
				_print._release_held(_point, _look.is_empty(), global_position, get_parent())
			queue_free()
			return
		_gap = gap

	func _draw() -> void:
		if not _look.is_empty() and is_instance_valid(_print):
			_print._draw_caps(self, _point, _look, 1)

class Stand extends Node2D:
	var regrowing := false
	var _print
	var _point: Vector2
	func _init(print_node, point: Vector2) -> void:
		_print = print_node
		_point = point
		name = "Mushroom"
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # 1x crisp pixels
	func _draw() -> void:
		if is_instance_valid(_print):
			_print._draw_stand(self, _point, regrowing)

# Where a mushroom on route point `point` is DRAWN (the gameplay point stays the route point: touches, doses, owner,
# saves). The drawn path is a ribbon about 40 px wide along the route's points, not the whole corridor between the
# Wardens (the corridor centring of 2026-10-15 pushed mushrooms off it), so the spot is the ribbon's middle there
# (PathGenerator.ribbon_centre: a bend's is pulled into the turn), then the foot moves down (and at a bend in) until the
# whole cap fits inside the ribbon (fit_on_ribbon; a cap on the top edge of a stretch would stick out otherwise). [px, along],
# `along` the route's direction (Twin Caps line up on it). Worked out for every route point in on_board (when the board
# or the route changes), never per frame.
const SPOT_ART_SIZE := Vector2(22.0, 25.0)  # The largest cap's visible width and height above its foot (clump_4)
var _spots := {}

func _spot(point: Vector2) -> Array:
	if not _spots.has(point):
		_spots[point] = _work_out_spot(int(_index[point]))
	return _spots[point]

func _work_out_spot(i: int) -> Array:
	var at: Vector2 = _route_px[i]
	var along: Vector2 = (_route_px[mini(i + 1, _route_px.size() - 1)] - _route_px[maxi(i - 1, 0)]).normalized()
	if along == Vector2.ZERO:
		along = Vector2.RIGHT
	var path := PathGenerator.find(self)
	if path == null:
		return [at, along]
	var at_global := to_global(at)
	# A straight keeps the middle line: only a horizontal stretch moves the foot down so the cap fits (user screenshot
	# 2026-10-22 19:44: mushrooms on the path's edges in one-cell corridors)
	var straight := path.ribbon_axis(at_global) != Vector2.ZERO
	return [to_local(path.fit_on_ribbon(path.ribbon_centre(at_global), SPOT_ART_SIZE, straight)), along]

# The mushroom art (Tower Assets eaed6c74, owner 2026-10-18: "change the mushroom to a new asset"): its own breathing
# toadstool, drawn at 1x (crisp pixels) with the stem's foot on the drawn spot; size by clump (one or two caps: normal;
# three or four: normal and small mixed; a regrowing sprout: small at half alpha). Eaten caps pop (MUSHROOM_POP).
# The plain shape is only the fallback when a sheet is missing.
# Evolved looks (Tower Assets a945dd0e, owner 2026-10-18: "different mushrooms where an evolution makes them look
# different"): clumps of 2-4 in one stack, Windblown's seedlings, Mother Spore's cap + tintable speckles, Sticky Caps.
const MUSHROOM_DIR := "res://assets/effects/%s.png"  # Each sheet: square frames side by side, MUSHROOM_FRAMES of them
const MUSHROOM_POP := &"spore_mushroom_pop"  # effects.json one-shot: the cap bursts, a stub stays
const MUSHROOM_FRAMES := 4
const MUSHROOM_FPS := 4.0  # The slow breathe
var _sheets := {}  # Sheet name -> Texture2D (null when missing), per node, never static
var _breathe_frame := -1  # The breathe frame last drawn (redraw only when it changes)

func _sheet(sheet: String) -> Texture2D:
	if not _sheets.has(sheet):
		var path := MUSHROOM_DIR % sheet
		_sheets[sheet] = load(path) if ResourceLoader.exists(path) else null
	return _sheets[sheet]

func _draw_mushroom(c: CanvasItem, at: Vector2, tex: Texture2D, alpha: float, flip: bool, phase: int = 0, tint: Color = Color(1, 1, 1)) -> void:
	if tex == null:
		tex = _sheet("spore_mushroom")
	if tex == null:
		c.draw_circle(at + Vector2(0.0, -4.0), 5.0, Color(Palette.BLOSSOM, alpha))
		return
	var w: float = tex.get_width() / float(MUSHROOM_FRAMES)
	var h: float = tex.get_height()
	var frame := (maxi(_breathe_frame, 0) + phase) % MUSHROOM_FRAMES
	var rect := Rect2((at - Vector2(w / 2.0, h - 2.0)).round(), Vector2(w, h))  # The stem's foot at (w/2, h-2) on the spot, 1x
	if flip:
		rect = Rect2(rect.position, Vector2(-w, h))  # A negative width mirrors the art in place (Godot keeps the left edge)
	c.draw_texture_rect_region(tex, rect, Rect2(w * frame, 0.0, w, h), Color(tint, alpha))  # multiplier
