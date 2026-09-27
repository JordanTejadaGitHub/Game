# Demo Scope

Phase 4, topic 13 of `design_plan.md`. Revised 2026-09-27: **no meta progression in the demo**,
and runs follow the 100-drift structure (`run_design.md`). The demo's job: **turn players into
wishlists** (Steam Next Fest and before it). It should show both hooks (`pitch.md`) and a
replayable run, then leave players wanting the Deep Wood and the Memory Grove.

## Shape

- **A demo run = acts 1–2: drifts 1–50**, with **the Hollow Stag** at 25 and **the Mire Hag** at
  50 ending the demo. About **45 minutes** at 1×, ~30 with fast-forward.
- **Unlimited replays, no progression.** Every run starts the same way (new random map, new
  Dreams), with nothing carried between demo runs.
- **Seeds are still earned and saved** (not spendable in the demo). They carry into the full game
  (`meta_design.md`, "Seeds from the demo").
- **Mid-run save** works in the demo too (autosave at every rest).
- Dispelling the Mire Hag ends the run with a victory screen: *"Deeper in the dream, something
  larger stirs…"*, the Seeds earned and banked, a **Wishlist** button, and a **teaser of the Memory Grove**
  (see below).

## In the demo

| Area | Included |
|---|---|
| Wardens | **To be decided after playtesting** (2026-09-27): a **Test Grove** mode unlocks every Warden so all of them can be tried first (below). Starting proposal: Sprout, Thornwall (+ Bramble); **Sporeling, Firefly Jar, Dewdrop** as family picks, with their 6 branches |
| Family picks | after drift 1 and after the Hollow Stag (drift 25): **2 families per run**, so cross-family combos (Storm Grid) are reachable |
| Final forms | **shown but locked** ("in the full game") on Dream cards |
| Dreams | after drifts 5, 10, … 45 (**9 per run**; the drift 25 one guaranteed Rare+), from the Start pool (no Legendaries) |
| Nightmares | act 1: Shade, Husk, Mourner, **the Hollow Stag**; act 2: 3 maze testers from `enemy_design.md`: **Phantom** (glides through walls), **Night Hound** (sprints down straight corridors) and the **Procession** (Lantern Bearer + Wraiths), plus **the Mire Hag** (plan in `acts_1_2.md`) |
| Act 2 boss | **always the Mire Hag** in the demo (the full game picks the Hag or the Moth Queen); the Hag needs no extra nightmares, the Moth Queen needs Lurkers and flying |
| Map | the forest biome, fully procedural (ridges, tending) |
| Story | the intro, and **Memory 1** as a story hook on the victory screen |
| Onboarding | everything in `onboarding.md` for run 1 (Grove parts replaced by the teaser) |
| Basics | title screen, settings (audio, display, key rebinding), pause, speed controls, results screen, save |

### The Memory Grove teaser

After every demo run, the results screen shows the Grove **greyed out and asleep**, with the
player's banked Seeds: *"In the full game, every run grows your Memory Grove. Your 214 Seeds will
be waiting."* It sells the meta without building it for the demo.

### Test Grove (developer playtest mode, not shipped)

To choose the demo roster by playing, not guessing. A toggle (settings "Developer" section, or a
launch flag) that starts a normal run with:
- **every Warden family** in the Warden bar from drift 1 (no family picks needed);
- **every branch, final form, hidden branch and Memory Warden** evolvable without its Dream (still
  costs Dew);
- a **"+500 Dew"** hotkey and a **skip to drift N** option, so late-game Wardens can be tested fast;
- everything else normal (drifts, bosses, Dreams still offered for their other effects).

While testing, note for each Warden: fun?, readable?, too strong / too weak?, needs art or sound
work? Then pick the demo families (2–3) and branches from the notes. Must be off (and hidden) in
demo and release builds.

## Not in the demo

Acts 3–4, the Moth Queen and The Hollow Oak, the other act 2 nightmares, Pebbling / Rootling /
Acorn, final forms, Legendary Dreams, the Memory Grove (spending Seeds), Memories 2–10, Blight
Levels, the true ending, the Forest Journal.

## Decisions

| Question | Decision |
|---|---|
| Meta in the demo | **None**; replay freely, no progression |
| Seeds | **Earned and saved; all of them carry into the full game** |
| Mid-run save | **Yes** |
| Length | **Drifts 1–50** (acts 1–2, two bosses, two family picks) |
| Steam Deck | recommended: at least **Deck-playable** (mouse-style cursor on the stick) |
| Languages | English first, all text through the localization system |

## Things to watch

- **Demo Seeds carry over in full.** A demo win (50 drifts, two bosses) earns roughly 90 Seeds, so
  a player who replays the demo 15 times could start the full game with over half the Grove bought.
  If that feels like it skips too much, a cap (e.g. 500 Seeds) is an easy change later.
- **Content cost.** 50 drifts means the demo needs act 2's creatures and a second boss finished
  and polished (art, animation, sound), not just act 1's.
- **Length.** 45 minutes per run is long for a demo; the mid-run save and speed controls matter,
  and the Hollow Stag at drift 25 is a natural "I've seen enough to wishlist" point for busy players.

## Must be true before the demo is public

- **All art is original.** The Foozle tileset and creature placeholders can't ship in a public
  demo unless their licence clearly allows it; since the plan is to replace them anyway, replace
  them first: tileset (grass, path, border, Withered Tree, Mossy Boulder), Shade, Husk, Mourner +
  Sob, the Hollow Stag, Phantom, Night Hound, Lantern Bearer + Wraith, the Mire Hag.
- **The three marketing moments are polished** (`pitch.md`): the dispel, the live re-route, and
  the Sporeling.
- **Audio exists:** calm music for build and drift, a boss track, and good SFX, especially the
  dispel sound, and whispers/signature sounds for each nightmare.
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

- Median demo playtime **over 45 minutes**.
- Share of players who **reach the Hollow Stag** (drift 25), **dispel the Mire Hag** (drift 50), and
  **start a second run**.
- **Wishlists per demo player** (Steam shows both).
- Where players quit (which drift? the first Dream?), from playtests and feedback.

An in-game feedback link (form or Discord) on the pause menu and victory screen helps collect this.
