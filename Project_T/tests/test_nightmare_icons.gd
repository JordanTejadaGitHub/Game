extends SceneTree

# Headless test for resistances as icons and the boss dossier (screens_ui.md "Nightmare info" and
# "Boss dossier", added 2026-09-28): the icon rows, the nightmare info's rows, map pips in context,
# the immune flash, "Coming this block", the dossier at the rest opening a boss block (after the
# Dream and the Omen), its content, reopening, the boss bar's 50% line and the boss record.
#   godot --headless --path . --script res://tests/test_nightmare_icons.gd --fixed-fps 60

const PROFILE_PATH := "user://test_nightmare_icons_profile.json"

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
	_check(strip != null and strip.visible and strip._row.get_child_count() == ComingStrip.kinds_in_block(director, 1).size(),
		"the strip shows block 1's kinds at the first rest")

	# --- The dossier at the rest opening block 5 (after drift 20) ----------------------------------
	var dossier := root.get_tree().get_first_node_in_group(BossDossier.GROUP) as BossDossier
	_check(dossier != null and not dossier.visible, "the dossier exists, closed")
	director.drifts_started = 20
	director.rest_started.emit(4, false, 0, true)
	for i in 40:
		await process_frame
	var omens := root.get_tree().get_first_node_in_group(OmenDirector.GROUP) as OmenDirector
	if dreams.is_offering() or dreams.has_pending_offer():
		_check(not dossier.visible, "the dossier waits for the Dream")
		dreams.skip()
		for i in 5:
			await process_frame
	if omens != null and omens.is_offering():
		_check(not dossier.visible, "the dossier waits for the Omen")
		omens.choose(null)
	for i in 40:
		await process_frame
	# New nightmares are introduced before the dossier (the test profile has met nothing).
	var intro := root.get_tree().get_first_node_in_group(NightmareIntro.GROUP) as NightmareIntro
	_check(intro != null, "the introduction card exists")
	if intro != null and NightmareIntro.enabled():
		_check(intro.visible and not dossier.visible, "a new kind's introduction comes before the dossier")
		var introduced := 0
		while intro.visible and introduced < 10:
			introduced += 1
			_check(intro._content.get_child_count() > 1, "the card shows " + (intro.shown.display_name if intro.shown else "?"))
			intro.advance()
		_check(introduced >= 1 and not intro.visible, "Next goes through each new kind (%d)" % introduced)
		_check(intro.new_kinds_in_block(5).is_empty(), "once shown, never again (session)")
		for i in 40:
			await process_frame
	_check(dossier.visible and dossier.shown_drift == 25, "the dossier shows itself last in the rest (drift %d)" % dossier.shown_drift)
	var text := _text(dossier._content)
	var health := NightmareCard.health_at(stag, 25, director)
	_check(health == maxi(roundi(stag.health * director.get_health_scale(stag, 25)), 1) and text.contains(str(health)),
		"the real boss health (%d)" % health)
	_check(text.contains(stag.title) and text.contains("Arrives in drift 25"), "header: title and arrival")
	_check(text.contains("What it does") and text.contains("Charge") and text.contains("at 50% health"), "abilities with when")
	_check(text.contains("What helps") and text.contains("Your record") and text.contains("New"), "tips and record")
	dossier.close_dossier()
	_check(not dossier.visible, "Prepare closes it")
	BossDossier.open_for(root.get_tree())
	_check(dossier.visible and dossier.shown_drift == 25, "reopens for the next boss")
	dossier.close_dossier()

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

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
