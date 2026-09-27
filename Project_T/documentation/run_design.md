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
| Selling | Full refund during a **rest**, half while creatures are walking |
| Speed controls | **Pause, 1×, 2×, 3×.** Building works while paused |
| Obstacle payoff | **+1 Seed per cleared obstacle** at run end; Withered Tree / Mossy Boulder |
| Call early | **Yes**, small Dew bonus |
| Final boss | **Always The Hollow Oak** (drift 100) |

## Run structure

**100 drifts in 4 acts of 25.** One map for the whole run, so the maze keeps paying off.

| Act | Drifts | Feel | Boss |
|---|---|---|---|
| 1. Forest's Edge | 1–25 | learn the maze, first Wardens | **The Hollow Stag** (25) |
| 2. Deep Wood | 26–50 | maze testers arrive, builds take shape | **The Mire Hag** or **The Moth Queen** (50) |
| 3. Misty Hollow | 51–75 | status testers, bigger drifts | the other of the two (75) |
| 4. Heartwood Glade | 76–100 | full builds, everything mixed | **The Hollow Oak** (100, story climax) |

- **Win:** dispel The Hollow Oak and every nightmare still in the dream.
- **Between acts:** the season changes (spring dusk → summer night → autumn fog → winter dark;
  `art_direction.md`), the Heartwood regrows 3 leaves (up to its
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
  reward) appears, and you can rebuild at full refund. Press **Start** when ready. No timer.
- **Call early:** starting the next drift before the previous one has finished arriving gives
  +1 Dew per 2 seconds skipped (capped per drift).

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

- **Start with 20.** A normal creature costs 1 leaf; big ones (`EnemyData.leaf_cost`) cost 2;
  bosses cost 5.
- Regrow 3 at each act break. Perks and Dreams can raise the maximum.
- 0 leaves = the Heartwood goes dormant, run over (Seeds are still earned).
- **Tune in playtests**: over 100 drifts, 20 leaves may be too few or too many.

## Rewards

### Dreams: every 5 drifts

**19 Dreams per run**: after drifts 5, 10, 15, … 95. Pick 1 of 3 (`dream_design.md`). Dreams no
longer unlock base Wardens; they give stats, branches, final forms and rules.

### Warden families: at the start and from bosses

| When | Reward |
|---|---|
| After drift 1 | **Pick your first family**: 1 of 3 base Wardens |
| Boss at 25, 50, 75 | **Pick a new family**: 1 of 3 base Wardens you don't have yet, **plus** a Dream that's guaranteed Rare or better |
| Boss at 100 | the win |

That's **4 of the 6 Warden families per run**, so every run leans a different way. The run starts
with only Sprout + Thornwall. **Act 1 is about one family**: you deepen it through its branches
before a second family arrives at drift 25. When fewer than 3 new families are available (early
in the meta, before the Grove unlocks Pebbling, Rootling and Acorn), empty slots become **Family
Blessings** for a family you own (`meta_design.md`).

### Omens: choose the next block's twist

Added 2026-09-27. Aimed at "does the middle of the run stay interesting?". **At every rest from
drift 10 on**, after the Dream, the wind brings **2 Omens**. Pick one to change the next block
(5 drifts) for a reward, or keep **Clear Skies** (the default: nothing changes). This is optional
risk: players set their own difficulty block by block.

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

- **Blight Levels** can make Omens harsher or remove Clear Skies ("an Omen is always chosen").
- **Grove perks** later: a third Omen option, or Omen rewards +25% (`meta_design.md`).
- **Data:** `OmenData` resource: `display_name`, `description`, `min_drift`, `requires` (e.g.
  flyers), next-block multipliers (health, speed, count, coat, flyer share, creature Dew, status
  duration, arrival spacing) and a reward (Dew, Seeds, leaves, max leaves, Dream min rarity, Dream
  extra cards, rest-bonus multiplier). `DriftDirector` applies the multipliers to the next block.
- **To check:** is one more choice per rest too much? If it is, offer Omens only every other rest.

## Build rules

- **Anything, any time:** build, evolve, sell and tend obstacles during drifts and rests. The path
  rule always applies: no placement may leave any creature (or the start) without a route.
- **Speed:** Pause / 1× / 2× / 3× + hotkeys (Space = pause). Pausing is a normal way to plan.

## Selling

- Refund is based on **all Dew invested** in that Warden (build + evolutions).
- **During a rest: 100%.** Rearranging the forest between blocks is free; that's a feature.
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
| Base → branch | 45 | needs the branch Dream |
| Branch → final form | 90 | needs the Rare Dream for that branch |
| Tend a Withered Tree / move a Mossy Boulder | 5 / 8 | |

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

- **Health × 1.035 per drift** (drift 100 ≈ ×30 of drift 1), speed unchanged. The old ×1.12 per
  drift would reach ×75,000 by drift 100.
- Difficulty also rises through **composition**: more creatures per drift, tougher types, maze
  testers from act 2, status testers from act 3, mixed everything in act 4.
- **Variety matters over 100 drifts**: every block should feel different (a new creature, a
  "special drift" like a Haunting of Phantoms or a Funeral of Processions, or a mini-boss). Needs a bigger creature
  roster than 15 drifts did (`enemy_design.md`).
- Bosses have fixed health per act (start at 3,000 / 8,000 / 16,000 / 30,000; tune).

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

**Each cleared obstacle adds +1 Seed to the run's end payout** ("the forest remembers you tended
it"): a trade-off between in-run power and long-term progress. Shown on the results screen
("Tended: 14 → +14 Seeds").

Named to fit the fiction: **Withered Tree** ("Tend") and **Mossy Boulder** ("Move"), later
**Blight Bramble**.

## To check in playtests

- Run length: ~100 min at 1×? Does the middle of the run (drifts 30–70) stay interesting?
- Leaves: are 20 (+3 per act break) right over 100 drifts?
- Dew curve vs the target table; health scaling (×1.035) vs player power.
- Do overlapping drifts feel good, or do players prefer Auto-drift off?
