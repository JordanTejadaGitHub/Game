extends Node2D
class_name DreamTempoView

# Only inspected Wardens show transient tempo. No labels over the whole formation.
var dreams: DreamState
var seller: TowerSeller
var rows: Array = []
var _clock := 0.0
func _ready() -> void:
	z_index = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	dreams = get_parent().get_node_or_null("%DreamState")
	seller = get_parent().get_node_or_null("%TowerSeller")
func _process(delta: float) -> void:
	_clock -= delta / maxf(Engine.time_scale, 0.001)
	if _clock > 0.0:
		return
	_clock = 0.1
	rows.clear()
	if dreams != null and seller != null:
		for tower in seller.selection:
			if is_instance_valid(tower) and Fx.on_screen(tower.global_position):
				var line := tempo_text(tower, dreams)
				if line != "":
					rows.append({"at": tower.global_position + Vector2(0, 26), "text": line})
	queue_redraw()
static func tempo_text(tower: Tower, ds: DreamState) -> String:
	var parts: Array[String] = []
	if tower.turnover_active():
		parts.append("Turnover +%d%% · %.1fs" % [roundi(DreamState.TARGET_TURNOVER_SPEED * 100.0), maxf(tower._turnover_until - tower._anim_time, 0.0)])
	if ds.has_rule(&"momentum"):
		var step := ds.momentum_step()
		var bonus := minf(step.x * int(tower._grove.get(&"streak", 0)), step.y)
		if bonus > 0.0:
			parts.append("Momentum +%d%%" % roundi(bonus * 100.0))
	return " · ".join(parts)
func _draw() -> void:
	for row: Dictionary in rows:
		var at := to_local(row.at)
		WorldLabel.draw_tag(self, at.x, at.y, row.text, Palette.SPRIG)
