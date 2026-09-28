# First Runs: onboarding

Phase 4, topic 10 of `design_plan.md`. Goal: across the **first 3 runs** a new player learns the
core mechanics *and* the meta loop, without a separate tutorial mode. This is also what the demo
has to nail (`pitch.md`).

## Principles

- **Teach by doing, one thing at a time.** Each lesson appears the first time it matters, and is
  dismissed by doing the thing, not by clicking "OK".
- **The Heartwood speaks.** Hints are one-line italic whispers at the top of the screen, in the
  story's voice (*"They're coming for the dream. Don't let them reach me."*). No tutorial windows, no walls of text.
- **Never punish learning.** Run 1 is a real run, but the first drifts are gentle and Seeds are
  guaranteed, so even a quick loss moves the player forward.
- **Hide what isn't needed yet.** Systems appear when the player can use them (see the table
  below).
- **Skippable.** A "Heartwood whispers" setting (on / off) for experienced players; restarting the
  first-run tips is also possible from settings.

## Run 1: the core loop (and the first taste of meta)

Runs are 100 drifts (`run_design.md`), so nearly all teaching happens in **act 1 (drifts 1–25)**;
a new player's first run will usually end (and open the Grove) somewhere in act 1 or 2. Lessons
trigger at these moments:

| When | Lesson | How |
|---|---|---|
| Run start | Where nightmares go | Camera glides along the path from the dark forest edge to the Heartwood. *"Something moves at the edge of the dream."* |
| Build phase 1 | Planting | The Sprout button glows; a soft highlight on a good cell beside the path. *"Plant a Warden near the path."* Start Drift pulses once one is placed. |
| First dispel | What they are | A brief slow-motion as the Shade shrieks and cracks into light. *"Nightmares. They're coming for the dream. Don't let them reach me."* The Dew motes and counter pulse. |
| After drift 1 | First family | The family pick (1 of 3 base Wardens). *"The Heartwood stirs, and remembers an old friend…"* Card text explains Sprouts growing into it. |
| Right after the pick | **Towers are walls** | *"Wardens are walls. Make them take the long way."* The route preview is emphasised; a "+N path" tag on the ghost; the path length counter appears. |
| Drift 2 starts on its own | Drifts flow | *"They don't stop. They come in drifts, like fog."* The Auto-drift toggle glows once. |
| First rest (after drift 5) | Dreams and rests | The first Dream. *"The Heartwood stirs, and dreams of…"* Then: *"Rest here. Rearrange the forest while they're gone."* (75% refunds during rests) |
| First rest | Saving | *"The forest will wait for you."* Save & Quit is highlighted once. |
| First blocked placement | The dream's rule | The ghost turns red. *"A dream can bend, but never close."* |
| First affordable evolution | Growing | The Sprout under the cursor shimmers. *"This Sprout could grow."* |
| First hover on an obstacle | Obstacles | Before clearing is unlocked: *"Dead wood. I can't move it… yet."* (the hover tag says a clearing Dream is needed). After the first clearing card: *"Tend the forest, and it will remember you."* (+1 Seed at run end) |
| First leaf lost | Stakes | The leaf counter shakes. *"It fed. A leaf blackens and falls."* |
| Drift 2 starts | Speed and pause | The speed buttons glow once. *"Pause if you need to think. They'll wait."* |
| First sell | Refunds | A tooltip on the sell button: 75% during a rest, half while nightmares walk. |
| Rest before drift 25 | Bosses | The Hollow Stag's silhouette appears at the forest edge, antlers burning. *"Something old has found the dream."* |
| After the Hollow Stag | New family | The second family pick. *"It's gone, and something I'd forgotten came back."* |

**Run end (win or lose):**
1. Dormancy (or victory) moment: *"The Heartwood sinks into dreamless sleep. A seed falls, and
   remembers."*
2. **Results screen** with the Seeds breakdown (drifts, dispelled, bosses, tended).
3. **First-run bonus: +20 Seeds** ("The first seed"), so a very early loss still affords an
   unlock.
4. **The Memory Grove opens for the first time.** Memory 1 plays (*"Before the Heartwood, there
   were two trees…"*). The Heartwood guides the first purchase: 2–3 cheap unlocks glow (e.g.
   Morning Stores I, Charged Bloom, Pebbling line).
5. *"The Heartwood dreams again."* → Start run 2.

## Run 2: seeing the meta pay off

- The first Dream that comes from a Grove unlock is marked with a small leaf badge: *"Remembered
  from a past dream."* This closes the loop: runs → Seeds → new things in the next run.
- **Branches** and **statuses** are taught when the player first gets one: when a Warden first
  applies a status, its icon appears over the nightmare with a one-time tooltip (*"Soaked: slower,
  and lightning loves it"*).
- **Let it pass** and **call early** get one-time hints the first time they're available.

## Run 3 and after: rhythm

- By now the player has ~5 unlocks; the **second Memory** arrives around here (one every 3
  unlocks), establishing the story rhythm.
- Grove roots beyond the first become the focus (perks vs new Wardens: the first real meta choice).
- No more whispers except for genuinely new things (new nightmare, first Legendary, act 2).

## When each system appears

| System | Appears |
|---|---|
| Sprout, Thornwall, Start Drift, Dew, leaves | run 1, drift 1 |
| First family pick | run 1, after drift 1 |
| Route preview "+N path", path length | run 1, right after the first pick |
| Drift flow, Auto-drift | run 1, drift 2 |
| Dreams, rests, Save & Quit | run 1, first rest (after drift 5) |
| Evolving | run 1, first affordable |
| Obstacles (fixed) | run 1, first hover |
| Tending | after the first clearing Dream card |
| Speed, pause, selling | run 1, drift 2 or first use |
| Bosses, second family pick | run 1, drift 25 |
| Memory Grove, Seeds, Memories | end of run 1 |
| Statuses, branches | first time owned (usually run 1–2) |
| Let it pass, call early | first time available |
| Rerolls, banish | when bought in the Grove |
| Legendary Dreams | act 2 (usually run 2–4) |
| Blight Levels | after the first win |
| Forests root | after the first win (shown greyed before, as a promise) |

## Forest Journal (later: not in the first playable or demo)

A bestiary on the title screen: each nightmare gets an entry (art, a line of unsettling lore, its
trait) the first time it's dispelled, and each Warden when first grown. It gives curious players a
place to look things up without tutorials, rewards seeing new things, and adds a completionist
goal. Entries could double as milestone progress (e.g. *"Dispel every kind of nightmare once"*).

## Demo fit

The demo has no meta (`demo_scope.md`): a demo run is acts 1–2 (drifts 1–50), taught exactly as
run 1 above. At the end, the Grove parts are replaced by a **teaser** (the Grove asleep, with the
player's banked Seeds) and a wishlist screen.
