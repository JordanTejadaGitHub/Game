extends CanvasModulate

# Between acts the season changes (run_design.md, art_direction.md: spring dusk → summer night →
# autumn fog → winter dark, visual only). Each act has its own environment palette
# (MapGenerator.set_act swaps the sheets); this node can add a world tint on top (not the HUD),
# eased in at each act break. The palettes already carry the season, so the tints start neutral.

@export var season_colors: Array[Color] = [
	Color(1, 1, 1),  # Act 1, Forest's Edge: spring dusk
	Color(1, 1, 1),  # Act 2, Deep Wood: summer night
	Color(1, 1, 1),  # Act 3, Misty Hollow: autumn fog
	Color(1, 1, 1),  # Act 4, Heartwood Glade: winter dark
]
@export var change_time: float = 3.0

@onready var drift_director: DriftDirector = %DriftDirector
@onready var map_generator: Node2D = %MapGenerator

var _act := 1

func _ready() -> void:
	color = season_colors[0]
	drift_director.act_started.connect(func(act: int, _regrown: int) -> void: set_act(act))
	drift_director.rest_ended.connect(func(_block: int) -> void:
		set_act(drift_director.get_act(drift_director.drifts_started + 1), false))
	# A resumed run (RunSaver) starts resting in its saved act: catch up on its first phase change.
	drift_director.build_phase_changed.connect(func(_building: bool) -> void:
		set_act(drift_director.get_act(drift_director.drifts_started + 1), false), CONNECT_ONE_SHOT)

func set_act(act: int, animate: bool = true) -> void:
	act = clampi(act, 1, season_colors.size())
	if act == _act:
		return
	_act = act
	map_generator.set_act(act)
	var target := season_colors[act - 1]
	if not animate:
		color = target
		return
	create_tween().tween_property(self, "color", target, change_time)
