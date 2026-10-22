extends MarginContainer
class_name KeywordRow

# A row of keyword chips (keyword chips 2026-10-16: Roguelite Code's DreamState.KEYWORDS gives [{id, kind, label}],
# uses first; UI Code's UiStyle.chip draws each). The chips wrap; the whole row is one tap target (48 px tall on phones,
# Mobile UI), and a tap or hover shows the glossary line of each keyword in it, nothing else (owner rule: never a list of
# the player's own cards). Made by make(); null when there are no chips. Used on Dream cards, the Calling offer,
# "Dreams this run", the Warden header (panel, bar hover card, Codex) and the build ghost's card.

const PHONE_ROW_H := 48.0
const PHONE_ICON := 20

# Every row is the quiet chip (screens_ui.md 844fa70a: outlined, dim word, never a filled gold tag): `outline` is the
# frame colour (a card's rarity; GOLD by default), on one line for up to two chips, `font_size` the word.
static func make(chips: Array, icon_size: int = 0, outline: Color = UiStyle.GOLD, font_size: int = 12) -> KeywordRow:
	if chips.is_empty():
		return null
	var row := KeywordRow.new()
	row.name = "KeywordRow"
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	var phone := UiStyle.is_phone()
	if phone:
		row.custom_minimum_size.y = PHONE_ROW_H
	# Always a wrapping row: two short chips still share a line, two long ones wrap (user 2026-10-22: "Clusters" +
	# "Mixed statuses" ran off the right of a Calling card; it was a one-line row for any two chips)
	var flow := HFlowContainer.new()
	flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 3)
	row.add_child(flow)
	var size := icon_size if icon_size > 0 else (PHONE_ICON if phone else UiStyle.CHIP_ICON)
	var lines: Array[String] = []
	for chip in chips:
		var id := StringName(chip.get("id", &""))
		if id == &"":
			continue
		var label := String(chip.get("label", ""))
		flow.add_child(UiStyle.chip(id, StringName(chip.get("kind", &"makes")), label, size, font_size, outline))
		var entry: Dictionary = DreamState.KEYWORDS.glossary(id)
		var line := "%s: %s" % [entry.get("name", label), entry.get("text", "")] if String(entry.get("text", "")) != "" else ""
		if line == "" and String(chip.get("tip", "")) != "":
			line = String(chip.tip)  # A chip that isn't a glossary word (a Warden's attack shape) brings its own tip
		if line != "" and not lines.has(line):
			lines.append(line)
	if not lines.is_empty():
		TapTip.attach(row, IconInfo.format("\n".join(lines)))
	return row
