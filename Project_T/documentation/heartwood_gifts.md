# Heartwood's Gifts (experiment/spire-difficulty)

Owner: design hub (story chat). Replaces the per-rest "rest choices" (Rest / Tend / Dream) of
`spire_difficulty.md` Phase 3 (user, 2026-10-02: *"don't want it to be exactly like Slay the Spire"*;
*"I do like the gift options that change the map after an act. We need more options though"*).

## The rule

- **When:** once per act break: the rests after the bosses at 25, 50 and 75 (3 gifts a run). After the
  Dream and the family pick, before the Omen.
- **The offer:** 3 gifts drawn from the pool below, **at least 2 that change the map**. Never the same
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
| **Sow a Ridge** | Draw a ridge of 3–5 Withered Trees, cell by cell (adjacent cells). Clearable later at the normal cost. |
| **Fallen Giant** | Lay a fallen log 2–4 cells long, straight, where you choose. It can't be cleared this run. |
| **Glade** | Clear every obstacle within 2 cells of a chosen cell, free; each one still counts as tended (+1 Seed). |
| **Shift the Stones** | Move up to 3 obstacles to new empty cells. |
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
| **Deeper Glade** | The Heartwood's glade grows by one ring of clear cells (more room to wall it in), and +1 max leaf. |
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
