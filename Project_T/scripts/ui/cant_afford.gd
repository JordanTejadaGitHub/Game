class_name CantAfford

# One can't-afford style for every buy button (user via the story chat, 2026-10-01): the same frame, the label dimmed
# (INK_DIM) and only the missing amount in POOR ("Unlock · 2 Dreamlight · 2 more needed"); its hover / tap says how
# to get there. Pressing it refuses out loud: the button shakes, a toast explains, the resource counter flashes.
# The button stays enabled so the press can explain (never a silent dead button). `clear` puts the normal look back
# the moment it's affordable. Static helpers; Remember screen now, the Warden panel can share them.

const TEXT_NODE := "CantAffordText"

# Dims `button` to "<label> · <missing>" with only `missing` in POOR, and sets its tooltip.
static func apply(button: Button, label: String, missing: String, tip: String) -> void:
	button.text = ""
	button.tooltip_text = tip
	var rich := button.get_node_or_null(TEXT_NODE) as RichTextLabel
	if rich == null:
		rich = RichTextLabel.new()
		rich.name = TEXT_NODE
		rich.bbcode_enabled = true
		rich.fit_content = true
		rich.scroll_active = false
		rich.autowrap_mode = TextServer.AUTOWRAP_OFF
		rich.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rich.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rich.add_theme_font_size_override("normal_font_size", button.get_theme_font_size("font_size"))
		button.add_child(rich)
	rich.text = "[center][color=#%s]%s · [/color][color=#%s]%s[/color][/center]" % [
		UiStyle.INK_DIM.to_html(false), label, UiStyle.POOR.to_html(false), missing]
	button.set_meta(&"cant_afford", true)
	# Centre the text vertically once it's laid out
	rich.resized.connect(func() -> void: rich.offset_top = (button.size.y - rich.size.y) / 2.0, CONNECT_ONE_SHOT)

# The normal look again (affordable): `text` back on the button itself.
static func clear(button: Button, text: String, tip: String = "") -> void:
	var rich := button.get_node_or_null(TEXT_NODE)
	if rich != null:
		rich.queue_free()
	button.text = text
	button.tooltip_text = tip
	button.set_meta(&"cant_afford", false)

static func is_shown(button: Button) -> bool:
	return bool(button.get_meta(&"cant_afford", false))

# The refusal: a short shake of `control` (no motion under reduced motion).
static func shake(control: Control) -> void:
	if not is_instance_valid(control) or bool(Fx.setting("reduced_motion", false)):
		return
	var home := control.position
	var tween := control.create_tween()
	for offset in [-6.0, 6.0, -4.0, 4.0, 0.0]:
		tween.tween_property(control, "position", home + Vector2(offset, 0), 0.04)

# Flashes a resource counter (a Label) in POOR with a small wobble, then back to `normal` colour.
static func flash_counter(label: Label, normal: Color) -> void:
	if not is_instance_valid(label):
		return
	label.pivot_offset = label.size / 2
	label.add_theme_color_override("font_color", UiStyle.POOR)
	var tween := label.create_tween()
	if not bool(Fx.setting("reduced_motion", false)):
		for offset in [-3.0, 3.0, -2.0, 2.0, 0.0]:
			tween.tween_property(label, "rotation_degrees", offset, 0.04)
	tween.tween_interval(0.25)
	tween.tween_callback(label.add_theme_color_override.bind("font_color", normal))
