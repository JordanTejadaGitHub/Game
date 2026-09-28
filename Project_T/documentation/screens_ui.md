# Screens and HUD

Phase 4, topic 11 of `design_plan.md`. Many of these screens already exist in the game
(`scripts/ui/`); this doc is the **target** for layout, content and behaviour, so they feel like one
game. The checklist at the end lists what to compare against the current build.

## Principles

1. **The forest comes first.** The maze is the game: HUD elements hug the screen edges and never
   cover the middle of the map. Nothing permanent sits over the path.
2. **Glance, then dig.** The HUD shows only what you need every few seconds (leaves, Dew, drift,
   speed). Everything else appears on hover or selection.
3. **One icon language.** The same icon everywhere for Dew (a drop), leaves (a leaf), Seeds (a
   seed), each status, each rarity. Icons differ in **shape, not only colour** (see
   `design_plan.md`, accessibility).
4. **Time stops for choices.** Family picks, Dreams and Omens pause the game; nothing is ever
   decided under time pressure.
5. **Never cover the map's ends.** The camera must be able to scroll so that every part of the
   map, especially the start and **the Heartwood**, can sit clear of the HUD (let the camera go a
   little past the map edges by the HUD's size). Panels never overlap each other: one left panel at
   a time (Warden panel), dev tools elsewhere (below).
6. **Readable on a Steam Deck.** Designed at 1920×1080, must work at 1280×800: body text at least
   16 px there, buttons at least 48 px tall, and a UI scale setting.

## Screen flow

```
Title ─┬─ Continue (saved run) ─────────────┐
       ├─ New Run (Blight Level picker*) ───┤
       ├─ Memory Grove ─ Memories viewer    ├─→ Run ─→ Results ─→ Memory Grove ─→ Title / New Run
       ├─ Settings                          │     └─ overlays: family pick, Dream, Omen, pause
       ├─ Credits                           │
       └─ Quit                              │
* after the first win
```

**Demo:** no Memory Grove button (a greyed teaser instead), a **Wishlist** button on the title and
results screens; results lead back to the title.

## The run HUD

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ ❦ 18/20   💧 245        Act 1 · Forest's Edge   Drift 7 / 100        ⚙ Menu  │
│ Dreams: ◆◆◇◆            ● ● ○ ○ ○  Hollow Stag in 18    Path 132 tiles      │
│                         [Omen: Swift Stream]                                 │
│                   ~ "Wardens are walls. Make their walk longer." ~           │
│                                                                              │
│  [Warden panel]                    (the forest)              [Creature info] │
│  (on selection)                                              (on hover)      │
│                                                                              │
│                  [1 Sprout 10][2 Wall 3][3 Sporeling 25]…   [Start Drift 8 ⏎]│
│                                                             [Auto ✓] II 1× 2× 3×│
└──────────────────────────────────────────────────────────────────────────────┘
```

| Zone | Shows | Behaviour |
|---|---|---|
| **Top right: resources** (as built) | Dew, Dreamlight, leaves (current / max), path length | leaves flash and shake when one is lost; Dew flashes red when you can't afford something; Dew motes float up from dispelled nightmares; path length pulses when it changes |
| **Top left: Dreams** (as built) | one small icon per Dream taken this run (rarity shape + colour, stack count, live bonus) | hover or tap for the card; click opens "Dreams this run" (all cards + stack counts) |
| **Top centre: drift** | act and name, drift / 100, **5 pips for the current block**, countdown to the next boss | pips fill as drifts arrive; the boss countdown turns into the **boss health bar** during a boss drift |
| **Under drift: Omen** | the active Omen, if any | hover for its effect and reward |
| **Top centre, lower: whispers and toasts** | Heartwood whispers (italic, teaching) and event toasts (plain: rest bonus, act start, trampled wall, boss lines) | whispers stay until done; toasts fade after ~2.5 s |
| **Menu** | pause menu button | with the drift controls or top right, clear of the resources |
| **Bottom centre: Warden bar** | every Warden you can plant, with hotkey and cost | unaffordable = faded (still selectable, the ghost shows red); new families slide in after a pick |
| **Bottom right: drift controls** | Start / Call early (shows the Dew bonus), Auto-drift, pause, 1×/2×/3×, status line ("Resting: rearrange freely") | the Start button pulses during rests |
| **Left: Warden panel** | on selecting a Warden (below) | closes on Esc / right-click / clicking empty ground |
| **Right: nightmare info** | on hovering a nightmare (below) | follows the most recently hovered one |

**Dev panels (Test Grove tools, damage meter):** docked on the **right side**, under the
resources, collapsible with one key (F10), never overlapping the Warden panel or the Warden bar.

### The Clear tool

Added 2026-09-27 (user request). Clearing trees and rocks is a **tool on the Warden bar**, like
planting a Warden, instead of clicking obstacles directly. That also stops clears clashing with
drag-select and works on touch (`platforms.md`).

- **The button** sits at the **left end of the Warden bar**, set slightly apart, with its own icon
  (tending hands around a small sprout; art to make) and hotkey **0** (and **C**). A small badge
  shows **free clears** from Heartwood's Reach when you have any.
- **Before clearing is unlocked** (no clearing Dream yet, `dream_design.md`): the button shows
  **locked**; tapping it explains *"Take a clearing Dream to tend the forest."* Once unlocked it
  lights up with a short glow and the whisper *"Tend the forest, and it will remember you."*
- **Using it:** select the tool (click / 0 / C) → the cursor changes → hovering an obstacle shows
  its outline, cost (or "free") and the **route preview** → click to clear. The tool **stays
  active** for more clears until Esc, right-click or picking a Warden. On touch: tap an obstacle,
  then **✓**.
- **Without the tool**, clicking an obstacle does nothing but show its name (so box-select can start
  anywhere).

## In the world

| Element | Design |
|---|---|
| **Build ghost** | the Warden on the hovered cell, green/red; range circle; **route preview line**; tag above: **"+12 path"** (or "−4 path") and the cost, red if unaffordable |
| **Invalid placement** | red ghost + a short reason tag ("would close the dream", "nightmare here", "can't afford") |
| **Obstacle hover** | name only (e.g. "Withered Tree"); clearing happens through the **Clear tool** (below). With the tool active: outline + "Tend Withered Tree · 5 Dew" + route preview if clearing changes it |
| **Health bars** | only once a nightmare is hit (setting: always) |
| **Status icons** | up to 3 small icons above a nightmare, most important first; each status has its own **shape** (Damp droplet, Drowsy "z", Spored dots, Marked ring, Static bolt, Held vine) and a stack number where relevant |
| **Elites** | Deeply Blighted nightmares: black haze + a small swirl icon, larger sprite |
| **Bosses** | a name plate on arrival ("The Hollow Stag"), the screen edges darken; the top-centre boss bar with health and a marker at 50% (where its behaviour changes) |
| **Leak** | when a nightmare reaches the Heartwood: it lunges into the tree, a leaf blackens and falls, a dark pulse at the goal, the leaves counter shakes |
| **Selected Warden** | range circle + a soft outline; its status field (clouds, fog) highlighted |

## Combat feedback: seeing what works

Added 2026-09-27 after the first playtest: the player couldn't tell whether combos fired or which
Wardens mattered. Builds are the heart of the roguelite, so **the game must show them paying off**.

| Feedback | Design |
|---|---|
| **Combo callouts** | a short word pops over the nightmare when a synergy fires, in the triggering Warden's colour: *Conducted!* (lightning through Damp), *Popped!* (Puffball burst), *Asleep!* (Dreamshroom), *Splintered!* (crit splash from *Shattering Blow*), *Weak!* (family weakness). Reactions have their own callouts (below). Throttled so a busy maze shows a few at a time, never a wall of text |
| **Damage numbers** | setting: **off / big hits only (default) / all**. Crits larger with a ping; weakness hits bright; resisted hits small and grey; status ticks tiny, **in the status's colour** (Spored violet, Static yellow…), and slightly larger for Wardens above 100% Potency |
| **Status icons** | always visible on nightmares, with stack counts (already specced above); flash when a status is *used* by a combo (Damp flashes as lightning jumps) |
| **Placement links** | while placing, a small vine icon links the ghost to nearby Wardens it combos with ("combos with Rain Lily"); the Warden panel lists its active links |
| **Warden panel stats** | damage this run, damage per second over the last drift, and **"from combos: N%"** |
| **Rest report** | at every rest, a small card: top 3 Wardens by damage, and combos triggered this block ("Lightning through Damp: 124 times"). Tap to see all Wardens |
| **Results screen** | the same report for the whole run, plus your most-used combo |

These double as teaching: a new player sees *Conducted!* once and understands why Rain Lily and
Stormcap belong together.

### Impact tiers: bigger combos must feel bigger

Added 2026-09-27 with Reactions (`tower_design.md`). Every combat event belongs to one tier, and
each tier is clearly louder than the one below. Effects are in `assets/effects/` (index:
`effects.json`, generator: `tools/effect_art_generator.gd`).

| Tier | Examples | Feedback |
|---|---|---|
| **Hit** | a normal attack | small flash, damage number (if on) |
| **Crit** | crit, weakness hit | `crit_flare` gold glint, bigger gold number, a sharp ping |
| **Combo** | quiet bonuses (*Conducted!*, *Weak!*) | callout text, `status_flash` on the status that was used |
| **Reaction** | Thunderclap, Ignite, Mushrooming… | its own effect and sound, callout in its colour, a small screen shake, **light threads** |
| **Signature** | final-form moments | its own big effect (`thunderhead_strike`, `monsoon_sweep`, `moonstone_beam`, `puffball_bloom`, `long_way_home_drag`) |
| **Chain** | ×5 / ×10 | `chain_badge` + digits; ×5: hitstop + `surge`; ×10: **Dawnburst** (`dawnburst`), Wardens flare, music stinger |

**Reaction callouts** (colours from the art chat, matching each effect):

| Reaction | Callout | Colour | Effect |
|---|---|---|---|
| Thunderclap | *Thunderclap!* | `#bfe0ff` | `thunderclap` + `thunderclap_arc` (64×16, stretched between nightmares) |
| Ignite | *Ignite!* | `#ffc040` | `ignite` |
| Mushrooming | *Mushrooming!* | `#c080ff` | `overgrowth`, then `overgrowth_cloud` (ground loop) |
| Shatter | *Shatter!* | `#bff4ff` | `shatter` |
| Drown | *Drown!* | `#6ab0ff` | `drown` |
| Pinned | *Pinned!* | `#e8ecff` | `pinned` |
| Smother | *Smother!* | `#a8d060` | `smother` (loops while Held) |
| Lightning Rod | *Lightning Rod!* | `#fff27a` | `lightning_rod` (anchor = impact point); shown when a bolt is actually **redirected**, not merely when Marked and Static meet |

- **Light threads:** when a Reaction fires, a thin warm line (`light_thread`, stretched) runs
  for ~0.3 s from **each Warden whose status was part of it** to the nightmare. Players can see
  *who made that happen*, the thing the first playtest said was missing.
- **Discovery:** the first time a Reaction fires (ever, saved in `HeartwoodMemory`), a small card
  slides in: *"Reaction discovered: Thunderclap. Damp + Static."* Discovered Reactions fill a
  **Codex** page (reachable from the pause menu and the Grove), with undiscovered ones shown as
  silhouettes. Finding them all can be a Steam achievement.
- **Size check (first playtest with effects):** Thunderclap's burst, Ignite, Pinned and Shatter
  peak small inside their 64 px frames, and `monsoon_sweep` is faint. If they get lost over a busy
  maze, play them at **1.5–2× scale** before asking for new art.
- **Budget:** at most ~6 full Reaction effects per second; the rest use the `_lite` sheets
  (`thunderclap_lite`, `ignite_lite`, `dawnburst_lite`). Callouts stay throttled. Game rules
  always apply in full; only visuals are capped.
- **Rest report / results:** add Reactions triggered per type and the **longest chain**.

## Stat and status icons

Added 2026-09-27 (user request). **Every stat and every status has a pixel-art icon**, and **every
icon explains itself**: hover on PC, tap on touch, a small tooltip in plain words.

- **Status icons** (on nightmares, in panels, in the Codex): Damp, Drowsy, Spored, Marked, Static,
  Held, Caught, Frozen, plus Deeply Blighted and Hidden. Distinct **shapes**, not just colours
  (accessibility). Tooltip example: *"Damp: 10% slower. Lightning jumps further between Damp
  nightmares."* (names may change, see below).
- **Warden stat icons** (Warden panel, build tooltips, Dream cards): Damage, Attack speed, Range,
  Crit chance, Crit damage, Potency, Rank, Focus (Power / Swift / Reach / Deep), Dew cost,
  Dreamlight cost. Tooltip example: *"Attack speed: attacks per second."*
- **Resource icons**: Dew, Dreamlight, Leaves, Seeds (already exist; get tooltips too).
- **Combos get no icons** anywhere a player hasn't discovered them yet: callouts are words, locked
  Codex entries are "???" (user decision: icons hint at the answer).
- **Status names (decided 2026-09-28):** Damp → **Soaked**, Drowsy **stays Drowsy** (Slowed read the same as Soaked), Spored →
  **Poisoned**, Marked → **Exposed**, Static → **Charged**, Held → **Rooted**; Caught and Frozen
  unchanged. Display names only: code ids and older design docs keep the internal names (table in
  `story.md`). The Heartwood Sapling's "can't be sold or moved" term becomes **Permanent** (not
  Rooted).
- **Every status word is a link, everywhere** (user decision): in tooltips, Dream cards, the Warden
  panel, nightmare info, the Codex, whispers and results, each status name is **underlined** and
  **hover (PC) / tap (touch)** shows its definition popup (the same IconInfo text + icon), with a
  "More in the Codex" link. **Exception:** family pick cards keep plain status names, because tapping
  anywhere on the card picks it. Built in 1e811ee (StatusLinks + IconInfo tokens; renames live only in IconInfo).

## The Codex: Glossary and Combos

Added 2026-09-27 (user request). One **Codex** book, opened from the pause menu, the title screen
and the Memory Grove (and a **?** button on the HUD). It extends the existing Reactions Codex panel.
Two tabs:

### Glossary (every term, always complete)

A reference, not a collection: every entry is there from the start, grouped, searchable, each with a
one-line definition, a small icon, and "see also" links. Terms in tooltips, cards and whispers can be
**tapped to jump to their entry** (underlined in-game text).

| Group | Terms |
|---|---|
| **Resources** | Dew, Dreamlight, Dreamlight shard, Leaves, Seeds, The thinning dream (Dew per nightmare falls each act) |
| **The run** | Drift, Block, Rest, Act, Boss, Family pick, Family Blessing, Dream, Omen, Call early, Auto-drift, Remember screen |
| **Combos** | Reaction, Crowned Reaction, **Chain** (Reactions setting each other off within 1 s; shown "Chain 5", never "×5"; not a damage multiplier), Dawnburst (a Chain 10) |
| **Wardens** | Warden, Family, Branch, Final form, Hidden branch, **Ascended** (a family's endgame Warden, from drift 51), Memory Warden, **Heartwood Sapling** (the 2×2 economy offshoot, from drift 51), **Rooted** (can't be sold or moved), Grow (evolve), Nurture, Rank, Focus (Power / Swift / Reach / Deep), Thornwall and wall growths, Crit, Potency, Clear tool / Tend |
| **Nightmares** | Nightmare, Dispel, Deeply Blighted (elite), Resists / Weak to (families), Dread shell, Hidden (Lurkers), Flying |
| **Statuses** | Damp, Drowsy, Spored, Marked, Static, Held, Caught, Frozen |
| **Dreams** | Rarity, Deepened, Entwined, **Woven** (a three-ingredient Legendary for a Crowned Reaction), Bittersweet, Legendary, Let it pass, Reroll, Banish |
| **The Memory Grove** | Memory Grove, Memories, Loadout (waystones), **Ascension** (the Grove node that lets a family ascend), Blight Levels, Milestones |

Boss names and late nightmares only show once met, to avoid spoilers (the rest is always visible).

### Combos (discovered in play)

Every combo starts **locked** and is **discovered the first time it actually fires** in a run.

- **Locked entry:** a dark card with just *"???"*: **no ingredient icons or hints** (user decision
  2026-09-27: icons gave the combos away). Players find combos by experimenting.
- **Discovery:** the first time a combo fires, a card **slides in at the top of the screen for ~5
  seconds** (the game doesn't pause): *"Combo discovered: Thunderclap"*, the two ingredients, one
  line on what it does, and *"Added to the Codex."* A short chime (distinct from the dispel). If
  several fire at once they queue. The rest report lists *"New combos: Thunderclap"*.
- **Unlocked entry:** name, ingredients, what it does, which Wardens apply each ingredient (from your
  families seen so far), and how many times you've set it off.
- **Counter:** *"12 / 15 combos discovered"* on the tab; discovering every one is a **milestone**
  (a Steam achievement; `meta_design.md`).

**The combos (15):**

| Kind | Combo | Ingredients | What it does |
|---|---|---|---|
| Synergy | **Conducted** | Damp + lightning (Stormcap) | lightning jumps further and more often between Damp nightmares |
| Synergy | **Popped** | Spored 10+ + Puffball | the spores burst over the nightmare and its neighbours |
| Synergy | **Asleep** | full Drowsy + Dreamshroom | the nightmare falls asleep |
| Synergy | **Spore Fog** | Spored + Mistveil fog | spores tick harder inside the fog |
| Synergy | **Set Off** | Static + a pulse (Chime Stone, Lullaby Bell) | the pulse sets off a Static bolt |
| Synergy | **Exposed Blow** | Marked + a heavy hitter (Mossback, Boulderback) | double damage on Marked nightmares |
| Synergy | **Caught** | asleep / full Drowsy + Dreamcatcher | the nightmare takes extra damage from everything |
| Reaction | **Drown** | Damp + full Drowsy | falls asleep for 2 s |
| Reaction | **Ignite** | 3 Spored + Static | every spore stack goes off, and sparks spread |
| Reaction | **Lightning Rod** | Marked + Static | nearby Static bolts strike it at 2× |
| Reaction | **Mushrooming** | 3 Spored + Damp | spores tick harder and a spore cloud grows |
| Reaction | **Pinned** | Marked + Held or full Drowsy | the next hit is a guaranteed 3× crit |
| Reaction | **Shatter** | Held + Damp, then a crit or heavy hit | that hit does 2.5× and shards fly |
| Reaction | **Smother** | Held + Spored | spores tick three times as fast while held |
| Reaction | **Thunderclap** | Damp + 3 Static | 4× damage; lightning arcs to nearby Damp nightmares |
| Crowned | **Tempest** | Thunderclap + Spored | arcs also Ignite spored nightmares; the storm feeds itself |
| Crowned | **Still Pool** | Drown + Held | leaves a pool that puts walkers to sleep |
| Crowned | **Fever Dream** | Smother ends on full Drowsy | spores go off at once; spores and sleep spread to neighbours |
| Crowned | **Starfall** | Pinned + Static | nearby Static bolts all strike the pinned nightmare as crits |
| Crowned | **Avalanche** | a Cairn lob sets off Shatter | the Shatter spreads to every wet, held nightmare under the lob |
| Crowned | **Prismstorm** | Shatter + Static | ice shards carry lightning to nearby nightmares |
| Crowned | **Nightbloom** | Mushrooming + full Drowsy | a glowing cloud where nothing can wake, even with a Watcher |
| Crowned | **Fairy Circle** | Mushrooming + Held | a ring of mushrooms that spores and soaks the next walkers |

**Crowned entries** (added 2026-09-27, `tower_design.md` "Crowned Reactions"): locked ones show
*"???"* in a gold crown frame, **with no hint icons** (same rule as the combos).
As built (57a551e): they live in **their own hidden Codex section**, separate from the 15 combos
(which keep their own counter), with their own first-ever discovery card in the gold tier accent.
Full game only (they can't happen in the demo).

New combos (new Wardens, Reactions) are added to this table and the Codex automatically.

- **Saved in the profile**, including in the demo (carried into the full game like Seeds). Not
  recorded in developer runs (Test Grove, Unlock all families).
- Touch: everything is tap-based; the discovery card can be tapped to open the entry.

## Panels

### Warden panel (on selection)

- **Header:** portrait, name, family icon and tier ("Rain Lily · Dewdrop family · branch").
- **Stats:** soothe per hit, attacks per second, range; applies (status icons + numbers); loves
  (what it's good with); auras affecting it.
- **This run:** damage dealt, nightmares dispelled (helps players judge placements).
- **Grow into:** one button per next form: "Grow into Stormcap · 45 Dew", or "Thunderhead · needs a
  Dream" (disabled, with the Dream's name).
- **Sell:** "+62 Dew" (full during a rest, half while nightmares walk; the button says which).
- **Targeting** (proposed): *First* (default) / *Strongest* / *Closest* for attacking Wardens. Adds
  real decisions (bosses, elites, Lantern Bearers) at little cost.

### Selecting several Wardens

Added 2026-09-27. Mazes reach 30–40 Wardens, so upgrading one at a time gets tedious.

**Selecting** (outside build mode):

| Input | Selects |
|---|---|
| Click | one Warden (as now) |
| **Click and drag** on the map | every Warden inside the box (a thin warm outline shows the box) |
| **Double-click** a Warden | every Warden **of the same kind visible on screen** |
| Ctrl + double-click | every Warden of that kind on the whole map |
| Shift + click / Shift + drag | add to or remove from the selection |
| Esc, right-click, click empty ground | clear the selection |

A drag only starts after the mouse moves ~8 px, so normal clicks never turn into boxes. Walls
(Thornwalls) are included in box selections only if the box contains nothing else, so a sweep
across the maze picks the Wardens, not the hedges.

**The panel with a selection:**
- Header: *"8 Wardens selected"*, grouped by kind (*5 Sporeling, 3 Dewdrop*), each group with its
  portrait.
- **Grow, per group:** one button per form that group can grow into, with the total cost:
  *"Grow 5 Sporelings into Driftspore · 225 Dew"*. If you can't afford them all, the button says
  so and grows as many as you can: *"Grow 3 of 5 · 135 Dew"*. It grows the ones **closest to the
  Heartwood first** (usually where they matter most). Forms still needing a Dream show as
  disabled, as now.
- **Sell all:** *"Sell 8 · +310 Dew"* (half refund while nightmares walk, as always); asks for
  confirmation during a drift.
- **Targeting** (if accepted): set it for the whole group at once.
- Stats in the panel become totals and averages (damage this run, from combos).

Selected Wardens have the warm outline; growing plays a short staggered bloom across them.

**Controller** (see the controller topic): hold the select button and move the cursor to paint a
selection; a "select all of this kind" button.

### Nightmare info (on hover)

Name, one-line trait ("Rolls fast down straight corridors"), health, speed, leaf cost, current
statuses with remaining time. First time a nightmare type appears: a **"New"** tag and the whisper
from `onboarding.md`.

## Choice screens (time stops)

**Rest order:** rest bonus toast → **family pick** (boss rests) → **Dream** → **Omen** (from drift 10)
→ free building → Start. Each choice screen can be **minimised** to look at the map first (a
"peek" button), then reopened.

### Family pick

Three large cards, one per family: portrait, name, one-line identity ("soothe over time"), the
statuses it applies, and small previews of its two branches. Family Blessings (when fewer than 3
new families remain) use the same card with a blessing border.

### Dream

- Three cards. **Rarity** is shown by frame colour **and** a gem shape: Common circle, Uncommon
  diamond, Rare star, Legendary crown.
- Card: name, effect, tags, and a kind badge: **Deepened II** (a "II" ribbon), **Entwined** (vine
  border), **Bittersweet** (thorn border, the cost in its own line).
- Hovering a card highlights the Wardens on the map it would affect.
- Buttons: **Let it pass (+15 Dew)**; **Reroll** (only with the Grove perk, shows how many left).

### Omen

Two Omen cards + **Clear Skies** (default, highlighted). Each: what changes in the next block, the
reward, and a difficulty mark (one to three thorns).

### Pause

Resume, Settings, **Save & Quit**, **Abandon run** (confirm; still earns Seeds), whispers on/off.
Side: a run summary (Dreams, families, active Omen, time played).

### Results

- Headline: **"The dream goes dark"** (loss) or **"The Hollow Oak is dispelled"** (win), with the
  drift reached.
- Stats: drifts survived, nightmares dispelled, leaves lost, longest path, Dreams taken, families.
- **Seeds breakdown**, one line per source, counting up (drifts, dispelled, bosses, tended, win,
  Blight Level bonus).
- Buttons: Memory Grove / New Run / Title. **Demo:** the Grove teaser (asleep, "Your 214 Seeds will
  be waiting") and **Wishlist**.

## Meta screens

- **Title:** the Heartwood in its current state (Grove sapling after the true ending, blossoms per
  Blight Level won), Continue / New Run / Memory Grove / Settings / Credits / Quit. New Run shows
  the **Blight Level picker** after the first win.
- **Memory Grove:** a garden with 4 roots (Wardens, Dreams, Perks, Forests). Each unlock is a plant:
  **seed** (locked, shows cost), **glowing** (affordable), **grown** (owned). Hover for a card with
  the effect and prerequisites. Seeds counter top left; a **Memories shelf** (leaves 1–10) that opens
  the viewer; "Start run" button.
- **Memories viewer:** one illustration + a few lines per Memory, page through in order.

## Settings

| Tab | Options |
|---|---|
| Audio | master, music, effects |
| Display | fullscreen/windowed, resolution, V-sync, **UI scale** |
| Gameplay | Heartwood whispers, Auto-drift default, health bars (hit / always), screen shake, confirm before selling during a drift |
| Controls | rebind every action, controller layout (see controller topic) |
| Accessibility | colour-blind-friendly blight cue (outline/haze), text size, reduced motion, high-contrast route line, **reduce flashes** (photosensitivity: lite effects everywhere, no `surge`/Dawnburst flash), **hitstop and slow-motion** on/off |
| Language | once translations exist |

## Controls (keyboard and mouse)

| Action | Key |
|---|---|
| Select Warden / place | 1–9, left click |
| Select several | click and drag; double-click (same kind on screen); Ctrl + double-click (whole map); Shift adds/removes |
| Clear tool (trees and rocks) | 0 or C, then click obstacles (once clearing is unlocked) |
| Cancel / deselect | right click, Esc |
| Build mode | B |
| Start drift / call early | Enter |
| Pause | Space |
| Speed | Tab (cycle) |
| Sell selected Warden | Delete, or the panel's Sell button. **Right-click never sells** (decided 2026-09-28; it only cancels / deselects) |
| Grow selected Warden | G (proposed; first option) |
| Centre on the Heartwood / on the start | H / F (proposed) |
| Camera | WASD, mouse wheel zoom |

All rebindable. Controller and Steam Deck layout: its own topic (`design_plan.md` #8).

## Checklist against the current build

For the coding chat. Items likely missing or different (verify in the game):
- [ ] Block pips and "boss in N drifts" in the drift display; boss health bar with a 50% marker
- [ ] Dreams-this-run row and list
- [ ] Active Omen badge
- [ ] Creature info on hover; "New" tag for first sightings
- [ ] Status icons with distinct shapes and stack numbers
- [ ] "+N path" and invalid-placement reason tags on the build ghost
- [ ] Rarity gem shapes; Deepened / Entwined / Bittersweet card styles
- [ ] "Peek" (minimise) on choice screens
- [ ] Warden panel: per-run stats, targeting modes (if accepted)
- [ ] Leak feedback at the Heartwood
- [ ] Abandon run in pause; UI scale and accessibility settings
- [ ] Proposed hotkeys (Delete, G, H, F)
- [ ] Selecting several Wardens: box select, double-click same kind, group grow / sell
- [ ] Combat feedback: combo callouts, damage numbers setting, placement links, "from combos" stat,
      rest report, run report on results
