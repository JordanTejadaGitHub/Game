# Seat P: Pacing and balance, plus the wipe payoff (round 2026-10-24c)

Frames: `seat_P_frames\` (`packs26_*`, `big70_*`, crops of the start corner where the board's Wardens stand).

## 1. Verdict
**Feels good with fixes.** One Packs drift per block already gives 3-6 wipe chances a block from act 2, so that is often
enough. The fixes are about the payoff and one leaf cliff. Today a wiped pack of 8 sounds about 2 dB louder than a single
dispel, it shows 8 separate "+1 Dew" popups, and in big packs the bodies vanish under a solid strip of damage numbers. So
the moment happens but doesn't land. More wipes should come from a better payoff, not from more crowd drifts.

## 2. What works (keep)
- **How often:** from act 2, every ordinary block plans two Streams plus Packs, Single file and Few and tough once each
  (`drift_roller.gd:166-186`). That is one Packs drift in five (20%), with 2+ packs, or 6 when big. Boss blocks put Packs
  in drifts 1-3 of the block. That is the right frequency: the wipe stays an event, not the norm.
- **Same budget, same pot.** Shapes never add a nightmare (`drift_shapes.gd:4-8`), and the pot is fixed and split by
  weight (`balance_simulation.md` "Dew stays fair"). Crowds don't change the economy. Keep it that way: **no Dew bonus for
  a wipe.** A bonus would snowball area boards and break "no reward sound" (`audio_direction.md` ~420).
- **Pack sizes 6-8 (act 1: 4-5) and the 5 s gap** read as clumps in `packs26_wipe_crop.png`: a pack of 6 meets the
  first ring together and dies inside about 2 s.
- **Few and tough leaks are capped at 6** (`TOUGH_LEAVES`, `drift_shapes.gd:156`), and Deeply Blighted count as 3 dispels.
  Both keep the test shape from causing a cliff.

## 3. Problems, ranked

**P1. A wiped pack doesn't sound like a group (Q4).**
- *Feel:* eight dispels land as one dispel with a soft tail.
- *Cause:* `sound.gd:14-16, 56-58, 160-166, 216-219`: `MAX_VOICES` 4, `MIN_INTERVAL_MS` 45, `CROWD_DB` −2.5 per sounding
  voice, cluster −1.5 dB per dispel down to −6. For 8 dispels in 0.4 s, voices 5-8 are dropped and the four that play sit
  at about −3, −7, −11 and −15 dB. Summed, that is about −0.9 dB, only ~2 dB over one dispel. The rule says "one wider,
  warmer glow" (`audio_direction.md` ~407), and today it is not wider.
- *Fix:* add one **`dispel_swell`** one-shot made from the dispel's own material: tuned air on the whole D chord, twice
  the resonances, full stereo spread, ~1.2 s, no pitch movement, no chime, no low end. It plays once when **5+ dispels
  land inside 700 ms within 3 cells**, at −1 dB (+1.5 dB at 10+, never more), and it takes the place of dispel voices 3+
  in that window. It never steps up and never ducks the music; instead `set_ambience_trim` dips the ambience by 2 dB for
  1 s.
- *Owner:* Sound Code (generator recipe, `Sound`, `SoundHooks`). Sound Council should listen to it first.

**P2. Damage numbers bury the wipe (Q4/Q5).**
- *Feel:* in `big70_wipe_crop.png` the 18-strong pack is a strip of digits ("4553331…"), status glyphs and green bars.
  The crack and motes underneath are hard to see.
- *Cause:* per-hit numbers on every crowded body (`damage_log.gd` numbers mode). The compact-crowd rule (enemy_design.md
  ~781) only covers status rows.
- *Fix:* on nightmares that are crowded (the same 0.5-cell test), **merge numbers per pack every 0.25 s into one number**
  at the pack's centre. Crits and boss/Deeply Blighted numbers stay on their own.
- *Owner:* Main Merger (DamageLog / numbers).

**P3. No "cleared the pack" beat, and the Dew pops are noise (Q4).**
- *Feel:* at act 3's pot (~125 Dew for ~100 nightmares, `drift_director.gd:174`) a pack of 18 shows 18 "+1 Dew" popups.
- *Fix, facts only:*
  - Enemy Code emits `pack_cleared(key, size, pos)` on `EnemyContainer` when the last member of a pack (`PACK_META`) is
    dispelled with **0 of it leaked**.
  - The pack's Dew shares show as **one DewPopup "+N Dew"** at the last dispel (the same Dew, paid as now).
  - Add one warm mote updraft, 1.5× the normal motes, budgeted through `Fx`.
  - The rest report gains a "Packs cleared: 5 of 6" line.
  - No words like "Wiped!", no extra Dew.
- *Owner:* Enemy Code (signal), Main Merger (popup merge, rest report, run history column `packs_cleared`), Tower Assets
  (the updraft sheet).

**P4. Big packs: a leaf cliff, and a grind at drift 96 (Q1).**
- *Feel:* `PACK_LEAVES_PER` 8 gives a cap of 3 per 8 nightmares (`drift_shapes.gd:37-38, 285-286`). A drift 70 pack
  (107 / 6 ≈ 18) can cost 9 leaves, and a drift 96 pack (243 / 6 ≈ 40) can cost 15, which is a whole 15-leaf run in one
  slip. A 40-body carpet also takes longer than one wipe to clear.
- *Fix:* cap a pack at **min(3 × ceil(n / 8), 6)**, the same 6 as Few and tough. A glossary line can then say "a pack
  takes at most 3 leaves, a big one at most 6." Losing six big packs still ends a run, so failing is still failing.
- *Keep `PACKS_BIG_COUNT` 6.* The window decides it: 6 packs × 3 s + 5 gaps × 2 s = 28 s fits a ~30 s window. 8 packs
  only fit if `PACK_SPAN_MAX` drops to 2.2 s (8 × 2.2 + 7 × 2 = 31.6 s, still tight). So the phone fallback "8 instead of
  6" also needs `PACK_SPAN_MAX` 2.0.
- *Owner:* Balancing Discussion (the number), Enemy Code (`pack_leaf_limit`).

**P5. About 12.5% of runs see no pack before drift 26 (pacing).**
- *Cause:* act 1 picks Packs or Single file 50/50 in each of blocks 3-5 (`drift_roller.gd:150-157`). Three Single file
  picks = 0.5³ = 12.5%, and those mostly fall back to Stream anyway.
- *Fix:* **block 3 (drifts 11-15) always gets Packs**, the first wipe right after the second family pick. Blocks 4-5 stay
  50/50. This is still seeded, never read from the board.
- *Owner:* Enemy Code; Balancing Discussion signs off.

**P6. Single file rarity (Q3).**
- *Cause:* `_fit_single_file` (`drift_roller.gd:529-552`) fits window / 1.5 + 1 ≈ 21 arrivals in a 30 s window. Thinning
  25% only rescues drifts of up to ~28 bodies. Act 2 has ~40-60 and acts 3-4 have 75-240. So Single file mostly exists in
  act 1-2's small drifts, and loosening the cap can't save the late ones (thinning 240 down to 21 is a Few and tough
  without its safeguards).
- *Ruling:* **keep `SINGLE_THIN_MAX` 0.25.** Do two things instead:
  - When the Single file fit fails, retry once with the **Heavy** template (fewer, heavier bodies for the same budget)
    before falling back to Stream.
  - In acts 3-4, accept that the slot becomes a Stream.
- For the wipe question, rarity barely matters: the planned Packs slot is unaffected.
- *Owner:* Enemy Code (retry), Balancing Code (measure planned vs realised shapes per act; target ≥ 50% realised Single
  file in acts 1-2).

**P7. The Pall in a pack (Q5).**
- *Feel:* one covered member survives the wipe on its shared blows and turns "all at once" into a straggler.
- *Fix:* **a Pall never settles over a nightmare carrying `PACK_META`**. It can still cover loose walkers between packs.
- *Owner:* Enemy Code.
- Flyers pulled out of packs and riding loose between them: keep. Y-sort in clumps is Seat S's call; from pacing, nothing
  changes.

## 4. Questions 1-2 in numbers
- **Q1:** 6-8, 4-5 and 6 big packs from 48+ (49 bodies gives 6 packs of ~8, so the step into big packs is smooth): keep
  all of them, with the P4 leaf cap.
- **Q2:** keep lanes at 0.2 cell and jostle as ruled in 2026-10-24b. Tighter clumps raise area hits per pulse in
  proportion to the bodies inside the radius. Halving the in-pack gap (`PACK_CELLS` 0.5 → 0.25) would roughly double the
  area damage per pack, before the shape gate has even been measured. The clump reads already (`packs26_wipe_crop.png`).
  Revisit `PACK_CELLS` 0.4 only if sims show area lines under-performing on Packs.

## 5. Builds that shine / suffer
- **Shine on Packs:**
  - Lantern Light Strung Lights / Carried Lights (dispel jumps chain through a clump)
  - Puddles Black Pond → Breaking Wave
  - Keeping Time Midnight Bell (a Toll per nightmare)
  - Spore Print Spore Season
  - Dawnbreak and Wild Growth (dispel counters fill fast)
  - Bellflower pulses
  - Firefly chains

  P1-P3 make their moment audible and visible without changing any number.
- **Suffer if crowds grow:** Focus / boss lines (Lantern Parade, Fathoms, Double Time) and the hit cards. They are tested
  on Packs by design (gate 1.5-3×). A second Packs drift per block would push them past the 40% damage limit, so **don't
  add one.**

## 6. What the sims should measure (Balancing Code, when sims are allowed)
- **Wipe rate:** the share of packs fully dispelled within 2 s of the first member's dispel, per Calling line, at drifts
  30 / 60 / 85.
  - Crowd lines: ≥ 60%.
  - Focus / boss lines: 15-35% (they should be tested, not dead).
- **Leaks per pack** and **worst single-pack leaf loss** at drifts 60-95, under the current cap and the P4 cap.
- **Realised shape mix** per act (planned vs played) over 200 seeds, including the P5 rule.
- The existing shape gate: best vs worst shape 1.5-3× in leaves, no shape costing a build over 40% damage.

## 7. Open questions for the owner
1. **Big-pack leaf cap:** cap it at 6 per pack (P4), or keep 3 per 8 (a drift 96 pack can cost 15 leaves)?
2. **The pack swell:** may a cleared pack of 5+ count as a "big moment" that ducks the music 2 dB, or does it stay
   unducked with only the ambience dip (my pick: unducked)?
3. **Act 1's first Packs drift:** fix it to drifts 11-15 every run (P5)?
