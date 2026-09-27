class_name Heartwood
extends Sprite2D

# The goal tree on the end cell (art_direction.md). It shows leaves lost: each one blackens a patch of
# canopy and dims the hollow (heartwood.png: row = leaves lost 0-20, EnvironmentTiles.FRAMES per row).
# Position it at the goal cell's centre; the sprite's bottom centre sits 8 px below the cell's bottom.

const BASE_BELOW_CELL := 8.0

var run_state: RunState  # Optional: without one the tree stays whole
var _frame_time := 0.0

func _ready() -> void:
	texture = load(EnvironmentTiles.sheet_path(EnvironmentTiles.HEARTWOOD, 1))
	hframes = EnvironmentTiles.FRAMES
	vframes = EnvironmentTiles.HEARTWOOD_STATES
	var half_cell := EnvironmentTiles.SIZE.y / 2.0
	offset = Vector2(0, half_cell + BASE_BELOW_CELL - EnvironmentTiles.HEARTWOOD_SIZE / 2.0)
	if run_state != null:
		run_state.leaves_changed.connect(_on_leaves_changed)
		_on_leaves_changed(run_state.leaves, run_state.max_leaves)

func _process(delta: float) -> void:
	_frame_time = fmod(_frame_time + delta * EnvironmentTiles.FPS, EnvironmentTiles.FRAMES)
	frame_coords.x = int(_frame_time)

# The tree is the same warm moss-gold in every act; only its sheet's folder changes.
func set_act(act: int) -> void:
	texture = load(EnvironmentTiles.sheet_path(EnvironmentTiles.HEARTWOOD, act))

func _on_leaves_changed(leaves: int, max_leaves: int) -> void:
	var lost := 1.0 - float(leaves) / maxf(max_leaves, 1)
	frame_coords.y = clampi(roundi(lost * (EnvironmentTiles.HEARTWOOD_STATES - 1)), 0, EnvironmentTiles.HEARTWOOD_STATES - 1)
