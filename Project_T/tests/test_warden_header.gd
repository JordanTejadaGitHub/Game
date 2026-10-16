extends SceneTree

# Headless test for WardenHeaderView (screens_ui.md, the bullets above "Readable tooltips"): the Warden
# panel's top half as one shared view. build(data) shows an unplanted Warden (base + this run's Dreams,
# "Grows into"); build(data, tower) matches the panel. Run from the project folder:
#   godot --headless --path . --script res://tests/test_warden_header.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	var dreams: DreamState = main.get_node("%DreamState")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var panel: Node = main.find_child("WardenPanel", true, false)
	dreams.unlock_everything = true
	var driftspore: TowerData = load("res://resource/tower/driftspore.tres")

	# Unplanted: the base numbers, its damage type, and what it grows into.
	var view := WardenHeaderView.build(driftspore, null, dreams)
	main.get_node("HUD").add_child(view)
	await process_frame
	_check(view.title.text == driftspore.display_name, "the name (%s)" % view.title.text)
	_check((view.damage_type.get_child(0) as Label).text == " · ".join(WardenHeaderView.role_tags(driftspore)) and view.damage_type.visible == (not WardenHeaderView.role_tags(driftspore).is_empty()), "the role tags under the name (%s)" % (view.damage_type.get_child(0) as Label).text)
	var texts := _texts(view.stats)
	# One icon row, values only (light pass): each value is named Value_<stat id>.
	var damage_value := view.stats.find_child("Value_damage", true, false) as Label
	_check(damage_value != null and damage_value.text == BossDossier.thousands(roundi(driftspore.damage)), "base damage rounds to %d (%s)" % [roundi(driftspore.damage), texts])
	_check(view.stats.find_child("Value_%s" % driftspore.applies_status, true, false) != null, "the status it applies, in the same row (%s)" % [texts])
	var grows := _texts(view.growth)
	_check(view.growth.visible and grows.any(func(t: String) -> bool: return t.to_lower() == "grows into") and grows.any(func(t: String) -> bool: return t.contains(UiStyle.DEW_GLYPH)),
		"Grows into, with the Dew (%s)" % [grows])
	_check(view.find_children("*", "Button", true, false).is_empty(), "no buttons")
	view.queue_free()

	# Groundroot's grab reach beside its range (Tower Code e530a46a: the panel's range read as its reach).
	var groundroot: TowerData = load("res://resource/tower/groundroot.tres")
	var rooted: Tower = placer.tower_scene.instantiate()
	rooted.tower_data = groundroot
	rooted.cell = Vector2(2, 2)
	placer.tower_container.add_child(rooted)
	rooted.set_process(false)
	var grab_view := WardenHeaderView.build(groundroot, rooted, dreams)
	main.get_node("HUD").add_child(grab_view)
	await process_frame
	var grab := grab_view.stats.find_child("Value_grab_reach", true, false) as Label
	_check(grab != null and grab.text == "Grab range %.1f" % BranchKit.ability_reach(rooted) and BranchKit.ability_reach(rooted) > rooted.get_range_cells(),
		"Groundroot shows its grab reach beside its range (%s)" % (grab.text if grab else "none"))
	# The attack shape chip (user: "can't tell if something is an aura attack or not"; Tower.attack_shape).
	# UI Asset's shape icons (54cc7cfb): an icon-only chip in the first row, the name in its tip.
	var shape_id := "shape_" + String(Tower.attack_shape(groundroot))
	var shape := grab_view.stats.find_child("Value_" + shape_id, true, false) as Label
	_check(IconInfo.icon(StringName(shape_id)) != null and shape != null and shape.text == "",
		"the attack shape chip is its icon (%s)" % shape_id)
	_check(WardenHeaderView.shape_tip(load("res://resource/tower/acorn.tres")).length() > 10
		and WardenHeaderView.shape_tip(load("res://resource/tower/thornwall.tres")).begins_with("No attack"),
		"shape tips: %s / %s" % [WardenHeaderView.shape_tip(load("res://resource/tower/acorn.tres")),
			WardenHeaderView.shape_tip(load("res://resource/tower/thornwall.tres"))])
	grab_view.queue_free()
	rooted.queue_free()

	# A run-wide damage Dream shows on the unplanted card too.
	var boost: UpgradeData = null
	for card in dreams.pool:
		if card.soothe_bonus > 0.0 and dreams._applies_to(card, driftspore):
			boost = card
			break
	if boost != null:
		dreams.take(boost)
		var boosted := WardenHeaderView.build(driftspore, null, dreams)
		main.get_node("HUD").add_child(boosted)
		await process_frame
		var damage_line: String = (boosted.stats.find_child("Value_damage", true, false) as Label).text
		_check(damage_line != BossDossier.thousands(roundi(driftspore.damage)), "%s shows in the unplanted card (%s)" % [boost.id, damage_line])
		boosted.queue_free()

	# Planted: the panel is built from the same view.
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = driftspore
	tower.cell = Vector2(12, 12)
	tower.position = Vector2(12, 12) * 64.0 + Vector2(32, 32)
	main.get_node("%TowerContainer").add_child(tower)
	seller.select(tower)
	await process_frame
	await process_frame
	_check(panel._header is WardenHeaderView and panel._header.title.text.begins_with(driftspore.display_name), "the panel's header is the shared view")
	_check(not panel._header.growth.visible, "the panel keeps its Grow buttons instead of the Grows into list")
	var planted := WardenHeaderView.build(driftspore, tower, dreams)
	main.get_node("HUD").add_child(planted)
	await process_frame
	_check(_texts(planted.stats).slice(0, 3) == _texts(panel._stats).slice(0, 3), "a planted card matches the panel (%s)" % [_texts(planted.stats).slice(0, 3)])

	# Potency says what it does on this Warden (user, 2026-10-07), and is hidden where it does nothing.
	var rootling: TowerData = load("res://resource/tower/rootling.tres")
	var rootling_uses := Tower.potency_uses(rootling)
	var rootling_tip := WardenHeaderView.potency_tip(rootling.potency, rootling_uses)
	_check(not rootling_uses.is_empty() and rootling_tip.begins_with("Potency 1") and rootling_tip.contains("\nOn this Warden: ")
		and not rootling_tip.contains("{") and rootling_tip.ends_with("Higher Potency strengthens its statuses and effects."),
		"Rootling's Potency tip says what it does there (%s)" % rootling_tip.replace("\n", " / "))
	var wall := WardenHeaderView.build(load("res://resource/tower/thornwall.tres"), null, null)
	main.get_node("HUD").add_child(wall)
	await process_frame
	_check(Tower.potency_uses(load("res://resource/tower/thornwall.tres")).is_empty() and not _texts(wall.stats).any(func(t: String) -> bool: return t.begins_with("Potency")),
		"a wall shows no Potency (%s)" % [_texts(wall.stats)])

	var well: Tower = placer.tower_scene.instantiate()
	well.tower_data = load("res://resource/tower/wellspring.tres")
	well.cell = Vector2(40, 40)
	main.get_node("%TowerContainer").add_child(well)
	well.rank = 5
	well.rank_choices.assign([Tower.Focus.STRONG, Tower.Focus.STRONG, Tower.Focus.STRONG, Tower.Focus.STRONG, Tower.Focus.WIDE])
	well._stats.clear()
	var economy := WardenHeaderView.build(well.tower_data, well, dreams, false)
	main.get_node("HUD").add_child(economy)
	await process_frame
	var economy_text := " ".join(_texts(economy.stats))
	_check(economy_text.contains("Catch +197%") and economy_text.contains("Interest") and economy_text.contains("cap"), "catch and interest show live nurture/mastery values: " + economy_text)
	well.bowl = 12.5
	await process_frame
	_check(" ".join(_texts(economy.stats)).contains("Caught 12.5 Dew"), "catcher bowl refreshes while the panel is open")

	print("warden header test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _texts(node: Node) -> Array:
	var out := []
	for child in node.find_children("*", "Label", true, false):
		if not child.is_queued_for_deletion():
			out.append(child.text)
	return out

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
