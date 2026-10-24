# Round 2026-10-24b: enemy movement ("Enemy movement looks off")

Owner, 2026-10-24: **"Enemy movement looks off."** Judge walking lanes (and how drift shapes arrive) as the player
sees them; say what is off and how to fix it, with exact numbers. Round 1 (2026-10-24, `verdict.md` in
`D:\Projects\logs\enemy_council\rounds\2026-10-24\`) covered the design; this round is about the LOOK.

## What changed today (Enemy Code; visual only, the node stays on the path's centre line)
- Walking lanes: `documentation/enemy_design.md` "Walking lanes" (96bfba15); code f70e67d9, 84011a9a, 7ba8dd17 in
  `scripts/enemy/enemy.gd` (`_update_lane`, `get_lane_width`, `LANE_*` constants near `_corner_offset`) and
  `scripts/enemy/enemy_spawner.gd` (`_jostle_lanes`, `JOSTLE_*`).
  - The drawn body sits up to ±0.3 cell beside the line (bosses, big kinds, Few and tough elites ±0.15; Single file
    ±0.1; flyers sway ±0.15).
  - It picks a new lane every 3-6 s, eased over ~1 s, measured across an eased travel direction (LANE_TURN_EASE 5).
  - The lane opens over the first cell walked and closes over the last cell before the Heartwood.
  - Jostle: walkers within 0.4 cell on lanes < 0.25 cell apart push their target lanes apart (1.2 lane units/s).
  - Reduced motion: a fixed lane.
- It stacks on the older rounded corners (`_round_corners` / `_corner_offset`). Y-sort still follows the node, not
  the drawn body.
- Drift shapes: Packs / Single file / Few and tough / big packs (`scripts/run/drift_shapes.gd`, enemy_design.md
  "Drift shapes").

## Watch (real speed, map seed 4242), in `D:\Projects\logs\enemy_code\shapes_video\`
- `walking_lanes.mp4` (50 s, 1920×620): before vs after, side by side.
- `drift_types_small.mp4` (160 s, 1280×720): every shape with lanes on.
- Also there: `lanes_packs_on.avi` / `lanes_packs_off.avi`, `lanes_stream_on.avi` / `_off.avi`, `v2_packs.avi`,
  `v2_single_file.avi`, `v2_few_and_tough.avi`, `v2_big_packs.avi`, `v2_stream.avi` (full-size captures).
- Prepared frames: `D:\Projects\logs\enemy_council\rounds\2026-10-24b\frames\` (`lanes_sheet_*.png` 1 frame/s,
  `shapes_sheet_*.png` 1 frame per 2 s, `lanes_burst_12s.png` 10 frames/s). They are small: crop closer.
- **To look closer**, extract your own frames with ffmpeg into your own subfolder of the round folder (never C:):
  `D:\Projects\ffmpeg\ffmpeg-9.0.2-essentials_build\bin\ffmpeg.exe -ss <s> -t <s> -i <video> -vf "crop=w:h:x:y,fps=10,tile=5x2" <out>.png`
  then read the PNG. A burst at 10-15 fps over 1-2 s is how you judge sliding, jitter and corner easing.
  Don't render new captures (that runs Godot); use what's there.

## The owner's questions (answer all four in your seat's terms)
1. What looks off: lane width, wander speed, the corner easing, sliding sideways without the walk animation
   turning, jostle jitter, lanes on narrow or turning paths, or y-sort overlap?
2. Should the lane follow the walk animation's facing?
3. Are bunching and packs readable, or messy?
4. Which numbers should change?
Give rulings with exact numbers. Read-only: no code changes.

## Seat focus this round
- **B (build player):** do lanes hide or misread Calling cues (Firefly glow and lights, mushrooms, water, bell
  pips), status icons, health bars, damage numbers? Does bunching make crowd builds readable?
- **W (Warden roster keeper):** do Wardens' shots, beams, chains, pecks and hit effects land on the drawn body
  (`Enemy.get_visual_position()`; check whether Tower Code switched), and does any Warden now look like it misses?
- **T (tower defense veteran):** what looks off overall to a player, readability of packs and shapes at game zoom
  and on a phone, comparison with Kingdom Rush / Bloons TD 6 crowds.
- **S (systems and code keeper):** the code behind what you see: `_update_lane`, `get_lane_width`, `LANE_*`,
  `_corner_offset` stacking, `_jostle_lanes` jitter, narrow half-cell gaps, y-sort by node, walk animation facing
  (`update_animation` uses the node's velocity), the lane rng. Cite lines.
- **P (THIS ROUND: motion and game-feel animator, replacing pacing):** the walk cycle vs the sideways slide, easing
  curves, wander frequency and amplitude, corner arcs, whether motion reads as alive or as drift; give the numbers.
