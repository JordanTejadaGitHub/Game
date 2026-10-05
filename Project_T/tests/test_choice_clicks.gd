extends SceneTree

# Choice cards answer real clicks (user, 2026-10-05, family pick: "buttons don't really do anything here"): a mouse
# press and release at the drawn cue's position picks the card (pushed through the viewport, not `pressed.emit`), and
# the cue lights with the card (ChoiceCard.link_cue). A boss dossier left open when the block starts closes, so its
# full-screen shield never sits over the family pick. Temp profile and run save; the window is 1280 x 800.

var failures := 0

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok: ", what)
	else:
		failures += 1
		push_error("FAIL: " + what)

func _initialize() -> void:
	_run.call_deferred()

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _move(at: Vector2) -> void:
	var move := InputEventMouseMotion.new()
	move.position = at
	move.global_position = at
	root.push_input(move)
	await _frames(2)

func _click(at: Vector2) -> void:
	await _move(at)
	for pressed in [true, false]:
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = pressed
		press.position = at
		press.global_position = at
		root.push_input(press)
		await _frames(1)

# The cue shows the look of `state` (its own theme stylebox for it).
func _cue_shows(cue: Button, state: String) -> bool:
	cue.remove_theme_stylebox_override("normal")  # Read its own look, then put the shown one back
	var own := cue.get_theme_stylebox(state)
	var normal := cue.get_theme_stylebox("normal")
	cue.queue_redraw()
	var card := cue.get_parent()
	while card != null and not card is Button:
		card = card.get_parent()
	(card as Button).queue_redraw()
	await _frames(1)
	var shown := cue.get_theme_stylebox("normal")
	return shown == own and (state == "normal" or shown != normal)

func _run() -> void:
	var pid := OS.get_process_id()
	HeartwoodMemory.file_path = "user://test_choice_clicks_%d.json" % pid
	RunSaver.file_path = "user://test_choice_clicks_run_%d.json" % pid
	ResultsScreen.demo_override = 0
	root.size = Vector2i(1280, 800)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 4242
	root.add_child(main)
	await _frames(2)
	var family: Control = main.get_node("%FamilyPickScreen")
	var drifts: DriftDirector = main.get_node("%DriftDirector")
	var dossier: Control = main.get_node("HUD/BossDossier")

	# A dossier open as the block starts some other way than Face it: it closes, and the pick after drift 1 is clickable.
	dossier.open()
	_check(dossier.visible, "the dossier is open at the first rest")
	drifts.start_next_drift()
	await _frames(1)
	_check(not dossier.visible, "starting the block closes the dossier")
	Engine.time_scale = 4.0
	var frames := 0
	while not family.visible and frames < 20000:
		await process_frame
		frames += 1
	Engine.time_scale = 1.0
	_check(family.visible, "the family pick after drift 1")
	await _frames(int(ChoiceArm.ARM_TIME * 60.0) + 10)
	var card: Button = family._cards.get_child(0)
	var wake: Button = card.find_child("Wake", true, false)
	var at := wake.get_global_rect().get_center()
	await _move(at)
	_check(root.gui_get_hovered_control() == card, "the card is what's under the Wake cue (%s)" % root.gui_get_hovered_control())
	_check(await _cue_shows(wake, "hover"), "hovering the card lights Wake")
	await _move(Vector2(4, 4))
	_check(await _cue_shows(wake, "normal"), "Wake goes back when the pointer leaves")
	var picked := [false]
	card.pressed.connect(func() -> void: picked[0] = true)
	await _click(at)
	await _frames(2)
	_check(picked[0] and not family.visible, "a click on Wake picks the family and closes the screen")

	# The Omen screen's "Face it" (and the gift screen's "Plant it", the same helper) light with their card.
	var omens: Control = main.get_node("HUD/OmenScreen")
	omens._show_offer([] as Array[OmenData], 2)
	await _frames(int(ChoiceArm.ARM_TIME * 60.0) + 10)
	var face: Button = omens._cards.get_child(0).find_child("Action", true, false)
	_check(face != null, "Face an Omen has its drawn action")
	if face != null:
		await _move(face.get_global_rect().get_center())
		_check(await _cue_shows(face, "hover"), "hovering Face an Omen lights Face it")
	RunSaver.safe_quit(self, failures)
