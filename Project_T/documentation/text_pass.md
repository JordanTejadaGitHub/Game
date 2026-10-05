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
