extends SceneTree

# Saves the Moonlit Thread project theme (UiStyle.make_theme, documentation/ui_style.md) to
# assets/ui/ui_theme.tres, the project's gui/theme/custom. Re-run it after changing UiStyle:
#   godot --headless --path . --script res://tools/ui_theme_generator.gd

func _initialize() -> void:
	var theme := UiStyle.make_theme()
	var error := ResourceSaver.save(theme, UiStyle.THEME_PATH)
	print("Saved %s (error %d)" % [UiStyle.THEME_PATH, error])
	quit(error)
