# Seat P (wording and look keeper), round 2026-10-24d: all 38 nightmares

**Verdict: feels good with fixes.** All 38 have their own sheets (no `tint` / `sprite_scale` placeholder anywhere: F3
passes), bosses meet the title / tips / defeat-line / whisper rules, and most cards read. But one card shows a raw
token (Gloamwing `{soaked}`), four lines state things that aren't true today (Crow "all Wardens can hit it",
the Stag's rain tip, the Whisper Swarm's area hint, the Fast line's "holds"), the ability glyphs borrow other
traits' shapes, and about a third of the everyday cards say the same thing in title, description and hint (E2).

Checked: `roster.md`, every `trait_text` / `intro_lines` / `hint` / boss field against the code; token
resolution (`icon_info.gd:397` `format`, `status_links.gd:57` `bbcode`, `enemy_data.gd:321` `format_text`); Kind
lines (`enemy_data.gd:23-30`); glyphs (`nightmare_icons.gd:41-61, 336-396`); frame sizes of every sheet; flyer,
Wisp and Thief sheets by eye.

## Failures

| # | Nightmare | Std | What's wrong | Fix (one meaning) | Owner |
|---|---|---|---|---|---|
| 1 | Gloamwing | E1, E2, E4 | `{soaked}` is not a token: `IconInfo.format` only replaces `STATUSES` ids (`damp`…) and `TERMS`; nothing maps `soaked`, so the card prints "{soaked}" in title and intro. Also: "but heavy wings" isn't a sentence; "3" is typed (field `drop_stacks`); "holds" is the old Held name; the hint repeats intro line 1; "a splash and two tolls" names families (Dewdrop, Bellflower). | trait: "Flies the path until its wings get heavy: {drop_stacks} stacks of {damp} and {drowsy} together bring it down." intro: "Down, it walks the rest of the way for good, and your maze, ground effects and {held} all reach it." / "{damp} and {drowsy} count together." hint: "Brought down early, it walks most of your maze." | Enemy Code |
| 2 | Crow; Scarecrow tip 2 | E4 | "Wardens all along the path can hit it" / "Wardens all along the maze can hit them": false for every "Can't hit flyers" Warden. Night Kite already says it right. Crow intro also repeats the title ("flies the path over your walls"). | Crow trait: "Flies along the path above your walls: Wardens that hit flyers reach it all the way." intro: "Small and fast: they burst from the {nightmare:scarecrow}'s coat." Scarecrow tip 2: "They fly the path over your walls: Wardens that hit flyers can reach them all along it." | Enemy Code |
| 3 | Hollow Stag | E3, E4 | Tip 3 "Rain douses the ghost-fire in its antlers." is the old water weakness (damp types gone 2026-10-15; no rain/douse code in `scripts/`). Trait "Tramples walls": every Warden is a wall in this game, but only Thornwalls fall (`enemy_data.gd:47`). | Trait: "Tramples Thornwalls and charges down straights: keep the path turning, and never lean on one Thornwall." Tip 3 (its proverb slot): "Only Thornwalls fall. Your Wardens stand." | Enemy Code; doc row: Enemy types design |
| 4 | Kind lines (all Fast, Hidden) | E1, E4 | Fast: "slows and holds keep it in reach" ("holds" = the retired Held; status is Root). Hidden: "until a Warden reveals it", but the Will-o'-Wisp reveals too (`enemy.gd:3419`), and the Gravecrawler (Hidden Kind) is never revealed: it is out of the `enemies` group while under (`enemy.gd:3086`). | Fast: "Fast: it outruns a thin maze; slows and {held} keep it in reach." Hidden: "Hidden: it can't be targeted until something reveals it, or while it is underground." (Whether the Gravecrawler stays Hidden: S/W.) | Enemy Code |
| 5 | Drowned One | E2, E4 | Title, intro and hint all say "no slows / lightning loves Soak"; its Drowsy and Root immunity (`status_immune`) is on no line; "with lightning if you have it" names a build. | trait: "Always has {damp}; slows, {drowsy} and {held} never take hold." intro: "Black water streams off it as it walks, and it never dries." hint: "Lightning loves {damp}." | Enemy Code |
| 6 | Whisper Swarm | E4 | Hint "Anything that damages an area hits every whisper at once" was true with the ×0.5 single-target rule; that rule is gone (Nightmare Kinds), so one area hit on one Swarm does the same as one single hit. Doc still says "single-target damage reduced" (enemy_design.md roster, `acts_3_4.md:30`). | hint: "They come by the dozen, packed close: one area hit reaches several." Fix both docs. | Enemy Code; docs: Enemy types design |
| 7 | Watcher | E2, E4 | It strips every {drowsy} stack (`enemy.gd:3257-3263`), not "wakes" them; intro and hint restate the title. | trait: "Never sleeps, wakes the {asleep} near it and clears their {drowsy}: dispel it first." intro: "It can't gain {drowsy}. Reach: {wake_radius} cells." hint: "A {silenced} Watcher wakes no one." | Enemy Code |
| 8 | Phantom | E2 | Title, intro and hint all say "straight to the Heartwood over walls". Missing facts: can't gain Root, at most 4 in a drift (`drift_max`). | intro: "Your maze doesn't exist for it. Roots can't grip it: it can't gain {held}." hint: "At most {drift_max} come in a drift." | Enemy Code |
| 9 | Lantern Bearer, Wraith | E2 | Bearer intro line 2 = its title; Wraith intro and hint = Bearer's title. | Bearer intro line 2 → "A {silenced} Lantern Bearer's lantern goes dark too." Wraith intro: "Each one that reaches the Heartwood takes {leaf_cost} {leaf}." (one line); hint: "Without the lantern they walk at {lost_speed}." (or drop the hint). | Enemy Code |
| 10 | Mourning Mother | E3 | Black Tears "Heals nightmares within {mend_radius} cells." has no rate (`mend_rate` 0.02); the ability doesn't read fully. Icon `damp` puts the Soak glyph on a heal. | "Heals nightmares within {mend_radius} cells for {mend_rate:pct} of their health a second." icon `mender`. | Enemy Code |
| 11 | Boss ability glyphs | F1, E3 | Glyphs are shared by shape (`nightmare_icons.gd:364` `wanders`+`grief`, `:389` `splits`+`sapling`+`rises`, `:354` `sprints`+`charge`), and some icons are other keywords: Huntsman "The Pack" and Lamplighter "Cold Light" use `hidden`; Black Tears `damp`; Withering Grip and Cold Lanterns `sapling`; Shrug `grief`. A player reads Hidden, Soak, "wanders", "splits" on abilities that are none of those. | Own glyphs: `pack` (Pack), `lantern` (Cold Lanterns, Cold Light), `wither` (Withering Grip, Drought), `shrug` (Shrug), `summon` (every grief / bellow / crows / horn), `mender` (Sorrow, Black Tears); never a status or Kind glyph on an ability that isn't it. | Main Merger (glyphs), Enemy Code (icon ids) |
| 12 | Night Hound | E4 | "Sprints down long straight paths" but `roll_after_tiles` = 3; the hint even says "Even a short straight sets it off". Glyph tip "long straight corridors" (`nightmare_icons.gd:48`) too. | trait: "Sprints down any straight of {roll_after_tiles}+ cells: corners break its stride." hint: "A sprint ends at the next turn." Glyph: "Speeds up down straights, until the next turn." | Enemy Code, Main Merger (glyph tip) |
| 13 | Weeper (+ glyph) | E4 | One thing, two words: Weeper intro "Mends", trait "Heals"; the Mother "heals"; glyph "Mends". | "Heals" everywhere (intro, glyph name "Heals", tip). | Enemy Code, Main Merger |
| 14 | Dream Thief | E2 | Intro repeats the whole title (steal + double); `{dew:5}` typed beside the `steals_dew` field. | trait: "Steals {dew:{steals_dew}} if it reaches the Heartwood, and drops double {dew} if dispelled." intro: "A grinning shape clutching stolen light. It takes a {leaf} too." | Enemy Code |
| 15 | Hollow Oak forms | E3 | Withering and Remembering titles start "Withering:" / "Remembering:", Thorned doesn't. Remembering's tip 3 "Remember how you beat them the first time." is a third closing proverb (rule: two, Stag and King) and, with its whisper "It remembers every one of them", breaks the voice rule ("Remember" only for the Remember screen, Memories, the Grove). | Thorned trait starts "Thorned: ". Remembering tip 3 → "An echo of the Night Mare laps; one of the Lamplighter lights lanterns." Whisper: "It's here. It's wearing their faces." | Enemy Code |
| 16 | Night Kite | E2 | Intro line 1 ("Walls never slow it: it follows the path from above") = title; hint = intro line 2. | intro: "A ragged kite on a knotted string. Ground effects never reach it." / keep line 2; hint: "It's past one spot in a moment." | Enemy Code |
| 17 | Ash Crawler | E2 | Hint restates the intro's {ash_trail_time} s. | hint: "{spored} put on after the ash cools stays." | Enemy Code |
| 18 | Pall | E4 | Hint "lighter than what it shields": "shields" reads as damage reduction, which the ruling forbids ("shares, it doesn't halve"); title says "covers". | "Hit the Pall first: it has less health than what it covers, and area hits catch both." | Enemy Code |
| 19 | Gravecrawler | E4 | Kind Hidden, but no line says it can't be hit while under; title says "one" while intro uses `{burrow_max}`; hint repeats the title. | intro add: "While under, nothing can hit it." title: "Burrows under {burrow_max} Warden or wall each trip". hint: "Lit path tiles keep it above ground." (`enemy_spawner.gd:455`) | Enemy Code |

## Near-misses (E2 overlap, wording)
- **Shade** (approved text, flagged only), **Sob, Creep, Sleepwalker, Lurker, Mire Hag tip 1, Mourning Mother tip
  1:** intro or hint restates the title. **Husk:** title holds four ideas; suggest "Slow and very tough, under a
  {dread_shell}." **Barrow Wight:** intro line 2 repeats the title's Root / Drowsy facts. **Mourner:** title types
  "three" beside `{split_count}`.
- **Will-o'-Wisp:** says "Lurkers", but its glow reveals any hidden nightmare, Eclipse ones too (`enemy.gd:3419`):
  "reveals the {hidden} near it".
- **Huntsman:** "{pack_shield:pct} damage" renders "takes 50% damage": write "half damage".
- **Dead glyph** `bulky` "Area hits deal less to it." (`nightmare_icons.gd:60, 177`): no nightmare uses it (S).
- **Look:** the Wisp is a small glow with almost no body at 64 px (weak silhouette); the Gloamwing's fly rows show
  no eye or core glow; a lone Pall is pale like the Phantom. Lanes: every non-boss sheet is 64 px and only bosses
  get ±0.1 (`LANE_BIG_SCALE` keys on `sprite_scale`), which fits F2.

## Docs that disagree with the data (Enemy types design)
enemy_design.md: boss Resists / Weak to columns and "one weakness" rules; Withering "Weak to water"; Night Mare
"takes 3 leaves"; Watcher "resists song"; Whisper Swarm "single-target damage reduced"; Kinds "Reveals Hidden (Brood
Cap, Quaker)" (role lines are on Rootlight, Starcave); "Boss text" table (4 Mire Hag tips, data 3). Mark as history
so no text pass copies them back.

## Owner calls
1. **Advice after the colon.** Nearly every `trait_text` ends in advice: "use Wardens that hit many at once", "rely on
   heavy hits", "with lightning if you have it". The 2026-10-05 card rule allowed it; the owner rule is "facts only,
   never build Y". My recommendation: keep advice about **the maze and the order you dispel things** (corners,
   spread out, dead ends, dispel it first), and drop advice that **names a Warden type, family or status source**
   (lightning, heavy hits, area Wardens), because the Kind badge line already says that as a fact.
2. **Heal or mend:** one word for the Weeper, the Mother and the glyph (I'd pick "heal").
3. **Text says what other seats may rule against:** the Huntsman's half damage (B2: "the dread shell is the only
   damage reduction") and the Thorned Oak's "Thorn-Saplings bend the path" (A5: the route is the player's plan).
   The text is honest about both; if T/S change the rule, the cards change with it.
