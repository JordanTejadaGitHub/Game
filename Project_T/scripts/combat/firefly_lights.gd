extends Node2D
# Firefly Jar class prototype (documentation/dream_council_review.md section 20; the spec is
# D:\Projects\logs\dream_council\v4_sporeling_firefly.md sections 0 and 11-20; owner direction 2026-10-12).
#
# The family's thing: "damage spreads to other nightmares". The word on the cards is FORK: a damage-only strike that
# adds no status and that nothing triggers from (tag FORK_TAG: every hook here ignores its own forks).
#   Glow       the path within GLOW_CELLS of a Firefly Warden (any light-line form)
#   Lit        a nightmare standing in any glow, flyers too; Lit nightmares can't hide
#   A light    one Firefly Warden's glow; glows sharing a path cell are one light; a lit Sprout is its own light
#   Gold path  path inside two or more Firefly Wardens' glows
# One node per run, made by DreamState (group GROUP). It listens to DamageLog.damage_dealt, so no Warden or nightmare
# code calls it. Forks are queued and struck at the end of the frame: one per nightmare per event (the largest wins),
# at most EVENT_MAX per event, bosses take half. No class_name: DreamState preloads this file.
#
# Every number is a starting point from Balancing's queue. They all live here.

const GROUP := &"firefly_lights"
const FAMILY := "firefly_jar"  # DreamState.calling on a Firefly start
const LINE := "light"  # A Firefly Warden: any form of this line
const FORK_TAG := &"fork"

const GLOW_CELLS := 1.5  # Glow: path within this many cells of a Firefly Warden, plus the range it gained (owner 2026-10-16: lighting was too easy; was 3 / the whole range)
const GLOW_BASE_RANGE := 3.0  # …a Firefly Warden's range beyond this (the Firefly Jar's) adds to its glow
const SPROUT_TOUCH := 1.25  # A lit Sprout's light: the path touching it (the path rule, both axes)
const NEAR_CELLS := 2.0  # "near": within 2 cells on both axes (lent cards)
const CALLING_SHARE := 0.5  # Lantern Light: half the dispelling Warden's hit
const BRIGHTNESS_SECONDS := 3.0  # Another family's fork is capped at this many seconds of the lighting Firefly Warden
const BOSS_SHARE := 0.5  # Bosses take half of any fork
const EVENT_MAX := 6  # Forks one event can throw
const MEET_MAX := 4  # Where Lights Meet: one fork per Firefly Warden lighting the gold path, up to this
const CHAIN_TARGETS := 2  # Chain of Lanterns
const CHAIN_SHARE := 0.5
const HAMMER_SHARE := 0.5  # Hammerfall
const SPOTLIGHT_SHARE := 0.25  # Spotlight
const SPOTLIGHT_MAX := 6
const NEXT_LIGHT_STEPS := 8  # The next light ahead is at most this many steps along the path
const SIGNAL_SHARE := 0.5  # Signal Fires
const SIGNAL_EVERY := 1.0  # ...once for each light each second
const LANTERNWAY_LIGHTS := 3  # Lanternway
const LANTERNWAY_SHARE := 0.5
const AMBUSH_SHARE := 0.5  # Ambush
const SPARK_MAX := 3  # Waiting Spark: sparks that can wait in one light
const SPARK_TIME := 5.0
const LIVE_WIRE_SHARE := 0.5  # Nothing Wasted's Live Wire part: half the hit, per dispel (owner 2026-10-13: never more than the Calling)
const CROSSFIRE_WINDOW := 1.0  # Lent
const CROSSFIRE_TARGETS := 2
const CROSSFIRE_SHARE := 0.5
const CROSSFIRE_WAIT := 3.0
const LIKE_SHARE := 0.5  # Lent: Like to Like
const LIKE_TICK_EVERY := 1.0  # ...ticks and clouds fork once a second per nightmare
const HEAVY_ATTACK_SHARE := 0.8  # A heavy Warden's next hit counts as a new attack after this share of its attack time

# Rule ids of the class cards (UpgradeData.calling = FAMILY) and the lent cards.
const WHERE_LIGHTS_MEET := &"where_lights_meet"
const CHAIN_OF_LANTERNS := &"chain_of_lanterns"
const LAST_SPARK := &"last_spark"
const HAMMERFALL := &"hammerfall"
const KNOCK_ON := &"knock_on"
const SPOTLIGHT := &"spotlight"
const LIT_SPROUTS := &"lit_sprouts"  # Fireflies in the Grass
const SIGNAL_FIRES := &"signal_fires"
const LANTERNWAY := &"lanternway"
const NOTHING_WASTED := &"nothing_wasted"
const AMBUSH := &"ambush"
const WAITING_SPARK := &"waiting_spark"
const LENT_LIVE_WIRE := &"lent_live_wire"
const LENT_CROSSFIRE := &"lent_crossfire"
const LIKE_TO_LIKE := &"like_to_like"
# Lent, 2026-10-14 (lent_noplace_sporeling_firefly.md with dream_council_review.md 26's fixes)
const SPARKS_FLY := &"sparks_fly"
const SPARKS_EVERY_HIT := 3  # Sparks Fly: every 3rd hit a Warden lands on a nightmare…
const SPARKS_WINDOW := 2.0  # …a Firefly Warden hit in the last 2 s…
const SPARKS_SHARE := 0.5  # …jumps on at half
const STRUCK_TWICE := &"struck_twice"  # Struck Twice (self-sufficiency audit 2026-10-18): a jump landing readies the next hit…
const STRUCK_BONUS := 1.3  # …from a Firefly Warden or a Warden near one: 30% more…
const STRUCK_TIME := 2.0  # …for 2 s; one waiting hit per nightmare
const STRUCK_META := &"ff_struck"  # On a nightmare: [time, frame, the jump's source id, WeakRef spark]
const FLASHOVER := &"flashover"
const FLASHOVER_SHARE := 0.5  # Flashover: an area attack on 2+ nightmares jumps half to the nearest one it missed
const FLASHOVER_MIN := 2
const SPARKLERS := ["sparkler", "starburst"]  # Firefly area forms: they count for Flashover beside another Firefly Warden
const THUNDERSTRUCK := &"thunderstruck"
const THUNDER_SHARE := 0.25  # Thunderstruck: a heavy hit on a nightmare with a status fans a quarter to the ones near it with a status…
const THUNDER_MAX := 4  # …up to this many…
const THUNDER_STATIC := 1  # Thunderstruck: each jump adds this many Charged, from the Firefly Warden
const THUNDER_CAP_SECONDS := 1.5  # …the whole fan at most this many seconds of the Firefly Warden near the heavy one
const THUNDER_RECENT := 2.0  # Thunderstruck fans to nightmares hit in the last this many seconds (non-status builds, owner 2026-10-19; was: carrying a status)
const THUNDER_HIT_META := &"ff_any_hit"  # On a nightmare: when any Warden last hit it (only kept while Thunderstruck is held)
const CHAIN_EVERY := 1.0  # Chain of Lanterns: each Firefly Warden's Reactions jump once a second
const CHAIN_META := &"ff_chain_next"  # On a Firefly Warden
const CLASS_KIT := preload("res://scripts/combat/class_kit.gd")  # The shared Reaction list (REACTION_BURSTS)
const SETUP := preload("res://scripts/run/setup_credit.gd")  # Setup credit 2026-10-16: the stack ledger; "credit" on a jump request = its own damage
const BRUSHFIRE := &"brushfire"
const BRUSH_SHARE := 0.5  # Brushfire: half the damage over time of a nightmare a Firefly Warden hit in the last 2 s, each second
const BRUSH_EVERY := 1.0
const BRUSH_TAGS: Array[StringName] = [&"spored", &"cloud", &"fog"]  # Damage over time (not bolts, Reactions or jumps)
const GATHERING_STORM := &"gathering_storm"
const GATHER_STEP := 0.25  # Gathering Storm: each jump a nightmare takes makes the next 25% stronger…
const GATHER_MAX := 3.0  # …up to +200% (owner, hard cards 2026-10-16); the jump's cap stretches with it, never past 3x…
const GATHER_RESET := 2.0  # …reset after 2 s without one
const GATHER_WIDTH_STEP := 1.0  # …each stack draws the jump 1 px thicker…
const GATHER_WIDTH_MAX := 4  # …for at most this many stacks
const CHAIN_REACTIONS: Array[StringName] = [&"thunderclap", &"ignite", &"lightning_rod", &"tempest", &"night_terror"]  # Reactions that spend Charged (Night Terror: 2026-10-17)
const SPARKS_META := &"ff_sparks"  # On a nightmare: {Warden id: hits counted}
const FF_HIT_META := &"ff_firefly_hit"  # On a nightmare: [time, WeakRef]: the last Firefly Warden hit (Sparks Fly)
const SPARKS_FRAME_META := &"ff_sparks_frame"  # On a Warden: the frame its last hit was counted (an area attack counts once)
const GATHER_META := &"ff_gather"  # On a nightmare: [jumps, last time] (Gathering Storm)
const GUIDING_LIGHT := &"guiding_light"  # A general card (needs Lanternmoth), reworked to fork: Firefly spreads damage, never statuses
const GUIDING_SHARE := 0.5
const GUIDING_CELLS: Array[float] = [1.0, 2.0]  # II

# --- Calling evolutions (scripts/combat/calling_paths.gd ids lf_*; rebuilt 2026-10-23, owner: dream_council_review.md 33;
# D:\Projects\logs\dream_council\evo_fixed_firefly.md and evo_shared_spec.md) ------------------------------------------
# Read with evo(id) (the Firefly start with that id on DreamState.calling_path). Spread = damage per glow entered (a % or
# a flare), Focus = forced crits only (no crit chance, never HEAVY), Support = jumps. Every number is a paper starting
# value (Balancing). A FLARE is the one Calling hit (class_kit.calling_hit, tag FLARE_TAG): that Warden's hit, at most one
# second of its damage, no status, no crit, bosses half, and damage only for every other card (R1). Evolution jumps are
# marked "row": damage only too (no note_jump, never an F1 Calling output). Each row shows itself and credits its id.
const FLARE_TAG := &"flare"
const FLARE_META := &"lf_flare_next"  # On a Firefly Warden: its flare clock (Far Lights, Marsh Lights, Lantern Road, Circling Light)
const PART_META := &"lf_part_next"  # …Parting Light's own clock (a Deepen never fires into a spent budget)
const DRAWN_META := &"lf_drawn_next"  # On a touching Warden: Drawn In's clock
const TOUCH_CELLS := 1.0  # Two Wardens touching: centres within 1 cell on both axes (class_kit.touching)
# Spread
const EVO_STRUNG := &"lf_strung_lights"
const STRUNG_PER_GLOW := 0.04  # Strung Lights: direct hits on a nightmare inside a Firefly glow deal 4% more per glow it entered…
const STRUNG_MAX := 0.20  # …up to +20%
const GLOWS_META := &"lf_glows_entered"  # On a nightmare: {light id: [entries, route index it last left at (-1: inside)]}
const LAST_EXIT_META := &"lf_last_exit"  # On a nightmare: the route index where it last left any glow
const FRONT_META := &"lf_front"  # On a nightmare: the furthest route index it reached (steps count forward only)
const STRUNG_PIPS := 5  # Spark pips drawn by the health bar, at most
const EVO_FAR := &"lf_far_lights"
const FAR_STEPS := 6  # Far Lights: a glow entered this many steps after the last one was left flares
const EVO_ROAD := &"lf_lantern_road"
const ROAD_FROM := 4  # Lantern Road: from the 4th glow every entry flares…
const ROAD_SCALE := 2.0  # …at double
const EVO_PARTING := &"lf_parting_light"
const PART_SCALE := 0.5  # Parting Light: leaving a glow from the 4th on flares at half
const EVO_MARSH := &"lf_marsh_lights"
const MARSH_STEPS := 4  # Marsh Lights: walking back into a glow left this many steps before flares…
const MARSH_RETURNS := 4  # …at most this many times per glow and nightmare
const EVO_CIRCLING := &"lf_circling_light"  # On a Marsh return every other remembered glow's Firefly flares too
const EVO_DRAWN := &"lf_drawn_in"
const DRAWN_SCALE := 0.25  # Drawn In: each Warden touching a flaring Firefly flares for a quarter of its own hit
# (Far Lights, Lantern Road, Parting Light, Marsh Lights, Circling Light and Drawn In retired 2026-10-24: code kept for saves.)
# Final pass 2026-10-24 (owner; evo_fixed_firefly.md, final_check.md). Steps here are route points / 2.
# Spread A: a lantern that carries Strung Lights outside glows, fading past each glow and relit in the next.
const EVO_EARLY := &"lf_early_lamps"
const EARLY_GLOWS := 3  # Early Lamps: the 3rd glow entered in the path's first half lights a lantern…
const LANTERN_FADE_STEPS := 20.0  # …that carries Strung Lights outside glows, fading over this many steps past the last glow left
const LANTERN_META := &"lf_lantern"  # On a nightmare: true once it carries one (all its walk; the Waymark keeps it)
const EVO_CARRIED := &"lf_carried_lights"
const CARRIED_PER_GLOW := 0.08  # Carried Lights: on a lantern carrier, Strung Lights is 8% per glow…
const CARRIED_MAX := 0.40  # …up to +40%, inside glows and out (the same fade outside)
const EVO_LATE := &"lf_late_lanterns"
const LATE_GLOWS := 5  # Late Lanterns: the 5th glow entered anywhere lights a lantern too
# Spread B: Firefly-only flares along a streak of separate glows (a flare: period 1 s, class_kit.output_share)
const EVO_ALLEY := &"lf_lantern_alley"
const STREAK_GAP := 4  # Lantern Alley: a glow entered at most this many steps after leaving the streak's last one carries it on…
const ALLEY_STEP := 0.25  # …and flares the nightmare from that glow's Firefly: 25% of its damage per glow in the streak…
const ALLEY_MAX := 1.5  # …up to 150% (FLARE_META: each Firefly once a second)
const STREAK_META := &"lf_streak"  # On a nightmare: {count, last_exit (route index), lights: [light ids], passed}
const STREAK_SEEN_META := &"lf_streak_seen"  # On a nightmare: {light id: true}: each glow counts in one streak per nightmare
const EVO_PARADE := &"lf_lantern_parade"
const PARADE_MIN := 4  # Lantern Parade: when a streak of this many glows ends (not on a dispel)…
const PARADE_BASE := 0.25  # …each of its Fireflies flares the nightmare: 25% of its damage…
const PARADE_PER_FORM := 0.25  # …+25% for each other Firefly form in the streak…
const PARADE_MAX := 1.0  # …at most 100%
const PARADE_CLOCK_META := &"lf_parade_next"  # On a Firefly Warden: Lantern Parade's own clock (never shares Lantern Alley's)
const EVO_PASSED := &"lf_passed_torch"
const PASSED_CELLS := 2.0  # Passed Torch: a nightmare dispelled mid-streak hands it to the nearest walker within 2 cells, once
# Retired 2026-10-23 (never offered; their code stays for an old save's path)
const EVO_TORCH := &"lf_torchbearers"
const RELAY_SHARE := 0.5  # Torchbearers: half the dispelling hit jumps to the nearest Lit nightmare further along the path
const EVO_BALE := &"lf_bale_fires"
const BALE_HOPS := 4  # Bale-fires: a Torchbearers jump that dispels jumps on to the next Lit nightmare ahead, up to this many more
const TORCH_STEPS := 8  # Torchbearers / Bale-fires (hard cards 2026-10-16): "further along" = at most this many steps ahead
const TORCH_CLAIM := 0.25  # …a nightmare just jumped to is skipped for this long, so the fire runs on ahead
const TORCH_CLAIM_META := &"lf_torch_claim"  # On a nightmare: the clock until which Torchbearers skips it
const EVO_GLOWWORMS := &"lf_glowworms"
const GLOW_SPROUTS_PER_JAR := 2  # Glowworms: Sprouts touching each Firefly Warden that glow (nearest the Heartwood first)
const GLOW_SPROUT_TOUCH := 1.25  # …"touching": within this many cells on both axes
const EVO_SWARM := &"lf_swarm_night"
const SWARM_AT := 6  # Swarm Night: while this many nightmares are Lit, every jump jumps once more…
const SWARM_SHARE := 1.0  # …at this share of the jump
const EVO_EMBERS := &"lf_embers"
const EMBER_SHARE := 0.5  # Embers: a dispel on gold path leaves this share of the dispelling hit…
const EMBER_TIME := 4.0  # …for this long…
const EMBER_REACH := 0.6  # …for the next nightmare within this many cells of its step
const EMBER_MAX := 8  # Embers (piles) on the map at once
const EVO_WITCHFIRE := &"lf_witchfire"
const HEARTH_JOIN := 2  # Witchfire: an ember within this many steps of a pile joins it…
const HEARTH_MAX := 3  # …up to this many embers in a pile…
const HEARTH_CELLS := 1.0  # …and the pile bursts on the nightmares within this many cells…
const HEARTH_TARGETS := 6  # …up to this many
# Focus (forced crits: DreamState.calling_crit -> calling_crit here; Tower deals the Warden's own crit multiplier only)
const EVO_BONFIRE := &"lf_bonfire"
const WAIT_META := &"lf_wait_crit"  # On a nightmare: the Firefly Warden (instance id) whose hit on gold path readied a waiting crit
const FORCED_META := &"lf_forced"  # On a Warden: [frame, passes, chain ids, moth bonus, nightmare id] of the crit forced this frame
const GOLD_JARS := 2  # Gold path: inside this many Firefly glows
const EVO_MOTH := &"lf_moth_to_flame"
const MOTH_META := &"lf_moth_crit"  # On a nightmare: [holder Warden id, other direct hits since]
const MOTH_HITS := 4  # Moth to Flame: after this many other hits the kept crit…
const MOTH_BONUS := 1.5  # …deals 50% more
const EVO_PYRE := &"lf_pyre"
const WHITE_JARS := 3  # White path: inside this many Firefly glows
const PYRE_DISPELS := 50  # Pyre / Banked Fire: Wardens with this many gold dispels (final pass 2026-10-24; was rank V+)
const GOLD_COUNTED_META := &"lf_gold_counted"  # On a nightmare: its gold dispel was counted (once)
const PYRE_META := &"lf_pyre_count"  # On a Warden: {"white" / "white_boss" / "gold" / "gold_boss": direct hits counted}
const PYRE_EVERY := 2  # Pyre: every 2nd direct hit on white path crits…
const PYRE_BOSS_EVERY := 3  # …bosses every 3rd
const EVO_BANKED := &"lf_banked_fire"
const BANKED_EVERY := 3  # Banked Fire: every 3rd on gold (not white) path…
const BANKED_BOSS_EVERY := 4  # …bosses every 4th
const EVO_SPREADING := &"lf_spreading_flame"
const SPREAD_GROW_MAX := 4  # Spreading Flame: a crit dispel on gold grows that gold stretch 1 step at each end, up to 4…
const SPREAD_TIME := 20.0  # …for 20 s (refreshed by each one)
const EVO_FLINT := &"lf_flint_and_steel"
const PASS_META := &"lf_pass_crit"  # On a Warden: [passes so far, chain of Warden ids]: its next direct hit on gold path crits
const EVO_TINDERBOX := &"lf_tinderbox"
const TINDER_PASSES := 2  # Tinderbox: a passed crit passes once more (never a fourth Warden)
# Support
const EVO_BORROWED := &"lf_borrowed_light"
const LAMP_SHARE := 0.33  # Borrowed Light: another family's Warden's hit on a Lit nightmare jumps this share (no Sprouts; Fireflies until a second family)…
const LAMP_EVERY := 1.0  # …once a second per Warden
const LAMP_META := &"lf_lamp_next"  # On a Warden
const EVO_WAKE := &"lf_lantern_wake"
const WAKE_PER_JAR := 2  # Lantern Wake: the 2 nearest other families' Wardens (no Sprouts) within WAKE_CELLS of each Firefly glow too…
const WAKE_CELLS := 2.0  # …centre to centre, on both axes (ties: nearest the Heartwood)…
const WAKE_LIT_CELLS := 1.0  # …lighting the path within this many cells of them (final pass 2026-10-24: was touching)
const EVO_SHOW := &"lf_show_the_way"
const SHOW_SHARE := 0.5  # Show the Way: a Borrowed Light jump carries on once more at half (in full from a glowing Warden)
const EVO_FULL_GLOW := &"lf_full_glow"
const FULL_GLOW_TIME := 3.0  # Full Glow: a nightmare hit by a glowing Warden stays Lit this long, anywhere
const LIT_UNTIL_META := &"lf_lit_until"  # On a nightmare: [until, WeakRef glowing Warden, its light id]
const EVO_SIGHT := &"lf_sightline"
const PALE_WARDENS := 3  # Sightline: Lit path in range of this many other families' Wardens (no Sprouts) is pale…
const SIGHT_SHARE := 0.5  # …and Borrowed Light jumps half of a hit there, not a third, to the healthiest other Lit nightmare…
const SIGHT_POOL := 6  # …of the nearest this many (the usual jump reach; final pass 2026-10-24)
const EVO_CONSTELLATION := &"lf_constellation"
const STAR_WARDENS := 3  # Constellation: this many different Wardens hitting one nightmare on pale path…
const STAR_WINDOW := 2.0  # …within this long light a star over it…
const STAR_HITS := 3  # …its next 3 hits jump in full…
const STAR_LOCK := 4.0  # …each nightmare once in this long
const STAR_META := &"lf_star"  # On a nightmare: star charges left
const STAR_ROSTER_META := &"lf_star_roster"  # On a nightmare: {Warden id: time}
const STAR_NEXT_META := &"lf_star_next"
const EVO_NORTH_STAR := &"lf_north_star"
const NORTH_WARDENS := 2  # North Star: a boss or a Deeply Blighted nightmare on any Lit path, from this many Wardens
const MARK_META := &"lf_mark_node"  # On a nightmare: WeakRef to its LanternMark (the drawn flames, pips and star)
const EVENT_MEMORY := 512  # Events whose struck nightmares are remembered (recursive hops land a frame later)

const LIT_SPROUT_META := &"lit_sprout"  # On a Sprout the player chose to glow
const GROUPS_META := &"ff_lights"  # On a nightmare: the lights it stands in (Array of light ids)
const AMBUSH_META := &"ff_ambushed"  # On a nightmare: {light id: true}
const CROSS_META := &"ff_crossfire"  # On a nightmare: the last qualifying hit, for Crossfire
const LIKE_META := &"ff_like_next"  # On a nightmare: when its ticks may fork again (Like to Like)
const HEAVY_META := &"ff_heavy_next"  # On a Warden: when its next hit counts as a new attack

const POLL := 0.1  # Seconds between looks at who is Lit
const REBUILD := 0.5  # Seconds between rebuilds of the light map when nothing told us it changed

var dream_state: Node  # DreamState (untyped: DreamState preloads this script)
var _hooked := false
var _sources: Array = []  # [{tower, sprout: bool, light: int}]
var _glow := {}  # Route cell -> {jars: int, lights: Array}
var _max_lit_step := -1
var _board := -1
var _rebuild_in := 0.0
var _poll_in := 0.0
var _queue: Array = []  # Fork requests waiting for the end of the frame
var _event := 0
var _sparks := {}  # Light id -> Array of {amount, source, until, cap}
var _signal_next := {}  # Light id -> clock
var _base_jar_dps := 0.0
var forks_thrown := 0  # This run (tests and the owner's eye)
var _flashes := {}  # Flashover: Warden id -> {frame, source: WeakRef, hits: Array, base}: one attack's hits, struck next frame
var _brush := {}  # Brushfire: nightmare id -> {enemy: WeakRef, source: WeakRef, amount}: this second's damage over time
var _brush_in := BRUSH_EVERY
var _heavy_now := false  # This event is a new heavy attack (worked out once per event: _new_heavy_attack has a clock)
var saved_sprouts: Array = []  # From the run save (DreamState.load_save); applied once the Wardens are back
var _strung := {}  # (Old Strung Lights' joined gaps: always empty since the 2026-10-23 rebuild; the thread art reads it)
var _light_rep := {}  # Light id -> one source of it (a gap borrows it for brightness)
var _step_px := {}  # Route step -> map position (embers)
var _end_px := Vector2.ZERO  # The route's last step (the Heartwood): Glowworms pick the Sprouts nearest it
var _embers := {}  # Embers / Witchfire: route step -> {amount, cap, source: WeakRef, until, count}
var _lit_count := 0  # Nightmares Lit at the last poll (Swarm Night)
var _lit_by_step: Array = []  # [[step, nightmare], …] Lit walkers at the last poll, sorted by step (Torchbearers, hard cards 2026-10-16)
var _event_seen := {}  # Event id -> {nightmare id: true}: struck by it (EVENT_MAX across a recursive chain)
var _wake_ids := {}  # Lantern Wake: a glowing Warden's instance id -> its source
var _pale := {}  # Sightline: route cell -> true (pale path, cached per rebuild)
var _pale_frame := -1  # Sightline's glint frame last drawn
var _grown := {}  # Spreading Flame: route cell -> true (grown gold, never white)
var _gold_runs: Array = []  # [first step, last step] of each gold stretch (Firefly glows only)
var _gold_grow := {}  # Spreading Flame: a stretch's first step -> [steps grown, until]
var _gold_cells: Array = []  # Gold route cells, grown ones too ("gold path in range", Moth to Flame's holder)
var _moth_holder: WeakRef = null  # Moth to Flame: the Warden with most gold dispels covering gold path (cached per rebuild and gold dispel)
var _moth_last: WeakRef = null  # …the last holder, kept while no candidate has a gold dispel this block
var _gold_block := {}  # Gold dispels (Focus A): Warden instance id -> nightmares it dispelled on gold path this block (reset at rest start)
var _gold_total := {}  # …while it stands (evolving and Nurture keep the node; selling frees it; a Walking Wood swap moves the node)
var saved_gold: Array = []  # From the run save ([cell x, cell y, block, total] rows), applied once the Wardens are back
var _one_family := true  # Borrowed Light's bridge: until the second family pick, Firefly hits count too (worked out per rebuild)
var _wake_from := Vector2.ZERO  # Lantern Wake's sort: the Firefly whose carriers are being picked
var _kit_node: Node2D = null  # A bare class kit: class_kit.calling_hit and the route by steps (flares)

func _ready() -> void:
	add_to_group(GROUP)
	z_index = -1  # With the ground: the glow lies on the path, under Wardens and nightmares
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # The Calling evolution marks: 1x crisp pixels
	var jar: TowerData = load("res://resource/tower/firefly_jar.tres")
	if jar != null:
		_base_jar_dps = jar.damage * jar.attacks_per_second
	if dream_state != null and dream_state.get("drift_director") != null:
		dream_state.drift_director.rest_started.connect(_on_rest.unbind(4))

func _on_rest() -> void:
	_sparks.clear()  # Waiting sparks go out when a rest starts
	_embers.clear()  # So do embers (nothing waits through a rest)
	_gold_block.clear()  # A new block's gold dispels (Moth to Flame's last holder keeps it until someone has one)
	if not _gold_grow.is_empty():
		_gold_grow.clear()  # Spreading Flame's grown gold too
		_rebuild_in = 0.0
	queue_redraw()

# --- Who this is on for -----------------------------------------------------------------------------------------

func class_on() -> bool:
	return dream_state != null and dream_state.calling == FAMILY

func _rule(id: StringName) -> bool:
	return dream_state != null and dream_state.has_rule(id)

# A Calling evolution on the path (DreamState.calling_path): the Firefly start only (as class_kit.evo).
func evo(id: StringName) -> bool:
	return class_on() and dream_state.has_evolution(id)

func _evolved() -> bool:
	return class_on() and not dream_state.calling_path.is_empty()

# A bare class kit (class_kit.gd) made on first use, never processing: the one Calling hit (calling_hit) and the route by
# steps (index_of, split by the Waymark). This node is not a class kit itself (it predates them).
func _kit():  # (Untyped: its methods are the class kit script's)
	if not is_instance_valid(_kit_node):
		_kit_node = CLASS_KIT.new()
		_kit_node.name = "LanternKit"
		_kit_node.set("dream_state", dream_state)
		_kit_node.process_mode = Node.PROCESS_MODE_DISABLED  # Never its own loop: it only lends calling_hit and index_of
		add_child(_kit_node)
	return _kit_node

# A walker's furthest route index so far (-1: a flyer or off the route): steps count forward only (pulls never add).
func _front(enemy) -> int:
	var kit = _kit()
	kit._refresh_route()
	var i: int = kit.index_of(enemy)
	if i < 0:
		return -1
	var front := maxi(int(enemy.get_meta(FRONT_META, -1)), i)
	enemy.set_meta(FRONT_META, front)
	return front

# Two Wardens touching: centres within TOUCH_CELLS on both axes.
func _touching(a, b) -> bool:
	if a == b or not is_instance_valid(a) or not is_instance_valid(b):
		return false
	var reach := TOUCH_CELLS * _cell() + 1.0
	return absf(a.global_position.x - b.global_position.x) <= reach and absf(a.global_position.y - b.global_position.y) <= reach

static func _attacker(tower) -> bool:
	return tower is Tower and is_instance_valid(tower) and tower.tower_data != null and tower.tower_data.can_attack \
		and tower.tower_data.line != "wall"

# Credit an effect to its evolution (DreamState.note_card: callouts and the rest report), as class_kit.credit.
func credit(id: StringName, at: Vector2 = Vector2.INF, source = null) -> void:  # source: the Warden (badge pop; visual feedback spec B5, owner 2026-10-18)
	if dream_state != null:
		dream_state.note_card(id, at, 1, source if is_instance_valid(source) and source is Node else null)

# A thin line between two points for a moment (as class_kit._line_fx).
# The jump line: Tower Assets' calling_thread with a calling_spark at the far end, like the Callings' links (owner
# 2026-10-19: "Firefly try using new thread"); the old ChainBolt only when the sheet is missing.
const LINE_THREAD := &"calling_thread"
const LINE_SPARK := &"calling_spark"
const LINE_SECONDS := 0.3

func _line_fx(from: Vector2, to: Vector2, width: float, color: Color = Palette.HEARTLIGHT) -> void:
	var world := Reactions._world(self)
	if world == null or from.is_equal_approx(to):
		return
	if Fx.texture(LINE_THREAD) == null:
		world.add_child(ChainBolt.new(PackedVector2Array([from, to]), color, width))
		return
	var still := _still()
	var thread := Fx.segment(LINE_THREAD, from, to, world, LINE_SECONDS)
	if thread != null:
		thread.modulate = color  # multiplier: the jump's colour on the warm thread
		if still:
			thread.set("still", 0)
	if Fx.texture(LINE_SPARK) != null:
		var spark := Fx.play(LINE_SPARK, to, world)
		if spark != null:
			spark.modulate = color  # multiplier
			if still:
				spark.set("still", 0)

# Nightmares Lit at the last look (Swarm Night's count; the Calling badge can show "Lit 7/10").
func lit_count() -> int:
	return _lit_count

# Lent cards never give the Calling's setup (owner 2026-10-14, dream_council_review.md 25-26): Lit, the glow, lights and
# gold path are the first pick's only. The lent cards work from Firefly Wardens, where Wardens stand, their attacks and
# Charged; they never read Lit (no sources_at, nearest_lit or is_lit in a lent path).
const LENT_RULES: Array[StringName] = [HAMMERFALL, KNOCK_ON, THUNDERSTRUCK, CHAIN_OF_LANTERNS, NOTHING_WASTED, LENT_CROSSFIRE,
	SPARKS_FLY, FLASHOVER, BRUSHFIRE, GATHERING_STORM, STRUCK_TWICE, LENT_LIVE_WIRE, LIKE_TO_LIKE]  # (Live Wire, Like to Like: retired; old saves)

func _lent_on() -> bool:
	for id in LENT_RULES:
		if _rule(id):
			return true
	return false

# Cards retired or moved to class-only that worked in the light when a later owner could hold them: an old save holding
# one keeps the lights on Continue (the "keep a retired card's effect" convention).
const LEGACY_LIT: Array[StringName] = [SPOTLIGHT, SIGNAL_FIRES]

# Whether the lights are worked out: the Firefly start (or an old save's legacy card).
func _lit_on() -> bool:
	if class_on():
		return true
	for id in LEGACY_LIT:
		if _rule(id):
			return true
	return false

func _cell() -> float:
	return Tower.MAP_GRID.cell_size.x

func _now() -> float:
	return dream_state._game_clock

static func is_firefly(tower) -> bool:
	return tower is Tower and tower.tower_data != null and tower.tower_data.line == LINE and tower.tower_data.can_attack

# "Another family's Warden": not this family, not a Sprout, not a wall.
static func is_other_family(tower) -> bool:
	return tower is Tower and tower.tower_data != null and tower.tower_data.can_attack and tower.tower_data.line != LINE \
		and tower.tower_data.line != "wall" and tower.tower_data.get_id() != "sprout"

# Any other attacking Warden: not this family, not a wall; Sprouts count.
static func is_other(tower) -> bool:
	return tower is Tower and tower.tower_data != null and tower.tower_data.can_attack and tower.tower_data.line != LINE \
		and tower.tower_data.line != "wall"

static func is_heavy(tower) -> bool:
	if not (tower is Tower) or tower.attack_data == null:
		return false
	return bool(tower.attack_data.get("heavy"))  # attack_data: a Graftling follows the form it copies

static func _living(enemy) -> bool:
	return is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and not enemy.is_cleansed and enemy.health > 0

# --- The light map ----------------------------------------------------------------------------------------------

# Perf (Enemy Code's probe6, 2026-10-17): the DamageLog dispatch per damage event cost ~0.15 ms a frame for each idle
# node, so it is connected only while a rule of this family is on (checked each frame from the cached rule map).
var _hooked_log: Object = null

# DreamState calls it when cards or the Calling change, so a hit in the same frame is heard.
func sync_hook() -> void:
	_sync_hook(_any_rule_on())

func _sync_hook(on: bool) -> void:
	var want: Object = DamageLog.instance if on else null
	if want == _hooked_log:
		return
	if _hooked_log != null and is_instance_valid(_hooked_log) and _hooked_log.damage_dealt.is_connected(_on_damage):
		_hooked_log.damage_dealt.disconnect(_on_damage)
	_hooked_log = want
	_hooked = want != null
	if want != null and not want.damage_dealt.is_connected(_on_damage):
		want.damage_dealt.connect(_on_damage)

func _process(delta: float) -> void:
	if dream_state == null:
		return
	_sync_hook(_any_rule_on())  # Listens to DamageLog only while this family's rules are on (perf)
	var on := _lit_on()
	if not on and not _lent_on():
		if not _sources.is_empty() or not _glow.is_empty():
			_sources.clear()
			_glow.clear()
			_glow_serial += 1
			queue_redraw()
		_flush()  # Guiding Light forks on any start
		return
	_tick_glow_sheets()
	if not _pale.is_empty() and not get_tree().paused:  # Sightline's glints loop on their own clock
		var pale_frame := mark_stamp_of(&"lf_pale_path_dot")
		if pale_frame != _pale_frame:
			_pale_frame = pale_frame
			queue_redraw()
	_rebuild_in -= delta
	if _rebuild_in <= 0.0 or _board != int(dream_state.board_version):
		_rebuild()
	if on:
		_poll_in -= delta
		if _poll_in <= 0.0:
			_poll_in = POLL
			_poll()
	if not _flashes.is_empty():
		_flash_over()
	if not _brush.is_empty() and not get_tree().paused:
		_brush_in -= delta
		if _brush_in <= 0.0:
			_brush_in = BRUSH_EVERY
			_brush_fire()
	_flush()

func _towers() -> Array:
	return get_tree().get_nodes_in_group(Tower.GROUP).filter(_tower_ok)

func _tower_ok(tower) -> bool:
	return is_instance_valid(tower) and not tower.is_queued_for_deletion() and tower.tower_data != null

func _rebuild() -> void:
	_rebuild_in = REBUILD
	if not saved_sprouts.is_empty() and not _towers().is_empty():
		var cells := saved_sprouts
		saved_sprouts = []
		load_save(cells)
	if not saved_gold.is_empty() and not _towers().is_empty():
		_apply_saved_gold()
	_prune_gold()
	_one_family = dream_state.has_method("_families_owned") and int(dream_state._families_owned()) <= 1
	_board = int(dream_state.board_version)
	_sources.clear()
	_glow.clear()
	_glow_serial += 1  # The glow art re-lays its points on the next draw
	_max_lit_step = -1
	_strung.clear()
	_light_rep.clear()
	_wake_ids.clear()
	_pale.clear()
	_grown.clear()
	_gold_runs.clear()
	_gold_cells.clear()
	_moth_holder = null
	var jars: Array = []
	var sprouts: Array = []
	var plain_sprouts: Array = []  # Glowworms' candidates
	for tower in _towers():
		if is_firefly(tower):
			jars.append(tower)
		elif tower.tower_data.get_id() == "sprout" and tower.get_meta(LIT_SPROUT_META, false):
			sprouts.append(tower)
		elif tower.tower_data.get_id() == "sprout":
			plain_sprouts.append(tower)
	if not _lit_on():
		for tower in jars:
			_sources.append({"tower": tower, "sprout": false, "light": _sources.size()})  # Lent cards only ask "near a Firefly Warden"
		return
	var allowed := jars.size() if _rule(LIT_SPROUTS) else 0
	while sprouts.size() > allowed:
		sprouts.pop_back().remove_meta(LIT_SPROUT_META)  # One glowing Sprout per Firefly Warden: a sold Jar frees the newest pick
	var touch := SPROUT_TOUCH * _cell()
	var parent: Array = []  # Union-find over the Jars: glows sharing a path cell are one light
	for i in jars.size():
		parent.append(i)
	var cells_of: Array = []
	var path: Dictionary = dream_state._path_index
	for i in jars.size():
		var mine: Array = []
		var reach := glow_reach(jars[i])
		for cell in path:
			if jars[i].global_position.distance_to(Tower.MAP_GRID.calculate_map_position(cell)) <= reach:
				mine.append(cell)
		cells_of.append(mine)
	var owner_of := {}  # Route cell -> the first Jar lighting it
	for i in jars.size():
		for cell in cells_of[i]:
			if owner_of.has(cell):
				var a := _find(parent, i)
				var b := _find(parent, int(owner_of[cell]))
				if a != b:
					parent[a] = b
			else:
				owner_of[cell] = i
	var names := {}  # Union-find root -> the light's stable id: the smallest cell code among its Jars
	for i in jars.size():
		var root := _find(parent, i)
		names[root] = mini(int(names.get(root, 1 << 30)), _cell_code(jars[i]))
	for i in jars.size():
		var light := int(names[_find(parent, i)])
		_sources.append({"tower": jars[i], "sprout": false, "light": light})
		for cell in cells_of[i]:
			_note(cell, light, true)
	_step_px.clear()
	var last_step := -1
	for cell in path:
		var s := int(path[cell])
		if not _step_px.has(s):
			_step_px[s] = Tower.MAP_GRID.calculate_map_position(cell)
		if s > last_step:
			last_step = s
			_end_px = Tower.MAP_GRID.calculate_map_position(cell)
	var worms := _glowworms(jars, plain_sprouts) if evo(EVO_GLOWWORMS) else []
	for j in sprouts.size() + worms.size():
		var worm := j >= sprouts.size()
		var sprout = worms[j - sprouts.size()] if worm else sprouts[j]
		var light := -1 - _cell_code(sprout)  # Always its own light (negative ids), and never gold path
		_sources.append({"tower": sprout, "sprout": true, "light": light, "worm": worm})
		for cell in path:
			var at: Vector2 = Tower.MAP_GRID.calculate_map_position(cell)
			if absf(at.x - sprout.global_position.x) <= touch and absf(at.y - sprout.global_position.y) <= touch:
				_note(cell, light, false)
	if evo(EVO_WAKE):
		_lantern_wake(jars, sprouts + worms, path, touch)
	for source in _sources:
		if not _light_rep.has(source.light) or (_light_rep[source.light].sprout and not source.sprout):
			_light_rep[source.light] = source
	for cell in _glow:
		_max_lit_step = maxi(_max_lit_step, int(path.get(cell, -1)))
	_lay_gold_runs(path)
	if evo(EVO_SIGHT):
		_lay_pale()
	if evo(EVO_MOTH):
		_find_moth_holder()
	queue_redraw()

# Lantern Wake (final pass 2026-10-24): the WAKE_PER_JAR nearest other families' Wardens (not Fireflies, Sprouts or walls)
# within WAKE_CELLS of each Firefly Warden (both axes, centre to centre; ties nearest the Heartwood) carry its light: the path
# within WAKE_LIT_CELLS of them is Lit with that Firefly's light id. Never reveals hidden nightmares.
func _lantern_wake(jars: Array, taken: Array, path: Dictionary, _touch: float) -> void:
	var used := {}
	for tower in taken:
		used[tower.get_instance_id()] = true
	var candidates: Array = _towers().filter(is_other_family)
	var reach := WAKE_CELLS * _cell() + 1.0
	var lit := WAKE_LIT_CELLS * _cell() + 1.0
	for jar_source in _sources.duplicate():
		if jar_source.sprout or not jars.has(jar_source.tower):
			continue
		var jar = jar_source.tower
		var near: Array = []
		for tower in candidates:
			if not used.has(tower.get_instance_id()) and _within(jar, tower, reach):
				near.append(tower)
		_wake_from = jar.global_position
		near.sort_custom(_nearer_wake)
		for tower in near.slice(0, WAKE_PER_JAR):
			used[tower.get_instance_id()] = true
			var source := {"tower": tower, "sprout": true, "light": int(jar_source.light), "wake": true, "jar": jar, "reach": lit}
			_sources.append(source)
			_wake_ids[tower.get_instance_id()] = source
			for cell in path:
				var at: Vector2 = Tower.MAP_GRID.calculate_map_position(cell)
				if absf(at.x - tower.global_position.x) <= lit and absf(at.y - tower.global_position.y) <= lit:
					_note(cell, int(jar_source.light), false)

# Within `reach` px of each other on both axes (centre to centre).
static func _within(a, b, reach: float) -> bool:
	return absf(a.global_position.x - b.global_position.x) <= reach and absf(a.global_position.y - b.global_position.y) <= reach

# Lantern Wake's order: nearest the Firefly (_wake_from), then nearest the Heartwood.
func _nearer_wake(a, b) -> bool:
	var da: float = a.global_position.distance_squared_to(_wake_from)
	var db: float = b.global_position.distance_squared_to(_wake_from)
	if not is_equal_approx(da, db):
		return da < db
	return _nearer_heartwood(a, b)

func _nearer_heartwood(a, b) -> bool:
	return a.global_position.distance_squared_to(_end_px) < b.global_position.distance_squared_to(_end_px)

# Gold path (2+ Firefly glows) by stretch, and Spreading Flame's grown steps at each end (gold for every card, never white).
func _lay_gold_runs(path: Dictionary) -> void:
	var cells_at := {}  # Step -> its route cells
	var gold_steps: Array = []
	for cell in path:
		var s := int(path[cell])
		(cells_at.get_or_add(s, []) as Array).append(cell)
		if _glow.has(cell) and int(_glow[cell].jars) >= GOLD_JARS:
			_gold_cells.append(cell)
			if not gold_steps.has(s):
				gold_steps.append(s)
	gold_steps.sort()
	for s in gold_steps:
		if _gold_runs.is_empty() or int(_gold_runs[-1][1]) + 1 < int(s):
			_gold_runs.append([int(s), int(s)])
		else:
			_gold_runs[-1][1] = int(s)
	if _gold_grow.is_empty():
		return
	for run in _gold_runs:
		var grow := int(_gold_grow.get(int(run[0]), [0, 0.0])[0])
		for k in range(1, grow + 1):
			for s in [int(run[0]) - k, int(run[1]) + k]:
				for cell in cells_at.get(s, []):
					if not (_glow.has(cell) and int(_glow[cell].jars) >= GOLD_JARS) and not _grown.has(cell):
						_grown[cell] = true
						_gold_cells.append(cell)

# Sightline: Lit route cells in range of PALE_WARDENS or more other families' Wardens (no Sprouts or walls; final pass 2026-10-24).
func _lay_pale() -> void:
	var others: Array = _towers().filter(is_other_family)
	if others.size() < PALE_WARDENS:
		return
	for cell in _glow:
		var at: Vector2 = Tower.MAP_GRID.calculate_map_position(cell)
		var count := 0
		for tower in others:
			if tower.global_position.distance_to(at) <= tower.get_range_pixels():
				count += 1
				if count >= PALE_WARDENS:
					_pale[cell] = true
					break

# The pale path for the UI (UI Code, 2026-10-23): today's cells, or with a build ghost the cells it would make: a ghost
# `ghost_data` at whole cell `ghost_cell` counts as one more Warden in range (its base range in cells) unless it is a Firefly
# or a wall. Empty without Sightline. Not cached: TowerPlacer asks on hover change only.
func pale_cells(ghost_data: TowerData = null, ghost_cell := Vector2i(-1, -1)) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not evo(EVO_SIGHT):
		return out
	var counts_ghost := ghost_data != null and ghost_cell != Vector2i(-1, -1) and ghost_data.line != LINE and ghost_data.line != "wall" \
		and ghost_data.get_id() != "sprout" and ghost_data.can_attack
	if not counts_ghost:
		for cell in _pale:
			out.append(Vector2i(cell))
		return out
	var ghost_at: Vector2 = Tower.MAP_GRID.calculate_map_position(Vector2(ghost_cell))
	var ghost_reach: float = ghost_data.attack_range * Tower.MAP_GRID.cell_size.x
	var others: Array = _towers().filter(is_other_family)
	for cell in _glow:
		var at: Vector2 = Tower.MAP_GRID.calculate_map_position(cell)
		var count := 1 if ghost_at.distance_to(at) <= ghost_reach else 0
		for tower in others:
			if count >= PALE_WARDENS:
				break
			if tower.global_position.distance_to(at) <= tower.get_range_pixels():
				count += 1
		if count >= PALE_WARDENS:
			out.append(Vector2i(cell))
	return out

# Moth to Flame's holder (final pass 2026-10-24: gold dispels, not rank): the attacking Warden (no Sprouts or walls) whose range
# covers a gold step with the most gold dispels this block; while none has one this block, the last holder keeps it if it
# still stands, else the most gold dispels in all. Ties: the higher form. Recomputed per rebuild and on each gold dispel.
func _find_moth_holder() -> void:
	var kit = _kit()
	var candidates: Array = []
	var any_block := false
	for tower in _towers():
		if not kit.counts_as_warden(tower) or not _gold_in_range(tower):
			continue
		candidates.append(tower)
		if int(_gold_block.get(tower.get_instance_id(), 0)) > 0:
			any_block = true
	var last = _moth_last.get_ref() if _moth_last != null else null
	if not any_block and _tower_ok(last) and kit.counts_as_warden(last):
		_moth_holder = weakref(last)
		return
	var best = null
	var best_score := -1
	for tower in candidates:
		var id: int = tower.get_instance_id()
		var score := int(_gold_block.get(id, 0)) if any_block else int(_gold_total.get(id, 0))
		if best == null or score > best_score or (score == best_score and int(tower.tower_data.tier) > int(best.tower_data.tier)):
			best = tower
			best_score = score
	_moth_holder = weakref(best) if best != null else null
	if best != null:
		_moth_last = weakref(best)

# Gold dispels (Focus A): a nightmare dispelled on gold or white path (grown gold too) counts once for the Warden whose
# damage dispelled it (DamageLog's source; no Sprouts or walls). Pyre / Banked Fire read the total, Moth to Flame the block.
func _note_gold_dispel(source, enemy) -> void:
	if enemy.has_meta(GOLD_COUNTED_META) or not _kit().counts_as_warden(source) or gold_level(enemy) == 0:
		return
	enemy.set_meta(GOLD_COUNTED_META, true)
	var id: int = source.get_instance_id()
	var counted := DreamState.dispel_count(enemy)  # A Deeply Blighted counts 3 (Balancing 2026-10-24)
	_gold_block[id] = int(_gold_block.get(id, 0)) + counted
	_gold_total[id] = int(_gold_total.get(id, 0)) + counted
	if evo(EVO_MOTH):
		_find_moth_holder()

func gold_dispels_block(tower) -> int:
	return int(_gold_block.get(tower.get_instance_id(), 0)) if is_instance_valid(tower) else 0

func gold_dispels_total(tower) -> int:
	return int(_gold_total.get(tower.get_instance_id(), 0)) if is_instance_valid(tower) else 0

# A sold Warden's counts go with it.
func _prune_gold() -> void:
	if _gold_total.is_empty() and _gold_block.is_empty():
		return
	var standing := {}
	for tower in _towers():
		standing[tower.get_instance_id()] = true
	for counts in [_gold_total, _gold_block]:
		for id in counts.keys():
			if not standing.has(id):
				counts.erase(id)

# Saved with the run (Main Merger's RunSaver, beside "batch"): [cell x, cell y, block, total] per Warden with any.
func gold_to_save() -> Array:
	var rows: Array = []
	for tower in _towers():
		var id: int = tower.get_instance_id()
		if _gold_total.has(id) or _gold_block.has(id):
			rows.append([tower.cell.x, tower.cell.y, int(_gold_block.get(id, 0)), int(_gold_total.get(id, 0))])
	return rows

func gold_load_save(rows: Array) -> void:
	saved_gold = rows.duplicate()
	_rebuild_in = 0.0

func _apply_saved_gold() -> void:
	var rows := saved_gold
	saved_gold = []
	for tower in _towers():
		for row in rows:
			if row is Array and row.size() == 4 and tower.cell.is_equal_approx(Vector2(row[0], row[1])):
				_gold_block[tower.get_instance_id()] = int(row[2])
				_gold_total[tower.get_instance_id()] = int(row[3])

# Whether gold path (grown gold too) lies inside `tower`'s range.
func _gold_in_range(tower) -> bool:
	var reach: float = tower.get_range_pixels()
	for cell in _gold_cells:
		if tower.global_position.distance_to(Tower.MAP_GRID.calculate_map_position(cell)) <= reach:
			return true
	return false

# 0: no gold here, 1: gold path (grown gold counts), 2: white path (3+ Firefly glows).
func gold_level(enemy) -> int:
	if not is_instance_valid(enemy):
		return 0
	var jars := jars_at(_lit_sources(enemy))
	if jars >= WHITE_JARS:
		return 2
	if jars >= GOLD_JARS:
		return 1
	if not _grown.is_empty() and enemy.has_method("get_current_cell") and _grown.has(enemy.get_current_cell()):
		return 1
	return 0

func is_pale(enemy) -> bool:
	return not _pale.is_empty() and is_instance_valid(enemy) and enemy.has_method("get_current_cell") \
		and _pale.has(enemy.get_current_cell())

# Glowworms: up to GLOW_SPROUTS_PER_JAR Sprouts touching each Firefly Warden glow by themselves, the ones nearest the
# Heartwood first (chosen automatically; TD fix 4: never "any number", so the lights stay bounded).
func _glowworms(jars: Array, candidates: Array) -> Array:
	var out: Array = []
	var reach := GLOW_SPROUT_TOUCH * _cell()
	for jar in jars:
		var near: Array = []
		for s in candidates:
			if not out.has(s) and absf(s.global_position.x - jar.global_position.x) <= reach \
					and absf(s.global_position.y - jar.global_position.y) <= reach:
				near.append(s)
		near.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(_end_px) < b.global_position.distance_squared_to(_end_px))
		out.append_array(near.slice(0, GLOW_SPROUTS_PER_JAR))
	return out

# A Warden's cell as one number (half cells count): stable while it stands there.
func _cell_code(tower) -> int:
	return roundi(tower.cell.x * 2.0) * 1000 + roundi(tower.cell.y * 2.0)

func _find(parent: Array, i: int) -> int:
	while int(parent[i]) != i:
		i = int(parent[i])
	return i

func _note(cell: Vector2, light: int, jar: bool) -> void:
	var entry: Dictionary = _glow.get(cell, {"jars": 0, "lights": []})
	if jar:
		entry.jars += 1
	if not entry.lights.has(light):
		entry.lights.append(light)
	_glow[cell] = entry

# How far a Firefly Warden's glow reaches: GLOW_CELLS, plus every cell of range it has beyond a Firefly Jar's (ranks,
# forms and cards that add range grow it; owner 2026-10-14 "it doesn't grow when range grows"). Small on purpose
# (owner 2026-10-16): where you plant Fireflies decides what is Lit, so Strung Lights, Glowworms and Bonfire matter.
func glow_reach(tower) -> float:
	return (GLOW_CELLS + maxf(tower.get_range_cells() - GLOW_BASE_RANGE, 0.0)) * _cell()

# The sources lighting `at` (by distance, so flyers count).
func sources_at(at: Vector2) -> Array:
	var out: Array = []
	var touch := SPROUT_TOUCH * _cell()
	for source in _sources:
		var tower = source.tower
		if not is_instance_valid(tower):
			continue
		if source.sprout:
			var reach: float = source.get("reach", touch)  # (A Lantern Wake carrier's 1 cell)
			if absf(at.x - tower.global_position.x) <= reach and absf(at.y - tower.global_position.y) <= reach:
				out.append(source)
		elif tower.global_position.distance_to(at) <= glow_reach(tower):
			out.append(source)
	return out

func is_lit(enemy) -> bool:
	return _lit_on() and is_instance_valid(enemy) and not _lit_sources(enemy).is_empty()

# The sources lighting a nightmare: by distance (sources_at), or, with Full Glow, the glowing Warden that hit it in the last
# FULL_GLOW_TIME s wherever it walks (marked "carried": never gold path, never shows hidden nightmares). Every Lit question
# about a nightmare asks this.
func _lit_sources(enemy) -> Array:
	var out := sources_at(enemy.global_position)
	if out.is_empty() and enemy.has_meta(LIT_UNTIL_META):
		var held: Array = enemy.get_meta(LIT_UNTIL_META)
		var glowing = held[1].get_ref() if held.size() > 2 and held[1] != null else null
		if _now() <= float(held[0]) and is_instance_valid(glowing) and evo(EVO_FULL_GLOW):
			out.append({"tower": glowing, "sprout": true, "light": int(held[2]), "wake": true, "carried": true})
	return out

# Only a Firefly Warden's own light shows hidden nightmares (or an old save's chosen Sprout): never a Glowworm, a Lantern
# Wake Warden or Full Glow's carried light (TD fix 4).
func _reveals(sources: Array) -> bool:
	for source in sources:
		if not source.get("gap", false) and not source.get("worm", false) and not source.get("wake", false):
			return true
	return false

# Credit for being Lit by an evolution's light only: Glowworms (a Sprout's) or Lantern Wake / Full Glow.
func _credit_light(sources: Array, at: Vector2) -> void:
	var id := _light_evo(sources)
	if id != &"":
		credit(id, at)

# The evolution whose light alone lights it (&"": a Firefly Warden lights it anyway, or no evolution light): the Calling's
# jump from it is that evolution's own damage (owner 2026-10-19: "view the damage for the evolutions").
func _light_evo(sources: Array) -> StringName:
	var worm := false
	var wake := false
	var carried := false
	for source in sources:
		if source.get("carried", false):
			carried = true
		elif source.get("wake", false):
			wake = true
		elif source.get("worm", false):
			worm = true
		else:
			return &""  # A Firefly Warden lights it anyway
	if wake and evo(EVO_WAKE):
		return EVO_WAKE
	if carried and evo(EVO_FULL_GLOW):
		return EVO_FULL_GLOW
	if worm and evo(EVO_GLOWWORMS):
		return EVO_GLOWWORMS
	return &""

func lights_of(sources: Array) -> Array:
	var out: Array = []
	for source in sources:
		if not out.has(source.light):
			out.append(source.light)
	return out

# Firefly Wardens lighting this spot (gold path = two or more).
func jars_at(sources: Array) -> int:
	var count := 0
	for source in sources:
		if not source.sprout and not source.get("gap", false):
			count += 1
	return count

# The most another family's fork can be, started on a nightmare lit by `sources` (INF: uncapped).
func brightness(source_tower, sources: Array) -> float:
	if is_firefly(source_tower):
		return INF  # Firefly Wardens' own hits and bolts are never capped
	var best := 0.0
	for source in sources:
		var tower = source.tower
		if not is_instance_valid(tower):
			continue
		best = maxf(best, _base_jar_dps if source.sprout else tower.get_damage() * tower.get_attacks_per_second())
	return best * BRIGHTNESS_SECONDS if best > 0.0 else INF

func _enemies() -> Array:
	return get_tree().get_nodes_in_group(Tower.ENEMY_GROUP).filter(_living)

# The nearest Lit nightmares to `at`, nearest first (not those in `skip`).
func nearest_lit(at: Vector2, skip: Array, count: int = 1) -> Array:
	var found: Array = []
	for enemy in _enemies():
		if skip.has(enemy) or _lit_sources(enemy).is_empty():
			continue
		found.append(enemy)
	found.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(at) < b.global_position.distance_squared_to(at))
	return found.slice(0, count)

# Sightline / Constellation on pale path: of the SIGHT_POOL nearest other Lit nightmares, the one with the most health left
# (ties: the nearer), as a one-item list ([] = none).
func _healthiest_lit(at: Vector2, skip: Array) -> Array:
	var best = null
	for enemy in nearest_lit(at, skip, SIGHT_POOL):
		if best == null or float(enemy.health) > float(best.health):
			best = enemy
	return [best] if best != null else []

# The nearest Lit nightmares that event `id` has not struck yet (recursive hops).
func _fresh_lit(at: Vector2, id: int, skip: Array, count: int = 1) -> Array:
	var seen: Dictionary = _event_seen.get(id, {})
	var out: Array = []
	for enemy in nearest_lit(at, skip, count + seen.size()):
		if not seen.has(enemy.get_instance_id()):
			out.append(enemy)
	return out.slice(0, count)

func _step_of(enemy) -> int:
	return int(dream_state._path_index.get(enemy.get_current_cell(), -1))

# The front (furthest along the path) living nightmare standing in light `light`, or null.
func front_in(light: int, skip: Array = []):
	var best = null
	var best_step := -INF
	for enemy in _enemies():
		if skip.has(enemy) or not lights_of(_lit_sources(enemy)).has(light):
			continue
		var step := float(_step_of(enemy))
		if step > best_step:
			best_step = step
			best = enemy
	return best

# The next light ahead of path step `step`, not one of `from`: walk forward at most NEXT_LIGHT_STEPS. -1 = none.
func next_light(step: int, from: Array) -> Array:
	if step < 0:
		return [-1, -1]
	var by_step := {}
	for cell in _glow:
		var s := int(dream_state._path_index.get(cell, -1))
		if s > step and s <= step + NEXT_LIGHT_STEPS:
			by_step[s] = _glow[cell].lights
	for s in range(step + 1, step + NEXT_LIGHT_STEPS + 1):
		for light in by_step.get(s, []):
			if not from.has(light):
				return [light, s]
	return [-1, -1]

# --- Who is Lit, each POLL: reveals, entries (Ambush, Waiting Spark), leaving the last light (Last Spark) ----------

func _poll() -> void:
	var now := _now()
	for light in _sparks.keys():
		var waiting: Array = _sparks[light].filter(func(s: Dictionary) -> bool: return s.until > now)
		if waiting.is_empty():
			_sparks.erase(light)
			queue_redraw()
		else:
			_sparks[light] = waiting
	if not _embers.is_empty():
		_ember_poll(now)
	for key in _gold_grow.keys():
		if now > float(_gold_grow[key][1]):
			_gold_grow.erase(key)  # Spreading Flame: the grown gold shrinks back (re-laid with the next rebuild)
			_rebuild_in = 0.0
	var container: Node = dream_state.spawner
	if container == null:
		return
	var lit := 0
	_lit_by_step = []
	var streaks := evo(EVO_ALLEY)
	for enemy in container.get_children():
		if not _living(enemy) or not enemy.has_method("get_current_cell"):
			continue
		var sources := _lit_sources(enemy)
		var lights: Array = lights_of(sources)
		if streaks and enemy.has_meta(STREAK_META):
			_streak_tick(enemy, lights)  # Lantern Alley / Parade: a streak ends 4 steps past its last glow or at the Heartwood
		var before: Array = enemy.get_meta(GROUPS_META, [])
		if not lights.is_empty():
			lit += 1
			var lit_step := _step_of(enemy)
			if lit_step >= 0:  # Walkers only (a flyer has no step): Torchbearers' list (hard cards 2026-10-16)
				_lit_by_step.append([lit_step, enemy])
		if not lights.is_empty() and enemy.has_method("is_hidden") and enemy.is_hidden() and _reveals(sources):
			enemy.reveal_for(POLL * 3.0)  # Lit nightmares can't hide (a Firefly Warden's own light only)
		if lights == before:
			continue
		enemy.set_meta(GROUPS_META, lights)
		for light in before:
			if not lights.has(light) and _living(enemy):
				_left(enemy, int(light))  # Out of one glow first, then into the next (a gap of 0 steps)
		for light in lights:
			if not before.has(light) and _living(enemy):
				_entered(enemy, light)
		if lights.is_empty() and not before.is_empty() and _step_of(enemy) >= _max_lit_step:
			_left_last_light(enemy)
	_lit_count = lit
	_lit_by_step.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))

# Torchbearers / Bale-fires (hard cards 2026-10-16): the nearest Lit nightmare further along the path than `step`, at most
# TORCH_STEPS ahead, not in `skip` and not claimed by another throw in the last TORCH_CLAIM s (smallest step first, then
# nearest to `at`). Reads the poll's sorted list: at most 0.1 s stale. Null = none. `seen` = instance ids the event
# already struck (an _event_seen entry), skipped as _fresh_lit does (council full_review 2026-10-17: Bale-fires).
func next_lit_ahead(step: int, at: Vector2, skip: Array = [], seen: Dictionary = {}):
	if step < 0 or _lit_by_step.is_empty():
		return null
	var i: int = _lit_by_step.bsearch_custom([step, null], func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]), false)
	var now := _now()
	var best = null
	var best_step := -1
	while i < _lit_by_step.size():
		var entry: Array = _lit_by_step[i]
		i += 1
		var s := int(entry[0])
		if s > step + TORCH_STEPS or (best != null and s > best_step):
			break
		var enemy = entry[1]
		if not _living(enemy) or skip.has(enemy) or seen.has(enemy.get_instance_id()) \
				or now < float(enemy.get_meta(TORCH_CLAIM_META, -INF)):
			continue
		if best == null or enemy.global_position.distance_squared_to(at) < best.global_position.distance_squared_to(at):
			best = enemy
			best_step = s
	return best

# Torchbearers: half the dispelling hit jumps to the nearest Lit nightmare ahead (no per-light clock: EVENT_MAX bounds a
# chain, the claim spreads many throws forward). Bale-fires: `parent` is the jump that just dispelled, so this one keeps
# its event and hops. The spark threads through the glow spot of the target's light.
func _torch(id: int, source, at: Vector2, step: int, amount: float, cap: float, parent: Dictionary = {}, origin = null,
		skip: Array = []) -> void:
	var target = next_lit_ahead(step, at, skip, _event_seen.get(id, {}))
	if target == null:
		return
	target.set_meta(TORCH_CLAIM_META, _now() + TORCH_CLAIM)
	var relay := int(parent.get("relay", -1)) + 1
	var opts := _hop(parent, {"relay": relay, "color": Palette.HEARTLIGHT}) if not parent.is_empty() \
		else {"relay": 0, "color": Palette.HEARTLIGHT}
	if origin != null:
		opts["origin"] = origin
	var from := at
	var groups: Array = target.get_meta(GROUPS_META, [])
	var spot := _light_spot(int(groups[0])) if not groups.is_empty() else Vector2.ZERO
	if spot != Vector2.ZERO:
		_line_fx(at, spot, 2.0, Palette.GLOW)  # The spark flies to the target's light…
		from = spot  # …and the light throws it
	# Credited in _strike once the throw lands, never here: _flush may still drop it (council full_review 2026-10-17)
	opts["credit"] = EVO_BALE if relay > 0 else EVO_TORCH  # Setup credit 2026-10-16: its own damage
	opts["calling"] = true  # F1 (f1_spec.md): a Calling output (a hit by `source` for other families' lent cards)
	_fork(id, source, from, target, amount, cap, opts)

# Waiting Spark: every spark waiting in a light strikes the next nightmare to enter it. The Spread line counts the glow.
func _entered(enemy, light: int) -> void:
	if evo(EVO_STRUNG):
		_spread_entered(enemy, light)
	if not _sparks.has(light) or not _living(enemy):
		return
	var id := _next_event()
	for spark in _sparks[light]:
		var source = spark.source.get_ref()
		_strike({"event": id, "source": source, "from": enemy.global_position + Vector2(0, -24), "target": enemy,
			"amount": spark.amount, "cap": spark.cap, "waited": true, "final": true})  # A spark never waits twice
	_sparks.erase(light)
	queue_redraw()

# Last Spark: a Charged nightmare walking out of its last light throws its charge back into the light.
func _left_last_light(enemy) -> void:
	if not _rule(LAST_SPARK) or not enemy.statuses.has(EnemyStatuses.STATIC):
		return
	var charge: float = enemy.statuses.stored_bolt_damage()
	var source = enemy.statuses.source(EnemyStatuses.STATIC)
	enemy.statuses.remove(EnemyStatuses.STATIC)  # On walking out its Charged ends
	var targets := nearest_lit(enemy.global_position, [enemy])
	if charge > 0.0 and not targets.is_empty():
		_fork(_next_event(), source, enemy.global_position, targets[0], charge, INF, {"final": true})

# --- Spread: the lantern road (Strung Lights, Far Lights, Lantern Road, Parting Light, Marsh Lights, Circling Light,
# Drawn In). Glows are light ids (overlapping glows are one); steps are route points along the walker's own leg, forward
# only (_front); flyers have none ------------------------------------------------------------------------------------

# A nightmare walked into glow `light` (the poll): count it, then Lantern Road / Far Lights / Marsh Lights / Circling Light.
func _spread_entered(enemy, light: int) -> void:
	var glows: Dictionary = enemy.get_meta(GLOWS_META, {})
	var first := not glows.has(light)
	var row: Array = glows.get(light, [0, -1])
	var left_at := int(row[1])
	row[0] = int(row[0]) + 1
	row[1] = -1
	glows[light] = row
	enemy.set_meta(GLOWS_META, glows)
	_mark(enemy)
	var at := _front(enemy)
	var flyer := at < 0
	if first and evo(EVO_EARLY) and not enemy.has_meta(LANTERN_META):
		var early := glows.size() >= EARLY_GLOWS and _route_share(enemy, at) < 0.5
		var late := evo(EVO_LATE) and glows.size() >= LATE_GLOWS
		if early or late:
			enemy.set_meta(LANTERN_META, true)  # Early Lamps / Late Lanterns: it carries a lantern the rest of its walk
			credit(EVO_EARLY if early else EVO_LATE, enemy.global_position)
	if evo(EVO_ALLEY):
		_streak_entered(enemy, light, at)
	if evo(EVO_ROAD) and glows.size() >= ROAD_FROM:
		_flare(light, enemy, ROAD_SCALE, EVO_ROAD)  # From the 4th glow every entry, near or far, at double
	elif evo(EVO_FAR) and (flyer or at - int(enemy.get_meta(LAST_EXIT_META, 0)) >= FAR_STEPS * 2):
		_flare(light, enemy, 1.0, EVO_FAR)  # Steps = 2 route points; before any glow it counts from the start
	if first or flyer or left_at < 0 or not evo(EVO_MARSH):
		return
	if at - left_at < MARSH_STEPS * 2 or int(row[0]) - 1 > MARSH_RETURNS:
		return
	var marsh := _flare(light, enemy, 1.0, EVO_MARSH)  # Walking back into a glow it left 4+ steps before
	if not evo(EVO_CIRCLING) or not _living(enemy):
		return
	for other in glows:
		if int(other) != light and _living(enemy):
			_flare(int(other), enemy, 1.0, EVO_CIRCLING)  # Every other remembered glow's Firefly, each on its own clock
	if marsh:
		Reactions._effect(&"spark_burst", enemy.global_position, self, 0.8)  # The marsh flashes at once

# A nightmare left glow `light`: where (Far Lights and Marsh Lights count from it); Parting Light from its 4th glow on.
func _left(enemy, light: int) -> void:
	if not evo(EVO_STRUNG):
		return
	var glows: Dictionary = enemy.get_meta(GLOWS_META, {})
	var at := _front(enemy)
	if at >= 0:
		enemy.set_meta(LAST_EXIT_META, at)
		if glows.has(light):
			glows[light][1] = at
			enemy.set_meta(GLOWS_META, glows)
		var streak: Dictionary = enemy.get_meta(STREAK_META, {})
		if not streak.is_empty() and (streak.lights as Array).has(light):
			streak.last_exit = at  # Lantern Alley's gap counts from leaving the streak's glow
	if evo(EVO_PARTING) and glows.size() >= ROAD_FROM:
		_flare(light, enemy, PART_SCALE, EVO_PARTING, PART_META)  # Its own clock: never into a spent budget

# The Firefly Warden of light `light` nearest `at` (never a Sprout, Wake Warden or carried light), or null.
func _jar_of(light: int, at: Vector2):
	var best = null
	for source in _sources:
		if source.sprout or int(source.light) != light or not is_instance_valid(source.tower):
			continue
		if best == null or source.tower.global_position.distance_squared_to(at) < best.global_position.distance_squared_to(at):
			best = source.tower
	return best

# A flare from light `light`'s Firefly on `enemy` (class_kit.calling_hit, tag FLARE_TAG: damage only, bosses half, one per
# Firefly a second on `budget`). Drawn In: the Wardens touching that Firefly flare it too. True when it landed.
func _flare(light: int, enemy, scale: float, own: StringName, budget: StringName = FLARE_META) -> bool:
	if not _living(enemy):
		return false
	var jar = _jar_of(light, enemy.global_position)
	if not _flare_from(jar, enemy, scale, own, budget):
		return false
	if evo(EVO_DRAWN) and _living(enemy):
		_drawn_in(jar, enemy)
	return true

# One flare from Firefly Warden `jar` (period 1 s: calling_hit's default output share). True when it dealt damage (the
# clock on `budget` is spent only then).
func _flare_from(jar, enemy, scale: float, own: StringName, budget: StringName) -> bool:
	if jar == null or not is_instance_valid(jar) or jar.attack_data == null or not _living(enemy):
		return false
	if _now() < float(jar.get_meta(budget, -INF)):
		return false
	var dealt: float = _kit().calling_hit(jar, enemy, scale, FLARE_TAG, own, false, true, &"", BOSS_SHARE)
	if dealt <= 0.0:
		return false
	jar.set_meta(budget, _now() + CLASS_KIT.CALLING_HIT_EVERY)
	_line_fx(CLASS_KIT.body(jar), CLASS_KIT.body(enemy), 3.0, Palette.GLOW)
	return true

# How far along its route a nightmare is (0 start, 1 Heartwood): a walker by route index over the joined route's length; a
# flyer by its straight flight (start to Heartwood).
func _route_share(enemy, at: int) -> float:
	var kit = _kit()
	if at >= 0 and kit._route.size() > 1:
		return float(at) / float(kit._route.size() - 1)
	var start: Vector2 = _step_px.get(0, Vector2.ZERO)
	var whole := start.distance_to(_end_px)
	if whole <= 0.0:
		return 0.0
	return clampf(1.0 - enemy.global_position.distance_to(_end_px) / whole, 0.0, 1.0)

# The lantern's strength on `enemy` for Early Lamps / Carried Lights (0: none): 1 inside any Firefly glow (relit), else
# fading to 0 over LANTERN_FADE_STEPS past the last glow it left. Flyers have no steps: theirs never fades. For the UI too.
func lantern_level(enemy) -> float:
	if not _living(enemy) or not enemy.has_meta(LANTERN_META) or not evo(EVO_EARLY):
		return 0.0
	if jars_at(_lit_sources(enemy)) >= 1:
		return 1.0
	var at := _front(enemy)
	if at < 0:
		return 1.0
	var since := float(at - int(enemy.get_meta(LAST_EXIT_META, at))) / 2.0
	return maxf(0.0, 1.0 - since / LANTERN_FADE_STEPS)

# The glows in `enemy`'s open streak (0: none), for the UI's streak counter.
func streak_of(enemy) -> int:
	return int((enemy.get_meta(STREAK_META, {}) as Dictionary).get("count", 0)) if is_instance_valid(enemy) else 0

# Lantern Alley: a nightmare entered glow `light` (route index `at`). A glow not yet in any of its streaks, entered at most
# STREAK_GAP steps after it left the streak's last glow (or while it still stands in one), carries the streak on and flares
# it from that glow's Firefly at ALLEY_STEP per glow in the streak; else a new streak starts there (no flare). Each glow
# counts in one streak per nightmare (bends and laps never refire). Flyers have no steps: no streaks.
func _streak_entered(enemy, light: int, at: int) -> void:
	if at < 0:
		return
	var seen: Dictionary = enemy.get_meta(STREAK_SEEN_META, {})
	if seen.has(light):
		return
	seen[light] = true
	enemy.set_meta(STREAK_SEEN_META, seen)
	var streak: Dictionary = enemy.get_meta(STREAK_META, {})
	var inside := false
	if not streak.is_empty():
		for other in enemy.get_meta(GROUPS_META, []):
			if int(other) != light and (streak.lights as Array).has(other):
				inside = true
	if not streak.is_empty() and (inside or at - int(streak.last_exit) <= STREAK_GAP * 2):
		streak.count = int(streak.count) + 1
		(streak.lights as Array).append(light)
		_flare_from(_jar_of(light, enemy.global_position), enemy, minf(ALLEY_STEP * float(streak.count), ALLEY_MAX), EVO_ALLEY, FLARE_META)
		return
	if not streak.is_empty():
		_end_streak(enemy, streak)  # (One that ran out between polls)
	enemy.set_meta(STREAK_META, {"count": 1, "last_exit": at, "lights": [light], "passed": false})

# Each poll: a streak ends STREAK_GAP steps past its last glow with no new one, or at the Heartwood (never on a dispel).
func _streak_tick(enemy, lights: Array) -> void:
	var streak: Dictionary = enemy.get_meta(STREAK_META)
	for light in lights:
		if (streak.lights as Array).has(light):
			return  # Still in one of its glows
	var at := _front(enemy)
	if at < 0:
		return
	var kit = _kit()
	if at - int(streak.last_exit) > STREAK_GAP * 2 or at >= kit._route.size() - 2:
		enemy.remove_meta(STREAK_META)
		_end_streak(enemy, streak)

# Lantern Parade: a streak of PARADE_MIN+ glows that ended flares the nightmare from each of its Fireflies: PARADE_BASE plus
# PARADE_PER_FORM per other Firefly form among them, at most PARADE_MAX; its own clock per Firefly (PARADE_CLOCK_META).
func _end_streak(enemy, streak: Dictionary) -> void:
	if not evo(EVO_PARADE) or int(streak.get("count", 0)) < PARADE_MIN or not _living(enemy):
		return
	var jars: Array = []
	var forms := {}
	for light in streak.lights:
		var jar = _jar_of(int(light), enemy.global_position)
		if jar != null and not jars.has(jar):
			jars.append(jar)
			forms[jar.tower_data.get_id()] = true
	var scale := minf(PARADE_BASE + PARADE_PER_FORM * float(forms.size() - 1), PARADE_MAX)
	var any := false
	for jar in jars:
		if _flare_from(jar, enemy, scale, EVO_PARADE, PARADE_CLOCK_META):
			any = true
	if any:
		Reactions._effect(&"spark_burst", enemy.global_position, self, 0.8)

# Passed Torch: a nightmare dispelled with an open streak hands it to the nearest walker within PASSED_CELLS that isn't
# already in a streak as long; its glows already counted stay counted (seen sets joined). A streak passes once.
func _pass_streak(enemy) -> void:
	var streak: Dictionary = enemy.get_meta(STREAK_META, {})
	if streak.is_empty() or bool(streak.get("passed", false)):
		return
	enemy.remove_meta(STREAK_META)  # A dispel never ends a streak into a Parade
	var at: Vector2 = enemy.global_position
	var reach := PASSED_CELLS * _cell()
	var best = null
	for other in _enemies():
		if other == enemy or other.is_flying() or other.global_position.distance_to(at) > reach:
			continue
		var theirs: Dictionary = other.get_meta(STREAK_META, {})
		if not theirs.is_empty() and int(theirs.count) >= int(streak.count):
			continue
		if best == null or other.global_position.distance_squared_to(at) < best.global_position.distance_squared_to(at):
			best = other
	if best == null:
		return
	var front := _front(best)
	var copy := streak.duplicate(true)
	copy.passed = true
	copy.last_exit = maxi(front, 0)
	best.set_meta(STREAK_META, copy)
	var seen: Dictionary = best.get_meta(STREAK_SEEN_META, {})
	seen.merge(enemy.get_meta(STREAK_SEEN_META, {}))
	best.set_meta(STREAK_SEEN_META, seen)
	_line_fx(at, CLASS_KIT.body(best), 2.0, Palette.GLOW)
	credit(EVO_PASSED, best.global_position)

# Drawn In: each attacking Warden touching a flaring Firefly (Sprouts count, walls don't) flares the nightmare for a
# quarter of its own hit, once a second each (its own clock). These flares never call Drawn In again.
func _drawn_in(jar, enemy) -> void:
	for tower in _towers():
		if not _living(enemy):
			return
		if tower == jar or not _attacker(tower) or tower.attack_data == null or not _touching(jar, tower):
			continue
		var dealt: float = _kit().calling_hit(tower, enemy, DRAWN_SCALE, FLARE_TAG, EVO_DRAWN, false, true, DRAWN_META, BOSS_SHARE)
		if dealt > 0.0:
			_line_fx(CLASS_KIT.body(tower), CLASS_KIT.body(enemy), 2.0, Palette.GLOW)

# --- Damage events ----------------------------------------------------------------------------------------------

func _next_event() -> int:
	_event += 1
	return _event

# Whether any rule _on_damage reads is on (Chain of Lanterns, the lights, a lent card, Guiding Light), cached against
# the run's rule map and Calling as class_kit.active(): asked for every damage event (Enemy Code perf, 2026-10-17).
var _any_on_map = null
var _any_on_calling := ""
var _any_on := false
var _any_on_key := Vector3i(-1, -1, -1)  # Frame x rules_stamp x stacks: repeat asks in a frame skip even _rule_map (perf, Main Merger 2026-10-17)

func _any_rule_on() -> bool:
	var key := Vector3i(Engine.get_process_frames(), dream_state.rules_stamp, dream_state.stacks.size())
	if key == _any_on_key and dream_state.calling == _any_on_calling:
		return _any_on
	_any_on_key = key
	var map: Dictionary = dream_state._rule_map()
	if not is_same(map, _any_on_map) or dream_state.calling != _any_on_calling:
		_any_on_map = map
		_any_on_calling = dream_state.calling
		_any_on = _rule(CHAIN_OF_LANTERNS) or _lit_on() or _lent_on() or _rule(GUIDING_LIGHT)
	return _any_on

func _on_damage(event) -> void:
	if dream_state == null or event.tag == FORK_TAG or event.tag == FLARE_TAG or not is_instance_valid(event.enemy):
		return  # A fork or a flare triggers nothing (R1: a Calling row's hits are damage only)
	if not _any_rule_on():
		return  # Nothing of the Firefly set is held: the common case, and the cheap one
	if event.calling != &"" and String(event.calling) != FAMILY and event.kind != &"reaction":
		_calling_event(event)  # F1 (f1_spec.md): another family's Calling output: the lent cards only, as a hit
		return
	if _rule(CHAIN_OF_LANTERNS) and CLASS_KIT.is_reaction_burst(event):
		_chain_more(event)  # Any family's Reaction on a nightmare a Firefly Warden hit in the last 2 s (the shared list, council 2026-10-15)
	if event.kind == &"reaction":
		return  # A Reaction's own lightning gets nothing else added (a burst logged as a hit, Shatter, still counts as a dispel)
	var on := _lit_on()
	var lent := _lent_on()
	var guiding := _rule(GUIDING_LIGHT)
	if not on and not lent and not guiding:
		return
	var source = event.source if is_instance_valid(event.source) and event.source is Tower else null
	if source == null:
		return
	var id := _next_event()  # One event for every rule this hit sets off: one fork per nightmare, the largest wins
	if guiding and event.kind == &"hit" and event.tag == &"":
		_guiding_light(id, event, source)
	if not on and not lent:
		return
	var enemy = event.enemy
	var dispel: bool = enemy.health <= 0
	var is_bolt: bool = event.kind == &"bolt"
	var is_hit: bool = event.kind == &"hit" and event.tag == &""
	# One clock for every heavy rule on this event (a second call would read the clock this one just set)
	_heavy_now = is_hit and (is_heavy(source) or source.tower_data.get_id() == "sprout") \
		and (_rule(SPOTLIGHT) or _rule(HAMMERFALL) or _rule(THUNDERSTRUCK)) and _new_heavy_attack(source)
	if on and _evolved():
		if is_hit and evo(EVO_FULL_GLOW) and _wake_ids.has(source.get_instance_id()):
			_glow_on(enemy, source)  # Full Glow: before the Lit check, so the nightmare it hits is Lit at once
		if dispel and evo(EVO_BONFIRE):
			_note_gold_dispel(source, enemy)  # Focus A's gold dispels (Moth to Flame, Pyre, Banked Fire), before the crit rows read them
		if dispel and evo(EVO_PASSED):
			_pass_streak(enemy)  # Passed Torch: the streak goes on in the nearest walker
		if evo(EVO_BONFIRE):
			_focus_event(event, source, enemy, dispel, is_hit)  # Gold path by grown steps too: before the Lit check
	if on:
		_class_rules(id, event, source, enemy, dispel, is_hit, is_bolt)
	if lent:
		_lent_rules(id, event, source, enemy, dispel, is_hit, is_bolt)

# F1 lent × Calling (owner 2026-10-18; D:\Projects\logs\dream_council\f1_spec.md): another family's Calling output (a
# Toll, a dose's Warden, a Reflection…) is a hit by its Warden for the lent cards here: Hammerfall, Thunderstruck, Sparks
# Fly, Nothing Wasted, the Firefly-hit mark (Struck Twice spends on it in damage_multiplier). Never Flashover, Crossfire
# (attack-shaped) or Brushfire (ticks); never the Calling's class rules. Each card's own clock is shared with real hits.
func _calling_event(event) -> void:
	if not _lent_on():
		return
	var source = event.source if is_instance_valid(event.source) and event.source is Tower else null
	if source == null:
		return
	var enemy = event.enemy
	var is_hit: bool = event.kind == &"hit"
	var id := _next_event()
	_heavy_now = is_hit and (is_heavy(source) or source.tower_data.get_id() == "sprout") \
		and (_rule(SPOTLIGHT) or _rule(HAMMERFALL) or _rule(THUNDERSTRUCK)) and _new_heavy_attack(source)
	_lent_rules(id, event, source, enemy, enemy.health <= 0, is_hit, false, true)

# The nightmares other jumps of event `id` are already queued to (F4: two jumps from one hit go to different nightmares).
func _taken_by(id: int) -> Array:
	var out: Array = []
	for request in _queue:
		if int(request.event) == id and is_instance_valid(request.target):
			out.append(request.target)
	return out

# `skip` plus `taken`, unless that leaves nothing near `at` to jump to (then today's list: _flush keeps the largest).
func _fan_out(at: Vector2, skip: Array, taken: Array) -> Array:
	if not taken.is_empty():
		var found := _near_enemies(at, skip + taken)
		if not found.is_empty():
			return found
	return _near_enemies(at, skip)

# Chain of Lanterns on any Reaction (trait rework 2026-10-15; was Charged Reactions only): on a nightmare a Firefly Warden
# hit in the last 2 s, half of it jumps to the 2 nearest other nightmares near it. Each Firefly Warden, once a second;
# capped at 3 s of that Firefly Warden's damage.
func _chain_more(event) -> void:
	var enemy = event.enemy
	var lit: Array = enemy.get_meta(FF_HIT_META, [])
	if lit.is_empty() or _now() - float(lit[0]) > SPARKS_WINDOW:
		return
	var jar = lit[1].get_ref()
	if not is_instance_valid(jar) or _now() < float(jar.get_meta(CHAIN_META, -INF)):
		return
	var targets: Array = _near_enemies(enemy.global_position, [enemy]).slice(0, CHAIN_TARGETS)
	if targets.is_empty():
		return
	jar.set_meta(CHAIN_META, _now() + CHAIN_EVERY)
	var source = event.source if is_instance_valid(event.source) and event.source is Tower else jar
	var id := _next_event()
	for target in targets:
		_fork(id, source, enemy.global_position, target, event.base * CHAIN_SHARE, _lent_cap(null, jar), {"final": true})

# The most a lent card's jump may deal (never "no cap" for another family: brightness() is never asked with no light).
# A Firefly Warden's own jumps stay uncapped, as the Calling's are; another family's are capped at 3 s of the Firefly
# Warden `jar` (the one near it, or the one that Charged the nightmare), or of a base Firefly Jar when there is none.
func _lent_cap(source, jar) -> float:
	if is_instance_valid(source) and is_firefly(source):
		return INF
	if is_instance_valid(jar) and is_firefly(jar):
		return jar.get_damage() * jar.get_attacks_per_second() * BRIGHTNESS_SECONDS
	return _base_jar_dps * BRIGHTNESS_SECONDS

# Guiding Light (owner ruling 2026-10-12, dream_council_review.md 21; family-wide since section 35, 2026-10-24): a
# Firefly Warden's direct hit on a nightmare at full Charged forks to the nightmares within 1 cell of it (II: 2 cells), for
# half. Full Charged = EnemyStatuses.FULL_SHARE (0.75) of Charged's base cap, the "full" every section 35 card uses (it
# comes before the bolt at Charged's most). (Was full Exposed: Exposed comes from one branch.)
func _guiding_light(id: int, event, source) -> void:
	var enemy = event.enemy
	if not is_firefly(source):
		return
	var s: EnemyStatuses = enemy.statuses
	if s.stacks(EnemyStatuses.STATIC) < ceili(s.base_cap(EnemyStatuses.STATIC) * EnemyStatuses.FULL_SHARE):
		return
	var at: Vector2 = enemy.global_position
	var reach: float = GUIDING_CELLS[mini(dream_state.rule_level(GUIDING_LIGHT), GUIDING_CELLS.size() - 1)] * _cell()
	for other in _enemies():
		if other != enemy and other.global_position.distance_to(at) <= reach:
			_fork(id, source, at, other, event.base * GUIDING_SHARE, INF, {"final": true})

# The size a dispel's fork starts from: that Warden's hit, or one second of its damage for a tick, cloud or trail.
func _hit_size(source, is_hit: bool, is_bolt: bool) -> float:
	var hit: float = source.get_damage()
	if is_hit or is_bolt:
		return hit  # A bolt that dispels forks from the Warden's hit, not the bolt
	return hit * source.get_attacks_per_second()

func _class_rules(id: int, event, source, enemy, dispel: bool, is_hit: bool, is_bolt: bool) -> void:
	var at: Vector2 = enemy.global_position
	var sources := _lit_sources(enemy)
	if sources.is_empty():
		return  # Class cards follow the light: the nightmare that was hit must be Lit
	var lights := lights_of(sources)
	var cap := brightness(source, sources)  # Never an empty list here: the nightmare is Lit
	if dispel:
		var size := _hit_size(source, is_hit, is_bolt)
		var jars := jars_at(sources)
		var gold := jars >= 2
		# Lantern Light; on gold path Where Lights Meet replaces it: one fork per Firefly Warden lighting it.
		var count := mini(jars, MEET_MAX) if gold and _rule(WHERE_LIGHTS_MEET) else 1
		var targets := nearest_lit(at, [enemy], count)
		if class_on():  # The Calling's own payoff: the first pick only
			var light_evo := _light_evo(sources)  # Lit only by a Glowworm, Lantern Wake or Full Glow: its jump is that evolution's
			for t in targets.size():
				var opts := {"origin": enemy, "calling": true}  # (F1: the Calling's jump)
				if t >= 1:
					opts["credit"] = WHERE_LIGHTS_MEET
				elif light_evo != &"":
					opts["credit"] = light_evo
				_fork(id, source, at, targets[t], size * CALLING_SHARE, cap, opts)
			if targets.is_empty():
				_wait(lights, source, size * CALLING_SHARE, cap)
			else:
				_credit_light(sources, at)
		if evo(EVO_TORCH):  # Hard cards 2026-10-16: the nearest Lit nightmare ahead (Torchbearers wins over Signal Fires)
			# Its own event, skipping the Calling's targets, so _flush never drops the throw (council full_review 2026-10-17)
			_torch(_next_event(), source, at, _step_of(enemy), size * RELAY_SHARE, cap, {}, enemy, [enemy] + targets)
		elif _rule(SIGNAL_FIRES):  # (Retired class card: an old save keeps its light-to-light rule)
			_signal(id, source, at, _step_of(enemy), lights, size * SIGNAL_SHARE, cap, {}, enemy)
		if gold and evo(EVO_EMBERS):
			_drop_ember(enemy, source, size * EMBER_SHARE, cap)
		if _rule(LAST_SPARK) and enemy.statuses.has(EnemyStatuses.STATIC):
			var charge: float = enemy.statuses.stored_bolt_damage()
			var spark_to := nearest_lit(at, [enemy])
			if charge > 0.0 and not spark_to.is_empty():
				_fork(_next_event(), enemy.statuses.source(EnemyStatuses.STATIC), at, spark_to[0], charge, INF, {"final": true, "credit": LAST_SPARK})
	if is_bolt:
		if _rule(LANTERNWAY):
			var step := _step_of(enemy)
			var seen := lights.duplicate()
			var from := at
			for i in LANTERNWAY_LIGHTS:
				var next := next_light(step, seen)
				if int(next[0]) < 0:
					break
				seen.append(next[0])
				step = int(next[1])
				var front = front_in(int(next[0]))
				if front != null:
					_fork(id, source, from, front, event.base * LANTERNWAY_SHARE, cap, {"credit": LANTERNWAY})
					from = front.global_position
	if is_hit and evo(EVO_BORROWED):
		_borrowed_light(id, event, source, enemy, at, cap)  # With Sightline's pale share and Constellation's stars
	if is_hit:
		if _heavy_now and is_heavy(source) and _rule(SPOTLIGHT):  # (Spotlight: retired 2026-10-14; an old save keeps it)
			for light in lights:
				if front_in(light) != enemy:
					continue
				var others: Array = _enemies().filter(func(e) -> bool:
					return e != enemy and lights_of(sources_at(e.global_position)).has(light))
				var fan: Array = others.slice(0, SPOTLIGHT_MAX)
				for other in fan:  # The cap covers the whole fan (council, new_lent_td.md)
					_fork(id, source, at, other, minf(event.base * SPOTLIGHT_SHARE, cap / maxf(fan.size(), 1.0)), cap, {"heavy": true})
				break
		if _rule(AMBUSH):
			var ambushed: Dictionary = enemy.get_meta(AMBUSH_META, {})
			var fresh := false
			for light in lights:
				if not ambushed.has(light):
					ambushed[light] = true
					fresh = true
			if fresh:
				enemy.set_meta(AMBUSH_META, ambushed)
				var targets := nearest_lit(at, [enemy])
				if not targets.is_empty():
					_fork(id, source, at, targets[0], event.base * AMBUSH_SHARE, cap)

# One fork per heavy attack: the first hit after most of its attack time has passed starts a new one.
func _new_heavy_attack(source) -> bool:
	var now := _now()
	if now < float(source.get_meta(HEAVY_META, -INF)):
		return false
	source.set_meta(HEAVY_META, now + HEAVY_ATTACK_SHARE / maxf(source.get_attacks_per_second(), 0.05))
	return true

# Signal Fires: a dispel in one light also forks to the front nightmare in the next light ahead, once per light a second.
# (Torchbearers and Bale-fires used this until hard cards 2026-10-16; they now go through _torch. The relay branch below
# stays for the parent/relay options a Signal Fires throw may carry.)
func _signal(id: int, source, at: Vector2, step: int, lights: Array, amount: float, cap: float, parent: Dictionary = {},
		origin = null) -> void:
	var now := _now()
	for light in lights:
		if now < float(_signal_next.get(light, -INF)):
			return
	var next := next_light(step, lights)
	if int(next[0]) < 0:
		return
	var front = front_in(int(next[0]))
	if front == null:
		return
	for light in lights:
		_signal_next[light] = now + SIGNAL_EVERY
	var from := at
	var opts := {}
	if evo(EVO_TORCH) or not parent.is_empty():
		var relay := int(parent.get("relay", -1)) + 1
		opts = _hop(parent, {"relay": relay, "color": Palette.HEARTLIGHT}) if not parent.is_empty() \
			else {"relay": 0, "color": Palette.HEARTLIGHT}
		if origin != null:
			opts["origin"] = origin
		var spot := _light_spot(int(next[0]))
		if spot != Vector2.ZERO:
			_line_fx(at, spot, 2.0, Palette.GLOW)  # The spark flies light to light…
			from = spot  # …and the next light throws it
		credit(EVO_BALE if relay > 0 else EVO_TORCH, front.global_position)
	_fork(id, source, from, front, amount, cap, opts)

# --- Hit bonuses: Struck Twice (self-sufficiency audit 2026-10-18; Bonfire and Strung Lights left it 2026-10-23) ---------

# Whether any hit bonus here is on (DreamState.batch_damage_multiplier asks once a frame before calling damage_multiplier).
func wants_damage_hook() -> bool:
	return _rule(STRUCK_TWICE)  # (Bonfire's +25% and the old Strung Lights left this hook 2026-10-23: hit_multiplier below)

# Struck Twice (DreamState.note_jump, every jump from any card or Warden): the nightmare a jump lands on waits for one
# boosted hit for STRUCK_TIME s. A new jump refreshes the one mark (never stacks). A small spark shows it.
func mark_struck(source, to) -> void:
	if not _living(to):
		return
	var old: Array = to.get_meta(STRUCK_META, [])
	var spark = old[3].get_ref() if old.size() > 3 and old[3] != null else null
	if not is_instance_valid(spark) or spark.is_queued_for_deletion():
		spark = null
		var world := Reactions._world(self)
		if world != null:
			spark = StruckSpark.new(to, self)
			world.add_child(spark)  # Never under %EnemyContainer (its children are all nightmares)
	to.set_meta(STRUCK_META, [_now(), Engine.get_process_frames(), source.get_instance_id() if is_instance_valid(source) else 0,
		weakref(spark) if spark != null else null])

# Whether `enemy` still waits for its Struck Twice hit (the spark asks each frame).
func is_struck(enemy) -> bool:
	if not _living(enemy) or not enemy.has_meta(STRUCK_META):
		return false
	return _now() - float(enemy.get_meta(STRUCK_META)[0]) <= STRUCK_TIME

# The hit bonuses, for hits only (tag ""; never jumps or bolts): Struck Twice (a Firefly Warden or a Warden near one; a
# Warden counts as near itself). It notes its card bonus (DamageLog) and credits itself with the Warden.
func damage_multiplier(enemy, source, tag: StringName = &"") -> float:
	var calling: bool = DamageLog.calling_now != &"" and String(DamageLog.calling_now) != FAMILY  # F1: another family's Calling output is a hit
	if (tag != &"" and not calling) or not (source is Tower) or not is_instance_valid(source) or not is_instance_valid(enemy):
		return 1.0
	var multiplier := 1.0
	var own := is_firefly(source)
	if _rule(STRUCK_TWICE) and enemy.has_meta(STRUCK_META):
		var mark: Array = enemy.get_meta(STRUCK_META)
		if _now() - float(mark[0]) > STRUCK_TIME:
			enemy.remove_meta(STRUCK_META)  # Faded
		elif (own or firefly_near(source) != null) \
				and not (int(mark[1]) == Engine.get_process_frames() and int(mark[2]) == source.get_instance_id()):
			# (A chain Warden's hop is a jump and its hit in the same frame: it never spends the mark it just made)
			enemy.remove_meta(STRUCK_META)
			multiplier *= STRUCK_BONUS
			DamageLog.note_card_bonus(String(STRUCK_TWICE), STRUCK_BONUS)
			credit(STRUCK_TWICE, enemy.global_position, source)
	return multiplier

# --- Calling hit multipliers and forced crits (DreamState._calling_hit_multiplier / calling_crit; evo_shared_spec.md 5-6) --

# The Calling branch of DreamState.hit_card_multiplier (direct hits only; Tower skips Pinned / Shatter / effects): Strung
# Lights (any Warden's direct hit on a nightmare inside a Firefly glow, per glow it entered) and Moth to Flame's kept crit
# (x1.5 after 4 other hits). Each part noted with DamageLog.note_card_bonus, so card_cap_factor holds it at x4.
func hit_multiplier(tower, enemy, _is_area: bool, is_crit: bool, combo: StringName) -> float:
	if not class_on() or not is_instance_valid(tower) or not _living(enemy):
		return 1.0
	var m := 1.0
	if combo == &"" and evo(EVO_STRUNG):  # Not jumps, bolts, flares or statuses
		var glows := (enemy.get_meta(GLOWS_META, {}) as Dictionary).size()
		if glows > 0:
			# Early Lamps' lantern carries it outside glows, fading (lantern_level); Carried Lights: 8% a glow, to +40%, for a carrier
			var lantern := lantern_level(enemy)
			var carried := lantern > 0.0 and evo(EVO_CARRIED)
			var share := 0.0
			var row := EVO_STRUNG
			if carried:
				share = minf(CARRIED_PER_GLOW * glows, CARRIED_MAX) * lantern
				row = EVO_CARRIED
			elif jars_at(_lit_sources(enemy)) >= 1:
				share = minf(STRUNG_PER_GLOW * glows, STRUNG_MAX)
			elif lantern > 0.0:
				share = minf(STRUNG_PER_GLOW * glows, STRUNG_MAX) * lantern
				row = EVO_EARLY
			if share > 0.0:
				var strung := 1.0 + share
				m *= strung
				DamageLog.note_card_bonus(String(row), strung)
				credit(row, enemy.global_position, tower)
	if is_crit and evo(EVO_MOTH) and tower.has_meta(FORCED_META):
		var forced: Array = tower.get_meta(FORCED_META)
		if int(forced[0]) == Engine.get_process_frames() and bool(forced[3]) and int(forced[4]) == enemy.get_instance_id():
			m *= MOTH_BONUS
			DamageLog.note_card_bonus(String(EVO_MOTH), MOTH_BONUS)
	return m

# Tower's forced-crit hook (DreamState.calling_crit; asked only for a direct hit that didn't crit): true = this hit is a
# forced crit, dealt with the Warden's own crit multiplier only. Forced only, never a chance roll. At most one waiting crit
# is spent per hit (Flint and Steel's pass, then Moth to Flame's kept crit for its holder, then Bonfire's shared one); Pyre
# and Banked Fire count every hit on white / gold by a rank V+ Warden and crit on their beat. The crit factor is noted to
# DamageLog (inside the x4 card cap, credited to the row). "Not a crit for other cards": Tower hands them real_crit.
func calling_crit(tower, enemy) -> bool:
	if not class_on() or not _attacker(tower) or tower.attack_data == null or not _living(enemy):
		return false
	var level := gold_level(enemy)
	var cause := &""
	var passes := 0
	var chain: Array = []
	var moth_bonus := false
	if level > 0 and tower.has_meta(PASS_META) and evo(EVO_FLINT):
		var passed: Array = tower.get_meta(PASS_META)
		tower.remove_meta(PASS_META)
		passes = int(passed[0])
		chain = passed[1]
		cause = EVO_FLINT if passes <= 1 else EVO_TINDERBOX
	elif enemy.has_meta(MOTH_META) and evo(EVO_MOTH) and int(enemy.get_meta(MOTH_META)[0]) == tower.get_instance_id():
		moth_bonus = int(enemy.get_meta(MOTH_META)[1]) >= MOTH_HITS
		enemy.remove_meta(MOTH_META)
		cause = EVO_MOTH
	elif enemy.has_meta(WAIT_META) and int(enemy.get_meta(WAIT_META)) != tower.get_instance_id():
		enemy.remove_meta(WAIT_META)  # Any other Warden's next direct hit (Fireflies can take it)
		cause = EVO_BONFIRE
	var counter := _beat(tower, enemy, level)
	if cause == &"":
		cause = counter
	if cause == &"":
		return false
	tower.set_meta(FORCED_META, [Engine.get_process_frames(), passes, chain, moth_bonus, enemy.get_instance_id()])
	var factor: float = tower.attack_data.crit_multiplier
	DamageLog.note_card_bonus(String(cause), factor if factor > 1.0 else 2.0)  # The Warden's own crit (2.0 when it has none)
	credit(cause, enemy.global_position, tower)
	return true

# Pyre (white path) and Banked Fire (gold, not white): direct hits there by a Warden with PYRE_DISPELS gold dispels, counted per
# Warden; true on every PYRE_EVERY-th (BANKED_EVERY-th; bosses one more). Returns the row whose beat this is, or &"".
func _beat(tower, enemy, level: int) -> StringName:
	if level == 0 or gold_dispels_total(tower) < PYRE_DISPELS:
		return &""
	var white := level == 2
	if not evo(EVO_PYRE) or (not white and not evo(EVO_BANKED)):
		return &""
	var boss: bool = enemy.enemy_data != null and enemy.enemy_data.is_boss
	var key: String = ("white" if white else "gold") + ("_boss" if boss else "")
	var every: int = (PYRE_BOSS_EVERY if boss else PYRE_EVERY) if white else (BANKED_BOSS_EVERY if boss else BANKED_EVERY)
	var counts: Dictionary = tower.get_meta(PYRE_META, {})
	var n := int(counts.get(key, 0)) + 1
	counts[key] = n % every
	tower.set_meta(PYRE_META, counts)
	if n < every:
		return &""
	return EVO_PYRE if white else EVO_BANKED

# Whether `tower`'s crit this frame on `enemy` was forced by a row (FORCED_META), as [passes, chain]; [] = not forced.
func _forced_now(tower, enemy) -> Array:
	if not tower.has_meta(FORCED_META):
		return []
	var forced: Array = tower.get_meta(FORCED_META)
	if int(forced[0]) != Engine.get_process_frames() or int(forced[4]) != enemy.get_instance_id():
		return []
	return [int(forced[1]), forced[2]]

# --- Focus: the bonfire. Every direct hit (DamageLog event, tag "") while Bonfire is held: Moth to Flame's count, Bonfire's
# waiting crit, Moth's kept crit, Spreading Flame and Flint and Steel / Tinderbox's passes ------------------------------
func _focus_event(event, source, enemy, dispel: bool, is_hit: bool) -> void:
	if not is_hit:
		return
	var forced := _forced_now(source, enemy)
	if enemy.has_meta(MOTH_META) and not dispel:
		var moth: Array = enemy.get_meta(MOTH_META)
		if int(moth[0]) != source.get_instance_id():
			moth[1] = int(moth[1]) + 1  # Another Warden's direct hit (an area attack hits each nightmare once)
			enemy.set_meta(MOTH_META, moth)
	var level := gold_level(enemy)
	if level == 0:
		return
	if is_firefly(source) and forced.is_empty() and not dispel:
		# Bonfire: a Firefly's hit on gold readies a waiting crit (one per nightmare; a crit from one never readies another)
		if not enemy.has_meta(WAIT_META):
			enemy.set_meta(WAIT_META, source.get_instance_id())
			_mark(enemy)
		if evo(EVO_MOTH) and not enemy.has_meta(MOTH_META) and _moth_holder != null:
			var holder = _moth_holder.get_ref()
			if _attacker(holder):
				enemy.set_meta(MOTH_META, [holder.get_instance_id(), 0])  # Kept for the Warden with most gold dispels
				_mark(enemy)
	if not event.combos.has(&"crit"):
		return
	if dispel and evo(EVO_SPREADING):
		_spread_gold(enemy, source)
	if evo(EVO_FLINT):
		_pass_crit(source, forced)

# Spreading Flame: a crit dispel on gold grows that gold stretch 1 step at each end (up to SPREAD_GROW_MAX) for SPREAD_TIME s.
func _spread_gold(enemy, source) -> void:
	var step := _step_of(enemy)
	if step < 0:
		return
	for run in _gold_runs:
		var key := int(run[0])
		var grow := int(_gold_grow.get(key, [0, 0.0])[0])
		if step < key - grow or step > int(run[1]) + grow:
			continue
		_gold_grow[key] = [mini(grow + 1, SPREAD_GROW_MAX), _now() + SPREAD_TIME]
		_rebuild_in = minf(_rebuild_in, 0.0)  # Re-laid on the next frame (the rebuild re-lays at most twice a second anyway)
		Reactions._effect(&"spark_burst", enemy.global_position, self, 0.6)
		credit(EVO_SPREADING, enemy.global_position, source)
		return

# Flint and Steel: a crit on gold passes to the nearest Warden touching the critting one with gold path in range (Sprouts
# and walls never take or pass one: final pass 2026-10-24): its next direct hit on gold crits. One waiting pass per Warden; a
# passed crit never passes on, except with Tinderbox once more (to a Warden touching the second, never back, never a fourth).
func _pass_crit(source, forced: Array) -> void:
	var kit = _kit()
	if not kit.counts_as_warden(source):
		return
	var passes := int(forced[0]) if not forced.is_empty() else 0
	var chain: Array = (forced[1] as Array).duplicate() if not forced.is_empty() else []
	if passes >= TINDER_PASSES or (passes >= 1 and not evo(EVO_TINDERBOX)):
		return
	chain.append(source.get_instance_id())
	var best = null
	for tower in _towers():
		if not kit.counts_as_warden(tower) or chain.has(tower.get_instance_id()) or tower.has_meta(PASS_META) or not _touching(source, tower):
			continue
		if not _gold_in_range(tower):
			continue
		if best == null or tower.global_position.distance_squared_to(source.global_position) < best.global_position.distance_squared_to(source.global_position):
			best = tower
	if best == null:
		return
	best.set_meta(PASS_META, [passes + 1, chain])
	_line_fx(CLASS_KIT.body(source), CLASS_KIT.body(best), 2.0, Palette.GOLD)  # The gold spark jumps to the partner
	credit(EVO_TINDERBOX if passes >= 1 else EVO_FLINT, best.global_position, source)

# Struck Twice's mark: a small warm spark over the nightmare until its boosted hit lands or the mark fades.
class StruckSpark extends Node2D:
	var _enemy: WeakRef
	var _lights: WeakRef

	func _init(enemy: Node2D, lights: Node) -> void:
		_enemy = weakref(enemy)
		_lights = weakref(lights)
		z_index = 20  # Over the nightmares
		global_position = enemy.global_position

	func _process(_delta: float) -> void:
		var enemy = _enemy.get_ref()
		var lights = _lights.get_ref()
		if lights == null or not lights.is_struck(enemy):
			queue_free()
			return
		global_position = enemy.global_position

	func _draw() -> void:
		draw_circle(Vector2(12, -30), 3.0, Color(Palette.HEARTLIGHT, 0.6))
		draw_circle(Vector2(12, -30), 1.5, Palette.HEARTLIGHT)

# The marks the Calling evolutions draw over a nightmare (one LanternMark each, made on first need, gone when nothing is
# left to show): Strung Lights' glow pips, Bonfire's waiting flame, Moth to Flame's kept crit (white once it is ready),
# Constellation's pips and star, Full Glow's carried light.
func _mark(enemy) -> void:
	if not _living(enemy):
		return
	var held = enemy.get_meta(MARK_META) if enemy.has_meta(MARK_META) else null  # (A null default is no default: it errors)
	if held is WeakRef and is_instance_valid(held.get_ref()):
		return
	var world := Reactions._world(self)
	if world == null:
		return
	var mark := LanternMark.new(enemy, self)
	world.add_child(mark)  # Never under %EnemyContainer (its children are all nightmares)
	enemy.set_meta(MARK_META, weakref(mark))

# What a LanternMark draws for `enemy` ([] = nothing): [glow pips, waiting crit, Moth (-1 none, 0 kept, 1 ready), star
# charges, star pips, carried light].
func mark_state(enemy) -> Array:
	if not _living(enemy) or not class_on():
		return []
	var glows: int = mini((enemy.get_meta(GLOWS_META, {}) as Dictionary).size(), STRUNG_PIPS) if evo(EVO_STRUNG) else 0
	var wait: bool = enemy.has_meta(WAIT_META)
	var moth := -1
	if enemy.has_meta(MOTH_META):
		moth = 1 if int(enemy.get_meta(MOTH_META)[1]) >= MOTH_HITS else 0
	var stars := int(enemy.get_meta(STAR_META, 0))
	var roster: int = (enemy.get_meta(STAR_ROSTER_META, {}) as Dictionary).size()
	var carried: bool = enemy.has_meta(LIT_UNTIL_META) and _now() <= float(enemy.get_meta(LIT_UNTIL_META)[0])
	if glows == 0 and not wait and moth < 0 and stars <= 0 and roster == 0 and not carried:
		return []
	return [glows, wait, moth, stars, roster, carried]

# The Calling evolution marks (assets/effects/calling_evo/; class_kit's static helpers with this node's own cache, never
# static). evo_mark returns false when the sheet is missing: the caller draws its palette placeholder.
var evo_art := {}

func evo_mark(c: CanvasItem, mark: StringName, at: Vector2, alpha: float = 1.0, flip: bool = false, frame: int = -1,
		phase: int = 0) -> bool:
	return CLASS_KIT.draw_evo_art(evo_art, c, mark, at, alpha, flip, frame, phase)

func has_evo_mark(mark: StringName) -> bool:
	return CLASS_KIT.evo_art_tex(evo_art, mark) != null

func mark_stamp_of(mark: StringName) -> int:
	return CLASS_KIT.evo_art_frame(evo_art, mark)

# The frames of the sheets a LanternMark with `state` (mark_state) shows: it redraws when this changes.
func mark_stamp(state: Array) -> int:
	if state.size() < 6:
		return 0
	var marks: Array = []
	if int(state[0]) > 0:
		marks.append(&"lf_strung_pip")
	if bool(state[1]):
		marks.append(&"lf_waiting_flame")
	if int(state[2]) >= 0:
		marks.append(&"lf_moth_flame_ready" if int(state[2]) > 0 else &"lf_moth_flame")
	if int(state[4]) > 0 or int(state[3]) > 0:
		marks.append(&"lf_constellation_pip")
	if int(state[3]) > 0:
		marks.append(&"lf_constellation_star")
	return CLASS_KIT.evo_art_stamp(evo_art, marks)

class LanternMark extends Node2D:
	const BAR_DEFAULT := Vector2(0, -38)  # Enemy.HEALTH_BAR_OFFSET, when the nightmare is gone
	const WAITING_FLAME_AT := Vector2(-9, 20)  # From the bar centre: tucked under the bar's middle, inside its width
	const MOTH_FLAME_AT := Vector2(10, 22)  # ...beside it (Bonfire and Moth are both Focus; asset chat 2026-10-23)
	const STAR_AT := Vector2(0, -30)  # Above the status row
	const STAR_CHARGES: Array[Vector2] = [Vector2(-13, 0), Vector2(13, 0), Vector2(0, -13)]
	var _enemy: WeakRef
	var _lights: WeakRef
	var _state: Array = []
	var _stamp := -1  # The sheets' frames last drawn
	var _ring: GlowRing = null  # Full Glow's ring on the ground, made on first need

	func _init(enemy: Node2D, lights: Node) -> void:
		_enemy = weakref(enemy)
		_lights = weakref(lights)
		z_index = 20  # Over the nightmares
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # 1x crisp marks
		global_position = enemy.global_position

	func _process(_delta: float) -> void:
		var enemy = _enemy.get_ref()
		var lights = _lights.get_ref()
		var state: Array = lights.mark_state(enemy) if lights != null and is_instance_valid(enemy) else []
		if state.is_empty():
			queue_free()
			return
		global_position = enemy.global_position
		if state != _state:
			_state = state
			queue_redraw()
		# The sheets loop on their own clocks: redraw when a shown one's frame changes
		var stamp: int = lights.mark_stamp(_state)
		if stamp != _stamp:
			_stamp = stamp
			queue_redraw()
		# Full Glow's ring lies on the ground under the nightmare (its own node at z -1); the drawn arc without the sheet
		var ring_on: bool = bool(_state[5]) and lights.has_evo_mark(&"lf_full_glow_ring")
		if ring_on and _ring == null:
			_ring = GlowRing.new(lights)
			add_child(_ring)
		if _ring != null:
			_ring.visible = ring_on
			if ring_on and _ring.frame_changed():
				_ring.queue_redraw()

	# Placed from the nightmare's health-bar centre B (Enemy._bar_offset; Roguelite asset chat, owner 2026-10-23,
	# placement_mock.png): the marks sit in the gap between the bar and the head, never on the bar or the status row.
	func _draw() -> void:
		if _state.is_empty():
			return
		var lights = _lights.get_ref()
		var art: bool = lights != null
		var enemy = _enemy.get_ref()
		var bar: Vector2 = enemy._body_offset() + enemy._bar_offset if enemy != null and "_bar_offset" in enemy else BAR_DEFAULT  # Where its HUD draws the bar
		for i in int(_state[0]):  # Strung Lights: a spark pip per glow entered, hung just under the bar (lf_strung_pip)
			var pip: Vector2 = bar + Vector2(-12 + 6 * i, 6)
			if not (art and lights.evo_mark(self, &"lf_strung_pip", pip)):
				draw_circle(pip, 1.5, Palette.GLOW)
		if bool(_state[1]):  # Bonfire: a small flame holding a waiting crit (lf_waiting_flame), at the bar's left
			var base: Vector2 = bar + WAITING_FLAME_AT
			if not (art and lights.evo_mark(self, &"lf_waiting_flame", base)):
				draw_circle(base + Vector2(0, -3), 3.0, Color(Palette.EMBER, 0.85))
				draw_circle(base + Vector2(0, -4), 1.5, Palette.GOLD)
		if int(_state[2]) >= 0:  # Moth to Flame: a larger flame, white once its 4 hits are in, at the bar's right
			var sheet: StringName = &"lf_moth_flame_ready" if int(_state[2]) > 0 else &"lf_moth_flame"
			var base: Vector2 = bar + MOTH_FLAME_AT
			if not (art and lights.evo_mark(self, sheet, base)):
				var core: Color = Palette.HEARTLIGHT if int(_state[2]) > 0 else Palette.GLOW
				draw_circle(base + Vector2(0, -5), 4.5, Color(Palette.GOLD, 0.7))
				draw_circle(base + Vector2(0, -6), 2.5, core)
		var star: Vector2 = bar + STAR_AT
		for i in int(_state[4]):  # Constellation: a pip per Warden counted, where the star will appear
			var pip: Vector2 = star + Vector2(-8 + 8 * i, 0)
			if not (art and lights.evo_mark(self, &"lf_constellation_pip", pip)):
				draw_circle(pip, 1.5, Palette.MOONLIGHT)
		if int(_state[3]) > 0:  # The star (lf_constellation_star) and its charges round it, a dotted thread to each
			if not (art and lights.evo_mark(self, &"lf_constellation_star", star)):
				for k in 4:
					draw_line(star, star + Vector2(6, 0).rotated(PI * 0.5 * k), Color(Palette.HEARTLIGHT, 0.8), 1.5)
			for i in mini(int(_state[3]), STAR_CHARGES.size()):  # Spent from the last
				var dot: Vector2 = star + STAR_CHARGES[i]
				draw_dashed_line(star, dot, Color(Palette.GOLD, 0.4), 1.0, 1.0)
				if not (art and lights.evo_mark(self, &"lf_constellation_pip", dot)):
					draw_circle(dot, 1.2, Palette.HEARTLIGHT)
		if bool(_state[5]) and not (art and lights.has_evo_mark(&"lf_full_glow_ring")):  # Full Glow: the light it carries
			draw_arc(Vector2(0, -8), 14.0, 0.0, TAU, 20, Color(Palette.GLOW, 0.45), 2.0)

# Full Glow's carried light under a lit nightmare: lf_full_glow_ring centred on its feet (the LanternMark's origin), on
# the ground (z -1, absolute: under the nightmares, over the path).
class GlowRing extends Node2D:
	var _lights: WeakRef
	var _frame := -1

	func _init(lights: Node) -> void:
		_lights = weakref(lights)
		name = "FullGlowRing"
		z_as_relative = false
		z_index = -1
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func frame_changed() -> bool:
		var lights = _lights.get_ref()
		var frame: int = lights.mark_stamp_of(&"lf_full_glow_ring") if lights != null else 0
		if frame == _frame:
			return false
		_frame = frame
		return true

	func _draw() -> void:
		var lights = _lights.get_ref()
		if lights != null:
			lights.evo_mark(self, &"lf_full_glow_ring", Vector2.ZERO)

# --- Calling evolutions: the helpers --------------------------------------------------------------------------------

# The options of a recursive hop from `request`: same chain, one more hop (TD correction 3: never a new event id).
func _hop(request: Dictionary, extra: Dictionary) -> Dictionary:
	var opts := {"hops": int(request.get("hops", 0)) + 1}
	if request.has("calling"):
		opts["calling"] = request.calling  # F1: a Calling jump's hop is one too
	if request.has("row"):
		opts["row"] = request.row  # R1: an evolution's jump stays damage only down the chain
	opts.merge(extra, true)
	return opts

# Whether `request` may hop again (a chain is never longer than EVENT_MAX).
func _can_hop(request: Dictionary) -> bool:
	return int(request.get("hops", 0)) + 1 < EVENT_MAX

# --- Support: borrowed light (Borrowed Light, Lantern Wake, Show the Way, Full Glow, Sightline, Constellation, North Star) --

# Borrowed Light (final pass 2026-10-24): another family's Warden's direct hit on a Lit nightmare (no Sprouts or walls; until
# the second family pick, Firefly Wardens' too) jumps a third to the nearest other Lit nightmare, once a second per Warden.
# Sightline: half, on pale path, to the healthiest other Lit nightmare of the nearest SIGHT_POOL. Constellation: a nightmare
# under a star jumps its next STAR_HITS hits in full, from any Warden, within the same clock (on pale path to the healthiest).
# Jumps are a share of the real hit (per own attack: no per-output cap), capped by the light's brightness (3 s of the
# lighting Firefly). Evolution jumps are damage only for every other card ("row", R1).
func _borrowed_light(id: int, event, source, enemy, at: Vector2, cap: float) -> void:
	var stars := int(enemy.get_meta(STAR_META, 0)) if evo(EVO_CONSTELLATION) else 0
	var lends := is_other_family(source) or (_one_family and is_firefly(source))
	if (stars > 0 or lends) and _now() >= float(source.get_meta(LAMP_META, -INF)):
		var pale := evo(EVO_SIGHT) and is_pale(enemy)
		var targets := _healthiest_lit(at, [enemy]) if pale else nearest_lit(at, [enemy])
		if not targets.is_empty():
			source.set_meta(LAMP_META, _now() + LAMP_EVERY)
			var share := LAMP_SHARE
			var own := EVO_BORROWED
			if stars > 0:
				share = 1.0
				own = EVO_CONSTELLATION
				if stars > 1:
					enemy.set_meta(STAR_META, stars - 1)
				else:
					enemy.remove_meta(STAR_META)
			elif pale:
				share = SIGHT_SHARE
				own = EVO_SIGHT
			var limit := cap
			_fork(id, source, at, targets[0], event.base * share, limit, {"origin": enemy, "color": Palette.GLOW,
				"width": 3.0 if stars > 0 else 2.0, "credit": own, "row": true, "borrowed": stars <= 0,
				"glowing": _wake_ids.has(source.get_instance_id())})
			credit(own, targets[0].global_position, source)
	_star_note(source, enemy)

# Show the Way (from _evolved_strike): a Borrowed Light jump that landed carries on once more to another Lit nightmare, at
# half, in full when it started at a Warden that glows (Lantern Wake). Same event (a hop: never a nightmare the event already
# struck, never the one the hit was on, inside EVENT_MAX), same cap; never a third time.
func _show_the_way(request: Dictionary, source, target, at: Vector2) -> void:
	var skip: Array = [target]
	var left = request.get("jump_from")
	if is_instance_valid(left):
		skip.append(left)
	var next := _fresh_lit(at, int(request.event), skip)
	if next.is_empty():
		return
	var share := 1.0 if request.get("glowing", false) else SHOW_SHARE
	var opts := _hop(request, {"color": Palette.GLOW, "width": 2.0, "credit": EVO_SHOW})
	_fork(int(request.event), source, at, next[0], float(request.amount) * share, float(request.cap), opts)
	credit(EVO_SHOW, next[0].global_position, source)

# Full Glow: a nightmare hit by a glowing Warden (a Lantern Wake source) stays Lit for FULL_GLOW_TIME s wherever it walks;
# a new hit starts the time again. Never reveals hidden nightmares (_reveals skips it).
func _glow_on(enemy, source) -> void:
	var wake: Dictionary = _wake_ids.get(source.get_instance_id(), {})
	if wake.is_empty() or not _living(enemy):
		return
	enemy.set_meta(LIT_UNTIL_META, [_now() + FULL_GLOW_TIME, weakref(source), int(wake.light)])
	_mark(enemy)

# Constellation: STAR_WARDENS different Wardens' direct hits on one nightmare on pale path within STAR_WINDOW s light a star
# over it (its next STAR_HITS hits jump in full); North Star: a boss or a Deeply Blighted nightmare on any Lit path, from
# NORTH_WARDENS. Each nightmare once every STAR_LOCK s.
func _star_note(source, enemy) -> void:
	if not evo(EVO_CONSTELLATION) or not _living(enemy) or not _kit().counts_as_warden(source):
		return  # (Different Wardens: never Sprouts or walls; final pass 2026-10-24)
	var now := _now()
	if now < float(enemy.get_meta(STAR_NEXT_META, -INF)) or int(enemy.get_meta(STAR_META, 0)) > 0:
		return
	var big: bool = evo(EVO_NORTH_STAR) and ((enemy.enemy_data != null and enemy.enemy_data.is_boss) or bool(enemy.get("elite")))
	var pale := is_pale(enemy)
	if not pale and not big:
		return
	var roster: Dictionary = enemy.get_meta(STAR_ROSTER_META, {})
	roster[source.get_instance_id()] = now
	for key in roster.keys():
		if now - float(roster[key]) > STAR_WINDOW:
			roster.erase(key)
	enemy.set_meta(STAR_ROSTER_META, roster)
	_mark(enemy)
	if roster.size() < (NORTH_WARDENS if big else STAR_WARDENS):
		return
	enemy.remove_meta(STAR_ROSTER_META)
	enemy.set_meta(STAR_META, STAR_HITS)
	enemy.set_meta(STAR_NEXT_META, now + STAR_LOCK)
	Reactions._effect(&"spark_burst", enemy.global_position + Vector2(0, -40), self, 0.7)  # A star lights over it
	credit(EVO_NORTH_STAR if big and (not pale or roster.size() < STAR_WARDENS) else EVO_CONSTELLATION, enemy.global_position, source)

# Embers: a dispel on gold path leaves an ember on its step for EMBER_TIME. Witchfire: an ember within HEARTH_JOIN steps
# of a pile joins it (up to HEARTH_MAX). At most EMBER_MAX piles.
func _drop_ember(enemy, source, amount: float, cap: float) -> void:
	var step := _step_of(enemy)
	if step < 0 or amount <= 0.0:
		return
	var until := _now() + EMBER_TIME
	if evo(EVO_WITCHFIRE):
		for s in _embers:
			if absi(int(s) - step) <= HEARTH_JOIN:
				var pile: Dictionary = _embers[s]
				if int(pile.count) < HEARTH_MAX:
					pile.count = int(pile.count) + 1
					pile.amount = float(pile.amount) + amount
					pile.cap = float(pile.cap) + cap
					pile.source = weakref(source)
				pile.until = until
				queue_redraw()
				return
	elif _embers.has(step):
		var pile: Dictionary = _embers[step]
		if amount > float(pile.amount):
			pile.amount = amount
			pile.cap = cap
			pile.source = weakref(source)
		pile.until = until
		return
	if _embers.size() >= EMBER_MAX:
		return
	_embers[step] = {"amount": amount, "cap": cap, "source": weakref(source), "until": until, "count": 1}
	queue_redraw()

# Embers (polled): the next nightmare to reach an ember takes it (half the dispelling hit); with Witchfire the pile
# bursts on the nightmares within 1 cell. Bosses take half (_strike), so this is Lantern Light's answer to a boss.
func _ember_poll(now: float) -> void:
	var reach := EMBER_REACH * _cell()
	for step in _embers.keys():
		var pile: Dictionary = _embers[step]
		if now > float(pile.until) or not _step_px.has(int(step)):
			_embers.erase(step)
			queue_redraw()
			continue
		var at: Vector2 = _step_px[int(step)]
		var near: Array = Tower.nightmares_near(get_tree(), at, reach).filter(func(e) -> bool:
			return _living(e) and e.global_position.distance_to(at) <= reach)
		if near.is_empty():
			continue
		_embers.erase(step)
		queue_redraw()
		var source = pile.source.get_ref()
		var id := _next_event()
		var amount: float = minf(float(pile.amount), float(pile.cap))
		var targets: Array = near.slice(0, 1)
		if evo(EVO_WITCHFIRE):
			var burst := HEARTH_CELLS * _cell()
			targets = Tower.nightmares_near(get_tree(), at, burst).filter(func(e) -> bool:
				return _living(e) and e.global_position.distance_to(at) <= burst)
			targets.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(at) < b.global_position.distance_squared_to(at))
			targets = targets.slice(0, HEARTH_TARGETS)
			Reactions._effect(&"spark_burst", at, self, 0.7 + 0.2 * float(pile.count))
			credit(EVO_WITCHFIRE, at)
		else:
			Reactions._effect(&"hit_light", at, self)
			credit(EVO_EMBERS, at)
		for target in targets:
			_strike({"event": id, "source": source, "from": at, "target": target, "amount": amount, "cap": float(pile.cap),
				"final": true, "color": Palette.EMBER, "credit": EVO_WITCHFIRE if evo(EVO_WITCHFIRE) else EVO_EMBERS, "calling": true})

# After a jump struck (the Firefly start with any evolution): Show the Way, and the retired Bale-fires / Swarm Night (old
# saves). `before`: the sources lighting the target before the hit.
func _evolved_strike(request: Dictionary, source, target, at: Vector2, before: Array, step: int) -> void:
	var dead := not _living(target)
	if not before.is_empty():
		_credit_light(before, at)
	if not _can_hop(request):
		return
	var event: int = request.event
	if evo(EVO_SHOW) and request.get("borrowed", false):
		_show_the_way(request, source, target, at)
	if dead and request.has("relay") and evo(EVO_BALE) and int(request.relay) < BALE_HOPS:
		var parent := request.duplicate()
		parent.erase("target")
		_torch(event, source, at, step, float(request.amount), float(request.cap), parent, null, [target])  # Hard cards 2026-10-16
	if evo(EVO_SWARM) and _lit_count >= SWARM_AT and not request.get("swarm", false) and not request.get("final", false):
		var next := _fresh_lit(at, event, [target])
		if not next.is_empty():
			var opts := _hop(request, {"swarm": true, "color": Palette.HEARTLIGHT, "credit": EVO_SWARM, "calling": true})
			_fork(event, source, at, next[0], float(request.amount) * SWARM_SHARE, float(request.cap), opts)
			credit(EVO_SWARM, next[0].global_position, source)

# Waiting Spark: a fork with nowhere to go waits in its light.
func _wait(lights: Array, source, amount: float, cap: float) -> void:
	if not _rule(WAITING_SPARK) or lights.is_empty() or amount <= 0.0:
		return
	var light: int = lights[0]
	var waiting: Array = _sparks.get(light, [])
	if waiting.size() >= SPARK_MAX:
		return
	waiting.append({"amount": amount, "source": weakref(source), "until": _now() + SPARK_TIME, "cap": cap})
	_sparks[light] = waiting
	queue_redraw()

# --- The lent cards: "near a Firefly Warden", no Lit and no lights ------------------------------------------------

# The strongest Firefly Warden near `tower` (within NEAR_CELLS on both axes), or null.
func firefly_near(tower):
	var near := NEAR_CELLS * _cell()
	var best = null
	var best_dps := -1.0
	for source in _sources:
		var jar = source.tower
		if source.sprout or not is_instance_valid(jar) or jar == tower:
			continue
		if absf(jar.global_position.x - tower.global_position.x) > near or absf(jar.global_position.y - tower.global_position.y) > near:
			continue
		var dps: float = jar.get_damage() * jar.get_attacks_per_second()
		if dps > best_dps:
			best_dps = dps
			best = jar
	return best

func _near_enemies(at: Vector2, skip: Array) -> Array:
	var near := NEAR_CELLS * _cell()
	var found: Array = _enemies().filter(func(e) -> bool:
		return not skip.has(e) and absf(e.global_position.x - at.x) <= near and absf(e.global_position.y - at.y) <= near)
	found.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(at) < b.global_position.distance_squared_to(at))
	return found

func _lent_rules(id: int, event, source, enemy, dispel: bool, is_hit: bool, is_bolt: bool, calling: bool = false) -> void:
	var at: Vector2 = enemy.global_position
	var now := _now()
	if is_bolt:
		return  # Chain of Lanterns' bolt half is gone (hard cards 2026-10-16): only Reactions jump (_chain_more)
	var prev: Array = enemy.get_meta(FF_HIT_META, [])  # The Firefly hit before this one: Sparks Fly reads it, so a Jar's hit counts after another Jar's
	if is_firefly(source) and event.kind == &"hit" and (_rule(SPARKS_FLY) or _rule(CHAIN_OF_LANTERNS) or _rule(BRUSHFIRE)):
		enemy.set_meta(FF_HIT_META, [now, weakref(source)])  # Hit by a Firefly Warden (any form) just now: Sparks Fly, Chain of Lanterns, Brushfire
	if not calling and _rule(BRUSHFIRE) and event.tag in BRUSH_TAGS and _firefly_hit_recently(enemy, now):
		_brush_add(event, source, enemy)
	if is_hit and _rule(THUNDERSTRUCK):
		enemy.set_meta(THUNDER_HIT_META, now)  # Thunderstruck's "hit in the last 2 s"
	var taken := _taken_by(id) if not _queue.is_empty() else []  # F4 (f1_spec.md): built once, before any lent card queues
	if is_hit:
		if _rule(LENT_CROSSFIRE) and not calling:
			_crossfire(id, event, source, enemy, at, now)
		if _rule(NOTHING_WASTED):
			_nothing_wasted(id, event, source, enemy, at, taken)
		if _rule(FLASHOVER) and not calling:
			_flash_note(event, source, enemy)
		if _rule(SPARKS_FLY):  # Any Warden but the Firefly Warden that started the 2 s (own family too, owner 2026-10-15)
			_sparks_fly(id, event, source, enemy, at, now, prev, taken)
	if _heavy_now:
		# Hammerfall: another family's heavy Warden, or a Sprout, near a Firefly Warden jumps half of each attack
		if _rule(HAMMERFALL) and (is_other_family(source) and is_heavy(source) or source.tower_data.get_id() == "sprout"):
			var jar = firefly_near(source)
			var targets := _fan_out(at, [enemy], taken) if jar != null else []
			if not targets.is_empty():
				_fork(id, source, at, targets[0], event.base * HAMMER_SHARE, _lent_cap(source, jar), {"heavy": true, "credit": HAMMERFALL})  # Sprouts too. No re-jump on a dispel (owner 2026-10-17: Bale-fires / Pyre's verb); an old save holding Knock-On keeps it
		# Thunderstruck: another family's heavy Warden near a Firefly Warden: its hit fans a quarter to up to 4 near it that any
		# Warden hit in the last THUNDER_RECENT s (non-status builds 2026-10-19; was: carrying a status), 1.5 s of that Firefly's damage at most
		var thunder_jar = null  # A Firefly heavy form is its own Firefly Warden (own family too, owner 2026-10-15)
		# Keyword chips 2026-10-16: any heavy hit (the target needs no status)
		if _rule(THUNDERSTRUCK) and is_heavy(source) and (is_firefly(source) or is_other_family(source)):
			thunder_jar = source if is_firefly(source) else firefly_near(source)
		if thunder_jar != null:
			var cap_fan: float = thunder_jar.get_damage() * thunder_jar.get_attacks_per_second() * THUNDER_CAP_SECONDS
			var fan: Array = _hit_recently(_near_enemies(at, [enemy] + taken), now) if not taken.is_empty() else []  # F4: others first
			if fan.is_empty():
				fan = _hit_recently(_near_enemies(at, [enemy]), now)
			fan = fan.slice(0, THUNDER_MAX)
			for other in fan:  # The cap covers the whole fan
				_fork(id, source, at, other, minf(event.base * THUNDER_SHARE, cap_fan / maxf(fan.size(), 1.0)), cap_fan, {"heavy": true, "final": true, "credit": THUNDERSTRUCK})  # final: Hammerfall never re-jumps it (council full_review 2026-10-17)
				if _living(other) and not other.statuses.is_boss:
					# Each jump adds 1 Charged, from the Firefly Warden (its bolt, never the heavy Warden's: card pass 2026-10-16)
					SETUP.begin(StringName(SETUP.rule_card(dream_state, THUNDERSTRUCK)))  # Setup credit 2026-10-16
					thunder_jar._apply_one_status(other, EnemyStatuses.STATIC, THUNDER_STATIC, thunder_jar.get_damage(), false)
					SETUP.end()
	# Live Wire and Like to Like: retired (2026-10-13 / earlier); an old save keeps them
	if calling or not is_other_family(source):
		return
	var jar = firefly_near(source)
	if jar == null:
		return
	var cap: float = jar.get_damage() * jar.get_attacks_per_second() * BRIGHTNESS_SECONDS
	if dispel and _rule(LENT_LIVE_WIRE) and not (class_on() and is_lit(enemy)):  # On a Firefly start it replaces the Calling's jump, never adds one
		var targets := _near_enemies(at, [enemy])
		if not targets.is_empty():
			_fork(id, source, at, targets[0], _hit_size(source, is_hit, false) * LIVE_WIRE_SHARE, cap)
			return  # One fork per hit across the three lent cards
	if _rule(LIKE_TO_LIKE) and enemy.statuses.has(EnemyStatuses.STATIC):
		var amount: float = event.base
		if not is_hit:
			if now < float(enemy.get_meta(LIKE_META, -INF)):
				return
			enemy.set_meta(LIKE_META, now + LIKE_TICK_EVERY)
			amount = source.get_damage() * source.get_attacks_per_second()  # That second's damage
		elif not _new_like_hit(source, now):
			return  # A pulse or splash forks once
		for other in _near_enemies(at, [enemy]):
			if other.statuses.has(EnemyStatuses.STATIC):
				_fork(id, source, at, other, amount * LIKE_SHARE, cap)
				break

# Nothing Wasted: the damage a nightmare's shell (the blight coat) soaks up from a hit, by a Firefly Warden or a Warden
# near one, jumps to the nearest nightmare near it without a shell. (Resistances are gone, enemy_design.md ed6f573b:
# it read the resisted part before.)
func _with_status(list: Array) -> Array:
	return list.filter(func(e) -> bool: return e.statuses.count() > 0)

func _hit_recently(list: Array, now: float) -> Array:
	return list.filter(func(e) -> bool: return now - float(e.get_meta(THUNDER_HIT_META, -INF)) <= THUNDER_RECENT)

func _nothing_wasted(id: int, event, source, enemy, at: Vector2, taken: Array = []) -> void:
	if event.coat_soaked <= 0.0:
		return
	var jar = source if is_firefly(source) else firefly_near(source)
	if jar == null:
		return
	var others: Array = _near_enemies(at, [enemy] + taken).filter(func(e) -> bool: return float(e.coat) <= 0.0) if not taken.is_empty() else []
	for other in (others if not others.is_empty() else _near_enemies(at, [enemy])):  # F4: other jumps' targets last
		if float(other.coat) <= 0.0:
			_fork(id, source, at, other, event.coat_soaked, _lent_cap(source, jar))
			return

# Sparks Fly: every 3rd hit a Warden (any but the Firefly Warden that started the 2 s; Sprouts and other Firefly Wardens
# count) lands on a nightmare a Firefly Warden hit in the last 2 s jumps on at half. Counted per Warden and nightmare; an
# area attack counts once. `lit` = the Firefly hit before this one (read before _lent_rules records this hit).
func _sparks_fly(id: int, event, source, enemy, at: Vector2, now: float, lit: Array, taken: Array = []) -> void:
	if lit.is_empty() or now - float(lit[0]) > SPARKS_WINDOW or lit[1].get_ref() == source:
		return
	if int(source.get_meta(SPARKS_FRAME_META, -1)) == Engine.get_process_frames():
		return
	source.set_meta(SPARKS_FRAME_META, Engine.get_process_frames())
	var counts: Dictionary = enemy.get_meta(SPARKS_META, {})
	var n := int(counts.get(source.get_instance_id(), 0)) + 1
	counts[source.get_instance_id()] = n % SPARKS_EVERY_HIT
	enemy.set_meta(SPARKS_META, counts)
	if n < SPARKS_EVERY_HIT:
		return
	var targets := _fan_out(at, [enemy], taken)  # F4
	if not targets.is_empty():
		_fork(id, source, at, targets[0], event.base * SPARKS_SHARE, _lent_cap(null, lit[1].get_ref()))  # Capped even from a Firefly Warden, as Chain of Lanterns (council full_review 2026-10-17)

# Flashover: one attack's hits are gathered by Warden and frame; the next frame, an area attack that hit 2 or more
# jumps half (of the largest hit) to the nearest nightmare it missed. Another family's Warden near a Firefly Warden;
# Sparkler and Starburst near another Firefly Warden.
func _flash_note(event, source, enemy) -> void:
	var sid: int = source.get_instance_id()
	var frame := Engine.get_process_frames()
	var entry: Dictionary = _flashes.get(sid, {})
	if entry.is_empty() or int(entry.frame) != frame:
		if not entry.is_empty():
			return  # The last attack's hits are still waiting (struck next frame)
		if is_firefly(source) and not SPARKLERS.has(source.tower_data.get_id()):
			return
		if not is_other(source) and not is_firefly(source):
			return
		entry = {"frame": frame, "source": weakref(source), "hits": [], "base": 0.0}
		_flashes[sid] = entry
	entry.hits.append(weakref(enemy))
	entry.base = maxf(float(entry.base), event.base)

func _flash_over() -> void:
	var frame := Engine.get_process_frames()
	for sid in _flashes.keys():
		var entry: Dictionary = _flashes[sid]
		if int(entry.frame) >= frame:
			continue
		_flashes.erase(sid)
		var source = entry.source.get_ref()
		if not is_instance_valid(source) or entry.hits.size() < FLASHOVER_MIN:
			continue
		var jar = firefly_near(source)
		if jar == null:
			continue
		var hit: Array = []
		var centre := Vector2.ZERO
		for ref in entry.hits:
			var e = ref.get_ref()
			if is_instance_valid(e):
				hit.append(e)
				centre += e.global_position
		if hit.is_empty():
			continue
		centre /= hit.size()
		var targets := _near_enemies(centre, hit)
		if not targets.is_empty():
			_fork(_next_event(), source, centre, targets[0], float(entry.base) * FLASHOVER_SHARE, _lent_cap(null, jar), {"final": true})  # Always capped (council full_review 2026-10-17)

# Brushfire: a Charged nightmare's damage over time this second, by its source.
func _brush_add(event, source, enemy) -> void:
	var key: int = enemy.get_instance_id()
	var entry: Dictionary = _brush.get(key, {"enemy": weakref(enemy), "source": weakref(source), "amount": 0.0})
	entry.amount = float(entry.amount) + event.amount
	_brush[key] = entry

func _brush_fire() -> void:
	var entries := _brush.values()
	_brush.clear()
	for entry in entries:
		var enemy = entry.enemy.get_ref()
		var source = entry.source.get_ref()
		if not _living(enemy) or not is_instance_valid(source):
			continue
		var targets := _near_enemies(enemy.global_position, [enemy])
		if not targets.is_empty():
			var lit: Array = enemy.get_meta(FF_HIT_META, [])
			var cap := _lent_cap(source, lit[1].get_ref() if not lit.is_empty() else null)
			if is_firefly(source):
				cap = _lent_cap(null, source)  # Damage over time is never a Firefly hit: always capped
			_fork(_next_event(), source, enemy.global_position, targets[0], float(entry.amount) * BRUSH_SHARE, cap, {"final": true})

# Whether a Firefly Warden hit `enemy` in the last 2 s (Brushfire).
func _firefly_hit_recently(enemy, now: float) -> bool:
	var lit: Array = enemy.get_meta(FF_HIT_META, [])
	return not lit.is_empty() and now - float(lit[0]) <= SPARKS_WINDOW

func _new_like_hit(source, now: float) -> bool:
	if int(source.get_meta(&"ff_like_frame", -1)) == Engine.get_process_frames():
		return false
	source.set_meta(&"ff_like_frame", Engine.get_process_frames())
	return true

# Crossfire, reworked: a Firefly Warden and another family's Warden near it hit one nightmare within a second.
func _crossfire(id: int, event, source, enemy, at: Vector2, now: float) -> void:
	var firefly := is_firefly(source)
	if not firefly and not is_other_family(source):
		return
	var last: Dictionary = enemy.get_meta(CROSS_META, {})
	if now < float(last.get("wait", -INF)):
		return
	var other = last.get("source").get_ref() if last.has("source") else null
	if is_instance_valid(other) and other != source and now - float(last.at) <= CROSSFIRE_WINDOW and is_firefly(other) != firefly:
		var jar = source if firefly else other
		var partner = other if firefly else source
		var near := NEAR_CELLS * _cell()
		if absf(jar.global_position.x - partner.global_position.x) <= near and absf(jar.global_position.y - partner.global_position.y) <= near:
			var step := _step_of(enemy)
			var behind: Array = _enemies().filter(func(e) -> bool: return e != enemy and _step_of(e) >= 0 and _step_of(e) <= step)
			behind.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(at) < b.global_position.distance_squared_to(at))
			var amount: float = minf(event.base, float(last.base)) * CROSSFIRE_SHARE
			var cap: float = jar.get_damage() * jar.get_attacks_per_second() * BRIGHTNESS_SECONDS
			for target in behind.slice(0, CROSSFIRE_TARGETS):
				_fork(id, partner, at, target, amount, cap)
			enemy.set_meta(CROSS_META, {"wait": now + CROSSFIRE_WAIT})
			return
	enemy.set_meta(CROSS_META, {"source": weakref(source), "at": now, "base": event.base})  # Stored before defences

# --- Forks ------------------------------------------------------------------------------------------------------

# Queues a fork of `amount` from `from` to `target` for event `id`. `cap`: brightness (INF = none).
func _fork(id: int, source, from: Vector2, target, amount: float, cap: float, opts: Dictionary = {}) -> void:
	if amount <= 0.0 or not _living(target):
		return
	var request := {"event": id, "source": source, "from": from, "target": target, "amount": minf(amount, cap), "cap": cap,
		"heavy": opts.get("heavy", false), "final": opts.get("final", false)}
	for key in opts:  # Evolutions: hops, relay, swarm, row, borrowed, glowing, color, width
		if key != "origin":
			request[key] = opts[key]
	if not request.has("jump_from"):  # Keyword chips 2026-10-16: the nightmare it leaves, for DreamState.note_jump
		request["jump_from"] = opts.origin if opts.has("origin") else _nightmare_at(from, target)
	_queue.append(request)

# The nightmare standing at `at` (within half a cell), not `skip`: where a jump leaves from (null if none).
func _nightmare_at(at: Vector2, skip) -> Node2D:
	var best: Node2D = null
	var best_sq := pow(_cell() * 0.5, 2.0)
	for enemy in Tower.nightmares_near(get_tree(), at, _cell() * 0.5):
		if enemy == skip or not is_instance_valid(enemy):
			continue
		var sq: float = enemy.global_position.distance_squared_to(at)
		if sq <= best_sq:
			best_sq = sq
			best = enemy
	return best

# Gathering Storm's count on `target` (DreamState.note_jump): each jump a nightmare takes makes the next one on it 25%
# stronger, up to GATHER_MAX; resets after GATHER_RESET s without one. Returns this jump's multiplier.
static func gather(target: Node2D, now: float) -> float:
	var gathered: Array = target.get_meta(GATHER_META, [0, -INF])
	var taken := int(gathered[0]) if now - float(gathered[1]) <= GATHER_RESET else 0
	target.set_meta(GATHER_META, [taken + 1, now])
	return minf(1.0 + GATHER_STEP * taken, GATHER_MAX)

# One fork per nightmare per event (the largest wins), at most EVENT_MAX per event. A recursive hop (a frame later, same
# event) never strikes a nightmare its event already struck, and the event's total stays within EVENT_MAX.
func _flush() -> void:
	if _queue.is_empty():
		return
	var queue := _queue
	_queue = []
	var by_event := {}
	for request in queue:
		var per_target: Dictionary = by_event.get_or_add(request.event, {})
		var key: int = request.target.get_instance_id() if is_instance_valid(request.target) else 0
		if not per_target.has(key) or per_target[key].amount < request.amount:
			per_target[key] = request
	for id in by_event:
		var requests: Array = by_event[id].values()
		requests.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.amount > b.amount)
		var seen: Dictionary = _event_seen.get_or_add(id, {})
		for request in requests:
			if seen.size() >= EVENT_MAX:
				break
			var key: int = request.target.get_instance_id() if is_instance_valid(request.target) else 0
			if seen.has(key):
				continue
			seen[key] = true
			_strike(request)
	if _event_seen.size() > EVENT_MEMORY:
		for id in _event_seen.keys():
			if int(id) < _event - (EVENT_MEMORY >> 1):
				_event_seen.erase(id)

func _strike(request: Dictionary) -> void:
	var target = request.target
	if not _living(target):
		return
	var source = request.source if is_instance_valid(request.source) else null
	var amount: float = request.amount
	# Keyword chips 2026-10-16: every jump goes through DreamState.note_jump (Gathering Storm's count, Shared Spark). Card
	# pass 2026-10-16 (player review 4.2): Gathering Storm multiplies after the jump's own cap; hard cards 2026-10-16
	# (owner: +200%): the cap stretches with the bonus, never past GATHER_MAX times its value
	# R1 (evo_shared_spec.md, 2026-10-23): an evolution's jump ("row") is damage only for every other card: no note_jump
	# (Gathering Storm, Struck Twice, Shared Spark), never an F1 Calling output.
	var row: bool = request.get("row", false)
	var from_enemy = request.get("jump_from")
	var gather_mult: float = dream_state.note_jump(source, from_enemy if is_instance_valid(from_enemy) else null, target, amount) \
		if dream_state != null and not row else 1.0
	if gather_mult > 1.0:
		amount = minf(amount * gather_mult, float(request.cap) * gather_mult)
		var taken := roundi((gather_mult - 1.0) / GATHER_STEP)
		request["width"] = maxf(float(request.get("width", 4.0)), 4.0 + GATHER_WIDTH_STEP * mini(taken, GATHER_WIDTH_MAX))
	if not _living(target):
		return  # (Shared Spark's stack can complete a Reaction that dispels it)
	if target.enemy_data != null and target.enemy_data.is_boss:
		amount *= BOSS_SHARE
	var at: Vector2 = target.global_position
	var start: Vector2 = request.from  # The bolt is drawn body to body (walking lanes); the jump's logic keeps the route positions
	if is_instance_valid(from_enemy) and start.is_equal_approx(from_enemy.global_position):
		start = CLASS_KIT.body(from_enemy)
	var bolt := ChainBolt.new(PackedVector2Array([start, CLASS_KIT.body(target)]), request.get("color", Palette.GOLD), float(request.get("width", 4.0)))
	Reactions._world(self).add_child(bolt)
	forks_thrown += 1
	var evolved := _evolved()
	var before: Array = _lit_sources(target) if evolved else []  # Read before the hit: a dispelled nightmare leaves the light
	var step := _step_of(target) if evolved else -1
	var own: StringName = request.get("credit", &"")  # Setup credit 2026-10-16: the evolution or card this jump is (its own damage)
	if own != &"" and dream_state != null:
		dream_state.begin_own_hit(own, target)
	if request.get("calling", false) and class_on() and not row:
		DamageLog.calling_next = StringName(FAMILY)  # F1 (f1_spec.md): armed just before; take_damage takes it on entry
	target.take_damage(amount, source.tower_data.line if source is Tower else LINE, false, false, source, FORK_TAG)
	DamageLog.calling_next = &""
	if own != &"" and dream_state != null:
		dream_state.end_own_hit()
	if own == EVO_TORCH or own == EVO_BALE:
		credit(own, at, source)  # The callout once the throw has landed (council full_review 2026-10-17)
	if evolved:
		_evolved_strike(request, source, target, at, before, step)
	# A nightmare dispelled by a fork gives no fork. Knock-On is the one exception: a heavy Warden's fork, one more hop.
	if request.get("heavy", false) and not request.get("final", false) and _rule(KNOCK_ON) and not _living(target):
		var next := _near_enemies(at, [target]).slice(0, 1)
		if not next.is_empty():
			var hop := request.duplicate()
			hop.from = at
			hop["jump_from"] = target  # Keyword chips 2026-10-16: it leaves the nightmare just struck
			hop["credit"] = KNOCK_ON  # Setup credit 2026-10-16
			hop["calling"] = false  # (F1: a lent card's hop is never a Calling output)
			hop.target = next[0]
			hop.final = true  # The second fork never forks again and takes no leftover
			_strike(hop)

# --- Fireflies in the Grass: the Sprouts the player chose to glow (the Warden panel's button) ---------------------

# "" = this Sprout can be made to glow now; else why not.
func lit_sprout_blocker(sprout) -> String:
	if not class_on() or not _rule(LIT_SPROUTS):
		return "needs Fireflies in the Grass"
	if not (sprout is Tower) or sprout.tower_data.get_id() != "sprout":
		return "only a Sprout can glow"
	if not _resting():
		return "choose at a rest"  # Never mid-drift: a light moved to chase a pack (dream_council_review.md 26, fix 12)
	if sprout.get_meta(LIT_SPROUT_META, false):
		return ""
	var jars := 0
	var lit := 0
	for tower in _towers():
		if is_firefly(tower):
			jars += 1
			if tower.global_position.distance_to(sprout.global_position) <= glow_reach(tower):
				return "already inside a Firefly Warden's glow"
		elif tower.get_meta(LIT_SPROUT_META, false):
			lit += 1
	if lit >= jars:
		return "one glowing Sprout for each Firefly Warden"
	return ""

func _resting() -> bool:
	return dream_state == null or dream_state.get("drift_director") == null or dream_state.drift_director.resting

func set_lit_sprout(sprout, on: bool) -> bool:
	if on and lit_sprout_blocker(sprout) != "":
		return false
	if not on and not _resting():
		return false  # Chosen at a rest only, either way
	if on:
		sprout.set_meta(LIT_SPROUT_META, true)
	elif sprout.has_meta(LIT_SPROUT_META):
		sprout.remove_meta(LIT_SPROUT_META)
	_rebuild()
	return true

# Saved with the run (DreamState.to_save): the cells of the glowing Sprouts.
func to_save() -> Array:
	var cells: Array = []
	for tower in _towers():
		if tower.get_meta(LIT_SPROUT_META, false):
			cells.append([tower.cell.x, tower.cell.y])
	return cells

func load_save(cells: Array) -> void:
	for tower in _towers():
		for saved in cells:
			if saved is Array and saved.size() == 2 and tower.cell.is_equal_approx(Vector2(saved[0], saved[1])) \
					and tower.tower_data.get_id() == "sprout":
				tower.set_meta(LIT_SPROUT_META, true)
	_rebuild_in = 0.0

# --- Drawing: the glow on the path, gold where two Firefly Wardens' glows cross, and waiting sparks ----------------

# The glow is a soft band along the path's own line (user 2026-10-13, "fix the lit area": it was a flat square per lit
# cell, centred on whole cells while the path is a half-cell lane, so pale squares with gaps sat on the grass beside
# it). Each lit stretch of the route is three nested round-jointed lines (GLOW_BANDS: wide and dim to narrow and
# bright), so it fades out in three steps with no grid. Gold path is its own stretch, joined end to end.
# One group, one cap (user, the same day, a 102-Warden maze at drift 35: "large and bright, several cells wide ...
# stepped blocks ... the main thing on screen"): the first version added every band and every stretch on top of the
# others, 80 px wide, so close lanes merged into bright slabs. Now the lines are opaque inside one CanvasGroup (a
# brighter band covers a dimmer one, lanes side by side just meet) and the group is added to the map once at
# GLOW_CAP: nowhere is brighter than one lit path's centre, however the maze winds. The bands hug the path's ribbon
# (~40 px) with a few pixels of soft edge.
const GLOW_BANDS: Array[float] = [52.0, 40.0, 26.0]  # px wide, widest first
const GLOW_SHARES: Array[float] = [0.25, 0.5, 0.75]  # Each band's share of GLOW_CAP: a lit path's centre adds 0.75 × the cap
const GOLD_SHARES: Array[float] = [0.35, 0.7, 1.0]  # Gold path: the full cap at its centre
const GLOW_CAP := 0.55  # The most light the glow ever adds (the group's alpha). Owner 2026-10-14 "too faint": was 0.34 (a lit centre ~0.22, now ~0.41)
const GLOW_SHADER := "shader_type canvas_item;\nrender_mode unshaded, blend_add;\nuniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;\nvoid fragment() {\n\tvec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);\n\tif (c.a > 0.0001) {\n\t\tc.rgb /= c.a;\n\t}\n\tCOLOR *= c;\n}\n"
var _glow_lines: Array[Line2D] = []
var _glow_group: CanvasGroup  # Every glow line, flattened, then added to the map once (kept on this node, never static)

func _draw() -> void:
	# Lines are nodes: laid after the draw, whenever anything here asked for a redraw. With the glow sheets only when the
	# light map changed (the shimmer's redraws reuse the laid points).
	if not _glow_sheets_ready() or _laid_serial != _glow_serial:
		_laid_serial = _glow_serial
		_lay_glow.call_deferred()
	if not _lit_on():
		return
	_draw_glow_sheets()
	for light in _sparks:
		var spot := _light_spot(int(light))
		for i in _sparks[light].size():
			draw_circle(to_local(spot) + Vector2(-10 + 10 * i, -14), 3.0, Color(Palette.HEARTLIGHT, 0.9))
	# Embers / Witchfire: glowing coals on the path, one per ember in the pile
	for step in _embers:
		if not _step_px.has(int(step)):
			continue
		var coal := to_local(_step_px[int(step)])
		var count := int(_embers[step].count)
		for i in count:
			var offset := Vector2(-6.0 * (count - 1) + 12.0 * i, 0.0)
			draw_circle(coal + offset, 6.0, Color(Palette.EMBER, 0.85))
			draw_circle(coal + offset, 3.0, Color(Palette.GOLD, 0.95))
	# Glowworms and Lantern Wake: a lantern spark at the foot of each glowing Warden
	for source in _sources:
		if (source.get("worm", false) or source.get("wake", false)) and is_instance_valid(source.tower):
			draw_circle(to_local(source.tower.global_position) + Vector2(14, 18), 4.0, Color(Palette.GLOW, 0.9))
	# Sightline: pale path, a silver glint on each pale step (lf_pale_path_dot; the soft moonlit dot without the sheet)
	for cell in _pale:
		var step := to_local(Tower.MAP_GRID.calculate_map_position(cell))
		if not evo_mark(self, &"lf_pale_path_dot", step):
			draw_circle(step, 6.0, Color(Palette.MOONLIGHT, 0.45))

func _exit_tree() -> void:
	_clear_gold_marks()
	for node in [_gold_marks, _gold_tint]:
		if is_instance_valid(node):
			node.queue_free()
	if is_instance_valid(_glow_group):
		_glow_group.queue_free()
	_glow_group = null
	_glow_lines.clear()

func _lay_glow() -> void:
	for line in _glow_lines:
		if is_instance_valid(line):
			line.queue_free()
	_glow_lines.clear()
	if not _lit_on() or _glow.is_empty() or dream_state.get("map_generator") == null:
		if is_instance_valid(_glow_group):
			_glow_group.visible = false
		_clear_gold_marks()
		if not _glow_pts.is_empty():
			_glow_pts = PackedVector2Array()
			_glow_states = PackedInt32Array()
			queue_redraw()
		return
	var map: Node2D = dream_state.map_generator
	if not is_instance_valid(_glow_group):
		_glow_group = CanvasGroup.new()
		_glow_group.name = "FireflyGlow"
		_glow_group.fit_margin = 32.0
		_glow_group.clear_margin = 32.0
		var shader := Shader.new()
		shader.code = GLOW_SHADER
		var material := ShaderMaterial.new()
		material.shader = shader
		_glow_group.material = material
		_glow_group.self_modulate = Color(1, 1, 1, GLOW_CAP)  # multiplier: the cap on the added light
		map.path_layer.add_child(_glow_group)  # On the path layer: over the path's ribbon, under everything else
	_glow_group.visible = true
	var ground: Node2D = _glow_group
	var runs: Array = []  # [points, bright, joins_before, joins_after] per lit stretch
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var gold := _rule(WHERE_LIGHTS_MEET) or evo(EVO_BONFIRE)
	var states := PackedInt32Array()  # Per route point: 0 dark, 1 glow, 2 gold path
	for point in route:
		var state := 0
		for cell in dream_state.route_cells(point):
			if _glow.has(cell):
				state = maxi(state, 2 if gold and int(_glow[cell].jars) >= 2 else 1)
			if gold and _grown.has(cell):
				state = 2  # Spreading Flame's grown gold
		states.append(state)
	_lay_gold_marks(map, route, states)  # Above the capped glow: the gold edge, the warm tint under it, the embers
	if _glow_sheets_ready():
		_lay_glow_sheets(map, route, states)
		return
	var from := 0
	while from < route.size():
		if states[from] == 0:
			from += 1
			continue
		var to := from
		while to + 1 < route.size() and states[to + 1] == states[from]:
			to += 1
		# Where the glow goes on as gold (or the other way), the stretches share the point between them: no gap, no cap
		var joins_before := from > 0 and states[from - 1] != 0
		var joins_after := to + 1 < route.size() and states[to + 1] != 0
		var points := PackedVector2Array()
		for i in range(from, mini(to + 1 if joins_after else to, route.size() - 1) + 1):
			points.append(ground.to_local(map.to_global(Tower.MAP_GRID.calculate_map_position(route[i]))))
		if points.size() == 1:
			points.append(points[0] + Vector2(0.5, 0.0))  # One lit point: a round spot
		runs.append([points, states[from] == 2, joins_before, joins_after])
		from = to + 1
	# Band by band over every stretch, dimmest first: a lane's bright centre is never covered by its neighbour's edge
	for band in GLOW_BANDS.size():
		for run: Array in runs:
			var share: float = GOLD_SHARES[band] if run[1] else GLOW_SHARES[band]
			var base: Color = Palette.GOLD if run[1] else Palette.GLOW
			var line := Line2D.new()
			line.points = run[0]
			line.width = GLOW_BANDS[band]
			line.default_color = Color(base.r * share, base.g * share, base.b * share, 1.0)  # multiplier: the band's share of the light (opaque in the group)
			line.joint_mode = Line2D.LINE_JOINT_ROUND
			line.begin_cap_mode = Line2D.LINE_CAP_NONE if run[2] else Line2D.LINE_CAP_ROUND
			line.end_cap_mode = Line2D.LINE_CAP_NONE if run[3] else Line2D.LINE_CAP_ROUND
			line.round_precision = 6
			line.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			ground.add_child(line)
			_glow_lines.append(line)

# Bonfire's gold path at a glance (owner 2026-10-20, drift 10 Finale: "hard to see the difference between bonfire and
# regular lit paths"): inside the capped glow group the gold washed out to the same cream, so gold path gets marks of its
# own OUTSIDE the cap: a warm multiply tint under it (the ribbon reads amber), a thin gold edge along both sides of each
# gold stretch (over the glow, stopping where gold ends), and slow embers drifting up (none under reduced motion, fewer at
# Reduced effects). Plain lit path is unchanged. Visual only.
const GOLD_EDGE_HALF := 21.0  # px from the route line to the edge: the path ribbon is ~40 px wide
const GOLD_EDGE_WIDTH := 2.0
const GOLD_TINT := Color(1.0, 0.93, 0.8)  # multiplier: warms the ribbon under gold steps (owner 2026-10-21: "too orange"; was 1.0, 0.84, 0.6)
const GOLD_TINT_WIDTH := 40.0
var _gold_marks: Node2D  # Edge lines and the embers, on the path layer above the glow group
var _gold_tint: Node2D  # The multiply tint, on the path layer under the glow group

var _gold_key: Array = []  # The gold stretches last laid: the marks are rebuilt only when they change

func _clear_gold_marks() -> void:
	_gold_key = []
	for node in [_gold_marks, _gold_tint]:
		if is_instance_valid(node):
			for child in node.get_children():
				node.remove_child(child)  # Gone this frame: a queued old tint beside the new one doubled it (owner 2026-10-21: "bonfire shouldn't pulse")
				child.queue_free()
	if is_instance_valid(_gold_marks):
		_gold_marks.spots = PackedVector2Array()
		_gold_marks.visible = false
	if is_instance_valid(_gold_tint):
		_gold_tint.visible = false

func _lay_gold_marks(map: Node2D, route: PackedVector2Array, states: PackedInt32Array) -> void:
	# Per gold stretch: [points, joins_before, joins_after, gold-only point count]. The points are the glow band's own (the
	# next lit point too when it goes on as plain light), so the marks end flat exactly where the glow changes colour and
	# round only where the gold path truly ends (owner 2026-10-21: "looks like a piece cut off" where gold met lit path).
	var runs: Array = []
	var from := 0
	while from < route.size():
		if states[from] != 2:
			from += 1
			continue
		var to := from
		while to + 1 < route.size() and states[to + 1] == 2:
			to += 1
		var joins_before := from > 0 and states[from - 1] != 0
		var joins_after := to + 1 < route.size() and states[to + 1] != 0
		var run := PackedVector2Array()
		for i in range(from, (to + 1 if joins_after else to) + 1):
			run.append(map.to_global(Tower.MAP_GRID.calculate_map_position(route[i])))
		runs.append([run, joins_before, joins_after, to - from + 1])
		from = to + 1
	if runs == _gold_key and (runs.is_empty() or (is_instance_valid(_gold_marks) and _gold_marks.visible)):
		return  # The glow is relaid on every redraw; the gold marks only when the gold path itself changed
	_clear_gold_marks()
	_gold_key = runs.duplicate()
	if runs.is_empty() or not is_instance_valid(_glow_group):
		return
	var layer: Node = map.path_layer
	if not is_instance_valid(_gold_tint):
		var group := CanvasGroup.new()  # Every stretch's tint flattened, then multiplied once: overlaps at corners never darken
		group.fit_margin = 32.0
		group.clear_margin = 32.0
		_gold_tint = group
		_gold_tint.name = "FireflyGoldTint"
		var mul := CanvasItemMaterial.new()
		mul.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
		_gold_tint.material = mul
		layer.add_child(_gold_tint)
	layer.move_child(_gold_tint, _glow_group.get_index())  # Just under the glow: tint the ground, then the light adds
	if not is_instance_valid(_gold_marks):
		_gold_marks = GoldMarks.new()
		_gold_marks.name = "FireflyGoldMarks"
		layer.add_child(_gold_marks)
	layer.move_child(_gold_marks, _glow_group.get_index() + 1)  # Just over the glow: the cap never reaches it
	_gold_tint.visible = true
	_gold_marks.visible = true
	_gold_marks.moving = not _still()
	var spots := PackedVector2Array()
	var shapes: Array = []  # Every stretch's gold shape, joined below so corners and side-by-side lanes merge
	var cuts: Array = []  # [end point, outward direction, half width] per flat end
	for entry: Array in runs:
		var run: PackedVector2Array = entry[0]
		var tint_pts := PackedVector2Array()
		var edge_pts := PackedVector2Array()
		for k in run.size():
			tint_pts.append(_gold_tint.to_local(run[k]))
			edge_pts.append(_gold_marks.to_local(run[k]))
			if k < int(entry[3]):
				spots.append(_gold_marks.to_local(run[k]))  # Embers from gold steps only
		if edge_pts.size() == 1:
			tint_pts.append(tint_pts[0] + Vector2(0.5, 0.0))
			edge_pts.append(edge_pts[0] + Vector2(0.5, 0.0))
		var tint := Line2D.new()
		tint.points = tint_pts
		tint.width = GOLD_TINT_WIDTH
		tint.default_color = GOLD_TINT  # multiplier (the node multiplies the ground)
		tint.use_parent_material = false  # Opaque inside the group; the group multiplies once
		tint.joint_mode = Line2D.LINE_JOINT_ROUND
		tint.begin_cap_mode = Line2D.LINE_CAP_NONE if entry[1] else Line2D.LINE_CAP_ROUND
		tint.end_cap_mode = Line2D.LINE_CAP_NONE if entry[2] else Line2D.LINE_CAP_ROUND
		_gold_tint.add_child(tint)
		shapes.append_array(_gold_shape(edge_pts, entry[1], entry[2], cuts))
	for piece in _open_lines(_union_shapes(shapes), cuts):
		var edge := Line2D.new()
		edge.points = piece
		edge.width = GOLD_EDGE_WIDTH
		edge.default_color = Palette.GOLD
		edge.joint_mode = Line2D.LINE_JOINT_ROUND
		_gold_marks.add_child(edge)
	_gold_marks.spots = spots
	_gold_marks.queue_redraw()

# One gold stretch's shape: its outline at GOLD_EDGE_HALF from the route line (round bends and ends), cut flat at each
# end that goes on as plain lit path. Each flat end is added to `cuts` ([end point, outward direction, half width]).
func _gold_shape(pts: PackedVector2Array, flat_start: bool, flat_end: bool, cuts: Array) -> Array:
	var shapes: Array = Geometry2D.offset_polyline(pts, GOLD_EDGE_HALF, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND)
	var mine: Array = []
	if flat_start and pts.size() >= 2:
		mine.append([pts[0], (pts[0] - pts[1]).normalized(), GOLD_EDGE_HALF])
	if flat_end and pts.size() >= 2:
		mine.append([pts[pts.size() - 1], (pts[pts.size() - 1] - pts[pts.size() - 2]).normalized(), GOLD_EDGE_HALF])
	for cut in mine:
		var at: Vector2 = cut[0]
		var out: Vector2 = cut[1]
		var side := Vector2(-out.y, out.x) * (GOLD_EDGE_HALF * 2.0)
		var beyond := PackedVector2Array([at + side, at + side + out * 200.0, at - side + out * 200.0, at - side])
		var kept: Array = []
		for shape in shapes:
			kept.append_array(Geometry2D.clip_polygons(shape, beyond))
		shapes = kept
	cuts.append_array(mine)
	return shapes.filter(func(s: PackedVector2Array) -> bool: return not Geometry2D.is_polygon_clockwise(s))

# Every stretch's shape joined into one (owner 2026-10-21: "doesn't merge properly the lights in corners for bonfire"):
# where gold stretches meet or run side by side only the outer border is drawn. Holes (gold all around a Warden) are kept
# as their own loops.
func _union_shapes(shapes: Array) -> Array:
	var outers: Array = shapes.duplicate()
	var holes: Array = []
	var merged := true
	while merged:
		merged = false
		for i in outers.size():
			for j in range(i + 1, outers.size()):
				var joined: Array = Geometry2D.merge_polygons(outers[i], outers[j])
				var rings: Array = joined.filter(func(s: PackedVector2Array) -> bool: return not Geometry2D.is_polygon_clockwise(s))
				if rings.size() != 1:
					continue  # They don't touch
				holes.append_array(joined.filter(func(s: PackedVector2Array) -> bool: return Geometry2D.is_polygon_clockwise(s)))
				outers.remove_at(j)
				outers[i] = rings[0]
				merged = true
				break
			if merged:
				break
	return outers + holes

# The border loops, left open along each flat cut (where gold goes on as lit path, only the two sides run).
func _open_lines(shapes: Array, cuts: Array) -> Array:
	var lines: Array = []
	for outline: PackedVector2Array in shapes:
		var n := outline.size()
		var open_at := -1  # An edge lying on a cut: the outline opens there
		for i in n:
			if _on_cut(outline[i], cuts) and _on_cut(outline[(i + 1) % n], cuts):
				open_at = i
				break
		if open_at < 0:
			var loop := outline.duplicate()
			loop.append(outline[0])
			lines.append(loop)
			continue
		var piece := PackedVector2Array()
		for step in n:
			var i := (open_at + 1 + step) % n
			var j := (i + 1) % n
			if piece.is_empty():
				piece.append(outline[i])
			if _on_cut(outline[i], cuts) and _on_cut(outline[j], cuts):
				if piece.size() >= 2:
					lines.append(piece)
				piece = PackedVector2Array()
				continue
			piece.append(outline[j])
		if piece.size() >= 2:
			lines.append(piece)
	return lines

# Whether `p` lies on one of the flat-end cuts: on its line and within its half width of the end point (so a cut never
# takes another lane's edge that happens to line up with it).
static func _on_cut(p: Vector2, cuts: Array) -> bool:
	for c in cuts:
		var off: Vector2 = p - c[0]
		var out: Vector2 = c[1]
		if absf(off.dot(out)) < 0.75 and absf(off.dot(Vector2(-out.y, out.x))) <= float(c[2]) + 1.0:
			return true
	return false

# The embers over gold path: a few small motes rising slowly from its steps and fading (every 2nd step; every 4th at
# Reduced effects). Drawn on a calm clock (MOTE_FPS), never under reduced motion.
class GoldMarks extends Node2D:
	const MOTE_FPS := 15.0
	const MOTE_LIFE := 2.4  # Seconds from a step to gone
	const MOTE_RISE := 18.0  # px it climbs
	var spots := PackedVector2Array()
	var moving := true
	var _t := 0.0
	var _next := 0.0

	func _process(delta: float) -> void:
		if not moving or spots.is_empty() or not visible:
			return
		_t += delta
		if _t >= _next:
			_next = _t + 1.0 / MOTE_FPS
			queue_redraw()

	func _draw() -> void:
		if not moving or spots.is_empty():
			return
		var every := 4 if Fx.reduced() else 2
		for k in range(0, spots.size(), every):
			var phase := fmod(_t / MOTE_LIFE + float(k) * 0.37, 1.0)
			var at: Vector2 = spots[k] + Vector2(sin(float(k) * 1.7 + _t) * 4.0, -4.0 - phase * MOTE_RISE)
			var alpha := sin(phase * PI)
			draw_circle(at, 2.5, Color(Palette.EMBER, 0.5 * alpha))
			draw_circle(at, 1.2, Color(Palette.GOLD, 0.9 * alpha))

func _light_spot(light: int) -> Vector2:
	for source in _sources:
		if int(source.light) == light and is_instance_valid(source.tower):
			return source.tower.global_position
	return Vector2.ZERO

# --- Drawing: the glow's art (Tower Assets cb907eb6) ---------------------------------------------------------------------
# lantern_glow_a-c (48x48, 4 frames, 4 fps, anchor (24, 24)): a warm pool of light on each lit route point, the variant by
# route index; neighbours 32 px apart merge into a band. Gold path: lantern_glow_gold (6 fps). Strung Lights' gaps: the
# lantern_thread segment (16x8, 4 frames, 8 fps, anchor (0, 4)) tiled from the last glow through the gap to the next.
# Drawn here at 1x (z -1, under Wardens and nightmares); points laid in _lay_glow (only when the light map changed),
# redrawn only when a frame changes. Reduced motion: frame 0. Without the glow sheets: the CanvasGroup band above;
# without the thread sheet, a gap glows like the rest.
const GLOW_VARIANTS: Array[StringName] = [&"lantern_glow_a", &"lantern_glow_b", &"lantern_glow_c"]
const GLOW_GOLD := &"lantern_glow_gold"
const GLOW_THREAD := &"lantern_thread"
const GLOW_SIZE := Vector2(48, 48)
const GLOW_ANCHOR := Vector2(24, 24)
const GLOW_FRAMES := 4
const GLOW_FPS := 4.0
const GOLD_FPS := 6.0
const THREAD_SIZE := Vector2(16, 8)
const THREAD_ANCHOR_Y := 4.0
const THREAD_FPS := 8.0
const STATE_GAP := 3  # A Strung Lights gap (drawn as a thread)
var _fx_sheets := {}  # Sheet -> Texture2D (null when missing), per node, never static
var _glow_pts := PackedVector2Array()  # Lit route points (this node's space)…
var _glow_states := PackedInt32Array()  # …and theirs: 1 glow, 2 gold path, STATE_GAP strung gap (0: dark, kept for joins)
var _glow_has_gold := false
var _glow_has_gap := false
var _glow_serial := 0  # Bumped when the light map is rebuilt
var _laid_serial := -1
var _glow_key := -1  # The frames last drawn

func _fx_sheet(sheet: StringName) -> Texture2D:
	if not _fx_sheets.has(sheet):
		var path := "res://assets/effects/%s.png" % sheet
		_fx_sheets[sheet] = load(path) if ResourceLoader.exists(path) else null
	return _fx_sheets[sheet]

# The lit path is the soft ribbon above (screens_ui.md lit-path rule), not the per-point sheets: drawn per route point,
# they read as rows of gold discs with pale dots over the path (user screenshot 2026-10-19: "the path looks ugly now").
# Kept off until a ribbon-shaped Lantern Light sheet exists; the sheet code stays for that.
const USE_GLOW_SHEETS := false

func _glow_sheets_ready() -> bool:
	if not USE_GLOW_SHEETS:
		return false
	for sheet in GLOW_VARIANTS:
		if _fx_sheet(sheet) == null:
			return false
	return true

static func _still() -> bool:
	return bool(Fx.setting("reduced_motion", false))

func _glow_frames_key() -> int:
	if _still():
		return 0
	var t := Time.get_ticks_msec() / 1000.0
	var key := int(t * GLOW_FPS) % GLOW_FRAMES
	if _glow_has_gold:
		key += 4 * (int(t * GOLD_FPS) % GLOW_FRAMES)
	if _glow_has_gap:
		key += 16 * (int(t * THREAD_FPS) % GLOW_FRAMES)
	return key

func _tick_glow_sheets() -> void:
	if _glow_pts.is_empty() or get_tree().paused:
		return
	if _glow_frames_key() != _glow_key and _glow_sheets_ready():
		queue_redraw()

func _lay_glow_sheets(map: Node2D, route: PackedVector2Array, states: PackedInt32Array) -> void:
	if is_instance_valid(_glow_group):
		_glow_group.visible = false
	var thread := _fx_sheet(GLOW_THREAD) != null and not _strung.is_empty()
	var pts := PackedVector2Array()
	var kinds := PackedInt32Array()
	for i in route.size():
		var state := states[i]
		if state == 1 and thread:
			for cell in dream_state.route_cells(route[i]):
				if _strung.has(cell):
					state = STATE_GAP
					break
		pts.append(to_local(map.to_global(Tower.MAP_GRID.calculate_map_position(route[i]))))
		kinds.append(state)
	if pts == _glow_pts and kinds == _glow_states:
		return
	_glow_pts = pts
	_glow_states = kinds
	_glow_has_gold = kinds.has(2) and _fx_sheet(GLOW_GOLD) != null
	_glow_has_gap = kinds.has(STATE_GAP)
	queue_redraw()

func _draw_glow_sheets() -> void:
	if _glow_pts.is_empty() or not _glow_sheets_ready():
		return
	_glow_key = _glow_frames_key()
	var still := _still()
	var t := Time.get_ticks_msec() / 1000.0
	var plain := Rect2(Vector2(GLOW_SIZE.x * (0 if still else int(t * GLOW_FPS) % GLOW_FRAMES), 0.0), GLOW_SIZE)
	var gold_tex := _fx_sheet(GLOW_GOLD)
	var gold := Rect2(Vector2(GLOW_SIZE.x * (0 if still else int(t * GOLD_FPS) % GLOW_FRAMES), 0.0), GLOW_SIZE)
	for i in _glow_pts.size():
		var state := _glow_states[i]
		if state == 0 or state == STATE_GAP:
			continue
		var rect := Rect2((_glow_pts[i] - GLOW_ANCHOR).round(), GLOW_SIZE)
		if state == 2 and gold_tex != null:
			draw_texture_rect_region(gold_tex, rect, gold)
		elif state == 2:
			draw_texture_rect_region(_fx_sheet(GLOW_VARIANTS[i % 3]), rect, plain, Palette.GOLD)  # multiplier: gold path without its sheet
		else:
			draw_texture_rect_region(_fx_sheet(GLOW_VARIANTS[i % 3]), rect, plain)
	if not _glow_has_gap:
		return
	# Strung Lights: the thread from the last glow through the gap to the next (each step between two lit points)
	var thread_tex := _fx_sheet(GLOW_THREAD)
	var frame := 0 if still else int(t * THREAD_FPS) % GLOW_FRAMES
	for i in range(1, _glow_pts.size()):
		var a := _glow_states[i - 1]
		var b := _glow_states[i]
		if a == 0 or b == 0 or (a != STATE_GAP and b != STATE_GAP):
			continue
		var from := _glow_pts[i - 1]
		var length := from.distance_to(_glow_pts[i])
		if length <= 0.0:
			continue
		draw_set_transform(from.round(), from.angle_to_point(_glow_pts[i]))
		var x := 0.0
		while x < length:
			var width := minf(THREAD_SIZE.x, length - x)
			draw_texture_rect_region(thread_tex, Rect2(x, -THREAD_ANCHOR_Y, width, THREAD_SIZE.y),
				Rect2(THREAD_SIZE.x * frame + 0.0, 0.0, width, THREAD_SIZE.y))
			x += THREAD_SIZE.x
		draw_set_transform(Vector2.ZERO)
