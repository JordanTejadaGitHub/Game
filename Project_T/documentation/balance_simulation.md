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
