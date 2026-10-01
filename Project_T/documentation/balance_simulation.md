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
| **Half** | about half the tree by Seed cost, 3–4 perk slots (3 are free from the start) | ~15 hours in |
| **Full** | everything, 6 perk slots (incl. the secret one) | endgame (Blight 0) |

**Build styles** (the bot's preferences; each is a scoring rule, not a script):

| Style | Plays like |
|---|---|
| **Balanced** | a sensible first-time player: a medium maze, grows the Wardens nearest the Heartwood |
| **Wide** | many cheap Wardens and Thornwalls, few ranks |
| **Sprout** | the Sprout swarm build: Sprouts as walls and attackers, takes Seedfall, Sprout Surge, Sprout Chorus, Root Network, Seedling Gift, Nursery |
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
| Fresh, Balanced: first leak | drift **20 or later** (revised 2026-09-28: act 1 teaches; reach 25) |
| Fresh, Balanced: leaves lost by drift 25 | **0–3** of 15; reaches drift 25 in almost every run and **beats the first boss in about 75%** of runs (user, 2026-09-29: "a fresh player doesn't have to beat the first boss every time") |
| Fresh, Balanced: run end | **act 2** (drift 35–50) in most runs; a win in **< 5%** |
| Act 1, Spender (spends whenever affordable, builds the maze) | nightmares' **closest approach ≤ ~70%** of the route in most drifts; 0–1 leaves by 25 |
| Act 1, Saver (holds Dew up to 5 drifts for a bigger growth) | closest approach **85–100%**, **0–2 leaves** by 25, survives; its Warden power at drift 25 clearly above the Spender's |
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

## First findings (realistic-run probe, 2026-09-28, fresh profile, 3 seeds)

Income only for drifts 1–60 (assumed perfect blocks), then drifts 61–70 fought for real:
- **Dew by drift 60 ≈ 8,100** (dispels ~7,000, rests ~800, call-early ~300). Spent: plant ~370, grow
  ~1,800, **Nurture ~5,900 (73%)**. The board: 16 attackers, all **branch tier**, average rank ~3.8.
- **No final forms on a fresh profile**: they're Grove-only, so 2–3 Dreamlight sat unspent. That's
  by design (a fresh Heartwood is outmatched), and it means **the old "12 rank-IV finals" probe was
  far above anything a fresh player can own**; act 3 health isn't tuned against it.
- Drifts 61–70: damage ×1.26 / ×0.99 / ×0.73 of the health spawned; 0 / 6 / 229 leaks. The act 3
  wall is right there for a first-time board; the spread is the map plus naive Dream picks (seed 3
  took Sprout cards with no Sprouts; DreamSimPolicy replaces that).
- **Watch:** the target says a fresh profile usually **ends in act 2**. Reaching act 3 comfortably on
  one seed of three hints that acts 1–2 are too gentle for a fresh profile, but this probe didn't
  fight drifts 1–60. The quick batch (all 100 drifts fought) decides it.
- **Watch:** Nurture is the only big Dew sink before finals. If Dew still piles up in act 2 of a
  fresh run, the fix is a sink or less income, not more health.

- **Watch: mass-Sprout mazes. User: "Sprout spam should be a build"** (2026-09-28): a real archetype you commit to through Sprout cards, not the default. Plan if the numbers confirm it's too strong **without** those cards: Sprouts cost +1 Dew per Sprout on the map, and **Seedfall** becomes "Sprouts cost 6 and their price never rises" (the door into the build). The **Sprout** style is its own bot style. Playtest ( fresh profile, drift 23: 60+ Sprouts with Sprout Surge, **15/15 leaves and 782 Dew banked**, far easier than the 5–8 leaves lost by 25 target). The user chose to wait for the numbers: the **Wide** style must be in the first batches, with Sprouts as its walls (Seedfall, Sprout Surge, Root Network). If Wide beats the 1.5× Balanced limit, the leading fix is **Sprouts cost +1 Dew per Sprout on the map**.

## First batch (tools/balance_sim.gd, 2026-09-28; Fresh, 5 seeds, every drift fought; baseline `tools/balance_baseline.json`)

| Style | Survival (median, range) | First leak | Leaves lost by 25 | Banked Dew (× rest bonus) |
|---|---|---|---|---|
| Balanced | 42 (23–49) | 20 | 4 | 2.1 |
| Wide | 19 (19–37): **0.45× Balanced** | — | — | — |
| Sprout | **67 (46–67): 1.6× Balanced** | 50 | 0 | 2.6 |

- **Balanced** is close to the revised act 1 target (one run died at 23; 4 leaves by 25 is one over).
- **Wide** died at drift 20 in 4 of 5: the old **Wake** (10 Mourners, all spore-resistant) wiped single-family Sporeling boards. Fixed in `acts_1_2.md` plus a new rule: no act 1 drift over ~40% of its health resistant to one type (`enemy_design.md`).
- **Sprout** is too strong **without its cards** (a seed with 0 Sprout cards reached drift 67 losing nothing) and ends in sudden wipes, not leaks. Decision pending with the user: the planned Sprout price rule.

## Second batch (2026-09-29; Sprout +3 per 5, act 2 ramp ×1.55, acts 3–4 ×1.6)

| Style | Survival (median, range) | vs Balanced | First leak | Leaves lost by 25 | Wins |
|---|---|---|---|---|---|
| Balanced | 45 (25–74) | — | 28 | 0 (per seed 0/5/9/0/0) | 0/5 |
| Sprout, no Seedfall | 45 (39–66) | ×1.00 | 45 | 0 | 0/5 |
| Sprout + Seedfall | 45 (39–46) | ×1.00 | 44 | 0 | 0/5 |

**Every target passes.** Watch: Balanced's spread by map is wide (one seed dies at the drift 25 boss); **Seedfall adds no survival** (it only saves Dew), so as the door into the swarm build it's too weak: **Flat Seedfall tested (62af1fd): ×1.05 of Balanced, first leak 50, kept.**

## Grove-profile batch (2026-09-29, 10 seeds, Balanced)

| Profile | Survival (median, range) | Wins | First leak |
|---|---|---|---|
| Fresh | 43 (23–74) | 0/10 | 27 |
| Early | 43 (26–74) | 0/10 | 28 |
| Half | 40 (27–72) | 0/10 | 28 |
| Full | 42 (28–67) | 0/10 | 28 |

**Fails every Grove check: the Grove makes no difference for the bot.** Survival follows the **map seed** (the same 3 seeds run long in every profile). Before tuning the Grove: a diagnosis of whether the bot uses Grove content (finals, Ascended, Dreamlight, cards, family spread) and how much the map decides. Levers on the table if the Grove really adds little: stronger perks, stronger (not just more) Grove families and cards, a Blight 0 curve, a smarter bot.

**Diagnosis + fixed-bot rerun (2026-09-29):** the bot never grew a final (nurturing made them cost 300+; fixed in 97a33ca). With the fix Full grows ~7 finals by drift 40 but still doesn't outlast Fresh (median ~40 vs 43): it hoards for finals while leaking, and **a Full run with Pebbling as first family died at drift 4**. New checks: **every family must carry act 1 alone** (reach drift 25 in ≥8 of 10 runs), a scripted **"Grove player"** (Firefly + Dewdrop, finals first, Ascended from 51) at Fresh / Half / Full, and the **DPS per Dew of a final form** vs its rank III branch.

**Final form value (2026-09-29):** growing a rank III branch into its final (325 Dew incl. rank difference) adds **3–8× more single-target DPS per Dew** than ranks IV–V (450 Dew) for every damage final; support finals (Morning Fog, Wellspring, Zephyr, …) and area finals (Monsoon, Starling Murmuration) trade single-target DPS by design. So **finals are worth their price**; the Grove unlocks real power, and the old bot trap was the mistake. Early sign from the family-opening check: **Pebbling alone dies at drift 3–4** (40 damage at 0.5/s overkills early swarms); likely fix after the full check: its shots skip on to a second nightmare.

**Family openings + Grove player (2026-09-29):** only the starting three carry act 1 alone (Bellflower, Whirligig 6/10; Nestling 3/10; Pebbling, Rootling, Acorn 0/10) → base Warden DPS floor (`warden_stats.md`). The Grove player (Firefly + Dewdrop, finals first): Fresh 35.5, Half 39 (one win), Full 40 median; **half of all runs at every profile die at drifts 28–29** (the act 2 opening, before finals) → the guaranteed elite moves to drift 31; **no Ascended form in any run** (3–6 Dreamlight earned) → bosses give 4 Dreamlight.

## Batch grove10 (2026-09-30; random drifts, 10 seeds per cell)

**A. Each family alone, Full Grove, to drift 25** (reached 25 / average leaves lost by 25): Sporeling
10/1.1, Firefly 10/0.3, Dewdrop 10/0.3, Bellflower 10/0.5, Pebbling 9/3.1, **Acorn 9/9.2**, Nestling
8/0.4, **Rootling 8/0.5 (its 2 deaths at drifts 2–3)**, **Whirligig 7/7.8**.
**E. Fresh Balanced:** beat the drift 25 boss **10/10** (target ~75%), 0.8 leaves by 25.
**C. Spend or save** (Mixed style, 5 families × 10, reached 25 · close calls · approach): Fresh
spender 36/50 · 1.5 · 0.86, saver **46/50** · 0.7 · 0.80; Early spender 36/50, saver 45/50. The
spender's deaths are Dewdrop and Firefly (4/10 each, drifts 5–13); the saver's weak spot is Early
Pebbling (5/10).
**D. Grove player** (Firefly + Dewdrop, to 100): medians Fresh 38, Half 41, Full 39; wins 0/30; the
26–30 death cluster is gone; best 97 (Half). Stormheart unlocked in 2 Full runs, planted in 1.

Decisions (design chat, 2026-09-30):
- **Openings under the floor:** Rootling (dies at drift 2–3 on some seeds, a terrible first run),
  Whirligig (7/10) and Acorn (9.2 leaves). The floor is now **≥ 8/10 reach 25 and ≤ 3 leaves on
  average**, alone, at Fresh. Tower Code tunes their base Wardens; rerun A for those three at Fresh.
- **The first boss is too easy at Fresh:** raise **only the drift 25 boss** (the act stays the
  teacher): boss health ×1.5 → **×1.75** for act 1's boss, rerun E with 20 seeds, target 14–16/20.
- **Saving is safer than spending, the reverse of the target.** No tuning yet: first a breakdown of
  what the spender bought by drift 10 in its Dewdrop / Firefly deaths (plants, ranks, clears,
  growth). If spending on the wrong thing kills it, fix the bot; if the target is wrong, act 1's
  early drifts need to punish an unspent 100+ Dew bank.
- **The Grove still doesn't move the median.** Fresh at 38 is on target, so act 2 stays; the Grove
  must add more. Next: per profile, the death drift and what leaked, Dew and damage at 30 / 45, the
  perks carried. Then buff the perks and the Grove families (not lower act 2).

**Breakdowns (same day):**
- **Spend or save:** the spender died because it poured 340–384 Dew into **Nurture on base Wardens**
  (rank ~II) while the saver grew 4–5 branches by drift 10. Ranking the base is the trap; spending
  on growth is fine. Decision: the **spender bot buys the next growth whenever affordable, else
  plants, and ranks only after that**; rerun C. Design note: a human can fall into the same trap. The
  Warden panel already lists Grow first; if playtests show players ranking Sprouts, add a one-time
  whisper.
- **Grove player:** the Grove's power is real (Half/Full reach 9–10 finals by 45) but the bot banks
  ~200 Dew into the act break and meets drift 31's jump with it unspent (deaths d31–38). Decision:
  **fix the bot first** (spend down to one rest bonus before drifts 26 and 31), add a **loadout
  column**, rerun D. Perks and Grove families are buffed only if the Grove still doesn't move the
  median after that.

**Omens and reruns (same day):**
- **Omens, always face vs never** (Balanced, 15 seeds, to 50): Fresh reached 50 in 6/15 vs 8/15
  (mean death 41.3 vs 44.7); Early 4/15 vs 7/15 (36.3 vs 43.7). Leaves lost in drifts 11–25: 14.4 vs
  5.9 (Fresh), 18.3 vs 3.2 (Early). **Passes** the "facing every Omen loses clearly more" target
  (run_design.md): Omens have teeth. Later, lower priority: a bot that faces only when its maze has
  slack, to check the rewards make picking your moments worth it.
- **Openings:** Rootling 10/10 (3.7 leaves: accepted, within 10-seed noise), Whirligig 10/10 (0.3).
  **Acorn 1/10** at 14 @ 1.6/s (single target loses act 1's swarms); now 16 @ 1.4/s with a small
  bounce splash (85c4240), rerunning.
- **First boss:** ×1.75 still beaten 19/20 → **×2.0**, rerun E (target 14–16/20).
- **Acorn keeps attacker ranks and the attacker Focus** (decision): it's its family's base attacker
  and opener. Only **Elder Stump and Grove Heart** are pure supports whose ranks go to the aura.

## Batch g11 and the Dream value "before" (2026-09-30)

- **Acorn at Fresh:** 9/10 reach 25, 4.8 leaves: just misses the floor → **+2 damage** (approved).
- **The first boss:** ×1.5, ×1.75 and ×2.0 all give 19–20/20 clean dispels: its health barely
  matters, the maze outclasses it. Decision: wait for the "after" batch (act 1 health rises with the
  cards), then raise the act 1 boss until Fresh Balanced beats it ~75% **and always-skip loses to
  it**. If that takes more than ~×3.5, it needs a threat, not health: Enemy Code gives act 1's
  bosses a mechanic that punishes a maze without Dreams (e.g. a charge on straights, shrugging the
  first status).
- **Spend or save (C):** spending now beats saving (reach 25: Fresh 48 vs 46, Early 50 vs 41) and the
  saver comes within 85% of the route far more often (25 vs 14; 29 vs 5). **Saving is the risky
  gamble now, as intended**; whether surviving it pays off later is checked in the run history.
- **Grove player (D):** medians Fresh 43 / Half 49 / Full 49. The Grove now adds ~6 drifts (was 0),
  no deaths at 26–33 with a Grove, 0 wins. Still short of "Half reaches act 4, Full wins": revisit
  after the Dream pass and the health rise; Grove perks get buffed then if still short.
- **All families, to 100:** the Sprout bot plays the swarm badly (median 14), so no verdict on "too
  easy"; the run history of real swarm runs decides. Balanced with all families: median 39.
- **Dream value BEFORE the power pass** (skip / random / Balanced × Fresh / Full × own / all
  families, 10 each): medians **35–45 everywhere**; always-skip beat the drift 25 boss **8–9/10**;
  Dreams gave ~5–18% of DPS at drift 50. **Confirms the user: Dreams barely mattered.** The same
  batch after the pass (cc38d56 + 5b72073) is the "after".

**Dream value AFTER the power pass** (cc38d56 + 5b72073; median death drift, before → after):

| Profile, families | Skip | Random | Balanced |
|---|---|---|---|
| Fresh, own | 41 → 41 | 43 → 45 | 45 → 49 |
| Fresh, all | 38 → 34 | 37 → 42 | 39 → 44 |
| Full, own | 35 → 37 | 44 → 41 | 45 → **62** |
| Full, all | 45 → 33 | 40 → 47 | 41 → **56** |

Dream share of DPS at drift 50: 0.05–0.18 → **0.12–0.39** (Balanced 0.21–0.39). Wins 1/120. **Dreams
now separate the policies** (skip < random < Balanced), most with the Grove.

Reading (design chat): the bot's random and Balanced runs already die **before** their targets (act
3 / acts 3–4), yet the user wins at drift 100: **the bot is much weaker than a person**, so the bot
can't set act 2–4 health. Decision:
- **Act 1 only, from the bot:** the act 1 boss sweep (×2.5 / ×3.0 / ×3.5; Fresh Balanced and Fresh
  skip, 20 seeds, to drift 26) until skip loses and Balanced wins ~75%.
- **Acts 2–4 from people:** the run history of real runs decides the rise (target: a sensible run
  ends in act 3–4, a build that comes together wins). Until then act 2–4 health stays.

## Human run 1 (2026-09-30, the run history's first record)

Fresh profile (7 Grove nodes, perk Morning Stores), Blight 0, the old health (before the interim
rise), 3× speed, 29 min. **Lost at drift 100 to the Hollow Oak: Remembering**; drifts 1–99 without a
single leak.

| What | Number | Reading |
|---|---|---|
| Leaks, drifts 1–99 | **0** (46 close calls, all in act 1–2 boss drifts) | acts 1–4 far too easy |
| Closest approach, drifts 51–99 | **0.00–0.3 of the route** (most 0.02–0.14) | nightmares die in the first tenth of the maze: a several-fold surplus, not 30% |
| Bosses | Hollow Stag 32 s, Mire Hag 20 s, Barrow King 18 s | no threat |
| Drift 100 | 12.6M health spawned vs 5.9M dealt, 15 leaves in one drift | one wall at the very end |
| Dew | earned 18,953; spent 9,650 (plant 1,095 · grow 4,681 · ranks 3,874); **9,277 banked** at the end | nothing left to buy |
| Omens | 18 faced, 0 Clear Skies, 4× Bountiful Night (×2.5 Dew) | Omens cost nothing to a strong maze and paid a lot |
| Dreams | 25 taken (Lucid Dreaming from 70), 0 passed | |
| Build | 59 Sprouts + 29 branches (88 attackers); Driftspore 31%, Bloomcap 14% | the Sprout swarm |

Decisions (design chat; the interim rise in run_design.md was too small for this):
1. **Health, replacing the interim:** act 2 ×1.3 at 26 → **×2.5 by 45**; acts 3–4 **×3.5**; **the Hollow
   Oak (drift 100) keeps today's health** so the curve builds up to it instead of ending on a wall.
   Act 1 as is (the first boss is tuned separately). Next human run checks it.
2. **Bountiful Night:** ×2.5 Dew → **×1.6**.
   **Late Dew cut** (user: "earn less late"): Dew per dispel by act **[1.0, 0.68, 0.45, 0.35]** (was [1.0, 0.68, 0.65, 0.5]; `RunState.act_dew_multipliers`).
3. **Dew had nothing to buy** once the map was full and ranks stopped at II. User's answer: earn less
   late (the cut above) **and** ranks III–V for Dew, with a choice at every rank: **Nurture v3**
   (`warden_stats.md`).
4. **Per-drift rows are unreliable when drifts are called early:** most drifts show 0.1–0.6 s and
   the block's health lands on its 5th drift. Record health, damage and leaks **by the drift that
   spawned the nightmare**, not by the drift that was current when it happened.

## Human run 2 (2026-09-30, build a596ea, after the Dream power pass and the health rise)

Fresh profile (7 Grove nodes), Blight 0. **Won at drift 100, 2 leaves lost (both at the drift 25
Scarecrow)**, 35 min. Build: **92 Thornwalls, 35 Honeysuckles**, 9 Morning Fog, 7 Puffball, 4 Dewdrop,
3 Sporeling (a poison-in-fog maze, path 188 tiles). Top Wardens: **one Puffball 76% of all damage**,
Morning Fog 20%.

| Stretch | Closest approach | Reading |
|---|---|---|
| Act 1 (drifts 6–25) | **0.54–0.86** (one 1.00 at 23) | right: tense, readable, the target |
| Early act 2 (26–40) | 0.28–0.72 | still has teeth |
| **Drift 41 → 100** | **0.08–0.22**, no leaks | the maze kills in the first ~15% of the route: too easy, matches the user's *"good until mid act 2"* |

- **Bosses:** Scarecrow 183 s (a real fight, cost the 2 leaves), Mire Hag 35 s, Moth Queen 92 s,
  **Hollow Oak 17 s** (the drift 100 boss is trivial now that it was exempted from the ×3.5).
- **Dew:** earned 15,274; spent on growing 6,915, ranks 2,450, clears 1,663; the bank rose to ~1–2.7k late
  (better than run 1's 9k; the late cut works).
- **Dreams:** 28 taken (Lucid Dreaming at 50), a poison build (Lingering Spores I+II, Spore Cascade
  I+II, Mushroom Rain, Monoculture late).

Decisions (design chat):
1. **Puffball is the outlier** (one Warden, 76%): its area puff gives **1 Poisoned** (was 2) and **keeps its 16-stack cap** (revised: the cap is its identity, "the deepest poison"; user asked whether it stays unique). Not:
   hit cap 16 → 12. Check the "Top" attribution too: Spore Cascade spreads
   and fog-boosted ticks may all be credited to the first applier (fine if true, but verify).
2. **Hollow Oak at drift 100:** ×1.6 → **×3.0** (17 s is no final boss; run 1's wall was before the
   boss-stays rule and the old curve).
3. **Steepen from mid act 2** (both runs agree): act 2 ends at **×3.0** (was 2.5) with the ramp's
   steeper half from drift 38; acts 3–4 **×4.0** (was 3.5). Act 1 and drifts 26–37 unchanged.
4. **Chain falloff** (already queued) lands with these. Next human run checks all four.

## Human run 3 (2026-10-01, build ebc899, fresh profile with 0 Grove nodes)

Abandoned at drift 50 by the user (*"I know I can beat 100 already"*), 6 leaves lost (4 at drift 9–10,
2 at 31–32). Spore + water build: **2 Puffballs = 76% of all damage** (57% + 19%), 6 Bloomcap, 4
Driftspore, 5 Rain Lily, 20 Sprouts. Bosses: **Hollow Stag 38 s, Lamplighter 29 s**. Dew earned 6,995,
banked up to 1,671 at drift 25. Closest: act 1 mostly ~0.30 (one leak spike at 9); act 2 0.17–0.68,
drifts 44–49 ~0.20.

Decisions (design chat):
1. **Puffball is still the outlier** after the stack nerf. The cause: Poisoned stacks tick at the
   **strongest applier's Potency** (Puffball 1.3), so one Puffball lifts every Sporeling's and
   Driftspore's poison. Puffball **Potency 1.3 → 1.0**; its deep cap (16) and area stay.
2. **Act 2–3 bosses are trivial** (Mire Hag 35 s in run 2, Lamplighter 29 s here):
   `boss_health_multiplier` **1.5 → 2.25** for acts 2–3 (act 1 keeps its tuned ×1.75, the Oak its ×3.0).
3. Act 1's first half reads a little calm (~0.30) after the lean pool; watch, no change yet.
4. A fresh profile reaching drift 50 comfortably and "knowing it can beat 100" says late acts are
   still soft: the next run after these two fixes decides whether acts 3–4 go from ×4.0 to ×5.0.

## Human run 4 (2026-10-01, build 82373f, 1 Grove node)

*"Still lost, but felt easy."* Lost at **drift 50 to the Huntsman: 20 leaves in that one drift** (the
first leak of the run). Drifts 1–49: **closest 0.07–0.48, mostly 0.10–0.25** (act 2 ~0.09–0.27), no
leaks; leaves rose to 20 from Omen rewards. Night Mare 23 s. Two families only (spore + water);
Puffballs 25% + 25%, Bloomcap 14% (Potency 1.0 is fairer). Dew earned 5,814 by 50.

Reading: **easy drifts, then a wall.** Normal drifts never threaten, so the player has no warning,
and the Huntsman (pack shield, hounds respawning every 12 s, now ×2.25 and staying to drain) becomes
unkillable once he reaches the Heartwood.

Decisions:
1. **Normal drifts harder from act 2:** act 2 starts at **×1.6** (was 1.3) and ends at **×3.6** (was 3.0);
   acts 3–4 **×4.8** (was 4.0). Act 1 unchanged. Target: closest ~0.4–0.7 most drifts, the odd leak.
   The gentle half of the ramp keeps its shape: **×2.3 at drift 37** (`act2_steep_value`, was 1.995),
   so act 2 goes 1.6 → 2.3 (26–37) → 3.6 (45).
2. **Huntsman at the Heartwood:** his horn stops (no new hounds while he drains), and his pack shield
   only counts hounds within 3 tiles of him, so clearing the hounds around the tree lets the maze
   finish him.
3. Next run checks both; the act 2–3 boss ×2.25 stays.

## Later

A **human baseline**: the same CSV written from real playtests (debug builds only), so the bot's
curve can be checked against how people really play.

## Run history (2026-09-30, user: "keep a run history to check balancing")

Why: the user beat drift 100 (an "Unlock all families" dev run, a Sprout swarm with Many Hands at 139
attacking Wardens, 7 Grove nodes) and "felt it might be a bit too easy", while the Grove-player bot
wins 0/30. Nothing about that run was kept. **The bot is weaker than a person**, so its numbers
underestimate player power; the history is the check.

- **Saved on every run end** (win, loss, abandon), real game **and** dev runs (tagged `dev`, with
  which dev setting: all families / Test Grove / Dev Grove preset), never from tests. Last **50** runs
  in `user://run_history.json`, separate from the profile so it can be sent along with bug reports.
- **Per run:** date, build version, map seed, demo/full, Blight Level, Grove nodes owned and perks
  carried, result, drift reached, play time, leaves lost **per act**, close calls; family picks
  (offered and chosen); Dreams taken (with the drift) and skipped; Omens faced / Clear Skies and their
  rewards; bosses met and dispelled (time to dispel); Dew earned / spent on planting, growth, ranks,
  clears, and banked at each rest; Wardens at the end (count by form and rank, number of attackers);
  top 5 Wardens by damage and their share; combo and Reaction counts; Dreamlight earned / spent.
- **The exact build it was played on** (2026-09-30, user: *"make sure you know what version I am
  playing on; versions are not commits but every change"*). Many chats edit the folder at once and
  the user plays whatever is on disk, often with uncommitted edits, so a commit hash isn't enough.
  Each record carries:
  - **`build_id`**: a short hash of the **contents** of every script and data file the game loads
    (`.gd`, `.tres`, `.tscn`, `project.godot`, `.json` data), computed once at launch (debug builds)
    or baked at export. Any change, committed or not, gives a new id; the same files give the same id.
  - **`commit`** (HEAD) and **`dirty`**: the uncommitted files at launch, each with its own content
    hash, so a build can be matched to "commit X plus these edits".
  - **`build_time`** (when the id was computed) and a readable **`build_label`**: "Sep 30 21:14 ·
    3f9a2c" shown on the title screen (debug) and in the run report.
  - **`balance`**: a snapshot of the tuning numbers that matter for comparing runs (DriftDirector
    health multipliers per act, boss multiplier, starting Dew and leaves, rest bonus, Dew per act),
    so two runs on different builds can be compared number by number.
  - A local **`builds.json`** log next to the history: every new `build_id` the first time it's
    launched, with its commit, dirty files and time, so the design chat can see which changes
    landed between two runs.
- **Per drift, compact:** drift, leaves lost, Dew banked, nightmare health spawned vs damage dealt,
  closest approach (share of the route). Same column names as the bot's `runs.csv` / drift log, so
  `tools/balance_summary.gd` can read human and bot runs side by side.
- **In game:** a "Past runs" page in the Codex (results screen style, newest first; dev runs marked)
  and a "Copy run report" button there and on the results screen for sharing with the design chat.
- **Design use:** after each playtest the design chat reads the history (the file is local) and
  compares it with the bot at the same Grove level and families.

## Do the tests consider Dreams? (answer, 2026-09-30)

Yes: every simulated run takes a Dream at every rest through `DreamSimPolicy` (by style: Balanced,
Wide, Sprout, Mixed…), grows forms with Dreamlight and meets random drifts and bosses. Its limits: it
picks by tag score, not by reading a synergy the way a person does; it doesn't reroll or banish
well; Omens are "Clear Skies" unless the batch says otherwise; and no batch has run **all families
unlocked** (the user's winning setup). Next batch: **Sprout swarm with all families, to 100** (the
Sprout cards the user took: Many Hands, Sprout Surge, Seedfall, Quickened Sap, First Light, Last
Stand), and the Balanced bot with all families, to see how much the family choice alone adds.
