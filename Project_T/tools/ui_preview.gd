extends SceneTree

# Renders the Moonlit Thread UI (documentation/ui_style.md) to PNGs so the look can be checked
# without playing: the run HUD, the Dream choice, and a component sheet. Needs a window (not
# --headless). Never touches the player's saves (main.tscn isn't the running scene).
#   godot --path . --script res://tools/ui_preview.gd -- --out=D:/Projects/logs/ui_preview

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
	main.get_node("HUD/RememberScreen").visible = false
	# A Calling evolution offer and the family pick: they share the family look (owner 2026-10-23), the Dream cards don't
	dreams.set_calling("sporeling")
	var grow := dreams._calling_offer_for(5)
	if not grow.is_empty():
		dreams.offering_calling = true
		dreams.current_offer = grow
		dreams.picks_left = 1
		dreams.offer_ready.emit(grow, 5)
		await _frames(60)  # The cards flip in
		_save("calling")
		main.get_node("HUD/DreamScreen").visible = false
	dreams.unlock_everything = false  # Unlocked everything, the family pick skips itself (Test Grove)
	main.get_node("%DriftDirector").family_pick_requested.emit(&"first")
	await _frames(60)
	_save("family_pick")
	main.queue_free()
	await _frames(2)

	var sheet := _sheet()
	root.add_child(sheet)
	await _frames(10)
	_save("components")
	sheet.queue_free()
	var feedback := _feedback_sheet()
	root.add_child(feedback)
	await _frames(10)
	_save("feedback")
	var strip := feedback.find_child("CueStrip", true, false) as Control
	if strip != null:  # The Calling cues at ×3, nearest: the art council checks their pixels
		var shot := root.get_texture().get_image().get_region(Rect2i(strip.get_global_rect()))
		shot.resize(shot.get_width() * 3, shot.get_height() * 3, Image.INTERPOLATE_NEAREST)
		shot.save_png(out_dir.path_join("feedback_cues_x3.png"))
	quit()

# The section 33 final pass's Calling cues (CallingCues) on fake nightmares and Wardens: Deathcap pips, the lantern and
# streak, the Last Bell tally with Halfway Bell's notch, the throne's growth rings, gold-dispel badges, the halfway bell.
func _calling_cue_strip() -> Control:
	var holder := Control.new()
	holder.name = "CueStrip"
	holder.custom_minimum_size = Vector2(900, 230)
	var cues := CallingCues.new()
	cues.set("_clock", 1.0e9)  # Never looks at the (absent) run: the samples below stay as set
	holder.add_child(cues)
	# [bar centre, Deathcap bursts, lantern level, streak, tally share (-1 none), halfway, caption]
	var foes := [[Vector2(70, 50), 3, 0.0, 0, -1.0, 0, "Deathcap 3 left"], [Vector2(240, 50), 0, 1.0, 3, -1.0, 0, "lantern, streak ×3"],
		[Vector2(410, 50), 0, 0.4, 0, -1.0, 0, "fading lantern"], [Vector2(580, 50), 0, 0.0, 0, 0.5, 1, "Last Bell half, notch waiting"],
		[Vector2(750, 50), 0, 0.0, 0, 1.0, 2, "full, halfway taken"]]
	var wardens: Array = []
	for x in [70, 210, 350, 490, 630, 770]:
		var w := Node2D.new()
		w.position = Vector2(x, 160)
		cues.add_child(w)
		wardens.append(w)
	cues.set("_capped", [wardens[0]])
	cues.set("_thrones", [[wardens[0], 2, 1.0], [wardens[5], 0, 0.6]])
	cues.set("_gold", [[wardens[1], "12", true, false], [wardens[2], "50", false, true], [wardens[3], "23/50", false, false]])
	cues.set("_halfway_bell", wardens[4])
	var over: Node2D = cues.get("_over")
	over.draw.connect(func() -> void:
		for f: Array in foes:
			var c: Vector2 = f[0]
			over.draw_rect(Rect2(c - Vector2(20, 2.5), Vector2(40, 5)), Palette.VOID)
			over.draw_rect(Rect2(c - Vector2(19, 1.5), Vector2(30, 3)), Palette.EMBER)
			CallingCues.draw_deathcap(over, c, f[1])
			if float(f[2]) > 0.0 or int(f[3]) >= 2:
				cues.draw_lantern_cue(over, c, f[2], f[3])
			if float(f[4]) >= 0.0:
				CallingCues.draw_tally(over, c, f[4], f[5]))
	holder.draw.connect(func() -> void:
		var font := UiStyle.body_font()
		for f: Array in foes:
			holder.draw_string(font, f[0] + Vector2(-60, 30), String(f[6]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiStyle.INK_DIM)
		var names := ["throne + cap", "Moth holder", "Pyre lit", "Pyre 23/50", "halfway bell", "throne in 4 drifts"]
		for i in wardens.size():
			var at: Vector2 = (wardens[i] as Node2D).position
			holder.draw_rect(Rect2(at - Vector2(32, 32), Vector2(64, 64)), Color(Palette.MOONLIGHT, 0.12), false, 1.0)
			holder.draw_string(font, at + Vector2(-40, 50), names[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiStyle.INK_DIM))
	return holder

# Section 33's look (owner-approved 2026-10-24): a card's first-fire callout beside a later fire's, an Unfettered number
# beside a plain and a crit one, the {lingering} chip, and "Your Dreams this block" with sample rows.
func _feedback_sheet() -> Control:
	var page := ColorRect.new()
	page.color = Palette.DEEPMOSS  # A map-ish ground under the world cues
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.position = Vector2(40, 40)
	box.add_theme_constant_override("separation", 28)
	page.add_child(box)
	var world := Control.new()  # The callouts and numbers as drawn over the map
	world.custom_minimum_size = Vector2(900, 150)
	world.draw.connect(func() -> void:
		var font := UiStyle.display_font()
		var glyph := UiStyle.dream_glyph_texture(&"spore")
		for pair in [[Vector2(150, 40), null, "Later fire: per drift"], [Vector2(520, 40), glyph, "First fire in the run (held 1.5x)"]]:
			var text := "Mycelium"
			var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
			var x: float = pair[0].x - (width + (22.0 if pair[1] != null else 0.0)) / 2.0
			if pair[1] != null:
				for d: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:  # As CombatCallouts draws a card glyph
					world.draw_texture_rect(pair[1], Rect2(Vector2(x, pair[0].y - 8.0) + d, Vector2(16.0, 16.0)), false, Palette.DREAD)
				world.draw_texture_rect(pair[1], Rect2(x, pair[0].y - 8.0, 16.0, 16.0), false, UiStyle.GOLD)
				x += 22.0
			world.draw_string_outline(font, Vector2(x, pair[0].y + 6.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, 2, Palette.DREAD)
			world.draw_string(font, Vector2(x, pair[0].y + 6.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, UiStyle.GOLD)
			world.draw_string(UiStyle.body_font(), pair[0] + Vector2(-90, 34), String(pair[2]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiStyle.INK_DIM)
		var numbers := [["86", 14, Palette.MOONLIGHT, Palette.DREAD, "a hit"], ["640", 20, Palette.GLOW, Palette.DREAD, "a crit"],
			["1280", DamageLog.UNFETTERED_NUMBER_SIZE, Palette.HEARTLIGHT, Palette.VOID, "Unfettered (2x+ the cap)"]]
		for i in numbers.size():
			var n: Array = numbers[i]
			var at := Vector2(110 + i * 230, 118)
			world.draw_string_outline(UiStyle.number_font(), at, n[0], HORIZONTAL_ALIGNMENT_LEFT, -1, n[1], 2, n[3])  # As FloatingNumber draws it
			world.draw_string(UiStyle.number_font(), at, n[0], HORIZONTAL_ALIGNMENT_LEFT, -1, n[1], n[2])
			world.draw_string(UiStyle.body_font(), at + Vector2(0, 22), String(n[4]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiStyle.INK_DIM))
	box.add_child(world)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 8)
	for kind in [&"makes", &"uses"]:
		chips.add_child(UiStyle.chip(&"lingering", kind, "", UiStyle.CHIP_ICON, 12, UiStyle.GOLD))
	for id in [&"age", &"order"]:
		chips.add_child(UiStyle.chip(id, &"uses", "", UiStyle.CHIP_ICON, 12, UiStyle.GOLD))
	box.add_child(chips)
	box.add_child(_calling_cue_strip())
	var meter := _dreams_meter_sample()
	meter.position = Vector2(560, 420)  # Beside the cue strip: the page is one window tall
	page.add_child(meter)
	return page

# DreamsMeter (Main Merger's b2ff8c99, UI Code's look) open on Last block, from a loose DreamState with sample credit.
func _dreams_meter_sample() -> Control:
	var state := DreamState.new()  # Never in the tree: only its tables are read
	var cards: Array[UpgradeData] = []
	for id in ["mycelium", "morning_dew", "thick_bark", "quick_step"]:
		cards.append(load("res://resource/dream/%s.tres" % id) as UpgradeData)
	state.pool = cards
	state.stacks = {"mycelium": 1, "morning_dew": 1, "thick_bark": 1, "quick_step": 1}
	var credit := {"mycelium": {"damage": 1240.0}, "sp_throne": {"damage": 880.0}, "morning_dew": {"dew": 12.0}}
	state.card_credit = {"block": credit, "last_block": credit, "run": credit}
	state.card_counts_last_block = {"mycelium": 14, "sp_throne": 31}
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(340, 250)
	holder.tree_exited.connect(state.free)
	var meter := DreamsMeter.new(state)
	holder.add_child(meter)
	meter.ready.connect(func() -> void:
		meter.set("_period", &"last_block")
		meter.set_open(true))
	return holder

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
	for text in ["1×", "2×", "Auto-drift"]:
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
	# Keyword chips (owner 2026-10-16; quiet since screens_ui.md 844fa70a): every keyword and status word, Makes over Uses.
	var ids: Array = KeywordIcons.WORDS.keys() + KeywordIcons.STATUSES.keys()
	for kind in [&"makes", &"uses"]:
		var chips := HFlowContainer.new()
		chips.custom_minimum_size.x = 1200
		chips.add_theme_constant_override("h_separation", 6)
		chips.add_theme_constant_override("v_separation", 6)
		var lead := Label.new()
		lead.text = "Makes" if kind == &"makes" else "Uses"
		UiStyle.caps(lead)
		chips.add_child(lead)
		for id in ids:
			chips.add_child(UiStyle.chip(id, kind, "", UiStyle.CHIP_ICON, 12, UiStyle.GOLD))  # The quiet chip every row uses
		box.add_child(chips)
	# The light pass (2026-10-05): primary + key chip, quiet, rows, the segmented speed row, slots.
	var light := HBoxContainer.new()
	light.add_theme_constant_override("separation", 14)
	box.add_child(light)
	var nurture := Button.new()
	nurture.text = "Nurture to rank I  "
	nurture.custom_minimum_size = Vector2(200, 44)
	UiStyle.primary(nurture)
	light.add_child(nurture)
	light.add_child(UiStyle.key_chip("Q"))  # A key chip off a primary (Mist)
	var sell := Button.new()
	sell.text = "Sell +25"
	UiStyle.quiet(sell)
	light.add_child(sell)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 0)
	for name in ["Chime Stone · 180 Dew", "Dreamcatcher · 180 Dew"]:
		var r := Button.new()
		r.text = name
		r.custom_minimum_size.x = 220
		UiStyle.row(r)
		rows.add_child(r)
	light.add_child(rows)
	var speeds := HBoxContainer.new()
	for t in ["Auto-drift on", "II", "1×", "2×", "3×"]:
		var b := Button.new()
		b.text = t
		b.toggle_mode = true
		b.button_pressed = t in ["Auto-drift on", "1×"]
		b.custom_minimum_size = Vector2(46, 40)
		speeds.add_child(b)
	light.add_child(speeds)
	UiStyle.segmented(speeds)
	var slots := HBoxContainer.new()
	for i in 3:
		var s := Button.new()
		s.theme_type_variation = &"WardenSlot"
		s.toggle_mode = true
		s.button_pressed = i == 1
		s.text = str([12, 3, 25][i])
		s.custom_minimum_size = Vector2(56, 70)
		slots.add_child(s)
	light.add_child(slots)
	# Feeling the cards (dream_design.md): the impact lines, a credit line, the toast and a bloom.
	var impact := Label.new()
	impact.text = "On your board · +22% damage on 7 Wardens"
	UiStyle.impact_line(impact)
	box.add_child(impact)
	var none := Label.new()
	none.text = "None of your Wardens yet"
	UiStyle.impact_line(none, false)
	box.add_child(none)
	var credit := RichTextLabel.new()
	credit.bbcode_enabled = true
	credit.fit_content = true
	credit.custom_minimum_size = Vector2(700, 0)
	credit.text = UiStyle.credit_bbcode("Dreams this block", [["Spore Cascade", "+1,840"], ["Cozy Corners", "+920"],
		["Flurry", "+610"]])
	box.add_child(credit)
	var toast := Label.new()
	toast.text = "Cozy Corners · 6 Wardens +30%"
	UiStyle.impact_toast(toast)
	box.add_child(toast)
	var blooms := Control.new()
	blooms.custom_minimum_size = Vector2(500, 90)
	blooms.draw.connect(func() -> void:
		for i in 4:
			UiStyle.draw_bloom(blooms, Vector2(60 + i * 120, 80), [0.1, 0.35, 0.6, 0.85][i], i, &"spore"))
	box.add_child(blooms)
	return page

func _save(name: String) -> void:
	var image := root.get_texture().get_image()
	var path := out_dir.path_join(name + ".png")
	image.save_png(path)
	print("saved ", path)

func _frames(n: int) -> void:
	for i in n:
		await process_frame
