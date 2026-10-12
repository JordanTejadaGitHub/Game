# Dream Build Overhaul Prototype Implementation Plan

Goal: a playable isolated prototype in which Dreams alter Warden roles and maze decisions, with far fewer automatic damage picks.
Architecture: preserve Warden evolution, native combinations, stable card IDs/save compatibility, random run pools and Grove placement. Add a bounded DreamBuildRules helper for original-attack mechanics; replace broad passive rules with positional/temporal mechanics and retire redundant numerical cards from new offers. No changes to enemy difficulty or progression currencies.
Spec: this conversation and documentation/dream_design.md; this prototype section supersedes numerical legacy text for changed cards.
Constraints: work only D:/Projects/GameDreamPrototype; no commits, pushes, merges, or source-checkout changes. All Godot calls through D:/Projects/logs/scripts/godot_dev.ps1. Preserve Half-Dreamed and speculative failure, Full Moon, RNG/no guarantees, structural Deepened replacement, Grove-exclusive playstyles.

## Task 1: Family role mechanics
Files: new scripts/tower/dream_build_rules.gd, scripts/tower/tower.gd, bounded cosmetic helpers as needed, tests/test_dream_build_rules.gd.
- Write and run failing behavior tests before implementing.
- Stone Relay (blessing_pebbling): direct stone primary damage embeds one globally shared stone on a living target; next original positive direct damage from a different family consumes it and strikes first living follower along the route for 75% embedding attack damage. Cannot recurse, crit, embed or trigger direct-hit rules. Consumed even if no follower. No same-family cash-out.
- Stored Rain (blessing_dewdrop): original targeted water attack against already Damp/Soaked living target removes Damp and diverts whole attack incl splash into a 4-second single-use puddle. Next different living non-flying enemy entering footprint receives stored damage. One per Warden; replacement loses old puddle. Excludes pulse-only/status-only attacks unless an original targeted attack exists. No proc recursion.
- Spore Reserve (blessing_sporeling): actual primary target change moves up to three Poisoned stacks from previous still-living target to new target using accepted status semantics, preserving bounded remaining duration. Dead targets cannot supply stacks, no copies.
- Remove family stat bonuses via resources Task 3; use has_card IDs for helper hooks. Derived effect hits cannot trigger these rules.
- Verify actual integration, effect parenting outside typed containers, targeting switches, dying targets, immunity and expiration; import UID and run combat/reaction/signature regressions.

## Task 2: Broad mechanical Dreams
Files: scripts/run/dream_state.gd, scripts/enemy/enemy_statuses.gd if needed, new helper integration coordinated with Task 1, tests/test_dream_build_roles.gd.
- Write failing tests, implement and verify.
- Drumbeat: touching at least two other attackers enables relay; each two distinct adjacent Wardens completing original attacks advances own next attack cooldown by 35% of one base interval. Never emits an immediate recursive attack; repeated one-neighbor spam cannot feed full cycle. Replace unconditional APS bonus.
- Steadfast: Warden that has stood five drifts gains patrol reach: first hit on a new primary target briefly pins it (0.4 seconds, per-enemy shared 4-second cooldown; bosses immune). No standing damage bonus; growth keeps age.
- Canopy (Grove): attackers in orthogonally connected clusters of at least six attackers gain one range while their cluster has attacked at least six distinct living targets in the past 3 seconds. No permanent numerical damage milestones; no temporary planting exploit.
- Grand Tour (Grove): applying a genuinely new status to a living enemy preserves existing other statuses for at most one extra second each, total per-status extension capped one second over its original lifetime; cannot renew Hold/sleep or persistent statuses; no stat damage.
- Retire Menagerie and Long Walk numerical rewards from new offers (Task 3); keep readable legacy IDs.
- Remove old passive rule contributions for redesigned cards; clear transient state across drifts/load; preserve all other rules and save fields.

## Task 3: Pool, card resources and playtest guide
Files: resource/dream/*.tres, resource/meta/blessing/*.tres, documentation/dream_design.md and new documentation/dream_prototype_playtest.md; own resource files only, coordinate scripts with root.
- Family Blessing resources: three new role mechanics retain IDs, rarity Rare, minact2, start/Grove/family prerequisite placements. Numerical family damage/growth bonuses zero. Other six Blessings retired from new offers, rather than invent weak replacements; native families and their existing mechanical Dreams unchanged.
- Redesign resource descriptions for Task 2, matching mechanics exactly and removing stale diagrams/captions.
- Audit current pool for passive damage/APS/stat packages that are easy automatic picks. Retire clearly redundant unconditional numerical growth/stat rewards including old numerical Menagerie/Long Walk and family-only damage packages; preserve meaningful limited economy, structural range, crit/attack-pattern builds, risks/tradeoffs, simple conditional survival cards and Full Moon. Avoid broad indiscriminate removal; document every disposition and rationale. Retired resources remain loadable, Grove nodes compatible.
- Offers permit up to two mechanical family cards without guarantees; root owns script patch. No change to 60% sampling, rarity weights, fade/pity/Half-Dreamed or family draws.
- Add pool tests for retirement, availability and fresh-player offer viability; report retired list to root.
- Write concise guide including exact mechanics, intended alternative roles, branch path, launcher and what to judge during real play. No forced enablers or unlocked Grove cheating in normal run.

## Task 4: Integration and verification
Root owns script offer patch, executable prototype launcher, any glue, integration/full tests and final review.
- Baseline import and targeted suites before changes.
- Verify new family cards are eligible ordinary Dream offers, retired cards excluded, Grove cards remain locked, no stale upgrade bonuses.
- Run new suites and existing tests; full-suite runner captures timeout/crash failures and logs, not fabricated PASS from exit code alone.
- Fresh reviewer checks actual attack hooks, save compatibility, per-enemy caps, large-board performance and UI text accuracy. Fix consequential findings.
- Leave uncommitted requested branch playable via D: launcher; original checkout remains untouched.
