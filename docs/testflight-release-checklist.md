# TestFlight release checklist

Work through this before **every** TestFlight upload. Tick each box in the pull request or release notes. A skipped item counts as not done.

## A. Automated (must be green)

- [ ] `bash scripts/run_tests.sh` ends with **ALL TEST SUITES PASSED**.
- [ ] `python3 scripts/release_check.py` shows **no FAIL** lines. MANUAL lines are covered in the sections below.
- [ ] The GitHub Actions **Release gate** workflow is green for the exact commit you're archiving: tests, compliance, secret scan and iOS build.

## B. Version and signing

- [ ] `project.yml` (`MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`) and `Package.swift` (`displayVersion`, `bundleVersion`) agree; the gate fails if they don't. The build number must be higher than every build already uploaded for that version (App Store Connect → TestFlight → Builds).
- [ ] After editing `project.yml`, regenerate with `xcodegen generate` and commit `HopQuest.xcodeproj`.
- [ ] Bundle IDs `com.phoronomics.hopquest` and `com.phoronomics.hopquest.widget`, team `X6LZQ3FS36`, App Group `group.com.phoronomics.hopquest` enabled for both App IDs.
- [ ] Open **`HopQuest.xcodeproj`**, not the `.swiftpm`: the widget only exists in the Xcode project. Set the destination to **Any iOS Device (arm64)**, then Product → **Archive** (the Release configuration).
- [ ] Organizer → **Validate App** passes, with automatic signing and an App Store distribution profile.
- [ ] Organizer → **Generate Privacy Report** lists **HopQuest and HopQuestWidget**, with only UserDefaults and system boot time, and no tracking or collected data.

## C. Device tests (one iPhone and one iPad)

**Install**
- [ ] Fresh install: onboarding works with an empty name ("Explorer") and with a typed name.
- [ ] Cold start (after force-quit) and warm start (back from the home screen) land where they should, with no frozen screen.

**Every page and card opens and can be left again**
- [ ] Bottom menu: Home, Adventures, Games, Learn, Worlds
- [ ] PLAY (Hop Village), SURPRISE ME!
- [ ] Star Dash, Star Hop, Breathe, Level Maker, Sticker Scenes, Fridge Door, Writing Desk, the learning places
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

**Widgets**
- [ ] Add Buddy, Star Hop and Brain Bubble to the home screen. Each one updates, and its buttons work.
- [ ] A Star Hop button that opens the app lands in Star Dash. With no player, or at bedtime, it just opens the app.
- [ ] Lock Screen widgets show no child name.

**Grown-up extras**
- [ ] Progress page: chart, certificate Print/Share, practice sheet Print/Share, milestone text. Each is reachable only after the gate.
- [ ] Bedtime: the goodnight screen shows, then clears in the morning.

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

- [ ] What to Test filled in (see `docs/external-tester-guide.md`). It describes this build's actual changes (Guidelines 2.3 and 2.5.19).
- [ ] Screenshots show the current app (tab menu, worlds, widgets), not older screens.
- [ ] The age rating questionnaire is answered on the current form.
- [ ] Beta App Description, feedback email and contact info set (see `docs/app-review-notes.md`).
- [ ] Export compliance: pre-answered by `ITSAppUsesNonExemptEncryption = NO` (iOS-provided encryption only). Confirm App Store Connect didn't ask.
- [ ] Privacy Policy URL opens the **current** policy, which is on `main`.
- [ ] After uploading, update `release/last_uploaded.json`, e.g. `{"version": "1.0", "build": "3"}`, and commit it.

## E. Never without the owner's go-ahead

- [ ] Uploading a build.
- [ ] Submitting for Beta App Review or App Review.
- [ ] Enabling a public link.
- [ ] Merging to `main`.


## Automated upload (GitHub Actions, no Xcode menus needed)

`.github/workflows/testflight.yml` archives the app and widget on a GitHub Mac with Xcode 26, then uploads to App Store Connect. It runs only when started by hand, and **never submits for App Review**.

**One-time setup (owner only, about 5 minutes):**
1. App Store Connect → **Users and Access → Integrations → App Store Connect API → Team Keys → ＋**. Name it "HopQuest CI" and give it the **Admin** role, so Xcode can create the distribution certificate and profiles itself. Download the `.p8` file; Apple only lets you download it once.
2. GitHub → marcompsci/HopQuest → **Settings → Secrets and variables → Actions → New repository secret**, three times:
   - `ASC_KEY_ID`: the key's ID
   - `ASC_ISSUER_ID`: the Issuer ID shown above the keys list
   - `ASC_KEY_P8`: open the `.p8` file in a text editor and paste all of it, including the BEGIN and END lines
3. Keep the `.p8` file somewhere safe, or delete it. Never commit it.

**Each upload:**
1. GitHub → **Actions → TestFlight upload → Run workflow** and enter a build number higher than any uploaded for this version. This works once the workflow is on `main`. Before then, push a commit to `feature/hop-village` whose message includes `[testflight build N]`.
2. The gate job runs the tests and the release check. Any failure stops the upload, except the main-branch privacy-policy check, which is reported as a warning because it only blocks external testing and App Review.
3. When Apple's "processed" email arrives, the build appears under TestFlight. Then record it in `release/last_uploaded.json`.
