"""Fort Friends art for HopQuest, in the buddy ink-outline style.

Tiles are 100 x 100 (one grid cell). Pieces fill the cell; the walkable top is the top edge.
fort 200 x 220 (bottom-center sits on the ground), rain_cloud 260 x 130, icons 200 x 200.
"""
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_characters import OUT, E, C, P, R, shine, star_path  # noqa: E402
from make_world import svg, heart  # noqa: E402


def tile_grass():
    s = R(3, 3, 94, 94, 10, "#C98F5E", 4)
    s += P("M3 30 Q3 3 18 3 L82 3 Q97 3 97 30 Q86 38 76 30 Q64 40 52 30 Q40 40 28 30 Q16 38 3 30 Z", "#5CC46A", 4)
    s += shine(26, 12, 14, 4, rot=0, op=0.5)
    for (x, y) in ((24, 60), (62, 72), (80, 52)):
        s += E(x, y, 8, 5, "#A8714A", False)
    return s


def tile_dirt():
    s = R(3, 3, 94, 94, 10, "#B98256", 4)
    for (x, y, r) in ((26, 30, 9), (68, 42, 7), (40, 74, 8), (78, 78, 5)):
        s += E(x, y, r, r * 0.65, "#A06B43", False)
    return s


def tile_water():
    s = R(0, 0, 100, 100, 0, "#5EC8F2", False)
    s += P("M0 18 Q12 8 25 18 Q38 28 50 18 Q62 8 75 18 Q88 28 100 18 L100 0 L0 0 Z", "#9FE2FF", False)
    for (x, y) in ((22, 50), (66, 70)):
        s += P(f"M{x - 10} {y} Q{x} {y - 6} {x + 10} {y}", "none", 3, op=0.35)
    return s


def piece_block():
    s = R(4, 4, 92, 92, 14, "#FFB020")
    s += R(14, 14, 72, 72, 10, "#FFC94D", False)
    s += R(4, 4, 92, 92, 14, "none", 5)
    for (x, y) in ((32, 32), (68, 32), (32, 68), (68, 68)):
        s += C(x, y, 9, "#FFD97A", 4)
        s += shine(x - 2, y - 3, 3, 2, op=0.8)
    s += shine(26, 14, 16, 4, rot=0, op=0.6)
    return s


def piece_ramp():
    """Rises to the right (flip in game for left)."""
    s = P("M6 94 L94 94 L94 8 Q90 4 84 8 L10 82 Q4 88 6 94 Z", "#4D96FF")
    s += P("M22 86 L86 86 L86 26 Z", "#7FB5FF", False)
    for i in range(4):
        x = 22 + i * 18
        y = 80 - i * 18
        s += P(f"M{x} {y} L{x + 14} {y - 14}", "none", 4, op=0.4)
    s += shine(60, 40, 12, 3, rot=-45, op=0.6)
    return s


def piece_bridge():
    s = ""
    for x in (12, 80):
        s += R(x, 22, 10, 70, 4, "#9C5B2E", 4)
    s += R(4, 4, 92, 24, 8, "#D9A066")
    for x in (30, 52, 74):
        s += P(f"M{x} 6 L{x} 26", "none", 3, op=0.4)
    s += P("M18 30 Q50 58 82 30", "none", 4)
    s += shine(26, 10, 12, 3, rot=0, op=0.6)
    return s


def crate(gold=False):
    base, light_, dark_ = ("#FFD93D", "#FFE98A", "#E0A800") if gold else ("#D9A066", "#E8BC87", "#A0673B")
    s = E(50, 94, 40, 5, "#000000", False, op=0.15)
    s += R(10, 18, 80, 72, 10, base)
    s += R(18, 26, 64, 56, 6, light_, False)
    s += P("M18 26 L82 82 M82 26 L18 82", "none", 5, op=0.5)
    s += R(10, 18, 80, 72, 10, "none", 5)
    s += shine(28, 26, 12, 4, rot=0, op=0.7)
    if gold:
        s += C(50, 54, 17, "#FFFFFF", 4)
        s += ('<text x="50" y="64" text-anchor="middle" font-family="Arial Rounded MT Bold, Arial, sans-serif" '
              f'font-weight="900" font-size="28" fill="#7C4DFF">?</text>')
    else:
        s += R(40, 46, 20, 16, 4, dark_, 3)
    return s


def party_balloon():
    s = P("M50 66 Q46 80 54 90 Q46 96 50 100", "none", 3)
    s += P("M50 8 Q82 8 82 38 Q82 60 50 70 Q18 60 18 38 Q18 8 50 8 Z", "#FF7FC4")
    s += P("M44 68 L56 68 L52 76 L48 76 Z", "#FF7FC4", 3)
    s += E(38, 26, 8, 12, "#FFFFFF", False, rot=20, op=0.6)
    s += P(star_path(54, 40, 9, 0.45), "#FFD93D", 3)
    return s


def fort():
    s = E(100, 214, 90, 7, "#000000", False, op=0.15)
    # tree-house style fort on stilts
    for x in (34, 166):
        s += R(x - 8, 120, 16, 96, 5, "#9C5B2E")
    s += R(18, 92, 164, 40, 10, "#D9A066")
    for x in range(34, 180, 22):
        s += P(f"M{x} 96 L{x} 128", "none", 3, op=0.35)
    s += R(40, 132, 120, 0, 0, "none", False)
    # walls + roof
    s += R(40, 46, 120, 50, 8, "#FFF4C2")
    s += P("M28 54 L100 6 L172 54 Z", "#FF7A59")
    s += P("M46 44 L100 12 L154 44", "none", 3, op=0.3)
    s += R(84, 60, 32, 36, 12, "#3CC9A0")
    s += C(66, 66, 8, "#7FD8FF", 4) + C(134, 66, 8, "#7FD8FF", 4)
    # flag
    s += P("M100 8 L100 -26", "none", 5)
    s += P("M100 -26 Q122 -32 136 -20 Q120 -10 100 -12 Z", "#FFD93D", 4)
    # ladder
    s += P("M82 132 L82 214 M118 132 L118 214", "none", 5)
    for y in range(146, 212, 16):
        s += P(f"M82 {y} L118 {y}", "none", 4)
    return s


def rain_cloud():
    s = P("M30 92 Q6 92 8 70 Q10 46 40 48 Q46 16 86 18 Q110 0 140 18 Q170 4 196 26 Q232 22 238 52 "
          "Q262 56 256 80 Q250 98 226 96 Q130 104 30 92 Z", "#9AA8C7")
    s += P("M36 86 Q130 96 228 88 Q224 96 210 98 Q130 104 34 94 Z", "#7F8DB0", False)
    s += shine(70, 44, 26, 8, rot=-8, op=0.5)
    # sleepy, friendly face
    s += P("M100 64 Q108 70 116 64", "none", 4) + P("M150 64 Q158 70 166 64", "none", 4)
    s += P("M124 80 Q133 86 142 80", "none", 4)
    s += E(92, 76, 8, 4, "#FFB3C7", False, op=0.7) + E(174, 76, 8, 4, "#FFB3C7", False, op=0.7)
    return s


def icon_fort():
    s = E(100, 184, 70, 9, "#000000", False, op=0.15)
    # a ramp, a block and a little flag fort
    s += P("M20 176 L96 176 L96 104 Z", "#4D96FF")
    s += R(96, 104, 72, 72, 12, "#FFB020")
    for (x, y) in ((116, 124), (148, 124), (116, 156), (148, 156)):
        s += C(x, y, 7, "#FFD97A", 3)
    s += P("M132 104 L132 40", "none", 5)
    s += P("M132 40 Q156 32 170 46 Q154 58 132 56 Z", "#FF7FC4", 4)
    s += P(star_path(52, 52, 16, 0.42), "#FFD93D", 3)
    return s


def icon_bricks():
    s = ""
    for (x, y, col) in ((30, 104, "#FFB020"), (100, 104, "#4D96FF"), (65, 46, "#34C77B")):
        s += R(x, y, 70, 56, 12, col)
        for dx in (18, 52):
            s += C(x + dx, y + 18, 8, "#FFFFFF", 3, op=0.6)
    return s


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    files = {
        "fort_grass": svg(100, 100, tile_grass()),
        "fort_dirt": svg(100, 100, tile_dirt()),
        "fort_water": svg(100, 100, tile_water()),
        "piece_block": svg(100, 100, piece_block()),
        "piece_ramp": svg(100, 100, piece_ramp()),
        "piece_bridge": svg(100, 100, piece_bridge()),
        "crate": svg(100, 100, crate()),
        "crate_gold": svg(100, 100, crate(True)),
        "party_balloon": svg(100, 100, party_balloon()),
        "fort_goal": f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -40 200 260" width="200" height="260">{fort()}</svg>',
        "rain_cloud": svg(260, 110, rain_cloud()),
        "icon_fort": svg(200, 200, icon_fort()),
        "icon_bricks": svg(200, 200, icon_bricks()),
    }
    for name, body in files.items():
        open(os.path.join(out, f"{name}.svg"), "w").write(body)
    print(len(files))
