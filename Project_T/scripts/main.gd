extends Node

# The run's flow (build phase, drifts, win/lose) lives in DriftDirector; resources in RunState.

func _ready() -> void:
	if CaptureDirector.wanted():  # Capture mode or a scripted capture (debug builds, marketing.md §3)
		add_child(CaptureDirector.new())
