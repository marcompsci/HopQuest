"""Generates HopQuest's 23 original character illustrations as SVG.

Style: chibi "vinyl toy" — big head, small body, stubby limbs, thick ink outline,
soft highlight blobs, glossy eyes. Every character is original to HopQuest.
Canvas: 400 x 440, ground at y ~418.
"""
import json
import os
import sys

OUT = "#2B1B3D"
SW = 6
W, H = 400, 440


def _stroke(stroke):
    if stroke is True:
        return f' stroke="{OUT}" stroke-width="{SW}" stroke-linejoin="round" stroke-linecap="round"'
    if stroke:
        return f' stroke="{OUT}" stroke-width="{stroke}" stroke-linejoin="round" stroke-linecap="round"'
    return ""


def E(cx, cy, rx, ry, fill, stroke=True, rot=0, op=1):
    t = f' transform="rotate({rot} {cx} {cy})"' if rot else ""
    o = f' opacity="{op}"' if op != 1 else ""
    return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{fill}"{_stroke(stroke)}{t}{o}/>'


def C(cx, cy, r, fill, stroke=True, op=1):
    return E(cx, cy, r, r, fill, stroke, 0, op)


def P(d, fill, stroke=True, op=1, rot=None):
    o = f' opacity="{op}"' if op != 1 else ""
    t = f' transform="rotate({rot[0]} {rot[1]} {rot[2]})"' if rot else ""
    return f'<path d="{d}" fill="{fill}"{_stroke(stroke)}{o}{t}/>'


def R(x, y, w, h, rx, fill, stroke=True, rot=None, op=1):
    t = f' transform="rotate({rot[0]} {rot[1]} {rot[2]})"' if rot else ""
    o = f' opacity="{op}"' if op != 1 else ""
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}"{_stroke(stroke)}{t}{o}/>'


def shine(cx, cy, rx, ry, rot=-30, op=0.35):
    return E(cx, cy, rx, ry, "#FFFFFF", False, rot, op)


def mix(hex_a, hex_b, t):
    a = [int(hex_a[i:i + 2], 16) for i in (1, 3, 5)]
    b = [int(hex_b[i:i + 2], 16) for i in (1, 3, 5)]
    return "#" + "".join(f"{round(x + (y - x) * t):02X}" for x, y in zip(a, b))


def dark(c, t=0.25):
    return mix(c, "#000000", t)


def light(c, t=0.45):
    return mix(c, "#FFFFFF", t)


# ---------------------------------------------------------------- faces

def eyes(cx=200, cy=192, dx=40, size=1.0, color=OUT):
    s = []
    for x in (cx - dx, cx + dx):
        s.append(E(x, cy, 15 * size, 20 * size, color, False))
        s.append(C(x - 5 * size, cy - 8 * size, 6.5 * size, "#FFFFFF", False))
        s.append(C(x + 5 * size, cy + 7 * size, 3 * size, "#FFFFFF", False))
    return "".join(s)


def brows(cx=200, cy=160, dx=40):
    return (P(f"M{cx - dx - 18} {cy - 6} L{cx - dx + 16} {cy + 4}", "none", 7)
            + P(f"M{cx + dx + 18} {cy - 6} L{cx + dx - 16} {cy + 4}", "none", 7))


def cheeks(cx=200, cy=222, dx=64, color="#FF7FA8"):
    return E(cx - dx, cy, 17, 10, color, False, op=0.55) + E(cx + dx, cy, 17, 10, color, False, op=0.55)


def smile(cx=200, cy=228, w=16, depth=14):
    return P(f"M{cx - w} {cy} Q{cx} {cy + depth} {cx + w} {cy}", "none", 5)


def open_smile(cx=200, cy=226, w=18):
    return (P(f"M{cx - w} {cy} Q{cx} {cy + 30} {cx + w} {cy} Z", "#8C2F4A", 5)
            + E(cx, cy + 13, 9, 6, "#FF8FB1", False))


def cat_mouth(cx=200, cy=222):
    return P(f"M{cx - 14} {cy} Q{cx - 7} {cy + 10} {cx} {cy} Q{cx + 7} {cy + 10} {cx + 14} {cy}", "none", 5)


def face(cx=200, cy=192, dx=40, mouth="smile", hero=False, cheek_dy=30, mouth_dy=34, cheek_dx=64, eye_size=1.0):
    s = eyes(cx, cy, dx, eye_size)
    if hero:
        s += brows(cx, cy - 32, dx)
    s += cheeks(cx, cy + cheek_dy, cheek_dx)
    if mouth == "smile":
        s += smile(cx, cy + mouth_dy)
    elif mouth == "open":
        s += open_smile(cx, cy + mouth_dy - 2)
    elif mouth == "cat":
        s += cat_mouth(cx, cy + mouth_dy - 4)
    return s


# ---------------------------------------------------------------- body kit

def shadow(w=100):
    return E(200, 418, w, 13, "#000000", False, op=0.18)


def legs(color, shoe=None, spread=38, top=352, h=54):
    shoe = shoe or dark(color, 0.15)
    s = ""
    for x in (200 - spread, 200 + spread):
        s += R(x - 22, top, 44, h, 20, color)
        s += E(x, top + h - 2, 28, 15, shoe)
    return s


def body(color, belly=None, cy=318, rx=80, ry=68):
    s = E(200, cy, rx, ry, color)
    if belly:
        s += E(200, cy + 12, rx * 0.62, ry * 0.66, belly, False)
    s += shine(200 - rx * 0.45, cy - ry * 0.4, rx * 0.22, ry * 0.18)
    return s


def arms(color, y=306, wave=False, hand=None):
    s = E(120, y, 22, 34, color, rot=30)
    if wave:
        s += E(286, y - 34, 22, 34, color, rot=-150)
    else:
        s += E(280, y, 22, 34, color, rot=-30)
    if hand:
        s += C(108, y + 24, 14, hand)
        s += C(298, y - 60 if wave else y + 24, 14, hand)
    return s


def head(color, cx=200, cy=180, rx=110, ry=100):
    return E(cx, cy, rx, ry, color) + shine(cx - rx * 0.45, cy - ry * 0.45, rx * 0.22, ry * 0.15)


def cape(color, top=262):
    d = (f"M152 {top} Q120 330 92 404 Q150 388 200 400 Q250 388 308 404 Q280 330 248 {top} Z")
    return P(d, color) + P(f"M200 {top + 20} Q205 340 200 396", "none", 4, op=0.4)


def star_path(cx, cy, r, inner=0.45, points=5):
    import math
    pts = []
    for i in range(points * 2):
        rr = r if i % 2 == 0 else r * inner
        a = -math.pi / 2 + i * math.pi / points
        pts.append(f"{cx + rr * math.cos(a):.1f} {cy + rr * math.sin(a):.1f}")
    return "M" + " L".join(pts) + " Z"


def emblem_star(cx=200, cy=322, r=24, color="#FFD93D"):
    return C(cx, cy, r + 10, "#FFFFFF") + P(star_path(cx, cy, r), color, 4)


def hose_arms(y=300, left_x=140, right_x=260, glove="#FFFFFF", wave=True):
    s = P(f"M{left_x} {y} Q{left_x - 34} {y + 10} {left_x - 46} {y + 40}", "none", 8)
    s += C(left_x - 48, y + 46, 15, glove)
    if wave:
        s += P(f"M{right_x} {y} Q{right_x + 34} {y - 10} {right_x + 44} {y - 46}", "none", 8)
        s += C(right_x + 46, y - 52, 15, glove)
    else:
        s += P(f"M{right_x} {y} Q{right_x + 34} {y + 10} {right_x + 46} {y + 40}", "none", 8)
        s += C(right_x + 48, y + 46, 15, glove)
    return s


def hose_legs(top=360, shoe="#FF5A5F"):
    s = ""
    for x, dx in ((172, -6), (228, 6)):
        s += P(f"M{x} {top} L{x + dx} {top + 44}", "none", 8)
        s += E(x + dx * 3, top + 50, 26, 14, shoe)
        s += shine(x + dx * 3 - 8, top + 45, 8, 4, rot=0, op=0.5)
    return s


def bow(cx, cy, color="#FF4F9A", scale=1.0):
    s = scale
    return (P(f"M{cx} {cy} L{cx - 34 * s} {cy - 22 * s} L{cx - 34 * s} {cy + 22 * s} Z", color)
            + P(f"M{cx} {cy} L{cx + 34 * s} {cy - 22 * s} L{cx + 34 * s} {cy + 22 * s} Z", color)
            + C(cx, cy, 10 * s, light(color, 0.2)))


def crown(cx, cy, w=90, color="#FFC83D"):
    h = w * 0.55
    d = (f"M{cx - w / 2} {cy} L{cx - w / 2} {cy - h * 0.7} L{cx - w / 4} {cy - h * 0.35} L{cx} {cy - h} "
         f"L{cx + w / 4} {cy - h * 0.35} L{cx + w / 2} {cy - h * 0.7} L{cx + w / 2} {cy} Z")
    return (P(d, color) + C(cx, cy - h - 2, 7, "#FF5A8A", 4)
            + C(cx - w / 4, cy - h * 0.18, 6, "#5EC8F2", 3) + C(cx + w / 4, cy - h * 0.18, 6, "#34C77B", 3))


def hard_hat(cx, cy, w=170, color="#FFC83D"):
    # sits ON TOP of the head; brim at cy, dome above. Never covers the eyes.
    return (P(f"M{cx - w * 0.42} {cy} Q{cx - w * 0.42} {cy - w * 0.48} {cx} {cy - w * 0.48} "
              f"Q{cx + w * 0.42} {cy - w * 0.48} {cx + w * 0.42} {cy} Z", color)
            + R(cx - w * 0.55, cy - 8, w * 1.1, 18, 9, dark(color, 0.1))
            + R(cx - 10, cy - w * 0.47, 20, w * 0.44, 8, light(color, 0.35), 4)
            + shine(cx - w * 0.2, cy - w * 0.3, 14, 8))


# ---------------------------------------------------------------- characters

def lavender():
    c, belly, inner = "#9B6BDF", "#E8DBFF", "#FFB3DA"
    s = shadow()
    s += C(292, 372, 22, "#FFFFFF")  # fluffy tail
    s += legs(c, shoe=light(c, 0.55))
    s += body(c, belly)
    s += arms(c, wave=True)
    for x, r in ((150, -12), (250, 12)):
        s += E(x, 70, 32, 78, c, rot=r) + E(x, 78, 15, 56, inner, False, rot=r)
    s += head(c, ry=96)
    s += E(200, 226, 46, 32, belly, False)
    s += face(mouth="smile", mouth_dy=40)
    s += P("M190 216 L210 216 L200 228 Z", "#FF7FB0", 4)
    s += R(192, 236, 16, 14, 4, "#FFFFFF", 4)
    return s


def pixelpup():
    c, belly, ear = "#F6B94A", "#FFF1D6", "#9C5B2E"
    s = shadow()
    s += f'<path d="M266 330 Q326 302 316 252" fill="none" stroke="{OUT}" stroke-width="28" stroke-linecap="round"/>'
    s += f'<path d="M266 330 Q326 302 316 252" fill="none" stroke="{c}" stroke-width="16" stroke-linecap="round"/>'
    s += legs(c, shoe=belly)
    s += body(c, belly)
    s += arms(c, wave=True)
    s += head(c)
    s += E(235, 182, 34, 30, ear, False, op=0.9)  # eye patch
    s += E(96, 196, 30, 62, ear, rot=18) + E(304, 196, 30, 62, ear, rot=-18)
    s += E(200, 232, 50, 36, belly, False)
    s += face(mouth="open", mouth_dy=44)
    s += E(200, 218, 16, 11, OUT, False) + C(195, 214, 4, "#FFFFFF", False)
    return s


def mochi():
    c, belly, inner = "#FFB3C7", "#FFE7EE", "#FF7FA8"
    s = shadow()
    s += f'<path d="M262 360 Q340 356 324 290 Q316 262 296 276" fill="none" stroke="{OUT}" stroke-width="30" stroke-linecap="round"/>'
    s += f'<path d="M262 360 Q340 356 324 290 Q316 262 296 276" fill="none" stroke="{c}" stroke-width="18" stroke-linecap="round"/>'
    s += legs(c, shoe=belly)
    s += body(c, belly)
    s += arms(c)
    for x, sgn in ((126, -1), (274, 1)):
        s += P(f"M{x - 34} 128 L{x + sgn * 14} 52 L{x + 40} 116 Z", c)
        s += P(f"M{x - 18} 120 L{x + sgn * 12} 76 L{x + 24} 116 Z", inner, False)
    s += head(c)
    s += face(mouth="cat")
    s += P("M192 212 L208 212 L200 220 Z", "#FF5A8A", 4)
    for y, dy in ((214, -6), (226, 4)):
        s += P(f"M118 {y} L72 {y + dy}", "none", 4) + P(f"M282 {y} L328 {y + dy}", "none", 4)
    s += bow(286, 92, "#FF4F9A", 0.9)
    return s


def ollie():
    c, belly, ring = "#4FB3A3", "#DDF4EE", "#F4FBF9"
    s = shadow(90)
    for x in (172, 228):
        s += P(f"M{x - 18} 404 L{x - 10} 384 L{x} 404 L{x + 10} 384 L{x + 18} 404", "#FFB020", 5)
    s += E(200, 312, 92, 86, c) + E(200, 330, 58, 60, belly, False)
    for y in (300, 330, 360):
        for x in (178, 200, 222):
            s += P(f"M{x - 9} {y} Q{x} {y + 10} {x + 9} {y}", "none", 3, op=0.5)
    s += E(116, 318, 26, 56, dark(c, 0.15), rot=18) + E(284, 318, 26, 56, dark(c, 0.15), rot=-18)
    s += P("M104 116 L118 54 L160 96 Z", c) + P("M296 116 L282 54 L240 96 Z", c)
    s += head(c, rx=116, ry=98)
    s += C(152, 186, 44, ring) + C(248, 186, 44, ring)
    s += eyes(200, 188, 48, 1.15)
    s += P("M200 204 L184 222 L200 246 L216 222 Z", "#FFB020", 5)
    s += cheeks(200, 236, 92)
    return s


def coral():
    skin, shell, rim, plast = "#7DD3A0", "#2E9E8F", "#1F7A6E", "#F7E7A6"
    s = shadow()
    s += E(200, 312, 112, 96, rim)
    for (x, y) in ((122, 268), (278, 268), (110, 330), (290, 330)):
        s += P(f"M{x - 18} {y} L{x} {y - 16} L{x + 18} {y} L{x} {y + 16} Z", light(shell, 0.4), 3)
    s += legs(skin, shoe=dark(skin, 0.1), spread=44)
    s += E(200, 320, 78, 70, plast)
    s += P("M140 300 L260 300 M136 334 L264 334 M200 258 L200 386", "none", 4, op=0.35)
    s += arms(skin, wave=True)
    s += head(skin, ry=94)
    s += face(mouth="open", mouth_dy=40)
    s += bow(260, 96, "#FF5A8A", 0.85)
    return s


def sunny():
    c, beak = "#FFE066", "#FF9F1C"
    s = shadow(90)
    for x in (174, 226):
        s += P(f"M{x} 380 L{x} 404", "none", 7)
        s += P(f"M{x - 16} 408 L{x} 398 L{x + 16} 408", "none", 6)
    s += E(200, 322, 84, 72, c)
    # eggshell skirt
    s += P("M116 330 L132 312 L152 332 L172 308 L192 332 L212 308 L232 332 L252 308 L272 332 L286 314 "
           "Q290 392 200 396 Q110 392 116 330 Z", "#FFFFFF")
    s += P("M160 360 L176 352 M226 372 L240 362", "none", 3, op=0.3)
    s += E(118, 288, 20, 34, light(c, 0.1), rot=40) + E(282, 288, 20, 34, light(c, 0.1), rot=-40)
    s += head(c, ry=98)
    for x, r in ((186, -20), (200, 0), (214, 20)):
        s += E(x, 84, 10, 24, c, rot=r)
    s += face(mouth=None)
    s += P("M184 222 L200 210 L216 222 L200 236 Z", beak, 5)
    return s


def comet():
    fur, suit, capec, white = "#FF8A4C", "#3B5BA5", "#E63946", "#FFF4E8"
    s = shadow()
    s += cape(capec)
    s += P("M262 360 Q340 380 346 300 Q350 250 316 236 Q332 300 270 330 Z", fur)
    s += P("M346 300 Q350 250 316 236 Q326 270 322 292 Z", white, 4)
    s += legs(suit, shoe="#FFD93D")
    s += body(suit, None)
    s += emblem_star()
    s += arms(suit, wave=True, hand=white)
    for x, sgn in ((120, -1), (280, 1)):
        s += P(f"M{x - 38} 136 L{x + sgn * 10} 40 L{x + 42} 120 Z", fur)
        s += P(f"M{x + sgn * 10} 40 L{x + sgn * 2 - 6} 72 L{x + sgn * 18 + 6} 72 Z", OUT, False)
    s += head(fur)
    s += P("M104 200 Q200 300 296 200 Q260 250 200 252 Q140 250 104 200 Z", white, False)
    s += face(hero=True, mouth="smile", mouth_dy=40)
    s += E(200, 214, 12, 8, OUT, False)
    return s


def midnight():
    fur, suit, capec, mask = "#8E99AE", "#4B3F99", "#2B1B3D", "#2F2A3E"
    s = shadow()
    s += cape(capec)
    s += P("M262 350 Q330 360 344 300", "none", 0)
    for i, col in enumerate([fur, OUT, fur, OUT, fur]):
        s += E(300 + i * 9, 352 - i * 18, 22, 14, col, 4, rot=-50)
    s += legs(suit, shoe="#FFD93D")
    s += body(suit)
    s += C(200, 322, 34, "#FFFFFF") + P("M212 300 A26 26 0 1 0 214 344 A20 20 0 1 1 212 300 Z", "#FFD93D", 4)
    s += arms(suit, hand=fur)
    s += C(118, 102, 30, fur) + C(282, 102, 30, fur) + C(118, 102, 14, mask, False) + C(282, 102, 14, mask, False)
    s += head(fur)
    s += P("M96 184 Q120 150 200 168 Q280 150 304 184 Q290 220 240 214 Q200 200 160 214 Q110 220 96 184 Z", mask, False)
    s += E(200, 236, 46, 30, "#E8ECF4", False)
    s += face(hero=True, mouth="smile", mouth_dy=46)
    s += E(200, 224, 12, 8, OUT, False)
    return s


def starspark():
    c, suit, capec = "#FFF5FA", "#F7A8E0", "#B983FF"
    mane = ["#B983FF", "#FF7FC4", "#7FD8FF", "#FFD93D"]
    s = shadow()
    s += cape(capec)
    s += legs(suit, shoe="#FFFFFF")
    s += body(suit)
    s += emblem_star(color="#B983FF")
    s += arms(suit, wave=True, hand=c)
    s += P("M112 110 L120 58 L156 92 Z", c) + P("M288 110 L280 58 L244 92 Z", c)
    s += head(c)
    for i, (x, y, r) in enumerate([(150, 90, 30), (190, 74, 32), (232, 80, 30), (270, 104, 26), (300, 140, 24), (310, 182, 22)]):
        s += C(x, y, r, mane[i % 4])
    s += P("M184 70 L200 -2 L216 70 Z", "#FFD93D")
    s += P("M190 52 L210 46 M194 32 L206 28", "none", 4)
    s += face(hero=True, mouth="smile", mouth_dy=40)
    s += E(200, 236, 46, 26, "#FFD6EC", False, op=0.8)
    return s


def acorn():
    fur, belly, armor, cap = "#C98A55", "#FFE9CF", "#C9D3E0", "#8A5A35"
    s = shadow()
    s += P("M250 360 Q370 360 356 230 Q346 130 270 140 Q330 180 320 250 Q312 320 250 330 Z", dark(fur, 0.05))
    s += P("M330 180 Q350 230 340 280", "none", 4, op=0.35)
    s += legs(fur, shoe="#6E4325")
    s += body(armor)
    s += P("M150 300 Q200 280 250 300 L246 360 Q200 376 154 360 Z", light(armor, 0.3), 4)
    s += E(200, 326, 16, 20, cap, 4) + P("M184 314 Q200 296 216 314 Z", dark(cap, 0.2), 4)
    s += arms(fur, wave=True, hand=belly)
    s += C(116, 116, 26, fur) + C(284, 116, 26, fur)
    s += head(fur)
    s += E(200, 230, 52, 34, belly, False)
    s += face(hero=True, mouth="smile", mouth_dy=42)
    s += E(200, 220, 12, 8, OUT, False)
    s += R(190, 238, 20, 14, 4, "#FFFFFF", 4)
    # acorn-cap helmet, sits on top of the head
    s += P("M104 128 Q110 52 200 50 Q290 52 296 128 Q200 108 104 128 Z", cap)
    for x in range(130, 280, 26):
        s += P(f"M{x} 70 L{x + 20} 118", "none", 3, op=0.35)
    s += R(192, 30, 16, 26, 6, dark(cap, 0.2), 4)
    return s


def novawing():
    c, suit = "#BDEBFF", "#5B8DEF"
    w1, w2 = "#7FD8FF", "#B983FF"
    s = shadow()
    s += E(110, 250, 92, 70, w1, rot=-30) + E(290, 250, 92, 70, w1, rot=30)
    s += E(126, 340, 62, 46, w2, rot=20) + E(274, 340, 62, 46, w2, rot=-20)
    for (x, y, r) in ((92, 238, 20), (308, 238, 20), (130, 344, 14), (270, 344, 14)):
        s += C(x, y, r, "#FFFFFF", 4) + C(x, y, r * 0.45, "#FF7FC4", False)
    s += legs(suit, shoe="#FFFFFF")
    s += body(suit)
    s += C(200, 322, 30, "#FFFFFF") + P("M200 322 L178 304 Q170 330 200 322 L222 304 Q230 330 200 322 Z", "#B983FF", 3)
    s += arms(suit, wave=True, hand=c)
    s += P("M168 98 Q150 50 128 38", "none", 6) + P("M232 98 Q250 50 272 38", "none", 6)
    s += C(126, 36, 13, "#FFD93D") + C(274, 36, 13, "#FFD93D")
    s += head(c)
    s += face(hero=True, mouth="open", mouth_dy=40)
    return s


def benny():
    c = "#FFE45C"
    s = shadow(80)
    s += hose_legs(shoe="#5B8DEF")
    s += P("M180 70 Q120 160 136 290 Q150 386 230 380 Q286 370 270 330 Q220 330 214 260 Q206 160 228 76 Z", c)
    s += P("M196 96 Q150 190 166 300", "none", 5, op=0.25)
    s += R(186, 44, 30, 36, 8, "#8A5A35", True, rot=(14, 200, 62))
    s += P("M262 340 Q280 352 274 366 Q262 366 258 350 Z", "#6E4325", 4)
    s += shine(166, 170, 12, 40, rot=10, op=0.45)
    s += hose_arms(y=290, left_x=144, right_x=256)
    s += face(cx=190, cy=206, dx=28, eye_size=0.85, mouth="open", mouth_dy=36, cheek_dx=44)
    return s


def stella():
    c, leaf = "#FF4D6D", "#34C77B"
    s = shadow(90)
    s += hose_legs(shoe="#FFB3DA")
    s += P("M200 400 Q90 330 90 200 Q92 120 200 130 Q308 120 310 200 Q310 330 200 400 Z", c)
    import random
    rnd = random.Random(3)
    for y in range(170, 360, 34):
        for x in range(120, 290, 34):
            if (x - 200) ** 2 / 110 ** 2 + (y - 250) ** 2 / 150 ** 2 < 0.8 and not (140 < x < 260 and 170 < y < 260):
                s += E(x + rnd.randint(-6, 6), y + rnd.randint(-6, 6), 4, 7, "#FFE08A", False)
    for a in (-60, -25, 10, 45, 80):
        s += E(200, 112, 18, 46, leaf, rot=a)
    s += R(192, 70, 16, 34, 6, dark(leaf, 0.2), 4)
    s += shine(140, 190, 16, 30, rot=20, op=0.4)
    s += hose_arms(y=280, left_x=104, right_x=296)
    s += face(cy=210, dx=36, mouth="smile", mouth_dy=36, cheek_dx=60)
    s += bow(272, 124, "#FFB3DA", 0.8)
    return s


def broccoli():
    stalk, flor = "#B7E4A1", "#3FA34D"
    s = shadow(80)
    s += hose_legs(shoe="#FFD93D")
    s += P("M146 230 L254 230 L240 380 Q200 396 160 380 Z", stalk)
    s += P("M178 300 L174 370 M222 300 L226 370", "none", 4, op=0.25)
    for (x, y, r) in ((110, 170, 46), (290, 170, 46), (150, 120, 52), (250, 120, 52), (200, 96, 56), (130, 222, 40), (270, 222, 40), (200, 180, 70)):
        s += C(x, y, r, flor)
    for (x, y) in ((140, 110), (230, 92), (280, 150), (110, 190), (200, 140), (260, 210), (160, 200)):
        s += C(x, y, 9, light(flor, 0.3), False)
    s += hose_arms(y=276, left_x=150, right_x=250, wave=False)
    s += face(cy=270, dx=28, eye_size=0.8, mouth="smile", mouth_dy=32, cheek_dx=42, cheek_dy=24)
    s += crown(200, 52, 88)
    return s


def carlos():
    c, leaf = "#FF8C2A", "#34C77B"
    s = shadow(80)
    s += hose_legs(shoe="#5B8DEF")
    for a in (-30, 0, 30):
        s += E(200, 92, 16, 44, leaf, rot=a)
    s += P("M120 140 Q200 104 280 140 Q266 290 200 400 Q134 290 120 140 Z", c)
    for y, w in ((236, 24), (290, 18), (336, 12)):
        s += P(f"M{200 - w - 30} {y} L{200 - 30 + w} {y + 4}", "none", 4, op=0.35)
    s += shine(152, 180, 14, 34, rot=10, op=0.4)
    s += hose_arms(y=250, left_x=140, right_x=260)
    s += face(cy=196, dx=34, mouth="open", mouth_dy=38, cheek_dx=54)
    s += hard_hat(200, 140, 156, "#FFC83D")
    return s


def gigi():
    c = "#9B5DE5"
    s = shadow(84)
    s += hose_legs(shoe="#34C77B")
    for (x, y, r) in ((200, 376, 30), (168, 344, 32), (232, 344, 32), (136, 304, 34), (200, 310, 34), (264, 304, 34),
                      (120, 250, 36), (280, 250, 36)):
        s += C(x, y, r, c) + shine(x - r * 0.35, y - r * 0.35, r * 0.2, r * 0.13)
    s += C(200, 206, 96, light(c, 0.15)) + shine(160, 160, 22, 14)
    s += P("M246 124 Q258 92 250 70", "none", 8)
    s += P("M252 92 Q290 52 322 80 Q286 112 252 92 Z", "#34C77B")
    s += hose_arms(y=260, left_x=110, right_x=290)
    s += face(cy=204, dx=34, mouth="smile", mouth_dy=36, cheek_dx=58)
    s += crown(196, 118, 70)
    return s


def avi():
    skin, flesh, pit = "#3E7B27", "#D5ECA4", "#9C5B2E"
    s = shadow(84)
    s += hose_legs(shoe="#FF7A59")
    s += P("M200 60 Q262 60 270 150 Q330 230 300 330 Q270 404 200 404 Q130 404 100 330 Q70 230 130 150 Q138 60 200 60 Z", skin)
    s += P("M200 86 Q246 86 250 160 Q300 230 276 320 Q254 380 200 380 Q146 380 124 320 Q100 230 150 160 Q154 86 200 86 Z", flesh, False)
    s += C(200, 300, 46, pit) + shine(184, 284, 12, 8, op=0.5)
    s += P("M200 318 Q178 300 188 290 Q196 284 200 294 Q204 284 212 290 Q222 300 200 318 Z", "#FF8FB1", 3)
    s += hose_arms(y=250, left_x=112, right_x=288, wave=True)
    s += face(cy=176, dx=32, mouth="smile", mouth_dy=36, cheek_dx=52)
    return s


def leo():
    fur, mane, belly = "#F6C177", "#D9822B", "#FFF1D6"
    s = shadow()
    s += P("M262 360 Q320 380 330 330", "none", 10) + C(334, 322, 18, mane)
    s += legs(fur, shoe=belly)
    s += body(fur, belly)
    s += arms(fur, wave=True)
    import math
    pts = []
    for i in range(24):
        a = i / 24 * math.tau
        r = 148 if i % 2 == 0 else 126
        pts.append(f"{200 + r * math.cos(a):.1f} {184 + r * 0.92 * math.sin(a):.1f}")
    s += P("M" + " L".join(pts) + " Z", mane)
    s += C(118, 110, 24, fur) + C(282, 110, 24, fur)
    s += head(fur, ry=96)
    s += E(200, 230, 50, 34, belly, False)
    s += face(hero=True, mouth="smile", mouth_dy=46)
    s += P("M186 214 L214 214 L200 228 Z", "#8C2F4A", 4)
    s += crown(200, 72, 96)
    return s


def zara():
    c, stripe = "#F7F7FA", OUT
    s = shadow()
    s += legs(c, shoe=OUT)
    s += body(c)
    for x in (150, 186, 222, 256):
        s += P(f"M{x} 262 Q{x + 14} 300 {x - 4} 340", "none", 9)
    s += arms(c, wave=True)
    for x in (130, 270):
        s += E(x, 92, 22, 40, c, rot=-20 if x < 200 else 20)
    s += head(c)
    for i, (x, y) in enumerate(((150, 104), (166, 80), (186, 64), (208, 60), (230, 68), (250, 86))):
        s += E(x, y, 16, 26, OUT if i % 2 == 0 else "#FFFFFF", 4, rot=(x - 200) * 0.6)
    for y in (120, 150):
        s += P(f"M100 {y + 30} Q130 {y + 20} 140 {y}", "none", 9) + P(f"M300 {y + 30} Q270 {y + 20} 260 {y}", "none", 9)
    s += E(200, 238, 58, 38, "#6B6B7B", True)
    s += E(182, 236, 6, 9, OUT, False) + E(218, 236, 6, 9, OUT, False)
    s += eyes(200, 180, 42)
    s += cheeks(200, 206, 72)
    s += smile(200, 256, 18, 10)
    s += bow(266, 92, "#FF4F9A", 0.8)
    return s


def gemma():
    c, spot = "#FFD97A", "#C98A3E"
    s = shadow(90)
    s += legs(c, shoe="#8A5A35", spread=36, top=356)
    s += E(200, 336, 76, 50, c)
    for (x, y) in ((160, 326), (226, 342), (198, 312), (244, 316)):
        s += E(x, y, 14, 11, spot, False)
    s += E(124, 330, 18, 30, c, rot=30) + E(276, 330, 18, 30, c, rot=-30)
    s += R(172, 170, 56, 160, 26, c)
    for (x, y) in ((186, 220), (212, 258), (190, 296)):
        s += E(x, y, 12, 10, spot, False)
    s += P("M224 176 Q236 230 230 290", "none", 6, op=0.25)
    for x in (168, 232):
        s += R(x - 7, 36, 14, 44, 7, "#C98A3E") + C(x, 34, 13, "#8A5A35")
    s += E(110, 112, 32, 16, c, rot=-20) + E(290, 112, 32, 16, c, rot=20)
    s += head(c, cy=126, rx=94, ry=78)
    s += E(200, 166, 64, 34, light(c, 0.4), False)
    s += face(cy=118, dx=36, mouth="smile", mouth_dy=52, cheek_dy=30, cheek_dx=60)
    s += C(186, 160, 5, OUT, False) + C(214, 160, 5, OUT, False)
    return s


def pip():
    c, white, orange = "#2B2D42", "#FFFFFF", "#FF9F1C"
    s = shadow(90)
    for x in (168, 232):
        s += E(x, 404, 30, 14, orange)
    s += P("M200 40 Q320 40 316 210 Q320 400 200 404 Q80 400 84 210 Q80 40 200 40 Z", c)
    s += P("M200 160 Q290 160 278 290 Q270 386 200 388 Q130 386 122 290 Q110 160 200 160 Z", white, False)
    s += P("M200 108 Q236 76 262 120 Q284 170 230 196 Q200 206 170 196 Q116 170 138 120 Q164 76 200 108 Z", white, False)
    s += E(92, 270, 24, 64, c, rot=20) + E(308, 250, 24, 64, c, rot=-40)
    s += shine(130, 90, 20, 12)
    s += eyes(200, 150, 36, 0.95)
    s += cheeks(200, 182, 60)
    s += P("M178 176 Q200 162 222 176 Q200 204 178 176 Z", orange, 5)
    s += P("M128 214 Q200 240 272 214 L276 238 Q200 266 124 238 Z", "#FF5A5F")
    s += P("M228 236 L262 236 L270 300 L236 304 Z", "#FF5A5F")
    s += P("M240 256 L262 254 M244 276 L266 274", "none", 5, op=0.9)
    s += P("M238 304 L238 316 M250 303 L250 315 M262 301 L262 313", "none", 4)
    return s


def ellie():
    c, inner = "#B8C1D9", "#FFC2DA"
    s = shadow()
    s += legs(c, shoe=light(c, 0.5), spread=40)
    s += body(c, light(c, 0.35))
    s += arms(c, wave=True)
    s += E(84, 190, 70, 84, c, rot=-10) + E(316, 190, 70, 84, c, rot=10)
    s += E(92, 194, 44, 58, inner, False, rot=-10) + E(308, 194, 44, 58, inner, False, rot=10)
    s += head(c, rx=100, ry=96)
    s += P("M184 214 Q178 280 210 300 Q236 310 240 288 Q214 284 216 214 Z", c)
    s += P("M196 250 L206 250 M194 266 L206 268", "none", 3, op=0.35)
    s += eyes(200, 176, 42)
    s += cheeks(200, 214, 66)
    s += P("M156 222 Q164 236 176 230", "none", 4) + P("M244 222 Q236 236 224 230", "none", 4)
    s += bow(254, 92, "#FF4F9A", 0.85)
    return s


def rocky():
    c, horn = "#A7B4C2", "#FFF6E0"
    s = shadow()
    s += legs(c, shoe=dark(c, 0.15), spread=40)
    s += body(c, light(c, 0.35))
    s += arms(c, wave=True)
    s += P("M106 128 L118 92 L146 118 Z", c) + P("M294 128 L282 92 L254 118 Z", c)
    s += head(c, rx=112, ry=96)
    s += E(200, 236, 66, 40, light(c, 0.3), False)
    s += P("M172 220 Q200 120 228 220 Z", horn)
    s += P("M184 172 Q200 160 214 172", "none", 3, op=0.3)
    s += eyes(200, 190, 56, 0.95)
    s += cheeks(200, 228, 82)
    s += C(184, 244, 5, OUT, False) + C(216, 244, 5, OUT, False)
    s += smile(200, 260, 16, 8)
    s += hard_hat(200, 112, 170, "#FFB020")
    return s


CHARACTERS = {
    "lavender": lavender, "pixelpup": pixelpup, "mochi": mochi, "ollie": ollie, "coral": coral, "sunny": sunny,
    "comet": comet, "midnight": midnight, "starspark": starspark, "acorn": acorn, "novawing": novawing,
    "benny": benny, "stella": stella, "broccoli": broccoli, "carlos": carlos, "gigi": gigi, "avi": avi,
    "leo": leo, "zara": zara, "gemma": gemma, "pip": pip, "ellie": ellie, "rocky": rocky,
}


def svg(name):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="-10 -10 {W + 20} {H + 20}" '
            f'width="{W + 20}" height="{H + 20}">{CHARACTERS[name]()}</svg>')


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for name in CHARACTERS:
        with open(os.path.join(out, f"{name}.svg"), "w") as f:
            f.write(svg(name))
    print(json.dumps(list(CHARACTERS)))
