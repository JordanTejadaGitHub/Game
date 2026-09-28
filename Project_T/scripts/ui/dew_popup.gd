extends Node2D
class_name DewPopup

# "+3 Dew" that floats up from where Dew was earned and fades out. Script-only node.

const RISE := 36.0  # Pixels it floats up
const DURATION := 0.9
const COLOR := Color(0.55, 0.85, 1.0)

var _text: String

func _init(amount: int, world_position: Vector2) -> void:
	_text = "+%d Dew" % amount
	position = world_position
	z_index = 10  # Above creatures and Wardens

func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - RISE, DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, DURATION * 0.5).set_delay(DURATION * 0.5)
	tween.tween_callback(queue_free)

func _draw() -> void:
	WorldLabel.draw_tag(self, 0.0, -32.0, _text, COLOR)
