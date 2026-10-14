"""Render Robot Lab SVGs to transparent PNGs plus a review sheet."""
import base64
import os
import subprocess
import sys

from playwright.sync_api import sync_playwright

here = os.path.dirname(os.path.abspath(__file__))
svg_dir = os.path.join(here, "robot_svg")
png_dir = os.path.join(here, "robot_png")
os.makedirs(png_dir, exist_ok=True)
subprocess.check_call([sys.executable, os.path.join(here, "make_robot.py"), svg_dir])

with sync_playwright() as p:
    b = p.chromium.launch()
    for f in sorted(os.listdir(svg_dir)):
        name = f[:-4]
        svg = open(os.path.join(svg_dir, f)).read()
        w = 420 if name.startswith("robot_") and name != "robot_gear" else (100 if name == "robot_gear" else 200)
        h = 460 if w == 420 else w
        target = 600 if w == 420 else 300
        page = b.new_page(viewport={"width": w, "height": h}, device_scale_factor=target / w)
        page.set_content(f'<html><body style="margin:0;background:transparent">{svg}</body></html>')
        page.locator("svg").screenshot(path=os.path.join(png_dir, f"{name}.png"), omit_background=True)
        page.close()

    def uri(n):
        return "data:image/png;base64," + base64.b64encode(open(os.path.join(png_dir, f"{n}.png"), "rb").read()).decode()

    layers = ["robot_wheels", "robot_chassis", "robot_motors", "robot_battery", "robot_sensors", "robot_brain", "robot_smile"]
    stack = "".join(f'<img src="{uri(n)}" style="position:absolute;inset:0;width:100%">' for n in layers)
    partial = "".join(f'<img src="{uri(n)}" style="position:absolute;inset:0;width:100%">' for n in ["robot_ghost", "robot_wheels", "robot_chassis", "robot_battery"])
    icons = "".join(f'<div class="c"><img src="{uri(n)}" style="width:100%"><div>{n[5:]}</div></div>'
                    for n in ["part_chassis", "part_battery", "part_motors", "part_wheels", "part_sensors", "part_brain", "goal_star", "robot_gear"])
    page = b.new_page(viewport={"width": 1300, "height": 900})
    page.set_content(f"""<html><body style="margin:0;background:linear-gradient(#E0F2FF,#F3ECFF);font:600 16px sans-serif">
    <div style="display:flex;gap:20px;padding:16px">
      <div style="position:relative;width:300px;height:330px;background:#fff6;border-radius:20px"><img src="{uri('robot_ghost')}" style="position:absolute;inset:0;width:100%"></div>
      <div style="position:relative;width:300px;height:330px;background:#fff6;border-radius:20px">{partial}</div>
      <div style="position:relative;width:300px;height:330px;background:#fff6;border-radius:20px">{stack}</div>
    </div>
    <style>.g{{display:grid;grid-template-columns:repeat(8,1fr);gap:10px;padding:16px}} .c{{background:#fff;border-radius:18px;text-align:center;padding:8px}}</style>
    <div class="g">{icons}</div></body></html>""")
    page.wait_for_timeout(300)
    page.screenshot(path=os.path.join(here, "robot_sheet.png"), full_page=True)
    b.close()
print("ok")
