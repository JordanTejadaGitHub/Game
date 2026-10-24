# Seat W (Warden roster keeper), round 2026-10-24b: enemy movement

## 1. Verdict
**Feels good with fixes.** Lanes do what the owner asked: packs read as clumps, not beads. Tower Code already
aims the main attacks at the drawn body. But about 60 effect calls still land on the node, up to 19 px beside the
sprite. The worst are the Firefly Jar's Charged bolt and its Calling jump, the Dewdrop splash ring and the crit
flare. These are the starting families' signature moments, so with lanes on they now look like they **miss**.

Caveat: none of the captures has an attacking Warden. Every capture plants 22 Thornwalls only
(`shapes_video/lanes_packs.json`, `big_packs.json`; `v2_packs.log`: all 35 leaked). So I could not watch a hit
land. Everything below about hits comes from the code, with file:line.

## 2. What works (keep)
- `Enemy.get_visual_position()` = `get_body_position()` = node + `_body_offset()` (corner + `_lane_drawn` + foot
  lift) (`scripts/enemy/enemy.gd:1930`, `:2341`, `:2347`). `Tower.aim_at()` reads it (`scripts/tower/tower.gd:5454`).
- These already land on the body, so they are correct:
  - Projectiles: they home on the body each frame (`projectile.gd:84`). This covers Sporeling, Dewdrop, Acorn,
    Pebbling and the swoops.
  - Beams: `tower.gd:5466`.
  - The Firefly Jar's main CHAIN attack: `tower.gd:4368`, `:5239-5240`.
  - Pecking birds: `pecking_bird.gd:49`, peck spark `tower.gd:5071`.
  - Pulse sparks: `tower.gd:2892`.
  - Reaction sheets: `reactions.gd:654`, `:658`, `:800`, `:1040`, `:1636`, `:2151`.
  - Exposed marks, last-hit effects and followers: `fx.gd:722`, `:860`, `:883`, `:1042`, `:1134`, `:1230`.
  - Big hit chips and the boss burst: `enemy.gd:1849`, `:3408`.
  - Callouts ride the lane: `fx.gd:468-472`.
- Damage and range stay on the node (enemy_design.md "Walking lanes"). That is right: Warden balance,
  `warden_stats.md` and every range ring keep their meaning.
- Lane widths by shape: Single file ±0.1 (`drift_shapes.gd:137`) keeps beam and chain lines clean. Bosses and big
  bodies ±0.15 keep boss-killer Wardens (Thunderhead, Old Mountain) on target.

## 3. Problems, ranked

**P1. The Firefly Jar's bolts strike empty ground beside the sprite.**
- What the player sees: a Charged bolt or a Lantern Light jump drops 1.5 cells from the sky and lands up to 19 px
  to the side of the nightmare. The jar's signature payoff reads as a miss.
- Cause:
  - The Charged bolt strikes `at := target.global_position` (`reactions.gd:906`), passed to
    `ChargedBolt.strike(at, …)` (`reactions.gd:952`, `charged_bolt.gd:51`, `DROP` 96 px).
  - Live Wire draws from `at` to `next.global_position` (`reactions.gd:938`).
  - The Calling jump draws `ChainBolt([request.from, target.global_position])` (`firefly_lights.gd:2640-2641`).
    Its `from` is also a node position (`:1159`, `:1609`).
  - The `spark_burst` effects are on the node too (`firefly_lights.gd:1215`, `:1358`, `:1870`, `:2201`).
- Fix: every bolt endpoint and strike point uses `Tower.aim_at(target)`. The Static Field and Live Wire reach
  tests keep `global_position`.
- Owners: Tower Code (`reactions.gd`), Roguelite Code (`firefly_lights.gd`).

**P2. The splash ring and area hit sheets are centred on the node, not the body that was hit.**
- What the player sees: the Dewdrop's water hits the body, then its 0.6-cell ring (38 px) opens up to 19 px
  beside it. Neighbours that look inside the ring are skipped, and ones that look outside are hit.
  - The same holds for Pebbling (0.5 cell), Hoarfrost (0.75), Puffball and Cairn (1.0) and Rockslide (1.25).
  - Pulse hit sheets (Tidecaller's wave, World Root's grasp) also play at the node.
- Cause:
  - The projectile lands at the node (`projectile.gd:87`, "Lands at the logical spot").
  - The ring is drawn there (`tower.gd:3887` `_splash_ring(where, …)`).
  - The pulse hit sheets play at `enemy.global_position` (`tower.gd:3231`).
- Fix:
  - Draw the ring at `where + Fx.lane_shift(target)` and play the hit sheets at `aim_at(enemy)`.
  - Keep the splash membership test on the node (`tower.gd:3889`).
  - Lower the lane width (P5) so the mismatch between the ring and who gets hit stays under a third of the
    smallest splash radius.
- Owner: Tower Code.

**P3. Crit flares and status flashes pop beside the body.**
- What the player sees: "Critical!" glints and Marked or Poisoned flashes appear beside the sprite. This hurts
  crit builds most: Prism Jar, Rainbow Prism, Starlit Aim.
- Cause: `Fx.crit(global_position, …)` (`enemy.gd:3106`); `Fx.status_flash(id, global_position, …)`
  (`enemy.gd:965`, `fx.gd:724`); the Dreamlight shard (`enemy.gd:3357`).
- Fix: use `get_body_position()` for both flashes. The shard stays where it is: it is a ground drop.
- Owner: Enemy Code.

**P4. Calling and card effects on the ground still use the node.**
- What the player sees: Dewdrop splashes, Bellflower toll rings and Sporeling dose puffs appear in the path's
  middle while the walker is at its edge. That is about 30 calls in `puddles.gd`, plus:
  - `spore_print.gd`: 657, 694, 875, 901, 940, 1760.
  - `keeping_time.gd`: 695, 1042, 1673, 1690, 1755, 1932, 1998, 2081.
  - `reaction_tracker.gd:64` (the chain badge), `dream_state.gd:5114` (Last Breath), `dream_role_cards.gd:265`
    (Heavy Heart), `tower.gd:5709` (`goal_hold`).
- Fix, one rule for everyone:
  - Effects on the body use `Tower.aim_at(e)`.
  - Effects at the feet or on the ground use `e.global_position + Fx.lane_shift(e)`.
  - Effects tied to path tiles (water runs `puddles.gd:1092`, mushrooms on route points, fairy rings, PathCloud,
    Rootlight tiles) stay on the route. They describe the ground, not the walker, and a ±0.2 lane stays inside
    the tile.
- Owners: Roguelite Code (class scripts, `dream_*`), Tower Code (`reaction_tracker`, `tower.gd`).

**P5. LANE_MAX 0.3 is too wide for small splash Wardens.**
- What the player sees: at ±0.3 two walkers on the same route point are drawn up to 38 px apart. That equals the
  Dewdrop's whole 0.6-cell splash radius, so who got splashed reads as random.
- Cause: `enemy.gd:267` `LANE_MAX := 0.3`.
- Fix: **LANE_MAX 0.3 → 0.2** (12.8 px). Keep LANE_BIG 0.15, LANE_FLYER 0.15 and Single file 0.1. Clumps still
  read at 0.2: the path tile is 64 px and bodies are about 32-40 px. For readability, Seat T's call rules.
- Owner: Enemy Code (Balancing Discussion has no stake: visual only).

**P6. Sweep attacks test hits against the node.**
- What the player sees: a Samara seed visibly passes through a body and doesn't hit it, or hits one that looks
  out of reach.
  - Samara: `HIT_RADIUS` 26 px (`seed_boomerang.gd:11`, `:128-129`).
  - Dawnwing and Whirlwind: 36 px (`patrol_flight.gd:10`, `:111`).
  - At ±0.3 the visible error is up to 19 px of a 26 px hit band.
- Fix: none needed if P5 lands (13 px against 26 px reads fine). Otherwise see question 2.
- Owner: Tower Code.

## 4. Builds and Wardens that shine / suffer
- **Shine with lanes:** clumps make area Wardens visibly worth it.
  - Bellflower pulses and Rootling/Acorn pulses: the ring is around the Warden, so they are unaffected and the
    clump inside reads well.
  - Puffball and Old Mountain splash, Morning Fog and Bloomcap clouds (route-anchored).
  - The Firefly Jar's main chain, which now jumps across a visible clump.
  - Single-target snipers (Thunderhead, Moon Moth line) are unaffected: their projectiles home on the body.
- **Suffer until fixed:**
  - Firefly Jar Charged / Lantern Light builds (P1): the most visible, a starting family.
  - Dewdrop splash and Puddles builds (P2, P4): a starting family.
  - Crit builds such as Prism Jar and Starlit Aim (P3).
  - Bellflower Keeping Time toll rings (P4, milder: the rings are big).
  - Samara and Dawnwing sweeps (P6).
- No Warden loses its reason to exist, and every starting family keeps its answers. The lanes change no gameplay
  number.

## Answers to the owner's four questions (seat W terms)
1. **What looks off, for Wardens:**
   - Hits land on the body for projectiles, beams, the main chain and pecks.
   - They do **not** for the Charged bolt, the Calling jumps, the splash ring, crit and status flashes, and about
     50 Calling ground effects.
   - Lane width 0.3 makes the splash mismatch visible.
   - Y-sort by node does not affect any Warden: shots don't sort against nightmares.
2. **Lane follows facing?**
   - For Wardens, no. Facing should follow the node's travel direction (`update_animation`).
   - A ±0.2 lane eased over about 1 s (`LANE_EASE` 3) is a slide of about 10 px/s, far below walk speed. Turning
     the sprite for it would make projectiles appear to hit a sideways-facing body for no reason.
   - Seat P owns the feel.
3. **Packs readable?** Yes, and they help area Wardens read. But a splash ring that isn't centred on the struck
   body (P2) makes "who got hit" messy. Fix P2 and P5, and packs become the area Wardens' best moment.
4. **Numbers to change:**
   - `LANE_MAX` 0.3 → **0.2**. Keep `LANE_BIG` 0.15, `LANE_FLYER` 0.15, Single file 0.1 and Few and tough 0.15.
   - Visual offset rule: body effects at `aim_at` (offset 0 px from the body); ground effects at
     node + `lane_shift`; splash ring centre at `where + lane_shift(target)`.
   - No change to splash radii, ranges, `HIT_RADIUS` or chain reach.

## 5. Open questions for the owner
1. Should the Wardens' acceptance capture include attacks? I propose a re-capture of `lanes_packs` (seed 4242,
   drift 26) with a Firefly Jar + Dewdrop + Bellflower maze, done by Main Merger after P1-P3 land. This is not a
   new capture by this council.
2. If LANE_MAX stays at 0.3: should Samara and Dawnwing sweeps test against the drawn body? That would be the only
   lane rule with a gameplay effect, which breaks "visual only". I recommend no: shrink the lane instead.
