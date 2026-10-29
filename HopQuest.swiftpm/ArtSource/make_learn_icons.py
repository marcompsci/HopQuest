"""Menu icons for the learning places (Reading Nook, Math Market, Science Lab, Music Maker, Garden, Stories),
in the same ink-outline style as icon_kart / icon_bop (make_world.py), so the menu doesn't fall back to emoji.

Usage: python3 make_learn_icons.py <Assets.xcassets dir>
Renders each 200x200 SVG to a 300x300 PNG imageset with Playwright (same as render_world.py).
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_characters import OUT, E, C, P, R, shine, star_path  # noqa: E402
from make_world import svg  # noqa: E402


def ground(cx=100, w=74):
    return E(cx, 178, w, 9, "#000000", False, op=0.18)


def star(x, y, r):
    return P(star_path(x, y, r, 0.42), "#FFD93D", 3)


def icon_reading():
    s = ground()
    # open book, pages fanned
    s += P("M100 70 Q70 54 30 60 L30 156 Q70 150 100 166 Z", "#FFFFFF")
    s += P("M100 70 Q130 54 170 60 L170 156 Q130 150 100 166 Z", "#FFFFFF")
    s += P("M22 66 L22 164 Q66 156 100 172 Q134 156 178 164 L178 66", "none", 6)
    s += P("M100 70 L100 166", "none", 5)
    for i, y in enumerate((84, 100, 116, 132)):
        s += P(f"M42 {y + 2} Q66 {y - 4} 88 {y + 4}", "none", 4, op=0.25)
    # big letter A on the right page, in red
    s += P("M118 138 L134 84 L150 138 M124 120 L144 120", "none", 9)
    s += P("M118 138 L134 84 L150 138 M124 120 L144 120", "none", False)
    s += f'<path d="M118 138 L134 84 L150 138 M124 120 L144 120" fill="none" stroke="#FF6B6B" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>'
    s += star(46, 34, 13) + star(160, 30, 9)
    return s


def icon_market():
    s = ground()
    # stall counter
    s += R(32, 104, 136, 64, 10, "#F2C38B") + R(32, 104, 136, 14, 6, "#D9A066")
    # striped awning
    cols = ["#FF6B6B", "#FFFFFF"] * 3
    for i, c in enumerate(cols):
        x = 24 + i * 25.3
        s += P(f"M{x} 56 L{x + 25.3} 56 L{x + 25.3} 90 Q{x + 12.6} 102 {x} 90 Z", c, 5)
    s += R(22, 46, 156, 14, 7, "#FF6B6B")
    # fruit on the counter
    s += C(66, 98, 14, "#FF6B6B") + shine(61, 93, 5, 3) + P("M66 84 Q70 78 76 80", "none", 4)
    s += E(100, 98, 16, 12, "#FFD93D") + shine(94, 94, 5, 3)
    # gold coin
    s += C(138, 132, 20, "#FFD93D") + C(138, 132, 12, "#FFC23D", 4) + shine(130, 124, 6, 4)
    return s


def icon_science():
    s = ground()
    # round flask with bubbling liquid
    s += R(86, 30, 28, 16, 6, "#BDEBFF")
    s += P("M90 44 L90 82 Q48 102 52 136 Q58 172 100 172 Q142 172 148 136 Q152 102 110 82 L110 44 Z", "#E8F7FF")
    s += P("M58 128 Q100 112 142 128 Q142 168 100 168 Q58 168 58 128 Z", "#3CC9A0", False)
    s += P("M90 44 L90 82 Q48 102 52 136 Q58 172 100 172 Q142 172 148 136 Q152 102 110 82 L110 44 Z", "none", 6)
    s += shine(74, 118, 8, 16, rot=20, op=0.5)
    for (x, y, r) in ((92, 142, 6), (112, 150, 4), (104, 128, 5)):
        s += C(x, y, r, "#FFFFFF", 3)
    for (x, y, r) in ((126, 22, 9), (146, 40, 6), (60, 24, 6)):
        s += C(x, y, r, "#BDEBFF", 3)
    s += star(160, 92, 11)
    return s


def icon_music():
    s = ground()
    # rainbow keys
    colors = ["#FF5A5F", "#FF9F1C", "#FFD23F", "#34C77B", "#4D96FF", "#9B6BDF"]
    for i, c in enumerate(colors):
        s += R(28 + i * 24, 96, 22, 74, 6, c, 4)
        s += R(31 + i * 24, 100, 5, 30, 2, "#FFFFFF", False, op=0.35)
    # music note
    s += P("M118 34 L162 24 L162 74", "none", 7)
    s += P("M118 34 L118 84", "none", 7)
    s += E(108, 86, 13, 10, OUT, False, rot=-20) + E(152, 76, 13, 10, OUT, False, rot=-20)
    s += star(54, 46, 12)
    return s


def icon_garden():
    s = ground()
    # flower pot
    s += P("M64 124 L136 124 L128 172 L72 172 Z", "#E07B39") + R(56, 116, 88, 16, 6, "#F29A5B")
    # stem + leaves
    s += P("M100 118 L100 70", "none", 6)
    s += E(80, 98, 18, 9, "#34C77B", rot=-30) + E(120, 92, 18, 9, "#34C77B", rot=30)
    # sunflower head
    import math
    for k in range(10):
        a = k * math.pi / 5
        s += E(100 + 26 * math.cos(a), 54 + 26 * math.sin(a), 13, 8, "#FFD93D", 4, rot=math.degrees(a))
    s += C(100, 54, 18, "#8B5A2B") + shine(94, 48, 5, 3)
    s += star(160, 40, 10)
    return s


ICONS = {"icon_reading": icon_reading, "icon_market": icon_market, "icon_science": icon_science,
         "icon_music": icon_music, "icon_garden": icon_garden}


if __name__ == "__main__":
    from playwright.sync_api import sync_playwright
    assets = sys.argv[1]
    with sync_playwright() as p:
        b = p.chromium.launch()
        for name, fn in ICONS.items():
            body = svg(200, 200, fn())
            page = b.new_page(viewport={"width": 200, "height": 200}, device_scale_factor=1.5)
            page.set_content(f'<html><body style="margin:0;background:transparent">{body}</body></html>')
            d = os.path.join(assets, f"{name}.imageset")
            os.makedirs(d, exist_ok=True)
            page.locator("svg").screenshot(path=os.path.join(d, f"{name}.png"), omit_background=True)
            json.dump({"images": [{"filename": f"{name}.png", "idiom": "universal"}], "info": {"author": "xcode", "version": 1}},
                      open(os.path.join(d, "Contents.json"), "w"), indent=2)
            page.close()
        b.close()
    print("ok", len(ICONS))
