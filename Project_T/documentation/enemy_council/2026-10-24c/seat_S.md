# Seat S (Systems and code keeper), round 2026-10-24c: more of the group-wipe moment

**Verdict: feels good with fixes.** Packs are made right and stay bunched (one kind per pack, so one speed). Three
things keep a wipe from reading as one moment. (1) The pack is a long column, not a clump. (2) Sound turns 18
dispels into about 3 quiet sighs. (3) Each nightmare gets its own icon row, bar and Dew popup, so a pack shows as a
wall of UI. Every fix is small and stays inside today's code paths.

Paths are under `D:\Projects\Game\Project_T`. Line numbers are from the working tree on 2026-10-24.
`enemy.gd` / `enemy_spawner.gd` have uncommitted Enemy Code edits (the crowd icon row is being built), so their
line numbers will move.

Frames I extracted (`seat_S_frames\`): `big_packs_overview.png`, `big_packs_start_crop.png` (dt_4, drift 70, "107
nightmares in 6 packs") and `packs26_crop.png` (dt_1). In the drift 70 crop, every pack is a solid block of
status icons, stack numbers and green bars. The bodies under it can't be seen. Each wipe is a column of separate
gold flashes running along the path, not one burst.

## 1. What works (keep)
- **One kind per pack.** `_packs` groups by `EnemyData` (`drift_shapes.gd` ~312-330). A pack shares one speed, so
  it stays together all the way down the maze. Slows on the front members only bunch it more.
- **Flyers never ride in packs.** `LOOSE_TRAITS` (line 48) holds FLYING, ROLLING, LEAP, BURROW and WANDER; these
  kinds fill the gaps between packs. `FLYER_CAPS` {1:4, 2:4, 3:5, 4:6} (line 174) limits flyers per drift. So a
  wipe is always walkers. Keep both.
- **Leak caps.** `cap_pack_leak` (line 94): `pack_leaf_limit` = 3 × ceil(size/8), so a big pack of 18 can take at
  most 9 leaves. Split children inherit the pack and its limit (`enemy_spawner.gd` 555-556). The Few and tough
  shared key is 999.
- **Lane numbers.** `LANE_MAX` 0.2 (`enemy.gd` 269). The jostle compares nightmares by distance left along the
  route, in 0.55-cell buckets, on every 2nd frame (`enemy_spawner.gd` 317-366). That costs little even in pile-ups:
  18 nightmares held in one bucket is about 300 pair checks every 2 frames.

## 2. Problems, ranked

**P1. A big pack is too long for one area hit.** The player sees a wipe that runs along the path instead of a
burst.
- Cause: `_pack_step` (`drift_shapes.gd` 276-281).
  - A normal pack spaces its members `PACK_CELLS` 0.5 cell apart.
  - A big pack spaces them `min(0.5 cell / speed, PACK_SPAN_MAX 3.0 / (n-1))` apart.
- Shades (102.4 px/s): a pack of 8 is 7 × 32 px = 3.5 cells long. A big pack of 18 (107/6) has 0.176 s gaps =
  18 px apart, so it is 4.8 cells long.
- Husks (57.6 px/s): a big pack of 18 is 2.6 cells long.
- Area reach today: Dewdrop splash 0.6 (1.2 cells across), Hoarfrost 0.75, Cairn / Boulderback 1.0, Morning Fog
  cloud 1.25, Old Mountain 1.5. A pack longer than about 2.5 cells never fits under one splash or cloud.
- The lane can't get wider. ±0.2 cell already fills the 0.55-0.6-cell sand band (retune 614ec352).
- Fix: tighten along the route only.
  - `PACK_CELLS` 0.5 → **0.35**. A Shade pack of 8 becomes 2.45 cells; Husks of 8 become 2.45 cells too.
  - `PACK_SPAN_MAX` 3.0 → **2.4**. A big Shade pack of 18 becomes 0.141 s = 14 px apart, 3.8 cells long.
  - Leave `PACK_GAP_FLOOR` 0.2 as it is.
- Streams and Single file don't use `_pack_step`, so they are unaffected.
- `CROWD_MAX` 8 in 3 s (line 34) still holds: a pack of 8 Shades now arrives in 1.53 s.
- Jostle needs no change. At 14-22 px apart, 2-3 neighbours are within 0.55 cell, and they spread across the 25 px
  band.
- Owners: Balancing Discussion decides; Enemy Code builds (two constants).

**P2. A wipe sounds smaller than one dispel.** The player feels a big moment land as a quiet patter.
- Cause: `Sound.play` (`sound.gd` 151-200) allows `MIN_INTERVAL_MS` 45 ms between starts of an id and
  `MAX_VOICES` 4. `play_dispel` (210-219) also lowers each clustered dispel by `DISPEL_CLUSTER_DB` −1.5 dB, down to
  −6 dB, inside `DISPEL_CLUSTER_MS` 700 ms.
- Result: 18 dispels inside about 0.3 s give 3-4 voices, each quieter than a single dispel.
- audio_direction.md (~421) already asks for "one fuller, softer swell" when dispels land close together. No code
  does this today.
- Fix: in `play_dispel`, from the **5th** dispel inside 700 ms, start one `dispel_swell` at the cluster's centre.
  - A low, wide release of air and light, never a rising pitch.
  - Gain grows with the log of the count, up to a +4 dB cap. Size sets its length, 0.8-1.6 s.
  - Then hold further single dispels until the cluster ends.
  - It doesn't climb and it isn't a Dew sound, so it fits the house rules.
- Owners: Sound Code (generator + `play_dispel`). SoundHooks line 214 needs no change.

**P3. A crowd is a wall of UI.** The player can't see the bodies they are wiping.
- Cause: each nightmare draws a full icon row and health bar (frames above), and each dispel adds its own
  `DewPopup` (`run_state.gd` 169 and 226).
- The compact crowd row is being built now (uncommitted, `enemy.gd` 313-328: `CROWD_PIP` 5 px, alpha 0.7, bar
  3 px). **Land it before any tightening (P1)**: tighter packs make the wall worse.
- Dew fix: inside one pack wipe, merge popups. After the 3rd popup within 0.7 s and 1.5 cells, the next ones add to
  one popup that counts up ("+46"), 20 px, and rises from the pack's centre.
- Owners: Enemy Code (compact row), Main Merger (`RunState.earn_dew_at` / `DewPopup` merge).

**P4. There is no "pack wiped" event to hang the beat on.** Today nothing knows that a pack died together.
- `PACK_META` is a run-wide key (`pack_key` = drift × 1000 + pack, line 62). It is set in `tag_enemy`, which is
  called from `drift_director.gd` 785.
- Fix: add a signal in `EnemySpawner._on_enemy_cleansed`, `pack_wiped(key, centre, count, size)`.
  - Keep `{key: [dispel times]}` and a live count per key (spawn +1, cleanse / leak −1).
  - Emit when **≥ 5 and ≥ 60%** of a pack of 6+ were dispelled within **1.0 s**. Once per pack.
  - Leave out the Few and tough key 999, bosses and echoes.
  - Cost: O(1) per dispel.
- The sound swell (P2), merged Dew (P3) and one soft ring of motes at the centre (Fx, "ground" kind,
  `MAX_EFFECT_PX` 160) all hang on this signal.
- Text: at most a fact on the rest report ("Packs wiped: 4"). No praise words and no screen shake (that is the
  boss's).
- Owners: Enemy Code (signal), Sound Code, Main Merger (rest report line), Enemy Assets (ring art, if any).

**P5. Motes and cracks have no budget on the phone.** A wipe can make a frame spike on mobile.
- Each dispel creates its own `CPUParticles2D` with 14 × scale motes (`enemy.gd` ~3803). It also makes its own
  `ShaderMaterial.duplicate()` for the crack (~3828), which breaks 2D batching for 0.37 s.
- A big pack of 18 gives 252+ particles and 18 unbatched draws in one frame. A 25-member pack at drift 100 (fixed
  6 packs) gives more.
- Fix: count dispels in a 0.5 s window. Past 8, mote amount × 0.5 (min 6). Past 16, × 0.25 (min 4). Under
  `Fx.reduced()`, past 4.
- Keep the crack per body: it is the read.
- Owner: Enemy Code.

**P6. Y-sort in tight clumps.** On horizontal stretches, members flicker over and under each other.
- Every node on a horizontal stretch has the same y. The lane is drawn with `sprite.offset` (`_body_offset`,
  `enemy.gd` ~2606), so ties sort by tree order.
- A body drawn 12 px lower can draw behind one drawn higher.
- Tighter packs (P1) make this happen more often. The doc's "Watch" note at enemy_design.md ~775 covers it.
- Least-change fix:
  - Move the lane from `sprite.offset` to `sprite.position`.
  - Set `y_sort_enabled = true` on the Enemy node. Godot 4 sorts a y-sorted child together with the parent's
    group by its own global y.
  - Keep the HUD canvas item on the node. Bars sort with the node, which is fine since they draw above.
- Check it in the v3 scenes after P1 lands. Owner: Enemy Code.

**P7. Big-pack mode counts arrivals, normal packs count bodies.** A splitter-heavy late drift never becomes big
packs.
- `big := schedule.size() > 48` (line 300) and `_big_pack_counts` count arrivals.
- `PACK_SIZE` and `PACK_MIN` count `_weight` (children and followers, line 271).
- Result: 40 splitters × 2 children (120 bodies) gets normal packs of 2-3 arrivals.
- Fix: total `_weight` for the big check. Owner: Enemy Code.

## 3. The owner's five questions
1. **Sizes.**
   - 6-8, and act 1's 4-5, are right in code. `PACK_SHARE` 1/3 means act 1 needs 12+ arrivals to pack.
   - "6 big packs from 49+" is right, but the count is fixed. At drift 100 (about 150 bodies) that is 25 a pack.
   - Recommend `PACKS_BIG_COUNT` = clamp(round(count/18), 6, 8), so packs stay 16-20.
   - Owner: Balancing Discussion.
2. **Lanes.** Keep ±0.2 and the jostle. Bunch along the route instead: P1's 0.35 / 2.4.
3. **Single file.**
   - The plan gives each shape once a block (`plan_shapes`, `drift_roller.gd` 131-198). The rarity is all
     fallbacks: `most = floor(window / 1.5) + 1` (532), with at most 25% of bodies thinned.
   - Example: a 30 s act 2 drift fits 21 arrivals, so it can't be Single file past 28 bodies.
   - Recommend leaving the 25% cap alone (it keeps Single file from turning into a Few and tough without its
     safeguards). Make `SINGLE_GAP` act-scaled instead: 1.5 / 1.2 / 1.0 / 0.8.
   - Single file is the counter-board drift that keeps area from answering everything.
   - Owner: Balancing Discussion; Enemy Code builds.
4. **Payoff pieces.**
   - The swell: Sound Code.
   - `pack_wiped` and the mote budget: Enemy Code.
   - Merged Dew popup and rest report "Packs wiped": Main Merger.
   - Compact rows: Enemy Code (in flight).
   - Optional ground ring: Enemy Assets.
   - No new callout words. `CombatCallouts` has `MAX_ALIVE` 3; leave it.
5. **Fights.**
   - **The Pall:** acceptable.
     - It rides loose in the gaps. `_walker_to_cover` (`enemy.gd` 2427) picks the nearest walker ahead within
       `PALL_REACH` 2.5 cells, which is usually the pack's last member.
     - That member takes half of each blow (`PALL_SHARE` 0.5, line 3507), so it outlives the wipe by about 2×.
     - Area hits the Pall too, so the Pall dies first.
     - It is act 4 only, at most 6 flyers a drift. One straggler is a fair test. Keep it, but count it in
       P4's 60% rule.
   - **Flyers out of packs:** correct (see "What works").
   - **Y-sort:** P6. **The icon wall:** P3.

## 4. Builds and Wardens
- **Shine with P1:**
  - Splash and cloud forms that are short of a column today: Dewdrop splash 0.6, Hoarfrost 0.75, Bloomcap 0.75,
    Mistveil 0.9, Morning Fog 1.25.
  - Bellflower pulses (they already cover a column).
  - Firefly chain jumps: shorter hops between members keep the chain inside `chain_jump_range`.
- **Already shine:** Rootling, Acorn and Bellflower pulses.
- **Suffer:** single-target snipers do relatively worse against tighter packs. That is the point of Single file
  (Q3).

## 5. Open questions for the owner
1. Tighten packs to 0.35 cell / 2.4 s (P1), knowing it makes area forms stronger on Packs drifts?
2. A `dispel_swell` that gets louder (+4 dB max, never higher in pitch) for 5+ dispels: within "not a reward
   sound"?
3. Rest-report fact "Packs wiped: N": yes or no?
