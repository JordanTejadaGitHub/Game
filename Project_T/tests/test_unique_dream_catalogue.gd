extends SceneTree

const SUCCESSORS := {
	"cozy_corners_ii": "corner_sign", "deep_water_ii": "wake_ripple",
	"lullaby_ii": "dream_residue", "old_friends_ii": "kins_keepsake",
	"quickened_sap_ii": "passing_thread", "ricochet_ii": "crosswind",
	"shattering_blow_ii": "opening_fracture", "spore_cascade_ii": "shared_mycelium",
	"static_field_ii": "crossed_sparks", "sunlit_rest_ii": "fresh_beginnings",
	"tangled_release_ii": "afterroot", "thick_bark_ii": "emergency_reserves",
	"thorn_snare_ii": "hushed_hedge", "watchful_rest_ii": "quiet_vigil",
}
var failures := 0

func _initialize() -> void:
	for old_id in SUCCESSORS:
		var old: UpgradeData = load("res://resource/dream/%s.tres" % old_id)
		var path := "res://resource/dream/%s.tres" % SUCCESSORS[old_id]
		_check(ResourceLoader.exists(path), "%s successor exists" % old_id)
		if not ResourceLoader.exists(path):
			continue
		var card: UpgradeData = load(path)
		_check(old.retired, "%s is retired" % old_id)
		_check(card.id == SUCCESSORS[old_id] and card.rule_id == StringName(card.id), "%s has independent identity" % card.id)
		_check((not card.retired or card.id in ["emergency_reserves", "quiet_vigil", "wake_ripple", "shared_mycelium", "crossed_sparks", "corner_sign", "fresh_beginnings"]) and card.deepens.is_empty(), "%s is independently offered" % card.id)  # Emergency Reserves retired 2026-10-12 (card_review section 10); Corner Sign retired 2026-10-15 (overlap pass)
		_check(card.rarity == old.rarity and (card.tags == old.tags or card.id == "passing_thread"), "%s preserves rarity/family" % card.id)  # (Wake Ripple, Shared Mycelium, Crossed Sparks retired and Passing Thread reworked as a maze card, 2026-10-13)
		_check(card.in_start_pool == old.in_start_pool and card.discovered_by == old.discovered_by, "%s preserves access/discovery" % card.id)
		var requirements := old.requires.duplicate()
		requirements.erase(old.deepens)
		_check((card.requires == requirements and card.requires_any == old.requires_any) or card.id == "afterroot", "%s preserves Warden gates" % card.id)  # Afterroot needs a Holding form (council full_review 2026-10-17)
		_check(not card.description.is_empty(), "%s has player text" % card.id)
		var dreams := DreamState.new()
		dreams.pool.assign([load("res://resource/dream/%s.tres" % old.deepens), old, card])
		dreams.unlock_everything = true
		dreams.stacks = {old.deepens: 1, old.id: 1, card.id: 1}
		_check(dreams.rule_level(old.rule_id) == 1, "%s keeps legacy upgraded effects" % old.id)
		_check(dreams._taken_cards().size() == 2, "%s coexists while legacy II replaces base" % card.id)
		_check(not dreams.can_offer(old), "%s cannot be newly offered" % old.id)
		dreams.free()
	for id in ["rolling_thunder_ii", "root_network_ii", "guiding_light_ii", "tender_care_ii"]:
		var card: UpgradeData = load("res://resource/dream/%s.tres" % id)
		_check(not card.retired and card.is_deepened(), "%s remains active Deepened" % id)
	for entry in [["whirligig_hidden", "ricochet_ii", "crosswind"], ["sharpened", "shattering_blow_ii", "opening_fracture"], ["thorn_and_bramble", "thorn_snare_ii", "hushed_hedge"]]:
		var grove = load("res://resource/meta/grove/%s.tres" % entry[0])
		# The retired II left the node's list (card_review_2026-10-12.md 11 E); its card file stays loadable for old saves.
		_check(not grove.dream_cards.has(entry[1]) and grove.dream_cards.has(entry[2]) and ResourceLoader.exists("res://resource/dream/%s.tres" % entry[1]),
			"%s grants the successor; the retired II is off the node but still loadable" % entry[0])
	var rows := GroveCardList.new()
	root.add_child(rows)
	rows.show_for(load("res://resource/meta/grove/sharpened.tres"))
	_check(rows.has_node("opening_fracture"), "Sharpened presents its unique successor")
	_check(not rows.get_node("shattering_blow").find_children("*", "Label", true, false).any(func(l: Label) -> bool: return l.text == "+ II"),
		"retired II does not advertise an obtainable Grove upgrade")
	rows.queue_free()
	print("unique_dream_catalogue test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
