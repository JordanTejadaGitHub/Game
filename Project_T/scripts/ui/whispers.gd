extends Label

# Heartwood whispers (onboarding.md): one-line italic hints at the top of the screen, in the story's
# voice, each shown the first time it matters and then never again (remembered in HeartwoodMemory).
# Off when the "Heartwood whispers" setting is off. Mostly polls simple conditions each frame, so it
# needs no hooks in the systems it teaches.

const SHOW_TIME := 5.0
const TEXT := {
	&"start": "Something moves at the edge of the dream.",
	&"plant": "Plant a Warden near the path.",
	&"first_cleanse": "Nightmares. They're coming for the dream. Don't let them reach me.",
	&"walls": "Wardens are walls. Make them take the long way.",
	&"flow": "They don't stop. They come in drifts, like fog.",
	&"speed": "Pause if you need to think. They'll wait.",
	&"rest": "Rest here. Rearrange the forest; nothing is lost.",
	&"save": "The forest will wait for you.",
	&"cage": "A dream can bend, but never close.",
	&"grow": "This Sprout could grow.",
	&"tend": "Tend the forest, and it will remember you.",
	&"leaf": "It fed. A leaf blackens and falls.",
	&"sell": "Selling gives everything back during a rest, and half while nightmares walk.",
	&"boss": "Something old has found the dream.",
	&"after_boss": "It's gone, and something I'd forgotten came back.",
	&"again": "The Heartwood dreams again.",
	&"damp": "Damp: slower, and lightning loves it.",
	&"drowsy": "Drowsy: heavy-eyed and slow.",
	&"spored": "Spored: the spores keep eating at it.",
	&"marked": "Marked: every Warden hits it harder.",
	&"static": "Static: five charges, and a bolt.",
	&"held": "Held: it can't move. Now's the time.",
}

@onready var run_state: RunState = %RunState
@onready var drift_director: DriftDirector = %DriftDirector
@onready var tower_placer: TowerPlacer = %TowerPlacer
@onready var obstacle_clearer: ObstacleClearer = %ObstacleClearer
@onready var tower_container: Node2D = %TowerContainer
@onready var dream_state: DreamState = %DreamState

var enabled := true
var _seen: Array = []
var _queue: Array[StringName] = []
var _tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var memory := HeartwoodMemory.load_data()
	enabled = memory.settings.whispers
	_seen = memory.get("whispers_seen", [])
	modulate.a = 0.0
	if not enabled:
		set_process(false)
		return
	if not _seen.has("start"):
		_glide_along_path.call_deferred()  # After the camera is ready
	if memory.runs_played > 0:
		whisper(&"again")
	whisper(&"start")
	whisper(&"plant")
	var spawner = %EnemyContainer
	spawner.enemy_cleansed.connect(func(_e: Node2D) -> void: whisper(&"first_cleanse"), CONNECT_ONE_SHOT)
	drift_director.family_pick_requested.connect(func(reason: StringName) -> void:
		if reason == &"first":
			whisper(&"walls")
		else:
			whisper(&"after_boss"))
	drift_director.drift_started.connect(func(number: int) -> void:
		if number == 2:
			whisper(&"flow")
			whisper(&"speed"))
	drift_director.rest_started.connect(func(_block: int, _boss: bool, _bonus: int, _perfect: bool) -> void:
		whisper(&"rest")
		whisper(&"save")
		if drift_director.is_boss_drift(drift_director.drifts_started + drift_director.drifts_per_block):
			whisper(&"boss"))
	run_state.leaves_changed.connect(func(leaves: int, _max: int) -> void:
		if leaves < run_state.max_leaves:
			whisper(&"leaf"))
	%TowerSeller.tower_sold.connect(func(_t: Tower, _refund: int) -> void: whisper(&"sell"), CONNECT_ONE_SHOT)

# First run: the camera glides from the forest's edge to the Heartwood along the path.
func _glide_along_path() -> void:
	var camera := get_tree().get_first_node_in_group(&"game_camera")
	if camera == null:
		return
	var map_generator = %MapGenerator
	var cells: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	var points := PackedVector2Array()
	for i in range(0, cells.size(), maxi(cells.size() / 12, 1)):
		points.append(map_generator.MAP_GRID.calculate_map_position(cells[i]))
	points.append(map_generator.MAP_GRID.calculate_map_position(cells[-1]))
	camera.glide(points, 6.0)

# Shows `id` once ever (queued behind whatever is showing).
func whisper(id: StringName) -> void:
	if not enabled or _seen.has(String(id)) or _queue.has(id):
		return
	_queue.append(id)
	if _queue.size() == 1:
		_show_next()

func _show_next() -> void:
	if _queue.is_empty():
		return
	var id: StringName = _queue[0]
	_seen.append(String(id))
	_remember()
	text = TEXT.get(id, "")
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.4)
	_tween.tween_interval(SHOW_TIME)
	_tween.tween_property(self, "modulate:a", 0.0, 0.8)
	_tween.tween_callback(func() -> void:
		_queue.pop_front()
		_show_next())

# Conditions that are easiest to notice by looking.
func _process(_delta: float) -> void:
	if tower_placer.hover_breaks_path():
		whisper(&"cage")
	if obstacle_clearer._hover_obstacle != null:
		whisper(&"tend")
	for id in EnemyStatuses.ALL:
		if not _seen.has(String(id)) and _any_creature_has(id):
			whisper(id)
	if not _seen.has("grow"):
		for tower in tower_container.get_children():
			if tower is Tower and tower.tower_data.get_id() == "sprout":
				for option in dream_state.get_evolutions(tower.tower_data):
					if option[1] and run_state.can_afford(dream_state.get_evolve_cost(option[0])):
						whisper(&"grow")
						return

func _any_creature_has(id: StringName) -> bool:
	for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
		if enemy.statuses.has(id):
			return true
	return false

# Remembered in the player's profile, except in tests (the scene isn't the running game there).
func _remember() -> void:
	if get_tree().current_scene != owner:
		return
	var memory := HeartwoodMemory.load_data()
	memory["whispers_seen"] = _seen
	HeartwoodMemory.save_data(memory)
