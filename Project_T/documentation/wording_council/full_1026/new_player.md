# Wording Council 2026-10-26 (full round): new player seat

Seat: a few mobile games played, never a tower defence or a roguelite. Test: after one read (about 5 s), do I know
what happens, to what, when, and how much?

Read: corpus_resources.txt, corpus_ui.txt, corpus_short.txt, icon_info.gd (dictionaries), wording_council_review.md
(sections 3, 5, 6 and every round's decisions). Ranking is by how often a first-time player meets the text: the first
screens (family pick, Lessons, HUD), the four starting families (Sporeling, Firefly Jar, Dewdrop, Bellflower), their
Callings, their statuses and first Reactions, and the common Dream cards (rarity 0 in resource/dream/). Late content
(Ascended forms, Legendaries, deep Calling rows) is ranked lower. Code checks are marked "checked"; "(check)" means
I could not confirm the mechanic.

---

## 1. Top 25 problems, ranked

### 1. Family pick: "Dreams into" and "Sprout into it" (the very first screen of every run)
- **Where:** `family_pick_screen.gd:741` / `:859` OFFER_LINE "Dreams into, %d of %d this run"; `:598` cost row
  "Sprout into it [Dew] 15 · Plant [Dew] 25"; `:860` OFFER_TIP "…Add one on the Remember screen for %s, once per family."
- **Problem:** "Dreams into" is not English to a newcomer (it means "can grow into"). "Sprout into it" reads as a verb I
  don't know. The tip sends me to a Remember screen I haven't seen yet. This is the first thing every run asks me to read.
- **Rewrite:** heading "Can grow into (%d of %d this run)"; costs "Grow a Sprout into it [Dew] 15 · Plant it [Dew] 25";
  tip "Only these branches can appear this run. Later you can add one more with Dreamlight (once per family)."

### 2. Bellflower: "ring" and "pulse" mean different things on its first three texts
- **Where:** `tower/bellflower.tres` "Rings out, damaging every nightmare in range. Every 2nd ring on a nightmare gives
  it {drowsy}."; `callings.gd:20` "Each bell hit rings the nightmare; at 4 rings it is a {toll}… Nightmares start with 2
  rings."; `dream/dream_bellflower.tres` "A soft ringing pulse; one pulse in {field:bellflower.status_every} gives the
  nightmares around it {drowsy}."
- **Problem:** the Warden's "ring" is its attack; the Calling's "ring" is a counter on the nightmare, and nightmares
  "start with 2". So does "every 2nd ring" mean every 2nd attack or the Calling's count? The card calls the same attack a
  "pulse", says "one pulse in 2" (rule 4 wants "every 2nd") and "around it" where the Warden says "in range". How much
  {drowsy} is never said.
- **Rewrite:** Warden: "It hits every nightmare in range at once. Every 2nd of its hits on a nightmare gives it 1
  {drowsy}." (check the stack count). Card: "Sprouts can now {grow} into {warden:bellflower}s (…), or plant one directly
  (…). It hits every nightmare in range at once; every 2nd hit on a nightmare gives it {drowsy}." Calling: see 13.

### 3. Drowsy promises sleep that the starting Bellflower never gives
- **Where:** `icon_info.gd:20` "At {stacks:cap_drowsy} stacks … the nightmare can fall {asleep} and trigger
  {reactions}."; `lesson_card.gd:221` same; `dream_keywords.gd:61` "the nightmare slows, and falls {asleep} at {full}.";
  `codex_data.gd:605` "At {full} {drowsy}, the nightmare falls {asleep} for a moment"; `codex_data.gd:121` "At {full}
  {drowsy}, a nightmare triggers one Reaction: Drown, then Night Terror…".
- **Problem (checked):** only Dreamshroom (`sleep_at_max_drowsy`, `tower.gd:3997-4007`) and Undiluted put a nightmare to
  sleep at full {drowsy}. A Bellflower player fills {drowsy}, waits, and nothing sleeps. "can fall" hides that. The Codex
  line reads as if full {drowsy} alone triggers a Reaction; every one listed needs a second status.
- **Rewrite:** tooltip "A nightmare with it walks 2% slower per stack, up to {stacks:cap_drowsy} ({stacks:bosscap_drowsy}
  on bosses). Full {drowsy} doesn't make it sleep by itself: some Wardens and {reactions} do. At {full} it can trigger
  {reactions} with a second status." Keyword: "{drowsy}: the nightmare slows; some Wardens put it {asleep} at {full}."
  Codex 121: "At {full} {drowsy} with a partner status, a nightmare triggers one Reaction: Drown first, then Night Terror,
  Sleepwalk, Pinned…".

### 4. Charge: three explanations of one bolt, none with a number I can see
- **Where:** `icon_info.gd:23` "it releases a strong bolt (16× the stored Charge)"; `lesson_card.gd:224` "it is struck
  by a bolt for heavy damage. Other statuses can set it off early as a {reaction}."; `firefly_jar.tres` "the {static}
  strikes it as a bolt for heavy damage"; `tower.gd:1431` "{static} bolts deal ×N its hit".
- **Problem (checked):** the bolt is the Warden's Charge potency ×16 (`enemy_statuses.gd:47, :439`). "The stored Charge"
  is not a number shown anywhere, so "16×" means nothing. The lesson says "set it off" (avoid list) and "heavy" (a
  glossary word, see 5). Firefly Jar is a starting family; this is the first status many players read.
- **Rewrite:** tooltip "Lightning builds up on a nightmare. At {stacks:cap_static} stacks ({stacks:bosscap_static} on
  bosses) it strikes the nightmare as one big bolt and the {static} is used up. At {stacks:need_static} stacks it can
  trigger {reactions}." (the ×16 belongs on the Warden panel's Potency line, which already says it). Lesson: "At
  {stacks:cap_static} stacks … a bolt strikes it for big damage. A {reaction} can use the {static} before that."
  Firefly Jar: "…the {static} strikes it as a bolt for big damage."

### 5. "heavy" is a glossary word and also plain English
- **Where:** {heavy} = "Heavy Warden" (`codex_data.gd:90`; role tag "Heavy"; common Hammerfall "When a {heavy} Warden or
  Sprout…", Thunderstruck, Millstone, Starlit Aim). Plain "heavy": Firefly Jar "heavy damage", Charge lesson, Shatter
  "A crit or heavy hit on it deals ×4", Exposed Blow (`codex_data.gd:183`) "A heavy hit does double damage", Dread shell
  (`:111`) "heavy hits mostly do", Lightning Tree gift "for heavy damage", Pebbling "A slow, heavy pebble".
- **Problem:** I learn "Heavy" as a tag, then read "a heavy hit" on Shatter and don't know whether a Heavy Warden is
  needed. Two careful readers play Shatter differently.
- **Rewrite:** plain uses become "big": "for big damage", "big hits mostly get through", "A big hit does double damage".
  Shatter: say which it is: "A crit, or a hit from a {heavy} Warden, deals ×4…" or "a hit of 10%+ of its health" (check).

### 6. Dewdrop: the Calling "splashes" soak everything, the Warden's splash soaks one
- **Where:** `dewdrop.tres` "A small splash that hurts every nightmare within … cells; the nightmare it hits gains
  {damp}."; `callings.gd:19` "A Dewdrop's hit there {dew_splashes}: nightmares within 4 {steps} in that {water} gain
  {damp}."; `dream_dewdrop.tres` "Its splash hurts nearby nightmares; only the one hit gains {damp}."
- **Problem:** on the same family pick card I read "only the one hit gains Soak" and "the splash: nightmares within 4
  steps gain Soak". They read as a contradiction; the token is a different glossary entry but shows the same word.
  "only the one hit" also breaks F.3 ("the nightmare it hits").
- **Rewrite:** Calling: "The path {touching} your Dewdrops is {water}. When a Dewdrop hits a nightmare in {water}, the
  {water} ripples: nightmares within 4 {steps} in it gain {damp}." Owner call: show the {dew_splash} token as
  **"ripple"** (glossary "Dewdrop ripple"), so "splash" means one thing. Card: "…Its splash hurts nearby nightmares; the
  nightmare it hits gains {damp}."

### 7. Warden panel: bare "Rank", and "grow past rank V"
- **Where:** `warden_panel.gd:269` "Rank %s · Eldest"; `:443` "Make this the Eldest? Only one Warden can grow past rank
  V"; `:458` "Choose what rank %s adds"; `:461` "Nurture Rank %s"; `:469` "Nurture to rank %s"; `:473` "Rank %s: …";
  `:494` "Only the Eldest grows past rank %s."; `:648`, `:654`, `:662`, `:2608`; toast `:1278` "Top rank";
  `lesson_card.gd:431-432` "Each rank lets you choose one improvement"; `:667` RANK_TEXT "At rank V a Warden earns a mark.
  Four ranks of the same choice…".
- **Problem:** Grow vs Nurture rule (2026-10-25): "grow" = forms only, "Nurture {rank}" every time. The first Nurture
  (taught in the first minutes) still shows "Rank II" and "grow past rank V", the exact mix-up the rule was made for.
  "earns a mark" names nothing I can find.
- **Rewrite:** "Nurture rank %s · Eldest"; "Make this the Eldest? Only one Warden can be nurtured past Nurture rank V";
  "Nurture rank %s" (button, small r); "Nurture to Nurture rank %s" or "Nurture: rank %s"; "Only the Eldest goes past
  Nurture rank %s."; toast "Highest Nurture rank"; lesson "Each Nurture rank lets you choose one improvement"; RANK_TEXT
  "At Nurture rank V a Warden gets a reward: four Nurture ranks of the same choice give a signature, a special rule. Any
  other mix gives All-Rounder: 20% better at what it does."

### 8. Thunderclap (the Codex's own example Reaction): "×12" of what, "in range" of what
- **Where:** `reaction/thunderclap.tres` "A Thunderclap hits it hard and arcs to nightmares with {damp} in range. Needs
  … ×12 damage, ×6 per arc, and each arc adds 1 {static}."
- **Problem:** Dewdrop + Firefly Jar are both starters, so this is the first Reaction many players see. "hits it hard"
  and "×12" say the same thing twice; ×12 has no base (rule 5); "in range" has no owner (the arc reach is 2.5 cells,
  per Rolling Thunder "3.5 cells instead of 2.5"); the numbers come after "Needs".
- **Rewrite:** "It takes ×12 the damage of the Warden that triggered it, and lightning arcs to every nightmare with
  {damp} within 2.5 cells for ×6, adding 1 {static} to each. Needs {stacks:need_damp} {damp} + {stacks:clap_static}
  {static} ({stacks:bossclap_static} on bosses)." (check the ×12 base.)

### 9. Nod Off tip has a grammar error (common Bellflower card)
- **Where:** `dream/nod_off.tres` tip "{family:bellflower} Wardens that add no {drowsy}, like {warden:chime_stone},
  {warden:hushbell} and {warden:dreamcatcher}s, don't triggered it."; face "Each {family:bellflower} Warden keeps one
  sleeper at a time."
- **Problem:** "don't triggered it" is broken English on a starting-family common. "keeps one sleeper" is a riddle;
  "{warden:dreamcatcher}s" glues "s" onto a token (G.2).
- **Rewrite:** tip "…like {warden:chime_stone}, {warden:hushbell} and {warden:dreamcatcher}, don't trigger it." Face:
  "Each {family:bellflower} Warden can keep only one nightmare {asleep} this way at a time."

### 10. Firefly cards cap a jump at "3 s of that Warden's damage"
- **Where:** tips of Flashover, Hammerfall, Sparks Fly (commons), Chain of Lanterns, Brushfire, Nothing Wasted ("At most 3
  s of that {family:firefly_jar} Warden's damage"), Thunderstruck ("At most 1.5 s … in all").
- **Problem:** "3 s of damage" is not something I can picture: is it a duration, a delay, a cap? It sits on every Firefly
  card in the start pool.
- **Rewrite:** "A {jump} deals at most what that {family:firefly_jar} Warden deals in 3 s." Add it once to the Codex
  "Jump" entry.

### 11. Bearing Down (common): no Nurture rank, no bonus, and it doesn't say so
- **Where:** `dream/bearing_down.tres` "…deal 4% more damage for each attack in a row on one nightmare, up to +10% per
  Nurture {rank}."
- **Problem (checked):** `dream_hit_cards.gd:133` caps the bonus at 10% × the Warden's rank, so a Warden I haven't
  nurtured gets 0. Early in a run that is every Warden, and "per Nurture rank" reads as "per level of the card".
- **Rewrite:** "…up to +10% for each Nurture {rank} the Warden has. Without a Nurture {rank}: no bonus."

### 12. "pulse" is used everywhere and defined nowhere; "Hush" sounds like Silence
- **Where:** Hush (common) "Pulsing {family:bellflower} Wardens get 50% more range."; Wide Petals (common) "Pulses and
  clouds are 0.75 cells wider."; Great Ripple "Every pulse and splash…"; Chime Stone / Lullaby Bell cards "pulse"; only
  the Splash entry (`codex_data.gd:136`) says "A pulse hits everything in the Warden's range instead". Warden texts say
  "Rings out" (Bellflower), "It damages every nightmare in range" (Rootling family), "Pulses damage…" (Acorn family).
- **Problem:** I can't tell which of my Wardens "pulse", so I can't judge Wide Petals or Hush. Hush is also the word the
  game uses for silencing (Hushbell, Silence "A wider hush"), so I expect it to silence.
- **Rewrite:** Codex entry "Pulse: an attack that hits every nightmare in the Warden's range at once." Warden texts that
  pulse open the same way: "Pulses: hits every nightmare in range…". Owner call: rename the card Hush (e.g. "Carrying
  Peal") so the hush words mean silence only.

### 13. Calling faces lean on words defined only in their small print
- **Where:** `callings.gd:18` Firefly "Nightmares in a Firefly's glow are {lit}…" (glow is defined only in `:30`);
  `callings.gd:20` Bellflower "Each bell hit rings the nightmare; at 4 rings it is a {toll}: the hit lands again at half
  damage. Nightmares start with 2 rings."
- **Problem:** the Calling is "the bigger stake" on the family pick card. "a Firefly's glow" has no size; "it is a
  Toll" makes the nightmare the Toll; "start with 2 rings" doesn't say when (on entering? after each Toll? the tip says
  rings go back to 0).
- **Rewrite:** Firefly: "The path within 1.5 cells of a Firefly is its glow; nightmares there are {lit}. When any Warden
  dispels a {lit} nightmare, half that hit {jumps} to the nearest other {lit} nightmare." Bellflower: "Each bell hit adds
  a ring to the nightmare. Its 4th ring is a {toll}: that hit lands again at half damage. Nightmares arrive with 2 rings
  already." (check "arrive").

### 14. Clearing: three verbs, and "for Dew" reads as a reward
- **Where:** `clear_tool_button.gd:11` "Clearing needs a Dream. Take a clearing card to tend the forest.";
  `dream_state.gd:2777` "Tend Withered Trees and move Mossy Boulders for Dew (Clear tool, C)."; obstacle clear_verb
  "Tend" / "Move" / "Clear"; `hud.gd:256` "tending a tree or moving a rock costs half"; `meta_run.gd:24` "Tend 120
  obstacles"; gift "each counts as tended".
- **Problem:** obstacles are on every first map and the Clear button is visible from drift 1. Clear, tend and move are
  one action; "for Dew" reads as "you earn Dew" when it costs Dew (gifts that *pay* Dew make it worse).
- **Rewrite:** rules and tips say **clear**: "Clearing needs a Dream: take a card that unlocks clearing."; "Clear
  Withered Trees and Mossy Boulders for a Dew price (Clear tool, C)."; "Half-price clears: clearing an obstacle costs
  half…"; milestone "Clear 120 obstacles". The per-obstacle button verbs may stay as flavour.

### 15. The Flyers lesson is wrong for path flyers
- **Where:** `lesson_card.gd:438` "Flyers ignore your maze and go straight for the Heartwood. Keep attacking Wardens near
  it, and check which nightmares are coming before each block."
- **Problem:** Crow, Night Kite, Gloamwing and Pall "fly along the path above your walls" (their traits;
  `flyer_warning.gd:14` ROUTE_LINE already says so). The lesson teaches one rule for both kinds.
- **Rewrite:** "Flyers pass over your walls. Some fly straight to the Heartwood; others follow the path in the air. Each
  nightmare's card says which. Check what's coming before each block."

### 16. Sparks Fly (common): the trigger is in the middle of the sentence
- **Where:** `dream/sparks_fly.tres` "After a {family:firefly_jar} Warden hits a nightmare, every 3rd hit another Warden
  lands on it within 2 s {jumps} half to the nearest other nightmare."
- **Problem:** I read it three times: who hits, which hit jumps, half of what.
- **Rewrite:** "For 2 s after a {family:firefly_jar} Warden hits a nightmare, every 3rd hit another Warden lands on it
  also {jumps}: half its damage goes to the nearest other nightmare."

### 17. In Time (common): the subject is buried
- **Where:** `dream/in_time.tres` "Every 5th hit a Warden {touching} a {family:bellflower} Warden makes on the same
  nightmare lands again 0.25 s later."
- **Rewrite:** "A Warden {touching} a {family:bellflower} Warden repeats every 5th hit it lands on the same nightmare,
  0.25 s later."

### 18. On the Beat (common): "Each once every 3 s"
- **Where:** `dream/on_the_beat.tres` "…each Warden {touching} it hits that nightmare again for its own damage. Each
  once every 3 s."
- **Problem:** each what: each Warden, each bell, each nightmare?
- **Rewrite:** "…Each Warden once every 3 s." (check which the code limits.)

### 19. Topped Up (common): "its starting time"
- **Where:** `dream/topped_up.tres` "A {family:dewdrop} Warden's hit resets every status on the nightmare to its
  starting time." Tip "Never longer than when it landed, and at most 4 s extra in all…"
- **Problem:** "starting time" reads as "back to zero", the opposite of what it does.
- **Rewrite:** "A {family:dewdrop} Warden's hit refills the time on every status on the nightmare, as if it had just
  landed. Each nightmare once a second." Tip: "Never more than its full time, and at most 4 s extra in all ({static} 2
  s)…"

### 20. Touching, Near, Cell: "on both sides" and "small squares"
- **Where:** `codex_data.gd:92` Touching "Within 1 cell on both sides: the 8 cells around a Warden…"; `:93` Near "Within 2
  cells on both sides…"; `:94` Cell "2×2 of the small squares you place on"; `distance_diagram.gd:10` same.
- **Problem:** {touching} and {near} are on most common cards (Close Quarters, Fruiting, High Tide, Pass It Round, Heavy
  Going, Sodden…), so this is the glossary I open most. "On both sides" makes me think of the path's two sides. "Small
  squares" is a second grid unit nobody names.
- **Rewrite:** Touching: "In one of the 8 cells around a Warden. A Warden touches the path within 1.25 cells of its
  middle; two nightmares touch within 1 cell." Near: "Within 2 cells in every direction: the dashed square shown while
  you plant." Cell: "The space one Warden takes up. The build grid shows half cells: a Warden covers 2×2 of them."

### 21. Straightaway's diagram promises damage the card no longer gives (wrong text)
- **Where:** `dream/straightaway.tres` diagram_caption "Beside a straight stretch of 5 or more path cells: +30% and +0.5
  range."; description "+0.5 range".
- **Checked:** `dream_state.gd:190` STRAIGHTAWAY [[0.0, 0.5], …], "range only since 2026-10-23".
- **Rewrite:** "Beside a straight stretch of 5 or more path cells: +0.5 range."

### 22. Reroll and Banish tips: a fixed card count and an old name
- **Where:** `dream_state.gd:3283` "Shows three new cards. Rerolls don't refill…"; `:3289` "…More come from Let Go
  (Memory Grove)."
- **Problem:** offers can be 4 or 5 cards (Lucid Dreaming, Omen rewards, MAX_OFFER_CARDS 5: check that a reroll keeps
  the count). "Let Go" was renamed Banish (G.2, section 6).
- **Rewrite:** "Swaps every card on offer for new ones. Rerolls don't refill…"; "…More come from the Banish node (Memory
  Grove)." (use the node's current name.)

### 23. "Let it pass" vs "Skip"
- **Where:** `dream_screen.gd:303` "Let it pass, +30"; Codex "Let it pass" entry and the Dream entry's link; Waking Dreams
  cost "you can't let it pass"; Gifts "Skip the gifts, +60"; Omens "Skip the Omen".
- **Problem:** three screens, two verbs for one action. "Let it pass" is an idiom; "can't let it pass" (Waking Dreams)
  reads as "can't let it go by", i.e. must react. Round 1 flagged the cost line; it is still not plain.
- **Rewrite (owner call):** "Skip, +30" on the Dream screen and Codex entry "Skip"; Waking Dreams "For the rest of the
  run, every Dream shows only 2 cards and can't be skipped." If "Let it pass" stays, at least fix Waking Dreams.

### 24. Restless lesson: "Re-routing"
- **Where:** `lesson_card.gd:172` "Re-routing nightmares mid-walk makes them restless: they speed up. Keep doing it and
  they ignore the new path."
- **Problem:** "route" is on the avoid list, and the lesson doesn't say what I did (I planted a Warden that changed the
  path). No numbers, though the Codex has them.
- **Rewrite:** "Changing the path while nightmares walk it makes them restless: each change makes them 20% faster. After
  3 changes they ignore your maze and trample Wardens in their way."

### 25. Kinship commons name stages and limits without the base
- **Where:** Old Friends (common) "New {kinships} start at Blooming, and {kinships} reach each later stage 1 {drift}
  sooner."; Close Kin (common) "{kinships} reach 3 cells."
- **Problem:** these are offered from the first Dream, before I've seen a Kinship. "Blooming" is plain text (no token,
  no link), and "reach 3 cells" doesn't say from what.
- **Rewrite:** Old Friends: "New {kinships} start Blooming (as if 5 {drifts} old), and each later stage comes 1 {drift}
  sooner." Close Kin: "{kinships} form within 3 cells instead of 2." (Add a token for Blooming / Old Kin linking to the
  existing Codex entry.)

---

## 2. Every other flagged string

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| `dream_sporeling.tres` (family card) | "Nightmares with {spored} take damage over time." | Doesn't say the Sporeling gives it. | "It gives nightmares {spored}: damage every second." |
| `dream_firefly_jar.tres` | "Sparks build {static} for free bolts." | "free" bolts? | "Its sparks build {static}; at {full} it strikes as a bolt." |
| `dream_cloudlet.tres` | "rain clouds over any spot in range, flyers too." | Doesn't say what the rain does. | "…rain clouds that give {damp} to everything under them, flyers too." |
| `dream_jetreed.tres` | "an erosion jet that wears down a share of its target's max health." | Raw "erosion"; no number. | "…a jet of {erosion}: each hit also takes {field:jetreed.special_params.erosion:pct} of the target's max health." |
| `dream_lichenling.tres` | "crusted spores that strip {dread_shells} and stop mending." | "stop mending" whom? | "…spores that wear {dread_shells} away; nightmares with its {spored} can't heal." |
| `dream_whetstone.tres` | "the finisher, its hits on worn-down nightmares land far harder." | No threshold or number. | "…its hits on nightmares below 30% health deal ×2.5 damage (×1.5 on bosses)." |
| `dream_windmill.tres` | "bigger, faster blades; loves bends." | Hides the mechanic. | "…bigger, faster blades: +35% damage for each path cell past 2 among the 8 around it." |
| `dream_quaker.tres` | "a slam that stops sprints." | "sprint" undefined. | "…a slam that stops sprinting nightmares." |
| `dream_magpie_perch.tres`, `magpie_perch.tres` | "steals a boost from its target" | A nightmare's boost is never explained. | "…removes one of its target's boosts (a shell chip, healing, an Omen boost)." (check list) |
| `dream_rain_lily.tres`, `dream_hoarfrost.tres`, `dream_old_mountain.tres` | "the nightmare hit gains", "to the nightmare hit", "the one hit gains" | F.3 rule. | "the nightmare it hits gains …" |
| `dream_lanternmoth.tres` | "at {full} {stacks} the nightmare takes more damage." | No number; the Warden says 25%. | "…takes 25% more damage from every Warden." |
| `boulderback.tres`, `mossback.tres`, `dream_mossback.tres`, `dream_boulderback.tres` | "nightmares with full {marked}" | Raw "full". | "nightmares with {full} {marked}" |
| `stormcap.tres` "chains to 4", `thunderhead.tres` "Chains to 4", role lines "Chains" | | {chain} is the Reaction chain (F.2: "never chain"). | "Lightning that {jumps} to 4 nightmares…"; role word "Jumps". |
| Nestling, Wren's Nest, Starling, Lightning Fence cards | "extra damage to Phantoms" | Raw name, not a link. | "{nightmare:dandelion_seed}s" |
| `reaction/mushrooming.tres` | "take 30% more effect damage" | Ruling 7: "status damage". | "take 30% more status damage (statuses, bolts and most {reactions})" |
| `reaction/pinned.tres` | "and the {drowsy} when that set it off." | Avoid list. | "and the {drowsy} when the {drowsy} triggered it." |
| `reaction/drown.tres` | "…Uses up the {drowsy}. 60% slower while under (bosses 30%)." | Effect split by the "Needs" line. | "It is pulled under for 3 s: 60% slower (bosses 30%) and takes more damage each second. Needs … Uses up the {drowsy}." |
| `reaction/shatter.tres` | "ice shards fly into the nightmares beside it" | "ice" with Frost now a status (doesn't slow). | "shards hit the nightmares {touching} it" |
| `hedgehog.tres` (Night Hound) hint | "Even a short straight sets it off" | Avoid list; "a straight" (noun). | "Even a short straight stretch starts its sprint: keep the path turning." |
| `dawnbreak.tres` tip | "Each nightmare sets one off at most once every 3 s." | Avoid list. | "Each nightmare triggers one at most once every 3 s." |
| `codex_data.gd:39` Chain | "Reactions setting each other off within a second." | Avoid list. | "Reactions triggering each other within a second." |
| `dream_keywords.gd:65` Frost | "at {full}, it bursts and chills the nightmares beside it." | "chills" reads as a slow; Frost doesn't slow (F.1). | "at {full}, it bursts, hurting the nightmares beside it." |
| `dream_keywords.gd:47` Slows | "slowed, stopped or pulled back: {held}, {asleep}, {caught}." | {caught} doesn't slow. | drop {caught} |
| `dream_keywords.gd:52` Ranks | "Nurture {ranks}: higher-rank Wardens." | Bare rank. | "Wardens with higher Nurture {ranks}." |
| `dream_batch_rules.gd:267` (Quiet Rings live line) | "no free rank at the next rest" / "a free rank at the next rest" | N1. | "…a free Nurture rank at the next rest" |
| `dream_state.gd:4339`, `dream_effects.gd:820` (Sunlit Rest) | "a free rank waits on %s", "Next Sunlit Rest rank" | N1. | "a free Nurture rank waits on %s"; "Next Sunlit Rest Nurture rank" |
| `signatures.gd:38-39`, `codex_data.gd:58-59` | "Mixed ranks", "Four ranks of the same choice", "The rank V reward for four matching ranks" | N1. | "Mixed Nurture ranks…", "Four Nurture ranks of the same choice…", "The Nurture rank V reward…" |
| `family_pick_screen.gd:447` (Sapling) | "+%d per rank" | N1. | "+%d per Nurture rank" |
| `heartwood_gifts.gd:61, :81`; gift_screen.gd:56, :70 | "2 free {ranks}", "keeps its {ranks}", "rank II", "2 free ranks" | N1. | "2 free Nurture {ranks}", "keeps its Nurture {ranks}", "Nurture rank II" |
| `heartwoods_reach.tres` tip | "a Sprout keeps its rank when it grows" | N1. | "a Sprout keeps its Nurture {rank} when it grows" |
| `dream_screen.gd:307` | "Your Calling grows" | "grow" = forms only (N1). | "Your Calling deepens" / "Your Calling evolves" (owner pick) |
| `tower.gd:1771`; `codex_data.gd:304` (Nursery Bond) | "Wardens in its range grow 10% cheaper", "also grow 10% cheaper" | grow vs Nurture: which price? | "…pay 10% less to Nurture" or "…to grow" (check which) |
| `heartwood_gifts.gd:67, :79, :41`; `codex_data.gd:66` | "The strike grows…", "their bond grows one step", "It grows at each later {act} break.", "bond and grow stronger" | N1: non-form "grow". | "gets stronger", "moves up one stage", "It gets stronger at each later {act} break." |
| `sunpetal.tres` | "A beam that grows stronger…" | N1. | "A beam that gets stronger…" |
| `momentum.tres` tip; `quickening_ii.tres` tip; `wild_growth.tres` tip | "a kill never drops it", "kills keep coming", "where nightmares die" | Rule 17: dispel. | "a dispel never drops it", "dispels keep coming", drop "A bet: where nightmares die" or "where nightmares are dispelled" |
| `longer_roots.tres` diagram | "The dim Warden touches the route" | Avoid list. | "touches the path" |
| `sprout_chorus.tres` (Thicket) diagram | "W touches at least 2 distinct path cells" | "W" is a letter on the picture; "distinct". | "This Sprout touches 2 or more path cells: +20% attack speed." |
| `rest_report.gd:284` | "Worst 10%%: %d%% along the route" | Avoid list; unreadable stat. | "The furthest 10% got %d%% of the way" (check meaning) |
| `calling_paths.gd:35, :39` and others | "starts its route again" | Avoid list. | "starts the path again" |
| `rude_awakening.tres` tip | "Each {family:bellflower} Warden once a second." | Card isn't about Bellflowers. | "Each Warden once a second." (check) |
| `wandering_mind.tres` | "Gain 2 Dream rerolls." | Use the term. | "Gain 2 {rerolls}." |
| `cozy_corners.tres` name | "Cozy Corners" | UK spelling (owner 2026-10-22). | "Cosy Corners" |
| `forests_edge.tres` | name "Forest's Edge"; "within 3 cells of the start" | Same name as Act 1 (G.2); "the start" undefined. | Rename (owner pick); "within 3 cells of where nightmares enter" |
| `lesson_card.gd:411`, Codex Mist, route_line "Start", gift "a new start on the rim" | "forest edge", "mist", "start", "rim" | Four names for where nightmares enter. | One: "the mist" (Codex) with "where nightmares enter" on first use. |
| `family_pick_screen.gd:992` vs `remember_screen.gd:583, :986` | "Not in this dream" / "Not in this run" | Two labels for one state. | "Not in this run" |
| `drift_meter.gd:99-100, :454`; `rest_report.gd:586` | "Your maze 120 DPS…", "Last drift 62 DPS" | "DPS" is jargon for a non-TD player. | Tooltip once: "DPS: damage per second"; or "dmg/s". |
| `warden_panel.gd:300` | "Reactions: triggered %d · fed %d" | "fed" unexplained. | "Reactions: triggered %d · helped %d" or a tip "fed: it added a status another Warden's Reaction used". |
| `tower_seller.gd:257` | "Overgrown: no selling while nightmares walk" | "Overgrown" is a name I don't know (card? Omen?). | "Overgrown (Dream): no selling while nightmares walk" (check source) |
| `omen_screen.gd:209` vs `codex_data.gd:31` | "Once revealed, you must take one" / "A harder next block that you may accept" | Read as a contradiction. | Codex: "…that you may choose to face. Once you face one, you must take one of the Omens shown." |
| `breathe_it_in.tres` tip (common) | 60+ words, five rules | Too long to read on a choice screen. | Split: face keeps the rule; tip "Any family's statuses count. {drowsy} gets only 1 more. Never {held}, never past {full}. Only a Warden's own attacks count." |
| `steeped.tres` (common) | two conditions joined by "or" in one sentence | Re-read needed. | "Statuses last 40% longer on a nightmare in range of two {family:dewdrop} Wardens, or when a Warden {touching} a {family:dewdrop} Warden adds them." |
| `fruiting.tres`, `sodden.tres`, `high_tide.tres`, `heavy_going.tres`, `murmur.tres` | "deal 6% more", "deal 10% more", "deal 25% more" | Rule 1: "more damage". | "deal 6% more damage…" |
| `heavy_going.tres` tip | "A slowed nightmare drips while it counts." | "drips" is an unexplained visual. | "A nightmare that counts shows dripping water." |
| `morning_dew.tres` (common) | "every {drift} holds 10% more {dew}" + tip "Holds: …" | "holds" needs a tip. | "every {drift} pays 10% more {dew}" (drop the tip) |
| `thorny_walls.tres` (common) live line `dream_batch_rules.gd:645` | "Lash now: %d damage." | "Lash" is a new word. | "Thorn hit now: %d damage." |
| `deep_sleep.tres` name | "Deep Sleep" | Sounds like {drowsy}/{asleep}; it is about 2+ statuses. | Rename (owner), e.g. "Many Troubles". |
| `drowned_one.tres` hint, `always_damp` | "Lightning loves {damp}" | Flavour hides that Charge/lightning gets a bonus. | "Lightning jumps further between nightmares with {damp}." (if that is what it means) |
| `hobble.tres`, `shattering_blow.tres` tips (common) | "A Calling's forced crit doesn't count." | Calling jargon on a neutral card. | "Crits a Calling forces don't count." |
| `codex_data.gd:30, :156` | Dream entry links "Let it pass" | See 23. | follow the owner's pick |
| `lesson_card.gd:585` | "Face an Omen … You can skip it: nothing changes, no reward." | Fine, but the screen's button says "Continue", not "Skip". | match the button word |

Flagged: 25 ranked + 55 table rows = **80**.

---

## 3. Patterns

1. **Bare "rank" is everywhere outside the cards** (Warden panel, toasts, lessons, signatures, gifts, Sapling, live lines). The Grow vs Nurture sweep fixed card text only: sweep UI strings with the same rule.
2. **"grow" still means "get stronger"** in UI and gift text. Fix: "gets stronger" / "moves up a stage"; "grow" only for forms.
3. **Plain words that are also glossary words** ("heavy", "chain", "pulse", "splash" ×2, "ring" ×2). Fix: one meaning each; plain uses get a different word ("big", "jump", "ripple").
4. **"set off" survives** in the Charge lesson, Pinned, Dawnbreak, Codex Chain and the Night Hound hint. Fix: "trigger".
5. **Base Reactions still say "Needs"** while the Frost ones say "Triggered by … Uses up". Fix: give all 13 base Reactions the Crowned shape (effect, Triggered by, Uses up), numbers before the trigger.
6. **Multipliers without a base** (Thunderclap ×12 / ×6, Charge "16× the stored Charge"). Fix: rule 5, "×N the damage of …".
7. **Firefly jump caps in seconds of damage** on six commons. Fix: "at most what that Warden deals in 3 s", once in the Codex.
8. **Family Dream cards describe the Warden in different words** from the Warden's own text (Bellflower pulse/ring, Dewdrop "only the one hit", Sporeling with no "gives"). Fix: the card's second sentence copies the Warden's first sentence.
9. **Branch Dream cards end in flavour** ("loves bends", "worn-down", "stop mending", "free bolts"). Fix: one number or one effect, as their Warden texts do.
10. **Where nightmares enter has four names** (forest edge, mist, start, rim). Fix: one.

## 4. What already works

- The opening Lessons "Protect the Heartwood" and "Plant and start": short, concrete, name the drift on first use.
- Omen faces: "For the next 5 {drifts}: …" with one number each; I always know what changes and for how long.
- Nightmare traits and hints: plain, one rule each (Shellbound, Widow, Weeper, Crow).
- Sporeling's Calling: trigger, result and number in two sentences.
- First Grip, Hard-Won Rings, Wild Growth, Quiet Rings: the Grow vs Nurture rewrites read cleanly.
- Frost and Cold Snap (F.2) read in one pass; "It doesn't slow." stops the wrong guess at once.
- Nurture choices (Power / Swift / Reach / Deep) say the number in the first words.
