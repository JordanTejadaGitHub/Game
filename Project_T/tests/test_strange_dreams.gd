extends SceneTree

# Headless test for the Strange Dreams gamble cards (dream_design.md "Strange Dreams: gamble cards", cards 252–255):
# Mystery Dream becomes a random Uncommon / Rare it could offer (revealed at once, one copy), Moonflip's seeded coin per
# block (+25% / −15% damage), Double or Nothing (Omens ×2 with no leaf lost, nothing with any; from drift 10), and
# Wild Dew (each drift's pot ×0.6–×1.6, seeded, in the shown pot). Never touches the player's saves.
#   godot --headless --path . --script res://tests/test_strange_dreams.gd --fixed-fps 60

const IDS := ["mystery_dream", "moonflip", "double_or_nothing", "wild_dew"]

var failures := 0
var main: Node
var dreams: DreamState
var director: DriftDirector
var omens: OmenDirector
var run_state: RunState

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	dreams = main.get_node("%DreamState")
	director = main.get_node("%DriftDirector")
	omens = main.get_node("%OmenDirector")
	run_state = main.get_node("%RunState")
	dreams.unlock_everything = false
	dreams.unlocked = {"sprout": true, "thornwall": true, "sporeling": true}
	for id in IDS:
		dreams.grove_cards.append(id)  # Planted (the Strange Dreams node)
	_test_cards()
	await _test_mystery()
	_test_moonflip()
	_test_double_or_nothing()
	_test_wild_dew()
	print("strange dreams test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _test_cards() -> void:
	var rarities := {"mystery_dream": UpgradeData.Rarity.UNCOMMON, "moonflip": UpgradeData.Rarity.UNCOMMON,
		"double_or_nothing": UpgradeData.Rarity.RARE, "wild_dew": UpgradeData.Rarity.COMMON}
	for id in IDS:
		var card := _card(id)
		if card == null:
			continue
		_check(card.tags == ["strange"] and not card.in_start_pool and card.max_stacks == 1 and card.rarity == rarities[id]
			and card.rule_id == StringName(id), "%s: tag strange, Grove pool, one copy, %s" % [id, UpgradeData.rarity_name(rarities[id])])

func _test_mystery() -> void:
	var mystery := _card("mystery_dream")
	_check(dreams.can_offer(mystery, 1), "Mystery Dream can be offered once planted")
	_check(dreams.preview_card_impact(mystery).text == "Unknown until taken", "its impact preview: \"Unknown until taken\"")
	var revealed := []
	dreams.mystery_revealed.connect(func(m: UpgradeData, c: UpgradeData) -> void: revealed.append([m, c]), CONNECT_ONE_SHOT)
	dreams.current_offer = [mystery]
	dreams.picks_left = 1
	dreams.choose(mystery)
	await process_frame
	var became: UpgradeData = revealed[0][1] if not revealed.is_empty() else null
	_check(became != null and became != mystery and (became.rarity == UpgradeData.Rarity.UNCOMMON or became.rarity == UpgradeData.Rarity.RARE)
		and not became.is_bittersweet() and dreams.has_card(became.id),
		"taken, it becomes a random Uncommon or Rare (%s) and that card is yours" % (became.display_name if became else "none"))
	_check(dreams.card_stacks("mystery_dream") == 0 and dreams.mystery_spent and not dreams.can_offer(mystery, 1),
		"…the Mystery Dream itself is spent (one copy, never offered again)")
	var shown := main.find_child("MysteryReveal", true, false)
	_check(shown != null, "the card it became is shown at once")
	if shown != null:
		shown.queue_free()
	_check(dreams.to_save().get("mystery_spent", false) == true, "…and saved with the run")
	# Nothing Uncommon or Rare it could offer: a Common instead
	dreams.mystery_spent = false
	var pool := dreams.pool.duplicate()
	var common: UpgradeData = null
	for card in pool:
		if card.rarity == UpgradeData.Rarity.COMMON and card.in_start_pool and dreams.can_offer(card, 1) and card.rule_id != &"wild_dew":
			common = card
			break
	dreams.pool.assign([mystery, common])
	_check(dreams.mystery_pick() == common, "with no Uncommon or Rare to become, it becomes a Common (%s)" % (common.display_name if common else "none"))
	dreams.pool.assign(pool)
	dreams.stacks.clear()
	dreams.mystery_spent = false

func _test_moonflip() -> void:
	var tower: Tower = load("res://scenes/tower/tower.tscn").instantiate()
	tower.tower_data = load("res://resource/tower/sporeling.tres")
	tower.cell = Vector2(3, 3)
	tower.position = tower.MAP_GRID.calculate_map_position(tower.cell)
	main.get_node("%TowerContainer").add_child(tower)
	tower.set_process(false)
	var before := dreams.get_soothe_multiplier(tower)
	_check(dreams.moonflip_bonus() == 0.0 and dreams.moonflip_text() == "", "no Moonflip: no coin")
	dreams.take(_card("moonflip"))
	var bonus := dreams.moonflip_bonus()
	_check(bonus == DreamState.MOONFLIP_UP or bonus == DreamState.MOONFLIP_DOWN, "Moonflip: +25% or −15% (%s)" % bonus)
	_check(is_equal_approx(dreams.get_soothe_multiplier(tower), before + bonus), "…on every Warden's damage (%.2f → %.2f)" % [before, dreams.get_soothe_multiplier(tower)])
	_check(dreams.moonflip_text() == ("Moonflip · +25%" if bonus > 0.0 else "Moonflip · −15%"), "the DriftPanel line: %s" % dreams.moonflip_text())
	var ups := 0
	for block in range(1, 21):
		if dreams.moonflip_is_up(block):
			ups += 1
	_check(ups > 3 and ups < 17, "a coin per block: both sides come up over 20 blocks (%d heads)" % ups)
	_check(dreams.moonflip_is_up(7) == dreams.moonflip_is_up(7), "seeded: the same block flips the same way")
	tower.free()
	dreams.stacks.clear()
	dreams.bump_board()

func _test_double_or_nothing() -> void:
	var don := _card("double_or_nothing")
	director.drifts_started = 5
	dreams._offer_drift = 5
	_check(not dreams.can_offer(don, 1), "Double or Nothing: not before drift 10 (Omens begin there)")
	director.drifts_started = 10
	dreams._offer_drift = 10
	_check(dreams.can_offer(don, 1), "…offered from drift 10")
	var omen := OmenData.new()
	omen.id = "test_omen"
	omen.reward_dew = 40
	omen.reward_rare_dreams = 1
	director.drifts_started = 12
	var plain_clean := _paid(omen, 0)
	var plain_lost := _paid(omen, 1)
	dreams.take(don)
	_check(omens.share_for(0) == 2.0 and omens.share_for(1) == 0.0 and omens.dreams_kept_for(0) and not omens.dreams_kept_for(1),
		"with it: ×2 with no leaf lost, nothing with any")
	var rare_before: int = dreams._rare_dreams_left
	var clean := _paid(omen, 0)
	_check(clean == plain_clean * 2 and dreams._rare_dreams_left - rare_before == 2, "a clean block pays double: %d Dew (not %d), Rare+ in 2 Dreams" % [clean, plain_clean])
	rare_before = dreams._rare_dreams_left
	var lost := _paid(omen, 1)
	_check(lost == 0 and plain_lost > 0 and dreams._rare_dreams_left == rare_before, "a leaf lost pays nothing (not %d)" % plain_lost)
	_check(omens.reward_sentence(omen, 1).contains("+%d Dew" % (plain_clean * 2)) and omens.reward_sentence(omen, 1).contains("Double or Nothing"),
		"the Omen's reward line says so: %s" % omens.reward_sentence(omen, 1))
	var prize := OmenData.new()  # A double-edged Omen (its extra Dew is the prize): unaffected
	prize.creature_dew_multiplier = 1.5
	omens.active = prize
	_check(omens.get_reward_share(1) == 1.0, "a double-edged Omen is unaffected")
	omens.active = null
	dreams.stacks.clear()
	director.drifts_started = 0
	dreams._offer_drift = 0

# What the active `omen` pays at the rest with `lost` leaves lost in its block (Dew).
func _paid(omen: OmenData, lost: int) -> int:
	omens.active = omen
	omens.active_block = 3
	omens._leaves_lost_at_start = run_state.leaves_lost - lost
	var dew := run_state.dew
	omens._pay_reward(0)
	return run_state.dew - dew

func _test_wild_dew() -> void:
	var base := director.get_dew_pot_multiplier(12)
	_check(dreams.wild_dew_roll(12) == 1.0, "no Wild Dew: ×1")
	dreams.take(_card("wild_dew"))
	var rolls := {}
	for number in range(2, 30):
		var roll := dreams.wild_dew_roll(number)
		_check(roll >= DreamState.WILD_DEW_MIN and roll <= DreamState.WILD_DEW_MAX, "drift %d rolls ×%s (0.6–1.6)" % [number, roll])
		rolls[roll] = true
	_check(rolls.size() > 10, "each drift rolls its own (%d different rolls)" % rolls.size())
	_check(dreams.wild_dew_roll(12) == dreams.wild_dew_roll(12), "seeded: the same drift rolls the same")
	_check(is_equal_approx(director.get_dew_pot_multiplier(12), base * dreams.wild_dew_roll(12)),
		"it multiplies the pot with the other modifiers (the DriftPanel's next pot shows it)")
	_check(is_equal_approx(director.get_effective_pot(12), director.get_dew_pot(12) * director.get_dew_pot_multiplier(12)), "…in the pot shown before the drift")
	dreams.stacks.clear()

func _card(id: String) -> UpgradeData:
	for card in dreams.pool:
		if card.id == id:
			return card
	_check(false, "card %s exists" % id)
	return null

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
