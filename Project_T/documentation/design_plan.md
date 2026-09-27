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
| 2 | **Art and audio direction** | style guide: palette, outlines, sizes, animation counts, how blighted vs cleansed reads, tileset list, UI style; music mood per phase, key SFX (the cleanse) | original art (longest lead time for the demo) |
| 3 | **Accessibility** | blight must not rely on colour alone (grey vs colour is the core visual): a second cue such as haze, outline or icon; text size, reduced motion, key remapping, colour-blind check of status icons | art direction (do together) |
| 4 | **Balance framework** | target soothe vs creature health per drift; how much of a drift should leak at "par"; spec for a simulation tool | tuning 100 drifts |
| 5 | **Soft mechanics review** | tighten per "cozy theme, not easy gameplay": rest refund 100% → 75%? leaf regrowth +3 per act → none? | run rules |
| 6 | **Dream pool to ~70 cards** | family cards for Pebbling, Rootling, Acorn; **Family Blessings** list; more Entwined pairs | full game |
| 7 | **Acts 3–4 content** | stats for ~13 creatures (Dusk Moth, Mole, Wandering Hare, Tortoise, Newt, Owl, Snail, Glowworm, Mother Spider, Badger, Bee Swarm, Squirrel, Mossling); Mother Moth; The Hollow Oak incl. its Blight Level 10 phase; drifts 51–100 | full game |
| 8 | **Controller / Steam Deck** | building with a gamepad: cursor, snapping, selecting Wardens, route preview, menus | demo (Deck-playable) |
| 9 | **Story text** | final wording of the 10 Memories, boss cleanse lines, flavour-text library, The Long Walk Out sequence | full game |
| 10 | **Biomes and special tiles** | the 2 Grove forests (look, obstacles, rule twist); special tiles (waystones, dew pools) | full game |
| 11 | **Forest Journal** | parked for later | post-launch? |

**Open decisions:** title (keep "The Heartwood Remembers"?), Memory 5's tone, whether The Long Walk
Out is worth building, committing the shared design docs.

## 2. Content to produce

| Content | Amount (full game) | Demo needs |
|---|---|---|
| Creature sprites (walk ×3 directions; the shader does blighted) | ~25 + 4 bosses | 7 + 2 bosses |
| Warden sprites (idle + attack) | ~33 (6 families × 5, Sprout, Thornwall, Bramble) | ~16 |
| Projectiles, status icons, cleanse and hit effects | ~20 | most |
| Tilesets (ground, path, border, obstacles) + the Heartwood | 3 biomes | 1 |
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
- **Creatures:** behaviours (flying, rolling, splitting, following, burrowing, hiding), elites,
  bosses (Old Stag, Great Toad first).
- **Meta:** `HeartwoodMemory` save, Grove, Memories, milestones, Blight Levels, demo Seed import.
- **Around the game:** title and scene flow, settings, localization, controller, accessibility
  options.
- **Steam:** achievements, cloud saves, demo build.
- **Tools:** Dream offer simulation (exists: `tests/test_dreams.gd`), a balance simulation.

## 4. Release and business

Title check (Steam, itch.io, trademarks) → Steam page with capsule and trailer → private playtests →
public demo 1–2 months before a Next Fest → Next Fest → launch. Also: press kit, a community space
(Discord), pricing, and a licence check for anything not original (`demo_scope.md`).
