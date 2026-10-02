# Demo Scope

Phase 4, topic 13 of `design_plan.md`. Revised 2026-09-27: **no meta progression in the demo**,
and runs follow the 100-drift structure (`run_design.md`). The demo's job: **turn players into
wishlists** (Steam Next Fest and before it). It should show both hooks (`pitch.md`) and a
replayable run, then leave players wanting the Deep Wood and the Memory Grove.

## Shape

- **Now (2026-09-27, user decision): the demo runs all 100 drifts**, like the full game: the Hollow
  Stag (25), the Mire Hag (50), the Moth Queen (75), the Hollow Oak (100; `acts_3_4.md`). About
  1.5–2 hours at 1×.
- **Decided (2026-09-28): the public demo is 100 drifts.** The full game's reasons to buy are the
  Memory Grove, more families, Memories and the true ending, Blight Levels. Every nightmare needs
  finished art and sound before the demo is public.
- **Unlimited replays, no progression.** Every run starts the same way (new random map, new
  Dreams), with nothing carried between demo runs.
- **Seeds are still earned and saved** (not spendable in the demo). They carry into the full game
  (`meta_design.md`, "Seeds from the demo").
- **Mid-run save** works in the demo too (autosave at every rest).
- Dispelling the Hollow Oak ends the run with a victory screen (if the demo ends at 50: the Mire
  Hag, *"Deeper in the dream, something larger stirs…"*), the Seeds earned and banked, a **Wishlist** button, and a **teaser of the Memory Grove**
  (see below).

## In the demo

| Area | Included |
|---|---|
| Wardens | **Decided (user, 2026-09-28; Bellflower added 2026-10-01, meta_design.md a3375108): Sporeling, Firefly Jar, Dewdrop and Bellflower are the demo's families** (the same four every new full-game account starts with), with their branches and final forms (Dreamlight unlocks), plus Sprout and Thornwall (+ Bramble, Honeysuckle). The four family picks (drift 1, 25, 50, 75) can each offer a family you lack, so the drift 75 pick is never empty. Pebbling, Rootling, Acorn, Nestling and Whirligig are full-game only (dev toggles "Test Grove" / "Unlock all families" can still show them in debug builds) |
| Family picks | after drift 1 and after the bosses at 25, 50 and 75 (a pick with nothing left to offer gives +2 Dreamlight; Family Blessings are Rare Dream cards now, not pick fillers) |
| Final forms | **shown but locked** ("in the full game") on Dream cards |
| Kinships | **Slumber Rot, Rainfog, Storm Beacon** (the demo families' main Kinships) and **Kindred** (`tower_design.md` "Kinships"). Whole Tree and hidden Kinships need Grove unlocks, so full game only |
| Dreams | after drifts 5, 10, … 95 (**19 per run**; boss Dreams guaranteed Rare+), from the Start pool |
| Nightmares | acts 1–2 as in `acts_1_2.md` (Shade, Husk, Mourner, Phantom, Night Hound, Procession, the Hollow Stag, the Mire Hag) and acts 3–4 as in `acts_3_4.md` (the whole roster, the Moth Queen, the Hollow Oak) |
| Act 2 boss | **always the Mire Hag** in the demo; the full game draws from a pool of 3 per act (`enemy_design.md`, boss pools). Open question: should the demo's act 1 already draw from its pool (Hollow Stag / Night Mare / Scarecrow) to show off the feature, at the cost of two more bosses before launch? |
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
demo and release builds, and **Test Grove runs don't bank Seeds**.

**Demo mode toggle** (added 2026-09-27, user request): Settings → Developer → **Demo mode** on/off,
overriding the `game/demo` project setting at runtime, so the full game (Memory Grove, Blight
Levels, Seeds spending) and the demo (Grove teaser, Wishlist) can both be tested from one build.
Debug builds only; exported builds always use the project setting. Switching returns to the title
screen. Full-game runs made this way use the real profile, so it's clearly labelled.

**Unlock all families** (added 2026-09-27): a second developer toggle for testing the *core game*:
normal runs (family picks, Dreams, Dew, difficulty all as usual) but with **every family in the
pick pool** and their Grove Dream cards, as if the Memory Grove had unlocked everything. Doesn't
touch the real profile; runs don't bank Seeds. Unlike Test Grove, nothing is free or pre-unlocked.

**Dev Grove** (added 2026-09-28, user request: "unlock every Grove node for developer"): Settings →
Developer → **Dev Grove: Off / Early / Half / Full**. It plays normal runs *and* opens the Memory
Grove screen as if the profile had that much of the tree, using the balance simulation's presets
(`MetaRun.load_preset`; Full = every node at max level, all 6 perk slots incl. the secret one). Perks, families, card
bundles, Ascension nodes, Blight Levels and loadouts all work, so any Grove content can be tested.
- Uses a separate dev profile (`user://sim_heartwood.json`); the real profile is never read or
  written while it's on. Loadout changes and purchases in the Grove screen stay in the dev profile
  (reset to the preset when the option changes).
- Counts as a dev run (`MetaRun.is_dev_run()`): no Seeds banked, no records, milestones or
  whispers written. The HUD and Grove show a small "Dev Grove: Full" tag.
- Turns **Demo mode** off while on (the Grove only applies in the full game). Debug builds only.
  Can combine with Test Grove and Unlock all families.

**Reset to a new profile** (added 2026-09-30, user request: "add an option for devs to reset to a
new profile"): Settings → Developer → **Start over as a new profile**, debug builds only.
- Two-step confirm in the panel itself ("This resets your Memory Grove, Seeds, records,
  discoveries and Codex. Your settings and run history stay." → **Reset** / Cancel).
- **Backs up first:** copies `user://heartwood.json` to `user://heartwood.backup-<date-time>.json`
  (keeps the last 5), so nothing is lost by accident. A "Restore last backup" button sits next to it.
- Resets everything the profile holds (Grove nodes, Seeds, run counts, milestones, Blight, account
  knowledge: combos / nightmares / Dreams / chains seen, whispers, intros, last first pick, boss
  records), **keeps settings** (volumes, keybinds, the Developer toggles), deletes the saved run
  (`run.json`), and **keeps `run_history.json` and `builds.json`** (balance data).
- Returns to the title screen as a first launch (first-run whisper, first-run Seed bonus).

**Pick any card** (added 2026-09-28, user request: "for the dev run, allow picking cards from all
the card selection"): in **any dev run** (Test Grove, Unlock all families or Dev Grove), the Dream
screen gets a **"Dev: any card…"** button beside "Let it pass". It opens a searchable grid of **every
Dream card in the game** (all rarities, Grove-only and Legendary included, Deepened too), filtered by
name, tag, rarity and family, each with its full text and a "not normally offered: needs …" note
when its Needs aren't met. Taking one counts as this Dream's pick (Lucid Dreaming: one of its picks).
Also reachable from the Test Grove panel at any time (the existing "Take any Dream"), and the
Remember screen gets a matching "Dev: unlock free" toggle. Debug builds only; never in the demo or
release.

**Test tools v2** (added 2026-09-27: first test showed combos and impact couldn't be judged):
- **Spawn panel:** pick a nightmare type, a count and "elite", spawn at the start now.
- **Target Dummy:** a slow, unkillable nightmare that walks the route on a loop; shows the damage
  per second it's taking, and from whom.
- **Damage meter:** every Warden's damage this drift and per second, including its status damage
  and its share from combos (e.g. Stormcap: 40% of its damage came from jumps between Damp
  nightmares).
- **Damage numbers** toggle (see `screens_ui.md`, combat feedback).
- **Inspect:** click a nightmare while paused to see its statuses, stacks and the damage breakdown
  (base × family resist/weak × Marked × crit).
- **Invulnerable Heartwood** toggle (leaves can't fall) and **clear the field** button, so a test
  can run as long as needed.

**Built** (2026-09-27): Settings → Developer → Test Grove (applies from the next run), or launch
with `-- --test-grove`; debug builds only. Tools panel on the left: +500 Dew (or **F9**), and "Skip
to drift N" at a rest.

## Not in the demo

Acts 3–4, the Moth Queen and The Hollow Oak, the other act 2 nightmares, Pebbling / Rootling /
Acorn, final forms, Legendary Dreams, the Memory Grove (spending Seeds), Memories 2–10, Blight
Levels, the true ending, the Forest Journal.

## Decisions

| Question | Decision |
|---|---|
| Meta in the demo | **None** for now; replay freely, no progression. Demo runs play the fresh-profile curve (`run_design.md` "Difficulty curve targets": wins are rare). **Maybe later: a few Memory Grove unlocks** as a taste of the meta (user, 2026-09-28) |
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
