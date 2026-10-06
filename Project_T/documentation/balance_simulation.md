# Balance Simulation

Design spec, 2026-09-28. Playtests keep finding "too easy" one exploit at a time (the Sapling, two
Great Bells, cheap Nurture on Sprouts). This tool measures the whole difficulty curve against the
targets in `run_design.md` ("Difficulty curve targets"), so balance changes are checked by numbers,
not by feel alone. It grows out of Tower Code's probes (`tools/balance_act3.gd`,
`tools/balance_run.gd`) and Roguelite Code's `sim_rest` / `sim_family_pick`.

## Current targets (from 2026-10-02: the Spire rules are in main, bebfb22c)

These replace the older targets below for the **full game**; the demo keeps the old curve
(`DriftDirector.DEMO_RULES`) and the old act 1 targets. Detail and history: `spire_difficulty.md`.

| What | Target |
|---|---|
| Average player | **first win after ~10–15 runs** |
| Skilled player, Blight 0 | **wins ~30–50%** |
| Fresh profile | usually dies in **act 2–3** |
| Act 4 | a real test |
| Every block | can kill you; the **block finale** (last drift, ×1.4 health + elites) costs an average maze ~1 leaf; a clean finale earns a Rare+ Dream slot |
| Bot, fresh, act 1 boss (full game, real boss draw) | Balanced **~55–60%** survive, skip **≤ 15–20%** |
| Grove | a full carried loadout adds **≤ +10–15 points** of bot survival / reach over no perks (measured +15) |
| Combos + Reactions | **~25–40%** of a good build's damage (`combo_share`) |
| Damage branches | **0.8–1.0× Driftspore** per Dew on the fixed board (drift 45); a drawn branch must match the one it replaces |
| Final forms | **0.8–1.5× Puffball** per Dew (drifts 45 and 61) |
| Supports / control | their board does **≥ par** with 4 of the reference |
| Dream builds | a decent build (≥ 3 picks of one tag) in **~50%** of runs; skipping Dreams loses |
| Every family | viable from act 1 (each start family survives the act 1 boss 70–90% for the bot) |

Human runs set acts 2–4 (the bot dies in act 2); the bot sets act 1, bosses, per-form probes and A/B.

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
- **Every other act boss takes a flat bite and leaves:** **10 leaves in act 1 (was 8, raised 2026-10-01, below), 10 in act 2, 12 in act 3**
  (user chose flat over health-scaled). Elite/escort leaks unchanged.
- **The Night Mare keeps its own laps** (untouchable lingers that drain, then another lap).
- This replaces enemy_design.md's "A boss that reaches the Heartwood stays" for every boss but the Oak.
  Act 1's target "always-skip loses to the boss" now has to come from leaks before 25 plus the bite (10).
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

Also (user, run_design.md 20df1914): **steady Dreamlight 3 per act boss** (was 4), **no +1 per rest
from drift 51**: 10 by drift 76 with the first pick's 1. Fewer finals and Ascended late: watch late-act
power in the next human run (it may offset part of the +25% acts 2–4 health).

## Human run 8 (2026-10-01, build a8e311 = a2353925+: run-7 curve, Bellflower a start family)

**Lost at drift 50 to the Lamplighter's bite** (13 leaves with 3 left), 17 min, 1 Grove node. Bellflower
first, Dewdrop at 25; 75 attackers (45 Sprouts, 13 Chime Stones, 12 Bellflowers, 4 Morning Fog). Four
Chime Stones = 76% of damage, with Live Wire ×3 and Hush ×2. Dew earned 6,023 (grow 3,750, ranks only
130). Banked up to 986 at 45.
- **Act 1 closest 0.08–0.25**, no leaks; the Night Mare dispelled in 22 s.
- **Act 2:** 0.08–0.68, spikes from ~38, **1.0 at 46, 47, 49, 50**; first leak at 49; all 15 leaves in act 2.
- **On target:** a ~fresh profile ends in act 2, and act 2 gets hard from its second half. **No curve
  change.** Act 1 reads calm with a Bellflower opener; watch against Firefly runs 5–6 (much harder).
- Chime Stone: a branch probe (no Dreams, drifts 45–49) before judging, since run 8's share came with
  Live Wire ×3 and 13 Chime Stones.

User: *"Felt balanced; the Chimes in the beginning felt broken though, since I just upgraded them once
and let them sweep past to drift 40. Maybe have a smoother difficulty curve."* Decisions:
1. **Chime Stone damage 35 → 26** (area pulse 28 DPS + its own Static set off every 3 pulses: one
   upgrade carried act 1). Static and set-off unchanged; branch probe (drifts 15–19 and 45–49) checks it.
2. **Act 2 linear, no knee:** **×1.7 at 26 → ×4.5 at 45** in one line (`act2_steep_value` 3.3 at 37; was
   2.0 → 2.9 → 4.5, gentle then steep where run 8 broke). Act 1, acts 3–4 unchanged. Both in 3faea358.

**Act 1 baseline with the first pick at 1 Dreamlight** (781b1cbb, Bellflower a start node, fresh, 20
seeds): Balanced survives the boss **70%** (target ~75% ✓; was 95% with 2 Dreamlight), skip **45%**
(target ≤ 25%). By first family: **Sporeling 80%, Firefly Jar 40%** (5 runs), matching human runs 5–6;
the bot never opened with Bellflower or Dewdrop. Kill profile: most nightmares die at 0.3–0.4 of the
route in every block; the bot's Dew sits evenly over 0.1–0.9. Next: each starting family forced (10
seeds) on the Chime Stone / linear act 2 build.

## Human run 9 (2026-10-01, build 18d296 = e3cf8f41: **before** 3faea358, Chime Stone 35, old act 2)

**Lost at drift 50 to the Huntsman's bite** (6, the last leaves), 15 min, 1 Grove node. Bellflower first,
Firefly Jar at 25; Chime Stone 38% + Thunderhead 36% of damage; ranks 1,925 Dew. Act 1 closest
0.12–0.28, Stag 31 s; act 2 leaks from 33 (2), 44, 47, 49; all 15 leaves in act 2. **On target**, same
shape as run 8; no change beyond 3faea358.

**First human route profile:** almost every kill is in the **first 0.3 of the route**, and the Dew sits
at 0.0–0.3 (a second cluster at 0.5–0.7 from block 7), **nothing in 0.8–1.0, Heartwood share 0%**. The
bot is the opposite (kills at 0.3–0.4 median, Dew even over 0.1–0.9, a Heartwood cover). The human
plays a front-loaded kill zone with no second line, so once act 2's late drifts break the entrance
nothing behind it catches them, and the act 2 boss bites. A playstyle read, not a number change; worth
telling the user, and worth a bot style (`--style=front`) if bot and human should compare.

**Forced first family, act 1** (1c9fb3bd = 3faea358 in; fresh, 10 seeds): survived the boss
**Sporeling 70%, Firefly Jar 70%, Dewdrop 90%, Bellflower 90%** (Bellflower by taking the bite: 1/9
dispels). **Every starting family is viable in act 1: closed.**
**Branch probe** (no Dreams): drifts 15–19 rank II, Chime Stone (26) ≈ Rootcurl ≈ Stormcap at the top
per Dew (the field is cleared, so this is who takes the kills); drifts 45–49 rank IV, Chime Stone is
mid (behind Driftspore, ~2× Stormcap). **Chime Stone accepted.** Flag: **Lullaby Bell** (its final) is
~3× Driftspore per Dew with a ~0% board leak (a probe finding; runs 8–9 had no Bell, their carrier was pre-nerf Chime Stone); 40–53% of the Chime
line's damage is Static bolts, which they charge and set off themselves (Static + set-off at 3). Finals probe next (Bell vs
Puffball / Dreamshroom / Morning Fog, with and without Thunderhead).

**Lullaby Bell finals probe** (3d7c5d9f, 4 copies, rank IV, no Dreams, 3 seeds; "finals" cast with
Thunderhead, "nocharge" without): per Dew vs Puffball, **Bell 1.65× (45–49) / 2.62× (61–65)**, 3.2× /
5.4× without a Static partner (it charges and sets off its own Static; half pulse, half bolts); act 2
board leak ~0%. Dreamshroom (post-nerf) 0.89× / 1.21× ✓. Morning Fog 0.75× with Thunderhead, 0.25×
without (87% of its damage is Thunderclap): a combo final, no change. Puffball loses ~half without
Thunderhead (cause not traced). **Bell: damage 123 → 80 and set-off at 4 stacks (was 3)**, expected
~0.95× / ~1.5×; re-probe (band ~0.9–1.5×, area finals scale with crowds).
**Bell re-probe** (be52dc39 = 90ad7f61 in, finals cast, 3 seeds): median **1.50× (45–49), 1.42×
(61–65)**, one map at 2.28×; boards still leak least (1–3% vs 11–21% at 45). Top edge of the band, so
**one more step: damage 80 → 72** (expected ~1.35× / 1.28×), in b1374ae8. Closed.
Why Puffball halves without Thunderhead: **Ignite** (Spored 3+ and Static → Spored ticks ×3 for 3 s,
re-fired while Static keeps coming): measured, 63% of Puffball's damage with Thunderhead (183k vs 76k per Warden without). A combo working as designed: no change. But its extra ticks were
tagged only "spored", invisible to combo feedback and the sims: Tower Code tags them "ignite".

**Act 2 boss too hard** (user: *"is the boss too hard? Didn't feel close to killing it"*): **0 of 3**
human runs killed it: run 7 (×3.6 act 2) ~10% of drift 50's health left, run 8 Lamplighter ~21%, run 9
Huntsman ~25% (health spawned vs damage at drift 50). The ×2.25 was set when act 2 ended at ×3.0; it
rides the act multiplier, now ×4.5. **`mid_boss_health_multiplier` 2.25 → 1.75** (act 3's boss lands
near its old effective health under ×6.0). Act 1 boss, the Oak and the bite unchanged. In: f1b10216.

## Human run 10 (2026-10-01, build 3de1d4 = 735ff30a+; first run with route lines)

**Lost at drift 18**, Sporeling only, 1 Grove node; user: *"This run seems fine, the Omen is what got
me."* Act 1 closest 0.44–0.72, no leaks to 15, kills at 0.4–0.5 of the route. Took **Second Path** at
the drift 15 rest: the crumbled Thornwall shortened the route, block 4's kills spread toward the
Heartwood and **14 leaked**; all 15 leaves went in drifts 17–18 (reward: 4 Seeds). Banked 282–445
unspent. **Second Path is offered from drift 26, not 15** (act 2+, like Tramplers / Burrowers): an act 1
maze is a few walls deep and can't absorb losing its longest one (in 7ee4817a). Curve: no change.

## Human run 11 (2026-10-01, build 3d47ff = b84f3e75+)

**Lost at drift 30**, Sporeling → Dewdrop, 1 Grove node. Act 1 calm to 11 (≤ 0.24), leaks at 12 (5
leaves) and 18–20 (3); Stag 42 s. Act 2 26–28 at 0.23–0.35, then **Leaf Fall** (taken at the drift 25
rest with 8 leaves): 3 leaks at 29 cost all 8. Omens 4 faced, 0 Clear Skies. Front-loaded again: Dew and
kills at 0.0–0.3, Heartwood share 0%. Driftspore 50%, Puffball 28%; Quickened Sap credited +15.6k.
User on Omens with a hurt Heartwood: **keep as is** (Clear Skies is the choice; losing to an Omen is
the gamble). No change.

## Human run 12 (2026-10-01, build 238191 = 483e43ec; **a first-time player who doesn't play games**)

**Lost at drift 30**, Sporeling → Firefly Jar, 2 Grove nodes. **Planted only: 60 Sporelings + 10 Firefly
Jars, grow 0, ranks 0** (all 2,058 Dew spent on planting). Act 1 closest 0.70–0.94 to drift 10, then
0.29–0.48, **no leaks until the boss**. Dew spread evenly along the route, Heartwood share 5–13% (unlike
the user's front-loaded mazes). **The Scarecrow was dispelled (36 s), yet 6 Crows leaked: 12 leaves**,
more than the 10-leaf bite for *failing* a boss. Act 2 with 4 leaves: 3 leaks at 29, dead at 30. Omens
4 faced (Leaf Fall, Dry Spell ×2, Wilting).

Reading: a total newcomer with a pure "plant base Wardens" plan holds act 1 and reaches act 2, which is
on target for a fresh profile (and act 1's "teaches" side holds). Decisions:
1. **Crow `leaf_cost` 2 → 1**: a won boss fight must not cost more than a lost one (in 5c716b8d).
2. Never growing or ranking is an onboarding point, not a number: passed to the hub (a whisper when
   Dew sits on a growable Warden?).

**Correction:** whispers / hints were **switched off** for this run, so she got no onboarding at all.
"Never grew a Warden" is partly that; **her economy (plant-only) is not a fresh player's normal.** Since
c8d1fc33 the always-on Growth hint marks are a separate setting from whispers.

## Human run 13 (2026-10-03, build 6e7574 = 83d9b3b0, Dev Grove: Full; first run after the act 1 fixes)

**Lost at drift 10**, 3 min. Nestling first, grew **3 Magpie Perch** (the thief; ~0.1× Driftspore on its
own damage) + 10 Sprouts; Dew earned 515. Closest 0.84–0.88 at drifts 7 and 9, then **drift 10, the first
block finale: 8,619 health (drift 9: 3,747, so ×2.3), 13 leaks, all 15 leaves in one drift.** Kills and Dew
were at 0.1–0.4 of the route, nothing near the Heartwood.
- **A first finale must not end a full-leaf run:** `block_finale_health_from` **10 → 15** (in d75b7d9f after Roguelite 72a2879b; drift 10 keeps its
  one elite as a small first spike). The demo is unaffected.
- Nestling isn't expanded yet (the sky merge is Phase 3), so both branches were offered and the user picked
  the support. Not a draw issue; watch whether Magpie Perch reads as a trap first pick.

## Half-cell placement: the re-check plan (2026-10-04; half_cells.md, experiment until the user says yes)

Once it merges (Wardens at half-cell offsets, nightmares on a 32 px grid, 1-cell corridor minimum), re-check
on the merged build, at low sim load while the user may play:
1. **Route length:** the opening route, the route at drifts 24 / 45, and "+N path" units (cells vs half cells).
   Mazes are expected to be longer, which eases every drift.
2. **Act 1 baseline:** fresh Balanced / skip, 30 seeds, --boss-draw, finale leaves (targets as the Current
   targets table).
3. **Each act 1 boss forced** (Stag, Night Mare, Scarecrow), 20 seeds; the Stag's trample and the Night
   Mare's laps on longer routes.
4. **Time in range:** per-form probes for close-range and pulse Wardens (they gain most from hugging walls).
5. **Rootling pulls:** the "two pulls = one drag" test in tiles walked (half steps).
6. **Cell-measured things:** auras, Kinship reach, gift areas, Deeproot's guard ring. They stay in full cells
   by spec, so check only that they read the same.
Lever if mazes grow a lot: act 1 ramp / finale health, not Warden numbers.

**Item 1, routes + act 1** (0596eb94; the bot made half-aware in the same commit, 30 seeds per bot): half-aware
mazes are **+7% (opening) to +12% (drift 24)** longer (83 vs 74 cells at 24). Act 1 survival is **73% with
either bot**, so **half cells barely move act 1**. The jump from 53% (84bbaf44) comes from the changes in
between (finale ×1.4 from drift 15, finale elites without ×1.4, the Firefly Jar buff, Nurture): now **above
the 55–60% target**. Held until the skip arm: if skip also rises well above 15%, act 1 tightens (the ramp or
the drift 20 finale); humans (runs 15–16) still end in act 2 and found it fair.
**Item 2, skip:** **43%** (target ≤ 15%; it was 0% on 175058a0); finales 10 / 15 cost 0.03 / 0.07 leaves.
**Act 1 tightens: `act1_health_multiplier` 1.15 → 1.30** (full game only; the demo keeps 1.15 via
DEMO_RULES; in 4e8162d2). Expected: Balanced ~60%, skip ~20%; re-run both after.
**Corridor rule changed** (user, half_cells.md 04c10c33): nightmares fit through one-half gaps, so mazes can be
denser and longer. The ×1.30 checks (Balanced, skip, bosses) are held for that build; the current results
read the old one-cell corridor rule.
**Act 1 on 1768f778** (one-half gaps + ×1.30; half-aware bot with pair search; 30 seeds): Balanced **60%** ✓,
skip **10%** ✓ (both in band). Route: base 40, opening 51, drift 24 ~80 cells (human run 17: 68). The drift
20 finale is act 1's real test (1.2 leaves Balanced, 4.4 skip). **×1.30 stays.** The bosses and the demo follow.
**Act 1 bosses forced** (same build, 20 seeds each): survived **Stag 75%, Night Mare 70%, Scarecrow 60%** ✓ all
near target; the Scarecrow is the hardest (its drift costs 2.7 leaves, the drift 20 finale before it 1.8). The
Night Mare's losses are laps / drain, not leaks. No change.
**Demo** (one-half gaps, demo ×1.15, 20 seeds): Balanced **80%** ✓, skip **65%** (band 25–45%; 3 runs from 50%).
**Kept**: the demo is the gentle intro, and Balanced being in band matters more. **The half-cell re-check is
closed**. Rootling: Rootcurl 1 tile per pull, two pulls = one drag (2 tiles) ✓; Long Way Home pulls 4 tiles by design (the final's lever since 54155266; the "3" in warden_stats.md was stale), test tightened to 3.5–4.5.
**Item 3, demo** (0596eb94, old corridor rule, 20 seeds): Balanced **100%**, skip **50%** (pre-merge 70% / 40%;
band 75–85% / 25–45%), route at 24 ~86 cells. Half cells plus the Firefly / Nurture changes eased the demo
too. Held with the full game for the new corridor rule (which lengthens mazes further); then the demo's
own DEMO_RULES act 1 value gets a step if it stays above band.

## Milestone thresholds (2026-10-04; milestones give bonus Seeds only, meta_design.md 269b14b0)

Checked against the user's profile and run history: shades_dispelled 577 after a few real runs; a drift-42
run dispels ~1,200 nightmares (~700 Shades). **Shades 3,000** total (was 2,000: the third good run); **path 130
tiles** (was 300: impossible with 240–294 buildable cells; openings are 35–57, bot mazes ~80 at drift 24);
**tends 120** total (was 300: the profile's tended_total is still 0). Bonuses (+20 to +150) unchanged.
`longest_path` / `tended` requested in the run history to re-check.

## Maze feel: walls first (user via the hub, maze_feel.md 8b50fce6, 2026-10-05)

"Walls early, upgrade only where it covers everything" (Tropical Tower Wars).
1. **Walls:** Thornwall and the wall line are already exempt from `copy_cost_step` (a7525077). **User: Thornwall stays 3 Dew, up to 5 if checks call for it** (the 3 →
   2 proposal is cancelled). Wall Dew is a rounding error of a run (20 walls ≈ 60 of ~2,000 act 1 Dew), so price
   isn't what keeps players off walls; the open ground (maze_feel #5) is the real lever.
2. **Checks (probe arms):** (e) X Dew all on walls vs (b) one grow; (b-hi) vs (b-lo), the grow at the highest vs
   the lowest coverage Warden (route halves in range, per pass). Wanted: (e) > (b) in act 1, and (b-hi) clearly >
   (b-lo). If not, the levers: range counting more for grown forms (e.g. branches +0.5 range), or the first grow
   priced so it only pays at a junction.
3. **Act 1 re-check** on main HEAD (walls at 3) (default / spender / skip, per boss). If cheaper walls lift the
   default above ~70%, `act1_health_multiplier` 1.20 → 1.25 (or Thornwall up to 5) answers it.

## Nurture audit numbers (warden_stats.md b6f44fac, 2026-10-05; in 188a75ba)

| Row | Number |
|---|---|
| Swift (all) | **+15%** attack speed per rank (was 12%; Power +18% on damage stays ahead on plain strikers) |
| Maelstrom / Undercurrent Deep | +1 linked nightmare per rank (6 → 11, 8 → 13), share fixed |
| Pull per Deep rank | Rootcurl **+0.2** tiles (1 → 2.0), Long Way Home **+0.5** (4 → 6.5): ~+15–20% a rank each, no cap |
| Groundroot / Earthbind | grounded 3 s × Potency, cap **6.75 s** |
| Hushbell / Silence Deep | silence lingers **+0.4 s** per rank |
| Sunpetal / Midsummer Swift | beam ramp **+15%** per rank |
| Dreamcatcher Strong | Caught statuses tick **+10%** per rank (a conditional, so above Power's 18%/2) |
| Mother Log Strong | 0.35 + 0.03 a rank, cap **0.50** (Nurse Log stays 0.40) |
| Grove Keeper Swift | −0.2 drifts per rank |
| Wellspring Kindred | interest cap +10 per rank (80 → 130); the shared `DewCatch.INTEREST_CAP` 120 → **130** so a lone V Wellspring reaches it |
| Dream Oak Yield | run cap +1 Dreamlight per rank (4 → 9); shard bonus trimmed +0.5 → **+0.3** per rank |
| Drowsy / Exposed / Soaked | Drowsy duration × Potency; past a 40% cap, duration × (Potency ÷ Potency at the cap) |

Rule 1 (distance areas, d3cd75c3 / 03880e14): base radii ≥ 2 got +0.5 (Grove Heart, Dream Oak 2.5; Jarlink link 4.5). Radius 2.5 covers
20 cells vs the old 5×5 square's 24 (−17%); Wide rank II (2.9 ≥ √8) adds the 4 corners back. Accepted.

## Brood Cap / Hatchery Yield (Tower Discussion 68120c18, 2026-10-05)

Yield = **+1 sprite alive per rank** (cap 4 → 9 at V), nothing else; Swift = hatches faster (+12% a rank). The
cap only binds in lulls (a drift's start, gaps between groups); under steady pressure sprites burst as fast as
they hatch. So Yield is the opening burst and Swift the sustain: even per Dew. Approved per rank, no burst
cut. The old Yield hooks (−0.25 s interval, +8% burst per rank) must be gone. Seedbearer too: **+1 Sprout per rank**
(YIELD_PER 1; five ranks cost 726 Dew at tier 2 for +5 Sprouts of ~12–16 Dew each, not too strong; an odd-rank
"seed sooner" would duplicate Swift).

## Twig Walls (card 256, Rare; dream_design.md c6fefe1b)

Geometry: a serpentine's pitch is corridor + wall. One-half corridors with Thornwalls (2 halves thick) =
pitch 3 halves; with twig walls (1 half) = pitch 2. **The same walled area gives ~×1.5 the route**: the user's
73-cell mazes become ~100–110. Wall Dew per length stays about equal (Thornwall 3 per 2 halves, twig 2 per
half), and wall Dew was never the limit, so price changes little. ×1.5 exposure ≈ +40–50% damage for every
Warden: about the Rare all-Wardens budget (+40%), before stacking with route cards.
**Verdict:** keep half price, **min_act 2** (act 1's curve was tuned on full walls), no cap yet. Measure
human `longest_path` with the card; **above ~120 cells, cap it** (e.g. twig walls up to 30). A static route
probe (the bot's wall planner, same walled area, Thornwalls vs twigs, 20 maps) goes in the queue after the
plant/grow probe.
**Route probe (c2f1fd3c, 20 maps, same walled area; base route ~40):** route added Thornwall / twig: 10 walls'
area +28.9 / +40.0 (twig longer on 20 of 20 maps), 20: +42.7 / +55.0 (18 of 20), 30: +51.4 / +59.2 (16 of 20).
Useful twig bars run out past ~60. **Whole route only +10–15% longer** (not my ×1.5: real maps aren't open
serpentines). Under the Rare budget; **no cap**, min_act 2 stays. The bot takes it 8 of 9 times offered: watch
its pick rate and human `longest_path`, and raise its effect only if humans pass it by.

## Rank-choice cards 266–269 (dream_design.md cdfbe349)

| Card | Number | Why |
|---|---|---|
| Specialist (U) | a Warden whose every rank is the same choice gets that choice's bonus **×2** (not ×1.5) | Power V: +90% → +180% choice damage, ≈ +47% on that Warden (base ranks included): the Uncommon conditional budget (+45%); ×1.5 gave +24% |
| Many Talents (U) | **+10%** damage per different choice among its ranks, up to **+40%** (4 choices) | sits just under Specialist, so mixing and specialising are both live |
| Shared Training (R) | as designed (a kin pair with the same majority gets the rank V signature at IV) | worth one rank (~135 × tier Dew) per pair plus the signature early; a build-shaper, not a number |
| Brimming (R) | every status cap ×2, as designed | Spore boards up to ≈ +40% once stacks reach 16 (status share ~40%); Charge boards lose about half their bolts; Drowsy's slow already meets its floor, so ×2 only slows catching. A real trade, under the Rare one-family ×1.8 |

## Rank V signatures (warden_stats.md 96d728dd)

Crushing: every 5th hit ×2 + strips 25% of dread shell. Relentless: a dispel resets the cooldown (≤ once per
0.5 s). Watchtower: reveals hidden nightmares within its own range (≈ 726 Dew of tier-2 ranks for one stretch:
the Lurker counter isn't trivialised). Spreading: half the stacks (min 1) jump within 2 cells on dispel.
**Executioner: a crit under 20%** (not 30) dispels; bosses / elites take ×1.5 (at Moonstone / Hoard crit rates
30% erased the last third of every normal nightmare, ≈ +40%). Firstborn, Shelter as designed. Surge: aura ×2
for 2 s every 10 s (≈ +20%, in line with Crushing). In e951b540 (Crushing counts every hit, so an area Warden doubles every
5th target: the same +20% on average, shell strips a bit more often; fine).

**Signature audit (warden_stats.md a09297af):** Crushing on ticks: the 5th tick ×2, shell strip 25% × (tick ÷
full hit), capped at 25%. Acorn Strong 0.01 → **0.025** aura per rank (≈ Power per rank). Held Potency cap 2.25,
Watchtower 2 s linger, Relentless on tick dispels (still ≤ once per 0.5 s): watch Sporeling boards.

**Maze cards made conditional (dream_design.md 7fc0665c):** Winding Path **+1 Dew per 2 reached path tiles**
(each once; ≈ +10% of a run's Dew; per 5 fell to ~3%). Hedge Maze **+5% per touching Thornwall, up to +30%**
(twig half; typical +10–20%).

## Shape cards 262–264 (dream_design.md e4d17195, Uncommon, defining)

Budget: Uncommon one-family **+50%** for the kits that match, ~0 for the rest (by design).
| Card | Number | Why |
|---|---|---|
| Small Hands | sent-out things **+35%** damage and **+1 s** | the +1 s adds hits for birds, seeds and lobbed stones, so the total sits ≈ +50% |
| Sap Rising | each non-attacking Warden (not Thornwalls) pulses the 8 cells around it every 2 s for **2 s × its aura bonus × the summed DPS of the attacking Wardens in its aura**, at least **2 s × 50% of the board's median attacker DPS**. Effect damage (Potency applies) | it deals again, as an area, the damage it already grants: scales with ranks (Strong) and the board; the floor gives catchers and lone support Wardens a real hit |
| Lingering Ground | ground effects last **×1.5**, not ×2 | overlapping clouds / rings on the same tiles turn duration into damage almost 1:1, so ×2 ≈ +100% for cloud kits |

After the build: an all-Acorn check (fresh, Acorn family forced, the card forced at the first rest, 30 seeds) to
see whether it makes the user's all-Acorn run viable. Hooks in Tower Code 712d37d3 (the +1 s only where a timer exists: sprites
8 → 9 s, hummingbird pecks; seeds and patrols get the damage only).

## Heartwood gifts: every gift gives something (heartwood_gifts.md b3e464e6, 2026-10-06)

Sized beside the living-ground gifts (Moonwell +1 range within 1 cell, Spring +20%, Heartwood Roots +15%):
| Gift | Number | Why |
|---|---|---|
| Sow a Ridge | Wardens touching it **+10%**; **+2 Seeds** per tended gift tree | the ridge is already a free wall; 3–5 trees touch more cells than a Moonwell |
| Fallen Giant | touching **+0.5 range**; nightmares beside it **15% slower** | as proposed (an uncleared free wall, Mire is 20% on 3 cells) |
| Shift the Stones | **+20 Dew × act** per stone moved (act 2 ≈ 120 for 3); the old spot fertile (half price) | 15 × act was under a drift's pot |
| Shifting Mist | this act's Dew pots **+10%** (≈ 300 Dew in act 2) | +15% ≈ 470 Dew, four times Shift the Stones; the re-facing maze is its cost |

In: Tower Code cdedfec0 (Warden buffs), Main Merger 285dbd6b (Dew, fertile, Mist), Environment Code 8833efaf (log slow,
ridge Seeds; fixed to 2 in total in 8ec114cb).
**Overlap fixes (user, heartwood_gifts.md 8f46c6ac):** Fallen Giant = **+15% crit chance** touching the log only (range
and slow dropped; 10% at ×2 crits sat under the Ridge's +10% damage). Shift the Stones = Dew only, **30 × act** per
stone (fertile dropped: 3 half-price plants were worth ~40–75 Dew). Bramble Verge = free Thornwall → Bramble
growth for the run + Drowsy cap +1 (≈ 10 Dew a wall, ~200–300 by act 2; as designed). In: Main Merger d8f18e55, Tower Code
5f61e09a, Environment Code 23c2f39b.

## Fewer, bigger cards: numbers (dream_design.md de439ea8, 2026-10-06)

**Principle:** one pick ≈ **two** old stacked picks, never three. A rest still gives one card, so sizing every
one-copy card at its old 3-stack maximum would be an across-the-board raise (the user's constraint). All-Warden
cards move up a rarity where the number passes their budget.

| Card | Number | Rarity |
|---|---|---|
| Deeper Calm / Quickened Sap | **+25%**; II **+25%** more | **Uncommon** (was Common; Uncommon all-Wardens budget) |
| Longer Roots | **+1 cell**; II **+0.5** more | **Uncommon** |
| Glinting Dew | **every 5th** attack crits (+20% at ×2) | **Uncommon** |
| Flurry | every 5th attack fires twice | stays **Uncommon** (not Common: the same +20% as Glinting Dew) |
| Bitter Sap | +1 stack on apply | Common (conditional, status builds) |
| Live Wire | bolts jump to a 2nd nightmare | Common |
| Lasting Dreams | statuses ×2 duration | Common |
| Quick Step | +50% attack speed until the called drift has arrived | Common |
| Damp Rot / Sparking Spores | **+100%** (2 old copies) | Common |
| Rain on Glass | **+70%** | Common |
| Heavy Dew | twice as wide, Damp +4 s | Common |
| Heartwood's Reach | clearing half + 3 half-price clears | as is |
| Hush | **+50%** pulse reach | Common |
| Longer Flight | **+2 cells** | Common |
| Sharp Beaks | +2 hits | Common |
| Dew Bowl | **+50 Dew** now | Common |
| Sudden Insight | +2 Dreamlight now | Uncommon |
| Bright Marks | Marked take **+30%** (not 40: Marked boards already hit 55% combo share, friend run 1) | Common |

**New Commons:** Thorny Walls: each Thornwall lashes one nightmare beside it **every 2 s for 5 damage** (half a
Sprout's hit; 20 walls ≈ +10% of a late act 1 board; Dream damage cards apply; a full Sprout every 1 s would be
10 DPS per 3 Dew wall, more than a Sporeling per Dew). Passing Dream: statuses jump with their remaining time and
stacks to the nearest nightmare within **2 cells**. Lantern Glow: **+15%** (in reach covers nearly every hit:
the Common all-Wardens budget exactly). First Frost: the **first 5** nightmares of each drift are Held **1.5 s**
at the first Warden they meet (one nightmare for 2 s can't be felt), bosses exempt. Dew Line: every 10th dispel
pays twice (≈ +10% Dew, beside Wild Dew's ×1.1).

**Bittersweet (spike ≈ 2× a Rare, the price felt every drift):** Thin Bark +75%, max leaves halved → **Rare**
(with 7–8 leaves any act 2+ boss leak ends the run: that is the price). Venom Bloom Potency ×2, hits −40% (+30%
on a half-status board, −8% on a 20% one: build-dependent, as meant). Blood Is Thicker kin ×2 / non-kin ×0.5 →
**Rare** (×2 is above the Uncommon budget). Chosen Few V+ ×2 / below III ×0.5. Deep Sleep **+80%**, no rest bonus
and no Omens. Burn Back: all Withered Trees free now (no Seeds), **+20%** speed for the run. Waking Dreams: 3
Legendaries, then no skipping and 2-card offers. All as proposed except the two rarity moves.

**Defining rule (act 2+, one defining card per offer):** no numbers, but it moves picks. The bot's card picker
must take it as offered; after the build, Balancing Code re-checks act 1–2 (default / spender / skip) and the
pick rate of defining cards.

**Re-check (40bdebda = main + bend10 + walling bot + the card pass; 30 seeds, half 20):** act 1 default **36%**,
spender 50%, skip 16%, half default 30% (no-card reference on the same maps: 53 / 40 / 20). Act 2: 0–3%
(fresh dies in act 2, on target; too few act 2 offers to read the defining rule). Combo share act 1 / 2: 0.16 /
0.33. The bot took Thorny Walls 22 of 28 and First Frost 1 of 34, which reads as its policy's scores. Default's −17
is on the edge of noise: 30 more seeds on both builds, and a check of how the policy scores Thorny Walls.
**Cause found:** the bot's card policy scores tags only (×10 + rarity), never effect size: Thorny Walls 10, Glinting
Dew 11, Deeper Calm and Quickened Sap 1, First Frost 0. Every tagged card beats every plain stat card, which has
held the balanced bot's stat picks down all along. Next: a Thorny Walls override arm, then effect-size scoring
(`--card-value`, damage-equivalent % × k) as a flag, A/B, and the default if it picks sensibly.
**Firmed up (60 seeds each):** act 1 default **40%** with the cards vs **46%** without (−6 ± 9: not significant; the
first −17 was seed luck). The bend10 default reference reads ~46%, a little under the ~55 target; the card-value
A/B decides whether that is the bot's picks.
**Thorny Walls override (paired, seeds 1–30):** scored like a plain Common, the bot takes it 1/13 (was 11/13) and
act 1 goes 36% → **53%**: most of the card pass's act 1 effect was the bot's picks. It also shows Thorny Walls
under budget (taking it costs a pick): **every 1 s, 5 damage** (was every 2 s; ≈ +20% at 20 walls, fading late). In 62dc0c0f.
**`--card-value` A/B (paired, seeds 1–30):** act 1 default 36% (tags only) → 53% (Thorny override) → **63%**
(effect-size scoring); picks look sensible (Tender Care, Old Growth, First Light, big stat cards first; conditional
cards by board share). **Made the bot's default; every baseline from the flip on is card-value.** Spender / skip
re-based on it next. **Card-value baseline (40bdebda, 30 seeds):** default **63%**, spender **56%**, skip **13%**,
0 dead by d5. All inside the targets (default ~55 ± noise, spender ≤ 80, skip ≤ 15–20); Dreams vs none now a
50-point gap (was ~33). No curve change. (On 3-family picks; from meta_design e0c02e54 fresh picks show 2,
Wider Choice 3: note it on later fresh baselines.)
**More obstacles (04c42701, 38–48):** default 63%, spender 66%, skip **23%** (+2 route cells, ~1 free wall by d5).
Skip is 3 over its line, inside noise, and the 2-family picks (harder) are coming: **kept**. If the next fresh
baseline with 2-family picks still has skip > 25%, `act1_health_multiplier` 1.20 → 1.25.

## Drawn route and early deaths (19f426c5, 2026-10-05)

After "fewest turns among the shortest", 5–7 of 30 bot runs per arm die by drift 2 (was ~1 in 90). Same-board
replays (seeds 7 / 8 / 9): the game holds the old boards, but **a new placement can flip the drawn route to
another lane**, stranding earlier Wardens (seed 8's first Sprout ends at 0 coverage; seed 9 leaks 9 Shades after
one d7 placement). Partly a bot weakness (it doesn't price the cover it takes from its other Wardens), but for a
player too. Asked Environment Code for stronger stickiness: shortest → closest to the current route → fewest
turns. Until then read main's act 1 "past d5" column.

## Sprout-into follows the copy price (user found it, 2026-10-05)

Sprout (~12) + sprout-into (15) was a flat 27, under the Nth planted copy (33 at 5, 43 at 10): a bypass of
`copy_cost_step`. **Sprout-into = max(base, live planting price − the Sprout's paid price)**; gift Sprouts pay
the full price; the grown Warden counts as a copy. The two routes cost the same; the Sprout only delays the
choice. First copy unchanged (15), so the opening holds. In 526df9d7 (Tower.plant_dew; group grows price each Sprout in order).

## Room to maze (maze_feel #5, worktree room-to-maze, 2026-10-05)

Environment Code's open bowl: obstacles ~60 → 30–41, buildable ~275 → ~298 cells, but the **opening route ~46 →
~25** (20–36); the bot's fresh seed 3 died at drift 2. **Verdict: open bowl yes, opening route kept at ~38–46**
(the band's minimum ~38, made with ridges and the guaranteed bend): drifts 1–10 and the 60 Dew opening are
tuned on it, and the user's goal is room to build longer, not a shorter start. **Revised:** Environment Discussion
wants the short opening on purpose ("the player builds the length"), so it is simmed as is, with a wall-first bot
opening (Thornwall 3: ~7 walls take 25 → ~45 and leave 3 Sprouts). Go if drifts 1–5 leak no more than main and
act 1 survival is within ±10 points; else the bend spur adds +8–10 cells.
**Sim (main 526df9d7 vs room c0ad2808, wall-first bot, 30 seeds per arm):** d1–5 leaks default 1.8 → 3.5, skip
2.4 → 3.1, spender even; act 1 boss default 50 → 30%, spender 56 → 36%, skip 16 → 6%; route d1 / d10 66 / 73 vs
44 / 49. Bosses no harder; room runs reach 25 less often. **No-go; the spur fallback (+8–10) asked for**, then the
room arm re-simmed. (The bot stops walling at ~45 cells; a new player walls less, not more.) Act 1 bot check on the worktree
before merge; if the extra room makes act 1 easy, the curve answers it.
**Final (sticky lanes 1c46063d, walls-keep-going bot, 30 seeds):** act 1 boss, main / room / bend10 (opening
26–41, +10 bend): default 76 / 46 / 53%, spender 70 / 50 / 40%, skip 16 / 26 / 20%; d1–5 leaks 0.6–0.7 / 1.0–1.1 /
0.2–0.8. Both branches miss "±10 of main", but main itself now sits above target with the walling bot. Judged on the
targets, **bend10 is on them** (default ~55, skip ≤ 20) with the cleanest opening; the spender's 40% is the attacker
spam "walls first" means to weaken (fewer free obstacle walls: the player builds the maze). **GO for bend10; room
stays out.** Watch the first human runs on it; if act 1 is too hard, `act1_health_multiplier` 1.20 → 1.10.
**Bot baseline change:** from a99d5382 the bot keeps walling by default; every batch before it is the non-walling
bot. Warm-up and pgr wait for bend10 on main.

## Human run 21 (2026-10-05 20:57, build 91161b = b3c61186; 0 Grove)

Sporeling, Bellflower picked at 25 but **none planted** (board: 10 Sporeling, 6 Inkcap, Hatchery, 6 Sprouts).
Lost at **drift 33**. Act 1: 4 leaves (drift 20 finale), the Stag beaten at 25 with 11–12, closest 0.5–0.99:
firm. Act 2: clean to 29; **30 (finale, under Leaf Fall) −4**; 32 dealt only 60% of its health (Puffcaps
resist spore, Dandelion flyers skip the maze); 33 took the last 8 in 9 s under a **second Leaf Fall** (taken at
the 30 rest with 8 leaves). Status ticks 41%, combos 13%. **Read: no tuning.** The death is the design working:
a one-family spore board meets spore resistance and flyers, with leaks doubled by an Omen the player chose.
It lands in the 32–42 act 2 band again. Watch: the Bellflower pick unused (did the panel make the second family
clear?), and two Leaf Falls in one run (fine, it's offered, not forced).

## Friend run 1 (2026-10-05 20:22, a new player, fresh profile, live main)

Firefly Jar, then Dewdrop at 25; lost at **drift 40** (25 min). **Act 1: 1 leaf lost** (a leak at 5), the Stag
beaten at 25 with 14–15 leaves, closest mostly 0.3–0.7: firm, not a wall. **Act 2: clean to 31**, first
leaks at 32–35 (−9 leaves), then **38–40 took the last 6**: the same late-act-2 wall as human runs 15–18
(deaths at 35–42). Board at the end: 33 attackers (13 Firefly Jar, 6 Lanternmoth, Beacon, Prism Jar, 3
Cloudlet) + 10 Thornwalls + 8 Sprouts, route 60. Dew 3,988: plant 822 / **grow 2,266** / ranks 885. **Combos
55% of damage** (Marked from Lanternmoth / Beacon; target 25–40%). Omens taken: Swift Stream, Frozen
Ground, Thick Blight.
**Read:** right on the fresh-profile target (dies in act 2–3) for a first-time player. Watch: (1) the
38–40 wall: every human death in act 2 lands at 32–42, so it's the act's real test rather than a single
spike (drift 38 is 168k health, after a light 37 at 63k); act 2 may need one earlier pressure point to spread
it. (2) The combo share on Marked builds: one run above 40%, earlier runs 16–21%.

## Human run 20 (2026-10-05 19:06, live main: grow setting + drift 10 eased; 0 Grove)

Sporeling (13 + Lichenling + 2 Brood Cap), longest path 56. **Drifts 1–24: 0 leaks, 15/15 leaves**, closest
≤ 0.87 (drift 10 now 0.37). **Drift 25, the Scarecrow: 14 leaks, all 15 leaves**; the board dealt 14.7k of
18.8k health. Dew 2,150: plant 597 / grow 435 / ranks 1,062. Combos 16%. The Scarecrow is weak to spore, so
this was a favourable draw: a clean run wiped by the boss alone is a cliff. Suspect: its 16 Crows (speed 190,
4 at each of 80 / 60 / 40 / 20%) leaking on a short route, plus the 10-leaf bite. Per-boss survival from the
bot data asked of Balancing Code before choosing a fix.
**Per boss (bot, live tuning, survivors of 25):** Stag 83 / 86%, Night Mare 92 / 57%, Scarecrow 71 / 84%
(default / spender). The Scarecrow itself never reached the Heartwood; its drift leaks **~4 per surviving run vs
~0.4 for the Stag**: the Crows. The bot hides the cliff because it covers the Heartwood end. **Fix: Scarecrow
`grief_count` 4 → 2 and `split_count` 4 → 2** (10 Crows in all, was 20 with the 4 on its fall): at 1 leaf each, 20 could end a clean run alone; 10 leaves a clean run
alive. In 5155f17e. Watch: Night Mare for the spender (57%, small n).

## Human run 19 (2026-10-05, build c473ca = 4aae45a5, the new grow setting; 0 Grove): "a bit too hard early on"

Sporeling (Brood Cap ×3), lost at drift 20. Drifts 1–9 calm (closest ≤ 0.33, 0 leaks). **Drift 10: 10 leaks,
12 of 15 leaves in one drift**; then clean to 18, a leak at 19, and the drift 20 finale took the last 3. Dew:
plant 437 / grow 375 / rank 456 of 1,400. Drift 10 stacks the Husk-heavy group (10 Shades + 6 Husks), the
first finale elite and the first +25% count (`extra_nightmares_from` 10); it has been the early cliff before
(Oct 3: 15 leaves there). **Fix: `extra_nightmares_from` 10 → 11** (full game; the demo keeps 10), so the +25%
lands a drift after the finale. In 6c54445a. **Bot check (1d5f53ba, 30 seeds):** drifts 10–11 now gentle
for every arm (≤ 0.4 leaves lost, 83–93% clean); act 1 boss default **50%**, spender **70%**, skip **27%**
(was 70 / 67 / 10). The default's drop goes the wrong way for an easier drift 10, so it reads as noise.
Skip sits just over its ≤ 20% line: **kept**, because the user found early too hard and the Dreams still
separate clearly (27 vs 50–70). Skip re-run on seeds 31–60 queued; above ~25% over 60 seeds, revisit.

## Plant vs grow vs rank: value per Dew (user via the hub, 2026-10-05: "placing more towers and growing them equal the same math with the new interest")

Goal: planting the Nth copy, growing (base → branch 120, branch → final 450) and Nurture ranks (30 / 48 / 60 /
90 / 135 × tier 1 / 2 / 3) give about the same value per Dew (±15%) over act 1–2's usual counts. Walls exempt.

**Paper numbers (data, hit DPS = damage × attacks/s; no statuses, area, Reactions or reach):**

| | Sporeling | Firefly Jar | Dewdrop | Bellflower |
|---|---|---|---|---|
| Base DPS | 14 | 21 | 18 | 17 (pulse) |
| Copy N price (step 0.08) | 25 → 33 (N 5) → 43 (N 10) → 53 (N 15) | same | same | same |
| Copy DPS / Dew, N 1 / 5 / 10 / 15 | 0.56 / 0.42 / 0.33 / 0.26 | 0.84 / 0.64 / 0.49 / 0.40 | 0.72 / 0.55 / 0.42 / 0.34 | 0.68 / 0.52 / 0.40 / 0.32 |
| Branch mean DPS (range) | 20 (12–39) | 51 (10–113) | 30 (6–72) | 38 (13–70) |
| Grow → branch, DPS / Dew | 0.05 | 0.25 | 0.10 | 0.18 |
| Final mean DPS (range) | 41 (27–60) | 94 (10–240) | 31 (8–60) | 85 (24–165) |
| Branch → final, DPS / Dew | 0.05 | 0.10 | 0.00 | 0.10 |
| Rank I on base / branch / final (≈ +14% DPS) | 0.07 / 0.05 / 0.06 | 0.10 / 0.12 / 0.15 | 0.09 / 0.07 / 0.05 | 0.08 / 0.09 / 0.13 |

On paper the 15th copy still beats any grow by 2–5×, yet in the sims they come out even: at copy step 0.08 the
**default bot (13 Wardens, ~5 branches) survives the act 1 boss 63–70%, the spender (~18 Wardens, no grows)
67–70%**. Hit DPS misses what growing buys (statuses, area, Reactions, a branch's ability, no new cell needed)
and what each extra copy loses (worse spots, a status that's already on the target). **Paper DPS can't set
these numbers; a measured value per Dew can.**

**Measured probe (asked of Balancing Code):** from a bot board saved at drifts 10, 20 and 35 (`--save-at`), give
+X Dew and spend it only one way: (a) planted copies, (b) one grow to a branch (X = 120), (c) branch → final
(X = 450), (d) ranks; each family via `--families`, 30 seeds. Value = the next block's leaves saved and health
dispelled versus no extra Dew, per Dew. Plus the bot's mean +path per placement (the maze side of planting).
Then the crossover ("from the Nth copy, growing is better") and a proposal; **nothing changes until the user
approves.**

## Lichen shell strip (2026-10-05, flagged by Tower Code)

`shell_strip` was 1% of a dread shell per Spored tick (one tick a second, whatever the stacks): ~100 s
per shell. **Lichenling 0.10, Old Lichen 0.15** (crack at 8 unchanged): one Lichenling clears a shell in
~10 s of Spored, two in ~5 s; Old Lichen ~7 s. Sent to Tower Code.

## Acts 3–4 coverage (user via the hub, 2026-10-05: the bots never get there)

Balancing Discussion decides, Balancing Code builds the tools. At most 2 sims in parallel while the user may play.

**1. Synthetic late start (now).** `--start-at=51` / `76`: the run skips straight to that rest with what a
typical run holds there, the bot builds its whole board in that one rest, then plays on to 75 / 100.
- **Dew:** `starting_dew` + Σ Dew pot of the skipped drifts × **0.9** (leaks lose shares) + Σ base rest
  bonus (no perfect blocks), read from the live exports, so tuning changes follow automatically.
- **Leaves:** **10 / 15 at 51, 8 at 76** (to calibrate against snapshots).
- **Families:** the first pick + the boss picks (25, 50, 75) via the bot's normal pick logic.
- **Dreams:** one offer per skipped rest from `DreamState.make_offer`, chosen by the bot's normal logic
  (boss rests Rare+); Omens: Clear Skies.
- **Dreamlight:** the act's mean earned by that drift from the run history (human runs). The bot spends it
  on branch / final unlocks as usual.
- **Grove:** fresh / half / full presets; --boss-draw.
- **Arms:** per preset × {default, spender} × {51, 76}, 30 seeds. Then the finals question: the same at 76
  with final forms **+12.5% damage** (an export, asked of Tower Code).
- **Targets (bot, first read):** from 51, half Grove default survives the act 3 boss **~45–60%**; from 76,
  half Grove wins **~30–50%** (the skilled-player target), fresh **~10–20%**, full ≤ ~65%. The bot does
  not use finals, Ascended, Reactions or Kinships well yet, so it reads **low**; misses are judged with that
  in mind and with human runs.
- Measured: survival per boss, death drifts, leaves lost per drift and per finale, Dew banked, tier mix
  (finals share of the board and of damage), closest.

**2. Start from a save.** `--from-save=<run.json>`: the bot continues a real board saved by `RunSaver`. A
snapshot library in `D:\Projects\logs\balancing\snapshots\` from the user's and the testers' runs (release
builds save under `%APPDATA%\TopBunk Studios\Heartwood TD`). **Copies only with the user's yes; never
written back.**

**3. Calibration.** As snapshots arrive, compare a snapshot's continuation with a synthetic start at the
same drift and Grove; adjust the 0.9 capture, the leaves and the Dreamlight until survival and leaves
lost agree within noise.

Later, not now: teaching the bot finals, Ascended, Reactions and Kinships.

**Built:** `--start-at` 2685a9cd (Dreamlight 9 at 51 / 20 at 76 from human runs), `--from-save` / `--save-at`
f66dae95, `%DreamState.final_damage_multiplier` 3707c71c (tier 3 only). **User said yes to copying their saves**
(2026-10-05). Main Merger asked for per-rest save copies (dev opt-in) to grow the library.
**First arms (half Grove, 30 seeds each):** from 51, 0/30 reach 76 on either bot; from 76, 1/30 wins (spender).
**70–80% die in the first drift:** the bot turns ~5,700 / ~9,700 Dew into 16–26 attackers, where the user had
42–88 at these drifts. These arms measure the bot's board-building, not acts 3–4. Next: a late-start build
rule (plant to the human attacker count, then grow, then rank, near the human 52 / 29 / 13 split), then rerun.
**With the build rule (7fdf5a3e):** the right board size (34 / 46 attackers), and a board that holds is as strong as
the user's at 51 (damage ≈ health spawned, 0–1 leaks), but **40–80% still die inside the first drift**: a board
built in one rest from an act 1 maze isn't laid out like one grown over 50 drifts. **Next: an invulnerable
warm-up**: drifts 1–50 (or 1–75) played for real with the Heartwood invulnerable, then leaves set to 10 / 8 and
acts 3–4 played for real. Real snapshots (`--from-save`) once the user has deep saves.

## Overlap-audit reworks, power check (2026-10-05, dream_design.md e1e39b56; dream_audit.md budgets)

| Card | As reworked | Budget | Verdict |
|---|---|---|---|
| Nightshade (L) | effects ×2 vs 4+ statuses | ×2-class | **keep**. At 4 statuses it beats the old +80%, at 3 it gives nothing: a build card, as meant. It multiplies with Potency and Seeping (not added) |
| Deep Sleep (Rare, Bittersweet) | +40% all; no rest bonus for the run | Rare all +40% × 1.5 = **+60%** | **raise to +60%**. +40% is the plain Rare budget, and the cost (≈15–20% of a run's Dew from act 2) is heavier than −4 leaves |
| Sheltering Boughs (U) | +20% touching an aura Warden | Uncommon conditional +45% | **raise to +35%**. It needs an aura family; it stays under budget because those auras already help neighbours |
| Last Stand (Rare) | +35% within 4 cells of the Heartwood | Rare conditional +70% | **raise to +60%**. Only the route's last stretch counts; Forest's Edge (Common, start) is +20% |
| Patient Aim (U) | +10% crit chance per idle second, max +40% | Uncommon conditional +45% | **+15% per second, max +45%**. At a ×2 crit, +10% chance is +10% damage a second, below the old +15% |

All five in a4be7e06 (Deep Sleep: Dream cards that add to the rest bonus still pay; fine, the base bonus is the cost).

## Restless Omens numbers (2026-10-05, for run_design.md a106b83d; data values, before the act scale)

Calibrated on the live data (Swift Stream ×1.25 speed → 5 Seeds; Heavy Rain +50% health → 45 Dew; Crowded
Paths ×1.45 → 60 Dew; Moth Night → Rare+ and 25 Dew). A double-edged Omen's twist moves **total** health up
by ~20%, so it is never free for the build it favours.

| Omen | Twist | Reward |
|---|---|---|
| Swarming Night | count ×2 (round up), health **×0.6** each (total ×1.2) | **5 Seeds** |
| Giants' Walk | count ×0.5 (min 1), health **×2.4** each (total ×1.2; elites ×3 on top), each leak **+1 leaf**; act 2+, never a boss block | Rare+ card **+ 25 Dew** |
| Brittle Night | health **×0.75**, leaks ×2; never a boss block | **45 Dew** |
| Static Sky | always Charged, speed **×1.3** | **40 Dew** |

- Swarming Night's halves leak at full leaf cost each, which is its real teeth for single-target builds.
- Brittle Night is the one Omen that lowers health: a safe maze takes it for Dew, which is its point; the
  double leak keeps it a gamble. Static Sky is offered only with a Charged source, so its taker usually
  profits from the Charged: the speed is above Swift Stream's to pay for that.
- Watch on human runs (RunHistory Omens + leaks per block): any of the four taken > 60% of the times
  offered, or leaking < Clear Skies blocks, gets its reward cut first. In 116d52bc.

**Strange Dreams averages (116d52bc):** Moonflip (+25% / −15% per block, seeded coin) averages **+5%** per
block; Wild Dew (pot ×0.6–1.6 per drift, uniform) averages **×1.1**, beside Rich Dew's +5–15%; Double or
Nothing (Omen rewards ×2 on a clean block, 0 with any leaf lost) breaks even at a **50% clean rate** on Omen
blocks. All three are mildly positive or neutral on average: fine as gambles. Watch Double or Nothing's clean
rate on Omen blocks in the run history; above ~70% it is a straight upgrade.

## Pricier growing (user, 2026-10-04: "make growing your Wardens more expensive, make the player rely on making more Wardens early instead of saving")

Intent: in acts 1–2 the best use of Dew is **more Wardens** (a longer maze, more coverage); growing becomes a
mid/late sink, not something saved up for by drift 6 (human run 18 banked 1,340 by drift 20). Starting values,
as exports for A/B (Tower Code): **branch ×1.5 (120 → 180), final ×1.5 (300 → 450), Ascended ×1.0 (600)**,
Nurture **30 / 48 / 60 / 90 / 135** (+20% on the first two). The demo gets them too. In f9fd8526 (DreamState exports); **wall-line forms (Honeysuckle…) exempt** (more maze early is the point). Measured: Wardens owned at
10 / 25, Dew banked per rest, the first-grow drift, act 1 survival (base Wardens now carry more of act 1).
**Constraint (user):** no across-the-board damage raise to match (that brings saving back); if the late game
gets too hard, compensate on **final forms only (~+10–15% damage)**. Act 1 has no finals, so an act 1 drop is
answered on the curve (act 1 health), not on Warden damage.
**First arms** (4497566a, 30 seeds): old costs 60%, new costs **37%** for the default bot. It plants the same
Wardens (its room target is drift-based) and **never reaches a branch in act 1** (banks ~40–50 vs a 180 branch).
The spender arm (plants when it can't afford a growth) is the real test; it's running.
**Spender results:** new costs **100%**, old costs **100%** (zero leaks, ~80 attackers + ~50 walls by drift 25).
Skip on new costs 0%; the demo, default bot 80% → 25%. **Mass-planting base Wardens already dominated act 1 at
any grow price**; the default bot only looked balanced because its room target capped it at 13 attackers.
**User decision: copies cost more**: each planted Warden costs **+5% per copy of the same kind** on the map
(family base Wardens; walls and Sprouts exempt: Sprouts already escalate +4 per 5 and the opening needs 5 at 12; `TowerPlacer.copy_cost_step`; in a7525077). A/B queued: the default bot, the spender, skip, and the
spender without the step, on the new grow prices.

**Overnight batch (2026-10-04/05, a7525077, fresh, --boss-draw, act 1 boss survival, 30 seeds unless noted).**
Targets: default ~55%, spender ≤ ~80%, skip ≤ 15–20%; demo 75–85%.

| Branch × | Copy step | Act 1 health | Default | Spender | Notes |
|---|---|---|---|---|---|
| 1.5 | 0 | 1.30 | – | 100% | spender ~71 base Wardens + ~50 walls by 24 |
| 1.5 | 0.05 | 1.30 (live) | 27% | 73% | skip 0%; demo default 40% / spender 100% |
| 1.5 | 0.05 | 1.20 / 1.15 / 1.10 | 50 / 30 / 57% | 93 / 93 / 90% | the curve moves both bots together |
| 1.5 | 0.08 / 0.10 | 1.20 | 30 / 30% | 67 / 57% | the step stops the spender, costs the default too |
| 1.5 | 0.10 | 1.15 | 32% (60) | 47% (60) | confirmed on seeds 31–60 |
| 1.25 | 0.05 / 0.08 | 1.30 / 1.20 | 23 / 33% | 77 / 73% | 1.25 still out of reach in act 1 |
| 1.25 | 0.05 | 1.20 | 40% | 90% | |
| **1.0** | **0.08** | **1.20** | **63% (60)** | **70% (60)** | **skip 10%; demo (×1.15) 90% / 85%** |

- **Why the default bot fell:** at the old prices it grew ~5 branches by 24 (first at a median drift 14) and
  spent 654 Dew on growth; at branch ×1.5 it never reaches one, so the Dew goes to Nurture ranks instead
  (1,106 → 1,662 Dew) and ranks are worth less. Cheaper ranks would not help; branch reachability does.
- **Levers separate cleanly:** the copy step sets the spender (0.05 → 24, 0.08 → 18, 0.10 → 15.5 base Wardens
  at 24); the branch price sets the default bot (1.25 → 33%, 1.0 → 63% at the same step and curve).
- At the winning row the default bot banks ~64 Dew by drift 15 for its first branch (human run 18: 1,340 by 20).
- **Late game (C, half Grove, --last=100, 20 + 20):** the bot never reaches act 3 on either price, so it can't
  judge finals. **No final-form +10–15% for now**; decided from human runs into acts 3–4.
  (Half Grove carries sidegrade perks, ~fresh survival as designed.)
- Seed 26 (shortest empty route, 35 vs mean 40) leaks at drift 1 with the opening in every arm; one map in 30,
  a bot opening limit, left alone.

**Recommendation (to the user, 2026-10-05):** branch ×1.0 (the old price), copy step **0.08**, act 1 health
**×1.20** (demo keeps ×1.15); finals ×1.5 and Nurture 30 / 48 / … stay. Copies, not branch prices, now hold
back early mass-planting. This walks back the branch half of "growing more expensive", so it waits for the
user's yes. **Decided (user, 2026-10-05: "Yes")**, sent to Tower Code (`branch_cost_multiplier` 1.0,
`copy_cost_step` 0.08, `act1_health_multiplier` 1.20 full game only). **In 5bef4ddd**; live check (no --set,
30 seeds): default **70%**, spender **67%**, first branch at a median drift 14, matching Bx4. Watch: humans found act 1 at ×1.30 calm
(runs 17–18, old growth); re-read act 1 closest on the first human runs at this build.

## Human run 18 (2026-10-04, build 5d8f3f = 7762f0cd; 0 Grove)

**Lost at drift 35**, 9 min; user: *"feels fine so far."* Bellflower → Sporeling; **2 Thrums = 66% of damage**
(Thrum at 70 is a real carry now); 3 Dreamshrooms; combos 22%. **Longest path 47 cells** (a short maze);
**Dew banked up to 1,340 at drift 20** (saved for act 2). Act 1 closest 0.14–0.28 throughout, **15/15 leaves
to 24**; the Night Mare at 25 cost 5 (41 s). Act 2 calm (≤ 0.24) until **drift 31, the Phantoms' intro (5
flyers leaked) and 32 (5 more): 7 leaves**, the run's end. No anti-air in this pair of families.
- On target (a fresh profile ends in act 2), and the user finds it fair. **No change.**
- Act 1 at ×1.30 still reads calm for this player with a carry (the bot sits at 60%); watch, don't tune yet.

## Human run 17 (2026-10-04, build a4bd05 = 0b41c1ed: act 1 ×1.30, half cells, one-half gaps; 0 Grove)

**Lost at drift 40**, 16 min; user: *"didn't play too much"* (drift 2 took 152 s; **1,000–1,337 Dew unspent**
from drift 37). Bellflower → Sporeling; Brood Cap / Chime Stones / Silver + Vesper Bells; combos 34%.
Longest path **68 cells**. **Act 1 at ×1.30 still read very calm** (closest 0.14–0.22 most drifts, 0.46–0.70
only at the finales; the Stag in 15 s). Act 2 calm to 37 (≤ 0.45), then **38: 13 leaks / 6 leaves, 39: 8**,
dead at 40.
- A low-attention run (Dew left unspent), so not used to tune.
- **Pattern across runs 15–17:** full leaves deep into act 2, then a collapse at 38–40. Watching it: if the
  next attentive run repeats it, act 2's last third (37–45, 3.45 → 4.5) gets smoothed.

## Human run 16 (2026-10-03, build 0848cb = 27c658f7, the real profile with 0 Grove nodes)

**Lost at drift 42**, 13 min. Firefly Jar → Dewdrop; **2 Starbursts = 53% of damage**, 7 Sparklers, 3
Cloudlets. **Combos 41%** of damage (the top of the 25–40% target). **15/15 leaves through drift 39**, no leak
before 40; the Hollow Stag in 22 s; act 2 closest mostly 0.2–0.4. Then **the drift 40 finale: 9 leaks, 13
leaves in one drift** (its 3 elites at ×3 × 1.4 = ×4.2 health), and 41–42 finished it. Kills sat at 0.0–0.3 of
the route, Heartwood share 0%.
- On target: a fresh profile ending in act 2 ✓.
- A full-leaf run losing almost everything to one finale is a cliff: **the finale's ×1.4 no longer stacks on
  its elites** (elites keep ×3; in 577f62b0).

## Nurture rework (2026-10-03, tower_design / warden_stats 02417f32; in e2631f54, boss side 0a309566)

Numbers: Keen +10% crit chance per rank (cap 75%); Yield +1 alive per 2 ranks (Brood Cap, Seedbearer), Dream
Oak +0.5 shard / drift per rank; Reach +0.3 cells; Deep caps (pull 1.5×, grounding 5 s, link 50%, boss
slow floor 0.35); supports Prism +2%, Acorn +1%, Nurse Log +3% (40% max). **Probe** (rank V, no Dreams):
**Keen 0.61–0.82× Power** per Dew; **Brood Cap Yield 0.56×** (max-alive rarely binds). Changes: **Keen also
+10% crit damage per rank**; **Brood Cap Yield = sprite interval −0.25 s per rank** (floors 0.75 / 0.5 s; in b1e28266). **Re-run:** Keen 0.87–0.91× Power (Moonstone 0.64: already 25% crit, Power is its pick; accepted); Brood Yield 0.78× → **+8% sprite burst per rank** too (dc26dea0): Brood Yield now **1.09× Power** (leak 0.228 vs 0.211) ✓. Nurture tuning closed.

## Human run 15 (2026-10-03, 83d9b3b0 → 5692de; before the finale-health fix, Dev Grove: Full)

**Lost at drift 39**, 18 min. Pebbling → Rootling; 7 Mossbacks carried (from combos 26–34%); run combo share
**23%** (near the 25–40% target). Act 1 calm (closest ~0.3–0.5) except the finales (10: −3, 15: −2); the
Hollow Stag in 23 s; act 2 calm to 29, then **the drift 30 finale −6**, and 38–39 the rest. Kills at 0.2–0.4 of
the route. User: **"Feels fine, keep it for now. Needs a bit more testing."** No change.

## Human run 14 (2026-10-03, same build, Dev Grove: Full)

**Lost at drift 20** (a finale), 8 min. **Acorn first**: 2 Acorns, 4 Elder Stumps, 13 Sprouts; Dew banked
230–320 through drifts 5–11. Leaks from drift 6; the drift 10 finale spawned 9,281 health (×2.5 drift 9;
the finale fix lowers it); 4 leaves at 15, the rest at 19–20. Kills moved deep (0.5–0.8 of the route) by
block 3. Combos 1%.
User on support openers (Magpie Perch, Acorn): **"Keep as is"**. Picking a support family first is a
choice with a cost. No change beyond the pending drift 10 finale fix.

## Nap batch on main (2026-10-02, 175058a0: Spire rules + round 3)

**1. Round-3 re-probe of the new branches** (fixed board, 3 seeds): **in band:** Undercurrent 0.52×,
Jarlink 0.52× (fence 96%) Driftspore; Silence 0.82× Puffball. **Just under:** Lightning Fence 0.68 / 0.78×,
Rainbow Prism 0.72 / 0.64×, Prism Jar 0.38× → **last nudge** (19941de6): Fence arc 650, Rainbow 240, Prism Jar 105.
**Bells** (Silver Bell, Vesper Bell, Hushbell) still below par on leak; left for human runs (their
sleep / silence value needs real builds). The new-branch probe series is closed.

**2. Act 1 baseline** (fresh, real boss draw, 30 seeds): Balanced survives the boss **30%** (target ~55–60%;
14/30 die before 25), skip **0%** ✓. Finales: drift 10 0.62 leaves (86% clean), 15 0.92 (81%), **20: 2.53
(29% clean)**. Below the Spire branch's own 50–55% on the same act 1 rules, so something since then made
act 1 harder for the bot: A/B queued (branch expansion on / off, and the pre-expansion branch build)
before choosing a lever (finale health, the drift 20 finale, or the ramp).

**3. Each start family** (fresh, forced, 15 seeds): survived the boss **Bellflower 53%, Sporeling 40%,
Dewdrop 20%, Firefly Jar 7%** (target 70–90%). Dewdrop leaks hardest at the finales (2.8 / 3.8 / 2.8 leaves
at 10 / 15 / 20); Firefly dies mostly at 13–20. All four are low, matching item 2; the A/B decides the cause
before any family change.

**5. Demo sanity** (`--demo`, DEMO_RULES, the Hollow Stag, 20 seeds): Balanced **70%**, skip **40%**; finales
cost nothing (no finale rules in the demo). **The demo gating works** and plays like before the Spire rules.
So the full game's 30% comes from what differs: the act 1 ramp from drift 3, the finales (×1.4 + elites),
and the branch expansion. The A/B splits the branch expansion off from the rest.

**Act 1 A/B** (fresh, Balanced, 30 seeds): main as is **30%**; main with the branch expansion off **60%**;
the Spire build before the expansion **60%**. With the expansion on, the bot grew Driftspore in 8 runs
instead of 21 and took Lichenling / Brood Cap instead. **Cause: the 2-of-5 draw often doesn't offer
Driftspore, and the new damage branches are weaker.** Decision: the damage-branch band tightens to
**0.8–1.0× Driftspore** (a drawn branch must be about as good as the one it replaces). Raises: Lichenling
22, Brood Cap burst 24, Thrum 70, Jetreed base 60, Undercurrent 60 dmg/s, Jarlink arc 210, Sparkler 40 (in 7567034e).
Re-run arm (a) after.

**Arm (a) re-run on 7567034e** (the branch raises): **40%** (was 30%; 60% with the expansion off); drift 20
finale 1.33 leaves / 50% clean; 14/30 still die before 25. When Driftspore isn't offered, the bot now
grows Bloomcap / Lanternmoth / Prism Jar (supports and enablers), so an act 1 pair of two supports leaves
no carry. Proposed to Tower Discussion: **every offered pair includes at least one damage branch** (a
draw rule); if not, act 1 eases instead.
**Agreed as a hard rule** (Tower Discussion 66e9927b): every offered pair has ≥ 1 **carry**. Carry list
(own damage ≈ 0.6× Driftspore or more; Balancing Discussion owns it): Sporeling driftspore, inkcap,
lichenling, brood_cap; Dewdrop rain_lily, mistveil, cloudlet, undercurrent, jetreed; Firefly Jar jarlink,
sparkler; Bellflower chime_stone, thrum; Pebbling cairn, standing_stone, whetstone, rampart, quaker;
Rootling rootcurl, tangleroot, rootlight; **Acorn exempt** (no carry branch). Built in a1b934d0 (`DreamState.CARRY_BRANCHES`); detection weight ×3 after coverage fell to 73% (agreed with Tower Discussion: 78%, Rootling top pair 34 → 36%); Thorncoil joins the carries if its re-probe lands in band. Act 1 numbers unchanged
until the re-run.

**Arm (a) with the carry rule** (a1b934d0): still **40%** (drift 20 finale 65% clean; 16/30 die before
25). Bloomcap is still grown in 5 runs although every pair now has a carry, so the open question is the
bot's choice between the two offered branches. An offered-branches column is being added; if the bot
passes up a carry, the fix is the bot's policy, not the game.
**It was the bot:** it alternated growth between its unlocked branches (Driftspore, Bloomcap, …). Fixed
(Balancing Code 63da43c8: through drift 25 it grows and unlocks carries first). Same 30 seeds: **47%** with
the fix vs 37% without. Driftspore is offered in ~1/3 of runs (vs every run with the expansion off), so
the Lichenling / Brood Cap runs are what's left: **Lichenling 26, Brood Cap burst 28** (the top of the band; in 84bbaf44).
**Re-run on 84bbaf44:** **53%** (close to target; no more Sporeling changes). With Driftspore offered 9/12,
without 7/14. **Firefly Jar first: 0/9** (it was 70% before the Spire rules). Its carries are now Jarlink
and Sparkler; checking whether the bot's normal placement ever makes a Jarlink arc over the route (the probe
places pairs on purpose) before any game change.
**Answer:** the 9 runs died at drifts 8–23 with 8–12 base Firefly Jars and at most one branch Warden, and no
Jarlink pair was ever made. Forced Firefly, 15 seeds: **27–33%** with or without a bot fence rule (fence
damage 0: the bot rarely has two jars across the route). Jarlink pairing is human skill (the build ghost
shows the arc); **the base board is the problem: Firefly Jar cost 30 → 25, damage 12 → 14** (d69c53b4; shared with the
demo, which is re-checked).
**After d69c53b4** (15 seeds): full game Firefly-first **33% → 47%**, no run dies before drift 18 (was 10–17);
the demo 87% → 100% (two runs; within noise, and the demo is the gentle intro). **Accepted; act 1 tuning
closed** at ~50–55% overall for the bot (the user plays better than it). Human runs judge from here.

**4. Grove cap on main** (ed114826, before the branch raises; a bot gift-screen stall voided the first
attempt): full loadout vs no perks, 20 seeds each, act 1 boss survival **40% vs 30% (+10 points)**, +2.5
drifts: **within the ≤ +10–15 cap** ✓. Both arms suffer the branch-draw drop. **Combo share** (bot):
run-level 0.11–0.14, Reactions 0; it only reaches 0.2–0.45 in late blocks with few runs left. The bot
under-builds combos; the 25–40% target is judged on human runs (`combo_share` in the run history).

## Combo share of damage (user-approved, 2026-10-02)

The user's Warden panels showed 52–76% of damage "from combos". **Target: in a good build, combos and
Reactions make ~25–40% of all damage**: a real boost, not the majority. Measured as (combo bonus
amounts + Reaction damage) ÷ total damage, by block, for the bot (Balancing Code, on the Dreams-vs-skip
batch) and in the run history (Main Merger adds `combo_damage` / `reaction_damage` / `status_damage` /
`combo_share`, in 731537b5; the record only had counts). Levers if far above: lower Reaction base damage, raise
Wardens' direct damage, or both. Main first, the Spire branch after.
**Bot measurement** (9b1a73ee, Resonance removed, real boss draw, 20 seeds per mode): combo share
(DamageLog combo_amount ÷ damage) rises **0.06 → 0.39** fresh by drifts 36–40 (full profile 0.12 → 0.31);
Reactions stay small (≤ 0.10). Top Wardens' "from combos": Stormcap 0.43–0.49, Firefly Jar 0.30–0.35,
Driftspore 0.23–0.28, Sporeling 0.15. **Within the 25–40% target for the bot**; the user's 52–76% comes
from human builds deeper into combos (and a Static bolt counts whole as combo). Decision waits for the
first human runs carrying the new `combo_share` fields. No lever change yet.
**Resonance removal check** (same batch): fresh with Dreams passes the act 1 boss **15/20 (75%)** ✓, skip
**5/20 (25%)** ✓; runs with ≥ 3 Dream picks of one tag (a decent-build proxy) **55% fresh / 60% full** ✓
(target ~50%). **No card re-basing needed.**
**Combo cards as choices** (dream_design.md 784680b2): power signed off, with **Quick Reactions'**
trade set at **−35%** Reaction damage (not −25%: double frequency × 0.75 was still +50%). Pick rates vs
same-rarity cards are checked once offers are logged.

## Tag Resonance removed (user, 2026-10-02; dream_audit.md a6628056)

Resonance (+10% per same-tag card, max +50%) was a bonus on top of rarity-budgeted cards, so **no
re-basing** (agreed with Roguelite Mechanic Discussion; fits "runs too strong / cards handed to me").
Removal in 854a537e. Check: Dreams vs skip on main (act 1 targets: Balanced ~75%, skip clearly
lower); specific cards are raised only if builds fall short.

## Caveat: fresh-profile sims ran as the demo (found 2026-10-02)

Until e3f3a211, every **fresh** sim ran as the demo (`game/demo` true under `--script`): act 1–2 bosses
were the defaults whatever the seed, the demo's Kinship set applied, and the Grove was inert (no effect
on fresh). Half / full sims and all human runs were the full game. Affected: the fresh act 1 baselines,
the bite-10 checks, the per-family act 1 tables and the first-pick-1 baseline (all on the Hollow Stag);
the Night Mare check forced its boss and stands. Fixed: all sims run as the full game, and
`--boss-draw` gives the real per-seed draw. The overnight batch re-measures act 1 per family and per boss.

## Overnight batch (2026-10-02, full game, real boss draw, build e3f3a211)

**Morning summary.** In the game: Bellflower 17 (756676ac), the Sunpetal beam fix (d4efe268), the echo
follows its nightmare (dd977146). Act 1 is on target for all four start families and all three bosses;
the economy matches the design. **Committed in 2ef6d56f:** 16
Warden files (Autumn Gale 85, Moonstone 490, Elf Circle 68, Snugroot 56, Fairy Ring 30; Starling
Murmuration 57, Jewelwing Court 28, Midsummer 170, Sunpetal 81, Hummingbird Bower 27, Mossback 372,
Wren's Nest 27, Frostfern 72, Whispering Hollow 50, Echo Hollow 22; Stormcap chains 4). Then a
129-run re-probe of branches + finals and an 18-run Hollow re-check.

**1. Act 1 per start family** (fresh, forced first family, 20 seeds; draw: Scarecrow 10, Stag 5, Night
Mare 3): survived the boss, Balanced / skip: **Sporeling 85% / 45%**, Firefly Jar 70% / 20%, Dewdrop
70% / 30%, **Bellflower 50% / 25%**. Bellflower leaks in block 1 (29 nightmares over 20 runs; the
others 0–1) and in the boss block, but has the calmest blocks 2–4. Sporeling skip is the main miss on
"skip loses". Decisions after item 2 (bosses forced).

**2. Act 1 bosses forced** (fresh, 20 seeds each): survived with Dreams / skip: **Stag 80% / 30%,
Night Mare 80% / 15%, Scarecrow 80% / 25%** ✓ all targets. The Stag is survived by its bite (55%
dispelled); the Night Mare and Scarecrow are mostly dispelled (80%) at a median 5 leaves (laps,
Crows). The boss pool is fine.

Decisions: **Bellflower damage 14 → 17** (in 756676ac; the only family off target, 50%, and the only one leaking
in drifts 1–5). **Sporeling unchanged:** its 45% skip in item 1 doesn't repeat in item 2, where most
skip runs opened with Sporeling and survived 15–30%.

**Bellflower re-check** (3608f4fc, damage 17, same seeds): Balanced survives the boss **75%** ✓ (was
50%), skip 30% (was 25%); block 1 leaks 4 over 20 runs (was 29). **Closed.**

**5. Economy** (40d26ed1, full profile to 40, 20 seeds, Clear Skies vs always face): Dew earned in
drifts 1–25 **2,387 vs the pot table's 1,960** (+22%: rest bonuses, Rich Dew and call-early on top, as
designed); the bot banks ~20–50 at each rest. **Dreamlight is spent the moment it arrives**: first pick
→ one branch, then ~2.5 forms per run by 40 (per-run order inferred, not traced). Always facing Omens:
Omen Dew −626 to +690 per run (negative runs: likely Dry Spell, the only pot cut; not checked), median drift reached 24
vs 27. **No change:** income matches the design, and Omens are the gamble they should be.

**Branch sweep** (40d26ed1, every branch ×4, rank IV, no Dreams, drifts 45–49, per Dew vs Driftspore):
**Fairy Ring ~1.6× Driftspore** (1.5× Puffball, the only branch above a final) → **damage 44 → 30**.
The damage branches spread 0.25–1.0×; support / economy branches sit near zero on their own damage
(their board leak tells more: Bloomcap and Rain Lily boards leak less than higher-damage ones). Role
check with Tower Discussion on the low ones (Hummingbird Bower, Sunpetal, Frostfern, Stormcap, Gust,
Echo Hollow, Wren's Nest, Mossback).
Roles and decisions: **Stormcap** (0.22×, yet even with Chime Stone at drift 15) and **Sunpetal**
(0.11×, a ramping beam) are checked for bugs first (chain / bolt scaling; does the beam's ramp reset
on retarget?). Buffs: **Hummingbird Bower ×3** (9 → 27), **Mossback ×1.5**, **Wren's Nest ×1.5** (a
fast-nightmare specialist), **Frostfern ×2** (an enabler that shouldn't feel dead). Gust and Echo
Hollow are support: board-lift probes.
Bug checks: **Sunpetal was a bug** (the beam retargeted to each new front-runner and its ramp reset;
fixed in d4efe268: beams hold their target while it's alive and in range). **Midsummer's ×2 reverted**
(measured with the bug; re-probe first). **Stormcap: no bug** (chains and bolts use ranked damage);
its data is the lever: **chain targets 3 → 4**.
**Clean beam probe** (d4efe268): the fix adds only 10–20%: Midsummer ~0.31 / 0.35× Puffball, Sunpetal
~0.12×. Buffs: **Midsummer 68 → 170 (×2.5)**, **Sunpetal 27 → 81 (×3)**; re-probe after.

**Support check** (d4efe268; 4 of the support vs 4 of a reference on the same board, 3 seeds; pass =
board damage ≥ and leak ≤): **Hoarfrost ✓** (board 0.96–1.24×, Shatter 41–55% of its credit, act 2 leak
≤ 0.8%); **Grafted Elder ✓** (board 0.95–1.24×; per Warden 1.0–2.2× a Puffball, consistent with copying
two neighbours at 85%); **Zephyr and Gust at par** (board 0.94–1.04×): accepted for supports.
**Whispering Hollow ✗** (board 0.60–0.91×, echo only 1.6% of its credit) and **Echo Hollow ✗** (2 of 3
maps): **bug check first** (do the echoes fire on Thunderclap; where is echo damage credited?), then a
number.
**Found:** echoes fire and are credited correctly, but land 1 s later on the **same spot** (1-cell
reach), after the nightmare has walked on (a walking Shade took 0 echo hits). Recommended to Tower
Discussion: the echo **follows the nightmare** the Reaction fired on. Re-probe both Hollows after.
**After the fix** (dd977146): echoes land (Whispering Hollow's echo share 1% → 4–5%, Echo Hollow ~70%),
but both boards still fail (WH 0.61–0.90× with far more leak; EH 0.86–1.05×): Reactions are too rare
for echoes to carry a Warden. **Own pulse up: Whispering Hollow 18 → 50, Echo Hollow 10 → 22.** Echo
shares final at 0.75 (Echo Hollow) / 1.0 (Whispering Hollow).
**Full re-probe on 2ef6d56f** (eb0063cd, 3 seeds): finals in act 2 all in band except Midsummer 0.78
(close); act 3 still high for Autumn Gale 2.07, Snugroot 2.18, Elf Circle 1.75, Moonstone 1.65 (they
scale with the bigger act 3 field). Branches: Fairy Ring 1.19× Driftspore (was 1.6), Mossback 0.61 into
band; still under 0.5: Wren's Nest 0.47, Sunpetal 0.37, Hummingbird Bower 0.31, Stormcap 0.28,
Frostfern 0.26 (an enabler), plus the support / economy tail. **Last step, then the probe series
closes:** Autumn Gale 85 → 72, Snugroot 56 → 48; Hummingbird Bower 27 → 40, Sunpetal 81 → 113, Stormcap
damage 18 → 24; Whispering Hollow 50 → 62, Echo Hollow 22 → 28 (in 14546411). Everything else stays; human runs judge
from here.
**Re-check on 2ef6d56f:** Whispering Hollow board **0.95–1.03× at 45** (par) but 0.69–0.82× at 61, and
still leakier; Echo Hollow board unchanged (0.85 / 0.85 / 1.07). Held for the full re-probe, then one
more step on both, decided together with the branches.

**4. Act 2 bosses at drift 50** (40d26ed1, fixed board of 12 finals, rank IV, no Dreams, 3 seeds): none
dispelled; health left at the Heartwood Huntsman 44–88%, Lamplighter 10–34%, Mire Hag 45–53%. A
no-Dream board is a floor, not a player's board. Bosses at **×1.75** (confirmed: Huntsman 6,500 × 1.75
× 4.5 = 51,188). No change; the next human run on ×1.75 decides.

**3. Finals sweep** (40d26ed1, every final ×4, rank IV, no Dreams, finals cast, 3 seeds, per Dew vs
Puffball; band 0.8–1.5×). **High:** Autumn Gale 1.61 / 2.36, Moonstone 1.54 / 2.11, Elf Circle 1.42 /
2.10, Snugroot 1.34 / 2.36 (act 2 / act 3); Lullaby Bell (72) 1.34 / 1.53 (accepted). **Low damage
dealers:** Midsummer ~0.28, Starling Murmuration ~0.53. Supports / economy (Grove Heart, Beacon,
Wellspring, Great Dreamcatcher, Magpie's Hoard) are low on direct damage by design; Thunderhead (0.37)
is a Static enabler (Puffball's Ignite, Morning Fog's Thunderclap). **Decisions:** damage ×0.75 on
Autumn Gale, Moonstone, Elf Circle, Snugroot; Midsummer ×2, Starling Murmuration ×1.5. Role check with
Tower Discussion on Whispering Hollow, Zephyr, Grafted Elder, Jewelwing Court and Hoarfrost. Re-probe after.
Roles (Tower Discussion): **Jewelwing Court** is a damage final → **damage 23 → 28**. Whispering Hollow
and Zephyr are amplifiers, Hoarfrost a combo piece, Grafted Elder a copier (~0.85× its neighbours):
judged by the **board with vs without them** (vs 4 Puffballs) on boards that suit them, not by their
own damage per Dew. Support probes queued.

## Route profiles in the run history (user, 2026-10-01)

User: *"Look where I've invested the most in the maze; it shows where most of the nightmares die."*
Requested from Main Merger: `dispels_by_progress` (kills + health per 0.1 of route progress, plus
leaked, per block), `invested_by_progress` (Wardens' Dew spread over the route cells they cover, at
each rest) and `heart_share` (Dew within 3 cells of the Heartwood), with report lines and, if cheap, a
heat-map PNG. **In from d8010456** (`route_blocks`, `heat_map` in user://run_maps/). The bot logs the same. Reads: front-loaded vs last-ditch builds, where leaks slip
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
