"""Renders Hop Village with the same rules as HopVillageScene (ground masks, props, depth sort).
python3 preview_village.py <assets dir> <out.png> [closeup.png] [buddy ids...]"""
import sys, os, re
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_map

T = 16
assets = sys.argv[1]
def load(name):
    return Image.open(os.path.join(assets, f'{name}.imageset', f'{name}.png')).convert('RGBA')

tiles = load('village_tiles'); props = load('village_props')

rects = {}
for m in re.finditer(r'"(\w+)": CGRect\(x: (\d+), y: (\d+), width: (\d+), height: (\d+)\)', open(os.environ.get('ATLAS', os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'Scenes', 'VillageAtlas.swift'))).read()):
    rects[m.group(1)] = tuple(int(m.group(i)) for i in range(2, 6))

def prop(name):
    x, y, w, h = rects[name]; return props.crop((x, y, x + w, y + h))
def tile(col, row):
    return tiles.crop((col * T, row * T, col * T + T, row * T + T))

rows = make_map.rows; H = len(rows); W = len(rows[0])
def ch(c, r):
    if 0 <= r < H and 0 <= c < W: return rows[r][c]
    return None

def h(c, r): return (c * 73856093 ^ r * 19349663) & 0xffff

PATHLIKE = set('=Qz#')
WATERLIKE = set('~o#')
BUILD = {'C': 'castle', 'M': 'museum', 'A': 'arena', 'W': 'workshop', 'D': 'academy', 'K': 'stadium', 'Y': 'shed'}

def mask(c, r, like):
    m = 0
    for bit, (dc, dr) in ((1, (0, -1)), (2, (1, 0)), (4, (0, 1)), (8, (-1, 0))):
        n = ch(c + dc, r + dr)
        if n is not None and n not in like: m |= bit
    return m

def ground(c, r):
    k = ch(c, r)
    if k in PATHLIKE - {'#'} or k == 'Q':
        return tile(mask(c, r, PATHLIKE | set('Q')), 1)
    if k in '~o': return tile(mask(c, r, WATERLIKE), 2)
    if k == '#': return tile(9, 0)
    if k == 's' or (k in 'bkY' and any(ch(c + dc, r + dr) == 's' for dc, dr in ((1, 0), (-1, 0), (0, 1), (0, -1)))):
        return tile(4 + (h(c, r) % 5 == 0), 0)
    if k in 'rc': return tile(6, 0)
    if k == 'z': return tile(7, 0)
    v = h(c, r) % 9
    return tile({5: 1, 6: 2, 7: 3}.get(v, 0), 0)

world = Image.new('RGBA', (W * T, H * T))
for r in range(H):
    for c in range(W):
        world.paste(ground(c, r), (c * T, r * T))

sprites = []   # (footY, image, x, y)
def add(im, cx, foot, z=None):
    sprites.append(((foot if z is None else z), im, cx - im.width // 2, foot - im.height))

seen = set()
for r in range(H):
    for c in range(W):
        k = rows[r][c]; cx = c * T + T // 2; foot = (r + 1) * T
        if k == 'T': add(prop('tree1' if h(c, r) % 5 == 0 and r < 35 else 'tree0'), cx, foot + 2)
        elif k == 't': add(prop('bush'), cx, foot - 1)
        elif k == '*': world.alpha_composite(prop(f'flowers{h(c, r) % 4}'), (c * T, r * T))
        elif k == 'm': add(prop('mushroom'), cx, foot - 3)
        elif k == 'B': add(prop('bench'), cx, foot - 1)
        elif k == 'L': add(prop('lamp0'), cx, foot - 2)
        elif k == 'F': add(prop('fence_v' if ch(c, r - 1) == 'F' or ch(c, r + 1) == 'F' else 'fence_h'), cx, foot)
        elif k == 'R': add(prop('rock'), cx, foot - 2)
        elif k == 'b': add(prop('blocks'), cx, foot - 1)
        elif k == 'k': add(prop('crane'), cx, foot)
        elif k == 'c': add(prop(f'car{h(c, r) % 2}'), cx, foot - 1)
        elif k == 'n': add(prop('sign'), cx, foot - 1)
        elif k == 'o': world.alpha_composite(prop('lily0'), (c * T, r * T + 2))
        elif k in '123': add(prop('portal0' if k != '3' else 'portal_sleep'), cx, foot)
        elif (k == 'Q' or k in BUILD) and k not in seen:
            seen.add(k)
            cs = [cc for cc in range(W) for rr in range(H) if rows[rr][cc] == k]
            rs = [rr for cc in range(W) for rr in range(H) if rows[rr][cc] == k]
            bx = (min(cs) + max(cs) + 1) * T // 2; by = (max(rs) + 1) * T
            name = 'fountain0' if k == 'Q' else None
            if name: add(prop(name), bx, by)
            else:
                nm = 'castle_rainbow' if k == 'C' else BUILD[k]
                add(load(f'village_{nm}'), bx, by)

buddies = sys.argv[4:] if len(sys.argv) > 4 else ['lavender', 'ollie']
spots = [(20, 22), (17, 23), (12, 13), (25, 13)]
for i, b in enumerate(buddies):
    sheet = load(f'px_{b}')
    fr = sheet.crop((0, 36 * (1 if i else 0), 32, 36 * (1 if i else 0) + 36))
    c, r = spots[i % len(spots)]
    add(prop('shadow'), c * T + 8, (r + 1) * T - 1)
    add(fr, c * T + 8, (r + 1) * T + 2)

for foot, im, x, y in sorted(sprites, key=lambda s: s[0]):
    world.alpha_composite(im, (x, y))

world.resize((world.width * 2, world.height * 2), Image.NEAREST).save(sys.argv[2])
if len(sys.argv) > 3 and sys.argv[3] != '-':
    # a phone-sized closeup around the square at game scale (3x): 393 x 852 pt viewport ~ 131 x 284 art px
    cx, cy = 20 * T, 19 * T
    crop = world.crop((cx - 66, cy - 150, cx + 66, cy + 134))
    crop.resize((crop.width * 3, crop.height * 3), Image.NEAREST).save(sys.argv[3])
print('preview ok')
