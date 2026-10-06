# Nurture choice audit (2026-10-05)

Owner: design hub (story chat). User: *"check all the other tower codes as well"* (after Brood Cap's Swift vs Yield overlap).
Read-only pass over `nurture_choices.gd` CHOICES, tower.gd, branch_kit.gd and the Warden data. **Tower Discussion decides**
the fixes in warden_stats.md, **Balancing Discussion** sets numbers, **Tower Code** implements. Line numbers drift.

Brood Cap is already fixed (c672b22e): Swift = hatch faster, Yield = +1 sprite alive per rank.

## Flagged
| Warden | Choice | Problem | Evidence | Suggested fix |
|---|---|---|---|---|
| Dream Oak / Dreamroot | Yield, Wide | capped: all Oaks share one 4-Dreamlight run cap; both only reach it sooner | dream_state.gd:505-510 | Yield raises the Dreamlight cap (+1 per rank) |
| Dream Oak / Dreamroot | Wide | dead ranks 1–4 (Chebyshev reach 2.0+0.2n only reaches the next ring at rank 5; family_max 3) | branch_kit.gd:1064 | +1 family_max per 2 ranks, or +0.5 reach |
| Wellspring | Kindred | near-dead past the 60-interest cap (~750 Dew banked) | dew_catch.gd:122-125 | +10 to the interest cap per rank |
| Mother Log | Strong | capped by rank 2 (NURSE_CAP 0.40) | branch_kit.gd:1003 | raise the cap for finals, or a different Strong |
| Prism Jar / Rainbow Prism, Nurse / Mother Log | Wide | dead ranks 1,2,4,5 (1.5+0.2n vs whole-cell rings) | branch_kit.gd:184, :1001 | whole-cell steps (a ring at ranks 2 and 4) or Euclidean |
| Grove Keeper | Swift | capped by rank 4 (seed floor 1.0) | branch_kit.gd:1055 | lower SEED_MIN for the final, or −0.2 per rank |
| Dewcatcher | Kindred | rounding: roundi(0.8n) → rank 3 adds nothing; text says +0.8 | tower.gd:3089 | +1 per rank, or carry the fraction |
| Graftling / Grafted Elder | Deep | dead when the copied Warden applies no status; doc's grey-out not implemented | tower.gd:875 | implement the grey-out |
| Jarlink / Lightning Fence | Swift | **bug:** only the lower-id jar runs the arc with its own speed; the panel claims it for both | branch_kit.gd:418, :91, :402 | use the pair's average or max speed |
| Jarlink / Lightning Fence | Reach | dead ranks 1–3 (Chebyshev link 4.0+0.3n reaches 5 only at rank 4) | branch_kit.gd:497 | +0.5 per rank, or +1 cell per 2 ranks |
| Sunpetal / Midsummer | Swift | dominated by Power (same number, +12% vs +18%; the ramp ignores Swift) | tower.gd:3597-3603 | Swift = faster ramp |
| Maelstrom | Deep | capped at rank 1 (link share capped 0.5); Undercurrent at rank 4 | branch_kit.gd:297 | raise the cap, or Deep = more link targets |
| Jetreed / Torrent | Power | mislabelled vs the doc: Power doesn't scale the max-health share unless the cap binds | branch_kit.gd:320 | fix the doc, or scale the share |
| Rootcurl / Long Way Home | Deep | capped at rank 2 (PULL_CAP 1.5) | tower.gd:2428 | raise the cap, or Deep = extra targets |
| Groundroot / Earthbind | Deep | capped at rank 3 (GROUND_CAP 5 s) | branch_kit.gd:871 | cap 6–7 s, or +1 ground_max |
| Hushbell | Deep | bosses only, capped at rank 2; no linger on the base form | branch_kit.gd:621 | a small linger × Potency |
| Silver / Vesper Bell, Bellflower, Great Bell | Deep | capped at rank 1 (slows floor at 50%; 5 stacks hit it at Potency 1.25) | enemy_statuses.gd:355 | Deep = longer Drowsy / sleep instead of slow strength |
| Dreamcatcher / Great Dreamcatcher | Power | near-dead (only a small shot; the catch doesn't scale; doc's Potency tick not in code) | get_caught_tick_bonus | swap Power for Wide or Strong |
| Lanternmoth | Deep | capped at rank 3 (Exposed cap 0.40) | enemy_statuses.gd:371 | Deep = longer Exposed, or swap for Keen |
| Whirligig (missing from the doc table) | Deep | dead (copies keep the original potency) | tower.gd:3836 | Gust's set: Swift · Reach · Deep (Deep = copied stacks) |
| Gust / Zephyr | Deep | partly dead on 1-stack statuses | tower.gd:3439 | fine; say it in the text |
| every form | Keen | text says +8% crit chance; code gives 10% | tower.gd:245, warden_panel.gd:528 | fix FOCUS_TEXT; Yield's fallback "makes more" is vague |

Design note: on plain projectile Wardens Swift (+12% DPS) trails Power (+18%); consider Swift ~15% or a distinct speed perk.
Smaller: Elder Stump / Grove Heart Wide skips ranks; Keen caps at 75% chance on Moonstone + Prism (crit damage still grows);
Hoarfrost's freeze is above the Hold cap, so Deep only scales Soaked.

## All fine
Sprout; the Sporeling line (Driftspore / Puffball, Inkcap / Deliquescent, Lichenling / Old Lichen, Sporemother, Bloomcap /
Dreamshroom, Fairy Ring / Elf Circle, Mistveil / Morning Fog, Brood Cap / Hatchery); Dewdrop, Rain Lily / Monsoon,
Frostfern, Tidecaller, Cloudlet / Nimbus, Undercurrent; Firefly Jar, Stormcap / Thunderhead / Stormheart, Chime Stone /
Lullaby Bell, Beacon, Sparkler / Starburst; Thrum / Resonance, Silence, Echo Hollow / Whispering Hollow; the Pebbling line;
Rootling, Tangleroot / Snugroot, Deeproot / Heartroot, Thorncoil / Crown of Thorns, Rootlight / Starcave, World Root;
Acorn, Grandmother Oak, Seedbearer; the birds, Hummingbird Bower / Jewelwing Court, Samara / Autumn Gale, Pinwheel /
Windmill, Dawnwing, The Whirlwind.
