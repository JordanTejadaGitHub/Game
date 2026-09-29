extends RefCounted
class_name DevGrove

# Developer option "Dev Grove: Off / Early / Half / Full" (demo_scope.md "Dev Grove", debug builds
# only): runs and the Memory Grove screen use a GrovePresets profile (user://sim_heartwood.json)
# instead of the player's. The real profile is never read or written while it's on, except for
# settings, which always stay in the real profile (HeartwoodMemory.real_settings_path). Purchases
# and loadout changes stay in the dev profile until the option changes (then it resets to the new
# preset). A dev run (MetaRun.is_dev_run()), and the full game: Demo mode is off while it's on.
# apply() runs at the title screen (before anything reads the profile) and when the setting changes.

const SETTING := "dev_grove"
const LEVELS: Array[StringName] = [&"off", &"early", &"half", &"full"]
const PRESET_KEY := "dev_grove_preset"  # In the dev profile: the preset it was made from
const RUN_PATH := "user://sim_run.json"  # Dev runs save here, never over the real run in progress

static var force := &""  # Tests: this level instead of the setting
static var active := &""  # The level applied now (&"" = off)
static var _real_path := ""
static var _demo_override_before := -1
static var _real_run_path := ""

# The level chosen in the settings (always off outside debug builds and in headless test scripts).
static func chosen() -> StringName:
	if not TestGrove.is_available():
		return &"off"
	if force != &"":
		return force
	if OS.get_cmdline_args().has("--script"):
		return &"off"
	var level := StringName(str(HeartwoodMemory.get_settings().get(SETTING, "off")))
	return level if LEVELS.has(level) else &"off"

static func is_active() -> bool:
	return active != &""

# The HUD / Grove tag, or "" when off.
static func tag() -> String:
	return "Dev Grove: %s" % String(active).capitalize() if is_active() else ""

static func apply() -> void:
	var level := chosen()
	if level == &"off":
		if is_active():
			HeartwoodMemory.file_path = _real_path
			HeartwoodMemory.real_settings_path = ""
			ResultsScreen.demo_override = _demo_override_before
			RunSaver.file_path = _real_run_path
			active = &""
		return
	if not is_active():
		_real_path = HeartwoodMemory.file_path
		_demo_override_before = ResultsScreen.demo_override
		_real_run_path = RunSaver.file_path
	HeartwoodMemory.real_settings_path = _real_path
	HeartwoodMemory.file_path = GrovePresets.PATH
	RunSaver.file_path = RUN_PATH
	# Switched to another level (or no dev profile for this one yet): start again from its preset.
	# The same level next launch keeps the dev profile's purchases and loadout.
	if (is_active() and level != active) or str(HeartwoodMemory.load_data().get(PRESET_KEY, "")) != String(level):
		var data := GrovePresets.profile(level)
		data[PRESET_KEY] = String(level)
		HeartwoodMemory.save_data(data)
	ResultsScreen.demo_override = 0  # The full game (wins over the Demo mode setting)
	active = level
