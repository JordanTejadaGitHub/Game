extends PanelContainer
class_name CodexPanel

# The Reaction Codex (screens_ui.md "Reactions"): every Reaction, discovered ones with their name,
# status pair and description, undiscovered ones as silhouettes. Reached from the pause menu and the
# Memory Grove. Discoveries come from the profile's `reactions_seen` (ReactionFeedback). Built in code.

const SILHOUETTE := Color(0.45, 0.47, 0.5)

var _list := VBoxContainer.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.custom_minimum_size = Vector2(440, 0)
	add_child(box)
	var title := Label.new()
	title.text = "Codex: Reactions"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	box.add_child(_list)
	var close := Button.new()
	close.text = "Close"
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 48)
	close.pressed.connect(func() -> void: visible = false)
	box.add_child(close)

func open() -> void:
	for child in _list.get_children():
		child.queue_free()
	var seen: Array = HeartwoodMemory.load_data().get(ReactionFeedback.SETTING, [])
	var found := 0
	for data in Reactions.all():
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if seen.has(String(data.id)):
			found += 1
			label.text = "%s  (%s)\n%s" % [data.display_name, ReactionFeedback.pair_text(data), data.description]
			label.add_theme_color_override("font_color", data.callout_color)
		else:
			label.text = "? ? ?  (? + ?)\nNot discovered yet."
			label.add_theme_color_override("font_color", SILHOUETTE)
		_list.add_child(label)
	var count := Label.new()
	count.text = "%d / %d discovered" % [found, Reactions.all().size()]
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_list.add_child(count)
	visible = true
