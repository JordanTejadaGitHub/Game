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
	_check((view.damage_type.get_child(0) as Label).text == IconInfo.damage_type_text(driftspore.line), "the damage type as text")
	var texts := _texts(view.stats)
	# One icon row, values only (light pass): each value is named Value_<stat id>.
	var damage_value := view.stats.find_child("Value_damage", true, false) as Label
	_check(damage_value != null and damage_value.text == str(driftspore.damage), "base damage %d (%s)" % [driftspore.damage, texts])
	_check(view.stats.find_child("Value_%s" % driftspore.applies_status, true, false) != null, "the status it applies, in the same row (%s)" % [texts])
	var grows := _texts(view.growth)
	_check(view.growth.visible and grows.any(func(t: String) -> bool: return t.to_lower() == "grows into") and grows.any(func(t: String) -> bool: return t.contains("Dew")),
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
	_check(grab != null and grab.text == "Grab %.1f" % BranchKit.ability_reach(rooted) and BranchKit.ability_reach(rooted) > rooted.get_range_cells(),
		"Groundroot shows its grab reach beside its range (%s)" % (grab.text if grab else "none"))
	# The attack shape chip (user: "can't tell if something is an aura attack or not"; Tower.attack_shape).
	var shape := grab_view.stats.find_child("Value_attack_shape", true, false) as Label
	_check(shape != null and shape.text == WardenHeaderView.shape_name(groundroot) and shape.text != "",
		"the attack shape chip (%s)" % (shape.text if shape else "none"))
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
		_check(damage_line != str(driftspore.damage), "%s shows in the unplanted card (%s)" % [boost.id, damage_line])
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
