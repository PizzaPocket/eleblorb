"""Authoring tool for the Plant Kingdom's primate village
(docs/architecture/plant_kingdom_village_layout.md and _buildings.md). It holds
the three giant trees, the commons deck and everything on it, the inn, the
household rings with their pavilions, the bridges, the public switchbacks, the
grand ramp, the ground camp, and the kingdom's landmarks; checks them; and
writes JSON for the drawings and the 3D model.

    python3 tools/plant_village_layout.py [--json out.json]

Local metres from the village centre (the kingdom origin); x and z follow the
world axes, +z toward the river (south). Heights are metres above the village
floor. Bearings are degrees from +x toward +z.
"""
import json, math, sys

def rad(b): return math.radians(b)
def pol(c, r, b): return (c[0] + r * math.cos(rad(b)), c[1] + r * math.sin(rad(b)))
def dist(a, b): return math.hypot(a[0] - b[0], a[1] - b[1])
def bearing(a, b): return math.degrees(math.atan2(b[1] - a[1], b[0] - a[0])) % 360

FLAT_RADIUS = 55.0            # the protected clearing (jungle_kingdom_terrain.gd)
SAFE_RADIUS = 55.0
FOLIAGE_CLEAR = 60.0          # the layout asks the jungle to clear to 60 m
RAMP_ANGLE = 32.0
LANDING = 1.2
STOREY = 3.8                  # the trees' landing spacing (nature_props.gd EMERGENT_BRANCH_RISE)
COMMONS_Y = 11.4
RING_YS = (22.8, 34.2)
CROWN_Y = 45.6
BRIDGE_Y = 22.8
ROUTE = 1.5                   # clear route between things on a deck
RING_WIDTH = 5.0
BAY_WIDTH = 6.5

## ---- the three giant trees (jungle_kingdom_village.gd), tualang
TREES = {
    'east':  dict(name='East Tree',  c=(14.0, 12.0),  h=56.0),
    'elder': dict(name='Elder Tree', c=(-16.0, 9.0),  h=62.0),
    'north': dict(name='North Tree', c=(2.0, -18.0),  h=58.0),
}
def trunk_r(t, y):
    """Trunk radius at height y (nature_props.gd: 0.045 h at the base to 0.02 h at 0.86 h)."""
    h = TREES[t]['h']; top = 0.86 * h
    return 0.045 * h + (0.02 * h - 0.045 * h) * min(1, y / top)

GATE = (0.0, -3.0)
PLAZA_CLEAR = 12.0            # the gate plaza: nothing in it but the gate and the arrival

## ---- the commons (11.4 m): a rounded triangle round the trunks
COMMONS_OFFSET = 3.5          # deck edge beyond the line between trunk centres: wraps each trunk
def commons_outline(offset=COMMONS_OFFSET, n=18):
    cs = [TREES[k]['c'] for k in ('east', 'north', 'elder')]   # counter-clockwise in screen space
    cen = (sum(c[0] for c in cs) / 3, sum(c[1] for c in cs) / 3)
    pts = []
    for i, c in enumerate(cs):
        a, b = cs[i - 1], cs[(i + 1) % 3]
        b0 = bearing(cen, c)
        # sweep the corner arc between the outward normals of the two edges
        def normal(p, q):
            d = (q[0] - p[0], q[1] - p[1]); L = math.hypot(*d); nrm = (d[1] / L, -d[0] / L)
            mid = ((p[0] + q[0]) / 2, (p[1] + q[1]) / 2)
            if (mid[0] - cen[0]) * nrm[0] + (mid[1] - cen[1]) * nrm[1] < 0: nrm = (-nrm[0], -nrm[1])
            return math.degrees(math.atan2(nrm[1], nrm[0]))
        n0, n1 = normal(a, c), normal(c, b)
        sweep = (n1 - n0) % 360
        if sweep > 180: sweep -= 360
        for k in range(n + 1):
            pts.append(pol(c, offset, n0 + sweep * k / n))
    return pts
def area(poly): return abs(sum(poly[i][0] * poly[i - 1][1] - poly[i - 1][0] * poly[i][1] for i in range(len(poly)))) / 2
def inside(p, poly):
    x, y = p; c = False
    for i in range(len(poly)):
        a, b = poly[i], poly[i - 1]
        if (a[1] > y) != (b[1] > y) and x < (b[0] - a[0]) * (y - a[1]) / (b[1] - a[1]) + a[0]: c = not c
    return c
def seg_dist(p, a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]; L = dx * dx + dy * dy
    t = 0 if L == 0 else max(0, min(1, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / L))
    return math.hypot(p[0] - a[0] - t * dx, p[1] - a[1] - t * dy)
def edge_dist(p, poly): return min(seg_dist(p, poly[i - 1], poly[i]) for i in range(len(poly)))
def rect(c, w, d, yaw):
    """Corners of a w (along yaw) by d rectangle centred at c."""
    u = (math.cos(rad(yaw)), math.sin(rad(yaw))); v = (-u[1], u[0])
    return [(c[0] + u[0] * sx * w / 2 + v[0] * sy * d / 2, c[1] + u[1] * sx * w / 2 + v[1] * sy * d / 2) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
def poly_gap(a, b):
    """Least distance between two convex polygons (0 if they meet)."""
    if any(inside(p, b) for p in a) or any(inside(p, a) for p in b): return 0.0
    return min(min(seg_dist(p, b[i - 1], b[i]) for i in range(len(b))) for p in a + [] ) if a else 0.0
def gap(a, b): return min(poly_gap(a, b), poly_gap(b, a))

COMMONS = commons_outline()
CEN = (sum(TREES[k]['c'][0] for k in TREES) / 3, sum(TREES[k]['c'][1] for k in TREES) / 3)

## amenities on the deck, placed along the deck's edges: key, name, keeper, edge, t (0..1 along it),
## w (along the edge), d (across it), roof. Edges run W->E (south), W->N (north-west), N->E (north-east).
EDGES = {'S': ('elder', 'east'), 'NW': ('elder', 'north'), 'NE': ('north', 'east')}
def on_edge(edge, t, d, inset=0.9):
    a, b = (TREES[k]['c'] for k in EDGES[edge])
    p = (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
    L = dist(a, b); n = ((b[1] - a[1]) / L, -(b[0] - a[0]) / L)
    if (p[0] - CEN[0]) * n[0] + (p[1] - CEN[1]) * n[1] < 0: n = (-n[0], -n[1])
    off = COMMONS_OFFSET - inset - d / 2
    return (p[0] + n[0] * off, p[1] + n[1] * off), bearing(a, b)
AMENITY_SPEC = [
    ('market', 'Market', "Delima's fruit, Rotan's rope", 'S', 0.5, 12.0, 4.0, 'long leaf roof, facing the grand ramp\'s head', 2.0),
    ('kitchen', 'Shared kitchen', 'Wangi', 'NW', 0.34, 8.0, 6.0, 'the one fire in the trees', 0.1),
    ('dining', 'Dining terrace', 'everyone', 'NW', 0.64, 10.0, 6.0, 'open roof', 0.1),
    ('store', 'Food store', 'shared', 'NE', 0.2, 4.0, 4.0, 'raised basket store', 0.1),
    ('privy', 'Public privy', 'shared', 'NE', 0.28, 1.8, 1.4, 'rattan closet', 0.1),
    ('cistern', 'Cistern pavilion', 'shared', 'NE', 0.45, 6.0, 6.0, 'the largest leaf roof', 0.1),
    ('workshop', "Jati's workshop", 'Jati', 'NE', 0.73, 6.0, 5.0, 'half-open', 0.1),
]
CIRCLE = (CEN[0] - 0.4, CEN[1] + 0.9)
AMENITIES = [('circle', 'Gathering circle', 'the elders; Purnama presides', CIRCLE, 8.0, 8.0, 0, 'open to the sky')]
for k, n_, w_, e, t, w, d, r, front in AMENITY_SPEC:
    c, y = on_edge(e, t, d, 0.9 + front)
    AMENITIES.append((k, n_, w_, c, w, d, y, r))
## the inn: a lobe east of the East Tree, its veranda facing the commons
INN = dict(c=(23.0, 12.0), w=12.0, d=16.0, yaw=0.0, house=(14.0, 8.0), veranda=3.0, keeper='Bima', price=15)
## the grand ramp: a switchback of three 32 deg flights from the plaza's south up to the deck's south edge
S_EDGE, _ = on_edge('S', 0.5, 0.0, 0.0)
GRAND = dict(head=S_EDGE, width=2.4, flights=3, yaw=95.7)
## six posts to the ground, 1 m inside the deck edge, outside the gate plaza's clear zone
POSTS = [on_edge(e, t, 2.0, 0.0)[0] for e, t in (('S', 0.25), ('S', 0.75), ('NW', 0.2), ('NW', 0.9), ('NE', 0.1), ('NE', 0.85))]

## ---- household rings and pavilions: tree, ring height, bearing round the trunk, kind, who
PAVILIONS = [
    ('elder', CROWN_Y, 225, 'crown', 'Purnama and Sekar'),
    ('elder', 34.2, 225, 'couple', 'Senja and Rimba'),
    ('elder', 22.8, 40, 'single', 'Abu'),
    ('east', 34.2, 300, 'single', 'Tunas'),
    ('east', 34.2, 50, 'single', 'Bayu'),
    ('east', 22.8, 300, 'couple', 'Jati and Embun'),
    ('east', 22.8, 50, 'single', 'Dahan'),
    ('north', 34.2, 20, 'joined', 'Intan and Murai'),
    ('north', 34.2, 180, 'empty', 'Laras and Gilang (empty)'),
    ('north', 22.8, 165, 'couple', 'Tirta and Bintang'),
]
PAV_SIZE = {'single': (4.0, 4.0), 'couple': (5.0, 4.0), 'joined': (9.0, 4.0), 'empty': (4.0, 4.0), 'crown': (7.0, 5.0)}
## the 32 deg public switchback on each tree: a tower of flights beside the trunk, from the commons up
SWITCHBACK = {'east': 135.0, 'elder': 153.4, 'north': 275.9}   # at each tree's outer corner, on its own deck lobe
SB_LANE = 1.4
SB_RUN_PER_FLIGHT = STOREY / math.tan(rad(RAMP_ANGLE))     # one flight per 3.8 m storey
SB_LENGTH = SB_RUN_PER_FLIGHT + 2 * LANDING
SB_DEPTH = 2 * SB_LANE + 0.4
BRIDGES = [('elder', 'east'), ('east', 'north'), ('north', 'elder')]

## ---- the ground camp: key, name, who, centre, w, d, yaw, kind
GROUND = [
    ('ape_lodge', 'Ape lodge', 'Batu, Sari, Teguh', (38.0, -14.0), 14.0, 7.0, 0, 'lodge on short stilts'),
    ('stable', 'Stable and paddock', 'Ossian Redbrow; Manchego', (24.0, -30.0), 12.0, 10.0, 0, 'stall, paddock, lean-to'),
    ('tailed', "Tailed monkeys' house", 'Rotan, Kilat, Akar', (-34.0, -16.0), 10.0, 6.0, 0, 'raised hut'),
    ('garden', 'Garden house and gardens', 'Delima, Melati', (-38.0, 14.0), 9.0, 6.0, 0, 'raised hut and beds'),
    ('floor_hut', 'Floor hut', 'Damar, Wangi', (-24.0, 34.0), 8.0, 6.0, 0, 'raised hut'),
    ('training', 'Training grounds', 'Batu', (-48.0, -48.0), 20.0, 16.0, 45, 'fenced yard, dummies, shed'),
]
LANDMARKS = {  # the wider kingdom
    'kova_kong': dict(name='Kova Kong (Da Hou Zi)', c=(400.0, -280.0), note='the giant gorilla, about 80 m tall'),
    'wood_kingdom': dict(name='The Wood Kingdom', c=(-250.0, -300.0), r=34.0, note='abandoned treehouses; appears after the Ice Kingdom'),
    'clearing_w': dict(name='West clearing', c=(-250.0, 90.0), note=''),
    'falls': dict(name='The falls and the Water Curtain Cave', c=(-640.0, 150.0), note='a 38 m limestone cliff; the river begins here'),
    'mountain': dict(name='Flower Fruit Mountain', c=(-760.0, 150.0), note='the stone egg on its highest knoll'),
    'landing': dict(name="Tirta's fishing landing", c=(0.0, 141.0), note='on the river bank, end of the river trail'),
}

# ---- checks
problems = []
A = area(COMMONS)
if A < 520: problems.append(('the commons is only %.0f m2, under the 520 m2 its program needs' % A,))
amen = {k: rect(c, w, d, y) for k, _, _, c, w, d, y, _ in AMENITIES}
amen['circle'] = [pol(CIRCLE, 4.0, b) for b in range(0, 360, 20)]
trunks11 = {k: [pol(t['c'], trunk_r(k, COMMONS_Y) + 0.3, b) for b in range(0, 360, 20)] for k, t in TREES.items()}
for k, poly in amen.items():
    if not all(inside(p, COMMONS) for p in poly): problems.append((k, 'reaches off the commons deck'))
    elif min(edge_dist(p, COMMONS) for p in poly) < 0.9: problems.append((k, 'stands within 0.9 m of the deck edge (rail and net)'))
    for t, tp in trunks11.items():
        if gap(poly, tp) < ROUTE: problems.append((k, 'leaves no route past the %s trunk (%.1f m)' % (t, gap(poly, tp))))
ks = list(amen)
for i in range(len(ks)):
    for j in range(i + 1, len(ks)):
        g = gap(amen[ks[i]], amen[ks[j]])
        if g < ROUTE and {ks[i], ks[j]} != {'store', 'privy'} and {ks[i], ks[j]} != {'kitchen', 'dining'}:
            problems.append((ks[i], ks[j], 'only %.1f m apart on the deck' % g))
# the gate plaza stays open below; the posts stand outside it and outside the buildings
for i, p in enumerate(POSTS):
    if dist(p, GATE) < PLAZA_CLEAR: problems.append(('post %d stands in the gate plaza' % i,))
    if not inside(p, COMMONS): problems.append(('post %d stands outside the deck it carries' % i,))
# the inn lobe joins the deck and clears the East Tree
inn_poly = rect(INN['c'], INN['w'], INN['d'], INN['yaw'])
house_poly = rect((INN['c'][0] + INN['w'] / 2 - 0.5 - INN['house'][1] / 2, INN['c'][1]), INN['house'][1], INN['house'][0], 0)
if gap(inn_poly, COMMONS) > 0.01: problems.append(('the inn lobe does not meet the commons',))
if gap(house_poly, trunks11['east']) < ROUTE + 1.5: problems.append(('the inn house crowds the East Tree',))
# the grand ramp: its footprint south of the deck, clear of trunks and buildings, its head at the deck's edge
G_RUN = COMMONS_Y / math.tan(rad(RAMP_ANGLE))
g_len = G_RUN / GRAND['flights'] + 2 * LANDING
g_w = GRAND['width'] * GRAND['flights'] + 0.4 * (GRAND['flights'] - 1)
head = GRAND['head']
g_poly = rect((head[0] - 0.1 * g_len / 2, head[1] + g_len / 2 + 0.2), g_w, g_len, 5.7)
# rings: pavilions on bays fit round each ring with the walkway, the switchback and the bridge landings
def ring_arc(t, y, b0, width):
    r = trunk_r(t, y) + RING_WIDTH      # pavilions, bridges and switchbacks meet the ring at its outer edge
    return math.degrees(width / r)
for t in TREES:
    for y in RING_YS + ((CROWN_Y,) if t == 'elder' else ()):
        used = []
        for tt, yy, b, kind, who in PAVILIONS:
            if tt == t and yy == y: used.append((b, ring_arc(t, y, b, PAV_SIZE[kind][0] + 1.0), who))
        used.append((SWITCHBACK[t], ring_arc(t, y, 0, SB_DEPTH + 0.6), 'switchback head'))
        if y == BRIDGE_Y:
            for a_, b_ in BRIDGES:
                if t in (a_, b_):
                    o = b_ if t == a_ else a_
                    used.append((bearing(TREES[t]['c'], TREES[o]['c']), ring_arc(t, y, 0, 3.0), 'bridge to %s' % o))
        for i in range(len(used)):
            for j in range(i + 1, len(used)):
                d = abs((used[i][0] - used[j][0] + 180) % 360 - 180)
                if d < (used[i][1] + used[j][1]) / 2: problems.append((t, y, '%s and %s overlap on the ring' % (used[i][2], used[j][2])))
# bridges: span between ring edges
BR = []
for a_, b_ in BRIDGES:
    pa, pb = TREES[a_]['c'], TREES[b_]['c']
    span = dist(pa, pb) - trunk_r(a_, BRIDGE_Y) - trunk_r(b_, BRIDGE_Y) - 2 * RING_WIDTH
    BR.append(dict(a=a_, b=b_, span=round(span, 1)))
    if span > 32: problems.append(('the %s-%s bridge spans %.1f m' % (a_, b_, span),))
SBPOLY = {}
LOBES = {}
# switchback towers stand clear of the commons amenities they land among, and of the bridges
for t, b in SWITCHBACK.items():
    r0 = trunk_r(t, COMMONS_Y) + 0.4 + SB_DEPTH / 2
    c = pol(TREES[t]['c'], r0, b)
    poly = rect(c, SB_LENGTH, SB_DEPTH, b + 90)
    for k, ap in amen.items():
        if gap(poly, ap) < 1.0: problems.append((t, 'switchback lands on the %s' % k))
    if gap(poly, inn_poly) < 1.0: problems.append((t, 'switchback lands on the inn'))
    LOBES[t] = rect(c, SB_LENGTH + 2.0, SB_DEPTH + 2.4, b + 90)          # the lobe: 1 m of deck round the tower
    for k2, b2 in SWITCHBACK.items():
        pass
    SBPOLY[t] = poly
# ground camp: 3 m apart, 8 m from trunks, out of the plaza, posts, ramp; training grounds outside the safe zone
gpolys = {k: rect(c, w, d, y) for k, _, _, c, w, d, y, _ in GROUND}
gpolys['grand_ramp'] = g_poly
for k, p in gpolys.items():
    for t in TREES.values():
        if min(dist(q, t['c']) for q in p) < 8.0 and k != 'grand_ramp': problems.append((k, 'within 8 m of the %s trunk' % t['name']))
    if any(dist(q, GATE) < PLAZA_CLEAR for q in p): problems.append((k, 'stands in the gate plaza'))
    for i, q in enumerate(POSTS):
        if inside(q, p): problems.append((k, 'post %d stands in it' % i))
ks = list(gpolys)
for i in range(len(ks)):
    for j in range(i + 1, len(ks)):
        if gap(gpolys[ks[i]], gpolys[ks[j]]) < 3.0: problems.append((ks[i], ks[j], 'closer than 3 m'))
tr = gpolys['training']
if min(math.hypot(*q) for q in tr) < SAFE_RADIUS - 0.5: problems.append(('the training grounds reach into the safe zone (%.1f m)' % min(math.hypot(*q) for q in tr),))
for k, p in gpolys.items():
    if k != 'training' and max(math.hypot(*q) for q in p) > FLAT_RADIUS: problems.append((k, 'reaches off the flat clearing'))

for p in problems: print('PROBLEM', p)

# ---- the trees' existing branch-ramp chains (nature_props.gd build_emergent_tree), for the model:
# each ramp climbs 3.8 m over 3.6 m from the last landing, turning by the golden angle.
GOLDEN = 360 * 0.6180339887498949
def branch_chain(t, start_angle):
    h = TREES[t]['h']; top = 0.86 * h; y = 0.0; pos = None; a = start_angle; out = []
    while y + STOREY <= top * 0.95:
        tr_ = trunk_r(t, y)
        start = (math.cos(rad(a)) * (tr_ + 0.3), math.sin(rad(a)) * (tr_ + 0.3)) if pos is None else pos
        d = (math.cos(rad(a)), math.sin(rad(a)))
        top_pt = (start[0] + d[0] * 3.6, start[1] + d[1] * 3.6)
        land = (top_pt[0] + d[0] * 2.3 * 0.7, top_pt[1] + d[1] * 2.3 * 0.7)
        out.append(dict(a=start, b=top_pt, y0=y, y1=y + STOREY, land=land))
        pos = land; y += STOREY; a += GOLDEN
    return out

for i, p in enumerate(POSTS):
    for k, ap in list(amen.items()) + list(SBPOLY.items()):
        if inside(p, ap): problems.append(('post %d stands in %s' % (i, k),))
for p in problems[len(problems) - 0:]: pass
data = dict(
    trees={k: dict(v, base_r=0.045 * v['h'], top_r=0.02 * v['h'], trunk_top=0.86 * v['h'], canopy_r=0.34 * v['h'],
                   chain=branch_chain(k, {'east': 30, 'elder': 200, 'north': 290}[k])) for k, v in TREES.items()},
    gate=GATE, plaza=PLAZA_CLEAR, commons=COMMONS, commons_y=COMMONS_Y, commons_area=round(A), centroid=CEN,
    amenities=[dict(key=k, name=n, who=w_, c=c, w=w, d=d, yaw=y, roof=r) for k, n, w_, c, w, d, y, r in AMENITIES],
    inn=INN, grand=dict(GRAND, run=G_RUN, flight_len=g_len, poly=g_poly), posts=POSTS, sbpoly=SBPOLY, lobes=LOBES, inn_house=house_poly,
    rings=dict(ys=RING_YS, crown=CROWN_Y, width=RING_WIDTH, bay=BAY_WIDTH),
    pavilions=[dict(tree=t, y=y, b=b, kind=k, who=w_, size=PAV_SIZE[k]) for t, y, b, k, w_ in PAVILIONS],
    switchbacks={t: dict(b=b, lane=SB_LANE, length=SB_LENGTH, depth=SB_DEPTH, top=CROWN_Y if t == 'elder' else 34.2) for t, b in SWITCHBACK.items()},
    bridges=BR, bridge_y=BRIDGE_Y,
    ground=[dict(key=k, name=n, who=w_, c=c, w=w, d=d, yaw=y, kind=kd) for k, n, w_, c, w, d, y, kd in GROUND],
    landmarks=LANDMARKS, flat=FLAT_RADIUS, safe=SAFE_RADIUS, foliage_clear=FOLIAGE_CLEAR,
    trunk_r_fn='0.045h at the base to 0.02h at 0.86h', problems=[list(map(str, p)) for p in problems])
if '--json' in sys.argv:
    json.dump(data, open(sys.argv[sys.argv.index('--json') + 1], 'w'))
print('commons %.0f m2 (offset %.1f m); grand ramp run %.1f m in %d flights; bridges %s; %d problems' % (
    A, COMMONS_OFFSET, G_RUN, GRAND['flights'], ', '.join('%s-%s %.1f m' % (b['a'], b['b'], b['span']) for b in BR), len(problems)))
