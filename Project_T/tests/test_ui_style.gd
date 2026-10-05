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
		_check(saved.get_color("font_color", "PrimaryButton").is_equal_approx(UiStyle.GOLD), "primary buttons speak in Glow text")
		var primary := saved.get_stylebox("normal", "PrimaryButton") as MoonStyleBox
		_check(primary != null and primary.frame_color.a > 0.5 and primary.thread == MoonStyleBox.TopLine.GOLD and primary.diamond
			and primary.glow_color.is_equal_approx(UiStyle.PRIMARY_GLOW), "the primary is a gold frame + thread + mark with an Ember glow, not a fill")
		var panel := saved.get_stylebox("panel", "PanelContainer") as MoonStyleBox
		_check(panel != null and panel.fog_color.is_equal_approx(UiStyle.FOG), "panels are MoonStyleBoxes in FOG")
		var button := saved.get_stylebox("normal", "Button") as StyleBoxFlat
		_check(button != null and Color(button.border_color, 1.0).is_equal_approx(UiStyle.BUTTON_GOLD),
			"button outlines are BUTTON_GOLD")
	# Dream glyphs (UI Asset's dream_glyphs.json): first priority id a tag maps to, else the fallback.
	var tagged := UpgradeData.new()
	tagged.tags = ["swift", "bittersweet"]
	_check(UiStyle.dream_glyph(tagged) == &"bittersweet", "a card's glyph is the highest-priority tag (%s)" % UiStyle.dream_glyph(tagged))
	_check(UiStyle.dream_glyph(UpgradeData.new()) == &"generic", "an untagged card gets the fallback glyph")
	_check(UiStyle.dream_glyph_texture(&"spore") != null, "the glyph sheet has a spore cell")
	# Tips anchor to their control: centred above, flipped below at the top, clamped at the sides.
	var above := UiStyle.tip_beside(Rect2(600, 400, 32, 32), Vector2(200, 60), Vector2(1280, 800))
	var below := UiStyle.tip_beside(Rect2(600, 10, 32, 32), Vector2(200, 60), Vector2(1280, 800))
	var edge := UiStyle.tip_beside(Rect2(1250, 400, 24, 24), Vector2(200, 60), Vector2(1280, 800))
	_check(above == Vector2(516, 332) and below.y == 50.0 and edge.x + 200.0 <= 1276.0,
		"tips sit centred above their control, flip below, stay on screen (%s, %s, %s)" % [above, below, edge])
	# Even letter spacing at fractional UI scales (2026-10-01: "B l oom i ng"): every UI font imports with
	# subpixel positioning off, so oversampled glyphs land on whole pixels.
	for file in ["AlegreyaSans-Regular.ttf", "AlegreyaSans-Medium.ttf", "CormorantGaramond-Variable.ttf",
			"CormorantGaramond-Italic-Variable.ttf", "CormorantSC-Medium.ttf"]:
		var font: FontFile = load(UiStyle.FONT_DIR + file)
		_check(font != null and font.subpixel_positioning == TextServer.SUBPIXEL_POSITIONING_DISABLED,
			"%s imports with subpixel positioning off" % file)
	# Word gaps stay visible at fractional UI scales (2026-10-02: "Asmall splash"): every UI face adds
	# SPACE_EXTRA to the space advance.
	for face: Font in [UiStyle.body_font(), UiStyle.body_medium_font(), UiStyle.display_font(), UiStyle.number_font(),
			UiStyle.caps_font(), UiStyle.whisper_font()]:
		_check(face is FontVariation and (face as FontVariation).spacing_space >= UiStyle.SPACE_EXTRA,
			"%s adds space width" % face)
	var saved_default: Theme = load(UiStyle.THEME_PATH)
	_check(saved_default.default_font is FontVariation and (saved_default.default_font as FontVariation).spacing_space >= 1,
		"the saved theme's default font has the extra space (re-run the generator?)")
	# Every glyph id has a non-empty cell inside the sheet (a blank region drew a white square).
	var sheet: Texture2D = load(UiStyle.DREAM_GLYPHS + ".png")
	var glyph_ids: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(UiStyle.DREAM_GLYPHS + ".json")).icons
	for id in glyph_ids:
		var region := UiStyle.dream_glyph_region(StringName(id))
		_check(region.has_area() and Rect2(Vector2.ZERO, sheet.get_size()).encloses(region), "glyph %s has a cell in the sheet (%s)" % [id, region])
	# Feeling the cards: the credit line keeps names Ink and numbers Gold, escaping brackets.
	var credit := UiStyle.credit_bbcode("Dreams this block", [["Lingering Spores", "+1,840"], ["Odd [card]", "+9"]])
	_check(credit.contains(UiStyle.GOLD.to_html(false)) and credit.contains("Odd [lb]card]") and credit.count(" · ") + credit.count("·[/color]") >= 1,
		"credit_bbcode builds the Dreams-this-block line (%s)" % credit)
	_scale_and_layout.call_deferred()

# UI scale (UiStyle.apply_ui_scale): only the UI scales, never past its 1280×720 layout, and the
# camera keeps the map its size. Then the top-right row fits at 1280×720.
func _scale_and_layout() -> void:
	_check(is_equal_approx(UiStyle.ui_scale_factor(Vector2(1920, 1080), 1.0), 1.5), "1920×1080 fits the UI at 1.5×")
	_check(is_equal_approx(UiStyle.ui_scale_factor(Vector2(1280, 800), 1.0), 1.0), "1280×800 (Steam Deck) stays 1×")
	_check(is_equal_approx(UiStyle.ui_scale_factor(Vector2(3840, 2160), 0.5), 1.5), "4K at 50% is 1.5×")
	_check(is_equal_approx(UiStyle.ui_scale_factor(Vector2(1920, 1080), 2.0), 1.5), "an old 2.0 setting can't scale past the fit")
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	root.size = Vector2i(1280, 720)
	for i in 5:
		await process_frame
	var camera = main.get_node("GameCameraNode")
	var before: Vector2 = camera.camera_2d.zoom
	root.content_scale_factor = 2.0
	for i in 30:
		await process_frame
	_check(camera.camera_2d.zoom.is_equal_approx(before / 2.0), "at a 2× UI the camera halves its zoom, so the map keeps its size (%s → %s)" % [before, camera.camera_2d.zoom])
	root.content_scale_factor = 1.0
	for i in 30:
		await process_frame
	var hud := main.get_node("HUD")
	# Text draws linear, pixel art stays Nearest (strokes dropped at fractional scales, 2026-10-02).
	UiStyle.install_text_filter(self)
	_check((main.get_node("%DewLabel") as CanvasItem).texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "HUD text draws with a linear filter")
	var slot := main.get_node("%TowerBar").get_child(0) as CanvasItem
	_check(slot.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "a Warden slot (pixel sprite) keeps Nearest")
	var avoid: Array[Control] = [main.get_node("%DriftBanner"), main.get_node("%DewLabel"), main.get_node("%LeavesLabel"),
		main.get_node("%PathLabel"), hud.get_node("DreamlightLabel"), main.get_node("HUD/NightmareInfo")]
	for child in hud.get_children():
		if child is ComingStrip:
			avoid.append(child)
	for name in ["CodexButton", "BuffLensButton", "RememberButton", "MenuButton"]:
		var button := hud.get_node(name) as Control
		var rect := button.get_global_rect()
		_check(rect.size.y >= 48.0 and rect.end.x <= 1280.0, "%s is touch-sized and on screen (%s)" % [name, rect])
		for other in avoid:
			var other_rect := _drawn_rect(other)
			_check(not rect.intersects(other_rect), "%s clears %s at 1280×720 (%s vs %s)" % [name, other.name, rect, other_rect])
	print("ui style test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

# The banner draws its text centred in its own rect; labels are only as wide as their text.
static func _drawn_rect(control: Control) -> Rect2:
	var rect := control.get_global_rect()
	if control is Label:
		var label := control as Label
		var width := label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			label.get_theme_font_size("font_size")).x
		if label.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
			rect = Rect2(rect.end.x - width, rect.position.y, width, rect.size.y)
	return rect

static func _token(name: String) -> Color:
	return {"INK": UiStyle.INK, "INK_DIM": UiStyle.INK_DIM, "GOLD": UiStyle.GOLD, "BUTTON_GOLD": UiStyle.BUTTON_GOLD,
		"GOLD_TEXT": UiStyle.GOLD_TEXT, "WHISPER": UiStyle.WHISPER, "POOR": UiStyle.POOR, "FOG": UiStyle.FOG,
		"CARD_BG": UiStyle.CARD_BG, "BOSS": UiStyle.BOSS, "LIVE": UiStyle.LIVE, "OFF": UiStyle.OFF, "MOONLIGHT": UiStyle.MOONLIGHT, "MOON_MIST": UiStyle.MOON_MIST}[name]

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)
