# Heartwood's Gifts (experiment/spire-difficulty)

Owner: design hub (story chat). Replaces the per-rest "rest choices" (Rest / Tend / Dream) of
`spire_difficulty.md` Phase 3 (user, 2026-10-02: *"don't want it to be exactly like Slay the Spire"*;
*"I do like the gift options that change the map after an act. We need more options though"*).

## The rule

- **When:** once per act break: the rests after the bosses at 25, 50 and 75 (3 gifts a run). After the
  Dream and the family pick, before the Omen.
- **The offer:** 3 gifts drawn from the pool below, **at least 2 that change the map**. **Every gift gives something** (user, 2026-10-06: "not have any that just only places trees and logs, everything would give buffs or more resources"): a map gift always comes with a buff or a resource, never terrain alone. Never the same
  gift twice in a run. Pick 1, or let them pass for a small Dew sum (like a Dream).
- **Placing:** map gifts are placed on the gift screen itself, with a ghost preview: the route mist shows the
  new route, the "+N path" tag updates, and invalid cells are refused exactly like Warden placement (never
  closing the route, never on the start or the Heartwood glade's inner ring, never on a Warden). Esc goes
  back to the three cards.
- **Why it's ours, not Slay the Spire's:** every gift is about the forest and the maze: terrain, routes,
  living ground that feeds Wardens. No heal, no flat upgrade.
- **Demo:** off (the demo stays on main's rules).

## The pool (18)

### Shape the land (route and space)
| Gift | What it does |
|---|---|
| **Sow a Ridge** | Draw a ridge of 3–5 Withered Trees, cell by cell (adjacent cells). **Sheltered:** Wardens touching the ridge deal +10% damage. Each of its trees gives **+2 Seeds** when tended (instead of 1). Clearable at the normal cost (the bonus goes with the tree). |
| **Fallen Giant** | Lay a fallen log 2–4 cells long, straight, where you choose; it can't be cleared this run. **High ground:** Wardens touching the log get +0.5 range. **Snag:** nightmares walking beside it move 15% slower there. |
| **Glade** | Clear **up to 5 obstacles of your choice**, free; each still counts as tended (+1 Seed). Pick them one by one on the gift screen (gold outline + ×, click again to unselect; counter "3 of 5 · −6 path"; the route mist previews live); "Clear them" confirms. (Revised 2026-10-03, user: the radius version "didn't feel right and was unintuitive"; as built 3ab8abee.) |
| **Shift the Stones** | Move up to 3 obstacles to new empty cells. Each one moved pays **+20 Dew × act**, and the ground it leaves is **fertile**: the next Warden planted there costs half. |
| **Mire** | Pick 3 connected path cells: the ground turns to bog, and nightmares move 20% slower there. |

### Living ground (terrain that feeds Wardens)
| Gift | What it does |
|---|---|
| **Spring** | A 2×2 pond where you choose (unbuildable). Water Wardens next to it deal +20%, and Soaked lasts 1 s longer on nightmares within 2 cells. |
| **Mushroom Ring** | A ring of toadstools on a 3×3 patch. Spore Wardens planted touching it get +2 Poisoned cap. |
| **Lightning Tree** | A dead tree you place (an obstacle). Charged bolts within 2 cells of it deal +25%. |
| **Moonwell** | A lit stone cell (unbuildable). Wardens within 1 cell get +1 range. |
| **Bell Stone** | A singing stone. Song Wardens within 1 cell pulse 15% faster. |
| **Ancient Stump** | 3 stumps you place: a Warden planted on a stump starts at rank I. |

### The nightmares' way
| Gift | What it does |
|---|---|
| **Heartwood Roots** | Roots grow over the last 4 path cells before the Heartwood: nightmares there take +15% damage. |
| **Thick Mist** | For the next act, nightmares leave the start mist 25% further apart. |
| **Bramble Verge** | Thornwalls cost half this run, and nightmares touching one gain +1 Drowsy cap. |

### Heartwood and kin
| Gift | What it does |
|---|---|
| **Old Kin** | One Kinship you choose jumps a stage, and new bonds start one stage up for the next act. |
| **Shifting Mist** | The start mist moves. 3 spots on the island's rim are offered (the MapLayout rules: on the rim, far enough from the Heartwood), each previewed with its route mist and path length; pick one, or keep the old start. Nightmares arrive from there for the rest of the run, so your maze faces a new way. Bridge and mist move with it. **Fresh ground:** this act's Dew pots are +10%. (Replaces Deeper Glade, 2026-10-04, user: "seems useless".) |
| **Waking Root** | The next form you unlock on the Remember screen costs 1 less Dreamlight. |
| **Memory Seed** | Choose a Warden: this act, selling and replanting it keeps its ranks and Kinship age (move it freely at rests). |

## Notes for the code chats
- New terrain uses existing systems where it can: ponds and logs (Environment's features), obstacles
  (`ObstacleData`), path modifiers via `MapGenerator` (route rules unchanged).
- New art: Lightning Tree, Moonwell, Bell Stone, Mushroom Ring, Heartwood Roots, bog path, Ancient Stump
  (Environment Assets; Heartwood 32, the act's sheets).
- Everything saved in the run save. Each gift is a card on the gift screen (Moonlit Thread), with an
  animated mini-scene like the placement Dream cards.
- Numbers are starting points; Balancing Discussion tunes them.
