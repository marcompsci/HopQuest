# External TestFlight: setup and tester guide

**TestFlight approval is not App Store approval.** External testing needs a *Beta App Review* of the build. Passing it lets up to 10,000 testers install the beta. The App Store version is reviewed again, separately and in full, when you submit it for release.

## Part 1: For the developer (App Store Connect)

1. **Upload a build (owner only).** Open `HopQuest.xcodeproj`, not the `.swiftpm`: only the Xcode project contains the widget. Choose Any iOS Device → Product → Archive → Validate App → Distribute App → App Store Connect → Upload. Wait for processing; you'll get an email. Export compliance is pre-answered in the Info.plist.
2. **Internal group (optional, no review needed).** TestFlight → Internal Testing → ＋ → name it (e.g. "Phoronomics team"). Add App Store Connect users and turn on the build.
3. **External group.** TestFlight → External Testing → ＋ → name it (e.g. "Family beta").
4. **Test information.** TestFlight → Test Information:
   - beta app description
   - feedback email
   - marketing URL
   - privacy policy URL
   - Beta App Review contact (name, phone, email)
   - sign-in required: **No**
   - notes

   The text is in `docs/app-review-notes.md`.
5. **Add the build to the external group.** Open the group → Builds → ＋ → pick the build → paste **What to Test** (below).
6. **Submit for Beta App Review.** The first build of a version always needs it. Later builds of the same version may not.
7. **Confirm approval.** The build's status changes to "Ready to Test" or "Approved", and you get an email.
8. **Public link (optional).** Open the group → **Public Link** → Enable. Set a tester limit (for example 100) and optional criteria (for example iOS 17+). Copy the link.

   Share it only with people you trust: anyone with the link can join.
9. **Verify from outside.** Using a different Apple Account (not one on your developer team), on an iPhone with the TestFlight app:
   - open the public link
   - Accept → Install
   - check that the build number matches
   - send a test screenshot with feedback

## Part 2: What to Test (paste into App Store Connect, 4,000 characters max)

Thanks for testing HopQuest 1.0! Please try:

1. **First launch:** type a name (or leave it blank), pick a buddy and a castle.
2. **Home page:** tap PLAY (Hop Village) and SURPRISE ME! Then use the menu bar at the bottom to visit Adventures, Games, Learn and Worlds, and come back Home. My Castle, Together and Stories are at the bottom of Home.
3. **Hop Village:**
   - walk around and visit the Reading Nook, Math Market and Coding Lab
   - plant something in the garden, and pick a pet
4. **Learn:** Reading Nook, Math Market, Science Lab, Music Maker, Writing Desk and the learning places (Rhyme Pond, Number Builder, Times Treehouse, Measure Meadow, Feelings Corner, Nature Trail and more). New in this build: Word Workshop, Ten Frame Farm, Sky Watch, Helper Town, Sound Shop and Number Line Lane, a Keep going card at the top of Learn, and help in every quiz: tap the speaker to hear the choices, see the missed questions at the end, and practise just the tricky ones. Did anything feel too hard or too easy for your child?
5. **Adventures and Worlds:** play Meadow Street to the end (a short story scene plays), then open a world from the Worlds page.
6. **Games:**
   - Bubble Kart, Pillow Bop, Fort Friends, Star Dash, Star Hop and Breathe
   - Level Maker: build a Star Hop level and play it
   - Sticker Scenes
7. **Widgets:** long-press the home screen → ＋ → HopQuest. Add the Buddy, Star Hop and Brain Bubble widgets, then play Star Hop (now 16 levels) and answer a Brain Bubble right on the home screen. If you add a Lock Screen widget, check it doesn't show your child's name.
8. **Grown-ups:** open the gear and answer the multiplication. Try:
   - the Progress page: chart, certificates and practice sheets
   - Bedtime and the daily limit
   - with two devices in the same room: "Play with others → Nearby only" on both, then a Brain Duel

Please tell us about:
- anything that froze, crashed or looked wrong
- text that was hard to read
- places where your child got stuck

Take a screenshot to send feedback right from TestFlight.

## Part 3: For testers (send with the invitation)

**You'll need**
- An iPhone or iPad on **iOS/iPadOS 17 or later**.
- The free **TestFlight** app from the App Store.
- An Apple Account. Kids should play on a parent's device or a device set up through Family Sharing.

**Install**
1. Open the invitation email or public link on the iPhone or iPad.
2. Tap **Accept**, then **Install** in TestFlight.

**Send feedback**
- Take a screenshot in the app, tap the TestFlight share option, and write what happened.
- Or open TestFlight → HopQuest → **Send Beta Feedback**.

**Good to know**
- HopQuest has no ads, purchases or accounts, and collects no data. Your child's name stays on the device.
- "Play with others" is off unless a grown-up turns it on. It works only with devices in the same room.
- Beta builds expire after 90 days. Your progress stays on the device if you install a newer build or the App Store version.
