"""Render world SVGs to PNGs and a review sheet."""
import base64
import os
import re
import subprocess
import sys

from playwright.sync_api import sync_playwright

here = os.path.dirname(os.path.abspath(__file__))
svg_dir = os.path.join(here, "world_svg")
png_dir = os.path.join(here, "world_png")
os.makedirs(png_dir, exist_ok=True)
subprocess.check_call([sys.executable, os.path.join(here, "make_world.py"), svg_dir])

TARGET = {"castle_": 600, "balloon_": 330, "map_bg": 1200}

with sync_playwright() as p:
    b = p.chromium.launch()
    for f in sorted(os.listdir(svg_dir)):
        name = f[:-4]
        svg = open(os.path.join(svg_dir, f)).read()
        w, h = (int(v) for v in re.search(r'width="(\d+)" height="(\d+)"', svg).groups())
        target = next((v for k, v in TARGET.items() if name.startswith(k)), 300)
        page = b.new_page(viewport={"width": w, "height": h}, device_scale_factor=target / w)
        page.set_content(f'<html><body style="margin:0;background:transparent">{svg}</body></html>')
        page.locator("svg").screenshot(path=os.path.join(png_dir, f"{name}.png"), omit_background=True)
        page.close()

    def uri(n):
        return "data:image/png;base64," + base64.b64encode(open(os.path.join(png_dir, f"{n}.png"), "rb").read()).decode()

    names = sorted(x[:-4] for x in os.listdir(png_dir) if not x.startswith("map_bg"))
    cells = "".join(f'<div class="c"><div class="i" style="background-image:url({uri(n)})"></div><div>{n}</div></div>' for n in names)
    page = b.new_page(viewport={"width": 1500, "height": 1000})
    page.set_content(f"""<html><body style="margin:0;background:linear-gradient(#E0F2FF,#F3ECFF);font:600 13px sans-serif;display:flex">
    <div style="width:330px;height:710px;margin:12px;border-radius:20px;background:linear-gradient(#D8F7FF,#FFF0C9);
      background-image:url({uri('map_bg')}), linear-gradient(#D8F7FF,#FFF0C9);background-size:100% 100%"></div>
    <style>.g{{display:grid;grid-template-columns:repeat(6,1fr);gap:10px;padding:12px;flex:1}} .c{{background:#fff;border-radius:16px;text-align:center;padding:6px}}
    .i{{height:150px;background-size:contain;background-repeat:no-repeat;background-position:center}}</style>
    <div class="g">{cells}</div></body></html>""")
    page.wait_for_timeout(300)
    page.screenshot(path=os.path.join(here, "world_sheet.png"), full_page=True)
    b.close()
print("ok")
