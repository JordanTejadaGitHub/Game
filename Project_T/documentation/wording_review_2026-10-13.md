# Wording review for first-time players — 2026-10-13

Owner: design hub (story chat). User: *"Go through all the wording, make sure it makes sense for first time
players."* A read-only pass over every player-facing text except the Dream cards (done in
`card_review_2026-10-12.md`): about 1,600 strings, about 300 flagged. Nothing was run. Line numbers are from HEAD
83ab7b5b and will drift; search for the quoted text. Rewrites keep the mechanics and the tokens; numbers stay read
from the data. Where a rewrite says "(check)", confirm the mechanic before using it.

Rules that already apply: `text_pass.md` (voice, capitalisation, card links), icons for Dew / Dreamlight / Seeds,
status tokens, UK spelling, no exclamation marks.

## 1. One name per thing (decisions)
| Use everywhere | Never in player text | Notes |
|---|---|---|
| **path** (what nightmares walk), **cells** (the unit) | road, route, lane, "the forest's own path" → "the starting path"; tiles | The HUD counter is Path; Warden text already says path |
| **Lessons** (the paused cards) | Hints, guides, tutorial, whispers | Setting "Lessons"; pause menu "Replay lessons"; opening "Skip lessons" |
| **plant** (the action), **Build mode** (the mode) | build a Warden, place | |
| **range** (how far a Warden attacks) | reach, aura (as a distance), "nearby" → "in range"; "around it" → "the 8 cells around it" | |
| **Wardens** | towers, attackers (say "attacking Wardens") | "Warden bar", never "tower bar" |
| **map** | board | |
| **Maze bonus** | maze Dew, maze income | "+N at rest" beside the Dew total |
| **run** | this dream, your dreams (as a run) | "the dream" stays for story lines only |
| **Start** | "Start … now"; "Call early" only with its Dew amount | |
| **Clear** (the action on obstacles) | Tend / Move as the verb (flavour in the tooltip only); "Tended: N" → "Obstacles cleared: N" | |
| **reaches the Heartwood** | leak, leaks | In all player text, Omens included |
| **flyers** | Phantoms (unless it means that one nightmare) | |
| **damages / hits** | soothes, "blows"; "pulse" only as "pulses damage around it" on first use | |
| **Nurture choice** | Focus, pick, "Nurtured:" → "Nurture choices:" | |
| **Attuned** (the support Nurture choice, was Kindred) | Kindred for the choice | **Kindred** stays the Kinship family bonus only |
| **Young** (first Kinship stage, was Sapling) | Sapling for the stage | Heartwood Sapling keeps its name |
| statuses by their names: Soaked, Drowsy, Poisoned, Exposed, Charged, Rooted, Asleep, Caught, Frozen, Hidden, Silenced | Damp, hold / held, marking, spores tick, static | Always the token |
| **Deeply Blighted** | elite | |
| **critical hit** (first use), **crit** (short) | Critical | |
| **boosts** | buff, buffs; "Buff lens" → "Show boosts" | |
| **Memory Grove** | the Grove (alone), your tree | |
| **node**; **Plant** (first buy), **Grow** (later levels), **Grown** (state) | bud, bloom, unlock (as a noun) | |
| **perk**, **carry**, **perk slot** | loadout, waystone; "Loadout slot 4" → "Perk slot 4"; "Loadout full" → "All slots full" | |
| **Dream cards your runs can offer** | the pool, the Dream pool | |
| **add a branch** (with Dreamlight) | call in, call back, call into this dream | |
| **Grove branch** | Hidden branch, "the Grove's hidden branch" | |
| **Banish** (the perk that removes a card) | Let Go as the action | "Let it pass" stays the Dream button |
| "for half damage", "N times" after a plain sentence, **×N** | "at half", "x2" (letter x), "2.5 times" mixed | |
| UK spelling | neighbors, color, gray, favorite, center | |

## 2. Teaching order (Lessons)
Words must not appear before their Lesson. New order:
1. **Protect the Heartwood** (opening 1): nightmares, leaves.
2. **Plant and start** (opening 2, replaces "Build your maze"): "Wardens are walls. Pick a Sprout from the bar below
   and click the ground to plant it; Thornwalls make the path longer. Press Start (Enter) to let in the first wave,
   called a drift." (Touch variant: tap.) No "Earn Dew" card before drift 1.
3. **Speed and pause**: moves to the start of drift 1: "Space pauses, Tab changes speed. You can plant while paused."
4. **Rests** (the rest after drift 1): "The forest is resting. Nothing moves until you press Start, and selling a
   Warden gives all its Dew back. After this, a rest comes every 5 drifts."
5. **Dew and the Maze bonus** (same rest, after it): "Dispelling nightmares earns Dew. Spend it to plant more Wardens.
   A longer path pays a Maze bonus at each rest: the small number beside your Dew shows how much."
6. **Wake a family** (two sentences + the Calling): "Choose one Warden family. Your Sprouts can grow into it, or you
   can plant it directly. Your first family also brings a Calling, a rule that lasts all run, shown on its card."
7. **A Dream**: as now, plus "You don't have to take one."
8. **Statuses stack** (new, once, before the first status Lesson): "Some Wardens leave a status on nightmares. Each
   hit adds a stack; the icon above a nightmare shows how many. Two full statuses on one nightmare set off a
   Reaction."
9. The six **status Lessons**: "Your {Warden} is adding {status} to this nightmare. Each hit adds one stack. {status
   line from section 4}."
10. **Grow**: don't name Remember, the Memory Grove or Dreamlight before the player has them; "Press Remember beside
    Start" when Dreamlight is first earned.
11. **Nurture** (short): "Select a Warden and press Nurture (R) to make it stronger for Dew. Each rank lets you choose
    one improvement. {Hover / Tap} a choice to read it." The rank V rules (signature, Mastery, All-Rounder) move to
    the first time a Warden reaches rank IV, and to Replay lessons.
12. **Catchers**: "This Warden catches extra Dew when a nightmare is dispelled in its range. It is paid to you at the
    next rest." (No bowl / bank / interest on the card.)
13. **Face an Omen**: section 6.
Other Lesson fixes: "Turned around" → "Re-routing nightmares mid-walk makes them restless: they speed up. Keep doing
it and they ignore the new path."; the maze guide's "P" / "S" letters need a legend or icons; "shared interest cap"
→ "all Wellsprings together pay at most {dew}"; pause menu tooltip → "Short lessons the first time a rule matters."

## 3. HUD, building, Callings
- Refusal: "would close the dream" → "blocks the only path"; toast "Leave nightmares a way to the Heartwood. A dream
  can bend, but never close."
- "+3 path" → "+3 cells of path"; "covers N path tiles · a top spot" → "covers N cells of path · one of the best
  spots".
- DriftPanel: "The mist is full" → "Nightmares still arriving"; "Resting, 100% refunds" → "Resting: selling refunds
  100%". HUD "Dreamed: X" → "Unlocked: X". "tramples a Thornwall!" → no exclamation mark.
- Callings (`callings.gd`), written for a player who has seen no status yet:
  - Take Root: "When {spored} on a nightmare is half full, it is {held} for 1.5 seconds. Once per nightmare."
  - Lantern Ring: "Any Warden's hit on a nightmare in a Firefly Jar's range also adds {static}."
  - Splashback: "The first hit on a {damp} nightmare from another family also splashes the nightmares beside it."
  - Ringing: "Each Bellflower pulse adds 1 stack to every status a nightmare already has."
  - Volley: "Every 5th acorn, all Wardens next to the Acorn attack its target at once."
  - Anvil: "Every Warden in range turns to a {held} nightmare, and their hits on it add twice as much status."
  - Tailwind: "Attacks that pass through a Whirligig's range go further: shots fly on to a second nightmare, and
    pulses and splashes spread 1 cell wider."
  - Perches, Lodged Stone: keep, with "range" for "reach".

## 4. Reference text (glossary, statuses, Nurture, Reactions)
**Status pattern:** "[What happens to it.] [Stacks rule.] At N stacks it can set off {reactions}." Plain sentence
first, the number after.
- Soaked: "Water hits deal 20% more damage to it. At {need} stacks it can set off {reactions}."
- Drowsy: "Walks 2% slower per stack. At {cap} stacks ({boss} on bosses) it can fall {asleep} and set off {reactions}."
- Poisoned: "Takes damage every second, more per stack. Each stack lasts 5 s, so keep hitting it. At {need} stacks it
  can set off {reactions}."
- Exposed: "Nothing until {need} stacks; then it takes 25% more damage from every Warden and can set off {reactions}."
- Charged: "Lightning builds up on it. At {cap} stacks ({boss} on bosses) it goes off as a strong bolt (16× the
  stored charge). At {need} stacks it can set off {reactions}."
- Rooted: "Cannot move for a moment. At {need} stacks it can set off {reactions}."
- Potency: "How strong this Warden's statuses are. Higher Potency: harder {spored} and {static}, stronger slows,
  longer {held}. Raise it with the Deep choice."
- Chain: "Reactions setting each other off within 1 s. The number counts them; Chain 10 is a Dawnburst."

**Nurture choices** (row = name · change; tip = one verb sentence): Power: hits harder (+18% damage) · Swift: attacks
faster (+12%) · Reach: more range (+0.3 cells) · Deep: stronger statuses (+25% Potency) · Wide: its aura reaches
further (+0.2 cells) · Strong: stronger aura (+5%) · Attuned: takes every boost in full, not a reduced share.
Footer: "Kept when it grows. Cannot be changed." Check the Rank entry: ranks no longer add flat range (Tower Code
16afb948), and supports have other choices than the four listed.

**Rank V mark** (never "main job", "trained role", "role mastery"): "Signature · Crushing: four Power ranks. [rule]."
/ "Mastery: four [choice] ranks. Its [damage / aura / Dew per drift] is 20% stronger." / "All-Rounder: mixed ranks.
Its [same] is 20% stronger." Firstborn: say it per Warden ("its Sprouts arrive at rank I"). Codex Signature entry:
"Nurture a Warden to rank V. Four ranks of the same choice give a signature, a special rule. Any other mix gives
All-Rounder: 20% better at what it does." "Power majority… Answers armour." → "Four Power ranks: … Good against
armour."

**Reactions** (all 16 `.tres`): effect first, recipe second, numbers last. Thunderclap: "A thunderclap hits it hard
and arcs to {damp} nightmares nearby. Needs 8 {damp} + 10 {static} (15 on bosses). ×12 damage, ×6 per arc."

**Callouts:** "Strong!" on a resisted hit → "Resisted"; "Weak!" → "Weak"; drop every "!".

**Warden panel:** catcher line → "Catches part of the Dew from nightmares dispelled in range. Only the strongest
catcher in range counts. {damp} nightmares give more."; "after the Harvest" → "at the rest"; nursery line →
"reaches 20% further; discount 20% bigger (same limit)"; Gust / Echo choice labels → "copies N% more stacks",
"counts families 0.x cells further out".
**Facts to fix:** the Codex says the Wellspring cap is 120 (the game: 130).

## 5. Wardens (`resource/tower`)
Pattern: what it does to nightmares, then why you'd want it. No fragments that only make sense if you remember the
branch below. No named sub-abilities ("Rockfall:", "Clean cut:", "Not yet:", "the Harvest").
**Starting set**
| Warden | Rewrite |
|---|---|
| Sprout | "A cheap, weak attacker. Grow it later into any family you have picked this run." |
| Sporeling | "Puffs spores at one nightmare and leaves it {spored}: it keeps taking damage over time." |
| Firefly Jar | "Its sparks build {static} on a nightmare. At {cap} stacks ({boss} on bosses) the charge strikes it as a bolt for heavy damage." |
| Dewdrop | "A small splash that hits a few nightmares and leaves them {damp}. {damp} nightmares take 20% more damage from water hits." |
| Driftspore | "Fast puffs that add 2 {spored} stacks each. Its targets can hold more {spored}, so the damage climbs higher." |
| Inkcap | "A {spored} nightmare it hits leaves an ink trail on the path. Nightmares that walk through the ink are {spored} too." |
| Lichenling | "Breaks armour: its {spored} strips a Dread Shell every second (check). Nightmares it has {spored} can't heal." |
| Deliquescent | "Stronger ink trails. A {spored} nightmare it dispels melts into a pool of ink that poisons whatever walks through." |
| Dreamshroom | "A bigger sleepy cloud that makes nightmares {drowsy} twice as fast. At full {drowsy} a nightmare falls {asleep} for 4.5 s, once each." |
| Elf Circle | "Plants up to 9 rings. They never fade: each stays until a nightmare steps on it. (check)" |
| Old Lichen | Two sentences; end with "At N {spored} stacks the whole shell breaks." |
| Jarlink | "Plant two within N cells and lightning joins them (shown when placing). Nightmares crossing it take damage and {static} every second. Flyers take N {static} at once." |
| Lanternmoth | "Long-range light that builds {marked}. At full stacks a nightmare takes 25% more damage from every Warden." |
| Prism Jar | "Shoots one nightmare. Wardens in the 8 cells around it crit 15% more often, for 25% more damage. Two Prisms don't add up." |
| Lightning Fence | Say the new thing over Jarlink in "flyers" wording. |
| Midsummer | "A brighter beam that builds to far higher damage and also hits the nightmare behind its target. It keeps half its build-up when it switches target." |
| Frostfern | "Freezes: a hit on a nightmare with N {damp} stops it for N s. Pair it with Wardens that Soak." |
| Jetreed | "A jet that hits every nightmare in a line. Each hit also takes 2% of its target's max health (0.5% on bosses), so it suits big nightmares." |
| Mistveil | "Lays fog on the path. Nightmares in it stay {damp}, and {spored} hurts them more." |
| Undercurrent | "Opens a whirlpool on the path. Nightmares in it share damage: 25% of any hit on one also hits each of the others." |
| Hoarfrost | "Splashing frost that leaves nightmares {damp} (up to N). At N {damp} a nightmare is {frozen} for N s. It crits more on {held} nightmares." |
| Maelstrom | "A wider whirlpool: up to 8 nightmares share 45% of each hit and are {damp}. A {static} bolt on one hits the others for half damage." |
| Monsoon | "…it damages them all and leaves them {damp} for 9 s." |
| Morning Fog | "A wide fog that lasts 7 s. Nightmares in it are {damp}, for 3 s after leaving too, and {spored} hurts more. Nothing can hide or heal in it." |
| Torrent | "A heavier jet: 3% of max health a hit (0.75% on bosses). It leaves a wet trail 3 cells long that Soaks nightmares crossing it." |
Clear as written: Bloomcap, Brood Cap, Fairy Ring, Hatchery, Puffball, Sporemother, Sparkler, Stormcap, Sunpetal,
Beacon, Rainbow Prism, Starburst, Thunderhead, Stormheart, Cloudlet, Rain Lily, Nimbus, Tidecaller, Thornwall.

**Rest of the roster**
- Dreamroot: "Gathers Dreamlight shards like Dream Oak, and twice as many in a block where no nightmare reaches the Heartwood."
- Earthbind: "Every 2 s it drags up to 5 flyers down to the path. Each is {held} for 0.5 s when it lands."
- Heartroot: "Once per drift, the first nightmare about to reach the Heartwood is dragged back 4 cells instead. Not bosses."
- Autumn Gale: "Throws three seeds down the three busiest lines. Each seed that hits something and returns makes the next throw 10% stronger (up to 50%)."
- Grove Keeper: "Grows a free Sprout seed every 2 drifts. Its Sprouts start at rank II."
- Vesper Bell: "A heavier toll on the strongest nightmare that also hits the next strongest for half damage."
- Chime Stone: "Makes nightmares around it {static}, and sets off {static} early: any nightmare with N or more is struck by its bolt at once."
- Whispering Hollow: "…and each repeat counts towards a Reaction chain."
- Crown of Thorns: "Sharper thorns. Nightmares beside a {held} one take half the thorn damage."
- Mother Log, second sentence: "Sell a Warden beside it and the next Warden planted on that cell this rest keeps its rank."
- Great Dreamcatcher: three sentences. Dream Oak: "Makes Dreamlight slowly, faster with more families near it. …"
- Bastion: "Every 6 s each Thornwall beside it drops a rock on the path."
- Windmill: "Bigger, faster blades. +35% damage for each extra path cell among the 8 around it."
- Silver Bell: "A long-range toll that makes the strongest nightmare fully {drowsy} at once (bosses: 3 stacks)."
- Also: Honeysuckle "(walls alone stop at 3)", Whirligig "carry trouble along", Earthshaker "no new sprints there",
  Edgestone "overkill", Wellspring / Dewcatcher "the Harvest".

**Role lines vs descriptions**
- 19 forms say "Area damage" but their description never mentions an attack (Dewcatcher, Wellspring, Dream Oak,
  Dreamroot, Nurse Log, Mother Log, Seedbearer, Grove Keeper, Deeproot, Heartroot, Long Way Home, Rootcurl,
  Tangleroot, Snugroot, Groundroot, Earthbind, Hushbell, Silence, Whirligig): add a short first clause ("Its roots
  damage every nightmare in range, and…") or drop the term where the damage is negligible.
- Dreamcatcher / Great Dreamcatcher "Single target" vs "nightmares in its range"; Prism Jar; Nestling / Wren's Nest
  ("one more beside it"); Great Bell "Drowses" vs "falls Asleep"; Tidecaller "Pulls back" vs "pushes back", Freezes
  missing; Lightning Fence lost "Charges"; Magpie "removes boosts" vs "strips a buff"; Echo Hollow "repeats combos"
  vs Reactions; Driftspore "fast attacks", Frostfern "high damage", Pebbling "slow attacks" unsupported.
- "Rain cloud", "Boomerang", "Cone" are nouns, not roles: "Rains on the path", "Seed flies out and back", "Hits a cone".
- Don't repeat the role line word for word in the description (Lanternmoth, Mossback, Standing Stone, Moonstone).

## 6. Nightmares, bosses, Omens, gifts, Dream screen, results
**Nightmares** (`resource/enemy`): `trait_text` = what it does, colon, what to do; it is the line the hover and tap
panels show, so the advice must be in it. Shade: "Fast and comes in crowds: use Wardens that hit many at once."
Never name a counter the player may not own without a general alternative. Husk's "thick shell of blight" reads as
the Dread Shell: reword. Night Mare's Laps: "It can't be hurt at the Heartwood. It drains a leaf every 2 s, then runs
the maze again, faster, with Shades behind it."
**Resistances:** "Resists the Sporeling family: those Wardens deal half damage."; split "Immune / shrugs off" into
"Immune to" and "Wears off fast".
**Bosses:** one bold headline above "What it does", from each boss's `tips` (no script seems to show `tips` today:
check). Huntsman: "Dispel his hounds first: he takes half damage while one is near."
**Omens:** pattern "For the next 5 drifts: [twist]. At the rest: [reward]. Each leaf lost: [cut]." Crowded Paths:
"For the next 5 drifts: 45% more nightmares. At the rest: {dew:+60}, {dew:15} less for each leaf lost."
- Screen: "A hidden twist on the next 5 drifts" / "A reward at the next rest, smaller for each leaf you lose" /
  "Once revealed, you must take one".
- Declining: "No Omen. Nothing changes, no reward."; button "Skip the Omen"; "Esc also skips". (Clear Skies may stay
  as the option's title.)
- "Every leak costs double leaves." → "Each nightmare that reaches the Heartwood takes twice as many leaves."
- "A Rare+ card…" → "Your next Dream has a Rare or better card. Lose 2 leaves and it is gone."
- Double or Nothing: "Lose no leaf: the reward is doubled. Lose one: no reward."
- Dry Spell: "Nightmares give no Dew for these 5 drifts. At the rest you get all of it at once, plus 25%."
**Gifts** (`heartwood_gifts.gd`): pattern "Place [what] [where]. [Who] near it [gets what]." One word for near:
"touching" = the 8 cells around; say "on its four sides" when it is four.
- Moonwell: "Place a lit stone on one empty cell. Wardens on its four sides get +1 range."
- Mushroom Ring: "Spore Wardens touching it can stack 2 more {spored} on each nightmare."
- Old Kin: "Pick two bonded Wardens: their bond grows one step now. Bonds formed next act start one step stronger."
- Sow a Ridge: "Draw a wall of 3–5 Withered Trees. Wardens touching it deal 10% more damage. Clearing one later gives 2 Seeds."
- Ancient Stump: "3 stumps. A Warden planted on one gets a free rank, and you choose the bonus."
- "Let them pass, +30" → "Skip the gifts, {dew:+30}".
**Dream screen:** "Dream again · 1 left this run" / "No rerolls left this run" → "New cards · 1 left" / "New cards ·
none left"; labels with their meaning: "Upgrade: replaces Evergreen", "Bittersweet: has a cost", "Woven: needs three
Wardens".
**Results and rest report:** under the Seeds total: "Seeds grow permanent unlocks in the Memory Grove."; "Drifts
survived from 26: 3" → "Drifts survived after 25: 3"; "Tended: 12" → "Obstacles cleared: 12"; rest report shorthand
("Harvest", "Maze DPS", "Carrying", "Underused", "next drift needs ~") in plain words: "Dew caught", "Damage per
second, whole maze", "Did the most", "Did little", "Next drift needs about".
**Demo ending:** "You've reached the end of the demo (drift 50). The full game continues to drift 100, with two more
acts and more of the Memory Grove."

## 7. Memory Grove, Remember, settings
**Node descriptions** (`resource/meta/grove`):
- Families: "[Name] can now appear as a choice at family picks. [What it does.]" — Pebbling: "…Slow, heavy hits for
  tough nightmares."; Acorn: "…Strengthens nearby Wardens and earns Dew. Also adds the Dew Trail card."; Whirligig:
  "…Wind that spreads one nightmare's statuses to others."; Rootling: "…Roots that slow and hold nightmares."
- Cards: "Adds N Dream card(s) to your runs for [build]: [names]." — Sharpened: "Adds five Dream cards for critical
  hits: …"; Planted Promises: "Adds three Dream cards that pay off later in a run: …"; a single card: "Adds the Dream
  card Seeping: {spored} does more damage."; Legendary: "Adds the Legendary Dream card Briar Crown to the cards your
  runs can offer." Where the node's name differs from its card (Elders → Few and Mighty), name the card.
- Perks: "While carried: [effect]." — Morning Stores: "While carried: +10 starting Dew per level, up to +30."; Wider
  Dreams: "While carried: each Dream offers 4 cards instead of 3."; Second Thoughts: "While carried: +1 Dream reroll
  per run per level, up to 3. Always: adds the Wandering Mind card."; Wider Roots: "Your first family offers 3
  branches instead of 2. Adding another branch costs 4 Dreamlight."
- Ascensions: "Unlocks Sporemother, the Sporeling family's strongest form. In a run: from drift 51, unlock it for 3
  Dreamlight, then grow a final form into it for 600 Dew."
- Grove branches: "Also adds its Dream cards (listed below)." for "Brings the on-hit cards."
**Screens:** three limb labels on the tree with one line each (Families: new Warden families for the family pick ·
Cards: more Dream cards for your runs · Perks: bonuses you carry into a run). "Carry it to use it." → "Perks only
work while carried. Tap Carry into the run." "needs" + chips → heading "Plant first"; any-of: "One of: Pebbling,
Rootling". "Full game. It sleeps until then." → "Not in the demo. This node grows in the full game." Loadout:
"No perks yet. Plant one in the Memory Grove." / "Locked. Plant Perk slot 4 in the Memory Grove." Blight picker:
state each level's effect in plain words ("Skipping a Dream gives no Dew; Dreams are more often Common").
**Remember screen:** "Dreamlight unlocks, Dew grows." → "Spend Dreamlight here to unlock a form. Then pay Dew on the
map to grow a Warden into it."; "This dream offers 2 of 5 branches…" → "This run offers 2 of this family's 5
branches, chosen at random. You can add one more for Dreamlight."
**Settings** (label → plain label · tooltip):
- V-sync → Smooth frames (V-sync) · "Stops screen tearing. Turn off if the game feels delayed."
- UI size → Text and button size · "The map does not zoom."
- Placement grid → Build grid · "Shows grid lines while planting a Warden."
- Hints → Lessons
- Damage numbers · "Numbers over nightmares when hit. Big hits shows only crits and Reactions."
- Warden DPS tags → Damage per second labels · "Shows each Warden's damage per second above it."
- Rest summary → Summary card at rests
- Always show resist / weak pips → Always show resistance markers · "Small marks showing which damage a nightmare resists or is weak to."
- Kinship effects → Kinship visuals · "The vines between bonded Wardens. Subtle draws fewer."
- Omens: Ask each rest / Never → Omen offers · "Never always skips them."
- Edge scrolling → Move camera at screen edge
- Hit-stop on big hits → Brief freeze on big hits
- Buff lens (keybind) → Show boosts

## 8. Owners
| Chat | Sections |
|---|---|
| Main Merger | 1 (in its files), 2, 3 (HUD and building text), 4 (glossary, Codex, callouts, Warden panel), 6 (Omen screen, Dream screen, results, rest report, nightmare panels, dossier headline), 7 (Remember, settings) |
| Tower Code | 1 (in its files), 4 (signatures, Nurture choice labels, Reactions, Kinship stage and the Attuned rename), 5 (all Warden text and role lines) |
| Roguelite Code | 1 (in its files), 3 (Callings), 6 (Omen data and reward sentences, gifts) |
| Enemy Code | 1 (in its files), 6 (nightmare trait text, boss headlines, resistance wording data) |
| Meta Game Code | 1 (in its files), 7 (Grove nodes, Grove screens, loadout, Blight picker) |
