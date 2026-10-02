# Asset Galleries

Every asset chat keeps **one living gallery artifact** of the art it owns and republishes it (same
URL) in the same turn as every asset commit (user, 2026-09-30: *"let all the asset chats create an
updated artifact that they keep updating every change; this chat references those artifacts"*).
The design chat reads these before making art calls; this page is the index.

Each gallery shows every current asset (animated where it animates, 1× and 3× for pixel art), its
name, file path, size and frame count, its status (final / placeholder / in progress), and a "What
changed" log at the top (date, commit, what), newest first.

## Gallery layout standard (2026-10-02, user: *"make sure all the artifact files are organized well when being updated"*)

Every gallery follows the same structure, so any page reads the same way:

1. **Header:** gallery name, owner chat, last updated (date + commit), a one-line summary of the latest change.
2. **What changed:** newest first, at most the last 10 entries visible (older ones under a collapsed "Older changes").
3. **Contents bar:** jump links to every section, plus a search / filter box (by name, status, family).
4. **Sections in a fixed order:** grouped by game area (e.g. Wardens by family → base, branches, finals, Ascended; nightmares by act; environment by act → tiles, obstacles, features, dream layer). Within a section, alphabetical, or in game order where that is clearer (base → branch → final).
5. **One card per asset:** preview (animated where it animates, 1× and 3×), name (player-facing name first, file id second), file path, size / frames, status badge (**Final · Placeholder · In progress · Experimental**), and the commit that last changed it.
6. **Experimental work is kept apart:** art that exists only on a branch (e.g. `experiment/spire-difficulty`) sits in its own clearly labelled section ("Spire branch, not in the main game"), never mixed into the main sections.
7. **Superseded art** moves to a collapsed **Archive** section at the bottom (with what replaced it), never deleted silently, never left beside the current version.
8. **No duplicates:** one card per file; a renamed asset updates its card, not a second one.
9. **Same URL every time:** republish over the existing artifact; never a new page for an update.

| Chat | Owns | Gallery |
|---|---|---|
| Tower Assets | Warden idle/attack sheets, Ascended, projectiles, effects, rank art | https://claude.ai/artifact/N8Jax8F4EWtdkoznbUMf42 |
| Enemy Assets | nightmare sprite sheets, bosses, Thorn-Sapling | https://claude.ai/artifact/YUa3SG93MgF6JhJ2reGhn3 |
| Environment Assets | per-act environment sheets + dream-layer sheets (`assets/environment/`) | https://claude.ai/artifact/V4QRayu3d7ckStH2btwvGQ |
| Theme Asset | style references (`assets/style_reference/`), Warden Night | https://claude.ai/artifact/1Mq111zHWpf3EbgsWwF6d8 (whole-look overview: https://claude.ai/artifact/34adEMHN6xJNnMXPK7ziWq) |
| UI Asset | icons (`assets/ui/icons.png`), Clear tool frames | https://claude.ai/artifact/3PZKNfNnBtBTzMouyqyDPN (style concept page: https://claude.ai/artifact/4Cs1PP2CrqTjth2dHiZFow) |
| Meta Game Asset | Memory Grove art (`assets/meta/`); the 10 Memories are placeholders | https://claude.ai/artifact/Buk9SDW2NhCo32BZgRX6Sp |
| Title Screen | title screen art and layers (`assets/ui/title/`) | https://claude.ai/artifact/CJTTD5Y43kdDHM5gSfj6Bc |

**Hub** (everything in one page, kept by the design chat): https://claude.ai/artifact/RHpbqXJJnzQBBpUxyBpabv. Design-chat pages: Dream card audit https://claude.ai/artifact/K1EBiyXPeJdbjVL2ByyZQW.
