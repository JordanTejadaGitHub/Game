# Warden Night: the Wardens' shade for the Mistwood look

**Status: proposal (2026-09-30).** The user picked "night shade" for the Wardens and asked for it
to be fixed and made into a palette. It goes with the Mistwood environment preview
(https://claude.ai/artifact/R3v9xg1JhCoRXkRpob3twd), which is also preview only. The in-game Warden art is
unchanged. Comparison page: https://claude.ai/artifact/969uR9QxNS9D71h8gCDqdh

**Owners.** Tower Assets applies this to the Warden sheets. Theme Code wires the colours into
`HeartwoodPalette` / the palette export. Theme Discussion records the 3 added colours in
`art_direction.md`, which allows at most 4 additions.

## The idea

Every Warden keeps its base colour and moves **one shade darker inside its own colour family**, so
the Wardens sit in the fog instead of glowing like stickers on it. Sporeling stays pink, Dewdrop
blue, Acorn amber and Bramble green. Their stone bases darken with them.

A plain one-step-down swap inside Heartwood 32 had three problems:

1. **Sporeling got louder.** Blossom → Orchid is the palette's most saturated magenta.
2. **Acorn and every gold Warden didn't change**, because gold was kept for glows. Gold is a body
   colour on about 15 Wardens (Acorn, Gust, Samara, Rootling, Beacon, …).
3. **Dreamshroom didn't change.** Wraithlight had no darker step, and violet in the fog reads as a
   nightmare.

## The fix: 3 new colours and one map

| New colour | Hex | Replaces | Why |
|---|---|---|---|
| **Rosedust** | `#b27aae` | Blossom | A dusty, darker pink. The mascot stays pink but calmer. |
| **Plum** | `#7a4a82` | Orchid | The matching shadow, less saturated than Orchid. |
| **Nightbloom** | `#6b6fb0` | Wraithlight | A deeper, bluer violet, so a Warden never reads as a nightmare. |

Gold bodies now shift like everything else (Gold → Ember, Glow → Gold, Heartlight → Moonpath), so
the warm Wardens turn amber, not neon yellow. Glow halos shift too but keep their alpha, so they
stay warm.

**The full map** (Heartwood 32 → Warden Night). Colours not listed stay the same:
Void, Night, Dusk, Dread, Shade, Bruise, Deepmoss, Root, Loam and Pool.

| Ramp | Map |
|---|---|
| Ink | Slate → Dusk |
| Stone & moon | Moonlight → Mist, Mist → Stone, Stone → Slate |
| Nightmare | Wraithlight → **Nightbloom** |
| Moss | Newleaf → Sprig, Sprig → Leaf, Leaf → Moss, Moss → Deepmoss |
| Bark | Deadwood → Path, Oak → Bark, Bark → Root |
| Path | Moonpath → Path, Path → Loam |
| Warm light | Heartlight → Moonpath, Glow → Gold, Gold → Ember, Ember → Oak |
| Blossom | Blossom → **Rosedust**, Orchid → **Plum** |
| Dew | Dewlight → Dew, Dew → Pool |

**Rules:**
- Apply the map to the Warden idle sheets only. Attack sheets and projectiles keep full warm light:
  attacks are *light pushing back the dark*.
- The Heartwood, nightmares, tiles and UI don't use the three new colours.
- The bottom of each ramp absorbs the step, so Slate/Dusk, Moss/Deepmoss, Bark/Root and Path/Loam
  merge. If a Warden loses a needed line because of this, fix it by hand. Don't add colours.

## Files (`assets/style_reference/warden_night/`)

| File | What |
|---|---|
| `warden_night.json` | The map (from → to, names and hex) and the 3 added colours with their roles |
| `warden_night.gpl` | GIMP/Aseprite palette: Heartwood 32 + the 3 Warden Night colours (35) |
| `warden_night_map.png` | Swatches for every colour: before → after. A gold tick marks a new colour |
| `wardens_night_sheet.png` | All 70 Wardens, frame 0, 2×: now (upper) / Warden Night (lower) |
| `sporeling_night.png`, `acorn_night.png`, `dewdrop_night.png`, `dreamshroom_night.png` | The fixed cases at 4×, before / after |
