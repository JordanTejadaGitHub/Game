extends RefCounted
class_name BuffSources

# Where a Warden's power comes from (screens_ui.md "Buff readability"): the one list the Warden panel's
# Buffs section, the buff pips, the source threads, the placement preview and the buff lens all read,
# so they always agree.
#
#   BuffSources.for_tower(tower)          # what boosts it: [{kind, source, stat, amount, position, kindred, …}]
#   BuffSources.given_by(support)         # who a support Warden boosts, and by how much
#   BuffSources.would_receive(data, at)   # the build ghost / a growth: what it would get there
#   BuffSources.would_give(data, at)      # a support ghost: who it would boost there
#
# Entry fields: kind (acorn / elder_stump / grove_heart / grandmother_oak / old_growth / kinship /
# kindred / whole_tree / kin_cards / rank / focus / dream / omen / penalty), source (the Warden, or
# null), stat ("damage", "attack_speed", "range", "aura", "catch" or "" for a trait), amount (fraction;
# range in cells), position (1st, 2nd… in its aura kind's falloff; 0 = none / Kindred), kindred, relayed
# (Hedgerow Roots: through a Thornwall), label (the panel's words), negative.

const AURA_KINDS := ["acorn", "elder_stump", "grove_heart", "grandmother_oak", "old_growth"]
const LOCAL_KINDS := ["acorn", "elder_stump", "grove_heart", "grandmother_oak", "old_growth", "kinship", "kindred", "whole_tree"]
# One colour per source kind (pips, threads, aura tints, panel rows): auras the Acorn family's gold (shaded
# per Warden so two kinds stay apart), Whole Tree green-gold; Kinships use their family's colour.
const COLORS := {
	"acorn": Palette.GLOW, "elder_stump": Palette.GOLD, "grove_heart": Palette.HEARTLIGHT,
	"grandmother_oak": Palette.DEADWOOD, "old_growth": Palette.NEWLEAF, "kinship": Palette.NEWLEAF,
	"kindred": Palette.MOONPATH, "whole_tree": Palette.SPRIG, "kin_cards": Palette.NEWLEAF,
	"rank": Palette.MOONPATH, "focus": Palette.MOONPATH, "dream": Palette.MIST,
	"omen": Palette.STONE, "penalty": Palette.EMBER,  # Ember: the palette's "bad" colour (no red)
}
const STAT_WORDS := {"damage": "damage", "attack_speed": "attack speed", "range": "range", "aura": "aura", "catch": "catch"}
const ORDINALS := ["", "", "2nd", "3rd", "4th", "5th", "6th"]

static func color(kind: String, source: Node = null) -> Color:
	if kind == "kinship" and source is Tower:
		return Kinships.FAMILY_COLORS.get(source.tower_data.line, COLORS.kinship)
	return COLORS.get(kind, Palette.MOONPATH)

# --- One Warden --------------------------------------------------------------------------------------

static func for_tower(tower: Tower) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not is_instance_valid(tower):
		return result
	# Auras, per kind in falloff order (Tower._stack_auras keeps each giver's share).
	for source in tower._aura_sources:
		if not is_instance_valid(source.tower):
			continue
		for stat in ["damage", "speed"]:
			var amount: float = source[stat]
			if amount <= 0.0:
				continue
			var entry := _entry(source.kind, source.tower, "damage" if stat == "damage" else "attack_speed", amount)
			entry.position = source.position
			entry.kindred = source.kindred
			entry.relayed = source.relayed
			entry.label = _aura_label(source.tower, source.kind, entry)
			result.append(entry)
	# Kinships: the bond (traits, no number), then Kindred / Whole Tree and the Kinship cards.
	var kin := Kinships.find(tower)
	if kin != null:
		for pair in kin.get_pairs(tower):
			var partner: Tower = pair.b if pair.a == tower else pair.a
			var entry := _entry("kinship", partner, "", 0.0)
			entry.label = "Kinship %s (%s, %d%%)" % [Kinships.KINSHIPS[pair.id][0], Kinships.STAGE_NAMES[kin.get_stage(pair)],
				roundi(Kinships.STAGE_SHARE[kin.get_stage(pair)] * 100.0)]
			result.append(entry)
		var family := kin.family_bonus(tower.tower_data.line)
		if family > 0.0:
			var whole := family >= Kinships.WHOLE_TREE_BONUS - 0.0001 and Kinships.WHOLE_TREE_BONUS > Kinships.KINDRED_BONUS
			var entry := _entry("whole_tree" if whole else "kindred", null, "damage", family)
			entry.label = "%s %s damage" % ["Whole Tree" if whole else "Kindred", _signed(family)]
			result.append(entry)
		var cards := kin.damage_bonus(tower) - family
		if absf(cards) > 0.0001:
			var entry := _entry("kin_cards" if cards > 0.0 else "penalty", null, "damage", cards)
			entry.label = "Kinship Dreams %s damage" % _signed(cards)
			entry.negative = cards < 0.0
			result.append(entry)
	# Nurture and Focus.
	if tower.rank > 0:
		var entry := _entry("rank", null, "", 0.0)
		if tower.is_aura_support():
			entry.stat = "aura"
			entry.amount = pow(Tower.AURA_PER_RANK, tower.get_effective_rank()) - 1.0
		elif tower.is_catcher():
			entry.stat = "catch"
			entry.amount = tower.tower_data.catch_per_rank * tower.get_effective_rank()
		else:
			entry.stat = "damage"
			entry.amount = tower.get_rank_damage_multiplier() - 1.0
		entry.label = "Rank %s%s" % [Tower.rank_name(tower.rank),
			" (%s)" % Tower.FOCUS_NAMES[tower.focus] if tower.focus != Tower.Focus.NONE else ""]
		result.append(entry)
	# Dreams on this Warden (DreamState rows: position and run-wide cards).
	var dreams := tower._dream_state
	if dreams != null and dreams.has_method("get_card_effects"):
		for row in dreams.get_card_effects(tower.tower_data, tower.cell, tower):
			if not row.get("active", false):
				continue
			for key in [["damage", "damage"], ["speed", "attack_speed"], ["range", "range"]]:
				var amount: float = row.get(key[0], 0.0)
				if amount == 0.0:
					continue
				var entry := _entry("dream" if amount > 0.0 else "penalty", null, key[1], amount)
				entry.label = "Dream %s %s %s" % [row.name, _signed(amount, key[1] == "range"), STAT_WORDS[key[1]]]
				entry.negative = amount < 0.0
				result.append(entry)
	# Omens and other penalties (a Lamplighter's cold lantern).
	var omens = tower._omens
	if omens != null and omens.has_method("get_warden_speed_multiplier"):
		var speed: float = omens.get_warden_speed_multiplier() - 1.0
		if absf(speed) > 0.0001:
			var entry := _entry("omen" if speed > 0.0 else "penalty", null, "attack_speed", speed)
			entry.label = "Omen %s attack speed" % _signed(speed)
			entry.negative = speed < 0.0
			result.append(entry)
	if omens != null and omens.has_method("get_warden_range_add"):
		var reach: float = omens.get_warden_range_add()
		if absf(reach) > 0.0001:
			var entry := _entry("omen" if reach > 0.0 else "penalty", null, "range", reach)
			entry.label = "Omen %s range" % _signed(reach, true)
			entry.negative = reach < 0.0
			result.append(entry)
	if tower.dim_multiplier < 0.999:
		var entry := _entry("penalty", null, "attack_speed", tower.dim_multiplier - 1.0)
		entry.label = "Cold lantern %s attack speed" % _signed(tower.dim_multiplier - 1.0)
		entry.negative = true
		result.append(entry)
	return result

# The local sources as pips: [[kind, count, a source Warden], …] (Global Dreams and Omens aren't pips).
# Cheap on purpose (the overlay draws every Warden's pips at rests): only the local sources, never the
# Dream rows or Omens that for_tower also reads.
static func pips(tower: Tower) -> Array:
	var counts := {}
	var order: Array = []
	for entry in _local_entries(tower):
		var key: String = entry.kind
		if not counts.has(key):
			counts[key] = [key, 0, entry.source]
			order.append(key)
		if entry.source == null or not _counted(counts[key], entry.source):
			counts[key][1] += 1
			counts[key].append(entry.source)
	return order.map(func(k: String) -> Array: return counts[k].slice(0, 3))

# The local buff sources only: auras (Tower._aura_sources), the Kinship bond, Kindred / Whole Tree.
static func _local_entries(tower: Tower) -> Array:
	var result := []
	for source in tower._aura_sources:
		if is_instance_valid(source.tower) and (source.damage > 0.0 or source.speed > 0.0):
			result.append({"kind": source.kind, "source": source.tower})
	var kin := Kinships.find(tower)
	if kin != null:
		for pair in kin.get_pairs(tower):
			result.append({"kind": "kinship", "source": pair.b if pair.a == tower else pair.a})
		var family := kin.family_bonus(tower.tower_data.line)
		if family > 0.0:
			result.append({"kind": "whole_tree" if family >= Kinships.WHOLE_TREE_BONUS - 0.0001 else "kindred", "source": null})
	return result

static func _counted(row: Array, source: Node) -> bool:
	return row.slice(3).has(source)

# The total the Buffs section closes with: {stat: fraction}.
static func totals(entries: Array) -> Dictionary:
	var sum := {}
	for entry in entries:
		if entry.stat != "" and entry.stat != "aura" and entry.stat != "catch":
			sum[entry.stat] = float(sum.get(entry.stat, 0.0)) + entry.amount
	return sum

# --- A support Warden ----------------------------------------------------------------------------------

# Who `support` boosts: [{target, damage, speed, position, kindred}], plus the Wardens it covers but adds
# nothing to (capped, or not attackers) with damage and speed 0 ("—").
static func given_by(support: Tower) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not is_instance_valid(support) or support.get_parent() == null:
		return result
	var reach := support.get_aura_reach()
	for other in support.get_parent().get_children():
		if not (other is Tower) or other == support or other.is_queued_for_deletion():
			continue
		var given := {}
		for source in other._aura_sources:
			if source.tower == support:
				given = source
		var covered: bool = other.global_position.distance_to(support.global_position) / Tower.MAP_GRID.cell_size.x <= reach + 0.001
		if given.is_empty() and not covered:
			continue
		result.append({"target": other, "damage": given.get("damage", 0.0), "speed": given.get("speed", 0.0),
			"position": given.get("position", 0), "kindred": given.get("kindred", false), "relayed": given.get("relayed", false)})
	return result

# --- Previews (the build ghost, grow and nurture) --------------------------------------------------------

# What a Warden of `data` would receive from the auras around `centre` (world): entries like for_tower's
# aura ones, falloff worked out among the givers of each kind.
static func would_receive(data: TowerData, centre: Vector2, towers: Array) -> Array[Dictionary]:
	var kinds := {}
	for other in towers:
		if not (other is Tower) or not AuraView.is_aura(other.tower_data):
			continue
		if other.global_position.distance_to(centre) / Tower.MAP_GRID.cell_size.x > other.get_aura_reach() + 0.001:
			continue
		var kind: String = other.tower_data.get_id()
		if not kinds.has(kind):
			kinds[kind] = []
		kinds[kind].append([other, other.get_aura_bonus(false), other.get_aura_bonus(true)])
	var result: Array[Dictionary] = []
	for kind in kinds:
		var list: Array = kinds[kind]
		list.sort_custom(func(a: Array, b: Array) -> bool: return maxf(a[1], a[2]) > maxf(b[1], b[2]))
		var weight := 1.0
		var position := 0
		for item in list:
			var giver: Tower = item[0]
			var kindred := giver.focus == Tower.Focus.KINDRED and giver.is_aura_support()
			var share := 1.0 if kindred else weight
			if not kindred:
				weight *= Tower.AURA_FALLOFF
				position += 1
			for stat in [[1, "damage"], [2, "attack_speed"]]:
				if item[stat[0]] > 0.0:
					var entry := _entry(kind, giver, stat[1], item[stat[0]] * share)
					entry.position = 0 if kindred else position
					entry.kindred = kindred
					entry.label = _aura_label(giver, kind, entry)
					result.append(entry)
	return result

# Who a support Warden of `data` at `centre` would boost, and by how much (after falloff):
# [{target, damage, speed, position}].
static func would_give(data: TowerData, centre: Vector2, towers: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not AuraView.is_aura(data):
		return result
	var reach := data.aura_radius if data.aura_radius > 0.0 else data.attack_range
	var bonus := maxf(data.aura_damage_bonus, data.aura_speed_bonus)
	for tower in towers:
		if not (tower is Tower) or tower.global_position.distance_to(centre) / Tower.MAP_GRID.cell_size.x > reach + 0.001:
			continue
		var weight := 1.0
		var position := 1
		for source in tower._aura_sources:
			if source.kind == data.get_id() and not source.kindred and is_instance_valid(source.tower) \
					and maxf(source.tower.get_aura_bonus(false), source.tower.get_aura_bonus(true)) >= bonus:
				weight *= Tower.AURA_FALLOFF
				position += 1
		result.append({"target": tower, "damage": data.aura_damage_bonus * weight, "speed": data.aura_speed_bonus * weight,
			"position": position})
	return result

# "+30% attack speed from 2 Elder Stumps · +5% damage from an Acorn": aura entries summed per kind.
static func summary(entries: Array) -> String:
	var kinds := {}
	var order: Array = []
	for entry in entries:
		if not AURA_KINDS.has(entry.kind) or entry.stat == "":
			continue
		var key: String = "%s|%s" % [entry.kind, entry.stat]
		if not kinds.has(key):
			kinds[key] = [entry, 0.0, {}]
			order.append(key)
		kinds[key][1] += entry.amount
		kinds[key][2][entry.source] = true
	var parts: Array[String] = []
	for key in order:
		var row: Array = kinds[key]
		var count: int = row[2].size()
		var name: String = _kind_name(row[0].kind, row[0].source)
		parts.append("%s %s from %s" % [_signed(row[1]), STAT_WORDS[row[0].stat],
			("%d %ss" % [count, name]) if count > 1 else ("an " + name if name[0].to_lower() in "aeiou" else "a " + name)])
	return " · ".join(parts)

# --- Helpers ---------------------------------------------------------------------------------------------

static func _entry(kind: String, source: Node, stat: String, amount: float) -> Dictionary:
	return {"kind": kind, "source": source, "stat": stat, "amount": amount, "position": 0, "kindred": false,
		"relayed": false, "label": "", "negative": amount < 0.0}

static func _kind_name(kind: String, source: Node) -> String:
	if source is Tower:
		return source.tower_data.display_name
	return kind.capitalize()

# "Elder Stump (rank IV, Kindred) +26% attack speed", "Elder Stump +10% attack speed (2nd)".
static func _aura_label(giver: Tower, kind: String, entry: Dictionary) -> String:
	var notes: Array[String] = []
	if giver.rank > 0:
		notes.append("rank %s" % Tower.rank_name(giver.rank))
	if entry.kindred:
		notes.append("Kindred")
	var name := "Old Growth" if kind == "old_growth" else giver.tower_data.display_name
	var text := "%s%s %s %s" % [name, " (%s)" % ", ".join(notes) if not notes.is_empty() else "", _signed(entry.amount),
		STAT_WORDS[entry.stat]]
	if entry.position >= 2:
		text += " (%s, falloff)" % ORDINALS[mini(entry.position, ORDINALS.size() - 1)]
	return text

# The thread label: "+20%", "+10% (2nd stump)", "Kindred +26%".
static func thread_label(entry: Dictionary) -> String:
	var amount := _signed(entry.get("amount", maxf(entry.get("damage", 0.0), entry.get("speed", 0.0))))
	if entry.get("kindred", false):
		return "Kindred " + amount
	var position: int = entry.get("position", 0)
	return amount + (" (%s)" % ORDINALS[mini(position, ORDINALS.size() - 1)] if position >= 2 else "")

static func _signed(amount: float, cells: bool = false) -> String:
	if cells:
		return "%s%.1f" % ["+" if amount >= 0.0 else "−", absf(amount)]
	return "%s%d%%" % ["+" if amount >= 0.0 else "−", roundi(absf(amount) * 100.0)]
