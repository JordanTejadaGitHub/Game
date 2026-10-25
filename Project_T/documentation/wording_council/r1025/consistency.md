# Consistency seat, round 2026-10-25

Read-only. Read in the working tree D:\Projects\Game\Project_T at about 17:00 on 2026-10-25. **The working tree is
moving:** Frost is being built there right now (uncommitted: enemy_statuses.gd FROST, icon_info.gd {frost} /
{frostburst} / {cold_snap}, codex_data.gd:128-130, frostfern / hoarfrost / tidecaller / windmill .tres, First Frost
renamed "First Grip", Deep Frost `retired = true`, "Never {held} or {frost}" added to 10 tips). Undiluted changed twice
while I read it. Line numbers are the working tree's.

---

## Job 1: fixes_checklist.md

**25 items: 19 DONE, 4 PARTIAL, 2 MISSING, 0 WRONG.** Main Merger's commit 59ae630f covered M1, M2, M4 and part of M3.
M5 and M6 were never applied.

| # | Status | Evidence | Fix still needed |
|---|---|---|---|
| M1 | PARTIAL | `drift_panel.gd:516` "Closing drift (drift %d): clear it clean for a Rare Dream"; `rest_report.gd:493-494`. "Last drift" stays on the meter (`drift_meter.gd:454`) and card lines (`dream_effects.gd:991-1004`). | `shape_rows.gd:110` still prints ", finales Packs / Single file / ..." on the drift 45 capstone screen. Say ", closing drifts ...". |
| M2 | DONE | `drift_shapes.gd:22` NAMES, `:66` fallback; `shape_rows.gd:84`; Codex `codex_data.gd:22`; rest report uses display_name (`rest_report.gd:345`). The Stream evolution (`calling_paths.gd:352`) is unchanged, as ruled. | (Only code comments still say "a Stream": `shape_rows.gd:75, :100`.) |
| M3 | PARTIAL | `shape_rows.gd:79` "Packs: %d packs of %d, %d s apart"; `:83` Few and tough OK; `:84` "Steady: 30 nightmares" OK. | `:81` says "Single file: 18 nightmares, 1.6 s apart". Ruled: "18 nightmares, one every 1.6 s". "Packs: 4 packs of 7" says "packs" twice (fine, or drop the label). |
| M4 | DONE | Codex "Drift shape" with the pack leaf cap `codex_data.gd:22`; "Nearly full" `:142`. | Nit: `:142` still names Called Shot, which is retired. |
| M5 | MISSING | Combo "Set Off" `codex_data.gd:123, :181`. "Face it" `omen_screen.gd:210, :212`. "Add, free" `remember_screen.gd:632`. Tooltip "Seed %d" `seed_picker.gd:89` (the "Map seed" head at `:94` already exists). "pick a square" `tower_placer.gd:1949`. "tiles" `results_screen.gd:354`, `dream_effects.gd:517, :790, :843`, puffball.tres:13 (new text). "leak" `rest_report.gd:257` and the new Headlong tip. "Pick a family" `drift_panel.gd:421`, `tower.gd:293`. "Grows into" `warden_header_view.gd:321`. "Grow into The Great Bell" `warden_panel.gd:368`, `tower_placer.gd:1949` (no IconInfo.name_in_sentence). | Apply all of the round 3 list. |
| M6 | MISSING | Codex "Free hit" `codex_data.gd:83` still says "at most once a second per Warden"; "Ring" `:82` still "a hit from a bell"; "Flare" `:84` still "in its glow". No "glow" entry anywhere in codex_data / icon_info. "Calling hit" `:87` is unchanged and 18 tips still end "Slower Wardens deal less." (`calling_paths.gd`). | Apply as ruled in R3.3 #7 / #8. The Unfettered tip now uses the Codex words ("clock", "share"), so only one rule needs to be written. |
| R1 | DONE | starlit_aim.tres:9, guiding_light / _ii.tres "nearly {full}". Called Shot is retired. | |
| R2 | DONE | starlit_aim.tres:20 "Nearly {full}: at least 3/4 of a status's usual most. Direct hits only." The "Not Charged/Rooted" line is gone. | |
| R3 | DONE | eddy.tres: nearest other nightmare, half of each status's {stacks}, {asleep}. | |
| R4 | DONE | loose_stones.tres "Nearby: within 1.5 cells. Area hits and stones never count"; code `tower.gd:71` 0.35, `:2779` every 3rd. | |
| R5 | DONE | conductive_soil.tres "for half", "These {jumps} don't count for other {jump} cards"; code `tower.gd:2789-2792` (2 cells, 4, 0.5, 1 s). | |
| R6 | DONE | grandfather_stump.tres "for each Warden in them, up to +45% faster in all"; `tower.gd:93-94`. | |
| R7 | DONE | `calling_paths.gd:187-188` crit at once, +50% after 4 more hits, gold dispels "this block's"; Pyre "all its dispels ... while it stands". | Nit: the card says "4 more hits", the tip "4 more direct hits". |
| R8 | DONE | `calling_paths.gd:103` "{potency} here: status and effect damage only". | The global Potency tip (`icon_info.gd:43` "stronger slows, longer {held}") still promises more. |
| R9 | DONE | unfettered.tres: "however slowly it attacks", clocks "1, 3 or 4 s", no "row". | |
| R10 | DONE | clean_strike.tres:9-10 matches `dream_hit_cards.gd:231-248`. | The face says "Hits deal 25% more" and the tip "Direct hits only.": two wordings. |
| R11 | DONE | "stretch of {water}" `calling_paths.gd:434, :438, :441`; {flare} as a noun `:159`; towering.tres "damage", "Direct hits only.". | |
| R12 | DONE | charged_feathers / pollen_beaks / resonance faces end "Each Warden once a second per nightmare." | |
| R13 | DONE | conductive_soil "a nightmare with {damp}"; Host Trees "nightmares with {spored}". | One live adjective is left: still_target.tres:17 "{frozen} nightmares". The others found are on retired cards. |
| R14 | PARTIAL | Starlit Aim {Heavy} (a valid capitalised token, `icon_info.gd:356`); Eddy {asleep}; Chain Bloom has no raw "Area"; Phantom shown as {nightmare:dandelion_seed}. | The new Hailfall brings raw "Area" back: hailfall.tres:9 "They count as Area, not single target", :10 "resist Area". Use "count as area attacks" (the Codex "Area attack" / "Splash" wording). |
| R15 | PARTIAL | Clump "uses 1 {mushroom}"; Throne "never used up", "keep coming"; Still Water "don't run down". | trophies.tres:9 "for the rest of this run" still uses the avoid-list phrase. Say "until the run ends". |
| R16 | DONE | Pyre / Banked Fire `calling_paths.gd:190, :194` "a Warden that has made 50 gold dispels". | |
| R17 | DONE | The Tallest Tree card is 21 words; panel `dream_hit_cards.gd:487` "fed by %d" / "Feeding the Tallest Tree: doesn't attack"; tooltip `warden_panel.gd:1432`; TALLEST_MAX_FEEDERS 8 (`dream_hit_cards.gd:63`). | |
| R18 | DONE | `dream_reaction_cards.gd:200, :203` "Needs %d ... (you have %d)". | |
| R19 | DONE | Unfettered tip; Clump tip `calling_paths.gd:66`. | |

---

## Job 2: text changed since 53ca7192

### Term map (live resources; counts are files)
| Thing | Names on screen now | Count | Ruling / fix |
|---|---|---|---|
| Splash radius | "nearby" (5: Dewdrop / Old Mountain / Puffball dream texts, Loose Stones, Puffball tower), "beside it" (21, header tip `warden_header_view.gd:501`), "near the one hit" (Codex Splash `codex_data.gd:133`), "within 1 cell" (Hailfall) | 3 words | The Codex "near" is a **defined term** ({near} = within 2 cells, 17 files). A splash is 0.6-1 cell. In the Codex Splash entry, say "beside the one hit". Pick one of "beside" / "nearby" for splashes. |
| The nightmare that takes the status | "the nightmare hit" (3), "the one hit" (3), "The nightmare it hits" (2) | 3 phrasings | "the nightmare hit" everywhere. |
| What it gains | "gains" (Dewdrop / Old Mountain / Puffball dream texts), "takes" (Puffball, Rain Lily tower texts), "give(s)" (Hoarfrost) | 3 verbs | Status: "gains N {x}"; damage: "takes". The Puffball tower text uses "takes" for both. |
| Splash shape word | Header chip "Splash" / "Splash + status"; Area role reads "Splash" (`warden_header_view.gd:391`); Hailfall "count as Area"; Codex "Splash hits count as area attacks" | Splash vs Area vs area | Owner: one shape word, Splash. Hailfall should say "area attacks" (lower case, the Codex term), not "Area". |
| Reaction lock | Afterglow / Spent Light cost "can't **set off** a {reaction} for 2 s"; Spattered tip "set off a {reaction} on a nightmare at most once every 2 s" | 3 uses of "set off", 2 phrasings | "set off" is the combo name "Set Off" (`codex_data.gd:181`, M5) and the round 3 avoid word; 18 files say "trigger". Write one line: "Its {stacks} can't trigger a {reaction} for 2 s." |
| Status pause | "wear off / wearing off" (12 files, Caught `icon_info.gd:26`, Bound and Burning, new Codex Cold Snap `:130`), "run down" (Still Water `calling_paths.gd:424-425`, after RR.3) | 2 | RR.3 moved Still Water to "run down". Pick one; I suggest "stop running down", and use it in Cold Snap too. |
| Boulders | "Mossy Boulders" (Forest Floor), "a boulder" (prompts) | OK | |
| Rush | Card "Rush it", button "Rush" / "Rush on", tooltip "Headlong: the next drift ..." | consistent | |
| Leak | Headlong tip "A leak loses no {dew}" (new), `rest_report.gd:257` | 2 | "A nightmare that reaches the Heartwood takes no {dew}." |
| Tiles | puffball.tres:13 "burst over a tile" (new text), 4 obstacles, `results_screen.gd:354`, 3 `dream_effects.gd` reasons | 9 | "cell(s)". The Puffball dream text already uses {field:puffball.splash_radius:cells}. |

### Fact mismatches (form text vs the unlock card, the data or the code)
1. **Dewdrop's own text is now wrong.** `resource/tower/dewdrop.tres:31` says "A small splash that hits a few nightmares and
   gives them {damp}". Since section 37, only the nightmare hit gains it, and the unlock card dream_dewdrop.tres already says
   so. Rewrite: "A small splash that hurts nightmares beside the one hit; only the nightmare hit gains {damp}. ..."
2. **Old Mountain**, tower/old_mountain.tres:14: "what it hits gains 1 {held}". The unlock card (dream_old_mountain) says
   "hurts nearby nightmares; the one hit gains 1 {held}". Section 37 asked for both texts to be rewritten; only the card was.
3. **Rain Lily**: the tower text (:14) says "which lasts longer"; the unlock card doesn't (data: status_duration 6,
   status_stacks 2). The two should match.
4. **Puffball** tower vs unlock: "a tile" vs {cells}; "takes ... {spored}; the others nearby take its damage" vs "hurting
   every nightmare there; the one hit gains". Use the unlock's wording.
5. **Tangled Lightning** (tangled_lightning.tres:9) has no reach and no tip. The code jumps within 2 cells
   (`dream_role_cards.gd:48` TANGLED_REACH) on direct hits. The card says "{family:firefly_jar} attacks", where every
   sibling card says "{family:x} Wardens' direct hits".
6. **Spattered scope (check)**: the tip limits *Dream-card* splashes to once a second per Warden, but `tower.gd:3779-3783`
   applies SPATTERED_WAIT to every Spattered splash, the Warden's own too.
7. **Hailfall**: "within 1 cell", "3 nearest", 40% all match `tower.gd:3765-3767`. Only the raw "Area" is wrong (R14).
8. Checked and matching the code: Slow Burn 30% / 4 s / 1.5 s (`dream_state.gd:2599-2601`); Wide Petals 0.75 (`:3761`);
   Spinning Corners 35% (`:6063`); Hairpin 6 cells / 30%; One Bough 2 / 25% (`dream_role_cards.gd:62-63`); Growth Rings
   rank III; Heartwood's Reach rank I; Forest Floor 2 / 20%; Headlong 1/3 (`drift_director.gd:212`); Chain Bloom x1.5
   (`tower.gd:413`); Loose Stones / Needle Point every 3rd (`tower.gd:2779`); Undiluted's {marked} from 5 / 10 with Brimming
   (working tree `exposed_need`).

### Capitalisation / token breaks
- `warden_panel.gd:368` "Grow into %s" shows "Grow into The Great Bell" (M5).
- dream_frostfern / tower frostfern (working tree): "When a nightmare's {frost} is full": a raw "full" where the {full}
  token belongs.
- Hailfall "Area" (capital, raw). The Codex says "area attacks".
- Headlong "Before any {drift} but a boss {drift}" reads like a garden path. Say "Before any {drift} except a boss
  {drift}, ...".
- `boulder_placement.gd:87` "click open ground ... (Esc to look round first)" is not wrapped in InputMode.text, unlike the
  Sell hints (`hud.gd:1135`). Phones would see "click" / "Esc" (check: the text filter in `ui_style.gd:314` may already
  swap PC words). The Waymark prompt `waymark_stone.gd:97-98` has the same issue.
- `pause_menu.gd` "Save & quit to desktop": the only "&" among the button labels (check the other quit labels).

### What already works
The "Never {held} or {frost}" line is added the same way on 10 tips. Callings now name the Phantom with a token. The
Tallest Tree card, tip and panel agree word for word. The Rush button says "Rush on", not colour alone. "Nearly full"
is one Codex line.

---

## Job 3: Frost texts (frost_draft.md 4-5, frost_review_player.md 6)

### 0. The rules in the brief are out of date
dream_council_review.md section 37 and the working-tree code have moved on from the draft's numbers (cap 10 / bosses 15,
burst 5x / 2.5x, Cold Snap 2 s / 1 s, Brittle 4 / 3 / 2 s, Frostbite 3 / 2 / 1%):
- Council: burst 3x / 1.5x; Frostfern 1 Frost a hit, Hoarfrost 2. Cold Snap 1.5 s (bosses 0.5 s), once per 6 s (bosses
  10 s). Brittle halves shells for 3 s (bosses 1 s). Frostbite 2% / 1.5% / 0.5%, outside the pool.
- Owner rulings: Rime is renamed **Flash Freeze**; Windmill is the second Frost Warden; and finally **cap 15 (bosses 22)**,
  burst 4.5x / 2.25x, chain and copied Frost stop 2 short (13).
- Working tree: `enemy_statuses.gd` has cap 15 / 22, `FROST_QUIET_SHORT 2`, `COLD_SNAP 1.5 / 0.5`, but `FROST_BURST 3.0`
  (not 4.5). Frostfern status_stacks 1, Hoarfrost 2, `FROST_CRIT_AT 5`. Codex `codex_data.gd:130` Cold Snap "1.5 s
  (bosses 0.5 s)".

So every Frost text that types a number ("At 10", "2 {frost}", "3 {frost}", "up to 9", "for 4 s", "3%") is already wrong
for at least one of the three sources. **Rule: no typed Frost numbers.** Use `{full}` / `{stacks:cap_frost}`,
`{field:frostfern.status_stacks:count}` (the working tree already does) and code-checked constants, as the Charged texts do.

### 1. Do the two sets agree with each other and with the draft's rules?
| Text | Draft | Player rewrite | Against the draft's rules | Notes |
|---|---|---|---|---|
| Codex Frost | "At 10 it bursts: damage around it, 1 Frost to those beside it, and its statuses pause 2 s." | "At 10 Frost ... hurting it and up to 4 beside it. They gain 1 Frost; its statuses pause 2 s." | Both say 10 / 1 / 2 s and leave out bosses (15, 1 s) and Brimming (20). The draft hides that the burst nightmare is hit (5x) and drops "4 nearest". The player version has it right. | "beside" matches "within 1.0 cell" (fine; Shatter uses it). "its statuses" should be "its other statuses" (Frost drains). The working tree already uses {full} and the {frostburst} / {cold_snap} links (`icon_info.gd:29`). |
| Codex Cold Snap | "... stop wearing off for 2 s (bosses 1 s)." | same | matches the draft | "wear off" vs "run down" (Job 2). Live: 1.5 s / 0.5 s. The once-per-6 s limit is in neither text. |
| Frostfern | "Its hits give 2 {frost}. At full {frost} ... hurting those beside it." | "At 10 {frost} ... hurting it and those beside it." | 2 matches the draft (live: 1) | The player's "At 10" is a regression: {full} is the right word (cap varies 10 / 15 / 20; live 15 / 22 / 30). Keep the player's "hurting it and". |
| Hoarfrost | "Splashing frost. Its hits give 3 {frost}, and it crits more ... 5 {frost} or more." | "Its hits splash and give 3 {frost}. +20% crit chance ..." | 3 matches the draft (live: 2) | **Both break section 37**: a splash gives its status only to the nightmare hit. The working tree adds "to the nightmare hit". |
| Tidecaller | "drags nightmares back 1 cell, and adds 2 {frost} to those with {frost}" | "drags ... and gives 2 {frost} ..." | matches | The unlock card (working tree dream_tidecaller.tres:10) says "**pushes it back 1 {step}**". The Grove node dewdrop_ascension.tres:9 still says "at 8 {damp} it is {frozen} for 1 s". That is three versions. |
| Windmill | "35% more damage per extra path cell ... Every second spin gives 1 {frost}." | "Every other spin gives 1 {frost} to each nightmare on its 8 cells." | matches (every 2nd spin, 1) | "Every second spin" reads as "each second": the player is right. The working tree text matches the player. The data cap `spin_bonus_max 1.0` (+100%) is in no text (check). |
| Hoar Fog | "The fog gives 1 {frost} a second to nightmares inside." | "... up to 9." | 9 = cap - 1 matches the draft | Live it stops at 13, and it changes with bosses and Brimming. Use the house precedent "{static} stops 1 short of a bolt" (6 tips): "**never enough to burst**". Neither text mentions the bond share. Codex combo text `codex_data.gd:306` still describes the old freeze. |
| Brittle | "A Frostburst on a nightmare with 10 {marked} spends it: for 4 s it resists nothing (bosses 2 s)." | "A Frostburst spends 10 {marked}: for 4 s the nightmare has no resistances or blight coat (bosses 2 s)." | 4 s / 2 s match; **elites 3 s missing from both** | The player version drops "on a nightmare with", so it reads as if the burst uses Exposure from anywhere. "blight coat" is a code word, not a screen word (see 3). |
| Frostbite | "... 12 {spored} spends half of it and deals 3% of its max health (bosses 1%)." | "... spends half and deals 3% ..." | 3% / 1% match; **elites 2% missing from both** | Live: 2 / 1.5 / 0.5%. "half" = the oldest half of the batches: fine. |
| Rime | "... 8 {damp} spends it: the burst reaches 2 cells and gives 2 {frost}." | Blizzard: "... reaches 2 cells, hits up to 6, gives 2 {frost}." | the draft leaves out "up to 6" | Owner chose **Flash Freeze** (see collisions). |
| Deep Frost | "Frostbursts deal 50% more and Cold Snap lasts 1 s longer." | "... and statuses pause 1 s longer after one." | | Retired in the working tree and by the council. Drop it. |
| Long Winter | "go one link further, and Cold Snap pauses Rooted too" | "can set off one more burst in a row" (Rooted clause dropped) | | Parked by the council. "set off" again. |
| First Frost | "First Chill" | "First Chill" OK | | Working tree: **"First Grip"** (pending the owner). The texts disagree. |

Token breaks in both sets: "Frostburst" is plain text in every Reaction line. It should be `{frostburst}`, which exists
in the working tree (`icon_info.gd:246`). Hard-coded "10 {marked}" / "12 {spored}" / "8 {damp}" should be
`{stacks:need_marked}` etc., as every other Reaction text does.

### 2. Name collisions (grep of resource/ and scripts/)
| Name | Collides with | Severity | Advice |
|---|---|---|---|
| **Frost** (status) | Status token **{frozen} "Frozen"**: `icon_info.gd:27` "Frost stops it for a moment." and Codex `codex_data.gd:127` "Frost's {held}: ... freeze adds 1 {held}". They say the exact opposite of "Frost stops nothing", and both are still live. Still used in still_target.tres:17 ("frost adds 1 {held}"), dewdrop_hidden.tres:9 ("it freezes nightmares that have {damp}", and it adds the retired {card:deep_frost}), dewdrop_ascension.tres:9, Codex Hoar Fog `:306`. Bound and Burning tip lists {warden:frostfern} as a Root Warden, which it no longer is. | **High** | Retire {frozen} with Frost, or rename it if any freeze is left. Fix the 6 texts in the same commit. |
| "freeze" words | Settings "Brief freeze on big hits" (`settings_panel.gd:218`, hit-stop); Omen **Frozen Ground** (no planting during a drift; 5 strings in tower_placer / tower_seller) | Low | Leave both. Neither is a status. |
| **Flash Freeze** (owner's pick for Rime) | the {frozen} / "freeze" family that means "can't move". A burst that "stops nothing" called *Freeze* breaks the player-seat rule "never imply a slow". No resource or script uses the name yet. | **Medium-high** | Flag to the owner. Blizzard (no collisions found) or Rime fit "stops nothing" better. If Flash Freeze stays, {frozen} must go. |
| **Brittle** (Reaction) | Omen **Brittle Night** (`resource/omen/brittle_night.tres:8`, also in the Grove node restless_omens.tres:9): "25% less health, ... twice as many {leaves}". Both mean "weaker nightmares", so a player will assume the Omen makes nightmares Brittle. | Medium | Keep both only if the Reaction's name is always the {named_combo:brittle} link. Otherwise the Omen could become e.g. "Thin Night". |
| **Cold Snap** | none (no "snap" anywhere in live text) | none | OK |
| **Blizzard** | none | none | |
| **First Chill / First Grip** | "Grip": only Deep Grip, which is retired. "Chill": none. | none | Owner to pick one. The working tree has "First Grip"; the draft and the player seat say "First Chill". |
| **Hoar Fog** | the existing Kinship (`kinships.gd:58`). Its Codex text `codex_data.gd:306` is the old freeze. | text | Rewrite with Frost. |
| **Windmill** | the existing Whirligig final (resource/tower/windmill.tres). Hairpin Winds and Spinning Corners are now family-wide, so there is no name clash. | none | |
| "chain" (Frostburst chains) | the **{chain}** glossary term (Reaction Chains, links; Afterglow "never add links to the {chain}"). Working-tree Codex Frostburst `:129` says "Up to 3 bursts in a chain", and the player seat wants a "Chain x2 / x3" callout. Frostbursts are not Reactions. | **Medium** | Say "Up to 3 bursts in a row" (the player's Long Winter wording), and use a "x2 / x3" callout without "Chain". |
| "burst" | Puffball "its puff bursts", Sparkler / Starburst bursts, spore-sprite "half a burst" | Low | "Frostburst" is distinct enough. Avoid a bare "bursts" in Frost lines; "Frostbursts" is fine. |

### 3. Brittle has to say "shell"
On screen, the blight coat is **{dread_shell}** ("dread shell", `icon_info.gd:244`). The Codex entry `codex_data.gd:110`
says "A shell that absorbs part of every hit", and the Armoured kind says "crack its shell" (`:563`). "Blight coat"
appears on no screen. Proposed text (draft numbers; swap in the live ones):
- Draft rule: "A {frostburst} on a nightmare with {stacks:need_marked} {marked} spends it: for 4 s it resists nothing and
  its {dread_shell} absorbs nothing (Deeply Blighted 3 s, bosses 2 s)."
- Council / live rule: "A {frostburst} on a nightmare with {stacks:need_marked} {marked} spends it: its {dread_shell}
  absorbs half as much for 3 s (bosses 1 s)."

### 4. Proposed text set (merged; no typed Frost numbers)
- Codex Frost: "Builds up on a nightmare. At {full} it bursts in a {frostburst}: it takes damage, up to 4 nightmares
  beside it take less and gain 1 {frost}, and its other statuses stop running down ({cold_snap})."
- Frostfern: "Its hits give {field:frostfern.status_stacks:count} {frost}. At {full} {frost} a nightmare bursts, hurting it
  and those beside it."
- Hoarfrost: "Its hits splash and give {field:hoarfrost.status_stacks:count} {frost} to the nightmare hit. +20% crit chance
  against nightmares with 5 {frost} or more." (5 = `tower.gd:3746`.)
- Tidecaller: one wording for the form and the unlock: "drags nightmares back 1 cell".
- Hoar Fog: "The fog gives 1 {frost} a second to nightmares inside, never enough to burst."
- Brittle: see 3. Frostbite: "A {frostburst} on a nightmare with {stacks:need_spored} {spored} spends half of it and deals
  N% of its max health (Deeply Blighted N%, bosses N%)." (Use whichever numbers the owner settles.)

---

## Counts
- Job 1: 25 items. 19 DONE, 4 PARTIAL (M1, M3, R14, R15), 2 MISSING (M5, M6), 0 WRONG.
- Job 2: 9 term clashes, 7 fact mismatches (Dewdrop and Old Mountain wrong after section 37), 6 token / capital breaks.
- Job 3: 13 texts compared. 4 disagree with the draft's own rules (elites left out of Brittle and Frostbite in both sets;
  Hoarfrost splash status in both; Rime "up to 6" in the draft). All typed numbers are stale against the live rulings.
  9 name checks: 3 high or medium-high ({frozen}, Flash Freeze, plus the 6 stale freeze texts under the {frozen} row),
  2 medium (Brittle vs Brittle Night, "chain" vs {chain}).
