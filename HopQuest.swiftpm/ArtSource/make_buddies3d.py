"""HopQuest — "3D" buddies for Hop Village.

Bakes soft volumetric lighting into each original char_<id> illustration so buddies look rounded and
smooth (like little vinyl toys) instead of flat pixel sprites:
  * a height field: a dome over the whole silhouette plus a "pillow" for every inked part,
  * normals from that height field, lit from the top-left front (Lambert + soft specular + rim light),
  * a little ambient occlusion toward the feet.
Outputs buddy3d_<id> imagesets (256 px tall, transparent) that HopVillageScene draws with smooth filtering.

Run:  python3 make_buddies3d.py <Assets.xcassets dir> [preview.png]
"""
import os, sys, json
import numpy as np
from PIL import Image
from scipy import ndimage

H_OUT = 256
LIGHT = np.array([-0.55, -0.62, 0.56])          # x right, y DOWN (image space), z toward viewer
LIGHT = LIGHT / np.linalg.norm(LIGHT)
VIEW = np.array([0.0, 0.0, 1.0])
HALF = (LIGHT + VIEW) / np.linalg.norm(LIGHT + VIEW)


def bake(src_path):
    im = Image.open(src_path).convert('RGBA')
    im = im.crop(im.getbbox())
    w = round(im.width * H_OUT / im.height)
    im = im.resize((w, H_OUT), Image.LANCZOS)
    # pad so the rim light and blur never clip
    pad = 6
    canvas = Image.new('RGBA', (w + pad * 2, H_OUT + pad * 2), (0, 0, 0, 0))
    canvas.alpha_composite(im, (pad, pad))
    a = np.asarray(canvas).astype(np.float32) / 255.0
    rgb, alpha = a[..., :3], a[..., 3]
    inside = alpha > 0.5

    lum = rgb @ np.array([0.3, 0.59, 0.11])
    ink = inside & (lum < 0.25)

    # 1) global dome over the silhouette
    d_global = ndimage.distance_transform_edt(inside)
    dome = np.sqrt(d_global / max(1.0, d_global.max()))
    # 2) pillow for each inked part (distance to the nearest outline or ink line)
    parts = inside & ~ink
    d_part = ndimage.distance_transform_edt(parts)
    pillow = np.sqrt(np.clip(d_part / 12.0, 0, 1))
    height = 0.65 * dome * 38 + 0.35 * pillow * 14
    height = ndimage.gaussian_filter(height, 1.6)

    gy, gx = np.gradient(height)
    n = np.dstack([-gx, -gy, np.ones_like(height)])
    n /= np.linalg.norm(n, axis=2, keepdims=True)

    diffuse = np.clip(n @ LIGHT, 0, 1)
    spec = np.clip(n @ HALF, 0, 1) ** 40
    rim = (1 - np.clip(n[..., 2], 0, 1)) ** 2.2
    # ambient occlusion: a touch darker toward the feet and in creases
    yy = np.linspace(0, 1, height.shape[0])[:, None]
    ao = 1 - 0.10 * np.clip((yy - 0.55) / 0.45, 0, 1) - 0.06 * (1 - np.clip(d_part / 4.0, 0, 1)) * parts

    shade = (0.60 + 0.52 * diffuse) * ao
    out = rgb * shade[..., None]
    out += (0.22 * spec * ~ink)[..., None]                 # soft plastic shine (not on ink lines)
    out += (0.16 * rim * (n[..., 0] > 0) * ~ink)[..., None] * np.array([0.85, 0.9, 1.0])   # cool rim light on the right
    out = np.clip(out, 0, 1)
    res = np.dstack([out, alpha])
    return Image.fromarray((res * 255).astype(np.uint8), 'RGBA')


def save_imageset(assets, name, im):
    d = os.path.join(assets, f'{name}.imageset'); os.makedirs(d, exist_ok=True)
    im.save(os.path.join(d, f'{name}.png'))
    json.dump({"images": [{"filename": f"{name}.png", "idiom": "universal"}],
               "info": {"author": "xcode", "version": 1}}, open(os.path.join(d, 'Contents.json'), 'w'), indent=2)


def main():
    assets = sys.argv[1]
    ids = sorted(d[5:-9] for d in os.listdir(assets) if d.startswith('char_') and d.endswith('.imageset'))
    baked = {}
    for cid in ids:
        out = bake(os.path.join(assets, f'char_{cid}.imageset', f'char_{cid}.png'))
        save_imageset(assets, f'buddy3d_{cid}', out)
        baked[cid] = out
    if len(sys.argv) > 2:
        pick = [c for c in ['lavender', 'rocky', 'pip', 'ollie', 'benny', 'novawing', 'leo', 'stella'] if c in baked]
        sheet = Image.new('RGBA', (sum(baked[c].width for c in pick) * 2 + 20 * len(pick), 560), (140, 205, 110, 255))
        x = 10
        for c in pick:
            src = Image.open(os.path.join(assets, f'char_{c}.imageset', f'char_{c}.png')).convert('RGBA')
            src = src.crop(src.getbbox()); src = src.resize((round(src.width * 256 / src.height), 256), Image.LANCZOS)
            sheet.alpha_composite(src, (x, 10))
            sheet.alpha_composite(baked[c], (x - 6, 280))
            x += max(src.width, baked[c].width) + 20
        sheet.save(sys.argv[2])
    print('baked', len(baked))


if __name__ == '__main__':
    main()
