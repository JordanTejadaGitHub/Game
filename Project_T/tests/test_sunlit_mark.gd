extends SceneTree

# Headless test for Sunlit Rest's markers (story chat, user: "should have an icon of which Warden would get the free
# Nurture upgrade"): the Warden the next rest gives a free rank carries the card badge (a positional row, "Next Sunlit
# Rest rank" in its panel), the SunlitMark sun sits on it and moves when a nearer Warden is planted, and the rest
# toasts who got the rank.
#   godot --headless --path . --script res://tests/test_sunlit_mark.gd --fixed-fps 60

var failures := 0
var main: Node
var dreams: DreamState

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	await process_frame
	dreams = main.get_node("%DreamState")
	var mark := main.get_node_or_null("SunlitMark")
	_check(mark != null, "DreamState adds the SunlitMark to the run's scene")

	var map := main.get_node("%MapGenerator")
	var path: PackedVector2Array = Tower.route_cells(map.get_path_from(map.startPath))
	var far := _plant_at("sporeling", _beside(path, 5))
	await _poll()
	_check(mark.get_targets().is_empty(), "no sun without the card")
	_check(_sunlit_row(far).is_empty(), "…and no Sunlit row")

	dreams.take(_card("sunlit_rest"))
	dreams.bump_board()
	await _poll()
	_check(mark.get_targets() == [far], "with the card, the sun sits on the only Warden (%s)" % [mark.get_targets()])
	var row := _sunlit_row(far)
	_check(not row.is_empty() and row.positional and row.active and row.effect == "Next Sunlit Rest Nurture rank",
		"its row is positional (the badge) and says so in the panel (%s)" % [row])
	Tower.set_badges_visible(&"test", true)
	far._refresh_badge()
	_check(far.get_badge_cards().any(func(r: Dictionary) -> bool: return r.id == "sunlit_rest"), "…and it shows the card badge")
	Tower.set_badges_visible(&"test", false)

	var near := _plant_at("sporeling", _beside(path, path.size() - 4))
	dreams.bump_board()
	await _poll()
	_check(mark.get_targets() == [near], "planting nearer the Heartwood moves the sun (%s)" % [mark.get_targets()])
	_check(_sunlit_row(far).is_empty() and not _sunlit_row(near).is_empty(), "…and the row with it")

	var raised := dreams.sunlit_rest()
	var toast: String = main.get_node("%ToastLabel").text
	_check(raised == [near] and near.banked_ranks == 1 and near.rank == 0 and toast == "Sunlit Rest: a free Nurture rank waits on %s." % near.tower_data.display_name,
		"the rest toasts who got the rank (%s)" % toast)

	near.free()
	dreams.bump_board()
	await _poll()
	_check(mark.get_targets() == [far], "selling it hands the sun back (%s)" % [mark.get_targets()])

	print("sunlit mark test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _poll() -> void:
	for i in 20:  # SunlitMark looks every 0.25 s
		await process_frame

func _sunlit_row(tower: Tower) -> Dictionary:
	for row in dreams.effects().rows(DreamEffects.spot_for(tower)):
		if row.id == "sunlit_rest":
			return row
	return {}

func _card(id: String) -> UpgradeData:
	for card in dreams.pool:
		if card.id == id:
			return card
	_check(false, "card %s exists" % id)
	return null

func _plant_at(id: String, cell: Vector2) -> Tower:
	var tower: Tower = load("res://scenes/tower/tower.tscn").instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = cell
	tower.position = tower.MAP_GRID.calculate_map_position(cell)
	main.get_node("%TowerContainer").add_child(tower)
	tower.set_process(false)
	return tower

# A cell next to path[i] that isn't on the path.
func _beside(path: PackedVector2Array, i: int) -> Vector2:
	for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		if not path.has(path[i] + offset):
			return path[i] + offset
	return path[i] + Vector2(2, 0)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
