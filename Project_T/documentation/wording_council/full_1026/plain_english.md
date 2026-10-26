# Wording Council full round 2026-10-26: plain_english seat

Seat: second-language readers and future translators. Read: corpus_resources.txt (656 files, every live .tres text
field), corpus_ui.txt and corpus_short.txt (script strings), with the tokens resolved through
`scripts/ui/icon_info.gd` (STATUSES, TERMS). Rules: wording_council_review.md (all rounds through "Grow vs Nurture" and
the Flashover note) and the words-to-avoid lists in documentation/wording_council/plain_english.md §3, round2, gap,
round3, roguelite and r1025. Read-only; nothing was run.

"Rules text" here = description, cost, tip, caption, role line, trait, hint, grows_text and every script string a
player reads. Flavour lines, cleanse lines, whispers and the story Memories are left out. Places use the .tres file
name (`.d` description, `.t` tip, `.cost`, `.cap` caption, `.role` role line, `.trait`, `.hint`) or `script.gd:line`.

---

## 1. Top 10 problems (ranked)

### 1. Token nouns used as verbs: `{jumps}` 21 times, plus `{dispels}`, `{tolls}`, `{dew_splashes}`, `{crit}`
`{jump}` is a glossary noun (TERMS: "jump" / "jumps"), but 21 rules lines use `{jumps}` as a verb: brushfire.d,
chain_of_lanterns.d, conductive_soil.d, dream_stormcap.d, dream_stormheart.d, flashover.d, guiding_light.d,
guiding_light_ii.d, hammerfall.d, nothing_wasted.d, sparks_fly.d, tangled_lightning.d (`{jump}`), thunderstruck.d,
dream_keywords.gd:43, calling_paths.gd:207, :214, :230, :233, :239 ("every {jump} {jumps}"), callings.gd:18. The same
habit: trophies.d and spillover.d ("a Warden {dispels} 10 nightmares"), calling_paths.gd:257 ("When that one {tolls}"),
callings.gd:19 ("A Dewdrop's hit there {dew_splashes}"), pebbling_ascension.d ("always {crit}").
**Problem:** the token can only hold a noun's singular and plural. In English the plural happens to look like the verb;
in every other language the link word will be a plural noun in a verb slot. Round 3 fixed this for `{toll}`, not for
`{jump}`.
**Rewrite pattern:** the token stays a noun, a plain verb carries the action. Flashover: "When a Warden {near} a
{family:firefly_jar} Warden hits 2 or more nightmares with one attack, half of the damage goes as a {jump} to the
nearest nightmare it missed." Trophies: "Each {drift}, a Warden that makes 10 {dispels} gets direct hits that deal 4%
more damage until the run ends, up to +40%." Callings.gd:19: "A Dewdrop's hit there makes a {dew_splash}: …".
Pebbling ascension: "its hits … are always a {crit}".

### 2. "set off / go off / fire" are back (8 places; rule 10 says "trigger")
- dawnbreak.t "Each nightmare sets one off at most once every 3 s." → "Each nightmare can trigger one at most once every 3 s."
- pinned.d "…and the {drowsy} when that set it off." → "…and the {drowsy} when that triggered it."
- codex_data.gd:39 Chain "Reactions setting each other off within a second." → "Reactions that trigger each other within a second."
- lesson_card.gd:224 (Charge lesson) "Other statuses can set it off early as a {reaction}." → "A {reaction} with another status can trigger it early."
- status_links.gd:215 "Not discovered yet: set it off in a run to learn it." → "Not discovered yet: trigger it in a run to learn it."
- brimming.t "{reactions} still fire at their usual count." → "{reactions} still trigger at their usual number of {stacks}."
- night_terror.d "its {static} fires at once as a bolt" → "its {static} triggers its bolt at once".
- hedgehog.hint "Even a short straight sets it off" → "Even a short straight stretch starts its sprint".

### 3. Bare "rank" in 36 places (the 2026-10-25 rule: "Nurture {rank}" every time)
Data: grove_keeper.d "{rank} II", heartwood_sapling.d "from rank III", mother_log.d "keeps its {rank}",
first_care.d "{nurture} {ranks}" (two tokens, reads "Nurture ranks" but links twice), tending_hands.d "to {rank} VII".
Scripts: codex_data.gd:49, :58 ×2 (Mastery "The rank V reward for four matching ranks"), :59, :304 ("arrives at rank
I"), :548; family_pick_screen.gd:447 ("+%d per rank"); gift_screen.gd:56 ×2 ("rank II", "2 free ranks"), :70 ×2;
heartwood_gifts.gd:61, :81; lesson_card.gd:431, :432, :667 ×2; lesson_demo.gd:50; settings_panel.gd:182 ("when you
can afford a rank"); signatures.gd:38, :39; warden_panel.gd:269, :443, :458, :469, :473, :494, :662;
dream_batch_rules.gd:267 ×2; dream_state.gd:4339 ("a free rank waits on %s").
**Rewrite:** "Nurture rank" (with `{rank}` in data): e.g. gift_screen.gd:56 "Plant on a stump: the Warden gets 2 free
Nurture ranks."; codex_data.gd:58 "The Nurture rank V reward when four Nurture ranks took the same choice on a Warden
with no signature: …".

### 4. "Hollow" now names a stack state and half the story
Hollow stacks (codex_data.gd:143, nightmare_info.gd:463, since 2026-10-25) share the word with the Hollow (the villain
in every Memory and boss line), The Hollow Oak, Echo Hollow, Whispering Hollow, Hollow Ground (and "a moved hollow" in
its caption), Hollow Wind, Hollow Stag. A learner who reads "Hollow: a Dream card added these stacks" will connect it
to the boss. **Owner call:** rename the state; suggested **"Unsettled"** ("Unsettled: a Dream card added these stacks.
No Reaction can trigger on this nightmare until they settle ({const:fed_lock} s).") The art (hollow pip) can stay.

### 5. Unclear "it" where a Warden, a wall and a nightmare share one sentence (rule 13)
- briar_crown.d "When a nightmare passes a Thornwall, Bramble or Honeysuckle, **it** takes 60% of a hit from the
  strongest attacking Warden {touching} **it**." (first it = nightmare, second = wall) → "…, the nightmare takes 60% of
  a hit from the strongest attacking Warden {touching} that wall."
- shared_light.d "When a Warden's hit dispels a nightmare, each Warden {touching} **it** deals 25% more" (the Warden
  or the nightmare? caption says the Warden) → "each Warden {touching} that Warden deals …".
- the_tallest_tree.d / warden_panel.gd:1464 "each one gives the Tree an extra attack whenever **it** attacks" →
  "whenever the Tree attacks, each of them gives it one extra attack". (check which one attacks)
- thorncoil.d "while one with {held} is in **its** range, **it** takes thorn damage each second" → "each nightmare
  with {held} in its range takes thorn damage each second".
- chime_stone.d, lullaby_bell.d, great_bell.d "is struck by **its** bolt" (the bell's? the nightmare's Charge?) →
  "releases its own {static} bolt at once" (check: code releases the nightmare's Charge).
- whirligig.d / dream_whirligig.d "onto one beside **it**" (beside the Whirligig or the source nightmare?) → "onto
  the nightmare nearest to that one" (check).
- dream_frostfern.d "When a nightmare's {frost} is full **it** bursts, hurting **it** and those beside **it**." →
  copy the Warden text (frostfern.d): "At {full} {frost} a nightmare bursts, hurting it and up to 4 others within 1 cell."
More in §2.

### 6. Evolution cards still carry the pre-37 splash and Frost wording (F3 not done)
"the one hit" / "the nightmare hit" (r1025 rule: "the nightmare it hits"): dream_dewdrop.d, dream_old_mountain.d,
dream_puffball.d, dream_hoarfrost.d, dream_rain_lily.d, calling_paths.gd:399. The Warden texts were fixed; the "X can
now grow into Y" cards were not. dewdrop_hidden.d says Frostfern "**freezes** nightmares that have {damp}": Frost
doesn't slow (F.1); "freezes" is the retired Frozen meaning. → "…the {warden:hoarfrost}: its hits build {frost}."

### 7. English already wrong where code or a token chooses the form
- callings.gd:21 "Every 5th attack of **a {family:acorn}** aura Warden" shows "a Acorn". → "Every 5th attack of an
  aura Warden of the {family:acorn} family".
- nod_off.t "…{warden:dreamcatcher}s, **don't triggered it**." → "…don't trigger it."
- 197 `{warden:x}s` plurals glued in data, so writers hand-type the exceptions: "Rain Lilies", "Nimbuses",
  "Hatcheries", "Magpie Perches", "Crowns of Thorns", "Silence" (dream_silence.d has no plural at all). The token
  needs its own plural form (`{wardens:x}`), see §4.

### 8. "pass" has two definitions in rules text
bitter_hedges.t "Passed: stepped on a path cell sharing a side with it", briar_crown.t "Passes: steps on a path cell
sharing a side with it", but thorn_snare.t "Passes it: walks within about 1 cell of the Thornwall" (and tramplers.d,
hushed_hedge.d, card_scene.gd:202, dream_effects.gd:959 use it undefined). The same word is also the Dream skip ("Let
it pass"), passing_thread's "second pass", "passed crit" (calling_paths.gd:201-205) and Fathoms "pass the
{dread_shell}" (calling_paths.gd:404). **Fix:** one definition for walls ("walks past: steps on a path cell
{touching} it" or whatever the code does, check thorn_snare), and give the others their own verb: "hands on" (crit),
"ignore" (shell).

### 9. "grow" keeps a second life outside forms (60 places)
The 2026-10-25 rule: grow = forms only. Still: every Grove node ("Grows the first time you dispel the Moth Queen",
"Grows when all the other {nodes}…", grove_screen.gd:417-446 "Grow to level %d", "Grown", "Grows by itself",
heartwood_memory.gd:454-463), Kinships (codex_data.gd:66, :318, gift_screen.gd:64, heartwood_gifts.gd:79 "their bond
grows one step"), mushrooms (calling_paths.gd:54, :63, :134, codex_data.gd:75), glow / water / gold path
(codex_data.gd:77, :80, calling_paths.gd:199), effects (codex_data.gd:138 "Effects grow with Potency"), Legendaries
"grown in the Memory Grove" (codex_data.gd:149, :155), results_screen.gd:182 "Seeds grow permanent unlocks",
heartwood_gifts.gd:41/:67 ("It grows at each later act break", "The strike grows"), sunpetal.d / firefly_jar_hidden.d
("grows stronger"), bastion.role / rampart.role ("grows with walls"). **Fix:** Grove nodes "unlock" / "Unlocked"
(button "Plant"); bonds "get stronger"; effects "scale with"; mushrooms may keep "grow" (ruled).

### 10. "takes leaves" and "the rest": two avoid-list words the core screens still teach
"take(s)" for leaves / cells / health / Dew: 22 (thick_bark.d "takes no {leaves}", the three Omens brittle_night /
giants_walk / leaf_fall "takes twice as many {leaves}", crow.hint, codex_data.gd:15, :43, :109, :110 ×2,
icon_info.gd:30, :56, boss_dossier.gd:782, nightmare_icons.gd:58, twig_walls.d "take a quarter of a cell",
dawnbreak.d / jetreed.d / codex_data.gd:98, :148 health, thorny_walls.t, headlong.t / codex_data.gd:18 Dew,
omen_director.gd:271). "take" already means "receive damage" and "choose a card". → "costs {leaves}", "fills a
quarter of a cell", "removes 10% of their maximum health". "the rest" = the others: 10 (tempest.d / dream_tempest.d
"settle on the rest", codex_data.gd:36 "holds the rest back", "for the rest of the run" ×5, thinning_the_herd.d,
results_screen.gd:192). → "on the others", "until the run ends".

---

## 2. Every other flagged string

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| lucid_dream.d | "one of its {branches} it didn't offer this run" | two "it"s, one is the family, one the run | "one {branch} of that family that this run didn't offer is unlocked now, free" |
| hunters_moon.d | "Dispelling it gives the 2 nearest 1 {stack}." | "it" (stack or nightmare?), "2 nearest" has no noun | "Dispelling that nightmare gives the 2 nearest nightmares 1 {stack} of {marked}." |
| last_drop.t | "The Warden that added it deals it, as one new hit." | two "it"s | "The Warden that added the {damp} deals this damage as one new hit." |
| sporeling_ascension.d | "it never wears off while they stay in range" | it/they | "{spored} doesn't run down on nightmares in her range" |
| night_kite.hint | "it is past it in a moment" | two "it"s | "the Night Kite flies past one anti-air spot in a moment" |
| breathe_it_in.d | "3 if it is {asleep} or {held}" | subject is "statuses", "it" = nightmare | "3 if the nightmare is {asleep} or has {held}" |
| dream_maelstrom.d | "leaves {damp} on its nightmares and carries {static} bolts through it" | its/it = whirlpool, unclear | "gives the nightmares in it {damp}; a {static} bolt on one also hits the others" |
| snare_line.d | "each status on the one that triggered it" | it = trap | "…on the nightmare that triggered the trap" |
| callings.gd:24 | "its hits on it add twice as much status" | its = Warden, it = nightmare | "and its hits on that nightmare add twice as much status" |
| codex_data.gd:30 | "It changes your run until it ends." | it/it | "It changes your run until the run ends." |
| Reactions: drown, frostbite, ignite, lightning_rod, night_terror, pinned, shatter, sleepwalk, smother, thunderclap, flash_freeze | open "It …", "Its …", "That burst …" | no antecedent (gap G.2); the Crowned ones were fixed, the 11 base ones were not | open "The nightmare …" (flash_freeze: "The {frostburst} reaches 2 cells …") |
| heavy_going.t | "{held} and {asleep} nightmares stand still"; "{drowsy}'s"; "drips" | status as adjective; token possessive; "drips" undefined | "Nightmares with {held} or {asleep} stand still, so they don't count. … Slows from {drowsy} and from the Calling don't count." (check "drips") |
| nothing_wasted.t, wash_away.t | "shelled nightmares", "a crust that blocks / takes part of each hit" | adjective from a term; two verbs for the shell | "nightmares with a {dread_shell}", "a crust that absorbs part of each hit" |
| codex_data.gd:111, nightmare_icons.gd:45 | "A shell … cracks for good", "Each hit wears it down" | bare "shell", "for good", phrasal | "A {dread_shell} absorbs part of every hit until it breaks; each hit weakens it." |
| codex_data.gd:183, :123 | "Exposed Blow" (combo name) | old status adjective (round 1 §6) | rename with the owner (e.g. "Exposure Blow") |
| rooted_nightmares (card name) | "Rooted Nightmares" | raw adjective of {held} (Rooted ruled out 2026-10-13) | owner call; e.g. "Rooting Strikes" |
| moon_moth.d | "Long-range shots that Expose" | status as verb | "Long-range shots that add {marked}" |
| torrent.d | "a wet trail … that Soaks nightmares crossing it" | status as verb; "wet" | "a trail … that gives nightmares crossing it {damp}" |
| role lines (59: Soaks 11, Roots 9, Drowses 7, Charges 13, Poisons 9, Frosts 4, Exposes 2, Silences 2, + gift "Heartwood Roots") | "Drowses, area damage" | status nouns as verbs (P1 §3) | "Adds Drowsy, area damage" (or the status icon in the role chip) |
| dream_echo_hollow.d, echo_hollow.d | "repeats a second later" | ordinal / time | "repeats 1 s later" |
| headlong.d, refrain.t, second_verse.t | "any {drift} but a boss {drift}", "any but that … Warden" | "any X but Y" (r1025 list) | "any {drift} except a boss {drift}" |
| chain_bloom.d | "×1.5 as wide" | r1025 list | "50% wider" |
| heartwood_gifts.gd:71 | "half again as many {stacks}" | idiom | "50% more {stacks}" |
| few_and_mighty.d | "for each one short of 12" | idiom | "for each attacking Warden fewer than 12" |
| ebb.t, gone_to_seed.t, mixed_company.t, mycelium.t, overnight.t, second_verse.t, calling_paths.gd:458, :482 | "{static} stops 1 short of a bolt", "{drowsy} stops 1 short of {full}" | idiom (round 2) | "{static} stops 1 below its bolt" |
| sap_rising.t, thunderstruck.t, topped_up.t, calling_paths.gd:419, :423, :446 | "in all" | idiom | "in total" |
| heartwood_sapling.d, drift_panel.gd:93, nightmare_icons.gd:52 | "rooted for good", "for good" | idiom + Root | "permanent" |
| leaf_bug.hint, bark_beetle.hint, waymark.t, wild_growth.t | "The trick is…", "buy a lot of time", "a kill zone", "where nightmares die" | idioms; "kill", "die" for dispel (rule 17) | "The hard part is…", "give you more time", cut the "A bet:" advice |
| momentum.t, quickening_ii.t | "a kill never drops it", "while kills keep coming" | kill = dispel (rule 17) | "a dispel never …", "while dispels keep coming" |
| quickening_ii.t | "The rush keeps building" | "Rush" is also Headlong's Rush button | "The bonus keeps building" |
| dream_vesper_bell.d, dream_great_bell.d, dream_silver_bell.d, silver_bell.d, vesper_bell.d, great_bell.d, calling_paths.gd:269 | "peal", "peals" | P1 §3: one word for one bell hit; "Peal" is not a term | "ring" (or "attack") |
| bellflower.d, hushbell.d | "Rings out, …" | phrasal + {ring} term | "Its ring damages every nightmare in range…" |
| calling_paths.gd:292 | "When Midnight strikes, … strike their own Midnight" | round 3 list: strikes → lands | "When a Midnight {toll} lands, … get their own Midnight {toll}" |
| dream_nimbus.d, nimbus.d | "drift to the busiest spot" | drift = the wave term | "move to the busiest spot" |
| eddy.d | "1 step either side" | raw step beside {step} | "1 {step} either side" |
| crossroads.cap, seeping_in.t, calling_paths.gd:176, dream_batch_rules.gd:654 | raw "steps" | {step} exists | "{steps}" |
| codex_data.gd:45, :46, signatures.gd:35, heartwood_gifts.gd:79 | "second-step form", "third step", "one step stronger", "grows one step" | step = path cell | "second form", "third form", "one stage stronger" |
| calling_paths.gd:50, :51, :54, :63, :76 | "eating", "eat", "eaten", "A {mushroom} doses each nightmare" | round 3 list | "using up", "is used up", "gives each nightmare one {dose}" |
| calling_paths.gd:72, :73, :182 | "calls a {free_hit}", "never calls another", "never call more" | call = Calling / call early | "gives", "never gives another" |
| wider_roots.d, codex_data.gd:29, remember_screen.gd:552 | "calling back", "call back", "call one in" | same | "adding back", "add one" |
| calling_paths.gd:32, :97, :100 | "go first when there are more than 40" | round 3 list | "are removed first" |
| calling_paths.gd:287, :320, :401 | "swell", "Dreams that quicken it", "has waded the pond" | round 3 list | "bonus", "Dreams that make it faster", "has spent in the pond" |
| calling_paths.gd:283, :284, :319 | "makes a {toll}" | roguelite list | "gets a {toll}" |
| calling_paths.gd:357 ×2, :454 | "each end of a {water}", "for each {water}", "each {water} it leaves" | uncountable token | "each stretch of {water}" |
| calling_paths.gd:245, :246 | "a pile" of embers | round 2 list | "a heap of embers" or "an ember group" |
| calling_paths.gd:109, :202 | "don't pass on", "never passes on" | phrasal | "aren't passed again", "is never passed again" |
| calling_paths.gd:163 | "takes over its streak" | phrasal | "gets its streak" |
| calling_paths.gd:384, :398 | "spill onto up to 4 others" | phrasal ("Spill" is a Codex term, the verb isn't) | "also hit up to 4 others for 25% of the hit" |
| dream_edgestone.d | "the leftover damage spills onto the next" | phrasal | "the damage left over hits the next nightmare" |
| dream_midsummer.d | "carries on to the nightmare right behind it" | phrasal | "also hits the nightmare right behind it" |
| homesick.d | "topped up to full time" | phrasal; "full" ≠ {full} | "restart their time" |
| dream_jetreed.d, wash_away.d | "wears down", "wear its {dread_shell} down" | phrasal | "removes", "weaken its {dread_shell}" |
| bound_and_burning.d, eternal_static.d, hunters_moon.d/.t, last_drop.t, barrow_wight.trait, sporemother.d, dream_sporemother.d, sporeling_ascension.d, dreamcatcher.d, great_dreamcatcher.d (+dream_ versions), icon_info.gd:21, :26, codex_data.gd:184, lesson_card.gd:222, calling_paths.gd:446, :450, nightmare_icons.gd:233 | "wear(s) off", "stop wearing off" | phrasal; the Frost texts already say "run down" | "run(s) out", "stop running down" |
| ash_crawler.trait, nightmare_icons.gd:55, puffcaplet.hint, shellbound.hint, sleepwalk.d | "burns {spored} off", "Shakes {drowsy} off", "sweep them up", "cracks off", "turns round" | phrasal | "removes {spored} from", "Removes {drowsy} from", "hit them all", "breaks", "turns back" |
| edgestone.role, whetstone.role/.d, signatures.gd:34, :46 | "finishes off the weak" | phrasal | "dispels weakened nightmares" |
| calling_paths.gd:243 | "They go out when a {rest} starts." | phrasal | "They disappear when a {rest} starts." |
| dream_rootling.d | "Its roots nip at everything in range." | phrasal + roots | "It damages every nightmare in range." (round 1 ruling 8) |
| dream_windmill.d, drowned_one.hint, nightmare_icons.gd:46 | "loves bends", "Lightning loves {damp}" | personification | "stronger beside bends", "Lightning hits harder on {damp}" |
| smother.d | "its {spored} stops hurting and swells" | personification | "its {spored} stops dealing damage and builds up" |
| cairn.d/.role, rockslide.role, dream_cairn.d, codex_data.gd:201, :309 | "Lobs", "lob" | rare verb | "Throws … over walls" |
| dream_silence.d, silence.d | "a wider hush" | rare word | "a wider silence" |
| icon_info.gd:25 | "long but fragile" | rare word | "Stopped for 3 s; a big hit (10%+ of its health) wakes it." |
| hollow_oak.trait | "grieves as it weakens" | rule hidden in flavour | say what it does (check) |
| dream_nestling.d, nestling.d, homing_instinct.d/.t ×4, codex_data.gd:313, callings.gd:22 | "swoops", "swoop" | gap list | "attacks", "dives" (or define Swoop) |
| old_growth.d, callings.gd:24 | "turns to a new nightmare", "turns to face" | gap list | "targets a new nightmare", "targets" |
| callings.gd:23 | "lodges in its target" | gap list | "stays stuck in its target" |
| codex_data.gd:201 | "leaves scree" | gap list | "leaves loose stones" |
| codex_data.gd:47, calling_paths.gd:442, :476 | "on top of" | round 2 list | "in addition to", "added to" |
| codex_data.gd:141, :142, guiding_light.t, guiding_light_ii.t, starlit_aim.t, flashover.t, calling_paths.gd:89 | "its most", "usual most", "Half of the most it dealt" | r1025 list: "most" as a noun | "its maximum", "the highest damage it dealt to one nightmare" |
| mycelium.t, warden_panel.gd:300, dream_hit_cards.gd:487, :489, calling_paths.gd:92, :96, :99 | "feed", "fed", "Feeding", "fed ground" | r1025 list | "add to", "giving attacks", "spored ground" (check name) |
| undercurrent.d, codex_data.gd:64 | "Opens a whirlpool", "Opens with a clearing Dream" | r1025 list | "Makes a whirlpool", "You can use it after taking a clearing Dream" |
| drift_panel.gd:520 | "clear it clean for a Rare Dream" | r1025 list | "lose no leaves in it for a Rare Dream" |
| slow_burn.d/.t, calling_paths.gd:148, :151, :154, :252 ×2, codex_data.gd:314, strength_ribbon.gd:26 | "has carried {spored}", "Carried:", "carries a lantern", "A shot carries", "what carried this block" | carry = the perk verb ("While carried") | "has had {spored} without a gap", "gets a lantern", "reaches", "what did the most this block" |
| struck_twice.t, nod_off.d, slow_burn.t | "waiting hit", "one sleeper", "A new batch" | undefined nouns | "one extra hit waits", "one nightmare {asleep} at a time", "New {stacks}" |
| bearing_down.d, momentum.d, da_capo.d | "in a row" for repeated attacks | roguelite list | "without changing target"; da_capo "happens twice" |
| codex_data.gd:28, :29, family_pick_screen.gd:149 | "you deepen a family" | round 2 list; the pick is called Deepen | keep the term as a name only: "After drift 60, the Deepen pick: choose a family you already have." |
| codex_data.gd:93, :94, :310, distance_diagram.gd:10 | "square", "small squares", "lit tiles" | one name: cells | "half-cells", "lit cells" |
| longer_roots.cap, walking_wood.t, calling_paths.gd:35, :39, gift_screen.gd:824, :826, rest_report.gd:284, dream_batch_rules.gd:643, :654, test_grove.gd:359 | "route" | one name: path | "path" |
| dream_lightning_fence.d, dream_nestling.d, dream_starling_murmuration.d, dream_wrens_nest.d, dandelion_seed.hint, codex_data.gd:99, :296 | "Phantoms" | the Kind is Flying; the nightmare is Dandelion Seed | "{nightmare:dandelion_seed}s" / "flyers" |
| run_history.gd:922, :962, :970 | "first leak", "leaked" | P1 list (the copied run report is player-visible) | "first leaf lost", "reached the Heartwood" |
| codex_data.gd:36 | "holds the rest back" | rest = rest | "holds the others back" |
| card_scene.gd:202, touch_build.gd:88 | "the marked Thornwalls", "the marked Wardens" | "marked" = old Exposure id; "mark" also = Reaction mark, rank V mark | "the highlighted Thornwalls", "the Wardens you picked" |
| codex_data.gd:42 | "it blocks the path like a wall" | block = 5-drift term | "it is a wall: nightmares walk around it" |
| brittle.d, bark_beetle.trait, shellbound.trait | "{dread_shell} blocks half as much", "blocks part of every hit" | block verb; shell verb is "absorbs" (round 2) | "absorbs half as much", "absorbs part of every hit" |
| cozy_corners.t, long_way_round.t, switchback.t, witching_bend.t | "Bend: a turn with a full cell of straight path…" | "turn" defines "bend" | "Bend: where the path changes direction, with …" |
| nightmare_icons.gd:48, old_stag.trait, hedgehog.hint | "until the next turn", "long straights", "a short straight" | straight as noun (P1) | "until the next bend", "long straight stretches" |
| dream_dream_oak.d | "from a mixed grove" | Grove = Memory Grove | "from mixed families" |
| dream_dewcatcher.d | "poured out at the {rest}" | idiom | "paid at the {rest}" (or "given") |
| heartwood_sapling.d | "withers the yield 5%" | idiom | "lowers the {dew} it gives by 5%" |
| dream_whetstone.d | "worn-down nightmares" | unclear | "nightmares below 30% health" |
| dream_whirligig.d | "Its gusts carry trouble along" | idiom | cut; the rule follows |
| gust.d, mossback.d | "others close to it", "a nightmare close by" | unlinked distance | "others within N cells" / "{touching}" (check) |
| winding_roads.d, dream_deeproot.d, night_terror.d, sleepwalk.d, codex_data.gd:184, icon_info.gd:26, gift_screen.gd:46-54, nightmare_icons.gd:54-56, enemy traits (8) | raw "near" | {near} = 2 cells; raw "near" reads the same | `{near}` where the code uses 2 cells, else "within N cells" |
| acorn.d, elder_stump.d, mother_log.d, nurse_log.d, prism_jar.d, rainbow_prism.d, pinwheel.d, windmill.d | "in the 8 cells around it" | correct but is the {touching} definition | "{touching} it" |
| codex_data.gd:130, fever_dream.d, codex_data.gd:197, enemy.gd:2039, rest_report.gd:10, watcher.hint, dreamshroom.role, great_bell.role, bellflower.d (Grove node) | raw "sleep", "fall asleep" | roguelite list: plain sleep → {asleep} | "{asleep}" |
| codex_data.gd:79, :83 | "A jump triggers another jump", "Every 4th ring makes a Toll" | glossary lines as rules; fine. | (no change) |
| dream_hatchery.d | "every {…:count}th sprite" | English ordinal glued to a token | "every Nth sprite" as one token, or "one sprite in every N" |
| settings_panel.gd:207 | "Never always skips them." | reads as a contradiction | "Never: Omens are always skipped." |
| warden_header_view.gd:385 | "Some Dream cards wake only once you have grown a Warden…" | wake = family pick / Asleep | "Some Dream cards are offered only once…" |
| warden_panel.gd:1213 | "Growing gets dearer … finals" | rare word; "finals" | "Growing costs more … final forms" |
| family_pick_screen.gd:598, :859 | "Sprout into it", "Dreams into, %d of %d" | Sprout as a verb; "Dreams into" unclear | "Grow a Sprout into it", (check what :859 labels) |
| dream_effects.gd:956 | "pin new primary targets" | pin = the Pinned Reaction | "hold new targets in place" |

---

## 3. Patterns and rules

### 3.1 Avoid-list words still in rules text (count by word, with places)

Counted by script over the three corpora (player strings only), then spot-checked; places are in §1, §2 or listed
here. Total about **820 hits** (the 62 "Safe. / A bet:" tags are left out: kept by the round 3 ruling).

| Word (list) | Hits | Places |
|---|---|---|
| set off / go off / fire (P1, rule 10) | 8 | §1 item 2 |
| a second later (P1) | 2 | dream_echo_hollow.d, echo_hollow.d |
| the rest / rest of the run (P1) | 10 | burn_back.cost, deep_sleep.cost, restless_dreams.cost, thinning_the_herd.d, tempest.d, dream_tempest.d, codex_data.gd:36, results_screen.gd:192, heartwood_gifts.gd:63, omen_director.gd:449 |
| take(s) leaves / cells / health / Dew (P1) | 22 | §1 item 10 |
| leave / leaves / left as a verb (P1) | 48 | "leaves a patch / trail / mushroom / ember / note" (= makes, ~28): lingering_splash.d, bloomcap.d, inkcap.d, torrent.d, dream_torrent.d, stormheart.d, dream_stormheart.d, firefly_jar_ascension.d, never_quite_dry.d, hushbell.d, broad_strokes.d, great_dreamcatcher.d (+dream_), dream_maelstrom.d, dream_mother_log.d, second_verse.d, codex_data.gd:195, :290, :301 ×2, :307, lesson_card.gd:216, calling_paths.gd:96, :133, :242, :298, :308, :330, callings.gd:17; "leaves its range / {water} / a glow" (= exits, ~20): silence.d, dream_silence.d, morning_fog.d (+dream_), dream_inkcap.d, mushrooming.d, nowhere_to_run.t, passing_thread.t, steeped.t, calling_paths.gd:166, :172, :175, :363, :372, :402, :434, :438, :446, :453, :454 |
| block (verb) (P1) | 7 | brittle.d, bark_beetle.trait, shellbound.trait, nothing_wasted.t, codex_data.gd:42, run_saver.gd:429, :430 |
| step / steps raw (P1, beside {step}) | 39 | bitter_hedges.t, briar_crown.cap/.t, crossroads.cap ×2, eddy.d, seeping_in.t, spent_light.d, elf_circle.d (+dream_), fairy_ring.d (+dream_), codex_data.gd:45, :46, :75, :76, :91, :94 ×2, :310, dream_batch_rules.gd:654, heartwood_gifts.gd:79 ×2, signatures.gd:35, calling_paths.gd:38, :57, :60, :66, :69, :75 ×2, :113, :116, :130, :136, :176, :381, callings.gd:17 ("steps on" is a plain verb; fine where no {step} is meant) |
| grow (not a form) (P1, 10-25 rule) | 60 | §1 item 9 |
| catch / caught (not {caught}) (P1) | 23 | dew_bowl.grows_text, dream_wellspring.d, dream_autumn_gale.d, dream_lightning_fence.d, dream_thief.hint, leaf_bug.hint, mother_duck.hint, pall.hint, codex_data.gd:17 ×2, :54, :99, :197, :294, lesson_card.gd:666, warden_header_view.gd:296 ×2, :298, :594, support_log.gd:172 (Dewcatcher "catch" is its name; the rest → "collect", "hit") |
| marked raw (P1) | 2 | card_scene.gd:202, touch_build.gd:88 |
| roots / rooted flavour (P1) | 11 | dream_rootling.d, dream_rootlight.d, rootlight.d, dream_groundroot.d, dream_world_root.d, world_root.d, rootling_hidden.d, rootling.d (Grove), hollow_oak_withering.trait, heartwood_sapling.d, drift_panel.gd:93 |
| echo raw (P1) | 14 | clean_night.t ("Echoes don't count": which echoes?), dream_vesper_bell.d, reprise.t, spattered.t, hollow_oak_remembering.trait (boss echoes), codex_data.gd:137, :311 ×3, + Echo Hollow texts |
| peal / rings out (P1) | 9 | §2 |
| corner / turn (P1) | 12 | cozy_corners.t, long_way_round.t, switchback.t, witching_bend.t, root_network_ii.t ×2, hedgehog.hint, nightmare_icons.gd:48 (+ "corner brackets" UI: fine) |
| straight as a noun (P1) | 2 | hedgehog.hint, old_stag.trait |
| near 30 · nearby 6 · beside 46 · around 36 · close by/to 2 · next to 2 (P1, unlinked) | 122 | near: §2; nearby: dream_dewdrop.d, dream_echo_hollow.d, dream_old_mountain.d, loose_stones.d/.t, dream_keywords.gd:43; beside: 46 (pebbling.d, acorn.d, moonstone.d, cairn.d, standing_stone.d, rockslide.d "right beside it", ignite.d, shatter.d, fever_dream.d, codex_data.gd:115, :136, :302, :304 ×2, :309, warden_panel.gd:403, heartwood_gifts.gd:77, calling_paths.gd:254, :357 …); around: 36 (mostly "the 8 cells around it" = {touching}) |
| phrasal verbs (P1, round 3) | 41 | §2 rows "wear off", "spill onto", "carries on", "topped up", "finish off", "burn off", "go out", "pass on", "takes over" |
| pay / pays / paid (P1, round 2) | 43 | cards: deep_sleep.t, double_or_nothing.d, gathering_storm.t, held_breath.d, morning_dew.t, wild_growth.t, heartwoods_reach.t, lean_season.d, planted_promises.d ("pay off"); Nurture cost: nurse_log.d, mother_log.d (+dream_), leaf_or_dew.d; Dew economy (Codex, lessons, HUD, catcher panels: 26). Economy "pays Dew" is plain money talk; the card / tip ones ("still pay", "pays when", "pay off") are the idiom. |
| leak (P1) | 3 | run_history.gd:922, :962, :970 |
| pierce (P1) | 3 | run_through.d/.t, pinned.d (no glossary entry) |
| loves / grieves / fragile / hush / swells / lobs (P1) | 16 | §2 |
| idioms: in all, one short of, stops 1 short, for good, the trick is, buy time, kill zone, where nightmares die (P1, round 2) | 24 | §2 |
| Soaks / Roots / Drowses / Exposes / Frosts / Charges / Poisons / Silences as verbs (P1) | 59 | role lines (55), moon_moth.d, torrent.d, gift_screen.gd:58, rest_report.gd:79 ×2, heartwood_gifts.gd:75 |
| kill / kills (round 2, rule 17) | 4 | momentum.t, quickening_ii.t, waymark.t, run_history.gd:962 |
| on top (round 2) | 3 | codex_data.gd:47, calling_paths.gd:442, :476 |
| crit / crits as a verb (round 2) | 13 | dream_boulderback.d, boulderback.d, dream_old_mountain.d, old_mountain.d, dream_prism_jar.d, white_stag.d, memory_white_stag.d, opening_fracture.t, codex_data.gd:309, calling_paths.gd:191, :195, :201 ×2 |
| pile (round 2) | 6 | icon_info.gd:21, lesson_card.gd:222, calling_paths.gd:245 ×2, :246 ×2 |
| arc as a verb (round 2) | 1 | thunderclap.d "arcs to nightmares" |
| every other (= all others) (gap) | 6 | mycelium.d, undiluted.d, starfall.d, calling_paths.gd:178, :484; windmill.d "Every other spin" (= every 2nd: rule 4) |
| turns to / lodges / swoop / scree (gap) | 14 | §2 |
| Breaks the rules (gap) | 1 | coming_strip.gd:428 (fallback text) |
| eat / eaten / eating, doses (round 3) | 6 | calling_paths.gd:50 ×2, :51, :54, :63, :76 |
| quicken / waded / swell (round 3) | 3 | calling_paths.gd:287, :320, :401 |
| strike / strikes / struck, not Harmony strike (round 3) | 18 | rolling_thunder.cost (+_ii), lightning_rod.d, firefly_jar.d, chime_stone.d, lullaby_bell.d, great_bell.d, lightning_fence.d, thunderhead.d, wrens_nest.d, gift_screen.gd:50, lesson_card.gd:224, rest_report.gd:77, dream_keywords.gd:59, heartwood_gifts.gd:67 ×2, calling_paths.gd:292 ×2 |
| {water} counted (round 3) | 3 | calling_paths.gd:357 ×2, :454 |
| half again / ×1.5 as wide (roguelite, r1025) | 2 | chain_bloom.d, heartwood_gifts.gd:71 |
| makes a {toll} (roguelite) | 3 | calling_paths.gd:283, :284, :319 |
| lit raw (roguelite) | 5 | rootling_hidden.d, codex_data.gd:310, heartwood_gifts.gd:73, tower.gd:1397, :1455 |
| for nothing else (roguelite) | 1 | callings.gd:30 |
| sleep / asleep raw (roguelite) | 9 | §2 |
| the one hit / the nightmare hit (r1025) | 6 | §1 item 6 |
| bare shell / blight coat (r1025) | 15 | barrow_wight.hint, shellbound.hint, old_lichen.d, nothing_wasted.t, wash_away.t, codex_data.gd:111 ×2, :296, :637, nightmare_icons.gd:45 ×2, signatures.gd:30, :43, test_grove.gd:254 (dev), codex_data.gd:567 |
| Opens (r1025) | 2 | undercurrent.d, codex_data.gd:64 |
| any X but Y (r1025) | 3 | headlong.d, refrain.t, second_verse.t |
| most as a noun (r1025) | 8 | §2 |
| fed / feeding (r1025) | 7 | §2 |
| clear it clean (r1025) | 1 | drift_panel.gd:520 |
| carried, not a perk (r1025) | 9 | §2 |
| tiles / square (round 1 §6) | 4 | codex_data.gd:93, :94, :310, distance_diagram.gd:10 |
| route (round 1 §6) | 14 | §2 |
| Phantom(s) (round 1 §6) | 7 | §2 |
| Rooted / Exposed raw (round 1 §6) | 2 + 1 name | codex_data.gd:123, :183; card name Rooted Nightmares |
| chain / jump as plain verbs, raw (round 1) | 9 | stormcap.d ×2, stormheart.d, thunderhead.d, firefly_jar_ascension.d, the_old_ones.t ("It never chains"), codex_data.gd:39, :179, signatures.gd:33 |
| drift as a verb (P1) | 2 | dream_nimbus.d, nimbus.d |
| deepen raw (round 2) | 4 | codex_data.gd:28 ×2, :29, family_pick_screen.gd:149 |
| sleeper / waiting hit / batch (round 2) | 3 | nod_off.d, struck_twice.t, slow_burn.t |
| in a row, repeated attacks (roguelite) | 3 | bearing_down.d, momentum.d, da_capo.d |
| call / calls / call back, not Calling (round 3) | 6 | calling_paths.gd:72, :73, :182, wider_roots.d, codex_data.gd:29, remember_screen.gd:552 |
| go first (round 3) | 3 | calling_paths.gd:32, :97, :100 |
| bare rank (10-25 rule) | 36 | §1 item 3 |
| Gone (count 0): Let go, Dream again, New cards, Hints, Rime, Hoar Fog, blight coat in player text, be it, Rush on, every second ring | 0 | fixed |

**Words to avoid: additions this round**

| Avoid | Use instead |
|---|---|
| Hollow (stack state) | Unsettled (owner call) |
| pass / passes (walls), passed crit | walks past (one definition); hands on |
| peal | ring |
| dearer, finals | costs more, final forms |
| shelled (nightmares) | with a {dread_shell} |
| pin (targets) | hold in place |
| nip at, lobs | damages, throws |
| freezes (Frost) | builds {frost} |
| rush (outside Headlong) | bonus |
| Expose / Soaks (in sentences) | adds {marked} / gives {damp} |
| a {family:acorn} (vowel names) | of the {family:acorn} family |
| `{jumps}`, `{dispels}`, `{tolls}`, `{dew_splashes}`, `{crit}` as verbs | a plain verb + the token as noun |

### 3.2 Words with two game meanings across the whole game

| Word | Meanings | Worst places | Fix |
|---|---|---|---|
| **Hollow** | Unsettled stacks (new) · the Hollow (villain) · The Hollow Oak · Echo / Whispering Hollow · Hollow Ground ("a moved hollow") · Hollow Wind · Hollow Stag | codex_data.gd:143, nightmare_info.gd:463 | rename the stack state (§1 item 4) |
| **grow** | form change · Grove nodes "Grows / Grown / Grow to level" · mushrooms · Kinship bond · effects scale · gift strike · "Seeds grow unlocks" | §1 item 9 | Grove: "unlock"; bonds: "get stronger" |
| **pass** | skip a Dream ("Let it pass") · wall contact (two definitions) · second pass · passed crit · pass the shell | §1 item 8 | one definition; other verbs |
| **carry** | perk "While carried / Carry into the run" · status kept "carried for 4 s" · lantern "carries a lantern" · shot "carries to" · "what carried this block" · Carrying Tune · "carries {static} bolts" | slow_burn.d/.t, calling_paths.gd:148-154, :252, strength_ribbon.gd:26 | keep "carry" for perks only |
| **step** | {step} path cell · "steps on" · "second-step form / third step" · "bond grows one step" · "one step stronger" | codex_data.gd:45, :46, heartwood_gifts.gd:79, signatures.gd:35 | "form", "stage" |
| **ring** | {ring} bell count · Fairy / Elf Circle traps "rings" · Fairy Circle "Mushroom rings" · "ring of toadstools" (gift) · Great Ripple "in a ring" · "-Rings" rank cards · "Rings out" · Bell Stone "rings" | elf_circle.d, fairy_circle.d, great_ripple.d, heartwood_gifts.gd:71 | traps: "circles" or "traps"; ripple: "1 cell wider all round" |
| **note** | Counterpoint mark on a nightmare (calling_paths.gd:308, :311) · Sounding note left on the path (:330, :333) | calling_paths.gd:308 vs :330 | one of them "echo mark" / "lingering note" (Roguelite) |
| **cap** | a limit (Wellspring cap, card cap, "+30% limit") · a mushroom cap (Host Trees "wears a cap", "Its cap is pale") | calling_paths.gd:103-110, :134, :137 vs warden_header_view.gd:302 | limits: "at most"; caps stay mushroom-only |
| **block** | 5-drift unit · "blocks the path" · shell "blocks half" · "path was blocked" | codex_data.gd:42, brittle.d, run_saver.gd:429 | block = unit only |
| **leaves** | lives · verb leave (48) | §3.1 | "makes", "exits" |
| **rest** | the pause · the others / "rest of the run" (10) | §3.1 | "the others", "until the run ends" |
| **dream** | Dream card · the run ("The dream goes dark", pause_menu.gd:410, results_screen.gd:96, codex_data.gd:15; "the dream offers", remember_screen.gd:552) · the world | as listed | "run" in rules text; story keeps "dream" |
| **wake** | choose a family ("Wake a family", "Choose a family to wake") · leave {asleep} · "Dream cards wake only once…" (warden_header_view.gd:385) · "how the Hollow Oak wakes" | lesson_card.gd:579, family_pick_screen.gd:87 | family pick: "Choose"; cards: "are offered" |
| **full** | {full} (status maximum) · "full damage / full hit / full time / full refund / in full / full strength" | homesick.d, grafted_elder.d, calling_paths.gd:283, second_path.d | keep "full" for {full}; "all of the damage", "the whole hit" |
| **Kind** | Nightmare Kind (glossary) · "another kind of Warden", "each kind of joined Warden" | callings.gd:23, calling_paths.gd:308, :309, :311 | "another form", "each different Warden form" |
| **Rush** | Headlong's Rush button · the card Hunt's Rush ("The rush keeps building") | quickening_ii.t | "bonus" in the tip |
| **land** | a hit lands · a flyer lands (snag.d, earthbind.d) | snag.d, earthbind.d | flyers "come down" |
| **Frost / freeze** | Frost status · Frozen Ground Omen · "freezes" (dewdrop_hidden.d) · First Grip's file id first_frost (not shown) | dewdrop_hidden.d, tower_placer.gd:2656 | dewdrop_hidden: "builds {frost}"; Omen name an owner call |
| **lit** | {lit} nightmare in a glow · Rootlight "lit path / cells" · "lit stone" gift | rootling_hidden.d, tower.gd:1397, heartwood_gifts.gd:73 | "glowing cells" (rootlight.d already says it) |
| **mark** | Reaction mark · "earns a mark" at rank V (lesson_card.gd:667) · Growth marks · sell-mode "marked Wardens" · "marked Thornwalls" | as listed | "highlighted", "picked" |
| **call** | Calling · call early · "calls a {free_hit}" · "call back / call one in" a branch | §3.1 | keep for Calling and call early |
| **strike** | Harmony strike (term) · Midnight "strikes" · bolts "strike" · Lightning Tree "strikes" | §3.1 | "hits", "lands" outside the term |
| **pond** | Black Pond Calling's pond · Pond Keeper's pond · gift "Place a 2×2 pond" | calling_paths.gd:384-479, pond_keeper.d, heartwood_gifts.gd:65 | gift: "spring" or "pool" (it is the "Spring" in gift_screen.gd:46) |
| **echo** | Echo Hollow repeats · boss echoes (Remembering) · "Echoes don't count" (clean_night.t) | clean_night.t | name which: "Echo Hollow repeats don't count" |
| **pin** | Pinned Reaction · "pin new primary targets" (dream_effects.gd:956) | | "hold" |
| **Charge** | Charge status · "charges down long straights" (old_stag.trait) | | "runs down long straight stretches" |
| **Root** | status · damage type · flavour roots · "Heartwood Roots" gift (rest_report.gd:79 "gave Roots to %d") | round 1 still open | "gave Root to %d nightmares" |

### 3.3 Unclear "it" (rule 13)
§1 item 5 (briar_crown.d, shared_light.d, the_tallest_tree.d + warden_panel.gd:1464, thorncoil.d, chime_stone.d,
lullaby_bell.d, great_bell.d, whirligig.d + dream_whirligig.d, dream_frostfern.d) and §2 (lucid_dream.d,
hunters_moon.d, last_drop.t, sporeling_ascension.d, night_kite.hint, breathe_it_in.d, dream_maelstrom.d,
snare_line.d, callings.gd:24, codex_data.gd:30, the 11 base Reactions that open "It / Its / That"). 21 places.

### 3.4 Status names used as adjectives
Mostly fixed ("nightmares with {damp}" is now the norm: 0 hits of "{damp} nightmare" type). Left: heavy_going.t
"{held} and {asleep} nightmares" ({asleep} is a state and fine; {held} is not); "shelled nightmares" (nothing_wasted.t,
wash_away.t); "Exposed Blow" (codex_data.gd:123, :183); the card name "Rooted Nightmares"; "a wet trail"
(torrent.d, dream_torrent.d) next to {damp}. Status nouns as verbs: 59 (§3.1 role verbs).

### 3.5 Token nouns used as verbs
`{jumps}` 21, `{dispels}` 2, `{tolls}` 1, `{dew_splashes}` 1, `{crit}` 1 (§1 item 1). Possessive or plural glued to a
token: `{warden:x}s` 197, `{nightmare:x}s` 15, `{warden:x}'s` 6, `{named_combo:x}'s` 3, `{combo:x}'s` 2,
`{rank}s` 2 (dream_mother_log.d, wild_growth.t: `{ranks}` exists), `{frostburst}s` (undiluted.d: `{frostbursts}`
exists), `{marked}'s` (dream_beacon.d), `{drowsy}'s` (heavy_going.t), `{calling}'s` (homesick.t), `{card:x}'s`
(nursery.d), `{family}'s` (overnight.d), `{drift}'s` (wild_dew.d), `{act}'s` (heartwood_gifts.gd:63), `{reaction}'s`
(witching_bend.d, callings.gd:30).

### 3.6 Habits (one line each)
- **Evolution cards lag their Warden** (Frostfern, Dewdrop, Old Mountain, Puffball, Hoarfrost, Rain Lily, Rootling):
  when a Warden text changes, change its "can now grow into" card in the same commit.
- **A rule word defined twice** (pass, Nearest: "within 2 cells" vs "within 3 cells" in hunters_moon.t): one glossary line, linked.
- **Fixed phrases already decided keep slipping back** (set off, wear off, bare rank): add them to
  `tests/test_text_style` as banned strings, as the Frost numbers are.
- **Lessons and Reactions open with "It"** where the heading carries the subject; screen readers and translators get
  the line alone. Name the nightmare.
- **Money words** stay right for Dew ("pays Dew"); never for effects ("still pay", "pays when", "pay off").

---

## 4. Localisation list (updated; file:line as of this corpus)

No `tr()`, `TranslationServer`, .po or .csv anywhere in `scripts/`: every player string is a literal. Nothing below is
urgent for an English launch; all of it blocks the first translation.

**A. English-only plurals in code (`"" if n == 1 else "s"` and helpers): 37**
boss_dossier.gd:299, :677, :791 (`display_name + "s"`), :891; kinships.gd:649; signatures.gd:230;
dream_effects.gd:297, :935 `count_text()` (callers :525, :561, :929, :959); dream_state.gd:579, :4778
("family"/"families"), :5529; tower_placer.gd:481, :2579 (`display_name + "s"`); run_saver.gd:426, :428;
tower.gd:1791; dreams_row.gd:278; drift_banner.gd:215; icon_info.gd:353 (plural token ids), :494; codex_panel.gd:669,
:877 (verb agreement "wait%s"), :1069, :1130, :1172, :1600, :1962, :2110, :2113; status_links.gd:221;
warden_panel.gd:378, :620 + :723 `_plural()`; buff_sources.gd:281 (`"%d %ss"` and a/an by first letter).
No singular at all: support_log.gd:176 "(to %d Wardens)", touch_build "Plant %d" / "Sell %d", shape_rows.gd:79
"%d packs of %d".

**B. Token plurals and glued endings in data**
icon_info.gd:236-346 TERMS hold one singular + one plural; `{water}`, `{lingering}`, `{full}`, `{potency}`,
`{dreamlight}`, `{leaves}` repeat the singular. 197 `{warden:x}s`, 15 `{nightmare:x}s`, 6 `{warden:x}'s` and the
token possessives in §3.5. Hand-typed plurals prove it: "Rain Lilies", "Nimbuses", "Hatcheries", "Magpie Perches",
"Crowns of Thorns". Ordinals: dream_hatchery.d "{…:count}th"; settings_panel.gd:25-26 "1st / 2nd / 3rd / 4th option";
"Every 3rd / 5th …" in ~60 cards. Need per-language plural forms on the token (`{wardens:x}`) and an ordinal token.

**C. Articles, case and agreement chosen in code: 20**
icon_info.gd:366-374 `name_in_sentence` / `the_name` (callers boss_dossier.gd:306, :535, hud.gd:284,
nightmare_intro.gd:298); tower.gd:298 and dream_state.gd:4767 `begins_with("The ")`; buff_sources.gd:281 "a"/"an";
callings.gd:21 "a {family:acorn}" (already wrong in English); gift_screen.gd:271 "grows"/"grow" by
`ends_with("s")`; first-letter upper-casing: icon_info.gd:194, :361-362, omen_director.gd:334, codex_data.gd:592,
combo_feedback.gd:432, family_pick_screen.gd:274, :829, :831; `.capitalize()` on shown text: coming_strip.gd:428 (a
verb phrase), and id fallbacks in ~25 places (dream_state.gd:2694, :3108, codex_panel.gd:2168, :2180 …).

**D. Code that reads, compares or edits on-screen text: 17** (breaks silently when translated; compare ids)
drift_panel.gd:366-368 `phone_short()` (`begins_with("Call drift ")`, `get_slice(" early, ")`);
hud.gd:2082 `.replace("Cost:", "Plant for")` + `begins_with("Sprout")`; dream_state.gd:6581 `trim_prefix("Now: ")`;
remember_screen.gd:1014 `== "Not enough Dreamlight"`; omen_screen.gd:505 `== "Reward gone" / "Reward lost"`;
rest_report.gd:244-250 `"Struggling"` + strength_ribbon.gd:14 colours keyed by the label; warden_header_view.gd:129,
:131 chips filtered by label `"Area"` / `shape_word`, :287 `begins_with("Covers ")`; warden_panel.gd:1132, :2183
`begins_with("Nurture")` (new); tower.gd:1689, :1797 `begins_with("Already")` (new); tower.gd:1504 `get_slice(" ", 2)`
on a stat line (new); rest_report.gd:472 `get_slice(" · ")` on a row's text (new); dew_popup.gd:40 `get_slice(" +")`
(new); combo_feedback.gd:744 `get_slice(":")` on card lines (new).

**E. Lists joined with English words: 22**
omen_director.gd:399-402 `_and()` (callers :295, :304, :306, :307, :387); dream_state.gd:2312, :4339, :4409, :4776,
:4778, :5541, :5632, :5641, :5647 (" or "); grove_screen.gd:593-594 ("One of: ", "%d of %s"), :661 (" or "), :666
(" and "); grove_card_list.gd:83; codex_panel.gd:595, :1193, :1769; combo_feedback.gd:694, :906, :915.

**F. Sentences built from fragments (translator sees half a sentence): 30**
boss_dossier.gd:669, :676-677; coming_strip.gd:564 (", something new"); omen_director.gd:355 ("Next Dream offers %d
cards%s%s"), :820; dream_screen.gd:303 ("Let it pass, %s"), :505 ("Grows with %s: %s"); dreams_row.gd:256, :298;
drift_banner.gd:243; drift_panel.gd:274, :520; hud.gd:2013 (a sentence inserted mid-paragraph); tower.gd:1428-1438
("…a second%s"); tower_placer.gd:469; warden_panel.gd:473, :1287, :1464 (+ " Moves the Tallest Tree here.");
kinships.gd:675 (article + possessive), :694 ("A %s within %d cells"), :859; buff_sources.gd:303 (name + signed
number + stat word); dream_reaction_cards.gd:200, :203, :205 (three unnamed `%d`: use named placeholders);
dream_hit_cards.gd:487; dream_state.gd:579, :3280 / :3286 ("Reroll · " + …); results_screen.gd:186; signatures.gd:230.

**G. Number formats**
`%.1f` decimal point in player text: shape_rows.gd:81, warden_header_view.gd:298, :545, :557, :594,
codex_panel.gd:2095, enemy.gd:2039; signed `+%d%%` order (dream_reaction_cards.gd:587, hud.gd:1941, many tooltips);
"×%.2f" (test_grove only, dev).

---

## 5. What already works
- "set off" is down from ~84 strings (round 2) to 8; "Let go", "Dream again", "New cards", "Hints", "Rime",
  "Hoar Fog" and "every second ring" are gone.
- Status adjectives are almost gone: "nightmares with {damp}" is the norm across 600+ texts.
- The Frost family reads cleanly through tokens (frostfern.d, hoarfrost.d, tidecaller.d, brittle.d, frostbite.d) and
  Cold Snap says "run down", the right replacement for "wear off".
- Crowned Reactions all open with "The nightmare …" and end "Triggered by …"; the base Reactions only need the same.
- Grove Ascension nodes lead with the effect and end with one fixed route line; Omens are short and plain.
- The splash rewrite landed on every Warden text ("the nightmare it hits"); only the evolution cards lag.
- Flashover's 2026-10-26 wording ("When a Warden {near} a Firefly Jar Warden hits 2 or more nightmares…") is clear
  apart from the `{jumps}` verb.

Flagged: 10 top problems + 102 table rows; about 820 avoid-list hits counted (§3.1); 27 words with two meanings;
21 unclear "it"; 6 status-adjective places; 26 token-verb uses; localisation list 7 groups, ~150 places.
