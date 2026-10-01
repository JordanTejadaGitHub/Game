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
