extends VBoxContainer
class_name ComingStrip

# "Coming this block" (screens_ui.md "Nightmare info"): the nightmare kinds still to come, top centre
# right under the drift banner (moved 2026-09-28 from the bottom right: "hard to see and notice").
# - At rests: full size, the next block's kinds (portraits ~40 px, "New" if never met, the boss last
#   in a red frame), each with its resist / weak damage-type icons underneath.
# - During a drift: a compact row of small portraits for the rest of the current block, the next
#   drift's kinds lit and the others dimmed. Hidden in a boss drift (the boss bar has the spot).
# Tap a portrait: its centred card (NightmareIntro; one card at a time), the boss: the dossier.
# Made by the HUD.

const FACE := 48.0  # screens_ui.md "Readable on the night sky": 48 px at rests, 36 in drifts
const FACE_SMALL := 36.0
const FACE_BIG := 64.0  # A new rule-breaker at a rest (RuleBreakers)
const PIP := 16.0
const TOP := 72.0  # Just under the drift banner
# Phones (user 2026-10-17: "Coming this block is taking up a space"): no caption, one row of small discs on a tight fog,
# right under the banner. A tap on a disc still opens its card.
const PHONE_FACE := 40.0  # Phones: the tap target; the disc draws PHONE_DISC inside it, in a plate the size of the top-right buttons' visible box (user 2026-10-21)
const PHONE_DISC := 40.0  # (Full size in the Incoming dropdown)
const PHONE_PER_ROW := 8
var _phone := false
const BOSS_COLOR := UiStyle.BOSS  # Heartwood 32 (ui_style.md)
const DIM := Color(1, 1, 1, 0.4)

var drift_director: DriftDirector
const SHAPE_ROWS := preload("res://scripts/ui/shape_rows.gd")
var _shapes := SHAPE_ROWS.new()  # Drift shapes at a rest (owner 2026-10-24, enemy_design.md "Drift shapes")
var compact := false  # A drift is walking: the small row
var next_after_rest := false  # Compact in a block's last drift: the next block's first drift ("After the rest")
var _caption := Label.new()
var _row := VBoxContainer.new()  # Rows of up to PER_ROW kinds (each an HBoxContainer)
var _built_for := ""  # "mode:first:last" of what's shown ("" = nothing)
var _fog := UiStyle.panel()

func _init(director: DriftDirector = null) -> void:
	drift_director = director

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	offset_top = TOP
	mouse_filter = Control.MOUSE_FILTER_STOP  # A panel: the map's hover tags never show through it (user screenshot)
	add_theme_constant_override("separation", CAPTION_GAP)  # Caption → discs: the "New" badge sits 6 px above a disc
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.caps(_caption, UiStyle.BODY_SIZE)  # At body size
	add_child(_caption)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 4)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	add_child(_shapes)  # Drift shapes: a row per drift of the next block at a rest (shape_rows.gd)
	_kind_words.name = "KindWords"
	_kind_words.add_theme_constant_override("separation", 0)
	_kind_words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_kind_words)
	move_child(_kind_words, 1)  # In the caption's place, over the discs
	_phone = UiStyle.is_phone()
	if _phone:
		_caption.visible = false
		add_theme_constant_override("separation", 0)
	# The panel's padding is part of the strip's own rect (user screenshot, Moon-glass: a portrait and its "×30" hung
	# over the frame's bottom border), so everything placed under it clears the frame too: an empty spacer at the top and
	# the foot; on PC the separation adds CAPTION_GAP on each side, on phones the spacers carry PHONE_PAD.
	for pad: Control in [_pad_top, _pad_foot]:
		pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pad.custom_minimum_size.y = PHONE_PAD if _phone else 0.0
	add_child(_pad_top)
	move_child(_pad_top, 0)
	add_child(_pad_foot)
	if _phone:
		_make_phone_toggle()
	else:
		_make_pc_chip()
	visible = false
	resized.connect(queue_redraw)

const PHONE_PAD := 8.0
const SIDE_PAD := 16.0  # The frame's sides beyond the widest row (6 on phones)
var _pad_top := Control.new()
var _pad_foot := Control.new()

# The strip sits on its panel, the padding inside its own rect (the spacers above): portraits and badges stay inside.
func _draw() -> void:
	# PC, in a drift too: opened from the chip or showing the warning line, it sits on its panel (user screenshots
	# 2026-10-24: "Still to come this block" and "Drift 6 · Armoured: …" drew on no panel, text over the map)
	if _phone:  # The dropdown's panel, under the Incoming button, only while open
		if phone_open:
			var top := _phone_toggle.size.y + PHONE_DROP_GAP
			draw_style_box(_fog, Rect2(Vector2(0, top), size - Vector2(0, top)))
		return
	if not pc_open and not _kind_words.visible:
		return  # PC, shut: the chip on the banner row stands in for it
	var box := size.max(get_combined_minimum_size())  # Never smaller than what it holds (user 2026-10-22: opened from the chip, the
	draw_style_box(_fog, Rect2(Vector2(-SIDE_PAD, 0), box + Vector2(SIDE_PAD * 2.0, 0)))  # faces showed on no panel)

const REFRESH := 0.2  # Seconds (real time) between checks: the span, the boss scan and the stack (perf)
var _clock := 0.0

func _process(delta: float) -> void:
	_clock -= delta / maxf(Engine.time_scale, 0.001)
	if _clock > 0.0:
		return
	_clock = REFRESH
	_stack()
	var span := shown_span()
	# Hidden, steadily, while a screen covers the map (RestScreens.covering: a choice, Remember, a Lesson, the pause menu…;
	# "Peek at the map" shows it again). Only this line sets the strip's visibility (it flickered behind the Dream screen
	# when the phone HUD hid it too, user screenshot 2026-10-17).
	visible = span.y >= span.x and not RestScreens.covering(get_parent()) and not _under_drawer()
	if _chip != null:
		_chip.visible = visible
		if not visible and pc_open:
			_chip.button_pressed = false
	if not visible:
		_built_for = ""
		_chip_for = ""
		return
	var key := "%s:%d:%d" % [compact, span.x, span.y]
	if not compact:
		key += ":" + SHAPE_ROWS.omen_key(drift_director)  # The shapes' numbers come once the Omen is picked
	if key != _built_for:
		_built_for = key
		_build(span)
		_lit_for = -1  # New items: light them again
	if compact:
		_light_next()
	if _chip != null:  # PC: the chip shows what comes; the strip opens from it
		_fill_chip(span)
		_apply_pc()
		_place_chip()

# The top-centre stack (playtest 2026-09-30: the strip overlapped the Omen line): the drift banner,
# then the active Omen's line (Roguelite's OmenScreen tag "ActiveOmen"), then this strip.
const OMEN_TOP := 68.0  # Just under the banner's boss row
func _stack() -> void:
	if _phone:
		_stack_phone()
		return
	var top := TOP
	var omen := get_parent().get_node_or_null("ActiveOmen") as Control if get_parent() != null else null
	if omen != null and omen.visible:
		omen.offset_top = OMEN_TOP
		if omen is Label and omen.autowrap_mode == TextServer.AUTOWRAP_OFF:  # Long Omens wrap to 2 lines, never clipped
			omen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			omen.offset_left = -OMEN_WIDTH / 2.0
			omen.offset_right = OMEN_WIDTH / 2.0
		top = maxf(top, OMEN_TOP + omen.size.y + 14.0)  # Clear of the strip's fog panel too
	offset_top = top
const OMEN_WIDTH := 640.0

# The drifts whose kinds show now (x > y = none): the next block at a rest, the rest of the current
# block during a drift (none in a boss drift or after the run).
func shown_span() -> Vector2i:
	if drift_director == null or not drift_director.has_next_drift() or drift_director.awaiting_family_pick:
		return Vector2i(1, 0)
	var run_state := drift_director.get_node_or_null("%RunState")  # Made in code: no owner of its own
	if run_state != null and run_state.is_over:
		return Vector2i(1, 0)
	var started := drift_director.drifts_started
	var per := drift_director.drifts_per_block
	compact = not drift_director.is_resting()
	if not compact:
		var block := drift_director.get_block(started + 1)
		return Vector2i((block - 1) * per + 1, mini(block * per, drift_director.get_total_drifts()))
	if drift_director.is_boss_drift(started) or _boss_walking():
		return Vector2i(1, 0)
	var block_end := drift_director.get_block(maxi(started, 1)) * per
	next_after_rest = started >= block_end
	if next_after_rest:  # The block's last drift walks: the next drift (after the rest), so the strip never vanishes mid-drift
		return Vector2i(started + 1, started + 1)
	return Vector2i(started + 1, mini(block_end, drift_director.get_total_drifts()))

func _boss_walking() -> bool:
	for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
		if enemy.get("enemy_data") != null and enemy.enemy_data.is_boss and not enemy.is_cleansed:
			return true
	return false

# Kinds arriving in drifts `first`..`last` (first appearance order, bosses last) with the drift
# each first comes in and how many come in all (the difficulty's extra nightmares and the Omen's
# count changes included, as DriftDirector schedules them): [[EnemyData, drift, count], …].
static func kinds_in_range(director: DriftDirector, first: int, last: int) -> Array:
	var kinds: Array = []
	var bosses: Array = []
	var by_kind := {}  # resource path -> its [data, drift, count]
	for number in range(first, last + 1):
		var extra := director.get_extra_nightmares(number)
		var mods: Dictionary = director.get_schedule_modifiers(number)
		for group in director.drifts[number - 1].groups:
			for entry in group.entries:
				var data: EnemyData = entry.enemy
				if data == null:
					continue
				var count: int = entry.get_count(mods.get("count", 1.0), mods.get("flyers", 1.0), extra)
				if by_kind.has(data.resource_path):
					by_kind[data.resource_path][2] += count
					continue
				var item := [data, number, count]
				by_kind[data.resource_path] = item
				(bosses if data.is_boss else kinds).append(item)
	return kinds + bosses

static func kinds_in_block(director: DriftDirector, block: int) -> Array:
	var first := (block - 1) * director.drifts_per_block + 1
	return kinds_in_range(director, first, mini(block * director.drifts_per_block, director.get_total_drifts()))

# Laid out low and wide (screens_ui.md "Coming this block" → "Too tall": six kinds stacked five rows
# deep): one centred row of equal round discs, a second row only past PER_ROW kinds, and past two rows
# a "+N" chip that opens the rest on tap. About 90 px tall at rests.
const PER_ROW := 6
const CAPTION_GAP := 18  # 6 px clear between the caption and a "New" tab (12 px over its disc), the disc row 18 below (user)

func _build(span: Vector2i) -> void:
	_caption.text = ("After the rest" if next_after_rest else "Still to come this block") if compact else "Coming this block"
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	var kinds := kinds_in_range(drift_director, span.x, span.y)
	# New rule-breakers (RuleBreakers: a flyer, sprinter… this run hasn't faced) lead at rests, larger, with their trait in words.
	var breaking := {}
	if not compact:
		for item in RuleBreakers.new_in(drift_director, span.x, span.y):
			breaking[item[0].resource_path] = true
		if not breaking.is_empty():
			var first_ones := kinds.filter(func(k: Array) -> bool: return breaking.has(k[0].resource_path))
			kinds = first_ones + kinds.filter(func(k: Array) -> bool: return not breaking.has(k[0].resource_path))
	var shown := kinds
	var rest: Array = []
	var per_row := PHONE_PER_ROW if _phone else PER_ROW
	var cap := per_row if _phone else PER_ROW * 2  # Phones: one row
	if kinds.size() > cap:  # The last slot becomes "+N"
		shown = kinds.slice(0, cap - 1)
		rest = kinds.slice(cap - 1)
	var line: HBoxContainer = null
	for i in shown.size():
		if i % per_row == 0:
			if line != null:
				line.add_child(_hang_room())
			line = HBoxContainer.new()
			line.alignment = BoxContainer.ALIGNMENT_CENTER
			line.add_theme_constant_override("separation", BADGE_HANG + 4)  # Room for each count plate past its disc, +4 clear
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_row.add_child(line)
			line.add_child(_hang_room())  # The same room on the left keeps the discs centred
		line.add_child(_make_item(shown[i][0], shown[i][1], shown[i][2], breaking.has(shown[i][0].resource_path)))
	if not rest.is_empty():
		line.add_child(_more_chip(rest))
	if line != null:
		line.add_child(_hang_room())
	_build_kind_words(span)
	_shapes.build(drift_director, span, compact)

# A Kind's first drift this run, in words on the strip itself (Balancing Discussion, owner 2026-10-19: "warning 1 drift
# earlier is better"; human run lost to drift 31's Phantoms). Only the very next drift, at a rest and mid-block alike
# (owner 2026-10-19: "should just be the 1 drift earlier"): the drift 30 rest names drift 31's Phantoms ("Drift 31 · Flying:
# flies over your maze"); a Kind first coming at drift 33 shows once drift 32 is under way. Plain text, no hover or tap
# needed (phones too). Kinds from EnemyData.Kind.
const KIND_WORDS := {EnemyData.Kind.ARMOURED: "heavy hits crack its shell", EnemyData.Kind.FLYING: "flies over your maze",
	EnemyData.Kind.HIDDEN: "can't be targeted until a Warden reveals it", EnemyData.Kind.SWARM: "comes as a crowd; area attacks catch them all",
	EnemyData.Kind.FAST: "outruns a thin maze; slows and holds keep it in reach"}
const KIND_WORDS_WIDTH := 640.0  # One line for the longest (Fast) at 16 px
var _kind_words := VBoxContainer.new()

# [[Kind, EnemyData, drift], …]: the Kinds (not Plain, never bosses) first arriving in drifts `first`..`last` this run.
static func new_kinds(director: DriftDirector, first: int, last: int) -> Array:
	if director == null or first > last:
		return []
	var faced := {}
	if first > 1:
		for item in kinds_in_range(director, 1, first - 1):
			if not item[0].is_boss:  # A boss has its dossier; it doesn't teach the Kind
				faced[item[0].kind] = true
	var result: Array = []
	for item in kinds_in_range(director, first, last):
		var data: EnemyData = item[0]
		if data.is_boss or data.kind == EnemyData.Kind.PLAIN or faced.has(data.kind):
			continue
		faced[data.kind] = true
		result.append([data.kind, data, item[1]])
	return result

static func kind_words(data: EnemyData) -> String:
	var what: String = KIND_WORDS.get(data.kind, "")
	if data.kind == EnemyData.Kind.FLYING and not data.is_through_walls():
		what = "flies along your path"
	return "%s: %s" % [data.get_kind_name(), what]

func _build_kind_words(_span: Vector2i) -> void:
	for child in _kind_words.get_children():
		_kind_words.remove_child(child)
		child.queue_free()
	var next := drift_director.drifts_started + 1  # Only the very next drift, at a rest and mid-block alike
	for entry in new_kinds(drift_director, next, next):
		var words := Label.new()
		words.name = "Kind%d" % entry[0]
		words.text = "Drift %d brings %s" % [entry[2], kind_words(entry[1])]  # No " · " (ui_style.md)
		words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.custom_minimum_size.x = minf(KIND_WORDS_WIDTH, get_viewport_rect().size.x - 32.0) if _phone else KIND_WORDS_WIDTH
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiStyle.plain(words, UiStyle.BODY_SIZE, UiStyle.GOLD)  # Body size, as the caption (user 2026-10-24: "different text size"; it was 15)
		if not _phone:  # As wide as its words (the panel hugs a short line), wrapping only past KIND_WORDS_WIDTH
			var need := UiStyle.body_medium_font().get_string_size(words.text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiStyle.BODY_SIZE).x
			words.custom_minimum_size.x = minf(ceilf(need) + 2.0, KIND_WORDS_WIDTH)
		_kind_words.add_child(words)
	_kind_words.visible = _kind_words.get_child_count() > 0 and not _phone  # Phones: no "Drift N · …" line (user 2026-10-21: "remove the drift hint"; a disc's tap card says it)
	if not _phone:  # The line takes the caption's place, so the strip stays low (test_rule_breakers: 140 px)
		_caption.visible = not _kind_words.visible and not compact  # In a drift: no caption (its words are the tip)
	tooltip_text = _caption.text if compact else ""
	queue_redraw()  # The box comes and goes with a rest

# The kind items, whichever row they're on.
func items() -> Array:
	var all: Array = []
	for line in _row.get_children():
		for item in line.get_children():
			if item.has_meta(&"kind"):
				all.append(item)
	return all

# Compact: the next drift's kinds lit, the rest dimmed.
var _lit_for := -1  # The drift the lit set was built for (rebuilt only when a drift starts; perf)

func _light_next() -> void:
	var next := drift_director.drifts_started + 1
	if next == _lit_for:
		return
	_lit_for = next
	var lit := {}
	if next <= drift_director.get_total_drifts():
		for pair in kinds_in_range(drift_director, next, next):
			lit[pair[0]] = true
	for item in items():
		item.modulate = Color.WHITE if lit.has(item.get_meta(&"kind")) else DIM

# One kind: the same round disc for every kind (the art fitted inside, whatever its shape), "New" and
# the count as badges on its corners, the resist / weak row under it (14 px). Its name on hover / tap.
func _make_item(data: EnemyData, drift: int, count: int = 1, breaks_rules: bool = false) -> Control:
	var item := VBoxContainer.new()
	item.set_meta(&"kind", data)
	item.set_meta(&"breaks_rules", breaks_rules)
	item.add_theme_constant_override("separation", 1)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var side := FACE_SMALL if compact else (FACE_BIG if breaks_rules else FACE)
	if _phone:
		side = PHONE_FACE  # Phones: one small row (user 2026-10-17: "Coming this block is taking up a space")
	# The disc and its badges as siblings in a holder: the disc clips its art, the badges must not be clipped
	# (user screenshot: "New" showed as "EW", the counts as "×1?").
	var holder := Control.new()
	holder.name = "Disc"
	holder.custom_minimum_size = Vector2(side, side)
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(holder)
	var face := Button.new()
	face.name = "Face"
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face.icon = NightmareCard.portrait(data)
	face.expand_icon = true
	face.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	face.custom_minimum_size = Vector2(side, side)
	face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Never stretched into a wide pill
	face.clip_contents = true
	face.focus_mode = Control.FOCUS_NONE
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.add_theme_color_override("icon_normal_color", data.tint)
	face.add_theme_constant_override("icon_max_width", int(side - 10))
	face.tooltip_text = "%s, ×%d" % [data.display_name, count]  # No " · " (ui_style.md)
	UiStyle.moon_disc_button(face, BOSS_COLOR if data.is_boss else UiStyle.OFF)  # Pale disc: readable on the night sky
	if _phone:  # A 40 px tap target, the disc drawn PHONE_DISC inside it (it sits in a plate the buttons' size)
		var inset := (side - PHONE_DISC) / 2.0
		for state in ["normal", "pressed", "disabled", "hover", "hover_pressed"]:
			var disc := face.get_theme_stylebox(state).duplicate() as StyleBox
			if "expand_margin_left" in disc:
				for side_name in ["expand_margin_left", "expand_margin_right", "expand_margin_top", "expand_margin_bottom"]:
					disc.set(side_name, -inset)
			face.add_theme_stylebox_override(state, disc)
		face.add_theme_constant_override("icon_max_width", int(PHONE_DISC - 8))
	if data.is_boss:
		face.pressed.connect(func() -> void: BossDossier.open_for(get_tree(), drift))
	else:  # One centred card for every nightmare (its name, what it does)
		face.pressed.connect(func() -> void: NightmareIntro.open_for(get_tree(), [data], drift))
	holder.add_child(face)
	var badge := Label.new()  # How many come: on a dark pill inside the disc's lower-right corner
	badge.name = "KindCount"
	badge.text = "×%d" % count
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.number(badge, UiStyle.BODY_SIZE, UiStyle.GOLD)  # As the chip's counts (user 2026-10-24: "different text size"; it was 13)
	_badge_look(badge)
	badge.add_theme_stylebox_override("normal", UiStyle.plate_box(3.0, 0.0))  # On a small glass plate (UI council round 4: hard to read bare)
	# Hung off the disc's corner, not over the nightmare's face (UI council 2026-10-22: "×57" covered the art): its left edge
	# on the rim, growing right (user screenshot 2026-10-24: a 20 px push from a guessed width still covered the small disc)
	badge.anchor_left = 1.0
	badge.anchor_right = 1.0
	badge.anchor_top = 1.0
	badge.anchor_bottom = 1.0
	badge.offset_left = -BADGE_ON_RIM
	badge.offset_right = -BADGE_ON_RIM
	badge.offset_top = 4.0  # Its foot 4 px under the disc: clear of the panel's bottom rim
	badge.offset_bottom = 4.0
	badge.grow_horizontal = Control.GROW_DIRECTION_END
	badge.grow_vertical = Control.GROW_DIRECTION_BEGIN
	holder.add_child(badge)
	if breaks_rules or NightmareCard.is_new(data):  # "New": a gold tab over the disc's top edge (a new rule-breaker: always)
		var tag := Label.new()
		tag.name = "New"
		tag.text = "New"
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiStyle.caps(tag, 11, UiStyle.GOLD)
		_badge_look(tag)
		tag.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		tag.grow_horizontal = Control.GROW_DIRECTION_BOTH
		tag.offset_top = -12.0  # Above the disc's rim, off the face
		tag.offset_bottom = tag.offset_top + 14.0
		holder.add_child(tag)
	if not compact:
		var icons := NightmareIcons.make_rows(data, 14.0, true)
		# The item's full width (the flow centres them): shrunk to one icon, a flow wrapped every icon onto its own line
		# (a Phantom resisting one family and weak to another stood 113 px tall, Spire 2026-10-02).
		icons.size_flags_horizontal = Control.SIZE_FILL
		item.add_child(icons)
	if breaks_rules:  # Just its verb ("Flies"): the DriftPanel's warning line has the sentence
		var words := Label.new()
		words.name = "TraitWords"
		words.text = String(RuleBreakers.VERBS.get(data.trait_kind, "Breaks the rules")).capitalize()
		words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		words.add_theme_font_size_override("font_size", 14)
		words.add_theme_color_override("font_color", UiStyle.GOLD)
		item.add_child(words)
	return item

const BADGE_ON_RIM := 6.0  # The count plate's left edge sits this far over the disc's rim
const BADGE_HANG := 36.0  # How far a count plate ("×16", "×157") reaches past its disc

# An empty end of a row of discs: the row's separation beside it is the room, so the last count plate stays on the
# panel and the discs stay centred (one at each end).
func _hang_room() -> Control:
	var room := Control.new()
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return room

# A badge over a portrait ("×22", "New"): a crisp Void outline round the letters keeps it readable on the pale disc, no
# dark pill under it (user 2026-10-21: "why is it dark underneath the 22 and 4").
func _badge_look(label: Label) -> void:
	var room := StyleBoxEmpty.new()
	room.content_margin_left = 3.0
	room.content_margin_right = 3.0
	label.add_theme_stylebox_override("normal", room)
	label.add_theme_color_override("font_outline_color", Palette.VOID)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_shadow_color", Color(Palette.VOID, 0.0))  # The theme's soft shadow would smear it

# "+N": the kinds that didn't fit; a tap opens their cards in turn.
func _more_chip(rest: Array) -> Control:
	var chip := Button.new()
	chip.name = "More"
	chip.text = "+%d" % rest.size()
	chip.focus_mode = Control.FOCUS_NONE
	var chip_side := PHONE_FACE if _phone else (FACE_SMALL if compact else FACE)
	chip.custom_minimum_size = Vector2(chip_side, chip_side)
	chip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	chip.tooltip_text = ", ".join(rest.map(func(k: Array) -> String: return k[0].display_name))
	var kinds: Array = rest.filter(func(k: Array) -> bool: return not k[0].is_boss).map(func(k: Array) -> EnemyData: return k[0])
	chip.pressed.connect(func() -> void: NightmareIntro.open_for(get_tree(), kinds, drift_director.drifts_started + 1))
	return chip

# Phones (user 2026-10-21 screenshot: the strip's "Drift 16 · Swarm" line drew over the Warden drawer): hidden while the
# drawer is open, as the drift panel is.
# PC (user 2026-10-22, mock-up https://claude.ai/artifact/D52C8XkKfUk8MHZVN9W6Gt: "Coming this block" took a 110 px box
# under the banner for one icon): a chip on the banner's second row, left of the drift pips: the first kinds' faces and
# counts ("×57"), "+N" for more, a gold dot when a never-met kind or a new rule-breaker comes. A click opens the strip
# (as it was) under the banner; a click again or anywhere else folds it. The "Drift N · Flying: …" warning line
# (owner 2026-10-19) never folds: it shows on its own when the strip is shut.
const CHIP_FACE := 22.0
const CHIP_KINDS := 2  # Faces with counts; the rest as "+N"
const CHIP_GAP := 10.0  # Between the chip and the pips
var pc_open := false
var _chip: Button = null
var _chip_row := HBoxContainer.new()
var _chip_for := ""

func _make_pc_chip() -> void:
	_chip = Button.new()
	_chip.name = "ComingChip"
	_chip.toggle_mode = true
	_chip.focus_mode = Control.FOCUS_NONE
	_chip.tooltip_text = "Coming this block. Click to see them."
	_chip.visible = false
	for pair in [[&"normal", &"plate"], [&"hover", &"plate_hover"], [&"pressed", &"plate_pressed"], [&"hover_pressed", &"plate_pressed"]]:
		_chip.add_theme_stylebox_override(pair[0], UiStyle.plate_box(6.0, 2.0, pair[1]))
	_chip_row.name = "Kinds"
	_chip_row.add_theme_constant_override("separation", 6)
	_chip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_chip_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chip_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_chip.add_child(_chip_row)
	_chip.toggled.connect(func(on: bool) -> void:
		pc_open = on
		_apply_pc()
		_place_chip())
	get_parent().add_child.call_deferred(_chip)

# The chip's faces for `span` (rebuilt only when the span changes).
func _fill_chip(span: Vector2i) -> void:
	var key := "%d:%d" % [span.x, span.y]
	if key == _chip_for:
		return
	_chip_for = key
	for child in _chip_row.get_children():
		_chip_row.remove_child(child)
		child.queue_free()
	var kinds := kinds_in_range(drift_director, span.x, span.y)
	var fresh := not RuleBreakers.new_in(drift_director, span.x, span.y).is_empty()
	for i in mini(kinds.size(), CHIP_KINDS):
		var data: EnemyData = kinds[i][0]
		fresh = fresh or NightmareCard.is_new(data)
		var face := TextureRect.new()
		face.texture = NightmareCard.portrait(data)
		face.custom_minimum_size = Vector2(CHIP_FACE, CHIP_FACE)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		face.modulate = data.tint  # multiplier: placeholder art's recolour, as the strip's discs
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_chip_row.add_child(UiStyle.on_moon_disc(face))  # On the strip's pale disc: the dark art vanished on the plate
		var count := Label.new()
		count.text = "×%d" % int(kinds[i][2])
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiStyle.number(count, 16, Palette.HEARTLIGHT)  # One size up, brighter (UI council round 7: it read as dust)
		_chip_row.add_child(count)
	for i in range(CHIP_KINDS, kinds.size()):
		fresh = fresh or NightmareCard.is_new(kinds[i][0])
	if kinds.size() > CHIP_KINDS:
		var more := Label.new()
		more.text = "+%d" % (kinds.size() - CHIP_KINDS)
		more.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiStyle.number(more, 16, UiStyle.INK_DIM)
		_chip_row.add_child(more)
	if fresh:  # A never-met kind or a new rule-breaker: a small gold dot
		var dot := Control.new()
		dot.custom_minimum_size = Vector2(14, 14)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.draw.connect(func() -> void:  # A 5 px gold dot in a soft glow (council round 7: 3 px read as dust)
			dot.draw_circle(dot.size / 2.0, 6.5, Color(UiStyle.GOLD, 0.22))
			dot.draw_circle(dot.size / 2.0, 4.0, Color(UiStyle.GOLD, 0.35))
			dot.draw_circle(dot.size / 2.0, 2.5, UiStyle.GOLD))
		_chip_row.add_child(dot)
	_chip.tooltip_text = "Coming this block%s. Click to see them." % (", something new" if fresh else "")
	var need := _chip_row.get_combined_minimum_size()
	_chip.custom_minimum_size = Vector2(need.x + 16.0, maxf(need.y + 6.0, 30.0))
	_chip.size = _chip.custom_minimum_size

# The strip's own parts follow the chip: shut, only the warning line shows (on its fog); open, the whole strip.
func _apply_pc() -> void:
	if _phone:
		return
	_row.visible = pc_open
	_shapes.visible = pc_open and _shapes.has_rows()
	_caption.visible = pc_open and not _kind_words.visible
	for pad: Control in [_pad_top, _pad_foot]:
		pad.visible = pc_open or _kind_words.visible
	mouse_filter = Control.MOUSE_FILTER_STOP if (pc_open or _kind_words.visible) else Control.MOUSE_FILTER_IGNORE
	queue_redraw.call_deferred()

# Left of the banner's drift pips, centred on their row.
func _place_chip() -> void:
	if _chip == null or not _chip.is_inside_tree():
		return
	var banner := get_parent().get_node_or_null("DriftBanner") as Control
	var pips: Rect2 = banner.get("_pips_rect") if banner != null else Rect2()
	if banner == null or not banner.visible or pips.size == Vector2.ZERO:
		_chip.visible = false
		return
	var at := banner.global_position + pips.position
	_chip.position = Vector2(roundf(at.x - CHIP_GAP - _chip.size.x), roundf(at.y + pips.size.y / 2.0 - _chip.size.y / 2.0))

func _input(event: InputEvent) -> void:
	if _chip == null or not pc_open or not (event is InputEventMouseButton and event.pressed):
		return
	var at := get_global_mouse_position()  # Canvas space, as the rects (the UI scale changes the event's)
	if not _chip.get_global_rect().has_point(at) and not get_global_rect().has_point(at):
		_chip.button_pressed = false  # A click anywhere else folds it (the click still goes on to the map)

func _under_drawer() -> bool:
	if not _phone:
		return false
	var hud := get_parent()
	while hud != null and hud.get_node_or_null("WardenPanel") == null:
		hud = hud.get_parent()
	var drawer := hud.get_node_or_null("WardenPanel") as CanvasItem if hud != null else null
	return drawer != null and drawer.visible

# Phones (user 2026-10-21: "move the drifts coming somewhere else, takes too much space", "put the incoming drift to the
# top right between the buttons and middle title", "a smaller bar that fits the theme", then "instead of the picture,
# have a word: Incoming"): an "Incoming" button like the top-right ones (HudButton), just left of them and level with
# them; Gold when a never-met kind comes. A tap drops the discs and the "Drift N · …" lines down under it, on the panel;
# a tap again (or on a disc's card) folds it. Without room beside the buttons it sits just under them.
const PHONE_GAP := 0.0  # HudButtons sit edge to edge (their visible boxes are inset)
const PHONE_DROP_GAP := 0.0  # (The button's inset plate leaves 6 px under it already)
const PHONE_BOX_INSET := 6.0  # As hud.gd BUTTON_BOX_INSET
const PHONE_DROP_W := 420.0  # The dropdown's "Drift N · …" lines wrap at this
var phone_open := false
var _phone_toggle := Button.new()

func _make_phone_toggle() -> void:
	# Placed again whenever the window changes or it shows (Main Merger 2026-10-21: placed while the window was still 64 px
	# wide, it stayed at x -66 until the next 0.2 s refresh)
	get_viewport().size_changed.connect(_stack_phone.call_deferred)
	visibility_changed.connect(func() -> void:
		if visible:
			_stack_phone())
	_phone_toggle.name = "Incoming"
	_phone_toggle.text = "Incoming"
	_phone_toggle.theme_type_variation = &"HudButton"
	_phone_toggle.toggle_mode = true
	_phone_toggle.focus_mode = Control.FOCUS_NONE
	_phone_toggle.custom_minimum_size = Vector2(0, UiStyle.HUD_BUTTON_H)
	_phone_toggle.size_flags_horizontal = Control.SIZE_SHRINK_END
	_phone_toggle.tooltip_text = "The nightmares of the next drifts. Tap to see them."
	# The same visible height as the icon buttons beside it (user 2026-10-21): their plate inset 6 px inside the 48 px hit
	# area (hud.gd _place_top_button, BUTTON_BOX_INSET).
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var box := _phone_toggle.get_theme_stylebox(state, &"HudButton")
		if box is MoonStyleBox and "inset" in box:
			box = box.duplicate()
			box.set("inset", Vector2(PHONE_BOX_INSET, PHONE_BOX_INSET))
			_phone_toggle.add_theme_stylebox_override(state, box)
		elif box != null and "expand_margin_left" in box:
			box = box.duplicate()
			for side_name in ["expand_margin_left", "expand_margin_right", "expand_margin_top", "expand_margin_bottom"]:
				box.set(side_name, -PHONE_BOX_INSET)
			_phone_toggle.add_theme_stylebox_override(state, box)
	_phone_toggle.add_theme_font_size_override("font_size", 14)  # Fits the 36 px box
	var font := _phone_toggle.get_theme_font("font")
	_phone_toggle.custom_minimum_size.x = ceilf(font.get_string_size(_phone_toggle.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x) \
		+ 2.0 * (PHONE_BOX_INSET + 12.0)  # 12 px of air inside the plate on each side
	_phone_toggle.toggled.connect(func(on: bool) -> void:
		phone_open = on
		_built_for = ""  # Rebuild with or without the dropdown's lines
		_stack_phone()
		queue_redraw())
	add_child(_phone_toggle)
	move_child(_phone_toggle, 0)
	var gap := Control.new()
	gap.name = "DropGap"
	gap.custom_minimum_size.y = PHONE_DROP_GAP
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gap)
	move_child(gap, 1)

func _stack_phone() -> void:
	for node in [_row, _shapes, _kind_words, _pad_top, _pad_foot, get_node_or_null("DropGap")]:
		if node != null:
			node.visible = phone_open and node != _kind_words
	var fresh := false
	for item in items():
		if bool(item.get_meta(&"breaks_rules", false)) or NightmareCard.is_new(item.get_meta(&"kind")):
			fresh = true
	for state in ["font_color", "font_hover_color"]:
		_phone_toggle.add_theme_color_override(state, UiStyle.GOLD if fresh else UiStyle.INK)
	for words in _kind_words.get_children():
		(words as Control).custom_minimum_size.x = PHONE_DROP_W
	var hud := get_parent()
	if hud == null:
		return
	var buttons_left := get_viewport_rect().size.x - 16.0
	var buttons_top := 12.0
	var buttons_bottom := 12.0
	var names: Array = hud.call("_top_row_names") if hud.has_method("_top_row_names") else []
	for name in names:
		var button := hud.get_node_or_null(name) as Control
		if button != null and button.visible:
			buttons_left = minf(buttons_left, button.get_rect().position.x)
			buttons_top = button.get_rect().position.y
			buttons_bottom = maxf(buttons_bottom, button.get_rect().end.y)
	var banner_right := 0.0
	var banner := hud.get_node_or_null("DriftBanner") as Control
	if banner != null and banner.visible and banner.has_method("drawn_rect"):
		banner_right = banner.drawn_rect().end.x - (hud.global_position.x if hud is Control else 0.0)
	var need := get_combined_minimum_size()
	var toggle_w := _phone_toggle.get_combined_minimum_size().x
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_END
	var right := buttons_left - PHONE_GAP
	var top := buttons_top
	if right - toggle_w < banner_right + 8.0:  # No room beside the buttons: just under them, right-aligned
		right = get_viewport_rect().size.x - 16.0
		top = buttons_bottom + 4.0
	position = Vector2(right - need.x, top)
	size = need
