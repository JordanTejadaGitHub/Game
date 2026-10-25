# Seat B (build player): more of the group-wipe moment

Frames: `seat_B_frames\` (big.png / big_wipe.png = big Packs 70, 133-138 s; packs26.png / packs_wipe.png = Packs 26,
45-50 s; stream27, single_tough, lanes). Read-only; nothing run.

## 1. Verdict: feels good with fixes
The wipe already happens. In Packs 26 the 6-8 clumps fold round the first corner and the Firefly/Dewdrop/Bellflower
cluster takes them down together. In big Packs 70 (107 nightmares, 6 packs of ~18) a whole column dies inside about 3 s.
But two things blunt it for a build player. **The moment doesn't say whose it was.** In big_wipe.png the pack is buried
under a wall of damage numbers and green health bars, and the dispels come through as a few quieter sighs. Nothing
names the Calling or the card that did it. **The contrast drift is missing.** Single file almost never rolls, so an
area board isn't tested, and "one board answers everything" creeps back. My advice: get more wipes from contrast and
payoff, not from bigger or more frequent packs.

## 2. What works (keep)
- Pack sizes and spacing (`drift_shapes.gd:26-31`): 6-8 one-kind packs, 0.5 cell apart, ≥5 s between them. One pack
  fits a pulse-and-chain cluster. The 5 s gap gives a beat of "reload".
- One Packs drift per act 2+ block (enemy_design.md "The mix through a run"). Crowds are an event, not the norm.
  Keep it at one.
- Dispel-count engines don't care about shape. Wild Growth (`WILD_NEEDS` 20/60/150) and Hard-Won Rings (every 80)
  count dispels, and shapes never change a drift's count. Packs don't over-feed them.
- Most per-Warden clocks stay flat in a crowd: Breathe It In and Mixed Company once a second per Warden
  (`spore_print.gd:66,86`), Wave `WAVE_COOLDOWN` 4 s (`puddles.gd:250`), Floodgate `SURGE_COOLDOWN` 6 s (`:209`),
  Rude Awakening once a second per bell. Those cards don't explode in packs, and that is what stops an area board from
  answering every drift. Per-nightmare clocks (Toll `TOLL_WAIT` 1 s, `keeping_time.gd:17`) do scale with bodies,
  which is fair: more targets, more Tolls.
- Leak caps: `PACK_LEAVES` 3 per 8 (`drift_shapes.gd:37-38`) and Few and tough's 6. A missed wipe costs a few leaves.
  It doesn't end the run, so it feels like my own fault.

## 3. Problems, ranked

**P1. A wipe is never credited to the build (biggest feel loss).**
- *Feel:* 18 bodies die and I can't tell whether my Lantern Light jumps, Peal or Black Pond did it. In the frames the
  gold motes and sparks are lost under the numbers.
- *Cause:* per-hit damage numbers and the green bars draw on every pack member (big_wipe.png). `Sound.play_dispel`
  only gets quieter in a cluster, and `MAX_VOICES` 4 per id (`sound.gd:14, 210-219`). Nothing in combat_callouts,
  Fx, SoundHooks or DewPopup knows about packs: a grep for "pack" finds only a comment. `class_kit.credit` →
  `card_fired` exists, but nothing shows it yet (CLAUDE.md "Calling evolutions": "UI still to build").
- *Fix:* a **pack cleared** event. The spawner tracks the members left per `pack_key` (`PACK_META` is already on
  every member, `drift_shapes.gd:46,67`). When the last member is dispelled and **none leaked**, emit
  `pack_cleared(key, count, pos, top_source)`. The payoff hangs off that one signal (see Q4). The callout names a
  fact: "Pack ×8". The rest report adds "Packs cleared: 3 of 4" and the top Dream credited in those packs
  (`card_counts_block`).
- *Owner:* Enemy Code (signal), Main Merger (callout, report, SoundHooks), Roguelite Code (card credit lines).

**P2. Single file is ~14% of its planned slots (143 vs ~1,000 Packs), so area builds are rarely tested.**
- *Feel:* Spread lines (Windblown → Spore Season, Strung Lights → Lantern Parade, Black Pond / Wave, Peal) clear
  Packs, Streams and the trash in Few and tough. The one drift built to make them sweat is almost always a Stream.
  An area board then answers every drift but Few and tough's elites.
- *Cause:* `_fit_single_file` gives up once it has thinned `SINGLE_THIN_MAX` 0.25 of the bodies
  (`drift_roller.gd:127, 536-540`), and the drift becomes a Stream (`:316`). Late counts (~107 at 70) can never fit
  1.5 s apart in a 30 s window.
- *Fix:* before falling back, **stretch Single file's arrival window up to 1.5×**, then thin up to **0.35**.
  Target: Single file plays in **≥60%** of its planned slots in every act. Don't shrink `SINGLE_GAP` below 1.2 s, or it
  stops reading as single.
- *Owner:* Balancing Discussion (numbers), Enemy Code (roller).

**P3. Numbers and status glyphs bury the clump.**
- *Feel:* packs_wipe.png shows a stack of Drowsy "Z"s, bars and numbers over each Bellflower-rung pack. At game zoom
  the bodies are gone, and so is the "bunched" look the owner likes.
- *Fix:* damage numbers on pack members within 0.4 s merge into one number per pack (the sum, at the pack's centre).
  Health bars on pack members draw at 50% opacity until hovered or selected. No change to the bars of loose
  nightmares or bosses.
- *Owner:* Main Merger (DamageLog `numbers_mode`, health bar).

**P4. The Pall can cover a pack member and break the wipe (act 4).**
- *Feel:* a Dewdrop pulse or Firefly chain dispels 7 of 8, and the covered one walks on at half damage. It reads as
  the game saving one.
- *Cause:* `_can_cover` (`enemy.gd:2313-2316`) excludes bosses and elites but not pack members. Flyers can be in a
  Packs drift, spaced outside the packs.
- *Fix:* `_can_cover` also refuses a walker with `PACK_META`. The Pall then covers loose walkers only.
- *Owner:* Enemy Code.

**P5. Big packs outgrow every Calling's area caps. This is fine, but name it.**
- At ~18 per pack: Lantern Light's jump event reaches `EVENT_MAX` 6 (`firefly_lights.gd:29`), Black Pond spills to
  `SPILL_MAX` 4 (`puddles.gd:243`), Wave hits `WAVE_MAX` 6, Twelfth Hour 3, Sleeping Hall 4, Pile-On only the clump's
  rank III+. A third of a big pack falls to the cards; the rest needs the Wardens' own area (pulses, splash, cloud).
- **Don't raise these caps for packs.** It would make big Packs the area board's free win. Keep `PACKS_BIG_COUNT` 6.
  Don't make big packs bigger.

## 4. Builds checked: who gets the wipe
**Shine in Packs (they get the moment):**
- Lantern Light Support (Borrowed Light → Show the Way / Constellation). The jump on every dispel starts a new event,
  so a pack cascades: the Vampire Survivors chain, the best wipe in the game.
- Puddles Black Pond / Wave lines.
- Keeping Time Peal (a Toll rings everything within 4 steps) and Sleeping Hall.
- Spore Print Windfall (each dispel leaves a mushroom the next member steps on) and Rot Bloom. In a one-kind clump
  they all walk the same bed.
- Dewdrop Monsoon and Morning Fog. Bellflower pulses.
- Legendaries: Headlong (a compressed drift is one giant pack) and Wild Growth (ripens fast in Packs, at the same
  rate overall).

**Never get it (and shouldn't):**
- Focus lines: Bonfire → Pyre / Flint and Steel, Steady Beat → Midnight Bell / Double Time, Clump → Pile-On / Elder
  Cap, Accompaniment → Symphony.
- These shine on Few and tough's 3-5 Deeply Blighted and on bosses. They're tested by Packs, which is right. Midnight
  Bell (12 rings, once per nightmare) is a trap in Packs alone, but every block has a Few and tough.
- Keep F&T at one per block. Never let a Packs drift replace it.

**Over-rewarded if crowds grow:** a Dewdrop + Bellflower pulse cluster near the start (the v3 board) already wipes
every pack in the frames. More Packs per block would make that board the answer. Hence P2 and no second Packs drift.

## 5. The owner's five questions
1. **Pack sizes:** 6-8 right; act 1's 4-5 right (act 1 cards have ~3-target caps such as Spore Ring). Keep the 6 big
   packs from 48+, so ~18 at drift 70. For tighter clumps, take **`PACK_CELLS` 0.5 → 0.4** for packs only: 8 bodies
   then span 2.8 cells, inside one pulse range, not 3.5.
2. **Lanes:** 0.2-cell lanes and the jostle are enough (lanes.png reads as one column). Don't narrow the lanes. Tighten
   along the route instead (Q1's 0.4).
3. **Single file:** not fine for builds. Loosen it as in P2: window ×1.5, thin cap 0.35, at least 60% landing. Owner:
   Balancing Discussion.
4. **Payoff:**
   - The `pack_cleared` beat (Enemy Code).
   - One low settle on the pack's last dispel (no climbing chime, so `audio_direction.md` holds), on SoundHooks (Main
     Merger).
   - One merged Dew pop per pack, the pot shares summed (Main Merger, DewPopup).
   - Merged numbers (P3).
   - "Pack ×N" callout, and top card credit in the rest report (Main Merger + Roguelite Code).
   - Motes are already right. Keep them under the Fx budget.
5. **What fights it:**
   - The Pall covering a pack member (P4).
   - Numbers and bars burying the clump (P3).
   - Y-sort overlap at 0.2 lanes is invisible at game zoom. Leave it.
   - Flyers out of packs: correct, keep.

## 6. Open questions for the owner
1. A **"pack cleared" beat**: yes or no, and does it get its own sound (a low settle, never a chime)?
2. Should **Streams carry loose clumps**? For example, 25% of a Stream's arrivals in clumps of 3-4. That gives small
   wipes in two drifts a block without a full crowd. I'm against it until P2 lands, because it widens the
   area-board lead.
