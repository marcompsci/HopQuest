"""Render Fort Friends SVGs to PNGs and a review sheet."""
import base64, os, re, subprocess, sys
from playwright.sync_api import sync_playwright
here = os.path.dirname(os.path.abspath(__file__))
svg_dir, png_dir = os.path.join(here, "fort_svg"), os.path.join(here, "fort_png")
os.makedirs(png_dir, exist_ok=True)
subprocess.check_call([sys.executable, os.path.join(here, "make_fort.py"), svg_dir])
TARGET = {"fort_goal": 300, "rain_cloud": 360}
with sync_playwright() as p:
    b = p.chromium.launch()
    for f in sorted(os.listdir(svg_dir)):
        name = f[:-4]
        svg = open(os.path.join(svg_dir, f)).read()
        w, h = (int(v) for v in re.search(r'width="(\d+)" height="(\d+)"', svg).groups())
        page = b.new_page(viewport={"width": w, "height": h}, device_scale_factor=TARGET.get(name, 200 if w <= 100 else 300) / w)
        page.set_content(f'<html><body style="margin:0;background:transparent">{svg}</body></html>')
        page.locator("svg").screenshot(path=os.path.join(png_dir, f"{name}.png"), omit_background=True)
        page.close()
    uri = lambda n: "data:image/png;base64," + base64.b64encode(open(os.path.join(png_dir, n + ".png"), "rb").read()).decode()
    names = sorted(x[:-4] for x in os.listdir(png_dir))
    cells = "".join(f'<div style="background:#fff;border-radius:14px;padding:6px;text-align:center"><div style="height:170px;background:url({uri(n)}) center/contain no-repeat"></div>{n}</div>' for n in names)
    page = b.new_page(viewport={"width": 1200, "height": 600})
    page.set_content(f'<body style="margin:0;padding:12px;background:#BFE3FF;font:600 13px sans-serif;display:grid;grid-template-columns:repeat(4,1fr);gap:10px">{cells}</body>')
    page.screenshot(path=os.path.join(here, "fort_sheet.png"), full_page=True)
    b.close()
print("ok")
