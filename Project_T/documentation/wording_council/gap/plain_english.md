# Plain English seat: gap round (2026-10-23)

Reader: second-language players and future translators. Corpus: corpus_resources.txt (Grove nodes, Crowned Reactions,
drift template names), corpus_combat.txt (callings.gd, buff_sources, kinships, support_log, gift_ground; calling_paths.gd
skipped as asked), corpus_short.txt (buttons, headings, labels). Judged with tokens resolved through icon_info.gd.
"P1 §3" = my round 1 words-to-avoid list.

**Corpus gap:** the brief names Blessings and boss pools with boss flavour lines, but corpus_resources.txt holds no
Blessing or BossData text (only Grove nodes, Crowned Reactions and drift template names). Those still need a read.

---

## 1. Top 10 problems

| # | Where | Now | Problem | Rewrite |
|---|---|---|---|---|
| 1 | grove/heartwoods_crown.tres | "Every other {node} is Grown. Adds a sixth {perk} slot…" | "Every other" means "every 2nd" to most learners (lead rule 4 bans that sense). Here it means "all the other nodes". A reader thinks half the tree must be grown. | "Needs every other {node} Grown first." or "Grows when all other {nodes} are Grown." (check: requirement or condition). Then "Adds a sixth {perk} slot: carry 6 {perks} into a run." |
| 2 | callings.gd:24 (Rootling Calling) | "Every Warden in range turns to a nightmare with {held}, and their hits on it add twice as much status." | "turns to" also means "becomes" (the Warden turns into a nightmare?). "their / it" chain. | "Every Warden in range attacks a nightmare with {held} first. Their hits on that nightmare add twice as many {stacks}." (check "first" = target priority) |
| 3 | boss_dossier.gd:141, :419 | button "Face it" | Idiom; "it" has no noun on a button. A learner can't tell whether it starts the fight or closes the page. | "Face the boss" (keeps the voice, names the object). |
| 4 | boss_dossier.gd:535 (Chosen Hunt pick) | button "Hunt it" | The action is "choose this boss for the act", not hunting. "it" again. | "Choose this boss" (or "Hunt this boss" if the voice must stay). |
| 5 | family_pick_screen.gd:611, :613 | "Wake %s" / "Wake %s, %s" | Poetic verb for "take this family". Reads as "wake the Warden up" or an alarm. The Dream screen says "Take %s" for the same act. | "Take %s" (one verb for every pick), or "Wake the %s family" if the owner keeps the verb. Drop the ", %s" tail into its own line (see §4). |
| 6 | seed_picker.gd:65, :110 | title "Which dream?", button "Dream it" | "dream" here = the map, but a Dream is a card everywhere else (two game meanings). "Dream it" is an idiom. | "Which map?" / "Play this seed". |
| 7 | crowned/changeling, fever_dream, still_pool, fairy_circle | "It trades places…", "It falls {asleep}…", "It sinks…", "…path cells around it" | Opens with "it" before any noun; the "Triggered by…" that names the nightmare comes last. Lead rule 13. | "The nightmare trades places with…", "The nightmare falls {asleep} for 2 s…", "The nightmare sinks, and a still pool stays on its cell for 5 s.", "…on the path cells around that nightmare". |
| 8 | crowned/nightbloom | "nightmares {asleep} inside don't wake from hits, and their sleep doesn't run out." | Two negatives in a row; "run out" phrasal. | "Hits don't wake {asleep} nightmares inside it, and their sleep has no end while they stay inside." (check: ends on leaving the cloud?) |
| 9 | grove/*_hidden.tres, *_ascension.tres (18 nodes) | "{warden:acorn}s can grow into {warden:graftling}s…", "the {family:acorn} {family}'s strongest form" | Plural and possessive made by gluing "s" / "'s" onto a token. Untranslatable (see §4); also "Firefly Jars" vs "Firefly Jar's" depend on English. | "Your {warden:acorn} Wardens can grow into {warden:graftling}, then {warden:grafted_elder}: …"; "the strongest form of the {family:acorn} {family}". |
| 10 | grove/planted_promises.tres | "three {dream} cards that pay off later in a run" | "pay off" is on P1 §3 (money idiom). | "three {dream} cards that get stronger later in a run". |

---

## 2. Every other flagged string

### Resources (Grove, Crowned)

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| grove/bellflower_ascension | "triggers the {static} of each nightmare with 4 or more: its bolt strikes for half damage" | "4 or more" what? "its" = the Bell or the nightmare? | "…triggers the {static} bolt of each nightmare with 4 or more {stacks} of {static}, for half damage." |
| grove/dewdrop_ascension | "Tides roll along the path and wash nightmares back." | "wash back" phrasal; back to where? | "Tides move along the path and push nightmares back toward the start." |
| grove/sporeling_ascension | "A constant spore storm that pops nightmares like a {warden:puffball}." | "pops" slang for a damage burst. | "A constant spore storm: nightmares in range burst like a {warden:puffball}'s cloud." (check mechanic) |
| grove/firefly_jar_hidden | "a beam that grows stronger the longer it stays on one nightmare" | "grow" = change form (P1 §3). | "a beam that deals more damage the longer it stays on one nightmare." |
| grove/acorn_hidden | "they copy the attack of their strongest neighbour" | "neighbour" undefined; {touching} is the defined term. | "…copy the attack of the strongest Warden {touching} them." |
| grove/acorn | "Strengthens Wardens in range and earns {dew}." | fine meaning, but "earns" for a Warden is a money idiom | "Makes Wardens in range stronger and gives {dew}." |
| grove/nestling | "Fast birds that fly out to hunt nightmares." | phrasal "fly out"; OK as flavour, mechanic hidden | "Fast birds that leave the Warden, attack nightmares and return." (check) |
| grove/whirligig_hidden | "they throw a seed that flies out and comes back" | phrasal pair, but clear; low | "…throw a seed that flies away and returns." |
| grove/pebbling_hidden | "they throw stones over the maze onto the path" | fine; "over the maze" = over walls (check) | keep |
| grove/memory_moon_moth | "Reveals every Lurker" | "Lurker" undefined, untokened | "Reveals every {kind_hidden} nightmare" (if Lurker = Hidden). |
| grove/memory_pond_keeper | "Its tongue pulls the nightmare furthest along the path back to its pond." | two "its" (Warden, Warden); fine once read; long subject | "Its tongue pulls the leader back to the Pond Keeper's pond." (lead rule 11: "the leader") |
| grove/leaf_or_dew | "Your max {leaves} change with them." | "them" = the leaves traded? vague | "Your max {leaves} go down or up by the same number." |
| grove/heartwoods_crown, deep_taproot, etc. | "While carried:" | "carried" is a game term (Carry button) but reads as "held in hand" | keep, but add "carried" to the glossary: "a perk taken into a run". |
| grove/clear_sight | "…so you can clear obstacles from {drift} 1." | "from" = "starting at" | "…from the first {drift}." or "starting at {drift} 1". |
| grove/strange_dreams | "three {dream} cards that gamble" | cards don't gamble; the player does | "three {dream} cards with random results". |
| grove/bittersweet_dreams | "big effects with a cost" | OK | keep |
| grove/old_wood, last_stand, scarred_bark | "cards for risky play" | OK, but "risky play" borders on advice (owner rule) | "cards with a risk" (check owner) |
| grove/bellflower | "Song that gives nightmares {drowsy} until they fall asleep." | "asleep" unlinked; {asleep} exists | "…until they fall {asleep}." |
| crowned/avalanche | "Scree covers the path…", "from a lobbed stone" | "Scree" rare word; "lob" on P1 §3 | "Loose stones cover the path…", "from a thrown stone". |
| crowned/prismstorm | "The ice shards spark: each nightmare they hit with 8 {static} triggers its bolt at once." | flavour first; "they hit with 8" parses as "hit with 8 shards" | "Each nightmare the ice shards hit that has 8 {static} triggers its bolt at once." |
| crowned/starfall | "The crit splits into stars: every nightmare … takes a crit for half the hit." | flavour first; OK after it | "Every nightmare within 3 cells with {stacks:need_marked} {marked} takes a crit for half the hit (falling stars)." |
| crowned/tempest | "Each arc triggers {combo:ignite} on nightmares with {spored}, and Ignite's spreading spores also spread {static}, so more Thunderclaps follow." | "arc" undefined; "Ignite", "Thunderclaps" untokened; "so … follow" is a result clause, not a rule; trigger last | "Needs 6 {spored} on a {combo:thunderclap}. Each lightning arc triggers {combo:ignite} on nightmares with {spored}, and that Ignite also spreads {static}. Not again on the same nightmare for 2 s." |
| crowned/wide_awake | "The scream startles your attacking Wardens: … attacks 40% faster" | "startles" reads negative; it is a buff | "The scream wakes up your attacking Wardens: every attacking Warden within 3 cells attacks 40% faster for 3 s." |
| crowned/changeling | "…then turns and walks back. Never bosses." | "back" toward where? | "…then turns around and walks toward the start." |

### Combat strings

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| callings.gd:20 | "Each bell hit rings the nightmare; at 4 rings it is a {toll}" | "ring" verb and noun in one line; "it" = the 4th ring? P1 §3: four words for one hit | "Each hit from a bell adds 1 ring to the nightmare. The 4th ring is a {toll}: the hit lands again at half damage." |
| callings.gd:21 | "Every 5th acorn, all Wardens next to the {warden:acorn} attack its target at once." | "acorn" = projectile and the Warden; "next to" unlinked | "Every 5th attack of an {warden:acorn}, all Wardens {touching} it attack its target at once." |
| callings.gd:23 | "A {warden:pebbling}'s stone lodges in its target. The next hit … knocks it into the nightmare behind." | "lodges" rare; "it" = stone or nightmare | "A {warden:pebbling}'s stone stays stuck in its target. The next hit from another kind of Warden knocks the stone into the nightmare behind." |
| callings.gd:22 | "A {warden:nestling}'s bird can also swoop from…" | "swoop" rare verb | "…can also attack from any of your Wardens within 3 cells…" |
| callings.gd:25 | "Attacks that pass through … go further: shots fly on to a second nightmare, and pulses and splashes spread 1 cell wider." | "fly on to" phrasal; "splashes" collides with {dew_splash} | "…shots continue to a second nightmare, and pulse and splash attacks reach 1 cell further." |
| callings.gd:31 | "so it is weak against flyers" | "it" = the Calling; reads as advice | "Flyers pass over them." (stop there) |
| support_log.gd:172 | "Caught this run: %d Dew" | Caught is a status (P1 §3) | "Dew collected this run: %d" |
| support_log.gd:179 | "Adds %d path tiles" | "tiles" banned term (lead §6); plural | "Adds %d cells of path" |
| buff_sources.gd:133 | "Cold lantern %s attack speed" | OK; lower-case "lantern" vs boss name | keep (check name case) |
| kinships.gd:675 | "No kin: the %s in range is bonded to its %s" | "its" = whose? | "No kin: the %s in range already has a kin, the %s." |

### Short UI

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| boss_dossier.gd:595 | "Prepare" | prepare what? It closes the dossier | "Back to the rest" or "Get ready" (check what it does) |
| omen_screen.gd:204 | heading "Face an Omen" | "face" idiom; same as Face it | "Choose an Omen" (the button already says so: drift_panel.gd:284) |
| family_pick_screen.gd:741 | "Dreams into" | verb unclear ("dreams into" = grows into?) | "Grows into" (warden_header_view.gd:317 already uses it) |
| gift_screen.gd:200, :443 | "Plant it" | "it" on a button; low | "Plant the gift" |
| tower_seller.gd:1007 | tag "Rooted" | Root is a status (P1 §3); means "can't be sold" | "Permanent" (codex_data.gd:464 already says so) or "Can't sell" |
| warden_panel.gd:1395 | "Choose as Tallest" | "Tallest" undefined (Eldest is the term) | (check) "Make Eldest" if same mechanic |
| drift_panel.gd:83, remember_screen.gd:90 | "Remember" | a verb button that opens the unlock screen; reads as "save this" | keep as the screen's name, but the button: "Remember (unlock)" or tooltip "Unlock forms with Dreamlight" |
| grove_screen.gd:264 | "Carry" | carry what? | "Carry perks" |
| grove_screen.gd:211 | "Plant first" | heading reads as an order | "Plant these first" or "Needs" |
| pause_menu.gd:383 | "Leave the dream?" | metaphor for quit; a learner may not know "dream" = this run | "Leave this run?" (or keep with body text "Your run is saved") |
| results_screen.gd:228 | "Title" | noun as button | "Title screen" |
| lesson_card.gd:95, nightmare_intro.gd:309 | "Got it" | idiom, but very common; translators know it | keep |
| title_screen.gd:242 | "Couldn't continue" | contraction + "continue" (also a button name) | "Could not load the run" (check cause) |
| coming_strip.gd:410 | "Breaks the rules" | idiom (cheats?) | "Has a special rule" |
| remember_screen.gd:632 | "Add, free" | comma reads odd | "Add (free)" |
| remember_screen.gd:1114 | "Unlock, free" | same | "Unlock (free)" |
| rest_report.gd:238-244 | Holding / Struggling / Overpowered / Strong | "Overpowered" is gamer slang (= too strong) but well known; "Holding" vague | "Holding" → "Even" or "Holding on" |
| codex_panel.gd:2181 | "Copied" | OK | keep |
| ui_style.gd:35 | rarity "Mist, Sprig, Dewlight, Gold" vs codex_panel.gd:1771 "Common…Legendary" | two names for rarity; "Mist" = fog effect, "Sprig" = plant | consistency seat; flag only |

---

## 3. Patterns and rules

- **Buttons need an object, not "it".** "Face it", "Hunt it", "Plant it", "Dream it": write verb + noun ("Face the boss").
- **One verb per action across screens.** Take (Dream) vs Wake (family) vs Hunt (boss) vs Dream it (seed): pick "Take" /
  "Choose" for every choice; keep poetic verbs for headings, not buttons.
- **"dream" has three meanings** (Dream card, the run/map, the Heartwood's world). Buttons and titles should use
  "run" or "map" when the card isn't meant.
- **Flavour clause before the rule** (Crowned: "The ice shards spark:", "The scream startles…", "Scree covers…"): put
  the rule first or make the flavour verb match the effect (a buff never "startles").
- **"it" at the start of a Reaction text** has no antecedent; name "the nightmare" once.
- **Token + "s" / "'s"** builds English plurals and possessives on a token: rewrite around it.
- **New words for P1 §3:** "every other" (= all the others) → "all other"; "turns to" → "targets / attacks first";
  "lodges" → "stays stuck"; "swoop" → "attack"; "scree" → "loose stones"; "pops" → "bursts"; "wash back" → "push
  back"; "pay off" (again); "Rooted" as a tag → "Permanent"; "Breaks the rules" → "Has a special rule".

---

## 4. Localisation risks (gap corpus)

**Tokens glued to English endings (resources):** `{warden:x}s` and `{family}'s` in all 9 `*_hidden.tres` and 9
`*_ascension.tres` Grove nodes; `{warden:puffball}` in "like a"; `{drift} 51` (number after a token noun). Plural and
possessive must come from the token's own forms or be written around.

**String surgery / English grammar in code:**
- gift_screen.gd:271 `"The %s grows" … if not gift_name.ends_with("s") else "The %s grow"`: verb agreement by English spelling.
- hud.gd:2018 `.replace("Cost:", "Plant for")` and `begins_with("Sprout")`: edits a translated string by English words.
- coming_strip.gd:410 `.capitalize()` on a verb phrase: English (and title-case) only.
- boss_dossier.gd:306 `"About %s" % IconInfo.name_in_sentence(...)`: article handled in code.
- warden_header_view.gd:28 `"in the Memory Grove"` inserted into another sentence.
- remember_screen.gd:1628 `"Needs " + parent.display_name`.
- nightmare_info.gd:172 `"Omen " + omen.display_name` then `"%s: %s"` with `" · ".join(parts)`.

**English-only plurals:**
- codex_panel.gd:1052 `"Formed %d time%s"` with `"" if times == 1 else "s"`.
- dream_effects.gd:916 `count_text(n, "attacking Warden")` (helper adds "s").
- support_log.gd:176 "(to %d Wardens)", :179 "%d path tiles": no singular at all ("1 Wardens").
- kinships.gd:694 "within %d cells" (1 cell), touch_build.gd:157 "Sell %d", :164 "Plant %d" / "Confirm (%d)".
- blight_picker.gd:107 "+%d%% Seeds".

**Sentences built from fragments (corpus_combat):**
- buff_sources.gd:65 `"{Kinship} %s (%s, %d%%)"`; :77 `"{Kinship} Dreams %s damage"`; :105 `"Dream %s %s %s"` (name +
  signed number + stat word: word order fixed); :114 `"Omen %s attack speed"`; :133 `"Cold lantern %s attack speed"`.
- kinships.gd:645 `"Kin: %s · %s · %s"`; :675 `"No kin: the %s in range is bonded to its %s"` (article + possessive);
  :694 `"No kin. A %s within %d cells would form %s."` (article "A" before a name: "An Acorn"); :859 `"Kindred: the %s
  family +%d%%"`.
- support_log.gd:172, :176, :179 (above).

**Sentences built from fragments (corpus_short):**
- family_pick_screen.gd:611, :613 "Wake %s" / "Wake %s, %s" (second %s = the Calling, a fragment).
- dream_screen.gd:245 "Take %s"; warden_panel.gd:258 "Rank %s" + " · Eldest"; :368 "Grow %s"; :401, :573 "Unlock %s";
  :1497 "Details (%s)".
- lesson_card.gd:237-239 "A Warden is" / "Your %s is" (sentence start chosen in code; the rest added later).
- boss_dossier.gd:675 `_stake("Arrives", "walking now" if … else "drift %d")`.
- results_screen.gd:186 "%s: nothing was banked." with "Test Grove" / "Developer run".
- codex_panel.gd:1352 "Branches" + " · %d offered each run"; :2000 "Act %d · %s".
- hud.gd:1272 "Rest · %s"; remember_screen.gd:517 "Dreamlight %s"; :632 "Add  %d"; dream_bonus_view.gd:271 "Nurture %s".
- blight_picker.gd:97 "Level %d"; :107 `"\n".join(lines) + "\n\n+%d%% Seeds"`; grove_screen.gd:328 "Seeds %d", :745
  "Memory %d"; seed_picker.gd:89 "Seed %d"; tower_seller.gd:1007 "+%d Dew"; omen_screen.gd:537 "Reward %d%%".
- drift_panel.gd:346 `begins_with("Call drift ") and contains(" early, ")` (round 1 item, still there).
- Comparisons on displayed English text: remember_screen.gd:1014, rest_report.gd:246/254, omen_screen.gd:505,
  grove_tree_view.gd:583 compare to "Not enough Dreamlight", "Struggling", "Reward gone", "Not enough Seeds": these
  break silently once translated. Compare ids, not labels.

---

## 5. What already works

- Grove perk lines: "While carried: +20 starting {dew} per level, up to +60." Short, numeric, one clause; a model for
  every perk.
- "Adds the {legendary} {dream} card {card:x} to the cards your runs can offer." is plain and repeats the same shape.
- Most Crowned texts give numbers and "(bosses: …)" plainly; Still Pool's "(bosses are slowed 30% inside)" is clear.
- Buttons Continue / New run / Settings / Resume / Cancel / Keep my run / Start new run / Apply and close: plain.
- callings.gd:32-33 details define "Touching", "step", "Firefly" in one clause each: good glossary style.

Flagged: 10 top + 53 table rows (24 resources, 10 combat, 19 short UI; a few are "keep / check" notes) and about 45
localisation sites.
