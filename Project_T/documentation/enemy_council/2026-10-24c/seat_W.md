# Seat W (Warden roster keeper): more of the group-wipe moment

Footage: `dt_4.mp4` (big Packs 70, 107 nightmares in 6 packs), `dt_1.mp4` (Packs 26); frames in `seat_W_frames\`.
The board is base forms only (4 Firefly Jars, 3 Dewdrops, 3 Bellflowers at rank IV, Firefly Calling), so no branch or
final form is on film; form claims below are from `resource/tower/*.tres`.

## 1. Verdict
**Feels good with fixes.** A wipe is *synchronised death*: even area damage on a clump (pulses, splash, clouds,
shared damage) or a dispel cascade. Three of four starting families get it early. Sporeling gets it late. The forms
with a **count cap** (forks, chains, links) cut a big pack into thirds, which reads as one at a time. Pack sizes 6-8
fit the roster's caps. Single file being this rare quietly over-rewards area forms.

## 2. What works (keep)
- **In the video the wipe comes from two Warden sources.** The Bellflower pulse (`bellflower.tres`: PULSE, range
  2.0, 18.36 dmg/s) wears a clump down evenly, and Lantern Light's dispel jump (`firefly_lights.gd:26,29`: half the
  hit, up to `EVENT_MAX` 6 forks) chains death into death: the gold sparks sweeping a big pack at 13-16 s. Low even
  damage plus a dispel cascade is the look the owner likes.
- **Pack size 6-8 matches the roster's caps:** Maelstrom links 8 and Undercurrent 6 (`maelstrom.tres` /
  `undercurrent.tres` `link_max`), Lantern forks 6, Sparkler / Starburst 6 sparks in 1.5 cells, Starling multi 5,
  Stormcap / Thunderhead chain 4 + the first target. One capped Warden can take a whole normal pack. Keep.
- **Every family has wipe forms.** Area, pulse, cloud, link or chain forms, out of 14 each:

  | Family | Wipe forms | From |
  |---|---|---|
  | Bellflower | Bellflower, Chime Stone, Lullaby Bell, Echo / Whispering Hollow, Hushbell / Silence, Great Bell (pulse, range 5.0, 422 dmg), Thrum / Resonance (cone 90-180°) | **base** |
  | Dewdrop | Dewdrop (splash 0.6), Rain Lily (1.0), Hoarfrost (0.75), Monsoon (pulse 3.0), Mistveil / Morning Fog (cloud 0.9 / 1.25), Undercurrent / Maelstrom (links), Jetreed / Torrent (6-cell line) | **base** |
  | Firefly Jar | Calling jump (6), Stormcap / Thunderhead / Stormheart (chains), Sparkler / Starburst, Jarlink / Lightning Fence (arc), Midsummer (beam spill 0.5) | Calling, or branch |
  | Sporeling | Bloomcap / Dreamshroom (cloud 0.75 / 1.0), Fairy Ring / Elf Circle (path traps), Puffball (splash 1.0), Sporemother (pulse 3.0) | **branch / tier 3** |

- **Lanes are visual only** (enemy_design.md "Walking lanes": area hits use the node on the centre line), so the
  0.2 lane changes no hit counts. Clumps look right without making any Warden stronger.

## 3. Problems, ranked

**W1. Big packs (≈18 each) overflow the count caps, so capped Wardens wipe a third.**
- *Player feels:* in Packs 70, the Firefly cascade clears 6 of 18 and the rest die one by one. A Maelstrom links 8 of
  18. "My chain Warden is weak on the big packs" when it is really capped.
- *Cause:* `drift_shapes.gd:42-44,279,300`: over 48 nightmares, 6 packs of count / 6, each squeezed into
  `PACK_SPAN_MAX` 3 s (about 2.8 cells at Shade speed). Radius forms take all 18 (Bellflower's 4-cell pulse,
  Monsoon's 6). Count forms take 4-8.
- *Fix:* keep 6 big packs. Add one roster rule: **on a big pack, count caps rise by half, rounded up** (`EVENT_MAX`
  6→9, Maelstrom 8→12, Undercurrent 6→9, chains 4→6, Sparkler sparks 6→9). It applies only to nightmares carrying
  `PACK_META` in a drift where `big` is true, so it is a fact of the arrival and not of the board. The damage share
  per hit stays the same. Balancing confirms that Lightning / Storm lines stay inside the 1.5-3× leak gate.
- *Owner:* Tower Code (Maelstrom / Undercurrent / chain / spark caps), Roguelite Code (`firefly_lights.gd`
  `EVENT_MAX`), Enemy Code (exposes `is_big_pack(enemy)`), Balancing Discussion (the ×1.5).

**W2. Sporeling never gets the moment before its branches unless it took the Calling.**
- *Player feels:* Sporeling and Driftspore are single-target projectiles (`sporeling.tres`, `driftspore.tres`: no
  splash). Poisoned kills each body when its own stacks run out, so a pack melts in a staggered trickle. A
  Sporeling started without Spore Print sees no wipe until Bloomcap (branch) or Puffball (tier 3).
- *Cause:* the roster. Spore Print's mushrooms dose every walker that passes (`spore_print.gd`), which is the
  Calling's wipe. A Sporeling taken as a *second* family has no Calling.
- *Fix:* no new Warden. Two small things:
  (a) Packs walk through **Fairy Ring / Elf Circle** tiles together, so their trap is the family's natural wipe.
  Check Fairy Ring's ring cap (`warden_stats.md:196`) against a pack of 8 and raise it to fit 8 if it is lower.
  (b) Pass It Round (+3 on first application) already evens stacks across a pack. That is enough; no card changes.
- *Owner:* Tower Code (the ring cap check), Balancing Discussion.

**W3. A loose Pall covering a pack member breaks the wipe.**
- *Player feels:* a pulse clears seven; the eighth, under the cloth, survives at half and walks on alone.
- *Cause:* Pall rules (enemy_design.md "Flyers"): it covers "the nearest walker ahead", and each blow is shared half
  and half. Flyers are kept out of packs but can still fly loose in a Packs drift.
- *Fix:* **a Pall never settles on a nightmare carrying `PACK_META`** (packs and Few and tough's `TOUGH_PACK`). It
  covers loose walkers only, and if there are none it flies on.
- *Owner:* Enemy Code.

**W4. Single file is a design-breaking 143 vs ~1,000, and the single-target forms lose their shine.**
- *Player feels:* Prism Jar / Rainbow Prism, Silver / Vesper Bell, Lanternmoth / Beacon, Frostfern, Sunpetal /
  Midsummer, Lichenling / Old Lichen and Jetreed's line (a single-file corridor is its best case) get their drift
  about once in seven blocks. Area forms then win every block, which is the "one board answers all" problem coming
  back.
- *Cause:* `drift_roller.gd:127,316,536`: thinning past `SINGLE_THIN_MAX` 0.25 turns the roll into a Stream. The
  design says each shape appears once per ordinary block from act 2 (enemy_design.md "The mix").
- *Fix:* Balancing loosens it: `SINGLE_THIN_MAX` **0.25 → 0.40**, and **`SINGLE_GAP` 1.5 → 1.2 s** from act 3.
  Target: Single file within 0.8-1.2× the Packs count from act 2. If a roll still can't fit, retry Single file on
  another free drift of the block before falling back to Stream.
- *Owner:* Balancing Discussion (numbers), Enemy Code (the retry).

**W5. Status rows bury the combo read in clumps.**
- *Player feels:* in the big-pack frames each body's icons and green bar stack into a solid strip over the pack
  (`big_packs_crop_11_16.png`). Damp + Drowsy bands are how a player sees their Dewdrop / Bellflower combo landing
  before the wipe.
- *Fix:* build the approved compact pips (enemy_design.md "Status icons in crowds") before more crowding.
- *Owner:* Enemy Code, UI Code, Main Merger (as already assigned).

## 4. The owner's five questions, in Warden terms
1. **Pack sizes: keep 6-8, act 1 4-5, and 6 big packs from 48+.** 6-8 fits every count cap. Act 1 4-5 at 0.5 cell
   is about 2 cells long, so a base Dewdrop splash (0.6) takes 3 and a Bellflower pulse takes all of them. Big packs
   need W1's cap rule, not smaller packs.
2. **Lanes: keep 0.2 and the jostle.** Tighter lanes change no hits (logic stays on the centre line). If more
   bunching is wanted, the lever that matters to Wardens is the in-pack gap: **`PACK_CELLS` 0.5 → 0.4 from act 2**
   puts 4 bodies inside a 0.6 splash instead of 3, and 6 instead of 5 inside Puffball's 1.0. That is an owner call,
   because it strengthens area forms (see 5).
3. **Single file: loosen** (W4). The more wipes we add, the more single-target forms need their drift.
4. **Payoff, Warden side:**
   (a) a **"Pack cleared" beat**: when a pack id's last member is dispelled within 2 s of its first, show one word at
   the spot ("Pack cleared ×8") through CombatCallouts, throttled to one per 3 s. Owners: Enemy Code (signal
   `pack_cleared(pack_id, count, seconds, pos)`), Main Merger (callout).
   (b) **credit it to the Warden** that dealt the most damage to that pack: Warden panel "Packs cleared: N" this run.
   Owner: Main Merger (DamageLog has the per-source totals).
   (c) Sound: one rising-then-settling "release" swell on `pack_cleared`, inside audio_direction.md ("never a
   climbing chime"; the per-dispel cluster stays quieter, `sound.gd:216-219`). Owner: the Sound chat via
   `SoundHooks`.
   No damage bonus: a wipe must not pay more than its dispels.
5. **What fights it:** the Pall on pack members (W3), count caps on big packs (W1), stacked status rows (W5).
   Flyers pulled out of packs is correct for Wardens: anti-air stays a separate test. Y-sort overlap is cosmetic
   at 0.2.

## 5. Builds and Wardens: shine / suffer
- **Shine (watch for over-reward):** Bellflower pulses and the Great Bell, Monsoon, Morning Fog, Maelstrom (shared
  damage makes deaths simultaneous, the purest wipe), Puffball / Sporemother, Lantern Light Calling, Starburst.
  Dewdrop and Bellflower are already area from base, so more crowding helps them most. That is why W4 has to land
  together with any rise in Packs frequency or `PACK_CELLS` 0.4.
- **Suffer:** capped chains on big packs (W1); early Sporeling without its Calling (W2); single-target strikers if
  Single file stays rare (W4).
- No Warden loses its reason to exist.

## 6. Open questions for the owner
1. `PACK_CELLS` 0.5 → 0.4 from act 2 (tighter clumps, stronger area forms): yes or no?
2. The ×1.5 count caps on big packs (W1): accept, or keep big packs as an area-only test?
3. Should the "Pack cleared" beat carry a Warden credit line in the panel, or stay a world callout only?
