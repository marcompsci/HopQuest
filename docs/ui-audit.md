# UI audit: what made HopQuest feel generated, and what changed

_October 28, 2026 · audited against Emil Kowalski's `apple-design` skill (Apple's "Designing Fluid Interfaces", translated for SwiftUI)_

## The pattern

The original screens (map, karts, Pillow Bop, forts, stickers) have a real art style: thick ink outlines, flat fills, little stars, and soft ground shadows. The screens added later (Reading Nook, Math Market, Science Lab, Music Maker, Garden, Story Book) used emoji instead:

- emoji as hero art ("🦉📚", "🐻🛒", "🐙🔬")
- a different saturated color for every row
- "🎉" on every result
- emoji tacked onto titles ("Notice Board 📌", "Coding Lab 💻")

That mix is what reads as AI-made: a crafted game with templated screens bolted on. A single bouncy press animation on every button made it feel like a toy rather than something physical.

## Findings and fixes

| # | Skill principle | Finding | Fix |
|---|---|---|---|
| 1 | Craft (§16.7), Familiarity (§16.4) | The menu's Learn section was four full-width cards in four unrelated colors, with emoji icons. Everything else on the menu uses illustrated tiles. | New ink-outline icons for Reading, Market, Science, Music and Garden (`ArtSource/make_learn_icons.py`, drawn with the same helpers as `icon_kart`). The Learn places are now the same 2-column tiles as Games, with a progress line, under a "Learn" heading. Coding Lab's card uses its real `icon_code` art. |
| 2 | Familiarity, Craft | Learning places opened on emoji hero art ("🦉📚"), and the market's host "Benny Bear" doesn't exist in the game. | A shared `PlaceHeader`: the host buddy's real art (Ollie, Benny **Banana**, Ocho, Fizz), the place name, a speech bubble, and a stars pill. One layout for every place. |
| 3 | Simplicity, not minimalism (§16.6) | Game lists gave every row its own bright color (5 competing colors per screen). | `LearnGameCard` is now a white card. The place's single accent appears only on the icon tile, with SF Symbols instead of per-row emoji, plus a chevron for "goes somewhere". |
| 4 | Response (§1), Behavior over animation (§4) | Every button scaled to 92% with a bouncy spring (damping 0.55): wobbly and toy-like. | Press = 96% plus slight darkening, eased in 0.1 s on touch-down. Release = critically damped spring (response 0.3, damping 1). Reduce Motion keeps the darkening but drops the scale. |
| 5 | Springs over durations (§4), one vocabulary | 68 hand-picked springs and fixed `easeInOut(0.25)` page swaps. | `Views/Motion.swift`: `standard` (0.35/1.0), `snappy` (0.25/1.0), `present` (0.38/0.86), `celebrate` (0.42/0.68, rewards only), `press`, `release`. New and touched screens use them. |
| 6 | Spatial consistency (§7) | List→game used a full-screen slide in and a full-screen slide out the other way. | `pushIn` enters and leaves along the same edge. The list behind drifts 40 pt (`pushedBack`) instead of flying off. |
| 7 | Materialize, don't just pop (§12) | Panels scaled up from 80–85%, an exaggerated zoom. | `.panel` grows from 96% with a fade. Applied to all 9 panels (dialogue, notice board, house, garden, missions, duels, Bop intro). |
| 8 | Utility of feedback (§13), Delight (§16.8) | Every result card opened with "🎉"; the stars just appeared. | The host buddy cheers, and the stars land one by one with the celebrate spring, the only bounce in the flow. Reduce Motion shows them at once. |
| 9 | Typography (§15) | Every title and subtitle was heavy/black at default tracking, so there was no hierarchy. | Display tracking: -0.6 at 28+ pt, -0.3 at 20+ pt (`displayTracking`). Secondary lines dropped to medium/semibold at ~60% ink. Counts use monospaced digits. |
| 10 | Craft | Emoji glued onto titles and messages ("Missions 📜", "🏆 You finished…", "👨‍👩‍👧 Grown-ups only", "🔇 Sounds are off"). | Plain titles, or SF Symbol labels (trophy, lock.shield, speaker.slash, lightbulb, music.note). Emoji stay where they *are* the content (sticker fruit, kart scenery, story props). |
| 11 | Materials (§12) | The village "Today" pill was flat white at 92% opacity on top of moving pixel art. | Regular material with a soft shadow, so it reads as a layer over the world. |
| 12 | Progress clarity | Round progress was five identical dots. | A capsule for the current round that stretches as rounds advance, animated with the standard spring. |

## Left as-is, on purpose

- The hard offset shadows (radius 0, y 4–6) on cards are part of the game's toy-like visual identity and are consistent across the app.
- Gesture-driven springs with velocity handoff (§5–6) apply to dragged UI. HopQuest's drags are the village joystick and SpriteKit scenes, which already track 1:1.
- Emoji used as in-world content (kart scenery, story props, science objects) are illustrations of things, not UI chrome.

## Verify on device

- Main menu: the Learn section shows illustrated tiles.
- Reading Nook, Math Market, Science Lab and Music Maker: host header, white cards, a push/back transition.
- Finish a game: stars land one by one.
- Press any button: it sinks quickly and doesn't wobble.
- Turn on Reduce Motion: no scaling, just fades.
