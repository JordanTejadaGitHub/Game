extends SceneTree

# WASD panning stays steady when hit-stop / slow motion changes Engine.time_scale mid-frame (user: "I jump around
# the screen while using WASD when a wave is there"): the step is never the old delta divided by the new scale.

var failures := 0

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok: ", what)
	else:
		failures += 1
		push_error("FAIL: " + what)

# Runs before the camera each frame and changes time_scale there, as Fx's hit-stop does.
class Stopper extends Node:
	var set_scale := -1.0
	func _process(_delta: float) -> void:
		if set_scale >= 0.0:
			Engine.time_scale = set_scale
			set_scale = -1.0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_camera_pan_%d.json" % OS.get_process_id()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var camera := main.get_node("GameCameraNode")
	var stopper := Stopper.new()
	stopper.process_priority = -1000
	stopper.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(stopper)
	camera.target_position = Vector2(700, 560)  # Mid-map: no clamping in the way
	Input.action_press("move_camera_right")
	await process_frame
	var x: float = camera.target_position.x
	await process_frame
	var normal: float = camera.target_position.x - x
	_check(normal > 1.0, "WASD pans (%.1f px a frame)" % normal)

	# Hit-stop starts mid-frame: this frame's delta was scaled by 1.0, the new scale is 0.05.
	x = camera.target_position.x
	stopper.set_scale = 0.05
	await process_frame
	var hit: float = camera.target_position.x - x
	_check(absf(hit - normal) < normal * 0.25, "a mid-frame hit-stop keeps the step (%.1f px, normal %.1f)" % [hit, normal])
	# During the slow motion the camera still pans in real time.
	x = camera.target_position.x
	await process_frame
	var slow: float = camera.target_position.x - x
	_check(absf(slow - normal) < normal * 0.25, "slow motion pans at normal speed (%.1f px)" % slow)
	# It ends mid-frame too: this delta was scaled by 0.05, the new scale is 1.0.
	x = camera.target_position.x
	stopper.set_scale = 1.0
	await process_frame
	var back: float = camera.target_position.x - x
	_check(absf(back - normal) < normal * 0.25, "and when it ends (%.1f px)" % back)
	_check(camera.MAX_STEP * camera.camera_speed < 200.0, "a long hitch moves at most %d px" % int(camera.MAX_STEP * camera.camera_speed))

	Input.action_release("move_camera_right")
	Engine.time_scale = 1.0
	stopper.queue_free()
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("PASS" if failures == 0 else "FAILURES: %d" % failures)
	quit(failures)
