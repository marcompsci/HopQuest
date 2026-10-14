"""World art for HopQuest in the buddy ink-outline style:
castles (3 themes), hot air balloons (back + basket front), map background,
level icons, menu icons, and Bubble Kart items.
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_characters import OUT, E, C, P, R, shine, star_path, dark, light  # noqa: E402


def svg(w, h, body, pad=0):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{-pad} {-pad} {w + 2 * pad} {h + 2 * pad}" '
            f'width="{w + 2 * pad}" height="{h + 2 * pad}">{body}</svg>')


def heart(cx, cy, s, color, stroke=4):
    d = (f"M{cx} {cy + s * 0.9} C{cx - s * 1.4} {cy - s * 0.1} {cx - s * 0.7} {cy - s * 1.1} {cx} {cy - s * 0.35} "
         f"C{cx + s * 0.7} {cy - s * 1.1} {cx + s * 1.4} {cy - s * 0.1} {cx} {cy + s * 0.9} Z")
    return P(d, color, stroke)


# ------------------------------------------------------------------ castles (400 x 420, ground at y 400)

THEMES = {
    "sparkle": dict(wall="#FFD6EC", wall2="#FFC2E2", roofs=["#C77DFF", "#B05CF2", "#C77DFF"], trim="#FFD93D",
                    door="#9B5DE5", flag="#FF7FC4", emblem="heart"),
    "fortress": dict(wall="#C3CEDD", wall2="#AEBBCE", roofs=["#3B5BA5", "#2F4A8A", "#3B5BA5"], trim="#F2B134",
                     door="#5A4632", flag="#F2B134", emblem="shield"),
    "rainbow": dict(wall="#FFF4C2", wall2="#FFE9A3", roofs=["#FF7A59", "#3CC9A0", "#4D96FF"], trim="#FF7FC4",
                    door="#3CC9A0", flag="#FFD93D", emblem="star"),
}


def cone(x, base_y, w, h, color):
    return P(f"M{x - w / 2} {base_y} Q{x - w * 0.18} {base_y - h * 0.55} {x} {base_y - h} "
             f"Q{x + w * 0.18} {base_y - h * 0.55} {x + w / 2} {base_y} Z", color) + \
        P(f"M{x - w * 0.12} {base_y - h * 0.15} Q{x - w * 0.05} {base_y - h * 0.5} {x} {base_y - h * 0.85}",
          "none", 3, op=0.3)


def flag(x, top_y, color):
    return (P(f"M{x} {top_y} L{x} {top_y - 34}", "none", 4)
            + P(f"M{x} {top_y - 34} Q{x + 18} {top_y - 40} {x + 30} {top_y - 30} Q{x + 18} {top_y - 22} {x} {top_y - 20} Z", color, 4))


def window(x, y, w, h, glass="#6C5CE7"):
    return (P(f"M{x - w / 2} {y + h / 2} L{x - w / 2} {y - h / 2 + w / 2} A{w / 2} {w / 2} 0 0 1 {x + w / 2} {y - h / 2 + w / 2} "
              f"L{x + w / 2} {y + h / 2} Z", glass, 4) + E(x - w * 0.15, y - h * 0.1, w * 0.12, h * 0.18, "#FFFFFF", False, op=0.5))


def battlements(x0, x1, y, h, color, n):
    s = ""
    step = (x1 - x0) / n
    for i in range(n):
        if i % 2 == 0:
            s += R(x0 + i * step, y - h, step, h + 4, 4, color)
    return s


def emblem(kind, cx, cy, t):
    if kind == "heart":
        return heart(cx, cy, 16, "#FF4F9A")
    if kind == "shield":
        return (P(f"M{cx - 18} {cy - 18} L{cx + 18} {cy - 18} L{cx + 18} {cy + 2} Q{cx + 18} {cy + 18} {cx} {cy + 26} "
                  f"Q{cx - 18} {cy + 18} {cx - 18} {cy + 2} Z", "#3B5BA5", 4)
                + P(star_path(cx, cy + 2, 10), t["trim"], 3))
    return P(star_path(cx, cy, 20), t["trim"], 4)


def castle(theme):
    t = THEMES[theme]
    wall, wall2, roofs = t["wall"], t["wall2"], t["roofs"]
    s = E(200, 404, 170, 14, "#000000", False, op=0.18)
    # side towers
    for i, x in enumerate((84, 316)):
        s += R(x - 36, 170, 72, 232, 6, wall2)
        s += shine(x - 18, 196, 8, 22, rot=0, op=0.3)
        s += cone(x, 176, 96, 120, roofs[0 if i == 0 else 2])
        s += flag(x, 56, t["flag"])
        s += window(x, 250, 22, 36)
        s += R(x - 44, 168, 88, 12, 6, t["trim"], 4)
    # center keep
    s += R(146, 110, 108, 292, 8, wall)
    s += shine(166, 140, 10, 30, rot=0, op=0.3)
    s += cone(200, 118, 140, 140, roofs[1])
    s += flag(200, -22, t["flag"])
    s += R(138, 106, 124, 14, 7, t["trim"], 4)
    s += window(200, 190, 30, 46)
    s += emblem(t["emblem"], 200, 252, t)
    # front wall with battlements
    s += battlements(52, 348, 292, 22, wall, 11)
    s += R(52, 290, 296, 112, 6, wall)
    if theme == "fortress":
        for y in (316, 342, 368):
            off = 0 if (y // 26) % 2 == 0 else 22
            for x in range(60 + off, 340, 44):
                s += R(x, y, 40, 22, 3, "none", 2, op=0.25)
    # gate
    s += P("M168 402 L168 348 A32 32 0 0 1 232 348 L232 402 Z", t["door"])
    s += P("M200 316 L200 402", "none", 3, op=0.35)
    s += C(190, 370, 3.5, t["trim"], False) + C(210, 370, 3.5, t["trim"], False)
    if theme == "rainbow":
        for i, col in enumerate(["#FF7A59", "#FFD93D", "#3CC9A0", "#4D96FF"]):
            r = 54 - i * 7
            s += P(f"M{200 - r} 348 A{r} {r} 0 0 1 {200 + r} 348", "none", 0)
            s += f'<path d="M{200 - r} 350 A{r} {r} 0 0 1 {200 + r} 350" fill="none" stroke="{col}" stroke-width="7"/>'
    for x in (100, 300):
        s += window(x, 340, 20, 30)
    # sparkles / decorations
    if theme == "sparkle":
        for (x, y, r) in ((30, 120, 12), (372, 150, 10), (250, 40, 8)):
            s += P(star_path(x, y, r, 0.35, 4), "#FFE066", 3)
        for x in (140, 260):
            s += C(x, 290, 7, "#7FD8FF", 3)
    elif theme == "fortress":
        s += R(186, 280, 28, 10, 3, t["trim"], 3)
    else:
        for (x, y) in ((34, 130), (366, 140)):
            s += P(star_path(x, y, 11, 0.4), "#FFD93D", 3)
    return s


# ------------------------------------------------------------------ balloon (220 x 380, basket center at 110,340)

def balloon_back(theme):
    t = THEMES[theme]
    a, b = t["roofs"][0], t["flag"]
    s = ""
    # ropes
    for x0, x1 in ((66, 70), (154, 150), (92, 94), (128, 126)):
        s += P(f"M{x0} 218 L{x1} 314", "none", 4)
    # envelope with stripes
    env = "M110 14 C 200 14 214 100 200 150 C 186 196 146 214 134 228 L86 228 C 74 214 34 196 20 150 C 6 100 20 14 110 14 Z"
    s += P(env, a)
    s += f'<clipPath id="env-{theme}"><path d="{env}"/></clipPath>'
    s += f'<g clip-path="url(#env-{theme})">'
    s += E(110, 120, 40, 140, b, False)
    s += E(110, 120, 14, 140, light(a, 0.35), False)
    s += P("M0 150 Q110 175 220 150 L220 170 Q110 195 0 170 Z", t["trim"], False)
    s += "</g>"
    s += P(env, "none")
    s += shine(62, 62, 14, 26, rot=20, op=0.45)
    s += R(84, 226, 52, 14, 5, "#8A5A35")
    # basket back half
    s += R(64, 312, 92, 56, 12, "#B97A49")
    return s


def balloon_front():
    s = P("M60 330 L160 330 L154 370 Q110 380 66 370 Z", "#D9A066")
    for y in (342, 356):
        s += P(f"M64 {y} L156 {y}", "none", 3, op=0.4)
    for x in (82, 100, 120, 138):
        s += P(f"M{x} 332 L{x - 2} 372", "none", 3, op=0.3)
    s += R(56, 322, 108, 14, 7, "#8A5A35")
    return s


# ------------------------------------------------------------------ icons (200 x 200)

def icon_meadow():
    s = E(100, 160, 80, 30, "#7CCB5B") + E(100, 156, 70, 22, "#9BE07A", False)
    for i, (x, y) in enumerate(((52, 138), (76, 122), (100, 138), (124, 122))):
        s += E(x, y, 8, 10, "#9C5B2E", False, op=0.75)
        for dx in (-7, 0, 7):
            s += C(x + dx, y - 12, 3.5, "#9C5B2E", False)
    s += P("M150 150 L150 96", "none", 6)
    for a in range(0, 360, 60):
        s += E(150 + 18 * math.cos(math.radians(a)), 80 + 18 * math.sin(math.radians(a)), 13, 13, "#FF7FC4")
    s += C(150, 80, 11, "#FFD93D")
    s += E(132, 122, 14, 7, "#34C77B", rot=-30)
    return s


def side_car(cx, cy, w, color):
    h = w * 0.5
    s = E(cx, cy + h * 0.55, w * 0.55, 8, "#000000", False, op=0.18)
    s += P(f"M{cx - w * 0.32} {cy - h * 0.1} Q{cx - w * 0.2} {cy - h * 0.75} {cx + w * 0.05} {cy - h * 0.75} "
           f"Q{cx + w * 0.3} {cy - h * 0.75} {cx + w * 0.38} {cy - h * 0.1} Z", color)
    s += R(cx - w / 2, cy - h * 0.15, w, h * 0.6, h * 0.25, color)
    s += P(f"M{cx - w * 0.2} {cy - h * 0.12} Q{cx - w * 0.14} {cy - h * 0.6} {cx} {cy - h * 0.6} L{cx} {cy - h * 0.12} Z", "#BFE6FF", 3)
    s += P(f"M{cx + w * 0.05} {cy - h * 0.12} L{cx + w * 0.05} {cy - h * 0.6} Q{cx + w * 0.22} {cy - h * 0.6} {cx + w * 0.3} {cy - h * 0.12} Z", "#BFE6FF", 3)
    s += C(cx + w * 0.12, cy - h * 0.38, 4, OUT, False) + C(cx + w * 0.22, cy - h * 0.38, 4, OUT, False)
    s += shine(cx - w * 0.3, cy, w * 0.08, 4, rot=0, op=0.4)
    for x in (cx - w * 0.28, cx + w * 0.28):
        s += C(x, cy + h * 0.45, h * 0.28, "#3A3D47") + C(x, cy + h * 0.45, h * 0.12, "#C9CED8", False)
    s += R(cx + w * 0.44, cy, 8, 10, 3, "#FFF3A0", 3)
    return s


def icon_driving():
    s = R(20, 150, 160, 26, 8, "#5B6170", False)
    for x in (36, 84, 132):
        s += R(x, 160, 30, 6, 3, "#FFFFFF", False)
    return s + side_car(100, 108, 130, "#FF5A5F")


def icon_robot():
    s = C(100, 34, 10, "#FF7FC4") + P("M100 44 L100 64", "none", 6)
    s += C(32, 112, 13, "#6CB8E0") + C(168, 112, 13, "#6CB8E0")
    s += R(36, 60, 128, 104, 40, "#8FD3F4") + shine(66, 82, 18, 8)
    s += R(54, 82, 92, 58, 24, "#2B3A67", 5)
    for x in (80, 120):
        s += E(x, 110, 14, 17, "#5EE6FF", 4) + C(x - 4, 104, 4.5, "#FFFFFF", False)
    s += P("M86 130 Q100 140 114 130", "none", 0)
    s += '<path d="M86 128 Q100 138 114 128" fill="none" stroke="#5EE6FF" stroke-width="5" stroke-linecap="round"/>'
    return s


def icon_lily():
    s = E(100, 150, 84, 30, "#5EC8F2") + E(100, 148, 70, 20, "#7FD8FF", False)
    s += P("M64 140 Q100 150 136 140", "none", 3, op=0.4)
    pad = "M100 132 L100 92 A54 30 0 1 1 72 98 Z"
    s += P("M100 128 L118 96 A52 28 0 1 1 82 96 Z", "#3FA34D")
    for i in range(6):
        a = -90 + i * 60
        x, y = 100 + 22 * math.cos(math.radians(a)), 86 + 14 * math.sin(math.radians(a))
        s += E(x, y - 4, 12, 20, "#FFB3DA", rot=a + 90)
    s += C(100, 82, 12, "#FFE066")
    return s


def icon_rally():
    s = P("M44 176 L44 30", "none", 8)
    s += P("M44 34 Q100 18 156 34 L156 104 Q100 88 44 104 Z", "#FFFFFF")
    for r in range(4):
        for c in range(6):
            if (r + c) % 2 == 0:
                x0 = 44 + c * 18.7
                s += R(x0, 36 + r * 17 - (c * 0.0), 18.7, 17, 0, OUT, False)
    s += P("M44 34 Q100 18 156 34 L156 104 Q100 88 44 104 Z", "none")
    s += C(44, 26, 9, "#FFD93D")
    for y, w in ((130, 70), (150, 100), (170, 60)):
        s += P(f"M{170 - w} {y} L170 {y}", "none", 6, op=0.5)
    return s


def icon_castle_hill():
    return f'<g transform="translate(14 8) scale(0.43)">{castle("rainbow")}</g>'


def icon_lock():
    s = P("M64 92 L64 66 A36 36 0 0 1 136 66 L136 92", "none", 16)
    s += f'<path d="M64 92 L64 66 A36 36 0 0 1 136 66 L136 92" fill="none" stroke="#C9CED8" stroke-width="8" stroke-linecap="round"/>'
    s += R(44, 86, 112, 92, 22, "#FFC83D") + shine(66, 104, 14, 8)
    s += C(100, 124, 13, OUT, False) + R(94, 128, 12, 26, 5, OUT, False)
    return s


def icon_kart():
    s = E(100, 176, 80, 9, "#000000", False, op=0.18)
    s += P("M30 140 L44 110 L120 110 L136 86 L160 86 L172 140 Z", "#7C4DFF")
    s += R(28, 134, 150, 22, 10, "#5B3BD6")
    s += shine(60, 120, 18, 5, rot=0, op=0.4)
    s += P("M118 110 L128 70", "none", 6) + R(116, 62, 24, 10, 5, "#3A3D47")
    s += C(122, 92, 15, "#FFD93D") + C(118, 88, 3, OUT, False) + C(127, 88, 3, OUT, False)
    for x, r in ((56, 24), (154, 20)):
        s += C(x, 158, r, "#3A3D47") + C(x, 158, r * 0.45, "#FFD93D", 4)
    for y, w in ((112, 30), (128, 22)):
        s += P(f"M{14} {y} L{14 + w} {y}", "none", 5, op=0.45)
    return s


def icon_together():
    s = heart(80, 104, 46, "#B983FF", 6) + heart(126, 116, 40, "#FF7FC4", 6)
    s += shine(62, 82, 10, 6) + shine(112, 98, 9, 5)
    for (x, y, r) in ((36, 40, 12), (168, 52, 9)):
        s += P(star_path(x, y, r, 0.4), "#FFD93D", 3)
    return s


def item_shield():
    s = C(100, 100, 78, "#BDEBFF", 6)
    s += C(100, 100, 78, "#7FD8FF", False, op=0.35)
    s += E(72, 66, 22, 12, "#FFFFFF", False, rot=-35, op=0.85)
    s += C(134, 136, 7, "#FFFFFF", False, op=0.7)
    s += P(f"M100 72 L124 82 L124 104 Q124 124 100 136 Q76 124 76 104 L76 82 Z", "#5EC8F2", 4)
    return s


def item_carrot():
    s = ""
    for a in (-30, 0, 30):
        s += E(128, 52, 12, 30, "#34C77B", rot=a + 40)
    s += P("M150 70 Q164 92 136 118 L56 172 Q42 178 40 164 L96 82 Q120 54 150 70 Z", "#FF8C2A")
    for (x0, y0, x1, y1) in ((96, 104, 112, 112), (78, 130, 92, 138), (118, 84, 132, 92)):
        s += P(f"M{x0} {y0} L{x1} {y1}", "none", 4, op=0.35)
    s += shine(110, 82, 8, 16, rot=40, op=0.45)
    for y in (150, 170, 188):
        s += P(f"M{150 + (y - 150) * 0.2} {y - 40} L{186} {y - 46}", "none", 5, op=0.4)
    return s


def item_jelly():
    s = E(100, 168, 72, 12, "#000000", False, op=0.15)
    s += P("M40 160 Q36 96 62 74 Q100 50 138 74 Q164 96 160 160 Q100 176 40 160 Z", "#FF7FC4")
    s += P("M54 82 Q100 56 146 82 Q132 102 118 92 Q100 112 82 92 Q68 102 54 82 Z", "#9C5B2E", 4)
    s += shine(64, 110, 9, 18, rot=10, op=0.5)
    s += E(84, 120, 7, 9, OUT, False) + E(116, 120, 7, 9, OUT, False)
    s += C(81, 116, 2.5, "#FFFFFF", False) + C(113, 116, 2.5, "#FFFFFF", False)
    s += P("M90 136 Q100 144 110 136", "none", 4)
    s += C(100, 56, 9, "#FF4D6D")
    return s


def item_box():
    s = E(100, 176, 70, 10, "#000000", False, op=0.15)
    s += R(30, 30, 140, 140, 28, "#FFD93D")
    s += R(30, 30, 140, 140, 28, "none", False)
    s += P("M30 70 Q30 30 70 30 L130 30 Q170 30 170 70", "none", 0)
    for i, col in enumerate(["#FF7A59", "#3CC9A0", "#4D96FF"]):
        s += R(40 + i * 0, 40 + i * 0, 0, 0, 0, col, False)
    s += R(42, 42, 116, 116, 20, "none", 4, op=0.25)
    s += shine(64, 56, 16, 8)
    s += ('<text x="100" y="134" text-anchor="middle" font-family="Arial Rounded MT Bold, Arial, sans-serif" '
          f'font-weight="900" font-size="104" fill="#7C4DFF" stroke="{OUT}" stroke-width="5" paint-order="stroke">?</text>')
    return s


def map_bg():
    """Portrait landscape, 400 x 860. Top 150 is transparent so the theme sky shows."""
    rnd = random.Random(7)
    s = ""
    # distant hills
    s += P("M0 190 Q60 120 140 168 Q210 110 290 160 Q350 120 400 150 L400 860 L0 860 Z", "#B9EA9C", False)
    s += P("M0 230 Q90 170 180 214 Q270 160 400 206 L400 860 L0 860 Z", "#A5E386", False)
    # main field
    s += P("M0 270 Q120 230 220 262 Q320 236 400 258 L400 860 L0 860 Z", "#9BE07A", False)
    for i in range(10):
        y = 300 + i * 56
        s += P(f"M0 {y} Q200 {y - 18} 400 {y}", "none", 0)
        s += f'<path d="M0 {y} Q200 {y - 20} 400 {y} L400 {y + 28} Q200 {y + 8} 0 {y + 28} Z" fill="#8FD86E" opacity="0.35"/>'
    # pond near Lily River (right, ~57%)
    s += E(352, 470, 52, 30, "#5EC8F2") + E(348, 466, 40, 20, "#7FD8FF", False)
    s += E(336, 462, 10, 5, "#3FA34D", False) + E(364, 474, 8, 4, "#3FA34D", False)
    # tree clumps along the edges
    def tree(x, y, r):
        return (E(x + 4, y + r * 0.9, r * 0.9, r * 0.3, "#000000", False, op=0.15)
                + R(x - 4, y + r * 0.4, 8, r * 0.7, 3, "#9C5B2E", 3)
                + C(x, y, r, "#3FA34D", 4) + C(x - r * 0.3, y - r * 0.3, r * 0.45, "#5CC46A", False)
                + shine(x - r * 0.35, y - r * 0.45, r * 0.18, r * 0.1))
    spots = [(24, 300), (372, 296), (20, 400), (30, 520), (16, 640), (380, 600), (370, 720), (26, 770), (378, 820), (60, 830)]
    for (x, y) in spots:
        s += tree(x, y, rnd.uniform(16, 22))
    # flowers
    for _ in range(46):
        x, y = rnd.uniform(10, 390), rnd.uniform(290, 850)
        col = rnd.choice(["#FFFFFF", "#FFD93D", "#FF7FC4", "#B983FF"])
        s += C(x, y, 3.2, col, False) + C(x, y, 1.2, "#FFB020", False)
    # little houses near Driving School (right, ~78%)
    for (x, y, col) in ((352, 690, "#E76F51"), (384, 664, "#6C7BD9")):
        s += R(x - 16, y - 8, 32, 24, 3, "#FFF4E0", 3) + P(f"M{x - 20} {y - 6} L{x} {y - 24} L{x + 20} {y - 6} Z", col, 3)
    return s


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    files = {}
    for th in THEMES:
        files[f"castle_{th}"] = svg(400, 420, castle(th), pad=30)
        files[f"balloon_{th}"] = svg(220, 380, balloon_back(th))
    files["balloon_front"] = svg(220, 380, balloon_front())
    files["map_bg"] = svg(400, 860, map_bg())
    for name, fn in {"level_meadow": icon_meadow, "level_driving": icon_driving, "level_robot": icon_robot,
                     "level_lily": icon_lily, "level_rally": icon_rally, "level_castle": icon_castle_hill,
                     "level_lock": icon_lock, "icon_kart": icon_kart, "icon_together": icon_together,
                     "item_shield": item_shield, "item_carrot": item_carrot, "item_jelly": item_jelly,
                     "item_box": item_box}.items():
        files[name] = svg(200, 200, fn())
    for name, body in files.items():
        open(os.path.join(out, f"{name}.svg"), "w").write(body)
    print(len(files))
