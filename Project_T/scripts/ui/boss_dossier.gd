extends Control
class_name BossDossier

# The boss dossier (screens_ui.md "Boss dossier", added 2026-09-28): at the rest that opens a boss
# block (after drifts 20 / 45 / 70 / 95), last in the rest order (after the family pick, Dream and
# Omen), a card for the coming boss:
#   header    animated portrait, name · title, a whisper line, "Arrives in drift N", "New"
#   numbers   real health (this run's scaling, Blight, Dreams), speed, leaves it takes
#   defences  the Resists / Weak to / Immune rows, larger (NightmareIcons)
#   abilities icon, name, what it does, WHEN (EnemyData.get_ability: numbers filled from the data)
#   it brings summons (EnemyData.get_summons) + the boss drift's escorts
#   what helps EnemyData.tips; your record (times dispelled, best time; profile "boss_records")
# Reopen any time from the drift banner's "Boss in N" or the boss portrait in Coming this block
# (BossDossier.open_for). Opened during a drift it pauses until closed. Made by the HUD.

const GROUP := &"boss_dossier"
const RECORDS_KEY := "boss_records"  # Profile: {kind: {"dispelled": n, "best": seconds}}
const WIDTH := 600.0
const BOSS_COLOR := UiStyle.BOSS  # Heartwood 32 (ui_style.md)
const TITLE_COLOR := Color(1.0, 0.85, 0.75)
const WHISPER_COLOR := Color(0.75, 0.9, 0.8)
const SECTION_COLOR := Color(0.95, 0.8, 0.55)
const DEFAULT_WHISPER := "Something old has found the dream."
const OPEN_DELAY := 0.35  # Seconds after the rest starts before checking the rest's screens

var drift_director: DriftDirector
var shown_drift := 0  # The boss drift on the card (0 = closed)
var _auto_shown := {}  # Boss drift -> true once shown by itself
var _pending := 0  # Boss drift waiting to show itself once the rest's screens are done
var _wait := 0.0
var _paused_it := false
var _panel := PanelContainer.new()
var _content := VBoxContainer.new()
var _scroll := ScrollContainer.new()
var _boss_time := {}  # Boss enemy instance id -> game seconds alive (for "best time")

# Opens the dossier for boss drift `drift` (0 = the next / current boss).
static func open_for(tree: SceneTree, drift: int = 0) -> void:
	var dossier := tree.get_first_node_in_group(GROUP) as BossDossier
	if dossier != null:
		dossier.open(drift)

func _init(director: DriftDirector = null) -> void:
	drift_director = director

func _ready() -> void:
	add_to_group(GROUP)
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Offsets too: exactly the screen
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.05, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Offsets too: exactly the screen
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Offsets too: exactly the screen
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	var frame := UiStyle.panel_in(BOSS_COLOR.darkened(0.2), 16.0, 16.0)
	frame.center_alpha = 0.95  # Over the whole field: nearly solid
	frame.edge_alpha = 0.9
	_panel.add_theme_stylebox_override("panel", frame)
	centre.add_child(_panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	_panel.add_child(outer)
	# The card scrolls on small screens (screens_ui.md "Touch").
	_scroll.custom_minimum_size = Vector2(WIDTH, 0)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(_scroll)
	_content.custom_minimum_size = Vector2(WIDTH - 16, 0)
	_content.add_theme_constant_override("separation", 10)
	_scroll.add_child(_content)
	var close := Button.new()
	close.text = "Prepare"
	close.tooltip_text = "Close the dossier. Reopen it from \"Boss in N\" at the top."
	close.custom_minimum_size = Vector2(200, 44)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(close_dossier)
	outer.add_child(close)
	if drift_director != null:
		drift_director.rest_started.connect(_on_rest_started)
	var spawner := drift_director.get_node_or_null("%EnemyContainer") if drift_director != null else null
	if spawner != null:
		spawner.child_entered_tree.connect(_on_spawned)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("cancel_build"):
		close_dossier()
		get_viewport().set_input_as_handled()

# --- When it shows -------------------------------------------------------------------------------

# The boss drift in block `block`, or 0.
func boss_drift_in_block(block: int) -> int:
	var first := (block - 1) * drift_director.drifts_per_block + 1
	for number in range(first, mini(first + drift_director.drifts_per_block, drift_director.get_total_drifts() + 1)):
		if drift_director.is_boss_drift(number):
			return number
	return 0

func _on_rest_started(block: int, _boss_rest: bool, _bonus: int, _perfect: bool) -> void:
	var boss := boss_drift_in_block(block + 1)
	if boss > 0 and not _auto_shown.has(boss) and boss_data(boss) != null:
		_pending = boss
		_wait = OPEN_DELAY

# The rest's other screens (family pick, Dream, Omen, pause menu, results) are all done.
func screens_clear() -> bool:
	for path in ["HUD/FamilyPickScreen", "HUD/DreamScreen", "HUD/OmenScreen", "HUD/RememberScreen", "HUD/PauseMenu", "HUD/ResultsScreen"]:
		var screen := drift_director.owner.get_node_or_null(path) as CanvasItem if drift_director.owner != null else null
		if screen != null and screen.visible:
			return false
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	if dreams != null and (dreams.is_offering() or dreams.has_pending_offer()):
		return false
	var omens := get_tree().get_first_node_in_group(OmenDirector.GROUP) as OmenDirector
	if omens != null and omens.is_offering():
		return false
	var intro := get_tree().get_first_node_in_group(NightmareIntro.GROUP) as NightmareIntro
	if intro != null and intro.is_busy():
		return false  # New nightmares are introduced before the boss dossier
	return not drift_director.awaiting_family_pick

func _process(delta: float) -> void:
	if not get_tree().paused:  # Game seconds each live boss has been walking (its record's time)
		for id in _boss_time:
			_boss_time[id] += delta
	if _pending == 0:
		return
	if not drift_director.is_resting():
		_pending = 0  # The block started without it (Start pressed in the meantime)
		return
	_wait -= delta / maxf(Engine.time_scale, 0.001)
	if _wait <= 0.0 and screens_clear():
		_auto_shown[_pending] = true
		open(_pending)
		_pending = 0

# --- Open / close ----------------------------------------------------------------------------------

# The next boss drift not dispelled yet (the one walking now counts until it's dispelled), or 0.
func next_boss_drift() -> int:
	var started := drift_director.drifts_started
	for number in range(maxi(started, 1), drift_director.get_total_drifts() + 1):
		if drift_director.is_boss_drift(number) and (number > started or _boss_alive()):
			return number
	return 0

func _boss_alive() -> bool:
	for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
		if enemy.get("enemy_data") != null and enemy.enemy_data.is_boss and not enemy.is_cleansed:
			return true
	return false

func can_open() -> bool:
	return next_boss_drift() > 0

func open(drift: int = 0) -> void:
	if drift <= 0:
		drift = next_boss_drift()
	var data := boss_data(drift)
	if data == null:
		return
	shown_drift = drift
	_pending = 0
	for child in _content.get_children():
		child.queue_free()
	_build(data, drift)
	visible = true
	_scroll.scroll_vertical = 0
	var screen := get_viewport_rect().size
	_scroll.custom_minimum_size.y = minf(_content.get_combined_minimum_size().y, screen.y - 140.0)
	# Mid-drift it pauses (a choice screen's calm); at rests nothing walks anyway.
	var speed := drift_director.get_node_or_null("%GameSpeed") as GameSpeed
	_paused_it = speed != null and not drift_director.is_resting() and not speed.paused
	if _paused_it:
		speed.set_paused(true)

func close_dossier() -> void:
	visible = false
	shown_drift = 0
	if _paused_it:
		_paused_it = false
		var speed := drift_director.get_node_or_null("%GameSpeed") as GameSpeed
		if speed != null:
			speed.set_paused(false)

func is_open() -> bool:
	return visible

func boss_data(drift: int) -> EnemyData:
	if drift < 1 or drift > drift_director.get_total_drifts():
		return null
	for group in drift_director.drifts[drift - 1].groups:
		for entry in group.entries:
			if entry.enemy != null and entry.enemy.is_boss:
				return entry.enemy
	return null

# The boss drift's other arrivals: [[EnemyData, count], …].
func escorts(drift: int) -> Array:
	var counts := {}
	var order: Array = []
	var extra := drift_director.get_extra_nightmares(drift)
	for group in drift_director.drifts[drift - 1].groups:
		for entry in group.entries:
			if entry.enemy == null or entry.enemy.is_boss:
				continue
			if not counts.has(entry.enemy):
				order.append(entry.enemy)
				counts[entry.enemy] = 0
			counts[entry.enemy] += entry.get_count(1.0, 1.0, extra)
	return order.map(func(data: EnemyData) -> Array: return [data, counts[data]])

# --- The card ------------------------------------------------------------------------------------

func _build(data: EnemyData, drift: int) -> void:
	_content.add_child(_header(data, drift))
	var numbers := HBoxContainer.new()
	numbers.add_theme_constant_override("separation", 22)
	numbers.add_child(_stat("Health", str(NightmareCard.health_at(data, drift, drift_director)),
		"With this run's growth, Blight and Dreams."))
	numbers.add_child(_stat("Speed", "%.1f tiles/s" % (data.speed / 64.0), "How fast it walks."))
	numbers.add_child(_stat("Leaves", str(data.leaf_cost), IconInfo.resource_tooltip(&"leaves")))
	_content.add_child(numbers)
	var rows := NightmareIcons.make_rows(data, 36.0, false, true)
	if rows.get_child_count() > 0:
		_content.add_child(rows)
	if data.abilities.size() > 0:
		_content.add_child(_section("What it does"))
		for i in data.abilities.size():
			_content.add_child(_ability_row(data.get_ability(i)))
	var brings := _brings(data, drift)
	if brings.get_child_count() > 0:
		_content.add_child(_section("It brings"))
		_content.add_child(brings)
	if not data.tips.is_empty():
		_content.add_child(_section("What helps"))
		var tips: Array[String] = []
		for tip in data.tips:
			tips.append("• " + tip)
		_content.add_child(StatusLinks.make_label("\n".join(tips), 15, Color(0.85, 0.9, 0.85)))
	_content.add_child(_section("Your record"))
	_content.add_child(StatusLinks.make_label(record_text(data), 15))

func _header(data: EnemyData, drift: int) -> Control:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	head.add_child(BossPortrait.new(data, 104.0))
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var name := Label.new()
	name.text = data.display_name + ("   · New" if NightmareCard.is_new(data) else "")
	UiStyle.display(name, 24)
	name.add_theme_color_override("font_color", BOSS_COLOR.lightened(0.25))
	box.add_child(name)
	var title: String = data.title
	if title != "":
		var sub := Label.new()
		sub.text = title
		sub.add_theme_font_size_override("font_size", 16)
		sub.add_theme_color_override("font_color", TITLE_COLOR)
		box.add_child(sub)
	var whisper := StatusLinks.make_label("[i]\"%s\"[/i]" % whisper_line(data), 15, WHISPER_COLOR)
	whisper.text = _links_keep_tags("[i]\"%s\"[/i]" % whisper_line(data))  # Italic, status names still links
	box.add_child(whisper)
	var arrives := Label.new()
	var started := drift_director.drifts_started
	arrives.text = "Walking now: drift %d" % drift if drift <= started else "Arrives in drift %d (%d from now)" % [drift, drift - started]
	arrives.add_theme_font_size_override("font_size", 15)
	arrives.add_theme_color_override("font_color", SECTION_COLOR)
	box.add_child(arrives)
	head.add_child(box)
	return head

static func whisper_line(data: EnemyData) -> String:
	var line = data.get("whisper")
	return String(line) if line != null and String(line) != "" else DEFAULT_WHISPER

func _stat(caption: String, value: String, tip: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	var top := Label.new()
	top.text = caption
	top.add_theme_font_size_override("font_size", 13)
	top.add_theme_color_override("font_color", Color(0.7, 0.72, 0.7))
	box.add_child(top)
	var number := Label.new()
	number.text = value
	number.add_theme_font_size_override("font_size", 20)
	box.add_child(number)
	TapTip.attach(box, tip)
	return box

func _section(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", SECTION_COLOR)
	return label

func _ability_row(ability: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var icon := NightmareIcons.trait_icon(StringName(ability.get("icon", "")), 34.0)
	icon.tip = IconInfo.format("%s: %s" % [ability.get("name", ""), ability.get("text", "")])
	icon.tooltip_text = icon.tip
	for child in icon.get_children():
		if child is TapTip:
			child._label.text = icon.tip
	row.add_child(icon)
	var text := "[b]%s[/b]  [color=#%s]%s[/color]\n%s" % [ability.get("name", ""), SECTION_COLOR.to_html(false),
		ability.get("when", ""), ability.get("text", "")]
	var label := StatusLinks.make_label("", 15)
	label.text = _links_keep_tags(text)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	return row

# StatusLinks.bbcode escapes "[" (plain text in); here the card's own tags must survive.
static func _links_keep_tags(text: String) -> String:
	var out := StatusLinks.bbcode(text)
	for tag in ["b", "/b", "/color", "i", "/i"]:
		out = out.replace("[lb]%s]" % tag, "[%s]" % tag)
	var colour := RegEx.create_from_string("\\[lb\\](color=#[0-9a-fA-F]{6})\\]")
	return colour.sub(out, "[$1]", true)

func _brings(data: EnemyData, drift: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	for summon in data.get_summons():
		box.add_child(_escort_row(summon.data, int(summon.count), String(summon.how), drift))
	for pair in escorts(drift):
		box.add_child(_escort_row(pair[0], pair[1], "in the same drift", drift))
	return box

func _escort_row(data: EnemyData, count: int, how: String, drift: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var face := TextureRect.new()
	face.texture = NightmareCard.portrait(data)
	face.modulate = data.tint
	face.custom_minimum_size = Vector2(36, 36)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	TapTip.attach(face, "%s: %s" % [data.display_name, NightmareCard.numbers_text(data, drift, drift_director)])
	row.add_child(UiStyle.on_moon_disc(face))  # Readable on the night sky (screens_ui.md)
	var label := Label.new()
	label.text = "%s ×%d · %s" % [data.display_name, count, how]
	label.add_theme_font_size_override("font_size", 15)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	row.add_child(NightmareIcons.make_rows(data, 20.0, true))
	return row

# --- Your record ---------------------------------------------------------------------------------

static func record_text(data: EnemyData) -> String:
	var profile := HeartwoodMemory.load_data()
	var kind := NightmareCard.kind_of(data)
	var record: Dictionary = profile.get(RECORDS_KEY, {}).get(kind, {})
	var dispelled := int(record.get("dispelled", 0))
	if dispelled > 0:
		return "Dispelled %d time%s · best %s" % [dispelled, "" if dispelled == 1 else "s", _time_text(float(record.get("best", 0.0)))]
	if profile.get("nightmares_seen", []).has(kind):
		return "Met before, never dispelled."
	return "New: you've never faced it."

static func _time_text(seconds: float) -> String:
	var s := roundi(seconds)
	return "%d:%02d" % [s / 60, s % 60]

func _on_spawned(node: Node) -> void:
	if node.get("enemy_data") == null or not node.enemy_data.is_boss:
		return
	var id := node.get_instance_id()
	_boss_time[id] = 0.0
	if node.has_signal("cleansed"):
		node.cleansed.connect(func(enemy: Node2D) -> void: _on_boss_dispelled(enemy, id), CONNECT_ONE_SHOT)
	node.tree_exited.connect(func() -> void: _boss_time.erase(id))

func _on_boss_dispelled(enemy: Node2D, id: int) -> void:
	var seconds: float = _boss_time.get(id, 0.0)
	if visible and shown_drift > 0 and shown_drift <= drift_director.drifts_started:
		close_dossier()  # "Until the boss is dispelled"
	# Records are the real game's only (never tests or dev runs).
	if get_tree().current_scene != owner_scene() or MetaRun.is_dev_run():
		return
	record_dispel(enemy.enemy_data, seconds)

func owner_scene() -> Node:
	return drift_director.owner  # main.tscn (code-made nodes have no owner of their own)

static func record_dispel(data: EnemyData, seconds: float) -> void:
	var profile := HeartwoodMemory.load_data()
	var records: Dictionary = profile.get(RECORDS_KEY, {})
	var kind := NightmareCard.kind_of(data)
	var record: Dictionary = records.get(kind, {})
	record["dispelled"] = int(record.get("dispelled", 0)) + 1
	var best := float(record.get("best", 0.0))
	record["best"] = seconds if best <= 0.0 else minf(best, seconds)
	records[kind] = record
	profile[RECORDS_KEY] = records
	HeartwoodMemory.save_data(profile)


# The boss's animated portrait (full art, never a silhouette): its sprite frames playing in a box.
class BossPortrait extends Control:
	var _sprite := AnimatedSprite2D.new()

	func _init(data: EnemyData, side: float) -> void:
		custom_minimum_size = Vector2(side, side)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		clip_contents = true
		process_mode = Node.PROCESS_MODE_ALWAYS
		_sprite.process_mode = Node.PROCESS_MODE_ALWAYS
		_sprite.sprite_frames = data.sprite_frames
		_sprite.modulate = data.tint
		add_child(_sprite)
		if data.sprite_frames == null:
			return
		for animation in [&"idle", &"walk_down", &"walk_side"]:
			if data.sprite_frames.has_animation(animation):
				_sprite.play(animation)
				break
		var frame := data.sprite_frames.get_frame_texture(_sprite.animation, 0)
		if frame != null:
			var fit := side / maxf(frame.get_width(), frame.get_height())
			_sprite.scale = Vector2(fit, fit) * 0.95

	func _ready() -> void:
		resized.connect(func() -> void: _sprite.position = size / 2.0)
		_sprite.position = size / 2.0

	func _draw() -> void:
		# The moon disc, rimmed in the boss colour (screens_ui.md "Readable on the night sky").
		UiStyle.draw_moon_disc(self, size / 2.0, size.x / 2.0, BOSS_COLOR)
