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
var _body := Label.new()
var _groups := VBoxContainer.new()  # Several selected: one row per kind with its portrait
var _buttons := VBoxContainer.new()
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
	box.add_child(_header)
	_buffs.add_theme_constant_override("separation", 1)
	box.add_child(_buffs)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(280, 0)
	box.add_child(_body)
	box.add_child(_groups)
	box.add_child(_buttons)
	visible = false

	tower_seller.tower_selected.connect(_show)
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
	tower_seller.selection_changed.connect(func(_t: Array[Tower]) -> void:
		_confirm_grow = null
		_choosing = false)

# TowerSeller emits tower_selected right before selection_changed, which refreshes: refreshing here
# too built the panel twice per selection change (slow with a big selection).
func _show(tower: Tower) -> void:
	_tower = tower

func _refresh() -> void:
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
		if _tower.choices_text() != "":
			_title.text += " · %s" % _tower.choices_text()  # "Power ×2, Reach"
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
			lines.append("This run: %d damage · %.0f/s · from combos %d%%" % [roundi(run),
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

	for child in _buttons.get_children():
		child.queue_free()
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
		if option[1]:
			var grow := _tower.get_grow_cost(next)  # Ranked Wardens also pay the rank difference
			var cost: int = grow.total
			button.text = "Grow into %s · %d Dew" % [next.display_name, cost]
			button.tooltip_text = IconInfo.format(next.description)  # {spored}-style tokens as words
			if grow.ranks > 0:
				button.tooltip_text += "\n\n%d Dew + %d for its rank %s." % [grow.base, grow.ranks, Tower.rank_name(_tower.rank)]
			button.disabled = not run_state.can_afford(cost)
			button.set_meta(&"cost", cost)  # Affordability updates in place on Dew changes
			var awake := tower_placer.ascended_blocker(next)
			if awake != "":
				button.text = "Grow into %s · %s" % [next.display_name, awake]  # One per family
				button.disabled = true
			elif next.footprint > _tower.get_footprint() and tower_placer.get_grow_squares(_tower, next).is_empty():
				# A 2×2 form needs three free cells (or Thornwalls) beside it, and the path must stay open.
				button.text = "Grow into %s · Needs 3 free cells beside it" % next.display_name
				button.disabled = true
			var changes := tower_placer.grow_changes(_tower, next)
			if changes != "":
				button.tooltip_text += "\n\n" + changes
			if _confirm_grow == next:
				button.text = "Grow · %d Dew" % cost  # Touch: the second tap grows
			button.pressed.connect(func() -> void:
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
			_locked_form_button(button, "Grow into %s" % next.display_name, next)
		_grow_key(button, index)
		_preview_on(button, [[_tower, next]])
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
				var nurture := _add_button("Nurture to rank %s · %s (R)" % [Tower.rank_name(_tower.rank + 1), _price(cost)])
				nurture.tooltip_text = ("Choose what rank %s adds. Kept when it grows; can't be changed." % Tower.rank_name(_tower.rank + 1)
					if _tower.needs_focus() else "Rank %s: %s." % [Tower.rank_name(_tower.rank + 1), _tower.focus_text(_tower.default_choice())]) + _growth_note()
				nurture.disabled = not run_state.can_afford(cost)
				nurture.set_meta(&"cost", cost)  # Affordability updates in place on Dew changes
				nurture.pressed.connect(_toggle_choices)
			else:
				var choices: Array = _tower.focus_options()
				for index in choices.size():
					var which: Tower.Focus = choices[index]
					var button := _choice_row(index, Tower.FOCUS_NAMES[which], _choice_preview(_tower, which), _price(cost))
					button.tooltip_text = "Rank %s: %s. Kept when it grows; can't be changed." % [
						Tower.rank_name(_tower.rank + 1), _tower.focus_text(which)] + _growth_note()
					button.disabled = not run_state.can_afford(cost)
					button.set_meta(&"cost", cost)
					button.pressed.connect(_nurture_with.bind(which))
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
	var sell := _add_button("Sell · +%d Dew (%s)" % [refund, tower_seller.sell_key_name()])  # Its hotkey, like Nurture's (R)
	sell.tooltip_text = note
	sell.pressed.connect(func() -> void: tower_seller.sell(_tower.cell))
	if _tower.tower_data.rooted:
		sell.text = "Permanent: the Sapling can't be sold or moved"
		sell.disabled = true
	elif not tower_seller.can_sell():
		sell.text = "Overgrown: no selling while nightmares walk"
		sell.disabled = true
	var close := _add_button("Close")
	close.pressed.connect(tower_seller.select.bind(null))

func _is_eldest(tower: Tower) -> bool:
	return dream_state.has_method("is_eldest") and dream_state.is_eldest(tower)

# One row of stats ("Damage 24 · 1.00/s · range 2.50"): each part is its icon and a label, both
# explaining the stat on hover and on tap (IconInfo). `parts`: [[text, stat id], …] or
# [text, status id, true] for a status (&"" = plain text).
# Several Wardens selected: grouped by kind, with totals, group grow buttons and Sell all.
func _refresh_group() -> void:
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

	for child in _buttons.get_children():
		child.queue_free()
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
			button.tooltip_text = IconInfo.format(next.description)  # {spored}-style tokens as words
			if not option[1]:
				_locked_form_button(button, "%s → %s" % [_plural(data, towers.size()), next.display_name], next)
				_grow_key(button, index)
				_preview_on(button, towers.map(func(t: Tower) -> Array: return [t, next]))
				continue
			# Each pays Tower.get_grow_cost (ranked ones their rank difference too).
			var plan: Array = tower_seller.plan_grow(towers, next)
			var affordable: int = plan[0]
			if affordable >= towers.size():
				button.text = "Grow %d %s into %s · %d Dew" % [towers.size(), _plural(data, towers.size()),
					next.display_name, plan[1]]
			else:
				# Grows as many as the Dew allows, closest to the Heartwood first.
				button.text = "Grow %d of %d %s into %s · %d Dew" % [affordable, towers.size(),
					_plural(data, towers.size()), next.display_name, plan[1]]
				button.disabled = affordable == 0
			var awake := tower_placer.ascended_blocker(next)
			if awake != "":
				button.text = "%s → %s · %s" % [_plural(data, towers.size()), next.display_name, awake]
				button.disabled = true
			button.pressed.connect(func() -> void: tower_seller.grow_group(towers, next))
			_grow_key(button, index)
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
		var open := _add_button("Nurture %d · choose a rank (R)" % selection.filter(func(t) -> bool:
			return is_instance_valid(t) and t.can_nurture()).size())
		open.pressed.connect(_toggle_choices)
	for index in (rank_options.size() if _choosing else 0):
		var which: Tower.Focus = rank_options[index]
		var cost: Array = tower_seller.full_nurture_cost(selection, which)
		var plan_focus: Array = tower_seller.plan_nurture(selection, which)
		var button: Button
		if plan_focus[0].size() >= cost[0]:
			button = _choice_row(index, Tower.FOCUS_NAMES[which], "all %d" % cost[0], _price(cost[1]))
		else:
			button = _choice_row(index, Tower.FOCUS_NAMES[which], "%d of %d" % [plan_focus[0].size(), cost[0]], _price(plan_focus[1]))
			button.disabled = plan_focus[0].is_empty()
		button.tooltip_text = "Each gains a rank of %s: %s. Kept when it grows; can't be changed." % [
			Tower.FOCUS_NAMES[which], Tower.FOCUS_TEXT[which]]
		button.pressed.connect(func() -> void:
			_choosing = false
			tower_seller.nurture_group(tower_seller.selection, which))
	var refund := tower_seller.get_selection_refund()
	var in_drift := not drift_director.is_build_phase()
	var sell := _add_button("Sell %d · +%d Dew (%s)" % [selection.size(), refund, tower_seller.sell_key_name()])
	sell.tooltip_text = "Half the Dew back while nightmares walk." if in_drift else ""
	if _confirm_sell:
		sell.text = "Really sell %d while nightmares walk? +%d Dew" % [selection.size(), refund]
	sell.pressed.connect(_sell_group)
	if not tower_seller.can_sell():
		sell.text = "Overgrown: no selling while nightmares walk"
		sell.disabled = true
	var close := _add_button("Close")
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
		child.queue_free()
	_buffs.visible = false
	if tower == null:
		return
	var entries := BuffSources.for_tower(tower)
	if entries.is_empty():
		return
	_buffs.visible = true
	var header := Label.new()
	header.text = "Buffs"
	UiStyle.caps(header)
	_buffs.add_child(header)
	for entry in entries:
		var colour: Color = BuffSources.COLORS.penalty if entry.negative else BuffSources.color(entry.kind, entry.source)
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
	var key := TowerSeller.key_name(TowerSeller.GROW_OPTION_ACTIONS[index])
	if key != "":
		button.text += " (%s)" % key

func _locked_form_button(button: Button, label: String, next: TowerData) -> void:
	button.tooltip_text = IconInfo.format(next.description)  # {spored}-style tokens as words
	if not dream_state.has_method("get_unlock_cost"):
		button.text = "%s · needs a Dream" % label  # Before Dreamlight
		button.disabled = true
		return
	var cost: int = dream_state.get_unlock_cost(next)
	var blocker: String = dream_state.get_unlock_blocker(next)
	var affordable: bool = dream_state.can_unlock(next) and dream_state.dreamlight >= cost
	button.text = "%s · Unlock with %d Dreamlight" % [label, cost]
	if blocker != "":
		button.text = "%s · %s" % [label, blocker]
	elif not affordable:
		button.text += " (%d)" % dream_state.dreamlight  # What you have
	if blocker != "" or not affordable:
		_dim(button)  # Glow means "you can do this now"; still opens Remember
	button.pressed.connect(_on_locked_form.bind(next, affordable and blocker == ""))

# Can't do it now, but still clickable: the plain, dimmed look instead of the primary glow.
func _dim(button: Button) -> void:
	button.theme_type_variation = &""
	button.modulate.a = 0.6

func _on_locked_form(next: TowerData, _can_unlock_now: bool) -> void:
	# Playtest fix (screens_ui.md 2026-09-30): a form not unlocked yet opens the Remember tree on that node,
	# where it's unlocked (or shows what it needs first).
	_confirm_unlock = null
	dream_state.open_remember(next)

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
			return "Potency %d%% → %d%%" % [roundi(tower.get_potency() * 100.0), roundi((tower.get_potency() + Tower.FOCUS_DEEP) * 100.0)]
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
	if _tower != null and tower_seller.selection.size() <= 1 and _tower.can_nurture() and not _tower.needs_focus():
		_nurture_with(_tower.default_choice())
		return
	_choosing = not _choosing
	_refresh()

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
		label.clip_text = true
		if column[1] > 0.0:
			label.custom_minimum_size.x = column[1]
		else:
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
	var badge: Label = row.get_child(3)  # The key, as a badge like the Warden bar's numbers
	UiStyle.number(badge, 13, UiStyle.INK_DIM)
	return button

func _nurture_with(which: Tower.Focus) -> void:
	_choosing = false
	if tower_placer.nurture(_tower, which):
		_refresh()

# A Nurture price for a button: "40 Dew", or "free" (First Care's free ranks).
static func _price(dew: int) -> String:
	return "free" if dew <= 0 else "%d Dew" % dew

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
	for button in _buttons.get_children():
		if button is Button and button.has_meta(&"cost"):
			var disabled: bool = not run_state.can_afford(int(button.get_meta(&"cost")))
			if button.disabled != disabled:
				button.disabled = disabled
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
	var tip := ("All three branches of the %s family are planted: its Wardens deal +%d%% damage." if whole \
		else "Two branches of the %s family are planted: its Wardens deal +%d%% damage.") \
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
