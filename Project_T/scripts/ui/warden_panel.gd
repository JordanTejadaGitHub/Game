extends PanelContainer

# Bottom-left panel for the selected Warden: what it does, its stats (including Dreams), what it
# can grow into (Dew cost, or which Dream it needs) and Sell. Built in code; hidden with no selection.

const TARGET_TIPS := {
	TowerData.TargetMode.FIRST: "The nightmare furthest along the path",
	TowerData.TargetMode.LAST: "The nightmare furthest back on the path (the newest arrival)",
	TowerData.TargetMode.STRONGEST: "The nightmare with the most health left",
	TowerData.TargetMode.CLOSEST: "The nightmare nearest this Warden",
}

@onready var tower_seller: TowerSeller = %TowerSeller
@onready var tower_placer: TowerPlacer = %TowerPlacer
@onready var dream_state: DreamState = %DreamState
@onready var run_state: RunState = %RunState
@onready var drift_director: DriftDirector = %DriftDirector

var _tower: Tower = null
var _header := WardenHeaderView.new()  # The top half, shared with the hover card and Codex
var _title := _header.title
var _portrait := _header.portrait  # Left of the title: the Warden's idle art, animated (screens_ui.md "Selected vs hovered")
var _portrait_atlas := _header.portrait_atlas
var _portrait_time := 0.0
var _damage_type := _header.damage_type  # Under the title: the damage type name in its colour (one Warden)
var _desc := _header.desc  # What it does, with its status words as links (StatusLinks)
var _stats := _header.stats  # Stat rows: each stat explains itself on hover and tap (IconInfo)
var _buffs := VBoxContainer.new()  # Buffs: every source of this Warden's power (BuffSources), then the total
var _ranks_row := HFlowContainer.new()  # Its rank picks ("Power ×2 · Reach"), an old one dimmed when its form ignores it
var _map_note := Label.new()  # "+N more not labelled on the map" (BuffOverlay's chips had no room for them)
var _body := Label.new()
var _groups := VBoxContainer.new()  # Several selected: one row per kind with its portrait
var _buttons := VBoxContainer.new()
var _scroll := ScrollContainer.new()  # Everything between the header and the footer, capped (_fit_height)
var _content: VBoxContainer
var _footer := HBoxContainer.new()  # Sell and Close: always visible
var _buffs_open := false  # Buffs: folded to the Total line until "Details"
const LOCKED_FORM_TIP := WardenHeaderView.LOCKED_FORM_TIP  # A locked form's Grow tooltip
const MAX_SHARE := 0.55  # The panel never takes more of the screen's height than this
const TOP_CLEAR := 150.0  # Keeps clear of the Dreams row and the top-right buttons
const BOTTOM_MARGIN := 16.0  # The panel's offset from the bottom edge
const MIN_INFO := 80.0  # The info part never squeezes below this (it scrolls)
var _confirm_sell := false  # Selling a group during a drift asks once more
var _confirm_unlock: TowerData = null  # Unlocking a form with Dreamlight asks once more
var _confirm_eldest := false  # Rank VI would crown the Eldest: asks once more
var _choosing := false  # The Nurture button / R opened the rank choices: 1–4 pick one, Esc / R close
var _confirm_grow: TowerData = null  # Touch: the Grow tapped once (previewing; the next tap grows)
var _touch := false

func _ready() -> void:
	custom_minimum_size = Vector2(300, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	# The header (portrait + name, damage type, description, stats, Dreams on it) is the shared
	# WardenHeaderView, also on the Warden bar's hover card and the Codex, so they never disagree.
	_header.growth.visible = false
	# screens_ui.md "The Warden panel never fills the screen": the info part (header, Buffs, notes) scrolls
	# inside a cap; the action buttons (Grow, Nurture, Targeting ...) and Sell / Close stay below it, always on screen.
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_scroll)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(content)
	_content = content
	content.add_child(_header)
	_ranks_row.name = "RankPicks"
	_ranks_row.add_theme_constant_override("h_separation", 8)
	content.add_child(_ranks_row)
	_buffs.add_theme_constant_override("separation", 1)
	content.add_child(_buffs)
	_map_note.name = "MapNote"
	_map_note.visible = false
	_map_note.add_theme_font_size_override("font_size", 14)
	_map_note.add_theme_color_override("font_color", UiStyle.INK_DIM)
	content.add_child(_map_note)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(280, 0)
	content.add_child(_body)
	content.add_child(_groups)
	box.add_child(_buttons)  # Actions: never scrolled away
	_footer.add_theme_constant_override("separation", 6)
	box.add_child(_footer)
	get_viewport().size_changed.connect(_fit_height)
	visible = false

	tower_seller.tower_selected.connect(_show)
	# World labels (DPS tags, name tags) don't draw under the open panel: it's see-through, and they read through it.
	item_rect_changed.connect(_update_cover)
	visibility_changed.connect(_update_cover)
	tree_exiting.connect(func() -> void: WorldLabel.set_cover(&"warden_panel", Rect2(), false))
	if tower_placer.has_signal(&"seed_choice_changed"):  # A Seedbearer's Sprout planted or cancelled: its count changed
		tower_placer.seed_choice_changed.connect(func(_active: bool) -> void:
			if visible:
				_refresh())
	tower_seller.selection_changed.connect(func(_towers: Array[Tower]) -> void:
		_confirm_sell = false
		_confirm_unlock = null
		_confirm_eldest = false
		_refresh())
	run_state.dew_changed.connect(_on_dew_changed.unbind(1))
	dream_state.unlocks_changed.connect(_refresh)
	dream_state.card_taken.connect(_refresh.unbind(1))
	if dream_state.has_signal("dreamlight_changed"):
		dream_state.dreamlight_changed.connect(_refresh_unless_hovered.unbind(1))  # Shards arrive mid-drift
	drift_director.build_phase_changed.connect(_refresh.unbind(1))
	tower_seller.grow_option_held.connect(_on_grow_key_held)
	tower_seller.nurture_asked.connect(_toggle_choices)
	tower_seller.grow_refused.connect(_on_grow_refused)
	tower_seller.selection_changed.connect(func(_t: Array[Tower]) -> void:
		_confirm_grow = null
		_choosing = false)

# TowerSeller emits tower_selected right before selection_changed, which refreshes: refreshing here
# too built the panel twice per selection change (slow with a big selection).
func _show(tower: Tower) -> void:
	_tower = tower

func _refresh() -> void:
	_hook_buff_overlay()
	if is_inside_tree() and not get_tree().process_frame.is_connected(_fit_height):
		get_tree().process_frame.connect(_fit_height, CONNECT_ONE_SHOT)  # Next frame: the new rows are in, the old ones gone
	_group_refresh_queued = false  # This refresh already shows the current Dew
	_shown = _selection_state()
	for child in _groups.get_children():
		child.queue_free()
	tower_placer.hide_catch_preview()
	tower_placer.hide_grow_preview()
	if tower_seller.selection.size() > 1:
		visible = true
		_desc.visible = false
		for child in _stats.get_children():
			child.queue_free()
		_body.visible = true
		_fill_buffs(null)
		_title.tooltip_text = ""
		_refresh_group()
		return
	if not is_instance_valid(_tower) or _tower.is_queued_for_deletion():
		_tower = null
		visible = false
		return
	visible = true
	var data := _tower.tower_data
	if _tower.is_catcher():
		tower_placer.show_catch_preview(_tower.global_position, _tower.get_catch_radius())  # Its catch zone
	# The shared header: portrait, name, damage type, description, stats, Dreams on it.
	var lines: Array[String] = _header.show_warden(data, _tower, dream_state, false)
	if _tower.rank > 0:
		_title.text += " · Rank %s" % Tower.rank_name(_tower.rank)
		if _is_eldest(_tower):
			_title.text += " · Eldest"
	_fill_rank_picks()
	_title.tooltip_text = ""
	if _tower.rank > 0:
		_title.tooltip_text = IconInfo.stat_tooltip(&"rank") + "\n" + IconInfo.stat_tooltip(&"focus")
	_title.mouse_filter = Control.MOUSE_FILTER_PASS if _title.tooltip_text != "" else Control.MOUSE_FILTER_IGNORE
	if data.is_unique:
		lines.append("A freed memory: one per run, can't grow.")
	# Combat feedback (screens_ui.md): what this Warden has done, and what it combos with.
	var log := DamageLog.instance
	if log != null and data.can_attack:
		var stats := log.get_tower_stats(_tower)
		var run: float = stats.get("run", 0.0)
		if run > 0.0:
			lines.append("This run: %s damage · %.0f/s · from combos %d%%" % [BossDossier.thousands(roundi(run)),
				log.get_dps(_tower), roundi(100.0 * stats.get("run_combo", 0.0) / run)])
	var links := Synergies.find_links(data, _tower.cell, _tower.get_parent().get_children())
	# Combos with: the shared combo links (hover / tap = its tip, ??? until found; a click opens the Codex).
	var combo_ids: Array[String] = []
	for l in links:
		var id: String = String(Synergies.link_combo(data, l[0].tower_data).get("id", ""))
		if id != "" and not combo_ids.has(id):
			combo_ids.append(id)
	if not combo_ids.is_empty():
		_stats.add_child(StatusLinks.make_label("Combos with: " + ", ".join(combo_ids.map(func(id: String) -> String:
			return "{combo:%s}" % id)), 15))
	elif not links.is_empty():
		lines.append("Combos with: " + ", ".join(links.map(func(l: Array) -> String: return l[1])))
	var kin := Kinships.find(_tower)
	if kin != null:
		var kin_line := kin.describe(_tower)  # "Kin: Bloomcap · Slumber Rot · Blooming (3 drifts to Old Kin)"
		if kin_line == "":
			kin_line = kin.unbonded_reason(_tower)  # A kin in reach but bonded elsewhere: say so
		if kin_line != "":
			lines.append(kin_line)  # Only with kin (screens_ui.md: no "No kin. A … would form …" line)
		var family := kin.family_bonus(data.line)
		if family > 0.0:
			_stats.add_child(_kindred_row(data.line, family))  # The family icon + "Kindred +10%"
	var support := SupportLog.find(_tower)
	var support_line := support.get_panel_line(_tower) if support else ""
	if support_line != "":
		lines.append(support_line)  # "Caught this run: 240 Dew · paid back ✓", "Held 42 s · …"
	_fill_buffs(_tower)  # The Buffs section (auras with falloff, Kinships, rank, Dreams, Omens)
	if dream_state.has_method("get_crossroads_bonus") and dream_state.has_rule(&"crossroads"):
		var crossroads: float = dream_state.get_crossroads_bonus(_tower)
		if crossroads > 0.0:
			lines.append("Crossroads: +%d%%" % roundi(crossroads * 100))
	_body.text = "\n".join(lines)

	for child in _buttons.get_children() + _footer.get_children():
		child.queue_free()
	_clear_not_in_dream()
	if _tower.can_choose_target():
		_add_target_switch([_tower])
	if data.has_bird_toggle:
		var birds := _add_button("Birds: %s" % ("all on the strongest" if _tower.focus_strongest else "spread out"))
		birds.tooltip_text = "Spread out, or all on the strongest."
		birds.pressed.connect(func() -> void:
			_tower.focus_strongest = not _tower.focus_strongest
			_refresh())
	var options := Tower.grow_options(dream_state, data)
	if options.is_empty() and data.line == "sprout":
		_add_button(Tower.NO_FAMILY_YET).disabled = true  # No family picked yet
	for index in options.size():
		var option: Array = options[index]
		var next: TowerData = option[0]
		var button := _add_button("")
		UiStyle.primary(button)  # Grow is the panel's main action (ui_style.md)
		_grow_key(button, index)
		if option[1]:
			var grow := _tower.get_grow_cost(next)  # Ranked Wardens also pay the rank difference
			var cost: int = grow.total
			# The form's name and key changes first ("Thunderhead: damage 30 → 48, chains 3 → 5, range 3.0 → 3.5").
			button.tooltip_text = tower_placer.grow_changes(_tower, next) + "\n\n" + IconInfo.format(next.description)  # {spored}-style tokens as words
			if grow.ranks > 0:
				button.tooltip_text += "\n\n%d Dew + %d for its rank %s." % [grow.base, grow.ranks, Tower.rank_name(_tower.rank)]
			var label := "Grow" if _confirm_grow == next else "Grow into %s" % next.display_name  # Touch: the second tap grows
			var awake := tower_placer.ascended_blocker(next)
			if awake != "":
				button.text = "Grow into %s · %s%s" % [next.display_name, awake, button.get_meta(&"key", "")]  # One per family
				button.disabled = true
			elif next.footprint > _tower.get_footprint() and tower_placer.get_grow_squares(_tower, next).is_empty():
				# A 2×2 form needs three free cells (or Thornwalls) beside it, and the path must stay open.
				button.text = "Grow into %s · Needs 3 free cells beside it%s" % [next.display_name, button.get_meta(&"key", "")]
				button.disabled = true
			else:
				_priced(button, label, "%s Dew" % BossDossier.thousands(cost), cost, &"dew", true)  # Short: dim, the cost in POOR; a press refuses
			var tower := _tower
			button.pressed.connect(func() -> void:
				if tower_seller.refuse_if_short([tower], next, true, index):
					return  # Short of Dew: the refusal (shake, toast, Dew counter); nothing previewed or spent
				if _touch and _confirm_grow != next:
					_confirm_grow = next  # First tap: preview + confirm
					_refresh()
					tower_placer.show_grow_preview([[_tower, next]])
					return
				_confirm_grow = null
				_evolve(next))
			if next.catch_share > 0.0 and not _tower.is_catcher():  # Where it would catch (placement preview)
				var radius := next.catch_radius + (DewCatch.WIDE_BOWL_STEP if dream_state.has_rule(&"dew_trail") else 0.0)  # Dew Trail widens the catch
				button.mouse_entered.connect(func() -> void: tower_placer.show_catch_preview(_tower.global_position, radius))
				button.mouse_exited.connect(tower_placer.hide_catch_preview)
		else:
			_locked_form_button(button, "Unlock %s" % next.display_name, next, [_tower], index)
			continue  # Locked: no ring, no ghost
		_preview_on(button, [[_tower, next]])
	_not_in_dream_button(data)
	_seed_button()
	if _tower.can_nurture():
		var cost := _tower.get_nurture_cost()
		# The Eldest (a Legendary): rank VI crowns the one Warden that can grow past V, so ask first.
		var eldest_ask: bool = dream_state.has_method("needs_eldest_confirm") and dream_state.needs_eldest_confirm(_tower)
		if eldest_ask:
			_add_button("Make this the Eldest? Only one Warden can grow past rank V").disabled = true
			var yes := _add_button("Yes: make it the Eldest")
			yes.pressed.connect(func() -> void:
				dream_state.make_eldest(_tower)  # Then the rank VI choices show
				_refresh())
		else:
			# Nurture v3 (warden_stats.md "Playtest fix"): one Nurture button; it (or R) opens the rank's choices
			# in place, 1–4 pick, Esc / R close. (The Heartwood Sapling's ranks only raise its yield: the
			# button nurtures at once.)
			if not _choosing or not _tower.needs_focus():
				var nurture := _add_button("")
				nurture.set_meta(&"key", " (R)")
				nurture.tooltip_text = ("Choose what rank %s adds. Kept when it grows; can't be changed." % Tower.rank_name(_tower.rank + 1)
					if _tower.needs_focus() else "Rank %s: %s." % [Tower.rank_name(_tower.rank + 1), _tower.focus_text(_tower.default_choice())]) + _growth_note()
				var price := 0 if _free_rank() else cost
				_priced(nurture, "Nurture to rank %s" % Tower.rank_name(_tower.rank + 1), _price(price), price, &"dew", false)
				nurture.pressed.connect(_toggle_choices)  # Short: refuses (_refuse_nurture)
				_rank_preview_on(nurture, [_tower], _tower.default_choice() if not _tower.needs_focus() else Tower.Focus.NONE)
			else:
				var choices: Array = _tower.focus_options()
				for index in choices.size():
					var which: Tower.Focus = choices[index]
					var button := _choice_row(index, Tower.FOCUS_NAMES[which], _choice_preview(_tower, which), _price(cost))
					button.tooltip_text = "Rank %s: %s. Kept when it grows; can't be changed." % [
						Tower.rank_name(_tower.rank + 1), _tower.focus_text(which)] + _growth_note()
					button.set_meta(&"cost", 0 if _free_rank() else cost)
					if _tower.has_method("choice_available") and not _tower.choice_available(which):
						button.disabled = true  # A one-time choice already taken ("Already taken: Kindred works once")
						button.tooltip_text = _tower.choice_blocker(which)
						continue
					_mark_choice(button, _free_rank() or run_state.can_afford(cost))  # Picking one plays the refusal (spend_dew)
					button.pressed.connect(_nurture_with.bind(which))
					_rank_preview_on(button, [_tower], which)
	elif _tower.can_be_nurtured() and _tower.rank > 0:
		var others_can: bool = dream_state.has_method("get_max_rank") and dream_state.get_max_rank() > _tower.rank
		if others_can and not _is_eldest(_tower):
			_add_button("Rank %s: only the Eldest grows further" % Tower.rank_name(_tower.rank)).disabled = true
		else:
			_add_button("Rank %s: fully nurtured" % Tower.rank_name(_tower.rank)).disabled = true
	var refund := tower_seller.get_refund(_tower)
	# Buttons show the action and its price (screens_ui.md "Less hand-holding"); the refund rule is the tooltip.
	var note := "Half the Dew back while nightmares walk." if not drift_director.is_build_phase() else ""
	if tower_seller.is_placed_this_rest(_tower):
		note = "Placed this rest: all its Dew back."
	elif drift_director.is_build_phase() and _tower.rest_dew > 0:
		note = "This rest's %d Dew comes back in full." % _tower.rest_dew
	var sell := _add_footer_button("Sell · +%s Dew (%s)" % [BossDossier.thousands(refund), tower_seller.sell_key_name()])  # Its hotkey, like Nurture's (R)
	sell.tooltip_text = note
	sell.pressed.connect(func() -> void: tower_seller.sell(_tower.cell))
	if _tower.tower_data.rooted:
		sell.text = "Permanent: the Sapling can't be sold or moved"
		sell.disabled = true
	elif not tower_seller.can_sell():
		sell.text = tower_seller.sell_block_reason()
		sell.disabled = true
	var close := _add_footer_button("Close")
	close.pressed.connect(tower_seller.select.bind(null))

func _is_eldest(tower: Tower) -> bool:
	return dream_state.has_method("is_eldest") and dream_state.is_eldest(tower)

# One row of stats ("Damage 24 · 1.00/s · range 2.50"): each part is its icon and a label, both
# explaining the stat on hover and on tap (IconInfo). `parts`: [[text, stat id], …] or
# [text, status id, true] for a status (&"" = plain text).
# Several Wardens selected: grouped by kind, with totals, group grow buttons and Sell all.
func _refresh_group() -> void:
	_ranks_row.visible = false  # One Warden's picks only
	var selection := tower_seller.selection
	var groups := tower_seller.get_selection_groups()
	_title.text = "%d Wardens selected" % selection.size()
	_portrait.visible = false
	_damage_type.visible = false
	var kinds: Array[String] = []
	var damage_per_second := 0.0
	for group in groups:
		kinds.append("%d %s" % [group[1].size(), group[0].display_name])
		for tower in group[1]:
			if tower.tower_data.can_attack and tower.attack_data.attack_kind != TowerData.AttackKind.AURA:
				damage_per_second += tower.get_damage() * tower.get_attacks_per_second()
		_groups.add_child(_group_row(group[0], group[1].size()))
	var lines: Array[String] = [", ".join(kinds)]
	if damage_per_second > 0.0:
		lines.append("Together: %.0f damage per second" % damage_per_second)
	lines.append_array(DreamBonusView.group_summary(selection))  # "Solitude: 3 of 5"
	_body.text = "\n".join(lines)

	for child in _buttons.get_children() + _footer.get_children():
		child.queue_free()
	_clear_not_in_dream()
	var aimed := selection.filter(func(t) -> bool: return is_instance_valid(t) and t.can_choose_target())
	if not aimed.is_empty():
		_add_target_switch(aimed)
	for group in groups:
		var data: TowerData = group[0]
		var towers: Array = group[1]
		var group_options := Tower.grow_options(dream_state, data)  # Sprouts: only this run's families
		for index in group_options.size():
			var option: Array = group_options[index]
			var next: TowerData = option[0]
			var button := _add_button("")
			UiStyle.primary(button)
			_grow_key(button, index)
			if not option[1]:
				_locked_form_button(button, "Unlock %s" % next.display_name, next, towers, index)
				continue  # Locked: no ring, no ghost
			button.tooltip_text = tower_placer.grow_changes(towers[0], next) + "\n\n" + IconInfo.format(next.description)  # As the first of them
			# Each pays Tower.get_grow_cost (ranked ones their rank difference too).
			var plan: Array = tower_seller.plan_grow(towers, next)
			var affordable: int = plan[0]
			var cheapest: int = towers.map(func(t: Tower) -> int: return t.get_grow_cost(next).total).min()
			var label: String
			var price := plan[1] as int
			if affordable >= towers.size():
				label = "Grow %d %s into %s" % [towers.size(), _plural(data, towers.size()), next.display_name]
			elif affordable > 0:
				# Grows as many as the Dew allows, closest to the Heartwood first.
				label = "Grow %d of %d %s into %s" % [affordable, towers.size(), _plural(data, towers.size()), next.display_name]
			else:
				# None affordable: the price of the first one.
				label = "Grow 1 of %d %s into %s" % [towers.size(), _plural(data, towers.size()), next.display_name]
				price = cheapest
			var awake := tower_placer.ascended_blocker(next)
			if awake != "":
				button.text = "%s → %s · %s%s" % [_plural(data, towers.size()), next.display_name, awake, button.get_meta(&"key", "")]
				button.disabled = true
			else:
				_priced(button, label, "%s Dew" % BossDossier.thousands(price), cheapest, &"dew", true)  # Short of even one: the can't-afford style
			button.pressed.connect(func() -> void:
				if not tower_seller.refuse_if_short(towers, next, true, index):
					tower_seller.grow_group(towers, next))
			_preview_on(button, towers.map(func(t: Tower) -> Array: return [t, next]))
	# Nurture v3: one choice for the whole group ("Group Nurture asks once"); each Warden takes it if it can
	# (attackers Power / Swift / Reach / Deep, support Wardens their own). R arms 1–4.
	var rank_options: Array[Tower.Focus] = []
	for tower in selection:
		if is_instance_valid(tower) and tower.can_nurture():
			for which in tower.focus_options():
				if not rank_options.has(which):
					rank_options.append(which)
	if not rank_options.is_empty() and not _choosing:
		var nurturable := selection.filter(func(t) -> bool: return is_instance_valid(t) and t.can_nurture())
		var open := _add_button("")
		open.set_meta(&"key", " (R)")
		var cheapest_rank: int = 0 if _free_rank() else nurturable.map(func(t: Tower) -> int: return t.get_nurture_price()).min()
		_priced(open, "Nurture %d · choose a rank" % nurturable.size(), _price(cheapest_rank), cheapest_rank, &"dew", false)  # Short: R refuses
		open.pressed.connect(_toggle_choices)
		_rank_preview_on(open, nurturable, Tower.Focus.NONE)
	for index in (rank_options.size() if _choosing else 0):
		var which: Tower.Focus = rank_options[index]
		var cost: Array = tower_seller.full_nurture_cost(selection, which)
		var plan_focus: Array = tower_seller.plan_nurture(selection, which)
		var button: Button
		if plan_focus[0].size() >= cost[0]:
			button = _choice_row(index, Tower.FOCUS_NAMES[which], "all %d" % cost[0], _price(cost[1]))
		else:
			button = _choice_row(index, Tower.FOCUS_NAMES[which], "%d of %d" % [plan_focus[0].size(), cost[0]], _price(plan_focus[1]))
			_mark_choice(button, not plan_focus[0].is_empty())  # None affordable: the press plays the refusal
		# The selected Warden's real change when it offers this choice ("holds every 3.0 → 2.7 s"), else the general text.
		var lead: Tower = _tower if is_instance_valid(_tower) and _tower.focus_options().has(which) else null
		button.tooltip_text = "Each gains a rank of %s: %s. Kept when it grows; can't be changed." % [
			Tower.FOCUS_NAMES[which], lead.focus_text(which) if lead != null else Tower.FOCUS_TEXT[which]]
		button.pressed.connect(func() -> void:
			_choosing = false
			tower_seller.nurture_group(tower_seller.selection, which))
		_rank_preview_on(button, selection.filter(func(t) -> bool: return is_instance_valid(t) and t.can_nurture()), which)
	var refund := tower_seller.get_selection_refund()
	var in_drift := not drift_director.is_build_phase()
	var sell := _add_footer_button("Sell %d · +%s Dew (%s)" % [selection.size(), BossDossier.thousands(refund), tower_seller.sell_key_name()])
	sell.tooltip_text = "Half the Dew back while nightmares walk." if in_drift else ""
	if _confirm_sell:
		sell.text = "Really sell %d while nightmares walk? +%d Dew" % [selection.size(), refund]
	sell.pressed.connect(_sell_group)
	if not tower_seller.can_sell():
		sell.text = tower_seller.sell_block_reason()
		sell.disabled = true
	var close := _add_footer_button("Close")
	close.pressed.connect(tower_seller.select.bind(null))

# Portrait and count for one kind in the selection.
func _group_row(data: TowerData, count: int) -> Control:
	var row := HBoxContainer.new()
	if data.texture != null:
		var icon := TextureRect.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = data.texture
		atlas.region = data.get_frame_rect(0)
		icon.texture = atlas
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		TapTip.attach(icon, "%s: %s" % [data.display_name, IconInfo.format(data.description)])
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
	var label := Label.new()
	label.text = "%d × %s" % [count, data.display_name]
	row.add_child(label)
	return row

static func _plural(data: TowerData, count: int) -> String:
	if count == 1 or data.display_name.ends_with("s"):
		return data.display_name
	if data.display_name.ends_with("ch") or data.display_name.ends_with("sh"):
		return data.display_name + "es"
	return data.display_name + "s"

# During a drift, the first press asks for confirmation; the second sells.
func _sell_group() -> void:
	# Settings > Gameplay "confirm before selling during a drift" (on by default).
	var ask: bool = HeartwoodMemory.get_settings().get("confirm_sell", true)
	if ask and not drift_director.is_build_phase() and not _confirm_sell:
		_confirm_sell = true
		_refresh()
		return
	_confirm_sell = false
	tower_seller.sell_selection()

# Targeting (screens_ui.md): a 4-way switch First / Last / Strongest / Closest for `towers` (one Warden or a
# group). A group with mixed modes shows none pressed; a press sets them all. T cycles (TowerSeller).
func _add_target_switch(towers: Array) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = "Targeting"
	row.add_child(label)
	var modes := {}
	for tower in towers:
		modes[tower.get_target_mode()] = true
	for mode in Tower.PLAYER_TARGET_MODES:
		var button := Button.new()
		button.text = Tower.TARGET_MODE_NAMES[mode]
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.button_pressed = modes.size() == 1 and modes.has(mode)
		button.tooltip_text = TARGET_TIPS[mode] + " (T cycles)"
		button.pressed.connect(func() -> void:
			tower_seller.set_target_group(towers, mode)
			_refresh())
		row.add_child(button)
	_buttons.add_child(row)

# A form that isn't unlocked yet (run_design.md "Dreamlight"): "Grow into Stormcap · Unlock with 1
# Dreamlight". With enough Dreamlight, the first click asks and the second unlocks it; otherwise it
# opens the Remember screen on that form (which also says what else it needs).
# Buffs (screens_ui.md "Buff readability"): every source with its amount, then the total; penalties in
# muted plum; a Warden source is a button that selects it and glides the camera there.
func _fill_buffs(tower: Tower) -> void:
	for child in _buffs.get_children():
		_buffs.remove_child(child)  # Out of the layout now: the height fits the new rows at once (user: "Hide" left a gap)
		child.queue_free()
	_buffs.visible = false
	if tower == null:
		return
	var entries := BuffSources.for_tower(tower)
	if entries.is_empty():
		return
	_buffs.visible = true
	var head := HBoxContainer.new()  # "Buffs" and its Details toggle: the list folds to its Total line
	var header := Label.new()
	header.text = "Buffs"
	UiStyle.caps(header)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(header)
	var details := Button.new()
	details.text = "Hide" if _buffs_open else "Details (%d)" % entries.size()
	details.flat = true
	details.focus_mode = Control.FOCUS_NONE
	details.pressed.connect(func() -> void:
		_buffs_open = not _buffs_open
		_fill_buffs(tower)
		_fit_height()
		if not get_tree().process_frame.is_connected(_fit_height):
			get_tree().process_frame.connect(_fit_height, CONNECT_ONE_SHOT))  # Again once the new rows are laid out
	head.add_child(details)
	_buffs.add_child(head)
	for entry in (entries if _buffs_open else []):
		var colour: Color = BuffSources.PENALTY_TEXT if entry.negative else BuffSources.color(entry.kind, entry.source)
		var row: Control
		if entry.source is Tower and is_instance_valid(entry.source):
			var link := Button.new()
			link.flat = true
			link.alignment = HORIZONTAL_ALIGNMENT_LEFT
			link.text = IconInfo.format(entry.label)  # Tokens as plain words on a button
			link.add_theme_color_override("font_color", colour)
			link.tooltip_text = "Select it"
			var source: Tower = entry.source
			link.pressed.connect(func() -> void: _go_to(source))
			row = link
		else:
			row = StatusLinks.make_label(entry.label, 15, colour)  # {Kinship} and status words link to the Codex
		_buffs.add_child(row)
	var total := BuffSources.totals(entries)
	var parts: Array[String] = []
	for stat in ["damage", "attack_speed", "range"]:
		if total.has(stat) and absf(total[stat]) > 0.0001:
			parts.append("%s %s" % [BuffSources._signed(total[stat], stat == "range"), BuffSources.STAT_WORDS[stat]])
	if not parts.is_empty():
		var sum := Label.new()
		sum.text = "Total: " + " · ".join(parts)
		_buffs.add_child(sum)

# A Warden source in Buffs: select it and glide the camera there.
func _go_to(tower: Tower) -> void:
	if not is_instance_valid(tower):
		return
	DriftMeter.focus_tower(tower)  # Selects it and glides the camera there (Main's)

# Growth preview (screens_ui.md "Preview the growth before growing"): while the pointer is on a Grow
# button, the Wardens show the new form (TowerPlacer.show_grow_preview).
func _preview_on(button: Button, pairs: Array) -> void:
	button.mouse_entered.connect(func() -> void: tower_placer.show_grow_preview(pairs))
	button.mouse_exited.connect(func() -> void:
		if _confirm_grow == null:
			tower_placer.hide_grow_preview())

# A grow key held: every selected Warden previews its option `index` (each kind its own); let go: gone.
func _on_grow_key_held(index: int, held: bool) -> void:
	if not held:
		tower_placer.hide_grow_preview()
		return
	var pairs := []
	for group in tower_seller.get_selection_groups():
		var options := Tower.grow_options(dream_state, group[0])
		if index < options.size():
			for tower in group[1]:
				pairs.append([tower, options[index][0]])
	tower_placer.show_grow_preview(pairs)

# Touch (platforms.md): the last input was a touch, so Grow asks with a first tap.
func _input(event: InputEvent) -> void:
	if _choosing and visible and event is InputEventKey and event.pressed and not event.echo:
		var key: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
		if key >= KEY_1 and key <= KEY_4:
			_pick_choice(key - KEY_1)
			get_viewport().set_input_as_handled()  # Not the Warden bar's 1–4 while choosing
			return
		if key == KEY_ESCAPE:
			_toggle_choices()  # Closes them (and keeps the selection)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventScreenTouch:
		_touch = true
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		_touch = false

# Q / E / Z: the Grow button's key badge, like Sell (X) and Nurture (R).
func _grow_key(button: Button, index: int) -> void:
	if index >= TowerSeller.GROW_OPTION_ACTIONS.size():
		return
	button.set_meta(&"grow_index", index)  # TowerSeller.grow_refused shakes it
	var key := TowerSeller.key_name(TowerSeller.GROW_OPTION_ACTIONS[index])
	if key != "":
		button.set_meta(&"key", " (%s)" % key)  # Added by _set_short after the price / missing part
		button.text += " (%s)" % key

# A form not unlocked yet: "Grow into Beacon · 2 Dreamlight (Q)" opens the Remember tree on it; short of
# Dreamlight it's the can't-afford style (the cost in POOR) and a press refuses; not open yet (Memory Grove,
# its branch first, drift 51) it's dim with the reason, and a press refuses too.
func _locked_form_button(button: Button, label: String, next: TowerData, towers: Array, index: int) -> void:
	# Not unlocked yet (user: "rename Grow to Unlock if they haven't unlocked it yet"): "Unlock Beacon · 2
	# Dreamlight (Q)"; once unlocked the same slot reads "Grow into Beacon · 300 Dew (Q)". No preview of a locked
	# form; a Grove-locked one stays "???" with no Unlock wording ("??? · in the Memory Grove"), as on Remember.
	button.tooltip_text = LOCKED_FORM_TIP
	if not dream_state.has_method("get_unlock_cost"):
		button.text = "%s · needs a Dream" % label  # Before Dreamlight
		button.disabled = true
		return
	var cost: int = dream_state.get_unlock_price(next)  # Waking Root's discount included (it can reach 0)
	var blocker: String = dream_state.get_unlock_blocker(next)
	if blocker == "Memory Grove":
		label = RememberScreen.UNKNOWN_NAME
		button.tooltip_text = RememberScreen.UNKNOWN_NAME
	if blocker != "":
		button.set_meta(&"label", label)
		button.set_meta(&"price", WardenHeaderView.blocker_text(blocker))
		_set_short(button, true, false)  # Not a price: just the dim look
	else:
		_priced(button, label, ("%d Dreamlight" % cost) if cost > 0 else "free", cost, &"dreamlight", true)
	button.pressed.connect(func() -> void:
		_confirm_unlock = null
		if tower_seller.refuse_if_short(towers, next, false, index):
			return  # Short of Dreamlight (or not open yet): shake, toast, the counter flashes; nothing opens
		# Playtest fix (screens_ui.md 2026-09-30): the Remember tree on that node, where it's unlocked.
		dream_state.open_remember(next))

# One rank of `which` on `tower`, as its effect: "28 → 33 damage", "2.5 → 2.8 range".
func _choice_preview(tower: Tower, which: Tower.Focus) -> String:
	match which:
		Tower.Focus.POWER:
			var mult := tower.get_rank_damage_multiplier()
			return "%d → %d damage" % [roundi(tower.get_damage()), roundi(tower.get_damage() * (mult + Tower.FOCUS_POWER) / maxf(mult, 0.01))]
		Tower.Focus.SWIFT:
			return "%.2f → %.2f/s" % [tower.get_attacks_per_second(), tower.get_attacks_per_second() * (1.0 + Tower.FOCUS_SWIFT)]
		Tower.Focus.REACH:
			return "%.1f → %.1f range" % [tower.get_range_cells(), tower.get_range_cells() + Tower.FOCUS_REACH]
		Tower.Focus.DEEP:
			return "Potency %d%% → %d%%" % [roundi(tower.get_potency() * 100.0), roundi((tower.get_potency() + Tower.deep_share()) * 100.0)]
	return tower.focus_text(which)

# R, then 1–4: presses the rank choice at `index` (single Warden or the group's), if it's there and affordable.
func _pick_choice(index: int) -> void:
	var choices := _buttons.get_children().filter(func(b) -> bool:
		return b is Button and b.get_meta(&"choice", -1) == index)
	if not choices.is_empty() and not choices[0].disabled:
		_choosing = false
		choices[0].pressed.emit()

# The Nurture button / R: open the rank's choices in place, or close them. A Warden with a single choice
# (the Sapling) nurtures at once.
func _toggle_choices() -> void:
	if not visible:
		return
	if not _choosing and not _can_afford_a_rank():
		_refuse_nurture()  # User: "still able to press the hotkey for nurture when I don't have enough Dew"
		return
	if _tower != null and tower_seller.selection.size() <= 1 and _tower.can_nurture() and not _tower.needs_focus():
		_nurture_with(_tower.default_choice())
		return
	_choosing = not _choosing
	_refresh()

# Whether any selected Warden can pay for its next rank now (First Care's free ranks count). Nothing to
# nurture at all is left to the old path (it does nothing).
func _can_afford_a_rank() -> bool:
	var towers: Array = tower_seller.selection.filter(func(t) -> bool: return is_instance_valid(t) and t.can_nurture())
	if towers.is_empty() or int(run_state.get("free_nurtures") if run_state.get("free_nurtures") != null else 0) > 0:
		return true
	return towers.any(func(t: Tower) -> bool: return t.get_nurture_price() <= run_state.dew)

# Short of Dew for any rank: no choices open, nothing is spent; the "can't buy" refusal instead (the Nurture
# button shakes; dew_short brings the "needs N Dew" toast, the Dew counter's flash and the refusal sound).
func _refuse_nurture() -> void:
	var prices: Array = tower_seller.selection.filter(func(t) -> bool: return is_instance_valid(t) and t.can_nurture()) \
		.map(func(t: Tower) -> int: return t.get_nurture_price())
	if not prices.is_empty():
		run_state.dew_short.emit(prices.min())
		_toast(tower_seller.dew_message(prices.min()))  # "Not enough Dew"
	nurture_refused += 1
	for button in _buttons.get_children():
		if button is Button and String(button.text).begins_with("Nurture"):
			_shake(button)

# First Care's free ranks: the next rank costs nothing.
func _free_rank() -> bool:
	return int(run_state.get("free_nurtures") if run_state.get("free_nurtures") != null else 0) > 0
var nurture_refused := 0  # Refusals so far (tests)

# One rank choice as a row of columns: name, its change, price, key. Fixed widths, so every row's
# columns line up (warden_stats.md "Playtest fix").
const CHOICE_NAME_WIDTH := 64.0
const CHOICE_PRICE_WIDTH := 60.0
const CHOICE_KEY_WIDTH := 22.0

func _choice_row(index: int, choice_name: String, change: String, price: String) -> Button:
	var button := _add_button("")
	button.set_meta(&"choice", index)
	button.custom_minimum_size.y = 30
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8
	row.offset_right = -6
	row.add_theme_constant_override("separation", 6)
	button.add_child(row)
	for column in [[choice_name, CHOICE_NAME_WIDTH, HORIZONTAL_ALIGNMENT_LEFT], [change, 0.0, HORIZONTAL_ALIGNMENT_LEFT],
			[price, CHOICE_PRICE_WIDTH, HORIZONTAL_ALIGNMENT_RIGHT], [str(index + 1), CHOICE_KEY_WIDTH, HORIZONTAL_ALIGNMENT_CENTER]]:
		var label := Label.new()
		label.text = column[0]
		label.horizontal_alignment = column[2]
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if column[1] > 0.0:
			label.custom_minimum_size.x = column[1]  # A floor: a longer name widens its column rather than being cut
		else:
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # The change wraps to a second line, never cut
			label.custom_minimum_size.x = 60
		row.add_child(label)
	var badge: Label = row.get_child(3)  # The key, as a badge like the Warden bar's numbers
	UiStyle.number(badge, 13, UiStyle.INK_DIM)
	# The button (its row is a child it doesn't size to) grows with a wrapped change line.
	var fit := func() -> void:
		if is_instance_valid(button) and is_instance_valid(row):
			button.custom_minimum_size.y = maxf(30.0, row.get_combined_minimum_size().y + 6.0)
	row.minimum_size_changed.connect(fit)
	row.resized.connect(fit)
	fit.call_deferred()
	return button

func _nurture_with(which: Tower.Focus) -> void:
	_choosing = false
	if tower_placer.nurture(_tower, which):
		_refresh()

# A Nurture price for a button: "40 Dew", or "free" (First Care's free ranks).
static func _price(dew: int) -> String:
	return "free" if dew <= 0 else "%d Dew" % dew

# Branch expansion: the branches this run didn't draw aren't Grow buttons (Tower.grow_options); one quiet line
# points at Remember, where a misty branch can be called back into the dream for Dreamlight. It sits in the info part
# (which scrolls), not among the actions, so the panel keeps within MAX_SHARE.
func _not_in_dream_button(data: TowerData) -> void:
	_clear_not_in_dream()
	var hidden := Tower.not_in_dream(dream_state, data)
	if hidden.is_empty():
		return
	var button := Button.new()
	button.name = "NotInDream"
	button.text = "%d more not in this dream · Remember" % hidden.size()
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_content.add_child(button)
	button.flat = true
	button.add_theme_color_override("font_color", UiStyle.INK_DIM)
	button.tooltip_text = "%s: not in this dream. Call one back on Remember." % ", ".join(hidden.map(
		func(form: TowerData) -> String: return form.display_name))
	button.pressed.connect(func() -> void: dream_state.open_remember(hidden[0]))

# Every rank pick, in its colour, counted ("Swift ×2"); one its current form doesn't use is dimmed with "no effect on
# <form>" (Nurture rework, Tower Code e2631f54: Tower.choice_applies). Empty for an unranked Warden.
func _fill_rank_picks() -> void:
	for child in _ranks_row.get_children():
		_ranks_row.remove_child(child)
		child.queue_free()
	_ranks_row.visible = _tower != null and _tower.rank > 0 and not _tower.rank_choices.is_empty()
	if not _ranks_row.visible:
		return
	var order: Array = []
	for which in _tower.rank_choices:
		if not order.has(which):
			order.append(which)
	for which in order:
		var n: int = _tower.rank_choices.count(which)
		var pick := Label.new()
		pick.name = "Pick_%d" % int(which)
		pick.text = Tower.FOCUS_NAMES.get(which, "?") + (" ×%d" % n if n > 1 else "")
		pick.add_theme_font_size_override("font_size", 14)
		pick.add_theme_color_override("font_color", Tower.FOCUS_COLORS.get(which, UiStyle.INK))
		pick.mouse_filter = Control.MOUSE_FILTER_PASS
		var applies: bool = _tower.choice_applies(which) if _tower.has_method("choice_applies") else true
		if applies:
			pick.tooltip_text = _tower.focus_text(which)
		else:
			pick.modulate.a = 0.4  # multiplier: dimmed, it does nothing here
			pick.tooltip_text = "No effect on %s" % _tower.tower_data.display_name
		_ranks_row.add_child(pick)

func _update_cover() -> void:
	WorldLabel.set_cover(&"warden_panel", get_global_rect(), is_visible_in_tree())

# The map's buff chips (BuffOverlay, made after this panel): when some had no room, the panel says how many.
func _hook_buff_overlay() -> void:
	if not is_inside_tree():
		return
	var overlay := get_tree().get_first_node_in_group(BuffOverlay.GROUP) as BuffOverlay
	if overlay != null and not overlay.hidden_changed.is_connected(_on_chips_hidden):
		overlay.hidden_changed.connect(_on_chips_hidden)
		_on_chips_hidden(overlay.hidden_chips)

func _on_chips_hidden(count: int) -> void:
	_map_note.text = "+%d more not labelled on the map" % count
	_map_note.visible = count > 0

func _clear_not_in_dream() -> void:
	var old := _content.get_node_or_null("NotInDream")
	if old != null:
		_content.remove_child(old)
		old.queue_free()

func _add_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_buttons.add_child(button)
	return button

func _evolve(into: TowerData) -> void:
	if into.footprint > _tower.get_footprint():
		# A 2×2 form: pick the square on the map (one valid square grows there at once).
		if tower_placer.begin_grow_choice(_tower, into):
			_refresh()
		return
	if tower_placer.evolve(_tower, into):
		_refresh()

# The Warden's damage type under the title (screens_ui.md "Damage-type icons"); hidden for Wardens
# that don't attack (Thornwalls).
const PORTRAIT_SIZE := 48.0
const WATCH_EVERY := 0.1  # Seconds between checks that the selection still looks like what the panel shows
var _watch_left := 0.0
var _shown := []  # [form, rank, Focus] of each selected Warden when the panel was last built

func _selection_state() -> Array:
	var state := []
	for tower in tower_seller.selection:
		if is_instance_valid(tower):
			state.append([tower.tower_data, tower.rank, tower.focus])
	return state


# The header portrait idles like the Warden on the map (called from _process).
func _animate_portrait(delta: float) -> void:
	if not visible or not _portrait.visible or not is_instance_valid(_tower) or _tower.tower_data.texture == null:
		return
	var data := _tower.tower_data
	_portrait_time += delta
	var frame := int(_portrait_time * data.animation_fps) % maxi(data.frame_count, 1)
	var region := data.get_frame_rect(frame)
	if _portrait_atlas.region != region:
		_portrait_atlas.region = region

# Hover and tap tips stay (screens_ui.md): Dew changes on every dispel, and rebuilding the panel then
# closed any tooltip under the pointer. Affordability updates in place; anything else that depends on Dew
# (group counts) waits until the pointer leaves the panel.
var _dew_dirty := false
var _group_refresh_queued := false  # Dew changed with a group selected: refresh soon (throttled)
var _group_refreshed_at := 0  # Ticks (ms) of the last Dew-driven group refresh
const GROUP_REFRESH_MS := 250  # A big selection's refresh walks every Warden: at most 4 times a second

func _on_dew_changed() -> void:
	_update_prices()  # Live counts, the style switching the moment it's affordable
	if _pointer_inside():
		_dew_dirty = true
	elif tower_seller.selection.size() > 1:
		# Group counts ("grow 3 of 5") follow the Dew, throttled: nurturing 200 Sprouts at once changes
		# the Dew 200 times, drifts change it on every dispel, and each refresh walks the whole selection.
		_group_refresh_queued = true

func _pointer_inside() -> bool:
	return is_visible_in_tree() and get_global_rect().has_point(get_global_mouse_position())

func _process(delta: float) -> void:
	_animate_portrait(delta)
	# A Warden grown or nurtured by a hotkey (Q / E / Z, G, R) or a group bloom: show its new form.
	_watch_left -= delta
	if visible and _watch_left <= 0.0:
		_watch_left = WATCH_EVERY
		if _selection_state() != _shown:
			_refresh()
	var now := Time.get_ticks_msec()
	var group_due := _group_refresh_queued and now - _group_refreshed_at >= GROUP_REFRESH_MS
	if (_dew_dirty and not _pointer_inside()) or group_due:
		_dew_dirty = false
		_group_refresh_queued = false
		_group_refreshed_at = now
		_refresh()

func _refresh_unless_hovered() -> void:
	_update_prices()  # Dreamlight-priced buttons follow at once, even under the pointer
	if _pointer_inside():
		_dew_dirty = true  # Rebuilt once the pointer leaves
	else:
		_refresh()

# Kindred / Whole Tree (tower_design.md "Kinships"): a quiet marker, the family's icon and its bonus.
func _kindred_row(line: String, bonus: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var whole := bonus > Kinships.KINDRED_BONUS
	var name := "Whole Tree" if whole else "Kindred"
	var tip := ("All three branches of the %s family are planted: its Wardens deal %d%% more damage." if whole \
		else "Two branches of the %s family are planted: its Wardens deal %d%% more damage.") \
		% [NightmareIcons.family_name(line), roundi(bonus * 100)]
	TapTip.attach(row, tip)  # Hover or tap (screens_ui.md "Every icon can be hovered or tapped")
	var icon := TextureRect.new()
	icon.texture = IconInfo.damage_type_icon(line)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.custom_minimum_size = Vector2(16, 16)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var label := Label.new()
	label.text = "%s +%d%%" % [name, roundi(bonus * 100)]
	label.add_theme_color_override("font_color", Kinships.FAMILY_COLORS.get(line, UiStyle.LIVE))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	return row

# The Nurture / Focus tooltip's last line, "+60 when it grows into Thunderhead.": what this rank adds to the
# next growth's price (warden_stats.md; off the button since "less hand-holding"). "" when nothing.
func _growth_note() -> String:
	var next := _tower.next_growth()
	if next == null:
		return ""
	var extra := _tower.get_next_rank_growth_extra(next)
	return "\n\n+%d when it grows into %s." % [extra, next.display_name] if extra > 0 else ""

# Sell / Close: in the footer, never scrolled away.
func _add_footer_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Never clipped: "Sell · +113 Dew (X)" whole (user screenshot)
	_footer.add_child(button)
	return button

# The middle scrolls once the panel would pass MAX_SHARE of the screen (the Dreams row stays clear).
func _fit_height() -> void:
	if _content == null:
		return
	var screen: float = get_viewport().get_visible_rect().size.y
	# The whole panel (info + actions + footer) within MAX_SHARE of the screen, never past its top margin.
	var actions := _buttons.get_combined_minimum_size().y + _footer.get_combined_minimum_size().y + 40.0
	var room := minf(screen * MAX_SHARE, screen - TOP_CLEAR - BOTTOM_MARGIN) - actions
	var wanted := _content.get_combined_minimum_size().y
	_scroll.custom_minimum_size.y = clampf(wanted, 0.0, maxf(room, MIN_INFO))
	# No reset_size(): the panel is anchored to the bottom and grows upward; resetting kept its top and pushed
	# the buttons off the bottom of the screen (the "can't upgrade" bug). It's placed from its bottom edge instead.
	_place_from_bottom.call_deferred()

# Anchored to the bottom: its top edge follows its height (grows up, shrinks down), never past the screen.
func _place_from_bottom() -> void:
	var height := get_combined_minimum_size().y
	offset_top = offset_bottom - height

# --- Prices on action buttons (screens_ui.md "can't buy", user 2026-10-01) ---------------------------------
# Every action the player can't pay for looks the same: the plain frame, a dim INK_DIM label, and only the
# cost in POOR ("Nurture to rank III · 120 Dew (R)", "Grow into Beacon · 2 Dreamlight (Q)"; no "more
# needed": user, "a bit too much hand holding"). Still pressable: the press plays the refusal
# (TowerSeller.refuse_if_short / _refuse_nurture: the button shakes, "Not enough Dew", the counter flashes).
# Dew / Dreamlight changes update it in place (_update_prices), back to the normal look the moment it's affordable.
const FONT_STATES := ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]

# `label` and `price` make the line "<label> · <price>" (the key badge follows); `cost` in `currency` decides short.
func _priced(button: Button, label: String, price: String, cost: int, currency: StringName, primary: bool) -> void:
	button.set_meta(&"label", label)
	button.set_meta(&"price", price)
	button.set_meta(&"cost", cost)
	button.set_meta(&"currency", currency)
	button.set_meta(&"primary", primary)
	button.set_meta(&"tip", button.tooltip_text)
	_apply_price(button)

func _apply_price(button: Button) -> void:
	var currency: StringName = button.get_meta(&"currency", &"dew")
	var have: int = dream_state.dreamlight if currency == &"dreamlight" else run_state.dew
	var short := int(button.get_meta(&"cost", 0)) > have
	var tip: String = button.get_meta(&"tip", "")
	if short:
		var why := "Not enough Dreamlight: it's unlocked on the Remember screen." if currency == &"dreamlight" else "Not enough Dew."
		button.tooltip_text = why + ("\n\n" + tip if tip != "" else "")
	else:
		button.tooltip_text = tip
	_set_short(button, short)

# The look: normal (primary frame for Grow), or the can't-afford style. A short line is drawn by an overlay of
# three labels (label, price, key; the button's own text stays, transparent, so sizes and tests see the line).
# `poor_price` false: a dim line with nothing in POOR (a form that isn't open yet).
func _set_short(button: Button, short: bool, poor_price := true) -> void:
	button.set_meta(&"short", short)
	button.set_meta(&"cant_afford", short)  # CantAfford.is_shown, like the Remember screen's buttons
	var label: String = button.get_meta(&"label", "")
	var price: String = button.get_meta(&"price", "")
	var key: String = button.get_meta(&"key", "")
	button.text = label + (" · " + price if price != "" else "") + key
	button.modulate.a = 1.0
	var overlay := button.get_node_or_null("Short")
	if not short:
		if overlay != null:
			overlay.free()
		button.theme_type_variation = &"PrimaryButton" if button.get_meta(&"primary", false) else &""
		for state in FONT_STATES:
			button.remove_theme_color_override(state)
		return
	button.theme_type_variation = &""  # One frame for every short action
	for state in FONT_STATES:
		button.add_theme_color_override(state, Color(UiStyle.INK, 0.0))  # The overlay draws the words
	if overlay == null:
		overlay = HBoxContainer.new()
		overlay.name = "Short"
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_theme_constant_override("separation", 0)
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.offset_left = button.get_theme_stylebox("normal").get_margin(SIDE_LEFT)
		button.add_child(overlay)
		for i in 3:
			var part := Label.new()
			part.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			part.mouse_filter = Control.MOUSE_FILTER_IGNORE
			part.add_theme_font_override("font", button.get_theme_font("font"))
			part.add_theme_font_size_override("font_size", button.get_theme_font_size("font_size"))
			overlay.add_child(part)
	var parts := [label + (" · " if price != "" else ""), price, key]
	for i in 3:
		var part := overlay.get_child(i) as Label
		part.text = parts[i]
		part.add_theme_color_override("font_color", UiStyle.POOR if i == 1 and poor_price else UiStyle.INK_DIM)

# A Nurture choice row (columns: name, change, price, key): the same style, its price column in POOR.
func _mark_choice(button: Button, affordable: bool) -> void:
	button.set_meta(&"short", not affordable)
	var row := button.get_child(0) as HBoxContainer if button.get_child_count() > 0 else null
	if row == null or row.get_child_count() < 4:
		return
	for i in 4:
		var colour: Color = UiStyle.INK if affordable else UiStyle.INK_DIM
		if i == 2 and not affordable:
			colour = UiStyle.POOR
		if i == 3:
			continue  # The key badge keeps its own colour
		(row.get_child(i) as Label).add_theme_color_override("font_color", colour)

# Dew or Dreamlight changed: every priced button follows at once (no rebuild: a tooltip under the pointer stays).
func _update_prices() -> void:
	for button in _buttons.get_children():
		if not button is Button:
			continue
		if button.has_meta(&"currency"):
			_apply_price(button)
		elif button.has_meta(&"cost") and button.has_meta(&"choice"):
			_mark_choice(button, run_state.can_afford(int(button.get_meta(&"cost"))))

func _shake(button: Control) -> void:
	CantAfford.shake(button)  # The Remember screen's shake (none under reduced motion)

# Seedbearer / Grove Keeper with a ripe seed (Tower Code's BranchKit.seeds_ready, the golden seed badge): "Plant Sprout
# (N)" lights the open cells beside it (TowerPlacer.begin_seed_choice) and a click there plants a free Sprout. At a
# rest only; the button is the way in on touch.
func _seed_button() -> void:
	var seeds := BranchKit.seeds_ready(_tower)
	if seeds <= 0:
		return
	var button := _add_button("Plant Sprout (%d)" % seeds)
	button.name = "PlantSprout"
	button.tooltip_text = "A free Sprout in an open cell beside it. Pick the cell on the map (Esc cancels)."
	if not Tower.resting:
		button.text = "Plant Sprout (%d) · at the next rest" % seeds
		button.disabled = true
		return
	var tower := _tower
	button.pressed.connect(func() -> void:
		if not tower_placer.begin_seed_choice(tower):
			_shake(button)
			_toast("No open cell beside it"))

func _toast(text: String) -> void:
	var hud := get_parent()
	if hud != null and hud.has_method("show_toast"):
		hud.show_toast(text)

# TowerSeller refused a grow (Q / E / Z, G, or one of these buttons): shake its button(s), say why.
func _on_grow_refused(index: int, text: String) -> void:
	grow_refused += 1
	_toast(text)
	for button in _buttons.get_children():
		if button is Button and button.has_meta(&"grow_index") and (index < 0 or int(button.get_meta(&"grow_index")) == index):
			_shake(button)
var grow_refused := 0  # Refusals so far (tests)

# Nurture range preview (user: "hovering Nurture range should show the range it would go into"): pointing at
# (or focusing, touch / controller) a Nurture button or rank choice shows each Warden's range after that rank.
func _rank_preview_on(button: Button, towers: Array, focus: Tower.Focus) -> void:
	var show := func() -> void: tower_placer.show_rank_preview(towers, focus)
	button.mouse_entered.connect(show)
	button.focus_entered.connect(show)
	button.mouse_exited.connect(tower_placer.hide_rank_preview)
	button.focus_exited.connect(tower_placer.hide_rank_preview)
	button.tree_exiting.connect(tower_placer.hide_rank_preview)  # The panel rebuilt under the pointer

# One soft pulse on the Grow buttons (`kind` &"grow") or the Nurture button (&"nurture"): the grow onboarding
# (onboarding.md, Main's GrowHints) points at them once. "Unlock …" slots (grow_index too) never pulse: only
# a form you can grow now. Returns how many buttons pulsed.
func pulse(kind: StringName) -> int:
	var count := 0
	for button in _buttons.get_children():
		if not button is Button or button.is_queued_for_deletion():
			continue
		var text := String(button.text)
		var match_kind: bool = (kind == &"grow" and button.has_meta(&"grow_index") and text.begins_with("Grow")) \
			or (kind == &"nurture" and text.begins_with("Nurture"))
		if match_kind:
			count += 1
			var tween := button.create_tween()
			tween.tween_property(button, "modulate", Color(1.5, 1.35, 1.0), 0.25)  # A multiplier (glow), not a colour
			tween.tween_property(button, "modulate", Color.WHITE, 0.6)
	return count
