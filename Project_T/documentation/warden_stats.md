# Warden Stats

Numbers for every Warden. What each one *does* and why it exists is in `tower_design.md`; status
rules are in `dream_design.md`. Rows marked **✓** are already in the game (`resource/tower/*.tres`)
and their values here are copied from there; the rest are proposals for the coding chat. Everything
is a starting point for playtesting.

## Principles

**Cost tiers (economy pass v2, 2026-09-27):** Sprout 10 → base 25–30 (Sprout + 15–20) → branch
**+80** (was 45) → final form **+200** (was 90) → **Ascended +400** (new, `tower_design.md`). A final
form costs ~310 Dew in total. **Power per tier goes up to match:** branch ≈ **2.5×** its base (was
2×), final form ≈ **3×** its branch (was 2×), Ascended ≈ 3× a final form. Existing Warden numbers
below are the pre-pass values; scale branch and final-form damage by ×1.25 and ×1.5 respectively
when applying the pass. **Nurture base costs** rise to **25 / 40 / 60 / 90 / 135** (× tier:
Sprout 0.5, base 1, branch 2, final 3, Ascended 4, Memory Warden 2).

**Dew-efficiency falls, space-efficiency rises.** Each tier is roughly **2× as strong per cell**
as the one before, but costs ~2.3× as much. Early on, Dew is what limits you, so cheap Wardens are
best; later, **space on the map** is what limits you (every Warden is a wall in the maze), so
evolving is how you keep growing. That tension is the long-run economy.

**Reference power:** a Sprout soothes 10 per second for 10 Dew. "DPS" below = soothe per second
against one creature, before statuses, auras and Dreams. Area and status effects are worth extra;
single-target Wardens get higher raw numbers to compensate.

**Ranks: Nurture** (added 2026-09-27, user request). Every attacking Warden (not Thornwall) can be
**Nurtured** up to **rank V** with Dew, from the Warden panel (group Nurture works with
multi-select; hotkey **R**).

**Nurture v2** (2026-09-27, after a playtest where "upgrading without thought" won the mid-game):
costs scale with the Warden's tier, gains per rank are smaller, and **rank III asks for a choice**.

| Rank | Base cost | Each rank adds |
|---|---|---|
| I | 15 | **+10% damage**, **+4% attack speed**, **+0.1 range** |
| II | 25 | the same again |
| III | 40 | the same again, **and choose a Focus** (below) |
| IV | 60 | the same again + the Focus bonus |
| V | 90 | the same again + the Focus bonus (230 base in total) |

**Cost × tier:** Sprout **×0.5** (115 to rank V), base **×1** (230), branch **×2** (460), final form
**×3** (690), Memory Warden **×2**. (Base costs are now 25/40/60/90/135, economy pass v2; Ascended ×4.)

**Growing a ranked Warden pays the rank difference** (changed 2026-09-28, user: "you can nurture for
less Dew, then upgrade your Warden"; was: ranks bought cheap on a Sprout carried through for free).
When a Warden with ranks grows into a higher tier, the grow cost adds, for every rank it holds,
**that rank's cost at the new tier minus its cost at the old tier** (with the current Dream
discounts). Ranks never get cheaper by being bought early.
- The Grow button shows the total and the split: *"Grow into Stormcap · 140 Dew (80 + 60 for rank
  III)"*. Unaffordable = the usual faded button with "needs 140 Dew".
- Free ranks (First Care, `free_nurtures`) pay the difference too: they were free at their tier, not
  at every tier.
- The difference counts as Dew invested (sell refunds it like any rank Dew). Group grow and the G
  hotkey use the same total.
- It applies per step (Sprout → base, base → branch, branch → final, final → Ascended).
- **Don't let it trap players** (2026-09-29: the balance bot nurtured branches, then found their
  final form cost 300+ Dew and never grew one; a new player can fall into the same trap). The
  **Nurture button's tooltip shows what a rank adds to the Warden's next growth** when that growth is
  unlocked or unlockable: *"+60 when it grows into Thunderhead"* (moved off the button into the
  tooltip, 2026-09-30, "less hand-holding"; the button reads just "Rank III · 60 Dew"). The total
  is the same whether you nurture before or after growing; only the timing changes, and a big
  grow price shouldn't come as a surprise. No rule change.

**Every family must carry act 1 on its own** (2026-09-29; family-opening check, each family alone to drift 25, 10 seeds: only Sporeling, Firefly Jar and Dewdrop passed; Bellflower and Whirligig 6/10, Nestling 3/10, Pebbling, Rootling and Acorn 0/10). Players can open with any unlocked family, so **every base Warden needs an act 1 damage floor of about 14 DPS** (Sporeling 14, Firefly Jar 18) while keeping its identity:
- **Acorn** (support): its base throws acorns (a real projectile, ~14 DPS) on top of its small aura; the support role grows in its branches.
- **Rootling:** its root lash pulse deals ~12 DPS in its area (was ~6); holds and pulls stay in the branches.
- **Pebbling:** its pebble **skips on** to a second nightmare within 1 cell at 50% (a skipping stone), and fires faster with less per shot (~24 damage at 0.75/s ≈ 18 DPS), so early swarms aren't wasted overkill.
- **Bellflower, Whirligig, Nestling:** raised to the same floor (tune damage or rate; keep their shapes).
Target: each family reaches drift 25 alone in **≥ 8 of 10** runs, like the starting three. Tower Code tunes the exact numbers against the opening check. **Status 2026-09-29:** 7 of 9 pass; **Pebbling (3/10) and Whirligig (7/10)** die at 22–24, close misses: small further bumps (about +15% damage each) until they pass. Acorn and Whirligig pass but bleed 9–16 leaves: fine for harder families. **Rerun:** Pebbling fell to 1/10 after its bump: the real cause was that **2 of act 1's 4 types resisted stone** (Husk, Night Hound). Fix (user-approved): the **Husk now resists water** instead (`enemy_design.md`), and **Pebbling's base pebble gets a small splash** (0.5 cells, 40%) for swarms, on top of its skip.

**Sprouts cost more, walls do the maze** (2026-09-30, user: *"I'm not using the mazing and walls
well … maybe increase Sprout costs as well; I still spam Sprouts"*; their run history: **59 Sprouts**
after taking Seedfall at drift 15, the maze built of Sprouts, not Thornwalls):
- **Base Sprout 10 → 12 Dew, and every 5 Sprouts on the map add +4** (was +3): 12, 16, 20, 24…;
  40 Sprouts ≈ 44 each. A Thornwall stays **3 Dew**, so a wall is a quarter of a Sprout: walls build
  the maze, Sprouts are placed where they can hit.
- **Seedfall no longer freezes the price:** Sprouts start at **8** and rise **+2 per 5** (half speed).
  Still the door to the swarm build, never an unlimited one.
- Tooltip, "↑" tag and first-rise toast follow the new numbers.
- Watch: the bot's Sprout style and the next human runs (Sprout count by drift 25 / 50, Thornwalls
  planted, path length).

**Sprouts get pricier as you plant** (2026-09-28, user-approved after the first balance batch: a Sprout swarm on a fresh profile was 1.6× the Balanced style with no Sprout cards at all). **Every 5 Sprouts on the map add +3 Dew** to the next Sprout's price (10 for the first 5, then 13, 16, 19…; 40 Sprouts ≈ 34 each). The balance batch (1a4d494) showed +5 per 5 left a Seedfall-less Sprout maze at ×0.20 of Balanced (stalled at ~20 Sprouts, dead by drift 13), so it settled at +3 (2026-09-29). History: +1 per Sprout (too much), then +1 per 5 (user: "very minimal, didn't feel like it changed anything", a run without Seedfall), then this, the user's own suggestion (2026-09-29). Walls should be Thornwalls; Sprouts are the flexible attacker. Selling or growing a Sprout lowers it again. **Seedfall** opens the swarm build: Sprouts cost a **flat 6 and the price never rises** (2026-09-29; balance batch 62af1fd: the swarm at ×1.05 of Balanced, where half-speed rising added nothing). The Warden bar shows the current price. Sprouts planted for free (Seedling Gift charges) don't add to the price. **The rule is shown** (2026-09-30, user: "should have information the Sprout costs more the more you plant"): the Sprout button's tooltip reads *"Sprout · 13 Dew. Every 5 Sprouts on the map add +3 Dew to the price (next rise at 10 Sprouts). Selling or growing one lowers it."*; the price under the button gets a small "↑" and a count to the next rise ("8/10"); the first time the price rises in a run, a one-line toast: *"Sprouts now cost 13 Dew: the more you have, the more they cost."* With Seedfall the tooltip says the price is fixed at 6.

**Branches: pricier and worth it** (2026-09-30, user: *"I want the tier 2 upgrade to be more
expensive and more worthwhile; it shouldn't be as easy to upgrade to it"*). Today a branch costs 80
Dew for only ~1.2–1.5× its base's damage (Firefly Jar 18 DPS → Stormcap ~22 before its chain;
Sporeling 14 → Driftspore 20; Dewdrop 18 → Rain Lily 28), so players grew everything cheaply.
- **Grow cost 80 → 120 Dew** (× the usual Dream discounts; the rank difference on growing still
  applies). Dreamlight unlock unchanged (1).
- **Power: about 2× its base Warden's damage per second** in its own role, counting its mechanic
  (a chain's extra jumps, a splash, a status that does damage): each branch's numbers are raised to
  that line by Tower Code, with its identity kept (Stormcap stays the chain, Mistveil the fog).
  Support branches (Elder Stump, Dewcatcher, Graftling…) get a matching jump in what they give.
- **Final forms are the big payoff** (same day, user: *"its final form should be a big payoff as
  well"*): grow cost **200 → 300 Dew** (Dreamlight unchanged, 2), power **about 2.5× its branch**
  (≈5× its base) in its role, and its **signature mechanic turned up** so it changes how the maze
  plays (e.g. Thunderhead's all-Soaked strike every 3rd strike instead of every 5th; Tower Code picks
  one lever per final and lists them). Growing into one is a moment: a bigger bloom, the Warden's
  name as a callout the first time each run, and the grow preview's "2.5×".
- **Ascended keeps its gap:** it stays about 5× an average final form (`tower_design.md`), so it
  scales up with the finals; its price goes **400 → 600 Dew** (3 Dreamlight unchanged).
- The ladder reads **25 → 120 → 300 → 600**. Nurture v3's ranks and the late Dew cut all pull on
  the same Dew: the run history decides whether income needs to ease back.
- **A branch should feel like an event:** fewer of them, each one clearly stronger on the DPS tag
  (the grow preview shows "2.1× damage"). Watch act 1 (fewer early branches) with the first boss
  sweep, and the Balanced bot's reach at 25.

**Nurture v3: every rank is a choice, no Dream gate** (2026-09-30, user after human run 1, which ended
with 9,277 Dew unspent because ranks stopped at II: *"ranks III–V for Dew … maybe for the nurture, all
levels you choose an option"*). Replaces the gate below and the fixed per-rank gains:
- **Ranks I–V are bought with Dew**, same costs (25/40/60/90/135 × tier), no Nurture Dream needed.
  Deeper Rings still opens VI–VII.
- **Every rank, you choose one** (attackers):

  | Choice | Each rank adds |
  |---|---|
  | **Power** | +18% damage |
  | **Swift** | +12% attack speed |
  | **Reach** | +0.3 range |
  | **Deep** | +18% Potency and status duration |

  Five Power ranks ≈ ×1.9 damage (the old rank V with Power was ≈ ×2.1 DPS); a mix is the point: a
  Warden's ranks read as its story ("Power, Power, Reach"). Support Wardens choose from their
  support table (below) at every rank the same way.
- **Choices are kept** through evolution and can't be changed; selling refunds as before. The rank
  difference on growing is unchanged.
- UI: Nurture (R) opens the four choices in the Warden panel (1–4 or click; each shows its effect on
  this Warden: "Power · 28 → 33 damage"). Group Nurture asks once and applies it to every selected
  Warden. The rank pips under a Warden show each rank's choice by shape/colour.
  **Playtest fix (2026-09-30**, user: *"fix the text alignment for the upgrades, and the hotkeys
  aren't working"*): the four choices were always shown with keys 1–4, which clash with the Warden
  bar's 1–4. Now:
  - The panel shows **one button, "Nurture to rank III · 50 Dew (R)"**. Pressing it (or R) opens the
    four choices in place; **while they're open, 1–4 pick** (they don't reach the Warden bar) and
    Esc / R closes them.
  - Each choice is a **three-column row**: the choice's name left-aligned, the change in the middle
    column ("14 → 17 damage"), the price right-aligned, the key badge at the far right. All four rows
    share the same column edges.
- The Nurture cards stay as boosts (Tender Care cheaper, Warm Hands +6% per rank, Sunlit Rest free
  ranks); none of them gate anything any more.
- The old "Focus at rank III" disappears; a Warden with a Focus from an old save keeps it as the
  choice for ranks III–V and Power for I–II.
- Watch in the run history: whether a few tall Wardens now beat the maze (the reason the gate
  existed). The act 2–4 health rise makes ranks a needed sink, not a shortcut.

### Nurture choices that fit every Warden (audit 2026-10-03)

User: *"make sure the Nurture makes sense on all Wardens."* A code audit of every form (Phase 1 and 2
branches included) found that the same four attacker choices were offered to every non-support
Warden, and many of them did nothing for it:
- **Deep** did nothing on about 40 forms with no status or effect damage (the whole Pebbling family,
  the birds, beams, cones, spinners), and on Beacon (its Exposed is already above the cap).
- **Swift** only sped up the basic attack. Timed abilities (holds, pulls, Mark-all), BranchKit timers
  (fence ticks, grounding, thorns, rockfall), returning birds and seeds, and patrols ignored it.
- **Reach** only changed targeting range. Fixed areas (silence, catch, fence length, jet length,
  cloud and burst radii, the goal guard, the 8 tiles around a spinner) ignored it.
- Control, setup and economy Wardens (Hushbell, Dreamcatcher, Groundroot, Deeproot, Seedbearer, Nurse
  Log, Dream Oak) had every choice only touch a 12–35 damage pulse: **five ranks for almost nothing**.
- Kindred on Elder Stump / Grove Heart only counts once; ranks 2–5 of it were wasted. The catcher
  choice texts said +1 radius / +10% catch, the code gives +0.2 / +6%.

**The rule now: each choice means "more of this Warden's job".**

| Choice | Means, for every Warden | Examples |
|---|---|---|
| **Power** | more of **all** its damage: hits, zones, arcs, thorns, rocks, links | Jarlink arc, Jetreed's max-health share |
| **Swift** | its **main cycle** runs faster: attacks, timed abilities, ticks, spawns, flights, patrols | Tangleroot's hold every 3 → 2.7 s, Groundroot's grab, birds fly and peck faster |
| **Reach** | its **main area** is bigger: range, or the area its effect covers | silence radius, catch area, fence length, cone, guard ring, cloud radius |
| **Deep** | its **effect** is stronger (Potency): statuses, effect damage, holds, pulls, linger | pull distance, grounded time, crack length, copied stacks |
| **Keen** *(new)* | **+crit chance** per rank (**+10%**, cap 75%; Balancing Discussion 2026-10-03). Replaces Deep for Wardens with no status or effect: the build-around choice for crit (Prism Jar, Pinned, Moonstone, Magpie's Hoard) | Mossback, Whetstone, the birds, Thrum |
| **Yield** *(new)* | **more of what it makes** (Balancing, 2026-10-05: **+1 sprite / Sprout alive per rank**; Dream Oak +0.5 shard per drift per rank) | Brood Cap sprites, Seedbearer Sprouts, Dream Oak shards |
| **Wide / Strong / Kindred** | supports, as before (Wide = aura/catch reach, Strong = the aura or catch, Kindred = see the table) | |

- **A Warden only shows the choices that do something for it** (3–4, a few economy Wardens 2). Each
  shows its real effect on this Warden ("Swift · holds every 3.0 → 2.7 s", "Reach · silence 2.0 →
  2.3 cells"), as the panel already does for damage.
- **Choices taken earlier stay** if a Warden grows into a form that doesn't offer them: they keep
  working where they still apply, and the pip shows them dimmed with "no effect on Silence" when they
  don't. No refunds (pre-release).
- **A one-time choice** (Kindred on aura supports) is greyed after the first rank of it: "Already
  taken: Kindred works once."
- **Walls stay un-nurtured:** Thornwall, Bramble, Honeysuckle are cheap maze pieces; their growth
  comes from Dream cards. Rampart is a Warden (a golem in the wall), not a wall, and is nurtured.
- **Grandmother Oak** (Ascended, AURA) had no ranks at all: it gets the support set.

**Per form** (branch / final share a row when they share choices; "fix" = what changes in code or
text; Balancing Discussion sets every per-rank number marked *).

| Form(s) | Role | Choices now | Verdict | Fix |
|---|---|---|---|---|
| Sprout | striker | Power · Swift · Reach | OK | no Deep (no status) |
| **Sporeling** family: Sporeling, Driftspore / Puffball, Inkcap / Deliquescent, Lichenling / Old Lichen, Sporemother | afflicter | Power · Swift · Reach · Deep | OK | — |
| Bloomcap / Dreamshroom | afflicter | Power · Swift · Reach · Deep | Reach only aimed the cloud | Reach also widens the cloud* |
| Fairy Ring / Elf Circle | afflicter (traps) | Power · Swift · Reach · Deep | Swift stalled at the ring cap | Swift also raises the ring cap (+1 per 2 Swift ranks*) |
| Brood Cap / Hatchery | afflicter (spawner) | Power · Swift · Deep · **Yield** | Reach did nothing; Swift stalled at 4 sprites | Reach → Yield. **Speed vs quantity** (2026-10-05; as first built Yield also shortened the hatch interval, so it beat Swift outright): **Swift** = hatches faster (attack speed); **Yield** = **+1 sprite alive per rank** (raises the cap of 4), nothing else. Yield is useless while the cap isn't reached, Swift is useless at the cap: a real choice |
| Dewdrop, Rain Lily / Monsoon, Frostfern / Hoarfrost, Tidecaller | afflicter | Power · Swift · Reach · Deep | OK (Deep = Soaked strength / freeze, to the caps) | text shows "Soaked +20% → +25%" |
| Mistveil / Morning Fog | afflicter | Power · Swift · Reach · Deep | Reach only aimed | Reach also widens the fog* |
| Cloudlet / Nimbus | afflicter | Power · Swift · Reach · Deep | Deep only touched Soaked | rain damage becomes effect damage (tag `rain`), so Deep scales it |
| Undercurrent / Maelstrom | afflicter | Power · Swift · Reach · Deep | Deep did nothing | `linked` damage becomes effect damage: Deep raises the link share (25% × Potency, cap 50%*) |
| Jetreed / Torrent | striker | Power · Swift · Reach · Keen | Power missed the max-health share; Reach missed the jet; Deep nothing | Power also scales the max-health share; Reach lengthens the jet*; Deep → Keen |
| Firefly Jar, Stormcap / Thunderhead, Stormheart, Lanternmoth, Chime Stone / Lullaby Bell, Great Bell, Bellflower, Silver Bell / Vesper Bell | afflicter | Power · Swift · Reach · Deep | OK | Stormcap: Reach also lengthens chain jumps* |
| Beacon | afflicter | Power · Swift · Reach · **Keen** | Deep did nothing (Exposed above the cap); Swift missed Mark-all | Swift also speeds Mark-all; Deep → Keen |
| Sparkler / Starburst | afflicter | Power · Swift · Reach · Deep | Reach only aimed | Reach also widens the burst* |
| Jarlink / Lightning Fence | afflicter (fence) | Power · Swift · Reach · Deep | Swift and Reach did nothing | Swift = the arc ticks faster; Reach = longer link range (4 → +0.3 per rank*) |
| Sunpetal / Midsummer | striker (beam) | Power · Swift · Reach · Keen | Deep nothing | Deep → Keen |
| Prism Jar / Rainbow Prism | hybrid support | Power · Swift · **Wide · Strong** | its job (the crit aura) took no ranks; Deep nothing | Wide = aura reach; Strong = +crit aura per rank* |
| Thrum / Resonance | striker (cone) | Power · Swift · Reach · Keen | Deep nothing | Deep → Keen |
| Hushbell / Silence | control | Reach · Deep · Power | every choice only touched its pulse | Reach = silence radius; Deep = silenced bosses' timers slower (× Potency, cap*) and Silence's linger longer; Swift removed |
| Dreamcatcher / Great Dreamcatcher | setup | Reach · Deep · Power | Swift / Power only touched a 13–24 shot; Deep nothing | Reach = catch area (works); Deep = Caught statuses keep going 0.5 s per rank* after leaving (Great: also its +25% tick × Potency); Swift removed |
| Echo Hollow / Whispering Hollow | setup | Reach · Deep · Power | Swift only touched the pulse | Swift removed |
| Pebbling, Mossback / Boulderback, Standing Stone / Moonstone, Cairn / Rockslide, Whetstone / Edgestone | striker | Power · Swift · Reach · Keen | Deep nothing | Deep → Keen |
| Old Mountain | striker | Power · Swift · Reach · Deep | OK (Deep = its freeze) | — |
| Quaker / Earthshaker | striker | Power · Swift · Reach · Deep | Deep nothing | Deep = the reveal and the crack last longer (× Potency) |
| Rampart / Bastion | striker (spin) | Power · Swift · Keen | Reach and Deep nothing; Swift missed the rockfall | Reach hidden (fixed 8 tiles); Swift also speeds the rockfall; Deep → Keen |
| Rootling | afflicter | Power · Swift · Reach · Deep | OK (Deep = its hold) | — |
| Tangleroot / Snugroot | control | Swift · Reach · Deep | Swift missed the hold; Power only the pulse | Swift = the hold cycle; Power removed |
| Rootcurl / Long Way Home | control | Swift · Reach · Deep | Swift missed the pull; Deep nothing | Swift = the pull cycle; Deep = pull distance × Potency*; Power removed |
| Groundroot / Earthbind | control | Swift · Reach · Deep | everything only touched the pulse | Swift = the grab cycle; Reach = grab reach; Deep = grounded time (+ Earthbind's landing hold) |
| Deeproot / Heartroot | control | Reach · Deep · Power | only Deep worked | Reach = the guard ring (3 cells +0.2 per rank*); Power = its pulse; Swift removed |
| Thorncoil / Crown of Thorns | afflicter | Power · Swift · Reach · Deep | Swift missed the thorns | Swift = the thorn tick |
| Rootlight / Starcave | control | Power · Swift · Reach · Deep | Deep nothing on Rootlight | Deep = lit tiles stretch holds more (+50% × Potency) |
| World Root | control | Power · Swift · Reach · Deep | OK | — |
| Acorn | striker + aura | Power · Swift · Reach · **Strong** | the aura took no ranks; Deep nothing | Deep → Strong (+1% aura per rank*) |
| Elder Stump / Grove Heart | support | Wide · Strong · Kindred | Kindred ranks 2–5 wasted | Kindred is one-time (greyed after) |
| Dewcatcher / Wellspring | economy (catcher) | Wide · Strong · Kindred | texts wrong | texts: "+0.2 catch radius", "+6% catch" |
| Graftling / Grafted Elder | support (copy) | Power · Swift · Reach · Deep | works through the copied Warden | Deep greyed "its copy applies no status" when so |
| Grandmother Oak | support | Wide · Strong · Kindred | no ranks at all | gets the support set |
| Seedbearer / Grove Keeper | economy | **Yield** · Swift · Kindred | everything only touched the pulse | Yield = +1 Sprout alive per rank*; Swift = a seed sooner (−0.3 drifts per rank*); Kindred = its Sprouts +6% damage per rank* |
| Nurse Log / Mother Log | economy | Strong · Wide · Kindred | everything only touched the pulse | Strong = +3% discount per rank*; Wide = +0.2 radius; Kindred = Wardens in range also evolve 2% cheaper per rank* |
| Dream Oak / Dreamroot | economy | **Yield** · Wide | everything only touched the pulse | Yield = more shards per drift*; Wide = families counted from further (+0.2 per rank) |
| Nestling, Wren's Nest / Starling Murmuration, Magpie Perch / Magpie's Hoard | striker | Power · Swift · Reach · Keen | Deep nothing | Deep → Keen |
| Hummingbird Bower / Jewelwing Court | striker | Power · Swift · Reach · Keen | Swift did nothing (waits for birds) | Swift = faster pecks and flight; Deep → Keen |
| Samara / Autumn Gale | striker | Power · Swift · Reach · Keen | Swift did little (waits for the seed) | Swift = the seed flies faster; Reach = longer throw*; Deep → Keen |
| Gust / Zephyr | setup | Swift · Reach · Deep | Power and Deep did nothing | Deep = copies carry more stacks (half → +10% per rank*); Swift also speeds Zephyr's gale; Power removed |
| Pinwheel / Windmill | striker (spin) | Power · Swift · Keen | Reach and Deep nothing | Reach hidden; Deep → Keen |
| Dawnwing, The Whirlwind | striker (patrol) | Power · Swift · Reach · Keen | Swift did nothing | Swift = faster patrol / strikes; Deep → Keen |
| Thornwall, Bramble, Honeysuckle | wall | — | — | not nurtured (unchanged) |
| Whirligig (base, parked in Phase 3) | setup | Swift · Reach · Deep | missing from this table; Deep did nothing | Gust's set (Deep = copied stacks) |

### Nurture audit fixes (2026-10-05)

The design hub audited every choice against the code (`nurture_audit.md`, 0422a3bc): 22 rows were
dead on some ranks, capped early, dominated or mislabelled. Three **rules** fix most of them, so new
Wardens don't repeat the faults:

1. **Areas grow smoothly.** Every area a Nurture choice widens is measured as the **distance from the
   Warden's centre to each cell's centre** (like range), never in whole-cell rings. With rings, +0.2
   or +0.3 per rank only reached the next ring every 3–5 ranks, so the ranks between did nothing
   (Prism Jar, Nurse Log, Elder Stump / Grove Heart, Dream Oak, Jarlink's link range). With distance,
   nearly every rank adds cells, and the panel shows how many ("+2 cells"). **Base radii of 2 or more grow by +0.5** (2026-10-05, as built d3cd75c3) so the switch only trims the far corners of the old squares: Grove Heart 2 → 2.5, Dream Oak 2 → 2.5, Jarlink link 4 → 4.5. Radius 1.5 (the 8 around) is unchanged.
2. **No choice hits its cap before rank V.** A cap is set at what five ranks of that choice reach
   (Potency ×2.25, or five steps). Balancing Discussion re-sets the caps that bound at ranks 1–4.
3. **Past a strength cap, Potency lengthens.** A status whose strength is capped (Exposed 40%, Soaked
   40%, and Drowsy, whose slow meets the slow floor) turns the rest of its applier's Potency into
   **duration**. Drowsy simply lengthens with Potency (its per-stack slow stays), since the floor binds
   almost at once.

**Per row** (* = Balancing Discussion sets the number):

| Warden | Choice | Problem | Decision |
|---|---|---|---|
| Bellflower, Silver / Vesper Bell, Great Bell | Deep | capped at rank 1 (slow floor) | rule 3: Deep **lengthens Drowsy** (× Potency) |
| Lanternmoth | Deep | capped at rank 3 (Exposed 40%) | rule 3: past the cap, longer Exposed |
| Maelstrom (Undercurrent too) | Deep | link share capped at rank 1 (Undercurrent rank 4) | Deep = **+1 linked nightmare per rank** (6 → 11, Maelstrom 8 → 13*); the share is fixed |
| Rootcurl / Long Way Home | Deep | pull capped at rank 2 | Deep = **more pull per rank**, added, no cap (Balancing: Rootcurl +0.2 → 2.0, Long Way Home +0.5 → 6.5) |
| Groundroot / Earthbind | Deep | grounded time capped at rank 3 | rule 2: grounded 3 s × Potency, cap 6.75 s* |
| Hushbell / Silence | Deep | bosses only, capped at rank 2 | Deep = **silence lingers** +0.4 s per rank* after a nightmare leaves (Hushbell too); the boss slow floor stays 0.35 |
| Jarlink / Lightning Fence | Swift | **bug:** only one jar's speed counted | the arc ticks at the **average** of the pair's speeds, so nurturing either jar helps; the panel shows the pair's new tick |
| Jarlink / Lightning Fence | Reach | dead ranks 1–3 | rule 1 |
| Sunpetal / Midsummer | Swift | dominated by Power (the ramp ignored it) | Swift = **the beam ramps faster** (+12% ramp speed per rank*) |
| Jetreed / Torrent | Power | didn't scale the max-health share | **Power scales the share too**, as designed (the code follows the doc) |
| Dreamcatcher / Great Dreamcatcher | Power | near-dead (a small shot) | Power → **Strong**: Caught statuses tick **+10%** per rank (Balancing; Great's +25% adds) |
| Graftling / Grafted Elder | Deep | dead when the copied Warden has no status | build the grey-out: "its copy applies no status" |
| Prism Jar, Nurse Log, Elder Stump / Grove Heart | Wide | dead on alternate ranks | rule 1 |
| Mother Log | Strong | capped by rank 2 (discount cap 40%) | rule 2: Balancing re-sets base and cap so five Strong ranks reach it* |
| Grove Keeper | Swift | capped by rank 4 (seed floor) | Swift = **−0.2 drifts per rank** (2 → 1.0 at V) |
| Wellspring | Kindred | near-dead past the interest cap | Kindred also raises the interest cap **+10 per rank** |
| Dewcatcher | Kindred | rounding made rank 3 add nothing | carry the fraction (+0.8 Dew per rank, paid as it adds up) |
| Dream Oak / Dreamroot | Yield, Wide | both only reached the shared 4-Dreamlight cap sooner; Wide dead ranks 1–4 | **Yield** also raises the run cap +1 Dreamlight per rank* (Balancing may trim the shard rate); **Wide**: rule 1 |
| Gust / Zephyr | Deep | little on 1-stack statuses | fine; the text says "more stacks copied (statuses with stacks)" |
| every form | Keen / Yield text | Keen said +8% (code 10%); Yield's fallback "makes more" was vague | fix FOCUS_TEXT; every Yield line names what it makes |

**Swift vs Power on plain strikers:** Swift's +12% trails Power's +18%, and on a Warden with nothing
on-hit it's simply worse. Swift still wins wherever hits carry something (statuses, crit rolls,
Reactions, cycles of abilities), so it's not dead. **Proposal to Balancing Discussion: Swift +15% per
rank** (its "faster cycle" now does more work than raw damage, and the ×1.45 attack speed at rank V
stays inside the timers' cooldowns). **Decided: Swift +15%** (Balancing Discussion, 22aa03f9). Mother Log's discount cap 50%, Nurse Log 40%; Sunpetal ramp +15% per Swift rank; Dream Oak shard bonus trimmed to +0.3.

**(Replaced by Nurture v3 above.) Ranks III–V need a Nurture Dream** (2026-09-28, user: "the maze aspect is getting lost with a
few strong Wardens through upgrades… focusing on strong Wardens should only happen when you get the
cards for them"). Every Warden can be nurtured to **rank II**; **ranks III–V** (and Focus) open once
you own **any `nurture` card** (Tender Care and Warm Hands are Commons, opened by 30 Dew spent on
ranks, which ranks I–II provide). Deeper Rings still opens VI–VII. Until then the Nurture button
reads *"Rank III needs a Nurture Dream"*. So the default plan is **a good maze plus light ranks**,
and a tall build is a choice the cards make possible (Nurture, narrow cards, Solitude).

**Focus (chosen at rank III, kept through evolution, can't be changed):**

| Focus | Ranks III, IV and V each add | At rank V (on top of the base gains) |
|---|---|---|
| **Power** | +8% damage | +24% damage |
| **Swift** | +6% attack speed | +18% attack speed |
| **Reach** | +0.2 range | +0.6 range |
| **Deep** | +10% status strength (**Potency**) and duration | +30% |

- At rank V without Focus: +50% damage, +20% attack speed, +0.5 range ≈ **1.8× damage per second**;
  with Power ≈ 2.1×. Two identical Wardens can end up doing different jobs (a Reach Lanternmoth
  marking far ahead, a Deep Rain Lily keeping everything soaked).
- **Ranks carry through evolution:** a rank III Sporeling that grows into a Driftspore is a rank III
  Driftspore, with the same Focus.
- Ranks are **less Dew-efficient than evolving** (a branch costs 45 for ~2×; rank V on a base
  Warden costs 230 for ~1.8×), so evolving stays the better buy when a Dream allows it.
- Ranks multiply with Dream bonuses (Deeper Calm etc.). Status potency uses the ranked damage.
- Selling refunds rank Dew like any other Dew spent on the Warden.
- Shown as small pips under the Warden and in its panel ("Rank III").

**Auras of the same kind stack with falloff** (changed 2026-09-30, user: "Elder Stumps and support
Wardens should stack"; was: only the highest applied). When several auras of one kind touch a
Warden, **the strongest counts 100%, the next 50%, then 25%, 12.5%**, and so on, so the total tops
out at about **2× a single aura** (Elder Stump: +20 / +30 / +35 / +37.5%… cap ≈ +40%; Acorn: +5 /
+7.5 / +8.75%… ≈ +10%). A **Kindred**-focused aura (see *Support Wardens and Nurture* below) always
counts 100% and isn't part of the falloff. **Different aura kinds** (Acorn, Elder Stump, Grove
Heart, Grandmother Oak) still stack fully with each other. Full stacking was rejected: four stumps
around one attacker would give +80% and make a stump checkerboard the best build. The Warden panel
shows it: *"Elder Stump ×3: +35% attack speed"*. **Watch:** *The Quiet Ones* and *Hedgerow Roots*
multiply this; if support clusters run away, lower the cap (≈1.75× a single aura) or make Kindred
count 75%.

**Potency** (rules in `tower_design.md`, "Potency: effect damage"): every Warden is **100%** unless
listed. It multiplies the effect damage of the statuses it applies and the Reactions it completes.

| Warden | Potency | Why |
|---|---|---|
| Driftspore | 115% | the poison specialist |
| Puffball | 130% | pops are its whole job |
| Mistveil, Morning Fog | 115% | fog is where effects land hardest |
| Thunderhead | 115% | Thunderclap engine |
| Chime Stone, Lullaby Bell | 110% | Static set-off |
| Elf Circle | 115% | spore traps |
| Echo Hollow, Whispering Hollow | 120% | echoes are pure effect damage |
| Rockslide | 110% | rubble |

**Crits** (rules in `tower_design.md`): every attacking Warden has **5% crit chance, ×2** unless
listed below. Average damage with crits = DPS × (1 + chance × (multiplier − 1)), so the default
adds +5%. Clouds, fog, Spored, Static bolts and Puffball pops never crit.

| Warden | Crit chance | Multiplier | Notes |
|---|---|---|---|
| Pebbling | 8% | ×2 | |
| Mossback | 10% | ×2 | |
| Boulderback | 12% | ×2 | always crits on Drowsy (guaranteed, no roll) |
| Lanternmoth, Beacon | 10% | ×2 | |
| ✓ Midsummer | 8% | ×2 | per beam tick |
| ✓ Hoarfrost | 5% | ×2 | +20% chance vs Held (frozen) nightmares |
| **Standing Stone** | **20%** | **×2.5** | |
| **Moonstone** | **25%** | **×3** | first hit on each nightmare always crits |
| Cairn, Rockslide | 8%, 10% | ×2 | |
| Hummingbird Bower, Jewelwing Court | 5% | ×2 | rolls **per peck**; Jewelwing's every 6th peck is guaranteed |
| Samara, Autumn Gale | 5% | ×2 | rolls per pass (twice per nightmare per throw) |
| ✓ Wren's Nest | 15% | ×2 | |
| ✓ Magpie Perch | 10% | ×2 | |
| ✓ Magpie's Hoard | 15% | ×2 | each crit +1 Dew, max 15 per drift |
| Bloomcap, Dreamshroom, Mistveil, Morning Fog | — | — | clouds and fog can't crit |

## Always available

| Warden | Cost | Range | Soothe × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|
| ✓ Sprout | 10 | 2.5 | 10 × 1.0 | 10 | projectile | none |
| ✓ Thornwall | 3 | — | — | — | wall | no attack |
| ✓ Bramble | +10 | 1.25 | 6 × 1.5 | 9 (area) | pulse | soothes creatures walking beside it; **×2 vs Held** (proposed) |
| ✓ Honeysuckle | **+30** (was +10) | 1.25 | — | — | aura | nightmares beside it gain **1 Drowsy per 1.5 s** (no damage); **Drowsy from walls caps at 3 stacks** (walls slow, they don't put to sleep alone; 2026-09-30, user: "too overpowering with the slow for how cheap it was", run 2 had 35 Honeysuckles) |

## Sporeling family (spore)

| Warden | Tier | Cost | Range | Soothe × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| ✓ Sporeling | base | 25 (+15) | 2.5 | 7 × 2.0 | 14 | projectile | Spored 1 per hit (cap 8) |
| ✓ Driftspore | branch | +45 | 2.5 | 8 × 2.0 | 16 | projectile | Spored **2** per hit, cap **12** |
| Puffball | final | +90 | 2.5 | 12 × 2.0 | 24 | projectile | Spored 2 per hit, cap 12. At **10+ stacks** the target **pops**: soothes it and creatures within 1 cell for **6 × stacks**, and half its stacks spread to up to 3 nearby creatures |
| ✓ Bloomcap | branch | +45 | 2.5 | 10 × 0.5 | cloud | cloud | leaves a sleepy cloud on the path (radius 0.75, 3 s): Drowsy |
| Dreamshroom | final | +90 | 2.5 | 14 × 0.6 | cloud | cloud | bigger cloud (radius 1.0, 4 s), **2 Drowsy** per tick; at 5 Drowsy a creature **sleeps 1.5 s** (once each; bosses cap at 3 Drowsy, so they never sleep) |
| ✓ Fairy Ring *(hidden)* | branch | +45 | 2.5 | 35 per burst | trap | trap | every 2 s plants a ring on a random path tile in range (max 4, last 10 s); stepping on one: 35 damage within 0.6 cells + **Spored 2**; *Balancing 2026-10-02 (branch sweep, per Dew vs Driftspore): ~1.6× Driftspore, so burst damage 44 → 30.* |
| ✓ Elf Circle *(hidden)* | final | +90 | 3 | 60 per burst | trap | trap | every 1.5 s, max 6 rings, **rings last until stepped on**; Spored 3; *Balancing 2026-10-02 (finals sweep, damage per Dew vs Puffball): damage ×0.75 (was 1.3–1.6× in act 2, 2.1–2.4× in act 3).* |

## Dewdrop family (water)

| Warden | Tier | Cost | Range | Soothe × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| ✓ Dewdrop | base | 25 (+15) | 2.5 | 15 × 1.2 | 18 | projectile | splash 0.6; Damp |
| ✓ Rain Lily | branch | +45 | 2.75 | 18 × 1.2 | 22 | projectile | splash **1.0**; Damp **6 s** |
| Monsoon | final | +90 | 3 | 40 every 3 s | 13 to **each** creature in range | rain | soothes **every** creature in range + Damp 6 s |
| ✓ Mistveil | branch | +45 | 2.5 | 8 × 0.5 | cloud | cloud (fog) | fog on the path (radius 0.9, 4 s): Damp, and **Spored ticks +50%** inside (proposed value) |
| Morning Fog | final | +90 | 3 | 10 × 0.5 | cloud | cloud (fog) | fog radius **1.25**, 5 s: Damp that **lingers 3 s after leaving**, and Spored and Static tick **+25%** inside. *Changed 2026-09-29: no slow, no Drowsy (Bellflower's job)* |
| ✓ Frostfern *(hidden)* | branch | +45 | 2.5 | 16 × 1.0 | 16 | projectile | hits on **Damp** nightmares **freeze** them (Held 0.75 s; once per 4 s per nightmare) |
| ✓ Hoarfrost *(hidden)* | final | +90 | 3 | 26 × 1.0 | 26 | projectile | splash 0.75; freeze **1 s**; +20% crit chance vs Held. **Buffed 2026-09-28** (probe: ~1.6% share and contribution; the freeze rarely landed): each hit also adds **1 Soaked** (melting frost), so it sets up its own freeze; freeze at **2 Soaked** on the target; damage **39 → 48** (as built, be7fd06; the row's 26 predates the ×1.5 finals pass), then freeze **1.5 s** (was 1 s; rerun: ~4% share and contribution). Target ~6–8% |

## Firefly Jar family (light)

| Warden | Tier | Cost | Range | Soothe × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| ✓ Firefly Jar | base | 30 (+20) | 3 | 12 × 1.5 | 18 | projectile | Static 1 |
| ✓ Stormcap | branch | +45 | 3 | 14 × 1.2 | 17 × up to 3 | chain | chains to 3 (jump 1.5); vs Damp: **+2 jumps**, jump 2.5 |
| ✓ Thunderhead | final | +90 | 3.5 | 20 × 1.3 | 26 × up to 4 | chain | every **5th** attack strikes **every Damp creature** in range. **Proposed:** chain 4 (currently the default 3) |
| ✓ Lanternmoth | branch | +45 | 4.5 | 12 × 1.0 | 12 | projectile | Marked; **reveals** fog-hidden creatures in range |
| Beacon | final | +90 | 5 | 16 × 1.0 | 16 | projectile + pulse | every 2 s, **Marks everything** in range; its Marked is **+35%** |
| ✓ Sunpetal *(hidden)* | branch | +45 | 3.5 | 12/s, ramping | 12 → 48 | beam | ramps +25% per second on one target (max ×4); ramps **2× as fast** on Drowsy or Held |
| ✓ Midsummer *(hidden)* | final | +90 | 4 | 18/s, ramping | 18 → 90 | beam | ramps +35%/s (max ×5), 2× on Drowsy/Held; beam **also hits the nightmare right behind** its target at 50%. **Buffed 2026-09-28** (probe: ~3%): starts at **45/s** (27 → 36 in be7fd06, the row's 18 predates the ×1.5 finals pass; then +25% after a rerun at ~5–6% share) and keeps **half its ramp** for 1 s when it switches target. Target ~6–8%; *Balancing 2026-10-02 (finals sweep, damage per Dew vs Puffball): damage 68 → 170 (×2.5, after the beam fix; was 0.28×).* |

## Pebbling family (stone) — heavy hits: close, far, area

| Warden | Tier | Cost | Range | Soothe × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| ✓ Pebbling | base | 30 (+20) | 2 | 40 × 0.5 | 20 | projectile | heavy, slow |
| Mossback | branch | +45 | 1.75 | 110 × 0.4 | 44 | projectile | **×2 vs Marked** |
| Boulderback | final | +90 | 1.75 | 220 × 0.35 | 77 | projectile | splashes 50% to creatures within 1 cell; **always crits (×2) on Drowsy** |
| ✓ Standing Stone | branch | +45 | **8** (min 2) | 100 every 3 s | 33 | projectile | **+10% damage per cell** of distance beyond 3 (max +50%); crit 20% ×2.5; target priority. With crits and full distance ≈ 65 DPS. *(Was hidden; now branch B, 2026-09-27 review.)* |
| ✓ Moonstone | final | +90 | **10** (min 2) | 220 every 3.5 s | 63 | projectile | distance bonus as above; crit 25% **×3**; **first hit on each nightmare always crits**. Full distance + crits ≈ 140 DPS; *Balancing 2026-10-02 (finals sweep, damage per Dew vs Puffball): damage ×0.75 (was 1.3–1.6× in act 2, 2.1–2.4× in act 3).* |
| Cairn *(hidden)* | branch | +45 | **6** (min 2) | 60 every 2.5 s | 24 (area) | lob | lobs over walls onto the target's tile: 60 to everything within **1 cell**; crit 8% ×2 |
| Rockslide *(hidden)* | final | +90 | 7 (min 2) | 110 every 2.5 s | 44 (area) | lob | splash **1.25 cells**; the path tiles hit get **rubble**: −25% speed for 3 s; crit 10% |

## Bellflower family (song) — new 2026-09-27

Owns **Drowsy**. Chime Stone and Lullaby Bell moved here from Pebbling (numbers unchanged).

| Warden | Tier | Cost | Range | Damage × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| Bellflower | base | 25 (+15) | 2 | 10 × 1.0 | 10 (area) | pulse | every 2nd pulse: **1 Drowsy** to everything in range |
| Chime Stone | branch | +45 | 2 | 22 × 0.8 | 18 (area) | pulse | Static 1; each pulse **sets off** a Static bolt on nightmares with 3+ stacks |
| Lullaby Bell | final | +90 | 2.5 | 40 × 0.8 | 32 (area) | pulse | Static 1 + **Drowsy 1** per pulse; sets off Static like Chime Stone. **Tuned 2026-09-28** (probe: ~20% of a 12-Warden board each, vs 8% average): pulse every **1.75 s** (was 1.25 s) and sets off Static at **4** stacks (was 3); target ~12% |
| Dreamcatcher | branch | +45 | 2.5 | 10 × 1.0 | 10 | projectile | nightmares in range that are **asleep or at max Drowsy** are **Caught**: its **statuses stop wearing off** (Spored keeps ticking, Static doesn't decay, Damp / Marked / Held timers pause). *Changed 2026-09-29: was +damage taken (Marked's job)* |
| Great Dreamcatcher | final | +90 | 3.5 | 16 × 1.0 | 16 | projectile | Caught statuses tick **+25%**; sleep in range lasts **+1 s** (once per nightmare); each Caught nightmare dispelled drops a **Dreamlight shard** (10 shards = 1 Dreamlight; max 2 Dreamlight per run from shards) |
| Echo Hollow *(hidden)* | branch | +45 | 2.5 | 8 × 1.0 | 8 (area) | echo | a Reaction within range **repeats 1 s later at its echo share** (**75%**, final: Balancing Discussion 2026-10-02) on the **same nightmare** (wherever it has walked; if it was dispelled, where it died) (echoes don't echo) |
| Whispering Hollow *(hidden)* | final | +90 | 3.5 | 12 × 1.0 | 12 (area) | echo | echo share **100%** (final: Balancing Discussion 2026-10-02); each echo **counts as a chain link** |

**Echoes follow the nightmare** (changed 2026-10-02: on the same spot they missed, since nightmares
had walked on after 1 s: 1.6% of the Hollow's damage at drift 45, 0% at 61). The echo hits the
nightmare the Reaction fired on, wherever it is now, plus anything within 1 cell of it; if that
nightmare was dispelled, the echo fires where it died. **Echoes, as built (a9ba4b6):** an echo is a burst, sized from the applier's
damage × a per-Reaction factor (Thunderclap 4, Ignite 3, Shatter 2.5, Lightning Rod 6) × the echo share (final, Balancing Discussion 2026-10-02: Echo Hollow 75%, Whispering Hollow 100%).
**Hollow pulse raised** (2026-10-02): with echoes landing, Reactions are still too infrequent for
echoes to carry the Hollows (boards 0.6–0.9×), so their own pulse goes up: **Echo Hollow 10 → 22,
Whispering Hollow 18 → 50**. They stay Reaction repeaters. Drown echoes as a shorter sleep, Pinned re-primes its guaranteed
crit, Mushrooming grows a shorter cloud, and **Smother doesn't echo**.

Caught no longer adds damage (2026-09-29), so it pairs with Marked instead of stacking with it: a
Caught nightmare's Marked simply doesn't wear off. Bosses
never sleep, but their Drowsy cap is 3, and **3 counts as max for them**, so bosses can be Caught.
Caught bosses give no Dreamlight shards.

## Rootling family (root)

| Warden | Tier | Cost | Range | Soothe × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| ✓ Rootling | base | 25 (+15) | 2 | 6 × 1.0 | 6 (area) | pulse | every **4th** pulse **Holds** the nightmare furthest along for **0.3 s**. *Changed 2026-09-29: half damage (control family), Held instead of a slow* |
| Rootcurl | branch | +45 | 2 | 14 × 1.0 | 14 (area) | pulse + pull | every **4 s**, pulls the creature furthest along (in range) **back 1 tile** |
| Long Way Home | final | +90 | 2.5 | 18 × 1.0 | 18 (area) | pulse + pull | every **5 s**, pulls back **4 tiles** (since the late-game pass 54155266); each creature only once (bosses: 1 tile) |
| Tangleroot | branch | +45 | 2 | 14 × 1.0 | 14 (area) | pulse + hold | every **3 s**, **Holds** the creature furthest along for 1 s |
| Snugroot | final | +90 | 2.5 | 20 × 1.0 | 20 (area) | pulse + hold | every 3 s, Holds **up to 3** creatures for 1 s; *Balancing 2026-10-02 (finals sweep, damage per Dew vs Puffball): damage ×0.75 (was 1.3–1.6× in act 2, 2.1–2.4× in act 3).* |
| ✓ Rootlight *(hidden)* | branch | +45 | 3 | 10 × 1.0 | 10 (area) | pulse + light | lights path tiles in range: **reveals Lurkers**, **Gravecrawlers can't burrow** on lit tiles, **Held lasts 50% longer** on lit tiles (no Marked since 2026-09-29: Marked is Firefly Jar's) |
| ✓ Starcave *(hidden)* | final | +90 | 4 | 16 × 1.0 | 16 (area) | pulse + light | as Rootlight; Held lasts **twice as long** on lit tiles |

## Acorn family (support, economy)

| Warden | Tier | Cost | Range | Soothe × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| ✓ Acorn | base | 25 (+15) | 2 | 4 × 1.0 | 4 (area) | pulse | **aura:** the 8 surrounding Wardens +5% soothe. *Pulse halved 2026-09-29 (support family)* |
| Elder Stump | branch | +45 | 2 | 10 × 1.0 | 10 (area) | pulse | **aura:** the 8 surrounding Wardens **+20% attack speed** |
| Grove Heart | final | +90 | 2 | 14 × 1.0 | 14 (area) | pulse | **aura, radius 2:** +15% soothe and attack speed, **+3% more per Warden** in the radius (max +30%) |
| Dewcatcher | branch | +45 (+80 after the economy pass) | **2.5 (catch)** | 8 × 1.0 | 8 (area) | pulse | **Reworked 2026-09-29** (playtest: "+3 Dew a drift doesn't feel worth it"; it paid back in ~35 drifts after the economy pass). **Catch:** nightmares dispelled within **2.5 cells** drop **+40% Dew**, plus **+4 Dew per drift**. With about a third of dispels in range that's ~10 Dew per drift in act 1, **paying back in ~8–10 drifts**; a percentage keeps pace as Dew per nightmare falls by act. Several catchers don't stack on one nightmare (the highest applies) |
| Wellspring | final | +90 (+200 after the economy pass) | 3 (catch) | 10 × 1.0 | 10 (area) | pulse | catch **+60%** (and keeps the Dewcatcher's **+4 Dew per drift**), and at every rest **+8% of your banked Dew** (max **60** per Wellspring; all Wellsprings together max **120** per rest). Pays back in about 1–2 blocks when you save |
| ✓ Graftling *(hidden)* | branch | +45 | as copied | 60% of copied | — | copied | copies the attack (kind, range, statuses, crit) of the **highest-DPS adjacent** attacking Warden; not Memory Wardens or other Graftlings |
| ✓ Grafted Elder *(hidden)* | final | +90 | as copied | 85% of copied | — | copied | as Graftling |

**Economy Wardens and Nurture** (2026-09-29): for Dewcatcher and Wellspring, each rank adds **+10%
catch** instead of damage (rank V Wellspring: +110%). Rank costs are unchanged.

**Support Wardens and Nurture** (2026-09-30, user request). Ranks for support Wardens grow **what
they do**, not their (tiny) attack:

| Warden | Each rank (I–V) | At rank V |
|---|---|---|
| Elder Stump | its attack-speed bonus ×1.1 | +20% → **+30%** |
| Acorn | *(changed after 7996d89: the Acorn keeps **attacker** ranks and the attacker Focus; only Elder Stump and Grove Heart are pure supports)* | — |
| Grove Heart | its base bonus ×1.1 (the +3% per Warden is unchanged) | +15% → +22.5% |
| Dewcatcher, Wellspring | +10% catch (above) | +50% more catch |

At **rank III** support Wardens (Elder Stump, Grove Heart, Dewcatcher, Wellspring) choose a **support Focus** instead of Power / Swift / Reach / Deep:

| Focus | Auras (Acorn, Elder Stump, Grove Heart) | Catchers (Dewcatcher, Wellspring) |
|---|---|---|
| **Wide** | aura reach **+1 cell** (Elder Stump: the 8 neighbours become everything within 2; Grove Heart radius 3) | catch radius **+1** |
| **Strong** | the aura bonus grows a further **+25%** by rank V (on top of the ×1.1 per rank) | catch **+30%** more by rank V |
| **Kindred** | **ignores the stacking falloff:** always counts 100%, even as the 2nd or 3rd aura of its kind | Wellspring interest **+2%**; Dewcatcher **+4 Dew per drift** |

- Two Kindred Elder Stumps at rank V give **+60%** to the Wardens between them: strong, but it
  costs two cells, the rank Dew and both Focus picks. It's the deliberate way to stack.
- The strongest stacked aura (for the falloff) is the one with the highest bonus after ranks, so
  nurturing your best stump makes it the one that counts fully.
- Rank costs, "growing pays the rank difference" and the Focus rules (kept through evolution, can't
  be changed) are the same as for attackers. Walls (Thornwall, Honeysuckle) still can't be nurtured.

**Support credit** (2026-09-29): Wardens whose value isn't damage are credited with what they
*enable*, so they show up in panels and reports: auras (Acorn, Elder Stump, Grove Heart, Grandmother
Oak, the White Stag) get the extra damage their bonus caused; catchers get Dew caught and interest;
walls get path tiles added (Thornwall), damage (Bramble) or Drowsy applied (Honeysuckle). Details:
`screens_ui.md` "Support and economy feedback".

## Nestling family (wing) — full game

| Warden | Tier | Cost | Range | Damage × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| ✓ Nestling | base | 25 (+15) | 3 | 14 × 1.2 | 17 | swoop | bird flies out and back; ×1.25 vs Phantoms |
| ✓ Wren's Nest | branch | +45 | 3.5 | 8 × 3.0 | 24 | swoop | targets the **fastest** nightmare in range; ×1.5 vs Phantoms and sprinting Night Hounds; crit 15%; **each swoop also strikes a second nightmare it passes (50%)** (2026-09-29: an early multi-target tool for Nestling) |
| ✓ Starling Murmuration | final | +90 | 4 | 3 birds × 10 × 1.5 | 45 (split) | swoop | **changed 2026-09-27:** 3 starlings each hunt one of the **3 fastest** nightmares in range; ×1.5 vs Phantoms and sprinting Night Hounds; crit 15%. (Was: sweeps the 5 busiest path tiles); *Balancing 2026-10-02 (finals sweep, damage per Dew vs Puffball): damage ×1.5 (was 0.5×).* |
| ✓ Magpie Perch | branch | +45 | 3 | 12 × 1.0 | 12 | swoop | **thief** (2026-09-29): each hit strips a nightmare buff: removes **2× its normal chip** of dread shell, stops a Weeper's mending for **3 s**, removes an Omen's boosts from that nightmare; **+1 Dew** when a nightmare it stripped is dispelled; crit 10% |
| ✓ Magpie's Hoard | final | +90 | 3.5 | 20 × 1.0 | 20 | swoop | as Magpie Perch (every hit strips); **each crit +1 Dew** (max 15 per drift); crit 15% |
| Hummingbird Bower *(hidden)* | branch | +45 | 3 | 6 pecks × 4, every 1.5 s | 16 | multi-hit | pecks one nightmare 6 times in 1 s, returns in 0.5 s; **each peck is a full hit** (crit roll, Marked, on-hit cards) |
| Jewelwing Court *(hidden)* | final | +90 | 3.5 | 3 birds × 8 pecks × 6, every 1.5 s | 96 (split) | multi-hit | birds spread over targets or all focus the strongest (toggle); **every 6th peck crits** |

## Whirligig family (wind) — full game

| Warden | Tier | Cost | Range | Damage × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| ✓ Whirligig | base | 25 (+15) | 2 | 10 × 1.0 | 10 (area) | pulse | every **3 s** copies one status (half stacks) of the most-afflicted nightmare in range onto **one** neighbour within 1.5 cells. *Changed 2026-09-29: was a nudge back (pulling is Rootling's job)* |
| ✓ Gust | branch | +45 | 2.5 | 10 × 0.5 | 5 (area) | gust | every 2 s, copies all statuses of the **most-afflicted** nightmare in range onto **2** others within 1.5 cells (**half stacks**, full duration) |
| ✓ Zephyr | final | +90 | 3 | 16 × 0.5 | 8 (area) | gust | as Gust, onto **up to 5** |
| ✓ Pinwheel | branch | +45 | 1 (adjacent tiles) | 12 × 2.0 | 24 (area) | blades | hits every nightmare on the 8 tiles around it; **+20% damage per adjacent path tile beyond 2** (max +100%) |
| ✓ Windmill | final | +90 | 1 | 18 × 2.5 | 45 (area) | blades | as Pinwheel |
| Samara *(hidden)* | branch | +45 | 4 (line) | 20 per pass, ~1 throw / 1.6 s | ~25 to **each** in the line | boomerang | straight out and back through everything; each nightmare hit twice; carries the first-hit nightmare's statuses (half stacks) down the line |
| Autumn Gale *(hidden)* | final | +90 | 5 (line) | 2 seeds × 35 per pass, ~1 throw / 1.6 s | ~44 to each, two lines | boomerang | aims along the 2 lines with most nightmares; each catch +10% next-throw damage (max +50%; resets if a throw hits nothing); *Balancing 2026-10-02 (finals sweep, damage per Dew vs Puffball): damage ×0.75 (was 1.3–1.6× in act 2, 2.1–2.4× in act 3).* |

As built: Samara aims its line at its **first target**; Autumn Gale picks the **two lines through the
most nightmares**. The catch rhythm counts **per throw** (+10% if any seed hit, reset if none did),
not per seed.

## Memory Wardens (unique, from bosses): PARKED

**Cut for now (2026-09-29)**, see `tower_design.md`. The numbers are kept for a possible return.

Free, one of each per run, can't evolve or be sold for Dew (selling returns the memory: it can be
placed again at the next rest).

| Warden | Range | Damage × /s | Kind | Effect |
|---|---|---|---|---|
| ✓ The White Stag | 4 (aura) | — | aura | nightmares in range −15% speed, **+15% damage taken**; Wardens in range **+5% crit chance** |
| ✓ The Pond Keeper | 3 | 40 per grab | grab | every 4 s, pulls the nightmare **furthest along** back to the path tile nearest the pond (bosses: back 2 tiles) and makes it Damp |
| ✓ The Moon Moth | 6 | 30 × 0.8 | projectile | reveals **every Lurker on the map**; Marks what it hits; Wardens within 3 cells **+1 range** |

## New mechanics the unbuilt Wardens need

For the coding chat, in rough order of need:
0. **2026-09-27 review:** Bellflower family (`song` line; Chime Stone and Lullaby Bell move from
   Pebbling), Dreamcatcher's **Caught** state and Dreamlight shards, Echo Hollow's **Reaction
   echo**, Cairn's **lob** over walls with rubble tiles, Hummingbird's **multi-hit** (each peck a
   full hit), Samara's **boomerang** (line out and back, catch, status carry), Standing Stone and
   Moonstone no longer hidden, Starling Murmuration hunts the 3 fastest.
1. **Pulse with an effect**: slow (Rootling), Static set-off (Chime Stone), extra statuses.
2. **Pull back along the path** (Rootcurl, Long Way Home): move a creature back N cells on its
   current route; once-per-creature memory.
3. **Hold** (Tangleroot, Snugroot): the Held status (`dream_design.md`).
4. **Auras** (Acorn, Elder Stump, Grove Heart): neighbour lookup on the grid; highest-of-type rule.
5. **Economy hooks** (Dewcatcher, Wellspring): per-drift and per-rest Dew.
6. **Pop / burst** (Puffball), **sleep** (Dreamshroom), **rain** (Monsoon), **mark-all pulse**
   (Beacon), **ramping beam** (Sunpetal).
7. **Crits**: roll per hit in `Tower`, pass `is_crit` to `Enemy.take_damage`, crit flare/number.
   Cheap and cross-cutting, so it can go in early.
8. Hidden and full-game Wardens: **min range + distance bonus + target priority** (snipers),
   **traps** (Fairy Ring), **freeze** (Frostfern, reuses Held), **lit tiles** that block burrowing
   (Rootlight), **attack copying** (Graftling), **swoop** projectiles that return, **status
   copying** (Gust), **adjacent-tile blades** (Pinwheel), **unique** Memory Wardens.

## Tuning from the 2026-10-02 probe series (Balancing Discussion)

The current numbers after Balancing Discussion's overnight sweeps (every final and every branch ×4
on a fixed board, rank IV, no Dreams, damage per Dew vs Puffball / Driftspore), the follow-up
re-probes and the last step on 2ef6d56f. **Where this list and an older row in the tables above
disagree, this list wins** (the tables keep pre-pass values plus row notes). The probe series is
closed; **human runs judge from here**. Full measurements: `balance_simulation.md`.

| Warden | Change | Why |
|---|---|---|
| Autumn Gale | ×0.75, then **85 → 72** | 1.3–1.6× in act 2, 2.1–2.4× in act 3 |
| Moonstone, Elf Circle | ×0.75 | the same |
| Snugroot | ×0.75, then **56 → 48** | the same; act 3 still ~2.1× after the first cut |
| Midsummer | **68 → 170** (×2.5, after the beam fix) | was 0.28× |
| Starling Murmuration | ×1.5 | was 0.5× |
| Fairy Ring | burst **44 → 30** | ~1.6× Driftspore |
| Hummingbird Bower | **27 → 40** | 0.10× Driftspore |
| Sunpetal | **81 → 113** | 0.11× (also check beam target retention) |
| Stormcap | damage **18 → 24** | 0.22× at drifts 45–49 |
| Echo Hollow | echo share **75%** (final); pulse **10 → 22 → 28** | echoes now follow the nightmare, but Reactions are too rare to carry it |
| Whispering Hollow | echo share **100%** (final); pulse **18 → 50 → 62** | the same |
| Dreamshroom | Dream spores at **half** soothe, one puff per sleeper per second | ~2.1× Puffball per Warden |
| Deep focus | **+25% Potency** per rank (was +18%) | committed Deep builds trailed Power |
| Acorn family | **+15% attack damage** (auras unchanged) | weakest family in act 1 |

Role notes from the same series (`tower_design.md` roles): Gust, Zephyr, Echo/Whispering Hollow,
Frostfern and the support Wardens are judged by **what they add to the board** (support credit),
not by direct damage per Dew.

## To check in playtests

- Is each family roughly as strong as the others at the same Dew? (Compare Dew spent vs creatures
  dispelled per family.)
- Do players evolve when space runs out, as intended, or hoard cheap Wardens?
- Pull and Hold on bosses: fun, or trivialising? (Bosses get reduced effects.)
- Economy Wardens: does Dewcatcher pay back fast enough to be picked, without being mandatory?
