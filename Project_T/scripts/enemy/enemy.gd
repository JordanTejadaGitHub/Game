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
const ELITE_HAZE_COLOR := Color(Palette.DREAD, 0.32)
const ELITE_HAZE_RIM := Color(Palette.STONE, 0.16)  # Keeps the haze visible on dark ground
const ELITE_SWIRL_COLOR := Palette.MIST
const ELITE_OUTLINE_COLOR := Color(Palette.MOONLIGHT, 0.9)  # Setting "blight_outline" (accessibility)
const LEAP_TIME := 0.45  # Seconds to sink, move under the mire and rise again

# Group of nightmares that are still walking and targetable. Dispelled ones leave it.
const GROUP := "enemies"
const BLIGHT_SHADER := preload("res://shaders/blight.gdshader")
const HEALTH_BAR_SIZE := Vector2(40, 5)
const HEARTWOOD_DRAIN_EVERY := 2.0  # A boss at the Heartwood takes a leaf this often (s)
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

var health: int
var max_health: int
var speed: float
var is_cleansed := false
# Multiplies `enemy_data.health` (set before adding to the tree; drifts grow creatures this way).
var health_scale := 1.0
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
const BADGE_ORDER: Array[StringName] = [&"static", &"held", &"marked", &"spored", &"drowsy", &"damp"]
const VIEW_MARGIN := 96.0  # px past the screen edge where nightmares still draw (their badges overhang)
const HUD_TIME_FRAMES := 4  # The time bars under the icons are looked at every this many frames (_update_hud)
const TIME_BAR_GAP := 6.0  # Room under each icon for its time bar (px, above the health bar)
const TIME_BAR_HEIGHT := 3.0
# The HUD's canvas items (update_hud), each kind on its own z layer so the whole field batches.
enum { HUD_BARS, HUD_MARKS, HUD_ICONS, HUD_PILLS, HUD_TEXT }
const HUD_PASSES := [HUD_BARS, HUD_MARKS, HUD_ICONS, HUD_PILLS, HUD_TEXT]
const STATUS_DOT_RADIUS := 3.0  # Fallback when the icon sheet has no icon for a status
const STACK_FONT_SIZE := 16
const STACK_POP_TIME := 0.18  # An icon's quick scale bump when a stack is added
const STACK_POP_SCALE := 0.35  # …up to this much bigger
const STACK_PIP_MAX := 4.0  # Stack pips above an icon: at most this big (px), smaller when many
const BOLT_FLASH_TIME := 0.2
const HIT_MARK_TIME := 0.35  # Grey puff (resisted) / sparkle (weak) after a hit
# Damage that only happened because of a Reaction (DamageLog: whole-hit combos, event kind "reaction").
const REACTION_TAGS: Array[StringName] = [&"thunderclap", &"ignite", &"shatter", &"pinned", &"lightning_rod",
	&"dawnbreak", &"echo"]
const STATUS_FLASH_TIME := 0.3  # A status icon flashes when a combo uses it (see flash_status)
const COAT_COLOR := Palette.STONE
const CRIT_FLASH_TIME := 0.3  # Seconds a crit counts as "just happened" (the glint itself is Fx.crit)

var _crit_flash := 0.0
# Extra Dew when dispelled (Magpie Perch: +1 once it's been hit by a magpie).
var bonus_dew := 0
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
# Blight coat left to soak up, and soothe it takes off each hit (both already health-scaled).
var coat := 0.0
var coat_max := 0.0
var _coat_per_hit := 0.0
# Omen modifiers for this creature's drift (set before adding to the tree; bosses get none):
# {"speed", "coat", "dew", "status_duration": multiplier}. Split-off creatures inherit them.
var modifiers := {}

var elite := false  # Deeply Blighted (set before adding to the tree)
var _haze_phase := 0.0
# Cached display settings (Fx.setting): health bars at full health too ("health_bars" 1), and the
# elite outline ("blight_outline"). Re-read on the presence tick so the settings panel applies live.
var _bars_always := false
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
var straight_charging := false  # Hollow Stag: on a straight of straight_charge_tiles+ (see _update_straight_charge)
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
var restless := 0
var unbound := false
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
var _hud_items: Array[RID] = []
var _hud_shown := false
var _hud_scale := -1.0
# What the bars item shows (health, coat, Restless, bars always), and the marks item (statuses, time-bar steps)
var _hud_health := -2  # (Bar width in px; -1 = hidden)
var _hud_coat := -1
var _hud_restless := -1
var _hud_unbound := false
var _hud_always := false
var _hud_marks_key := -1
var _hud_stagger := randi() % 4  # So a crowd doesn't check its time bars on the same frame
var _hud_pops := {}  # {status id: seconds left of its icon's pop} (a stack was just added)
var _hud_popping := false
var _hud_flashing := false
var hud_builds := 0  # Items rebuilt (tests: only when something changed)
# The badge row, cached until statuses.changes moves (_update_hud_layout)
var _hud_changes := -1
var _hud_ids: Array = []
var _hud_stacks: Array[int] = []
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
var _hidden := false
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
var _path_index: int = 0

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_free_hud()  # Its HUD canvas items live in the RenderingServer, not in the tree

func _ready() -> void:
	add_to_group(GROUP)
	var parent := get_parent()
	if parent != null and parent.has_method("route_around"):
		_spawner = parent  # The EnemyContainer: its per-frame flags are read straight, no lookups by name

	# Initialize attributes
	max_health = maxi(roundi(enemy_data.health * health_scale * (ELITE_HEALTH if elite else 1.0)), 1)
	health = max_health
	speed = enemy_data.speed * modifiers.get("speed", 1.0)
	statuses.is_boss = enemy_data.is_boss
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
	coat_max = enemy_data.coat_total * health_scale * modifiers.get("coat", 1.0)
	coat = coat_max
	_coat_per_hit = enemy_data.coat_per_hit * health_scale * modifiers.get("coat", 1.0)

	# Set up animations
	sprite.sprite_frames = enemy_data.sprite_frames
	sprite.scale = Vector2.ONE * enemy_data.sprite_scale * (ELITE_SCALE if elite else 1.0)
	_measure_bar_offset()
	sprite.modulate = enemy_data.tint
	if is_echo:
		sprite.modulate.a *= ECHO_ALPHA  # A pale face from the Oak's bark
	sprite.play("walk_side")

	# Nightmare look: one material shared by every nightmare (so their sprites batch into few draw
	# calls); one cracking apart gets its own copy (_set_crack), outlined elites share a second one.
	sprite.material = _blight_material(false)

	_refresh_display_settings()
	_keep_always_statuses()
	if enemy_data.hidden:
		_set_hidden(true)  # Revealed on the first presence tick if something sees it

func _process(delta: float) -> void:
	if is_cleansed or (_path_index >= _path.size() and not at_heartwood):
		return

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
		_web_cooldown = maxf(_web_cooldown - delta, 0.0)
	elif statuses.marked_bonus != 0.0:
		statuses.marked_bonus = 0.0
	var spore_soothe := statuses.tick(delta)
	if thin:
		if was_caught and not statuses.is_caught():
			_on_caught_lapsed()
		_caught_left = statuses.caught_time
		if was_held and not statuses.is_held():
			_on_hold_ended()
			if is_cleansed:
				return
	if spore_soothe > 0.0:
		var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
		if dreams != null:
			spore_soothe *= dreams.get_spored_tick_multiplier(self)  # Damp Rot: harder on Soaked nightmares
		take_damage(spore_soothe, statuses.spore_line(), true, false, statuses.source(EnemyStatuses.SPORED),
			&"spored")
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
	if _pose_left > 0.0:
		_pose_left = maxf(_pose_left - delta, 0.0)
	if freeze_cooldown > 0.0:
		freeze_cooldown = maxf(freeze_cooldown - delta, 0.0)
	if push_cooldown > 0.0:
		push_cooldown = maxf(push_cooldown - delta, 0.0)
	# Smother's looping effect lasts while it's held with spores on it (Reactions): ended on the frame
	# tick() reports it stopping, and checked on each presence tick as well (_update_presence).
	if statuses.smother_ended:
		_end_smother_fx()
	# Its own drawing (the bars and badges are NightmareOverlay's): redrawn only for the Stag aura ring
	# or an animation that's playing (flashes, haze, embers, glow); off screen it waits until it's back.
	var aura := statuses.is_in_stag_aura()
	var animating := _bolt_flash > 0.0 or _shrug_flash > 0.0 or _hit_mark_time > 0.0 or elite or _crit_flash > 0.0 \
		or not _ash_cells.is_empty() or unbound
	if animating or _was_animating or aura != _drawn_aura:
		_drawn_aura = aura
		_redraw_pending = true  # (One more after an animation ends, to clear its last frame.)
	_was_animating = animating
	if _redraw_pending and _on_screen(self):
		_redraw_pending = false
		queue_redraw()
	_update_hud(delta)
	_update_presence(delta)

	if _dragging:
		_update_drag(delta)  # Pulled back: no walking, traits or trampling meanwhile
		return
	if at_heartwood:
		if _path_index < _path.size():
			at_heartwood = false  # Pulled back off the Heartwood, or re-routed: it walks in again
		else:
			_drain_left -= delta  # It stays, draining a leaf every HEARTWOOD_DRAIN_EVERY s
			if _drain_left <= 0.0:
				_drain_left = HEARTWOOD_DRAIN_EVERY
				heartwood_drained.emit(self)
			return
	if hold_time > 0.0:
		hold_time -= delta
		return
	if statuses.is_held() or statuses.is_asleep():
		return  # Frozen / rooted in place, or asleep (Drown)
	_charge_left = maxf(_charge_left - delta, 0.0)
	_update_trait(delta)
	if _leaping:
		return
	if _is_blocked_ahead(delta):
		return  # Rooted Nightmares: waiting for a Held nightmare in the next cell
	if unbound:
		_trample_ahead()

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
		var target := grid.calculate_map_position(_path[_path_index])
		var to_target := target - position
		var distance := to_target.length()
		if distance <= remaining:
			position = target
			remaining -= distance
			_path_index += 1
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
	update_animation(position - previous_position)

	if _path_index >= _path.size():
		if loops_route:
			_restart_route()
			return
		if enemy_data.laps():
			_lap()
			return
		if enemy_data.is_boss and not is_echo:
			at_heartwood = true  # Bosses stay (the timer keeps running if it's re-routed and walks back in)
			return
		reached_goal.emit(self)
		queue_free()

# Night Mare: the Heartwood loses its lap leaves (the spawner takes them) and the Mare gallops back to
# the start, faster each time.
func _lap() -> void:
	laps += 1
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
func flash_status(id: StringName) -> void:
	# Once per flash: combos fire on every tick and hit (a Marked, Spored nightmare reports "marked"
	# twice a second), and each flash spawns a world effect.
	if statuses.has(id) and not _status_flash.has(id):
		_status_flash[id] = STATUS_FLASH_TIME
		queue_redraw()
		var world := Reactions._world(self)
		if world:
			Fx.status_flash(id, global_position, world)

# Target Dummy: back to the forest's edge to walk the maze again.
func _restart_route() -> void:
	var map_generator = get_parent().get("map_generator")  # The EnemyContainer's
	var start: Vector2 = _path[0] if map_generator == null else map_generator.startPath
	var route: PackedVector2Array = _path if map_generator == null else map_generator.get_path_from(start)
	position = grid.calculate_map_position(start)
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
	if unbound:  # Cold ghost-fire glow behind the sprite, pulsing (no warm colour on nightmares)
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 150.0)
		draw_circle(Vector2(0, -8), 24.0 * sprite.scale.x, Color(UNBOUND_GLOW, 0.18 + 0.12 * pulse))
		draw_circle(Vector2(0, -8), 15.0 * sprite.scale.x, Color(Palette.MOONLIGHT, 0.22 + 0.12 * pulse))
	if elite:
		_draw_elite_haze()  # Drawn before the sprite (a child), so it sits behind it
	if _bolt_flash > 0.0:
		var t := _bolt_flash / BOLT_FLASH_TIME
		draw_circle(Vector2.ZERO, 26.0 * (1.5 - t), Color(Palette.GLOW, 0.5 * t))  # The Warden's bolt: warm light
	if _shrug_flash > 0.0:  # Barrow King: a ring of grave-dust out to the shrug's reach
		var t := _shrug_flash / SHRUG_FLASH_TIME
		draw_arc(Vector2.ZERO, enemy_data.shrug_radius * grid.cell_size.x * (1.0 - t * 0.6), 0.0, TAU, 48,
			Color(SHRUG_COLOR, 0.6 * t), 4.0)
	if enemy_data.pack_shield < 1.0 and pack_alive() > 0:  # Huntsman: the faint ring the pack keeps round him
		draw_arc(Vector2(0, -8), 30.0 * sprite.scale.x, 0.0, TAU, 32, Color(Palette.DEWLIGHT, 0.35), 2.0)
	if _hit_mark_time > 0.0:
		_draw_hit_mark(_hit_mark_time / HIT_MARK_TIME)
	if statuses.is_in_stag_aura():
		draw_arc(Vector2(0, 6), 18.0, 0.0, TAU, 24, Color(Palette.MOONLIGHT, 0.35), 2.0)
	# The health bar, coat, Restless arrows and status badges are in the HUD's own canvas items (update_hud).

# The HUD over this nightmare (health bar, blight coat, Restless arrows, status badges), in canvas
# items of its own under this node's (so they move with it, and the renderer culls them off screen):
# HUD_BARS, HUD_MARKS, HUD_ICONS, HUD_TEXT, each on its own absolute z layer (NightmareOverlay.Z +
# kind), so every nightmare's bars draw together, then every mark (time bars, glows: one atlas), every icon, every
# number: the field batches. Each item is rebuilt only when what it shows changes (checked from
# _process); freed with the nightmare. NightmareOverlay keeps the shared badge atlas.
func _update_hud(delta: float) -> void:
	var overlay: NightmareOverlay = _spawner.overlay if _spawner != null else null
	if overlay == null or overlay.badge_atlas == null:
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
	var text_scale := WorldLabel.text_scale(self)
	if text_scale != _hud_scale:  # The badges keep their screen size: scaled round the row's anchor
		_hud_scale = text_scale
		var badges := Transform2D(0.0, Vector2(text_scale, text_scale), 0.0, _hud_anchor())
		for kind in [HUD_MARKS, HUD_ICONS, HUD_PILLS, HUD_TEXT]:
			RenderingServer.canvas_item_set_transform(_hud_items[kind], badges)
	# The bars are keyed on their width in whole px (a smaller change can't be seen), -1 = not shown.
	var bar_px := int(HEALTH_BAR_SIZE.x * health / max_health) if health < max_health or _bars_always else -1
	var coat_px := int(HEALTH_BAR_SIZE.x * coat / maxf(coat_max, 1.0)) if coat > 0.0 else -1
	if bar_px != _hud_health or coat_px != _hud_coat or restless != _hud_restless or unbound != _hud_unbound \
			or _bars_always != _hud_always:
		_hud_health = bar_px
		_hud_coat = coat_px
		_hud_restless = restless
		_hud_unbound = unbound
		_hud_always = _bars_always
		_build_hud_bars(_hud_items[HUD_BARS])
		hud_builds += 1
	if _hud_ids.is_empty() and _hud_changes == statuses.changes:
		return  # No badges: nothing more to check
	var changed := _hud_changes != statuses.changes
	if changed:
		_update_hud_layout()
		_build_hud_pills(_hud_items[HUD_PILLS], overlay)
		_build_hud_text(_hud_items[HUD_TEXT])
	# A stack was just added: that icon pops (a quick scale bump), rebuilt each frame while it plays.
	if not _hud_pops.is_empty():
		for id in _hud_pops.keys():
			_hud_pops[id] -= delta
			if _hud_pops[id] <= 0.0:
				_hud_pops.erase(id)
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
	if marks_key != _hud_marks_key or flashing or _hud_flashing:
		_hud_marks_key = marks_key
		_hud_flashing = not _status_flash.is_empty()  # (One more once a flash ends, to clear it)
		_build_hud_marks(_hud_items[HUD_MARKS], overlay)
		hud_builds += 1

func _make_hud() -> void:
	_hud_root = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(_hud_root, get_canvas_item())  # Moves with the nightmare, no script
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
	_hud_shown = true
	_hud_scale = -1.0
	_hud_changes = -1
	_hud_health = -2  # Builds the bars on the first update

func _free_hud() -> void:
	if not _hud_root.is_valid():
		return
	for item in _hud_items:  # Children first, then the root
		if item.is_valid():
			RenderingServer.free_rid(item)
	_hud_items.clear()
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
	_hud_ids = get_badge_ids()
	for id in _hud_ids:
		if statuses.stacks(id) > int(before.get(id, 0)):
			_hud_pops[id] = STACK_POP_TIME
	_hud_stacks.clear()
	_hud_full.clear()
	_hud_colors.clear()
	_hud_icons.clear()
	for id in _hud_ids:
		var stacks := statuses.stacks(id)
		var cap := statuses.get_max_stacks(id)
		_hud_stacks.append(stacks)
		_hud_full.append(cap > 1 and stacks >= cap)
		_hud_colors.append(EnemyStatuses.COLORS.get(id, Palette.MOONLIGHT))
		_hud_icons.append(_status_icon(id))

# Status icon i's centre in the badge items' space (screen px round the anchor): a row of icons with
# room under each for its time bar.
func _badge_centre(i: int) -> Vector2:
	var r := get_badge_size() / 2.0
	var step := r * 2.0 + STATUS_BADGE_GAP
	var extra := statuses.count() - _hud_ids.size()
	var width := _hud_ids.size() * step - STATUS_BADGE_GAP + (step * 0.6 if extra > 0 else 0.0)
	return Vector2(-width / 2.0 + r + i * step, -r - TIME_BAR_GAP)

func _time_steps(i: int) -> int:
	return mini(ceili(statuses.time_share(_hud_ids[i]) * NightmareOverlay.TIME_STEPS), NightmareOverlay.TIME_STEPS)

func _build_hud_bars(item: RID) -> void:
	RenderingServer.canvas_item_clear(item)
	# Restless: a small backward arrow per stack, right of the health bar (red-hot once Unbound)
	for i in restless:
		var tip := _bar_offset + Vector2(HEALTH_BAR_SIZE.x / 2 + 5 + i * 6, 0)
		var arrow := PackedVector2Array([tip + Vector2(4, -3), tip, tip + Vector2(4, 3)])
		RenderingServer.canvas_item_add_polyline(item, arrow, PackedColorArray([Color(Palette.VOID, 0.8)]), 3.0)
		RenderingServer.canvas_item_add_polyline(item, arrow, PackedColorArray([UNBOUND_GLOW if unbound else RESTLESS_COLOR]), 1.5)
	# Health bar once the enemy has been hit, with the blight coat as a grey bar on top of it
	var bar := Rect2(_bar_offset - HEALTH_BAR_SIZE / 2, HEALTH_BAR_SIZE)
	if health < max_health or _bars_always:
		RenderingServer.canvas_item_add_rect(item, bar.grow(1), Color(Palette.VOID, 0.8))
		var fill := bar
		fill.size.x *= float(health) / max_health
		RenderingServer.canvas_item_add_rect(item, fill, Palette.SPRIG)  # The health bar is HUD, not the nightmare: green reads as health
	if coat > 0.0:
		var crust := Rect2(bar.position - Vector2(0, 4), Vector2(bar.size.x * coat / maxf(coat_max, 1.0), 3))
		RenderingServer.canvas_item_add_rect(item, crust.grow(1), Color(Palette.VOID, 0.8))
		RenderingServer.canvas_item_add_rect(item, crust, COAT_COLOR)

# The marks around the status icons, from NightmareOverlay's atlas: a soft gold glow behind an icon at
# max stacks, a row of pips above a stacking status's icon (one per stack it can hold, filled per
# stack, gold when full), a thin bar under each icon that shortens with the time left, a dot if the
# icon sheet has none, and the flash when a combo just used the status.
func _build_hud_marks(item: RID, overlay: NightmareOverlay) -> void:
	RenderingServer.canvas_item_clear(item)
	var atlas: Texture2D = overlay.badge_atlas
	var solid := overlay.badge_region(NightmareOverlay.MARK_SOLID)
	var dot := overlay.badge_region(NightmareOverlay.MARK_DOT)
	var r := get_badge_size() / 2.0
	for i in _hud_ids.size():
		var centre := _badge_centre(i)
		var color: Color = _hud_colors[i]
		var id: StringName = _hud_ids[i]
		if _hud_full[i]:  # At max stacks: a warm glow behind the icon
			var g := r * 1.7
			atlas.draw_rect_region(item, Rect2(centre - Vector2(g, g), Vector2(g, g) * 2.0),
				overlay.badge_region(NightmareOverlay.MARK_GLOW), Color(Palette.GOLD, 0.75))
		var cap := statuses.get_max_stacks(id)
		if cap > 1:  # Stack pips, centred over the icon
			var pip := minf(STACK_PIP_MAX, (r * 2.0 - (cap - 1)) / cap)
			var x := centre.x - (cap * pip + (cap - 1)) / 2.0
			var y := centre.y - r - pip - 2.0
			var lit: Color = Palette.GOLD if _hud_full[i] else color
			for k in cap:
				var at := Rect2(x + k * (pip + 1.0), y, pip, pip)
				atlas.draw_rect_region(item, at.grow(1.0), dot, Color(Palette.VOID, 0.8))
				atlas.draw_rect_region(item, at, dot, lit if k < _hud_stacks[i] else Color(color, 0.25))
		var bar := Rect2(centre + Vector2(-r * 0.8, r + 1.5), Vector2(r * 1.6, TIME_BAR_HEIGHT))
		atlas.draw_rect_region(item, bar.grow(1.0), solid, Color(Palette.VOID, 0.75))
		var steps := _time_steps(i)
		if steps > 0:
			bar.size.x *= float(steps) / NightmareOverlay.TIME_STEPS
			atlas.draw_rect_region(item, bar, solid, color)
		if _hud_icons[i] == null:
			RenderingServer.canvas_item_add_circle(item, centre, STATUS_DOT_RADIUS, color)
		if _status_flash.has(id):
			var f: float = _status_flash[id] / STATUS_FLASH_TIME  # 1 -> 0
			RenderingServer.canvas_item_add_circle(item, centre, r + 2.0 + 4.0 * (1.0 - f), Color(color, 0.5 * f))
			RenderingServer.canvas_item_add_circle(item, centre, r, Color(1, 1, 1, 0.45 * f))

# The bare pixel-art status icons, at the badge size (drawn nearest-neighbour: the icons' own look);
# an icon that just gained a stack pops (bigger, easing back over STACK_POP_TIME).
func _build_hud_icons(item: RID) -> void:
	RenderingServer.canvas_item_clear(item)
	for i in _hud_ids.size():
		var icon: Texture2D = _hud_icons[i]
		if icon == null:
			continue
		var s := get_badge_size()
		if _hud_pops.has(_hud_ids[i]):
			var t: float = 1.0 - _hud_pops[_hud_ids[i]] / STACK_POP_TIME  # 0 -> 1
			s *= 1.0 + STACK_POP_SCALE * sin(PI * t)
		icon.draw_rect(item, Rect2(_badge_centre(i) - Vector2(s, s) / 2.0, Vector2(s, s)), false)

# The dark pill behind each stack count (lower right of the icon, from 2 stacks).
func _build_hud_pills(item: RID, overlay: NightmareOverlay) -> void:
	RenderingServer.canvas_item_clear(item)
	var atlas: Texture2D = overlay.badge_atlas
	var pill := overlay.badge_region(NightmareOverlay.MARK_PILL)
	for i in _hud_ids.size():
		if _hud_stacks[i] > 1:
			atlas.draw_rect_region(item, _stack_pill(i), pill, Color(Palette.VOID, 0.9))

# Stack counts (bold, on their pills, from 2 stacks; gold at max) and "+N" past the last icon.
func _build_hud_text(item: RID) -> void:
	RenderingServer.canvas_item_clear(item)
	var r := get_badge_size() / 2.0
	for i in _hud_ids.size():
		if _hud_stacks[i] > 1:
			var text := str(_hud_stacks[i])
			var box := _stack_pill(i)
			var width := _stack_font_face().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, STACK_FONT_SIZE).x
			var baseline := Vector2(box.get_center().x - width / 2.0, box.get_center().y + STACK_FONT_SIZE * 0.35)
			_add_stack_text(item, baseline, text, Palette.GOLD if _hud_full[i] else Palette.MOONLIGHT)
	var extra := statuses.count() - _hud_ids.size()
	if extra > 0:
		var after := _badge_centre(_hud_ids.size() - 1) + Vector2(r + STATUS_BADGE_GAP, STACK_FONT_SIZE * 0.35)
		_add_stack_text(item, after, "+%d" % extra, Palette.MOONLIGHT)

# Icon i's stack-count pill: sized to its number, over the icon's lower-right corner.
func _stack_pill(i: int) -> Rect2:
	var r := get_badge_size() / 2.0
	var width := _stack_font_face().get_string_size(str(_hud_stacks[i]), HORIZONTAL_ALIGNMENT_LEFT, -1,
		STACK_FONT_SIZE).x + 8.0
	var height := STACK_FONT_SIZE + 2.0
	var corner := _badge_centre(i) + Vector2(r + 2.0, r + 1.0)  # The pill's lower-right corner
	return Rect2(corner - Vector2(maxf(width, height), height), Vector2(maxf(width, height), height))

# The stack-count font: NightmareOverlay's (an instance's, freed with the run: a Font kept in a static
# is freed after the TextServer at exit and crashes).
func _stack_font_face() -> Font:
	return _spawner.overlay.stack_font

func _add_stack_text(item: RID, at: Vector2, text: String, color: Color) -> void:
	var font := _stack_font_face()
	font.draw_string_outline(item, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, STACK_FONT_SIZE, 3, Palette.VOID)
	font.draw_string(item, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, STACK_FONT_SIZE, color)

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
	return not _view_rect.has_area() or _view_rect.has_point(node.global_position)
static var _view_frame := -1
static var _view_rect := Rect2()

# The statuses its badges show, most important first (BADGE_ORDER), at most STATUS_BADGES_MAX; the
# rest only count towards the "+N".
func get_badge_ids() -> Array:
	return get_status_order().slice(0, STATUS_BADGES_MAX)

# Every status it carries, most important first (the info panel lists them in this order).
func get_status_order() -> Array:
	var ids := statuses.active_ids()
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return _badge_rank(a) < _badge_rank(b))
	return ids

static func _badge_rank(id: StringName) -> int:
	var rank := BADGE_ORDER.find(id)
	return rank if rank >= 0 else BADGE_ORDER.size()

func get_badge_size() -> float:
	return STATUS_BADGE_BIG if enemy_data.is_boss or elite else STATUS_BADGE

# Deeply Blighted: soft puffs drifting slowly round the nightmare, and a swirl left of the health bar.
func _draw_elite_haze() -> void:
	var r := 18.0 * sprite.scale.x
	for i in ELITE_HAZE_PUFFS:
		var a := _haze_phase + TAU * i / ELITE_HAZE_PUFFS
		var at := Vector2(cos(a) * r, sin(a) * r * 0.5 - 8.0)  # Flattened ring round the body
		var size := (9.0 + 3.0 * sin(_haze_phase * 1.7 + i)) * sprite.scale.x
		draw_circle(at, size + 2.0, ELITE_HAZE_RIM)
		draw_circle(at, size, ELITE_HAZE_COLOR)
	var centre := _bar_offset + Vector2(-HEALTH_BAR_SIZE.x / 2 - 8.0, 0)
	var mark := _status_icon(&"elite")
	if mark != null:  # The sheet's Deeply Blighted icon; the drawn swirl otherwise
		draw_texture(mark, (centre - mark.get_size() / 2.0).round())
		return
	var swirl := PackedVector2Array()
	for s in 14:
		var t := s / 13.0
		swirl.append(centre + Vector2.from_angle(t * TAU * 1.6 + _haze_phase) * (1.0 + 4.0 * t))
	draw_circle(centre, 6.0, Color(Palette.VOID, 0.8))
	draw_polyline(swirl, ELITE_SWIRL_COLOR, 1.5)

# A small grey puff for a resisted hit, a little sparkle for a weak one. `t` fades 1 -> 0.
func _draw_hit_mark(t: float) -> void:
	var at := Vector2(10, -20)
	if _hit_mark < 0:
		for i in 3:
			var puff := at + Vector2.from_angle(TAU * i / 3.0) * 4.0 * (1.6 - t)
			draw_circle(puff, 3.5 * t + 1.0, Color(Palette.MIST, 0.7 * t))
	else:
		var r := 7.0 * (1.4 - t)
		var col := Color(Palette.GLOW, t)  # A Warden's hit: warm light
		draw_line(at + Vector2(-r, 0), at + Vector2(r, 0), col, 2.0)
		draw_line(at + Vector2(0, -r), at + Vector2(0, r), col, 2.0)

func update_animation(velocity: Vector2) -> void:
	# Keep the current animation when not moving (e.g. end of path) or while a pose plays
	if velocity.is_zero_approx() or _pose_left > 0.0:
		return
	var animation := &"walk_up"
	var flip := false
	if rolling and sprite.sprite_frames.has_animation(&"roll"):
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
	sprite.flip_h = flip

# Dew for dispelling this nightmare (Omens can change it, e.g. Dry Spell = 0).
func get_dew_reward() -> int:
	return roundi(enemy_data.dew_reward * modifiers.get("dew", 1.0)) * (ELITE_DEW if elite else 1) + bonus_dew

# Leaves lost when this nightmare reaches the Heartwood (Deeply Blighted cost at least 2).
func get_leaf_cost() -> int:
	return maxi(enemy_data.leaf_cost, ELITE_LEAVES) if elite else enemy_data.leaf_cost

func is_flying() -> bool:
	return enemy_data.trait_kind == EnemyData.Trait.FLYING

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
	if enemy_data.ash_trail_time > 0.0:
		_ash_cells[get_current_cell()] = enemy_data.ash_trail_time
	if enemy_data.straight_charge_tiles > 0:
		_update_straight_charge()
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
	rolling = _straight_steps >= enemy_data.roll_after_tiles and next_same
	_speed_stale = true

# Hollow Stag: charges along any straight of straight_charge_tiles+ path tiles (the whole straight,
# counting the tiles behind and ahead of it), and stops at the turn.
func _update_straight_charge() -> void:
	var was := straight_charging
	straight_charging = false
	if _path_index >= 1 and _path_index < _path.size():
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
		straight_charging = tiles >= enemy_data.straight_charge_tiles
	if straight_charging != was:
		_speed_stale = true

# Mire Hag: sinks into the mire and rises `leap_tiles` ahead along her path, then makes nightmares
# near where she rose Damp.
func _leap() -> void:
	if _path_index >= _path.size():
		return
	var landing_index := mini(_path_index + enemy_data.leap_tiles - 1, _path.size() - 1)
	var landing := grid.calculate_map_position(_path[landing_index])
	_sink_and_rise(landing, func() -> void:
		_path_index = landing_index + 1
		var reach := enemy_data.leap_splash_radius * grid.cell_size.x
		for creature in get_tree().get_nodes_in_group(GROUP):
			if creature.global_position.distance_to(global_position) <= reach:
				creature.apply_status(EnemyStatuses.DAMP)
		leaped.emit(self)
		if _path_index >= _path.size():
			reached_goal.emit(self)
			queue_free())

# Squashes flat into the ground and fades, moves to `landing` (pixels) while under, rises the same
# way back up, then calls `on_risen`. Not walking meanwhile (Mire Hag, Gravecrawler).
func _sink_and_rise(landing: Vector2, on_risen: Callable) -> void:
	_end_drag(false)
	_leaping = true
	if sprite.sprite_frames.has_animation(&"burrow"):
		_burrow_to(landing, on_risen)
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

# With burrow art (Gravecrawler): plays "burrow" to sink, moves while under, plays it backwards to
# surface, then calls on_risen.
func _burrow_to(landing: Vector2, on_risen: Callable) -> void:
	var length := _animation_length(&"burrow")
	sprite.play(&"burrow")
	var tween := create_tween()
	_leap_tween = tween
	tween.tween_interval(length)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.05)
	tween.tween_property(self, "position", landing, LEAP_TIME * 0.2)
	tween.tween_callback(func() -> void: sprite.play_backwards(&"burrow"))
	tween.tween_property(sprite, "modulate:a", 1.0, 0.05)
	tween.tween_interval(length)
	tween.tween_callback(func() -> void:
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
	if frames == null or not frames.has_animation(&"walk_side") or frames.get_frame_count(&"walk_side") == 0:
		return
	var texture := frames.get_frame_texture(&"walk_side", 0)
	var sheet: String = texture.atlas.resource_path if texture is AtlasTexture else texture.resource_path
	var bounds: Dictionary = _art_bounds().get(sheet.get_file().get_basename(), {})
	if bounds.has("top"):
		var top: float = float(bounds.top) * sprite.scale.y + sprite.position.y
		_bar_offset.y = minf(HEALTH_BAR_OFFSET.y, top - BAR_ABOVE_HEAD)

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
		sprite.play(&"walk_side")

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
	if _tower_cells().has(next):
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
	var holder = spawner.rooted_cells.get(next)
	if holder != null and holder != self and holder.has_meta(FinalTwists.LOGJAM_META):
		waiting = true  # Logjam: the ones behind a Snugroot hold queue, they don't path around it
		return true
	if holder != null and holder != self:
		_reroute_wait -= delta
		if _reroute_wait <= 0.0:
			_reroute_wait = REROUTE_RETRY
			var around: PackedVector2Array = spawner.route_around(get_current_cell())
			if not around.is_empty():
				set_path(around)  # Heads for this cell first (already here), then round the blocker
				_path_index = 1
				waiting = false
				return false
		waiting = true
		return true
	var queued = spawner.waiting_cells.get(next)
	waiting = queued != null and queued != self
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
	var best_route := PackedVector2Array()
	var best_length := _path.size() - _path_index - enemy_data.burrow_min_saving  # Cells to beat
	for direction in DIRECTIONS:
		var beyond := here + direction * 2
		if not walls.has(here + direction) or not _is_walkable(beyond, map_generator):
			continue
		var route: PackedVector2Array = map_generator.get_path_from(beyond)
		if not route.is_empty() and route.size() + 1 <= best_length:  # +1: the tunnel under the wall
			best_route = route
			best_length = route.size() + 1
	if best_route.is_empty():
		return
	_burrows += 1
	var surface := grid.calculate_map_position(best_route[0])
	_sink_and_rise(surface, func() -> void: set_path(best_route))

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
	var detour := pocket.duplicate()
	for i in range(pocket.size() - 2, -1, -1):
		detour.append(pocket[i])
	detour.append(here)
	detour.append_array(_path.slice(_path_index))
	set_path(detour)
	_wander_cooldown = enemy_data.wander_cooldown_cells

# Cells of a dead-end pocket starting next to `here` (off the route, one way in, at most
# `wander_depth` deep), from the entrance to the end. Empty if there's none.
func _find_dead_end(here: Vector2, map_generator: Node) -> PackedVector2Array:
	var on_route := {}
	for cell in _path:
		on_route[cell] = true
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
	return grid.is_within_bounds(cell) and not map_generator.path_layer.is_cell_blocked(cell)

# The map (through the EnemyContainer), or null outside the main scene.
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

	_revealed_time = maxf(_revealed_time - elapsed, 0.0)
	var hide := (enemy_data.hidden or _is_eclipsed()) and not _is_revealed()
	if hide != _hidden:
		_set_hidden(hide)
	_settings_elapsed += elapsed
	if _settings_elapsed >= SETTINGS_TICK:  # The settings panel's changes show within half a second
		_settings_elapsed = 0.0
		_refresh_display_settings()
	if enemy_data.wake_radius > 0.0:  # Watcher
		for other in _others_within(enemy_data.wake_radius):
			if other.statuses.has(EnemyStatuses.DROWSY):
				other.statuses.remove(EnemyStatuses.DROWSY)
				other.queue_redraw()
			if other.statuses.sleep_time > 0.0 and other.statuses.sleep_locked_time <= 0.0:
				other.statuses.sleep_time = 0.0  # Wakes sleepers too (not under Nightbloom's lock)
	_mend_stopped = maxf(_mend_stopped - elapsed, 0.0)
	if enemy_data.mend_radius > 0.0 and _mend_stopped <= 0.0:  # Weeper (a magpie can stop it)
		for other in _others_within(enemy_data.mend_radius):
			other.heal(other.max_health * enemy_data.mend_rate * elapsed)
	if not _ash_cells.is_empty():  # Ash Crawler
		for other in _field():
			if other != self and other.statuses.has(EnemyStatuses.SPORED) and _ash_cells.has(other.get_current_cell()):
				other.statuses.remove(EnemyStatuses.SPORED)
				other.queue_redraw()
	if enemy_data.brood != null:  # Moth Queen
		_brood_timer += elapsed
		if _brood_timer >= enemy_data.brood_interval:
			_brood_timer = 0.0
			brood_requested.emit(self)
	if enemy_data.sapling != null:  # Hollow Oak
		_sapling_timer += elapsed * _sapling_speed
		if _sapling_timer >= enemy_data.sapling_interval:
			_sapling_timer = 0.0
			sapling_requested.emit(self)
	_update_boss_pool_abilities(elapsed)

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

# Huntsman: the soothe share it takes while any of its hounds still hunts (1.0 once they're gone).
func get_pack_multiplier() -> float:
	if enemy_data.pack_shield >= 1.0:
		return 1.0
	for hound in pack:
		if is_instance_valid(hound) and not hound.is_cleansed:
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
	else:
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
func take_damage(amount: float, line: String = "", is_area: bool = false, is_crit: bool = false,
		source: Node = null, tag: StringName = &"") -> void:
	if is_cleansed:
		return
	if source is Tower and Reactions.is_effect(tag):
		amount *= Reactions.effect_multiplier(self, source)  # Potency (and Seeping)
	if is_crit:
		_crit_flash = CRIT_FLASH_TIME
		var world := Reactions._world(self)
		if world:
			Fx.crit(global_position, world)  # The crit_flare glint (drawn by the effects player)
	var family := enemy_data.get_soothe_multiplier(line, is_area)
	if line == "water" and statuses.has(EnemyStatuses.DAMP):
		# Soaked conducts: water hits +20% (Damp's potency 1.5 with Soaked Through II: +30%)
		family *= 1.0 + EnemyStatuses.DAMP_WATER_BONUS * maxf(1.0, statuses.potency(EnemyStatuses.DAMP))
	var taken := statuses.get_damage_taken_multiplier()
	var soothe := amount * family * taken * get_pack_multiplier()  # Huntsman: the pack shields him
	var soothe_before_coat := soothe
	_since_hit = 0.0  # Mourning Mother: Sorrow waits for a quiet moment
	sorrowing = false  # (Her walk comes back at once: update_animation)
	if line in enemy_data.resists:
		_mark_hit(-1)
	elif line in enemy_data.weak_to:
		_mark_hit(1)
	var pierce := pierce_coat_once
	pierce_coat_once = false
	if coat > 0.0 and soothe > 0.0 and not pierce:
		# Each hit loses up to _coat_per_hit (always keeping at least 1), never more than the coat has left.
		var soaked := minf(minf(_coat_per_hit, coat), soothe - minf(soothe, 1.0))
		coat -= soaked
		soothe -= soaked
		if coat <= 0.0:
			coat = 0.0
			_mark_hit(-1)  # The crust crumbles off in a puff
			if enemy_data.cracked_frames != null:
				_swap_frames(enemy_data.cracked_frames)
	_soothe_carry += soothe
	var whole := int(_soothe_carry)
	_soothe_carry -= whole
	health = maxi(health - whole, 1 if unkillable else 0)
	# Asleep is long but fragile: one hit (not an effect tick) of 10%+ of max health wakes it.
	if statuses.can_wake_from_hit() and not Reactions.is_effect(tag) \
			and soothe >= max_health * EnemyStatuses.WAKE_HIT_SHARE:
		statuses.sleep_time = 0.0
	_report_damage(amount, family, taken, soothe_before_coat - soothe, soothe, line, is_crit, source, tag)
	if health == 0 and not _try_rise():
		_cleanse()
		return
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
	if is_cleansed:
		return
	if id in statuses.immune or (rolling and id in enemy_data.immune_while_sprinting):
		_refuse_status(id)  # Night Hound: can't be Held mid-sprint
		return
	if id == EnemyStatuses.DROWSY:
		statuses.drowsy_cap_bonus = Reactions.drowsy_cap_bonus(self)  # Heavy Eyelids
	var was_held := statuses.is_held()
	var bolt := statuses.apply(id, stacks, duration, potency, max_stacks, line, source)  # (Bumps statuses.changes: the badges redraw)
	if id == EnemyStatuses.HELD and statuses.is_held() and not was_held:
		_spread_root_web(source)
	if bolt > 0.0:
		_bolt_flash = BOLT_FLASH_TIME
		# Static bolts count as light; a Lightning Rod nearby takes the bolt instead.
		Reactions.strike_bolt(self, bolt, source, &"static")
	if not is_cleansed and id in statuses.ALL:
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
	if tiles <= 0.0 or is_flying():
		return
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
		is_crit: bool, source: Node, tag: StringName) -> void:
	var damage_log := DamageLog.instance
	if damage_log == null:
		return
	var event := DamageLog.Event.new()
	event.source = source
	event.enemy = self
	event.kind = &"status" if tag == &"spored" else (&"bolt" if tag == &"static" else (&"pop" if tag == &"popped" else &"hit"))
	event.tag = tag
	if tag in REACTION_TAGS:
		event.kind = &"reaction"
	event.amount = dealt
	event.base = amount
	event.family_multiplier = family
	event.taken_multiplier = taken
	event.coat_soaked = soaked
	var factor := 1.0  # Multiplicative combos
	if is_crit and source is Tower:
		event.crit_multiplier = source.attack_data.crit_multiplier
		event.combos.append(&"crit")
		factor *= event.crit_multiplier
	if line in enemy_data.weak_to:
		event.combos.append(&"weak")
		factor *= EnemyData.WEAK_MULTIPLIER
	if statuses.has(EnemyStatuses.MARKED):
		event.combos.append(&"marked")
		factor *= taken / (taken - EnemyStatuses.MARKED_EXTRA)
	if tag == &"spored" and statuses.is_in_fog():
		event.combos.append(&"fog")
		factor *= 1.0 + EnemyStatuses.FOG_SPORE_BONUS
	if tag == &"conducted" or tag == &"static" or tag == &"popped" or tag in REACTION_TAGS:
		event.combos.append(tag)
		event.combo_amount = dealt  # The whole hit only happened thanks to the combo
	else:
		event.combo_amount = dealt * (1.0 - 1.0 / factor)
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
	var base_scale := Vector2.ONE * enemy_data.sprite_scale * (ELITE_SCALE if elite else 1.0)
	sprite.scale = base_scale
	_shriek()
	var tween := create_tween()
	tween.tween_interval(SHRIEK_TIME)
	tween.tween_method(_set_crack, 0.0, 1.0, CRACK_TIME).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "scale", base_scale * 1.12, CRACK_TIME)
	tween.tween_callback(_burst_into_motes)
	tween.tween_property(sprite, "scale", base_scale * 1.35, BURST_TIME).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, BURST_TIME)
	tween.tween_interval(MOTE_LIFETIME)
	tween.tween_callback(queue_free)

# Hook for the dispel shriek / hiss sound (none yet). Visually: a quick, violent shudder.
func _shriek() -> void:
	var tween := create_tween()
	for i in 4:
		tween.tween_property(sprite, "position:x", 2.5 if i % 2 == 0 else -2.5, SHRIEK_TIME / 5)
	tween.tween_property(sprite, "position:x", 0.0, SHRIEK_TIME / 5)

# The motes of light a dispelled nightmare breaks into. Bigger nightmares make more.
func _burst_into_motes() -> void:
	var motes := CPUParticles2D.new()
	motes.one_shot = true
	motes.explosiveness = 0.9
	motes.amount = roundi(14 * maxf(sprite.scale.x, 1.0))
	motes.lifetime = MOTE_LIFETIME
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	motes.emission_sphere_radius = 12.0 * sprite.scale.x
	motes.direction = Vector2.UP
	motes.spread = 180.0
	motes.initial_velocity_min = 30.0
	motes.initial_velocity_max = 75.0
	motes.gravity = Vector2(0, -70)  # Motes drift up
	motes.damping_min = 40.0
	motes.damping_max = 60.0
	motes.scale_amount_min = 2.0
	motes.scale_amount_max = 3.5
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
	_path_index = 0
	if straight_charging:
		straight_charging = false  # Until it next reaches a cell on the new route
		_speed_stale = true

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

# The cell the enemy is standing in right now.
func get_current_cell() -> Vector2:
	return grid.calculate_grid_coordinates(position)

# Pixels left to walk before reaching the goal. Lower = further ahead (used for "first" targeting).
func get_remaining_distance() -> float:
	if _path_index >= _path.size():
		return 0.0
	var to_next := position.distance_to(grid.calculate_map_position(_path[_path_index]))
	# Paths step one cell at a time, so every remaining step is one cell long.
	return to_next + (_path.size() - 1 - _path_index) * grid.cell_size.x
