# Wording Council: Plain English / Global Reader

Seat: a Steam player reading English as a second language, and a translator later. Judged on the corpus as it is now
(corpus_resources.txt, corpus_ui.txt, icon_info.gd). Tokens render as: {damp} Soak, {drowsy} Sleep, {spored} Poison,
{marked} Exposure, {static} Charge, {held} Root, {asleep} Asleep. Numbers are copied from the text; where two texts
disagree, I mark it for the owner instead of picking one.

---

## 1. Top 10 problems (ranked)

### 1. "Sleep" and "Asleep" are two different statuses with the same word (systemic)
- **Where:** icon_info.gd:20, 25 (status names); every card with {drowsy} and {asleep} (Dreamshroom, Dreamcatcher, Watcher, Nod Off, Night Terror, Sleepwalk, Falling Weight…); role lines "Drowses" (bellflower, bloomcap, dreamshroom, honeysuckle, lullaby_bell, silver_bell, vesper_bell .tres); Honeysuckle "can't put a nightmare to sleep"; Watcher hint "don't count on sleep to stop the others".
- **Now:** "nightmares at full Sleep fall Asleep"; "wakes nightmares near it that are Asleep or have Sleep"; role tag "Drowses".
- **Misreading:** a non-native reader treats Sleep and Asleep as the same thing (the noun and the adjective of one word), so "has Sleep" reads as "is sleeping = can't move". Sleep is a stacking slow; Asleep is a full stop. The role tag "Drowses" names a status that no longer exists on screen.
- **Rewrite:** rename the stacking status to a word that is not "sleep": **Drowsy** (the old name) or **Drowse**, and keep "Asleep" for the stop. Until then: role lines "Drowses" → "Adds Sleep"; Honeysuckle "A wall's scent alone can't make a nightmare {asleep}."; Watcher hint "While it lives, {asleep} and {drowsy} won't hold the others."

### 2. "set off" / "go off" for the core Reaction rule (systemic, about 60 strings)
- **Where:** icon_info.gd:19–24 (every status tip: "can set off {reactions}", "goes off as a strong bolt"); every Crowned cost line "{named_combo:X} can go off only half as often." (Alarm Bells, Deep Stillness, Endless Night, Tempest's Reach, Falling Stars, Fever Pitch, Mountain's Fall, Prism Heart, Ring of Rings, Stolen Away); Brimming, Called from Afar, Old Heart, Quick Reactions, Dawnbreak, Gone to Seed, Heavy Heart, Witching Bend, Chime Stone, Fairy Ring, Night Terror, Pinned, Snare Line, Spent Light; codex_data.gd:37, 130–133; lesson_card.gd:216, 224; status_links.gd:195, 201; warden_panel.gd:287 "Reactions: set off %d · fed %d"; codex_panel.gd:1165 "Set off by: ".
- **Now:** "{reactions} set off with twice the usual {stacks} hit 2.2 times as hard." / "can go off only half as often."
- **Misreading:** "set off" also means "start a journey" and "decorate"; "go off" also means "spoil" or "leave". Translators get a phrasal verb with no single meaning. In Brimming the reader cannot find the verb of the sentence.
- **Rewrite:** one verb everywhere: **trigger**. "At {stacks:need_damp} stacks it can trigger {reactions}." · "{named_combo:X} triggers only half as often." · Brimming: "Nightmares can hold twice as many {stacks} of every status. A {reaction} triggered with twice the usual {stacks} hits 2.2 times as hard." Tip: "{reactions} still trigger at their usual count."

### 3. "every second" means "every other" (ordinal) but reads as "each second" (time)
- **Where:** resource/tower/bellflower.tres; resource/dream/dream_bellflower.tres; resource/tower/thorncoil.tres; resource/dream/dream_thorncoil.tres.
- **Now:** "Every second ring on a nightmare gives it {drowsy}." · "every second pulse gives the nightmares around it {drowsy}." · "thorns bite nightmares with {held}: every second one has {held} in its range, it takes thorn damage."
- **Misreading:** The game uses "s" and "a second" for time everywhere, so "every second ring" reads as "a ring each second". Thorncoil's sentence has "second" as time but the same shape; the reader cannot tell which.
- **Rewrite:** "Every 2nd ring on a nightmare gives it {drowsy}." · "every 2nd pulse gives…" · Thorncoil: "It damages every nightmare in range. Each second a nightmare with {held} stays in its range, thorns deal extra damage to it."

### 4. "Root" is a status, a damage type, a family word and flavour (systemic)
- **Where:** icon_info.gd:24 ({held} = "Root") and :67 (damage type "Root"); tower descriptions "Its roots damage every nightmare in range" (deeproot, earthbind, groundroot, heartroot, long_way_home, rootcurl, rootling, snugroot, tangleroot, thorncoil .tres); World Root "roots erupt"; heartwood_sapling.tres "rooted for good"; drift_panel.gd:92 "rooted for good"; tower_seller.gd:192 "Rooted: it can't be sold"; rest_report.gd:79 "Heartwood Roots: gave Roots to %d nightmares"; heartwood_gifts.gd:75 "Roots cover the last 6 cells".
- **Now:** "Its roots damage every nightmare in range."
- **Misreading:** "roots" next to a status called Root reads as "it puts Root on every nightmare in range" (stops them all). "Rooted: it can't be sold" reads as the status.
- **Rewrite:** flavour roots out of rules text: "It damages every nightmare in range." · Sapling: "2×2. It can never be sold or moved." · seller: "Permanent: it can't be sold" · rest report: "Heartwood Roots: gave {held} to %d nightmares".

### 5. Restless Dreams (Waking Dreams) cost: broken grammar
- **Where:** resource/dream/restless_dreams.tres cost_description.
- **Now:** "For the rest of the run, every Dream shows only 2 cards and can't be let pass."
- **Misreading:** "be let pass" is not standard English; a reader cannot parse it, and "the rest of the run" collides with the game term rest (item in table).
- **Rewrite:** "Until the run ends, every Dream shows only 2 cards, and you can't use Let it pass."

### 6. Breathe It In: "it" could be the Sporeling or the nightmare
- **Where:** resource/dream/breathe_it_in.tres description.
- **Now:** "Statuses added to nightmares in a Sporeling's range get 1 more {stack}, 3 if it is {asleep} or {held}."
- **Misreading:** the nearest noun is "a Sporeling's range" / "Sporeling"; also "is {held}" turns a status noun into an adjective ("is Root").
- **Rewrite:** "Statuses added to nightmares in a Sporeling's range get 1 more {stack}, or 3 more if the nightmare is {asleep} or has {held}."

### 7. Briar Crown: unclear who is touching whom, and the caption disagrees
- **Where:** resource/dream/briar_crown.tres description + diagram_caption.
- **Now:** "When a nightmare passes a Thornwall, Bramble or Honeysuckle, it takes 60% of a hit from the strongest attacking Warden {touching} it." Caption: "…takes 25% of the strongest Warden touching it."
- **Misreading:** "{touching} it" can be the nightmare or the wall; "takes 60% of a hit" can read as "blocks 60%". The caption number (25%) and the description (60%) differ: for the owner (Balancing), not a wording fix.
- **Rewrite:** "When a nightmare passes a Thornwall, Bramble or Honeysuckle, the strongest attacking Warden {touching} that wall hits it for 60% of a normal hit." (Fix the caption's number to match.)

### 8. Mother Log: "its rank" has two owners
- **Where:** resource/tower/mother_log.tres; resource/dream/dream_mother_log.tres.
- **Now:** "Sell a Warden beside it and the next Warden planted on that cell this {rest} keeps its {rank}." / "a Warden sold there leaves its {rank} in the log for the next one planted on that cell this {rest}."
- **Misreading:** "keeps its rank" reads as "the new Warden keeps its own rank" (nothing happens). "leaves" (verb) sits next to leaves (lives).
- **Rewrite:** "If you sell a Warden beside it, the next Warden you plant on that cell during this {rest} gets the sold Warden's {rank}."

### 9. Omens "at the start": place or time?
- **Where:** resource/omen/second_path.tres; resource/omen/shifting_ground.tres.
- **Now:** "the Thornwall that makes the path longest crumbles at the start (full refund)." · "5 Withered Trees sprout on empty ground at the start."
- **Misreading:** "the start" is also the map's start cell (H key "Centre on the start", Forest's Edge "within 3 cells of the start"). A reader expects the trees to appear at the start cell.
- **Rewrite (check the rule):** "When these {drifts} begin, the Thornwall that makes the path longest crumbles (full refund)…" · "When these {drifts} begin, 5 Withered Trees sprout on empty ground."

### 10. Falling Stars: "marked" is not Exposure, "pierce" is undefined
- **Where:** resource/dream/falling_stars.tres.
- **Now:** "Each nightmare a {named_combo:starfall} star hits is marked: its next hit is a crit for ×2. These crits never pierce."
- **Misreading:** "marked" reads as the Exposure status (whose code id and old name is Marked); "pierce" is never defined on this card (it comes from Pinned).
- **Rewrite:** "The next hit on each nightmare a {named_combo:starfall} star hits is a crit for ×2. These crits don't hit the nightmares behind it."

---

## 2. Other flagged strings

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| dream/afterglow.tres | "gives nightmares within 2 cells 2 {stacks} of each status in that {reaction}." | Two numbers back to back ("2 cells 2 Stacks"); double object | "…: nightmares within 2 cells gain 2 {stacks} of each status in that {reaction}." |
| dream/alarm_bells.tres | "startle every Warden {touching} them too: one more step of 40% faster attacks." Tip "One step only: those Wardens startle no more." | "step" is the path-cell term; "startle no more" archaic | "…startle every Warden {touching} them too: those attack 40% faster as well." Tip: "It spreads once: Wardens startled this way don't startle others." |
| dream/brimming.tres tip | "{reactions} still fire at their usual count." | "fire" = shoot / dismiss | "{reactions} still trigger at their usual number of {stacks}." |
| dream/called_from_afar.tres; dream/old_heart.tres | "lets the nightmare's next {reaction} go off at once" | phrasal verb; "at once" does not say what is skipped (the wait? the stacks?) | "…makes the nightmare's next {reaction} trigger right away, without its usual wait." (owner: confirm what is skipped) |
| dream/crown_of_leaves.tres | "{reactions} a {final_form} takes part in deal 30% more damage" | preposition at the end of a relative clause; hard to parse | "{reactions} deal 30% more damage when a {final_form} helped cause them (60% for an {ascended} form)." |
| dream/clean_night.tres tip | "Echoes don't count." | Echo = Echo Hollow's repeat, or a boss echo? | "Echo Hollow echoes don't count." |
| dream/deep_stillness.tres; deep_water.tres; reaction/drown.tres | "pulled under", "60% slower while under" | idiom; "under" alone has no noun | "held under the water"; "60% slower while held under" |
| dream/deep_water.tres cost/tip | "Only within 5 cells of the Heartwood." · "Bosses are slowed 40% instead of 30%." | fragment: what works only there? tip has no subject | "{named_combo:drown} works only within 5 cells of the Heartwood." · "{named_combo:drown} slows bosses 40% instead of 30%." |
| dream/dream_autumn_gale.tres | "seeds down the busiest lines; each caught seed that hit something…" | "caught" collides with Caught; tense mix | "…seeds along the 3 busiest lines; each seed that hits something and comes back makes…" (tower text already says this) |
| dream/dream_cairn.tres; tower/cairn.tres; rockslide role | "lobs its top stone", "Lobs over walls" | rare verb | "throws its top stone over the maze"; role "Throws over walls" |
| dream/dream_dewcatcher.tres | "poured out at the {rest}" | poetic verb for a payment | "paid at the {rest}" (as the tower text says) |
| dream/dream_echo_hollow.tres; tower/echo_hollow.tres | "repeats a second later" / "happens again a second later" | "second" reads as ordinal | "…1 s later" |
| dream/dream_edgestone.tres | "the leftover damage spills onto the next." | phrasal; "the next" what? | "the damage left over hits the nearest nightmare." |
| dream/dream_hatchery.tres | "every {field:…:count}th sprite" | ordinal suffix glued in data; "5th" ok, "1th/2th/3th" breaks | "every {count} sprites, one is big…" or a number-aware ordinal |
| dream/dream_hushbell.tres; tower/hushbell.tres | "no waking, no healing" | "no waking" reads as "nightmares can't wake (stay asleep)"; it means they can't wake others | "they can't wake other nightmares or heal" |
| dream/dream_lichenling.tres | "crusted spores that strip {dread_shells} and stop mending." | who stops mending? | "spores that wear away {dread_shells}; nightmares with its {spored} can't heal." |
| dream/dream_magpie_perch.tres | "each hit steals a boost from its target" | "boost" undefined for nightmares (Codex "Boosts" = Warden boosts) | "each hit removes one of its target's bonuses" (glossary link) |
| dream/dream_midsummer.tres | "carries on to the nightmare right behind it" | phrasal "carries on" (= continues) | "also hits the nightmare right behind it" |
| dream/dream_nimbus.tres; tower/nimbus.tres | "rain clouds that drift to the busiest spot" | "drift" is the wave term | "…move to the busiest spot" |
| dream/dream_rampart.tres | "heavy blows that get stronger with each Thornwall {touching} it, and turn them to stone." | "them" = blows or Thornwalls | "…and those Thornwalls turn to stone." |
| dream/dream_rootling.tres | "Its roots nip at everything in range." | phrasal + Root collision | "It damages everything in range." |
| dream/dream_samara.tres | "carrying the first nightmare's statuses along it" | "it" = line? seed? | "…and carries the first nightmare's statuses along the line." |
| dream/dream_silence.tres; tower/silence.tres | "a wider hush" | poetic noun for a mechanic | "a wider area" |
| dream/dream_tempest.tres; tower/tempest.tres | "statuses it touches travel with it and settle on the rest." | "the rest" = remainder vs rest phase; "settle" vague | "…it picks up statuses and puts them on the other nightmares it hits." |
| dream/dream_whetstone.tres | "the finisher, its hits on worn-down nightmares land far harder." | "worn-down" vague | "its hits on nightmares below 30% health deal far more damage." (number from tower text) |
| dream/dream_whirligig.tres | "Its gusts carry trouble along:" | idiom-like flavour inside rules | cut, start at "Every … it copies…" |
| dream/dream_windmill.tres | "loves bends." | personification instead of a rule | "stronger the more path cells are around it." |
| dream/dream_jetreed.tres | "wears down a share of its target's max health" | phrasal; "share" vague | "each hit also removes a part of its target's max health ({erosion})" |
| dream/eye_of_the_tempest.tres | "Nightmares burning from a {named_combo:tempest}… so its {arcs} never run dry." | "burning" undefined; idiom "run dry" | "Nightmares hit by a {named_combo:tempest} give 1 {stack} of {damp} to the nightmares beside them each second, so its {arcs} always find {damp}." |
| dream/fever_pitch.tres | "Nightmares that catch the fever from…" | idiom; "catch" vs Caught | "Nightmares that {named_combo:fever_dream} spreads to also fall {asleep} for 1 s." |
| dream/few_and_mighty.tres | "for each one short of 12" | idiom | "for each attacking Warden fewer than 12" |
| dream/flashover.tres | "half {jumps} to the nearest one it missed." | "half" of what | "half of its damage {jumps} to the nearest nightmare it missed." |
| dream/fresh_growth.tres tip | "Only a Warden that stood at the last {rest} sets it off." | "stood" = existed; phrasal | "Only a Warden that was already planted at the last {rest} counts." |
| dream/gathering_storm.tres tip | "A bet: pays when several {jump} cards hit one pack." | "pays" idiom; "pack" | "Needs several {jump} cards hitting the same group." |
| dream/grandfather_stump.tres | "4% stronger for each Warden {touching} it, up to 45% faster in all." | "in all" idiom; "stronger" then "faster" | "{warden:elder_stump}'s aura gives 4% more attack speed for each Warden {touching} it, up to 45% faster in total." |
| dream/heavy_going.tres tip | "A slowed nightmare drips while it counts." | flavour in a rules tip; reads like a status | "A dripping effect shows while it counts." |
| dream/headlong.tres tip | "a leak costs {leaves} only." | "leak" is jargon (never defined) | "a nightmare reaching the Heartwood costs only {leaves}." |
| dream/homesick.tres | "its statuses are topped up to full time." | phrasal "topped up" | "its statuses start their time again." |
| dream/hollow_ground.tres caption | "Planted in a moved hollow" | "moved hollow" means nothing | "Planted where you cleared an obstacle: +1 range." |
| dream/hunters_moon.tres | "Dispelling it gives the 2 nearest 1 {stack}." | "it" + numbers back to back; "dispel" also means "remove a status" to gamers | "When that nightmare is dispelled, the 2 nearest nightmares gain 1 {stack} each." |
| dream/in_time.tres | "Every 5th hit a Warden {touching} a bell makes on the same nightmare lands again 0.25 s later." | relative clause split by its object; hard to parse | "When a Warden {touching} a bell hits the same nightmare 5 times, the 5th hit lands again 0.25 s later." |
| dream/last_drop.tres | "the nightmare takes 40% of their hit per {stack}" | "their" = Dewdrops? Wardens? | "the nightmare takes 40% of that Warden's hit for each {stack}, up to 3 hits." |
| dream/lightning_fence.tres (tower) | "…gliding through it, which a {warden:jarlink}'s link can't touch." | "which" = Phantoms or lightning? | "It also hits {nightmare:dandelion_seed}s gliding through it. A {warden:jarlink}'s link can't." |
| dream/nothing_wasted.tres | "Damage a {dread_shell} stops from Fireflies and Wardens {near} them {jumps} to…" | object-first clause, hard to parse | "When a {dread_shell} stops damage from a Firefly or a Warden {near} one, that damage {jumps} to the nearest nightmare without a {dread_shell}." |
| dream/old_rain.tres | "if it spends a status a card made last longer." | stacked clause | "…if one of its statuses was made to last longer by a card." |
| dream/quick_step.tres | "Calling a {drift} early makes Wardens attack 50% faster…" | "Calling" at a sentence start looks like the Calling term | "When you call a {drift} early, Wardens attack 50% faster until it has fully arrived." |
| dream/scarred_bark.tres | "makes later {drift} {dew} pots 2% bigger" | three nouns stacked | "makes the {dew} pot of every later {drift} 2% bigger" |
| dream/seeping_in.tres tip | "Steps it is pulled or pushed back over don't count again." | hard to parse | "If it is pulled or pushed back, the {steps} it walks again don't count." |
| dream/shared_fever.tres | "the most-stacked one's top 2 statuses" | stacked compound | "each gains 1 {stack} of the 2 biggest statuses on the nightmare with the most {stacks}." |
| dream/spillover.tres | "the leftover damage hits nightmares within 1 cell." | "leftover" = overkill, unclear | "the damage beyond its health hits nightmares within 1 cell." |
| dream/sprout_chorus.tres (Thicket) | desc "attack 20% faster"; caption "touches another Sprout … +30%" | caption adds a condition and a different number | Owner: make caption = description. |
| dream/crossroads.tres | desc "100% more damage"; caption "+40%" | numbers disagree | Owner: fix caption. |
| dream/twig_walls.tres | "Thornwalls you plant take a quarter of a cell" | "take" = occupy (vs takes damage / takes leaves) | "Thornwalls you plant fill a quarter of a cell and cost half as much." |
| dream/wild_growth.tres tip | "Nurture ranks still pay their difference… A bet: where nightmares die." | "pay their difference" unclear; fragment | "Growing a ranked Warden still costs the rank difference… Needs a spot where many nightmares are dispelled." |
| dream/waymark.tres tip | "Sprouts and Thornwalls build the second leg. A bet: a kill zone on each leg." | "leg" jargon | "Sprouts and Thornwalls can shape the route after the Waymark." |
| dream/heavy_seed.tres | "Seeds from {warden:samara}…" | capital "Seeds" at sentence start = the currency | "{warden:samara}'s seeds deal double damage on their way back." |
| dream/hardened_bark (thick_bark.tres) | "takes no {leaves}" | take = steal / receive | "costs no {leaves}" |
| all .tres tips ending "Safe." / "A bet: …" | "Safe." | "Safe" reads as "protects you"; "a bet" is an idiom | "Works on its own." / "Risky: needs …" |
| enemy/ash_crawler.tres | "Its ash burns {spored} off the nightmares behind it" | phrasal "burn off" | "Its ash removes {spored} from the nightmares behind it" |
| enemy/bark_beetle.tres (Husk) | "heavy hits first, then a long path." · hint "a few more turns in your maze buy a lot of time" | cryptic; idiom "buy time" | "use heavy hits and a long path." · "It is slow, so a few more bends give your Wardens much more time." |
| enemy/drowned_one.tres hint | "Lightning loves {damp}, and it never dries." | "it" = lightning or nightmare; "loves" | "Lightning hits {damp} harder, and this nightmare's {damp} never wears off." |
| enemy/gravecrawler.tres | "build two deep where it matters." · hint "One thin wall is its favourite shortcut." | idiom "two deep" | "put two Wardens or walls in a row where it matters." · "It burrows most often under a single wall." |
| enemy/hedgehog.tres (Night Hound) | "add corners to break its stride." · hint "Even a short straight sets it off" | idioms; "straight" as noun; "corners" vs bend | "add bends to stop its sprint." · "Even a short straight stretch starts its sprint: keep the path turning." |
| enemy/lamplighter.tres | "snuff the lanterns" | rare verb; how? | "and destroy the lanterns" (owner: say how) |
| enemy/leaf_bug.tres hint | "The trick is catching them all." | idiom | "The hard part is hitting all of them." |
| enemy/mother_duck.tres hint | "where the path doubles back" | idiom | "where the path turns back on itself" |
| enemy/mother_spider.tres hint | "near where it falls" | "falls" = dies | "near where it is dispelled" |
| enemy/puffcaplet.tres hint | "sweep them up" | phrasal | "hit them all at once" |
| enemy/watcher.tres hint | "don't count on sleep to stop the others" | idiom + negative + Sleep/Asleep | "While it lives, {asleep} won't stop the others." |
| enemy/will_o_wisp.tres hint | "its glow gives the {nightmare:dusk_moth}s away." | "gives away" = reveals, but "gives" means add a status everywhere else | "its glow reveals the {nightmare:dusk_moth}s." |
| enemy/hollow_oak.tres | "grieves as it weakens" | reads as a rule (what does grieving do?) | Keep in title/whisper; trait: "Plants Thorn-Saplings that change the path: leave room to change your maze." |
| omen/lean_season.tres flavour | "with a strange gift at its end." | "Gift" is a game term (Heartwood gifts) | "with a strange reward at its end." |
| omen/restless_wind.tres flavour | "They come in waves" | "waves" is the old word for drifts | "They come close behind each other." |
| reaction/smother.tres | "its {spored} stops hurting and swells." | "swells" poetic | "its {spored} stops dealing damage and builds up." |
| reaction/pinned.tres | "Uses up the {marked}, and the {drowsy} when that set it off." | "that … it" unclear | "Uses up the {marked}; also uses up the {drowsy} if {drowsy} triggered it." |
| reaction/night_terror.tres; sleepwalk.tres | "Waits while it is {asleep} or near a {warden:dreamcatcher}." | "Waits" = delayed? cancelled? | "Does not trigger while the nightmare is {asleep} or near a {warden:dreamcatcher}." |
| reaction/sleepwalk.tres | "every nightmare it bumps into turns round too" | phrasal + UK "round" | "every nightmare it touches also turns back" |
| tower/heartwood_sapling.tres | "rooted for good… Each {leaf} lost withers the yield 5%" | idiom; poetic verb | "It can never be sold or moved… Each {leaf} lost lowers its yield by 5% until the next {rest}." |
| tower/jetreed.tres | "Each hit also takes … of its target's max health… so it suits big nightmares." | "takes" | "Each hit also removes … of its target's max health, so it is good against big nightmares." |
| tower/pond_keeper.tres | "drags the nightmare furthest along back beside the pond" | "along back" stacked | "pulls the nightmare closest to the Heartwood back to the pond" |
| tower/quaker.tres | "Slams sprints to a stop… shakes {hidden} nightmares loose" | idioms | "Stops sprints… makes {hidden} nightmares visible for 3 s" |
| tower/frostfern.tres | "Pair it with Wardens that Soak." | status noun used as a verb | "Use it with Wardens that add {damp}." |
| tower role lines (all .tres) | "Drowses", "Soaks", "Exposes", "Poisons", "Roots", "Charges", "Silences" | status nouns used as verbs; "Drowses" ≠ "Sleep"; "Roots" = flavour too | "Adds Sleep", "Adds Soak"… (or the status icon + name) |
| icon_info.gd:159–169 role/counter words | "thins swarms", "quiets support", "answers bosses", "holds the line" | idioms | "hits swarms", "stops support nightmares", "good against bosses", "controls nightmares" |
| icon_info.gd:25 (Asleep tip) | "Stopped for 3 s, long but fragile" | "fragile" for a status | "Can't move for 3 s. A big hit (10%+ of its health) wakes it." |
| codex_data.gd:14 Dreamlight | "Freed by great nightmares (bosses, the first family pick)" | "freed" poetic; the family pick is not a nightmare | "Earned from bosses and the first family pick." |
| codex_data.gd:34 Mist; mist_count.gd:10; drift_panel.gd:401 | "it holds the rest back until there's room" | "the rest" = remainder vs rest phase | "it keeps the other nightmares back until there is room" |
| codex_data.gd:102 Dread shell | "chip damage barely gets through" | gamer jargon | "small hits barely get through" |
| codex_data.gd:76 Jump | "A jump sets off another jump only when a card says so." | set off | "A jump triggers another jump only when a card says so." |
| lesson_card.gd:216 | "Two full statuses on one nightmare set off a {reaction}." | wrong rule: Reactions need the Reaction mark, not full (Stack glossary, status tips) | "Two statuses with enough {stacks} on one nightmare trigger a {reaction}." |
| dream_keywords.gd:56 | "{damp}: the nightmare conducts water and lightning." | "conducts water" is nonsense | "{damp}: water and lightning hits deal more to the nightmare." |
| signatures.gd:35 FIRSTBORN | "starts one step stronger." | "step" = path cell term | "starts one stage stronger." |
| heartwood_gifts.gd:79 | "their bond grows one step now" | step | "their bond grows one stage now." |
| whispers.gd:19 | "It took its toll, and went back into the dark." | idiom, and "Toll" is a game term | "It hurt the Heartwood, and went back into the dark." |
| settings_panel.gd:182, 204 | "Big hits shows only crits and Reactions." · "Never always skips them." | grammar; "Never always" parses as nonsense | "Big hits: only crits and Reactions." · "Never: always skips them." |
| boss_dossier.gd:771 | "it drains, then runs the maze again" | "drains" no object | "it takes leaves, then walks the maze again" |
| omen_director.gd:245 | "Each leaf lost takes a quarter of its Dew and Seeds away" | split phrasal "takes … away" | "Each leaf lost removes a quarter of its Dew and Seeds" |
| several .tres + UI | "for the rest of the run" (burn_back, deep_sleep, restless_dreams, gift "for the rest of the run") | "rest" is a game term | "until the run ends" |
| several UI/.tres | British spellings: neighbour (graftling, grafted_elder, warden_header_view.gd:232), armour (lichenling, old_lichen, icon_info.gd:159), colour, coloured, favourite, Centre (settings_panel.gd:30), "turns round" — and US "neighbors" in codex_data.gd:182, 280, 297 | text_style.md says US throughout; mixed spellings look like two words to a learner and to translation memory | Pick US: neighbor, armor, color, favorite, Center, turns around |

Rows in this table: 98 (plus the 10 above).

---

## 3. Words to avoid in rules text

| Avoid | Why | Use instead |
|---|---|---|
| set off, go off, fire (for Reactions, bolts, traps) | phrasal verbs with several meanings | trigger(s) |
| every second (meaning every 2nd) | collides with time | every 2nd |
| a second later | ordinal or time | 1 s later |
| the rest (remainder), for the rest of the run | rest is a game term | the others; until the run ends |
| take(s) (leaves, cells, max health) | already means "receive damage" and "choose a card" | costs (leaves), fills (cells), removes (health) |
| leave(s) (verb) in rules | leaves = the Heartwood's lives | makes, puts, keeps, stays |
| drift (verb) | the wave term | move |
| block (verb: absorb, stop) | the 5-drift term; "perfect block" | absorb, stop (keep "block" for the game term only) |
| step (stage, level) | the path-cell term | stage |
| grow (meaning increase) | grow = change form | get stronger, increase |
| catch, caught (seeds, fever, hits) | Caught is a status | hit, get, spread to |
| marked (lowercase) | old name of Exposure | Exposure ({marked}) or rephrase |
| roots, rooted (flavour) | Root is a status | cut, or "permanent" |
| Calling / call (at a sentence start) | the Calling term | "When you call a drift early" |
| Seeds (projectiles) | the currency | seeds, lowercase mid-sentence, after the Warden's name |
| echo (bosses) | Echo Hollow's echoes | boss echoes |
| ring / peal / toll / pulse for one bell hit | four words for one action; Toll is a term | pulse (area) or hit |
| corner, turn (path) | bend is the defined term | bend |
| straight (noun) | adjective for learners | straight stretch |
| near, beside, around, close by (unlinked) | {near} = 2 cells, {touching} = 1 cell | the linked token |
| spill onto, spill over, carry on, top up, wear down, burn off, shake off, sweep up, give away, nip at, double back | phrasal verbs | hits, continues, resets, removes, reveals, turns back |
| pays, pays out (for cards, damage) | money idiom | gives, deals, is worth it |
| leak | undefined jargon | a nightmare reaching the Heartwood |
| pierce | undefined on most cards | hits the nightmares behind |
| loves, grieves, fragile, hush, swells, lobs, snuff | personification / rare words | the effect in numbers |
| in all, one short of, two deep, buy time, the trick is, break its stride, for good | idioms | in total, fewer than, two in a row, more time, the hard part, stop its sprint, permanently |
| Safe. / A bet: | idioms as tags | Works on its own. / Risky: needs … |
| Soaks, Roots, Drowses, Exposes (role verbs) | status nouns used as verbs | Adds Soak, Adds Root… |

---

## 4. Localisation risks (code-assembled sentences)

**String surgery on displayed text (breaks as soon as the text is translated):**
- drift_panel.gd:347 `"Call early, " + text.get_slice(" early, ", 1)`: splits a translated button on an English word.
- drift_panel.gd:348–349: shortens buttons by replacing English prefixes ("Rest after drift " → "Rest after ").
- dream_state.gd:6146 `"On your map · " + live.trim_prefix("Now: ")`: strips an English prefix from another string.
- icon_info.gd:186–193 `role_terms`: splits role lines on ", " and upper-cases the first letter; translated commas or no case = wrong bullets.
- icon_info.gd:175 `"Support, " + "Heavy, " + role_line`: list built by gluing.
- icon_info.gd:354–367 `_upper_first`, `name_in_sentence`, `the_name`: the English article "the" added or removed in code; other languages inflect it by gender/case.
- tower_placer.gd:2278 `why[0].to_upper() + why.substr(1)`: capitalises a sentence in code.

**English-only plurals and lists:**
- `"" if n == 1 else "s"`: boss_dossier.gd:677, 891; codex_panel.gd:1943, 2091, 2094; status_links.gd:201.
- Singular/plural chosen in code: dream_state.gd:4431 ("family"/"families"), 6141 ("Warden"/"Wardens"); warden_panel.gd:582 `_plural(data, n)`.
- Lists joined with English words: dream_state.gd:4133, 4179, 4429 (" + "), 5287 (" and "), 5293 (" or "); omen_director.gd:269, 278, 280–281 (`_and(...)`).
- icon_info.gd TERMS: one singular + one plural per term; Slavic and Arabic need 3–6 forms, and nouns inserted by tokens ({drift}, {dew}, {leaves}) cannot take case endings. Tokens need per-language forms, or the sentence must be written around them.

**Sentences built from fragments (translator sees half a sentence):**
- boss_dossier.gd:669 "Health %s%s (with …)" + `_compare_text`; :676–677 "Drift %d%s. %s" with " · the last drift of the act" and "Arrives in %d drift%s".
- coming_strip.gd:522 "Coming this block%s. Click to see them." with ", something new".
- omen_director.gd:329 "Next Dream offers %d cards%s%s" with ", one of them Rare or better" + `keep`; :331, :333 + `keep`; :794 "You'd get nothing right now: %s." with a reason fragment.
- tower.gd:1392, 1395, 1399, 1438, 1459 "…a second%s" with `_at_potency_one(...)` fragments.
- dream_state.gd:3101, 3107 `"Dream again · " + _left_this_run(...)`; :4429 "Needs %s: a family that brings it may come %s" (`when` is a fragment).
- dream_screen.gd:274 "Let it pass, %s"; :461 "Grows with %s: %s".
- codex_data.gd:532 "Four %s ranks: %s%s%s"; :608–609 NIGHTMARE_TERMS "Worn by %s." with a joined name list.
- codex_panel.gd:1165 "Set off by: " + combo.by.
- dream_bonus_view.gd:145 "Off: " + reason.
- dreams_row.gd:200 "Calling: %s (%s): %s"; :242 "Calling, %s family".
- drift_banner.gd:243 "At %s health · %s: %s".
- hud.gd:1949 "Sprout · %s. Every %d Sprouts … (next rise at %d Sprouts).%s Growing or selling one lowers it." (a sentence inserted mid-paragraph).
- icon_info.gd:82 "%s damage" (word order fixed); :208 "Counters " + ", ".join(words).
- nightmare_icons.gd:113 "Immune to %s %s: …" (`condition` fragment).
- rest_report.gd:573 "Did little: %s%s" with " (%s)"; :65 "Omen · %s · %s" with a summary built elsewhere.
- tower_placer.gd:463 `tag += " · %+d cells of path"`.
- warden_header_view.gd:337 "Unlock %s · %s" with a nested ternary.
- warden_panel.gd:455 "Rank %s: %s.\n%s. Kept when it grows…"; :1565–1566 "the %s family" (family name inserted where languages need a case form).
- results_screen.gd:135–136: report text glued from several builders.
- Data: dream_hatchery.tres "every {…:count}th sprite" (English ordinal suffix glued to a number); "5th / 3rd / 4th" across many .tres need number-aware ordinals.
- Roman rank numerals via `Tower.rank_name` inside sentences ("Nurture to rank %s"): fine to keep, but the sentence around them must be one string.
