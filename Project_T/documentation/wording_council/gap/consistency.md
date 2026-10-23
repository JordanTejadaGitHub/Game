# Consistency seat: gap round (2026-10-23)

Corpus: corpus_resources.txt (95 Grove nodes, 10 Crowned Reactions, 7 drift templates; no Blessing or boss-pool
files are in it, so none were checked), corpus_combat.txt (calling_paths.gd skipped), corpus_short.txt. Status names
as the player sees them now (icon_info.gd STATUSES): {damp} Soak, {spored} Poison, {marked} Exposure, {static} Charge,
{held} Root, {drowsy} Drowsy, {asleep} Asleep.

Counts: **58 flagged strings**. 9 fact mismatches, 14 term-map rows, 9 phrase-map rows, 12 button-word rows,
14 capitalisation or token breaks.

---

## 1. Top 10 problems, ranked

| # | Where | Now | Problem | Rewrite |
|---|---|---|---|---|
| 1 | grove/venom.tres | "Adds the {dream} card {card:venom_bloom}: statuses and {reactions} deal double damage." | **Wrong number.** Venom Bloom (dream/venom_bloom.tres) says "Wardens have 40% more Potency: their status and {reaction} damage is 40% higher." Double is ×2, the card is ×1.4. | "Adds the {dream} card {card:venom_bloom}: Wardens have 40% more Potency, so statuses and {reactions} deal 40% more damage." |
| 2 | grove/let_go.tres display_name | "Let Go" | Owner ruling: **Banish**, not Let go. The body already says {banish}. | "Banish" (or "Banishment"; the node needs a name, not a verb). |
| 3 | grove/sporeling_ascension.tres | "A constant spore storm that pops nightmares like a {warden:puffball}." | The Sporemother's own text (tower/sporemother.tres) has no popping: "breathes spores over everything in range (2 {spored} each). {spored} never wears off while a nightmare is in her range." (check) | "…grow a {final_form} into it for 600 {dew}. Breathes spores over everything in range, and {spored} never wears off while a nightmare is in her range." |
| 4 | grove/rootling_hidden.tres | "…{warden:starcave}s: light that reveals nightmares and gives them {marked}." | Neither Rootlight nor Starcave text adds Exposure; both say {held} lasts longer on glowing cells and {hidden} nightmares show. Only a stale code comment (tower.gd:5342 "soothed and Marked") backs the node. (check) | "…{warden:starcave}s: glowing roots that reveal {hidden} nightmares and make {held} last longer." |
| 5 | grove/memory_moon_moth.tres | "Reveals every Lurker, and Wardens in range attack from further away." | The Moon Moth's own text: "Long-range shots that Expose; Wardens within 3 cells get +1 range." Revealing Lurkers isn't on the Warden; Exposure isn't on the node. "Lurker" is a nightmare name, plain (no token). (check) | "…that boss. Long-range shots that give {marked}; Wardens within 3 cells get +1 range." (and tower/moon_moth.tres "Expose" → "give {marked}") |
| 6 | crowned/tempest.tres | "Each arc triggers {combo:ignite} on nightmares with {spored}…" | Code (reactions.gd:1046) needs `IGNITE_MIN_SPORES` (12) {spored} and needs {static} for Ignite on an arc target; "nightmares with {spored}" reads as any amount. The Codex fallback (codex_data.gd:181) says "12 {spored} and 8 {static}". Also "Ignite's" and "Thunderclaps" plain after tokens. | "Each arc triggers {combo:ignite} on nightmares with 12 {spored} and 8 {static}; the burning spores also carry {static}, so more {combo:thunderclap}s follow. Needs 6 {spored} on a {combo:thunderclap}. Each nightmare once every 2 s." |
| 7 | crowned/changeling.tres | "…the nightmare furthest along its path within 3 cells…" | Code measures along the path (reactions.gd:153-156 comment: "route cells ahead on its own route… never across walls"). Rule 7: along the path is "N {steps}". Also "the leader" short form (rule 11). | "It trades places with the leader within 3 {steps} ahead on its path, then turns and walks back. Never bosses. Triggered by…" |
| 8 | grove/second_thoughts.tres | "+1 {dream} reroll per run per level, up to 3." | **Reroll** has a token (`{new_cards}` → "Reroll", icon_info.gd:290); here it's plain lowercase text, no link. "up to 3" while siblings say "up to +3". | "While carried: +1 {new_cards} per run per level, up to +3. Always: adds the {card:wandering_mind} card." |
| 9 | warden_panel.gd:797 (and 795, 1492 tooltip context) | "Buffs" | **Boosts** is the one name (wording_review_2026-10-13 §1: "buff, buffs → boosts"). The panel header still says Buffs. | "Boosts" |
| 10 | grove/whirligig_ascension.tres; grove/firefly_jar_ascension.tres; grove/bellflower_ascension.tres | "A cyclone drifts along the path…"; "Lightning chains to every nightmare in range."; "Its toll puts every nightmare to sleep…" | Game words used plainly with another meaning: "drifts" is a {drift}; "chains" is on the avoid list (Chain = Reaction chain); "toll" is the Bellflower Calling's {toll}. The Wardens' own texts say "roams", "jumps", "peals". | "A cyclone roams the path and carries every status it touches." / "Its lightning jumps to every nightmare in range." / "Every 8 s it peals: every nightmare falls {asleep}, and each one with 4 or more {static} is struck by its bolt for half damage." |

---

## 2. Fact mismatches (file:line evidence)

| Where | Text says | Data says | Verdict |
|---|---|---|---|
| grove/venom.tres | "deal double damage" | dream/venom_bloom.tres: +40% Potency, "40% higher" | Wrong (top 1) |
| grove/sporeling_ascension.tres | "pops nightmares like a Puffball" | tower/sporemother.tres: 2 {spored} a second, never wears off in range | Wrong or stale (check) |
| grove/rootling_hidden.tres | "gives them {marked}" | tower/rootlight.tres, starcave.tres: no Exposure; tower.gd:5342 comment only | Stale (check) |
| grove/memory_moon_moth.tres | "Reveals every Lurker" | tower/moon_moth.tres: no reveal; adds Exposure the node omits | Mismatch (check) |
| crowned/tempest.tres | "nightmares with {spored}" | reactions.gd:1046 needs need(IGNITE_MIN_SPORES)=12 (+ {static}) | Missing threshold |
| crowned/changeling.tres | "within 3 cells" | reactions.gd:153 CHANGELING_REACH along the route | Wrong distance word |
| crowned/prismstorm.tres, starfall.tres | literal "8 {static}" | reactions.gd:32 CROWNED_MIN_STATIC 8, read through need(); need() halves any base equal to 8 when _half_need is on (reactions.gd:418, 457: HALF_NEED_BASES matches by value, and IGNITE_MIN_STATIC is also 8) | Text stays 8 while the rule drops to 4 under half-need. Use a live {stacks:} key, or keep Crowned out of HALF_NEED_BASES (code). (check) |
| crowned/nightbloom.tres | "their sleep doesn't run out" | reactions.gd:146 NIGHTBLOOM_TIME 4 s (the cloud's life); crowned_ground.gd:8 bosses keep full {drowsy} instead | Duration and boss rule missing: "…for 4 s… (bosses: stay at {full} {drowsy})" (check) |
| grove/winding_roads.tres | "Wardens near the start of the path" | dream/forests_edge.tres "within 3 cells of the start"; "near" is a glossary word = 2 cells (firefly_lights.gd:25 NEAR_CELLS) | Use "within 3 cells of the start" |

**Checked and matching** (no flag): Ascension nodes (from {drift} 51 = dream_state.gd:241; 3 {dreamlight} = :240; 600 {dew}
= evolve_cost in all 9 Ascended .tres); Deep Taproot (max_leaves 1 × 3 levels); Morning Stores (20 × 3); Rested Roots
(0.1 × 2); Rich Dew (0.05 × 3); Seed Pouch (0.1); Leaf or Dew (meta_run.gd:103-104 rate 30, max 3); First Care
(free_nurtures 3); Sprout Bed (2); Wider Roots (dream_state.gd:1425 call-back 4 vs 3); Early Light (1); Second Thoughts
(1 × 3); Great Bell 4 {static} (great_bell.tres sets_off_static_at 4); Crowned: Avalanche 4 s / 30% / 0.5 s / 4
(reactions.gd:138-141), Fever Dream 2 s / 3 / 2, Starfall 3 cells / half, Still Pool 5 s / 1 s / 30% bosses
(crowned_ground.gd:15), Fairy Circle 6 s / 2 (RING_STACKS), Wide Awake 3 cells / 40% / 3 s, Tempest 6 {spored} / 2 s;
Callings: acorn every 5th (callings.gd:43), nestling 3 cells (:44), whirligig 1 cell (:48), bell 4 rings / starts 2 /
0.5 s / once a second (keeping_time.gd:13-17), glow 1.5 cells (firefly_lights.gd:22), dew splash 4 {steps} once a
second (puddles.gd:15-16), dose 3 / 40 mushrooms (spore_print.gd:14-15); Tending Hands rank VII.

---

## 3. Term map (one name per thing)

| Thing | Names in this corpus (count) | One name | Where to fix |
|---|---|---|---|
| Removing a card for the run | "Let Go" node name (1), {banish} (2) | Banish | grove/let_go.tres display_name |
| Redrawing Dream cards | "{dream} reroll" plain (1) | {new_cards} (Reroll) token | grove/second_thoughts.tres |
| Warden bonuses from others | "Buffs" header (warden_panel.gd:797) | boosts | warden_panel.gd:797 |
| The top tier | "Ascension:" node prefix (9), "the {family}'s strongest form" (9), "Ascended" column (remember_screen.gd:1298), glossary {ascended} | Ascended ("Ascended: Grandmother Oak"; "…'s {ascended} form") | 9 *_ascension.tres; text uses the {ascended} token |
| Path distance | "path tiles" (support_log.gd:179), "route" (corpus_combat calling_paths tip, already reviewed), "within 3 cells" for a path distance (changeling) | cells / path / {steps} | support_log.gd:179 "Adds %d path cells"; changeling.tres |
| Sleep | "fall asleep" plain (bellflower.tres), "to sleep" (bellflower_ascension.tres), "their sleep" (nightbloom.tres), "pulled under" (still_pool.tres; crowned_ground.gd:6 says it is a sleep), {asleep} token (3) | {asleep} | bellflower, bellflower_ascension, nightbloom, still_pool |
| Crit | "takes a crit" plain (starfall.tres), {crit} (old_mountain node), "{critical_hits}" (2 nodes) | token in rules text | starfall.tres "takes a {crit}" |
| Mushrooms | {mushroom} = Spore Print Calling only (callings.gd:31 "Only this Calling and its evolutions grow or use {mushrooms}"), but "mushroom traps" (sporeling_hidden.tres), "Mushroom rings" (fairy_circle.tres) | Reserve "mushroom" for the Calling; Fairy Ring = "spore traps" (as fairy_ring.tres says), Fairy Circle = "rings" | sporeling_hidden.tres, fairy_circle.tres |
| Toll | {toll} = Bellflower Calling; Great Bell node "Its toll" | "peal" (great_bell.tres word) | bellflower_ascension.tres |
| Kinship | "Kin:" / "No kin" (kinships.gd:645, 675, 694), "bonded" (:675), {Kinship} (buff_sources.gd:65) | Kinship: "Kinship: %s · …", "No Kinship: the %s in range already has one with its %s" | kinships.gd |
| Rooted | tower_seller.gd:1007 tag "Rooted" (an unsellable Warden) = the old name of Root; "Rooted Nightmares" Legendary | A different word for the unsellable tag: "Can't sell" or "Bound" (check what rooted means) | tower_seller.gd:1007 |
| Caught | {caught} status (Dreamcatcher) vs "Caught this run: %d Dew" (support_log.gd:172) | "Gathered this run: %d Dew" | support_log.gd:172 |
| Strong / Chain / Heavy | "Strong" rest tag (rest_report.gd:244) = Kinship {strong}; "Chain" role tag (warden_header_view.gd:378) = Reaction {chain}; "Heavy" drift template (drift/template/heavy.tres) = {heavy} Heavy Warden | rest tag "Winning"; role tag "Chain" → "Jumps" (or "Arcing"); template "Tough" / "Armoured" (check what it spawns) | as listed |
| Elite | "Elite hunt" drift template (shown in rest report via drift_roller.gd:108) vs glossary "Deeply Blighted" | "Blighted hunt" | drift/template/elite_hunt.tres |
| dream (a run / map) vs Dream (a card) | "Which dream?", "Dream it" (seed_picker.gd:65, 110), "Leave the dream?" (pause_menu.gd:383) | Keep lowercase "dream" for the run only on these flavour lines, or say "map" / "run": "Which map?", "Start", "Leave this run?" | seed_picker.gd, pause_menu.gd |
| Memory | Memory Grove; "Memory Warden" (3 nodes); "A Memory returns" (family_pick_screen.gd:1033); "Memory %d" viewer (grove_screen.gd:745); {memory} glossary "Memories" | Fine if the Codex entry covers all three; else the viewer title "Run %d" (check) | grove_screen.gd:745 |
| Who did most | "Top support" (block) vs "Best supporter" (run) (rest_report.gd:354) | "Top support" both | rest_report.gd:354 |
| Lamplighter's ability | "Cold Lanterns" (enemy/lamplighter.tres) vs boosts row "Cold lantern" (buff_sources.gd:133) | "Cold Lanterns" | buff_sources.gd:133 |

---

## 4. Phrase map (one phrasing per mechanic)

| Mechanic | Shapes found (count) | Pick |
|---|---|---|
| Node adds a card | "Adds the {dream} card {card:x}: …" (10), "Adds a {dream} card: {card:x}." (deep_promises), "Adds a {dream} card for area attacks: {card:x}." (far_reach), "Also adds the {card:x} card." (12, families/branches), "Also adds its {dream} cards (listed below)." (4), "Always: adds the {card:x} card." (second_thoughts) | Main: "Adds the {dream} card {card:x}: <what it does>." Family / branch nodes: "Also adds {card:x}." |
| Legendary node | "Adds the {legendary} {dream} card {card:x} to the cards your runs can offer." (14) vs "Adds two {legendary} {dream} cards to the cards your runs can offer: …" (the_old_ones) | Fine; one shape. Only One Line breaks the name rule (below). |
| Family node, starter vs not | "is a choice at {family_picks} from your first run." (4) / "can now appear as a choice at {family_picks}." (5) | Fine as a pair. Starters Dewdrop, Firefly Jar, Sporeling lack an "Also adds" line that Bellflower has (check whether they add cards). |
| Levelled perk | "+N X per level, up to +M" (4) vs "up to 3" (second_thoughts) | "up to +M" |
| Crowned trigger line | "Triggered by a {combo:x} on a nightmare with N {y}." (6), "Triggered by {combo:x} on…" (2, no "a"), "Triggered when {combo:smother} ends on…" (fever_dream), "Needs 6 {spored} on a {combo:thunderclap}." (tempest), "Triggered by a {combo:shatter} from a lobbed stone (…)" (avalanche) | Rule 12 says "Needs …". Pick one: "Needs a {combo:x} on a nightmare with N {y}." for all 10. |
| Boss exception | "(bosses: slowed only)" (avalanche), "(bosses are slowed 30% inside)" (still_pool), "Never bosses." (changeling) | Rule 9: "(bosses: slowed 30% instead)" right after the effect. |
| Who repeats | Great Bell node "its bolt strikes for half damage" vs Bellflower Calling "lands again at half damage" | Fine. |
| Copy the neighbour | acorn_hidden "copy the attack of their strongest neighbour" vs graftling.tres "neighbouring Warden" | Fine. |
| Rate limit | Tempest "Not again on the same nightmare for 2 s." vs rule 3 "Each nightmare once every N s" | "Each nightmare once every 2 s." |

**Node name vs card name.** Legendary nodes carry their card's name (14 of 15). Breaks: **One Line** → card
**Monoculture**. Upgrade nodes: **Quickening** → card **Hunt's Rush II** (the start card is "Hunt's Rush"; "Quickening" is
an old name), **Mixed Company** → **Mixed Grove II**. Name collision: card **Forest's Edge** (winding_roads node) = Act 1's
name "Forest's Edge" (drift_director.gd:67, codex_panel.gd:1993).

---

## 5. Button-word map

| Action | Words now (file:line) | One word |
|---|---|---|
| Close an overlay | "Close" (codex_panel:97, dreams_row:50/526, warden_panel:505/664/2517, grove_screen:247/314/539/949, dev_card_picker:80), **"Done"** (remember_screen:141/330, loadout_panel:76) | "Close" for overlays; "Done" only where it confirms a choice (touch_build:90 ends build mode: fine) |
| Go back one page | "Back" (gift_screen:195, grove_screen:268/841, loadout_panel:62, warden_panel:2435) | Fine |
| Leave a peek (map look) | "Return" (nightmare_intro:115), "Back to Remember" (remember_screen:151/322) | "Back to <screen>" both: "Back to the nightmare" (check label space) |
| Move on from an info card | "Continue" (boss_dossier:419/613, combo_feedback:213, nightmare_intro:490, grove_screen:850), "Got it" (lesson_card:95/607, nightmare_intro:309), "Next" (lesson_card:607, nightmare_intro:277/309), "Tap to continue" (flyer_warning:67) | "Next" while more follow, "Got it" on the last; "Continue" only for a step in a flow (Leaf or Dew, dossier). Combo card and nightmare intro block summary → "Got it" |
| Pick up a saved run | "Continue" (title_screen:102), "Resume" (pause_menu:73/222, drift_panel:288) | Title "Continue" is genre-standard; fine. Note the same word means "next card" elsewhere. |
| Start a run | "New run" (title:103, results:209), "Start new run" (title:291 confirm), "Start run" (grove_screen:262, loadout_panel:76), **"Start"** (blight_picker:62) | "Start run" from Grove / loadout / Blight; "New run" from title / results. Blight picker → "Start run" |
| Plant | "Plant it" (gift_screen:200/443), "Plant %d" (touch_build:164 PC), **"Confirm (%d)"** (same line, phones), "Plant for" (hud:2018) | "Plant %d" on both (touch rule: words don't change by platform) |
| Grow | "Grow %s" (warden_panel:368), heading "Grow into" (warden_panel:1429) vs **"Grows into"** (warden_header_view:317, hover card / Codex) | One heading: "Grows into" |
| Unlock / add | "Unlock", "Unlock, free" (remember_screen:1114), "Unlock %s" (warden_panel:415), "Add  %d" / "Add, free" (remember_screen:632; double space) | Fine; fix the double space ("Add %d") |
| Show more | "Details" / "Hide" (warden_panel:1492, results:148), "Show" / "Hide" (grove_screen:998), "Show all" (grove_screen:283) | Fine |
| Remove placed cells | "Clear" (gift_screen:186) vs "Clear" (clear_tool_button:40: clear an obstacle) | Gift screen → "Clear all" or "Reset" (two actions, one word; the clear tool is a game term) |
| Search | placeholder "Search terms…" (codex_panel:119) vs "Search the Codex" (:122) | One: "Search the Codex" |

Other short-string notes: "Choose as Tallest" (warden_panel:1395) cuts the card name; "Choose as Tallest Tree" (5 words) or
"Make Tallest Tree". "Reward gone" vs "Reward lost" (omen_screen:505) are two words for one state unless they differ
(check).

---

## 6. Capitalisation and token breaks

| Where | Now | Rule | Fix |
|---|---|---|---|
| grove/slot_4.tres, slot_5.tres | "Perk slot 4" | Node names are names: Title Case (all other 93 nodes) | "Perk Slot 4", "Perk Slot 5" |
| drift/template/elite_hunt.tres | "Elite hunt" | Template names elsewhere single words; shown in rest report | "Blighted Hunt" (see term map) |
| grove/heartwoods_crown.tres | "Every other {node} is Grown." | State word, mid-sentence: lowercase | "is grown" |
| buff_sources.gd:133 | "Cold lantern" | Ability name is Title Case "Cold Lanterns" | "Cold Lanterns" |
| grove/kindling.tres | "a random Common {dream} card" | Rarity is fine capitalised as a name, but has no link | "a random Common {dream} card" (OK) or add a rarity token (check) |
| bellflower.tres | "until they fall asleep" | Status → token | "until they fall {asleep}" |
| bellflower_ascension.tres | "puts every nightmare to sleep" | Status → token | "every nightmare falls {asleep}" |
| nightbloom.tres | "their sleep doesn't run out" | Status → token | "they stay {asleep} while inside" |
| starfall.tres | "takes a crit" | Keyword → token | "takes a {crit}" |
| tempest.tres | "Ignite's", "Thunderclaps" | Combo names → {combo:} tokens each time | as in top 3 #6 |
| memory_* nodes | "the Moth Queen", "the Mire Hag", "the Hollow Stag", "Lurker" | Names, correct case; no link | OK as text; add nightmare tokens if they exist (check) |
| gift_ground.gd:134-138 | "Sheltered (Sow a Ridge)", "Moonwell (sees Hidden)", "Lookout (Fallen Giant)" | One shape per row: the bracket names the source gift in two rows, an effect in one | Name the effect first and the gift in the bracket in every row: "Sheltered (Sow a Ridge)", "Sees Hidden (Moonwell)", "Lookout (Fallen Giant)" (check that Moonwell is the gift) |
| kinships.gd:675 / 694 | "No kin: …" vs "No kin. …" | One punctuation | Colon both |
| codex_panel.gd:1052 | "Formed %d time%s" | English-only plural (localisation, §7 of the lead review) | Note only |
| gift_screen.gd:271 | "The %s grows" / "The %s grow" by trailing "s" | Fragile plural guess | Note only (localisation) |
| grove_screen.gd:879 (not in corpus) | "%d fewer leaves and max leaves" | "1 fewer leaves" at trade 1 | singular for 1 |

UK spelling: no US spellings found in this corpus ("meter" is the device sense, correct in UK English). Sentence case on
buttons holds everywhere else checked (Apply and close, Reset this tab, Copy run report, Abandon run…, Skip lessons).

---

## 7. Patterns

- Grove nodes were written once and not updated when cards / Wardens changed: Venom, Sporemother, Rootlight, Moon Moth.
  Fix: a test that compares node numbers with the card's .tres (as test_text_style does for Silence).
- Plain game words with a second meaning in node flavour (drifts, chains, toll, mushroom, near). Fix: node text uses
  the Warden's own verb.
- Literal stack numbers in Crowned text where siblings use `{stacks:}` keys (8 {static} ×2, 6 {spored}). Fix: live keys.
- Old names leaking into labels: Buffs, Let Go, Elite, path tiles, Rooted tag, Quickening.
- One action, several button words: Close/Done, Continue/Got it/Next, Start/Start run/New run, Plant/Confirm.

## 8. What already works

- "While carried:" opens every perk (21 of 21); levelled perks share "+N per level, up to +M".
- The 9 Ascension nodes share one sentence with matching numbers in code.
- Family nodes split cleanly into "from your first run" (the four starters) and "can now appear".
- Callings' numbers all match their constants; tokens are used throughout.
- No "set off", "kill", "Phantom" or "Let go" in the short strings; "Finale" is the drift 75 stage (dream_screen.gd:514).
