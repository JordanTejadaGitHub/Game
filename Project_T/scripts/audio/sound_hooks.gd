extends Node
class_name SoundHooks

# Connects the run's signals to the Sound autoload (audio_direction.md), so gameplay scripts never
# know about audio, and drives the adaptive music layers from what's on the field:
# base always · dread1 while nightmares are in the dream · dread2 when many, or any in the last
# third of the path · heartbeat at 5 leaves or fewer · boss drums while a boss walks.
# Does nothing if the autoload is missing (e.g. a test run without it).

const MAP_GRID = preload("res://resource/map/map_grid.tres")
# EnemyData file name -> the nightmare's signature sound (played when one enters the dream).
const SIGNATURES := {
	"leaf_bug": &"sig_shade", "bark_beetle": &"sig_husk", "dusk_moth": &"sig_lurker",
	"dandelion_seed": &"sig_phantom", "hedgehog": &"sig_hound", "mother_duck": &"sig_procession",
	"wandering_hare": &"sig_sleepwalker", "puffcap": &"sig_mourner", "mother_spider": &"sig_widow",
	"old_stag": &"sig_stag", "great_toad": &"sig_hag",
}
const SIGNATURE_INTERVAL_MS := 2500  # One signature per nightmare type this often at most
const DREAD2_COUNT := 12
# One music theme per boss (audio_direction.md): EnemyData file name -> its stems (mus_act1_boss_<key>,
# + _warm below half health).
const BOSS_THEMES := {"old_stag": "stag", "great_toad": "hag", "moth_queen": "moth", "hollow_oak": "oak"}
const LOW_LEAVES := 5
const QUIET_LINES := ["wall"]  # Wardens that never attack
# Attacks (audio_direction.md "Wardens"): a quiet launch when the Warden fires, the impact on the hit.
const LAUNCH_DB := -15.0
const HIT_DB := -3.0  # ~6 dB above the first placeholder attacks
const EVENT_DB := -4.0  # Warden events (clouds, traps, storms, catches, echoes...)
const CHAIN_STEP_PITCH := 0.97  # Each chain jump also a little lower
const PECK_RATE := 6.0  # Hummingbird pecks per second (for loudness × rate)
const BEAM_HOLD := 0.5  # Seconds a loop stays up after its last tick
const LIT_HOLD := 2.0
const SPIN_HOLD := 1.0
const FIRST_BREATH_DELAY := 0.6  # Evolve bloom, then the new form's hit
const PLOP_DELAY := 0.25
const SLEEP_INTERVAL_MS := 1500
# Pulse Wardens whose sound should stay rare (ms between two).
# Each family's base Warden (the last fallback for a Warden without sounds of its own).
const FAMILY_BASE := {"spore": "sporeling", "stone": "pebbling", "water": "dewdrop", "light": "firefly_jar",
	"root": "rootling", "song": "bellflower", "acorn": "acorn", "wing": "nestling", "wind": "whirligig"}
const PULSE_THROTTLE_MS := {"bramble": 800, "honeysuckle": 3000, "acorn": 5000, "tempest": 400}
# Sound id prefixes a Warden can have (warden_sounds, tests).
const EVENT_PREFIXES := ["attack_", "hit_", "drowsy_", "pop_", "cloud_", "fog_", "sleep_", "trap_", "trigger_",
	"crit_", "storm_", "loop_", "echo_", "shard_", "place_", "plop_", "dew_", "turn_", "catch_", "event_",
	"ascend_", "plant_", "sap_", "ripen_", "wither_", "recover_"]
# Ascended Wardens (tier 4, audio_direction.md 4d1f283): their big events are the loudest Warden
# sounds, just under a boss, growing with the number hit, with a small music duck.
const ASCENDED_TIER := 4
const ASCENDED_EVENT_DB := -2.0
const ASCENDED_GROWTH_DB := 1.5  # Per doubling of nightmares hit, up to ASCENDED_GROWTH_MAX
const ASCENDED_GROWTH_MAX := 4.0
const ASCENDED_DUCK_INTERVAL_MS := 1500  # Stormheart chains often; its duck doesn't pump
const ASCENDED_POP_MS := 300  # Sporemother's crowds popping read as one rolling fwoomp
const PRESENCE_LEVEL := 0.45  # Presence loops: very quiet, a little fuller while nightmares walk
const ASCEND_SWELL_DELAY := 0.8  # Evolve bloom, then the material swell, then the first event
const ASCEND_EVENT_DELAY := 2.6
const WITHER_DELAY := 0.7  # The Sapling's creak comes after the leaf-lost sound
# Nurture: quieter and shorter than Evolve (it's frequent), fuller each rank.
const NURTURE_DB := -10.0
const NURTURE_RANK_DB := 0.6
const NURTURE_GROUP_DB := -1.0  # Each further Warden in a group nurture
const NURTURE_GROUP_MIN_DB := -6.0
# Dawnwing: its calm and busy wingbeat loops crossfade over this many nightmares.
const DAWNWING_BUSY_COUNT := 10.0
const GREAT_BELL_BLOOM_DB := -6.0
# Reactions: louder than a Warden hit, under a boss; sized by the nightmares caught.
const REACTION_DB := -1.0
const REACTION_BOSS_DB := -2.0  # A boss's reduced version plays a little smaller
const REACTION_THROTTLE_MS := 150
const REACTION_REACH_CELLS := 2.5
const CHAIN_SWELL_DB := -9.0
const CHAIN_SWELL_STEP_DB := 1.2  # Fuller each link, never higher
const SURGE_LINKS := 5
const DAWNBURST_LINKS := 10
const STINGER_DELAY := 0.9  # After the Dawnburst boom and its duck
# Kinships: quiet rewards. The Harmony strike stays well under the Reactions and is throttled hard.
const KIN_DB := -6.0
const HARMONY_DB := -16.0
const HARMONY_THROTTLE_MS := 1500
const WHOLE_DB := -3.0
# The field (nightmares, presence Wardens) is walked this often (s, real time), not every frame.
const FIELD_SCAN_INTERVAL := 0.25
const PRESENCE_HOLD := 0.6  # Longer than a scan, so presence loops stay up between scans
# Economy: a caught drop is near-silent and rare; the harvest is a rest-time reward, below bosses.
const DEW_CATCH_DB := -16.0
const DEW_CATCH_THROTTLE_MS := 400
const HARVEST_DB := -3.0
const HARVEST_WINDOW_MS := 4000  # Pours within this of the first belong to the same Harvest
const HIT_FAMILIES := ["stone", "root", "water", "light", "spore", "sprout"]  # Others sound like sprout
const HIT_GROUP_MS := 90  # A pulse or splash hitting many nightmares at once is one impact
const CHAIN_STEP_DB := -4.0  # Each jump of a chain ripples a little quieter
const CLOUD_HIT_MS := 400  # A cloud's lingering ticks are silent; only its landing hits
const RESISTED_DB := -3.0
const WEAK_DB := 2.0
const DEW_DB := -6.0  # Lump sums of Dew (rest bonus, Omen rewards): a soft, low rustle of light
# Ambience (audio_direction.md "Ambience"): thins out with the field, swells at rests.
const AMBIENCE_THIN_DB := -8.0  # At AMBIENCE_THIN_COUNT nightmares or more
const AMBIENCE_THIN_COUNT := 15
const AMBIENCE_REST_DB := 3.0

@onready var sound: Node = get_node_or_null("/root/Sound")
@onready var run_state = %RunState
@onready var map_generator = %MapGenerator
@onready var enemy_container = %EnemyContainer
@onready var tower_container: Node2D = %TowerContainer
@onready var tower_placer = %TowerPlacer
@onready var tower_seller = %TowerSeller
@onready var drift_director = %DriftDirector
@onready var dream_state = %DreamState
@onready var omen_director = %OmenDirector

var _last_signature := {}  # sound id -> msec
var _path_pixels := 1.0
var _choice_screens: Array[Control] = []
var _hit_groups := {}  # Tower instance id -> [first hit msec, hits since]
var _released_at := {}  # Tower instance id -> msec of its last attack release
var _attack_counts := {}  # Tower instance id -> attacks released (storms, sleepier bells)
var _loop_until := {}  # loop id -> [until msec, level]
var _slept_at := {}  # Warden id -> msec of its last sleep drone
var _withered := {}  # Tower instance id -> Sapling withered since the last rest
var _popped_at := {}  # Tower instance id -> msec of its last pop sound (Sporemother)
var _ducked_at := {}  # Tower instance id -> msec of its last Ascended duck
var _nurture_frame := -1  # Group nurtures arrive in one frame
var _nurture_index := 0
var _focus_heard := {}  # Tower instance id -> its Focus lean already played
var _reaction_at := {}  # Reaction id -> msec of its last sound
var _last_reaction_crowned := false  # The Reaction just before a chain_reached (Crowned = 2 links)
var _dawnburst_played := false
var _harmony_at := -100000  # msec of the last Harmony strike sound
var _scan_left := 0.0  # Seconds (real time) until the next field scan
var _resting := true
var _presence := {}  # Tower instance id -> a Warden with a presence loop
var _dew_catch_at := -100000
var _harvest_at := -100000  # msec of this rest's harvest sound (later pours add droplets)

func _ready() -> void:
	if sound == null:
		set_process(false)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	for path in ["HUD/FamilyPickScreen", "HUD/DreamScreen", "HUD/OmenScreen", "HUD/PauseMenu", "HUD/ResultsScreen"]:
		var screen := owner.get_node_or_null(path) as Control
		if screen:
			_choice_screens.append(screen)

	enemy_container.child_entered_tree.connect(_on_enemy_added)
	enemy_container.enemy_cleansed.connect(func(enemy: Node2D) -> void:
		sound.play_dispel(enemy.global_position, enemy.enemy_data.is_boss))
	enemy_container.enemy_reached_goal.connect(func(_enemy: Node2D) -> void:
		sound.duck(8.0, 1.0)
		sound.play(&"leaf_lost", null, 0.0, 1.0, 0.03))
	enemy_container.enemy_split.connect(func(parent: Node2D, child: Node2D) -> void:
		if parent.is_cleansed:  # Followers (Wraiths) also come through here; only real splits crack
			sound.play(&"split", child.global_position, -4.0))
	enemy_container.wall_trampled.connect(func(cell: Vector2, _by: Node2D) -> void:
		sound.duck(8.0, 1.0)
		sound.play(&"trample", MAP_GRID.calculate_map_position(cell), 2.0))

	tower_container.child_entered_tree.connect(_on_tower_added)
	tower_placer.tower_built.connect(func(tower: Tower) -> void:
		var own_plant := StringName("plant_" + warden_id(tower.tower_data))  # The Sapling's big rooting
		sound.play(own_plant if sound.has_sound(own_plant) else &"plant", tower.global_position)
		_event("place_", tower, tower.global_position))  # The White Stag arriving
	tower_placer.build_rejected.connect(func(_cell: Vector2) -> void: sound.ui(&"invalid"))
	tower_seller.tower_sold.connect(func(tower: Tower, _refund: int) -> void:
		sound.play(&"sell", MAP_GRID.calculate_map_position(tower.cell)))
	map_generator.obstacle_cleared.connect(func(cell: Vector2, data: ObstacleData) -> void:
		var id := &"move" if data.resource_path.get_file().begins_with("rock") else &"tend"
		sound.play(id, MAP_GRID.calculate_map_position(cell)))
	map_generator.path_changed.connect(_on_path_changed)

	run_state.dew_short.connect(func(_cost: int) -> void: sound.ui(&"invalid"))
	# No Dew sound per kill (third listen: kills sounded like coins); only lump sums make one.
	run_state.run_ended.connect(_on_run_ended)

	drift_director.drift_started.connect(func(_number: int) -> void: sound.play(&"drift_start", null, -4.0, 1.0, 0.0))
	drift_director.rest_started.connect(func(_block: int, _boss: bool, bonus: int, _perfect: bool) -> void:
		sound.play(&"rest", null, -2.0, 1.0, 0.0)
		for t in _withered.values():  # The Sapling recovers at a rest: a warm exhale
			if is_instance_valid(t):
				_event("recover_", t, t.global_position)
		_withered.clear()
		if bonus > 0:
			sound.play(&"dew", null, DEW_DB, 1.0, 0.0))
	omen_director.omen_rewarded.connect(func(_omen: OmenData, _summary: String) -> void:
		sound.play(&"dew", null, DEW_DB, 1.0, 0.0))
	drift_director.act_started.connect(func(_act: int, _regrown: int) -> void: sound.play(&"act_swell", null, 0.0, 1.0, 0.0))
	drift_director.family_pick_requested.connect(func(_reason: StringName) -> void:
		sound.play(&"family_bell", null, 0.0, 1.0, 0.0, &"UI"))
	dream_state.offer_ready.connect(func(_cards: Array[UpgradeData], _drift: int) -> void:
		sound.play(&"dream_open", null, -2.0, 1.0, 0.0, &"UI"))
	dream_state.card_taken.connect(func(card: UpgradeData) -> void:
		sound.play(StringName("dream_take_%d" % clampi(int(card.rarity), 0, 2)), null, 0.0, 1.0, 0.0, &"UI"))
	omen_director.offer_ready.connect(func(_omens: Array[OmenData], _block: int) -> void:
		sound.play(&"omen_wind", null, -2.0, 1.0, 0.0, &"UI"))
	# The Codex: a combo fired for the first time ever (its card slides in).
	# The Heartwood Sapling's offer card (Main's FamilyPickScreen): a slow warm swell, no bell.
	var family_pick := owner.get_node_or_null("%FamilyPickScreen")
	if family_pick != null and family_pick.has_signal("sapling_offered"):
		family_pick.sapling_offered.connect(func() -> void:
			sound.play(&"offer_heartwood_sapling", null, -3.0, 1.0, 0.0, &"UI"))
	var combo_feedback := owner.get_node_or_null("%ComboFeedback")
	if combo_feedback != null and combo_feedback.has_signal("combo_discovered"):
		# Reactions and Crowned: the Dream-screen breath in and a soft shimmer (+ the crown swell);
		# other combos keep their discovery chime.
		combo_feedback.combo_discovered.connect(func(id: StringName) -> void:
			if Reactions.get_data(id) != null or Reactions.is_crowned(id):
				sound.play(&"discover_reaction", null, -3.0, 1.0, 0.0, &"UI")
				if Reactions.is_crowned(id):
					sound.play(&"crown_swell", null, -5.0, 1.0, 0.0, &"UI")
			else:
				sound.play(&"combo_found", null, -3.0, 1.0, 0.0, &"UI"))
	# The first chain ever: the Dream-screen breath in under its whisper (Main's Whispers, 8d17562).
	var whispers := owner.get_node_or_null("%Whispers")
	if whispers != null and whispers.has_signal("whispered"):
		whispers.whispered.connect(func(id: StringName) -> void:
			if id == &"chain":
				sound.play(&"discover_reaction", null, -6.0, 1.0, 0.0, &"UI"))
	# Reactions: ReactionTracker joins the run on the first one.
	get_tree().node_added.connect(_on_node_added)
	var tracker := get_tree().get_first_node_in_group(ReactionTracker.GROUP)
	if tracker != null:
		_on_node_added(tracker)
	for node in owner.find_children("*", "", true, false):  # Kinship nodes already in the scene
		_hook_kinships(node)
		_hook_economy(node)

	sound.play_music(&"act1", [&"base"])
	sound.play_ambience(&"act1")
	_on_path_changed()

func _exit_tree() -> void:
	if sound != null:
		sound.set_muffled(false)
		sound.set_drifting(false)
		sound.set_ambience_trim(0.0)
		sound.stop_ambience()
		sound.stop_loops()

# Cheap things every frame; anything that walks the field (the nightmares, the Wardens with a
# presence loop) only FIELD_SCAN_INTERVAL times per second of real time, so a busy field stays cheap.
func _process(delta: float) -> void:
	_scan_left -= delta / maxf(Engine.time_scale, 0.01)
	if _scan_left <= 0.0:
		_scan_left = FIELD_SCAN_INTERVAL
		_scan_field()
	sound.set_muffled(_choice_screens.any(func(screen) -> bool: return is_instance_valid(screen) and screen.visible))
	sound.set_drifting(not _resting)
	_apply_loops()

func _scan_field() -> void:
	var enemies: Array = enemy_container.get_enemies()  # Once per scan: it builds a new list each call
	var near := false
	var boss := false
	var smothered := false
	var theme := ""  # The walking boss's own theme (BOSS_THEMES), if it has one
	var winning := false  # That boss is below half health: its warm counter-melody enters
	var near_distance := _path_pixels / 3.0
	for enemy in enemies:
		if enemy.enemy_data.is_boss:
			boss = true
			var key: String = BOSS_THEMES.get(enemy.enemy_data.resource_path.get_file().get_basename(), "")
			if key != "" and theme == "":
				theme = key
				winning = enemy.health * 2 <= enemy.max_health
		if not near and enemy.get_remaining_distance() < near_distance:
			near = true
		if not smothered and enemy.has_meta(&"smother_fx"):
			smothered = true
	sound.set_layer(&"dread1", not enemies.is_empty())
	sound.set_layer(&"dread2", enemies.size() >= DREAD2_COUNT or near)
	sound.set_layer(&"heartbeat", run_state.leaves <= LOW_LEAVES and not run_state.is_over)
	sound.set_layer(&"boss", boss and theme == "")  # A boss without a theme of its own: the shared drums
	for key in BOSS_THEMES.values():
		sound.set_layer(StringName("boss_" + key), theme == key)
		sound.set_layer(StringName("boss_%s_warm" % key), theme == key and winning)
	_resting = drift_director.is_build_phase()
	if _resting:
		sound.set_ambience_trim(AMBIENCE_REST_DB)
	else:
		sound.set_ambience_trim(AMBIENCE_THIN_DB * minf(float(enemies.size()) / AMBIENCE_THIN_COUNT, 1.0))
	if smothered:  # Smother's hum lasts while any nightmare is smothered
		_touch_loop("loop_smother", 1.0, PRESENCE_HOLD)
	_update_presence(enemies.size())

func _on_enemy_added(enemy: Node) -> void:
	# Its position is set right after it enters the tree, so wait a frame.
	_play_signature.call_deferred(enemy)
	if enemy.has_signal("leaped"):
		enemy.leaped.connect(func(e: Node2D) -> void:
			if e.enemy_data.is_boss:
				sound.duck(8.0, 1.0)
			sound.play(&"hag_rise", e.global_position))

# Untyped on purpose: the nightmare may be freed before this deferred call runs.
func _play_signature(enemy) -> void:
	if not is_instance_valid(enemy) or enemy.enemy_data == null:
		return
	var id: StringName = SIGNATURES.get(enemy.enemy_data.resource_path.get_file().get_basename(), &"")
	if id == &"":
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_signature.get(id, -100000)) < SIGNATURE_INTERVAL_MS:
		return
	_last_signature[id] = now
	if enemy.enemy_data.is_boss:
		sound.duck(8.0, 1.0)
	# Deeply Blighted: the same sound, pitched down.
	sound.play(id, enemy.global_position, 2.0 if enemy.enemy_data.is_boss else -3.0, 0.8 if enemy.elite else 1.0)

# --- Wardens (audio_direction.md "Warden sound sheet") ---------------------------------------------
# Every Warden looks up its own sounds by its file name: attack_<id> (launch), hit_<id>, events
# (<event>_<id>) and loops (loop_<id>), falling back to its family's attack_<line> / hit_<line>.
# Sprout and Firefly Jar are their families' sounds. A Graftling plays the Warden it copies, muffled
# through bark. Loudness × rate stays even: fast Wardens are quieter per shot (`_rate_db`).

static func warden_id(data: TowerData) -> String:
	return data.resource_path.get_file().get_basename()

# Every sound a Warden can make that exists (tests check each built Warden has at least one).
static func warden_sounds(snd: Node, data: TowerData) -> Array[StringName]:
	var found: Array[StringName] = []
	for prefix in EVENT_PREFIXES:
		for id in _lookup_ids(prefix, data):
			if snd.has_sound(StringName(id)) and not found.has(StringName(id)):
				found.append(StringName(id))
	return found

# Where a Warden's sound is looked up: its own, its family's base Warden's, then its family's (so a
# Warden not on the sound sheet yet, e.g. a new final form, sounds like its family until it has its own).
static func _lookup_ids(prefix: String, data: TowerData) -> Array:
	var ids := [prefix + warden_id(data)]
	if FAMILY_BASE.has(data.line):
		ids.append(prefix + FAMILY_BASE[data.line])
	ids.append(prefix + data.line)
	return ids

func _sound_for(prefix: String, data: TowerData) -> StringName:
	for id in _lookup_ids(prefix, data):
		if sound.has_sound(StringName(id)):
			return StringName(id)
	return &""

# Plays `<prefix><warden id>` (no family fallback: events belong to one Warden) if it exists.
func _event(prefix: String, tower: Tower, at: Vector2, volume_db := EVENT_DB) -> void:
	var id := StringName(prefix + warden_id(tower.attack_data))
	if sound.has_sound(id):
		sound.play(id, at, volume_db, 1.0, 0.03, _bus_for(tower))

func _bus_for(tower: Tower) -> StringName:
	if tower.get_copied() == null:
		return &"SFX"
	return &"SFXBark" if warden_id(tower.tower_data) == "grafted_elder" else &"SFXMuffled"

# Loudness × rate stays even: −7 dB per tenfold rate, clamped (a 6/s peck is near-subliminal, a
# 1-per-3-s Standing Stone lands full).
static func _rate_db(rate: float) -> float:
	return clampf(-7.0 * log(maxf(rate, 0.05)) / log(10.0), -9.0, 3.0)

static func _hit_rate(data: TowerData) -> float:
	return PECK_RATE if data.attack_kind == TowerData.AttackKind.PECK else data.attacks_per_second

# Keeps loop `id` at `level` for `hold` more seconds (SoundHooks._process fades it out after).
func _touch_loop(id: String, level: float, hold: float) -> void:
	_loop_until[StringName(id)] = [Time.get_ticks_msec() + int(hold * 1000.0), level]

# The Wardens with a presence loop (the White Stag's aura, Dawnwing, Ascended Wardens), registered when
# they join or evolve, so the field scan never walks every Warden.
func _refresh_presence(tower: Tower) -> void:
	var id := tower.get_instance_id()
	# tower_data, not attack_data: this runs as the Warden enters the tree, before its _ready sets attack_data.
	if tower.tower_data.attack_kind == TowerData.AttackKind.AURA or tower.tower_data.tier >= ASCENDED_TIER:
		_presence[id] = tower
	else:
		_presence.erase(id)

func _update_presence(walking_count: int) -> void:
	var walking := walking_count > 0
	for id in _presence.keys():
		var tower: Tower = _presence[id] if is_instance_valid(_presence[id]) else null
		if tower == null or tower.is_queued_for_deletion():
			_presence.erase(id)
			continue
		if tower.tower_data.attack_kind == TowerData.AttackKind.AURA:
			# The White Stag: a faint breathing presence, fuller while nightmares walk.
			_touch_loop("loop_" + warden_id(tower.tower_data), 1.0 if walking else 0.35, PRESENCE_HOLD)
		elif warden_id(tower.tower_data) == "dawnwing":
			# Calm and busy wingbeats crossfaded by how many nightmares walk (not sped up: that'd raise
			# the pitch). Neither ever drops to 0, so the two loops keep playing in sync.
			var busy := clampf(walking_count / DAWNWING_BUSY_COUNT, 0.0, 1.0)
			_touch_loop("loop_dawnwing", maxf(PRESENCE_LEVEL * (1.0 - busy), 0.0001), PRESENCE_HOLD)
			_touch_loop("loop_dawnwing_busy", maxf(PRESENCE_LEVEL * busy, 0.0001), PRESENCE_HOLD)
		else:  # An Ascended Warden's presence
			_touch_loop("loop_" + warden_id(tower.tower_data), PRESENCE_LEVEL * (1.0 if walking else 0.6), PRESENCE_HOLD)

# Every frame: the few active loop ids fade toward their level (cheap; no field walk).
func _apply_loops() -> void:
	var now := Time.get_ticks_msec()
	for id in _loop_until.keys():
		var entry: Array = _loop_until[id]
		var active: bool = now < int(entry[0])
		sound.set_loop(id, float(entry[1]) if active else 0.0)
		if not active:
			_loop_until.erase(id)

func _on_tower_added(node: Node) -> void:
	var tower := node as Tower
	if tower == null or tower.attack_released.is_connected(_on_attack):
		return
	tower.attack_released.connect(_on_attack)
	_refresh_presence(tower)
	tower.hit_landed.connect(_on_hit)
	# Evolving: the bloom, then the new form's hit once as a "first breath".
	tower.evolved.connect(func(t: Tower) -> void:
		sound.play(&"evolve", t.global_position)
		_refresh_presence(t)  # Growing into an Ascended form starts its presence
		if t.tower_data.tier >= ASCENDED_TIER:
			return  # Ascending has its own moment (below)
		get_tree().create_timer(FIRST_BREATH_DELAY).timeout.connect(func() -> void:
			if is_instance_valid(t):
				var id := _sound_for("hit_", t.attack_data)
				if id != &"":
					sound.play(id, t.global_position, HIT_DB, 1.0, 0.03, _bus_for(t))))
	# The hit's own sound plays too. Most crits add a low punch and a soft, low bell; some Wardens
	# have their own (Moonstone's bell-stone, Jewelwing's fuller tap), Magpie's Hoard adds its trinkets.
	tower.crit_landed.connect(func(t: Tower, enemy: Node2D) -> void:
		var own := StringName("crit_" + warden_id(t.attack_data))
		if sound.has_sound(own):
			sound.play(own, enemy.global_position, EVENT_DB, 1.0, 0.03, _bus_for(t))
		else:
			sound.play(&"crit", enemy.global_position, -6.0)
			sound.play(&"crit_punch", enemy.global_position, -4.0)
		if t.attack_data.crit_dew > 0:
			_event("dew_", t, enemy.global_position, EVENT_DB - 3.0))
	tower.popped.connect(func(t: Tower, enemy: Node2D, _stacks: int) -> void:
		if t.tower_data.tier >= ASCENDED_TIER:  # A crowd popping reads as one rolling fwoomp
			var now := Time.get_ticks_msec()
			if now - int(_popped_at.get(t.get_instance_id(), -100000)) < ASCENDED_POP_MS:
				return
			_popped_at[t.get_instance_id()] = now
		_event("pop_", t, enemy.global_position))
	# Beams (Sunpetal / Midsummer): one warm loop per Warden type, swelling with the ramp (1 -> 4 or 5).
	tower.beam_ticked.connect(func(t: Tower, ramp: float) -> void:
		_touch_loop("loop_" + warden_id(t.attack_data), 0.5 + 0.5 * clampf((ramp - 1.0) / 3.0, 0.0, 1.0), BEAM_HOLD))
	tower.nurtured.connect(_on_nurtured)
	# Ascended Wardens and the Sapling (Tower Code a187e96); connected only if present.
	if tower.has_signal("ascended"):
		tower.ascended.connect(_on_ascended)
	if tower.has_signal("ascended_event"):
		tower.ascended_event.connect(_on_ascended_event)
	if tower.has_signal("statics_set_off"):  # The Great Bell's toll setting off Static: one bloom, growing
		tower.statics_set_off.connect(func(t: Tower, where: Vector2, count: int) -> void:
			var growth := minf(ASCENDED_GROWTH_DB * log(1.0 + count) / log(2.0), ASCENDED_GROWTH_MAX)
			_event("bloom_", t, where, GREAT_BELL_BLOOM_DB - ASCENDED_GROWTH_MAX + growth))
	if tower.has_signal("sap_yielded"):
		tower.sap_yielded.connect(func(t: Tower, _dew: int) -> void: _event("sap_", t, t.global_position))
	if tower.has_signal("dreamlight_ripened"):
		tower.dreamlight_ripened.connect(func(t: Tower) -> void: _event("ripen_", t, t.global_position))
	if tower.has_signal("withered"):
		tower.withered.connect(func(t: Tower) -> void:
			_withered[t.get_instance_id()] = t
			get_tree().create_timer(WITHER_DELAY).timeout.connect(func() -> void:
				if is_instance_valid(t):
					_event("wither_", t, t.global_position)))
	# Events from Tower Code (abbc0f9); connected only if present.
	if tower.has_signal("cloud_formed"):
		tower.cloud_formed.connect(func(t: Tower, where: Vector2, duration: float) -> void:
			_on_cloud(t, where, duration))
	if tower.has_signal("trap_set"):
		tower.trap_set.connect(func(t: Tower, where: Vector2) -> void: _event("trap_", t, where, EVENT_DB - 3.0))
	if tower.has_signal("trap_triggered"):
		tower.trap_triggered.connect(func(t: Tower, where: Vector2) -> void: _event("trigger_", t, where))
	if tower.has_signal("seed_caught"):
		tower.seed_caught.connect(func(t: Tower) -> void: _event("catch_", t, t.global_position, EVENT_DB - 3.0))
	if tower.has_signal("echoed"):
		tower.echoed.connect(func(t: Tower, _reaction: StringName, where: Vector2) -> void: _event("echo_", t, where))
	if tower.has_signal("put_to_sleep"):
		tower.put_to_sleep.connect(func(t: Tower, enemy: Node2D) -> void:
			var now := Time.get_ticks_msec()
			var key := warden_id(t.attack_data)
			if now - int(_slept_at.get(key, -100000)) >= SLEEP_INTERVAL_MS:
				_slept_at[key] = now
				_event("sleep_", t, enemy.global_position))
	if tower.has_signal("shard_dropped"):
		tower.shard_dropped.connect(func(t: Tower, where: Vector2) -> void: _event("shard_", t, where))
	if tower.has_signal("grab_finished"):
		tower.grab_finished.connect(func(t: Tower, enemy: Node2D) -> void:
			var at: Vector2 = enemy.global_position if is_instance_valid(enemy) else t.global_position
			get_tree().create_timer(PLOP_DELAY).timeout.connect(func() -> void:
				if is_instance_valid(t):
					_event("plop_", t, at)))
	var id := tower.get_instance_id()
	tower.tree_exiting.connect(func() -> void:
		_hit_groups.erase(id)
		_released_at.erase(id)
		_attack_counts.erase(id)
		_presence.erase(id))

# Nurture (a rank up): a soft swell of the family's material, ~1 semitone deeper and a touch fuller per
# rank; choosing a Focus adds its lean. A group nurture fires these in one frame: they stagger with the
# visual bloom (TowerSeller.BLOOM_STAGGER) and each is a little quieter, so ten read as one rolling swell.
func _on_nurtured(tower: Tower) -> void:
	var frame := Engine.get_process_frames()
	_nurture_index = _nurture_index + 1 if frame == _nurture_frame else 0
	_nurture_frame = frame
	var index := _nurture_index
	var line: String = tower.tower_data.line
	var id := StringName("nurture_" + line)
	if not sound.has_sound(id):
		id = &"nurture_sprout"
	var pitch := pow(2.0, -maxf(tower.rank - 1, 0) / 12.0)
	var volume := NURTURE_DB + NURTURE_RANK_DB * tower.rank + maxf(NURTURE_GROUP_DB * index, NURTURE_GROUP_MIN_DB)
	var key := tower.get_instance_id()
	var lean := &""
	if tower.focus != Tower.Focus.NONE and not _focus_heard.has(key):
		_focus_heard[key] = true
		lean = StringName("focus_" + String(Tower.Focus.keys()[tower.focus]).to_lower())
	var play_it := func() -> void:
		if not is_instance_valid(tower):
			return
		sound.play(id, tower.global_position, volume, pitch, 0.0)
		if lean != &"":
			sound.play(lean, tower.global_position, volume, 1.0, 0.03)
	if index == 0:
		play_it.call()
	else:
		get_tree().create_timer(index * TowerSeller.BLOOM_STAGGER).timeout.connect(play_it)

# Ascending: the evolve bloom (evolved), then a slow, deep swell of the family's material, then the
# Warden's first event (or its hit, for Wardens without one).
func _on_ascended(tower: Tower) -> void:
	get_tree().create_timer(ASCEND_SWELL_DELAY).timeout.connect(func() -> void:
		if is_instance_valid(tower):
			_event("ascend_", tower, tower.global_position, ASCENDED_EVENT_DB))
	get_tree().create_timer(ASCEND_EVENT_DELAY).timeout.connect(func() -> void:
		if not is_instance_valid(tower):
			return
		var id := StringName("event_" + warden_id(tower.tower_data))
		if not sound.has_sound(id):
			id = _sound_for("hit_", tower.tower_data)
		if id != &"":
			sound.play(id, tower.global_position, ASCENDED_EVENT_DB, 1.0, 0.0))

# One big event (a pulse, the tide, the toll, a Stormheart chain): one sound that grows with the
# number of nightmares hit, never one per target, and a small music duck.
func _on_ascended_event(tower: Tower, where: Vector2, targets: int) -> void:
	var id := StringName("event_" + warden_id(tower.tower_data))
	if not sound.has_sound(id):
		return
	var growth := minf(ASCENDED_GROWTH_DB * log(1.0 + maxf(targets, 0)) / log(2.0), ASCENDED_GROWTH_MAX)
	_ascended_duck(tower)
	sound.play(id, where, ASCENDED_EVENT_DB - ASCENDED_GROWTH_MAX + growth + minf(_rate_db(tower.tower_data.attacks_per_second), 0.0),
		1.0, 0.0 if tower.tower_data.line == "song" else 0.03)

func _ascended_duck(tower: Tower) -> void:
	var now := Time.get_ticks_msec()
	if now - int(_ducked_at.get(tower.get_instance_id(), -100000)) >= ASCENDED_DUCK_INTERVAL_MS:
		_ducked_at[tower.get_instance_id()] = now
		sound.duck(3.0, 0.5)

func _on_cloud(tower: Tower, where: Vector2, duration: float) -> void:
	if tower.attack_data.cloud_fog:
		_event("fog_", tower, where)
		_touch_loop("loop_" + warden_id(tower.attack_data), 1.0, duration)
	else:
		_event("cloud_", tower, where)

# The launch: quiet, and by kind the start of something continuous (lit tiles, blades) or an event
# (a Thunderhead's storm strike, a Windmill's turn). Pulses have none (the pulse is the hit).
func _on_attack(tower: Tower) -> void:
	var data: TowerData = tower.attack_data
	var key := tower.get_instance_id()
	_released_at[key] = Time.get_ticks_msec()
	var count: int = _attack_counts.get(key, 0) + 1
	_attack_counts[key] = count
	var wid := warden_id(data)
	if tower.tower_data.tier >= ASCENDED_TIER and (data.attack_kind == TowerData.AttackKind.PULSE
			or data.attack_kind == TowerData.AttackKind.CHAIN):
		return  # The big event carries it
	match data.attack_kind:
		TowerData.AttackKind.BEAM, TowerData.AttackKind.AURA, TowerData.AttackKind.PULSE:
			return
		TowerData.AttackKind.LIGHT:
			_touch_loop("loop_" + wid, 1.0, LIT_HOLD)
		TowerData.AttackKind.SPIN:
			_touch_loop("loop_" + wid, 1.0, SPIN_HOLD)
			_event("turn_", tower, tower.global_position, EVENT_DB - 3.0)
		TowerData.AttackKind.CHAIN:
			if data.storm_every > 0 and count % data.storm_every == 0:
				_event("storm_", tower, tower.global_position)
		TowerData.AttackKind.CLOUD:
			if not tower.has_signal("cloud_formed"):
				_on_cloud(tower, tower.global_position, data.cloud_duration)
		TowerData.AttackKind.TRAP:
			if not tower.has_signal("trap_set"):
				_event("trap_", tower, tower.global_position, EVENT_DB - 3.0)
			return
	if QUIET_LINES.has(tower.tower_data.line):
		return
	var id := _sound_for("attack_", data)
	if id != &"":
		sound.play(id, tower.global_position, LAUNCH_DB + _rate_db(data.attacks_per_second), 1.0, 0.05, _bus_for(tower))

# The impact, where the attack lands: the Warden's hit, pitched lower on big or tanky nightmares
# (not the tonal song family), muffled when resisted, fuller and louder when the nightmare is weak.
func _on_hit(tower: Tower, enemy: Node2D, _is_area: bool, _is_crit: bool) -> void:
	if not is_instance_valid(enemy):
		return
	var data: TowerData = tower.attack_data
	var kind := data.attack_kind
	var key := tower.get_instance_id()
	var now := Time.get_ticks_msec()
	match kind:
		TowerData.AttackKind.BEAM:
			if data.beam_behind_share > 0.0 and enemy != tower.get("_beam_target"):
				_touch_loop("loop_%s_behind" % warden_id(data), 1.0, BEAM_HOLD)  # Midsummer's signature layer
			return
		TowerData.AttackKind.LIGHT, TowerData.AttackKind.AURA:
			return
		TowerData.AttackKind.CLOUD:  # The cloud's forming is the sound; its ticks are silent
			if tower.has_signal("cloud_formed") or now - int(_released_at.get(key, -100000)) > CLOUD_HIT_MS:
				return
		TowerData.AttackKind.TRAP:
			if tower.has_signal("trap_triggered"):
				return
	var wid := warden_id(data)
	if tower.tower_data.tier >= ASCENDED_TIER:
		if kind == TowerData.AttackKind.PULSE or kind == TowerData.AttackKind.CHAIN:
			return  # Its ascended_event is the one sound for all the targets
		if kind == TowerData.AttackKind.PROJECTILE:
			_ascended_duck(tower)  # Old Mountain's boulder: a small boss moment too
	var group: Array = _hit_groups.get(key, [-100000, 0])
	var hits_before := 0
	if now - int(group[0]) < HIT_GROUP_MS:
		hits_before = group[1] + 1
		group[1] = hits_before
	else:
		if now - int(group[0]) < int(PULSE_THROTTLE_MS.get(wid, 0)):
			return  # Bramble scrapes, Honeysuckle sighs and Acorn knocks stay rare
		group = [now, 0]
	_hit_groups[key] = group
	if hits_before > 0 and kind != TowerData.AttackKind.CHAIN:
		return

	var id := _sound_for("hit_", data)
	if kind == TowerData.AttackKind.PULSE and sound.has_sound(StringName("drowsy_" + wid)) \
			and int(_attack_counts.get(key, 0)) % 2 == 1:
		id = StringName("drowsy_" + wid)  # Bellflower: every 2nd pulse a sleepier, lower bell
	_attack_counts[key] = int(_attack_counts.get(key, 0)) + (1 if kind == TowerData.AttackKind.PULSE else 0)
	if id == &"":
		return
	var line: String = tower.tower_data.line  # The line Enemy.take_damage resists by
	var resisted: bool = line in enemy.enemy_data.resists
	var weak: bool = not resisted and line in enemy.enemy_data.weak_to
	var at: Vector2 = tower.global_position if kind == TowerData.AttackKind.PULSE else enemy.global_position
	var tonal := data.line == "song"
	var pitch := 1.0 if tonal else _weight_pitch(enemy) * pow(CHAIN_STEP_PITCH, hits_before)
	var volume := HIT_DB + _rate_db(_hit_rate(data)) + CHAIN_STEP_DB * hits_before \
		+ (RESISTED_DB if resisted else WEAK_DB if weak else 0.0)
	var bus := _bus_for(tower)
	if resisted:
		var dull := StringName("%s_dull" % id)
		if sound.has_sound(dull):
			id = dull
		else:
			bus = &"SFXMuffled"
	sound.play(id, at, volume, pitch, 0.0 if tonal else 0.05, bus)
	if weak:  # Fuller and louder, never brighter: an extra low body under the hit
		sound.play(&"hit_full", at, HIT_DB - 2.0 + _rate_db(_hit_rate(data)), _weight_pitch(enemy), 0.05, bus)

# Hits on big or tanky nightmares land lower and fuller, on small ones lighter and higher.
static func _weight_pitch(enemy: Node2D) -> float:
	return _weight_pitch_for(enemy.enemy_data.health, enemy.elite, enemy.enemy_data.is_boss)

static func _weight_pitch_for(base_health: int, elite: bool, boss: bool) -> float:
	if boss:
		return 0.8
	var health := float(base_health) * (3.0 if elite else 1.0)  # Deeply Blighted: ×3 health
	return clampf(1.0 - 0.12 * log(maxf(health, 1.0) / 100.0) / log(2.0), 0.82, 1.15)

# --- Reactions (audio_direction.md 5594129) --------------------------------------------------------
# One sound per Reaction event, sized by how many nightmares it caught (counted around where it
# landed), throttled per type. Crowned ones add the shared crown swell, their signature and a small
# duck, and count as 2 links. Chains build a warm swell link by link, never higher; ×5 surges,
# ×10 is the Dawnburst with its stinger.

func _on_node_added(node: Node) -> void:
	if node is ReactionTracker and not node.reaction_fired.is_connected(_on_reaction):
		node.reaction_fired.connect(_on_reaction)
		node.chain_reached.connect(_on_chain)
	_hook_kinships(node)
	_hook_economy(node)

# Kinships (tower_design.md "Kinships"): whichever node carries these signals (Tower Code's), hooked
# when it joins the tree. Rewarding but quiet: bonds and stage-ups are chords at rests, the Harmony
# strike is a very quiet, throttled chime under the Reactions, Whole is the biggest (below bosses).
func _hook_kinships(node: Node) -> void:
	if node.has_signal("kin_bonded") and not node.is_connected("kin_bonded", _on_kin_bonded):
		node.connect("kin_bonded", _on_kin_bonded)
	if node.has_signal("kin_stage_grew") and not node.is_connected("kin_stage_grew", _on_kin_stage_grew):
		node.connect("kin_stage_grew", _on_kin_stage_grew)
	if node.has_signal("harmony_struck") and not node.is_connected("harmony_struck", _on_harmony_struck):
		node.connect("harmony_struck", _on_harmony_struck)
	if node.has_signal("family_whole") and not node.is_connected("family_whole", _on_family_whole):
		node.connect("family_whole", _on_family_whole)

func _on_kin_bonded(family: String, _where: Vector2 = Vector2.ZERO) -> void:
	var id := StringName("kin_bond_" + family)
	sound.play(id if sound.has_sound(id) else &"kin_bond", null, KIN_DB, 1.0, 0.0, &"UI")

func _on_kin_stage_grew(_family: String, _stage: int = 0, _where: Vector2 = Vector2.ZERO) -> void:
	sound.play(&"kin_stage_up", null, KIN_DB, 1.0, 0.0, &"UI")

func _on_harmony_struck(_tower: Node, enemy: Node2D = null) -> void:
	var now := Time.get_ticks_msec()
	if now - _harmony_at < HARMONY_THROTTLE_MS:
		return
	_harmony_at = now
	sound.play(&"harmony_strike", enemy.global_position if is_instance_valid(enemy) else null, HARMONY_DB, 1.0, 0.0)

func _on_family_whole(_family: String) -> void:
	sound.duck(3.0, 0.5)
	sound.play(&"whole_tree", null, WHOLE_DB, 1.0, 0.0, &"UI")


# Economy (Tower Code's catchers): any node with these signals, like the Kinships. A caught drop is a
# very quiet, throttled droplet; the rest's harvest gathers every catcher's pour in that frame into
# one warm pour, fuller with the amount; the Wellspring's interest is a gentle ripple.
func _hook_economy(node: Node) -> void:
	for pair in [["dew_caught", _on_dew_caught], ["harvest_poured", _on_harvest_poured], ["interest_paid", _on_interest_paid]]:
		if node.has_signal(pair[0]) and not node.is_connected(pair[0], pair[1]):
			node.connect(pair[0], pair[1])

# `amount` is a float (Tower Code fa57ad9), so it's untyped here.
func _on_dew_caught(_tower: Node = null, where: Variant = null, _amount = 0) -> void:
	var now := Time.get_ticks_msec()
	if now - _dew_catch_at < DEW_CATCH_THROTTLE_MS:
		return
	_dew_catch_at = now
	sound.play(&"dew_catch", where if where is Vector2 else null, DEW_CATCH_DB, 1.0, 0.04)

# The Harvest: the catchers pour one after another (~0.25 s apart) at the rest. The first pour plays the
# harvest, sized by its amount; the rest of that rest's pours add soft droplets under it. Unpositioned:
# the Dream screen pauses the game (and the world's positional players) while it plays.
func _on_harvest_poured(_tower: Node = null, amount = 0) -> void:
	var now := Time.get_ticks_msec()
	if now - _harvest_at > HARVEST_WINDOW_MS:
		_harvest_at = now
		var growth := minf(ASCENDED_GROWTH_DB * log(1.0 + maxf(float(amount), 1.0) / 10.0) / log(2.0), ASCENDED_GROWTH_MAX)
		sound.play(&"harvest", null, HARVEST_DB - ASCENDED_GROWTH_MAX + growth, 1.0, 0.0, &"UI")
	else:
		sound.play(&"dew_catch", null, DEW_CATCH_DB + 4.0, 1.0, 0.04, &"UI")

func _on_interest_paid(_tower: Node = null, _amount = 0) -> void:
	sound.play(&"interest_ripple", null, KIN_DB, 1.0, 0.0, &"UI")

func _on_reaction(id: StringName, enemy: Node2D, _chain: int, _towers: Array) -> void:
	if not is_instance_valid(enemy):
		return
	var crowned := Reactions.is_crowned(id)
	_last_reaction_crowned = crowned
	var now := Time.get_ticks_msec()
	if now - int(_reaction_at.get(id, -100000)) < REACTION_THROTTLE_MS:
		return
	_reaction_at[id] = now
	var base: StringName = Reactions.CROWNED_BASE.get(id, id)
	var where := enemy.global_position
	var caught := _nightmares_near(where, REACTION_REACH_CELLS)
	var growth := minf(ASCENDED_GROWTH_DB * log(1.0 + caught) / log(2.0), ASCENDED_GROWTH_MAX)
	var volume := REACTION_DB - ASCENDED_GROWTH_MAX + growth + (REACTION_BOSS_DB if enemy.enemy_data.is_boss else 0.0)
	var reaction_id := StringName("reaction_" + base)
	if sound.has_sound(reaction_id):
		sound.play(reaction_id, where, volume, 1.0, 0.03)
	if crowned:
		sound.duck(3.0, 0.5)
		sound.play(&"crown_swell", where, volume - 3.0, 1.0, 0.0)
		var signature := StringName("crowned_" + id)
		if sound.has_sound(signature):
			sound.play(signature, where, volume, 1.0, 0.02)

# A chain reached `count` links: the warm swell under it builds each link (a Crowned counts 2).
func _on_chain(count: int, where: Vector2, _towers: Array) -> void:
	var links := count + (1 if _last_reaction_crowned else 0)
	if count >= DAWNBURST_LINKS and not _dawnburst_played:
		_dawnburst_played = true
		sound.duck(8.0, 1.0)
		sound.play(&"chain_dawnburst", where, REACTION_DB + 2.0, 1.0, 0.0)
		get_tree().create_timer(STINGER_DELAY).timeout.connect(func() -> void:
			sound.play(&"stinger_dawnburst", null, -4.0, 1.0, 0.0, &"Music"))
		return
	if count < DAWNBURST_LINKS:
		_dawnburst_played = false
	if count == SURGE_LINKS:
		sound.duck(3.0, 0.5)
		sound.play(&"chain_surge", where, REACTION_DB, 1.0, 0.0)
		return
	sound.play(&"chain_swell", where, CHAIN_SWELL_DB + CHAIN_SWELL_STEP_DB * minf(links - 2, 6), 1.0, 0.0)

func _nightmares_near(where: Vector2, cells: float) -> int:
	var reach := cells * MAP_GRID.cell_size.x
	var count := 0
	for enemy in enemy_container.get_enemies():
		if enemy.global_position.distance_to(where) <= reach:
			count += 1
	return maxi(count, 1)

func _on_path_changed() -> void:
	_path_pixels = maxf(map_generator.get_path_from(map_generator.startPath).size() * MAP_GRID.cell_size.x, 1.0)
	if is_node_ready() and tower_container.get_child_count() > 0:
		sound.play(&"path_shimmer", null, -10.0, 1.0, 0.0)

func _on_run_ended(won: bool) -> void:
	sound.stop_music()
	sound.play(&"win" if won else &"loss", null, 0.0, 1.0, 0.0, &"UI")
