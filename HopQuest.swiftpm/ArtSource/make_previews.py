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
        ("Meadow Street", "level_meadow", .30, .765, "done"),
        ("Driving School", "level_driving", .70, .685, "done"),
        ("Robot Lab", "level_robot", .30, .60, "open"),
        ("Lily River", "level_lily", .70, .515, "locked"),
        ("City Rally", "level_rally", .30, .43, "locked"),
        ("Castle Hill", "level_castle", .68, .345, "locked"),
    ]
    pts = [(x * W, 47 + y * 763) for _, _, x, y, _ in chapters] + [(W * .5, 47 + 763 * .26)]
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
        <div class="abs" style="left:{x*W}px;top:{47 + y*763}px;transform:translate(-50%,-38px);display:flex;flex-direction:column;align-items:center;gap:4px">
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
    <img src="{img('castle_rainbow')}" class="abs" style="width:{164*1.15}px;left:{W/2}px;top:{47+763*.2}px;transform:translate(-50%,-55%)">
    {nodes}
    <img src="{img('char_lavender')}" class="abs" style="width:64px;left:{.30*W+30}px;top:{47+.60*763-70}px">
    <div class="abs" style="left:12px;right:12px;top:54px;background:rgba(255,255,255,.75);border-radius:26px;padding:10px 16px;display:flex;align-items:center;gap:10px">
      <div style="width:52px;height:52px;border-radius:50%;background:rgba(255,255,255,.9);display:flex;align-items:center;justify-content:center">
        <img src="{img('char_lavender')}" style="width:50px"></div>
      <div style="flex:1"><div style="font-size:22px;font-weight:900">Hi, Maya!</div>
        <div style="font-size:16px;font-weight:700;color:#7C4DFF;display:flex;align-items:center;gap:4px"><img src="{img('goal_star')}" style="width:20px">14 stars</div></div>
      <div style="width:64px;height:52px;border-radius:16px;background:rgba(255,122,89,.35);display:flex;flex-direction:column;align-items:center;justify-content:center">
        <img src="{img('icon_together')}" style="width:30px"><div style="font-size:11px;font-weight:900">Together</div></div>
      <div style="width:44px;height:44px;border-radius:50%;background:#fff;display:flex;align-items:center;justify-content:center;font-size:22px;color:#7C4DFF">⚙︎</div>
    </div>
    <div class="abs" style="left:12px;right:12px;bottom:42px;background:rgba(255,255,255,.8);border-radius:28px;padding:8px;display:flex;gap:6px">
      <div style="flex:1;position:relative;background:#FF9F45;box-shadow:0 5px 0 #D9731C;border-radius:20px;padding:6px 0;text-align:center;color:#fff;font-weight:900;font-size:13px"><img src="{img('icon_stickers')}" style="width:44px;display:block;margin:0 auto">Stickers
        <div class="abs" style="right:-6px;top:-8px;width:26px;height:26px;border-radius:50%;background:#FF5A5F;border:2px solid #fff;font-size:15px;line-height:22px">1</div></div>
      <div style="flex:1;background:#34C77B;box-shadow:0 5px 0 #239A5C;border-radius:20px;padding:6px 0;text-align:center;color:#fff;font-weight:900;font-size:13px"><img src="{img('icon_fort')}" style="width:44px;display:block;margin:0 auto">Fort Friends</div>
      <div style="flex:1;background:#B983FF;box-shadow:0 5px 0 #7C4DFF;border-radius:20px;padding:6px 0;text-align:center;color:#fff;font-weight:900;font-size:13px"><img src="{img('icon_bop')}" style="width:44px;display:block;margin:0 auto">Pillow Bop</div>
      <div style="flex:1;background:#FF7A59;box-shadow:0 5px 0 #C2410C;border-radius:20px;padding:6px 0;text-align:center;color:#fff;font-weight:900;font-size:13px"><img src="{img('icon_kart')}" style="width:44px;display:block;margin:0 auto">Bubble Kart</div>
    </div>
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


def bop_arena():
    gy = 844 - 844 * 0.40
    iw = 390 * 0.92
    ih = iw * 380 / 800
    def char(cid, x, feet, flip=False, pillow=True, me=False):
        w, h = 62, 68
        top = feet - h + 0.07 * h
        sx = -1 if flip else 1
        pil = (f'<img src="{img("pillow")}" class="abs" style="width:46px;left:{31 + 22 - 23}px;top:{h - 0.07*h - 29.7 - 15.5}px;transform:rotate(-28deg)">'
               if pillow else "")
        arrow = f'<div class="abs" style="left:{x-10}px;top:{top-30}px;color:#FF7A59;font-size:20px;font-weight:900">▼</div>' if me else ""
        return (f'<div class="abs" style="left:{x-27}px;top:{feet-4}px;width:44px;height:9px;border-radius:50%;background:rgba(0,0,0,.15)"></div>'
                f'<div class="abs" style="left:{x-31}px;top:{top}px;width:{w}px;height:{h}px;transform:scaleX({sx})">'
                f'<img src="{img("char_"+cid)}" class="abs" style="left:0;top:0;width:{w}px;height:{h}px;z-index:1">{pil}</div>' + arrow)
    def cloud(cx, walk, w):
        h = w * 138 / 360
        return f'<img src="{img("cloud_platform")}" class="abs" style="width:{w}px;left:{cx-w/2}px;top:{walk - h*46/138}px">'
    score = [("lavender", 7, .25, True), ("pixelpup", 5, .55, False), ("broccoli", 3, .15, False), ("ellie", 4, .7, False)]
    cells = "".join(f"""<div style="flex:1;background:rgba(255,255,255,{.95 if me else .75});border-radius:16px;padding:6px 0;text-align:center;{'box-shadow:inset 0 0 0 3px #FF7A59' if me else ''}">
        <img src="{img('char_'+c)}" style="height:44px"><div style="font-size:18px;font-weight:900">{n}</div>
        <div style="margin:2px auto 0;width:46px;height:7px;border-radius:4px;background:rgba(43,27,61,.12)"><div style="width:{max(4,46*g)}px;height:7px;border-radius:4px;background:{'#FF5A5F' if g>.6 else '#FFB020' if g>.3 else '#34C77B'}"></div></div></div>""" for c, n, g, me in score)
    return f"""{BASE}<body style="background:#BFE6FF">
    <img src="{img('arena_bg')}" class="abs" style="left:0;top:0;width:390px;height:844px">
    <img src="{img('arena_island')}" class="abs" style="width:{iw}px;left:{195-iw/2}px;top:{gy - ih*50/380}px">
    {cloud(390*.24, gy-140, 120)}{cloud(390*.76, gy-140, 120)}{cloud(195, gy-235, 110)}
    <img src="{img('brain_bubble')}" class="abs" style="width:58px;left:{195-29}px;top:{gy-64-29}px">
    {char('lavender', 130, gy, me=True)}{char('pixelpup', 186, gy, flip=True)}
    {char('broccoli', 390*.76, gy-140, flip=True)}{char('ellie', 300, gy-60, flip=True, pillow=True)}
    <div class="abs" style="left:150px;top:{gy-112}px;font-size:26px;font-weight:900;color:#fff;text-shadow:2px 3px 0 #7C4DFF">BOP!</div>
    <div class="abs" style="left:14px;right:14px;top:53px;display:flex;align-items:center;justify-content:space-between">
      <div style="width:48px;height:48px;border-radius:50%;background:#fff;display:flex;align-items:center;justify-content:center;color:#7C4DFF;font-size:22px">⌂</div>
      <div style="background:rgba(255,255,255,.92);border-radius:99px;height:44px;padding:0 16px;display:flex;align-items:center;gap:6px;font-size:22px;font-weight:900">⏱ 42</div>
      <div style="width:48px"></div></div>
    <div class="abs" style="left:14px;right:14px;top:110px;display:flex;gap:8px">{cells}</div>
    <div class="abs" style="left:0;right:0;bottom:0;height:150px;background:linear-gradient(rgba(0,0,0,0),rgba(0,0,0,.3))"></div>
    <div class="abs" style="left:14px;right:14px;bottom:44px;display:flex;align-items:flex-end;gap:12px">
      <div style="width:70px;height:70px;border-radius:20px;background:rgba(255,255,255,.9);box-shadow:0 5px 0 rgba(0,0,0,.2);display:flex;align-items:center;justify-content:center;font-size:30px">◀</div>
      <div style="width:70px;height:70px;border-radius:20px;background:rgba(255,255,255,.9);box-shadow:0 5px 0 rgba(0,0,0,.2);display:flex;align-items:center;justify-content:center;font-size:30px">▶</div>
      <div style="flex:1"></div>
      <div style="width:74px;height:74px;border-radius:50%;background:#4D96FF;border:3px solid #fff;box-shadow:0 5px 0 #4D96FF99;color:#fff;font-weight:900;font-size:18px;display:flex;align-items:center;justify-content:center">JUMP</div>
      <div style="width:92px;height:92px;border-radius:50%;background:#FF7FC4;border:3px solid #fff;box-shadow:0 5px 0 #FF7FC499;color:#fff;font-weight:900;font-size:22px;display:flex;align-items:center;justify-content:center">BOP!</div>
    </div>
    {STATUS}</body>"""


def sticker_book():
    pets = [("lavender", "Lavender Lop", "#9B6BDF", True), ("pixelpup", "Pixel Pup", "#FFC95E", True), ("mochi", "Mochi Cat", "#FFB3C7", False),
            ("ollie", "Ollie Owl", "#8FD3C8", True), ("coral", "Coral Turtle", "#5EC8E5", False), ("sunny", "Sunny Chick", "#FFE66D", True)]
    heroes = [("comet", "Captain Comet", "#FF8A5E", True), ("midnight", "Midnight Mask", "#6C7BD9", False), ("starspark", "Star Spark", "#F7A8E0", True),
              ("acorn", "Iron Acorn", "#C9A27E", False), ("novawing", "Nova Wing", "#7FD8FF", False)]
    tilts = [-5, 4, -2, 6, -4, 3]
    def grid(lst):
        out = ""
        for i, (cid, name, col, own) in enumerate(lst):
            if own:
                out += f"""<div style="text-align:center"><div style="margin:0 auto;width:84px;height:84px;border-radius:24px;background:#fff;box-shadow:0 3px 3px rgba(0,0,0,.15);padding:6px;transform:rotate({tilts[i%6]}deg)">
                  <div style="width:100%;height:100%;border-radius:18px;background:{col}73;display:flex;align-items:center;justify-content:center"><img src="{img('char_'+cid)}" style="height:72px"></div></div>
                  <div style="font-size:11px;font-weight:700;margin-top:3px">{name}</div></div>"""
            else:
                out += f'<div style="height:112px;display:flex;align-items:center;justify-content:center"><img src="{img("sticker_locked")}" style="width:80px"></div>'
        return out
    def sec(title, lst):
        n = sum(1 for x in lst if x[3])
        return f"""<div style="background:rgba(255,255,255,.6);border-radius:24px;padding:14px;margin-top:14px">
          <div style="display:flex;justify-content:space-between;font-size:20px;font-weight:800">{title}<span style="color:#7C4DFF;font-size:15px">{n}/{len(lst)}</span></div>
          <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin-top:10px">{grid(lst)}</div></div>"""
    return f"""{BASE}<body style="background:linear-gradient(#FFF4E0,#F3ECFF)">
    <div style="padding:54px 18px 0">
      <div style="display:flex;justify-content:space-between"><div style="width:48px;height:48px;border-radius:50%;background:#fff;display:flex;align-items:center;justify-content:center;color:#7C4DFF;font-size:22px">⌂</div>
        <div style="width:44px;height:44px;border-radius:50%;background:#F3ECFF;display:flex;align-items:center;justify-content:center">🔊</div></div>
      <div style="display:flex;align-items:center;justify-content:center;gap:8px;margin-top:-6px"><img src="{img('icon_stickers')}" style="width:58px"><span style="font-size:34px;font-weight:900;color:#7C4DFF">Sticker Book</span></div>
      <div style="text-align:center;font-size:16px;font-weight:700">8 of 23 buddies</div>
      <div style="margin:4px 30px 0;height:12px;border-radius:6px;background:rgba(43,27,61,.1)"><div style="width:35%;height:12px;border-radius:6px;background:linear-gradient(90deg,#FF7FC4,#7C4DFF)"></div></div>
      <div style="margin-top:16px;background:#7C4DFF;box-shadow:0 5px 0 #5B32D6;border-radius:22px;padding:14px;display:flex;align-items:center;gap:14px">
        <div style="width:64px;height:82px;border-radius:14px;border:3px solid #2B1B3D;background:linear-gradient(#FFD93D,#FF9F45);display:flex;align-items:center;justify-content:center;transform:rotate(-6deg)"><img src="{img('goal_star')}" style="width:40px"></div>
        <div><div style="color:#fff;font-size:20px;font-weight:900">Open your sticker pack!</div><div style="color:rgba(255,255,255,.9);font-size:14px;font-weight:700">Tap to find out who's inside!</div></div></div>
      {sec('Retro Pets', pets)}{sec('Hero Squad', heroes)}
    </div>{STATUS}</body>"""


def fort_friends():
    rows = ["..............................", "..............................", "..............................",
            ".......B..............B.......", "......###........B...###......", "S..C..###.....G......###...F..",
            "##########~~~~################", "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"]
    built = {(4, 2): ("piece_ramp", 1), (5, 2): ("piece_block", 1), (5, 3): ("piece_ramp", 1)}
    c = 54
    base = 186 - 0.7 * c
    nrow = len(rows)
    def top(y): return 844 - (base + (y + 1) * c)
    tiles = ""
    for ri, line in enumerate(rows):
        y = nrow - 1 - ri
        for x, ch in enumerate(line[:8]):
            name = None
            if ch == "#":
                above = rows[ri - 1][x] if ri > 0 else "."
                name = "fort_grass" if above != "#" else "fort_dirt"
            elif ch == "~":
                name = "fort_water"
            if name:
                tiles += f'<img src="{img(name)}" class="abs" style="left:{x*c}px;top:{top(y)}px;width:{c+1}px;height:{c+1}px">'
    for (x, y), (n, d) in built.items():
        tiles += f'<img src="{img(n)}" class="abs" style="left:{x*c}px;top:{top(y)}px;width:{c+1}px;height:{c+1}px;transform:scaleX({d})">'
    items = f'<img src="{img("crate")}" class="abs" style="left:{3*c+5}px;top:{top(2)+11}px;width:{c*0.8}px">'
    items += f'<img src="{img("party_balloon")}" class="abs" style="left:{7*c+4}px;top:{top(4)+2}px;width:{c*0.85}px">'
    # player standing on the pillar at (6,4)
    pw = c * 0.95 * 1.15
    items += f'<img src="{img("char_lavender")}" class="abs" style="left:{6.5*c - pw/2}px;top:{top(4) + c - pw*460/420 + 4}px;width:{pw}px">'
    ghosts = "".join(f'<div class="abs" style="left:{x*c+4}px;top:{top(y)+4}px;width:{c-8}px;height:{c-8}px;border:3px solid #34C77B;border-radius:10px;background:rgba(255,255,255,.25)"></div>'
                     for (x, y) in [(3, 3), (4, 3), (6, 5), (7, 5), (8, 4), (9, 4), (9, 3)])
    rain = f'<div class="abs" style="left:0;top:{top(7)}px;width:{c*0.9}px;height:{8*c}px;background:rgba(91,107,140,.28)"></div><img src="{img("rain_cloud")}" class="abs" style="left:{-c*1.6}px;top:{top(7)+4}px;width:{c*3.2}px">'
    tools = [("piece_ramp", "Ramp", "2 🧱", True), ("piece_block", "Block", "1 🧱", False), ("piece_bridge", "Bridge", "1 🧱", False), (None, "Take back", "", False)]
    tb = "".join(f"""<div style="flex:1;height:72px;border-radius:18px;background:{'#FFF4C2' if sel else 'rgba(255,255,255,.92)'};{'box-shadow:inset 0 0 0 4px #FFB020' if sel else 'box-shadow:0 4px 0 rgba(0,0,0,.2)'};text-align:center;padding-top:4px;font-size:12px;font-weight:900">
        {f'<img src="{img(a)}" style="width:34px;height:34px">' if a else '<div style="width:34px;height:34px;margin:0 auto;border-radius:50%;background:#FF5A5F;color:#fff;font-size:20px;line-height:34px">↺</div>'}<div>{t}</div><div style="font-size:11px;opacity:.75">{cst}</div></div>""" for a, t, cst, sel in tools)
    return f"""{BASE}<body style="background:#BFE6FF">
    <img src="{img('arena_bg')}" class="abs" style="left:0;top:0;width:390px;height:844px">
    <div class="abs" style="left:0;right:0;bottom:0;height:{base + 0.2*c}px;background:#5EC8F2"></div>
    {tiles}{rain}{ghosts}{items}
    <div class="abs" style="left:14px;right:14px;top:53px;display:flex;gap:8px;align-items:center">
      <div style="width:48px;height:48px;border-radius:50%;background:#fff;display:flex;align-items:center;justify-content:center;color:#7C4DFF;font-size:22px">⌂</div>
      <div style="background:rgba(255,255,255,.92);border-radius:99px;height:42px;padding:0 12px;display:flex;align-items:center;gap:4px;font-size:20px;font-weight:900"><img src="{img('icon_bricks')}" style="width:26px">7</div>
      <div style="background:rgba(255,255,255,.92);border-radius:99px;height:42px;padding:0 12px;display:flex;align-items:center;gap:4px;font-size:20px;font-weight:900"><img src="{img('party_balloon')}" style="width:26px">0/3</div>
    </div>
    <div class="abs" style="left:16px;right:16px;top:108px;background:#fff;border-radius:18px;padding:10px 14px;font-size:15px;font-weight:700;box-shadow:0 3px 0 rgba(124,77,255,.3)">A ramp is an inclined plane. It's a simple machine that makes going up easier!</div>
    <div class="abs" style="left:0;right:0;bottom:0;height:170px;background:linear-gradient(rgba(0,0,0,0),rgba(0,0,0,.35))"></div>
    <div class="abs" style="left:14px;right:14px;bottom:110px;display:flex;gap:8px">{tb}</div>
    <div class="abs" style="left:14px;right:14px;bottom:30px;display:flex;align-items:center;gap:12px">
      <div style="width:70px;height:70px;border-radius:20px;background:rgba(255,255,255,.9);box-shadow:0 5px 0 rgba(0,0,0,.2);display:flex;align-items:center;justify-content:center;font-size:30px">◀</div>
      <div style="width:70px;height:70px;border-radius:20px;background:rgba(255,255,255,.9);box-shadow:0 5px 0 rgba(0,0,0,.2);display:flex;align-items:center;justify-content:center;font-size:30px">▶</div>
      <div style="flex:1;text-align:right;color:#fff;font-size:13px;font-weight:700;text-shadow:0 1px 2px rgba(0,0,0,.4)">Tap a glowing square to build.</div>
    </div>
    {STATUS}</body>"""


def code_club():
    cell, gap = 50, 4
    step = cell + gap
    rocks = [(2, 5), (0, 3), (3, 4)]
    gears = [(3, 3)]
    trail = [(0, 5), (1, 5), (1, 4), (2, 4), (2, 3)]
    tiles = ""
    for y in range(6):
        for x in range(6):
            col = "#F6F0FF" if (x + y) % 2 == 0 else "#EADFFF"
            dot = '<div style="width:10px;height:10px;border-radius:50%;background:rgba(124,77,255,.35)"></div>' if (x, y) in trail else ""
            tiles += f'<div class="abs" style="left:{x*step}px;top:{y*step}px;width:{cell}px;height:{cell}px;border-radius:11px;background:{col};display:flex;align-items:center;justify-content:center">{dot}</div>'
    for (x, y) in rocks:
        tiles += f'<img src="{img("code_rock")}" class="abs" style="left:{x*step+2}px;top:{y*step+2}px;width:{cell-4}px">'
    for (x, y) in gears:
        tiles += f'<img src="{img("robot_gear")}" class="abs" style="left:{x*step+10}px;top:{y*step+10}px;width:{cell-20}px">'
    tiles += f'<img src="{img("goal_star")}" class="abs" style="left:{3*step+4}px;top:{2*step+4}px;width:{cell-8}px">'
    tiles += f'<img src="{img("robot_full")}" class="abs" style="left:{2*step+4}px;top:{3*step+2}px;width:{cell-8}px">'
    tiles += f'<div class="abs" style="left:{2*step+18}px;top:{3*step-14}px;color:#FFB020;font-size:14px">▲</div>'
    w = 6 * step - gap
    def chip(sym, col, small=False, active=False):
        sz = 34 if small else 42
        return f'<div style="width:{sz}px;height:{sz if small else 46}px;border-radius:11px;background:{col};color:#fff;font-weight:900;font-size:{15 if small else 18}px;display:flex;align-items:center;justify-content:center;{"box-shadow:0 0 0 4px #FFD93D;transform:scale(1.1)" if active else ""}">{sym}</div>'
    F, L, R = ("↑", "#34C77B"), ("↰", "#4D96FF"), ("↱", "#FF7A59")
    loop = (f'<div style="display:flex;align-items:center;gap:5px;padding:3px 6px;border-radius:14px;background:#FFF4C2;box-shadow:inset 0 0 0 4px #FFD93D">'
            f'<div style="width:42px;text-align:center"><img src="{img("icon_loop")}" style="width:22px"><div style="font-weight:900;font-size:14px">×3</div></div>'
            + chip(*F, small=True) + chip(*L, small=True, active=True) + chip(*F, small=True) + chip(*R, small=True)
            + '<div style="color:rgba(43,27,61,.35);font-size:16px">✕</div></div>')
    pal = "".join(f'<div style="flex:1;height:60px;border-radius:16px;background:{c};box-shadow:0 5px 0 {c}99;color:#fff;text-align:center;font-weight:900;padding-top:6px"><div style="font-size:22px">{sym}</div><div style="font-size:11px">{t}</div></div>'
                  for sym, c, t in (("↰", "#4D96FF", "Turn left"), ("↑", "#34C77B", "Forward"), ("↱", "#FF7A59", "Turn right")))
    pal += f'<div style="flex:1;height:60px;border-radius:16px;background:#FFD93D;box-shadow:0 5px 0 #E0A800b3;text-align:center;font-weight:900;padding-top:6px"><img src="{img("icon_loop")}" style="width:26px"><div style="font-size:11px">Repeat</div></div>'
    return f"""{BASE}<body style="background:linear-gradient(#E0F2FF,#F3ECFF)">
    <div style="padding:54px 14px 0;display:flex;align-items:center">
      <div style="width:48px;height:48px;border-radius:50%;background:#fff;display:flex;align-items:center;justify-content:center;color:#7C4DFF;font-size:22px">‹</div>
      <div style="flex:1;text-align:center;font-size:24px;font-weight:900">Staircase</div>
      <div style="width:56px;height:48px;border-radius:14px;background:rgba(255,255,255,.9);text-align:center;padding-top:5px"><div style="font-size:17px;font-weight:900;color:#34C77B">5/5</div><div style="font-size:10px;font-weight:700;opacity:.6">blocks</div></div>
    </div>
    <div style="text-align:center;font-size:15px;font-weight:700;opacity:.85;padding:10px 18px;min-height:60px">See a pattern? Forward, turn left, forward, turn right... and again! Put the whole pattern inside one Repeat block.</div>
    <div style="margin:0 auto;width:{w + 18}px;padding:9px;border-radius:22px;background:#C9B8F5;box-shadow:0 6px 0 #9B86E0"><div style="position:relative;width:{w}px;height:{w}px">{tiles}</div></div>
    <div style="margin:14px 14px 0;height:70px;border-radius:18px;background:rgba(255,255,255,.85);display:flex;align-items:center;padding:0 12px">{loop}</div>
    <div style="margin:12px 14px 0;display:flex;gap:8px">{pal}</div>
    <div style="margin:16px 22px 0;display:flex;gap:12px">
      <div style="flex:1;height:62px;border-radius:22px;background:#9AA0AE;box-shadow:0 6px 0 #9AA0AE73;color:#fff;font-size:22px;font-weight:900;display:flex;align-items:center;justify-content:center">Clear</div>
      <div style="flex:1;height:62px;border-radius:22px;background:#34C77B;box-shadow:0 6px 0 #34C77B73;color:#fff;font-size:22px;font-weight:900;display:flex;align-items:center;justify-content:center">Running…</div>
    </div>
    {STATUS}</body>"""


SCREENS = {"world-map": world_map, "buddy-picker": buddy_picker, "brain-gate": brain_gate,
           "robot-lab": robot_lab, "welcome": welcome, "balloon-flight": balloon_flight,
           "pillow-bop": bop_arena, "sticker-book": sticker_book,
           "fort-friends": fort_friends, "code-club": code_club}

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
