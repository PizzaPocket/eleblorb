"""The Chinese village's floating islands as the pieces of one broken plateau
(chinese_village.md 4.0). The tool breaks the plateau along jagged fracture lines,
lets the pieces drift apart over the Abyss and turn a little, as land that broke off
would, then checks the islands, the bridges and the land each household needs, and
writes JSON for the 3D model.

    python3 tools/chinese_village_gorge.py [--json out.json]

How the break works:
- the old plateau was a rounded mass about 210 m across;
- the palace stands on its biggest remnant, which broke out whole. The rest of the
  rim shattered round it into a ring of smaller pieces along jagged fracture lines,
  so neighbouring islands' broken edges still roughly match;
- the piece on the north rim, behind the palace, shattered: what is left of it floats as
  bare fragments at their own heights;
- each lived-on piece drifted outward from the palace by its own distance and turned
  by its own small angle, so the gaps and the bridges between them all differ.

The lived-on islands keep the village's one shared surface height, which the NPC, Pandy
and Sun Wu Kong code relies on. The bare fragments float above and below it.

Frame: village-local metres from VILLAGE_CENTER, x east, z south (as scripts/chinese_village.gd).
"""
import json, math, sys
from shapely.geometry import Polygon, Point, MultiPoint, LineString
from shapely.ops import voronoi_diagram
from shapely import affinity

def rad(b): return math.radians(b)
ABYSS_FULL = 170.0             # terrain_generator.gd CHINESE_VILLAGE_ABYSS_RADIUS: full depth inside this
ABYSS_RIM = 225.0              # where the entry bridge lands on ordinary ground (ENTRY_BRIDGE_RIM_DISTANCE)
ABYSS_FLOOR = -345.0           # the Abyss's floor below the village surface (-400 world, the surface about -55)
CHAIN_MAX, CANTILEVER_MAX, ARCH_MAX = 100.0, 38.0, 15.0
ISLAND_GAP = 12.0              # pieces closer than this have not really broken apart
EDGE_CLEAR = 4.0               # lived-on islands stay this far inside the full-depth Abyss

def blob(cx, cz, a, b, n=160, amp=(0.07, 0.05, 0.03), ph=0.4):
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n; k = 1 + amp[0] * math.sin(3 * t + ph) + amp[1] * math.sin(5 * t + 1.9 + ph) + amp[2] * math.sin(11 * t + ph * 2)
        pts.append((cx + a * k * math.cos(t), cz + b * k * math.sin(t)))
    return Polygon(pts)
def warp(x, z, amp=6.5):
    """A fixed noise field: every fracture line passes through it the same way, so the two
    pieces either side of a break share one jagged edge."""
    # long bends in the break, then the smaller teeth of torn rock
    dx = math.sin(x * 0.07 + z * 0.045 + 0.3) * 0.55 + math.sin(x * 0.21 + z * 0.07) * 0.25 + math.sin(x * 0.53 - z * 0.31 + 1.7) * 0.13 + math.sin(z * 0.9 + x * 0.11) * 0.07
    dz = math.sin(z * 0.065 - x * 0.05 + 1.1) * 0.55 + math.sin(z * 0.19 - x * 0.09 + 0.6) * 0.25 + math.sin(z * 0.47 + x * 0.37 + 2.3) * 0.13 + math.sin(x * 0.83 - z * 0.13) * 0.07
    return (x + amp * dx, z + amp * dz)
def jag(poly):
    if poly.geom_type != 'Polygon': poly = max(poly.geoms, key=lambda q: q.area)
    g = poly.segmentize(1.5)
    return Polygon([warp(x, z) for x, z in g.exterior.coords]).buffer(0)

## ---- the plateau and its break
PLATEAU = blob(0, 0, 104, 110)
PALACE_PIECE = blob(-3, -10, 60, 68, amp=(0.05, 0.04, 0.02), ph=1.1)
RING = PLATEAU.difference(PALACE_PIECE)
# where the ring broke: one seed per piece (tuned so each lived-on piece is the land its program needs,
# chinese_village.md 4.1.2, with room to spare); f1 is the north piece that shattered
SEEDS = {'gate': (-12.90, 100.41), 'inn': (-70.62, 72.63), 'roofers': (-100.59, 17.00), 'lantern': (-79.87, -41.73), 'market': (75.21, -58.22), 'fields': (87.20, 9.64), 'bamboo': (15.14, 75.42), 'f1': (-16.45, -86.73)}
NEED = {'palace': 12076, 'gate': 1018, 'inn': 2290, 'market': 2290, 'lantern': 1963, 'roofers': 1521, 'fields': 3632, 'bamboo': 3217}
NAMES = {'palace': 'Palace', 'gate': 'Gate', 'inn': 'E, Inn', 'roofers': 'C, Roofers', 'lantern': 'A, Lantern Row', 'market': 'B, Market',
         'fields': 'D, Fields', 'bamboo': 'Bamboo, Farm'}
vd = voronoi_diagram(MultiPoint(list(SEEDS.values())), envelope=PLATEAU.buffer(300))
PIECES = {'palace': jag(PALACE_PIECE)}
for g in vd.geoms:
    for k, s in SEEDS.items():
        if g.contains(Point(s)): PIECES[k] = jag(g.intersection(RING))
ORIGINAL = dict(PIECES)

## ---- the drift: each piece moves out from the palace along its own heading, by its own distance,
## and turns about its own centre. The palace moved least.
DRIFT = {  # key: (distance m, heading offset deg from straight out, turn deg)
    'palace': (6.0, 200.0, -3.0),
    # the pieces swung a little as they parted, all the same way (about 20 deg), each by its own amount
    'gate': (52.0, -16.0, 14.0), 'inn': (38.0, 8.0, -19.0), 'roofers': (52.0, 22.0, 17.0), 'lantern': (44.0, 24.0, -9.0),
    'market': (44.0, 12.0, 11.0), 'fields': (44.0, 10.0, 12.0), 'bamboo': (36.0, 0.0, 18.0),
}
pc0 = PIECES['palace'].centroid
ISLANDS = {}
for k, (d, off, turn) in DRIFT.items():
    g = PIECES[k]; c = g.centroid
    base = math.degrees(math.atan2(c.y - pc0.y, c.x - pc0.x)) if k != 'palace' else 0.0
    h = rad(base + off)
    g2 = affinity.rotate(g, turn, origin=c)
    ISLANDS[k] = affinity.translate(g2, d * math.cos(h), d * math.sin(h)).buffer(0.8, 4).buffer(-0.8, 4)   # the broken edges have weathered a little
# the north piece shattered along its own cracks; what is left of each shard floats bare at its own height
FRAGMENTS = []
f1 = PIECES['f1']; fc = f1.centroid
SHARDS = [((fc.x - 22, fc.y + 4), 50, -4, 18, 7.0), ((fc.x, fc.y - 6), 58, 4, -22, -11.0), ((fc.x + 24, fc.y + 2), 36, 40, 27, 4.0), ((fc.x + 2, fc.y + 14), 22, -10, 9, -26.0)]
svd = voronoi_diagram(MultiPoint([s_[0] for s_ in SHARDS]), envelope=f1.buffer(100))
for i, (seed, dist, off, turn, dy) in enumerate(SHARDS):
    cell = next(g for g in svd.geoms if g.contains(Point(seed)))
    part = jag(cell.intersection(f1).buffer(0))
    if part.geom_type != 'Polygon': part = max(part.geoms, key=lambda q: q.area)
    part = affinity.scale(part, 0.62, 0.62, origin=part.centroid)          # what is left once the rest crumbled away
    pc = part.centroid; h = rad(math.degrees(math.atan2(pc.y - pc0.y, pc.x - pc0.x)) + off)
    moved = affinity.translate(affinity.rotate(part, turn, origin=pc), dist * math.cos(h), dist * math.sin(h))
    FRAGMENTS.append(dict(key='shard%d' % (i + 1), poly=moved.buffer(0.6, 4).buffer(-0.6, 4), dy=dy))
## ---- bridges (chinese_village.md 4.1.4 and 4.1.5)
BRIDGES = [  # a, b, deck width, use
    ('rim', 'gate', 5.0, 'entry; Bo Xiang to Ohio'), ('gate', 'palace', 5.0, 'processional axis'),
    ('gate', 'inn', 3.2, 'visitors to the inn'), ('gate', 'bamboo', 2.4, 'farm path'),
    ('palace', 'lantern', 3.2, 'garden gate, shut before the quest'), ('palace', 'market', 3.2, 'service: levy, deliveries'),
    ('lantern', 'roofers', 3.2, 'ring'), ('roofers', 'inn', 3.2, 'ring'),
    ('market', 'fields', 3.2, 'ring; produce and night soil'), ('fields', 'bamboo', 3.2, 'ring; the farm pair'),
]

problems = []
# 1. land: every lived-on island holds its program
for k, need in NEED.items():
    if ISLANDS[k].area < need: problems.append((k, 'has %.0f m2, needs %.0f' % (ISLANDS[k].area, need)))
# the palace's plan (chinese_village_palace.md 3: the axis north-south, about 94 x 114 m) fits its piece
pal_c = ISLANDS['palace'].centroid
pal_plan = affinity.translate(blob(0, 0, 44, 55, amp=(0, 0, 0)), pal_c.x, pal_c.y)
if not ISLANDS['palace'].buffer(-2).contains(pal_plan): problems.append(('palace', 'its piece cannot hold the palace plan with the axis north-south'))
# 2. inside the Abyss, and genuinely apart
for k, g in ISLANDS.items():
    reach = max(math.hypot(x, z) for x, z in g.exterior.coords)
    if reach > ABYSS_FULL - EDGE_CLEAR: problems.append((k, 'reaches %.0f m out, past the full-depth Abyss (%.0f)' % (reach, ABYSS_FULL)))
allp = [(k, g) for k, g in ISLANDS.items()] + [(f['key'], f['poly']) for f in FRAGMENTS]
for i in range(len(allp)):
    for j in range(i + 1, len(allp)):
        g = allp[i][1].distance(allp[j][1])
        if g < ISLAND_GAP: problems.append((allp[i][0], allp[j][0], 'only %.1f m apart' % g))
for f in FRAGMENTS:
    if max(math.hypot(x, z) for x, z in f['poly'].exterior.coords) > ABYSS_FULL + 30: problems.append((f['key'], 'drifts out over the rim'))
# 3. bridges: each spans what its type can, and passes over nothing
BR = []
gate_c = ISLANDS['gate'].centroid
RIM_LANDING = (round(gate_c.x * 0.25, 2), ABYSS_RIM)        # the entry lands south of the gate, on ordinary ground
for a, b, w, use in BRIDGES:
    pa = RIM_LANDING if a == 'rim' else (ISLANDS[a].centroid.x, ISLANDS[a].centroid.y); pb = (ISLANDS[b].centroid.x, ISLANDS[b].centroid.y)
    line = LineString([pa, pb])
    def edge(k, other):
        hit = line.intersection(ISLANDS[k].exterior); pts = [hit] if hit.geom_type == 'Point' else list(getattr(hit, 'geoms', []))
        return min(pts, key=lambda q: q.distance(Point(other)))
    A_ = Point(pa) if a == 'rim' else edge(a, pb); B_ = edge(b, pa)
    span = A_.distance(B_)
    kind = 'arch' if span <= ARCH_MAX else 'cantilever' if span <= CANTILEVER_MAX else 'chain'
    if span > CHAIN_MAX: problems.append((a, b, 'spans %.0f m' % span))
    deck = LineString([(A_.x, A_.y), (B_.x, B_.y)]).buffer(w / 2 + 0.5)
    for k, g in allp:
        if k in (a, b): continue
        if deck.intersects(g): problems.append((a, b, 'passes over %s' % k))
    BR.append(dict(a=a, b=b, width=w, use=use, kind=kind, span=round(span, 1), ends=[[round(A_.x, 2), round(A_.y, 2)], [round(B_.x, 2), round(B_.y, 2)]],
                   sag=round(span / 20, 2) if kind == 'chain' else 0))

# ---- today's discs (scripts/chinese_village.gd), for comparison
BUILT = [dict(key=k, c=c, r=r) for k, c, r in [('palace', (0, 0), 62), ('lantern', (-105, -58), 21), ('market', (108, -48), 20), ('bamboo', (18, 116), 25),
                                               ('roofers', (-118, 42), 18), ('fields', (112, 48), 19), ('inn', (-62, 124), 17)]]
BUILT_BRIDGES = [('palace', 'lantern'), ('palace', 'market'), ('palace', 'bamboo'), ('lantern', 'roofers'), ('market', 'fields'), ('roofers', 'inn'), ('inn', 'bamboo')]

for p in problems: print('PROBLEM', p)
def plot_svg(path):
    """A plan for checking by eye: the original plateau dashed, the islands, fragments and bridges."""
    S_ = 1.9; o = []
    o.append('<svg xmlns="http://www.w3.org/2000/svg" viewBox="-240 -240 480 480" width="900" height="900"><rect x="-240" y="-240" width="480" height="480" fill="#d9d4c7"/>')
    o.append('<circle r="%g" fill="#4a4540"/><circle r="%g" fill="none" stroke="#999" stroke-dasharray="3 3"/>' % (ABYSS_FULL, ABYSS_RIM))
    pts = lambda g: ' '.join('%.1f,%.1f' % (x, z) for x, z in (g if isinstance(g, list) else out_poly(g)))
    for k, g in ORIGINAL.items(): o.append('<polygon points="%s" fill="none" stroke="#bbb" stroke-width="0.6" stroke-dasharray="2 2"/>' % pts(g))
    for k, g in ISLANDS.items(): o.append('<polygon points="%s" fill="#7da35a" stroke="#3b3022" stroke-width="0.8"/><text x="%.1f" y="%.1f" font-size="7" text-anchor="middle">%s %d</text>' % (pts(g), g.centroid.x, g.centroid.y, k, g.area))
    for f in FRAGMENTS: o.append('<polygon points="%s" fill="#6a7d55" stroke="#3b3022" stroke-width="0.6"/><text x="%.1f" y="%.1f" font-size="5" text-anchor="middle">%+d</text>' % (pts(f['poly']), f['poly'].centroid.x, f['poly'].centroid.y, f['dy']))
    for b in BR: (a_, b_) = b['ends']; o.append('<line x1="%g" y1="%g" x2="%g" y2="%g" stroke="%s" stroke-width="2"/><text x="%.1f" y="%.1f" font-size="5">%.0f</text>' % (a_[0], a_[1], b_[0], b_[1], '#222' if b['kind'] == 'chain' else '#8a5a32', (a_[0] + b_[0]) / 2, (a_[1] + b_[1]) / 2, b['span']))
    o.append('</svg>'); open(path, 'w').write('\n'.join(o))
def out_poly(p):
    if p.geom_type != 'Polygon': p = max(p.geoms, key=lambda q: q.area)
    return [[round(x, 2), round(z, 2)] for x, z in p.exterior.coords]
data = dict(abyss_full=ABYSS_FULL, abyss_rim=ABYSS_RIM, floor=ABYSS_FLOOR, rim_landing=RIM_LANDING,
            plateau=out_poly(PLATEAU), original={k: out_poly(v) for k, v in ORIGINAL.items()},
            islands=[dict(key=k, name=NAMES[k], outline=out_poly(g), area=round(g.area), need=NEED[k], c=[round(g.centroid.x, 2), round(g.centroid.y, 2)],
                          size=round(math.sqrt(g.area), 1)) for k, g in ISLANDS.items()],
            fragments=[dict(key=f['key'], outline=out_poly(f['poly']), dy=f['dy'], area=round(f['poly'].area), c=[round(f['poly'].centroid.x, 2), round(f['poly'].centroid.y, 2)]) for f in FRAGMENTS],
            bridges=BR, built=BUILT, built_bridges=BUILT_BRIDGES, problems=[list(map(str, p)) for p in problems])
if '--json' in sys.argv:
    json.dump(data, open(sys.argv[sys.argv.index('--json') + 1], 'w'))
print('%d islands, %d floating fragments; bridges %s; %d problems' % (len(ISLANDS), len(FRAGMENTS), ', '.join('%s-%s %.0f %s' % (b['a'], b['b'], b['span'], b['kind']) for b in BR), len(problems)))
if '--plot' in sys.argv:
    plot_svg(sys.argv[sys.argv.index('--plot') + 1])
if problems: sys.exit(1)
