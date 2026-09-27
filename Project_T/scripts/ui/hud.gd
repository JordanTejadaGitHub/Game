extends CanvasLayer

@onready var build_button: Button = %BuildButton
@onready var tower_placer: TowerPlacer = %TowerPlacer

func _ready() -> void:
	build_button.toggled.connect(tower_placer.set_build_mode)
	# Keep the button in sync when build mode is toggled with B / cancelled with Esc or right-click.
	tower_placer.build_mode_changed.connect(build_button.set_pressed_no_signal)
