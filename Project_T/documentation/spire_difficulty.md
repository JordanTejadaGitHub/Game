# Spire Difficulty (experiment branch `experiment/spire-difficulty`)

Owner: Balancing Discussion (numbers); code by the owning chats, **committed on
`experiment/spire-difficulty`, never on main**. Main keeps today's balance until the user compares the
two and picks. Started 2026-10-02.

User: *"Make it feel like Slay the Spire difficulty."* Tried on a branch first.

## Targets

| | Target |
|---|---|
| Average player | **first win after ~10–15 runs** |
| Skilled player, Blight 0 | **wins ~30–50%** |
| Fresh profile | usually dies in **act 2–3** |
| Act 4 | a real test, not a victory lap |
| Every block | **can kill you**: no safe stretch, no single wall |
| Grove perks | give **options, not raw power** (behind one switch to compare) |
| Blight Levels | the Ascension ladder: **one clear new problem per level**, up to 20 |

What Slay the Spire does that we copy: every fight costs something; HP carries over and healing is a
choice that costs power; elites are optional-feeling spikes with better rewards; each act ends in a
boss that checks the deck; Ascension adds one named problem per level.

## Phase 1: the curve (numbers only)

The live curve is calm early and rises in steps (act 1 ×1.0 to drift 9, act 2's start a breather).
Spire shape: pressure from the first block, a spike at every block's end, act 4 harder than act 3.

| Lever | Main today | Spire branch |
|---|---|---|
| Act 1 ramp (`act1_ramp_from` / `act1_ramp_to` / `act1_health_multiplier`) | ×1.0 to drift 9 → ×1.15 at 20 | **×1.0 at drift 3 → ×1.35 at 20**, held to 24 |
| Act 2 (`act2_start_health_multiplier`, `act2_steep_value`, `early_acts_health_multiplier`) | 1.7 at 26 → 4.5 at 45, linear | **2.0 at 26 → 4.5 at 45**, linear (`act2_steep_value` 3.45) |
| Acts 3–4 (`late_acts_health_multiplier`) | ×6.0 both | ×6.0 act 3, **act 4 ×7.2** (new export `act4_health_multiplier` 1.2 on top) |
| **Block finales** (new) | one guaranteed elite from drift 31 | the **last drift of every block** gets guaranteed elites: **1 from drift 10, 2 from 30, 3 from 60** (`block_finale_elites`; never on an intro drift; replaces `guaranteed_elite_from` there) |
| Dew pot (`dew_pot_acts`) | as run_design.md | **acts 2–4 −10%** (each pot row × 0.9); act 1 unchanged |
| Bosses, bites, Oak | 1.75 / 1.75 / 3.0; bites 10 / 10 / 12 | unchanged at first |

Expected: act 1 closest ~0.5–0.8 throughout (not ~0.3), a leak or two per block finale for an average
maze, act 2 hard from its start. Measured with the bot for acts 1–2 (fresh Balanced survives the act 1
boss ~60%, skip ≤ 15%) and with human runs for acts 2–4.

## Phase 2: Grove perks as sidegrades (with Meta Game Discussion)

Spec by Meta Game Discussion (2026-10-02). Rule: each power perk becomes a trade-off or a timing shift,
roughly net-zero over a run, so carrying it is a style choice. Costs, levels, positions and
prerequisites stay; only effects swap. Switch: `MetaRun.sidegrade_perks` (Developer setting "Perk
style: Power / Sidegrade"; Power on main, Sidegrade on this branch). Code: Meta Game Code.

| Perk | Power (main) | Sidegrade |
|---|---|---|
| Morning Stores I–III | +10/20/30 starting Dew | same, but drifts 1–5 pay −15/30/45% of their pot (a fast opening, not more Dew) |
| Rich Dew I–III | Dew pot +5/10/15% | same, rest bonus −10/20/30% |
| Rested Roots I–II | rest bonus +10/20% | rest bonus +20/40%, Dew pot −5/10% (the mirror of Rich Dew) |
| Deep Taproot I–III | +1/2/3 max leaves | same, no leaf regrows at act breaks |
| Sprout Bed | 2 free Sprouts | 2 Sprouts planted where you choose at the start, 30 less starting Dew |
| First Care | first 3 Nurture ranks free | same, then Nurture +15% for the run |
| Early Bloom | first pick shows every unlocked family | same, the drift 25 pick shows one fewer |
| Early Light | +1 Dreamlight at start | same, the first family pick gives none |
| Kindling | a random Common Dream at start | same, the first Dream offer has 2 cards |
| Clear Sight | start holding Heartwood's Reach | same, and the map rolls one extra ridge |
| Wider Dreams | 4 cards per Dream | same, "Let it pass" gives no Dew |
| Seed Pouch, Second Thoughts, Let Go, Omen Reader, slots 4/5/6 | options / meta | unchanged |

Measure: with a full loadout, Sidegrade lands within ±5% of a no-perk run (Power lands clearly above).
A sidegrade that's strictly better or worse in the sims goes back to Meta Game Discussion.
Clear Sight's extra ridge stacks with Blight 9's on purpose; if route generation breaks on small maps
(min obstacles, route caps), extra ridges cap at +2 in total.

## Phase 3: Blight Levels 1–20 (the Ascension ladder)

Levels 1–10 stay as in meta_design.md. New levels, one named problem each:

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

+10% Seeds per level as now.

## Phase 4 (optional, after a playtest): the rest choice

Spire's campfire: heal or upgrade. Ours: at each rest, **Tend the Heartwood (regrow 2 leaves)
instead of the rest bonus**. Healing becomes a choice that costs power. Only if Phases 1–3 make runs
too brittle.

## How it's judged

- **Human runs** on the branch (its own profile): wins per run count, act reached, leaks per block.
  The run history tags the branch build.
- **Bot** (Balancing Code, full-game sims on the branch): act 1 and act 1 bosses (targets above), block
  finale leak rate, Blight 1–20 step sizes (each level should cost the bot a similar slice of drift
  reached).

## Changes log

(newest at the bottom)
- 2026-10-02: Phase 1 curve and Dew pot in **b69c72ef** (Tower Code): act 1 ramp from 3 to ×1.35, act 2
  2.0 → 4.5 linear, `act4_health_multiplier` 1.2, Dew pot acts 2–4 ×0.9 (bosses 243 / 288).
