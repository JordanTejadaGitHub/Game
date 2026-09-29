extends SceneTree

# The Moonlit Thread UI style (documentation/ui_style.md): every UiStyle colour token is its
# Heartwood 32 palette colour (UiStyle.PALETTE_NAMES / RARITY_NAMES), and the saved project theme
# is the one UiStyle builds today (re-run tools/ui_theme_generator.gd if this fails).
#   godot --headless --path . --script res://tests/test_ui_style.gd

var failures := 0

func _initialize() -> void:
	for token: String in UiStyle.PALETTE_NAMES:
		var value := _token(token)
		var palette := HeartwoodPalette.color(UiStyle.PALETTE_NAMES[token])
		_check(value.is_equal_approx(palette), "UiStyle.%s is Heartwood %s (%s vs %s)" % [token,
			UiStyle.PALETTE_NAMES[token], value.to_html(false), palette.to_html(false)])
	for i in UiStyle.RARITY.size():
		var palette := HeartwoodPalette.color(UiStyle.RARITY_NAMES[i])
		_check(UiStyle.rarity_color(i).is_equal_approx(palette), "rarity %d is Heartwood %s" % [i, UiStyle.RARITY_NAMES[i]])
	# The saved theme matches make_theme() (a few spot checks).
	var saved: Theme = load(UiStyle.THEME_PATH)
	_check(saved != null and ProjectSettings.get_setting("gui/theme/custom") == UiStyle.THEME_PATH,
		"the project theme is %s" % UiStyle.THEME_PATH)
	if saved != null:
		_check(saved.get_color("font_color", "Label").is_equal_approx(UiStyle.INK), "the saved theme's text colour is INK (re-run the generator?)")
		_check(saved.get_color("font_color", "PrimaryButton").is_equal_approx(UiStyle.GOLD_TEXT), "primary buttons use GOLD_TEXT")
		var panel := saved.get_stylebox("panel", "PanelContainer") as MoonStyleBox
		_check(panel != null and panel.fog_color.is_equal_approx(UiStyle.FOG), "panels are MoonStyleBoxes in FOG")
		var button := saved.get_stylebox("normal", "Button") as StyleBoxFlat
		_check(button != null and Color(button.border_color, 1.0).is_equal_approx(UiStyle.BUTTON_GOLD),
			"button outlines are BUTTON_GOLD")
	print("ui style test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

static func _token(name: String) -> Color:
	return {"INK": UiStyle.INK, "INK_DIM": UiStyle.INK_DIM, "GOLD": UiStyle.GOLD, "BUTTON_GOLD": UiStyle.BUTTON_GOLD,
		"GOLD_TEXT": UiStyle.GOLD_TEXT, "WHISPER": UiStyle.WHISPER, "POOR": UiStyle.POOR, "FOG": UiStyle.FOG,
		"CARD_BG": UiStyle.CARD_BG, "BOSS": UiStyle.BOSS, "LIVE": UiStyle.LIVE, "OFF": UiStyle.OFF, "MOONLIGHT": UiStyle.MOONLIGHT, "MOON_MIST": UiStyle.MOON_MIST}[name]

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)
