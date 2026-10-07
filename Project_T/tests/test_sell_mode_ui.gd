extends SceneTree

# Sell mode's HUD (maze_feel.md 9356ec5a; Tower Code a5d16d5f): while it's on, a hint above the Warden bar says how to
# use and leave it and the bar steps back; both go when it ends. Temp profile.

var failures := 0

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok: ", what)
	else:
		failures += 1
		push_error("FAIL: " + what)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_sell_mode_ui_%d.json" % OS.get_process_id()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var hud := main.get_node("HUD")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var bar := main.get_node("%TowerBar") as Control
	seller.set_sell_mode(true)
	await process_frame
	var hint := hud.get_node_or_null("SellModeHint") as Control
	_check(hint != null and hint.visible and (hint.get_child(0) as Label).text.contains("Right-click or Esc"),
		"sell mode: the hint shows")
	_check(bar.modulate.a < 1.0, "…and the Warden bar steps back")
	seller.set_sell_mode(false)
	await process_frame
	_check(hint != null and not hint.visible and is_equal_approx(bar.modulate.a, 1.0), "leaving sell mode clears both")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("sell mode ui test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)
