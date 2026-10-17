# TestFlight release checklist

Work through this before **every** TestFlight upload. Tick each box in the pull request or release notes. A skipped item counts as not done.

## A. Automated (must be green)

- [ ] `bash scripts/run_tests.sh` ends with **ALL TEST SUITES PASSED**.
- [ ] `python3 scripts/release_check.py` shows **no FAIL** lines. MANUAL lines are covered in the sections below.
- [ ] The GitHub Actions **Release gate** workflow is green for the exact commit you're archiving: tests, compliance, secret scan and iOS build.

## B. Version and signing

- [ ] `Package.swift`: `displayVersion` is the marketing version, and `bundleVersion` is higher than every build already uploaded for that version (check App Store Connect → TestFlight → Builds).
- [ ] Bundle ID `com.phoronomics.hopquest`, team `X6LZQ3FS36`.
- [ ] In Xcode, the destination is **Any iOS Device (arm64)**, then Product → **Archive**. This uses the Release configuration.
- [ ] Organizer → **Validate App** passes, with automatic signing and an App Store distribution profile.
- [ ] Organizer → **Generate Privacy Report** lists only UserDefaults and system boot time.

## C. Device tests (one iPhone and one iPad)

**Install**
- [ ] Fresh install: onboarding works with an empty name ("Explorer") and with a typed name.
- [ ] Cold start (after force-quit) and warm start (back from the home screen) land where they should, with no frozen screen.

**Every menu card opens and can be left again**
- [ ] PLAY (Hop Village)
- [ ] Coding Lab, Reading Nook, Math Market, Science Lab, Music Maker
- [ ] Stickers, Fort Friends, Pillow Bop, Bubble Kart, My Castle
- [ ] Adventure Map, Together, Stories

**Hop Village**
- [ ] Walk with the joystick and by tapping.
- [ ] Enter at least five buildings.
- [ ] Garden: plant, water, pick a pet. The pet follows you.
- [ ] Notice board.
- [ ] Mission log.

**Games**
- [ ] One story level to the end. Its story scene plays, Skip works, then the balloon flight.

**Grown-up settings**
- [ ] The gate rejects a wrong answer.
- [ ] Play with others shows only Off / Nearby only.
- [ ] Left-handed controls.
- [ ] Start over with a new player.

**Two devices (if available)**
- [ ] Nearby only on both.
- [ ] The Local Network prompt appears.
- [ ] Buddies see each other.
- [ ] A Brain Duel finishes.

**iPad**
- [ ] Rotate between portrait and landscape in the menu, a hop level and Hop Village. The play area stays centered with the sky around it.

**Accessibility**
- [ ] Text Size at the largest setting: menu, Reading Nook and the garden still fit.
- [ ] VoiceOver reads the Brain Gate answers.
- [ ] Reduce Motion is respected.

**Interruptions**
- [ ] A phone call, Siri or Control Center mid-game: sound and music resume.
- [ ] Airplane mode: everything works except Nearby play.

**Memory**
- [ ] Optional: Instruments → Leaks during 10 minutes of play shows no growing leaks.

## D. App Store Connect

- [ ] What to Test filled in (see `docs/external-tester-guide.md`).
- [ ] Beta App Description, feedback email and contact info set (see `docs/app-review-notes.md`).
- [ ] Export compliance answered: iOS-provided encryption only (exempt).
- [ ] Privacy Policy URL opens the **current** policy, which is on `main`.
- [ ] After uploading, update `release/last_uploaded.json`, e.g. `{"version": "2.0", "build": "2"}`, and commit it.

## E. Never without the owner's go-ahead

- [ ] Uploading a build.
- [ ] Submitting for Beta App Review or App Review.
- [ ] Enabling a public link.
- [ ] Merging to `main`.
