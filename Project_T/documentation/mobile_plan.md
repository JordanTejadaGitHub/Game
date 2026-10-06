# Mobile plan (2026-10-06)

Owner: design hub (story chat). User: *"I feel like we can turn this into a mobile game"*, then *"we can do that"* (the
free-to-try + one unlock model). Engine stays **Godot** (Android and iOS exports). Steam stays; mobile is a second
platform, possibly launched first.

## Business model
- **Free to try, one purchase unlocks the full game.** The free tier is the demo (`game/demo`: acts 1–2, the 4 demo
  families, the Grove teaser, the "Full game" showcase). One in-app purchase (~$4.99–7.99) unlocks the full game: all
  acts, the Memory Grove and every family. No ads, no consumables, no paid Grove speed-ups (they'd push the Grove to
  feel grindy).
- The unlock offer appears at natural moments only: the demo ending, the Grove teaser, and a "Full game" item in the
  Codex. Never a timer or a nag.
- Later and optional: cosmetic packs (card backs, Warden looks), never power.
- Same deal as Steam (one price, everything), so the two platforms never feel different.

## Work
| # | Work | Owner |
|---|---|---|
| 1 | **Performance pass:** a late-game frame at 150 nightmares is ~14 ms on desktop; phones need far less. Profile and trim per-frame costs; an Fx "mobile" tier; Godot's mobile / compatibility renderer. Target: 60 fps mid-range Android, 30 fps floor. | Main Merger (lead), Tower Code, Environment Code, Enemy Code |
| 2 | **Phone layouts:** every screen at 19.5:9 and 16:9 phone sizes; bigger tap targets; HUD and panels simplified; the touch Pin / tap-select already exist (platforms.md). | Main Merger, UI Code / UI Asset |
| 3 | **Shorter sessions:** confirm save / resume at every rest works when the OS kills the app; consider a "quick run" mode (fewer drifts) later. | Main Merger; Roguelite Mechanic Discussion for a quick mode |
| 4 | **Android test build** on the user's phone first (export template, signing key, `.apk`); iOS later (needs a Mac or a cloud build service, plus a $99/yr Apple account). Google Play is $25 one-time. | Main Merger |
| 5 | **The unlock purchase:** Google Play Billing / StoreKit plugins wired to the demo / full switch, with restore purchases. | Main Merger (after 4) |
| 6 | **Mobile marketing:** store page, launch plan (below). | Marketing Discussion |

## Marketing for mobile (Marketing Discussion owns the details)
- **The store page carries most installs:** the icon (most-tested asset), a title + subtitle with keywords ("Heartwood
  TD: Maze Tower Defense Roguelite"), the first 2–3 screenshots showing the maze, and a 15–30 s preview video.
- **Pre-registration (Google Play) / pre-order (App Store)** to bank day-one installs from the shorts.
- **Featuring is the big lever for premium games:** apply through Apple's "Promote your app" form and Google Play's
  indie programmes (Indie Corner, the Indie Games Festival) months ahead.
- **Short-form video works the same** on TikTok / Reels / Shorts; add "on mobile" versions with the phone UI.
- **Soft launch** in a small market (Canada or the Philippines are common) to check crashes, the free → paid conversion
  and the ratings, before launching worldwide.
- **Ratings:** ask for a review only after a good moment (a boss dispelled, a first win), never on a loss.
- **Press and community:** Pocket Gamer, mobile-gaming YouTubers who cover TD / roguelites, r/AndroidGaming,
  r/iosgaming.
- **Skip paid ads** at first: a premium-unlock game rarely earns back the cost per install.
