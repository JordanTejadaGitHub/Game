extends SceneTree

# Card text check (Roguelite Mechanic Discussion, 2026-10-02: "check every card's text"): every stat-field Dream
# card (no rule id, an effect number in its fields) states numbers its fields carry (0.25 ↔ 25%, 1.25 ↔ +25%,
# 0.75 ↔ 25% less). Cards whose text is not yet fixed are KNOWN, with why; the list shrinks as texts are fixed
# (a known card that now passes is reported, so it can come off). The full audit: tools/card_text_audit.gd.
#   godot --headless --path . --script res://tests/test_card_text.gd

const Check := preload("res://tools/card_text_check.gd")
const KNOWN := {
	"burn_back": "5 Dew a tree is DreamState.BURN_BACK_PER_TREE, not a field",
	"deeper_rings": "130 / 180 Dew are rank cost constants, not fields",
}

const TYPED_KNOWN := {
	"dream_hatchery": "splits into 3 is a split constant (not a field); status_stacks 3 only by chance",
}

var failures := 0

func _initialize() -> void:
	var stat_cards := 0
	for card in Check.load_cards():
		if not Check.is_stat_card(card):
			continue
		stat_cards += 1
		var missing := Check.unmatched(card)
		if missing.is_empty():
			if KNOWN.has(card.id):
				print("  %s now matches its fields: take it off KNOWN" % card.id)
			continue
		if not KNOWN.has(card.id):
			_check(false, "%s: \"%s\" states %s, which no field carries (%s)" % [card.id, card.description, missing, Check.numeric_fields(card)])
	_check(stat_cards >= 20, "the check sees the stat cards (%d)" % stat_cards)
	# Unlock cards read their Dew prices from the Warden ({grow_cost:id} / {plant_cost:id}): never a hand-written number
	var unlock_cards := 0
	for card in Check.load_cards():
		if card.kind == UpgradeData.Kind.UNLOCK_EVOLUTION or card.kind == UpgradeData.Kind.UNLOCK_WARDEN:
			unlock_cards += 1
			_check(not Check.has_written_price(card), "%s: a hand-written Dew price (\"%s\"): use {grow_cost:id} / {plant_cost:id}" % [card.id, card.description])
	_check(unlock_cards >= 60, "the check sees the unlock cards (%d)" % unlock_cards)
	# A grow card never types a number its Warden's fields carry (text_pass.md 797758fe: 17 cards had drifted): it uses
	# {field:<id>.<field>[:format]}. TYPED_KNOWN: numbers that only look like a field (with why).
	for card in Check.load_cards():
		var typed := Check.typed_warden_numbers(card)
		if not typed.is_empty() and not TYPED_KNOWN.has(card.id):
			_check(false, "%s: hand-typed %s that its Warden's fields carry: use {field:%s.<field>} (\"%s\")" % [card.id, typed,
				card.unlocks.get_id(), card.description])
		elif typed.is_empty() and TYPED_KNOWN.has(card.id):
			print("  %s has no typed Warden number now: take it off TYPED_KNOWN" % card.id)
	var graft: UpgradeData = load("res://resource/dream/dream_graftling.tres")
	var share := "%d%%" % roundi((load("res://resource/tower/graftling.tres") as TowerData).copy_share * 100.0)
	_check(IconInfo.format(graft.description).contains("at " + share), "Graftling's card reads copy_share (%s): \"%s\"" % [share, IconInfo.format(graft.description)])
	var acorn: UpgradeData = load("res://resource/dream/dream_acorn.tres")
	_check(IconInfo.format(acorn.description).contains("(15 Dew)") or IconInfo.format(acorn.description).contains("(%d Dew)" % (load("res://resource/tower/acorn.tres") as TowerData).evolve_cost),
		"the price tokens read the Warden (\"%s\")" % IconInfo.format(acorn.description))
	# {pct:warden.field} reads the Warden's share field (Beacon's Mark, Grafted Elder's copy), so the text can't drift
	var beacon: UpgradeData = load("res://resource/dream/dream_beacon.tres")
	var mark := "+%d%%" % roundi((load("res://resource/tower/beacon.tres") as TowerData).marked_bonus * 100.0)
	_check(IconInfo.format(beacon.description).contains(mark), "Beacon's text shows its marked_bonus (%s): \"%s\"" % [mark, IconInfo.format(beacon.description)])
	# An offered card always names what it's about (story chat, Mushroom Rain read "???'s spore cloud"): no "???" from a
	# combo or nightmare not yet found, in any card's or Omen's text ({named_combo:x} on cards).
	var hidden: Array[String] = []
	for card in Check.load_cards():
		for text in [card.description, card.cost_description, card.grows_text]:
			if IconInfo.format(text).contains("???") or IconInfo.format(text).contains("combo:") or StatusLinks.bbcode(text).contains("???"):
				hidden.append(card.id)
	for file in ResourceLoader.list_directory("res://resource/omen/"):
		var omen := load("res://resource/omen/" + file) as OmenData if file.ends_with(".tres") else null
		if omen != null and IconInfo.format(omen.description).contains("???"):
			hidden.append(omen.id)
	_check(hidden.is_empty(), "no card or Omen text shows ??? or a leftover token (%s): write {named_combo:x}" % ", ".join(hidden))
	# text_style.md "Card wording, one way each" (e2176ea3) on every card's text and cost line, and the stacking note
	for card in Check.load_cards():
		for text in [card.description, card.cost_description]:
			for problem in Check.wording_breaks(text):
				_check(false, "%s: %s" % [card.id, problem])
		var stacking := Check.stacking_break(card)
		_check(stacking == "", "%s: %s (\"%s\")" % [card.id, stacking, card.description])
	print("card text test: %s (%d stat cards, %d known exceptions)" % ["PASS" if failures == 0 else "%d FAILED" % failures, stat_cards, KNOWN.size()])
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
