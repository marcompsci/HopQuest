# HopQuest — Game Design Brief (v1.0)

A kid-safe, educational hop-and-drive adventure for iPhone and iPad (ages ~5–10).
Kids hop across roads and rivers, learn to drive at Driving School, build and code a robot,
and finish every level by jumping into a hot air balloon at their castle.

---

## 1. What's in the v0.1 build

| Area | What works now |
|---|---|
| Onboarding | Name (first name / nickname only) → Girl / Boy / "I'd rather not say" → pick castle (one pre-selected "Made for you") → pick a buddy |
| Characters | 23 original characters in 4 families: Retro Pets (incl. **Lavender Lop**, the purple bunny), Hero Squad, Garden Gang (fruits & veggies), Zoo Crew. "Picked for you" row is based on the chosen castle; all characters open to everyone |
| Hop levels (3) | Crossy-road style rows of grass, roads, and rivers with logs. Tap to hop, swipe to steer, optional on-screen arrow pad. **Brain Gates** every 8–10 rows ask a math, road-safety, nature, science, or word question |
| Kid-friendly crashes | Cars give a cartoon "BOING!" with spinning stars; water gives "SPLISH!" bubbles. You float back to the last safe row with a safety tip. No lives, no game over, nothing scary |
| Driving School (2) | Racing feel (speedometer, coins, finish line) that teaches: red/yellow/green lights, full stops at STOP signs, school-zone speed limit, turn signal before lane change, safe following distance |
| Robot Lab (1) | Build a robot in the right order (chassis → battery → motors → wheels → sensors → brain), each part explained in 10-year-old language. Then program it with Forward / Left / Right commands to reach a star |
| Castles | Sparkle Castle, Stone Fortress, Rainbow Castle — shown on the map, at every finish line, and on the balloon |
| Balloon transition | At the finish the character jumps into the basket and floats away → full-screen flight that shrinks big-to-little → the tiny balloon drops and bounces onto the next level on the map |
| Grown-ups area | Typed multiplication parental gate → edit name/castle, stretch-break reminder (15–45 min), reset progress, privacy summary |
| Read-aloud (v0.2) | Built-in iOS voice reads onboarding, every Brain Gate question with its choices, right/wrong feedback, hop and driving tips, Robot Lab lessons, map arrivals, and break reminders. 🔊 replay buttons on questions, lessons, and onboarding. Grown-ups can turn it off in settings |
| Grown-up & Me (v0.3) | "Together" button on the map. **Team Hop**: two characters on one board; left half of the screen moves the kid, right half moves the grown-up; nobody can get more than 5 rows ahead ("Teams stick together!"); the first one at the castle cheers for the other, then both jump into the balloon. **Team Drive**: kid holds GO/BRAKE on the left, grown-up steers lanes on the right. Brain Gates tell the kid to answer while grown-ups hint. Team play earns stars but never changes story progress. Grown-up picks their own character |
| Bubble Kart (v0.4) | Kart racing on the map (🏎️ button). 3 cups: Meadow Loop, Candy City, Castle Circuit. 4 racers, 3 laps, 4 lanes. Items from ? boxes: Bubble Shield (blocks one bump), Carrot Boost, Jelly Pad (drop behind you). Mud puddles and jelly make racers float in a bubble for a second — no crashes. Rainbow speed pads. **Math Gates**: a question across the road with one answer per lane; drive through the right one for a super boost. Gentle rubber-banding keeps races close. Auto-gas on by default. Podium with Race again; best medal per cup saved |
| Character art (v0.5) | All 23 buddies redrawn as full-body chibi game characters (big head, small body, arms and legs, ink outline, glossy eyes) with species-specific designs: bunny ears and tail, owl eye discs and wings, turtle shell, hatching chick, hero suits with capes and chest emblems, rubber-hose fruit and veggie mascots, giraffe neck, elephant trunk, rhino horn with a hard hat that no longer covers the face. Art lives in Assets.xcassets (char_<id>); source generator in ArtSource/make_characters.py. Characters idle-bounce in game and ride in the karts and cars |
| Driving upgrade (v0.6) | Real-car controls: a steering wheel you turn (springs back, gentle lane-assist), blinker buttons that cancel themselves after a lane change, and pedals laid out like a car — brake on the left, gas on the far right (also in Bubble Kart). Smooth physics: pedals ease in, engine pulls softer near top speed, the car's nose turns with steering, look-ahead camera, 120 fps on ProMotion phones. New graphics: painted road with sidewalks, curbs and lane paint, detailed cars/vans/school bus with working brake lights and blinkers, overhead traffic lights that glow, STOP and SCHOOL road paint, crosswalk with kids waiting on the sidewalk, trees/houses, gold coins, speed lines and exhaust puffs, dial speedometer and a road progress bar. Teaches signaling (star for first signaled lane change), side bumps teach mirror checks |
| Sound & hop world (v0.7) | Original sound everywhere (all synthesized; no licensed audio): hops, coins, boings, splashes, countdown, item pickups, engine hum that rises with speed, blinker tick-tock, star chimes, level-complete fanfare. Two music loops: an adventure theme (map, hops, Robot Lab) and a racing theme (Driving School, Bubble Kart); music dips while the narrator talks. Grown-ups can turn music and sound effects off separately. Hop levels repainted: textured grass, roads with curbs and lane paint, animated water, side-view cars, school buses and trucks with friendly faces, wobbling wooden logs, lily-pad rafts on Lily River, trees and bushes. Characters now leap in an arc with squash-and-stretch, a ground shadow, and dust puffs on landing |
| Robot Lab redesign (v0.8) | All Robot Lab art redrawn from scratch in the buddy style (ArtSource/make_robot.py): six illustrated part cards (chassis, battery, motors, wheels, sensors, brain chip), a robot that assembles layer by layer on a blueprint workbench over a dashed outline, spinning motor gears, a glowing antenna, and a smile when it's finished. Wrong picks shake the card; a color progress bar fills as parts snap on. Coding grid restyled: tiled floor, a smiling goal star, the robot with a direction arrow, a dotted trail of where it's been, color-coded command buttons and numbered code chips that light up as each step runs. Finish screen: the robot dances |
| World art pass (v0.9) | Everything left in emoji or flat shapes redrawn in the buddy style (ArtSource/make_world.py): painted world-map landscape with tree clumps, a pond and village houses, a winding dirt road between levels, illustrated icons for every level plus a padlock and a gold star for finished levels; three illustrated castles (Sparkle, Stone Fortress, Rainbow) used on the map, at every finish line and in onboarding; striped hot air balloons with your buddy sitting inside the wicker basket (map, flight screen, levels); Bubble Kart and Together buttons with art; Bubble Kart ? boxes, Bubble Shield, Carrot Boost and Jelly Pad drawn as art in the race, HUD and how-to; Brain Gate card hosted by Ollie Owl with lettered, color-coded answers |
| Pillow Bop Arena (v1.0) | The Smash-style party mode, made gentle. You and 3 buddy bots on a floating island with two cloud platforms and a high cloud. Walk, jump, double-jump, and swing a fluffy pillow (BOP!). Every bop scores a point; bopped buddies get giggly (a meter on the scoreboard), and the gigglier you are, the farther a bop pushes you. Fall off and a hot air balloon floats you back after 2 seconds, no "KO". Pushing someone off earns a +2 bonus. Brain Bubbles float in twice a match: pop one, answer the Brain Gate, and get a GIANT pillow for 10 seconds. 60-second matches, stars for placing and for Brain Bubbles, feathers and "FLUFF!" pop words, and friendly bots that never gang up on the player |
| Sticker Book (v1.0) | Collect all 23 buddies. Every 6 stars earns a sticker pack; opening one flips over a die-cut sticker of a new buddy and reads its fun fact aloud. Stickers are grouped by family with progress bars; tap one to hear its fact or play as that buddy. Your own buddy is always in the book, and resetting progress never takes stickers away |
| Map dock (v1.0) | The world map's bottom dock holds Stickers (with a badge for unopened packs), Pillow Bop, and Bubble Kart; level stops moved up so nothing overlaps |
| Privacy | No network calls, ads, purchases, chat, analytics, or accounts. Profile stored locally only |

Characters are original vector illustrations generated from ArtSource/make_characters.py (rendered to PNG); everything else is drawn in code. No third-party images to license. Swap in real illustrated art later without changing game logic.

---

## 2. Characters & copyright

The original request asked for characters "inspired by" specific Disney, Marvel, DC, and Fortnite characters with small changes (a recolor, an older design). That doesn't make them safe to ship: characters are protected as characters, so a recolored or retro version of a recognizable one is still that character — and "old" designs are still owned (the very earliest Mickey is the rare public-domain exception, and the trademark still isn't). Apple also rejects apps that use other companies' characters without a license.

So HopQuest's cast is **original**, built to hit the same feelings kids love:

| Kids love… | HopQuest's original answer |
|---|---|
| A cute mischievous alien pet / ocean adventurer | Retro Pets — Coral Turtle (ocean explorer), Mochi Cat, Pixel Pup, Ollie Owl, Sunny Chick |
| Superheroes | Hero Squad — Captain Comet (fox, cape), Midnight Mask (raccoon), Star Spark (unicorn, cape), Iron Acorn (squirrel), Nova Wing (butterfly) |
| A cuddly bunny hero | **Lavender Lop** — our own purple bunny with her own look (round face, tall lavender ears, pink cheeks) |
| Food characters | Garden Gang — Benny Banana, Stella Strawberry, Sir Broccoli, Carlos Carrot, Gigi Grape, Avi Avocado |
| Zoo animals | Zoo Crew — Leo Lion, Zara Zebra, Gemma Giraffe, Pip Penguin, Ellie Elephant, Rocky Rhino |

Rule for future characters: design from a feeling ("brave tiny hero"), never from an existing character. If a description would make a kid say the other character's name, start over. Licensing a real property later is possible, but it's a business deal, not a design tweak.

**Game modes are different:** mechanics like kart racing with items, knock-out-of-the-ring party battles, or building are not owned by anyone. HopQuest can borrow those freely (see §6) — just not names, characters, logos, music, or level layouts.

---

## 3. Boy / Girl / "I'd rather not say"

Implemented the way the request described, with one guardrail:

- The onboarding answer **pre-selects** a castle (Girl → Sparkle Castle, Boy → Stone Fortress, Not saying → Rainbow Castle) and fills the "Picked for you" character row.
- Kids can pick **any** castle and **any** character, and change them later. Robot Lab, Driving School, and every mode are open to everyone.

Why the guardrail: parents surveyed rate same-gender and gender-neutral toys as equally desirable, and younger parents increasingly look for brands that don't box kids in. Locking a girl out of the Stone Fortress or the Robot Lab would cost us those parents' trust (and App Store reviews), while pre-selecting still gives the "made for me" feeling.

---

## 4. What parents want (research summary)

| Finding | What HopQuest does |
|---|---|
| Kids want to play **with** their parents — about 3 in 4 kids ages 5–10 say so (ESA, 2025) | Grown-up & Me: Team Hop and Team Drive on one device (v0.3) |
| Parents value apps that build **logic, creativity, and hands-on skills** | Robot building + coding, Brain Gates, Driving School rules |
| Parents are wary of **manipulative design**: ~4 in 5 apps used by preschoolers had at least one manipulative feature (lures to keep playing, purchase pressure, forced ads) — JAMA Network Open study | No ads, no purchases, no streak guilt, no "come back!" notifications, clear exit (house button) on every screen, stretch-break reminder |
| Ads and in-app purchases are everywhere in kids' apps, often disguised as gameplay or pushed by characters | None. Characters never ask for money |
| 4 in 5 parents of 5–9 year-olds use parental controls; 92% require approval for purchases | Parental gate on settings; any future purchase or link goes behind it |
| Families value games as active (not passive) screen time that teaches resilience | No-fail design: wrong answers get a hint and another try; bumps are funny, not punishing |

### App Store Kids Category checklist
- No third-party advertising or analytics (Guidelines 1.3 / 5.1.4) — ✅ none included
- No personal data sent to third parties (no name, birthday, email, location, device IDs) — ✅ nothing leaves the device
- Parental gate before purchases, outside links, or settings — ✅ settings gated; keep this for anything added later
- Age band to choose at submission: **6–8** (fits 5–10)
- Also needed before submission: privacy policy URL, App Privacy "Data Not Collected" label, real app icon, screenshots

### Business model recommendation
Paid up front ($3.99–$6.99) or free with a **single** one-time "Unlock all worlds" purchase behind the parental gate. Avoid ads and consumable currencies entirely — "no ads, no tricks" is a selling point parents actively search for.

---

## 5. Educational design

| Subject | Where it lives |
|---|---|
| Road safety | Brain Gates + every hop road + all of Driving School |
| Driving rules | Lights, stop signs, school zones, signals, following distance — rewarded with stars, never punished |
| Engineering | Robot Lab build order and part explanations |
| Coding | Robot Lab command sequencing (sequence → debug → retry) |
| Math | Addition (easy), subtraction (medium), multiplication (hard) scale with level difficulty |
| Nature / science / reading | Brain Gate decks, character fun facts |

Tone rules: every wrong answer gets a hint, never a buzzer. Every mistake keeps the kid moving.

---

## 6. Roadmap — party, kart, and build modes

These borrow **mechanics** that made top kids' games great, with original everything else.

**Bubble Kart (kart-racing mode)** — ✅ v0.4 shipped the lane-racing version with Math Gates. Next: 2-player kart in Grown-up & Me, more cups, unlockable kart colors with stars. Original plan: 3D-ish lane racing on loop tracks. Items: Bubble Shield, Carrot Boost, Jelly Bounce Pad (instead of attack items). Getting hit = car bounces in a bubble for 1 second. Auto-steer + auto-gas assists for little kids. Grand Prix cups through each castle world.

**Pillow Bop Arena (party-brawler mode)** — ✅ shipped in v1.0 (1 player + 3 bots). Next: 2-player on one iPad, more arenas. 2–4 characters on a floating island; bop each other with giant pillows to push them toward the edge. Fall off → you float back in a balloon after 2 seconds (no "KO"). Score = bops landed, not damage.

**Fort Friends (build-and-explore mode)** — build ramps, bridges, and towers from blocks to reach balloons and treasure; a gentle rain cloud slowly shrinks the play area (the "storm," re-imagined). Cooperative goals only, no combat.

**Grown-up & Me (co-op)** — ✅ shipped in v0.3 (Team Hop + Team Drive). Next: Team Robot Lab (one builds, one codes) and two-kid sibling mode.

**Robot Lab 2** — add gears and ramps (simple machines), then loops ("repeat 3×") in the coding grid.

**More** — ✅ sticker book shipped in v1.0. Still to do: seasonal castle skins, VoiceOver labels on all game objects.

---

## 7. Next engineering steps

1. Build & run in Xcode on device; tune hop speed, car speed, and gate frequency with real kids.
2. Commission or generate original illustrated art + sound (soft boings, balloon whoosh, castle fanfare).
3. ~~Add narration for every Brain Gate question and tip~~ — done in v0.2 with the built-in voice. Later: swap in recorded voice acting for the characters.
4. Move levels to data files so new worlds don't need code changes.
5. Privacy policy + App Store Kids Category submission.

---

### Sources
- ESA, 2025 holiday survey — kids want to play with parents; parental-control and purchase-approval rates: https://www.theesa.com/what-do-kids-want-for-holiday-gifts-video-games-of-course-they-also-want-their-parents-to-game-alongside-them/
- WBKO coverage of the ESA survey (3 in 4 kids ages 5–10 want parents to play): https://www.wbko.com/2025/11/27/video-games-top-kids-holiday-wish-lists-study-finds
- Michigan Medicine / JAMA Network Open — manipulative design in apps used by young children: https://www.michiganmedicine.org/health-lab/design-tricks-commonly-used-monetize-young-childrens-app-use
- Advertising in young children's apps (Mott Children's Hospital study coverage): https://www.cpbj.com/watchdog-groups-call-for-ftc-to-stop-app-makers-deceptive-practices-with-children
- Parents' preferences for educational apps (logic, creativity, manual skills): https://dbc.wroc.pl/dlibra/publication/178069/edition/139301
- Apple Kids Category rules (no third-party ads/analytics, no data to third parties): https://9to5mac.com/?p=595904 and https://www.goodbarber.com/help/apple-rejection-r100/apple-rejection-apps-for-kids-a365/
- Parental gate requirement for purchases and links: https://uae.revera.legal/?p=707
- Parents' toy desirability by gender typing (Sex Roles, 2017): https://pmc.ncbi.nlm.nih.gov/articles/PMC6096664
- Parent attitudes toward gender-neutral products: https://strategyonline.ca/?p=107798
