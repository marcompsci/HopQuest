<p align="center"><img src="docs/icon.png" width="180" style="border-radius:40px" alt="HopQuest app icon"></p>

# HopQuest 🐰🎈🏰

**A kid-safe educational adventure for iPhone and iPad.** Hop across busy streets like a crossy-road game. Learn to drive in a gentle driving school. Build and code a robot. Race Bubble Karts. Build ramps and bridges to reach a fort. Bop friends with pillows on a floating island. Collect every buddy in a Sticker Book, then decorate a cozy castle home for them. Fly a hot air balloon to the castle at the end of every level. Along the way, kids answer quick "Brain Gate" questions about math, road safety, nature, science and words.

There's no blood, no bad words, no ads, no chat and no accounts. Every crash is soft and bouncy, and a wrong answer just gets a hint and another try.

> **HopQuest 2.0 (branch `feature/hop-village`, ready for App Store review): Hop Village, Coding Lab, Reading Nook, Math Market, two new worlds and more.** Press **PLAY** on the main menu to walk your buddy (and your pet) around a pixel-art village with seasons, weather, festivals, a garden and a house to decorate. Learn real HTML, CSS and Python in the Coding Lab, program a robot with sensors, solve gear and lever puzzles, hop through a second world, and play two-player games on one device. See [docs/VILLAGE_ARCHITECTURE.md](docs/VILLAGE_ARCHITECTURE.md) and [APPSTORE.md](APPSTORE.md).
>
> Built with SwiftUI, SpriteKit and AVFoundation, with no third-party dependencies.

---

## Hop Village (2.0 release)

| On the phone (3× pixel scale) | The whole village |
|:---:|:---:|
| <img src="docs/screenshots/hop-village.png" width="240"> | <img src="docs/art/village.png" width="420"> |

These images are rendered by `ArtSource/preview_village.py` from the same map, tiles and sprites the game uses. The on-screen controls aren't shown.

## Screenshots

> These previews are rendered from the game's real art files, using the same colors, sizes and layout values as the SwiftUI screens (`HopQuest.swiftpm/ArtSource/make_previews.py`). On-device captures will replace them.

| Welcome | Pick your buddy | World map |
|:---:|:---:|:---:|
| <img src="docs/screenshots/welcome.png" width="240"> | <img src="docs/screenshots/buddy-picker.png" width="240"> | <img src="docs/screenshots/world-map.png" width="240"> |

| My Castle | Fort Friends | Pillow Bop Arena |
|:---:|:---:|:---:|
| <img src="docs/screenshots/my-castle.png" width="240"> | <img src="docs/screenshots/fort-friends.png" width="240"> | <img src="docs/screenshots/pillow-bop.png" width="240"> |

| Code Club | Robot Lab | Brain Gate (Ollie Owl) |
|:---:|:---:|:---:|
| <img src="docs/screenshots/code-club.png" width="240"> | <img src="docs/screenshots/robot-lab.png" width="240"> | <img src="docs/screenshots/brain-gate.png" width="240"> |

| Sticker Book | Balloon flight |
|:---:|:---:|
| <img src="docs/screenshots/sticker-book.png" width="240"> | <img src="docs/screenshots/balloon-flight.png" width="240"> |

### Original art

Every character, castle, balloon, robot part and icon was drawn from scratch in one shared outlined, cartoon style. The SVG generators live in `ArtSource/`.

<img src="docs/art/characters.png" width="760">

<img src="docs/art/world.png" width="760">

<img src="docs/art/robot.png" width="760">

<img src="docs/art/arena.png" width="760">

<img src="docs/art/fort.png" width="760">

<img src="docs/art/home.png" width="760">

---

## What's in the game

| Mode | What kids do | What they learn |
|---|---|---|
| **Hop Village** | Walk anywhere with the joystick or by tapping. Every game has a building. Finish all 10 challenges to open your castle. Chat with 12 villagers, take on 7 missions (fix the clock, water the garden, deliver mail, hop the lily pads and more). Hop forward a few feet with the Hop button, even across water. **Seasons** follow the calendar, the **weather** changes daily (sun, clouds, wind, rain, snow), and Gemma Giraffe hosts a **festival** each week (7 in all, any of them playable any time from the notice board). **Your own house** on the hill can be painted and decorated, with a new decoration from every festival. A pop-quiz buddy drops by every 2 minutes with a follow-up question | Road safety, math, science, nature and words riddles; seasons and weather science; recall of what each game taught; exploring and wayfinding |
| **Coding Lab** 💻 | A building in the village (and a menu tile). Ocho the octopus teaches 24 beginner lessons in 3 tracks, and every lesson adds to a real project the child keeps and can remix: **Web Designer** (HTML & CSS: a live web page with fonts, flexbox and a CSS animation), **Python Coder** (print, variables, math, loops, if/else, functions with parameters and return, and the Hop-Skip counting game, run in a safe built-in Python), **Game Maker** (a Python star-catching game with speed, bubbles to dodge and a level-up). **Free Build** in each track: make your own project from the blocks you've learned | HTML tags, CSS colors, fonts, layout and animation; print, variables, loops, if/else, functions, return, remainders; events and game design |
| **Brain Duels** (live play) | Off until a grown-up turns it on. Then friends in the same room (or Game Center friends) see each other's buddies and can duel: 5 questions, fastest right answers win. Only buddy names are shared, never the child's name. No chat, ever | Quick recall, sportsmanship |
| **Hop levels** (Meadow Street, Lily River, Castle Hill, then **Snowy Peaks**: Frosty Path, Icy Lake, Peak Castle, then **Sunny Shores**: Sandy Path, Tide Pools, Lighthouse Point, then **Jungle Journey**: Vine Valley, Hippo River, Temple Top) | Hop across roads, rivers and lily pads to reach the castle, then across snowy roads and ice floes, then ride surfboards across the waves. Worlds after the first are data (`worlds.json`), not code | Looking both ways, timing, patience |
| **Brain Gates** | Ollie Owl asks a question, answered with lettered, color-coded buttons | Math, road safety, nature, science, words |
| **Driving School and City Rally** | Steer with a wheel, use the **brake** and **gas** pedals (gas on the far right, like a real car), use blinkers and stop at lights | Real road rules, in a kid-friendly way |
| **Robot Lab** | Build a robot part by part, then "code" it with arrow commands to reach the star | Engineering basics: chassis, battery, motors, wheels, sensors, microcontroller, sequencing |
| **Bubble Kart** | Kart racing with bubble shields, carrot boosts and jelly pads. Five cups, including **Snowy Slalom** and **Beach Boardwalk** with jump ramps. Paint your kart | Steering, items, fair play |
| **My Castle** | Tap the castle on the map to decorate your own room with furniture bought with stars, change the walls, invite Sticker Book buddies, and share treats with them (no hunger or guilt mechanics) | Creativity, planning, caring for others |
| **Code Club** | 9 coding puzzles after the robot is built: program the robot with Forward, Turn and **Repeat** blocks, then sensor blocks (**Repeat until ⭐**, **If blocked … else**) where one program must solve several maps. Plus the **Machine Workshop**: 6 puzzles with gears, levers and pulleys | Coding: sequences, loops, patterns, algorithms, conditionals, sensors; simple machines and the math behind them |
| **Fort Friends** | A building game with no fighting. Build ramps, blocks and bridges with bricks to reach balloons and a tree-house fort, while a sleepy rain cloud drifts along behind you. Six levels (Lily Lagoon, Treetop Towers and Moat Castle are new) plus **Builder's Island**, an endless sandbox that remembers what you built | Engineering: inclined planes, support, planning a budget of bricks, recycling |
| **Pillow Bop Arena** | A gentle party-brawler: walk, jump and swing a pillow to push three buddy bots toward the edge of a floating island. Falling off just means a balloon floats you back. Pop the Brain Bubble and answer it for a GIANT pillow. Four arenas: Cloud Island, **Ice Rink** (slippery), **Bouncy Castle** (springy) and **Moon Base** (low gravity) | Sportsmanship, timing, quick thinking |
| **Sticker Book** | Every 6 stars earns a sticker pack with a new buddy and a fun fact read aloud. Collect all 29 | Animal and nature facts, goal-setting |
| **Reading Nook** 📚 | Ollie Owl's library in the village: First Sounds, Build a Word (spelling), Word Pop (sight words), Rhyme Time and Read & Match (sentences). Up to 3 stars per game | Letter sounds, spelling CVC words, sight words, rhyming families, reading a sentence |
| **Math Market** 🛒 | Benny Bear's shop: Count the Coins, Pay Exactly (tap coins into a tray), Make Change, Better Buy and Shopping List. Coins and prices follow the Learning level | Coins, adding, subtracting, comparing |
| **Garden & pets** 🌻 | Six garden beds beside your house: plant, water once a day, pick. Plants never wilt. A pet (puppy, kitten, bunny or duckling) follows your buddy around the village | Plant science facts, patience |
| **Science Lab** 🔬 | Professor Ocho's five guess-then-test experiments: Sink or Float (watch it drop in the tank), Magnet Test, Plant Parts, Weather Watch, Solid/Liquid/Gas | Predicting and testing, magnetism, plants, weather, states of matter |
| **Music Maker** 🎹 | Rainbow keys (C to C, with do-re-mi) and drum pads, four synthesized instruments, Echo Me, Drum Copy, Learn a Song (four public-domain tunes) and an 8-step song builder | Pitch, patterns, rhythm, playing a melody |
| **Story Book** 📖 | Picture-book cutscenes with character voices between levels (once, skippable), replayable from the menu | Listening, sequencing a story |
| **Together mode** | A grown-up and a kid play on one device: Team Hop, Team Drive, **two-player Bubble Kart**, **two-player Pillow Bop**, **Team Robot Code** (take turns adding blocks, like pair programmers) and **Team Fort** (two builders, longer reach) | Co-op play, fair play, and talking it through |
| **Hot air balloon finish** | Your buddy rides a balloon from big to little and lands on the next level | |

**Kid- and parent-friendly by design:**
- **Onboarding:** the kid's name, plus girl / boy / "I'd rather not say". The kid also picks a castle: Sparkle Castle, Stone Fortress or Rainbow Castle.
- **29 original buddies** in five families: Retro Pets (including Lavender Lop, the purple bunny), Hero Squad, Garden Gang (fruits and veggies), Zoo Crew and Wild Pals (Kip, Fizz, Ocho, Flora, Polly and Buzzy).
- **Narrator:** reads questions, tips and lessons aloud, and the music ducks while it speaks.
- **Original music and sound effects**, synthesized in code or generated by `ArtSource/make_audio.py`.
- **Grown-ups area** behind a parent gate, with break reminders, narration and sound settings, plus a **Learning Report**: Brain Gate questions solved per subject (with first-try rates) and progress in every mode.
- **Learning level:** questions fit the child's age: picture counting for 4–5, the classic mix for 6–7, times tables and harder science and words for 8–10. Automatic mode adapts to how the child is doing.
- **Daily play limit** with a gentle "time to rest" goodbye. HopQuest has **no streaks, no daily-login rewards and no notifications**.
- **Accessibility:** text grows with the Text Size setting, right/wrong answers use a shape as well as a color, left-handed controls, Reduce Motion respected, VoiceOver labels.
- **iPad:** runs in any orientation, with the game in a tall play area in the middle.
- Saves only on the device, with no data collection. Live play is off until a grown-up turns it on, and shares only the buddy's name.

---

## Run it

1. Clone the repo and double-click **`HopQuest.swiftpm`**. It opens in Xcode 15 or later, or in Swift Playgrounds on iPad/Mac.
2. Choose an iPhone simulator or your connected iPhone, then press **Run** (⌘R).
3. To run on your own phone, set your signing team: change `teamIdentifier` in `Package.swift`, or use the Signing settings in Xcode.

Requires **iOS 17** or later.

## Tests

The village's logic (map, A* pathfinding, collision, movement, NPC behavior, save data) is plain Swift and has its own test runner:

```bash
Tests/VillageLogic/run.sh      # needs swiftc (Xcode command-line tools on a Mac, or any Swift toolchain)
Tests/CodeLab/run.sh           # the mini Python, all 24 lessons, every project, and Free Build
Tests/RobotLab/run.sh          # Code Club's robot language, every puzzle's solvability, and the Machine Workshop
python3 Tests/FortLevels/check_levels.py   # every Fort Friends level can be finished within its brick budget
Tests/Worlds/run.sh            # worlds.json decodes and passes every content check
Tests/Learn/run.sh             # Reading Nook, Math Market, Science Lab, Music Maker and Story Book: every round over hundreds of seeds
```

## Project layout

```
HopQuest.swiftpm/
├── App/            Entry point and screen routing (map → level → balloon → map)
├── Models/         Profile and save, characters, chapters, questions, narrator, sound and music
├── Scenes/         SpriteKit: HopVillageScene (+ Village* systems), HopScene, DriveScene, KartScene, BopScene, FortScene, plus art helpers
├── Views/          SwiftUI: onboarding, world map, quiz card, Robot Lab, kart, Fort Friends, Pillow Bop, Sticker Book, team mode, parent area
├── Assets.xcassets Character, world and robot art; music and sound effects
├── ArtSource/      Python generators for all art and audio, and the README previews
└── GAME_DESIGN.md  Full design brief, parent research, version history and roadmap
```

## Rebuilding the art

```bash
pip install playwright && playwright install chromium
cd HopQuest.swiftpm/ArtSource
python3 render.py           # characters
python3 render_robot.py     # Robot Lab parts
python3 render_world.py     # castles, balloons, map, icons, kart items
python3 render_arena.py     # Pillow Bop island, clouds, pillow, Brain Bubble, Sticker Book icons
python3 render_fort.py      # Fort Friends tiles, pieces, crates, fort, rain cloud
python3 render_code.py      # Code Club rock, loop and menu icons
python3 render_home.py      # My Castle furniture, room, and treats
python3 make_icons.py icons # app icon options
python3 make_village.py ../Assets.xcassets ..   # Hop Village pixel art, buddy animation sheets, map + atlas Swift files
python3 make_previews.py ../Assets.xcassets ../../docs/screenshots
```

## Design notes

All characters are **original designs**. They're inspired by the *feel* of classic cartoon pets, superheroes and zoo animals, but they don't copy any existing character. See [`GAME_DESIGN.md`](HopQuest.swiftpm/GAME_DESIGN.md) for the full brief, the research on what parents want from kids' apps, the App Store Kids category checklist and the roadmap.

---

[Privacy Policy](PRIVACY.md) · [Support](SUPPORT.md)

© Phoronomics. All rights reserved.
