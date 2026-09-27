extends PanelContainer

# Bottom-left panel for the selected Warden: what it does, its stats (including Dreams), what it
# can grow into (Dew cost, or which Dream it needs) and Sell. Built in code; hidden with no selection.

const STATUS_NAMES := {&"damp": "Damp", &"drowsy": "Drowsy", &"spored": "Spored", &"marked": "Marked", &"static": "Static"}

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
	if data.can_attack:
		lines.append("Damage %.0f · %.2f/s · range %.2f" % [_tower.get_damage(), _tower.get_attacks_per_second(), _tower.get_range_cells()])
		if data.applies_status != &"":
			lines.append("Applies %s%s" % [STATUS_NAMES.get(data.applies_status, data.applies_status),
				" ×%d" % data.status_stacks if data.status_stacks > 1 else ""])
	else:
		lines.append("A wall: no attack.")
	_body.text = "\n".join(lines)

	for child in _buttons.get_children():
		child.queue_free()
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

func _evolve(into: TowerData) -> void:
	if tower_placer.evolve(_tower, into):
		_refresh()
