"""Code Club art for HopQuest (buddy ink-outline style): rock obstacle, loop block icon, Code Club menu icon."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_characters import OUT, E, C, P, R, shine, star_path  # noqa: E402
from make_world import svg  # noqa: E402


def rock():
    s = E(100, 168, 70, 10, "#000000", False, op=0.15)
    s += P("M30 160 Q22 110 52 86 Q70 46 112 50 Q150 48 166 88 Q186 120 170 160 Z", "#A7B4C2")
    s += P("M50 150 Q48 116 70 100 Q86 80 112 84", "none", 5, op=0.25)
    s += P("M120 70 Q146 74 154 100", "none", 4, op=0.3)
    s += shine(80, 80, 16, 8, rot=-25, op=0.55)
    s += E(126, 132, 10, 6, "#8A97A6", False) + E(70, 140, 7, 4, "#8A97A6", False)
    return s


def icon_loop():
    s = P("M60 70 Q60 40 100 40 Q140 40 140 70 L140 96", "none", 18)
    s += P("M60 70 Q60 40 100 40 Q140 40 140 70 L140 96", "none", 10, op=1).replace(f'stroke="{OUT}"', 'stroke="#FFB020"')
    s += P("M118 92 L140 124 L162 92 Z", "#FFB020")
    s += P("M140 130 Q140 160 100 160 Q60 160 60 130 L60 104", "none", 18)
    s += P("M140 130 Q140 160 100 160 Q60 160 60 130 L60 104", "none", 10).replace(f'stroke="{OUT}"', 'stroke="#FFB020"')
    s += P("M38 108 L60 76 L82 108 Z", "#FFB020")
    return s


def icon_code():
    s = E(100, 184, 70, 9, "#000000", False, op=0.15)
    s += R(24, 30, 152, 140, 22, "#7C4DFF")
    s += R(36, 44, 128, 112, 14, "#2E2A5C", False)
    for i, (col, w) in enumerate((("#34C77B", 70), ("#FFB020", 90), ("#4D96FF", 56), ("#FF7FC4", 80))):
        s += R(50 + (16 if i in (1, 2) else 0), 58 + i * 24, w, 14, 7, col, False)
    s += P(star_path(150, 40, 20, 0.45), "#FFD93D", 4)
    return s


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for name, fn in {"code_rock": rock, "icon_loop": icon_loop, "icon_code": icon_code}.items():
        open(os.path.join(out, f"{name}.svg"), "w").write(svg(200, 200, fn()))
    print("3")
