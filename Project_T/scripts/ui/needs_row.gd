extends RefCounted
class_name NeedsRow

# "Needs Wind" (dream_design.md "Named by damage type"; no emblem): what a half-dreamed or sleeping
# Dream card still needs, by damage type; the word is a link to the family's
# popup and its tooltip names a specific form ("Samara, a Wind Warden"). The Dream card and "Dreams
# this run" both use it, so they match.
#   var row := NeedsRow.make(dream_state.missing_needs(card), 12, UiStyle.INK_DIM)

# `needs` = DreamState.missing_needs(card); null when it's empty.
static func make(needs: Array, font_size: int, colour: Color) -> HBoxContainer:
	if needs.is_empty():
		return null
	var row := HBoxContainer.new()
	row.name = "MissingRow"
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_theme_constant_override("separation", 4)
	row.add_child(_word("Needs", font_size, colour))
	for i in needs.size():
		var need: Dictionary = needs[i]
		if i > 0:
			row.add_child(_word("and", font_size, colour))
		var link := StatusLinks.make_label("", font_size, colour)
		link.text = StatusLinks._link(StatusLinks.FAMILY_PREFIX + need.family, need.type)
		link.autowrap_mode = TextServer.AUTOWRAP_OFF
		link.mouse_filter = Control.MOUSE_FILTER_PASS
		if need.form != "":
			link.tooltip_text = "%s, a %s Warden" % [need.form, need.type]
		row.add_child(link)
	return row

static func _word(text: String, font_size: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", colour)
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
