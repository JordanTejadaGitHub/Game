# Claude takeover — 2026-10-11

Read after `CLAUDE.md`, before changing gameplay. This describes the normal project. Older dated plans also contain historical scope and test results.

## Checkout and standing rules

Repository: `D:\Projects\Game`; Godot project: `D:\Projects\Game\Project_T`. Observed branch: `main`, HEAD `ac322d79`. Substantial modified/untracked work predates this handoff. Inspect status and diffs; preserve all existing work. Recent changes are present in the working tree; being on main does not mean they were committed. Do not reset/clean, overwrite with the prototype, automatically commit or push.

- Preserve mechanics unless explicitly instructed otherwise.
- Preserve random Dreams, speculative picks and Half-Dreamed; no guaranteed cards, forced partners or deterministic build steering.
- Keep appropriate builds/cards exclusive to Memory Grove; retain progression gates, saved enum values and legacy IDs.
- Encourage multiple Wardens, status cooperation and larger defended mazes, while bounding control/economy.
- All project outputs, userdata, logs, caches and scratch files belong on D:. Use the wrapper; close test-launched Godot when checks finish.
- The user's council includes game designer, player advocate, Godot engineer, roguelite specialist, tower-defence specialist and lead reviewer. Review substantive Dream/build changes; do not ask again for already approved rules.

## Architecture and conventions

`scenes/main.tscn` wires the run. `scripts/run/drift_director.gd` owns drift/rest flow and rewards; `run_state.gd` owns Dew/leaves; `dream_state.gd` owns offers/rules/unlocks; `run_saver.gd` serializes the run. Spend Dew through `RunState.spend_dew()`.

Resources under `resource/tower`, `resource/dream`, enemy/drift folders are data-driven. `scripts/tower/tower.gd` supplies effective stats, nurture and combat; `branch_kit.gd` supplies branch abilities. `scripts/enemy/enemy_statuses.gd` and `scripts/combat/reactions.gd` own status/reaction behavior. Preserve source credit, float precision and native-versus-derived hit distinctions. Memory Grove/profile code lives under `scripts/meta`. Placement must retain an open route. Shared Warden descriptions/stats use `scripts/ui/warden_header_view.gd`.

## Approved implementation already present

### Rank V and Shared Training

Four matching picks among ranks I–V grant the existing working signature. Missing/inapplicable signature paths, including repeatable Kindred, receive useful role Mastery. Other rank-V builds receive All-Rounder: permanent +20% to their main job. Later ranks cannot change the first-five result. One-time Kindred remains once only.

Main jobs: attacker damage; catcher income; aura strength; Seedbearer offspring damage; Sapling drift Dew; Dream Oak shard yield; Dreamcatcher Caught tick rate. Nurse Log gains +20% reach plus stronger nurture discounts within its cap, so a capped discount still has a useful payoff. Missing continuous-attack Swift paths use speed mastery; missing Deep control paths use reach mastery. All-Rounder does not multiply both damage and speed.

Shared Training requires four matching initial picks on BOTH kin on the same choice, with both at least rank IV. No early All-Rounder. Legacy/free choices migrate before bonus selection. Bonus helpers must not query computed stats during stat-cache construction. Sapling must not get dead combat signatures; Dreamcatcher must boost actual Caught ticks, including Great Dreamcatcher's base contribution.

Files: `signatures.gd`, `tower.gd`, `branch_kit.gd`, `resource/dream/shared_training.tres`; details in `warden_stats.md`. Preserve the rule against advance signature-name hints; explain general requirements and unlocked results.

### Dreams and statuses

The approved Dream overhaul/Early Builds v2 is integrated into NORMAL MAIN. Isolated prototype launchers/profiles/title labels are historical.

Stone Relay, Stored Rain and Spore Reserve are Uncommon/Act 1 with family gates. Fifth Beat replaces Rhythm; Crossfire adds an early cross-Warden pattern. Drumbeat, Steadfast, Canopy and Grand Tour reward their mechanical conditions. Twenty-two additional passive packages retire from new offers; legacy IDs/effects remain loadable. Ordinary offers may contain two family cards without guaranteeing either. Retired-only Grove nodes cannot charge Seeds or block completion; Whirlwind Heart connects through Quickening.

Separately, the earlier successor pass kept Rolling Thunder II, Root Network II, Guiding Light II and Tender Care II, replacing fourteen other II offers. Do not conflate those retirements with the overhaul's twenty-two. Preserve rarity/family/discovery/Grove gates. See the current opening of `dream_design.md` and `unique_dream_successors.md`.

High status capacities, reaction requirements and damage tuning are already implemented. Exposed requires 10 stacks (20 with Brimming) before vulnerability/dependent bonuses activate. Brimming doubles all six capacities and numeric reaction/payoff requirements; completed damaging payoffs scale by 2.2, while control stays bounded. Consult live constants, overrides and boss caps instead of old examples. Poisoned uses independent application expiry/cohorts; synthetic applications must not count as native cooperation. Ink Trail poison contact is fixed. Seedbearer free Sprouts may be planted anywhere on valid ground.

### Economy, UI and onboarding

Sprout base cost: 10 Dew, +4 per five paid Sprouts. Starting Dew: 60. Ordinary Act 1 kill pots +15% from drift 11; Act 2 +20%. Ordinary non-elite Act 1 health ramps to +5% by drift 24. Grow/Nurture prices and documented boss/elite/later-act exceptions remain. See `maze_economy.md`.

Maze payout: +1 Dew per four extra DEFENDED route cells, cap 20 per block. Baseline comparisons, snapshots/ledger safeguards and save persistence prevent temporary-maze farming. Empty detours do not qualify. The top-right +Dew forecast is maze income, separate from Wellspring interest. Best catcher in reach counts; Wellsprings share a 130-Dew interest cap per rest.

DPS/tower-bar arrows hide/reopen panels without losing build selection; hide state is per HUD instance. Shared headers show catch percentage/reach, live bowl Dew and interest rate/cap. Icon help is hover-only. High-stack counts stay smaller at icon bottom-right. Twig Wall single/drag previews use smaller art.

Opening/discovery lessons pause and preserve prior/modal pause ownership. Pause → Replay guides has looping nurture/maze/catcher explanations even with Hints off, without changing Hints or discovery history. These are in-game animations, NOT exported videos. See `lesson_card.gd`, `lesson_demo.gd`, `pause_menu.gd` and `onboarding.md`.

Shutdown ownership fixes cover inactive TestGrove controls, unused HUD hover controls, an overwritten GiftScreen placeholder, off-tree diagrams and temporary UI-test bonus rows. Do not suppress warnings instead of fixing ownership.

## Launch and test commands

Double-click `D:\Projects\Game\Open Heartwood Godot.cmd` for the normal main checkout in Godot; F5 runs the project, F6 the current scene. The launcher uses the D: logs wrapper with the `player` profile.

Direct game launch, from any PowerShell directory:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\Projects\Game\Project_T\tools\godot_dev.ps1" player --path "D:\Projects\Game\Project_T"
```

Regression example and required launch smoke:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\Projects\Game\Project_T\tools\godot_dev.ps1" takeover-signatures --headless --path "D:\Projects\Game\Project_T" --script res://tests/test_signatures.gd --fixed-fps 60
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\Projects\Game\Project_T\tools\godot_dev.ps1" takeover-smoke --headless --path "D:\Projects\Game\Project_T" --quit-after 300
```

The wrapper and `dev_environment.ps1` redirect APPDATA, LOCALAPPDATA, TEMP and TMP beneath `D:\Projects\logs`, separated by the supplied name. Use unique test names and per-process profile files; preserve the player profile. Process-scoped ExecutionPolicy Bypass handles script-disabled errors without changing global policy.

Import new class_name scripts through the wrapper if the global class cache is stale. For verbose output use explicit `-GodotArgs @('--verbose', ...)`: PowerShell may consume bare --verbose. Inspect script/runtime errors and teardown warnings, not merely exit status/PASS. Run `git -c core.safecrlf=false diff --check` from the repository root.

## Recorded verification and remaining limits

The latest rank/UI implementation passed 15 targeted scripts: `test_signatures`, `test_signature_dreams`, `test_catchers`, `test_nurture`, `test_nurture_choices`, `test_free_ranks`, `test_rank_cards`, `test_save`, `test_initial_lessons`, `test_hide_controls`, `test_warden_header`, `test_warden_meter`, `test_phone_layout`, `test_ui`, `test_twig_walls`. Final affected checks exited cleanly after ownership fixes. The 300-frame launch smoke and whitespace check passed. Final rank council review found no blocking issues. These are implementation-session results, not tests rerun during this documentation-only handoff.

Historical Early Builds v2 prototype validation recorded 188/189 scripts passing. The stress test exceeded its 14 ms p95 budget (14.37 ms); an earlier unchanged-source comparison also exceeded budget. This remains a performance follow-up, NOT proof that the full suite is green on today's dirty main. Do not weaken the assertion.

Next: inspect the working tree and wait for the user's next task. Human playtesting remains necessary for maze incentives, status/payoff tuning, mixed-versus-specialised ranks and rendered guide/UI clarity. Guide behavior/layout tests do not constitute a GPU-rendered visual review. Run a fresh full-main regression/performance check before release. This documentation request authorizes no new gameplay change, commit or push.