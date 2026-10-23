# Wording Council: the new player's seat

Reader: has played a few mobile games, never a tower-defence or roguelite game. Test for each string: after one read (about 5 s), do I know what happens, to what, when, and how much?
Corpus: corpus_resources.txt (every .tres text) + corpus_ui.txt (UI/run/meta strings), read in full, judged as the player sees them (tokens resolved via icon_info.gd: {damp} Soak, {drowsy} Sleep, {spored} Poison, {marked} Exposure, {static} Charge, {held} Root).
Read-only: nothing in the repo was changed. A few facts were checked against the code (noted "verified"). "(check)" = I'm not sure of the mechanic.

---

## 1. Top 10 problems (ranked by harm to understanding)

### 1. Card diagrams contradict the card text
The picture is the first thing a new player trusts. On these cards, the caption gives a different number (or condition) from the description.
| Card | Description (correct, verified in dream_state.gd) | diagram_caption now | Rewrite of caption |
|---|---|---|---|
| crossroads | "…deals 100% more damage." (CROSSROADS_BONUS 1.0) | "Touches the path at steps 1 and 7, 6+ apart: +40%. ✗ steps 2 and 6 are only 4 apart." | "Touches the path at steps 1 and 7, 6+ apart: +100%. ✗ steps 2 and 6 are only 4 apart." |
| briar_crown | "…takes 60% of a hit from the strongest attacking Warden {touching} it." (BRIAR_SHARE 0.60) | "A nightmare stepping beside the Thornwall takes 25% of the strongest Warden touching it." | "A nightmare stepping beside the Thornwall takes 60% of a hit from the strongest Warden touching it." |
| sprout_chorus (Thicket) | "Sprouts {touching} 2 or more path cells attack 20% faster." (SPROUT_CHORUS_SPEED 0.20; the touching-Sprout rule is gone) | "W touches another Sprout and at least 2 distinct route cells: +30% attack speed." | "This Sprout touches 2 or more path cells: attacks 20% faster." |
Also in Thicket's caption: "W" (an unexplained letter) and "route" (banned word: path). Back-row Roots' caption has the same "Back row W". Rule: captions must be built from the same numbers as the description, or get a check in test_text_style.

### 2. The Codex teaches the old family-pick schedule
Verified: picks are after drift 1 and at the rests after drifts 10, 35 and 60 (drift_director.gd); no boss rest brings a pick. The glossary still says otherwise, so a new player waits for a pick that never comes.
| Where | Now | Rewrite |
|---|---|---|
| codex_data.gd:27 Family pick | "After drift 1 and after each boss: choose a new Warden family for this run. With none left, the Heartwood gives Dreamlight instead." | "After drift 1, then at the rests after drifts 10, 35 and 60: choose a new Warden family for this run. With none left, the Heartwood gives Dreamlight instead." |
| codex_data.gd:26 Boss | "…Dispelling it brings a family pick, Dreamlight and a rare Dream." | "…Dispelling it brings Dreamlight and a Rare Dream." |
| codex_data.gd:14 Dreamlight | "Freed by great nightmares (bosses, the first family pick): …" (a family pick isn't a nightmare) | "Comes from bosses and the first family pick. Unlocks branches and final forms on the Remember screen." (check the sources) |

### 3. Three different rules for what sets off a Reaction
The lesson that teaches stacks, the glossary and the keyword chip disagree:
- lesson_card.gd:216 STACK_TEXT: "Two full statuses on one nightmare set off a {reaction}." (Reactions need their own thresholds, not full; the Soak tooltip says "At {stacks:need_damp} stacks".)
- dream_keywords.gd:45: "Two statuses on one nightmare go off together. Any two can." (The glossary says each pair has its own Reaction; there are 8.) (check)
- codex Reaction: "When a nightmare carries enough stacks of two different statuses…" (correct)
Rewrites:
- STACK_TEXT: "Some Wardens leave a status on nightmares. Each hit adds a stack; the icon above a nightmare shows how many. Enough stacks of two statuses on one nightmare set off a {reaction}. Blue corner brackets round a status: enough stacks for a Reaction."
- Keyword "Reactions": "Enough stacks of two statuses on one nightmare go off together."

### 4. Poison's timing is told two ways
- lesson_card.gd:222: "Each stack lasts 5 s, so keep hitting it."
- icon_info.gd Poison: "Every new stack keeps the whole pile going; it wears off 5 s after the last one."
The lesson says stacks fall off one at a time; the tooltip says the whole pile stays until 5 s after the last stack.
Rewrite of the lesson: "It takes damage every second, more per stack. It wears off 5 s after the last new stack, so keep hitting it. At {stacks:need_spored} stacks it can set off {reactions}."

### 5. Four names for "new cards", two for "banish", and two buttons that sound alike
- Button: "Dream again · N left", tip: "Rerolls don't refill", Wandering Mind: "Gain 2 Dream rerolls", glossary entry: "New cards".
- Button: "Let go · N left", tip "Let-gos don't refill… More come from Let Go (Memory Grove)", glossary: "Banish". wording_review section 1 already bans "Let Go" as the action.
- "Let go" (remove one card for the run) sits next to "Let it pass" (skip the whole offer): a new player can't tell them apart.
Rewrites (dream_state.gd ~3101–3118, wandering_mind.tres):
- "New cards · N left" / "No new cards left this run"; tip "Shows three new cards. Doesn't refill: N left this run. More come from Second Thoughts (Memory Grove) and the Wandering Mind card."
- "Banish · N left" / "No banishes left this run"; tip "This card won't come back this run; another takes its place. Doesn't refill: N left this run. More come from the Memory Grove." (check the Grove node's name; if it is "Let Go", rename it too)
- Wandering Mind: "Gain 2 more uses of {new_cards}."

### 6. "Every second ring" reads as a time
"Every second" in a game full of seconds means "once per second" to a new player. Verified: Bellflower is status_every = 2, so it means every other ring.
- bellflower.tres: "Rings out, damaging every nightmare in range. Every second ring on a nightmare gives it {drowsy}." → "Rings out, damaging every nightmare in range. Every other ring on a nightmare gives it {drowsy}."
- dream_bellflower.tres: "…every second pulse gives the nightmares around it {drowsy}." → "…every other pulse gives the nightmares around it {drowsy}."
- thorncoil.tres / dream_thorncoil.tres: "every second one has {held} in its range, it takes thorn damage" → "a nightmare with {held} in its range takes thorn damage each second."

### 7. One word, two meanings: chain, jump, Charge
{chain} is a glossary term (Reactions setting each other off) and {jump} is a glossary term (damage passing as a spark), but Warden text uses both as plain verbs for lightning:
- stormcap.tres: "Lightning that chains to 4 nightmares; jumps further and more often between those with {damp}." role_line "Chains, Charges"
- thunderhead.tres: "Chains to 4; every 3rd strike hits every nightmare with {damp} in range."
- stormheart.tres: "Its lightning jumps to every nightmare in range (−15% per jump)"
Rewrites:
- Stormcap: "Lightning that strikes up to 4 nightmares, one after another; it {jumps} further and more often between those with {damp}." role_line: "Hits several, Charges" (check with Tower Code: role lines are theirs)
- Thunderhead: "Strikes up to 4 in a row; every 3rd strike hits every nightmare with {damp} in range."
- Stormheart: "Its lightning {jumps} to every nightmare in range (−15% per {jump}) and leaves 2 {static}."
Related: "Charged Bloom" (static_bloom) adds Sleep, not Charge; the name points at the wrong status. (Name change is a design call; flag only.)

### 8. Hunter's Patience hides a second effect in the tip
- Description: "Wardens deal 50% more damage to {deeply_blighted} nightmares and bosses."
- Tip: "Hits only, not statuses. Wardens' hits also deal 40% more to flyers."
A player choosing between cards reads the description only. Rewrite: description "Wardens' hits deal 50% more damage to {deeply_blighted} nightmares and bosses, and 40% more to flyers." tip "Hits only, not statuses."

### 9. "Free rank" that "waits until you Nurture"
- clean_night (Hard-Won Rings): "…gets a free Nurture {rank}… The {rank} waits until you Nurture."
- growth_rings: "…gets a free Nurture {rank}, up to {rank} III." tip "The {rank} waits until you Nurture."
A new player reads "free" as "it levels up now", then sees nothing happen. (check: I read it as "the next Nurture on that Warden costs nothing")
Rewrite (Hard-Won Rings): "Each Warden that dispels 40 nightmares banks a free Nurture {rank}: its next Nurture costs no {dew}. Again every 40, up to {rank} V." Growth Rings likewise: "…the {block}'s top Warden banks a free Nurture {rank} (its next Nurture costs no {dew}), up to {rank} III."

### 10. "At the start" in Omens: the map's start or the block's start?
Both readings make sense, and they mean different things.
- second_path: "…the Thornwall that makes the path longest crumbles at the start (full refund)." → "…crumbles when the first of these drifts begins (full refund)." (check)
- shifting_ground: "…5 Withered Trees sprout on empty ground at the start." → "…5 Withered Trees sprout on empty ground near where nightmares enter." (check: or "when the first of these drifts begins")

---

## 2. Every other flagged string

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| dream/afterglow | "Every 5th link of a {chain} gives nightmares within 2 cells 2 {stacks} of each status in that {reaction}." | "link of a chain" is two layers of jargon in one line | "When a {chain} reaches its 5th {reaction} (and every 5th after), nightmares within 2 cells get 2 {stacks} of each status in that {reaction}." |
| dream/alarm_bells | "Wardens startled by {named_combo:wide_awake} startle every Warden {touching} them too: one more step of 40% faster attacks." | "startled" and "one more step" never explained | "When {named_combo:wide_awake} speeds up your Wardens, every Warden {touching} them also attacks 40% faster." (check) |
| dream/brimming | "{reactions} set off with twice the usual {stacks} hit 2.2 times as hard." + tip "{reactions} still fire at their usual count." | reads as a contradiction: twice the stacks, or the usual count? | "Nightmares hold twice as many {stacks} of every status. A {reaction} that goes off with double the usual {stacks} hits 2.2× as hard; with the usual count, it hits as normal." |
| dream/sap_rising tip | "…bosses and Deeply Blighted a tenth." | raw keyword, not a link | "…bosses and {deeply_blighted} ones a tenth." |
| dream/damp_rot cost | "{damp} no longer makes {family:dewdrop} hits stronger on them." | Soak's tooltip says "Water hits", not Dewdrop hits: two ways to say it | "{damp} no longer makes Water hits stronger on them." (check) |
| dream/deep_water | tip "Bosses are slowed 40% instead of 30%." | a new effect only in the tip | add to description: "…grows 50% faster, and slows bosses 40% instead of 30%." |
| dream/dew_trail | "{warden:dewcatcher}s catch 0.5 cells further." | "catch" as a distance verb | "{warden:dewcatcher}s catch {dew} from 0.5 cells further away." |
| dream/dream_autumn_gale | "…seeds down the busiest lines; each caught seed that hit something…" | "caught" by whom? | "…seeds down the busiest lines; each seed that hits something and comes back makes the next throw…" (the tower text already says this) |
| dream/dream_bastion | "its stone walls drop rocks on the path." | which walls? how often? | "every {field:bastion.special_params.rock_every:seconds}, each Thornwall beside it drops a rock on the path." |
| dream/dream_bramble | "(+{dew:…} each)" | "+" and "each" differ from every other grow card | "({dew:{grow_cost:bramble}} each)" |
| dream/dream_crown_of_thorns | "sharper thorns that spread at half to the nightmares {touching} one with {held}." | "at half" banned; what spreads? | "sharper thorns; nightmares {touching} one with {held} take half the thorn damage." |
| dream/dream_dreamroot | "shards double on a perfect block." | raw keyword; "shards" of what? | "{dreamlight} shards double in a {perfect_block}." |
| dream/dream_earthshaker | "a wider slam that cracks the path." | what does cracked path do? | "a wider slam that cracks the path: nightmares can't start a sprint there." |
| dream/dream_grove_keeper, tower/grove_keeper | "a seed every N {drifts}" / "Grows a free Sprout seed" | "seed" next to Seeds (the Grove currency) | "a free Sprout every N {drifts}…" |
| dream/dream_jetreed | "an erosion jet that wears down a share of its target's max health." | raw "erosion" (Torrent links {erosion}); "a share" = how much? | "a jet of {erosion}: each hit also takes {field:jetreed.special_params.erosion:pct} of its target's max health." |
| dream/dream_lichenling | "crusted spores that strip {dread_shells} and stop mending." | who stops mending? | "spores that wear {dread_shells} away and stop nightmares healing." |
| dream/dream_lightning_fence | "a stronger fence that catches Phantoms too." | raw nightmare name (should be ??? until met) | "…catches {nightmare:dandelion_seed}s too." |
| dream/dream_magpie_perch, tower/magpie_perch, magpies_hoard | "each hit steals a boost from its target" / "removes a boost" | nightmares' "boosts" are never named; Kinship text (flock_together) explains them | tip: "Boosts: a {dread_shell} chip, a Weeper's mending, an Omen's bonus." (check) |
| dream/dream_nestling, tower/nestling | "extra damage to Phantoms" | how much? (Starling/Wren same) | give the number from data, e.g. "+{field:…:pct} damage to …" (check) |
| dream/dream_quaker | "a slam that stops sprints." | jargon "sprints" without subject | "a slam that stops sprinting nightmares." |
| dream/dream_rampart | "heavy blows… and turn them to stone." | what does stone do? | "…and turns them to stone: they can't be trampled or burrowed under." |
| dream/dream_resonance | "the cone widens for each nightmare with {drowsy} in it." | ok, but "Resonance" is also an old removed mechanic name | keep; note for naming |
| dream/dream_seedbearer | "every few {drifts}" | vague | "every {field:seedbearer.special_params.seed_every:count} {drifts}" |
| dream/dream_whetstone | "the finisher, its hits on worn-down nightmares land far harder." | no number, no threshold (tower text has them) | "its hits on a nightmare below 30% health deal ×2.5 damage (×1.5 on bosses)." |
| dream/dream_windmill | "bigger, faster blades; loves bends." | flavour hides the mechanic | "bigger, faster blades; 35% more damage for each extra path cell around it." |
| dream/dream_heartroot | "the first nightmare to reach the Heartwood is dragged back." | how far? | "…is dragged back {field:heartroot.special_params.not_yet_tiles:count} cells." |
| dream/dream_deeproot | "nightmares near the Heartwood…" | "near" is a defined term (2 cells) but the real reach is a field | "nightmares within {field:deeproot.special_params.goal_reach:count} cells of the Heartwood…" |
| dream/dream_vesper_bell | "…echoes to the next-strongest nightmare at half." | "at half" banned | "…also hits the next-strongest nightmare for half damage." |
| dream/dream_great_bell vs tower/great_bell | card: nightmares with N+ {static} stacks release a bolt; tower: "every nightmare with {static}" | the two disagree on the threshold | tower: "…every nightmare with {field:great_bell.sets_off_static_at:count} or more {static} is struck by its bolt for half damage." (check) |
| dream/eye_of_the_tempest | "Nightmares burning from a {named_combo:tempest}… so its {arcs} never run dry." | "burning" and "run dry" are images, not rules | "Nightmares set burning by a {named_combo:tempest} give 1 {stack} of {damp} to those beside them each second, so its {arcs} keep finding targets." |
| dream/falling_stars | "…is marked: its next hit is a crit for ×2. These crits never pierce." | "marked" (Exposure's old name) and "pierce" undefined | "…is singled out: its next hit is a crit for ×2 (this crit never passes through to others)." |
| dream/fresh_growth tip | "Only a Warden that stood at the last {rest} sets it off." | "stood" = was already planted | "Only a Warden planted before the last {rest} sets it off." |
| dream/grandfather_stump | "…gets 4% stronger for each Warden {touching} it, up to 45% faster in all." | "stronger" then "faster" | "{warden:elder_stump}'s aura makes Wardens attack 4% faster for each Warden {touching} it, up to 45% in all." (check) |
| dream/hammerfall, flashover, sparks_fly, brushfire | "half {jumps} to the nearest other nightmare" | "half" of what? | "half its damage {jumps} to…" |
| dream/heartwoods_reach | "You can clear obstacles, and your next 5 clears are free." | a new player doesn't know clearing is locked | "Unlocks the Clear tool: remove obstacles from the map. Your next 5 clears are free. The first Warden…" |
| dream/heavy_going tip | "A slowed nightmare drips while it counts." | flavour in a rule tip | "A slowed nightmare shows drips while the bonus applies." |
| dream/hollow_ground caption | "Planted in a moved hollow" | "moved hollow" never defined | "Planted where you moved a boulder or cleared a log: +1 range." |
| dream/homesick tip | "the Puddles {calling}'s Whirlpool and Drowning Deep" | evolution names a new player has never seen | "…the Puddles {calling}'s pulling evolutions…" |
| dream/last_drop | "the nightmare takes 40% of their hit per {stack}, up to 3 hits." | "their hit", "per stack, up to 3 hits" | "…the nightmare takes 40% of that Warden's hit for each {stack} that ran out (up to 3 stacks)." (check) |
| dream/longer_roots caption | "Back row W: +1 range." | "W" | "A Warden one cell back from the path: +1 range. The dim Warden touches the path and gains none." |
| dream/lucid_dream (Borrowed Branch) | "…one of its {branches} it didn't offer this run is unlocked now, free." | "it didn't offer" — the family doesn't offer | "Choose one of your {families}: add one of its {branches} that isn't in this run, free." |
| dream/mothers_hand | "adds 1 more {stack} with each status." | "with each status" reads as "of every status" | "A Warden {touching} a support Warden adds 1 more {stack} each time it adds a status." |
| dream/nightshade | "…carrying statuses from 3 different families." | statuses come from Wardens, not "families"; tip says "each status counts once" | "…on nightmares carrying 3 or more different statuses." (check: if it really is families, say "statuses from Wardens of 3 different families") |
| dream/old_rain | "…deals 40% more if it spends a status a card made last longer." | three clauses deep | "…deals 40% more when a status it uses up was kept on longer by a card." |
| dream/restless_dreams (Waking Dreams) | "…every Dream shows only 2 cards and can't be let pass." | ungrammatical button-speak | "…every Dream shows only 2 cards, and you must take one." |
| dream/rude_awakening tip | "Each bell once a second." | the card isn't about bells (leftover) | "Each Warden once a second." (check) |
| dream/scarred_bark | "makes later {drift} {dew} pots 2% bigger" | "pot" is undefined on the card (glossary has "The Dew pot") | "makes every later {drift} pay 2% more {dew}, up to +20%." |
| dream/shared_light, dew_bowl, kind_canopy, patient_roots (grows_text) + dream_screen.gd:461 "Grows with %s: %s" | "Grows with Acorn: Aura bonuses are 50% stronger." | "Grows with" doesn't say when it applies | "With %s: %s" or "If you have %s: %s" (check the rule behind grows_text) |
| dream/slow_burn tip | "…{card:waterlogged}… Calling evolution such as Riverside." | a Calling path name new players haven't met | "…or a Calling evolution." |
| dream/starlit_aim cost | "A crit uses up half of the {marked} {stacks} needed." | "needed" for what? | "A crit uses up half the {marked} {stacks} it took to fill it (the tip has the numbers)." |
| dream/static_bloom (Charged Bloom) | name says Charge, effect is Sleep | name misleads | flag for naming (Roguelite Code) |
| dream/twig_walls | "Thornwalls you plant take a quarter of a cell" | a cell is "2×2 small squares": quarter = one small square? | "Thornwalls you plant fill one small square (a quarter of a cell) and cost half as much." |
| dream/waymark tip | "Sprouts and Thornwalls build the second leg. A bet: a kill zone on each leg." | "leg" undefined (the description itself is clear) | "…build the path from the Waymark to the Heartwood. A bet: a kill zone on each half of the walk." |
| dream/wild_growth | "a new form after 20, 60, then 150 in their range" | "20" what? | "a new form after 20, then 60, then 150 dispels in their range." |
| dream/winding_path | "…up to +30% Dew from every {drift}." | raw "Dew" (should be the {dew} icon) | "…up to +30% {dew} from every {drift}." |
| dream/witching_bend, heavy_heart tip | "It needs half the usual {stacks} of each ({drowsy} still {full})." | good, but long; fine | keep |
| omen/lean_season flavour | "A thin season, with a strange gift at its end." | flavour promises a gift the text doesn't show | "A thin season. The wind remembers who endured it." (or make sure the reward line is on the card) |
| omen (all) | description lists only the twist | new player can't see the reward on the card itself (check: the Omen screen adds a reward line) | keep if the screen shows "At the rest: …" under each |
| reaction/thunderclap | "×12 damage, ×6 per arc" | ×12 of what? | "×12 of the bolt's damage, ×6 for each arc" (check the base) |
| reaction/drown | "It is pulled under for 3 s…" | "It" with no subject when read in the Codex list | "The nightmare is pulled under for 3 s…" (same for Ignite, Lightning Rod, Night Terror, Pinned, Shatter, Sleepwalk, Smother) |
| reaction/shatter | "A crit or heavy hit on it…" | "heavy" is a linked term ({heavy} Warden) | "A crit or a hit from a {heavy} Warden…" (check) |
| reaction/lightning_rod, thunderclap | "10 {static} (15 on bosses)" | typed numbers; every other Reaction uses {stacks:…} | "{stacks:need_static} {static}" with a boss token (code change; check) |
| enemy/hollow_oak | "Plants Thorn-Saplings that bend the path, and grieves as it weakens" | "grieves" hides what happens | "…and grows more dangerous as it weakens: leave room to change your maze." (check what grieving does) |
| enemy/drowned_one hint, nightmare_icons always_damp | "Lightning loves {damp}" / "lightning loves it" | flavour instead of rule | "Lightning deals more to nightmares with {damp}." |
| tower/puffball | "Its puffs burst over a tile" | "tile" banned (cells) | "…burst over {field:puffball.splash_radius:cells}…" |
| tower/frostfern | "Pair it with Wardens that Soak." | hand-holding on a card; "Soak" as a verb | "It adds no {damp} of its own." |
| tower role lines | "Drowses" (Bellflower, Bloomcap, Silver Bell, Vesper Bell, Honeysuckle…) | every other status verb matches its name (Soaks, Roots, Poisons, Exposes, Charges); Sleep's doesn't | "Puts to sleep" is taken; use "Sleeps" or "Adds Sleep" (owner call) |
| tower/lichenling, old_lichen role lines; signatures CRUSHING; IconInfo COUNTER_WORDS | "breaks armour", "armoured nightmare" | the game's name is {dread_shell}; "Armoured" is also a Kind | "breaks shells"; "a nightmare with a {dread_shell}" |
| tower/echo_hollow, whispering_hollow | "echoes Reactions", "a Reaction chain" | raw keywords, not links | {reactions}, {chain} |
| tower/heartwood_sapling | "1 {dreamlight} every 10 drifts… from rank III, Dreamlight every 8 drifts" | raw "drifts", "rank", "Dreamlight" | tokens |
| tower/grandmother_oak | "within her range (3 cells)" vs other auras "the 8 cells around it" | fine; keep | — |
| codex_data.gd:52 Harvest and interest | "…at most 130 a rest for all Wellsprings together." | stale: INTEREST_CAP is 260 (verified; Wellspring card says 260) | "…at most {dew:260} a rest…" (better: read DewCatch.INTEREST_CAP) |
| codex_data.gd:24 Rest | "rebuild freely at a 75% refund" | "freely" + 75% fights itself | "The pause after a block: a Dew bonus, a Dream, sell for 75% back, then Start." |
| codex_data.gd:83 Touching | "Within 1 cell on both sides: the 8 cells around a Warden. A Warden touches the path within 1.25 cells…" | three definitions in one; "on both sides" unclear | "The 8 cells around a Warden. For the path: within 1.25 cells of the Warden's middle. Two nightmares touch within 1 cell of each other." |
| codex_data.gd:126 Effect | "…clouds, rings, Reactions." | "rings" also means bell hits and Fairy Ring traps | "…clouds, traps, Reactions." (check) |
| codex combos (codex_data.gd:279–297) | "neighbors", "Catch nightmares", "the sniper's eye (+10% crit chance at ×2.5)" | US spelling breaks the UK rule; "Catch" capital verb; flavour wrapper | "neighbours"; "catch"; "Mossback gets +10% crit chance, crits ×2.5" |
| codex_data.gd:178 etc. | "Arcs can set off Ignite once targets reach 12 {spored} and 8 {static}" | typed numbers in a status rule | {stacks:…} tokens (check) |
| dream_keywords.gd:56 Soak | "{damp}: the nightmare conducts water and lightning." | "conducts water" means nothing | "{damp}: Water hits deal more, and lightning spreads through it." |
| lesson_card.gd:224 Charge | "Other statuses can set it off early as a {reaction}." | fine; "early" = before the bolt | keep |
| family_pick_screen.gd:830 | "Dreams into, %d of %d this run" | cryptic | "Branches this run: %d of %d" |
| family_pick_screen.gd:566 | "Sprout into it" | reads like a command to a Sprout | "Grow a Sprout into it" |
| remember_screen.gd:552 MISTY_TIP | "the dream offers… call one in for Dreamlight… find the Borrowed Branch card" | "this dream" and "call in" banned (wording_review §1) | "Each run offers only some of a family's branches. These weren't drawn this time: add one for Dreamlight (once per family), or take the Borrowed Branch card." |
| remember_screen.gd comments / heads | "Not in this dream" vs "Not in this run" | two names | "Not in this run" everywhere |
| remember_screen.gd:639,1030 | "Its final still costs %d." | "final" shorthand | "Its final form still costs %d Dreamlight." |
| remember_screen.gd:1120 | "Waking Root: %s less, once." | what is Waking Root? less of what? | "Waking Root (Grove perk): your first unlock costs %s less." (check) |
| dream_tempo_view.gd:30 | "Turnover +%d%% · %.1fs" | jargon; no space before s | "New-target bonus +%d%% · %.1f s" (check) |
| warden_header_view.gd:381 ROLE_TAGS_TIP; warden_panel "wakes Hammerfall" | "Some Dream cards wake only once…", "wakes Hammerfall" | "wake" = "can be offered" | "…only appear once…"; "unlocks Hammerfall offers" |
| warden_panel.gd:287 | "Reactions: set off %d · fed %d" | "fed" | "Reactions: set off %d · helped %d" |
| warden_header_view.gd:534; results_screen.gd:354; meta_run.gd:23; tower_placer.gd:1938 | "Sprites walk %d tiles", "Longest path: %d tiles", "Build a 130-tile path", "pick a square" | "tiles"/"square" banned (cells) | "cells" throughout |
| dream_batch_rules.gd:617 | "Lash now: %d damage." | "Lash" is undefined | "Thorns now: %d damage a hit." |
| dream_batch_rules.gd:615,626; card_scene / heartwood gift | "Your route: %d bends", "Gauntlet path on your route", "route %d cells" | "route" banned (path) | "Your path: …" |
| dream_effects.gd:943 | "Now: %d Wardens can pin new primary targets for 0.4 s" | "pin" collides with the Pinned Reaction; "primary targets" | "Now: %d Wardens can Root a new target for 0.4 s" |
| dream_effects.gd:936 | "…Dew pot: x%s" | letter x | "×%s" |
| dream_state.gd:4633 | "Moonflip · +N%" | a word with no explanation anywhere in the corpus | add a glossary line or rename (check) |
| drift_panel.gd:494,510 | "Finale (drift %d): clear it clean for a Rare dream" | "clear it clean"; "dream" lowercase | "Drift %d: lose no leaf for a Rare Dream" |
| heartwood_gifts.gd:59,88 | "Each one pays {dew:60} × the {act}." | "× the act" = act number? | "Each one pays {dew:60} × the act number (act 2: 120)." |
| heartwood_gifts.gd:71 | "…lands with half again as many {stacks}." | idiom | "…lands with 50% more {stacks}." |
| gift_screen.gd:26 | "Click a new start on the rim" | "rim" | "Click a new start on the edge of the map" |
| gift_screen.gd:38 | "Wardens touching it can crit, whatever their family." | how much? | use the heartwood_gifts number: "+20% crit chance" |
| settings_panel.gd:204 | "Never always skips them." | unreadable without the option names | name the options: "Never: they are always skipped." (check which setting) |
| settings_panel.gd:182 | "Big hits shows only crits and Reactions." | grammar | "\"Big hits\" shows only crits and Reactions." |
| nightmare_icons.gd:60 Bulky | "Area hits deal less to it." | how much? | add the share from data (check) |
| omen_director.gd:245 | "Each leaf lost takes a quarter of its Dew and Seeds away (4 leaves: nothing)." | fine; only Omen text that explains well | keep |
| codex Cell / distance_diagram | "2×2 of the small squares you place on" | "small squares" first meets the player here | keep, but add the picture link everywhere "half cell" appears (narrow_way: "half a cell wide") |

Count: 10 top problems covering 30 strings, plus 85 table rows (some rows group several files): **about 115 flagged strings**.

---

## 3. Patterns (one rule each)

1. **Captions and tips drift from the description** (Crossroads, Briar Crown, Thicket, Codex Wellspring cap, Codex family pick). Rule: a number appears once, from data; captions and glossary lines use the same token or are checked by test_text_style.
2. **Effects hidden in the tip** (Hunter's Patience flyers, Deep Water bosses). Rule: the tip may limit or explain an effect, never add one.
3. **Game terms reused as plain words** (chain, jump, ring, seed, pin, catch, wake, stone, "marked"). Rule: a glossary word means only its glossary thing; pick another verb for everything else.
4. **Two names for one thing** (New cards / Dream again / reroll; Banish / Let go; dread shell / armour; run / dream; cells / tiles / squares / route). Rule: the wording_review §1 table wins; add "Dream again", "Let go", "armour", "tiles", "route" to the lint's banned list.
5. **Flavour where the rule should be** ("loves bends", "lightning loves it", "grieves", "the finisher", "drips while it counts"). Rule: in description, trait and tip fields, every clause must name a target, a trigger or a number; mood lives in flavour/whisper fields only.
6. **"half" / "every second" without a noun** ("half jumps", "at half", "every second ring"). Rule: always "half its damage", "every other ring", "each second".
7. **Vague amounts** ("every few drifts", "extra damage to Phantoms", "far harder", "Area hits deal less"). Rule: if the data has a number, show it with a {field:} token.
8. **Raw keywords** (perfect block, Reactions, Deeply Blighted, Dreamlight, drifts in Warden text). Rule: every glossary word through its token, so the lint catches it.
9. **Spelling rule conflict**: text_style.md says US ("US throughout"), wording_review_2026-10-13 §1 and text_pass say UK; the corpus mixes both (neighbour/neighbors, armour, colour). Rule: the council should confirm one, then fix text_style.md to match.
10. **Pronoun starts in reference text** (Reactions begin "It …"). Rule: Codex and glossary lines name their subject; they are read out of context.

---

## 4. What already works well

- Status tooltips (icon_info.gd) are short, noun-named and state the trigger number live ({stacks:…}); "Exposure: does nothing until N stacks" is exactly what a new player needs.
- Omen descriptions all start "For the next 5 {drifts}:" and then one clear effect: the most consistent set in the game.
- Nightmare trait lines follow "what it does: what to do about it" (Shade, Widow, Night Hound, Lurker), which teaches strategy in one line.
- Many tips define their own words first ("Bend: a turn with…", "Passed: stepped on a path cell sharing a side with it", "Network: Sprouts joined side by side"); keep that habit.
- The opening Lessons (Protect the Heartwood, Plant and start, Rests) are plain and in the right order.
- Omen reward rules (omen_director.gd) spell out the leaf penalty with an example ("4 leaves: nothing").
- Warden descriptions mostly read numbers from data ({field:…}), so they stay right after balance changes.
