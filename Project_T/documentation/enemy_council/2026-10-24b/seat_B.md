# Seat B (build player): enemy movement, round 2026-10-24b

## 1. Verdict
**Feels good with fixes.** Packs finally read as clumps, which is great for crowd builds, but the lanes are wider than
the drawn path (bodies hang off it and onto obstacles at inside bends), the sideways slide is faster than the walk, and
half of the build feedback (damage numbers, combo words, Keeping Time rings, class threads) is still anchored to the
node, so it now sits up to 19 px beside the sprite.

What I looked at: `lanes_packs_on/off.avi` (zoom 1.4, bursts at 5-10 fps around the first bend), `v2_packs.avi`
(zoom 0.62, 10 fps crops of the left column), the prepared `lanes_burst_12s.png` and `shapes_sheet_03.png`. Frames in
`seat_B_frames\`. **Limit:** every capture plants only Thornwalls, with no attacking Wardens, no Calling and no
statuses, so no capture shows a single Calling cue, status icon or damage number. My cue findings below come from code;
they need one capture with a Calling run (see Open questions).

## 2. What works (keep)
- **Packs read as packs.** In `lanes_packs_on` vs `_off` at the 10 s bend, the "after" crowd is a clump two or three
  wide, not beads on a string. For Spore Print (Spread), Puddles' splash lines, Keeping Time Tolls and Firefly jumps,
  that is the picture the build promises: one area hit, a clump lights up.
- **Bars, status dots and elite haze ride the lane.** `_update_lane` pushes `_body_offset()` to the HUD root
  (`enemy.gd:1977-1981`) and redraws haze/marks. Status icons stay on the body.
- **Projectiles aim at the body.** `Tower` aims via `get_body_position()` (`tower.gd:5455`); Fx callouts add
  `Fx.lane_shift` (`fx.gd:417-422`).
- **Logic untouched.** Per-nightmare caps, dispel-count engines (Hard-Won Rings' 80 dispels, Wild Growth's 20/60/150,
  Spore Print's mushroom-per-dispel), once-a-second clocks (Overnight, Rude Awakening, Chain of Lanterns) and "3+"
  checks all read the node, so no build gains or loses power. Good: this round must stay visual.
- Ground cues (mushrooms on route points, water runs, Lit tiles, the gold path) sit on the centre line and the bodies
  walk over them. At ±0.2 cell that still reads as "on the water / on the light".

## 3. Problems, ranked

**P1. Lanes are wider than the drawn path; bodies leave it.** *Player feels:* nightmares walking on the grass, over
the rock base of a tree at the bend (`v2packs_bars16.png` frames 3, 4 and 6: a dark blob sits on the obstacle). That
looks like a bug, and it makes "is it still in my Dewdrop's water / on my mushroom?" unreadable.
*Cause:* the dirt path is about 0.6 cell wide on screen (53 px against a 90 px tree cell at zoom 1.4 in
`packs_on_12.png`), so its edge is about ±0.30 cell. A small body is about 0.28 cell wide (half-width 0.14). `LANE_MAX`
0.3 (`enemy.gd:267`) puts its outer edge at 0.44, so 0.14 cell hangs off. At an inside bend the corner curve
(`CORNER_ROUNDING` 0.3, `enemy.gd:85`; its midpoint cuts in by about 0.11 cell) adds to an inward lane, about 0.4 cell
in total, which is over the obstacle.
*Fix:* `LANE_MAX` 0.3 → **0.18**, `LANE_BIG` 0.15 → **0.10**, Single file 0.1 → **0.06** (`drift_shapes.gd` width),
`LANE_FLYER` stays 0.15. Within **0.5 cell** of a turn's centre, scale the lane by **0.4** (it fades in and out with
the corner curve, so the two never add past 0.2 cell). *Owner:* Enemy Code.

**P2. The sideways slide outruns the walk (crab-walk).** *Player feels:* slow nightmares (Husk, Barrow Wight, Ash
Crawler) shuffle sideways while their walk_up / walk_down cycle plays straight ahead. That reads as drift on ice, not
as being alive.
*Cause:* the new target is anywhere in -1..1 (`enemy.gd:1960`), so a jump can be 2 lane units = 38 px. It is eased at
rate 3 (`LANE_EASE`, `:272`), which starts at 3 × 38 = **115 px/s** sideways. Ash Crawler walks 45, Husk 57.6, a boss
35-45 px/s. Even the average jump (12.8 px) peaks at 38 px/s.
*Fix:* draw the new target within **±0.6 lane units of the current lane** (clamped to ±1). Move toward it at a capped
rate: **sideways speed ≤ 0.2 × walk speed, and never above 14 px/s** (`move_toward`, not an exponential). Wander
3-6 s → **4-8 s**. Then the heading never leans more than about 11° off the travel line, so facing never needs to
change (Q2). *Owner:* Enemy Code.

**P3. Damage numbers and combo words float beside the body.** *Player feels:* the "Weak!", "Conducted!", "Popped!",
"Asleep!" words and the numbers come from empty path beside the nightmare that took the hit. In a Pack that can mean
the neighbour's sprite, so the player credits the wrong target. This hurts Firefly (Conducted / jumps) and Spore Print
(Popped) the most, because the combo word is their payoff.
*Cause:* `DamageLog` spawns at `event.enemy.global_position` (`damage_log.gd:425`). `CombatCallouts` anchors and follows
`global_position` (`combat_callouts.gd:60, 119, 133, 228`). Only the Fx callouts use `lane_shift`.
*Fix:* use `enemy.get_body_position()` in those five places, and keep the ±10 px number scatter. *Owner:* Main Merger
(DamageLog / CombatCallouts).

**P4. Keeping Time rings and the Midnight Bell clock miss the body.** *Player feels:* on a vertical stretch the ring
pips hang up to 19 px (12 px after P1) beside the bar they belong under. In a Pack, two nightmares' rings overlap the
wrong sprites, which makes "how close is this one to a Toll?" unreadable. That count is the whole Keeping Time build.
*Cause:* `_ring_anchor` adds only `_body_offset().y` (`keeping_time.gd:396-398`), so it drops the lane's x and the
corner's x. The clock uses `who.global_position` (`:463`), and the prime mark (`:429`) uses the full offset. Three
anchors in one file disagree.
*Fix:* anchor all three at `enemy.get_body_position()` + the bar offset. *Owner:* Roguelite Code.

**P5. Class threads and puffs point at the node.** *Player feels:* the Firefly jar-to-target thread, the jump threads,
Puddles' Millrace / splash threads and Keeping Time's Allegro thread end in empty path next to the sprite. These
threads are how evolutions "credit themselves" (noticeability rule, owner 2026-10-16).
*Cause:* `_line_fx(..., enemy.global_position)` at `firefly_lights.gd:1267, 1388, 1401`, `puddles.gd:794, 1173`,
`keeping_time.gd:772`, `class_kit.gd:448`. The `landing_dust` / `toll_ring` effects at an enemy go to the node
(`spore_print.gd:657, 694, 875`, `puddles.gd:957, 996, 1175`, `keeping_time.gd:695`).
*Fix:* one helper `class_kit.body(enemy)` (body position for visuals, node for rules), used at every
visual-only call above. Never use it in range or "near" checks. *Owner:* Roguelite Code.

**P6. Clumps merge into one blob, so counts are lost.** *Player feels:* in `v2packs_bars16.png` frames 2 and 7, three
nightmares draw as one dark shape. Lanes make crowds readable as a *group* but not as a *count*. That matters for
"how many did my Bellflower pulse catch?" and for Hard-Won Rings or Wild Growth players watching dispels add up.
*Cause:* jostle reach 0.4 cell (`enemy_spawner.gd:315`) is less than two body widths (about 0.56). Pack spacing along
the path lets bodies stack.
*Fix:* `JOSTLE_REACH` 0.4 → **0.55**, `JOSTLE_PUSH` 1.2 → **0.8** lane units/s (gentler, so no jitter with the narrower
lanes). `JOSTLE_LANES` 0.25 → **0.15** cell (it scales with the 0.18 lanes). *Owner:* Enemy Code.

**P7 (watch). Area visuals vs node hits.** A splash ring drawn at the body while the hit is measured from nodes can
disagree by up to 2 × 0.18 cell after P1 (0.6 cell today). After P1 this is small. Seat W owns it; I only flag that
Puddles' splash and Bellflower pulses are where a player would notice it.

## 4. Builds that shine / suffer
- **Shine:** Spore Print Spread (clumps soak spore clouds and Overnight / Mixed Company stack visibly), Puddles Black
  Pond / Stream (a clump wading reads at once), Keeping Time Tolls on Packs, Firefly Strung Lights jumps (short hops
  inside a clump look right), Brimming / Gone to Seed fills on a Pack.
- **Suffer until fixed:** Keeping Time (P4 rings), Firefly Lantern Light (P3 "Conducted!" + P5 threads, its whole
  feedback), Puddles (P1: a body off the path looks "out of the water" while the rule says in), Gauntlet and Cozy
  Corners (P1 at bends: bodies over the corner obstacle muddle "which side of the path").
- Neutral: Single file (0.1 lanes already read as a line), Few and tough, Legendaries (Waymark's shed flare and
  Headlong are node-based and unaffected; Walking Wood unaffected).

## 5. The owner's four questions (seat B rulings)
1. **What looks off:** first lane width vs the drawn path (P1), then the sideways slide speed (P2), then blobs (P6).
   Corner easing is fine alone, but too much when added to an inward lane (P1). Jostle jitter: none visible at 5-10 fps.
   Y-sort: acceptable at 0.18 cell (about 12 px), no change.
2. **Lane follows facing?** **No.** Facing stays on the node's velocity (`update_animation`, `enemy.gd:1617`). With P2's
   cap (≤ 0.2 × speed) the slide is never steep enough to need a turn, and switching walk_side / walk_up on a lane
   change would flicker in Packs.
3. **Bunching:** readable as groups and good for crowd builds. Messy only where bodies merge (P6) and where the
   feedback misses the body (P3-P5).
4. **Numbers:** `LANE_MAX` 0.18, `LANE_BIG` 0.10, Single file 0.06, `LANE_FLYER` 0.15 (unchanged); lane × 0.4 within 0.5
   cell of a turn; new target within ±0.6 units; sideways ≤ 0.2 × speed and ≤ 14 px/s; wander 4-8 s; `JOSTLE_REACH`
   0.55, `JOSTLE_PUSH` 0.8, `JOSTLE_LANES` 0.15. `CORNER_ROUNDING` 0.3 and `LANE_TURN_EASE` 5 unchanged.

## 6. Open questions for the owner
- Can Enemy Code capture one 30 s clip with a Calling run (Test Grove off, Keeping Time or Lantern Light, damage numbers
  on) after P1-P5? It needs no Thornwall-only maze. No capture in this round shows any build cue, so the cue findings
  rest on code only.
