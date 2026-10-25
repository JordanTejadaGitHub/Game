extends "res://scripts/combat/class_kit.gd"
# The Dewdrop class (dream_council_review.md 20 "Dewdrop: water on the path", rulings in 21).
# Calling, Puddles: the path touching your Dewdrops is water. A Dewdrop's hit there ripples: nightmares within 4
# steps in that water are Soaked. (Dewdrops already hit Soaked nightmares harder: the built Soaked rule.)
# A water is one unbroken run of wet route points; it knows its Dewdrops, its bank (other attacking Wardens touching
# it) and its length in steps. A Dewdrop is lone while no other attacking Warden touches any of its waters.
# Water is the first pick's only (place_on, 2026-10-14); the 5 class cards use it. The 10 lent cards never do: they use
# "near a Dewdrop" (2 cells), "a Dewdrop's range" and Soaked, for any Dewdrop owner.
# Every number is a paper starting value.

const GROUP := &"puddles"
const FAMILY := "dewdrop"
const LINE := "water"

const RIPPLE_STEPS := 4  # The ripple, Swell and Wake Ripple run this many steps each way in the water
const RIPPLE_EVERY := 1.0  # …and Soak each nightmare at most once a second
const LEVEE_WALLS := 2  # Levee: a row of up to this many walls between two Dewdrops
const BACKWASH_DEWDROPS := 4
const BREAKWATER_STEPS := 14.0  # Breakwater: water this long or longer…
const BREAKWATER_SECONDS := 3.0  # …this many seconds of the strongest Dewdrop's damage
const BOTH_BANKS_SHARE := 0.5
const RIPTIDE_SECONDS := 2.0  # Pulled under this long…
const RIPTIDE_SLOW := 0.5  # …walking this much slower…
const RIPTIDE_DAMAGE_SECONDS := 3.0  # …taking this many seconds of that Dewdrop's damage over it
const RIPTIDE_TICK := 0.5
const CAUGHT_WARDENS := 3  # Caught Wading
const WASH_AWAY_SHELL := 2.0  # Wash Away: a Soaked nightmare's shell takes this much damage from Wardens near a Dewdrop
const SWELL_SHARE := 0.5
const ACROSS_STEPS := 3  # Across the Water: this many steps further along the water…
const ACROSS_CELLS := 5.0  # …never more than this far from the Warden
const REMEMBERS_SECONDS := 3.0  # The Water Remembers: a status that had ended comes back this long
const SOMETHING_STATUSES := 2  # Something in the Water: at most this many statuses, 1 stack each, once a second per Dewdrop
const SOAKED_THROUGH_WARDENS := 4

# Card rule ids
const LEVEE := &"levee"
const BACKWASH := &"backwash"
const BREAKWATER := &"breakwater"
const THERE_AND_BACK := &"there_and_back"
const BOTH_BANKS := &"both_banks"
const RIPTIDE := &"riptide"
const CAUGHT_WADING := &"caught_wading"
const WAKE_RIPPLE := &"class_wake_ripple"  # (Retired from offers 2026-10-13: Deep Pool took its slot)
const DEEP_POOL := &"deep_pool"
const DEEP_POOL_PER_STATUS := 0.10  # Deep Pool: hits from Wardens touching water deal this much more per status besides Soaked
const RIP_META := &"pd_rip"  # On a nightmare: {until, done: {Warden id: true}} (Riptide: the bank's first hits land double)
const WASH_AWAY := &"wash_away"
const SWELL := &"swell"
const ACROSS := &"across_the_water"
const REMEMBERS := &"the_water_remembers"
const SOMETHING := &"something_in_the_water"  # Lent
const SOAKED_THROUGH := &"lent_soaked_through"  # Lent
const RUN_OFF := &"run_off"  # Lent

# Lent and class, 2026-10-14 (lent_noplace_dewdrop_bellflower.md, expand_dewdrop_bellflower.md, dream_council_review.md 26)
const SHALLOWS := &"shallows"
const SHALLOWS_EVERY := 1.0  # Shallows: each other Warden touching a Dewdrop adds 1 Soaked with a hit, once a second
const KNEE_DEEP := &"knee_deep"
const KNEE_SLOW := 0.1  # Knee-Deep: a Soaked nightmare in a Dewdrop's range walks this much slower…
const KNEE_SLOW_FULL := 0.2  # …this much when fully Soaked…
const KNEE_TIME := 0.25  # …re-applied each poll, so it ends soon after it leaves or dries
const ACROSS_EXTRA_CELLS := 1.0  # Across the Water: Wardens near a Dewdrop reach Soaked nightmares this far past their range
const RETURN_STEPS := 3  # Walking back into a Dewdrop's range: at least this many route steps past where it left (pulls don't count)
const WATERLOGGED := &"waterlogged"
const WATERLOGGED_FACTOR := 1.5  # Waterlogged: other families' statuses on a Soaked nightmare last this much longer (never Drowsy)
const HEAVY_GOING := &"heavy_going"  # Lent (non-status builds, owner 2026-10-19; replaces Slow to Dry in offers): hits on slowed nightmares
const HEAVY_GOING_BONUS := 1.25  # Dewdrops and Wardens near them deal this much more to a nightmare walking slowed (not by Sleep)
const HEAVY_TRAIL_EVERY := 0.6  # A slowed nightmare it counts on drips: a small splash this often at most
const HEAVY_META := &"pd_heavy_fx"
const SOAKED_BONE := &"soaked_to_the_bone"  # Class: walking back into a lone Dewdrop's water fills Soaked at once
const RANGE_META := &"pd_range"  # On a nightmare: {Dewdrop key: [inside: bool, exit route index]}
const SHALLOWS_META := &"pd_shallows_next"  # On a Warden

# Statuses linger (owner 2026-10-15, trait_lent_proposal.js): the lent cards carry Dewdrop's trait to every family.
# Everything that adds time after a landing goes through EnemyStatuses.linger (all together at most LINGER_MAX past the
# last landing; Charged LINGER_MAX_STATIC). Never Rooted or Drowsy (EnemyStatuses.can_linger).
const STEEPED := &"steeped"
const STEEPED_SHARE := 0.4  # Steeped: statuses from Wardens touching a Dewdrop (a Dewdrop touches itself), or landing inside two Dewdrops' ranges, last 40% longer (card pass 2026-10-16: absorbs Pooling and Dripping)
const TOPPED_UP := &"topped_up"
const TOPPED_UP_EVERY := 1.0  # Topped Up: a Dewdrop's hit resets every status's time, once a second per nightmare
const TOPPED_META := &"pd_topped_next"  # On a nightmare
const DRIPPING := &"dripping"
const DRIPPING_SECONDS := 2.0  # Dripping: leaving a Dewdrop's range, every status keeps this much longer
const EBB := &"ebb"
const EBB_SECONDS := 3.0  # Ebb: a status running out in a Dewdrop's range comes back at half its most stacks for this long
const EBB_META := &"pd_ebb"  # On a nightmare: true once its ran-out signal is hooked
const POOLING := &"pooling"
const POOLING_SHARE := 0.5  # Pooling: in two Dewdrops' ranges at once, statuses landing last 50% longer
const HIGH_TIDE := &"high_tide"
const HIGH_TIDE_SHARE := 0.75  # (Unused since keyword chips 2026-10-16: every status counts now)
const HIGH_TIDE_PER := 0.10  # High Tide: each status on the nightmare adds 10% to hits from Wardens near a Dewdrop…
const HIGH_TIDE_MAX := 0.30  # …up to +30% (keyword chips 2026-10-16, TD: was +40% with only fresh statuses)
const OLD_RAIN := &"old_rain"
const OLD_RAIN_AGE := 4.0  # (Unused since keyword chips 2026-10-16: Old Rain reads EnemyStatuses.is_lingering, not age)
const OLD_RAIN_BONUS := 1.4  # …deals 40% more (its burst; damage over time after it is unchanged)
const NEVER_DRY := &"never_quite_dry"
const NEVER_DRY_EVERY := 3.0  # Never Quite Dry: a Reaction near a Dewdrop leaves the statuses it spent at half, once per nightmare in 3 s
const NEVER_DRY_META := &"pd_never_dry_next"  # On a nightmare
# Dewdrop helping itself (owner 2026-10-18; D:\Projects\logs\dream_council\dewdrop_self.md): three lent cards that pay
# Dewdrop Wardens and Wardens near them (2 cells; a Dewdrop is near itself: dewdrop_near), so they still give every family
# the trait. Wash Away is the revived id (WASH_AWAY above; shell_multiplier).
const SODDEN := &"sodden"
const SODDEN_PER := 0.10  # Sodden: hits deal this much more for each whole second the nightmare's Soaked has lasted…
const SODDEN_MAX := 0.40  # …up to this much (EnemyStatuses.age(DAMP): it resets only when Soaked runs out)
const SODDEN_META := &"pd_sodden_full"  # On a nightmare: true once its count reached the cap (the one status pop)
const LAST_DROP := &"last_drop"
const LAST_DROP_TAG := &"last_drop"  # A class tag (never sets a card off). Potency is applied here (_last_drop): Reactions.EFFECT_TAGS is not ours to edit
const LAST_DROP_SHARE := 0.4  # Last Drop: Soaked running out deals this share of the adder's hit for each stack it had…
const LAST_DROP_HITS := 3.0  # …up to this many hits
const LAST_DROP_EVERY := 6.0  # Each nightmare once in this long (covers Ebb bringing Soaked back to run out again)
const LAST_DROP_META := &"pd_last_drop_next"  # On a nightmare
const WASH_FX_EVERY := 1.0  # Wash Away's credit and puff: once a second per nightmare
const WASH_FX_META := &"pd_wash_fx"  # On a nightmare
var _old_rain := false  # True while a boosted Reaction check runs (damage_multiplier reads it)
var _rain_ids: Array = []  # Old Rain: the lingering statuses on the nightmare that check runs for (keyword chips 2026-10-16)

# Old Rain (keyword chips 2026-10-16): the statuses on `statuses` that a card is making last longer.
func _lingering_ids(statuses: EnemyStatuses) -> Array:
	var out: Array = []
	for id in statuses.active_ids():
		if statuses.is_lingering(id):
			out.append(id)
	return out

# Whether Reaction burst `tag` spends one of `ids` (its base Reaction's statuses; a tag without data: any of them).
func _rain_spends(tag: StringName, ids: Array) -> bool:
	if ids.is_empty():
		return false
	var data: ReactionData = Reactions.get_data(Reactions.CROWNED_BASE.get(tag, tag))
	if data == null:
		return true
	for id in ids:
		if data.statuses.has(id) or data.alternatives.has(id):
			return true
	return false
const WATER_META := &"pd_water"  # On a nightmare: the water it stands in (-1 none)
const SEEN_META := &"pd_seen"  # On a nightmare: {Dewdrop cell key: true}: it has walked this Dewdrop's water
const LEFT_META := &"pd_left"  # On a nightmare: {Dewdrop id: {status: [stacks, potency, line, WeakRef]}} (The Water Remembers)
const ONCE_META := &"pd_once"  # On a nightmare: {"card:key": true}
const RIPPLE_META := &"pd_ripple"  # On a nightmare: when the ripple may Soak it again
const CARRY_META := &"pd_carry"  # On a nightmare: when a carried stack may reach it again (Wake Ripple)
const SOMETHING_META := &"pd_something"  # On a Dewdrop: when it may add again

var waters: Array = []  # [{id, first, last, points: {index: true}, dewdrops: Array, bank: Array, steps: float}]
var _water_at := {}  # Route index -> index into `waters`
var _lone := {}  # Dewdrop instance id -> true
var _waters_of := {}  # Warden instance id -> Array of indices into `waters` (Dewdrops and bank Wardens)
var _across := {}  # Warden instance id -> {route index: true}: where it reaches along the water (unused since 2026-10-14)
var _near_dew := {}  # Warden instance id -> the strongest Dewdrop near it, or null (cleared with the board)
var _riptides: Array = []  # [{enemy: WeakRef, tower: WeakRef, amount, ticks, wait}]
var ripples := 0  # This run (tests and the owner's eye)

# --- Calling evolutions (scripts/combat/calling_paths.gd; council calling_evolution_*.md, owner 2026-10-16) -----------
# Read with evo(id) (implies the Calling). Every number is a paper starting value (Balancing). Each one shows itself (a
# flash along the water, a thread, a splash, the drawn current / pond / footprints) and credits its id (credit()).
# Pulls never move bosses or flyers; Holds are halved on bosses; flyers are never in water (index_of is -1 for them).
const EVO_STREAM := &"dw_stream"  # Spread
const FLOW_STEPS := 4  # Stream: water flows this many steps past each water's downstream end (joining a water it reaches)
const EVO_MILLRACE := &"dw_millrace"
const MILL_STATUSES := 3  # Millrace: a ripple carries up to this many of the hit nightmare's other statuses…
const MILL_STACKS := 1  # …this many stacks each, to every nightmare it soaks (never Soaked, Drowsy or Held)
const EVO_FLOOD := &"dw_flood"
const FLOOD_STEPS := 24  # Flood: a ripple runs its whole water, at most this many steps each way
const EVO_LAPPING := &"dw_lapping_water"
const LAP_STEPS := 2  # Lapping Water: a bank Warden's hit on a Soaked nightmare in its water ripples this many steps…
const LAP_EVERY := 1.0  # …once a second per Warden
const LAP_META := &"pd_lap_next"  # On a Warden
const EVO_SPRING := &"dw_spring_flood"
const SPRING_EVERY := 10.0  # Spring Flood: drift time between floods (paused at rests)…
const SPRING_MAX := 8  # …up to this many nightmares in the longest water with one in it…
const SPRING_SLOW := 0.25  # …fully Soaked and this much slower (bosses half)…
const SPRING_SECONDS := 2.0  # …for this long
const EVO_POND := &"dw_black_pond"  # Focus
const POND_DEWDROPS := 2  # (Unused since 2026-10-23: the pond is the highest-rank Dewdrop's water, _refresh_pond)
const POND_STEPS := 8  # (Unused since 2026-10-18)
const POND_TIME := 0.25  # (Unused since 2026-10-23: the pond's slow is gone; the Calling slow is class_kit.calling_slow)

# --- Calling evolutions rebuilt 2026-10-23 (owner, dream_council_review.md 33; evo_fixed_dewdrop.md, evo_shared_spec.md) ---
# Spread: the one capped Calling slow (class_kit.calling_slow, once per nightmare a poll: _spread_slow). Its amount comes
# only from Stream (15%) and the line's capstone (30%); the other rows grow where or how long. Bosses half.
const STREAM_SLOW := 0.15  # Stream: nightmares in water walk this much slower (Balancing 2026-10-23)
const CAPSTONE_SLOW := 0.30  # Flash Flood, Mudflats, Sinking Mud (Balancing 2026-10-23; bosses half)
const SLOW_BOSS_SHARE := 0.5
const EVO_REED := &"dw_reed_bed"
const REED_STEPS := 12  # Reed Bed: water runs on along path a Thornwall or Sprout touches, this many steps for each water
const EVO_FLASH := &"dw_flash_flood"
const FLASH_STEPS := 24  # Flash Flood: a splash runs this many steps each way along its water (Soaked still 4: RIPPLE_STEPS)…
const FLASH_SECONDS := 2.0  # …and slows each nightmare it reaches CAPSTONE_SLOW for this long…
const FLASH_EVERY := 1.0  # …each nightmare once a second
const FLASH_NEXT_META := &"pd_flash_next"  # On a nightmare
const TIMED_META := &"pd_timed_slow"  # On a nightmare: [until, amount, row id] (Flash Flood, Sinking Mud)
const EVO_LONG := &"dw_long_current"
const LONG_STEPS := 6  # Long Current: a nightmare leaving water keeps its in-water slow this many forward steps
const LONG_META := &"pd_long"  # On a nightmare: [exit route index, amount, passed the Waymark]
const LAST_SLOW_META := &"pd_last_slow"  # On a nightmare: its Calling slow at the last poll in water
const EVO_BACKWATERS := &"dw_backwaters"
const BACKWATER_GAP := 6  # Backwaters: two waters of one Dewdrop this many steps apart or less join through the gap
const EVO_MUDFLATS := &"dw_mudflats"
const MUD_GAP := 4  # Mudflats: path between two waters this many steps apart or less is mud (never more mud than water)
const EVO_SINKING := &"dw_sinking_mud"
const SINK_SECONDS := 2.0  # Sinking Mud: a flyer over mud or water is slowed STEADY_SLOW this long
# Final pass 2026-10-24 (owner "yes to all"; evo_fixed_dewdrop.md, final_check.md). Balancing 2026-10-24: every number here.
const STEADY_SLOW := 0.20  # Mudflats and Sinking Mud (bosses 0.10). CAPSTONE_SLOW stays for an old save's Flash Flood
const CLING_STEPS := 4  # Sinking Mud: leaving mud or water, STEADY_SLOW clings this many forward steps (Long Current keeps LONG_STEPS)
const WET_LAST_META := &"pd_wet_last"  # On a nightmare: it was in water or on mud at the last poll (Sinking Mud's walk-out)
const EVO_FLOODGATE := &"dw_floodgate"  # (EVO_FLOOD is the retired dw_flood)
const SURGE_SLOW := 0.35  # Floodgate: a dispel in water surges it: everything in it walks this much slower…
const SURGE_SECONDS := 3.0  # …for this long…
const SURGE_COOLDOWN := 6.0  # …each water at most once in this long
const EVO_SPATE := &"dw_spate"
const SPATE_STEPS := 12  # Spate: a surge also runs this many steps on down the path past its water (path only, never water)
const EVO_SILT := &"dw_silt"
const SILT_SECONDS := 4.0  # Silt: a surge's path stays silt this long…
const SILT_SLOW_SECONDS := 2.0  # …and a nightmare stepping onto it walks SURGE_SLOW slower this long (once per surge)
const KING_UPSTREAM_STEPS := 6  # King Tide: the steps before each pond water count toward its wave…
const KING_UPSTREAM := 4  # …and up to this many nightmares there take a wave hit too
const EVO_UNDERTOW := &"dw_undertow"
const UNDERTOW_PER := 0.10  # Undertow: a pond hit deals this much more for each spill target short of SPILL_MAX
const EVO_FATHOMS := &"dw_fathoms"
const FATHOM_PER := 0.10  # Fathoms: this much more for each second the nightmare has waded the pond (bosses twice as fast)…
const FATHOM_MAX := 0.50  # …up to this
const POND_SINCE_META := &"pd_pond_since"  # On a nightmare: when it entered the pond (leaving clears it)
const EVO_CRUSH := &"dw_crushing_depth"
const CRUSH_EVERY := 1.0  # Crushing Depth: at Fathoms' cap the pond Dewdrop's direct hit passes the shell, once a second per nightmare
const CRUSH_META := &"pd_crush_next"  # On a nightmare
const SIDE_DAMP_SECONDS := 2.0  # Riverside: a Dewdrop's own Soaked landing on a nightmare in water lasts this much longer
const EVO_MOUTH := &"dw_river_mouth"
const MOUTH_PER := 0.20  # River Mouth: the first other-family direct hit after leaving water, +20% per lingering status (not Soaked)…
const MOUTH_MAX := 0.60  # …up to this…
const MOUTH_STEPS := 6  # …within this many steps of the water's exit
const MOUTH_WIN_META := &"pd_mouth_win"  # On a nightmare: [exit route index, leg, water key] of the water it last left
const MOUTH_META := &"pd_mouth_seen"  # On a nightmare: {water key: true}: River Mouth spent (never re-armed by weaving)
const EVO_DELTA := &"dw_delta"
const DELTA_META := &"pd_delta_seen"  # On a nightmare: {water key: {Warden id: true}}
const EVO_RAPIDS := &"dw_rapids"
const RAPIDS_STEPS := 3  # Rapids: River Mouth's bonus also in a water's last this many steps…
const RAPIDS_META := &"pd_rapids_seen"  # …once per nightmare per water: {water key: true}
const SLOW_FX_EVERY := 1.0  # A slow's credit and puff: once a second per nightmare
const SLOW_FX_META := &"pd_slow_fx"
const SLOW_SEEN_META := &"pd_calling_slow"  # On a nightmare: [amount applied, poll time] (Heavy Going leaves it out)
# Focus: area damage across one pond (class_kit.calling_hit, damage only: never a status, crit, repeat or Reaction).
const SPILL_SHARE := 0.25  # Black Pond: a pond Dewdrop's direct hit there hits up to SPILL_MAX others in the pond for this share…
const SPILL_MAX := 4  # …nearest first, once per attack (a pulse spills its largest hit onto those it missed)
const EVO_DEEP_END := &"dw_deep_end"
const DEEP_END_PER_RANK := 0.03  # Deep End: +3% spill per rank of its Dewdrop, to rank VII (0.46; Balancing 2026-10-23)
const DEEP_END_TOP_RANK := 7
const EVO_WAVE := &"dw_breaking_wave"
const WAVE_RANK := 5  # Breaking Wave: the pond's Dewdrop at this rank or more…
const WAVE_CROWD := 4  # …with this many nightmares in the pond at once…
const WAVE_COOLDOWN := 4.0  # …hits each of them in full, at most once in this long…
const WAVE_MAX := 6  # …up to this many (furthest along first)
const EVO_KING := &"dw_king_tide"  # (Final pass: the queue before the pond; the boss count and shell pass are gone)
const EVO_TWIN := &"dw_twin_springs"
const EVO_CHURN := &"dw_churning_water"
const CHURN_EVERY := 3.0  # Churning Water: drift time between churns…
const CHURN_SCALE := 0.5  # …each a half hit (Balancing 2026-10-23: 0.75 if a sim shows it behind Breaking Wave)…
const CHURN_MAX := 4  # …on up to this many nightmares in the pond, shared between its two highest-rank Dewdrops
const EVO_THREE := &"dw_three_springs"
# Support: other families' statuses (a Sprout's statuses linger too; Sprouts count toward no Warden count and never take River
# Mouth / Delta / Rapids; Dewdrops never) linger by the water (EnemyStatuses.linger_calling, the
# Calling's room; Poisoned / Exposed / Charged share one room with the lent cards); the rows that stop the clock mark_kept.
const EVO_OPEN := &"dw_open_water"
const EVO_STILL := &"dw_still_water"
const STILL_WARDENS := 3  # Still Water: other Wardens on a water's bank for it to be still
const STILL_WATER_META := &"pd_still_water"  # On a nightmare in still water: {status: time left at the last poll}
const EVO_WIDE := &"dw_wide_banks"
const WIDE_BANK_CELLS := 2.0  # Wide Banks: Support rows count Wardens this many cells from water as on its bank
const WET_FOOT_SECONDS := 2.0  # Wet Footprints: after leaving water, other families' statuses don't run down this long
const WET_FOOT_META := &"pd_wet_foot"  # On a nightmare: when its footprints dry
const WET_KEEP_META := &"pd_wet_keep"  # On a nightmare: {status: time left at the last poll}
const PRINT_SECONDS := 2.0  # A drawn footprint lasts this long
const EVO_LOW_TIDE := &"dw_low_tide"
const LOW_TIDE_PER := 0.10  # Low Tide: other families' direct hits +10% per kept status, up to +30%
const LOW_TIDE_MAX := 0.30
const EVO_OUTFLOW := &"dw_outflow"
const OUTFLOW_PER := 0.20  # Outflow: the first such hit after leaving water +20% per kept status, up to +60% (instead of Low Tide)
const OUTFLOW_MAX := 0.60
const OUT_META := &"pd_outflow"  # On a nightmare: its first other-family direct hit is Outflow's
const LOW_FX_META := &"pd_low_fx"  # On a nightmare: Low Tide's splash, at most every SIDE_FX_EVERY
const EVO_WHIRLPOOL := &"dw_whirlpool"
const PULL_STEPS := 2  # Whirlpool: a fully Soaked nightmare in a pond is pulled back this many steps, once per pond (never bosses or flyers)
const WHIRL_HITS := 3  # Whirlpool (non-status builds, owner 2026-10-19): a Dewdrop's 3rd hit on a nightmare in a pond pulls it (was: full Soak)
const WHIRL_META := &"pd_whirl_hits"  # On a nightmare: {pond key: Dewdrop hits there}
const EVO_DEEP := &"dw_drowning_deep"
const DEEP_CELLS := 1.0  # Drowning Deep: a Whirlpool pull drags the nightmares within this many cells…
const DEEP_MAX := 4  # …up to this many (never bosses or flyers); Wardens touching the pond each hit the pulled one once, free
const EVO_STAGNANT := &"dw_stagnant_water"
# Stagnant Water (owner 2026-10-17: Dewdrop's own trait, Duration): statuses on a nightmare in a pond don't run down
# while it stays there. Each poll gives back the time a status lost since the last one, through EnemyStatuses.linger_calling
# (F2: the Calling's own CALLING_LINGER_MAX past the last landing, Charged 2 s, on top of the lent cards'; never above the time it had: never
# longer than its own duration; never Rooted or Drowsy). Bosses get back only this share: they run down at half speed.
const STILL_BOSS_SHARE := 0.5
const STILL_META := &"pd_still"  # On a nightmare in a pond: {status: time left at the last poll}
const STILL_FX_EVERY := 1.0  # The held cue (a ripple on the nightmare): once a second per nightmare
const STILL_FX_META := &"pd_still_fx"  # On a nightmare
const EVO_HANDS := &"dw_drowned_hands"
const HANDS_STATUSES := 4  # Drowned Hands: a nightmare carrying this many statuses in a pond…
const HANDS_HOLD := 1.0  # …is Held this long by the pond's strongest Dewdrop (bosses half), once per pond
const EVO_RIVERSIDE := &"dw_riverside"  # Support
const SIDE_SECONDS := 2.0  # Riverside (owner 2026-10-17: Duration, was +1 stack): a status a Warden touching water adds to a nightmare in that water lasts this much longer (F2: EnemyStatuses.linger_calling, its own cap; never Rooted or Drowsy)
const SIDE_FX_EVERY := 0.5  # Its cue (a thread and a puff): once in this long per nightmare
const SIDE_FX_META := &"pd_side_fx"  # On a nightmare
const EVO_RAIN := &"dw_rain_on_the_bank"
const RAIN_WARDENS := 3  # Rain on the Bank: a ripple gives every nightmare it soaks the status of up to this many bank Wardens…
const RAIN_STACKS := 1  # …this many stacks each (never Drowsy or Held)
const EVO_DOWNPOUR := &"dw_downpour"
const BURST_SOAKED := 4  # Downpour: a ripple that soaks this many nightmares…
const BURST_EVERY := 4.0  # …makes every bank Warden attack one of them at once, each Warden once in this long
const BURST_META := &"pd_burst_next"  # On a Warden
const DOWNPOUR_HIT_META := &"pd_burst_hit"  # On a Warden: [target id, until]: its forced attack's hit is Downpour's (damage credit)
const DOWNPOUR_HIT_WAIT := 2.0  # The forced attack lands within this long (a slow throw), or it is not counted
const EVO_WET := &"dw_wet_footprints"  # (Rebuilt 2026-10-23: WET_FOOT_SECONDS above; footprints are drawn only, never water)
const EVO_REFLECTION := &"dw_reflection"
const MIRROR_SHARE := 0.5  # Reflection: a bank Warden's hit on a Soaked nightmare in water lands this share (before defences) on the last one in it…
const MIRROR_EVERY := 1.0  # …once a second per Warden
const MIRROR_META := &"pd_mirror_next"  # On a Warden
const MIRROR_TAG := &"both_banks"  # A class tag (class_kit.CLASS_TAGS): the mirrored hit never sets a card off again
var _flowed := {}  # Route index -> true: water a Stream carried on (drawn as a current)
var _reeds := {}  # Route index -> true: water Reed Bed carried along a wall or Sprout (drawn with reeds)
var _backwater := {}  # Route index -> true: a gap Backwaters filled
var _mud := {}  # Route index -> true: Mudflats' mud (not water)
var _prints := {}  # Route index -> when it dries: Wet Footprints' drawn prints (never water)
var _spring_in := SPRING_EVERY
var _pond_dewdrops: Array = []  # Black Pond: the pond's Dewdrop first, then the ones that joined (Twin / Three Springs)
var _pond_waters := {}  # Water index -> true: the pond
var _spills := {}  # Dewdrop id -> {tower, base, hit: {enemy id: true}, at}: this attack's spill, flushed deferred
var _wave_next := -INF
var _churn_in := 0.0
var _still := {}  # Water index -> true: Still Water's still waters this poll
var _surge_next := {}  # Water key -> when it may surge again (Floodgate)
var _silt: Array = []  # Silt: [{points: {route index: true}, until, seen: {nightmare id: true}}]

func _family() -> String:
	return FAMILY

func _line() -> String:
	return LINE

# Lent cards never give the Calling's setup (owner 2026-10-14, dream_council_review.md 25-26): water, lone water and the
# ripple are the first pick's only (place_on). The lent cards work from Dewdrops, where Wardens stand ("near a Dewdrop":
# 2 cells; "a Dewdrop's range": its attack range) and Soaked.
func _lent_rules() -> Array:
	return [STEEPED, TOPPED_UP, DRIPPING, EBB, REMEMBERS, POOLING, WATERLOGGED, HEAVY_GOING, HIGH_TIDE, OLD_RAIN, NEVER_DRY,
		SODDEN, LAST_DROP, WASH_AWAY, CAUGHT_WADING, SHALLOWS, KNEE_DEEP, ACROSS, DEEP_POOL, RUN_OFF, RIPTIDE,
		SOMETHING, SOAKED_THROUGH]  # (From Caught Wading on: retired 2026-10-15 or before, need no water; old saves keep them)

# Wake Ripple (retired) carried statuses along the water: an old save holding it keeps the water on Continue.
func _legacy_rules() -> Array:
	return [WAKE_RIPPLE]

func _ready() -> void:
	super._ready()
	add_to_group(GROUP)

# --- The water map ----------------------------------------------------------------------------------------------------

func on_board() -> void:
	waters.clear()
	_water_at.clear()
	_lone.clear()
	_waters_of.clear()
	_across.clear()
	_near_dew.clear()
	_flowed.clear()
	_reeds.clear()
	_backwater.clear()
	_mud.clear()
	_pond_dewdrops.clear()
	_pond_waters.clear()
	if not place_on():  # Water is the Calling's (the first pick, or an old save's Wake Ripple)
		queue_redraw()
		return
	var dewdrops := own_towers()
	var touch := {}  # Warden id -> Array of route indices it touches
	var wet := {}
	for tower in dewdrops:
		touch[tower.get_instance_id()] = points_touching(tower)
		for i in touch[tower.get_instance_id()]:
			wet[i] = true
	if rule(LEVEE):
		for i in _levee_points(dewdrops):
			wet[i] = true
	if evo(EVO_STREAM):
		_flow(wet)
	if evo(EVO_REED):
		_reed_bed(wet)
	if evo(EVO_BACKWATERS):
		_backwaters(wet, dewdrops)
	var indices: Array = wet.keys()
	indices.sort()
	var run: Array = []
	for i in indices:
		if not run.is_empty() and int(i) - int(run[-1]) > 1:
			_add_water(run)
			run = []
		run.append(i)
	if not run.is_empty():
		_add_water(run)
	var all := towers()
	for w in waters.size():
		var water: Dictionary = waters[w]
		for tower in all:
			if not tower.tower_data.can_attack:
				continue
			var touches := false
			for i in water.points:
				if touches_point(tower, _route_px[int(i)]):
					touches = true
					break
			if not touches:
				continue
			(water.dewdrops if is_own(tower) else water.bank).append(tower)
			var mine: Array = _waters_of.get(tower.get_instance_id(), [])
			mine.append(w)
			_waters_of[tower.get_instance_id()] = mine
	# Lone: only walls touch its water (every water it touches has it alone and an empty bank)
	for tower in dewdrops:
		var lone := true
		for w in _waters_of.get(tower.get_instance_id(), []):
			if waters[int(w)].dewdrops.size() != 1 or not waters[int(w)].bank.is_empty():
				lone = false
		if lone and not _waters_of.get(tower.get_instance_id(), []).is_empty():
			_lone[tower.get_instance_id()] = true
	if evo(EVO_MUDFLATS):
		_make_mud()
	_refresh_pond()
	queue_redraw()

func _add_water(run: Array) -> void:
	var points := {}
	for i in run:
		points[i] = true
		_water_at[i] = waters.size()
	waters.append({"id": int(run[0]), "first": int(run[0]), "last": int(run[-1]), "points": points, "dewdrops": [], "bank": [],
		"steps": run.size() / 2.0})

# Stream: each water flows on FLOW_STEPS steps toward the Heartwood, stopping where it meets another water (they join).
func _flow(wet: Dictionary) -> void:
	var ends: Array = []
	for i in wet:
		if not wet.has(int(i) + 1):
			ends.append(int(i))
	for e in ends:
		for k in range(1, FLOW_STEPS * 2 + 1):
			var j: int = int(e) + k
			if j >= _route_px.size() or wet.has(j):
				break
			wet[j] = true
			_flowed[j] = true

# The wet route points split into runs of neighbours, in route order.
static func _wet_runs(wet: Dictionary) -> Array:
	var indices: Array = wet.keys()
	indices.sort()
	var runs: Array = []
	var run: Array = []
	for i in indices:
		if not run.is_empty() and int(i) - int(run[-1]) > 1:
			runs.append(run)
			run = []
		run.append(int(i))
	if not run.is_empty():
		runs.append(run)
	return runs

# Thornwalls and Sprouts (Reed Bed's carriers).
func _is_carrier(tower) -> bool:
	return is_wall(tower) or (tower is Tower and tower.tower_data != null and tower.tower_data.get_id() == "sprout")

# Reed Bed: from each water's ends the water runs on along path points a Thornwall or Sprout touches (path steps, never the
# walls), up to REED_STEPS steps for each water, both ways. Carried points are water for everything.
func _reed_bed(wet: Dictionary) -> void:
	var carriers: Array = towers().filter(_is_carrier)
	if carriers.is_empty():
		return
	for run in _wet_runs(wet):
		var budget := REED_STEPS * 2
		for dirn in [1, -1]:
			var j: int = (int(run[-1]) + 1) if dirn == 1 else (int(run[0]) - 1)
			while budget > 0 and j >= 0 and j < _route_px.size() and not wet.has(j) and _carried_at(carriers, j):
				wet[j] = true
				_reeds[j] = true
				budget -= 1
				j += dirn

func _carried_at(carriers: Array, i: int) -> bool:
	for tower in carriers:
		if touches_point(tower, _route_px[i]):
			return true
	return false

# Backwaters: where the path bends back past one Dewdrop, two of its waters up to BACKWATER_GAP steps apart join through
# the gap (path points only, forward order). Joined points are water for everything.
func _backwaters(wet: Dictionary, dewdrops: Array) -> void:
	var runs := _wet_runs(wet)
	for tower in dewdrops:
		var touched := {}
		for i in points_touching(tower):
			touched[int(i)] = true
		var mine: Array = []
		for run in runs:
			for i in run:
				if touched.has(int(i)):
					mine.append(run)
					break
		for k in range(1, mine.size()):
			var gap_from: int = int(mine[k - 1][-1]) + 1
			var gap_to: int = int(mine[k][0]) - 1
			if gap_to < gap_from or gap_to - gap_from + 1 > BACKWATER_GAP * 2:
				continue
			for j in range(gap_from, gap_to + 1):
				if not wet.has(j):
					wet[j] = true
					_backwater[j] = true

# Mudflats: path between two waters up to MUD_GAP steps apart is mud (not water). Never more mud than water: the shortest
# gaps are kept when it would be.
func _make_mud() -> void:
	var order: Array = range(waters.size())
	order.sort_custom(func(a, b) -> bool: return int(waters[a].first) < int(waters[b].first))
	var water_points := 0
	var gaps: Array = []  # [length, from, to]
	for k in order.size():
		water_points += (waters[order[k]].points as Dictionary).size()
		if k == 0:
			continue
		var from: int = int(waters[order[k - 1]].last) + 1
		var to: int = int(waters[order[k]].first) - 1
		if to >= from and to - from + 1 <= MUD_GAP * 2:
			gaps.append([to - from + 1, from, to])
	gaps.sort_custom(func(a, b) -> bool: return int(a[0]) < int(b[0]))
	var mud_points := 0
	for gap in gaps:
		if mud_points + int(gap[0]) > water_points:
			continue
		mud_points += int(gap[0])
		for j in range(int(gap[1]), int(gap[2]) + 1):
			_mud[j] = true

# Levee: a row of up to 2 walls, each touching the next, with a Dewdrop touching each end, carries their water along
# the path beside it. Sprouts are not walls.
func _levee_points(dewdrops: Array) -> Array:
	var walls: Array = towers().filter(is_wall)
	var found := {}
	for first in walls:
		var ends: Array = dewdrops.filter(func(d) -> bool: return touching(d, first))
		if ends.is_empty():
			continue
		if ends.size() >= 2:
			for i in points_touching(first):
				found[i] = true
			continue
		if LEVEE_WALLS < 2:
			continue
		for second in walls:
			if second == first or not touching(first, second):
				continue
			if dewdrops.any(func(d) -> bool: return d != ends[0] and touching(d, second)):
				for i in points_touching(first) + points_touching(second):
					found[i] = true
	return found.keys()

# A Dewdrop's key for "once for each nightmare and Dewdrop" records: its cell, so selling and replanting it on the
# same spot does not pay again (council, lent_td.md).
func _key(tower) -> String:
	return "%d,%d" % [roundi(tower.cell.x * 2.0), roundi(tower.cell.y * 2.0)]

# The strongest hit among a water's Dewdrops (Caught Wading's cap).
func _dewdrop_hit(dewdrops: Array) -> float:
	var best := 0.0
	for tower in dewdrops:
		if is_instance_valid(tower):
			best = maxf(best, tower.get_damage())
	return best

# A water's stable key: the smallest cell key among its Dewdrops.
func _water_key(water: Dictionary) -> String:
	var keys: Array = []
	for tower in water.dewdrops:
		if is_instance_valid(tower):
			keys.append(_key(tower))
	keys.sort()
	return keys[0] if not keys.is_empty() else str(water.id)

func water_of(enemy) -> int:
	var i := index_of(enemy)
	return _water_at_i(i) if i >= 0 else -1

# The water at route index `i` (-1 none). Real water only (since 2026-10-23 Wet Footprints' prints are never water).
func _water_at_i(i: int) -> int:
	return int(_water_at.get(i, -1))

func is_lone(tower) -> bool:
	return _lone.has(tower.get_instance_id())

func touches_water(tower, w: int) -> bool:
	return w >= 0 and _waters_of.get(tower.get_instance_id(), []).has(w)

# A water's bank: the attacking Wardens of other families (Sprouts too) touching it.
func _bank_of(w: int) -> Array:
	if w < 0 or w >= waters.size():
		return []
	return (waters[w].bank as Array).filter(_tower_ok)

# The Support rows' bank (Riverside, Still Water): touching water `w`, or with Wide Banks up to WIDE_BANK_CELLS from it.
func _on_bank(tower, w: int) -> bool:
	if w < 0 or w >= waters.size() or not _tower_ok(tower):
		return false
	if touches_water(tower, w):
		return true
	if not evo(EVO_WIDE):
		return false
	for i in waters[w].points:
		if within(tower.global_position, _route_px[int(i)], WIDE_BANK_CELLS):
			return true
	return false

# Black Pond (rebuilt 2026-10-23): the pond is the water of the highest-rank Dewdrop (ties: the higher form, then the first
# planted); Twin Springs adds the highest-rank Dewdrop touching it, Three Springs a third touching either. Their waters
# are the pond. Worked out on the board and each poll (ranks change without a board change).
func _refresh_pond() -> void:
	_pond_dewdrops.clear()
	_pond_waters.clear()
	if not evo(EVO_POND):
		return
	var dewdrops: Array = own_towers()
	if dewdrops.is_empty():
		return
	dewdrops.sort_custom(_pond_order)
	_pond_dewdrops.append(dewdrops[0])
	var partners := 1 if evo(EVO_TWIN) else 0
	if evo(EVO_THREE):
		partners = 2
	while _pond_dewdrops.size() < 1 + partners:
		var joined = null
		for tower in dewdrops:
			if not _pond_dewdrops.has(tower) and _touches_pond_dewdrop(tower):
				joined = tower
				break
		if joined == null:
			break
		_pond_dewdrops.append(joined)
	for tower in _pond_dewdrops:
		for w in _waters_of.get(tower.get_instance_id(), []):
			_pond_waters[int(w)] = true

func _touches_pond_dewdrop(tower) -> bool:
	for d in _pond_dewdrops:
		if touching(d, tower):
			return true
	return false

# Higher rank first, then the higher form, then the first planted (the older node).
func _pond_order(a, b) -> bool:
	if int(a.rank) != int(b.rank):
		return int(a.rank) > int(b.rank)
	if int(a.tower_data.tier) != int(b.tower_data.tier):
		return int(a.tower_data.tier) > int(b.tower_data.tier)
	return a.get_instance_id() < b.get_instance_id()

# The living nightmares standing in the pond.
func _pond_enemies() -> Array:
	var out: Array = []
	if _pond_waters.is_empty():
		return out
	for enemy in enemies():
		var i := index_of(enemy)
		if i >= 0 and _pond_waters.has(_water_at_i(i)):
			out.append(enemy)
	return out

# The strongest (damage a second) valid Warden in `list`, or null.
func _strongest(list: Array):
	var best = null
	for tower in list:
		if _tower_ok(tower) and (best == null or second_of(tower) > second_of(best)):
			best = tower
	return best

# The pond (Black Pond, rebuilt 2026-10-23: _refresh_pond; was any water touching 2 Dewdrops). The retired pond rows
# (Whirlpool, Stagnant Water, Drowned Hands) of an old save read it too.
func _is_pond(w: int) -> bool:
	return w >= 0 and _pond_waters.has(w)

# The living nightmares in water `w` within `steps` of route index `from` (not `skip`), nearest first.
func _in_water(w: int, from: int, steps: int, skip = null) -> Array:
	var found: Array = []
	for enemy in enemies():
		if enemy == skip:
			continue
		var i := index_of(enemy)
		if i >= 0 and _water_at_i(i) == w and absi(i - from) <= steps * 2:
			found.append(enemy)
	found.sort_custom(func(a, b) -> bool: return absi(index_of(a) - from) < absi(index_of(b) - from))
	return found

func _once(enemy, key: String) -> bool:
	var done: Dictionary = enemy.get_meta(ONCE_META, {})
	if done.has(key):
		return false
	done[key] = true
	enemy.set_meta(ONCE_META, done)
	return true

func _soaked(enemy) -> bool:
	return enemy.statuses.has(EnemyStatuses.DAMP)

func _fully_soaked(enemy) -> bool:
	return _soaked(enemy) and enemy.statuses.stacks(EnemyStatuses.DAMP) >= enemy.statuses.get_max_stacks(EnemyStatuses.DAMP)

# --- Damage events ----------------------------------------------------------------------------------------------------

# The strongest Dewdrop near `tower` (2 cells on both axes; a Dewdrop is near itself), or null. Cached per board.
func dewdrop_near(tower):
	var id: int = tower.get_instance_id()
	if _near_dew.has(id) and (_near_dew[id] == null or is_instance_valid(_near_dew[id])):
		return _near_dew[id]
	var found = strongest_near(tower.global_position, is_own)
	_near_dew[id] = found
	return found

func on_damage(event, source, enemy, is_hit: bool, dispel: bool, tagged: bool) -> void:
	if dispel and rule(RUN_OFF):
		_run_off(enemy)
	if dispel and evo(EVO_FLOODGATE):
		_floodgate(enemy)  # Any family's dispel, any damage (echoes and split children too)
	if tagged or source == null or not is_hit:
		return
	if rule(SOMETHING) and is_own(source) and living(enemy):
		_something(source, enemy)
	if rule(SHALLOWS) and is_other(source) and living(enemy):
		_shallows(source, enemy)
	if rule(TOPPED_UP) and is_own(source) and living(enemy) and now() >= float(enemy.get_meta(TOPPED_META, -INF)):
		# Topped Up: a Dewdrop's hit puts every status back to its time at landing (never longer). Once a second per nightmare
		enemy.set_meta(TOPPED_META, now() + TOPPED_UP_EVERY)
		for id in enemy.statuses.active_ids():
			var left_before := SETUP.time_left(enemy, id)  # (setup credit 2026-10-16: the seconds given back, as Linger)
			enemy.statuses.top_up(id)
			SETUP.note_linger(enemy, card_id(TOPPED_UP), id, SETUP.time_left(enemy, id) - left_before)
	if not place_on():
		return
	if not is_own(source):
		if class_on() and not dream_state.calling_path.is_empty() and living(enemy):
			var bank_w := water_of(enemy)
			if bank_w >= 0:
				_bank_hit(event, source, enemy, bank_w)  # Lapping Water, Reflection (retired: old saves)
		return
	var w := water_of(enemy)
	if evo(EVO_WHIRLPOOL) and w >= 0 and _is_pond(w) and living(enemy) and not enemy.statuses.is_boss and not enemy.is_flying():
		_whirl_hit(enemy, w)
	if evo(EVO_POND) and _is_pond(w) and _pond_dewdrops.has(source) and not _in_calling_event:
		_queue_spill(source, enemy, float(event.base))  # Black Pond: this attack spills across the pond
	if w < 0 or not touches_water(source, w):
		return
	var from := index_of(enemy)
	# The Calling's ripple (the first pick only): nightmares within 4 steps in that water are Soaked (Black Pond: 8;
	# Flood: the whole water)
	if class_on():
		ripples += 1
		_splash(enemy)  # puddle_ripple where the ripple starts
		_pulses.append([from, _ripple_steps(w) * 2, now()])  # It runs visibly along the water (owner 2026-10-22)
	var soaked: Array = []
	for other in (_in_water(w, from, _ripple_steps(w), enemy) if class_on() else []):
		if now() >= float(other.get_meta(RIPPLE_META, -INF)):
			other.set_meta(RIPPLE_META, now() + RIPPLE_EVERY)
			var by := _ripple_evo(other, from)  # Reached only thanks to Flood, Wet Footprints or the Stream: its Soaked (owner 2026-10-19)
			if by != &"":
				SETUP.begin(StringName(card_id(by)))
			_arm_apply()  # F1 (f1_spec.md): the ripple's Soaked is that Dewdrop's application for other families' lent cards
			source._apply_one_status(other, EnemyStatuses.DAMP, 1, source.get_damage(), false)
			_disarm_apply()
			if by != &"":
				SETUP.end()
			soaked.append(other)
	if class_on() and not dream_state.calling_path.is_empty():
		_ripple_shown(enemy, w, from, soaked)
		_ripple_extras(enemy, w, soaked)
		if evo(EVO_FLASH):
			_flash_flood(enemy, w, from)
	# Swell: the splash spreads through that water, up to 4 steps each way, at half outside its own circle
	if rule(SWELL):
		var circle: float = source.get_splash_cells() * cell()
		for other in _in_water(w, from, RIPPLE_STEPS, enemy):
			if other.global_position.distance_to(enemy.global_position) > circle:
				strike(source, other, event.base * SWELL_SHARE, &"swell", true)
	# Both Banks: a lone Dewdrop with water on two sides: each splash also lands on the front nightmare in its other
	# water, at half, with its Soaked
	if rule(BOTH_BANKS) and is_lone(source):
		for other_w in _waters_of.get(source.get_instance_id(), []):
			if int(other_w) == w:
				continue
			var front = _front_in(int(other_w))
			if front != null:
				_line_fx(body(source), body(front), 2.0, Palette.DEWLIGHT)
				strike(source, front, event.base * BOTH_BANKS_SHARE, &"both_banks")
				if living(front):
					source._apply_one_status(front, EnemyStatuses.DAMP, maxi(int(source.attack_data.status_stacks), 1), source.get_damage(), false)

# Shallows: a hit from another Warden touching a Dewdrop that Soaks adds 1 Soaked, the Dewdrop's own application (not
# native: it never counts as a Dewdrop Soaking it). Each Warden, once a second; the main target only.
func _shallows(source, enemy) -> void:
	if now() < float(source.get_meta(SHALLOWS_META, -INF)):
		return
	var dewdrop = null
	for tower in own_towers():
		if status_of(tower) == EnemyStatuses.DAMP and touching(tower, source) and (dewdrop == null or second_of(tower) > second_of(dewdrop)):
			dewdrop = tower
	if dewdrop == null:
		return
	source.set_meta(SHALLOWS_META, now() + SHALLOWS_EVERY)
	dewdrop._apply_one_status(enemy, EnemyStatuses.DAMP, 1, dewdrop.get_damage(), false)

func _front_in(w: int):
	var front = null
	var best := -1
	for enemy in enemies():
		var i := index_of(enemy)
		if i > best and _water_at_i(i) == w:
			best = i
			front = enemy
	return front

# The last nightmare in water `w` (furthest from the Heartwood), not `skip`, or null (Reflection).
func _back_in(w: int, skip):
	var back = null
	var best := 1 << 30
	for enemy in enemies():
		if enemy == skip:
			continue
		var i := index_of(enemy)
		if i >= 0 and i < best and _water_at_i(i) == w:
			best = i
			back = enemy
	return back

# --- The poll: who walks in, who walks out ------------------------------------------------------------------------------

func on_poll() -> void:
	if rule(SODDEN):
		for enemy in enemies():
			_sodden_walk(enemy)  # F6
	if rule(SOAKED_THROUGH):
		for enemy in enemies():
			_soaked_through(enemy)
	if rule(EBB) or rule(LAST_DROP):
		for enemy in enemies():
			if not enemy.has_meta(EBB_META):
				enemy.set_meta(EBB_META, true)
				enemy.statuses.status_ran_out.connect(_ran_out.bind(enemy))
	if rule(WATERLOGGED):
		for enemy in enemies():
			_slow_to_dry(enemy)
	var ranges := rule(REMEMBERS) or rule(RIPTIDE) or rule(DRIPPING)
	var knee := rule(KNEE_DEEP)
	if ranges or knee:
		var dewdrops := own_towers()
		for enemy in enemies():
			if enemy.is_flying():
				continue  # Flyers never walk back in, and Knee-Deep never slows them
			if ranges:
				_track_ranges(enemy, dewdrops)
			if knee and _soaked(enemy):
				for tower in dewdrops:
					if tower.global_position.distance_to(enemy.global_position) <= tower.get_range_pixels():
						HelperCommons.slow(enemy, KNEE_SLOW_FULL if _fully_soaked(enemy) else KNEE_SLOW, KNEE_TIME)
						control_slow(KNEE_DEEP, KNEE_SLOW_FULL if _fully_soaked(enemy) else KNEE_SLOW, POLL)  # (setup credit 2026-10-16: the poll's time)
						break
	_tick_riptides()
	if not place_on():
		return
	# The water (the first pick only): walking in and out (Breakwater, Soaked to the Bone, Both Banks' lanes)
	for enemy in enemies():
		if enemy.is_flying():
			continue
		var w := water_of(enemy)
		var was := int(enemy.get_meta(WATER_META, -1))
		var was_water: Dictionary = waters[was] if was >= 0 and was < waters.size() else {}
		if w != was:
			enemy.set_meta(WATER_META, w)
			if not was_water.is_empty():
				_left(enemy, was_water)
			if w >= 0:
				_entered(enemy, waters[w])
	_evolutions_poll()

func on_rest() -> void:
	if not _prints.is_empty():  # Nothing waits through a rest: footprints dry at once
		_prints.clear()
		queue_redraw()

# Each Dewdrop's range, per walking nightmare: leaving it records where; coming back in at least 3 route steps further
# along is "walking back in" (a pull back into the same range never counts). The Water Remembers and Riptide.
func _track_ranges(enemy, dewdrops: Array) -> void:
	var i := index_of(enemy)
	if i < 0:
		return
	var seen: Dictionary = enemy.get_meta(RANGE_META, {})
	for tower in dewdrops:
		var key := _key(tower)
		var inside: bool = tower.global_position.distance_to(enemy.global_position) <= tower.get_range_pixels()
		var row: Array = seen.get(key, [false, -1])
		if inside == bool(row[0]):
			continue
		if not inside:
			seen[key] = [false, i]  # It left: where, and what it carried
			var left: Dictionary = enemy.get_meta(LEFT_META, {})
			left[key] = _other_statuses(enemy)
			enemy.set_meta(LEFT_META, left)
			if rule(DRIPPING) and bool(row[0]) and living(enemy):
				_drip(enemy)
			continue
		seen[key] = [true, int(row[1])]
		if int(row[1]) >= 0 and i - int(row[1]) >= RETURN_STEPS * 2 and living(enemy):
			_walked_back(enemy, tower, key)
	enemy.set_meta(RANGE_META, seen)

func _walked_back(enemy, tower, key: String) -> void:
	if rule(REMEMBERS) and _once(enemy, "remembers:" + key):
		_remember(enemy, key)
	if rule(RIPTIDE) and _soaked(enemy) and _once(enemy, "riptide:" + key):
		# Riptide: it wades at half speed for 2 s (a slow, never Rooted), and each Warden near that Dewdrop lands its first
		# hit on it double in those 2 s
		HelperCommons.slow(enemy, RIPTIDE_SLOW, RIPTIDE_SECONDS)
		control_slow(RIPTIDE, RIPTIDE_SLOW, RIPTIDE_SECONDS)  # (setup credit 2026-10-16)
		enemy.set_meta(RIP_META, {"until": now() + RIPTIDE_SECONDS, "at": tower.global_position, "done": {}})

func _left(enemy, water: Dictionary) -> void:
	var seen: Dictionary = enemy.get_meta(SEEN_META, {})
	var left: Dictionary = enemy.get_meta(LEFT_META, {})
	var snapshot := _other_statuses(enemy)
	for tower in water.dewdrops:
		if is_instance_valid(tower):
			seen[_key(tower)] = true
			left[_key(tower)] = snapshot
	enemy.set_meta(SEEN_META, seen)
	enemy.set_meta(LEFT_META, left)
	if not living(enemy):
		return
	if class_on() and not dream_state.calling_path.is_empty():
		_left_water(enemy, water)  # Long Current, Wet Footprints, Outflow, River Mouth
	# Backwash: a Soaked nightmare leaving water is hit once, free, by each Dewdrop touching that water (up to 4)
	if rule(BACKWASH) and _soaked(enemy):
		var fired := 0
		for tower in water.dewdrops:
			if fired >= BACKWASH_DEWDROPS:
				break
			if is_instance_valid(tower) and free_hit(tower, enemy, 1.0, FREE_HIT_TAG, INF, BACKWASH):  # (own: setup credit 2026-10-16)
				fired += 1
	# Breakwater: a fully Soaked nightmare leaving water 14 or more steps long takes a wave
	if rule(BREAKWATER) and float(water.steps) >= BREAKWATER_STEPS and _fully_soaked(enemy) and living(enemy) \
			and _once(enemy, "breakwater:%d" % int(water.id)):
		var best = null
		for tower in water.dewdrops:
			if is_instance_valid(tower) and (best == null or second_of(tower) > second_of(best)):
				best = tower
		if best != null:
			Reactions._effect(&"landing_dust", enemy.global_position, self, 1.5)
			strike(best, enemy, second_of(best) * BREAKWATER_SECONDS, &"breakwater")

# A nightmare walked out of water (the poll's walk-out, before _evolutions_poll): Long Current keeps its last in-water slow
# for LONG_STEPS forward steps; Wet Footprints keeps other families' statuses for WET_FOOT_SECONDS; Outflow readies its first
# other-family direct hit (once for each water left).
func _left_water(enemy, water: Dictionary = {}) -> void:
	if (evo(EVO_MOUTH) or evo(EVO_DELTA)) and not water.is_empty():
		var exit := index_of(enemy)
		if exit >= 0:  # River Mouth / Delta: the window past this water's exit (spent per water key, never re-armed)
			enemy.set_meta(MOUTH_WIN_META, [exit, bool(enemy.get("passed_waymark")), _mouth_key(enemy, water)])
	if evo(EVO_LONG):
		var amount := float(enemy.get_meta(LAST_SLOW_META, 0.0))
		var i := index_of(enemy)
		if amount > 0.0 and i >= 0:
			enemy.set_meta(LONG_META, [i, amount, bool(enemy.get("passed_waymark"))])
	if evo(EVO_WET):
		enemy.set_meta(WET_FOOT_META, now() + WET_FOOT_SECONDS)
		enemy.remove_meta(WET_KEEP_META)
		credit(EVO_WET, enemy.global_position)
	if evo(EVO_OUTFLOW):
		enemy.set_meta(OUT_META, true)

func _entered(enemy, water: Dictionary) -> void:
	if class_on():  # Back in water: no footprints, no Outflow hit waiting, no Long Current / Sinking Mud wake, no mouth window
		for meta in [WET_FOOT_META, WET_KEEP_META, OUT_META, LONG_META, MOUTH_WIN_META]:
			if enemy.has_meta(meta):
				enemy.remove_meta(meta)
	var seen: Dictionary = enemy.get_meta(SEEN_META, {})
	for tower in water.dewdrops:
		if not is_instance_valid(tower) or not seen.has(_key(tower)) or not living(enemy):
			continue
		# It walks back into this Dewdrop's water (The Water Remembers and Riptide read the Dewdrop's range now: _walked_back)
		if not is_lone(tower):
			continue
		if rule(SOAKED_BONE) and _once(enemy, "bone:" + _key(tower)):
			# Soaked to the Bone (class): fully Soaked at once, the Dewdrop's own application up to the limit
			var room: int = enemy.statuses.get_max_stacks(EnemyStatuses.DAMP) - enemy.statuses.stacks(EnemyStatuses.DAMP)  # (The application's own cap clamps it)
			if room > 0:
				Reactions._effect(&"landing_dust", enemy.global_position, self, 0.8)
				setup_apply(SOAKED_BONE, tower, enemy, EnemyStatuses.DAMP, room, tower.get_damage())  # (setup credit 2026-10-16)
		if rule(THERE_AND_BACK):
			free_hit(tower, enemy, 1.0, FREE_HIT_TAG, INF, THERE_AND_BACK)  # There and Back: hit once, free, by that lone Dewdrop

func _tick_riptides() -> void:
	for i in range(_riptides.size() - 1, -1, -1):
		var rip: Dictionary = _riptides[i]
		var enemy = rip.enemy.get_ref()
		var tower = rip.tower.get_ref()
		if not living(enemy) or int(rip.ticks) <= 0:
			_riptides.remove_at(i)
			continue
		rip.wait = float(rip.wait) - POLL
		if float(rip.wait) <= 0.0:
			rip.wait = RIPTIDE_TICK
			rip.ticks = int(rip.ticks) - 1
			strike(tower, enemy, float(rip.amount), &"riptide")

# --- Calling evolutions -------------------------------------------------------------------------------------------------

# The evolutions' batch-hook hit bonuses: only the retired Downpour's credit now (old saves). Since 2026-10-23 Stream, Black
# Pond and Riverside have no hit bonus; Low Tide and Outflow multiply direct hits through DreamState.hit_card_multiplier's
# Calling branch (hit_multiplier below).
func _evo_hit_multiplier(enemy, source) -> float:
	if evo(EVO_DOWNPOUR) and source.has_meta(DOWNPOUR_HIT_META):
		_downpour_hit(enemy, source)
	return 1.0

# Heavy Going: the nightmare walks slowed by anything but Sleep (a timed slow, Sticky Caps, Switchback, the Stag's aura).
# Held and asleep nightmares stand still: only a slow counts. Never the Calling's own slow (section 33: Heavy Going counts
# only slows not from the Calling): the timed-slow entry this node applied last poll (SLOW_SEEN_META) is left out.
func walking_slowed(enemy) -> bool:
	var s: EnemyStatuses = enemy.statuses
	if s.ignores_slows:
		return false
	if (s.slow_time > 0.0 and s.slow_amount > 0.0) or s.is_in_stag_aura():
		return true
	var mine: Array = enemy.get_meta(SLOW_SEEN_META, [])
	for timed in s.timed_slows:
		if float(timed[0]) <= 0.0 or float(timed[1]) <= 0.0:
			continue
		var ours: bool = mine.size() >= 2 and is_equal_approx(float(timed[0]), float(mine[0])) \
			and float(timed[1]) <= POLL + 0.05 + 0.001 and now() - float(mine[1]) <= POLL * 2.0
		if not ours:
			return true
	return false

func wants_damage_hook() -> bool:
	return rule(HEAVY_GOING) or rule(SODDEN) or evo(EVO_DOWNPOUR)  # (Stream / Black Pond / Riverside hit bonuses gone 2026-10-23)

# The evolution a ripple reached `other` thanks to (&"": the Calling's own 4 steps of real water): Flood (past 4 steps, an
# old save's), the Stream (water it carried), Reed Bed or Backwaters (water they made). For the ledger.
func _ripple_evo(other, from: int) -> StringName:
	var i := index_of(other)
	if i < 0:
		return &""
	if evo(EVO_FLOOD) and absi(i - from) > RIPPLE_STEPS * 2:
		return EVO_FLOOD
	if _reeds.has(i):
		return EVO_REED
	if _backwater.has(i):
		return EVO_BACKWATERS
	if evo(EVO_STREAM) and _flowed.has(i):
		return EVO_STREAM
	return &""

# Downpour's forced attack (from damage_multiplier, inside Enemy.take_damage): its hit on the nightmare it was sent at is
# Downpour's own damage, whole (DreamState.begin_own_hit; damage credit, owner 2026-10-19).
func _downpour_hit(enemy, source) -> void:
	var sent: Array = source.get_meta(DOWNPOUR_HIT_META, [])
	if sent.size() < 2:
		return
	if now() > float(sent[1]):
		source.remove_meta(DOWNPOUR_HIT_META)
		return
	if int(sent[0]) != enemy.get_instance_id():
		return
	source.remove_meta(DOWNPOUR_HIT_META)
	dream_state.begin_own_hit(EVO_DOWNPOUR, enemy)

# How many steps each way a Dewdrop's ripple runs in water `w` (Flood; Black Pond's 8 steps became POND_BONUS 2026-10-18).
func _ripple_steps(w: int) -> int:
	var steps := RIPPLE_STEPS
	if evo(EVO_FLOOD) and w >= 0 and w < waters.size():
		steps = maxi(steps, mini(ceili(float(waters[w].steps)), FLOOD_STEPS))
	return steps

# A flash along water `w` from route index `a` to `b` (Flood, Black Pond, Spring Flood): the ripple running.
func _water_fx(w: int, a: int, b: int, width: float = 1.0) -> void:
	var points := PackedVector2Array()
	for i in range(maxi(a, 0), mini(b, _route_px.size() - 1) + 1):
		if _water_at_i(i) == w:
			points.append(_route_px[i])
	var world := Reactions._world(self)
	if world != null and points.size() >= 2:
		world.add_child(ChainBolt.new(points, Palette.DEWLIGHT, width))

# What a ripple shows and credits once it soaked `soaked` (a long ripple flashes along the water).
func _ripple_shown(enemy, w: int, from: int, soaked: Array) -> void:
	if soaked.is_empty():
		return
	var far := 0
	var flowed := false
	for other in soaked:
		var i := index_of(other)
		if i < 0:
			continue
		far = maxi(far, absi(i - from))
		if _flowed.has(i):
			flowed = true
	if flowed and evo(EVO_STREAM):
		credit(EVO_STREAM, enemy.global_position)  # It reached a nightmare on water the Stream carried (drawn as a current)
	if far > RIPPLE_STEPS * 2:
		_water_fx(w, from - far, from + far)
		credit(EVO_FLOOD, enemy.global_position)  # Only Flood runs a splash past 4 steps (2026-10-18)

# Everything an evolution adds to a ripple (a Dewdrop's, or Lapping Water's from a bank Warden).
func _ripple_extras(enemy, w: int, soaked: Array) -> void:
	if soaked.is_empty() or not living(enemy):
		return
	if evo(EVO_MILLRACE):
		_millrace(enemy, soaked)
	if evo(EVO_RAIN):
		_rain(w, soaked)
	if evo(EVO_DOWNPOUR) and soaked.size() >= BURST_SOAKED:
		_downpour(enemy, w, soaked)

# Puts `stacks` of `id` on `other`: quietly onto a status it has, or started as `source`'s own (not native) application.
# Charged never fills to a bolt. True when it landed.
# `credit_id` (setup credit 2026-10-16): the evolution whose carry this is, for the ledger.
# F1 (f1_spec.md): a carry that starts the status is a Calling application by `source` (a top-up is nothing).
# F5 (owner 2026-10-18): Drowsy (Rain on the Bank only) stops 1 short of full, so a carry never completes Drown, Night
# Terror, Sleepwalk or Pinned, and gets no F1 extras.
func _carry(other, id: StringName, stacks: int, source, credit_id: StringName = &"") -> bool:
	if not living(other) or id == EnemyStatuses.HELD or stacks <= 0:
		return false
	var drowsy := id == EnemyStatuses.DROWSY
	if drowsy:
		var s: EnemyStatuses = other.statuses
		var room: int = mini(s.normal_cap(id), s.get_max_stacks(id)) - 1 - s.stacks(id)
		if room <= 0:
			return false
		stacks = mini(stacks, room)
	if other.statuses.has(id):
		var added: int = other.statuses.add_quiet(id, stacks)
		setup_quiet(other, credit_id, id, added)
		return added > 0
	if not (source is Tower) or not is_instance_valid(source):
		return false
	if id == EnemyStatuses.STATIC and stacks >= other.statuses.get_max_stacks(id) - 1:
		return false
	if class_on() and dream_state != null:
		dream_state.arm_apply(FAMILY, drowsy)
	setup_apply(credit_id, source, other, id, stacks, source.get_damage())
	_disarm_apply()
	return living(other) and other.statuses.has(id)

# Millrace: the ripple carries 1 stack of up to 3 of the hit nightmare's other statuses to every nightmare it soaks.
func _millrace(enemy, soaked: Array) -> void:
	var carried: Array = []
	for id in enemy.statuses.active_ids():
		if carried.size() >= MILL_STATUSES:
			break
		if id == EnemyStatuses.DAMP or id == EnemyStatuses.HELD or id == EnemyStatuses.DROWSY:
			continue
		carried.append([id, enemy.statuses.source(id)])
	if carried.is_empty():
		return
	var given := 0
	for other in soaked:
		var landed := false
		for row in carried:
			if _carry(other, row[0], MILL_STACKS, row[1], EVO_MILLRACE):
				landed = true
		if landed:
			given += 1
			_line_fx(body(enemy), body(other), 1.0, Palette.DEWLIGHT)
	if given > 0:
		Reactions._effect(&"landing_dust", enemy.global_position, self, 0.5)
		credit(EVO_MILLRACE, enemy.global_position)

# Rain on the Bank: every nightmare the ripple soaks takes 1 of each of up to 3 bank Wardens' statuses (their own application).
func _rain(w: int, soaked: Array) -> void:
	var bank: Array = _bank_of(w)  # F5: Drowsy too, 1 short of full (_carry)
	for dewdrop in waters[w].dewdrops:  # The Dewdrops touching that water count too (non-status builds, owner 2026-10-19)
		if _tower_ok(dewdrop) and not bank.has(dewdrop):
			bank.append(dewdrop)
	bank = bank.filter(func(t) -> bool: return status_of(t) != &"")
	if bank.is_empty():
		return
	bank.sort_custom(func(a, b) -> bool: return second_of(a) > second_of(b))
	bank = bank.slice(0, RAIN_WARDENS)
	var rained := false
	for other in soaked:
		var wet_one := false
		for tower in bank:
			if _carry(other, status_of(tower), RAIN_STACKS, tower, EVO_RAIN):
				wet_one = true
		if wet_one:
			rained = true
			Reactions._effect(&"landing_dust", other.global_position, self, 0.35)
	if rained:
		for tower in bank:
			_line_fx(body(tower), body(soaked[0]), 1.0, Palette.DEWLIGHT)
		credit(EVO_RAIN, soaked[0].global_position)

# Downpour: a ripple soaking 4 or more makes every bank Warden attack one of them at once (each Warden once in 4 s).
func _downpour(enemy, w: int, soaked: Array) -> void:
	var fired := 0
	for tower in _bank_of(w):
		if not tower.tower_data.can_attack or now() < float(tower.get_meta(BURST_META, -INF)):
			continue
		var target = soaked[fired % soaked.size()]
		if not living(target):
			continue
		tower.set_meta(BURST_META, now() + BURST_EVERY)
		tower.volley_now(target)
		tower.set_meta(DOWNPOUR_HIT_META, [target.get_instance_id(), now() + DOWNPOUR_HIT_WAIT])  # (damage credit, owner 2026-10-19)
		_line_fx(body(tower), body(target), 2.0, Palette.DEWLIGHT)
		fired += 1
	if fired > 0:
		Reactions._effect(&"landing_dust", enemy.global_position, self, 1.6)
		credit(EVO_DOWNPOUR, enemy.global_position)

# A bank Warden's own hit on a Soaked nightmare in water it touches (Lapping Water, Reflection).
func _bank_hit(event, source, enemy, w: int) -> void:
	if not _soaked(enemy) or not touches_water(source, w):
		return
	if evo(EVO_LAPPING) and now() >= float(source.get_meta(LAP_META, -INF)) and w < waters.size():
		var dewdrop = _strongest(waters[w].dewdrops)
		if dewdrop != null:
			var soaked: Array = []
			for other in _in_water(w, index_of(enemy), LAP_STEPS, enemy):
				if now() >= float(other.get_meta(RIPPLE_META, -INF)):
					other.set_meta(RIPPLE_META, now() + RIPPLE_EVERY)
					calling_apply(EVO_LAPPING, dewdrop, other, EnemyStatuses.DAMP, 1, dewdrop.get_damage())  # (setup credit 2026-10-16)
					soaked.append(other)
			if not soaked.is_empty():
				source.set_meta(LAP_META, now() + LAP_EVERY)
				Reactions._effect(&"landing_dust", enemy.global_position, self, 0.6)
				for other in soaked:
					_line_fx(body(enemy), body(other), 1.0, Palette.DEWLIGHT)
				credit(EVO_LAPPING, enemy.global_position, source)
				_ripple_extras(enemy, w, soaked)
	if evo(EVO_REFLECTION) and living(enemy) and now() >= float(source.get_meta(MIRROR_META, -INF)):
		var last = _back_in(w, enemy)
		if last != null:
			source.set_meta(MIRROR_META, now() + MIRROR_EVERY)
			_line_fx(body(enemy), body(last), 2.0, Palette.DEWLIGHT)
			Reactions._effect(&"landing_dust", last.global_position, self, 0.5)
			calling_strike(source, last, float(event.base) * MIRROR_SHARE, MIRROR_TAG, false, EVO_REFLECTION)  # (own: setup credit 2026-10-16)
			credit(EVO_REFLECTION, last.global_position, source)

# Riverside / Open Water (rebuilt 2026-10-23): a status another family's Warden (Sprouts count, Dewdrops never) just put on a
# nightmare in water lasts SIDE_SECONDS longer when the Warden is on that water's bank (Wide Banks: 2 cells), or anywhere
# with Open Water. EnemyStatuses.linger_calling: the Calling's room (Poisoned / Exposed / Charged share it with the lent
# cards). Every landing; the room bounds it. Never Drowsy or Held (can_linger).
func _evo_status(tower, enemy, status: StringName) -> void:
	var w := water_of(enemy)
	if w < 0 or not EnemyStatuses.can_linger(status) or not evo(EVO_RIVERSIDE):
		return
	if is_own(tower):
		# Final pass 2026-10-24 (owner pick: as drafted): a Dewdrop's own Soaked landing on a nightmare in water lasts
		# SIDE_DAMP_SECONDS longer, so Riverside works at drift 5 with no second family (replaces the Sprout part, S1)
		if status == EnemyStatuses.DAMP:
			var wet: float = enemy.statuses.linger_calling(status, SIDE_DAMP_SECONDS)
			SETUP.note_linger(enemy, card_id(EVO_RIVERSIDE), status, wet)
			if wet > 0.0 and now() >= float(enemy.get_meta(SIDE_FX_META, -INF)):
				enemy.set_meta(SIDE_FX_META, now() + SIDE_FX_EVERY)
				credit(EVO_RIVERSIDE, enemy.global_position, tower)
		return
	if not is_other(tower):
		return
	var bank := _on_bank(tower, w)
	if not bank and not evo(EVO_OPEN):
		return
	var row: StringName = EVO_RIVERSIDE if bank else EVO_OPEN
	var side: float = enemy.statuses.linger_calling(status, SIDE_SECONDS)
	SETUP.note_linger(enemy, card_id(row), status, side)  # (setup credit 2026-10-16)
	if side > 0.0 and now() >= float(enemy.get_meta(SIDE_FX_META, -INF)):
		enemy.set_meta(SIDE_FX_META, now() + SIDE_FX_EVERY)
		_line_fx(body(tower), body(enemy), 1.5, Palette.DEWLIGHT)
		Reactions._effect(&"landing_dust", enemy.global_position, self, 0.35)
		credit(row, enemy.global_position, tower)

# Flash Flood: a Dewdrop's splash runs down its whole water, up to FLASH_STEPS each way; every nightmare it reaches (the
# hit one too) walks CAPSTONE_SLOW slower for FLASH_SECONDS (bosses half), each nightmare once a second. No Soaked past 4
# steps: the slow only. The slow is the one Calling slow (_spread_slow reads TIMED_META).
func _flash_flood(enemy, w: int, from: int) -> void:
	var reached: Array = _in_water(w, from, FLASH_STEPS)
	var far := 0
	for other in reached:
		if now() < float(other.get_meta(FLASH_NEXT_META, -INF)):
			continue
		other.set_meta(FLASH_NEXT_META, now() + FLASH_EVERY)
		_set_timed_slow(other, CAPSTONE_SLOW, FLASH_SECONDS, EVO_FLASH)
		far = maxi(far, absi(index_of(other) - from))
	if far > 0 or not reached.is_empty():
		_water_fx(w, from - FLASH_STEPS * 2, from + FLASH_STEPS * 2, 2.0)  # The wave racing down the river
		_wave_crest(from, from + 1)  # Its crest breaking where the splash started (dw_wave_flash)
		credit(EVO_FLASH, enemy.global_position)

# A timed Calling slow (Flash Flood, Sinking Mud): `amount` (bosses half) for `seconds`, kept on TIMED_META; the stronger or
# the later one counts. _spread_slow asks for it each poll through class_kit.calling_slow (one capped slow).
func _set_timed_slow(enemy, amount: float, seconds: float, row: StringName) -> void:
	if not living(enemy):
		return
	amount *= SLOW_BOSS_SHARE if enemy.statuses.is_boss else 1.0
	var was: Array = enemy.get_meta(TIMED_META, [])
	if was.size() >= 3 and float(was[0]) > now() and float(was[1]) > amount:
		return
	enemy.set_meta(TIMED_META, [now() + seconds, amount, row])

# Black Pond: queues this Dewdrop's hit on a pond nightmare; the attack's spill goes out once, at the end of the frame
# (a pulse: its largest hit, onto the pond nightmares it missed).
func _queue_spill(source, enemy, base: float) -> void:
	if base <= 0.0 or not living(enemy):
		return
	var key: int = source.get_instance_id()
	if _spills.is_empty():
		_flush_spills.call_deferred()
	var row: Dictionary = _spills.get(key, {"tower": source, "base": 0.0, "hit": {}, "at": enemy.global_position})
	row.base = maxf(float(row.base), base)
	row.hit[enemy.get_instance_id()] = true
	_spills[key] = row

func _flush_spills() -> void:
	var queued := _spills
	_spills = {}
	if not evo(EVO_POND):
		return
	for key in queued:
		var row: Dictionary = queued[key]
		var tower = row.tower
		if not _tower_ok(tower) or not is_own(tower):
			continue
		var at: Vector2 = row.at
		var targets: Array = _pond_enemies().filter(func(e) -> bool: return not row.hit.has(e.get_instance_id()))
		targets.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(at) < b.global_position.distance_squared_to(at))
		targets = targets.slice(0, SPILL_MAX)
		if targets.is_empty():
			continue
		var amount := _spill_amount(tower, float(row.base))
		var landed := 0
		for other in targets:
			if calling_hit(tower, other, amount, &"pond_spill", EVO_POND, true, false, &"") > 0.0:
				landed += 1
				if tower is Tower and is_instance_valid(other) and not other.is_cleansed:
					tower.spatter(other, true)  # Spattered (section 37): the pond spill is a card splash, 1 stack
		if landed > 0:
			Reactions._effect(&"landing_dust", at, self, 0.8 + 0.2 * landed)  # The ring of spray crossing the pond
			_splashes.append([to_local(at), 0.0])
			if evo(EVO_DEEP_END) and int(tower.rank) > 0:
				credit(EVO_DEEP_END, at, tower)

# One spill: SPILL_SHARE of the hit (event.base: the form x1.4 and the hit cards already in it). Deep End: +3% a rank to
# VII. Deep End and Towering on one Dewdrop add, never multiply (Balancing 2026-10-23): Towering's own bonus is taken out of
# the base and added to the spill's rank bonus instead (25% x (1 + Deep End's rank bonus + Towering's bonus)).
func _spill_amount(tower, base: float) -> float:
	if not evo(EVO_DEEP_END):
		return base * SPILL_SHARE
	var share := SPILL_SHARE + DEEP_END_PER_RANK * mini(int(tower.rank), DEEP_END_TOP_RANK)
	var tall := _towering(tower)
	return base / tall * SPILL_SHARE * (share / SPILL_SHARE + (tall - 1.0))

# Towering's multiplier on this Warden's hits (dream_role_cards.hit_multiplier), 1.0 without it.
func _towering(tower) -> float:
	var roles = dream_state.role_cards if dream_state != null else null
	if roles == null or not roles._on.has(roles.TOWERING) or not roles._towering_set().has(tower.get_instance_id()):
		return 1.0
	return 1.0 + roles.TOWERING_PER_RANK * maxi(int(tower.rank) - roles.TOWERING_FROM_RANK, 0)

# Stagnant Water (from _in_pond, each poll): every status gets back the time it lost since the last poll while the
# nightmare stays in a pond (bosses half). Leaving the pond forgets the record, so time lost outside never comes back.
func _stagnant(enemy) -> void:
	var statuses: EnemyStatuses = enemy.statuses
	var was: Dictionary = enemy.get_meta(STILL_META, {})
	var now_left := {}
	var share := STILL_BOSS_SHARE if statuses.is_boss else 1.0
	var held := false
	for id in statuses.active_ids():
		if not EnemyStatuses.can_linger(id):
			continue
		var left: float = statuses.time_left(id)
		if was.has(id):
			var lost: float = float(was[id]) - left  # Negative after a fresh landing: nothing to give back
			if lost > 0.0:
				var back: float = statuses.linger_calling(id, lost * share)  # F2: the Calling's own cap, on top of the lent cards'
				if back > 0.0:
					SETUP.note_linger(enemy, card_id(EVO_STAGNANT), id, back)  # (setup credit 2026-10-16)
					held = true
					left = statuses.time_left(id)
		now_left[id] = left
	enemy.set_meta(STILL_META, now_left)
	if held and now() >= float(enemy.get_meta(STILL_FX_META, -INF)):
		enemy.set_meta(STILL_FX_META, now() + STILL_FX_EVERY)
		Reactions._effect(&"landing_dust", enemy.global_position, self, 0.4)  # The still water's ripple
		credit(EVO_STAGNANT, enemy.global_position)

# The evolutions' poll: the Calling slow (Spread), the pond (Breaking Wave, Churning Water; an old save's Whirlpool,
# Stagnant Water, Drowned Hands), Support's kept statuses (Still Water, Wet Footprints), footprints drying, Spring Flood.
func _evolutions_poll() -> void:
	if not class_on() or dream_state.calling_path.is_empty():
		return
	_dry_prints()
	_refresh_pond()
	var spread := evo(EVO_STREAM)
	var old_pond := evo(EVO_STAGNANT) or evo(EVO_HANDS)
	var still_on := evo(EVO_STILL)
	var wet_on := evo(EVO_WET)
	if still_on:
		_find_still_waters()
	var fathoms := evo(EVO_FATHOMS)
	var silt := evo(EVO_SILT) and not _silt.is_empty()
	if silt:
		_age_silt()
	for enemy in enemies():
		if not living(enemy):
			continue
		if silt and not enemy.is_flying():
			_silt_step(enemy)  # (Before the slow: its timed slow is read this poll)
		if spread:
			_spread_slow(enemy)
		if enemy.is_flying():
			continue  # Flyers are never in water
		if fathoms:
			_pond_time(enemy)
		if old_pond:
			_in_pond(enemy)
		if still_on:
			_still_water(enemy)
		if wet_on:
			_wet_footprints(enemy)
	if evo(EVO_WAVE):
		_wave_tick()
	if evo(EVO_CHURN):
		_churn_tick()
	if evo(EVO_SPRING):
		_spring_tick()

# Spread's one Calling slow for `enemy` this poll (class_kit.calling_slow; at most CALLING_SLOW_MAX, bosses half): Stream
# 15% in water; Mudflats STEADY_SLOW 20% in water and on mud; the timed slows (Floodgate / Spate / Silt 35%, Sinking Mud's
# flyers 20%, an old save's Flash Flood 30%); Sinking Mud's cling (STEADY_SLOW for CLING_STEPS forward steps after leaving
# water or mud) and an old save's Long Current (its in-water slow for LONG_STEPS) on LONG_META. The strongest counts: one
# request, never a second slow.
func _spread_slow(enemy) -> void:
	var half := SLOW_BOSS_SHARE if enemy.statuses.is_boss else 1.0
	var amount := 0.0
	var row := &""
	var flying: bool = enemy.is_flying()
	var i := -1 if flying else index_of(enemy)
	var in_water := i >= 0 and _water_at.has(i)
	var on_mud := i >= 0 and _mud.has(i) and evo(EVO_MUDFLATS)
	if in_water:
		amount = (STEADY_SLOW if evo(EVO_MUDFLATS) else STREAM_SLOW) * half
		row = EVO_MUDFLATS if evo(EVO_MUDFLATS) else EVO_STREAM
	elif on_mud:
		amount = STEADY_SLOW * half
		row = EVO_MUDFLATS
	if flying and evo(EVO_SINKING):
		var over := nearest_point(enemy.global_position, 0.5)
		if over >= 0 and (_water_at.has(over) or _mud.has(over)):
			_set_timed_slow(enemy, STEADY_SLOW, SINK_SECONDS, EVO_SINKING)  # Refreshed while over it
	elif evo(EVO_SINKING) and i >= 0:
		# Sinking Mud's cling: walking out of water or mud, STEADY_SLOW stays for CLING_STEPS forward steps (re-entering
		# clears it: _entered for water, here for mud)
		var wet := in_water or on_mud
		if wet:
			var held: Array = enemy.get_meta(LONG_META, [])
			if held.size() >= 5 and StringName(held[4]) == EVO_SINKING:
				enemy.remove_meta(LONG_META)
		elif bool(enemy.get_meta(WET_LAST_META, false)):
			enemy.set_meta(LONG_META, [i, STEADY_SLOW * half, bool(enemy.get("passed_waymark")), CLING_STEPS, EVO_SINKING])
		enemy.set_meta(WET_LAST_META, wet)
	var timed: Array = enemy.get_meta(TIMED_META, [])
	if timed.size() >= 3:
		if float(timed[0]) <= now():
			enemy.remove_meta(TIMED_META)
		elif float(timed[1]) > amount:
			amount = float(timed[1])
			row = StringName(timed[2])
	if in_water:
		enemy.set_meta(LAST_SLOW_META, amount)
	elif enemy.has_meta(LONG_META):
		var wake: Array = enemy.get_meta(LONG_META)
		var walked := i - int(wake[0])
		var steps: int = int(wake[3]) if wake.size() >= 5 else LONG_STEPS  # Sinking Mud's cling carries its own steps and row
		if i < 0 or walked < 0 or walked > steps * 2 or bool(enemy.get("passed_waymark")) != bool(wake[2]):
			enemy.remove_meta(LONG_META)  # Past its steps, a lap started again, or the other leg of a Waymark route
		elif float(wake[1]) > amount:
			amount = float(wake[1])
			row = StringName(wake[4]) if wake.size() >= 5 else EVO_LONG
	if amount <= 0.0:
		return
	calling_slow(enemy, amount, row)
	var cap := CALLING_SLOW_MAX * (0.5 if enemy.statuses.is_boss else 1.0)
	enemy.set_meta(SLOW_SEEN_META, [minf(snap5(amount), cap), now()])  # What _apply_calling_slows adds (Heavy Going skips it)
	if now() >= float(enemy.get_meta(SLOW_FX_META, -INF)):
		enemy.set_meta(SLOW_FX_META, now() + SLOW_FX_EVERY)
		credit(row, enemy.global_position)
		if row == EVO_LONG or row == EVO_SINKING:
			Reactions._effect(&"landing_dust", enemy.global_position, self, 0.35)  # The current streaking on / mud dripping

# Breaking Wave: at rank V+ (class_kit.gate_rank: The Old Ones counts), with WAVE_CROWD nightmares in the pond at once, the
# pond's Dewdrop hits each of them (up to WAVE_MAX, furthest along first), at most once every WAVE_COOLDOWN. Damage only
# (class_kit.calling_hit, tag breaker), never a crit or HEAVY. Per-output cap period WAVE_COOLDOWN 4 s (final_check.md D):
# a Dewdrop slower than one attack per 4 s hits for a share. King Tide (final pass 2026-10-24): nightmares on the
# KING_UPSTREAM_STEPS steps before each pond water count toward the crowd, and up to KING_UPSTREAM of them take a wave hit too
# (same call, same period). The boss count and the shell pass are gone (S1).
func _wave_tick() -> void:
	if _pond_dewdrops.is_empty() or now() < _wave_next:
		return
	var dewdrop = _pond_dewdrops[0]
	if not _tower_ok(dewdrop) or gate_rank(dewdrop) < WAVE_RANK:
		return
	var inside := _pond_enemies()
	var king := evo(EVO_KING)
	var queue: Array = _upstream_enemies() if king else []
	if inside.size() + queue.size() < WAVE_CROWD:
		return
	_wave_next = now() + WAVE_COOLDOWN
	inside.sort_custom(func(a, b) -> bool: return index_of(a) > index_of(b))
	for enemy in inside.slice(0, WAVE_MAX):
		calling_hit(dewdrop, enemy, 1.0, &"breaker", EVO_WAVE, true, true, &"", 1.0, WAVE_COOLDOWN)
	if not queue.is_empty():
		queue.sort_custom(func(a, b) -> bool: return index_of(a) > index_of(b))
		for enemy in queue.slice(0, KING_UPSTREAM):
			calling_hit(dewdrop, enemy, 1.0, &"breaker", EVO_KING, true, true, &"", 1.0, WAVE_COOLDOWN)
	for w in _pond_waters:
		_water_fx(int(w), int(waters[int(w)].first), int(waters[int(w)].last), 3.0)  # A white wave crossing the pond
		var wet: Array = (waters[int(w)].points as Dictionary).keys()
		if not wet.is_empty():
			wet.sort()
			_wave_crest(int(wet[wet.size() >> 1]), int(waters[int(w)].last))  # Its crest breaking mid-pond (dw_wave_flash)
		if not queue.is_empty():  # King Tide: the wave runs back up the path against the queue
			var first := int(waters[int(w)].first)
			_water_fx(int(w), first - KING_UPSTREAM_STEPS * 2, first, 2.0)
			_wave_crest(first, maxi(first - 1, 0))

# King Tide: the living walkers on the KING_UPSTREAM_STEPS steps before a pond water's first point (not in water).
func _upstream_enemies() -> Array:
	var out: Array = []
	for enemy in enemies():
		if enemy.is_flying():
			continue
		var i := index_of(enemy)
		if i < 0 or _water_at.has(i):
			continue
		for w in _pond_waters:
			var first := int(waters[int(w)].first)
			if i < first and first - i <= KING_UPSTREAM_STEPS * 2:
				out.append(enemy)
				break
	return out

# Churning Water: while 2 Dewdrops share the pond, every CHURN_EVERY s of drift time its two highest-rank Dewdrops hit up
# to CHURN_MAX nightmares in it (furthest along first, shared between them in turn) for CHURN_SCALE. Damage only; never
# moves a nightmare. With nobody in the pond it waits for the first one.
func _churn_tick() -> void:
	if _pond_dewdrops.size() < 2 or resting():
		return
	_churn_in -= POLL
	if _churn_in > 0.0:
		return
	var inside := _pond_enemies()
	if inside.is_empty():
		_churn_in = 0.0
		return
	_churn_in = CHURN_EVERY
	var two: Array = _pond_dewdrops.duplicate()
	two.sort_custom(_pond_order)
	two = two.slice(0, 2)
	inside.sort_custom(func(a, b) -> bool: return index_of(a) > index_of(b))
	var k := 0
	for enemy in inside.slice(0, CHURN_MAX):
		calling_hit(two[k % 2], enemy, CHURN_SCALE, &"churn", EVO_CHURN, true, true, &"", 1.0, CHURN_EVERY)  # Old saves: period 3 s
		k += 1
		Reactions._effect(&"landing_dust", enemy.global_position, self, 0.5)  # The pond swirls white

# --- Final pass 2026-10-24 (evo_fixed_dewdrop.md, final_check.md) -------------------------------------------------------

# Floodgate: a nightmare dispelled in water surges it: every walker in that water walks SURGE_SLOW slower for SURGE_SECONDS
# (_set_timed_slow: bosses half, the one capped Calling slow). Each water at most once every SURGE_COOLDOWN. Spate: the surge
# also runs SPATE_STEPS on down the path past the water (path steps only, never water). Silt: the surged path stays silt for
# SILT_SECONDS; a nightmare stepping onto it walks SURGE_SLOW slower for SILT_SLOW_SECONDS, once per surge.
func _floodgate(enemy) -> void:
	if not is_instance_valid(enemy) or enemy.is_flying() or resting():
		return
	var w := water_of(enemy)
	if w < 0 or w >= waters.size():
		return
	var water: Dictionary = waters[w]
	var key := "%d" % int(water.last)
	if now() < float(_surge_next.get(key, -INF)):
		return
	_surge_next[key] = now() + SURGE_COOLDOWN
	var points := {}
	for i in water.points:
		points[int(i)] = true
	var row: StringName = EVO_FLOODGATE
	if evo(EVO_SPATE):
		row = EVO_SPATE
		for k in range(1, SPATE_STEPS * 2 + 1):
			var j: int = int(water.last) + k
			if j >= _route_px.size():
				break
			points[j] = true
	var seen := {}
	for other in enemies():
		if other.is_flying() or not living(other):
			continue
		var i := index_of(other)
		if i >= 0 and points.has(i):
			_set_timed_slow(other, SURGE_SLOW, SURGE_SECONDS, row)
			seen[other.get_instance_id()] = true
	if evo(EVO_SILT):
		_silt.append({"points": points, "until": now() + SILT_SECONDS, "seen": seen})
	_water_fx(w, int(water.first), int(water.last), 3.0)  # The water heaves white
	if row == EVO_SPATE:
		_water_fx(w, int(water.last), int(water.last) + SPATE_STEPS * 2, 2.0)  # The wave racing on down the path
	_wave_crest(int(water.last), int(water.last) + 1)
	credit(row, enemy.global_position)

func _age_silt() -> void:
	for k in range(_silt.size() - 1, -1, -1):
		if float(_silt[k].until) <= now():
			_silt.remove_at(k)

func _silt_step(enemy) -> void:
	var i := index_of(enemy)
	if i < 0:
		return
	var id: int = enemy.get_instance_id()
	for zone in _silt:
		if zone.points.has(i) and not zone.seen.has(id):
			zone.seen[id] = true
			_set_timed_slow(enemy, SURGE_SLOW, SILT_SLOW_SECONDS, EVO_SILT)
			credit(EVO_SILT, enemy.global_position)
			return

# Fathoms: when a walker entered the pond (leaving it clears the clock).
func _pond_time(enemy) -> void:
	if _is_pond(water_of(enemy)):
		if not enemy.has_meta(POND_SINCE_META):
			enemy.set_meta(POND_SINCE_META, now())
	elif enemy.has_meta(POND_SINCE_META):
		enemy.remove_meta(POND_SINCE_META)

# Fathoms' part for `enemy`: FATHOM_PER for each second it has waded the pond (bosses twice as fast), up to FATHOM_MAX.
func _fathoms_part(enemy) -> float:
	if not enemy.has_meta(POND_SINCE_META):
		return 0.0
	var seconds: float = maxf(now() - float(enemy.get_meta(POND_SINCE_META)), 0.0)
	return minf(FATHOM_MAX, FATHOM_PER * seconds * (2.0 if enemy.statuses.is_boss else 1.0))

# A water's key for River Mouth / Delta / Rapids' once-per-water records: its downstream end, the Waymark leg, the lap (a lap
# restart arms them again; re-entering, pulls and weaving never do).
func _mouth_key(enemy, water: Dictionary) -> String:
	return "%d:%d:%d" % [int(water.last), int(bool(enemy.get("passed_waymark"))), int(enemy.get("laps"))]

# Still Water's bank count: other families' Wardens (counts_as_warden: no Sprouts, no walls).
func _counts_on_bank(tower) -> bool:
	return is_other(tower) and counts_as_warden(tower)

# How many statuses on `enemy` are lingering (EnemyStatuses.is_lingering, the Dew-light rim), Soaked left out (owner pick
# 2026-10-24): River Mouth, Delta and Rapids.
func _lingering_count(enemy) -> int:
	var found := 0
	for id in enemy.statuses.active_ids():
		if id != EnemyStatuses.DAMP and enemy.statuses.is_lingering(id):
			found += 1
	return found

# Still Water: the waters with STILL_WARDENS or more other families' Wardens on their bank (final pass 2026-10-24: Sprouts and
# walls don't count, class_kit.counts_as_warden; Wide Banks: 2 cells).
func _find_still_waters() -> void:
	_still.clear()
	var others: Array = towers().filter(_counts_on_bank)
	for w in waters.size():
		var count := 0
		for tower in others:
			if _on_bank(tower, w):
				count += 1
				if count >= STILL_WARDENS:
					_still[w] = true
					break

# Still Water: on a nightmare in a still water, other families' statuses (no Dewdrop's) get back the time they lost since
# the last poll (bosses half), within the Calling's room (linger_calling: 4 s past landing, Charged 2 s; Poisoned and
# Exposed share it with the lent cards). Each one it keeps is marked kept (Low Tide, the Dew-light bar).
func _still_water(enemy) -> void:
	var w := water_of(enemy)
	if w < 0 or not _still.has(w):
		if enemy.has_meta(STILL_WATER_META):
			enemy.remove_meta(STILL_WATER_META)
		return
	if _keep_running(enemy, STILL_WATER_META, EVO_STILL, STILL_BOSS_SHARE if enemy.statuses.is_boss else 1.0):
		if now() >= float(enemy.get_meta(STILL_FX_META, -INF)):
			enemy.set_meta(STILL_FX_META, now() + STILL_FX_EVERY)
			Reactions._effect(&"landing_dust", enemy.global_position, self, 0.4)
			credit(EVO_STILL, enemy.global_position)

# Wet Footprints: for WET_FOOT_SECONDS after leaving water, other families' statuses don't run down (the same room: the
# owner's ruling keeps Poisoned and Exposed at 4 s past landing). Prints are drawn where it walks (never water).
func _wet_footprints(enemy) -> void:
	if not enemy.has_meta(WET_FOOT_META):
		return
	if float(enemy.get_meta(WET_FOOT_META)) <= now() or water_of(enemy) >= 0:
		enemy.remove_meta(WET_FOOT_META)
		enemy.remove_meta(WET_KEEP_META)
		return
	_keep_running(enemy, WET_KEEP_META, EVO_WET, 1.0)
	var i := index_of(enemy)
	if i >= 0 and not _prints.has(i):
		_prints[i] = now() + PRINT_SECONDS
		queue_redraw()

# Gives every other family's status on `enemy` (no Dewdrop's; never Drowsy or Held) back the time it lost since the last
# poll (x `share`), through linger_calling, and marks it kept. `meta`: the record of last poll's time left. True when any
# time came back.
func _keep_running(enemy, meta: StringName, row: StringName, share: float) -> bool:
	var statuses: EnemyStatuses = enemy.statuses
	var was: Dictionary = enemy.get_meta(meta, {})
	var now_left := {}
	var kept := false
	for id in statuses.active_ids():
		if not EnemyStatuses.can_linger(id) or is_own(statuses.source(id)):
			continue
		var left: float = statuses.time_left(id)
		if was.has(id):
			var lost: float = float(was[id]) - left  # Negative after a fresh landing: nothing to give back
			if lost > 0.0:
				var back: float = statuses.linger_calling(id, lost * share)
				if back > 0.0:
					SETUP.note_linger(enemy, card_id(row), id, back)
					statuses.mark_kept(id)
					kept = true
					left = statuses.time_left(id)
		now_left[id] = left
	enemy.set_meta(meta, now_left)
	return kept

# Footprints dry after PRINT_SECONDS.
func _dry_prints() -> void:
	if _prints.is_empty():
		return
	for i in _prints.keys():
		if float(_prints[i]) <= now():
			_prints.erase(i)
	queue_redraw()

# An old save's pond rows (Whirlpool, Stagnant Water, Drowned Hands; retired 2026-10-23). Black Pond's slow is gone (S1).
func _in_pond(enemy) -> void:
	var w := water_of(enemy)
	if not _is_pond(w):
		if enemy.has_meta(STILL_META):
			enemy.remove_meta(STILL_META)  # Stagnant Water: out of the pond, its statuses run down again
		return
	var key := _water_key(waters[w])
	if evo(EVO_STAGNANT):
		_stagnant(enemy)
	if evo(EVO_HANDS) and living(enemy) and _status_count(enemy) >= HANDS_STATUSES \
			and not enemy.get_meta(ONCE_META, {}).has("hands:" + key):
		_drowned_hands(enemy, w, key)

func _status_count(enemy) -> int:
	var found := 0
	for id in enemy.statuses.active_ids():
		if id != EnemyStatuses.HELD:
			found += 1
	return found

# Whirlpool's trigger (non-status builds, owner 2026-10-19): a Dewdrop's WHIRL_HITS-th hit on a nightmare in a pond pulls
# it, once per pond and nightmare (was: reaching full Soak there).
func _whirl_hit(enemy, w: int) -> void:
	var key := _water_key(waters[w])
	if enemy.get_meta(ONCE_META, {}).has("whirl:" + key):
		return
	var hits: Dictionary = enemy.get_meta(WHIRL_META, {})
	hits[key] = int(hits.get(key, 0)) + 1
	enemy.set_meta(WHIRL_META, hits)
	if int(hits[key]) >= WHIRL_HITS:
		_whirlpool(enemy, w, key)

# Whirlpool: pulled back 2 steps (never bosses or flyers: the caller checks). Drowning Deep drags its neighbours too.
func _whirlpool(enemy, w: int, key: String) -> void:
	var pixels := PULL_STEPS * cell()
	var pulled: float = enemy.push_back(pixels)
	if pulled <= 0.0:
		return  # Nothing moved: the pond's once is kept for a later try (council full_review 2026-10-17)
	_once(enemy, "whirl:" + key)
	SETUP.control_pull(dream_state, card_id(EVO_WHIRLPOOL), enemy, pulled)  # (setup credit 2026-10-16)
	Reactions._effect(&"landing_dust", enemy.global_position, self, 1.0)
	credit(EVO_WHIRLPOOL, enemy.global_position)
	dream_state.role_cards.pulled_back(null, enemy)  # Homesick hears this pull too (it counts as the pull role, 0104c4d7)
	if evo(EVO_DEEP):
		_drowning_deep(enemy, w, pixels)

# Drowning Deep: up to 4 nightmares within 1 cell are dragged with it (never bosses or flyers), and every Warden touching
# the pond hits the pulled one once, free (the one free-hit rule: once a second per Warden).
func _drowning_deep(enemy, w: int, pixels: float) -> void:
	var reach := DEEP_CELLS * cell()
	var dragged := 0
	for other in Tower.nightmares_near(get_tree(), enemy.global_position, reach):
		if dragged >= DEEP_MAX:
			break
		if other == enemy or not living(other) or other.statuses.is_boss or other.is_flying() \
				or other.global_position.distance_to(enemy.global_position) > reach:
			continue
		var dragged_px: float = other.push_back(pixels)
		if dragged_px > 0.0:
			SETUP.control_pull(dream_state, card_id(EVO_DEEP), other, dragged_px)  # (setup credit 2026-10-16)
			dragged += 1
			dream_state.role_cards.pulled_back(null, other)  # (Homesick)
			_line_fx(body(enemy), body(other), 2.0, Palette.DEWLIGHT)
	var hits := 0
	for tower in (waters[w].dewdrops as Array) + _bank_of(w):
		if _tower_ok(tower) and calling_free_hit(tower, enemy, 1.0, FREE_HIT_TAG, INF, EVO_DEEP):  # (own: setup credit 2026-10-16)
			hits += 1
	if dragged > 0 or hits > 0:
		Reactions._effect(&"landing_dust", enemy.global_position, self, 1.6)
		credit(EVO_DEEP, enemy.global_position)

# Drowned Hands: Held by the pond's strongest Dewdrop (bosses half), once per pond (only spent when it holds).
func _drowned_hands(enemy, w: int, key: String) -> void:
	var dewdrop = _strongest(waters[w].dewdrops)
	if dewdrop == null:
		return
	var boss: bool = enemy.statuses.is_boss
	dewdrop.hold(enemy, HANDS_HOLD * (0.5 if boss else 1.0))
	if living(enemy) and enemy.statuses.is_held():
		control(EVO_HANDS, HANDS_HOLD * (0.5 if boss else 1.0))  # (setup credit 2026-10-16)
		_once(enemy, "hands:" + key)
		Reactions._effect(&"landing_dust", enemy.global_position, self, 1.2)
		credit(EVO_HANDS, enemy.global_position)

# Spring Flood: every 10 s of drift time the longest water with a nightmare in it floods: up to 8 in it are fully Soaked
# (by its strongest Dewdrop) and walk 25% slower for 2 s (bosses half). With nobody in water it waits for the first one.
func _spring_tick() -> void:
	if resting():
		return
	_spring_in -= POLL
	if _spring_in > 0.0:
		return
	var inside := {}  # Water -> nightmares in it
	for enemy in enemies():
		var w := water_of(enemy)
		if w >= 0 and int(_water_at.get(index_of(enemy), -1)) == w:  # Real water only (wet steps aren't a water's length)
			if not inside.has(w):
				inside[w] = []
			inside[w].append(enemy)
	var best := -1
	for w in inside:
		if best < 0 or float(waters[int(w)].steps) > float(waters[best].steps):
			best = int(w)
	if best < 0:
		_spring_in = 0.0
		return
	_spring_in = SPRING_EVERY
	var dewdrop = _strongest(waters[best].dewdrops)
	var targets: Array = inside[best]
	targets.sort_custom(func(a, b) -> bool: return index_of(a) > index_of(b))
	for enemy in targets.slice(0, SPRING_MAX):
		var room: int = enemy.statuses.get_max_stacks(EnemyStatuses.DAMP) - enemy.statuses.stacks(EnemyStatuses.DAMP)
		if room > 0 and dewdrop != null:
			calling_apply(EVO_SPRING, dewdrop, enemy, EnemyStatuses.DAMP, room, dewdrop.get_damage())  # (setup credit 2026-10-16)
		if living(enemy):
			var boss: bool = enemy.statuses.is_boss
			HelperCommons.slow(enemy, SPRING_SLOW * (0.5 if boss else 1.0), SPRING_SECONDS)
			control_slow(EVO_SPRING, SPRING_SLOW * (0.5 if boss else 1.0), SPRING_SECONDS)
			Reactions._effect(&"landing_dust", enemy.global_position, self, 0.6)
	_water_fx(best, int(waters[best].first), int(waters[best].last), 2.0)
	credit(EVO_SPRING, _route_px[int(waters[best].first)])

# --- Statuses from another family's Wardens -----------------------------------------------------------------------------

# {status: [stacks, potency, line, WeakRef]} for every status on `enemy` whose Warden is another family's (never
# Soaked, never Rooted).
func _other_statuses(enemy) -> Dictionary:
	var out := {}
	var statuses: EnemyStatuses = enemy.statuses
	for id in statuses.active_ids():
		if id == EnemyStatuses.DAMP or id == EnemyStatuses.HELD:
			continue
		var source = statuses.source(id)
		if is_other_family(source):
			out[id] = [statuses.stacks(id), statuses.potency(id), source.tower_data.line, weakref(source), statuses.time_left(id)]
	return out

# Puts `stacks` of `id` on `enemy` (a carried status: not a native application, never above the limit, Charged one
# short of a bolt). A status that is there gains quietly; one that ended comes back for `seconds`.
func _give(enemy, id: StringName, stacks: int, row: Array, seconds: float) -> void:
	if stacks <= 0 or not living(enemy) or id == EnemyStatuses.HELD:
		return
	var statuses: EnemyStatuses = enemy.statuses
	if statuses.has(id):
		statuses.add_quiet(id, stacks)
		return
	var cap: int = statuses.get_max_stacks(id)
	if id == EnemyStatuses.STATIC:
		cap -= 1
	stacks = mini(stacks, cap)
	if stacks <= 0:
		return
	var source = row[3].get_ref() if row[3] is WeakRef else null
	enemy.apply_status(id, stacks, seconds, float(row[1]), 0, String(row[2]), source if is_instance_valid(source) else null)

# The Water Remembers: every status from another family's Warden that wore off since it left comes back (never above
# what it carried when it left; one that had ended comes back with 3 s).
func _remember(enemy, dewdrop_id: String) -> void:
	var left: Dictionary = enemy.get_meta(LEFT_META, {})
	var snapshot: Dictionary = left.get(dewdrop_id, {})
	var any := false
	for id in snapshot:
		var lost: int = int(snapshot[id][0]) - enemy.statuses.stacks(id)
		if lost > 0:
			_give(enemy, id, lost, snapshot[id], REMEMBERS_SECONDS)
			any = true
	if any:
		Reactions._effect(&"landing_dust", enemy.global_position, self, 0.6)

# Wake Ripple (DreamState.class_status tells us): another family's Warden touching water added its status to a
# nightmare in it: the ripple carries 1 stack to the others within 4 steps in that water (that Warden's own
# application of 1, once a second for each receiver; Charged stops one short of a bolt).
func status_applied(tower, enemy, status: StringName, _stacks: int) -> void:
	if _in_calling_event:
		return  # F1 (f1_spec.md): another family's Calling application changes nothing here
	if rule(CAUGHT_WADING) and status == EnemyStatuses.DAMP and is_own(tower) and living(enemy):
		_caught_wading(tower, enemy)
	if class_on() and not dream_state.calling_path.is_empty() and status != EnemyStatuses.HELD and living(enemy):
		_evo_status(tower, enemy, status)  # Riverside, Stagnant Water
	if not place_on() or not rule(WAKE_RIPPLE) or not is_other_family(tower) or status == EnemyStatuses.HELD or not living(enemy):
		return
	var w := water_of(enemy)
	if w < 0 or not touches_water(tower, w):
		return
	for other in _in_water(w, index_of(enemy), RIPPLE_STEPS, enemy):
		if now() < float(other.get_meta(CARRY_META, -INF)):
			continue
		var statuses: EnemyStatuses = other.statuses
		if status == EnemyStatuses.STATIC and statuses.stacks(status) >= statuses.get_max_stacks(status) - 1:
			continue
		other.set_meta(CARRY_META, now() + RIPPLE_EVERY)
		tower._apply_one_status(other, status, 1, tower.get_damage(), false)

# Caught Wading: when a Dewdrop first Soaks a nightmare, up to 3 other Wardens near that Dewdrop hit it once, free; again
# when it is fully Soaked. Never more than the Dewdrop's own hit; once each per nightmare.
func _caught_wading(dewdrop, enemy) -> void:
	var full := _fully_soaked(enemy)
	if not _once(enemy, "wading_full" if full else "wading"):
		return
	if full:
		_once(enemy, "wading")  # Full at the first touch: the first half is spent too
	var fired := 0
	for tower in towers():
		if fired >= CAUGHT_WARDENS:
			break
		if tower != dewdrop and is_other(tower) and near(tower.global_position, dewdrop.global_position) \
				and free_hit(tower, enemy, 1.0, FREE_HIT_TAG, dewdrop.get_damage(), CAUGHT_WADING):  # (own: setup credit 2026-10-16)
			fired += 1

# Steeped and Pooling (DreamState.class_duration, from Enemy.apply_status: every application counts, carried ones too):
# how much longer this landing lasts. Steeped: +30% from a Warden touching a Dewdrop (a Dewdrop touches itself).
# Pooling: +50% on a nightmare inside two Dewdrops' ranges at once. They add; the extra is at most LINGER_MAX (Charged
# LINGER_MAX_STATIC), never on Rooted or Drowsy. `duration` 0 = the status's default.
# (Waterlogged's old x1.5 at landing is Slow to Dry's poll now: _slow_to_dry.)
func status_duration(source, enemy, status: StringName, duration: float) -> float:
	if not EnemyStatuses.can_linger(status) or not living(enemy):
		return duration
	var share := 0.0
	var steeped: bool = rule(STEEPED) and ((source is Tower and is_instance_valid(source) and source.tower_data.can_attack \
			and (is_own(source) or own_towers().any(func(d) -> bool: return touching(d, source)))) or _ranges_holding(enemy, 2) >= 2)
	if steeped:
		share += STEEPED_SHARE  # One 40%, whichever way it qualifies (Pooling folded in)
	elif rule(POOLING) and _ranges_holding(enemy, 2) >= 2:
		share += POOLING_SHARE  # (Retired 2026-10-16; an old save keeps it)
	if share <= 0.0:
		return duration
	var base := duration if duration > 0.0 else float(EnemyStatuses.DEFAULT_DURATION.get(status, 0.0))
	var extra := minf(base * share, EnemyStatuses.LINGER_MAX_STATIC if status == EnemyStatuses.STATIC else EnemyStatuses.LINGER_MAX)
	if extra <= 0.0:
		return duration
	enemy.statuses.pending_linger[status] = extra  # The badge's lingering look (EnemyStatuses.apply books it)
	# Setup credit 2026-10-16 (Linger, stack-equivalent): the stacks it has (at least 1) x the extra seconds / its default
	SETUP.note(enemy, card_id(STEEPED if steeped else POOLING), status,
		float(maxi(enemy.statuses.stacks(status), 1)) * extra / maxf(float(EnemyStatuses.DEFAULT_DURATION.get(status, 1.0)), 0.1))
	return base + extra

# How many Dewdrops have `enemy` inside their range (stops counting at `enough`).
func _ranges_holding(enemy, enough: int) -> int:
	var found := 0
	for tower in own_towers():
		if tower.global_position.distance_to(enemy.global_position) <= tower.get_range_pixels():
			found += 1
			if found >= enough:
				break
	return found

# Dripping: a nightmare leaving a Dewdrop's range keeps every status it carries 2 s longer (within the linger cap).
func _drip(enemy) -> void:
	var any := false
	for id in enemy.statuses.active_ids():
		var dripped: float = enemy.statuses.linger(id, DRIPPING_SECONDS)
		SETUP.note_linger(enemy, card_id(DRIPPING), id, dripped)  # (setup credit 2026-10-16)
		if dripped > 0.0:
			any = true
	if any:
		Reactions._effect(&"landing_dust", enemy.global_position, self, 0.5)

# EnemyStatuses.status_ran_out (hooked in on_poll for Ebb or Last Drop): Last Drop reads the peak first, then Ebb may
# bring the status back.
func _ran_out(id: StringName, peak: int, source: Node, potency: float, line: String, enemy) -> void:
	_last_drop(id, peak, source, enemy)
	_ebb(id, peak, source, potency, line, enemy)

# Last Drop (owner 2026-10-18, dewdrop_self.md): when Soaked runs out of time, the Warden that added it (a Dewdrop or a
# Warden near one) hits that nightmare for 40% of its hit for each stack it had, up to 3 hits. One new hit (tag
# last_drop, x the adder's Potency; never a Reaction and never a replay). Spent Soaked never ran out, so a
# Reaction that spends it means no drop. Each nightmare once every 6 s (Ebb can bring Soaked back to run out again).
func _last_drop(id: StringName, peak: int, source: Node, enemy) -> void:
	if id != EnemyStatuses.DAMP or peak <= 0 or not rule(LAST_DROP) or not living(enemy):
		return
	if not (source is Tower) or not is_instance_valid(source) or not source.tower_data.can_attack or dewdrop_near(source) == null:
		return
	if now() < float(enemy.get_meta(LAST_DROP_META, -INF)):
		return
	enemy.set_meta(LAST_DROP_META, now() + LAST_DROP_EVERY)
	var amount: float = source.get_damage() * minf(LAST_DROP_SHARE * float(peak), LAST_DROP_HITS)  # Potency comes from EFFECT_TAGS in take_damage (Tower Code 25c686df)
	Reactions._effect(&"landing_dust", enemy.global_position, self, 0.5)  # A single falling drop
	_line_fx(body(source), body(enemy), 1.5, Palette.DEWLIGHT)
	credit(LAST_DROP, enemy.global_position, source)
	strike(source, enemy, amount, LAST_DROP_TAG, false, LAST_DROP)

# Ebb (EnemyStatuses.status_ran_out, hooked in on_poll): a status that runs out of time on a nightmare in a Dewdrop's
# range comes back at half its most stacks for 3 s. Once per status and nightmare; never Rooted or Drowsy. Soaked can
# come back (EnemyStatuses.can_linger(DAMP) is true; Last Drop's 6 s limit covers its second run-out). Charged stops one
# short of a bolt. Spent statuses (a Reaction, a bolt) never ran out, so they never ebb.
func _ebb(id: StringName, peak: int, source: Node, potency: float, line: String, enemy) -> void:
	if not rule(EBB) or not living(enemy) or not EnemyStatuses.can_linger(id) or _ranges_holding(enemy, 1) < 1:
		return
	if not _once(enemy, "ebb:" + String(id)):
		return
	var stacks := maxi(peak / 2, 1)
	if id == EnemyStatuses.STATIC:
		stacks = mini(stacks, enemy.statuses.get_max_stacks(id) - 1)
	if stacks <= 0:
		return
	SETUP.apply(enemy, card_id(EBB), id, stacks, EBB_SECONDS, potency, 0, line, source if is_instance_valid(source) else null)  # (setup credit 2026-10-16)
	if living(enemy):
		enemy.statuses.note_stretched(id, EBB_SECONDS)  # Keyword chips 2026-10-16: a status brought back is Linger (is_lingering)

# Slow to Dry (rule id waterlogged): on a Soaked nightmare near a Dewdrop, another family's status can't run out before
# its Soaked does (it lingers to match, within the linger cap). Polled.
func _slow_to_dry(enemy) -> void:
	if not _soaked(enemy) or strongest_near(enemy.global_position, is_own) == null:
		return
	var statuses: EnemyStatuses = enemy.statuses
	var soaked_left := statuses.time_left(EnemyStatuses.DAMP)
	for id in statuses.active_ids():
		if not EnemyStatuses.can_linger(id) or not is_other_family(statuses.source(id)):
			continue
		var short := soaked_left - statuses.time_left(id)
		if short > POLL:
			SETUP.note_linger(enemy, card_id(WATERLOGGED), id, statuses.linger(id, short))  # (setup credit 2026-10-16)

# Old Rain and Never Quite Dry (DreamState.class_reaction, from Enemy.apply_status): the Reaction check, wrapped.
func around_reaction(enemy, id: StringName, source) -> void:
	if not living(enemy) or enemy.statuses.count() < 2 or strongest_near(enemy.global_position, is_own) == null:
		Reactions.on_status(enemy, id, source)
		return
	var statuses: EnemyStatuses = enemy.statuses
	# Old Rain: the statuses a card is making last longer, read before this check spends them (keyword chips 2026-10-16)
	var was_raining := _old_rain  # (A Reaction's own statuses can run a check inside this one)
	var was_rain_ids := _rain_ids
	if rule(OLD_RAIN):
		_rain_ids = _lingering_ids(statuses)
		_old_rain = was_raining or not _rain_ids.is_empty()
	var before := {}
	if rule(NEVER_DRY) and now() >= float(enemy.get_meta(NEVER_DRY_META, -INF)):
		for status in statuses.active_ids():
			if status != EnemyStatuses.HELD:
				before[status] = [statuses.stacks(status), statuses.potency(status), String(statuses._active[status].get("line", "")),
					statuses.source(status), statuses.time_left(status)]
	Reactions.on_status(enemy, id, source)
	_old_rain = was_raining
	_rain_ids = was_rain_ids
	if before.is_empty() or not living(enemy):
		return
	# Never Quite Dry: the statuses a Reaction spent come back at half the stacks they had (quietly: no new check)
	var back := false
	for status in before:
		var row: Array = before[status]
		var lost: int = int(row[0]) - statuses.stacks(status)
		if lost <= 0:
			continue
		var stacks := maxi(int(row[0]) / 2 - statuses.stacks(status), 0)
		if status == EnemyStatuses.STATIC:
			stacks = mini(stacks, statuses.get_max_stacks(status) - 1 - statuses.stacks(status))
		if stacks <= 0:
			continue
		if statuses.has(status):
			statuses.add_quiet(status, stacks)
		else:
			statuses.apply(status, stacks, maxf(float(row[4]), 1.0), float(row[1]), 0, String(row[2]), row[3] if is_instance_valid(row[3]) else null)
		back = true
	if back:
		enemy.set_meta(NEVER_DRY_META, now() + NEVER_DRY_EVERY)
		Reactions._effect(&"landing_dust", enemy.global_position, self, 0.6)

# Something in the Water (lent): a Dewdrop's splash adds 1, quietly, to each status another family's Warden near it has
# put on that nightmare (at most two statuses; once a second for each Dewdrop; it never starts a status).
func _something(dewdrop, enemy) -> void:
	if now() < float(dewdrop.get_meta(SOMETHING_META, -INF)):
		return
	var added := 0
	var statuses: EnemyStatuses = enemy.statuses
	for id in statuses.active_ids():
		if added >= SOMETHING_STATUSES:
			break
		if id == EnemyStatuses.DAMP or id == EnemyStatuses.HELD:
			continue
		var source = statuses.source(id)
		if is_other_family(source) and near(source.global_position, dewdrop.global_position):
			var got: int = statuses.add_quiet(id, 1)
			setup_quiet(enemy, SOMETHING, id, got)  # (setup credit 2026-10-16)
			if got > 0:
				added += 1
	if added > 0:
		dewdrop.set_meta(SOMETHING_META, now() + 1.0)

# Soaked Through (lent): when a nightmare near a Dewdrop becomes fully Soaked, each Warden of another family near that
# Dewdrop hits it once, free (up to 4; once for each nightmare).
func _soaked_through(enemy) -> void:
	if not _fully_soaked(enemy) or enemy.get_meta(ONCE_META, {}).has("through"):
		return
	var dewdrop = strongest_near(enemy.global_position, is_own)
	if dewdrop == null:
		return
	_once(enemy, "through")
	var fired := 0
	for tower in towers():
		if fired >= SOAKED_THROUGH_WARDENS:
			break
		if is_other_family(tower) and near(tower.global_position, dewdrop.global_position) and free_hit(tower, enemy, 1.0, FREE_HIT_TAG, dewdrop.get_damage(), SOAKED_THROUGH):
			fired += 1

# Run-Off (lent): when a Soaked nightmare is dispelled near a Dewdrop, the statuses on it from another family's Wardens
# wash onto the nearest Soaked nightmare within 2 cells (moved, not copied; it keeps the longer clock).
func _run_off(enemy) -> void:
	if not is_instance_valid(enemy) or not _soaked(enemy) or strongest_near(enemy.global_position, is_own) == null:
		return
	var carried := _other_statuses(enemy)
	if carried.is_empty():
		return
	var at: Vector2 = enemy.global_position
	var target = null
	var best := INF
	for other in enemies():
		if other != enemy and _soaked(other) and near(other.global_position, at) and other.global_position.distance_squared_to(at) < best:
			best = other.global_position.distance_squared_to(at)
			target = other
	if target == null:
		return
	_line_fx(at, body(target), 2.0, Palette.DEWLIGHT)
	for id in carried:
		var row: Array = carried[id]
		var statuses: EnemyStatuses = target.statuses
		if statuses.has(id):
			statuses.add_quiet(id, int(row[0]))
		else:
			_give(target, id, int(row[0]), row, maxf(float(row[4]), 0.5))
		enemy.statuses.remove(id)

# --- What the other systems ask (through DreamState) --------------------------------------------------------------------

# The Calling branch of DreamState.hit_card_multiplier (evo_shared_spec.md 6; direct hits only: Tower skips Pinned / Shatter /
# effects). Every part is per own attack (no per-output cap) and noted with DamageLog.note_card_bonus, so card_cap_factor
# holds it inside the x4 card cap. Final pass 2026-10-24:
# - the pond Dewdrop's own hit on a pond nightmare: Undertow (+UNDERTOW_PER for each spill target short of SPILL_MAX) and
#   Fathoms (+FATHOM_PER a second waded, bosses twice as fast, up to FATHOM_MAX) add; at Fathoms' cap, Crushing Depth makes
#   the hit pass the shell (pierce_coat_once), once a second per nightmare. Neither raises the spill.
# - another family's direct hit (never a Sprout's, which neither takes nor spends it): River Mouth, the first one within
#   MOUTH_STEPS of leaving a water, +MOUTH_PER for each lingering status (not Soaked), up to MOUTH_MAX, once per nightmare per
#   water; Delta, each Warden's first one there; Rapids, the first one on a nightmare in a water's last RAPIDS_STEPS, once per
#   nightmare per water, on top of the mouth's.
# - an old save's Low Tide / Outflow (retired): as built.
func hit_multiplier(tower, enemy, _is_area: bool, _is_crit: bool, combo: StringName) -> float:
	if not class_on() or combo != &"" or not living(enemy) or not (tower is Tower):
		return 1.0
	if is_own(tower):
		return _pond_hit_multiplier(tower, enemy)
	if not is_other(tower):
		return 1.0
	var mouth := 1.0
	if is_other_family(tower) and (evo(EVO_MOUTH) or evo(EVO_DELTA) or evo(EVO_RAPIDS)):
		mouth = _mouth_multiplier(tower, enemy)
	if mouth > 1.0:
		return mouth
	var kept := _kept_count(enemy)
	if evo(EVO_OUTFLOW) and enemy.has_meta(OUT_META):
		enemy.remove_meta(OUT_META)  # Once for each water it leaves, kept statuses or not
		if kept > 0:
			var out := 1.0 + minf(OUTFLOW_PER * kept, OUTFLOW_MAX)
			DamageLog.note_card_bonus(String(EVO_OUTFLOW), out)
			credit(EVO_OUTFLOW, enemy.global_position, tower)
			Reactions._effect(&"landing_dust", enemy.global_position, self, 1.2)  # The big blue splash
			return out
	if evo(EVO_LOW_TIDE) and kept > 0:
		var tide := 1.0 + minf(LOW_TIDE_PER * kept, LOW_TIDE_MAX)
		DamageLog.note_card_bonus(String(EVO_LOW_TIDE), tide)
		credit(EVO_LOW_TIDE, enemy.global_position, tower)
		if now() >= float(enemy.get_meta(LOW_FX_META, -INF)):
			enemy.set_meta(LOW_FX_META, now() + SIDE_FX_EVERY)
			Reactions._effect(&"landing_dust", enemy.global_position, self, 0.6)  # The blue splash
		return tide
	return 1.0

# Undertow, Fathoms and Crushing Depth on the pond Dewdrop's own direct hit on a nightmare in the pond.
func _pond_hit_multiplier(tower, enemy) -> float:
	if _pond_dewdrops.is_empty() or _pond_dewdrops[0] != tower or not _is_pond(water_of(enemy)):
		return 1.0
	var part := 0.0
	var row := &""
	if evo(EVO_UNDERTOW):
		var others := 0
		for other in _pond_enemies():
			if other != enemy:
				others += 1
		var missing := SPILL_MAX - mini(others, SPILL_MAX)
		if missing > 0:
			part += UNDERTOW_PER * missing
			row = EVO_UNDERTOW
	var deep := 0.0
	if evo(EVO_FATHOMS):
		deep = _fathoms_part(enemy)
		if deep > 0.0:
			part += deep
			row = EVO_FATHOMS
	if evo(EVO_CRUSH) and deep >= FATHOM_MAX - 0.0001 and now() >= float(enemy.get_meta(CRUSH_META, -INF)):
		enemy.set_meta(CRUSH_META, now() + CRUSH_EVERY)
		enemy.pierce_coat_once = true  # Spent by this hit's take_damage
		credit(EVO_CRUSH, enemy.global_position, tower)
		Reactions._effect(&"landing_dust", enemy.global_position, self, 1.0)  # The shell cracks under the water line
	if part <= 0.0:
		return 1.0
	DamageLog.note_card_bonus(String(row), 1.0 + part)
	credit(row, enemy.global_position, tower)
	return 1.0 + part

# River Mouth, Delta and Rapids on another family's direct hit (not a Sprout's). 1.0 when none applies.
func _mouth_multiplier(tower, enemy) -> float:
	var i := index_of(enemy)
	if i < 0:
		return 1.0
	var w := _water_at_i(i)
	var row := &""
	if w >= 0 and w < waters.size():
		# Rapids: inside a water's last RAPIDS_STEPS steps
		if evo(EVO_RAPIDS) and int(waters[w].last) - i < RAPIDS_STEPS * 2:
			var key := _mouth_key(enemy, waters[w])
			var seen: Dictionary = enemy.get_meta(RAPIDS_META, {})
			if not seen.has(key):
				seen[key] = true
				enemy.set_meta(RAPIDS_META, seen)
				row = EVO_RAPIDS
	elif enemy.has_meta(MOUTH_WIN_META):
		var win: Array = enemy.get_meta(MOUTH_WIN_META)
		var walked := i - int(win[0])
		if walked < 0 or walked > MOUTH_STEPS * 2 or bool(enemy.get("passed_waymark")) != bool(win[1]):
			enemy.remove_meta(MOUTH_WIN_META)  # Past the window, a lap started again, or the other leg of a Waymark route
		else:
			var key := String(win[2])
			if evo(EVO_DELTA):  # Delta: each Warden's first hit there
				var all: Dictionary = enemy.get_meta(DELTA_META, {})
				var done: Dictionary = all.get(key, {})
				if not done.has(tower.get_instance_id()):
					done[tower.get_instance_id()] = true
					all[key] = done
					enemy.set_meta(DELTA_META, all)
					row = EVO_DELTA
			elif evo(EVO_MOUTH):
				var seen: Dictionary = enemy.get_meta(MOUTH_META, {})
				if not seen.has(key):
					seen[key] = true  # Spent by the first hit there, lingering statuses or not
					enemy.set_meta(MOUTH_META, seen)
					row = EVO_MOUTH
	if row == &"":
		return 1.0
	var count := _lingering_count(enemy)
	if count <= 0:
		return 1.0
	var bonus := 1.0 + minf(MOUTH_PER * count, MOUTH_MAX)
	DamageLog.note_card_bonus(String(row), bonus)
	credit(row, enemy.global_position, tower)
	Reactions._effect(&"landing_dust", enemy.global_position, self, 1.2)  # The big blue splash
	return bonus

# How many statuses on `enemy` the water is keeping (EnemyStatuses.is_kept; never is_lingering).
func _kept_count(enemy) -> int:
	var found := 0
	for id in enemy.statuses.active_ids():
		if enemy.statuses.is_kept(id):
			found += 1
	return found

# Hit bonuses (DreamState.batch_damage_multiplier, from Enemy.take_damage): Old Rain, High Tide, the evolutions' (Stream,
# Black Pond, Riverside), Sodden, and the retired Riptide / Deep Pool for old saves. (Wash Away is shell_multiplier.)
func damage_multiplier(enemy, source, tag: StringName = &"") -> float:
	if not active():
		return 1.0
	var multiplier := 1.0
	# Old Rain (keyword chips 2026-10-16, keyword_chips_td.md 4: reads EnemyStatuses.is_lingering, not age): a Reaction near
	# a Dewdrop that spends a status a card made last longer deals 40% more (its burst). Shatter and Lightning Rod never pass
	# a landing: they read the statuses still on it.
	if tag in REACTION_BURSTS and rule(OLD_RAIN):
		var rain_ids: Array = _rain_ids if _old_rain else _lingering_ids(enemy.statuses)
		if _rain_spends(tag, rain_ids) and (_old_rain or strongest_near(enemy.global_position, is_own) != null):
			multiplier *= OLD_RAIN_BONUS
			DamageLog.note_card_bonus("old_rain", OLD_RAIN_BONUS)  # Card credit (Main Merger df7010bb)
	if not (source is Tower) or not is_instance_valid(source):
		return multiplier
	var hit_like: bool = tag == &"" or _calling_hit()  # F1 (f1_spec.md): another family's Calling output counts as a hit
	if rule(HIGH_TIDE) and hit_like and dewdrop_near(source) != null:
		# High Tide (keyword chips 2026-10-16: every status counts, cap +30%): hits from Wardens near a Dewdrop deal 10% more
		# for each status on the nightmare
		var tide := 1.0 + minf(HIGH_TIDE_PER * enemy.statuses.count(), HIGH_TIDE_MAX)
		multiplier *= tide
		DamageLog.note_card_bonus("high_tide", tide)
	if rule(HEAVY_GOING) and hit_like and walking_slowed(enemy) and (is_own(source) or dewdrop_near(source) != null):
		multiplier *= HEAVY_GOING_BONUS
		DamageLog.note_card_bonus(String(HEAVY_GOING), HEAVY_GOING_BONUS)
		if now() >= float(enemy.get_meta(HEAVY_META, -INF)):  # The dripping trail it counts on
			enemy.set_meta(HEAVY_META, now() + HEAVY_TRAIL_EVERY)
			Reactions._effect(&"landing_dust", enemy.global_position, self, 0.3)
		credit(HEAVY_GOING, enemy.global_position, source)
	if tag == &"" and class_on() and not dream_state.calling_path.is_empty():
		multiplier *= _evo_hit_multiplier(enemy, source)  # Stream, Black Pond, Riverside
	if not _soaked(enemy):
		return multiplier  # Sodden and the older Dewdrop damage cards (retired) read a Soaked nightmare
	if rule(SODDEN) and hit_like and dewdrop_near(source) != null:
		multiplier *= _sodden(enemy, source)
	if tag == &"" and enemy.has_meta(RIP_META):  # Riptide: each Warden near that Dewdrop, its first hit while it wades
		var rip: Dictionary = enemy.get_meta(RIP_META)
		if now() <= float(rip.until) and not rip.done.has(source.get_instance_id()) and near(source.global_position, rip.at):
			rip.done[source.get_instance_id()] = true
			multiplier *= 2.0
			DamageLog.note_card_bonus("riptide", 2.0)
	if not rule(DEEP_POOL) or dewdrop_near(source) == null:
		return multiplier
	if rule(DEEP_POOL) and tag == &"":  # Deep Pool: hits deal +10% for each status it carries besides Soaked (never Rooted)
		var others := 0
		for id in enemy.statuses.active_ids():
			if id != EnemyStatuses.DAMP and id != EnemyStatuses.HELD:
				others += 1
		multiplier *= 1.0 + DEEP_POOL_PER_STATUS * others
		DamageLog.note_card_bonus("deep_pool", 1.0 + DEEP_POOL_PER_STATUS * others)
	return multiplier

# Sodden (owner 2026-10-18, dewdrop_self.md): a hit from a Dewdrop or a Warden near one deals 10% more for each whole
# second the nightmare's Soaked has lasted (EnemyStatuses.age: kept on by anything that keeps Soaked on; reset when it
# runs out), up to +40%. Hits only. The badge pops once when the count reaches the cap.
# F6 (owner 2026-10-18; f1_spec.md): Sodden counts from the nightmare's first Soaked this walk: a gap of SODDEN_GAP s or
# less without Soaked doesn't reset it (so Last Drop and Ebb no longer do). on_poll keeps [start, last time wet].
const SODDEN_GAP := 3.0
const SODDEN_WALK_META := &"pd_sodden_walk"  # On a nightmare: [first Soaked this walk, last time it was Soaked]

func _sodden_walk(enemy) -> void:
	if not _soaked(enemy):
		return
	var walk: Array = enemy.get_meta(SODDEN_WALK_META, [])
	if walk.size() < 2 or now() - float(walk[1]) > SODDEN_GAP:
		walk = [now() - enemy.statuses.age(EnemyStatuses.DAMP), now()]
	else:
		walk[1] = now()
	enemy.set_meta(SODDEN_WALK_META, walk)

# Seconds Sodden counts for `enemy` (it is Soaked now).
func _sodden_seconds(enemy) -> float:
	var walk: Array = enemy.get_meta(SODDEN_WALK_META, [])
	if walk.size() >= 2 and now() - float(walk[1]) <= SODDEN_GAP:
		return maxf(now() - float(walk[0]), enemy.statuses.age(EnemyStatuses.DAMP))
	return enemy.statuses.age(EnemyStatuses.DAMP)

func _sodden(enemy, source) -> float:
	var bonus := minf(SODDEN_PER * floorf(_sodden_seconds(enemy)), SODDEN_MAX)
	if bonus < SODDEN_MAX - 0.0001:
		if enemy.has_meta(SODDEN_META):
			enemy.remove_meta(SODDEN_META)
	elif not enemy.has_meta(SODDEN_META):
		enemy.set_meta(SODDEN_META, true)
		_status_pop(SODDEN, enemy, EnemyStatuses.DAMP)
	if bonus <= 0.0:
		return 1.0
	DamageLog.note_card_bonus(String(SODDEN), 1.0 + bonus)
	credit(SODDEN, enemy.global_position, source)
	return 1.0 + bonus

# Wash Away (revived 2026-10-18, owner: Dewdrops and Wardens near them; Enemy.take_damage asks through
# DreamState.shell_multiplier only while the nightmare has a shell): a hit from a Dewdrop Warden or a Warden near one on a
# Soaked nightmare wears its shell (the blight coat) down twice as fast. The damage through is unchanged until the shell
# breaks. Not bosses. The first hit, before any Soaked, doesn't count. Credited (and a puff) once a second per nightmare.
func shell_multiplier(enemy, source) -> float:
	if not active() or not rule(WASH_AWAY) or not (source is Tower) or not is_instance_valid(source):
		return 1.0
	if enemy.statuses.is_boss or not _soaked(enemy) or dewdrop_near(source) == null:
		return 1.0
	if now() >= float(enemy.get_meta(WASH_FX_META, -INF)):
		enemy.set_meta(WASH_FX_META, now() + WASH_FX_EVERY)
		credit(WASH_AWAY, enemy.global_position, source)  # (The puff is Enemy Code's Dew-light shell chip, c603cf56)
	return WASH_AWAY_SHELL

# Across the Water: any Warden touching water also reaches Soaked nightmares up to 3 steps further along that water
# (never more than 5 cells from it). Adds them to its target list.
func extra_targets(tower, candidates: Array[Node2D]) -> Array[Node2D]:
	if not active() or not rule(ACROSS) or not tower.tower_data.can_attack or dewdrop_near(tower) == null:
		return candidates
	# Across the Water: Wardens near a Dewdrop reach Soaked nightmares up to 1 cell past their range
	var reach: float = tower.get_range_pixels() + ACROSS_EXTRA_CELLS * cell()
	for enemy in Tower.nightmares_near(get_tree(), tower.global_position, reach):
		if not candidates.has(enemy) and living(enemy) and _soaked(enemy) and tower.global_position.distance_to(enemy.global_position) <= reach:
			candidates.append(enemy)
	return candidates

# --- Drawing: the water ---------------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	super._process(delta)
	_tick_water(delta)

func _draw() -> void:
	pass  # The water is drawn by its layers (_ensure_water_nodes): damp band, see-through body, animated surface, wading

# --- Drawing: the water (owner 2026-10-22: "can you make the water looks better") ----------------------------------------
# Water fills the path ribbon's own shape, never wider than the path, with an uneven wet edge (each bank on its own
# noise, narrowing at the ends) and a darker damp band on the path just outside it. Depth: light shallows, broken deeper
# patches down the middle; the body is one drawing in a CanvasGroup shown at WATER_ALPHA, so the path shows through it
# and overlaps never darken. Both static layers redraw only when the water map changes (_water_key). On top, an animated
# surface at WATER_FPS: ripple streaks along the water, moonlight glints, warm reflections of Firefly glows, splash rings and the Calling's ripple running
# along the water. A wading layer above the nightmares puts their feet under the surface, with rings and a V wake.
# Black Pond's water is darker and still. Reduced motion: still water, glints only. Palette colours only.
const USE_PUDDLE_SHEETS := false
const WATER_HALF := 14.0  # Shallows' half width (px): the path ribbon is ~40 px wide
const WATER_DEEP_HALF := 6.0  # The deeper patches' largest half width: broken pools down the middle, never a stripe
const WATER_DEEP_FROM := 0.5  # Deeper where the deep noise is above this (0..1): roughly half the length
const WATER_DEEP_MIX := 0.6  # Deep patches: this far from the shallows' colour toward the deep one, opaque (see-through
# stamps overlapped into beads), so a step darker, not a hole
const WATER_DEEP_SCALE := 1.6  # The deep noise runs this much faster than the edge's: short pools, not long streaks
const WATER_RIM := 1.0  # A thin lighter shallow rim at the wet edge (px)
const WATER_JITTER := 3.0  # The wet edge's wobble (px), each side on its own (owner 2026-10-22 review: no regular scallops)
const WATER_SWAY := 2.0  # The water's middle sways off the route line this far (px), so the two banks differ
const WATER_TAPER := 12.0  # A run's ends narrow over this many px: soft puddle ends, not round caps
const WATER_STEP := 3.0  # Px between stamps along the water (fine enough that no stamp shows)
const DAMP_HALF := 19.0  # The damp band on the path, just outside the water
const WATER_ALPHA := 0.78  # The body: see-through enough for the path's texture (was 0.9: too bright at night)
const DAMP_ALPHA := 0.35
const WATER_FPS := 5.0  # The surface's pixel-art frame rate
const RIPPLE_MARK_EVERY := 3  # About one ripple streak per 3 route points, at a different spot each cycle...
const RIPPLE_FRAMES := 6  # ...each one grows and fades over this many frames
const GLINT_CHANCE := 0.08  # A point glints in a frame with this chance
const REFLECT_CELLS := 1.5  # Firefly glows within this many cells of the water reflect in it
const SPLASH_TIME := 0.5  # A splash ring's life (s)
const PULSE_SPEED := 160.0  # px/s: the Calling's ripple running along the water
const WADE_FPS := 15.0  # The wading layer's redraw rate
var _damp: CanvasGroup
var _body: CanvasGroup
var _damp_art: Node2D
var _body_art: Node2D
var _surface: Node2D
var _wade_copy: BackBufferCopy  # The screen saved after the water, before the nightmares
var _wade_material: ShaderMaterial  # Draws that saved screen (the water over the legs)
var _wade_layer: Node2D  # The wading stands, in the map's y-sort
var _wade_stands := {}  # Nightmare instance id -> its WadeStand
# The saved screen at this pixel: the water as it was under the nightmare.
const WADE_SHADER_CODE := "shader_type canvas_item;\nuniform sampler2D screen : hint_screen_texture, filter_nearest;\nvoid fragment() {\n\tCOLOR = vec4(texture(screen, SCREEN_UV).rgb, COLOR.a);\n}\n"  # (Built per node, never a static: a static Shader crashes at exit)
var _water_map_key := ""  # (_water_key is the Whirlpool's per-water key)
var _surface_frame := -1
var _splashes: Array = []  # [local position, age]
var _pulses: Array = []  # [route index, reach in route points, start time]
var _wade_wait := 0.0
# Calling evolution marks (assets/effects/calling_evo/, class_kit.evo_mark); each falls back to the drawn shape
const ART_MUD := &"dw_mud"
const ART_PRINTS := &"dw_footprints"
const ART_REEDS := &"dw_reeds"
const ART_SHEEN := &"dw_still_sheen"
const ART_WAVE := &"dw_wave_flash"
var _mud_art: Node2D  # Mudflats' mud sheets: on the path layer, under the damp band (only with the dw_mud sheet)
var _reed_layer: Node2D  # Reed Bed's reeds stand in the map's y-sort (only with the dw_reeds sheet)
var _reed_stands := {}  # Vector2i(route index, side) -> its ReedStand
var _reed_key := ""
var _reed_frame := -1

func _exit_tree() -> void:
	for node in [_damp, _body, _surface, _mud_art, _wade_copy, _wade_layer]:
		if is_instance_valid(node) and node.get_parent() != self:
			node.queue_free()  # They live on the path layer, not under this node
	if is_instance_valid(_reed_layer):
		_reed_layer.queue_free()  # It lives in the map, not under this node
	_reed_layer = null
	_reed_stands.clear()

func _ensure_water_nodes() -> void:
	if is_instance_valid(_surface):
		return
	_mud_art = WaterArt.new(self, 4)
	_damp = CanvasGroup.new()
	_damp.self_modulate = Color(1, 1, 1, DAMP_ALPHA)  # multiplier: how dark the damp band is
	_damp_art = WaterArt.new(self, 0)
	_damp.add_child(_damp_art)
	_body = CanvasGroup.new()
	_body.self_modulate = Color(1, 1, 1, WATER_ALPHA)  # multiplier: the body is a little see-through
	_body_art = WaterArt.new(self, 1)
	_body.add_child(_body_art)
	_surface = WaterArt.new(self, 2)
	# The water over wading nightmares' legs (owner 2026-10-24: "can see the nightmares legs so it look weird"): a
	# BackBufferCopy right after the water on the path layer saves the screen as it is before any nightmare is drawn; each
	# wading nightmare's WadeStand (in the map's y-sort, just in front of it: _sync_wading) draws an oval of that saved
	# screen over its legs (WADE_SHADER_CODE), so they are under the water itself, pools and ripples, with no patch to see.
	_wade_copy = BackBufferCopy.new()
	_wade_copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	var shader := Shader.new()
	shader.code = WADE_SHADER_CODE
	_wade_material = ShaderMaterial.new()
	_wade_material.shader = shader
	# Damp, body and surface go on the map's path layer, over its tiles (the trodden lane was drawn over the water, like the
	# Lantern Light glow before it).
	var map = dream_state.get("map_generator") if dream_state != null else null
	var layer: Node2D = map.path_layer if map != null and "path_layer" in map and is_instance_valid(map.path_layer) else self
	for node in [_mud_art, _damp, _body, _surface]:  # Mud first: under the damp band
		layer.add_child(node)
		node.position = layer.to_local(global_position) if layer != self else Vector2.ZERO
	layer.add_child(_wade_copy)  # Last on the path layer: after the water, before anything standing

func _tick_water(delta: float) -> void:
	if not place_on():
		if is_instance_valid(_surface):
			for node in [_mud_art, _damp, _body, _surface]:
				node.visible = false
		if is_instance_valid(_reed_layer):
			_reed_layer.visible = false
		if is_instance_valid(_wade_layer):
			_wade_layer.visible = false
		return
	_ensure_water_nodes()
	for node in [_mud_art, _damp, _body, _surface]:
		node.visible = true
	_sync_reeds()
	var key := _make_water_key()
	if key != _water_map_key:
		_water_map_key = key
		_mud_art.queue_redraw()
		_damp_art.queue_redraw()
		_body_art.queue_redraw()
		_surface.queue_redraw()
	for splash in _splashes:
		splash[1] = float(splash[1]) + delta
	_splashes = _splashes.filter(_splash_alive)
	_pulses = _pulses.filter(_pulse_alive)
	if waters.is_empty() and not _wade_stands.is_empty():
		_sync_wading()  # The water's gone: no one wades
	if waters.is_empty() or get_tree().paused:
		return
	var frame := loop_frame(WATER_FPS, 1000)
	if frame != _surface_frame or not _splashes.is_empty() or not _pulses.is_empty():
		_surface_frame = frame
		_surface.queue_redraw()
	_wade_wait -= delta
	if _wade_wait <= 0.0:
		_wade_wait = 1.0 / WADE_FPS
		_sync_wading()
	else:
		_place_wading()

func _splash_alive(s: Array) -> bool:
	return float(s[1]) < SPLASH_TIME

func _pulse_alive(p: Array) -> bool:
	return (now() - float(p[2])) * PULSE_SPEED < float(p[1]) * cell() * 0.5 + cell()

func _make_water_key() -> String:
	var parts := PackedStringArray([str(_route_px.size()), "mud%d" % _mud.size()])
	for w in waters.size():
		parts.append("%d:%d:%d:%s" % [int(waters[w].first), int(waters[w].last), (waters[w].points as Dictionary).size(), _water_is_deep(w)])
	return ",".join(parts)

# A stable 0..1 number for route index `i` (the wet edge's wobble, glint spots).
static func _hash01(i: int, salt: int = 0) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(salt) * 78.233) * 43758.5453, 1.0)

func _water_is_deep(w: int) -> bool:
	return evo(EVO_POND) and not dream_state.calling_path.is_empty() and _is_pond(w)

# Smooth 0..1 noise along the route: `u` is route index + fraction; two octaves on knots that never line up with the
# route points, so nothing repeats at the points' even spacing.
static func _noise01(u: float, salt: int) -> float:
	var total := 0.0
	for octave in [[1.7, 0.65], [0.63, 0.35]]:
		var x: float = u / float(octave[0]) + float(salt) * 3.1
		var k := floori(x)
		var f := x - float(k)
		f = f * f * (3.0 - 2.0 * f)
		total += lerpf(_hash01(k, salt), _hash01(k + 1, salt), f) * float(octave[1])
	return total

# Stamps along each run every WATER_STEP px: [position, side normal, route u, 0..1 end taper].
func _water_samples(runs: Array) -> Array:
	var out: Array = []
	for run in runs:
		if run.size() == 1:
			out.append([_route_px[int(run[0])], Vector2.UP, float(run[0]), 1.0])
			continue
		var length := 0.0
		for k in range(1, run.size()):
			length += _route_px[int(run[k - 1])].distance_to(_route_px[int(run[k])])
		var walked := 0.0
		for k in range(1, run.size()):
			var a: Vector2 = _route_px[int(run[k - 1])]
			var b: Vector2 = _route_px[int(run[k])]
			var seg := a.distance_to(b)
			if seg <= 0.0:
				continue
			var dir := (b - a) / seg
			var steps := maxi(int(ceil(seg / WATER_STEP)), 1)
			for n in range(0 if k == 1 else 1, steps + 1):
				var t := float(n) / float(steps)
				var s := walked + seg * t
				var taper := clampf(minf(s, length - s) / WATER_TAPER, 0.0, 1.0)
				out.append([a.lerp(b, t), Vector2(-dir.y, dir.x), float(run[k - 1]) + t, sqrt(taper)])
			walked += seg
	return out

# One band along the stamps: each stamp's middle sways off the route line and its radius wobbles, on separate noises, so
# the two banks are uneven and different. `grow` widens the band past the water's own edge (rim, damp band).
func _band(c: CanvasItem, samples: Array, half: float, grow: float, colour: Color, salt: int) -> void:
	for sample in samples:
		var u: float = sample[2]
		var sway: float = (_noise01(u, salt + 40) - 0.5) * 2.0 * WATER_SWAY
		var r: float = (half + (_noise01(u, salt) - 0.5) * 2.0 * WATER_JITTER) * float(sample[3]) + grow
		if r > 0.5:
			c.draw_circle(sample[0] + sample[1] * sway, r, colour)

# The deeper patches: only where the deep noise rises, swelling from nothing, off-centre, so the middle reads as pools
# under the surface rather than a lane.
func _deep_patches(c: CanvasItem, samples: Array, colour: Color) -> void:
	for sample in samples:
		var u: float = float(sample[2]) * WATER_DEEP_SCALE
		var d := _noise01(u, 9)
		if d <= WATER_DEEP_FROM:
			continue
		var r: float = WATER_DEEP_HALF * (d - WATER_DEEP_FROM) / (1.0 - WATER_DEEP_FROM) * float(sample[3])
		var off: float = (_noise01(u, 13) - 0.5) * 2.0 * (WATER_HALF - WATER_DEEP_HALF)
		if r > 1.0:
			c.draw_circle(sample[0] + sample[1] * off, r, colour)

# The layers' drawing (WaterArt calls back here with its own canvas).
func _draw_water_layer(c: CanvasItem, kind: int) -> void:
	match kind:
		0:  # Damp band: the path darkened just outside the water
			for w in waters.size():
				_band(c, _water_samples(_water_runs(waters[w].points)), WATER_HALF, DAMP_HALF - WATER_HALF, Palette.POOL, 1)
		1:  # Body: light shallows, deeper patches down the middle (Black Pond: darker throughout)
			for w in waters.size():
				var samples := _water_samples(_water_runs(waters[w].points))
				var deep := _water_is_deep(w)
				_band(c, samples, WATER_HALF, WATER_RIM, Palette.DEW if deep else Palette.DEWLIGHT, 1)  # The shallow rim
				_band(c, samples, WATER_HALF, 0.0, Palette.POOL if deep else Palette.DEW, 1)
				var shallows: Color = Palette.POOL if deep else Palette.DEW
				_deep_patches(c, samples, shallows.lerp(Palette.NIGHT if deep else Palette.POOL, WATER_DEEP_MIX))
			if not _mud.is_empty() and evo_art_tex(evo_art, ART_MUD) == null:  # Mudflats: brown mud filling the gaps between the waters (not water; the dw_mud sheets in kind 4 when they exist)
				var mud_samples := _water_samples(_water_runs(_mud))
				_band(c, mud_samples, WATER_HALF - 2.0, 0.0, Palette.BARK, 5)
				_deep_patches(c, mud_samples, Palette.ROOT)
		2:
			_draw_water_surface(c)
		3:
			pass  # (The wading marks: now each nightmare's WadeStand)
		4:  # Mudflats: a dw_mud patch on each mud step (two variants by route index), under the damp band
			for i in _mud:
				if int(i) >= 0 and int(i) < _route_px.size():
					evo_mark(c, ART_MUD, _route_px[int(i)], 1.0, false, int(i) % 2)
		5:
			pass  # (The water over the legs: now each nightmare's WadeStand)

func _draw_water_surface(c: CanvasItem) -> void:
	var still: bool = motion_still()
	var frame: int = maxi(_surface_frame, 0)
	var reflect: Array = _glow_spots()
	for w in waters.size():
		var deep := _water_is_deep(w)
		for run in _water_runs(waters[w].points):
			for k in run.size():
				var i := int(run[k])
				var at: Vector2 = _route_px[i]
				# Ripple streaks: short lines along the water that grow, slide a little downstream and fade, each cycle at a
				# new spot (owner 2026-10-22 review: no chevrons, they read as the route arrows). Still water: none.
				if not deep and not still and k + 1 < run.size():
					var cycle := floori(float(frame + i * 5) / RIPPLE_FRAMES)  # Points start their cycles at different frames
					if _hash01(i, cycle * 3 + 21) < 1.0 / RIPPLE_MARK_EVERY:
						var ahead: Vector2 = _route_px[int(run[k + 1])]
						var dir := (ahead - at).normalized()
						var side := Vector2(-dir.y, dir.x)
						var phase := float((frame + i * 5) % RIPPLE_FRAMES) / RIPPLE_FRAMES
						var spot := at.lerp(ahead, _hash01(i, cycle + 22)) + side * (_hash01(i, cycle + 23) - 0.5) * 16.0 + dir * phase * 3.0
						var half_len := 1.0 + 3.0 * sin(phase * PI)
						c.draw_line((spot - dir * half_len).round(), (spot + dir * half_len).round(),
							Color(Palette.DEWLIGHT, 0.4 * sin(phase * PI)), 1.0)
				# Moonlight glints: a pixel or two, a new spot each frame
				var g := _hash01(i, frame * 7 + 11)
				if g < GLINT_CHANCE * (0.5 if deep else 1.0):
					var off := Vector2((_hash01(i, frame + 2) - 0.5) * 18.0, (_hash01(i, frame + 3) - 0.5) * 12.0)
					c.draw_rect(Rect2((at + off).round(), Vector2(2, 1)), Color(Palette.HEARTLIGHT, 0.7 if not deep else 0.45))
				# Firefly glows nearby reflect as soft warm dots
				for glow: Vector2 in reflect:
					if glow.distance_to(at) <= REFLECT_CELLS * cell() and (i % 2) == 0:
						c.draw_circle(at + (glow - at).normalized() * 6.0, 3.0, Color(Palette.GLOW, 0.22))
		if float(waters[w].steps) >= BREAKWATER_STEPS and rule(BREAKWATER):
			c.draw_circle(_route_px[int(waters[w].last)], 6.0, Color(Palette.DEWLIGHT, 0.8))  # Deep water: a wave waits at its end
	for splash in _splashes:  # A Dewdrop's hit in the water
		var s: float = float(splash[1]) / SPLASH_TIME
		c.draw_arc(splash[0], 4.0 + 14.0 * s, 0.0, TAU, 16, Color(Palette.DEWLIGHT, 0.8 * (1.0 - s)), 1.5)
	for pulse in _pulses:  # The Calling's ripple running both ways along the water, as a wave front
		for dirn: int in [-1, 1]:
			_draw_wave_front(c, pulse, dirn)
	for i in _prints:  # Wet Footprints: small wet prints trailing a nightmare out of the water (never water)
		if int(i) < 0 or int(i) >= _route_px.size():
			continue
		var at: Vector2 = _route_px[int(i)]
		var fade := clampf((float(_prints[i]) - now()) / PRINT_SECONDS, 0.0, 1.0)
		if not evo_mark(c, ART_PRINTS, at, fade, false, int(i) % 2):  # dw_footprints, the pair alternating down the path
			c.draw_circle(at + Vector2(-5.0, 0.0), 3.0, Color(Palette.DEW, 0.45 * fade))
			c.draw_circle(at + Vector2(5.0, -4.0), 3.0, Color(Palette.DEW, 0.45 * fade))
	var reed_art: bool = evo_art_tex(evo_art, ART_REEDS) != null  # With the sheet the reeds stand in the y-sort (_sync_reeds)
	for i in _reeds:  # Reed Bed: reeds where a wall or Sprout carries the water
		if reed_art or int(i) >= _route_px.size():
			continue
		var at: Vector2 = _route_px[int(i)]
		var sway := 0.0 if still else sin(now() * 2.0 + float(i)) * 1.5
		for side in [-1.0, 1.0]:
			var foot: Vector2 = at + Vector2(side * 15.0, 4.0)
			c.draw_line(foot, foot + Vector2(sway, -9.0), Color(Palette.MOSS, 0.85), 1.0)
			c.draw_line(foot + Vector2(2.0, 0.0), foot + Vector2(2.0 + sway, -6.0), Color(Palette.SPRIG, 0.7), 1.0)
	for w in _still:  # Still Water: the water turns glassy (dw_still_sheen, each point a frame apart so they don't march in step)
		if int(w) < waters.size():
			for i in waters[int(w)].points:
				if int(i) % 2 == 0 and not evo_mark(c, ART_SHEEN, _route_px[int(i)], 1.0, false, -1, int(i) >> 1):
					c.draw_line(_route_px[int(i)] + Vector2(-8.0, -2.0), _route_px[int(i)] + Vector2(8.0, -2.0), Color(Palette.MOONLIGHT, 0.3), 1.0)
	if evo(EVO_RIVERSIDE):  # Riverside: a dewdrop mark at the base of every Warden that counts
		for tower in _support_marks():
			var base: Vector2 = c.to_local(tower.global_position) + Vector2(0.0, 22.0)
			c.draw_circle(base, 3.0, Color(Palette.DEWLIGHT, 0.85))
			c.draw_circle(base + Vector2(0.0, -2.0), 1.5, Color(Palette.DEWLIGHT, 0.85))

# The Wardens Riverside counts (another family's, Sprouts too, on a water's bank; Wide Banks: 2 cells). Open Water's
# back-row Wardens show theirs as their statuses land (the thread and puff in _evo_status).
func _support_marks() -> Array:
	var out: Array = []
	for tower in towers():
		if not is_other(tower):
			continue
		for w in waters.size():
			if _on_bank(tower, w):
				out.append(tower)
				break
	return out

# The Calling's ripple running one way (`dirn`) along the water from a Dewdrop's hit (owner 2026-10-24: "redraw the
# Dewdrop splash ripple so it reads as a wave running along the water, not circles"; it was a 5 px ring jumping step to
# step, which read as rings on the ground). A surge of lighter water lying along the flow, foam on its back; it glides
# between route points and fades as it nears the end of its reach. Stops where the water stops.
const WAVE_LONG := 15.0  # The surge's length along the flow
const WAVE_WIDE := 5.0  # Its width across (about 3:1)
const WAVE_SWELL := 0.6  # Its extra size as it leaves the hit, gone over its first route step

func _draw_wave_front(c: CanvasItem, pulse: Array, dirn: int) -> void:
	var step_px := cell() * 0.5
	var t: float = (now() - float(pulse[2])) * PULSE_SPEED / step_px  # Route points travelled
	var reach := float(pulse[1])
	if t >= reach:
		return
	var from := int(pulse[0])
	var k := int(floor(t))
	var a_i := from + dirn * k
	var b_i := from + dirn * (k + 1)
	if a_i < 0 or b_i < 0 or a_i >= _route_px.size() or b_i >= _route_px.size():
		return
	if not _water_at.has(a_i) or not _water_at.has(b_i):
		return  # The water ends here
	var a: Vector2 = _route_px[a_i]
	var b: Vector2 = _route_px[b_i]
	var at := a.lerp(b, t - float(k))
	var dir := (b - a).normalized()
	if dir == Vector2.ZERO:
		return
	var across := Vector2(-dir.y, dir.x)
	var life := clampf(1.0 - t / reach, 0.0, 1.0)
	var fade := minf(life * 2.0, 1.0)  # Full until halfway, then fading out
	# A surge lying along the flow: a lighter lens of water WAVE_LONG long and WAVE_WIDE across, its leading half lit by
	# a foam streak, two thinner streaks beside it (any line spanning the channel, a crest whole, broken or with a band
	# behind, read as ring pieces, seams or brackets at 1x and matched the attack rings, council passes 6-8).
	# It swells as it leaves the hit, then thins as it glides (so it reads as a pulse from the hit, not the water's idle
	# glints, council pass 9).
	var grow := 1.0 + WAVE_SWELL * clampf(1.0 - t, 0.0, 1.0)
	var long := WAVE_LONG * grow
	var wide := WAVE_WIDE * grow
	var lens := PackedVector2Array()
	for n in 12:
		var ang := TAU * n / 12.0
		lens.append((at + dir * cos(ang) * long * 0.5 + across * sin(ang) * wide * 0.5).round())
	c.draw_colored_polygon(lens, Color(Palette.DEWLIGHT, 0.5 * fade))
	# Foam along its middle, brightest at the front (a foam cap across its nose drew ">" arrows: the owner turned down
	# direction chevrons on this water)
	var nose := at + dir * (long * 0.5 - 1.0)
	c.draw_line(_px(nose - dir * long * 0.35), _px(nose), Color(Palette.HEARTLIGHT, 0.85 * fade), 1.0)
	c.draw_line(_px(nose - dir * long * 0.8), _px(nose - dir * long * 0.35), Color(Palette.HEARTLIGHT, 0.4 * fade), 1.0)
	for s: float in [-1.0, 1.0]:
		var side := at + across * s * (wide * 0.5 + 2.0) - dir * 2.0
		c.draw_line(_px(side - dir * long * 0.3), _px(side + dir * long * 0.15), Color(Palette.DEWLIGHT, 0.5 * fade), 1.0)

func _px(p: Vector2) -> Vector2:
	return p.round() + Vector2(0.5, 0.5)


# Where the Firefly glows are (local), for the water's warm reflections.
func _glow_spots() -> Array:
	var out: Array = []
	var lights = dream_state.get("firefly_lights") if dream_state != null else null
	if lights == null or not ("_sources" in lights):
		return out
	for source in lights._sources:
		if source.has("tower") and is_instance_valid(source.tower):
			out.append(to_local(source.tower.global_position))
	return out

# Nightmares wading: their legs under the water, a waterline across the body, rings, a wake while moving.
# (Owner 2026-10-24, screenshot: "can see the nightmares legs so it look weird": a 20x7 patch 5 px over the logical
# position sat mid-body while the legs, drawn below it by the foot lift, showed. A flat-coloured cover at the feet read as
# a pad under each nightmare, art council.) Now the water itself goes over the legs: each wading nightmare has a WadeStand
# in the map's y-sort, just in front of it (so a nightmare lower on screen still draws over it: with all the covers over
# every nightmare, one's water hid its neighbour's body in a bunch, council pass 4). The stand's water part draws an oval
# at the nightmare's real feet (its drawn body position + its foot lift) showing the screen as it was saved just after
# the water was drawn (_wade_copy), before any nightmare: the same water, pools and ripples and all. Its marks part draws
# the waterline, splashes, rings and wake over that.
const WADE_COVER := Vector2(14.0, 5.0)  # The oval over its legs (half sizes, at sprite scale 1): the legs only, a third of a Shade (7.5 sank bodies by the bank to slivers and reached over the bank, council pass 5)
const WADE_DEPTH := 1.5  # The oval's centre this far above the feet: it covers ~6.5 px of legs and the shadow line below
const WADE_META := &"pd_wade_last"  # On a nightmare: where it was at the last wading sync

# Keeps a WadeStand on every wading nightmare (WADE_FPS), in a y-sorted layer in the map: just after the nightmare's
# sprite in the sort (its y + 0.5), so a nightmare lower on screen draws over this one's water.
func _sync_wading() -> void:
	if not is_instance_valid(_wade_layer):
		var map = dream_state.get("map_generator") if dream_state != null else null
		if map == null or not is_instance_valid(map) or not map is Node2D:
			return  # A bare DreamState (tools, some tests): no map to stand in
		_wade_layer = Node2D.new()
		_wade_layer.name = "Wading"
		_wade_layer.y_sort_enabled = true
		map.add_child(_wade_layer)
		_wade_stands.clear()
	_wade_layer.visible = is_visible_in_tree()
	var keep := {}
	if not waters.is_empty():
		for enemy in get_tree().get_nodes_in_group(&"enemies"):
			if not living(enemy) or enemy.is_flying():
				continue
			var w := _drawn_water_of(enemy)
			if w < 0 or _off_water(enemy):
				continue
			var id: int = enemy.get_instance_id()
			keep[id] = true
			var stand: WadeStand = _wade_stands.get(id)
			if stand == null or not is_instance_valid(stand):
				stand = WadeStand.new(self, _wade_material)
				_wade_layer.add_child(stand)
				_wade_stands[id] = stand
			stand.enemy = enemy
			_place_wade(stand)
			stand.deep = _water_is_deep(w)
			stand.ring_phase = float(id % 7) * 0.13
			var last: Vector2 = enemy.get_meta(WADE_META, enemy.global_position)
			enemy.set_meta(WADE_META, enemy.global_position)
			stand.move = enemy.global_position - last
			stand.redraw()
	for id in _wade_stands.keys():
		var held = _wade_stands[id].enemy if is_instance_valid(_wade_stands[id]) else null
		if not keep.has(id) and not waters.is_empty() and is_instance_valid(held) and bool(held.get("is_cleansed")) and held.is_visible_in_tree():
			continue  # Cracking as it's dispelled (out of the enemies group): it stays in the water until it's gone
		if not keep.has(id):
			if is_instance_valid(_wade_stands[id]):
				_wade_stands[id].queue_free()
			_wade_stands.erase(id)

# Puts a WadeStand on its nightmare's feet: every frame (_tick_water), not at WADE_FPS (a stand 4 frames behind a
# nightmare walking down the screen sorted behind its body and showed its legs, council pass 5).
func _place_wade(stand) -> void:
	var enemy = stand.enemy
	if not is_instance_valid(enemy):
		return
	var sprite = enemy.get("sprite")
	var scale: float = absf(sprite.scale.x) if sprite != null else 1.0
	var lift: float = float(enemy.get("_foot_lift")) if enemy.get("_foot_lift") != null else 0.0
	var recoil = enemy.get("_recoil")  # A hit's flinch moves the drawn body (sprite offset only): the water goes with it
	var feet: Vector2 = body(enemy) + Vector2(0.0, lift) + (recoil if recoil is Vector2 else Vector2.ZERO)
	var sort_y: float = (sprite.global_position.y if sprite != null else enemy.global_position.y) + 0.5
	stand.global_position = Vector2(feet.x, sort_y)
	stand.centre = feet - stand.global_position + Vector2(0.0, -WADE_DEPTH * scale)
	stand.half = WADE_COVER * scale

# Its feet past the water's edge, on the bank (an outer walking lane): it isn't wading (a cover there cut its legs off on
# the sand, council pass 5). The edge: WADE_BANK from the route's line, the water's shallows.
const WADE_BANK := 11.0

func _off_water(enemy) -> bool:
	var i := index_of(enemy)
	if i < 0:
		return false
	var lift: float = float(enemy.get("_foot_lift")) if enemy.get("_foot_lift") != null else 0.0
	var feet: Vector2 = body(enemy) + Vector2(0.0, lift)
	var best := INF
	for j in range(maxi(i - 1, 0), mini(i + 1, _route_px.size() - 1)):
		best = minf(best, Geometry2D.get_closest_point_to_segment(feet, _route_px[j], _route_px[j + 1]).distance_to(feet))
	return best > WADE_BANK

func _place_wading() -> void:
	for stand in _wade_stands.values():
		if is_instance_valid(stand):
			_place_wade(stand)

# The water a nightmare stands in AS DRAWN (-1 none): its own route point's, or a neighbour's (the drawn water reaches
# half a step past its last point, round its ends: a nightmare there showed its legs, council pass 4). Visuals only: the
# game's water_of is unchanged.
func _drawn_water_of(enemy) -> int:
	var w := water_of(enemy)
	if w >= 0:
		return w
	var i := index_of(enemy)
	if i < 0:
		return -1
	for d: int in [-1, 1]:
		w = _water_at_i(i + d)
		if w >= 0:
			return w
	return -1

# A WadeStand's two parts: kind 0 the oval of saved water (its shader), kind 1 the marks over it.
func _draw_wade_part(c: CanvasItem, stand, kind: int) -> void:
	var centre: Vector2 = stand.centre
	var half: Vector2 = stand.half
	c.draw_set_transform(centre, 0.0, Vector2(1.0, half.y / half.x))
	if kind == 0:
		c.draw_circle(Vector2.ZERO, half.x, Palette.HEARTLIGHT)  # A mask: its shader draws the saved water there (only the alpha is used)
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var still: bool = motion_still()
	var deep: bool = stand.deep
	var scale: float = half.x / WADE_COVER.x
	c.draw_arc(Vector2.ZERO, half.x * 0.75, PI + 0.6, TAU - 0.6, 14, Color(Palette.DEW if deep else Palette.DEWLIGHT, 0.45), 1.0)  # The waterline, across the body only (0.6 read as domes, council pass 5)
	if not still:
		var ring := fposmod(now() * 1.5 + float(stand.ring_phase), 1.0)
		c.draw_arc(Vector2.ZERO, half.x + 6.0 * ring, PI + 0.5, TAU - 0.5, 16, Color(Palette.DEWLIGHT, 0.35 * (1.0 - ring)), 1.5)  # Trimmed: its ends traced the oval
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for side: float in [-1.0, 1.0]:  # A bright splash where the water meets each side of the body (cold water light)
		c.draw_rect(Rect2((centre + Vector2(side * 9.0 * scale, -half.y * 0.45)).round(), Vector2(1, 1)), Color(Palette.DEWLIGHT, 0.9))
	var move: Vector2 = stand.move
	# No wake walking down the screen: behind it is up, over its own body (council pass 3: an arm ran up through it)
	if not still and move.length() > 0.2 and move.normalized().y < 0.6:
		var back := -move.normalized()
		for s: float in [-1.0, 1.0]:  # A wake: two arms trailing back (one V from its centre read as a ">")
			# Both arms from its back end, low on the water, spreading behind (council: arms from the body's sides went over
			# its back as a slash, or floated under its feet, when it walked sideways)
			var from := centre + back * half.x * 0.8 + Vector2(0.0, s * half.y * 0.4)
			c.draw_line(from, from + back * 6.0 + Vector2(0.0, s * 1.5), Color(Palette.DEWLIGHT, 0.35), 1.0)

# One wading nightmare's water (y-sorted with the nightmares: _sync_wading): the saved water over its legs, then its marks.
class WadeStand extends Node2D:
	var enemy  # Its nightmare
	var centre := Vector2.ZERO  # The oval's centre (local)
	var half := Vector2.ONE
	var deep := false
	var ring_phase := 0.0
	var move := Vector2.ZERO
	var _water: WadePart
	var _marks: WadePart
	func _init(puddles, material: Material) -> void:
		name = "Wading"
		_water = WadePart.new(puddles, self, 0)
		_water.material = material
		add_child(_water)
		_marks = WadePart.new(puddles, self, 1)
		add_child(_marks)
	func redraw() -> void:
		_water.queue_redraw()
		_marks.queue_redraw()

class WadePart extends Node2D:
	var _puddles
	var _stand
	var _kind := 0
	func _init(puddles, stand, kind: int) -> void:
		_puddles = puddles
		_stand = stand
		_kind = kind
	func _draw() -> void:
		if is_instance_valid(_puddles):
			_puddles._draw_wade_part(self, _stand, _kind)

# Reed Bed's reeds (dw_reeds): a clump on each bank of a reed point, its foot where the drawn reeds stood, in a y-sorted
# layer under the MapGenerator (like Spore Print's mushroom Stands) so Wardens and nightmares lower on screen draw in
# front. Without the sheet: no layer, the surface draws the old reed lines.
const REED_BANK := Vector2(15.0, 4.0)  # A clump's foot from its route point (x by side)

func _sync_reeds() -> void:
	var want: bool = not _reeds.is_empty() and evo_art_tex(evo_art, ART_REEDS) != null
	if not want:
		if is_instance_valid(_reed_layer):
			_reed_layer.visible = false
		return
	if not is_instance_valid(_reed_layer):
		var map = dream_state.get("map_generator") if dream_state != null else null
		if map == null or not is_instance_valid(map) or not map is Node2D:
			return  # A bare DreamState (tools, some tests): no map to stand in
		_reed_layer = Node2D.new()
		_reed_layer.name = "Reeds"
		_reed_layer.y_sort_enabled = true
		map.add_child(_reed_layer)
		_reed_stands.clear()
		_reed_key = ""
	_reed_layer.visible = is_visible_in_tree()
	var key := "%d:%d:%d:%s" % [_reeds.hash(), _route_serial, _route_px.size(), global_position]
	if key != _reed_key:
		_reed_key = key
		var keep := {}
		for i in _reeds:
			if int(i) < 0 or int(i) >= _route_px.size():
				continue
			for side in [-1, 1]:
				var id := Vector2i(int(i), side)
				keep[id] = true
				var stand: ReedStand = _reed_stands.get(id)
				if stand == null or not is_instance_valid(stand):
					stand = ReedStand.new(self)
					_reed_layer.add_child(stand)
					_reed_stands[id] = stand
				stand.phase = int(i)
				stand.flip = side < 0
				stand.global_position = to_global(_route_px[int(i)] + Vector2(REED_BANK.x * side, REED_BANK.y))
				stand.queue_redraw()
		for id in _reed_stands.keys():
			if not keep.has(id):
				if is_instance_valid(_reed_stands[id]):
					_reed_stands[id].queue_free()
				_reed_stands.erase(id)
	if get_tree().paused:
		return
	var frame := evo_art_frame(evo_art, ART_REEDS)  # They sway on the sheet's clock (each a frame apart by its phase)
	if frame != _reed_frame:
		_reed_frame = frame
		for id in _reed_stands:
			if is_instance_valid(_reed_stands[id]):
				_reed_stands[id].queue_redraw()

class ReedStand extends Node2D:
	var phase := 0
	var flip := false
	var _puddles
	func _init(puddles) -> void:
		_puddles = puddles
		name = "Reeds"
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # 1x crisp pixels
	func _draw() -> void:
		if is_instance_valid(_puddles):
			_puddles.evo_mark(self, &"dw_reeds", Vector2.ZERO, 1.0, flip, -1, phase)

# Breaking Wave / Flash Flood: a white crest (dw_wave_flash, one shot) on the water's middle at route index `i`, flipped
# when the wave runs right to left (toward route index `toward`). On the ground over the water, under the nightmares.
func _wave_crest(i: int, toward: int) -> void:
	if i < 0 or i >= _route_px.size() or evo_art_tex(evo_art, ART_WAVE) == null:
		return
	var world := Reactions._world(self)
	if world == null:
		return
	var meta := evo_art_meta(evo_art, ART_WAVE)
	var fps := maxf(float(meta.get("fps", 14.0)), 1.0)
	var life := float(maxi(int(meta.get("frames", 1)), 1)) / fps
	var flip: bool = (_route_px[clampi(toward, 0, _route_px.size() - 1)] - _route_px[i]).x < 0.0
	var crest := WaveCrest.new(self, flip, life)
	world.add_child(crest)  # Never under %EnemyContainer
	crest.global_position = to_global(_route_px[i])

# The crest's frame `age` s in (holds its last; reduced motion: frame 0).
func wave_frame(age: float) -> int:
	return evo_art_frame(evo_art, ART_WAVE, age)

class WaveCrest extends Node2D:
	var _puddles
	var _flip := false
	var _life := 0.36
	var _age := 0.0
	var _frame := -1
	func _init(puddles, flip: bool, life: float) -> void:
		_puddles = puddles
		_flip = flip
		_life = life
		name = "WaveCrest"
		z_as_relative = false
		z_index = -1  # With the ground: on the water, under the nightmares
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	func _process(delta: float) -> void:
		_age += delta
		if _age >= _life or not is_instance_valid(_puddles):
			queue_free()
			return
		var frame: int = _puddles.wave_frame(_age)
		if frame != _frame:
			_frame = frame
			queue_redraw()
	func _draw() -> void:
		if is_instance_valid(_puddles):
			_puddles.evo_mark(self, &"dw_wave_flash", Vector2.ZERO, 1.0, _flip, maxi(_frame, 0))

# A water layer: draws through the Puddles node (`kind`: 0 damp, 1 body, 2 surface, 3 wading, 4 mud sheets).
class WaterArt extends Node2D:
	var _puddles
	var _kind := 0
	func _init(puddles, kind: int) -> void:
		_puddles = puddles
		_kind = kind
	func _draw() -> void:
		if is_instance_valid(_puddles):
			_puddles._draw_water_layer(self, _kind)

# A water's wet route points split into runs of neighbours (route indices one apart), in route order.
func _water_runs(points) -> Array:  # (water.points is a Dictionary of route indices; an Array works too)
	var sorted: Array = points.keys() if points is Dictionary else (points as Array).duplicate()
	sorted.sort()
	var runs: Array = []
	var run: Array = []
	for i in sorted:
		if not run.is_empty() and int(i) != int(run[-1]) + 1:
			runs.append(run)
			run = []
		run.append(i)
	if not run.is_empty():
		runs.append(run)
	return runs

# The water's art (Tower Assets cb907eb6): puddle_a-d (48x48, 4 frames, 3 fps, anchor (24, 24) = the route point; the
# variant by route index), every wet point's body first, then every point's puddle_?_shine over them (same variant, same
# frame), so neighbours 32 px apart merge into one pool. Black Pond's water is the same art, darker (POND_TINT).
# 1x draws, frame from the clock, redrawn only when the frame changes (_process). Reduced motion: frame 0 (the still).
const PUDDLE_VARIANTS: Array[StringName] = [&"puddle_a", &"puddle_b", &"puddle_c", &"puddle_d"]
const PUDDLE_SHINES: Array[StringName] = [&"puddle_a_shine", &"puddle_b_shine", &"puddle_c_shine", &"puddle_d_shine"]
const PUDDLE_SIZE := Vector2(48, 48)
const PUDDLE_ANCHOR := Vector2(24, 24)
const PUDDLE_FRAMES := 4
const PUDDLE_FPS := 3.0
const POND_TINT := Color(0.62, 0.62, 0.78)  # multiplier: Black Pond's still, darker water
const SPLASH := &"puddle_ripple"  # The ripple's splash (64x48, 6 frames, 12 fps one-shot, anchor (32, 24))
const SPLASH_STILL := 2  # Reduced motion: this frame alone
const SPLASH_EVERY := 0.5  # At most one splash per nightmare this often (the sheet's length)
const SPLASH_META := &"pd_splash_next"
var _puddle_frame := -1

func _puddle_sheets_ready() -> bool:
	for k in PUDDLE_VARIANTS.size():
		if _fx_sheet(PUDDLE_VARIANTS[k]) == null or _fx_sheet(PUDDLE_SHINES[k]) == null:
			return false
	return true

func _draw_puddle_sheets() -> void:
	_puddle_frame = loop_frame(PUDDLE_FPS, PUDDLE_FRAMES)
	var source := Rect2(Vector2(PUDDLE_SIZE.x * _puddle_frame, 0.0), PUDDLE_SIZE)
	var ponds: bool = evo(EVO_POND) and not dream_state.calling_path.is_empty()
	for pass_shine in 2:
		var sheets: Array[StringName] = PUDDLE_SHINES if pass_shine == 1 else PUDDLE_VARIANTS
		for w in waters.size():
			var tint := POND_TINT if ponds and _is_pond(w) else Color(1, 1, 1)
			for i in waters[w].points:
				var at: Vector2 = _route_px[int(i)]
				draw_texture_rect_region(_fx_sheet(sheets[int(i) % 4]), Rect2((at - PUDDLE_ANCHOR).round(), PUDDLE_SIZE),
					source, tint)  # multiplier (Black Pond)

# The Calling's ripple shows where it starts: puddle_ripple on the hit nightmare, under the nightmares.
func _splash(enemy) -> void:
	if not living(enemy) or now() < float(enemy.get_meta(SPLASH_META, -INF)) or not Fx.on_screen(enemy.global_position):
		return
	enemy.set_meta(SPLASH_META, now() + SPLASH_EVERY)
	_splashes.append([to_local(enemy.global_position), 0.0])  # The drawn splash ring (the sheet below, when it exists, too)
	if Fx.texture(SPLASH) == null:
		return
	var node := Reactions._effect(SPLASH, enemy.global_position, self)
	if node != null:
		node.z_index = -1  # With the ground: the splash lies on the water, under the nightmares
		if motion_still():
			node.set("still", SPLASH_STILL)
