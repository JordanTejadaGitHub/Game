---
name: sound-council
description: Run Heartwood TD's Sound Council: five read-only reviewer agents (theme keeper, house rules, mix engineer, composer, player's ears) judge every sound effect and music stem against the dark-fairytale theme, audio_direction.md and the user's listening verdicts, using the generator recipes, the hooks and measured loudness / brightness of every rendered file; then one lead review with rulings, a fix-first list and paste-ready prompts. Use when the user asks for a sound / audio / music council or review.
---

# Sound Council

Created 2026-10-23 (user: "Create a council for sound design in the game, make sure it's relevant to the theme and
existing sound"). Owned by the Sound Discussion chat (it owns documentation/audio_direction.md). Five agents each
read the doc, the generator and the hooks (~80k tokens apiece), so run it when the user asks, ideally after a sound
pass or before a listening session.

**The agents can't hear.** They judge from the design doc (and its Revisions tables = the user's listening verdicts,
which outrank everything), the synthesis recipes in tools/sound_generator.gd, the wiring in scripts/audio/, and
`measure_sounds.sh`'s numbers (peak, RMS, spectral centroid, rolloff, attack per file, via ffmpeg). Nothing the
council says replaces the user listening: findings are "listen to these first", not verdicts on taste.

**Files** (all on D:, never C:): briefs in `D:\Projects\logs\sound_council\briefs\` (`_common.md`, `seats.md`,
`measure_sounds.sh`); each round in `D:\Projects\logs\sound_council\rounds\<YYYY-MM-DD>\`. The lead review lands in
the repo as `documentation/sound_council_review.md` (a newer round replaces it; keep earlier rulings that still
hold) with the seat reports in `documentation/sound_council/`.

## Steps
1. **Measure:** `bash /d/Projects/logs/sound_council/briefs/measure_sounds.sh <round folder>` (ffmpeg only, no Godot;
   ~2 minutes for every file). It writes sounds_measured.tsv, hooks_ids.txt, sound_signals.txt and copies the docs.
   If the user wants only part judged (the new Reactions, one act's music), say so in each seat's prompt.
2. **Five seats in parallel** (general-purpose agents, background): each prompt = `_common.md` + its seat from
   `seats.md` + the round folder. Read-only: no edits, no Godot, no renders, no tests.
3. **Spot-check before ruling:** every "the recipe does X" or "the hook plays Y at Z dB" claim that goes into the
   fix-first list gets one look at the line yourself. Seats are sometimes wrong. Never rule against an approved sound
   (the dispel, the Firefly Jar) or a Revisions verdict on a seat's word alone.
4. **Lead review** (`verdict.md` in the round, copied to `documentation/sound_council_review.md`): verdict; where the
   council agrees (seat letters T R M C P); where they disagree and the ruling; fix first (with owner: recipe and
   hooks = Sound code implementation, design = Sound Discussion, gameplay signals = their code chat); listen first
   (the sounds the user should hear before anything changes); missing sounds; house rules to add to audio_direction.md;
   what works; open owner calls.
5. **Report to the user** in plain words: the top problems, what to listen to, the owner calls. Design changes go into
   audio_direction.md only after the user agrees. Work for other chats goes out as paste-ready prompts (route-prompt
   skill), one per owning chat. Don't render or change sounds from the council's word alone.
