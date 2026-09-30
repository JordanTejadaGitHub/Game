extends SceneTree

# Renders the Moonlit Thread UI (documentation/ui_style.md) to PNGs so the look can be checked
# without playing: the run HUD, the Dream choice, and a component sheet. Needs a window (not
# --headless). Never touches the player's saves (main.tscn isn't the running scene).
#   godot --path . --script res://tools/ui_preview.gd -- --out=C:/tmp/ui

var out_dir := "user://ui_preview"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out_dir)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	root.size = Vector2i(1280, 800)
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _frames(20)
	var dreams: DreamState = main.get_node("%DreamState")
	dreams.unlock_everything = true
	dreams.unlocks_changed.emit()
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var run_state: RunState = main.get_node("%RunState")
	run_state.dew = 40
	var picks := {}
	for card in dreams.pool:
		if not picks.has(card.rarity) and not card.entwined and not card.is_deepened():
			picks[card.rarity] = card
	for rarity in picks:
		dreams.take(picks[rarity])
	var buildable := placer.get_buildable_towers()
	if buildable.size() > 3:
		placer.select_tower(buildable[3])
		main.get_node("HUD")._sync_buttons()
	await _frames(30)
	for path in ["HUD/BossDossier", "HUD/NightmareIntro"]:  # They open themselves at some rests
		var card := main.get_node_or_null(path) as CanvasItem
		if card != null:
			card.visible = false
	for node in get_nodes_in_group(&"boss_dossier"):
		(node as CanvasItem).visible = false
	await _frames(5)
	_save("hud")

	var offer: Array[UpgradeData] = []
	for rarity in [0, 1, 2, 3]:
		if picks.has(rarity):
			offer.append(picks[rarity])
	placer.set_build_mode(false)
	dreams.offer_ready.emit(offer, 5)
	await _frames(10)
	_save("dream")
	main.get_node("HUD/DreamScreen").visible = false
	dreams.dreamlight = 3
	dreams.open_remember()
	await _frames(20)
	_save("remember")
	main.queue_free()
	await _frames(2)

	root.add_child(_sheet())
	await _frames(10)
	_save("components")
	quit()

func _sheet() -> Control:
	var page := ColorRect.new()
	page.color = Color("1c2a24")
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.position = Vector2(40, 40)
	box.add_theme_constant_override("separation", 24)
	page.add_child(box)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	box.add_child(buttons)
	var start := Button.new()
	start.text = "Start drift 8"
	start.custom_minimum_size.y = 48
	UiStyle.primary(start)
	buttons.add_child(start)
	for text in ["Settings", "Locked"]:
		var b := Button.new()
		b.text = text
		b.custom_minimum_size.y = 48
		b.disabled = text == "Locked"
		buttons.add_child(b)
	for text in ["1×", "2×", "Auto"]:
		var b := Button.new()
		b.text = text
		b.toggle_mode = true
		b.button_pressed = text != "2×"
		b.custom_minimum_size = Vector2(52, 40)
		buttons.add_child(b)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 320
	box.add_child(panel)
	var inner := VBoxContainer.new()
	panel.add_child(inner)
	var title := Label.new()
	title.text = "Sporeling"
	UiStyle.title(title)
	inner.add_child(title)
	var caps := Label.new()
	caps.text = "Sporeling family · base"
	UiStyle.caps(caps)
	inner.add_child(caps)
	var body := Label.new()
	body.text = "Throws spores that Poison. 1,240 soothed this run."
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(body)
	inner.add_child(HSeparator.new())
	var number := Label.new()
	number.text = "1,240"
	UiStyle.number(number)
	inner.add_child(number)
	var whisper := Label.new()
	whisper.text = "“Wardens are walls. Make their walk longer.”"
	UiStyle.whisper(whisper)
	box.add_child(whisper)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 18)
	box.add_child(cards)
	for rarity in 4:
		var card := Button.new()
		card.custom_minimum_size = Vector2(200, 120)
		UiStyle.card_button(card, UiStyle.rarity_color(rarity))
		card.text = UpgradeData.rarity_name(rarity)
		cards.add_child(card)
	return page

func _save(name: String) -> void:
	var image := root.get_texture().get_image()
	var path := out_dir.path_join(name + ".png")
	image.save_png(path)
	print("saved ", path)

func _frames(n: int) -> void:
	for i in n:
		await process_frame
