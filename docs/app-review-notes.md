# HopQuest 2.0: App Review notes

Paste the **Notes for Review** section into App Store Connect (version 2.0 → App Review Information → Notes). Use the TestFlight section for **Test Information → Beta App Review**.

## Notes for Review (App Store)

HopQuest is a Kids Category app for ages 6–8, sold as a one-time purchase.

**What it doesn't have**
- No ads, no in-app purchases, no accounts or sign-in.
- No analytics or third-party SDKs, no links out of the app, and no internet use.
- All data (a first name, settings and progress) is stored only on the device.

**Grown-up settings** are behind a parental gate. Tap the gear ("Grown-ups") at the top of the home screen and type the answer to the multiplication shown (e.g. 7 × 8 = 56).

**New in 2.0, and where to find it.** Complete onboarding with any name, then:

- **PLAY** opens Hop Village, a walkable village. Its buildings open games:
  - Reading Nook and Math Market (new, beside the museum and the main road)
  - Coding Lab
  - the garden below the house on the hill (plant, water, pick a pet)
- **Home screen cards:**
  - Coding Lab (24 lessons: HTML/CSS, Python, game code; a safe built-in Python, no network)
  - Reading Nook, Math Market, Science Lab and Music Maker
  - Stickers, Fort Friends, Pillow Bop (four arenas) and Bubble Kart (five cups)
  - My Castle
- **Adventure Map:** story levels unlock in order, starting at Meadow Street.
  - Short story scenes play once after each level. They can be skipped and replayed from **Stories**.
  - Robot Lab leads to Code Club and the Machine Workshop.
  - Snowy Peaks, Sunny Shores and Jungle Journey open one after another after Castle Hill.
- **Together:** two players on one device (Team Hop, Team Drive, Bubble Kart, Pillow Bop, Team Robot Code, Team Fort).

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
- **Privacy label:** Data Not Collected.
- **Export compliance:** uses encryption, but only the encryption built into iOS (exempt). The owner must confirm.
- **Content rights:** no third-party content. The songs in Music Maker are traditional or public domain (Twinkle Twinkle, Mary Had a Little Lamb, Hot Cross Buns, Ode to Joy), synthesized in the app.
