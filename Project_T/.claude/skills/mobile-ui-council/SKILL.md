---
name: mobile-ui-council
description: Run Heartwood TD's Mobile UI Council: five read-only reviewer agents (mobile tower defense veteran, mobile roguelite veteran, touch ergonomics and accessibility, PC parity keeper, first-time phone player) judge the phone UI from fresh phone + PC captures and the code, with web research into how other mobile tower defense and roguelite games solve the same screens; then one lead review with rulings, a fix-first list and paste-ready prompts. Use when the user asks for a mobile / phone UI council or review.
---

# Mobile UI Council

Created 2026-10-25 by the Mobile UI chat (user: "Create a mobile ui council that also look at other mobile tower
defence and roguelite games for context"). Five agents each read screenshots, code and do ~10-15 web lookups, so run it
when the user asks, ideally after a batch of phone UI changes.

**Files** (all on D:, never C:): briefs in `D:\Projects\logs\mobile_council\briefs\` (`_common.md`, `seats.md`,
`standards.md`: reach, targets, read, no hover, parity, safe, PC untouched, look; keep it current when a round or the
owner changes a rule); capture scripts in `D:\Projects\logs\mobile_council\tools\` (`capture_drawer.gd` `-- --pc` /
`--share=1.0|0.9`; `capture_screens.gd` `-- --share=1.0|0.9`; edit their `out_dir` to the round); each round in
`D:\Projects\logs\mobile_council\rounds\<YYYY-MM-DD>\` (`subject.md`, `shots\`, `seat_<K|R|T|P|F>.md`, `verdict.md`).
The lead review lands in the repo as `documentation/mobile_ui_council_review.md` (a newer round adds a section; earlier
rulings that still hold stay).

## Steps
1. **Captures:** run both scripts windowed (not headless) through the wrapper, one at a time:
   `bash /d/Projects/logs/scripts/godot_dev.sh mobile_council --path /d/Projects/Game/Project_T --script D:/Projects/logs/mobile_council/tools/capture_drawer.gd -- --pc`
   (then `--share=1.0`, `--share=0.9`; then capture_screens.gd at both shares). Check a few PNGs yourself.
2. **Subject:** `subject.md` in the round: the build / commit, what changed, the owner's asks this round (each seat
   answers them), open items from earlier rounds.
3. **Five seats in parallel** (general-purpose agents, background): each prompt = `_common.md` + its seat from
   `seats.md` + `standards.md` + the round folder path. Read-only: no edits, no Godot, no tests.
4. **Spot-check before ruling:** every code claim that reaches the fix-first list gets one grep yourself; every "game X
   does Y" that a ruling leans on should be cited by the seat. Seats are sometimes wrong.
5. **Lead review** (`verdict.md`, copied to `documentation/mobile_ui_council_review.md`): verdict; the owner's asks with
   rulings; where seats agree (letters K R T P F) / disagree and the ruling; fix first (owner chat: Mobile UI for phone
   layouts, UI Code for the look, others by file); patterns from other games worth copying; what works; open owner calls.
6. **Report to the user** in plain words: verdict, top problems, owner calls. Phone-only fixes in the Mobile UI chat's
   files are done on the user's go; work for other chats goes out as paste-ready prompts (route-prompt skill).
