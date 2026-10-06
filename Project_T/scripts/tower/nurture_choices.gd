extends RefCounted
class_name NurtureChoices

# Nurture choices that fit every Warden (warden_stats.md "Nurture choices that fit every Warden", Tower Discussion
# 02417f32): each choice means "more of this Warden's job", and a Warden only offers the choices that do something
# for it. The per-form lists are below (a branch and its final share a row); forms not listed are attackers with
# Power · Swift · Reach · Deep. Per-rank numbers marked * in the doc are Balancing Discussion's (placeholders until
# they land). Focus values are Tower.Focus ints: NONE 0, POWER 1, SWIFT 2, REACH 3, DEEP 4, WIDE 5, STRONG 6,
# KINDRED 7, KEEN 8, YIELD 9.

const P := 1  # Power
const S := 2  # Swift
const R := 3  # Reach
const D := 4  # Deep
const W := 5  # Wide
const ST := 6  # Strong
const K := 7  # Kindred
const KEEN := 8
const Y := 9  # Yield

const ATTACKER := [P, S, R, D]
const STRIKER := [P, S, R, KEEN]  # No status or effect: Deep -> Keen
const SPINNER := [P, S, KEEN]  # A fixed 8-tile spin: Reach hidden
const SUPPORT := [W, ST, K]

# Per form (by id): the choices it offers, in the order shown.
const CHOICES := {
	"sprout": [P, S, R],
	"brood_cap": [P, S, D, Y], "hatchery": [P, S, D, Y],
	"jetreed": STRIKER, "torrent": STRIKER,
	"beacon": STRIKER,
	"sunpetal": STRIKER, "midsummer": STRIKER,
	"prism_jar": [P, S, W, ST], "rainbow_prism": [P, S, W, ST],
	"thrum": STRIKER, "resonance": STRIKER,
	"hushbell": [R, D, P], "silence": [R, D, P],
	"dreamcatcher": [R, D, P], "great_dreamcatcher": [R, D, P],
	"echo_hollow": [R, D, P], "whispering_hollow": [R, D, P],
	"pebbling": STRIKER, "mossback": STRIKER, "boulderback": STRIKER, "standing_stone": STRIKER, "moonstone": STRIKER,
	"cairn": STRIKER, "rockslide": STRIKER, "whetstone": STRIKER, "edgestone": STRIKER,
	"rampart": SPINNER, "bastion": SPINNER,
	"tangleroot": [S, R, D], "snugroot": [S, R, D],
	"rootcurl": [S, R, D], "long_way_home": [S, R, D],
	"groundroot": [S, R, D], "earthbind": [S, R, D],
	"deeproot": [R, D, P], "heartroot": [R, D, P],
	"acorn": [P, S, R, ST],
	"elder_stump": SUPPORT, "grove_heart": SUPPORT,
	"dewcatcher": SUPPORT, "wellspring": SUPPORT,
	"grandmother_oak": SUPPORT,
	"seedbearer": [Y, S, K], "grove_keeper": [Y, S, K],
	"nurse_log": [ST, W, K], "mother_log": [ST, W, K],
	"dream_oak": [Y, W], "dreamroot": [Y, W],
	"nestling": STRIKER, "wrens_nest": STRIKER, "starling_murmuration": STRIKER,
	"magpie_perch": STRIKER, "magpies_hoard": STRIKER,
	"hummingbird_bower": STRIKER, "jewelwing_court": STRIKER,
	"samara": STRIKER, "autumn_gale": STRIKER,
	"gust": [S, R, D], "zephyr": [S, R, D],
	"pinwheel": SPINNER, "windmill": SPINNER,
	"dawnwing": STRIKER, "tempest": STRIKER,
}

# One-time choices: a second rank of it does nothing (Kindred on the aura supports).
const ONCE := {"elder_stump": [K], "grove_heart": [K], "grandmother_oak": [K]}

# Per-rank numbers (Balancing Discussion, 2026-10-03).
const KEEN_CRIT := 0.10  # Crit chance per Keen rank (Balancing Discussion)
const KEEN_CAP := 0.75  # Crit chance never goes above this with Keen
const KEEN_CRIT_DAMAGE := 0.10  # Crit damage per Keen rank (Balancing Discussion, Keen / Yield probe)
# Yield (Tower Discussion, warden_stats.md 68120c18): Brood Cap / Hatchery +1 sprite alive per rank (BranchKit.brood_max_alive);
# the old sprite-interval and burst bonuses are gone (Yield beat Swift with them).
const YIELD_PER := 1  # Seedbearer: Yield ranks per extra Sprout alive (68120c18: was 2)
const YIELD_SPROUTS := 1  # Seedbearer: Sprouts alive per YIELD_PER Yield ranks
const YIELD_SHARDS := 0.5  # Dream Oak: shards per drift per Yield rank (fractions carry)
const REACH_AREA := 0.3  # Cells per Reach rank on a Warden's main area (silence, link, jet, grab, cloud, burst…)
const REACH_GUARD := 0.2  # Deeproot's guard ring, cells per Reach rank
const SWIFT_RINGS_PER := 2  # Fairy Ring: +1 ring cap per this many Swift ranks
const LINK_SHARE_CAP := 0.5  # Undercurrent: link share × Potency, up to this
const BOSS_SILENCE_FLOOR := 0.35  # Silenced bosses' timers: 0.5 × (1 / Potency), never below this
const CAUGHT_LINGER := 0.5  # Dreamcatcher: Caught statuses keep going this many seconds per Deep rank after leaving
const GUST_STACKS := 0.10  # Gust / Zephyr: copies carry half the stacks + this per Deep rank
const STRONG_CRIT_AURA := 0.02  # Prism Jar: crit aura per Strong rank
const STRONG_ACORN := 0.01  # Acorn: its aura per Strong rank
const SEED_SWIFT := 0.3  # Seedbearer: drifts sooner per Swift rank
const SEED_KINDRED := 0.06  # Seedbearer: its Sprouts' damage per Kindred rank
const NURSE_STRONG := 0.03  # Nurse Log: discount per Strong rank
const NURSE_KINDRED := 0.02  # Nurse Log: Wardens in range grow this much cheaper per Kindred rank
const WIDE_STEP := 0.2  # Wide: aura / catch / count reach per rank (Tower.FOCUS_WIDE)
const PULL_CAP := 1.5  # Rootcurl: pull distance × Potency, up to this × its base
const GROUND_CAP := 5.0  # Groundroot: grounded seconds × Potency, up to this
const NURSE_CAP := 0.40  # Nurse Log: the total Nurture discount, up to this
const SEED_MIN := 1.0  # Seedbearer: Swift never brings a seed in under this many drifts

static func options(data: TowerData) -> Array:
	if data == null:
		return ATTACKER
	return CHOICES.get(data.get_id(), ATTACKER)

static func is_once(data: TowerData, which: int) -> bool:
	return data != null and ONCE.get(data.get_id(), []).has(which)
