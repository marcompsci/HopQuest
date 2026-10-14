"""Render README screen previews from the game's real art and layout values.

These are HTML recreations of the SwiftUI screens (same art files, colors,
sizes and positions as the Swift code), rendered at iPhone size with Chromium.
Usage: python3 make_previews.py <assets.xcassets dir> <out dir>
"""
import base64
import os
import sys

from playwright.sync_api import sync_playwright

ASSETS, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)
W, H = 390, 844


def img(name):
    path = os.path.join(ASSETS, f"{name}.imageset", f"{name}.png")
    return "data:image/png;base64," + base64.b64encode(open(path, "rb").read()).decode()


BASE = """
<style>
* { box-sizing: border-box; margin: 0; }
body { width: 390px; height: 844px; overflow: hidden; position: relative;
  font-family: ui-rounded, 'SF Pro Rounded', 'Nunito', 'Arial Rounded MT Bold', system-ui, sans-serif; color: #2B1B3D; }
.abs { position: absolute; }
.center { transform: translate(-50%, -50%); }
.status { position:absolute; top:0; left:0; right:0; height:47px; display:flex; justify-content:space-between;
  padding: 16px 32px 0; font: 600 16px system-ui; z-index: 50; }
.home { position:absolute; bottom:8px; left:50%; width:134px; height:5px; margin-left:-67px; border-radius:3px; background:#2B1B3D; z-index:50; }
.pill { background: rgba(255,255,255,.9); border-radius: 99px; padding: 4px 10px; font-weight: 700; font-size: 13px; white-space: nowrap; }
.btn3d { border-radius: 99px; color: #fff; font-weight: 900; }
</style>
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@600;700;800;900&display=swap" rel="stylesheet">
"""
STATUS = '<div class="status"><span>9:41</span><span>●●● ▮</span></div><div class="home"></div>'

# Theme: rainbow castle (sky D8F7FF -> FFF0C9, accent FF7A59)
SKY = "linear-gradient(#D8F7FF, #FFF0C9)"
ACCENT = "#FF7A59"


def world_map():
    chapters = [
        ("Meadow Street", "level_meadow", .30, .88, "done"),
        ("Driving School", "level_driving", .70, .78, "done"),
        ("Robot Lab", "level_robot", .32, .67, "open"),
        ("Lily River", "level_lily", .70, .57, "locked"),
        ("City Rally", "level_rally", .30, .47, "locked"),
        ("Castle Hill", "level_castle", .68, .37, "locked"),
    ]
    pts = [(x * W, y * H) for _, _, x, y, _ in chapters] + [(W * .5, H * .26)]
    d = f"M{pts[0][0]},{pts[0][1]}"
    for (ax, ay), (bx, by) in zip(pts, pts[1:]):
        mx, my = (ax + bx) / 2, (ay + by) / 2
        cx = mx + (-30 if bx > ax else 30)
        d += f" Q{cx},{my + 20} {bx},{by}"
    nodes = ""
    for title, art, x, y, state in chapters:
        locked = state == "locked"
        ring = f"box-shadow: 0 5px 0 rgba(0,0,0,.18), 0 0 0 5px {ACCENT};" if state == "open" else "box-shadow: 0 5px 0 rgba(0,0,0,.18);"
        badge = ""
        if locked:
            badge = f'<img src="{img("level_lock")}" class="abs" style="width:30px;left:49px;top:47px">'
        if state == "done":
            badge = f'<img src="{img("goal_star")}" class="abs" style="width:30px;left:50px;top:-4px">'
        nodes += f"""
        <div class="abs" style="left:{x*W}px;top:{y*H}px;transform:translate(-50%,-38px);display:flex;flex-direction:column;align-items:center;gap:4px">
          <div style="position:relative;width:76px;height:76px;border-radius:50%;background:{'#EDEFF3' if locked else '#fff'};{ring}">
            <img src="{img(art)}" class="abs" style="width:58px;left:9px;top:9px;{'filter:grayscale(1);opacity:.45' if locked else ''}">
            {badge}
          </div>
          <div class="pill">{title}</div>
        </div>"""
    return f"""{BASE}<body style="background:{SKY}">
    <img src="{img('map_bg')}" class="abs" style="left:0;top:0;width:{W}px;height:{H}px">
    <svg class="abs" width="{W}" height="{H}" style="left:0;top:0">
      <path d="{d}" fill="none" stroke="#D9B86A" stroke-width="30" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="{d}" fill="none" stroke="#F3D99B" stroke-width="22" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="{d}" fill="none" stroke="rgba(255,255,255,.85)" stroke-width="5" stroke-linecap="round" stroke-dasharray="2 14"/>
    </svg>
    <img src="{img('castle_rainbow')}" class="abs" style="width:{164*1.15}px;left:{W/2}px;top:{H*.2}px;transform:translate(-50%,-55%)">
    {nodes}
    <img src="{img('char_lavender')}" class="abs" style="width:64px;left:{.32*W+30}px;top:{.67*H-70}px">
    <div class="abs" style="left:12px;right:12px;top:54px;background:rgba(255,255,255,.75);border-radius:26px;padding:10px 16px;display:flex;align-items:center;gap:10px">
      <div style="width:52px;height:52px;border-radius:50%;background:rgba(255,255,255,.9);display:flex;align-items:center;justify-content:center">
        <img src="{img('char_lavender')}" style="width:50px"></div>
      <div style="flex:1"><div style="font-size:22px;font-weight:900">Hi, Maya!</div>
        <div style="font-size:16px;font-weight:700;color:#7C4DFF;display:flex;align-items:center;gap:4px"><img src="{img('goal_star')}" style="width:20px">14 stars</div></div>
      <div style="width:64px;height:52px;border-radius:16px;background:rgba(255,122,89,.35);display:flex;flex-direction:column;align-items:center;justify-content:center">
        <img src="{img('icon_together')}" style="width:30px"><div style="font-size:11px;font-weight:900">Together</div></div>
      <div style="width:44px;height:44px;border-radius:50%;background:#fff;display:flex;align-items:center;justify-content:center;font-size:22px;color:#7C4DFF">⚙︎</div>
    </div>
    <div class="abs btn3d" style="right:16px;bottom:34px;background:#FF7A59;box-shadow:0 5px 0 #C2410C;display:flex;align-items:center;gap:6px;padding:4px 22px 4px 10px;font-size:20px">
      <img src="{img('icon_kart')}" style="width:46px">Bubble Kart</div>
    {STATUS}</body>"""


def buddy_picker():
    fam = {
        "Retro Pets": ["lavender", "pixelpup", "mochi", "ollie", "coral", "sunny"],
        "Hero Squad": ["comet", "midnight", "starspark", "acorn", "novawing"],
    }
    names = {"lavender": "Lavender Lop", "pixelpup": "Pixel Pup", "mochi": "Mochi Cat", "ollie": "Ollie Owl",
             "coral": "Coral Turtle", "sunny": "Sunny Chick", "comet": "Captain Comet", "midnight": "Midnight Mask",
             "starspark": "Star Spark", "acorn": "Iron Acorn", "novawing": "Nova Wing"}
    colors = {"lavender": "#9B6BDF", "pixelpup": "#FFC95E", "mochi": "#FFB3C7", "ollie": "#8FD3C8", "coral": "#5EC8E5",
              "sunny": "#FFE66D", "comet": "#FF8A5E", "midnight": "#6C7BD9", "starspark": "#F7A8E0", "acorn": "#C9A27E",
              "novawing": "#7FD8FF"}
    secs = ""
    for title, ids in fam.items():
        cells = "".join(f"""
          <div style="background:rgba(255,255,255,{1 if i=='lavender' else .7});border-radius:18px;padding:8px 2px;text-align:center;
               {'box-shadow:inset 0 0 0 4px '+ACCENT if i=='lavender' else ''}">
            <div style="position:relative;height:70px;display:flex;justify-content:center">
              <div class="abs" style="bottom:0;width:62px;height:16px;border-radius:50%;background:{colors[i]}80;left:50%;margin-left:-31px"></div>
              <img src="{img('char_'+i)}" style="height:70px;position:relative"></div>
            <div style="font-size:12px;font-weight:700;height:30px;display:flex;align-items:center;justify-content:center">{names[i]}</div>
          </div>""" for i in ids)
        secs += f'<div style="font-size:19px;font-weight:800;margin:14px 0 10px">{title}</div><div style="display:grid;grid-template-columns:repeat(4,1fr);gap:12px">{cells}</div>'
    return f"""{BASE}<body style="background:{SKY}">
    <div style="padding-top:62px;text-align:center">
      <div style="position:relative;height:150px;display:flex;justify-content:center">
        <div class="abs" style="bottom:-6px;width:150px;height:34px;border-radius:50%;background:#9B6BDF8c;left:50%;margin-left:-75px"></div>
        <img src="{img('char_lavender')}" style="height:150px;position:relative"></div>
      <div style="font-size:26px;font-weight:900;margin-top:10px">Lavender Lop</div>
      <div style="font-size:15px;font-weight:600;opacity:.75;padding:4px 24px">Fun fact: A bunny's teeth never stop growing — crunchy hay keeps them just right!</div>
    </div>
    <div style="padding:0 18px;height:420px;overflow:hidden">{secs}</div>
    <div class="abs btn3d" style="left:28px;right:28px;bottom:34px;height:62px;background:#7C4DFF;box-shadow:0 6px 0 #7C4DFF73;border-radius:22px;display:flex;align-items:center;justify-content:center;font-size:22px">Start my adventure! 🎈</div>
    {STATUS}</body>"""


def brain_gate():
    letters = [("#4D96FF", "Left, right, then left again"), ("#FF7A59", "Only straight ahead"), ("#34C77B", "Up at the sky")]
    rows = "".join(f"""<div style="display:flex;align-items:center;gap:12px;padding:10px 12px;border-radius:18px;background:{c}1f;box-shadow:0 4px 0 {c}59">
        <div style="width:34px;height:34px;border-radius:50%;background:{c};color:#fff;font-weight:900;display:flex;align-items:center;justify-content:center">{'ABC'[i]}</div>
        <div style="font-size:20px;font-weight:700">{t}</div></div>""" for i, (c, t) in enumerate(letters))
    return f"""{BASE}<body style="background:#8ED16F">
    <img src="{img('map_bg')}" class="abs" style="left:0;top:0;width:{W}px;height:{H}px;filter:blur(3px) brightness(.85)">
    <div class="abs" style="inset:0;background:rgba(0,0,0,.35)"></div>
    <div class="abs" style="left:20px;right:20px;top:170px;display:flex;flex-direction:column;align-items:center">
      <img src="{img('char_ollie')}" style="height:84px;margin-bottom:-18px;position:relative;z-index:2">
      <div style="width:100%;background:#fff;border:4px solid #7C4DFF;border-radius:28px;overflow:hidden;box-shadow:0 6px 12px rgba(0,0,0,.2)">
        <div style="background:#7C4DFF;padding:10px 16px;display:flex;align-items:center;gap:6px">
          <span style="color:#fff;font-size:16px;font-weight:900">Brain Gate</span>
          <span style="background:#fff;color:#7C4DFF;font-size:12px;font-weight:800;border-radius:99px;padding:3px 8px">Road Safety</span>
          <span style="margin-left:auto;width:36px;height:36px;border-radius:50%;background:#fff;color:#7C4DFF;display:flex;align-items:center;justify-content:center">🔊</span></div>
        <div style="padding:14px 18px 18px;display:flex;flex-direction:column;gap:12px">
          <div style="font-size:24px;font-weight:800;text-align:center">Before you cross the street, which way do you look?</div>
          {rows}
        </div>
      </div>
    </div>{STATUS}</body>"""


def robot_lab():
    parts = [("Wheels", "part_wheels", "#FFD93D"), ("Brain Chip", "part_brain", "#FF7FC4"), ("Sensors", "part_sensors", "#5EE6FF")]
    cards = "".join(f"""<div style="background:#fff;border-radius:20px;border:2px solid {c}99;box-shadow:0 5px 0 {c}8c;padding:10px 0;text-align:center">
        <img src="{img(a)}" style="width:70px;height:70px"><div style="font-size:14px;font-weight:800">{t}</div></div>""" for t, a, c in parts)
    built = ["chassis", "battery", "motors"]
    layers = "".join(f'<img src="{img("robot_"+k)}" class="abs" style="left:0;top:0;width:210px">' for k in built)
    bar_cols = ["#8FD3F4", "#34C77B", "#7C4DFF"] + ["rgba(43,27,61,.12)"] * 3
    bar = "".join(f'<div style="flex:1;height:8px;border-radius:4px;background:{c}"></div>' for c in bar_cols)
    grid = "".join('<line x1="{0}" y1="0" x2="{0}" y2="270" stroke="#C9DDF7" stroke-width="1"/>'.format(x) for x in range(0, 360, 18))
    grid += "".join('<line x1="0" y1="{0}" x2="360" y2="{0}" stroke="#C9DDF7" stroke-width="1"/>'.format(y) for y in range(0, 270, 18))
    return f"""{BASE}<body style="background:linear-gradient(#E0F2FF,#F3ECFF)">
    <div style="padding:56px 14px 0;display:flex;align-items:center">
      <div style="width:48px;height:48px;border-radius:50%;background:#fff;display:flex;align-items:center;justify-content:center;color:#7C4DFF;font-size:22px">⌂</div>
      <div style="flex:1;display:flex;justify-content:center;align-items:center;gap:6px"><img src="{img('part_chassis')}" style="width:34px"><span style="font-size:26px;font-weight:900">Robot Lab</span></div>
      <div style="width:48px;display:flex;gap:4px;justify-content:center"><i style="width:10px;height:10px;border-radius:50%;background:#7C4DFF"></i><i style="width:10px;height:10px;border-radius:50%;background:rgba(43,27,61,.15)"></i></div>
    </div>
    <div style="text-align:center;font-size:17px;font-weight:700;color:#7C4DFF;padding:10px 20px;min-height:54px">Hmm, not yet! The motors spin… what turns spinning into rolling?</div>
    <div style="position:relative;margin:0 16px;height:270px;border-radius:26px;overflow:hidden;border:3px solid #B9D3F5;background:#EAF3FF">
      <svg class="abs" width="360" height="270" style="left:0;top:0">{grid}</svg>
      <div class="abs" style="left:22px;right:22px;bottom:14px;height:22px;border-radius:10px;background:linear-gradient(#D9A066,#A0673B);border:2px solid rgba(43,27,61,.35)"></div>
      <div class="abs" style="left:50%;margin-left:-105px;bottom:26px;width:210px;height:{210*480/400:.0f}px">
        <img src="{img('robot_ghost')}" class="abs" style="left:0;top:0;width:210px;opacity:.5">{layers}</div>
    </div>
    <div style="display:flex;gap:6px;padding:14px 40px">{bar}</div>
    <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:12px;padding:0 16px">{cards}</div>
    {STATUS}</body>"""


def balloon(theme, char, size):
    w = size * 1.16
    h = w * 380 / 220
    r = w * 0.34
    return f"""<div style="position:relative;width:{w}px;height:{h}px">
      <img src="{img('balloon_'+theme)}" class="abs" style="left:0;top:0;width:{w}px;height:{h}px">
      <img src="{img('char_'+char)}" class="abs" style="width:{r}px;left:{w/2-r/2}px;top:{h*340/380-r}px">
      <img src="{img('balloon_front')}" class="abs" style="left:0;top:0;width:{w}px;height:{h}px"></div>"""


def welcome():
    return f"""{BASE}<body style="background:{SKY}">
    <div style="height:844px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:24px;padding-bottom:60px">
      {balloon('rainbow', 'lavender', 130)}
      <div style="font-size:48px;font-weight:900;color:#7C4DFF">HopQuest</div>
      <div style="font-size:20px;font-weight:700;text-align:center;padding:0 30px">Hop, drive, build, and learn your way to the castle!</div>
    </div>
    <div class="abs btn3d" style="left:28px;right:28px;bottom:48px;height:62px;background:#7C4DFF;box-shadow:0 6px 0 #7C4DFF73;border-radius:22px;display:flex;align-items:center;justify-content:center;font-size:22px">Let's play!</div>
    {STATUS}</body>"""


def balloon_flight():
    cloud = '<div class="abs" style="left:{x}px;top:{y}px;width:130px;height:56px"><div class="abs" style="left:10px;top:22px;width:110px;height:34px;border-radius:20px;background:#fff"></div><div class="abs" style="left:30px;top:4px;width:50px;height:50px;border-radius:50%;background:#fff"></div><div class="abs" style="left:62px;top:12px;width:40px;height:40px;border-radius:50%;background:#fff"></div></div>'
    clouds = "".join(cloud.format(x=x*W-65, y=i*H*.16-H*.1+60) for i, x in enumerate([0.15, 0.8, 0.4, 0.9, 0.2, 0.65, 0.35]))
    b = balloon('sparkle', 'lavender', 120)
    return f"""{BASE}<body style="background:linear-gradient(#FFE4F3,#E9D5FF,#fff)">
    {clouds}
    <div class="abs" style="left:{W/2}px;top:{H*.6}px;transform:translate(-50%,-50%) scale(1.6)">{b}</div>
    <div class="abs" style="left:0;right:0;top:{H*.18-20}px;text-align:center;font-size:30px;font-weight:900;color:#7C4DFF">Up, up and away! 🎈</div>
    {STATUS}</body>"""


SCREENS = {"world-map": world_map, "buddy-picker": buddy_picker, "brain-gate": brain_gate,
           "robot-lab": robot_lab, "welcome": welcome, "balloon-flight": balloon_flight}

with sync_playwright() as p:
    b = p.chromium.launch()
    for name, fn in SCREENS.items():
        page = b.new_page(viewport={"width": W, "height": H}, device_scale_factor=2)
        page.set_content(f"<html>{fn()}</html>")
        page.wait_for_timeout(600)
        page.screenshot(path=os.path.join(OUT, f"{name}.png"))
        page.close()
    b.close()
print("ok")
