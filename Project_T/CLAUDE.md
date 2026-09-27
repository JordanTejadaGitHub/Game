# Project_T — Maze Tower Defense Roguelite

2D top-down maze tower defense with roguelite progression, built in **Godot 4.7** with **GDScript**.

## Game concept
- **Towers are walls.** The player builds the maze; enemies path around towers to reach the goal.
  A placement that would fully block the path must be rejected.
- Procedurally generated map each run (grass, stone border, trees/details from noise).
- Waves of enemies; after each wave the player picks 1 of 3 random upgrades (roguelite).
- Persistent meta-progression between runs via an autoload singleton (planned).
- Art: 64x64 pixel art. Environment: original sheets in `assets/environment/<act>/`
  (`documentation/environment_assets.md`); creatures/Wardens from the generators in `tools/`.

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
**Run structure** (`run_design.md`, `acts_1_2.md`, `demo_scope.md`): the demo run, drifts 1–50 in
blocks of 5 with rests, Old Stag at 25, Great Toad at 50 (winning = clearing drift 50). Title
screen, pause menu, settings, results with Seeds, mid-run save. See "Run flow" and "Run end,
saving, onboarding" below.
Design, build order and story: `documentation/game_design.md` (overview), `tower_design.md`
(Wardens, statuses, synergies), `enemy_design.md` (creature roster), `documentation/story.md` (cozy tone;
enemies are "blighted creatures", towers are "Wardens", gold is "Dew", lives are "leaves").
**Dew economy**: `RunState` (`%RunState`, `scripts/run/run_state.gd`) holds Dew; `starting_dew`
export (45). Earned when a creature is cleansed (`EnemyData.dew_reward`, "+N Dew" `DewPopup`),
spent on Wardens (`TowerData.cost`) and obstacle clears (`ObstacleData.clear_cost`). Always go
through `run_state.spend_dew(cost)` (returns false + emits `dew_short` when short) — never subtract
directly. HUD shows the Dew counter (`%DewLabel`), dims unaffordable Warden buttons.
**Statuses, evolutions, Dreams** (first-playable scope of tower_design.md / dream_design.md): see
"Dreams and Wardens" below.
**Meta** (full game; inert in the demo): Memory Grove, Memories, milestones, Blight Levels, Family
Blessings — see "Meta" below.
Next up: acts 3–4 drifts and bosses (Moth Queen, Hollow Oak incl. Blight 10), the missing final
forms (Puffball, Beacon, Monsoon, …) and their Grove entries, Grove-only Dream cards (Static Bloom,
Twin Puff, Legendaries…), Forests root (biomes), Memory Wardens as boss rewards, localization,
controller / Steam Deck, accessibility, Steam achievements (milestones map to them).

## Dreams and Wardens
- `EnemyStatuses` (RefCounted on each enemy, `enemy.statuses`): damp, drowsy, spored, marked,
  static with dream_design.md numbers; `enemy.apply_status(id, stacks, duration, potency, max)`.
  Potency scales with the Warden's soothe (Spored = 25%/s per stack, Static bolt = 3×). Status dots
  above the health bar. `take_damage` takes floats (fractions carry) and applies Marked.
- Resistances (enemy_design.md): `take_damage(amount, line := "", is_area := false)`: soothe ×
  family (`EnemyData.resists` / `weak_to` vs `TowerData.line`: ×0.65 / ×1.35, constants on
  `EnemyData`) × shape (`single_target_multiplier` / `area_multiplier`) × Marked, then the blight
  coat (`coat_per_hit` / `coat_total`, × health_scale). Always pass the source: `Tower.hit(enemy,
  mult, is_area)` does (pulse, splash, cloud = area). Spored ticks use the applier's line
  (`statuses.spore_line()`), Static bolts count as "light". `status_immune` /
  `status_duration_multipliers` feed `EnemyStatuses`. Grey puff = resisted, sparkle = weak.
  `tests/test_resistances.gd`.
- `TowerData`: `line` (Dream tag), `tier`, `buildable_directly`, `evolve_cost`, `evolves_to`
  (typed `Array[Resource]` on purpose: a self-typed array leaks the script), `applies_status…`,
  `splash_radius`, chain (`chain_targets`, `chain_jump_range`, `storm_every`), cloud
  (`cloud_radius`, `cloud_duration`, `cloud_fog`). `AttackKind`: PROJECTILE, PULSE, CHAIN, CLOUD.
  `get_attack_origin()` reads `assets/towers/attacks.json` (point − 32) so regenerated art stays
  aligned; `attack_origin` is only the fallback.
- `Tower`: effective stats via `DreamState` (group `dream_state`): `get_damage()`,
  `get_attacks_per_second()`, `get_range_cells()`; `hit(enemy)`; `evolve(data, cost)` in place.
  `ChainBolt` / `PathCloud` are script-only effect nodes. Evolve through `TowerPlacer.evolve()`.
- `DreamState` (`%DreamState`): unlocked Warden ids (run starts with sprout + thornwall; base
  Wardens come from the family pick, never Dreams), taken cards (`stacks`), stat/status/rule
  queries, a Dream offer at every `rest_started` (built deferred; boss rests Rare+), `make_offer`,
  `choose`, `skip`, `offer_ready` / `offer_closed`, `to_save` / `load_save`. Cards:
  `resource/dream/*.tres` (`UpgradeData`), loaded from the folder. `unlock_everything` export for debugging.
- **Test Grove** (dev playtest mode, demo_scope.md; `scripts/run/test_grove.gd`, `%TestGrove`):
  debug builds only (`TestGrove.is_available()`), on via settings "Developer" toggle
  (`test_grove`), launch flag `-- --test-grove`, or `TestGrove.force_on` (tests). Sets
  `unlock_everything` (family picks then skip themselves), F9 = +500 Dew, `skip_to(n)` at a rest.
  Tools v2: spawn panel, Target Dummy (`Enemy.unkillable` + `loops_route`), damage meter, damage
  numbers, Inspect (click while paused), `RunState.invulnerable`, `clear_field()` (`Enemy.dispel()`).
- **Unlock all families** (settings "Developer", setting `all_families`, debug builds only;
  `MetaRun.all_families_active()`, `force_all_families` for tests): a normal run with every Warden-root
  Grove family + Dream card added by `MetaRun._apply_all_families()` (also in the demo). The profile's
  unlocks are untouched. `MetaRun.is_dev_run()` (this or Test Grove) = no Seeds banked, no records,
  no whispers / nightmares seen / last first pick written.
- **DamageLog** (`%DamageLog`, `DamageLog.instance`): every soothe is reported by
  `Enemy.take_damage(..., source, tag)` as a `DamageLog.Event` (source Warden, kind hit/status/bolt,
  combos crit/weak/marked/fog/conducted/static with `combo_amount`). Pass the source everywhere:
  `Tower.hit` does; statuses keep their applier (`EnemyStatuses.source(id)`, `apply(..., source)`).
  Per-Warden totals (`get_tower_stats`), `get_dps`, `get_meter_rows`, damage numbers
  (`numbers_mode`). Reuse it for player-facing combat feedback.
- Card kinds from dream_design.md (2026-09-27): **Deepened** (`deepens` = base id, e.g.
  `evergreen_ii`; only offered once the base is owned; replaces the base: `_taken_cards()` drops it,
  rule code reads `rule_level(rule)` 0/1). **Entwined** (`entwined`, ingredients = `requires`;
  guaranteed one slot in the next offer once all are owned, then normal). **Bittersweet** (tag
  `bittersweet`, `cost_description`, act 2+, max 1 per offer, off until `allow_bittersweet`):
  negative `max_leaves_add` / `leaves_now` (never offered if it'd end the run), `rest_bonus_add`,
  `creature_health_bonus`, `rare_dreams_add`, a `set_cost` above the base cost = surcharge, rules
  `overgrown` (`TowerSeller.can_sell()`) and `restless_dreams` (`can_skip()`).
- **Clearing cards** (tag `clearing`, need `min_obstacles` 8 left): clear cost always via
  `ObstacleClearer.get_clear_cost()` → `DreamState.get_clear_cost()` (Cleared Ground stacks);
  `RunState.free_clears` (Heartwood's Reach, used first by `try_clear`, HUD counter);
  `RunState.fertile_cells` + `TowerPlacer.get_cost(data, cell)` (Reclaimed Earth); Tended Forest
  reads `tended_cells.size()` (all clears); Burn Back sets `RunState.clearing_without_seeds` (no Seeds)
  and `creature_speed_bonus` (via `DriftDirector.get_spawn_modifiers`).
- **Omens** (run_design.md): `OmenDirector` (`%OmenDirector`, group `omens`), `OmenData` in
  `resource/omen/*.tres`. At rests from drift `first_rest_drift` (10), after the Dream: 2 Omens or
  Clear Skies (`choose(null)`); the pick twists the next block (`get_multiplier`,
  `get_schedule_modifiers`, `get_spawn_modifiers` → `Enemy.modifiers`; bosses ignore them). The reward is
  paid at the rest after that block, or on a win (Dew/Seeds × act scale; `RunState.omen_seeds`).
  `OmenScreen` shows the offer and an active-Omen tag. `tests/test_omens.gd`.
- UI: `WardenPanel` (click a Warden: stats, grow buttons, Sell), `DreamScreen` (pauses; 3 cards +
  "Let it pass"; Entwined vine border, Deepened / bittersweet lines). Tower bar shows only unlocked Wardens.
- `tests/test_dreams.gd` prints a Storm Grid reachability simulation: with both families, ~40% by
  drift 50 (× ~70% family odds ≈ the 33% target), thanks to Entwined Conductive Soil.

## Run flow
- Difficulty pass v1 (run_design.md), all exports: `RunState.starting_dew` 45, `starting_leaves` /
  `max_leaves` 15; `DriftDirector.health_growth_per_drift` 1.045, `boss_health_multiplier` 1.5,
  `extra_nightmares` 1.25 from `extra_nightmares_from` 10 (rounded up per entry, `DriftEntry.get_count`
  `extra`), `act_break_leaves` 1; `TowerSeller.build_phase_refund` 0.75.
- `RunState` also holds leaves (`starting_leaves`, `max_leaves`), `lose_leaves` / `regrow_leaves`,
  `end_run(won)` + `run_ended` signal, `is_over`. `earn_dew_at(amount, pos)` = add Dew + popup.
- `DriftDirector` (`%DriftDirector`, `scripts/run/drift_director.gd`): blocks of 5
  (`drifts_per_block`), acts of 25 (`drifts_per_act`, the act's last drift is its boss). `drifts`
  loads `resource/drift/demo/drift_01..50.tres` when empty. The run starts `resting`; Start
  (`start_next_drift()` / `start_next_block()`) begins a block; its drifts FLOW (the next starts
  `auto_drift_delay` s after the previous finished arriving; `set_auto_drift()`); starting one while
  the current is still arriving = call early (+1 Dew / 2 s of arrival skipped, cap 10). Once a
  block's last drift arrived and the field is clear: rest bonus (20 + 10×block, +10 perfect
  block, + Dreams) → `rest_started(block, is_boss_rest, bonus, perfect)`; boss rests are act breaks
  (+1 leaf, `act_started`). `family_pick_requested(&"first"|&"boss")` fires after drift 1 and
  before a boss rest; `FamilyPickScreen` calls `family_picked()` (first pick: 3 random of every
  unlocked family, never the last run's offer again, profile `last_first_pick`). `is_build_phase()`
  = resting (75% refunds). Health × 1.045^(n−1), bosses × 1.5. Hooks for Dreams/Omens:
  `get_health_multiplier`, `get_schedule_modifiers`, `get_spawn_modifiers`, `_pay_rest_bonus`.
- Drift data: `DriftData.groups: Array[DriftGroup]`; `DriftGroup.entries: Array[DriftEntry]`
  (enemy + count + `elite`; several entries mix evenly), `spacing`, `delay`. `get_schedule()` →
  `[[time, EnemyData, elite], …]`. The demo list mirrors the acts_1_2.md table (mixed drifts spread
  over 25 s in act 1, 30 s in act 2).
- `EnemyData`: `display_name`, `leaf_cost`, `is_boss`, `sprite_scale`, `tint` (placeholder recolour),
  `cleanse_line` (boss toast), `split_into`/`split_count`, `trait_kind` (NONE, FLYING, ROLLING,
  TRAMPLE, LEAP) with its numbers, `followers`/`follower_count` (Mother Duck → Ducklings, who get
  `lost` if she's cleansed first). Elites (Deeply Blighted) are a spawn flag: ×3 health/Dew, 2
  leaves (`enemy.get_dew_reward()`, `get_leaf_cost()`). Every act 1–2 creature has its own art
  (`assets/creatures/`, `animation/enemy/`); `tint` / `sprite_scale` are only for placeholders.
  `EnemyContainer.spawn_enemy(data, health_scale, modifiers, elite)`; flyers path straight
  start→end and are skipped by `get_maze_walkers()` (the path rule / re-routing); signals
  `enemy_cleansed`, `enemy_reached_goal`, `enemy_split` (split children and followers, emitted
  before the parent's cleanse), `wall_trampled`. `tests/test_creatures.gd`.
- Selling: `TowerSeller` (`%TowerSeller`): outside build mode, hover a Warden, RMB / Delete sells for
  `Tower.invested_dew` × 100% (resting) or 50% (walking); `MapGenerator.unblock_cell`.
- Speed: `GameSpeed` (`%GameSpeed`): pause = `get_tree().paused`, speed = `Engine.time_scale`.
  Build/clear/sell tools, HUD, camera and GameSpeed are `process_mode = ALWAYS` so building works
  while paused; the camera divides delta by time_scale so panning stays real-time.
- HUD: `%LeavesLabel`, `%PathLabel` (path length), `%ToastLabel` (`show_toast`), `DriftPanel`
  (bottom right, compact: status line, Start / call-early button, Auto-drift + speed buttons in one
  row). `%TowerBar` is bottom centre (cost under the icon, hotkey number in the corner) and must fit
  between the Warden panel and DriftPanel at 1280×800 (checked in `tests/test_ui.gd`). The camera
  may overscroll the map edges by `hud_overscroll` so the ends can clear the HUD.
  `Seasons` (CanvasModulate) swaps the environment to each act's sheets (`MapGenerator.set_act`)
  and can tint the world per act (neutral for now). `tests/test_run.gd`.
  It also owns selection (`selection`, `selected` = first; `selection_changed`): click, drag box
  (after 8 px; Thornwalls only if alone), double-click = same kind on screen (Ctrl: whole map), Shift
  adds/removes, Esc/RMB/empty ground clears. A left press on an obstacle is left to ObstacleClearer.
  Group ops: `get_selection_groups`, `count_affordable`, `grow_group` (nearest the Heartwood first,
  staggered bloom), `sell_selection`; the Warden panel shows them for 2+ selected.

## Run end, saving, onboarding
- Scene flow: `scenes/title.tscn` (main scene; Continue / New run / Settings / Credits / Quit) →
  `scenes/main.tscn`. Project settings `game/demo` (true) and `game/wishlist_url`.
- `HeartwoodMemory` (`scripts/meta/heartwood_memory.gd`, static, `user://heartwood.json`): banked
  Seeds, run counts, `whispers_seen`, settings (volumes, fullscreen, whispers, keybinds);
  `apply_settings()`. `SettingsPanel` edits it (title + pause menu).
- Seeds: `RunState.get_seed_breakdown()` (meta_design.md formula + first-run +20).
  `ResultsScreen` (`%ResultsScreen`) shows it on `run_ended`, banks it, and in the demo shows the
  Deep Wood ending, Memory 1, the sleeping Grove teaser and a Wishlist button.
- `RunSaver` (`%RunSaver`, `user://run.json`): autosaves each rest once no choice screen is open;
  `resume_next` (set by Continue) rebuilds the run from the save (map seed, tended cells, Wardens,
  counters, `DreamState`/`OmenDirector` `to_save`/`load_save`). `PauseMenu` (Esc): Resume,
  Settings, Save & Quit. `tests/test_save.gd`.
- **Tests never touch the player's saves:** autosave, Seed banking and whispers only write when
  `main.tscn` is the running scene (`get_tree().current_scene == owner`); tests add it under root
  by hand. `RunSaver.file_path` / `HeartwoodMemory.file_path` can point at temp files. Don't smoke
  run with `--scene res://scenes/main.tscn` or `grove.tscn` (they ARE the real game and write to
  user://: run saves, whispers, the Grove's one-time welcome). The title scene is safe.
- `Whispers` (`%Whispers`): onboarding.md's Heartwood whispers, each once ever; first run glides the
  camera along the path (`GameCameraNode.glide`). The build ghost shows "+N path".
- HUD from screens_ui.md: `DriftBanner` (top centre: act/drift, block pips, "Boss in N", boss
  health bar with 50% marker), `NightmareInfo` (hover panel; `EnemyData.trait_text`; "New" tag via
  profile `nightmares_seen`), `LeakEffect` (pulse + falling leaf at the goal). Pause menu: Abandon
  run, whispers toggle, run summary. Settings: UI scale, Auto-drift default, reduced motion, damage
  numbers (`damage_numbers` 0/1/2). Hotkeys G (grow selected), H / F (centre on goal / start).
  Results show run stats (`RunState.leaves_lost`, `longest_path`, `play_time`). `tests/test_ui.gd`.
- Combat feedback (screens_ui.md), all on `DamageLog` events: `CombatCallouts` (world; combo tag →
  "Conducted!" / "Popped!" / "Asleep!" / "Shattered!" / "Weak!", throttled; calls
  `enemy.flash_status`), `PlacementLinks` (vines from the build ghost to Wardens it combos with),
  `Synergies` (static status → payoff table; `link`, `find_links`), `RestReport` (top 3 Wardens +
  combos per block; `get_report_text` also feeds the results' run report), Warden panel "This run /
  from combos / Combos with". `DamageLog`: `combo_counts_block/run`, `get_top_towers(period)`,
  numbers mode from the `damage_numbers` setting. New combo tags just need a `CombatCallouts.WORDS` /
  `USES_STATUS` / `RestReport.COMBO_LINES` entry. `tests/test_feedback.gd`.

## Meta (meta_design.md; full game only — `game/demo` true = nothing applied or recorded)
- `UnlockData` (`resource/meta/grove/*.tres`): root (WARDENS/DREAMS/PERKS/FORESTS), `costs` per
  level, `requires_all` / `requires_any` (+count), effects: `families` (join family picks),
  `dream_cards` (→ `DreamState.grove_cards`), perks per level (`starting_dew`, `max_leaves`,
  `dream_rerolls`, `dream_banishes`, `extra_dream_cards`, `seed_bonus`, `early_bloom`).
- `HeartwoodMemory`: `unlocks {id: level}`, `buy()` / `buy_problem()`, `load_grove()`, `MEMORIES`
  (10) + `memories_unlocked()` (1 after the first run, +1 per 3 unlock levels, +1 per Memory
  milestone), `milestones`, `counters`, `highest_blight_won`, `max_blight_level()`, `cosmetics`.
- `MetaRun` (`%MetaRun`, `scripts/meta/meta_run.gd`): applies Grove perks, families, cards and the
  Blight Level (`MetaRun.blight_level`, static, chosen by `BlightPicker`, saved with the run) at
  run start; records counters / milestones / highest Blight won at run end (real game only).
  Blight hooks: `DriftDirector.blight_*` multipliers, `act_break_leaves`, `DreamState.skip_dew` /
  `lean_common`, `MetaRun.clear_cost_multiplier()`. `RunState.seed_bonus` adds a Seeds line.
- Family Blessings: `resource/meta/blessing/blessing_<family>.tres` (UpgradeData, +25% damage and
  25% cheaper growth for that family), put in the Dream pool by MetaRun (never offered); the family
  pick fills empty slots with them.
- `scenes/grove.tscn` (`GroveScreen`): roots of plants (seed / glowing / grown), Memories shelf +
  viewer, Start run (Blight picker after the first win), "The forest remembered you" on the first
  visit with Seeds. Title: Memory Grove button (demo: greyed + Wishlist). `tests/test_meta.gd`.

## Audio (placeholder, audio_direction.md)
- `tools/sound_generator.gd` synthesizes every sound into `assets/audio/` (sfx 44.1 kHz; music
  stems + ambience 22 kHz, D minor 72 bpm 3/4, 20 s loops of equal length). Re-run it, then `--import`.
- `Sound` autoload (`scripts/audio/sound.gd`): buses Music/SFX/Ambience/UI (reverb on Music/SFX,
  lowpass "muffle" on Music), `play(id, world_pos, db, pitch, jitter, bus)` (random variant
  `<id>_01..`, voice limit + throttle per id, positional via AudioStreamPlayer2D), `play_dispel`
  (chime climbs a pentatonic combo), `play_music(set, layers)` / `set_layer` (stems base, dread1,
  dread2, heartbeat, boss), `play_ambience`. Every BaseButton clicks. Silent under headless.
- `SoundHooks` (`%SoundHooks` in main.tscn) connects the run's signals to it and drives the music
  layers; gameplay scripts never call Sound (`Tower.attack_released`, `Tower.hit_landed`,
  `TowerPlacer.build_rejected` exist for it). Settings: Music slider = Music + Ambience, Sounds = SFX + UI.
  `tests/test_sound.gd`.
- Mix (first-listen revisions): levels in `Sound` (`MUSIC_DB`, `AMBIENCE_DB`, `LAYER_GAIN`; stems are
  trimmed so more layers never get louder), `duck(db, s)` (dispel 4/0.5, leaf lost + boss moments 8/1),
  `set_drifting` (−3 dB in drifts), `set_ambience_trim` (thins with the field, swells at rests).
  Attacks = quiet launch (`attack_<line>`) + hit where it lands (`hit_<family>`, `_dull` when resisted,
  `hit_full` + louder when weak, pitched by the target's size; one per pulse/splash, chains ripple quieter).
- Second listen ("Rounded, never sharp"): the generator never uses crackle/click textures; `_sfx()`
  lowpasses every effect (`SFX_TOP_HZ`) and fades it in (`SFX_ONSET`, `HIT_ONSET`); SFX bells skip
  partials above 6 kHz; SFX/UI buses get a −6 dB high shelf + a limiter (`Sound._add_softening`).

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
  Obstacle types are `resource/obstacle/*.tres` (`ObstacleData`: name, verb, cost, `source_id` +
  `tiles`, and the `cleared_source_id` mark left when the player clears one: tended stump, moved hollow).
  Tiles: `environment_tiles.gd` (`EnvironmentTiles`) builds one TileSet from `assets/environment/<act>/`
  (one atlas source per sheet, fixed source ids) shared by all three layers; the path picks
  `path.png` column = neighbour mask. The map is an island in a starry void: border cells are
  `island_edge` rim tiles (neighbour mask; no grass under them), cliffs under the bottom row, a rope
  bridge out from the start (shared sheets in `assets/environment/dream/`), and `DreamVoid`
  (`dream_void.gd`: Parallax2D sky + stars behind the map, islets). Mist on the start, `Heartwood` (`heartwood.gd`, Sprite2D) on the end shows leaves lost (its warm light and additive
  glow dim with them). Lighting pass (art_direction.md), made by MapGenerator: `EnvironmentLighting`
  (MUL-blended radial multiply, cold at the edges, z 3; a PointLight2D per attacking Warden, kept under
  it, not the Warden) and `EnvironmentAmbience` (`_draw`: edge fog + the act's particles, z 6). `tests/test_environment.gd`
  (`-- --preview=<file.png>` saves a flat render of the map).
- `scripts/enemy/` — `enemy.gd` (walks cell to cell along a grid path; `set_path` re-routes it),
  `enemy_spawner.gd` (on `path_changed`, re-routes every enemy from its `get_target_cell()`).
- `scripts/tower/` — `tower.gd` (`Tower`, plays the idle loop from `TowerData.texture` — a row of
  `frame_count` 64x64 frames — or draws a placeholder block when it's empty), `tower_placer.gd`
  (`TowerPlacer`: roster `towers`, `select_tower()`, build mode, ghost, route preview, validation).
  Wardens: `resource/tower/*.tres` (Sprout, Thornwall + 6 bases; all buildable until Dreams exist),
  art in `assets/towers/` (generated by `tools/tower_art_generator.gd`). The HUD's `%TowerBar` has
  a button per Warden (hotkeys 1-9). Thornwall has `can_attack = false`.
  Ranks: `Tower.rank` 0-5 (`RANK_COSTS` 15/25/40/60/90; +15% dmg, +5% speed, +0.1 range each),
  `TowerPlacer.nurture()`, `TowerSeller.plan_nurture` / `nurture_group`, R = `nurture_warden`; kept
  through evolution and in the run save.
  Towers can't go on border/trees/towers/start/end, on a cell an enemy occupies, or anywhere that
  would leave the start or any live enemy without a path to the end.
- `scripts/tower/tower.gd` also handles attacking (stats in `TowerData`: range in cells, damage,
  attacks/sec). Each attack plays `attack_texture` (`<warden>_attack.png`, 6 frames) and fires on
  `attack_release_frame`: PROJECTILE kinds spawn at `attack_origin` (px from centre, from
  `assets/towers/attacks.json`); PULSE kinds (Rootling, Acorn) soothe everything in range.
  `TowerData.AttackKind` also has TRAP (`fairy_ring.gd` rings on path tiles), BEAM (ramping,
  continuous), COPY (Graftling: `Tower.attack_data` becomes the strongest adjacent Warden's data at
  `copy_share`; attack code must read `attack_data`, not `tower_data`), SWOOP (projectile flies back),
  SWEEP (`flock_sweep.gd`), SPREAD (Gust copies statuses), SPIN (8 tiles around), PULL (Pond Keeper),
  LIGHT (Rootlight lit tiles) and AURA (White Stag). Crits: `crit_chance`/`crit_multiplier` per
  Warden (0 on the original roster), `Tower.hit(enemy, mult, is_area, crit)` rolls them and passes
  `is_crit` to `Enemy.take_damage`; signals `crit_landed`, `beam_ticked`. Snipers: `min_range`,
  distance bonus, `has_target_priority` (Warden panel button). Held status (`EnemyStatuses.HELD`) stops
  movement. Memory Wardens (`is_unique`): one on the map at a time. New Wardens are unlocked by Dream
  cards (`in_start_pool = false` for hidden branches and the Nestling/Whirligig families until the
  Memory Grove exists; Memory Wardens need the boss reward); `DreamState.unlock_everything` shows all.
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
- `resource/` — data resources + their scripts: `map_grid.tres` (`Grid`: 23x18 cells, 64px; small on purpose so each Warden matters),
  `obstacle/*.tres` (`ObstacleData`), `enemy/*.tres` (`EnemyData`),
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
