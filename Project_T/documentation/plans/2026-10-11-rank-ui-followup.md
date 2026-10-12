# Rank-V and UI follow-up
Authorised: four matching first-five nurture picks for specialised bonuses; mixed picks get an equally viable All-Rounder. Preserve existing effective signatures and role-specific limits, Grove exclusivity, Dream randomness, existing save choice ints. No commits or pushes. All writes on D:.
1. Rank bonuses: council review concrete role/getter hooks; tests for 4+1 specialised, 3+2 All-Rounder, 4+0 rankIV Shared Training, every repeatable path meaningful, automatic Sapling ranks, saves/growth continuity. Implement activation and contextual hints/text with no stat recursion.
2. Hide controls: regression click-to-hide/reopen DPS meter and tower bar, persistent handles, screen fit, rebuild stability, unchanged selected tower. Implement the already approved horizontal/vertical arrows.
3. Economy feedback/wording: correct Seedbearer anywhere and Wellspring cap; live catch percentage, rate/cap/bowl, consistent explanations and threshold text.
4. Explanations: await preferred animated in-game guides versus standalone videos; create focused explanations for rank choices, defended maze income, and catcher Harvest/interest.
5. Shutdown cleanup: investigate verbose leak ownership; repair real unowned nodes/resources with meaningful regression. Do not hide warnings.
6. Validation: targeted tests, existing signatures/catchers/UI/phone/settings/save/lessons checks as impacted; mandatory 300-frame startup smoke; whitespace check; read-only council review.

Completed:
- Approved four-pick rules and 20% All-Rounder/main-job Mastery. Legacy/free choice migration occurs before bonus selection. Council reviewed Sapling yield and actual Dreamcatcher Caught tick hooks; final review found no blockers.
- Hide/reopen arrows; live catch/range/bowl and interest/cap feedback; Seedbearer/Wellspring descriptions corrected.
- Replayable in-game animations via Pause → Replay guides; first-time relevant lessons use them. Replays preserve Hints/discovery history and modal pause ownership.
- Shutdown ownership fixes: inactive TestGrove preallocated controls, lazy HUD hover controls, overwritten GiftScreen placeholder, off-tree diagram cleanup, temporary UI-test rows.
Validation: signatures (including live bonuses, legacy migration and both-kin four-pick checks), signature_dreams, catchers, nurture, nurture_choices, free_ranks, rank_cards, save, initial_lessons (including animation replay/pause/settings), hide_controls, warden_header (including live bowl), warden_meter, phone_layout, ui and twig_walls passed. Common shutdown warnings and UI-test-specific allocations are resolved. Startup smoke: headless quit-after 300 passed. No commits or pushes.