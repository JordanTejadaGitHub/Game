# Project_T — Maze Tower Defense Roguelite

2D top-down maze tower defense with roguelite progression, built in **Godot 4.7** with **GDScript**.

## Current takeover entry — 2026-10-11

Read [documentation/claude_handoff.md](documentation/claude_handoff.md) before changing files. It records current-main integration, approved rank/All-Rounder rules, UI/onboarding fixes, D: launch/test commands, recorded validation and performance/playtest limits. Main has substantial uncommitted work: preserve it; do not automatically commit or push. Older prototype-only plans are historical and do not override this handoff.

## Game concept
- **Towers are walls.** The player builds the maze; enemies path around towers to reach the goal.
  A placement that would fully block the path must be rejected.
- Procedurally generated map each run (grass, stone border, trees/details from noise).
- Waves of enemies; after each wave the player picks 1 of 3 random upgrades (roguelite).
- Persistent meta-progression between runs via the Memory Grove and profile autoload.
- Art: 64x64 pixel art. Environment: original sheets in `assets/environment/<act>/`
  (`documentation/environment_assets.md`); creatures/Wardens from the generators in `tools/`.
- **Dark fairytale** (`documentation/story.md`): enemies are **nightmares** hunting the Heartwood's dream; cute Warden
  spirits are the warm contrast. Towers = "Wardens", gold = "Dew", lives = "leaves", waves = "drifts", in-run unlock
  currency = "Dreamlight", upgrades = "Dreams". Many files and code ids keep old cozy names (`leaf_bug` = Shade,
  `cleansed` = dispelled, …; table in `story.md`). Player-facing text always uses the new names.
- Full runs are drifts 1–100 in blocks of 5 with rests, bosses at 25 / 50 / 75 / 100; the demo ends at drift 50.

Original design docs are in `documentation/*.docx` (structure, 15-card dev plan). Design index:
`documentation/game_design.md`; plan / next up: `documentation/design_plan.md`.

## Reference index (read the section before touching that area)
Full system descriptions live in **[documentation/claude_reference.md](documentation/claude_reference.md)** (moved
verbatim from this file on 2026-10-25). One line per area:
- **Current status**: what's built (map, pathing, building, combat, obstacles, run structure, Dew economy) → reference "Current status".
- **Dreams and Wardens**: statuses, resistances, TowerData / Tower / DreamState, Test Grove, DamageLog, card kinds, Omens → "Dreams and Wardens" (+ `tower_design.md`, `dream_design.md`).
- **Run flow**: RunState, DriftDirector, Dew pot, drift data, EnemyData, boss pools, selling / selection, GameSpeed, HUD → "Run flow" (+ `run_design.md`, `acts_1_2.md`, `acts_3_4.md`).
- **Run end, saving, onboarding**: title, HeartwoodMemory, Seeds, RunHistory, RunSaver, Whispers, HUD screens, nightmare info / dossier, combat feedback, Reactions UI, Codex → "Run end, saving, onboarding" (+ `screens_ui.md`, `onboarding.md`).
- **Meta**: Grove tech tree, UnlockData, HeartwoodMemory profile, MetaRun, Blessings, Grove screen, presets, Dev Grove → "Meta" (+ `meta_design.md`).
- **Palette and Audio**: Heartwood 32 palette + DetailPass, Sound autoload, SoundHooks, mix → "Audio" (+ `art_direction.md`, `audio_direction.md`).
- **Layout**: scenes, y-sort, map scripts and pathing API, obstacles, tiles, lighting, enemy / tower scripts, ranks, attack kinds, late game, Reactions, Potency, Kinships, Dream ghost, Legendaries' hooks, UI style "Moon-glass", HUD, input actions, resources → "Layout" (+ `ui_style.md`).
- **Dated design integrations** (2026-10-09 on): status balance, Exposed, unique Dream successors, maze economy, Dream build overhaul, rank-V, Callings, run-shaping cards, starter class sets, lent cards, Calling evolutions, Legendaries / Waymark → "Dated design integrations" (+ `dream_council_review.md`, `maze_economy.md`).

## Hard rules that bite (details in the reference)
- Dew: always `run_state.spend_dew(cost)` (false + `dew_short` when short), never subtract directly.
- Game code draws only palette colours (`Palette.*`, `UiStyle` tokens in `scripts/ui/`); raw colours only for
  multipliers (mark the line "multiplier") or accessibility (mark "Accessibility"). `tests/test_palette.gd` checks.
- Never parent effects under `%EnemyContainer` (its children are all nightmares) or `%TowerContainer`; use `Reactions._world(node)`.
- Confusing names: `path.gd` = `class_name PathGenerator`, `path_generator.gd` = `class_name FindPath`;
  `enivornment_object_generator.gd` is misspelled. Rename via the Godot editor, not the shell.
- Attack code reads `Tower.attack_data`, not `tower_data` (Graftling copies). New effect damage uses an effect tag.
- When re-routing a nightmare, pass `enemy.passed_waymark` to `get_path_from(cell, passed)`.
- Tests never touch the player's saves: don't smoke run with `--scene res://scenes/main.tscn` or `grove.tscn`
  (they write to user://); the title scene is safe. `RunSaver.file_path` / `HeartwoodMemory.file_path` take temp files.
- After changing `UiStyle`, re-run `tools/ui_theme_generator.gd`. After art changes, re-run the generator, then `--import`.

## Conventions
- Tabs for indentation, typed GDScript (`var x: int`, `-> void`), snake_case files.
- Data lives in custom `Resource`s (`EnemyData`, `Grid`, `TileMapLocation`); new content types
  (towers, upgrades, waves) should follow the same pattern.
- Grid coords vs pixels: use `Grid.calculate_map_position()` / `calculate_grid_coordinates()`;
  never mix them.
- Frame-rate independence: scale by `delta`; for smoothing use `lerp(a, b, 1.0 - exp(-k * delta))`.
- Keep `.tscn` hand-edits to simple property/wiring changes; tell the user when something is
  easier to set up in the editor (TileSets, SpriteFrames, complex node trees).
- Commit `.uid` and `.import` files; `.godot/` and `*.tmp` are ignored.
- When you change a system, update its section in `documentation/claude_reference.md` (not this file).

## Working in parallel (many chats, one folder)
Most chats work directly in this folder on `main`. So nobody breaks anyone else:
- Commit small and often, and stage only your own files by explicit path (`git commit -- <paths>`,
  never `git add -A` / `commit -a`). Never commit, revert or stash another chat's uncommitted files.
  If they block you, message their owner.
- Only save edits that parse. A half-edited script breaks every other chat's test runs. After adding a
  `class_name`, a new script or new art, run `--import` and commit it (with its `.uid` / `.import`)
  right away.
- Editing a file another chat owns (see the `Owner:` notes in the design docs / session memory):
  tell its owner first, keep the change small, and tell them the commit.
- A worktree (own folder + branch, merged by the Main session after "ready <hash>") is only for big or
  risky work: long refactors, experiments you may throw away, or two chats needing the same file
  at once. Cloud sessions are worktrees by nature: they push a branch, and Main merges and tests it here.
- Tests use per-process temp files (`"user://test_x_%d.json" % OS.get_process_id()`): every checkout
  shares one `user://`, so fixed names collide when two chats test at once.
- Pushing: only the Main session pushes `main`, and only a commit the full suite (all
  `tests/test_*.gd`) passed on.

## Verifying changes
Git repo root is the parent folder `D:\Projects\Game` (this project is `Project_T/`).

Run headless to catch script/parse/runtime errors after every change (exit 0 and an empty log
after the banner = clean):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\Projects\Game\Project_T\tools\godot_dev.ps1" smoke --headless --path "D:\Projects\Game\Project_T" --quit-after 300
```

After adding a new `class_name`, run once with `--import` (same args, no `--quit-after`) so the
global class cache knows it; otherwise headless runs fail to parse scripts that use it.

Gameplay logic can be tested headless with a `extends SceneTree` script run via
`--script <path> --fixed-fps 60` that instantiates `res://scenes/main.tscn`, drives it (e.g.
`TowerPlacer._try_build(cell)`), and `quit(failures)`. `--fixed-fps 60` makes `delta` realistic.

**Nothing project-related on C:** (user, 2026-10-05). Run every test, sim and tool through the wrapper, which
points user:// (`%APPDATA%`) at `D:\Projects\logs\userdata`: `bash /d/Projects/logs/scripts/godot_dev.sh <args>`
or `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\Projects\Game\Project_T\tools\godot_dev.ps1" <name> <args>` (in PowerShell pass a bare `--` quoted: `'--'`).
Scratch files from game code go through `DevPaths.scratch(name)` (D: in dev builds, user:// elsewhere); logs,
renders and captures go under `D:\Projects\logs\`, never a C: temp folder.

Headless can't show visuals — for anything visual, ask the user to press Play and describe it.
