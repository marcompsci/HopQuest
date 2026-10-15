"""My Castle (cozy home) art for HopQuest, in the buddy ink-outline style.

Decor items are 200 x 200 and sit on the floor at about y = 186 (bottom-center anchor).
room_floor 400 x 220 (wooden floor), room_window 200 x 220 (castle window with sky), snacks 120 x 120.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_characters import OUT, E, C, P, R, shine, star_path, dark, light  # noqa: E402
from make_world import svg, heart  # noqa: E402


def shadow(w=70):
    return E(100, 188, w, 8, "#000000", False, op=0.15)


def bed():
    s = shadow(86)
    s += R(18, 70, 24, 116, 8, "#A0673B")          # headboard post
    s += R(14, 60, 60, 70, 18, "#B983FF")          # headboard
    s += P(star_path(44, 92, 14, 0.45), "#FFD93D", 3)
    s += R(20, 120, 164, 52, 14, "#7FD8FF")        # mattress / blanket
    s += R(20, 120, 164, 18, 9, "#FFFFFF", 4)
    s += E(60, 116, 26, 13, "#FFFFFF")             # pillow
    s += R(26, 168, 12, 18, 4, "#A0673B") + R(166, 168, 12, 18, 4, "#A0673B")
    for x in (90, 120, 150):
        s += C(x, 150, 6, "#FFFFFF", False, op=0.6)
    s += shine(100, 128, 40, 4, rot=0, op=0.5)
    return s


def rug():
    s = E(100, 160, 92, 30, "#FF9ECF")
    s += E(100, 160, 70, 21, "#FFC2E2", False)
    s += E(100, 160, 46, 13, "#FF7FC4", False)
    s += P(star_path(100, 160, 10, 0.45), "#FFD93D", 2)
    return s


def lamp():
    s = shadow(36)
    s += R(84, 172, 32, 14, 6, "#6C7BD9")
    s += R(96, 86, 8, 88, 4, "#9AA0AE")
    s += P("M56 90 L144 90 L124 30 L76 30 Z", "#FFE066")
    s += E(100, 98, 34, 8, "#FFF6B3", False, op=0.9)
    s += shine(88, 52, 6, 16, rot=10, op=0.6)
    return s


def plant():
    s = shadow(40)
    for a, col in ((-40, "#3FA34D"), (-10, "#5CC46A"), (20, "#3FA34D"), (48, "#5CC46A"), (-70, "#5CC46A")):
        s += E(100, 74, 16, 46, col, rot=a)
    s += P("M66 120 L134 120 L124 184 L76 184 Z", "#FF8A5E")
    s += R(60, 112, 80, 16, 6, "#E76F51")
    s += shine(84, 140, 5, 14, op=0.4)
    return s


def bookshelf():
    s = shadow(64)
    s += R(40, 24, 120, 162, 10, "#C98F5E")
    s += R(50, 34, 100, 142, 6, "#A0673B", False)
    for y in (78, 124):
        s += R(46, y, 108, 8, 3, "#C98F5E", 3)
    books = [("#FF7A59", 12), ("#4D96FF", 10), ("#FFD93D", 14), ("#34C77B", 9), ("#B983FF", 12)]
    for row, y in enumerate((36, 84, 130)):
        x = 54
        for i, (col, w) in enumerate(books):
            if (i + row) % 5 == 4:
                continue
            h = 38 if (i + row) % 2 == 0 else 32
            s += R(x, y + (40 - h), w, h, 2, col, 3)
            x += w + 3
    s += R(40, 24, 120, 162, 10, "none", 5)
    return s


def toybox():
    s = shadow(62)
    s += R(40, 110, 120, 76, 12, "#4D96FF")
    s += R(34, 96, 132, 24, 10, "#7FB5FF")
    s += C(70, 92, 16, "#FF5A5F")                    # ball
    s += shine(64, 86, 5, 3, op=0.7)
    s += R(108, 70, 26, 30, 6, "#FFD93D", 4)         # block
    s += P(f"M120 74 L120 92", "none", 3, op=0.4)
    s += P(star_path(100, 150, 14, 0.45), "#FFD93D", 3)
    return s


def painting():
    s = R(30, 30, 140, 110, 10, "#C98F5E")
    s += R(42, 42, 116, 86, 4, "#BDEBFF", 3)
    s += P("M42 128 L82 82 L108 108 L126 90 L158 128 Z", "#5CC46A", 3)
    s += C(132, 64, 12, "#FFE066", 3)
    s += P("M100 30 L100 12", "none", 3)
    return s


def rocket():
    s = shadow(40)
    s += P("M100 20 Q136 56 132 130 L68 130 Q64 56 100 20 Z", "#FFFFFF")
    s += P("M100 20 Q118 36 126 60 L74 60 Q82 36 100 20 Z", "#FF5A5F", 4)
    s += C(100, 88, 14, "#7FD8FF")
    s += P("M68 108 L44 150 L70 140 Z", "#FF5A5F") + P("M132 108 L156 150 L130 140 Z", "#FF5A5F")
    s += P("M80 130 L120 130 L114 150 L86 150 Z", "#9AA0AE")
    s += P("M88 152 Q100 186 112 152 Z", "#FFB020", 3)
    s += shine(86, 70, 4, 18, op=0.5)
    return s


def beanbag():
    s = shadow(76)
    s += P("M30 180 Q14 120 60 100 Q100 70 140 96 Q186 116 172 180 Z", "#34C77B")
    s += P("M60 140 Q100 116 140 140", "none", 4, op=0.3)
    s += shine(70, 116, 18, 7, rot=-20, op=0.5)
    return s


def cake():
    s = shadow(54)
    s += R(46, 166, 108, 12, 6, "#E0E0F0")
    s += R(54, 120, 92, 48, 12, "#FFC2E2")
    s += P("M54 132 Q66 144 78 132 Q90 144 102 132 Q114 144 126 132 Q138 144 146 132 L146 124 L54 124 Z", "#FFFFFF", 3)
    s += R(66, 82, 68, 40, 10, "#FF9ECF")
    s += P("M66 92 Q78 102 90 92 Q102 102 114 92 Q126 102 134 92 L134 84 L66 84 Z", "#FFFFFF", 3)
    for x in (84, 100, 116):
        s += R(x - 3, 58, 6, 24, 3, ["#4D96FF", "#FFD93D", "#34C77B"][(x // 16) % 3], 2)
        s += E(x, 52, 4, 7, "#FFB020", False)
    return s


def trophy():
    s = shadow(40)
    s += R(70, 166, 60, 20, 6, "#A0673B")
    s += R(90, 132, 20, 36, 4, "#FFC83D")
    s += P("M56 40 L144 40 Q146 120 100 134 Q54 120 56 40 Z", "#FFD93D")
    s += P("M56 54 Q26 54 32 82 Q38 104 62 104", "none", 7) + P("M144 54 Q174 54 168 82 Q162 104 138 104", "none", 7)
    s += P(star_path(100, 82, 18, 0.45), "#FFF6B3", 3)
    s += shine(74, 66, 5, 18, op=0.6)
    return s


def aquarium():
    s = shadow(70)
    s += R(30, 60, 140, 110, 14, "#BDEBFF")
    s += R(30, 60, 140, 26, 12, "#7FD8FF", False)
    s += P("M40 150 Q60 140 80 152 Q100 160 120 148 Q140 140 160 152 L160 162 L40 162 Z", "#FFE29A", False)
    s += E(84, 112, 18, 11, "#FF8A5E") + P("M66 112 L54 102 L54 122 Z", "#FF8A5E", 4) + C(92, 108, 3, OUT, False)
    s += E(130, 132, 12, 8, "#FFD93D") + P("M118 132 L110 125 L110 139 Z", "#FFD93D", 3) + C(136, 129, 2.5, OUT, False)
    for (x, y) in ((110, 90), (118, 78), (60, 84)):
        s += C(x, y, 4, "#FFFFFF", 2)
    s += R(30, 60, 140, 110, 14, "none", 5)
    s += R(24, 166, 152, 18, 6, "#6C7BD9")
    return s


def telescope():
    s = shadow(50)
    s += P("M100 112 L70 184 M100 112 L130 184 M100 112 L100 184", "none", 6)
    s += R(54, 70, 104, 30, 12, "#6C7BD9", rot=(-28, 100, 85))
    s += R(140, 42, 30, 38, 8, "#4D96FF", rot=(-28, 155, 61))
    s += C(100, 106, 9, "#FFD93D")
    s += P(star_path(44, 40, 12, 0.42), "#FFD93D", 3)
    return s


def piano():
    s = shadow(76)
    s += R(26, 70, 148, 90, 12, "#2E2A5C")
    s += R(34, 112, 132, 36, 4, "#FFFFFF", 3)
    for i in range(1, 11):
        x = 34 + i * 12
        s += P(f"M{x} 112 L{x} 148", "none", 2)
    for i in (1, 2, 4, 5, 6, 8, 9):
        x = 34 + i * 12
        s += R(x - 4, 112, 8, 20, 2, OUT, False)
    s += R(34, 160, 10, 26, 3, "#2E2A5C") + R(156, 160, 10, 26, 3, "#2E2A5C")
    s += P("M70 50 Q70 38 80 40 L80 64", "none", 4) + E(72, 64, 8, 6, OUT, False)
    s += P("M118 34 L136 30 L136 56", "none", 4) + E(130, 58, 7, 5, OUT, False)
    return s


def banner():
    s = P("M100 10 L100 24", "none", 4)
    s += R(40, 22, 120, 10, 5, "#A0673B")
    s += P("M50 30 L150 30 L150 150 L100 124 L50 150 Z", "#B983FF")
    s += P(star_path(100, 80, 26, 0.45), "#FFD93D", 4)
    s += shine(66, 60, 5, 20, op=0.4)
    return s


def balloons():
    s = ""
    for (x, col, top) in ((70, "#FF7FC4", 26), (104, "#7FD8FF", 12), (134, "#FFD93D", 34)):
        s += P(f"M{x} {top + 62} Q{x + 6} 130 100 182", "none", 3)
        s += E(x, top + 30, 24, 30, col)
        s += shine(x - 8, top + 18, 5, 9, rot=20, op=0.7)
    s += E(100, 186, 12, 5, "#000000", False, op=0.15)
    return s


DECOR = {
    "decor_bed": bed, "decor_rug": rug, "decor_lamp": lamp, "decor_plant": plant,
    "decor_bookshelf": bookshelf, "decor_toybox": toybox, "decor_painting": painting,
    "decor_rocket": rocket, "decor_beanbag": beanbag, "decor_cake": cake, "decor_trophy": trophy,
    "decor_aquarium": aquarium, "decor_telescope": telescope, "decor_piano": piano,
    "decor_banner": banner, "decor_balloons": balloons,
}


def floor():
    s = R(0, 0, 400, 220, 0, "#D9A066", False)
    for i, y in enumerate(range(0, 220, 30)):
        s += P(f"M0 {y} L400 {y}", "none", 3, op=0.25)
        off = 60 if i % 2 else 0
        for x in range(off, 400, 120):
            s += P(f"M{x} {y} L{x} {y + 30}", "none", 2, op=0.2)
    s += R(0, 0, 400, 14, 0, "#A0673B", False)
    return s


def window():
    s = R(30, 20, 140, 190, 70, "#BDEBFF")
    s += C(126, 70, 18, "#FFE066", False)
    for (x, y) in ((64, 110), (130, 140)):
        s += C(x, y, 14, "#FFFFFF", False) + C(x + 16, y + 4, 11, "#FFFFFF", False) + C(x - 14, y + 6, 10, "#FFFFFF", False)
    s += P("M100 20 L100 210 M30 120 L170 120", "none", 7)
    s += R(30, 20, 140, 190, 70, "none", 8)
    s += R(20, 200, 160, 16, 6, "#C98F5E")
    return s


def snack(kind):
    if kind == "apple":
        s = C(60, 68, 38, "#FF5A5F") + P("M60 32 Q62 20 70 14", "none", 4) + E(76, 22, 12, 7, "#34C77B", rot=-20)
        return s + shine(46, 56, 8, 12, rot=20, op=0.6)
    if kind == "cookie":
        s = C(60, 62, 40, "#E8BC87")
        for (x, y) in ((46, 50), (70, 46), (56, 74), (78, 70)):
            s += E(x, y, 6, 5, "#7A4A2A", False)
        return s
    # ball toy
    s = C(60, 62, 40, "#4D96FF") + P("M24 52 Q60 72 96 52", "none", 5) + P("M30 84 Q60 60 92 84", "none", 5).replace(OUT, "#FFFFFF")
    return s + shine(46, 40, 10, 6, op=0.6)


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    files = {name: svg(200, 200, fn()) for name, fn in DECOR.items()}
    files["room_floor"] = svg(400, 220, floor())
    files["room_window"] = svg(200, 220, window())
    for k in ("apple", "cookie", "ball"):
        files[f"snack_{k}"] = svg(120, 120, snack(k))
    for name, body in files.items():
        open(os.path.join(out, f"{name}.svg"), "w").write(body)
    print(len(files))
