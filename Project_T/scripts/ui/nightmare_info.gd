extends PanelContainer

# Right-hand panel for the hovered nightmare (screens_ui.md "Nightmare info"): name, one-line trait,
# health, speed, leaf cost and its statuses with time left. Follows the most recently hovered one
# and hides when it's gone. A nightmare type never met before gets a "New" tag (remembered in
# HeartwoodMemory, by the real game only). Built in code.

const HOVER_RADIUS := 30.0  # Pixels (world) around a nightmare that count as hovering it

var _target: Node2D = null
var _known := {}  # Nightmare kinds met before this run (for the "New" tag)
var _saved := {}  # Kinds already written to the profile (so the file is touched once per kind)
var _title := Label.new()
var _body := StatusLinks.make_label("", 15)  # Status names are links (hover / tap)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(240, 0)
	var box := VBoxContainer.new()
	add_child(box)
	_title.add_theme_font_size_override("font_size", 18)
	box.add_child(_title)
	_body.custom_minimum_size = Vector2(220, 0)
	box.add_child(_body)
	visible = false
	for kind in HeartwoodMemory.load_data().get("nightmares_seen", []):
		_known[kind] = true
	_saved = _known.duplicate()
	var spawner = %EnemyContainer
	spawner.child_entered_tree.connect(_on_spawned)

func _process(_delta: float) -> void:
	var hovered := _hovered_nightmare()
	if hovered != null:
		_target = hovered
	if not is_instance_valid(_target) or _target.is_cleansed:
		_target = null
		visible = false
		return
	visible = true
	var data: EnemyData = _target.enemy_data
	var kind := _kind(data)
	_title.text = data.display_name + ("   · New" if not _known.has(kind) else "")
	if _target.elite:
		_title.text += "   · Deeply Blighted"
	var lines: Array[String] = []
	if data.trait_text != "":
		lines.append(data.trait_text)
	lines.append("Health %d / %d" % [_target.health, _target.max_health])
	lines.append("Speed %.1f tiles/s   Leaves %d" % [_target.get_move_speed() / 64.0, _target.get_leaf_cost()])
	var statuses: Array[String] = []
	for id in _target.statuses.active_ids():
		var stacks: int = _target.statuses.stacks(id)
		statuses.append("%s%s %.0fs" % [IconInfo.status_name(id), " ×%d" % stacks if stacks > 1 else "",
			_target.statuses.time_left(id)])
	if not statuses.is_empty():
		lines.append(", ".join(statuses))
	# The Nightshade Legendary: +20% effect damage per status it carries (Reactions.nightshade_bonus).
	var nightshade := Reactions.nightshade_bonus(_target)
	if nightshade > 0.0:
		lines.append("Nightshade +%d%% effect damage" % roundi(nightshade * 100.0))
	var body := StatusLinks.bbcode("\n".join(lines))
	if body != _body.text:  # Only on change, so a link's hover isn't reset every frame
		_body.text = body

func _hovered_nightmare() -> Node2D:
	var mouse: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
	var best: Node2D = null
	var best_distance := HOVER_RADIUS
	for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
		var distance: float = enemy.global_position.distance_to(mouse)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best

func _on_spawned(node: Node) -> void:
	if node.get("enemy_data") == null:
		return
	var kind := _kind(node.enemy_data)
	if _saved.has(kind):
		return
	_saved[kind] = true
	# Remember the kind for future runs (this run keeps showing "New" for it). Real game only.
	if get_tree().current_scene != owner or MetaRun.is_dev_run():
		return
	var memory := HeartwoodMemory.load_data()
	var seen: Array = memory.get("nightmares_seen", [])
	if not seen.has(kind):
		seen.append(kind)
		memory["nightmares_seen"] = seen
		HeartwoodMemory.save_data(memory)

static func _kind(data: EnemyData) -> String:
	return data.resource_path.get_file().get_basename()
