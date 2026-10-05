extends Control
class_name ComboFeedback

# Combos in play (screens_ui.md "The Codex: Glossary and Combos"): the 7 synergies and the 8
# Reactions (CodexData.combos()). Discovered the first time each one fires, ever: the game pauses on
# the moment (the nightmare ringed) with a card in the screen centre ("Combo discovered: Thunderclap",
# ingredients, one line, "Added to the Codex"; Continue / Open in Codex); several queue behind one
# pause, and it waits while a choice screen or the pause menu is open. With the Gameplay setting
# "Pause on new combos" off, the old 5 s slide-in card instead. Saved in the profile
# (`combos_seen`, lifetime `combo_counts`; also in the demo; never tests; developer-run finds carry a
# hidden flag, `combos_seen_dev`, and never count for the milestone), with the
# "all_combos" milestone once all are found. Also counts Reactions per block for the rest report
# (Fx shows their callouts). Sources: DamageLog combo tags (conducted, fog), ReactionTracker
# (Reactions), and ComboFeedback.report(id, near) from game code where a synergy happens (set_off,
# marked_blow, caught, asleep).

signal combo_discovered(id: StringName)  # For a discovery chime (SoundHooks)

const GROUP := &"combo_feedback"
const CARD_LAYER := 4  # The card's own CanvasLayer: above the HUD (1), under the Dream-mark tips (5)
const CARD_TIME := 5.0
const SEEN_KEY := "combos_seen"
const COUNTS_KEY := "combo_counts"
const LEGACY_KEY := "reactions_seen"  # Before synergies were combos
const MILESTONE := "all_combos"
const DAMAGE_TAGS: Array[StringName] = [&"conducted", &"fog"]

@onready var drift_director: DriftDirector = %DriftDirector
@onready var run_state: RunState = %RunState

var block_counts := {}  # Reaction id -> times this block (rest report)
var block_longest_chain := 0
var block_new: Array[StringName] = []  # Combos discovered this block
# Kinships: bonds formed, Harmony strikes, families made Whole (family lines), per block and run.
var kin_formed_block := 0
var kin_formed_run := 0
var harmony_block := 0
var harmony_run := 0
var whole_block: Array[String] = []
var whole_run: Array[String] = []
# "Night Chimes (Chime Stone + Dreamcatcher)" per bond formed this block (rest report).
var kin_names_block: Array[String] = []
const KINSHIPS_GROUP := &"kinships"
var run_counts := {}  # Combo id -> times this run
var _seen: Array = []  # Combo ids (String) discovered ever
var _unsaved := {}  # Combo id -> count not yet added to the profile's lifetime counts
var _queue: Array[StringName] = []
var _card := PanelContainer.new()
var _card_label := Label.new()  # The body (18 px)
var _card_title := Label.new()  # "Combo discovered: Thunderclap" (display 28, gold)
var _card_icons := HFlowContainer.new()  # 48 px status icons, or a chain's Reactions with arrows
var _dim := TextureRect.new()  # The world dimmed behind a pausing card, the nightmare left lit
var card_text := ""  # The card's whole text (title + body; tests)
const DIM_ALPHA := 0.6  # The world at ~40%
const DIM_HOLE := 70.0  # Radius (px) left lit around the nightmare
var _dim_gradient: Gradient
var _card_id: StringName = &""
var _card_tween: Tween
var _crown_corners := Control.new()  # Gold corners, shown on Crowned discovery cards
var _buttons := HBoxContainer.new()  # Continue / Open in Codex (pausing cards)
var _pausing := false  # A pausing discovery is holding the game
var _was_paused := false  # Whether the game was paused before it
var _enemies := {}  # Combo id -> the nightmare it was discovered on (for the ring)
var _ring: Node2D = null
# Peek at the map (screens_ui.md "The discovery card can be minimised"): hides the card and lifts the dim, the
# game stays paused; a small tab at the top ("Combo discovered") reopens it, Space / Enter continues.
var peek: ChoicePeek

const PAUSE_SETTING := "pause_on_combo"

const CROWN_ACCENT := preload("res://assets/effects/crowned_card_accent.png")

# Reports combo `id` (e.g. &"set_off") firing, from anywhere in the run's scene; pass the nightmare
# it happened on, if known, so a first discovery can ring it.
static func report(id: StringName, near: Node, enemy: Node2D = null) -> void:
	if near == null or not near.is_inside_tree():
		return
	var feedback := near.get_tree().get_first_node_in_group(GROUP) as ComboFeedback
	if feedback != null:
		feedback.record(id, enemy)

# Discoveries are saved to the account in every run, developer runs included (screens_ui.md "Saved to
# the account", replacing the session-only rule): a find made only in a developer run (Test Grove,
# Unlock all families, Dev Grove) carries a hidden "dev" flag (profile combos_seen_dev), so the
# "Discover every combo" milestone and achievement count normal-run finds only. Finding it later in
# a normal run clears the flag. Nothing shows the flag.
const DEV_KEY := "combos_seen_dev"

# Discovered combo ids (the profile's; the old reactions_seen counts too).
static func load_seen() -> Array:
	return profile_seen()

# Found only in developer runs so far (the hidden flag).
static func dev_seen() -> Array:
	return HeartwoodMemory.load_data().get(DEV_KEY, []).duplicate()

static func profile_seen() -> Array:
	var memory := HeartwoodMemory.load_data()
	var seen: Array = memory.get(SEEN_KEY, []).duplicate()
	for id in memory.get(LEGACY_KEY, []):
		if not seen.has(String(id)):
			seen.append(String(id))
	return seen

func _ready() -> void:
	add_to_group(GROUP)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_seen = load_seen()
	_dev_flagged = dev_seen()
	_chains_seen = chains_seen()
	_best_ever = chain_best() if _may_write() else {}  # Read once: the per-chain check stays in memory
	_card.visible = false
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	# Screen centre on its own layer above the HUD: the drift banner, Omen line and Coming strip never
	# draw over it (user playtest 2026-09-30).
	_card.set_anchors_preset(Control.PRESET_CENTER)
	_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_card.grow_vertical = Control.GROW_DIRECTION_BOTH
	# It stands out in combat (screens_ui.md "The discovery card stands out in combat"): a solid panel
	# with the gold thread, the title in the display font, 48 px icons, 18 px body.
	var style := UiStyle.panel(28.0, 20.0)
	style.center_alpha = UiStyle.TIP_ALPHA
	style.edge_alpha = UiStyle.TIP_ALPHA
	style.shadow_size = 14
	_card.add_theme_stylebox_override("panel", style)
	_card_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_title.custom_minimum_size = Vector2(440, 0)
	_card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.display(_card_title, 28)
	_card_title.add_theme_color_override("font_color", UiStyle.GOLD)
	_card_icons.alignment = FlowContainer.ALIGNMENT_CENTER
	_card_icons.add_theme_constant_override("h_separation", 8)
	_card_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_label.custom_minimum_size = Vector2(440, 0)
	_card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_label.add_theme_font_size_override("font_size", 18)
	var card_box := VBoxContainer.new()
	card_box.add_theme_constant_override("separation", 12)
	_card.add_child(card_box)
	card_box.add_child(_card_title)
	card_box.add_child(_card_icons)
	card_box.add_child(_card_label)
	# Pausing cards: Continue (also Space / Enter / a tap on the card) and Open in Codex.
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 12)
	card_box.add_child(_buttons)
	for pair in [["Continue", continue_on], ["Open in Codex", _continue_to_codex]]:
		var button := Button.new()
		button.text = pair[0]
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(150, 48)
		button.pressed.connect(pair[1])
		_buttons.add_child(button)
	# Crowned Reactions get gold corners (effects.json crowned_card_accent: the top-left corner,
	# mirrored for the others).
	_crown_corners.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(_crown_corners)
	for corner in [[Control.PRESET_TOP_LEFT, false, false], [Control.PRESET_TOP_RIGHT, true, false],
			[Control.PRESET_BOTTOM_LEFT, false, true], [Control.PRESET_BOTTOM_RIGHT, true, true]]:
		var piece := TextureRect.new()
		piece.texture = CROWN_ACCENT
		piece.flip_h = corner[1]
		piece.flip_v = corner[2]
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		piece.set_anchors_and_offsets_preset(corner[0], Control.PRESET_MODE_MINSIZE)
		_crown_corners.add_child(piece)
	_card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if _pausing:
				continue_on()  # A tap on a pausing card continues
			else:
				_open_in_codex(_card_id))  # A tap on the slide-in card opens its entry
	var layer := CanvasLayer.new()
	layer.layer = CARD_LAYER
	add_child(layer)
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(holder)
	_dim_gradient = Gradient.new()  # Lit in the middle (the nightmare), dark beyond
	var gradient := _dim_gradient
	gradient.set_color(0, Color(Palette.VOID, 0.0))
	gradient.set_color(1, Color(Palette.VOID, DIM_ALPHA))
	var hole := GradientTexture2D.new()
	hole.gradient = gradient
	hole.fill = GradientTexture2D.FILL_RADIAL
	hole.fill_from = Vector2(0.5, 0.5)
	hole.fill_to = Vector2(0.5, 0.0)
	hole.width = 256
	hole.height = 256
	_dim.texture = hole
	_dim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dim.stretch_mode = TextureRect.STRETCH_SCALE
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.visible = false
	holder.add_child(_dim)
	holder.add_child(_card)
	peek = ChoicePeek.new(holder, [_card, _dim], "Combo discovered")
	peek.catch_mouse = false  # The holder stays click-through: the world under it pans, zooms and hovers
	peek.place_back_centre()  # The "Return" pill mid-screen (pausing cards, ChoicePeek)
	peek.changed.connect(func(on: bool) -> void:
		if on:
			peek.back_button().text = return_text())
	_buttons.add_child(peek.make_peek_button())
	drift_director.rest_ended.connect(func(_block: int) -> void:
		block_counts.clear()
		block_longest_chain = 0
		block_new.clear()
		block_new_chains.clear()
		kin_formed_block = 0
		kin_names_block.clear()
		harmony_block = 0
		whole_block.clear())
	drift_director.rest_started.connect(func(_b: int, _boss: bool, _bonus: int, _perfect: bool) -> void: _save_counts())
	run_state.run_ended.connect(func(_won: bool) -> void: _save_counts())
	owner.child_entered_tree.connect(func(node: Node) -> void:
		if node is ReactionTracker:
			_hook(node)
		_hook_kinships.call_deferred(node))  # Joins its group in _ready
	var tracker := get_tree().get_first_node_in_group(ReactionTracker.GROUP)
	if tracker != null:
		_hook(tracker)
	_hook_kinships.call_deferred(get_tree().get_first_node_in_group(KINSHIPS_GROUP))
	_connect_log.call_deferred()  # DamageLog readies later in the scene

func _connect_log() -> void:
	if DamageLog.instance != null and not DamageLog.instance.damage_dealt.is_connected(_on_damage):
		DamageLog.instance.damage_dealt.connect(_on_damage)

func _hook(tracker: ReactionTracker) -> void:
	if not tracker.reaction_fired.is_connected(_on_reaction):
		tracker.reaction_fired.connect(_on_reaction)
	if not tracker.chain_reached.is_connected(_on_chain):
		tracker.chain_reached.connect(_on_chain)

# --- Chains (screens_ui.md "Combo discovery" → "Chains are discovered too") ------------------------
# The first time ever a chain reaches 3, 5 and 10 links is a discovery like a combo (same pause,
# queue and setting). The card lists the chain's Reactions in order, rebuilt from the recent firings
# (each carries its link number; a Crowned Reaction counts 2 links, so links may skip). Profile:
# `chains_seen` (tiers, as strings) and `chain_best` ({links, reactions}) for the Codex.
const CHAIN_TIERS: Array[int] = [3, 5, 10]
const CHAINS_KEY := "chains_seen"
const CHAIN_BEST_KEY := "chain_best"
const CHAIN_PREFIX := "chain_"  # Queue ids: &"chain_3"
const CHAIN_MEMORY := 3.0  # Seconds of firings kept to rebuild a chain (links are within 1 s)

var block_new_chains: Array[int] = []  # Chain tiers discovered this block (rest report)
var _chains_seen: Array = []  # Tiers (String) discovered ever
var _recent: Array = []  # [id, link, time] of the last CHAIN_MEMORY seconds
var _chain_orders := {}  # Queue id -> Reaction names in order

static func chains_seen() -> Array:
	return HeartwoodMemory.load_data().get(CHAINS_KEY, []).duplicate()

# {links, reactions: [names]} of the longest chain ever, or {}.
static func chain_best() -> Dictionary:
	return HeartwoodMemory.load_data().get(CHAIN_BEST_KEY, {}).duplicate(true)

func _note_firing(id: StringName, link: int) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	while not _recent.is_empty() and now - _recent[0][2] > CHAIN_MEMORY:
		_recent.pop_front()
	_recent.append([id, link, now])

# A Reaction's display name, looked up once (perf, Tower's lag probe: CodexData.get_any rebuilds the Crowned and
# Kinship lists on every call, and chain_order asked it for every recent firing on every chain link: 6–130 ms
# per chain in a dense storm build).
var _names := {}
func _display_name(id: StringName) -> String:
	if not _names.has(id):
		var combo := CodexData.get_any(id)
		_names[id] = combo.name if not combo.is_empty() else String(id).capitalize()
	return _names[id]

# The Reaction names of the chain whose newest link is `links`, first to last.
func chain_order(links: int) -> Array[String]:
	var names: Array[String] = []
	var below := links + 1
	for i in range(_recent.size() - 1, -1, -1):
		var link: int = _recent[i][1]
		if link < below:
			names.push_front(_display_name(_recent[i][0]))
			below = link
			if link <= 1:
				break
	return names

func _on_chain(links: int, _where: Vector2, _towers: Array) -> void:
	var order := chain_order(links)
	# Perf (Tower: one Reaction burst cost 12–124 ms in the listeners): the longest chain is compared in memory and
	# written at the next rest / the run's end (_save_counts), never a profile read or file write per chain.
	if links > maxi(int(_best_ever.get("links", 0)), int(_best_this_session.get("links", 0))):
		_best_this_session = {"links": links, "reactions": order}
		_best_ever = _best_this_session
		_best_dirty = true
	# One discovery ever (screens_ui.md "Chains: one discovery, then Dawnbreak"): the first Chain 3+. Profiles
	# that saw any tier before never see it again.
	if links < CHAIN_TIERS[0] or has_seen_chain():
		return
	var tier: int = CHAIN_TIERS[0]
	_note_seen(str(tier))
	block_new_chains.append(tier)
	var id := StringName(CHAIN_PREFIX + str(tier))
	_chain_orders[id] = order
	_queue.append(id)
	if not showing():
		_try_show()

# Whether a chain was ever discovered (any tier: older profiles saw 3, 5, 10 separately).
func has_seen_chain() -> bool:
	return _chains_seen.any(func(s) -> bool: return String(s).is_valid_int())

# Adds `key` to the profile's `chains_seen` (tiers, and "dawnbreak").
func _note_seen(key: String) -> void:
	_chains_seen.append(key)
	if _may_write():
		var memory := HeartwoodMemory.load_data()
		var seen: Array = memory.get(CHAINS_KEY, []).duplicate()
		if not seen.has(key):
			seen.append(key)
		memory[CHAINS_KEY] = seen
		HeartwoodMemory.save_data(memory)

# Dawnbreak (the Legendary that fires at a Chain 10) gets its own one-time card the first time it goes off.
const DAWNBREAK_ID := &"dawnbreak"
const DAWNBREAK_TEXT := "Dawnbreak discovered\nA Chain 10 broke into dawn: 10% of max health to every nightmare within 4 cells (bosses 2%).\nAdded to the Codex."
func _discover_dawnbreak(enemy: Node2D) -> void:
	_note_seen(String(DAWNBREAK_ID))
	_queue.append(DAWNBREAK_ID)
	_enemies[DAWNBREAK_ID] = enemy
	if not showing():
		_try_show()

var _best_this_session := {}  # Tests and scenes that don't write the profile
var _best_ever := {}  # The profile's longest chain, read once (real game), raised in memory
var _best_dirty := false  # A longer chain to write at the next rest / run end

# The one chain discovery: what a chain is, then the longest so far (screens_ui.md "Chains: one discovery").
const CHAIN_LINE := "A Reaction can spread its statuses and set off another. Past the fifth link each one hits a little softer, but the chain keeps counting."

static func chain_text(tier: int, order: Array, longest: int = 0) -> String:
	var text := "Chain discovered: Chain %d\n" % tier
	if not order.is_empty():
		text += " → ".join(order) + "\n"
	text += CHAIN_LINE + "\n"
	text += "Your longest: Chain %d\n" % maxi(longest, tier)
	return text + "Added to the Codex."

# Kinships (Tower Code's node, group "kinships"; tower_design.md "Kinships"): the first-ever bond of
# each kind is a discovery like a combo, and bonds formed / Harmony strikes / families made Whole are
# counted here for the rest report and results (so they don't depend on when Kinships resets).
# Untyped: a node freed before this deferred call ran would fail the typed argument ("Cannot convert … Object").
func _hook_kinships(node) -> void:
	if not is_instance_valid(node) or not node is Node or not node.is_in_group(KINSHIPS_GROUP) or node.is_connected("kinship_formed", _on_kinship):
		return
	node.connect("kinship_formed", _on_kinship)
	if node.has_signal("harmony_struck"):
		node.connect("harmony_struck", func(_tower: Node, _enemy: Node2D) -> void:
			harmony_block += 1
			harmony_run += 1)
	if node.has_signal("family_whole"):
		node.connect("family_whole", func(family: String) -> void:
			whole_block.append(family)
			whole_run.append(family))

func _on_kinship(kinship: StringName, a: Node, b: Node) -> void:
	kin_formed_block += 1
	kin_formed_run += 1
	var names: Array[String] = []
	for tower in [a, b]:
		if tower is Tower:
			names.append(tower.tower_data.display_name)
	var entry := CodexData.get_any(kinship)
	if names.size() < 2:  # The pair from the Codex when the Wardens aren't known
		names.assign([entry.get("a", "?"), entry.get("b", "?")])
	kin_names_block.append("%s (%s)" % [entry.get("name", String(kinship).capitalize()), " + ".join(names)])
	record(kinship, a as Node2D)

func _on_damage(event: DamageLog.Event) -> void:
	if event.tag == DAWNBREAK_ID and not _chains_seen.has(String(DAWNBREAK_ID)):  # Its first Dawnburst ever
		_discover_dawnbreak(event.enemy)
	if event.combos.is_empty():  # Most hits (every hit and status tick comes through here)
		return
	for tag in event.combos:
		if DAMAGE_TAGS.has(tag):
			record(tag, event.enemy)

func _on_reaction(id: StringName, enemy: Node2D, chain: int, _towers: Array) -> void:
	block_counts[id] = block_counts.get(id, 0) + 1
	block_longest_chain = maxi(block_longest_chain, chain)
	_note_firing(id, chain)
	record(id, enemy)

# One firing of combo `id` (on `enemy`, if known): counted, and discovered if it's the first time ever.
func record(id: StringName, enemy: Node2D = null) -> void:
	run_counts[id] = run_counts.get(id, 0) + 1
	_unsaved[id] = _unsaved.get(id, 0) + 1
	var key := String(id)
	if _seen.has(key):  # The common case first (runs for many hits a frame): no Codex lookup
		if not _dev_flagged.is_empty() and _dev_flagged.has(key) and not MetaRun.is_dev_run():
			_clear_dev_flag(id)  # Found in a normal run now: it counts (no second discovery card)
		return
	if CodexData.get_any(id).is_empty():
		return
	# Discovery unlocks (dream_design.md): the Dreams this find lets into the pool, for the card.
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP)
	var before: Array = dreams.undiscovered_cards() if dreams != null and dreams.has_method("undiscovered_cards") else []
	_seen.append(String(id))
	block_new.append(id)
	_remember_discovery(id)
	if not before.is_empty():
		var typed: Array[UpgradeData] = []
		typed.assign(before)
		var names: Array = dreams.newly_discovered(typed)
		if not names.is_empty():
			new_dreams[id] = names
	combo_discovered.emit(id)
	_queue.append(id)
	_enemies[id] = enemy
	if not showing():
		_try_show()

# --- Pausing discoveries (screens_ui.md "Combos (discovered in play)") -----------------------------
# A discovery freezes the world on the moment (the nightmare ringed), with the card in the screen centre and
# the map visible. Continue resumes at the previous speed (already paused stays paused); several
# queue behind one pause. While a choice screen or the pause menu is open, it waits. The Gameplay
# setting "Pause on new combos" (pause_on_combo, default on) off = the old 5 s slide-in card.

# Headless test scripts never pause on a discovery (a drift would stall mid-test) unless a test
# turns it on with `pause_in_tests`.
static var pause_in_tests := false

static func pause_setting() -> bool:
	if OS.get_cmdline_args().has("--script"):
		return pause_in_tests
	return bool(HeartwoodMemory.get_settings().get(PAUSE_SETTING, true))

func _try_show() -> void:
	if CaptureDirector.capturing():  # Marketing captures run on a fresh profile: every combo is "new", no cards
		_queue.clear()
		return
	if _queue.is_empty() or showing():
		return
	if pause_setting() and _blocked():
		return  # _process tries again once the screen closes
	_show_next()

# A choice screen, the pause menu or the results are up: the discovery waits.
func _blocked() -> bool:
	for path in ["%PauseMenu", "%FamilyPickScreen", "%RememberScreen", "%ResultsScreen"]:
		var node := get_node_or_null(path) as Control
		if node != null and node.visible:
			return true
	var dreams = get_node_or_null("%DreamState")
	if dreams != null and dreams.is_offering():
		return true
	var omens := get_tree().get_first_node_in_group(&"omens")
	return omens != null and omens.has_method("is_offering") and omens.is_offering()

# The minimised card's pill: "Return to the combo" for one, "Return (2)" with more waiting behind it.
func return_text() -> String:
	if not _queue.is_empty():
		return "Return (%d)" % (_queue.size() + 1)
	var title := _card_title.text  # "Combo discovered: Thunderclap" -> "Thunderclap"
	var name := title.get_slice(":", 1).strip_edges() if title.contains(":") else title
	return "Return to %s" % (name if name != "" else "the discovery")

# A card is up: shown, or minimised while peeking at the map.
func showing() -> bool:
	return _card.visible or (peek != null and peek.peeking)

func _process(_delta: float) -> void:
	if not _queue.is_empty() and not showing():
		_try_show()

func _unhandled_input(event: InputEvent) -> void:
	if not (showing() and _pausing):
		return
	if event.is_action_pressed("pause_game") or event.is_action_pressed("start_drift") or event.is_action_pressed("ui_accept"):
		continue_on()
		get_viewport().set_input_as_handled()

# Continue: the next queued discovery, or the end of the pause (back to the previous speed).
func continue_on() -> void:
	if peek != null:
		peek.set_peeking(false)
	_clear_highlight()
	if not _queue.is_empty():
		_show_next()
		return
	_card.visible = false
	_dim.visible = false
	if _pausing:
		_pausing = false
		var speed = get_node_or_null("%GameSpeed")
		if speed != null:
			speed.set_paused(_was_paused)

func _continue_to_codex() -> void:
	var id := _card_id
	_queue.clear()  # Straight to the book; the rest are in it too
	continue_on()
	_open_in_codex(id)

func _highlight(enemy: Node2D) -> void:
	_clear_highlight()
	if is_instance_valid(enemy) and enemy.is_inside_tree():
		_ring = ComboRing.new()
		enemy.add_child(_ring)

func _clear_highlight() -> void:
	if is_instance_valid(_ring):
		_ring.queue_free()
	_ring = null

# A pulsing ring round the nightmare a combo was discovered on (runs while the tree is paused).
class ComboRing extends Node2D:
	var _time := 0.0

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		z_index = 20

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var pulse := 0.5 + 0.5 * sin(_time * 4.0)
		draw_arc(Vector2.ZERO, 26.0 + pulse * 4.0, 0.0, TAU, 40, Color(UiStyle.LIVE, 0.9), 3.0, true)
		draw_arc(Vector2.ZERO, 36.0 + pulse * 6.0, 0.0, TAU, 40, Color(UiStyle.LIVE, 0.35 * (1.0 - pulse)), 2.0, true)

# A Legendary's gem at the card's icon size (Dawnbreak has no icon art of its own yet).
class _LegendaryGem extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(48, 48)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		UiStyle.draw_gem(self, size / 2.0, 18.0, UpgradeData.Rarity.LEGENDARY)

static func discovery_text(id: StringName) -> String:
	var combo := CodexData.get_any(id)
	if combo.is_empty():
		return ""
	if combo.kind == "Kinship":  # screens_ui.md "Kinship feedback": first time ever, a card + Codex entry
		return "Kinship discovered: %s\n%s + %s\n%s\nAdded to the Codex." % [combo.name, combo.a, combo.b, combo.text]
	if combo.kind == "Crowned":  # Its own card (tower_design.md "Crowned Reactions", rule 3)
		var families: Array[String] = []
		for family in combo.families:
			families.append(CodexData.FAMILY_NAMES.get(family, family))
		return "Crowned Reaction discovered: %s\n%s · %s\n%s\nAdded to the Codex." % [combo.name,
			CodexData.crowned_recipe(combo), ", ".join(families), combo.text]
	return "Combo discovered: %s\n%s\n%s\nAdded to the Codex." % [combo.name, CodexData.ingredients_text(combo), combo.text]

func _show_next() -> void:
	if _queue.is_empty():
		_card.visible = false
		_dim.visible = false
		return
	_card_id = _queue.pop_front()
	var is_chain := String(_card_id).begins_with(CHAIN_PREFIX)
	var order: Array = _chain_orders.get(_card_id, [])
	if is_chain:
		var best: Dictionary = chain_best() if _may_write() else _best_this_session
		card_text = chain_text(int(String(_card_id).trim_prefix(CHAIN_PREFIX)), order, int(best.get("links", 0)))
	elif _card_id == DAWNBREAK_ID:
		card_text = DAWNBREAK_TEXT
	else:
		card_text = discovery_text(_card_id)
	if new_dreams.has(_card_id):  # "New Dreams: Rolling Thunder, Rain on Glass" (discovery unlocks)
		card_text += "\nNew Dreams: " + ", ".join(new_dreams[_card_id])
	# Title (display 28, gold), the icons, then the body (a chain's order is in the icons row).
	var lines := card_text.split("\n")
	_card_title.text = lines[0]
	var body := lines.slice(1)
	if is_chain and not order.is_empty() and body.size() > 0:
		body = body.slice(1)
	_card_label.text = "\n".join(body)
	_card_label.add_theme_color_override("font_color", UiStyle.INK)
	_build_card_icons(_card_id, is_chain, order)
	_crown_corners.visible = CodexData.CROWNED.has(_card_id)
	var pausing := pause_setting()
	_buttons.visible = pausing
	if pausing and not _pausing:  # The first of a queue freezes the world; the last Continue thaws it
		_pausing = true
		var speed = get_node_or_null("%GameSpeed")
		if speed != null:
			_was_paused = speed.paused
			speed.set_paused(true)
	if pausing:
		_highlight(_enemies.get(_card_id))
		_show_dim(_enemies.get(_card_id))
	_enemies.erase(_card_id)
	_card.visible = true
	_card.reset_size()
	_card.offset_left = -_card.size.x / 2.0
	_card.offset_right = _card.size.x / 2.0
	_card.offset_top = -_card.size.y / 2.0
	_card.offset_bottom = _card.size.y / 2.0
	_card.modulate.a = 0.0
	if _card_tween:
		_card_tween.kill()
	_card_tween = create_tween()
	_card_tween.tween_property(_card, "modulate:a", 1.0, 0.3)
	if not bool(HeartwoodMemory.get_settings().get("reduced_motion", false)):  # A soft rise-in
		_card.pivot_offset = _card.size / 2.0  # A soft rise-in: it grows into place (its rect never moves)
		_card.scale = Vector2(0.95, 0.95)
		_card_tween.parallel().tween_property(_card, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if is_chain:
		combo_discovered.emit(_card_id)  # The discovery chime for chains too (combos emit when found)
	if pausing:
		return  # Stays until Continue
	_card_tween.tween_interval(CARD_TIME)  # Setting off: the old slide-in card, for 5 s
	_card_tween.tween_property(_card, "modulate:a", 0.0, 0.5)
	_card_tween.tween_callback(_show_next)

func _open_in_codex(id: StringName) -> void:
	var pause := get_node_or_null("%PauseMenu")
	if pause != null and pause.has_method("open_codex"):
		pause.open_codex(&"combos", String(id))

# "Thunderclap 12 · Ignite 3" for `counts`, plus " · longest chain: N" from 2 up ("" = none). Chains
# always read as a count ("Chain 10"), never "×10", which looks like a damage multiplier.
static func summary(counts: Dictionary, longest_chain: int) -> String:
	var ids := counts.keys()
	ids.sort_custom(func(a, b) -> bool: return counts[a] > counts[b])
	var parts: Array[String] = []
	for id in ids:
		var combo := CodexData.get_any(id)
		parts.append("%s %d" % [combo.name if not combo.is_empty() else String(id), counts[id]])
	var text := " · ".join(parts)
	if longest_chain >= 2:
		text += " · longest chain: %d" % longest_chain
	return text

# "Damp + Static" for a Reaction (kept for callers from before the Codex).
static func pair_text(data: ReactionData) -> String:
	return CodexData.ingredients_text({"statuses": data.statuses})

# Discoveries: the real game writes them (tests never do); lifetime counts stay out of dev runs.
func _may_write() -> bool:
	return get_tree().current_scene == owner

var _dev_flagged: Array = []  # Ids found only in developer runs (loaded at _ready)
var new_dreams := {}  # Combo id -> names of the Dreams its discovery let into the pool

func _remember_discovery(id: StringName) -> void:
	if MetaRun.is_dev_run() and not _dev_flagged.has(String(id)):
		_dev_flagged.append(String(id))
	if not _may_write():
		return
	var memory := HeartwoodMemory.load_data()
	var seen: Array = memory.get(SEEN_KEY, []).duplicate()
	if not seen.has(String(id)):
		seen.append(String(id))
	memory[SEEN_KEY] = seen
	var dev: Array = memory.get(DEV_KEY, []).duplicate()
	if MetaRun.is_dev_run():
		if not dev.has(String(id)):
			dev.append(String(id))
	else:
		dev.erase(String(id))
	memory[DEV_KEY] = dev
	_check_milestone(memory)
	HeartwoodMemory.save_data(memory)

func _clear_dev_flag(id: StringName) -> void:
	_dev_flagged.erase(String(id))
	if not _may_write():
		return
	var memory := HeartwoodMemory.load_data()
	var dev: Array = memory.get(DEV_KEY, []).duplicate()
	dev.erase(String(id))
	memory[DEV_KEY] = dev
	_check_milestone(memory)
	HeartwoodMemory.save_data(memory)

# "Discover every combo" (meta_design.md): the 15 combos (not Crowned), each found in a normal run.
func _check_milestone(memory: Dictionary) -> void:
	var seen: Array = memory.get(SEEN_KEY, []) + memory.get(LEGACY_KEY, [])
	var dev: Array = memory.get(DEV_KEY, [])
	if CodexData.combos().all(func(c: Dictionary) -> bool: return seen.has(String(c.id)) and not dev.has(String(c.id))):
		memory.milestones[MILESTONE] = true

# Lifetime counts ("times you've set it off") go to the profile at rests and at the run's end.
func _save_counts() -> void:
	if _best_dirty and _may_write():  # The longest chain, held since the chain ran
		_best_dirty = false
		var profile := HeartwoodMemory.load_data()
		profile[CHAIN_BEST_KEY] = _best_ever
		HeartwoodMemory.save_data(profile)
	if _unsaved.is_empty() or not _may_write() or MetaRun.is_dev_run():  # Lifetime counts: normal runs only
		_unsaved.clear()
		return
	var memory := HeartwoodMemory.load_data()
	var counts: Dictionary = memory.get(COUNTS_KEY, {})
	for id in _unsaved:
		counts[String(id)] = int(counts.get(String(id), 0)) + _unsaved[id]
	memory[COUNTS_KEY] = counts
	HeartwoodMemory.save_data(memory)
	_unsaved.clear()

# The world dims to ~40% behind a pausing card, except a soft circle around the nightmare it fired on.
func _show_dim(enemy: Node2D) -> void:
	var screen := get_viewport().get_visible_rect().size
	var centre := screen / 2.0
	var hole := 0.0
	if is_instance_valid(enemy) and enemy.is_inside_tree():
		centre = enemy.get_global_transform_with_canvas().origin
		hole = DIM_HOLE
	var reach := screen.length() * 1.2  # Big enough to cover the screen from any centre
	_dim.size = Vector2(reach, reach) * 2.0
	_dim.position = centre - Vector2(reach, reach)
	_dim_gradient.set_offset(0, hole / reach)
	_dim_gradient.set_offset(1, minf((hole * 2.0 + 1.0) / reach, 1.0))
	_dim.visible = true

# The card's icons: a combo's two statuses at 48 px ("Soaked + Charged"); a chain's Reactions in
# order with arrows, repeats collapsed ("Drown → Nightbloom ×2").
func _build_card_icons(id: StringName, is_chain: bool, order: Array) -> void:
	for child in _card_icons.get_children():
		_card_icons.remove_child(child)
		child.queue_free()
	if id == DAWNBREAK_ID:  # Its own icon (UI Asset, icons.json "legendary"), else the Legendary gem
		_card_icons.add_child(_card_icon(id) if IconInfo.icon(id) != null else _LegendaryGem.new())
		return
	if is_chain:
		var runs: Array = []  # [name, count]
		for name in order:
			if not runs.is_empty() and runs[-1][0] == name:
				runs[-1][1] += 1
			else:
				runs.append([name, 1])
		for i in runs.size():
			if i > 0:
				_card_icons.add_child(_card_word("→", UiStyle.INK_DIM))
			var reaction_id := _reaction_id_named(String(runs[i][0]))
			if reaction_id != &"" and IconInfo.icon(reaction_id) != null:
				_card_icons.add_child(_card_icon(reaction_id))  # Each Reaction's own icon (UI Asset), 48 px
			_card_icons.add_child(_card_word(runs[i][0] + (" ×%d" % runs[i][1] if runs[i][1] > 1 else ""), UiStyle.GOLD))
		return
	var combo := CodexData.get_any(id)
	var statuses: Array = combo.get("statuses", [])
	for i in statuses.size():
		if i > 0:
			_card_icons.add_child(_card_word("+", UiStyle.INK_DIM))
		_card_icons.add_child(IconInfo.make_icon(statuses[i], 3))  # 48 px, with its tap tip
	if IconInfo.icon(id) != null:  # A Reaction: its own icon after its statuses (it's discovered now)
		_card_icons.add_child(_card_word("→", UiStyle.INK_DIM))
		_card_icons.add_child(_card_icon(id))

# A Reaction's icon at 48 px (16 px art ×3, nearest).
func _card_icon(id: StringName) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = IconInfo.icon(id)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(48, 48)
	return icon

# The Reaction (or Crowned Reaction) id for a name in a chain's order.
static func _reaction_id_named(name: String) -> StringName:
	for entry in CodexData.combos() + Array(CodexData.crowned()):
		if entry.get("name", "") == name:
			return StringName(entry.id)
	return &""

func _card_word(text: String, colour: Color) -> Label:
	var word := Label.new()
	word.text = text
	UiStyle.display(word, 22)
	word.add_theme_color_override("font_color", colour)
	word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return word
