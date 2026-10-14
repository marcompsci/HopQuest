"""Render character SVGs to transparent PNGs and a review sheet."""
import json
import os
import subprocess
import sys

from playwright.sync_api import sync_playwright

here = os.path.dirname(os.path.abspath(__file__))
svg_dir = os.path.join(here, "svg")
png_dir = os.path.join(here, "png")
os.makedirs(png_dir, exist_ok=True)
names = json.loads(subprocess.check_output([sys.executable, os.path.join(here, "make_characters.py"), svg_dir]))
size = int(sys.argv[1]) if len(sys.argv) > 1 else 420

with sync_playwright() as p:
    b = p.chromium.launch()
    page = b.new_page(viewport={"width": 420, "height": 460}, device_scale_factor=size / 420)
    for n in names:
        svg = open(os.path.join(svg_dir, f"{n}.svg")).read()
        page.set_content(f'<html><body style="margin:0;background:transparent">{svg}</body></html>')
        page.locator("svg").screenshot(path=os.path.join(png_dir, f"{n}.png"), omit_background=True)

    # review sheet
    import base64
    def uri(n):
        return "data:image/png;base64," + base64.b64encode(open(os.path.join(png_dir, f"{n}.png"), "rb").read()).decode()
    cells = "".join(
        f'<div class="c"><img src="{uri(n)}"><div>{n}</div></div>' for n in names)
    page2 = b.new_page(viewport={"width": 1400, "height": 1200})
    page2.set_content(f"""<html><body style="margin:0;background:linear-gradient(#cdeBff,#a9d0f5);font:600 16px sans-serif">
    <style>.g{{display:grid;grid-template-columns:repeat(6,1fr);gap:8px;padding:12px}}
    .c{{background:#fff8;border-radius:18px;text-align:center;padding:6px}} img{{width:100%}}</style>
    <div class="g">{cells}</div></body></html>""")
    page2.wait_for_timeout(300)
    page2.screenshot(path=os.path.join(here, "sheet.png"), full_page=True)
    b.close()
print("ok", len(names))
