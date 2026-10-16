class_name WardenRoles
extends RefCounted
# What job a Warden form does, read from its data (card pass 2026-10-16, council card_pass_td.md 1d): cards that pay off
# a branch choice ask for a role, never a form id, so every form with that job counts, and a Graftling copying one
# counts too (pass its attack_data). Roles: heavy, area, chain, beam, trap, pull, hold, sniper, support.

const HEAVY := &"heavy"
const AREA := &"area"
const CHAIN := &"chain"
const BEAM := &"beam"
const TRAP := &"trap"
const PULL := &"pull"
const HOLD := &"hold"
const SNIPER := &"sniper"
const SUPPORT := &"support"
const ALL: Array[StringName] = [HEAVY, AREA, CHAIN, BEAM, TRAP, PULL, HOLD, SNIPER, SUPPORT]

static func roles(data: TowerData) -> Array[StringName]:
	var out: Array[StringName] = []
	if data == null:
		return out
	for role in ALL:
		if has_role(data, role):
			out.append(role)
	return out

static func has_role(data: TowerData, role: StringName) -> bool:
	if data == null:
		return false
	match role:
		HEAVY:
			return data.heavy  # (Shatter's own "heavy" still reads stone line / target priority: Tower Code to unify)
		AREA:
			return HelperCommons.is_area_attack(data)
		CHAIN:
			return data.attack_kind == TowerData.AttackKind.CHAIN  # (chain_targets defaults to 3 on every form)
		BEAM:
			return data.attack_kind == TowerData.AttackKind.BEAM
		TRAP:
			return data.attack_kind == TowerData.AttackKind.TRAP
		PULL:
			return data.pull_tiles > 0.0 or data.attack_kind == TowerData.AttackKind.PULL
		HOLD:
			return data.hold_targets > 0
		SNIPER:
			return data.min_range > 0.0 or data.has_target_priority
		SUPPORT:
			return data.aura_radius > 0.0 or data.attack_kind == TowerData.AttackKind.AURA or data.role_tag == &"support" \
				or data.caught_bonus > 0.0
	return false

# The plain word a card shows for a role ("a heavy Warden", "an area Warden").
static func label(role: StringName) -> String:
	match role:
		HEAVY: return "a heavy Warden"
		AREA: return "an area Warden"
		CHAIN: return "a chain Warden"
		BEAM: return "a beam Warden"
		TRAP: return "a trap Warden"
		PULL: return "a Warden that pulls"
		HOLD: return "a Warden that holds"
		SNIPER: return "a long-range Warden"
		SUPPORT: return "a support Warden"
	return String(role)
