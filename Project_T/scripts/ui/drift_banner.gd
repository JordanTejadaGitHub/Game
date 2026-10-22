extends Control

# Top-centre drift display (screens_ui.md "The run HUD"): act and drift, 5 pips for the current
# block, and the countdown to the next boss. During a boss drift the countdown becomes the boss's
# health bar, with a marker where an ability starts (50%; the Oak 67% / 33%). Drawn in code.

const WIDTH := 460.0
const PIP_RADIUS := 5.0
const TEXT_COLOR := UiStyle.INK
const DIM_COLOR := Palette.PATH
const BOSS_COLOR := UiStyle.BOSS  # Heartwood 32 (ui_style.md)
const FONT_SIZE := 22
const SMALL_FONT_SIZE := 16
const BOSS_FONT_SIZE := 20  # The next-boss line: gold and larger than the rest
const DISC_RADIUS := 15.0  # Its portrait's moon disc
const BOSS_GAP := 22.0  # Between the pips and the boss

@onready var drift_director: DriftDirector = %DriftDirector

var _boss: Node2D = null
# Tappable spots (screens_ui.md "Boss dossier"): "Boss in N" opens the dossier; during the boss drift
# the bar's markers (50%, or the Oak's 67% / 33%) show the ability that starts there. Everything else lets clicks through.
var _countdown_rect := Rect2()
var _pips_rect := Rect2()  # The block pips, for their tooltip
var _markers: Array = []  # [[Rect2, line], …] on the boss bar
var _marker_tip := TapTip.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP  # Only on the spots above (_has_point)
	add_child(_marker_tip)
	var spawner = %EnemyContainer
	spawner.child_entered_tree.connect(func(node: Node) -> void:
		if node.get("enemy_data") != null and node.enemy_data.is_boss:
			_boss = node
			if node.has_signal("big_hit") and not node.big_hit.is_connected(_on_boss_big_hit):
				node.big_hit.connect(_on_boss_big_hit))

# Big-hit feedback (visual_feedback_spec.md A, Main Merger's part): at T2 and T3 the boss bar flashes the segment it just
# lost, GLOW at 0.6 alpha fading over 0.25 s (real time). Enemy.big_hit fires after the health drops, so the segment runs
# from the health now up by the hit's share. Subtle (big_hits 1) shows T1 everywhere: no flash; Off (2): none.
const CHUNK_FLASH := 0.25
var _chunk := Vector2(-1.0, -1.0)  # Health shares [from, to] of the segment lost
var _chunk_left := 0.0

func _on_boss_big_hit(enemy: Node2D, tier: int, share: float) -> void:
	if enemy != _boss or tier < 2 or int(Fx.setting("big_hits", 0)) != 0:
		return
	var now := float(enemy.health) / maxf(enemy.max_health, 1.0)
	_chunk = Vector2(now, minf(now + share, 1.0))
	_chunk_left = CHUNK_FLASH
	queue_redraw()

# Redrawn when what it shows changes (3× perf pass: it was every frame), and at least every
# SAFETY_REDRAW s for anything the key misses (pip states).
const SAFETY_REDRAW := 0.5
var _shown_key := ""
var _since_redraw := 0.0

func _process(delta: float) -> void:
	_since_redraw += delta / maxf(Engine.time_scale, 0.001)
	if _chunk_left > 0.0:  # The chunk flash fades every frame while it lasts
		_chunk_left = maxf(_chunk_left - delta / maxf(Engine.time_scale, 0.001), 0.0)
		queue_redraw()
	var boss_health := int(_boss.health) if is_instance_valid(_boss) and not _boss.is_cleansed else -1
	var pulse_step := int(Time.get_ticks_msec() / 50) if _boss_at_heartwood() else 0  # The drain pulse redraws ~20×/s
	var key := "%s|%d|%s|%d|%s|%d" % [get_drift_text(), drift_director.drifts_started, drift_director.is_resting(), boss_health, size, pulse_step]
	if key == _shown_key and _since_redraw < SAFETY_REDRAW:
		return
	_shown_key = key
	_since_redraw = 0.0
	queue_redraw()

# The width its drawing takes (centred in its rect): the widest of the top line and the pips + next
# boss line, or its boss bar. The HUD keeps the top-right row clear of it.
func drawn_width() -> float:
	var latest := drift_director.drifts_started
	var total := drift_director.get_total_drifts()
	var shown := mini(latest + 1 if drift_director.is_resting() else maxi(latest, 1), total)
	var act := drift_director.get_act(shown)
	var width := UiStyle.display_width(drift_director.get_act_name(act) + TOP_GAP, FONT_SIZE) + _phrase_width(get_drift_text(), FONT_SIZE)
	var pips := (drift_director.drifts_per_block - 1) * PIP_RADIUS * 3.0 + PIP_RADIUS * 2.0
	var boss_text := _next_boss_text(latest)
	if boss_text != "":
		pips += BOSS_GAP + DISC_RADIUS * 2.0 + 8.0 + _phrase_width(boss_text, BOSS_FONT_SIZE)
	return maxf(maxf(width, pips) + 12.0, _drawn_half * 2.0)  # What it last drew, if wider (+ outlines)

# Its drawn area in global coordinates (centred in the rect).
func drawn_rect() -> Rect2:
	var rect := get_global_rect()
	var width := drawn_width()  # Never clamped to the rect: its text may overflow it
	return Rect2(rect.get_center().x - width / 2.0, rect.position.y, width, rect.size.y)

var _drawn_half := 0.0  # Half the widest thing the last _draw drew, from the centre (+ outline)

func _draw() -> void:
	_drawn_half = 0.0
	var font := UiStyle.display_font()  # Moonlit Thread (ui_style.md)
	var center_x := size.x / 2.0
	var latest := drift_director.drifts_started
	var total := drift_director.get_total_drifts()
	var shown := mini(latest + 1 if drift_director.is_resting() else maxi(latest, 1), total)
	var act := drift_director.get_act(shown)
	# Light pass (user-approved): "Forest's Edge   Drift 1 of 100", the act's name in ink, the count quieter.
	var place: String = drift_director.get_act_name(act) + TOP_GAP
	var count := get_drift_text()
	var place_w := UiStyle.display_width(place, FONT_SIZE)
	var full_w := place_w + _phrase_width(count, FONT_SIZE)
	var top_left := center_x - full_w / 2.0
	for part in [[place, top_left, TEXT_COLOR], [count, top_left + place_w, UiStyle.MOON_MIST]]:
		if part[0] == place:
			UiStyle.draw_display(self, Vector2(part[1], 20), part[0], FONT_SIZE, part[2], 6, Palette.DREAD)
		else:
			_draw_phrase(part[0], Vector2(part[1], 20), FONT_SIZE, part[2])
	_drawn_half = maxf(_drawn_half, full_w / 2.0 + 6.0)

	if is_instance_valid(_boss) and not _boss.is_cleansed:
		_pips_rect = Rect2()
		_draw_boss_bar(font, center_x)
		return
	# The second row, centred as a whole: the block's pips, then the next boss (portrait on its disc +
	# "The Hollow Stag · drift 25 (in 20)" in gold, larger: screens_ui.md playtest fixes 2026-09-30).
	var block := drift_director.get_block(shown)
	var first := (block - 1) * drift_director.drifts_per_block + 1
	var step := PIP_RADIUS * 3.0
	var pips_width := (drift_director.drifts_per_block - 1) * step + PIP_RADIUS * 2.0
	var boss_text := _next_boss_text(latest)
	var boss_data := _next_boss_data(latest)
	var text_width := _phrase_width(boss_text, BOSS_FONT_SIZE) if boss_text != "" else 0.0
	var boss_width := (BOSS_GAP + DISC_RADIUS * 2.0 + 8.0 + text_width) if boss_text != "" else 0.0
	var row_y := 48.0
	var x := center_x - (pips_width + boss_width) / 2.0 + PIP_RADIUS
	_pips_rect = Rect2(x - PIP_RADIUS - 4.0, row_y - PIP_RADIUS - 4.0, pips_width + 8.0, PIP_RADIUS * 2.0 + 8.0)
	for i in drift_director.drifts_per_block:
		var number := first + i
		var at := Vector2(x + i * step, row_y)
		var colour := BOSS_COLOR if drift_director.is_boss_drift(number) else TEXT_COLOR
		if number <= latest:  # Filled once it has started
			draw_circle(at, PIP_RADIUS, colour)
		else:
			draw_arc(at, PIP_RADIUS, 0.0, TAU, 16, Color(colour, 0.7), 1.5)
	_markers = []
	if boss_text == "":
		_countdown_rect = Rect2()
		return
	var left := x - PIP_RADIUS + pips_width + BOSS_GAP
	var disc := Vector2(left + DISC_RADIUS, row_y)
	UiStyle.draw_moon_disc(self, disc, DISC_RADIUS, BOSS_COLOR)
	if boss_data != null:
		var side := DISC_RADIUS * 1.6
		draw_texture_rect(NightmareCard.portrait(boss_data), Rect2(disc - Vector2(side, side) / 2.0, Vector2(side, side)),
			false, boss_data.tint)
	var text_x := disc.x + DISC_RADIUS + 8.0
	var base := row_y + BOSS_FONT_SIZE * 0.35
	_draw_phrase(boss_text, Vector2(text_x, base), BOSS_FONT_SIZE, UiStyle.GOLD)
	# Underlined: it (and the portrait) opens the dossier.
	draw_line(Vector2(text_x, base + 4), Vector2(text_x + text_width, base + 4), Color(UiStyle.GOLD, 0.5), 1.0)
	_countdown_rect = Rect2(left - 4.0, row_y - DISC_RADIUS - 4.0, text_x + text_width - left + 8.0, DISC_RADIUS * 2.0 + 8.0)
	_drawn_half = maxf(_drawn_half, maxf(center_x - (left - 4.0), text_x + text_width + 6.0 - center_x))

func _draw_boss_bar(font: Font, center_x: float) -> void:
	var bar := Rect2(center_x - WIDTH / 2.0, 34, WIDTH, 10)
	_drawn_half = maxf(_drawn_half, WIDTH / 2.0 + 4.0)
	var fraction := float(_boss.health) / maxf(_boss.max_health, 1.0)
	draw_rect(bar.grow(2), Color(Palette.DREAD, 0.85))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * fraction, bar.size.y)), BOSS_COLOR)
	if _chunk_left > 0.0 and _chunk.y > _chunk.x:  # The segment a big hit just took
		draw_rect(Rect2(bar.position.x + bar.size.x * _chunk.x, bar.position.y, bar.size.x * (_chunk.y - _chunk.x), bar.size.y),
			Color(Palette.GLOW, 0.6 * _chunk_left / CHUNK_FLASH))
	# A marker (with a knob: it's tappable) at every health share an ability starts at.
	_markers = []
	var lines := marker_lines()
	for share in lines:
		var x := bar.position.x + bar.size.x * float(share)
		draw_line(Vector2(x, bar.position.y - 3), Vector2(x, bar.end.y + 3), UiStyle.INK, 2.0)
		draw_circle(Vector2(x, bar.position.y - 5), 3.0, UiStyle.INK)
		_markers.append([Rect2(x - 14, bar.position.y - 14, 28, 32), lines[share]])
	# The rest of the bar (and the name) opens the dossier too.
	_countdown_rect = Rect2(bar.position.x, bar.position.y - 4, bar.size.x, bar.size.y + 26)
	if _boss_at_heartwood():  # It got through and stays, draining leaves: say so, and pulse
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * TAU * 0.8)
		draw_rect(bar.grow(4), Color(UiStyle.POOR, 0.35 + 0.45 * pulse), false, 2.0)
		var at_text := "%s · at the Heartwood" % _boss.enemy_data.display_name
		if _boss.has_method("linger_left") and _boss.linger_left() > 0.0:  # The Night Mare lingers, then laps on
			at_text = "%s · At the Heartwood: %d s" % [_boss.enemy_data.display_name, ceili(_boss.linger_left())]
		if _boss.has_method("is_untouchable") and _boss.is_untouchable():  # Can't be hit while it lingers
			at_text += " · Untouchable"
		_draw_centered(font, at_text, Vector2(center_x, bar.end.y + 16),
			SMALL_FONT_SIZE, UiStyle.POOR)
		return
	var name: String = _boss.enemy_data.display_name
	_draw_centered(font, name, Vector2(center_x, bar.end.y + 16), SMALL_FONT_SIZE, BOSS_COLOR.lightened(0.3))

func _boss_at_heartwood() -> bool:
	return is_instance_valid(_boss) and bool(_boss.get("at_heartwood"))

func _has_point(point: Vector2) -> bool:
	return _marker_at(point) != "" or _countdown_rect.has_point(point) or _pips_rect.has_point(point)

func _marker_at(point: Vector2) -> String:
	for marker in _markers:
		if marker[0].has_point(point):
			return marker[1]
	return ""

func _get_tooltip(at: Vector2) -> String:
	var line := _marker_at(at)
	if line != "":
		return line
	if _pips_rect.has_point(at):
		return "This block's %d drifts: a filled dot has started. A rest follows the last one." % drift_director.drifts_per_block
	var data := _next_boss_data(drift_director.drifts_started)
	if data == null or not _countdown_rect.has_point(at):
		return ""
	var left := _next_boss_drift(drift_director.drifts_started) - drift_director.drifts_started
	return "%s in %d drift%s. Tap for its dossier." % [data.display_name, left, "" if left == 1 else "s"]

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var line := _marker_at(event.position)
	if line != "":
		show_marker_tip(line, event.position)
	elif _countdown_rect.has_point(event.position):
		BossDossier.open_for(get_tree())
	accept_event()

# {health share: line} for the boss's abilities that start at a health share (EnemyData abilities
# whose "when" says "at 50% health", "at 67% and 33% health"), e.g. 0.5: "At 50% health · Charge: its
# antlers flare and it runs +50% faster for 4 s." Empty = no markers (never a marker that says nothing).
func marker_lines() -> Dictionary:
	var lines := {}
	if not is_instance_valid(_boss):
		return lines
	var data: EnemyData = _boss.enemy_data
	var percent := RegEx.create_from_string("([0-9]+)%")
	for i in data.abilities.size():
		var ability := data.get_ability(i, NightmareCard.text_values(data, drift_director))  # Shell numbers at this drift
		var when := String(ability.get("when", ""))
		if not when.contains("health"):
			continue
		for found in percent.search_all(when):
			var share := int(found.get_string(1)) / 100.0
			lines[share] = IconInfo.format("At %s health · %s: %s" % [found.get_string(), ability.get("name", ""),
				ability.get("text", "")])
	return lines

# The 50% marker's line ("" if the boss has none).
func half_health_text() -> String:
	return marker_lines().get(0.5, "")

func show_marker_tip(line: String, at: Vector2) -> void:
	_marker_tip._label.text = line
	_marker_tip.visible = false
	_marker_tip.toggle()
	var screen := get_viewport_rect().size
	_marker_tip.global_position = Vector2(clampf(global_position.x + at.x - _marker_tip.size.x / 2.0,
		4, screen.x - _marker_tip.size.x - 4), global_position.y + 70)

const TOP_GAP := "   "  # Between the act's name and the drift count (trimmed: the top-right row needs the room at 1280)

# "Drift 7 of 100" (light pass, user-approved: the total is back, "Ready ·" is gone); drift 1 before the first.
func get_drift_text() -> String:
	var latest := drift_director.drifts_started
	return "Drift %d of %d" % [maxi(latest, 1), drift_director.get_total_drifts()]

# The next boss line after `latest`: just its countdown ("18") beside the boss portrait (design hub: the top-right row needs the room; the name and "in 18 drifts" are the tooltip, a tap opens the dossier), or "".
func _next_boss_text(latest: int) -> String:
	var number := _next_boss_drift(latest)
	if number == 0:
		return ""
	return "Boss in %d" % (number - latest)  # Says what the number counts (UI council 2026-10-22: a bare "22" read as anything)

func _next_boss_data(latest: int) -> EnemyData:
	var number := _next_boss_drift(latest)
	return _boss_of(number) if number > 0 else null

func _next_boss_drift(latest: int) -> int:
	for number in range(latest + 1, drift_director.get_total_drifts() + 1):
		if drift_director.is_boss_drift(number):
			return number
	return 0

var _bosses := {}  # Drift number -> its boss EnemyData (schedules are costly to rebuild each frame)

func _boss_of(number: int) -> EnemyData:
	var boss_drift: DriftData = drift_director.drifts[number - 1]
	if not _bosses.has(number) or _bosses[number][0] != boss_drift:
		var found: EnemyData = null
		for group in boss_drift.groups:
			for entry in group.entries:
				if entry.enemy != null and entry.enemy.is_boss:
					found = entry.enemy
		_bosses[number] = [boss_drift, found]
	return _bosses[number][1]

# A phrase that holds a number ("Drift 1 of 100", "Boss in 25"), whole in the number face (UI council round 4: a
# Pixelify word beside Vollkorn digits read patchy; round 3: Pixelify's 5 read as S). The act's name stays Pixelify.
func _phrase_width(text: String, font_size: int) -> float:
	return UiStyle.number_font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

func _draw_phrase(text: String, at: Vector2, font_size: int, colour: Color) -> void:
	var font := UiStyle.number_font()
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, Palette.DREAD)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)

func _draw_centered(font: Font, text: String, at: Vector2, font_size: int, colour: Color) -> void:
	var width := UiStyle.display_width(text, font_size) if font == UiStyle.display_font() else font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var origin := Vector2(at.x - width / 2.0, at.y)
	if font == UiStyle.display_font():
		UiStyle.draw_display(self, origin, text, font_size, colour, 6, Palette.DREAD)
	else:
		draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, Palette.DREAD)
		draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)
	_drawn_half = maxf(_drawn_half, width / 2.0 + 6.0)  # + the outline
