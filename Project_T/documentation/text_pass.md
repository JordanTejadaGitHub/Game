# Text pass: the human voice (2026-10-04)

Owner: design hub (story chat). User, 2026-10-04: *"check everything for the AI look"*. Art goes through Theme
Discussion (art_direction.md "Style references"); this file covers player-facing **text**.

## Voice rules
- **Ration the motifs.** "Remember" is for the Remember screen, Memories and the Grove's one welcome line; nowhere else.
  "Stirs", "the dream" and "the Hollow" at most once per screen.
- **Vary the shape.** Not every line is "Do X, and Y." Some lines are a remark, a half-sentence, a small joke.
- **Concrete beats grand.** Frogs starting up again, a seed in a pocket, a cold draught: never "somewhere beyond, something
  remembers".
- **The Heartwood speaks as "I"**, always: dry, old, fond, a little tired. Never third person about itself.
- **No "not just X, but Y"**, no stock trailer lines, no tidy three-part lists in copy.
- **Numbers and names match the data.** Player text that states a number reads it from the resource where it can; one
  name per thing (Rooted, not Held; Soaked, not Damp).
- Plain mechanical card text is fine as is; it already reads as human.
- **Capitalisation** (user, 2026-10-07: "let's be consistent with capitalisation"):
  - **Names of things are capitalised everywhere:** Wardens and their forms (Rootling, Standing Stone), nightmares (Shade, the
    Hollow Stag), Dream cards, Omens, Gifts, Reactions and Kinships (Heart of the Maze, Fog Bank, Still Pool), statuses in
    every form, noun or verb (Rooted / Roots, Soaked / Soaks, Charged / Charges, Poisoned / Poisons, Drowsy / Drowses,
    Exposed / Exposes, Frozen / Freezes, Silenced / Silences, Asleep, Hidden), currencies (Dew, Dreamlight, Seeds),
    named systems (Nurture, the Memory Grove, the Remember screen, Deeply Blighted, Blight Level) and the Heartwood.
  - **Everything else is lower case in running text:** drift, rest, block, act, leaf / leaves, rank, focus names used as
    words (power, reach), range, damage, path, route, wall, sprout as a verb. (Sprout the Warden is a name: capital.)
  - **Titles and names of cards / Dreams / Omens:** title case (Heart of the Maze, Fog Bank). A button is not a name: "Let it pass".
  - **Buttons, headings, labels, tags and role lines:** sentence case: first word capital, then lower case except names
    ("Take this Omen", "Start drift 1", "Dreams this run", "Long range, high damage", "Anti-air, Roots").
  - Small-caps labels (CapsLabel) are written in sentence case in the data; the font does the rest.
  - The capital marks the **game term**. Ordinary words that happen to match stay lower case: thrown or planted seeds
    (not the Seeds currency), weather and growth in flavour lines ("Rain soaks everything.", "Nothing takes root.").
    Flavour lines (italic) are prose and are exempt from the status rule.

## Fixes (audit by a read-only pass; owners apply)

### Flavour lines (my rewrites; owners paste them)
| Where | Now | New |
|---|---|---|
| results_screen.gd:78 (loss) | "The Heartwood sinks into dreamless sleep. A seed falls, and remembers." | "I'm so tired. Here, take a seed. Try again." |
| family_pick_screen.gd:19 | "The Heartwood stirs, and remembers an old friend…" | "Oh. I know you." |
| whispers.gd:18 | "A dream can bend, but never close." | "Leave them a way through. They'll find one anyway, if you don't." |
| whispers.gd:24 | "Tend the forest, and it will remember you." | "Clear it if you like. I keep count." |
| whispers.gd:31 | "The Heartwood dreams again" | "I'm dreaming again. Good." |
| whispers.gd:40 | "Dreamlight remembers what your Wardens could become." | "Dreamlight. Spend it, and your Wardens get ideas." |
| whispers.gd:43 | "Tend it, and it grows deeper roots." | "Feed it Dew. It'll toughen up." |
| whispers.gd:44 | "Not every dream is yours to keep. You can let one pass." | "None of these? Let them go. Something else will come." |
| grove_screen.gd:444 | "The forest remembered you." | "Back again. Good." (the one allowed "remember"-free welcome) |
| omen_screen.gd:116 / :147 | "The wind stirs" / "Something stirs out in the dark." | "The wind's turned." / "Something's out there. Waiting to be asked." |
| codex_data.gd:38 | "A guardian spirit you plant on the map." | "A small spirit that guards one spot. It's also a wall." |
| meta_run.gd:121-123 | "The X's light remembers you." ×3 | Hollow Stag: "The Stag's antlers are still warm." · act 2: "Quiet out there. Too quiet, then fine." · act 3: "That one's cold went with it." (Main / Meta Code: one line per boss id, not a template) |

### Bosses (Enemy types design + Enemy Code)
- **Tips:** not always three, and not always a closing proverb. Keep a proverb on two bosses at most; others get 2 or 4
  plain tips.
- **Defeat lines (`cleanse_line`):** no "X is gone. Y." template. Each one concrete and different, e.g. Mire Hag: "The fen
  goes still. The frogs, cautiously, start up again."
- **Titles:** "the X that Y" on two bosses at most (keep "the king under the hill"); the rest get a plain epithet.
- Hollow Oak's "Somewhere beyond the dream, the Hollow remembers." → "It's still. Far off, something sighs."

### Facts that don't match (each owner checks the data; the data wins unless its designer says otherwise)
- Heartwood Sapling yield: family_pick_screen.gd:223 "+20 Dew" vs heartwood_sapling.tres "8 Dew" (Main / Tower Code).
- Ascension cost: Grove ascension nodes say "400 Dew"; `evolve_cost` is 600 (Meta Code).
- codex_data.gd:40 "Sporeling grows into Driftspore or Puffball" vs Puffball from Driftspore (Main).
- Rooted vs "Held": rootlight.tres, starcave.tres, support_log.gd:184 (Tower Code). Soaked vs a "Damp" card name (Roguelite).
- Remember screen "any time" (codex_data.gd:33) vs "at rests" (icon_info.gd:47) (Main: say what the code does).
- settings_panel.gd:116 still says "a gold ↑" / "a dot": now a bud and a dewdrop (onboarding.md) (Main).
- codex_data.gd:18 "The thinning dream" quotes per-act Dew shares the Dew pot replaced (Main).
- "Grow: Evolve a Warden" (codex_data.gd:43): use Grow only. One spelling: neighbour, further (UK).

### Marketing copy (Marketing chat)
marketing.md:59 ("not just placing towers"), :60, :104-105 trailer cards and :112 Steam description: rewrite in the
developer's own words, one concrete thing per line. **Done:** :59-60 VO (Short Form Video d3aec1ea), :112 Steam
description (Marketing Discussion d3aec1ea / 9af99f70), :104-105 trailer cards (Trailer 302f7d7e).

## Dreams and Omens audit (2026-10-05, user: "check all the Dreams and Omens, no overlap; text and glossary; clear on what they do")
Read-only pass over 373 Dream cards, 9 Blessings and 27 Omens. Owners apply; the data wins for numbers.

### Omens (decided here, run_design.md)
- **Swift Stream** was a weaker Blood Moon: now **+40% speed on straights of 4+ cells** (a winding maze shrugs it off).
- **Brittle Night** and **Leaf Fall** both double leaks: kept, but **never in the same offer**.
- **Static Sky** → **Crackling Sky** (the status is Charged; "Static" is the old word).
- run_design.md's stale "current values" line is replaced by "the data is authoritative"; Frozen Ground's rule
  now matches the code (no selling during drifts).

### Dream overlaps (Roguelite Mechanic Discussion decides; recommendation in brackets)
- Seeping vs Nightshade: same "per status" effect [Nightshade becomes Seeping's Deepened III, or a new trigger].
- Thin Bark vs Deep Sleep: same Bittersweet trade [give Deep Sleep a different cost, e.g. no rest bonus].
- Kind Canopy vs Rootbound: same "touching 3+" trigger [Kind Canopy → touching an aura Warden].
- Last Leaf / Scarred Bark / Last Stand: three "per missing leaf" scalers [drop Last Stand's leaf part].
- Patient Aim vs Watchful Rest: both reward not firing [Patient Aim becomes crit-only].
- Name clashes: card Crowded Path (vs Omen Crowded Paths), card Resonance (vs the Warden), three "Restless"
  cards (vs Restless Wind / Restless Omens / the Restless nightmare), Remembered Path (the "remember" rule)
  [rename all of them]. Near-twins to check: Canopy / Kind Canopy, Chorus / Sprout Chorus, Lullaby / Lullaby
  Bell, Nursery / Spore Nursery, Eye of the Tempest / Eye of the Storm, Thorn Snare / Snare, Thick Bark /
  Thick Blight, Quickening / Quickened Sap.

### Numbers that drifted (Roguelite Code + Tower Code: read them from the data with tokens)
dream_graftling, elder_stump, grandmother_oak, dewcatcher, wellspring, long_way_home, snugroot, monsoon,
jewelwing_court, thunderhead, magpies_hoard, autumn_gale, puffball, dreamshroom, zephyr, gust, starcave all
quote numbers that no longer match their Warden. Add a generic `{field:warden.x}` token so it can't happen
again. Also: "free clears" that are half-price (dream_state.gd ~4463); Elite "2× Dew" vs the glossary's 3×
(say "a triple share of the Dew").

### Glossary (Main Merger: icon_info.gd / codex_data.gd)
- Focus values stale (Power 18%, Swift 12%, Reach +0.3, Deep +25% Potency); Rank range "I–V" (now VII+).
- Missing entries: Leak, Sprout, Area attack, Effect, Aura, Eldest, Harvest / interest, Blooming / Old Kin.
- Old words in card text: held / hold (Rooted), Marks (Exposed), frozen / soak / dread shells / Charges
  without links; "Chain 10" vs "×10 chain" (pick "Chain 10"); shard caps (say each cap separately).
- Typo: "Magpie Perchs".

### Clarity rewrites (Roguelite Code; the audit's lines are the starting point)
dry_spell, burrowers, blood_moon / bountiful_night ("each drift's pot holds 40% / 50% more Dew"),
crackling_sky / heavy_rain (say "at least 1 stack, kept topped up"), canopy, bramble_oath, heart_of_the_maze,
hunters_patience and reclaimed_earth (split into one effect per line), heartwoods_reach, quick_step,
thousand_cuts, overflowing_well, golden_harvest / hollow_ground / eddy / hairpin_winds (name the exact thing),
great_bell, wild_dew. Rule: one effect per line, every number stated, every term linked, say when a reward pays.

### Docs (owners)
dream_design.md Seeping / Thin Bark numbers and the Resonance contradiction (Roguelite Mechanic Discussion);
CLAUDE.md INTEREST_CAP 80 → 120 and the boss bite 10 / 10 / 12 (Main Merger, with the user's OK).

## Card names in text are links (user, 2026-10-12: "should have an underline showing what Flurry is")
A card named inside another card's text (`{card:id}`, e.g. "Taking it removes Flurry from this run.") is underlined
like a glossary term. Hovering or tapping it shows that card: its name, rarity and description. It is a card link,
never a status link, so "Charged Feathers" still can't be read as the Charged status. Omen names (`{omen:id}`) work
the same way.

## Keywords are always links (user, 2026-10-13: "keywords that aren't generic have the underline with it")
**Rule.** Any word with a meaning special to this game is a **keyword**. Every keyword has a glossary entry (one or
two plain sentences, under 30 words, no other keyword it could do without) and a token, and wherever it appears in
player text it is underlined; hovering or tapping it shows the entry (TapTip: one tip at a time).
- Link the **first** time the keyword appears in a card, panel, Lesson or tooltip block, not every time.
- Never link a keyword inside its own entry, or as part of a longer keyword ("Crowned Reaction").
- **Names are links too:** a Dream card ({card:id}), an Omen ({omen:id}), a nightmare ({nightmare:id}) and a Warden
  (new: {warden:id}, showing its role line and description).
- **Generic words are not keywords** and stay plain: damage, attack speed, range, path, cell, wall, map, run, health,
  boss, wave. (The stat icons explain themselves where they show.)
- Every screen that shows text draws it with the link renderer: Lessons, Dream cards, Omens, gifts, the Warden and
  nightmare panels, the dossier, Grove node cards, the Remember screen, the Codex, results. A plain engine tooltip
  can't hold a link: there the keyword stays plain and the tip itself is the explanation.
- `test_text_style` fails when a keyword is written as a plain word in player text instead of its token.

**Keywords that already have an entry:** the statuses (Soaked, Drowsy, Poisoned, Exposed, Charged, Rooted, Asleep,
Caught, Frozen, Hidden, Silenced), Deeply Blighted, Potency, rank, Nurture choice (Power, Swift, Reach, Deep), Dew,
Dreamlight, leaves, Seeds, drift, block, rest, perfect block, family pick, dread shell, Kinship, Harmony strike,
Reaction, Current, Erosion, arc, ink, spore-sprite, Whole Tree.

**Keywords that need an entry** (drafts):
| Keyword | Entry |
|---|---|
| Warden | A forest spirit you plant. It attacks nightmares, and it blocks the path like a wall. |
| nightmare | What walks the path toward the Heartwood. Dispel it before it arrives. |
| Heartwood | The tree you protect. Each nightmare that reaches it takes leaves; at no leaves the run ends. |
| dispel | To defeat a nightmare. It pays Dew. |
| Sprout | The cheapest Warden. It can grow into any family you have picked this run. |
| family | A line of Wardens that share a theme and a status, such as Sporeling or Firefly Jar. |
| grow | Pay Dew to turn a Warden into a stronger form of its family. |
| branch | A second-step form of a family. A run offers two of each family's branches. |
| final form | The third step of a branch, unlocked with Dreamlight. |
| Ascended | A family's strongest form, from the Memory Grove, late in a run. |
| Nurture | Pay Dew to raise a Warden's rank. Each rank lets you choose one improvement. |
| signature | A special rule a Warden gains at rank V when four of its ranks took the same choice. |
| Mastery | The rank V reward for four matching ranks on a Warden with no signature: 20% better at what it does. |
| All-Rounder | The rank V reward for mixed choices: 20% better at what it does. |
| Wide / Strong / Attuned | The Nurture choices of support Wardens: a wider aura, a stronger aura, or taking every boost in full. |
| stack | One layer of a status. More stacks make it stronger; the icon over a nightmare shows the count. |
| full | A status at its most stacks. Some statuses do nothing until they are full. |
| Crowned Reaction | A stronger Reaction, set off on a nightmare that also carries a third status. |
| Chain | Reactions setting each other off within a second. The number counts them. |
| Calling | The rule your first family brings. It lasts the whole run. |
| Dream | A card you choose at a rest. It changes your run until it ends. |
| rarity (Common, Uncommon, Rare, Legendary) | How strong and how seldom a Dream card is. |
| Bittersweet | A strong Dream card with a cost. |
| Upgrade (was Deepened) | A Dream card that replaces a weaker card you already have. |
| Woven | A Dream card that needs three particular Wardens. |
| New cards (reroll) | Swap the Dream cards on offer for different ones. Limited per run. |
| Banish | Remove a Dream card from this run's offers. |
| Omen | A harder next block that you may accept for a reward at the rest after it. |
| gift | Terrain the Heartwood offers after a boss. You place it on the map and it gives a bonus. |
| act | 25 drifts ending in a boss. A full run has four. |
| Start / call early | Starting the next drift before the current one has finished arriving pays a little Dew. |
| Maze bonus | Dew paid at each rest for a path longer than the starting path. |
| catcher | A Warden that collects extra Dew from nightmares dispelled in its range. |
| interest | Dew a Wellspring pays at a rest, a share of the Dew you hold. |
| aura | A bonus a support Warden gives to the Wardens around it. |
| crit (critical hit) | A hit that deals extra damage. Only some Wardens can crit. |
| flyer | A nightmare that flies over your Wardens instead of walking the maze. |
| resists / weak to | A nightmare takes half damage from a family it resists, and half again as much from one it is weak to. |
| restless | A nightmare made faster by having its path changed while it walks. |
| Remember | The screen where Dreamlight unlocks new forms during a run. |
| Memory Grove | The tree between runs where Seeds unlock families, Dream cards and perks for later runs. |
| node | One unlock on the Memory Grove. |
| perk | A bonus from the Memory Grove that only works while carried in a perk slot. |
| Blight Level | An optional, harder way to play, opened after your first win. |
| Memory | A piece of the story, found on the Memory Grove. |
