extends PanelContainer

# Right-hand panel for the hovered nightmare (screens_ui.md "Nightmare info"): name, one-line trait,
# health, speed, leaf cost and its statuses with time left, then its Resists / Weak to / Immune /
# Traits icon rows (NightmareIcons; each icon explains itself on hover and tap). Follows the most recently hovered one
# and hides when it's gone. A nightmare type never met before gets a "New" tag (remembered in
# HeartwoodMemory, by the real game only). Built in code.

const HOVER_RADIUS := 30.0  # Pixels (world) around a nightmare that count as hovering it

var _target: Node2D = null
var _known := {}  # Nightmare kinds met before this run (for the "New" tag)
var _saved := {}  # Kinds already written to the profile (so the file is touched once per kind)
var _title := Label.new()
var _body := StatusLinks.make_label("", 15)  # Status names are links (hover / tap)
var _rows_box := VBoxContainer.new()  # Resists / Weak to / Immune / Traits icons (NightmareIcons)
var _rows_for: EnemyData = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(UiStyle.TIP_WIDTH + 20.0, 0)  # Tip sizes (screens_ui.md playtest fixes 2026-09-30)
	var box := VBoxContainer.new()
	add_child(box)
	UiStyle.tip_name(_title)
	box.add_child(_title)
	_numbers.add_theme_font_size_override("font_size", UiStyle.TIP_SIZE)
	box.add_child(_numbers)
	UiStyle.tip_body(_body)
	box.add_child(_body)
	box.add_child(_rows_box)
	visible = false
	for kind in HeartwoodMemory.load_data().get("nightmares_seen", []):
		_known[kind] = true
	_saved = _known.duplicate()
	var spawner = %EnemyContainer
	spawner.child_entered_tree.connect(_on_spawned)

# Hover tips stay until the pointer leaves their target (screens_ui.md "Hover and tap tips"): the
# panel keeps its nightmare while other nightmares are dispelled around it; when its own nightmare
# is dispelled it reads "Dispelled" for DISPELLED_TIME and clears, and never jumps to a neighbour
# until the pointer moves. Changing numbers update in place (a plain label); the status-link text is
# left alone while the pointer is on it or its popup is open.
const DISPELLED_TIME := 1.0
const MOVE_EPSILON := 3.0  # Screen px the pointer must move before the panel picks a new nightmare

var _dispelled_left := 0.0
var _last_mouse := Vector2(-1000, -1000)
var _numbers := Label.new()
var _await_move := false  # Cleared after a dispel: the next nightmare needs a pointer move

func _process(delta: float) -> void:
	var mouse := get_viewport().get_mouse_position()
	var moved := mouse.distance_to(_last_mouse) > MOVE_EPSILON
	_last_mouse = mouse
	var target_gone: bool = not is_instance_valid(_target) or _target.is_cleansed
	if target_gone and _target != null and _dispelled_left <= 0.0 and visible:
		_dispelled_left = DISPELLED_TIME  # Its nightmare was just dispelled: say so, then clear
		_title.text += " · Dispelled"
	if _dispelled_left > 0.0:
		_dispelled_left -= delta / maxf(Engine.time_scale, 0.001)
		if _dispelled_left > 0.0 and not moved:
			return
		_dispelled_left = 0.0
		_target = null
		_await_move = true
	var hovered := _hovered_nightmare()
	if moved:
		_await_move = false
	if hovered != null and not _await_move and (hovered == _target or _target == null or moved):
		_target = hovered
	if not is_instance_valid(_target) or _target.is_cleansed:
		_target = null
		visible = false
		return
	visible = true
	var data: EnemyData = _target.enemy_data
	var kind := _kind(data)
	_title.text = data.display_name + (" · New" if not _known.has(kind) else "")
	if _target.elite:
		_title.text += " · Deeply Blighted"
	# Numbers: a plain label, rewritten freely.
	var numbers: Array[String] = ["Health %d / %d" % [_target.health, _target.max_health],
		"Speed %.1f cells/s   Leaves %d" % [_target.get_move_speed() / 64.0, _target.get_leaf_cost()]]
	var restless := restless_text(_target)
	if restless != "":
		numbers.append(restless)
	# The Nightshade Legendary: +20% effect damage per status it carries (Reactions.nightshade_bonus).
	var nightshade := Reactions.nightshade_bonus(_target)
	if nightshade > 0.0:
		numbers.append("Nightshade +%d%% effect damage" % roundi(nightshade * 100.0))
	var numbers_text := "\n".join(numbers)
	if numbers_text != _numbers.text:
		_numbers.text = numbers_text
	# Words with status links: the trait, the Omen, the statuses ("Charged 4/5 · 2.1 s").
	var lines: Array[String] = []
	if data.trait_text != "":
		lines.append(data.trait_text)
	var omen_line := omen_text(_target)
	if omen_line != "":
		lines.append(omen_line)
	var statuses: Array[String] = []
	for id in _target.get_status_order():  # The badge row's order, most important first
		statuses.append(_target.statuses.describe(id))
	if _target.has_method("get_status_notes"):  # Slow / sleep limits: "Slowed to the limit", "Awake: …"
		statuses.append_array(_target.get_status_notes())
	if not statuses.is_empty():
		lines.append("\n".join(statuses))
	var body := StatusLinks.bbcode("\n".join(lines))
	if body != _body.text and not _body_in_use():
		_body.text = body
	if data != _rows_for:  # The icon rows (resists, weak to, immune, traits): rebuilt per kind
		_rows_for = data
		for child in _rows_box.get_children():
			child.queue_free()
		_rows_box.add_child(NightmareIcons.make_rows(data, 26.0))

# The pointer is on the status-link text, or one of its popups is open: don't rewrite it now.
func _body_in_use() -> bool:
	if _body.get_global_rect().has_point(_body.get_global_mouse_position()):
		return true
	return _body.get_children().any(func(c: Node) -> bool: return c is StatusLinks and c.visible)

# What the drift's Omen gives this nightmare beyond its kind (get_defences doesn't know them):
# "Omen Sleepless: immune to Drowsy, Rooted · always Soaked". "" when nothing.
static func omen_text(enemy: Node) -> String:
	var parts: Array[String] = []
	var data: EnemyData = enemy.enemy_data
	var extra_immune: Array[String] = []
	for id in enemy.statuses.immune:
		if not data.status_immune.has(id):
			extra_immune.append(IconInfo.status_name(id))
	if not extra_immune.is_empty():
		parts.append("immune to " + ", ".join(extra_immune))
	var always: StringName = enemy.get("modifiers").get("always_status", &"") if enemy.get("modifiers") is Dictionary else &""
	if always != &"":
		parts.append("always " + IconInfo.status_name(always))
	if parts.is_empty():
		return ""
	var omens := enemy.get_tree().get_first_node_in_group(OmenDirector.GROUP) as OmenDirector
	var omen: OmenData = omens.current() if omens != null and omens.has_method("current") else null
	return "%s: %s" % ["Omen " + omen.display_name if omen != null else "Omen", " · ".join(parts)]

# No maze juggling (run_design.md): "Restless ×2: +40% speed (Unbound at 3)" or "Unbound: ignores
# the maze, tramples Wardens on its route" (Enemy Code's get_restless_info); "" when calm.
static func restless_text(enemy: Node) -> String:
	if not enemy.has_method("get_restless_info"):
		return ""
	var info: Dictionary = enemy.get_restless_info()
	if info.get("unbound", false):
		return "Unbound: ignores the maze, tramples Wardens on its route"
	var stacks := int(info.get("stacks", 0))
	if stacks <= 0:
		return ""
	var text := "Restless ×%d: +%d%% speed" % [stacks, roundi(float(info.get("speed_bonus", 0.0)) * 100.0)]
	if info.get("can_unbind", true):
		text += " (Unbound at %d)" % int(info.get("unbound_at", 3))
	return text

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
	# Remember the kind for future runs (this run keeps showing "New" for it). Real game only, dev runs
	# included (screens_ui.md playtest fixes: "New" = never seen on this profile, dev runs alike).
	if get_tree().current_scene != owner:
		return
	var memory := HeartwoodMemory.load_data()
	var seen: Array = memory.get("nightmares_seen", [])
	if not seen.has(kind):
		seen.append(kind)
		memory["nightmares_seen"] = seen
		HeartwoodMemory.save_data(memory)

static func _kind(data: EnemyData) -> String:
	return data.resource_path.get_file().get_basename()
