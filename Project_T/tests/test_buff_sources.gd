extends SceneTree

# Headless test for buff readability (screens_ui.md "Buff readability"): BuffSources lists what boosts a
# Warden (auras with falloff positions and Kindred), who a support Warden boosts, the placement preview,
# pips; BuffOverlay follows Main's BuffLens; the Warden panel's Buffs section. Run from the project folder:
#   godot --headless --path . --script res://tests/test_buff_sources.gd --fixed-fps 60

const CELL := 64.0

var failures := 0
var placer: TowerPlacer
var container: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	await process_frame
	placer = main.get_node("%TowerPlacer")
	container = main.get_node("%TowerContainer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var panel: Node = main.find_child("WardenPanel", true, false)
	for child in main.get_node("%EnemyContainer").get_children():
		child.queue_free()

	var target := _plant("sporeling", Vector2(12, 12))
	var first := _plant("elder_stump", Vector2(11, 12))
	var second := _plant("elder_stump", Vector2(13, 12))
	var acorn := _plant("acorn", Vector2(12, 11))
	target._refresh_neighbours()
	var entries := BuffSources.for_tower(target)
	var stumps := entries.filter(func(e: Dictionary) -> bool: return e.kind == "elder_stump")
	_check(stumps.size() == 2 and stumps.map(func(e: Dictionary) -> int: return e.position).has(2),
		"two Elder Stumps, the second one in falloff (%s)" % [stumps.map(func(e: Dictionary) -> String: return e.label)])
	_check(entries.any(func(e: Dictionary) -> bool: return e.kind == "acorn" and e.stat == "damage" and e.source == acorn),
		"the Acorn's damage aura is listed")
	var pips := BuffSources.pips(target)
	_check(pips.size() == 2 and pips.any(func(p: Array) -> bool: return p[0] == "elder_stump" and p[1] == 2),
		"pips: Elder Stump ×2 and Acorn (%s)" % [pips.map(func(p: Array) -> String: return "%s×%d" % [p[0], p[1]])])
	var given := BuffSources.given_by(first)
	_check(given.any(func(g: Dictionary) -> bool: return g.target == target and g.speed > 0.0),
		"the first Elder Stump says it boosts the Sporeling")
	var summary := BuffSources.summary(BuffSources.would_receive(load("res://resource/tower/sporeling.tres"),
		target.global_position, [first, second, acorn]))
	_check(summary.contains("from 2 Elder Stumps") and summary.contains("from an Acorn"),
		"the placement preview: %s" % summary)
	second.rank = 1
	second.rank_choices = [Tower.Focus.KINDRED]  # A Kindred rank (Nurture v3)
	target._refresh_neighbours()
	_check(BuffSources.for_tower(target).any(func(e: Dictionary) -> bool: return e.kindred and BuffSources.thread_label(e).begins_with("Kindred")),
		"a Kindred stump's thread reads \"Kindred +…\"")

	# The overlay: made by TowerSeller, the lens toggles on V.
	var overlay := BuffOverlay.find(main)
	_check(overlay != null, "the run has a BuffOverlay")
	if overlay:
		BuffLens.set_on(self, true)
		_check(overlay.lens, "the lens (Main's BuffLens, V) reaches the overlay")
		# Visible on and off (Main, user: "toggling Boosts doesn't change anything"): pips and markers draw above
		# the Wardens, only the aura tint on the ground; the lens adds halos over boosted Wardens.
		_check(overlay.z_index > 0 and overlay.get_node("LensGround").z_index < 0, "pips and markers above the Wardens, the tint on the ground")
		overlay.queue_redraw()
		await process_frame
		await process_frame
		var markers_on: int = overlay.drawn_markers
		BuffLens.set_on(self, false)
		await process_frame
		await process_frame
		_check(markers_on >= 1 and overlay.drawn_markers == 0, "the lens adds halos over boosted Wardens and removes them (%d → %d)" % [markers_on, overlay.drawn_markers])

	# The Warden panel's Buffs section.
	seller.select(target)
	await process_frame
	await process_frame
	var buffs: VBoxContainer = panel._buffs
	# Folded by default (screens_ui.md "The Warden panel never fills the screen"): header + Total + Details.
	var folded: Array = buffs.find_children("*", "", true, false).map(func(c: Node) -> String: return c.text if "text" in c else "")
	_check(folded.any(func(t: String) -> bool: return t.begins_with("Total:")) and folded.any(func(t: String) -> bool: return t.begins_with("Details"))
		and not folded.any(func(t: String) -> bool: return t.begins_with("Elder Stump")), "Buffs fold to the Total line with a Details toggle (%s)" % [folded])
	panel._buffs_open = true
	panel._fill_buffs(target)
	var texts: Array = buffs.find_children("*", "", true, false).map(func(c: Node) -> String: return c.text if "text" in c else "")
	_check(buffs.visible and texts.any(func(t: String) -> bool: return t.to_lower() == "buffs") and texts.any(func(t: String) -> bool: return t.begins_with("Total:")),
		"the panel lists the buffs and a total (%s)" % [texts])
	_check(buffs.get_children().any(func(c: Control) -> bool: return c is Button and c.text.begins_with("Elder Stump")),
		"a Warden source is a button")
	# Stat tips (story chat 2026-10-01): one tip per stat (icon + value), saying what it means for this Warden.
	var stat_tips: Array = panel._stats.find_children("*", "TapTip", true, false).map(func(t: TapTip) -> String: return t._label.text)
	var speed_tip: String = stat_tips.filter(func(t: String) -> bool: return t.begins_with("Attack speed:")).front() if stat_tips.any(func(t: String) -> bool: return t.begins_with("Attack speed:")) else ""
	_check(stat_tips.any(func(t: String) -> bool: return t.begins_with("Damage: ") and t.contains("per hit"))
		and speed_tip.contains("attacks a second") and speed_tip.contains("Elder Stump +")
		and stat_tips.any(func(t: String) -> bool: return t.begins_with("Range: ") and t.contains("cells")),
		"each stat's tip says its value and what changed it (%s)" % [stat_tips])
	var speed_targets: Array = panel._stats.find_children("*", "TapTip", true, false).filter(func(t: TapTip) -> bool: return t._label.text.begins_with("Attack speed:"))
	_check(speed_targets.size() == 1 and speed_targets[0].get_parent().get_child_count() == 3,
		"the speed tip belongs to its own icon + value (one target, not the row)")
	# Never more than MAX_SHARE of the screen; Sell and Close in the footer.
	root.size = Vector2i(1280, 800)
	await process_frame
	panel._body.text = "\n".join(range(40).map(func(i: int) -> String: return "A long note %d" % i))  # A long info part (it scrolls)
	panel._fit_height()
	await process_frame
	var screen: float = panel.get_viewport().get_visible_rect().size.y
	# The info part gives way (it scrolls, down to MIN_INFO); the actions never do (test_panel_fits: every action on
	# screen), so a Warden with many forms (a base growing into 6 on Spire's branch expansion) may need more.
	var floor_height: float = panel._buttons.get_combined_minimum_size().y + panel._footer.get_combined_minimum_size().y + 40.0 + panel.MIN_INFO
	var limit := maxf(screen * panel.MAX_SHARE, floor_height)
	_check(panel.size.y <= limit + 1.0, "the panel stays within %d%% of the screen, or just its actions + the least info (%.0f of %.0f px)" % [
		roundi(panel.MAX_SHARE * 100), panel.size.y, limit])
	_check(panel._scroll.size.y <= panel.MIN_INFO + 1.0 or panel.size.y <= screen * panel.MAX_SHARE + 1.0, "…the long info part is the one that gave way")
	_check(panel._footer.get_children().any(func(c: Node) -> bool: return c is Button and c.text.begins_with("Sell"))
		and panel._footer.get_children().any(func(c: Node) -> bool: return c is Button and c.text == "Close"), "Sell and Close stay in the footer")

	# The Boosts button (screens_ui.md "The lens button, revised"): shown once there's a local source; only
	# local sources light a Warden up; the legend lists the kinds on the map.
	_check(BuffOverlay.has_local_sources(main), "the map has a local buff source (Elder Stumps, an Acorn)")
	_check(BuffOverlay.local_boost(target) > 0.0, "the boosted Sporeling lights up")
	var lone := _plant("firefly_jar", Vector2(20, 2))
	lone._refresh_neighbours()
	_check(is_zero_approx(BuffOverlay.local_boost(lone)), "a Warden with no local source doesn't (Dreams and Nurture don't count)")
	var legend: Array = BuffOverlay.legend_kinds(main).map(func(row: Array) -> String: return row[2])
	_check(legend.has("Elder Stump") and legend.has("Acorn"), "the legend lists the source kinds on the map (%s)" % [legend])

	# Thread chips (user screenshot: labels piling up, "(…nd)"): short, never an ordinal, one per Warden.
	_check(BuffOverlay.chip_text(0.15, 0.0, false) == "+15% dmg" and BuffOverlay.chip_text(0.0, 0.3, false) == "+30% speed"
		and BuffOverlay.chip_text(0.15, 0.1, true) == "Kindred +15% dmg · +10% speed", "chips are short: \"+15% dmg\", \"+30% speed\"")
	print("buff sources test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _plant(id: String, cell: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = cell
	tower.position = cell * CELL + Vector2(CELL, CELL) / 2
	container.add_child(tower)
	tower.set_process(false)
	return tower

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
