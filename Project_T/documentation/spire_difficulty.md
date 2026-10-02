# Spire Difficulty (experiment branch `experiment/spire-difficulty`)

Owner: Balancing Discussion (numbers); code by the owning chats, **committed on
`experiment/spire-difficulty`, never on main**. Main keeps today's balance until the user compares the
two and picks. Started 2026-10-02.

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

## Phase 3: rest choices (Spire's campfire), before Blight 11–20

At **every rest**, after the Dream and the Omen, pick **one**:

| Choice | Effect |
|---|---|
| **Rest** | regrow **1 leaf** (up to max) |
| **Tend** | **one free Nurture rank** on a Warden you pick (`RunState.free_nurtures` + 1) |
| **Dream** | **one extra card** in the next Dream offer |

**Rest is only offered below max leaves** (user: regrowing isn't a reward when nothing was lost). At
full leaves it's replaced by **Clear: one free clear** (`RunState.free_clears` + 1), or, with fewer
than 3 obstacles left, **Forage: +20 Dew × act**.

Healing becomes a choice that costs power. The rest bonus (Dew) stays as it is. Code: Main Merger (the
rest step, UI) + Roguelite Code (the Dream effect; free Nurture exists). Saved with the run.

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
