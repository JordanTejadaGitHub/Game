extends Node
class_name DreamCodex

# The Codex's Dreams (screens_ui.md, Codex "Dreams"; user: "add a card Codex for all cards; all start
# as ???, and once you see them once in your account it's added"): records, for the account, every
# Dream card the player has been offered (seen, the first time it's in any offer: taking isn't needed),
# how often each was taken, and how many won runs had it. Written to the profile at once in the real
# game (never tests): dreams_seen (+ the hidden dev flag dreams_seen_dev in developer runs, like
# combos), dreams_taken {id: n}, dreams_won {id: n} (normal runs only), dreams_viewed (the Codex's
# gold "New" until viewed). The "Dream of everything" milestone (all_dreams) counts normal-run sights
# only. The dev "any card" pick is taken, not offered, so it never marks a card seen.
# Made by the HUD; the Codex reads the static helpers.

const SEEN_KEY := "dreams_seen"
const DEV_KEY := "dreams_seen_dev"
const TAKEN_KEY := "dreams_taken"
const WON_KEY := "dreams_won"
const VIEWED_KEY := "dreams_viewed"
const MILESTONE := "all_dreams"  # "Dream of everything" (Meta lists it)
const DREAM_DIR := "res://resource/dream/"

static var _all: Array[UpgradeData] = []

var dream_state: DreamState
var run_state: RunState
var _taken_this_run: Array[String] = []

# Every Dream card in the game (the resource folder: start pool, Grove-only, Legendary, Deepened).
# Family Blessings are never offered, so they aren't listed.
static func all_cards() -> Array[UpgradeData]:
	if _all.is_empty():
		for file in ResourceLoader.list_directory(DREAM_DIR):
			if file.ends_with(".tres") or file.ends_with(".res"):
				var card := load(DREAM_DIR + file) as UpgradeData
				if card != null:
					_all.append(card)
		_all.sort_custom(func(a: UpgradeData, b: UpgradeData) -> bool: return a.display_name < b.display_name)
	return _all

static func seen() -> Array:
	return HeartwoodMemory.load_data().get(SEEN_KEY, [])

static func is_seen(card: UpgradeData, seen_list: Array = []) -> bool:
	return (seen_list if not seen_list.is_empty() else seen()).has(card.id)

func _init(dreams: DreamState = null, run: RunState = null) -> void:
	dream_state = dreams
	run_state = run

func _ready() -> void:
	if dream_state != null:
		dream_state.offer_ready.connect(func(cards: Array[UpgradeData], _drift: int) -> void: record_offer(cards))
		dream_state.card_taken.connect(record_taken)
	if run_state != null:
		run_state.run_ended.connect(record_run_end)

# The real game writes (tests never do).
func _may_write() -> bool:
	return dream_state != null and get_tree().current_scene == dream_state.owner

func record_offer(cards: Array) -> void:
	if not _may_write():
		return
	var profile := HeartwoodMemory.load_data()
	var seen_list: Array = profile.get(SEEN_KEY, []).duplicate()
	var dev: Array = profile.get(DEV_KEY, []).duplicate()
	var changed := false
	for card in cards:
		if card == null:
			continue
		if not seen_list.has(card.id):
			seen_list.append(card.id)
			if MetaRun.is_dev_run():
				dev.append(card.id)
			changed = true
		elif dev.has(card.id) and not MetaRun.is_dev_run():
			dev.erase(card.id)  # Seen in a normal run now: it counts
			changed = true
	if not changed:
		return
	profile[SEEN_KEY] = seen_list
	profile[DEV_KEY] = dev
	if all_cards().all(func(c: UpgradeData) -> bool: return seen_list.has(c.id) and not dev.has(c.id)):
		profile.milestones[MILESTONE] = true
	HeartwoodMemory.save_data(profile)

func record_taken(card: UpgradeData) -> void:
	if card == null:
		return
	if not _taken_this_run.has(card.id):
		_taken_this_run.append(card.id)
	if not _may_write() or MetaRun.is_dev_run():
		return
	var profile := HeartwoodMemory.load_data()
	var taken: Dictionary = profile.get(TAKEN_KEY, {})
	taken[card.id] = int(taken.get(card.id, 0)) + 1
	profile[TAKEN_KEY] = taken
	HeartwoodMemory.save_data(profile)

func record_run_end(won: bool) -> void:
	if not won or not _may_write() or MetaRun.is_dev_run():
		return
	var profile := HeartwoodMemory.load_data()
	var wins: Dictionary = profile.get(WON_KEY, {})
	for id in _taken_this_run:
		wins[id] = int(wins.get(id, 0)) + 1
	profile[WON_KEY] = wins
	HeartwoodMemory.save_data(profile)

# The Codex marks the seen cards viewed (their gold "New" goes); never from tests.
static func mark_viewed(ids: Array) -> void:
	if OS.get_cmdline_args().has("--script") or ids.is_empty():
		return
	var profile := HeartwoodMemory.load_data()
	var viewed: Array = profile.get(VIEWED_KEY, [])
	var added := false
	for id in ids:
		if not viewed.has(id):
			viewed.append(id)
			added = true
	if added:
		profile[VIEWED_KEY] = viewed
		HeartwoodMemory.save_data(profile)
