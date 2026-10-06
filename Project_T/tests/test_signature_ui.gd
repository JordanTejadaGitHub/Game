extends SceneTree

# Rank V signatures, the player's side (warden_stats.md 96d728dd; Tower Code's Signatures 105f2252): the Warden panel
# shows the way there from rank III and a gold mark after the picks at rank V; the first time a signature fires its
# name pops over the Warden and the HUD says what it does (once); the Codex glossary lists all 8. Temp profile.
#   godot --headless --path . --script res://tests/test_signature_ui.gd --fixed-fps 60

const P := Tower.Focus.POWER
const S := Tower.Focus.SWIFT
const R := Tower.Focus.REACH

var failures := 0
var main: Node
var placer: TowerPlacer

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok: ", what)
	else:
		failures += 1
		push_error("FAIL: " + what)

func _initialize() -> void:
	_run.call_deferred()

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _plant(id: String, at: Vector2, choices: Array) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = at
	tower.position = Tower.MAP_GRID.calculate_map_position(at)
	placer.tower_container.add_child(tower)
	tower.set_process(false)
	tower.rank = choices.size()
	tower.rank_choices.assign(choices)
	tower._stats = {}
	return tower

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_signature_ui_%d.json" % OS.get_process_id()
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await _frames(3)
	placer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var panel: Node = main.find_child("WardenPanel", true, false)
	var callouts: Node = main.get_node("%CombatCallouts")

	# The panel: the way there at rank III, the mark at rank V.
	var growing := _plant("sporeling", Vector2(10, 2), [P, P, S])
	var crusher := _plant("sporeling", Vector2(4, 2), [P, P, S, P, R])
	await _frames(2)
	seller.select(growing)
	await _frames(2)
	var hint := panel.find_child("SignatureHint", true, false) as Label
	_check(hint != null and hint.text == "1 more Power rank: Crushing at rank V", "rank III: the hint (%s)" % (hint.text if hint else "none"))
	_check(panel.find_child("Signature", true, false) == null, "rank III: no mark yet")
	seller.select(null)
	seller.select(crusher)
	await _frames(2)
	var mark := panel.find_child("Signature", true, false) as Label
	_check(mark != null and mark.text.contains("Crushing") and mark.tooltip_text.contains("5th hit"),
		"rank V: the Crushing mark with what it does (%s)" % (mark.text if mark else "none"))
	_check(panel.find_child("SignatureHint", true, false) == null, "rank V: no hint")
	var icon := panel.find_child("SignatureIcon", true, false) as TextureRect
	_check(icon != null and icon.texture is AtlasTexture and (icon.texture as AtlasTexture).region.position.x == 0.0,
		"rank V: Tower Assets' Crushing mark (the first of the sheet) joins the picks")

	# The first fire: the name over the Warden and the discovery, once.
	crusher.signature_fired.emit(crusher, Signatures.CRUSHING)
	await _frames(1)
	_check(callouts.discovered == [Signatures.CRUSHING], "the first Crushing is a discovery (%s)" % [callouts.discovered])
	_check(callouts._alive.any(func(c: Array) -> bool: return c[1] == "Crushing!"), "its name pops over the Warden")
	var toast := main.get_node("%ToastLabel") as Label
	_check(toast != null and toast.text.begins_with("Signature discovered: Crushing"), "the HUD says what it does (%s)" % (toast.text if toast else ""))
	var later := _plant("sporeling", Vector2(6, 2), [P, P, P, S, R])
	await _frames(1)
	later.signature_fired.emit(later, Signatures.CRUSHING)
	await _frames(1)
	_check(callouts.discovered.size() == 1, "a second Crushing (another Warden, planted later) is no new discovery")
	_check(not HeartwoodMemory.load_data().has(callouts.SIGNATURES_SEEN_KEY), "tests never write the profile")

	# The Codex glossary.
	var groups: Array = CodexData.glossary().filter(func(g: Array) -> bool: return g[0] == "Signatures")
	_check(groups.size() == 1 and groups[0][1].size() == 8 and groups[0][1].any(func(e: Array) -> bool: return e[0] == "Crushing" and e[1].begins_with("Power majority")),
		"the glossary lists the 8 signatures")

	main.queue_free()
	await _frames(1)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("signature ui test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)
