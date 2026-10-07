class_name RestScreens
extends RefCounted

# One paused screen at a time at a rest (user screenshot: a new-nightmare card opened on top of the Heartwood's Gifts,
# both see-through, two sets of buttons drawn through each other). Every rest screen opens in this order, each only
# once the ones before it are done and nothing else is on screen: family pick → Dream → gift → Omen → boss dossier →
# new-nightmare intros (user, 2026-10-03). The choices open themselves when their system offers; the dossier and the intros
# wait here (BossDossier / NightmareIntro.screens_clear).

# HUD screens that cover the map while open.
const SCREENS := ["FamilyPickScreen", "DreamScreen", "GiftScreen", "OmenScreen", "RememberScreen", "BossDossier",
	"NightmareIntro", "LessonCard", "PauseMenu", "ResultsScreen"]

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
