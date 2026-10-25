# Enemy Design Council standards (collected 2026-10-24; every nightmare is checked against these)

Sources: `documentation/enemy_design.md` (Design principles, Nightmare Kinds, Bosses, Drift shapes, Walking
lanes, Flyers, Status icons in crowds, the text sections), `documentation/enemy_council_review.md` (rounds
2026-10-24, b, c), owner rules in `_common.md`. When a standard and the data disagree, report it; the owner or the
named design wins, not the file.

## A. Design (enemy_design.md "Design principles")
A1. **Tests the maze, not just the damage** (or has another clear job: a tank, a crowd, a helper), and its test
    differs from every other nightmare's in the same act.
A2. **A counter the player can own or Dream into**, and every starting family (Sporeling, Firefly Jar, Dewdrop,
    Bellflower) has some answer from its base Warden up. Hard for one build, a gift for another, never hopeless.
A3. **One clear trait**, readable in its silhouette and movement.
A4. **Menace, not gore:** how it hunts; cold, hungry, wrong; dispelling it is a small victory.
A5. **Never breaks the path rule** (the start always keeps a route). **The route is the player's plan** is a rule for Dream
    cards (no card moves, blocks or re-routes the maze on its own). Named bosses may change the maze as designed (the Hollow Stag's trample, the Hollow Oak's saplings); a new maze-changing nightmare needs the owner (corrected 2026-10-24d).
A6. **Protects the crowd feel:** nothing thins packs back to single file or makes a group wipe read as one-at-a-time.

## B. Kinds and defences (Nightmare Kinds, 2026-10-15)
B1. Exactly one **Kind** (Armoured, Flying, Hidden, Swarm, Fast, Plain) that matches what it does, with a Kind
    badge line; the Kind's answer exists in Warden tags.
B2. **No damage types:** no `resists` / `weak_to` left in data or text. **The dread shell is the only damage
    reduction** (and the Pall's shared blows, which reduce nothing); status resistances are part of its ability
    and on its card.
B3. Armoured kinds have a visible shell that chips as it breaks (`coat_*`, `cracked_frames`).

## C. Fairness
C1. Leaf cost readable and proportionate (1 normal, 2 big/elite, act boss bites 6 / 8 / 10 and leave; only the
    Hollow Oak stays and drains). A pack leak takes at most 6 leaves; a Few and tough drift's Deeply Blighted at
    most 6 together.
C2. **Flyers fly the route** (only the Phantom flies straight); flyer caps 4 / 5 / 6 by act and a third of a
    drift; Phantoms at most 4; never guaranteed / Blight elites; grounded route flyers rise onto their own route.
C3. Rolled fairly: `intro_drift` and `roll_tags` fit its job (flyers `special`; no cheap kind tagged so it can lead
    a stream of leaks); fits the drift shapes (packable or loose for a reason; Pall never on a pack member).
C4. No unfair burst: summons, splits and followers count in its budget and Dew weight.

## D. Builds and Wardens (the council's question)
D1. No build dead and no card a trap against it; dispel-count engines see a Deeply Blighted as 3.
D2. Something every Warden family can do well against it, and it doesn't make one board answer everything.

## E. Text (wording rules; text pass 2026-10-04; card text 2026-10-05)
E1. Player-facing names are the new names (`story.md` table); `{tokens}` resolve; ids are only in code.
E2. **Title line (`trait_text`) names the trait; the description (`intro_lines`) adds what the title doesn't; the
    hint repeats neither.** 1–2 intro lines, a hint present (non-bosses).
E3. Bosses: a title (no more than two bosses use "the X that Y"), 2–4 tips (a closing proverb on at most two
    bosses), a concrete defeat line, never "X is gone. Y.", abilities that read fully, a whisper.
E4. Plain words, no hand-holding ("good against X"), facts and numbers only; no stale mechanics in text (old
    damage types, old leaf costs, old names).

## F. Look (art_direction.md; Walking lanes; Status icons in crowds)
F1. Dark, cold, partly translucent; glow only in eyes or cores; one strong silhouette; Heartwood 32 palette.
F2. Lane width by its size (±0.2; big ±0.1; Single file ±0.06; flyers ±0.15); status icons compact in crowds.
F3. Placeholder art (`tint` / `sprite_scale` on a borrowed sheet) is flagged until it has its own.
