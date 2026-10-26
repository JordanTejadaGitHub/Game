extends Node2D

# Spawns creatures and re-emits their signals, so listeners (RunState, DriftDirector) don't track
# individual enemies. When a creature that splits is cleansed, `enemy_split` fires for each child
# BEFORE `enemy_cleansed` fires for the parent, so drift bookkeeping never sees an empty drift early.
# Followers (a Mother Duck's Ducklings) are announced through `enemy_split` too: any creature that
# comes from another belongs to the same drift.
signal enemy_cleansed(enemy: Node2D)
signal enemy_reached_goal(enemy: Node2D)
signal enemy_split(parent: Node2D, child: Node2D)
# The Old Stag knocked a Thornwall down (it's gone for good; the path re-routes).
signal wall_trampled(cell: Vector2, by: Node2D)
# A nightmare shrugged off a status it's immune to (throttled per nightmare; see Enemy.status_refused).
signal status_refused(enemy: Node2D, status: StringName)
# No maze juggling (run_design.md): a re-route turned a nightmare back (stacks = its Restless now),
# and one reached 3 and turned Unbound (it ignores re-routes and tramples Wardens on its route).
signal nightmare_restless(enemy: Node2D, stacks: int)
signal nightmare_unbound(enemy: Node2D)

const SPLIT_SPACING := 14.0  # Pixels between creatures that pop out of a split
const GRIEF_RING := 40.0  # Pixels from the Hollow Oak that its Grief Mourners rise
const SAPLING_REACH := 10  # Route cells ahead of the Hollow Oak it may plant beside

# Seconds left of the Moth Queen's Eclipse (every nightmare but bosses hidden unless revealed).
var eclipse_left := 0.0
# Health scale of the latest drift's (non-boss) arrivals: what boss spawns (brood, Grief) grow by,
# since bosses themselves have a fixed health scale.
var drift_health_scale := 1.0
# …and that drift's DriftDirector.get_growth: the dread shell's per-hit soak for summons that don't pass their own.
var drift_coat_growth := 1.0
const ROOTED_RULE := &"rooted_nightmares"
var root_web_share := 0.0  # Root Web: touching nightmares are Held for this share of a hold
var root_web_boss_share := 0.0  # …and bosses for this share
var release_pull := 0.0  # Tangled Release: tiles pulled back when a hold ends
var caught_linger := 0.0  # Lullaby: seconds Caught lasts after leaving a Dreamcatcher
var marked_bonus := 0.0  # Bright Marks: added to Marked's extra damage taken
var overlay: NightmareOverlay  # Draws every nightmare's health bar and status badges (see NightmareOverlay)
var blight_materials := {}  # {outlined: ShaderMaterial} shared by the nightmares (Enemy._blight_material)
# Most nightmares on the field at once (platforms.md "Calling drifts early stacks them"): drifts
# called early stack, so the drift schedule holds new arrivals in the start mist while it's full
# (DriftDirector asks has_room). Split children, followers and summons still always come.
@export var max_field := 140  # PC (was 180: stacked late drifts still spiked at 3x)
# Mobile and Steam Deck get a lower cap (platforms.md; tuned when porting). The Deck export preset
# needs the custom feature tag "steamdeck".
@export var max_field_handheld := 110
# Leaves an act boss takes when it reaches the Heartwood, by act (1, 2, 3, …); then it's gone, a leak
# like any other. The Hollow Oak stays and drains instead (EnemyData.stays_at_heartwood), and the
# Night Mare runs its laps (balance_simulation.md 538b85b7).
@export var boss_bite_leaves: Array[int] = [6, 8, 10]  # Balancing 2026-10-19: was 10 / 10 / 12; a flat 10 ended runs at the act 1 boss after the base damage cut

# The bite for a boss in act `act` (the last entry for later acts).
func get_boss_bite(act: int) -> int:
	if boss_bite_leaves.is_empty():
		return 5
	return boss_bite_leaves[clampi(act - 1, 0, boss_bite_leaves.size() - 1)]

# The act `enemy` is in: its drift's, else the drift being played (tests, summons outside a drift).
func act_of(enemy: Node) -> int:
	var director = get_node_or_null("%DriftDirector")
	if director == null:
		return 1
	var number: int = director.drift_of(enemy)
	if number <= 0:
		number = maxi(director.drifts_started, 1)
	return director.get_act(number)
# For hidden nightmares' reveal checks (Enemy._is_revealed), kept here so a crowd of Lurkers doesn't
# each scan every Warden and every nightmare: {cell: Tower} for every Warden's cells, the Wardens that
# Mark (they reveal in their whole range), and the nightmares that reveal others (reveal_radius).
# Rebuilt when Wardens come or go, and every TOWER_LOOKUP_REFRESH s (evolving changes what they apply).
var tower_cells := {}
var marker_towers: Array = []
var revealers: Array = []
var _towers_dirty := true
var _revealers_dirty := true
var _tower_lookup_age := 0.0
const TOWER_LOOKUP_REFRESH := 0.5
var _lit := {}  # Rootlight's lit path tiles this frame ({cell: true}; is_lit)
var _lit_frame := -1
var thin_cards := false  # Any of the above owned (else nightmares skip their per-frame bookkeeping)
var rooted_cells := {}  # {cell: Held nightmare} (Rooted Nightmares; see _update_rooted_cells)
var _root_footprints: Array[Vector2] = []  # Actual blocked half cells; static ground cue.
var waiting_cells := {}  # {cell: nightmare waiting behind a rooted one}
# Boss pools (enemy_design.md): the Night Mare galloped round again (it took `leaves`); a Warden
# withered; a lantern was lit / snuffed.
signal enemy_lapped(enemy: Node2D, leaves: int)
# A boss staying at the Heartwood took `leaves` (every Enemy.HEARTWOOD_DRAIN_EVERY s until dispelled):
# for the boss bar ("At the Heartwood"), LeakEffect, the Heartwood's tremble, Sound and the drift's leak.
signal boss_drained(enemy: Node2D, leaves: int)
signal tower_withered(tower: Node2D, by: Node2D)
signal lantern_lit(lantern: Node2D)
signal lantern_snuffed(lantern: Node2D, by_player: bool)
var _lanterns: Array[ColdLantern] = []
var _dimmed := {}  # {Tower: true} Wardens a lantern slowed last frame (reset when out of the light)
var _last_withered := {}  # {Withering Oak: Tower it withered last}
var _saplings := {}  # {Hollow Oak: [cells it planted]}
var _sapling_sprites := {}  # {cell: AnimatedSprite2D} the saplings' grow / idle / wither animation

@export var enemy_scene: PackedScene = preload("res://scenes/enemy/enemy.tscn")  # The enemy scene to spawn

# Node references
@onready var map_generator = %MapGenerator
@onready var tower_container: Node2D = %TowerContainer

func _ready() -> void:
	if OS.has_feature("mobile") or OS.has_feature("steamdeck"):
		max_field = max_field_handheld
	# Every nightmare's bars and badges, from one canvas item (never a child of this node: its
	# children are all nightmares)
	overlay = NightmareOverlay.new()
	overlay.name = "NightmareOverlay"
	overlay.spawner = self
	(owner if owner != null else get_parent()).add_child.call_deferred(overlay)
	tower_container.child_entered_tree.connect(func(_node: Node) -> void: _towers_dirty = true)
	tower_container.child_exiting_tree.connect(func(_node: Node) -> void: _towers_dirty = true)
	child_entered_tree.connect(func(_node: Node) -> void: _revealers_dirty = true)
	child_exiting_tree.connect(func(_node: Node) -> void: _revealers_dirty = true)
	map_generator.path_changed.connect(_on_path_changed)
	map_generator.obstacle_cleared.connect(func(cell: Vector2, _data: ObstacleData) -> void: _wither_sprite(cell))

# Room for another scheduled arrival (fewer than max_field nightmares out, the dispelled ones fading
# away included: they still draw).
func has_room() -> bool:
	return get_child_count() < max_field

# Spawns a creature at the start of the maze. Returns it, or null if there's no route.
# `modifiers`: Omen multipliers for the creature (see Enemy.modifiers). `elite`: Deeply Blighted.
# Flyers float straight at the Heartwood; a Mother Duck brings her Ducklings in single file.
# `coat_growth`: DriftDirector.get_growth of its drift (the dread shell's per-hit soak; Enemy.coat_growth).
func spawn_enemy(enemy_data: EnemyData, health_scale: float = 1.0, modifiers: Dictionary = {},
		elite: bool = false, coat_growth: float = 1.0) -> Node2D:
	var path_points: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	if path_points.is_empty():
		return null
	if not enemy_data.is_boss:
		drift_health_scale = health_scale
		drift_coat_growth = coat_growth
	if enemy_data.trait_kind == EnemyData.Trait.FLYING and not enemy_data.flies_along_route:  # Moth Queen keeps the route
		path_points = _flight_path(enemy_data.flight_weave)
	var enemy := _create(enemy_data, health_scale, modifiers, elite, coat_growth)
	enemy.position = enemy.grid.calculate_map_position(path_points[0])  # Start at the first waypoint (pixels)
	enemy.set_path(path_points)
	var way_in := _way_in(enemy.position)
	if not way_in.is_empty():
		enemy.enter_along(way_in)  # Out of the fog and across the bridge first (flyers too: straight from the fog)
	_spawn_followers(enemy, path_points, way_in)
	if enemy_data.is_boss:
		_boss_arrives(enemy)
	return enemy

# A boss arriving (screens_ui.md a8471922): a cold pulse where it comes in and, in the real game, a short low rumble.
const BOSS_ARRIVE_TRAUMA := 0.3
func _boss_arrives(boss: Node2D) -> void:
	var world := Reactions._world(self)  # (Never under this node: its children are all nightmares)
	if world == null:
		return
	var pulse := Fx.FxRing.new(Palette.WRAITHLIGHT, 24.0, 56.0, 0.6)
	world.add_child(pulse)
	pulse.global_position = boss.global_position
	if in_game:
		NightmareOverlay.rumble(world, BOSS_ARRIVE_TRAUMA)

# The way in from the start's fog (StartGate.walk_in: fog, bridge landing, `first`), one straight line that ends
# on `first`, this nightmare's first route point in pixels (user 2026-10-12: no detour by the start cell's centre and
# back), or [] without a gate (the way in is the start itself).
func _way_in(first: Vector2) -> PackedVector2Array:
	var gate = map_generator.get("start_gate") if map_generator != null else null
	# The real game only (main.tscn running, like autosave): tests place and spawn nightmares by hand
	var playing := owner != null and is_inside_tree() and get_tree().current_scene == owner
	if gate == null or not (force_walk_in or playing):
		return PackedVector2Array()
	var points: PackedVector2Array = gate.walk_in(first)
	if points.is_empty():
		return points
	if points[points.size() - 1] != first:
		points.append(first)
	return points

static var force_walk_in := false  # Tests: walk in from the fog outside the real game too

func _create(enemy_data: EnemyData, health_scale: float, modifiers: Dictionary = {},
		elite: bool = false, coat_growth: float = -1.0) -> Node2D:
	return _create_prepared(enemy_scene.instantiate(), enemy_data, health_scale, modifiers, elite, coat_growth)

# _create for an enemy already instantiated (so flags like is_echo are set before its _ready).
# `coat_growth` < 0 = the latest drift's (drift_coat_growth).
func _create_prepared(enemy, enemy_data: EnemyData, health_scale: float, modifiers: Dictionary = {},
		elite: bool = false, coat_growth: float = -1.0) -> Node2D:
	enemy.enemy_data = enemy_data
	enemy.health_scale = health_scale
	enemy.coat_growth = coat_growth if coat_growth > 0.0 else drift_coat_growth
	enemy.modifiers = modifiers
	enemy.elite = elite
	enemy.cleansed.connect(_on_enemy_cleansed)
	enemy.reached_goal.connect(_on_enemy_reached_goal)
	enemy.trample_requested.connect(_on_trample_requested)
	enemy.brood_requested.connect(_on_brood_requested)
	enemy.eclipse_started.connect(func(_by: Node2D, seconds: float) -> void: eclipse_left = maxf(eclipse_left, seconds))
	enemy.sapling_requested.connect(_on_sapling_requested)
	enemy.grief_requested.connect(_on_grief_requested)
	enemy.status_refused.connect(status_refused.emit)
	enemy.trample_cell_requested.connect(_on_trample_cell_requested)
	enemy.lapped.connect(_on_lapped)
	enemy.heartwood_drained.connect(_on_heartwood_drained)
	enemy.bellow_requested.connect(_on_bellow_requested)
	enemy.lantern_requested.connect(_on_lantern_requested)
	enemy.wither_requested.connect(_on_wither_requested)
	enemy.echo_requested.connect(_on_echo_requested)
	add_child(enemy)
	return enemy

# A Mother Duck's Ducklings set off one after another right behind her. If she's cleansed while
# they're still walking, they get lost and slow down.
func _spawn_followers(leader: Node2D, path: PackedVector2Array, way_in: PackedVector2Array = PackedVector2Array()) -> void:
	var data: EnemyData = leader.enemy_data
	if data.followers == null or data.follower_count <= 0:
		return
	var followers: Array[Node2D] = []
	# A boss's followers (the Huntsman's hounds) grow with the drift like its escort, not its fixed scale.
	var scale: float = drift_health_scale if data.is_boss else leader.health_scale
	for i in data.follower_count:
		var follower := _create(data.followers, scale, leader.modifiers, false, leader.coat_growth)
		follower.position = leader.position
		follower.passed_waymark = leader.passed_waymark  # Waymark: on its leader's leg
		follower.set_path(path)
		follower.hold_time = data.follower_spacing * (i + 1)
		if not way_in.is_empty():
			follower.enter_along(way_in)  # Waits its hold_time in the fog, then crosses after the leader
		followers.append(follower)
		enemy_split.emit(leader, follower)
	leader.dew_followers.append_array(followers)  # They share half its Dew pot share (Enemy.set_dew_share)
	if data.pack_shield < 1.0:
		leader.pack.append_array(followers)  # Huntsman: they shield him while they hunt
	leader.cleansed.connect(func(_leader: Node2D) -> void:
		for follower in followers:
			if is_instance_valid(follower):
				follower.set_lost())

# Enemies still walking the maze. Cleansing enemies are excluded: they don't block building or re-route.
func get_enemies() -> Array[Node]:
	var enemies: Array[Node] = []
	for enemy in get_children():
		if not enemy.is_cleansed:
			enemies.append(enemy)
	return enemies

# Walking creatures that follow the maze (flyers float over it): these are the ones building must
# never cut off, and the ones that re-route.
func get_maze_walkers() -> Array[Node]:
	return get_enemies().filter(func(enemy: Node) -> bool: return not enemy.is_flying())

var hud_text_scale := 1.0  # WorldLabel.text_scale, once a frame for every nightmare's HUD (perf: was per nightmare)
var hud_frame := 0  # Engine.get_process_frames(), once a frame (the badges' staggered time-bar look)
# Low detail (EnvironmentTiles.low_detail: phones, or the setting), read once a frame: off-screen nightmares
# pause their cosmetics (animation, HUD, rounded corners); gameplay never. Desktop Full: always false.
var low_detail_now := false
# The settings every nightmare's lane and status row read each frame, read here once a frame (Fx.setting's own cache).
var reduced_motion_now := false
var status_icons_now := 1

# C4 "slow ripple" (visual_feedback_spec.md C1 / C4; Roguelite's DreamState.card_cue, 451495cb): when a card slows, holds,
# sleeps or pulls, a low ground ripple where it happened: the landing_dust sheet, small and tinted Heartlight (Dream's
# colour). SLOW_RIPPLE_PER_SECOND for the whole field; none at Reduced effects or off screen.
const SLOW_RIPPLE_EFFECT := &"landing_dust"
const SLOW_RIPPLE_SCALE := 0.8
const SLOW_RIPPLE_PER_SECOND := 6
var _ripple_times: Array[int] = []

func _on_card_cue(_card_id: StringName, cue: StringName, at: Vector2, _source: Node) -> void:
	if cue != &"slow_ripple" or Fx.reduced() or not Fx.on_screen(at):
		return
	var now := Time.get_ticks_msec()
	while not _ripple_times.is_empty() and now - _ripple_times[0] > 1000:
		_ripple_times.pop_front()
	if _ripple_times.size() >= SLOW_RIPPLE_PER_SECOND:
		return
	var world := Reactions._world(self)  # (Never under this node: its children are all nightmares)
	if world == null:
		return
	var ripple := Fx.play(SLOW_RIPPLE_EFFECT, at, world, SLOW_RIPPLE_SCALE)
	if ripple != null:
		_ripple_times.append(now)
		ripple.modulate = Color(Palette.HEARTLIGHT, 0.8)  # multiplier: Dream's warm tint on the dust

# Half-rate logic (perf, owner 2026-10-19): in the real game every nightmare ticks its statuses (and their hooks) and presence on
# every other frame (staggered, with the time between); walking, badges and looks every frame (Enemy._process). Tests get
# every frame unless they set force_lane (test_perf_stress does, to measure the game as it runs).
var half_rate_logic := false
# Half-rate looks (perf trial 2026-10-24, needs the owner's look in a real run): with the half-rate logic, each nightmare's
# walking lane and crowd row run on the frames between its logic frames. Dev flag `--full-rate-looks` turns it off.
var half_rate_looks := false
var _full_rate_looks := OS.get_cmdline_user_args().has("--full-rate-looks")
var force_lane := false
var in_game := false  # main.tscn is the running scene (not a test): the boss beats' hitstop and camera rumble
var walking_lanes := not OS.get_cmdline_user_args().has("--no-lanes")  # Dev flag (before/after captures): bodies on the centre line

func _process(delta: float) -> void:
	in_game = owner != null and get_tree().current_scene == owner
	half_rate_logic = force_lane or in_game
	half_rate_looks = half_rate_logic and not _full_rate_looks
	hud_text_scale = WorldLabel.text_scale(self)  # (The spawner processes before its children)
	hud_frame = Engine.get_process_frames()
	low_detail_now = EnvironmentTiles.low_detail()
	reduced_motion_now = bool(Fx.setting("reduced_motion", false))  # (Once a frame for every nightmare's lane and row: perf)
	status_icons_now = int(Fx.setting("status_icons", 1))
	eclipse_left = maxf(eclipse_left - delta, 0.0)
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	if dreams != null and not dreams.card_cue.is_connected(_on_card_cue):
		dreams.card_cue.connect(_on_card_cue)  # The C4 slow ripple (visual_feedback_spec.md C4)
	# Thin-family cards (dream_design.md 2026-09-30), read once a frame for every nightmare.
	root_web_share = dreams.get_root_web_share(false) if dreams != null else 0.0
	root_web_boss_share = dreams.get_root_web_share(true) if dreams != null else 0.0
	release_pull = dreams.get_release_pull() if dreams != null else 0.0
	caught_linger = dreams.get_caught_linger() if dreams != null else 0.0
	marked_bonus = dreams.get_marked_bonus() if dreams != null else 0.0
	thin_cards = root_web_share > 0.0 or root_web_boss_share > 0.0 or release_pull > 0.0 \
			or caught_linger > 0.0 or marked_bonus > 0.0
	_update_rooted_cells(dreams)
	_update_reveal_lookup(delta)
	_update_lantern_light()
	_jostle_lanes(delta)

# Walking lanes (enemy_design.md, visual only; retune: council 2026-10-24b): walkers within JOSTLE_REACH cell of each
# other ALONG THE ROUTE (their distance left to the Heartwood, so corners never false-trigger) on lanes closer than
# JOSTLE_LANES cell ease their lanes apart (Enemy.nudge_lane: the same speed cap, never past ±0.85). Buckets of
# JOSTLE_REACH by distance left; a walker is compared with its own bucket and the next, each pair once, every
# JOSTLE_EVERY frames. Reduced motion: none.
const JOSTLE_REACH := 0.55  # Cells along the route
const JOSTLE_LANES := 0.15  # Cells: lanes closer than this push
const JOSTLE_PUSH := 0.8  # Lane units a second
const JOSTLE_EVERY := 2
const SORT_REACH := 0.5  # Cells: drawn bodies this close y-sort by their drawn position (Enemy.sort_seen; perf 2026-10-25)
var _jostle_time := 0.0
# Status icons in crowds (enemy_design.md, owner 2026-10-24): a nightmare is crowded (Enemy.crowd_seen = crowd_clock) in a
# cluster (owner 2026-10-25: "more of a group then we can use pips", "it shouldn't be a row, it should only be a cluster",
# "make it 4 enemies together"; 2026-10-25 later: "switch the group pip to 8"): at least CROWD_GROUP_MIN - 1 other drawn
# bodies within CROWD_RADIUS cell of one; it and those neighbours go compact. A line in single file at its usual spacing
# isn't (one ahead, one behind). Checked on
# the jostle's frames (_mark_crowds); hud_focus = the nightmare the info panel shows (hovered / tapped: it keeps its full
# row; NightmareInfo sets it).
const CROWD_GROUP_MIN := 8  # Nightmares together, itself included (was 4)
const CROWD_RADIUS := 1.0  # Cells between drawn bodies
const CROWD_ROW_W := 28.0  # px: a crowd row (3 pips and the "more" dot)…
const CROWD_ROW_H := 8.0  # …and its height
var crowd_clock := 0.0
var hud_focus: Node2D = null

func _jostle_lanes(delta: float) -> void:
	_jostle_time += delta
	crowd_clock += delta
	if Engine.get_process_frames() % JOSTLE_EVERY != 0:
		return
	var step := _jostle_time
	_jostle_time = 0.0
	# Jostle pushes only with lanes on and no reduced motion; the crowd marks (compact status rows) always
	var push := walking_lanes and not reduced_motion_now
	var cell_px := 0.0
	# floor(distance left / reach) -> [[nightmare, distance left, drawn body, lane × width, flying], …]: each walker's
	# values once a pass, not once a pair (perf 2026-10-24: ~440 pairs a pass; nudge_lane moves only lane_target, so
	# the lane read here stays what every pair saw before)
	var buckets := {}
	var walkers: Array = []
	for enemy in get_children():
		if not enemy.has_method("nudge_lane") or enemy.is_cleansed or enemy._culled:
			continue
		if cell_px == 0.0:
			cell_px = enemy.grid.cell_size.x
		var left: float = enemy.get_remaining_distance()
		var flying: bool = enemy.is_flying()
		var one := [enemy, left, enemy.get_body_position(), enemy.lane * enemy.get_lane_width() if push and not flying else 0.0, flying]
		buckets.get_or_add(floori(left / (JOSTLE_REACH * cell_px)), []).append(one)
		walkers.append(one)
	if buckets.is_empty():
		return
	_mark_crowds(walkers, cell_px)  # The crowd marks (compact status rows) always, jostle or not
	var reach := JOSTLE_REACH * cell_px
	var sort_reach := SORT_REACH * cell_px
	for key in buckets:
		var here: Array = buckets[key]
		var next: Array = buckets.get(key + 1, [])
		for i in here.size():
			var one: Array = here[i]
			var left: float = one[1]
			for j in range(i + 1, here.size() + next.size()):
				var other: Array = here[j] if j < here.size() else next[j - here.size()]
				if absf(left - float(other[1])) <= reach:
					# Two drawn bodies this close sort by where they're drawn (Enemy._update_sort_look), statuses or not
					if (one[2] as Vector2).distance_squared_to(other[2]) < sort_reach * sort_reach:
						one[0].sort_seen = crowd_clock
						other[0].sort_seen = crowd_clock
					if push:
						_jostle_pair(one, other, cell_px, step, push)

# Crowd marks from the walkers of this pass ([[nightmare, distance left, drawn body, …], …]): a spatial hash on the drawn
# bodies, buckets CROWD_RADIUS cell wide, each body against the 3 × 3 buckets round it.
func _mark_crowds(walkers: Array, cell_px: float) -> void:
	if walkers.size() < CROWD_GROUP_MIN:
		return
	var reach := CROWD_RADIUS * cell_px
	var grid := {}
	for one in walkers:
		var body: Vector2 = one[2]
		grid.get_or_add(Vector2i(floori(body.x / reach), floori(body.y / reach)), []).append(one)
	for one in walkers:
		var body: Vector2 = one[2]
		var key := Vector2i(floori(body.x / reach), floori(body.y / reach))
		var near: Array = []
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				for other in grid.get(key + Vector2i(dx, dy), []):
					if other[0] != one[0] and body.distance_squared_to(other[2]) <= reach * reach:
						near.append(other)
		if near.size() < CROWD_GROUP_MIN - 1:
			continue
		one[0].crowd_seen = crowd_clock
		for other in near:
			other[0].crowd_seen = crowd_clock
			# Two crowd rows overlapping by more than half (UI council round 8): only the front nightmare's pips show
			var there: Vector2 = other[2]
			if absf(body.x - there.x) < CROWD_ROW_W / 2.0 and absf(body.y - there.y) < CROWD_ROW_H:
				(one[0] if body.y < there.y else other[0]).pips_hidden_seen = crowd_clock

func _jostle_pair(one: Array, two: Array, cell_px: float, step: float, push: bool) -> void:
	var a = one[0]
	var b = two[0]
	if not push or one[4] or two[4]:
		return
	var wa: float = one[3]
	var wb: float = two[3]
	if absf(wa - wb) > JOSTLE_LANES:
		return
	var away := signf(wa - wb) if wa != wb else (1.0 if a.get_instance_id() > b.get_instance_id() else -1.0)
	a.nudge_lane(away * JOSTLE_PUSH * step)
	b.nudge_lane(-away * JOSTLE_PUSH * step)

# Rooted Nightmares (Dream card 122): with the card, every Held maze walker blocks its cell for the
# others ({cell: nightmare}), and walkers waiting behind one block theirs so nobody stacks up. Rebuilt
# every frame before the nightmares move (they're this node's children). Empty without the card.
func _update_rooted_cells(dreams: DreamState = null) -> void:
	rooted_cells.clear()
	waiting_cells.clear()
	if dreams == null:
		dreams = get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	var rooted_rule := dreams != null and dreams.has_rule(ROOTED_RULE)
	# Also without the card: a walker Snugroot holds (Logjam, a final-form twist; FinalTwists marks it
	# FinalTwists.LOGJAM_META) blocks its cell, and the ones behind it queue (Enemy._is_blocked_ahead).
	for enemy in get_children():
		if enemy.is_cleansed or enemy.is_flying():
			continue
		if enemy.statuses.is_held():
			if rooted_rule or enemy.has_meta(FinalTwists.LOGJAM_META):
				rooted_cells[enemy.get_route_point()] = enemy
		elif enemy.waiting:
			waiting_cells[enemy.get_route_point()] = enemy

	var footprints: Array[Vector2] = []
	for point: Vector2 in rooted_cells:
		for half in _halves_under(point):
			if not footprints.has(half):
				footprints.append(half)
	if footprints != _root_footprints:
		_root_footprints = footprints
		queue_redraw()

func _draw() -> void:
	# Parent ground drawing stays beneath nightmare bodies; static in reduced motion.
	var half_size := Tower.MAP_GRID.cell_size / FindPath.HALF
	for half in _root_footprints:
		var at := to_local(half * half_size)
		var box := Rect2(at + Vector2.ONE * 2.0, half_size - Vector2.ONE * 4.0)
		draw_rect(box, Color(Palette.OAK, 0.18), true)
		draw_rect(box, Color(Palette.GOLD, 0.55), false, 2.0)
		# Crossed twigs distinguish these obstructions from build previews.
		draw_line(box.position + Vector2(4, 4), box.end - Vector2(4, 4), Color(Palette.OAK, 0.8), 2.0)
		draw_line(box.position + Vector2(box.size.x - 4, 4), box.position + Vector2(4, box.size.y - 4), Color(Palette.OAK, 0.8), 2.0)

# The reveal lookups (see tower_cells) go stale every TOWER_LOOKUP_REFRESH s (evolving changes what a
# Warden applies); coming and going marks them stale at once (signals in _ready).
func _update_reveal_lookup(delta: float) -> void:
	_tower_lookup_age += delta
	if _tower_lookup_age >= TOWER_LOOKUP_REFRESH:  # Evolving changes what a Warden applies
		_tower_lookup_age = 0.0
		_towers_dirty = true

# Rebuilds the reveal lookups that went stale (Wardens or nightmares came or went, or the refresh):
# Enemy._is_revealed calls it first, so a Warden planted this frame already counts.
func refresh_reveal_lookup() -> void:
	if _revealers_dirty:
		_revealers_dirty = false
		revealers.clear()
		for enemy in get_children():
			if enemy.enemy_data.reveal_radius > 0.0:
				revealers.append(enemy)
	if not _towers_dirty:
		return
	_towers_dirty = false
	tower_cells.clear()
	marker_towers.clear()
	for tower in tower_container.get_children():
		if not tower is Tower or tower.is_queued_for_deletion() or tower.attack_data == null:
			continue
		for cell in tower.get_cells():
			tower_cells[cell] = tower
		if tower.attack_data.applies_status == EnemyStatuses.MARKED:
			marker_towers.append(tower)

# Rootlight's lit path tiles stop burrowing (Gravecrawlers, the Burrowers Omen). Gathered from the
# Wardens at most once a frame, and only when someone asks.
func is_lit(cell: Vector2) -> bool:
	var frame := Engine.get_process_frames()
	if frame != _lit_frame:
		_lit_frame = frame
		_lit.clear()
		for tower in tower_container.get_children():
			var lit = tower.get("_lit_cells")
			if lit is Array:
				for at in lit:
					_lit[at] = true
	return _lit.has(cell)

# The Tramplers Omen (run_design.md "Omens with teeth"): the first nightmare of each drift to walk
# past a Thornwall tramples it, like the Hollow Stag (gone for good, no refund, everyone re-routes).
# OmenDirector.claim_trample(drift) lets only the first caller of each drift through.
func try_omen_trample(enemy: Node2D) -> void:
	var tower := _wall_beside(enemy)
	if tower == null:
		return
	var omens := get_tree().get_first_node_in_group(OmenDirector.GROUP) as OmenDirector
	var director = get_node_or_null("%DriftDirector")
	if omens == null or director == null or not omens.claim_trample(director.drift_of(enemy)):
		return
	_trample_tower(tower, tower.cell, enemy)
	_towers_dirty = true

# A route from `from` to the Heartwood that avoids every rooted cell (except `from` itself), without
# changing the map. Empty if the Held nightmares close every way (then the walker waits).
func route_around(from: Vector2, passed := false) -> PackedVector2Array:
	var closed: Array[Vector2] = []  # Half cells blocked here (and only those: restored after)
	for point: Vector2 in rooted_cells:
		if _bodies_overlap(point, from):
			continue
		for h in _halves_under(point):
			if not map_generator.path_layer.is_half_blocked(h):
				map_generator.path_layer.set_half_blocked(h, true)
				closed.append(h)
	var route: PackedVector2Array = map_generator.get_path_from(from, passed)  # (Waymark: the walker's own leg)
	for h in closed:
		map_generator.path_layer.set_half_blocked(h, false)
	return route

# The nightmare in `cells` (rooted_cells / waiting_cells, by route point) whose body would overlap one at
# `point` (half cells: bodies a cell wide overlap within a cell on both axes), other than `me`; or null.
func blocker_at(point: Vector2, me: Node, cells: Dictionary) -> Node:
	for at: Vector2 in cells:
		var who = cells[at]
		if who != me and is_instance_valid(who) and _bodies_overlap(at, point):
			return who
	return null

# The half cells a rooted body at route point `point` closes: those whose centres lie within half a cell
# of the body's centre on both axes. A 2-half body (x.0 / x.5 points) closes its 2×2; a 1-half body
# (x.25 / x.75, half_cells.md one-half gaps) just its own half.
static func _halves_under(point: Vector2) -> Array[Vector2]:
	var halves: Array[Vector2] = []
	var centre := point * FindPath.HALF + Vector2.ONE  # In half cells (pixel / 32): the body centre; half h's centre is h + 0.5
	for y in range(floori(centre.y - 1.0), floori(centre.y + 1.0) + 1):
		for x in range(floori(centre.x - 1.0), floori(centre.x + 1.0) + 1):
			if absf(x + 0.5 - centre.x) < 0.99 and absf(y + 0.5 - centre.y) < 0.99:
				halves.append(Vector2(x, y))
	return halves

static func _bodies_overlap(a: Vector2, b: Vector2) -> bool:
	return absf(a.x - b.x) < 0.99 and absf(a.y - b.y) < 0.99

# The full cells a body at each route point covers (x.5 → both neighbours): for things placed beside
# the route on whole cells (saplings, lanterns).
static func _body_cells(points: PackedVector2Array) -> Array[Vector2]:
	var cells: Array[Vector2] = []
	for p in points:
		for x in [floorf(p.x), ceilf(p.x)]:
			for y in [floorf(p.y), ceilf(p.y)]:
				var cell := Vector2(x, y)
				if not cells.has(cell):
					cells.append(cell)
	return cells

func _on_enemy_cleansed(enemy: Node2D) -> void:
	_wither_saplings(enemy)
	_snuff_lanterns_of(enemy)
	_split(enemy)
	enemy_cleansed.emit(enemy)
	_pack_member_gone(enemy, false)

# --- Pack wipes (enemy_design.md "Drift shapes", "More of the group wipe", council 2026-10-24c) ----------------------
# pack_formed(key, size): a pack's first member arrived (size = the arrivals it was shaped with; for "Packs wiped: N of
# M"). pack_wiped(key, size, centre, top_source): every member (its splitters' children and followers too) was
# dispelled, none leaked, the first to the last dispel within PACK_WIPE_WINDOW s; size = members dispelled (PACK_WIPE_MIN
# at least), centre = the mean of their dispel spots (world), top_source = the Warden (Tower) that dealt it the most
# damage, or null. Keys are DriftShapes.pack_key (Few and tough's shared key never counts as a pack).
# Pooled dispel motes (perf 2026-10-25): a dispel used to make a CPUParticles2D of its own (a wiped pack: up to 20 at
# once); the emitters are kept in the map (beside this container, never in it) and reused once their burst has played,
# keyed by particle count (changing `amount` reallocates). At most MOTE_POOL_MAX of a count are kept.
const MOTE_POOL_MAX := 24
var _mote_pool := {}  # amount -> [CPUParticles2D, …]
var _mote_ramp: Gradient = null

# A mote emitter of `amount` that isn't playing (new if none is free), in the map, ready for Enemy to set up and fire.
func take_motes(amount: int, colour: Color) -> CPUParticles2D:
	var pool: Array = _mote_pool.get_or_add(amount, [])
	for motes in pool:
		if is_instance_valid(motes) and not motes.emitting:
			return motes
	var world: Node = get_parent()
	if world == null:
		return null
	var made := CPUParticles2D.new()
	made.one_shot = true
	made.amount = amount
	if _mote_ramp == null:
		_mote_ramp = Gradient.new()
		_mote_ramp.set_color(0, colour)
		_mote_ramp.set_color(1, Color(colour, 0.0))
	made.color_ramp = _mote_ramp
	world.add_child(made)
	if pool.size() < MOTE_POOL_MAX:
		pool.append(made)
	else:
		made.finished.connect(made.queue_free)  # Past the pool's size: a one-off
	return made

# Phone budget: dispels counted over DISPEL_BURST_WINDOW s (Enemy halves its motes past MOTE_BURST_MAX).
const DISPEL_BURST_WINDOW := 0.5
var _dispel_times: Array[float] = []

# A dispel now: how many landed within DISPEL_BURST_WINDOW s, this one included.
func dispel_burst() -> int:
	while not _dispel_times.is_empty() and crowd_clock - _dispel_times[0] > DISPEL_BURST_WINDOW:
		_dispel_times.pop_front()
	_dispel_times.append(crowd_clock)
	return _dispel_times.size()

signal pack_formed(key: int, size: int)
signal pack_wiped(key: int, size: int, centre: Vector2, top_source: Node)
const PACK_WIPE_MIN := 4
const PACK_WIPE_WINDOW := 3.0
var _pack_book := {}  # key -> {"needed", "arrived", "alive", "dispelled", "leaked", "first", "last", "sum", "damage"}

# A pack member arrived (DriftShapes.tag_enemy: `arrival` true for the shaped arrival, false for a follower) or popped
# out of one (a split child).
func note_pack_member(enemy: Node, needed: int, arrival: bool) -> void:
	var key: int = enemy.get_meta(DriftShapes.PACK_META, -1)
	if key < 0 or key % 1000 == DriftShapes.TOUGH_PACK:
		return
	var book: Dictionary = _pack_book.get(key, {})
	if book.is_empty():
		book = {"needed": needed, "arrived": 0, "alive": 0, "dispelled": 0, "leaked": false, "first": -1.0, "last": -1.0,
			"sum": Vector2.ZERO, "damage": {}}
		_pack_book[key] = book
		pack_formed.emit(key, needed)
	book.alive += 1
	if arrival:
		book.arrived += 1

# A hit on a pack member (Enemy._take_damage): who dealt it, for pack_wiped's top_source.
func note_pack_damage(enemy: Node, source: Node, amount: float) -> void:
	var book: Dictionary = _pack_book.get(enemy.get_meta(DriftShapes.PACK_META, -1), {})
	if not book.is_empty() and source is Tower:
		book.damage[source] = float(book.damage.get(source, 0.0)) + amount

func _pack_member_gone(enemy: Node, leaked: bool) -> void:
	var key: int = enemy.get_meta(DriftShapes.PACK_META, -1)
	var book: Dictionary = _pack_book.get(key, {})
	if book.is_empty():
		return
	book.alive -= 1
	if leaked:
		book.leaked = true
	else:
		book.dispelled += 1
		book.sum += enemy.global_position
		if book.first < 0.0:
			book.first = crowd_clock
		book.last = crowd_clock
	if book.alive > 0 or book.arrived < book.needed:
		return
	_pack_book.erase(key)
	if book.leaked or book.dispelled < PACK_WIPE_MIN or book.last - book.first > PACK_WIPE_WINDOW:
		return
	var top: Node = null
	for source in book.damage:
		if is_instance_valid(source) and (top == null or book.damage[source] > book.damage[top]):
			top = source
	_play_pack_bloom(book.sum / book.dispelled, book.dispelled)
	pack_wiped.emit(key, book.dispelled, book.sum / book.dispelled, top)

# Enemy Assets' pack_bloom (8b812626) where a pack was wiped: warm light lying on the ground, 80% (a multiplier), scale
# 1.0 for up to 8 members and 1.5 for bigger packs (whole steps keep the pixels crisp), above the ground and under the
# Dew popup and callouts. Reduced motion: its "still" frame fading out over PACK_BLOOM_FADE s.
const PACK_BLOOM_FRAMES := "res://animation/enemy/pack_bloom.tres"
const PACK_BLOOM_ALPHA := 0.8
const PACK_BLOOM_BIG := 9  # Members from which it plays at 1.5
const PACK_BLOOM_FADE := 0.4
const PACK_BLOOM_Z := 2  # Above the ground and the walkers' y-sort, below popups and callouts

func _play_pack_bloom(centre: Vector2, size: int) -> void:
	var world: Node = owner if owner != null else get_parent()
	if world == null or not ResourceLoader.exists(PACK_BLOOM_FRAMES):
		return
	var bloom := AnimatedSprite2D.new()
	bloom.sprite_frames = load(PACK_BLOOM_FRAMES)
	bloom.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bloom.modulate = Color(1, 1, 1, PACK_BLOOM_ALPHA)  # multiplier
	bloom.scale = Vector2.ONE * (1.5 if size >= PACK_BLOOM_BIG else 1.0)
	bloom.z_index = PACK_BLOOM_Z
	world.add_child(bloom)
	bloom.global_position = centre
	if bool(Fx.setting("reduced_motion", false)) and bloom.sprite_frames.has_animation(&"still"):
		bloom.play(&"still")
		var fade := bloom.create_tween()
		fade.tween_property(bloom, "modulate:a", 0.0, PACK_BLOOM_FADE)
		fade.tween_callback(bloom.queue_free)
	else:
		bloom.play(&"bloom")
		bloom.animation_finished.connect(bloom.queue_free)

# Pops `split_count` `split_into` creatures out where `parent` was, lined up behind it on its route.
func _split(parent: Node2D) -> void:
	var data: EnemyData = parent.enemy_data
	if data.split_into == null or data.split_count <= 0:
		return
	var path: PackedVector2Array = map_generator.get_path_from(parent.get_target_cell(), parent.passed_waymark)
	if path.is_empty():
		return
	var ahead: Vector2 = parent.grid.calculate_map_position(path[0]) - parent.position
	var back := -ahead.normalized() if not ahead.is_zero_approx() else Vector2.ZERO
	# The Dew pot: the children share 60% of the parent's share, the parent keeps 40% (paid just after
	# this, when enemy_cleansed goes out).
	var share: float = parent.dew_share
	var child_share: float = share * parent.SPLIT_CHILDREN_DEW_SHARE / data.split_count if share >= 0.0 else -1.0
	if share >= 0.0:
		parent.dew_share = share * (1.0 - parent.SPLIT_CHILDREN_DEW_SHARE)
	for i in data.split_count:
		var child := _create(data.split_into, parent.health_scale, parent.modifiers, false, parent.coat_growth)
		child.position = parent.position + back * SPLIT_SPACING * i
		child.passed_waymark = parent.passed_waymark  # Waymark: it carries on the leg its parent was on
		if parent.has_meta(DriftShapes.PACK_META):
			child.set_meta(DriftShapes.PACK_META, parent.get_meta(DriftShapes.PACK_META))  # Its leak counts toward the pack's cap
			child.set_meta(DriftShapes.PACK_LIMIT_META, parent.get_meta(DriftShapes.PACK_LIMIT_META, DriftShapes.PACK_LEAVES))
			note_pack_member(child, 0, false)  # Its pack waits for it too (pack_wiped)
		child.set_path(_flight_from(child) if _flies_straight(data.split_into) else path)
		if child_share >= 0.0:
			child.dew_share = child_share
		enemy_split.emit(parent, child)

# Flyers that burst out mid-maze (the Scarecrow's Crows) fly straight at the Heartwood from there.
func _flies_straight(data: EnemyData) -> bool:
	return data.trait_kind == EnemyData.Trait.FLYING and not data.flies_along_route

func _flight_from(enemy: Node2D) -> PackedVector2Array:
	return PackedVector2Array([enemy.grid.calculate_grid_coordinates(enemy.position), map_generator.endPath])

# `count` `data` lined up behind the start, walking in one after another (the Hollow Stag's bellow,
# the Night Mare's Shades).
func _run_from_start(data: EnemyData, count: int, parent: Node2D) -> void:
	var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	if data == null or count <= 0 or path.is_empty():
		return
	var first: Vector2 = parent.grid.calculate_map_position(path[0])
	var ahead: Vector2 = parent.grid.calculate_map_position(path[1]) - first if path.size() > 1 else Vector2.RIGHT
	var back := -ahead.normalized()
	for i in count:
		var child := _create(data, drift_health_scale, parent.modifiers)
		child.dew_share = 0.0  # A summon: its summoner's Dew share pays for the fight (the Dew pot)
		child.position = first + back * SPLIT_SPACING * (i + 1)
		child.set_path(path)
		enemy_split.emit(parent, child)

# Hollow Stag at half health: it bellows and its bellow_spawn run from the start.
func _on_bellow_requested(stag: Node2D) -> void:
	_run_from_start(stag.enemy_data.bellow_spawn, stag.enemy_data.bellow_count, stag)

# Old Stag: knocks down a Thornwall (or Bramble) next to it. The wall is gone for good, with no
# refund; opening a cell never breaks the path rule, and everyone re-routes.
func _on_trample_requested(enemy: Node2D) -> void:
	var tower := _wall_beside(enemy)
	if tower != null:
		_trample_tower(tower, tower.cell, enemy)
		enemy.trampled()

# An Unbound nightmare walks into a Warden on its route: any Warden, trampled (Weathered Walls
# doesn't save it; nothing blocks an Unbound nightmare).
func _on_trample_cell_requested(enemy: Node2D, cell: Vector2) -> void:
	var tower := tower_at_point(cell)
	if tower == null:
		return
	if _shelters(tower):  # A wall it can't pass: it finds a way round from where it stands
		var around: PackedVector2Array = map_generator.get_path_from(enemy.get_route_point(), enemy.passed_waymark)
		if not around.is_empty():
			enemy.set_path(around)
		return
	_trample_tower(tower, tower.cell, enemy)

# Shelter (Tower Code's rank V signature, warden_stats.md 96d728dd): a Warden inside a Shelter support's aura
# can't be trampled (the Stag, the Tramplers Omen, Unbound). True if `tower` is sheltered; then the
# signature's callout fires (at most once every SHELTER_CALLOUT_MS per Warden).
const SHELTER_CALLOUT_MS := 3000
var _shelter_said := {}  # Warden instance id -> msec of its last Shelter callout

func _shelters(tower: Tower) -> bool:
	if not tower.has_method("is_sheltered") or not tower.is_sheltered():
		return false
	var id := tower.get_instance_id()
	var now := Time.get_ticks_msec()
	if now - int(_shelter_said.get(id, -SHELTER_CALLOUT_MS)) >= SHELTER_CALLOUT_MS:
		_shelter_said[id] = now
		tower.signature_fired.emit(tower, Signatures.SHELTER)
	return true

# The wall Warden (Thornwall line) beside a walker: one whose footprint takes a half cell up to a cell
# from the walker's own half, left, right, up or down, nearest first (half cells: walls may sit at half
# offsets and bodies walk one half). Rampart's stone walls hold. null if none.
func _wall_beside(enemy: Node2D) -> Tower:
	var half_px: float = enemy.grid.cell_size.x / FindPath.HALF
	var here: Vector2 = (enemy.position / half_px).floor()
	var by_half := {}
	for tower in tower_container.get_children():
		if tower is Tower and not tower.is_queued_for_deletion() and tower.tower_data.line == "wall" \
				and not BranchKit.is_stone(tower):
			for half in tower.get_halves():
				by_half[half] = tower
	var sheltered := {}  # Walls in a Shelter aura in reach: skipped (it looks for another), called out once each
	for reach in [1, 2]:
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var tower = by_half.get(here + offset * reach)
			if tower == null or sheltered.has(tower):
				continue
			if _shelters(tower):
				sheltered[tower] = true
				continue
			return tower
	return null

# The Warden whose footprint takes route point `point`'s half cell (half cells: Wardens may sit at
# half offsets), or null.
func tower_at_point(point: Vector2) -> Tower:
	var half := Vector2(FindPath.point_to_node(point))
	for tower in tower_container.get_children():
		if tower is Tower and not tower.is_queued_for_deletion() and tower.get_halves().has(half):
			return tower
	return null

func _tower_on(cell: Vector2) -> Tower:
	for tower in tower_container.get_children():
		if tower is Tower and not tower.is_queued_for_deletion() and tower.get_cells().has(cell):
			return tower
	return null

# The Warden is gone for good, with no refund; opening its cells never breaks the path rule, and
# everyone else re-routes.
func _trample_tower(tower: Tower, cell: Vector2, by: Node2D) -> void:
	tower_container.remove_child(tower)
	tower.queue_free()
	if map_generator.has_method("unblock_halves"):
		map_generator.unblock_halves(tower.get_halves())  # Half cells: a Warden may sit at a half-cell offset
	else:
		for c in tower.get_cells():
			map_generator.unblock_cell(c)
	wall_trampled.emit(cell, by)

# The maze changed: every enemy re-routes from the cell it's currently walking toward. One whose next
# step would take it back to the cell it just left turns around: +1 Restless (No maze juggling).
# Unbound nightmares keep their route. Waymark: each walker keeps its leg (passed_waymark), and turning at the stone is
# never a turn back (a stone at the end of a corridor sends it back the way it came: that's the route, not a juggle).
func _on_path_changed() -> void:
	var stone: bool = map_generator.has_method("has_waymark") and map_generator.has_waymark()
	for enemy in get_maze_walkers():
		if enemy.is_unbound():
			continue
		var new_path: PackedVector2Array = map_generator.get_path_from(enemy.get_target_cell(), enemy.passed_waymark)
		if new_path.is_empty():
			continue
		var turned_back: bool = new_path.size() > 1 and new_path[1] == enemy.get_last_cell() \
			and enemy.get_target_cell() != enemy.get_last_cell()
		if turned_back and stone and (map_generator.is_waymark_point(enemy.get_target_cell()) \
				or map_generator.is_waymark_point(enemy.get_last_cell())):
			turned_back = false
		enemy.set_path(new_path)
		if turned_back:
			var became_unbound: bool = enemy.add_restless()
			nightmare_restless.emit(enemy, enemy.get_restless())
			if became_unbound:
				nightmare_unbound.emit(enemy)

# Dream Thief: takes steals_dew Dew (as much as there is) on its way in, then the leaf is lost as usual.
func _on_enemy_reached_goal(enemy: Node2D) -> void:
	var run_state = get_node_or_null("%RunState")
	if enemy.enemy_data.steals_dew > 0 and run_state != null:
		var stolen: int = mini(enemy.enemy_data.steals_dew, run_state.dew)
		if stolen > 0:
			run_state.spend_dew(stolen)
	enemy_reached_goal.emit(enemy)
	_pack_member_gone(enemy, true)

# A flyer's line from the forest's edge to the Heartwood (grid coordinates), weaving up to weave
# cells either side (the Moth Queen), gently at the ends so it still starts and ends on target.
func _flight_path(weave: float) -> PackedVector2Array:
	var from: Vector2 = map_generator.startPath
	var to: Vector2 = map_generator.endPath
	if weave <= 0.0:
		return PackedVector2Array([from, to])
	var across := (to - from).orthogonal().normalized()
	var steps := maxi(ceili(from.distance_to(to) / 2.0), 2)
	var points := PackedVector2Array()
	for i in steps + 1:
		var t := float(i) / steps
		var point := from.lerp(to, t) + across * sin(t * TAU * 1.5) * weave * sin(t * PI)
		var bounds: Vector2 = Vector2(map_generator.MAP_GRID.size) - Vector2.ONE
		points.append(point.clamp(Vector2.ZERO, bounds))
	return points

# Moth Queen: a brood nightmare lands on the route cell nearest her and walks the maze from there.
# Huntsman: his horn calls a hound only while the pack is short (the whole pack at once when he
# regroups at half health, then never again); it runs from his cell and joins the pack.
func _on_brood_requested(queen: Node2D) -> void:
	var data: EnemyData = queen.enemy_data
	if data.pack_shield < 1.0:
		_call_pack(queen)
		return
	var route: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	if route.is_empty():
		return
	# Waymark: a queen past the stone lands her brood on leg 2 (a corridor walked both ways has a point on each leg)
	var first := maxi(map_generator.waymark_split(route), 0) if queen.passed_waymark and map_generator.has_method("waymark_split") else 0
	var nearest := first
	for i in range(first, route.size()):
		if queen.grid.calculate_map_position(route[i]).distance_squared_to(queen.position) \
				< queen.grid.calculate_map_position(route[nearest]).distance_squared_to(queen.position):
			nearest = i
	var path := route.slice(nearest)
	var child := _create(queen.enemy_data.brood, drift_health_scale)
	child.passed_waymark = queen.passed_waymark and first > 0
	child.dew_share = 0.0  # A summon pays no Dew (the Dew pot)
	child.position = child.grid.calculate_map_position(path[0])
	child.set_path(path)
	enemy_split.emit(queen, child)

# Hollow Oak Grief: grief_count nightmares rise in a ring around it and walk on from its cell.
func _on_grief_requested(oak: Node2D) -> void:
	var data: EnemyData = oak.enemy_data
	var path: PackedVector2Array = map_generator.get_path_from(oak.get_target_cell(), oak.passed_waymark)
	if data.grief_spawn == null or path.is_empty():
		return
	for i in data.grief_count:
		var child := _create(data.grief_spawn, drift_health_scale)
		child.passed_waymark = oak.passed_waymark
		child.dew_share = 0.0  # A summon pays no Dew (the Dew pot)
		child.position = oak.position + Vector2.from_angle(TAU * i / data.grief_count) * GRIEF_RING
		child.set_path(_flight_from(child) if _flies_straight(data.grief_spawn) else path)
		enemy_split.emit(oak, child)

# Hollow Oak: plants a thorn-sapling on an empty cell beside its route ahead. Never on a Warden, the
# start / end or a nightmare, and never where it would cut anyone off (the path rule).
func _on_sapling_requested(oak: Node2D) -> void:
	var walkers := get_maze_walkers()
	var taken := {}
	var also_from := PackedVector2Array()
	for walker in walkers:
		# (Half cells: route points to the whole cells the bodies cover)
		for cell in _body_cells(PackedVector2Array([walker.get_route_point(), walker.get_target_cell()])):
			taken[cell] = true
		also_from.append(walker.get_target_cell())
		if walker.is_unbound():  # It won't re-route: keep its whole route clear
			for cell in _body_cells(walker.get_cells_ahead(1000)):
				taken[cell] = true
	# SAPLING_REACH cells ahead (in route steps: two a cell on half cells), as whole cells
	var ahead: Array[Vector2] = _body_cells(oak.get_cells_ahead(SAPLING_REACH * FindPath.HALF))
	var on_route := {}
	for cell in ahead:
		on_route[cell] = true
	var candidates: Array[Vector2] = []
	for cell in ahead:
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var beside: Vector2 = cell + offset
			if not on_route.has(beside) and not taken.has(beside) and not candidates.has(beside) \
					and map_generator.is_buildable(beside):
				candidates.append(beside)
	candidates.shuffle()
	for cell in candidates:
		if map_generator.can_block(cell, also_from):
			map_generator.place_obstacle(cell, oak.enemy_data.sapling)
			_saplings.get_or_add(oak, []).append(cell)
			_grow_sprite(cell, oak.enemy_data.sapling_frames)
			return

# The Hollow Oak is dispelled: the saplings it planted (and the player hasn't cleared) crumble.
func _wither_saplings(oak: Node2D) -> void:
	if not _saplings.has(oak):
		return
	for cell: Vector2 in _saplings[oak]:
		if map_generator.get_obstacle(cell) == oak.enemy_data.sapling:
			map_generator.remove_obstacle(cell)
			_wither_sprite(cell)
	_saplings.erase(oak)
# A sapling springs up on cell ("grow", then "idle"). Drawn on the map, under the nightmares.
func _grow_sprite(cell: Vector2, frames: SpriteFrames) -> void:
	if frames == null:
		return
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.position = map_generator.MAP_GRID.calculate_map_position(cell)
	map_generator.add_child(sprite)
	sprite.animation_finished.connect(func() -> void:
		if sprite.animation == &"grow":
			sprite.play(&"idle"))
	sprite.play(&"grow")
	_sapling_sprites[cell] = sprite

# The sapling on cell crumbles to ash ("wither"), then goes (the Oak fell, or the player cleared it).
func _wither_sprite(cell: Vector2) -> void:
	var sprite: AnimatedSprite2D = _sapling_sprites.get(cell)
	if sprite == null:
		return
	_sapling_sprites.erase(cell)
	if not is_instance_valid(sprite):
		return
	sprite.animation_finished.connect(sprite.queue_free)
	sprite.play(&"wither")

# --- Boss pools (enemy_design.md, 2026-09-29) --------------------------------------------------------

# Huntsman: calls hounds until the pack is back to full (follower_count). The regroup at half health
# is the last call.
func _call_pack(huntsman: Node2D) -> void:
	var data: EnemyData = huntsman.enemy_data
	if huntsman.is_regrouped():
		if huntsman.has_meta(&"regroup_called"):
			return  # The horn fell silent after The Kill
		huntsman.set_meta(&"regroup_called", true)
	var missing: int = data.follower_count - huntsman.pack_alive()
	if missing <= 0 or data.brood == null:
		return
	var path: PackedVector2Array = map_generator.get_path_from(huntsman.get_target_cell(), huntsman.passed_waymark)
	if path.is_empty():
		return
	var count := missing if huntsman.is_regrouped() else 1
	for i in count:
		var hound := _create(data.brood, drift_health_scale, huntsman.modifiers)
		hound.passed_waymark = huntsman.passed_waymark
		hound.dew_share = 0.0  # A summon pays no Dew (the Dew pot)
		hound.position = huntsman.position + Vector2.from_angle(TAU * i / maxi(count, 1)) * SPLIT_SPACING
		hound.set_path(path)
		huntsman.pack.append(hound)
		enemy_split.emit(huntsman, hound)
	if count > 0:
		huntsman.play_pose(&"horn")  # He raises the bone horn and blows

# Night Mare: back at the start for another lap (its leaves went while it lingered), Shades behind it.
func _on_heartwood_drained(enemy: Node2D) -> void:
	var leaves := 1
	var omens := get_tree().get_first_node_in_group(OmenDirector.GROUP) as OmenDirector
	if omens:
		leaves = roundi(leaves * omens.get_leak_multiplier())  # Leaf Fall doubles it, as for any leak
	var run_state = get_node_or_null("%RunState")
	if run_state != null:
		run_state.lose_leaves(leaves)
	boss_drained.emit(enemy, leaves)

func _on_lapped(enemy: Node2D) -> void:
	enemy_lapped.emit(enemy, 0)  # A lap costs nothing itself: it drains leaves while it lingers (boss_drained)
	_run_from_start(enemy.enemy_data.lap_spawn, enemy.enemy_data.lap_spawn_count, enemy)  # Shades behind it

# Lamplighter: lights a cold lantern on an empty cell beside its route, near it (up to lantern_max).
func _on_lantern_requested(lamplighter: Node2D) -> void:
	var data: EnemyData = lamplighter.enemy_data
	var own := _lanterns.filter(func(l: ColdLantern) -> bool: return l.is_lit() and l.owner_boss == lamplighter)
	if own.size() >= data.lantern_max:
		return
	var taken := {}
	for lantern in _lanterns:
		taken[lantern.cell] = true
	# Near it: 3 cells ahead and 2 behind (in route steps: two a cell on half cells), as whole cells
	var near_points: PackedVector2Array = lamplighter.get_cells_ahead(3 * FindPath.HALF)
	near_points.append_array(lamplighter.get_cells_behind().slice(-2 * FindPath.HALF))
	var near: Array[Vector2] = _body_cells(near_points)
	var on_route := {}  # The whole route (a maze doubles back past itself), never lit on
	for cell in _body_cells(lamplighter.get_cells_behind() + lamplighter.get_cells_ahead(1000)):
		on_route[cell] = true
	var candidates: Array[Vector2] = []
	for cell in near:
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var beside: Vector2 = cell + offset
			if not on_route.has(beside) and not taken.has(beside) and not candidates.has(beside) \
					and map_generator.is_buildable(beside):
				candidates.append(beside)
	if candidates.is_empty():
		return
	var lantern := ColdLantern.new()
	lantern.cell = candidates.pick_random()
	lantern.radius = data.lantern_radius
	lantern.life = data.lantern_life
	lantern.snuff_dew = data.lantern_snuff_dew
	lantern.owner_boss = lamplighter
	lantern.cell_size = map_generator.MAP_GRID.cell_size.x
	lantern.position = map_generator.MAP_GRID.calculate_map_position(lantern.cell)
	lantern.snuffed.connect(_on_lantern_snuffed)
	map_generator.add_child(lantern)  # In the world, never under this node (its children are nightmares)
	_lanterns.append(lantern)
	lantern_lit.emit(lantern)
	lamplighter.play_pose(&"light")  # It lowers the pole and the lantern kindles

func _on_lantern_snuffed(lantern: ColdLantern, by_player: bool) -> void:
	_lanterns.erase(lantern)
	if by_player and lantern.snuff_dew > 0:
		var run_state = get_node_or_null("%RunState")
		if run_state != null:
			run_state.earn_dew_at(lantern.snuff_dew, lantern.global_position)
	lantern_snuffed.emit(lantern, by_player)

# The Lamplighter is dispelled: its lanterns go out.
func _snuff_lanterns_of(boss: Node2D) -> void:
	for lantern in _lanterns.duplicate():
		if lantern.owner_boss == boss:
			lantern.snuff(false)

# Wardens in a lantern's cold light attack slower (the strongest slow if several reach one).
func _update_lantern_light() -> void:
	if _lanterns.is_empty() and _dimmed.is_empty():
		return
	var now := {}
	for lantern in _lanterns:
		if not is_instance_valid(lantern) or not lantern.is_lit():
			continue
		var slow: float = lantern.owner_boss.enemy_data.lantern_slow if is_instance_valid(lantern.owner_boss) else 0.4
		for tower in tower_container.get_children():
			if tower is Tower and tower.global_position.distance_to(lantern.global_position) <= lantern.get_reach():
				now[tower] = minf(now.get(tower, 1.0), 1.0 - slow)
	for tower in _dimmed:
		if is_instance_valid(tower) and not now.has(tower):
			tower.dim_multiplier = 1.0
	for tower in now:
		tower.dim_multiplier = now[tower]
	_dimmed = now

# Withering Oak: roots wither the `count` strongest Wardens within reach (never the one it withered
# last time, when there's another choice) for wither_time seconds.
func _on_wither_requested(oak: Node2D, count: int) -> void:
	var data: EnemyData = oak.enemy_data
	var reach: float = data.wither_reach * map_generator.MAP_GRID.cell_size.x
	var candidates: Array = []
	for tower in tower_container.get_children():
		if tower is Tower and not tower.is_queued_for_deletion() and tower.tower_data.can_attack \
				and not tower.is_withered() and tower.global_position.distance_to(oak.global_position) <= reach:
			candidates.append(tower)
	var last = _last_withered.get(oak)
	if candidates.size() > count and last in candidates:
		candidates.erase(last)
	candidates.sort_custom(func(a: Tower, b: Tower) -> bool:
		return a.get_damage() * a.get_attacks_per_second() > b.get_damage() * b.get_attacks_per_second())
	for tower in candidates.slice(0, count):
		tower.wither(data.wither_time)
		_last_withered[oak] = tower
		tower_withered.emit(tower, oak)

# Remembering Oak: the echo of the boss this run drew for `act` rises beside it with echo_share of
# that boss's health, and walks on from the Oak's cell with its full trait.
func _on_echo_requested(oak: Node2D, act: int) -> void:
	var director := get_node_or_null("%DriftDirector") as DriftDirector
	var drawn: BossData = director.get_drawn_boss(act) if director else null
	var boss: EnemyData = drawn.boss if drawn != null else null
	if boss == null or boss.echo_at.size() > 0:
		return  # No boss drawn for that act (or it's an Oak itself)
	var path: PackedVector2Array = map_generator.get_path_from(oak.get_target_cell(), oak.passed_waymark)
	if path.is_empty():
		return
	var scale: float = director.get_health_scale(boss, maxi(director.drifts_started, 1)) * oak.enemy_data.echo_share
	var echo = enemy_scene.instantiate()
	echo.is_echo = true
	echo.passed_waymark = oak.passed_waymark  # Waymark: on the Oak's leg
	var created := _create_prepared(echo, boss, scale)
	created.dew_share = 0.0  # A summon pays no Dew (the Dew pot)
	if boss.trait_kind == EnemyData.Trait.FLYING and not boss.flies_along_route:
		path = PackedVector2Array([oak.get_target_cell(), map_generator.endPath])
	created.position = oak.position + Vector2(GRIEF_RING, 0).rotated(TAU * act / 3.0)
	created.set_path(path)
	_spawn_followers(created, path)
	enemy_split.emit(oak, created)
