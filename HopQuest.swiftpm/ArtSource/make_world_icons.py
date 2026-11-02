"""Original pictures for the story worlds and their levels (v9.11), replacing the emoji on the world cards
and level buttons. Same ink-outline style as make_learn_icons.py.

Usage: python3 make_world_icons.py <Assets.xcassets dir>
Writes world_<id>.imageset (5) and chapter_<n>.imageset (levels 7–21) as 300x300 PNGs.
"""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_characters import OUT, E, C, P, R, shine, star_path  # noqa: E402
from make_world import svg  # noqa: E402

SNOW = "#FFFFFF"
ICE = "#CFEFFF"


def ground(cx=100, w=74):
    return E(cx, 180, w, 9, "#000000", False, op=0.16)


def star(x, y, r, fill="#FFD93D"):
    return P(star_path(x, y, r, 0.42), fill, 3)


def pine(x, y, s=1.0, snow=False):
    h = 46 * s
    out = R(x - 4 * s, y, 8 * s, 14 * s, 2, "#8B5A2B")
    out += P(f"M{x} {y - h} L{x + 22 * s} {y + 2} L{x - 22 * s} {y + 2} Z", "#2E8B57")
    if snow:
        out += P(f"M{x} {y - h} L{x + 9 * s} {y - h + 18 * s} Q{x} {y - h + 12 * s} {x - 9 * s} {y - h + 18 * s} Z", SNOW, 2)
    return out


def line(d, color, w):
    """A thick colored line with an ink outline."""
    return (f'<path d="{d}" fill="none" stroke="{OUT}" stroke-width="{w + 6}" stroke-linecap="round"/>'
            f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{w}" stroke-linecap="round"/>')


def bubble(x, y, r):
    return C(x, y, r, "#E8F7FF", 2.5) + C(x - r * 0.35, y - r * 0.35, r * 0.28, "#FFFFFF", False)


def cloud(cx, cy, s=1.0, fill="#FFFFFF"):
    d = (f"M{cx - 40 * s} {cy + 14 * s} Q{cx - 56 * s} {cy + 14 * s} {cx - 52 * s} {cy - 2 * s} Q{cx - 50 * s} {cy - 18 * s} {cx - 30 * s} {cy - 14 * s} "
         f"Q{cx - 24 * s} {cy - 38 * s} {cx} {cy - 34 * s} Q{cx + 22 * s} {cy - 44 * s} {cx + 34 * s} {cy - 18 * s} "
         f"Q{cx + 56 * s} {cy - 18 * s} {cx + 54 * s} {cy + 2 * s} Q{cx + 56 * s} {cy + 14 * s} {cx + 40 * s} {cy + 14 * s} Z")
    return P(d, fill)


# ---------- worlds ----------

def world_snowy():
    s = ground()
    s += P("M14 172 L78 52 L142 172 Z", "#8FA7C9")
    s += P("M78 52 L98 90 Q86 84 78 96 Q70 84 58 90 Z", SNOW, 3)
    s += P("M70 172 L134 70 L192 172 Z", "#A9BEDC")
    s += P("M134 70 L152 102 Q142 96 134 106 Q124 96 116 102 Z", SNOW, 3)
    s += pine(40, 150, 0.7, True) + pine(166, 154, 0.6, True)
    s += C(160, 34, 4, SNOW, False) + C(30, 40, 3, SNOW, False) + C(110, 26, 3, SNOW, False)
    return s


def world_shores():
    s = ground()
    s += P("M10 150 Q60 136 100 146 T190 146 L190 176 L10 176 Z", "#4FB6E8")
    s += P("M30 176 Q100 120 170 176 Z", "#F6D48B")
    s += P("M100 152 L104 66", "none", 5)
    s += P("M50 76 Q104 22 158 76 Q140 66 122 76 Q104 64 86 76 Q68 66 50 76 Z", "#FF6B6B")
    s += P("M86 76 Q104 30 104 30 M122 76 Q104 30 104 30", "none", 3)
    s += C(160, 34, 14, "#FFD93D")
    s += P("M64 160 L72 150 L80 160 L74 168 L68 168 Z", "#FF9F45", 3)
    return s


def world_jungle():
    s = ground()
    s += E(100, 172, 70, 12, "#3E9B52")
    for x, lean in ((70, -1), (130, 1)):
        s += line(f"M{x} 172 Q{x + lean * 6} 120 {x + lean * 14} 70", "#A9744F", 9)
        tx, ty = x + lean * 14, 70
        for ang in (-165, -125, -55, -15, 35, 145):
            a = math.radians(ang)
            s += E(tx + math.cos(a) * 24, ty + math.sin(a) * 14 + 4, 27, 10, "#34C77B", rot=ang)
        s += C(tx - 6, ty + 10, 6, "#8B5A2B") + C(tx + 6, ty + 12, 6, "#8B5A2B")
    s += P("M90 176 Q100 150 112 176", "#5FC86A")
    return s


def world_sky():
    s = ""
    s += cloud(100, 150, 1.2, "#FFFFFF")
    s += P("M40 112 Q100 96 160 112 L140 140 Q100 158 60 140 Z", "#B07A52")
    s += P("M40 112 Q100 96 160 112 Q100 122 40 112 Z", "#6FD08C")
    s += R(116, 72, 22, 34, 4, "#FFF1E6") + P("M112 74 L127 58 L142 74 Z", "#FF6B6B")
    s += pine(74, 104, 0.55)
    s += P("M150 40 Q160 30 170 40 M164 50 Q172 44 180 50", "none", 3, op=0.6)
    s += star(36, 44, 8)
    return s


def world_ocean():
    s = ""
    s += P("M40 100 Q70 54 128 66 Q150 72 158 100 Q150 128 128 134 Q70 146 40 100 Z", "#FFB547")
    s += P("M156 100 L188 74 L184 100 L188 126 Z", "#FF8A3D")
    s += P("M88 60 Q100 40 118 64 Z", "#FF8A3D") + P("M92 138 Q104 156 118 136 Z", "#FF8A3D")
    s += P("M78 70 Q70 100 78 130 M104 66 Q96 100 104 134", "none", 6, op=0.9)
    s += P("M78 70 Q70 100 78 130 M104 66 Q96 100 104 134", "none", False)
    s += P("M78 70 Q70 100 78 130", "#FFFFFF", False, op=0.0)
    s += C(62, 92, 9, "#FFFFFF") + C(64, 93, 4.5, OUT, False)
    s += P("M46 110 Q54 116 62 112", "none", 3)
    s += bubble(36, 62, 8) + bubble(24, 40, 5) + bubble(166, 46, 6)
    return s


# ---------- levels ----------

def ch_frosty():
    s = ground()
    s += P("M70 178 Q90 140 104 120 Q118 100 140 90 L150 96 Q128 110 118 130 Q106 152 96 178 Z", "#E8F4FF")
    s += pine(46, 150, 0.8, True) + pine(158, 140, 0.65, True)
    # a big snowflake
    cx, cy = 100, 62
    for k in range(6):
        a = math.radians(k * 60)
        x2, y2 = cx + math.cos(a) * 34, cy + math.sin(a) * 34
        s += P(f"M{cx} {cy} L{x2:.1f} {y2:.1f}", "none", 6)
        for side in (-1, 1):
            b = a + side * math.radians(40)
            mx, my = cx + math.cos(a) * 20, cy + math.sin(a) * 20
            s += P(f"M{mx:.1f} {my:.1f} L{mx + math.cos(b) * 11:.1f} {my + math.sin(b) * 11:.1f}", "none", 5)
    s += C(cx, cy, 7, ICE)
    return s


def ch_icylake():
    s = ground()
    s += E(100, 140, 84, 34, "#9ED8F5")
    s += P("M60 132 L84 142 L76 156 M110 128 L126 146 L146 140", "none", 3, op=0.6)
    s += shine(72, 128, 18, 5, rot=-8, op=0.6)
    s += P("M84 78 L124 70 L132 104 L92 112 Z", ICE) + shine(98, 84, 8, 4, op=0.6)
    s += P("M124 70 L140 82 L132 104", "#A9DDF5", 3)
    s += pine(30, 124, 0.6, True) + pine(176, 122, 0.55, True)
    return s


def castle(x, y, w, h, wall, roof):
    out = R(x, y, w, h, 3, wall)
    tw = w * 0.32
    out += R(x - tw * 0.4, y - h * 0.35, tw, h * 1.35, 3, wall) + R(x + w - tw * 0.6, y - h * 0.35, tw, h * 1.35, 3, wall)
    out += P(f"M{x - tw * 0.55} {y - h * 0.35} L{x - tw * 0.4 + tw / 2} {y - h * 0.9} L{x + tw * 0.75} {y - h * 0.35} Z", roof)
    out += P(f"M{x + w - tw * 0.75} {y - h * 0.35} L{x + w - tw * 0.6 + tw / 2} {y - h * 0.9} L{x + w + tw * 0.55} {y - h * 0.35} Z", roof)
    out += P(f"M{x + w / 2 - 10} {y + h} L{x + w / 2 - 10} {y + h - 18} Q{x + w / 2} {y + h - 30} {x + w / 2 + 10} {y + h - 18} L{x + w / 2 + 10} {y + h} Z", "#7A4B23")
    return out


def ch_peakcastle():
    s = ground()
    s += P("M10 178 L100 70 L190 178 Z", "#A9BEDC")
    s += P("M100 70 L124 100 Q112 94 100 104 Q88 94 76 100 Z", SNOW, 3)
    s += castle(72, 120, 56, 40, "#E8EEF8", "#4D96FF")
    s += P("M100 60 L100 30 L120 37 L100 44", "#FF6B6B", 3)
    return s


def ch_sandypath():
    s = ground()
    s += P("M14 176 Q100 130 186 176 Z", "#F6D48B")
    # a scallop shell
    s += P("M100 150 L58 84 Q100 40 142 84 Z", "#FFB3C7")
    for k in range(-2, 3):
        s += P(f"M100 150 L{100 + k * 20} {70 - abs(k) * 6}", "none", 3)
    s += R(88, 146, 24, 14, 5, "#FF9DB3")
    s += P("M154 160 L160 146 L166 160 L180 160 L169 168 L173 182 L160 174 L147 182 L151 168 L140 160 Z", "#FF9F45", 3)
    return s


def ch_tidepools():
    s = ground()
    s += E(100, 156, 82, 26, "#4FB6E8") + E(64, 148, 16, 6, "#FFFFFF", False, op=0.5)
    s += E(30, 150, 20, 14, "#9AA6B8") + E(172, 154, 22, 14, "#9AA6B8")
    # a friendly crab
    s += E(100, 120, 40, 26, "#FF6B6B")
    for side in (-1, 1):
        s += P(f"M{100 + side * 36} 122 L{100 + side * 50} 140 M{100 + side * 30} 130 L{100 + side * 42} 148", "none", 5)
        s += P(f"M{100 + side * 30} 108 Q{100 + side * 50} 86 {100 + side * 54} 76", "none", 6)
        s += C(100 + side * 58, 70, 13, "#FF6B6B") + P(f"M{100 + side * 58} 70 L{100 + side * 66} 62", "none", 4)
        s += P(f"M{100 + side * 10} 98 L{100 + side * 12} 80", "none", 4) + C(100 + side * 12, 76, 7, "#FFFFFF") + C(100 + side * 12, 77, 3.5, OUT, False)
    s += P("M90 126 Q100 134 110 126", "none", 3)
    return s


def ch_lighthouse():
    s = ground()
    s += P("M40 178 Q60 140 100 144 Q140 140 160 178 Z", "#9AA6B8")
    s += P("M84 150 L90 64 L110 64 L116 150 Z", "#FFFFFF")
    for y0 in (78, 106, 134):
        s += P(f"M{88 - (y0 - 64) * 0.07:.1f} {y0} L{112 + (y0 - 64) * 0.07:.1f} {y0} L{113 + (y0 + 14 - 64) * 0.07:.1f} {y0 + 14} L{87 - (y0 + 14 - 64) * 0.07:.1f} {y0 + 14} Z", "#FF6B6B", 3)
    s += R(86, 44, 28, 20, 4, "#FFD93D") + P("M82 44 L100 26 L118 44 Z", "#FF6B6B")
    s += P("M114 50 L176 34 L176 66 Z", "#FFF3B0", False, op=0.7) + P("M86 50 L24 34 L24 66 Z", "#FFF3B0", False, op=0.7)
    return s


def ch_vines():
    s = ground()
    s += P("M20 20 Q100 46 180 20", "none", 8) + P("M20 20 Q100 46 180 20", "#3E9B52", False)
    s += P("M100 36 Q96 70 100 96", "none", 5)
    for x, y in ((50, 30), (150, 30), (78, 36), (124, 36)):
        s += E(x, y + 8, 9, 5, "#34C77B", rot=30)
    # a monkey hanging on
    s += C(100, 120, 30, "#A9744F")
    s += E(100, 128, 20, 16, "#F2C9A0")
    s += C(72, 112, 10, "#F2C9A0") + C(128, 112, 10, "#F2C9A0")
    s += C(90, 114, 4, OUT, False) + C(110, 114, 4, OUT, False)
    s += P("M92 134 Q100 140 108 134", "none", 3)
    s += P("M84 96 Q90 86 100 96", "none", 5)
    s += P("M122 140 Q150 160 140 176", "none", 6)
    return s


def ch_hippo():
    s = ground()
    s += P("M10 130 Q55 120 100 128 T190 128 L190 176 L10 176 Z", "#4FB6E8")
    s += E(100, 116, 54, 34, "#B39DDB")
    s += E(100, 128, 40, 22, "#C9B6EA")
    s += E(86, 126, 5, 7, OUT, False) + E(114, 126, 5, 7, OUT, False)
    s += C(76, 90, 12, "#FFFFFF") + C(124, 90, 12, "#FFFFFF") + C(78, 92, 5, OUT, False) + C(122, 92, 5, OUT, False)
    s += E(64, 80, 9, 7, "#B39DDB") + E(136, 80, 9, 7, "#B39DDB")
    s += P("M10 140 Q55 132 100 140 T190 140", "none", 3, op=0.5)
    s += bubble(158, 104, 6)
    return s


def ch_temple():
    s = ground()
    for k, (w, y) in enumerate(((150, 150), (118, 124), (88, 98), (58, 72))):
        s += R(100 - w / 2, y, w, 28, 3, "#C9B48A" if k % 2 == 0 else "#B8A276")
    s += R(88, 52, 24, 20, 3, "#B8A276") + P("M92 72 L92 60 Q100 52 108 60 L108 72 Z", "#6B5A3E")
    s += P("M100 178 L100 150", "none", 3, op=0.3)
    s += P("M20 120 Q34 100 52 112 Q40 128 20 120 Z", "#34C77B") + P("M180 110 Q164 92 148 106 Q162 120 180 110 Z", "#34C77B")
    s += star(100, 32, 9)
    return s


def ch_cloudmeadow():
    s = ""
    s += cloud(100, 130, 1.3)
    for x, col in ((62, "#FF6B9A"), (90, "#FFD93D"), (118, "#B983FF"), (144, "#FF9F45")):
        s += P(f"M{x} 104 L{x} 84", "none", 3)
        for k in range(5):
            a = math.radians(k * 72)
            s += C(x + math.cos(a) * 7, 78 + math.sin(a) * 7, 6, col, 2)
        s += C(x, 78, 4.5, "#FFF3B0", 2)
    s += star(36, 46, 8) + star(168, 40, 6)
    return s


def ch_windmill():
    s = cloud(100, 168, 0.9)
    s += P("M54 150 Q100 136 146 150 L128 166 Q100 174 72 166 Z", "#B07A52") + P("M54 150 Q100 136 146 150 Q100 158 54 150 Z", "#6FD08C")
    s += P("M84 146 L90 78 L110 78 L116 146 Z", "#FFF1E6")
    s += P("M84 80 L100 62 L116 80 Z", "#FF6B6B")
    s += R(94, 120, 12, 26, 5, "#8B5A2B")
    cx, cy = 100, 76
    for k in range(4):
        a = math.radians(k * 90 + 20)
        b = a + math.radians(18)
        s += P(f"M{cx} {cy} L{cx + math.cos(a) * 52:.1f} {cy + math.sin(a) * 52:.1f} L{cx + math.cos(b) * 50:.1f} {cy + math.sin(b) * 50:.1f} Z", "#E8F4FF")
    s += C(cx, cy, 6, "#FFD93D")
    return s


def ch_rainbow():
    s = ""
    cols = ["#FF6B6B", "#FF9F45", "#FFD93D", "#5FC86A", "#4D96FF", "#B983FF"]
    for k, col in enumerate(cols):
        r = 78 - k * 9
        s += P(f"M{100 - r} 140 A{r} {r} 0 0 1 {100 + r} 140", "none", 11)
        s += P(f"M{100 - r} 140 A{r} {r} 0 0 1 {100 + r} 140", "none", False).replace('fill="none"', f'fill="none" stroke="{col}" stroke-width="8"')
    s += cloud(34, 150, 0.6) + cloud(166, 150, 0.6)
    return s


def ch_kelp():
    s = ground()
    s += P("M10 170 Q100 156 190 170 L190 182 L10 182 Z", "#F2D58A")
    for x, h, col in ((50, 120, "#2E8B57"), (88, 140, "#3E9B52"), (128, 110, "#2E8B57"), (160, 130, "#3E9B52")):
        s += P(f"M{x} 172 Q{x - 14} {172 - h * 0.35} {x} {172 - h * 0.6} Q{x + 14} {172 - h * 0.85} {x} {172 - h}", "none", 9)
        s += P(f"M{x} 172 Q{x - 14} {172 - h * 0.35} {x} {172 - h * 0.6} Q{x + 14} {172 - h * 0.85} {x} {172 - h}", "none", False).replace('fill="none"', f'fill="none" stroke="{col}" stroke-width="5"')
        s += E(x + 10, 172 - h * 0.5, 9, 5, col, rot=-30)
    s += P("M100 70 Q112 60 124 70 Q112 80 100 70 Z", "#FFB547") + P("M124 70 L134 62 L134 78 Z", "#FFB547") + C(106, 69, 2.5, OUT, False)
    s += bubble(70, 50, 6) + bubble(150, 40, 5)
    return s


def ch_turtle():
    s = ""
    s += E(96, 108, 56, 38, "#5FC86A")
    s += P("M60 108 Q96 70 132 108 Q96 130 60 108 Z", "#3E9B52", 3)
    s += P("M78 96 L96 86 L114 96 L110 112 L82 112 Z", "#2E7D4F", 3)
    s += C(160, 98, 18, "#8FD3A0") + C(166, 92, 5, "#FFFFFF") + C(167, 93, 2.5, OUT, False) + P("M160 106 Q166 110 172 106", "none", 2.5)
    for x, y, rot in ((60, 136, 30), (126, 140, -30), (54, 80, -30), (128, 76, 30)):
        s += E(x, y, 16, 8, "#8FD3A0", rot=rot)
    s += bubble(36, 50, 7) + bubble(180, 54, 5) + bubble(168, 30, 4)
    return s


def ch_coralcastle():
    s = ground()
    s += P("M10 170 Q100 156 190 170 L190 182 L10 182 Z", "#F2D58A")
    s += castle(66, 110, 68, 56, "#FFB3C7", "#B983FF")
    s += P("M100 76 L100 50 L118 56 L100 62", "#FFD93D", 3)
    s += P("M30 172 L30 136 M30 150 L18 130 M30 146 L44 126", "none", 6) + P("M30 172 L30 136 M30 150 L18 130 M30 146 L44 126", "none", False)
    s += P("M30 172 L30 136 M30 150 L18 130 M30 146 L44 126", "none", 3).replace('stroke="' + OUT + '"', 'stroke="#FF6B6B"')
    s += P("M168 172 Q160 140 172 124 Q186 140 176 172 Z", "#FF9F45")
    s += bubble(150, 60, 7) + bubble(40, 70, 5) + bubble(164, 36, 4)
    return s


ART = {
    "world_snowy-peaks": world_snowy, "world_sunny-shores": world_shores, "world_jungle-journey": world_jungle,
    "world_sky-islands": world_sky, "world_ocean-deep": world_ocean,
    "chapter_7": ch_frosty, "chapter_8": ch_icylake, "chapter_9": ch_peakcastle,
    "chapter_10": ch_sandypath, "chapter_11": ch_tidepools, "chapter_12": ch_lighthouse,
    "chapter_13": ch_vines, "chapter_14": ch_hippo, "chapter_15": ch_temple,
    "chapter_16": ch_cloudmeadow, "chapter_17": ch_windmill, "chapter_18": ch_rainbow,
    "chapter_19": ch_kelp, "chapter_20": ch_turtle, "chapter_21": ch_coralcastle,
}

if __name__ == "__main__":
    from playwright.sync_api import sync_playwright
    assets = sys.argv[1]
    with sync_playwright() as p:
        b = p.chromium.launch()
        for name, fn in ART.items():
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
    print("ok", len(ART))
