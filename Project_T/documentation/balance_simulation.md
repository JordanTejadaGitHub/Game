# Balance Simulation

Design spec, 2026-09-28. Playtests keep finding "too easy" one exploit at a time (the Sapling, two
Great Bells, cheap Nurture on Sprouts). This tool measures the whole difficulty curve against the
targets in `run_design.md` ("Difficulty curve targets"), so balance changes are checked by numbers,
not by feel alone. It grows out of Tower Code's probes (`tools/balance_act3.gd`,
`tools/balance_run.gd`) and Roguelite Code's `sim_rest` / `sim_family_pick`.

## What it answers

1. Does a **fresh profile** start leaking around drift 12–18 and usually end in act 2?
2. Do **Grove unlocks** and **Dream cards** visibly move that curve (the user's rule: "leaking early
   until you unlock perks from meta and cards")?
3. Is any **build, Warden or card** carrying runs on its own?
4. Does **Dew** stay scarce (no "infinite money" in act 3–4)?

## How a simulated run plays

A bot plays a normal run headless, using the real game (`main.tscn` under root, as the tests do),
with no hand-placed maze: everything is bought from the Dew the run earns.

**Profiles** (Grove state at run start; presets supplied by Meta Game Code):

| Profile | Grove | Stands for |
|---|---|---|
| **Fresh** | nothing | first runs, and every demo run |
| **Early** | ~5 cheap unlocks (a starting-Dew perk, Morning Stores I, one family, two card bundles) | ~3 hours in |
| **Half** | about half the tree by Seed cost, 3 perk slots | ~15 hours in |
| **Full** | everything, 5 perk slots | endgame (Blight 0) |

**Build styles** (the bot's preferences; each is a scoring rule, not a script):

| Style | Plays like |
|---|---|
| **Balanced** | a sensible first-time player: a medium maze, grows the Wardens nearest the Heartwood |
| **Wide** | many cheap Wardens, Sprouts and Thornwalls, few ranks |
| **Narrow** | few Wardens, heavy Nurture |
| **Combo** | seeks the family pair with the most combo cards (e.g. Storm Grid) |
| **Sleep** | Bellflower-led (full game only) |

**Bot rules (shared by all styles):**
- **Maze:** Thornwalls go where they add the most path length (the "+N path" number); attacking
  Wardens go where the most path cells are in range. The path rule is the game's own.
- **Spending** at each rest, in this order: fill the planned maze → grow the Wardens with the most
  path in range → Nurture (per style) → keep nothing in reserve. Also spends mid-drift on the same
  rule once it can afford the next item.
- **Dreams:** takes the card that scores highest for its style (tag match, then rarity); never
  lets a Dream pass. **Family picks:** its style's families, then the owed half-dreamed family.
  **Dreamlight:** unlocks the next form of its most-built family. **Omens:** Clear Skies (no Omens
  in the baseline).
- **No juggling, no selling** except to grow into a 2×2 Ascended form.

**Maps:** 5 fixed map seeds for every comparison (placement swings results 2–3×, as the act 3 probe
showed), plus a few random seeds for spread.

## What it records

Per drift, written to a CSV per run (outside `user://`, e.g. `tools/balance_out/`):
- nightmare health spawned, damage dealt, leaves lost, drift length
- Dew earned (rest bonus, dispels, other), spent (plant / grow / nurture), banked
- Wardens by tier and family, Dream cards owned, Dreamlight
- the top Warden's share of damage, the Asleep share, Reaction share, crit share

A summary table per batch: survival drift (median / spread) per profile × style, first-leak drift,
leaves lost by 25 / 50 / 75, banked Dew at act starts, the most frequent top Warden and top card.

## The checks (pass / fail)

| Check | Target |
|---|---|
| Fresh, Balanced: first leak | drift **12–18** |
| Fresh, Balanced: leaves lost by drift 25 | **5–8** of 15 |
| Fresh, Balanced: run end | **act 2** (drift 30–50) in most runs; a win in **< 5%** |
| Early | usually reaches **act 3** |
| Half | wins sometimes (the first win) |
| Full | wins in **most** runs at Blight 0 |
| Leak rate within a run | **falls** from drift 10 to 25 as Dreams stack, rises again in act 2 |
| Styles | no style's median survival more than **1.5×** the Balanced median, none below **0.6×** |
| One Warden | its share of damage **< 35%** in any run (Ascended **< 45%**) |
| Sleep | Asleep share **< 40%** outside the Sleep style |
| Dew | banked Dew at a rest averages **< 2 rest bonuses** after act 1 (no hoard) |

A failed check names the drift range and the likely cause (the top Warden, the top card, the banked
Dew), so the next change is obvious.

## How it's used

- **Quick batch** (after any balance change): 3 seeds × Fresh + Full × Balanced, compared with the
  last saved **baseline** (`tools/balance_baseline.json`); it reports what moved.
- **Full batch** (overnight, before a playtest build): 5 seeds × 4 profiles × 4–5 styles.
- A change ships when the quick batch passes and nothing moved that wasn't meant to.

**Speed:** headless, `--fixed-fps 60` with a high `Engine.time_scale`, effects in lite mode, audio
silent. Target: one 100-drift run in under 5 minutes, so a full batch fits in a night.

## Who builds it

- **Tower Code:** the runner (grows out of `tools/balance_run.gd`), the maze and spending bot, the
  CSV and summary.
- **Roguelite Code:** the Dream, family-pick, Dreamlight and Omen policies (`sim_rest`,
  `sim_family_pick`), and the style scoring for cards.
- **Meta Game Code:** the four Grove profile presets.

**As built so far (2026-09-28):** Grove presets `MetaRun.load_preset(&"fresh" | &"early" | &"half" | &"full")` (a separate sim profile; meta applies only with `game/demo` off). Card and pick policies `DreamSimPolicy` (`scripts/run/dream_sim_policy.gd`, 147ee8e): card score = style tag score × 10 + rarity; in-build cards +2; half-dreamed −1 (Combo +2); Dreamlight to the most-built family's next form (Wide may also buy Thornwall growths); Omens: Clear Skies. Tuning lives in the file's consts.
- **Design chat:** owns the targets above; adjusts them when the design changes.

## Later

A **human baseline**: the same CSV written from real playtests (debug builds only), so the bot's
curve can be checked against how people really play.
