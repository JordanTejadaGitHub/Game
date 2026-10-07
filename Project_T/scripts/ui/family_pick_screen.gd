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

const CARD_SIZE := Vector2(300, 400)  # Light pass (UI Asset's last page): 300 wide, the "Wake …" action at the foot
const CARD_PADDING := 32.0  # The box's top + bottom offsets inside a card
const SAPLING_DRIFT := 50  # The act 2 boss: the Heartwood Sapling is offered after its family pick
const TITLES := {
	&"first": "Oh. I know you.",
	&"boss": "It's gone, and something I'd forgotten came back.",
}

# Families that can be offered (the starting four, the demo's too: Bellflower joined 2026-10-01, meta_design.md
# a3375108; the full game adds the Grove's families through MetaRun).
@export var families: Array[TowerData] = [
	preload("res://resource/tower/sporeling.tres"),
	preload("res://resource/tower/firefly_jar.tres"),
	preload("res://resource/tower/dewdrop.tres"),
	preload("res://resource/tower/bellflower.tres"),
]
# Family picks show 2, the Grove widens them (user 2026-10-06, meta_design.md e0c02e54): every pick shows
# `cards_per_pick`; the Perks node Wider Choice adds one. A pick always holds an attacking family (never only support).
@export var cards_per_pick: int = 2
const WIDER_CHOICE_ID := "wider_choice"
static var force_wider_choice := false  # Tests: as if the node were planted
const SUPPORT_FAMILIES := ["acorn"]  # Family roots that mostly strengthen others (meta_design.md: "today: Acorn")
var offer_all_first := false  # Early Bloom (set by MetaRun)
var first_boss_pick_fewer := 0  # Sidegrade Early Bloom (MetaRun, Spire experiment): the drift 25 pick shows this many fewer
# Memory Warden (tower_design.md): set by MetaRun when a boss whose bloom the Grove has grown is dispelled;
# the next boss pick offers it in one of the slots (free, one per run).
var pending_memory_warden: TowerData
var previous_first_offer: Array = []  # Sorted ids of the last run's first-pick offer (profile "last_first_pick")
# Kin Foretold (Grove Perks node, meta_design.md b585bec5; full game): every pick also shows, below the cards, the
# families the NEXT boss pick will offer. That offer is drawn ahead and kept (saved with the run: RunSaver "foretold"),
# so the same families really come. Drawn from what's still free, never a card on screen now, so any choice keeps it true.
const KIN_FORETOLD_ID := "kin_foretold"
static var force_kin_foretold := false  # Tests: as if the node were planted
var foretold: Array = []  # Warden ids the next boss pick offers ([] = not drawn yet)
var _foretold_line := Label.new()

@onready var dream_state: DreamState = %DreamState
@onready var drift_director: DriftDirector = %DriftDirector
@onready var game_speed: GameSpeed = %GameSpeed

var offer: Array = []  # TowerData (a new family) or UpgradeData (a Family Blessing)
var _was_paused := false
var _title := Label.new()
var _subtitle := Label.new()  # "Choose a family to wake", quiet under the title (light pass)
var _cards := HBoxContainer.new()
var arm: ChoiceArm  # The arm delay (choice_arm.gd)
var peek: ChoicePeek  # Minimise to look at the map (screens_ui.md "Choice screens")

func _ready() -> void:
	WorldLabel.cover_while_visible(self, &"family_pick_screen")  # No world tags (DPS, hover names) over a full-screen screen
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
	_subtitle.name = "Subtitle"
	_subtitle.text = "Choose a family to wake"
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_color_override("font_color", UiStyle.INK_DIM)
	box.add_child(_subtitle)
	_cards.add_theme_constant_override("separation", 16)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_cards)
	_foretold_line.name = "Foretold"
	_foretold_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_foretold_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_foretold_line.custom_minimum_size.x = 520
	_foretold_line.add_theme_font_size_override("font_size", 15)
	_foretold_line.add_theme_color_override("font_color", UiStyle.MOON_MIST)
	_foretold_line.visible = false
	box.add_child(_foretold_line)
	peek = ChoicePeek.new(self, [dim, center], "Back to the family pick")
	var peek_button := peek.make_peek_button()
	if peek_button is Button:
		UiStyle.quiet(peek_button)  # Light pass: quiet; the cards hold the choice
		peek_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(peek_button)
	# A press for 0.6 s after the cards show never picks (Roguelite's ChoiceArm; user: "sometimes I click on cards when
	# waves end because I'm trying to place towers").
	arm = ChoiceArm.attach(self, _cards)
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
	var count := available.size() if reason == &"first" and offer_all_first else pick_count()
	if reason == &"boss" and first_boss_pick_fewer > 0 and drift_director.drifts_started <= drift_director.drifts_per_act:
		count = maxi(count - first_boss_pick_fewer, 2)  # Never below 2 (Meta Game Discussion: Early Bloom needs Wider Choice)
	_keep_an_attacker(available, count)
	# The first pick never repeats the previous run's offer exactly (when there's a choice), so runs
	# start differently (dream_design.md "Where Warden families come from").
	if reason == &"first" and available.size() > count:
		for attempt in 20:
			if _ids(available.slice(0, count)) != previous_first_offer:
				break
			available.shuffle()
			_keep_an_attacker(available, count)
	# Picks follow only their own rules: no card puts a family into them (user, "make it predictable"; dream_design.md
	# half-dreamed "Picks stay pure"). A half-dreamed card sleeps until a pick happens to offer its family.
	offer = []  # Untyped: families (TowerData) and Blessings (UpgradeData) share it
	if reason == &"boss" and not foretold.is_empty():  # Kin Foretold: the families shown last time, as promised
		var promised := available.filter(func(d: TowerData) -> bool: return foretold.has(d.get_id()))
		promised.sort_custom(func(a: TowerData, b: TowerData) -> bool: return foretold.find(a.get_id()) < foretold.find(b.get_id()))
		available.assign(promised + available.filter(func(d: TowerData) -> bool: return not promised.has(d)))  # Typed: assign
		count = maxi(count, promised.size())
		_keep_an_attacker(available, count)  # A promised family taken some other way since: still never only support
	foretold = []
	offer.append_array(available.slice(0, count))
	if reason == &"boss" and pending_memory_warden != null and not dream_state.is_unlocked(pending_memory_warden.get_id()):
		if offer.size() >= pick_count():
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
			arm.arm()
			return
		drift_director.family_picked()  # Nothing left to offer
		return
	if not visible:
		_was_paused = game_speed.paused
	game_speed.set_paused(true)
	_title.text = TITLES.get(reason, TITLES[&"first"])
	_subtitle.visible = true
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
	_foretell()
	visible = true
	arm.arm()

static func wider_choice_owned() -> bool:
	return force_wider_choice or DemoGrove.owns(WIDER_CHOICE_ID)  # The demo Grove grows it too (DemoGrove.NODES)

# Cards a pick shows: 2, 3 with Wider Choice (fewer when fewer families are left: the caller slices).
func pick_count() -> int:
	return cards_per_pick + (1 if wider_choice_owned() else 0)

static func is_support_family(data: TowerData) -> bool:
	return data != null and (SUPPORT_FAMILIES.has(data.get_id()) or data.role_tag == &"support")

# Puts an attacking family into the first `count` of `pool` when they'd all be support (the first attacker after them
# takes the last slot), so no pick offers only support families.
static func _keep_an_attacker(pool: Array, count: int) -> void:
	var shown := mini(count, pool.size())
	if shown <= 0 or pool.slice(0, shown).any(func(d: TowerData) -> bool: return not is_support_family(d)):
		return
	for i in range(shown, pool.size()):
		if not is_support_family(pool[i]):
			var attacker = pool[i]
			pool[i] = pool[shown - 1]
			pool[shown - 1] = attacker
			return

static func kin_foretold_owned() -> bool:
	if force_kin_foretold:
		return true
	if ResultsScreen.is_demo():
		return false
	var unlock := HeartwoodMemory.get_unlock(KIN_FORETOLD_ID)
	return unlock != null and HeartwoodMemory.node_level(HeartwoodMemory.load_data(), unlock) > 0

# The drift of the next boss pick (the act's last), or 0 when this is the last pick of the run.
func next_pick_drift() -> int:
	var per := drift_director.drifts_per_act
	var next := (drift_director.drifts_started / per + 1) * per
	return next if next < drift_director.get_total_drifts() else 0

# Draws (once) and shows the next boss pick's families: still free, none of the cards on screen now.
func _foretell() -> void:
	_foretold_line.visible = false
	var drift := next_pick_drift()
	if not kin_foretold_owned() or drift <= 0:
		return
	if foretold.is_empty():
		var on_screen := _ids(offer)
		var pool := get_available().filter(func(d: TowerData) -> bool: return not on_screen.has(d.get_id()))
		pool.shuffle()
		var count := pick_count()
		if first_boss_pick_fewer > 0 and drift <= drift_director.drifts_per_act:
			count = maxi(count - first_boss_pick_fewer, 2)  # Never below 2 (Meta Game Discussion: Early Bloom needs Wider Choice)
		_keep_an_attacker(pool, count)
		foretold = pool.slice(0, count).map(func(d: TowerData) -> String: return d.get_id())
	if foretold.is_empty():
		return  # Every family offered: nothing to foretell
	var names: Array = foretold.map(func(id: String) -> String:
		var data := families.filter(func(d: TowerData) -> bool: return d.get_id() == id)
		return data[0].display_name if not data.is_empty() else id.capitalize())
	_foretold_line.text = "Next pick (drift %d): %s" % [drift, ", ".join(names)]
	_foretold_line.visible = true

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
	_subtitle.visible = false  # Not a family
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
			["It doesn't attack. After every drift it yields %d Dew, +%d per rank, and every %d drifts +1 Dreamlight. Nurture it for more; leaks wither it a little."
				% ([data.dew_per_drift, data.dew_per_rank, data.dreamlight_every] if data != null else [8, 4, 10]), 15, UiStyle.MOONLIGHT],  # From the data
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
		if pair[0] == "Take the Sapling":
			UiStyle.primary(button)  # The default (button rule)
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
	ChoiceCard.solid(button)  # Hides the map behind it, as the Dream and Omen cards

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 20
	box.offset_top = 18
	box.offset_right = -20
	box.offset_bottom = -14
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	_fit_card(button, box)
	# Light pass: the emblem beside the name and its status chips; the job; the costs as an icon row; "dreams into, 2 of 5
	# this run" and the lanes; the framed "Wake …" at the foot (drawn: the whole card is the hit area).
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(header)
	var emblem := BranchEmblem.family(data)  # The family's emblem (UI Asset), else the base Warden's portrait
	if emblem != null or data.texture != null:
		var icon := TextureRect.new()
		icon.name = "FamilyEmblem" if emblem != null else "FamilyPortrait"
		if emblem != null:
			icon.texture = emblem
			icon.custom_minimum_size = Vector2(64, 64)  # ×2 of the 32 px emblem: crisp
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		else:
			var atlas := AtlasTexture.new()
			atlas.atlas = data.texture
			atlas.region = WardenIcon.visible_region(data)  # Centred by its drawn pixels
			icon.texture = atlas
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if emblem != null else TextureRect.STRETCH_KEEP_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		header.add_child(icon)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 6)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(names)
	var title := Label.new()
	title.name = "FamilyName"
	title.text = data.display_name
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.title(title, 26)
	names.add_child(title)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 6)
	chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.add_child(chips)
	for status in _statuses_of(data):
		chips.add_child(_status_chip(status))
	var job := Label.new()  # What it does, in its words
	job.name = "Job"
	job.text = IconInfo.format(data.description)
	job.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	job.mouse_filter = Control.MOUSE_FILTER_IGNORE
	job.add_theme_font_size_override("font_size", 15)
	job.add_theme_color_override("font_color", UiStyle.INK_DIM)
	box.add_child(job)
	var costs := HBoxContainer.new()  # "Sprout into it [Dew] 15   Plant [Dew] 25"
	costs.name = "Costs"
	costs.add_theme_constant_override("separation", 16)
	costs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(costs)
	for pair in [["Sprout into it", _sprout_into_cost(data)], ["Plant", data.cost]]:
		costs.add_child(_cost_part(pair[0], int(pair[1])))
	_add_routes(box, data)
	var spare := Control.new()
	spare.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spare.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(spare)
	var wake := Button.new()  # Drawn as the framed primary; the press is the card's
	wake.name = "Wake"
	wake.text = "Wake %s" % data.display_name
	wake.focus_mode = Control.FOCUS_NONE
	wake.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wake.custom_minimum_size.y = UiStyle.HUD_BUTTON_H
	# Secondary, like the Dream cards: no card is the default (the hovered card is the emphasis; story chat)
	ChoiceCard.link_cue(wake)  # Lights with the card (hover, press)
	box.add_child(wake)
	return button

# The statuses a family applies (its base Warden's), in order, once each.
# "Sprout into it": the live floor (Tower Code 526df9d7: growing a Sprout into a base pays at least the base's price minus
# the Sprout's), as an estimate before any Sprout is planted; the grow buttons show each Sprout's exact price.
func _sprout_into_cost(data: TowerData) -> int:
	var cost := dream_state.get_evolve_cost(data)
	var placer := get_node_or_null("%TowerPlacer")
	if placer != null and placer.has_method("get_cost"):
		cost = maxi(cost, int(placer.get_cost(data)) - int(placer.get_cost(SPROUT)))
	return cost

const SPROUT := preload("res://resource/tower/sprout.tres")

static func _statuses_of(data: TowerData) -> Array[StringName]:
	var out: Array[StringName] = []
	for status in [data.applies_status, data.extra_status]:
		if status != &"" and not out.has(status):
			out.append(status)
	return out

# A status as a chip: its icon and name in a thin outline.
func _status_chip(status: StringName) -> Control:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame := StyleBoxFlat.new()
	frame.draw_center = false
	frame.border_color = Color(UiStyle.MOON_MIST, 0.3)
	frame.set_border_width_all(1)
	frame.set_corner_radius_all(11)
	frame.content_margin_left = 8
	frame.content_margin_right = 8
	chip.add_theme_stylebox_override("panel", frame)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(row)
	var icon := TextureRect.new()
	icon.texture = IconInfo.icon(status)
	icon.custom_minimum_size = Vector2(16, 16)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var label := Label.new()
	label.text = IconInfo.status_name(status)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", UiStyle.INK_DIM)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	return chip

# "Plant [Dew] 25": the words quiet, the Dew glyph, the number in the number font.
func _cost_part(words: String, dew: int) -> Control:
	var part := HBoxContainer.new()
	part.add_theme_constant_override("separation", 5)
	part.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.text = words
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", UiStyle.INK_DIM)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	part.add_child(label)
	var icon := TextureRect.new()
	icon.texture = IconInfo.icon(&"dew")
	icon.custom_minimum_size = Vector2(14, 14)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	part.add_child(icon)
	var number := Label.new()
	number.text = str(dew)
	UiStyle.number(number, 16)
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	part.add_child(number)
	return part

# --- Routes (user, 2026-10-02: "when picking a family, it should show the family routes it can dream into") ---
# Under the base Warden: this run's branches (the same draw Remember shows: DreamState.preview_branch_offer), each
# → its final with a one-line role from its counter tags; the Grove's hidden branch as its own lane; the branches not
# in this dream as faint silhouettes that can be called in for Dreamlight. Hover / tap a lane: name, role, counters.
const ROUTE_ICON := 32.0  # Emblems are drawn for 32 px (UI Asset): crisp at ×1
const NOT_IN_DREAM_ICON := 20.0

# {"offered": Array[TowerData] (this run's lanes, the hidden branch last), "not_offered": Array[TowerData]}.
func get_routes(data: TowerData) -> Dictionary:
	var offered: Array[TowerData] = []
	var not_offered: Array[TowerData] = []
	var ids: Array = dream_state.preview_branch_offer(data)  # 2, or 3 with Wider Roots / a planted hidden branch: as Remember
	for form in data.evolves_to:
		var branch := form as TowerData
		if branch == null or branch.tier != 2:
			continue
		if ids.has(branch.get_id()):
			offered.append(branch)
		elif DreamState.branch_expansion_on() and dream_state.regular_branches(data).has(branch):
			not_offered.append(branch)
	offered.sort_custom(func(a: TowerData, b: TowerData) -> bool: return not dream_state.is_hidden_branch(a) and dream_state.is_hidden_branch(b))
	return {"offered": offered, "not_offered": not_offered}

# A branch's final form (its tier-3 growth), or null.
static func final_of(branch: TowerData) -> TowerData:
	for form in branch.evolves_to:
		if form is TowerData and form.tier == 3:
			return form
	return null

static func role_text(branch: TowerData) -> String:
	return IconInfo.role_text(branch)

static func counters_text(branch: TowerData) -> String:
	return IconInfo.counters_text(branch)

func _add_routes(box: VBoxContainer, data: TowerData) -> void:
	var routes := get_routes(data)
	var offered: Array = routes.offered
	if offered.is_empty():
		return
	# One caps line (light pass): "dreams into", and when the run draws from more, "dreams into, 2 of 5 this run"
	# (the branches are drawn per run: user via story chat; its tip says how to call another in).
	var regular: int = dream_state.regular_branches(data).size() if DreamState.branch_expansion_on() else 0
	var size: int = dream_state.branch_offer_size(data)
	var head := Label.new()
	head.name = "RoutesHead"
	head.text = "Dreams into" if regular <= size else OFFER_LINE % [size, regular]
	UiStyle.caps(head, 13, UiStyle.WHISPER)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(head)
	if regular > size:
		head.name = "OfferLine"
		head.mouse_filter = Control.MOUSE_FILTER_PASS
		head.tooltip_text = OFFER_TIP % dream_state.call_back_cost(data)
	for branch: TowerData in offered:
		box.add_child(_route_lane(branch))
	var missing: Array = routes.not_offered
	if not missing.is_empty():
		var row := HBoxContainer.new()
		row.name = "NotInDream"
		row.add_theme_constant_override("separation", 3)
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		row.modulate.a = 0.45  # multiplier: faint, "not in this dream"
		for branch: TowerData in missing:
			row.add_child(_icon(branch, NOT_IN_DREAM_ICON, true))
		var words := Label.new()
		words.text = "%d not in this dream" % missing.size()
		words.add_theme_font_size_override("font_size", 12)
		words.add_theme_color_override("font_color", UiStyle.INK_DIM)
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(words)
		row.tooltip_text = "%s: not in this dream. Call one in on Remember for %d Dreamlight." % [
			", ".join(missing.map(func(f: TowerData) -> String: return f.display_name)), dream_state.call_back_cost(data)]
		box.add_child(row)

# One lane: the branch (portrait, name, role). No final form (user, 2026-10-02: "don't show the final evolution in the
# card"; finals stay hidden until their branch is unlocked). Hover / tap: name, role and counters.
func _route_lane(branch: TowerData) -> Control:
	var lane := HBoxContainer.new()
	lane.name = "Route_" + branch.get_id()
	lane.set_meta(&"branch", branch)
	lane.add_theme_constant_override("separation", 6)
	lane.mouse_filter = Control.MOUSE_FILTER_PASS  # Tips on hover; a click still picks the card
	lane.add_child(_icon(branch, ROUTE_ICON, false))
	# The name, then the role under it: full names, wrapped in the card, never cut with "…"
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", -2)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_child(_lane_line(branch.display_name, 13, UiStyle.INK, "Name"))
	var role := role_text(branch)
	if dream_state.is_hidden_branch(branch):
		role = "Grove's hidden branch" + (", " + role if role != "" else "")
	if role != "":
		words.add_child(_lane_line(role, 11, UiStyle.GOLD, "Role"))
	lane.add_child(words)
	# One tip for the lane (its emblem and words ignore the mouse, so nothing stacks), saying each thing once: its name
	# and what it counters. The role is on the lane itself (user: "repeated explanations of the branch").
	var tip := branch.display_name
	if counters_text(branch) != "":
		tip += "\n" + counters_text(branch)
	elif role_text(branch) != "":
		tip += "\n" + role_text(branch).left(1).to_upper() + role_text(branch).substr(1)  # No counters: its job instead
	lane.tooltip_text = tip
	return lane

# "This dream offers 2 of 5 branches, different each run." Hover / tap: the call-in rule.
const OFFER_LINE := "Dreams into, %d of %d this run"  # Small caps lower it
const OFFER_TIP := "The others aren't in this dream. Call one in on Remember for %d Dreamlight, once per family."

func _offer_line(data: TowerData, size: int, regular: int) -> Label:
	var line := _lane_line(OFFER_LINE % [size, regular], 12, UiStyle.INK_DIM, "OfferLine")
	line.mouse_filter = Control.MOUSE_FILTER_PASS
	line.tooltip_text = OFFER_TIP % dream_state.call_back_cost(data)
	return line

# One line of a lane's words: wraps within the card (a long name takes two lines), never trimmed.
func _lane_line(text: String, size: int, colour: Color, node_name: String) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _icon(form: TowerData, side: float, silhouette: bool) -> TextureRect:
	var icon := TextureRect.new()
	var emblem := BranchEmblem.texture(form)  # The branch's emblem (UI Asset), else its Warden portrait
	icon.texture = emblem if emblem != null else _frame(form)
	icon.custom_minimum_size = Vector2(side, side)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if silhouette:
		icon.modulate = Color(0.35, 0.4, 0.55)  # multiplier: a misty silhouette, as on Remember
	return icon

# "Applies Spored" / "Applies Drowsy and Static": the statuses this family's base Warden puts on
# nightmares ("" = none).
static func get_status_text(data: TowerData) -> String:
	var names: Array[String] = []
	for status in [data.applies_status, data.extra_status]:
		if status != &"" and not names.has(IconInfo.status_name(status)):
			names.append(IconInfo.status_name(status))
	return "Applies " + " and ".join(names) if not names.is_empty() else ""

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
		atlas.region = WardenIcon.visible_region(data)  # Centred by its drawn pixels
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
