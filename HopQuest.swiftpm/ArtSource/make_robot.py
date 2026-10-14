"""Robot Lab art for HopQuest, in the same ink-outline chibi style as the characters.

Robot layers share one 400x440 canvas so they stack perfectly in the app:
  robot_ghost, robot_wheels, robot_chassis, robot_motors, robot_battery, robot_sensors, robot_brain, robot_smile
Plus robot_gear (spinning motor gear), part icons (part_<name>) and goal_star.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_characters import OUT, E, C, P, R, shine, star_path, dark, light  # noqa: E402

BODY = "#8FD3F4"
BODY_DK = "#6CB8E0"
VISOR = "#2B3A67"
PURPLE = "#7C4DFF"
YELLOW = "#FFD93D"
GREEN = "#34C77B"
PINK = "#FF7FC4"
CYAN = "#5EE6FF"
TIRE = "#3A3D47"

GEARS = [(112, 326), (288, 326)]
ANTENNA_TIP = (200, 14)


# ------------------------------------------------------------------ robot layers

def wheels():
    s = E(200, 418, 120, 13, "#000000", False, op=0.18)
    s += R(136, 372, 128, 14, 7, "#5A5F6E")
    for x in (136, 264):
        s += C(x, 384, 42, TIRE)
        s += C(x, 384, 31, "#555A69", False)
        for i in range(8):
            import math
            a = i * math.pi / 4
            s += C(x + 37 * math.cos(a), 384 + 37 * math.sin(a), 3.5, "#23252C", False)
        s += C(x, 384, 18, YELLOW, 5) + C(x, 384, 6, OUT, False)
        s += shine(x - 16, 366, 9, 5)
    return s


def chassis():
    s = ""
    # waving right arm (behind body)
    s += P("M276 262 Q318 236 324 196", "none", 30) + P("M276 262 Q318 236 324 196", "none", 0)
    s += f'<path d="M276 262 Q318 236 324 196" fill="none" stroke="{OUT}" stroke-width="30" stroke-linecap="round"/>'
    s += f'<path d="M276 262 Q318 236 324 196" fill="none" stroke="{BODY_DK}" stroke-width="18" stroke-linecap="round"/>'
    s += C(326, 186, 16, BODY) + P("M318 172 L326 160 M334 172 L342 164", "none", 5)
    # left arm resting
    s += f'<path d="M124 262 Q90 290 94 322" fill="none" stroke="{OUT}" stroke-width="30" stroke-linecap="round"/>'
    s += f'<path d="M124 262 Q90 290 94 322" fill="none" stroke="{BODY_DK}" stroke-width="18" stroke-linecap="round"/>'
    s += C(94, 330, 16, BODY)
    # neck + body
    s += R(178, 192, 44, 34, 8, BODY_DK)
    s += R(110, 218, 180, 152, 40, BODY)
    s += shine(146, 240, 22, 10)
    s += R(155, 250, 90, 66, 16, VISOR, 5)          # chest slot (battery goes here)
    s += P("M130 338 L270 338", "none", 4, op=0.35)
    for x in (134, 266):
        s += C(x, 238, 5, BODY_DK, 3)
    # head
    s += C(104, 144, 15, BODY_DK) + C(296, 144, 15, BODY_DK)
    s += R(108, 80, 184, 126, 50, BODY)
    s += shine(146, 102, 26, 11)
    s += R(132, 106, 136, 76, 32, VISOR, 5)          # visor (eyes go here)
    s += E(150, 120, 14, 6, "#FFFFFF", False, rot=-20, op=0.25)
    return s


def motors():
    s = ""
    for (x, y) in GEARS:
        s += R(x - 26, y - 30, 52, 60, 14, PURPLE)
        s += shine(x - 12, y - 18, 8, 5)
        s += C(x, y, 24, dark(PURPLE, 0.25), 4)
    # wires to the battery slot
    s += P("M138 322 Q160 330 168 312", "none", 4) + P("M262 322 Q240 330 232 312", "none", 4)
    return s


def gear(cx=50, cy=50, r=24, teeth=8, color=YELLOW):
    import math
    pts = []
    for i in range(teeth * 2):
        a = i * math.pi / teeth
        rr = r if i % 2 == 0 else r * 0.74
        a1, a2 = a - math.pi / teeth * 0.45, a + math.pi / teeth * 0.45
        pts.append(f"{cx + rr * math.cos(a1):.1f} {cy + rr * math.sin(a1):.1f}")
        pts.append(f"{cx + rr * math.cos(a2):.1f} {cy + rr * math.sin(a2):.1f}")
    return P("M" + " L".join(pts) + " Z", color, 4) + C(cx, cy, r * 0.32, OUT, False) + C(cx, cy, r * 0.14, "#FFFFFF", False)


def battery():
    s = R(166, 262, 60, 42, 9, GREEN, 5)
    s += R(226, 274, 9, 18, 3, dark(GREEN, 0.2), 4)
    s += shine(182, 270, 12, 4, rot=0, op=0.45)
    s += P("M200 268 L188 286 L200 286 L194 300 L212 280 L200 280 L206 268 Z", YELLOW, 3)
    # glowing charge dots under the slot
    for i, x in enumerate((176, 200, 224)):
        s += C(x, 309, 4, CYAN, False)
    return s


def sensors():
    s = ""
    # sonar ear dishes
    for x, sgn in ((96, -1), (304, 1)):
        s += E(x, 144, 11, 24, YELLOW, 4)
        s += P(f"M{x + sgn * 4} 132 Q{x + sgn * 10} 144 {x + sgn * 4} 156", "none", 3, op=0.5)
    # camera eyes on the visor
    for x in (168, 232):
        s += E(x, 144, 19, 23, CYAN, 4)
        s += E(x, 147, 9, 11, VISOR, False)
        s += C(x - 6, 136, 6, "#FFFFFF", False) + C(x + 5, 152, 3, "#FFFFFF", False)
    return s


def brain():
    s = ""
    s += P(f"M200 44 L200 {ANTENNA_TIP[1] + 8}", "none", 6)
    s += C(ANTENNA_TIP[0], ANTENNA_TIP[1], 11, PINK)
    s += shine(196, 10, 4, 2.5, rot=0, op=0.7)
    # glass dome on top of the head
    s += P("M156 86 A44 44 0 0 1 244 86 Z", "#D9F3FF", 5, op=0.9)
    s += R(174, 52, 52, 34, 7, PURPLE, 4)
    for x in range(180, 224, 9):
        s += R(x, 46, 4, 8, 1, YELLOW, False) + R(x, 84, 4, 6, 1, YELLOW, False)
    s += P("M184 62 L198 62 L198 74 L214 74 M206 58 L206 66 L218 66", "none", 3)
    s += P("M184 62 L198 62 L198 74 L214 74 M206 58 L206 66 L218 66", "none", 0)
    s += f'<path d="M184 62 L198 62 L198 74 L214 74 M206 58 L206 66 L218 66" fill="none" stroke="{PINK}" stroke-width="3" stroke-linecap="round"/>'
    s += P("M166 70 Q172 56 186 52", "none", 4, op=0)
    s += f'<path d="M166 72 Q170 58 184 52" fill="none" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" opacity="0.7"/>'
    return s


def smile():
    return f'<path d="M180 166 Q200 182 220 166" fill="none" stroke="{CYAN}" stroke-width="6" stroke-linecap="round"/>'


def ghost():
    dash = 'fill="#FFFFFF" fill-opacity="0.35" stroke="#A99BE0" stroke-width="4" stroke-dasharray="10 8" stroke-linecap="round" stroke-linejoin="round"'
    s = f'<rect x="108" y="80" width="184" height="126" rx="50" {dash}/>'
    s += f'<rect x="110" y="218" width="180" height="152" rx="40" {dash}/>'
    s += f'<rect x="155" y="250" width="90" height="66" rx="16" {dash}/>'
    s += f'<path d="M156 86 A44 44 0 0 1 244 86 Z" {dash}/>'
    for (x, y) in GEARS:
        s += f'<rect x="{x - 26}" y="{y - 30}" width="52" height="60" rx="14" {dash}/>'
    for x in (136, 264):
        s += f'<circle cx="{x}" cy="384" r="42" {dash}/>'
    for x in (168, 232):
        s += f'<ellipse cx="{x}" cy="144" rx="19" ry="23" {dash}/>'
    return s


LAYERS = {"robot_ghost": ghost, "robot_wheels": wheels, "robot_chassis": chassis, "robot_motors": motors,
          "robot_battery": battery, "robot_sensors": sensors, "robot_brain": brain, "robot_smile": smile}


def layer_svg(fn):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="-10 -10 420 460" width="420" height="460">{fn()}</svg>'


# ------------------------------------------------------------------ icons (200 x 200)

def icon_svg(content, box):
    """Fit the robot-space bounding box (x0, y0, x1, y1) into a 200x200 icon."""
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    k = 168 / max(w, h)
    tx = 100 - (x0 + w / 2) * k
    ty = 100 - (y0 + h / 2) * k
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="200" height="200">'
            f'<g transform="translate({tx:.1f} {ty:.1f}) scale({k:.3f})">{content}</g></svg>')


def icon_chassis():
    return icon_svg(chassis(), (76, 76, 346, 374))


def icon_battery():
    return icon_svg(battery().replace(f'<circle', '<circle opacity="0"', 0), (158, 254, 242, 316))


def icon_motors():
    x, y = 200, 200
    s = R(x - 34, y - 40, 68, 80, 16, PURPLE) + shine(x - 16, y - 24, 10, 6)
    s += gear(x, y, 30)
    s += P(f"M{x - 34} {y + 24} Q{x - 60} {y + 30} {x - 66} {y + 50}", "none", 5)
    s += P(f"M{x + 34} {y + 24} Q{x + 60} {y + 30} {x + 66} {y + 50}", "none", 5)
    return icon_svg(s, (124, 150, 276, 260))


def icon_wheels():
    import math
    s = ""
    for x, y, r in ((236, 186, 34), (176, 206, 44)):
        s += C(x, y, r, TIRE) + C(x, y, r * 0.74, "#555A69", False)
        for i in range(8):
            a = i * math.pi / 4
            s += C(x + r * 0.88 * math.cos(a), y + r * 0.88 * math.sin(a), 3.5, "#23252C", False)
        s += C(x, y, r * 0.43, YELLOW, 5) + C(x, y, r * 0.14, OUT, False) + shine(x - r * 0.4, y - r * 0.45, r * 0.22, r * 0.12)
    return icon_svg(s, (124, 144, 276, 256))


def icon_sensors():
    s = R(120, 112, 160, 70, 30, VISOR, 5) + sensors()
    return icon_svg(s, (80, 112, 320, 182))


def icon_brain():
    return icon_svg(brain(), (150, 0, 250, 92))


def goal_star():
    s = P(star_path(100, 104, 88, 0.5), YELLOW, 6)
    s += P(star_path(100, 104, 60, 0.5), "#FFE98A", False)
    s += E(84, 98, 7, 9, OUT, False) + E(116, 98, 7, 9, OUT, False)
    s += C(81, 94, 3, "#FFFFFF", False) + C(113, 94, 3, "#FFFFFF", False)
    s += E(72, 116, 9, 5, "#FF9EBB", False, op=0.7) + E(128, 116, 9, 5, "#FF9EBB", False, op=0.7)
    s += P("M90 116 Q100 126 110 116", "none", 4)
    s += shine(70, 64, 10, 6)
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="200" height="200">{s}</svg>'


def gear_svg():
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">{gear(50, 50, 44)}</svg>'


ICONS = {"part_chassis": icon_chassis, "part_battery": icon_battery, "part_motors": icon_motors,
         "part_wheels": icon_wheels, "part_sensors": icon_sensors, "part_brain": icon_brain}


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for name, fn in LAYERS.items():
        open(os.path.join(out, f"{name}.svg"), "w").write(layer_svg(fn))
    for name, fn in ICONS.items():
        open(os.path.join(out, f"{name}.svg"), "w").write(fn())
    open(os.path.join(out, "goal_star.svg"), "w").write(goal_star())
    open(os.path.join(out, "robot_gear.svg"), "w").write(gear_svg())
    print("ok")
