# Project_T — Maze Tower Defense Roguelite

2D top-down maze tower defense with roguelite progression, built in **Godot 4.7** with **GDScript**.

## Game concept
- **Towers are walls.** The player builds the maze; enemies path around towers to reach the goal.
  A placement that would fully block the path must be rejected.
- Procedurally generated map each run (grass, stone border, trees/details from noise).
- Waves of enemies; after each wave the player picks 1 of 3 random upgrades (roguelite).
- Persistent meta-progression between runs via an autoload singleton (planned).
- Art: 64x64 pixel art (Foozle "Spire" tileset + enemy pack in `assets/`).

Original design docs are in `documentation/*.docx` (structure, 15-card dev plan).

## Current status
Done: map generation, AStarGrid2D pathing + path tiles, camera (WASD + wheel zoom, clamped),
data-driven enemy (Leaf Bug), **tower building** (build mode, placement validation, enemies re-route),
**combat** (towers target the enemy closest to the goal and fire homing spore puffs; enemies are
*cleansed*, not killed: blight shader fades to full colour, then they fade out),
**clearable obstacles** (random map each run: ridges of rocks/trees from alternating walls make
the route zig-zag, plus noise tree clusters and scattered rocks; outside build mode, hover shows
cost + the route that would open, left-click clears. Obstacles are "Withered Tree" (Tend) and
"Mossy Boulder" (Move); `RunState.obstacles_tended` counts clears for +1 Seed each at run end).
**Run structure** (`documentation/run_design.md`): act 1 only for now (5 drifts; winning = clearing
drift 5). See "Run flow" below.
Design, build order and story: `documentation/game_design.md` (overview), `tower_design.md`
(Wardens, statuses, synergies), `enemy_design.md` (creature roster), `documentation/story.md` (cozy tone;
enemies are "blighted creatures", towers are "Wardens", gold is "Dew", lives are "leaves").
**Dew economy**: `RunState` (`%RunState`, `scripts/run/run_state.gd`) holds Dew; `starting_dew`
export (60). Earned when a creature is cleansed (`EnemyData.dew_reward`, "+N Dew" `DewPopup`),
spent on Wardens (`TowerData.cost`) and obstacle clears (`ObstacleData.clear_cost`). Always go
through `run_state.spend_dew(cost)` (returns false + emits `dew_short` when short) — never subtract
directly. HUD shows the Dew counter (`%DewLabel`), dims unaffordable Warden buttons.
Next up: Dreams (after drifts 1, 3, 5…, see run_design.md), results screen with Seeds, acts 2–3
drifts, Old Stag's Thornwall knock-down and its own art.

## Run flow
- `RunState` also holds leaves (`starting_leaves` 20, `max_leaves`), `lose_leaves` / `regrow_leaves`,
  `end_run(won)` + `run_ended` signal, `is_over`. `earn_dew_at(amount, pos)` = add Dew + popup.
- `DriftDirector` (`%DriftDirector`, `scripts/run/drift_director.gd`): `drifts: Array[DriftData]`
  (`resource/drift/act1/drift_N.tres`). Build phase = no drift on the field; `start_next_drift()` is
  Start Drift, or call early once the latest drift finished arriving (bonus: +1 Dew per 2 s skipped,
  estimated from the slowest creature's remaining walk, capped at the drift's clear bonus). Tracks
  creatures per drift (`_drift_of`), pays the clear bonus (15 + 5×n, +5 if no leaf lost) when a
  drift's last creature is resolved, regrows leaves at act breaks (every `drifts_per_act`), wins
  after the last drift. Non-boss health × `health_growth_per_drift`^(n-1).
- Drift data: `DriftData.groups: Array[DriftGroup]`; `DriftGroup.entries: Array[DriftEntry]`
  (enemy + count, several entries mix evenly), `spacing`, `delay`. `get_schedule()` gives arrival times.
- `EnemyData`: `display_name`, `leaf_cost`, `is_boss`, `sprite_scale`, `split_into`/`split_count`
  (Puffcap → 3 Puffcaplets). Creatures: `resource/enemy/*.tres` (Old Stag uses Bark Beetle frames).
  `EnemyContainer.spawn_enemy(data, health_scale)` returns the enemy; signals `enemy_cleansed`,
  `enemy_reached_goal`, `enemy_split` (emitted before the parent's `enemy_cleansed`).
- Selling: `TowerSeller` (`%TowerSeller`): outside build mode, hover a Warden, RMB / Delete sells for
  `Tower.invested_dew` × 100% (build phase) or 50% (during a drift); `MapGenerator.unblock_cell`.
- Speed: `GameSpeed` (`%GameSpeed`): pause = `get_tree().paused`, speed = `Engine.time_scale`.
  Build/clear/sell tools, HUD, camera and GameSpeed are `process_mode = ALWAYS` so building works
  while paused; the camera divides delta by time_scale so panning stays real-time.
- HUD: `%LeavesLabel`, `%ToastLabel` (`show_toast`), `DriftPanel` (`scripts/ui/drift_panel.gd`:
  drift label, Start/call-early button, speed buttons), win/lose panel with "New run" (reloads scene).

## Layout
- `scenes/main.tscn` — root scene: MapGenerator (Ground / Path / EnvironmentObject TileMapLayers),
  TowerContainer, EnemyContainer (spawner), HUD, GameCameraNode.
- `scripts/map/` — `map_generator.gd` orchestrates generation. Note the confusing names:
  `path.gd` defines `class_name PathGenerator` (draws path tiles), `path_generator.gd` defines
  `class_name FindPath` (AStar2D wrapper; routes are "sticky": a tiny off-route weight makes ties
  between equally short routes keep the current route, set by `PathGenerator.draw()`). `enivornment_object_generator.gd` is misspelled.
  Rename via the Godot editor (FileSystem dock), not the shell, so references update.
  `map_generator.gd` is also the pathing/building API: `is_buildable`, `can_block`,
  `get_path_if_blocked`, `block_cell`, `get_path_from`, and the `path_changed` signal.
  Obstacles: `obstacles` ({cell: `ObstacleData`}), `get_obstacle`, `get_path_if_cleared`,
  `clear_obstacle`, `obstacle_cleared` signal. `map_seed` export: 0 = random map, else reproducible.
  Generation guarantees a route (`_carve_route_if_blocked` clears the fewest obstacles, avoiding ridges).
  `obstacle_clearer.gd` (`ObstacleClearer`) is the hover/click tool; input action `clear_obstacle` (LMB).
  Obstacle types are `resource/obstacle/*.tres` (`ObstacleData`: name, verb, cost, tile atlas coords).
- `scripts/enemy/` — `enemy.gd` (walks cell to cell along a grid path; `set_path` re-routes it),
  `enemy_spawner.gd` (on `path_changed`, re-routes every enemy from its `get_target_cell()`).
- `scripts/tower/` — `tower.gd` (`Tower`, plays the idle loop from `TowerData.texture` — a row of
  `frame_count` 64x64 frames — or draws a placeholder block when it's empty), `tower_placer.gd`
  (`TowerPlacer`: roster `towers`, `select_tower()`, build mode, ghost, route preview, validation).
  Wardens: `resource/tower/*.tres` (Sprout, Thornwall + 6 bases; all buildable until Dreams exist),
  art in `assets/towers/` (generated by `tools/tower_art_generator.gd`). The HUD's `%TowerBar` has
  a button per Warden (hotkeys 1-8). Thornwall has `can_attack = false`.
  Towers can't go on border/trees/towers/start/end, on a cell an enemy occupies, or anywhere that
  would leave the start or any live enemy without a path to the end.
- `scripts/tower/tower.gd` also handles attacking (stats in `TowerData`: range in cells, damage,
  attacks/sec). Each attack plays `attack_texture` (`<warden>_attack.png`, 6 frames) and fires on
  `attack_release_frame`: PROJECTILE kinds spawn at `attack_origin` (px from centre, from
  `assets/towers/attacks.json`); PULSE kinds (Rootling, Acorn) soothe everything in range.
  `projectile.gd` (`Projectile`, script-only node; animates and rotates
  `TowerData.projectile_texture`, 16x16 frames drawn pointing right, else a coloured puff). Enemies in the `"enemies"` group
  are targetable; cleansing removes them from it and from `EnemyContainer.get_enemies()`.
- `shaders/blight.gdshader` — grey "blighted" look; `blight` uniform 1 → 0 on cleanse.
- `tests/` — headless `extends SceneTree` tests (e.g. `test_combat.gd`).
- `scripts/ui/hud.gd` — HUD (Warden bar + 1-8 hotkeys, Dew counter).
  `world_label.gd` (`WorldLabel.draw_tag` for world-space text tags, `cost_color`),
  `dew_popup.gd` (`DewPopup`).
- Input actions: `toggle_build_mode` (B), `place_tower` (LMB), `cancel_build` (RMB / Esc),
  `sell_tower` (RMB / Delete), `start_drift` (Enter), `pause_game` (Space), `cycle_speed` (Tab).
- `resource/` — data resources + their scripts: `map_grid.tres` (`Grid`: 45x36 cells, 64px),
  `tile_map_location_data.tres` (atlas coords of every tile), `enemy/*.tres` (`EnemyData`),
  `tower/*.tres` (`TowerData`).
- `animation/` — SpriteFrames (`walk_side`, `walk_up`, `walk_down`).

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

## Verifying changes
Git repo root is the parent folder `D:\Projects\Game` (this project is `Project_T/`).

Run headless to catch script/parse/runtime errors after every change (exit 0 and an empty log
after the banner = clean):

```powershell
& "D:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --quit-after 300
```

After adding a new `class_name`, run once with `--import` (same args, no `--quit-after`) so the
global class cache knows it; otherwise headless runs fail to parse scripts that use it.

Gameplay logic can be tested headless with a `extends SceneTree` script run via
`--script <path> --fixed-fps 60` that instantiates `res://scenes/main.tscn`, drives it (e.g.
`TowerPlacer._try_build(cell)`), and `quit(failures)`. `--fixed-fps 60` makes `delta` realistic.

Headless can't show visuals — for anything visual, ask the user to press Play and describe it.
