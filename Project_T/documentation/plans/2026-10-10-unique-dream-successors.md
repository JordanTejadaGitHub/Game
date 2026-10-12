# Unique Dream successors Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Replace fourteen active II offerings with distinct council-approved cards while retaining Rolling Thunder II, Root Network II, Guiding Light II and Tender Care II.
**Architecture:** Retain retired II resources and legacy rule-level behavior. New independent resources use separate rule IDs. Focused helper scripts implement cooperation and route/transition effects; root owns all integration in existing shared scripts.
**Tech Stack:** Godot 4.7.2, GDScript, resource-driven Dreams.
**Spec:** User-approved in-chat fourteen-card table and council safeguards, 2026-10-10.

## Global Constraints
- No commits/pushes. All writes and test runtime output on D:.
- Preserve speculative randomized offers, current family/discovery requirements, rarity, and Memory Grove exclusives.
- Ordinary status caps, immunity, duration rules and Brimming thresholds govern new stacks.
- Synthetic applications cannot qualify as native cooperation or recursively generate card bonuses.
- Existing saves containing old II cards retain their effects.

## Review Focus
- Lone towers/projectile returns cannot satisfy two-Warden conditions.
- Expired/removed statuses and targets cannot leave stale cooperation history.
- Persistent damage and reaction effects cannot consume primary-hit readiness or recursively prime.
- Old saves/Grove profiles retain selected effects and access without offering retired cards.
- Rest rewards respect rank caps, prevented leaks and combined base/successor cards.

### Task 1: Resources and catalogue compatibility
Files: resource/dream fourteen retired II and fourteen new resources, resource/meta Grove nodes if applicable; tests/test_unique_dream_catalogue.gd.
- [x] Write/run failing catalogue tests for retained four, retired fourteen, successor eligibility/access, legacy II replacement semantics.
- [x] Create independent successors using original rarity/family/discovery gates; update Grove assignments while retaining old IDs for compatibility.
- [x] Verify catalogue/Grove/card-text/save tests.

### Task 2: Cooperation effects
Files: scripts/run/dream_cooperation.gd; tests/test_dream_cooperation.gd. Root integrates Tower and Enemy hooks.
Interfaces (static): before_hit(tower,enemy,direct,now)->float; after_hit(tower,enemy,is_crit,direct,now); native_status(tower,enemy,id,accepted,was_present,now); hold_expired(dreams,enemy,source,now).
Crosswind: Samara direct +25% if another Warden direct-hit within1s, once enemy/throw. Opening Fracture: direct crit primes2s, another Warden next direct hit +40%, shared3s cooldown; payoff cannot re-prime. Shared Mycelium/Crossed Sparks: accepted native applications from distinct live Wardens <=2s add2 relevant stacks, shared2s cooldown; absent status clears history. Afterroot: natural Rooted expiry with known source arms2s, next other-Warden direct hit adds2Exposed, shared4s cooldown.
- [x] Tests red for self exclusion, two-source success, cooldowns, immunity/expiry and Brimming.
- [x] Implement focused helper; no edits to shared scripts.
- [x] Tests green, then review.

### Task 3: Path and transition effects
Files: scripts/run/dream_path_rules.gd; tests/test_dream_path_rules.gd. Root integrates hooks.
Interfaces (static): native_status(tower,enemy,id,accepted,direct,now); target_changed(tower,old_target,new_target,now); caught_exited(dreams,enemy,catcher,now); dispelled(dreams,enemy,now); harmony(dreams,a,b,enemy,drift).
Corner Sign: native direct accepted stack hit after bend adds1, cooldown3 per tower/enemy. Enemy metadata unique_bend_serial increments on forward route bend. Wake Ripple: currently drowning dispel applies2Soaked to<=3living nearest others within1cell; normal reactions allowed, no forced Drown. Dream Residue: true Catch exit adds2Drowsy, per catcher/enemy cooldown3. Kin Keepsake: first harmony per stable pair/drift1Dew global6, store ledger on DreamState metadata. Passing Thread: primary target switch copies1stack of donor's most-filled stackable status, donor remaining duration, potency/source, cooldown2.
- [x] Write/run failing tests for each effect and no recursion/cap bypass.
- [x] Implement helper using existing source/credit APIs; no shared-script edits.
- [x] Run green tests and review.

### Task 4: Root integration and growth effects
Files: tower.gd, enemy.gd, dream_state.gd, run_state.gd, kinships.gd, seed_boomerang.gd as needed; tests/test_dream_growth.gd.
- [x] Add failing rest/leak/wall/idle integration tests.
- [x] Integrate modules via existing _game_clock and direct/native status contexts; apply pre-hit effects before damage, natural expiry and actual Catch exit hooks.
- [x] Fresh Beginnings: newest actually planted attacker since previous rest receives1banked free rank, maxV and existing rank caps, exclude Sunlit Rest selected towers; saved stable planting sequence.
- [x] Emergency Reserves: actual positive leaves-loss after prevention8Dew onceblock, saved marker.
- [x] Hushed Hedge: grounded adjacent nightmare2Drowsy oncewall/drift, separate Briar marker and normal wall Drowsy limit.
- [x] Quiet Vigil: separate idle readiness5s, next primary direct hit3Exposed before damage, no persistent/secondary consumption.
- [x] Verify focused and broader suites, seeded offer checks, save/Grove fixtures. Update design docs and CLAUDE.
- [x] Independent council/lead code review, resolve findings, final diff check. No commits.