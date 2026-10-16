"""Hop Village layout (v2: a building for every game). Writes the ASCII map that VillageMapData.swift ships with.
Row 0 is the NORTH edge. Legend (also documented in VillageMap.swift):
  .  grass            =  stone path        ~  water (blocked)    o  lily pad (walkable, over water)
  #  wooden bridge    r  road              z  crosswalk          s  sand / dirt
  *  flowers (walk)   T  tree (blocked)    t  bush (blocked)     F  fence (blocked)
  B  bench (blocked)  L  lamp (blocked)    c  parked car         n  traffic sign
  k  crane            b  block pile        m  mushroom (walk)    R  rock (blocked)
  building footprints (doors face south, centered):
    C castle   M sticker museum   A pillow bop arena   W robot lab   D driving school   X city rally garage
    K kart stadium   Y fort friends shed   U together clubhouse   G meadow street cottage
    V lily river boathouse   H castle hill tower   Q fountain
"""
import random
W, H = 44, 54
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

# --- roads: north road, main avenue, south avenue, forest trail
hline(12, 6, 37); hline(13, 6, 37)
vline(21, 9, 41); vline(22, 9, 41)
hline(28, 5, 39); hline(29, 5, 39)
hline(41, 7, 36); hline(42, 7, 36)

# --- Village Square (Brain Duel plaza) with the fountain
rect(16, 15, 27, 24, '=')
rect(20, 18, 23, 21, 'Q')
for (c, r) in [(17, 16), (26, 16), (17, 23), (26, 23)]: put(c, r, '*')
put(15, 16, 'B'); put(28, 16, 'B'); put(15, 23, 'B'); put(28, 23, 'B')
put(15, 19, 'L'); put(28, 19, 'L'); put(19, 25, 'L'); put(24, 25, 'L')

# --- My Castle (north center): opens after every challenge is done
rect(18, 3, 25, 8, 'C')
vline(21, 9, 11); vline(22, 9, 11)
for c in range(13, 18): put(c, 9, '*')
for c in range(26, 31): put(c, 9, '*')
put(16, 7, 't'); put(27, 7, 't')

# --- Sticker Book Museum (NW)
rect(4, 4, 9, 8, 'M'); vline(7, 9, 11)
put(3, 9, '*'); put(10, 9, '*'); put(12, 5, 'T')

# --- Pillow Bop Arena on a lake island (NE)
rect(31, 2, 41, 10, '~')
rect(33, 3, 38, 7, 'A')
rect(32, 8, 39, 8, 's')
put(32, 3, 's'); put(39, 3, 's')
vline(35, 9, 11, '#'); vline(36, 9, 11, '#')
put(35, 8, '='); put(36, 8, '=')

# --- Coding Lab (W side, south of the Robot Lab)
rect(8, 23, 13, 26, 'P'); hline(27, 6, 11)

# --- Robot Lab (W)
rect(3, 16, 9, 20, 'W'); vline(6, 21, 27); vline(6, 14, 15)
put(11, 17, 'b'); put(11, 19, 'R'); put(3, 23, 'R')

# --- Driving School (E) on a practice road, City Rally garage south of it
rect(33, 14, 39, 18, 'D')
rect(29, 19, 41, 20, 'r')
put(35, 19, 'z'); put(36, 19, 'z'); put(35, 20, 'z'); put(36, 20, 'z')
put(31, 19, 'c'); put(40, 20, 'c'); put(32, 18, 'n'); put(40, 18, 'n')
hline(18, 28, 31)                                  # square → road
rect(33, 22, 39, 26, 'X')                          # City Rally garage
vline(36, 21, 21)                                  # road → around the garage
vline(32, 21, 27); vline(36, 27, 27)               # path down the west side to the doorstep / avenue
put(30, 21, 'L')

# --- Fort Friends Construction Yard (SW)
rect(3, 31, 14, 37, 's')
rect(4, 32, 8, 34, 'Y'); vline(6, 35, 37, 's')
put(11, 32, 'k'); put(12, 35, 'b'); put(13, 33, 'b'); put(10, 36, 'b')
for c in range(3, 15): put(c, 38, 'F')
for r in range(31, 38): put(15, r, 'F')
put(15, 34, 's'); put(15, 35, 's')                 # side gate toward the avenue
hline(34, 16, 20); hline(35, 16, 20)
vline(8, 30, 30, 's'); vline(8, 29, 29)

# --- Together Clubhouse (center south, east of the avenue)
rect(25, 31, 30, 34, 'U'); vline(28, 35, 36); hline(36, 23, 28)
put(24, 32, '*'); put(31, 32, '*')

# --- Bubble Kart Stadium (SE)
rect(33, 31, 41, 36, 'K'); vline(32, 30, 37); hline(37, 32, 37)

# --- Adventure Forest (south): three hop-adventure buildings and a lily pond
random.seed(7)
for r in range(39, H - 2):
    for c in range(2, W - 2):
        if g[r][c] == '.' and random.random() < 0.30:
            g[r][c] = 'T' if random.random() < 0.75 else 't'
hline(41, 7, 36); hline(42, 7, 36)                 # re-carve the trail through the trees
for c in range(7, 37):
    if g[40][c] in 'Tt': g[40][c] = '.'
    if g[43][c] in 'Tt': g[43][c] = '.'
# Meadow Street cottage (west)
rect(4, 45, 9, 48, '.'); rect(5, 45, 9, 48, 'G'); vline(7, 43, 44); vline(7, 49, 49)
# Lily River boathouse (center-west, on the pond shore) and the pond
rect(18, 44, 31, 50, '~'); rect(19, 51, 30, 51, '~')
rect(11, 45, 15, 48, 'V'); vline(13, 43, 44); vline(13, 49, 49)
rect(10, 44, 16, 44, '.'); rect(10, 49, 17, 50, '.')
hline(49, 14, 17)
for c in (18, 20, 22, 24, 26, 28): put(c, 49, 'o')   # lily pads one hop apart (the Hop button jumps the gaps)
vline(28, 43, 47, '#'); put(28, 48, 'o')           # a little jetty out over the pond
# Castle Hill tower (east)
rect(33, 44, 39, 49, '.'); rect(34, 45, 38, 48, 'H'); vline(36, 43, 44); vline(36, 49, 49)
# mushrooms in the clearings
for (c, r) in [(4, 49), (10, 50), (33, 50), (39, 50), (25, 43), (16, 43)]:
    if g[r][c] == '.': g[r][c] = 'm'

# meadow flowers sprinkled in grass (walkable)
random.seed(3)
for r in range(2, 38):
    for c in range(2, W - 2):
        if g[r][c] == '.' and random.random() < 0.05: g[r][c] = '*'

rows = [''.join(r) for r in g]
assert all(len(r) == W for r in rows)
if __name__ == '__main__':
    print('\n'.join(rows))
