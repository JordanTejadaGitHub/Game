class_name WardenHeaderView
extends VBoxContainer

# The top half of the Warden panel as one shared view (screens_ui.md, the bullets above "Readable
# tooltips"): portrait + name, damage type, the description with links, stats with this run's Dream
# bonuses, the status it applies and its Potency, and optionally "Grows into". The Warden panel, the
# Warden bar's hover card and the Codex Families page all build it, so they never disagree.
#   WardenHeaderView.build(data)          an unplanted Warden: its base plus this run's run-wide bonuses
#   WardenHeaderView.build(data, tower)   a planted one: exactly what the panel shows
# No buttons. Add it to the tree (it finds DreamState by group) or pass `dreams`.

const PORTRAIT_SIZE := 48.0
const WIDTH := 280.0

var title := Label.new()
var portrait := TextureRect.new()  # The Warden's idle art (the panel animates it)
var portrait_atlas := AtlasTexture.new()
var damage_type := HBoxContainer.new()  # The damage type name in its colour (no icon: user, 2026-09-30)
var desc: RichTextLabel  # What it does, with its status words as links (StatusLinks)
var stats := VBoxContainer.new()  # Stat rows: each stat explains itself on hover and tap (IconInfo)
var growth := VBoxContainer.new()  # "Grows into" (the hover card and Codex; the panel has its Grow buttons)

var _tower: Tower = null  # The planted Warden shown, or a probe carrying this run's bonuses (never in the tree)
var _probe: Tower = null

# A ready view for `data` (and `tower` when it's planted). `with_growth` adds "Grows into".
static func build(data: TowerData, tower: Tower = null, dreams: DreamState = null, with_growth := true) -> WardenHeaderView:
	var view := WardenHeaderView.new()
	view.show_warden(data, tower, dreams, with_growth)
	return view

func _init() -> void:
	add_theme_constant_override("separation", 6)
	UiStyle.title(title, UiStyle.TITLE_SIZE)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	portrait.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.texture = portrait_atlas
	header.add_child(portrait)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	add_child(header)
	damage_type.add_theme_constant_override("separation", 4)
	damage_type.add_child(Label.new())
	add_child(damage_type)
	desc = StatusLinks.make_label("", 16)
	desc.custom_minimum_size = Vector2(WIDTH, 0)
	add_child(desc)
	stats.add_theme_constant_override("separation", 2)
	add_child(stats)
	growth.add_theme_constant_override("separation", 2)
	add_child(growth)

func _exit_tree() -> void:
	_free_probe()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_free_probe()

func _free_probe() -> void:
	if is_instance_valid(_probe):
		_probe.free()
	_probe = null

# Fills the view. Returns the panel's notes that aren't stats ("A wall: no attack.", "Copying …").
func show_warden(data: TowerData, tower: Tower = null, dreams: DreamState = null, with_growth := true) -> Array[String]:
	if dreams == null and is_inside_tree():
		dreams = get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	_tower = tower if is_instance_valid(tower) else _probe_for(data, dreams)
	var notes: Array[String] = []
	title.text = data.display_name
	portrait_atlas.atlas = data.texture
	portrait_atlas.region = data.get_frame_rect(0) if data.texture else Rect2()
	portrait.visible = data.texture != null
	_show_damage_type(data)
	desc.text = StatusLinks.bbcode(data.description)  # {damp}-style tokens and plain names both work
	if is_instance_valid(tower) and tower.legacy_data != null:
		# An Ascended form still makes its final form's attack.
		desc.text += "\n[i]Still %s: %s[/i]" % [tower.legacy_data.display_name, StatusLinks.bbcode(tower.legacy_data.description)]
	desc.visible = desc.text != ""
	for child in stats.get_children():
		child.queue_free()
	var attack := _tower.attack_data
	if data.attack_kind == TowerData.AttackKind.AURA:
		_stat_row([["Aura", &""], ["range %.2f" % _tower.get_range_cells(), &"range"]])
	elif data.attack_kind == TowerData.AttackKind.COPY and (not is_instance_valid(tower) or tower.get_copied() == null):
		notes.append("Copies its strongest neighbour at %d%%." % roundi(data.copy_share * 100) if not is_instance_valid(tower)
			else "Nothing to copy: plant it beside an attacking Warden.")
	elif data.can_attack:
		if is_instance_valid(tower) and tower.get_copied() != null:
			notes.append("Copying %s at %d%%" % [attack.display_name, roundi(data.copy_share * 100)])
		var range_text := "range %.2f" % _tower.get_range_cells()
		if attack.min_range > 0.0:
			range_text = "range %.1f–%.1f" % [attack.min_range, _tower.get_range_cells()]
		_stat_row([["Damage %s" % BossDossier.thousands(roundi(_tower.get_damage())), &"damage"],
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
		notes.append("A wall: no attack.")
	if dreams != null:
		stats.add_child(DreamBonusView.make_rows(_tower) if is_instance_valid(tower)
			else DreamBonusView.make_rows_at(data, _tower.cell))  # "Dreams on this Warden"
	_fill_growth(data, dreams if with_growth else null)
	return notes

# "Grows into": each next form with its Dew, or what unlocking it takes (Dreamlight).
func _fill_growth(data: TowerData, dreams: DreamState) -> void:
	for child in growth.get_children():
		child.queue_free()
	growth.visible = false
	if dreams == null:
		return
	var options := Tower.grow_options(dreams, data)
	if options.is_empty():
		return
	growth.visible = true
	var head := Label.new()
	head.text = "Grows into"
	UiStyle.caps(head, 14)
	growth.add_child(head)
	for option in options:
		var next: TowerData = option[0]
		var line := Label.new()
		if option[1]:
			var cost: int = tower_grow_cost(next, dreams)
			line.text = "%s · %d Dew" % [next.display_name, cost]
		elif dreams.has_method("get_unlock_cost"):
			var blocker: String = dreams.get_unlock_blocker(next) if dreams.has_method("get_unlock_blocker") else ""
			line.text = "%s · %s" % [next.display_name, blocker if blocker != "" else "unlock with %d Dreamlight" % dreams.get_unlock_cost(next)]
			line.add_theme_color_override("font_color", UiStyle.INK_DIM)
		else:
			line.text = "%s · needs a Dream" % next.display_name
			line.add_theme_color_override("font_color", UiStyle.INK_DIM)
		TapTip.attach(line, IconInfo.format(next.description))  # Hover or tap
		growth.add_child(line)

func tower_grow_cost(next: TowerData, dreams: DreamState) -> int:
	return _tower.get_grow_cost(next).total if is_instance_valid(_tower) and _tower != _probe else dreams.get_evolve_cost(next)

func _show_damage_type(data: TowerData) -> void:
	damage_type.visible = data.can_attack
	if not data.can_attack:
		return
	var label := damage_type.get_child(0) as Label
	label.text = IconInfo.damage_type_text(data.line)
	label.add_theme_color_override("font_color", IconInfo.damage_type_color(data.line))
	if label.tooltip_text == "":
		TapTip.attach(label, "Nightmares can resist or be weak to a damage type.")  # Hover or tap

# An unplanted Warden's stats: a Tower that never enters the tree, reading this run's Dreams.
func _probe_for(data: TowerData, dreams: DreamState) -> Tower:
	if not is_instance_valid(_probe):
		_probe = Tower.new()
	_probe.tower_data = data
	_probe.attack_data = data
	_probe.cell = Vector2(-100, -100)  # Off the board: no position cards
	_probe._dream_state = dreams
	_probe.clear_dream_cache()
	return _probe

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
		if not is_status and id != &"" and is_instance_valid(_tower) and _tower != _probe:
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
	stats.add_child(row)
