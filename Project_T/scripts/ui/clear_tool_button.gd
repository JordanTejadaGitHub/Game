extends Button
class_name ClearToolButton

# The Clear tool on the Warden bar (screens_ui.md "The Clear tool"): the left end of the bar, set
# apart, hotkey 0 / C (action clear_tool). Locked until the run's first clearing Dream (tapping says
# why); then it glows once. Selecting it turns on ObstacleClearer's tool mode (Roguelite Code's:
# outline, cost, route preview, click to clear, stays on until Esc / right-click / picking a Warden).
# A badge shows free clears (Heartwood's Reach). On touch, a marked obstacle gets Clear / Cancel
# buttons above the tool. Icon: assets/ui/clear_tool.png (locked / available / active frames).

const LOCKED_TEXT := "Take a clearing Dream to tend the forest."
# assets/ui/clear_tool.png: three 64×64 frames, locked / available / active (Game tower assets).
const ICON_SHEET := preload("res://assets/ui/clear_tool.png")
const FRAME_LOCKED := 0
const FRAME_AVAILABLE := 1
const FRAME_ACTIVE := 2
const SPROUT_COLOR := Palette.SPRIG
const LOCKED_TINT := UiStyle.OFF
const BADGE_COLOR := UiStyle.LIVE

var clearer: ObstacleClearer
var run_state: RunState
var toast: Callable  # show_toast(text)
var _confirm := HBoxContainer.new()
var _glow := 0.0  # 1 → 0 after unlocking
var _frame := -1  # The icon frame shown

func setup(obstacle_clearer: ObstacleClearer, state: RunState, show_toast: Callable) -> void:
	clearer = obstacle_clearer
	run_state = state
	toast = show_toast

func _ready() -> void:
	name = "ClearTool"
	toggle_mode = true
	theme_type_variation = &"WardenSlot"  # Same fog patch + underline as the Warden bar (ui_style.md)
	focus_mode = Control.FOCUS_NONE
	# Laid out like the Warden buttons: icon on top, "Clear" under it.
	text = "Clear"
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	add_theme_constant_override("icon_max_width", 34)
	add_theme_font_size_override("font_size", 14)
	_update_icon()
	tooltip_text = "Clear tool (0 / C): Tend Withered Trees and move Mossy Boulders."
	pressed.connect(toggle_tool)
	clearer.tool_changed.connect(func(active: bool) -> void: set_pressed_no_signal(active))
	clearer.tool_refused.connect(func() -> void: toast.call(LOCKED_TEXT))
	clearer.lock_changed.connect(_on_lock_changed)
	clearer.clear_pending.connect(_on_clear_pending)
	run_state.free_clears_changed.connect(func(_n: int) -> void: queue_redraw())
	# Touch: Clear / Cancel for the marked obstacle, just above the tool.
	_confirm.visible = false
	_confirm.position = Vector2(0, -56)
	_confirm.add_theme_constant_override("separation", 6)
	for pair in [["Clear", func() -> void: clearer.confirm_pending()],
			["Cancel", func() -> void: clearer.set_tool_active(false)]]:
		var button := Button.new()
		button.text = pair[0]
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(88, 48)
		button.pressed.connect(pair[1])
		_confirm.add_child(button)
	add_child(_confirm)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("clear_tool"):
		toggle_tool()
		get_viewport().set_input_as_handled()

# Turns the tool on or off; while clearing is locked it explains why instead.
func toggle_tool() -> void:
	if clearer.is_locked():
		set_pressed_no_signal(false)
		toast.call(LOCKED_TEXT)
		return
	clearer.set_tool_active(not clearer.is_tool_active())
	set_pressed_no_signal(clearer.is_tool_active())

func _on_lock_changed(locked: bool) -> void:
	if not locked:
		_glow = 1.0  # A short glow as the tool lights up
	queue_redraw()

func _on_clear_pending(cell: Vector2) -> void:
	_confirm.visible = cell != ObstacleClearer.NO_CELL

func _process(delta: float) -> void:
	_update_icon()  # Cheap: only swaps the texture when the state changes
	if _glow > 0.0:
		_glow = maxf(_glow - delta / 1.5, 0.0)
		queue_redraw()
	if _confirm.visible and not clearer.is_tool_active():
		_confirm.visible = false

# Picks the icon frame for the tool's state: locked, available or active.
func _update_icon() -> void:
	var frame := FRAME_LOCKED if clearer.is_locked() else (FRAME_ACTIVE if clearer.is_tool_active() else FRAME_AVAILABLE)
	if frame == _frame:
		return
	_frame = frame
	var atlas := AtlasTexture.new()
	atlas.atlas = ICON_SHEET
	atlas.region = Rect2(frame * 64, 0, 64, 64)
	icon = atlas
	add_theme_color_override("font_color", LOCKED_TINT if frame == FRAME_LOCKED else UiStyle.INK_DIM)

func _draw() -> void:
	# The icon and "Clear" are the button's own; the glow, hotkey and free-clears badge go on top
	# (the sheet leaves every frame's top-right corner empty for the badge).
	if _glow > 0.0:
		draw_circle(Vector2(size.x / 2.0, size.y / 2.0 - 6.0), 22.0, Color(SPROUT_COLOR, 0.35 * _glow))
	var font := ThemeDB.fallback_font
	_text(font, Vector2(3, 12), "0", 11, UiStyle.INK_DIM)
	if not clearer.is_locked() and run_state.free_clears > 0:
		_text(font, Vector2(size.x - 14, 12), str(run_state.free_clears), 11, BADGE_COLOR)

func _text(font: Font, at: Vector2, text: String, font_size: int, colour: Color) -> void:
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Palette.DREAD)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)
