"""Three HopQuest app-icon options (1024 x 1024, opaque, iOS masks the corners).

Each is composed from the game's own vector art (characters, castles, balloons)
plus a background drawn here, so the icon matches the in-game style exactly.
Usage: python3 make_icons.py <out_dir> [font.woff2]
"""
import base64
import os
import sys

from playwright.sync_api import sync_playwright

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1]
FONT = sys.argv[2] if len(sys.argv) > 2 else None
os.makedirs(OUT, exist_ok=True)
INK = "#2B1B3D"


def svg_uri(path):
    return "data:image/svg+xml;base64," + base64.b64encode(open(os.path.join(HERE, path), "rb").read()).decode()


lav = svg_uri("svg/lavender.svg")
castle_rb = svg_uri("world_svg/castle_rainbow.svg")
castle_sp = svg_uri("world_svg/castle_sparkle.svg")
balloon_rb = svg_uri("world_svg/balloon_rainbow.svg")
balloon_front = svg_uri("world_svg/balloon_front.svg")

font_face = ""
if FONT:
    f = base64.b64encode(open(FONT, "rb").read()).decode()
    font_face = f"@font-face{{font-family:Kid;font-weight:900;src:url(data:font/woff2;base64,{f}) format('woff2')}}"

BASE = f"""<style>{font_face}
*{{margin:0;box-sizing:border-box}} body{{width:1024px;height:1024px;overflow:hidden;position:relative}}
.a{{position:absolute}}
</style>"""


def star(cx, cy, r, fill="#FFD93D", sw=10):
    import math
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        rr = r if i % 2 == 0 else r * 0.45
        pts.append(f"{cx + rr * math.cos(a):.1f},{cy + rr * math.sin(a):.1f}")
    return f'<polygon points="{" ".join(pts)}" fill="{fill}" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round"/>'


def cloud(x, y, s, op=1):
    return (f'<g opacity="{op}" transform="translate({x} {y}) scale({s})">'
            '<ellipse cx="0" cy="30" rx="110" ry="42" fill="#fff"/><circle cx="-40" cy="0" r="48" fill="#fff"/>'
            '<circle cx="30" cy="-12" r="60" fill="#fff"/><circle cx="80" cy="20" r="40" fill="#fff"/></g>')


# ---------------------------------------------------------------- 1. "Hop!" — Lavender mid-hop over a crosswalk
def icon_hop():
    bg = f"""<svg class="a" width="1024" height="1024" viewBox="0 0 1024 1024" style="left:0;top:0">
      <defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FD3FF"/><stop offset="1" stop-color="#D8F7FF"/></linearGradient></defs>
      <rect width="1024" height="1024" fill="url(#sky)"/>
      {cloud(170, 170, 1.0, 0.95)}{cloud(860, 120, 0.8, 0.9)}
      <path d="M0 610 Q260 540 520 590 Q790 640 1024 570 L1024 1024 L0 1024 Z" fill="#7EDB7E"/>
      <path d="M0 640 Q260 580 520 630 Q790 680 1024 610" fill="none" stroke="#5CC46A" stroke-width="14"/>
      <!-- road -->
      <path d="M0 760 L1024 700 L1024 900 L0 960 Z" fill="#5A6275" stroke="{INK}" stroke-width="12" stroke-linejoin="round"/>
      <path d="M40 862 L1000 806" stroke="#FFD93D" stroke-width="16" stroke-dasharray="70 50" stroke-linecap="round"/>
      <!-- crosswalk stripes -->
      {''.join(f'<path d="M{380 + i * 64} {744 - i * 3.8} L{420 + i * 64} {742 - i * 3.8} L{410 + i * 64} {934 - i * 3.8} L{370 + i * 64} {936 - i * 3.8} Z" fill="#FFFFFF" opacity="0.92"/>' for i in range(5))}
      <!-- hop arc -->
      <path d="M70 880 Q170 520 330 640" fill="none" stroke="#FFFFFF" stroke-width="18" stroke-dasharray="4 40" stroke-linecap="round" opacity="0.95"/>
      {star(120, 420, 44)}{star(900, 560, 30)}
      <ellipse cx="512" cy="868" rx="170" ry="28" fill="#000" opacity="0.25"/>
    </svg>"""
    return f"""{BASE}<body>{bg}
      <img src="{castle_rb}" class="a" style="left:700px;top:250px;width:270px">
      <img src="{lav}" class="a" style="left:240px;top:150px;width:560px;transform:rotate(-8deg)">
    </body>"""


# ---------------------------------------------------------------- 2. "Balloon Quest" — buddy in the hot air balloon over the castle
def icon_balloon():
    bg = f"""<svg class="a" width="1024" height="1024" viewBox="0 0 1024 1024" style="left:0;top:0">
      <defs>
        <linearGradient id="dusk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8E6CFF"/><stop offset="0.55" stop-color="#FF9ECF"/><stop offset="1" stop-color="#FFE29A"/></linearGradient>
        <radialGradient id="sun" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFF6B3"/><stop offset="1" stop-color="#FFF6B3" stop-opacity="0"/></radialGradient>
      </defs>
      <rect width="1024" height="1024" fill="url(#dusk)"/>
      <circle cx="512" cy="560" r="420" fill="url(#sun)" opacity="0.7"/>
      {''.join(star(x, y, r, '#FFFFFF', 0) for x, y, r in ((120, 140, 18), (900, 210, 14), (180, 420, 10), (860, 470, 12), (760, 90, 10)))}
      {cloud(160, 640, 1.1, 0.95)}{cloud(880, 600, 0.9, 0.9)}
      <path d="M0 860 Q512 700 1024 860 L1024 1024 L0 1024 Z" fill="#5CC46A" stroke="{INK}" stroke-width="12"/>
      <path d="M0 930 Q512 820 1024 930 L1024 1024 L0 1024 Z" fill="#7EDB7E"/>
    </svg>"""
    # balloon (220x380 art) with Lavender in the basket, same stacking as the game's BalloonView
    bw = 450
    bh = bw * 380 / 220
    bx, by = 512 - bw / 2, 22
    rider = bw * 0.44
    rider_top = by + bh * 340 / 380 - rider * 1.0
    return f"""{BASE}<body>{bg}
      <img src="{castle_rb}" class="a" style="left:700px;top:620px;width:270px">
      <img src="{balloon_rb}" class="a" style="left:{bx}px;top:{by}px;width:{bw}px;height:{bh}px">
      <img src="{lav}" class="a" style="left:{512 - rider / 2}px;top:{rider_top}px;width:{rider}px">
      <img src="{balloon_front}" class="a" style="left:{bx}px;top:{by}px;width:{bw}px;height:{bh}px">
    </body>"""


# ---------------------------------------------------------------- 3. "HQ badge" — bold lettering, buddy peeking over
def icon_badge():
    import math
    rays = "".join(
        f'<path d="M512 560 L{512 + 900 * math.cos(math.radians(a - 7))} {560 + 900 * math.sin(math.radians(a - 7))} '
        f'L{512 + 900 * math.cos(math.radians(a + 7))} {560 + 900 * math.sin(math.radians(a + 7))} Z" fill="#FFFFFF" opacity="0.10"/>'
        for a in range(0, 360, 30))
    bg = f"""<svg class="a" width="1024" height="1024" viewBox="0 0 1024 1024" style="left:0;top:0">
      <defs><radialGradient id="g" cx="0.5" cy="0.55" r="0.75"><stop offset="0" stop-color="#B983FF"/><stop offset="1" stop-color="#6A3BE8"/></radialGradient></defs>
      <rect width="1024" height="1024" fill="url(#g)"/>{rays}
      {star(150, 170, 44)}{star(880, 180, 34)}{star(890, 860, 40, '#FF7FC4')}{star(130, 870, 30, '#7FD8FF')}
    </svg>"""
    word = (f'<div class="a" style="left:0;right:0;top:500px;text-align:center;font-family:Kid,Inter,sans-serif;font-weight:900;'
            f'font-size:390px;line-height:1;letter-spacing:-8px;color:#FFD93D;'
            f'-webkit-text-stroke:26px {INK};paint-order:stroke fill;text-shadow:0 22px 0 {INK}">'
            f'H<span style="color:#FF7FC4">Q</span></div>')
    return f"""{BASE}<body>{bg}
      <img src="{lav}" class="a" style="left:292px;top:150px;width:440px">
      {word}
    </body>"""


# ---------------------------------------------------------------- Hop + Balloon combinations
def road(y0=760, y1=700, dash=True):
    """Diagonal road with a crosswalk, same as option 1. y0 = left top edge, y1 = right top edge."""
    h = 200
    out = (f'<path d="M0 {y0} L1024 {y1} L1024 {y1 + h} L0 {y0 + h} Z" fill="#5A6275" stroke="{INK}" stroke-width="12" stroke-linejoin="round"/>')
    if dash:
        out += f'<path d="M40 {y0 + 102} L1000 {y1 + 46}" stroke="#FFD93D" stroke-width="16" stroke-dasharray="70 50" stroke-linecap="round"/>'
    slope = (y1 - y0) / 1024
    for i in range(5):
        x = 380 + i * 64
        top = y0 + slope * x
        t2 = top + slope * 40
        out += (f'<path d="M{x} {top + 18} L{x + 40} {t2 + 18} L{x + 40} {t2 + h - 18} L{x} {top + h - 18} Z" '
                f'fill="#FFFFFF" opacity="0.92"/>')
    return out


def balloon_html(cx, top, bw, rider_scale=0.44, char=None):
    bh = bw * 380 / 220
    bx = cx - bw / 2
    html = f'<img src="{balloon_rb}" class="a" style="left:{bx}px;top:{top}px;width:{bw}px;height:{bh}px">'
    if char:
        r = bw * rider_scale
        html += f'<img src="{char}" class="a" style="left:{cx - r / 2}px;top:{top + bh * 340 / 380 - r}px;width:{r}px">'
    html += f'<img src="{balloon_front}" class="a" style="left:{bx}px;top:{top}px;width:{bw}px;height:{bh}px">'
    return html


def sky_day():
    return ('<defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FD3FF"/>'
            '<stop offset="1" stop-color="#D8F7FF"/></linearGradient></defs><rect width="1024" height="1024" fill="url(#sky)"/>')


def sky_sunset():
    return ('<defs><linearGradient id="dusk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8E6CFF"/>'
            '<stop offset="0.55" stop-color="#FF9ECF"/><stop offset="1" stop-color="#FFE29A"/></linearGradient>'
            '<radialGradient id="sun" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFF6B3"/>'
            '<stop offset="1" stop-color="#FFF6B3" stop-opacity="0"/></radialGradient></defs>'
            '<rect width="1024" height="1024" fill="url(#dusk)"/><circle cx="700" cy="420" r="380" fill="url(#sun)" opacity="0.7"/>')


# A. Daytime: Lavender hops the crosswalk toward a balloon waiting in the sky
def combo_a():
    bg = f"""<svg class="a" width="1024" height="1024" viewBox="0 0 1024 1024" style="left:0;top:0">{sky_day()}
      {cloud(150, 150, 0.9, 0.95)}{cloud(560, 90, 0.6, 0.85)}
      <path d="M0 610 Q260 540 520 590 Q790 640 1024 570 L1024 1024 L0 1024 Z" fill="#7EDB7E"/>
      <path d="M0 640 Q260 580 520 630 Q790 680 1024 610" fill="none" stroke="#5CC46A" stroke-width="14"/>
      {road()}
      <path d="M70 880 Q150 560 260 600" fill="none" stroke="#FFFFFF" stroke-width="18" stroke-dasharray="4 40" stroke-linecap="round"/>
      {star(110, 430, 40)}{star(610, 300, 24)}
      <ellipse cx="420" cy="878" rx="150" ry="26" fill="#000" opacity="0.25"/>
    </svg>"""
    return f"""{BASE}<body>{bg}
      {balloon_html(800, 40, 330)}
      <img src="{lav}" class="a" style="left:160px;top:210px;width:520px;transform:rotate(-8deg)">
    </body>"""


# B. Sunset: same hop, the balloon is landing on the hill with the castle behind
def combo_b():
    bg = f"""<svg class="a" width="1024" height="1024" viewBox="0 0 1024 1024" style="left:0;top:0">{sky_sunset()}
      {''.join(star(x, y, r, '#FFFFFF', 0) for x, y, r in ((110, 120, 16), (470, 70, 12), (940, 90, 12)))}
      {cloud(170, 330, 0.9, 0.9)}
      <path d="M0 620 Q300 520 620 600 Q840 650 1024 590 L1024 1024 L0 1024 Z" fill="#7EDB7E"/>
      <path d="M0 650 Q300 560 620 640 Q840 690 1024 630" fill="none" stroke="#5CC46A" stroke-width="14"/>
      {road()}
      <path d="M70 880 Q150 560 250 610" fill="none" stroke="#FFFFFF" stroke-width="18" stroke-dasharray="4 40" stroke-linecap="round"/>
      <ellipse cx="410" cy="878" rx="150" ry="26" fill="#000" opacity="0.25"/>
    </svg>"""
    return f"""{BASE}<body>{bg}
      <img src="{castle_rb}" class="a" style="left:740px;top:400px;width:240px">
      {balloon_html(690, 70, 300)}
      <img src="{lav}" class="a" style="left:150px;top:220px;width:510px;transform:rotate(-8deg)">
    </body>"""


# C. Lavender already in the balloon, floating up over the crosswalk toward the castle
def combo_c():
    bg = f"""<svg class="a" width="1024" height="1024" viewBox="0 0 1024 1024" style="left:0;top:0">{sky_day()}
      {cloud(140, 260, 0.9, 0.95)}{cloud(900, 380, 0.75, 0.9)}
      {star(130, 110, 36)}{star(920, 150, 28)}
      <path d="M0 700 Q260 640 520 690 Q790 740 1024 670 L1024 1024 L0 1024 Z" fill="#7EDB7E"/>
      {road(830, 770)}
      <path d="M300 900 Q300 760 440 700" fill="none" stroke="#FFFFFF" stroke-width="16" stroke-dasharray="4 36" stroke-linecap="round"/>
    </svg>"""
    return f"""{BASE}<body>{bg}
      <img src="{castle_rb}" class="a" style="left:770px;top:470px;width:220px">
      {balloon_html(512, 20, 430, 0.56, lav)}
    </body>"""


ICONS = {"icon_option_1_hop": icon_hop, "icon_option_2_balloon": icon_balloon, "icon_option_3_badge": icon_badge,
         "icon_combo_a_day": combo_a, "icon_combo_b_sunset": combo_b, "icon_combo_c_ride": combo_c}

with sync_playwright() as p:
    b = p.chromium.launch()
    for name, fn in ICONS.items():
        page = b.new_page(viewport={"width": 1024, "height": 1024})
        page.set_content(f"<html>{fn()}</html>")
        page.wait_for_timeout(400)
        page.screenshot(path=os.path.join(OUT, f"{name}.png"))
        page.close()
    b.close()
print("ok")
