# Spire Difficulty

**Status: in main** (merged bebfb22c, 2026-10-02, user: "just merge the Slay branch with main"). The
**full game** uses these rules; the **demo** keeps the old ones (`DriftDirector.DEMO_RULES`: act 1 ramp
from 9, act 2 from 1.7 via 3.3, act 4 ×1.0, full Dew pots, no block finales; gifts and the branch
expansion off). Built and live in the full game: Phases 1–4 and branch expansion phase 1. **Still the
plan:** Blight 11–20 (Phase 5) and branch expansion phases 2–3. Work continues on main; the experiment
branch stays until the user says. Owner: Balancing Discussion (numbers); code by the owning chats.
Started 2026-10-02.

User: *"Make it feel like Slay the Spire difficulty."* Tried on a branch first. Direction (user,
2026-10-02): **"Spire difficulty, ladder and decision focus, plus a small, capped Grove power,
Hades-style."**

## Targets

| | Target |
|---|---|
| Average player | **first win after ~10–15 runs** |
| Skilled player, Blight 0 | **wins ~30–50%** |
| Fresh profile | usually dies in **act 2–3** |
| Act 4 | a real test, not a victory lap |
| Every block | **can kill you**: no safe stretch, no single wall |
| Grove | **mostly options; a small, capped power** (Hades' Mirror): a full loadout adds **+10–15 points** of bot survival / reach over no perks, no more |
| Blight Levels | the Ascension ladder after the first win: **one clear new problem per level**, up to 20 |
| Demo | stays on **main's curve** |

What Slay the Spire does that we copy: every fight costs something; HP carries over and healing is a
choice that costs power; elites are spikes with better rewards; each act ends in a boss that checks the
deck; Ascension adds one named problem per level.

**Difficulty comes from decisions, not only health.** After the first human runs on the branch, prefer
composition levers (more mixed rule-breakers, a targeted counter per block) and scarcity (the Dew pot
−10% stays) over more health multipliers. Act 2's ×4.5 comes down if it plays spongy.

## Phase 1: the curve (playable, fd776918)

| Lever | Main | Spire branch (live) |
|---|---|---|
| Act 1 ramp | ×1.0 to drift 9 → ×1.15 at 20 | **×1.0 at drift 3 → ×1.15 at 20**, held to 24 |
| Act 2 | 1.7 at 26 → 4.5 at 45, linear | **2.0 at 26 → 4.5 at 45**, linear (`act2_steep_value` 3.45) |
| Acts 3–4 | ×6.0 both | ×6.0 act 3, **act 4 ×7.2** (`act4_health_multiplier` 1.2) |
| **Block finales** (last drift of each block, not boss drifts) | — | from drift 10: **every nightmare ×1.4 health** (`block_finale_health_multiplier`) and guaranteed elites **1 / 2 / 3 / 4 from drift 10 / 15 / 30 / 60** (`block_finale_elites`) |
| Dew pot | run_design.md | **acts 2–4 −10%** (bosses 243 / 288) |
| Bosses, bites, Oak | 1.75 / 1.75 / 3.0; bites 10 / 10 / 12 | unchanged |

Bot (fresh, 20 seeds): survives the act 1 boss ~50–55% with Dreams, ~5% skipping; a finale costs ~1
leaf. The user's runs judge from here.

## Phase 2: finale rewards (decision: risk the finale clean)

A block finale **cleared clean** (no leaf lost on the finale drift) earns **one Rare+ slot in the next
Dream** (the rest right after it). Chosen over +1 Dreamlight because Dreamlight is kept scarce
(1 + 3 per act). The finale banner says it before the drift ("Finale: clear it clean for a Rare
dream"); the rest report says whether it was earned. Code: Roguelite Code (DreamState: the slot,
DriftDirector: finale cleared clean) + Main Merger (banner, rest report).

## Phase 3: Heartwood's Gifts (replaces the per-rest choices)

User, 2026-10-02: drop Rest / Tend / Dream (too close to Spire's campfire; rests are busy). Instead,
**once per act break (after the bosses at 25 / 50 / 75), pick 1 of 3 gifts** from an 18-gift pool that
mostly reshapes the map. Spec: `heartwood_gifts.md` (design hub, 449c7437). The rest-choice code is
removed from the branch; Roguelite's `add_next_offer_cards` may stay unused.

**Numbers (Balancing Discussion, starting values):**

| Gift | Number |
|---|---|
| Let them pass | **+30 Dew × act** |
| Sow a Ridge | 3–5 Withered Trees |
| Fallen Giant | 2–4 cells, never clearable this run |
| Glade | radius 2, free, each counts as tended |
| Shift the Stones | up to 3 obstacles |
| Mire | 3 path cells, nightmares **−20% speed** there (respects the slow floors) |
| Spring | 2×2 pond; adjacent water Wardens **+20% damage**; Soaked **+1 s** within 2 cells |
| Mushroom Ring | 3×3; spore Wardens touching it **+2 Poisoned cap** |
| Lightning Tree | Charged bolts within 2 cells **+25%** |
| Moonwell | Wardens in the **4 orthogonal** cells **+1 range** (not all 8: +1 range on 8 Wardens is too much) |
| Bell Stone | song Wardens within 1 cell pulse **15% faster** |
| Ancient Stump | **3** stumps; a Warden planted on one starts at **rank I** |
| Heartwood Roots | last **4** path cells, nightmares take **+15%** |
| Thick Mist | next act, spawn spacing **×1.25** |
| Bramble Verge | Thornwalls **half cost**; nightmares touching one **+1 Drowsy cap** |
| Old Kin | one Kinship **+1 stage**; new bonds start **+1 stage** next act |
| Deeper Glade | glade **+1 ring**; **+1 max leaf** (the only leaf gift; a max, not a regrow) |
| Waking Root | next unlock **−1 Dreamlight** |
| Memory Seed | one Warden keeps ranks + Kinship age when sold and replanted, this act |

Judged by human runs (which gifts get picked, and whether a pick changes how the act plays); a gift
nobody picks gets a bigger number, one always picked a smaller one.
## Phase 4: Grove power, capped (with Meta Game Discussion)

Model: **most perks are sidegrades** (Meta Game Discussion's table below); **a few stay honest
power**; a full loadout's total power is capped at **+10–15 points** of bot survival / reach over no
perks (Balancing Code measures full loadout vs none, fresh-equivalent families). Switch kept for
comparison: `MetaRun.sidegrade_perks` (Developer setting "Perk style: Power / Sidegrade"); on the branch
it's on, and the perks listed as **power** ignore it.

**Honest power perks** (Meta Game Discussion, 2026-10-02: the new-player rescues): **Morning Stores
I–III** (+10/20/30 starting Dew), **Deep Taproot I–II** (+1/+2 max leaves, act-break regrow kept; level
III dropped in this mode), **Rested Roots I–II** (rest bonus +10/20%). Over the cap: trim Morning Stores
to +5/10/15 first, then Rested Roots to +5/10%; leaves last. Under the cap is fine (it's a ceiling).

| Perk | Power (main) | Branch |
|---|---|---|
| Morning Stores I–III | +10/20/30 starting Dew | **power** |
| Rich Dew I–III | Dew pot +5/10/15% | sidegrade: same, rest bonus −10/20/30% |
| Rested Roots I–II | rest bonus +10/20% | **power** |
| Deep Taproot I–III | +1/2/3 max leaves | **power, I–II only** |
| Sprout Bed | 2 free Sprouts | 2 Sprouts planted where you choose at the start, 30 less starting Dew |
| First Care | first 3 Nurture ranks free | sidegrade: same, then Nurture +15% for the run |
| Early Bloom | first pick shows every unlocked family | same, the drift 25 pick shows one fewer |
| Early Light | +1 Dreamlight at start | same, the first family pick gives none |
| Kindling | a random Common Dream at start | same, the first Dream offer has 2 cards |
| Clear Sight | start holding Heartwood's Reach | same, and the map rolls one extra ridge (stacks with Blight 9; cap +2 ridges if generation breaks) |
| Wider Dreams | 4 cards per Dream | same, "Let it pass" gives no Dew |
| Seed Pouch, Second Thoughts, Let Go, Omen Reader, slots 4/5/6 | options / meta | unchanged |

## Phase 5: Blight Levels 1–20 (the Ascension ladder)

Unlocked by the first win, as now. Levels 1–10 stay as in meta_design.md. New levels, one named
problem each:

| Level | Adds |
|---|---|
| 1–10 | as meta_design.md (health, no first-pick Dreamlight, boss health, rest bonus, Deeply Blighted, no act-break leaf, speed, lean Dreams, costly clears + ridge, the Oak's second phase) |
| 11 | **Wounded Heartwood:** start with 12 of 15 leaves |
| 12 | **Hungry bosses:** boss bites +2 leaves |
| 13 | **Thin omens:** one Omen offered (plus Clear Skies) |
| 14 | **Dry season:** Dew pot −10% |
| 15 | **Restless elites:** every elite gains a random trait (fast, shielded or splitting) |
| 16 | **Early nightmares:** each new nightmare type arrives 5 drifts sooner |
| 17 | **Dear walls:** Sprouts and Thornwalls +5 Dew |
| 18 | **Narrow dreams:** Dream offers show 2 cards |
| 19 | **Quick fury:** boss abilities "at 50% health" trigger at 75% |
| 20 | **The Hollow's court:** drift 100 adds an echo of an act boss beside the Hollow Oak |

+10% Seeds per level as now. With rest choices in, consider level 11 or 12 → **"Rest regrows
nothing"** instead.

## Phase 6: branch expansion (Tower Discussion, tower_design.md 46ba53c0)

User-approved: each family gets **5 branches + a hidden one**; a run **offers 2** of them (a smart draw),
plus Lucid Dream, generic Kin, and a **Dreamlight call-back** for a branch that wasn't offered (once per
family per run). Its first step: the **4 starting families**, built on this branch only.

Balancing sets: the new branches' numbers (branch probe: 0.5–1.0× Driftspore for damage branches, board
lift for supports), the **call-back cost (start at 2–3 Dreamlight)**, and the **Dreamlight budget** with
2 offered branches (today: 1 at the first pick + 3 per act boss). Numbers arrive from Tower Discussion.

**Numbers (Balancing Discussion, 2026-10-02; starting values, the branch probe checks them).** All new
branches grow for 120 Dew (tier 2), finals for 300 (tier 3), ranges as their family base unless given.

| Branch → final | Branch stats | Final stats + twist |
|---|---|---|
| Lichenling → Old Lichen | projectile 16 dmg, 1.5/s, Spored 1; Spored ticks strip **1% of a dread shell / coat** and block healing | 32 dmg, 1.5/s, Spored 2; at **8 stacks** a shell cracks off |
| Brood Cap → Hatchery | a sprite every **2.0 s** (max 4 alive), walks up the path at 3 tiles/s, bursts for **20** + Spored 2 | every **1.5 s**, **40** + Spored 3; every 5th is big and splits into 3 |
| Inkcap → Deliquescent | projectile 18 dmg, 1.0/s, Spored 1; a Poisoned nightmare leaves ink for **2 s**: +1 Spored per s to walkers | 36 dmg; a dispelled Poisoned nightmare leaves a **2-tile pool for 4 s** (+1 Spored per 0.5 s) |
| Cloudlet → Nimbus | a 3×3 rain cloud anywhere in range 4 for 4 s, a new one every 2 s: **12 dmg/s** to everything under it (flyers too), Soaked 1 | **24 dmg/s**; Cloudburst every **10 s**: refresh Soaked within 4 |
| Undercurrent → Maelstrom | a whirlpool (radius 1.5) on a path tile every 6 s for 3 s, draws **0.6 tiles/s** toward its centre (never backward past it), 10 dmg/s | radius 2, **0.9 tiles/s**, 20 dmg/s, Soaks |
| Jetreed → Torrent | a 6-tile jet, **40** dmg, 0.8/s, **+50% vs Soaked** | **90** dmg; leaves a 3-tile wet trail for 3 s (Soaked) |
| Jarlink → Lightning Fence | own hit 10, 1.0/s; an arc to another Jarlink within 4 cells: **20** + Charged 1 per crossing (each nightmare at most every 0.5 s) | **45** per crossing; hits Phantoms |
| Prism Jar → Rainbow Prism | aura within 1.5: **+10% crit chance** (the highest Prism counts, no stacking); own hit 15, 1.0/s | aura **+15%**; its hit 40 splits into 3 beams at 50% each |
| Sparkler → Starburst | 6 sparks over radius 1.5, **12** each + Charged 1, 0.5/s | **26** each; every 4th burst is a double |
| Silver Bell → Vesper Bell | range 6 toll every 2.5 s: **30** dmg, fills Drowsy on the strongest (bosses to 3) | **70** dmg; echoes to the next-strongest at half |
| Hushbell → Silence | silence radius 2 (no abilities, no mending, lanterns dim, boss abilities delayed); pulse 10 dmg, 1.0/s | radius 2.5, lingers **2 s**; pulse 20 |
| Thrum → Resonance | a 90° cone, range 3, **22** dmg, 1.0/s, **+30% vs Drowsy** | **50** dmg; +15° per Drowsy nightmare in it (max 180°) |

- **Generic Kin:** +10% damage each, Harmony strikes and stages as named Kinships; Whole Tree = any 3 different branches (as designed).
- **Named Kinships** (Crusted Brood, Eye of the Storm, Fireworks Fence, Vespers): each trait worth about **+20% of the pair's effect** at full stage, the same scale as the built named pairs.
- **Call-back:** **3 Dreamlight** (includes the branch unlock; its final still 2), once per family per run: a whole act's boss income, so steering is a real cost.
- **Dreamlight budget:** unchanged (1 at the first pick + 3 per act boss = 10 by drift 76, plus shards); with 2 offered, a typical family path is branch 1 → final 2 → second branch 1 → final 2.
- **Lucid Dream:** **Rare** (shows the 3 not offered, you pick one).

## Demo

The demo stays on **main's curve**: if this branch ever merges, every Spire value applies only to the
full game (`game/demo` false), and the demo reads main's exports.

## How it's judged

- **Human runs** on the branch (its own profile, `%APPDATA%\HeartwoodTD_Spire`, records tagged
  `"experiment": "spire"`): wins per run count, act reached, leaks per block, finale clears.
- **Bot** (Balancing Code, full-game sims on the branch): act 1 and act 1 bosses, finale leak rate and
  clean-clear rate, the Grove cap (full loadout vs none), Blight step sizes.

## Changes log

(newest at the bottom)
- 2026-10-02: Phase 1 curve and Dew pot in **b69c72ef** (Tower Code): act 1 ramp from 3 to ×1.35, act 2
  2.0 → 4.5 linear, `act4_health_multiplier` 1.2, Dew pot acts 2–4 ×0.9 (bosses 243 / 288).
- 2026-10-02: block finales in **e65e6dcf** (Enemy Code): `block_finale_elites` {10: 1, 30: 2, 60: 3};
  elites the drift already lists count toward it; boss drifts keep the normal rule. **Phase 1 playable.**
- 2026-10-02: **act 1 baseline** (6e1dc434, fresh, full game, 20 seeds): Balanced survives the boss
  **50%** (target ~60%), skip **10%** ✓; 7/20 Balanced runs die before 25 (blocks 3–4, closest .81 / .97);
  finales at 10 / 15 cost 0 leaks, 20 about 1. **Pressure moves from the ramp to the finales:**
  `act1_health_multiplier` 1.35 → **1.25**, `block_finale_elites` → **{10: 2, 30: 3, 60: 4}**.
- 2026-10-02: ramp 1.25 and finales {10: 2, 30: 3, 60: 4} both in **0f1c3944** (Tower Code's commit
  swept in Enemy Code's finale edit, as intended); test_run's elite check is being updated by Enemy Code.
- 2026-10-02: **re-run on 0f1c3944:** Balanced 55%, skip 10%; finales still cost the bot only 0.35
  leaves (its normal drifts leak twice as often). Extra elites alone don't make a spike. **Finale drifts
  get ×1.4 health on every non-boss nightmare** (`block_finale_health_multiplier`), and act 1's ramp
  goes back to ×1.15 (still from drift 3) to pay for it.
- 2026-10-02: finale health in **f2195173** (`block_finale_health_multiplier` 1.4 from drift 10, never
  boss drifts; act 1 ramp ×1.15 from drift 3).
- 2026-10-02: **run 3 on f2195173:** finales bite (Balanced loses 1.63 / 0.94 / 1.00 leaves at drifts
  10 / 15 / 20 ✓), skip 5% ✓, Balanced 50% (target ~60%): drift 10 is the run's hardest point. **First
  finale eased:** `block_finale_elites` {10: 1, 15: 2, 30: 3, 60: 4}. After this, the user's runs judge.
- 2026-10-02: first finale eased in **fd776918** (`block_finale_elites` {10: 1, 15: 2, 30: 3, 60: 4}).
  **Phase 1 handed to the user's runs.**
- 2026-10-02: **user direction:** ladder and decision focus plus a small, capped Grove power
  (Hades-style). Plan reordered: finale rewards (Phase 2), rest choices (Phase 3), capped Grove (Phase
  4), Blight 11–20 (Phase 5); decisions over health from here; the demo stays on main's curve.
- 2026-10-02: **capped Grove in 2114956d** (Meta Game Code): power Morning Stores, Rested Roots, Deep
  Taproot I–II; 8 sidegrades; `perk_style` Sidegrade by default on this branch. Cap measurement queued.
- 2026-10-02: **finale reward + rest-choice Dream effect in 8f43d628** (Roguelite Code): clean finale →
  one Rare+ slot in the next Dream (survives a reroll, saved); `add_next_offer_cards(1)` for the Dream
  rest choice. Banner / rest report / the rest step itself are Main Merger's (pending).
- 2026-10-02: **Phases 2 and 3 playable in 4053690c** (Main Merger, with 8f43d628): finale line on the
  DriftPanel, rest report result, the rest choice (Rest only below max / Clear / Forage, Tend, Dream),
  recorded as `rest_choices`. Clear becomes Forage while clearing is locked.
- 2026-10-02: **user decision: rest choices dropped, Heartwood's Gifts instead** (act breaks only;
  `heartwood_gifts.md` 449c7437). Rest-choice step being removed (Main Merger). Gifts routed: screen /
  draw / placement / Thick Mist (Main Merger), terrain (Environment Code), Warden effects (Tower Code),
  Waking Root (Roguelite Code), art (Environment Assets).
- 2026-10-02: rest choices removed in **a794bc9e**; **gift screen, draw, placement, save, Let them pass
  (+30 Dew × act) and Thick Mist in d3d85731** (Main Merger). Only gifts with a registered effect are
  drawn, so the pool grows as owners land theirs. Deeper Glade's +1 max leaf: Main Merger.
- 2026-10-02: Deeper Glade's **+1 max leaf and the leaf itself** in 911257d2 (Main Merger; applied once,
  saved). Accepted: the new slot arrives filled, so a full Heartwood stays full. The glade ring is
  Environment Code's; the gift is drawn once it's registered.
- 2026-10-02: **Waking Root** in 10d39cfa + 13aaf91a (Roguelite Code; registered, so it's drawn; also holds
  the Omen while a gift is offered). Asked to apply it on every unlock path (the Warden panel too).
  `add_next_offer_cards` removed (94906845).
- 2026-10-02: **Warden-side gift effects in 39b8cc2b** (Tower Code), all nine at the table's numbers;
  Bramble Verge, Old Kin and Memory Seed (no terrain) are drawn now; the six terrain-bound ones wait on
  Environment Code's MapGifts. Accepted edge case: a Memory Seed's ranks are lost if the run is
  saved and reloaded between the sale and the replant.
- 2026-10-02: **terrain gifts in cc503dd7** (Environment Code, `MapGifts`; art 46525c97). Confirmed:
  Deeper Glade's clears count as tended; Moonwell and Bell Stone block walking (a free wall cell). **All
  18 gifts are drawable: Heartwood's Gifts playable.** Exact-resume save hooks pending with Main Merger.
- 2026-10-02: resume + exit-crash fixes for gifts in 8cf3ff1b (Main Merger); the gift offer is now the
  full 3 from 18.
- 2026-10-02: **Grove cap measured** (0919b032, full profile, 20 seeds; the first batch was void, as
  parallel sims shared a profile file): full carried loadout (Sidegrade mode) **+15 points** act 1 boss
  survival (55% vs 40%) and **+3.5 drifts** (26.1 vs 22.6) over no perks: the top edge of the +10–15
  band. **No trim.** Power perks came out at 50% / 24.8 (not separable from Sidegrade at 20 seeds).
  No cell reaches 50. Re-measure if a perk changes.
- 2026-10-02: branch offer (2 of 5), call-back (3 Dreamlight, once per family) and Lucid Dream (Rare, one
  free call that skips the price and the limit) in **320b4969** (Roguelite Code). The new branches
  themselves wait on Tower Code.
- 2026-10-02: **Phase 6 built** (Tower Code): generic Kin 50dbcb28, BranchKit 75f378f3 / e05bdd81, the 12
  branches + 12 finals + named pairs ab455f24, tests 991f5553. Numbers live in each `.tres`
  (`special_params`). **Branch expansion playable**; branch probe queued.
- 2026-10-02: **Undercurrent / Maelstrom: an eddy pause instead of a draw** (Tower Discussion 9fcb8cdf;
  the draw was Rootling's job): a nightmare reaching the whirlpool pauses **0.8 s / 1.2 s** (bosses
  half), once per nightmare per whirlpool. Replaces 0.6 / 0.9 tiles/s.
- 2026-10-02: eddy pause in **1fb636f3** (Tower Code); Eye of the Storm's draw trait became a **0.3 s**
  pause under the rain (accepted).
- 2026-10-02: **branch review** (Tower Discussion, tower_design.md 7816b7e0), numbers (replace the
  table rows above where they differ):
  - **Undercurrent:** the eddy pause is dropped; the whirlpool **links** the nightmares in it: **25%** of a
    hit on one is shared with each other linked one (effect damage, max 6 linked); own 14 dmg/s.
    **Maelstrom:** **35%**, max 8, Soaks, Static bolts travel the current at half.
  - **Jetreed:** **20 + 2% max health** per hit (bosses 0.5%), 0.8/s, 6-tile line; no Soaked bonus.
    **Torrent:** **45 + 3%** (bosses 0.75%), wet trail as before.
  - **Nimbus:** the cloud moves to the densest 3×3 in range every **4 s**; 24 dmg/s; no range Soak refresh.
  - **Eye of the Storm:** the cloud links at **10%**.
  - Phase 2 (not built): **Whetstone** 40 dmg, 0.8/s, **×2.5 below 30%** (bosses ×1.5); **Edgestone** 95,
    overkill spills **100%** to the nearest nightmare within 2 cells. **Rampart** 50 dmg on the adjacent
    path tiles, 0.6/s, **+15% per touching Thornwall** (max 4), touching walls turn to stone; **Bastion** 110,
    a rock from a stone wall every **6 s** (60, 1-tile splash). **Heartroot:** the first non-boss leak per
    drift is dragged back **4 tiles**. **Nurse Log:** Nurture **25%** cheaper within 1.5; **Mother Log 35%**,
    plus a sold Warden's rank stays on its cell for the next plant. **Dream Oak:** +1 shard per different
    family within 2 (max +3). New Kinships Fault Line, Bramble Bed, Nursery at ~+20% of the pair's effect.
- 2026-10-02: branch-review reworks in **67beac23** (Tower Code): Undercurrent / Maelstrom links,
  Jetreed / Torrent erosion, Nimbus drift, Eye of the Storm 10%. Probe queued; if Torrent outscales in
  acts 3–4, cap the % part per hit (Tower Discussion agrees), not the base.
- 2026-10-02: **weighted smart draw** (Roguelite c8bb187e) + Prism Jar anti_tank (Tower 3d0eb468). 100
  seeds, 4 start families: **anti_tank 90%** (was 68), anti_armour 80, anti_swarm 89, anti_support 96,
  boss_abilities 82, detection 79, anti_air 75 (was 84; watch: flyers come from drift 31); 9–10 pairs per
  family, none above 26% of runs. The strict top-band version (100% everywhere, same Sporeling pair
  every run) was rightly not shipped.
- 2026-10-02: **probe of the reworked forms** (1685cae4, 3 seeds): Cloudlet 0.91× Driftspore ✓; Jetreed
  0.44; Undercurrent board 0.85 (fails); Maelstrom 0.41× Puffball; Nimbus 0.87 / 0.66 (45 / 61); Torrent
  1.01 / 1.51, with erosion ~3.5× its base hit at 45 and 7–11× at 61. Game error: `tide_link` meta
  missing in `_relink` (Tower Code to fix). Decisions: **erosion capped at 4× the hit's base**; Jetreed
  base 20 → **30**; Nimbus 24 → **30** dmg/s; Maelstrom and Undercurrent re-probed after the fix.
- 2026-10-02: **new branches probe** (9d5cb88f, 45, 3 seeds, × Driftspore): Inkcap 1.26 (high), Brood Cap
  0.76, Lichenling 0.60 ✓; Thrum 0.26, Sparkler 0.18, Silver Bell 0.05, Jarlink ~0.04 (low); Prism Jar /
  Hushbell boards 0.8× (fail). Decisions: **Inkcap 14**, **Thrum 50**, **Sparkler 36 per spark**,
  **Jarlink crossing 40** (+ a "fence" tag and a firing check), **Prism Jar +15% crit chance / +25% crit
  damage** (Rainbow +20 / +25). Silver Bell and Hushbell are re-judged as control on suitable boards.
- 2026-10-02: **31c89068** (Tower Code): tide_link fix, the erosion cap, Jetreed 30, Nimbus 30, and the
  round 1 changes; Jarlink's arc did fire on every crossing, but only one jar of a pair was credited (it
  alternates now). Re-probe queued.
- 2026-10-02: **new finals probe** (9d5cb88f, × Puffball per Dew, 45 / 61): Deliquescent 1.02 / 1.18 ✓,
  Hatchery 0.85 / 0.81 ✓; Old Lichen 0.70; Resonance, Starburst, Silence ~0.25; Rainbow Prism 0.13;
  Vesper Bell 0.09; Lightning Fence 0.02. Decisions: **Old Lichen 40**, **Resonance 135**, **Starburst 78 per
  spark**; Silence, Vesper Bell and Rainbow Prism get a board test (control / support); **Jarlink /
  Lightning Fence** can't reach the band through crossing damage (each nightmare crosses once or
  twice), so the arc design goes back to Tower Discussion (proposed: a damaging line laid along the route).
- 2026-10-02: Old Lichen 40, Resonance 135, Starburst 78 in **49ab5779**; the new finals grow into
  their family's Ascended form (e4217267).
- 2026-10-02: **fence redesign** (Tower Discussion de57a7c6: a damaging line): **Jarlink 60 dmg/s + 1
  Charged/s** to nightmares touching the arc, a flyer crossing takes **3 Charged**; **Lightning Fence 150
  dmg/s**; Fireworks Fence: every 2 s a nightmare on the fence sets off a 2-spark burst at half damage.
- 2026-10-02: damaging-line fence in **d0f82044** (Tower Code). The arc covers the cells between the
  two jars (jar cells excluded; side-by-side jars make no arc). Corridor probe queued.
- 2026-10-02: Jarlink links to the nearest jar that makes an arc, and the build ghost shows the arc
  (**f8d69e40**, usability).
- 2026-10-02: **re-probe on 706d5d3e** (n = 6 per row): in band Inkcap 1.02, Sparkler 0.74, Thrum 0.58
  (× Driftspore); Nimbus 1.00 / 0.85, Torrent 0.89 / 1.02 (× Puffball). Low: Jetreed 0.44, Undercurrent 0.18,
  Maelstrom 0.44 / 0.38, Prism Jar 0.07 / Rainbow Prism 0.15 (their boards leak more), Silver Bell 0.05
  (board leak 0.43 vs 0.29), Hushbell (0.72 vs 0.65). **Round 2:** Jetreed 40; Undercurrent 35 dmg/s;
  Maelstrom 50 dmg/s + link 0.45; Prism Jar hit 45, Rainbow 120; Silver Bell 80, Vesper Bell 180;
  Hushbell 30, Silence 60. (Supports get real damage: an aura or control alone couldn't hold a slot.)
- 2026-10-02: round 2 in **423887aa** (Tower Code, after Main's merge adb6c0d8). Re-probe queued.
- 2026-10-02: **chain_f3** (39d28f3d): Starburst 0.94 / 0.92, Old Lichen 0.81 / 0.81 ✓; Resonance 0.73 /
  0.64 → **165** (1801c8a1).
- 2026-10-02: **fence probe** (1db2b118, pairs on the route): the arc works (fence 90–96% of damage) but is
  weak: Jarlink 0.32× Driftspore, Lightning Fence 0.36 / 0.31× Puffball. **arc_dps: Jarlink 120, Lightning
  Fence 400** (in d8df6151).
- 2026-10-02: **round-2 re-probe** (d8df6151): in band Jetreed 0.53, Maelstrom 0.82 / 0.92; close Undercurrent
  0.45, Jarlink 0.45 / 0.44, Lightning Fence 0.58 / 0.60, Silence 0.66, Hushbell 0.44; still low Prism Jar 0.22,
  Rainbow Prism 0.43 / 0.39, Silver Bell 0.13, Vesper Bell 0.22. **Round 3 (last):** Undercurrent 40, Jarlink arc
  140, Lightning Fence arc 560, Hushbell 35, Silence 75, Prism Jar 80, Rainbow 200, Silver Bell 150, Vesper
  350 (in 6ad580f3). **The new-branch probe series is closed; human runs judge.**
- 2026-10-02: **branch expansion Phase 2 numbers** (go on main, full game only; user "just do Phase 2").
  All branches 120 Dew, finals 300. **Supersedes** the earlier Whetstone / Rampart values (too low next to
  Pebbling's own branches, ~55–75 dps).
  | Branch → final | Branch | Final |
  |---|---|---|
  | Whetstone → Edgestone | **110** dmg, 0.6/s, range 3; ×2.5 below 30% (bosses ×1.5) | **260**, 0.6/s; overkill spills 100% within 2 |
  | Quarry → Rampart / Bastion | Rampart **120** on adjacent path tiles, 0.5/s, +15% per touching Thornwall (max 4); touching walls turn to stone | Bastion **280**; a rock every 6 s (**150**, 1-tile splash) |
  | Quaker → Earthshaker | slam radius **1.5** every **3 s**, **90**; strips speed boosts | radius **2**, **220**; the path cracks for **3 s** (no new sprints) |
  | Groundroot → Earthbind | every **4 s** grounds up to **2** flyers within **3.5** for **3 s**; pulse 20, 1.0/s, r 2 | every **3 s**, up to **4**; landing hold **0.5 s**; pulse 45 |
  | Deeproot → Heartroot | pulse **24**, 1.0/s, r 2; nightmares within **3 cells** of the Heartwood are Rooted **1 s** (once each) | pulse **50**; the first non-boss leak per drift is dragged back **4 tiles** |
  | Thorncoil → Crown of Thorns | thorns **30/s** to Rooted nightmares in range 2.5; pulse 20 | thorns **70/s**; spread to adjacent at **50%** |
  | Seedbearer → Grove Keeper | a free Sprout on an adjacent cell every **3 drifts** (max 3 alive from it); hit 15, 1.0/s | every **2 drifts**, at rank II; hit 30 |
  | Nurse Log → Mother Log | Nurture **25%** cheaper within 1.5; hit 12 | **35%**, + rank memory on the cell; hit 25 |
  | Dream Oak → Dreamroot | **1 shard / drift** + 1 per different family within 2 (max +3); 10 shards = 1 Dreamlight; **max 4 Dreamlight per run** from shards; hit 12 | shards ×2 on perfect blocks; hit 25 |
  Counter tags confirmed: Whetstone anti_tank; Rampart and Quaker boss_abilities; Groundroot anti_air;
  Deeproot, Thorncoil and the Acorn three none (role lines). Fold-in: Driftspore anti_tank, Bloomcap and
  Inkcap anti_swarm. New Kinships (Fault Line, Bramble Bed, Nursery) ~+20% of the pair's effect.
- 2026-10-02: **Phase 2 built on main** (Tower Code aa9080d4, core 2fc86820; full game only). Placeholders
  accepted: Crown of Thorns pulse 40; thorns and Bastion's rock scale with the Warden's damage (effect
  damage); Fault Line / Bramble Bed / Nursery second traits at the stated shares × stage. Dream Oak's
  4-Dreamlight cap needs a per-source shard count (Roguelite Code); until then the shared cap of 2 applies.
  Probe queued after the act 1 A/B.
- 2026-10-02: Dream Oak's own cap in **7ee88bf2** (Roguelite Code: `add_source_shards`, 4 Dreamlight per run,
  separate from Great Dreamcatcher's shared cap of 2).
- 2026-10-02: **detection coverage**: Quaker / Earthshaker's slam reveals Lurkers 3 s (Tower Discussion
  219a7a9c); the tag alone gave 63%, so the draw weighs detection ×2 (Roguelite 7d17c35f). Now (100 runs, 4
  random families): detection **79%**, anti_tank 91, anti_air 87, anti_swarm 87, boss_abilities 74,
  anti_support 64, anti_armour 54; 9+ pairs per family, none above 25%. Accepted.
