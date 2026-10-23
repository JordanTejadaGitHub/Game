# Round 1 fixes to verify (prompts sent 2026-10-22; applied in e31d8b8e, cef44886, ce75281f)

For each item: DONE (text now right and reads well), PARTIAL, MISSING, or WRONG (new text still disagrees with data or
reads badly). Check against the current file and the data / constant named.

## Owner decisions
D1 Sleep -> Drowsy: icon_info.gd STATUSES drowsy name; dream_keywords.gd drowsy chip name. No "Sleep" left as the status name anywhere in player text.
D2 Reroll: icon_info.gd new_cards token names; codex_data.gd glossary "New cards" -> "Reroll"; dream_state.gd reroll_label / reroll_tip ("Dream again" gone).
D3 Banish: dream_state.gd banish_label / banish_tip / supply_line ("Let go", "let-go(s)" gone from player text; Grove node name "Let Go" may stay).
D4 UK spelling in player text (neighbour, colour, grey, centre, favourite).

## Main Merger
M1 codex Wellspring cap 260 (DewCatch.INTEREST_CAP). M2 codex Perfect block 20. M3 codex family picks after drifts 1, 10, 35, 60 (Boss, Family pick, Dreamlight entries). M4 codex Set Off 12 (16 Lullaby Bell). M5 Night Chimes 12. M6 Arc 4.5. M7 Swift +15%. M8 Rank adds range. M9 Poison lesson one shared clock. M10 Reaction lesson: two statuses each at enough stacks trigger a Reaction. M11 "Never slowed" without Soak. M12 Dreamlight sources match (codex vs remember_screen). M13 codex 180 / 576 "falls {asleep}".

## Roguelite Code
R1 dream_state.gd mojibake gone (no "Â·" or "Ã"). R2 captions: Crossroads +100%, Briar Crown 60%, Thicket 20% with no Sprout condition, Bitter Hedges matches its card. R3 Soak chip = Water hits +20%. R4 Hunter's Patience flyer bonus in the description. R5 Thorncoil and Bellflower "every second" made unambiguous. R6 lent cards use {family:} tokens instead of "a Sporeling / a Firefly / a Dewdrop / a bell".

## Tower Code
T1 Grandmother Oak Dew from the field (30). T2 Heartwood Sapling 16 / +8 from fields. T3 Honeysuckle card 12 (walls). T4 Honeysuckle "{asleep}" not "sleep". T5 Mossback / Boulderback / Exposed Blow "full {marked}". T6 Great Bell "4+ {static}". T7 Thorncoil "every second" fixed. T8 10 Root Wardens: "It damages every nightmare in range." T9 Thunderclap / Lightning Rod use {stacks:need_…}.
