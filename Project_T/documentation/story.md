# Story — *The Heartwood Remembers*

Tone: **relaxed, cozy, gently bittersweet.** Nobody is evil. Nothing dies. The forest is sick, and
you are helping it get better.

## Premise

Deep in an old forest stands the **Heartwood**, a great tree that dreams. Its dreams take shape as
**Wardens**: sleepy moss, stone and spore spirits that doze on old waystones among the trees.

Something is wrong at the forest's edge. A grey **Blight** is creeping in, and the creatures it
touches (leaf bugs, beetles, moths, mushrooms) turn dull, confused and restless. They wander toward
the Heartwood's warmth without knowing why, and the Blight comes with them.

The Heartwood can't walk out to meet them. **It can grow, though.** Where it plants a Warden, the
ground rises into root and stone and the path bends. On the long way round, the Wardens do what they
do best: they **soothe** the Blight away.

**You play the Heartwood.** You shape the forest so every lost creature gets a long, gentle walk
past someone who can help.

## Where the Blight comes from

Far outside the forest stands the **Hollow**, an ancient tree that withered long ago, alone. Its
loneliness seeps into the soil as the Blight. It isn't malicious. It just doesn't know how to stop.

Late-game hook: through meta-progression the Heartwood learns the Hollow's story. The true ending
is not destroying the Hollow but **reaching it**: growing a path of Wardens all the way out and
keeping it company until it blooms again.

## How the mechanics fit the story

| Mechanic | In the story |
|---|---|
| Towers are walls | Each Warden roots into its waystone and the ground rises around it. |
| Placements can't fully block the path | The old forest rule: *the forest may guide, but never cage.* Every creature must still have a way through. |
| Enemies "die" | They're **cleansed**. The grey drains out, their colour returns, and they hop, flutter or scurry off happily. |
| Goal / lives | Each blighted creature that reaches the Heartwood makes a **leaf** wilt. If every leaf falls, the Heartwood goes dormant. |
| Currency (tower cost) | **Dew**. Cleansed creatures leave a drop behind as thanks. |
| Procedural map | The forest shifts while the Heartwood sleeps. No two seasons grow the same woods. |
| Waves | **Drifts**: the Blight arrives in gentle surges, like fog rolling in. |
| Upgrade every few rounds | Between drifts the Heartwood **dreams**. Pick 1 of 3 dreams: a new Warden, a stronger root, or a growth. |
| Run ends | The Heartwood drifts into dormancy and a **seed** falls. |
| Meta-progression | Seeds keep **Memories**: permanent unlocks each new Heartwood inherits (planned `HeartwoodMemory` autoload). |

## Wardens (starter roster)

- **Sporeling**: a soft, sleepy blob on a mossy slab (existing concept art). It puffs calming spores
  and is the basic attacker.
  - *Bloom*: bigger, lingering spore clouds that slow creatures.
  - *Drift*: spores that keep soothing over time and stack.
- **Mossback**: a stone tortoise with a garden on its shell. Short range, strong single soothe.
- **Lanternmoth Roost**: long range, and its glow reveals creatures hidden in Blight fog.
- **Rootcurl**: a little root spirit that gently tugs creatures back a tile. Weak alone, great in long mazes.
- **Elder Stump** *(rare dream)*: a grumpy old stump whose aura helps neighbouring Wardens.

Upgrade names: attack speed = **Quickened Sap**, damage = **Deeper Calm**, range = **Longer Roots**.

## Blighted creatures

Enemy stats stay the same; the fiction is that they're confused and lost, not hostile.

1. **Leaf Bug** *(existing sprite)*: common and quick.
2. **Bark Beetle**: slow and sturdy, with thick blight on its shell.
3. **Dusk Moth**: flutters fast and hides in fog (Lanternmoth counters it).
4. **Puffcap**: a mushroom that splits into little puffcaps when cleansed.
5. **Old Stag** *(boss drift)*: a great forest guardian, badly blighted. Cleansing it is a big, happy moment.

Visual idea: blighted creatures use a grey, desaturated `modulate` (or a shader). On cleanse, they
flash back to full colour with a sparkle, then run off the path. The same sprite covers both states.

## Flavour text samples

- Dream screen: *"The Heartwood stirs, and dreams of…"*
- Drift start: *"A grey mist gathers at the forest's edge."*
- Leaf lost: *"A leaf wilts. The Heartwood shivers."*
- Dormancy: *"The Heartwood sleeps. A seed falls, and remembers."*
- New run: *"Spring comes again."*
