# UI Style: Moonlit Thread

Fills the "UI style" item in `art_direction.md` ("Still to do"). **Chosen 2026-09-28** by the user
from five mock-ups on the concept page (https://claude.ai/artifact/4Cs1PP2CrqTjth2dHiZFow, style
"Moonlit Thread"; the page shows the run HUD, Dream choice and components on real game sprites).
Layout and behaviour stay in `screens_ui.md`; this doc only covers how the UI looks.

Built 2026-09-28 by the UI Code Implementation chat: `UiStyle` + `assets/ui/ui_theme.tres` (see CLAUDE.md
"UI style"). The panels, thread and fog are drawn in code (`MoonStyleBox`); the textures listed at the
end are optional.

## The idea

**Almost no frames.** Text and icons float on a soft patch of dark fog, with a thin gold thread
above each panel. The maze stays visible around and between every HUD element ("the forest comes
first"). Warm vs cold still holds: the gold threads, numbers and buttons are the dream's light; the fog
behind them is the night.

Rejected alternatives, kept on the concept page: Carved Waystone (pixel stone), Lantern Glass,
Bark & Vellum, Root & Thorn.

## Colours

Every UI colour is a **Heartwood 32** colour picked by name (`art_direction.md`; in Godot
`HeartwoodPalette.color("glow")`, `color("void", 0.78)`), mostly from the Ink, Stone & moon and
Warm light ramps. Translucency is a palette colour with alpha, never a new colour. (Mapped
2026-09-28 from the mock's hex values to the nearest palette colours.)

| Token | Palette colour | Use |
|---|---|---|
| `ink` | **Heartlight** | body text, titles |
| `ink_dim` | **Mist** | labels, secondary text, "/20" |
| `gold` | **Glow** | numbers, thread lines, active button text, links underline |
| `gold_text` | **Heartlight** | text on primary buttons (on Gold at 16%) |
| `button_line` | **Gold** at 45% | normal button outline; solid Gold on primary |
| `whisper` | **Moonpath** | Heartwood whispers (italic) |
| `poor` | **Ember** | unaffordable costs (with the 50% fade, so it never relies on colour) |
| `fog` | **Void** at 78% → 35% | panel background (radial, darkest in the middle) |
| `card_bg` | **Night** → **Void**, ~90% | Dream / family / Omen cards (more solid than panels) |

The palette has no red, so "can't afford" is **Ember** plus the fade; the build ghost's red stays a
world colour, not a UI one.

Rarity colours (with gem **shapes**, `screens_ui.md`): Common **Mist**, Uncommon **Sprig**,
Rare **Dewlight**, Legendary **Gold**.

## Type

All three are SIL Open Font License (free to ship on Steam and mobile).

| Role | Font | Notes |
|---|---|---|
| Display: titles, card names, big numbers | **Cormorant Garamond** SemiBold | numbers use lining, tabular figures |
| Labels | **Cormorant SC** Medium | lowercase small caps, +10% letter spacing ("act 1 · forest's edge") |
| Body: card text, tooltips, panels | **Alegreya Sans** Regular / Medium | at least 16 px at 1280×800 |
| Whispers | Cormorant Garamond Italic | with a dark shadow, no panel |

Sizes at 1920×1080 (the UI scale setting multiplies all of them): resource numbers 28, card name 30,
choice title 38, panel title 28, body 16–17, labels 15, costs 15.

## Parts

- **Panel:** no border. Radial fog (darkest in the centre, fading at the edges), 4 px corner radius.
  A **1 px gold thread** across the top that fades out at both ends (10% inset), with a **small
  hollow diamond** at its centre (8 px, gold outline, dark fill). This thread is the style's
  signature: every panel, card and tooltip has one.
- **Dream card:** more solid fog, 2 px radius, faint 1 px side edges. The top thread runs full width
  **in the rarity colour** instead of gold, plus the rarity gem and label at the top. No art frame:
  the card's icon sits straight on the fog. Tags are plain small caps separated by " · ".
- **Buttons** (all at least 48 px tall; small ones 40): a 1 px gold outline at 45%, dark fog fill,
  ink text. **Primary** (Start drift, Grow, Continue): gold at 16% fill, a solid gold outline, a
  soft gold glow, `gold_text`. **Toggled** (1×, Auto) use the primary look. **Disabled:** 45% opacity.
- **Warden bar slots:** no box, just a fog patch under each Warden. The **selected slot** has a
  2 px gold underline with a glow. Unaffordable: 50% opacity, cost in `poor`.
- **Resources and Dreams row:** fog patch only, no thread (they sit at the screen edge).
- **Dividers inside panels:** a 1 px gold line fading at both ends.
- **Links** (status words, card names): ink text, gold underline 1 px, 3 px below.
- **Range circle / selection:** warm gold dashed ring with a faint gold fill (matches the threads).
- **Icons:** the existing 16×16 pixel icons (`assets/ui/icons.png`) scaled by whole numbers (×2 in
  panels, ×3 on cards), nearest filtering. Pixel icons on smooth type is intentional: the icons
  belong to the world, the type belongs to the dream. The generator (`tools/ui_icon_generator.gd`)
  snaps every icon to Heartwood 32 (nightmare traits to its cold ramps).

## Readability rules

- The fog must make text readable over **anything** (a Dawnburst, a bright Heartwood): if a panel
  sits over bright effects, the fog gets darker, never the text smaller.
- Accessibility "high contrast UI" option (proposed): fog to 92% and threads to full gold.
- Colour is never alone: rarity has shapes, costs have the red **and** the fade.

## Building it in Godot (for the UI code chat)

- One `Theme` resource (`ui_theme.tres`) with the three fonts and the colours above.
- Panels: `StyleBoxTexture` using a radial fog texture (9-slice, wide margins), or `StyleBoxFlat`
  with `shadow_size` for the fog. The thread + diamond is a small `TextureRect` (or `_draw`) anchored
  to the panel's top; the Dream card version takes the rarity colour as a modulate.
- Buttons: `StyleBoxFlat` (1 px border, 2 px radius) for normal / hover / pressed / disabled; primary
  adds `shadow_color` gold for the glow.
- Art to make (UI assets chat): `fog_panel.png` (9-slice), `thread.png` (fades at both ends,
  white so it can be tinted), `thread_diamond.png`, `divider.png`.
