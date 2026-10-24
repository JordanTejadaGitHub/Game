# Seat S: Systems and code keeper (2026-10-24)
Read-only. Paths from D:\Projects\Game\Project_T. Nothing was run.

## 1. Verdict
**Feels good with fixes.** Drift shapes and walking lanes fit the code. The new flyers need one rule fixed before
they do: today's Groundroot and Snag turn a route flyer into a Phantom. A cross-kind flyer cap and the cover / drop
rules also have to be added. None of this is a rewrite.

**The subject is out of date:** parts 1 and 2 are **built, but nothing has been run**. Drift shapes: `scripts/run/drift_shapes.gd`
(456 lines; ae4239c6, d3ff18a9, cdd6ed4e, f952ddb7, c7bde1ee), hooked into the director and every screen (41ed52f1), with
the pack leak cap at `run_state.gd:246-251`. Walking lanes: f70e67d9, 84011a9a, 1fffbb01. Every commit says
"Parse-checked only / UNTESTED". `tests/test_drift_shapes.gd` exists but has not been run. The lead should rule on what was built, not on
the doc.

## 2. What works (keep)
- **The shape transform sits in the right place.** It re-times the schedule and keeps the first and last arrival. The
  big-pack branch (`drift_shapes.gd:39-44, 232`) keeps the 140 field cap honest. Flyers, Rolling, Leap, Burrow and
  Wander kinds ride loose between packs (`:48`), and Hollow Wind turns a Packs drift into a Stream (`omen_director.gd:138`).
- **The pack leak cap is one function.** `cap_pack_leak` (`drift_shapes.gd:88`) runs after Leaf Fall and Giants' Walk.
  Split children and followers inherit `PACK_META` (`:67-83`).
- **The guaranteed elite is seeded and never lands on a kind's intro drift** (`drift_director.gd:740-759`).
- **Lanes are visual only, as approved.** The node stays on the centre line. Only the drawn body is offset, through
  `get_body_position` / `get_visual_position` (`enemy.gd:1925-1980`). The HUD root moves via RenderingServer, and a
  snap threshold skips tiny moves. The settings read is cached (`fx.gd:175-180`).
- **The jostle only compares nightmares on the same or the next cell, every 2 frames** (`enemy_spawner.gd:318-357`).
- **Route flyers already exist.** `EnemyData.flies_along_route` (`enemy_data.gd:78-80`) is used by the Crow and the Moth
  Queen. The spawner keeps such a flyer on its route (`enemy_spawner.gd:137`) and never re-routes flyers when walls
  change (`:369`). **The Night Kite is data only:** one `.tres` like `crow.tres` with `intro_drift = 41`.
- **The Pall's half damage has a ready slot.** `take_damage` already multiplies by the Huntsman's
  `get_pack_multiplier()` (`enemy.gd:3114`, function at `:2885`). A `get_cover_multiplier()` beside it reaches every
  damage source: hits, Poisoned ticks, Reactions and Calling outputs.
- **The intro drifts are free.** No enemy uses `intro_drift` 41, 69 or 92 yet. `DriftRoller.is_rollable` (`:91-97`)
  will make them fixed automatically.

## 3. Problems, ranked

**P1. Groundroot and Snag turn a route flyer into a Phantom.** (Enemy Code)
- *Player feels:* the doc lists Groundroot as an answer to the Night Kite. Grounding a Kite instead sends it straight
  over the maze to the Heartwood. Snag, a Dream card, becomes a trap against every route flyer.
- *Cause:* `Enemy.ground()` (`enemy.gd:2047-2077`) drops the flyer on the nearest cell of the *start* route and sets
  `passed_waymark = true`. Then `_rise_from_ground()` (`:2083-2088`) sets the path to `[cell, endPath]` for every flyer.
  Neither function checks `flies_along_route`. Callers: `branch_kit.gd:1210` (Groundroot) and
  `dream_batch_rules.gd:565` (Snag).
- *Fix:* when `flies_along_route` is set, rise along `map.get_path_from(cell, passed_waymark)`, so the flyer flies the
  rest of the route, not the straight line. Keep `passed_waymark` as it is, and drop on its own route point (see P4).
  About 6 lines.
- This is a live bug today for the Scarecrow's Crows. It would matter in every act 2–4 run once the Kite is in the
  roll pool.

**P2. The 6-flyer cap doesn't exist, and Hollow Wind would break it.** (Enemy Code, Roguelite Code)
- *Cause, the cap:* today the only cap is per kind. `drift_max` (`enemy_data.gd:201`) is spilled like an easing-in
  kind (`drift_roller.gd:287-289, 447-460`).
- *Fix, the cap:* add `FLYER_MAX := 6` in `_mix`, right after the per-kind caps. While the flyers total more than 6,
  trim the largest flyer count and spill its weight to known walkers (the same code as the spill). About 15 lines.
- *Free bonus:* give each new flyer `drift_max = 6`. The lead check (`drift_roller.gd:357`) then lets it lead only a
  Special drift, which is the proposal's `special` rule.
- *Cause, Hollow Wind:* `omen_director.gd:564-573` turns **every** non-boss arrival of 3 drifts into a flyer from the
  block. That gives 30+ Kites, Palls with no walker to cover, and even today a drift of Phantoms past their cap of 4.
- *Fix, Hollow Wind:* it swaps only into route flyers (`not is_through_walls()`, and never the Pall), and up to
  `FLYER_MAX × 2` at most. The rest stay walkers.
- Owner decision: does a chosen Omen get its own, higher cap?

**P3. Maze and Calling rules ignore route flyers.** (Roguelite Code; owner decision)
- *Player feels:* the doc says "every Warden along the maze that can hit flyers gets its turn". That holds for plain
  hits only. The maze cards give a Kite nothing: Passing Thread, Gauntlet, bends, Switchback and Cozy Corners.
  Keeping Time's prime is also skipped, along with the Bonfire streak and the class route index.
- *Cause:* each check returns early on `is_flying()`, written when the Phantom was the only rolled flyer. See
  `class_kit.gd:365`, `dream_batch_rules.gd:169-176, 339, 475` (its comment says "a flyer on its straight line never
  passes twice"), `dream_state.gd:958`, `keeping_time.gd:1086, 1123`, `firefly_lights.gd:1371`, `reactions.gd:867`.
- *Fix:* add `Enemy.on_route() -> bool` (a walker, or a flyer with `flies_along_route` that isn't grounded). Use it in
  the maze-shape checks only: Passing Thread, Gauntlet, bends, Switchback and Long Way Round. Ground effects keep
  `is_flying()` (puddles, mushrooms, traps, rubble), as the doc says.
- Without this fix, maze and Gauntlet builds lose up to 6 bodies a drift for no visible reason.

**P4. The Gloamwing's drop needs its own landing.** (Enemy Code)
- *Cause:* reusing `ground(INF)` brings back P1's two faults. It also searches the whole start route for the nearest
  cell (`enemy.gd:2055-2060`). Next to a parallel corridor, that can land it further along and skip a stretch of maze.
  The flyer's own route may also run under Wardens planted since it spawned, because flyers are never re-routed (`:369`).
- *Fix:* a `land()` that drops it within 1 cell, on the current route cell with the **largest** remaining distance (so
  it never gains ground). It keeps `passed_waymark`, never rises, and sets `speed` to a new `walk_speed` export (60)
  with `_speed_stale`.
- *Trigger:* in `apply_status`, right after `statuses.apply` (`enemy.gd:3193`), check Soaked (`EnemyStatuses.DAMP`)
  or Drowsy ≥ `drop_drowsy` (3).
- Rule: the drop threshold is a nightmare trait, so Brimming does **not** double it. The glossary should say so.
- Lanes need no work: once it lands, `is_flying()` is false and `get_lane_width` gives it a walker's lane (`:1932-1937`).

**P5. The Pall needs targeting and sync rules that aren't written.** (Enemy Code; owner decision on targeting)
- *Cause, targeting:* single-target Wardens shoot furthest along first (`tower.gd:4078`). A Pall sitting on its walker
  ties with it on remaining distance, and its own `_path` goes stale once the walker re-routes. Only Moonstone and
  Standing Stone have a priority button (`has_target_priority`), so "shoot the Pall first (target priority)" is not
  something most builds can do.
- *Fix, targeting:* while covering, `get_remaining_distance()` returns the walker's value minus 1 px. Default
  targeting then hits the Pall first, which reads plainly. Wardens that can't hit flyers hit the walker at half damage.
- *Fix, sync:* follow the walker's position every frame (its far-LOD frames included, `enemy.gd:651-657`). Copy its
  lane offset so the cloth sits on the drawn body. Search again on a 0.25 s timer only while uncovered, over
  `get_maze_walkers()`, skipping walkers that are covered, bosses and **Deeply Blighted**.
- *Owner decision:* a Pall over a Few and tough elite doubles 40–60% of the drift's budget. That is a spike aimed at
  the boss-capstone builds this round wants to reward.

**P6. Flyers can be guaranteed elites.** (Enemy Code; Balancing)
- *Cause:* `add_guaranteed_elite` filters out bosses and the kind on its own intro drift only (`drift_director.gd:752`).
  A Deeply Blighted Kite, Gloamwing or Pall becomes ×3 health and 2 leaves in the air. A Deeply Blighted Pall also
  covers its walker.
- *Fix:* add `trait_kind != FLYING` to that filter. Shapes' "elite last in line" still holds.

**P7. Lanes draw bodies over Wardens in 1-cell corridors.** (Enemy Code; owner Play check)
- *Cause:* `_update_lane` (`enemy.gd:1946-1980`) never reads how much room the path has beside the nightmare.
  ±0.3 cell is 19 px. Most maze corridors are one cell wide, the exact width of a body, so the sprite overlaps the wall
  Warden.
- *Fix (if Play shows it):* scale the lane by the free half cells on that side. The half grid already knows which
  half cells are open, and the path's dual-grid mask uses them. Full ±0.3 only where the path is 2 cells wide, about
  ±0.08 in a 1-cell corridor.

**P8. Small things.**
- *Roll weight* (Balancing): `get_roll_weight = cost × roll_threat` (`enemy_data.gd:357`). The proposed numbers give
  no `roll_threat`. The Phantom has 4. Suggest 2 for route flyers, and 2.5 for the Pall, since it doubles a walker's
  life.
- *Kind line is wrong for route flyers* (Main Merger / Enemy Code): it says "Flying: it skips the maze"
  (`enemy_data.gd:25`). Use two lines keyed on `is_through_walls()`, as the icon already is (`:260`).
- *Phone performance* (Enemy Code): `here + ahead` builds a new array for every nightmare on each jostle tick
  (`enemy_spawner.gd:341-343`). Loop over the two arrays instead. Profile one act 3 big-Packs drift with 140 on the
  field, as the shapes doc asks.
- *Teaching drifts* (Main Merger):
  - Drift 41 is a hand-edited demo file, inside the demo (1–50). The Kite therefore needs its art in the demo.
  - Drifts 69 and 92 need rows in `acts_3_4.md`, then a re-run of `tools/drift_generator.gd` and `--import`.

## 4. Builds and Wardens
- **Shine:**
  - Dewdrop and Bellflower control lines, through the Gloamwing's drop (Soaked or Drowsy).
  - Area builds against a Pall and its walker (one hit damages both).
  - Hit-flyer single-target Wardens, once the Pall is targeted first (P5).
- **Suffer until fixed:**
  - Groundroot and the Snag card (P1).
  - Passing Thread, Gauntlet, Switchback and Keeping Time's prime against Kites (P3).
  - Boss-capstone lines on Few and tough if a Pall may cover elites (P5).
  - Waymark against grounded flyers, which skip the stone (`enemy.gd:2075`, P1 and P4).

## 5. Open questions for the owner
1. Do route flyers count for maze cards (`on_route()`, P3), or only for plain hits?
2. Does Hollow Wind keep its all-flyer drifts above the 6-flyer cap, as a risk the player chose (P2)?
3. Can a Pall cover a Deeply Blighted (P5)? And is the Pall shot first by default?
