"""Pillow Bop Arena + Sticker Book art for HopQuest, in the buddy ink-outline style.

arena_island  800 x 380  floating grass island; walkable top edge at y = 50
cloud_platform 260 x 100 fluffy cloud; walkable top edge at y = 34
arena_bg      400 x 860  portrait sky backdrop with distant islands
pillow        180 x 120  white pillow (tinted per character in game)
icon_bop, brain_bubble, icon_stickers, sticker_locked  200 x 200
"""
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_characters import OUT, E, C, P, R, shine, star_path, light  # noqa: E402
from make_world import svg, heart  # noqa: E402


def island():
    rnd = random.Random(7)
    s = ""
    # rocky underside, tapering to a point
    s += P("M40 86 Q60 170 170 230 Q260 300 330 340 Q400 372 470 340 Q560 296 640 228 Q740 160 760 86 Z", "#B07A4F")
    s += P("M90 110 Q140 190 240 240 Q330 300 400 320 Q470 300 560 240 Q660 186 710 110 Z", "#C98F5E", False)
    for (x, y, w, h) in ((150, 140, 60, 26), (300, 200, 80, 30), (480, 190, 70, 28), (600, 140, 56, 24), (380, 270, 50, 22)):
        s += R(x, y, w, h, 12, "#9C6740", 4)
        s += shine(x + w * 0.3, y + h * 0.35, w * 0.18, h * 0.16, rot=0, op=0.3)
    # hanging roots / vines
    for x in (120, 210, 330, 470, 590, 690):
        ln = rnd.uniform(40, 90)
        s += P(f"M{x} 96 Q{x + 12} {96 + ln * 0.5} {x - 4} {96 + ln}", "none", 5)
        s += E(x - 4, 96 + ln, 9, 6, "#5CC46A", 4)
    # crystals peeking out
    for (x, y, col) in ((250, 160, "#B983FF"), (540, 150, "#5EC8F2"), (410, 230, "#FF7FC4")):
        s += P(f"M{x} {y} L{x + 14} {y - 30} L{x + 28} {y} L{x + 14} {y + 16} Z", col, 4)
        s += shine(x + 10, y - 10, 3, 9, rot=20, op=0.6)
    # grass cap with bumpy edge
    edge = "M24 70 "
    for i in range(24):
        x0 = 24 + i * 31.5
        edge += f"Q{x0 + 16} {104 + (i % 2) * 8} {x0 + 31.5} 96 "
    s += P(edge + "L776 70 Q776 50 756 50 L44 50 Q24 50 24 70 Z", "#5CC46A")
    s += R(40, 52, 720, 20, 10, "#7EDB7E", False)
    s += shine(140, 62, 60, 6, rot=0, op=0.45)
    # flowers and tufts on top
    for _ in range(22):
        x = rnd.uniform(50, 750)
        col = rnd.choice(["#FFFFFF", "#FFD93D", "#FF7FC4", "#B983FF"])
        s += C(x, 56, 5, col, 2) + C(x, 56, 2, "#FFB020", False)
    for x in (90, 260, 420, 600, 720):
        s += P(f"M{x - 10} 54 L{x - 4} 38 L{x} 52 L{x + 6} 36 L{x + 10} 54", "#3FA34D", 3)
    return s


def cloud():
    s = E(130, 92, 100, 7, "#000000", False, op=0.12)
    s += P("M20 70 Q4 70 6 52 Q8 32 34 34 Q40 6 76 10 Q100 -6 128 12 Q158 -4 182 16 Q216 10 224 36 "
           "Q256 36 254 58 Q252 76 230 76 Q130 84 20 70 Z", "#FFFFFF")
    s += P("M30 66 Q120 76 228 66 Q226 74 214 76 Q120 82 28 72 Z", "#DCEBFF", False)
    s += shine(70, 30, 26, 8, rot=-8, op=0.9)
    s += C(96, 54, 5, OUT, False) + C(160, 54, 5, OUT, False)
    s += P("M118 60 Q128 68 138 60", "none", 4)
    s += E(84, 64, 9, 5, "#FFB3C7", False, op=0.8) + E(172, 64, 9, 5, "#FFB3C7", False, op=0.8)
    return s


def backdrop():
    rnd = random.Random(3)
    s = '<defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">' \
        '<stop offset="0" stop-color="#9FD8FF"/><stop offset="0.55" stop-color="#D9F1FF"/>' \
        '<stop offset="1" stop-color="#FFE9C7"/></linearGradient></defs>'
    s += '<rect width="400" height="860" fill="url(#sky)"/>'
    # sun with soft rays
    for i in range(12):
        a = i * 30
        s += P("M320 120 L312 20 L328 20 Z", "#FFF6B3", False, op=0.5, rot=(a, 320, 120))
    s += C(320, 120, 44, "#FFE066", 5) + shine(306, 104, 12, 8)
    # distant floating islands (no outline, faded)
    for (x, y, w) in ((60, 300, 90), (310, 380, 70), (150, 560, 60), (340, 640, 80), (40, 700, 50)):
        s += P(f"M{x - w / 2} {y} Q{x} {y + w * 0.9} {x + w / 2} {y} Z", "#C7A5E8", False, op=0.55)
        s += R(x - w / 2 - 4, y - 8, w + 8, 12, 6, "#9ED8A6", False, op=0.7)
    # puffy background clouds
    for _ in range(9):
        x, y, r = rnd.uniform(0, 400), rnd.uniform(180, 820), rnd.uniform(18, 30)
        s += C(x, y, r, "#FFFFFF", False, op=0.7) + C(x + r, y + 4, r * 0.8, "#FFFFFF", False, op=0.7) \
            + C(x - r, y + 6, r * 0.7, "#FFFFFF", False, op=0.7)
    # sparkles
    for _ in range(14):
        x, y = rnd.uniform(10, 390), rnd.uniform(20, 840)
        s += P(star_path(x, y, rnd.uniform(4, 8), 0.4), "#FFFFFF", False, op=0.8)
    return s


def pillow():
    s = E(90, 112, 70, 7, "#000000", False, op=0.12)
    s += P("M18 30 Q8 14 24 12 Q90 26 156 12 Q172 14 162 30 Q172 60 162 90 Q172 106 156 108 "
           "Q90 94 24 108 Q8 106 18 90 Q8 60 18 30 Z", "#FFFFFF")
    s += P("M22 52 Q90 62 158 52 L158 68 Q90 78 22 68 Z", "#E0E0F0", False)
    s += shine(54, 36, 22, 7, rot=-6, op=0.9)
    for (x, y) in ((24, 18), (156, 18), (24, 102), (156, 102)):
        s += C(x, y, 4, "#E0E0F0", 3)
    s += P(star_path(130, 86, 9, 0.45), "#FFD93D", 3)
    return s


def icon_bop():
    s = E(100, 182, 70, 9, "#000000", False, op=0.15)
    for (rot, col) in ((-24, "#FF7FC4"), (24, "#7FD8FF")):
        s += (f'<g transform="rotate({rot} 100 104)">'
              + P("M40 78 Q34 66 46 64 Q100 74 154 64 Q166 66 160 78 Q166 104 160 130 Q166 142 154 144 "
                  "Q100 134 46 144 Q34 142 40 130 Q34 104 40 78 Z", col)
              + shine(66, 84, 16, 5, rot=-6, op=0.7) + '</g>')
    for (x, y, r) in ((38, 36, 14), (164, 40, 11), (100, 22, 10)):
        s += P(star_path(x, y, r, 0.42), "#FFD93D", 3)
    s += ('<text x="100" y="120" text-anchor="middle" font-family="Arial Rounded MT Bold, Arial, sans-serif" '
          f'font-weight="900" font-size="38" fill="#FFFFFF" stroke="{OUT}" stroke-width="5" paint-order="stroke">BOP!</text>')
    return s


def brain_bubble():
    s = C(100, 100, 80, "#E9D5FF", 6)
    s += C(100, 100, 80, "#B983FF", False, op=0.25)
    s += E(70, 62, 22, 12, "#FFFFFF", False, rot=-35, op=0.85)
    s += C(138, 140, 7, "#FFFFFF", False, op=0.7)
    # light bulb idea
    s += P("M100 52 Q134 52 136 86 Q136 104 120 116 L120 128 L80 128 L80 116 Q64 104 64 86 Q66 52 100 52 Z", "#FFE066", 5)
    s += R(82, 128, 36, 16, 5, "#B0B7C3", 4) + R(88, 144, 24, 8, 4, "#8A93A3", 3)
    s += P("M90 116 L90 96 Q100 86 110 96 L110 116", "none", 4, op=0.6)
    s += shine(84, 74, 8, 12, rot=-20, op=0.8)
    for (x, y) in ((44, 96), (156, 96), (100, 30)):
        s += P(f"M{x - 8} {y} L{x + 8} {y} M{x} {y - 8} L{x} {y + 8}", "none", 4)
    return s


def icon_stickers():
    s = E(100, 182, 70, 9, "#000000", False, op=0.15)
    s += R(30, 36, 140, 140, 18, "#FF9F45")
    s += R(42, 30, 128, 140, 16, "#FFFFFF")
    s += R(42, 30, 18, 140, 8, "#7C4DFF", 4)
    # three stickers on the page
    s += C(96, 70, 20, "#FFD93D", 4) + P(star_path(96, 70, 12, 0.45), "#FF7A59", 3)
    s += heart(140, 76, 18, "#FF7FC4", 4)
    s += R(84, 108, 66, 44, 14, "#7FD8FF", 4) + C(104, 126, 4, OUT, False) + C(130, 126, 4, OUT, False) \
        + P("M108 138 Q117 145 126 138", "none", 3)
    s += P("M150 108 L150 126 L134 108 Z", "#E0E0F0", 3)  # peeling corner
    return s


def sticker_locked():
    s = R(20, 20, 160, 160, 34, "#E9E3F5", 6)
    s += R(20, 20, 160, 160, 34, "none", False)
    s += ('<text x="100" y="128" text-anchor="middle" font-family="Arial Rounded MT Bold, Arial, sans-serif" '
          f'font-weight="900" font-size="90" fill="#C9BCE3" stroke="{OUT}" stroke-width="5" paint-order="stroke">?</text>')
    s += shine(60, 46, 18, 8, op=0.7)
    return s


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    files = {
        "arena_island": svg(800, 380, island()),
        "cloud_platform": svg(260, 100, '<g transform="translate(0 12)">' + cloud() + "</g>"),
        "arena_bg": svg(400, 860, backdrop()),
        "pillow": svg(180, 120, pillow()),
    }
    for name, fn in {"icon_bop": icon_bop, "brain_bubble": brain_bubble,
                     "icon_stickers": icon_stickers, "sticker_locked": sticker_locked}.items():
        files[name] = svg(200, 200, fn())
    for name, body in files.items():
        open(os.path.join(out, f"{name}.svg"), "w").write(body)
    print(len(files))
