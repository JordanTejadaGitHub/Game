# Consistency seat: Roguelite round (2026-10-24)

Read: corpus_cards.txt, corpus_scripts_diff.txt, fixes_checklist.md; working tree `calling_paths.gd`, the changed
`resource/dream/*.tres`, `dream_reaction_cards.gd`, the rule code in `scripts/tower/tower.gd`, `scripts/run/*.gd`,
`scripts/combat/*.gd`, `enemy_statuses.gd`, Codex (`codex_data.gd`), tokens (`icon_info.gd`); dream_council_review.md 35.
Read-only. dream_state.gd is being edited by another chat: its line numbers drift by ~60. "(check)" = I am unsure of the intended mechanic.

## Job 1: fixes_checklist R1-R9

| # | Verdict | Evidence | Remaining fix |
|---|---|---|---|
| R1 Retinue | DONE | calling_paths.gd:85 "At most 2 other Wardens." = `RETINUE_MAX 2` (spore_print.gd:179, :1199) | - |
| R2 Lantern Alley | DONE | calling_paths.gd:156 parses | Nit: "within 4 {steps} of its last" -> "of its last glow". |
| R3 {tolls} / {water} | PARTIAL | {tolls} as a verb: gone from every live row (Down the Line :256 "When that one {tolls}" is retired). {water} still counted in 3 live tips: River Mouth :434 "once per {water}", Delta :438 "per {water}", Rapids :441 "once per {water}". Floodgate :374 "the water surges" is the raw word. | "per stretch of {water}" in all three; "the {water} surges". Same habit on a new token: Lantern Parade :159 "{flares} the nightmare" (verb) beside Lantern Alley :156 "takes a {flare}" -> "each of its Fireflies gives the nightmare a {flare}". |
| R4 Coda / Deep Tone / Accompaniment | DONE | :314, :295, :303 | - |
| R5 rows + tips over 40 | DONE | Constellation :222, Show the Way :213, Full Glow :216, Moth to Flame :187 ("on that nightmare"), Pyre :190 / Banked Fire :194, Toadstool Throne :78, Host Trees :102. Longest live tips now 40 words (Clump :66, Lantern Parade :160, Borrowed Light :207), none over. | Host Trees still opens "Shared Caps' Warden" (possessive of a card): "The Warden Shared Caps picks at each {mushroom} wears a cap". Its 2nd sentence breaks the token rule (P1). |
| R6 hit cards | DONE | All 7 % hit cards say "deal N% more damage" (Bearing Down, Clean Strike, Finishing Blow, Open Road, Nowhere to Run, Standing Tall, Trophies); their tips say "Direct hits only."; Tallest Tree card "up to 6 of its own hits' worth", tooltip "stored damage" (dream_hit_cards.gd:445), panel "store damage … empties the store" (warden_panel.gd:1421) | Carry-over outside the ten: P17. |
| R7 "set off" | DONE | dream_reaction_cards.gd:200 "each triggered", :203 "Reactions triggered: %d this run (you: %d)" | New nit P9. Codex combo name "Set Off" (codex_data.gd:123, :177) still open from round 3. |
| R8 "a pack" | DONE | Gathering Storm / Struck Twice tips say "group" | - |
| R9 Unfettered | DONE | "bonus hits" / "slow Wardens" gone | New undefined word "row" in its tip (F6 / P11). |
| Also: drift shape "Steady" | MISSING | drift_shapes.gd:22 `STREAM: "Stream"`, :66 fallback "Stream"; Codex codex_data.gd:22 "Stream: an even mix." | "Steady" in both (Main / UI owners, not Roguelite). No Roguelite text uses the shape name. |
| Also: Spire finale "Last drift" | MISSING | drift_panel.gd:494 "Finale (drift %d): clear it clean for a Rare dream"; rest_report.gd:493 "Finale cleared clean", :494 "Finale cost %d leaves" | Rename per the owner. **Warning:** "Last drift" already means "the previous drift" on screen: dream_effects.gd:991, :997, :1004 ("Last drift: 2.4 nightmares in range…"), drift_meter.gd:99, :454 ("Last drift 62 DPS"). Two meanings again; suggest "Final drift" (or rename the meter's to "Previous drift"). Owner call. |

Score: 8 DONE, 1 PARTIAL, 2 MISSING (the two "Also" renames, other chats' files).

## Job 2: new lines

### Fact mismatches (text vs code)

| # | Where | Text | Code | Fix |
|---|---|---|---|---|
| F1 | starlit_aim.tres tip | "Not {static} or {held}." | The crit chance uses `any_full()` (dream_state.gd:1901; enemy_statuses.gd:544-546), which counts every status, Charge and Root included; the cost `spend_half` never spends Root or Drowsy (enemy_statuses.gd:553-554). So full Charge does count (and is spent), and full Root / Drowsy give the crit for free. Section 35 said "full_status()" (dream_role_cards.gd:611, which skips Charge only). | WRONG either way. Route to Roguelite / Tower Code: use `full_status()` and decide Root / Drowsy, then the tip says what is left (e.g. "Not {static}. A full {held} or {drowsy} counts but is never spent."). |
| F2 | Starlit Aim, Guiding Light, Guiding Light II | "{full}" | Card "full" = 75% of the *base* cap, before Brimming (`FULL_SHARE` enemy_statuses.gd:535; firefly_lights.gd:1546). Codex "Full" (codex_data.gd:138): "A status at its most stacks … Brimming doubles them", and the full dot draws only at the most. With Brimming a card's "full" is 37.5% of the real most, and no dot shows it. | One meaning: either the code uses the real most (Codex is right), or the Codex adds "Cards that need a full status count it from three-quarters of its usual most." Owner / Balancing call. |
| F3 | eddy.tres description | "copy half the target's statuses to the next nightmare ahead and behind" | ONE nightmare: the nearest of those on the cells 1 step either side (tower.gd:5363-5364); half of *each status's stacks*, rounded up, at least 1 (:5370), not half the statuses. | WRONG. "{family:whirligig} Wardens' hits copy half of each status's {stacks} to the nearest nightmare 1 {step} ahead or behind. Each Warden once a second." |
| F4 | loose_stones.tres | "Every 3rd hit from a {family:pebbling} Warden breaks into 3 stones" / tip "Nearby: within 1 cell, corners too." | The counter skips area hits (tower.gd:3465 `not is_area`). Cairn, Rockslide and Old Mountain (`lob`, splash_share 1) land through `_splash` -> `hit(…, true)` (tower.gd:3940, :3989): those forms never break stones (check: the card named them before). Pieces land 0.5-1.5 cells away, snapped to a cell centre, 0.5-cell splash (tower.gd:5349-5351): can be the target's own cell or 2 cells out. | Code or text. If lobs are meant to count, route to Tower Code; else the tip must say "Not splash forms". Nearby: "within 1.5 cells" or fix the code to the 8 around (check). |
| F5 | conductive_soil.tres | "also {jumps} to up to 4 {damp} nightmares within 2 cells" | Each jump is `CONDUCTIVE_SHARE 0.5` of the hit (tower.gd:2711, :5330). Every other jump card states its size ("for half", "a third of the hit"). | Add "for half". 4 / 2 cells / once a second match (:2709-2712). |
| F6 | unfettered.tres | "even from Wardens that attack less than once a second" / tip "as often as its row allows" | The cap is `aps × period` per output (class_kit.gd:413-416); several Calling outputs pass their own period (keeping_time.gd:831, :835, :1174 Midnight), so a Warden at 1+/s can still be capped there (check). "Row" is defined nowhere. | "Calling hits always deal the Warden's full damage, however slowly it attacks." Tip: "Each evolution's own once-a-second (or once-per) limit still applies." |
| F7 | keyword chips (makes / uses) | - | guiding_light / _ii `uses [exposed]` (now Charge); starlit_aim `uses [exposed]` (now any full status); deep_frost no `uses` (Root); chain_bloom no `uses` (2+ statuses = layered). Tags "mark" (Guiding Light, Starlit Aim), "crit" (Deep Frost) stale. | Update chips to the new conditions (check that `uses` shows on the card face). |
| F8 | Codex vs rows (open from R3.3 #7) | - | "Toll" codex_data.gd:81 "lands again at half damage" vs Steady Beat :282 "in full", Last Bell :272 "the bell's damage, +7%…". "Flare" :84 "on a nightmare in its glow" vs Lantern Parade :159 (streak's end). "Free hit" :83 "at most once a second" vs Elder Cap :81 / Retinue :84 "each of its own attacks". | Codex entries: "usually"/"unless a card says otherwise", or name the exceptions. |
| F9 | code comments (not player text) | - | `RESONANCE_CHARGED 2` (dream_state.gd:6049, "+2 Charged", card says 1); Hairpin comments "Pinwheel or Windmill" (dream_state.gd:2074, :6073); `GUIDING_LIGHT` "needs Lanternmoth" (firefly_lights.gd:108). | Stale; tidy so the next text pass doesn't copy them. |

Numbers that match: Bearing Down 4% / 10% (dream_hit_cards.gd:39-40), Finishing Blow 40% / third / II (:36-38), Open Road 25% / 4 (:41-42), Nowhere 5% / 40% (:45-46), Trophies 10 / 5 / 4% / 40% (:50-53), Tallest Tree 20% / 40 / 6 (:60-62), Spinning Corners 35% (dream_state.gd:5990), Hairpin 6 / 30% (:6073-6074), Deep Frost 45% (:6125), Starlit 25% (:95), Grandfather 4% / 45% (tower.gd:93-94), Chain Bloom ×1.5 = "half again" (tower.gd:411), Loose Stones 35% / 3 / every 3rd (tower.gd:71, :2699), cross-status 1 a second (:2704), Eddy 1 s (:2700), Guiding Light half / 1 / 2 cells (firefly_lights.gd:109-110), Gathering Storm 25% / +200% / 2 s (:98-100), Afterroot 5 (dream_cooperation.gd:5).

### Term map (new / changed lines)

| Thing | Forms seen | Use |
|---|---|---|
| direct-hit tip | "Direct hits only." 11; "Direct hits only: …" 3; "Hits only, not status damage." 4 (Fruiting, Heavy Going, High Tide, Sodden); "Hits only, not statuses." 1 (Hunter's Patience); "Hits only." 2 (Towering, Shared Light) | "Direct hits only." |
| speed share | "Slower Wardens deal less." (18 tips); Codex "slower than the hit's clock deals a share"; Unfettered "attack less than once a second" / "its row" | one Codex sentence + one tip form |
| Phantoms | "the Phantom never" (calling_paths.gd:34, :41, :257); Codex "Phantoms" (codex_data.gd:98, :291) | "Phantoms never count." (plural, as the Codex) |
| route | "starts its route again" Drifting Spores :34, Deathcap :38 | "starts the path again" (check lap wording) |
| sleep | Eddy tip "sleep" | {asleep} |
| Heavy | Starlit Aim "Heavy Wardens" + tip "Heavy: the Warden header's Heavy tag" | `{heavy}` token exists (icon_info.gd:337): "{heavy} Wardens", drop the tip line |
| need text | "(you: N)" dream_reaction_cards.gd:200, :203; "(yours: N)" :205 | one: "(you: N)" |

### Phrase map

- **P1 status-adjective tokens** (icon_info.gd:17-18: "nightmares with {damp}", never "{damp} nightmares"): Conductive Soil "a {damp} nightmare … 4 {damp} nightmares"; Host Trees :102 "{spored} nightmares". -> "A {family:firefly_jar} Warden's hit on a nightmare with {damp} also {jumps} for half to up to 4 other nightmares with {damp} within 2 cells."; "…its direct hits on nightmares with {spored} deal 15% more damage."
- **P2 rate limits, 5 shapes** (rule 3): "Once a second per nightmare for each Warden." (Charged Feathers, Pollen Beaks, Thunder Chimes), "Once a second per Warden." (Conductive Soil), "Each Warden once a second." (Eddy), "once a second for each nightmare" (Crushing Depth :403), "Up to 2 a second for each Warden" (Trampled :69). -> "Each Warden once a second on each nightmare." / "Each Warden once a second."
- **P3 one copy mechanic, two shapes:** Carried on the Wind "all of a status's {stacks} instead of half" vs Eddy "half the target's statuses". Use F3's wording on both. Neither says Charge stops 1 short of its bolt (copy_quiet, enemy_statuses.gd:523-524), so "all" is not all for {static}: add "{static} stops 1 short of its bolt." (Millrace's old wording).
- **P4 family hit shape** (rule 15): Deep Frost "Wardens' hits deal 45% more damage" (no "direct", no tip) beside the T7 cards; Needle Point has no "Direct hits only." though its counter is original direct hits only (tower.gd:3465), as Loose Stones' tip says. Add the tip to both.
- **P5 Grandfather Stump:** "grow 4% … up to 45%" -> "{family:acorn} Wardens' speed auras give +4% attack speed for each Warden {touching} them, up to 45% in all." (cap is the aura total, tower.gd:2290).
- **P6 Moth to Flame :187:** "+50% after 4 more direct hits": +50% of what? (check: crit damage?) Say it.
- **P7 need text :203:** "Reactions triggered: 20 this run (you: 7)" reads like a stat. -> "Trigger 20 Reactions this run (you: 7)", like :205 "a Reaction chain of %d".

### Capitalisation / token breaks

- "a Rare dream" (drift_panel.gd:494, rest_report.gd:493) -> "Rare Dream".
- {toll} renders "Toll" (capital, icon_info.gd:332) mid-sentence by design; fine. {flares} as a verb (P above, :159).
- P17 carry-over (older cards, same rule 1): "N% more" without "damage": Fruiting, Heavy Going, High Tide, Sodden, Murmur, Hunter's Patience ("40% more to flyers"), Towering.

## Patterns

1. Section 35 swapped "Warden X" for "{family:} Wardens" well, but each rewrite re-coined its own rate-limit and status-adjective phrasing: check every family-wide rewrite against rules 3 and the icon_info noun rule.
2. A shared code word ("full" = 75%) was given to players under a Codex name that means something else: one meaning per glossary word.
3. Counts that say "the next ahead and behind" / "every 3rd hit" must be read against the target picker and the counter (Eddy, Loose Stones): both were wrong in the simplest reading.
4. New tokens get used as verbs the round after the old ones were fixed ({flares}): add {flare}, {free_hit}, {jump} to the R3 noun rule.

## What works

Every Firefly / Bellflower / Dewdrop / Sporeling row I checked against R3's list now parses; no live tip is over 40 words;
"glowing Firefly" is one word now; the hit cards share one shape; all 23 numbers above match their constants; Retinue matches.
