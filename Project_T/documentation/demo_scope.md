# Demo Scope

Phase 4, topic 13 of `design_plan.md`. Revised 2026-09-27: **no meta progression in the demo**,
and runs follow the 100-drift structure (`run_design.md`). The demo's job: **turn players into
wishlists** (Steam Next Fest and before it). It should show both hooks (`pitch.md`) and a
replayable run, then leave players wanting the Deep Wood and the Memory Grove.

## Shape

- **A demo run = act 1: drifts 1–25**, ending with the **Old Stag**. About **20–25 minutes** at 1×.
- **Unlimited replays, no progression.** Every run starts the same way (new random map, new
  Dreams), with nothing carried between demo runs.
- **Seeds are still earned and saved** (not spendable in the demo). They carry into the full game
  (`meta_design.md`, "Seeds from the demo").
- **Mid-run save** works in the demo too (autosave at every rest).
- Beating the Old Stag ends the run with a victory screen: *"The Deep Wood awaits…"*, the Seeds
  earned and banked, a **Wishlist** button, and a **teaser of the Memory Grove** (see below).

## In the demo

| Area | Included |
|---|---|
| Wardens | Sprout, Thornwall (+ Bramble); **Sporeling, Firefly Jar, Dewdrop** as family picks, with their 6 branches |
| Family picks | after drift 1 (1 of 3); see the open question below about a second pick |
| Final forms | **shown but locked** ("in the full game") on Dream cards |
| Dreams | after drifts 5, 10, 15, 20 (4 per run), from the Start pool minus Legendaries |
| Creatures | Leaf Bug, Bark Beetle, Puffcap, **Old Stag** (act 1 plan in `run_design.md`) |
| Map | the forest biome, fully procedural (ridges, tending) |
| Story | the intro, and **Memory 1** as a story hook on the victory screen |
| Onboarding | everything in `onboarding.md` for run 1 (Grove parts replaced by the teaser) |
| Basics | title screen, settings (audio, display, key rebinding), pause, speed controls, results screen, save |

### The Memory Grove teaser

After every demo run, the results screen shows the Grove **greyed out and asleep**, with the
player's banked Seeds: *"In the full game, every run grows your Memory Grove. Your 214 Seeds will
be waiting."* It sells the meta without building it for the demo.

## Not in the demo

Acts 2–4 and their bosses, Pebbling / Rootling / Acorn, final forms, Legendary Dreams, the Memory
Grove (spending Seeds), Memories 2–10, Blight Levels, the true ending, the Forest Journal.

## Decisions

| Question | Decision |
|---|---|
| Meta in the demo | **None**; replay freely, no progression |
| Seeds | **Earned and saved; all of them carry into the full game** |
| Mid-run save | **Yes** |
| Steam Deck | recommended: at least **Deck-playable** (mouse-style cursor on the stick) |
| Languages | English first, all text through the localization system |

## Open question: one family per demo run?

Families come after drift 1 and at bosses, so a demo run (drifts 1–25) has **only one family**.
That shows evolution well, but **cross-family combos** (the Storm Grid "lightning through soaked
creatures" moment in `pitch.md`) can't happen in the demo.

Options:
- **A (recommended): demo-only second family pick at drift 15.** Shows combos; the full game keeps
  its structure.
- B: keep one family; the demo sells depth, and combos are a full-game promise.

Also worth watching: **all demo Seeds carry over**, so a player who replays the demo 20 times
could start the full game with half the Grove bought. If that feels like it skips too much, a cap
(e.g. 500 Seeds) is an easy change later.

## Must be true before the demo is public

- **All art is original.** The Foozle tileset and creature placeholders can't ship in a public
  demo unless their licence clearly allows it; since the plan is to replace them anyway, replace
  them first: tileset (grass, path, border, Withered Tree, Mossy Boulder), Leaf Bug, Bark Beetle,
  Puffcap, Old Stag.
- **The three marketing moments are polished** (`pitch.md`): the cleanse, the live re-route, and
  the Sporeling.
- **Audio exists:** calm music for build and drift, a boss track, and good SFX, especially the
  cleanse sound.
- **Stable:** no crashes, saves never lost (mid-run saves and banked Seeds), the path rule never
  broken.
- **Credits** screen (Godot MIT notice and any licences).

## Timeline

1. **Steam store page up first** (as early as possible, for wishlists; needs capsule art,
   screenshots, a short trailer).
2. **Private playtest** of the demo build with a few players (Steam playtest or keys); fix what
   confuses them.
3. **Public demo 1–2 months before a Next Fest**, so it has feedback and some wishlists before
   the festival.
4. **Next Fest** (they run in February, June and October; sign up well ahead through Steamworks).
   Prepare a press kit, a short gameplay video, and demo update notes.

## How to know it's working

- Median demo playtime **over 30 minutes** (more than one run).
- Share of players who **reach the Old Stag**, and who **start a second run**.
- **Wishlists per demo player** (Steam shows both).
- Where players quit (which drift? the first Dream?), from playtests and feedback.

An in-game feedback link (form or Discord) on the pause menu and victory screen helps collect this.
