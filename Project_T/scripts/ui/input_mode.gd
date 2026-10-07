class_name InputMode
extends RefCounted

# Mouse & keyboard or touch (user 2026-10-07: "on PC, hints shouldn't mention touch, and on mobile they shouldn't
# mention Esc or other keys"). One switch for every hint, Lesson, tooltip and Codex line that names a control: each
# such text comes in two variants through text(pc, touch), never both in one string; keys are named from the live
# bindings (key()). Auto = touch on phones / tablets (TouchBuild.mobile_controls()) or while a touchscreen is driving a
# PC (TouchBuild's live touch state); Settings > Controls > "Controls" overrides it.

const SETTING := "input_mode"  # -1 Auto, 0 Mouse & keyboard, 1 Touch
static var force := -2  # Tests: -2 = the setting; else as the setting

static func touch() -> bool:
	var mode := force if force != -2 else int(Fx.setting(SETTING, -1))
	if mode == 0:
		return false
	if mode == 1:
		return true
	return TouchBuild.mobile_controls() or TouchBuild._touch

# The variant for the current controls: `pc` names keys and clicks, `on_touch` names taps and buttons.
static func text(pc: String, on_touch: String) -> String:
	return on_touch if touch() else pc

# The key bound to `action` on PC ("Esc", "Q", "Space"), or `fallback` when none is bound.
static func key(action: StringName, fallback := "") -> String:
	if not InputMap.has_action(action):
		return fallback
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var code: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
			return "Esc" if code == KEY_ESCAPE else OS.get_keycode_string(code)
	return fallback

# Words that only make sense with a mouse or keyboard (a touch variant must not use them), and the reverse.
const PC_WORDS := ["Esc", "Right-click", "right-click", "click", "Click", "hover", "Hover", "Shift", "Ctrl", "Space",
	"Enter", "Delete", "(Q)", "(R)", "(X)", "(T)", "(G)", "(B)", "(C)"]
const TOUCH_WORDS := ["touch", "Touch", "tap", "Tap", "swipe", "pinch"]
