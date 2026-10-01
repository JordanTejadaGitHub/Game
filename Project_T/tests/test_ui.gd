extends SceneTree

# Headless test for the run HUD pieces from screens_ui.md: the drift banner's boss countdown, the
# nightmare info panel, leak feedback, the pause menu summary and Abandon run, the results stats and
# the G (grow) hotkey. Never touches the player's saves (the scene isn't the running game).
#   godot --headless --path . --script res://tests/test_ui.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var director: DriftDirector = main.get_node("%DriftDirector")
	var spawner = main.get_node("%EnemyContainer")
	var run_state: RunState = main.get_node("%RunState")

	# --- Drift banner: next boss countdown ---
	var banner = main.get_node("%DriftBanner")
	var text: String = banner._next_boss_text(0)
	_check(text.ends_with("· drift 25 (in 25)"), "banner names the next boss with its drift and the countdown (%s)" % text)

	# The top-centre stack: the active Omen's line sits under the banner, the Coming strip under it.
	var omen_tag := main.get_node_or_null("HUD/ActiveOmen") as Label
	var strip: ComingStrip = null
	for child in main.get_node("HUD").get_children():
		if child is ComingStrip:
			strip = child
	if omen_tag != null and strip != null:
		omen_tag.text = "Omen: Dry Spell (drifts 11–15) · a reward"
		omen_tag.visible = true
		strip._stack()
		_check(strip.offset_top >= omen_tag.offset_top + omen_tag.size.y, "the Coming strip stacks under the Omen line (%.0f vs %.0f)"
			% [strip.offset_top, omen_tag.offset_top + omen_tag.size.y])
		omen_tag.visible = false
		strip._stack()
	else:
		_check(false, "the Omen line and the Coming strip exist")

	# --- HUD layout (screens_ui.md "The run HUD", principles 5 and 6) ---
	var dreams: DreamState = main.get_node("%DreamState")
	dreams.unlock_everything = true  # Every Warden in the bar, as in Test Grove
	dreams.unlocks_changed.emit()
	var bar: HFlowContainer = main.get_node("%TowerBar")
	var first_button := bar.get_child(0) as Button
	var hotkey_label := first_button.get_node_or_null("Hotkey") as Label
	_check(first_button.text.is_valid_int() and hotkey_label != null and hotkey_label.text == "1",
		"Warden buttons show the cost and the hotkey (%s)" % first_button.text)
	# The Warden's own icon on the button (family emblems were removed, user 2026-09-30).
	var first_data: TowerData = main.get_node("HUD")._bar_towers[0]
	var bar_icon := first_button.icon as AtlasTexture
	_check(first_button.icon != null and (bar_icon == null or bar_icon.atlas == null
		or bar_icon.atlas.resource_path != IconInfo.ICON_SHEET), "Warden buttons show the Warden (%s), not a badge from the icon sheet" % first_data.display_name)
	_check(UiStyle.TIP_SIZE >= 16 and UiStyle.TIP_NAME_SIZE >= 18
		and ThemeDB.get_project_theme().get_font_size("font_size", "TooltipLabel") >= 16, "tooltip text is at least 16 px, names 18")
	# The buff lens (screens_ui.md "Buff readability"): the HUD toggle and V, a toggle (touch too);
	# lens nodes in BuffLens.GROUP hear every change.
	var lens_button := main.get_node_or_null("HUD/BuffLensButton") as Button
	var heard: Array = []
	var lens_script := GDScript.new()
	lens_script.source_code = "extends Node\nvar calls: Array = []\nfunc set_lens(on: bool) -> void:\n\tcalls.append(on)\n"
	lens_script.reload()
	var listener := Node.new()
	listener.set_script(lens_script)
	listener.add_to_group(BuffLens.GROUP)
	main.add_child(listener)
	_check(lens_button != null and lens_button.toggle_mode and not BuffLens.on and InputMap.has_action("buff_lens"),
		"the Buffs toggle is there, off at the start, with its V action")
	var v := InputEventAction.new()
	v.action = "buff_lens"
	v.pressed = true
	main.get_node("HUD")._unhandled_input(v)
	_check(BuffLens.on and lens_button.button_pressed and listener.get("calls") == [true], "V turns the lens on (and tells the lens)")
	main.get_node("HUD")._unhandled_input(v)
	_check(not BuffLens.on and listener.get("calls") == [true, false], "and off again")
	listener.queue_free()
	# Selected vs hovered: no button rests filled; the primary look at rest is only its gold border.
	var theme := ThemeDB.get_project_theme()
	var plain_rest := theme.get_stylebox("normal", "Button") as StyleBoxFlat
	var primary_rest := theme.get_stylebox("normal", "PrimaryButton") as StyleBoxFlat
	var primary_hover := theme.get_stylebox("hover", "PrimaryButton") as StyleBoxFlat
	var focus := theme.get_stylebox("focus", "Button") as StyleBoxFlat
	_check(primary_rest.bg_color == plain_rest.bg_color and primary_rest.shadow_size == 0
		and primary_hover.bg_color != primary_rest.bg_color and not focus.draw_center,
		"primary buttons rest unfilled (gold border only); hover fills; focus is an outline")
	# Seedling Gift: a seed badge with the count on the Sprout button, hidden at 0.
	var hud_node = main.get_node("HUD")
	_check(hud_node._seed_badge != null and not hud_node._seed_badge.visible, "no seed badge without free Sprouts")
	run_state.add_sprout_charges(2)
	_check(hud_node._seed_badge.visible, "free Sprouts show a seed badge on the Sprout button")
	run_state.add_sprout_charges(-2)
	for screen in [Vector2i(1920, 1080), Vector2i(1280, 800), Vector2i(1280, 720)]:
		root.size = screen
		await _frames(2)
		# The Clear tool + the Warden bar, centred together at the bottom.
		var tool_rect := (main.get_node("HUD/ClearTool") as Control).get_global_rect()
		var bar_rect := bar.get_global_rect().merge(tool_rect)
		for arrow_name in ["BarArrowLeft", "BarArrowRight"]:  # A scrolling bar centres with its arrows
			var arrow := main.get_node("HUD").get_node_or_null(arrow_name) as Control
			if arrow != null and arrow.visible:
				bar_rect = bar_rect.merge(arrow.get_global_rect())
		_check(bar_rect.end.y > screen.y - 100 and absf(bar_rect.get_center().x - screen.x / 2.0) < 2.0
			and tool_rect.end.x < bar.get_global_rect().position.x,
			"the Clear tool and Warden bar sit at the bottom centre at %s (%s)" % [screen, bar_rect])
		# The Clear slot is a Warden slot's size and shape, on the same baseline (user: not a different size).
		var visible_slots := bar.get_children().filter(func(b: Node) -> bool: return b is Control and b.visible)
		var slot_rect := (visible_slots[-1] as Control).get_global_rect()  # A shown slot (the bar may scroll)
		_check(tool_rect.size.is_equal_approx(slot_rect.size) and absf(tool_rect.end.y - slot_rect.end.y) < 1.0
			and (main.get_node("HUD/ClearTool").get_node_or_null("Hotkey") as Label) != null,
			"the Clear slot matches a Warden slot at %s (%s vs %s)" % [screen, tool_rect, slot_rect])
		for name in ["WardenPanel", "DriftPanel", "DriftBanner"]:
			var other := (main.get_node("HUD/" + name) as Control).get_global_rect()
			_check(not bar_rect.intersects(other), "the Warden bar doesn't overlap %s at %s (%s vs %s)" % [name, screen, bar_rect, other])
		# A minimised choice's "Back to …" button never covers the banner, the Coming strip or the bar.
		var peek_screen := Control.new()
		peek_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
		main.get_node("HUD").add_child(peek_screen)
		var peek := ChoicePeek.new(peek_screen, [], "Back to the Dream")
		peek.set_peeking(true)
		await process_frame
		var back_rect := (peek_screen.get_children().filter(func(c: Node) -> bool: return c is Button)[0] as Button).get_global_rect()
		var strip_rect := Rect2()
		for child in main.get_node("HUD").get_children():
			if child is ComingStrip:
				strip_rect = (child as Control).get_global_rect()
		_check(not back_rect.intersects(bar_rect) and not back_rect.intersects((main.get_node("HUD/DriftBanner") as Control).get_global_rect())
			and not back_rect.intersects(strip_rect) and back_rect.end.y <= screen.y,
			"the peek's Back button clears the bar, banner and Coming strip at %s (%s; bar %s, strip %s)" % [screen, back_rect, bar_rect, strip_rect])
		peek_screen.queue_free()
		# The top-right row (screens_ui.md "Top-right layout, as in the Moonlit Thread mock-up"): leaves ·
		# Dew · Dreamlight · path, then Remember · Boosts · ? · Menu, on one fog patch clear of the
		# banner's text (the buttons wrap onto a second line inside the patch when it's too narrow).
		var top_names := ["RememberButton", "BuffLensButton", "CodexButton", "MenuButton"]
		var was_shown := {}
		for n in top_names:
			var b := main.get_node("HUD/" + n) as Control
			was_shown[n] = b.visible
			b.visible = true
		var row_hud = main.get_node("HUD")
		row_hud._layout_top_row()
		await _frames(2)
		var row_rect: Rect2 = row_hud.resource_row_rect()
		var banner_rect: Rect2 = main.get_node("%DriftBanner").drawn_rect()
		var parts: Array = top_names.map(func(n: String) -> Rect2: return (main.get_node("HUD/" + n) as Control).get_global_rect())
		for n in ["%LeavesLabel", "%DewLabel", "HUD/DreamlightLabel", "%PathLabel"]:
			parts.append((main.get_node(n) as Control).get_global_rect())
		var inside := parts.all(func(r: Rect2) -> bool: return row_rect.grow(1.0).encloses(r))
		var ordered: bool = parts[0].end.x <= parts[1].position.x + 0.5 and parts[1].end.x <= parts[2].position.x + 0.5 \
			and parts[2].end.x <= parts[3].position.x + 0.5 and parts[4].end.x <= parts[5].position.x + 0.5 \
			and parts[5].end.x <= parts[6].position.x + 0.5 and parts[6].end.x <= parts[7].position.x + 0.5
		_check(inside and ordered and not row_rect.intersects(banner_rect) and absf(parts[3].end.x - (screen.x - 16.0)) < 1.0
			and parts.slice(0, 4).all(func(r: Rect2) -> bool: return r.size.y >= 48.0),
			"the top-right row: counters and buttons in order on one fog patch, clear of the banner at %s (row %s, banner %s, wrapped %s)" % [screen, row_rect, banner_rect, row_hud.row_wrapped])
		for n in top_names:
			(main.get_node("HUD/" + n) as Control).visible = was_shown[n]
		# The expanded damage meter (both tabs, the top rows + "and N more") never covers the DriftPanel
		# (user: "maze dps shouldn't go over the call drift").
		var meter := main.get_node("HUD/DriftMeter") as DriftMeter
		var meter_was := meter.visible
		meter.set_process(false)  # Its refresh would hide it (no Warden meter in this test)
		meter.visible = true
		var fake_rows: Array[Button] = []
		for i in 6:
			var row := Button.new()
			row.text = "Sporeling %d" % i
			row.custom_minimum_size = Vector2(0, 40)
			meter._rows.add_child(row)
			fake_rows.append(row)
		meter._more.visible = true
		meter._more.text = "and 16 more"
		for summary in [false, true]:
			meter.block_summary = summary
			for f in 4:
				meter._fit()
				while meter._rows.get_child_count() > meter._max_rows:  # What refresh does with the cap
					var extra := meter._rows.get_child(meter._rows.get_child_count() - 1)
					meter._rows.remove_child(extra)
					extra.queue_free()
				await process_frame
			var meter_rect := meter.get_global_rect()
			var panel_rect := (main.get_node("HUD/DriftPanel") as Control).get_global_rect()
			_check(not meter_rect.intersects(panel_rect) and meter_rect.position.y >= DriftMeter.TOP_LIMIT - 1.0,
				"the damage meter (%s tab) clears the DriftPanel at %s (%s vs %s)" % ["block" if summary else "Wardens", screen, meter_rect, panel_rect])
		for row in fake_rows.filter(func(r) -> bool: return is_instance_valid(r)):
			row.queue_free()
		meter._more.visible = false
		meter.block_summary = false
		meter.visible = meter_was
		meter.set_process(true)
	# The Warden bar is always one row (user: "the tower bar should not stack like this"), even with every
	# family: slots shrink to 56 px, then the bar scrolls with arrows.
	var bar_dreams: DreamState = main.get_node("%DreamState")
	var was_everything := bar_dreams.unlock_everything
	bar_dreams.unlock_everything = true
	bar_dreams.unlocks_changed.emit()
	for screen in [Vector2i(1280, 800), Vector2i(1920, 1080)]:
		root.size = screen
		await _frames(3)
		var shown_slots: Array = bar.get_children().filter(func(b: Node) -> bool: return b is Button and b.visible)
		var tool_y := (main.get_node("HUD/ClearTool") as Control).get_global_rect().position.y
		var one_row := not shown_slots.is_empty() and shown_slots.all(func(b: Button) -> bool:
			return absf(b.get_global_rect().position.y - tool_y) < 1.0 and b.get_global_rect().size.x >= 55.0)
		var all_slots := bar.get_children().filter(func(b: Node) -> bool: return b is Button).size()
		var arrows := main.get_node("HUD").get_node_or_null("BarArrowRight") as Control
		_check(one_row and (shown_slots.size() == all_slots or (arrows != null and arrows.visible)),
			"the Warden bar stays one row with %d Wardens at %s (%d shown, arrows %s)" % [all_slots, screen, shown_slots.size(), arrows != null and arrows.visible])
	bar_dreams.unlock_everything = was_everything
	bar_dreams.unlocks_changed.emit()
	await _frames(2)
	_check(banner.get_drift_text() == "Ready · Drift 1", "before the first drift the banner reads Ready · Drift 1")
	# The camera can scroll past the map's far corner, so the Heartwood can clear the drift controls.
	var camera = main.get_node("GameCameraNode")
	camera.target_position = Vector2(1e6, 1e6)
	camera._clamp_camera_to_map()
	var half_view: Vector2 = camera.camera_2d.get_viewport_rect().size / camera.camera_2d.zoom / 2.0
	_check(camera.target_position.x > camera.map_size_pixels.x - half_view.x + 1.0
		and camera.target_position.y > camera.map_size_pixels.y - half_view.y + 1.0,
		"the camera can go past the map's edges by the HUD's size")
	dreams.unlock_everything = false
	dreams.unlocks_changed.emit()

	# --- Dreams row: an icon per Dream, with Few and Mighty's live bonus following the Wardens ---
	var row = main.get_node("%DreamsRow")
	var few: UpgradeData = null
	for card in dreams.pool:
		if card.id == "few_and_mighty":
			few = card
	_check(few != null, "Few and Mighty is in the pool")
	if few != null:
		var before_count: int = row._icons.size()
		dreams.take(few)
		await process_frame
		_check(row._icons.size() == before_count + 1 and row._icons[-1].card == few, "taking a Dream adds its icon")
		var live_before: String = row._icons[-1].live
		_check(live_before == dreams.get_live_bonus_text(few) and live_before.begins_with("+"), "the icon shows the live bonus (%s)" % live_before)
		var row_placer: TowerPlacer = main.get_node("%TowerPlacer")
		main.get_node("%RunState").dew = 500
		row_placer.tower_data = load("res://resource/tower/sprout.tres")
		row_placer._try_build(_free_cell(main.get_node("%MapGenerator")))
		row.refresh()
		_check(row._icons[-1].live != live_before, "planting a Warden updates it (%s → %s)" % [live_before, row._icons[-1].live])
		_check(row.get_list_text().contains("Few and Mighty"), "Dreams this run lists it")
		# The redesigned list: grouped rows, status tokens filled in, a tap shows the full card.
		var soft := dreams.pool.filter(func(c: UpgradeData) -> bool: return c.description.contains("{spored}"))
		if not soft.is_empty():
			dreams.choose(soft[0]) if dreams.is_offering() else dreams.stacks.set(soft[0].id, 1)
			row.refresh()
		row._toggle_list()
		_check(row._list.visible and row._list_box.get_child_count() > 1, "Dreams this run opens as rows")
		_check(not row.get_list_text().contains("{"), "no raw status tokens in the list")
		var row_frame: Control = row._list_box.find_child("Row_few_and_mighty", false, false)
		_check(row_frame != null, "Few and Mighty has its own row")
		_check(DreamsRow.group_of(load("res://resource/dream/heart_of_the_maze.tres")) != "", "every card has a group")
		row._toggle_list()

	# --- Dreamlight: the counter beside the Dew, and Remember at rests ---
	var light: Label = main.get_node("HUD/DreamlightLabel")
	dreams.add_dreamlight(2)
	_check(light.text == str(dreams.dreamlight), "the Dreamlight counter follows DreamState (%s)" % light.text)
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	light.gui_input.emit(tap)
	var light_tip: TapTip = main.get_node("HUD").dreamlight_tip
	_check(light_tip.visible and light_tip._label.text.begins_with("Dreamlight") and light_tip._label.text.contains("(%d)" % dreams.dreamlight),
		"tapping the counter explains it at the counter (no hover-only info)")
	# Tips are opaque and on their own top layer, by the pointer (screens_ui.md "tips are opaque").
	_check(light_tip.get_parent() is CanvasLayer and (light_tip.get_parent() as CanvasLayer).layer == UiStyle.TIP_LAYER,
		"the tip draws on the top tip layer")
	var above_right := UiStyle.tip_position(Vector2(400, 400), Vector2(200, 60), Vector2(1280, 800))
	var flipped := UiStyle.tip_position(Vector2(1250, 20), Vector2(200, 60), Vector2(1280, 800))
	_check(above_right == Vector2(416, 328) and flipped.x + 200.0 <= 1250.0 and flipped.y >= 20.0,
		"tips sit above-right of the pointer and flip at the edges (%s, %s)" % [above_right, flipped])
	light_tip.visible = false
	# Resources explain themselves on hover and tap (IconInfo, TapTip).
	var dew_label: Label = main.get_node("%DewLabel")
	_check(dew_label.tooltip_text == IconInfo.resource_tooltip(&"dew") and dew_label.tooltip_text.begins_with("Dew: "), "Dew has a plain-words tooltip")
	var dew_tip: TapTip = dew_label.get_children().filter(func(c: Node) -> bool: return c is TapTip)[0]
	dew_label.gui_input.emit(tap)
	_check(dew_tip.visible and dew_tip._label.text == dew_label.tooltip_text, "tapping Dew shows the same text")
	dew_tip.toggle()
	_check(IconInfo.status_tooltip(&"damp").begins_with("Soaked: Water hits deal 20% more"), "status tooltips in plain words")
	# Dream bonuses on Wardens (DreamBonusView): breakdown text, and rows styled active / off.
	_check(DreamBonusView.format_breakdown(&"damage", {"base": 18.0, "final": 27.0,
		"parts": [["Nurture II", "+20%"], ["Solitude", "+30%"]]}) == "Damage 18 → 27: base 18 · Nurture II +20% · Solitude +30%",
		"a stat breakdown reads base → final with each part")
	_check(DreamBonusView.format_breakdown(&"range", {"base": 2.5, "final": 2.5, "parts": []}) == "Range 2.5", "an unchanged stat is just its value")
	var some_card: UpgradeData = main.get_node("%DreamState").pool[0]
	_check(DreamBonusView.get_line({"card": some_card, "active": false, "reason": "Rain Lily is 1 cell away"}) == "off: Rain Lily is 1 cell away"
		and DreamBonusView.get_line({"card": some_card, "active": true, "effect": "+30% damage"}) == "+30% damage", "row lines: the effect, or why it's off")
	_check(DreamBonusView.chip_text({"card": some_card, "active": true, "effect": "+30% damage"}) == some_card.display_name + " ✓ +30% damage"
		and DreamBonusView.chip_text({"card": some_card, "active": false, "reason": "Rain Lily is 1 cell away"}).ends_with("✗ Rain Lily is 1 cell away"),
		"ghost chips: ✓ with the effect, ✗ with the reason")
	_check(DreamBonusView.is_positional({"conditional": true}) and not DreamBonusView.is_positional({"conditional": true, "run_wide": true}),
		"positional chips are the conditional, non-run-wide ones")
	# With Roguelite's API: a planted Warden's breakdown ends on its real value (what combat uses).
	var bonus_placer: TowerPlacer = main.get_node("%TowerPlacer")
	main.get_node("%RunState").dew = 500
	bonus_placer.tower_data = load("res://resource/tower/sprout.tres")
	var bonus_cell := _free_cell(main.get_node("%MapGenerator"))
	if bonus_placer._try_build(bonus_cell):
		var planted: Tower = main.get_node("%TowerSeller").get_tower_at(bonus_cell)
		var parts := DreamBonusView.get_stat_parts(planted.tower_data, planted.cell, &"damage", planted)
		_check(not parts.is_empty() and is_equal_approx(parts.final, planted.get_damage())
			and is_equal_approx(parts.base, planted.tower_data.damage), "the damage breakdown runs from base to the real value (%s)" % [parts])
		_check(DreamBonusView.make_rows(planted) is Control, "rows build for a planted Warden")
		main.get_node("%TowerSeller").sell(bonus_cell)
	var off_row := DreamBonusView._row({"card": some_card, "active": false, "reason": "not alone"})
	_check(off_row.get_child(0).modulate.a < 1.0, "an off card is greyed")
	off_row.free()
	# Status display names (story.md): ids unchanged, names from IconInfo; {tokens} fill them in.
	_check(IconInfo.status_name(&"damp") == "Soaked" and IconInfo.status_name(&"static") == "Charged"
		and IconInfo.status_name(&"held") == "Rooted" and IconInfo.format("{spored} + {marked}") == "Poisoned + Exposed",
		"the new status names")
	# Every status word is a link: underlined, with a popup (icon, definition, More in the Codex).
	var linked := StatusLinks.bbcode("Soaked nightmares, {static} bolts, and a soaking rain.")
	_check(linked.contains("[url=status:damp]") and linked.contains("[url=status:static]") and not linked.contains("soaking[/url]"),
		"status names (and tokens) become links, whole words only (%s)" % linked)
	var link_label := StatusLinks.make_label("Applies Soaked.")
	main.get_node("HUD").add_child(link_label)
	await process_frame
	link_label.meta_clicked.emit("status:damp")
	var popup: StatusLinks = link_label.get_meta(&"status_popup")
	_check(popup.visible and popup._name.text == "Soaked" and popup._text.text.begins_with("Water hits deal 20% more"), "tapping a status shows its definition")
	link_label.meta_clicked.emit("status:damp")
	_check(not popup.visible, "tapping it again closes it")
	# Combo links (user: "hovering over combos doesn't do anything"): {combo:id} is a link; hovering shows
	# its tip (name, statuses, what it does, times set off), "???" until discovered.
	var combo_label := StatusLinks.make_label("Pairs with {combo:thunderclap}.")
	main.get_node("HUD").add_child(combo_label)
	await process_frame
	var combo_found := CodexData.is_discovered(&"thunderclap")
	_check(combo_label.text.contains("[url=combo:thunderclap]") and combo_label.text.contains("Thunderclap" if combo_found else "???"),
		"a combo token becomes a link (its name, or ??? until found)")
	combo_label.meta_hover_started.emit("combo:thunderclap")
	var combo_popup: StatusLinks = combo_label.get_meta(&"status_popup")
	_check(combo_popup.visible and combo_popup._name.text == ("Thunderclap" if combo_found else "???") and combo_popup._text.text != "",
		"hovering a combo link shows its tip (%s: %s)" % [combo_popup._name.text, combo_popup._text.text])
	combo_popup.visible = false
	combo_label.queue_free()
	# Game terms (playtest fixes 2026-09-30): {block}-style tokens are links to their glossary line.
	var term_text := StatusLinks.bbcode("{Perfect_block}: no leaf lost in a {block} of {drifts}. Soaked {deeply_blighted}.")
	_check(term_text.contains("[url=term:perfect_block]") and term_text.contains("Perfect block[/color]")
		and term_text.contains("[url=term:block]") and term_text.contains("drifts[/color]")
		and term_text.contains("[url=status:damp]") and term_text.contains("[url=term:deeply_blighted]"),
		"term tokens become links, capitalised and plural forms too (%s)" % term_text)
	_check(IconInfo.format("each {block}, {Rests}, {dreamlight}") == "each block, Rests, Dreamlight", "plain text gets the words")
	for id in IconInfo.TERMS:
		_check(CodexData.definition(StatusLinks.term_name(id)) != "", "the glossary defines %s" % StatusLinks.term_name(id))
	# Family names as links ({family:dewdrop}): the popup shows its emblem, damage type and identity.
	var family_text := StatusLinks.bbcode("Needs {family:dewdrop}.")
	_check(family_text.contains("[url=family:dewdrop]") and family_text.contains("Dewdrop[/color]")
		and IconInfo.format("Needs {family:dewdrop}.") == "Needs Dewdrop.", "family tokens become links / plain names (%s)" % family_text)
	link_label.meta_clicked.emit("family:dewdrop")
	_check(popup.visible and popup._name.text == "Dewdrop family" and popup._text.text.begins_with("Water damage.") and popup._icon.visible,
		"tapping a family shows its emblem, damage type and identity (%s)" % popup._text.text)
	link_label.meta_clicked.emit("term:perfect_block")
	_check(popup.visible and popup._name.text == "Perfect block" and popup._text.text.contains("no leaf lost") and not popup._icon.visible,
		"tapping a term shows its glossary line (%s)" % popup._text.text)
	link_label.queue_free()
	var whisper_node = main.get_node("%Whispers")
	whisper_node.enabled = true
	whisper_node._seen = []
	whisper_node._queue.clear()
	whisper_node.whisper(&"damp")
	_check(whisper_node.text.contains("[url=status:damp]Soaked") or whisper_node.text.contains("status:damp"), "whispers link their status words (%s)" % whisper_node.text)
	whisper_node.set_enabled(false)
	# The icon sheet (assets/ui/icons.png + icons.json): every status and stat id has a 16×16 icon.
	for id in [&"damp", &"static", &"elite", &"hidden", &"damage", &"potency", &"focus_deep", &"dreamlight_cost"]:
		var art := IconInfo.icon(id) as AtlasTexture
		_check(art != null and art.region.size == Vector2(16, 16), "icon for %s" % id)
	_check(IconInfo.status_tooltip(&"deeply_blighted") == IconInfo.status_tooltip(&"elite"), "sheet ids find their tooltips")
	var made := IconInfo.make_icon(&"range", 2)
	_check(made.custom_minimum_size == Vector2(32, 32) and made.tooltip_text.begins_with("Range:"), "make_icon: ×2, with its tooltip")
	made.free()
	var drift_panel = main.get_node("HUD/DriftPanel")
	# Remember: a top-right button beside the Dreamlight counter (run_design.md), glowing when
	# something can be unlocked; the DriftPanel's old button stays hidden.
	var hud_rem = main.get_node("HUD")
	_check(main.get_node_or_null("HUD/RememberButton") != null, "a Remember button at the top right")
	drift_panel._process(0.0)
	_check(not drift_panel._remember_button.visible, "the rest panel's old Remember button is gone")
	var saved_light := dreams.dreamlight
	var had_sporeling := dreams.unlocked.has("sporeling")
	dreams.unlocked["sporeling"] = true
	dreams.add_dreamlight(-dreams.dreamlight)
	_check(not hud_rem.can_remember_something(), "no glow without Dreamlight")
	dreams.add_dreamlight(5)
	_check(hud_rem.can_remember_something(), "it glows when a branch can be unlocked")
	var asked := []
	dreams.remember_requested.connect(func(_focus) -> void: asked.append(true), CONNECT_ONE_SHOT)
	hud_rem.remember_button.pressed.emit()
	_check(asked.size() == 1, "the button opens the Remember screen")
	var remember_screen = main.get_node_or_null("HUD/RememberScreen")
	if remember_screen != null and remember_screen.visible:
		remember_screen.close()
	dreams.add_dreamlight(saved_light - dreams.dreamlight)
	if not had_sporeling:
		dreams.unlocked.erase("sporeling")
	main.get_node("%GameSpeed").set_paused(false)  # The screen paused mid-drift; the test leaves it open

	# --- Whispers: a locked obstacle says "Dead wood…", Tend waits for the first clearing Dream ---
	var whispers = main.get_node("%Whispers")
	var clearer: ObstacleClearer = main.get_node("%ObstacleClearer")
	whispers.set_process(false)  # Driven by hand below
	whispers.enabled = true
	whispers._seen = []
	clearer.set_process(false)  # Its hover follows the mouse each frame
	clearer._hover_obstacle = load("res://resource/obstacle/tree.tres")
	whispers._process(0.0)
	_check(whispers._queue.has(&"dead_wood") and not whispers._queue.has(&"tend"), "a locked obstacle whispers Dead wood, not Tend")
	dreams.clearing_open = true
	clearer.lock_changed.emit(false)
	_check(whispers._queue.has(&"tend"), "Tend comes once clearing opens")

	# --- The Clear tool: locked until clearing opens, then a toggle for ObstacleClearer's tool mode ---
	var tool: ClearToolButton = main.get_node("HUD/ClearTool")
	tool._update_icon()
	_check(tool._frame == ClearToolButton.FRAME_AVAILABLE, "the icon shows the tool available once clearing opens")
	tool.toggle_tool()
	tool._update_icon()
	_check(clearer.is_tool_active() and tool.button_pressed and tool._frame == ClearToolButton.FRAME_ACTIVE,
		"the Clear tool turns the clear mode on (active icon)")
	tool.toggle_tool()
	_check(not clearer.is_tool_active() and not tool.button_pressed, "and off again")
	dreams.clearing_open = false
	tool.toggle_tool()
	_check(not clearer.is_tool_active() and (main.get_node("%ToastLabel") as Label).text == ClearToolButton.LOCKED_TEXT,
		"while locked it explains why instead")
	_check(InputMap.has_action("clear_tool"), "0 / C pick the Clear tool")
	clearer._hover_obstacle = null
	clearer.set_process(true)
	whispers.set_enabled(false)

	# --- Nightmare info on hover ---
	var info = main.get_node("%NightmareInfo")
	var shade: Node2D = spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	shade.set_process(false)
	info._target = shade
	info._known.clear()  # As if never met before
	await process_frame
	_check(info.visible and info._title.text.begins_with(shade.enemy_data.display_name), "hover panel shows the nightmare")
	_check(info._title.text.contains("New"), "a never-met nightmare gets the New tag")
	_check(info._body.text.contains(shade.enemy_data.trait_text) and info._numbers.text.contains("Health"),
		"hover panel shows the trait and health")

	# --- Leak feedback ---
	var leak = main.get_node("LeakEffect")
	var map_generator = main.get_node("%MapGenerator")
	shade.set_process(true)
	shade.position = shade.grid.calculate_map_position(map_generator.endPath) + Vector2(0, -8)
	shade.set_path(PackedVector2Array([map_generator.endPath]))
	await _frames(10)
	_check(not leak._pulses.is_empty() and run_state.leaves_lost == 1, "a leak pulses at the Heartwood and counts a lost leaf")

	# --- G grows the selected Warden ---
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	run_state.dew = 500
	placer.tower_data = load("res://resource/tower/sprout.tres")
	var cell := _free_cell(map_generator)
	placer._try_build(cell)
	seller.select(seller.get_tower_at(cell))
	_check(not seller.grow_selected(), "G does nothing without an unlocked form")
	dreams.unlocked["sporeling"] = true
	_check(seller.grow_selected() and seller.get_tower_at(cell).tower_data.get_id() == "sporeling", "G grows the Sprout")

	# --- Family pick: statuses, branch previews, and Peek (screens_ui.md "Choice screens") ---
	var family = main.get_node("%FamilyPickScreen")
	var sporeling: TowerData = load("res://resource/tower/sporeling.tres")
	_check(family.get_status_text(sporeling) == "Applies Poisoned", "the family card names its status (%s)" % family.get_status_text(sporeling))
	_check(family.get_branches(sporeling).size() == 2, "the family card previews two branches")
	family.show_pick(&"first")
	await _frames(3)
	# Each card holds all of its content (the "Grows into" rows used to spill out of the bottom).
	for card in family._cards.get_children():
		var content: Control = card.get_child(0)
		_check(card.size.y >= content.get_combined_minimum_size().y + family.CARD_PADDING - 1.0,
			"a family card fits its content (%.0f for %.0f)" % [card.size.y, content.get_combined_minimum_size().y])
	family.peek.set_peeking(true)
	_check(family.visible and family.mouse_filter == Control.MOUSE_FILTER_IGNORE and paused, "Peek shows the map, time still stopped")
	family.peek.set_peeking(false)
	_check(family.mouse_filter == Control.MOUSE_FILTER_STOP, "and Back reopens the pick")
	family.choose(family.offer[0])

	# The Memory Warden card (screens_ui.md): after its boss, its own card, as tall as the others at most.
	var stag: TowerData = load("res://resource/tower/white_stag.tres")
	family.pending_memory_warden = stag
	family.show_pick(&"boss")
	await _frames(3)
	var memory_card: Control = family._cards.get_child(0)
	var memory_box: Control = memory_card.get_child(0)
	_check(family.offer[0] == stag and (memory_box.get_child(0) as Label).text == "A Memory returns",
		"the pick after the boss shows the Memory Warden on its own card")
	var tallest: float = family.CARD_SIZE.y
	for i in range(1, family._cards.get_child_count()):
		tallest = maxf(tallest, family._cards.get_child(i).size.y)
	_check(memory_card.size.y >= memory_box.get_combined_minimum_size().y + family.CARD_PADDING - 1.0
		and memory_card.size.y <= tallest + 1.0,
		"the Memory Warden card fits its content and no taller than the other cards (%.0f, tallest %.0f)" % [memory_card.size.y, tallest])
	family.choose(stag)
	_check(dreams.is_unlocked("white_stag"), "choosing the Memory Warden plants it in the run")

	# Dream card marks (DreamMarks): Thick Bark's shield by the leaves, Heart of the Maze's heart layer.
	var marks_hud = main.get_node("HUD")
	marks_hud.bark_shield.set_charges(2)
	_check(marks_hud.bark_shield.visible and marks_hud.bark_shield.charges == 2, "Thick Bark: the shield shows while leaks can be saved")
	_check(marks_hud.bark_shield._intro > 0.0, "…and pulses with its name the first time")
	var bark_card = marks_hud.bark_shield.card()
	if bark_card != null:
		marks_hud.bark_shield.tip.show_card(marks_hud.bark_shield, bark_card, Vector2(200, 200))
		_check(marks_hud.bark_shield.tip.visible and marks_hud.bark_shield.tip._name.text == bark_card.display_name
			and marks_hud.bark_shield.tip._text.text == IconInfo.format(bark_card.description), "hover / tap: the card's icon, name and text")
		marks_hud.bark_shield.tip.hide_tip(marks_hud.bark_shield)
	marks_hud.bark_shield.set_charges(0)
	_check(not marks_hud.bark_shield.visible, "…and hides at 0")
	_check(main.get_children().any(func(c: Node) -> bool: return c is DreamMarks), "the Heart of the Maze mark layer exists")
	# Touch drag to build (TouchBuild): Plant / Cancel while a stroke waits; two fingers pan, never plant.
	var touch: TouchBuild = main.get_node("HUD").get_children().filter(func(c: Node) -> bool: return c is TouchBuild).front()
	var touch_placer: TowerPlacer = main.get_node("%TowerPlacer")
	main.get_node("%RunState").dew = 500
	touch.set_touch_mode(true)
	_check(not touch_placer.confirm_on_release, "touch: strokes wait for Plant")
	touch_placer.select_tower(load("res://resource/tower/thornwall.tres"))
	var touch_cell := _free_cell(main.get_node("%MapGenerator"))
	touch_placer.begin_stroke(touch_cell)
	touch._refresh()
	_check(touch.visible and touch._plant.text.begins_with("Plant"), "the Plant button shows for a pending stroke (" + touch._plant.text + ")")
	var planted_before: int = main.get_node("%TowerContainer").get_child_count()
	touch._on_plant()
	_check(not touch_placer.stroking and not touch.visible and main.get_node("%TowerContainer").get_child_count() > planted_before,
		"Plant plants the stroke")
	touch_placer.begin_stroke(_free_cell(main.get_node("%MapGenerator")))
	var touch_camera = main.get_node("GameCameraNode")
	var open_dossier := main.get_tree().get_first_node_in_group(BossDossier.GROUP) as BossDossier
	if open_dossier != null and open_dossier.visible:
		open_dossier.close_dossier()  # It opens by itself at the first rest; a modal screen stops map pans
	var cam_before: Vector2 = touch_camera.target_position
	for i in 2:
		var press := InputEventScreenTouch.new()
		press.index = i
		press.pressed = true
		press.position = Vector2(400 + 100 * i, 400)
		touch._input(press)
	_check(not touch_placer.stroking, "a second finger drops the stroke (a pan never plants)")
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(440, 400)
	drag.relative = Vector2(40, 0)
	touch._input(drag)
	_check(touch_camera.target_position != cam_before, "two fingers pan the map")
	for i in 2:
		var lift := InputEventScreenTouch.new()
		lift.index = i
		lift.pressed = false
		touch._input(lift)
	touch.set_touch_mode(false)
	_check(touch_placer.confirm_on_release, "a mouse plants on release again")
	touch_placer.set_build_mode(false)
	# Full-screen overlays draw above the strip and the top-right buttons; the pause menu tops them all.
	var order_hud := main.get_node("HUD")
	var idx := func(n: String) -> int: return order_hud.get_node(n).get_index()
	_check(idx.call("RememberScreen") > idx.call("RememberButton") and idx.call("DreamScreen") > idx.call("MenuButton")
		and idx.call("PauseMenu") == order_hud.get_child_count() - 1, "overlays draw above the HUD, the pause menu on top")
	var strip_node: Node = order_hud.get_children().filter(func(c: Node) -> bool: return c is ComingStrip).front()
	_check(strip_node.get_index() < idx.call("OmenScreen"), "the Coming strip stays under the Omen screen")
	# UI scrolling never moves the map: a wheel over the open Codex leaves the zoom alone; over the
	# map it zooms (screens_ui.md). WASD waits while a text field has focus.
	var wheel_cam = main.get_node("GameCameraNode")
	var wheel_pause = main.get_node("%PauseMenu")
	wheel_pause.open_codex(&"glossary")
	await process_frame
	var zoom_before: Vector2 = wheel_cam.target_zoom
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	wheel.position = wheel_pause.codex.get_global_rect().get_center()
	wheel.global_position = wheel.position
	root.push_input(wheel)
	var wheel_up := wheel.duplicate()
	wheel_up.pressed = false
	root.push_input(wheel_up)
	await process_frame
	_check(wheel_cam.target_zoom == zoom_before, "a wheel over the Codex doesn't zoom the map")
	wheel_pause.close()
	await process_frame
	wheel_cam.target_zoom = Vector2.ONE * 0.8
	wheel_cam._unhandled_input(wheel)
	_check(wheel_cam.target_zoom.x > 0.8, "a wheel over the map zooms")
	# Zoom (user: "allow zooming in more"): up to 2.5×, each notch ×1.1 (even at both ends), and world
	# text keeps its screen size when zoomed in.
	wheel_cam.target_zoom = Vector2.ONE
	wheel_cam.zoom_by_step(1.0)
	_check(is_equal_approx(wheel_cam.target_zoom.x, wheel_cam.zoom_step), "a notch multiplies the zoom by %.2f" % wheel_cam.zoom_step)
	wheel_cam.target_zoom = Vector2.ONE * 2.4
	wheel_cam.zoom_by_step(1.0)
	wheel_cam.zoom_by_step(1.0)
	_check(is_equal_approx(wheel_cam.target_zoom.x, 2.5), "zooming in stops at 2.5× (%.2f)" % wheel_cam.target_zoom.x)
	var camera_2d := main.get_viewport().get_camera_2d()
	var zoom_was := camera_2d.zoom
	camera_2d.zoom = Vector2.ONE * 2.5
	_check(is_equal_approx(WorldLabel.text_scale(main.get_node("HUD/DriftPanel")), 1.0 / 2.5)
		or is_equal_approx(WorldLabel.text_scale(wheel_cam), 1.0 / 2.5), "world text is drawn at 1 / zoom when zoomed in")
	camera_2d.zoom = Vector2.ONE * 0.6
	_check(is_equal_approx(WorldLabel.text_scale(wheel_cam), 1.0), "and at its own size when zoomed out")
	camera_2d.zoom = zoom_was
	wheel_cam.target_zoom = Vector2.ONE
	var search := LineEdit.new()
	main.get_node("HUD").add_child(search)
	search.grab_focus()
	_check(wheel_cam._typing(), "typing in a text field: WASD stays in the field")
	search.queue_free()
	# Hover tips stay until the pointer leaves (screens_ui.md "Hover and tap tips"): another dispel
	# doesn't reset the nightmare info or its status hov_popup; its own dispel shows "Dispelled", then it
	# clears without jumping to the nightmare now under a still pointer.
	var hov_spawner = main.get_node("%EnemyContainer")
	var hov_info = main.get_node("%NightmareInfo")
	var shade_kind: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	var watched: Node2D = hov_spawner.spawn_enemy(shade_kind)
	var other: Node2D = hov_spawner.spawn_enemy(shade_kind)
	for e in [watched, other]:
		e.set_process(false)
	watched.apply_status(&"damp", 1, 30.0)
	hov_info._target = watched
	for i in 3:
		await process_frame
	var hov_popup: StatusLinks = hov_info._body.get_children().filter(func(c: Node) -> bool: return c is StatusLinks).front()
	hov_popup._show_for("status:damp", hov_info._body, true)
	other.take_damage(other.max_health * 10.0)
	for i in 20:
		await process_frame
	_check(hov_info._target == watched and hov_info.visible and hov_popup.visible,
		"another nightmare's dispel keeps the hovered info and its status hov_popup")
	hov_popup.visible = false
	var under_pointer: Node2D = hov_spawner.spawn_enemy(shade_kind)
	under_pointer.set_process(false)
	under_pointer.global_position = main.get_viewport().get_canvas_transform().affine_inverse() * main.get_viewport().get_mouse_position()
	watched.take_damage(watched.max_health * 10.0)
	await process_frame
	await process_frame
	_check(hov_info.visible and hov_info._title.text.contains("Dispelled"), "its own dispel reads Dispelled (" + hov_info._title.text + ")")
	for i in 80:
		await process_frame
	_check(not hov_info.visible and hov_info._target == null, "then it clears, without jumping to the nightmare under the pointer")
	under_pointer.queue_free()
	# The Warden bar isn't rewritten on every Dew change (a hovered button's tooltip would reset).
	var bar_button: Button = main.get_node("HUD").get("_tower_buttons")[0]
	var state_before = bar_button.get_meta(&"bar_state", "")
	main.get_node("HUD")._on_dew_changed(main.get_node("%RunState").dew)
	_check(state_before != "" and bar_button.get_meta(&"bar_state") == state_before, "the bar skips unchanged buttons")
	# --- The Heartwood Sapling: its card after the drift 50 family pick, then the rest panel ---
	# The Sapling is out of runs (TowerPlacer.sapling_enabled, run_design.md): no Codex terms for it.
	var sapling_terms := func() -> bool:
		return CodexData.glossary().any(func(group: Array) -> bool:
			return group[1].any(func(entry: Array) -> bool: return entry[0] == "Permanent"))
	_check(not TowerPlacer.sapling_enabled and not sapling_terms.call(), "no Sapling terms in the Codex while it's off")
	TowerPlacer.sapling_enabled = true  # The rest of this part checks the Sapling's UI when it's on
	# (Its terms were removed from the glossary for good: screens_ui.md "Glossary and Families, revised".)
	var sapling_placer = main.get_node("%TowerPlacer")
	if sapling_placer.has_method("can_take_sapling"):
		var started_before := director.drifts_started
		director.drifts_started = 50
		director.awaiting_family_pick = true
		var offered := []
		family.sapling_offered.connect(func() -> void: offered.append(true))
		family.show_pick(&"boss")
		if not family.offer.is_empty():
			family.choose(family.offer[0])
		_check(family.visible and family._title.text == "The Heartwood offers a seedling of itself",
			"the Sapling's card follows the drift 50 family pick")
		_check(offered.size() == 1, "sapling_offered fires once (for its sound)")
		var not_now: Button = family._cards.get_child(0).get_child(-1).get_child(1)
		not_now.pressed.emit()
		_check(not family.visible and sapling_placer.can_take_sapling(), "Not now keeps it for later")
		var sapling_panel = main.get_node("HUD/DriftPanel")
		sapling_panel._process(0.0)
		_check(sapling_panel._sapling_button.visible == director.is_resting(), "the rest panel offers to plant it")
		sapling_panel.plant_sapling()
		_check(sapling_placer.has_unplanted_sapling() and sapling_placer.build_mode, "Sapling: taken and ready to place")
		sapling_placer.set_build_mode(false)
		director.drifts_started = started_before
		if sapling_placer.sapling != null and sapling_placer.sapling.texture != null:
			var crop := WardenIcon.region(sapling_placer.sapling)
			_check(crop.size == Vector2(64, 64), "the Sapling's big frame is cropped to a 64×64 icon (%s)" % crop)
	TowerPlacer.sapling_enabled = false

	# --- Settings: tabs, and the high-contrast route line ---
	var settings := SettingsPanel.new()
	main.add_child(settings)
	var tab_names: Array = settings.tabs.get_children().map(func(c: Node) -> String: return c.name)
	var omen_pick: OptionButton = null
	for pick in settings.find_children("*", "OptionButton", true, false):
		if pick.item_count == 2 and pick.get_item_text(0) == "Ask each rest":
			omen_pick = pick
	_check(omen_pick != null and omen_pick.get_item_text(1) == "Never", "Gameplay: Omens Ask each rest / Never")
	_check(tab_names.has("Audio") and tab_names.has("Display") and tab_names.has("Accessibility") and tab_names.has("Controls"),
		"settings are in tabs (%s)" % [tab_names])
	settings.queue_free()
	var line := Line2D.new()
	RouteLine._high = 1
	RouteLine.apply(line, Color.WHITE)
	_check(line.width == RouteLine.CONTRAST_WIDTH and line.default_color == RouteLine.CONTRAST_COLOR, "high-contrast route line")
	RouteLine._high = 0
	RouteLine.apply(line, Color.WHITE)
	_check(line.width == 6.0 and line.default_color == Color.WHITE, "normal route line")
	RouteLine._high = -1
	line.free()

	# --- Demo mode override: developer setting, never applied in headless tests (temp profile) ---
	var real_profile := HeartwoodMemory.file_path
	HeartwoodMemory.file_path = "user://test_ui_profile_%d.json" % OS.get_process_id()  # Per process
	var profile := HeartwoodMemory.defaults()
	profile.settings[ResultsScreen.DEMO_MODE_SETTING] = 0 if ProjectSettings.get_setting("game/demo", false) else 1
	HeartwoodMemory.save_data(profile)
	_check(ResultsScreen.is_demo() == ProjectSettings.get_setting("game/demo", false), "tests ignore the Demo mode override")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	HeartwoodMemory.file_path = real_profile

	# --- Hover and tap tips stay (screens_ui.md): a Dew change doesn't rebuild the Warden panel ---
	var tip_tower := seller.get_tower_at(seller.selected.cell) if seller.selected else null
	if tip_tower == null:
		for t in main.get_node("%TowerContainer").get_children():
			if t is Tower and t.tower_data.can_attack:
				tip_tower = t
				break
	if tip_tower:
		seller.select(tip_tower)
		await process_frame
		var panel := main.find_child("WardenPanel", true, false)
		var priced: Array = panel._buttons.get_children().filter(func(b) -> bool: return b.has_meta(&"cost"))
		var ids: Array = panel._buttons.get_children().map(func(b) -> int: return b.get_instance_id())
		run_state.dew = 0
		run_state.dew_changed.emit(0)
		await process_frame
		var ids_after: Array = panel._buttons.get_children().map(func(b) -> int: return b.get_instance_id())
		_check(ids_after == ids, "a Dew change keeps the Warden panel's buttons (a tooltip under the pointer stays)")
		_check(priced.all(func(b) -> bool: return b.disabled), "and their affordability updates in place")
		run_state.dew = 100000
		run_state.dew_changed.emit(100000)
		_check(priced.all(func(b) -> bool: return not b.disabled or b.text.contains("Dreamlight")), "back when there's Dew")
		seller.select(null)

	# --- Pause summary and Abandon run ---
	var pause = main.get_node("%PauseMenu")
	(main.get_node("HUD/MenuButton") as Button).pressed.emit()
	_check(pause.visible, "the on-screen Menu button opens the pause menu")
	pause.close()
	var summary: String = pause.get_run_summary()
	_check(summary.contains("Drift 0") and summary.contains("Families"), "pause shows a run summary")
	pause.open()
	_check(paused, "the pause menu pauses")
	pause._abandon()
	await _frames(2)
	var results: ResultsScreen = main.get_node("%ResultsScreen")
	_check(run_state.is_over and not run_state.won and results.visible, "Abandon run ends the run (results still shown)")
	_check(not results.breakdown.is_empty(), "abandoning still earns Seeds")
	var stats := results.get_stats_text()
	_check(stats.contains("Leaves lost: 1") and stats.contains("Longest path"), "results show the run's stats (%s)" % stats)

	# --- Omen cards: no label's text past its card's content rect (the padding inside the border), at
	# 1280×800 and at the largest UI scale (1280×720 in view units). Face an Omen / Clear Skies, then
	# every Omen revealed (the long twists).
	var omen_screen = main.get_node("HUD/OmenScreen")
	var all_omens: Array[OmenData] = []
	for file in DirAccess.get_files_at("res://resource/omen"):
		if file.ends_with(".tres"):
			all_omens.append(load("res://resource/omen/" + file))
	for view in [Vector2i(1280, 800), Vector2i(1280, 720)]:
		root.size = view
		omen_screen._show_offer([] as Array[OmenData], 2)
		await _frames(3)
		_check_omen_cards(omen_screen, "front cards at %s" % view)
		var body_sizes: Array = []
		for card in omen_screen._cards.get_children():
			var labels: Array = card.find_children("*", "Label", true, false)
			body_sizes.append(labels[2].get_theme_font_size("font_size") if labels.size() > 2 else -1)  # Name, flavour, then the body
			_check(card.find_child("Flavor", true, false) != null, "%s has a flavour line (Omen voice)" % card.name)
		_check(body_sizes.size() == 2 and body_sizes[0] == body_sizes[1], "Face an Omen and Clear Skies share one body size (%s)" % [body_sizes])
		omen_screen._clear_cards()
		for i in range(0, all_omens.size(), 3):
			omen_screen._reveal(all_omens.slice(i, i + 3), null)
			await _frames(3)
			_check_omen_cards(omen_screen, "revealed Omens %d–%d at %s" % [i, i + 2, view])
			for card in omen_screen._cards.get_children():
				var reward_label: Label = card.find_child("Reward", true, false)
				_check(reward_label != null and (reward_label.text.begins_with("Reward · ") or reward_label.text.begins_with("Double-edged")) and not reward_label.text.contains(":"),
					"%s: \"Reward · …\", no colon (%s)" % [card.name, reward_label.text if reward_label else "none"])
			omen_screen._clear_cards()
	omen_screen._on_closed()
	root.size = Vector2i(1280, 800)

	main.queue_free()
	await process_frame
	print("ui test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _frames(n: int) -> void:
	for i in n:
		await process_frame

# Every Label / RichTextLabel in each Omen card keeps OMEN_MIN_PAD from the card edge (clear of the border).
const OMEN_MIN_PAD := Vector2(16, 14)
func _check_omen_cards(screen, what: String) -> void:
	for card in screen._cards.get_children():
		var inner := Rect2(card.get_global_rect().position + OMEN_MIN_PAD, card.get_global_rect().size - OMEN_MIN_PAD * 2.0).grow(0.5)
		for label in card.find_children("*", "", true, false):
			if not (label is Label or label is RichTextLabel) or not label.is_visible_in_tree() or label.text == "":
				continue  # Status-link popups and other hidden helpers
			var rect: Rect2 = label.get_global_rect()
			if label is RichTextLabel:
				rect.size.y = maxf(rect.size.y, label.get_content_height())
			_check(inner.encloses(rect), "Omen card %s: \"%s\" stays inside its card (%s in %s; %s)"
				% [card.name, label.text.left(24), rect, inner, what])

func _free_cell(map_generator) -> Vector2:
	var path: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	for i in range(3, path.size()):
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var cell: Vector2 = path[i] + offset
			if not path.has(cell) and map_generator.can_block(cell):
				return cell
	return Vector2(-1, -1)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
