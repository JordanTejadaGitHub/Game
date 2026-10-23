# Scan reader: gap round (2026-10-23)

Seat: mid-fight, on a phone. Effect first? Fits? Button over 4 words? Action first? Vague words?
Corpus: corpus_resources.txt (Grove nodes, Crowned Reactions, drift templates), corpus_combat.txt (calling_paths.gd
skipped as told; callings.gd, buff_sources, kinships, support_log, gift_ground read), corpus_short.txt (short UI
strings; button texts checked against their source where a template builds them).
Counting rule: a token (nested too) = 1 word. Limits: card/node > 25, tooltip > 40, button > 4.

---

## 1. Top 10 problems, ranked

**1. Ascension nodes (9 Grove nodes): 34-51 words, the effect is last.**
Now (Great Bell, 51 words): "Unlocks {warden:great_bell}, the {family:bellflower} {family}'s strongest form. In a run: from {drift} 51, unlock it
for 3 {dreamlight}, then grow a {final_form} into it for 600 {dew}. Its toll puts every nightmare to sleep and
triggers the {static} of each nightmare with 4 or more: its bolt strikes for half damage."
Problem: 20 identical words of cost/route sit between the name and what the Warden does; all 9 Ascensions are over
25 (the 9 longest Grove texts). On a phone the effect is below the fold.
Rewrite (shape for all 8): effect sentence first, the fixed route as a short last line.
"Unlocks {warden:great_bell}, the {family:bellflower} {family}'s strongest form. Its toll puts every nightmare
{asleep} and triggers the bolt of each nightmare with 4 or more {static}, at half damage.
From {drift} 51: unlock for 3 {dreamlight}, grow a {final_form} into it for 600 {dew}."
(Same move for Grandmother Oak, Old Mountain, World Root, The Whirlwind, Dawnwing, Sporemother, Tidecaller,
Stormheart. Best: the last line as a fixed caption row under the node, not in the description.)

**2. Memory Warden nodes (3): effect last, 30-33 words.**
Now (Pond Keeper): "Grows the first time you dispel the Mire Hag. After that it can be your reward for dispelling that boss. Its
tongue pulls the nightmare furthest along the path back to its pond."
Problem: 18 words of unlock rule before the effect; "the nightmare furthest along the path" is "the leader" (rule 11).
Rewrite: "Its tongue pulls the leader back to its pond. Grows the first time you dispel the Mire Hag; after that, it can
be your reward for dispelling her." (Moon Moth, White Stag: same order.)

**3. Crowned Reactions: 9 of 10 over 25 words (avg 31.5), two trigger shapes.**
Now (Still Pool, 43): "It sinks, and a still pool stays on its cell for 5 s. Each nightmare entering the pool for the first time is pulled
under for 1 s (bosses are slowed 30% inside). Triggered by a {combo:drown} on a nightmare with {stacks:need_held}
{held}."
Problem: "It sinks" (it = the nightmare? does it die?); "pulled under" is not a token; bosses note in a long
parenthesis; 9 say "Triggered by…", Tempest says "Needs…" (rule 12 says "Needs").
Rewrite: "The nightmare sinks; a still pool stays on its cell for 5 s. Each nightmare entering it gets 1 {held} for 1 s,
once (bosses: slowed 30% inside). Needs {combo:drown} on a nightmare with {stacks:need_held} {held}." (check:
"pulled under" = {held}? does the sinking nightmare die?)

**4. Tempest (Crowned): explains instead of stating, raw combo names.**
Now: "Each arc triggers {combo:ignite} on nightmares with {spored}, and Ignite's spreading spores also spread {static}, so
more Thunderclaps follow. Needs 6 {spored} on a {combo:thunderclap}. Not again on the same nightmare for 2 s."
Problem: "so more Thunderclaps follow" is outcome advice; "Ignite's", "Thunderclaps" raw; limiter not in the fixed
form (rule 3); name also clashes with Warden id `tempest` (shown "The Whirlwind": fine for players, risky for
Codex search "Tempest").
Rewrite: "Each {combo:thunderclap} arc triggers {combo:ignite} on nightmares with {spored}, and that Ignite spreads
{static} too. Needs 6 {spored} on a {combo:thunderclap}. Each nightmare once every 2 s."

**5. Start button: "Face an Omen or Clear Skies" (6 words); phone short form drops the verb.**
Where: drift_panel.gd PENDING_TEXT / phone_short. Phone shows "Omen or Clear Skies": no action at all.
Rewrite: "Choose an Omen" on both (Clear Skies is one of the choices on that screen), phone the same. Also unify the three
Omen verbs: "Face an Omen" (screen head), "Choose the Omen" (title), "Choose an Omen" (button).

**6. Touch build: "Confirm (%d)" on phones vs "Plant %d" on PC.**
Where: touch_build.gd:164. "Confirm" is the vague word; the parenthesis breaks text_style.md ("no parenthetical
explanations on buttons").
Rewrite: "Plant 3" on both (the action, then the count).

**7. The Heartwood's Crown: "Every other {node} is Grown."**
Problem: "every other" reads as "every 2nd" (rule 4 bans it as 'every second'; same trap). Is it a requirement or a
reward?
Rewrite: "Grows once all other {nodes} are Grown. Adds a sixth {perk} slot: carry 6 {perks} into a run." (check:
requirement vs effect)

**8. Calling base texts (callings.gd): semicolons, double colons, a hand-holding tip.**
Bellflower now: "Each bell hit rings the nightmare; at 4 rings it is a {toll}: the hit lands again at half damage.
Nightmares start with 2 rings."
Rewrite: "Each bell hit adds a ring. The 4th ring is a {toll}: that hit lands again at half damage. Nightmares start
with 2 rings."
Sporeling tip: "Flyers pass over them, so it is weak against flyers." is strategy advice (owner's no-hand-holding
rule). Rewrite: "Flyers pass over them."
Tips are 45-55 words each (limit 40): Firefly, Sporeling, Dewdrop, Bellflower all over.

**9. "splash" means two things.**
Whirligig Calling: "pulses and splashes spread 1 cell wider" (splash attacks) vs {dew_splash}, whose name renders as
"splash" (owner 2026-10-20: "don't know what splash is on the card").
Rewrite: "…shots fly on to a second nightmare, and area attacks spread 1 cell wider." (check: pulses included in
"area attacks")

**10. Legendary-adder Grove nodes (16): a 14-word stock sentence with no effect.**
Now: "Adds the {legendary} {dream} card {card:last_leaf} to the cards your runs can offer."
Problem: "to the cards your runs can offer" is 7 padding words; regular adders give a one-clause effect
("Adds the {dream} card {card:burn_back}: clears every Withered Tree…"), legendary ones give none. Three shapes
for one job (also "Adds a {dream} card: {card:shared_light}." and "Adds a {dream} card for area attacks:
{card:spillover}.").
Rewrite: "Adds the {legendary} {dream} card {card:last_leaf}." (the link shows the card), or one clause after a colon
like the regular ones. One shape: "Adds the [{legendary}] {dream} card {card:X}[: one clause]."

---

## 2. Every other flagged string

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| grove/leaf_or_dew (28 w) | "…trade up to 3 {leaves} for 30 {dew} each, or pay 30 {dew} for each extra {leaf}. Your max {leaves} change with them." | Over 25; "change with them" vague | "While carried: before each run, trade {leaves} for {dew} or back, 30 {dew} each, up to 3. Your max {leaves} change to match." (check: cap on buying) |
| grove/bellflower (26 w) | "Song that gives nightmares {drowsy} until they fall asleep." | "fall asleep" raw; 1 over | "…Song that gives nightmares {drowsy} until they are {asleep}." |
| grove/second_thoughts | "+1 {dream} reroll per run per level, up to 3. Always: adds the {card:wandering_mind} card." | "Always:" reads as a keyword | "…up to 3. Also adds the {card:wandering_mind} card, carried or not." |
| grove/mixed_company, quickening | "it upgrades the start pool's {card:mixed_grove}, offered once you hold it." | "start pool" jargon; "it" twice, two things | "Adds {card:mixed_grove_ii}, an upgrade of {card:mixed_grove}. Offered only once you hold {card:mixed_grove}." |
| grove/wider_roots | "Adding another {branch} costs 4 {dreamlight}." | Reads as a new cost, not a change (check) | "…instead of 2. Each extra {branch} costs 4 {dreamlight}." (check old price) |
| grove/chosen_hunt | "choose its boss from three" | Numbers as digits | "…choose its boss from 3." |
| grove/old_mountain asc. | "Boulders crush and add 1 {held}, and always {crit} nightmares…" | "crush" says nothing | "Boulders add 1 {held} and always crit nightmares with {held} or {drowsy}." |
| grove/sporemother asc. | "A constant spore storm that pops nightmares like a {warden:puffball}." | "pops" vague; fragment | "A spore storm that never stops; it bursts on nightmares like a {warden:puffball}." (check mechanic) |
| grove/tidecaller asc. | "wash nightmares back" | Idiom; how far? | "Tides roll along the path and push nightmares back." (check distance) |
| grove/dewdrop_hidden | "they freeze nightmares with {damp}" | "freeze" not a token: {held}? | "…they add {held} to nightmares with {damp}." (check) |
| grove/memory_moon_moth | "Reveals every Lurker, and Wardens in range attack from further away." | Lurker is one kind; is it {kind_hidden}? "further away" = +range | "Reveals {kind_hidden} nightmares; Wardens in range get more range." (check) |
| grove/memory_white_stag | effect last | as #2 | "Nightmares in its range are slower and take more damage. Grows the first time…" |
| crowned/avalanche (39 w) | "(bosses: slowed only)" … "({warden:cairn}, {warden:rockslide})" | Two parentheses; "Triggered by" | "Scree covers the path under the stone for 4 s: nightmares on it are slowed 30% and gain 1 {held} every 0.5 s, up to 4. Bosses: slowed only. Needs a {combo:shatter} from a lobbed stone ({warden:cairn}, {warden:rockslide})." |
| crowned/changeling (30 w) | "the nightmare furthest along its path within 3 cells, then turns and walks back" | Rule 11; walks back how long? | "It trades places with the leader within 3 cells, then walks back [for N s]. Never bosses. Needs …" (check) |
| crowned/fairy_circle (32 w) | "gets 2 {spored} and {damp}" | Damp has no amount; "Triggered by" | "…gets 2 {spored} and 1 {damp}. Needs {combo:mushrooming} on a nightmare with {stacks:need_held} {held}." (check amount) |
| crowned/prismstorm | "each nightmare they hit with 8 {static}" | Reads "hit with 8 Static" | "…each nightmare they hit that has 8 {static} triggers its bolt at once." |
| crowned/starfall (31 w) | "Triggered by a {combo:pinned} hit…" | Shape | "Needs a {combo:pinned} hit on a nightmare with 8 {static}." |
| crowned/wide_awake (28 w) | "The scream startles your attacking Wardens: every attacking Warden within 3 cells…" | Flavour clause before effect; "attacking" twice | "Every attacking Warden within 3 cells attacks 40% faster for 3 s. Needs …" |
| crowned/fever_dream, nightbloom | "Triggered when / by…" | Shape | "Needs …" |
| callings.gd acorn | "Every 5th acorn, all Wardens next to the {warden:acorn} attack its target at once." | "acorn" = shot or Warden; "next to" vs {touching} | "Every 5th {warden:acorn} shot, all Wardens {touching} it attack its target at once." (check reach) |
| callings.gd rootling | "Every Warden in range turns to a nightmare with {held}" | "turns to" = becomes? range of what? | "Wardens in a {warden:rootling}'s range attack nightmares with {held} first, and add twice the status to them." (check) |
| callings.gd pebbling | "another kind of Warden" | kind/family? | "The next hit from a Warden of another family…" (check) |
| callings.gd firefly tip (52 w) | "Any dispel counts: by a hit, a {spored} tick or a cloud, but not by a {reaction}. Only this Calling…" | Over 40 | Split: Glow line + "Not {reaction} dispels." + family line; drop the list of what counts |
| callings.gd dewdrop tip (50 w) | Defines Touching, step, splash cap in one tip | Glossary work in a tip | Keep the splash cap and family line; {touching} and {step} already link |
| buff_sources.gd:65 | "{Kinship} %s (%s, %d%%)" | Parenthesis packs stage + % | "{Kinship} %s, %s: +%d%%" |
| buff_sources.gd:133 | "Cold lantern %s attack speed" | Lower-case name; what is it? | "Cold Lantern: %s attack speed" (check source name) |
| gift_ground.gd:134-138 | "Sheltered (Sow a Ridge)", "Moonwell (sees Hidden)", "Lookout (Fallen Giant)" | Three parenthesis jobs: source, effect, source | One form: "Sheltered: Sow a Ridge" / "Lookout: Fallen Giant" / "Moonwell: sees {kind_hidden}" |
| kinships.gd:675 | "No kin: the %s in range is bonded to its %s" | Fine on PC; ~10 words on a phone row | "No kin: that %s is bonded to its %s" |
| support_log.gd:179 | "Adds %d path tiles" | "tiles" is on the avoid list | "Adds %d {steps} of path" |
| support_log.gd:176 | "Added this run: %s damage (to %d Wardens)" | Parenthesis | "Added this run: %s damage to %d Wardens" |
| tower_seller.gd:1007 | "Rooted" (sell-mode tag) | "Rooted" is a banned raw word; reads as the {held} status (named Root) | "Can't sell" (check: tag width) |
| drift_panel.gd:256 | "Call drift %d early, +N Dew" | 5 words (PC); phone already "Call early, +N" | OK on phone; PC "Call drift %d early +N" or keep |
| family_pick_screen.gd:613 | "Wake Firefly Jar, Lantern Light" | 5 words (PC; longest family + Calling) | "Wake Firefly Jar" on the button, the Calling name on its card line (phones already do this) |
| family_pick_screen.gd:857 | "Dreams into, %d of %d this run" | Unreadable; third wording for growth ("Grows into" header, "Grow into" panel) | "Grows into: %d of %d offered" |
| boss_dossier.gd:141/419/595 | "Face it" / "Continue" / "Prepare" | One close button, three words; "Prepare" doesn't say what happens | "Face it" when the drift follows, "Continue" otherwise; drop "Prepare" (check when shown) |
| boss_dossier.gd:535 | "Hunt it" | Picks this boss; "Hunt" vs "Face it" next to it | "Choose" or keep "Hunt it" and make the close "Face it" only after a pick |
| grove_screen.gd:264 | "Carry" | Verb with no object | "Perks" or "Carry perks" |
| seed_picker.gd:110 | "Dream it" | Vague: starts a run with this seed | "Play seed" |
| remember_screen.gd:632/1114 | "Add, free" / "Unlock, free" | Comma reads like a list | "Add free" / "Unlock free" (or "Free" on the price chip) |
| results_screen.gd:228 | "Title" | Noun, no action | "To title" |
| results_screen.gd:202 | "Memory Grove" (button) vs demo "Plant your Seeds" | Two buttons for one job; noun vs verb | "Plant your Seeds" in both builds |
| drift_panel.gd:91 | "Sapling" | Noun; tooltip carries the action (no tooltip on phones) | "Plant Sapling" (check width) |
| drift_panel.gd:134/144 | "Auto" / "Auto on" | "Auto" what? | "Auto drift" / "Auto drift on" (check width) |
| clear_tool_button.gd:40 vs gift_screen.gd:186 | "Clear" (clear obstacles) / "Clear" (reset placement) | One word, two jobs | Gift screen: "Reset" (Undo is beside it) |
| rest_report.gd:354 | "Top support" / "Best supporter" | Same row, two wordings by period | "Top support" both |
| blight_picker.gd:47 | "Blight Level" | Title case on a heading (sentence case rule) | "Blight level" |
| dream_screen.gd:514 | stage "Style" | Says nothing about drift 10 stage (check) | "Start" or "First step" (check with Wording Council 2c) |
| warden_panel.gd:1395 | "Choose as Tallest" | OK length; "Tallest" capitalised mid-label, glossary? | "Make it the Tallest" or keep with {tallest} link |
| codex_panel.gd:1052 | "Formed %d time%s" | Plural built in code (localisation) | Two strings, or "Formed: %d" |
| gift_screen.gd:271 | "The %s grows" / "grow" by ends_with("s") | Grammar in code (localisation) | "%s: growing" or per-gift string |
| drift templates | "Special", "Heavy", "Mixed" | "Special" vague; "Heavy" = Warden role tag; "Mixed" = target-mode chip | "Special" → name what it is; "Heavy" → "Tough" or "Brutes" (check where shown) |
| hud.gd:1272 | "Rest · %s" | " · " in a label the style guide removes elsewhere | "Rest +30 Dew" form, like "Call early, +N" |

## 3. Patterns and rules

- **Fixed rule text before the effect** (Ascensions, Memory Wardens): put the effect first; the unlock route is a
  fixed last line or a caption row.
- **Crowned Reactions use "Triggered by"**: switch to rule 12's "Needs …" last, like normal Reactions; cap at 30 words.
- **Boss notes in five forms** ("(bosses: slowed only)", "Never bosses.", "(bosses are slowed 30% inside)", "Bosses
  take half."): rule 9 "(bosses N)" after the number, or "Never bosses." as its own sentence.
- **Raw state words** ("fall asleep", "to sleep", "freeze", "pulled under", "Rooted"): use the token or the glossary
  name.
- **One button, several words** (boss dossier close; Omen verbs; Clear; growth "Grows/Grow/Dreams into"): one
  word per job.
- **Noun-only buttons** (Carry, Sapling, Auto, Title, Memory Grove on results): verb first where it's an action;
  menu entries on the title screen can stay nouns.
- **Parentheses on buttons and log rows** ("Confirm (3)", "(to N Wardens)", gift row sources): a colon or nothing.
- **Phone short forms must keep the verb**: phone_short() should shorten the object, never drop the action.
- **Stock adder sentence** on 16 Legendary nodes: cut "to the cards your runs can offer".

## 4. What already works

- Perk nodes: "While carried: …" first, one number, "per level, up to +N" (Morning Stores, Rich Dew, Rested Roots,
  Deep Taproot): model shape, all under 15 words.
- Slot nodes: "Adds a fourth {perk} slot: carry 4 {perks} into a run."
- Family nodes: one noun phrase of what the family does ("Water that gives nightmares {damp}.").
- Short UI is mostly clean: no "OK", only one literal button over 4 words; "Got it", "Keep my run", "Start new run",
  "Apply and close", "Copy run report"/"Copied", "Skip lessons" are all clear. Phone shortening (phone_short) already
  exists and works for "Call early, +N" and "Rest after N".
- Callings' Dewdrop and Firefly texts lead with the rule and keep one number each.

## 5. Length stats

| Text kind | Count | Over limit | Average words |
|---|---|---|---|
| Grove node descriptions | 95 | **14 over 25** | 17.1 |
| · Ascension nodes | 9 | 9 over 25 (34-51) | |
| · Memory Warden nodes | 3 | 3 over 25 (30-33) | |
| · others | 83 | 2 over 25 (Leaf or Dew 28, Bellflower family 26); 8 at 21-25 | |
| Crowned Reactions | 10 | **9 over 25** (Nightbloom is 25) | 31.5 |
| Calling texts (callings.gd) | 9 | ~4 at 25-27 (Firefly, Dewdrop, Bellflower, Pebbling) | |
| Calling tips | 4 | 4 over 40 (45-55) | |
| Buttons (literal) | ~110 | **1 over 4** ("Face an Omen or Clear Skies", 6) | |
| Buttons (templated, worst case) | | **2 over 4**: "Call drift N early, +N Dew" (5, PC only), "Wake Firefly Jar, Lantern Light" (5, PC only) | |

Longest Grove texts: Great Bell 51 · Grandmother Oak 42 · Old Mountain 41 · World Root 41 · The Whirlwind 39 ·
Dawnwing 38 · Sporemother 37 · Tidecaller 36 · Stormheart 34 · Pond Keeper 33.
Longest Crowned: Still Pool 43 · Avalanche 39 · Tempest 34 · Fairy Circle 32 · Starfall 31 · Changeling 30 ·
Wide Awake 28 · Fever Dream 27 · Prismstorm 26 · Nightbloom 25.
(Ascension count 9 includes the shared shape; the 14 Grove nodes over 25 = 9 Ascensions + 3 Memory Wardens + 2.)
