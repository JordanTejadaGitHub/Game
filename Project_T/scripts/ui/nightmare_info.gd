extends PanelContainer

# Right-hand panel for the hovered nightmare (screens_ui.md "Nightmare info"). Moon-glass card (owner 2026-10-25: "remove
# any unneeded wording or info", "status icons, not words", "moon-glass restyle", "stays on click"): a header with the
# nightmare's portrait, its name (New / Deeply Blighted tags), one line of numbers and a health bar; its statuses as icon
# chips (stacks, a time bar, hollow while a Dream card's stacks are locked: section 36); then the lines only words can
# carry (trait, Omen, Pall, limits) and its Kind badge and line (NightmareIcons.kind_row).
# A small tooltip, never a screen: only while the pointer is on a nightmare (checked every frame against its live
# position), never over a HUD panel, gone after IDLE_TIME without a move (user 2026-10-22). A click on a nightmare pins
# it (PC; phones: the tap already does): the card stays on it, whatever the pointer hovers, until a click elsewhere,
# Esc / right click or its dispel. The full card opens only from the Coming strip, banner and Codex. A nightmare type
# never met before gets a "New" tag (remembered in HeartwoodMemory, by the real game only). Built in code.

const HOVER_RADIUS := 30.0  # Pixels (world) around a nightmare that count as hovering it
const PORTRAIT := 40.0  # px: the nightmare's first frame, nearest-filtered
const BAR_H := 6.0  # px: the health bar
const CHIP_SIZE := Vector2(32, 36)  # px: a status chip (16 px icon at x1, its stacks, its time bar)

var _target: Node2D = null
var _known := {}  # Nightmare kinds met before this run (for the "New" tag)
var _saved := {}  # Kinds already written to the profile (so the file is touched once per kind)
var _title := Label.new()
var _portrait := TextureRect.new()
var _health_bar := Control.new()
var _chips := HFlowContainer.new()  # One chip per status, the badge row's order
var _chip_note := StatusLinks.make_label("", UiStyle.TIP_SIZE - 2)  # The tapped / hovered chip's words, glossary links kept
var _chip_key := ""  # The statuses the chips were built for (rebuilt only when it changes)
var _note_for := &""
var _body := StatusLinks.make_label("", 15)  # Trait, Omen, Pall, limits (status names are links)
var _rows_box := VBoxContainer.new()  # Its Kind badge and line (NightmareIcons)
var _rows_for: EnemyData = null
var _portrait_for: EnemyData = null
var _disc: PanelContainer = null
var _disc_for: EnemyData = null
var _disc_held := false
var _note_held := false  # PC: the chip's words were clicked open (they stay when the pointer leaves the chip)
var _silence_full := 0.0  # The longest Silenced seen on this nightmare (its chip's time bar)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(UiStyle.TIP_WIDTH + 20.0, 0)  # Tip sizes (screens_ui.md playtest fixes 2026-09-30)
	add_theme_stylebox_override("panel", UiStyle.panel(12.0, 10.0))  # Moon-glass, as the Warden and Dreams meters
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(header)
	_portrait.custom_minimum_size = Vector2(PORTRAIT, PORTRAIT)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED  # Pre-scaled by a whole number (portrait_of): never a fraction
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_disc = UiStyle.on_moon_disc(_portrait)  # The pale moon disc every nightmare face sits on (screens_ui.md)
	header.add_child(_disc)
	var heading := VBoxContainer.new()
	heading.add_theme_constant_override("separation", 2)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(heading)
	UiStyle.tip_name(_title)
	heading.add_child(_title)
	_numbers.add_theme_font_size_override("font_size", UiStyle.TIP_SIZE - 2)
	_numbers.add_theme_color_override("font_color", UiStyle.INK_DIM)
	heading.add_child(_numbers)
	_health_bar.custom_minimum_size = Vector2(0, BAR_H)
	_health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_health_bar.draw.connect(_draw_health)
	box.add_child(_health_bar)
	_chips.add_theme_constant_override("h_separation", 4)
	_chips.add_theme_constant_override("v_separation", 4)
	_chips.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_child(_chips)
	UiStyle.tip_body(_chip_note)
	_chip_note.add_theme_font_size_override("normal_font_size", UiStyle.TIP_SIZE - 2)
	_chip_note.visible = false
	box.add_child(_chip_note)
	UiStyle.tip_body(_body)
	box.add_child(_body)
	box.add_child(_rows_box)
	visible = false
	for kind in HeartwoodMemory.load_data().get("nightmares_seen", []):
		_known[kind] = true
	_saved = _known.duplicate()
	var spawner = %EnemyContainer
	spawner.child_entered_tree.connect(_on_spawned)

# Hover tips stay until the pointer leaves their target (screens_ui.md "Hover and tap tips"): the
# panel keeps its nightmare while other nightmares are dispelled around it; when its own nightmare
# is dispelled it reads "Dispelled" for DISPELLED_TIME and clears, and never jumps to a neighbour
# until the pointer moves. Changing numbers update in place (a plain label); the status-link text is
# left alone while the pointer is on it or its popup is open.
const DISPELLED_TIME := 1.0
const MOVE_EPSILON := 3.0  # Screen px the pointer must move before the panel picks a new nightmare

var _dispelled_left := 0.0
var _last_mouse := Vector2(-1000, -1000)
var _numbers := Label.new()
var _await_move := false  # Cleared after a dispel: the next nightmare needs a pointer move
var test_pin: Node2D = null  # Tests only: the nightmare shown as if the pointer were on it (PC; null = the real hover)
const IDLE_TIME := 3.0  # Real seconds without a pointer move (phones: since the tap) before it hides
var _idle := 0.0
var _pinned: Node2D = null  # PC: the clicked nightmare (the card stays on it)
var _has_pin := false  # A pin is held (a freed nightmare reads as null: this flag keeps a dispelled pin held)
var _pin_gone := false  # The pinned nightmare was dispelled: the card stays, frozen, until the player lets go
var _pin_dispelled := false  # Its pinned nightmare was dispelled (not leaked) on the last frame it was seen
var _target_dispelled := false  # The same for the hovered one
var _last_data: EnemyData = null  # The shown nightmare's kind and max health on its last live frame (a frozen card)
var _last_max := 0

# Pin or let go (PC input): a new pin (or none) ends a dispelled pin's frozen card.
func _set_pin(enemy: Node2D) -> void:
	if _pin_gone:  # Letting go of a dispelled pin closes its card at once (no second "Dispelled" second)
		_target = null
		visible = false
	_pinned = enemy
	_has_pin = enemy != null
	_pin_gone = false
	_pin_dispelled = false

# A dispelled nightmare's card (pinned: until let go; hovered: for DISPELLED_TIME): "Dispelled" in the title and only
# what is still true on it (speed, leaves, limits, a Pall overhead, its statuses: no longer).
func _freeze_dispelled() -> void:
	if _last_data != null:
		_title.text = _last_data.display_name + " · Dispelled"
		_numbers.text = "Health 0 / %d" % _last_max
		_body.text = StatusLinks.bbcode(_last_data.trait_text)
		_body.visible = _last_data.trait_text != ""
	_note_for = &""
	_note_held = false
	_chips.visible = false
	_chip_note.visible = false
	_health_bar.queue_redraw()
	_set_hud_focus(null)

func _hide_card() -> void:
	_target = null
	visible = false
	_set_hud_focus(null)

func _process(delta: float) -> void:
	var mouse := get_viewport().get_mouse_position()
	var moved := mouse.distance_to(_last_mouse) > MOVE_EPSILON
	_last_mouse = mouse
	var blocked := RestScreens.map_blocked(self)
	if blocked and not TouchBuild.mobile_controls():  # A choice / rest screen lets go of a pin and hides the card
		if _has_pin:
			_set_pin(null)
		_hide_card()
		return
	# A pinned nightmare dispelled (owner 2026-10-25: "keep it on even if the unit is dispelled"): its card stays, "Dispelled"
	# in the title, only what is still true on it, until a click elsewhere, Esc / right click, a tool or a new pin. A
	# nightmare that leaked (gone without a dispel) just closes its card.
	if _has_pin and is_instance_valid(_pinned) and not _pin_gone:
		_pin_dispelled = _pinned.is_cleansed
	if _has_pin and (_pin_gone or not is_instance_valid(_pinned) or _pinned.is_cleansed):
		if not _pin_gone and not _pin_dispelled:
			_set_pin(null)  # A leak: no "Dispelled", the card closes
			_hide_card()
			return
		if not _pin_gone:
			_pin_gone = true
			_freeze_dispelled()
		visible = true
		return
	if is_instance_valid(_target):
		_target_dispelled = _target.is_cleansed
	var target_gone: bool = not is_instance_valid(_target) or _target.is_cleansed
	if target_gone and _target != null and not _target_dispelled and _dispelled_left <= 0.0:
		_hide_card()  # A leak: gone without a dispel, no "Dispelled"
		return
	if target_gone and _target != null and _dispelled_left <= 0.0 and visible:
		_dispelled_left = DISPELLED_TIME  # Its nightmare was just dispelled: say so, then clear
		_freeze_dispelled()
	if _dispelled_left > 0.0:
		_dispelled_left -= delta / maxf(Engine.time_scale, 0.001)
		if _dispelled_left > 0.0 and not moved:
			return
		_dispelled_left = 0.0
		_target = null
		_await_move = true
	var hovered := _hovered_nightmare()
	# A small tooltip that always goes away (user 2026-10-22: "I hover and the screen pops up and never goes away"): the
	# target is checked against the live position every frame, so it hides the moment the pointer is off it (the pointer
	# left, or the nightmare walked out from under it), over a HUD panel, after IDLE_TIME without the pointer moving
	# (phones: since the tap), and when its nightmare is gone. A pinned nightmare (a click) stays until a click elsewhere.
	_idle = 0.0 if moved else _idle + delta / maxf(Engine.time_scale, 0.001)
	if TouchBuild.mobile_controls() and _dispelled_left <= 0.0:
		_target = hovered  # Phones: the tapped nightmare, kept until a tap elsewhere (user 2026-10-25: no timeout, 64c30f7f)
	elif _has_pin:
		_target = _pinned  # Pinned (owner 2026-10-25: "stay on the pinned until you let go"): hover doesn't move it
	elif is_instance_valid(test_pin) and not test_pin.is_cleansed:
		_target = test_pin  # Tests: held as if hovered, whatever the (headless) pointer does
	else:
		if moved:
			_await_move = false
		var on_ui := get_viewport().gui_get_hovered_control() != null
		var on_card := visible and is_instance_valid(_target) and get_global_rect().has_point(mouse)
		if on_card:
			pass  # On the card itself (its status chips): it keeps its nightmare
		elif hovered != null and not on_ui and not _await_move and _idle <= IDLE_TIME:
			_target = hovered
		else:
			_target = null
			if _idle > IDLE_TIME:
				_await_move = true  # Back on the next pointer move
	if not is_instance_valid(_target) or _target.is_cleansed:
		_target = null
		visible = false
		_set_hud_focus(null)
		return
	visible = true
	_set_hud_focus(_target)
	var data: EnemyData = _target.enemy_data
	var kind := _kind(data)
	_title.text = data.display_name + (" · New" if not _known.has(kind) else "")
	if _target.elite:
		_title.text += " · Deeply Blighted"
	if data != _portrait_for:
		_portrait_for = data
		_portrait.texture = portrait_of(data)
		_portrait.modulate = data.tint  # multiplier (the kind's own tint, as its sprite)
	var held := _target == _pinned  # Pinned by a click: a 2 px Gold ring outside the disc says so, no words
	if data != _disc_for or held != _disc_held:
		_disc_for = data
		_disc_held = held
		var disc := UiStyle.moon_disc(UiStyle.BOSS if data.is_boss else UiStyle.OFF)
		if held and not data.is_boss:  # On the dark panel around the pale disc: it reads on both sides
			disc.border_color = Palette.GOLD
			disc.set_border_width_all(2)
			disc.set_expand_margin_all(2.0)
		elif held:  # A boss keeps its BOSS rim, a Gold halo outside it
			disc.shadow_color = Color(Palette.GOLD, 0.6)  # multiplier (alpha)
			disc.shadow_size = 3
		_disc.add_theme_stylebox_override("panel", disc)
	# Numbers: one plain line under the name (no units the player doesn't need), then rarer extras.
	var numbers: Array[String] = ["Health %d / %d · Speed %.1f · Leaves %d" % [_target.health, _target.max_health,
		_target.get_move_speed() / 64.0, _target.get_leaf_cost()]]
	_last_data = data
	_last_max = int(_target.max_health)
	var restless := restless_text(_target)
	if restless != "":
		numbers.append(restless)
	# The Nightshade Legendary: effect damage ×2 with 3 statuses from 3 families (Reactions.nightshade_bonus).
	var nightshade := Reactions.nightshade_bonus(_target)
	if nightshade > 0.0:
		numbers.append("Nightshade ×%s effect damage" % str(snappedf(1.0 + nightshade, 0.01)))
	var numbers_text := "\n".join(numbers)
	if numbers_text != _numbers.text:
		_numbers.text = numbers_text
	_health_bar.queue_redraw()
	_update_chips()
	# Words only where an icon can't say it: the trait, the Omen, a Pall overhead, the limits ("Awake: …"), Silenced.
	var lines: Array[String] = []
	if data.trait_text != "":
		lines.append(data.trait_text)
	var omen_line := omen_text(_target)
	if omen_line != "":
		lines.append(omen_line)
	# A walker a Pall flies over (Enemy.covered_by; enemy_design.md "Flyers"): the Pall's rule shows on both cards
	var pall = _target.get("covered_by")
	if pall != null and is_instance_valid(pall):
		lines.append("Covered by a Pall: blows at it are shared half and half.")
	var notes: Array[String] = []
	if _target.has_method("get_status_notes"):  # Slow / sleep limits: "Slowed to the limit", "Awake: …"
		notes.append_array(_target.get_status_notes())
	if not notes.is_empty():
		lines.append("\n".join(notes))
	var body := StatusLinks.bbcode("\n".join(lines))
	if body != _body.text and not _body_in_use():
		_body.text = body
	_body.visible = body != ""
	if data != _rows_for:  # Its Kind badge and line (Nightmare Kinds: no Resists / Weak to rows), rebuilt per kind
		_rows_for = data
		for child in _rows_box.get_children():
			child.queue_free()
		var kind_row := NightmareIcons.kind_row(data, 22.0, UiStyle.TIP_SIZE)
		if kind_row != null:
			_rows_box.add_child(kind_row)
		_rows_box.visible = kind_row != null  # No empty row's gap at the card's foot
	if TouchBuild.mobile_controls():
		_fit_phone()

# The first frame of a kind's walk, cropped to its drawn pixels (a small nightmare fills the portrait, not a speck in its
# 64 px frame); null when it has no frames. Cached per kind on this panel (never a static Texture: exit crash).
var _portraits := {}
func portrait_of(data: EnemyData) -> Texture2D:
	if data == null or data.sprite_frames == null:
		return null
	if _portraits.has(data):
		return _portraits[data]
	var names := data.sprite_frames.get_animation_names()
	if names.is_empty() or data.sprite_frames.get_frame_count(names[0]) == 0:
		return null
	var frame := data.sprite_frames.get_frame_texture(names[0], 0)
	var image := frame.get_image() if frame != null else null
	var out: Texture2D = frame
	if image != null and not image.is_empty():
		var used := image.get_used_rect()
		if used.size.x > 0 and used.size.y > 0:
			var crop := image.get_region(used)
			var longest := maxf(used.size.x, used.size.y)
			var scale := maxi(1, floori(PORTRAIT / longest))  # Whole-number scale: crisp pixels
			var shrink := ceili(longest / PORTRAIT)  # A boss bigger than the disc: a whole-number fraction (1/2, 1/3)
			if scale > 1:
				crop.resize(used.size.x * scale, used.size.y * scale, Image.INTERPOLATE_NEAREST)
			elif shrink > 1:
				crop.resize(maxi(1, used.size.x / shrink), maxi(1, used.size.y / shrink), Image.INTERPOLATE_NEAREST)
			out = ImageTexture.create_from_image(crop)
	_portraits[data] = out
	return out

# The health bar: the in-world bar's look (Sprig on a Void track), the full width of the card.
func _draw_health() -> void:
	var r := Rect2(Vector2.ZERO, _health_bar.size)
	_health_bar.draw_rect(r, Color(Palette.VOID, 0.85))
	if not _pin_gone and _dispelled_left <= 0.0 and is_instance_valid(_target):  # (Dispelled: the empty track)
		var fill := r.grow(-1.0)
		fill.size.x *= clampf(float(_target.health) / maxf(float(_target.max_health), 1.0), 0.0, 1.0)
		if fill.size.x > 0.0:
			_health_bar.draw_rect(fill, Palette.SPRIG)
			_health_bar.draw_rect(Rect2(fill.position, Vector2(fill.size.x, 1.0)), Palette.NEWLEAF)  # Its lit top edge
	_health_bar.draw_rect(r.grow(-0.5), Palette.SLATE, false, 1.0)  # Its edge: the empty part reads as a bar, not a rule

# --- Status chips -----------------------------------------------------------------------------------------------
# Icons, not words (owner 2026-10-25): one chip per status in the badge row's order. A chip is its icon on a plate of
# the status colour, its stacks bottom right (when it can hold more than one) and a time bar along its foot. Locked
# (a Dream card's stacks that can't complete its Reaction yet, EnemyStatuses.is_fed) draws hollow, as the pips do: the
# colour only on its rim, a dark inside. Hover or tap a chip for its words under the row (phones have no hover).
var _chips_for: Node2D = null

func _update_chips() -> void:
	if _target != _chips_for:  # Another nightmare: its own chips, no held words, its own Silenced length
		_chips_for = _target
		_chip_key = ""
		_silence_full = 0.0
		_note_held = false
		_note_for = &""
	var order: Array = _target.get_status_order().duplicate()
	var silenced: float = _target.statuses.silence_time  # Hushbell (BranchKit): not a stacking status, its own timer
	if silenced > 0.0 and not order.has(SILENCED):
		order.append(SILENCED)  # A chip too (cap 1), its time bar from silence_time
	_silence_full = maxf(_silence_full, silenced) if silenced > 0.0 else 0.0
	var key := ""
	for id in order:
		key += "%s:%d:%d|" % [id, _target.statuses.stacks(id), int(_locked(id))]
	if key != _chip_key:
		_chip_key = key
		for child in _chips.get_children():
			_chips.remove_child(child)
			child.queue_free()
		for id in order:
			_chips.add_child(_make_chip(id))
	else:
		for chip in _chips.get_children():
			chip.queue_redraw()  # The time bars run down
	_chips.visible = not order.is_empty()
	if _note_for != &"" and not order.has(_note_for):
		_note_for = &""
	_show_note(_note_for)  # (Its stacks and seconds change: rewritten unless a link popup is open)

const SILENCED := &"silenced"

func _locked(id: StringName) -> bool:
	return id != SILENCED and _target.statuses.has_method(&"is_fed") and _target.statuses.is_fed(id)

func _chip_words(id: StringName) -> String:
	if id == SILENCED and not _target.statuses._active.has(SILENCED):
		return silence_line(_target.statuses.silence_time)
	var words: String = _target.statuses.describe(id)
	if _locked(id):
		words += "\n" + CodexData._fill_constants(HOLLOW_LINE).replace("{const:fed_lock}", String.num(EnemyStatuses.FED_LOCK))
	return words

const PHONE_CHIP := Vector2(44, 44)  # Phones: the chip's tap area (platforms.md); its plate stays CHIP_SIZE, centred

func _make_chip(id: StringName) -> Button:
	var chip := Button.new()
	chip.name = "Status_%s" % id
	chip.flat = true
	chip.focus_mode = Control.FOCUS_NONE
	chip.custom_minimum_size = PHONE_CHIP if TouchBuild.mobile_controls() else CHIP_SIZE
	chip.draw.connect(_draw_chip.bind(chip, id))
	chip.mouse_entered.connect(func() -> void: _show_note(id))
	chip.mouse_exited.connect(_chip_left)
	chip.pressed.connect(_chip_pressed.bind(id))
	return chip

# A press opens its words and keeps them (a second press on the same chip closes them); on PC hovered words close when
# the pointer leaves the chip, unless it was pressed.
func _chip_pressed(id: StringName) -> void:
	var closing := _note_for == id and _note_held
	_note_held = not closing
	_show_note(&"" if closing else id)

func _chip_left() -> void:
	if not _note_held and not TouchBuild.mobile_controls():
		_show_note(&"")

func _show_note(id: StringName) -> void:
	_note_for = id
	_chip_note.visible = id != &""
	if _chip_note.visible:
		var words := StatusLinks.bbcode(_chip_words(id))  # "Charge", "Reaction": glossary links, as the old lines were
		if words != _chip_note.text and not _note_in_use():
			_chip_note.text = words

func _note_in_use() -> bool:
	return _chip_note.get_children().any(func(c: Node) -> bool: return c is StatusLinks and c.visible)

# A chip: the status's pip colour (KeywordIcons.pip_color, as the row over the nightmare) on a Void plate. Normal: its
# colour filled (PLATE_ALPHA) inside a 1 px rim in its colour. Full (at its most): a 2 px Heartlight frame with a Void
# inner line; the number stays INK. The time bar sits in a dark 4 px slot above the foot. Locked (it can't set anything
# off yet): hollow, as the pips: no fill, the rim kept, the time bar a 1 px top row only. Stacks in INK on a Void outline
# (gold read badly on gold plates). Square, no lit top: the chip is the badge pip enlarged; a bright edge means full.
const PLATE_ALPHA := 0.45

func _draw_chip(chip: Button, id: StringName) -> void:
	if not is_instance_valid(_target):
		return
	var colour: Color = KeywordIcons.pip_color(id)
	var r := Rect2(((chip.size - CHIP_SIZE) / 2.0).floor(), CHIP_SIZE)  # Phones: the plate centred in the 44 px tap area
	var locked := _locked(id)
	var silence_only: bool = id == SILENCED and not _target.statuses._active.has(SILENCED)
	var cap: int = 1 if silence_only else _target.statuses.get_max_stacks(id)
	var stacks: int = 1 if silence_only else _target.statuses.stacks(id)
	var full_stacks := cap > 1 and stacks >= cap
	chip.draw_rect(r, Color(Palette.VOID, 0.9))
	if not locked:
		chip.draw_rect(r.grow(-1.0), Color(colour, PLATE_ALPHA))
	# The time bar in a dark slot (rows 29-32, clear of the full frame and the rim): one geometry for every chip.
	var full := _silence_full if silence_only else float((_target.statuses.get("_active") as Dictionary).get(id, {}).get("full", 0.0))
	var left: float = _target.statuses.silence_time if silence_only else _target.statuses.time_left(id)
	if full > 0.0:
		chip.draw_rect(Rect2(r.position + Vector2(3.0, r.size.y - 7.0), Vector2(r.size.x - 6.0, 4.0)), Color(Palette.VOID, 0.9))
		var w := floorf((r.size.x - 6.0) * clampf(left / full, 0.0, 1.0))
		var bar := Rect2(r.position + Vector2(3.0, r.size.y - 6.0), Vector2(w, 2.0))
		if locked:  # Hollow: its top row only
			chip.draw_rect(Rect2(bar.position, Vector2(w, 1.0)), colour)
		else:
			chip.draw_rect(bar, colour)
	if full_stacks:
		chip.draw_rect(r.grow(-1.0), Palette.HEARTLIGHT, false, 2.0)
		chip.draw_rect(r.grow(-2.5), Palette.VOID, false, 1.0)  # A dark line inside it: the frame reads on Glow and Gold plates too
	else:
		chip.draw_rect(r.grow(-0.5), colour, false, 1.0)
	var icon := IconInfo.icon(id)
	if icon != null:
		chip.draw_texture_rect(icon, Rect2(r.position + Vector2(floorf((r.size.x - 16.0) / 2.0), 3.0), Vector2(16, 16)), false)
	if cap > 1:
		var font := UiStyle.number_font()
		var text := str(stacks)
		var inset := 5.0 if full_stacks else 3.0  # (Clear of the full frame)
		var at := r.position + Vector2(r.size.x - inset - font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x, r.size.y - 8.0)
		chip.draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Palette.VOID)
		chip.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiStyle.INK)

# Under a status a Dream card just added (wording_council_review.md "Hollow stacks", 981a425a; the seconds from
# EnemyStatuses.FED_LOCK, never typed). Shown in the chip's words now (the chip itself draws hollow).
const HOLLOW_LINE := "Hollow: a Dream card added these stacks. No Reaction can trigger on this nightmare until they fill in ({const:fed_lock} s)."

# The pointer is on the status-link text, or one of its popups is open: don't rewrite it now.
func _body_in_use() -> bool:
	if _body.get_global_rect().has_point(_body.get_global_mouse_position()):
		return true
	return _body.get_children().any(func(c: Node) -> bool: return c is StatusLinks and c.visible)

# What the drift's Omen gives this nightmare beyond its kind (get_defences doesn't know them):
# "Omen Sleepless: immune to Drowsy, Rooted · always Soaked". "" when nothing.
# "Silenced · 1.4 s" (the status word links to its glossary entry through StatusLinks).
static func silence_line(seconds: float) -> String:
	return "%s · %.1f s" % [IconInfo.status_name(&"silenced"), seconds]

static func omen_text(enemy: Node) -> String:
	var parts: Array[String] = []
	var data: EnemyData = enemy.enemy_data
	var extra_immune: Array[String] = []
	for id in enemy.statuses.immune:
		if not data.status_immune.has(id):
			extra_immune.append(IconInfo.status_name(id))
	if not extra_immune.is_empty():
		parts.append("immune to " + ", ".join(extra_immune))
	var always: StringName = enemy.get("modifiers").get("always_status", &"") if enemy.get("modifiers") is Dictionary else &""
	if always != &"":
		parts.append("always has " + IconInfo.status_name(always))
	if parts.is_empty():
		return ""
	var omens := enemy.get_tree().get_first_node_in_group(OmenDirector.GROUP) as OmenDirector
	var omen: OmenData = omens.current() if omens != null and omens.has_method("current") else null
	return "%s: %s" % ["Omen " + omen.display_name if omen != null else "Omen", " · ".join(parts)]

# No maze juggling (run_design.md): "Restless ×2: +40% speed (Unbound at 3)" or "Unbound: ignores
# the maze, tramples Wardens on its route" (Enemy Code's get_restless_info); "" when calm.
static func restless_text(enemy: Node) -> String:
	if not enemy.has_method("get_restless_info"):
		return ""
	var info: Dictionary = enemy.get_restless_info()
	if info.get("unbound", false):
		return "Unbound: ignores the maze, tramples Wardens on its path"
	var stacks := int(info.get("stacks", 0))
	if stacks <= 0:
		return ""
	var text := "Restless ×%d: +%d%% speed" % [stacks, roundi(float(info.get("speed_bonus", 0.0)) * 100.0)]
	if info.get("can_unbind", true):
		text += " (Unbound at %d)" % int(info.get("unbound_at", 3))
	return text

# Phones (user 2026-10-18): no hover. A tap on a nightmare opens its card and the card follows it; a tap anywhere else
# closes it; while building, selling or selecting a tap never opens it (the tool takes the tap).
# PC (owner 2026-10-25 "stays on click"): a left click on a nightmare pins it, a click elsewhere on the map lets go; the
# click is never consumed (selecting a Warden still works). A release more than CLICK_SLOP from its press is a drag.
const PHONE_TAP_RADIUS := 44.0  # A fingertip, in world px
const CLICK_SLOP := 6.0  # Screen px
var _phone_pick: Node2D = null
var _press_at := Vector2.INF

func _input(event: InputEvent) -> void:
	if not TouchBuild.mobile_controls():
		if _has_pin and event.is_action_pressed(&"cancel_build"):
			_set_pin(null)  # Esc / right click let go first (consumed: the next one clears the Warden selection)
			get_viewport().set_input_as_handled()
			return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_press_at = (event as InputEventMouseButton).position
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if (event as InputEventMouseButton).position.distance_to(_press_at) > CLICK_SLOP:
				return  # A drag (a camera pan), not a click
			if visible and get_global_rect().has_point((event as InputEventMouseButton).position):
				return  # A click on the card itself (its portrait, bar, a gap between chips)
			if _tool_active():
				_set_pin(null)  # Building, selling or selecting: the tool takes the click and the pin lets go
				return
			if RestScreens.map_blocked(self):
				return  # A screen covers the map (64c30f7f): its clicks aren't the map's
			if get_viewport().gui_get_hovered_control() != null:
				return  # A click on the HUD
			var world: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * (event as InputEventMouseButton).position
			var seller := owner.get_node_or_null("%TowerSeller") if owner != null else null
			if seller != null and seller.get_tower_at_point(world) != null:
				_set_pin(null)  # A click on a Warden selects only the Warden (owner 2026-10-25), never a nightmare beside it
				return
			_set_pin(_nightmare_near(world, HOVER_RADIUS))
		return
	if not (event is InputEventScreenTouch) or event.pressed:
		return
	if TouchBuild.gesture_moved() or (visible and get_global_rect().has_point(event.position)):
		return  # A pan or pinch; or a tap on the card's own words
	if _tool_active():
		_phone_pick = null
		return
	var world: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * (event as InputEventScreenTouch).position
	_phone_pick = _cycle_pick(world)

func _drawer_open() -> bool:
	var drawer := get_parent().get_node_or_null("WardenPanel") as Control if get_parent() != null else null
	return drawer != null and drawer.visible

# Phones (owner 2026-10-26: "can't read the pinned nightmare", its foot sat under Start drift and the speed buttons): the
# card ends above the drift panel, moving up from its scene place as far as PHONE_TOP_MIN (under the top-right buttons).
const PHONE_TOP_MIN := 72.0
const PHONE_GAP := 8.0
var _scene_top := NAN

func _fit_phone() -> void:
	if is_nan(_scene_top):
		_scene_top = offset_top
	var panel := get_parent().get_node_or_null("DriftPanel") as Control
	var bottom := get_parent_area_size().y - PHONE_GAP
	if panel != null and panel.is_visible_in_tree():
		bottom = minf(bottom, panel.get_rect().position.y - PHONE_GAP)
	var height := get_combined_minimum_size().y
	var top := clampf(bottom - height, PHONE_TOP_MIN, _scene_top)
	if not is_equal_approx(top, offset_top):
		offset_top = top
		offset_bottom = top + height

func _tool_active() -> bool:
	var main := owner
	if main == null:
		return false
	var placer := main.get_node_or_null("%TowerPlacer")
	var seller := main.get_node_or_null("%TowerSeller")
	return (placer != null and bool(placer.get("build_mode"))) or (seller != null and (bool(seller.get("sell_mode")) \
		or bool(seller.get("select_mode"))))

# Phones in a crowd (UI council round 8, item 5): a tap picks the nightmare nearest the finger by its drawn body; tapping
# the same crowd again steps to the next one under the finger, nearest first, then round again.
const CYCLE_RADIUS := 28.0  # World px: a second tap this close to the first stays in the same crowd
var _cycle_at := Vector2.INF

func _cycle_pick(world: Vector2) -> Node2D:
	var under: Array = []
	for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
		var body: Vector2 = enemy.get_body_position() if enemy.has_method("get_body_position") else enemy.global_position
		var distance := body.distance_to(world)
		if distance < PHONE_TAP_RADIUS:
			under.append([distance, enemy])
	under.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var same_crowd := _cycle_at.is_finite() and world.distance_to(_cycle_at) <= CYCLE_RADIUS
	_cycle_at = world
	if under.is_empty():
		return null
	if same_crowd and is_instance_valid(_phone_pick):
		for i in under.size():
			if under[i][1] == _phone_pick:
				return under[(i + 1) % under.size()][1]  # The next one in the crowd
	return under[0][1]

func _nightmare_near(world: Vector2, radius: float) -> Node2D:
	var best: Node2D = null
	var best_distance := radius
	for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
		var distance: float = enemy.global_position.distance_to(world)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best

func _hovered_nightmare() -> Node2D:
	if RestScreens.map_blocked(self):
		return null  # Under a choice screen nothing on the map is hovered (peeking: it is)
	if TouchBuild.mobile_controls():
		if _drawer_open():
			_phone_pick = null  # Phones (owner 2026-10-26: "Warden drawer should remove the pinned nightmare"): both sit on the right
		if _tool_active() or not is_instance_valid(_phone_pick) or _phone_pick.is_cleansed:
			return null
		return _phone_pick
	var mouse: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
	var best: Node2D = null
	var best_distance := HOVER_RADIUS
	for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
		var distance: float = enemy.global_position.distance_to(mouse)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best

func _on_spawned(node: Node) -> void:
	if node.get("enemy_data") == null:
		return
	var kind := _kind(node.enemy_data)
	if _saved.has(kind):
		return
	_saved[kind] = true
	# Remember the kind for future runs (this run keeps showing "New" for it). Real game only, dev runs
	# included (screens_ui.md playtest fixes: "New" = never seen on this profile, dev runs alike).
	if get_tree().current_scene != owner:
		return
	var memory := HeartwoodMemory.load_data()
	var seen: Array = memory.get("nightmares_seen", [])
	if not seen.has(kind):
		seen.append(kind)
		memory["nightmares_seen"] = seen
		HeartwoodMemory.save_data(memory)

static func _kind(data: EnemyData) -> String:
	return data.resource_path.get_file().get_basename()

# The hovered / tapped nightmare keeps its full status row in a crowd, and is the only row under "Status icons: Off"
# (Enemy Code 0fd6b2fb: EnemySpawner.hud_focus). Written only when it changes.
func _set_hud_focus(enemy: Node2D) -> void:
	var spawner := get_node_or_null("%EnemyContainer")
	if spawner != null and "hud_focus" in spawner and spawner.hud_focus != enemy:
		spawner.hud_focus = enemy
