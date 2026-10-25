extends Node2D

# Emitted when the enemy walks off the end of its path (reaches the goal), right before it's freed.
signal reached_goal(enemy: Node2D)
# Emitted when health hits 0 (the nightmare is dispelled). It stops being a target and plays its
# dispel effect.
signal cleansed(enemy: Node2D)
# TRAMPLE (The Hollow Stag): wants to knock down a Thornwall next to it. The spawner calls
# `trampled()` back if it did.
signal trample_requested(enemy: Node2D)
# LEAP (The Mire Hag) rose at her new position.
signal leaped(enemy: Node2D)
# Boss abilities the spawner carries out (acts_3_4.md): the Moth Queen drops a brood nightmare and
# starts the Eclipse; the Hollow Oak plants a thorn-sapling and grieves (Mourners rise around it).
signal brood_requested(enemy: Node2D)
signal eclipse_started(enemy: Node2D, seconds: float)
signal sapling_requested(enemy: Node2D)
signal grief_requested(enemy: Node2D)
# The Hollow Oak (Blight Level 10) rose again at half health instead of being dispelled.
signal rose_again(enemy: Node2D)
# Boss pools (enemy_design.md): the Night Mare reached the Heartwood and gallops round again (the
# spawner takes its lap leaves); the Lamplighter lights a lantern; the Withering Oak withers `count`
# Wardens; the Remembering Oak calls up the echo of act `act`'s boss; the Barrow King shrugged.
signal lapped(enemy: Node2D)
signal lantern_requested(enemy: Node2D)
signal bellow_requested(enemy: Node2D)  # Hollow Stag at half health: its bellow_spawn run from the start
# A boss that got through stays at the Heartwood and drains a leaf every HEARTWOOD_DRAIN_EVERY s (the
# spawner takes it and emits boss_drained); enemy_design.md "A boss that reaches the Heartwood stays".
signal heartwood_drained(enemy: Node2D)
signal wither_requested(enemy: Node2D, count: int)
signal echo_requested(enemy: Node2D, act: int)
signal shrugged(enemy: Node2D)
# A Warden tried a status this nightmare is immune to (the UI flashes the crossed-out icon). At most
# once per status every REFUSED_THROTTLE seconds per nightmare.
signal status_refused(enemy: Node2D, status: StringName)
# A pull began dragging it back (Sound: root_yank, soil_drag) / the drag ended (tower_design.md
# "pulls drag, not teleport").
signal drag_started(enemy: Node2D, tiles: float)
signal drag_ended(enemy: Node2D)
const REFUSED_THROTTLE := 1.0
# Pull drag: roots grab for DRAG_GRAB s, then an ease-out drag of DRAG_BASE + DRAG_PER_TILE × tiles s
# (bosses × DRAG_BOSS_SLOW); reduced motion: DRAG_REDUCED s, no grab, dust or wobble.
const DRAG_GRAB := 0.15
const DRAG_BASE := 0.25
const DRAG_PER_TILE := 0.18
const DRAG_BOSS_SLOW := 1.4
const DRAG_REDUCED := 0.2
const DRAG_WOBBLE := 0.08  # Radians
const DRAG_DUST_EVERY := 22.0  # Pixels dragged per dust puff
var _dragging := false
var _drag_total := 0.0  # Pixels this drag moves (from where the current ease started)
var _drag_done := 0.0
var _drag_time := 0.0
var _drag_duration := 0.0
var _grab_left := 0.0
var _drag_reduced := false
var _dust_left := 0.0
var _grab_fx: PullDragFx  # The roots holding its feet during a drag
var _refused_at := {}  # {status id: Time.get_ticks_msec() of the last status_refused}

# Deeply Blighted elites (acts_1_2.md): ×3 health, ×2 Dew, 2 leaves, 20% bigger, wrapped in a slow
# haze with a swirl mark by the health bar (not darkened: the nightmare art is already dark).
const ELITE_HEALTH := 3.0
const ELITE_DEW := 2
const ELITE_LEAVES := 2
const ELITE_SCALE := 1.2
const ELITE_HAZE_PUFFS := 6
const ELITE_HAZE_SPEED := 0.6  # Radians per second the haze drifts round
# Hard-edged Dread smoke (art_direction.md: darker, more smoke, never a pale halo): each puff is 3 stacked
# discs, so its alpha steps up in hard bands toward the middle; a few Wraithlight motes mark it as elite.
const ELITE_HAZE_COLOR := Color(Palette.DREAD, 0.26)
const ELITE_HAZE_BANDS := [1.0, 0.7, 0.4]  # Disc radii as shares of the puff
const ELITE_MOTE_COLOR := Palette.WRAITHLIGHT
const ELITE_MOTES := 3
const ELITE_SWIRL_COLOR := Palette.MIST
const ELITE_OUTLINE_COLOR := Color(Palette.MOONLIGHT, 0.9)  # Setting "blight_outline" (accessibility)
const LEAP_TIME := 0.45  # Seconds to sink, move under the mire and rise again

# Group of nightmares that are still walking and targetable. Dispelled ones leave it.
const GROUP := "enemies"
const BLIGHT_SHADER := preload("res://shaders/blight.gdshader")
const HEALTH_BAR_SIZE := Vector2(40, 5)
const HEARTWOOD_DRAIN_EVERY := 2.0  # A boss at the Heartwood takes a leaf this often (s)
const GROUND_DROP_TIME := 0.25  # Groundroot: a flyer's drop onto the route
const CORNER_ROUNDING := 0.3  # Cells before and after a turn's centre where the drawn path curves (the route stays square)
const SQUEEZE_WIDTH := 0.8  # Drawn width in a one-half gap (half_cells.md "The look in a narrow gap")
const SQUEEZE_RATE := 14.0  # Eases in and out over a few frames (reduced motion: at once)
const BOSS_SILENCE_SPEED := 0.5  # A silenced boss's timed abilities run this fast (Hushbell; tower_design.md 279ebb63)
const BOSS_SILENCE_FLOOR := 0.35  # …and never slower than this, however deep the Hushbell (Nurture rework e2631f54)
const LAP_SPEED_LAPS := 3  # Night Mare: laps that speed it up (×1.3 each: ×2.2 at most; Balancing Code's sim, seed 25)
const UNTOUCHABLE_TINT := Color(0.42, 0.38, 0.55)  # The Night Mare lingering: a dark, smoky shimmer (a self_modulate multiplier)
const UNTOUCHABLE_ALPHA := 0.55
const AWAKE_RING_COLOR := Color(Palette.MOONLIGHT, 0.35)  # Just woke: can't fall asleep again yet
const AWAKE_RING_RADIUS := 20.0
const AWAKE_RING_POINTS := 24
const SLOW_FLOOR_COLOR := Color(Palette.MOONLIGHT, 0.75)  # Slowed to the limit: the floor mark
# Enemy Assets' art bounds: {sheet: {"frame", "top", "bottom"}} (px from the frame centre). The bar
# goes BAR_ABOVE_HEAD over the top of tall art (the big bosses), never lower than HEALTH_BAR_OFFSET.
const ART_BOUNDS_PATH := "res://assets/creatures/bounds.json"
const BAR_ABOVE_HEAD := 6.0
const HEALTH_BAR_OFFSET := Vector2(0, -38)  # Bar centre, relative to the enemy's origin
# Dispel: shriek, crack with light, burst, then the motes drift up (about 1.2 s in all).
const SHRIEK_TIME := 0.12
const CRACK_TIME := 0.25
const BURST_TIME := 0.12
const MOTE_LIFETIME := 0.7
const MOTE_COLOR := Palette.GLOW  # Dispelled: the Wardens' light bursting out (warm on purpose)

@export var enemy_data: EnemyData
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var grid: Grid = preload("res://resource/map/map_grid.tres") # Reference to the shared Grid resource

var health: int:
	set(value):
		health = value
		_hud_dirty = true
var max_health: int:
	set(value):
		max_health = value
		_hud_dirty = true
var speed: float
var is_cleansed := false
# Multiplies `enemy_data.health` (set before adding to the tree; drifts grow creatures this way).
var health_scale := 1.0
# DriftDirector.get_growth of its drift (set before adding to the tree): grows the dread shell's per-hit soak, which
# must not follow health_scale (Balancing, balance_simulation.md "Dread shells after Nightmare Kinds").
var coat_growth := 1.0
# Damp, Drowsy, Spored, Marked, Static (see EnemyStatuses). Wardens apply them via apply_status().
var statuses := EnemyStatuses.new()

# Status icons (screens_ui.md "Status icons, revised"): the bare pixel-art icons in one row above the
# health bar, a thin bar under each that shortens with the time left, the stack count in the lower-
# right corner from 2 stacks (gold, with a glow behind the icon, at max). Screen px (they keep their
# screen size when zoomed and follow the UI scale); bosses and elites get the big ones.
const STATUS_BADGE := 28.0
const STATUS_BADGE_BIG := 32.0
const STATUS_BADGE_GAP := 3.0
const STATUS_BADGES_MAX := 3  # More → the most important ones (BADGE_ORDER) and "+N" (4 at 28 px overhang both neighbours)
const BADGE_ORDER: Array[StringName] = [&"static", &"held", &"asleep", &"silenced", &"marked", &"spored", &"drowsy", &"damp"]
const VIEW_MARGIN := 96.0  # px past the screen edge where nightmares still draw (their badges overhang)
const HUD_TIME_FRAMES := 6  # The time bars under the icons are looked at every this many frames (_update_hud; was 4: perf 2026-10-19)
const TIME_BAR_GAP := 6.0  # Room under each icon for its time bar (px, above the health bar)
const TIME_BAR_HEIGHT := 3.0
# The HUD's canvas items (update_hud), each kind on its own z layer so the whole field batches.
enum { HUD_BARS, HUD_MARKS, HUD_ICONS, HUD_PILLS, HUD_TEXT }
const HUD_PASSES := [HUD_BARS, HUD_MARKS, HUD_ICONS, HUD_PILLS, HUD_TEXT]
const STATUS_DOT_RADIUS := 3.0  # Fallback when the icon sheet has no icon for a status
const STACK_FONT_SIZE := 16
const STACK_FONT_SIZE_BIG_COUNT := 14  # Three-digit counts cover less of their icon
const STACK_POP_TIME := 0.18  # An icon's quick scale bump when a stack is added
const STACK_POP_SCALE := 0.35  # …up to this much bigger
# Status cues (visual_feedback_spec.md C3): a Dream card changed this status: its icon bumps x1.2 with a 1 px Heartlight rim
# (dream_status_pop, called by the card code); a status a card keeps from running down (statuses.is_lingering) draws its
# time bar's rim in Dew-light, "lasts longer".
const DREAM_POP_TIME := 0.15
const DREAM_POP_SCALE := 0.2
const DREAM_RIM_COLOR := Palette.HEARTLIGHT
const LINGER_RIM_COLOR := Palette.DEWLIGHT
const STACK_PIP_MAX := 4.0  # Stack pips above an icon: at most this big (px), smaller when many
const STACK_PIP_MIN := 2.0  # Small caps retain readable individual pips
const STACK_PIP_CAP := 8  # Larger capacities use one bounded progress bar
const BOLT_FLASH_TIME := 0.2
const HIT_MARK_TIME := 0.35  # Grey puff (resisted) / sparkle (weak) after a hit
# Damage that only happened because of a Reaction (DamageLog: whole-hit combos, event kind "reaction").
const REACTION_TAGS: Array[StringName] = [&"thunderclap", &"ignite", &"shatter", &"pinned", &"lightning_rod",
	&"dawnbreak", &"echo", &"starfall", &"avalanche", &"drown", &"fever_dream", &"carried_storm",
	&"smother"]  # Smother's burst (owner 2026-10-17, council reactions_unique.md)
# Reactions that change a Warden's own hit (card pass slice 1, council card_pass_td.md 1a): only the bonus is the
# Reaction's. Tag -> the multiplier it put on the hit (Shatter and Pinned also × EnemyStatuses.charged_payoff_multiplier).
const REACTION_BONUS_ONLY := {&"shatter": Reactions.SHATTER_MULTIPLIER, &"pinned": Reactions.PINNED_MULTIPLIER,
	&"lightning_rod": Reactions.ROD_MULTIPLIER,
	&"smother": Reactions.SMOTHER_BURST}  # (council rx review 2026-10-17) only the burst's bonus half is the Reaction's
const STATUS_FLASH_TIME := 0.3  # A status icon flashes when a combo uses it (see flash_status)
# Effect tags whose damage already carries its Warden's Potency (take_damage skips effect_multiplier; a const so a hit
# doesn't build the array)
const POTENCY_EXEMPT: Array[StringName] = [&"stone_relay", &"stored_rain", &"fifth_beat", &"crossfire"]
# The status row and the nightmare itself (screens_ui.md "Status row: Reaction-ready marks and falling asleep", 2026-10-18).
const READY_COLOR := Palette.DEWLIGHT  # Reaction-ready: four corner brackets round the icon (a shape, not only a colour)
const READY_PULSE_TIME := 1.6  # Seconds per breath of the brackets' gentle pulse (still under reduced motion)
const THRESHOLD_COLOR := Palette.HEARTLIGHT  # A slash on a stack bar / pip row where a Reaction starts to count
const READY_GROW := 0.06  # The brackets breathe out to this much bigger and back (owner 2026-10-18; none under reduced motion)
# Room a Reaction-ready badge adds round its cell (px): at full breath its brackets reach (r + 4.25) × (1 + READY_GROW)
# from the icon's centre (≤ r + 5.6 at the 32 px badge), while a cell holds the icon right-aligned with 2 px after it (r on
# the left, r + 2 on the right): they stay inside their own cell, clear of the next badge.
const READY_PAD_LEFT := 6.0
const READY_PAD_RIGHT := 4.0
const SLEEP_SETTLE_TIME := 0.35  # Seconds to settle into sleep (and back out)
const SLEEP_SINK := 1.5  # Px it sinks asleep
const SLEEP_LEAN := 0.1  # Radians it leans asleep (none under reduced motion)
const SLEEP_EYES := 0.33  # Its eye / core glow asleep (× the shader's; instance uniform eye_glow)
const WAKE_JOLT_TIME := 0.25  # Waking: a short hop, the eyes flaring back
const WAKE_HOP := 2.0  # Px up at the jolt's peak
const WAKE_EYE_FLARE := 1.6
const SLEEP_MOTE_EVERY := 1.0  # Seconds between "z" motes
const COAT_COLOR := Palette.STONE
const CRIT_FLASH_TIME := 0.3  # Seconds a crit counts as "just happened" (the glint itself is Fx.crit)

var _crit_flash := 0.0
# Extra Dew when dispelled (Magpie Perch: +1 once it's been hit by a magpie).
var bonus_dew := 0
# The Dew pot (run_design.md "The Dew pot"): its share of its drift's pot, set by the DriftDirector at
# spawn (set_dew_share); -1 = none assigned (old rule: EnemyData.dew_reward). Followers share half of
# their leader's (dew_followers); split children share 60% of their parent's (the spawner's _split).
var dew_share := -1.0
var dew_followers: Array = []
const FOLLOWER_DEW_SHARE := 0.5  # Of a leader's share, split among its followers
const SPLIT_CHILDREN_DEW_SHARE := 0.6  # Of a parent's share, split among the children it breaks into
# The next hit ignores the blight coat's (dread shell's) reduction (Needle Point pecks).
var pierce_coat_once := false
# Seconds before this nightmare can be frozen (Frostfern) / pushed back (Whirligig) again.
var freeze_cooldown := 0.0
var push_cooldown := 0.0
# Test Grove's Target Dummy: never drops below 1 health, and walks the route again instead of
# reaching the Heartwood.
var unkillable := false
var loops_route := false
# The last few damage events (DamageLog.Event) for Inspect.
var recent_hits: Array = []
const RECENT_HITS := 6

var _soothe_carry := 0.0  # Fractional soothe (Spored ticks, multipliers) waiting to add up to 1
var _bolt_flash := 0.0
var _hit_mark := 0  # -1 resisted, +1 weak, 0 none
var _hit_mark_time := 0.0
var _hit_mark_wash := false  # The shell-chip puff is Wash Away's (its cue: Dew-light, not Mist)
# Blight coat left to soak up, and soothe it takes off each hit (both already health-scaled).
var coat := 0.0:
	set(value):
		coat = value
		_hud_dirty = true
var coat_max := 0.0:
	set(value):
		coat_max = value
		_hud_dirty = true
var _coat_per_hit := 0.0
# Omen modifiers for this creature's drift (set before adding to the tree; bosses get none):
# {"speed", "coat", "dew", "status_duration": multiplier}. Split-off creatures inherit them.
var modifiers := {}

var elite := false  # Deeply Blighted (set before adding to the tree)
var _haze_phase := 0.0
var _body_fx: Node2D = null  # The glows and marks round the body (haze, bolt flash, hit marks), sorted with the sprite
# Cached display settings (Fx.setting): health bars at full health too ("health_bars" 1), and the
# elite outline ("blight_outline"). Re-read on the presence tick so the settings panel applies live.
var _bars_always := false:
	set(value):
		_bars_always = value
		_hud_dirty = true
var _outlined := false
var _status_flash := {}  # {status id: seconds left} for icons a combo just used
var hold_time := 0.0  # Seconds to stand still before setting off (Wraiths in single file)
var rolling := false  # Night Hound sprinting down a straight
var lost := false  # Wraith whose Lantern Bearer was dispelled first
var _straight_steps := 0
var _last_step := Vector2.ZERO
var _trait_timer := 0.0
var _trampled := 0
var _startled := false
var _charge_left := 0.0
var at_heartwood := false  # A boss that got through: it stays, draining leaves (see heartwood_drained)
var _drain_left := 0.0  # Seconds to its next leaf (0 on arrival: the first goes at once)
var _linger_left := 0.0  # Night Mare: seconds left of this visit before it gallops off again
var _grounded_left := 0.0  # Groundroot: seconds left on the ground (a flyer walking the maze; see ground)
var _corner_offset := Vector2.ZERO  # Drawn minus logical position on a rounded corner (_round_corners)
# Walking lanes (enemy_design.md "Walking lanes", owner 2026-10-24: visual only): the drawn body walks a lane beside
# the centre line, across the travel direction; the node (position, cell, targeting, ranges) stays on the line.
# Retune (council 2026-10-24b, enemy_council_review.md): narrower, no skating (each move eased in and out, sideways
# never faster than LANE_SLIDE_SHARE of its own walk), measured across the rounded corner's curve, closed in gaps.
const LANE_MAX := 0.25  # Cells either side (Stream and Packs; variation trial 2026-10-24: was 0.2, back to 0.2 if outer bodies touch the sand's edge)
const LANE_BIG := 0.1  # Bosses and big nightmares (sprite_scale >= LANE_BIG_SCALE), Few and tough's Deeply Blighted
const LANE_BIG_SCALE := 1.4
const LANE_FLYER := 0.15  # Flyers sway on their own line
const LANE_WANDER := Vector2(4.0, 8.0)  # Seconds between new target lanes
const LANE_STEP := Vector2(0.3, 0.7)  # A new target: the current lane ± this (random side), within ±1
const LANE_MOVE_MIN := 0.8  # Seconds a move takes at least (smoothstep in and out)
const LANE_SLIDE_SHARE := 0.25  # Sideways speed at most this share of its own walk speed
const LANE_TURN_EASE := 10.0  # Easing rate of the direction the lane is measured across (the rounded curve's tangent)
const LANE_TURN_NEAR := 0.5  # Cells from a turn's centre where the lane narrows…
const LANE_TURN_SHARE := 0.5  # …to this share at the centre
const LANE_GAP_EASE := 14.0  # A narrow half-cell gap closes the lane at this rate (past the speed cap)
const LANE_JOSTLE_MAX := 0.85  # Jostling never pushes a lane past this
const LANE_SNAP_PX := 1.0  # The drawn offset (whole pixels) is pushed to the sprite and HUD only when it moved this far
var lane_width := -1.0  # Cells either side; < 0 = by its kind (DriftShapes sets Single file / Few and tough's)
var lane := 0.0  # Current lane, -1..1 of lane_width (the spawner's jostle reads and nudges it)
var lane_target := 0.0
var _lane_left := 0.0
var _lane_from := 0.0  # The move in progress: from this lane to lane_target over _lane_move s
var _lane_t := 1.0
var _lane_move := 1.0
var _lane_gap := 1.0  # 0 in a narrow gap, 1 elsewhere (eased)
var _lane_last := Vector2.INF  # Last frame's drawn route position (position + corner offset): the curve's tangent
# Variation trial (owner 2026-10-24, enemy_design.md "Walking lanes"): a narrow half-cell gap keeps a small lane (what
# the gap leaves beside the squeezed body, at most LANE_GAP_MAX), and every body drifts a little along its travel too.
const LANE_GAP_MAX := 0.1  # Cells either side in a one-half gap, at most
const LANE_BODY_PX := 24.0  # A body's drawn width at scale 1 (× its drawn x scale: squeezed in a gap)
const ALONG_MAX := 0.1  # Cells forward / back along its travel
const ALONG_WANDER := Vector2(2.0, 4.0)  # Seconds between new targets
var _along := 0.0  # -1..1 of ALONG_MAX
var _along_from := 0.0
var _along_target := 0.0
var _along_t := 1.0
var _along_move := 1.0
var _along_left := 0.0
var _lane_dir := Vector2.ZERO
var _lane_offset := Vector2.ZERO  # The drawn offset in px
var _lane_drawn := Vector2.ZERO  # The offset last pushed to the sprite / HUD
var _lane_age := 0.0  # Seconds walked: the lane opens over the first cell
var _lane_rng: RandomNumberGenerator = null
# Route flyers (enemy_design.md "Flyers", 2026-10-24): the route they spawned with (to rise back onto after a grounding),
# the Gloamwing's drop and the Pall's cover.
const PALL_SHARE := 0.5  # Of each blow aimed at a covered walker, after its dread shell
const PALL_REACH := 2.5  # Cells: a walker ahead within this is one it settles over
const PALL_SWOOP := 150.0  # px/s: gliding over to it
const PALL_SETTLE := 6.0  # px: close enough to settle
const PALL_SEEK_EVERY := 0.25  # s between looks for a walker
const PALL_ABOVE := Vector2(0, 1)  # Its node sits a pixel below the walker's, so the cloth sorts in front
var covered_by: Node2D = null  # The Pall over this walker (blows are shared with it)
var covering: Node2D = null  # Pall: the walker it covers or glides to
var _settled := false
var _pall_seek := 0.0
var dropped := false  # Gloamwing: down on the path for good
var _air_route := PackedVector2Array()  # A route flyer's own route, in the air
var _air_held := 0  # Its index there when it was grounded
var _shared_hit := false  # A Pall's half of a blow: no multipliers again
# Status icons in crowds (enemy_design.md "Status icons in crowds", owner 2026-10-24): a crowded nightmare's badge row
# becomes one small pip per status (no numbers, 70%) and its health bar 3 px; full rows stay for the hovered / tapped
# nightmare, bosses, Deeply Blighted and anything not crowded. Setting "status_icons": 0 Full, 1 Compact in crowds
# (default), 2 Off (the row only on hover / tap). Eased over CROWD_EASE s (instant under reduced motion); a look holds
# CROWD_HOLD s at least.
const CROWD_PIP_ALPHA := 0.7
const CROWD_BAR_H := 3.0
const CROWD_EASE := 0.15
const CROWD_HOLD := 0.5
const CROWD_SEEN := 0.2  # s: a crowd mark this fresh still counts (the spawner marks every 2 frames)
enum RowLook { FULL, COMPACT, OFF }
var crowd_seen := -1.0  # EnemySpawner.crowd_clock when it was last in a cluster (_mark_crowds)
const FOCUS_Z := 8  # The hovered / tapped nightmare's HUD draws this many z steps higher, with a focus ring
var _focus_drawn := false
var _row_look: RowLook = RowLook.FULL
var _row_hold := 0.0
var _row_alpha := Vector2(1.0, 0.0)  # Drawn alpha of (the full row, the pips)
var _row_stale := false  # The full row was faded out and skipped drawing: rebuilt whole before it shows again (perf)
var _hud_pips := RID()
var _pips_changes := -1
var _squeeze := 1.0  # The width factor sprite.scale.x carries now (_update_squeeze)
# _in_narrow_gap's last answer and what it depended on (perf: re-checked only when the half cells under and
# just ahead of the body, the step or the map's blocking change, not every frame)
var _gap_finder: FindPath
var _gap_here := Vector2i(-1, -1)
var _gap_ahead := Vector2i(-1, -1)
var _gap_step := -1
var _gap_version := -1
var _gap_answer := false
# Per-route caches (perf, mobile_plan.md): set_path bumps _path_serial, and each cache rebuilds on demand.
var _path_serial := 0
var _turns := PackedByteArray()  # Per route point: 1 = the route changes direction there (rounded corners)
var _turns_serial := -1
var _target_px := Vector2.ZERO  # The pixel of _path[_target_index] (walking: no Grid call every frame)
var _target_index := -1
var _target_serial := -1
# The route step (and route) on which it was last found on a straight with no gap and nothing to ease: until
# the step, the route or the map's blocking changes, the corner and squeeze checks are skipped.
var _steady_index := -1
var _steady_serial := -1
# Low detail only (spawner.low_detail_now; mobile_plan.md): off screen, its cosmetics pause (the sprite's
# animation, the HUD, rounded corners and the squeeze) and catch up the frame it's back. Walking, statuses and
# presence never pause.
var _culled := false
# The way in (StartGate, Environment Assets' mock): it comes out of the fog in the void and crosses the rope
# bridge to the start along `_entry` (MapGenerator pixels) in ENTRY_TIME s, untargetable (out of the enemies
# group) until it steps onto the island; then the route as before.
# Hit feedback, layer 1 (screens_ui.md "Hit feedback on nightmares"): every damaging hit makes it flinch: a
# pale flash through its shader (hit_flash, FLASH_TIME) and the SPRITE recoils 1–2 px away from the hit, by the
# hit's share of its health (a floor so a tap shows, a ceiling so nothing jumps; bosses less). Visual only: the
# body, its route position and its HUD never move. Continuous sources (SUSTAINED_TAGS) don't flinch per tick:
# they keep a "sustained" state the Wardens' overlays hook (set_sustained / is_sustained / sustained_changed).
const FLINCH_TIME := 0.1  # The recoil settles back over this long (real seconds)
const FLASH_TIME := 0.06
const RECOIL_MIN := 1.0  # px, the lightest hit
const RECOIL_MAX := 2.0  # px, a hit of RECOIL_FULL_SHARE of its max health or more
const RECOIL_FULL_SHARE := 0.1
const FLASH_MIN := 0.3  # Flash strength of the lightest hit…
const FLASH_MAX := 0.6  # …and of a heavy one
const BOSS_FLINCH := 0.5  # Bosses flinch half as far and half as bright
const NO_SOURCE := Vector2(INF, INF)  # flinch(): no hit position: back along its path
const SUSTAINED_TAGS: Array[StringName] = [&"spored", &"cloud", &"fog", &"rain", &"beam", &"fence", &"whirlpool",
	&"lingering_splash"]
const SUSTAIN_HOLD := 0.3  # A tick keeps its sustained state on this long (game seconds) without the source saying
const ARC_TAG := &"fence"  # Jarlink / Lightning Fence arcs: it twitches while they hold it
const ARC_TWITCH := 0.7  # px
signal sustained_changed(enemy: Node2D, tag: StringName, on: bool)

# Big-hit feedback (visual_feedback_spec.md "A", owner 2026-10-18): one damage event's share of its max health (hits and
# bolts only; ticks, sustained tags, harmony and Reactions show themselves) sets a tier. T1 Heavy: 3 px recoil, a
# brighter flash, a hairline crack. T2 Crushing: + a stagger (squash) with a 4 px knock and light chips. T3 Shattering:
# + the sprite holds 60 ms (never a time stop), a Glow ring and a camera nudge (trauma 0.5). Bosses by BIG_HIT_BOSS_SHARES.
# big_hit fires for the number tiers and the boss bar's chunk flash (Main Merger); big_tier_now is the tier of the event
# DamageLog is reporting (0 otherwise). Setting "big_hits": 0 Full, 1 Subtle (T1 visuals at every tier), 2 Off.
signal big_hit(enemy: Node2D, tier: int, share: float)
const BIG_HIT_SHARES: Array[float] = [0.12, 0.25, 0.5]  # T1, T2, T3
const BIG_HIT_BOSS_SHARES: Array[float] = [0.04, 0.08, 0.15]  # (owner-approved)
const BIG_HIT_MERGE_MS := 100  # Hits from one source within this add up to one blow (Refrain, multi-peck, echoes)
const BIG_HIT_AGAIN_MS := 250  # A tier plays again on a nightmare only after this; a higher one may cut in
const BIG_HIT_RECOIL: Array[float] = [3.0, 4.0, 4.0]  # px: T1's recoil, T2/T3's knock (reduced motion: the flinch's own)
const BIG_HIT_FLASH := 0.7
const BIG_HIT_CRACK: Array[float] = [0.15, 0.3, 0.5]
const BIG_HIT_CRACK_TIME: Array[float] = [0.18, 0.3, 0.4]
const BIG_HIT_SQUASH := Vector2(1.12, 0.88)
const BIG_HIT_SQUASH_TIME := 0.14
const BIG_HIT_FREEZE := 0.06  # Its own walk frames only; game time and everything else run on
const BIG_HIT_NUDGE := 0.5  # Camera trauma on T3 (Fx.add_trauma, 0..1; counts against Fx.bright_flash_ok)
const BIG_HIT_CAPS: Array[int] = [10, 4]  # T2, T3 a second for the whole field…
const BIG_HIT_CAPS_REDUCED: Array[int] = [4, 2]  # …at Reduced effects
const BIG_HIT_CHIPS := &"big_hit_chips"  # Tower Assets' sheet; skipped until it exists
const BIG_HIT_RING_TIME := 0.3
var big_tier_now := 0
var _bh_source := 0  # The blow being merged: its source's instance id, its damage so far, when it last grew
var _bh_sum := 0.0
var _bh_at := -100000
var _bh_tier := 0  # The tier playing and until when (msec)
var _bh_until := 0
var _crack_hit := 0.0  # The hairline crack: its peak, seconds left of it and its length (shader hit_crack)
var _crack_hit_left := 0.0
var _crack_hit_time := 1.0
var _stagger_left := 0.0
var _stagger_scale := Vector2.ONE  # The squash factor sprite.scale carries now (as _squeeze)
var _freeze_left := 0.0
static var _bh_times: Array = [[], []]  # msec of the field's recent T2 and T3 blows (BIG_HIT_CAPS)
var _flinch_left := 0.0
# Falling asleep (_update_sleep): asleep last frame, the Asleep badge in for Sleep (after its flash), how far it has
# settled (0..1), the sink / lean / eye glow shown, the waking jolt, the next "z" mote and the latest one.
var _was_asleep := false
var _asleep_badge := false
var _asleep_swap := 0.0
var _settle := 0.0
var _sleep_sink := 0.0
var _sleep_lean := 0.0
var _eye_shown := 1.0
var _wake_jolt := 0.0
var _mote_left := 0.0
var _mote: WeakRef = null
var _hud_primed: Array[bool] = []  # Per shown badge: enough stacks for a Reaction (the blue frame)
var _flinch_recoil := Vector2.ZERO  # The recoil at its start (px); eases back to zero
var _flinch_flash := 0.0  # The flash at its start
var _recoil := Vector2.ZERO  # Added to the sprite's offset only (recoil + arc twitch)
var _flash_shown := 0.0  # The hit_flash the shader has now (set only when it changes)
var _sustained := {}  # tag -> game seconds left (INF = held by its source until cleared)

const ENTRY_TIME := 1.5
const ENTRY_FADE := 0.3  # Share of the way in over which it fades in out of the fog
const ENTRY_Z := 0  # While crossing: over the deck (z -1) and under the fog (z 1): StartGate 0eb9153b layers them
var _entry := PackedVector2Array()
var _entry_time := 0.0
# Pixels the drawn body (sprite, its HUD, its glows) is raised so its feet and contact shadow sit on the
# route point, the path ribbon's centreline (art_direction.md "Bigger Wardens"); 0 for flyers.
var _foot_lift := 0.0
var _untouchable := false  # Night Mare lingering: no hits, no statuses, not targeted (_set_untouchable)
var straight_charging := false  # Hollow Stag: on a straight of straight_charge_tiles+ (see _update_straight_charge)
var stream_speeding := false  # Swift Stream Omen: on a long straight, ×straight_speed (_update_swift_stream)
var _bellowed := false
var _leaping := false  # Sinking / underground / rising (Mire Hag, Gravecrawler): not walking
# Rooted Nightmares (Dream card 122): a Held nightmare blocks its cell. Walkers re-route round it,
# or wait at the cell before it (`waiting`; others then queue behind rather than stack in one cell).
const REROUTE_RETRY := 0.25  # Seconds between re-route attempts while waiting
# No maze juggling (run_design.md): each re-route that turns it back onto the tile it just came from
# gives 1 Restless (+RESTLESS_SPEED speed for good, stacking). At UNBOUND_AT it's Unbound (not
# bosses): it ignores re-routes and tramples any Warden planted on its route. Not a status.
signal trample_cell_requested(enemy: Node2D, cell: Vector2)
const RESTLESS_SPEED := 0.2
const UNBOUND_AT := 3
const RESTLESS_COLOR := Palette.DEWLIGHT
const UNBOUND_GLOW := Palette.WRAITHLIGHT
var restless := 0:
	set(value):
		restless = value
		_hud_dirty = true
var unbound := false:
	set(value):
		unbound = value
		_hud_dirty = true
var _last_cell := Vector2(-1, -1)  # The cell it last stood on (a turn-back heads there again)
var _unbound_trail: CPUParticles2D
var waiting := false
var _reroute_wait := 0.0
var _leap_tween: Tween
var _burrows := 0
var _revealed_time := 0.0  # Seconds it stays revealed whatever else (see reveal_for)
# Performance (test_perf_stress): the EnemyContainer (null outside it), and what the status row last
# drew, so it only redraws when a status comes, goes or changes stacks.
var _spawner = null  # Untyped: its script members are read directly
# Thin-family Dream cards (see _spread_root_web, _on_hold_ended, _on_caught_lapsed).
const ROOT_WEB_REACH := 1.0  # Tiles: "touching"
var _web_cooldown := 0.0
var _web_holding := false
var _held_by: Node = null
var _lingered := false
var _release_spent := false  # The current hold came from a release pull (Snare): it won't pull again
var _caught_left := 0.0  # Caught time after last frame's tick (a rise = caught again)
var _redraw_pending := false  # Something drawn changed: redrawn in _process once on screen
var _bar_offset := HEALTH_BAR_OFFSET  # The health bar's centre: raised over tall art (_measure_bar_offset)
# The HUD's canvas items (update_hud): a root the overlay moves, and one item per HUD_* kind
var _hud_root := RID()
var _hud_ready := RID()  # The Reaction-ready brackets: a child of the marks item, so pulsing is only its modulate
var _hud_ready_on := false  # Any shown badge is Reaction-ready (the pulse runs only then)
# One small item per ready badge under _hud_ready, its brackets drawn round its own origin at the icon's centre: the breath
# is its transform's scale (no rebuild). Kept and reused; the first _hud_ready_used are in use.
var _hud_ready_items: Array[RID] = []
var _hud_ready_at := PackedVector2Array()
var _hud_ready_used := 0
var _hud_items: Array[RID] = []
var _hud_shown := false
var _hud_scale := -1.0
var _hud_dirty := true  # Something the HUD shows changed (the setters above); _process looks at the HUD only then
# What the bars item shows (health, coat, Restless, bars always), and the marks item (statuses, time-bar steps)
var _hud_health := -2  # (Bar width in px; -1 = hidden)
var _hud_coat := -1
var _hud_restless := -1
var _hud_unbound := false
var _hud_always := false
var _hud_slow_capped := false  # Slowed to the limit (statuses.slow_capped): a floor mark under the bar
var _hud_awake := false  # Can't fall asleep again yet (statuses.sleep_cooldown): a faint ring
var _hud_marks_key := -1
var _hud_stagger := randi() % 4  # So a crowd doesn't check its time bars on the same frame
var _hud_pops := {}  # {status id: seconds left of its icon's pop} (a stack was just added)
var _dream_pops := {}  # {status id: true}: those pops are a Dream card's (dream_status_pop): their own size, time and rim
var _hud_popping := false
var _hud_flashing := false
var hud_builds := 0  # Items rebuilt (tests: only when something changed)
# The badge row, cached until statuses.changes moves (_update_hud_layout)
var _hud_changes := -1
var _hud_ids: Array = []
var _hud_total := 0  # Badge-worthy statuses in all (silence included): "+N" = this − the shown ones
var _hud_stacks: Array[int] = []
var _hud_badge_widths: Array[float] = []
var _hud_caps: Array[int] = []
var _hud_full: Array[bool] = []
var _hud_colors: Array[Color] = []
var _hud_icons: Array[Texture2D] = []
var _drawn_aura := false
var _was_animating := false
var _speed_cache := 0.0
var _speed_base := -1.0
var _speed_changes := -1
var _speed_stale := true  # Set on each presence tick and whenever speed rules change (below)
var _settings_elapsed := 0.0  # Display settings are re-read every SETTINGS_TICK s
const SETTINGS_TICK := 0.5
var _pose_left := 0.0  # Seconds a special animation (eclipse, grief) keeps the walk animation off
var _wander_cooldown := 0

# Presence (acts_3_4.md): hiding, revealing, waking, mending, the ash trail and boss timers, checked
# every PRESENCE_TICK seconds rather than every frame.
const PRESENCE_TICK := 0.1
const CLOSE_REVEAL_CELLS := 1.5  # Any Warden this close sees a hidden nightmare
const HIDDEN_ALPHA := 0.22
const ALWAYS_DAMP_TIME := 3600.0
const ASH_COLOR := Color(Palette.DEWLIGHT, 0.5)  # Cold ghost-fire (art_direction.md: no warm embers on nightmares)
const DIRECTIONS: Array[Vector2] = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
var _hidden := false:
	set(value):
		_hidden = value
		_hud_dirty = true
var _presence_elapsed := 0.0
var _ash_cells := {}  # {cell: seconds the ash still burns}
var _always_statuses: Array[StringName] = []  # See _keep_always_statuses
# Magpies, the thieves (status jobs): see strip_buff.
const MEND_STRIP_TIME := 3.0  # Seconds a stripped Weeper stops mending
var _mend_stopped := 0.0
var _heal_carry := 0.0
var _brood_timer := 0.0
var _sapling_timer := 0.0
var _sapling_speed := 1.0
var _eclipsed := false
var _griefs := 0  # grief_at thresholds already passed
var _has_thresholds := true  # Any health threshold at all (set in _ready; perf: every hit asks, nearly no nightmare has one)
var _has_risen := false
# Boss pools (enemy_design.md)
const ECHO_ALPHA := 0.6
const SHRUG_FLASH_TIME := 0.5
const SHRUG_COLOR := Palette.MIST
var is_echo := false  # An echo of an earlier boss (Remembering Oak): not counted as a boss dispelled
var pack: Array = []  # Huntsman's hounds (set by the spawner); it takes pack_shield damage while one lives
var laps := 0  # Night Mare: times it has reached the Heartwood and gone round again
var _lantern_timer := 0.0
var _shrug_timer := 0.0
var _shrug_flash := 0.0
var _since_hit := 0.0  # Seconds since the last hit (Mourning Mother's Sorrow)
var sorrowing := false  # Mourning Mother mending right now (Sorrow): plays her "sorrow" loop
var _regen_left := -1.0  # Health it may still mend (< 0 = not worked out yet)
var _wither_timer := 0.0
var _wither_bursts := 0  # wither_burst_at shares already passed
var _echoes := 0  # echo_at shares already passed
var _regrouped := false  # Huntsman's pack came back at half health; no more horns

# Cells to walk through, in grid coordinates. `_path_index` is the cell we're currently walking toward.
var _path: PackedVector2Array
var _cells_left: PackedFloat32Array  # Per route point: the route's length in cells from it to the end (made on demand)
var _path_index: int = 0

# Waymark (Legendary Dream, owner 2026-10-21): a walker's _path runs start -> stone -> Heartwood (one array, so targeting by
# get_remaining_distance and "furthest along" still work). It has `passed_waymark` once it stood on the stone (or stepped
# past its point: a leap, a burrow); pulls back never clear it; a lap (Night Mare, Target Dummy) starts over. Not saved:
# rests have a clear field. `_waymark_index`: the first point of _path on the stone (-1: none).
var passed_waymark := false
var _waymark_index := -1
signal waymark_reached(enemy: Node2D, shed: int)  # It touched the stone (shed: how many statuses it lost)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_free_hud()  # Its HUD canvas items live in the RenderingServer, not in the tree

func _ready() -> void:
	add_to_group(GROUP)
	statuses.status_filled.connect(flash_status)  # A status at its most flashes (Roguelite Code, 2026-10-16)
	var parent := get_parent()
	if parent != null and parent.has_method("route_around"):
		_spawner = parent  # The EnemyContainer: its per-frame flags are read straight, no lookups by name

	# Initialize attributes
	max_health = maxi(roundi(enemy_data.health * health_scale * (ELITE_HEALTH if elite else 1.0)), 1)
	health = max_health
	speed = enemy_data.speed * modifiers.get("speed", 1.0)
	statuses.is_boss = enemy_data.is_boss
	statuses.is_elite = elite  # Deeply Blighted: its own slow floor
	statuses.ignores_slows = enemy_data.ignores_slows
	# A copy: Omens (Sleepless) add to it per nightmare, never to the shared EnemyData.
	statuses.immune = enemy_data.status_immune.duplicate()
	for id: StringName in modifiers.get("status_immune", []):
		if not id in statuses.immune:
			statuses.immune.append(id)
	if enemy_data.always_damp:
		_always_statuses.append(EnemyStatuses.DAMP)
	var omen_status: StringName = modifiers.get("always_status", &"")  # Heavy Rain: always Soaked
	if omen_status != &"" and not omen_status in _always_statuses:
		_always_statuses.append(omen_status)
	statuses.duration_multipliers = enemy_data.status_duration_multipliers
	statuses.duration_multiplier_all = modifiers.get("status_duration", 1.0)
	_has_thresholds = enemy_data.eclipse_time > 0.0 or not enemy_data.grief_at.is_empty() \
		or not enemy_data.wither_burst_at.is_empty() or not enemy_data.echo_at.is_empty() or enemy_data.bellow_count > 0 \
		or enemy_data.pack_regroup_at_half
	coat_max = enemy_data.coat_total * health_scale * modifiers.get("coat", 1.0)
	coat = coat_max
	# The per-hit soak grows with the drift's growth only (health_scale rises ~×38 by drift 45, heavy hits ~×3–8);
	# the shell's total keeps health_scale. Hard Bark ("coat") and strip_buff work on both.
	_coat_per_hit = enemy_data.coat_per_hit * coat_growth * modifiers.get("coat", 1.0)

	# Set up animations
	sprite.sprite_frames = enemy_data.sprite_frames
	sprite.scale = Vector2.ONE * enemy_data.sprite_scale * (ELITE_SCALE if elite else 1.0)
	_measure_bar_offset()
	_measure_foot_lift()
	# Y-sort by the drawn body (council 2026-10-24c): the sprite (at its lane) and _body_fx sort on their own positions
	_body_fx = Node2D.new()
	_body_fx.name = &"BodyFx"
	add_child(_body_fx)
	move_child(_body_fx, sprite.get_index())  # Just before the sprite: the same y, so it draws behind it
	_body_fx.draw.connect(_draw_body)
	y_sort_enabled = false  # On only while crowded (_update_sort_look): one sorted item per nightmare elsewhere (perf 2026-10-25)
	_apply_sprite_offset()
	sprite.modulate = enemy_data.tint
	if is_echo:
		sprite.modulate.a *= ECHO_ALPHA  # A pale face from the Oak's bark
	sprite.play(_base_animation())  # (walk_side; the three route flyers: "fly")

	# Nightmare look: one material shared by every nightmare (so their sprites batch into few draw
	# calls); one cracking apart gets its own copy (_set_crack), outlined elites share a second one.
	sprite.material = _blight_material(false)

	_refresh_display_settings()
	_keep_always_statuses()
	if enemy_data.hidden:
		_set_hidden(true)  # Revealed on the first presence tick if something sees it

# Whether Afterroot or Dream Residue is held (their hooks watch a hold / a catch end), asked once a frame for every
# nightmare and again whenever DreamState.rules_stamp moves (take(), bump_board()): as fresh as has_rule itself, which
# caches by frame and stamp too (perf: a rule lookup per nightmare per frame cost more than the reads it saved).
static var _end_hooks_frame := -1
static var _end_hooks_stamp := -1
static var _end_hooks_owner := 0
static var _end_hooks_on := false
static func _end_hooks(dreams: DreamState) -> bool:
	var frame := Engine.get_process_frames()
	if frame != _end_hooks_frame or dreams.rules_stamp != _end_hooks_stamp or dreams.get_instance_id() != _end_hooks_owner:
		_end_hooks_frame = frame
		_end_hooks_stamp = dreams.rules_stamp
		_end_hooks_owner = dreams.get_instance_id()
		_end_hooks_on = dreams.has_rule(&"afterroot") or dreams.has_rule(&"dream_residue")
	return _end_hooks_on

# Far LOD (perf, owner 2026-10-19): a nightmare off screen that nothing has hit or given a status for LOD_QUIET s (so no
# Warden is on it) runs its whole update every LOD_EVERY frames, staggered, with the time it skipped: bigger walk steps,
# statuses ticked in one batch, its badges and looks only then. Bosses, and anything on the bridge, at the Heartwood,
# dragged or leaping, always run every frame; a hit or a status, or coming into view, puts it back at once.
const LOD_EVERY := 4
const LOD_QUIET := 1.5
var _lod_acc := 0.0  # Seconds skipped, still to run
var _quiet_for := 0.0  # Seconds since a hit or a status landed on it
var _logic_acc := 0.0  # Half-rate logic: seconds since its statuses, badges and presence last ran
var _look_acc := 0.0  # Half-rate looks: seconds since its lane and crowd row last ran
var _lod_slot := -1  # Its frame in the LOD_EVERY cycle (from its instance id: neighbours spread out)

func _far_lod() -> bool:
	return _quiet_for >= LOD_QUIET and not enemy_data.is_boss and not at_heartwood and _entry.is_empty() \
		and not _dragging and not _leaping and not _on_screen(self)

func _process(delta: float) -> void:
	if is_cleansed or (_path_index >= _path.size() and not at_heartwood):
		return
	if _waymark_index >= 0 and not passed_waymark and _path_index > _waymark_index:
		_touch_waymark()  # (Also after a leap or a burrow carried it past the stone)
	var far := _far_lod()
	if far:
		_lod_acc += delta
		if _lod_slot < 0:
			_lod_slot = get_instance_id() % LOD_EVERY
		if (Engine.get_process_frames() + _lod_slot) % LOD_EVERY != 0:
			return
		delta = _lod_acc
		_lod_acc = 0.0
	elif _lod_acc > 0.0:
		delta += _lod_acc  # Back to every frame: the skipped time runs now
		_lod_acc = 0.0
	_quiet_for += delta

	# Half-rate logic (perf, owner 2026-10-19; EnemySpawner.half_rate_logic, the real game): statuses and their hooks and
	# presence run every other frame (staggered) with the time between; walking, the badges and the looks every frame.
	var logic_now := true
	var ld := delta
	if _spawner != null and _spawner.half_rate_logic:
		_logic_acc += delta
		if _lod_slot < 0:
			_lod_slot = get_instance_id() % LOD_EVERY
		logic_now = (Engine.get_process_frames() + _lod_slot) % 2 == 0
		if logic_now:
			ld = _logic_acc
			_logic_acc = 0.0
	# Half-rate looks (perf trial 2026-10-24, EnemySpawner.half_rate_looks; reverses "the looks every frame" above for two
	# of them): the walking lane and the crowd row's look and fade run on the other frames from the logic, with the time
	# between. Walking, the badges and the rest stay every frame; a far-LOD frame does both.
	var look_now := true
	var look_delta := delta
	if _spawner != null and _spawner.half_rate_looks and not far:
		_look_acc += delta
		if _lod_slot < 0:
			_lod_slot = get_instance_id() % LOD_EVERY
		look_now = (Engine.get_process_frames() + _lod_slot) % 2 == 1
		if look_now:
			look_delta = _look_acc
			_look_acc = 0.0
	if logic_now:
		# Thin-family bookkeeping only while one of those cards is owned (the spawner checks once a frame).
		var thin: bool = _spawner != null and _spawner.thin_cards
		var was_caught := false
		var was_held := false
		if thin:
			statuses.marked_bonus = _spawner.marked_bonus  # Bright Marks
			was_caught = statuses.is_caught()
			if statuses.caught_time > _caught_left + 0.0001:
				_lingered = false  # Caught again (a Dreamcatcher's tick): its next lapse lingers again
			was_held = statuses.is_held()
			if was_held:
				_held_by = statuses.source(EnemyStatuses.HELD)
			_web_cooldown = maxf(_web_cooldown - ld, 0.0)
		elif statuses.marked_bonus != 0.0:
			statuses.marked_bonus = 0.0
		# Afterroot / Dream Residue read a hold or a catch ending: only while one of them is held (perf: this was a group
		# lookup and three status reads for every nightmare every frame)
		if _batch_dreams == null and is_inside_tree():
			_batch_dreams = get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState  # (Once, as take_damage)
		var unique_dreams := _batch_dreams if is_instance_valid(_batch_dreams) and _end_hooks(_batch_dreams) else null
		var unique_held := unique_dreams != null and statuses.is_held()
		var unique_holder := statuses.source(EnemyStatuses.HELD) if unique_held else null
		var unique_caught := unique_dreams != null and statuses.is_caught()
		var spore_soothe := statuses.tick(ld)
		if unique_dreams != null and unique_held and not statuses.is_held():  # Afterroot: any end of Rooted (keyword chips 2026-10-16)
			DreamState.UNIQUE_COOP.hold_expired(unique_dreams, self, unique_holder, unique_dreams._game_clock)
		if thin:
			if was_caught and not statuses.is_caught():
				_on_caught_lapsed()
			_caught_left = statuses.caught_time
			if was_held and not statuses.is_held():
				_on_hold_ended()
				if is_cleansed:
					return
		if unique_dreams != null and unique_caught and not statuses.is_caught():
			var catcher_ref = get_meta(&"unique_catcher") if has_meta(&"unique_catcher") else null
			var catcher = catcher_ref.get_ref() if catcher_ref is WeakRef else null
			DreamState.UNIQUE_PATH.caught_exited(unique_dreams, self, catcher, unique_dreams._game_clock)
		if spore_soothe > 0.0:
			var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
			if dreams != null:
				spore_soothe *= dreams.get_spored_tick_multiplier(self)  # Soaked Rot: harder on Soaked nightmares
			BranchKit.on_spore_tick(self)  # Lichenling: its spores strip the dread shell and stop mending
			statuses.delivering_spore_tick = true
			take_damage(spore_soothe, statuses.spore_tick_line, true, false, statuses.spore_tick_source,
				&"spored")
			statuses.delivering_spore_tick = false
			if is_cleansed:
				return
		if statuses.smother_ended:
			Reactions.on_smother_ended(self)  # Fever Dream (a Crowned Reaction)
			if is_cleansed:
				return
	# Timers: only the running ones count down (most sit at 0; this runs for every nightmare every frame).
	if _bolt_flash > 0.0:
		_bolt_flash = maxf(_bolt_flash - delta, 0.0)
	if _shrug_flash > 0.0:
		_shrug_flash = maxf(_shrug_flash - delta, 0.0)
	if elite:
		_haze_phase += ELITE_HAZE_SPEED * delta
	if _hit_mark_time > 0.0:
		_hit_mark_time = maxf(_hit_mark_time - delta, 0.0)
	if not _status_flash.is_empty():
		for id: StringName in _status_flash.keys():
			_status_flash[id] -= delta
			if _status_flash[id] <= 0.0:
				_status_flash.erase(id)
	if _crit_flash > 0.0:
		_crit_flash = maxf(_crit_flash - delta, 0.0)
	if _was_asleep or _settle > 0.0 or _wake_jolt > 0.0 or statuses.sleep_time > 0.0:
		_update_sleep(delta)  # Falling asleep / waking (screens_ui.md); nothing for an awake, settled nightmare
	if _pose_left > 0.0:
		_pose_left = maxf(_pose_left - delta, 0.0)
	if not _sustained.is_empty():
		_update_sustained(delta)
	if _flinch_left > 0.0 or _recoil != Vector2.ZERO or _sustained.has(ARC_TAG):  # (One timer; nothing when at rest)
		_update_flinch(delta / maxf(Engine.time_scale, 0.001))
	if _crack_hit_left > 0.0 or _freeze_left > 0.0 or _stagger_left > 0.0 or _stagger_scale != Vector2.ONE:
		_update_big_hit(delta / maxf(Engine.time_scale, 0.001))  # A big hit playing out (nothing for the rest)
	if freeze_cooldown > 0.0:
		freeze_cooldown = maxf(freeze_cooldown - delta, 0.0)
	if push_cooldown > 0.0:
		push_cooldown = maxf(push_cooldown - delta, 0.0)
	if _grounded_left > 0.0 and not _leaping:  # Groundroot: back up into the air when it runs out
		_grounded_left -= delta
		if _grounded_left <= 0.0:
			_rise_from_ground()
	# Smother's looping effect lasts while it's held with spores on it (Reactions): ended on the frame
	# tick() reports it stopping, and checked on each presence tick as well (_update_presence).
	if statuses.smother_ended:
		_end_smother_fx()
	# Its own drawing (the bars and badges are NightmareOverlay's): redrawn only for the Stag aura ring
	# or an animation that's playing (flashes, haze, embers, glow); off screen it waits until it's back.
	var aura := statuses.is_in_stag_aura()
	var animating := _bolt_flash > 0.0 or _shrug_flash > 0.0 or _hit_mark_time > 0.0 or elite or _crit_flash > 0.0 \
		or not _ash_cells.is_empty() or unbound or enemy_data.pack_shield < 1.0  # (The Huntsman's shield ring follows his hounds)
	if animating or _was_animating or aura != _drawn_aura:
		_drawn_aura = aura
		_redraw_pending = true  # (One more after an animation ends, to clear its last frame.)
	_was_animating = animating
	if _redraw_pending and _on_screen(self):
		_redraw_pending = false
		queue_redraw()
	# The HUD only when something it shows may have changed (perf, mobile_plan.md): its inputs' setters, a status
	# change, the zoom, or while badges (their time bars), flashes or pops are on
	var culled: bool = _spawner != null and _spawner.low_detail_now and not _on_screen(self)
	if culled != _culled:
		_culled = culled
		if culled:
			sprite.pause()  # Off screen on low detail: no frames to advance
		else:
			sprite.play()  # Back in view: carries on where it was
			_hud_dirty = true  # …and its HUD catches up this frame
			_steady_index = -1  # (The corner and squeeze checks too)
	# (Badges' time bars: every HUD_TIME_FRAMES frames, staggered, as _update_hud itself looks at them)
	if _culled:
		pass  # Off screen on low detail: the HUD waits (its dirty marks keep) until it's back in view
	elif _hud_dirty or statuses.hud_dirty or statuses.changes != _hud_changes \
			or _hud_flashing or _hud_popping or not _status_flash.is_empty() or not _hud_pops.is_empty() \
			or (_spawner != null and (_spawner.hud_text_scale != _hud_scale \
				or (not _hud_ids.is_empty() and (_spawner.hud_frame + _hud_stagger) % HUD_TIME_FRAMES == 0))):
		_hud_dirty = false
		statuses.hud_dirty = false
		_update_hud(delta)
	if not _culled and look_now:
		_update_row_look(look_delta)  # Status icons in crowds: pips or the full row
		_update_sort_look(look_delta)  # Y-sort by the drawn body, only in a crowd
	if _hud_ready_on and not _culled and _hud_ready.is_valid():  # Reaction-ready brackets breathe: a modulate and a scale, no rebuild
		_breathe_ready()
	if logic_now:
		_update_presence(ld)  # (Half-rate logic: reveals, fog and the per-kind presence with the time between)

	if _dragging:
		_update_drag(delta)  # Pulled back: no walking, traits or trampling meanwhile
		return
	if at_heartwood:
		if _path_index < _path.size():
			at_heartwood = false  # Pulled back off the Heartwood, or re-routed: it walks in again
		else:
			if enemy_data.laps():  # Night Mare: it lingers (10 s: leaves at 0, 2 … 8), then gallops off again
				_linger_left -= delta
				sprite.self_modulate.a = UNTOUCHABLE_ALPHA + 0.15 * sin(Time.get_ticks_msec() / 180.0)  # Smoky shimmer
				if _linger_left <= 0.0:
					_linger_left = 0.0
					at_heartwood = false
					_set_untouchable(false)  # Back on the path: it can be hit again
					_lap()
					return
			_drain_left -= delta  # It stays, draining a leaf every HEARTWOOD_DRAIN_EVERY s
			if _drain_left <= 0.0:
				_drain_left = HEARTWOOD_DRAIN_EVERY
				heartwood_drained.emit(self)
			return
	if hold_time > 0.0:
		hold_time -= delta
		return
	if not _entry.is_empty():
		_update_entry(delta)  # Still crossing the bridge from the fog
		return
	if statuses.is_held() or statuses.is_asleep():
		return  # Frozen / rooted in place, or asleep (Drown)
	if sleepwalk_left > 0.0:
		_walk_back(delta)  # Sleepwalk (Roguelite Code for the owner, 2026-10-17): back up the route, no traits meanwhile
		return
	_charge_left = maxf(_charge_left - delta, 0.0)
	_update_trait(delta)
	if _leaping:
		return
	if _spawner != null and not _spawner.rooted_cells.is_empty():  # (Perf: the call only when something is rooted)
		if _is_blocked_ahead(delta):
			return  # Rooted Nightmares: waiting for a Held nightmare in the next cell
	elif waiting:
		waiting = false
	if unbound:
		_trample_ahead()
	if enemy_data.covers_walkers and _update_pall(delta):
		return  # Pall: over (or gliding to) its walker, at its pace

	var previous_position := position
	# Walk toward the next cell centre; carry leftover distance into the following cell so speed
	# stays constant through corners. The speed is re-worked out when statuses change and on each
	# presence tick (0.1 s), not every frame.
	if statuses.changes != _speed_changes or _speed_stale or speed != _speed_base:
		_speed_cache = get_move_speed()
		_speed_changes = statuses.changes
		_speed_stale = false
		_speed_base = speed
	var remaining := _speed_cache * delta
	while remaining > 0.0 and _path_index < _path.size():
		if _target_index != _path_index or _target_serial != _path_serial:
			_point_px(_path_index)  # (The next point's pixel, once a step)
		var target := _target_px
		var to_target := target - position
		var distance := to_target.length()
		if distance <= remaining:
			position = target
			remaining -= distance
			_path_index += 1
			if _path_index >= 2 and _path_index < _path.size():
				var incoming: Vector2 = _path[_path_index - 1] - _path[_path_index - 2]
				var outgoing: Vector2 = _path[_path_index] - _path[_path_index - 1]
				if not incoming.normalized().is_equal_approx(outgoing.normalized()):
					set_meta(&"unique_bend_serial", int(get_meta(&"unique_bend_serial", 0)) + 1)
			_last_cell = _path[_path_index - 1]
			_on_cell_reached()
			if _leaping:
				return  # Started burrowing: the tween moves it now
			if _is_blocked_ahead(0.0):
				break  # Stops at this cell's centre and waits
			if unbound:
				_trample_ahead()
		else:
			position += to_target / distance * remaining
			remaining = 0.0

	# Update animation based on movement direction
	if not _culled:
		update_animation(position - previous_position)
	if not _culled and (_steady_index != _path_index or _steady_serial != _path_serial or _corner_offset != Vector2.ZERO \
			or _squeeze != 1.0 or (_gap_finder != null and _gap_finder.version != _gap_version)):
		_round_corners()
		_update_squeeze(delta)
		if _corner_offset == Vector2.ZERO and _squeeze == 1.0 and not _gap_answer and not _near_turn():
			_steady_index = _path_index  # A straight, no gap: nothing to check until the next step
			_steady_serial = _path_serial
	if look_now and not _culled and not _leaping and not _dragging and covering == null:
		_update_lane(look_delta)  # Walking lanes: the drawn body beside the centre line (a Pall takes its walker's)

	if _path_index >= _path.size():
		if loops_route:
			_restart_route()
			return
		if enemy_data.laps() and _linger_left <= 0.0:  # Night Mare: a new visit, a little longer each lap
			_linger_left = enemy_data.lap_linger + enemy_data.lap_linger_step * laps
			_drain_left = 0.0  # Its first leaf of the visit at once
			_set_untouchable(true)  # At the Heartwood it can't be touched
		if (enemy_data.is_boss and not is_echo and enemy_data.stays_at_heartwood) or enemy_data.laps():
			at_heartwood = true  # The Hollow Oak stays (the timers keep running if it's re-routed and walks back in)
			return
		if BranchKit.before_goal(self):
			return  # Heartroot's "Not yet": dragged back off the Heartwood (the drift's first leak)
		reached_goal.emit(self)
		queue_free()

# Night Mare: seconds left of its stay at the Heartwood (0 when it isn't there): the boss bar shows it.
func linger_left() -> float:
	return _linger_left if at_heartwood else 0.0

# Night Mare lingering at the Heartwood: it can't be hit or given statuses, and no Warden targets it
# (it leaves the enemies group, as hidden nightmares do); a dark, smoky shimmer. The boss bar tags it.
func is_untouchable() -> bool:
	return _untouchable

func _set_untouchable(value: bool) -> void:
	if value == _untouchable:
		return
	_untouchable = value
	if value:
		remove_from_group(GROUP)
		for id in statuses.active_ids():
			statuses.remove(id)  # Nothing sticks while it lingers
		sprite.self_modulate = Color(UNTOUCHABLE_TINT, UNTOUCHABLE_ALPHA)
	else:
		if not _hidden and not is_cleansed:
			add_to_group(GROUP)
		sprite.self_modulate = Color(1, 1, 1, HIDDEN_ALPHA if _hidden else 1.0)

# Night Mare: the Heartwood loses its lap leaves (the spawner takes them) and the Mare gallops back to
# the start, faster each time.
func _lap() -> void:
	laps += 1
	if laps <= LAP_SPEED_LAPS:  # Faster for its first laps only: unbounded, it soon crossed the map between two shots
		speed *= enemy_data.lap_speed_multiplier
	_speed_stale = true
	lapped.emit(self)
	_restart_route()

func _refuse_status(id: StringName) -> void:
	var now := Time.get_ticks_msec()
	if now - int(_refused_at.get(id, -100000)) < REFUSED_THROTTLE * 1000.0:
		return
	_refused_at[id] = now
	status_refused.emit(self, id)

# A combo just used this status (e.g. lightning jumped through Damp): its icon flashes briefly.
# Called by the HUD's combat callouts. Does nothing if the status isn't on this nightmare.
# A Dream card just changed status `id` on this nightmare (visual_feedback_spec.md C3 "Status pop"; the card code calls
# it from its cue table): its badge bumps x1.2 with a Heartlight rim for DREAM_POP_TIME. Nothing if it doesn't carry it; a status just added pops once the row lays it out.
func dream_status_pop(id: StringName) -> void:
	if is_cleansed or not statuses.has(id):  # (Newly added: not in the row yet; the pop waits there for its layout)
		return
	_hud_pops[id] = DREAM_POP_TIME
	_dream_pops[id] = true
	_hud_dirty = true

func flash_status(id: StringName) -> void:
	# Once per flash: combos fire on every tick and hit (a Marked, Spored nightmare reports "marked"
	# twice a second), and each flash spawns a world effect.
	if statuses.has(id) and not _status_flash.has(id):
		_status_flash[id] = STATUS_FLASH_TIME
		queue_redraw()
		var world := Reactions._world(self)
		if world:
			Fx.status_flash(id, get_body_position(), world)  # (On the drawn body: walking lanes)

# Comes in along `points` (the fog, the bridge, the start's lane point; MapGenerator pixels) before its route.
func enter_along(points: PackedVector2Array) -> void:
	if points.size() < 2:
		return
	_entry = points
	_entry_time = 0.0
	position = points[0]
	remove_from_group(GROUP)  # Not on the island yet: no Warden can reach it
	modulate.a = 0.0  # It fades in out of the fog (its HUD with it)
	z_index = ENTRY_Z  # Between the deck and the fog (it emerges from the fog)

func is_entering() -> bool:
	return not _entry.is_empty()

# Walks the way in at an even pace; on the island it joins the enemies group and its route begins.
func _update_entry(delta: float) -> void:
	_entry_time += delta
	var t := clampf(_entry_time / ENTRY_TIME, 0.0, 1.0)
	var total := 0.0
	for i in range(1, _entry.size()):
		total += _entry[i].distance_to(_entry[i - 1])
	var along := total * t
	var previous := position
	for i in range(1, _entry.size()):
		var leg := _entry[i].distance_to(_entry[i - 1])
		if along <= leg or i == _entry.size() - 1:
			position = _entry[i - 1].lerp(_entry[i], clampf(along / maxf(leg, 0.001), 0.0, 1.0))
			break
		along -= leg
	update_animation(position - previous)
	modulate.a = clampf(t / ENTRY_FADE, 0.0, 1.0)
	if t >= 1.0:
		_entry = PackedVector2Array()
		modulate.a = 1.0
		z_index = 0  # On the island: y-sorted with the Wardens again
		if not _hidden and not _untouchable and not is_cleansed:
			add_to_group(GROUP)  # On the island: the Wardens can reach it

# Target Dummy: back to the forest's edge to walk the maze again.
func _restart_route() -> void:
	var map_generator = get_parent().get("map_generator")  # The EnemyContainer's
	var start: Vector2 = _path[0] if map_generator == null else map_generator.startPath
	var route: PackedVector2Array = _path if map_generator == null else map_generator.get_path_from(start)
	position = grid.calculate_map_position(start)
	passed_waymark = false  # A new lap walks both legs again (Night Mare)
	set_path(route)

func _draw() -> void:
	if is_cleansed:
		return
	for cell: Vector2 in _ash_cells:  # Ash Crawler: embers on the cells it just crossed
		var t: float = _ash_cells[cell] / enemy_data.ash_trail_time
		var at := to_local(grid.calculate_map_position(cell))
		for i in 3:
			draw_circle(at + Vector2(-10 + 10 * i, 6 - 5 * (i % 2)), 2.0 + 1.5 * t, Color(ASH_COLOR, ASH_COLOR.a * t))
	if _hidden:
		return  # Only the faint sprite shows: no bars, no status icons
	# Ground rings stay on the route point; everything round the body is raised with it (foot lift)
	if _shrug_flash > 0.0:  # Barrow King: a ring of grave-dust out to the shrug's reach
		var t := _shrug_flash / SHRUG_FLASH_TIME
		draw_arc(Vector2.ZERO, enemy_data.shrug_radius * grid.cell_size.x * (1.0 - t * 0.6), 0.0, TAU, 48,
			Color(SHRUG_COLOR, 0.6 * t), 4.0)
	if statuses.is_in_stag_aura():
		draw_arc(Vector2(0, 6), 18.0, 0.0, TAU, 24, Color(Palette.MOONLIGHT, 0.35), 2.0)
	if _body_fx != null:
		_body_fx.queue_redraw()  # Round the body: _draw_body, on a child sorted with the sprite (y-sort by drawn body)
	# The health bar, coat, Restless arrows and status badges are in the HUD's own canvas items (update_hud).

# The glows and marks round the drawn body, on _body_fx (a child just before the sprite, at the sprite's position, so
# the y-sort keeps them right behind it: council 2026-10-24c), raised with the foot lift.
func _draw_body() -> void:
	if is_cleansed or _hidden:
		return
	_body_fx.draw_set_transform(Vector2(0, -_foot_lift))
	if unbound:  # Cold ghost-fire glow behind the sprite, pulsing (no warm colour on nightmares)
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 150.0)
		_body_fx.draw_circle(Vector2(0, -8), 24.0 * sprite.scale.x, Color(UNBOUND_GLOW, 0.18 + 0.12 * pulse))
		_body_fx.draw_circle(Vector2(0, -8), 15.0 * sprite.scale.x, Color(Palette.MOONLIGHT, 0.22 + 0.12 * pulse))
	if elite:
		_draw_elite_haze()  # Drawn before the sprite (the next child), so it sits behind it
	if _bolt_flash > 0.0:
		var t := _bolt_flash / BOLT_FLASH_TIME
		_body_fx.draw_circle(Vector2.ZERO, 26.0 * (1.5 - t), Color(Palette.GLOW, 0.5 * t))  # The Warden's bolt: warm light
	if enemy_data.pack_shield < 1.0 and get_pack_multiplier() < 1.0:  # Huntsman: the faint ring while the pack shields him
		_body_fx.draw_arc(Vector2(0, -8), 30.0 * sprite.scale.x, 0.0, TAU, 32, Color(Palette.DEWLIGHT, 0.35), 2.0)
	if _hit_mark_time > 0.0:
		_draw_hit_mark(_hit_mark_time / HIT_MARK_TIME)

# The HUD over this nightmare (health bar, blight coat, Restless arrows, status badges), in canvas
# items of its own under this node's (so they move with it, and the renderer culls them off screen):
# HUD_BARS, HUD_MARKS, HUD_ICONS, HUD_TEXT, each on its own absolute z layer (NightmareOverlay.Z +
# kind), so every nightmare's bars draw together, then every mark (time bars, glows: one atlas), every icon, every
# number: the field batches. Each item is rebuilt only when what it shows changes (checked from
# _process); freed with the nightmare. NightmareOverlay keeps the shared badge atlas.
func _update_hud(delta: float) -> void:
	var overlay: NightmareOverlay = _spawner.overlay if _spawner != null else null
	if overlay == null or overlay.badge_atlas == null:
		_hud_dirty = true  # Not ready yet: look again next frame
		return
	var show := not _hidden and not is_cleansed
	if not _hud_root.is_valid():
		if not show:
			return
		_make_hud()
	if show != _hud_shown:
		_hud_shown = show
		RenderingServer.canvas_item_set_visible(_hud_root, show)
	if not show:
		return
	var text_scale: float = _spawner.hud_text_scale  # (Worked out once a frame by the spawner; _spawner is set: overlay above)
	if text_scale != _hud_scale:  # The badges keep their screen size: scaled round the row's anchor
		_hud_scale = text_scale
		var badges := Transform2D(0.0, Vector2(text_scale, text_scale), 0.0, _hud_anchor())
		for kind in [HUD_MARKS, HUD_ICONS, HUD_PILLS, HUD_TEXT]:
			RenderingServer.canvas_item_set_transform(_hud_items[kind], badges)
	# The bars are keyed on their width in whole px (a smaller change can't be seen), -1 = not shown.
	var bar_px := int(HEALTH_BAR_SIZE.x * health / max_health) if health < max_health or _bars_always else -1
	var coat_px := int(HEALTH_BAR_SIZE.x * coat / maxf(coat_max, 1.0)) if coat > 0.0 else -1
	var awake := statuses.sleep_cooldown > 0.0
	if bar_px != _hud_health or coat_px != _hud_coat or restless != _hud_restless or unbound != _hud_unbound \
			or _bars_always != _hud_always or statuses.slow_capped != _hud_slow_capped or awake != _hud_awake:
		_hud_health = bar_px
		_hud_coat = coat_px
		_hud_restless = restless
		_hud_unbound = unbound
		_hud_always = _bars_always
		_hud_slow_capped = statuses.slow_capped
		_hud_awake = awake
		_build_hud_bars(_hud_items[HUD_BARS])
		hud_builds += 1
	if _hud_ids.is_empty() and _hud_changes == statuses.changes:
		return  # No badges: nothing more to check
	var changed := _hud_changes != statuses.changes
	# A cap that moved without a stack change (Brimming taken, Heavy Eyelids): looked at on this row's time-bar frames
	# only, at most HUD_TIME_FRAMES late (perf: get_max_stacks per badge on every HUD call was ~0.35 ms a frame on a busy
	# field, where hits call it for the health bar; Main Merger's ~0.1 s allowance for badge numbers, 2026-10-17).
	if not changed and (Engine.get_process_frames() + _hud_stagger) % HUD_TIME_FRAMES == 0:
		for i in _hud_ids.size():
			if _hud_caps[i] != statuses.get_max_stacks(_hud_ids[i]):
				changed = true
				break
	if changed:
		_update_hud_layout()
	if _row_alpha.x <= 0.0 and _row_look != RowLook.FULL:
		# (Perf 2026-10-24) In a crowd the full row is faded out (its pips show): the layout above keeps up, but its
		# badges, numbers and time bars aren't drawn until it shows again (_update_row_look rebuilds them, _row_stale)
		_row_stale = true
		for id in _hud_pops.keys():  # (Pops still play out, unseen)
			_hud_pops[id] -= delta
			if _hud_pops[id] <= 0.0:
				_hud_pops.erase(id)
				_dream_pops.erase(id)
		_hud_popping = false
		_hud_flashing = false
		_hud_ready_on = false
		return
	if changed:
		_build_hud_pills(_hud_items[HUD_PILLS], overlay)
		_build_hud_text(_hud_items[HUD_TEXT])
	# A stack was just added: that icon pops (a quick scale bump), rebuilt each frame while it plays.
	if not _hud_pops.is_empty():
		for id in _hud_pops.keys():
			_hud_pops[id] -= delta
			if _hud_pops[id] <= 0.0:
				_hud_pops.erase(id)
				_dream_pops.erase(id)
		_build_hud_icons(_hud_items[HUD_ICONS])
		_hud_popping = true
	elif changed or _hud_popping:
		_hud_popping = false
		_build_hud_icons(_hud_items[HUD_ICONS])
	# The time bars shorten in TIME_STEPS steps: looked at every HUD_TIME_FRAMES frames (staggered), and
	# the marks rebuilt when a step moved (or a status changed, or a combo flash plays).
	var flashing := not _status_flash.is_empty()
	if not changed and not flashing and not _hud_flashing \
			and (Engine.get_process_frames() + _hud_stagger) % HUD_TIME_FRAMES != 0:
		return
	var marks_key := _hud_changes << 16  # Below that: 4 bits of time-bar steps per icon (up to 4 icons)
	for i in _hud_ids.size():
		marks_key += _time_steps(i) << (i * 4)
		if statuses.is_lingering(_hud_ids[i]) or _is_kept(_hud_ids[i]):
			marks_key += 1 << (12 + i)  # (The linger / kept rim; bits 12-14 are free: at most 3 icons use 0-11)
	var season := _season_percent()  # Grows as it walks: looked at on the time-bar frames
	if season != _hud_season:
		_hud_season = season
		_build_hud_text(_hud_items[HUD_TEXT])
	if changed or marks_key != _hud_marks_key or flashing or _hud_flashing:
		_hud_marks_key = marks_key
		_hud_flashing = not _status_flash.is_empty()  # (One more once a flash ends, to clear it)
		_build_hud_marks(_hud_items[HUD_MARKS], overlay)
		hud_builds += 1

# The badge row's look now (RowLook): full for the hovered / tapped nightmare, bosses, Deeply Blighted and anything not
# crowded; compact pips in a crowd; nothing under "Off" (but the hovered / tapped one).
func _wanted_row_look() -> RowLook:
	if _spawner != null and _spawner.hud_focus == self:
		return RowLook.FULL
	var mode: int = _spawner.status_icons_now if _spawner != null else int(Fx.setting("status_icons", 1))  # (Read once a frame: perf)
	if mode == 2:
		return RowLook.OFF
	if mode == 0 or enemy_data.is_boss or elite:
		return RowLook.FULL
	if _spawner != null and crowd_seen >= 0.0 and _spawner.crowd_clock - crowd_seen <= CROWD_SEEN:
		return RowLook.COMPACT
	return RowLook.FULL

# Every frame it's on screen: switch the row's look (held CROWD_HOLD s at least) and ease the full row and the pips'
# alphas toward it; only touches the server when something moves.
# Y-sort by the drawn body only in a crowd (perf 2026-10-25): y_sort_enabled makes the sprite, BodyFx and other children
# sort one by one (about three items a nightmare); apart, the node's own position sorts it the same. On at once when
# crowded, off CROWD_HOLD s after the crowd thins (so a pack's edge doesn't flip it).
var _sort_hold := 0.0
var sort_seen := -1.0  # EnemySpawner.crowd_clock when another drawn body was last within SORT_REACH (its own mark: crowd_seen is the status rows')

func _update_sort_look(delta: float) -> void:
	_sort_hold -= delta
	var crowded: bool = _spawner != null and sort_seen >= 0.0 and _spawner.crowd_clock - sort_seen <= CROWD_SEEN
	if crowded:
		_sort_hold = CROWD_HOLD
	if crowded != y_sort_enabled and (crowded or _sort_hold <= 0.0):
		y_sort_enabled = crowded

func _update_row_look(delta: float) -> void:
	if not _hud_root.is_valid() or _hud_items.is_empty():
		return
	_row_hold -= delta
	var want := _wanted_row_look()
	if want != _row_look and (_row_hold <= 0.0 or want == RowLook.FULL and _spawner != null and _spawner.hud_focus == self):
		_row_look = want
		_row_hold = CROWD_HOLD
		_hud_health = -2  # The health bar rebuilds at its new height
		_hud_dirty = true
	var focus: bool = _spawner != null and _spawner.hud_focus == self
	if focus != _focus_drawn:  # Its row draws over the crowd's, with a ring (UI council round 8)
		_focus_drawn = focus
		for kind in HUD_PASSES:
			RenderingServer.canvas_item_set_z_index(_hud_items[kind], NightmareOverlay.Z + kind + (FOCUS_Z if focus else 0))
		if _hud_pips.is_valid():
			RenderingServer.canvas_item_set_z_index(_hud_pips, NightmareOverlay.Z + HUD_ICONS + (FOCUS_Z if focus else 0))
		_hud_health = -2  # The ring is drawn with the bars
		_hud_dirty = true
	var target := Vector2(1.0, 0.0)
	if _row_look == RowLook.COMPACT:
		# UI Code's pips carry their own 70%; the placeholders take it from the item. Hidden under a front row.
		var hidden: bool = _spawner != null and pips_hidden_seen >= 0.0 and _spawner.crowd_clock - pips_hidden_seen <= CROWD_SEEN
		target = Vector2(0.0, 0.0 if hidden else (1.0 if _ui_pip_rid() else CROWD_PIP_ALPHA))
	elif _row_look == RowLook.OFF:
		target = Vector2.ZERO
	if target.y > 0.0 and _pips_changes != statuses.changes:
		_build_pips()
	elif _hud_pips.is_valid():
		_place_pips()  # (The text scale or touch mode moved)
	if _row_stale and target.x > 0.0:  # Showing again: everything the faded-out row skipped, drawn before it fades in
		_row_stale = false
		_hud_changes = -1
		_update_hud(0.0)
	if _row_alpha == target:
		return
	if bool(Fx.setting("reduced_motion", false)):
		_row_alpha = target
	else:
		_row_alpha = _row_alpha.move_toward(target, delta / CROWD_EASE)
	for kind in [HUD_MARKS, HUD_ICONS, HUD_PILLS, HUD_TEXT]:
		RenderingServer.canvas_item_set_modulate(_hud_items[kind], Color(1, 1, 1, _row_alpha.x))
	if _hud_pips.is_valid():
		RenderingServer.canvas_item_set_modulate(_hud_pips, Color(1, 1, 1, _row_alpha.y))

# The crowd row (UI council round 8): left-aligned on its own health bar's left end, 1 px above it, scaled like the
# badge rows (hud_text_scale) and drawn in whole pixels (PIP_PX art px: x1 on PC, x2 on phones), at most CROWD_PIPS_MAX
# pips and a "more" dot. Hidden while a front nightmare's row covers it (EnemySpawner marks pips_hidden_seen).
const CROWD_PIPS_MAX := 3
const PIP_ART := 7  # UI Code's pip: 7 art px (5 of colour in a 1 px Void outline); a step of 8
const PIP_OUTLINE_ALPHA := 1.0  # = KeywordIcons.PIP_OUTLINE_ALPHA / PIP_FILL_ALPHA (not readable before UI Code's branch is on main)
const PIP_FILL_ALPHA := 0.85
var pips_hidden_seen := -1.0
var _pips_scale := -1.0
var _pips_px := 0

func _pip_px() -> int:
	return 2 if TouchBuild.mobile_controls() else 1

func _build_pips() -> void:
	_pips_changes = statuses.changes
	if not _hud_pips.is_valid():
		_hud_pips = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(_hud_pips, _hud_root)
		RenderingServer.canvas_item_set_z_as_relative_to_parent(_hud_pips, false)
		RenderingServer.canvas_item_set_z_index(_hud_pips, NightmareOverlay.Z + HUD_ICONS + (FOCUS_Z if _focus_drawn else 0))
		RenderingServer.canvas_item_set_modulate(_hud_pips, Color(1, 1, 1, _row_alpha.y))
		_pips_scale = -1.0
	_place_pips()
	RenderingServer.canvas_item_clear(_hud_pips)
	var px := _pip_px()
	var order := get_status_order()
	var shown := mini(order.size(), CROWD_PIPS_MAX)
	for i in shown:  # Centres in whole art pixels: a pip's top-left lands on a whole pixel
		_draw_pip(Vector2(px * (PIP_ART / 2.0 + (PIP_ART + 1) * i), -px * (PIP_ART / 2.0)), order[i], px)
	if order.size() > CROWD_PIPS_MAX:  # "More": a small dot after the last pip
		var at := Vector2(px * ((PIP_ART + 1) * shown + 1), -px * 4)
		RenderingServer.canvas_item_add_rect(_hud_pips, Rect2(at - Vector2(px, px), Vector2(px, px) * 3.0), Color(Palette.VOID, 0.8))
		RenderingServer.canvas_item_add_rect(_hud_pips, Rect2(at, Vector2(px, px)), Palette.MOONLIGHT)

# The pips item's transform: the health bar's left end, 1 px above it, at the badge rows' scale (rounded to whole px).
func _place_pips() -> void:
	var text_scale: float = _spawner.hud_text_scale if _spawner != null else 1.0
	if text_scale == _pips_scale and _pips_px == _pip_px():
		return
	_pips_scale = text_scale
	_pips_px = _pip_px()
	var bar_h := CROWD_BAR_H if _row_look == RowLook.COMPACT else HEALTH_BAR_SIZE.y
	var left := (_bar_offset + Vector2(-HEALTH_BAR_SIZE.x / 2.0, -bar_h / 2.0 - 2.0)).round()
	RenderingServer.canvas_item_set_transform(_hud_pips, Transform2D(0.0, Vector2(text_scale, text_scale), 0.0, left))

static var _ui_methods := {}  # UI Code's KeywordIcons draw helpers: name -> their argument count, -1 while not on main (looked up once)

# How many arguments KeywordIcons' `name` takes (-1: not on main yet), so a call can wait for (or match) UI Code's branch.
func _ui_method_args(method_name: String) -> int:
	if not _ui_methods.has(method_name):
		_ui_methods[method_name] = -1
		for method in (KeywordIcons as Script).get_script_method_list():
			if method.name == method_name:
				_ui_methods[method_name] = (method.args as Array).size()
	return int(_ui_methods[method_name])

func _ui_pip_rid() -> bool:
	return _ui_method_args("draw_pip_rid") >= 0

# One pip at `at` (its centre), `px` screen px per art px. UI Code's art once KeywordIcons.draw_pip_rid is on main (its
# own outline / fill alpha: the item's modulate is then only the ease); until then a plain square in the status colour.
func _draw_pip(at: Vector2, id: StringName, px: int) -> void:
	if _ui_method_args("draw_pip_rid") >= 7:  # Section 35: a full status lights its outline (Heartlight)
		var cap := statuses.get_max_stacks(id)
		var full := cap > 1 and statuses.stacks(id) >= cap
		(KeywordIcons as Script).call("draw_pip_rid", _hud_pips, id, at, float(px), PIP_OUTLINE_ALPHA, PIP_FILL_ALPHA, full)
		return
	if _ui_pip_rid():
		(KeywordIcons as Script).call("draw_pip_rid", _hud_pips, id, at, float(px))  # Its own outline 1.0 / fill 0.85 (ab79e6e4)
		return
	var colour: Color = EnemyStatuses.COLORS.get(id, Palette.MOONLIGHT)
	var corner := (at - Vector2(PIP_ART, PIP_ART) * px / 2.0).round()
	RenderingServer.canvas_item_add_rect(_hud_pips, Rect2(corner, Vector2(PIP_ART, PIP_ART) * px), Color(Palette.VOID, 0.8))
	RenderingServer.canvas_item_add_rect(_hud_pips, Rect2(corner + Vector2(px, px), Vector2(PIP_ART - 2, PIP_ART - 2) * px), colour)

func _make_hud() -> void:
	_hud_root = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(_hud_root, get_canvas_item())  # Moves with the nightmare, no script
	RenderingServer.canvas_item_set_transform(_hud_root, Transform2D(0.0, _body_offset()))  # (Mid-corner already)
	_hud_items.clear()
	for kind in HUD_PASSES:
		var item := RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(item, _hud_root)
		RenderingServer.canvas_item_set_z_as_relative_to_parent(item, false)
		RenderingServer.canvas_item_set_z_index(item, NightmareOverlay.Z + kind)
		if kind == HUD_ICONS:  # The pixel-art icons keep their pixels; the marks and numbers are smooth
			RenderingServer.canvas_item_set_default_texture_filter(item, RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_NEAREST)
		elif kind != HUD_BARS:
			RenderingServer.canvas_item_set_default_texture_filter(item, RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_LINEAR)
		_hud_items.append(item)
	_hud_ready = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(_hud_ready, _hud_items[HUD_MARKS])  # The badges' transform and layer; its own modulate
	_hud_shown = true
	_hud_scale = -1.0
	_hud_changes = -1
	_hud_health = -2  # Builds the bars on the first update

func _free_hud() -> void:
	if not _hud_root.is_valid():
		return
	for ready_item in _hud_ready_items:  # (Great-grandchildren, then their parent: children before parents)
		RenderingServer.free_rid(ready_item)
	_hud_ready_items.clear()
	_hud_ready_at.clear()
	_hud_ready_used = 0
	if _hud_ready.is_valid():  # (A grandchild: freed before its parent)
		RenderingServer.free_rid(_hud_ready)
	_hud_ready = RID()
	for item in _hud_items:  # Children first, then the root
		if item.is_valid():
			RenderingServer.free_rid(item)
	_hud_items.clear()
	if _hud_pips.is_valid():  # (A child of the root: freed first)
		RenderingServer.free_rid(_hud_pips)
	_hud_pips = RID()
	RenderingServer.free_rid(_hud_root)
	_hud_root = RID()

# Where the badge row sits (its bottom centre on the health bar's top edge), from the nightmare's origin.
func _hud_anchor() -> Vector2:
	return _bar_offset - Vector2(0, HEALTH_BAR_SIZE.y / 2.0 + 2.0)

# The badge row's statuses, stacks, caps, colours and icons, worked out again only when a status
# comes, goes or changes stacks (statuses.changes).
func _update_hud_layout() -> void:
	_hud_changes = statuses.changes
	var before := {}  # Stacks last time: an icon whose stacks went up pops
	for i in _hud_ids.size():
		before[_hud_ids[i]] = _hud_stacks[i]
	var order := get_status_order()
	_hud_total = order.size()
	_hud_ids = _pick_badges(order)
	for id in _hud_ids:
		if statuses.stacks(id) > int(before.get(id, 0)) and not _dream_pops.has(id):  # (A Dream pop keeps its own)
			_hud_pops[id] = STACK_POP_TIME
	_hud_stacks.clear()
	_hud_badge_widths.clear()
	_hud_caps.clear()
	_hud_full.clear()
	_hud_colors.clear()
	_hud_icons.clear()
	_hud_primed.clear()
	for id in _hud_ids:
		var stacks := statuses.stacks(id)
		var cap := statuses.get_max_stacks(id)
		_hud_stacks.append(stacks)
		_hud_caps.append(cap)
		var label_width := _stack_font_face().get_string_size(str(stacks), HORIZONTAL_ALIGNMENT_LEFT, -1, _stack_count_font_size(stacks)).x + 8.0
		var primed := _is_primed(id)
		_hud_primed.append(primed)
		# A Reaction-ready badge gets room for its corner brackets on both sides, so they never reach the next badge
		_hud_badge_widths.append(maxf(get_badge_size() + 2.0, label_width) + (READY_PAD_LEFT + READY_PAD_RIGHT if primed else 0.0))
		_hud_full.append(cap > 1 and stacks >= cap)
		_hud_colors.append(EnemyStatuses.COLORS.get(id, Palette.MOONLIGHT))
		var icon := _status_icon(id)
		if icon == null and id == EnemyStatuses.ASLEEP:
			icon = _status_icon(EnemyStatuses.DROWSY)  # No Asleep icon in the sheet yet: Sleep's, with a "z" (_build_hud_marks)
		_hud_icons.append(icon)

# Status icon i's centre in the badge items' space (screen px round the anchor): a row of icons with
# room under each for its time bar.
func _badge_centre(i: int) -> Vector2:
	var r := get_badge_size() / 2.0
	if i < 0 or i >= _hud_badge_widths.size():
		return Vector2(0.0, -r - TIME_BAR_GAP)  # Not laid out (the row was cleared or is being rebuilt): the row's centre
	var width := STATUS_BADGE_GAP * maxi(_hud_ids.size() - 1, 0)
	for cell_width in _hud_badge_widths:
		width += cell_width
	var extra := _hud_total - _hud_ids.size()
	if extra > 0:
		width += STATUS_BADGE_GAP + _stack_font_face().get_string_size("+%d" % extra, HORIZONTAL_ALIGNMENT_LEFT, -1, STACK_FONT_SIZE).x
	var x := -width / 2.0
	for previous in i:
		x += _hud_badge_widths[previous] + STATUS_BADGE_GAP
	var pad := READY_PAD_RIGHT if i < _hud_primed.size() and _hud_primed[i] else 0.0  # (Its brackets' room on the right)
	return Vector2(x + _hud_badge_widths[i] - r - 2.0 - pad, -r - TIME_BAR_GAP)
func _time_steps(i: int) -> int:
	return mini(ceili(statuses.time_share(_hud_ids[i]) * NightmareOverlay.TIME_STEPS), NightmareOverlay.TIME_STEPS)

func _build_hud_bars(item: RID) -> void:
	RenderingServer.canvas_item_clear(item)
	if _hud_awake:  # Just woke: a faint ring round it, it can't fall asleep again yet (tower_design.md)
		var ring := PackedVector2Array()
		for i in AWAKE_RING_POINTS + 1:
			ring.append(Vector2(0, -8) + Vector2.from_angle(TAU * i / AWAKE_RING_POINTS) * AWAKE_RING_RADIUS * sprite.scale.x)
		RenderingServer.canvas_item_add_polyline(item, ring, PackedColorArray([AWAKE_RING_COLOR]), 1.5)
	if _hud_slow_capped:  # Slowed to the limit: a pale floor line with end ticks under the health bar
		var y := _bar_offset.y + HEALTH_BAR_SIZE.y / 2.0 + 3.0
		var half := HEALTH_BAR_SIZE.x / 2.0
		var floor_line := PackedVector2Array([Vector2(-half, y - 2), Vector2(-half, y), Vector2(half, y), Vector2(half, y - 2)])
		RenderingServer.canvas_item_add_polyline(item, floor_line, PackedColorArray([SLOW_FLOOR_COLOR]), 1.5)
	# Restless: a small backward arrow per stack, right of the health bar (red-hot once Unbound)
	for i in restless:
		var tip := _bar_offset + Vector2(HEALTH_BAR_SIZE.x / 2 + 5 + i * 6, 0)
		var arrow := PackedVector2Array([tip + Vector2(4, -3), tip, tip + Vector2(4, 3)])
		RenderingServer.canvas_item_add_polyline(item, arrow, PackedColorArray([Color(Palette.VOID, 0.8)]), 3.0)
		RenderingServer.canvas_item_add_polyline(item, arrow, PackedColorArray([UNBOUND_GLOW if unbound else RESTLESS_COLOR]), 1.5)
	# Health bar once the enemy has been hit, with the blight coat as a grey bar on top of it
	var bar_size := HEALTH_BAR_SIZE if _row_look != RowLook.COMPACT else Vector2(HEALTH_BAR_SIZE.x, CROWD_BAR_H)  # (3 px in a crowd)
	var bar := Rect2(_bar_offset - bar_size / 2, bar_size)
	var compact := _row_look == RowLook.COMPACT
	if _focus_drawn:  # The hovered / tapped one: a ring round its body (UI council round 8)
		var ring := PackedVector2Array()
		for i in AWAKE_RING_POINTS + 1:
			ring.append(Vector2(0, -8) + Vector2.from_angle(TAU * i / AWAKE_RING_POINTS) * 22.0 * sprite.scale.x)
		RenderingServer.canvas_item_add_polyline(item, ring, PackedColorArray([Color(Palette.MOONLIGHT, 0.7)]), 1.5)
	if health < max_health or _bars_always:
		RenderingServer.canvas_item_add_rect(item, bar.grow(1), Color(Palette.VOID, 0.8))
		if compact:  # A 1 px Void line under it, so stacked crowd bars separate
			RenderingServer.canvas_item_add_rect(item, Rect2(bar.position + Vector2(-1, bar.size.y + 1), Vector2(bar.size.x + 2, 1)), Color(Palette.VOID, 0.8))
		var fill := bar
		fill.size.x *= float(health) / max_health
		# The health bar is HUD, not the nightmare: green reads as health. In a crowd a dread shell tints it instead of its own bar.
		RenderingServer.canvas_item_add_rect(item, fill, Palette.SPRIG.lerp(COAT_COLOR, 0.5) if compact and coat > 0.0 else Palette.SPRIG)
	if coat > 0.0 and not compact:
		var crust := Rect2(bar.position - Vector2(0, 4), Vector2(bar.size.x * coat / maxf(coat_max, 1.0), 3))
		RenderingServer.canvas_item_add_rect(item, crust.grow(1), Color(Palette.VOID, 0.8))
		RenderingServer.canvas_item_add_rect(item, crust, COAT_COLOR)

# The marks around the status icons, from NightmareOverlay's atlas: a soft gold glow behind an icon at
# max stacks, small-cap pips or a high-cap progress bar above a status's icon (one per stack it can hold, filled per
# stack, gold when full), a thin bar under each icon that shortens with the time left, a dot if the
# icon sheet has none, and the flash when a combo just used the status.
func _build_hud_marks(item: RID, overlay: NightmareOverlay) -> void:
	RenderingServer.canvas_item_clear(item)
	_hud_ready_used = 0
	var ready_any := false
	var atlas: Texture2D = overlay.badge_atlas
	var solid := overlay.badge_region(NightmareOverlay.MARK_SOLID)
	var dot := overlay.badge_region(NightmareOverlay.MARK_DOT)
	var r := get_badge_size() / 2.0
	for i in _hud_ids.size():
		var centre := _badge_centre(i)
		var color: Color = _hud_colors[i]
		var id: StringName = _hud_ids[i]
		if _hud_full[i] and _ui_method_args("draw_full_dot_rid") >= 0:  # UI Code section 35: the full dot under the icon
			(KeywordIcons as Script).call("draw_full_dot_rid", item, centre, r, color)
		elif _hud_full[i]:  # At max stacks: a warm glow behind the icon
			var g := r * 1.7
			atlas.draw_rect_region(item, Rect2(centre - Vector2(g, g), Vector2(g, g) * 2.0),
				overlay.badge_region(NightmareOverlay.MARK_GLOW), Color(Palette.GOLD, 0.75))
		var cap := statuses.get_max_stacks(id)
		if cap > STACK_PIP_CAP:
			var progress := Rect2(centre + Vector2(-r, -r - 6.0), Vector2(r * 2.0, 3.0))
			atlas.draw_rect_region(item, progress.grow(1.0), solid, Color(Palette.VOID, 0.8))
			atlas.draw_rect_region(item, progress, solid, Color(color, 0.25))
			progress.size.x *= clampf(float(_hud_stacks[i]) / cap, 0.0, 1.0)
			if progress.size.x > 0.0:
				atlas.draw_rect_region(item, progress, solid, Palette.GOLD if _hud_full[i] else color)
			var need := Reactions.ready_need(id, statuses)  # Brimming doubles the cap, never the need: the slash moves left
			if need > 0:  # A Reaction that needs it full: the slash at the bar's end (owner 2026-10-19)
				var x := centre.x - r + r * 2.0 * minf(float(need) / cap, 1.0)
				_draw_threshold_slash(item, Vector2(x - 1.5, centre.y - r - 1.5), Vector2(x + 1.5, centre.y - r - 7.5))
		elif cap > 1:  # Small caps use individual pips.
			var width := r * 2.0
			var most := maxi(int((width + 1.0) / (STACK_PIP_MIN + 1.0)), 1)  # Pips a row holds at the smallest size
			var shown_cap := mini(cap, 20)  # Bounded progress pips; the tooltip keeps exact counts.
			var shown_stacks := floori(float(_hud_stacks[i]) / cap * shown_cap)
			var rows := ceili(float(shown_cap) / most)
			var per_row := ceili(float(shown_cap) / rows)
			var pip := minf(STACK_PIP_MAX, (width - (per_row - 1)) / per_row)
			var lit: Color = Palette.GOLD if _hud_full[i] else color
			for k in shown_cap:
				var row := floori(float(k) / per_row)
				var in_row := mini(per_row, shown_cap - row * per_row)
				var x := centre.x - (in_row * pip + (in_row - 1)) / 2.0
				var y := centre.y - r - pip - 2.0 - row * (pip + 1.0)
				var at := Rect2(x + (k - row * per_row) * (pip + 1.0), y, pip, pip)
				atlas.draw_rect_region(item, at.grow(1.0), dot, Color(Palette.VOID, 0.8))
				atlas.draw_rect_region(item, at, dot, lit if k < shown_stacks else Color(color, 0.25))
			# The slash before the first pip at the Reaction's need (pip k lights at (k + 1) / shown_cap of the cap)
			var need := Reactions.ready_need(id, statuses)
			# A Reaction that needs it full: the slash after the last pip (owner 2026-10-19), as `first` = one past the end
			var first := shown_cap if need >= cap else ceili(float(need) * shown_cap / cap) - 1
			if need > 0 and first > 0:
				var row := floori(float(mini(first, shown_cap - 1)) / per_row)  # (Past the end: the last pip's row)
				var in_row := mini(per_row, shown_cap - row * per_row)
				var x := centre.x - (in_row * pip + (in_row - 1)) / 2.0 + (first - row * per_row) * (pip + 1.0) - 0.5
				var y := centre.y - r - pip - 2.0 - row * (pip + 1.0)
				_draw_threshold_slash(item, Vector2(x - 1.5, y + pip + 1.5), Vector2(x + 1.5, y - 1.5))
		if id == EnemyStatuses.ASLEEP:
			_draw_asleep_mark(item, centre, r, color, i)  # A draining ring instead of the time bar
		else:
			var bar := Rect2(centre + Vector2(-r * 0.8, r + 1.5), Vector2(r * 1.6, TIME_BAR_HEIGHT))
			# A card keeps it from running down: the bar's rim in Dew-light ("lasts longer", spec C3), else dark
			var kept := _is_kept(id)  # A Dewdrop Support row keeps it from running down: the bar in Dew-light
			atlas.draw_rect_region(item, bar.grow(1.0), solid, LINGER_RIM_COLOR if statuses.is_lingering(id) or kept else Color(Palette.VOID, 0.75))
			var steps := _time_steps(i)
			if steps > 0:
				bar.size.x *= float(steps) / NightmareOverlay.TIME_STEPS
				atlas.draw_rect_region(item, bar, solid, Palette.DEWLIGHT if kept else color)
		if i < _hud_primed.size() and _hud_primed[i]:  # Reaction-ready: corner brackets on their own pulsing item
			_draw_ready_brackets(centre, r)
			ready_any = true
		if _hud_icons[i] == null:
			RenderingServer.canvas_item_add_circle(item, centre, STATUS_DOT_RADIUS, color)
		if _status_flash.has(id):
			var f: float = _status_flash[id] / STATUS_FLASH_TIME  # 1 -> 0
			RenderingServer.canvas_item_add_circle(item, centre, r + 2.0 + 4.0 * (1.0 - f), Color(color, 0.5 * f))
			RenderingServer.canvas_item_add_circle(item, centre, r, Color(1, 1, 1, 0.45 * f))
	_hud_ready_on = ready_any
	for k in range(_hud_ready_used, _hud_ready_items.size()):
		RenderingServer.canvas_item_clear(_hud_ready_items[k])  # Badges no longer ready

# Reaction-ready (screens_ui.md "Status row: Reaction-ready marks", owner 2026-10-18): four small corner brackets just
# outside the icon, Dew-light on a dark outline: a shape, so it never relies on colour alone. Each ready badge has its own
# item under _hud_ready (its origin on the icon's centre), so the breath (_breathe_ready) is a modulate and a scale only.
func _draw_ready_brackets(centre: Vector2, r: float) -> void:
	if not _hud_ready.is_valid():
		return
	if _hud_ready_used >= _hud_ready_items.size():
		var made := RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(made, _hud_ready)
		_hud_ready_items.append(made)
		_hud_ready_at.append(Vector2.ZERO)
	var item := _hud_ready_items[_hud_ready_used]
	_hud_ready_at[_hud_ready_used] = centre
	_hud_ready_used += 1
	RenderingServer.canvas_item_clear(item)
	RenderingServer.canvas_item_set_transform(item, Transform2D(0.0, Vector2.ONE * _pulse_scale, 0.0, centre))
	var e := r + 2.5  # Just outside the icon
	var leg := maxf(2.5, r * 0.35)
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var at: Vector2 = corner * e
		var bracket := PackedVector2Array([at - Vector2(0, corner.y * leg), at, at - Vector2(corner.x * leg, 0)])
		RenderingServer.canvas_item_add_polyline(item, bracket, PackedColorArray([Color(Palette.VOID, 0.85)]), 3.5)
		RenderingServer.canvas_item_add_polyline(item, bracket, PackedColorArray([READY_COLOR]), 1.5)

# One frame of the brackets' breath (from _process, only while a badge is ready and on screen): the shared alpha on
# _hud_ready and the shared scale on each ready badge's item.
func _breathe_ready() -> void:
	RenderingServer.canvas_item_set_modulate(_hud_ready, _ready_pulse())
	for k in _hud_ready_used:
		RenderingServer.canvas_item_set_transform(_hud_ready_items[k], Transform2D(0.0, Vector2.ONE * _pulse_scale, 0.0, _hud_ready_at[k]))

# The brackets' breath, worked out once a frame for every nightmare: alpha 0.65 .. 1 and scale 1 .. 1 + READY_GROW over
# READY_PULSE_TIME; steady (and full size) under reduced motion.
static func _ready_pulse() -> Color:
	var frame := Engine.get_process_frames()
	if frame != _pulse_frame:
		_pulse_frame = frame
		var still := bool(Fx.setting("reduced_motion", false))
		var breath := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * TAU / READY_PULSE_TIME)
		_pulse = Color(1, 1, 1, 1.0 if still else 0.65 + 0.35 * breath)  # multiplier
		_pulse_scale = 1.0 if still else 1.0 + READY_GROW * breath
	return _pulse
static var _pulse_frame := -1
static var _pulse := Color.WHITE  # multiplier
static var _pulse_scale := 1.0

# Where a Reaction starts to count, on a stack bar or pip row (owner 2026-10-18): a short Heartlight slash from `a` to
# `b` with a dark outline, readable at phone size.
func _draw_threshold_slash(item: RID, a: Vector2, b: Vector2) -> void:
	var line := PackedVector2Array([a, b])
	RenderingServer.canvas_item_add_polyline(item, line, PackedColorArray([Color(Palette.VOID, 0.9)]), 3.0)
	RenderingServer.canvas_item_add_polyline(item, line, PackedColorArray([THRESHOLD_COLOR]), 1.5)

# The Asleep badge's marks: a ring round the icon that drains with the sleep left (in the time bars' steps), and while
# the sheet has no Asleep icon (Sleep's stands in) a small "z" at its top right.
func _draw_asleep_mark(item: RID, centre: Vector2, r: float, color: Color, i: int) -> void:
	var share := float(_time_steps(i)) / NightmareOverlay.TIME_STEPS
	var radius := r + 2.5
	var full := PackedVector2Array()
	for k in 25:
		full.append(centre + Vector2.from_angle(-PI / 2.0 + TAU * k / 24.0) * radius)
	RenderingServer.canvas_item_add_polyline(item, full, PackedColorArray([Color(Palette.VOID, 0.75)]), 3.0)
	var points := int(ceil(24.0 * share))
	if points > 0:
		RenderingServer.canvas_item_add_polyline(item, full.slice(0, points + 1), PackedColorArray([color]), 1.5)
	if _status_icon(EnemyStatuses.ASLEEP) == null:
		var at := centre + Vector2(r - 1.0, -r + 1.0)
		var z := PackedVector2Array([at + Vector2(-2, -2), at + Vector2(2, -2), at + Vector2(-2, 2), at + Vector2(2, 2)])
		RenderingServer.canvas_item_add_polyline(item, z, PackedColorArray([Color(Palette.VOID, 0.8)]), 3.0)
		RenderingServer.canvas_item_add_polyline(item, z, PackedColorArray([Palette.MOONLIGHT]), 1.0)

# The bare pixel-art status icons, at the badge size (drawn nearest-neighbour: the icons' own look);
# an icon that just gained a stack pops (bigger, easing back over STACK_POP_TIME).
func _build_hud_icons(item: RID) -> void:
	RenderingServer.canvas_item_clear(item)
	for i in _hud_ids.size():
		var icon: Texture2D = _hud_icons[i]
		if icon == null:
			continue
		var s := get_badge_size()
		var dream: bool = _dream_pops.has(_hud_ids[i])
		if _hud_pops.has(_hud_ids[i]):
			var t: float = clampf(1.0 - _hud_pops[_hud_ids[i]] / (DREAM_POP_TIME if dream else STACK_POP_TIME), 0.0, 1.0)  # 0 -> 1
			s *= 1.0 + (DREAM_POP_SCALE if dream else STACK_POP_SCALE) * sin(PI * t)
		if dream:  # A Dream card changed it: a 1 px Heartlight rim for the bump
			var rim := Rect2(_badge_centre(i) - Vector2(s, s) / 2.0, Vector2(s, s)).grow(1.0)
			RenderingServer.canvas_item_add_polyline(item, PackedVector2Array([rim.position, Vector2(rim.end.x, rim.position.y),
				rim.end, Vector2(rim.position.x, rim.end.y), rim.position]), PackedColorArray([DREAM_RIM_COLOR]), 1.0)
		# Exposed does nothing until it is full: its badge is dim while partial, bright once it completes
		# (screens_ui.md "Exposed at full stacks is visible"; Tower Code).
		var dim: bool = _hud_ids[i] == EnemyStatuses.MARKED and not statuses.is_exposed()
		icon.draw_rect(item, Rect2(_badge_centre(i) - Vector2(s, s) / 2.0, Vector2(s, s)), false,
			Color(1, 1, 1, 0.5) if dim else Color.WHITE)  # multiplier

# The dark pill behind each stack count (lower right of the icon, from 2 stacks).
func _build_hud_pills(item: RID, overlay: NightmareOverlay) -> void:
	RenderingServer.canvas_item_clear(item)
	var atlas: Texture2D = overlay.badge_atlas
	var pill := overlay.badge_region(NightmareOverlay.MARK_PILL)
	for i in _hud_ids.size():
		if _hud_stacks[i] > 1 or _hud_caps[i] > STACK_PIP_CAP:
			atlas.draw_rect_region(item, _stack_pill(i), pill, Color(Palette.VOID, 0.9))

# Stack counts (bold, on their pills, from 2 stacks; gold at max) and "+N" past the last icon.
func _build_hud_text(item: RID) -> void:
	RenderingServer.canvas_item_clear(item)
	var r := get_badge_size() / 2.0
	for i in _hud_ids.size():
		if _hud_stacks[i] > 1 or _hud_caps[i] > STACK_PIP_CAP:
			var text := str(_hud_stacks[i])
			var font_size := _stack_count_font_size(_hud_stacks[i])
			var box := _stack_pill(i)
			var width := _stack_font_face().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var baseline := Vector2(box.get_center().x - width / 2.0, box.get_center().y + font_size * 0.35)
			_add_stack_text(item, baseline, text, Palette.GOLD if _hud_full[i] else Palette.MOONLIGHT, font_size)
	if _hud_badge_widths.is_empty() or _hud_ids.is_empty():
		return  # No badge laid out (cleared this frame): nothing to put "+N" after
	var extra := _hud_total - _hud_ids.size()
	var after := _badge_centre(mini(_hud_ids.size(), _hud_badge_widths.size()) - 1) + Vector2(r + 2.0 + STATUS_BADGE_GAP, STACK_FONT_SIZE * 0.35)
	if extra > 0:
		_add_stack_text(item, after, "+%d" % extra, Palette.MOONLIGHT)
		after.x += _stack_font_face().get_string_size("+%d" % extra, HORIZONTAL_ALIGNMENT_LEFT, -1, STACK_FONT_SIZE).x + 4.0
	if _hud_season > 0 and not _hud_ids.is_empty():  # Spore Season: "+25%" on its Poisoned, in spore green
		_add_stack_text(item, after, "+%d%%" % _hud_season, SEASON_TAG_COLOR)

# Icon i's stack-count pill: on the lower-right corner, with row space for its exact number.
func _stack_pill(i: int) -> Rect2:
	var r := get_badge_size() / 2.0
	var font_size := _stack_count_font_size(_hud_stacks[i])
	var width := _stack_font_face().get_string_size(str(_hud_stacks[i]), HORIZONTAL_ALIGNMENT_LEFT, -1,
		font_size).x + 8.0
	var height := font_size + 2.0
	var size := Vector2(maxf(width, height), height)
	var centre := _badge_centre(i)
	return Rect2(centre + Vector2(r + 2.0, r + 1.0) - size, size)

# The stack-count font: NightmareOverlay's (an instance's, freed with the run: a Font kept in a static
# is freed after the TextServer at exit and crashes).
func _stack_font_face() -> Font:
	return _spawner.overlay.stack_font

func _stack_count_font_size(count: int) -> int:
	return STACK_FONT_SIZE_BIG_COUNT if count >= 100 else STACK_FONT_SIZE

func _add_stack_text(item: RID, at: Vector2, text: String, color: Color, font_size: int = STACK_FONT_SIZE) -> void:
	var font := _stack_font_face()
	font.draw_string_outline(item, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 2 if font_size < STACK_FONT_SIZE else 3, Palette.VOID)
	font.draw_string(item, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _end_smother_fx() -> void:
	if has_meta(&"smother_fx") and not statuses.smothering:
		var smother = get_meta(&"smother_fx")
		if is_instance_valid(smother):
			smother.queue_free()
		remove_meta(&"smother_fx")

# Whether `node` is inside the camera's view (plus a margin), with the view worked out once a frame
# for every nightmare. No camera, or headless: always on screen.
static func _on_screen(node: Node2D) -> bool:
	var frame := Engine.get_process_frames()
	if frame != _view_frame:
		_view_frame = frame
		_view_rect = Rect2()
		var camera := node.get_viewport().get_camera_2d()
		# Headless has a 64 px stand-in window: no culling there (tests and perf runs see every redraw)
		if camera != null and camera.zoom.x > 0.0 and DisplayServer.get_name() != "headless":
			var size := node.get_viewport().get_visible_rect().size / camera.zoom
			_view_rect = Rect2(camera.get_screen_center_position() - size / 2.0, size).grow(VIEW_MARGIN)
	if test_view_rect.has_area():
		return test_view_rect.has_point(node.global_position)
	return not _view_rect.has_area() or _view_rect.has_point(node.global_position)
static var _view_frame := -1
static var _view_rect := Rect2()
static var test_view_rect := Rect2()  # Tests: stands in for the camera's view (headless has none)

# The statuses its badges show, most important first (BADGE_ORDER), at most STATUS_BADGES_MAX; the
# rest only count towards the "+N".
func get_badge_ids() -> Array:
	return _pick_badges(get_status_order())

# Lines for the nightmare info panel about the limits on slow and sleep (tower_design.md "Slow and
# sleep have limits"), under its statuses.
func get_status_notes() -> Array[String]:
	var notes: Array[String] = []
	if statuses.slow_capped:
		notes.append("Slowed to the limit")
	if statuses.sleep_cooldown > 0.0:
		notes.append("Awake: can't fall asleep again for %.1f s" % statuses.sleep_cooldown)
	return notes

# Every status it carries, most important first (the info panel lists them in this order).
func get_status_order() -> Array:
	var ids := statuses.active_ids()
	if statuses.silence_time > 0.0:
		ids.append(EnemyStatuses.SILENCED)  # Hushbell's silence (not one of _active's): a badge all the same
	if _asleep_badge:  # Asleep takes Sleep's place once its flash has played (_update_sleep)
		ids.erase(EnemyStatuses.DROWSY)
		ids.append(EnemyStatuses.ASLEEP)
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return _badge_rank(a) < _badge_rank(b))
	return ids

static func _badge_rank(id: StringName) -> int:
	var rank := BADGE_ORDER.find(id)
	return rank if rank >= 0 else BADGE_ORDER.size()

# Calling evolution cues (Roguelite Code's rebuild, 2026-10-23), both inert until its API is in (has_method):
# a status a Dewdrop Support row keeps from running down (EnemyStatuses.is_kept) fills its time bar in Dew-light, and
# Spore Season's bonus on this nightmare's Poisoned (spore_print.season_bonus) shows as "+N%" at the badge row's end.
const SEASON_TAG_COLOR := Palette.SPRIG
var _hud_season := 0  # The "+N%" drawn now (a whole percent; 0 = none)

func _is_kept(id: StringName) -> bool:
	return statuses.has_method(&"is_kept") and statuses.is_kept(id)

func _season_percent() -> int:
	if _batch_dreams == null and is_inside_tree():
		_batch_dreams = get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	var spores: Node = _batch_dreams.spore_print if _batch_dreams != null else null
	if spores == null or not spores.has_method(&"season_bonus") or statuses.stacks(EnemyStatuses.SPORED) <= 0:
		return 0
	return roundi(float(spores.season_bonus(self)) * 100.0)

func get_badge_size() -> float:
	return STATUS_BADGE_BIG if enemy_data.is_boss or elite else STATUS_BADGE

# Deeply Blighted: hard-edged smoke puffs drifting slowly round the nightmare, a few cold motes in it,
# and a swirl left of the health bar.
func _draw_elite_haze() -> void:
	var r := 18.0 * sprite.scale.x
	for i in ELITE_HAZE_PUFFS:
		var a := _haze_phase + TAU * i / ELITE_HAZE_PUFFS
		var at := Vector2(cos(a) * r, sin(a) * r * 0.5 - 8.0).round()  # Flattened ring round the body
		var size := (9.0 + 3.0 * sin(_haze_phase * 1.7 + i)) * sprite.scale.x
		for band: float in ELITE_HAZE_BANDS:
			_body_fx.draw_circle(at, roundf(size * band), ELITE_HAZE_COLOR, true, -1.0, false)
	for i in ELITE_MOTES:
		var a := -_haze_phase * 1.3 + TAU * i / ELITE_MOTES
		var at := Vector2(cos(a) * r * 0.8, sin(a) * r * 0.4 - 10.0).round()
		var twinkle := 0.5 + 0.5 * sin(_haze_phase * 4.0 + i * 2.1)
		_body_fx.draw_rect(Rect2(at, Vector2(2, 2)), Color(ELITE_MOTE_COLOR, 0.35 + 0.5 * twinkle))
	var centre := _bar_offset + Vector2(-HEALTH_BAR_SIZE.x / 2 - 8.0, 0)
	var mark := _status_icon(&"elite")
	if mark != null:  # The sheet's Deeply Blighted icon; the drawn swirl otherwise
		_body_fx.draw_texture(mark, (centre - mark.get_size() / 2.0).round())
		return
	var swirl := PackedVector2Array()
	for s in 14:
		var t := s / 13.0
		swirl.append(centre + Vector2.from_angle(t * TAU * 1.6 + _haze_phase) * (1.0 + 4.0 * t))
	_body_fx.draw_circle(centre, 6.0, Color(Palette.VOID, 0.8))
	_body_fx.draw_polyline(swirl, ELITE_SWIRL_COLOR, 1.5)

# A small grey puff for a resisted hit, a little sparkle for a weak one. `t` fades 1 -> 0.
func _draw_hit_mark(t: float) -> void:
	var at := Vector2(10, -20)
	if _hit_mark < 0:
		for i in 3:
			var puff := at + Vector2.from_angle(TAU * i / 3.0) * 4.0 * (1.6 - t)
			_body_fx.draw_circle(puff, 3.5 * t + 1.0, Color(Palette.DEWLIGHT if _hit_mark_wash else Palette.MIST, 0.7 * t))
	else:
		var r := 7.0 * (1.4 - t)
		var col := Color(Palette.GLOW, t)  # A Warden's hit: warm light
		_body_fx.draw_line(at + Vector2(-r, 0), at + Vector2(r, 0), col, 2.0)
		_body_fx.draw_line(at + Vector2(0, -r), at + Vector2(0, r), col, 2.0)

# Its sheet's everyday row: walk_side, or "fly" for flyers drawn with a fly row only (Night Kite, Pall; Enemy Assets
# d8b0631a). Bounds and the bar height read its frame 0.
func _base_animation() -> StringName:
	var frames := sprite.sprite_frames
	if frames != null and frames.has_animation(&"fly") and (not frames.has_animation(&"walk_side") \
			or (enemy_data != null and enemy_data.trait_kind == EnemyData.Trait.FLYING and not dropped)):
		return &"fly"  # (The Gloamwing has both: it flies until it drops)
	return &"walk_side"

func update_animation(velocity: Vector2) -> void:
	# Keep the current animation when not moving (e.g. end of path) or while a pose plays
	if velocity.is_zero_approx() or _pose_left > 0.0:
		return
	var animation := &"walk_up"
	var flip := false
	if is_flying() and sprite.sprite_frames.has_animation(&"fly"):
		# Route flyers with a fly row (one row faces every way: right, flipped to fly left); a settled Pall drapes
		animation = &"settled" if _settled and sprite.sprite_frames.has_animation(&"settled") else &"fly"
		flip = velocity.x < 0 if absf(velocity.x) > 0.01 else sprite.flip_h
	elif rolling and sprite.sprite_frames.has_animation(&"roll"):
		animation = &"roll"
		flip = velocity.x < 0
	elif _charge_left > 0.0 and sprite.sprite_frames.has_animation(&"gallop"):
		animation = &"gallop"  # Night Mare's Bolt
		flip = velocity.x < 0
	elif sorrowing and sprite.sprite_frames.has_animation(&"sorrow"):
		animation = &"sorrow"  # Mourning Mother mending: hands to her face, black tears
		flip = velocity.x < 0
	elif abs(velocity.x) >= abs(velocity.y):  # Moving horizontally
		animation = &"walk_side"
		flip = velocity.x < 0  # Flip horizontally if moving left
	elif velocity.y > 0:  # Moving down
		animation = &"walk_down"
	if sprite.animation != animation or not sprite.is_playing():
		sprite.play(animation)  # Only when it changes: this runs every frame for every nightmare
	if flip != sprite.flip_h:
		sprite.flip_h = flip

# Dew for dispelling this nightmare (Omens can change it, e.g. Dry Spell = 0): its Dew pot share when
# it has one (a leak pays nothing: only a dispel pays), else the old per-kind dew_reward.
func get_dew_reward() -> int:
	return roundi(get_dew_share())

# The same, before rounding (the pot's shares are fractions; RunState can carry the remainder).
func get_dew_share() -> float:
	if dew_share == 0.0:
		return 0.0  # A summon (or a summon's split): nothing, not even card bonuses (they'd be farmable)
	if dew_share > 0.0:
		return dew_share * modifiers.get("dew", 1.0) + bonus_dew
	return roundi(enemy_data.dew_reward * modifiers.get("dew", 1.0)) * (ELITE_DEW if elite else 1) + bonus_dew

# The DriftDirector's pot share for this nightmare. A leader with followers keeps half and its
# followers share the other half (FOLLOWER_DEW_SHARE).
func set_dew_share(share: float) -> void:
	var followers := dew_followers.filter(func(f) -> bool: return is_instance_valid(f) and not f.is_cleansed)
	if followers.is_empty():
		dew_share = share
		return
	dew_share = share * (1.0 - FOLLOWER_DEW_SHARE)
	for follower in followers:
		follower.dew_share = share * FOLLOWER_DEW_SHARE / followers.size()

# Leaves lost when this nightmare reaches the Heartwood (Deeply Blighted cost at least 2).
func get_leaf_cost() -> int:
	if enemy_data.is_boss and not is_echo and not enemy_data.stays_at_heartwood and not enemy_data.laps() \
			and _spawner != null:
		return _spawner.get_boss_bite(_spawner.act_of(self))  # An act boss's flat bite (8 / 10 / 12)
	return maxi(enemy_data.leaf_cost, ELITE_LEAVES) if elite else enemy_data.leaf_cost

# Half cells (half_cells.md): in a gap one half cell wide a nightmare is drawn SQUEEZE_WIDTH wide, eased in
# and out, so it reads as slipping through rather than clipping into stone. Bosses too. Read from the half
# cells beside its position (and a little ahead), so it doesn't depend on how route points are encoded.
# Not for flyers, or while sinking, rising or dropping (their tweens own the scale and keep the factor).
func _update_squeeze(delta: float) -> void:
	if _leaping:
		return
	# Looked at once a route step, or when the map's blocking changes (perf: not every frame)
	if _gap_step != _path_index or (_gap_finder != null and _gap_finder.version != _gap_version):
		_gap_answer = _in_narrow_gap() and not is_flying()
	var target := SQUEEZE_WIDTH if _gap_answer else 1.0
	if target == _squeeze:
		return  # Nearly always: nothing to ease
	var next := target
	if not bool(Fx.setting("reduced_motion", false)):
		next = lerpf(_squeeze, target, 1.0 - exp(-SQUEEZE_RATE * delta))
		if absf(next - target) < 0.005:
			next = target
	if next == _squeeze:
		return
	sprite.scale.x = sprite.scale.x / _squeeze * next
	_squeeze = next
	_apply_sprite_offset()  # The rounded-corner offset and foot lift stay in world pixels

# Whether the walker is in (or about to enter) a one-half gap: its half cell open, both halves beside it
# across its walking direction blocked.
func _in_narrow_gap() -> bool:
	_gap_step = _path_index  # (Asked again at the next route step, or when the blocking changes)
	if _path_index < 1 or _path_index >= _path.size():
		return false
	var step := _path[_path_index] - _path[_path_index - 1]
	var dir := Vector2(signf(step.x), signf(step.y))
	if dir == Vector2.ZERO:
		return false
	# The halves it walks between: the point it left and the one it's heading to (the body's half and the
	# one just ahead, whatever the route's encoding)
	var half := grid.cell_size.x / FindPath.HALF
	var here := Vector2i(((grid.calculate_map_position(_path[_path_index - 1])) / half).floor())
	var ahead := Vector2i(((grid.calculate_map_position(_path[_path_index])) / half).floor())
	if _gap_finder == null:
		var map_generator = _map_generator()
		if map_generator == null:
			return false
		_gap_finder = map_generator.path_layer.get_finder()
	_gap_here = here
	_gap_ahead = ahead
	_gap_version = _gap_finder.version
	var side := Vector2(absf(dir.y), absf(dir.x))
	_gap_answer = false
	for h: Vector2 in [Vector2(here), Vector2(ahead)]:
		if not _gap_finder.is_half_blocked(h) and _gap_finder.is_half_blocked(h + side) and _gap_finder.is_half_blocked(h - side):
			_gap_answer = true
			break
	return _gap_answer

# Whether the route turns at the point it's walking to or the one it just left (the only places a rounded
# corner can bend the drawn path). Built once per route.
func _near_turn() -> bool:
	if _turns_serial != _path_serial or _turns.size() != _path.size():
		_turns_serial = _path_serial
		_turns.resize(_path.size())
		_turns.fill(0)
		for i in range(1, _path.size() - 1):
			if _path[i] - _path[i - 1] != _path[i + 1] - _path[i]:
				_turns[i] = 1
	var i := _path_index
	return (i < _turns.size() and _turns[i] == 1) or (i >= 1 and i - 1 < _turns.size() and _turns[i - 1] == 1)

# The pixel of route point `index` (cached for the point it's walking to).
func _point_px(index: int) -> Vector2:
	if index != _target_index or _target_serial != _path_serial:
		_target_index = index
		_target_serial = _path_serial
		_target_px = grid.calculate_map_position(_path[index])
	return _target_px

# A hit landed: flash and recoil. `share` = the hit's damage / its max health; `from` = where it came from in
# global pixels (NO_SOURCE: it recoils back along its path). No allocations; _update_flinch plays it out.
func flinch(share: float, from: Vector2 = NO_SOURCE, recoil_px: float = 0.0, flash: float = -1.0) -> void:
	if _culled or is_cleansed:
		return
	var strength := clampf(share / RECOIL_FULL_SHARE, 0.0, 1.0)
	var scale_by := BOSS_FLINCH if enemy_data.is_boss else 1.0
	var recoil := (recoil_px if recoil_px > 0.0 else lerpf(RECOIL_MIN, RECOIL_MAX, strength)) * scale_by  # (A big hit's own)
	# A weaker hit while a stronger flinch is still playing changes nothing you'd see (perf: a crowded field lands dozens of
	# hits a frame; each restart set the shader parameter and the sprite offset)
	if _flinch_left > 0.0 and _recoil.length_squared() >= recoil * recoil:
		return
	var away := Vector2.ZERO
	if from != NO_SOURCE:
		away = global_position - from
	if away.length_squared() < 1.0 and _path_index < _path.size():
		away = position - _point_px(_path_index)  # Back along its path
	if away.length_squared() < 1.0:
		away = Vector2.UP
	_flinch_recoil = away.normalized() * recoil
	_flinch_flash = 0.0 if Fx.reduce_flashes() else (flash if flash >= 0.0 else lerpf(FLASH_MIN, FLASH_MAX, strength)) * scale_by
	_flinch_left = FLINCH_TIME
	_update_flinch(0.0)

# The tier of one damage event of `share` of its max health (0 = below Heavy): BIG_HIT_SHARES, or the boss ones.
static func big_hit_tier_of(share: float, is_boss: bool) -> int:
	var shares: Array[float] = BIG_HIT_BOSS_SHARES if is_boss else BIG_HIT_SHARES
	var tier := 0
	while tier < shares.size() and share >= shares[tier]:
		tier += 1
	return tier

# The big-hit tier this damage event sets off (0 = none, or the setting is Off): hits from one source within
# BIG_HIT_MERGE_MS add up to one blow; while a tier plays (BIG_HIT_AGAIN_MS) only a higher one cuts in; T2 / T3 over the
# field's caps step down. Hits and bolts only (Reactions, ticks and sustained sources show themselves).
func _big_hit_tier(soothe: float, source: Node, tag: StringName) -> int:
	if not is_instance_valid(source) or tag in SUSTAINED_TAGS or tag in REACTION_TAGS or tag == &"harmony" \
			or tag == &"popped" or int(Fx.setting("big_hits", 0)) == 2:
		return 0
	var now := Time.get_ticks_msec()
	var id := source.get_instance_id()
	if id == _bh_source and now - _bh_at <= BIG_HIT_MERGE_MS:
		_bh_sum += soothe
	else:
		_bh_source = id
		_bh_sum = soothe
	_bh_at = now
	var tier := big_hit_tier_of(_bh_sum / maxf(max_health, 1.0), enemy_data.is_boss)
	if tier == 0 or (now < _bh_until and tier <= _bh_tier):
		return 0
	while tier >= 2 and not _big_hit_room(tier, now):
		tier -= 1  # The field is busy with big blows: a smaller one
	if now < _bh_until and tier <= _bh_tier:
		return 0
	if tier >= 2:
		_bh_times[tier - 2].append(now)
	_bh_tier = tier
	_bh_until = now + BIG_HIT_AGAIN_MS
	return tier

static func _big_hit_room(tier: int, now: int) -> bool:
	var times: Array = _bh_times[tier - 2]
	while not times.is_empty() and now - int(times[0]) > 1000:
		times.pop_front()
	return times.size() < (BIG_HIT_CAPS_REDUCED if Fx.reduced() else BIG_HIT_CAPS)[tier - 2]

# Plays big-hit tier `tier` (visual_feedback_spec.md A). `dying`: the blow dispels it (no stagger or hold, the dispel
# crack plays; the chips still fly). Reduce flashes: no flash, a soft Moonlight crack, no ring. Reduced motion: the
# flinch's own recoil, no stagger, hold or nudge. Reduced effects: T1 nothing here, T2 the crack, T3 + the ring.
# Subtle (big_hits 1): T1 at every tier. Off screen: only the crack (no nodes).
func _play_big_hit(tier: int, share: float, from: Vector2, is_crit: bool, dying: bool) -> void:
	var shown := 1 if int(Fx.setting("big_hits", 0)) == 1 else tier
	var still := bool(Fx.setting("reduced_motion", false))
	var soft := Fx.reduce_flashes()
	var lite := Fx.reduced()
	big_hit.emit(self, tier, share)
	if lite and shown == 1:
		if not dying:
			flinch(share, from)  # The everyday flinch; the number is the rest (Main Merger's)
		return
	if not dying:
		flinch(share, from, 0.0 if still else BIG_HIT_RECOIL[shown - 1], BIG_HIT_FLASH)
	_crack_hit = BIG_HIT_CRACK[shown - 1]
	_crack_hit_time = BIG_HIT_CRACK_TIME[shown - 1]
	_crack_hit_left = _crack_hit_time
	sprite.set_instance_shader_parameter(&"hit_crack_soft", 1.0 if soft else 0.0)
	sprite.set_instance_shader_parameter(&"hit_crack", _crack_hit)
	if not dying and not still and not lite and not _leaping and shown >= 2:
		_stagger_left = BIG_HIT_SQUASH_TIME
		if shown >= 3:
			_freeze_left = BIG_HIT_FREEZE
			sprite.speed_scale = 0.0  # Its own walk frames hold; restored by _update_big_hit
	if _culled or not Fx.on_screen(global_position):
		return  # Off screen: the crack only
	var world := Reactions._world(self)
	if world == null or shown < 2:
		return
	# Chips: not on a crit (its star flare plays) or an Exposed blow (its spark plays), nor at Reduced effects
	if not lite and not is_crit and not statuses.is_exposed() and Fx.has_effect(BIG_HIT_CHIPS):
		var size := (1.4 if shown >= 3 else 1.0) * (1.25 if TouchBuild.mobile_controls() else 1.0)
		Fx.play(BIG_HIT_CHIPS, Tower.aim_at(self), world, size)
	if shown >= 3:
		if not soft:
			var ring := Fx.FxRing.new(Palette.GLOW, 14.0, 20.0, BIG_HIT_RING_TIME)
			world.add_child(ring)
			ring.global_position = global_position
		if not still and Fx.bright_flash_ok():
			Fx.add_trauma(BIG_HIT_NUDGE, world)

# The big hit playing out, in real seconds (game speed doesn't shorten it): the hairline crack fading, the squash
# easing back, the held frames walking on. Called only while one of them runs.
func _update_big_hit(real_delta: float) -> void:
	if _crack_hit_left > 0.0:
		_crack_hit_left = maxf(_crack_hit_left - real_delta, 0.0)
		sprite.set_instance_shader_parameter(&"hit_crack", _crack_hit * _crack_hit_left / _crack_hit_time)
	if _freeze_left > 0.0:
		_freeze_left = maxf(_freeze_left - real_delta, 0.0)
		if _freeze_left <= 0.0:
			sprite.speed_scale = 1.0
	if _stagger_left > 0.0 or _stagger_scale != Vector2.ONE:
		_stagger_left = maxf(_stagger_left - real_delta, 0.0)
		var t := _stagger_left / BIG_HIT_SQUASH_TIME  # 1 -> 0
		var squash := Vector2.ONE.lerp(BIG_HIT_SQUASH, t * t) if not _leaping else Vector2.ONE  # (A leap's tween owns the scale)
		sprite.scale = sprite.scale / _stagger_scale * squash
		_stagger_scale = squash
		_apply_sprite_offset()

# Plays the flinch out (real seconds: game speed doesn't shorten it), plus the arc twitch; back at rest it
# leaves the sprite's offset and the shader's flash exactly where they were.
func _update_flinch(real_delta: float) -> void:
	_flinch_left = maxf(_flinch_left - real_delta, 0.0)
	var t := _flinch_left / FLINCH_TIME  # 1 -> 0
	_recoil = _flinch_recoil * t
	if _sustained.has(ARC_TAG):  # Wrapped in arcs: a small jitter for as long as they hold it
		var now := Time.get_ticks_msec() * 0.001
		_recoil += Vector2(sin(now * 83.0), cos(now * 61.0)) * ARC_TWITCH
	var flash := _flinch_flash * clampf((_flinch_left - (FLINCH_TIME - FLASH_TIME)) / FLASH_TIME, 0.0, 1.0)
	if flash != _flash_shown:
		_flash_shown = flash
		sprite.set_instance_shader_parameter(&"hit_flash", flash)
	_apply_sprite_offset()

# Continuous damage (arcs, beams, clouds, Poisoned ticks): no flinch per tick. `tag`'s source holds the state
# (on = true until it clears it), and every tick of a SUSTAINED_TAGS source refreshes it for SUSTAIN_HOLD s
# by itself. Wardens' overlays read is_sustained(tag) or listen to sustained_changed.
func set_sustained(tag: StringName, on: bool) -> void:
	if on:
		var was := _sustained.has(tag)
		_sustained[tag] = INF
		if not was:
			sustained_changed.emit(self, tag, true)
	elif _sustained.erase(tag):
		sustained_changed.emit(self, tag, false)

# Whether `tag`'s continuous source is on it now (no tag: any of them).
func is_sustained(tag: StringName = &"") -> bool:
	return not _sustained.is_empty() if tag == &"" else _sustained.has(tag)

func _note_sustained_tick(tag: StringName) -> void:
	if not _sustained.has(tag):
		_sustained[tag] = SUSTAIN_HOLD
		sustained_changed.emit(self, tag, true)
	elif _sustained[tag] < SUSTAIN_HOLD:
		_sustained[tag] = SUSTAIN_HOLD

# The tick-refreshed sustained states run out SUSTAIN_HOLD s after their last tick (held ones stay).
func _update_sustained(delta: float) -> void:
	var ended := &""  # (No key list made: one ends a frame at most, the next the frame after)
	for tag: StringName in _sustained:
		var left: float = _sustained[tag]
		if left == INF:
			continue
		_sustained[tag] = left - delta
		if left - delta <= 0.0:
			ended = tag
	if ended != &"":
		_sustained.erase(ended)
		sustained_changed.emit(self, ended, false)

# Where the nightmare is drawn (its lane, rounded corner and foot lift included): aim visuals here; game logic keeps
# global_position. Same as get_body_position (Tower Code's aim, walking lanes 2026-10-24).
func get_visual_position() -> Vector2:
	return get_body_position()

# This nightmare's lane width in cells (either side of the centre line).
func get_lane_width() -> float:
	if lane_width >= 0.0:
		return minf(lane_width, LANE_BIG) if _is_big_for_lanes() else lane_width
	if is_flying():
		return LANE_FLYER
	return LANE_BIG if _is_big_for_lanes() else LANE_MAX

func _is_big_for_lanes() -> bool:
	return enemy_data.is_boss or enemy_data.sprite_scale >= LANE_BIG_SCALE

# Walking lanes: every LANE_WANDER s a new lane a step from the current one, the move eased in and out and never
# sideways faster than LANE_SLIDE_SHARE of its walk; measured across the rounded corner's curve, narrower near a turn's
# centre, closed in a narrow half-cell gap; it opens over the first cell walked and closes over the last route cell.
# Reduced motion: a fixed lane.
func _update_lane(delta: float) -> void:
	if _spawner != null and not _spawner.walking_lanes:
		return  # Dev flag --no-lanes
	var still: bool = _spawner.reduced_motion_now if _spawner != null else bool(Fx.setting("reduced_motion", false))  # (Once a frame: perf)
	var cell: float = grid.cell_size.x
	if _lane_rng == null:
		_lane_rng = RandomNumberGenerator.new()
		_lane_rng.seed = randi()  # (The global RNG: a capture reseeds it, so its lanes replay)
		lane_target = _lane_rng.randf_range(-1.0, 1.0)
		lane = lane_target
		_lane_from = lane
		_lane_left = _lane_rng.randf_range(LANE_WANDER.x, LANE_WANDER.y)
	if not still:
		_lane_left -= delta
		if _lane_left <= 0.0:
			_lane_left = _lane_rng.randf_range(LANE_WANDER.x, LANE_WANDER.y)
			var step := _lane_rng.randf_range(LANE_STEP.x, LANE_STEP.y) * (1.0 if _lane_rng.randf() < 0.5 else -1.0)
			if absf(lane + step) > 1.0:
				step = -step  # (The other side has room)
			_start_lane_move(clampf(lane + step, -1.0, 1.0))
		if _lane_t < 1.0:
			# Paused while it stands still (held, asleep): the move keeps to its walk
			var walking := clampf(_speed_cache / maxf(speed, 1.0), 0.0, 1.0)
			_lane_t = minf(_lane_t + delta * walking / _lane_move, 1.0)
			lane = lerpf(_lane_from, lane_target, smoothstep(0.0, 1.0, _lane_t))
	# The direction: the drawn route position's motion (the rounded corner's curve), eased
	var drawn := position + _corner_offset
	if _lane_last != Vector2.INF:
		var moved := drawn - _lane_last
		if moved.length_squared() > 0.0025:
			var dir := moved.normalized()
			_lane_dir = dir if _lane_dir == Vector2.ZERO else _lane_dir.lerp(dir, 1.0 - exp(-LANE_TURN_EASE * delta)).normalized()
	elif _path_index < _path.size():
		var ahead := grid.calculate_map_position(_path[_path_index]) - position
		if ahead.length_squared() > 1.0:
			_lane_dir = ahead.normalized()
	_lane_last = drawn
	_lane_gap = lerpf(_lane_gap, 0.0 if _gap_answer else 1.0, 1.0 - exp(-LANE_GAP_EASE * delta))
	_lane_age += delta
	var open := clampf(_lane_age * maxf(speed, 1.0) / cell, 0.0, 1.0)  # Over the first cell
	if _path_index + 4 >= _path.size():  # (Perf: 4+ steps of at least half a cell left are over a cell: the full lane)
		open = minf(open, clampf(get_remaining_distance() / cell, 0.0, 1.0))  # …and closed over the last route cell
	var side := Vector2(-_lane_dir.y, _lane_dir.x)
	# In a one-half gap the lane narrows (eased) to what the gap leaves beside the squeezed body, never into a Warden
	var lane_px := lane * get_lane_width() * cell
	var gap_cap := clampf((cell / FindPath.HALF - LANE_BODY_PX * absf(sprite.scale.x)) / 2.0, 0.0, LANE_GAP_MAX * cell)
	lane_px = lerpf(clampf(lane_px, -gap_cap, gap_cap), lane_px, _lane_gap)
	if not still and not enemy_data.is_boss:
		_update_along(delta)
	var along_px := _along * ALONG_MAX * cell if not enemy_data.is_boss else 0.0
	_lane_offset = ((side * lane_px * _turn_share() + _lane_dir * along_px) * open).round()
	if _lane_offset.distance_squared_to(_lane_drawn) < LANE_SNAP_PX * LANE_SNAP_PX:
		return
	_lane_drawn = _lane_offset
	_apply_sprite_offset()
	if _hud_root.is_valid():
		RenderingServer.canvas_item_set_transform(_hud_root, Transform2D(0.0, _body_offset()))
	if elite or _hit_mark_time > 0.0 or _bolt_flash > 0.0 or unbound:
		queue_redraw()  # The haze and marks drawn in _draw follow the lane

# Along-path drift: a new target every ALONG_WANDER s, eased in and out like the lane and under the same speed cap.
func _update_along(delta: float) -> void:
	_along_left -= delta
	if _along_left <= 0.0:
		_along_left = _lane_rng.randf_range(ALONG_WANDER.x, ALONG_WANDER.y)
		_along_from = _along
		_along_target = _lane_rng.randf_range(-1.0, 1.0)
		_along_t = 0.0
		var px := absf(_along_target - _along) * ALONG_MAX * grid.cell_size.x
		_along_move = maxf(LANE_MOVE_MIN, 1.5 * px / maxf(LANE_SLIDE_SHARE * speed, 1.0))
	if _along_t < 1.0:
		var walking := clampf(_speed_cache / maxf(speed, 1.0), 0.0, 1.0)
		_along_t = minf(_along_t + delta * walking / _along_move, 1.0)
		_along = lerpf(_along_from, _along_target, smoothstep(0.0, 1.0, _along_t))

# A move to lane `to`, from where the lane is now: smoothstep over at least LANE_MOVE_MIN s, long enough that its
# fastest moment (1.5 × the average) stays under LANE_SLIDE_SHARE of its walk speed.
func _start_lane_move(to: float) -> void:
	var cell: float = grid.cell_size.x
	var px := absf(to - lane) * get_lane_width() * cell
	_lane_from = lane
	lane_target = to
	_lane_t = 0.0
	_lane_move = maxf(LANE_MOVE_MIN, 1.5 * px / maxf(LANE_SLIDE_SHARE * speed, 1.0))

# The spawner's jostle: ease the lane `amount` lane units away (never past LANE_JOSTLE_MAX), through the same cap.
func nudge_lane(amount: float) -> void:
	if _lane_rng == null:
		return
	var to := clampf(lane_target + amount, -LANE_JOSTLE_MAX, LANE_JOSTLE_MAX)
	if absf(to - lane_target) > 0.001:
		_start_lane_move(to)

# The lane's share near a turn: LANE_TURN_SHARE at the turn's centre, back to 1 at LANE_TURN_NEAR cells.
func _turn_share() -> float:
	if not _near_turn():
		return 1.0
	var near := INF
	for i in [_path_index - 1, _path_index]:
		if i >= 0 and i < _turns.size() and _turns[i] == 1:
			near = minf(near, position.distance_to(grid.calculate_map_position(_path[i])))
	if near == INF:
		return 1.0
	return lerpf(LANE_TURN_SHARE, 1.0, clampf(near / (LANE_TURN_NEAR * grid.cell_size.x), 0.0, 1.0))

func is_flying() -> bool:
	return enemy_data.trait_kind == EnemyData.Trait.FLYING and _grounded_left <= 0.0 and not dropped  # (Groundroot: not while grounded)

# A route flyer (Crow, Night Kite, Gloamwing, Pall, Moth Queen): it flies the nightmares' route, above it.
func is_route_flyer() -> bool:
	return enemy_data.trait_kind == EnemyData.Trait.FLYING and enemy_data.flies_along_route

# Whether it counts on the route for route cards (Passing Thread, Gauntlet, bends, the Callings' route): walkers and
# route flyers at the route point below them. Ground effects still ask is_flying() (they miss every flyer).
func on_route() -> bool:
	return not is_flying() or enemy_data.flies_along_route

# Rounded corners (user-approved, 2026-10-04): the route stays square and the logical position walks
# it exactly (speed, ETA, progress unchanged); only the drawn sprite and HUD ease through a turn, on a
# quadratic curve from CORNER_ROUNDING cells before the corner's centre to as far after it, with the
# centre as its control point. That curve stays inside the corner cell. Not for flyers, or while
# sinking, rising or being dragged.
func _round_corners() -> void:
	if _corner_offset == Vector2.ZERO and not _near_turn():
		return  # On a straight: nothing to bend (nearly every frame)
	var offset := Vector2.ZERO
	if not is_flying() and not _leaping and not _dragging and _path_index >= 1 and _path_index < _path.size():
		var here := position
		var next_c := grid.calculate_map_position(_path[_path_index])
		var prev_c := grid.calculate_map_position(_path[_path_index - 1])
		# Approaching a turn at the next centre, or just leaving one at the previous centre
		if _path_index + 1 < _path.size():
			offset = _corner_curve(prev_c, next_c, grid.calculate_map_position(_path[_path_index + 1]), here, true)
		if offset == Vector2.ZERO and _path_index >= 2:
			offset = _corner_curve(grid.calculate_map_position(_path[_path_index - 2]), prev_c, next_c, here, false)
	if offset == _corner_offset:
		return
	_corner_offset = offset
	_apply_sprite_offset()
	if _hud_root.is_valid():
		RenderingServer.canvas_item_set_transform(_hud_root, Transform2D(0.0, _body_offset()))

# The drawn offset at `here` for a turn at `corner` (from `before`, towards `after`); zero if the route
# doesn't turn there or `here` is farther than the rounding from it. `approaching`: before the corner.
func _corner_curve(before: Vector2, corner: Vector2, after: Vector2, here: Vector2, approaching: bool) -> Vector2:
	var into := (corner - before)
	var out := (after - corner)
	if into.is_zero_approx() or out.is_zero_approx():
		return Vector2.ZERO
	var d_in := into.normalized()
	var d_out := out.normalized()
	if d_in.is_equal_approx(d_out):
		return Vector2.ZERO  # Straight on
	var r := minf(CORNER_ROUNDING * grid.cell_size.x, 0.5 * minf(into.length(), out.length()))  # (Half-steps too)
	var dist := here.distance_to(corner)
	if dist > r:
		return Vector2.ZERO
	var s := r - dist if approaching else r + dist  # Distance along the two legs from the curve's start
	var t := s / (2.0 * r)
	var a := corner - d_in * r
	var b := corner + d_out * r
	var drawn := a * (1.0 - t) * (1.0 - t) + corner * 2.0 * (1.0 - t) * t + b * t * t
	return drawn - here

# --- Branch Phase 2 hooks (tower_design.md; Tower Code's BranchKit calls them) ---

# Quaker's slam: ends any speed boost it's on now: a Night Hound's sprint, the Hollow Stag's straight
# charge, a bolt / charge (_charge_left). Restless isn't a boost.
func stop_speed_boosts() -> void:
	rolling = false
	_straight_steps = 0
	straight_charging = false
	stream_speeding = false
	_charge_left = 0.0
	_speed_stale = true

# Groundroot: a flyer is dragged down onto the nearest route cell and walks the maze for `seconds`
# (is_flying() is false meanwhile: it re-routes, walls block it, walker-only effects reach it), then
# rises and flies straight at the Heartwood from where it is. Never a boss (BranchKit doesn't pass one).
func ground(seconds: float) -> void:
	if is_cleansed or enemy_data.trait_kind != EnemyData.Trait.FLYING or enemy_data.is_boss:
		return
	var map_generator = _map_generator()
	if map_generator == null:
		return
	if _grounded_left > 0.0:
		_grounded_left = maxf(_grounded_left, seconds)  # Already down: just longer
		return
	var nearest: Vector2
	var route_flyer := is_route_flyer()
	if route_flyer and not _path.is_empty():
		# A route flyer comes down on its own route, at the point below it (it rises back onto that route later)
		_air_route = _path
		_air_held = _route_point_below()
		nearest = _path[_air_held]
	else:
		var route: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
		if route.is_empty():
			return
		nearest = route[0]
		for cell in route:
			if grid.calculate_map_position(cell).distance_squared_to(position) \
					< grid.calculate_map_position(nearest).distance_squared_to(position):
				nearest = cell
	_grounded_left = seconds
	_end_drag(false)
	_leaping = true  # No walking during the drop
	var tween := create_tween()
	_leap_tween = tween
	tween.tween_property(self, "position", grid.calculate_map_position(nearest), GROUND_DROP_TIME) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(sprite, "scale", sprite.scale * Vector2(1.2, 0.8), GROUND_DROP_TIME)
	tween.tween_property(sprite, "scale", sprite.scale, 0.1)
	tween.tween_callback(_landed_from_air.bind(nearest, route_flyer))

# The drop finished: it walks the maze from `cell`. A route flyer keeps the Waymark leg it really is on; a through-wall
# flyer (the Phantom) counts as past the stone (legendaries_final.md 1.1).
func _landed_from_air(cell: Vector2, route_flyer: bool) -> void:
	_leaping = false
	var map_generator = _map_generator()
	if map_generator == null or is_cleansed:
		return
	if not route_flyer:
		passed_waymark = true
	set_path(map_generator.get_path_from(cell, passed_waymark))
	_speed_stale = true

# The index of the route point below it on its path (the nearer of the points either side of it).
func _route_point_below() -> int:
	if _path.is_empty():
		return 0
	var i := clampi(_path_index, 0, _path.size() - 1)
	if i > 0 and grid.calculate_map_position(_path[i - 1]).distance_squared_to(position) \
			<= grid.calculate_map_position(_path[i]).distance_squared_to(position):
		return i - 1
	return i

func is_grounded() -> bool:
	return _grounded_left > 0.0

# Its time on the ground ran out: a route flyer rises back onto its own route (the point nearest it from where it was
# grounded on, within the Waymark leg it is on); a through-wall flyer flies straight at the Heartwood from here.
func _rise_from_ground() -> void:
	_grounded_left = 0.0
	var map_generator = _map_generator()
	if map_generator == null or is_cleansed:
		return
	if is_route_flyer() and not _air_route.is_empty():
		_rejoin_air_route(_air_held)
		return
	set_path(PackedVector2Array([get_current_cell(), map_generator.endPath]))
	_speed_stale = true

# Back onto its own route in the air: the point nearest it at or after `from` (not past the Waymark while it hasn't
# passed it), and on from there.
func _rejoin_air_route(from: int) -> void:
	var map_generator = _map_generator()
	var last := _air_route.size()
	if not passed_waymark and map_generator != null and map_generator.has_method("waymark_split") and map_generator.has_waymark():
		var split: int = map_generator.waymark_split(_air_route)
		if split >= 0:
			last = split + 1
	var best := clampi(from, 0, _air_route.size() - 1)
	var best_d := INF
	for i in range(clampi(from, 0, _air_route.size() - 1), last):
		var d := grid.calculate_map_position(_air_route[i]).distance_squared_to(position)
		if d < best_d:
			best_d = d
			best = i
	var rest := _air_route.slice(best)
	set_path(rest)
	_air_route = rest
	_air_held = 0
	_speed_stale = true

# Gloamwing: with drop_stacks of Soaked and Drowsy together (Brimming never raises it), its wings are too heavy.
func _check_wings() -> void:
	if dropped or is_cleansed or enemy_data.drop_stacks <= 0 or _leaping:
		return
	if statuses.stacks(EnemyStatuses.DAMP) + statuses.stacks(EnemyStatuses.DROWSY) >= enemy_data.drop_stacks:
		_drop_for_good()

# It drops to the path at the route point below it and walks the rest, for good: a walker from that cell (the maze,
# ground effects and holds all apply), at drop_walk_speed. Its own landing, not ground() (which rises again).
func _drop_for_good() -> void:
	var map_generator = _map_generator()
	if map_generator == null or _path.is_empty():
		return
	var cell: Vector2 = _path[_route_point_below()]
	_grounded_left = 0.0
	dropped = true
	speed *= enemy_data.drop_walk_speed / maxf(enemy_data.speed, 1.0)  # (Its Omen / Dream speed share stays)
	_end_drag(false)
	_leaping = true  # No walking during the drop
	var tween := create_tween()
	_leap_tween = tween
	var frames := sprite.sprite_frames
	if frames != null and frames.has_animation(&"land") and frames.get_animation_speed(&"land") > 0.0:
		# Its "land" row: the wings close and fold in the air, then it drops (the last frame is walk_down's first)
		var land := frames.get_frame_count(&"land") / frames.get_animation_speed(&"land")
		sprite.play(&"land")
		_pose_left = land
		tween.tween_interval(maxf(land - GROUND_DROP_TIME, 0.0))
	tween.tween_property(self, "position", grid.calculate_map_position(cell), GROUND_DROP_TIME) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(sprite, "scale", sprite.scale * Vector2(1.2, 0.8), GROUND_DROP_TIME)
	tween.tween_property(sprite, "scale", sprite.scale, 0.1)
	tween.tween_callback(_landed_from_air.bind(cell, true))

# Pall: glides to the nearest walker ahead within PALL_REACH and settles over it, moving at its pace; when it is
# dispelled the Pall flies on along its route. True while it covers (or glides to) one: its own walk is skipped.
func _update_pall(delta: float) -> bool:
	if covering != null and (not is_instance_valid(covering) or covering.is_cleansed or not _can_cover(covering, true)):
		_uncover()
	if covering == null:
		_pall_seek -= delta
		if _pall_seek > 0.0 or not is_flying():
			return false
		_pall_seek = PALL_SEEK_EVERY
		covering = _walker_to_cover()
		if covering == null:
			return false
		_settled = false
		_air_held = _path_index  # Where it leaves its route (it flies on from about here)
		covering.covered_by = self
	var before := position
	var target: Vector2 = covering.position + covering._lane_drawn + PALL_ABOVE
	if _settled:
		position = target
	else:
		var to := target - position
		var step := PALL_SWOOP * delta
		if to.length() <= maxf(step, PALL_SETTLE):
			position = target
			_settled = true
			if sprite.sprite_frames.has_animation(&"settled"):
				sprite.play(&"settled")  # Drawn over the walker (see-through in the middle)
		else:
			position += to / to.length() * step
	if not _culled:
		update_animation(position - before)
	return true

# A walker it may cover: on the ground, not a boss or a Deeply Blighted, targetable, not under another Pall.
func _can_cover(walker: Node, mine: bool = false) -> bool:
	return walker != self and not walker.is_cleansed and walker.has_method("on_route") and not walker.is_flying() \
		and not walker.enemy_data.is_boss and not walker.elite and walker.is_in_group(GROUP) \
		and not walker.has_meta(DriftShapes.PACK_META) \
		and (walker.covered_by == null or (mine and walker.covered_by == self))

# The nearest walker ahead of it (nearer the Heartwood) within PALL_REACH cells.
func _walker_to_cover() -> Node2D:
	if _spawner == null:
		return null
	var mine := get_remaining_distance()
	var reach := PALL_REACH * grid.cell_size.x
	var best: Node2D = null
	var best_d := reach * reach
	for other in _spawner.get_enemies():
		if not _can_cover(other) or other.get_remaining_distance() >= mine:
			continue
		var d: float = other.position.distance_squared_to(position)
		if d < best_d:
			best_d = d
			best = other
	return best

# Its walker is gone (dispelled, flown up or now a boss's): the Pall flies on along its own route from here.
func _uncover() -> void:
	if covering != null and is_instance_valid(covering) and covering.covered_by == self:
		covering.covered_by = null
	covering = null
	_settled = false
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(&"fly") and not is_cleansed:
		sprite.play(&"fly")
	if not is_cleansed and not _air_route.is_empty():
		_rejoin_air_route(_air_held)

# A Pall's half of a blow at the walker it covers: no multipliers or shell again (they were the walker's).
func take_shared(amount: float, source: Node, tag: StringName) -> void:
	_shared_hit = true
	_take_damage(amount, "", false, false, source, tag)
	_shared_hit = false

# Earthbind / Deeproot on what Held can't stop (Phantoms): a plain stop for `seconds`, no status, no Reactions.
func pause(seconds: float) -> void:
	if not is_cleansed:
		hold_time = maxf(hold_time, seconds)

# Pixels per second right now: base speed, sprinting / lost / charging, then slows.
func get_move_speed() -> float:
	var base := speed
	if rolling:
		base = enemy_data.roll_speed * modifiers.get("speed", 1.0)
	elif lost:
		base = minf(base, enemy_data.lost_speed)
	if _charge_left > 0.0:
		base *= enemy_data.charge_speed_multiplier
	if straight_charging:
		base *= enemy_data.straight_charge_multiplier
	if stream_speeding:
		base *= float(modifiers.get("straight_speed", 1.0))  # Swift Stream Omen
	if enemy_data.hurt_below > 0.0 and health <= max_health * enemy_data.hurt_below:
		base *= enemy_data.hurt_speed_multiplier  # Scarecrow: Stitched
	base *= 1.0 + RESTLESS_SPEED * restless
	var moved := base * statuses.get_speed_multiplier()
	if enemy_data.min_speed_share > 0.0:
		moved = maxf(moved, base * enemy_data.min_speed_share)  # Barrow King: Iron Will
	return moved

# A Wraith whose Lantern Bearer was dispelled first loses the way and slows down.
func set_lost() -> void:
	if not is_cleansed:
		lost = true
		_speed_stale = true

# The spawner knocked down a Thornwall for this creature (TRAMPLE).
func trampled() -> void:
	_trampled += 1
	_trait_timer = 0.0


# --- Traits (acts_1_2.md) ---------------------------------------------------------------------

func _update_trait(delta: float) -> void:
	match enemy_data.trait_kind:
		EnemyData.Trait.TRAMPLE:
			if _trampled >= enemy_data.trample_max:
				return
			_trait_timer += delta
			if _trait_timer >= enemy_data.trample_interval:
				_trait_timer = enemy_data.trample_interval - 0.25  # No wall in reach: look again soon
				trample_requested.emit(self)
		EnemyData.Trait.LEAP:
			_trait_timer += delta
			var hurt := health <= max_health / 2
			var interval := enemy_data.leap_interval_hurt if hurt else enemy_data.leap_interval
			if _trait_timer >= interval:
				_trait_timer = 0.0
				_leap()

# Called each time the creature reaches a cell centre on its path.
func _on_cell_reached() -> void:
	if _path_index >= 2 and _path_index < _path.size() and not is_flying():
		var arrived: Vector2 = _path[_path_index - 1]
		if arrived - _path[_path_index - 2] != _path[_path_index] - arrived:
			var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
			if dreams != null:
				dreams.switchback_at(self, arrived)
	if enemy_data.ash_trail_time > 0.0:
		_ash_cells[get_current_cell()] = enemy_data.ash_trail_time
	if enemy_data.straight_charge_tiles > 0:
		_update_straight_charge()
	if not modifiers.is_empty():  # Omens: Tramplers, Burrowers
		if modifiers.has("straight_speed") and not is_flying():
			_update_swift_stream()
		if modifiers.get("tramples_thornwall", false) and _spawner != null and not is_flying():
			_spawner.try_omen_trample(self)
		var burrow_tiles := int(modifiers.get("burrow_tiles", 0))
		if burrow_tiles > 0 and not _leaping:
			_try_omen_burrow(burrow_tiles, float(modifiers.get("burrow_time", 0.5)))
	match enemy_data.trait_kind:
		EnemyData.Trait.ROLLING:
			_update_rolling()
		EnemyData.Trait.BURROW:
			_try_burrow()
		EnemyData.Trait.WANDER:
			_try_wander()

# Night Hound: sprints once it has gone `roll_after_tiles` in a straight line.
func _update_rolling() -> void:
	if _path_index < 1:
		return
	var step := _path[_path_index - 1] - (_path[_path_index - 2] if _path_index >= 2 else get_current_cell())
	_straight_steps = _straight_steps + 1 if step == _last_step else 1
	_last_step = step
	# Keeps rolling only while the next step goes the same way; stops at the turn.
	var next_same := _path_index < _path.size() and _path[_path_index] - _path[_path_index - 1] == step
	# A sprint can't start on a cracked cell (Earthshaker, Fault Line); one already running carries on
	var may_start := rolling or not BranchKit.is_cracked(self, get_current_cell())
	var straight_cells := _straight_steps * _step_cells(_path_index - 1)  # (Half cells: steps are half a cell)
	rolling = straight_cells >= enemy_data.roll_after_tiles - 0.01 and next_same and may_start
	_speed_stale = true

# Hollow Stag: charges along any straight of straight_charge_tiles+ path tiles (the whole straight,
# counting the tiles behind and ahead of it), and stops at the turn.
func _update_straight_charge() -> void:
	var was := straight_charging
	straight_charging = false
	if _path_index >= 1 and _path_index < _path.size():
		# A charge can't start on a cracked cell (Earthshaker, Fault Line); one already running carries on
		straight_charging = _straight_cells() >= enemy_data.straight_charge_tiles - 0.01 \
			and (was or not BranchKit.is_cracked(self, get_current_cell()))
	if straight_charging != was:
		_speed_stale = true

# The length in cells of the straight it's on now: the whole run of same-direction steps through its
# current step, behind and ahead (half-cell routes too). 0 off a route.
func _straight_cells() -> float:
	if _path_index < 1 or _path_index >= _path.size():
		return 0.0
	var here := _path_index - 1
	var step := _path[here + 1] - _path[here]
	var tiles := 2
	var i := here + 1
	while i + 1 < _path.size() and _path[i + 1] - _path[i] == step:
		tiles += 1
		i += 1
	i = here
	while i >= 1 and _path[i] - _path[i - 1] == step:
		tiles += 1
		i -= 1
	return (tiles - 1) * _step_cells(here + 1) + 1.0  # Points → cells

# The Swift Stream Omen (run_design.md; modifiers straight_speed / straight_speed_cells): faster only while
# on a straight of straight_speed_cells+ cells, back to its pace at the turn. Bosses never carry Omens.
func _update_swift_stream() -> void:
	var was := stream_speeding
	stream_speeding = _straight_cells() >= float(modifiers.get("straight_speed_cells", 4)) - 0.01
	if stream_speeding != was:
		_speed_stale = true

# Mire Hag: sinks into the mire and rises `leap_tiles` ahead along her path, then makes nightmares
# near where she rose Damp.
func _leap() -> void:
	if _path_index >= _path.size():
		return
	var leap_steps := maxi(roundi(enemy_data.leap_tiles / _step_cells(_path_index)), 1)  # leap_tiles cells ahead
	var landing_index := mini(_path_index + leap_steps - 1, _path.size() - 1)
	var landing := grid.calculate_map_position(_path[landing_index])
	_sink_and_rise(landing, func() -> void:
		_path_index = landing_index + 1
		var reach := enemy_data.leap_splash_radius * grid.cell_size.x
		for creature in get_tree().get_nodes_in_group(GROUP):
			if creature.global_position.distance_to(global_position) <= reach:
				creature.apply_status(EnemyStatuses.DAMP)
		leaped.emit(self)
		if _path_index >= _path.size():
			if BranchKit.before_goal(self):
				return  # Heartroot's "Not yet"
			reached_goal.emit(self)
			queue_free())

# Squashes flat into the ground and fades, moves to `landing` (pixels) while under, rises the same
# way back up, then calls `on_risen`. Not walking meanwhile (Mire Hag, Gravecrawler).
func _sink_and_rise(landing: Vector2, on_risen: Callable) -> void:
	_end_drag(false)
	_leaping = true
	if sprite.sprite_frames.has_animation(&"burrow"):
		# A leap (the Mire Hag) keeps its LEAP_TIME; a burrow (Gravecrawler) plays the row at its own length
		_burrow_to(landing, on_risen, LEAP_TIME if enemy_data.trait_kind == EnemyData.Trait.LEAP else 0.0)
		return
	var base_scale := sprite.scale
	var sunk_scale := Vector2(base_scale.x * 1.3, base_scale.y * 0.1)
	var tween := create_tween()
	_leap_tween = tween
	tween.tween_property(sprite, "scale", sunk_scale, LEAP_TIME * 0.4).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "position:y", 10.0, LEAP_TIME * 0.4).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, LEAP_TIME * 0.4)
	tween.tween_property(self, "position", landing, LEAP_TIME * 0.2)
	tween.tween_property(sprite, "scale", base_scale, LEAP_TIME * 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(sprite, "position:y", 0.0, LEAP_TIME * 0.4).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate:a", 1.0, LEAP_TIME * 0.4)
	tween.tween_callback(func() -> void:
		_leaping = false
		on_risen.call())

# With burrow art (Gravecrawler, the Mire Hag): plays "burrow" to sink, moves while under, plays it backwards to
# surface, then calls on_risen. `fit` > 0: the whole sink-and-rise takes that long, the row sped up to fit (the Mire
# Hag's leap keeps LEAP_TIME with her new burrow art: owner 2026-10-19, so she plays as balanced).
func _burrow_to(landing: Vector2, on_risen: Callable, fit: float = 0.0) -> void:
	var length := _animation_length(&"burrow")
	var each := length
	if fit > 0.0 and length > 0.0:
		each = maxf((fit - LEAP_TIME * 0.2 - 0.1) / 2.0, 0.05)  # (The rest of `fit` is the move under and the two fades)
		sprite.speed_scale = length / each
	sprite.play(&"burrow")
	var tween := create_tween()
	_leap_tween = tween
	tween.tween_interval(each)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.05)
	tween.tween_property(self, "position", landing, LEAP_TIME * 0.2)
	tween.tween_callback(func() -> void: sprite.play_backwards(&"burrow"))
	tween.tween_property(sprite, "modulate:a", 1.0, 0.05)
	tween.tween_interval(each)
	tween.tween_callback(func() -> void:
		sprite.speed_scale = 1.0
		_leaping = false
		on_risen.call())

# Plays a special animation (if the art has it) and keeps the walk animation from replacing it for
# seconds.
func _play_pose(animation: StringName, seconds: float, backwards: bool = false) -> void:
	if not sprite.sprite_frames.has_animation(animation):
		return
	if backwards:
		sprite.play_backwards(animation)
	else:
		sprite.play(animation)
	_pose_left = seconds

# Raises the health bar (and the status icons over it) above tall art: BAR_ABOVE_HEAD px over the
# top of its sheet's solid pixels (bounds.json, at its sprite_scale), if that's higher than the usual
# HEALTH_BAR_OFFSET. Everyday nightmares keep the usual place.
func _measure_bar_offset() -> void:
	_bar_offset = HEALTH_BAR_OFFSET
	var frames := sprite.sprite_frames
	if frames == null or not frames.has_animation(_base_animation()) or frames.get_frame_count(_base_animation()) == 0:
		return
	var texture := frames.get_frame_texture(_base_animation(), 0)
	var sheet: String = texture.atlas.resource_path if texture is AtlasTexture else texture.resource_path
	var bounds: Dictionary = _art_bounds().get(sheet.get_file().get_basename(), {})
	if bounds.has("top"):
		var top: float = float(bounds.top) * sprite.scale.y + sprite.position.y
		_bar_offset.y = minf(HEALTH_BAR_OFFSET.y, top - BAR_ABOVE_HEAD)

# Feet on the path: the art draws its feet `bottom` px below the frame's centre (bounds.json, the
# lowest solid pixel: the contact shadow's line), so the body is raised that far, at its scale. Flyers
# hover, so they keep their place.
func _measure_foot_lift() -> void:
	_foot_lift = 0.0
	if enemy_data.trait_kind == EnemyData.Trait.FLYING:
		return
	var frames := sprite.sprite_frames
	if frames == null or not frames.has_animation(_base_animation()) or frames.get_frame_count(_base_animation()) == 0:
		return
	var texture := frames.get_frame_texture(_base_animation(), 0)
	var sheet: String = texture.atlas.resource_path if texture is AtlasTexture else texture.resource_path
	var bounds: Dictionary = _art_bounds().get(sheet.get_file().get_basename(), {})
	if bounds.has("bottom"):
		_foot_lift = maxf(float(bounds.bottom) - 1.0, 0.0) * sprite.scale.y

# Where the body is drawn (global: its frame's centre). Visuals aim here (projectiles, hit effects);
# game logic (ranges, splash, y-sort) keeps global_position, the route point under its feet.
func get_body_position() -> Vector2:
	return global_position + _body_offset()

# The drawn body's offset from the logical position: the rounded corner plus the foot lift (and asleep, its sink).
func _body_offset() -> Vector2:
	return _corner_offset + _lane_drawn + Vector2(0, -_foot_lift + _sleep_sink)

# The sprite follows the drawn body: the walking lane goes in sprite.position (so the y-sort, which reads the sprite's
# position with the enemy's y_sort_enabled, sorts a clump by where each body is drawn: council 2026-10-24c), the rest
# (corner, foot lift, sink, recoil) in sprite.offset. A burrow's sink tween owns position.y while it runs.
func _apply_sprite_offset() -> void:
	sprite.offset = (_body_offset() - _lane_drawn + _recoil) / sprite.scale
	if not _leaping:
		sprite.position = _lane_drawn
	else:
		sprite.position.x = _lane_drawn.x
	if _body_fx != null:
		_body_fx.position = sprite.position

# Falling asleep (screens_ui.md "Status row: Reaction-ready marks and falling asleep"): when Sleep fills into Asleep
# (statuses.sleep_time from 0), the Sleep icon flashes once and turns into the Asleep badge; the nightmare settles
# (sinks, leans, its eyes dim to SLEEP_EYES) and a "z" (sleep_z) rises every SLEEP_MOTE_EVERY s. Waking: a short hop, the
# eyes flare back, the last "z" pops (sleep_pop). Reduced motion: no lean, hop or motes (the dim eyes and the badge stay). The
# motes keep to the Fx budget (none at reduced effects or off screen). Called only while any of it is in play.
func _update_sleep(delta: float) -> void:
	var asleep := statuses.sleep_time > 0.0
	if asleep and not _was_asleep:
		_was_asleep = true
		_wake_jolt = 0.0
		_mote_left = SLEEP_MOTE_EVERY * 0.5
		_asleep_swap = STATUS_FLASH_TIME if statuses.has(EnemyStatuses.DROWSY) else 0.0
		if _asleep_swap > 0.0:
			flash_status(EnemyStatuses.DROWSY)  # The Sleep icon flashes once, then turns into Asleep
	elif not asleep and _was_asleep:
		_was_asleep = false
		_wake_jolt = WAKE_JOLT_TIME
		if _mote != null:  # It had a "z": it pops (Tower Assets' sleep_pop) where the last one was, or above its head
			var last: Node2D = _mote.get_ref()
			var world := Reactions._world(self)
			if world != null:
				Fx.play(&"sleep_pop", last.global_position if is_instance_valid(last) else _head_top(), world)
			if is_instance_valid(last):
				last.queue_free()
		_mote = null
		if _asleep_badge:
			_asleep_badge = false
			_hud_changes = -1  # The row lays out again: Asleep goes
			_hud_dirty = true
	if asleep and not _asleep_badge:
		_asleep_swap -= delta
		if _asleep_swap <= 0.0:
			_asleep_badge = true
			_hud_changes = -1  # The row lays out again: Asleep in Sleep's place
			_hud_dirty = true
	var still := bool(Fx.setting("reduced_motion", false))
	_settle = move_toward(_settle, 1.0 if asleep else 0.0, delta / SLEEP_SETTLE_TIME)
	_wake_jolt = maxf(_wake_jolt - delta, 0.0)
	var jolt := sin(PI * (1.0 - _wake_jolt / WAKE_JOLT_TIME)) if _wake_jolt > 0.0 else 0.0
	var sink := SLEEP_SINK * _settle - (0.0 if still else WAKE_HOP * jolt)
	if sink != _sleep_sink:
		_sleep_sink = sink
		_apply_sprite_offset()
	var lean := 0.0 if still else SLEEP_LEAN * _settle * (-1.0 if sprite.flip_h else 1.0)
	if lean != _sleep_lean and not _dragging:  # (A drag wobbles the sprite itself)
		_sleep_lean = lean
		sprite.rotation = lean
	var eyes := lerpf(1.0, SLEEP_EYES, _settle) + (WAKE_EYE_FLARE - 1.0) * jolt
	if eyes != _eye_shown:
		_eye_shown = eyes
		sprite.set_instance_shader_parameter(&"eye_glow", eyes)
	if not asleep or still or _culled or Fx.reduced() or not Fx.on_screen(global_position):
		return
	_mote_left -= delta
	if _mote_left > 0.0:
		return
	_mote_left = SLEEP_MOTE_EVERY
	var world := Reactions._world(self)  # (Never under EnemyContainer: its children are all nightmares)
	if world == null:
		return
	var mote := Fx.play(&"sleep_z", _head_top(), world)  # Tower Assets' sleep_z (2ad0c219): its anchor sits on the head
	if mote != null:
		_mote = weakref(mote)

# Just above the drawn head (bounds.json "top", as the health bar is placed): where the sleep "z" rise from.
func _head_top() -> Vector2:
	return global_position + _body_offset() + Vector2(0.0, _bar_offset.y + BAR_ABOVE_HEAD)

# Enough stacks of `id` for a Reaction to count it (Reactions.ready_need: its lowest need, Brimming's rule included).
func _is_primed(id: StringName) -> bool:
	var need := Reactions.ready_need(id, statuses)
	return need > 0 and statuses.stacks(id) >= need

# The badges shown, from `order` (get_status_order): at most STATUS_BADGES_MAX, most important first, but a
# Reaction-ready status always keeps its place over one that isn't (screens_ui.md: a primed status is one of those shown).
func _pick_badges(order: Array) -> Array:
	if order.size() <= STATUS_BADGES_MAX:
		return order
	var picked: Array = order.filter(_is_primed).slice(0, STATUS_BADGES_MAX)
	for id in order:
		if picked.size() >= STATUS_BADGES_MAX:
			break
		if not id in picked:
			picked.append(id)
	picked.sort_custom(func(a: StringName, b: StringName) -> bool: return order.find(a) < order.find(b))
	return picked

# bounds.json, read once (plain numbers: safe to keep in a static).
static func _art_bounds() -> Dictionary:
	if _bounds_cache.is_empty() and FileAccess.file_exists(ART_BOUNDS_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(ART_BOUNDS_PATH))
		_bounds_cache = parsed if parsed is Dictionary else {"": {}}
	return _bounds_cache
static var _bounds_cache := {}

# Plays a one-off pose from its art for its own length, if it has one (the Huntsman's horn when a
# hound joins, the Lamplighter lighting a lantern); walking picks up again after.
func play_pose(animation: StringName) -> void:
	if not is_cleansed:
		_play_pose(animation, _animation_length(animation))

func _animation_length(animation: StringName) -> float:
	var frames := sprite.sprite_frames
	if not frames.has_animation(animation) or frames.get_animation_speed(animation) <= 0.0:
		return 0.0
	return frames.get_frame_count(animation) / frames.get_animation_speed(animation)

# New art for the same nightmare (the Shellbound's cracked shell), keeping the current animation.
func _swap_frames(frames: SpriteFrames) -> void:
	var animation := sprite.animation
	sprite.sprite_frames = frames
	if frames.has_animation(animation):
		sprite.play(animation)
	else:
		sprite.play(_base_animation())

# Magpie Perch / Magpie's Hoard (and Wrens with Flock Together) strip nightmare buffs on a hit,
# called before the hit lands (tower_design.md "status jobs"):
#   - a dread shell loses a double chunk (this extra one, then the hit's own),
#   - a Weeper stops mending for MEND_STRIP_TIME s,
#   - its Omen boosts go: extra immunities (Sleepless), shorter statuses (Stubborn Blight), the
#     thicker shell (Hard Bark), and the Omen's speed ("omen_speed"; Dreams / Blight speed stays).
#     Heavy Rain's Soaked is the player's gain, so it stays.
# Returns true if anything was stripped (the thief's +1 Dew is Tower Code's).
func strip_buff(_by: Node) -> bool:
	if is_cleansed:
		return false
	modifiers = modifiers.duplicate()  # Split-offs and followers share their parent's dictionary
	var stripped := false
	if coat > 0.0:
		coat = maxf(coat - _coat_per_hit, 0.0)
		stripped = true
	if enemy_data.mend_radius > 0.0:
		_mend_stopped = MEND_STRIP_TIME
		stripped = true
	if modifiers.has("status_immune"):
		statuses.immune = enemy_data.status_immune.duplicate()
		modifiers.erase("status_immune")
		stripped = true
	if float(modifiers.get("status_duration", 1.0)) < 1.0:
		statuses.duration_multiplier_all = 1.0
		modifiers.erase("status_duration")
		stripped = true
	var coat_boost := float(modifiers.get("coat", 1.0))
	if coat_boost > 1.0:
		coat /= coat_boost
		coat_max /= coat_boost
		_coat_per_hit /= coat_boost
		modifiers.erase("coat")
		stripped = true
	var omen_speed := float(modifiers.get("omen_speed", 1.0))
	if omen_speed > 1.0:
		speed /= omen_speed
		_speed_stale = true
		modifiers.erase("omen_speed")
		stripped = true
	if stripped:
		queue_redraw()
	return stripped

# --- No maze juggling (run_design.md) -----------------------------------------------------------

# Restless stacks (+RESTLESS_SPEED speed each, for the rest of its life).
func get_restless() -> int:
	return restless

# Unbound: deaf to re-routes, tramples Wardens planted on its route.
func is_unbound() -> bool:
	return unbound

# For the nightmare info: {stacks, speed_bonus (0.2 per stack), unbound, can_unbind (false for
# bosses), unbound_at}.
func get_restless_info() -> Dictionary:
	return {"stacks": restless, "speed_bonus": RESTLESS_SPEED * restless, "unbound": unbound,
		"can_unbind": not enemy_data.is_boss, "unbound_at": UNBOUND_AT}

# The cell it last stood on: a re-route whose next step leads back there turns it around.
func get_last_cell() -> Vector2:
	return _last_cell

# A re-route turned it back: one more Restless. True if that made it Unbound (never bosses).
func add_restless() -> bool:
	if is_cleansed:
		return false
	restless += 1
	_speed_stale = true
	queue_redraw()
	if unbound or restless < UNBOUND_AT or enemy_data.is_boss:
		return false
	unbound = true
	_start_unbound_trail()
	return true

# Unbound: a Warden on the cell it's heading into gets trampled (the spawner removes it).
func _trample_ahead() -> void:
	if _path_index >= _path.size():
		return
	var next := _path[_path_index]
	if _spawner != null and _spawner.tower_at_point(next) != null:  # (Half cells: by the point's half cell)
		trample_cell_requested.emit(self, next)

# Red-hot embers left behind while it walks (world space, so they trail).
func _start_unbound_trail() -> void:
	_unbound_trail = CPUParticles2D.new()
	_unbound_trail.local_coords = false
	_unbound_trail.amount = 16
	_unbound_trail.lifetime = 0.6
	_unbound_trail.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_unbound_trail.emission_sphere_radius = 8.0
	_unbound_trail.gravity = Vector2(0, -20)
	_unbound_trail.initial_velocity_max = 8.0
	_unbound_trail.scale_amount_min = 1.5
	_unbound_trail.scale_amount_max = 3.0
	var fade := Gradient.new()
	fade.set_color(0, Color(Palette.MOONLIGHT, 0.9))
	fade.set_color(1, Color(UNBOUND_GLOW, 0.0))
	_unbound_trail.color_ramp = fade
	_unbound_trail.position = Vector2(0, -6)
	add_child(_unbound_trail)
	_unbound_trail.emitting = true

# Rooted Nightmares: true while the next cell on the route is blocked for this walker, by a Held
# nightmare (it tries a way round every REROUTE_RETRY s, else waits) or a nightmare already waiting
# there (it queues). Only checked at a cell centre, so walkers never stop halfway between cells.
# Flyers ignore it. The spawner rebuilds the blocked cells each frame (rooted_cells / waiting_cells).
func _is_blocked_ahead(delta: float) -> bool:
	var spawner = _spawner
	if spawner == null or spawner.rooted_cells.is_empty() or is_flying() or _path_index < 1 \
			or _path_index >= _path.size() \
			or not position.is_equal_approx(grid.calculate_map_position(_path[_path_index - 1])):
		waiting = false
		return false
	var next := _path[_path_index]
	var holder = spawner.blocker_at(next, self, spawner.rooted_cells)  # (Half cells: bodies overlapping, not one cell)
	if holder != null and holder != self and holder.has_meta(FinalTwists.LOGJAM_META):
		waiting = true  # Logjam: the ones behind a Snugroot hold queue, they don't path around it
		return true
	if holder != null and holder != self:
		_reroute_wait -= delta
		if _reroute_wait <= 0.0:
			_reroute_wait = REROUTE_RETRY
			var around: PackedVector2Array = spawner.route_around(get_route_point(), passed_waymark)
			if not around.is_empty():
				set_path(around)  # Heads for this cell first (already here), then round the blocker
				_path_index = 1
				waiting = false
				return false
		waiting = true
		return true
	var queued = spawner.blocker_at(next, self, spawner.waiting_cells)
	waiting = queued != null
	return waiting

# Lantern Roots (Kinship): a Gravecrawler held by a bonded Tangleroot can't burrow again this trip.
func stop_burrowing() -> void:
	_burrows = maxi(_burrows, enemy_data.burrow_max)

# Lantern Roots (Kinship): stays revealed for `seconds` (hidden Lurkers, the Eclipse), at once.
func reveal_for(seconds: float) -> void:
	_revealed_time = maxf(_revealed_time, seconds)
	if _hidden:
		_set_hidden(false)

# Gravecrawler: if a Warden or wall is right beside it and the cell past it leads to the Heartwood by
# a route at least `burrow_min_saving` cells shorter, it sinks under and surfaces there.
func _try_burrow() -> void:
	var map_generator = _map_generator()
	if _burrows >= enemy_data.burrow_max or _path_index >= _path.size() or map_generator == null:
		return
	var walls := _tower_cells()
	var here := get_current_cell()
	if _spawner != null and _spawner.is_lit(here):
		return  # Rootlight's light holds it above ground
	var best_route := PackedVector2Array()
	# In cells, so half-cell routes (2 steps a cell) compare fairly with whole-cell ones
	var best_length := (_path.size() - _path_index) * _step_cells(_path_index) - enemy_data.burrow_min_saving
	for direction in DIRECTIONS:
		var beyond := here + direction * 2
		if not walls.has(here + direction) or not _is_walkable(beyond, map_generator) \
				or BranchKit.is_stone_cell(self, here + direction):  # Rampart's stone walls can't be dug under
			continue
		var route: PackedVector2Array = map_generator.get_path_from(beyond, passed_waymark)
		var length := _route_cells(route) + 1.0  # + the tunnel under the wall (a cell)
		if not route.is_empty() and length <= best_length + 0.01:
			best_route = route
			best_length = length
	if best_route.is_empty():
		return
	_burrows += 1
	var surface := grid.calculate_map_position(best_route[0])
	_sink_and_rise(surface, func() -> void: set_path(best_route))

# The Burrowers Omen (run_design.md "Omens with teeth"; modifiers burrow_tiles, burrow_time): at a bend
# in its route it burrows `tiles` path tiles ahead, untargetable while under (out of the enemies group).
# Never onto the Heartwood's own tile, and never from a tile Rootlight lights.
func _try_omen_burrow(tiles: int, seconds: float) -> void:
	if _path_index < 2 or _path_index >= _path.size() or is_flying():
		return
	var here := _path[_path_index - 1]
	if _path[_path_index] - here == here - _path[_path_index - 2]:
		return  # Not a bend
	if _spawner != null and _spawner.is_lit(here):
		return
	var steps := maxi(roundi(tiles / _step_cells(_path_index)), 1)  # `tiles` cells ahead (half-cell routes too)
	var landing_index := mini(_path_index + steps - 1, _path.size() - 2)
	if landing_index < _path_index:
		return
	_end_drag(false)
	_leaping = true
	remove_from_group(GROUP)
	var route := _path
	var landing := grid.calculate_map_position(_path[landing_index])
	var tween := create_tween()
	_leap_tween = tween
	tween.tween_property(sprite, "modulate:a", 0.15, seconds * 0.3)
	tween.tween_property(self, "position", landing, seconds * 0.4)
	tween.tween_property(sprite, "modulate:a", 1.0, seconds * 0.3)
	tween.tween_callback(func() -> void:
		_leaping = false
		if _path == route:
			_path_index = landing_index + 1
			_last_cell = _path[landing_index]
		else:  # The maze changed while it was under: on from where it surfaced
			var map_generator = _map_generator()
			if map_generator != null:
				set_path(map_generator.get_path_from(grid.calculate_grid_coordinates(position), passed_waymark))
		if not is_cleansed and not _hidden and not _untouchable:
			add_to_group(GROUP))

# Sleepwalker: sometimes steps into a dead-end pocket beside it, walks to the end and comes back.
func _try_wander() -> void:
	if _wander_cooldown > 0:
		_wander_cooldown -= 1
		return
	var map_generator = _map_generator()
	if map_generator == null or _path_index >= _path.size() or randf() >= enemy_data.wander_chance:
		return
	var here := get_current_cell()
	var pocket := _find_dead_end(here, map_generator)
	if pocket.is_empty():
		return
	# Half cells: it walks the pocket's cells in its own lane (the same offset from each cell's centre as
	# the route point it stands on: x.25 / x.75), out and back to that point.
	var stand := _path[_path_index - 1] if _path_index >= 1 else get_route_point()
	var lane := stand - here
	var detour := PackedVector2Array()
	for cell in pocket:
		detour.append(cell + lane)
	for i in range(pocket.size() - 2, -1, -1):
		detour.append(pocket[i] + lane)
	detour.append(stand)
	detour.append_array(_path.slice(_path_index))
	set_path(detour)
	_wander_cooldown = enemy_data.wander_cooldown_cells

# Cells of a dead-end pocket starting next to `here` (off the route, one way in, at most
# `wander_depth` deep), from the entrance to the end. Empty if there's none.
func _find_dead_end(here: Vector2, map_generator: Node) -> PackedVector2Array:
	var on_route := {}  # Whole cells the route runs through (half-cell routes: x.25 / x.75 points)
	for point in _path:
		on_route[(point + Vector2(0.5, 0.5)).floor()] = true
	var starts := DIRECTIONS.duplicate()
	starts.shuffle()
	for direction: Vector2 in starts:
		var cells := PackedVector2Array([here + direction])
		if on_route.has(cells[0]) or not _is_walkable(cells[0], map_generator):
			continue
		var visited := {here: true, cells[0]: true}
		while cells.size() <= enemy_data.wander_depth:
			var onward: Array[Vector2] = []
			for step in DIRECTIONS:
				var next: Vector2 = cells[cells.size() - 1] + step
				if not visited.has(next) and not on_route.has(next) and _is_walkable(next, map_generator):
					onward.append(next)
			if onward.is_empty():
				return cells  # The end of the pocket
			if onward.size() > 1:
				break  # It opens up: not a dead end
			visited[onward[0]] = true
			cells.append(onward[0])
	return PackedVector2Array()

func _is_walkable(cell: Vector2, map_generator: Node) -> bool:
	return grid.is_within_bounds(cell) and map_generator.path_layer.get_finder().is_walkable(cell)  # (A body fits there)

# The map (through the EnemyContainer), or null outside the main scene.
# Dew Pool landmark (environment_assets.md "Landmarks", 6fd3dccf): a walker on one of its cells (MapGenerator
# `dew_pool_cells`: {cell: true} or an Array of whole cells; Environment Code places it) is slowed DEW_POOL_SLOW while in
# it. A timed slow refreshed each presence tick, so it ends a moment after it wades out; slows never add up (the largest
# of it, the Mire gift and the rest counts) and the slow floors hold. Flyers, leaps and burrows pass over.
const DEW_POOL_SLOW := 0.25  # Balancing to confirm
func _wade_dew_pool() -> void:
	if is_flying() or _leaping:
		return
	var map := _map_generator()
	var cells = map.get("dew_pool_cells") if map != null else null
	if cells == null or cells.is_empty():
		return
	if cells.has(grid.calculate_grid_coordinates(position)):
		statuses.add_slow(DEW_POOL_SLOW, PRESENCE_TICK * 1.6)

func _map_generator() -> Node:
	return get_parent().get("map_generator") if get_parent() else null

# Cells with a Warden or wall on them.
func _tower_cells() -> Dictionary:
	var cells := {}
	var towers = get_parent().get("tower_container") if get_parent() else null
	if towers:
		for tower in towers.get_children():
			if tower is Tower and not tower.is_queued_for_deletion():
				for cell in tower.get_cells():
					cells[cell] = true
	return cells


# --- Presence (acts_3_4.md) ---------------------------------------------------------------------

# True while the nightmare can't be seen or targeted (Lurker in fog, the Moth Queen's Eclipse).
func is_hidden() -> bool:
	return _hidden

# Statuses it always carries (Drowned One: Damp; the Heavy Rain Omen: Damp), put back at once if
# anything clears them. Straight on `statuses`, so re-soaking never sets off Reactions.
func _keep_always_statuses() -> void:
	for id in _always_statuses:
		if not statuses.has(id):
			statuses.apply(id, 1, ALWAYS_DAMP_TIME)

func _update_presence(delta: float) -> void:
	_keep_always_statuses()
	for cell: Vector2 in (_ash_cells.keys() if not _ash_cells.is_empty() else []):
		_ash_cells[cell] -= delta
		if _ash_cells[cell] <= 0.0:
			_ash_cells.erase(cell)
	_presence_elapsed += delta
	if _presence_elapsed < PRESENCE_TICK:
		return
	var elapsed := _presence_elapsed
	_presence_elapsed = 0.0
	_speed_stale = true  # Timed slows (the Stag's aura, charges) may have run out
	if not statuses.smothering:
		_end_smother_fx()
	_wade_dew_pool()

	_revealed_time = maxf(_revealed_time - elapsed, 0.0)
	var hide := (enemy_data.hidden or _is_eclipsed()) and not _is_revealed()
	if hide != _hidden:
		_set_hidden(hide)
	_settings_elapsed += elapsed
	if _settings_elapsed >= SETTINGS_TICK:  # The settings panel's changes show within half a second
		_settings_elapsed = 0.0
		_refresh_display_settings()
	var silenced := statuses.silence_time > 0.0  # Hushbell (BranchKit): no abilities while silenced
	# Timed abilities' clock: a silenced boss runs them at BOSS_SILENCE_SPEED (a delay, never a stop;
	# tower_design.md 279ebb63), anything else silenced doesn't run them at all. Health-threshold
	# abilities (grief, bursts, echoes, bellow, laps) don't use this clock.
	var ability_elapsed := elapsed
	if silenced:
		# A Hushbell's Deep ranks slow it further (BranchKit sets the meta: 0.5 ÷ its Potency), never below the floor
		var boss_speed: float = maxf(float(get_meta(&"silence_boss_speed", BOSS_SILENCE_SPEED)), BOSS_SILENCE_FLOOR)
		ability_elapsed = elapsed * boss_speed if enemy_data.is_boss else 0.0
	elif has_meta(&"silence_boss_speed"):
		remove_meta(&"silence_boss_speed")  # The silence ended: the next one starts from half speed again
	if enemy_data.wake_radius > 0.0 and not silenced:  # Watcher
		for other in _others_within(enemy_data.wake_radius):
			if other.statuses.has(EnemyStatuses.DROWSY):
				other.statuses.remove(EnemyStatuses.DROWSY)
				other.queue_redraw()
			if other.statuses.sleep_time > 0.0 and other.statuses.sleep_locked_time <= 0.0:
				other.statuses.sleep_time = 0.0  # Wakes sleepers too (not under Nightbloom's lock)
	_mend_stopped = maxf(_mend_stopped - elapsed, 0.0)
	if enemy_data.mend_radius > 0.0 and _mend_stopped <= 0.0 and not silenced:  # Weeper (a magpie or a Hushbell can stop it)
		for other in _others_within(enemy_data.mend_radius):
			other.heal(other.max_health * enemy_data.mend_rate * elapsed)
	if not _ash_cells.is_empty():  # Ash Crawler
		for other in _field():
			if other != self and other.statuses.has(EnemyStatuses.SPORED) and _ash_cells.has(other.get_current_cell()):
				other.statuses.remove(EnemyStatuses.SPORED)
				other.queue_redraw()
	if enemy_data.brood != null:  # Moth Queen (and the Huntsman's horn)
		_brood_timer += ability_elapsed
		if _brood_timer >= enemy_data.brood_interval:
			_brood_timer = 0.0
			brood_requested.emit(self)
	if enemy_data.sapling != null:  # Hollow Oak
		_sapling_timer += ability_elapsed * _sapling_speed
		if _sapling_timer >= enemy_data.sapling_interval:
			_sapling_timer = 0.0
			sapling_requested.emit(self)
	_update_boss_pool_abilities(ability_elapsed)

# The new bosses' timed abilities (enemy_design.md "Boss pools"), on the presence tick.
func _update_boss_pool_abilities(elapsed: float) -> void:
	if enemy_data.lantern_interval > 0.0:  # Lamplighter
		_lantern_timer += elapsed
		if _lantern_timer >= enemy_data.lantern_interval:
			_lantern_timer = 0.0
			lantern_requested.emit(self)
	if enemy_data.shrug_interval > 0.0:  # Barrow King
		_shrug_timer += elapsed
		if _shrug_timer >= enemy_data.shrug_interval:
			_shrug_timer = 0.0
			shrug()
	if enemy_data.wither_interval > 0.0:  # Withering Oak (twice as fast once risen, like saplings)
		_wither_timer += elapsed * _sapling_speed
		if _wither_timer >= enemy_data.wither_interval:
			_wither_timer = 0.0
			play_pose(&"wither")  # Two roots lift and stab down
			wither_requested.emit(self, 1)
	if enemy_data.regen_rate > 0.0:  # Mourning Mother's Sorrow
		_since_hit += elapsed
		if _regen_left < 0.0:
			_regen_left = max_health * enemy_data.regen_cap
		sorrowing = _since_hit >= enemy_data.regen_delay and _regen_left > 0.0 and health < max_health \
			and statuses.veil_time <= 0.0
		if sorrowing:
			var amount := minf(max_health * enemy_data.regen_rate * elapsed, _regen_left)
			_regen_left -= amount
			heal(amount)

# Barrow King: every status on itself and the nightmares near it is shrugged off (they can be put back
# straight away). Static charges go without a bolt; sleepers wake.
func shrug() -> void:
	for creature in [self] + _others_within(enemy_data.shrug_radius):
		for id in creature.statuses.active_ids():
			creature.statuses.remove(id)
		creature.statuses.sleep_time = 0.0
		creature.queue_redraw()
	_shrug_flash = SHRUG_FLASH_TIME
	play_pose(&"shrug")  # Shoulders heave, a ring of grave-dust rolls out
	shrugged.emit(self)
	queue_redraw()

# Huntsman: the soothe share it takes while any of its hounds still hunts near it (within
# pack_shield_reach tiles; 1.0 once none is close, so clearing the hounds round him lets the maze finish him).
func get_pack_multiplier() -> float:
	if enemy_data.pack_shield >= 1.0:
		return 1.0
	var reach := enemy_data.pack_shield_reach * grid.cell_size.x
	for hound in pack:
		if is_instance_valid(hound) and not hound.is_cleansed \
				and (reach <= 0.0 or hound.global_position.distance_to(global_position) <= reach):
			return enemy_data.pack_shield
	return 1.0

# Hounds of its pack still hunting (Huntsman).
func pack_alive() -> int:
	return pack.filter(func(h) -> bool: return is_instance_valid(h) and not h.is_cleansed).size()

func is_regrouped() -> bool:
	return _regrouped

func _set_hidden(value: bool) -> void:
	_hidden = value
	if value:
		remove_from_group(GROUP)
	elif not is_entering():  # (Still on the bridge: it joins once on the island)
		add_to_group(GROUP)
	sprite.self_modulate.a = HIDDEN_ALPHA if value else 1.0
	_refresh_display_settings()
	queue_redraw()

# Health bars "always" (setting health_bars = 1; 0 = once hit, the default) and the Deeply Blighted
# outline (blight_outline), which stays off while the nightmare is hidden or cracking apart.
func _refresh_display_settings() -> void:
	var always := int(Fx.setting("health_bars", 0)) == 1
	if always != _bars_always:
		_bars_always = always
		queue_redraw()
	var outlined := elite and not _hidden and not is_cleansed and bool(Fx.setting("blight_outline", false))
	if outlined != _outlined:
		_outlined = outlined
		if _is_shared_material():
			sprite.material = _blight_material(outlined)
		else:  # Cracking apart on its own copy: change just that
			(sprite.material as ShaderMaterial).set_shader_parameter("outline_color",
				ELITE_OUTLINE_COLOR if outlined else Color(0, 0, 0, 0))

# The shared blight material: plain, or with the Deeply Blighted outline. Kept by the spawner (never
# a static: a material still held at exit is freed after the renderer and crashes). A nightmare
# outside an EnemyContainer gets a material of its own.
func _blight_material(outlined: bool) -> ShaderMaterial:
	var shared: Dictionary = _spawner.blight_materials if _spawner != null else {}
	if not shared.has(outlined):
		var material := ShaderMaterial.new()
		material.shader = BLIGHT_SHADER
		if outlined:
			material.set_shader_parameter("outline_color", ELITE_OUTLINE_COLOR)
		shared[outlined] = material
	return shared[outlined]

func _is_shared_material() -> bool:
	return _spawner != null and (sprite.material == _spawner.blight_materials.get(false)
		or sprite.material == _spawner.blight_materials.get(true))

# The 16×16 pixel-art icon for a status id (or "elite"), cached; null if the sheet has none.
func _status_icon(id: StringName) -> Texture2D:
	var overlay: NightmareOverlay = _spawner.overlay if _spawner != null else null
	return overlay.icon(id) if overlay != null else IconInfo.icon(id)

func _outline_alpha() -> float:
	var color = (sprite.material as ShaderMaterial).get_shader_parameter("outline_color")
	return color.a if color is Color else 0.0

# The Moth Queen's Eclipse hides every nightmare but bosses.
func _is_eclipsed() -> bool:
	return not enemy_data.is_boss and _spawner != null and _spawner.eclipse_left > 0.0

# Seen by a Warden within CLOSE_REVEAL_CELLS, a Marking Warden (Lanternmoth, Moon Moth, Rootlight)
# that has it in range, or a Will-o'-Wisp's glow.
func _is_revealed() -> bool:
	if _revealed_time > 0.0:
		return true  # Held in the light a while (Lantern Roots)
	if _spawner != null:  # The spawner's lookups: a few cells and short lists, not every Warden and nightmare
		_spawner.refresh_reveal_lookup()
		var reach := CLOSE_REVEAL_CELLS * grid.cell_size.x
		var here := get_current_cell()
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				var tower = _spawner.tower_cells.get(here + Vector2(dx, dy))
				if tower != null and is_instance_valid(tower) and global_position.distance_to(tower.global_position) <= reach:
					return true
		for tower in _spawner.marker_towers:
			if is_instance_valid(tower) and global_position.distance_to(tower.global_position) <= tower.get_range_pixels():
				return true
		for other in _spawner.revealers:
			if other != self and is_instance_valid(other) and not other.is_cleansed and not other.is_hidden() \
					and global_position.distance_to(other.global_position) <= other.enemy_data.reveal_radius * grid.cell_size.x:
				return true
		return false
	var towers = get_parent().get("tower_container") if get_parent() else null
	if towers:
		for tower in towers.get_children():
			if not tower is Tower or tower.attack_data == null:
				continue
			var distance := global_position.distance_to(tower.global_position)
			if distance <= CLOSE_REVEAL_CELLS * grid.cell_size.x:
				return true
			if tower.attack_data.applies_status == EnemyStatuses.MARKED and distance <= tower.get_range_pixels():
				return true
	for other in _field():
		if other != self and other.enemy_data.reveal_radius > 0.0 and not other.is_hidden() \
				and global_position.distance_to(other.global_position) <= other.enemy_data.reveal_radius * grid.cell_size.x:
			return true
	return false

# Every nightmare still on the field, hidden or not.
func _field() -> Array:
	var parent := get_parent()
	return parent.get_enemies() if parent and parent.has_method("get_enemies") else get_tree().get_nodes_in_group(GROUP)

func _others_within(cells: float) -> Array:
	var reach := cells * grid.cell_size.x
	return _field().filter(func(other: Node2D) -> bool:
		return other != self and global_position.distance_to(other.global_position) <= reach)

# Weeper's mending: restores up to `amount` health (fractions add up over time).
func heal(amount: float) -> void:
	if is_cleansed or health >= max_health or statuses.veil_time > 0.0:
		return  # (Veil: nothing mends inside Morning Fog's fog; FinalTwists)
	_heal_carry += amount
	var whole := int(_heal_carry)
	_heal_carry -= whole
	health = mini(health + whole, max_health)

# Boss moments that happen at a share of health: the Moth Queen's Eclipse, the Hollow Oak's Grief.
func _check_health_thresholds() -> void:
	if not _has_thresholds:
		return
	if enemy_data.eclipse_time > 0.0 and not _eclipsed and health <= max_health / 2:
		_eclipsed = true
		eclipse_started.emit(self, enemy_data.eclipse_time)
		_play_pose(&"eclipse", enemy_data.eclipse_time)  # Wings close over the dream…
		var reopen := create_tween()
		reopen.tween_interval(enemy_data.eclipse_time)
		reopen.tween_callback(func() -> void:  # …and open again
			if not is_cleansed:
				_play_pose(&"eclipse", _animation_length(&"eclipse"), true))
	while _griefs < enemy_data.grief_at.size() and health <= max_health * enemy_data.grief_at[_griefs]:
		_griefs += 1
		hold_time = maxf(hold_time, enemy_data.grief_pause)  # It stops and wails
		if sprite.sprite_frames.has_animation(&"burst"):  # Scarecrow: the coat flies open, Crows scatter
			_play_pose(&"burst", maxf(enemy_data.grief_pause, _animation_length(&"burst")))
		else:
			_play_pose(&"grief", enemy_data.grief_pause)
		grief_requested.emit(self)
	while _wither_bursts < enemy_data.wither_burst_at.size() and health <= max_health * enemy_data.wither_burst_at[_wither_bursts]:
		_wither_bursts += 1
		play_pose(&"wither")
		wither_requested.emit(self, enemy_data.wither_burst_count)  # Withering Oak: Drought
	while _echoes < enemy_data.echo_at.size() and health <= max_health * enemy_data.echo_at[_echoes]:
		_echoes += 1
		play_pose(&"echo")  # A pale bark face lights and the echo rises out of it
		echo_requested.emit(self, _echoes)  # Remembering Oak: act 1's boss, then 2's, then 3's
	if enemy_data.bellow_count > 0 and not _bellowed and health <= max_health / 2:
		_bellowed = true
		bellow_requested.emit(self)
	if enemy_data.pack_regroup_at_half and not _regrouped and health <= max_health / 2:
		_regrouped = true  # Huntsman: The Kill (the spawner calls the whole pack back)
		brood_requested.emit(self)

# Blight Level `rises_from_blight`+ (the Hollow Oak remembers): the first dispel doesn't take; it
# rises again at half health with saplings twice as fast. True if it rose.
func _try_rise() -> bool:
	if _has_risen or enemy_data.rises_from_blight <= 0 or MetaRun.blight_level < enemy_data.rises_from_blight:
		return false
	_has_risen = true
	health = max_health / 2
	_sapling_speed = 2.0
	var tween := create_tween()
	tween.tween_method(_set_crack, 0.0, 0.7, CRACK_TIME)
	tween.tween_method(_set_crack, 0.7, 0.0, CRACK_TIME * 2)
	rose_again.emit(self)
	return true

# Soothes the blight away. `line` is the Warden family that soothed it ("" = neutral) and `is_area`
# whether it was an area hit (splash, pulse, cloud, Spored). Soothe = amount × family × shape ×
# Marked, then the blight coat takes its bite. At 0 health the enemy is cleansed.
# `source` (the Warden) and `tag` (&"spored" tick, &"static" bolt, &"conducted" lightning through
# Damp) feed the DamageLog; crit/weak/Marked/fog combos are worked out here.
# Soaked Rot (a Dream card) trades Soaked's water boost away (DreamState.soaked_boosts_water).
func _soaked_boosts_water() -> bool:
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState if is_inside_tree() else null
	return dreams == null or dreams.soaked_boosts_water()

var _batch_dreams: DreamState = null  # The run's DreamState, found on the first hit (performance: once, not per damage event)

func take_damage(amount: float, line: String = "", is_area: bool = false, is_crit: bool = false,
		source: Node = null, tag: StringName = &"") -> void:
	# (F1 lent × Calling, owner 2026-10-18; f1_spec.md) A Calling output's mark is taken here and cleared, so nothing this
	# hit sets off is marked; it is held in DamageLog.calling_now for this hit only (restored on every exit).
	var calling_here := DamageLog.calling_next
	DamageLog.calling_next = &""
	var calling_was := DamageLog.calling_now
	DamageLog.calling_now = calling_here
	_take_damage(amount, line, is_area, is_crit, source, tag)
	DamageLog.calling_now = calling_was

func _take_damage(amount: float, line: String, is_area: bool, is_crit: bool, source: Node, tag: StringName) -> void:
	if is_cleansed or _untouchable:  # (Night Mare lingering at the Heartwood: nothing touches it)
		return
	var shared := _shared_hit  # A Pall's half of its walker's blow: the walker's multipliers already counted
	if not shared and source is Tower and Reactions.is_effect(tag) and not tag in POTENCY_EXEMPT:
		amount *= Reactions.effect_multiplier(self, source, tag)  # Potency (and Seeping, not on a Reaction: its pool has it)
	if not shared:
		amount *= Reactions.chain_falloff(self, tag)  # Chain falloff: 6th link ×0.85, 7th ×0.70 … (floor 25%)
	# The run-shaping Dream cards that change damage by who deals it or where the nightmare stands (First Light,
	# Passing Thread, Hot on Their Heels, Long Way Round, Front Line): 1.0 with none taken (Roguelite Code).
	if _batch_dreams == null and is_inside_tree():
		_batch_dreams = get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState  # Looked up once, not per hit
	var batch_dreams := _batch_dreams if is_instance_valid(_batch_dreams) else null
	if batch_dreams != null and not shared:
		amount *= batch_dreams.batch_damage_multiplier(self, source, tag)
		amount *= batch_dreams.card_cap_factor(source, tag)  # Power budget (2026-10-16): non-Reaction card power on one hit stops at x4 (Roguelite Code)
	if is_crit:
		_crit_flash = CRIT_FLASH_TIME
		var world := Reactions._world(self)
		if world:
			Fx.crit(get_body_position(), world)  # The crit_flare glint, on the drawn body (drawn by the effects player)
	var family := 1.0  # No damage types since Nightmare Kinds (2026-10-15); only Soaked's water boost is left here
	if line == "water" and statuses.has(EnemyStatuses.DAMP) and _soaked_boosts_water():
		# Soaked conducts: water hits +20% (Damp's potency 1.5 with Soaked Through II: +30%)
		family *= 1.0 + statuses.soaked_bonus(EnemyStatuses.DAMP_WATER_BONUS * maxf(1.0, statuses.potency(EnemyStatuses.DAMP)))  # × the applier's Potency, capped
	var taken := statuses.get_damage_taken_multiplier() if not shared else 1.0
	if not shared and statuses.marked_bonus > 0.0:  # Bright Marks' share of this hit, for the Dream damage panel and the boost tiers
		DamageLog.note_card_bonus("bright_marks", statuses.bright_marks_multiplier())
	var soothe := amount * family * taken * (get_pack_multiplier() if not shared else 1.0)  # Huntsman: the pack shields him
	var soothe_before_coat := soothe
	_since_hit = 0.0  # Mourning Mother: Sorrow waits for a quiet moment
	_quiet_for = 0.0  # (Far LOD: a hit puts it back on every frame)
	sorrowing = false  # (Her walk comes back at once: update_animation)
	var pierce := pierce_coat_once
	pierce_coat_once = false
	if coat > 0.0 and soothe > 0.0 and not pierce:
		# Each hit loses up to _coat_per_hit (always keeping at least 1), never more than the coat has left.
		var soaked := minf(minf(_coat_per_hit, coat), soothe - minf(soothe, 1.0))
		var shell := batch_dreams.shell_multiplier(self, source) if batch_dreams != null else 1.0  # Wash Away: the shell takes double (Roguelite Code)
		coat -= minf(soaked * shell, coat)
		soothe -= soaked
		_hit_mark_wash = shell > 1.0
		if _hit_mark_wash:
			_mark_hit(-1)  # Wash Away wears it down twice as fast: a shell-chip puff in Dew-light on each such hit (its cue)
		if coat <= 0.0:
			coat = 0.0
			_mark_hit(-1)  # The crust crumbles off in a puff (Dew-light when Wash Away broke it)
			if enemy_data.cracked_frames != null:
				_swap_frames(enemy_data.cracked_frames)
	if soothe > 0.0 and _spawner != null and has_meta(DriftShapes.PACK_META):
		_spawner.note_pack_damage(self, source, soothe)  # (pack_wiped's top Warden)
	if covered_by != null and soothe > 0.0 and not shared:  # Pall: each blow shared half and half, after the shell
		if is_instance_valid(covered_by) and not covered_by.is_cleansed:
			var half := soothe * PALL_SHARE
			soothe -= half
			covered_by.take_shared(half, source, tag)
		else:
			covered_by = null
	_soothe_carry += soothe
	var whole := int(_soothe_carry)
	_soothe_carry -= whole
	var health_before := health
	health = maxi(health - whole, 1 if unkillable else 0)
	# Asleep is long but fragile: one hit (not an effect tick) of 10%+ of max health wakes it.
	if statuses.can_wake_from_hit() and not Reactions.is_effect(tag) \
			and soothe >= max_health * EnemyStatuses.WAKE_HIT_SHARE:
		statuses.sleep_time = 0.0
	# Big-hit feedback: the tier first, so DamageLog's number can read it (big_tier_now) while it reports this event
	# (Perf: a hit under a quarter of the Heavy share never counts, not even toward a merged blow: most hits stop here)
	var big := 0
	if soothe >= max_health * (BIG_HIT_BOSS_SHARES[0] if enemy_data.is_boss else BIG_HIT_SHARES[0]) * 0.25:
		big = _big_hit_tier(soothe, source, tag)
	big_tier_now = mini(big, 1) if int(Fx.setting("big_hits", 0)) == 1 else big
	_report_damage(amount, family, taken, soothe_before_coat - soothe, soothe, line, is_crit, source, tag,
		maxf(soothe - health_before, 0.0), is_area)
	big_tier_now = 0
	var share := soothe / maxf(max_health, 1.0)
	var hit_from: Vector2 = source.global_position if source is Node2D else NO_SOURCE
	if health == 0 and not _try_rise():
		if big > 0:
			_play_big_hit(big, share, hit_from, is_crit, true)  # A dispelling blow: the chips fly with the dispel crack
		_cleanse()
		return
	if soothe > 0.0:  # It felt that: a flinch (or a big hit), or (continuous sources) the sustained state their overlays hook
		if tag in SUSTAINED_TAGS:
			_note_sustained_tick(tag)
		elif big > 0:
			_play_big_hit(big, share, hit_from, is_crit, false)
		else:
			flinch(share, hit_from)
	_check_health_thresholds()
	if (enemy_data.charges_at_half or (enemy_data.trait_kind == EnemyData.Trait.TRAMPLE
			and enemy_data.straight_charge_tiles <= 0)) and not _startled and health <= max_health / 2:
		_startled = true  # The Hollow Stag's antlers flare and it charges (the Night Mare bolts)
		_charge_left = enemy_data.charge_time
		_speed_stale = true

# Applies a status from a Warden (`potency` = its soothe, see EnemyStatuses). A Static charge that
# fills up sets off a free bolt right away.
func apply_status(id: StringName, stacks: int = 1, duration: float = 0.0, potency: float = 0.0,
		max_stacks: int = 0, line: String = "", source: Node = null) -> void:
	if is_cleansed or _untouchable:
		return
	_quiet_for = 0.0  # (Far LOD: a Warden is on it)
	if id in statuses.immune or (rolling and id in enemy_data.immune_while_sprinting):
		_refuse_status(id)  # Night Hound: can't be Held mid-sprint
		return
	if id == EnemyStatuses.DROWSY:
		statuses.drowsy_cap_bonus = Reactions.drowsy_cap_bonus(self)  # Heavy Eyelids
	var was_held := statuses.is_held()
	if _batch_dreams == null and is_inside_tree():
		_batch_dreams = get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	if is_instance_valid(_batch_dreams) and _batch_dreams.wants_duration_hook():
		duration = _batch_dreams.class_duration(source, self, id, duration)  # Dewdrop's lingering cards (Roguelite Code): every application, carried ones too
	if stacks > 0 and is_instance_valid(_batch_dreams):
		stacks += _batch_dreams.role_cards.bound_stacks(self, id)  # Card pass 2026-10-16, Bound and Burning: +2 while Rooted (never Drowsy)
	var bolt := statuses.apply(id, stacks, duration, potency, max_stacks, line, source)  # (Bumps statuses.changes: the badges redraw)
	if enemy_data.drop_stacks > 0 and (id == EnemyStatuses.DAMP or id == EnemyStatuses.DROWSY):
		_check_wings()  # Gloamwing: heavy wings
	if id == EnemyStatuses.HELD and statuses.is_held() and not was_held:
		_spread_root_web(source)
	if bolt > 0.0:
		_bolt_flash = BOLT_FLASH_TIME
		# Static bolts count as light; a Lightning Rod nearby takes the bolt instead. Credited to the Warden
		# whose charge it was (EnemyStatuses.bolt_source), not the last stack's.
		var charger: Node = statuses.bolt_source if is_instance_valid(statuses.bolt_source) else source
		Reactions.strike_bolt(self, bolt, charger, &"static")
	if not is_cleansed and id in statuses.ALL:
		if is_instance_valid(_batch_dreams) and _batch_dreams.wants_reaction_hook():
			_batch_dreams.class_reaction(self, id, source)  # Old Rain / Never Quite Dry wrap the check (Roguelite Code)
		else:
			Reactions.on_status(self, id, source)  # Two statuses may meet: a Reaction

# --- Thin-family Dream cards (dream_design.md 2026-09-30; values from DreamState, via the spawner) ---

# Root Web: a nightmare that becomes Held holds the ones touching it (within ROOT_WEB_REACH tiles) for
# a share of its hold (bosses a smaller share). Never chains (a Root Web hold doesn't spread), and
# each nightmare takes part at most once per DreamState.ROOT_WEB_COOLDOWN.
func _spread_root_web(source: Node) -> void:
	if _web_holding or _spawner == null or _web_cooldown > 0.0 \
			or (_spawner.root_web_share <= 0.0 and _spawner.root_web_boss_share <= 0.0):
		return
	var held_for := statuses.time_left(EnemyStatuses.HELD)
	if held_for <= 0.0:
		return
	_web_cooldown = DreamState.ROOT_WEB_COOLDOWN
	for other in _others_within(ROOT_WEB_REACH):
		if other._web_cooldown > 0.0 or other.is_flying():
			continue
		var share: float = _spawner.root_web_boss_share if other.enemy_data.is_boss else _spawner.root_web_share
		if share <= 0.0:
			continue
		other._web_cooldown = DreamState.ROOT_WEB_COOLDOWN
		other._web_holding = true  # So its own hold doesn't spread on
		other.apply_status(EnemyStatuses.HELD, 1, held_for * share, 0.0, 0, "", source)
		other._web_holding = false

# Tangled Release: when a hold ends, the nightmare is pulled back along its route, as a pull by the
# Warden that held it (credited to it; Patient Roots adds for the Rootling line). That pull may set
# off Snare's hold ("the pull ends in a hold"), but a hold that came from a release pull never pulls
# again: at most hold → release pull → Snare hold → done (dream_design.md ruling, 2026-09-30).
func _on_hold_ended() -> void:
	var tiles: float = _spawner.release_pull if _spawner != null else 0.0
	var holder := _held_by as Tower
	_held_by = null
	if _release_spent:
		_release_spent = false  # This was the Snare hold after a release pull: it ends there
		return
	if tiles <= 0.0 or is_flying() or has_meta(&"tangled_released"):
		return  # Tangled Release: once per nightmare (card pass 2026-10-16: repeated holds were a hidden stall)
	set_meta(&"tangled_released", true)
	if enemy_data.is_boss:
		tiles *= 0.5  # Bosses half as far
	if holder == null or not is_instance_valid(holder):
		push_back(tiles * grid.cell_size.x)
		return
	holder.pull(self, tiles)
	var snare := holder.kin_share(&"snare", "a")
	if snare > 0.0 and not is_cleansed:
		_release_spent = true
		holder.hold(self, 0.5 * snare)  # As Tower's Rootling pull: Snare's hold is 0.5 s × its share
		if statuses.is_held():
			holder._kin_fired(&"snare")
		else:
			_release_spent = false  # The hold didn't take (immune): nothing to stop

# Lullaby: once a Dreamcatcher lets go, the nightmare stays Caught a little longer (once per catch).
func _on_caught_lapsed() -> void:
	var linger: float = _spawner.caught_linger if _spawner != null else 0.0
	if linger > 0.0 and not _lingered:
		_lingered = true
		statuses.caught_time = linger

# Tells the DamageLog what this hit did, with the combos that boosted it (see DamageLog).
func _report_damage(amount: float, family: float, taken: float, soaked: float, dealt: float, line: String,
		is_crit: bool, source: Node, tag: StringName, overkill: float = 0.0, is_area: bool = false) -> void:
	var damage_log := DamageLog.instance
	if damage_log == null:
		return
	var event := DamageLog.Event.new()
	event.source = source
	event.enemy = self
	event.calling = DamageLog.calling_now  # (F1 lent × Calling, owner 2026-10-18; f1_spec.md)
	event.kind =&"status" if tag == &"spored" else (&"bolt" if tag == &"static" else (&"pop" if tag == &"popped" else &"hit"))
	event.tag = tag
	if tag in REACTION_TAGS:
		event.kind = &"reaction"
	event.amount = dealt
	event.overkill = overkill  # Of `dealt`, the part past the health it had left (RunHistory counts effective damage)
	event.base = amount
	event.family_multiplier = family
	event.taken_multiplier = taken
	event.coat_soaked = soaked
	var factor := 1.0  # Multiplicative combos
	if is_crit and source is Tower:
		event.crit_multiplier = source.attack_data.crit_multiplier
		event.combos.append(&"crit")
		factor *= event.crit_multiplier
	if statuses.is_exposed():
		event.combos.append(&"marked")
		factor *= taken / (taken - EnemyStatuses.MARKED_EXTRA)
	if tag == &"spored" and statuses.is_in_fog():
		event.combos.append(&"fog")
		factor *= 1.0 + EnemyStatuses.FOG_SPORE_BONUS
	if tag == &"spored" and statuses.burn_time > 0.0 and statuses.burn_rate > 1.0:
		# Ignite's burn: Spored ticks burn_rate× as often, so (1 - 1/rate) of this tick is the Reaction's
		# (Balancing: the sims and "from combos" couldn't see it); still credited to the Spored applier.
		event.combos.append(&"ignite")
		factor *= statuses.burn_rate
	# Reaction damage, classified by tag first (card pass slice 1; RunHistory filed it all as combo, so runs showed
	# Reactions at 0-1%): a Reaction's own damage is all of it; Shatter, Pinned and Lightning Rod only their bonus on the
	# hit (Shatter's shards, an area hit, are all the Reaction's); Ignite's burn stays a Spored tick, its share through
	# the "ignite" combo above.
	if tag in REACTION_TAGS:
		var bonus: float = REACTION_BONUS_ONLY.get(tag, 0.0)
		if tag == &"pinned" and not is_area and statuses.star_pin_hit:
			bonus = Reactions.STAR_PIN_CRIT  # (council rx review 2026-10-17) a Falling Stars Pin's crit is x2, no payoff
			statuses.star_pin_hit = false
		elif bonus > 0.0 and tag != &"lightning_rod":
			bonus *= statuses.reaction_payoff(tag)  # Brimming's x2.2 only where this Reaction earned it (Reactions._decide_payoff)
		# (An area-tagged Shatter or Pinned event is its shards / pierce: all of it is the Reaction's; owner 2026-10-17 pierce.)
		event.reaction_amount = dealt * (1.0 - 1.0 / bonus) if bonus > 1.0 and not ((tag == &"shatter" or tag == &"pinned") and is_area) else dealt
	elif event.combos.has(&"ignite"):
		event.reaction_amount = dealt * (1.0 - 1.0 / statuses.burn_rate)
	if tag == &"conducted" or tag == &"static" or tag == &"popped" or tag in REACTION_TAGS:
		event.combos.append(tag)
		event.combo_amount = event.reaction_amount if tag in REACTION_TAGS else dealt  # The whole hit only happened thanks to the combo (a hit Reaction: its bonus)
	else:
		event.combo_amount = dealt * (1.0 - 1.0 / factor)
	event.card_damage = DamageLog.take_card_bonuses(dealt)  # What each card's multiplier added (DamageLog.note_card_bonus)
	recent_hits.append(event)
	if recent_hits.size() > RECENT_HITS:
		recent_hits.pop_front()
	damage_log.report(event)

# Removes the nightmare as if dispelled (Test Grove's "clear the field").
func dispel() -> void:
	if is_cleansed:
		return
	unkillable = false
	health = 0
	_cleanse()

func _mark_hit(kind: int) -> void:
	_hit_mark = kind
	_hit_mark_time = HIT_MARK_TIME

# Dispelled (story.md): a short shriek, the shape cracks with light, then bursts into motes that
# drift up (the Dew popup rises with them). It no longer blocks building or re-routes. Code keeps
# the old "cleanse" names; players only ever see "dispel".
func _cleanse() -> void:
	is_cleansed = true
	if covering != null and is_instance_valid(covering) and covering.covered_by == self:
		covering.covered_by = null  # A dispelled Pall lets its walker go
	covering = null
	if _hud_root.is_valid():
		RenderingServer.canvas_item_set_visible(_hud_root, false)  # No bars or badges on the way out
		_hud_shown = false
	_end_drag(false)
	remove_from_group(GROUP)
	# Great Dreamcatcher: a Caught nightmare (never a boss) leaves a Dreamlight shard.
	if statuses.caught_shard and statuses.is_caught() and not enemy_data.is_boss:
		var dreams := get_tree().get_first_node_in_group(DreamState.GROUP)
		if dreams and dreams.has_method("add_dreamlight_shard"):
			dreams.add_dreamlight_shard()
			Reactions._effect(&"dreamlight_shard", global_position, self, 1.0, 1.2)
			var catcher = statuses.caught_shard_tower
			if is_instance_valid(catcher) and catcher.has_signal("shard_dropped"):
				catcher.shard_dropped.emit(catcher, global_position)
	cleansed.emit(self)
	queue_redraw()
	sprite.self_modulate.a = 1.0  # A hidden nightmare shows itself as it cracks apart
	_refresh_display_settings()  # No outline while it cracks
	if _unbound_trail:
		_unbound_trail.emitting = false

	if _leap_tween:
		_leap_tween.kill()  # Dispelled mid-sink: surface right here to crack apart
		sprite.modulate.a = 1.0
		sprite.position.y = 0.0
		sprite.speed_scale = 1.0  # (A fitted burrow row may have sped it up)
	var base_scale := Vector2.ONE * enemy_data.sprite_scale * (ELITE_SCALE if elite else 1.0)
	sprite.scale = base_scale
	_squeeze = 1.0  # Dispelled in a gap: cracks apart at full width
	_shriek()
	var tween := create_tween()
	tween.tween_interval(SHRIEK_TIME)
	# Eased throughout (screens_ui.md a8471922: never linear): the crack and swell build in, the burst bursts out
	tween.tween_method(_set_crack, 0.0, 1.0, CRACK_TIME).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(sprite, "scale", base_scale * 1.12, CRACK_TIME).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(_burst_into_motes)
	tween.tween_property(sprite, "scale", base_scale * 1.35, BURST_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, BURST_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_interval(MOTE_LIFETIME)
	tween.tween_callback(queue_free)

# Hook for the dispel shriek / hiss sound (none yet). Visually: a quick, violent shudder.
func _shriek() -> void:
	if bool(Fx.setting("reduced_motion", false)):
		return  # Reduced motion: no shudder (the dispel keeps its timing: _cleanse waits SHRIEK_TIME either way)
	var tween := create_tween()
	for i in 4:
		tween.tween_property(sprite, "position:x", 2.5 if i % 2 == 0 else -2.5, SHRIEK_TIME / 5)
	tween.tween_property(sprite, "position:x", 0.0, SHRIEK_TIME / 5)

# The motes of light a dispelled nightmare breaks into. Bigger nightmares make more. Reduced motion: they fade where they
# appear (no burst outward, no drift). A boss (never an echo) gets its own beat (screens_ui.md a8471922): Tower Assets'
# boss_burst if it exists (else twice the motes, wider), and in the real game a hitstop and the largest camera rumble.
const BOSS_DISPEL_TRAUMA := 1.0
const MOTE_BURST_MAX := 8  # More dispels than this within EnemySpawner.DISPEL_BURST_WINDOW s: half the motes each (phone budget)
const BOSS_BURST := &"boss_burst"
func _burst_into_motes() -> void:
	var boss := enemy_data.is_boss and not is_echo
	var still := bool(Fx.setting("reduced_motion", false))
	var world := Reactions._world(self)
	var big_art := boss and world != null and Fx.has_effect(BOSS_BURST)
	if big_art:  # Tower Assets 1ae620ce: anchored on the body's centre
		var burst := Fx.play(BOSS_BURST, Tower.aim_at(self), world)
		if burst != null and Fx.reduce_flashes():
			# Reduce flashes: frames 2-3 are its flash (the sheet's note); jump from 2 to 4 just as 2 would show
			var fps := float(Fx.info(BOSS_BURST).get("fps", 14.0))
			get_tree().create_timer(1.95 / fps, false).timeout.connect(func() -> void:
				if is_instance_valid(burst):
					burst._age += 2.0 / fps)
	if boss and world != null and _spawner != null and _spawner.in_game:
		Fx._hitstop(world)
		NightmareOverlay.rumble(world, BOSS_DISPEL_TRAUMA)
	var burst_share := 0.5 if _spawner != null and _spawner.dispel_burst() > MOTE_BURST_MAX else 1.0  # A pack wiped at once: half each (phones)
	var amount := maxi(roundi(14 * maxf(sprite.scale.x, 1.0) * (2.0 if boss and not big_art else 1.0) * burst_share), 1)
	var motes: CPUParticles2D = _spawner.take_motes(amount, MOTE_COLOR) if _spawner != null else null  # (Pooled: perf 2026-10-25)
	var pooled := motes != null
	if not pooled:
		motes = CPUParticles2D.new()
		motes.one_shot = true
		motes.amount = amount
	motes.explosiveness = 0.9
	motes.lifetime = MOTE_LIFETIME
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	motes.emission_sphere_radius = 12.0 * sprite.scale.x * (1.5 if boss and not big_art else 1.0)
	motes.direction = Vector2.UP
	motes.spread = 180.0
	motes.initial_velocity_min = 0.0 if still else 30.0
	motes.initial_velocity_max = 0.0 if still else (110.0 if boss and not big_art else 75.0)
	motes.gravity = Vector2.ZERO if still else Vector2(0, -70)  # Motes drift up (not under reduced motion)
	motes.damping_min = 40.0
	motes.damping_max = 60.0
	motes.scale_amount_min = 2.0
	motes.scale_amount_max = 3.5
	if pooled:
		motes.global_position = global_position
		motes.restart()  # (Fires the burst again from here)
	else:
		var fade := Gradient.new()
		fade.set_color(0, MOTE_COLOR)
		fade.set_color(1, Color(MOTE_COLOR, 0.0))
		motes.color_ramp = fade
		add_child(motes)
	motes.emitting = true

# 0 = whole, 1 = cracked through with light (see shaders/blight.gdshader).
func _set_crack(amount: float) -> void:
	if _is_shared_material():
		if is_zero_approx(amount):
			return  # Whole already: the shared material says so
		sprite.material = sprite.material.duplicate()  # Its own copy, to crack apart on its own
	(sprite.material as ShaderMaterial).set_shader_parameter("crack", amount)


# Sets the cells to walk through (grid coordinates). The enemy heads to points[0] first.
func set_path(points: PackedVector2Array) -> void:
	_end_drag()  # A re-route mid-drag: it walks the new route from here
	_path = points
	if is_route_flyer() and is_flying():
		_air_route = points  # Its route in the air (a grounding rises back onto it, a Pall flies on along it)
	_waymark_index = _find_waymark_index()
	_path_serial += 1  # Per-route caches (turns, the walk target) rebuild
	_cells_left = PackedFloat32Array()
	_gap_step = -1  # A new route: the gap check looks again
	_path_index = 0
	if stream_speeding:
		stream_speeding = false  # Swift Stream: until it next reaches a cell on the new route
		_speed_stale = true
	if straight_charging:
		straight_charging = false  # Until it next reaches a cell on the new route
		_speed_stale = true

# Waymark: the first point of the route on the stone (-1: no stone, or a flyer's straight line of whole cells).
func _find_waymark_index() -> int:
	var map_generator = _map_generator()
	if map_generator == null or not map_generator.has_method("waymark_split") or not map_generator.has_waymark():
		return -1
	return map_generator.waymark_split(_path)

const WAYMARK_FLARE_COLOR := Palette.HEARTLIGHT  # The white flare at the stone
const WAYMARK_FLARE_FROM := 10.0  # px: the flare's ring grows from here
const WAYMARK_FLARE_GROW := 40.0
const WAYMARK_FLARE_TIME := 0.5

# It reached the stone: every status and buildup goes (the stone wins over "never fades"), with a white flare.
func _touch_waymark() -> void:
	passed_waymark = true
	var shed := statuses.shed_all()
	_hud_dirty = true
	_speed_stale = true
	if not _culled:  # (Every effects level: the flare is how the stone's rule reads)
		var world := Reactions._world(self)
		if world != null:
			var flare := Fx.FxRing.new(WAYMARK_FLARE_COLOR, WAYMARK_FLARE_FROM, WAYMARK_FLARE_GROW, WAYMARK_FLARE_TIME)
			world.add_child(flare)
			flare.global_position = global_position
	waymark_reached.emit(self, shed)

# Drags the nightmare back along the way it came by `pixels` (pulls, Whirligig gusts, the Tidecaller's
# wave): roots grab its feet, it slides back over a moment (ease-out, still facing forward), then walks
# on. A pull during a drag extends it. It can't go back past the start of its current route (routes
# restart at each re-route). Returns the pixels it will move.
func push_back(pixels: float) -> float:
	if is_cleansed or _leaping or _path.is_empty() or pixels <= 0.0:
		return 0.0
	var left := _drag_total - _drag_done if _dragging else 0.0
	var amount := minf(pixels, _room_behind() - left)
	if amount <= 0.0:
		return 0.0
	if not _dragging:
		_dragging = true
		_drag_reduced = bool(Fx.setting("reduced_motion", false))
		_grab_left = 0.0 if _drag_reduced else DRAG_GRAB
		_dust_left = DRAG_DUST_EVERY * 0.5
		if not _drag_reduced:
			_grab_fx = PullDragFx.grab(self)
		drag_started.emit(self, amount / grid.cell_size.x)
	# Start the ease again from here over what's left (a second pull extends the drag, no new grab).
	_drag_total = left + amount
	_drag_done = 0.0
	_drag_time = 0.0
	_drag_duration = _drag_seconds(_drag_total)
	return amount

func is_dragged() -> bool:
	return _dragging

func _drag_seconds(pixels: float) -> float:
	if _drag_reduced:
		return DRAG_REDUCED
	var seconds := DRAG_BASE + DRAG_PER_TILE * pixels / grid.cell_size.x
	return seconds * (DRAG_BOSS_SLOW if enemy_data != null and enemy_data.is_boss else 1.0)

# Pixels back to the start of the current route.
func _room_behind() -> float:
	if _path_index <= 0:
		return 0.0
	var room := position.distance_to(grid.calculate_map_position(_path[_path_index - 1]))
	for i in range(_path_index - 1, 0, -1):
		room += grid.calculate_map_position(_path[i]).distance_to(grid.calculate_map_position(_path[i - 1]))
	return room

func _update_drag(delta: float) -> void:
	if _grab_left > 0.0:
		_grab_left -= delta  # The roots take hold
		return
	_drag_time += delta
	var t := minf(_drag_time / maxf(_drag_duration, 0.01), 1.0)
	var eased := 1.0 - pow(1.0 - t, 3.0)  # Fast, then settling
	var step := _drag_total * eased - _drag_done
	var moved := _step_back(step) if step > 0.0 else 0.0
	_drag_done += moved
	if not _drag_reduced:
		sprite.rotation = sin(_drag_time * 28.0) * DRAG_WOBBLE * (1.0 - t)
		_dust_left -= moved
		if _dust_left <= 0.0:
			_dust_left = DRAG_DUST_EVERY
			PullDragFx.dust(self)
	if t >= 1.0 or moved < step - 0.01:
		_end_drag()

# Moves back along the route by `pixels` (the old instant push_back, now one frame's worth). Leaves a
# furrow on each cell it's dragged back onto. Returns the pixels moved.
func _step_back(pixels: float) -> float:
	var moved := 0.0
	while pixels > 0.0 and _path_index > 0:
		var previous := grid.calculate_map_position(_path[_path_index - 1])
		var distance := position.distance_to(previous)
		if distance > pixels:
			position = position.move_toward(previous, pixels)
			return moved + pixels
		position = previous
		moved += distance
		pixels -= distance
		_path_index -= 1  # Now walking back toward the cell it just stood on
		var along := previous - (grid.calculate_map_position(_path[_path_index - 1]) if _path_index > 0 else previous)
		PullDragFx.furrow(self, global_position, along)
	return moved

# Ends a drag: the roots sink (`release`) and it walks on at its current speed from the cell it's on.
func _end_drag(release: bool = true) -> void:
	if not _dragging:
		return
	_dragging = false
	_grab_left = 0.0
	_drag_total = 0.0
	_drag_done = 0.0
	if sprite:
		sprite.rotation = 0.0
	_speed_stale = true
	if _path_index > 0 and _path_index <= _path.size():
		_last_cell = _path[_path_index - 1]  # Restless: the cell it ended on, never a "turn back"
	if is_instance_valid(_grab_fx):
		if release and not is_cleansed:
			_grab_fx.release()  # The roots sink
		else:
			_grab_fx.queue_free()
	_grab_fx = null
	drag_ended.emit(self)

# Sleepwalk / Night Terror (Roguelite Code for the owner, 2026-10-17): the Sleepwalk Reaction (Reactions._sleepwalk) turns
# the nightmare round: for `sleepwalk_left` s it walks back up its current route toward the start at `sleepwalk_share` of
# its speed, then turns again and carries on. The timer runs only while it walks (held / asleep / dragged: it waits).
# At the start of its current route (a re-route restarts it there) it stands until the time is up. Never flyers.
var sleepwalk_left := 0.0
var sleepwalk_share := 0.5
var sleepwalk_rest := 0.0  # (council rx review 2026-10-17) Sleepwalk's cooldown, started when this walk ends (0 = a bump)

# (council rx review 2026-10-17) Never at the Heartwood, past the route's end, on the entry bridge or while waiting
# to set off: the walk's timer would never run there.
func can_walk_back() -> bool:
	return not at_heartwood and _path_index < _path.size() and _entry.is_empty() and hold_time <= 0.0

func sleepwalk(seconds: float, share: float, rest: float = 0.0) -> void:
	if is_cleansed or is_flying() or _leaping or seconds <= 0.0 or not can_walk_back():
		return
	sleepwalk_left = maxf(sleepwalk_left, seconds)
	sleepwalk_share = share
	sleepwalk_rest = maxf(sleepwalk_rest, rest)

func is_sleepwalking() -> bool:
	return sleepwalk_left > 0.0

func _walk_back(delta: float) -> void:
	sleepwalk_left = maxf(sleepwalk_left - delta, 0.0)
	var previous_position := position
	if statuses.changes != _speed_changes or _speed_stale or speed != _speed_base:  # (council rx review 2026-10-17: cached, as the forward walk)
		_speed_cache = get_move_speed()
		_speed_changes = statuses.changes
		_speed_stale = false
		_speed_base = speed
	var remaining := _speed_cache * sleepwalk_share * delta
	while remaining > 0.0 and _path_index > 0:
		var back := grid.calculate_map_position(_path[_path_index - 1])
		var distance := position.distance_to(back)
		if distance > remaining:
			position = position.move_toward(back, remaining)
			break
		position = back
		remaining -= distance
		_path_index -= 1  # Now walking back toward the point before it (as _step_back)
	if not _culled:
		update_animation(position - previous_position)
	if sleepwalk_left <= 0.0:
		_speed_stale = true
		if sleepwalk_rest > 0.0:  # (council rx review 2026-10-17) Sleepwalk's cooldown starts when the walk ends
			statuses.start_cooldown(&"sleepwalk", maxf(float(statuses.reaction_cooldowns.get(&"sleepwalk", 0.0)), sleepwalk_rest))
			sleepwalk_rest = 0.0
		if _path_index > 0 and _path_index <= _path.size():
			_last_cell = _path[_path_index - 1]  # Restless: the cell it turned on, never a "turn back"

# Changeling (Crowned Sleepwalk; owner 2026-10-17, council reactions_unique.md): this nightmare and `other` trade places,
# each taking the other's spot and its route from there (both walk valid routes on). Never a flyer, a leaping or dragged
# one. True if they traded.
func trade_places(other: Node2D) -> bool:
	if other == self or not is_instance_valid(other) or is_cleansed or other.is_cleansed or is_flying() or other.is_flying() \
			or _leaping or other._leaping or _dragging or other._dragging \
			or not can_walk_back() or not other.can_walk_back():  # (Enemy Code: never one on the bridge, at the Heartwood or waiting to set off; _entry isn't traded)
		return false
	var my_position := position
	var my_path := _path
	var my_index := _path_index
	var my_last := _last_cell
	var my_passed := passed_waymark
	_take_route(other.position, other._path, other._path_index, other._last_cell, other.passed_waymark)
	other._take_route(my_position, my_path, my_index, my_last, my_passed)
	return true

func _take_route(at: Vector2, points: PackedVector2Array, index: int, last: Vector2, passed := false) -> void:
	position = at
	_path = points
	_waymark_index = _find_waymark_index()
	passed_waymark = passed  # Waymark: the place it takes has (or hasn't) passed the stone
	_path_index = index
	_last_cell = last
	_path_serial += 1  # Per-route caches rebuild (each nightmare's own serial, never swapped)
	_cells_left = PackedFloat32Array()
	_gap_step = -1
	_speed_stale = true
	queue_redraw()

# Index into the current route of the cell the nightmare last stood on (or is standing on).
func get_route_index() -> int:
	return maxi(_path_index - 1, 0)

# The next `count` route cells the nightmare will walk through (Hollow Oak plants beside these).
func get_cells_ahead(count: int) -> PackedVector2Array:
	return _path.slice(_path_index, _path_index + count)

# Route cells behind the nightmare (the ones it already walked through on this route), oldest first.
func get_cells_behind() -> PackedVector2Array:
	return _path.slice(0, maxi(_path_index, 0))

# Sends the nightmare back to route cell `index` (must be behind it). Pond Keeper's grab.
func pull_back_to(index: int) -> void:
	if is_cleansed or _leaping or index < 0 or index >= _path_index:
		return
	position = grid.calculate_map_position(_path[index])
	_path_index = index + 1
	queue_redraw()

# The cell the enemy is currently walking toward. New paths should start from here so the enemy
# never cuts diagonally through a cell mid-step.
func get_target_cell() -> Vector2:
	if _path_index < _path.size():
		return _path[_path_index]
	return grid.calculate_grid_coordinates(position)

# The route point the body stands on now (half cells, documentation/half_cells.md: full-cell units,
# x.0 or x.5), for rooted / waiting cells and routing around them.
func get_route_point() -> Vector2:
	var p: Vector2 = (position - grid.cell_size / 2.0) / grid.cell_size.x
	# The nearer of the route points it walks between (whatever their encoding: x.0 / x.5 for a 2-half
	# body, x.25 / x.75 for a 1-half one); off a route, the nearest quarter (both encodings sit on it).
	if _path_index >= 1 and _path_index < _path.size():
		var from := _path[_path_index - 1]
		var to := _path[_path_index]
		return from if p.distance_squared_to(from) <= p.distance_squared_to(to) else to
	return Vector2(roundf(p.x * 4.0) / 4.0, roundf(p.y * 4.0) / 4.0)

# The length in cells of the route step that ends at path index `i` (half cells: 0.5; 1 on a full-cell
# route; 1 when there's no step to measure). Rules counted in cells (sprints, charges, leaps) use it.
func _step_cells(i: int) -> float:
	if i < 1 or i >= _path.size():
		i = 1
	if _path.size() < 2:
		return 1.0
	var length := _path[i].distance_to(_path[i - 1])
	return length if length > 0.01 else 1.0

# A route's length in cells (its first real step's size per step: 0.5 on half cells).
static func _route_cells(route: PackedVector2Array) -> float:
	for i in range(1, route.size()):
		var step := route[i].distance_to(route[i - 1])
		if step > 0.01:
			return (route.size() - 1) * step
	return float(maxi(route.size() - 1, 0))

# The cell the enemy is standing in right now.
func get_current_cell() -> Vector2:
	return grid.calculate_grid_coordinates(position)

# Pixels left to walk before reaching the goal. Lower = further ahead (used for "first" targeting).
func get_remaining_distance() -> float:
	if _path_index >= _path.size():
		return 0.0
	var to_next := position.distance_to(grid.calculate_map_position(_path[_path_index]))
	# The steps' real lengths (half cells: half a cell each; a flyer's straight line: its whole length)
	if _cells_left.size() != _path.size():
		_cells_left.resize(_path.size())
		var total := 0.0
		for i in range(_path.size() - 1, -1, -1):
			if i < _path.size() - 1:
				total += _path[i].distance_to(_path[i + 1])
			_cells_left[i] = total
	return to_next + _cells_left[_path_index] * grid.cell_size.x
