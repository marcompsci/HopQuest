# HopQuest 2.0: App Review notes

Paste the **Notes for Review** section into App Store Connect (version 2.0 → App Review Information → Notes). Use the TestFlight section for **Test Information → Beta App Review**.

## Notes for Review (App Store)

HopQuest is a Kids Category app for ages 6–8, sold as a one-time purchase.

**What it doesn't have**
- No ads, no in-app purchases, no accounts or sign-in.
- No analytics or third-party SDKs, no links out of the app, and no internet use.
- All data (a first name, settings and progress) is stored only on the device.

**Grown-up settings** are behind a parental gate. Tap the gear ("Grown-ups") at the top of the home screen and type the answer to the multiplication shown (e.g. 7 × 8 = 56).

**Where to find things.** Complete onboarding with any name. The home page has **PLAY** (Hop Village) and **SURPRISE ME!**, with My Castle, Together and Stories below. A menu bar at the bottom opens these pages:

- **Adventures:** the story map (levels unlock in order from Meadow Street; short story scenes can be skipped and replayed from Stories) and Robot Lab.
- **Games:**
  - Stickers, Fort Friends, Pillow Bop, Bubble Kart, Star Dash, Star Hop
  - Breathe (a calm breathing exercise)
  - Level Maker (kids build Star Hop levels; saved on the device)
  - Sticker Scenes, Fridge Door
- **Learn:**
  - Coding Lab (a safe built-in Python, no network)
  - Reading Nook, Math Market, Science Lab, Music Maker, Writing Desk
  - learning places such as Rhyme Pond, Number Builder, Times Treehouse, Measure Meadow, Feelings Corner, Nature Trail, Calendar Corner, Compass Camp, Healthy Hut, Word Workshop, Ten Frame Farm, Sky Watch, Helper Town, Sound Shop, Number Line Lane, Color Lab, Even Steven, Animal Club, Opposite Island and Sentence Station
- **Mystery Mix** (on Learn) asks five questions from places already played. Learn also has subject chips (Words, Math, Science, World & Me, Art & Music).
- **Worlds:** the story worlds (Snowy Peaks, Sunny Shores, Jungle Journey and more), each with its own levels.
- **Together:** two players on one device.

**Widgets (WidgetKit extension in the same app).** Home-screen widgets: Buddy, Star Hop (a tap-to-play mini game) and Brain Bubble (one multiple-choice question). They:
- read and write a small App Group store on the same device
- use no network and collect nothing
- open the app with `hopquest://quickgame`, a link back into the app only
- on the Lock Screen, never show the child's name

**Grown-up extras (behind the gate):** a weekly play-time chart, certificates and printable practice sheets, Bedtime and a daily limit. Sharing or printing uses the iOS share sheet or Messages and is only reachable behind the gate.

**Nothing is switched on remotely.** There is no server and no feature flag fetched from anywhere: every feature described here is in the submitted binary (Guideline 2.5.19).

**Play with others.** It is OFF by default, and only a grown-up can turn it on: Grown-up settings → Hop Village → "Play with others" → **Nearby only**.

- Devices in the same room connect with Multipeer Connectivity, with no internet. iOS shows the Local Network prompt only then.
- Players see each other's buddies and can play Brain Duels: five preset multiple-choice questions.
- There is no chat, no free text, no voice and no images. The only name shared is the buddy's name (e.g. "Pip"), never the child's.
- Testing it needs two devices with HopQuest. Everything else works on one device.

**Coding Lab web preview.** The child's own page is shown in a web view with JavaScript off, a content policy blocking all network loads, and every navigation cancelled. It cannot reach the internet.

**Sign-in:** none required.

## Beta App Review (TestFlight) — Test Information

- **Beta App Description:** HopQuest is a cozy learning adventure for kids 6–8. Hop across roads and rivers, explore a village with reading, math, science and music games, learn to code, build forts, and race karts. There are no ads, no purchases, no accounts and no data collection.
- **What to Test:** see `docs/external-tester-guide.md` → "What to test".
- **Feedback email:** the developer's support email (required by TestFlight; put the address you want testers to reach).
- **Contact information:** first and last name, phone and email of the person Apple can contact about the beta (App Store Connect → TestFlight → Test Information).
- **Sign-in required:** No. There is no demo account because the app has no accounts.
- **Review notes:** use the App Store notes above.

## Answers for App Store Connect forms

- **Age rating:** see `APPSTORE.md` → "Age rating answers". Messaging and Chat: No. User-Generated Content: No. Unrestricted Web Access: No. Parental Controls: Yes. Cartoon or Fantasy Violence: Infrequent/Mild.
- **Privacy label:** Data Not Collected (app and widget).
- **Export compliance:** only the encryption built into iOS (exempt). `ITSAppUsesNonExemptEncryption` is set to NO in the Info.plist. The owner must confirm.
- **Content rights:** no third-party content. The songs in Music Maker are traditional or public domain (Twinkle Twinkle, Mary Had a Little Lamb, Hot Cross Buns, Ode to Joy), synthesized in the app.
