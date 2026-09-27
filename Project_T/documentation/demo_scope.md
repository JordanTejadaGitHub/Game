# Demo Scope

Phase 4, topic 13 of `design_plan.md`. The demo's job: **turn players into wishlists** (Steam Next
Fest and before it). It should show both hooks (`pitch.md`), the roguelite loop, and the meta
paying off, then leave players wanting acts 2 and 3.

## Shape

- **A demo run = act 1**: drifts 1–5, ending with the **Old Stag**. About **10–12 minutes**.
- **Demo Dream schedule: a Dream after drifts 1, 2, 3 and 4** (4 per run). The full game's
  schedule would give only 2 Dreams before the boss, too few to feel like a roguelite.
- **Target playtime: 30–60 minutes** across 3–5 runs, with the Grove giving a reason to replay.
- Beating the Old Stag ends the run with a victory screen: *"The Deep Wood awaits…"*, a
  **Wishlist** button, and the seeds/Grove flow as normal.

## In the demo

| Area | Included |
|---|---|
| Wardens | Sprout, Thornwall (+ Bramble), **Sporeling, Firefly Jar, Dewdrop** and their 6 branches |
| Final forms | **Shown but locked** ("in the full game"): a teaser on Dream cards and in the Grove |
| Dreams | first-playable pool minus Legendaries (~28 cards), including **Conductive Soil**, so the Storm Grid "wow" moment (lightning through soaked creatures) is reachable |
| Creatures | Leaf Bug, Bark Beetle, Puffcap, **Old Stag** (the act 1 list in `run_design.md`) |
| Map | the forest biome, fully procedural (ridges, tending) |
| Meta | Seeds, a **demo Grove of ~8 unlocks** (Morning Stores I–II, Deep Taproot I, Second Thoughts I, Static Bloom, Twin Puff, Static Field, Seedling Gift), completable in ~4–5 runs |
| Story | **Memories 1–3** (the setup, ending on a hook), rest shown as locked leaves |
| Replay | **Blight Levels 1–3** after the first demo win (great for streamers) |
| Onboarding | everything in `onboarding.md` runs 1–2 |
| Basics | title screen, settings (audio, display, key rebinding), pause, results screen, save |

## Not in the demo

Acts 2–3 and their bosses, Pebbling / Rootling / Acorn lines, final forms, Legendary Dreams, the
Forests root, Memories 4–10 and the true ending, Blight Levels 4–10, the Forest Journal.

## Decisions to make

1. **Carry demo progress into the full game?** Recommended **yes**: *"Your Grove will be waiting."*
   It's cheap if the demo uses the same save format, and it's a strong reason to wishlist.
2. **Steam Deck / controller in the demo?** Recommended: at least **Deck-playable** (mouse-style
   cursor on the stick), because Next Fest has many Deck players; full controller polish can come
   later.
3. **Languages:** English at launch of the demo, but all text through the localization system so
   others can be added (cozy games sell well in German, Japanese and Chinese).

## Must be true before the demo is public

- **All art is original.** The Foozle tileset and creature placeholders can't ship in a public
  demo unless their licence clearly allows it; since the plan is to replace them anyway, replace
  them first: tileset (grass, path, border, Withered Tree, Mossy Boulder), Leaf Bug, Bark Beetle,
  Puffcap, Old Stag.
- **The three marketing moments are polished** (`pitch.md`): the cleanse, the live re-route, and
  the Sporeling.
- **Audio exists:** a calm music track per act-1 phase (build / drift / boss) and good SFX,
  especially the cleanse sound.
- **Stable:** no crashes, saves never lost, the path rule never broken.
- **Credits** screen (Godot MIT notice and any licences).

## Timeline

1. **Steam store page up first** (as early as possible, for wishlists; needs capsule art,
   screenshots, a short trailer).
2. **Private playtest** of the demo build with a few players (Steam playtest or keys); fix what
   confuses them.
3. **Public demo 1–2 months before a Next Fest**, so it has feedback and some wishlists before
   the festival.
4. **Next Fest** (they run in February, June and October; sign up well ahead through Steamworks).
   Prepare a press kit, a short livestream/gameplay video, and demo update notes.

## How to know it's working

- Median demo playtime **over 30 minutes**.
- Share of players who **reach the Old Stag**, and who **play a second run**.
- **Wishlists per demo player** (Steam shows both).
- Where players quit (the first drift? the first Dream?), from playtests and feedback.

An in-game feedback link (form or Discord) on the pause menu and victory screen helps collect this.
