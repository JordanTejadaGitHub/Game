# Run Design: pacing, rules and economy

Phase 1 of `design_plan.md`. Revised 2026-09-27 to **100-drift runs** ("drift" = wave). This
replaces the earlier 15-drift version and the "10 drifts per run" prototype target in
`game_design.md`. All numbers are starting points for playtesting; they live in data (`RunState`
exports, `TowerData`, `EnemyData`, `DriftData`), so tuning never needs code changes.

## Decisions

| Question | Decision |
|---|---|
| Run length | **1–2 hours** (100 drifts); saved and resumable |
| Structure | **4 acts of 25 drifts**, a boss every 25th drift |
| Rewards | **A Dream every 5 drifts**; **each boss (25, 50, 75) unlocks a new Warden family** |
| First Warden | picked **after drift 1** (pick 1 of 3 base Wardens) |
| Mid-run save | **Yes**, at every rest (every 5 drifts) |
| Building during drifts | **Allowed** (build, evolve, sell and clear at any time) |
| Clearing obstacles | **Locked until you take a clearing Dream card** (`dream_design.md`, cards 54–58) |
| Selling | **75%** refund during a **rest**, half while nightmares are walking (difficulty pass v1) |
| Warden ranks | each Warden can be **Nurtured** up to **rank V** with Dew; ranks carry through evolution (`warden_stats.md`) |
| Speed controls | **Pause, 1×, 2×, 3×.** Building works while paused |
| Obstacle payoff | **+1 Seed per cleared obstacle** at run end; Withered Tree / Mossy Boulder |
| Call early | **Yes**, small Dew bonus |
| Final boss | **Always The Hollow Oak** (drift 100) |

## Run structure

**100 drifts in 4 acts of 25.** One map for the whole run, so the maze keeps paying off.

| Act | Drifts | Feel | Boss |
|---|---|---|---|
| 1. Forest's Edge | 1–25 | learn the maze, first Wardens | 1 of 3: **Hollow Stag**, Night Mare, Scarecrow (25) |
| 2. Deep Wood | 26–50 | maze testers arrive, builds take shape | 1 of 3: **Mire Hag**, Huntsman, Lamplighter (50) |
| 3. Misty Hollow | 51–75 | status testers, bigger drifts | 1 of 3: **Moth Queen**, Barrow King, Mourning Mother (75) |
| 4. Heartwood Glade | 76–100 | full builds, everything mixed | **The Hollow Oak** (100, story climax, always), in 1 of 3 variations: Thorned, Withering, Remembering |

**Boss pools** (2026-09-29, like Slay the Spire): each run draws one boss per act for acts 1–3,
shown from the act's first drift so players build toward it. First run ever: always the Hollow
Stag. Details in `enemy_design.md` ("Bosses: a pool of 3 per act").

- **Win:** dispel The Hollow Oak and every nightmare still in the dream.
- **Between acts:** the season changes (spring dusk → summer night → autumn fog → winter dark;
  `art_direction.md`), the Heartwood regrows 1 leaf (up to its
  maximum), and the boss rewards (below).
- **No endless mode for v1.** Blight Levels are the replay hook.

### Blocks and rests: how 100 drifts flow

Drifts come in **blocks of 5**:

```
[rest] → drift 1 → (quick rest: pick your first Warden) → drifts 2–5 flow → [rest: Dream]
       → drifts 6–10 flow → [rest: Dream] → … → drift 25 (boss) → [rest: Warden family + Dream] → …
```

- **Within a block, drifts flow.** The next drift starts automatically a few seconds after the
  previous one has finished *arriving* (not after it's dispelled), so drifts overlap and there's
  no dead time. An **Auto-drift** toggle lets players turn this off and start each drift by hand.
- **A rest** comes after every 5th drift, once the field is clear: time pauses, the Dream (or boss
  reward) appears, and you can rebuild at a 75% refund. Press **Start** when ready. No timer.
- **Call early:** starting the next drift before the previous one has finished arriving gives
  +1 Dew per 2 seconds skipped (capped per drift).

### Random drifts: every block rolls its nightmares (2026-09-29)

User: *"Enemies should be random every block, to add versatility and not predictability."* Until
now every run met the same drifts in the same order (`acts_1_2.md`, `acts_3_4.md`), so a learned run
played the same way. From now on **the drifts are rolled per block**, while the difficulty curve,
the teaching and the bosses stay fixed.

**What stays fixed**
- **Bosses** at 25, 50, 75, 100 (with their escorts) and the **drift budget**: each drift's total
  nightmare health follows the existing curve (growth, act multipliers, extra nightmares, elites),
  so difficulty doesn't change, only *what* the health is made of.
- **Introductions:** each nightmare type still **first appears** at its scheduled drift (the tables'
  "intro" drifts: Mourner at 16, Phantom, Night Hound, … and acts 3–4's), with its intro card. A type
  enters the random pool **only after** it has been introduced in this run.
- **Drift 1–5** stay hand-made (the first block teaches the basics).

**What's rolled** (at the rest before each block, so the Coming strip shows the real roll):
- Each drift draws a **template** from its act's list, weighted: *Mixed* (the common case), *Swarm*
  (many small), *Heavy* (few tough), *Fast* (Hounds, Phantoms, …), *Procession* (followers), *Special*
  (one trait-heavy type, like the old Wake or Vigil), *Elite hunt* (fewer, more elites, act 2+). The
  old named drifts become templates.
- The template picks its **types** from the unlocked pool and splits the drift's health budget among
  them (each type's share at least 15%, so a drift mixes 2–4 types unless it's a Swarm or Special).
- **At most one Special or Swarm per block**, and never two of the same template in a row.
- **Act 1 density cap** (2026-09-29, family-opening check: single-target families died at the densest Shade drifts): in act 1, **small nightmares (Shades, Sobs, Creeps) at least 0.9 s apart** in every drift outside the Swarm template, and a Swarm in act 1 at most 20 of them. Single-target families (Pebbling, Nestling) must be able to keep up.
- **Fairness:** act 1 keeps the rule that no drift has more than ~40% of its health resistant to one
  damage type the player can own; **acts 2–4: at most ~60%**, and a block never leans on the same
  resisted type for more than two drifts. No block is all flyers or all through-walls.
- **Omens** apply on top of the roll (e.g. Moth Night adds flyers to whatever was rolled).

**Seeded and fair to compare:** the roll uses the run's seed (from the map seed), so a saved run
resumes with the same drifts, and two players on the same seed meet the same nightmares.

**Shown:** the Coming strip lists the rolled types and counts at every rest; the rest report can say
*"This block: Swarm, Mixed, Heavy, Fast, Mixed"*. The boss dossier is unchanged.

**Balance:** the simulation now also varies by seed on drifts, so batches use **10 seeds** instead of
5. The hand-made tables in `acts_1_2.md` / `acts_3_4.md` remain the reference for budgets,
introductions, templates and boss escorts.

**As built** (Enemy Code, 0cd0fa2 + b056b94): rolled once at run start from the seed (a resume gets the same drifts); each rolled drift keeps its hand-made drift's health budget (±5%), arrival window and **designed elites** (those count outside the fairness caps: a fixed design choice); the caps count **every family a nightmare resists**, not only the starting three (stricter, and right for the full game, where any unlocked family can open a run); the "one resisted type in at most 2 drifts per block" rule applies in acts 2–4 only (act 1 has too few types); tested over 200 seeds (~14,600 drifts). The rest report can name each drift's template (`DriftRoller.template_name`).

### Time budget

A drift's creatures arrive over ~20–40 seconds, but a creature takes 1.5–3 minutes to walk a
built maze, so drifts overlap. A block of 5 drifts takes ~4 minutes early, ~6 minutes late.

| | Per block at 1× | Act at 1× |
|---|---|---|
| Act 1 | ~4 min | ~20 min |
| Act 2 | ~4.5 min | ~23 min |
| Act 3 | ~5 min | ~25 min |
| Act 4 | ~6 min | ~30 min |

**Total ≈ 100 minutes at 1×, ~60 with 2×/3×**, plus rests. If playtests run long, shorten the
arrival windows or speed creatures up before cutting drifts.

### Mid-run save

- **Autosave at every rest** (every 5 drifts): the map, Wardens, Dew, leaves, Dreams, drift number
  and the random state, so a resumed run continues exactly.
- **Save & Quit** is available any time; quitting mid-block resumes from the **start of that
  block's last rest** (at most ~5 minutes lost). Simple, fair, and no save-scumming of single drifts.
- One run in progress at a time. The title screen shows **Continue** when one exists.

## Leaves (lives)

- **Start with 15** (was 20; difficulty pass v1). A normal nightmare costs 1 leaf; big ones
  (`EnemyData.leaf_cost`) cost 2; bosses cost 5.
- Regrow **1** at each act break (was 3). Perks and Dreams can raise the maximum.
- 0 leaves = the Heartwood goes dormant, run over (Seeds are still earned).
- **Tune in playtests.**

## Difficulty curve targets (2026-09-28)

User direction: **"They should be leaking early until you're able to unlock some perks from meta and
cards."** A new Heartwood should feel outmatched; Memory Grove perks and a run's Dream cards are what
turn leaks into a hold. Targets for the balance simulation and playtests (average, sensible play):

| Player | By the Hollow Stag (25) | Typical run end | Wins |
|---|---|---|---|
| **Fresh profile** (no Grove) | **reaches the first boss** with few leaks and **beats it about 75% of the time** (user, 2026-09-29: "doesn't have to beat the first boss all the time") (**0–3 leaves** lost; revised 2026-09-28, user: "players should be able to get to 25 even without perks and unlocks; 25 is when they start getting combos") | act 2 (drift 35–50): **it gets harder after 25** | rare (<5%, strong play + good Dreams) |
| **~5 Grove unlocks** (~3 h in) | a few leaks, 2–4 leaves lost | act 3 | occasional |
| **Half the tree** (~15 h) | few leaks | act 4 | the first win |
| **Full tree** | clean | wins reliably at Blight 0 | Blight Levels bring the leaking back |

- **The shape of a run** (revised 2026-09-28): **act 1 teaches** (a sensible maze reaches drift 25
  with few leaks, even with no Grove); **from drift 25 it gets hard**, as combos, the second family
  and Dreamlight arrive: leaks start in act 2 unless the Dreams and combos come together, so each
  block's Dream visibly matters there.
- **Spend or save: the early tension** (2026-09-29, user: "we want users early to be using the Dew
  as drifts happen, or take the risk to save the Dew for bigger upgrades; if they save, nightmares
  should come close to reaching the Heartwood"). Act 1 is tuned so that:
  - **Spending as it comes** (planting and growing whenever affordable, building the maze) is safe:
    nightmares rarely get past **about 70% of the route**.
  - **Saving** (holding Dew for up to a block to afford a bigger growth, e.g. a branch or an early
    final) is a real gamble: nightmares reach **about 85–100% of the route**, the Heartwood shakes,
    maybe **0–2 leaves** fall, but a decent maze survives it and the upgrade then pays off.
  - **Neither choice is always right:** saving should win over a whole act if you survive the
    gamble, and spending should win if your maze is weak. The maze itself (its length, its bends)
    is what makes saving affordable, so building the maze stays central.
  - Feedback that sells the gamble: the Heartwood's leaves tremble and the route near it glows
    faintly cold when a nightmare passes 85% of the route (a "close call"), and the rest report
    counts close calls.
- **Leaks must be readable, not random:** a leak should come from a nightmare the maze doesn't
  answer (a Hound on a straight, a Phantom through walls, a resisted family), so the rest report and
  the boss dossier point at the fix.
- Current state (playtests 2026-09-28): too easy from act 2 on, even with a thin Grove. Fixes so far:
  the Sapling removed, one Ascended per family, Nurture's rank difference, resistances corrected.
  The balance simulation measures the rest.
- **Interim acts 1–2 tightening** (2026-09-28; two playtests: a fresh profile at drift 23 and
  again at drift 43 with **15/15 leaves**, ~800 and **1,925 Dew banked**, "haven't done much in the
  past 10 drifts"). **Revised the same day** (later playtests: "too hard from early drifts, especially 15 with the swarm"): nightmare health **×1.0 for drifts 1–9, ramping to ×1.15 by drift 20 and holding to 25** (2026-09-29: saving was almost free for the starting three families; the drift 25 Hollow Stag itself is exempt and keeps ×1.5, its escort doesn't), then **act 2 at ×1.15 for drifts 26–30 (a breather while the first finals arrive), ramping to ×1.55 by drift 45** (was: ramp from drift 26, which left 2–4 of 10 Grove-player runs dead at 28–30), ×1.55
  to 50** (acts 3–4 go from ×1.4 to **×1.6**, 2026-09-29), and **Dew per dispel ×0.85 in act 2 only** (act 1 back to ×1.0). Drift 15's Swarm is lighter (`acts_1_2.md`). Interim
  numbers, as exports, until the balance simulation's quick batch replaces them.
- **Human playtest after the Dream power pass** (2026-09-30, user's first run on a fresh profile,
  starting families only, no Grove: **drift 60 with 15/15 leaves, 1,746 Dew banked, maze ~10,000
  DPS**; *"feels too strong … felt like cards were handed to me"*). The target for a fresh profile is
  a run that **ends in act 2**. The cards were made stronger on purpose; the matching health rise
  for acts 2–4 was waiting on human data, and this is it. **Interim health (until the run history
  has more runs):**
  - **Act 2:** ×1.3 at drift 26, ramping to **×2.5 by drift 45**, held to 50 (was ×1.15 → ×1.55; first set to ×2.0, raised after human run 1, balance_simulation.md).
  - **Acts 3–4:** **×3.5** (was ×1.6; first set to ×2.4), bosses included **except the Hollow Oak at drift 100**, which keeps today's health.
  - Act 1 unchanged (the first boss is being tuned on its own).
  - **Dreams steer a little less:** the build tag weight 1.6 → **1.3**, so a direction takes
    choices (a pass, a reroll) instead of arriving by itself. Card power stays.
  - Then read the run history after each playtest and adjust.
- **Act 3 probe** (Tower Code, `tools/balance_act3.gd`, 2026-09-28): drifts 61–70, 12 final forms at
  rank IV (Power), **no Dreams**: the maze dealt ~155–160k damage per drift against **~100–115k
  health spawned, 0 leaks**. Act 3 is too easy with a plain final-form maze, before Dreams or the
  Great Bell. The Great Bell took 40% of all damage, 74% of it from Charged stacks its toll set off;
  damage on Asleep nightmares was 56–63% of everything (sleep control is the other big lever).
  **Interim changes** (until the balance simulation, which also has to check what a player can
  really afford by drift 60):
  - **Acts 3–4 nightmare health ×1.4** (a flat act multiplier on top of growth; bosses included).
  - **The Great Bell's toll sets off Charged stacks at 50%** of their bolt damage (its own hits
    unchanged). Target: an Ascended form deals about **5× an average final form** in total (it
    takes 4 cells now), not 7× as measured.
  - Watch sleep: if Asleep damage stays above ~50% after this, look at Caught's +40% and
    Dreamshroom next.
  - **Rerun after both changes** (2026-09-28): ~200k health per drift, the maze deals ×1.11–1.14 of
    it, 0–5 leaks, still **without Dreams**. The Great Bell at half-strength set-offs was no better
    than the Lullaby Bell it grows from (it lost the Lullaby's own effects, ~150k over 10 drifts).
    Decision: **Ascended forms keep their family final form's signature effects** (the Great Bell
    keeps the Lullaby Bell's lullaby) **plus** their own; set-offs stay at 50%. That puts the Great
    Bell near **5× an average final form**, the target. Asleep share still 52–56%: watch.
  - **Legacy rerun** (17c217a, fixed seeds 7 and 42): with the Lullaby legacy the Great Bell hit
    **×6.6–8.7** an average final (35–42% of all damage); its own hits (400k+) became the biggest
    part. The Bell's spot swings its share 2–3×, so single-map numbers are loose. Decision: **Great
    Bell damage 180 → 130 and the toll every 8 s** (was 6): trims both its hits and its sleep
    control (Asleep share 44–62% with it). Target ×5–6. **Result (2b0b2c4): ×4.6 and ×6.5** on the two seeds (27–35% of all damage; 9 and 0 leaks): on target, done. Asleep share 36% and 60%: the high one comes from a Dreamshroom beside the Bell, so Dreamshroom / Caught wait for the realistic-run numbers.
  - **Next:** the probe with a **realistic run** (Dreams taken by the real offer logic, a Dew
    budget from simulated income, so the maze is one a player could afford) is the start of the
    balance simulation. Only then raise act 3 health further.
- **Demo:** it has no meta, so every demo run is a fresh profile. **Decided (user, 2026-09-28): keep
  that curve** (demo wins are rare: "go deeper in the full game"). Maybe later: **a few Memory Grove
  unlocks in the demo** (a small taste of the meta), decided after playtests.

## Difficulty pass v1 (2026-09-27)

Playtests found the game too easy, and Warden ranks (below) add player power, so:

| Lever | Was | Now |
|---|---|---|
| Nightmare health growth | ×1.035 per drift (×5.4 by drift 50) | **×1.045 per drift** (×8.6 by drift 50, ×78 by drift 100) |
| Nightmares per drift | as listed in `acts_1_2.md` | **+25% from drift 10**, applied only to kinds with 3+ in the drift (rounded up); single/paired specials, elites and bosses unchanged; intro drifts unchanged |
| Starting Dew | 60 | ~~45~~ **60** (reverted: drift 1 became unwinnable without leaks; see below) |
| Refund during a rest | 100% | **75%** |
| Leaves | 20, +3 per act break | **15, +1 per act break** |
| Boss health | base values in `enemy_design.md` | **×1.5** |

**Economy pass v2** (2026-09-27; playtest: "after a while I have infinite money"):

| Lever | Was | Now |
|---|---|---|
| Rest bonus | 20 + 10 × block (220 at drift 100) | **30 + 4 × block** (≈ 110 at drift 100) |
| Dew per nightmare | the same every act | **× 1.0 / 0.8 / 0.65 / 0.5 by act** ("the dream thins") |
| Elite Dew | × 3 | **× 2** |
| Branch / final form cost | +45 / +90 | **+80 / +200** (with more power per tier; `warden_stats.md`) |
| Nurture base costs | 15 / 25 / 40 / 60 / 90 | **25 / 40 / 60 / 90 / 135** (× tier) |
| Endgame | — | **Ascended forms** (one per family, from drift 51; `tower_design.md`) (the Heartwood Sapling was removed 2026-09-28, below) |

Target: by act 3 a player should have to **choose** between an Ascended form, nurturing and more
Wardens, never afford all of them.

### The Heartwood Sapling (REMOVED 2026-09-28; kept for reference)

**Removed** (user, 2026-09-28: after tuning it down, "maybe remove the sapling?"). The late game's
problems were too much Dew and too little challenge, and the Sapling only added Dew. It is **switched
off, not deleted**: the code, art and sound stay behind a setting (`DriftDirector` / `TowerPlacer`
flag, off), so it can return later, e.g. as a Memory Grove perk. Its Dreamlight (~5 over drifts
51–100) isn't replaced: bosses and the other sources cover Ascended unlocks. Design as it was:

After the act 2 boss (drift 50), the Heartwood offers **one Sapling** of itself to plant in the maze.

- **Free to plant, 2×2 cells**, anywhere the path rule allows (it's a wall like any Warden, so it
  reshapes the maze: a real placement decision). **Rooted:** once planted it **can't be sold or
  moved**.
- **It doesn't attack.** At the end of every drift it yields **+8 Dew**, and every **10 drifts**
  it ripens **+1 Dreamlight** (feeding Ascended unlocks).
- **Nurture it** (ranks I–V at the **base-form** price, 350 Dew in all) to raise the yield: **+4 Dew
  per rank** (rank V: +28 Dew per drift) and, at rank III and above, Dreamlight every **8** drifts
  instead of 10.
- **Tuned down 2026-09-28** (playtest: "the Sapling is giving too much economy"). Was +20 Dew per
  drift, +10 per rank (rank V +70 per drift = 350 per block, over 4× the ~80 rest bonus of act 3).
  Now: ~40 Dew per block unranked (about half a rest bonus), ~140 at rank V; the 350 Dew of ranks
  pays back in roughly 18 drifts, a real bet rather than a free win.
- **Leaks hurt it:** each leaf lost withers it slightly (−5% yield, recovering at each rest), so a
  greedy maze that leaks pays twice.
- Offered on its own card right after the drift 50 family pick (*"The Heartwood offers a seedling
  of itself"*). If declined, it can be planted later from the rest panel.

**Mid-game rework** (2026-09-27; playtest: "upgrading without thought wins the mid-game"):

| Lever | Was | Now |
|---|---|---|
| Health growth | ×1.045 per drift all run | **×1.045 for drifts 1–25, ×1.055 for 26–50, ×1.045 from 51** (≈ ×11 by drift 50, ×100 by drift 100; `acts_3_4.md`) |
| Elites | block finales only | **one Deeply Blighted nightmare in every drift from drift 31** (was 26; moved 2026-09-29: the Grove-player batch had half of all runs die at drifts 28–29, the act 2 opening, before any final form could be grown) (a random non-boss kind from that drift) |
| Family resist / weak | ×0.65 / ×1.35 | **×0.5 / ×1.5** (`enemy_design.md`) |
| Nurture | flat cost, +15% damage per rank | **Nurture v2**: cost × tier, +10% per rank, a Focus at rank III (`warden_stats.md`) |

Plus new build-direction cards (wide / narrow, `dream_design.md` 69–76), so the mid-game asks
*which* Wardens, not just *more* upgrades. Act 1 (drifts 1–25) is unchanged.

**Opening rule** (added after playtest: drift 1 couldn't be held): **drifts 1–3 must be clearable
without losing a leaf** by a sensible player using only Sprouts and Thornwalls. Difficulty comes
from later drifts, not the opening. So starting Dew stays **60** and drift 1 is lighter (6 Shades,
2 s apart; `acts_1_2.md`). A headless test should check it: drift 1 with 5 Sprouts placed beside
the route leaks nothing.

All the levers are data (global multipliers), so any that overshoot can be loosened quickly. Next
playtest: note the drift where it first gets hard, and how many leaves were left at each boss.

## Rewards

### Dreams: every 5 drifts

**19 Dreams per run**: after drifts 5, 10, 15, … 95. Pick 1 of 3 (`dream_design.md`). Dreams no
longer unlock base Wardens; they give stats, branches, final forms and rules.

### Warden families: at the start and from bosses

| When | Reward |
|---|---|
| After drift 1 | **Pick your first family**: 1 of 3, drawn at random from **all families you've unlocked** (incl. Grove unlocks), **+1 Dreamlight** |
| Boss at 25, 50, 75 | **Pick a new family**: 1 of 3 base Wardens you don't have yet, **+3 Dreamlight**, **plus** a Dream that's guaranteed Rare or better |
| Boss at 100 | the win |

That's **4 Warden families per run** (out of 7, or 9 in the full game), so every run leans a
different way. The run starts
with only Sprout + Thornwall. **Act 1 is about one family**: you deepen it through its branches
before a second family arrives at drift 25. When fewer than 3 new families are available (early
in the meta, before the Grove unlocks Pebbling, Rootling and Acorn), empty slots become **Family
Blessings** for a family you own (`meta_design.md`).

### Dreamlight: choosing your build paths

Added 2026-09-27 (user decision): a second in-run currency so build paths come from **choice, not
card luck**. Dispelling a great nightmare frees the light it stole from the dream.

| Source | Dreamlight |
|---|---|
| First family pick (after drift 1) | **2** (was 1; 2026-09-30: branches now come free, so this buys your first final form in act 1) |
| Each boss (drifts 25, 50, 75) | **4** (was 3, 2026-09-29: runs earned only 3–6 Dreamlight, so no run ever reached an Ascended form) |
| Dream cards (Sudden Insight, Borrowed Memory) | +1 / +2 |
| Grove perk *Early Light* | +1 at run start |
| Every rest from drift 51 (2026-09-29) | **+1** (the Heartwood wakes: no run had ever reached an Ascended form) |

**Spending (per run, like the old unlock cards):**

| Unlock | Cost |
|---|---|
| A **branch** of a family you own (Stormcap, Rain Lily, Driftspore, …) | **free**: comes with the family (2026-09-30) |
| A **final form** of a family you own | **2** |
| A **hidden branch** (only if the Grove has unlocked it) | **1** |
| A **wall growth** (Bramble, Honeysuckle) | **1** |

- About **10 Dreamlight per run** against 4 families × (2 branches + 2 finals) = 24 possible: you
  can't have everything, so each run is a set of real choices. Unspent Dreamlight carries over.
- **A family comes with its base and both branches** (user, 2026-09-30: *"if you unlock a family,
  the first and 2nd forms are unlocked with it, or what else am I going to do with these Dreamlight
  if I just started"*). Picking a family unlocks its base Warden and its two regular branches at once
  (growing each Warden still costs Dew). **Dreamlight is for what comes after:** final forms (2),
  hidden branches (1, Grove), wall growths (1) and Ascended forms (3, Grove). A new player's first
  Dreamlight therefore always has a use: the first pick's 2 buys a final form of that family.
  - **Budget now:** ~2 + 12 (bosses) + ~9 (rests from 51) ≈ **23 per run**, against 4 families ×
    2 finals × 2 = 16, plus hidden branches, walls and Ascended forms (3 each): still more to want
    than you can have.
  - **Watch in the balance sim:** Kinships (need both branches) and final forms both arrive earlier.
    Evolving still costs Dew (branch +45, final +90), which is the real gate in act 1.
- **Where:** a **Remember** screen (a branching tree per owned family) opens right after each boss's
  family pick, and can be reopened at any rest from the rest panel. The Warden panel's disabled
  "Grow into Stormcap" button says *"Unlock with 1 Dreamlight"* and opens it.
- Unlocking makes the form available; **evolving each Warden still costs Dew**, as before.

**The Remember screen, fleshed out** (2026-09-28, user: "flesh it out more and have it on the top
right; the family tree should include the portraits"):
- **Opened from the top right:** a **Remember** button right beside the Dreamlight counter
  (Dreamlight mote + count), always visible, not only at rests (during a drift it opens paused).
  It glows softly when Dreamlight can buy something, and at the rest after each boss it opens
  itself after the family pick, as now. The old DriftPanel button goes.
- **One tab per owned family** (its base Warden's portrait on the tab), plus a **Thornwall** tab for
  the wall growths. Each tab is a real **tree drawn with portraits**: the base Warden at the root,
  lines up to its two branches, each branch to its final form, the hidden branch and its final in
  a third lane (silhouette until the Grove plants it), and the **Ascended** form at the crown (from
  drift 51). Each node shows the Warden's **idle-animated portrait** on its waystone.
- **Node states**, readable at a glance: **grown on your map** (full colour, a small count "×3"),
  **unlocked** (full colour, no count), **can unlock** (full colour, dimmed, with the Dreamlight
  cost as motes and a soft pulse), **locked** (needs its branch first: dim, with a thin chain to
  the parent), **Memory Grove** (a silhouette with a Grove leaf: not in this profile yet).
- **Selecting a node** opens a side panel: portrait, name, tier, **damage type** icon, what it does
  (the Warden's description with status links), its main stats (damage, speed, range, statuses,
  potency), the **Dew to grow** into it from its parent, its Kinship partner if any ("Kin: Chime
  Stone · Night Chimes"), the combos it's part of (links to the Codex), and the **Unlock (2 ✦)**
  button. Unlocking plays a small bloom along the tree line.
- **Playtest fixes (2026-09-30**, user screenshot of the Firefly tab at drift 1: *"the locked is too
  dark and still shows the 2nd tree line; I started a new run and the Ascended Warden is there"*):
  - **Locked nodes are readable:** the portrait at ~75% brightness with a light desaturation, not
    near-black; "Locked" stays as the caption. Only Memory Grove nodes are silhouettes.
  - **A lane the Grove hasn't planted shows only its branch**, as the Grove silhouette. Its final
    form and the line up to it are **hidden** (no Midsummer above an unplanted Sunpetal). The side
    panel for that silhouette says only "Plant it in the Memory Grove".
  - **Grove forms readable too** (same day, user: *"locked Grove is still too dark"*: a pure black
    silhouette): a Memory Grove form shows its portrait **desaturated at ~45% brightness with a cold
    moonlight tint and a pale rim**, a small Grove leaf badge, and **its name** under it; the side
    panel shows the same portrait, the name, one line on what it does, and "Plant it in the Memory
    Grove". Readable, but clearly not yours yet (the dimmest node state; locked nodes stay at 75%).
  - **The Ascended crown is hidden** until it can be unlocked this run: its Grove node planted **and**
    drift 51 reached. Before that there is no node and no line to it. From drift 51 it appears
    (the "can unlock" state once a final form of the family is grown).
- A header line: *"Dreamlight 3 ✦ · unspent carries over"* and a one-line reminder: *"Dreamlight
  unlocks, Dew grows."*
- Touch: tabs and nodes are 48 px+, the side panel slides up from the bottom on phones.
- **Dreams** no longer unlock evolutions (`dream_design.md`); they're stats, rules, combos and
  economy. The Rare-or-better boss Dream stays.
- **Test Grove:** everything unlocked, as now. **Demo:** same rules.
- HUD: a Dreamlight counter next to Dew (a small glowing mote icon).

### Omens: choose the next block's twist

Added 2026-09-27. Aimed at "does the middle of the run stay interesting?". **At every rest from
drift 10 on**, after the Dream, the wind brings **2 Omens**. Pick one to change the next block
(5 drifts) for a reward, or keep **Clear Skies** (the default: nothing changes). This is optional
risk: players set their own difficulty block by block.

- **How an Omen looks** (user, 2026-09-30):
  - **Icon: a moth before the moon.** A dark moth silhouette crossing a pale full moon (moths are old
    folk omens; it reads at small size). It replaces the placeholder wind swirl on the Face an Omen
    card and is the Omen icon everywhere (active-Omen tag, run history, Codex). **Clear Skies** gets
    the matching calm icon: **the moon alone, with a few stars**, so the two cards balance. Both are
    16×16 pixel art appended to the end of the UI icon sheet (`assets/ui/icons.png` via `tools/ui_icon_generator.gd`, ids `omen` and `clear_skies`, Heartwood 32 palette: Moonlight moon, Gold / Glow rim light),
    shown at whole-number scales (×2 in tags, ×3 on the cards, nearest).
  - **Card text is bigger:** the body lines on both front cards use the card body size (as on Dream
    cards, ~18 px, not 15), same face and spot on both.
  - **Omen mist:** facing an Omen brings **mist onto the map** for that block. It rolls in when the
    Omen is picked (over ~3 s), stays for the block's 5 drifts, and **lifts at the next rest** (when
    the reward is paid). Low, drifting mist, heaviest at the map's edges and the forest's edge
    (start), thin over the path; a faint cool tint (Omen gold-violet, not grey). **Readability first:**
    it sits under Wardens, nightmares, health bars and the build ghost, never hides the path, and is
    lighter with *reduced motion* (static, no drift). Clear Skies: no mist; the sky above the island
    stays clear. The same mist marks an active Omen in a resumed save.
- **Commit blind, then the Omen is revealed** (2026-09-30, user: "we should be asking if we want Clear
  Skies or an Omen, so the player locks in the Omen before seeing what it is; make the Omens a bit
  more punishing; I feel like I can Omen every rest"). Replaces the "pick 1 of 2 Omens or Clear
  Skies" screen:
  1. After the Dream, a centred screen in the Dream layout with **two cards**: **Face an Omen** (a
     face-down card, the wind swirling over it: *"An unknown twist for the next block. Survive it
     for a reward."*) and **Clear Skies** (*"Nothing changes. No reward."*, the default; Esc /
     right-click pick it).
  2. Choosing **Face an Omen** commits you (no going back to Clear Skies), then **reveals 2 Omens**
     (valid now, never the previous rest's) and you **pick 1**: name, what changes, the reward in
     gold. (Revised 2026-09-30, user via Meta Game Discussion: "you either choose Face an Omen or
     Clear Skies, then if you face an Omen, you have two Omens to pick from"; this replaces the
     single blind draw.) The Grove perk **Omen Reader** shows **3** to pick from (`meta_design.md`).
  - **Harsher Omens:** every Omen's downside stays about **1.5× its old strength** (e.g. Crowded
    Paths 45% more nightmares, Blood Moon 35% faster), as the user wanted Omens more punishing.
    Rewards stay **×1.5** of the old values (user, 2026-09-30: "1.5 for now"; ×1.25 was proposed for
    the pick-of-2 flow and can be revisited after playtests). Double-edged Omens
    keep their sharper downside.
  - The goal: facing an Omen is a real gamble you take when your maze is strong, not something you
    do every rest. Target: a Balanced player facing an Omen every rest should lose clearly more
    leaves than one who picks their moments.
  - Setting (Gameplay): **Omens: Ask each rest / Never** stays. Blight Levels that force an Omen
    skip step 1 and reveal it directly (*"An Omen must be faced"*).
  - Omen emblems are still on hold (user, 2026-09-29); the face-down card uses the wind swirl.
- An Omen affects only the **next block**. Bosses themselves ignore Omens (their escorts don't).
- Rewards are paid at the rest **after** the block, and only if the Heartwood is still standing.
  Losing leaves doesn't cancel the reward.
- Offers only include Omens that make sense (e.g. no flyer Omen before flyers exist).
- Omen rewards scale with the act (×1 / ×1.5 / ×2 / ×2.5 for Dew and Seeds).

| Omen | The next block | Reward |
|---|---|---|
| **Moth Night** | +40% flying creatures | next Dream: one card is Rare+ |
| **Thick Blight** | creatures +20% health | next Dream offers 4 cards |
| **Crowded Paths** | +30% creatures per drift | +40 Dew |
| **Hard Bark** | blight coats +50% | next Dream: one card is Rare+ |
| **Swift Stream** | creatures +15% speed | +3 Seeds |
| **Dry Spell** | creatures give no Dew | rest bonus ×2 |
| **Stubborn Blight** | status durations halved | regrow 2 leaves |
| **Restless Wind** | drifts arrive 30% closer together | +1 max leaf |

**More Omens (2026-09-28, user: "we need more omens").** With ~18 Omen rests and 2 per rest, 8 Omens
repeated constantly, and all 8 were "nightmares get stronger for a reward". The new ones add three
other kinds: **weaken your side**, **double-edged** (the twist itself helps some builds) and **change
the map or the rules**. That makes ~20; aim for no Omen twice in a row and each kind showing up.

| Omen | Kind | The next block | Reward |
|---|---|---|---|
| **Fog Bank** | your side | every Warden **−1 range** (min 1) | +4 Seeds |
| **Wilting** | your side | every Warden **−15% attack speed** | +1 Dreamlight |
| **Frozen Ground** | your side | **no planting or growing during drifts** (rests only) | +50 Dew |
| **Leaf Fall** | your side | every leak costs **double leaves** | +2 max leaves |
| **Lean Season** | your side | **rest bonus halved** at the end of the block | next Dream **includes a Legendary** (act 2+) |
| **Heavy Rain** | double-edged | every nightmare is **always Soaked**, but has **+35% health** | +30 Dew |
| **Blood Moon** | double-edged | nightmares **+25% speed**, and give **+50% Dew** | (the Dew is the reward) |
| **Bountiful Night** | double-edged | nightmares **+25% health**, and give **×2 Dew** | (the Dew is the reward) |
| **Elder Night** | nightmares | **+1 elite** in every drift (act 2+) | +1 Dreamlight |
| **Hollow Wind** | nightmares | the block's **first 2 drifts are all flyers** (act 2+, flyers exist) | next Dream: one card is Rare+ |
| **Sleepless** | nightmares | nightmares are **immune to Drowsy and Held** | +40 Dew |
| **Shifting Ground** | the map | **3 Withered Trees sprout** on empty cells at the block's start (never blocking the route or on a Warden) | each tree you clear this run gives **+2 Seeds** instead of 1 |

- **Heavy Rain, Sleepless and Hollow Wind read your build:** they're great or awful depending on
  what you've built (Heavy Rain feeds Thunderclap and Conductive Soil; Sleepless hurts sleep builds).
  That's the point: an Omen that's free for *your* build is a reason to take it.
- **Frozen Ground** still allows selling (at the usual 50%) and clearing; it's only about planting.
- **Leaf Fall** doubles a boss's leaf cost too, but bosses ignore Omens only for their *own* stats,
  so a boss leak costs 10. Shown clearly on the Omen card.
- **Lean Season's Legendary** follows the Legendary rules (any Legendary you could be offered);
  before act 2 it isn't offered.
- **Shifting Ground:** clearing is still locked until a clearing card (the trees stay as terrain if
  you never unlock it); its trees can be cleared at normal cost. Not offered on maps with fewer than
  3 free cells that don't touch the route.
- **Offer rules:** each offer's 2 Omens are of **two different kinds**; an Omen never repeats from
  the previous rest; the reward scaling by act (×1 / ×1.5 / ×2 / ×2.5) applies to Dew and Seeds only.
- **New `OmenData` fields:** Warden range add / attack-speed multiplier, `no_build_during_drift`,
  leak multiplier, rest-bonus multiplier below 1, status immunities, always-applied status, extra
  elites per drift, all-flyer drift count, obstacles to sprout, per-tree Seed bonus; rewards
  `dreamlight`, `dream_legendary`. Blood Moon and Bountiful Night have no separate reward (their Dew is it); **Heavy Rain keeps +30 Dew**, because its +35% health hurts every build while the Soaked only helps some.

- **Blight Levels** can make Omens harsher or remove Clear Skies ("an Omen is always chosen").
- **Grove perks** later: a third Omen option, or Omen rewards +25% (`meta_design.md`).
- **Data:** `OmenData` resource: `display_name`, `description`, `min_drift`, `requires` (e.g.
  flyers), next-block multipliers (health, speed, count, coat, flyer share, creature Dew, status
  duration, arrival spacing) and a reward (Dew, Seeds, leaves, max leaves, Dream min rarity, Dream
  extra cards, rest-bonus multiplier). `DriftDirector` applies the multipliers to the next block.
- **To check:** is one more choice per rest too much? If it is, offer Omens only every other rest.

## Build rules

- **Anything, any time:** build, evolve, sell and (once unlocked by a clearing card) tend obstacles
  during drifts and rests. The path
  rule always applies: no placement may leave any creature (or the start) without a route.
- **Speed:** Pause / 1× / 2× / 3× + hotkeys (Space = pause). Pausing is a normal way to plan.

### No maze juggling (2026-09-28)

The exploit: during a drift, flip the route back and forth (plant a wall, sell it, plant another)
so nightmares keep turning around and never arrive. Refunds don't stop it (a Thornwall flip costs a
few Dew). Two rules make it a losing trade while leaving ordinary mid-drift re-mazing alone:

1. **Restless nightmares.** When a route change makes a nightmare **turn back** (its next step is
   the tile it just came from), it gains **1 Restless**: **+20% speed** for the rest of its life,
   stacking. At **3 Restless** it becomes **Unbound**: it stops listening to the maze, keeps its
   current route and **tramples** any Warden planted on it afterwards (the wall is destroyed, like
   the Hollow Stag's trample; no refund).
   - A single re-maze that turns a crowd around gives each of them only 1 stack, so honest
     adjustments cost a little speed, never a Warden. Juggling the same nightmares is what triggers it.
   - Flyers ignore the maze anyway; bosses gain Restless but never become Unbound (their own rules
     cover them). **Nothing stops an Unbound nightmare's trample** (not Weathered Walls), and the
     Hollow Oak never plants a sapling on an Unbound route: it no longer re-routes, so a wall that
     held would trap it (as built, Enemy Code 2026-09-28). Restless doesn't count as a status (can't be cleansed, no Reactions).
   - **Readable:** Restless shows as small backward-arrow marks over the nightmare (one per stack);
     Unbound glows red-hot with a trail. The nightmare info explains both; the first Unbound ever
     triggers a whisper: *"Turn them too often, and they stop listening."*
2. **Settling ground.** During a drift, a cell where a Warden was just **sold** can't be planted
   again for **8 seconds** (a settling ring with a countdown on the tile). It stops
   sell-and-replant toggling on the same cell. Rests are exempt.

Not added: a delay before new walls block, and higher mid-drift costs (both would also punish
honest play). If juggling still pays after this, raise the speed per stack first.

## Selling

- Refund is based on **all Dew invested** in that Warden (build + evolutions).
- **During a rest: 75%** (was 100%; difficulty pass v1). Rearranging still pays, but mistakes
  cost something.
- **Placed this rest: 100%** (user, 2026-09-28: "if you just placed it incorrectly"). A Warden
  planted (or grown / nurtured) during the **current** rest refunds everything spent on it this
  rest in full, until Start is pressed. Once it has stood through a drift, the 75% applies. The
  Sell button says which: "+40 Dew (placed this rest: full refund)". Not during drifts (that would
  make juggling free).
- **While creatures are walking: 50%.**
- Dreams are unlocks, not refunded. Obstacle clears are permanent and never refunded.

## Economy (Dew)

### Income

| Source | Amount |
|---|---|
| Starting Dew | 60 |
| Shade | 3 (≈3 per 100 base health; other nightmares follow the same ratio) |
| Rest bonus (every 5 drifts) | 20 + 10 × block number (30 after drift 5, 220 after drift 100) |
| Perfect block (no leaf lost) | +10 |
| Boss | 40 / 60 / 80 / 100 by act |

Creature Dew does **not** scale with the per-drift health increase; more creatures come instead.

### Costs

| Thing | Cost | Notes |
|---|---|---|
| Thornwall | 3 | Bramble growth: +10 |
| Sprout | 10 | |
| Sprout → base Warden | 15–20 | = building the base directly (25–30, current values) |
| Base → branch | 45 | branch unlocked with **1 Dreamlight** |
| Branch → final form | 90 | final form unlocked with **2 Dreamlight** |
| Tend a Withered Tree / move a Mossy Boulder | 5 / 8 | needs a clearing Dream first |
| Nurture a Warden (rank I → V) | 15 / 25 / 40 / 60 / 90 | 230 for rank V; see `warden_stats.md` |

### Target curve (use this to tune)

| After drift | Roughly |
|---|---|
| 5 | 6–8 Sprouts/Wardens, a few walls |
| 25 (boss) | ~14 Wardens, first branches |
| 50 | ~24 Wardens, 2 families evolved to branches |
| 75 | ~32 Wardens, first final forms |
| 100 | ~40 Wardens, several final forms |

Measure real Dew totals at each boss in playtests and compare.

## Creature scaling

- **Health × 1.045 per drift** (difficulty pass v1; drift 100 ≈ ×78 of drift 1), speed unchanged.
  Was ×1.035; the original ×1.12 would reach ×75,000 by drift 100.
- Difficulty also rises through **composition**: more creatures per drift, tougher types, maze
  testers from act 2, status testers from act 3, mixed everything in act 4.
- **Variety matters over 100 drifts**: every block should feel different (a new creature, a
  "special drift" like a Haunting of Phantoms or a Funeral of Processions, or a mini-boss). Needs a bigger creature
  roster than 15 drifts did (`enemy_design.md`).
- Bosses have fixed health per act (base 3,000 / 8,000 / 16,000 / 30,000, **× 1.5** from difficulty
  pass v1; tune).

## Act 1 plan (first playable)

Nightmares: Shade, Husk, Mourner, **the Hollow Stag** (stats in `enemy_design.md`).

| Block | Drifts | Contents |
|---|---|---|
| 1 | 1–5 | Shades only, 8 → 16 per drift. First Warden pick after drift 1 |
| 2 | 6–10 | **Husks introduced** (drift 6: 3 Husks alone), then mixed in |
| 3 | 11–15 | bigger mixed drifts; drift 15 is a Swarm (35 fast Shades) |
| 4 | 16–20 | **Mourners introduced** (drift 16: 4 alone), then mixed in |
| 5 | 21–25 | everything mixed, growing; **drift 25: the Hollow Stag** with an escort |

Exact counts per drift: `acts_1_2.md`.

## Obstacles: why clear them?

**Clearing starts locked**: obstacles are fixed terrain until the player takes a clearing Dream
card, which unlocks clearing for the rest of the run. The map you're dealt matters more, and
clearing becomes a choice you commit to.

**Each cleared obstacle adds +1 Seed to the run's end payout** ("the forest remembers you tended
it"): a trade-off between in-run power and long-term progress. Shown on the results screen
("Tended: 14 → +14 Seeds").

Named to fit the fiction: **Withered Tree** ("Tend") and **Mossy Boulder** ("Move"), later
**Blight Bramble**.

## To check in playtests

- Run length: ~100 min at 1×? Does the middle of the run (drifts 30–70) stay interesting?
- Leaves: are 15 (+1 per act break) right over 100 drifts?
- Dew curve vs the target table; health scaling (×1.035) vs player power.
- Do overlapping drifts feel good, or do players prefer Auto-drift off?
