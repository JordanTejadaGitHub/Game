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
var _buttons := VBoxContainer.new()

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
	box.add_child(_buttons)
	visible = false

	tower_seller.tower_selected.connect(_show)
	run_state.dew_changed.connect(_refresh.unbind(1))
	dream_state.unlocks_changed.connect(_refresh)
	dream_state.card_taken.connect(_refresh.unbind(1))
	drift_director.build_phase_changed.connect(_refresh.unbind(1))

func _show(tower: Tower) -> void:
	_tower = tower
	_refresh()

func _refresh() -> void:
	if not is_instance_valid(_tower) or _tower.is_queued_for_deletion():
		_tower = null
		visible = false
		return
	visible = true
	var data := _tower.tower_data
	_title.text = data.display_name
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
	var refund := tower_seller.get_refund(_tower)
	var sell := _add_button("Sell · +%d Dew%s" % [refund, "" if drift_director.is_build_phase() else " (half during a drift)"])
	sell.pressed.connect(func() -> void: tower_seller.sell(_tower.cell))
	if not tower_seller.can_sell():
		sell.text = "Rooted: no selling while nightmares walk (Overgrown)"
		sell.disabled = true
	var close := _add_button("Close")
	close.pressed.connect(tower_seller.select.bind(null))

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
