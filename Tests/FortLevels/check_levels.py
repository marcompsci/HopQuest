"""Replays a reference solution for every Fort Friends level against the level maps in FortScene.swift.

The rules mirror FortScene (walking, ramps, falling, building within 3 squares, supports, crates, Brain crates,
helper bricks). It proves each level can be finished with every balloon, and reports how many bricks the
reference route needs compared with what the level gives (so levels stay a fair budgeting puzzle).
Run: python3 Tests/FortLevels/check_levels.py
"""
import os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
PKG = os.environ.get('PKG', os.path.join(HERE, '..', '..', 'HopQuest.swiftpm'))
SRC = open(os.path.join(PKG, 'Scenes', 'FortScene.swift')).read()

def parse_levels():
    levels = {}
    for m in re.finditer(r'FortLevel\(id: (\d+), title: "([^"]+)".*?startBricks: (\d+).*?rows: \[(.*?)\]\)', SRC, re.S):
        rows = re.findall(r'"([^"]*)"', m.group(4))
        levels[int(m.group(1))] = dict(title=m.group(2), bricks=int(m.group(3)), rows=rows)
    return levels

COST = {'ramp': 2, 'block': 1, 'bridge': 1}

class Sim:
    def __init__(self, lv):
        self.rows = lv['rows']; self.R = len(self.rows); self.C = max(len(r) for r in self.rows)
        self.t = {}; self.items = {}; self.crates = 0
        for ri, line in enumerate(self.rows):
            y = self.R - 1 - ri
            for x, ch in enumerate(line):
                if ch == '#': self.t[(x, y)] = 'ground'
                elif ch == '~': self.t[(x, y)] = 'water'
                elif ch == 'S': self.p = (x, y)
                elif ch == 'B': self.items[(x, y)] = 'balloon'
                elif ch == 'C': self.items[(x, y)] = 'crate'; self.crates += 1
                elif ch == 'G': self.items[(x, y)] = 'gold'
                elif ch == 'F': self.items[(x, y)] = 'fort'
        self.bricks = lv['bricks']; self.spent = 0; self.helper = 0
        self.balloons = 0; self.total = sum(1 for v in self.items.values() if v == 'balloon')
        self.facing = 1; self.safe = self.p; self.done = False; self.log = []

    def tile(self, x, y):
        if x < 0 or x >= self.C: return 'ground'
        if y < 0: return 'water'
        if y >= self.R: return 'empty'
        return self.t.get((x, y), 'empty')

    def solid(self, x, y):
        return self.tile(x, y) in ('ground', 'block', 'bridge') or self.tile(x, y).startswith('ramp')

    def collect(self, c):
        it = self.items.get(c)
        if it == 'balloon': del self.items[c]; self.balloons += 1
        elif it == 'crate': del self.items[c]; self.crates -= 1; self.bricks += 4
        elif it == 'gold': del self.items[c]; self.bricks += 5   # the smaller gift (not first try)

    def landing(self, x, y):
        while y > 0:
            if self.solid(x, y - 1): return (x, y)
            if self.tile(x, y - 1) == 'water': return None
            y -= 1
        return None

    def step(self, d):
        self.facing = d
        x, y = self.p; nx = x + d
        ahead = self.tile(nx, y)
        if ahead == f'ramp{d}' and not self.solid(nx, y + 1) and 0 <= nx < self.C:
            self.move((nx, y + 1)); return True
        if nx < 0 or nx >= self.C or self.solid(nx, y):
            return False
        self.move((nx, y)); return True

    def move(self, c):
        self.p = c; self.collect(c)
        x, y = c
        if not self.solid(x, y - 1):
            land = self.landing(x, y)
            if land is None:
                self.p = self.safe; self.log.append('splash'); return
            for yy in range(y - 1, land[1] - 1, -1): self.collect((x, yy))
            self.p = land
        self.safe = self.p
        if self.items.get(self.p) == 'fort': self.done = True

    def can_place(self, tool, c):
        x, y = c; px, py = self.p
        if not (0 <= x < self.C and 1 <= y < self.R): return False
        if abs(x - px) > 3 or abs(y - py) > 3: return False
        here = self.tile(x, y)
        if tool == 'take':
            return here in ('block', 'bridge') or here.startswith('ramp') and not (x == px and y == py - 1)
        if here not in ('empty', 'water'): return False
        if c in self.items or c == self.p: return False
        return self.solid(x, y - 1) or (self.solid(x - 1, y) and x - 1 >= 0) or (self.solid(x + 1, y) and x + 1 < self.C)

    def build(self, tool, x, y):
        c = (x, y)
        if not self.can_place(tool, c):
            raise AssertionError(f'cannot {tool} at {c} from {self.p} (tile {self.tile(x, y)})')
        if tool == 'take':
            here = self.tile(x, y)
            refund = 2 if here.startswith('ramp') else 1
            orig = self.rows[self.R - 1 - y][x] if x < len(self.rows[self.R - 1 - y]) else '.'
            self.t[c] = 'water' if (y == 1 and orig == '~') else 'empty'
            self.bricks += refund; return
        cost = COST[tool]
        while self.bricks < cost:
            assert self.crates == 0, f'out of bricks at {c} with crates still on the map'
            self.bricks += 6; self.helper += 6
        self.bricks -= cost; self.spent += cost
        self.t[c] = f'ramp{self.facing}' if tool == 'ramp' else tool

    def run(self, route):
        for cmd in route.split(';'):
            cmd = cmd.strip()
            if not cmd: continue
            parts = cmd.split()
            if parts[0] in ('R', 'L'):
                d = 1 if parts[0] == 'R' else -1
                n = int(parts[1]) if len(parts) > 1 else 1
                for _ in range(n):
                    if self.done: break
                    if not self.step(d): raise AssertionError(f'bumped walking {parts[0]} at {self.p}')
            elif parts[0] == 'face':
                self.facing = 1 if parts[1] == 'R' else -1
            else:
                self.build(parts[0], int(parts[1]), int(parts[2]))
            if self.done: break

# Reference routes. Coordinates: x from the left (0), y from the bottom (0 = the sea row).
ROUTES = {
    301: "R 3; ramp 4 2; block 5 2; ramp 5 3; R 6; bridge 10 1; bridge 11 1; bridge 12 1; R 1; bridge 13 1; R 6;"
         "ramp 17 2; R 2; ramp 19 2; block 20 2; ramp 20 3; R 9",
    # Lily Lagoon: the smart way takes each bridge back after crossing
    304: "R 5; bridge 6 1; bridge 7 1; R 3; take 6 1; take 7 1; R 4; bridge 13 1; bridge 14 1; bridge 15 1; R 4;"
         "take 13 1; take 14 1; take 15 1; R 4; bridge 21 1; bridge 22 1; bridge 23 1; R 3; bridge 24 1; R 6",
    # Treetop Towers: a staircase to each tree top, taking old stairs back when they're in reach
    305: "R 3; ramp 5 2; block 6 2; ramp 6 3; R 5; take 6 3; take 6 2; take 5 2; R 2;"
         "ramp 11 2; block 12 2; ramp 12 3; block 13 2; block 13 3; ramp 13 4; R 5;"
         "take 13 4; take 13 3; take 13 2; take 12 3; take 12 2; R 1;"
         "ramp 17 2; block 18 2; ramp 18 3; block 19 2; block 19 3; ramp 19 4; R 3;"
         "block 20 2; block 20 3; block 20 4; ramp 20 5; R 3; R 6",
    # Moat Castle: up the little hill, across the moat (taking the bridge back), then up the castle wall
    306: "R 6; ramp 7 2; block 8 2; ramp 8 3; R 5; bridge 12 1; bridge 13 1; bridge 14 1; R 2; bridge 15 1; bridge 16 1; R 4;"
         "take 14 1; take 15 1; take 16 1; R 1; ramp 19 2; block 20 2; ramp 20 3; block 21 2; block 21 3; ramp 21 4; R 3; R 6",
}

def main():
    levels = parse_levels()
    ok = True
    for lid in sorted(levels):
        lv = levels[lid]
        widths = {len(r) for r in lv['rows']}
        if len(widths) != 1:
            print(f'FAIL {lid} {lv["title"]}: rows have different widths {widths}'); ok = False; continue
        route = ROUTES.get(lid)
        if route is None:
            print(f'skip {lid} {lv["title"]}: no reference route yet'); continue
        s = Sim(lv)
        try:
            s.run(route)
        except AssertionError as e:
            print(f'FAIL {lid} {lv["title"]}: {e}'); ok = False; continue
        if not s.done or s.balloons < s.total:
            print(f'FAIL {lid} {lv["title"]}: finished={s.done} balloons {s.balloons}/{s.total} at {s.p}'); ok = False; continue
        print(f'ok   {lid} {lv["title"]}: all {s.total} balloons and the fort; route spent {s.spent} bricks '
              f'(level gives {lv["bricks"]} + crates), helper bricks needed: {s.helper}')
    sys.exit(0 if ok else 1)

if __name__ == '__main__':
    main()
