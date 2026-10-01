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
| **Invalid placement** | red ghost + a short reason tag ("would close the dream", "nightmare here", "can't afford", "the dream's edge") |
| **The map's edge must look unbuildable** (2026-09-29, user: "it looks like you can place towers there but you can't") | the outer ring of cells (`island_edge` rim) reads as **edge, not ground**: no grass on its top, a crumbling lip of earth and roots falling into the void, clearly lower and darker than the buildable island (value below the ground), so the buildable area ends where the grass ends. **In build mode**, every unbuildable cell (edge, obstacles, start / end) gets a faint cold hatch, and the ghost over the edge says *"the dream's edge"*. Same rule for any other cell that can never hold a Warden |
| **Obstacle hover** | name only (e.g. "Withered Tree"); clearing happens through the **Clear tool** (below). With the tool active: outline + "Tend Withered Tree · 5 Dew" + route preview if clearing changes it |
| **Health bars** | only once a nightmare is hit (setting: always) |
| **Status icons** | up to 3 small icons above a nightmare, most important first; each status has its own **shape** (Damp droplet, Drowsy "z", Spored dots, Marked ring, Static bolt, Held vine) and a stack number where relevant |
| **Status icons, clearer** (2026-09-30, user: *"their stack of statuses should be more clear"*; the drift 28 screenshot showed tiny bolts with 6 px digits) | Each status is a **14 px badge** (its shape on a dark disc with a status-coloured rim) in one row centred above the health bar; the **stack count is a bold 10 px number in the badge's lower-right corner** with a dark outline, shown from 2 stacks; **at max stacks the rim fills solid** and the number turns gold (e.g. Charged 5/5 about to bolt). A thin rim arc **drains with the time left**. Up to 4 badges; more → the 4 most important + "+1". Bosses and elites: 18 px. Scales with the UI scale setting; zoomed in, the badges keep their screen size (`WorldLabel.text_scale`). Hover / tap a nightmare: the info panel lists each status "Charged 4/5 · 2.1 s". |
| **Status icons, revised** (same day, user: *"the statuses on enemies are too small, I like the old icons from before"*) | Back to the **old status icons** (the bare shapes: bolt, droplet, "z", ring, vine, spore dots; no dark disc), **drawn larger: 20 px** (bosses and elites 24 px), in one row centred above the health bar. Kept from the badge version: the **stack number** (now **12 px**, bold, dark outline, lower-right, from 2 stacks), **gold number + a glow at max stacks**, the "+N" overflow, screen-size under zoom and the batched overlay drawing. The time-left arc becomes a **thin bar under the icon** that shortens. |
| **Status icons, third pass** (same day, user: *"have the status icons bigger"*, then *"keep [the duration bars] as is but make the status stacking more noticeable"*) | Icons **28 px** (bosses and elites 32), **at most 3 then "+N"** (4 would span two cells; built in 9ecf1cb1); the duration bar under each stays as is (3 px). **Stacks stand out:** a bold **16 px** count on a small dark pill at the lower right (from 2 stacks), **one small pip per stack** along the top of the icon (filled up to the current count, to the status's max), and a **quick pop** of the icon each time a stack lands. Max stacks: gold count and gold glow. |
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
| **Damage numbers** | setting: **off (default) / big hits only / all**. Crits larger with a ping; weakness hits bright; resisted hits small and grey; status ticks tiny, **in the status's colour** (Spored violet, Static yellow…), and slightly larger for Wardens above 100% Potency. **Reworked 2026-09-29:** raw hit numbers don't tell the player what's *good*, so the default is now the **Warden DPS tags** and the **drift meter** (below, "Damage that means something"); hit numbers are for players who want them. **Clicking a hit number selects its Warden** |
| **Status icons** | always visible on nightmares, with stack counts (already specced above); flash when a status is *used* by a combo (Damp flashes as lightning jumps) |
| **Placement links** | while placing, a small vine icon links the ghost to nearby Wardens it combos with ("combos with Rain Lily"); the Warden panel lists its active links |
| **Warden panel stats** | damage this run, damage per second over the last drift, and **"from combos: N%"** |
| **Rest report** | at every rest, a small card: top 3 Wardens by damage, and combos triggered this block ("Lightning through Damp: 124 times"). Tap to see all Wardens |
| **Results screen** | the same report for the whole run, plus your most-used combo |

These double as teaching: a new player sees *Conducted!* once and understands why Rain Lily and
Stormcap belong together.

### Damage that means something

Added 2026-09-29 (user: "damage numbers feel useless; I don't know what's good damage for a
wave"). Raw hit numbers don't answer the player's real questions: *is my maze strong enough, which
Wardens are pulling their weight, and is it getting better?* So the default feedback is now DPS,
compared against what the drift needs and against last drift. All of it is built on `DamageLog`.

**1. The drift benchmark ("what's good").** During a drift, the DriftPanel shows a bar:
*"Your maze 1,240 DPS · this drift needs ~980 · 127%"*.
- **Needed DPS** = the drift's total nightmare health (with health scaling, elites and bosses) ÷
  (the drift's **arrival span** + how long an average nightmare spends walking the **current**
  path: path length ÷ average speed). As built (abcc477, `WardenMeter`): the arrival span is
  included because nightmares arrive over 25–30 s; walk time alone would make a maze that exactly
  keeps up read under 100%.
  A longer maze lowers the number needed, which teaches the maze pillar.
- Colour: **green** at 110%+, **amber** 90–110%, **red** under 90% ("you'll leak").
- At a rest it becomes a forecast: *"Next drift needs ~1,100 · your maze did 1,240 last drift"*.
- It's an estimate (flyers, splits and leaks aren't exact); the tooltip says so.

**2. Warden DPS tags.** A small tag under each attacking Warden: its DPS this drift.
- Shown **at rests, while paused and in build mode**; during a drift only on the selected or
  hovered Warden (setting: *Warden DPS tags: rests only (default) / always / off*).
- A small **↑12% / ↓8%** beside it compares with **the Warden's own last drift**.

**3. Colour by performance, not by size.** A Warden's colour rates how much it did **for what it
cost**, so a cheap Warden that does a lot shines, and a big one that coasts doesn't:
- **Rating** = its share of the maze's damage this drift ÷ its share of the Dew invested (Nurture
  included). Support Wardens are rated on what they *enabled* (support credit: damage added, Dew
  caught).
- **Gold** (1.5× or more): *carrying*. **White** (0.75–1.5×): *pulling its weight*. **Dim blue**
  (under 0.75×): *underused*.
- An **underused** Warden's tooltip says why, when the game can tell: *"few nightmares in range"*
  (placement), *"mostly resisted"*, *"overkill: its hits land on nearly-dispelled nightmares"*.
- The **most improved** Warden of the drift (the biggest ↑ vs its last drift) gets a small star.

**4. The drift meter.** A collapsible panel on the right edge (like the Test Grove damage meter):
one row per Warden with portrait, name, DPS, % of the maze, rating colour and ↑↓ vs last drift,
sorted by DPS (or by rating). A header line: *"Maze 1,240 DPS · ↑8% vs last drift · needs ~980"*.

**5. Click to find it.** Clicking a meter row, a DPS tag or a hit number **selects that Warden and
glides the camera to it** (`GameCameraNode.glide`); with several Wardens of the same kind, it goes
to the exact one.

**6. At the rest.** The rest report opens with the maze line (*"Maze 1,240 DPS, ↑8% vs last block,
needs ~980"*), then **Carrying** (top gold Wardens), **Underused** (with the reason) and **Most
improved**, next to the existing top damage and top support lines.

- Hit numbers still exist (setting above), and clicking one selects its Warden.
- Touch: tags and meter rows are tap targets; nothing is hover-only (mobile port).

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
| **Harmony strike** | in combat | grows with the bond: **Sapling** a small two-colour spark (crit-glint size); **Blooming** petals spiral in from both Wardens; **Old Kin** two beams of light leave both Wardens and meet on the nightmare, bursting into petals. The bonus damage merges into the hit's number, tinted green. **No callout in combat.** Counted in the rest report ("Harmony strikes: 84") |
| **Vines** | always | on the ground under the Wardens, **~30% brightness, still during drifts**; full brightness in build mode, when one of the pair is selected, and during the rest moments. When a borrowed trait fires, a **bead of light runs along the vine** from teacher to learner |
| **Borrowed looks** | in combat | a kin Warden's attacks carry its sibling's colour and a hint of the borrowed trait (a lilac sleep-swirl on Driftspore's puffs, a gold edge on Stormcap's lightning…) |
| **Breathing together** | always | bonded Wardens' idle animations sync; at **Old Kin** a small flowering arch grows over the pair |

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

### Support and economy feedback: Wardens that don't deal damage

Added 2026-09-29 (user request: economy felt weak, and non-attacking Wardens should feel as
impactful as attackers). Economy, aura and wall Wardens are credited for what they **enable**, and
each gets a visible payoff. As with Kinships, **the big moments come at rests**; in combat they stay
light.

| Warden kind | In combat (light) | At the rest (the payoff) | Panel line |
|---|---|---|---|
| **Catchers** (Dewcatcher, Wellspring) | a caught nightmare's Dew pop turns **gold** and a small droplet arcs into the catcher, whose bowl **visibly fills** over the block (no extra numbers) | **The Harvest:** each catcher pours its bowl into the Dew counter in a short cascade, *"Harvest +126 Dew"*, then the Wellspring's interest ripples in on top | *"Caught this run: 240 Dew · paid back ✓"* (shows *"38 Dew to pay back"* until then) |
| **Auras** (Acorn, Elder Stump, Grove Heart, Grandmother Oak, the White Stag) | boosted Wardens carry a faint leaf mote; the aura ring breathes softly (brighter in build mode or when selected) | a line in the rest report: *"Elder Stump added 3,400 damage"* | *"Added this run: 12,800 damage (+18% to 6 Wardens)"*: the extra damage its bonus caused, credited through `DamageLog` |
| **Walls** (Thornwall, Bramble, Honeysuckle) | nothing new | rest report: *"Your walls added 34 path tiles"*; Bramble's damage; Honeysuckle's Drowsy applied | Thornwall: *"Adds 3 path tiles"*; Honeysuckle: *"Drowsy applied: 410"* |
| **Control** (Rootling line, holds and pulls) | nothing new | rest report: *"Held for 42 s · pulled back 31 tiles"* | *"Held 42 s · pulled back 31 tiles this run"* |

- **Show exactly who gets the aura** (2026-09-30, user: "acorn has misleading visual of who gets
  the buff"). When an aura Warden is selected or being placed, a glow falling on every Warden inside
  its attack circle reads as "all of these are boosted". Instead:
  - **The aura area is drawn as its real shape**, separate from the attack range: for Acorn and
    Elder Stump (`aura_radius` 1.5) a soft-cornered **3×3 square** of the 8 tiles around it, as a
    warm leaf-green fill with a gold edge. The attack range stays the thin circle, unfilled.
  - **Only boosted Wardens are marked**: a small "+5%" leaf chip over each one (what that Warden
    really gets from this booster: auras don't stack, each Warden takes its strongest), and the lit tile under it. Wardens in the attack circle but outside the
    aura get nothing.
  - The world light (`EnvironmentLighting`) must not make unboosted Wardens look lit: warm light is
    ambient, never a "boosted" signal.
  - Selecting a boosted Warden shows a thin line back to each Warden boosting it ("Acorn +5%").
- **Rest report "Support" line:** the top supporter of the block by what it enabled (*"Top support:
  Grove Heart, +9,200 damage to 7 Wardens"*), next to the top-damage Wardens, so support Wardens
  can be the block's MVP.
- **Results screen:** a *"Best supporter"* next to *"Best Warden"*, and total Dew harvested.
- **Placement preview** for catchers: the build ghost shades the path tiles in catch range, with
  *"~31% of dispels last block happened here"* (from `DamageLog` positions), so the player can
  find the kill zone.
- **Clutter:** catch droplets and leaf motes share the effects budget below Harmony sparks; with
  *reduce flashes* the Harvest is a simple count-up.

### Buff readability: where a Warden's power comes from

Added 2026-09-30 (user: "clear indication of where Wardens get buffs, or anything like that"). A
Warden's numbers can be changed by auras (Acorn, Elder Stump, Grove Heart, Grandmother Oak, relayed
through walls by *Hedgerow Roots*), Kinships, Kindred / Whole Tree, Nurture and Focus, Dreams, and
Omens. The player should always be able to answer **"what is boosting this Warden, and by how
much?"**, and, for a support Warden, **"who am I boosting?"**. In combat it stays quiet; the
details show when the player asks (selecting, hovering, placing, pausing, rests).

| Where | What it shows |
|---|---|
| **Buff pips** (on the map) | a short row of small icons under each Warden, like the status dots on nightmares: one per **local** buff source kind (Elder Stump, Acorn, Grove Heart, Kinship leaf, Whole Tree badge) with a stack count (*"×3"*). Global buffs (Dreams, Omens) aren't pips. Shown **at rests, while paused, in build mode, and on the hovered / selected Warden**; in a drift the rest stay hidden (only the leaf motes). |
| **Source threads** (select or hover a Warden) | thin lines (`light_thread`, tinted per aura kind) from **every Warden buffing it** to it, each labelled with its share: *"+20%"*, *"+10% (2nd stump)"*, *"Kindred +26%"*. A relay through Thornwalls (*Hedgerow Roots*) draws along the wall chain. Kin partners already show a vine. |
| **Selecting a support Warden** | its **aura area lights up** (`aura_ring_breath`, full strength) and threads run **out** to every Warden it boosts, each labelled with what it adds there (after falloff): *"+20% · +10% · +5% (3rd stump)"*. A Warden it covers but doesn't boost (already capped, or not an attacker) shows a dim *"—"*. |
| **Placement preview** | placing an attacker: the ghost shows what it **would receive** (*"+30% attack speed from 2 Elder Stumps"*, threads in). Placing a support Warden: it shows who it **would boost and by how much**, including falloff (*"+10% here: 2nd Elder Stump"*). Growing / nurturing shows the change the same way. |
| **Warden panel** | a **Buffs** section listing every source with its amount and a total, e.g. *"Elder Stump (rank IV, Kindred) +26.6% attack speed · Elder Stump +10% (falloff) · Kinship Slumber Rot (Blooming, 75%) · Kindred +10% damage · Rank III (Power) · Dreams: Deeper Calm ×3 +30% damage"*. Tapping a Warden source selects it and glides the camera there. Negative effects (e.g. *Blood Is Thicker*'s −15%, an Omen's penalty) are listed in a muted plum, the Bittersweet colour. |
| **Buff lens** (a HUD toggle, hotkey **V**) | a map overlay: every aura area tinted by kind, every Warden's buff pips shown, and Wardens coloured by how boosted they are. Toggle on/off (it isn't hold-only, for touch and the mobile port). |

- **The lens button, revised** (2026-09-30, user: *"buff toggle makes no sense for players who just
  started"*; in their screenshot every Warden glowed gold with the lens on):
  - **Hidden until it means something:** the top-right button appears only once the map has a
    **local** buff source (the first aura Warden or Kinship). The V hotkey works from then on too.
  - **Named for what it shows:** "Boosts" (not "Buffs"), and its tooltip says *"Show which Wardens
    are boosted, and by what."*
  - **Only boosted Wardens light up**, by local sources (auras, Kinships, Kindred / Whole Tree).
    Dreams and Nurture that apply to every Warden don't light anyone up (they're in the Warden panel);
    otherwise the whole map glows and says nothing.
  - **A small legend** under the button while it's on: the source kinds on the map with their colour
    and shape (*"Acorn aura · Elder Stump · Kinship"*).
- **One colour per buff source kind**, used everywhere (pips, threads, aura rings, panel rows): the
  Acorn family's gold for auras, the family colour for Kinships, green-gold for Whole Tree. Icons
  also differ by **shape**, not just colour (accessibility).
- Threads and aura areas are drawn **under** Wardens and nightmares, and never during a drift
  unless the player selects or hovers (Reactions own the screen).
- The numbers come from one place (Tower Code exposes each Warden's list of buff sources with
  amounts), so the panel, threads, preview and lens always agree.
- **Icons needed (for the UI Asset chat, not made yet):** buff pips for Elder Stump (attack speed),
  Acorn (damage), Grove Heart, Grandmother Oak, Kinship (leaf), Whole Tree (badge) and Kindred (a
  Focus mark), a tiny stack count (×2, ×3), a **penalty** pip, and a **buff lens** toggle button
  (on/off). Notes from the old UI Asset chat: icons come from `tools/ui_icon_generator.gd` (16 px,
  one row in `assets/ui/icons.png` + `icons.json`, snapped to Heartwood 32 with
  `HeartwoodPalette.snap_image`; **append new icons at the end** so columns never move). The palette
  has no red: the penalty "plum" should use **Bruise** or **Orchid**. The Kinship pip is drawn in
  greys and tinted per family in code. Distinct shapes, not just colours.

## Stat and status icons

Added 2026-09-27 (user request). **Every stat and every status has a pixel-art icon**, and **every
icon explains itself**: hover on PC, tap on touch, a small tooltip in plain words.

- **Status icons** (on nightmares, in panels, in the Codex): Damp, Drowsy, Spored, Marked, Static,
  Held, Asleep, Caught, Frozen, plus Deeply Blighted and Hidden. Distinct **shapes**, not just colours
  (accessibility). Tooltip example: *"Damp: soaked. Water hits +20%. Lightning jumps further between
  Damp nightmares."* (names may change, see below).
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

**Glossary and Families, revised (2026-09-30, user: *"make the glossary Codex more visually appealing
and update the families"*).**

*Terms updated* (the table above is out of date; the Codex follows this list):
- **Statuses:** Soaked, Drowsy, Asleep, Poisoned, Exposed, Charged, Rooted, Caught, Frozen (the old
  Damp / Spored / Marked / Static / Held names are gone).
- **Damage types:** Spore, Water, Light, Stone, Root, Song, Wind, Talon, Plain, with who deals each.
- **Wardens:** Nurture's **per-rank choice** (Power / Swift / Reach / Deep) replaces Focus;
  **Kinship**, **Harmony strike**, **Boosts** (auras, Kinship, Kindred / Whole Tree) added;
  Heartwood Sapling and Memory Warden removed (cut / parked).
- **The run:** Close call, Chain added; **Dreams:** Entwined and Half-dreamed stay internal (not
  entries); Woven, Deepened, Bittersweet stay.

*Glossary look:*
- **Two panes:** the groups down the left as a list with an icon each (Resources, The run, Combat,
  Wardens, Nightmares, Statuses, Damage types, Dreams, The Memory Grove); the right pane shows that
  group's entries. Search box at the top of the left pane; a result jumps to its entry and flashes it.
- **Every entry is a small card**, not a line of text: a **32 px icon** on the left (the status icon,
  the resource icon, the damage type's Warden face, a Warden portrait for Warden terms), the **term
  in the display font**, the one-line definition in body text, one muted **example** line (*"Stormcap's
  chain jumps farther through Soaked nightmares."*), and "See also" as **gold link chips**.
- **Statuses page:** each card has its **status colour** as the rim, and adds its numbers (max stacks,
  duration, what a stack does) and **who applies it** (small Warden portraits of your families); the
  combos it's part of show as chips, ??? until discovered.
- **Damage types page:** each type's card lists the nightmares weak to it and resisting it (icons,
  ??? until met).
- Cards sit in a 2-column grid on wide screens, 1 column on narrow; group headers use the gold thread
  divider. Moonlit Thread throughout (fog panels, no hand-built boxes).

*Families page, updated:*
- One page per family, tabs along the top with the base Warden's portrait (like Remember).
- **Header:** the base Warden large (animated), family name, damage type, its **role in one line**
  (*"Damage over time: stack Poisoned and keep it."*), its statuses, and **your record** (picked N times,
  won N runs with it).
- **The tree** drawn like the Remember screen (portraits on waystones): base → two branches → two
  finals → hidden branch → Ascended, each node with its **tier, Dew to grow (120 / 300 / 600) and
  Dreamlight to unlock (1 / 2 / 3)**, and its Grove state (planted, or a silhouette "in the Memory
  Grove"). Tapping a node shows its full card (the Warden panel's top half).
- Under the tree: its **Kinships** (the two branches, the bond's name and stages), its **combos**
  (chips, ??? until found), and the family's Dream cards (a count and a link to the Dreams tab).
- Numbers come from the data (TowerData / DreamState), never typed into the Codex, so balance changes
  (branch 120, final 300, Ascended 600, Puffball no longer popping, Nurture choices) show up by
  themselves.

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
  - **The discovery card stands out in combat** (2026-09-30, user: *"the discovery window should be more visible during combat and have the icons"*; it was a see-through panel with small text over a busy fight): a **solid panel** (the opaque tip fog, ~95%) with the gold thread, the world behind **dimmed to ~40%** except the nightmare it fired on (lit), a **title in the display font, 28 px gold** (*"Combo discovered: Thunderclap"*, *"Chain discovered: Chain 5"*), **icons at 48 px**: a combo shows its two status icons "+" its Reaction icon; a chain shows each Reaction's icon in order with arrows (repeats collapsed as "Nightbloom ×2"); body text 18 px; then Continue / Open in Codex. A soft rise-in and the discovery chime.
  - **The discovery card can be minimised** (2026-10-01, user: *"when a combo unlocks, I should be able to minimise the window"*): a **"Peek at the map"** button (same as the choice screens, `ChoicePeek`) hides the card and lifts the dim, **the game stays paused**, and the world can be panned, zoomed and hovered (nightmare and Warden info work). A small "Combo discovered" tab at the top reopens it; Continue on the card (or Space / Enter while peeking) resumes.
  - **Chains are discovered too** (2026-09-30, user: *"discover chain too as well should be like
    discovering a combo"*). A Reaction chain (Reactions setting each other off, the tracker's chain
    length) gets the **same pause + discovery card** the first time ever it reaches **Chain 3, Chain 5 and Chain 10**
    (×10 is the Dawnbreak line): *"Chain discovered: Chain 3"* (chains read as a count, never ×N, which looks like a damage multiplier), the Reactions in it in order ("Thunderclap
    → Lightning Rod → Mushrooming"), one line (*"Reactions can set each other off."*), and *"Added to
    the Codex."* Codex Combos page gets a **Chains** section: the three tiers (??? until reached) and
    your **longest chain ever**, with the Reactions it used. Same setting, queue and once-ever rules
    (profile key, account knowledge); the rest report lists *"New chain: Chain 5"*.
- **Unlocked entry:** name, ingredients, what it does, which Wardens apply each ingredient (from your
  families seen so far), and how many times you've set it off.
- **Counter shows the real total** (2026-09-30, user saw "7 / 7" with only the starting families and
  read it as "all found"): the tab and header count **every** combo in the game, *"7 / 22 combos"* and
  *"Crowned Reactions · 1 / 8"*; the ones your families can't make yet are listed as ??? under "15
  more wait in the Memory Grove". Same for Kinships and chains.
- **Counter:** *"12 / 15 combos discovered"* on the tab; discovering every one is a **milestone**
  (a Steam achievement; `meta_design.md`).

**The combos (15):**

| Kind | Combo | Ingredients | What it does |
|---|---|---|---|
| Synergy | **Conducted** | Damp + lightning (Stormcap) | lightning jumps further and more often between Damp nightmares |
| Synergy | **Popped** | Spored 10+ + Puffball | the spores burst over the nightmare and its neighbours |
| Synergy | **Asleep** | full Drowsy + Dreamshroom | the nightmare falls asleep for 3 s; a big hit (10%+ of its health) wakes it |
| Synergy | **Spore Fog** | Spored + Mistveil fog | spores tick harder inside the fog |
| Synergy | **Set Off** | Static + a pulse (Chime Stone, Lullaby Bell) | the pulse sets off a Static bolt |
| Synergy | **Exposed Blow** | Marked + a heavy hitter (Mossback, Boulderback) | double damage on Marked nightmares |
| Synergy | **Caught** | asleep / full Drowsy + Dreamcatcher | the nightmare's statuses stop wearing off |
| Reaction | **Drown** | Damp + full Drowsy | pulled under for 3 s: a heavy slow and growing drowning damage |
| Reaction | **Ignite** | 3 Spored + Static | the spores burn: they tick 3× as fast and spread to neighbours |
| Reaction | **Lightning Rod** | Marked + Static | nearby Static bolts strike it at 2× |
| Reaction | **Mushrooming** | 3 Spored + Damp | spores tick harder and a spore cloud grows |
| Reaction | **Pinned** | Marked + Held or full Drowsy | the next hit is a guaranteed 3× crit |
| Reaction | **Shatter** | Held + Damp, then a crit or heavy hit | that hit does 2.5× and shards fly |
| Reaction | **Smother** | Held + Spored | spores tick three times as fast while held |
| Reaction | **Thunderclap** | Damp + 3 Static | 4× damage; lightning arcs to nearby Damp nightmares |
| Crowned | **Tempest** | Thunderclap + Spored | arcs set spored nightmares burning; the storm feeds itself |
| Crowned | **Still Pool** | Drown + Held | leaves a pool that pulls walkers under |
| Crowned | **Fever Dream** | Smother ends on full Drowsy | it falls asleep, and spores and sleepiness spread to neighbours |
| Crowned | **Starfall** | Pinned + Static | nearby Static bolts all strike the pinned nightmare as crits |
| Crowned | **Avalanche** | a Cairn lob sets off Shatter | the Shatter spreads to every wet, held nightmare under the lob |
| Crowned | **Prismstorm** | Shatter + Static | ice shards carry lightning to nearby nightmares |
| Crowned | **Nightbloom** | Mushrooming + full Drowsy | a glowing cloud where sleep can't break or end, even with a Watcher |
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

**Dreams** (added 2026-09-29, user: "add a card Codex for all cards; all cards start as ??? but once
you see them once in your account, it adds into it"): a Codex section listing **every Dream card in
the game**.
- **Every card starts as "???"** in a plain card frame (no name, rarity, text or hint).
- A card is **seen** the first time it's **offered** to you in any Dream (taking it isn't needed);
  from then on its entry shows the full card: rarity gem, name, text with status links, tags, its
  Needs, its Deepened version (once that's seen too), and your **times taken** / **runs won with
  it**. Saved to the **account** immediately (profile `dreams_seen`, like the combos), in every
  run; dev-run sightings carry the hidden dev flag.
- Grouped like the "Dreams this run" panel (Damage and stats, Wardens and maze, Combos and
  statuses, Economy, Legendary), with filters by rarity, tag and family, and a counter:
  *"84 / 180 Dreams seen"*. Newly seen cards wear the gold "New" tag until you look.
- The "Dev: any card…" grid does **not** mark cards as seen (only real offers do).
- Milestone: **"Dream of everything"** (every card seen, normal runs only); a Steam achievement.

**Nightmares** (added 2026-09-30, user: "add a Codex of enemies, do the discover too"; this is the
bestiary that `onboarding.md` had parked as the "Forest Journal"): a Codex section listing **every
nightmare and boss**.
- **Every entry starts as "???"** (a dark silhouette-less frame, no name or hints).
- An entry is **discovered the first time that nightmare appears in one of your runs** (the same
  `nightmares_seen` that drives the "New" tag and the intro card); bosses the first time you meet
  them.
- A discovered entry shows: the portrait on its moonlit disc, name, the one-line trait, **what it
  does** (the intro lines), the hint, resist / weak / immune icons (damage-type badges and crossed
  statuses), health, speed and leaves it takes (at drift 1 scaling, "grows with each drift"), its
  first-appearance act, and **how many you've dispelled** in total. Bosses show their dossier
  (abilities and when, escorts) and your record against them.
- Grouped **by act** (in first-appearance order), bosses last in each act, with a counter
  *"23 / 34 nightmares met"*. Newly met entries wear the gold "New" until you open them.
- Milestone: **"Know every nightmare"** (all met, normal runs only).

**Account knowledge always lives on the real profile** (2026-09-30: with Dev Grove on, a separate dev
profile made every nightmare "New" again). What you've **met, discovered or seen** (nightmares,
combos and Reactions, Kinships, Dream cards) is always read from and written to the **real
profile**, even in Dev Grove, Test Grove and Unlock all families (dev finds keep their hidden dev flag
for milestones). Only the Grove's unlocks, perks and loadout come from the Dev Grove profile.

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

- **Saved to the account (profile), always** (revised 2026-09-28, user: "discovering it should
  persist for the account"): every discovery is written to the profile the moment it happens,
  including in the demo (carried into the full game like Seeds) **and in developer runs** (Test
  Grove, Unlock all families, Dev Grove). Discoveries from a dev run carry a small hidden flag, so
  the **"Discover every combo" milestone** (and its Steam achievement) only counts ones found in
  normal runs; the Codex shows them like any other entry. (Replaces the earlier "kept for the
  session" rule.)
- **Undiscovered combos are "???" everywhere, not just in the Codex** (user: "combos should only
  appear on the tech tree if you discover it, otherwise ???"). Every place that lists a Warden's or
  a family's combos shows an undiscovered one as a **"???" entry with no name, statuses or hints**:
  the Remember screen's side panel, the Codex Families page, the Warden panel's "Combos with",
  the build ghost's placement links, the Memory Grove's node cards, and the rest report. Once
  discovered it shows its name and links to its Codex entry. (Dream card texts that amplify a
  combo still name it, since a card must say what it does; taking one doesn't discover it.)
- Touch: everything is tap-based; the discovery card can be tapped to open the entry.

## Playtest fixes (2026-09-30)

From a user playtest with screenshots; each line is the rule going forward.

- **Drift banner:** the drift reads **"Drift 5"** (no "/ 100"). The boss line is prominent (gold,
  larger, the boss portrait on its disc) and gives the drift, not only a countdown: **"The Hollow
  Stag · drift 25 (in 20)"**.
- **"New" tags** (Coming strip, intro cards) mean **never seen on this profile**
  (`nightmares_seen`); a Shade you've met before is never "New". Dev runs follow the same rule.
- **DPS tags on Wardens:** colour by **rank on this board**, so the strongest reads strongest: top
  ~20% gold, middle white, bottom ~20% dim (the "underused" reason stays in the tooltip). A tag is
  never greyed just because the Warden underperforms its own potential.
- **Damage meter panel:** sort buttons read **"Sort: DPS"** and **"Sort: % of damage"** (was
  "share"); clicking a row **selects that Warden and glides the camera to it** (must work); the
  **last drift's DPS** lives in this panel ("Last drift 62 DPS"), not as loose text by Start;
  scrolling the panel never scrolls or zooms the map.
- **Meter shows the top 5 only** (2026-09-30, user: "the scroll bar doesn't work; limit the Wardens to
  the top 5 and show a ratio compared to last drift"): the Wardens tab lists the **5 highest**
  Wardens by the current sort, **no scrolling**, and each row adds its change against its own
  last drift (**"↑12%"** gold / **"↓8%"** dim, "new" if it didn't fight last drift). A small line
  under the list says *"and 18 more"*; clicking a Warden on the map still shows its own numbers.
- **"Needs ~N DPS" is removed in release:** the maze's own DPS stays; the estimate of what a drift
  needs is **dev-only** (debug builds / dev runs), since it's a rough balance number and can mislead.
- **Remember tree:** the lines from the root to every **unlocked or grown** node glow gold (the path
  you've taken reads at a glance); locked lines stay dim. The **Ascended** node uses the same node
  size as the others (its art scaled to fit the disc; its crown sits above, not bigger).
- **Warden panel → Remember:** a Grow button for a form you haven't unlocked (needs Dreamlight or
  its branch first) **opens the Remember tree on that node** instead of doing nothing.
- **Sell button** shows its hotkey icon (**X**, or the rebound key) like other hotkeyed buttons.
- **Preview the growth before growing** (2026-09-30, user: "hovering the upgrade it will go into
  shows what it would look like and the range it will become"). While the pointer is on a Grow
  button (or its key Q / E / Z / G is **held**):
  - the Warden on the map shows the **new form's sprite** in its place, softly translucent and
    idling, so you see what it becomes;
  - its **new range ring** is drawn bright over the current one (faint), with the difference
    visible (and the dead zone for snipers with a minimum range);
  - the button's tooltip lists the **stat changes** ("Damage 24 → 38 · Range 2.7 → 3.2 · adds
    Rooted"), and for a 2×2 Ascended form the valid squares show as ghosts.
  - Leaving the button restores the map. **Touch:** the first tap on a Grow button shows the preview
    with a "Grow · 80 Dew" confirm; the second tap grows. For a group, every selected Warden shows it.
- **No "No kin" line** (2026-09-30, user): the Warden panel shows a Kinship line **only when the
  Warden has kin** ("Kin: Mossback · Hammer and Anvil · Blooming"). The "No kin. A Mossback within 2
  cells would form…" hint is removed (kin spots while placing stay).
- **Every combat callout word is in the glossary** (user: "been seeing 'Shattered' but don't know
  what it means; it's not in the glossary"). Each callout (**Shattered!, Conducted!, Popped!, Asleep!,
  Weak!, Resisted, Crit**, Reaction names, "Chain N") has a glossary entry with one plain line
  linking to its Codex combo entry. (Correction 2026-09-30: "Shattered!" was the **crit** callout,
  easily confused with the **Shatter** Reaction; the crit callout is renamed **"Critical!"**, and
  "Shatter!" stays the Reaction.) The glossary entry appears once you've seen
  the callout (it names a discovered combo, so it doesn't spoil "???").
- **Selected vs hovered, everywhere** (2026-09-30, user): a **selected / active** control (the chosen
  targeting mode, the open tab, the current speed, a toggled option, the selected Warden's frame)
  shows only a **gold border** (and gold text), no fill. **Hovering** fills the **whole box** with the
  soft highlight. Pressing darkens it for a moment. So "chosen" and "under the pointer" never look
  alike. One UiStyle rule for all buttons, tabs and segmented switches.
  - **No button is filled unless the pointer is on it** (user, 2026-09-30: "still seems highlighted
    when I'm not hovering", the Warden panel's "Grow into Acorn"). Primary / affordable / keyboard-
    focused buttons don't get a resting fill either: at most the gold border. Keyboard focus shows
    as the border too (it must not look like hover).
- **The Warden panel never fills the screen** (2026-09-30, user, a late-run Honeysuckle with ~14 Dreams listed: *"this fills the whole screen"*; it also ran up over the Dreams row): the panel is capped at **~55% of the screen height**, starts **below the Dreams row**, and scrolls inside if needed. "Dreams on this Warden" becomes **one compact row of card gems** (rarity shape + a small count), **only the cards that are active on it**, each gem hovering / tapping to its line ("Crossroads +48% damage"); inactive cards collapse to one muted line *"4 more don't apply here"* (hover lists why). The Buffs list is folded to its **Total** line with a "Details" toggle. Stats, Sell and Close always stay visible.
- **Warden panel header shows the Warden's portrait** (its animated idle art), not the family
  emblem (user, 2026-09-30: "go back to the Warden portrait instead of the icon").
- **Less hand-holding on buttons** (2026-09-30, user: "a bit too much hand holding"):
  - Unlock buttons read **"Unlock with 2 Dreamlight (0)"**, not "(you have 0)".
  - A button you **can't afford never glows or pulses**; it's shown dim. Glow means "you can do this now".
  - Sell reads **"Sell · +176 Dew"**, without "(half during a drift)" (the refund rule is in the
    glossary and the number already shows it).
  - General rule: buttons show the action and its price; explanations live in tooltips and the Codex.
- **Plain words on cards** (user: "still don't know what a perfect block means, and what a block is
  if I was new"): card text says it plainly ("5 drifts in a row without losing a leaf") and any game
  term that remains (**drift, block, rest, perfect block, Dreamlight, family pick, Deeply Blighted**)
  is a **linked term** like the status words: underlined, hover / tap for a one-line definition
  from the Codex glossary (e.g. *"Block: the 5 drifts between two rests."*).
- **Family icons on the Warden bar** (user: "create icons for each family, then have them display
  for hotkeys"): every family gets an **emblem**, reusing its **damage-type badge** (Spore, Stone,
  Water, Light, Root, Song, Talon, Wind; Acorn and Memory forms a plain leaf; Sprout and Thornwall
  their own small sprout / hedge marks), so one symbol means "this family" everywhere. On each
  Warden bar button the **hotkey number sits on that emblem** in the top-left corner (the cost stays
  under the icon). The same emblem heads the Warden panel, the family pick cards and the Remember
  tabs.
  - **Removed (2026-09-30, user: "remove the family emblems … everything, go back to how it was
    before").** No family emblems anywhere: the Warden bar shows the Warden's icon with the plain
    hotkey number in its corner, the Warden panel's damage-type line is text, family pick cards and
    Remember tabs go back to their earlier look, and a Dream card's requirement reads **"Needs
    Wind"** (the damage type as a linked word, no emblem). The nightmare resist / weak icons (the
    base Warden face with a shield or spark, `NightmareIcons`) predate the emblems and stay.
- **Warden bar hover = the Warden panel's info** (2026-09-30, user: *"when you hover a tower in the tower bar, it should give you more detail, like when you select a tower"*). Hovering (or long-pressing on touch) a Warden bar button shows a card with **the same top half as the Warden panel**: portrait, name, damage type, description with status links, stats with this run's Dream bonuses (↑), statuses it applies, Potency, **"Grows into"** (its branches with their Dew and Dreamlight state), and the price line (Sprout: the rising price rule). No buttons. One shared view with the panel so the two never disagree.
- **Top-right layout, as in the Moonlit Thread mock-up** (2026-09-30; user first asked "above or beside?", then: *"look at the UI asset for Moonlit, it should be like that in terms of the top right"*; mock: https://claude.ai/artifact/4Cs1PP2CrqTjth2dHiZFow). **One horizontal row** in the top-right corner on one soft fog patch (no thread, no boxes): **leaves "15/15" · Dew · Dreamlight · path length**, each a pixel icon plus a **big Cormorant number (~28 px)**, then the buttons as **compact 40 px icon buttons at the end of the same row**: Remember (✦, glows when Dreamlight can buy something), Boosts (only once a boost source exists), ? (Codex) and ☰ (Menu). Their names move to tooltips. Nothing stacks vertically; the half-price clears counter sits just under the row. Replaces the earlier "buttons under the resources" layout. Check it fits beside the drift banner at 1280×800.
- **The Clear tool slot matches the Warden slots** (2026-09-30, user: *"it shouldn't be different in size from the rest"*; an earlier reading, a round separate button, was wrong): the **same size and shape** as a Warden slot, lined up with them on the same baseline; key badge in the same corner. No change otherwise.
- **Every icon can be hovered or tapped, and tips are opaque** (2026-09-30, user: *"I can't click and hover over icons; also I can barely read them once they are hovering over text, like on the Warden detail panel bottom left"*): **every icon in a panel** (stat icons, status icons, damage type, resource icons, rarity gems, buff pips) shows its tip on hover and on tap (TapTip), with the term's glossary line. **Tooltips and tap tips are opaque**: a solid Void fog panel (`UiStyle.FOG` at ~95%, not the see-through fog of HUD patches) with the gold thread, a soft drop shadow, drawn **above every panel** (their own top layer), placed so they never cover the text the pointer is on (prefer above-right of the pointer, flip at screen edges).
- **Readable tooltips and hover text** (user: "hovering things, in general, the text is too small
  and hard to read"): every tooltip, hover panel and tap popup uses **at least 16 px body text at
  1080p** (18 px for the first line / name), **1.35 line height**, a maximum width of about **42
  characters**, and scales with the UI scale setting. Small caps captions stay for labels only, never
  for sentences. Contrast at least 4.5:1 against the fog panel. Applies to the Warden bar, Warden
  panel stats, status and term links, nightmare info, Codex glossary popups and the rest report.
- **No automatic rest report** (user: "don't think this block of information is needed"). The text
  panel that opened at every rest (maze DPS, carrying / underused, top 3, crits, support, path tiles,
  held / pulled, this block's templates) is **gone from the screen**. What's worth keeping moves:
  - the damage meter gets a **"Last block"** tab (top Wardens, most improved, combos and Reactions,
    close calls, Kinships formed), opened only when you want it;
  - one-time moments still get their own toast or card (a new combo, a Kinship formed, a first
    close call), as before;
  - the **results screen** keeps the whole-run report.
  A Gameplay setting **"Rest summary: Off / On"** (Off by default) brings the old panel back for
  players who like it. Other features that wrote lines into the rest report now write to the
  "Last block" tab instead.
- **Family-seeding cards** ("Seed · calls Rootling to your next family pick", e.g. Patient Roots):
  if you **already own** that family, the seed line is hidden and nothing is seeded (it only calls
  families you don't have yet).

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
- **Targeting** (**decided 2026-09-28**, user; **Last added 2026-09-30**): four modes for attacking
  Wardens that pick a target:
  - **First** (default): the nightmare closest to the Heartwood (today's rule).
  - **Last**: the nightmare **furthest from the Heartwood** in range, the newest arrival. Good for
    status Wardens (tag a nightmare so it walks the whole maze Spored, Marked or Static), for
    Wardens near the start, and for mopping up stragglers.
  - **Strongest**: the most current health (bosses, elites, Husks).
  - **Closest**: the nearest to the Warden (good for short-range and splash Wardens).
  - Set per Warden with a 4-way switch in its panel (icons + words); with several selected, the
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
  - **Too tall** (2026-09-30, user screenshot: 6 kinds stacked 5 rows deep down the map, wide
    kinds like the Night Hound and Lantern Bearer each on a row of their own). Fixes:
    - **One row**, left to right, centred under the banner; a second row only past 6 kinds, never
      a third ("+2" chip after that, tap = the list).
    - Every portrait sits in the **same round disc** (48 px at rests), the art fitted inside it
      whatever its shape, so wide nightmares don't make wide pills.
    - The count is a **badge on the disc's corner** ("×28"), the resist / weak icons a small row
      under it (14 px); names only on hover / tap, not under every disc.
    - The whole strip stays about **90 px tall at rests** and never covers the map's playfield more
      than the banner does.
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

### Boss dossier (at the start of each act)

Added 2026-09-28, user request; **moved to the act's start 2026-09-29** (user: "give a heads-up at
the beginning of the act of what type of boss and its style, instead of the block right before").
The act's boss is drawn at random (boss pools, `enemy_design.md`), so the player learns which one
it is **when the act begins** and has the whole act to build for it:
- **Act 1:** the dossier opens by itself at the run's first rest, before drift 1 (after any
  onboarding whisper).
- **Acts 2–4:** it opens at the act-break rest (the boss rest after drifts 25 / 50 / 75), last in
  the rest order, for the **next** act's boss.
- **The rest opening the boss block** (after drifts 20, 45, 70, 95) no longer opens the full card,
  only a short reminder (*"The Hollow Stag arrives in 5 drifts"*, the portrait, an **"About the
  Hollow Stag"** button): a nudge, not a repeat.
- **It must feel like THE boss** (2026-09-30, user on the Night Mare card: *"these boss screens should
  give more of that feel and info that this is THE BOSS"*). The card read like a nightmare info panel.
  Changes (the content stays):
  - **Eyebrow over the name:** *"The boss of act 1"* in small caps, in **Wraithlight** (the boss
    colour, `UiStyle.BOSS`), and a subline *"Drift 25 · the last drift of the act"*.
  - **The portrait is the hero:** the boss's full animated art **~3× larger** (about 240 px tall),
    on the left, rising out of a cold violet mist, not in the small disc. Right column: name, title,
    whisper, numbers.
  - **Boss frame:** the panel's thread and diamond in Wraithlight instead of gold; the screen behind
    dims further (the map almost black) with a slow cold vignette pulse.
  - **Scale that reads:** the numbers get context: *"Health 4,000 · about 13 Husks"*, and the leaves it
    takes in large type (*"3 leaves each lap"*), the one number that ends runs.
  - **An entrance:** the portrait fades up from the mist, the name writes in, a low boss sting
    and one heartbeat (Sound: `boss_reveal`); reduced motion = a plain fade.
  - The button stays "Prepare"; the reminder card and the Codex entry use the same eyebrow and colour. **The word "dossier" never reaches the player**
  (2026-09-30, user: *"Open dossier???"*): buttons and tooltips name the boss ("About the Mire
  Hag"); "dossier" stays an internal name. It can be closed and **reopened any time
until the boss is dispelled**: tap the "Boss in N" countdown in the drift banner, or its portrait in
*Coming this block*.

| Part | Content |
|---|---|
| **Header** | the boss's animated portrait (full art, not a silhouette), name and title ("The Hollow Stag · the gaunt king of the old wood"), one line of whisper (*"Something old has found the dream."*), and "Arrives in drift 25" |
| **Numbers** | health (the real number with this run's scaling and Blight), speed, leaves it takes if it reaches the Heartwood |
| **Resists / Weak to / Immune** | the same icon rows as the nightmare info, larger |
| **What it does** | one row per ability: an icon, a name, what it does in one plain sentence, and **when** ("from the start", "every 8 s", "**at 50% health**", "when it takes a hit from…"). The 50% line matches the marker on the boss bar |
| **It brings** | escorts and summons (portraits, count, with their own resist icons), e.g. the Mire Hag's bog spawn |
| **Your record** | after the first meeting: times dispelled, best time. First meeting: a "New" tag |

- Spoilers: the Codex still hides boss names until met; the dossier doesn't, because the boss is
  arriving anyway.
- Touch: all rows and icons tappable; the card scrolls on small screens.
- During the boss drift the existing name plate and boss bar stay; the boss bar's 50% marker is
  tappable and shows that ability's line.
- **No "What helps" section** (removed 2026-09-30, user: "remove the what helps"): the ability and
  resist rows say enough; the hints were hand-holding. `EnemyData.tips` is no longer shown.

**Data (for the build):** per boss in `EnemyData`: a `title`, an ability list (name, icon, text,
when; stat numbers filled from the data, never hand-typed), and the escort list
from the existing followers / summon fields. Normal nightmares reuse `trait_text` plus the new
resist / immune rows.

## Choice screens (time stops)

**Rest order:** rest bonus toast → **family pick** (boss rests) → **Dream** → **Omen** (from drift 10)
→ **boss dossier** (the act's start: run start and act-break rests; a short reminder at the rest
opening a boss block) → free building → Start. Each choice screen can be **minimised** to look at the map first (a
"peek" button), then reopened.
- **A minimised choice still blocks the next drift** (bug, 2026-09-30, user: "I can hide the Dream
  choice and start the wave"). While any choice (family pick, Dream, Omen) is open or minimised, Start
  / Enter / Auto-drift / call early can't begin a drift. The Start button changes to the pending
  choice ("Choose a Dream", "Face an Omen or Clear Skies", "Pick a family") and reopens it. Building,
  selling and clearing stay allowed while peeking. The dossier is information only, so it doesn't block.

### Family pick

Three large cards, one per family: portrait, name, one-line identity ("soothe over time"), the
statuses it applies, and small previews of its two branches. Family Blessings (when fewer than 3
new families remain) use the same card with a blessing border.

**Memory Warden card: PARKED** (Memory Wardens cut for now, 2026-09-29; kept for a possible return).
Was: (2026-09-29, user): in the family pick right after a boss whose Memory
Warden the player has grown (first dispel of that boss, `meta_design.md`), the Memory Warden gets
its **own card**, not a normal family card, so it reads as that boss's reward:
- **Gold / dream-fruit border** instead of a family colour, with a soft glow.
- Heading *"A Memory returns"* above the Warden's name and portrait.
- One flavour line tied to the boss just dispelled (e.g. *"The Hollow Stag's light remembers
  you."*), then its identity line and statuses like any family card.
- A small **"Unique"** tag: only one on the map at a time.

### Dream

- Three cards. **Rarity** is shown by frame colour **and** a gem shape: Common circle, Uncommon
  diamond, Rare **hexagon**, Legendary **star** (settled 2026-09-29 to match the game as built; the earlier "Rare star, Legendary crown" is dropped).
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
| Grow selected Warden | **Q / E / Z** grow into the 1st / 2nd / 3rd option in the Warden panel (e.g. Mossback / Standing Stone / Cairn), each Grow button showing its key badge like Sell (X) and Nurture (R); **G** still grows into the first option (2026-09-30, user: "add hotkeys when growing into"). All rebindable in Settings → Controls. A locked option's key opens the Remember tree on it, like clicking |
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
- [ ] Boss dossier at the act's start (run start, act-break rests), a reminder at the rest opening
      a boss block (reopen from "Boss in N")
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
