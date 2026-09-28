# Story — *Heartwood TD*

**Revised 2026-09-27: from cozy to dark fairytale.** The enemies are no longer lost, friendly
creatures; they're **nightmares**: evil spirits, ghosts and shadow things that want to devour the
Heartwood's dream. The Wardens stay warm and charming. **That contrast is the look of the game.**

## Tone

- **The dream is warm; the nightmares are cold.** Golden light, moss, gentle Warden spirits, against
  hungry, twitching, whispering shapes that come out of the dark.
- **Unsettling, not gory.** No blood or bodies. Dread comes from silhouettes, glowing eyes, wrong
  movement (jerky, gliding, too fast), whispers and silence. Think dark fairytale, not horror gore.
- **The stakes are real.** Nightmares that reach the Heartwood feed on its dream. Losing feels like
  losing something precious.
- **One gentle thread.** The source of the nightmares is sorrow (the Hollow), so the story still ends
  in healing, not destruction. The nightmares themselves are cruel; their root is sad.

## Premise

Deep in an old forest stands the **Heartwood**, a great tree that dreams. The forest *is* its
dream: every glade, stone and path. Its good dreams take shape as **Wardens**: moss, stone and spore
spirits that sleep on old waystones.

Now something is getting into the dream. From the edges of the forest come **nightmares**: shades,
wraiths, hounds and hungrier things, drifting in like fog. They don't wander; they **hunt**. They
want the Heartwood, and every one that reaches it tears a piece out of the dream.

The Heartwood can't run and can't fight. **But it can dream.** Where it plants a Warden, the ground
rises into root and stone and the path bends. The nightmares must take the long way round, past
Wardens that glow, spark and sing them back into nothing.

**You play the Heartwood.** You shape the dream into a maze and make sure nothing reaches its heart.

## Where the nightmares come from

Far outside the forest stands the **Hollow**, an ancient tree that withered long ago, alone. Its
grief didn't fade. It **festered** into nightmares, and they are drawn to the one tree that still
dreams warmly, because they want what it has.

The nightmares are cruel. The Hollow is not; it's broken. Through meta-progression the Heartwood
learns its story, and the **true ending** is not destroying the Hollow but **reaching it**: growing
a path of Wardens all the way out through its nightmares and ending its grief.

## How the mechanics fit the story

| Mechanic | In the story |
|---|---|
| Towers are walls | Each Warden roots into its waystone and the dream-ground rises around it. |
| Placements can't fully block the path | The old rule of the dream: *a dream can bend, but never close.* A sealed dream breaks, so every path must stay open. |
| Enemies die | Nightmares are **dispelled**: they shriek, crack apart into motes of light and are gone. |
| Goal / lives | A nightmare that reaches the Heartwood **feeds on the dream**: a leaf blackens and falls. If every leaf falls, the Heartwood sinks into dreamless sleep. |
| Currency (tower cost) | **Dew**: dispelled nightmares break into light, which settles on the leaves as Dew. |
| Procedural map | The dream reshapes itself each night. No two nights grow the same forest. |
| Waves | **Drifts**: nightmares come in surges, like fog rolling in. |
| Upgrade every few drifts | At each rest the Heartwood **dreams**: pick 1 of 3 Dreams. |
| Warden families from bosses | Dispelling a great nightmare frees a memory the Heartwood had lost: a new Warden family, **or the memory the nightmare was wearing** (a Memory Warden, below). |
| Tower evolution | Sprouts grow into what the Heartwood has dreamed of, where they stand. |
| Run ends | The Heartwood sinks into dreamless sleep, and a **seed** falls. |
| Meta-progression | Seeds keep **Memories**: permanent unlocks each new Heartwood inherits. |

## Names (use these everywhere)

| Old (cozy) name | New name | What it is |
|---|---|---|
| blighted creatures | **nightmares** | the enemies |
| cleanse / cleansed | **dispel / dispelled** | defeating one |
| soothe (as damage) | **damage** in stats; Wardens *dispel* in the fiction | |
| Leaf Bug | **Shade** | small shadow spirit, the common one |
| Bark Beetle | **Husk** | a dead shell of bark with something inside it; slow, tough |
| Puffcap / Puffcaplet | **Mourner** / **Sob** | veiled ghost that breaks into 3 Sobs |
| Dusk Moth | **Lurker** | unseen until revealed |
| Dandelion Seed | **Phantom** | passes through walls |
| Mole | **Gravecrawler** | sinks into the ground under a wall |
| Hedgehog | **Night Hound** | sprints down straight paths |
| Mother Duck + Ducklings | **Lantern Bearer** + **Wraiths** (a **Procession**) | a ghost with a lantern, leading wraiths |
| Wandering Hare | **Sleepwalker** | wanders into dead ends |
| Tortoise | **Barrow Wight** | ancient, slow, can't be held |
| Newt | **Drowned One** | always soaked, ignores slows |
| Owl | **Watcher** | many-eyed, never sleeps, wakes others |
| Snail | **Ash Crawler** | leaves burning ash |
| Glowworm | **Will-o'-Wisp** | a treacherous light that reveals Lurkers |
| Mother Spider | **Widow** | bursts into Creeps |
| Badger | **Shellbound** | armoured in hardened dread |
| Bee Swarm | **Whisper Swarm** | a cloud of whispering motes |
| Squirrel | **Dream Thief** | steals Dew |
| Mossling | **Weeper** | its tears mend other nightmares |
| Old Stag | **The Hollow Stag** | boss: gaunt, antlered, ghost-fire |
| Great Toad | **The Mire Hag** | boss: bog witch |
| Mother Moth | **The Moth Queen** | boss |
| The Hollow Oak | **The Hollow Oak** | final boss: the Hollow's corrupted heart |

Unchanged: Heartwood, Wardens (all names), Dew, leaves, drifts, Dreams, Seeds, Memories, Omens, the
Blight (the dark rot nightmares carry; Blight Levels, Deeply Blighted elites).

**Status display names** (decided 2026-09-28; code ids and older design docs keep the internal names):

| Internal name (code, older docs) | Player-facing name |
|---|---|
| Damp | **Soaked** |
| Drowsy | **Drowsy** (kept: it builds up to **Asleep**; "Slowed" read the same as Soaked) |
| Spored | **Poisoned** |
| Marked | **Exposed** |
| Static | **Charged** |
| Held | **Rooted** |
| Caught, Frozen | unchanged |

The game's title is **Heartwood TD** (decided 2026-09-28).

## Wardens

Every Warden starts as a **Sprout**, a small bright shoot, and grows into what the Heartwood has
dreamed of (full tree in `tower_design.md`). Wardens are the **warm, cute side** of the contrast:
their light, sparks, rain and song are what the nightmares fear. The Sporeling (the purple spirit on
its mossy slab) is the mascot.

The Heartwood's families: **Sporeling** (spores), **Pebbling** (stone), **Dewdrop** (water),
**Firefly Jar** (light), **Rootling** (roots), **Bellflower** (bell-flower spirits that sing
nightmares to sleep and catch them in dreamcatchers), **Acorn** (support), and in the full game **Nestling**
(birds that swoop out and back) and **Whirligig** (maple-seed spinners that carry other Wardens'
magic further). Each has hidden branches the Heartwood only remembers later (Grove unlocks, e.g.
Sunpetal, Fairy Ring, Frostfern). **Thornwall** hedges can grow into Brambles or **Honeysuckle**,
whose sweet scent makes nightmares drowsy.

### Memory Wardens: what the great nightmares stole

The great nightmares aren't born from nothing. **Each one wears a good dream it stole and twisted.**
Dispelling it breaks the twist, and the dream underneath comes back as a unique **Memory Warden**
(one per run, can't evolve; `tower_design.md`):

| Great nightmare | The memory underneath |
|---|---|
| The Hollow Stag | **The White Stag**: the forest's old guardian, whose presence slows nightmares |
| The Mire Hag | **The Pond Keeper**: an old toad spirit who pulls nightmares back into its pond |
| The Moth Queen | **The Moon Moth**: its light reveals everything hiding in the dark |
| The Hollow Oak | none: its memory is the Hollow itself, and freeing it is the true ending |

This is the story's hope in miniature: under every nightmare is something that was once loved. It
also foreshadows the ending: the Hollow Oak is the Hollow's own dream, twisted the same way.

Upgrade names: attack speed = **Quickened Sap**, damage = **Deeper Calm**, range = **Longer Roots**.

## Nightmares

Full roster and mechanics in `enemy_design.md`; stats in `acts_1_2.md`. Art direction for all of
them:
- **Dark, cold, partly translucent**, with a soft glow only in the eyes or core.
- **Wrong movement:** gliding without walking, twitching, stopping and starting, heads that turn.
- **Readable at a glance:** each has one strong silhouette tied to its trait (the Hound's long
  stride, the Phantom's trailing veil, the Lantern Bearer's light).
- **Dispel:** a short shriek or hiss, the shape cracks with light, and it bursts into motes that
  drift up and settle as Dew.

## Flavour text samples

- Drift start: *"Something moves at the edge of the dream."*
- Leaf lost: *"It fed. A leaf blackens and falls."*
- Boss arrives: *"The Hollow Stag has found the dream."*
- Dormancy: *"The Heartwood sinks into dreamless sleep. A seed falls, and remembers."*
- New run: *"The Heartwood dreams again."*
