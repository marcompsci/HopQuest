<p align="center"><img src="docs/icon.png" width="180" style="border-radius:40px" alt="HopQuest app icon"></p>

# HopQuest 🐰🎈🏰

**A kid-safe educational adventure for iPhone and iPad.** Hop across busy streets like a crossy-road game. Learn to drive in a gentle driving school. Build and code a robot. Race Bubble Karts. Build ramps and bridges to reach a fort. Bop friends with pillows on a floating island. Collect every buddy in a Sticker Book, then decorate a cozy castle home for them. Fly a hot air balloon to the castle at the end of every level. Along the way, kids answer quick "Brain Gate" questions about math, road safety, nature, science and words.

There's no blood, no bad words, no ads, no chat and no accounts. Every crash is soft and bouncy, and a wrong answer just gets a hint and another try.

> Version **1.4**: My Castle (decorate your home and care for your buddies), learning levels that adapt to each child, and a gentle daily play limit. Built with SwiftUI, SpriteKit and AVFoundation, with no third-party dependencies.

---

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
| **Hop levels** (Meadow Street, Lily River, Castle Hill) | Hop across roads, rivers and lily pads to reach the castle | Looking both ways, timing, patience |
| **Brain Gates** | Ollie Owl asks a question, answered with lettered, color-coded buttons | Math, road safety, nature, science, words |
| **Driving School and City Rally** | Steer with a wheel, use the **brake** and **gas** pedals (gas on the far right, like a real car), use blinkers and stop at lights | Real road rules, in a kid-friendly way |
| **Robot Lab** | Build a robot part by part, then "code" it with arrow commands to reach the star | Engineering basics: chassis, battery, motors, wheels, sensors, microcontroller, sequencing |
| **Bubble Kart** | Kart racing with bubble shields, carrot boosts and jelly pads (three cups) | Steering, items, fair play |
| **My Castle** | Tap the castle on the map to decorate your own room with furniture bought with stars, change the walls, invite Sticker Book buddies, and share treats with them (no hunger or guilt mechanics) | Creativity, planning, caring for others |
| **Code Club** | 5 coding puzzles after the robot is built: program the robot with Forward, Turn and **Repeat** blocks, steer around rocks, collect gears, and try to use as few blocks as possible | Coding: sequences, loops, patterns, planning (algorithms), shapes |
| **Fort Friends** | A building game with no fighting. Build ramps, blocks and bridges with bricks to reach balloons and a tree-house fort, while a sleepy rain cloud drifts along behind you | Engineering: inclined planes, support, planning a budget of bricks, recycling |
| **Pillow Bop Arena** | A gentle party-brawler: walk, jump and swing a pillow to push three buddy bots toward the edge of a floating island. Falling off just means a balloon floats you back. Pop the Brain Bubble and answer it for a GIANT pillow | Sportsmanship, timing, quick thinking |
| **Sticker Book** | Every 6 stars earns a sticker pack with a new buddy and a fun fact read aloud. Collect all 23 | Animal and nature facts, goal-setting |
| **Together mode** | A grown-up and a kid play side by side (Team Hop and Team Drive) | Co-op play and talking it through |
| **Hot air balloon finish** | Your buddy rides a balloon from big to little and lands on the next level | |

**Kid- and parent-friendly by design:**
- **Onboarding:** the kid's name, plus girl / boy / "I'd rather not say". The kid also picks a castle: Sparkle Castle, Stone Fortress or Rainbow Castle.
- **23 original buddies** in four families: Retro Pets (including Lavender Lop, the purple bunny), Hero Squad, Garden Gang (fruits and veggies) and Zoo Crew.
- **Narrator:** reads questions, tips and lessons aloud, and the music ducks while it speaks.
- **Original music and sound effects**, synthesized in code or generated by `ArtSource/make_audio.py`.
- **Grown-ups area** behind a parent gate, with break reminders, narration and sound settings, plus a **Learning Report**: Brain Gate questions solved per subject (with first-try rates) and progress in every mode.
- **Learning level:** questions fit the child's age: picture counting for 4–5, the classic mix for 6–7, times tables and harder science and words for 8–10. Automatic mode adapts to how the child is doing.
- **Daily play limit** with a gentle "time to rest" goodbye. HopQuest has **no streaks, no daily-login rewards and no notifications**.
- Saves only on the device, with no data collection.

---

## Run it

1. Clone the repo and double-click **`HopQuest.swiftpm`**. It opens in Xcode 15 or later, or in Swift Playgrounds on iPad/Mac.
2. Choose an iPhone simulator or your connected iPhone, then press **Run** (⌘R).
3. To run on your own phone, set your signing team: change `teamIdentifier` in `Package.swift`, or use the Signing settings in Xcode.

Requires **iOS 17** or later.

## Project layout

```
HopQuest.swiftpm/
├── App/            Entry point and screen routing (map → level → balloon → map)
├── Models/         Profile and save, characters, chapters, questions, narrator, sound and music
├── Scenes/         SpriteKit: HopScene, DriveScene, KartScene, BopScene, FortScene, plus art helpers
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
python3 make_previews.py ../Assets.xcassets ../../docs/screenshots
```

## Design notes

All characters are **original designs**. They're inspired by the *feel* of classic cartoon pets, superheroes and zoo animals, but they don't copy any existing character. See [`GAME_DESIGN.md`](HopQuest.swiftpm/GAME_DESIGN.md) for the full brief, the research on what parents want from kids' apps, the App Store Kids category checklist and the roadmap.

---

© Phoronomics. All rights reserved.
