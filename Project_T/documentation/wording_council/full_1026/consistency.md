# Consistency seat: full round 2026-10-26

Seat C (one name per thing, one phrasing per mechanic). Read: corpus_resources.txt, corpus_ui.txt, corpus_short.txt, the
working tree of D:\Projects\Game\Project_T (icon_info.gd, codex_data.gd, status_links.gd, the .tres files and the code
named below), against documentation/wording_council_review.md (section 6 and every round's decisions). Read-only.
Counts are lines in the three corpora (a line holding a word twice counts once) unless marked "words". Code comments
were left out.

---

## Job 1: fixes_checklist.md

| Item | Verdict | Evidence |
|---|---|---|
| **F1** Frost numbers through tokens; "It doesn't slow."; {frozen} retired; Old Mountain / World Root {held} | **DONE** | `scripts/ui/icon_info.gd:29` (Frost text = F.2, `{stacks:cap_frost}` / `{stacks:bosscap_frost}`); no `{frozen}` and no Frozen status left anywhere in scripts/ or resource/ ("Frozen Ground" is an Omen); `resource/dream/still_target.tres:9`, `still_target_ii.tres:9` say {drowsy} or {held}; `resource/tower/old_mountain.tres:14`, `world_root.tres:12` say {held}; Codex Cold Snap uses `{const:cold_snap}` (`codex_data.gd:130`, `:495`). |
| **F2** Frost family texts, Reaction shape, "in a row" | **PARTIAL** | Done: Frostfern Warden (`tower/frostfern.tres:14`), Hoarfrost Warden (`tower/hoarfrost.tres:14`), Hoar Fog (`codex_data.gd:307`), Brittle / Frostbite / Flash Freeze (`reaction/*.tres:10`, Crowned shape), First Grip (`dream/first_frost.tres:8-9`), Deep Frost retired (`dream/deep_frost.tres:19`), Codex Frostburst "Up to 3 bursts in a row" (`codex_data.gd:129`, = FROST_CHAIN_LINKS 3). **Not done:** (1) **Windmill** (`tower/windmill.tres:12`) says "Every other spin … to each nightmare there" (F.2: "Every 2nd spin … on those cells") and has **no tip** ("Its {frost} alone never makes a {frostburst}." is missing; no tip field). (2) **Tidecaller**: the Warden says "drags nightmares back 1 cell" (`tower/tidecaller.tres:12`) but its Dream card (`dream/dream_tidecaller.tres:10`) and Grove node (`meta/grove/dewdrop_ascension.tres:9`) say "pushes it back 1 {step}" and "everything in range"; the data is a path push (`push_back_tiles = 1.0`): all three should say "pushes nightmares back 1 {step}". (3) The Dream cards were not brought in line with their Wardens: **Frostfern** card "When a nightmare's {frost} is full it bursts, hurting it and those beside it" (`dream/dream_frostfern.tres:10`; Warden: "At {full} {frost} … up to 4 others within 1 cell"); **Hoarfrost** card "to the nightmare hit" (`dream/dream_hoarfrost.tres:10`). (4) **Base Reactions** are still in the old shape, "Needs … Uses up …" with rules after the "Uses up" (all 10: `reaction/drown.tres`, `ignite`, `lightning_rod`, `mushrooming`, `night_terror`, `pinned`, `shatter`, `sleepwalk`, `smother`, `thunderclap`); only the 3 Frost and 10 Crowned Reactions say "Triggered by". If the F.2 ruling covers every Reaction, 10 to go. |
| **F3** Splash, "set off", Main's M5 / M6, shape rows, Codex | **PARTIAL** | Done: Warden splash texts say "the nightmare it hits" (Dewdrop `tower/dewdrop.tres`, Old Mountain, Puffball, Rain Lily, Hoarfrost); Codex Splash says "beside", no "near" (`codex_data.gd:136`); Hailfall ("Wardens without a splash gain one", `dream/hailfall.tres:9`), Tangled Lightning (2 cells, full hit), Spattered ("Each Warden's splash"), Eddy ("1 step either side on the path") rewritten; Afterglow / Spent Light / Spattered free of "set off"; M5: "Face it" → Continue (`omen_screen.gd:210`), "Add branch (free)" (`remember_screen.gd:632`), "Map seed %d" (`seed_picker.gd:89`), no "Pick a family", "the Great Bell" mid-sentence (`tower.gd:296-298` grow_name), M6: Free hit / Ring / Flare / Glow / Calling hit entries (`codex_data.gd:77-88`); shape rows "4 packs of 7, 6 s apart", "18 nightmares, one every 1.6 s" (`shape_rows.gd:79-84`, finales now "Closing drifts"); Codex "Nearly full" without Called Shot (`codex_data.gd:142`). **Not done:** (1) the four **Dream evolution cards** keep the old splash wording: `dream/dream_dewdrop.tres:10` "only the one hit gains {damp}", `dream_hoarfrost.tres:10` "to the nightmare hit", `dream_puffball.tres:10` "the one hit gains", `dream_rain_lily.tres:10` "the nightmare hit gains". (2) **"set off" in 6 places** (forms the old sweep's regex missed): `reaction/pinned.tres:11` "when that set it off", `dream/dawnbreak.tres:10` "sets one off", `codex_data.gd:39` Chain "Reactions setting each other off", `lesson_card.gd:224` "Other statuses can set it off early", `status_links.gd:215` "set it off in a run to learn it", `enemy/hedgehog.tres:17` hint "sets it off". (3) M5 leftovers: "tiles" `codex_data.gd:310` (Lantern Roots "lit tiles"); "squares" `codex_data.gd:94` and `distance_diagram.gd:10` ("2×2 of the small squares you place on"); "Grows into" as a heading `warden_header_view.gd:321` (the panel says "Grow into", `warden_panel.gd:1497`); "leak / leaked / kills by route" only in the copied run report (`run_history.gd:922, :962, :970`). |
| **H1** Hollow tooltip line, Codex entry, `{const:fed_lock}` | **DONE** | Tooltip line `nightmare_info.gd:463` (HOLLOW_LINE, shown only while `is_fed`, `:368-375`), Codex entry `codex_data.gd:143` with the pip picture (`nightmare_info.gd:499-504`), `{const:fed_lock}` filled from EnemyStatuses.FED_LOCK (`codex_data.gd:496`). Text matches the ruling word for word. |
| **N1** Grow vs Nurture | **PARTIAL** | Done: Wild Growth and Hard-Won Rings as ruled (`dream/wild_growth.tres`, Hard-Won Rings' tip); Quiet Rings (`dream/growth_rings.tres:8`, `dream_batch_rules.gd` reads the card's name, fallback "Quiet Rings"); every Calling row says "Nurture {rank}" (`calling_paths.gd:69, 72, 88, 295, 298, 301, 384, 387, 390, 408, 415`); Codex Grow / Nurture / Nurture rank (`codex_data.gd:48-50`); {rank} links to "Nurture rank" (`icon_info.gd:273`); bud icon for {grow} (`status_links.gd:130-138`); Boosts lens has its own icon (`hud.gd:1446`). **Not done:** bare "{rank}" / "rank" in 15 player strings and non-form "grow" in 27 (lists in Job 2, rows T1-T2): e.g. `tower/grove_keeper.tres:14` "start at {rank} II", `tower/mother_log.tres:14` "keeps its {rank}", `meta/grove/tending_hands.tres:9` "nurtured to {rank} VII", `dream_batch_rules.gd:267` "no free rank at the next rest", `lesson_card.gd:431-432` "Each rank lets you choose", `warden_panel.gd:458, 473, 494, 648, 654, 662` "rank"; `tower/sunpetal.tres:13` "grows stronger", Codex Glow / Lit "more as its range grows" (`codex_data.gd:77-78`), Kinship "grow stronger" (`:66`). Grove nodes still say plain "can grow into" (9 hidden-branch nodes) and "600 {dew} grows a {final_form} into it" (9 Ascension nodes) where the rule says {grow}. |
| **X1** Flashover | **DONE** | `dream/flashover.tres:9` exactly the ruled text; tip names "{warden:sparkler} and {warden:starburst} {near} another one" (`:10`). |

**Score: 3 DONE (F1, H1, X1), 3 PARTIAL (F2, F3, N1), 0 MISSING, 0 WRONG.**

---

## Job 2: term map (every concept named more than one way now)

Counts are lines; "tok" = through a token.

### T1. Rank (Nurture) — rule: "Nurture {rank}" every time
| Name in use | Count | Where |
|---|---|---|
| Nurture {rank} / Nurture rank | 46 tok + 10 plain | cards, Calling rows, Codex, icon_info |
| bare {rank} / {ranks} | 5 | `grove_keeper.tres:14` "{rank} II", `mother_log.tres:14` "keeps its {rank}", `tending_hands.tres:9` "{rank} VII", `first_care.tres:9` "{nurture} {ranks}", `heartwood_gifts.gd:61, :81` "2 free {ranks}", "keeps its {ranks}" |
| bare "rank" (plain) | 15 | `heartwoods_reach.tres:18` "a Sprout keeps its rank"; Codex `codex_data.gd:58-59` "The rank V reward for four matching ranks", `:304` "arrives at rank I"; `lesson_card.gd:431, 432`; `warden_panel.gd:443, 458, 473, 494, 648, 654, 662, 2608`; `dream_batch_rules.gd:267`; `dream_state.gd:4339` "a free rank waits"; `dream_effects.gd:820`; `gift_screen.gd:56, 70`; `signatures.gd:38-39` "Mixed ranks", "Four ranks"; `settings_panel.gd:182`; "Top rank" toast `warden_panel.gd:1278` |
| "Nurture Rank %s" (capital R) | 1 | `warden_panel.gd:461` |

### T2. Grow — rule: forms only
| Use | Count | Where |
|---|---|---|
| form grow, through {grow} | Dream evolution cards (~95) | fine |
| form grow, plain "grow(s) into" in rules text | 21 | 9 Grove hidden-branch nodes "can grow into" (`meta/grove/*_hidden.tres:9`), 9 Ascension nodes "grows a {final_form} into it", `living_walls.tres` "grows into a {warden:bramble}", Codex Sprout / Thornwall (`codex_data.gd:52, :63`). Ascension Dream cards say "can **ascend** into" for the same step: one action, two verbs |
| non-form "grow" (rule says change it) | 27 | **Wardens / cards:** `sunpetal.tres:13` + `firefly_jar_hidden.tres:9` "a beam that grows stronger"; `bastion.tres` / `rampart.tres` role lines "grows with walls"; `grove_keeper.tres:14` "Grows a free Sprout seed", `seedbearer.tres` "it grows a seed"; `mushrooming.tres` "A spore cloud grows". **Codex:** `codex_data.gd:13` "growth" (Dew), `:66` Kinship "grow stronger", `:77-78` Glow / Lit "more as its range grows", `:80` Water "its evolutions grow it", `:138` "Effects grow with Potency", `:149, :155` "grown in the Memory Grove", `:304` "grow 10% cheaper" (form: ok), `:308` Sunspot "shots grow +10% per hit", `:318` "the bond grows". **Run / gifts:** `heartwood_gifts.gd:41` "It grows at each later {act} break", `:67` "The strike grows", `:79` "their bond grows one step", `gift_screen.gd:64` "A Kinship grows a stage", `gift_screen.gd:271` "The %s grows"; `calling_paths.gd:199` "grows it 1 more … Grown gold"; `dream_screen.gd:307` "Your Calling grows"; `boss_dossier.gd:669` "this run's growth". **Grove (grow = unlock):** "Grow to level %d", "Grown", "Grows by itself", "This node grows in the full game" (`grove_screen.gd:423-433`), "Seeds grow permanent unlocks" (`results_screen.gd:182`), "One more branch grows in the Memory Grove" (`remember_screen.gd:553`), "Your Memory Grove keeps growing" (`grove_screen.gd:107`) |

The Grove's "Grow / Grown" for buying a node is the biggest leftover: the same word on the same player's screen means
"unlock a node" between runs and "change form" in a run. (Owner call: the Grove's tree image may be worth keeping; if so,
say it in the Grow vs Nurture rule as the one exception, like mushrooms.)

### T3. Root (status {held}) — one status, six names
| Name | Count | Where |
|---|---|---|
| {held} → "Root" | ~140 tok | everywhere |
| "Roots" (role-line verb) | 7 role lines | ruled: role lines keep verbs |
| "Hold" (role tag chip) | 1 table | `warden_header_view.gd:383` ROLE_TAG_NAMES HOLD: "Hold" (next to the "Root" status on the same panel) |
| "Rooted" (card / node names) | 3 | Rooted Nightmares (`dream/rooted_nightmares.tres`, `meta/grove/rooted_nightmares.tres`); Root as damage type "Root" (`icon_info.gd:69`) |
| "can't move for N s" spelled out next to {held} | 23 | e.g. `old_mountain.tres:14` "gains 1 {held} and can't move for 0.5 s", `world_root.tres:12`, `first_frost.tres:9`; rule 11 short form "1 {held} for N s" used nowhere |
| "Roots" as a thing that gives Root | 2 | `heartwood_gifts.gd:75` "Roots cover the last 6 cells", `rest_report.gd:79` "gave Roots to %d nightmares" (plural of the status: reads as the status counted) |

### T4. Old status words left as raw text (token exists)
| Raw word | Count | Where |
|---|---|---|
| "Soaks" (rules text) | 1 | `tower/torrent.tres:15` "a wet trail … that Soaks nightmares" → "gives nightmares {damp}" |
| "Soaked" | 1 name | card **Soaked Rot** (`dream/damp_rot.tres:8`): the only card name still using the retired adjective (status is "Soak" since 2026-10-17) |
| "Exposed" | 2 | Codex combo **Exposed Blow** (`codex_data.gd:183`, related link `:123`); section 6 listed it as leaking: the status is "Exposure" |
| "sleep" (= Asleep, rules text) | 3 | Codex Cold Snap "Not {held}, sleep or slows" (`codex_data.gd:130`), Fever Dream "Bosses: no sleep" (`reaction/crowned/fever_dream.tres`), rest report combo "Put to sleep" (`rest_report.gd:10`); ruling 1: plain sleep in rules text says {asleep}. Flavour uses (Barrow King, Huntsman, Sleepless, Wilting, Watcher "Never sleeps") are fine |
| "asleep" lower, plain | 2 | Grove `meta/grove/bellflower.tres:9` "until they fall asleep" (no token); `enemy.gd:2039` "can't fall asleep again" |
| "freezes" (Frost doesn't freeze) | 1 | `meta/grove/dewdrop_hidden.tres:9` "it freezes nightmares that have {damp}" — wrong since section 37; also "Also adds the {card:deep_frost} card", a retired card |
| "chills" | 1 | `dream_keywords.gd:65` Frost chip "it bursts and chills the nightmares beside it": an undefined third verb for Frostburst's Frost |
| "elites" (= Deeply Blighted) | 2 | Brittle and Frostbite (`reaction/brittle.tres:10`, `frostbite.tres:10`) "(elites 2 s, bosses 1 s)" — the F.2 text itself, but the one name is **Deeply Blighted** (icon_info has `{deeply_blighted}`) |
| "Poisoned", "Charged", "Drowses" (rules text) | 0 | clean (only role lines and dream_keywords ids) |
| "Frozen" status | 0 | clean |

### T5. "set off" (rule 10: trigger)
6 left (Job 1 F3 list). Plus "Set off N / Fed N" survives only in a code comment (`tower.gd:1183`).

### T6. Distance words (rule 7 and the 2026-10-19 distance words)
| Word | Count | Note |
|---|---|---|
| {touching} | 78 tok | defined |
| raw "touching" / "touches" / "touch" | 25 / 9 / 8 words | e.g. `briar_crown.tres`, `dream_jarlink.tres`, `hedgerow_roots.tres`, `shared_light.tres`, `heartwood_gifts.gd` ("Wardens touching it deal 30%"), `gift_screen.gd`, `warden_panel.gd` Tallest Tree line, Codex Arc / Water / Fault Line. Same meaning as the token, so they should be the token |
| {near} | 23 tok | defined: 2 cells |
| raw "near" | 30 words | nightmare abilities (`mourning_mother`, `lamplighter`, `watcher`, `will_o_wisp`, `nightmare_icons.gd`), gifts ("Wardens near the Spring / Moonwell"), Caught ("near a Dreamcatcher", `icon_info.gd:26`, `codex_data.gd:184`), `dream_deeproot.tres` "near the Heartwood", `winding_roads.tres`. With a defined {near} = 2 cells, a raw "near" reads as 2 cells too |
| "nearby" | 6 | `dream_dewdrop.tres`, `dream_old_mountain.tres`, `dream_echo_hollow.tres`, `loose_stones.tres:18` (**defines its own "Nearby: within 1.5 cells"**), `dream_keywords.gd` |
| "Nearest: within 2 cells" (local definitions) | 3 | Hammerfall, Brushfire tips; Loose Stones' "Nearby: 1.5": three cards each define a distance word for themselves |
| "beside" | 49 words | undefined; Codex Splash uses it as the splash reach, Ignite / Shatter / Frost chip / Fever Dream / gifts use it loosely |
| "around it" / "the 8 cells around it" | 24 | = {touching} for Wardens (Pinwheel, Windmill, Mother Log "the 8 cells around it") |
| "neighbour(s)" | 8 | Graftling / Grafted Elder / Codex Kinships, Fever Dream "its neighbours" |
| "next to", "close by" | 2, 1 | `nightmare_icons.gd` "Thornwalls next to it", `calling_paths.gd` "the path next to them", `mossback.tres` "close by" |
| raw "step(s)" vs {step}/{steps} | 30 raw vs 64 tok | raw "step" also means **a stage**: Codex Branch "A second-step form", Final form "The third step of a branch", `heartwood_gifts.gd:79` "bond grows one step", `signatures.gd` "one step stronger"; and the path unit raw in `eddy.tres:9` "1 step either side" |

### T7. Phantom / flyers
"Phantom" is now one nightmare's name (`enemy/dandelion_seed.tres` display_name "Phantom"); Warden texts link it
(`{nightmare:dandelion_seed}`: nestling, wrens_nest, lightning_fence). Still plain: `dream/dream_nestling.tres:10`,
`dream_wrens_nest.tres:10`, `dream_starling_murmuration.tres:10` ("Phantoms and sprinting Night Hounds"),
`dream_lightning_fence.tres:10`, Codex Arc (`codex_data.gd:99` "catches Phantoms gliding through"), Kinship Flock Together
(`codex_data.gd:296` "+25% vs Phantoms"). 6 lines: plain names skip the ??? rule and don't link. "Night Hounds" plain too
(the Wardens say `{nightmare:hedgehog}`).

### T8. Route / path
"path" is the word (hundreds). "route" in player text: 9 lines: `longer_roots.tres:18` caption "touches the route",
`walking_wood.tres:10` "The route never changes", `flyer_warning.gd:14` (constant name only: text says "path"),
`gift_screen.gd:824, :826` "route %d cells", `rest_report.gd:284` "% along the route", `dream_batch_rules.gd:643` "Your
route: %d bends", `:654` "Gauntlet path on your route", `calling_paths.gd:35, :39` "starts its route again", plus the
run report (`run_history.gd:919, 962, 963`). Also "Path length" (resource) vs "cells of path".

### T9. Tiles / squares / cells
"cell" is the word. "tiles": 1 (`codex_data.gd:310`). "squares": 2 player strings (`codex_data.gd:94`, `distance_diagram.gd:10`)
for the half cell; "square" also = the dashed outline (`codex_data.gd:93`, fine). The half cell has no name of its own.

### T10. Leak / dispel / kill
"dispel" is the word. "kill(s)": 3 card tips: `momentum.tres:15` "a kill never drops it", `quickening_ii.tres:10` "while
kills keep coming", `waymark.tres:10` "a kill zone" (rule 17: dispel). "leak": run report only (3). "defeat": Codex Dispel
definition (fine, it defines).

### T11. Buff / boost
Header and lens: "Boosts" (`warden_panel.gd:846`, `hud.gd:1447`). "buff": 0 in player text. But **"boost" has two
meanings**: a Warden's aura bonus (Boosts lens, role lines "boosts damage", Codex Boosts) and a nightmare's ability
(`magpies_hoard.tres` "removes a boost from its target", `dream_magpie_perch.tres` "steals a boost", `codex_data.gd:296`,
`:313` "steals a nightmare's boost", "Omen boosts fall away"). 24 lines in all, about 6 on the nightmare side.

### T12. Chain
{chain} = the Reaction chain (glossary "Chain"). Also: role tag **"Chain"** for lightning Wardens (`warden_header_view.gd:382`,
same panel family as the glossary link); "Reaction chain" plain (`whispering_hollow.tres:12`, `dream_reaction_cards.gd:205`),
"the chain" (`combo_feedback.gd:435`), "Longest chain ever: Chain %d" (`codex_panel.gd:2237`). F.2 moved Frost to "in a
row" for this reason; the role tag is the same clash.

### T13. Calling
"Calling" (cards, Codex entry) vs the Codex glossary **group "Classes"** (`codex_data.gd:74`) holding the Calling words;
Calling lines called "{calling} paths" (`bound_and_burning.tres` "the Witch Ring and Drowned Hands {calling} paths": path
= the walk), "style" / "Follow-up" / "Capstone" / "Finale" stages (`dream_screen.gd:569`), "evolution" (Codex, tips,
settings). Also "calling back" a branch (`wider_roots.tres`, Codex Deepen) beside the Calling.

### T14. Declining an offer
"Let it pass" (Dream, 4), "Skip the gifts, +%d" (gifts), "Skip the Omen" / "Clear Skies" (Omen, `omen_screen.gd:615, 622`),
Lesson "You can skip it" (`lesson_card.gd:585`); Restless Dreams "you can't let it pass" (`restless_dreams.tres:10`).
Three verbs for one action (owner's names may be deliberate: flag only).

### T15. Last drift
"Last drift" = the previous drift (meter, card lines: 5); "the last drift" = the run's final drift (`drift_panel.gd:261`
"The last drift is walking", `boss_dossier.gd:676` "the last drift of the act"); button "Final drift" (`drift_panel.gd:262`);
"Closing drift" = Spire block finale (`drift_panel.gd:520`) and "Closing drifts" = every block's 5th (`shape_rows.gd`, same
concept, fine). The RR.4 clash is back from the other side: "last drift" still means two things.

### T16. Bosses phrasing (rule 9: "(bosses N)" after the number)
"Bosses take half" 30, "(bosses N)" 19, "(N on bosses)" 11 (all status tooltips: `icon_info.gd:20, 23, 29` and their
Codex copies), "Never bosses" 8, "Bosses: …" 8, "Not bosses" 3, "Bosses don't count" 1 (`first_frost.tres:15`), "bosses
half" / "(bosses half)" 2. Two orders for the same parenthesis.

### T17. Direct hits (rule 14: "Direct hits only" in that one form)
"Direct hits only." 9; "Hits only, not status damage." 5 (Fruiting, Heavy Going, High Tide, Sodden; `hunters_patience`
"Hits only, not statuses."); "Hits only." 1 (`shared_light.tres`); Opening Fracture "Direct hits only: a hit on one
nightmare, not an area attack, beam or status damage" (`opening_fracture.tres:16`) **redefines** the term: the Codex
Direct hit (`codex_data.gd:137`) doesn't exclude area attacks or beams. 16 lines, 4 wordings.

### T18. Status damage / effect damage (ruling 7: "status damage")
"status damage" 7 (cards); "effect damage" 3 (`mushrooming.tres` "30% more effect damage", `nightmare_info.gd:250`
"Nightshade ×%s effect damage", `calling_paths.gd:104` "status and effect damage"); and the Codex entry is still named
**"Effect"** (`codex_data.gd:138`), related from Area attack / Direct hit. The ruled name has no Codex entry.

### T19. Wear off
"wears off / wearing off" 13, "runs down / running down" 5 (Codex Cold Snap "stop running down", 4 Calling rows), "runs
out" 3 (Ebb, Last Drop), "fades" 3 (Struck Twice, Thousand Cuts, Elf Circle). One mechanic (a status's clock), four verbs.

### T20. Rate limits (rule 3, subject first)
"Each nightmare once every N s" 18, "Each Warden once a second" 11, bare "Once a second." 7, "Each nightmare once a
second" 6, "Once per nightmare" 6, "At most once every N s" 6, "At most once a second" 3, "once a second for each
nightmare" 2, "Once a second per Warden" 1, "At most once a second per Warden" 1. Bare forms (no subject): 17.

### T21. Every 2nd (rule 4)
"every other" as "every 2nd": 1 left, Windmill (`windmill.tres:12`). Other "every other" (Mycelium, Undiluted, Starfall,
Marsh Lights, King Tide) mean "each of the others": fine, but 5 uses of the phrase beside the rule's ban.

### T22. Area / splash / pulse
Role lines "Area damage" 25 vs "Splash damage" 10 vs "hits all around it"; cards "Area attacks" / "Area hits" / "Area
Wardens"; chip "Area"; Codex "Area attack" (no token: `{splash}` exists, `{area}` doesn't). Fine as terms; listed so the
seats don't count it twice.

### T23. Spelling (UK, ruling 2)
US forms in player text: **0** (color / center / gray / neighbor / armor / -ize all clean; "meter" is the gauge, fine).
"toward" 10 vs "towards" 1 (`whispering_hollow.tres:12`): UK usage prefers "towards"; pick one (house style can say
"toward"; then fix the one "towards").

### T24. Buttons (G.3)
| Action | Now | Verdict |
|---|---|---|
| Close a panel | "Close" 19; "Done" 0 | done |
| Past an info screen | "Next" in a sequence, "Continue" at the end (`lesson_card.gd:607`, `nightmare_intro.gd:309`); "Got it" 0 (comments only) | done |
| Start a run | "New run" title + results (`title_screen.gd:103`, `results_screen.gd:209`); "Start run" Grove, loadout, Blight picker (`grove_screen.gd:262`, `loadout_panel.gd:76`, `blight_picker.gd:62`) | done |
| Group plant | PC "Plant %d"; phone `touch_build.gd:169` "Plant %d" but built as **"Confirm"** (`touch_build.gd:71`) until the first refresh | done, check the first frame |
| Omen | "Face an Omen" title, "Choose an Omen" button (`drift_panel.gd:302`), "Skip the Omen" | done |
| Back vs Cancel | "Back" 6, "Cancel" 6: different jobs, fine | |
| Abandon | "Abandon run…" (`pause_menu.gd:235`) and "Abandon this run…" (`pause_menu.gd:400`) | two labels for one action |

---

## Phrase map (one mechanic, several phrasings)

| Mechanic | Phrasings now (count) | Use |
|---|---|---|
| Reaction trigger line | "Needs X + Y. Uses up …" (10 base) vs "Triggered by … Uses up …" (13) | the F.2 shape for all |
| A status's stack gate | "At {stacks:need_x} stacks it can trigger" (tooltips), "with {stacks:need_x} {x}" (Reactions), "nearly {full}" (cards) | fine (three different thresholds) |
| Splash target gets the status | "the nightmare it hits" (Wardens, Codex), "the nightmare hit" (2 cards), "the one hit" (2 cards) | "the nightmare it hits" |
| Pushback | "pulled back 1 {step}" (Rootcurl), "pushes it back 1 {step}" (Tidecaller card / node), "drags nightmares back 1 cell" (Tidecaller Warden), "drags the nightmare … back beside its pond" (Pond Keeper) | "pushes / pulls … back N {steps}" |
| Can't move | "gains 1 {held} and can't move for N s" (23) | rule 11: "1 {held} for N s" (Root's tooltip already says it can't move) |
| Flyers vs the maze | Lesson "Flyers ignore your maze and go straight for the Heartwood" (`lesson_card.gd:438`); flyer warning "They fly along your path, above your walls" for route flyers (`flyer_warning.gd:14`); "Flyers pass over" (mushrooms, Spent Light); "Flyers fly straight past" (Waymark) | see fact F7 |
| Card stacks gate | "can't trigger a {reaction} for 2 s" (Afterglow cost), "can trigger a {reaction} … at most once every 2 s" (Spattered tip), Hollow entry "no Reaction can trigger on it" | Hollow wording (it is the same lock, FED_LOCK) |
| Distance definitions inside tips | "Nearby: within 1.5 cells" (Loose Stones), "Nearest: within 2 cells" (Hammerfall, Brushfire), "Passed: stepped on a path cell sharing a side with it" (Bitter Hedges) | defined words, or "within N cells" in the card |

---

## Fact mismatches (text vs data / another screen)

| # | Where | Says | Data / other screen |
|---|---|---|---|
| F1 | `meta/grove/dewdrop_hidden.tres:9` | Frostfern line "freezes nightmares that have {damp}"; "Also adds the {card:deep_frost} card" | Frost doesn't slow or freeze (`icon_info.gd:29`); Deep Frost `retired = true` (`dream/deep_frost.tres:19`) |
| F2 | Tidecaller: `tower/tidecaller.tres:12` vs `dream/dream_tidecaller.tres:10`, `meta/grove/dewdrop_ascension.tres:9` | "drags nightmares back 1 cell" vs "pushes it back 1 {step}"; "{damp}" vs "everything in range {damp}" | one push of `push_back_tiles = 1.0` along the path |
| F3 | Frostfern card `dream/dream_frostfern.tres:10` | bursts "hurting it and those beside it" | up to 4 within 1 cell (FROST_NEIGHBOURS 4, FROST_REACH 1.0, `reactions.gd:2219-2220`) — the Warden text says so |
| F4 | Windmill `tower/windmill.tres:12` | no tip | F.2: its Frost alone never makes a Frostburst |
| F5 | Opening Fracture `dream/opening_fracture.tres:16` | "Direct hits only: … not an area attack, beam" | Codex Direct hit (`codex_data.gd:137`) counts any Warden's own attack landing (check which the code does) |
| F6 | Mother Log `tower/mother_log.tres:14` | "Wardens in the 8 cells around it pay 35% less to Nurture" | its Dream card uses `{field:mother_log.special_params.nurture_discount:pct}`; the Warden text types 35% (stale-risk; check it equals the field) |
| F7 | Lesson Flyers `lesson_card.gd:438` | "Flyers ignore your maze and go straight for the Heartwood" | route flyers (Crow, Night Kite, Gloamwing, Pall, Moth Queen) fly along the path (`flyer_warning.gd:14`, their .tres "Flies along the path") |
| F8 | Codex Cell `codex_data.gd:94`, `distance_diagram.gd:10` | "2×2 of the small squares you place on" | correct, but "squares" is the retired word and the half cell has no name |
| F9 | Brittle / Frostbite | "elites" | the Deeply Blighted entry (`codex_data.gd:109`) never says "elite"; a player can't map it |
| F10 | `codex_data.gd:39` Chain | "Reactions setting each other off within a second" | CHAIN_WINDOW 1.0 (`reactions.gd:18`): number right, verb old |

Checked and matching (no row): Wellspring 260 (`dew_catch.gd:12`), Power 18% / Swift 15% / Reach 0.3 / Deep 25% /
rank 0.1 cells (`tower.gd:247, :433-436`), Kindred 10% / Whole Tree 20% / Harmony 2 s per pair (`kinships.gd:28-32`),
Deeply Blighted ×3 health and triple pot share (`enemy.gd:63`, `drift_director.gd:860`), Restless +20% (`enemy.gd:585`),
Dawnburst 10 / Dawnbreak 10% / 2% / 4 cells (`reactions.gd:101-104`), Frost chain 3 / 4 / 1 cell, family picks after 1,
10, 40 and the drift 60 deepen (`drift_director.gd:46`).

---

## Job 3: capitalisation and token breaks

### Token breaks (raw word where a token exists)
| Where | Raw | Token |
|---|---|---|
| `dream/eddy.tres:9` | "1 step either side" | `{step}` |
| `tower/torrent.tres:15` | "Soaks nightmares" | "gives nightmares {damp}" |
| `meta/grove/bellflower.tres:9` | "fall asleep" | `{asleep}` |
| `codex_data.gd:130`, `fever_dream.tres`, `rest_report.gd:10` | "sleep" | `{asleep}` |
| `tower/tidecaller.tres:12` | "1 cell" (a path push) | `{step}` |
| 6 Dream / Codex lines (T7) | "Phantoms", "Night Hounds" | `{nightmare:dandelion_seed}s`, `{nightmare:hedgehog}s` |
| 25 lines (T6) | raw "touching" | `{touching}` |
| ~10 Warden-side lines (T6: gifts, Deeproot, Winding Roads, Caught) | raw "near" | `{near}` where it means 2 cells, else "within N cells" |
| `icon_info.gd:26`, `codex_data.gd:184` Caught | "near a Dreamcatcher" | "in a Dreamcatcher's range" (check) |
| 9 Grove hidden-branch nodes, 9 Ascension nodes, Codex Sprout / Thornwall | "can grow into", "grows a {final_form} into it" | `{grow}` |
| Ascension Dream cards (9) | "Any …-{family} final form can ascend" | `{final_form}` (token used in the Grove nodes, plain here) |
| `grove_keeper.tres:14`, `mother_log.tres:14`, `tending_hands.tres:9`, `first_care.tres:9`, `heartwood_gifts.gd:61, :81` | bare `{rank}` / `{ranks}` | "Nurture {rank}" |
| `whispering_hollow.tres:12`, `dream_reaction_cards.gd:205` | "Reaction chain" | `{chain}` (plain "chain" auto-links, but the capital differs from the glossary's "Chain") |
| `dream/heavy_going.tres` etc. | `{held} and {asleep} nightmares` | "nightmares with {held} or {asleep}" (status names as adjectives; house rule since 2026-10-17) |
| "heavy hit" (`shatter.tres`, Codex Dread shell / Exposed Blow, `barrow_wight.tres`) | "heavy hit" = a big hit | not the `{heavy}` Warden: one word, two meanings beside a token (use "big hit", as the Asleep text does) |

### Capitalisation
| Where | Now | Fix |
|---|---|---|
| `warden_panel.gd:461` | "Nurture Rank %s" | "Nurture rank %s" (Codex / icon_info: lower r) |
| `whispering_hollow.tres:12`, `dream_reaction_cards.gd:205`, `combo_feedback.gd:435`, `codex_panel.gd:2237` | "Reaction chain", "the chain", "Longest chain ever: Chain %d" | {chain} reads "Chain": one case |
| `codex_data.gd:74` | group "Classes" | "Callings" |
| Codex fallback combo id `&"asleep"` name "Asleep" vs status "Asleep" | same word for a combo and a status (`codex_data.gd:180`, `:605` "the Asleep combo") | fine if intended; flagged once |
| `pause_menu.gd:235` vs `:400` | "Abandon run…" / "Abandon this run…" | one label |
| `deeper_rings.tres`, `tending_hands.tres`, `heartwoods_reach.tres` | "nurtured" (lower) beside "Nurture" (capital) | house style: verb lower is fine; noted |

Everything else checked is consistent: Warden, Dew, Dreamlight, Heartwood, Sprout, Thornwall, Reaction, Dream, Omen,
Kinship, Seeds and Memory Grove are capitalised in player text (0 lowercase hits outside ids and comments);
drift / block / rest / cell / step / nightmare are lower-case mid-sentence.

---

## Top 10 (ranked)

1. **Grove "Grow / Grown"** (`grove_screen.gd:423-433`, `results_screen.gd:182`, `remember_screen.gd:553`): grow means
   unlocking a node between runs, the exact clash the Grow vs Nurture rule fixed in runs. Rewrite: "Plant" / "Planted"
   / "Raise to level %d", or keep it and write the exception into the rule (owner call).
2. **Dewdrop Grove branch node** (`meta/grove/dewdrop_hidden.tres:9`): "it freezes nightmares that have {damp}. Also adds
   the {card:deep_frost} card." Rewrite: "The {warden:dewdrop} can {grow} into the {warden:frostfern}, then the
   {warden:hoarfrost}: its hits give {frost}, which bursts at {full}." (drop the retired card).
3. **"set off" ×6** (Pinned, Dawnbreak tip, Codex Chain, Charge lesson, undiscovered-combo tip, Hedgehog hint).
   Pinned: "Uses up the {marked}, and the {drowsy} when that triggered it." Codex Chain: "Reactions triggering each other
   within a second." Lesson: "Other statuses can trigger it early as a {reaction}." Status link: "Not discovered yet:
   trigger it in a run to learn it." Dawnbreak: "Each nightmare triggers one at most once every 3 s."
4. **Tidecaller three ways** (Warden, card, node): one text: "Every 6 s a great wave gives nightmares in range {damp},
   pushes them back 1 {step}, and gives {field:tidecaller.frost_if_frosted:count} {frost} to those that already have
   {frost}."
5. **Base Reactions in the old shape** (10): e.g. Thunderclap: "A Thunderclap hits it hard (×12 damage) and arcs to
   nightmares with {damp} in range (×6 each); each arc adds 1 {static}. Triggered by {stacks:need_damp} {damp} +
   {stacks:clap_static} {static} ({stacks:bossclap_static} on bosses)." (if the F.2 ruling covers them).
6. **Dream evolution cards' splash wording** (Dewdrop, Hoarfrost, Puffball, Rain Lily): "the nightmare it hits"; and
   Frostfern card: "At {full} {frost} a nightmare bursts, hurting it and up to 4 others within 1 cell."
7. **Bare {rank} / "rank" (20 strings)**: Grove Keeper "Its Sprouts start at Nurture {rank} II."; Mother Log "…keeps its
   Nurture {rank}."; Tending Hands "…to Nurture {rank} VII."; Quiet Rings report "no free Nurture rank at the next rest";
   lesson "Each Nurture rank lets you choose one improvement."
8. **Distance words**: raw "touching" ×25 and raw "near" ×30 beside defined tokens, plus three cards that define their
   own ("Nearby: 1.5 cells", "Nearest: 2 cells"). Tokens where the meaning matches; "within N cells" where it doesn't.
9. **Root's six names** (Root / Roots / Hold tag / Rooted / "can't move for N s" ×23 / Roots gift): rename the role tag
   "Hold" → "Root", and apply rule 11's short form.
10. **Phantom** is a nightmare now: the 4 Nestling-line Dream cards, Lightning Fence card, Codex Arc and Flock Together
    say plain "Phantoms" (and "Night Hounds"): `{nightmare:dandelion_seed}s`, `{nightmare:hedgehog}s`, as the Wardens do.

Smaller: Windmill "Every 2nd spin" + its tip; Opening Fracture's own Direct-hit definition; "Hits only, not status
damage" ×5 → "Direct hits only."; Codex "Effect" entry vs ruled "status damage"; "kill" ×3; "tiles" / "squares";
"Soaked Rot", "Exposed Blow"; "elites" in Brittle / Frostbite; "Grows into" heading; route ×9; Flyers lesson vs route flyers;
role tag "Chain"; Codex group "Classes"; "boost" both sides; "last drift" two meanings; "toward(s)".

## Patterns (one line each)

- Sweeps fix the file named in the ruling and miss its twin: Warden fixed, Dream evolution card not (splash, Frostfern,
  Tidecaller). Rule: every Warden text change also greps `dream_<id>.tres` and `meta/grove/*`.
- Regex sweeps miss split phrasal verbs ("set it off", "setting each other off"). Sweep `\bset\b.{0,20}\boff\b`.
- Grove nodes lag every rule (grow token, {rank}, Frost); they need their own pass per ruling.
- Local definitions inside tips ("Nearby:", "Nearest:", "Passed:") multiply distance words; define once in the Codex.
- Two orders for boss numbers: "(bosses N)" on cards, "(N on bosses)" in tooltips. Pick one.

## What already works

UK spelling is clean. Reroll / Banish / Lessons / Boosts / Closing drift / Steady / map seed are applied everywhere. The
Frost family, Hollow and Flashover texts landed exactly. Every Calling row uses "Nurture {rank}". Numbers checked against
the code all match (list under Fact mismatches). The Crowned Reactions now share one shape.
