"""The ground of the Chinese village: the Abyss as a jointed sandstone gorge and the
village's islands as the stone pillars left standing in it (chinese_village.md 4.0).
It holds the gorge's rim, every pillar (inhabited or bare) with its plan outline and top
height, and the bridges between them; checks them; and writes JSON for the 3D model.

    python3 tools/chinese_village_gorge.py [--json out.json]

How the ground formed (proposed): the plateau was quartz sandstone crossed by two sets
of near-vertical joints, one along the gorge (about 15 degrees east of north) and one
across it. Water working down the joints for an age widened them into the Abyss and
left the blocks between them standing as pillars, as at Zhangjiajie, inside a sinkhole
like the great tiankeng. So:
- pillars are blocky: rounded-corner rectangles turned with the joints, never discs;
- they stand in rows along the joints, close across one set and wider along the other;
- their tops are what is left of the old plateau surface. That surface tilted gently down
  to the south, and the smaller pillars have lost more, so the tops are accordant but not
  level;
- many pillars are too small or too steep to live on. They stand bare, with pines;
- mist fills the Abyss below about 60 m under the village, so the pillars read as
  floating, though every one stands on the floor 400 m down.

Plan frame: x across the gorge (east-ish), z along it (+z south, toward the entry and
Ohio), origin at the palace pillar's centre. The world frame is this turned by HEADING.
Heights y are metres above the village datum (the palace top is +4).
"""
import json, math, sys
from shapely.geometry import Polygon, Point, LineString
from shapely.ops import unary_union

def rad(b): return math.radians(b)
HEADING = 15.0                 # plan +z points this many degrees east of world south
VILLAGE_CENTER = (250.0, -650.0)
DATUM_Y = -55.0                # today's island surface height, world
ABYSS_FLOOR = -400.0
MIST_TOP = -60.0               # mist fills the Abyss below this, relative to the datum
CHAIN_MAX, CANTILEVER_MAX, ARCH_MAX = 100.0, 38.0, 15.0
MAX_GRADE = 1 / 8.0            # a bridge between tops of different height
RIM_CLEAR = 18.0               # an inhabited pillar keeps this from the rim unless bridged to it
PILLAR_GAP = 8.0               # pillars closer than this would be one rock

def to_world(x, z):
    t = rad(HEADING); return (VILLAGE_CENTER[0] + x * math.cos(t) + z * math.sin(t), VILLAGE_CENTER[1] - x * math.sin(t) + z * math.cos(t))
def from_world_local(wx, wz):
    """Village-local world offset (from VILLAGE_CENTER) to the plan frame."""
    t = rad(HEADING); return (wx * math.cos(t) - wz * math.sin(t), wx * math.sin(t) + wz * math.cos(t))

def noise(a, seed):
    return 0.5 * math.sin(3 * a + seed) + 0.3 * math.sin(5 * a + 2.1 * seed) + 0.2 * math.sin(9 * a + 0.7 * seed)
def pillar_outline(c, a, b, rot, eps=3.4, rough=0.05, seed=1.0, notch=None, n=96):
    """A jointed block: a superellipse half-widths a (across) and b (along), turned rot degrees,
    its edge roughened, and optionally a notch where a joint bit in (bearing, depth)."""
    pts = []
    for i in range(n):
        th = 2 * math.pi * i / n
        ct, st = math.cos(th), math.sin(th)
        x = a * math.copysign(abs(ct) ** (2 / eps), ct); z = b * math.copysign(abs(st) ** (2 / eps), st)
        k = 1 + rough * noise(th, seed)
        if notch:
            d = abs((math.degrees(th) - notch[0] + 180) % 360 - 180)
            if d < 18: k -= notch[1] * (1 - d / 18) ** 2
        x *= k; z *= k
        r_ = rad(rot); pts.append((c[0] + x * math.cos(r_) - z * math.sin(r_), c[1] + x * math.sin(r_) + z * math.cos(r_)))
    return Polygon(pts).buffer(0)

## ---- the gorge's rim: an elongated, joint-guided outline with a west bay, narrowing south to the entry
RIM_PTS = [(-40, -300), (40, -306), (118, -270), (176, -205), (196, -120), (204, -30), (210, 60), (192, 140),
           (150, 196), (96, 236), (40, 252), (-30, 250), (-92, 222), (-150, 196), (-212, 160), (-236, 96),
           (-224, 20), (-196, -40), (-176, -120), (-150, -210), (-104, -272)]
RIM = Polygon(RIM_PTS).buffer(18, 8).buffer(-18, 8)

## ---- pillars: key, role, centre (x, z), half-widths (across, along), turn, top height, roughness seed, notch
## The roles and land needs come from chinese_village.md 4.1.2 (the re-fit's radii as areas).
NEED = {'palace': 12076, 'gate': 1018, 'inn': 2290, 'market': 2290, 'lantern': 1963, 'roofers': 1521, 'fields': 3632, 'bamboo': 3217}
P = []
def pillar(key, role, c, a, b, rot, top, seed, notch=None, eps=3.4, name=None):
    P.append(dict(key=key, role=role, name=name or key, c=c, a=a, b=b, rot=rot, top=top, seed=seed, notch=notch, eps=eps,
                  poly=pillar_outline(c, a, b, rot, eps, 0.05 if role != 'bare' else 0.09, seed, notch)))
# inhabited: the old plateau surface tilts down 1:40 toward the entry; smaller pillars stand a little lower
pillar('palace', 'palace', (0.0, 0.0), 56.0, 62.0, 0.0, 4.0, 1.3, name='Palace')
pillar('gate', 'gate', (6.0, 176.0), 18.0, 17.0, 4.0, -2.2, 2.2, name='Gate')
pillar('inn', 'inn', (-72.0, 128.0), 26.0, 25.0, -7.0, -1.8, 3.1, name='E, Inn')
pillar('roofers', 'roofers', (-140.0, 50.0), 22.0, 21.0, 9.0, 0.6, 4.4, name='C, Roofers')
pillar('lantern', 'lantern', (-104.0, -66.0), 25.0, 23.0, -4.0, 2.6, 5.2, name='A, Lantern Row')
pillar('market', 'market', (104.0, -52.0), 26.0, 25.0, 6.0, 2.4, 6.6, name='B, Market')
pillar('fields', 'fields', (110.0, 54.0), 34.0, 30.0, 3.0, 0.4, 7.7, name='D, Fields')
pillar('bamboo', 'bamboo', (88.0, 132.0), 32.0, 29.0, -5.0, -1.2, 8.1, notch=(200, 0.12), name='Bamboo, Farm')
# piers: small pillars that carry a bridge-head between two long spans
pillar('axis_pier', 'pier', (0.0, 104.0), 9.0, 8.0, 3.0, 1.0, 9.4, name='Axis pier')
pillar('west_pier', 'pier', (-122.0, -8.0), 8.0, 9.0, -6.0, 1.0, 10.2, name='West pier')
# bare pillars along the joints: too small or too steep to live on; pines on their tops
BARE = [((-48, -150), 12, 10, 4, 14.0), ((40, -158), 9, 12, -3, -9.0), ((112, -148), 14, 11, 7, 6.0), ((-130, -168), 10, 9, 0, -22.0),
        ((-60, -118), 7, 8, 5, 22.0), ((150, -100), 8, 10, -4, -15.0), ((160, 10), 9, 8, 2, 18.0), ((-176, -60), 9, 11, 8, -6.0),
        ((-64, 74), 11, 9, -6, -12.0), ((-176, 118), 10, 8, 5, -30.0), ((-110, 178), 9, 10, -2, 9.0), ((54, 84), 10, 9, 4, -18.0),
        ((150, 150), 9, 9, -7, 11.0), ((-24, 218), 8, 9, 3, -14.0), ((60, -100), 6, 7, 0, 26.0), ((-178, 20), 8, 7, 6, 15.0),
        ((172, -30), 7, 6, -2, -35.0), ((40, 206), 7, 8, -4, -26.0), ((-50, 190), 8, 7, 2, 4.0), ((172, 92), 8, 9, 6, -8.0)]
for i, (c, a, b, rot, top) in enumerate(BARE):
    pillar('bare_%d' % (i + 1), 'bare', (float(c[0]), float(c[1])), a, b, rot, top, 11.0 + i * 1.7, eps=2.8)

## ---- bridges (chinese_village.md 4.1.4 and 4.1.5), now joining pillars. type by span:
## chain over 38 m; covered cantilever up to 38 m; stone arch up to 15 m.
BRIDGES = [  # a, b, deck width, use
    ('rim_s', 'gate', 5.0, 'entry; Bo Xiang to Ohio'),
    ('gate', 'axis_pier', 5.0, 'processional axis'), ('axis_pier', 'palace', 5.0, 'processional axis'),
    ('gate', 'inn', 3.2, 'visitors to the inn'), ('gate', 'bamboo', 2.4, 'farm path'),
    ('palace', 'lantern', 3.2, 'garden gate, shut before the quest'), ('palace', 'market', 3.2, 'service: levy, deliveries'),
    ('lantern', 'west_pier', 3.2, 'ring'), ('west_pier', 'roofers', 3.2, 'ring'), ('roofers', 'inn', 3.2, 'ring'),
    ('market', 'fields', 3.2, 'ring; produce and night soil'), ('fields', 'bamboo', 3.2, 'ring; the farm pair'),
]
RIM_LANDINGS = {'rim_s': (6.0, 252.0)}

# ---- checks
problems = []
PK = {p['key']: p for p in P}
for p in P:
    if not RIM.buffer(-4).contains(p['poly']): problems.append((p['key'], 'reaches the gorge wall'))
    if p['role'] not in ('bare', 'pier') and p['key'] != 'gate' and p['poly'].distance(RIM.exterior) < RIM_CLEAR:
        problems.append((p['key'], 'stands %.0f m from the rim, under %.0f' % (p['poly'].distance(RIM.exterior), RIM_CLEAR)))
for i in range(len(P)):
    for j in range(i + 1, len(P)):
        g = P[i]['poly'].distance(P[j]['poly'])
        if g < PILLAR_GAP: problems.append((P[i]['key'], P[j]['key'], 'only %.1f m apart: they would be one rock' % g))
for k, need in NEED.items():
    have = PK[k]['poly'].area
    if have < need * 0.97: problems.append((k, 'has %.0f m2 of top, needs %.0f' % (have, need)))
BR = []
for a, b, w, use in BRIDGES:
    pa = RIM_LANDINGS.get(a) or PK[a]['c']; pb = PK[b]['c']
    line = LineString([pa, pb])
    ea = Point(pa) if a in RIM_LANDINGS else line.intersection(PK[a]['poly'].exterior)
    eb = line.intersection(PK[b]['poly'].exterior)
    def nearest(geom, other):
        pts = [geom] if geom.geom_type == 'Point' else list(getattr(geom, 'geoms', []))
        return min(pts, key=lambda q: q.distance(Point(other)))
    A_ = nearest(ea, pb); B_ = nearest(eb, pa)
    span = A_.distance(B_)
    ya = 0.0 if a in RIM_LANDINGS else PK[a]['top']; yb = PK[b]['top']
    kind = 'arch' if span <= ARCH_MAX else 'cantilever' if span <= CANTILEVER_MAX else 'chain'
    if span > CHAIN_MAX: problems.append((a, b, 'spans %.0f m, past what a chain bridge can' % span))
    if abs(yb - ya) / max(span, 1) > MAX_GRADE: problems.append((a, b, 'climbs %.1f m over %.0f m' % (abs(yb - ya), span)))
    deck = LineString([(A_.x, A_.y), (B_.x, B_.y)]).buffer(w / 2 + 0.5)
    for p in P:
        if p['key'] in (a, b): continue
        if deck.intersects(p['poly']): problems.append((a, b, 'passes through %s' % p['key']))
    if a in RIM_LANDINGS and RIM.exterior.distance(Point(pa)) > 3: problems.append((a, 'landing is not on the rim'))
    BR.append(dict(a=a, b=b, width=w, use=use, kind=kind, span=round(span, 1), ends=[[round(A_.x, 2), round(A_.y, 2), ya], [round(B_.x, 2), round(B_.y, 2), yb]],
                   sag=round(span / 20, 2) if kind == 'chain' else 0))
# every inhabited pillar reachable from the rim
adj = {}
for b_ in BR: adj.setdefault(b_['a'], set()).add(b_['b']); adj.setdefault(b_['b'], set()).add(b_['a'])
seen = {'rim_s'}; stack = ['rim_s']
while stack:
    n = stack.pop()
    for m in adj.get(n, ()):
        if m not in seen: seen.add(m); stack.append(m)
for k in NEED:
    if k not in seen: problems.append((k, 'is not reached from the rim'))

# ---- the village as built today (scripts/chinese_village.gd), in the plan frame
BUILT = []
for key, (wx, wz), r in [('palace', (0, 0), 62), ('A', (-105, -58), 21), ('B', (108, -48), 20), ('bamboo', (18, 116), 25),
                         ('C', (-118, 42), 18), ('D', (112, 48), 19), ('E', (-62, 124), 17)]:
    x, z = from_world_local(wx, wz); BUILT.append(dict(key=key, c=[round(x, 2), round(z, 2)], r=r))
BUILT_BRIDGES = [('palace', 'A'), ('palace', 'B'), ('palace', 'bamboo'), ('A', 'C'), ('B', 'D'), ('C', 'E'), ('E', 'bamboo')]
BUILT_ABYSS = (170.0, 220.0)

for p in problems: print('PROBLEM', p)
def out_poly(p): return [[round(x, 2), round(z, 2)] for x, z in p.exterior.coords]
data = dict(heading=HEADING, datum_y=DATUM_Y, floor=ABYSS_FLOOR, mist=MIST_TOP, rim=out_poly(RIM),
            pillars=[dict({k: v for k, v in p.items() if k != 'poly'}, outline=out_poly(p['poly']), area=round(p['poly'].area)) for p in P],
            bridges=BR, rim_landings=RIM_LANDINGS, built=BUILT, built_bridges=BUILT_BRIDGES, built_abyss=BUILT_ABYSS,
            need=NEED, problems=[list(map(str, p)) for p in problems])
if '--json' in sys.argv:
    json.dump(data, open(sys.argv[sys.argv.index('--json') + 1], 'w'))
inh = [p for p in P if p['role'] not in ('bare', 'pier')]
print('gorge %.0f x %.0f m; %d pillars (%d lived on, %d piers, %d bare); %d bridges: %s; %d problems' % (
    RIM.bounds[2] - RIM.bounds[0], RIM.bounds[3] - RIM.bounds[1], len(P), len(inh), sum(p['role'] == 'pier' for p in P),
    sum(p['role'] == 'bare' for p in P), len(BR), ', '.join('%s-%s %s %.0f' % (b['a'], b['b'], b['kind'], b['span']) for b in BR), len(problems)))
if problems: sys.exit(1)
