extends CanvasLayer

const DEW_COLOR := UiStyle.GOLD
const DEW_SHORT_COLOR := UiStyle.POOR
const UNAFFORDABLE_BUTTON_ALPHA := UiStyle.UNAFFORDABLE_ALPHA
const UNAFFORDABLE_SPRITE_ALPHA := 0.45  # An unaffordable slot: its Warden at this alpha, the tile itself full strength

# A 1 px Void shadow at 80% under a bar text (cost, key, "Clear"), as on whispers: it reads over sand and grass.
static func _shadowed(control: Control) -> void:
	control.add_theme_color_override("font_shadow_color", Color(Palette.VOID, 0.8))
	control.add_theme_constant_override("shadow_offset_x", 1)
	control.add_theme_constant_override("shadow_offset_y", 1)
# Warden bar slots (bottom centre): the HUD's hero, framed like every HUD button, a 48 px sprite and the
# cost (UiStyle.HUD_SLOT). They stay between the Warden panel and the drift controls: slots shrink to
# BUTTON_MIN_WIDTH (the 48 px touch minimum, platforms.md), then the bar wraps into more rows.
# Smaller, centred (user: "the tower bar should be centred, make it smaller then"): 48 px wide, the touch minimum.
const BUTTON_SIZE := Vector2(64, 84)  # Two steps up from 48 × 62 (user, twice: "the tower bar can be a bit bigger")
const SLOT_SPRITE := 48  # The Warden sprite in a slot (UiStyle.HUD_SPRITE size again)
const SLOT_COST_SIZE := 16  # The cost under the sprite
const SLOT_KEY_SIZE := 12  # The hotkey in the corner
const BUTTON_MIN_WIDTH := UiStyle.HUD_BUTTON_H
const BAR_GAP := 6  # Between slots and between rows
# Half-width taken from each side: the Warden panel (16–316 px) or the drift controls (272 px + 16),
# plus a small gap; the wider of the two, so the centred bar clears both.
const BAR_CLEARANCE := 336.0
const SPROUT_ID := "sprout"
const CLEAR_TOOL_GAP := 10.0
const SEED_COLOR := Palette.SPRIG
const COUNTER_ICON_GAP := 8.0  # Icon to number (UI Code: pairs group, counters stand apart)
const COUNTER_ICON := 24.0  # Resource icons (the mock's .pxi 24 px; user: "the icons on the right seem too big")
const BUTTON_GLYPH := 20  # The top-right buttons' icons and glyphs
const HUD_COUNTER_ICONS := {&"dew": &"dew_hud", &"dreamlight": &"dreamlight_hud", &"leaves": &"leaf_hud", &"path_length": &"path_hud"}
const HUD_GLYPHS := {&"MenuButton": &"menu_hud", &"CodexButton": &"help_hud", &"BuffLensButton": &"boosts_hud", &"RememberButton": &"remember_hud"}
const BUTTON_BOX_INSET := 6.0  # Their visible box: ~36 px inside the 48 px hit area

@onready var tower_bar: HBoxContainer = %TowerBar  # One row by construction (user: "should not stack")
@onready var tower_placer: TowerPlacer = %TowerPlacer
@onready var dew_label: Label = %DewLabel
@onready var leaves_label: Label = %LeavesLabel
@onready var toast_label: Label = %ToastLabel
@onready var run_state: RunState = %RunState
@onready var drift_director: DriftDirector = %DriftDirector

const LEAVES_COLOR := UiStyle.GOLD  # The value; its max "/15" is dim (the mock)
const DREAMLIGHT_COLOR := UiStyle.GOLD
# The top-right buttons sit in one row directly under the resources, right-aligned (_layout_top_row):
# [Remember][Buffs][?][Menu], Remember nearest the Dreamlight counter.
# (They used to share the top row with the resources, which ran into the drift banner at 1280 wide.)
# Each is [right, width] from the screen's right edge; all TOP_BUTTON_H tall (touch: 48).
const TOP_BUTTONS_Y := 128.0  # Directly under the resources (their fog patch ends at y 124)
const TOP_BUTTON_H := UiStyle.HUD_BUTTON_H
# Compact HudButtons (small caps at the HUD text size, the thin frame), not big boxes (user,
# 2026-09-30: "the Remember etc tabs look out of place").
const MENU_SLOT := [-16.0, 84.0]
const REMEMBER_SLOT := [-106.0, 124.0]
const BUFFS_SLOT := [-236.0, 76.0]
const CODEX_SLOT := [-318.0, 48.0]
const LEAF_LOST_COLOR := UiStyle.POOR
const TOAST_TIME := 2.5

@onready var dream_state: DreamState = %DreamState
var bark_shield: DreamMarks.BarkShield = null  # Thick Bark (DreamMarks)

# One toggle button per plantable Warden (unlocked this run), in roster order; `_bar_towers` matches.
var _tower_buttons: Array[Button] = []
var _seed_badge: Control = null  # On the Sprout button
var clear_tool: ClearToolButton  # Left of the Warden bar, CLEAR_TOOL_GAP apart
var _bar_towers: Array[TowerData] = []
var _dew_flash: Tween
var _leaf_flash: Tween
var _toast_tween: Tween
var _counter_icons := {}  # Label -> its icon (TextureRect)

func _ready() -> void:
	UiStyle.install_tooltip_wrap(get_tree())  # Long tooltips wrap at the tip width (also when main runs alone)
	# The Clear tool sits at the left end of the Warden bar, set apart (screens_ui.md "The Clear tool").
	# (A sibling of %TowerBar, placed and sized with it in _fit_tower_bar.)
	_style_resources()
	clear_tool = ClearToolButton.new()
	clear_tool.setup(%ObstacleClearer, run_state, show_toast)
	clear_tool.anchor_left = 0.5
	clear_tool.anchor_right = 0.5
	clear_tool.anchor_top = 1.0
	clear_tool.anchor_bottom = 1.0
	add_child(clear_tool)
	_build_tower_bar()
	get_viewport().size_changed.connect(_fit_tower_bar)
	# New Wardens unlocked by Dreams appear in the bar (and prices can change).
	dream_state.unlocks_changed.connect(_build_tower_bar)
	# The Sprout price follows the Sprouts on the map (planted, sold, grown): refresh the bar after each.
	# One refresh per frame however many Wardens come and go, and none while the run is being freed (Environment Code:
	# freeing a run with many Wardens queued one per Warden and overflowed the stack).
	tower_placer.tower_container.child_entered_tree.connect(_queue_price_refresh.unbind(1))
	tower_placer.tower_container.child_exiting_tree.connect(_queue_price_refresh.unbind(1))
	# Keep the buttons in sync when build mode is toggled with B / cancelled with Esc or right-click.
	tower_placer.build_mode_changed.connect(_sync_buttons.unbind(1))

	run_state.sprout_charges_changed.connect(_update_seed_badge)
	run_state.dew_changed.connect(_on_dew_changed)
	run_state.dew_short.connect(_on_dew_short.unbind(1))
	dream_state.dreamlight_short.connect(_on_dreamlight_short.unbind(1))
	_on_dew_changed(run_state.dew)

	run_state.leaves_changed.connect(_on_leaves_changed)
	_on_leaves_changed(run_state.leaves, run_state.max_leaves)
	_add_dreamlight_counter()
	_add_menu_button()
	_add_buff_lens_button()
	_add_remember_button()
	# "Coming this block" (top centre, under the drift banner) and the new-nightmare introduction
	# card (before the dossier in the rest order), both from screens_ui.md.
	var strip := ComingStrip.new(drift_director)
	add_child(strip)
	var intro := NightmareIntro.new(drift_director)
	add_child(intro)
	intro.name = "NightmareIntro"
	# Boss dossier (screens_ui.md): under the pause menu, above the rest of the HUD.
	var dossier := BossDossier.new(drift_director)
	add_child(dossier)
	dossier.name = "BossDossier"
	# Damage that means something (screens_ui.md): the drift meter (right edge) and DPS tags (world).
	var drift_meter := DriftMeter.new(drift_director)
	drift_meter.name = "DriftMeter"
	add_child(drift_meter)
	owner.add_child.call_deferred(DpsTags.new())
	# Close calls (run_design.md): a nightmare past 85% of the route trembles the Heartwood (world).
	var close_calls := CloseCalls.new()
	close_calls.name = "CloseCalls"
	owner.add_child.call_deferred(close_calls)
	var start_arrows := StartArrows.new()  # Route arrows, start to Heartwood, until the first drift (world)
	start_arrows.name = "StartArrows"
	owner.add_child.call_deferred(start_arrows)
	var rule_breakers := RuleBreakers.new(drift_director)  # New flyers / sprinters…: the dashed path and name plates (world)
	rule_breakers.name = "RuleBreakers"
	owner.add_child.call_deferred(rule_breakers)
	var mist_count := MistCount.new(drift_director)  # "+N" waiting in the start mist (the field cap)
	mist_count.name = "MistCount"
	owner.add_child.call_deferred(mist_count)
	# The Codex's Dreams: every card offered is seen on the account (DreamCodex).
	add_child(DreamCodex.new(dream_state, run_state))
	# The Codex's Nightmares: lifetime dispels per kind and the "Know every nightmare" milestone.
	add_child(NightmareCodex.new(drift_director))
	# The run history (balance_simulation.md "Run history"): saved at every run end, shown in the Codex.
	add_child(RunHistory.new(drift_director))
	_raise_overlays.call_deferred()  # After everything above (and deferred adds) is in
	# Resist / weak pips and the immune flash, drawn in the world over the nightmares.
	owner.add_child.call_deferred(ResistPips.new())
	# Touch: Plant / Cancel for a pending drag-to-build stroke, two-finger pan and pinch (TouchBuild).
	add_child(TouchBuild.new(tower_placer, owner.get_node_or_null("GameCameraNode")))
	# Dream card marks: Heart of the Maze's heart (world), Thick Bark's shield by the leaves.
	owner.add_child.call_deferred(DreamMarks.new())
	bark_shield = DreamMarks.BarkShield.new(leaves_label)
	leaves_label.add_child(bark_shield)
	if dream_state.has_signal("bark_changed"):
		dream_state.connect("bark_changed", bark_shield.set_charges)
		bark_shield.set_charges.call_deferred(int(dream_state.get("bark_charges")))
	# Every resource explains itself on hover and tap (screens_ui.md "Stat and status icons").
	TapTip.attach(dew_label, IconInfo.resource_tooltip(&"dew"))
	TapTip.attach(leaves_label, IconInfo.resource_tooltip(&"leaves"))
	TapTip.attach(%PathLabel, IconInfo.resource_tooltip(&"path"))
	dream_state.card_taken.connect(func(card: UpgradeData) -> void: show_toast("Dreamed: %s" % card.display_name))
	# Feeling the cards (dream_design.md): a pick from an offer blooms on the Wardens it affects, and the toast says
	# what it does on the board ("Cozy Corners · 6 Wardens +30%"), right after the "Dreamed" one.
	owner.add_child.call_deferred(CardBloom.new())
	# Grow onboarding (onboarding.md): ↑ / dot marks at rests, the first-grow spotlight, the drift 15 reminder (world).
	owner.add_child.call_deferred(GrowHints.new(drift_director))
	# Heartwood's Gifts (heartwood_gifts.md, Spire): the act-break gift and its screen.
	var gifts := HeartwoodGifts.new(drift_director)
	add_child(gifts)
	add_child(GiftScreen.new(drift_director, gifts))
	if dream_state.has_signal("card_chosen"):
		dream_state.connect("card_chosen", func(_card: UpgradeData, _towers: Array, impact: String) -> void:
			if impact.contains(" · "):  # A card with no effect yet sends just its name: "Dreamed: X" stays
				show_impact_toast(impact))
	drift_director.rest_started.connect(_on_rest_started)
	# Path length ("Wardens are walls: make their walk longer").
	var map_generator = %MapGenerator
	var path_label: Label = %PathLabel
	var update_path := func() -> void:
		path_label.text = str(map_generator.route_length(map_generator.get_path_from(map_generator.startPath)))  # Cells (route points step by half a cell)
		_place_counter_icon(path_label)
	map_generator.path_changed.connect(update_path)
	update_path.call()
	drift_director.act_started.connect(_on_act_started)
	# Half-price clears (Heartwood's Reach; clearing always costs Dew), under the path length; hidden when there are none.
	var clears_label := path_label.duplicate() as Label
	clears_label.unique_name_in_owner = false
	clears_label.offset_top = TOP_BUTTONS_Y + TOP_BUTTON_H + 6.0  # Under the button row (it shows only with free clears)
	clears_label.offset_bottom = clears_label.offset_top + (path_label.offset_bottom - path_label.offset_top)
	clears_label.tooltip_text = "Half-price clears: tending a tree or moving a rock costs half (never less than half its base price)."
	UiStyle.number(clears_label, 16, UiStyle.GOLD)  # A small line under the patch (it was title-size: user)
	clears_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	clears_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(clears_label)
	_clears_label = clears_label
	var update_clears := func(n: int) -> void:
		clears_label.text = "%d" % n  # The icon (left of it) says what it counts; the tooltip explains
		clears_label.visible = n > 0
	run_state.free_clears_changed.connect(update_clears)
	update_clears.call(run_state.free_clears)
	var spawner = %EnemyContainer
	spawner.enemy_cleansed.connect(func(enemy: Node2D) -> void:
		if enemy.enemy_data.cleanse_line != "":
			show_toast(enemy.enemy_data.cleanse_line))
	spawner.wall_trampled.connect(func(_cell: Vector2, by: Node2D) -> void:
		show_toast("%s tramples a Thornwall!" % IconInfo.the_name(by.enemy_data.display_name, true)))
	toast_label.modulate.a = 0.0
	# Counters are icon + number (ui_style.md, the mock); the words stay in their tooltips.
	_add_counter_icon(dew_label, &"dew", 2)
	_add_counter_icon(get_node("DreamlightLabel"), &"dreamlight", 2)
	_add_counter_icon(leaves_label, &"leaves", 2)
	_add_counter_icon(%PathLabel, &"path_length", 2)
	_add_counter_icon(_clears_label, &"dew_cost", 1)  # Half-price clears: the cost icon, 16 px

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("buff_lens"):  # V: the buff lens on / off (a toggle, for touch too)
		buff_lens_button.button_pressed = not buff_lens_button.button_pressed
		get_viewport().set_input_as_handled()
		return
	# Number keys 1-9 pick a Warden.
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var index := key.physical_keycode - KEY_1
	if index >= 0 and index < mini(_tower_buttons.size(), 9):
		_on_tower_pressed(_bar_towers[index])
		get_viewport().set_input_as_handled()

func _build_tower_bar() -> void:
	for button in _tower_buttons:
		tower_bar.remove_child(button)
		button.queue_free()
	_tower_buttons.clear()
	_bar_towers = tower_placer.get_buildable_towers()
	for i in _bar_towers.size():
		var data: TowerData = _bar_towers[i]
		# The Warden's icon on top, the Dew cost under it, the hotkey number in the top-left corner (family
		# emblems were tried and removed, user 2026-09-30: screens_ui.md "Family icons on the Warden bar").
		var button := Button.new()
		button.name = "Warden_" + data.get_id()
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.icon = _tower_icon(data)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.add_theme_constant_override("icon_max_width", SLOT_SPRITE)
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # Pixel art stays crisp
		button.expand_icon = true  # The sprite fits the slot (above the cost), never taller than it
		button.theme_type_variation = &"WardenSlot"  # The HUD button frame; selected = the gold border
		button.add_theme_font_size_override("font_size", SLOT_COST_SIZE)
		_shadowed(button)  # Reads over the bright path (user screenshot)
		button.custom_minimum_size = BUTTON_SIZE
		# Hover (long-press on touch) shows the Warden card (WardenHeaderView + price), not a plain tooltip.
		button.set_meta(&"price_line", "Cost: %d Dew · key %s" % [tower_placer.get_cost(data), str(i + 1) if i < 9 else "none"])
		button.mouse_entered.connect(_show_hover_card.bind(button, data))
		button.mouse_exited.connect(_hide_hover_card.bind(button))
		button.button_down.connect(_on_slot_down.bind(button, data))
		button.button_up.connect(_hide_hover_card.bind(button))
		button.pressed.connect(_on_tower_pressed.bind(data))
		if i < 9:
			var hotkey := Label.new()
			hotkey.name = "Hotkey"
			hotkey.text = str(i + 1)
			hotkey.position = Vector2(3, 0)
			hotkey.mouse_filter = Control.MOUSE_FILTER_IGNORE
			UiStyle.number(hotkey, SLOT_KEY_SIZE, Color(UiStyle.MOON_MIST, 0.6))
			_shadowed(hotkey)
			hotkey.add_theme_color_override("font_outline_color", UiStyle.FOG)
			hotkey.add_theme_constant_override("outline_size", 3)
			button.add_child(hotkey)
		if data.get_id() == SPROUT_ID:
			button.add_child(_make_seed_badge())
		tower_bar.add_child(button)
		_tower_buttons.append(button)
	_sync_buttons()
	_on_dew_changed(run_state.dew)
	_update_seed_badge(run_state.sprout_charges)
	_fit_tower_bar()

# The bar is centred at the bottom and must stay clear of the Warden panel (left) and the drift
# controls (right). It is always ONE row (user: "the tower bar should not stack like this"): the Clear
# slot first, then the Wardens in key order. Slots shrink evenly to SLOT_MIN_WIDTH; past that the bar
# shows a window of slots with ‹ › arrows at its ends (hotkeys still reach every Warden).
const SLOT_MIN_WIDTH := 48.0
const ARROW_W := 32.0  # Narrow and quiet
var _bar_offset := 0  # The first Warden shown when the bar scrolls
var _bar_arrows: Array[Button] = []

func _fit_tower_bar() -> void:
	if _tower_buttons.is_empty():
		return
	var room := get_viewport().get_visible_rect().size.x - BAR_CLEARANCE * 2.0
	var n := _tower_buttons.size()
	var width := floorf((room - CLEAR_TOOL_GAP - BAR_GAP * (n - 1)) / (n + 1))
	var shown := n
	if width < SLOT_MIN_WIDTH:
		width = SLOT_MIN_WIDTH
		var inner := room - 2.0 * (ARROW_W + BAR_GAP)  # The arrows take their room first
		shown = clampi(floori((inner - width - CLEAR_TOOL_GAP + BAR_GAP) / (width + BAR_GAP)), 1, n)
	width = minf(width, BUTTON_SIZE.x)
	_bar_offset = clampi(_bar_offset, 0, n - shown)
	var icon := mini(SLOT_SPRITE, int(width) - 12)
	for i in n:
		var button: Button = _tower_buttons[i]
		button.custom_minimum_size = Vector2(width, BUTTON_SIZE.y)
		button.add_theme_constant_override("icon_max_width", icon)
		button.visible = i >= _bar_offset and i < _bar_offset + shown
		if button == _seed_badge_button():
			_seed_badge.position.x = width - 14
	clear_tool.add_theme_constant_override("icon_max_width", icon)
	clear_tool.add_theme_font_size_override("font_size", SLOT_COST_SIZE)  # Its caption and key as a Warden slot's cost and key
	clear_tool.add_theme_color_override("font_color", UiStyle.MOON_MIST)  # Mist, not dim Slate (UI Asset)
	_shadowed(clear_tool)
	var clear_key := clear_tool.get_node_or_null("Hotkey") as Label
	if clear_key != null:
		UiStyle.number(clear_key, SLOT_KEY_SIZE, Color(UiStyle.MOON_MIST, 0.6))
		_shadowed(clear_key)
	clear_tool.custom_minimum_size = Vector2(width, BUTTON_SIZE.y)  # Exactly a Warden slot (user: not a different size)
	# Centre the tool + bar (+ arrows) from the computed widths (the container only re-sorts its children
	# next frame), one row, 16 px above the bottom.
	var scrolling := shown < n
	var bar_width := width * shown + BAR_GAP * (shown - 1)
	var arrows_w := (ARROW_W + BAR_GAP) * 2.0 if scrolling else 0.0
	var total := width + CLEAR_TOOL_GAP + bar_width + arrows_w
	var left := -total / 2.0
	clear_tool.offset_left = left
	clear_tool.offset_right = left + width
	clear_tool.offset_bottom = -16.0
	clear_tool.offset_top = -16.0 - BUTTON_SIZE.y
	var bar_left := left + width + CLEAR_TOOL_GAP + (ARROW_W + BAR_GAP if scrolling else 0.0)
	tower_bar.offset_left = bar_left
	tower_bar.offset_right = bar_left + bar_width
	tower_bar.offset_bottom = -16.0
	tower_bar.offset_top = -16.0 - BUTTON_SIZE.y
	_place_bar_arrows(scrolling, bar_left, bar_left + bar_width, n - shown)
	if is_inside_tree() and not get_tree().process_frame.is_connected(_recentre_bar):
		get_tree().process_frame.connect(_recentre_bar, CONNECT_ONE_SHOT)

# The bar is laid out from computed widths; if the slots' real minimum size is wider (a cost or sprite), the HBox grows
# to the right and the group drifts off-centre (user: "Tower bar isn't centred still"). Next frame, from what is drawn:
# shift the whole group (Clear tool, bar, arrows) so its middle is the screen's middle.
func _recentre_bar() -> void:
	if not is_instance_valid(tower_bar) or not tower_bar.is_visible_in_tree():
		return
	var parts: Array[Control] = [clear_tool, tower_bar]
	for arrow in _bar_arrows:
		if arrow.visible:
			parts.append(arrow)
	var group := tower_bar.get_global_rect()
	for part in parts:
		if part.visible:
			group = group.merge(part.get_global_rect())
	var shift := get_viewport().get_visible_rect().get_center().x - group.get_center().x
	if absf(shift) < 0.5:
		return
	for part in parts:
		part.offset_left += shift
		part.offset_right += shift

func _place_bar_arrows(scrolling: bool, bar_left: float, bar_right: float, hidden: int) -> void:
	if _bar_arrows.is_empty():
		for pair in [["‹", -1], ["›", 1]]:
			var arrow := Button.new()
			arrow.name = "BarArrowLeft" if pair[1] < 0 else "BarArrowRight"
			arrow.text = pair[0]
			arrow.focus_mode = Control.FOCUS_NONE
			arrow.theme_type_variation = &"WardenSlot"  # The bar's ends in the slots' own frame, never stronger than the Wardens (UI Asset)
			arrow.add_theme_font_size_override("font_size", 22)
			arrow.anchor_left = 0.5
			arrow.anchor_right = 0.5
			arrow.anchor_top = 1.0
			arrow.anchor_bottom = 1.0
			arrow.tooltip_text = "More Wardens"
			var step: int = pair[1]
			arrow.pressed.connect(func() -> void:
				_bar_offset += step
				_fit_tower_bar())
			add_child(arrow)
			_bar_arrows.append(arrow)
	for i in 2:
		var arrow := _bar_arrows[i]
		arrow.visible = scrolling
		var x := bar_left - BAR_GAP - ARROW_W if i == 0 else bar_right + BAR_GAP
		arrow.offset_left = x
		arrow.offset_right = x + ARROW_W
		arrow.offset_bottom = -16.0
		arrow.offset_top = -16.0 - BUTTON_SIZE.y
		arrow.disabled = (i == 0 and _bar_offset <= 0) or (i == 1 and _bar_offset >= hidden)

func _seed_badge_button() -> Button:
	return _seed_badge.get_parent() as Button if is_instance_valid(_seed_badge) else null

# Seedling Gift (Roguelite's `RunState.sprout_charges`): free Sprouts, shown as a seed with the
# count in the Sprout button's top-right corner; hidden at 0.
func _make_seed_badge() -> Control:
	_seed_badge = Control.new()
	_seed_badge.name = "SeedBadge"
	_seed_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_seed_badge.position = Vector2(BUTTON_SIZE.x - 14, 2)
	_seed_badge.draw.connect(func() -> void:
		_seed_badge.draw_set_transform(Vector2(0, 7), -0.5, Vector2(0.7, 1.0))
		_seed_badge.draw_circle(Vector2.ZERO, 6.0, Palette.ROOT)
		_seed_badge.draw_circle(Vector2.ZERO, 4.5, SEED_COLOR)
		_seed_badge.draw_set_transform(Vector2.ZERO)
		var font := ThemeDB.fallback_font
		var text := str(run_state.sprout_charges)
		_seed_badge.draw_string_outline(font, Vector2(-2, 22), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 4, Palette.DREAD)
		_seed_badge.draw_string(font, Vector2(-2, 22), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, SEED_COLOR.lightened(0.3)))
	return _seed_badge

func _update_seed_badge(charges: int) -> void:
	if is_instance_valid(_seed_badge):
		_seed_badge.visible = charges > 0
		_seed_badge.queue_redraw()

# Selecting the tower that's already being built leaves build mode; any other enters it.
func _on_tower_pressed(data: TowerData) -> void:
	if tower_placer.build_mode and tower_placer.tower_data == data:
		tower_placer.set_build_mode(false)
	else:
		tower_placer.select_tower(data)
	_sync_buttons()

func _sync_buttons() -> void:
	for i in _tower_buttons.size():
		var selected := tower_placer.build_mode and _bar_towers[i] == tower_placer.tower_data
		_tower_buttons[i].set_pressed_no_signal(selected)

var _prices_pending := false

func _queue_price_refresh() -> void:
	if _prices_pending or not is_inside_tree() or is_queued_for_deletion():
		return
	_prices_pending = true
	(func() -> void:
		_prices_pending = false
		if is_inside_tree() and not is_queued_for_deletion():
			_on_dew_changed(run_state.dew)).call_deferred()

func _on_dew_changed(dew: int) -> void:
	dew_label.text = str(dew)
	_place_counter_icon(dew_label)
	# Fade out Wardens the player can't afford right now (still selectable, the ghost shows red).
	# (Costs can change with Dreams, so the cost text is refreshed here too.)
	for i in _tower_buttons.size():
		var cost := tower_placer.get_cost(_bar_towers[i])
		var affordable := run_state.can_afford(cost)
		# Only when something changed: rewriting text / theme on every Dew change (each dispel) would
		# reset a hovered button's tooltip (screens_ui.md "Hover and tap tips").
		var bar_state := "%d:%s:%d" % [cost, affordable, tower_placer.count_paid_sprouts() if _bar_towers[i].get_id() == SPROUT_ID else 0]
		if _tower_buttons[i].get_meta(&"bar_state", "") == bar_state:
			continue
		_tower_buttons[i].set_meta(&"bar_state", bar_state)
		_tower_buttons[i].text = str(cost)
		_tower_buttons[i].set_meta(&"price_line", "Cost: %d Dew" % cost)
		if _bar_towers[i].get_id() == SPROUT_ID:
			_update_sprout_rule(_tower_buttons[i], cost)
		# The slot stays a dark, readable tile; only the Warden dims (UI Asset: the whole slot faded into the path).
		_tower_buttons[i].modulate.a = 1.0
		UiStyle.slot_short(_tower_buttons[i], not affordable)  # A Slate border when it can't be paid for (the press still refuses)
		for state in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color", "icon_focus_color"]:
			if affordable:
				_tower_buttons[i].remove_theme_color_override(state)
			else:
				_tower_buttons[i].add_theme_color_override(state, Color(1, 1, 1, UNAFFORDABLE_SPRITE_ALPHA))  # multiplier: the sprite dims
		# Colour is never alone (ui_style.md): faded AND the cost in red.
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			if affordable:
				_tower_buttons[i].remove_theme_color_override(state)
			else:
				_tower_buttons[i].add_theme_color_override(state, UiStyle.POOR)

# Tried to spend Dew we don't have: flash the counter red and give it a little shake.
func _on_dew_short() -> void:
	if _dew_flash:
		_dew_flash.kill()
	dew_label.pivot_offset = dew_label.size / 2
	dew_label.add_theme_color_override("font_color", DEW_SHORT_COLOR)
	_dew_flash = create_tween()
	for offset in [-6.0, 6.0, -4.0, 4.0, 0.0]:
		_dew_flash.tween_property(dew_label, "rotation_degrees", offset * 0.5, 0.04)
	_dew_flash.tween_interval(0.25)
	_dew_flash.tween_callback(dew_label.add_theme_color_override.bind("font_color", DEW_COLOR))

# Tried to unlock a form without enough Dreamlight: the same flash and shake on the Dreamlight counter.
func _on_dreamlight_short() -> void:
	CantAfford.flash_counter(get_node_or_null("DreamlightLabel") as Label, DREAMLIGHT_COLOR)  # The Remember screen's flash

# The pause menu on screen (screens_ui.md "Top right: … Menu"; platforms.md: Esc is only a
# shortcut), left of the resources.
func _add_menu_button() -> void:
	var button := Button.new()
	button.name = "MenuButton"
	button.text = "≡"  # An icon button; the name is in the tooltip (Moonlit mock)
	button.tooltip_text = "Pause menu (Esc)"
	button.focus_mode = Control.FOCUS_NONE
	_place_top_button(button, MENU_SLOT)
	button.pressed.connect(func() -> void:
		var pause := get_node_or_null("%PauseMenu")
		if pause != null and not pause.visible and not run_state.is_over:
			pause.open())
	add_child(button)
	# The Codex ("?", screens_ui.md "The Codex"), just left of Menu.
	var codex := button.duplicate() as Button
	codex.name = "CodexButton"
	codex.text = "?"
	codex.tooltip_text = "Codex: glossary and combos"
	_place_top_button(codex, CODEX_SLOT)
	codex.pressed.connect(func() -> void:
		var pause := get_node_or_null("%PauseMenu")
		if pause != null and not run_state.is_over:
			pause.open_codex())
	add_child(codex)

# Dreamlight (run_design.md "Dreamlight"): its icon and the count, just left of the Dew.
func _add_dreamlight_counter() -> void:
	var label := dew_label.duplicate() as Label
	label.unique_name_in_owner = false
	label.name = "DreamlightLabel"
	label.offset_right = dew_label.offset_right - 150
	label.offset_left = label.offset_right - 110
	label.add_theme_color_override("font_color", DREAMLIGHT_COLOR)
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	# Tap / click shows the same text as the tooltip, at the counter (platforms.md: no hover-only
	# information; a top-centre toast read as a misplaced tooltip).
	dreamlight_tip = TapTip.attach(label, IconInfo.resource_tooltip(&"dreamlight"))
	dream_state.dreamlight_changed.connect(func(amount: int) -> void:
		dreamlight_tip._label.text = "%s (%d)" % [IconInfo.resource_tooltip(&"dreamlight"), amount])
	add_child(label)
	var update := func(amount: int) -> void:
		label.text = str(amount)
		_place_counter_icon(label)
	dream_state.dreamlight_changed.connect(update)
	update.call(dream_state.dreamlight)

var _shown_leaves := -1

func _on_leaves_changed(leaves: int, max_leaves: int) -> void:
	leaves_label.text = str(leaves)
	_leaves_max.text = "/%d" % max_leaves
	_place_counter_icon(leaves_label)
	if bark_shield != null and bark_shield.visible:
		bark_shield._place.call_deferred()  # The text width changed
	var lost := _shown_leaves >= 0 and leaves < _shown_leaves
	_shown_leaves = leaves
	if not lost:
		return
	# A creature reached the Heartwood: flash the leaves orange.
	if _leaf_flash:
		_leaf_flash.kill()
	leaves_label.add_theme_color_override("font_color", LEAF_LOST_COLOR)
	_leaf_flash = create_tween()
	# The leaves counter shakes as well as flashing (screens_ui.md "Leak"), unless reduced motion.
	if not HeartwoodMemory.get_settings().get("reduced_motion", false):
		leaves_label.pivot_offset = leaves_label.size / 2
		for offset in [-5.0, 5.0, -3.0, 3.0, 0.0]:
			_leaf_flash.tween_property(leaves_label, "rotation_degrees", offset, 0.04)
	_leaf_flash.tween_interval(0.4)
	_leaf_flash.tween_callback(leaves_label.add_theme_color_override.bind("font_color", LEAVES_COLOR))

func _on_rest_started(_block: int, _is_boss_rest: bool, bonus: int, perfect: bool) -> void:
	var text := "Rest · +%d Dew" % bonus
	if perfect:
		text += " · perfect block"
	show_toast(text)

func _on_act_started(act: int, leaves_regrown: int) -> void:
	var text := "Act %d: %s" % [act, drift_director.get_act_name(act)]
	if leaves_regrown > 0:
		text += "\nThe Heartwood regrows %d leaves" % leaves_regrown
	show_toast(text)

# A pixel icon (IconInfo, whole-number scale) just left of a right-aligned counter's text.
func _add_counter_icon(label: Label, id: StringName, scale: int) -> void:
	var icon := TextureRect.new()
	icon.name = "CounterIcon"
	# The row's counters use the 12 px HUD icons at exactly ×2 (UI Asset 93963da1), the rest the 16 px set.
	var hud_tex: Texture2D = IconInfo.hud_icon(HUD_COUNTER_ICONS[id]) if scale >= 2 and HUD_COUNTER_ICONS.has(id) else null
	icon.texture = hud_tex if hud_tex != null else IconInfo.icon(id)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.size = Vector2(COUNTER_ICON, COUNTER_ICON) if scale >= 2 else Vector2(16, 16) * scale  # The mock: 24 px beside 28 px numbers
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE  # The label's own tooltip / tap explains it
	label.add_child(icon)
	label.set_meta(&"icon_width", icon.size.x + COUNTER_ICON_GAP)  # DreamMarks' shield goes left of it
	_counter_icons[label] = icon
	label.resized.connect(_place_counter_icon.bind(label))
	_place_counter_icon(label)

func _place_counter_icon(label: Label) -> void:
	var icon: TextureRect = _counter_icons.get(label)
	if icon == null:
		return
	var width := label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		label.get_theme_font_size("font_size")).x
	icon.position = Vector2(label.size.x - width - icon.size.x - COUNTER_ICON_GAP, (label.size.y - icon.size.y) / 2.0)

# Moonlit Thread (ui_style.md): the resources sit on a fog patch (no thread: they hug the screen
# edge), numbers in Cormorant with lining figures.
func _style_resources() -> void:
	var fog := Panel.new()
	fog.name = "ResourcesFog"
	var patch := UiStyle.fog_patch()
	patch.center_alpha = 0.8  # Darker fog, never smaller text: readable over a bright map (ui_style.md)
	fog.add_theme_stylebox_override("panel", patch)
	fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fog.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	fog.offset_left = -300.0
	fog.offset_right = -4.0
	fog.offset_top = 4.0
	fog.offset_bottom = 124.0
	add_child(fog)
	move_child(fog, 0)
	UiStyle.number(dew_label, 28, DEW_COLOR)
	UiStyle.number(leaves_label, 28, LEAVES_COLOR)
	_leaves_max.name = "LeavesMax"
	UiStyle.number(_leaves_max, 20, UiStyle.INK_DIM)
	_leaves_max.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_leaves_max.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_leaves_max.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_leaves_max)
	UiStyle.number(%PathLabel, 28, UiStyle.INK_DIM)
	for label: Label in [dew_label, leaves_label, %PathLabel]:
		label.add_theme_color_override("font_outline_color", UiStyle.FOG)
		label.add_theme_constant_override("outline_size", 4)
	UiStyle.title(toast_label, 22)
	toast_label.add_theme_color_override("font_outline_color", UiStyle.FOG)

# Shows a message at the top of the screen for a few seconds.
var impact_label: Label  # The card toast's own label (UiStyle.impact_toast), in the toast's place
var _impact_tween: Tween

# "Cozy Corners · 6 Wardens +30%" after a Dream is taken (dream_design.md "Feeling the cards"), in UI Code's
# impact face, replacing the plain "Dreamed" toast.
func show_impact_toast(text: String) -> void:
	if impact_label == null:
		impact_label = toast_label.duplicate() as Label
		impact_label.name = "ImpactToast"
		UiStyle.impact_toast(impact_label)
		toast_label.add_sibling(impact_label)
	if _toast_tween:
		_toast_tween.kill()
	toast_label.modulate.a = 0.0
	if _impact_tween:
		_impact_tween.kill()
	impact_label.text = text
	impact_label.modulate.a = 1.0
	_impact_tween = create_tween()
	_impact_tween.tween_interval(TOAST_TIME)
	_impact_tween.tween_property(impact_label, "modulate:a", 0.0, 0.6)

func show_toast(text: String) -> void:
	if _toast_tween:
		_toast_tween.kill()
	if impact_label != null and _impact_tween:  # A newer message takes the place
		_impact_tween.kill()
		impact_label.modulate.a = 0.0
	toast_label.text = text
	toast_label.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(TOAST_TIME)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.6)

# First idle frame of the tower's sheet.
func _tower_icon(data: TowerData) -> Texture2D:
	return WardenIcon.make_centred(data)  # Centred by its drawn pixels at its usual size; the Sapling cropped to the bottom centre

# --- Remember (run_design.md "The Remember screen, fleshed out") ----------------------------------
# Top right beside the Dreamlight counter, always there: opens the Remember screen (DreamState
# .open_remember; the screen is Roguelite's). It glows while something can be unlocked with the
# Dreamlight you have (DreamState.can_unlock). The screen pauses mid-drift and restores it on close.

var remember_button := Button.new()
var dreamlight_tip: TapTip  # The Dreamlight counter's tap tip
var _remember_glow := 0.0

func _add_remember_button() -> void:
	remember_button.name = "RememberButton"
	remember_button.text = "✦"
	remember_button.tooltip_text = "Remember: spend Dreamlight on your families' branches and final forms."
	remember_button.focus_mode = Control.FOCUS_NONE
	_place_top_button(remember_button, REMEMBER_SLOT)
	remember_button.process_mode = Node.PROCESS_MODE_ALWAYS
	remember_button.pressed.connect(open_remember)
	add_child(remember_button)

# The buff lens toggle (BuffLens; V): under the Menu button, the theme's selected look while on.
var buff_lens_button := Button.new()
func _add_buff_lens_button() -> void:
	BuffLens.set_on(get_tree(), false)  # A new run starts with the lens off
	buff_lens_button.name = "BuffLensButton"
	buff_lens_button.text = ""
	buff_lens_button.icon = IconInfo.icon(&"rank")  # Boosts: an up-chevron
	buff_lens_button.tooltip_text = "Boosts (%s): show which Wardens are boosted, and by what." % _action_key("buff_lens")
	buff_lens_button.toggle_mode = true
	buff_lens_button.focus_mode = Control.FOCUS_NONE
	_place_top_button(buff_lens_button, BUFFS_SLOT)
	_boosts_glyph(false)  # Off at the start of a run
	buff_lens_button.process_mode = Node.PROCESS_MODE_ALWAYS
	buff_lens_button.toggled.connect(func(pressed: bool) -> void:
		BuffLens.set_on(get_tree(), pressed)
		_boosts_glyph(pressed))
	add_child(buff_lens_button)

# Puts a top-right button in its slot ([right, width]) of the row under the resources.
func _place_top_button(button: Button, slot: Array) -> void:
	button.theme_type_variation = &"HudButton"
	# Compact icon buttons (the mock; user: "the icons on the right seem too big"): the glyph / icon at
	# BUTTON_GLYPH, the visible box inset to ~36 px, the hit area still 48 (platforms.md).
	button.add_theme_font_size_override("font_size", BUTTON_GLYPH)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("icon_max_width", BUTTON_GLYPH)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var box := button.get_theme_stylebox(state, &"HudButton")
		if box != null:
			box = box.duplicate()
			box.expand_margin_left = -BUTTON_BOX_INSET
			box.expand_margin_right = -BUTTON_BOX_INSET
			box.expand_margin_top = -BUTTON_BOX_INSET
			box.expand_margin_bottom = -BUTTON_BOX_INSET
			button.add_theme_stylebox_override(state, box)
	if button.name == &"CodexButton":
		button.add_theme_font_override("font", UiStyle.display_font())
	# The 10 px glyphs at exactly ×2 (20 px, nearest) in place of the font glyphs (UI Asset 93963da1).
	var glyph: Texture2D = IconInfo.hud_icon(HUD_GLYPHS[button.name]) if HUD_GLYPHS.has(button.name) else null
	if glyph != null:
		button.text = ""
		button.icon = glyph
	button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	button.offset_right = slot[0]
	button.offset_left = slot[0] - slot[1]
	button.offset_top = TOP_BUTTONS_Y
	button.offset_bottom = TOP_BUTTONS_Y + TOP_BUTTON_H
	button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	button.set_meta(&"top_width", slot[1])
	if not button.visibility_changed.is_connected(_layout_top_row):
		button.visibility_changed.connect(_layout_top_row)
	_layout_top_row.call_deferred()

# The row under the resources (user 2026-09-30, screens_ui.md): right-aligned with the resources'
# right edge, packed right to left in TOP_ROW order so hidden buttons leave no gap; Remember ends up
# nearest the Dreamlight counter above it.
const TOP_ROW := ["MenuButton", "CodexButton", "BuffLensButton", "RememberButton"]  # Right to left
const TOP_ROW_GAP := 0.0  # The visible boxes are inset, so they sit 12 px apart
# The top-right row as in the Moonlit Thread mock (screens_ui.md "Top-right layout, as in the Moonlit
# Thread mock-up"): leaves · Dew · Dreamlight · path (icon + a big Cormorant number), then the icon
# buttons Remember ✦ · Boosts · ? · ≡, all on one soft fog patch. When the buttons would run into the
# drift banner's text (1280 wide), they wrap onto a second line inside the same patch. The nodes stay
# direct HUD children (laid out here), so %DewLabel / HUD/MenuButton paths keep working.
const ROW_RIGHT := -16.0
const ROW_TOP := 12.0
const ROW_H := 48.0
const ROW_GAP := 22.0  # Between counters
const ROW_PAD := 10.0  # The fog patch around the row
const BANNER_CLEARANCE := 16.0
const ROW_BUTTON := 48.0  # Touch-sized (platforms.md); the icon inside is drawn smaller
const ROW_STEPS := [[28, 22.0], [24, 12.0], [21, 10.0], [19, 8.0]]  # [counter number size, gap]: full, then tighter steps
var row_compact := false  # The counters stepped down to keep one row (tests)
var row_wrapped := false  # The buttons sit on a second line (tests)

func _set_counter_size(counters: Array, size: int) -> void:
	for label: Label in counters:
		if label.get_theme_font_size("font_size") != size:
			label.add_theme_font_size_override("font_size", size)
			if _counter_icons.has(label):
				_place_counter_icon.call_deferred(label)
	_leaves_max.add_theme_font_size_override("font_size", roundi(size * 20.0 / 28.0))  # "/15" keeps its proportion
var leaves_down := false  # …and the leaves counter with them (tests)
var _leaves_max := Label.new()  # "/15" after the leaves value, dim
var _clears_label: Label
var _row_key := ""
var _row_check := 0.0

func _layout_top_row() -> void:
	if not is_inside_tree():
		return
	var counters: Array = [%PathLabel, get_node_or_null("DreamlightLabel"), dew_label, leaves_label]  # Right to left
	counters = counters.filter(func(c) -> bool: return c != null)
	var buttons: Array = []
	for name in TOP_ROW:
		var button := get_node_or_null(name) as Button
		if button != null and button.visible:
			buttons.append(button)
	var buttons_w := buttons.size() * ROW_BUTTON + maxf(buttons.size() - 1, 0) * TOP_ROW_GAP
	var screen_w := get_viewport().get_visible_rect().size.x
	var banner := get_node_or_null("DriftBanner") as Control
	var banner_right := 0.0
	if banner != null and banner.has_method("drawn_rect") and banner.visible:
		banner_right = banner.drawn_rect().end.x
	# One row (user: "all the icons and buttons should fit in one row on the top right"): before wrapping, the counter
	# numbers step down and the gaps tighten (ROW_STEPS); the buttons keep their 48 px hit area. Wraps only if even
	# the smallest step would reach the banner's text.
	var widths := {}
	var counters_w := 0.0
	var gap := ROW_GAP
	row_wrapped = true
	for step in ROW_STEPS:
		row_compact = step[0] < ROW_STEPS[0][0]
		_set_counter_size(counters, int(step[0]))
		gap = float(step[1])
		widths.clear()
		counters_w = 0.0
		for label: Label in counters:
			var icon: TextureRect = _counter_icons.get(label)
			var text_w := label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(step[0])).x
			widths[label] = ceilf(text_w + (icon.size.x + COUNTER_ICON_GAP if icon != null else 0.0) + 2.0)
			counters_w += widths[label]
		counters_w += gap * (counters.size() - 1)
		if _leaves_max.text != "":
			counters_w += _leaves_max.get_theme_font("font").get_string_size(_leaves_max.text, HORIZONTAL_ALIGNMENT_LEFT, -1, _leaves_max.get_theme_font_size("font_size")).x + 2.0
		var one_line_w := counters_w + (gap + buttons_w if not buttons.is_empty() else 0.0)
		row_wrapped = screen_w + ROW_RIGHT - one_line_w - ROW_PAD < banner_right + BANNER_CLEARANCE
		if not row_wrapped:
			break
	if row_wrapped:  # Even the smallest step doesn't fit: back to full size, the buttons on a second line
		row_compact = false
		_set_counter_size(counters, int(ROW_STEPS[0][0]))
		gap = ROW_GAP
		widths.clear()
		counters_w = 0.0
		for label: Label in counters:
			var icon: TextureRect = _counter_icons.get(label)
			var text_w := label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(ROW_STEPS[0][0])).x
			widths[label] = ceilf(text_w + (icon.size.x + COUNTER_ICON_GAP if icon != null else 0.0) + 2.0)
			counters_w += widths[label]
		counters_w += gap * (counters.size() - 1)
	# Buttons: right end of line 1, or line 2 when wrapped.
	var x := ROW_RIGHT
	var button_top := ROW_TOP + (ROW_H + 4.0 if row_wrapped else 0.0)
	for button: Button in buttons:
		button.offset_right = x
		button.offset_left = x - ROW_BUTTON
		button.offset_top = button_top
		button.offset_bottom = button_top + ROW_BUTTON
		x -= ROW_BUTTON + TOP_ROW_GAP
	# Counters: left of the buttons on one line, or from the right edge on line 1. If line 1 still
	# reaches the banner's text (its boss line, at 1280), the leaves counter joins the buttons' line.
	var line2_x := x - gap + TOP_ROW_GAP
	x = line2_x if not row_wrapped and not buttons.is_empty() else ROW_RIGHT
	var max_w := 0.0
	if _leaves_max.text != "":
		max_w = ceilf(_leaves_max.get_theme_font("font").get_string_size(_leaves_max.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			_leaves_max.get_theme_font_size("font_size")).x + 2.0)
	leaves_down = row_wrapped and not buttons.is_empty() \
		and screen_w + ROW_RIGHT - counters_w - ROW_PAD < banner_right + BANNER_CLEARANCE
	var left := x
	for label: Label in counters:
		var top := ROW_TOP
		var at := x
		if label == leaves_label and leaves_down:
			top = button_top
			at = line2_x
		if label == leaves_label and max_w > 0.0:  # "/15" right after the value, dim
			_leaves_max.offset_right = at
			_leaves_max.offset_left = at - max_w
			_leaves_max.offset_top = top + 4.0  # Sits on the value's baseline
			_leaves_max.offset_bottom = top + ROW_H
			at -= max_w
		label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.offset_right = at
		label.offset_left = at - widths[label]
		label.offset_top = top
		label.offset_bottom = top + ROW_H
		left = minf(left, label.offset_left)
		if not (label == leaves_label and leaves_down):
			x = label.offset_left - gap
		_place_counter_icon.call_deferred(label)
	if not buttons.is_empty():
		left = minf(left, buttons[buttons.size() - 1].offset_left)
	var bottom := button_top + ROW_BUTTON if not buttons.is_empty() else ROW_TOP + ROW_H
	var fog := get_node_or_null("ResourcesFog") as Control
	if fog != null:
		fog.offset_left = left - ROW_PAD
		fog.offset_right = ROW_RIGHT + ROW_PAD - 4.0
		fog.offset_top = ROW_TOP - ROW_PAD + 4.0
		fog.offset_bottom = bottom + ROW_PAD - 2.0
	if _clears_label != null:  # The half-price clears counter: just under the row
		var clears_w := _clears_label.get_theme_font("font").get_string_size(_clears_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 16.0 + COUNTER_ICON_GAP + 2.0
		_clears_label.offset_right = ROW_RIGHT
		_clears_label.offset_left = ROW_RIGHT - clears_w
		_clears_label.offset_top = bottom + ROW_PAD + 2.0  # Just under the patch
		_clears_label.offset_bottom = _clears_label.offset_top + 22.0
		_place_counter_icon.call_deferred(_clears_label)

# The row's global rect (the fog patch), for tests and the banner check.
func resource_row_rect() -> Rect2:
	var fog := get_node_or_null("ResourcesFog") as Control
	return fog.get_global_rect() if fog != null else Rect2()


func _action_key(action: String) -> String:
	for event in InputMap.action_get_events(action) if InputMap.has_action(action) else []:
		if event is InputEventKey:
			return OS.get_keycode_string(event.physical_keycode if event.physical_keycode != 0 else event.keycode)
	return ""

func open_remember() -> void:
	if run_state.is_over:
		return
	dream_state.open_remember()  # RememberScreen pauses (and restores the pause on close) itself

# Something the Dreamlight on hand can unlock now (a branch, final or Ascended form of a family you own).
func can_remember_something() -> bool:
	if dream_state.dreamlight <= 0:
		return false
	for tree in dream_state.get_remember_trees():
		var forms: Array = []
		for branch in tree[1]:
			forms.append(branch[0])
			forms.append_array(branch[1])
		if tree[2] != null:
			forms.append(tree[2])
		for form in forms:
			if dream_state.can_unlock(form):
				return true
	return false

var _remember_check := 0.0
var _remember_ready := false

func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.001)
	_remember_check -= real
	if _remember_check <= 0.0:  # can_unlock walks every family's tree: 4 times a second is plenty
		_remember_check = 0.25
		_remember_ready = can_remember_something()  # ✦ glows (below) when Dreamlight can buy something
	_row_check -= real
	if _row_check <= 0.0:  # The top-right row follows its numbers, buttons and the banner (cheap key)
		_row_check = 0.2
		_update_boosts()
		var banner := get_node_or_null("DriftBanner")
		var key := "%s|%s|%s|%s|%s|%s|%d" % [leaves_label.text, dew_label.text, %PathLabel.text,
			"%s%s" % [(get_node("DreamlightLabel") as Label).text, _clears_label.text if _clears_label else ""], buff_lens_button.visible,
			banner.drawn_width() if banner != null and banner.has_method("drawn_width") else 0.0,
			get_viewport().get_visible_rect().size.x]
		if key != _row_key:
			_row_key = key
			_layout_top_row()
	_remember_glow += real
	remember_button.modulate = Color.WHITE.lerp(Color(1.35, 1.2, 0.8), 0.5 + 0.5 * sin(_remember_glow * 4.0)) \
		if _remember_ready else Color.WHITE  # A multiplier (glow pulse)

# Full-screen overlays draw above the rest of the HUD (the Coming strip, the top-right buttons and
# the counters are added in code after the scene's screens): they go last, in rest order, with the
# pause menu on top of everything.
const OVERLAY_ORDER := ["FamilyPickScreen", "DreamScreen", "OmenScreen", "RememberScreen", "NightmareIntro",
	"BossDossier", "ResultsScreen", "PauseMenu"]

func _raise_overlays() -> void:
	for overlay_name in OVERLAY_ORDER:
		var overlay := get_node_or_null(overlay_name)
		if overlay != null:
			move_child(overlay, get_child_count() - 1)

# --- The Sprout price rule (warden_stats.md "The rule is shown") -------------------------------------
# Every TowerPlacer.sprout_per_step() Sprouts on the map add sprout_step_dew() to the price (Seedfall:
# a slower rise). The tooltip says so, a small "↑ 8/10" tag above the button counts to the next rise,
# and the first rise in a run gets a one-line toast.
var _sprout_rise_told := false
var _sprout_last_cost := -1

func sprout_rule_text(cost: int) -> String:
	var per := tower_placer.sprout_per_step()
	if per <= 0:
		return "Sprout · %d Dew, fixed." % cost
	var next := (tower_placer.count_paid_sprouts() / per + 1) * per
	return "Sprout · %d Dew. Every %d Sprouts on the map add +%d Dew to the price (next rise at %d Sprouts).%s Selling or growing one lowers it." % [
		cost, per, tower_placer.sprout_step_dew(), next, " (Seedfall: a slower rise.)" if tower_placer.sprout_price_halved() else ""]

func _update_sprout_rule(button: Button, cost: int) -> void:
	var tag := button.get_node_or_null("SproutRise") as Label
	if tag == null:
		tag = Label.new()
		tag.name = "SproutRise"
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiStyle.number(tag, 12, UiStyle.INK_DIM)
		tag.add_theme_color_override("font_outline_color", UiStyle.FOG)
		tag.add_theme_constant_override("outline_size", 4)
		button.add_child(tag)
	var per := tower_placer.sprout_per_step()
	var count := tower_placer.count_paid_sprouts()
	tag.visible = per > 0 and cost > 0
	if per > 0:
		tag.text = "↑ %d/%d" % [count, (count / per + 1) * per]
	tag.reset_size()
	tag.position = Vector2((button.size.x - tag.size.x) / 2.0, -tag.size.y - 4.0)  # Clear of the slot's hotkey
	button.set_meta(&"price_line", sprout_rule_text(cost))  # The hover card's price line
	if _sprout_last_cost >= 0 and cost > _sprout_last_cost and per > 0 and not _sprout_rise_told:
		_sprout_rise_told = true
		show_toast("Sprouts now cost %d Dew: the more you have, the more they cost." % cost)
	_sprout_last_cost = cost

# --- The Warden bar's hover card (screens_ui.md, the bullets above "Readable tooltips") --------------
# Hovering a Warden slot (a long press on touch) shows the Warden panel's top half for it: the shared
# WardenHeaderView (portrait, name, damage type, description, stats with this run's Dreams, statuses,
# Potency, Grows into) plus its price line (the Sprout's rising rule). No buttons. Above the slot.
const HOVER_LONG_PRESS := 0.45  # Seconds held before the card shows on touch
var hover_card: PanelContainer  # (tests)
var _hover_box := VBoxContainer.new()
var _hover_view: WardenHeaderView
var _hover_price := Label.new()
var _hover_for: Button = null
var _press_serial := 0

func _ensure_hover_card() -> void:
	if hover_card != null:
		return
	hover_card = PanelContainer.new()
	hover_card.name = "WardenHoverCard"
	hover_card.add_theme_stylebox_override("panel", UiStyle.panel_in(UiStyle.GOLD, 14.0, 12.0))
	hover_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_card.process_mode = Node.PROCESS_MODE_ALWAYS
	hover_card.visible = false
	_hover_box.add_theme_constant_override("separation", 6)
	_hover_box.custom_minimum_size = Vector2(WardenHeaderView.WIDTH, 0)
	_hover_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_card.add_child(_hover_box)
	_hover_price.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hover_price.custom_minimum_size = Vector2(WardenHeaderView.WIDTH, 0)
	UiStyle.caps(_hover_price, 14, UiStyle.GOLD)
	add_child(hover_card)

func _show_hover_card(button: Button, data: TowerData) -> void:
	_ensure_hover_card()
	if is_instance_valid(_hover_view):
		_hover_box.remove_child(_hover_view)
		_hover_view.queue_free()
	_hover_view = WardenHeaderView.build(data, null, dream_state, true)
	_hover_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hover_box.add_child(_hover_view)
	if _hover_price.get_parent() != null:
		_hover_box.remove_child(_hover_price)
	_hover_price.text = String(button.get_meta(&"price_line", ""))
	_hover_price.text = _hover_price.text.replace("Cost:", "Plant for") if not _hover_price.text.begins_with("Sprout") else _hover_price.text
	_hover_box.add_child(_hover_price)
	_hover_for = button
	move_child(hover_card, get_child_count() - 1)  # Above the rest of the HUD…
	_raise_overlays()  # …but under the full-screen overlays and the pause menu
	hover_card.visible = true
	hover_card.reset_size()
	_place_hover_card.call_deferred(button)

func _place_hover_card(button: Button) -> void:
	if hover_card == null or not hover_card.visible or _hover_for != button:
		return
	hover_card.reset_size()
	var screen := get_viewport().get_visible_rect().size
	var rect := button.get_global_rect()
	var at := Vector2(rect.get_center().x - hover_card.size.x / 2.0, rect.position.y - hover_card.size.y - 10.0)
	hover_card.position = Vector2(clampf(at.x, 8.0, screen.x - hover_card.size.x - 8.0), maxf(at.y, 8.0))

func _hide_hover_card(button: Button) -> void:
	_press_serial += 1  # A pending long press no longer shows it
	if hover_card != null and _hover_for == button:
		hover_card.visible = false
		_hover_for = null

# Touch: a long press shows the card (a tap still just picks the Warden).
func _on_slot_down(button: Button, data: TowerData) -> void:
	_press_serial += 1
	var serial := _press_serial
	get_tree().create_timer(HOVER_LONG_PRESS, true, false, true).timeout.connect(func() -> void:
		if serial == _press_serial:  # Still held (button_up bumps the serial)
			_show_hover_card(button, data))

# --- Boosts (screens_ui.md "The lens button, revised") ------------------------------------------------
# The Boosts button shows only once the map has a local boost source (an aura, a Kinship, Kindred /
# Whole Tree: BuffOverlay.has_local_sources); while the lens is on, a small legend sits under the
# top-right patch: each kind's pip (BuffOverlay.draw_pip) and name, hoverable and tappable.
var boosts_legend: VBoxContainer  # (tests)
var _legend_key := ""

# The Boosts toggle's glyph (UI Asset c2a2a600): a grey arrow off, the gold one with sparkles on.
func _boosts_glyph(on: bool) -> void:
	var glyph := IconInfo.hud_icon(&"boosts_on" if on else &"boosts_off")
	if glyph != null:
		buff_lens_button.icon = glyph

func _update_boosts() -> void:
	var sources := BuffOverlay.has_local_sources(self)
	buff_lens_button.visible = sources or buff_lens_button.button_pressed  # Never hidden while it's on
	if not sources and buff_lens_button.button_pressed:
		buff_lens_button.button_pressed = false  # The last source went: the lens goes off with it
	var kinds: Array = BuffOverlay.legend_kinds(self) if BuffLens.on else []
	var key := ",".join(kinds.map(func(k: Array) -> String: return String(k[0])))
	if key == _legend_key and boosts_legend != null:
		boosts_legend.visible = not kinds.is_empty()
		return
	_legend_key = key
	if boosts_legend == null:
		boosts_legend = VBoxContainer.new()
		boosts_legend.name = "BoostsLegend"
		boosts_legend.add_theme_constant_override("separation", 2)
		boosts_legend.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		boosts_legend.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		add_child(boosts_legend)
		_raise_overlays()  # Full-screen overlays and the pause menu stay on top
	for child in boosts_legend.get_children():
		boosts_legend.remove_child(child)
		child.queue_free()
	for kind in kinds:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_END
		row.add_theme_constant_override("separation", 6)
		var name := Label.new()
		name.text = String(kind[2])
		name.add_theme_font_size_override("font_size", 15)
		name.add_theme_color_override("font_color", UiStyle.INK)
		name.add_theme_color_override("font_outline_color", UiStyle.FOG)
		name.add_theme_constant_override("outline_size", 4)
		row.add_child(name)
		var pip := Control.new()
		pip.custom_minimum_size = Vector2(22, 22)  # The 10 px pip art at ×2
		var pip_kind := String(kind[0])
		var pip_colour: Color = kind[1]
		pip.draw.connect(func() -> void: BuffOverlay.draw_pip(pip, pip.size / 2.0, pip_kind, pip_colour, 10.0))  # r 10 = the art ×2 (panels)
		row.add_child(pip)
		TapTip.attach(row, "%s: a Warden boosted by %s shows this pip." % [kind[2], kind[2]])
		boosts_legend.add_child(row)
	boosts_legend.visible = not kinds.is_empty()
	var fog := get_node_or_null("ResourcesFog") as Control
	var top := fog.offset_bottom + 8.0 if fog != null else 140.0
	if _clears_label != null and _clears_label.visible:
		top = _clears_label.offset_bottom + 4.0
	boosts_legend.offset_right = ROW_RIGHT
	boosts_legend.offset_top = top
