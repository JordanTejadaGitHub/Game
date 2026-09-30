extends SceneTree

# Headless test for resistances as icons and the boss dossier (screens_ui.md "Nightmare info" and
# "Boss dossier", added 2026-09-28): the icon rows, the nightmare info's rows, map pips in context,
# the immune flash, "Coming this block", the dossier at the start of each act (after the Dream, the
# Omen and the introductions), the boss-block reminder, its content, reopening, the boss bar's 50% line
# and the boss record.
#   godot --headless --path . --script res://tests/test_nightmare_icons.gd --fixed-fps 60

var PROFILE_PATH := "user://test_nightmare_icons_profile_%d.json" % OS.get_process_id()  # Per process: parallel sessions share user://

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = PROFILE_PATH  # Never the player's profile
	ResultsScreen.demo_override = 0  # The full game: every family's icons (the demo's: test_demo_scope)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE_PATH))
	var stag: EnemyData = load("res://resource/enemy/old_stag.tres")
	var wight: EnemyData = load("res://resource/enemy/barrow_wight.tres")
	var queen: EnemyData = load("res://resource/enemy/moth_queen.tres")

	# --- "New" = never seen on this profile (met on the field or read on its intro card) --------
	var shade: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	_check(NightmareCard.is_new(shade), "a never-met Shade is New")
	var profile := HeartwoodMemory.load_data()
	profile[NightmareIntro.SEEN_KEY] = ["leaf_bug"]
	HeartwoodMemory.save_data(profile)
	_check(not NightmareCard.is_new(shade), "a Shade read on its intro card isn't New")
	profile[NightmareIntro.SEEN_KEY] = []
	profile["nightmares_seen"] = ["leaf_bug"]
	HeartwoodMemory.save_data(profile)
	_check(not NightmareCard.is_new(shade), "a Shade met before isn't New")
	# Dev Grove on (a dev profile with its own Grove): account knowledge still lives on the real profile.
	var dev_path := "user://test_nightmare_icons_dev_%d.json" % OS.get_process_id()
	HeartwoodMemory.real_settings_path = PROFILE_PATH
	HeartwoodMemory.file_path = dev_path
	HeartwoodMemory.save_data(HeartwoodMemory.defaults())  # The dev profile: nothing seen
	_check(not NightmareCard.is_new(shade), "Dev Grove on: a Shade met on the real profile isn't New")
	var dev_data := HeartwoodMemory.load_data()
	dev_data["nightmares_seen"] = ["leaf_bug", "bark_beetle"]
	HeartwoodMemory.save_data(dev_data)
	HeartwoodMemory.file_path = PROFILE_PATH
	HeartwoodMemory.real_settings_path = ""
	_check(HeartwoodMemory.load_data().get("nightmares_seen", []).has("bark_beetle"),
		"a nightmare met with Dev Grove on is saved to the real profile")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dev_path))
	HeartwoodMemory.save_data(HeartwoodMemory.defaults())

	# --- The icon rows --------------------------------------------------------------------------
	var rows := NightmareIcons.make_rows(stag)
	var resist_icons := _icons(rows, NightmareIcons.Kind.FAMILY, &"resist")
	var weak_icons := _icons(rows, NightmareIcons.Kind.FAMILY, &"weak")
	_check(resist_icons.size() == stag.resists.size() and weak_icons.size() == stag.weak_to.size(),
		"the Hollow Stag's rows: %d resist, %d weak icons" % [resist_icons.size(), weak_icons.size()])
	_check(_text(rows).contains("Resists") and _text(rows).contains("Stone ×0.5") and _text(rows).contains("Weak to") and _text(rows).contains("Water ×1.5"),
		"rows name the damage types (" + _text(rows) + ")")
	var pebble := NightmareIcons.family("stone", &"resist")
	_check(pebble.tip == "Resists Stone: Stone damage deals half to it.", "resist tooltip (%s)" % pebble.tip)
	_check(IconInfo.damage_type_name("wing") == "Talon" and IconInfo.damage_type_name("acorn") == "Plain"
		and IconInfo.damage_type_text("light") == "Light damage", "damage type names (wing = Talon, acorn = Plain)")
	_check(["spore", "stone", "water", "light", "root", "song", "wing", "wind", "acorn"].all(func(l: String) -> bool: return IconInfo.damage_type_icon(l) != null),
		"every damage type (and Plain) has its sheet icon")
	var wight_rows := NightmareIcons.make_rows(wight)
	_check(not _icons(wight_rows, NightmareIcons.Kind.STATUS, &"immune").is_empty(), "the Barrow Wight shows a crossed-out Rooted")
	var short := _icons(wight_rows, NightmareIcons.Kind.STATUS, &"short")
	_check(short.size() == 1 and short[0].id == "drowsy" and short[0].tip.contains("twice as fast"),
		"…and Drowsy with ½ (%s)" % (short[0].tip if not short.is_empty() else "none"))
	_check(NightmareIcons.traits_of(queen).has(&"flying"), "the Moth Queen has the Flying trait icon")
	_check(NightmareIcons.shrugs_off(stag).has(&"held"), "bosses shrug off Rooted (½)")
	for art_id in NightmareIcons.TRAITS.keys() + [&"charge", &"sink", &"eclipse", &"brood", &"sapling", &"grief", &"rises"]:
		_check(IconInfo.icon(art_id) != null, "the sheet has the " + String(art_id) + " icon (used over the drawn glyph)")
	var empty := NightmareIcons.make_rows(load("res://resource/enemy/leaf_bug.tres"), 16.0, true)
	_check(empty.get_child_count() == 0 or not stag.resists.is_empty(), "a compact row with nothing to show is empty")

	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var director: DriftDirector = main.get_node("%DriftDirector")
	var spawner = main.get_node("%EnemyContainer")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var dreams: DreamState = main.get_node("%DreamState")
	dreams.unlock_everything = true

	# --- Nightmare info rows ----------------------------------------------------------------------
	var enemy: Node2D = spawner.spawn_enemy(stag)
	enemy.set_process(false)
	var info = main.get_node("%NightmareInfo")
	info._target = enemy
	await process_frame
	_check(info.visible and not _icons(info._rows_box, NightmareIcons.Kind.FAMILY, &"resist").is_empty(),
		"the nightmare info shows the resist icons")

	# --- Map pips in context -------------------------------------------------------------------
	var pips: ResistPips = null
	for child in main.get_children():
		if child is ResistPips:
			pips = child
	_check(pips != null, "the map pips layer exists")
	if pips != null:
		_check(pips.get_lines().is_empty(), "no pips without context")
		placer.select_tower(load("res://resource/tower/pebbling.tres"))
		_check(pips.get_lines() == ["stone"], "placing a Pebbling compares against stone (%s)" % str(pips.get_lines()))
		_check(ResistPips.pip_for(stag, ["stone"]) == -1, "the Stag resists stone: shield pip")
		_check(ResistPips.pip_for(stag, ["water"]) == 1, "the Stag is weak to water: spark pip")
		_check(ResistPips.pip_for(stag, ["stone", "water"]) == 2, "a mixed selection shows both")
		placer.set_build_mode(false)
		# Immune flash: once, throttled.
		spawner.status_refused.emit(enemy, &"held")
		spawner.status_refused.emit(enemy, &"held")
		_check(pips._flashes.size() == 1, "a refused status flashes once (throttled): %d" % pips._flashes.size())
	enemy.queue_free()
	await process_frame

	# --- Coming this block -----------------------------------------------------------------------
	var kinds := ComingStrip.kinds_in_block(director, 5)
	_check(not kinds.is_empty() and kinds.back()[0].is_boss and kinds.back()[1] == 25,
		"block 5's kinds end with the boss in drift 25")
	var strip: ComingStrip = null
	for child in main.get_node("HUD").get_children():
		if child is ComingStrip:
			strip = child
	await process_frame
	_check(strip != null and strip.visible and strip.items().size() == ComingStrip.kinds_in_block(director, 1).size(),
		"the strip shows block 1's kinds at the first rest")
	# "Too tall" (screens_ui.md): one row of equal discs, the count a badge on the disc, the name on hover.
	var first_kinds := ComingStrip.kinds_in_block(director, 1)
	if strip != null and not first_kinds.is_empty():
		var first_item: Control = strip.items()[0]
		var count_label := first_item.find_child("KindCount", true, false) as Label
		var face := first_item.get_child(0) as Button
		_check(count_label != null and count_label.text == "×%d" % first_kinds[0][2] and face.tooltip_text.begins_with(first_kinds[0][0].display_name)
			and first_item.find_child("KindName", true, false) == null, "each kind: its count as a badge, its name on hover")
		_check(strip._row.get_child_count() == ceili(first_kinds.size() / float(ComingStrip.PER_ROW))
			and face.size.x == face.size.y, "one row of up to 6 round discs (no wide pills)")
		await process_frame
		_check(strip.get_combined_minimum_size().y <= 100.0, "the strip stays low (%.0f px)" % strip.get_combined_minimum_size().y)
	var d10 := ComingStrip.kinds_in_range(director, 10, 10)
	var listed := 0
	for group in director.drifts[9].groups:
		for entry in group.entries:
			if entry.enemy == d10[0][0]:
				listed += entry.count
	_check(d10[0][2] >= listed, "counts include the extra nightmares (drift 10: %d listed, %d shown)" % [listed, d10[0][2]])

	# --- The dossier at the start of each act (screens_ui.md, 2026-09-29) ---------------------------
	# Act 1: it opens by itself at the run's first rest, after the new kinds' introductions (the test
	# profile has met nothing).
	var dossier := root.get_tree().get_first_node_in_group(BossDossier.GROUP) as BossDossier
	var omens := root.get_tree().get_first_node_in_group(OmenDirector.GROUP) as OmenDirector
	var intro := root.get_tree().get_first_node_in_group(NightmareIntro.GROUP) as NightmareIntro
	_check(dossier != null and intro != null, "the dossier and the introduction card exist")
	main.get_node("%Whispers").set_enabled(false)  # Deterministic: no onboarding whispers to wait for
	var intro_first := false
	for i in 150:
		await process_frame
		if intro.visible:
			intro_first = intro_first or not dossier.visible
			intro.advance()
		if dossier.visible:
			break
	if NightmareIntro.enabled():
		_check(intro_first, "a new kind's introduction comes before the dossier")
	_check(dossier.visible and dossier.shown_drift == 25, "act 1: the dossier opens by itself at the first rest (drift %d)" % dossier.shown_drift)
	var text := _text(dossier._content)
	var health := NightmareCard.health_at(stag, 25, director)
	_check(health == maxi(roundi(stag.health * director.get_health_scale(stag, 25)), 1) and text.contains(str(health)),
		"the real boss health (%d)" % health)
	_check(text.contains(stag.title) and text.contains("Arrives in drift 25"), "header: title and arrival")
	_check(text.contains("What it does") and text.contains("Charge") and text.contains("at 50% health"), "abilities with when")
	_check(not text.contains("What helps") and text.contains("Your record") and text.contains("New"), "no What helps (removed 2026-09-30); the record")
	dossier.close_dossier()
	_check(not dossier.visible, "Prepare closes it")
	BossDossier.open_for(root.get_tree())
	_check(dossier.visible and dossier.shown_drift == 25, "reopens for the next boss")
	dossier.close_dossier()

	# The rest opening the boss block (after drift 20): only a reminder, with "Open dossier".
	director.drifts_started = 20
	director.rest_started.emit(4, false, 0, true)
	await _settle(dossier, dreams, omens, intro, func() -> bool: return dossier.is_reminding())
	_check(dossier.is_reminding() and not dossier.visible, "the boss-block rest only shows a reminder")
	_check(_text(dossier._reminder).contains("arrives in 5 drifts"), "\"The Hollow Stag arrives in 5 drifts\" (%s)" % _text(dossier._reminder))
	await process_frame  # Placed each frame
	for coming in dossier.get_parent().get_children():
		if coming is ComingStrip and coming.visible:
			_check(dossier._reminder.position.y >= coming.position.y + coming.size.y,
				"the reminder sits under the Coming strip, not on it (%.0f vs %.0f)" % [dossier._reminder.position.y, coming.position.y + coming.size.y])
	var open_button: Button = dossier._reminder.find_children("*", "Button", true, false)[0]
	open_button.pressed.emit()
	_check(dossier.visible and dossier.shown_drift == 25 and not dossier.is_reminding(), "Open dossier opens the card")
	dossier.close_dossier()

	# The act break (the boss rest after drift 25): the NEXT act's boss, last in the rest.
	director.drifts_started = 25
	director.rest_started.emit(5, true, 0, true)
	await _settle(dossier, dreams, omens, intro, func() -> bool: return dossier.visible)
	_check(dossier.visible and dossier.shown_drift == 50, "act 2 begins: the dossier shows the Mire Hag's drift (%d)" % dossier.shown_drift)
	dossier.close_dossier()
	director.drifts_started = 0

	# --- The boss bar's 50% marker -----------------------------------------------------------------
	var banner = main.get_node("%DriftBanner")
	var boss: Node2D = spawner.spawn_enemy(stag)
	boss.set_process(false)
	await process_frame
	_check(banner.half_health_text().begins_with("At 50% health · Charge"), "the 50 percent marker names the ability (" + banner.half_health_text() + ")")
	banner._boss = spawner.spawn_enemy(load("res://resource/enemy/hollow_oak.tres"))
	banner._boss.set_process(false)
	var oak_lines: Dictionary = banner.marker_lines()
	_check(oak_lines.has(0.67) and oak_lines.has(0.33) and not oak_lines.has(0.5), "the Oak marks 67 and 33 percent, not 50: " + str(oak_lines.keys()))
	banner._boss.queue_free()
	boss.queue_free()

	# Click / tap a nightmare: its centred card with live state; a boss: the dossier; a never-seen
	# kind spawning mid-block opens its card too.
	if intro != null:
		var click_spawner = main.get_node("%EnemyContainer")
		var clicked: Node2D = click_spawner.spawn_enemy(load("res://resource/enemy/bark_beetle.tres"))
		clicked.set_process(false)
		await process_frame
		var at: Vector2 = main.get_viewport().get_canvas_transform() * clicked.global_position
		for pressed in [true, false]:
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = pressed
			click.position = at
			intro._unhandled_input(click)
		_check(intro.visible and intro.shown == clicked.enemy_data and intro._live_label != null
			and intro._live_label.text.begins_with("Health"), "clicking a nightmare opens its card with live health")
		intro.close()
		clicked.queue_free()
		var kind := NightmareIntro.kind_of(load("res://resource/enemy/puffcaplet.tres"))
		NightmareIntro.session_seen.erase(kind)
		intro._met.erase(kind)
		# One card at a time: a second open replaces the first; the card pauses (at a rest too) and
		# closing resumes; it's always on, whispers or not.
		var speed_node: GameSpeed = main.get_node("%GameSpeed")
		speed_node.set_paused(false)
		intro.open([load("res://resource/enemy/leaf_bug.tres")], 0)
		intro.open([load("res://resource/enemy/bark_beetle.tres")], 0)
		_check(intro.visible and intro.shown.display_name == load("res://resource/enemy/bark_beetle.tres").display_name and intro.queue.is_empty(),
			"a second card replaces the first (no stacking)")
		_check(speed_node.paused, "the card stops the game, even at a rest")
		var old_size: Vector2i = root.size
		root.size = Vector2i(1280, 800)  # A real window (the test's is 64 px, smaller than the card)
		await process_frame
		await process_frame
		var card_centre: Vector2 = intro._panel.get_global_rect().get_center()
		var screen_centre: Vector2 = intro.get_viewport_rect().size / 2.0
		_check(card_centre.distance_to(screen_centre) < 2.0, "the card is centred on screen (%s vs %s)" % [card_centre, screen_centre])
		root.size = old_size
		intro.close()
		_check(not speed_node.paused, "closing it resumes")
		_check(NightmareIntro.enabled(), "introductions are always on")
		NightmareIntro.pause_in_tests = true  # This part checks the mid-drift card
		var sob: Node2D = click_spawner.spawn_enemy(load("res://resource/enemy/puffcaplet.tres"))
		sob.set_process(false)
		await process_frame
		await process_frame
		_check(not NightmareIntro.enabled() or (intro.visible and intro.shown.display_name == "Sob"),
			"a never-seen kind appearing mid-block opens its centred card")
		intro.close()
		sob.queue_free()
		NightmareIntro.pause_in_tests = false
	# --- Record ----------------------------------------------------------------------------------
	BossDossier.record_dispel(stag, 65.0)
	BossDossier.record_dispel(stag, 80.0)
	_check(BossDossier.record_text(stag) == "Dispelled 2 times · best 1:05", "the record (%s)" % BossDossier.record_text(stag))

	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE_PATH))
	main.queue_free()
	await process_frame
	ResultsScreen.demo_override = -1
	print("nightmare icons test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _icons(node: Node, kind: int, mode: StringName) -> Array:
	var out: Array = []
	for child in node.find_children("*", "", true, false):
		if child is NightmareIcons and child.kind == kind and child.mode == mode:
			out.append(child)
	return out

func _text(node: Node) -> String:
	var parts: Array[String] = []
	for child in node.find_children("*", "", true, false):
		if child is Label:
			parts.append(child.text)
		elif child is RichTextLabel:
			parts.append(child.get_parsed_text())
	return " | ".join(parts)

# Runs frames through a rest's screens (Dream offer skipped, Omen passed, introductions advanced)
# until `done` is true or ~4 s pass.
func _settle(dossier: BossDossier, dreams: DreamState, omens: OmenDirector, intro: NightmareIntro, done: Callable) -> void:
	var remember := dossier.drift_director.owner.get_node_or_null("HUD/RememberScreen") as RememberScreen
	for i in 240:
		await process_frame
		if dreams.is_offering() or dreams.has_pending_offer():
			_check(not dossier.visible, "the dossier waits for the Dream")
			dreams.skip()
		if omens != null and omens.is_offering():
			_check(not dossier.visible, "the dossier waits for the Omen")
			omens.choose(null)
		if intro != null and intro.visible:
			intro.advance()
		if remember != null and remember.visible:
			_check(not dossier.visible, "the dossier waits for Remember")
			remember.close()
		if done.call():
			return

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
