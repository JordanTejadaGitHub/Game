extends PanelContainer

# Bottom-left panel for the selected Warden: what it does, its stats (including Dreams), what it
# can grow into (Dew cost, or which Dream it needs) and Sell. Built in code; hidden with no selection.

const STATUS_NAMES := {&"damp": "Damp", &"drowsy": "Drowsy", &"spored": "Spored", &"marked": "Marked", &"static": "Static", &"held": "Held"}
const TARGET_NAMES := {
	TowerData.TargetMode.FIRST: "Furthest along", TowerData.TargetMode.STRONGEST: "Strongest",
	TowerData.TargetMode.BOSSES: "Bosses first", TowerData.TargetMode.FASTEST: "Fastest",
}

@onready var tower_seller: TowerSeller = %TowerSeller
@onready var tower_placer: TowerPlacer = %TowerPlacer
@onready var dream_state: DreamState = %DreamState
@onready var run_state: RunState = %RunState
@onready var drift_director: DriftDirector = %DriftDirector

var _tower: Tower = null
var _title := Label.new()
var _body := Label.new()
var _groups := VBoxContainer.new()  # Several selected: one row per kind with its portrait
var _buttons := VBoxContainer.new()
var _confirm_sell := false  # Selling a group during a drift asks once more

func _ready() -> void:
	custom_minimum_size = Vector2(300, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	_title.add_theme_font_size_override("font_size", 20)
	box.add_child(_title)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(280, 0)
	box.add_child(_body)
	box.add_child(_groups)
	box.add_child(_buttons)
	visible = false

	tower_seller.tower_selected.connect(_show)
	tower_seller.selection_changed.connect(func(_towers: Array[Tower]) -> void:
		_confirm_sell = false
		_refresh())
	run_state.dew_changed.connect(_refresh.unbind(1))
	dream_state.unlocks_changed.connect(_refresh)
	dream_state.card_taken.connect(_refresh.unbind(1))
	drift_director.build_phase_changed.connect(_refresh.unbind(1))

func _show(tower: Tower) -> void:
	_tower = tower
	_refresh()

func _refresh() -> void:
	for child in _groups.get_children():
		child.queue_free()
	if tower_seller.selection.size() > 1:
		visible = true
		_refresh_group()
		return
	if not is_instance_valid(_tower) or _tower.is_queued_for_deletion():
		_tower = null
		visible = false
		return
	visible = true
	var data := _tower.tower_data
	_title.text = data.display_name
	if _tower.rank > 0:
		_title.text += " · Rank %s" % Tower.RANK_NAMES[_tower.rank]
		if _tower.focus != Tower.Focus.NONE:
			_title.text += " · %s" % Tower.FOCUS_NAMES[_tower.focus]
	var lines: Array[String] = []
	if data.description != "":
		lines.append(data.description)
	var attack := _tower.attack_data
	if data.attack_kind == TowerData.AttackKind.AURA:
		lines.append("Aura · range %.2f" % _tower.get_range_cells())
	elif data.attack_kind == TowerData.AttackKind.COPY and _tower.get_copied() == null:
		lines.append("Nothing to copy: plant it beside an attacking Warden.")
	elif data.can_attack:
		if _tower.get_copied() != null:
			lines.append("Copying %s at %d%%" % [attack.display_name, roundi(data.copy_share * 100)])
		var range_text := "range %.2f" % _tower.get_range_cells()
		if attack.min_range > 0.0:
			range_text = "range %.1f–%.1f" % [attack.min_range, _tower.get_range_cells()]
		lines.append("Damage %.0f · %.2f/s · %s" % [_tower.get_damage(), _tower.get_attacks_per_second(), range_text])
		if _tower.get_crit_chance() > 0.0:
			lines.append("Crit %d%% · ×%s" % [roundi(_tower.get_crit_chance() * 100), str(attack.crit_multiplier)])
		if attack.applies_status != &"":
			lines.append("Applies %s%s" % [STATUS_NAMES.get(attack.applies_status, attack.applies_status),
				" ×%d" % attack.status_stacks if attack.status_stacks > 1 else ""])
	else:
		lines.append("A wall: no attack.")
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
	_body.text = "\n".join(lines)

	for child in _buttons.get_children():
		child.queue_free()
	if data.has_target_priority:
		var aim := _add_button("Aim: %s (click to change)" % TARGET_NAMES[_tower.target_mode])
		aim.pressed.connect(_cycle_target)
	for option in dream_state.get_evolutions(data):
		var next: TowerData = option[0]
		var button := _add_button("")
		if option[1]:
			var cost := dream_state.get_evolve_cost(next)
			button.text = "Grow into %s · %d Dew" % [next.display_name, cost]
			button.tooltip_text = next.description
			button.disabled = not run_state.can_afford(cost)
			button.pressed.connect(_evolve.bind(next))
		else:
			button.text = "%s · needs a Dream" % next.display_name
			button.tooltip_text = next.description
			button.disabled = true
	if _tower.needs_focus():
		# Rank III asks for a Focus, kept through growth and never changed.
		var cost := _tower.get_nurture_cost()
		for which in [Tower.Focus.POWER, Tower.Focus.SWIFT, Tower.Focus.REACH, Tower.Focus.DEEP]:
			# Usually rank III; a Warden planted at a higher rank (Remembered Care) chooses on its next one.
			var button := _add_button("Rank %s · %s: %s per rank · %d Dew" % [Tower.RANK_NAMES[_tower.rank + 1],
				Tower.FOCUS_NAMES[which], Tower.FOCUS_TEXT[which], cost])
			button.tooltip_text = "The usual rank gains, plus this Focus at ranks III, IV and V. Can't be changed later."
			button.disabled = not run_state.can_afford(cost)
			button.pressed.connect(func() -> void:
				if tower_placer.nurture(_tower, which):
					_refresh())
	elif _tower.can_nurture():
		var cost := _tower.get_nurture_cost()
		var nurture := _add_button("Nurture to rank %s · %d Dew (R)" % [Tower.RANK_NAMES[_tower.rank + 1], cost])
		nurture.tooltip_text = "+10% damage, +4% attack speed, +0.1 range%s. Kept when it grows." % (
			", and %s" % Tower.FOCUS_TEXT[_tower.focus] if _tower.focus != Tower.Focus.NONE else "")
		nurture.disabled = not run_state.can_afford(cost)
		nurture.pressed.connect(func() -> void:
			if tower_placer.nurture(_tower):
				_refresh())
	elif _tower.can_be_nurtured() and _tower.rank > 0:
		_add_button("Rank %s: fully nurtured" % Tower.RANK_NAMES[_tower.rank]).disabled = true
	var refund := tower_seller.get_refund(_tower)
	var sell := _add_button("Sell · +%d Dew%s" % [refund, "" if drift_director.is_build_phase() else " (half during a drift)"])
	sell.pressed.connect(func() -> void: tower_seller.sell(_tower.cell))
	if not tower_seller.can_sell():
		sell.text = "Rooted: no selling while nightmares walk (Overgrown)"
		sell.disabled = true
	var close := _add_button("Close")
	close.pressed.connect(tower_seller.select.bind(null))

# Several Wardens selected: grouped by kind, with totals, group grow buttons and Sell all.
func _refresh_group() -> void:
	var selection := tower_seller.selection
	var groups := tower_seller.get_selection_groups()
	_title.text = "%d Wardens selected" % selection.size()
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
	_body.text = "\n".join(lines)

	for child in _buttons.get_children():
		child.queue_free()
	if selection.any(func(t: Tower) -> bool: return t.tower_data.has_target_priority):
		var aim := _add_button("Aim all: %s (click to change)" % TARGET_NAMES[_group_target_mode()])
		aim.pressed.connect(_cycle_group_target)
	for group in groups:
		var data: TowerData = group[0]
		var towers: Array = group[1]
		for option in dream_state.get_evolutions(data):
			var next: TowerData = option[0]
			var button := _add_button("")
			button.tooltip_text = next.description
			if not option[1]:
				button.text = "%s → %s · needs a Dream" % [_plural(data, towers.size()), next.display_name]
				button.disabled = true
				continue
			var cost := dream_state.get_evolve_cost(next)
			var affordable := tower_seller.count_affordable(towers, next)
			if affordable >= towers.size():
				button.text = "Grow %d %s into %s · %d Dew" % [towers.size(), _plural(data, towers.size()),
					next.display_name, cost * towers.size()]
			else:
				# Grows as many as the Dew allows, closest to the Heartwood first.
				button.text = "Grow %d of %d %s into %s · %d Dew" % [affordable, towers.size(),
					_plural(data, towers.size()), next.display_name, cost * affordable]
				button.disabled = affordable == 0
			button.pressed.connect(func() -> void: tower_seller.grow_group(towers, next))
	# Nurture all: one rank each, as far as the Dew goes (nearest the Heartwood first).
	var full: Array = tower_seller.full_nurture_cost(selection)
	if full[0] > 0:
		var plan: Array = tower_seller.plan_nurture(selection)
		var nurture := _add_button("")
		if plan[0].size() >= full[0]:
			nurture.text = "Nurture all %d · %d Dew (R)" % [full[0], full[1]]
		else:
			nurture.text = "Nurture %d of %d · %d Dew (R)" % [plan[0].size(), full[0], plan[1]]
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
				button.text = "Nurture all %d, %d at rank III take %s · %d Dew" % [cost[0], waiting,
					Tower.FOCUS_NAMES[which], cost[1]]
			else:
				button.text = "Nurture %d of %d, rank III take %s · %d Dew" % [plan_focus[0].size(), cost[0],
					Tower.FOCUS_NAMES[which], plan_focus[1]]
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
		sell.text = "Rooted: no selling while nightmares walk (Overgrown)"
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
	if not drift_director.is_build_phase() and not _confirm_sell:
		_confirm_sell = true
		_refresh()
		return
	_confirm_sell = false
	tower_seller.sell_selection()

func _group_target_mode() -> TowerData.TargetMode:
	for tower in tower_seller.selection:
		if tower.tower_data.has_target_priority:
			return tower.target_mode
	return TowerData.TargetMode.FIRST

func _cycle_group_target() -> void:
	var order := [TowerData.TargetMode.FIRST, TowerData.TargetMode.STRONGEST, TowerData.TargetMode.BOSSES]
	var next: TowerData.TargetMode = order[(order.find(_group_target_mode()) + 1) % order.size()]
	for tower in tower_seller.selection:
		if tower.tower_data.has_target_priority:
			tower.target_mode = next
	_refresh()

func _add_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_buttons.add_child(button)
	return button

# Snipers: Furthest along -> Strongest -> Bosses first -> back.
func _cycle_target() -> void:
	var order := [TowerData.TargetMode.FIRST, TowerData.TargetMode.STRONGEST, TowerData.TargetMode.BOSSES]
	var index := order.find(_tower.target_mode)
	_tower.target_mode = order[(index + 1) % order.size()]
	_refresh()

func _evolve(into: TowerData) -> void:
	if tower_placer.evolve(_tower, into):
		_refresh()
