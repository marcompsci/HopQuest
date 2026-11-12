# HopQuest: privacy and security audit

_Updated November 12, 2026 · version 2.0 (build 3) · covers the app and the HopQuest widget extension_

## Data inventory

| Data | Where it lives | Leaves the device? | How it's erased |
|---|---|---|---|
| Child's first name or nickname (optional; "Explorer" if blank) | `UserDefaults` (profile JSON) | **Never**, including during live play | Grown-up settings → Start over with a new player, or delete the app |
| "Girl / boy / rather not say", castle and buddy choices | `UserDefaults` | No | Same |
| Progress: stars, levels, stickers, castle, house, garden, songs, Coding Lab code, learning counts | `UserDefaults` | No | Same |
| Grown-up settings (narration, sound, limits, live play, left-handed, kart color, arena) | `UserDefaults` / `@AppStorage` | No | Same |
| Widget data: buddy snapshot (buddy, stars, next lesson), Star Hop game state, Level Maker levels, Brain Bubble question index and count | App Group `group.com.phoronomics.hopquest` (`UserDefaults(suiteName:)`), shared only between HopQuest and its own widget on the same device | No | Same; the widget shows an empty state after Start over |
| Daily minutes (last two weeks), certificates, practice sheets, Level Maker levels, Sticker Scenes | `UserDefaults` (inside the player's save); certificates and sheets are made on the device when opened | Only if a grown-up chooses Print/Share or sends a milestone text, behind the parental gate, through the iOS share sheet or Messages; the developer still receives nothing | Same |
| Live play messages (only when a grown-up picks "Nearby only") | In memory | Yes, to other devices **in the same room** over Multipeer Connectivity, encrypted (`.required`): a random session key, the buddy's name and look, the buddy's position, and multiple-choice duel answers | Gone when play stops |

The developer runs no server and receives nothing. No analytics, crash reporting, advertising, tracking or third-party SDKs.

**App Store privacy label:** Data Not Collected. Apple's definition of "collect" means data that leaves the device and reaches the developer or third parties. Peer-to-peer messages between kids' own devices in the same room don't reach either.

## Required checks

| Requirement | Status | Evidence |
|---|---|---|
| HTTPS/TLS for network transport | n/a: no HTTP(S) networking at all | Gate: "No web addresses in the app code" |
| App Transport Security not weakened | ✅ no `NSAppTransportSecurity` key in either Info.plist, so there are no exceptions | `project.yml`, `Support/*.plist` |
| Secrets not in the bundle or repo | ✅ none exist; the gate scans for common key and token patterns, and gitleaks runs in CI | `scripts/release_check.py`, CI |
| Server-side authorization / RLS / Firebase rules | n/a: no backend | — |
| Secure token or session storage | n/a: no accounts or tokens | — |
| Input validation | ✅ The only free text is the child's own name (stored locally). Live play messages are decoded with `Codable`, nicknames are cleaned (`VillageNetMessage.cleanNick`), and malformed messages are ignored. Coding Lab code runs in a small built-in interpreter, never as native code. | `Network/VillageNetwork.swift`, `Models/CodeLab/MiniPython.swift` |
| Safe output | ✅ The web preview has JavaScript off, a Content-Security-Policy of `default-src 'none'` (pictures embedded as data), only `about:` loads allowed, and every navigation cancelled | `Views/CodeLab/CodeLabParts.swift` |
| Permission purpose strings | ✅ Local Network only, set in both builds (`Package.swift` and `project.yml` Info). The prompt appears only after a grown-up turns on Nearby play. Sharing and Messages use system sheets that need no permission. | Gate: "Xcode app: Local Network purpose string" |
| Privacy policy reachable | ⚠️ `PRIVACY.md` is up to date on this branch; **main must be updated** (compliance report F-3) | Gate |
| In-app account deletion | n/a: no accounts. In-app data erase exists. | `Views/ParentViews.swift` |
| Privacy manifests | ✅ The **app** has `HopQuest.swiftpm/PrivacyInfo.xcprivacy` with:<br>• tracking false, no domains, no collected data<br>• UserDefaults **CA92.1** (the app's own defaults) and **1C8F.1** (the App Group shared with the widget)<br>• system boot time **35F9.1** (live-play timeouts)<br>✅ The **widget** has `Support/Widget/PrivacyInfo.xcprivacy` (new on November 12) with UserDefaults **1C8F.1**. | The gate audits each target's manifest against that target's code and validates reason codes. CI checks that both are in the built products. The Xcode build log shows "Copy PrivacyInfo.xcprivacy" in the widget target. |
| Third-party SDK manifests | n/a: no SDKs | Gate: "No third-party package dependencies" |
| Encryption export classification | Uses only iOS-provided encryption (Multipeer Connectivity). `ITSAppUsesNonExemptEncryption = false` is set in the Xcode project's Info.plist, so uploads aren't asked. **The owner must confirm this classification.** | Gate: "Export compliance declared in Info.plist" |
| Tracking / ATT | ✅ none, and no IDFA | Gate |

## Kids-specific safeguards (Guidelines 1.3, 5.1.4)

- Parental gate (a typed multiplication answer) in front of all grown-up settings, including live play, and in front of every way to share or print (certificates, practice sheets, milestone texts).
- Lock Screen widgets never show the child's name. Home-screen widgets show only the buddy and game progress.
- Things children make (Level Maker levels, Sticker Scenes, Fridge Door drawings) stay on the device and are never shown to other players.
- Live play is **off** by default. When on, it is same-room only, and other players see only the buddy's name.
- The "Anyone" (strangers) mode was removed in v3.2. Game Center play is switched off (compliance report F-2).
- No links out of the app, no purchases, no ads, no analytics, no notifications, no streaks.

## What would change this audit

Adding any of these means updating this file, the privacy policy, the App Store privacy label and `scripts/release_check.py` in the same change:

- a new app extension or target (it needs its own privacy manifest)
- a server
- an account
- analytics or crash reporting
- an SDK
- a new permission
- a link out
- a purchase
- chat or shared content
- Game Center

_This is an engineering audit, not legal advice._
