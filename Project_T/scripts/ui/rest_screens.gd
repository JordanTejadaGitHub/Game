class_name RestScreens
extends RefCounted

# One paused screen at a time at a rest (user screenshot: a new-nightmare card opened on top of the Heartwood's Gifts,
# both see-through, two sets of buttons drawn through each other). Every rest screen opens in this order, each only
# once the ones before it are done and nothing else is on screen: family pick → Dream → gift → Omen → boss dossier →
# new-nightmare intros (user, 2026-10-03). The choices open themselves when their system offers; the dossier and the intros
# wait here (BossDossier / NightmareIntro.screens_clear).

# HUD screens that cover the map while open.
const SCREENS := ["FamilyPickScreen", "DreamScreen", "GiftScreen", "OmenScreen", "RememberScreen", "BossDossier",
	"NightmareIntro", "FlyerWarning", "LessonCard", "PauseMenu", "ResultsScreen"]

# Whether a screen covers the map now, for HUD pieces that sit over it (the Coming strip, the boss reminder): a choice
# (Dream, Calling, Omen, family pick, gift), Remember, the boss dossier, an intro, a Lesson, the pause menu or the
# results. "Peek at the map" uncovers the choice screens (planning what's coming is part of choosing); the pause menu and
# the results always cover. `hud` = the HUD node; `except` = a screen not to count (the caller itself). One place, so
# nothing else sets those pieces' visibility (user phone screenshot 2026-10-17: the strip flickered behind a choice).
const ALWAYS_COVER := ["PauseMenu", "ResultsScreen"]
static func covering(hud: Node, except: Node = null, choices_only := false) -> bool:
	if hud == null:
		return false
	var peeking := ChoicePeek.any_peeking()
	for screen_name in SCREENS:
		var screen := hud.get_node_or_null(screen_name) as CanvasItem
		if screen == null or screen == except or not screen.visible:
			continue
		if choices_only and ALWAYS_COVER.has(screen_name):
			continue  # The pause menu and the results aren't choices (choice_locked)
		if peeking and not ALWAYS_COVER.has(screen_name):
			continue
		return true
	return false

# The map's input under a choice screen (user 2026-10-23: "able to hover and select Wardens when the Dream screen is up,
# while not peeking at the map"; a phone tap on "Take" reached "Nurture rank I" under the Calling choice). One rule for
# every world tool (TowerSeller, TowerPlacer, ObstacleClearer, NightmareInfo, the camera), PC and phones:
# - map_blocked: a covering screen is open and not peeking: the map takes no input at all, not even hover.
# - map_locked: that, or a choice is peeking: look and hover only; no selecting, buying, selling, building or Nurture
#   until "Back to …".
static func map_blocked(node: Node) -> bool:
	return covering(hud_of(node))

static func map_locked(node: Node) -> bool:
	return ChoicePeek.any_peeking() or map_blocked(node)

# A choice screen (not the pause menu or the results) is open, peeking or not: TowerSeller closes the Warden panel then.
static func choice_locked(node: Node) -> bool:
	return ChoicePeek.any_peeking() or covering(hud_of(node), null, true)

# The run's HUD from any node in the run's scene (a world tool or a HUD piece), or null.
static func hud_of(node: Node) -> Node:
	var at := node
	while at != null:
		var hud := at.get_node_or_null("HUD")
		if hud != null:
			return hud
		at = at.get_parent()
	return null

# Whether a covering screen other than `caller` is open (a choice screen waits for it before opening).
static func any_open(caller: Node, director: DriftDirector) -> bool:
	var hud := director.owner.get_node_or_null("HUD") if director != null and director.owner != null else null
	for screen_name in SCREENS:
		var screen := hud.get_node_or_null(screen_name) as CanvasItem if hud != null else null
		if screen != null and screen != caller and screen.visible:
			return true
	return false

# Whether `caller` (the boss dossier or a nightmare intro) may open now.
static func clear_for(caller: Node, director: DriftDirector) -> bool:
	if director == null or not caller.is_inside_tree():
		return false
	var hud := director.owner.get_node_or_null("HUD") if director.owner != null else null
	for screen_name in SCREENS:
		var screen := hud.get_node_or_null(screen_name) as CanvasItem if hud != null else null
		if screen != null and screen != caller and screen.visible:
			return false  # Something is already open: never a second one on top
	if director.awaiting_family_pick:
		return false
	var tree := caller.get_tree()
	var dreams := tree.get_first_node_in_group(DreamState.GROUP) as DreamState
	if dreams != null and (dreams.is_offering() or dreams.has_pending_offer()):
		return false
	var gifts := tree.get_first_node_in_group(&"heartwood_gifts")
	if gifts != null and gifts.is_offering():
		return false
	var omens := tree.get_first_node_in_group(OmenDirector.GROUP) as OmenDirector
	if omens != null and (omens.is_offering() or omens.has_pending_offer()):
		return false
	if caller is NightmareIntro:  # The boss dossier comes before the new-nightmare intros (user, 2026-10-03)
		var dossier := tree.get_first_node_in_group(BossDossier.GROUP) as BossDossier
		if dossier != null and dossier.is_waiting():
			return false
	return true
