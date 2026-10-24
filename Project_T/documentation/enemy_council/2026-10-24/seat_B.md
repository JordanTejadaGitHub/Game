# Seat B: Build player (roguelite veteran), round 2026-10-24

## 1. Verdict
**Feels good with fixes.** Drift shapes are the best thing to happen to builds in a while: every Calling line gets a
drift it owns and a drift that tests it, and the Calling hit code already gives Deeply Blighted full value. Walking
lanes are harmless to builds. The new flyers are a good idea, but the **Pall's half damage** as written is a trap for
Focus lines and hit cards. The **Gloamwing's drop rule** is lopsided (one Dewdrop splash grounds it, Bellflower needs
3 stacks). And **Hollow Wind** breaks the 6-flyer cap. Fix those three and I'd ship all three parts.

## 2. What works (keep)
- **Shapes give each build a moment to shine.** Packs feed Puddles' ripple, Firefly jumps and Reaction bursts. Single
  file feeds the Spread lines (Windblown / Drifting Spores, Strung Lights / Lantern Alley, Carrying Tune / Last Bell).
  Few and tough feeds Focus lines (Clump / Pile-On, Bonfire / Pyre, Steady Beat / Midnight Bell) and the hit cards.
  Each ordinary block from act 2 has each shape once, so no build waits a whole act for its drift.
- **The boss-capstone worry is mostly already solved in code.** Calling hits only halve on `enemy_data.is_boss`
  (`scripts/combat/class_kit.gd:499-500`; Firefly `BOSS_SHARE` the same, `firefly_lights.gd:28,2639`). Deeply Blighted
  are not bosses, so Lantern Parade, Rot Bloom, Midnight Bell and Elder Cap deal full value on Few and tough. The card
  fix in enemy_design.md "Card fixes shapes need" bullet 3 is only needed for cards outside `calling_hit`. Seat S should
  check that.
- **Elite placement by shape** (Few and tough first, Single file last, Packs middle) lets the player read where the
  hit cards' "boss or Deeply Blighted" targets will be.
- **Route flyers, not straight flyers.** Every flyer-hitting Warden along the maze gets its turn, so the maze still
  matters. This is the right lesson from the Phantom.
- **The Gloamwing's idea is a real build moment.** Once it drops it becomes a walker (`is_flying()` is false while
  grounded, `enemy.gd:1982-1983`). Then mushrooms, water, Tolls and steps all switch on for it. A control player gets
  to watch the engine catch a flyer.
- **Walking lanes leave combat alone** (node on the centre line, `get_visual_position` only for aim). No build loses
  anything.
- **Snag** (`dream_batch_rules.gd:36,552`) already lands route flyers on Thornwalls. Maze builders get a real answer to
  the Night Kite.

## 3. Problems, ranked

**P1. The Pall's "half damage" makes hit builds feel like a trap.**
- *Player feels:* my Bonfire / Pyre crits, Midnight Bell, Bearing Down / Measured Blow / Finishing Blow land half on
  the walker under the cloth. If my Wardens keep shooting the walker and not the Pall, half my output is gone, and
  nothing tells me I chose wrong.
- *Cause:* enemy_design.md "Flyers" table, Pall row. It is a second damage reduction, which contradicts "Nightmare
  Kinds": *"The shell is the only damage reduction left, and it is visible."* Default targeting is "closest to the
  goal". A Pall settled on its walker ties with it. The only targeting tool, `has_target_priority`, is on snipers. Six
  Sporeling and Dewdrop forms can't hit the Pall at all (Brood Cap, Fairy Ring, Elf Circle, Hatchery, Undercurrent,
  Maelstrom; `resource/tower/*.tres` role_line). Spread engines never hit flyers either (`class_kit.gd:364-366`
  returns -1).
- *Fix (one meaning):* **the cloth shares the blow.** Every hit or effect on a covered walker deals half to the walker
  and half to the Pall. Area hits that touch both still hit both in full. Nothing is wasted. Dispel engines and Focus
  totals hold. Focusing the Pall still uncovers the walker faster, so target priority still matters. Add: the Pall
  counts as **0.1 cell ahead** of its walker for "closest to the goal", so default aim picks it when it can.
  **Never covers a boss or a Deeply Blighted** (keeps it off the hit cards' targets). **No Palls in Few and tough
  drifts.** Card line: "Covers the walker ahead: hits on it are shared with the Pall."
- *Owner:* Enemy Code (rule), Balancing Discussion (numbers), owner decision below.

**P2. The Gloamwing's drop is a coin flip by family.**
- *Player feels:* with Dewdrop, the first splash grounds every Gloamwing ("Soaked" is a plain status, `damp`;
  `enemy_statuses.gd:8`; Cloudlet rains on flyers too). With Bellflower I need 3 Drowsy at `status_every = 2`
  (`resource/tower/bellflower.tres`). And if I took **Brimming**, which doubles "numeric reaction/stack-payoff
  requirements" (CLAUDE.md "Brimming update"), it may read as 6. A Rare card that makes flyers harder to land is a trap.
- *Fix:* **3 stacks of Soaked or 3 of Drowsy, counted together** (so 2 + 1 works). Brimming never raises it (fixed
  number, said in the tip). The drop is permanent: a Waymark shedding statuses doesn't lift it back up. Sporeling's
  lent "stacks faster" cards count toward it. That gives a Sporeling + Bellflower pair a real reason to hit flyers.
- *Owner:* Enemy Code; Balancing Discussion for the 3.

**P3. Hollow Wind breaks the 6-flyer cap and would make all-Pall drifts.**
- *Player feels:* a Spread-line board (Carrying Tune, Windblown, Puddles' Stream line) faces a drift where every
  arrival is a flyer its engine can't touch. Palls with no walkers to cover just float. A Phantom-only block turns
  into a Phantom flood.
- *Cause:* `omen_director.gd:568-573` swaps every non-boss arrival for a random flyer of the block. The pool is
  `_block_flyers`, `:939-948`, which includes Phantoms and would include the Pall. There is no cap.
- *Fix:* the Hollow Wind swap pool takes **route flyers only** (no Phantom, no Pall), and the 6-flyer rule doesn't
  apply to it. It's an Omen the player chose, so the Omen card states the full count ("every nightmare flies").
  Phantoms stay at most 4 even under Hollow Wind.
- *Owner:* Roguelite Code (Omens), Enemy Code (cap).

**P4. Few and tough starves dispel-count engines.**
- *Player feels:* Wild Growth (`WILD_NEEDS` 20/60/150) and Hard-Won Rings (every 80 dispels) slow down in the block
  where 9 bodies replace 30. Single file also carries fewer.
- *Fix:* accept the doc's proposal, but **everywhere, not only in Few and tough**: a Deeply Blighted dispel counts as
  **3** for counting engines (Wild Growth, Hard-Won Rings), said in the glossary. It doesn't apply to a jump on
  dispel (Lantern Light's jump is a hit, not a count).
- *Owner:* Roguelite Code.

**P5. Once-a-second clocks idle between packs.**
- Calling hits use a per-Warden 1 s budget (`class_kit.gd:486-489`). Others: Toll once a second per nightmare
  (`keeping_time.gd:17`), On the Beat 3 s (`:54`), Chain of Lanterns 1 s (`firefly_lights.gd:89`). A pack of 7
  crosses a 3-cell Warden in about 6 s, then 5+ s of nothing. Spread and per-Warden builds lose about half their
  output in Packs. That is the intended test, but Balancing should check it stays near the 60-70% floor. No change now.
- *Owner:* Balancing Code (measure).

**P6. Doc error: Pile-On is not a "3+ nightmares" card.** Its rule is about rank III+ Wardens around a clump
(`calling_paths.gd:70-72`), and it works on Single file. Drop it from the "never fires on Single file" bullet so no
one "fixes" it. *Owner:* Main Merger (doc).

**P7. Lanes vs edge-reading cues (minor).** A body drawn 19 px off the centre line can look outside a Firefly glow
while its node is inside it (Lit is counted at the node). It can also eat a mushroom it visibly walked past. The
fix is art only: a small pop on the mushroom as it's eaten, and glow edges soft rather than a crisp ring.
*Owner:* Enemy Assets / Roguelite Asset chat.

## 4. Builds checked: shine / suffer
- **Spore Print** Spread (Windblown → Drifting Spores → Spore Season; Deathcap → Rot Bloom): shines on Single file.
  It is tested by Packs and by flyers ("Never flyers", `calling_paths.gd:41`). It gets a moment when a Gloamwing
  drops onto mushrooms.
- **Spore Print Focus** (Clump → Pile-On, Elder Cap): shines on Few and tough. Under P1 as written it suffers most from
  the Pall, since 4 Sporeling forms can't hit flyers.
- **Spore Print Support** (Shared Caps → Windfall, Host Grove): flat, fine.
- **Lantern Light** (Strung Lights / Lantern Alley / Lantern Parade; Bonfire / Pyre; Borrowed Light /
  Constellation): Packs are its moment. Early Lamps already handles flyers. Bonfire suffers under P1.
- **Puddles:** Packs (ripple) and Gloamwing drops are its shine, too easily under P2. It is blind to flyers otherwise
  (`puddles.gd:156`).
- **Keeping Time** (Carrying Tune / Last Bell / Curfew; Steady Beat / Midnight Bell; Accompaniment / Symphony): Few and
  tough shines. Tolls never on flyers (`keeping_time.gd:1084-1086`). Hit by Brimming under P2 as written.
- **Lent cards:** stacks-faster (Packs, and the Gloamwing under P2's fix), linger (Single file), jumps (Packs),
  repeats (Few and tough). None is dead.
- **Legendaries:** Headlong (Single file best), Wild Growth (P4), The Walking Wood (Few and tough), Waymark (Single
  file; sheds statuses, so the Gloamwing drop must stay permanent).
- **Hit cards** (Bearing Down, Measured Blow, Finishing Blow): Few and tough shines. P1 is their trap.
- **Dead builds found:** none once P1 to P3 are fixed.

## 5. Open questions for the owner
1. **Pall: share the blow, or halve it?** I recommend sharing (P1). Halving keeps the target-priority puzzle sharper,
   but it wastes output for every build that can't aim, which is most of the four starting families.
2. **Gloamwing: Soaked and Drowsy counted together (3), or keep "any Soaked"?** Keeping it makes the Gloamwing a
   Dewdrop gift and a Bellflower chore.
3. **Hollow Wind:** route flyers only (no Phantom, no Pall), with the cap lifted for it as the player's own choice?
