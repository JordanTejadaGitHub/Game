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
| **"Dreams this run" panel** (redesigned 2026-09-28, user: "should be more distinct") | was a plain list of card texts. Now **one row per card**: its rarity icon (shape + colour) on the left, the **name in the rarity's colour** (bold), a stack badge ("II", "×3"), then the effect in the body style with **status words as links** (never raw tokens like "{spored}"), and on the right the **live value** in gold ("+36%", "network of 6", "off: needs 4 Sprouts"). Rows are grouped under small headers: **Damage and stats · Wardens and maze · Combos and statuses · Economy · Legendary**, with thin dividers; Legendaries get a gold rim; Half-dreamed (sleeping) cards are dimmed with their "needs …" line. Tapping a row opens the full card. Scrolls when long | — |
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
- **Discovery:** the first time a Reaction fires (ever, saved in `HeartwoodMemory`), the game
  pauses and a card shows (see "Combos (discovered in play)" below): *"Reaction discovered: Thunderclap. Damp + Static."* Discovered Reactions fill a
  **Codex** page (reachable from the pause menu and the Grove), with undiscovered ones shown as
  silhouettes. Finding them all can be a Steam achievement.
- **Size check (first playtest with effects):** Thunderclap's burst, Ignite, Pinned and Shatter
  peak small inside their 64 px frames, and `monsoon_sweep` is faint. If they get lost over a busy
  maze, play them at **1.5–2× scale** before asking for new art.
- **Budget:** at most ~6 full Reaction effects per second; the rest use the `_lite` sheets
  (`thunderclap_lite`, `ignite_lite`, `dawnburst_lite`). Callouts stay throttled. Game rules
  always apply in full; only visuals are capped.
- **Rest report / results:** add Reactions triggered per type and the **longest chain**.

### Kinship feedback: rewarding at rests, quiet in combat

Added 2026-09-28 (`tower_design.md` "Kinships"). Kinships should feel as rewarding as Reactions but
look different: **Reactions are light bursting on nightmares; Kinships are the forest growing
between Wardens** (green-gold vines, petals, harmony). To avoid clutter, **the loud moments happen
at rests**, when the screen is calm; in combat Kinships are nearly invisible.

| Moment | When it plays | Feedback |
|---|---|---|
| **Preview** | while placing | the build ghost's vine to its kin reads *"Forms Kinship: Slumber Rot"* |
| **Bond forms** | when placed or evolved (almost always at a rest) | a vine grows along the ground between them, both flare in the family colour, petals burst, callout *"Kinship: Slumber Rot"*, a two-note chord (one note per Warden). First time ever: discovery card + Codex entry |
| **Bond grows** (Blooming, Old Kin) | **queued to the next rest** even if reached mid-drift | the vine thickens / flowers, a soft chime, a small line in the rest report |
| **Whole Tree** | once per family per run; **held until the next rest** if reached mid-drift | every Warden of the family flares at once, **the Heartwood itself blossoms** in the family's colour (light climbs its bark, the crown bursts into bloom, a ring pulses over the roots; `whole_tree_sigil`, drawn above the Heartwood sprite), banner *"The Sporeling line is whole."*; a lasting small badge on those Wardens |
| **Harmony strike** | in combat | **a small two-colour spark** (crit-glint size) on the nightmare; the bonus damage merges into the hit's number, tinted green. **No callout in combat.** Counted in the rest report ("Harmony strikes: 84") |
| **Vines** | always | on the ground under the Wardens, **~30% brightness, still during drifts**; full brightness in build mode, when one of the pair is selected, and during the rest moments |

**Screen priority** (what wins when things overlap): Crowned Reactions and Dawnburst > Reactions
and chains > crits and weakness hits > Harmony sparks > vines.

- Harmony sparks share the Reaction effect budget and **always lose to Reactions**; when the budget
  is full they skip the spark and only deal their damage. Reduce flashes: no petal bursts, vines
  never brighten.
- A 23×18 map holds about 8–10 kin pairs, so vines never become a web.
- Setting **Kinship effects: Full / Subtle / Off** (Gameplay tab). Subtle hides vines outside build
  mode and drops the Harmony spark. Rules and bonuses always apply in full.
- Warden panel: *"Kin: Bloomcap · Slumber Rot · Blooming (3 drifts to Old Kin)"*.

**Playtest fix (2026-09-28: "I wasn't seeing any Kinship"; one Kinship formed in a 65-drift run):**
the rule was never taught and the bond was nearly invisible. Changes:
- **Teach the rule where it matters.** A Warden without kin says so in its panel, with the way to
  get one: *"No kin. A Chime Stone within 2 cells would form Night Chimes."* (the other branch of
  its family; greyed if that branch isn't unlocked yet: *"…(unlock Chime Stone with Dreamlight)"*).
- **Kin spots while placing.** When the ghost is a branch or final form, cells within 2 of an
  unbonded Warden of the family's *other* branch get a faint green-gold leaf outline, and the tag
  reads *"Kin spot: forms Night Chimes"*. Placing there plays the "Bond forms" moment.
- **A whisper the first time** a run has two branches of one family: *"Two of one family, planted
  close, learn from each other."* (once ever).
- **Always-visible sign:** both kin wear a small **leaf-pair badge** at their base (tap = the Kinship
  and its stage). Vines during drifts go from ~30% to **~50%** brightness and are drawn **in front
  of the ground and path, behind Wardens**, and routed around large sprites (Ascended), never under
  them.
- **Rest report:** a line per Kinship formed this block (*"Kinship: Night Chimes (Chime Stone +
  Dreamcatcher)"*), and *"No Kinships yet: two branches of one family within 2 cells"* once, at the
  first rest where the player owns two branches of a family but has no Kinship.
- Rest report / results: Kinships formed, Harmony strikes, families made Whole.

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
- **Hover and tap tips stay** (2026-09-28, user: "it never stays when a nightmare dies"): a tip
  stays until the pointer leaves its target. Live values update in place and never rebuild or close
  the tip (nothing is rewritten while it's pointed at, unless it changed). If the hovered target
  itself is gone (the hovered nightmare is dispelled), the nightmare info reads **"Dispelled"** for
  ~1 s and then clears; it never jumps to another nightmare until the pointer moves.
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
- **Discovery:** the first time a combo fires, the **game pauses** (changed 2026-09-28, user
  request; was: a card for ~5 s without pausing) and a discovery card appears near the top of the
  screen, leaving the map visible: *"Combo discovered: Thunderclap"*, the two ingredients, one line on
  what it does, and *"Added to the Codex."* A short chime (distinct from the dispel). The world stays
  frozen on the moment, with the nightmare it fired on highlighted (the light threads hold), so the
  player sees what happened.
  - **Continue** (button, click or tap the card, Space, Enter) resumes at the speed the player had
    before (1×/2×/3×). If the game was already paused, it stays paused. "Open in Codex" is a second
    button.
  - **Several at once** (same frame, or a new one while a card is open): the cards queue behind one
    pause; Continue shows the next, and the last one resumes.
  - Each combo pauses **once ever** (saved in the profile), so it only interrupts while the player
    is learning. Crowned Reactions pause the same way.
  - No pause while a choice screen or the pause menu is open: the card waits and shows when it
    closes (and pauses then).
  - Setting (Gameplay): **"Pause on new combos"**, on by default; off = the old 5 s slide-in card.
  - The rest report lists *"New combos: Thunderclap"*.
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

**Kinships** (added 2026-09-28, `tower_design.md` "Kinships"): their own Codex section, locked as
*"???"* with a leaf frame, discovered the first time the bond forms. The entry shows both Wardens,
what each borrows, and the bond stages. 9 main (Slumber Rot, Rainfog and Storm Beacon are in the
demo) and 9 hidden ones later. Kindred and Whole Tree are explained on the section's first page.

New combos (new Wardens, Reactions) are added to this table and the Codex automatically.

**What the Codex covers** (2026-09-28, user): **the families you can get in a run**: the three
starting families plus every family unlocked in the Memory Grove (hidden branches only once their
Grove node is planted). Combos, Reactions, Crowned Reactions and Kinships appear once all the
families they need are yours in that sense; the list grows as the Grove does, and a newly covered
entry arrives as "???" with a small leaf "New from the Grove" mark.
- Entries that need a family you haven't unlocked aren't listed. One quiet line at the end of each
  section says how many: *"4 more wait in the Memory Grove."* (no names, no hints).
- Counters read against that scope ("9 / 11 combos discovered"); the **Discover every combo**
  milestone still needs every combo in the game.
- The demo covers only its three families (as built, 22bab70); dev toggles show everything.
- A **Families** page lists the families you have, with their branches and final forms (locked ones
  as silhouettes with "unlock with Dreamlight" / "Memory Grove"), each linking to its combos.

- **Saved in the profile**, including in the demo (carried into the full game like Seeds). Not
  saved from developer runs (Test Grove, Unlock all families), **but** (changed 2026-09-28, user
  playtest: "unlocking stuff in the codex doesn't display after") discoveries in a developer run are
  kept **for the session** (until the game closes): the Codex shows them with a small "dev" mark, the
  discovery pause happens once per session, and nothing is written to the profile or counted for
  the "Discover every combo" milestone. The Codex header says "Developer run: discoveries aren't
  saved" while one is active.
- Touch: everything is tap-based; the discovery card can be tapped to open the entry.

## Panels

### Warden panel (on selection)

- **Header:** portrait, name, family icon and tier ("Rain Lily · Dewdrop family · branch").
- **Stats:** soothe per hit, attacks per second, range; applies (status icons + numbers); loves
  (what it's good with); auras affecting it.
- **This run:** damage dealt, nightmares dispelled (helps players judge placements).
- **Grow into:** one button per next form: "Grow into Stormcap · 45 Dew", or "Thunderhead · needs a
  Dream" (disabled, with the Dream's name).
  - **A Sprout lists only the families you have this run** (added 2026-09-28, user request).
    Families not picked yet are **hidden**, not greyed ("family pick" buttons read as clutter and
    spoil which families exist). With none picked yet (before drift 1's pick), the section shows
    one quiet line: *"Pick a family after the first drift to grow Sprouts."*
  - Branches and final forms of families you **do** have still show when locked ("unlock with
    Dreamlight"), since those are goals within reach.
  - Developer modes that unlock everything (Test Grove) show every family.
- **Sell:** "+62 Dew" (full during a rest, half while nightmares walk; the button says which).
- **Targeting** (**decided 2026-09-28**, user): three modes for attacking Wardens that pick a target:
  - **First** (default): the nightmare closest to the Heartwood (today's rule).
  - **Strongest**: the most current health (bosses, elites, Husks).
  - **Closest**: the nearest to the Warden (good for short-range and splash Wardens).
  - Set per Warden with a 3-way switch in its panel (icons + words); with several selected, the
    group panel sets all of them. **T** cycles the selected Wardens' mode. Kept through growing
    and in the run save. The Warden shows a tiny mode pip only while selected.
  - Hidden for Wardens that don't pick a target (pulses, auras, traps, rings, Thornwalls). Snipers'
    existing target-priority button becomes this switch.

### Dream bonuses on Wardens (added 2026-09-28, user request)

Problem: Dream cards change Warden stats, some only in certain spots (Solitude: no other attacking
Warden within 2 cells), and the player can't see when a bonus is on, either when placing or when
selecting. **Rule: every number the player sees for a Warden is its real, current number, and every
card that touches it is listed.**

**Warden panel**
- Stats show the **effective** value (what the Warden really does now: Dreams, Nurture, Focus, auras,
  Blessings). A changed stat is tinted warm with a small up-arrow; tapping or hovering it opens the
  breakdown: `Damage 18 → 27` / `base 18 · Nurture II +20% · Solitude +30%`.
- A **"Dreams on this Warden"** list under the stats: one row per card that affects it, with the card
  icon (rarity shape), name and what it gives. Card names are links (like status words) to the
  card's text.
  - **Active:** bright, e.g. "Solitude · +30% damage, +0.5 range".
  - **Conditional and off:** greyed, with **why** and what would turn it on, e.g. "Solitude · off:
    Rain Lily is 1 cell away (needs no attacking Warden within 2)". This is the key teaching line.
  - Run-wide cards (Many Hands, Few and Mighty) show their current value ("+6%: 24 attacking Wardens").
- Selecting several Wardens: the group summary shows how many have each conditional card active
  ("Solitude: 3 of 5").

**Build ghost (placing)**
- The **range circle uses the range the Warden would really have on that cell**, including
  position-based cards. When a card adds range there, draw the base range as a faint ring and the
  boosted range as the bright ring, so the gain is visible.
- **Bonus chips** above the ghost, beside "+N path": one small chip per position-based card, green
  when it would be on at this cell ("Solitude ✓ +30% dmg, +0.5 range"), grey when it would be off
  ("Solitude ✗ Rain Lily too close").
- **Effect on neighbours:** if this placement would turn a card **off** (or on) for a Warden already
  planted, that Warden gets a small red (or green) chip while the ghost is there ("loses Solitude")
  and the ghost's tag says "breaks Solitude on 2 Wardens". Placing a Warden should never silently
  weaken others.
- For position cards with an area (Solitude's 2 cells, Sprout Chorus), the ghost shows that area as
  a dashed outline while the card is owned, so "within 2 cells" is something the player can see.

**On the map (while in build mode or with a Warden selected)**
- Wardens with an active position-based card show a small card-icon badge at their base (the card's
  rarity shape). Outside build mode the badges are hidden to keep the map clean (setting: always).
- **Marks that are always on the map** (Heart of the Maze's heart, Thick Bark's shield) must
  **explain themselves** (playtest 2026-09-28: "what is the heart?"): hover or tap shows the card
  icon, its name and one line: *"Heart of the Maze: the Warden furthest from any other attacking
  Warden. +50% damage."* The first time one appears in a run it pulses once with the card's name
  under it for ~2 s. When the heart moves to another Warden it glides there (no pop), and the build
  ghost says *"Becomes the Heart of the Maze"* when a placement would move it.

**Which cards this covers:** every card whose effect depends on where a Warden stands or what is near
it (Solitude, Sprout Chorus, Cozy Corners, Hedge Maze, Kindred Roots, Reclaimed Earth's fertile cells,
and any later ones), plus run-wide stat cards in the panel breakdown. New position-based cards must
report themselves through the same breakdown (below), so the UI never needs a card-by-card patch.

**Data (for the build):** one query answers all of this, for a planted Warden or a hypothetical one:
`DreamState` returns, for a Warden (or a Warden type at a cell), the list of cards that affect it,
each with *active or not*, the stat changes, and a short reason line when off. The Warden panel, the
ghost chips, the neighbour check (re-run for Wardens within the largest card radius) and the range
circle all read from it.

Touch: chips and badges are tappable (no hover-only); on touch the ghost's chips show above the
confirm button.

### Planting several Wardens: drag to build (2026-09-28, user request)

In build mode, **press and drag** to plant the chosen Warden on every cell you drag over, like
drawing a wall.
- **While dragging:** each cell passed shows a ghost: green = will plant, red = skipped (not
  buildable, would break the path rule given the cells before it, a nightmare on it, settling
  ground, or out of Dew). The route preview and "+N path" update for the whole stroke, and the tag
  shows the count and total cost: *"6 Thornwalls · 30 Dew · +14 path"*.
- **Straight lines:** after the first two cells the stroke locks to that row or column; hold
  **Alt** for a free stroke. Diagonal jumps fill the corner cell.
- **Release** plants them all at once (one bloom, one sound, cells in drag order so the path rule
  is checked cell by cell). **Right-click or Esc** during the drag cancels the whole stroke.
- A single click still plants one, as now. Works for any Warden, but mostly for Thornwalls and
  Sprouts. It stops at the Dew you have: cells past that are red with "not enough Dew".
- **Touch:** in build mode, a one-finger drag draws the stroke and a Plant button confirms it (two
  fingers pan the camera). Placed this rest = full refund, so a wrong stroke costs nothing.

### Selecting several Wardens

Added 2026-09-27. Mazes reach 30–40 Wardens, so upgrading one at a time gets tedious.

**Selecting** (outside build mode):

| Input | Selects |
|---|---|
| Click | one Warden (as now) |
| **Click and drag** on the map | every Warden inside the box (a thin warm outline shows the box) |
| **Double-click** a Warden | every Warden **of the same kind and the same Nurture rank** visible on screen (2026-09-28, user; was same kind at any rank) |
| Ctrl + double-click | the same, on the whole map |
| Alt + double-click | same kind at **any** rank (on screen; with Ctrl, the whole map) |
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

**Resistances and immunities as icons** (added 2026-09-28, user request: "enemy statuses should be
more clear with icons of their resistances"):

- **Damage-type icons** (changed 2026-09-28, user: resist the Warden's *type*, not a Warden; see
  `enemy_design.md` "Damage types"): Spore, Stone, Water, Light, Root, Song, Talon, Wind, each with
  its own small icon (new art), replacing the base-Warden faces. Plain Wardens (Sprout, Thornwall,
  Acorn, Memory Wardens) show a plain dot and are never resisted. Every Warden shows its type
  (Warden panel, build tooltip, Warden bar tooltip: "Light damage").
- In the nightmare info, three rows under the stats, each hidden when empty:
  - **Resists** (grey frame, small shield): the type icons + names, "Stone ×0.5".
  - **Weak to** (warm frame, small spark): the type icons + names, "Light ×1.5".
  - **Immune / shrugs off**: the **status icons** crossed out for immunities (Barrow Wight: Rooted),
    or with "½" for shorter durations (Barrow Wight: Drowsy wears off fast). Traits get their own
    icons too (Flying, Hidden, Dread shell, Passes through walls).
  - Every icon is tappable / hoverable for its definition (same popup as status words), e.g.
    "Resists Pebbling: stone Wardens deal half damage to it."
- **On the map, in context:** while placing a Warden or with Wardens selected, nightmares on the field
  that **resist** that Warden's family show a small grey shield pip beside their health bar, and
  those **weak** to it a small warm spark pip. Nothing otherwise (setting: always show).
- **Immune feedback:** when a Warden tries to apply a status a nightmare is immune to, the crossed
  status icon flashes once over it (throttled), instead of nothing happening.
- **Coming this block:** at every rest, a strip shows the nightmare **types** in the next block
  (portraits, "New" tag, boss portrait last), each with its resist / weak icons underneath. Tap one
  for its full info. This is where players plan around resistances.
  - **Moved (2026-09-28, user: "hard to see and notice" bottom right):** it sits **top centre, right
    under the drift banner**. At rests it's full size (portraits ~40 px, with the damage-type icons);
    during a drift it shrinks to a row of small portraits for the **rest of the current block**, the
    next drift's types lit, the others dimmed. It never covers the path's start or the boss bar
    (during a boss drift it hides; the boss bar takes its place).
  - **Readable on the night sky** (2026-09-28, user screenshot: an empty-looking box, because a dark
    Shade on a dark sky vanishes). The strip sits on a **fog panel** (the Moonlit Thread style), and
    each nightmare portrait on a **pale moonlit disc** (Moonlight ramp) with a thin cold rim, so the
    dark silhouettes and glowing eyes read. Portraits **48 px** at rests (36 px during drifts), the
    kind's **count** as a badge ("×18"), the name under each at rests, and a "New" tag in gold. The
    label "Coming this block" uses the body size, not small caps at caption size. The same disc
    treatment applies to nightmare portraits everywhere they're shown on dark UI (dossier, intro
    card, nightmare info).
- **New nightmare introduction** (2026-09-28, user: "new enemies should have a display window in
  the middle like bosses"): the first time **ever** a nightmare type is about to appear (profile
  `nightmares_seen`), the rest before its block opens a **centred card**, in the boss dossier's style
  but smaller: animated portrait, name, the one-line trait, **what it does** (1–2 plain lines, e.g.
  *"Breaks into 3 Sobs when dispelled"*), resist / weak / immune icons, and one hint (*"Splash and
  pulses catch the Sobs"*). Several new types in one block: one card each, in order, with "Next".
  - Shown after the Dream / Omen and before the boss dossier, like the other rest screens; dismissed
    by click, tap or Esc; reopen from its portrait in the Coming strip.
  - A type that first appears mid-block also gets a **2-second name plate** when the first one
    spawns (no pause), like the boss name plate.
  - **Always centred** (2026-09-28, user: "make the new enemies appear in the middle of the screen"):
    the intro card is a centred modal, like the boss dossier and the Dream screen, never a side
    panel or corner toast. When the first one of a never-seen type **spawns** without having been
    introduced at a rest (a split child, a summon, an Omen extra), the game **pauses** and shows the
    centred card then, instead of the name plate.
  - **Click or tap any nightmare** on the map (user: "also when you click on the enemies, same with
    bosses"): the game pauses and opens its **centred card**: the intro card for a regular nightmare,
    the **boss dossier** for a boss, plus that nightmare's live state (health, statuses, Restless
    stacks). Close with a click outside, Esc or the ✕; the game resumes at its previous speed. Hover
    still shows the small nightmare info at the side. (With a Warden selected or in build mode, a
    click on a nightmare still does that mode's action first.)
  - Once ever per type (dev runs: per session). Off with the "Heartwood whispers" setting.
  - Data: the nightmare's `trait_text` plus a new `intro_lines` (what it does) and `hint`
    (Enemy Code, same voice as the boss tips).

### Boss dossier (the rest before a boss block)

Added 2026-09-28, user request. At the rest that **opens a boss block** (after drifts 20, 45, 70,
95), a dossier card for the coming boss appears **last in the rest order** (after the Omen, before
free building) so the player plans the build with it. It can be closed and **reopened any time
until the boss is dispelled**: tap the "Boss in N" countdown in the drift banner, or its portrait in
*Coming this block*.

| Part | Content |
|---|---|
| **Header** | the boss's animated portrait (full art, not a silhouette), name and title ("The Hollow Stag · the gaunt king of the old wood"), one line of whisper (*"Something old has found the dream."*), and "Arrives in drift 25" |
| **Numbers** | health (the real number with this run's scaling and Blight), speed, leaves it takes if it reaches the Heartwood |
| **Resists / Weak to / Immune** | the same icon rows as the nightmare info, larger |
| **What it does** | one row per ability: an icon, a name, what it does in one plain sentence, and **when** ("from the start", "every 8 s", "**at 50% health**", "when it takes a hit from…"). The 50% line matches the marker on the boss bar |
| **It brings** | escorts and summons (portraits, count, with their own resist icons), e.g. the Mire Hag's bog spawn |
| **What helps** | 2–3 short hints written per boss (e.g. *"Long straight corridors let it charge: bend the path"*), no numbers, never a solution |
| **Your record** | after the first meeting: times dispelled, best time. First meeting: a "New" tag |

- Spoilers: the Codex still hides boss names until met; the dossier doesn't, because the boss is
  arriving anyway.
- Touch: all rows and icons tappable; the card scrolls on small screens.
- During the boss drift the existing name plate and boss bar stay; the boss bar's 50% marker is
  tappable and shows that ability's line.

**Data (for the build):** per boss in `EnemyData`: a `title`, an ability list (name, icon, text,
when; stat numbers filled from the data, never hand-typed), `tips` (2–3 lines), and the escort list
from the existing followers / summon fields. Normal nightmares reuse `trait_text` plus the new
resist / immune rows.

## Choice screens (time stops)

**Rest order:** rest bonus toast → **family pick** (boss rests) → **Dream** → **Omen** (from drift 10)
→ **boss dossier** (rests opening a boss block) → free building → Start. Each choice screen can be **minimised** to look at the map first (a
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
| Gameplay | Heartwood whispers, Auto-drift default, health bars (hit / always), screen shake, confirm before selling during a drift, **Kinship effects** (Full / Subtle / Off) |
| Controls | rebind every action, controller layout (see controller topic) |
| Accessibility | colour-blind-friendly blight cue (outline/haze), text size, reduced motion, high-contrast route line, **reduce flashes** (photosensitivity: lite effects everywhere, no `surge`/Dawnburst flash), **hitstop and slow-motion** on/off |
| Language | once translations exist |

## Controls (keyboard and mouse)

| Action | Key |
|---|---|
| Select Warden / place | 1–9, left click |
| Select several | click and drag; double-click (same kind and rank on screen); Ctrl + double-click (whole map); Alt + double-click (any rank); Shift adds/removes |
| Clear tool (trees and rocks) | 0 or C, then click obstacles (once clearing is unlocked) |
| Cancel / deselect | right click, Esc |
| Build mode | B |
| Start drift / call early | Enter |
| Pause | Space |
| Speed | Tab (cycle) |
| Sell selected Warden | **X** or Delete (added 2026-09-28: Delete is hard to reach on many keyboards; rebindable), or the panel's Sell button. During a drift the first press shows the half refund and a second press within 2 s sells (unless `confirm_sell` is off). **Right-click never sells** (decided 2026-09-28; it only cancels / deselects) |
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
- [ ] Resist / weak / immune icon rows (family = base Warden face), map pips in context, immune
      flash, "Coming this block" strip
- [ ] Boss dossier at the rest opening a boss block (reopen from "Boss in N")
- [ ] Status icons with distinct shapes and stack numbers
- [ ] "+N path" and invalid-placement reason tags on the build ghost
- [ ] Rarity gem shapes; Deepened / Entwined / Bittersweet card styles
- [ ] "Peek" (minimise) on choice screens
- [ ] Warden panel: per-run stats, targeting modes (if accepted)
- [x] Dream bonuses on Wardens (8a6f1ab, get_card_effects, DreamBonusView): effective stats + breakdown, "Dreams on this Warden" (active / off +
      why), ghost range with card range, bonus chips, neighbour "breaks Solitude" warning
- [ ] Leak feedback at the Heartwood
- [ ] Abandon run in pause; UI scale and accessibility settings
- [ ] Proposed hotkeys (Delete, G, H, F)
- [ ] Selecting several Wardens: box select, double-click same kind, group grow / sell
- [ ] Combat feedback: combo callouts, damage numbers setting, placement links, "from combos" stat,
      rest report, run report on results
