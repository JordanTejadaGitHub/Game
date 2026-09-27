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
| **Top left: resources** | leaves (current / max), Dew | leaves flash and shake when one is lost; Dew flashes red when you can't afford something; Dew motes float up from dispelled nightmares |
| **Under resources: Dreams** | one small icon per Dream taken this run (rarity shape + colour) | hover for the card; click opens "Dreams this run" (all cards + stack counts) |
| **Top centre: drift** | act and name, drift / 100, **5 pips for the current block**, countdown to the next boss | pips fill as drifts arrive; the boss countdown turns into the **boss health bar** during a boss drift |
| **Under drift: Omen** | the active Omen, if any | hover for its effect and reward |
| **Top centre, lower: whispers and toasts** | Heartwood whispers (italic, teaching) and event toasts (plain: rest bonus, act start, trampled wall, boss lines) | whispers stay until done; toasts fade after ~2.5 s |
| **Top right** | path length, Menu | path length pulses when it changes |
| **Bottom centre: Warden bar** | every Warden you can plant, with hotkey and cost | unaffordable = faded (still selectable, the ghost shows red); new families slide in after a pick |
| **Bottom right: drift controls** | Start / Call early (shows the Dew bonus), Auto-drift, pause, 1×/2×/3×, status line ("Resting: rearrange freely") | the Start button pulses during rests |
| **Left: Warden panel** | on selecting a Warden (below) | closes on Esc / right-click / clicking empty ground |
| **Right: nightmare info** | on hovering a nightmare (below) | follows the most recently hovered one |

**Dev panels (Test Grove tools, damage meter):** docked on the **right side**, under the
resources, collapsible with one key (F10), never overlapping the Warden panel or the Warden bar.

## In the world

| Element | Design |
|---|---|
| **Build ghost** | the Warden on the hovered cell, green/red; range circle; **route preview line**; tag above: **"+12 path"** (or "−4 path") and the cost, red if unaffordable |
| **Invalid placement** | red ghost + a short reason tag ("would close the dream", "nightmare here", "can't afford") |
| **Obstacle hover** | outline + "Tend Withered Tree · 5 Dew" + route preview if clearing changes it |
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
| **Combo callouts** | a short word pops over the nightmare when a synergy fires, in the triggering Warden's colour: *Conducted!* (lightning through Damp), *Popped!* (Puffball burst), *Asleep!* (Dreamshroom), *Shattered!* (crit splash), *Weak!* (family weakness). Throttled so a busy maze shows a few at a time, never a wall of text |
| **Damage numbers** | setting: **off / big hits only (default) / all**. Crits larger with a ping; weakness hits bright; resisted hits small and grey; status ticks tiny |
| **Status icons** | always visible on nightmares, with stack counts (already specced above); flash when a status is *used* by a combo (Damp flashes as lightning jumps) |
| **Placement links** | while placing, a small vine icon links the ghost to nearby Wardens it combos with ("combos with Rain Lily"); the Warden panel lists its active links |
| **Warden panel stats** | damage this run, damage per second over the last drift, and **"from combos: N%"** |
| **Rest report** | at every rest, a small card: top 3 Wardens by damage, and combos triggered this block ("Lightning through Damp: 124 times"). Tap to see all Wardens |
| **Results screen** | the same report for the whole run, plus your most-used combo |

These double as teaching: a new player sees *Conducted!* once and understands why Rain Lily and
Stormcap belong together.

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
| Accessibility | colour-blind-friendly blight cue (outline/haze), text size, reduced motion, high-contrast route line |
| Language | once translations exist |

## Controls (keyboard and mouse)

| Action | Key |
|---|---|
| Select Warden / place | 1–9, left click |
| Select several | click and drag; double-click (same kind on screen); Ctrl + double-click (whole map); Shift adds/removes |
| Cancel / deselect | right click, Esc |
| Build mode | B |
| Start drift / call early | Enter |
| Pause | Space |
| Speed | Tab (cycle) |
| Sell selected Warden | Delete (proposed) |
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
