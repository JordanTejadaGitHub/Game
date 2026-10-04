# Steam capsules and logo (concept A, in-house)

The store-page art for `marketing.md` §2. It's made in-house for now: the user said on 2026-10-04,
"Leave it AI for now, then I'll decide later". It follows the brief in `art_direction.md` ("Brief
for a human artist") and its "Avoiding the AI look" table. The user picked **concept A, the watchful
Warden**, over B and the A+B hybrid; both are archived in Theme Asset's gallery
(https://claude.ai/artifact/1Mq111zHWpf3EbgsWwF6d8).

Files are in `assets/store/steam/`. A `.gdignore` in `assets/store/` keeps them out of the
game build.

| File | Size | Notes |
|---|---|---|
| `header_capsule.png` | 920×430 | Art at 2×, the logo at 2× on the dark forest side, the Warden's face clear. |
| `small_capsule.png` | 462×174 | The logo at 2× nearly fills it (Steam's rule), on the Warden's dark body. It must read at 120×45. |
| `main_capsule.png` | 1232×706 | Art at 2×, the logo at 3× on the left. |
| `vertical_capsule.png` | 748×896 | Art at 3×, centred on the Warden, the logo at the bottom over the water. |
| `library_capsule.png` | 600×900 | Art at 3×, the logo at 2× at the bottom. |
| `library_hero.png` | 3840×1240 | Art at 6×, **no text** (Steam overlays the library logo). The Warden sits right of centre. |
| `page_background.png` | 1438×810 | Art at 3×, dimmed to 55% so it doesn't compete with the page. |
| `library_logo.png` | 1278×420 | The logotype only, transparent, 6× (max 1280×720). |
| `logo_1x.png` | 213×70 | The logo at 1×, the source for every size. |
| `source_title_polished.png` | 640×360 | The polished art all crops come from (see below). |

**Steam rules followed** (partner.steamgames.com store and library asset pages, checked 2026-10-04):
- Capsules show only the art and the game's name: no awards, quotes or other text.
- The small capsule's logo nearly fills it.
- The library hero has no text.
- The library logo is the logotype alone on transparency.

## What was polished

- **The art:** the title Warden as cleaned up by the Title Screen chat (AI-look audit #5, 96cc361b).
  The Warden and the nightmares are left exactly as drawn. On the background, a de-checker pass:
  - 50% checker fields in the fog and the warm halo fold into **hard shading bands**;
  - lone specks and stray motes are removed;
  - the glow stays where it means something: the Warden's eyes and the warm light behind it.
- **The logo, hand-lettered:**
  - The letterforms start from the UI's Cormorant Garamond, then each letter is placed by hand. Each
    has its own baseline nudge (−1 to +1 px) and spacing, and the strokes are heavier, like a pen.
  - The H's left stem drops a root that curls under the first letters. A leaf sprouts from the d.
  - "TD" sits off-centre on a single gold thread with one diamond, not a mirrored pair.
  - Colour: gold bands (Heartlight → Glow → Gold → Ember) with a Night and Void outline.
- **Whole-number scales only** (2×, 3×, 6×), hard edges, no smoothing.

**Not done yet:** no small map Wardens appear. The brief says to add them only in the new per-family
poses, once Tower Assets' redo of the starting three is approved. A layered source file (for a human
artist) isn't made; the title generator's layers in `assets/ui/title/` are the closest thing.
