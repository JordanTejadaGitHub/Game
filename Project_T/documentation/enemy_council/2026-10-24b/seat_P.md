# Seat P (motion and game-feel animator), round 2026-10-24b: enemy movement

## 1. Verdict
**Feels good with fixes.** The idea works: crowds read as clumps, not beads (compare `seat_P_frames/on_burst_11.png` with `off_burst_11.png`). What looks off is three motion faults: (a) the lane ease **starts at full speed** and slides bodies sideways faster than they walk, with no turn of the body; (b) the lane's frame **snaps at the corner centre** and then catches up, which drags inner-lane walkers backwards and makes stair paths wobble; (c) ±0.3 cell is too wide for a 1-cell path, so bodies hang over the grass. All three are number or curve changes. None touches the node.

Evidence: 10–15 fps bursts from `lanes_packs_on/off.avi` (seed 4242, drift 26), crops at 11–12.4 s in `seat_P_frames/` (`on_burst_11.png`, `off_burst_11.png`, `on_corner_15fps.png`, `after_12s.png`); the Single file sheet (`frames/shapes_sheet_05.png`, staircase path). Caveat: the capture camera follows the leader, so it pans in every burst. Per-body speeds below come from the code, not from tracking pixels.

## 2. What works (keep)
- Visual-only lanes: the node, targeting and y-sort anchor stay on the line (`enemy.gd` 265–283, 1946–1982).
- The open and close ramps over the first and last cell (1970–1972) look clean: nothing pops at the start or the Heartwood.
- Shape-aware widths (Single file ±0.1, big ±0.15) are the right hierarchy. Single file still reads as a line on the sheet.
- The facing logic already ignores the lane (`update_animation(position - previous_position)`, 879/1617). That is right (Q2 below).
- `LANE_SNAP_PX` 0.25 (1975) holds the sprite still under sub-pixel noise. Keep it.
- Reduced motion uses a fixed lane. Keep.

## 3. Problems, ranked

**P1. Sideways skating: the exponential ease launches at its top speed.** *Player sees:* a Husk suddenly slides half a cell sideways while its legs walk straight ahead, like it is on ice. *Cause:* `lane = lerpf(lane, lane_target, 1 - exp(-LANE_EASE*delta))` (1961) with `LANE_EASE` 3.0 (272). An exponential ease has no ease-in: its lateral speed at t=0 is 3 × Δ. Targets are uniform in −1..1 (1960), so the mean Δ is 0.67 lane units = 12.8 px, which starts at **38 px/s**. A full swing is 38.4 px, which starts at **115 px/s**. A Husk walks 57.6 px/s and a Great Toad 38.4 px/s, so the slide can be **2–3× the forward walk** at a heading of up to 63–72°, while the sprite keeps facing forward. That is the "drift" look. *Fix:* replace the lerp with a **rate-limited smoothstep**:
- Lateral speed is capped at **0.25 × the nightmare's walk speed** (Husk 14 px/s, Shade 26 px/s). That keeps the drawn heading within **14°** of the path, below the 45° facing threshold, so it reads as a gentle diagonal walk, not a slide.
- Each move eases in and out (smoothstep) over `max(0.8 s, |Δpx| / cap)`.
- New target = current ± uniform(**0.35..0.8**) lane units, clamped to −1..1 (no full side-to-side crossings).
- `LANE_WANDER` **4–8 s** (was 3–6). With the cap, a 0.5-unit move takes about 1.2 s on a Shade and 2.1 s on a Husk, so bodies spend most of their time settled. Settled bodies read as alive; bodies always gliding read as drift.
- Jostle pushes go through the same cap.

*Owner:* Enemy Code.

**P2. Corners: the lane frame snaps at the corner centre, then lags.** *Player sees:* at a bend, inner-lane walkers stall or step backwards and outer ones fling wide. On stair paths (Single file sheet: 1-cell steps), every laned body zig-zags. *Cause:* `_lane_dir` aims at the **next cell centre** (1963–1964). It flips 90° the frame the node reaches the corner centre, and `LANE_TURN_EASE` 5 (τ = 0.2 s, 95% at 0.6 s) then rotates the side vector. For an inner walker at −0.3 cell turning left, the offset swings from (0, −19) to (−19, 0) px. At the start of that swing it moves about **134 px/s, mostly backwards**, while the node walks on. That motion is also out of step with the corner rounding: `CORNER_ROUNDING` 0.3 cell (85) curves the body from 0.3 cell **before** the centre, but the lane only starts turning **at** the centre. On a staircase at Shade speed (1.6 cells/s) the turns come every 0.6 s, so the side vector swings ±45° around the diagonal and never settles. *Fix:* measure the lane frame from a **route chord**: dir = route point **0.5 cell ahead** − route point **0.5 cell behind**, by arc length along `_path`. Drop `LANE_TURN_EASE`. On a single 90° bend the frame then turns linearly over exactly 1 cell of travel, centred on the corner, in step with the rounding. The inner body slows to about 30% through the bend without reversing, and the outer body speeds up to about 1.6×, which is how a crowd takes a corner. On a 1-cell staircase the chord holds the diagonal, so the pack walks one smooth diagonal band. *Owner:* Enemy Code.

**P3. Corner radius vs lane width makes a cusp.** With rounding 0.3 cell and lane 0.3, the inner lane's effective radius is **0**, a sharp pivot. *Fix:* `CORNER_ROUNDING` **0.4** on full-cell legs (half-steps still cap at 0.5 × leg = 0.25, line 2023). With the narrower lane in P4, the inner radius is 0.4 − 0.22 = **0.18 cell** and the outer 0.62. No cusp. *Owner:* Enemy Code.

**P4. Bodies overhang the path.** *Player sees:* in `on_burst_11.png`, bodies on the vertical leg sit on the path's outer edge with feet on the grass. *Cause:* `LANE_MAX` 0.3 (267) + body half-width about 0.25–0.3 cell = 0.55–0.6 cell from the centre, while the path's half-width is 0.5. *Fix:* `LANE_MAX` **0.22** (14 px), `LANE_BIG` **0.10**, Single file **0.06**, `LANE_FLYER` **0.12** sway. Total spread is still 0.44 cell, so packs still read as side-by-side. In a narrow half-cell gap, multiply the lane by **0 at full squeeze** (scale it by `(_squeeze - SQUEEZE_WIDTH) / (1 - SQUEEZE_WIDTH)`, fed from `_update_squeeze`). A body squeezing through a gap must be on the centre line. *Owner:* Enemy Code.

**P5. Stacked pairs and jostle.** *Player sees:* two Husks drawn on top of each other (`on_burst_11.png` frames 1 and 9). *Cause:* `JOSTLE_REACH` 0.4 cell (spawner 315) is shorter than one body length (about 0.5 cell). Pairs 0.4–0.55 cell apart along the path on the same lane overlap and never push. *Fix:* `JOSTLE_REACH` **0.6**, `JOSTLE_LANES` **0.3 cell**, `JOSTLE_PUSH` **1.5** lane units/s on the target only, delivered through P1's speed cap so the push reads as shouldering aside, never as jitter. Keep `JOSTLE_EVERY` 2. *Owner:* Enemy Code.

**P6. Animation timing at corners and foot skate.** The walk loops are 6 frames: Shade at 10 fps (0.6 s per cycle, about 61 px per stride at 102.4 px/s), Husk at 6 fps (1.0 s, about 58 px). The facing switch happens on the node's velocity, the frame it reaches the corner centre, while the drawn body is still mid-arc. With P2, the drawn speed through a bend changes 0.3–1.6×, but the legs keep cycling at 1.0×. *Fix:* (a) facing from the **lane frame direction (the chord)** with **10° hysteresis**, so the side→down switch lands at the 45° point of the arc; (b) `sprite.speed_scale` = drawn speed / node speed, clamped to **0.7–1.4** and eased at rate 8. One line per frame; it only differs from 1 on bends. Bosses and special poses (roll, gallop, sorrow) are left alone. *Owner:* Enemy Code.

**P7. Y-sort by node.** On horizontal legs, two bodies 28 px apart in drawn y share one node y. The draw order is then tree order, so the higher body sometimes draws over the lower one's face. It is visible on Packs. *Fix:* the sort key should be the drawn foot. Seat S owns how (e.g. the sprite in a y-sorted child carrying `_body_offset()`). *Owner:* Enemy Code.

## Owner's four questions
1. **What looks off:** in order: the sideways slide from the instant-start ease (P1), corners and staircases (P2/P3), the edge overhang from lane width (P4), stacked pairs (P5), y-sort (P7). Jostle jitter itself is minor once P1 caps the speed.
2. **Should the lane follow the walk facing?** No. The lane must never turn the body: cap lateral motion at 14° (P1) so it never has to. But **facing should follow the eased lane frame (the chord) instead of the raw node velocity**, so the turn animation lands mid-arc, not at the square corner (P6).
3. **Bunching and packs:** readable. Clumps are clearly side by side and Single file stays a line. They read as messy only because of overlaps (P5) and edge overhang (P4).
4. **Numbers:** `LANE_MAX` 0.3→**0.22**, `LANE_BIG` 0.15→**0.10**, Single file 0.1→**0.06**, `LANE_FLYER` 0.15→**0.12**; `LANE_WANDER` 3–6→**4–8 s**; new target **current ± 0.35–0.8**; `LANE_EASE` exp 3 → **smoothstep, lateral cap 0.25 × speed, minimum 0.8 s**; `LANE_TURN_EASE` 5 → **chord ±0.5 cell**; `CORNER_ROUNDING` 0.3→**0.4**; `JOSTLE_REACH` 0.4→**0.6**, `JOSTLE_LANES` 0.25→**0.3**, `JOSTLE_PUSH` 1.2→**1.5** (capped); lane × 0 in a full squeeze; walk `speed_scale` **0.7–1.4**; facing hysteresis **10°**.

## 4. Builds and Wardens that shine or suffer
- **Shine:** wide-area Wardens (Puffball clouds, pulses, Bellflower rings) and Firefly chains. Side-by-side clumps make "one burst hits five" visible.
- **Suffer (look only):** single-target Wardens and pecks aim at the drawn body. P1's fast slides make shots visibly curve late in flight. Capping lateral speed at 0.25 × walk speed removes that.
- **Neutral:** Single file and bosses, at their narrower lanes.

## 5. Open questions for the owner
- Do you want a small **surge along the path** (drawn ±0.08 cell, period 2–4 s, visual only) so spacing in a Stream also breathes? Without it, a Stream keeps metronome spacing even with lanes.
- Should packs **share a drift** (one lane target per pack, ±0.1 per member) so a pack swings together, or should every member keep wandering on its own (today)?
