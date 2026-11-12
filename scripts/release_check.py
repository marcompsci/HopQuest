#!/usr/bin/env python3
"""HopQuest release gate: static checks to run before every TestFlight / App Store upload.

    python3 scripts/release_check.py            # all checks
    python3 scripts/release_check.py --strict   # MANUAL items also fail the run

Results:
  PASS    the check ran and passed
  FAIL    a known problem: fix before uploading (exit code 1)
  MANUAL  can't be checked from the repo; a person must confirm it (listed at the end, never counted as passed)

These checks don't replace building in Xcode, testing on a device, or Apple's review.
"""
import json, os, plistlib, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PKG = os.path.join(ROOT, "HopQuest.swiftpm")
WIDGET = os.path.join(ROOT, "HopQuestWidget")
SUPPORT = os.path.join(ROOT, "Support")
STRICT = "--strict" in sys.argv

results = []   # (status, name, detail)


def record(status, name, detail=""):
    results.append((status, name, detail))


def check(ok, name, detail_fail="", detail_ok=""):
    record("PASS" if ok else "FAIL", name, detail_ok if ok else detail_fail)
    return ok


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def swift_files(roots=(PKG, WIDGET)):
    for root in roots:
        for base, dirs, files in os.walk(root):
            dirs[:] = [d for d in dirs if d not in ("ArtSource", ".build", ".swiftpm")]
            for f in files:
                if f.endswith(".swift") and f != "Package.swift":
                    yield os.path.join(base, f)


SOURCES = {p: read(p) for p in swift_files()}
ALL_SWIFT = "\n".join(SOURCES.values())


def uses(pattern, only=None):
    """Files whose code matches. only: a list of directories to limit the search to."""
    return [os.path.relpath(p, ROOT) for p, s in SOURCES.items()
            if re.search(pattern, s) and (only is None or any(p.startswith(d + os.sep) for d in only))]


# The widget extension is built from HopQuestWidget/ plus HopQuest.swiftpm/Shared (see project.yml).
WIDGET_DIRS = [WIDGET, os.path.join(PKG, "Shared")]


# ---------------------------------------------------------------- package / versions
manifest = read(os.path.join(PKG, "Package.swift"))
m_ver = re.search(r'displayVersion:\s*"([^"]+)"', manifest)
m_build = re.search(r'bundleVersion:\s*"([^"]+)"', manifest)
check(bool(re.search(r'bundleIdentifier:\s*"com\.phoronomics\.hopquest"', manifest)), "Bundle ID is com.phoronomics.hopquest",
      "bundleIdentifier changed or missing in Package.swift")
check(bool(re.search(r'teamIdentifier:\s*"[A-Z0-9]{10}"', manifest)), "Team ID is set", "teamIdentifier missing or malformed")
check(bool(m_ver and re.fullmatch(r"\d+(\.\d+){0,2}", m_ver.group(1))), "Version number is valid (e.g. 2.0)",
      f"displayVersion {m_ver.group(1) if m_ver else 'missing'} isn't a dotted number")
check(bool(m_build and re.fullmatch(r"\d+(\.\d+){0,2}", m_build.group(1))), "Build number is valid (e.g. 3)",
      f"bundleVersion {m_build.group(1) if m_build else 'missing'} isn't a number")
check(bool(re.search(r'\.iOS\("1[7-9]\.\d+"\)', manifest)), "Deployment target is iOS 17+", "platforms .iOS version unexpected")
check("dependencies:" not in manifest, "No third-party package dependencies (no SDKs to audit)",
      "Package.swift now has dependencies: review each one's privacy manifest, licence and Kids Category rules")

last_path = os.path.join(ROOT, "release", "last_uploaded.json")
if os.path.exists(last_path) and m_ver and m_build:
    last = json.load(open(last_path))
    def key(v):
        return tuple(int(x) for x in str(v).split("."))
    if last.get("version") == m_ver.group(1):
        check(key(m_build.group(1)) > key(last.get("build", 0)), "Build number is higher than the last upload of this version",
              f"build {m_build.group(1)} must be higher than {last.get('build')} (last uploaded {last.get('version')}); bump bundleVersion")
    else:
        check(key(m_ver.group(1)) > key(last.get("version", "0")), "Version is newer than the last upload",
              f"version {m_ver.group(1)} isn't newer than {last.get('version')}")
else:
    record("MANUAL", "Build number is higher than anything already uploaded",
           "create release/last_uploaded.json after each upload so this can be checked automatically")

# ---------------------------------------------------------------- privacy manifests + required-reason APIs
# Approved reason codes (Apple: "Describing use of required reason API"). Only the codes HopQuest could
# legitimately use are listed; anything else fails so a person has to look at it.
REASONS = {
    "NSPrivacyAccessedAPICategoryUserDefaults": {"CA92.1", "1C8F.1", "C56D.1", "AC6B.1"},
    "NSPrivacyAccessedAPICategorySystemBootTime": {"35F9.1", "8FFB.1", "3D61.1"},
    "NSPrivacyAccessedAPICategoryFileTimestamp": {"DDA9.1", "C617.1", "3B52.1", "0A2A.1"},
    "NSPrivacyAccessedAPICategoryDiskSpace": {"85F4.1", "E174.1", "7D9E.1", "B728.1"},
    "NSPrivacyAccessedAPICategoryActiveKeyboards": {"3EC4.1", "54BD.1"},
}
REQUIRED_REASON = {
    "NSPrivacyAccessedAPICategoryUserDefaults": r"\bUserDefaults\b|@AppStorage",
    "NSPrivacyAccessedAPICategorySystemBootTime": r"systemUptime|mach_absolute_time|mach_continuous_time",
    "NSPrivacyAccessedAPICategoryFileTimestamp": r"creationDate|modificationDate|contentModificationDate|attributesOfItem|\bstat\(|getattrlist",
    "NSPrivacyAccessedAPICategoryDiskSpace": r"volumeAvailableCapacity|systemFreeSize|systemSize|statfs|NSFileSystemFreeSize",
    "NSPrivacyAccessedAPICategoryActiveKeyboards": r"activeInputModes",
}
APP_GROUP_DEFAULTS = r"UserDefaults\(suiteName:"


def audit_manifest(label, path, code_dirs):
    """Checks one target's privacy manifest against the code that target compiles."""
    declared = {}
    if not check(os.path.exists(path), f"{label}: privacy manifest exists ({os.path.relpath(path, ROOT)})",
                 "missing: every target that calls a required-reason API needs its own PrivacyInfo.xcprivacy (ITMS-91053)"):
        return declared
    try:
        priv = plistlib.load(open(path, "rb"))
    except Exception as e:  # noqa: BLE001
        record("FAIL", f"{label}: privacy manifest is a valid plist", str(e))
        return declared
    check(priv.get("NSPrivacyTracking") is False, f"{label}: no tracking", "NSPrivacyTracking must be false")
    check(priv.get("NSPrivacyTrackingDomains", []) == [], f"{label}: no tracking domains", "tracking domains listed")
    check(priv.get("NSPrivacyCollectedDataTypes", []) == [], f"{label}: no collected data (matches 'Data Not Collected')",
          "collected data types are listed: the App Store privacy label must match")
    for item in priv.get("NSPrivacyAccessedAPITypes", []):
        declared[item.get("NSPrivacyAccessedAPIType")] = item.get("NSPrivacyAccessedAPITypeReasons", [])
    for cat, reasons in declared.items():
        short = cat.replace("NSPrivacyAccessedAPICategory", "")
        bad = [r for r in reasons if r not in REASONS.get(cat, set())]
        check(bool(reasons) and not bad, f"{label}: '{short}' reason codes are valid ({', '.join(reasons)})",
              f"unknown or empty reason codes {bad or reasons}: check Apple's list")
    for cat, pattern in REQUIRED_REASON.items():
        files = uses(pattern, code_dirs)
        short = cat.replace("NSPrivacyAccessedAPICategory", "")
        if files:
            check(bool(declared.get(cat)), f"{label}: required-reason API '{short}' is declared",
                  f"used in {', '.join(files[:3])} but not declared (ITMS-91053)")
        elif cat in declared:
            record("PASS", f"{label}: '{short}' declared (not found in this target's code: harmless, consider removing)")
    if uses(APP_GROUP_DEFAULTS, code_dirs):
        check("1C8F.1" in declared.get("NSPrivacyAccessedAPICategoryUserDefaults", []),
              f"{label}: App Group defaults declared with reason 1C8F.1",
              "UserDefaults(suiteName:) on the App Group is used: add 1C8F.1 (CA92.1 covers the app's own defaults only)")
    return declared


declared = audit_manifest("App", os.path.join(PKG, "PrivacyInfo.xcprivacy"), [PKG])
audit_manifest("Widget", os.path.join(SUPPORT, "Widget", "PrivacyInfo.xcprivacy"), WIDGET_DIRS)

# ---------------------------------------------------------------- Xcode project (the build that ships with the widget)
yml_path = os.path.join(ROOT, "project.yml")
if check(os.path.exists(yml_path), "Xcode project spec exists (project.yml)", "project.yml missing"):
    yml = read(yml_path)
    def yv(key):
        mm = re.search(r"^\s*" + re.escape(key) + r":\s*\"?([^\"\n]+)\"?\s*$", yml, re.M)
        return mm.group(1).strip() if mm else None
    check(yv("MARKETING_VERSION") == (m_ver.group(1) if m_ver else None), "Xcode version matches Package.swift",
          f"MARKETING_VERSION {yv('MARKETING_VERSION')} vs displayVersion {m_ver.group(1) if m_ver else '?'}")
    check(yv("CURRENT_PROJECT_VERSION") == (m_build.group(1) if m_build else None), "Xcode build number matches Package.swift",
          f"CURRENT_PROJECT_VERSION {yv('CURRENT_PROJECT_VERSION')} vs bundleVersion {m_build.group(1) if m_build else '?'}")
    ids = re.findall(r"PRODUCT_BUNDLE_IDENTIFIER:\s*(\S+)", yml)
    check("com.phoronomics.hopquest" in ids and all(i == "com.phoronomics.hopquest" or i.startswith("com.phoronomics.hopquest.") for i in ids),
          "Bundle IDs: app com.phoronomics.hopquest, extensions prefixed with it", f"bundle IDs {ids}")
    check(bool(re.search(r"DEVELOPMENT_TEAM:\s*[A-Z0-9]{10}", yml)), "Xcode team ID is set", "DEVELOPMENT_TEAM missing")
    check(bool(re.search(r"ITSAppUsesNonExemptEncryption:\s*false", yml)), "Export compliance declared in Info.plist (exempt: no custom encryption)",
          "ITSAppUsesNonExemptEncryption missing: every upload will ask")
    lnd = re.search(r"NSLocalNetworkUsageDescription:\s*(.+)", yml)
    check(bool(lnd) and len(lnd.group(1)) >= 20, "Xcode app: Local Network purpose string", "NSLocalNetworkUsageDescription missing")
    check("NSBonjourServices" in yml, "Xcode app: Bonjour services declared", "NSBonjourServices missing")
    check("Support/Widget/PrivacyInfo.xcprivacy" in yml and "HopQuest.swiftpm/PrivacyInfo.xcprivacy" in yml,
          "Both privacy manifests are copied into their targets (each named PrivacyInfo.xcprivacy)",
          "a privacy manifest isn't listed as a resource in project.yml")
    check(bool(re.search(r"archive:\s*\n\s*config:\s*Release", yml)), "Archive uses the Release configuration", "scheme archive config isn't Release")
ALLOWED_ENTITLEMENTS = {"com.apple.security.application-groups"}
for ent in ("HopQuest.entitlements", "HopQuestWidget.entitlements"):
    p = os.path.join(SUPPORT, ent)
    if os.path.exists(p):
        keys = set(plistlib.load(open(p, "rb")).keys())
        check(keys <= ALLOWED_ENTITLEMENTS, f"{ent}: only the App Group entitlement",
              f"extra entitlements {sorted(keys - ALLOWED_ENTITLEMENTS)}: confirm each is enabled for the App ID and needed")
    else:
        record("MANUAL", f"{ent} is generated by xcodegen", "run xcodegen generate and re-check")
deep = uses(r"onOpenURL")
if deep:
    hosts = re.findall(r'case\s+"([a-z]+)":\s*route', ALL_SWIFT)
    check('url.scheme == "hopquest"' in ALL_SWIFT and hosts == ["quickgame"], "Deep links: only hopquest://quickgame is acted on",
          "onOpenURL handles more than the known quick-game link: review it")

# ---------------------------------------------------------------- permissions / purpose strings
if uses(r"import MultipeerConnectivity|import Network\b"):
    check(bool(re.search(r"\.localNetwork\(purposeString:\s*\"[^\"]{20,}\"", manifest)),
          "Local Network purpose string is set", "MultipeerConnectivity is used but no .localNetwork(purposeString:) capability")
    check("bonjourServiceTypes" in manifest, "Bonjour service types are declared", "NSBonjourServices missing")
PERMISSION_APIS = {
    "camera": r"AVCaptureDevice", "microphone": r"requestRecordPermission|AVAudioApplication\.requestRecord",
    "location": r"CLLocationManager", "photos": r"PHPhotoLibrary", "contacts": r"CNContactStore",
    "calendar": r"EKEventStore", "motion": r"CMMotionManager", "bluetooth": r"CBCentralManager|CBPeripheralManager",
    "speech recognition": r"SFSpeechRecognizer", "notifications": r"UNUserNotificationCenter",
}
for name, pattern in PERMISSION_APIS.items():
    files = uses(pattern)
    check(not files, f"No {name} access (none needed)", f"{name} API used in {', '.join(files)}: add a purpose string and update the privacy docs")

# ---------------------------------------------------------------- Kids Category (Guideline 1.3) and payments (3.1)
for name, pattern in {
    "StoreKit / in-app purchases": r"import StoreKit|SKPayment|Product\.purchase",
    "advertising / IDFA": r"import AdSupport|advertisingIdentifier|import GoogleMobileAds",
    "tracking prompt": r"import AppTrackingTransparency",
    "third-party analytics": r"import Firebase|Analytics\.logEvent|import Mixpanel|import Amplitude|import Sentry",
}.items():
    files = uses(pattern)
    check(not files, f"Kids Category: no {name}", f"found in {', '.join(files)}")
def leaves_app(path):
    code = SOURCES[os.path.join(ROOT, path)]
    if re.search(r"openURL|UIApplication\.shared\.open|SFSafariViewController|ASWebAuthenticationSession", code):
        return True
    # a Link is fine only when every URL it can open is the app's own scheme (the widget opening HopQuest)
    return bool(re.search(r"\bLink\(", code)) and any(not u.startswith("hopquest://") for u in re.findall(r'URL\(string:\s*"([^"]*)"', code)) \
        or bool(re.search(r"\bLink\((?![^)]*URL\(string:\s*\"hopquest://)", code))
links = [f for f in uses(r"openURL|UIApplication\.shared\.open|\bLink\(|SFSafariViewController|ASWebAuthenticationSession") if leaves_app(f)]
check(not links, "Kids Category: no links out of the app", f"links found in {', '.join(links)}: they must sit behind the parental gate")
http = uses(r'"https?://')
check(not http, "No web addresses in the app code (no network calls)", f"URL literals in {', '.join(http)}")
if uses(r"import WebKit"):
    parts = SOURCES.get(os.path.join(PKG, "Views", "CodeLab", "CodeLabParts.swift"), "")
    check("allowsContentJavaScript = false" in parts and "Content-Security-Policy" in parts and "default-src 'none'" in parts,
          "Web preview: JavaScript off and an offline-only content policy",
          "WKWebView found without JavaScript off + CSP default-src 'none' (Unrestricted Web Access rating)")

# ---------------------------------------------------------------- live play safety
save = SOURCES.get(os.path.join(PKG, "Models", "VillageSaveState.swift"), "")
check("var playMode: VillagePlayMode = .off" in save and "forKey: .playMode)) ?? .off" in save,
      "Live play starts Off (new and old saves)", "playMode must default to .off")
check(not re.search(r"case\s+[^\n]*\banyone\b", save), "No play with strangers ('anyone' mode is gone)", "an 'anyone' play mode is back")
gc_flag = re.search(r"static let gameCenterAvailable\s*=\s*(true|false)", save)
if gc_flag and gc_flag.group(1) == "false":
    record("PASS", "Game Center play is switched off (no Game Center entitlement in either build)")
else:
    record("MANUAL", "Game Center play is on: confirm the build carries com.apple.developer.game-center and Game Center is enabled in App Store Connect")
check("VillageNetMessage.cleanNick" in ALL_SWIFT and "let nick = store.character.name" in ALL_SWIFT,
      "Only the buddy's name is shared in live play (never the child's)", "nickname source changed: check it can't be the child's name")

# ---------------------------------------------------------------- app icon
try:
    from PIL import Image
    icon_dir = os.path.join(PKG, "Assets.xcassets", "AppIcon.appiconset")
    meta = json.load(open(os.path.join(icon_dir, "Contents.json")))
    fname = next((i.get("filename") for i in meta["images"] if i.get("size") == "1024x1024"), None)
    if check(bool(fname), "App icon: a 1024×1024 image is listed", "no 1024x1024 icon in AppIcon.appiconset"):
        im = Image.open(os.path.join(icon_dir, fname))
        alpha = im.mode in ("RGBA", "LA", "P") and (im.convert("RGBA").getchannel("A").getextrema() != (255, 255))
        check(im.size == (1024, 1024) and not alpha, "App icon: 1024×1024 with no transparency",
              f"icon is {im.size} {im.mode}; the App Store icon must be opaque")
except ImportError:
    record("MANUAL", "App icon size and transparency", "install Pillow (pip install pillow) to check automatically")

# ---------------------------------------------------------------- secrets
SECRET = re.compile(r"AKIA[0-9A-Z]{16}|sk_live_[0-9a-zA-Z]{20,}|ghp_[0-9A-Za-z]{30,}|xox[baprs]-[0-9A-Za-z-]{10,}|"
                    r"-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|AIza[0-9A-Za-z_-]{35}|"
                    r"(api[_-]?key|secret|password)\s*[:=]\s*\"[^\"]{8,}\"", re.I)
hits = []
for base, dirs, files in os.walk(ROOT):
    dirs[:] = [d for d in dirs if d not in (".git", ".build", "__pycache__")]
    for f in files:
        if f.endswith((".png", ".jpg", ".m4a", ".wav", ".swiftmodule", ".pdf")):
            continue
        p = os.path.join(base, f)
        try:
            s = read(p)
        except (UnicodeDecodeError, OSError):
            continue
        if p.endswith("release_check.py"):
            continue
        for mm in SECRET.finditer(s):
            hits.append(f"{os.path.relpath(p, ROOT)}: {mm.group(0)[:12]}…")
check(not hits, "No secrets, keys or tokens in the repository", "; ".join(hits[:5]))

# ---------------------------------------------------------------- listing + docs
store = read(os.path.join(ROOT, "APPSTORE.md"))
def section(title):
    m = re.search(r"## " + re.escape(title) + r"[^\n]*\n(.+?)(\n## |\Z)", store, re.S)
    return m.group(1).strip() if m else ""
kw = section("Keywords").splitlines()[0] if section("Keywords") else ""
check(0 < len(kw) <= 100, f"Keywords fit in 100 characters ({len(kw)})", f"keywords are {len(kw)} characters")
promo = section("Promotional text").splitlines()[0] if section("Promotional text") else ""
check(0 < len(promo) <= 170, f"Promotional text fits in 170 characters ({len(promo)})", f"promotional text is {len(promo)} characters")
name = re.search(r"\*\*Name:\*\*\s*([^\(\n]+)", store)
check(bool(name) and len(name.group(1).strip()) <= 30, "App name fits in 30 characters", "app name missing or too long")
sub = re.search(r"\*\*Subtitle:\*\*\s*([^\n]+)", store)
check(bool(sub) and len(sub.group(1).strip()) <= 30, "Subtitle fits in 30 characters", "subtitle missing or too long")
check("Game Center" not in store or (gc_flag and gc_flag.group(1) == "true"), "Listing doesn't promise Game Center play",
      "APPSTORE.md mentions Game Center but it's switched off in the app (Guideline 2.3)")
for doc in ["PRIVACY.md", "SUPPORT.md", "docs/apple-compliance-report.md", "docs/testflight-release-checklist.md",
            "docs/app-review-notes.md", "docs/privacy-security-audit.md", "docs/external-tester-guide.md"]:
    check(os.path.exists(os.path.join(ROOT, doc)), f"{doc} exists", f"{doc} is missing")
privacy = read(os.path.join(ROOT, "PRIVACY.md"))
check("Playing with others" in privacy and "Game Center" not in privacy, "PRIVACY.md describes live play as it ships (Nearby only)",
      "PRIVACY.md is out of date with the live-play settings")

# The Privacy Policy and Support URLs in App Store Connect point at the main branch on GitHub.
try:
    main_privacy = subprocess.run(["git", "-C", ROOT, "show", "origin/main:PRIVACY.md"], capture_output=True, text=True, timeout=20)
    if main_privacy.returncode == 0:
        check(main_privacy.stdout.strip() == privacy.strip(), "Published privacy policy (main branch) matches this release",
              "the PRIVACY.md on main (what reviewers open) differs from this branch: merge before submitting")
    else:
        record("MANUAL", "Published privacy policy matches this release", "couldn't read origin/main (fetch it, or check the URL by hand)")
except Exception:  # noqa: BLE001
    record("MANUAL", "Published privacy policy matches this release", "git not available here")

# ---------------------------------------------------------------- always manual
for item in [
    "Release build archives in Xcode (Product > Archive) and validates in the Organizer",
    "Tested on a real iPhone and iPad: first launch, onboarding, every menu card, Hop Village, background/foreground",
    "Privacy report from the archive (Organizer > Generate Privacy Report) lists the app and the widget, only UserDefaults + system boot time",
    "Widgets checked on a device: Buddy, Star Hop, Brain Bubble (home screen) and Lock Screen show no child name",
    "Export compliance answered at upload: only iOS-provided encryption (exempt)",
    "Age rating questionnaire (current version), Kids Category (6-8), privacy label 'Data Not Collected' entered in App Store Connect",
    "'What to Test' and version notes describe this build's actual changes (Guideline 2.3 / 2.5.19: no hidden features)",
    "Screenshots are current (6.9\" iPhone and 13\" iPad)",
]:
    record("MANUAL", item)

# ---------------------------------------------------------------- report
width = max(len(n) for _, n, _ in results)
for status in ("FAIL", "PASS", "MANUAL"):
    for st, n, d in results:
        if st == status:
            print(f"{st:6}  {n}" + (f"\n        → {d}" if d and st != "PASS" else ""))
fails = sum(1 for s, _, _ in results if s == "FAIL")
manual = sum(1 for s, _, _ in results if s == "MANUAL")
passes = sum(1 for s, _, _ in results if s == "PASS")
print(f"\n{passes} passed, {fails} failed, {manual} need a person to confirm")
if fails:
    print("RESULT: FAIL")
    sys.exit(1)
if manual and STRICT:
    print("RESULT: CONDITIONAL (strict mode treats manual items as not done)")
    sys.exit(2)
print("RESULT: CONDITIONAL — automated checks pass; finish the MANUAL items" if manual else "RESULT: PASS")
