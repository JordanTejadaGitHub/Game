# Round 3: new_player seat (2026-10-24)

Seat: I've played a few mobile games but never a tower defence or a roguelite. One read, about 5 seconds: do I know
what happens, to what, when, and how much?

Read: corpus_resources.txt, the "+" lines of corpus_ui_diff.txt, the 84 live rows in calling_rows_now.txt (53 retired
skipped), enemy_design.md "Drift shapes", and the shape text the player will see: `scripts/ui/shape_rows.gd` (uncommitted,
in the shared tree), `drift_banner.gd:262-271`, `rest_report.gd:332-363`. Tokens are judged as icon_info.gd renders them.

**Drift shapes, short answer:** a first-time player gets the shape **names** (Packs, Single file, Few and tough read
fine; Stream doesn't) but not the **numbers**. The fact lines give bare numbers with no nouns ("Packs: 4 × 7"), nothing
in the game says what a shape is, and nothing says a pack can only take 3 leaves. Problems 1-3 below.

---

## 1. Top 10 problems

### 1. Shape fact lines: numbers with no nouns
**Where:** `shape_rows.gd:79-84` (Coming strip rows at a rest), built as "Drift N · <fact> · <where>".
**Now:**
- "Stream: 30"
- "Packs: 4 × 7, 6 s apart"
- "Single file: 18, 1.6 s apart"
- "Few and tough: 9, 4 Deeply Blighted"

**Problem:** 30 what? "4 × 7" reads as a sum to work out, or a size, not "4 packs of 7". "18, 1.6 s apart" is two numbers
and I have to guess which one is the count. "9, 4 Deeply Blighted" reads like a list of 13. Every line leaves out the
noun, "nightmares".
**Rewrite** (same numbers, same order):
- "Stream: 30 nightmares, evenly spaced"
- "Packs: 4 packs of 7, 6 s apart"
- "Single file: 18 nightmares, one every 1.6 s"
- "Few and tough: 9 nightmares, 4 {deeply_blighted}"

On phones, if this is too wide, "4 packs of 7" is the one to keep; "nightmares" can drop from the other three before it.

### 2. Nothing explains what a shape is, or the 3-leaf pack cap
**Where:** codex_data.gd GLOSSARY_SOURCE has no shape entry (grep finds no "Single file", "Packs" or "rolled with the
map" outside the drift scripts). The design wants it: "The glossary names the four shapes once and says *shapes are
rolled with the map*", and "A pack takes at most 3 leaves … the glossary says so". The cap is live in code
(`run_state.gd:247-249`), so right now a pack that reaches the Heartwood takes fewer leaves than the player expects, and
nothing tells them why.
**Problem:** the banner says "Drift 31 of 100 · Packs" and the rest report says "This block: Stream, Packs, …" with no
link to anything. "Stream" in particular means nothing on its own (see 3).
**Rewrite** (new glossary entries, linked from the shape name in the strip, banner and rest report):
- **Drift shape:** "How a {drift}'s nightmares arrive. Shapes are rolled with the map. Stream, Packs, Single file, Few
  and tough."
- **Stream:** "Nightmares arrive evenly spaced."
- **Packs:** "Nightmares arrive in packs of one kind, close together, with a gap between packs. A pack takes at most 3
  {leaves} in all."
- **Single file:** "Nightmares arrive one at a time, with a gap between each. Fewer nightmares, but tougher ones."
- **Few and tough:** "A few nightmares, several of them {deeply_blighted}, and they come first." (check: "first" is the
  elite placement from the design)

### 3. "Stream" is already a Dewdrop evolution and part of an Omen's name
**Where:** `drift_shapes.gd:22` (shape name "Stream"); `calling_paths.gd:352` dw_stream "Stream" (Dewdrop Spread style:
"{Water} runs 4 {steps} further…"); resource/omen/swift_stream.tres "Swift Stream".
**Problem:** a Dewdrop player who took the Stream evolution sees "This block: Stream, Packs, Stream, …" on the rest
report and thinks it's about their water. Two meanings for one word, on the same screens.
**Rewrite:** rename one of the two (owner decision). For the shape, a plain word that says the same thing:
"**Steady**" ("Steady: 30 nightmares, evenly spaced"). If the owner keeps "Stream" for the shape, rename the Dewdrop
style instead (e.g. "Running Water"). The Omen "Swift Stream" can stay; "Swift" makes it a different thing.

### 4. Advice lines are back: "Works for:", "Safe.", "A bet: pays when…"
**Where:** resource/dream gathering_storm.tres, heavy_going.tres, on_the_beat.tres, struck_twice.tres (tips).
**Now:**
- Gathering Storm: "… Works for: boards with several cards that make {jumps}. A bet: pays when several {jump} cards hit
  one pack."
- Heavy Going: "… Works for: Wardens beside slows. Safe."
- On the Beat: "… Works for: any Warden {touching} a {family:bellflower} Warden. Safe."
- Struck Twice: "… Works for: {family:firefly_jar} Wardens against tough nightmares in a pack. Safe."

**Problem:** this breaks the owner's no-hand-holding rule (no strategy or combo lines). And for me as a new player,
"Safe." and "A bet" sound like rules: is the card risky? Does it cost me something? "pays" is also on the
words-to-avoid list.
**Rewrite:** cut every "Works for: …", "Safe." and "A bet: …" sentence and keep the rules:
- Gathering Storm tip: "Resets after 2 s without a {jump}. Every {jump} counts, from any card or Warden, except a Calling
  evolution's. Bosses take half of each {jump}."
- Heavy Going tip: "Any slow counts except {drowsy}'s and the Calling's own; {held} and {asleep} nightmares stand
  still, so they don't. Hits only, not status damage. A slowed nightmare drips while it counts." (check "drips": it
  isn't explained; see table)
- On the Beat tip: "Damage only: no status, and it triggers no other card or bell. Other {family:bellflower} Wardens
  join too."
- Struck Twice tip: "Every {jump} counts, from any card or Warden, except a Calling evolution's. Hits only, not {jumps}
  or bolts. One waiting hit per nightmare; it fades after 2 s. Multiplies with your other Dream damage."

### 5. Lantern Alley: the main sentence doesn't parse
**Where:** calling_paths.gd lf Lantern Alley text.
**Now:** "A glow entered within 4 {steps} of the last {flares} the nightmare: 25% of its Firefly's damage for each glow
in the streak, up to 150%."
**Problem:** "the last {flares} the nightmare" has no verb I can find. It took three reads to work out that a glow
entered soon after the last one makes that glow's Firefly flare the nightmare.
**Rewrite:** "When a nightmare enters a glow within 4 {steps} of its last one, that glow's Firefly {flares} it: 25% of
the Firefly's damage for each glow in the streak, up to 150%."

### 6. Unfettered and "Calling hit": "clock" and "share" are never explained
**Where:** unfettered.tres (NEW); codex_data.gd "Calling hit" glossary entry (new).
**Now:**
- Unfettered: "Bonus hits from your Calling deal full damage, even from slow Wardens." Tip: "Still once per its own
  clock. Bosses still take their share."
- Calling hit: "Deals the Warden's damage, scaled; a Warden slower than the hit's clock deals a share."

**Problem:** "its own clock", "the hit's clock" and "their share" are invented terms, never explained. I can't tell what
a slow Warden normally loses, so I can't tell what Unfettered gives me. The card also says "Bonus hits from your
Calling" when the glossary just named them "Calling hits".
**Rewrite:**
- Calling hit: "An extra hit made by a Calling evolution ({free_hit}, {flare}, {toll}, repeat, spill). It deals the
  Warden's damage, scaled. A Warden that attacks less often than the hit can come deals less." (check the rule)
- Unfettered: "{calling_hit}s deal full damage, even from Wardens that attack slowly." Tip: "Each still comes only as
  often as its card says. Bosses still take half." (check: "their share" = half?)

### 7. "Deeply Blighted counts as 3 toward dispel counts" and "Deeply Blighted first"
**Where:** codex_data.gd:107 (Deeply Blighted glossary); shape_rows.gd:96 ("Deeply Blighted first").
**Problem:** "dispel counts" is not a thing a new player has seen; it reads as a score. "Deeply Blighted first" (in the
Coming strip, after "Few and tough: 9, 4 Deeply Blighted") could mean the first ones you'll meet, or a ranking. Its
siblings say "in a pack" / "last in line".
**Rewrite:**
- Glossary, last sentence: "Cards that count dispels count a Deeply Blighted as 3."
- Strip: "Deeply Blighted first in line" (matches "last in line").

### 8. Moth to Flame: who gets the crit, and what "+50% once 4 other hits land" means
**Where:** calling_paths.gd lf Moth to Flame text.
**Now:** "A Firefly's direct hit on gold path saves a crit for the Warden with most gold dispels this block: +50% once 4
other hits land."
**Problem:** "saves a crit for" plus "+50% once 4 other hits land" is two rules squashed into one. Is it +50% crit
damage? Does the crit wait for 4 hits, or get stronger after 4? I can't tell.
**Rewrite (check):** "A Firefly's direct hit on gold path readies a crit for your Warden with the most gold dispels this
block. If 4 other hits land on that nightmare first, the crit deals 50% more."

### 9. {tolls} used as a verb renders as the capitalised noun "Tolls"
**Where:** Last Bell ("Your last bell before the Heartwood {tolls} each once"), Halfway Bell ("also {tolls} each
nightmare once"), Steady Beat ("{tolls} every 3rd {ring}"), Steady Beat tip ("… first {ring} on one {tolls}").
icon_info.gd:332 has toll = ["Toll", "Tolls", "Toll"].
**Problem:** on screen this reads "Your last bell … Tolls each once", a capital noun where a verb goes, with a glossary
link that defines the noun. I read "Tolls" as a thing, not an action.
**Rewrite:** keep the token on the noun only: "Your last bell before the Heartwood strikes each nightmare once with a
{toll} for its own damage, …"; "A nightmare rung by only one bell since its last {toll} gets a {toll} every 3rd {ring},
in full, …"; Halfway Bell: "… also gives each nightmare one {toll}, at half Last Bell's bonus; …".

### 10. Toadstool Throne: what was planted 10+ drifts ago, the clump or the Warden?
**Where:** calling_paths.gd sp_throne text; dream_keywords.gd "Age" keyword.
**Now:** "A Warden at a clump planted 10+ {drifts} ago makes it a throne: …". Age: "A Warden kept on the map for many
{drifts}."
**Problem:** "a clump planted 10+ drifts ago" is the natural reading, but the tip ("your oldest Warden's", "Growing it
keeps its age") says it's the Warden. "many" in the Age keyword is vague when the card has a number.
**Rewrite:** "A Warden planted 10+ {drifts} ago makes its clump a throne: its last {mushroom} is never eaten, so its
{free_hits} go on." Age: "How many {drifts} ago a Warden was planted. Growing it keeps its age; selling it resets it."

---

## 2. Other flagged strings

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| hollow_wind.tres | "For the next 5 {drifts}: the first 3 are all flyers." | "the first 3": 3 nightmares or 3 drifts? | "For the next 5 {drifts}: the first 3 of them are all flyers." |
| restless_wind.tres | "nightmares arrive 45% closer together." | On Packs drifts only the gaps between packs shrink (omen_director.gd:114); a new player expects the packs to squeeze too. The strip shows the numbers after the pick, so this is low. | Optional tip: "On Packs drifts: the gaps between packs." (check) |
| shape strip, Omen pending (shape_rows.gd:59-67) | Shows "Drift 31 · Few and tough", then after Giants' Walk is picked that drift becomes a Stream | The shape changes with no word. I'd think I misread it. | Glossary line on Giants' Walk or Few and tough: "Under Giants' Walk a Few and tough drift arrives as a Stream." (check) |
| rest_report.gd:363 | "Leaves lost by shape this act: Packs 3, Single file 0, Few and tough 1" | Fine once shapes have a glossary (2). Stream drifts are left out with no word, so the numbers look like they don't add up to my leaves lost. | "Leaves lost this act: Packs 3, Single file 0, Few and tough 1, other drifts N" (check), or keep as is once the glossary exists |
| callings.gd acorn | "Every 5th attack of a {family:acorn} aura Warden, the Wardens in its aura attack its target at once." | "aura Warden" is jargon; three "its/aura" in one line | "Every 5th attack of an {family:acorn} Warden with an aura: every Warden in that aura attacks the same nightmare at once." |
| callings.gd rootling | "Every Warden in range turns to face a nightmare with {held}, …" | "turns to face" reads as an animation, not "targets first" | "Every Warden in range attacks a nightmare with {held} first, and its hits on it add twice as much status." (check) |
| codex_data "Calling hit" related list | "Free hit, Flare, Toll, Repeat, Spill" | "Repeat" and "Spill" are glossary entries but not tokens in card text (Black Pond says "spill onto", Accompaniment "repeats its hit"); the link is lost on the cards | Tokenise "spill" and "repeat" on the cards that use them, or drop them from the glossary |
| Crushing Depth | "… direct hits pass the {dread_shell}, bosses' too, …" | "pass" could mean go past without hitting | "… direct hits ignore the {dread_shell}, bosses' too, …" (check) |
| Fathoms | "10% more damage for each second (bosses 20%) a nightmare has waded the pond" | The "(bosses 20%)" lands after "second", so it reads like a time | "10% more damage (bosses 20%) for each second a nightmare has waded the pond, up to +50%." |
| Windblown tip / Windfall / Sporefall tips | "go first when there are more than 40" | "go" = removed? used? | "are removed first when there are more than 40" |
| Host Trees | "… the Warden Shared Caps picks wears a cap: +15% {potency} …" | "cap" is a mushroom cap and also "up to" cap elsewhere; "the Warden Shared Caps picks" needs Shared Caps open | "At each {mushroom}, the Warden that Shared Caps adds stacks for gets a mushroom hat: +15% {potency}, …" (check name: owner may keep "cap") |
| Shared Caps tip | "for a Sprout, the {spored} the {dose} just put on. {static} and {marked}: 1." | Sentence fragments; I can't tell what "1" is | "For a Sprout, it adds to the {spored} the {dose} just put on. {static} and {marked} get 1 {stack}, not 2." |
| Curfew | "… the bell keeps its count: the next nightmare it hits takes a second {toll} …" | "its count" of what? | "… the bell saves that nightmare's {rings}: the next nightmare it hits takes a second {toll}, at half damage." (check) |
| Early Lamps tip | "Halfway along the path it walks; flyers, their flight." | Cryptic shorthand | "The path's first half: of the path it walks; for flyers, of their flight." |
| Allegro | "A {rank} V+ bell keeps each {toll} stopped by the once-a-second limit (up to 3) and spends it on the next ready nightmare it hits." | Long, nested; "ready" undefined | "A {rank} V+ bell saves up to 3 {tolls} the once-a-second limit blocked. It gives them to the next nightmare it hits that can take a {toll}." |
| Accompaniment | "Wardens {touching} a bell, bells too, join it and ring." | "bells too" dangling | "Wardens {touching} a bell join it and ring, other bells too." |
| Tenor Bell tip | "Its form's speed: Dreams that quicken it don't take this away." | "Its form's speed" is a fragment | "It goes by the form's own speed: Dreams that make it faster don't take this away." |
| Moth to Flame tip / Pyre | "Gold dispels" / "a Warden with 50 dispels on gold path" | Two phrasings of one count | One name: "gold dispels" everywhere, defined once in the tip |
| Borrowed Light tip | "at most 3 s of the lighting Firefly's damage" | Which Firefly is "lighting"? | "at most 3 s of the damage of the Firefly whose glow it's in" |
| The Old Ones | "count as 2 {ranks} higher for every {rank} check, Callings included" | "rank check" is jargon | "count as 2 {ranks} higher wherever a card or Calling asks for a {rank}." |
| hobble.tres / shattering_blow.tres tip | "A Calling's forced crit doesn't count." | "forced crit" never defined | "A crit made by a Calling evolution doesn't count." |
| heavy_going.tres tip | "A slowed nightmare drips while it counts." | "drips" is unexplained: a visual? a status? | "A slowed nightmare is drawn dripping while it counts." (check) |
| gathering_storm.tres | "Needs another source of {jumps}." | Is it a cost or an unlock condition? I don't own one yet. | "Only offered when you have another card or Warden that makes {jumps}." (check) |
| clean_strike.tres tip | "A family that puts no status never gets it." | "gets it": gets the bonus? | "A family whose Wardens put no status never gets the bonus." |
| unfettered vs monoculture vs solitude | "slow Wardens" / "attacking Wardens" | "slow Wardens" could mean Wardens that slow nightmares | "Wardens that attack slowly" (as in 6) |

---

## 3. Patterns

- **Numbers without nouns** (shape lines, "{static} and {marked}: 1"): every number names what it counts.
- **Advice in tips** ("Works for:", "Safe.", "A bet"): four Dream cards changed since the gap round brought it back.
  Cut on sight.
- **Invented clock words** ("its own clock", "the hit's clock", "share"): say how often or how much, in seconds or %.
- **Noun tokens used as verbs** ({tolls}): tokens go on nouns only; use "gives a {toll}" or "strikes … with a {toll}".
- **One word, two things** (Stream, cap, pass): check new names against card, evolution and Omen names before shipping.
- **Possessive chains** ("the Warden Shared Caps picks", "Last Bell's bonus", "Spore Season's +60%"): fine for a
  veteran; for me, name the effect once ("at +60% from Spore Season").
- **New concepts with no glossary on day one** (shapes, pack cap): a new on-screen word ships with its glossary entry.

## 4. What already works

- The shape names Packs, Single file and Few and tough are plain English and say the arrival in two or three words. The
  shape glyphs and the arrival timeline idea (clumps, dotted line, fat dots) will teach the rest without words.
- The banner rule "a Stream says nothing" keeps the normal drift quiet; "Drift 31 of 100 · Packs" reads at a glance.
- Showing the numbers only after the Omen is picked is right: the strip never shows numbers that are about to change.
- "Deeply Blighted in a pack" / "last in line" read instantly.
- Buttons: "Start run", "Carry perk", "Close", "Continue", "Hunt the X", "Use this map", "Map seed", "Auto-drift",
  "Title screen", "Grow into X", "Can't be sold", "Not enough Dew: need N" all say what happens. "Which map?" is much
  clearer than "Which dream?".
- Omen lines all open with "For the next 5 {drifts}:" and then one plain effect: easy to learn.
- New Dream cards Monoculture, Solitude, Hobble and Shattering Blow are one clean sentence each, with the number up front.
- The Ring, Flare and Lingering glossary entries fix the round-2c complaints that those words were never defined.
- Dewdrop rows Stream, Floodgate, Spate and Silt all share one shape ("walk N% slower (bosses N%) for N s").
