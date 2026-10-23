# Gap round 2026-10-23: new player seat

Seat: I've played a few mobile games, never a tower defence or a roguelite. One read, about 5 seconds: do I know
what happens, to what, when and how much? I read tokens as the player sees them (icon_info.gd TERMS/STATUSES:
{held} = Root, {static} = Charge, {damp} = Soak, {spored} = Poison, {marked} = Exposure, {water} = water,
{toll} = Toll, {lit} = Lit, {new_cards} = Reroll). As briefed, I skipped the calling_paths.gd evolution rows.

## 1. Top 10 problems, ranked

| # | Where | Now | Problem | Rewrite |
|---|---|---|---|---|
| 1 | meta/grove/heartwoods_crown.tres | "Every other {node} is Grown. Adds a sixth {perk} slot: carry 6 {perks} into a run." | "Every other" reads as "every 2nd node" (rule 4 uses "every 2nd" for that idea). It also sounds like an effect ("this makes half your nodes Grown"), when it's the unlock condition (heartwood_memory.gd:437: every other node at max level). | "Grows once every other {node} is fully Grown. Adds a sixth {perk} slot: carry 6 {perks} into a run." Better still: "…once all the other {nodes} are fully Grown." |
| 2 | meta/grove/remembered_seed.tres + seed_picker.gd:94/101/110 | "choose its map: a new one, one you have played before, or a seed you type." / "A seed", "Type a seed", "Dream it" | "Seed" here means a map code, but {seeds} (Seeds) is the meta currency on the same screen and on every results screen. A new player reads "a seed you type" as spending Seeds. "Dream it" doesn't say it starts the run. | Node: "…or a map code you type." Picker: "A map code" / "Type a map code" / "Start". If "seed" stays, add "(a map's number)" the first time. |
| 3 | meta/grove/*_ascension.tres (×9) | "In a run: from {drift} 51, unlock it for 3 {dreamlight}, then grow a {final_form} into it for 600 {dew}." | Three currencies and two steps in one clause. "a {final_form}": any final form at all, or only one of this family? I can't tell where to do it (the Remember screen is never named). | "In a run, from {drift} 51: unlock it on the {remember} screen for 3 {dreamlight}, then grow one of your {family:x} {final_forms} into it for 600 {dew}." (check: same family only) |
| 4 | meta/grove/whirligig_ascension.tres | Title "Ascension: The Whirlwind", token {warden:tempest}; body "carries every status it touches" | The Warden's id is "tempest", and **Tempest** is also a Crowned Reaction (reaction/crowned/tempest.tres). The text is fine (it shows "The Whirlwind"), but any place that falls back to the id would clash. "Carries every status it touches": carries it where, to whom? | "…A cyclone drifts along the path, picks up the statuses of each nightmare it passes and spreads them to the others it touches." (check) |
| 5 | callings.gd:21 acorn Calling | "Every 5th acorn, all Wardens next to the {warden:acorn} attack its target at once." | "acorn" here means the Acorn's attack (its shot?), but the same word names the family and the Warden. I read "every 5th Acorn Warden". "Next to" is not a distance word (rule 7: {touching}). | "Every 5th attack of an {warden:acorn}, all Wardens {touching} it also attack its target at once." (check: whether "acorn" is the shot) |
| 6 | callings.gd:24 rootling Calling | "Every Warden in range turns to a nightmare with {held}, and their hits on it add twice as much status." | "Turns to" reads as "becomes a nightmare". "In range" of what: the Rootling? Each Warden's own range? | "Wardens in a {warden:rootling}'s range attack nightmares with {held} first, and their hits on them add twice the {stacks}." (check) |
| 7 | callings.gd:23 pebbling Calling | "A {warden:pebbling}'s stone lodges in its target. The next hit from another kind of Warden knocks it into the nightmare behind." | "Another kind" means another family? Does the knocked stone deal damage, and how much? "It" could be the stone or the nightmare (rule 13). | "A {warden:pebbling}'s stone sticks in the nightmare it hits. The next hit from a Warden of another {family} knocks the stone into the nightmare behind, hitting it for N damage." (check: the damage) |
| 8 | reaction/crowned/changeling, fever_dream, still_pool | "It trades places…", "It falls {asleep}…", "It sinks, and a still pool stays…" | Opens with "It" before any nightmare has been named; the trigger comes at the end. "Sinks": does it die? Is it dispelled? "Pulled under for 1 s" means it can't move? | "The nightmare trades places with…" / "The nightmare falls {asleep} for 2 s…" / Still Pool: "The nightmare is pulled under for N s (check), leaving a still pool on its cell for 5 s. Each nightmare entering the pool for the first time can't move for 1 s (bosses: slowed 30% inside)." |
| 9 | tower_seller.gd:1007 sell tag "Rooted"; warden_panel.gd:797 "Buffs" | "Rooted" (can't be sold) / heading "Buffs" | "Rooted" means "can't be sold", but {held} shows as **Root** (a status that stops nightmares). Rule list bans "Rooted" as a raw word. "Buffs" is on the banned list too (old name). | "Can't be sold" (or "Planted for good"). Heading: "Bonuses on it". |
| 10 | meta/grove/dewdrop.tres | "Water that gives nightmares {damp}." | "Water" is the Dewdrop Calling's term ({water}: the path next to Dewdrops). A new player thinks the family itself makes water. The other families' lines read "Spores…", "Light…", "Song…", so this one is the odd one out. | "Splashes that give nightmares {damp}." (check against the family's attack word) |

## 2. Every other flagged string

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| grove/*_ascension (pattern) | "the {family:x} {family}'s strongest form" | Fine, but "Ascension" is never explained here; the glossary token is {ascended}. | "Unlocks {warden:x}, the {family:x} {family}'s {ascended} form (its strongest)." |
| grove/bellflower_ascension | "triggers the {static} of each nightmare with 4 or more: its bolt strikes for half damage." | "4 or more" what? Its toll is a plain "toll", but {toll} is a game term with its own meaning. | "Its ring puts every nightmare {asleep}, and each nightmare with 4+ {static} {stacks} releases its bolt at half damage." |
| grove/pebbling_ascension | "Boulders crush and add 1 {held}, and always {crit} nightmares with {held} or {drowsy}." | "Crush": flavour, no number. | "Boulders hit an area, add 1 {held}, and always {crit} nightmares with {held} or {drowsy}." (check: area) |
| grove/sporeling_ascension | "A constant spore storm that pops nightmares like a {warden:puffball}." | I don't know what a Puffball does, so "like a Puffball" tells me nothing. "Pops" = kills? | "A constant spore storm that adds {spored} to every nightmare in range and bursts like a {warden:puffball}." (check) |
| grove/dewdrop_ascension | "Tides roll along the path and wash nightmares back." | How far back? Which nightmares? | "Tides roll along the path and push the nightmares they hit N {steps} back." (check: the number) |
| grove/acorn_ascension | "Wardens in range deal more damage and attack faster" | Fine; "more" with no number is OK for a Grove overview. | keep |
| grove/dewdrop_hidden | "they freeze nightmares with {damp}." | Two readings: freezes nightmares that have Soak, or uses Soak to freeze. | "they freeze nightmares that have {damp}." (check) |
| grove/rootling_hidden | "light that reveals nightmares and gives them {marked}." | Reveals hidden ones? Every nightmare is visible to me. | "light that reveals {kind_hidden} nightmares and gives nightmares {marked}." |
| grove/bellflower_hidden | "they repeat {reactions} that happen in range." | OK. | keep |
| grove/memory_moon_moth | "Reveals every Lurker" | "Lurker" is a nightmare name I may not have met; the token for the idea is {kind_hidden}. | "Reveals {kind_hidden} nightmares in range" (check: only Lurkers, or every Hidden?) |
| grove/memory_pond_keeper | "pulls the nightmare furthest along the path back to its pond." | Where is its pond? Rule 11: "the leader". | "Its tongue pulls the leader back to the Pond Keeper's pond (beside it)." (check) |
| grove/memory_* (×3) | "Grows the first time you dispel the Moth Queen. After that it can be your reward for dispelling that boss." | "Grows" for a Grove node = unlocks; "can be your reward": always or sometimes? | "Unlocks the first time you dispel the Moth Queen. After that, it can be offered as a reward when you dispel that boss." |
| grove/second_thoughts | "+1 {dream} reroll per run per level, up to 3." | Owner decision: Reroll is a term ({new_cards}); plain "reroll" isn't a link. | "+1 {new_cards} per run per level, up to 3." |
| grove/perks (pattern) | "While carried: …" | "Carried" is unexplained the first time; the button says "Carry". | Glossary link on first use: "While carried (in a {perk} slot): …", or make "carried" a link. |
| grove/deep_taproot, morning_stores, rested_roots, rich_dew | "per level, up to …" | "Level" of what? A node's level shows only as dots. | Keep, but make sure the node shows "Level 1 of 3" next to it. (check UI) |
| grove/mixed_company, quickening | "it upgrades the start pool's {card:mixed_grove}, offered once you hold it." | "Start pool" and "hold" are jargon. "It" is ambiguous. | "Adds the {dream} card {card:mixed_grove_ii}, an {upgrade} of {card:mixed_grove}. It can be offered once you have {card:mixed_grove}." |
| grove/wider_roots | "Adding another {branch} costs 4 {dreamlight}." | Adding where, and when? | "Unlocking a further {branch} costs 4 {dreamlight}." (check) |
| grove/planted_promises | "cards that pay off later in a run" | "Pay off" is on the avoid list. | "cards that grow stronger later in a run" |
| grove/strange_dreams | "cards that gamble" | OK for a summary. | keep |
| grove/leaf_or_dew | "Your max {leaves} change with them." | "Them" = the trades? | "Your max {leaves} change by the same number." |
| grove/kindling | "a random Common {dream} card" | "Common" is a rarity. Is it shown capitalised as a word anywhere on cards? codex_panel.gd:1771 uses Common/Uncommon/Rare/Legendary; ui_style.gd:35 also has Mist/Sprig/Dewlight/Gold. | Keep "Common" if that's the word on the card; make sure only one rarity name set reaches the player. (check) |
| grove/dead_wood | "clears every Withered Tree on the map" | Fine (it's a named obstacle). | keep |
| grove/elders | "the fewer attacking Wardens you have, the stronger each one is." | Good. | keep |
| grove/omen_reader | "facing an {omen} shows 3 to choose from instead of 2." | 3 what? | "…shows 3 {omens} to choose from instead of 2." |
| grove/tending_hands | "the {eldest} can be nurtured to {rank} VII." | Fine; "VII" Roman numerals for a mobile player are OK because ranks show them. | keep |
| drift/template/special, mixed | "Special", "Mixed" | If shown to players (coming strip?), "Special" says nothing about the drift. | "Special" → "Strange ones" or the trait it brings. (check: is it shown) |
| crowned/avalanche | "Scree covers the path under the stone for 4 s" | "Scree" is a rare word (loose stones). "Under the stone": which stone? | "Loose stones cover the path where the stone lands, for 4 s: …" |
| crowned/starfall | "takes a crit for half the hit." | Is it a crit or half a hit? Two numbers fight. | "…takes half the hit's crit damage." |
| crowned/tempest | "Each arc triggers {combo:ignite} … Ignite's spreading spores also spread {static}, so more Thunderclaps follow. Needs 6 {spored} on a {combo:thunderclap}." | "Arc" is unexplained (it's a term token {arc}, not linked here). Raw "Ignite" / "Thunderclaps" are next to their tokens. It says "Needs" while the 9 siblings say "Triggered by". | "Each lightning {arc} of the {combo:thunderclap} triggers {combo:ignite} on nightmares with {spored}, and those spores also spread {static}. Triggered by a {combo:thunderclap} on a nightmare with 6 {spored}. Each nightmare once every 2 s." |
| crowned/prismstorm | "The ice shards spark" | Which ice shards? (Shatter's, I guess.) | "The {combo:shatter}'s ice shards spark: …" |
| crowned/nightbloom | "their sleep doesn't run out" | Forever? Until what? | "…don't wake from hits and stay {asleep} while they are inside the cloud." (check) |
| crowned/wide_awake | "The scream startles your attacking Wardens" | Whose scream? Flavour first, effect second. | "Every attacking Warden within 3 cells attacks 40% faster for 3 s. Triggered by…" |
| callings.gd:30 firefly tip | "by a hit, a {spored} tick or a cloud" | "A cloud": which cloud? | "…a {spored} tick or a spore cloud" |
| callings.gd:31 sporeling tip | "Flyers pass over them, so it is weak against flyers." | Strategy advice (no hand-holding). | "Flyers pass over them." |
| callings.gd:20 bellflower | "Each bell hit rings the nightmare; at 4 rings it is a {toll}…" | "Bell" is only defined in the tip. Semicolon. | "Each hit from a bell (any Bellflower) adds a ring. The 4th ring is a {toll}: the hit lands again at half damage. Nightmares start with 2 rings." |
| callings.gd:22 nestling | "A {warden:nestling}'s bird can also swoop from any of your Wardens within 3 cells" | Swoop from a Warden = starts its attack there? | "A {warden:nestling}'s bird can attack from any of your Wardens within 3 cells, and its hit adds that Warden's status." |
| callings.gd:25 whirligig | "pulses and splashes spread 1 cell wider" | "Splashes" plain, while {dew_splash} also shows "splash". | "area attacks spread 1 cell wider" |
| kinships.gd:675 | "No kin: the %s in range is bonded to its %s" | "Bonded": unexplained word. | "No kin: the %s in range already has a kin (its %s)." |
| kinships.gd:859 | "Kindred: the %s family +%d%%" | +N% of what? | "Kindred: the %s family deals +%d%% damage" (check stat) |
| buff_sources.gd:133 | "Cold lantern %s attack speed" | Source not named as the player knows it (capitalised name? an Omen? a nightmare?). | Use the source's display name. (check) |
| support_log.gd:179 | "Adds %d path tiles" | "Tiles" is a banned word; use {steps}. | "Adds %d path {steps}" |
| support_log.gd:172/176 | "Caught this run: %d Dew" / "Added this run: …" | Fine. | keep |
| rest_report.gd:354 | "Top support" / "Best supporter" | Two names for one row. | One: "Best support". |
| boss_dossier.gd:141/535/595 | "Face it", "Hunt it", "Prepare" | "Prepare" = go back and build? "Hunt it" = choose this boss? | "Face it" OK. "Hunt it" → "Choose this boss". "Prepare" → "Back to the map". (check) |
| chain_counter.gd:55 | "Chain" | Counts what? | Keep only if the Codex link ({chain}) is on it; else "Chain: N in a row". (check) |
| drift_panel.gd:83/91/134 | "Remember", "Sapling", "Auto" | "Remember" opens the unlock screen: the word doesn't say that. "Auto": auto what? | "Remember" (term, keep, but give it a tooltip "Unlock forms"); "Auto" → "Auto-start". |
| drift_panel.gd:244 | "Final drift" | OK. | keep |
| family_pick_screen.gd:611 | "Wake %s" | Wake = take this family? Fine after one use, but the first time I didn't know a button would pick it. | "Wake %s" is OK with the flavour; consider "Choose %s" on the first pick. |
| family_pick_screen.gd:741 | "Dreams into" | Unclear heading. | "Its Dream cards" (check meaning) |
| family_pick_screen.gd:1033 | "A Memory returns" | OK as flavour. | keep |
| omen_screen.gd:615 | "Clear Skies" | The skip option reads like another Omen. | "Clear Skies (no Omen)" |
| omen_screen.gd:537 / 505 | "Reward %d%%", "Reward gone", "Reward lost" | Two words for one idea. | Pick one: "Reward lost". |
| omen_screen.gd:574 | "Omens locked" | Why? Until when? | "Omens locked this {rest}" (check) |
| lesson_demo.gd:84 | "Wellsprings" | New word with no hint. | Make it a link, or "Wellsprings (bonus Dew)". (check) |
| remember_screen.gd:632 | "Add, free" / "Add %d" | Add what, to where? | "Add branch, free" / "Add branch %d". (check) |
| remember_screen.gd:1298 | "Ascended" (column) | OK if linked. | keep |
| results_screen.gd:202 | "Memory Grove" (button) | A new player doesn't know it's where Seeds are spent; the demo's "Plant your Seeds" says it. | "Memory Grove: plant Seeds" or use "Plant your Seeds" in both. |
| results_screen.gd:228 | "Title" | Short. | "Title screen" |
| grove_screen.gd:264 | "Carry" | Opens the perk loadout: verb with no object. | "Choose perks" |
| grove_screen.gd:211 | "Plant first" | Heading for the nodes needed first? | "Grow these first" (check) |
| grove_screen.gd:829/834 | "More Dew" / "More leaves" | Fine. | keep |
| warden_panel.gd:1395 | "Choose as Tallest" | "Tallest" is not in the glossary. | Link it, or say what it does. (check) |
| warden_panel.gd:722 | "Mixed" target chip | Fine once seen. | keep |
| warden_panel.gd:1594 | "Whole Tree" / "Kindred" | OK if linked. | keep |
| touch_build.gd:164 | "Confirm (%d)" (phone) vs "Plant %d" (PC) | Phone loses the verb. | "Plant %d" on both. |
| dream_screen.gd:514 | stage tags "Style", "Follow-up", "Capstone", "Finale" | "Capstone" is uncommon English. | "Capstone" → "Peak" or "Third step". (check with Finale ruling) |
| drift_meter.gd:440 | "Maze %s DPS" | "DPS" is gamer jargon; mobile players may not know it. | "Maze damage per second: %s" |
| pause_menu.gd:383 | "Leave the dream?" | Leave the run or quit the game? | "Quit the game?" (the run is saved: check) |
| hud.gd:2018 | "Plant for" | Fine. | keep |
| codex_panel.gd:665 | "Applied by" | Fine. | keep |
| settings_panel.gd:178 | "Growth marks" | What are they? | Add a one-line tooltip. (check if present) |

## 3. Patterns and rules

- **"It" before a subject:** Crowned Reactions open with "It …". Open with "The nightmare …" (rule 13).
- **The same word for two things:** seed/Seeds, Root/Rooted, water/{water}, toll/{toll}, splash/{dew_splash}, acorn/Acorn. Fix: give each meaning its own word.
- **Flavour verbs with no numbers:** crush, pops, wash back, carries, sinks. Fix: name the effect and the amount.
- **Buttons with no object:** Carry, Add, Auto, Prepare, Hunt it, Title. Fix: verb + object, 2-4 words.
- **Undefined Grove words:** carried, level, start pool, hold. Fix: link the term the first time, or replace it with plain words.
- **Raw names next to tokens:** Ignite, Thunderclaps, Lurker. Fix: token or plain kind word.
- **Ascension rows:** one long clause with 3 currencies. Fix: split into two sentences and name the Remember screen.

## 4. What already works

- Family nodes are short and clear ("Fast birds that fly out to hunt nightmares").
- Perk lines say the number and the cap ("+20 starting {dew} per level, up to +60").
- Blight picker: "No extra difficulty." / "+N% Seeds": clear.
- Title confirm "Keep my run / Start new run", Lessons "Got it / Skip lessons": perfect for first-timers.
- combo_feedback "a Reaction: two statuses meet on one nightmare": the best one-line definition in the game.
- Crowned Reactions mostly give exact numbers, durations and boss exceptions.
