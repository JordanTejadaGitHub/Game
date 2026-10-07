class_name UiTime
extends RefCounted

# Speed only changes gameplay (user 2026-10-07: "make sure speed only changes gameplay speed, it shouldn't change
# everything else like Dream pick animations"; screens_ui.md 80fc4c25, principle 4). GameSpeed sets Engine.time_scale,
# which speeds up every tween, timer and _process delta. Screens and the HUD use these instead, so ×2 / ×3 speeds up
# only the field (nightmares, Wardens, attacks, map effects, statuses, drift timers); the camera already does the same.

# A tween on `node` that runs in real time (time scale ignored); pause mode as `node`'s unless `always` (PROCESS while
# the game is paused, for the paused choice screens).
static func tween(node: Node, always := true) -> Tween:
	var t := node.create_tween().set_ignore_time_scale(true)
	if always:
		t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	return t

# A one-shot timer of `seconds` real time (time scale ignored), running while paused when `always`.
static func timer(node: Node, seconds: float, always := true) -> SceneTreeTimer:
	return node.get_tree().create_timer(seconds, always, false, true)

# A _process delta turned back into real seconds (as GameCameraNode does).
static func delta(scaled: float) -> float:
	return scaled / Engine.time_scale if Engine.time_scale > 0.0 else scaled
