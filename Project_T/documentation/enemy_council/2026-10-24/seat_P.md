# Seat P: Pacing and balance (round 2026-10-24)

## 1. Verdict
**Feels good with fixes.** The shapes keep health and the Dew pot equal by construction, and the pack leaf cap keeps losses
gradual. But leaf risk is now uneven across shapes: Packs are cushioned, Few and tough is the cliff. The proposed flyers
bring back the Phantom leak pattern through two Omen paths that skip every cap.

## 2. What works (keep)
- **Same budget, same pot.** Few and tough pays its share through the elite flag. The roller pays elites from the budget
  (`drift_roller.gd` `_mix_cost`, ELITE_COST), and `pot_shares` splits by weight, so no shape prints Dew or hides health.
  `apply()` keeps the first and last arrival, so call-early Dew, Call of the Wild, `arrival_left` and Auto-drift don't move.
- **Pack leaf cap.** `DriftShapes.cap_pack_leak` (`drift_shapes.gd:88-97`, called at `run_state.gd:249`) allows
  3 leaves per 8 nightmares. This is the rule that keeps one bad pack from ending a run, and the glossary states it
  (`codex_data.gd:22`).
- **Safeguards already built:** a Deeply Blighted counts as 3 dispels (7573c842), Poisoned cap ×3 on elites (a39603dc),
  `FEW_SHARE` 0.4–0.6, Single file thins at most 25% (cdd6ed4e). These pull Few and tough back inside the 30–40% build-loss
  limit on paper.
- **Mix timing.** No shapes before 11. One shape per block in act 1. No shape on 24/49/74/99. Never two Few and tough in a
  row. This is the right pacing skeleton.
- **Walking lanes** don't touch pacing: logic stays on the centre line, and the lane fades out before the Heartwood, so
  leak timing and CloseCalls are unchanged. Keep it as is.
- **Flyers fly the route**, not straight. That alone answers most of the Phantom lesson.

## 3. Problems, ranked

**P1. Hollow Wind and Moth Night bypass every flyer cap. With the new flyers they become common.**
- *Player feels:* three whole drifts arrive as Palls, Gloamwings or Phantoms, and 15+ leaves go in one block. "The game cheated."
- *Cause:* `omen_director.gd:568-573` (`shape_schedule`) turns every non-boss arrival into a flyer from `_block_flyers`
  (`:939-948`). That pool includes the Phantom (`dandelion_seed.tres` trait 1). `drift_max` is enforced only at roll time
  (`drift_roller.gd:287-289`), so Hollow Wind already turns a Phantom block's first 3 drifts into all-Phantom drifts
  today. Moth Night's `flyer_count_multiplier` 1.6 is applied in `get_schedule` after the roll
  (`drift_director.gd:574/628`), so 4 Phantoms become 6. The 6-flyer cap is proposed in the roller only. `requires_flyers`
  currently gates both Omens to rare Phantom blocks; Night Kite, Gloamwing and Pall make them offerable in most act 2–4 blocks.
- *Fix:* apply the flyer cap after Omens, at schedule time: at most 6 flyers a drift, at most 4 Phantoms, extras spill to
  the drift's other kinds. Hollow Wind draws only from route flyers (no Phantom). Pall becomes a Night Kite in an all-flyer
  drift (nothing to cover). Also check Hollow Wind's text: the doc says 2 drifts (`run_design.md:627`), the data says 3
  (`hollow_wind.tres`). Use 2.
- *Owner:* Roguelite Code (Omens), Enemy Code (the cap's schedule-time spill).

**P2. Few and tough is the leaf cliff, and an act's finales guarantee one.**
- *Player feels:* the board can't kill the first elite in its route time, so it can't kill any of them. 3–5 Deeply
  Blighted × 2 leaves (`enemy.gd:1669`, `ELITE_LEAVES`) plus 2-leaf Husk leads leak together: 8–12 of 15–16 leaves in
  one drift. The leaks are correlated (all-or-nothing), unlike a Stream's partial slips. Packs of the same kinds are
  capped at 3.
- *Cause:* the leaf cap is pack-only (`cap_pack_leak` returns early without `PACK_META`). The "6–10 leaves ≈ a Stream's
  worst case" estimate in balance_simulation.md "Drift shapes: numbers" assumes independent leaks. Human run 58 hit the
  act 3 wall at drift 51. The first block after an act break is where a Few and tough finale hurts most.
- *Fix (proposal):* (a) treat a Few and tough drift's Deeply Blighted as one "pack" for the cap, at 2 leaves per elite up to
  6 in all; or (b) no Few and tough finale in the first block after an act break (drifts 30, 55, 80). Choose after the sim.
  Gate: a Few and tough drift's worst-decile leaves ≤ 6, and its median ≤ 1.5× the same block's Stream median.
- *Owner:* Balancing Discussion (decides), Enemy Code (builds).

**P3. The pack cap cancels Leaf Fall (and half of Brittle Night) on Packs drifts.**
- *Player feels:* Leaf Fall ("every leak costs double leaves") barely bites in a Packs drift, yet still pays its 4-card
  Rare+ Dream.
- *Cause:* the cap runs after the multiplier (`run_state.gd:245-249`, comment "after Leaf Fall / Giants' Walk"). A pack of
  7 Shades leaking costs 3 under Leaf Fall, the same as without it.
- *Fix:* scale the pack limit by the leak multiplier: 6 per 8 under Leaf Fall or Brittle Night. Giants' Walk's +1 stays
  inside the cap. One sentence in the Omen text: "packs too".
- *Owner:* Roguelite Code / Enemy Code; Balancing Discussion confirms.

**P4. The shape gate measures leaves, but leaves are capped on one shape only.**
- *Cause:* the gate "worst shape 1.5–3× best in leaves lost" (balance_simulation.md "Sim gate"). With the cap, Packs can
  almost never be a build's worst shape in leaves, even when it overruns the board.
- *Fix:* gate on **bodies leaked and health leaked**, with leaves as a third column. Same 1.5–3× band.
- *Owner:* Balancing Code.

**P5. A 6-flyer cap is too high for act 2, and the teaching drifts are budget cliffs both ways.**
- *Player feels:* drift 41 sends 6 Night Kites at a board that has only met 4 Phantoms (drift 31) and act 1's Crows. A
  flyer-blind board loses 6 of 16 leaves to the lesson.
- *Cause:* the Phantom intro was cut from 6 to 4 for exactly this reason (`acts_1_2.md:164`). The proposed 41 row (6 NK +
  16 SH ≈ 2,100 base health) replaces 28 SH, 8 HU, 6 NH, 1 PR (≈ 6,500). 69 (4 GW + 20 SH ≈ 2,900 vs ≈ 7,200) and 92
  (3 PA + 12 HU ≈ 4,100 + cover vs ≈ 8,800) drop the same way. That is consistent with the small intro drifts (31, 68),
  but it lands in act 2's hardest stretch (38–45).
- *Fix:* teaching drifts of **4** Kites / 3 Gloamwings / 3 Palls. Cap flyers per drift by act: **4 in act 2, 5 in act 3,
  6 in act 4**, Phantoms ≤ 4 inside it. Keep the intros small, like 31 and 68 (the breather is fine). After each intro,
  the roller's ease-in caps (`fresh_caps`) should hold the new flyer to ≤ 2 for the next block.
- *Owner:* Balancing Discussion; Main Merger (rows).

**P6. Pall's cover hides health in the budget, and can stack on elites, bosses and shells.**
- *Player feels:* a Pall settles on a Deeply Blighted Husk: 3× health, then half damage, then the dread shell. Low-damage,
  fast-hitting boards (Firefly, Sporeling ticks) see it barely move.
- *Cause (design):* "takes half damage" doesn't say whether it applies before the shell's flat cut. A 20 hit with a −6
  shell does 14 normally, 10−6 = 4 if halved first (3.5× less) or 7 if halved after. The cover isn't in `get_roll_cost`.
  At 92, 3 Palls on 12 Husks hide ≈ +25% health that the budget doesn't see.
- *Fix:* the half applies after the shell. A Pall never covers a boss or a Deeply Blighted (it moves to the next walker).
  Pall's roll and Dew weight ≈ 160 + its cover (proposed: 2.5× its health, about 400 at drift 1). No Palls in Few and
  tough drifts.
- *Owner:* Enemy Code; Balancing Discussion (the weight).

**P7. Single file concentrates leaf cost.**
- Thinning 25% into the heavy lead turns 1-leaf Shades into 2-leaf Husks, so Single file has fewer leaks that each cost
  more. Small. Measure it with P4's columns; no change unless Single file's leaves exceed Stream's by 1.5×.

**P8. Blight sharpening via "bigger packs from 51" softens leaves.**
- Bigger packs mean fewer leaves per nightmare under the 3-per-8 cap (a pack of 40 costs at most 15). If Blight sharpens
  shapes, use shorter pack gaps (Restless-Wind style), not bigger packs.

## 4. Builds or Wardens that shine / suffer (pacing view)
- **Shine:** Puddles and Keeping Time against Gloamwing (Soaked / 3 Drowsy drops it into the maze: about half its
  effective health). Crowd capstones on Packs, plus the capped leaks. Area boards against Pall + walker together.
- **Suffer:** Spore Print's mushrooms and doses, Puddles' water, rubble, Hold, Rooted: no answer to route flyers, by
  design, so these boards rely on plain anti-air. Hit-count / Poisoned boards against Pall-covered elites (P6). Every
  board on a Few and tough finale right after an act break (P2). Firefly and Sporeling get no Gloamwing drop; at 220
  health and speed 80 it stays a long, slow anti-air check (health per unit of speed 2.75, Shade 1.0), which is fair.

## 5. What the sims should measure (when allowed)
- **Gates:** per Calling × crowd/boss line: best vs worst shape 1.5–3× in bodies and health leaked (P4); no shape cuts
  damage > 40%; a Few and tough worst decile ≤ 6 leaves (P2); **flyers ≤ 25% of leaves lost** over drifts 41–100 for
  each starting-family pair (the Phantom took 53%); no drift with > 4 flyer leaves.
- **Drifts:** 30 / 60 / 85 (the shape gate); **51–60** per shape (act 3's new ramp 3.6→4.0; aim: leaks start in the 60s);
  41, 69, 92 (intros) and the block after each; one Hollow Wind and one Moth Night block in act 3 with the new flyers; a
  Leaf Fall block that holds a Packs drift.
- **Phone:** drift 96 as Packs (already asked of Main Merger).

## 6. Open questions for the owner
1. Few and tough leaf risk: one capped "pack" of elites (P2a), or no Few and tough finale after an act break (P2b)?
2. Flyer cap by act (4 / 5 / 6), or a flat 6?
3. Should the pack leaf cap double under Leaf Fall and Brittle Night (P3)?
4. Teaching drifts: small intros like 31 / 68 (a breather in act 2's hardest stretch), or keep the replaced drift's
   budget with 4 flyers inside it?
