extends SceneTree

# Headless test for the phone layout base (mobile only; UiStyle.PHONE_LAYOUT_MIN, Mobile chat): at the views a phone
# gets (1200×540 on 20:9, 1100×619 on 16:9) every button of the HUD and the full-screen screens is on screen and
# at least 40 tall (48 for the screens' own actions). Never touches the player's saves.
#   godot --headless --path . --script res://tests/test_phone_layout.gd --fixed-fps 60

const VIEWS := [Vector2i(1200, 540), Vector2i(1100, 619)]
const MIN_H := 40.0

var failures := 0
var main: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	TouchBuild.force_mobile = true
	_check(UiStyle.is_phone() and UiStyle.layout_min() == UiStyle.PHONE_LAYOUT_MIN, "phones lay out for the phone base")
	# The notch: the HUD layer fits the safe area (UiStyle.safe_transform; real phones only)
	_check(UiStyle.safe_transform(Vector2(1200, 540), Rect2()) == Transform2D.IDENTITY, "no unsafe edges: the HUD stays as is")
	var notch := Rect2(Vector2(60, 0), Vector2(20, 10))  # 60 left, 20 right, 10 bottom
	var fitted := UiStyle.safe_transform(Vector2(1200, 540), notch)
	var top_left: Vector2 = fitted * Vector2.ZERO
	var bottom_right: Vector2 = fitted * Vector2(1200, 540)
	_check(top_left.x >= 60.0 - 0.01 and bottom_right.x <= 1180.0 + 0.01 and bottom_right.y <= 530.0 + 0.01
		and is_equal_approx(fitted.get_scale().x, fitted.get_scale().y),
		"a notch: the HUD scales evenly into the safe rect (%s → %s)" % [top_left, bottom_right])
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	for i in 5:
		await process_frame
	var dreams: DreamState = main.get_node("%DreamState")
	var director: DriftDirector = main.get_node("%DriftDirector")
	for view in VIEWS:
		root.size = view
		await _settle()
		_close_all()
		await _settle()
		_check_buttons("HUD", main.get_node("HUD"), view, true)
		# The HUD row buttons and the DriftPanel are 48 on PC: a phone layout never shrinks them (UI Code)
		var row: Array = ["MenuButton", "CodexButton", "RememberButton"].map(func(n: String) -> Node: return main.get_node_or_null("HUD/" + n))
		row.append_array(main.get_node("HUD/DriftPanel").find_children("*", "BaseButton", true, false))
		var short: Array = row.filter(func(b) -> bool: return b is Control and b.is_visible_in_tree() and b.size.y < UiStyle.HUD_BUTTON_H - 0.5) \
			.map(func(b: Control) -> String: return "%s (%d)" % [b.name, int(b.size.y)])
		_check(short.is_empty(), "HUD %s: the top row and DriftPanel buttons stay %d tall %s" % [view, int(UiStyle.HUD_BUTTON_H), short])
		# The counters top left, the buttons top right (Menu at the corner), the speeds one cycling button (user 2026-10-18,
		# after the mobile TD survey)
		var hud_node: Node = main.get_node("HUD")
		var leaves_x: float = (hud_node.leaves_label as Control).get_global_rect().position.x
		var menu_rect: Rect2 = (main.get_node("HUD/MenuButton") as Control).get_global_rect()
		var banner_rect: Rect2 = main.get_node("%DriftBanner").drawn_rect()
		_check(leaves_x < 60.0, "HUD %s: the counters start top left (%d)" % [view, int(leaves_x)])
		_check(menu_rect.end.x > view.x - 40.0, "HUD %s: Menu in the top-right corner (%d)" % [view, int(menu_rect.end.x)])
		_check(not hud_node.get_node("ResourcesFog").get_global_rect().intersects(banner_rect),
			"HUD %s: the counters stay clear of the banner" % [view])
		var speeds: Array = main.get_node("HUD/DriftPanel").find_children("*", "Button", true, false).filter(func(b: Button) -> bool:
			return b.text.ends_with("×"))
		_check(speeds.size() == 1, "HUD %s: one speed button (%d)" % [view, speeds.size()])
		var pause: Node = main.get_node("HUD/PauseMenu")
		pause.open()
		await _settle()
		_check_buttons("pause menu", pause, view)
		pause._show_settings()  # Settings: every tab
		await _settle()
		await _check_tabs("settings", pause._settings, view)
		pause.open_codex()  # The Codex: every tab
		await _settle()
		# Opened straight from This run (the HUD's "?" does this): the Codex fills the pane, never This run's hug (user 2026-10-19)
		var pane_h: float = (pause.get("_pane_box") as Control).size.y
		_check(pane_h > view.y * 0.7, "Codex %s: opened directly it fills the pane (%d of %d)" % [view, int(pane_h), int(view.y)])
		await _check_tabs("Codex", pause.find_children("*", "CodexPanel", true, false).front(), view)
		pause.close()
		dreams.stacks[DREAM_CARDS[0]] = 1  # A Dream taken: Your Dreams shows
		var cards := dreams.make_offer(5)
		dreams.offer_ready.emit(cards, 5)
		await _settle()
		_check_buttons("Dream", main.get_node("HUD/DreamScreen"), view)
		await _check_choice_extras(view, main.get_node("HUD/DreamScreen"))
		main.get_node("HUD/DreamScreen").visible = false
		director.family_pick_requested.emit(&"first")
		await _settle()
		_check_buttons("family pick", main.get_node("HUD/FamilyPickScreen"), view)
		main.get_node("HUD/FamilyPickScreen").visible = false
		# The Omens and the Heartwood's gifts: the Dream screen's phone layout too (PhoneChoice)
		var omen_director: OmenDirector = main.get_node("%OmenDirector")
		var omen_screen := main.get_node("HUD/OmenScreen")
		omen_director.current_offer = omen_director.make_offer(3)
		omen_director.current_offer_block = 3
		omen_director.offer_ready.emit(omen_director.current_offer, 3)
		await _settle()
		_check_buttons("Omen", omen_screen, view)
		_check(omen_screen.get_node_or_null("PhoneLayout") != null, "Omen %s: the phone layout" % view)
		omen_screen._reveal(omen_director.face(), null)
		await _settle()
		_check_buttons("Omens revealed", omen_screen, view)
		omen_director.faced = false
		omen_director.current_offer = []
		omen_screen._on_closed()
		var gift_screen := main.get_node_or_null("HUD/GiftScreen") as GiftScreen
		if gift_screen != null:
			gift_screen.gifts.current_offer = gift_screen.gifts.draw(1)
			gift_screen.open()
			await _settle()
			_check_buttons("gifts", gift_screen, view)
			_check(gift_screen.get_node_or_null("PhoneLayout") != null, "gifts %s: the phone layout" % view)
			gift_screen._close()
			gift_screen.gifts.current_offer = []
		var dossier := main.get_node("HUD/BossDossier") as BossDossier
		dossier.open_for(self, 25)
		await _settle()
		_check_buttons("boss dossier", dossier, view)
		dossier.close_dossier()
		main.get_node("%GameSpeed").set_paused(false)
		await _check_dreams_page(view, dreams)
	# The results screen (last: a run end can't be undone)
	for view in VIEWS:
		root.size = view
		var results := main.get_node("%ResultsScreen")
		if view == VIEWS[0]:
			main.get_node("%RunState").end_run(false)
		await _settle()
		_check_buttons("results", results, view)

	TouchBuild.force_mobile = false
	_check(not UiStyle.is_phone() and UiStyle.layout_min() == UiStyle.LAYOUT_MIN, "the PC keeps its base")
	main.queue_free()
	await process_frame
	print("FAILURES: %d" % failures if failures > 0 else "PASS")
	quit(failures)

# "Dreams this run" on phones (user 2026-10-17: "make it a whole screen UI"): opened from the HUD's Dreams button it fills
# the screen above the HUD's top-right row and dock (under the pause menu), every button on screen and 44+ tall; Close
# and Android Back close it.
const DREAM_CARDS := ["morning_dew", "longer_roots", "deep_roots", "thick_bark", "quick_step", "tender_care"]

func _check_dreams_page(view: Vector2i, dreams: DreamState) -> void:
	var hud := main.get_node("HUD")
	var row := main.get_node("%DreamsRow") as DreamsRow
	for id in DREAM_CARDS:
		dreams.stacks[id] = 1
	row.refresh()
	hud.dreams_button.button_pressed = true
	await _settle()
	var page: Control = row._list
	_check(page.visible and row.strip_hidden, "Dreams this run %s: opens from the Dreams button" % view)
	var r := page.get_global_rect()
	_check(_fills(r, view),
		"Dreams this run %s: fills the screen (%s)" % [view, r])
	_check(row.get_index() > hud.get_node("MenuButton").get_index() and row.get_index() > hud.get_node("%TowerBar").get_index()
		and row.get_index() < hud.get_node("PauseMenu").get_index(), "Dreams this run %s: above the HUD, under the pause menu" % view)
	_check(page.find_children("Row_*", "", true, false).size() >= DREAM_CARDS.size(), "Dreams this run %s: a row per Dream" % view)
	var screen := Rect2(Vector2.ZERO, Vector2(view))
	var bad: Array[String] = []
	for button in page.find_children("*", "BaseButton", true, false):
		if not button.is_visible_in_tree():
			continue
		var scroll := _scroll_of(button)
		var at: Rect2 = scroll.get_global_rect() if scroll != null else button.get_global_rect()
		if not screen.encloses(at.grow(-0.5)) or button.size.y < 44.0:
			bad.append("%s %s" % [button.name, button.get_global_rect()])
	_check(bad.is_empty(), "Dreams this run %s: every button on screen and 44+ tall %s" % [view, bad])
	var close := page.find_child("PhoneClose", true, false) as Button
	_check(close != null and close.size.x >= 44.0, "Dreams this run %s: a square Close" % view)
	if close != null:
		close.pressed.emit()
	await _settle()
	_check(not page.visible and not hud.dreams_button.button_pressed, "Dreams this run %s: Close closes it (%s %s)" % [view, page.visible, hud.dreams_button.button_pressed])
	hud.dreams_button.button_pressed = true
	await _settle()
	var back := InputEventAction.new()
	back.action = &"open_menu"
	back.pressed = true
	root.push_input(back)
	await _settle()
	_check(not page.visible and not main.get_node("HUD/PauseMenu").visible, "Dreams this run %s: Back closes it, no pause menu (%s %s)" % [view, page.visible, main.get_node("HUD/PauseMenu").visible])
	var pause: Node = main.get_node("HUD/PauseMenu")
	if pause.visible:
		pause.close()
	main.get_node("%GameSpeed").set_paused(false)

# Phone choice screens (user 2026-10-18): Glossary and Your Dreams top right (on screen, 44+ tall), Peek bottom left
# before Let it pass; each opens above the screen, which stays open; Close / Android Back return to it.
func _check_choice_extras(view: Vector2i, screen: Control) -> void:
	var hud := main.get_node("HUD")
	var pause: Node = hud.get_node("PauseMenu")
	var rect := Rect2(Vector2.ZERO, Vector2(view))
	var glossary := screen.find_child("GlossaryButton", true, false) as Button
	var mine := screen.find_child("YourDreamsButton", true, false) as Button
	for pair in [[glossary, "Glossary"], [mine, "Your Dreams"]]:
		var b: Button = pair[0]
		var r: Rect2 = b.get_global_rect() if b != null else Rect2()
		_check(b != null and b.is_visible_in_tree() and rect.encloses(r.grow(-0.5)) and b.size.y >= 44.0
			and r.position.x > view.x * 0.5 and r.end.y < view.y * 0.3, "Dream %s: %s top right, on screen, 44+ tall (%s)" % [view, pair[1], r])
	var peek_button: Button = null
	for b in screen.find_children("*", "Button", true, false):
		if (b as Button).text == "Peek at the map":
			peek_button = b
	var skip := screen.get("_skip") as Button
	var take := screen.find_child("TakeButton", true, false) as Button
	var pr: Rect2 = peek_button.get_global_rect() if peek_button != null else Rect2()
	_check(peek_button != null and peek_button.is_visible_in_tree() and pr.end.x < view.x * 0.5 and pr.position.y > view.y * 0.6
		and (not skip.visible or pr.end.x <= skip.get_global_rect().position.x), "Dream %s: Peek bottom left, before Let it pass (%s)" % [view, pr])
	_check(take != null and take.get_global_rect().position.x > view.x * 0.5 and (not skip.visible or absf(take.size.x - skip.size.x) < 1.0),
		"Dream %s: Take bottom right, as wide as Let it pass" % view)
	if glossary == null or mine == null:
		return
	# Glossary: the Codex on its Glossary tab over the screen
	glossary.pressed.emit()
	await _settle()
	var over := screen.get_node_or_null("ChoiceCodex") as Control
	var codex: CodexPanel = over.find_children("*", "CodexPanel", true, false).front() as CodexPanel if over != null else null
	_check(over != null and over.is_visible_in_tree() and over.get_index() == screen.get_child_count() - 1 and over.z_index >= 20
		and over.mouse_filter == Control.MOUSE_FILTER_STOP and over.get_global_rect().size.distance_to(Vector2(view)) < 1.0
		and codex != null and codex.visible and codex.tabs.get_current_tab_control().name == "Glossary" and screen.visible,
		"Dream %s: Glossary opens the Codex's Glossary above the screen, which stays open" % view)
	_check_buttons("Dream Glossary", over, view)
	var back := InputEventAction.new()
	back.action = &"open_menu"
	back.pressed = true
	root.push_input(back)
	await _settle()
	_check(over != null and not over.visible and screen.visible and not pause.visible, "Dream %s: Back closes the Codex, back to the Dream" % view)
	# Your Dreams: "Dreams this run" above the screen
	mine.pressed.emit()
	await _settle()
	var row := main.get_node("%DreamsRow") as DreamsRow
	var page: Control = row._list
	_check(page.is_visible_in_tree() and row.get_index() > screen.get_index() and row.z_index >= 20 and screen.visible
		and _fills(page.get_global_rect(), view), "Dream %s: Your Dreams opens Dreams this run above the screen (row %d, screen %d)" % [view, row.get_index(), screen.get_index()])
	var close := page.find_child("PhoneClose", true, false) as Button
	if close != null:
		close.pressed.emit()
	await _settle()
	_check(not page.is_visible_in_tree() and screen.visible and row.z_index == 0, "Dream %s: Close returns to the Dream" % view)
	mine.pressed.emit()
	await _settle()
	root.push_input(back.duplicate())
	await _settle()
	_check(not page.visible and screen.visible and not pause.visible, "Dream %s: Back closes Dreams this run, back to the Dream" % view)
	if pause.visible:
		pause.close()

# A tabbed panel: its buttons on every tab.
func _check_tabs(what: String, panel: Node, view: Vector2i) -> void:
	if panel == null:
		_check(false, "%s %s: found" % [what, view])
		return
	var tabs: Array = panel.find_children("*", "TabContainer", true, false)
	if tabs.is_empty():
		_check_buttons(what, panel, view)
		return
	var container: TabContainer = tabs.front()
	for i in container.get_tab_count():
		if container.is_tab_hidden(i):
			continue
		container.current_tab = i
		await _settle()
		_check_buttons("%s/%s" % [what, container.get_tab_title(i)], panel, view)

# A full-screen page: the whole width down to the bottom, its top at most 16 px down (moon-glass leaves room for the
# rim sprout above it, DreamsRow.PAGE_GLASS_TOP).
func _fills(r: Rect2, view: Vector2i) -> bool:
	return absf(r.position.x) < 1.0 and r.position.y >= -1.0 and r.position.y <= 16.0 \
		and absf(r.size.x - view.x) < 1.0 and absf(r.end.y - view.y) < 1.0

func _settle() -> void:
	for i in 3:
		await process_frame

func _close_all() -> void:
	for path in ["HUD/BossDossier", "HUD/NightmareIntro", "HUD/Whispers", "HUD/DreamScreen", "HUD/FamilyPickScreen"]:
		var screen := main.get_node_or_null(path) as CanvasItem
		if screen != null and screen.visible:
			if screen.has_method("close_dossier"):
				screen.close_dossier()
			else:
				screen.visible = false
	var pause := main.get_node("HUD/PauseMenu")
	if pause.visible:
		pause.close()
	main.get_node("%GameSpeed").set_paused(false)

# Every visible button under `node` is inside the view and tall enough to tap. The HUD skips its full-screen screens.
func _check_buttons(what: String, node: Node, view: Vector2i, hud_only := false) -> void:
	var rect := Rect2(Vector2.ZERO, Vector2(view))
	var off: Array[String] = []
	var small: Array[String] = []
	for button in node.find_children("*", "BaseButton", true, false):
		if not button.is_visible_in_tree():
			continue
		if hud_only and _inside_screen(button):
			continue
		var r: Rect2 = button.get_global_rect()
		if r.size.x < 2.0:
			continue
		var label: String = button.text if "text" in button and button.text != "" else String(button.name)
		var scroll := _scroll_of(button)
		if scroll != null:
			r = scroll.get_global_rect()  # In a scrolling list: the list is on screen, the rest scrolls into view
		if not rect.encloses(r.grow(-0.5)):
			off.append("%s %s" % [label.left(24), r])
		if button.size.y < MIN_H:
			small.append("%s (%d)" % [label.left(24), int(button.size.y)])
	_check(off.is_empty(), "%s %s: every button on screen %s" % [what, view, off])
	_check(small.is_empty(), "%s %s: every button %d+ tall %s" % [what, view, int(MIN_H), small])

func _scroll_of(control: Node) -> ScrollContainer:
	var up := control.get_parent()
	while up != null:
		if up is ScrollContainer:
			return up
		up = up.get_parent()
	return null

func _inside_screen(control: Node) -> bool:
	var up := control.get_parent()
	while up != null and up.name != "HUD":
		if up.name in ["PauseMenu", "DreamScreen", "FamilyPickScreen", "BossDossier", "RememberScreen", "ResultsScreen", "OmenScreen", "NightmareIntro"]:
			return true
		up = up.get_parent()
	return false

func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   " + label)
	else:
		print("  FAIL " + label)
		failures += 1
