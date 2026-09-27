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
*cleansed*, not killed: blight shader fades to full colour, then they fade out).
Temporary: `EnemyContainer.start_spawning()` spawns a Leaf Bug every 2 s forever (stand-in for waves).
Design, build order and story: `documentation/game_design.md`, `documentation/story.md` (cozy tone;
enemies are "blighted creatures", towers are "Wardens", gold is "Dew", lives are "leaves").
Next up: step 2 of the build order (leaves, Dew, tower cost, lose condition, HUD).

## Layout
- `scenes/main.tscn` — root scene: MapGenerator (Ground / Path / EnvironmentObject TileMapLayers),
  TowerContainer, EnemyContainer (spawner), HUD, GameCameraNode.
- `scripts/map/` — `map_generator.gd` orchestrates generation. Note the confusing names:
  `path.gd` defines `class_name PathGenerator` (draws path tiles), `path_generator.gd` defines
  `class_name FindPath` (AStar2D wrapper). `enivornment_object_generator.gd` is misspelled.
  Rename via the Godot editor (FileSystem dock), not the shell, so references update.
  `map_generator.gd` is also the pathing/building API: `is_buildable`, `can_block`,
  `get_path_if_blocked`, `block_cell`, `get_path_from`, and the `path_changed` signal.
- `scripts/enemy/` — `enemy.gd` (walks cell to cell along a grid path; `set_path` re-routes it),
  `enemy_spawner.gd` (on `path_changed`, re-routes every enemy from its `get_target_cell()`).
- `scripts/tower/` — `tower.gd` (`Tower`, draws a placeholder block when `TowerData.texture` is
  empty), `tower_placer.gd` (`TowerPlacer`: build mode, ghost, route preview, validation).
  Towers can't go on border/trees/towers/start/end, on a cell an enemy occupies, or anywhere that
  would leave the start or any live enemy without a path to the end.
- `scripts/tower/tower.gd` also handles attacking (stats in `TowerData`: range in cells, damage,
  attacks/sec); `projectile.gd` (`Projectile`, script-only node). Enemies in the `"enemies"` group
  are targetable; cleansing removes them from it and from `EnemyContainer.get_enemies()`.
- `shaders/blight.gdshader` — grey "blighted" look; `blight` uniform 1 → 0 on cleanse.
- `tests/` — headless `extends SceneTree` tests (e.g. `test_combat.gd`).
- `scripts/ui/hud.gd` — HUD (Build Tower button, synced with build mode).
- Input actions: `toggle_build_mode` (B), `place_tower` (LMB), `cancel_build` (RMB / Esc).
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
