"""Hop Village layout. Writes the ASCII map that VillageMapData.swift ships with.
Row 0 is the NORTH edge. Legend (also documented in VillageMap.swift):
  .  grass            =  stone path        ~  water (blocked)    o  lily pad (walkable, over water)
  #  wooden bridge    r  road              z  crosswalk          s  sand / dirt
  *  flowers (walk)   T  tree (blocked)    t  bush (blocked)     F  fence (blocked)
  B  bench (blocked)  L  lamp (blocked)    c  parked car         n  traffic sign
  k  crane            b  block pile        m  mushroom (walk)    R  rock (blocked)
  1 2 3  portals to Hop chapters 1, 4, 6
  building footprints: C castle, M museum, A arena, W workshop, D academy, K kart stadium, Y fort shed, Q fountain
"""
import random
W, H = 40, 48
g = [['.'] * W for _ in range(H)]
def put(c, r, ch):
    if 0 <= c < W and 0 <= r < H: g[r][c] = ch
def rect(c0, r0, c1, r1, ch):
    for r in range(r0, r1 + 1):
        for c in range(c0, c1 + 1): put(c, r, ch)
def hline(r, c0, c1, ch='='): rect(min(c0, c1), r, max(c0, c1), r, ch)
def vline(c, r0, r1, ch='='): rect(c, min(r0, r1), c, max(r0, r1), ch)

# --- border of trees
for c in range(W):
    put(c, 0, 'T'); put(c, 1, 'T' if c % 3 else 't'); put(c, H - 1, 'T'); put(c, H - 2, 'T')
for r in range(H):
    put(0, r, 'T'); put(1, r, 'T' if r % 4 else 't'); put(W - 1, r, 'T'); put(W - 2, r, 'T' if r % 3 else 't')

# --- main avenues (2 wide)
vline(19, 9, 36); vline(20, 9, 36)
hline(12, 6, 33); hline(13, 6, 33)          # north road past castle
hline(24, 5, 34); hline(25, 5, 34)          # south road
# village square ring around the fountain
rect(15, 15, 24, 22, '=')
rect(18, 17, 21, 20, 'Q')                   # fountain 4x4
# benches, lamps, flowers around the square
for (c, r) in [(16, 16), (23, 16), (16, 21), (23, 21)]: put(c, r, '*')
put(14, 16, 'B'); put(25, 16, 'B'); put(14, 21, 'B'); put(25, 21, 'B')
put(14, 18, 'L'); put(25, 18, 'L'); put(17, 23, 'L'); put(22, 23, 'L')

# --- My Castle (north, centered)
rect(16, 3, 23, 8, 'C')                     # 8 wide, door at cols 19-20 bottom row 8
vline(19, 9, 11); vline(20, 9, 11)
for c in range(12, 16): put(c, 9, '*')
for c in range(24, 28): put(c, 9, '*')
put(14, 7, 't'); put(25, 7, 't')

# --- Sticker Book Museum (NW)
rect(4, 4, 9, 8, 'M'); vline(7, 9, 11)
put(3, 9, '*'); put(10, 9, '*'); put(11, 5, 'T')

# --- Pillow Bop Arena on a little lake island (NE)
rect(28, 2, 37, 10, '~')
rect(30, 3, 35, 7, 'A')                     # arena 6x5 on the island
rect(29, 8, 36, 8, 's')                     # island beach in front
put(29, 3, 's'); put(36, 3, 's')
vline(32, 9, 11, '#'); vline(33, 9, 11, '#')   # bridge to the north road
put(32, 8, '='); put(33, 8, '=')

# --- Robot Workshop (W)
rect(3, 16, 9, 20, 'W'); vline(6, 21, 23); hline(14, 6, 6)
vline(6, 13, 15); put(10, 17, 'b'); put(10, 19, 'R'); put(2+1, 22, 'R')

# --- Driving Academy (E) with a practice road
rect(30, 15, 36, 19, 'D'); vline(33, 20, 23)
rect(26, 20, 37, 21, 'r')                   # practice road in front of the academy
put(33, 20, 'z'); put(33, 21, 'z'); put(32, 20, 'z'); put(32, 21, 'z')
put(28, 20, 'c'); put(36, 21, 'c'); put(29, 19, 'n'); put(37, 19, 'n')
hline(22, 33, 33); put(26, 19, 'L')
# connect square to the road
hline(18, 25, 29)

# --- Fort Friends Construction Yard (SW)
rect(3, 27, 13, 33, 's')
rect(4, 28, 8, 30, 'Y'); vline(6, 31, 33, 's')
put(10, 28, 'k'); put(11, 31, 'b'); put(12, 29, 'b'); put(9, 32, 'b')
for c in range(3, 14): put(c, 34, 'F')
put(8, 34, 's'); put(9, 34, 's')            # yard gate
for r in range(27, 34): put(14, r, 'F')
put(14, 30, 's'); put(14, 31, 's')          # side gate toward the avenue
hline(30, 15, 18); hline(31, 15, 18)
vline(8, 26, 26, 's'); vline(8, 26, 25)

# --- Bubble Kart Stadium (SE)
rect(28, 27, 36, 32, 'K'); vline(27, 26, 33); hline(33, 27, 32)
put(27, 33, '*'); put(37, 33, '*')

# --- Adventure Forest (south)
random.seed(7)
for r in range(35, H - 2):
    for c in range(2, W - 2):
        if g[r][c] == '.' and random.random() < 0.30:
            g[r][c] = 'T' if random.random() < 0.75 else 't'
# forest trails (clear trees)
def trail(points):
    for (a, b) in zip(points, points[1:]):
        (c0, r0), (c1, r1) = a, b
        for c in range(min(c0, c1), max(c0, c1) + 1):
            for rr in (r0,):
                g[rr][c] = '=' if g[rr][c] in '.Tt*' else g[rr][c]
                if rr + 1 < H - 2 and g[rr + 1][c] in 'Tt': g[rr + 1][c] = '.'
        for r in range(min(r0, r1), max(r0, r1) + 1):
            g[r][c1] = '=' if g[r][c1] in '.Tt*' else g[r][c1]
            if c1 + 1 < W - 2 and g[r][c1 + 1] in 'Tt': g[r][c1 + 1] = '.'
trail([(19, 35), (19, 37), (8, 37), (8, 41)])            # west branch → portal 1
trail([(20, 35), (20, 37), (32, 37), (32, 41)])          # east branch → portal 3
# pond with lily pads and a bridge
rect(14, 39, 26, 43, '~')
rect(15, 38, 25, 38, '~'); rect(15, 44, 25, 44, '~')
vline(19, 38, 44, '#'); vline(20, 38, 41, '#')
for c in (21, 23, 25): put(c, 42, 'o')
put(22, 43, 'o'); put(24, 41, 'o')
vline(19, 37, 37); vline(20, 37, 37)
rect(18, 45, 21, 45, '='); 
# clear around portals
for (c, r, ch) in [(8, 42, '1'), (20, 45, '2'), (32, 42, '3')]:
    rect(c - 1, r - 1, c + 1, r + 1, '.')
    put(c, r, ch)
put(8, 41, '='); put(32, 41, '='); put(19, 45, '='); put(21, 45, '='); put(20, 44, '#')
# some mushrooms & flowers in clearings
for (c, r) in [(7, 43), (9, 43), (31, 43), (33, 43), (18, 46), (22, 46)]:
    if g[r][c] == '.': g[r][c] = 'm'
# meadow flowers sprinkled in grass (walkable)
random.seed(3)
for r in range(2, 34):
    for c in range(2, W - 2):
        if g[r][c] == '.' and random.random() < 0.05: g[r][c] = '*'

rows = [''.join(r) for r in g]
assert all(len(r) == W for r in rows)
if __name__ == '__main__':
    print('\n'.join(rows))
