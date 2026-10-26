# Veteran seat: full round 2026-10-26

Seat: genre veteran (Slay the Spire, Balatro, Hades, BTD6, Kingdom Rush). I read the text as a contract and checked it
against the code. Focus this round: places where the text and the code disagree. I checked the start-pool Dream cards,
Reactions and Crowned Reactions, Frost, the Calling rows (timing and spot checks), Grove perks / nodes and the Codex
rule entries. Repo read-only, nothing run. "(check)" = I am not certain of the mechanic.

Earlier rounds already confirmed most numbers (Calling rows 2b / 2c / R3). Since then the Calling stages moved to drifts
20 / 45 / 60 / 75 (`calling_paths.gd:13`). No player text still names the old drifts, and the Codex family-pick drifts
(1, 10, 40, deepen 60) match `drift_director.gd:43`.

## 1. Top mismatches, ranked by how badly a player would misplay

| # | Where | Text says | Code does | Rewrite (keeps every number / token) |
|---|---|---|---|---|
| 1 | **Grove nodes that name retired cards**: `meta/grove/acorn.tres` ({card:dew_trail}), `bellflower_hidden.tres` ({card:encore}), `dewdrop_hidden.tres` ({card:deep_frost}), `nestling.tres` ({card:shiny_things}), `sporeling_hidden.tres` ({card:ring_dance}), `last_stand.tres` ({card:desperate_bloom}, {card:second_wind}) | "Also adds the X card" | All 7 cards are `retired = true`. They are never offered, and the player pays Seeds for them. | Delete the "Also adds…" clause, or un-retire the card (owner's call). `last_stand.tres`: "Adds the {dream} card {card:last_stand} for risky play." |
| 2 | `dewdrop_hidden.tres` | "…the {warden:hoarfrost}: it freezes nightmares that have {damp}." | Frost builds from Frostfern's own hits and needs no {damp} (`frostfern.tres` status_stacks 1, cap 15). Nothing "freezes"; Frost doesn't slow (F.1). | "…then the {warden:hoarfrost}: its hits build {frost} until the nightmare bursts in a {frostburst}." |
| 3 | **The Great Bell**: `dream/dream_great_bell.tres`, `tower/great_bell.tres`, `meta/grove/bellflower_ascension.tres` | "every nightmare falls {asleep}" | The peal adds 99 {drowsy} (`great_bell.tres` status_stacks 99), which fills Drowsy. It has no `sleep_at_max_drowsy`, and full Drowsy never puts a nightmare to sleep on its own (no sleep call; the sleep sources are `tower.gd:4007`, `class_kit.gd:566`, `reactions.gd:611/627`, `enemy.gd:1412`). Bosses never sleep (`enemy_statuses.gd:1170`). A player times hits around a 3 s sleep that never happens. | "…every 8 s it peals across a huge range: every nightmare reaches {full} {drowsy}, and every nightmare with … {static} … releases its bolt at half strength." Or the code makes it sleep (owner's call). |
| 4 | `meta/grove/bellflower.tres` | "Song that gives nightmares {drowsy} until they fall asleep." | Same as #3: no Bellflower form except Dreamshroom-style sleep cards puts a nightmare {asleep} from Drowsy alone. | "Song that gives nightmares {drowsy}." |
| 5 | **Undiluted** (`dream/undiluted.tres`, uncommitted edit) | "{spored}, {static} and {frostburst}s deal double damage" | `UNDILUTED_FROSTBURST` (`dream_state.gd:6122`) is defined and never read. The burst (`enemy_statuses.gd:446`, `reactions.gd:2268`) has no Undiluted factor. Poisoned and Charged do double (`dream_state.gd:5331`, `:6155`). | Wire the ×2 into the burst, or drop "and {frostburst}s" from the text. |
| 6 | **Rolling Thunder** (start pool) and **Thunderclap** | RT: "reach 3.5 cells instead of 2.5 and add 2 {stacks}…". Thunderclap: "arcs to nightmares with {damp} in range". | Arc cap: base 8, **Rolling Thunder 5**, II 8 (`reactions.gd:40`, `:1033`). RT quietly cuts the arcs from 8 to 5, so taking it can lower Thunderclap damage in a crowd. | RT cost: "Nightmares its {arcs} strike lose their {damp}. It arcs to at most 5 nightmares (usually 8)." Thunderclap: "…arcs to up to 8 nightmares with {damp} within 2.5 cells." |
| 7 | **Run Through** tip (start pool) | "Only nightmares within 4 {steps} behind it" | `RUN_THROUGH_CELLS 2.0` × 64 px along the path (`dream_hit_cards.gd:56`, `:358`). The Codex defines a Step as one cell of path, so the reach is 2 {steps}. | "Only nightmares within 2 {steps} behind it; flyers don't count." (or change the constant) |
| 8 | **Drown** (`reaction/drown.tres`) and **Deep Water** | Nothing about repeats | Drown happens **once per nightmare** (`DROWN_TIMES [1, 1, 2]`, `reactions.gd:68`, `:1259`). Players feed Damp into a nightmare that has already drowned. | Drown: add "Once per nightmare." Deep Water II's card: "…twice per nightmare." (check its text) |
| 9 | **Frost Reactions**: Brittle, Frostbite, Flash Freeze | No cooldown, no order | Cooldowns: Brittle 8 s, Flash Freeze 6 s, Frostbite 6 s (bosses 10 s) (`reaction/*.tres` cooldown, `reactions.gd:2244`). One per burst, checked in the order Brittle, Frostbite, Flash Freeze (`reactions.gd:2323-2346`). Only a Warden-made burst counts (`gen == 0`, `:2266`). Quick Reactions doesn't shorten them (`:1704`). | Add to each: "Each nightmare once every 8 s." / "…6 s (bosses 10 s)." Codex Frostburst: "A burst a Warden made triggers at most one Frost Reaction: Brittle first, then Frostbite, then Flash Freeze." |
| 10 | **Codex Frostburst** (`codex_data.gd:129`) | "Up to 3 bursts in a row." | Frost a burst gives to others is a quiet add that stops 2 short of the cap (`apply_chain_frost` → `copy_quiet`, `FROST_QUIET_SHORT 2`, `enemy_statuses.gd:62`, `:577`). Only Flash Freeze's Frost can burst again (`full = flash`). A plain burst never chains. | "…those 4 gain 1 {frost} (never enough to burst). With {combo:flash_freeze}, its bursts can set off up to 3 more in a row." |
| 11 | **Cold Snap** (Frost tooltip `icon_info.gd:29`, Codex `:130`) | "…and it gets a {cold_snap}" | At most once per 6 s (bosses 10 s) per nightmare (`COLD_SNAP_EVERY`, `enemy_statuses.gd:67-68`, `:84`). A boss's Drowsy keeps running down (`:946`). Most fast bursts give no Cold Snap. | Codex Cold Snap: "…(bosses {const:cold_snap_boss} s). Each nightmare once every 6 s (bosses 10 s). Not {held}, sleep, slows or a boss's {drowsy}." |
| 12 | **Asleep** glossary (`icon_info.gd:25`) and Codex synergy "Asleep" (`codex_data.gd` SYNERGIES) | "Stopped for 3 s"; "Full {drowsy}: the nightmare falls {asleep} for 3 s" | No fixed 3 s: Dreamshroom 4.5 s (`dreamshroom.tres:30`), Undiluted 2 s, Fever Dream 2 s, Nod Off / naps 1 s, Still Pool 1 s. Full Drowsy alone never sleeps. Bosses never sleep. After waking, there is a 4 s wait (bosses 8 s) before the next sleep (`SLEEP_COOLDOWN`, `enemy_statuses.gd:126`). | Asleep: "Stopped for a time the card or Warden names; a big hit (10%+ of its health) wakes it. Bosses never fall asleep. After waking it can't fall asleep again for 4 s." Synergy: "Dreamshroom: at {full} {drowsy} a nightmare falls {asleep} for {field:dreamshroom.sleep_at_max_drowsy:seconds}." |

## 2. Every other flagged string

| Where | Now | Problem (code) | Rewrite |
|---|---|---|---|
| Grove **Early Bloom** sidegrade text (`early_bloom.tres` sidegrade_description; shown by default, see §5) | "Costs: the {family_pick} at {drift} 25 shows one fewer {family}." | There is no pick at drift 25. The cost hits the first pick after drift 1 within Act 1, i.e. drift 10 (`family_pick_screen.gd:157`, `:338`), and never drops below 2, so without Wider Choice it costs nothing. | "Costs: the {family_pick} after {drift} 10 shows one fewer {family} (never fewer than 2)." |
| Codex **Hollow** (`codex_data.gd`) and the hollow tooltip line | "While any status on a nightmare is hollow, no Reaction can trigger on it." | Only Reactions triggered by a status landing wait (`reactions.gd:293`). Shatter on a hit (`:725`), Frost Reactions (`:2266`) and Smother's end don't check `fed_locked()`. | "…no Reaction can trigger from a status landing on it (Shatter and Frost Reactions still can)." (check: maybe the code should block them all) |
| **Hunter's Patience** (start pool) | "…and 40% more to flyers." | It also carries `skyward_gaze`: **+1 range against flyers** (`hunters_patience.tres` extra_rules, `tower.gd:6348`). That buff is hidden. | "…and 40% more to flyers, with +1 range against them." |
| Codex **Deeply Blighted** vs **Trophies** tip | Codex: "counts as 3 toward dispel counts". Trophies: "Deeply Blighted nightmares and bosses count 5." | Both are right for their own counters (`ELITE_DISPEL_COUNT 3`, `TROPHY_BIG 5`), but the Codex line reads as a rule for every card. | Codex: "…counts as 3 toward dispel counts (some cards say otherwise)." |
| Codex **Crowned Reaction** | "A Reaction on a nightmare that also carries a third status." | Avalanche needs a lobbed Shatter (Cairn / Rockslide), not a third status (`reactions.gd:727`). The Codex table lists Held as its third status, but Shatter already needs Held. A late crown also counts if the third status lands within 1 s (`CROWN_WINDOW`). | "…also carries a third status, or that lands within 1 s after (Avalanche: a Shatter from a thrown stone)." |
| **Shatter** (`reaction/shatter.tres`) | "A crit or heavy hit on it deals ×4 damage…" | It uses up the {held} (`reactions.gd:734`). "Heavy" is not linked: it means a {heavy} Warden, any Pebbling-family form, or a Warden that picks its target (`:724`). Shard share is 50% within 1 cell (`SHATTER_SPLASH`). | "A crit or a {heavy} hit on it deals ×4 damage; ice shards deal half of it to nightmares within 1 cell. Needs … Uses up the {held}." (add "Pebbling forms count as heavy" to the Heavy glossary) |
| **Thunderclap** text | No "Uses up" line | The code comment says it uses up the Static (`reactions.gd:999` comment) (check). The Crowned shape needs the line. | "…Uses up the {static}." |
| **Brittle** | "Uses up the {marked}." | It spends only the need (`spend_stacks(MARKED, need)`, `reactions.gd:2328`); with Brimming the extra stays. | "Uses up {stacks:need_marked} {marked}." |
| **Quick Reactions** (start pool) | "{reactions} can trigger on the same nightmare again after 0.75 s instead of 1.5 s." | Frost Reactions are excluded (`reactions.gd:1704`). Woven cards double the wait (`:1706`). | Tip: "Not Frost Reactions." |
| **Bellflower** Dream card (`dream_bellflower.tres`) | "one pulse in {field:bellflower.status_every} gives the nightmares around it {drowsy}" | Counted per nightmare per bell (`count_hit(id) % status_every`, `tower.gd:3954`), as the Warden text says ("Every 2nd ring on a nightmare"). Read per pulse, it suggests every nightmare gets Drowsy together. | "…every {field:bellflower.status_every}th ring on a nightmare gives it {drowsy}." |
| **Frost** tooltip | "it and up to 4 nightmares within 1 cell take damage" | Each nightmare takes at most 2 burst area hits per 0.5 s (`FROST_AREA_HITS`, `FROST_AREA_WINDOW`, `reactions.gd:2226-2227`). This only matters in big bursts. | Codex Frostburst tip: "A nightmare takes at most 2 burst hits every half second." |
| **Frostbite** | "It loses 2% of its max health (elites 1.5%, bosses 0.5%)." | Max-health damage, not a hit: it ignores the shell? (check `take_damage` tag frostbite). The cooldown is in row 9. | n/a unless the check shows a difference |
| **Nod Off** tip | "…don't triggered it." | Grammar. The rule matches (`keeping_time.gd:1590`; one first-Drowsy per nightmare, `DROWSED_META`). | "…don't trigger it." |
| **Undiluted** tip | "(10 with Brimming)" | Raw card name, not {card:brimming}; the number is right (`enemy_statuses.gd:789`). | "(10 with {card:brimming})" |
| **Witching Bend** tip | "({drowsy} still {full})" | Matches. "Offered after 20 {reactions}" is fine. | — |
| **Dawnbreak** tip | "Each nightmare sets one off at most once every 3 s." | Numbers match (`DAWNBREAK_WAIT 3`); "sets off" breaks rule 10. | "Each nightmare triggers one at most once every 3 s." |
| **Pinned** | "…and the {drowsy} when that set it off." | "set off" (rule 10). | "…and the {drowsy} if that triggered it." |

## 3. Checked and matching (no change)

Afterglow (5th link, 2 stacks, 2 cells, twice a second), Spent Light (4 s, 6 cells), Witching Bend (5 s / bosses 10 s,
half need), Reprise (1 s, half, 8 s), Knell (up to 3, 0.2 s, 6 s, own status counts), In Time (5th, 0.25 s), Refrain
(2 s, 4 s), Da Capo (6 s, 3 attacks), Rude Awakening (3 Wardens, 3 s), Nod Off (1 s, never bosses), Hailfall (40%,
3 within 1 cell), Conductive Soil (4, half, 2 cells, 1 s), Struck Twice (30%, 2 s), Flashover (half, 2+), Eddy (1 s),
Last Drop / Sodden / High Tide / Heavy Going / Steeped / Topped Up / Ebb / Wash Away, Overnight (2), Breathe It In
(1 / 3), Spore Huddle (3), Mycelium (3 Sprouts), Bearing Down, Finishing Blow, Open Road, Clean Strike, Nowhere to
Run, Standing Tall, Trophies, Measured Blow, The Tallest Tree (8, 2 procs), Old Hand (8th / 5th), Towering (+10% per
rank above II), Deep Grain, One Bough, Snare Line, Hard-Won Rings (40, V), Seedfall (fixed 10), Nipped in the Bud,
Cozy Corners, Passing Thread, Long Way Round, Switchback, Hobble, Walking Wood (2 s / 10 s), Headlong (a third),
Steadfast (0.4 s), Patient Roots, Root Web, Quick Reactions' −35%, Brimming's 2.2, Seeping (5 × 8%), Spore Cascade,
Undiluted's Damp 25% / sleep 2 s / Exposure 5 / Rooted echo half. Reactions: Ignite, Mushrooming, Night Terror,
Pinned, Sleepwalk, Smother, Lightning Rod, Thunderclap ×12 / ×6. Crowned: Avalanche, Still Pool, Fever Dream,
Fairy Circle, Nightbloom, Starfall, Changeling, Wide Awake, Tempest (2 s). Nurture choices (18% / 15% / 0.3 / 25%).
Charge glossary 16×, Exposure 25%, Drowsy 2% a stack, Soak 20%. Leaf or Dew (3 × 30), Wider Roots (4), Ascension from
drift 51.

## 4. Patterns

- **Limits live only in code.** Once-per-nightmare (Drown), cooldowns (Frost Reactions, Cold Snap) and caps (Thunderclap
  arcs, burst hits) are where a careful player gets punished. Every Reaction gets its per-nightmare limit in its text.
- **Retired cards keep their links.** Grove node text can't tell that `{card:x}` is retired. A test that fails on any
  `{card:}` token pointing at a retired card (Main Merger / Meta) would stop this coming back.
- **Defined-but-unread constants** (UNDILUTED_FROSTBURST) leave text promising effects the code doesn't deliver. Grep
  each number on a card for a reader, not only a definition.
- **"Asleep" is used for "full Drowsy"** (Great Bell, Bellflower node). These are two states with two rules; never swap
  them.
- **Corpus gap:** the Grove shows `sidegrade_description` by default (Hades perk style, `meta_run.gd:155`,
  `unlock_data.gd:74`), but the extractor read only `description`. Nine nodes' shown text (Clear Sight, Deep Taproot,
  Early Bloom, Early Light, First Care, Kindling, Rich Dew, Sprout Bed, Wider Dreams) went unread by the other seats.
  Add the field to `extract_corpus.sh`. (Deep Taproot's plain text says "up to +3" but the shown text says +2; the
  code caps at +2 in Hades, so the shown text is right.)

## 5. Conventions (fixed phrasings)

1. **Per-nightmare limits** close every Reaction and card that has one: "Once per nightmare." / "Each nightmare once
   every N s (bosses M s)."
2. **Caps** come right after the effect: "…arcs to up to 8 nightmares", "…up to +40%".
3. **Reach**: "within N cells" (straight line) or "N {steps}" (along the path). Never write {steps} for a code value
   measured in cells, or the other way round. One {step} = one cell.
4. **Asleep vs full Drowsy**: "falls {asleep} for N s" only where the code calls sleep; otherwise "reaches {full}
   {drowsy}". Add "Bosses never fall asleep." wherever sleep appears.
5. **Uses up**: every Reaction ends with "Uses up …", or "Uses up nothing." when it doesn't.
6. **Frost-made Frost**: "never enough to burst" whenever Frost comes from a burst, Windmill, Hoar Fog or a copy.
7. **Hidden extras**: when a card adds a rule through `extra_rules`, the text names it ("+1 range against flyers").
8. **Grove nodes** name only live cards; "Also adds" lines come from the node's `dream_cards`, filtered for retired.

## 6. What already works

The Crowned Reactions now read in one shape and their numbers match. The Frost texts use tokens, so the cap and boss
cap stay right automatically. The hit cards' numbers all match. The Calling rows survived the drift move with no
stale drift numbers. The Codex Card bonuses entry (cap, pool, speed) states the hidden stacking rules a veteran wants.
