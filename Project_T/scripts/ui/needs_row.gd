extends RefCounted
class_name NeedsRow

# "Needs Whirligig" (no emblem): what a half-dreamed or sleeping Dream card still needs, by family (damage types went
# with Nightmare Kinds, enemy_design.md ed6f573b); the word is a link to the family's popup and its tooltip names a
# specific form ("Samara, a Whirligig Warden"). The Dream card and "Dreams this run" both use it, so they match.
#   var row := NeedsRow.make(dream_state.missing_needs(card), 12, UiStyle.INK_DIM)

# A need's family name ("Whirligig"), from its family id.
static func family_word(need: Dictionary) -> String:
	var data := IconInfo.family_data(String(need.get("family", "")))
	return data.display_name if data != null else String(need.get("family", "")).capitalize()

# "Needs Whirligig and Dewdrop" as plain text ("" when nothing is missing).
static func text(needs: Array) -> String:
	return "" if needs.is_empty() else "Needs " + " and ".join(needs.map(func(n: Dictionary) -> String: return family_word(n)))

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
		var word := family_word(need)
		link.text = StatusLinks._link(StatusLinks.FAMILY_PREFIX + need.family, word)
		link.autowrap_mode = TextServer.AUTOWRAP_OFF
		link.mouse_filter = Control.MOUSE_FILTER_PASS
		if need.form != "":
			link.tooltip_text = "%s, a %s Warden" % [need.form, word]
		row.add_child(link)
	return row

static func _word(text: String, font_size: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", colour)
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
