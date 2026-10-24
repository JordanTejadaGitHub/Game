---
name: enemy-design-council
description: Run Heartwood TD's Enemy Design Council: five read-only reviewer agents (build player, Warden roster keeper, tower defense veteran, systems and code keeper, pacing and balance) judge an enemy, drift or boss change against the current game, asking one question, does it make Wardens and Dream builds feel good; then one lead review with rulings, a fix-first list and paste-ready prompts. Use when the user asks for an enemy / nightmare / drift / boss design council or review.
---

# Enemy Design Council

Created 2026-10-24 (user: "Create a council for enemy design, then let the council go over this change with keeping
the current game in mind in terms of making wardens and dream builds feel good"). Five agents each read a lot
(~50-80k tokens apiece), so run it when the user asks, after a batch of enemy or drift design.

**Files** (all on D:, never C:): briefs in `D:\Projects\logs\enemy_council\briefs\` (`_common.md`, `seats.md`);
each round in `D:\Projects\logs\enemy_council\rounds\<YYYY-MM-DD>\` (`subject.md`, `seat_<B|W|T|S|P>.md`,
`verdict.md`). The lead review lands in the repo as `documentation/enemy_council_review.md` (a newer round adds a
section; earlier rulings that still hold stay) with the seat reports in `documentation/enemy_council/<date>/`.

## Steps
1. **Subject:** write `subject.md` in the round folder: what changed (doc sections and commits), what the owner
   asked, and earlier reviews the seats should read.
2. **Five seats in parallel** (general-purpose agents, background): each prompt = `_common.md` + its seat from
   `seats.md` + the round folder path. Read-only: no edits, no Godot, no tests, no sims.
3. **Spot-check before ruling:** every code or data claim that reaches the fix-first list gets one grep against the
   script / .tres yourself. Seats are sometimes wrong.
4. **Lead review** (`verdict.md`, copied to `documentation/enemy_council_review.md`): verdict; where the seats agree
   (letters B W T S P); where they disagree and the ruling; fix first (with owner chat); builds and Wardens that
   shine / suffer; numbers for Balancing; open owner calls.
5. **Update the design** (`enemy_design.md` and the act tables) only with rulings that need no owner call; mark the
   rest as open.
6. **Report to the user** in plain words: verdict, top problems, owner calls. Work for other chats goes out as
   paste-ready prompts (route-prompt skill), one per owning chat. Don't edit other chats' files on the council's word.
