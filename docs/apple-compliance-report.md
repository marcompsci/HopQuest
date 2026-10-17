# HopQuest: Apple compliance report

_Audit date: October 17, 2026 · Version 2.0 (build 2) · branch `feature/hop-village`_
_Source of truth: the App Review Guidelines at https://developer.apple.com/app-store/review/guidelines/ and the Apple Developer documentation linked below. Nothing here guarantees Apple's approval; App Review decides._

## 1. Release-readiness result

**FAIL until one item is done, then CONDITIONAL.**

- **The one blocker:** the Privacy Policy and Support URLs in App Store Connect point at the `main` branch, and `main` still has the version 1.0 policy. That policy says "no internet connection at all" and "no contact with other players". Version 2.0 has optional same-room play, so a reviewer would read a policy that doesn't match the app.
- **The fix:** merge `feature/hop-village` into `main`, or point the URLs at a page that has the 2.0 policy. This needs the owner's approval.
- **After that fix:** every automated gate passes, and the result becomes **CONDITIONAL**. The manual items in section 6 still need a person: an archive, device tests, screenshots and App Store Connect answers.

Run `python3 scripts/release_check.py` to see the live result; it's listed in section 5.

## 2. Architecture summary (what was actually found)

| Area | Finding |
|---|---|
| Project type | Swift Playgrounds app package `HopQuest.swiftpm` (SwiftPM + `AppleProductTypes`), opened in Xcode 15+. No `.xcodeproj`, no separate Info.plist or entitlements file: the Info.plist values come from `Package.swift`. |
| Platforms | iOS/iPadOS 17+. iPhone portrait; iPad in all orientations, with the game drawn in a tall play area. |
| Languages / frameworks | Swift, SwiftUI, SpriteKit, UIKit, AVFoundation (synthesized sound + `AVSpeechSynthesizer` narration), WebKit (offline web-page preview), MultipeerConnectivity (same-room play), GameKit (online play code, switched off; see F-2). |
| Third-party code | None. `Package.swift` has no dependencies. |
| Backend / accounts / database | None. No server, no Supabase/Firebase, no sign-in, no accounts. |
| Storage | One JSON profile in `UserDefaults` on the device, plus a few `@AppStorage` settings. Erased by Grown-up settings → "Start over with a new player", or by deleting the app. |
| Network | No HTTP(S) calls at all. Optional Multipeer Connectivity between devices in the same room, with `encryptionPreference: .required`, off by default and switched on only behind the parental gate. |
| Payments | Paid up front ($4.99). No in-app purchases, subscriptions or virtual currency. |
| UGC / communication | No chat, no free text, no uploads. Live play exchanges positions, buddy choice, buddy name and multiple-choice duel answers only. |
| Permissions | Local Network only, prompted by iOS when a grown-up picks "Nearby only". Purpose string is in `Package.swift`. |
| Privacy manifest | `PrivacyInfo.xcprivacy`: no tracking, no collected data, required-reason APIs UserDefaults (CA92.1) and system boot time (35F9.1). |
| Tests | Six suites (Village logic, Coding Lab, Robot Lab, Learn + Story, Worlds data, Fort levels): about 553,000 checks, all passing. `scripts/run_tests.sh` runs them all. |
| CI | None existed. Added `.github/workflows/release-gate.yml`, which runs the tests, compliance checks, a secret scan and an iOS Simulator build. |

## 3. Findings

Severity: BLOCKER (will likely be rejected or block upload), HIGH, MEDIUM, LOW.

| # | Guideline / requirement | Where | Severity | Concern | Remediation | Done? | Verified by |
|---|---|---|---|---|---|---|---|
| F-1 | Privacy manifest required-reason APIs (enforced at upload since May 1, 2024; ITMS-91053) | `Network/VillageNetwork.swift:61` uses `ProcessInfo.processInfo.systemUptime` | HIGH | The system-boot-time API was used without a declared reason, so the upload would get ITMS-91053. | Declared `NSPrivacyAccessedAPICategorySystemBootTime` with reason **35F9.1** (measuring time intervals between app events), which is what the code does: duel and peer timeouts. | ✅ | `release_check.py` scans the code for every required-reason API family and fails if one is undeclared. Mutation test: deleting the entry makes it FAIL. The manifest parses as a valid plist. |
| F-2 | Game Center entitlement required for submissions that use Game Center ([Apple: capability entitlement updates](https://developer.apple.com/help/account/reference/capability-entitlement-updates/)); 2.1 App Completeness | `Network/GameCenterTransport.swift`, `Views/ParentViews.swift` | HIGH | Grown-ups could pick "Game Center friends". A Swift Playgrounds package can't add the Game Center capability ([supported capabilities](https://developer.apple.com/documentation/swift-playgrounds/project-capabilities)), so the shipped app has no entitlement. Reviewers would hit "Game Center isn't set up". | Added `VillagePlayMode.gameCenterAvailable = false`: the picker offers Off / Nearby only, and an old saved "Game Center friends" choice runs as Off. The online code stays, ready for the day the project moves to an Xcode project with the Game Center capability. The listing, privacy policy and support page no longer mention Game Center. | ✅ | Unit tests in `Tests/VillageLogic`. Release gate: "Game Center play is switched off" and "Listing doesn't promise Game Center play". |
| F-3 | 2.3 Accurate Metadata; 5.1.1(i) privacy policy must be accurate and reachable | Privacy Policy URL `…/blob/main/PRIVACY.md`, Support URL `…/blob/main/SUPPORT.md` | **BLOCKER** | `main` has the 1.0 policy, which says no internet and no contact with other players. That doesn't describe 2.0's optional same-room play. | Merge `feature/hop-village` → `main` (or host PRIVACY.md and SUPPORT.md elsewhere and update the URLs). | ❌ needs owner approval | The gate compares `origin/main:PRIVACY.md` with this branch and FAILs until they match. |
| F-4 | 2.3.3 Screenshots; iPad support requires iPad screenshots | App Store Connect | HIGH | The app now runs on iPad, and the 2.0 screens (village, labs, worlds) aren't in the current screenshots. | Take 6.9" iPhone and 13" iPad sets. The shot list is in `APPSTORE.md`. | ❌ manual | Manual |
| F-5 | Export compliance | Upload in App Store Connect / Xcode | MEDIUM | Uses only iOS-provided encryption (Multipeer Connectivity). The `ITSAppUsesNonExemptEncryption` key can't be set from a Swift Playgrounds package, so the question is asked at every upload. | Answer: uses encryption, but only the exempt encryption built into iOS. The owner must confirm this answer. | ❌ manual | Manual |
| F-6 | 2.1 App Completeness (device testing) | Whole app | MEDIUM | Version 2.0 (all of v2.4–v4.3) built with 0 errors in Xcode on the owner's Mac and was installed and launched on a connected iPhone on Oct 16–17, 2026 (Debug, Run). A Release archive, an iPad device run and a full manual pass haven't been done. | Archive, validate, then run the checklist in `docs/testflight-release-checklist.md` on an iPhone and an iPad. | Partly | Xcode build log (owner's Mac). |
| F-7 | 5.1.4 Kids / accurate privacy statements | `PRIVACY.md` | LOW | The policy said the app "complies with COPPA", an unqualified legal claim. | Reworded to "designed … with COPPA and the Kids Category guidelines in mind". The facts it relies on (no data collected) are unchanged. Not legal advice: have a lawyer review if you need certainty. | ✅ | Diff review |
| F-8 | 2.1 / review notes (features reviewers can't easily reach) | Same-room play needs two devices | MEDIUM | Reviewers may not be able to test Nearby play. | The review notes explain the feature and that it needs two devices. Everything else works on one device. | ✅ | `docs/app-review-notes.md` |
| F-9 | Build numbers must increase | `Package.swift` (2.0 / 2) | MEDIUM | It isn't known which builds were already uploaded under app 6823413640. | Before uploading, check TestFlight → Builds, raise `bundleVersion` if needed, then record it in `release/last_uploaded.json` so the gate checks it from then on. | ❌ manual | Gate shows MANUAL until the file exists |
| F-10 | 3.1 Payments: Paid Apps agreement | App Store Connect → Business | MEDIUM | A $4.99 app needs the Paid Apps Agreement, tax and banking active before it can go on sale. This doesn't apply to TestFlight. | Check Business in App Store Connect. | ❌ manual | Manual |
| F-11 | 1.3 Kids Category | Whole app | — (passes) | No links out, no purchases, no ads, no analytics, no third-party SDKs. Grown-up settings are behind a typed math parental gate. The web preview has JavaScript off and a content policy that blocks every network load. | Kept, and now enforced by the gate. | ✅ | Release gate (7 checks) |
| F-12 | 1.2 UGC / 4.x social | Live play | — (passes) | There is no user-generated content or communication, so reporting and blocking tools don't apply. Live play is off by default, same room only, and only the buddy's name is shared (never the child's). | Kept, and enforced by the gate. | ✅ | Gate + unit tests |
| F-13 | 5.1.1(v) account deletion | — | — (n/a) | No accounts. On-device data can be erased in-app ("Start over with a new player"). | — | n/a | Code review |
| F-14 | CI gate | `.github/workflows/release-gate.yml` | MEDIUM | New workflow. The GitHub CLI isn't signed in here, so its first run on GitHub hasn't been observed. The `ios-build` job (unsigned simulator build of a `.swiftpm`) is the one most likely to need a tweak. | Open the Actions tab after this push and fix anything red. A red job means the gate failed; nothing is marked "allowed to fail". | ❌ to observe | GitHub Actions |

Also fixed in this release (v4.0 polish, from an earlier runtime audit): kart ramps that dropped karts into puddles, voice tips talking over math questions, Ice Rink bots sliding off, Moon Base jumps leaving the screen, a cutscene double tap that skipped the next screen, Word Pop not working with narration off, region-dependent day keys breaking the garden, iPad edges being clipped, and pet taps stealing walk taps.

## 4. Functionality and crash-prevention notes

- **Static review:** no `try!`. The only `fatalError` is the standard unused `init(coder:)`. The force unwraps are on non-empty constant arrays or are covered by tests (e.g. `StoryBook.intro`). Data files (`worlds.json`) are validated before use; a bad file falls back to "no extra worlds" instead of crashing.
- **Saves:** every saved field decodes with a default, so old or damaged saves load. This is tested for the village save, garden, songs, reading, market, science and stories.
- **Background/foreground:** the audio engine restarts after interruptions and configuration changes. The garden refreshes when the app comes back. Daily play time is counted only while the app is active.
- **Not verifiable here:** cold/warm start timing, memory use (use Instruments → Allocations/Leaks on device), iPad rotation on device, and VoiceOver walk-throughs. These are listed in the checklist.

## 5. Automated gates

| Gate | Command | Status here |
|---|---|---|
| All logic test suites | `bash scripts/run_tests.sh` | ✅ all six pass (Linux toolchain) |
| Apple compliance checks | `python3 scripts/release_check.py` | 46 pass, 1 FAIL until merge (F-3), 7 MANUAL |
| Secret scan | gitleaks (CI) + the gate's own scan | Gate's scan ✅; gitleaks runs in CI |
| iOS build | `xcodebuild … CODE_SIGNING_ALLOWED=NO build` (CI, macos-14) | Not yet observed; owner's Xcode build ✅ |
| UI tests | — | None exist. A Swift Playgrounds package can't host an XCUITest target; that needs an Xcode project. |
| Dependency vulnerabilities | Gate checks there are no dependencies | ✅ none |

## 6. Remaining manual Apple Developer actions

1. Approve and merge `feature/hop-village` → `main` (F-3).
2. In Xcode: set the destination to Any iOS Device → Product → Archive → Validate App, then Distribute → App Store Connect → Upload. Answer export compliance (F-5).
3. Record the uploaded version and build in `release/last_uploaded.json` (F-9).
4. App Store Connect, version 2.0:
   - Description, What's New and keywords from `APPSTORE.md`.
   - New iPhone and iPad screenshots (F-4).
   - Age rating questionnaire (answers in `APPSTORE.md`).
   - Kids Category, Ages 6–8.
   - Privacy label "Data Not Collected".
   - Review notes from `docs/app-review-notes.md`.
5. TestFlight: follow `docs/testflight-release-checklist.md` and `docs/external-tester-guide.md`.
6. Paid Apps Agreement, tax and banking (F-10).
7. Never press "Submit for Review" without the owner's go-ahead.

## 7. Permanent release gate

Before every TestFlight or App Store upload:

1. Run `bash scripts/run_tests.sh` and `python3 scripts/release_check.py`. Both must end without FAIL.
2. Check that the GitHub Actions "Release gate" workflow is green for the commit you're archiving.
3. Work through `docs/testflight-release-checklist.md`.
4. If you add a framework, permission, SDK, network call, link, purchase or anything social, extend `scripts/release_check.py` in the same change.
