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


def icon_writing():
    s = ground()
    # lined paper, slightly tilted
    s += '<g transform="rotate(-6 100 112)">'
    s += R(40, 46, 116, 128, 10, "#FFFFFF")
    for y in (82, 112, 142):
        s += P(f"M52 {y} L144 {y}", "none", 3, op=0.25)
    s += '<path d="M64 140 L82 76 L100 140 M70 118 L94 118" fill="none" stroke="#2F6FD1" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>'
    s += '</g>'
    # pencil
    s += '<g transform="rotate(38 140 112)">'
    s += R(128, 52, 26, 96, 4, "#FFD93D") + R(128, 52, 26, 16, 4, "#FF8FAB") + R(128, 66, 26, 6, 0, "#C9CED6", 4)
    s += P("M128 148 L154 148 L141 176 Z", "#F2C38B") + P("M136 166 L146 166 L141 176 Z", OUT, False)
    s += '</g>'
    s += star(162, 34, 10) + star(34, 40, 8)
    return s


def icon_clock():
    s = ground()
    # little clock tower
    s += R(64, 70, 72, 104, 8, "#F2C38B") + P("M56 74 L100 26 L144 74 Z", "#FF6B6B")
    s += C(100, 108, 28, "#FFFFFF")
    for k in range(12):
        import math
        a = k * math.pi / 6
        s += C(100 + 21 * math.cos(a), 108 + 21 * math.sin(a), 1.8, OUT, False)
    s += P("M100 108 L100 90", "none", 5) + P("M100 108 L114 114", "none", 5) + C(100, 108, 4, OUT, False)
    s += R(88, 146, 24, 28, 10, "#B5651D")
    s += star(160, 40, 10)
    return s


def icon_world():
    s = ground()
    s += C(100, 100, 62, "#5EC8E5")
    # continents (blobs)
    s += P("M62 70 Q74 54 92 62 Q100 76 88 86 Q80 100 70 92 Q58 84 62 70 Z", "#34C77B", 4)
    s += P("M110 60 Q132 56 146 72 Q140 86 126 84 Q114 82 110 60 Z", "#34C77B", 4)
    s += P("M104 104 Q124 98 136 112 Q134 136 116 146 Q104 132 104 104 Z", "#34C77B", 4)
    s += P("M70 116 Q82 112 86 124 Q82 136 72 132 Z", "#34C77B", 4)
    s += shine(76, 60, 9, 5, rot=-30, op=0.5)
    # a little plane
    s += P("M140 30 L176 22 L168 32 Z", "#FFFFFF", 4) + P("M150 28 L156 42 L162 30", "#FFFFFF", 4)
    s += P("M126 40 Q120 52 108 54", "none", 3, op=0.4)
    return s


ICONS = {"icon_reading": icon_reading, "icon_market": icon_market, "icon_science": icon_science,
         "icon_music": icon_music, "icon_garden": icon_garden,
         "icon_writing": icon_writing, "icon_clock": icon_clock, "icon_world": icon_world}


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
