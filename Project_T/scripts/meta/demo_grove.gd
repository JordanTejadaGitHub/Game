extends RefCounted
class_name DemoGrove

# The demo's small Memory Grove (demo_scope.md cb0e096c, meta_design.md 490a157e "Seeds from the demo, and the
# demo Grove", 5bfb65be "add 1 Warden tree"): in the demo only these nodes can be planted, each up to the level
# here, at full-game costs (375 Seeds in all). Every other node sleeps with a "Full game" tag. One family (Rootling:
# its picks, cards and Blessing; its hidden branch stays asleep), no Blight, 3 loadout slots. It is the full game's profile,
# so what's planted and the Seeds banked carry over; the full game just wakes the rest.

const NODES := {"morning_stores": 1, "deep_taproot": 1, "second_thoughts": 1, "wider_choice": 1,
	"rootling": 1, "sharpened": 1, "seedbed": 1, "scarred_bark": 1}
const ASLEEP := "Full game"  # buy_problem() for a node (or a level) the demo doesn't grow
const LOADOUT_SLOTS := 3
const MEMORIES := 1  # The demo shows Memory 1 only

static func is_active() -> bool:
	return ResultsScreen.is_demo()

# The highest level `unlock` reaches in this edition: all of it in the full game, 0 = asleep in the demo.
static func level_cap(unlock: UnlockData) -> int:
	if not is_active():
		return unlock.get_levels()
	return int(NODES.get(unlock.id, 0))

static func is_asleep(unlock: UnlockData) -> bool:
	return is_active() and not NODES.has(unlock.id)

# Its level in this edition: the profile's, capped in the demo (a full-game profile keeps only the demo's part there).
static func level(data: Dictionary, unlock: UnlockData) -> int:
	var owned := HeartwoodMemory.node_level(data, unlock)
	return mini(owned, level_cap(unlock)) if is_active() else owned

# Node `id` owned in this edition (Main's gates: Wider Choice in the family pick, Rootling in CodexData.scope).
static func owns(id: String) -> bool:
	var unlock := HeartwoodMemory.get_unlock(id)
	return unlock != null and level(HeartwoodMemory.load_data(), unlock) > 0

# Every demo node planted to its demo level: "Your tree keeps growing in the full game."
static func complete(data: Dictionary) -> bool:
	for id in NODES:
		var unlock := HeartwoodMemory.get_unlock(id)
		if unlock == null or HeartwoodMemory.node_level(data, unlock) < int(NODES[id]):
			return false
	return true
