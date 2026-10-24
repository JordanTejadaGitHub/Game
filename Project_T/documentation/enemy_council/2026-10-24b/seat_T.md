# Seat T (tower defense veteran: maze and fairness): enemy movement, round 2026-10-24b

## 1. Verdict
**Feels good with fixes.** Packs read as packs, not beads on a string, and that is the right goal. Three things make
the movement look off. The lane is too wide for the path as drawn: bodies sit on the path's edge and half over the
grass. The sideways slide is too fast for slow walkers, so they crab-walk. Narrow gaps don't narrow the lane. All
three are numbers, not design.

What I looked at: `walking_lanes.mp4`, `lanes_packs_on/off.avi` (bursts at 12-13.5 s, crop 280x200 at 2x, 10 fps),
`v2_packs.avi` (full frame at 14 s, game zoom), `v2_big_packs.avi` (burst at 20 s), and the shapes sheets. My frames
are in `seat_T_frames\` (`burst_on_12.png`, `burst_off_12.png`, `on_12.png`, `v2packs_14.png`, `bigpacks_burst.png`).

## 2. What works (keep)
- Lanes are visual only (enemy_design.md "Walking lanes"; `get_visual_position()` = body, enemy.gd:1930). Range,
  leaks, Waymark and the route rule are untouched, so fairness doesn't change. Keep it that way.
- Packs (drift 26) now read as five clumps rather than one even line. At game zoom (`v2packs_14.png`) you can count
  the groups, and that is the point of the Packs shape.
- The lane opens over the first cell and closes over the last (enemy.gd:1969-1972). Nothing pops in or leaks
  off the edge at the Heartwood. Keep.
- The side vector comes from an eased travel direction (LANE_TURN_EASE 5). A walker on the left stays on the left
  through a bend, so it reads as one crowd swinging round. Keep.
- Reduced motion uses a fixed lane. Keep.

## 3. Problems, ranked

**P1. The lane is wider than the path as drawn: bodies walk on the edge and onto the grass.**
- *What the player sees:* in `burst_on_12.png` and `on_12.png`, several Shades sit with their lower half on the dark
  grass at the inside of the path. In `v2packs_14.png` (game zoom) the left column of walkers hangs off the sand.
  This hurts more than it looks: the light sand path is the only backdrop that makes dark, cold nightmares readable.
  Off it, they vanish into the grass. That is worse on a phone and at 1280x800.
- *Cause:* `LANE_MAX := 0.3` (enemy.gd:267). The drawn path band is about 0.55-0.6 cell wide: about 22 px per 35 px
  cell at game zoom in `v2packs_14.png`, and about 48 px per 90 px cell in the 1.4-zoom capture (the dual grid
  draws the half cells a body covers). So ±0.3 cell puts the body's **centre on the path's edge**.
- *Fix:* `LANE_MAX` 0.3 → **0.18**. That keeps the centre about 0.1 cell inside the edge, so a Shade's body stays on
  the sand.
  - `LANE_BIG` 0.15 → **0.08**.
  - Single file's `lane_width` 0.1 → **0.05** (drift_shapes.gd:76).
  - Flyers stay at 0.15: they aren't on the sand.
- *Owner:* Enemy Code.

**P2. The sideways slide outruns the walk (crab-walking).**
- *What the player sees:* a walker glides sideways while its `walk_side` or `walk_up` cycle keeps facing forward.
  On slow kinds it looks like ice-skating.
- *Cause:* a lane retarget is a fresh `randf_range(-1, 1)` (enemy.gd:1960), eased at `LANE_EASE 3` (enemy.gd:1961).
  - Worst case is a −1 → +1 jump: 2 × 0.3 × 64 = 38 px, at 3 × 38 = **115 px/s** at the start of the ease.
  - A typical jump (about 0.67 lane) starts at about **38 px/s**.
  - Compare forward speeds: Barrow Wight 40, Ash Crawler 45, Great Toad 38.4, Hollow Stag 44.8 px/s. For these,
    a typical retarget is a 40-45° crab, and the worst case is about 70°.
  - For a Shade (102.4) it is about 20°, which reads fine. That is why the Packs capture (Shades) looks OK and slow
    kinds won't.
- *Fix:* cap the lateral rate by the walker's own speed. Move the lane toward the target at most
  **0.3 × speed / (width × cell)** lane units per second (a crab angle of 17° or less), instead of the exponential
  ease. Keep a smoothstep in and out so it starts and stops softly.
  - Retarget within **±0.5 lane** of the current lane, not the full ±1, so walkers never swap sides in one move.
  - Wander gap `LANE_WANDER` (3, 6) → **(5, 9) s**.
- *Owner:* Enemy Code.

**P3. Narrow gaps squeeze the sprite but keep the full lane.**
- *What the player sees:* in a half-cell gap (about 32 px of sand), a walker squeezed to a narrow body still sits
  up to 19 px off centre: inside the Warden or obstacle beside the gap.
- *Cause:* `_update_squeeze` / `_gap_answer` (enemy.gd:1677-1724) scale `sprite.scale.x`, but `_update_lane`
  (enemy.gd:1946-1981) never reads `_gap_answer`.
- *Fix:* multiply the lane by **0** while `_gap_answer` is true (eased with the same squeeze rate), and set the lane
  target to 0 there so it doesn't snap back on the far side.
- *Owner:* Enemy Code.

**P4. Jostle pins packs to the path edges.**
- *What the player sees:* in dense Packs, pairs push apart until one or both sit at the clamp, which is the edge
  (P1 again). A pack then reads as two rails, not a clump.
- *Cause:* `JOSTLE_PUSH 1.2` lane units/s, applied every second frame for as long as the pair stays close
  (enemy_spawner.gd:315-355), and clamped to ±1.0 (enemy_spawner.gd:354-355).
- *Fix:*
  - `JOSTLE_PUSH` → **0.6**.
  - Clamp the jostled target to **±0.8**, so jostle alone never puts a body on the edge lane.
  - Keep `JOSTLE_REACH` at 0.4.
  - Keep `JOSTLE_LANES` at 0.25 cells as stored, but since lanes are about 40% narrower after P1, use **0.15**
    cells so the trigger keeps the same meaning.
- *Owner:* Enemy Code.

**P5. Y-sort follows the node, not the body.**
- *What the player sees:* on horizontal stretches the lane offset is vertical. A walker drawn lower (in front) can
  sort behind one drawn higher, and the wrong body overlaps. At the inner edge, a body can also draw over a Warden's
  base on the cell above.
- *Cause:* y-sort uses the node position (subject.md; MapGenerator is the y-sort root). The drawn offset is
  `_corner_offset + _lane_drawn` (enemy.gd:2347).
- *Fix:* P1's 0.18 cell (about 11 px) mostly hides it, because bodies rarely overlap by more than that. If it still
  shows, add the body's vertical offset to the sort (a z nudge or a sort-origin offset) for walkers only.
  Not a fairness issue.
- *Owner:* Enemy Code; check after P1.

**P6. Big Packs are hard to read at game zoom.**
- *What the player sees:* in `bigpacks_burst.png` the pack is a faint, translucent smear along the path. You can
  tell something is there, not how many.
- *Cause:* art and shader translucency (blight.gdshader), not lanes.
- *Fix:* none from lanes. Ask Enemy Assets whether walkers in a pack of 8+ keep at least the single-walker contrast.
  The Coming strip's count already does the reading for the player (facts on screen, no hand-holding).
- *Owner:* Enemy Assets.

## Answers to the owner's four questions
1. **What looks off.** In order:
   - lane width vs the drawn path (P1);
   - the sideways slide on slow kinds (P2);
   - lanes in narrow gaps (P3);
   - jostle pushing walkers to the edges (P4);
   - y-sort, minor (P5).

   Corner easing is fine: rotating the side vector with LANE_TURN_EASE 5 on top of CORNER_ROUNDING 0.3 reads as a
   swing round the bend, and I saw no snapping. I couldn't tell jostle jitter at 10 fps; the push is eased, so I saw
   drift rather than shake.
2. **Should the lane follow the walk animation's facing?** **No.**
   - Turning the sprite by the drawn velocity would flip walk_side / walk_up on every lane change. That is worse:
     facing thrash in a crowd.
   - Cap the slide instead (P2): at 17° or less of crab, the forward-facing cycle reads correctly. Kingdom Rush does
     the same: small sideways offsets on a wide road, the sprite always facing along the road.
   - If the slide ever goes above about 30°, face by the drawn velocity only past 45° (hysteresis), never by the
     raw lane change.
3. **Are bunching and packs readable?**
   - Readable at game zoom on PC once they stay on the sand: clumps are countable, and Single file still reads as
     a line.
   - Messy today where bodies leave the sand (P1) and in Big Packs (P6).
   - On a phone (about 22 px per cell) every walker at ±0.3 is half off the path. That is the deciding case for P1.
   - Bloons TD 6 keeps every bloon on the track and gets its crowd look from count and spacing. Kingdom Rush keeps
     offsets well inside a road 1.5 bodies wide. Both keep the enemy on the high-contrast lane, and we should too.
4. **Which numbers should change:**

| Name | Now | Proposed |
|---|---|---|
| `LANE_MAX` | 0.3 | **0.18** |
| `LANE_BIG` | 0.15 | **0.08** |
| Single file `lane_width` | 0.1 | **0.05** |
| `LANE_FLYER` | 0.15 | 0.15 |
| `LANE_WANDER` | 3-6 s | **5-9 s** |
| Retarget range | ±1 | **±0.5 of the current lane** |
| Lateral rate | ease rate 3 | **≤ 0.3 × speed px/s**, smoothstepped |
| Lane in a narrow gap (`_gap_answer`) | full | **×0** |
| `JOSTLE_PUSH` | 1.2 | **0.6** |
| Jostle clamp | ±1.0 | **±0.8** |
| `JOSTLE_LANES` | 0.25 | **0.15** cell |

   Keep as they are: `LANE_TURN_EASE` 5, `CORNER_ROUNDING` 0.3, `JOSTLE_REACH` 0.4, `LANE_SNAP_PX` 0.25.

## 4. Builds and Wardens that shine or suffer
- Fairness is untouched: lanes are visual only, so no build gains or loses range or hits.
- Area Wardens (Puffball clouds, Bellflower pulses) *look* better against clumped packs. The player sees why area
  pays against Packs.
- After P1, area builds look like they hit bodies that are inside their ring. Today, a body drawn on the grass
  edge can look out of a cloud it is really inside. That is a perceived-fairness risk, and the narrower lane fixes it.
- Ground cues on the route (mushrooms, water, gold path) stay under the bodies when the lane is narrower. Today the
  edge walkers stand beside them, which misreads "is it in the puddle?" (Seat B owns the details.)

## 5. Open questions for the owner
1. Should the lane width follow the drawn path width (sand band ≈ 0.6 cell) as a rule, so a future path art change
   can't put bodies on the grass again? (I recommend yes: lane max = 0.3 × the band width.)
2. Big Packs: should a pack of 8+ be easier to read (art contrast), or is the Coming strip's count enough?
