extends Node

# Hide all UI (user, 2026-10-21: "a hotkey to hide all the ui"): U hides every CanvasLayer in the current
# scene (HUD, side panels, overlays) so only the map shows; U again brings back the ones it hid. Screens
# whose root is a Control (title, Memory Grove) are all UI, so the key does nothing there. A layer that
# opens while hidden (a choice screen) shows as normal. Autoload; a focused text box keeps the key.

const HIDE_KEY := KEY_U  # H is "centre on the Heartwood"

var _hidden: Array[CanvasLayer] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Works on a paused tree too
	get_tree().scene_changed.connect(_on_scene_changed)

func _on_scene_changed() -> void:
	_hidden.clear()

func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.physical_keycode != HIDE_KEY:
		return
	if key.ctrl_pressed or key.alt_pressed or key.meta_pressed:
		return
	if toggle():
		get_viewport().set_input_as_handled()

# True when it hid or showed something.
func toggle() -> bool:
	if not _hidden.is_empty():
		for layer in _hidden:
			if is_instance_valid(layer):
				layer.visible = true
		_hidden.clear()
		return true
	var scene := get_tree().current_scene
	if scene == null or scene is Control:
		return false
	for node in scene.find_children("*", "CanvasLayer", true, false):
		var layer := node as CanvasLayer
		if layer.visible and layer.layer > 0:
			layer.visible = false
			_hidden.append(layer)
	return not _hidden.is_empty()
