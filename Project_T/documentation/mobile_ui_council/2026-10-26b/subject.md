# Round 2 (2026-10-26): the phone drift controls only (bottom right)

Owner (2026-10-26): "Go over that portion with the council first" (before a phone build), after three asks today:
"pause and speed buttons should be bigger than the auto button", "the pause button and speed button should be wider
than the auto since its used more", "Just rename it to say auto". Built in commits 966e9f42 and eab31a19
(`scripts/ui/drift_panel.gd`, the phone branch after `if UiStyle.is_phone():` near line 183; `_add_speed_button`,
`_on_look`, `_on_phone_speed`, `_fit_start`, `_process` for the Start button's words and states).

## What it is now (phones)
- Row 1: one wide button: "Start drift N" at a rest (gold, the one primary), "Call drift N early, +Dew" mid-drift,
  "Resume" while paused mid-drift, the waiting choice's name when a Dream etc. waits. As wide as row 2.
- Row 2, left to right: **Auto** (48 px tall, as narrow as its word, sits at the row's foot; on = brass plate + a small
  underline mark), **II** (pause, 96 x 60, 22 px type), **speed** (96 x 60; one button that cycles 1x -> 2x -> 3x -> 1x;
  the current speed is its label), 10 px apart. Auto-drift = drifts in a block start by themselves a few seconds after
  the last one arrived.
- While building (a Warden picked to place) the speed row steps aside; while the Warden drawer is open the whole panel
  hides (it sits under the drawer). PC: unchanged (Auto-drift on, II, 1x 2x 3x as separate buttons).

## The question
Is this the right layout for a phone (thumb reach, sizes, what reads as primary, how Auto's on/off reads with one
word, the speed cycle vs separate speed buttons, pause vs Resume duplication, Start drift's width), compared with
how mobile TDs (Kingdom Rush, Bloons TD 6's play / fast-forward and auto-start, Arknights' 1x/2x and pause, Infinitode 2,
PvZ2) do it? Keep it to this portion. Rank fixes; say what to keep.

## Screenshots (shots\)
large_* / standard_* (both UI sizes, 1200 x 540): rest_auto_off, rest_auto_on, building, drift_2x, drift_paused,
drawer_open. Earlier full-screen context: ..\2026-10-26\shots\large_hud.png.
