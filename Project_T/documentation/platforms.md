# Platforms: PC first, then mobile

Added 2026-09-27. **Order:** Steam (PC, Steam Deck) first; a **mobile port (iOS and Android)** later
to widen sales. Godot exports to both. Nothing needs building for mobile yet, but **design choices
made now must not block it**. This doc is the checklist.

## Rules for everything we design and build from now on

1. **No hover-only information or actions.** Everything shown on hover (obstacle cost, route
   preview, nightmare info, tooltips, Dream card highlights) must also be reachable by **tap /
   select**. On PC hover stays as a shortcut.
2. **No right-click-only or keyboard-only actions.** Every action (sell, grow, nurture, cancel,
   start drift, speed) has an on-screen button. Hotkeys are shortcuts, never the only way.
3. **Touch targets at least 48 px** at the reference resolution, with space between them; text at
   least 16 px on a Steam Deck, larger on phones (UI scale setting).
4. **Gestures have one meaning each** (see the touch map below); never make a player guess whether
   a drag builds, selects or scrolls.
5. **Performance budget:** a full late-game maze (40 Wardens, 100+ nightmares, effects, lighting) at
   60 fps on a mid-range phone. Keep particle counts, lights and per-frame pathfinding in check;
   profile on a mid-range Android device before the port.
   **Revised 2026-09-28** (playtest: "super laggy" with ~150 Sprouts at drift 46; Sprout swarms are a
   real build, so huge mazes are normal): the worst case is **every buildable cell filled (~200
   Wardens) + 150 nightmares + a Reaction chain**. Targets (revised again 2026-09-29, user decision via Main): scripts **≤ 10 ms at p95** (60% of a 60 fps frame) in the stress case **at 1×** on PC; **3× is a stretch goal**, measured and printed by `test_perf_stress` and revisited before release (so far: 1× p95 ~11 ms on a loaded machine, borderline; 3× ~22 ms; the manager-node refactor was dropped, no measurable gain); 60 fps on a
   mid-range phone at 1×. Rules:
   - No per-frame work that scales with **Wardens × nightmares** (targeting uses a spatial grid or a
     cheap interval, not a scan of every nightmare every frame).
   - Card / Kinship / network / Heart of the Maze queries are **cached** and only recomputed when
     the map changes (a Warden planted, grown or sold, or the route changing), never per hit.
   - **Lights and glows are pooled or merged:** no PointLight2D per Warden; one light per cluster
     or a baked glow layer.
   - Idle animations and UI marks (badges, pips, chips) are cheap draws, updated only when changed.
   - A headless **stress test** (`tests/test_perf_stress.gd`: the worst case above) reports
     frame-time percentiles and fails over budget.
6. **Short sessions work:** the mid-run save at every rest already allows 5-minute play; keep it.

## Touch controls (target design for the port)

| Action | PC | Touch |
|---|---|---|
| Move the camera | WASD / edge | **one-finger drag** on empty ground |
| Zoom | mouse wheel | **pinch** |
| Place a Warden | pick in the bar, click a cell | pick in the bar, **tap a cell**: the ghost, range and route preview appear with **✓ / ✕** buttons; tap ✓ to build (drag the ghost to adjust) |
| Select a Warden | click | tap |
| Select several | drag box, double-click | a **"Select" mode button**, then drag to box-select; **"Select all of this kind"** button in the Warden panel (no double-tap needed) |
| Nightmare / obstacle info | hover | **tap** (shows the info card; tap elsewhere to close) |
| Clear an obstacle | click | tap it (shows cost + route preview), then **✓** |
| Sell, grow, nurture | panel buttons, Delete / G / R | panel buttons |
| Cancel | right-click / Esc | **✕** button, or tap empty ground |
| Pause, speed, start drift | Space / Tab / Enter | on-screen buttons (already exist) |

## Things in the current design that need a touch answer

| Feature (doc) | Issue | Touch answer |
|---|---|---|
| Obstacle hover tag and route preview (`screens_ui.md`) | hover | tap shows it; ✓ to clear |
| Nightmare info on hover | hover | tap a nightmare |
| Build ghost follows the mouse | hover | tap to place the ghost + ✓ / ✕ |
| Right-click sells a Warden | right-click; also easy to misclick on PC | Sell button only (recommended on PC too) |
| Double-click selects the same kind | double-tap conflicts with zoom on phones | "Select all of this kind" button |
| Drag-box select | drag = camera pan on touch | "Select" mode |
| Dream card hover highlights affected Wardens | hover | tap a card once to preview, tap again (or a Take button) to choose |
| Hotkeys 1–9 | keyboard | the Warden bar (already there) |

## Screen size

- Landscape only. Design the HUD for **1280×720 at UI scale 1.0** as the smallest target (phones
  are wider, e.g. 19.5:9; keep the HUD anchored to edges and respect notch safe areas).
- Panels (Warden panel, dev dock) must fit or become sliding drawers on phones.
- The map benefits from the camera overscroll already added (keep the Heartwood clear of the HUD).

## Business notes (decide nearer the port)

- **Premium (pay once)** fits a roguelite tower defense and the Steam version; free-to-play would
  need a different design. A mid price (e.g. $4.99–$7.99 on mobile) is typical for premium ports.
- The demo idea becomes a **free trial** (e.g. act 1 free, unlock the rest once).
- Mobile store pages need their own screenshots and a short portrait-free trailer cut.
