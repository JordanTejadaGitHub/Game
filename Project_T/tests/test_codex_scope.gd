extends SceneTree

# Headless test for what the Codex covers (screens_ui.md "What the Codex covers"): the starting three
# families plus Grove-planted ones; entries out of scope are counted in "N more wait in the Memory
# Grove."; newly covered ones get the "New from the Grove" leaf; the Families page; the demo stays at
# its three; dev runs show everything. Uses a temp profile.
#   godot --headless --path . --script res://tests/test_codex_scope.gd --fixed-fps 60

var PROFILE_PATH := "user://test_codex_scope_profile_%d.json" % OS.get_process_id()  # Per process: parallel sessions share user://

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = PROFILE_PATH
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE_PATH))
	ResultsScreen.demo_override = 0
	MetaRun.force_all_families = false

	# No Pebbling in the Grove: its combos wait there.
	var profile := HeartwoodMemory.load_data()
	HeartwoodMemory.save_data(profile)
	var scope := CodexData.scope()
	_check(scope.families == CodexData.DEMO_FAMILIES, "a fresh profile covers the starting three (%s)" % str(scope.families))
	var codex := CodexPanel.new()
	root.add_child(codex)
	codex.open(&"combos")
	# Out of reach = "???" under the "N more wait in the Memory Grove" line (the counter shows the real total).
	var waits := func(id: String) -> bool:
		var entry: Control = codex._entries.get(id)
		if entry == null:
			return false
		var texts := entry.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
		return entry.get_meta(&"waiting", false) and texts.has("???") and texts.all(func(t: String) -> bool: return t == "???")
	_check(waits.call("marked_blow"), "without Pebbling, Exposed Blow waits as ??? in the Memory Grove")
	_check(codex._combo_count.text.ends_with("/ %d combos discovered" % CodexData.combos().size()), "the counter counts every combo (%s)" % codex._combo_count.text)
	_check(waits.call("spore_nursery") and codex._entries.has("slumber_rot") and not waits.call("slumber_rot"),
		"a hidden Kinship (Fairy Ring, a hidden branch) waits for its Grove node; Slumber Rot is listed")
	var waiting := codex._combos.find_children("Waiting", "Label", false, false)
	_check(not waiting.is_empty() and (waiting[0] as Label).text.ends_with("wait in the Memory Grove."),
		"…one line says how many wait in the Memory Grove (%s)" % ((waiting[0] as Label).text if not waiting.is_empty() else "none"))
	_check(codex.family_cards.size() == CodexData.DEMO_FAMILIES.size() and codex.family_cards.has("bellflower") and not codex.family_cards.has("pebbling"),
		"the Families page shows the starting four (%s)" % [codex.family_cards.keys()])
	var covered_before: Array = (CodexData.combos() + CodexData.crowned() + CodexData.kinships()).filter(
		func(e: Dictionary) -> bool: return CodexData.in_build(e, scope)).map(func(e: Dictionary) -> String: return String(e.id))

	# Pebbling planted in the Grove: its combos arrive, marked "New from the Grove".
	profile = HeartwoodMemory.load_data()
	profile.unlocks["pebbling"] = 1
	profile[CodexPanel.COVERED_KEY] = covered_before  # As remembered from the last look
	HeartwoodMemory.save_data(profile)
	scope = CodexData.scope()
	_check(scope.families.has("pebbling"), "a planted Pebbling joins the scope")
	codex.open(&"combos")
	_check(codex._entries.has("marked_blow"), "with Pebbling, Exposed Blow is listed")
	var card: Control = codex._entries.get("marked_blow")
	_check(card != null and card.get_node_or_null("GroveMark") != null, "…with the New from the Grove mark")
	_check(codex._entries.has("conducted") and codex._entries["conducted"].get_node_or_null("GroveMark") == null,
		"entries covered before have no mark")
	_check(codex.family_cards.has("pebbling"), "the Families page shows Pebbling")
	var pebbling: TowerData = load("res://resource/tower/pebbling.tres")
	_check(codex.family_combos(pebbling).any(func(e: Dictionary) -> bool: return e.id == &"marked_blow"),
		"Pebbling's section links to Exposed Blow")
	# A Grove-kept form (a hidden branch not planted) is a silhouette.
	var kept := CodexData.grove_forms().keys().filter(func(id: String) -> bool:
		return CodexData.grove_forms()[id] == "pebbling_hidden")
	if not kept.is_empty():
		_check(not scope.wardens.has(kept[0]), "Pebbling's hidden branch waits for its Grove node (%s)" % kept[0])

	# The demo stays at its three; dev runs cover everything.
	ResultsScreen.demo_override = 1
	_check(CodexData.scope().families == CodexData.DEMO_FAMILIES, "the demo covers only its three, whatever the profile")
	ResultsScreen.demo_override = 0
	MetaRun.force_all_families = true
	_check(CodexData.scope().all, "Unlock all families covers everything")
	codex.open(&"combos")
	_check(codex._combos.find_children("Waiting", "Label", false, false).is_empty(), "…with nothing waiting")
	MetaRun.force_all_families = false

	# Combat callouts in the glossary (user: "been seeing 'Shattered' but don't know what it means"): a
	# callout's line appears once it's been seen; Weak / Resisted always; a Reaction once discovered.
	var fresh := HeartwoodMemory.defaults()
	HeartwoodMemory.save_data(fresh)
	var names := CodexData.callout_entries().map(func(e: Array) -> String: return e[0])
	_check(names.has("Weak") and names.has("Resisted") and not names.has("Critical") and not names.has("Thunderclap"),
		"before seeing them: only Weak and Resisted (%s)" % [names])
	fresh[CodexData.CALLOUT_SEEN_KEY] = ["crit"]
	fresh["combos_seen"] = ["thunderclap"]
	HeartwoodMemory.save_data(fresh)
	names = CodexData.callout_entries().map(func(e: Array) -> String: return e[0])
	_check(names.has("Critical") and names.has("Thunderclap"), "seen callouts join the glossary (%s)" % [names])
	_check(CodexData.definition("Critical").begins_with("A critical hit"), "Critical means a critical hit (the callout was Shattered!)")

	codex.queue_free()
	ResultsScreen.demo_override = -1
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE_PATH))
	await process_frame
	print("codex scope test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
