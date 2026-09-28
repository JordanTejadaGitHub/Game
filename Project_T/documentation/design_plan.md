# Design Plan: what a fleshed-out game still needs

Status as of 2026-09-27. The overview of the whole design is `game_design.md`; this doc tracks
**what's done and what's missing**, across design, content, systems and release.

## Designed (first drafts done)

| Doc | Covers |
|---|---|
| `story.md` | tone, premise, the Hollow |
| `pitch.md` | hook, tagline, store page, capsule, trailer |
| `run_design.md` | 100 drifts in 4 acts, blocks and rests, rules, economy, scaling, Omens |
| `tower_design.md` | Warden families, evolutions, statuses, synergies, archetypes |
| `warden_stats.md` | numbers for every Warden, new mechanics needed |
| `enemy_design.md` | creature roster, traits, counters, bosses |
| `acts_1_2.md` | creature and boss stats, special drifts, drifts 1–50 |
| `dream_design.md` | Dream pool, offer rules, Deepened / Entwined / Bittersweet cards, status numbers |
| `meta_design.md` | Seeds, Memory Grove, milestones, Blight Levels, Memories, true ending |
| `onboarding.md` | teaching across the first runs |
| `screens_ui.md` | screen flow, run HUD layout, panels, choice screens, settings, controls |
| `demo_scope.md` | demo content (drifts 1–50, no meta), timeline, success measures |

All numbers are guesses until act 1 is playable; **playtesting is the biggest missing piece**.

## 1. Design still to do (the design chat)

In recommended order:

| # | Topic | What it needs | Needed for |
|---|---|---|---|
| 1 | ~~Screens and HUD~~ | **done: `screens_ui.md`**; open question: Warden targeting modes | — |
| 2 | **Art and audio direction** (**drafted: `art_direction.md`, `audio_direction.md`**; UI style still to do) | style guide for the **dark fairytale** (`story.md`): warm Wardens vs cold nightmares, palette, outlines, sizes, animation counts, nightmare look and dispel effect, a darker dream-forest tileset, UI style; music mood per phase (dread building during drifts), key SFX (the dispel, nightmare whispers) | original art (longest lead time for the demo) |
| 3 | **Accessibility** | warm vs cold must not rely on colour alone: nightmares also need shape cues (silhouette, glowing eyes, haze); text size, reduced motion, key remapping, colour-blind check of status icons; a note on scary content for younger players | art direction (do together) |
| 4 | **Balance framework** (**spec: `balance_simulation.md`**, 2026-09-28; targets in `run_design.md`) | target damage vs nightmare health per drift; how much of a drift should leak at "par"; spec for a simulation tool | tuning 100 drifts |
| 5 | **Soft mechanics review** | tighten now that the theme is darker too: rest refund 100% → 75%? leaf regrowth +3 per act → none? | run rules |
| 6 | **Dream pool to ~70 cards** | family cards for Pebbling, Rootling, Acorn; **Family Blessings** list; more Entwined pairs; **Rare tier gap** (2026-09-28): many boards have 0–1 eligible Rares in acts 1–2 (Few and Mighty sim, c64183a); add ~6 Rares with loose Needs (general and per family) | full game |
| 7 | ~~Acts 3–4 content~~ **done** (`acts_3_4.md`, all four bosses built; boss dossier data 2026-09-28) | behaviour detail and drift plan for the act 3–4 nightmares (Lurker, Gravecrawler, Sleepwalker, Barrow Wight, Drowned One, Watcher, Ash Crawler, Will-o'-Wisp, Widow, Shellbound, Whisper Swarm, Dream Thief, Weeper; stats exist in `enemy_design.md`); the Moth Queen; The Hollow Oak incl. its Blight Level 10 phase; drifts 51–100 | full game |
| 8 | **Controller / Steam Deck** (**later**, user 2026-09-28; proposal: a tile-snapping cursor, A place/select, B cancel, bumpers switch Wardens, a radial menu for grow / nurture / sell) | building with a gamepad: cursor, snapping, selecting Wardens, route preview, menus | demo (Deck-playable) |
| 9 | **Story text** | final wording of the 10 Memories, boss dispel lines, nightmare lore lines, flavour-text library, The Long Walk Out sequence | full game |
| 10 | **Biomes and special tiles** | the 2 Grove forests (look, obstacles, rule twist); special tiles (waystones, dew pools) | full game |
| 11 | **Forest Journal** (now a bestiary) | parked for later | post-launch? |

**Open decisions:** ~~tagline~~ (B, decided), ~~title~~ (**Heartwood TD**, decided 2026-09-28; check Steam / itch.io / trademarks), the **art style** (undecided), whether
The Long Walk Out is worth building. (Memory 5's tone is settled by the darker theme.)

## 2. Content to produce

| Content | Amount (full game) | Demo needs |
|---|---|---|
| Nightmare sprites (movement ×3 directions + dispel; dark, translucent, glowing eyes) | ~25 + 4 bosses | 9 + 2 bosses |
| Warden sprites (idle + attack) | ~33 (6 families × 5, Sprout, Thornwall, Bramble) | ~16 |
| Projectiles, status icons, dispel and hit effects | ~20 | most |
| Tilesets (ground, path, border, obstacles) + the Heartwood | 3 biomes | 1 (**forest drawn: 4 act palettes in `assets/environment/`, in the game, with lighting and edge fog**) |
| UI art (frames, buttons, cards, icons) | full set | full set |
| Grove garden + 10 Memory illustrations | full set | Grove teaser only |
| Music | ~6–8 tracks (build, drift, boss per act, Grove, title) | ~3 |
| Sound effects | ~60 | ~40 |
| Marketing: capsule art, trailer, screenshots | 1 set | 1 set |

## 3. Systems to build (the coding chats)

Per the build order in `game_design.md`; current status in `CLAUDE.md`.

- **Run flow:** blocks of 5, rests, Auto-drift, call early, family picks, Dreams, Omens, leaves and
  losing, results, mid-run save.
- **Wardens:** evolution UI, remaining families' mechanics (`warden_stats.md`), selling.
- **Nightmares:** the theme change (names, nightmare shader, dispel effect), behaviours (through
  walls, sprinting, splitting, following, burrowing, hiding), elites, bosses (the Hollow Stag and
  the Mire Hag first).
- **Meta:** `HeartwoodMemory` save, Grove, Memories, milestones, Blight Levels, demo Seed import.
- **Around the game:** title and scene flow, settings, localization, controller, accessibility
  options.
- **Steam:** achievements, cloud saves, demo build.
- **Tools:** Dream offer simulation (exists: `tests/test_dreams.gd`), a balance simulation.

## 4. Release and business

Title check (Steam, itch.io, trademarks) → Steam page with capsule and trailer → private playtests →
public demo 1–2 months before a Next Fest → Next Fest → launch. Also: press kit, a community space
(Discord), pricing, and a licence check for anything not original (`demo_scope.md`).
