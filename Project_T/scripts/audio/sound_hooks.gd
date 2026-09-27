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
const LOW_LEAVES := 5
const ATTACK_DB := -9.0
const QUIET_LINES := ["wall"]  # Wardens that never attack

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
	enemy_container.enemy_reached_goal.connect(func(_enemy: Node2D) -> void: sound.play(&"leaf_lost", null, 0.0, 1.0, 0.03))
	enemy_container.enemy_split.connect(func(parent: Node2D, child: Node2D) -> void:
		if parent.is_cleansed:  # Followers (Wraiths) also come through here; only real splits crack
			sound.play(&"split", child.global_position, -4.0))
	enemy_container.wall_trampled.connect(func(cell: Vector2, _by: Node2D) -> void:
		sound.play(&"trample", MAP_GRID.calculate_map_position(cell), 2.0))

	tower_container.child_entered_tree.connect(_on_tower_added)
	tower_placer.tower_built.connect(func(tower: Tower) -> void: sound.play(&"plant", tower.global_position))
	tower_placer.build_rejected.connect(func(_cell: Vector2) -> void: sound.ui(&"invalid"))
	tower_seller.tower_sold.connect(func(tower: Tower, _refund: int) -> void:
		sound.play(&"sell", MAP_GRID.calculate_map_position(tower.cell)))
	map_generator.obstacle_cleared.connect(func(cell: Vector2, data: ObstacleData) -> void:
		var id := &"move" if data.resource_path.get_file().begins_with("rock") else &"tend"
		sound.play(id, MAP_GRID.calculate_map_position(cell)))
	map_generator.path_changed.connect(_on_path_changed)

	run_state.dew_short.connect(func(_cost: int) -> void: sound.ui(&"invalid"))
	run_state.dew_earned.connect(func(_amount: int, where: Vector2) -> void: sound.play(&"dew", where, -8.0))
	run_state.run_ended.connect(_on_run_ended)

	drift_director.drift_started.connect(func(_number: int) -> void: sound.play(&"drift_start", null, -4.0, 1.0, 0.0))
	drift_director.rest_started.connect(func(_block: int, _boss: bool, _bonus: int, _perfect: bool) -> void:
		sound.play(&"rest", null, -2.0, 1.0, 0.0))
	drift_director.act_started.connect(func(_act: int, _regrown: int) -> void: sound.play(&"act_swell", null, 0.0, 1.0, 0.0))
	drift_director.family_pick_requested.connect(func(_reason: StringName) -> void:
		sound.play(&"family_bell", null, 0.0, 1.0, 0.0, &"UI"))
	dream_state.offer_ready.connect(func(_cards: Array[UpgradeData], _drift: int) -> void:
		sound.play(&"dream_open", null, -2.0, 1.0, 0.0, &"UI"))
	dream_state.card_taken.connect(func(card: UpgradeData) -> void:
		sound.play(StringName("dream_take_%d" % clampi(int(card.rarity), 0, 2)), null, 0.0, 1.0, 0.0, &"UI"))
	omen_director.offer_ready.connect(func(_omens: Array[OmenData], _block: int) -> void:
		sound.play(&"omen_wind", null, -2.0, 1.0, 0.0, &"UI"))

	sound.play_music(&"act1", [&"base"])
	sound.play_ambience(&"act1")
	_on_path_changed()

func _exit_tree() -> void:
	if sound != null:
		sound.set_muffled(false)
		sound.stop_ambience()

func _process(_delta: float) -> void:
	var enemies: Array = enemy_container.get_enemies()
	var near := false
	var boss := false
	for enemy in enemies:
		boss = boss or enemy.enemy_data.is_boss
		near = near or enemy.get_remaining_distance() < _path_pixels / 3.0
	sound.set_layer(&"dread1", not enemies.is_empty())
	sound.set_layer(&"dread2", enemies.size() >= DREAD2_COUNT or near)
	sound.set_layer(&"heartbeat", run_state.leaves <= LOW_LEAVES and not run_state.is_over)
	sound.set_layer(&"boss", boss)
	sound.set_muffled(_choice_screens.any(func(screen: Control) -> bool: return screen.visible))

func _on_enemy_added(enemy: Node) -> void:
	# Its position is set right after it enters the tree, so wait a frame.
	_play_signature.call_deferred(enemy)
	if enemy.has_signal("leaped"):
		enemy.leaped.connect(func(e: Node2D) -> void: sound.play(&"hag_rise", e.global_position))

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
	# Deeply Blighted: the same sound, pitched down.
	sound.play(id, enemy.global_position, 2.0 if enemy.enemy_data.is_boss else -3.0, 0.8 if enemy.elite else 1.0)

func _on_tower_added(node: Node) -> void:
	var tower := node as Tower
	if tower == null:
		return
	if not tower.attack_released.is_connected(_on_attack):
		tower.attack_released.connect(_on_attack)
		tower.evolved.connect(func(t: Tower) -> void: sound.play(&"evolve", t.global_position))
		tower.crit_landed.connect(func(_t: Tower, enemy: Node2D) -> void:
			sound.play(&"crit", enemy.global_position, -6.0))
		# Sunpetal / Midsummer: the hum climbs as the beam ramps up (ramp 1 -> 4 or 5).
		tower.beam_ticked.connect(func(t: Tower, ramp: float) -> void:
			sound.play(&"beam", t.global_position, ATTACK_DB, 1.0 + (ramp - 1.0) * 0.08, 0.0))

func _on_attack(tower: Tower) -> void:
	var line: String = tower.tower_data.line
	if QUIET_LINES.has(line):
		return
	var id := StringName("attack_" + line)
	if not sound.has_sound(id):
		id = &"attack_sprout"
	sound.play(id, tower.global_position, ATTACK_DB)

func _on_path_changed() -> void:
	_path_pixels = maxf(map_generator.get_path_from(map_generator.startPath).size() * MAP_GRID.cell_size.x, 1.0)
	if is_node_ready() and tower_container.get_child_count() > 0:
		sound.play(&"path_shimmer", null, -10.0, 1.0, 0.0)

func _on_run_ended(won: bool) -> void:
	sound.stop_music()
	sound.play(&"win" if won else &"loss", null, 0.0, 1.0, 0.0, &"UI")
