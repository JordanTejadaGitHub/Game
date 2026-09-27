extends RefCounted
class_name Synergies

# Which Wardens combo with which (tower_design.md "Status effects": towers interact through the
# nightmare). A Warden that applies a status combos with the Wardens that pay that status off.
# Used for placement links on the build ghost and the Warden panel's "Combos with" line.

# Status -> Warden ids that pay it off (only Wardens that exist are ever matched).
const PAYOFFS := {
	&"damp": ["stormcap", "thunderhead", "frostfern", "hoarfrost"],
	&"drowsy": ["mossback", "boulderback", "dreamshroom", "sunpetal", "midsummer"],
	&"spored": ["puffball", "mistveil", "rootcurl", "long_way_home"],
	&"marked": ["mossback", "boulderback", "standing_stone", "moonstone"],
	&"static": ["chime_stone", "lullaby_bell"],
	&"held": ["bloomcap", "mistveil", "chime_stone", "bramble", "sunpetal", "hoarfrost", "standing_stone"],
}
const LINK_RANGE := 1.0  # Cells beyond the larger attack range that still count as "nearby"

# How `a` and `b` combo, e.g. "Damp → Stormcap", or "" if they don't.
static func link(a: TowerData, b: TowerData) -> String:
	for pair in [[a, b], [b, a]]:
		var applier: TowerData = pair[0]
		var payoff: TowerData = pair[1]
		var status := applier.applies_status
		if status != &"" and PAYOFFS.get(status, []).has(payoff.get_id()):
			return "%s → %s" % [String(status).capitalize(), payoff.display_name]
	return ""

# Wardens in `towers` near `cell` that combo with `data`: [[Tower, description], …].
static func find_links(data: TowerData, cell: Vector2, towers: Array) -> Array:
	var result := []
	for tower in towers:
		if not tower is Tower or tower.is_queued_for_deletion() or tower.cell == cell:
			continue
		var reach := maxf(data.attack_range, tower.tower_data.attack_range) + LINK_RANGE
		if tower.cell.distance_to(cell) > reach:
			continue
		var description := link(data, tower.tower_data)
		if description != "":
			result.append([tower, description])
	return result
