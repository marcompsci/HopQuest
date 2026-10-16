"""HopQuest — Hop Village pixel art.

Draws every village texture at native pixel resolution with Pillow (no SVG, no filtering):
  village_tiles.png      ground tiles: grass, sand, road, bridge, path (16 edge masks), water (16 masks x 4 frames)
  village_props.png      trees, bushes, fences, lamps, fountain, cars, signs, crane, portal, critters, effects
  village_<building>.png the seven buildings (+ three castle styles)
  px_<buddy>.png         a 4x8 animation sheet for each of the 23 buddies, derived from the original char_<id> art
and writes ../Scenes/VillageAtlas.swift with the sprite rectangles, plus ../Models/VillageMapData.swift.

Run:  python3 make_village.py <Assets.xcassets dir> <package dir>
Style: 1 art pixel = 3 points in game. Ink outline #2B1B3D, three-tone shading, light from the top-left.
"""
import os, sys, json, random, math
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import make_map  # noqa: E402

T = 16
INK = (43, 27, 61, 255)
CLEAR = (0, 0, 0, 0)

def hexc(h, a=255):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)

P = {k: hexc(v) for k, v in dict(
    g0='7BC950', g1='93D962', g2='62B347', g3='4E9A3C', g4='B4E87E',
    p0='EAD9B2', p1='D6C196', p2='B9A177', p3='9A8260',
    w0='4C9BE0', w1='66B6EE', w2='94D6F7', w3='DDF5FF', wd='3A7FC4',
    s0='F2D59A', s1='E2BD7A', s2='C99E58',
    d0='E7C8A0',
    r0='5D6378', r1='4E5468', r2='6C7389', ry='FFD84D', rw='F4F4F4',
    k0='D9A066', k1='B57A45', k2='7D4E2B', k3='5E3820',
    c0='FFF3DC', c1='EBD6B0', c2='C9AE85',
    st0='D3D9E4', st1='AEB7C7', st2='8791A6',
    leaf0='5FBF4A', leaf1='479B3A', leaf2='35792F', leaf3='8AD866',
    blos0='FFB7D5', blos1='F58DB8', blos2='D9659A',
    gold='FFD24D', gold2='E0A92E',
    red='FF6B6B', red2='D94A57', blue='4D96FF', blue2='2F6FD1', purp='B983FF', purp2='8A5AD6',
    orng='FF9F45', orng2='D9731C', teal='3CC9A0', teal2='2A9D7E', pink='FF8CC6', pink2='E0619F',
    win='BFE9FF', win2='86C9F0', glow='FFE9A8', white='FFFFFF',
).items()}

def img(w, h):
    return Image.new('RGBA', (w, h), CLEAR)

def px(im, x, y, c):
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), c)

def rect(im, x0, y0, x1, y1, c):
    ImageDraw.Draw(im).rectangle([x0, y0, x1, y1], fill=c)

def outline_rect(im, x0, y0, x1, y1, fill, ink=INK):
    rect(im, x0, y0, x1, y1, ink)
    if x1 - x0 >= 2 and y1 - y0 >= 2:
        rect(im, x0 + 1, y0 + 1, x1 - 1, y1 - 1, fill)

def ellipse(im, box, fill, outline=None):
    d = ImageDraw.Draw(im)
    d.ellipse(box, fill=fill, outline=outline)

def add_outline(im, ink=INK):
    """1px ink outline around every opaque pixel (outside only)."""
    src = im.copy(); w, h = im.size; a = src.load(); o = im.load()
    for y in range(h):
        for x in range(w):
            if a[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < w and 0 <= yy < h and a[xx, yy][3] > 0:
                        o[x, y] = ink; break
    return im

def rng(seed):
    return random.Random(seed)

# ---------------------------------------------------------------- ground tiles

def grass(v):
    t = img(T, T); rect(t, 0, 0, T - 1, T - 1, P['g0']); r = rng(10 + v)
    for _ in range(14):
        x, y = r.randrange(T), r.randrange(T); px(t, x, y, P['g1'] if r.random() < .6 else P['g2'])
    if v == 1:
        for (x, y) in [(3, 5), (11, 10), (7, 13)]:
            px(t, x, y, P['g3']); px(t, x + 1, y - 1, P['g3']); px(t, x - 1, y - 1, P['g2']); px(t, x, y - 1, P['g1'])
    if v == 2:
        for (x, y, c) in [(4, 4, 'white'), (12, 7, 'gold'), (6, 12, 'pink')]:
            px(t, x, y, P[c]); px(t, x + 1, y, P['g4'])
    if v == 3:
        for _ in range(10):
            x, y = r.randrange(T), r.randrange(T); px(t, x, y, P['g2'])
    return t

def sand(v):
    t = img(T, T); rect(t, 0, 0, T - 1, T - 1, P['s0']); r = rng(30 + v)
    for _ in range(16):
        px(t, r.randrange(T), r.randrange(T), P['s1'] if r.random() < .7 else P['s2'])
    if v:
        px(t, 5, 9, P['st1']); px(t, 6, 9, P['st2']); px(t, 11, 4, P['st1'])
    return t

def road(kind):
    t = img(T, T); rect(t, 0, 0, T - 1, T - 1, P['r0']); r = rng(50)
    for _ in range(18):
        px(t, r.randrange(T), r.randrange(T), P['r1'] if r.random() < .6 else P['r2'])
    if kind == 'cross':
        for x in range(1, T, 4):
            rect(t, x, 1, x + 1, T - 2, P['rw'])
    if kind == 'dash':
        rect(t, 3, 7, 12, 8, P['ry'])
    return t

def bridge():
    t = img(T, T)
    for y in range(0, T, 4):
        rect(t, 0, y, T - 1, y + 3, P['k0']); rect(t, 0, y + 3, T - 1, y + 3, P['k2'])
        px(t, 3 + (y % 8), y + 1, P['k1']); px(t, 10 - (y % 6), y + 2, P['k1'])
    rect(t, 0, 0, 1, T - 1, P['k3']); rect(t, T - 2, 0, T - 1, T - 1, P['k3'])
    return t

def dirt():
    t = img(T, T); rect(t, 0, 0, T - 1, T - 1, P['d0']); r = rng(70)
    for _ in range(14): px(t, r.randrange(T), r.randrange(T), P['s1'])
    return t

N, E, S, Wb = 1, 2, 4, 8   # bit set = that side touches a DIFFERENT terrain (grass)

def path(mask):
    t = img(T, T); rect(t, 0, 0, T - 1, T - 1, P['p0'])
    # cobbles
    r = rng(90 + mask)
    for row in range(4):
        off = 2 if row % 2 else 0
        for col in range(-1, 4):
            x0 = col * 5 + off; y0 = row * 4
            rect(t, x0, y0, x0 + 3, y0 + 2, P['p0'] if r.random() < .7 else P['p1'])
            for x in range(x0, x0 + 5): px(t, x, y0 + 3, P['p2'])
            px(t, x0 + 4, y0, P['p2']); px(t, x0 + 4, y0 + 1, P['p2']); px(t, x0 + 4, y0 + 2, P['p2'])
            px(t, x0, y0, P['c0'])
    # grass lips where the path meets grass
    gl = lambda x, y: px(t, x, y, P['g0'])
    for i in range(T):
        wob = 1 if (i * 7) % 5 == 0 else 0
        if mask & N:
            for y in range(0, 1 + wob): gl(i, y)
            px(t, i, 1 + wob, P['p3'])
        if mask & S:
            for y in range(T - 1 - wob, T): gl(i, y)
            px(t, i, T - 2 - wob, P['p3'])
        if mask & Wb:
            for x in range(0, 1 + wob): gl(x, i)
            px(t, 1 + wob, i, P['p3'])
        if mask & E:
            for x in range(T - 1 - wob, T): gl(x, i)
            px(t, T - 2 - wob, i, P['p3'])
    return t

def water(mask, frame):
    t = img(T, T); rect(t, 0, 0, T - 1, T - 1, P['w0'])
    # gentle diagonal ripples that drift with the frame
    for k in range(3):
        y = (k * 6 + frame * 2) % T
        x = (k * 5 + frame * 3) % T
        rect(t, x, y, min(T - 1, x + 3), y, P['w1'])
        px(t, (x + 8) % T, (y + 3) % T, P['w2'])
    if frame % 2 == 0:
        px(t, (frame * 4 + 2) % T, (frame * 3 + 11) % T, P['w3'])
    # banks: grass lip + darker water line + foam on sides that touch land
    for i in range(T):
        wob = 1 if (i * 3 + frame) % 7 == 0 else 0
        if mask & N:
            rect(t, i, 0, i, 1, P['g0']); px(t, i, 2, P['g3']); px(t, i, 3, P['wd']); px(t, i, 4 + wob, P['w3'])
        if mask & S:
            rect(t, i, T - 2, i, T - 1, P['g0']); px(t, i, T - 3, P['s1']); px(t, i, T - 4 - wob, P['w3'])
        if mask & Wb:
            rect(t, 0, i, 1, i, P['g0']); px(t, 2, i, P['g3']); px(t, 3, i, P['wd']); px(t, 4 + wob, i, P['w3'])
        if mask & E:
            rect(t, T - 2, i, T - 1, i, P['g0']); px(t, T - 3, i, P['g3']); px(t, T - 4, i, P['wd']); px(t, T - 5 - wob, i, P['w3'])
    return t

def tile_sheet():
    sheet = img(16 * T, 6 * T)
    row0 = [grass(0), grass(1), grass(2), grass(3), sand(0), sand(1), road('plain'), road('cross'), road('dash'), bridge(), dirt()]
    for i, t in enumerate(row0): sheet.paste(t, (i * T, 0))
    for m in range(16): sheet.paste(path(m), (m * T, T))
    for f in range(4):
        for m in range(16): sheet.paste(water(m, f), (m * T, (2 + f) * T))
    return sheet

# ---------------------------------------------------------------- props

def tree(kind):
    w, h = 32, 44; t = img(w, h)
    # trunk
    outline_rect(t, 13, 30, 18, 42, P['k1']); rect(t, 14, 31, 15, 41, P['k0']); px(t, 16, 36, P['k2'])
    rect(t, 11, 41, 20, 42, P['k2']); outline_rect(t, 11, 40, 20, 43, P['k1'])
    c0, c1, c2, c3 = (P['leaf3'], P['leaf0'], P['leaf1'], P['leaf2']) if kind == 0 else (P['blos0'], P['blos0'], P['blos1'], P['blos2'])
    blobs = [(16, 14, 13), (8, 20, 8), (24, 20, 8), (16, 24, 10), (11, 9, 7), (21, 9, 7)]
    for (cx, cy, r) in blobs: ellipse(t, [cx - r - 1, cy - r - 1, cx + r + 1, cy + r + 1], INK)
    for (cx, cy, r) in blobs: ellipse(t, [cx - r, cy - r, cx + r, cy + r], c2)
    for (cx, cy, r) in blobs: ellipse(t, [cx - r + 1, cy - r, cx + r - 3, cy + r - 3], c1)
    for (cx, cy, r) in blobs[:1] + blobs[4:]: ellipse(t, [cx - r + 3, cy - r + 1, cx + 1, cy - 2], c0)
    # under-shadow band
    for x in range(4, 29):
        for y in range(27, 33):
            if t.getpixel((x, y)) in (c1, c0): t.putpixel((x, y), c2)
    if kind == 1:
        for (x, y) in [(9, 12), (20, 6), (23, 17), (13, 22), (6, 21)]: px(t, x, y, P['white'])
    else:
        for (x, y) in [(10, 10), (19, 7), (22, 18)]: px(t, x, y, P['red']); px(t, x + 1, y, P['red2'])
    return t

def bush():
    t = img(16, 14)
    for (cx, cy, r) in [(5, 8, 5), (11, 8, 5), (8, 6, 5)]: ellipse(t, [cx - r - 1, cy - r - 1, cx + r + 1, cy + r + 1], INK)
    for (cx, cy, r) in [(5, 8, 5), (11, 8, 5), (8, 6, 5)]: ellipse(t, [cx - r, cy - r, cx + r, cy + r], P['leaf1'])
    for (cx, cy, r) in [(5, 7, 3), (10, 5, 3)]: ellipse(t, [cx - r, cy - r, cx + r, cy + r], P['leaf0'])
    px(t, 6, 5, P['leaf3']); px(t, 10, 3, P['leaf3']); px(t, 12, 9, P['pink'])
    return t

def flowers(v):
    t = img(16, 16); r = rng(200 + v)
    cols = [('white', 'gold'), ('pink', 'white'), ('gold', 'orng'), ('purp', 'white')]
    for k in range(4):
        x, y = 2 + r.randrange(11), 3 + r.randrange(10)
        a, b = cols[(k + v) % 4]
        px(t, x, y + 1, P['leaf2']); px(t, x, y + 2, P['leaf2'])
        for (dx, dy) in ((1, 0), (-1, 0), (0, 1), (0, -1)): px(t, x + dx, y + dy, P[a])
        px(t, x, y, P[b])
    return t

def fence(vertical):
    t = img(16, 16)
    if not vertical:
        for x in (1, 13):
            outline_rect(t, x, 3, x + 3, 14, P['k0']); px(t, x + 1, 4, P['c0'])
        outline_rect(t, 0, 6, 15, 8, P['k0']); outline_rect(t, 0, 10, 15, 12, P['k1'])
    else:
        outline_rect(t, 6, 0, 9, 14, P['k0']); px(t, 7, 1, P['c0'])
        outline_rect(t, 5, 3, 10, 5, P['k1']); outline_rect(t, 5, 9, 10, 11, P['k1'])
    return t

def bench():
    t = img(16, 14)
    outline_rect(t, 1, 2, 14, 6, P['k0']); rect(t, 2, 3, 13, 3, P['c1'])
    outline_rect(t, 0, 7, 15, 9, P['k1'])
    outline_rect(t, 2, 9, 4, 13, P['st2']); outline_rect(t, 11, 9, 13, 13, P['st2'])
    return t

def lamp(lit):
    t = img(12, 32)
    outline_rect(t, 4, 9, 7, 30, P['st2']); px(t, 5, 10, P['st0'])
    outline_rect(t, 2, 28, 9, 31, P['st1'])
    outline_rect(t, 1, 1, 10, 9, P['glow'] if lit else P['win'])
    rect(t, 2, 0, 9, 1, INK); rect(t, 3, 0, 8, 0, P['st1'])
    rect(t, 3, 3, 4, 6, P['white'] if lit else P['win2'])
    return t

def fountain(frame):
    w, h = 64, 64; t = img(w, h)
    # basin (4x4 tiles footprint drawn from the bottom)
    ellipse(t, [1, 26, 62, 62], INK); ellipse(t, [2, 27, 61, 61], P['st1']); ellipse(t, [2, 27, 61, 56], P['st0'])
    ellipse(t, [7, 31, 56, 54], INK); ellipse(t, [8, 32, 55, 53], P['w0'])
    for k in range(4):
        x = 14 + ((k * 11 + frame * 4) % 34); y = 38 + (k * 5) % 12
        rect(t, x, y, x + 3, y, P['w2'])
    # center column + bowl
    outline_rect(t, 28, 24, 35, 46, P['st0']); rect(t, 29, 25, 30, 45, P['white'])
    ellipse(t, [19, 18, 44, 30], INK); ellipse(t, [20, 19, 43, 29], P['st0']); ellipse(t, [22, 20, 41, 26], P['w1'])
    # water spray (animated)
    sp = [(31, 4 + frame), (32, 3 + frame % 2)]
    for i in range(14):
        y = 6 + i + (frame % 2)
        px(t, 31, y, P['w3']); px(t, 32, y, P['w2'])
    for side in (-1, 1):
        for i in range(9):
            x = 32 + side * (2 + i); y = 8 + int(i * i * 0.18) + (frame % 2)
            px(t, x, y, P['w3']); px(t, x, y + 1, P['w1'])
    for i in range(3):
        px(t, 18 + i * 12 + frame, 35 + (i % 2), P['w3'])
    return t

def car(color, color2):
    t = img(30, 18)
    outline_rect(t, 1, 6, 28, 14, P[color]); rect(t, 2, 7, 27, 8, P['white'] if False else P[color])
    outline_rect(t, 7, 1, 21, 7, P[color]); rect(t, 9, 3, 13, 6, P['win']); rect(t, 15, 3, 19, 6, P['win']); px(t, 9, 3, P['white'])
    rect(t, 2, 11, 27, 12, P[color2]); px(t, 27, 8, P['gold']); px(t, 2, 8, P['red'])
    for x in (6, 22):
        ellipse(t, [x - 3, 11, x + 3, 17], INK); ellipse(t, [x - 2, 12, x + 2, 16], P['st2']); px(t, x, 14, P['st0'])
    return t

def sign():
    t = img(14, 28)
    outline_rect(t, 6, 10, 8, 27, P['st2'])
    # round "school" sign: yellow diamond with two little walkers
    pts = [(7, 0), (13, 6), (7, 12), (1, 6)]
    ImageDraw.Draw(t).polygon(pts, fill=P['gold'], outline=INK)
    px(t, 5, 4, INK); px(t, 5, 5, INK); px(t, 4, 6, INK); px(t, 6, 6, INK); px(t, 5, 7, INK); px(t, 4, 8, INK); px(t, 6, 8, INK)
    px(t, 9, 5, INK); px(t, 9, 6, INK); px(t, 9, 7, INK); px(t, 8, 8, INK); px(t, 10, 8, INK)
    return t

def crane():
    t = img(44, 66)
    outline_rect(t, 6, 6, 11, 63, P['gold']);
    for y in range(8, 62, 6):
        for i in range(5): px(t, 7 + i, y + i, P['gold2'])
    outline_rect(t, 0, 2, 43, 7, P['gold']);
    for x in range(2, 42, 5): px(t, x, 4, P['gold2']); px(t, x + 1, 5, P['gold2'])
    outline_rect(t, 3, 9, 13, 16, P['orng']); rect(t, 5, 10, 8, 13, P['win'])
    outline_rect(t, 0, 0, 5, 8, P['st1'])
    rect(t, 37, 8, 37, 34, INK)
    outline_rect(t, 34, 34, 40, 40, P['red']); rect(t, 35, 35, 39, 36, P['pink'])
    outline_rect(t, 3, 60, 14, 65, P['st1'])
    return t

def blocks():
    t = img(16, 16)
    outline_rect(t, 0, 8, 7, 15, P['red']); px(t, 2, 10, P['pink'])
    outline_rect(t, 7, 8, 15, 15, P['blue']); px(t, 9, 10, P['win'])
    outline_rect(t, 3, 1, 11, 8, P['gold']); px(t, 5, 3, P['white'])
    return t

def rock():
    t = img(16, 12)
    ellipse(t, [1, 1, 14, 11], INK); ellipse(t, [2, 2, 13, 10], P['st1']); ellipse(t, [3, 2, 10, 7], P['st0']); px(t, 5, 3, P['white'])
    return t

def mushroom():
    t = img(12, 12)
    outline_rect(t, 4, 6, 7, 11, P['c0'])
    ellipse(t, [0, 0, 11, 8], INK); ellipse(t, [1, 1, 10, 7], P['red']); px(t, 3, 3, P['white']); px(t, 7, 2, P['white']); px(t, 8, 5, P['white'])
    return t

def lily(frame):
    t = img(16, 12)
    ellipse(t, [1, 1 + frame, 14, 10 + frame], P['leaf2']); ellipse(t, [2, 1 + frame, 13, 9 + frame], P['leaf0'])
    ImageDraw.Draw(t).polygon([(8, 5 + frame), (13, 3 + frame), (13, 7 + frame)], fill=P['w0'])
    px(t, 5, 3 + frame, P['leaf3']); px(t, 6, 3 + frame, P['pink']); px(t, 5, 4 + frame, P['pink'])
    return t

def portal(frame, asleep=False):
    w, h = 32, 40; t = img(w, h)
    # stone arch
    outline_rect(t, 2, 12, 7, 39, P['st1']); outline_rect(t, 24, 12, 29, 39, P['st1'])
    ellipse(t, [2, 0, 29, 26], INK); ellipse(t, [3, 1, 28, 25], P['st1']); ellipse(t, [8, 6, 23, 31], INK)
    rect(t, 3, 3, 4, 38, P['st0']); rect(t, 25, 14, 25, 38, P['st0'])
    # swirl inside
    inner = img(w, h)
    if asleep:
        ellipse(inner, [9, 7, 22, 30], hexc('7A8094'))
        ellipse(inner, [12, 11, 19, 25], hexc('9AA0B4'))
    else:
        cols = [P['purp'], P['blue'], P['teal'], P['pink']]
        ellipse(inner, [9, 7, 22, 30], cols[frame % 4])
        ellipse(inner, [11, 10, 20, 27], cols[(frame + 1) % 4])
        ellipse(inner, [13, 13, 18, 24], cols[(frame + 2) % 4])
        for k in range(4):
            a = (frame * 0.8 + k * math.pi / 2)
            x = 15 + int(math.cos(a) * 4); y = 18 + int(math.sin(a) * 7)
            px(inner, x, y, P['white'])
    # mask inner to the arch hole
    for y in range(h):
        for x in range(w):
            if inner.getpixel((x, y))[3] and t.getpixel((x, y)) == INK and 9 <= x <= 22 and 7 <= y <= 30:
                pass
    rect(t, 9, 31, 22, 39, CLEAR)
    t.alpha_composite(inner)
    # gem keystone
    outline_rect(t, 13, 0, 18, 5, P['gold'] if not asleep else P['st2']); px(t, 14, 1, P['white'])
    return t

def butterfly(color, frame):
    t = img(8, 7)
    if frame == 0:
        rect(t, 0, 0, 2, 3, P[color]); rect(t, 5, 0, 7, 3, P[color]); rect(t, 1, 4, 2, 5, P[color + '2'] if color + '2' in P else P[color]); rect(t, 5, 4, 6, 5, P[color])
    else:
        rect(t, 1, 1, 2, 4, P[color]); rect(t, 5, 1, 6, 4, P[color])
    rect(t, 3, 1, 4, 5, INK)
    return t

def leaf(frame):
    t = img(5, 5)
    pts = [[(0, 2), (2, 0), (4, 2), (2, 4)], [(0, 0), (4, 1), (4, 4), (1, 3)]][frame]
    ImageDraw.Draw(t).polygon(pts, fill=P['orng'] if frame else P['leaf3'])
    return t

def firefly():
    t = img(5, 5); ellipse(t, [0, 0, 4, 4], hexc('FFF7B0', 120)); px(t, 2, 2, hexc('FFFDE0')); return t

def dust(frame):
    t = img(10, 6); r = [2, 3, 2][frame]
    c = hexc('FFFFFF', [220, 160, 90][frame])
    ellipse(t, [0 + frame, 2 - min(frame, 1), 2 * r + frame, 2 + 2 * r - min(frame, 1)], c)
    ellipse(t, [9 - 2 * r - frame, 2, 9 - frame, 2 + 2 * r], c)
    return t

def sparkle():
    t = img(5, 5)
    for (x, y) in [(2, 0), (2, 1), (0, 2), (1, 2), (3, 2), (4, 2), (2, 3), (2, 4)]: px(t, x, y, P['gold'])
    px(t, 2, 2, P['white']); return t

def shadow():
    t = img(16, 6); ellipse(t, [0, 0, 15, 5], (30, 40, 30, 70)); return t

def cloud_shadow():
    t = img(64, 32)
    for (cx, cy, rx, ry) in [(20, 16, 18, 10), (40, 14, 20, 12), (30, 20, 22, 9)]:
        ellipse(t, [cx - rx, cy - ry, cx + rx, cy + ry], (20, 50, 30, 38))
    return t

def interact_marker(frame):
    t = img(9, 11)
    pts = [(0, 0), (8, 0), (4, 6)]
    ImageDraw.Draw(t).polygon([(p[0], p[1] + frame) for p in pts], fill=P['gold'], outline=INK)
    return t

# ---------------------------------------------------------------- buildings

def shingles(im, x0, y0, x1, y1, c, c2, step=3):
    rect(im, x0, y0, x1, y1, c)
    for y in range(y0 + step - 1, y1 + 1, step):
        rect(im, x0, y, x1, y, c2)
        off = (y // step) % 2 * 2
        for x in range(x0 + off, x1 + 1, 4): px(im, x, y - 1, c2)

def gable(im, cx, top, base_y, half, c, c2, overhang=2):
    """Triangle roof from (cx, top) down to base_y, half-width at the base."""
    d = ImageDraw.Draw(im)
    d.polygon([(cx, top - 1), (cx + half + overhang + 1, base_y + 1), (cx - half - overhang - 1, base_y + 1)], fill=INK)
    d.polygon([(cx, top), (cx + half + overhang, base_y), (cx - half - overhang, base_y)], fill=c)
    for y in range(top + 3, base_y, 3):
        span = int((y - top) / (base_y - top) * (half + overhang))
        d.line([(cx - span + 1, y), (cx + span - 1, y)], fill=c2)
    d.line([(cx - half - overhang, base_y), (cx + half + overhang, base_y)], fill=c2)
    d.line([(cx, top), (cx - half - overhang + 1, base_y - 1)], fill=lighten(c))

def lighten(c, k=40):
    return (min(255, c[0] + k), min(255, c[1] + k), min(255, c[2] + k), c[3])

def darken(c, k=40):
    return (max(0, c[0] - k), max(0, c[1] - k), max(0, c[2] - k), c[3])

def bricks(im, x0, y0, x1, y1, c, c2):
    rect(im, x0, y0, x1, y1, c)
    for y in range(y0 + 3, y1, 4):
        rect(im, x0, y, x1, y, c2)
        off = 0 if (y // 4) % 2 else 3
        for x in range(x0 + off, x1, 6):
            rect(im, x, y - 3, x, y - 1, c2)
    rect(im, x0, y0, x0, y1, lighten(c, 25))

def window(im, x, y, w=6, h=7, lit=False, arched=False):
    outline_rect(im, x, y, x + w - 1, y + h - 1, P['glow'] if lit else P['win'])
    rect(im, x + 1, y + 1, x + 2, y + 2, P['white'])
    rect(im, x + w // 2, y + 1, x + w // 2, y + h - 2, INK if w > 5 else P['win2'])
    rect(im, x + 1, y + h // 2, x + w - 2, y + h // 2, INK if h > 6 else P['win2'])
    rect(im, x - 1, y + h, x + w, y + h, P['c2'])
    if arched:
        px(im, x, y, CLEAR); px(im, x + w - 1, y, CLEAR)

def door(im, cx, base, w=10, h=14, c=None):
    c = c or P['k1']
    x0 = cx - w // 2; x1 = x0 + w - 1; y0 = base - h + 1
    outline_rect(im, x0, y0 + 2, x1, base, c)
    ImageDraw.Draw(im).ellipse([x0, y0, x1, y0 + 6], fill=INK)
    ImageDraw.Draw(im).ellipse([x0 + 1, y0 + 1, x1 - 1, y0 + 6], fill=c)
    for x in range(x0 + 3, x1 - 1, 3): rect(im, x, y0 + 4, x, base - 1, darken(c, 30))
    px(im, x1 - 2, base - 6, P['gold'])
    rect(im, x0 - 1, base + 1, x1 + 1, base + 1, P['st1'])

def flag(im, x, y, c, right=True):
    rect(im, x, y, x, y + 8, INK)
    d = ImageDraw.Draw(im)
    if right: d.polygon([(x + 1, y), (x + 6, y + 2), (x + 1, y + 4)], fill=c, outline=INK)
    else: d.polygon([(x - 1, y), (x - 6, y + 2), (x - 1, y + 4)], fill=c, outline=INK)

def tower(im, x0, x1, top, base, wall, wall2, roof, roof2):
    bricks(im, x0 + 1, top + 1, x1 - 1, base - 1, wall, wall2)
    rect(im, x0, top, x0, base, INK); rect(im, x1, top, x1, base, INK)
    cx = (x0 + x1) // 2; half = (x1 - x0) // 2
    gable(im, cx, top - 16, top, half, roof, roof2, overhang=2)
    flag(im, cx, top - 25, P['pink'])
    window(im, cx - 2, top + 6, 5, 7, arched=True)

def building_castle(theme):
    walls = {'sparkle': ('FFD6EC', 'F1B7D6'), 'fortress': ('B8C4D6', '93A1B8'), 'rainbow': ('FFF4C2', 'EAD991')}[theme]
    roofs = {'sparkle': ('C77DFF', '9B55D8'), 'fortress': ('3B5BA5', '29437E'), 'rainbow': ('3CC9A0', '27997A')}[theme]
    accent = {'sparkle': 'FF7FC4', 'fortress': 'F2B134', 'rainbow': 'FF7A59'}[theme]
    W, H = 128, 156; im = img(W, H)
    wall, wall2 = hexc(walls[0]), hexc(walls[1]); roof, roof2 = hexc(roofs[0]), hexc(roofs[1])
    base = H - 2
    # back keep
    bricks(im, 30, 46, 97, base - 20, darken(wall, 12), darken(wall2, 12)); rect(im, 29, 45, 98, 45, INK)
    for x in range(30, 98, 8): outline_rect(im, x, 39, x + 4, 45, darken(wall, 12))
    gable(im, 64, 8, 39, 26, roof, roof2, overhang=4)
    flag(im, 64, 0, hexc(accent))
    window(im, 60, 22, 8, 10, lit=True, arched=True)
    # front wall
    bricks(im, 18, 82, 109, base, wall, wall2); rect(im, 17, 81, 110, 81, INK); rect(im, 17, 81, 17, base, INK); rect(im, 110, 81, 110, base, INK); rect(im, 17, base + 1, 110, base + 1, INK)
    for x in range(18, 108, 7): outline_rect(im, x, 75, x + 4, 81, wall)
    # towers
    tower(im, 2, 24, 62, base, wall, wall2, roof, roof2)
    tower(im, 103, 125, 62, base, wall, wall2, roof, roof2)
    rect(im, 2, base + 1, 125, base + 1, INK)
    # gate and banners
    door(im, 64, base, w=20, h=28, c=P['k1'])
    for x in (40, 84):
        outline_rect(im, x - 4, 92, x + 4, 112, hexc(accent)); rect(im, x - 3, 93, x - 2, 110, lighten(hexc(accent)))
        ImageDraw.Draw(im).polygon([(x - 4, 112), (x, 117), (x + 4, 112)], fill=hexc(accent), outline=INK)
        px(im, x, 100, P['gold']); px(im, x - 1, 101, P['gold']); px(im, x + 1, 101, P['gold']); px(im, x, 102, P['gold'])
    window(im, 28, 92, 6, 8); window(im, 94, 92, 6, 8)
    # bushes at the base
    for x in (26, 98):
        b = bush(); im.alpha_composite(b, (x - 8, base - 12))
    return im

def building_museum():
    W, H = 96, 118; im = img(W, H); base = H - 2
    wall, wall2 = P['c0'], P['c1']
    # pediment roof with a star medallion
    ImageDraw.Draw(im).polygon([(48, 8), (94, 40), (2, 40)], fill=INK)
    ImageDraw.Draw(im).polygon([(48, 10), (90, 38), (6, 38)], fill=P['purp'])
    ImageDraw.Draw(im).polygon([(48, 16), (78, 36), (18, 36)], fill=P['c0'])
    ellipse(im, [41, 21, 55, 35], INK); ellipse(im, [42, 22, 54, 34], P['gold'])
    for (x, y) in [(48, 24), (48, 25), (46, 27), (47, 27), (48, 27), (49, 27), (50, 27), (47, 29), (49, 29), (46, 31), (50, 31), (48, 28)]: px(im, x, y, P['white'])
    outline_rect(im, 2, 40, 93, 46, P['c1']); rect(im, 3, 41, 92, 41, P['white'])
    # columns
    outline_rect(im, 6, 46, 89, base, wall2)
    for x in (10, 26, 62, 78):
        outline_rect(im, x, 47, x + 8, base - 4, P['white']); rect(im, x + 2, 48, x + 2, base - 5, P['c1']); rect(im, x + 6, 48, x + 6, base - 5, P['c2'])
        outline_rect(im, x - 1, 46, x + 9, 50, P['c0']); outline_rect(im, x - 1, base - 5, x + 9, base - 1, P['c0'])
    # sticker posters between columns
    outline_rect(im, 20, 60, 25, 72, P['pink']); outline_rect(im, 72, 60, 77, 72, P['teal'])
    door(im, 48, base - 1, w=16, h=26, c=P['purp2'])
    outline_rect(im, 0, base - 1, 95, base + 1, P['st1'])
    rect(im, 1, base, 94, base, P['st0'])
    return im

def building_arena():
    W, H = 96, 112; im = img(W, H); base = H - 2
    # striped big-top tent dome with pillow flags, on a cloud ring
    d = ImageDraw.Draw(im)
    d.ellipse([4, 22, 91, 92], fill=INK)
    d.ellipse([5, 23, 90, 91], fill=P['purp'])
    for k in range(-4, 5):
        x = 48 + k * 10
        d.polygon([(48, 24), (x - 3, 70), (x + 3, 70)], fill=P['white'] if k % 2 == 0 else P['purp'])
    d.ellipse([18, 26, 40, 40], fill=lighten(P['purp'], 50))
    outline_rect(im, 8, 62, 87, base - 6, P['blos0']); bricks(im, 9, 63, 86, base - 7, P['blos0'], P['blos1'])
    flag(im, 48, 6, P['gold']); rect(im, 47, 14, 49, 24, INK)
    for x in (16, 80):
        outline_rect(im, x - 5, 52, x + 5, 60, P['white']); px(im, x - 3, 54, P['win'])
    door(im, 48, base - 6, w=18, h=22, c=P['pink2'])
    # fluffy cloud base
    for (cx, r) in [(10, 9), (26, 10), (44, 9), (62, 10), (80, 9), (90, 7)]:
        d.ellipse([cx - r - 1, base - 12, cx + r + 1, base + 1], fill=INK)
    for (cx, r) in [(10, 9), (26, 10), (44, 9), (62, 10), (80, 9), (90, 7)]:
        d.ellipse([cx - r, base - 11, cx + r, base], fill=P['white'])
    rect(im, 39, base - 10, 57, base, CLEAR)
    door(im, 48, base, w=18, h=16, c=P['pink2'])
    return im

def gear(im, cx, cy, r, c):
    for k in range(8):
        a = k * math.pi / 4
        x, y = cx + int(math.cos(a) * (r + 1)), cy + int(math.sin(a) * (r + 1))
        rect(im, x - 1, y - 1, x + 1, y + 1, INK); px(im, x, y, c)
    ellipse(im, [cx - r, cy - r, cx + r, cy + r], INK); ellipse(im, [cx - r + 1, cy - r + 1, cx + r - 1, cy + r - 1], c)
    ellipse(im, [cx - 2, cy - 2, cx + 2, cy + 2], INK)

def building_workshop():
    W, H = 112, 114; im = img(W, H); base = H - 2
    # saw-tooth factory roof, chimney with steam, big gear sign
    outline_rect(im, 80, 6, 90, 40, P['red2']); rect(im, 81, 7, 82, 39, P['red'])
    for (x, y) in [(84, 2), (88, 0)]: ellipse(im, [x - 3, y, x + 3, y + 5], P['white'])
    for k in range(4):
        x0 = 4 + k * 26
        ImageDraw.Draw(im).polygon([(x0, 50), (x0 + 26, 30), (x0 + 26, 50)], fill=INK)
        ImageDraw.Draw(im).polygon([(x0 + 2, 49), (x0 + 25, 32), (x0 + 25, 49)], fill=P['blue'])
        rect(im, x0 + 20, 36, x0 + 24, 48, P['win'])
    outline_rect(im, 2, 49, 109, 53, P['blue2'])
    bricks(im, 5, 54, 106, base, P['st0'], P['st1']); rect(im, 4, 53, 4, base, INK); rect(im, 107, 53, 107, base, INK)
    gear(im, 30, 70, 8, P['gold']); gear(im, 82, 72, 6, P['orng'])
    window(im, 14, 84, 8, 8, lit=True); window(im, 90, 84, 8, 8, lit=True)
    # roller door
    outline_rect(im, 42, 74, 69, base, P['st1'])
    for y in range(76, base, 3): rect(im, 43, y, 68, y, P['st2'])
    rect(im, 0, base + 1, 111, base + 1, INK)
    return im

def building_academy():
    W, H = 112, 110; im = img(W, H); base = H - 2
    gable(im, 56, 14, 44, 52, P['red'], P['red2'], overhang=2)
    bricks(im, 6, 45, 105, base, P['c0'], P['c1']); rect(im, 5, 44, 5, base, INK); rect(im, 106, 44, 106, base, INK)
    # traffic light on the roof
    outline_rect(im, 51, 0, 61, 26, P['st2'])
    for i, c in enumerate(['red', 'gold', 'leaf0']):
        ellipse(im, [53, 2 + i * 8, 59, 8 + i * 8], P[c])
    # steering wheel sign
    ellipse(im, [44, 50, 68, 74], INK); ellipse(im, [45, 51, 67, 73], P['white'])
    ellipse(im, [47, 53, 65, 71], INK); ellipse(im, [49, 55, 63, 69], P['white'])
    rect(im, 49, 61, 63, 63, INK); rect(im, 55, 62, 57, 70, INK); ellipse(im, [53, 59, 59, 65], P['blue'])
    window(im, 14, 56, 10, 10); window(im, 88, 56, 10, 10); window(im, 14, 80, 10, 10); window(im, 88, 80, 10, 10)
    door(im, 56, base, w=16, h=22, c=P['blue2'])
    rect(im, 0, base + 1, 111, base + 1, INK)
    return im

def building_stadium():
    W, H = 144, 118; im = img(W, H); base = H - 2
    d = ImageDraw.Draw(im)
    # oval stands
    d.ellipse([2, 18, 141, 96], fill=INK); d.ellipse([3, 19, 140, 95], fill=P['orng'])
    d.ellipse([12, 26, 131, 88], fill=P['orng2'])
    for k in range(6):
        d.arc([12 + k * 3, 26 + k * 2, 131 - k * 3, 88 - k * 2], 180, 360, fill=P['gold'] if k % 2 else P['orng'])
    d.ellipse([28, 38, 115, 80], fill=INK); d.ellipse([29, 39, 114, 79], fill=P['leaf0'])
    d.ellipse([40, 46, 103, 72], fill=P['r0']); d.ellipse([52, 52, 91, 66], fill=P['leaf0'])
    # crowd dots
    r = rng(5)
    for _ in range(70):
        a = r.random() * math.pi; rr = 54 + r.random() * 10
        x = 72 + int(math.cos(a) * rr * 1.1); y = 57 - int(math.sin(a) * rr * 0.55)
        px(im, x, y, P[r.choice(['red', 'blue', 'white', 'pink', 'teal', 'purp'])])
    # front wall with checkered banner and gate
    bricks(im, 8, 70, 135, base, P['st0'], P['st1']); rect(im, 7, 69, 136, 69, INK); rect(im, 7, 69, 7, base, INK); rect(im, 136, 69, 136, base, INK)
    for i in range(16):
        for j in range(2):
            rect(im, 40 + i * 4, 74 + j * 4, 43 + i * 4, 77 + j * 4, INK if (i + j) % 2 else P['white'])
    outline_rect(im, 39, 73, 104, 82, CLEAR);
    for x in (12, 132):
        flag(im, x, 8, P['red'] if x < 50 else P['blue'], right=x < 50); rect(im, x, 16, x, 70, INK)
    door(im, 72, base, w=22, h=22, c=P['r1'])
    window(im, 20, 88, 8, 8); window(im, 116, 88, 8, 8)
    rect(im, 0, base + 1, 143, base + 1, INK)
    return im

def building_shed():
    W, H = 80, 76; im = img(W, H); base = H - 2
    # site office: corrugated roof, hard-hat sign, striped barrier
    outline_rect(im, 0, 18, 79, 26, P['orng']);
    for x in range(2, 78, 4): rect(im, x, 19, x, 25, P['orng2'])
    bricks(im, 4, 27, 75, base, P['k0'], P['k1']); rect(im, 3, 27, 3, base, INK); rect(im, 76, 27, 76, base, INK)
    # hard hat sign
    ellipse(im, [30, 0, 50, 16], INK); ellipse(im, [31, 1, 49, 15], P['gold']); rect(im, 28, 13, 52, 17, INK); rect(im, 29, 14, 51, 16, P['gold2'])
    window(im, 10, 36, 10, 9); window(im, 60, 36, 10, 9)
    door(im, 40, base, w=14, h=22, c=P['st2'])
    for i in range(10):
        rect(im, 4 + i * 7, base - 4, 7 + i * 7, base - 2, INK if i % 2 else P['gold'])
    rect(im, 0, base + 1, 79, base + 1, INK)
    return im

# ---------------------------------------------------------------- buddies

CELL_W, CELL_H, BASE = 32, 36, 33    # feet rest on y = BASE (from the top) in each cell
ANIM_ROWS = [('idle', 2), ('walkS', 4), ('walkN', 4), ('walkE', 4), ('hop', 3), ('celebrate', 4), ('talk', 2), ('interact', 2)]

def pixelize(src, h, wscale=1.0):
    bb = src.getbbox(); im = src.crop(bb)
    w = max(4, round(im.width * h / im.height * wscale))
    if w > CELL_W - 4:
        w = CELL_W - 4; h = round(h * w / max(1, round(im.width * h / im.height * wscale)))
    sm = im.resize((w, h), Image.LANCZOS)
    a = sm.split()[3].point(lambda v: 255 if v > 110 else 0)
    rgb = sm.convert('RGB').quantize(14, method=Image.MEDIANCUT).convert('RGB')
    out = rgb.convert('RGBA'); out.putalpha(a)
    return out

def with_outline(sprite):
    w, h = sprite.size
    big = img(w + 2, h + 2); big.paste(sprite, (1, 1), sprite)
    return add_outline(big)

def place(cell, sprite, dx=0, dy=0):
    x = (CELL_W - sprite.width) // 2 + dx
    y = BASE - sprite.height + 1 + dy
    cell.alpha_composite(sprite, (max(0, x), max(0, y)))

def legs_shift(sprite, side, lift=1):
    """Lift the bottom rows on one side (0 = left, 1 = right) by `lift` px: a real step frame."""
    s = sprite.copy(); w, h = s.size; src = sprite.load(); o = s.load()
    rows = 4; cx = w // 2
    xs = range(0, cx) if side == 0 else range(cx, w)
    for y in range(h - rows, h):
        for x in xs: o[x, y] = CLEAR
    for y in range(h - rows, h):
        for x in xs:
            if src[x, y][3]: o[x, y - lift] = src[x, y]
    return s

def back_view(sprite):
    """Rear view: keep the silhouette and outline, repaint the inside in the body's main color (no face)."""
    s = sprite.copy(); px_ = s.load(); w, h = s.size
    counts = {}
    for y in range(h // 4, h * 3 // 4):
        for x in range(w):
            c = px_[x, y]
            lum = (c[0] * 3 + c[1] * 6 + c[2]) / 10
            if c[3] and lum > 110 and not (c[0] > 235 and c[1] > 235 and c[2] > 235):
                counts[c[:3]] = counts.get(c[:3], 0) + 1
    body = max(counts, key=counts.get) if counts else (200, 200, 200)
    body = body + (255,)
    for y in range(h):
        for x in range(w):
            c = px_[x, y]
            if not c[3]: continue
            lum = (c[0] * 3 + c[1] * 6 + c[2]) / 10
            if lum < 70: continue                      # keep outline / dark details (ears, feet)
            shade = darken(body, 35) if y > h * 0.62 else (lighten(body, 18) if lum > 200 and y < h * 0.3 else body)
            px_[x, y] = shade
    # a little tail/back highlight stripe so it reads as "back"
    for y in range(h // 3, h // 3 + 3):
        px_[w // 2, y] = lighten(body, 30) if px_[w // 2, y][3] else px_[w // 2, y]
    return s

def squash(sprite, sx, sy):
    w, h = sprite.size
    return sprite.resize((max(2, round(w * sx)), max(2, round(h * sy))), Image.NEAREST)

def lean(sprite, dx):
    s = img(sprite.width + 3, sprite.height); src = sprite.load()
    for y in range(sprite.height):
        off = 1 + (dx if y < sprite.height // 2 else 0)
        for x in range(sprite.width):
            if src[x, y][3]: s.putpixel((x + off, y), src[x, y])
    return s

def buddy_sheet(char_png):
    src = Image.open(char_png).convert('RGBA')
    front = with_outline(pixelize(src, 28))
    side = with_outline(pixelize(src, 28, wscale=0.78))
    back = with_outline(back_view(pixelize(src, 28)))
    sheet = img(CELL_W * 4, CELL_H * len(ANIM_ROWS))
    def cell(row, col, sprite, dx=0, dy=0, sparkles=()):
        c = img(CELL_W, CELL_H); place(c, sprite, dx, dy)
        for (x, y) in sparkles:
            sp = sparkle(); c.alpha_composite(sp, (x, y))
        sheet.alpha_composite(c, (col * CELL_W, row * CELL_H))
    # idle: breathe (1px squash)
    cell(0, 0, front); cell(0, 1, squash(front, 1.04, 0.965))
    # walk cycles: step left, up, step right, up
    for row, base in ((1, front), (2, back), (3, side)):
        cell(row, 0, legs_shift(base, 0)); cell(row, 1, base, dy=-1)
        cell(row, 2, legs_shift(base, 1)); cell(row, 3, base, dy=-1)
    # hop: crouch, air, land
    cell(4, 0, squash(front, 1.10, 0.86)); cell(4, 1, squash(front, 0.93, 1.06), dy=-2); cell(4, 2, squash(front, 1.14, 0.84))
    # celebrate: jump with sparkles
    cell(5, 0, front, dy=-1, sparkles=[(2, 4), (25, 8)]); cell(5, 1, squash(front, 0.95, 1.04), dy=-2, sparkles=[(5, 1), (23, 3)])
    cell(5, 2, front, dy=-1, sparkles=[(1, 10), (26, 2)]); cell(5, 3, squash(front, 1.08, 0.92), sparkles=[(4, 6), (24, 10)])
    # talk: little nod
    cell(6, 0, front); cell(6, 1, squash(front, 1.0, 0.965), dy=0)
    # interact: lean in
    cell(7, 0, lean(side, 1)); cell(7, 1, lean(side, 2), dx=1)
    return sheet

# ---------------------------------------------------------------- packing + Swift output

def pack(items, width=256):
    """Simple shelf packer. items: list of (name, Image). Returns sheet, {name: (x, y, w, h)}"""
    items = sorted(items, key=lambda it: -it[1].height)
    x = y = shelf = 0; rects = {}
    for name, im in items:
        if x + im.width > width:
            x = 0; y += shelf + 1; shelf = 0
        rects[name] = (x, y, im.width, im.height)
        x += im.width + 1; shelf = max(shelf, im.height)
    H = y + shelf
    H = 1 << (H - 1).bit_length()
    sheet = img(width, H)
    for name, im in items:
        r = rects[name]; sheet.paste(im, (r[0], r[1]))
    return sheet, rects

def save_imageset(assets, name, im):
    d = os.path.join(assets, f'{name}.imageset'); os.makedirs(d, exist_ok=True)
    im.save(os.path.join(d, f'{name}.png'))
    json.dump({"images": [{"filename": f"{name}.png", "idiom": "universal"}],
               "info": {"author": "xcode", "version": 1},
               "properties": {"preserves-vector-representation": False}}, open(os.path.join(d, 'Contents.json'), 'w'), indent=2)

def main():
    assets = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'out_assets')
    pkg = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, 'out_pkg')
    os.makedirs(assets, exist_ok=True)
    save_imageset(assets, 'village_tiles', tile_sheet())

    props = [('tree0', tree(0)), ('tree1', tree(1)), ('bush', bush()), ('fence_h', fence(False)), ('fence_v', fence(True)),
             ('bench', bench()), ('lamp0', lamp(False)), ('lamp1', lamp(True)), ('car0', car('blue', 'blue2')), ('car1', car('red', 'red2')),
             ('sign', sign()), ('crane', crane()), ('blocks', blocks()), ('rock', rock()), ('mushroom', mushroom()),
             ('shadow', shadow()), ('cloud', cloud_shadow()), ('firefly', firefly()), ('sparkle', sparkle()), ('portal_sleep', portal(0, True))]
    props += [(f'flowers{v}', flowers(v)) for v in range(4)]
    props += [(f'fountain{f}', fountain(f)) for f in range(3)]
    props += [(f'lily{f}', lily(f)) for f in range(2)]
    props += [(f'portal{f}', portal(f)) for f in range(4)]
    props += [(f'fly_{c}{f}', butterfly(c, f)) for c in ('pink', 'gold', 'blue') for f in range(2)]
    props += [(f'leaf{f}', leaf(f)) for f in range(2)]
    props += [(f'dust{f}', dust(f)) for f in range(3)]
    props += [(f'marker{f}', interact_marker(f)) for f in range(2)]
    sheet, rects = pack(props, 256)
    save_imageset(assets, 'village_props', sheet)

    buildings = {'castle_sparkle': building_castle('sparkle'), 'castle_fortress': building_castle('fortress'),
                 'castle_rainbow': building_castle('rainbow'), 'museum': building_museum(), 'arena': building_arena(),
                 'workshop': building_workshop(), 'academy': building_academy(), 'stadium': building_stadium(), 'shed': building_shed()}
    for k, im in buildings.items(): save_imageset(assets, f'village_{k}', im)

    char_dir = assets
    for cid in [d[5:-9] for d in sorted(os.listdir(char_dir)) if d.startswith('char_') and d.endswith('.imageset')]:
        save_imageset(assets, f'px_{cid}', buddy_sheet(os.path.join(char_dir, f'char_{cid}.imageset', f'char_{cid}.png')))

    # Swift: atlas rectangles
    lines = ['// GENERATED by ArtSource/make_village.py. Do not edit by hand.', 'import CoreGraphics', '',
             '/// Pixel rectangles (top-left origin) of each sprite inside its sheet.', 'enum VillageAtlas {',
             f'    static let propsSheetSize = CGSize(width: {sheet.width}, height: {sheet.height})',
             '    static let props: [String: CGRect] = [']
    for k in sorted(rects):
        x, y, w, h = rects[k]; lines.append(f'        "{k}": CGRect(x: {x}, y: {y}, width: {w}, height: {h}),')
    lines += ['    ]', '',
              f'    static let tileSize: CGFloat = {T}',
              '    static let tilesSheetSize = CGSize(width: 256, height: 96)',
              '    /// Buildings: sprite size in art pixels (bottom-center sits on the footprint\'s bottom edge).',
              '    static let buildingSizes: [String: CGSize] = [']
    for k, im in sorted(buildings.items()):
        lines.append(f'        "village_{k}": CGSize(width: {im.width}, height: {im.height}),')
    lines += ['    ]', '',
              f'    static let buddyCell = CGSize(width: {CELL_W}, height: {CELL_H})',
              f'    /// Feet line, measured from the bottom of a buddy cell.',
              f'    static let buddyFeet: CGFloat = {CELL_H - 1 - BASE}',
              '    static let buddyRows: [(name: String, frames: Int)] = [' + ', '.join(f'("{n}", {c})' for n, c in ANIM_ROWS) + ']',
              '}', '']
    os.makedirs(os.path.join(pkg, 'Scenes'), exist_ok=True)
    open(os.path.join(pkg, 'Scenes', 'VillageAtlas.swift'), 'w').write('\n'.join(lines))

    # Swift: the map
    rows = make_map.rows
    m = ['// GENERATED by ArtSource/make_village.py from make_map.py. Do not edit by hand.', '',
         'enum VillageMapData {', '    /// 40 x 48 tiles. Row 0 is the north edge. Legend: see VillageMap.swift.', '    static let rows: [String] = [']
    m += [f'        "{r}",' for r in rows]
    m += ['    ]', '}', '']
    os.makedirs(os.path.join(pkg, 'Models'), exist_ok=True)
    open(os.path.join(pkg, 'Models', 'VillageMapData.swift'), 'w').write('\n'.join(m))
    print('ok', len(rects), 'props;', sheet.size)

if __name__ == '__main__':
    main()
