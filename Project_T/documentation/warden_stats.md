# Warden Stats

Numbers for every Warden. What each one *does* and why it exists is in `tower_design.md`; status
rules are in `dream_design.md`. Rows marked **✓** are already in the game (`resource/tower/*.tres`)
and their values here are copied from there; the rest are proposals for the coding chat. Everything
is a starting point for playtesting.

## Principles

**Cost tiers:** Sprout 10 → base 25–30 (Sprout + 15–20) → branch +45 → final form +90. A final form
costs ~160 Dew in total.

**Dew-efficiency falls, space-efficiency rises.** Each tier is roughly **2× as strong per cell**
as the one before, but costs ~2.3× as much. Early on, Dew is what limits you, so cheap Wardens are
best; later, **space on the map** is what limits you (every Warden is a wall in the maze), so
evolving is how you keep growing. That tension is the long-run economy.

**Reference power:** a Sprout soothes 10 per second for 10 Dew. "DPS" below = soothe per second
against one creature, before statuses, auras and Dreams. Area and status effects are worth extra;
single-target Wardens get higher raw numbers to compensate.

**Auras don't stack with themselves:** a Warden next to two Elder Stumps gets the bonus once (the
highest one applies). Different aura types do stack.

## Always available

| Warden | Cost | Range | Soothe × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|
| ✓ Sprout | 10 | 2.5 | 10 × 1.0 | 10 | projectile | none |
| ✓ Thornwall | 3 | — | — | — | wall | no attack |
| ✓ Bramble | +10 | 1.25 | 6 × 1.5 | 9 (area) | pulse | soothes creatures walking beside it; **×2 vs Held** (proposed) |

## Sporeling family (spore)

| Warden | Tier | Cost | Range | Soothe × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| ✓ Sporeling | base | 25 (+15) | 2.5 | 7 × 2.0 | 14 | projectile | Spored 1 per hit (cap 8) |
| ✓ Driftspore | branch | +45 | 2.5 | 8 × 2.0 | 16 | projectile | Spored **2** per hit, cap **12** |
| Puffball | final | +90 | 2.5 | 12 × 2.0 | 24 | projectile | Spored 2 per hit, cap 12. At **10+ stacks** the target **pops**: soothes it and creatures within 1 cell for **6 × stacks**, and half its stacks spread to up to 3 nearby creatures |
| ✓ Bloomcap | branch | +45 | 2.5 | 10 × 0.5 | cloud | cloud | leaves a sleepy cloud on the path (radius 0.75, 3 s): Drowsy |
| Dreamshroom | final | +90 | 2.5 | 14 × 0.6 | cloud | cloud | bigger cloud (radius 1.0, 4 s), **2 Drowsy** per tick; at 5 Drowsy a creature **sleeps 1.5 s** (once each; bosses cap at 3 Drowsy, so they never sleep) |

## Dewdrop family (water)

| Warden | Tier | Cost | Range | Soothe × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| ✓ Dewdrop | base | 25 (+15) | 2.5 | 15 × 1.2 | 18 | projectile | splash 0.6; Damp |
| ✓ Rain Lily | branch | +45 | 2.75 | 18 × 1.2 | 22 | projectile | splash **1.0**; Damp **6 s** |
| Monsoon | final | +90 | 3 | 40 every 3 s | 13 to **each** creature in range | rain | soothes **every** creature in range + Damp 6 s |
| ✓ Mistveil | branch | +45 | 2.5 | 8 × 0.5 | cloud | cloud (fog) | fog on the path (radius 0.9, 4 s): Damp, and **Spored ticks +50%** inside (proposed value) |
| Morning Fog | final | +90 | 3 | 10 × 0.5 | cloud | cloud (fog) | fog radius **1.25**, 5 s: Damp, slows 15%, **1 Drowsy per second** inside |

## Firefly Jar family (light)

| Warden | Tier | Cost | Range | Soothe × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| ✓ Firefly Jar | base | 30 (+20) | 3 | 12 × 1.5 | 18 | projectile | Static 1 |
| ✓ Stormcap | branch | +45 | 3 | 14 × 1.2 | 17 × up to 3 | chain | chains to 3 (jump 1.5); vs Damp: **+2 jumps**, jump 2.5 |
| ✓ Thunderhead | final | +90 | 3.5 | 20 × 1.3 | 26 × up to 4 | chain | every **5th** attack strikes **every Damp creature** in range. **Proposed:** chain 4 (currently the default 3) |
| ✓ Lanternmoth | branch | +45 | 4.5 | 12 × 1.0 | 12 | projectile | Marked; **reveals** fog-hidden creatures in range |
| Beacon | final | +90 | 5 | 16 × 1.0 | 16 | projectile + pulse | every 2 s, **Marks everything** in range; its Marked is **+35%** |
| Sunpetal *(hidden)* | branch | +45 | 3.5 | 12/s, ramping | 12 → 48 | beam | ramps +25% per second on one target (max ×4); ramps **2× as fast** on Drowsy or Held |

## Pebbling family (stone) — not built yet

| Warden | Tier | Cost | Range | Soothe × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| ✓ Pebbling | base | 30 (+20) | 2 | 40 × 0.5 | 20 | projectile | heavy, slow |
| Mossback | branch | +45 | 1.75 | 110 × 0.4 | 44 | projectile | **×2 vs Marked** |
| Boulderback | final | +90 | 1.75 | 220 × 0.35 | 77 | projectile | splashes 50% to creatures within 1 cell; **always crits (×2) on Drowsy** |
| Chime Stone | branch | +45 | 2 | 22 × 0.8 | 18 (area) | pulse | Static 1; each pulse **sets off** a Static bolt on creatures with 3+ stacks |
| Lullaby Bell | final | +90 | 2.5 | 40 × 0.8 | 32 (area) | pulse | Static 1 + **Drowsy 1** per pulse; sets off Static like Chime Stone |

## Rootling family (root) — not built yet

| Warden | Tier | Cost | Range | Soothe × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| ✓ Rootling | base | 25 (+15) | 2 | 12 × 1.0 | 12 (area) | pulse | **proposed:** pulses slow 10% for 1 s (the "roots nip at feet" in the design) |
| Rootcurl | branch | +45 | 2 | 14 × 1.0 | 14 (area) | pulse + pull | every **4 s**, pulls the creature furthest along (in range) **back 1 tile** |
| Long Way Home | final | +90 | 2.5 | 18 × 1.0 | 18 (area) | pulse + pull | every **5 s**, pulls back **3 tiles**; each creature only once (bosses: 1 tile) |
| Tangleroot | branch | +45 | 2 | 14 × 1.0 | 14 (area) | pulse + hold | every **3 s**, **Holds** the creature furthest along for 1 s |
| Snugroot | final | +90 | 2.5 | 20 × 1.0 | 20 (area) | pulse + hold | every 3 s, Holds **up to 3** creatures for 1 s |

## Acorn family (support, economy) — not built yet

| Warden | Tier | Cost | Range | Soothe × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| ✓ Acorn | base | 25 (+15) | 2 | 8 × 1.0 | 8 (area) | pulse | **aura:** the 8 surrounding Wardens +5% soothe |
| Elder Stump | branch | +45 | 2 | 10 × 1.0 | 10 (area) | pulse | **aura:** the 8 surrounding Wardens **+20% attack speed** |
| Grove Heart | final | +90 | 2 | 14 × 1.0 | 14 (area) | pulse | **aura, radius 2:** +15% soothe and attack speed, **+3% more per Warden** in the radius (max +30%) |
| Dewcatcher | branch | +45 | 2 | 8 × 1.0 | 8 (area) | pulse | **+3 Dew per drift** (+15 per block; pays itself back in ~15 drifts) |
| Wellspring | final | +90 | 2 | 10 × 1.0 | 10 (area) | pulse | at every rest, **+5% of your banked Dew** (max +40 per Wellspring; all Wellsprings together max +80 per rest) |

## New mechanics the unbuilt Wardens need

For the coding chat, in rough order of need:
1. **Pulse with an effect**: slow (Rootling), Static set-off (Chime Stone), extra statuses.
2. **Pull back along the path** (Rootcurl, Long Way Home): move a creature back N cells on its
   current route; once-per-creature memory.
3. **Hold** (Tangleroot, Snugroot): the Held status (`dream_design.md`).
4. **Auras** (Acorn, Elder Stump, Grove Heart): neighbour lookup on the grid; highest-of-type rule.
5. **Economy hooks** (Dewcatcher, Wellspring): per-drift and per-rest Dew.
6. **Pop / burst** (Puffball), **sleep** (Dreamshroom), **rain** (Monsoon), **mark-all pulse**
   (Beacon), **ramping beam** (Sunpetal).

## To check in playtests

- Is each family roughly as strong as the others at the same Dew? (Compare Dew spent vs creatures
  dispelled per family.)
- Do players evolve when space runs out, as intended, or hoard cheap Wardens?
- Pull and Hold on bosses: fun, or trivialising? (Bosses get reduced effects.)
- Economy Wardens: does Dewcatcher pay back fast enough to be picked, without being mandatory?
