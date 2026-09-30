extends Node2D
class_name ColdLantern

# The Lamplighter's cold lantern (enemy_design.md, "Boss pools"): lit on an empty cell beside the
# route, it slows Wardens within `radius` cells (the EnemyContainer applies the slow each frame). It
# burns out after `life` seconds, when the Lamplighter is dispelled, or when the player clicks it
# (snuffed: + `snuff_dew` Dew). Never blocks the path: it's only a light.

signal snuffed(lantern: ColdLantern, by_player: bool)

const COLOR := Palette.DEWLIGHT
const CLICK_RADIUS := 24.0
const FADE_TIME := 0.4

var cell := Vector2.ZERO
var radius := 1.5  # Cells
var life := 16.0
var snuff_dew := 2
var owner_boss: Node2D = null
var cell_size := 64.0
var _age := 0.0
var _out := false

func _ready() -> void:
	z_index = 2  # Over the ground, under the nightmares' bars
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _process(delta: float) -> void:
	if _out:
		return
	_age += delta
	if _age >= life:
		snuff(false)
		return
	queue_redraw()

func is_lit() -> bool:
	return not _out

# Radius in pixels of the cold light (for the slow and the drawing).
func get_reach() -> float:
	return radius * cell_size

func snuff(by_player: bool) -> void:
	if _out:
		return
	_out = true
	snuffed.emit(self, by_player)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(queue_free)

func _unhandled_input(event: InputEvent) -> void:
	if _out or not (event is InputEventMouseButton) or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if get_global_mouse_position().distance_to(global_position) <= CLICK_RADIUS:
		get_viewport().set_input_as_handled()
		snuff(true)

func _draw() -> void:
	var flicker := 0.85 + 0.15 * sin(_age * 9.0 + cell.x)
	var fade := clampf((life - _age) / 2.0, 0.3, 1.0)  # Gutters in its last seconds
	draw_circle(Vector2.ZERO, get_reach(), Color(COLOR, 0.07 * fade))
	draw_arc(Vector2.ZERO, get_reach(), 0.0, TAU, 48, Color(COLOR, 0.25 * fade), 1.5)
	# The lantern: a dark post with a cold flame in a small cage
	draw_line(Vector2(0, 14), Vector2(0, -6), Palette.VOID, 3.0)
	draw_rect(Rect2(-6, -18, 12, 12), Palette.NIGHT)
	draw_circle(Vector2(0, -12), 4.5 * flicker, Color(COLOR, 0.95 * fade))
	draw_circle(Vector2(0, -12), 9.0 * flicker, Color(COLOR, 0.3 * fade))
