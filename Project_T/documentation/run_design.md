# Run Design: pacing, rules and economy

Phase 1 of `design_plan.md`. Decided 2026-09-27. This replaces the "10 drifts per run" prototype
target in `game_design.md`. All numbers are starting points for playtesting; they live in data
(`RunState` exports, `TowerData`, `EnemyData`, `DriftData`), so tuning never needs code changes.

## Decisions

| Question | Decision |
|---|---|
| Run length | **30–45 minutes** |
| Building during drifts | **Allowed** (build, evolve, sell and clear at any time) |
| Selling | **Allowed.** Full refund in the build phase, half during a drift |
| Speed controls | **Pause, 1×, 2×, 3×.** Building works while paused |
| Obstacle payoff | **+1 Seed per cleared obstacle** at run end; renamed Withered Tree / Mossy Boulder |
| Call early | **Yes**, small Dew bonus |
| Leaves | 20, +3 per act break; **tune by playtesting** |
| Act 3 boss | **Always The Hollow Oak** (story beat) |

## Run structure

**15 drifts in 3 acts of 5. The 5th drift of each act is a boss.** One map for the whole run, so
the maze you build keeps paying off.

| Act | Drifts | Feel | Boss (drift 5 / 10 / 15) |
|---|---|---|---|
| 1. Forest's Edge | 1–5 | learn the maze, first Wardens | Old Stag |
| 2. Deep Wood | 6–10 | maze testers arrive, builds take shape | Great Toad *or* Mother Moth (random) |
| 3. Heartwood Glade | 11–15 | status testers, full builds | The Hollow Oak (always: the run's story climax) |

- **Win:** cleanse the act 3 boss and everything still walking.
- **Between acts:** the season changes (spring → summer → autumn, visual only), the Heartwood
  regrows 3 leaves (up to its maximum), and you get a boss Dream.
- **No endless mode for v1.** Blight Levels are the replay hook; endless can come after launch.

### Time budget

A creature walks about 1.6 cells per second. Starting routes are about 130 cells; built mazes
reach 200–300.

| | Drift length at 1× | Build phase |
|---|---|---|
| Act 1 | 1–1.5 min | player-paced, ~20–30 s |
| Act 2 | ~2 min | ~20–30 s |
| Act 3 | 2.5–3 min | ~20–30 s |

Total ≈ 35–45 min at 1×, less with 2×/3×. **If playtests run long, speed up creatures before
cutting drifts.**

## Leaves (lives)

- **Start with 20.** A normal creature costs 1 leaf; big ones (marked in `EnemyData.leaf_cost`)
  cost 2; bosses cost 5.
- Regrow 3 at each act break. Perks and Dreams can raise the maximum.
- 0 leaves = the Heartwood goes dormant, run over (Seeds are still earned).

## Dreams (when they happen)

**8 Dreams per run:** after drifts 1, 3, **5★**, 7, 9, **10★**, 12 and 14.

- Drift 1: guaranteed "pick 1 of 3 base Wardens" (the run starts with only Sprout + Thornwall).
- ★ Boss Dreams guarantee at least one Rare or better.
- No Dream after drift 15; the run is won.

## Build-phase and drift rules

- **Build phase:** starts when a drift is fully cleansed or through. No timer; press
  **Start Drift** when ready.
- **During a drift** you can build, evolve, sell and clear obstacles. The path rule still applies:
  no placement may leave any creature (or the start) without a route.
- **Speed:** Pause / 1× / 2× / 3× buttons + hotkeys (Space = pause). Pausing is a normal way to
  plan, not a penalty.
- **Call early:** once a drift has finished arriving, the next one can be
  started early for +1 Dew per 2 seconds skipped (capped at the drift-clear bonus). This rewards
  confident players without pressuring anyone.

## Selling

- Refund is based on **all Dew invested** in that Warden (build + evolutions).
- **Build phase: 100%.** Rearranging the forest between drifts is free; that's a feature.
- **During a drift: 50%.** Emergency re-mazing has a cost.
- Dreams are unlocks, not refunded. Obstacle clears are permanent and never refunded.
- Selling only ever opens paths, so it's always allowed; creatures re-route immediately.

## Economy (Dew)

### Income

| Source | Amount |
|---|---|
| Starting Dew | 60 |
| Leaf Bug | 3 (≈3 per 100 base health; other creatures follow the same ratio) |
| Drift-clear bonus | 15 + 5 × drift number (20 after drift 1, 90 after drift 15) |
| Perfect drift (no leaf lost) | +5 |
| Boss | 40 / 60 / 80 by act |

Creature Dew does **not** scale with the per-drift health increase; more creatures come instead.
This keeps late-game income from exploding.

### Costs

| Thing | Cost | Notes |
|---|---|---|
| Thornwall | 3 | Bramble growth: +10 |
| Sprout | 10 | |
| Sprout → base Warden | 15–20 | so Sprout + evolve = building the base directly (25–30, current values) |
| Base → branch | 45 | needs the branch Dream |
| Branch → final form | 90 | needs the Rare Dream for that branch |
| Clear a tree / rock | 5 / 8 | current values |

### Target curve (use this to tune)

| After drift | Total Dew earned (incl. start) | Roughly |
|---|---|---|
| 1 | ~110 | 5–6 Sprouts, a few walls |
| 3 | ~270 | 8–10 Wardens, first base evolutions |
| 5 (boss) | ~560 | 12–14 Wardens, first branch |
| 10 | ~1,700 | ~20 Wardens, 3–4 branches |
| 15 | ~3,500 | ~28 Wardens, 1–2 final forms |

If players are well above these numbers, drifts are too easy (or Dew too generous); well below,
too hard.

## Creature scaling

- **Health × 1.12 per drift** (drift 15 ≈ ×4.9 of drift 1), speed unchanged.
- Difficulty also rises through **composition**: more creatures, tougher types, maze testers.
- Bosses have fixed health per act (tune in playtests; start at Old Stag 3,000 / 7,000 / 14,000).

## Act 1 drifts (first playable)

Creatures for act 1: Leaf Bug, Bark Beetle, Puffcap. (Proposed stats for the new ones: Bark Beetle
300 health, ~0.9 cells/s, 8 Dew; Puffcap 150 health, splits into 3 × 30-health Puffcaplets,
4 Dew + 1 each.)

| Drift | Creatures (in order) | Spacing | Notes |
|---|---|---|---|
| 1 | 10 Leaf Bug | 1.5 s | then the first Dream (base Warden) |
| 2 | 16 Leaf Bug | 1.2 s | |
| 3 | 3 Bark Beetle, then 12 Leaf Bug | 2 s / 1 s | Beetles alone first, so their trait reads |
| 4 | 4 Puffcap, then 20 Leaf Bug + 5 Bark Beetle mixed | 1.5 s / 0.8 s | Puffcaps alone first |
| 5★ | 10 Leaf Bug, then **Old Stag** | 1 s | boss knocks down one Thornwall as it passes |

Acts 2–3 follow the introduction rules in `enemy_design.md`; they get written once act 1 has been
playtested.

## Obstacles: why clear them?

Clearing costs Dew and usually *helps* the creatures (it opens shortcuts), so it needs a payoff
beyond building space.

**Each cleared obstacle adds +1 Seed to the run's end payout** ("the forest remembers you tended
it"). That gives a real trade-off: in-run power (spend Dew on Wardens) vs long-term progress (tend
the forest), without changing in-run balance. Show the running count on the results screen
("Tended: 14 → +14 Seeds").

Renamed to fit the fiction: **Withered Tree** ("Tend", was Tree) and **Mossy Boulder** ("Move",
was Rock), later **Blight Bramble**. You're healing the forest, not chopping it down.

## To check in playtests

- Leaves: are 20 (+3 per act break) too forgiving or right for a cozy game?
- Run length: 35–45 min at 1×? If long, speed creatures up before cutting drifts.
- Dew curve: compare real totals to the target table above.
