extends Control
class_name BossDossier

# The boss dossier (screens_ui.md "Boss dossier (at the start of each act)", 2026-09-29): the act's
# boss is warned of when the act begins. It opens by itself at the run's first rest (act 1, after
# the onboarding whisper) and at each act-break rest (after drifts 25 / 50 / 75, last in the rest
# order: after the family pick, Dream and Omen) for the NEXT act's boss. The rest that opens a boss
# block (after 20 / 45 / 70 / 95) only shows a small reminder ("<Boss> arrives in 5 drifts", its
# portrait, "About the Mire Hag"). The card:
#   stage     "It must feel like THE boss" (2026-09-30): the eyebrow "The boss of act N", the animated
#             portrait at PORTRAIT px rising from violet mist on the left, the map dimmed near black with a
#             slow vignette pulse, a Wraithlight frame; an entrance (portrait fades up, the name writes in;
#             reduced motion = a plain fade) and `boss_revealed` for Sound (boss_reveal)
#   header    eyebrow, name · title, a whisper line, "Drift 25 · the last drift of the act", "New"
#   the toll  the leaves it takes, large (health: the portrait's tip; speed and "It brings" removed, user 2026-10-02)
#   defences  the Resists / Weak to / Immune rows, larger (NightmareIcons)
#   abilities icon, name, what it does, WHEN (EnemyData.get_ability: numbers filled from the data)
#   your record (times dispelled, best time; profile "boss_records")
# Reopen any time from the drift banner's "Boss in N" or the boss portrait in Coming this block
# (BossDossier.open_for). Opened during a drift it pauses until closed. Made by the HUD.

const GROUP := &"boss_dossier"
const ENEMY_SCRIPT := preload("res://scripts/enemy/enemy.gd")  # HEARTWOOD_DRAIN_EVERY
const SPAWNER_SCRIPT := preload("res://scripts/enemy/enemy_spawner.gd")  # boss_bite_leaves (toll_text without a run)
const RECORDS_KEY := "boss_records"  # Profile: {kind: {"dispelled": n, "best": seconds}}
const WIDTH := 880.0
const PORTRAIT := 240.0  # The boss's portrait, ~3× the old one
const BOSS_COLOR := UiStyle.BOSS  # Heartwood 32 (ui_style.md)
const COMPARE_PATH := "res://resource/enemy/bark_beetle.tres"  # The Husk: "about 13 Husks"
const PULSE_SPEED := 1.1  # The vignette's slow breath (radians per second)

signal boss_revealed(data: EnemyData)  # The card came up (Sound: boss_reveal)
const TITLE_COLOR := UiStyle.WHISPER
const WHISPER_COLOR := UiStyle.WHISPER
const SECTION_COLOR := UiStyle.GOLD
const DEFAULT_WHISPER := "Something old has found the dream."
const OPEN_DELAY := 0.35  # Seconds after the rest starts before checking the rest's screens
const WHISPER_PATIENCE := 8.0  # Most seconds it waits for onboarding whispers to finish

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
var _pending_first := false  # The run's first rest: act 1's boss (checked once the save is restored)
var _reminder_drift := 0  # Boss drift the boss-block reminder shows (0 = none)
var _reminder_pending := 0  # …waiting for the rest's screens, like the card
var _reminder: PanelContainer  # Its own node: the dossier root is hidden while the card is closed
var _vignette := TextureRect.new()
var _clock := 0.0
var _stage: BossStage  # The portrait in its mist (entrance)
var _name_label: Label  # Writes in on the entrance

# "The boss of act 1", Wraithlight small caps (the dossier, the reminder and the Codex).
static func eyebrow(act: int, size: int = 16) -> Label:
	var label := Label.new()
	label.text = "The boss of act %d" % act
	UiStyle.caps(label, size, BOSS_COLOR)
	return label

static func _reduced_motion() -> bool:
	return bool(HeartwoodMemory.get_settings().get("reduced_motion", false))

# 4000 -> "4,000".
static func thousands(n: int) -> String:
	var digits := str(absi(n))
	var out := ""
	while digits.length() > 3:
		out = "," + digits.right(3) + out
		digits = digits.left(digits.length() - 3)
	return ("-" if n < 0 else "") + digits + out

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
	# The map dims almost black, with a slow vignette pulse at the edges.
	var shade := ColorRect.new()
	shade.color = Color(Palette.VOID, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Offsets too: exactly the screen
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(Palette.VOID, 0.0))
	gradient.set_color(1, Color(Palette.VOID, 0.95))
	gradient.set_offset(0, 0.45)
	var ring := GradientTexture2D.new()
	ring.gradient = gradient
	ring.fill = GradientTexture2D.FILL_RADIAL
	ring.fill_from = Vector2(0.5, 0.5)
	ring.fill_to = Vector2(1.0, 1.0)
	ring.width = 256
	ring.height = 256
	_vignette.texture = ring
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vignette)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Offsets too: exactly the screen
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	var frame := UiStyle.panel_in(BOSS_COLOR, 16.0, 16.0)  # Thread and diamond in Wraithlight
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
	close.tooltip_text = "Reopen it from the boss name at the top."
	close.custom_minimum_size = Vector2(200, 44)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(close_dossier)
	outer.add_child(close)
	if drift_director != null:
		drift_director.rest_started.connect(_on_rest_started)
		_pending_first = true  # Act 1's boss at the first rest (if this is a new run: see _process)
		_wait = OPEN_DELAY
		_make_reminder.call_deferred()
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

func _on_rest_started(block: int, boss_rest: bool, _bonus: int, _perfect: bool) -> void:
	_pending_first = false
	_pending = 0  # A new rest: whatever the last one was waiting to show is past
	_reminder_pending = 0
	_hide_reminder()
	if boss_rest:
		# The act break: the next act's boss, now that the act begins.
		var next := next_boss_drift()
		if next > 0 and not _auto_shown.has(next) and boss_data(next) != null:
			_pending = next
			_wait = OPEN_DELAY
		return
	var boss := boss_drift_in_block(block + 1)
	if boss > 0 and boss_data(boss) != null:
		_reminder_pending = boss  # The boss block: only a reminder now
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
	if visible:  # The vignette breathes (held still with reduced motion)
		_clock += delta / maxf(Engine.time_scale, 0.001)
		_vignette.modulate.a = 1.0 if _reduced_motion() else 0.8 + 0.2 * sin(_clock * PULSE_SPEED)
	if not get_tree().paused:  # Game seconds each live boss has been walking (its record's time)
		for id in _boss_time:
			_boss_time[id] += delta
	if _reminder_drift > 0 and not drift_director.is_resting():
		_hide_reminder()  # The boss block started
	elif _reminder_drift > 0:
		_place_reminder()
	if _pending_first:
		# The run's first rest, once RunSaver has restored a save (a resumed run isn't at drift 0)
		_pending_first = false
		var first := next_boss_drift()
		if drift_director.drifts_started == 0 and first > 0 and boss_data(first) != null:
			_pending = first
	if _pending == 0 and _reminder_pending == 0:
		return
	if not drift_director.is_resting():
		_pending = 0  # The block started without it (Start pressed in the meantime)
		_reminder_pending = 0
		return
	_wait -= delta / maxf(Engine.time_scale, 0.001)
	if _wait > 0.0 or not screens_clear():
		return
	if _whisper_showing() and _wait > -WHISPER_PATIENCE:
		return  # After the whisper on screen, but a first run's queue of them doesn't hold it forever
	if _pending > 0:
		_auto_shown[_pending] = true
		open(_pending)
		_pending = 0
	elif _reminder_pending > 0:
		_show_reminder(_reminder_pending)
		_reminder_pending = 0

# An onboarding whisper is on screen (the act 1 dossier comes after it).
func _whisper_showing() -> bool:
	var whispers := drift_director.owner.get_node_or_null("%Whispers") as CanvasItem if drift_director.owner != null else null
	return whispers != null and whispers.visible and whispers.modulate.a > 0.01

# --- The boss-block reminder --------------------------------------------------------------------

func _make_reminder() -> void:
	_reminder = PanelContainer.new()
	_reminder.name = "BossReminder"
	var frame := UiStyle.panel_in(BOSS_COLOR, 10.0, 10.0)
	_reminder.add_theme_stylebox_override("panel", frame)
	_reminder.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_reminder.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_reminder.position.y = 96.0  # Under the drift banner
	_reminder.process_mode = Node.PROCESS_MODE_ALWAYS
	_reminder.visible = false
	get_parent().add_child(_reminder)

func _show_reminder(drift: int) -> void:
	var data := boss_data(drift)
	if _reminder == null or data == null:
		return
	for child in _reminder.get_children():
		child.queue_free()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.add_child(eyebrow(drift_director.get_act(drift), 13))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(BossPortrait.new(data, 44.0))
	var text := Label.new()
	var left := drift - drift_director.drifts_started
	text.text = "%s arrives in %d drift%s" % [data.display_name, left, "" if left == 1 else "s"]
	text.add_theme_font_size_override("font_size", 17)
	text.add_theme_color_override("font_color", BOSS_COLOR.lightened(0.25))
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(text)
	var button := Button.new()
	button.text = "About %s" % IconInfo.name_in_sentence(data.display_name)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void:
		open(drift)
		_hide_reminder())
	row.add_child(button)
	box.add_child(row)
	_reminder.add_child(box)
	_reminder.reset_size()
	_reminder.visible = true
	_reminder_drift = drift
	_place_reminder()

# Centred under the drift banner, and under the "Coming this block" strip (same spot at rests).
func _place_reminder() -> void:
	var top := 96.0
	for node in get_parent().get_children():
		if node is ComingStrip and node.visible:
			top = maxf(top, node.position.y + node.size.y + 16.0)  # Clear of its fog panel
	_reminder.position = Vector2((get_viewport_rect().size.x - _reminder.size.x) / 2.0, top)

func _hide_reminder() -> void:
	if _reminder != null:
		_reminder.visible = false
	_reminder_drift = 0

# The boss-block reminder is showing (for tests and the HUD).
func is_reminding() -> bool:
	return _reminder_drift > 0

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
	_entrance(data)
	_scroll.scroll_vertical = 0
	var screen := get_viewport_rect().size
	_scroll.custom_minimum_size.y = minf(_content.get_combined_minimum_size().y, screen.y - 140.0)
	# Mid-drift it pauses (a choice screen's calm); at rests nothing walks anyway.
	var speed := drift_director.get_node_or_null("%GameSpeed") as GameSpeed
	_paused_it = speed != null and not drift_director.is_resting() and not speed.paused
	if _paused_it:
		speed.set_paused(true)

# The card comes up: the portrait fades up out of the mist and the name writes in (reduced motion:
# a plain fade of the whole card). Runs while paused.
func _entrance(data: EnemyData) -> void:
	boss_revealed.emit(data)
	_clock = 0.0
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_panel.modulate.a = 0.0
	if _reduced_motion():
		tween.tween_property(_panel, "modulate:a", 1.0, 0.4)
		return
	tween.tween_property(_panel, "modulate:a", 1.0, 0.25)
	if _stage != null:
		_stage.reveal = 0.0
		tween.parallel().tween_property(_stage, "reveal", 1.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if _name_label != null:
		_name_label.visible_ratio = 0.0
		tween.parallel().tween_property(_name_label, "visible_ratio", 1.0, 0.7).set_delay(0.35)

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

# --- The card ------------------------------------------------------------------------------------

# The portrait in its mist on the left, everything else in the right column.
func _build(data: EnemyData, drift: int) -> void:
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 22)
	_content.add_child(columns)
	_stage = BossStage.new(data, PORTRAIT)
	_stage.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	columns.add_child(_stage)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(right)
	right.add_child(_header(data, drift))
	# Less on the page (user: "a lot of information on the boss page, remove health and speed and what it brings"):
	# health lives on the boss bar in the fight, and in the portrait's tip here; speed and "It brings" are gone
	# (escorts show in the Coming strip; a summoning ability's row names what it calls).
	var health := NightmareCard.health_at(data, drift, drift_director)
	TapTip.attach(_stage, "Health %s%s (with this run's growth, Blight and Dreams)" % [thousands(health), _compare_text(health, drift)])
	var leaves := Label.new()  # What it costs you, large
	var spawner = drift_director.get_node_or_null("%EnemyContainer") if drift_director != null else null
	leaves.text = toll_text(data, drift_director.get_act(drift) if drift_director != null else 1, spawner)
	UiStyle.display(leaves, 26)
	leaves.add_theme_color_override("font_color", BOSS_COLOR.lightened(0.25))
	TapTip.attach(leaves, IconInfo.resource_tooltip(&"leaves"))
	right.add_child(leaves)
	var rows := NightmareIcons.make_rows(data, 36.0, false, true)
	if rows.get_child_count() > 0:
		right.add_child(rows)
	if data.abilities.size() > 0:
		right.add_child(_section("What it does"))
		for i in data.abilities.size():
			right.add_child(_ability_row(data.get_ability(i)))
	right.add_child(_section("Your record"))
	right.add_child(StatusLinks.make_label(record_text(data), 15))

# What a boss costs you at the Heartwood (the dossier, large; the Codex's boss entry): "Takes 10 leaves if it reaches
# the Heartwood"; the Night Mare and the Hollow Oak in their own words. Without a run's EnemyContainer (the Codex on the
# title screen), the bite table's default from the spawner script.
static func toll_text(data: EnemyData, act: int, spawner: Node = null) -> String:
	if data.laps():  # The Night Mare: untouchable while it lingers, longer each lap
		return "At the Heartwood it can't be touched: it drains, then runs the maze again, faster"
	if data.stays_at_heartwood:  # The Hollow Oak
		return "Stays at the Heartwood, draining a leaf every %s s" % String.num(ENEMY_SCRIPT.HEARTWOOD_DRAIN_EVERY)
	var bite := data.leaf_cost
	if spawner != null and spawner.has_method("get_boss_bite"):
		bite = spawner.get_boss_bite(act)  # A flat bite by act (EnemyContainer.boss_bite_leaves), then it's gone
	else:
		var spawner_script: Script = SPAWNER_SCRIPT
		var table = spawner_script.get_property_default_value("boss_bite_leaves")
		if table is Array and not table.is_empty():
			bite = int(table[clampi(act - 1, 0, table.size() - 1)])
	return "Takes %d leaves if it reaches the Heartwood" % bite

# " · about 13 Husks": its health in the act's everyday nightmare, at the same drift.
func _compare_text(health: int, drift: int) -> String:
	var husk := load(COMPARE_PATH) as EnemyData
	if husk == null:
		return ""
	var each := NightmareCard.health_at(husk, drift, drift_director)
	var count := roundi(float(health) / maxf(each, 1.0))
	return " · about %d %s" % [count, husk.display_name + ("s" if count != 1 else "")] if count >= 2 else ""

func _header(data: EnemyData, drift: int) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(eyebrow(drift_director.get_act(drift)))
	var name := Label.new()
	name.text = data.display_name + (" · New" if NightmareCard.is_new(data) else "")
	UiStyle.display(name, 34)
	name.add_theme_color_override("font_color", BOSS_COLOR.lightened(0.25))
	box.add_child(name)
	_name_label = name
	var title: String = data.title
	if title != "":
		var sub := Label.new()
		sub.text = title
		sub.add_theme_font_size_override("font_size", 16)
		sub.add_theme_color_override("font_color", TITLE_COLOR)
		box.add_child(sub)
	var when := Label.new()
	var last := drift == drift_director.get_act(drift) * drift_director.drifts_per_act
	when.text = "Drift %d%s" % [drift, " · the last drift of the act" if last else ""]
	UiStyle.caps(when, 14, UiStyle.INK_DIM)
	box.add_child(when)
	var whisper := StatusLinks.make_label("[i]\"%s\"[/i]" % whisper_line(data), 15, WHISPER_COLOR)
	whisper.text = _links_keep_tags("[i]\"%s\"[/i]" % whisper_line(data))  # Italic, status names still links
	box.add_child(whisper)
	var arrives := Label.new()
	var started := drift_director.drifts_started
	arrives.text = "Walking now" if drift <= started else "Arrives in %d drift%s" % [drift - started, "" if drift - started == 1 else "s"]
	arrives.add_theme_font_size_override("font_size", 15)
	arrives.add_theme_color_override("font_color", SECTION_COLOR)
	box.add_child(arrives)
	return box

static func whisper_line(data: EnemyData) -> String:
	var line = data.get("whisper")
	return String(line) if line != null and String(line) != "" else DEFAULT_WHISPER

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

# The portrait rising from violet mist ("It must feel like THE boss"): `reveal` 0..1 fades it up and
# lifts it out of the mist (the entrance tweens it); the mist drifts slowly (still with reduced motion).
class BossStage extends Control:
	const RISE := 36.0  # Pixels the portrait rises through on the entrance
	var reveal := 1.0:
		set(value):
			reveal = value
			_portrait.modulate.a = value
			_portrait.position.y = (1.0 - value) * RISE
			queue_redraw()
	var _portrait: BossPortrait
	var _time := 0.0

	func _init(data: EnemyData, side: float) -> void:
		custom_minimum_size = Vector2(side, side + 24.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		process_mode = Node.PROCESS_MODE_ALWAYS
		_portrait = BossPortrait.new(data, side)
		_portrait.size = Vector2(side, side)
		add_child(_portrait)

	func _process(delta: float) -> void:
		if BossDossier._reduced_motion():
			return
		_time += delta / maxf(Engine.time_scale, 0.001)
		if Engine.get_process_frames() % 3 == 0:  # The mist drifts: a redraw every 3rd frame is plenty
			queue_redraw()

	func _draw() -> void:
		# Soft violet mist pooled under the portrait: stacked translucent ellipses, drifting.
		var base := Vector2(size.x / 2.0, size.y - 30.0)
		for i in 7:
			var t := float(i) / 6.0
			var sway := sin(_time * 0.6 + i * 1.3) * 10.0
			var r := size.x * (0.52 - t * 0.28)
			var centre := base + Vector2(sway, -t * size.y * 0.55)
			# The Nightmare ramp (Dread → Shade → Bruise), Wraithlight only on the thin top wisp (ui_style.md:
			# the gold stays the card's only warmth).
			var ramp: Color = [Palette.DREAD, Palette.DREAD, Palette.SHADE, Palette.SHADE, Palette.BRUISE, Palette.BRUISE, Palette.WRAITHLIGHT][i]
			var colour := Color(ramp, (0.5 - t * 0.38) * (0.4 + 0.6 * reveal))
			draw_set_transform(centre, 0.0, Vector2(1.0, 0.45))
			draw_circle(Vector2.ZERO, r, colour)
		draw_set_transform(Vector2.ZERO)
