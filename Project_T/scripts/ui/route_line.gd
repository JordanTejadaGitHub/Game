extends RefCounted
class_name RouteLine

# The route previews (building, clearing) follow the "High-contrast route line" accessibility setting
# (screens_ui.md "Settings"): thicker, opaque and bright instead of the soft translucent line.
# The setting is cached (previews restyle often); SettingsPanel calls reload() when it changes.

const SETTING := "high_contrast_route"
const CONTRAST_COLOR := Color(1.0, 0.92, 0.2)
const CONTRAST_WIDTH := 10.0

static var _high := -1  # -1 = not read yet, 0 / 1

static func reload() -> void:
	_high = 1 if bool(HeartwoodMemory.get_settings().get(SETTING, false)) else 0

static func is_high_contrast() -> bool:
	if _high < 0:
		reload()
	return _high == 1

# Styles `line` for the current setting; `normal_color` / `normal_width` are its usual look.
static func apply(line: Line2D, normal_color: Color, normal_width: float = 6.0) -> void:
	var high := is_high_contrast()
	line.default_color = CONTRAST_COLOR if high else normal_color
	line.width = CONTRAST_WIDTH if high else normal_width
