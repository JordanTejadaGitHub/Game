# Veteran seat, round 3 (2026-10-24)

Read: working tree `scripts/combat/calling_paths.gd` (committed at 7573c842, no uncommitted edits; 84 live rows, 21 per
Calling, same text as calling_rows_now.txt) against `spore_print.gd`, `firefly_lights.gd`, `puddles.gd` (committed Dewdrop
rebuild), `keeping_time.gd`, `class_kit.gd`, plus `tower.gd`, `enemy_statuses.gd`, `dream_state.gd`, `codex_data.gd`. Drift
shapes: working-tree `scripts/run/drift_shapes.gd`, `drift_roller.gd`, `omen_director.gd`, `scripts/ui/shape_rows.gd`,
`rest_report.gd`, `codex_data.gd`, `resource/omen/*.tres`, enemy_design.md "Drift shapes". Read-only; nothing run.

Counting rule: every number, ordinal, "half/double/third" and rate limit in text or tip is one item.

## 1. Numbers: N of M match

| Calling | Match | Notes |
|---|---|---|
| Spore Print (Sporeling) | **63 of 64** | Retinue's "3" (below) |
| Lantern Light (Firefly) | **74 of 74** | Two ranges read two ways (Spreading Flame, Sightline): section 3 |
| Keeping Time (Bellflower) | **59 of 59** | |
| Puddles (Dewdrop), all 21 rows | **65 of 65** | Rebuilt `puddles.gd` checked row by row; boss slows now halved in code |

Checked highlights (constant = text): Windblown SEED_STEPS 3 / GROWS_MAX 6 / MUSHROOM_MAX 40; Drifting 0.01 / 0.30 / 0.15;
Season 15 / 0.60 / 0.30; Deathcap 3 bursts / 2 s / bosses 0.5; Rot Bloom 6 s; Sprout Beds 2 cells / 10 s; Clump 4 / 3 steps /
3 Wardens / 1 a s; Trampled III / 2 / half; Pile-On 4 route points = 2 steps; Trodden ±2 points = 1 step; Throne 10 drifts;
Shared Caps 2 (Charged/Exposed 1); Feeding 12 points = 6 steps / 8 s / +1; Sporefall 6 points = 3 steps; Host Trees 1.15 /
8 s, Grove 3 / 1.30; Spreading Caps 2 cells. Firefly: Strung 4% / 20%; Early 3 / first half / 20 steps; Carried 8% / 40%;
Late 5; Alley gap 4 / 25% / 150%; Parade 4 / 25% / +25% / 100%; Passed 2 cells; gold 2 jars, white 3; Moth 4 / ×1.5; Pyre 50
gold dispels (Deeply Blighted count 3, DreamState.dispel_count) / 2nd / boss 3rd; Banked 3rd / 4th; Spreading 1 / 20 s / 4;
Tinderbox 2 passes; Borrowed 0.33 / 1 s / 3 s brightness / boss 0.5; Wake 2 / 2 cells / 1 cell; Show 0.5; Full Glow 3 s;
Sightline 3 / 0.5; Star 3 / 2 s / 3 hits / 4 s; North 2. Bonfire "at least double": TowerData default crit_multiplier 2.0,
only moonstone 4.0 and standing_stone 2.5 override, values <= 1 become 2.0 (`tower.gd:3401-3402`): true.
Bellflower: TUNE 6 / 4; HAND 2; PEAL 4 / 8; CHANGE 0.5 / 1 s; LAST 0.07 × 30 = 210%; CURFEW 0.5; HALFWAY 0.035; STEADY 3 /
+0.5 (full); CRESC 0.25 / 2.0; MIDNIGHT 12 / ×3 / boss 0.5; TWELFTH 6 / 3; DEEP III / 2; RING_MERGE 0.5; DOUBLE IV / 2;
ALLEGRO V / 3; ACCOMP 1 s / 0.5; COUNTER 0.5 / 1 s; SYMPHONY 4 / 0.5 / 6 s; CODA 4 s / 0.5; TENOR < 1.0; ENSEMBLE 2 / 1 s /
0.5. Dewdrop: FLOW 4; STREAM 0.15 (boss ×0.5 = 7.5%, `puddles.gd:1441,1449`); BACKWATER 6; MUD 4; STEADY 0.20 / boss 0.10;
CLING 4; SINK 2 s; SURGE 0.35 / 3 s / 6 s (timed slows halved for bosses, `puddles.gd:1304`); SPATE 12; SILT 4 s / 2 s; SPILL
0.25 / 4; DEEP_END 0.03 to VII (46%); WAVE V / 4 / 4 s / 6; KING 6 / 4; UNDERTOW 0.10; FATHOM 0.10 (bosses ×2) / 0.50; CRUSH
1 s; SIDE 2 s, SIDE_DAMP 2 s; CALLING_LINGER_MAX 4 s / Charged 2 s (`enemy_statuses.gd:1099-1100`); STILL 3 / boss 0.5;
WIDE 2 cells; MOUTH 0.20 / 0.60 / 6 steps; RAPIDS 3.

## 2. Mismatch list

| # | Row | Text | Code | Evidence | Fix |
|---|---|---|---|---|---|
| M1 | Retinue (`calling_paths.gd:83`) | tip "At most Clump's 3 Wardens." | At most **2** other Wardens: Clump's 3 picks minus the throne's Warden, `slice(0, RETINUE_MAX)`, RETINUE_MAX 2 | `spore_print.gd:179`, `:1197-1202` | Tip: "At most 2: the rest of Clump's 3. Bosses take half." |

No other number disagrees with its constant.

## 3. Rules that two careful readers would play differently (Calling rows)

| # | Row | Now | Two readings / what code does | Rewrite (same numbers, tokens) |
|---|---|---|---|---|
| A1 | Host Trees (`:101`) | "+15% {potency}" | The {potency} glossary says Potency also makes "stronger slows, longer {held}". Code raises only effect **damage** (every Reactions.EFFECT_TAGS tag: Poisoned ticks, Charged bolts, fog, cloud, rain, thorns...), never slows or Root (`spore_print.gd:1477-1491`, `reactions.gd:496`). A Root or slow Warden's player expects longer Root. | "...wears a cap: its status and effect damage deal 15% more, or, if its status deals no damage, its direct hits deal 15% more on {spored} nightmares." (Drop {potency}, or add "damage only" to the tip.) |
| A2 | Host Trees | "if its status deals no damage" | Code: anything but Poisoned or Charged, and also a Warden with **no** status (`spore_print.gd:1466-1470`). A no-status Warden reads as excluded. | Tip: "Its status deals damage: {spored} or {static}. Any other Warden, with or without a status, gets the hit bonus." |
| A3 | Elder Cap (`:80`) / Retinue | "a {free_hit} there with each of its own attacks" | Each attack readies **one** waiting free hit (a flag, not a count), spent by the next nightmare to step on the throne; attacks with no step in between are lost (`spore_print.gd:1185-1187`, `:1255-1256`). Reads as a hit stored per attack. | Tip: "Each attack readies 1 {free_hit}, at most 1 waiting; the next nightmare on the throne takes it." |
| A4 | Spreading Flame (`:196`) | "grows 1 {step} at each end for 20 s, up to 4 {steps}" | SPREAD_GROW_MAX 4 is **per end** (up to 8 steps longer in all), `firefly_lights.gd:1859-1872`. | "...grows 1 {step} at each end for 20 s, up to 4 {steps} at each end." |
| A5 | Sightline (`:218`) | tip "within the usual {jump} reach" | No distance: the healthiest of the **6 nearest** other {lit} nightmares (SIGHT_POOL 6, `firefly_lights.gd:239`, `:998-1004`); nearest_lit has no range cap. "Usual reach" is defined nowhere. | Tip: "Healthiest: the most health left among the 6 nearest other {lit} nightmares." |
| A6 | Lantern Parade vs Codex "Flare" | Codex: "An extra hit ... on a nightmare **in its glow**" | Parade flares when a streak ends, 4 {steps} past its last glow, i.e. outside any glow (`firefly_lights.gd:1325-1335`). | Codex Flare: "An extra hit from a Firefly Warden, from a Lantern Light evolution. Damage only. Triggers no other card." |
| A7 | Carrying Tune (`:249`) | "rings nightmares up to 6 {steps} further down the path" | The carry stops at the next bell's range (`keeping_time.gd:999-1003`, `:556-559`). With bells in a row it never reaches 6. | Tip: "A shot carries to up to 4 nightmares. It stops where the next bell's range starts." |
| A8 | Deep Tone tip (`:293`) | "{Rings} on one nightmare closer than half a second still count as one." | Does a doubled ring merged with another count 1 or 2? Code: the first counts 2, the second within 0.5 s is dropped (RING_MERGE). | "Two hits on one nightmare within half a second make one ring, doubled or not." (round 2b #6, still open) |
| A9 | Coda (`:313`) | "keeps its note" | "note" is Counterpoint's mark on a **nightmare**; here it is a kept repeat on a **Warden** (round 2b #9, still open). | "After a Symphony, each Warden in it has its next hit within 4 s, on any nightmare, land again at half damage." |
| A10 | Accompaniment (`:302`) | "Wardens {touching} a bell, bells too, join it and ring." | Parses as "bells too join it" vs "Wardens touching bells too". Code: any Warden (bells, Sprouts too) touching a bell (`keeping_time.gd:1298-1305`). | "Wardens {touching} a bell, other bells too, join it: their hits ring nightmares. At its {toll}, the joined Warden that rang last repeats its hit at half damage." |
| A11 | Deep End (`:385`) | "(46% at {rank} VII)" | Capped at VII (`puddles.gd:1356`, DEEP_END_TOP_RANK). If ranks above VII exist (Eldest), the text doesn't say it stops (check max rank). | "...+3% for each {rank} of the pond's Warden, up to 46% at {rank} VII." |
| A12 | Riverside / Open Water | "Up to 4 s past landing in all" | 4 s is the Calling's share; lent linger cards can add to 6 s total (LINGER_MAX 6, `enemy_statuses.gd:1059`). "in all" reads as the whole cap. | "Up to 4 s past landing from the Calling ({static} 2 s)." |
| A13 | Early Lamps tip | "Halfway along the path it walks; flyers, their flight." | Flyers' lanterns never fade (`firefly_lights.gd:1289-1291`); Carried Lights' "fades over 20 {steps}" is false for flyers. | Add to Carried Lights tip: "A flyer's lantern never fades." |
| A14 | Drifting Spores tip | "A nightmare that starts its route again starts counting again." | After a lap the count stays 0 until its **next {dose}** (walk[4] = -1, `spore_print.gd:1043-1045`). | "...starts counting again from its next {dose}." |

## 4. Checklist B2, C1, C2, C3

| Item | Verdict | Evidence | Remaining fix |
|---|---|---|---|
| **B2** Keeping Time | **PARTIAL** | Carrying Tune DONE (`:250-251`: "Carried {rings} deal no damage; a {toll} they make does", tip "A shot carries to up to 4 nightmares"). Humming Walls DONE (retired at `:252`; its text has no "pips"; no live row says pips). Steady Beat DONE: the touching-group idea was cut in code ("one bell, the touching group is gone", `keeping_time.gd:195`), text matches. Midnight Bell tip DONE ("Crescendo makes it stronger too."). Allegro DONE (text "stopped by the once-a-second limit", tip "Each nightmare can {toll} once a second"). Deep Tone tip PARTIAL ("still count as one", no "doubled or not"). Accompaniment PARTIAL (defines joining, but "bells too" is ambiguous; no "join its song"). Coda MISSING ("keeps its note"). | A8, A9, A10 above |
| **C1** Sporeling | **PARTIAL** | Drifting Spores not garbled DONE (`:33`). "limit" DONE: no live Sporeling row uses it (only retired Thick Haze). "Sprout bed" DONE (Sprout Beds says "nearest {step} within 2 cells"). Toadstool Throne DONE in substance: code changed to one throne by age (`spore_print.gd:1262-1283`), text "One throne at a time: your oldest Warden's" matches. Sporefall Sprouts DONE ("Sprouts count."). Pile-On direct hits DONE ("each direct hit"). Host Grove Poisoned/Charged PARTIAL: only implied by Host Trees' "if its status deals no damage"; the {potency} word overpromises (A1, A2). Retinue "other" fixed in text, but its number is wrong (M1). | M1, A1, A2 |
| **C2** Firefly | **PARTIAL** | "flare" DONE as token + Codex entry (`codex_data.gd:84`), but the entry says "in its glow" (A6). "glow" PARTIAL: rows use it consistently as one Firefly's light with "Overlapping glows count as one" for counting; still no glossary entry ("Lit" only). Constellation 3 s cap DONE (tip). Bosses take half: Borrowed Light DONE, Sightline DONE; Far Lights, Marsh Lights, Drawn In, Circling Light are retired. Circling Light condition: N/A (retired). Bonfire "at least double" DONE and true (`tower.gd:3401-3402`, only 2.5 / 4.0 overrides). New: Sightline's "usual jump reach" undefined (A5). | A5, A6; a "Glow" Codex entry |
| **C3** Dewdrop | **DONE** | "Bosses half": now true because code halves the slow before the cap (`puddles.gd:1441`, `:1449`, `:1304`; class_kit.SLOW_SNAP 2.5% keeps 7.5%, `class_kit.gd:524-537`). Wet Footprints retired (no live row). All 21 rows' numbers match committed `puddles.gd`: 65 of 65. | none (A11, A12 are wording) |

## 5. New text: drift shapes and Omens

Numbers vs code: all match. PACK_LEAVES 3 = Codex "{const:pack_leaves}" (`codex_data.gd:22`, `:488`); Omen numbers
unchanged (Crowded 1.45, Swarming 2.0 / 0.6, Giants 0.5 / 2.4 / +1 leaf, Restless 0.55 = 45% closer). Problems are
what the text leaves out or lets two players read differently.

| # | Where | Now | Problem | Rewrite |
|---|---|---|---|---|
| D1 | Codex "Drift shape" vs Leaf Fall / Brittle Night / Giants' Walk | "A pack that gets through takes at most 3 leaves." / "each one that reaches the Heartwood takes twice as many {leaves}" | Which wins? Code caps the pack **after** the Omen multiplier and Giants' +1 (`run_state.gd:246-247`), so a Leaf Fall pack still costs at most 3. Players will read the Omen as doubling it. "gets through" is also a new phrase for "reaches the Heartwood". | Codex: "A pack that reaches the Heartwood takes at most 3 {leaves} in all, its Deeply Blighted and Omens included." |
| D2 | crowded_paths.tres, swarming_night.tres | "45% more nightmares." / "twice as many nightmares..." | Silent on pack_fill 8: under these Omens every Packs drift's packs fill to 8, even in act 1 (normally 4-5) (`drift_shapes.gd:173-175`). | Add: "Packs drifts: packs of up to 8." |
| D3 | restless_wind.tres | "nightmares arrive 45% closer together." | In Packs drifts only the gaps **between** packs shrink; nightmares inside a pack don't (`omen_director.gd:110-122`, `drift_shapes.gd:181`). | Add: "In Packs drifts, only the gaps between packs." |
| D4 | giants_walk.tres | "half as many nightmares, each with 2.4× health..." | Silent that a Few and tough drift plays as a Stream (few_tough_as_stream, `omen_director.gd:136-137`). The Coming strip will suddenly show "Stream". | Add: "Few and tough drifts come as a Stream." |
| D5 | hollow_wind.tres | "the first 3 are all flyers." | Packs among those 3 become Streams (`omen_director.gd:138`). Inferable (flyers never pack), but the strip changes shape without a word. | Add: "(as a Stream: flyers never form packs)." |
| D6 | Coming strip fact line (`shape_rows.gd:72-82`) | "Packs: 4 × 7, 6 s apart" | "× 7" is the **largest** pack's arrival count, not each pack's; and it counts arrivals, while pack size in the design counts splitter children and followers (`drift_shapes.gd:157-160` vs `describe` `:327-331`): a pack of 3 splitters shows "× 3" but is 9 bodies. "6 s apart" is the average gap, rounded, with loose flyers/Rolling arriving inside it. | "Packs: 4, up to 7 each, about 6 s apart" (and count splitter children in describe's pack_size, Main Merger / Enemy Code). |
| D7 | Coming strip | "Stream: 30" / "Single file: 18, 1.6 s apart" / "Few and tough: 9, 4 Deeply Blighted" | Bare numbers: 18 what? Is the 9 with or without the 4? (Code: schedule.size(), elites included.) | "Single file: 18 nightmares, 1.6 s apart"; "Few and tough: 9 nightmares, 4 of them Deeply Blighted". |
| D8 | Coming strip elite_line (`shape_rows.gd:104-115`) | "Deeply Blighted in a pack" | With two or more, singular "a pack" is wrong (one per pack, middle packs: `drift_shapes.gd:191`, `:248-266`). A loose (flying) Deeply Blighted rides in the middle gap and gets no line, or the line still says "in a pack" if another one is packed. | "Deeply Blighted: 1 per pack, middle packs" / "...in the middle". |
| D9 | Rest report "This block:" (`rest_report.gd:343-347`) | "This block: Stream, Packs, Single file, Stream, Stream" | A boss drift is listed as "Stream" (drift_shape returns STREAM for fixed drifts, `drift_director.gd:610`), while the Coming strip shows the same drift as "Boss". | Name it "Boss" there too. |
| D10 | Rest report (`rest_report.gd:350-363`) | "Leaves lost by shape this act: Packs 3, Single file 0, Few and tough 1" | Streams are left out, so it reads as the act's total. | "Leaves lost this act: Stream 2, Packs 3, Single file 0, Few and tough 1." |
| D11 | Drift 45 act line (`shape_rows.gd:85-103`) | "%d %s" | "1 Packs" with one; "finales" undefined in player text (= each ordinary block's 5th drift). | "1 Packs drift"; "block finales: ..." (or define "finale" once; note "Finale" is also now the drift 75 stage name, B1). |
| D12 | Codex "Drift shape" | "Packs: tight groups of one kind, spaced apart." | Packs drifts also carry loose nightmares between packs (flyers, Rolling, Leap, Burrow, Wander, kinds with fewer than 3) (`drift_shapes.gd:34-36`, `:199-201`). | "Packs: tight groups of one kind, spaced apart; flyers and kinds too few to pack come between them." |
| D13 | Single file under Restless Wind (design, not text) | design: "at least 1.5 s apart" | The roller fits Single file to the pre-Omen window (`drift_roller.gd:521-524`); a 0.55 spacing Omen could put it under 1.5 s (check). The fact line shows the real number, so no text change; flag to Balancing. | none |

Name clash: "Finale" is now both the drift 75 Calling stage and (per act_line, "finales") each block's 5th drift. Pick
one; "block's last drift" for the second.

## 6. Conventions (fixed phrasings)

- Per-end growth: "N {steps} at each end" / "N {steps} in all". Never bare "up to N {steps}" after "at each end".
- Caps that a number scales into: "+X% for each Y, up to +Z% (at {rank} VII)". Always "up to" before the cap.
- Stored triggers: "Each attack readies 1 {free_hit}, at most 1 waiting." Say whether it stacks.
- Choice of target: "the healthiest of the 6 nearest" / "the nearest within N cells". Never "usual reach".
- Count lines: number + noun ("18 nightmares"), "of them" for a subset.
- Omen vs shape: every Omen that changes a shape says so in its own text, one clause: "Packs drifts: ...".
- Caps over multipliers: say the order ("at most 3 {leaves} in all, Omens included").
- Potency only where Potency's full glossary meaning applies; for damage-only boosts say "damage".

## 7. What works

- Every Dewdrop number now matches; boss slows are honest because the code was fixed, not the text bent.
- Firefly and Bellflower rows state rate limits, boss halves and "Slower Wardens deal less" consistently.
- The Codex "Calling hit" / "Free hit" / "Toll" / "Ring" entries make "Damage only. Triggers no other card." one rule.
- Shape fact lines are facts only (no "good against"), and numbers appear only after the Omen is picked.
