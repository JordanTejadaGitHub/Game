class_name ChoiceCard

# Choice cards (the Dream and Omen screens) hide what's behind them (user screenshot 2026-10-01: a HUD / banner label
# bled through an Omen card's title). The Moonlit card's fog is see-through on purpose elsewhere; on a choice card
# it's made near-opaque, per card, without touching the shared UiStyle look. Starlit card backs thin their own fog
# again afterwards (their night-sky frame is opaque).

const EDGE_ALPHA := 0.94
const CENTER_ALPHA := 0.97

static func solid(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var style := button.get_theme_stylebox(state) as MoonStyleBox
		if style == null:
			continue
		style = style.duplicate()  # Only this card
		style.edge_alpha = EDGE_ALPHA
		style.center_alpha = CENTER_ALPHA
		button.add_theme_stylebox_override(state, style)

# A card's drawn action (Wake …, Plant it, Take this Omen) answers the pointer like a real button (user, 2026-10-05:
# "buttons don't really do anything here"): the whole card takes the press, so the cue copies the card's state each
# time the card redraws: lit while the card is hovered, pressed while it's held. Call it on the cue before it's in the
# tree; it finds its card (the nearest Button above it) when it enters.
static func link_cue(cue: Button) -> void:
	cue.tree_entered.connect(func() -> void:
		var card := cue.get_parent()
		while card != null and not card is Button:
			card = card.get_parent()
		if card == null:
			return
		var looks := {}  # The cue's own normal / hover / pressed look, read once it has its theme
		(card as Button).draw.connect(func() -> void:
			if not is_instance_valid(cue):
				return
			if looks.is_empty():
				for state in ["normal", "hover", "pressed"]:
					looks[state] = cue.get_theme_stylebox(state)
				looks["normal_font"] = cue.get_theme_color("font_color")
				looks["hover_font"] = cue.get_theme_color("font_hover_color")
				looks["pressed_font"] = cue.get_theme_color("font_pressed_color")
			var mode := (card as Button).get_draw_mode()
			var state := "normal"
			if mode == BaseButton.DRAW_PRESSED or mode == BaseButton.DRAW_HOVER_PRESSED:
				state = "pressed"
			elif mode == BaseButton.DRAW_HOVER:
				state = "hover"
			cue.add_theme_stylebox_override("normal", looks[state])
			cue.add_theme_color_override("font_color", looks[state + "_font"])), CONNECT_ONE_SHOT)

# A destructive action (Abandon, Reset profile; ui_style.md button rule): the plain frame in POOR, lettered POOR, never the
# primary; the caller sets it apart (a divider, a smaller size).
static func danger(button: Button) -> void:
	for state in ["normal", "hover", "pressed"]:
		var box := button.get_theme_stylebox(state)
		if box is MoonStyleBox:
			box = (box as MoonStyleBox).duplicate()
			(box as MoonStyleBox).frame_color = Color(UiStyle.POOR, 0.85 if state == "normal" else 1.0)
			button.add_theme_stylebox_override(state, box)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, UiStyle.POOR)
