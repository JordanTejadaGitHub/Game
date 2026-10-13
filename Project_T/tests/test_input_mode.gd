extends SceneTree

# Mouse & keyboard vs touch texts (InputMode; user 2026-10-07: "on PC, hints shouldn't mention touch, and on mobile they
# shouldn't mention Esc or other keys"): the switch and its override, both variants of the build-mode whisper and Lesson,
# and a scan of every script: no string carries both ("(touch: …)"), and InputMode.text(pc, touch) keeps keys out of the
# touch variant and taps out of the PC one.

var failures := 0

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok: ", what)
	else:
		failures += 1
		push_error("FAIL: " + what)

func _initialize() -> void:
	_run.call_deferred()

func _scripts(dir: String, out: Array[String]) -> void:
	for sub in DirAccess.get_directories_at(dir):
		_scripts(dir + sub + "/", out)
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			out.append(dir + file)

func _has_any(text: String, words: Array) -> String:
	for word in words:
		if text.contains(word):
			return word
	return ""

func _run() -> void:
	InputMode.force = 0
	_check(not InputMode.touch(), "forced mouse & keyboard")
	InputMode.force = 1
	_check(InputMode.touch(), "forced touch")
	_check(InputMode.text("A", "B") == "B", "touch picks the touch variant")
	InputMode.force = 0
	_check(InputMode.text("A", "B") == "A", "PC picks the PC variant")
	_check(InputMode.key(&"cancel_build", "Esc") != "", "the bound key for cancel_build (%s)" % InputMode.key(&"cancel_build", "Esc"))
	_check(InputMode.key(&"no_such_action", "x") == "x", "an unbound action falls back")
	for mode in [0, 1]:
		InputMode.force = mode
		# The build-mode line is a Lesson now (the teaching whisper is gone, user 2026-10-12): its two variants.
		var whisper: String = InputMode.text("Build mode stays on. Right-click or Esc to stop building.", "Build mode stays on. Tap Done to stop building.")
		var wrong := _has_any(whisper, InputMode.PC_WORDS if mode == 1 else InputMode.TOUCH_WORDS)
		_check(whisper != "" and wrong == "", "the build-mode Lesson on %s has no '%s' (%s)" % ["touch" if mode == 1 else "PC", wrong, whisper])
	InputMode.force = -2

	# Every script: no string names both, and InputMode.text's variants stay on their side.
	var files: Array[String] = []
	_scripts("res://scripts/", files)
	var mixed := RegEx.create_from_string("\\((touch|on touch|phones?): ")  # "(touch: Done)" inside a string
	var pairs := RegEx.create_from_string("InputMode\\.text\\(\\s*(\"[^\"]*\")[^,]*,\\s*(\"[^\"]*\")")
	var problems: Array[String] = []
	for path in files:
		var source := FileAccess.get_file_as_string(path)
		for line in source.split("\n"):
			if line.strip_edges().begins_with("#"):
				continue
			var code := line.split(" # ")[0] if not line.contains("\"") or line.find(" # ") > line.rfind("\"") else line
			if mixed.search(code) != null:
				problems.append("%s: %s" % [path.get_file(), line.strip_edges().left(90)])
		for found in pairs.search_all(source.replace("\n", " ")):
			var pc := found.get_string(1)
			var touch := found.get_string(2)
			var in_pc := _has_any(pc, InputMode.TOUCH_WORDS)
			var in_touch := _has_any(touch, InputMode.PC_WORDS)
			if in_pc != "" or in_touch != "":
				problems.append("%s: InputMode.text(%s, %s)" % [path.get_file(), pc.left(40), touch.left(40)])
	_check(problems.is_empty(), "no mixed PC / touch strings (%s)" % "; ".join(problems))
	print("input mode test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)
