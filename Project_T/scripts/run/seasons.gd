extends CanvasModulate

# Between acts the season changes (run_design.md: spring → summer → autumn, visual only). Tints the
# world (not the HUD) and eases into the new season at each act break.

@export var season_colors: Array[Color] = [
	Color(1, 1, 1),  # Act 1, Forest's Edge: spring
	Color(1.0, 0.96, 0.86),  # Act 2, Deep Wood: summer
	Color(1.0, 0.88, 0.74),  # Act 3, Misty Hollow: autumn
	Color(0.9, 0.93, 1.0),  # Act 4, Heartwood Glade: first frost
]
@export var change_time: float = 3.0

@onready var drift_director: DriftDirector = %DriftDirector

func _ready() -> void:
	color = season_colors[0]
	drift_director.act_started.connect(func(act: int, _regrown: int) -> void: set_act(act))
	drift_director.rest_ended.connect(func(_block: int) -> void:
		set_act(drift_director.get_act(drift_director.drifts_started + 1), false))

func set_act(act: int, animate: bool = true) -> void:
	var target := season_colors[clampi(act, 1, season_colors.size()) - 1]
	if not animate:
		color = target
		return
	create_tween().tween_property(self, "color", target, change_time)
