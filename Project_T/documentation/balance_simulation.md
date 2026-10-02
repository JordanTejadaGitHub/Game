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
   so act 2 goes 1.6 → 2.3 (26–37) → 3.6 (45). **In the game from 474e76c6** (local main; the next
   human run should be on that build or later).
2. **Huntsman at the Heartwood:** his horn stops (no new hounds while he drains), and his pack shield
   only counts hounds within 3 tiles of him, so clearing the hounds around the tree lets the maze
   finish him.
3. Next run checks both; the act 2–3 boss ×2.25 stays.

**Note: run 4 called most drifts early** (user, 2026-10-01). Early calls stack drifts on the field, so
"closest 0.10–0.25" was measured under *harder* conditions than normal play: the act 2 "too easy"
reading is stronger, and a player who never calls early will find the new curve gentler still.
- **Per-drift rows are fine for runs 2–4:** RunHistory counts each nightmare under the drift that
  spawned it since ae47049e (2026-09-30 10:36); only run 1 is blurred per drift (per block is fine).
  Early calls are recorded **from 9a31505a**: run-level `early_calls` and `dew_call_early`, per-drift
  `called_early` (last CSV column), report line "Called early: N drifts · X Dew". Runs 1–4 lack them.
- **Call-early Dew stays outside the pot, unchanged** (+1 per 2 s skipped, cap 10 per drift, ~500 by
  drift 50 = ~9% of run 4's income). It pays for a real risk (stacked drifts), which the harder act 2
  makes bite. Revisit if a run with `early_calls` data shows calling early as both safe and the
  bigger Dew source.
- **Omen rewards** (user, 2026-10-01): no leaves (0891119a), then **no Dreamlight either** ("leave it in
  cards", f2f2a428). Tramplers +50 Dew and Stubborn Blight +40 Dew are starting numbers; the
  three-mode Omen sim on the new rewards sets them.

## Omen three-mode sim (2026-10-01, build f214066a, full profile, 20 seeds per mode, to 40)

Balancing Code, `tools/balance_omens.gd`. **Saturated by the act 1 boss:** 9–10 of 20 bots per mode
die exactly at drift 25 (the Hollow Stag drains 14–18 leaves from untouched bots), so run-level leaf
and dormancy targets read 18 vs 18 and 100% vs 100%. **Measured before the wall (by 20), Omens bite:**
always +5 leaves (median), +25 points dormancy, clean 0.87 reward shares per Omen-block leaf vs 0.38;
drift reached always −5.0, clean −4.2 (mean).

Decisions:
1. **Measure without the boss:** re-run with `--last=24` on the build with the no-Dreamlight rewards
   (f2f2a428); a half-profile batch to 50 later for acts 2–3 rewards.
2. **The Stag wall is the bot, not the game** for now: humans passed him in runs 2–4 (38 s in run 3).
   Watch the next fresh human run (target: beats him ~75%).
3. **Pot-multiplier Omens are out of scale** (Bountiful Night ×2 = +580–800 Dew a block in act 2,
   5–8× the biggest fixed reward): **Bountiful Night ×2.0 → ×1.5**, **Blood Moon ×1.75 → ×1.4**;
   their twists (+35% health / +35% speed) stay.
4. **Dry Spell is a pure loss under the pot** (−556 to −769 Dew in act 2 for +27–35 rest bonus).
   New: **no Dew from nightmares during the block; at the rest the Heartwood releases the block's
   pot ×1.25**, cut by leaves lost like any reward (25% per leaf). The twist becomes "build without
   income, get paid late"; the ×1.5 rest bonus goes.
5. Fixed Dew rewards are in scale (≤ one drift's pot); Tramplers +50 and Stubborn Blight +40 stay.
6. The sim's `omen_dew` should count the pot multipliers' extra (or loss) too (321811ef).
   In the game: e5de9471 (rewards, Bountiful / Blood Moon, Dry Spell) and bd507e42 (Dry Spell pays the
   pot the block would really have paid, with the player's own multipliers, × 1.25).

**Batch (a), act 1 without the boss** (e5de9471, full profile, `--last=24`, 20 seeds × 3 modes):
**all three targets met.** Always vs Clear Skies: **+9.5 leaves** (median, by 24; target ≥ 3), dormancy
**30% vs 5%** (+25 points; target ≥ +10); picking moments **0.52 vs 0.38** reward shares per Omen-block
leaf ✓ (per run leaf a tie, 0.15 vs 0.16). Mean drift reached 23.9 / 21.8 / 23.3. Omen reward Dew
~50 median per run: in scale. No change. Batch (c) (half profile to 50, on 4993001b) checks acts 2–3
and the Dry Spell +25%.

**Batch (c)** (4993001b, half profile to 50): **the Omen Dew is right**: clean Dry Spell nets exactly
**+25%**, Bountiful Night +50%, Blood Moon +40%, fixed rewards at their table values. The acts 2–3
check failed to run: **12/20 Clear Skies bots die at the Stag** again; only 3–8 runs per mode start act
2. Next: Balancing Code finds out **why untouched bots lose all 18 leaves to the Stag** (maze DPS vs
his health and route time, Dew banked at 24, drain speed). That's the "easy, then a wall" shape
from human run 4, so it may be a game change, not just a bot fix. Then an Omen batch with the act 1
boss at ×1.0 (test-only) for acts 2–3.

## The Stag wall and the boss drain (2026-10-01)

**Diagnosis** (Balancing Code, full profile, 20 seeds): the drain, not DPS or banking. 13/18 Stags
reached the Heartwood, 12 of them with **no Warden in range there**, so health left didn't matter: 38
health (0.7%) left cost all 18 leaves, the same as 3,400. The bot now covers the Heartwood from drift 18
(23736625): Stag dispelled **28% → 79%**, median 0 leaves drained in wins. But one covering Warden
(~45–100 DPS) only saves it below ~1,000–1,800 health left, so the game-side cliff stays.

**Decision (user, 2026-10-01: "most bosses just lose a lot of leaves and have 1 boss that sticks"):**
- **Only the Hollow Oak (drift 100, every form) stays and drains** until dispelled: the last stand.
- **Every other act boss takes a flat bite and leaves:** **8 leaves in act 1, 10 in act 2, 12 in act 3**
  (user chose flat over health-scaled). Elite/escort leaks unchanged.
- **The Night Mare keeps its own laps** (untouchable lingers that drain, then another lap).
- This replaces enemy_design.md's "A boss that reaches the Heartwood stays" for every boss but the Oak.
  Act 1's target "always-skip loses to the boss" now has to come from leaks before 25 plus the 8.
- **Leaf Fall is never offered for a block with a boss drift** (its ×2 would make the bite 16–24
  leaves: a boss must never one-shot the run).
- In the game: **bfc33e75** (boss bite, `EnemyContainer.boss_bite_leaves` [8, 10, 12],
  `EnemyData.stays_at_heartwood` on the Oak; the Huntsman's silent horn dropped) and **b708815a**
  (Leaf Fall, `OmenData.never_before_boss`).

**Act 1 boss check with the bite** (0b4861b6, cover rule, Hollow Stag 5,250, 20 seeds): survived the
boss: **fresh Balanced 90%**, fresh skip 45%, full Balanced 80%, full skip 65%. The cliff is gone
(fresh Balanced bots that nearly kill him pay 8 and carry on). Too kind against the targets (~75% /
skip loses), and humans play better than the bot: **act 1 bite 8 → 10** (`boss_bite_leaves` [10, 10,
12]); re-check fresh only. The full profile doing worse than fresh (29% vs 67% dispelled) is on the
bot's side (same boss health). **Cause (measured):** the first family. Fresh always draws Sporeling
(every start offer has it; Balanced picks it): 20/20, Stag dispelled 67%. Full offers 3 of 9 families:
Sporeling 7/20 (dispelled 50%), **other families 2/11 (18%)**; Pebbling is resisted by
the Stag (stone; Acorn is neutral, never resisted), Firefly lost 3/3. Same attackers, tiers and card counts in both: no thinning.
So **non-Sporeling families look weak in act 1** (n = 1–5 each). Next: a per-family act 1 batch
(10 seeds per forced family), then a same-family Grove control (fresh / half / full, Sporeling + one).

**Omen batch, full profile to 50** (0b4861b6): always facing reaches **~10 drifts less** (19.9 vs 29.6)
and loses **+10 leaves by 25** ✓; clean reaches 5.7 more drifts than always but pays the same per leaf
(0.27 vs 0.28). Every Omen's Dew is as designed. **Act 2 kills every bot profile**, so acts 2–3 Omens
are read from human runs, not the sim. **The Omen check is closed** for the sim: targets met in act 1.

**Bite-10 re-check** (e19b9230, fresh, 20 seeds): Balanced survives the boss **90%** (Stag dispelled
89%), skip **45%** (6 of skip's 11 deaths come before the boss; skip runs that fight him often survive
the 10 on 5 leaves). The bite alone can't push skip to ≤ 25%. **Held** until the per-family batch:
fresh runs here are all Sporeling, so act 1 boss health is set once the family spread is known.

**The Night Mare** (user: "feels useless now, since its mechanic is to do it multiple times"): at
2,286 base (×1.75 ≈ 4,000, under the Stag's 5,250) it dies on its first pass (23 s in run 4), so its
laps never show, and one visit (5 leaves) is half the other bosses' bite. **Health ×1.5 (3,430 base)**
so a typical maze needs two passes; visits stay 5 / 7 / 9 leaves (one lap is kinder than a bite, two are
worse). Check: Night Mare forced, fresh Balanced / skip; target Balanced laps once+ in ~60% of fights.
**Result** (cde782f3, 6,003 health, 20 seeds): Balanced **laps 88%**, dies on lap 2 in 12 of 15
dispels, **survives 75%**, median 5 leaves drained ✓ all three. Skip survives **35%** (12 leaves): the
act 1 boss that best separates Dreams from skipping. **Kept.**

**Per-family act 1** (e19b9230, **full profile** so every family has its branches; first family
forced, 10 seeds; the fresh run was confounded: unowned families had no branches):

| family | survived boss | Stag dispelled | leaves lost before the boss |
|---|---|---|---|
| Rootling | 100% | 9/10 | 0 |
| Nestling | 100% | 8/10 | 0 |
| Dewdrop | 90% | 6/10 | 0 |
| Firefly Jar | 70% | 2/8 | 1 |
| Sporeling | 80% | 2/9 | 1.5 |
| Bellflower | 90% | 2/10 | 0 |
| Pebbling | 100% | 1/10 | 0 (highest maze DPS, 673, but stone is resisted) |
| Whirligig | 100% | 0/10 | 4 |
| **Acorn** | **50%** | **0/10** | **6** (2 runs dead before 25) |

Decisions: **"beats the first boss" = survives it**: 8 of 9 families at 70–100%, so **the Stag stays**.
**Acorn +15% attack damage** across its forms (auras unchanged; Tower Code): the only family that
leaks in normal act 1 drifts. Whirligig holds normal drifts, no change. Sporeling dispels 2/9 on full
vs 6/9 on fresh: possibly a big Grove Dream pool diluting the cards; the same-family Grove control
(Sporeling + Firefly Jar, fresh / half / full) measures it. The "skip loses by 25" target is still
unmet (Sporeling skip on full survives 70%); act 1 health is held for the next fresh human run.
**Caveat (user: "are we testing that we have Wardens around it?"):** no. The bot places by path in
range only, so Acorn's auras (the 8 around; Grove Heart radius 2, +3% per Warden) land by chance and
the support family is undersold. Balancing Code adds aura-aware placement; the Acorn re-check runs
with and without it on the same seeds.

**Acorn re-check** (e0627b99: Acorn +15% from 67e4e9f6, aura-aware bot with AURA_WEIGHT 2 tiles per
Warden, cap 5; full, 10 seeds): Balanced survives the boss **100%** (was 50%) and loses **0 leaves
before him** (was 6): the +15% fixed the normal drifts. The auras add **+15% maze DPS** (537 vs 466;
skip +10%, and 100% vs 70% survival). Acorn still almost never dispels the Stag (1/40). Not a
resistance (Acorn is neutral, line `acorn`; he resists stone and root only): its damage on him (~2,100–
3,000 of 5,250) is low. The bite keeps it survivable; watch Acorn's boss damage, no change yet. **Closed:** no first-pick change (Tower Discussion's fallback not
needed). The bots never grew Dewcatcher / Wellspring / Grove Heart (first-form blind spot), so the
economy branches are unmeasured.

**Bot upgrades for the Grove control** (bfa430cd): Kinship placement (+2 tiles per unbonded kin in
reach, cap 5, sticky bonds respected), the grow step picks the branch that bonds / the rarer one, and
Dreamlight unlocks a family's two branches before its finals (finals arrive a little later). Still
blind: the 9 hidden Kinships (third branches).

## Grove control (2026-10-01, bfa430cd, Sporeling + Firefly Jar forced, auras + kin, 20 seeds, to 50)

**The Grove shows no measurable gain; fresh ≥ half ≥ full.** Mean drift reached 34.0 / 33.1 / 31.9;
reached 35: 8 / 8 / 6 of 20; Stag dispelled 14/19, 15/20, 12/19. Perks add +7% maze DPS at 24 (583 vs
543), which doesn't turn into survival; every run dies in act 2.
**Dream pool dilution, measured:** the drawable pool goes **49 → ~91** cards (half already owns nearly
every card node), and ~6 cards are taken by 50 in every profile. *(The first "fits the build" shares, 36% → 24%, were
**invalid**: the classifier counted style-only cards like "maze" or "economy" as off-build.)*
**Re-run** (e4e54ba2, family-line classifier, same seeds): matched 24% → 17%, generic ~75% in all,
off-build **1% → 8%**, and of those 69 offers only **10 are dead** (~0.8% of offers on Grove
profiles: patient_roots with no status gate; rolling_thunder, rain_on_glass gated on unlocked, not
planted, Wardens; heavy_eyelids is usable, since Bloomcap applies Drowsy). **No dilution problem.** Survival: 32.7 / 31.8 / 32.9 mean drift
reached, so the first run's "fresh ≥ half ≥ full" was noise: **the bot shows no Grove effect either
way** (every profile dies in act 2). The Grove's value has to come from human runs on Dev Grove
presets. The "dead" offers turned out to be **by design** (Roguelite Code, 35efae49): patient_roots
is a Seed card that calls the Rootling family to the next pick; rolling_thunder / rain_on_glass are
half-dreamed "Adapt" offers. **No change.**

## Map change: inland Heartwood (722cf38b, 2026-10-01)

Environment Code: the Heartwood sits on an inland cell (its 8 neighbours always open, reachable from
several sides), the start stays on the rim; opening routes are a little shorter (median 39 corner / 44
side vs 46; band 35–57); 240–294 buildable cells; ~69 obstacles. **Every sim and human run above is
"edge Heartwood"**; human run 5 (ee3d82d0) predates it. Re-baseline: act 1 fresh Balanced / skip on
722cf38b+, plus a check that the bot's maze and cover rule handle the open glade.

## Human run 6 (2026-10-01, build 88ef33 = b2d8b3e6: **first run on the inland Heartwood**, intro-elite fix)

**Lost at drift 24, before the boss**, 1 Grove node, Firefly Jar again, no early calls. 13 attackers,
5 Thornwalls, 7 Sprouts (run 5: 17 Thornwalls, 15 Sprouts). Dew earned 1,896 by 24; banked up to 875
at drift 20, spent at that rest.
- **Act 1 closest 0.41–0.70 from drift 1** (run 5, same family and Grove on the edge map: 0.25–0.55
  outside block 3). Leaks at drift 8 (5 nightmares, 5 leaves) and **drift 22 (9 nightmares, 10
  leaves)**; 17 close calls.
- Same curve as run 5, so the differences are the **map** (shorter routes, open glade) and the maze
  (fewer walls). Two Firefly-first runs lost 9 and 15 leaves in act 1 against a fresh target of 0–3.
- User: *"I like the Heartwood inland; making it shorter doesn't matter because you don't have
  enough towers to make a difference. It feels fair. I haven't unlocked perks yet so this is fine so
  far. Needs a bit more testing."* **No change.**
- **Sim re-baseline** (980f0b41, fresh, Sporeling via the bot's pick, 20 seeds): the map change is
  within noise (same old bot, edge → inland: Balanced survives the boss 90 → 85%, skip 45 → 50%; the
  opening route is ~4 tiles *longer* at drift 1). The newer bot (Kinship placement + branches first)
  lifts Balanced to 95% and skip to 70%. **New baseline = inland, current bot.** An exact edge/inland
  A/B (4c8050a9 vs 722cf38b, Sporeling and Firefly first, 20 seeds): **no map effect**; inland is if
anything a little easier (Firefly: leaves lost by 25 8.5 → 3, first leak 9 → 14; survived 90% both).
Run 6's early pressure was that seed or the opening, not the inland change. Closed.

## Human run 7 (2026-10-01, build 25755d = cbae70bc, before status Potency; 1 Grove node)

**Abandoned at drift 80** (29 min, "started lagging": that was 8 parallel sims starting at the same
time, not the game; sims are capped at 2 while the user may play). Firefly → Sporeling (25) → Dewdrop
(50); 16 Dreams, none passed, Kinship-heavy (extended_family, grove_of_kin, spore_kin, kin_and_kindling,
old_friends) plus both family Blessings; 15 Omens faced, 0 Clear Skies. Dew earned 11,861.
- Closest: **act 1 median ~0.33**, no leaks; **act 2 median ~0.16** (0.05–0.44), no leaks, banked up
  to 1,230 at 45; **drift 50: the act 2 boss bit for 10** (the run's biggest loss); **act 3 median
  ~0.27**, 2 leaves; act 4 2 leaves by 80. Scarecrow 70 s, Barrow King 48 s.
- **2 Dreamshrooms = 61% of all damage** (47% + 14%), under the old status rules.

Reading: with a good build, act 2–3 normal drifts don't threaten a human, against the target "a fresh
profile ends in act 2" (runs 5 and 6 ended at 35 and 24, but run 5's act 2 also read 0.22–0.29 before
its flyer leak). Decisions:
1. **Acts 2–4 health +25%:** act 2 **2.0** at 26 → **2.9** at 37 → **4.5** at 45 (was 1.6 / 2.3 / 3.6);
   acts 3–4 **×6.0** (was 4.8). Act 1, boss multipliers, the bite and the Oak unchanged. In the game: d55618fd.
2. **Dreamshroom:** measure before changing: per-final damage shares in the status-Potency A/B, and a
   fixed-maze probe (Dreamshroom vs Morning Fog / Mistveil / Puffball, damage per Dew).

## Potency scales statuses (user, 2026-10-01; tower_design.md 175bf263)

Caps confirmed: **Soaked** water bonus 20% × Potency, cap +40%; **Exposed** 25% × Potency (Beacon
included), cap +40%; **Drowsy** slow per stack × Potency, floors unchanged; **Rooted** duration ×
Potency, cap 2 s. **Deep rank = +18% Potency only** (the separate duration bonus goes). Several
appliers: the strongest current applier's Potency (as Poisoned). Exposed caps at Potency 1.6 (~3 Deep
ranks on a base Warden). Built behind a toggle; A/B on the same seeds (maze DPS, Exposed share, how
often the caps bind) once it lands.

**A/B (c961b3ec, full, 20 seeds, Power-focus bot):** on vs off barely differs (drift reached 32.2 vs
32.0 spore+dew, 28.7 vs 28.0 firefly+bell; maze DPS +4–14%), and **no cap ever binds**: applier
Potency stays ~1.0–1.37 because the bot nurtures Power, never Deep. Harmless for Power players;
untested for Deep builds: a `--focus=deep` check follows. Per Warden, **Bloomcap ~18% of all damage
each** (mostly Spored ticks) vs Driftspore 7%, Sporeling 5%; Dreamshroom too rare for the bot (2/80);
a fixed-maze finals probe measures it.

**Deep-focus check** (8bed3b93, `--focus=deep`, 10 seeds): Deep builds are **weaker than Power**
(drift reached spore+dew 28.4 vs 32.5, firefly+bell 21.8 vs 28.1; firefly+bell Deep lost 17 leaves by
25). Status strength reaches ~1.2–2.2; Soaked sits at its cap 27% of the time, Exposed never (max 1.56).
**Deep rank +18% → +25% Potency** (rank IV Deep = 2.0); re-check after Tower Code's commit.
**Re-run** (a9951bd1, 27155a73 in, Power re-run on the same build and seeds): gap to Power **−2.2**
drifts (spore+dew) and **−3.1** (firefly+bell), halved; Deep maze DPS at 24 now *above* Power (549 vs
518, 644 vs 571); Exposed at its cap 5% of the time ✓. Deep still survives the act 1 boss less (7/10 vs
9/10; firefly+bell Deep median 13 leaves by 25 ≈ the bite). The bot runs Deep on every Warden from
drift 1, before a second family exists for its statuses to pay off; a player choosing Deep later
wouldn't. **Accepted, closed:** within noise of the target at 10 seeds; Deep is the act 2+ choice.

## A 4th starting family (user, 2026-10-01)

User: *"We should have one more family unlocked for new accounts so wave 75 is there."* A fresh account
owned 3 families, so the picks at 1 / 25 / 50 used them all and drift 75's pick fell back to +2
Dreamlight. **Bellflower becomes a starting family** (user's pick from four options: it combos with all
three starters through Drowsy and Static, and it's mid-strength in the act 1 batch, 90% survive). With
Meta Game Discussion → Meta Game Code. The first pick now offers 3 of 4 (Sporeling not guaranteed).
Also (user): **the first family pick gives 1 Dreamlight, not 2**, so act 1 gets one branch and no final
before the boss (+4). Both make act 1 a little harder; act 1 re-baseline once they land.

## Route profiles in the run history (user, 2026-10-01)

User: *"Look where I've invested the most in the maze; it shows where most of the nightmares die."*
Requested from Main Merger: `dispels_by_progress` (kills + health per 0.1 of route progress, plus
leaked, per block), `invested_by_progress` (Wardens' Dew spread over the route cells they cover, at
each rest) and `heart_share` (Dew within 3 cells of the Heartwood), with report lines and, if cheap, a
heat-map PNG. The bot logs the same. Reads: front-loaded vs last-ditch builds, where leaks slip
through, and whether a kill zone pays for its Dew.

**Finals probe** (`tools/balance_finals.gd`, ≥ 144d371b, drifts 61–65, 4 copies in the same spots +
8 fixed finals, rank IV Power, no Dreams, 3 map seeds): per Warden over 5 drifts, **Dreamshroom
~319k vs Puffball ~154k, Morning Fog ~137k, Mistveil (branch) ~51k**; at the same 1,090 Dew,
**Dreamshroom is ~2.1× Puffball**, and its board leaks 19% of spawned health vs ~50%. 73–88% of its
damage is credited as status ticks (which ticks: being broken down). **Dreamshroom is a real outlier**:
the nerf targets whatever makes the 2× (target ≈ 1.1–1.2× Puffball), once the breakdown is in.
**Breakdown** (457a9807): ~88% is its **Dream Spores** twist (each sleeper in range puffs Spored onto
neighbours every 1 s at `get_damage() × 0.25` = 2× Puffball's stack, which also lifts the whole stack
to its potency and credit; every overlapping Dreamshroom puffs separately). Cloud 10%; the sleep is
only the trigger. **Nerf:** Dream Spores at **half soothe**, and **one puff per sleeper per second
across all Dreamshrooms**. Re-probe after Tower Code's commit.
**Drifts 45–49** (f80fb34d): Dreamshroom ~240k vs Puffball ~197k per Warden (**~1.2×**), board leak 0%
vs 15%: its edge grows with the field (2.1× at 61). Acceptance after the nerf: **1.0–1.3× Puffball in
both windows**; if act 2 drops below 1.0×, Dream Spores soothe goes ×0.5 → ×0.65.
**Re-probe** (a9951bd1, c7f3e56d in): **61–65: 1.22–1.25× on every seed ✓** (was 2.1×). 45–49:
per-seed 0.77 / 1.11 / 0.77, ratio of medians 1.05 (one high Puffball seed); its board still leaks
least (1.6–4.7% vs 12–20%). **Kept at ×0.5:** the board-level strength says it isn't weak in act 2,
and ×0.65 would push act 3 to ~1.5×. Watch it in human runs. Closed.
This conflicts with the targets (Half Grove reaches act 4, Full wins). Next: find out whether the
off-build cards are dead for the build (a `can_offer` rule fixes it) or usable (a pool-size question),
then bring the fix to the user. Caveat: one family pair, one bot style, which picks by tag + rarity.

## Human run 5 (2026-10-01, build b6d458 = ee3d82d0: run-4 curve, Dew pot, boss bite 10, Night Mare ×1.5, Acorn +15%)

Lost at **drift 35**, 1 Grove node (Morning Stores), no early calls. Firefly Jar first, Sporeling at
25. Top damage: 2 Stormcaps 51%, 2 Lanternmoths 23%. Dew earned 3,729 (ranks 2,140), banked ≤ 571.
Dreams 6 taken, 0 passed; Omens 4 faced, 1 Clear Skies.

- **Act 1 block 3 spiked:** closest 0.80–1.00 at drifts 11–15, **9 leaves lost** (first leak 13; the
  Swarm at 15 took 5). Blocks 4–5 settled at 0.25–0.55. Target for a fresh profile is 0–3 by 25.
  One run, and Firefly Jar (single target) against the Swarm is a readable matchup: **watch**.
- **The Stag: dispelled in 46 s**, no leaves.
- **Act 2 drifts 26–30: closest 0.22–0.29** (the breather), then **drift 31 cost 6 leaves**: it's the
  Phantom's intro drift (4 Phantoms, flying, fixed), and the guaranteed elite from drift 31 made one an
  elite Phantom; all 5 flew past (802 of 3,193 damage). Down to 1 leaf, then drift 34 (77k health,
  closest 1.0) ended the run at 35.
- Against the targets: **a fresh profile ending in act 2 ✓**. But the deciding leak was an intro
  drift doubled by a rule, which isn't readable.

Decisions:
1. **No guaranteed elite on a nightmare's intro drift:** `add_guaranteed_elite` never picks a kind
   whose `intro_drift` is this drift (skipped if nothing else is there). In the game: ade9a9ef.
2. Act 1 block 3 and act 2's start: no change from one run.

User: *"The run felt fair so far, lost because of flyers that I didn't notice would be coming from
the wave, but that is my fault."* So **the curve reads fair**; the loss was not seeing the first
flyers coming (a readability point for the Coming strip / new-nightmare warning, passed to the hub).

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
