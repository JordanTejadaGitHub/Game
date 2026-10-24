# Seat S (Systems and code keeper): round 2026-10-24b, enemy movement

Read: `scripts/enemy/enemy.gd` (lanes 264-283, `_process` 796-888, `update_animation` 1617-1640, squeeze / gap
1673-1726, `get_lane_width` / `_update_lane` 1933-1982, `_round_corners` / `_corner_curve` 1987-2032, `_body_offset`
2342-2347), `scripts/enemy/enemy_spawner.gd` 284-355 (`_jostle_lanes`), `scripts/run/drift_shapes.gd` 26-44, 136-146,
207-223, `scripts/map/path_generator.gd` 1-12, enemy_design.md "Walking lanes" (719-750).
Frames (mine, `seat_S_frames\`): `packs_on_corner_burst.png` / `packs_off_corner_burst.png` (lanes_packs_*.avi
10.5-12 s, 10 fps, corner crop at 2x), `full_12.png`, `big_14.png`, `bigpacks_burst.png` (v2_big_packs.avi 14-15 s).

## 1. Verdict
**Feels good with fixes.** Lanes as a node-stays-on-the-line, drawn-offset-only system are the right design and
cheap. What looks off is in five specific lines: the sideways ease is speed-blind (bodies slide faster sideways than
they walk), the width ignores the corridor (bodies poke past the path edge and through half-cell gaps), the lane's
"sideways" axis whips at every corner, jostle has a double-count and a corner false trigger, and y-sort is by node.

## 2. What works (keep)
- Node on the line, only `_body_offset()` moves (2346-2347): targeting, ranges, Waymark, pulls untouched.
  `get_visual_position()` = `get_body_position()` (1930), already used by Tower (`tower.gd:5455`), keeping_time
  (904), fx (418), capture_director (952).
- Lane frozen while Held / asleep / waiting / entering / leaping / dragged: `_process` returns before 888
  (817-835) and 887 skips leap/drag. No sliding statues.
- Open over the first cell, close over the last (1969-1972); reduced motion = fixed lane (1949, 1956).
- Per-shape widths through `DriftShapes._set_lane` (drift_shapes.gd 136-146), big kinds capped (1936, 1941-1942).
- Cost is small: per walker a couple of `calculate_map_position` + normalize per frame; culled walkers skip (887).

## 3. Problems, ranked

**P1. Sideways slide faster than the walk, with the walk animation unchanged.**
- Player sees: crabs/skating, most on slow kinds (the owner's "looks off").
- Cause: `lane = lerpf(lane, lane_target, 1 - exp(-LANE_EASE*delta))` (1961) with LANE_EASE 3 and a target rolled
  over the full -1..1 range (1960). Worst jump 2 lane units x 0.3 x 64 = 38.4 px; initial lateral speed
  3 x 38.4 = **115 px/s**; an average re-roll (0.67 units = 12.8 px) still starts at **38 px/s**. Walk speeds in
  `resource/enemy/*.tres`: 13 kinds at 35-57.6 px/s. A 35 px/s Husk can move sideways at 3.3x its walk.
  Facing comes from the node's step only (`update_animation(position - previous_position)`, 879; 1632-1636), so
  the side-walk frame plays during a vertical slide. Slows (Drowsy etc.) make it worse: the slide ignores
  `_speed_cache`.
- Fix (Enemy Code): cap the lateral rate by the walk. In `_update_lane`, after the exp step, clamp the change to
  `LANE_SLIDE * _speed_cache * delta / (get_lane_width() * cell)` lane units with **LANE_SLIDE = 0.35** (max crab
  angle atan 0.35 = 19 deg). Re-roll the target near the current lane: `lane_target = clamp(lane +
  randf_range(-0.7, 0.7), -1, 1)`; **LANE_WANDER 3-6 s -> 4-8 s**. Keep LANE_EASE 3 for the shape of the ease.

**P2. Lane ignores the space: bodies over the path edge and through Wardens in half-cell gaps.**
- Player sees: bodies brushing grass on 1-cell legs (corner bursts, top edge of the horizontal leg and beside the
  tree on the vertical leg; also `bigpacks_burst.png` left edge); in a half-cell gap the body is drawn over the
  wall Warden.
- Cause: route points are half-cell centres (path_generator.gd 4-9), the drawn path is about 1 cell wide around
  the line, a ~36 px body has ~18 px half-width; 19 px lane + 18 = 37 px > 32 px. A one-half gap is 32 px wide
  (16 px each side): `_update_squeeze` narrows the sprite to SQUEEZE_WIDTH 0.8 (86, 1683) but `_update_lane` never
  reads `_gap_answer`, so a ±19 px lane puts the body's centre outside the gap.
- Fix (Enemy Code): **LANE_MAX 0.3 -> 0.2** (12.8 px; edge at ~31 px, inside the path), **LANE_BIG 0.15 -> 0.1**,
  LANE_FLYER 0.15 keep, LANE_SINGLE 0.1 keep, LANE_TOUGH 0.15 -> 0.1. In a gap the lane goes to 0: a `_lane_room`
  factor eased with SQUEEZE_RATE 14 toward `0.0 if _gap_answer else 1.0`, multiplied into 1974 (the gap answer is
  already cached per step, no new search).

**P3. Corner whip: the lane axis lags the turn and double-stacks with rounding.**
- Player sees: outside-lane walkers flick out past the corner, inside-lane walkers hitch backwards (corner frames:
  bodies pile into the corner and fan out of it).
- Cause: `dir` = next route point minus the node (1964), so it snaps at the corner's centre; `_lane_dir` eases at
  LANE_TURN_EASE 5 (1967, 63% in 0.2 s). The offset rotates 90 deg about a node already walking the new leg: the
  outside body travels 19 x sqrt2 = 27 px in ~0.3 s (~90 px/s), on top of `_corner_offset`'s up-to 0.25 x r x sqrt2
  = 6.8 px (2023-2031). On half-step staircases (r = 16 px, every 32 px) the same lag makes a lateral wobble
  (predicted from code; check stair legs in v2_big_packs).
- Fix (Enemy Code), least change: take `side` from the rounded curve's tangent instead of an eased direction. In
  `_corner_curve` the tangent is `2(1-t)(corner-a) + 2t(b-corner)`; return it alongside the offset (or store
  `_corner_tangent`), and in `_update_lane` use it when `_corner_offset != ZERO`, else the leg direction. That makes
  the lane a parallel curve through the same arc, no lag, and lets LANE_TURN_EASE go. Cap the inside lane at 0.8 x r
  on a turn so it never cusps. If that's too much for now: LANE_TURN_EASE 5 -> 10 plus P2's 0.2 width halves it.

**P4. Jostle jitter.**
- Cause (a): double push. When `ahead` exists, `near = here + ahead` (343) and the same-cell "each pair once" guard
  (345) only applies when `near == here`, so same-cell pairs get pushed twice (2.4 instead of 1.2 lane units/s),
  and only for walkers whose next cell is occupied: uneven.
- (b) Corner false trigger: reach is straight-line (347). Pack members are 0.5 cell apart along the route
  (`PACK_CELLS`, drift_shapes 31, 223) = 32 px > 25.6 px reach on a straight, but 22.6 px across a corner chord,
  so every pack pair jostles at every corner, on top of P3.
- (c) Rails: pushes clamp targets to ±1 (354-355). Threshold JOSTLE_LANES 0.25 cell is absolute: span at 0.3 is
  0.6 cell, room for 3 lanes; big packs arrive `min(32/speed, 3/(n-1))` s apart (211), e.g. 13 at 45 px/s =
  11 px apart, so 3+ share the reach and get pushed to the two edges. Single file (span 0.2) is always "too
  close" when it bunches (Drowsy, speed mixes).
- Fix (Enemy Code): reach by route progress, not distance (`abs(a._path_index - b._path_index) <= 1` and a
  same-leg check), which also kills (b); fix the guard to "pair once" in both cases; threshold relative:
  push only when `abs(wa - wb) < 0.4 * (a width + b width)`; skip pairs where either width < 0.15; never push a
  target already at ±1 further, push the other one instead. JOSTLE_PUSH 1.2 keep (it is under P1's cap).

**P5. Y-sort by the node on horizontal legs.**
- Cause: on an east-west leg the lane offset is vertical, but y-sort reads the node; walkers on one leg share a y,
  so overlap order is child order (spawn order), not drawn depth. Doc already flags it (enemy_design.md 748-750).
  Visible as wrong overlaps inside packs (corner burst, bottom row frames 4-5).
- Fix: P2's 0.2 width shrinks the window from 38 to 26 px. Proper fix (Enemy Code, separate change, test first):
  `y_sort_enabled = true` on the Enemy and the lane's **y component** moved into `sprite.position.y` (x stays in
  `sprite.offset`), so the sprite sorts by its drawn feet with Wardens and other walkers. The HUD canvas item and
  `_draw` haze keep the node; check overlays' z.

**P6. Sub-pixel shimmer and update cost.**
- Cause: LANE_SNAP_PX 0.25 (274) pushes fractional offsets nearly every frame during an ease (sprite.offset,
  RenderingServer transform, and `queue_redraw` for elites/marked, 1978-1982); `default_texture_filter=0`
  (nearest) and no 2D pixel snap in project.godot, so fractional offsets crawl pixel art.
- Fix: round `_lane_offset` to whole world pixels and **LANE_SNAP_PX 0.25 -> 1.0**. Fewer pushes and no crawl.

**P7. Minor.** The close-out reads straight-line distance to the Heartwood (1972), so a maze that winds within one
cell of it narrows lanes early; use route points left (`_path.size() - _path_index <= 2`). `_jostle_lanes` allocates
a dict + arrays every 2 frames (329-343) for the whole field: fine at today's 60-100 walkers; reuse arrays if the
phone profile shows it. Lane rng uses `randi()` from the global RNG (1952): visual only, no gameplay roll depends on
it; fine under "rolled from the map seed".

## The owner's four questions (code terms)
1. **Off:** the slide speed (P1, 115 px/s peak vs 35-80 walks), the width vs the path and gaps (P2), the corner
   axis lag (P3), jostle doubling/corners/rails (P4), then y-sort (P5) and pixel crawl (P6).
2. **Follow facing?** No: keep facing from the node (879). With LANE_SLIDE 0.35 the body never moves more than
   19 deg off its walk, which a side or up/down cycle covers. Turning the animation to a lane slide would flip
   walk_up/walk_side for a few frames on every wander.
3. **Packs:** readable at the 0.5-cell spacing; big packs bunch to ~11 px and jostle pins them to two rails. With
   P4's fixes and 0.2 width a big pack reads as one clump on the path.
4. **Numbers:** LANE_MAX 0.2, LANE_BIG 0.1, LANE_TOUGH 0.1, LANE_SINGLE 0.1, LANE_FLYER 0.15; LANE_SLIDE 0.35 x walk
   speed (new); re-roll ±0.7 around the current lane; LANE_WANDER 4-8 s; LANE_EASE 3; lane x 0 in a half gap (eased at
   14); corner side from the curve tangent (else LANE_TURN_EASE 10); JOSTLE reach by route index ±1, threshold
   0.4 x summed widths, PUSH 1.2, skip widths < 0.15; LANE_SNAP_PX 1.0 with whole-pixel rounding.

## 4. Builds / Wardens
No combat change (node unchanged). Visual aim already follows the body (tower.gd 5455), so P2 (narrower lanes)
also shrinks how far beams and pecks bend to reach a body. Area visuals centred on the node (pulses, clouds,
Puddles water, mushrooms) look truer with 0.2.

## 5. Open questions for the owner
- Y-sort: accept the residual (26 px window at 0.2) or ask Enemy Code for the sprite-position y-sort change?
- Corner: the tangent rewrite (exact, small) or just LANE_TURN_EASE 10 for now?
