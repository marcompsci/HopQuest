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


def icon_dash():
    s = ground()
    # two platforms and a big star leaping between them, with speed lines
    s += R(18, 140, 66, 34, 8, "#B57A45") + R(18, 136, 66, 12, 6, "#58C46A")
    s += R(118, 112, 66, 62, 8, "#B57A45") + R(118, 108, 66, 12, 6, "#58C46A")
    s += P("M40 120 Q70 40 112 64", "none", 4, op=0.35)
    s += P(star_path(104, 66, 34, 0.45), "#FFD93D", 6) + shine(94, 56, 7, 4)
    s += C(96, 70, 3.5, OUT, False) + C(112, 70, 3.5, OUT, False) + P("M98 80 Q104 86 110 80", "none", 3.5)
    for (y, w) in ((52, 26), (66, 34), (80, 22)):
        s += P(f"M{60 - w} {y} L{60} {y}", "none", 5)
    return s


def icon_spelling():
    import math
    s = ground()
    # three letter tiles
    for i, (ch, col) in enumerate((("A", "#FF6B6B"), ("B", "#4D96FF"), ("C", "#34C77B"))):
        x = 24 + i * 52
        s += R(x, 112, 46, 50, 9, col)
        s += f'<text x="{x + 23}" y="{150}" font-family="Arial Rounded MT Bold, Arial" font-weight="900" font-size="34" text-anchor="middle" fill="#FFFFFF">{ch}</text>'
    # a bee buzzing above
    s += E(112, 62, 30, 22, "#FFD93D")
    s += P("M100 42 L100 82 M116 41 L116 83", "none", 6)
    s += E(98, 36, 14, 10, "#E8F7FF", 4, rot=-25) + E(124, 36, 14, 10, "#E8F7FF", 4, rot=25)
    s += C(138, 58, 3.5, OUT, False)
    s += P("M60 70 Q70 60 80 66", "none", 3, op=0.4)
    s += star(160, 98, 9)
    return s


def icon_fractions():
    s = ground()
    # a pie with one slice pulled out
    s += C(92, 112, 56, "#F2C38B")
    s += C(92, 112, 44, "#FF6B9A", 4)
    for a in (0, 90, 180, 270):
        import math
        r = math.radians(a)
        s += P(f"M92 112 L{92 + 44 * math.cos(r):.1f} {112 + 44 * math.sin(r):.1f}", "none", 4)
    s += P("M118 70 L162 70 A44 44 0 0 1 144 106 Z", "#FF6B9A")
    s += shine(74, 96, 8, 5)
    s += star(40, 40, 10) + star(164, 40, 8)
    return s


def icon_shapes():
    s = ground()
    s += P("M100 30 L140 98 L60 98 Z", "#FFD93D")
    s += C(64, 136, 28, "#4D96FF")
    s += R(108, 110, 54, 54, 6, "#FF6B6B")
    s += shine(92, 64, 6, 10, rot=30, op=0.4)
    s += star(160, 40, 9)
    return s


def icon_story():
    s = ground()
    # an open book with a little scene popping out
    s += P("M100 92 Q70 80 32 86 L32 166 Q70 160 100 172 Z", "#FFFFFF")
    s += P("M100 92 Q130 80 168 86 L168 166 Q130 160 100 172 Z", "#FFFFFF")
    s += P("M100 92 L100 172", "none", 5)
    s += C(66, 60, 18, "#FFD93D") + P("M128 92 L146 40 L164 92 Z", "#34C77B")
    s += P("M46 120 Q62 112 84 122 M46 138 Q62 130 84 140 M116 120 Q138 112 154 122 M116 138 Q138 130 154 140", "none", 3, op=0.3)
    s += star(160, 30, 9) + star(30, 34, 7)
    return s


def T(x, y, text, size, fill="#FFFFFF"):
    return (f'<text x="{x}" y="{y}" font-family="Arial Rounded MT Bold, Arial" font-weight="900" font-size="{size}" '
            f'text-anchor="middle" fill="{fill}" stroke="{OUT}" stroke-width="2" paint-order="stroke">{text}</text>')


def icon_rhyme():
    s = ground()
    # a frog singing two rhyming words
    s += E(86, 136, 50, 36, "#5FC86A")
    s += C(64, 102, 16, "#5FC86A") + C(108, 102, 16, "#5FC86A")
    s += C(64, 100, 8, "#FFFFFF") + C(108, 100, 8, "#FFFFFF")
    s += C(66, 101, 3.5, OUT, False) + C(110, 101, 3.5, OUT, False)
    s += P("M70 140 Q86 154 102 140", "none", 4)
    s += R(120, 34, 70, 34, 12, "#FFFFFF") + T(155, 59, "cat", 22, "#2E8B3E")
    s += R(118, 76, 70, 34, 12, "#FFFFFF") + T(153, 101, "hat", 22, "#2E8B3E")
    s += P("M30 44 L30 74 M30 44 L48 40 L48 68", "none", 4) + C(26, 76, 6, OUT, False) + C(44, 70, 6, OUT, False)
    return s


def icon_numbers():
    s = ground()
    # three rods of ten and four ones
    for i in range(3):
        x = 30 + i * 30
        s += R(x, 40, 24, 130, 4, "#8E6BE0")
        for k in range(1, 10):
            s += P(f"M{x} {40 + k * 13} L{x + 24} {40 + k * 13}", "none", 2, op=0.5)
    for i in range(4):
        s += R(126 + (i % 2) * 26, 118 + (i // 2) * 26, 22, 22, 4, "#FF9F45")
    s += star(160, 50, 11)
    return s


def icon_times():
    s = ground()
    # a treehouse with acorns in groups of three
    s += R(88, 110, 24, 64, 4, "#9C6B3F")
    s += C(100, 70, 58, "#5FBF5F")
    s += R(66, 80, 68, 44, 6, "#C98B4B")
    s += P("M60 82 L100 54 L140 82 Z", "#E5484D")
    s += R(92, 96, 16, 28, 3, "#7A4B23")
    for gx in (36, 164):
        for k in range(3):
            s += E(gx - 10 + k * 10, 150 - (k % 2) * 10, 6, 7, "#B5793D")
    return s


def icon_measure():
    s = ground()
    # a ruler and a ribbon
    s += R(22, 120, 156, 34, 5, "#FFD93D")
    for k in range(13):
        h = 14 if k % 2 == 0 else 8
        s += P(f"M{30 + k * 12} 120 L{30 + k * 12} {120 + h}", "none", 2.5)
    s += P("M22 76 L162 76 L176 90 L162 104 L22 104 Z", "#3E7BFA")
    s += P("M22 90 L150 90", "none", 2, op=0.35)
    s += star(160, 40, 10)
    return s


def icon_feelings():
    s = ground()
    # a big heart with a happy face, and two small faces
    s += P("M100 168 C40 120 30 80 58 62 C78 50 96 60 100 76 C104 60 122 50 142 62 C170 80 160 120 100 168 Z", "#FF6B9A")
    s += C(84, 98, 5, OUT, False) + C(116, 98, 5, OUT, False)
    s += P("M80 118 Q100 136 120 118", "none", 5)
    s += C(34, 46, 16, "#FFD93D") + P("M27 50 Q34 56 41 50", "none", 3) + C(29, 42, 2.5, OUT, False) + C(39, 42, 2.5, OUT, False)
    s += C(168, 44, 16, "#8FD3FF") + P("M161 52 Q168 46 175 52", "none", 3) + C(163, 41, 2.5, OUT, False) + C(173, 41, 2.5, OUT, False)
    return s


def icon_breathe():
    s = ground()
    # a balloon breathing in, with soft rings
    s += C(100, 86, 62, "#BFE3FF", False, op=0.5)
    s += C(100, 86, 46, "#8FD3FF")
    s += shine(84, 68, 10, 14)
    s += P("M100 132 L94 140 L106 140 Z", "#8FD3FF")
    s += P("M100 140 Q90 156 104 172", "none", 3)
    s += P("M36 150 Q50 140 64 150 M136 150 Q150 140 164 150", "none", 3, op=0.4)
    return s


def icon_starhop():
    s = ground()
    # a star over a puff cloud and a spring
    s += P("M34 92 Q22 92 24 78 Q26 64 42 66 Q46 44 70 46 Q90 34 106 52 Q128 50 128 72 Q136 92 116 92 Z", "#FFFFFF")
    s += C(66, 72, 3.5, OUT, False) + C(86, 72, 3.5, OUT, False)
    s += E(58, 80, 5, 3, "#FF9DB3", False, op=0.8) + E(94, 80, 5, 3, "#FF9DB3", False, op=0.8)
    s += P(star_path(140, 110, 34, 0.42), "#FFD93D", 4)
    s += R(42, 150, 48, 12, 6, "#FF5A5F")
    s += P("M50 162 L82 170 L50 176", "none", 3)
    return s


def icon_surprise():
    s = ground()
    # a gift box with a question mark
    s += R(40, 92, 120, 80, 8, "#7C4DFF")
    s += R(32, 74, 136, 26, 6, "#9B7BFF")
    s += R(92, 74, 16, 98, 2, "#FFD93D")
    s += P("M100 74 Q76 44 66 62 Q62 74 100 74 Q138 74 134 62 Q124 44 100 74 Z", "#FFD93D")
    s += T(132, 150, "?", 40)
    s += star(30, 40, 9) + star(170, 36, 8)
    return s


ICONS = {"icon_reading": icon_reading, "icon_market": icon_market, "icon_science": icon_science,
         "icon_music": icon_music, "icon_garden": icon_garden,
         "icon_writing": icon_writing, "icon_clock": icon_clock, "icon_world": icon_world, "icon_dash": icon_dash,
         "icon_spelling": icon_spelling, "icon_fractions": icon_fractions, "icon_shapes": icon_shapes, "icon_story": icon_story,
         "icon_rhyme": icon_rhyme, "icon_numbers": icon_numbers, "icon_times": icon_times, "icon_measure": icon_measure,
         "icon_feelings": icon_feelings, "icon_breathe": icon_breathe, "icon_starhop": icon_starhop, "icon_surprise": icon_surprise}


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
