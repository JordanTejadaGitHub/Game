extends PanelContainer

# Bottom-left panel for the selected Warden: what it does, its stats (including Dreams), what it
# can grow into (Dew cost, or which Dream it needs) and Sell. Built in code; hidden with no selection.

const TARGET_TIPS := {
	TowerData.TargetMode.FIRST: "The nightmare furthest along the path",
	TowerData.TargetMode.STRONGEST: "The nightmare with the most health left",
	TowerData.TargetMode.CLOSEST: "The nightmare nearest this Warden",
}

@onready var tower_seller: TowerSeller = %TowerSeller
@onready var tower_placer: TowerPlacer = %TowerPlacer
@onready var dream_state: DreamState = %DreamState
@onready var run_state: RunState = %RunState
@onready var drift_director: DriftDirector = %DriftDirector

var _tower: Tower = null
var _title := Label.new()
var _damage_type := HBoxContainer.new()  # Under the title: the damage type icon + name (one Warden)
var _desc: RichTextLabel  # What it does, with its status words as links (StatusLinks)
var _stats := VBoxContainer.new()  # Stat rows: each stat explains itself on hover and tap (IconInfo)
var _body := Label.new()
var _groups := VBoxContainer.new()  # Several selected: one row per kind with its portrait
var _buttons := VBoxContainer.new()
var _confirm_sell := false  # Selling a group during a drift asks once more
var _confirm_unlock: TowerData = null  # Unlocking a form with Dreamlight asks once more
var _confirm_eldest := false  # Rank VI would crown the Eldest: asks once more

func _ready() -> void:
	custom_minimum_size = Vector2(300, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	UiStyle.title(_title, UiStyle.TITLE_SIZE)
	box.add_child(_title)
	# Damage type (enemy_design.md "Damage types"): the type's icon and "Light damage" in its colour.
	_damage_type.add_theme_constant_override("separation", 4)
	_damage_type.add_child(TextureRect.new())
	_damage_type.get_child(0).stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_damage_type.get_child(0).expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_damage_type.get_child(0).custom_minimum_size = Vector2(16, 16)
	_damage_type.add_child(Label.new())
	box.add_child(_damage_type)
	_desc = StatusLinks.make_label("", 16)
	_desc.custom_minimum_size = Vector2(280, 0)
	box.add_child(_desc)
	_stats.add_theme_constant_override("separation", 2)
	box.add_child(_stats)
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
	run_state.dew_changed.connect(_refresh.unbind(1))
	dream_state.unlocks_changed.connect(_refresh)
	dream_state.card_taken.connect(_refresh.unbind(1))
	if dream_state.has_signal("dreamlight_changed"):
		dream_state.dreamlight_changed.connect(_refresh.unbind(1))
	drift_director.build_phase_changed.connect(_refresh.unbind(1))

func _show(tower: Tower) -> void:
	_tower = tower
	_refresh()

func _refresh() -> void:
	for child in _groups.get_children():
		child.queue_free()
	if tower_seller.selection.size() > 1:
		visible = true
		_desc.visible = false
		for child in _stats.get_children():
			child.queue_free()
		_body.visible = true
		_title.tooltip_text = ""
		_refresh_group()
		return
	if not is_instance_valid(_tower) or _tower.is_queued_for_deletion():
		_tower = null
		visible = false
		return
	visible = true
	var data := _tower.tower_data
	_title.text = data.display_name
	_show_damage_type(data)
	if _tower.rank > 0:
		_title.text += " · Rank %s" % Tower.rank_name(_tower.rank)
		if _is_eldest(_tower):
			_title.text += " · Eldest"
		if _tower.focus != Tower.Focus.NONE:
			_title.text += " · %s" % Tower.FOCUS_NAMES[_tower.focus]
	_title.tooltip_text = ""
	if _tower.rank > 0:
		_title.tooltip_text = IconInfo.stat_tooltip(&"rank") + ("\n" + IconInfo.stat_tooltip(&"focus") if _tower.focus != Tower.Focus.NONE else "")
	_title.mouse_filter = Control.MOUSE_FILTER_PASS if _title.tooltip_text != "" else Control.MOUSE_FILTER_IGNORE
	_desc.text = StatusLinks.bbcode(data.description)  # {damp}-style tokens and plain names both work
	if _tower.legacy_data != null:
		# An Ascended form still makes its final form's attack.
		_desc.text += "\n[i]Still %s: %s[/i]" % [_tower.legacy_data.display_name, StatusLinks.bbcode(_tower.legacy_data.description)]
	_desc.visible = _desc.text != ""
	for child in _stats.get_children():
		child.queue_free()
	var lines: Array[String] = []
	var attack := _tower.attack_data
	if data.attack_kind == TowerData.AttackKind.AURA:
		_stat_row([["Aura", &""], ["range %.2f" % _tower.get_range_cells(), &"range"]])
	elif data.attack_kind == TowerData.AttackKind.COPY and _tower.get_copied() == null:
		lines.append("Nothing to copy: plant it beside an attacking Warden.")
	elif data.can_attack:
		if _tower.get_copied() != null:
			lines.append("Copying %s at %d%%" % [attack.display_name, roundi(data.copy_share * 100)])
		var range_text := "range %.2f" % _tower.get_range_cells()
		if attack.min_range > 0.0:
			range_text = "range %.1f–%.1f" % [attack.min_range, _tower.get_range_cells()]
		_stat_row([["Damage %.0f" % _tower.get_damage(), &"damage"],
			["%.2f/s" % _tower.get_attacks_per_second(), &"attack_speed"],
			[range_text, &"range"]])
		var second: Array = []
		if _tower.get_crit_chance() > 0.0:
			second.append(["Crit %d%%" % roundi(_tower.get_crit_chance() * 100), &"crit_chance"])
			second.append(["×%s" % str(attack.crit_multiplier), &"crit_damage"])
		var potency := _tower.get_potency()
		if not is_equal_approx(potency, 1.0):
			second.append(["Potency %d%%" % roundi(potency * 100), &"potency"])  # Effect damage
		if not second.is_empty():
			_stat_row(second)
		if attack.applies_status != &"":
			_stat_row([["Applies %s%s" % [IconInfo.status_name(attack.applies_status),
				" ×%d" % attack.status_stacks if attack.status_stacks > 1 else ""], attack.applies_status, true]])
	else:
		lines.append("A wall: no attack.")
	_stats.add_child(DreamBonusView.make_rows(_tower))  # "Dreams on this Warden": on, off (and why), run-wide
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
	if not links.is_empty():
		lines.append("Combos with: " + ", ".join(links.map(func(l: Array) -> String: return l[1])))
	var kin := Kinships.find(_tower)
	if kin != null:
		var kin_line := kin.describe(_tower)  # "Kin: Bloomcap · Slumber Rot · Blooming (3 drifts to Old Kin)"
		if kin_line != "":
			lines.append(kin_line)
		else:
			var hint := kin.no_kin_hint(_tower)  # "No kin. A Chime Stone within 2 cells would form Night Chimes."
			if hint != "":
				lines.append(hint)
		var family := kin.family_bonus(data.line)
		if family > 0.0:
			lines.append("%s: +%d%% damage for the family" % ["Whole Tree" if family > Kinships.KINDRED_BONUS else "Kindred",
				roundi(family * 100)])
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
		var birds := _add_button("Birds: %s (click to change)" % ("all on the strongest" if _tower.focus_strongest else "spread out"))
		birds.pressed.connect(func() -> void:
			_tower.focus_strongest = not _tower.focus_strongest
			_refresh())
	var options := Tower.grow_options(dream_state, data)
	if options.is_empty() and data.line == "sprout":
		_add_button(Tower.NO_FAMILY_YET).disabled = true  # No family picked yet
	for option in options:
		var next: TowerData = option[0]
		var button := _add_button("")
		UiStyle.primary(button)  # Grow is the panel's main action (ui_style.md)
		if option[1]:
			var grow := _tower.get_grow_cost(next)  # Ranked Wardens also pay the rank difference
			var cost: int = grow.total
			button.text = "Grow into %s · %d Dew" % [next.display_name, cost]
			if grow.ranks > 0:
				button.text += " (%d + %d for rank %s)" % [grow.base, grow.ranks, Tower.rank_name(_tower.rank)]
			button.tooltip_text = IconInfo.format(next.description)  # {spored}-style tokens as words
			button.disabled = not run_state.can_afford(cost)
			var awake := tower_placer.ascended_blocker(next)
			if awake != "":
				button.text = "Grow into %s · %s" % [next.display_name, awake]  # One per family
				button.disabled = true
			elif next.footprint > _tower.get_footprint() and tower_placer.get_grow_squares(_tower, next).is_empty():
				# A 2×2 form needs three free cells (or Thornwalls) beside it, and the path must stay open.
				button.text = "Grow into %s · Needs room: 3 free cells next to it (2×2)" % next.display_name
				button.disabled = true
			button.pressed.connect(_evolve.bind(next))
		else:
			_locked_form_button(button, "Grow into %s" % next.display_name, next)
	if _tower.needs_focus():
		# Rank III asks for a Focus, kept through growth and never changed.
		var cost := _tower.get_nurture_cost()
		for which in [Tower.Focus.POWER, Tower.Focus.SWIFT, Tower.Focus.REACH, Tower.Focus.DEEP]:
			# Usually rank III; a Warden planted at a higher rank (Remembered Care) chooses on its next one.
			var button := _add_button("Rank %s · %s: %s per rank · %s" % [Tower.rank_name(_tower.rank + 1),
				Tower.FOCUS_NAMES[which], Tower.FOCUS_TEXT[which], _price(cost)])
			button.tooltip_text = "The usual rank gains, plus this Focus at ranks III, IV and V. Can't be changed later."
			button.disabled = not run_state.can_afford(cost)
			button.pressed.connect(func() -> void:
				if tower_placer.nurture(_tower, which):
					_refresh())
	elif _tower.can_nurture():
		var cost := _tower.get_nurture_cost()
		# The Eldest (a Legendary): rank VI crowns the one Warden that can grow past V, so ask first.
		var eldest_ask: bool = dream_state.has_method("needs_eldest_confirm") and dream_state.needs_eldest_confirm(_tower)
		if eldest_ask and _confirm_eldest:
			_add_button("Make this the Eldest? Only one Warden can grow past rank V").disabled = true
			var yes := _add_button("Yes: make it the Eldest · rank %s · %s" % [Tower.rank_name(_tower.rank + 1), _price(cost)])
			yes.disabled = not run_state.can_afford(cost)
			yes.pressed.connect(func() -> void:
				_confirm_eldest = false
				if dream_state.make_eldest(_tower):
					tower_placer.nurture(_tower)
				_refresh())
			_add_button("Not now").pressed.connect(func() -> void:
				_confirm_eldest = false
				_refresh())
		else:
			var nurture := _add_button("Nurture to rank %s · %s (R)" % [Tower.rank_name(_tower.rank + 1), _price(cost)])
			nurture.tooltip_text = "+10%% damage, +4%% attack speed, +0.1 range%s. Kept when it grows." % (
				", and %s" % Tower.FOCUS_TEXT[_tower.focus] if _tower.focus != Tower.Focus.NONE else "")
			nurture.disabled = not run_state.can_afford(cost)
			nurture.pressed.connect(func() -> void:
				if eldest_ask:
					_confirm_eldest = true
				else:
					tower_placer.nurture(_tower)
				_refresh())
	elif _tower.nurture_blocker() != "":
		var locked := _add_button(_tower.nurture_blocker())  # "Rank III needs a Nurture Dream"
		locked.disabled = true
		locked.tooltip_text = "Every Warden can reach rank II. A Nurture Dream opens ranks III-V and the Focus."
	elif _tower.can_be_nurtured() and _tower.rank > 0:
		var others_can: bool = dream_state.has_method("get_max_rank") and dream_state.get_max_rank() > _tower.rank
		if others_can and not _is_eldest(_tower):
			_add_button("Rank %s: only the Eldest grows further" % Tower.rank_name(_tower.rank)).disabled = true
		else:
			_add_button("Rank %s: fully nurtured" % Tower.rank_name(_tower.rank)).disabled = true
	var refund := tower_seller.get_refund(_tower)
	var note := "" if drift_director.is_build_phase() else " (half during a drift)"
	if tower_seller.is_placed_this_rest(_tower):
		note = " (placed this rest: full refund)"
	elif drift_director.is_build_phase() and _tower.rest_dew > 0:
		note = " (this rest's %d Dew in full)" % _tower.rest_dew
	var sell := _add_button("Sell · +%d Dew%s" % [refund, note])
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
func _stat_row(parts: Array) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	for i in parts.size():
		var part: Array = parts[i]
		if i > 0:
			var dot := Label.new()
			dot.text = " · "
			row.add_child(dot)
		var id: StringName = part[1]
		var is_status: bool = part.size() > 2 and part[2]
		var tip := IconInfo.status_tooltip(id) if is_status else IconInfo.stat_tooltip(id)
		if id != &"" and IconInfo.icon(id) != null:
			var icon := IconInfo.make_icon(id, 1)  # Carries its own TapTip
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(icon)
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(3, 0)
			row.add_child(gap)
		var label := Label.new()
		label.text = part[0]
		if not is_status and id != &"" and is_instance_valid(_tower):
			# Dream bonuses on Wardens: the real number, and what made it (base · Nurture · cards).
			var breakdown := DreamBonusView.stat_breakdown(_tower, id)
			if breakdown != "":
				tip = breakdown + ("\n" + tip if tip != "" else "")
			if DreamBonusView.is_boosted(_tower, id):
				label.text += " ↑"
				label.add_theme_color_override("font_color", DreamBonusView.BOOSTED_COLOR)
		if tip != "":
			TapTip.attach(label, tip)
		row.add_child(label)
	_stats.add_child(row)

# Several Wardens selected: grouped by kind, with totals, group grow buttons and Sell all.
func _refresh_group() -> void:
	var selection := tower_seller.selection
	var groups := tower_seller.get_selection_groups()
	_title.text = "%d Wardens selected" % selection.size()
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
		for option in Tower.grow_options(dream_state, data):  # Sprouts: only this run's families
			var next: TowerData = option[0]
			var button := _add_button("")
			UiStyle.primary(button)
			button.tooltip_text = IconInfo.format(next.description)  # {spored}-style tokens as words
			if not option[1]:
				_locked_form_button(button, "%s → %s" % [_plural(data, towers.size()), next.display_name], next)
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
	# Nurture all: one rank each, as far as the Dew goes (nearest the Heartwood first).
	var full: Array = tower_seller.full_nurture_cost(selection)
	if full[0] > 0:
		var plan: Array = tower_seller.plan_nurture(selection)
		var nurture := _add_button("")
		if plan[0].size() >= full[0]:
			nurture.text = "Nurture all %d · %s (R)" % [full[0], _price(full[1])]
		else:
			nurture.text = "Nurture %d of %d · %s (R)" % [plan[0].size(), full[0], _price(plan[1])]
			nurture.disabled = plan[0].is_empty()
		nurture.tooltip_text = "Each gains a rank: +10% damage, +4% attack speed, +0.1 range."
		if tower_seller.count_needing_focus(selection) > 0:
			nurture.tooltip_text += " Wardens at rank II wait for a Focus (below)."
		nurture.pressed.connect(func() -> void: tower_seller.nurture_group(tower_seller.selection))
	# Wardens at rank II need a Focus for rank III: one choice for the whole group.
	var waiting := tower_seller.count_needing_focus(selection)
	if waiting > 0:
		for which in [Tower.Focus.POWER, Tower.Focus.SWIFT, Tower.Focus.REACH, Tower.Focus.DEEP]:
			var cost: Array = tower_seller.full_nurture_cost(selection, which)
			var plan_focus: Array = tower_seller.plan_nurture(selection, which)
			var button := _add_button("")
			if plan_focus[0].size() >= cost[0]:
				button.text = "Nurture all %d, %d at rank III take %s · %s" % [cost[0], waiting,
					Tower.FOCUS_NAMES[which], _price(cost[1])]
			else:
				button.text = "Nurture %d of %d, rank III take %s · %s" % [plan_focus[0].size(), cost[0],
					Tower.FOCUS_NAMES[which], _price(plan_focus[1])]
				button.disabled = plan_focus[0].is_empty()
			button.tooltip_text = "%s: %s per rank from rank III. Can't be changed later." % [
				Tower.FOCUS_NAMES[which], Tower.FOCUS_TEXT[which]]
			button.pressed.connect(func() -> void: tower_seller.nurture_group(tower_seller.selection, which))
	var refund := tower_seller.get_selection_refund()
	var in_drift := not drift_director.is_build_phase()
	var sell := _add_button("Sell %d · +%d Dew%s" % [selection.size(), refund, " (half during a drift)" if in_drift else ""])
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

# Targeting (screens_ui.md): a 3-way switch First / Strongest / Closest for `towers` (one Warden or a
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
		button.text += " (you have %d)" % dream_state.dreamlight
	elif _confirm_unlock == next:
		button.text = "Unlock %s for %d Dreamlight? Click to confirm" % [next.display_name, cost]
	button.pressed.connect(_on_locked_form.bind(next, affordable and blocker == ""))

func _on_locked_form(next: TowerData, can_unlock_now: bool) -> void:
	if not can_unlock_now:
		_confirm_unlock = null
		dream_state.open_remember(next)
		return
	if _confirm_unlock != next:
		_confirm_unlock = next
		_refresh()
		return
	_confirm_unlock = null
	dream_state.unlock_with_dreamlight(next)  # Emits unlocks_changed -> refresh
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
func _show_damage_type(data: TowerData) -> void:
	_damage_type.visible = data.can_attack
	if not data.can_attack:
		return
	var icon := _damage_type.get_child(0) as TextureRect
	var label := _damage_type.get_child(1) as Label
	icon.texture = IconInfo.damage_type_icon(data.line)
	label.text = IconInfo.damage_type_text(data.line)
	label.add_theme_color_override("font_color", IconInfo.damage_type_color(data.line))
	_damage_type.tooltip_text = "Nightmares can resist or be weak to a damage type."
