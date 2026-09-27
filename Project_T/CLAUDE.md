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
Done: map generation, A* path + path tiles, camera (WASD + wheel zoom, clamped), data-driven enemy
(Leaf Bug) that walks the path.
Next milestone: grid tower placement with path blocking + live re-pathing (see below).
Not started: tower attacks/projectiles, wave manager, core/lives, HUD, upgrades, save data.

## Layout
- `scenes/main.tscn` — root scene: MapGenerator (Ground / Path / EnvironmentObject TileMapLayers),
  TowerContainer, EnemyContainer (spawner), HUD, GameCameraNode.
- `scripts/map/` — `map_generator.gd` orchestrates generation. Note the confusing names:
  `path.gd` defines `class_name PathGenerator` (draws path tiles), `path_generator.gd` defines
  `class_name FindPath` (AStar2D wrapper). `enivornment_object_generator.gd` is misspelled.
  Rename via the Godot editor (FileSystem dock), not the shell, so references update.
- `scripts/enemy/` — `enemy.gd` (PathFollow2D movement), `enemy_spawner.gd`.
- `resource/` — data resources + their scripts: `map_grid.tres` (`Grid`: 45x36 cells, 64px),
  `tile_map_location_data.tres` (atlas coords of every tile), `enemy/*.tres` (`EnemyData`).
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

Headless can't show visuals — for anything visual, ask the user to press Play and describe it.

## Planned architecture for the maze milestone
- Replace `FindPath` (custom AStar2D) with `AStarGrid2D`: towers/trees/border = `set_point_solid`.
- Validate placement: mark solid → check a path still exists → revert if not.
- Enemies should re-route mid-wave from their current cell (cell-to-cell movement or a flow field
  from the goal) instead of a baked per-enemy `Curve2D`.
- Reuse `PathGenerator.draw_unit_path()` (Line2D) as the placement preview.
