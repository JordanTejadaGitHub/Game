extends Control

# Warden family pick (run_design.md, "Warden families"): after drift 1 and after each boss, pick 1
# of up to 3 base Wardens you don't have yet, drawn at random from every family the profile has
# unlocked (the starting 3 + Grove families added by MetaRun); the first pick avoids repeating the
# previous run's first offer. The pick unlocks it (Sprouts can grow into it, or
# plant it directly). Only real new families are offered: 3, else 2 or 1 (no Blessing filler, user
# 2026-09-30); a boss pick with none left is skipped for +2 Dreamlight. Early Bloom (Grove perk) makes the first pick offer
# every family. Pauses the game while open; "Peek at the map" minimises it. Cards show the statuses
# the family applies and its two branches (screens_ui.md "Family pick"). Built in code.

signal sapling_offered  # The Heartwood Sapling's card appears (once, after the drift 50 pick)
signal family_chosen(offered: Array, chosen: Resource)  # RunHistory: the offer and the pick

const CARD_SIZE := Vector2(250, 300)
const CARD_PADDING := 24.0  # The box's top + bottom offsets inside a card
const SAPLING_DRIFT := 50  # The act 2 boss: the Heartwood Sapling is offered after its family pick
const TITLES := {
	&"first": "The Heartwood stirs, and remembers an old friend…",
	&"boss": "It's gone, and something I'd forgotten came back.",
}

# Families that can be offered (demo: the first-playable three; the full game adds Pebbling,
# Rootling and Acorn once the Memory Grove unlocks them).
@export var families: Array[TowerData] = [
	preload("res://resource/tower/sporeling.tres"),
	preload("res://resource/tower/firefly_jar.tres"),
	preload("res://resource/tower/dewdrop.tres"),
]
@export var cards_per_pick: int = 3
var offer_all_first := false  # Early Bloom (set by MetaRun)
# Memory Warden (tower_design.md): set by MetaRun when a boss whose bloom the Grove has grown is dispelled;
# the next boss pick offers it in one of the slots (free, one per run).
var pending_memory_warden: TowerData
var previous_first_offer: Array = []  # Sorted ids of the last run's first-pick offer (profile "last_first_pick")

@onready var dream_state: DreamState = %DreamState
@onready var drift_director: DriftDirector = %DriftDirector
@onready var game_speed: GameSpeed = %GameSpeed

var offer: Array = []  # TowerData (a new family) or UpgradeData (a Family Blessing)
var _was_paused := false
var _title := Label.new()
var _cards := HBoxContainer.new()
var peek: ChoicePeek  # Minimise to look at the map (screens_ui.md "Choice screens")

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(UiStyle.FOG, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.display(_title, 28)
	_title.add_theme_color_override("font_color", UiStyle.LIVE)
	box.add_child(_title)
	_cards.add_theme_constant_override("separation", 16)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_cards)
	peek = ChoicePeek.new(self, [dim, center], "Back to the family pick")
	box.add_child(peek.make_peek_button())
	visible = false
	previous_first_offer = HeartwoodMemory.load_data().get("last_first_pick", [])
	previous_first_offer.sort()
	drift_director.family_pick_requested.connect(show_pick)

# Families not unlocked yet, in roster order.
func get_available() -> Array[TowerData]:
	var result: Array[TowerData] = []
	for data in families:
		if not dream_state.is_unlocked(data.get_id()):
			result.append(data)
	return result

func show_pick(reason: StringName = &"first") -> void:
	var available := get_available()
	available.shuffle()
	var count := available.size() if reason == &"first" and offer_all_first else cards_per_pick
	# The first pick never repeats the previous run's offer exactly (when there's a choice), so runs
	# start differently (dream_design.md "Where Warden families come from").
	if reason == &"first" and available.size() > count:
		for attempt in 20:
			if _ids(available.slice(0, count)) != previous_first_offer:
				break
			available.shuffle()
	_include_owed_family(available, count)
	offer = []  # Untyped: families (TowerData) and Blessings (UpgradeData) share it
	offer.append_array(available.slice(0, count))
	if reason == &"boss" and pending_memory_warden != null and not dream_state.is_unlocked(pending_memory_warden.get_id()):
		if offer.size() >= cards_per_pick:
			offer.pop_back()
		offer.push_front(pending_memory_warden)
	pending_memory_warden = null
	if reason == &"first":
		_remember_first_offer()
	# Only real new families: no Blessing filler (user, meta_design.md "Replaced 2026-09-30"). With no
	# family left, a boss pick is skipped for +2 Dreamlight ("The Heartwood remembers deeper.").
	if offer.is_empty() and reason == &"boss":
		var line := dream_state.grant_no_family_pick()
		var hud := get_parent()
		if hud != null and hud.has_method("show_toast"):
			hud.show_toast(line)
	if offer.is_empty():
		if should_offer_sapling():  # No family left, but the Sapling still gets its card
			if not visible:
				_was_paused = game_speed.paused
			game_speed.set_paused(true)
			visible = true
			_show_sapling()
			return
		drift_director.family_picked()  # Nothing left to offer
		return
	if not visible:
		_was_paused = game_speed.paused
	game_speed.set_paused(true)
	_title.text = TITLES.get(reason, TITLES[&"first"])
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	for data in offer:
		if data is UpgradeData:
			_cards.add_child(_make_blessing_card(data))
		elif data.line == "memory":
			_cards.add_child(_make_memory_card(data))  # A boss's reward, not a family
		else:
			_cards.add_child(_make_card(data))
	visible = true

# Sorted Warden ids of the families in `datas`.
func _ids(datas: Array) -> Array:
	var ids: Array = datas.filter(func(d) -> bool: return d is TowerData).map(func(d: TowerData) -> String: return d.get_id())
	ids.sort()
	return ids

# Kept in the profile for the next run's first pick; real game only (never tests or Test Grove).
func _remember_first_offer() -> void:
	previous_first_offer = _ids(offer)
	if get_tree().current_scene != owner or MetaRun.is_dev_run():
		return
	var memory := HeartwoodMemory.load_data()
	memory["last_first_pick"] = previous_first_offer
	HeartwoodMemory.save_data(memory)

# Blessings for the families you own (their cards are in the Dream pool, added by MetaRun).
func get_blessings() -> Array:
	var result: Array = []
	for data in families:
		if dream_state.is_unlocked(data.get_id()):
			var card := _blessing_for(data)
			if card != null:
				result.append(card)
	return result

func _blessing_for(data: TowerData) -> UpgradeData:
	for card in dream_state.pool:
		if card.id == "blessing_" + data.get_id():
			return card
	return null

func choose(data: Resource) -> void:
	if not offer.has(data):
		return
	dream_state.note_family_pick(_ids(offer), data.get_id() if data is TowerData else "")  # Declined families (half-dreamed)
	family_chosen.emit(offer.duplicate(), data)
	offer = []
	if data is UpgradeData:
		dream_state.take(data)  # A Family Blessing
	else:
		dream_state.unlocked[data.get_id()] = true
		dream_state.unlocks_changed.emit()
	if should_offer_sapling():
		_show_sapling()  # Right after the drift 50 family pick (run_design.md "The Heartwood Sapling")
		return
	_finish()

func _finish() -> void:
	visible = false
	game_speed.set_paused(_was_paused)
	drift_director.family_picked()

# The Heartwood Sapling's own card follows the act 2 boss's family pick (drift 50), once.
func should_offer_sapling() -> bool:
	var placer := get_node_or_null("%TowerPlacer")
	return placer != null and placer.has_method("can_take_sapling") and placer.can_take_sapling() \
		and drift_director.drifts_started == SAPLING_DRIFT

func _show_sapling() -> void:
	sapling_offered.emit()  # For its own swell (SoundHooks; audio_direction.md)
	var placer = %TowerPlacer
	_title.text = "The Heartwood offers a seedling of itself"
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(420, 0)
	card.add_theme_constant_override("separation", 10)
	var data: TowerData = placer.sapling
	if data != null and data.texture != null:
		var icon := TextureRect.new()
		icon.texture = _frame(data)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		card.add_child(icon)
	for line in [["The Heartwood Sapling", 22, UiStyle.INK],
			["Free to plant, 2×2, a wall like any Warden. Permanent: once planted it can't be sold or moved.", 15, UiStyle.INK],
			["It doesn't attack. After every drift it yields +20 Dew, and every 10 drifts +1 Dreamlight. Nurture it for more; leaks wither it a little.", 15, UiStyle.MOONLIGHT],
			["Not now? You can plant it later from the rest panel.", 13, UiStyle.WHISPER]]:
		var label := Label.new()
		label.text = line[0]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", line[1])
		label.add_theme_color_override("font_color", line[2])
		card.add_child(label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	for pair in [["Take the Sapling", func() -> void:
			_finish()
			placer.take_sapling()],  # Enters build mode with it selected
			["Not now", _finish]]:
		var button := Button.new()
		button.text = pair[0]
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(180, 48)
		button.pressed.connect(pair[1])
		row.add_child(button)
	card.add_child(row)
	_cards.add_child(card)

# A card's content sits in `box` inside the button (a Button doesn't size to its children), so the
# card grows to fit it, at least CARD_SIZE tall; the row then gives every card the tallest's height.
func _fit_card(button: Button, box: Control) -> void:
	var fit := func() -> void:
		var needed := box.get_combined_minimum_size().y + CARD_PADDING
		button.custom_minimum_size = Vector2(CARD_SIZE.x, maxf(CARD_SIZE.y, needed))
	box.minimum_size_changed.connect(fit)
	fit.call_deferred()

func _make_card(data: TowerData) -> Button:
	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(choose.bind(data))
	UiStyle.card_button(button, Palette.SPRIG)  # Moonlit Thread card (ui_style.md)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 14
	box.offset_top = 12
	box.offset_right = -14
	box.offset_bottom = -12
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	_fit_card(button, box)
	if data.texture != null:
		var icon := TextureRect.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = data.texture
		atlas.region = data.get_frame_rect(0)
		icon.texture = atlas
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(icon)
	var sprout_cost := dream_state.get_evolve_cost(data)
	# screens_ui.md "Family pick": name, identity, the statuses it applies, previews of its branches.
	var lines := [[data.display_name, 22, UiStyle.INK], [IconInfo.format(data.description), 15, UiStyle.INK]]
	var statuses := get_status_text(data)
	if statuses != "":
		lines.append([statuses, 14, Palette.DEWLIGHT])
	lines.append(["Grow a Sprout into it: %d Dew · plant directly: %d Dew" % [sprout_cost, data.cost], 13, UiStyle.LIVE])
	for line in lines:
		var label := Label.new()
		label.text = line[0]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", line[1])
		label.add_theme_color_override("font_color", line[2])
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(label)
	var branches := get_branches(data)
	if not branches.is_empty():
		var grows := Label.new()
		grows.text = "Grows into"
		grows.add_theme_font_size_override("font_size", 13)
		grows.add_theme_color_override("font_color", UiStyle.WHISPER)
		box.add_child(grows)
		for branch in branches:
			var row := HBoxContainer.new()
			row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_theme_constant_override("separation", 6)
			box.add_child(row)
			var preview := TextureRect.new()
			preview.texture = _frame(branch)
			preview.custom_minimum_size = Vector2(32, 32)
			preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(preview)
			var name_label := Label.new()
			name_label.text = branch.display_name
			name_label.add_theme_font_size_override("font_size", 13)
			row.add_child(name_label)
	return button

# "Applies Spored" / "Applies Drowsy and Static": the statuses this family's base Warden puts on
# nightmares ("" = none).
static func get_status_text(data: TowerData) -> String:
	var names: Array[String] = []
	for status in [data.applies_status, data.extra_status]:
		if status != &"" and not names.has(IconInfo.status_name(status)):
			names.append(IconInfo.status_name(status))
	return "Applies " + " and ".join(names) if not names.is_empty() else ""

# The branches this family grows into in this run (up to 2), without hidden ones the Memory Grove
# hasn't opened.
func get_branches(data: TowerData) -> Array[TowerData]:
	var result: Array[TowerData] = []
	for next in data.evolves_to:
		var branch := next as TowerData
		if branch != null and dream_state.get_unlock_blocker(branch) != "Memory Grove" and result.size() < 2:
			result.append(branch)
	return result

func _frame(data: TowerData) -> Texture2D:
	return WardenIcon.make(data)

# A Family Blessing: the same card shape, with a golden blessing border.
func _make_blessing_card(card: UpgradeData) -> Button:
	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(choose.bind(card))
	UiStyle.card_button(button, UiStyle.GOLD)  # Moonlit Thread card (ui_style.md)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 14
	box.offset_top = 12
	box.offset_right = -14
	box.offset_bottom = -12
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	_fit_card(button, box)
	for line in [["Blessing", 14, UiStyle.GOLD], [card.display_name, 22, UiStyle.INK], [IconInfo.format(card.description), 15, UiStyle.INK]]:
		var label := Label.new()
		label.text = line[0]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", line[1])
		label.add_theme_color_override("font_color", line[2])
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(label)
	return button

# A Memory Warden (screens_ui.md "Memory Warden card"): the boss's reward, not a family. Gold /
# dream-fruit thread and a warm glow, "A Memory returns", the boss's flavour line, its identity and
# statuses, and a "Unique" tag. Placeholder look until the bloom art exists.
const MEMORY_GOLD := UiStyle.GOLD
const MEMORY_GLOW := Palette.DEEPMOSS

func _make_memory_card(data: TowerData) -> Button:
	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(choose.bind(data))
	UiStyle.card_button(button, MEMORY_GOLD)
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var style := button.get_theme_stylebox(state) as MoonStyleBox
		if style:
			style = style.duplicate()
			style.glow_color = MEMORY_GLOW  # The soft warm glow
			button.add_theme_stylebox_override(state, style)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 14
	box.offset_top = 12
	box.offset_right = -14
	box.offset_bottom = -12
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	_fit_card(button, box)
	var heading := Label.new()
	heading.text = "A Memory returns"
	heading.add_theme_font_size_override("font_size", 14)
	heading.add_theme_color_override("font_color", MEMORY_GOLD)
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(heading)
	if data.texture != null:
		var icon := TextureRect.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = data.texture
		atlas.region = data.get_frame_rect(0)
		icon.texture = atlas
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(icon)
	var lines := [[data.display_name, 22, UiStyle.INK]]
	var flavour: String = MetaRun.MEMORY_FLAVOUR.get(data.get_id(), "")
	if flavour != "":
		lines.append([flavour, 14, UiStyle.INK])
	lines.append([IconInfo.format(data.description), 15, UiStyle.INK])
	var statuses := get_status_text(data)
	if statuses != "":
		lines.append([statuses, 14, Palette.DEWLIGHT])
	lines.append(["Unique: one on the map at a time. Free to plant.", 12, MEMORY_GOLD])
	for line in lines:
		var label := Label.new()
		label.text = line[0]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", line[1])
		label.add_theme_color_override("font_color", line[2])
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(label)
	_add_memory_border(button)
	return button

# The Memory Warden card's dream-fruit border (meta_assets.md "memory_card_border.png"): a 9-slice
# drawn over the card, grown 12 px on every side, the vine sides tiled; 4 frames pulse at 4 fps.
const MEMORY_BORDER := preload("res://assets/meta/ui/memory_card_border.png")
const MEMORY_BORDER_FRAME := Vector2(274, 324)
const MEMORY_BORDER_MARGIN := 42
const MEMORY_BORDER_GROW := 12
const MEMORY_BORDER_FPS := 4.0

func _add_memory_border(button: Button) -> void:
	var border := NinePatchRect.new()
	border.name = "MemoryBorder"
	border.texture = MEMORY_BORDER
	border.region_rect = Rect2(Vector2.ZERO, MEMORY_BORDER_FRAME)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		border.set_patch_margin(side, MEMORY_BORDER_MARGIN)
	border.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE  # The vine repeats every 24 px
	border.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.offset_left = -MEMORY_BORDER_GROW
	border.offset_top = -MEMORY_BORDER_GROW
	border.offset_right = MEMORY_BORDER_GROW
	border.offset_bottom = MEMORY_BORDER_GROW
	button.add_child(border)
	var pulse := Timer.new()
	pulse.wait_time = 1.0 / MEMORY_BORDER_FPS
	pulse.autostart = true
	pulse.process_mode = Node.PROCESS_MODE_ALWAYS  # The pick pauses the game
	pulse.timeout.connect(func() -> void:
		var frame := (int(border.region_rect.position.x / MEMORY_BORDER_FRAME.x) + 1) % 4
		border.region_rect = Rect2(Vector2(frame * MEMORY_BORDER_FRAME.x, 0), MEMORY_BORDER_FRAME))
	border.add_child(pulse)

# A half-dreamed Dream taken since the last pick owes this pick its missing family (one of them if
# several): it's moved into the offered slots; the player still chooses (dream_design.md
# "Adapt, don't get handed" 5).
func _include_owed_family(available: Array[TowerData], count: int) -> void:
	# Seed cards held call their families (every one); a half-dreamed Dream owes one of its missing ones.
	var wanted: Array = dream_state.get_called_families()
	for id in dream_state.take_owed_families():
		if not wanted.has(id) and available.any(func(d: TowerData) -> bool: return d.get_id() == id):
			wanted.append(id)
			break
	var slot := 0
	for id in wanted:
		if slot >= count:
			break
		for i in available.size():
			if available[i].get_id() != id:
				continue
			if i >= slot:  # Move it into the next offered slot
				var swapped := available[slot]
				available[slot] = available[i]
				available[i] = swapped
				slot += 1
			break
