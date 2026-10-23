---
name: wording-council
description: Run Heartwood TD's Wording Council: five read-only reviewer agents (new player, genre veteran, consistency keeper, scan reader, plain English) read every player-facing text and judge whether gamers can read it and understand the effect; then one lead review with rulings, a fix-first list of wrong text, phrasing rules and paste-ready prompts. Use when the user asks for a wording / text / readability council or review.
---

# Wording Council

Created 2026-10-22 (user: "look for all the wording and make sure it looks right for gamers, if they can read and
understand the effect properly. Create a council just for this purpose"). Five agents each read the whole corpus
(~70k tokens apiece), so it is expensive: run it when the user asks, ideally after a batch of new cards or a rename.

**Files** (all on D:, never C:): briefs in `D:\Projects\logs\wording_council\briefs\` (`_common.md`, `seats.md`,
`extract_corpus.sh`); each round in `D:\Projects\logs\wording_council\rounds\<YYYY-MM-DD>\`. The lead review lands in
the repo as `documentation/wording_council_review.md` (a newer round replaces it; keep earlier rulings that still
hold) with the seat reports in `documentation/wording_council/`.

## Steps
1. **Corpus:** `bash /d/Projects/logs/wording_council/briefs/extract_corpus.sh <round folder>`. If the user wants only
   part judged (new cards, one screen), cut the corpus to that.
2. **Five seats in parallel** (general-purpose agents, background): each prompt = `_common.md` + its seat from
   `seats.md` + the round folder. Read-only: no edits, no Godot, no tests.
3. **Spot-check before ruling:** every "text says X, game does Y" claim that goes into the fix-first list gets one grep
   against the .tres / script yourself. Seats are sometimes wrong.
4. **Lead review** (`verdict.md` in the round, copied to `documentation/wording_council_review.md`): verdict; where the
   council agrees (seat letters N V C S P); where they disagree and the ruling; fix first (text that is wrong, with
   owner); phrasing rules; one-name terms; localisation risks; what works; open owner calls.
5. **Report to the user** in plain words: the top problems, the owner calls. Work for other chats goes out as
   paste-ready prompts (route-prompt skill), one per owning chat; the user decides what to accept. Don't edit other
   chats' files from the council's word alone.
