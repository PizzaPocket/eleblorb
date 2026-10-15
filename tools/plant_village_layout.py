"""Authoring tool for the Plant Kingdom's primate village
(docs/architecture/plant_kingdom_village_layout.md and _buildings.md). It holds
the three giant trees, the commons deck and everything on it, the inn, the
household rings with their pavilions, the bridges, the one trunk spiral on each
tree, what carries every deck, the ground camp, and the kingdom's landmarks;
checks them; and
writes JSON for the drawings and the 3D model.

    python3 tools/plant_village_layout.py [--json out.json]

Local metres from the village centre (the kingdom origin); x and z follow the
world axes, +z toward the river (south). Heights are metres above the village
floor. Bearings are degrees from +x toward +z.

When every check passes it writes scripts/plant_village_plan.gd (tools/gd_plan.py), the one plan the game's builder
and validator read; edit here and rerun, never the generated file.
"""
import json, math, sys
from shapely.geometry import Polygon, Point, LineString, box
from shapely.ops import unary_union   # pip install shapely

def rad(b): return math.radians(b)
def frange(a, b, st):
    out = []; x = a
    while x < b - 0.5: out.append(x); x += st
    return out
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
HEADROOM = 2.4                # clear height over every route and ramp
RING_WIDTH = 5.0
## Every deck bears on its trunk: a bracket collar stands just off the bark, leaving a growth gap
## for the tree to thicken and sway (structure, section 11). The 2 m climbing well is gone.
WELL = 0.3
## One ramp per tree (circulation, section 11): a 32 deg spiral hugging the trunk from the roots to
## its highest deck, a landing at every deck and one half way between. 2.4 m wide from the ground
## to the commons, which everyone and the goods use; 1.5 m above it.
SPIRAL_W_LOW = 2.4
SPIRAL_W_UP = 1.5
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
    ('store', 'Food store', 'shared', 'NE', 0.272, 4.0, 4.0, 'raised basket store', 0.1),
    ('cistern', 'Cistern pavilion', 'shared', 'NE', 0.473, 5.5, 6.0, 'the largest leaf roof', 0.1),
    ('workshop', "Jati's workshop", 'Jati', 'NE', 0.695, 5.5, 5.0, 'half-open', 0.1),
]
CIRCLE = (CEN[0] - 0.4, CEN[1] + 0.8)
AMENITIES = [('circle', 'Gathering circle', 'the elders; Purnama presides', CIRCLE, 7.2, 7.2, 0, 'open to the sky')]
for k, n_, w_, e, t, w, d, r, front in AMENITY_SPEC:
    c, y = on_edge(e, t, d, 0.9 + front)
    AMENITIES.append((k, n_, w_, c, w, d, y, r))
## the public privy hangs just outside the rail beside the food store, on its own small bracketed
## platform, so it takes no room from the deck and its vat lowers straight to the ground
PRIVY_C, PRIVY_YAW = on_edge('NE', 0.33, 1.4, -1.6)
PRIVY = ('privy', 'Public privy', 'shared', PRIVY_C, 1.8, 1.4, PRIVY_YAW, 'rattan closet on a bracketed platform')
## the inn: a rounded lobe of deck east of the East Tree, one piece with the commons, the house on
## its east part with its veranda facing the commons. It sits in the East Tree's arms: three saddle
## limbs grown just under the deck carry it (structure, section 11), so no post stands under it.
INN = dict(lobe=(14.0, 3.5, 28.9, 20.5), round=3.0, house_c=(23.65, 12.0), house=(14.0, 6.5), veranda=3.0, keeper='Bima', price=15,
           saddle=(-24.0, 0.0, 24.0))
## no posts: every deck is carried by its trees (structure, section 11)
POSTS = []

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
## The public spiral: a 32 deg ramp 1.5 m wide wound round each trunk just outside its well, under
## the rings, from the commons to every ring (and the Elder Tree's crown). It replaces the
## switchback towers, which took too much of the commons (circulation, section 9).
PUBLIC_W = 1.5
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
amen['circle'] = [pol(CIRCLE, 3.6, b) for b in range(0, 360, 20)]
privy_poly = rect(PRIVY_C, 1.8, 1.4, PRIVY_YAW)
if dist(PRIVY_C, GATE) < PLAZA_CLEAR: problems.append(('the privy hangs over the gate plaza',))
trunks11 = {k: [pol(t['c'], trunk_r(k, COMMONS_Y) + WELL + SPIRAL_W_LOW, b) for b in range(0, 360, 15)] for k, t in TREES.items()}   # the spiral's zone round the trunk
for k, poly in amen.items():
    if not all(inside(p, COMMONS) for p in poly): problems.append((k, 'reaches off the commons deck'))
    elif min(edge_dist(p, COMMONS) for p in poly) < 0.9: problems.append((k, 'stands within 0.9 m of the deck edge (rail and net)'))
    for t, tp in trunks11.items():
        if gap(poly, tp) < ROUTE: problems.append((k, 'leaves no route round the %s well (%.1f m)' % (t, gap(poly, tp))))
ks = list(amen)
for i in range(len(ks)):
    for j in range(i + 1, len(ks)):
        g = gap(amen[ks[i]], amen[ks[j]])
        if g < ROUTE and {ks[i], ks[j]} != {'store', 'privy'} and {ks[i], ks[j]} != {'kitchen', 'dining'}:
            problems.append((ks[i], ks[j], 'only %.1f m apart on the deck' % g))
# the inn lobe joins the deck and clears the East Tree
INN_LOBE = box(*INN['lobe']).buffer(-INN['round']).buffer(INN['round'], 16)
inn_poly = list(INN_LOBE.exterior.coords)[:-1]
house_poly = rect(INN['house_c'], INN['house'][1], INN['house'][0], 0)
if not INN_LOBE.buffer(-0.9).contains(Polygon(house_poly)): problems.append(('the inn house stands within 0.9 m of its lobe\'s edge',))

if gap(house_poly, trunks11['east']) < ROUTE: problems.append(('the inn house crowds the East Tree\'s spiral',))
# rings: pavilions on bays fit round each ring with the walkway, the switchback and the bridge landings
def ring_arc(t, y, b0, width):
    r = trunk_r(t, y) + WELL + RING_WIDTH      # pavilions, bridges and switchbacks meet the ring at its outer edge
    return math.degrees(width / r)
for t in TREES:
    for y in RING_YS + ((CROWN_Y,) if t == 'elder' else ()):
        used = []
        for tt, yy, b, kind, who in PAVILIONS:
            if tt == t and yy == y: used.append((b, ring_arc(t, y, b, PAV_SIZE[kind][0] + 1.0), who))
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
    span = dist(pa, pb) - trunk_r(a_, BRIDGE_Y) - trunk_r(b_, BRIDGE_Y) - 2 * (WELL + RING_WIDTH)
    BR.append(dict(a=a_, b=b_, span=round(span, 1)))
    if span > 32: problems.append(('the %s-%s bridge spans %.1f m' % (a_, b_, span),))
SBPOLY = {}
LOBES = {}
# ground camp: 3 m apart, 8 m from trunks, out of the plaza, posts, ramp; training grounds outside the safe zone
gpolys = {k: rect(c, w, d, y) for k, _, _, c, w, d, y, _ in GROUND}
for k, p in gpolys.items():
    for t in TREES.values():
        if min(dist(q, t['c']) for q in p) < 8.0: problems.append((k, 'within 8 m of the %s trunk' % t['name']))
    if any(dist(q, GATE) < PLAZA_CLEAR for q in p): problems.append((k, 'stands in the gate plaza'))
ks = list(gpolys)
for i in range(len(ks)):
    for j in range(i + 1, len(ks)):
        if gap(gpolys[ks[i]], gpolys[ks[j]]) < 3.0: problems.append((ks[i], ks[j], 'closer than 3 m'))
tr = gpolys['training']
if min(math.hypot(*q) for q in tr) < SAFE_RADIUS - 0.5: problems.append(('the training grounds reach into the safe zone (%.1f m)' % min(math.hypot(*q) for q in tr),))
for k, p in gpolys.items():
    if k != 'training' and max(math.hypot(*q) for q in p) > FLAT_RADIUS: problems.append((k, 'reaches off the flat clearing'))

# the commons' net area, less the three wells
def net_area(poly, step=0.5):
    xs = [p[0] for p in poly]; zs = [p[1] for p in poly]; n = 0
    x = min(xs)
    while x < max(xs):
        z = min(zs)
        while z < max(zs):
            if inside((x, z), poly) and all(dist((x, z), t['c']) > trunk_r(k, COMMONS_Y) + WELL + SPIRAL_W_LOW for k, t in TREES.items()): n += 1
            z += step
        x += step
    return n * step * step
A_NET = net_area(COMMONS)
if A_NET < 520: problems.append(('the commons is only %.0f m2 net of the trunks and their spirals' % A_NET,))

## ---- the trunk spiral: one 32 deg ramp per tree, hugging the trunk from the roots to its highest
## deck. Each storey (11.4 m) is two flights with a 1.2 m landing between them, and a landing on every
## deck it reaches. Where it comes up through a deck, that deck is cut for the length in which the ramp
## is within a walker's headroom below it (the opening).
DECKS = {'east': (COMMONS_Y,) + RING_YS, 'north': (COMMONS_Y,) + RING_YS, 'elder': (COMMONS_Y,) + RING_YS + (CROWN_Y,)}
OPEN_RUN = (HEADROOM + 0.3) / math.tan(rad(RAMP_ANGLE))
def spiral(t, a0):
    ys = (0.0,) + DECKS[t]; a = a0; steps = []; opens = []
    for y0, y1 in zip(ys, ys[1:]):
        w = SPIRAL_W_LOW if y0 == 0 else SPIRAL_W_UP
        r = trunk_r(t, y0) + WELL + w / 2        # the trunk is thickest at the turn's foot: keep the well clear there
        half = (y1 - y0) / 2 / math.tan(rad(RAMP_ANGLE))
        for k in range(2):
            ya, yb = y0 + (y1 - y0) * k / 2, y0 + (y1 - y0) * (k + 1) / 2
            a1 = a + math.degrees(half / r); a2 = a1 + math.degrees(LANDING / r)
            steps.append(dict(y0=ya, y1=yb, a0=a, a1=a1, a2=a2, r=r, w=w)); a = a2
        # the opening runs from the bark (so it is one hole with the trunk's) to the ramp's outer edge
        opens.append(dict(y=y1, a0=a1 - math.degrees(OPEN_RUN / r), a1=a1, r0=trunk_r(t, y1) + WELL, r1=r + w / 2))
    return steps, opens
def arc_gap(a, b0, b1, r):
    """Distance along a circle of radius r from bearing a to the arc b0..b1 (0 inside it)."""
    a = (a - b0) % 360; L = (b1 - b0) % 360
    if a <= L: return 0.0
    return math.radians(min(a - L, 360 - a)) * r
def sector(c, r0, r1, b0, b1, n=16):
    """An annular sector round c from bearing b0 to b1 (b1 > b0)."""
    outer = [pol(c, r1, b0 + (b1 - b0) * i / n) for i in range(n + 1)]
    inner = [pol(c, r0, b1 - (b1 - b0) * i / n) for i in range(n + 1)]
    return Polygon(outer + inner)
SPIRAL = {}
for t in TREES:
    best = None
    for a0 in range(0, 360, 2):
        steps, opens = spiral(t, a0)
        foot = pol(TREES[t]['c'], steps[0]['r'], a0)
        if dist(foot, GATE) < PLAZA_CLEAR: continue
        # the commons landing and the opening it comes up through stand clear of everything on the deck
        st = steps[1]; land = pol(TREES[t]['c'], st['r'], (st['a1'] + st['a2']) / 2)
        o = opens[0]; hole = sector(TREES[t]['c'], o['r0'], o['r1'], o['a0'], o['a1'])
        if any(Polygon(q).buffer(0.6).intersects(hole) or Polygon(q).buffer(0.6).contains(Point(land)) for q in amen.values()): continue
        if not Polygon(COMMONS).union(Point(TREES[t]['c']).buffer(trunk_r(t, COMMONS_Y) + 6)).contains(hole): continue
        # on the East Tree the saddle limbs under the inn must cross no flight
        if t == 'east':
            hs = []
            for s_ in steps:
                for b_ in INN['saddle']:
                    d = (b_ - s_['a0']) % 360
                    if d <= s_['a1'] - s_['a0']: hs.append(s_['y0'] + (s_['y1'] - s_['y0']) * d / (s_['a1'] - s_['a0']))
                    elif d <= s_['a2'] - s_['a0']: hs.append(s_['y1'])
            if any(COMMONS_Y - 1.6 - HEADROOM - 0.3 < h < COMMONS_Y - 0.1 for h in hs): continue
        # every pavilion and bridge landing on the rings needs a clear bearing for the limb under it
        def hts(b_):
            out = []
            for s_ in steps:
                d = (b_ - s_['a0']) % 360
                if d <= s_['a1'] - s_['a0']: out.append(s_['y0'] + (s_['y1'] - s_['y0']) * d / (s_['a1'] - s_['a0']))
                elif d <= s_['a2'] - s_['a0']: out.append(s_['y1'])
            return out
        loads = [(yy, pb, PAV_SIZE[k][0]) for tt, yy, pb, k, who in PAVILIONS if tt == t]
        loads += [(BRIDGE_Y, bearing(TREES[t]['c'], TREES[b_ if t == a_ else a_]['c']), 3.0) for a_, b_ in BRIDGES if t in (a_, b_)]
        def limb_ok(y, pb, w):
            r_out = trunk_r(t, y) + WELL + (5.5 if y == CROWN_Y else RING_WIDTH); half = int(math.degrees((w / 2 - 0.5) / r_out))
            return any(all(y - 0.35 < h - 0.3 or y - 1.3 > h + HEADROOM for h in hts((pb + d) % 360)) for d in range(-half, half + 1))
        if not all(limb_ok(*l) for l in loads): continue
        # people arrive on the commons facing its middle
        score = abs((bearing(TREES[t]['c'], CEN) - (st['a1'] + st['a2']) / 2 + 180) % 360 - 180)
        if best is None or score < best[0]: best = (score, a0, steps, opens)
    if best is None: problems.append((t, 'no start for the trunk spiral fits the commons')); continue
    SPIRAL[t] = dict(a0=best[1], steps=best[2], openings=best[3])
    # one turn above another clears the headroom
    st = best[2]; per = sum(x['a2'] - x['a0'] for x in st[2:4])
    if 11.4 * 360 / per < HEADROOM + 0.4: problems.append((t, 'the trunk spiral\'s turns are too close'))
## the deck as built: the commons, a collar round each trunk (the spiral's zone, a 1.5 m route and the
## rail), and the inn's lobe, filleted into one outline, less each trunk and the opening where its
## spiral comes up. It must be one piece, so everything on it is reachable.
COLLAR = SPIRAL_W_LOW + ROUTE + 0.4
TRUNKS = {k: Point(t['c']).buffer(trunk_r(k, COMMONS_Y) + WELL, 48) for k, t in TREES.items()}
COLLARS = [Point(t['c']).buffer(trunk_r(k, COMMONS_Y) + WELL + COLLAR, 48) for k, t in TREES.items()]
OPENINGS = {k: sector(TREES[k]['c'], SPIRAL[k]['openings'][0]['r0'] - 0.05, SPIRAL[k]['openings'][0]['r1'], SPIRAL[k]['openings'][0]['a0'], SPIRAL[k]['openings'][0]['a1']) for k in SPIRAL}
DECK = unary_union([Polygon(COMMONS), INN_LOBE] + COLLARS).buffer(1.5, 16).buffer(-1.5, 16).difference(unary_union(list(TRUNKS.values()) + list(OPENINGS.values())))
if DECK.geom_type == 'Polygon' and len(DECK.interiors) != 3: problems.append(('a trunk or its opening breaks through the deck\'s edge',))
if DECK.geom_type != 'Polygon': problems.append(('the commons deck is in %d pieces once the trunks are cut' % len(DECK.geoms),))
DECK_POLYS = [DECK] if DECK.geom_type == 'Polygon' else list(DECK.geoms)
## the rings and the Elder Tree's crown deck: an annulus from the bark, less the spiral's opening
RING_POLYS = []
for t in SPIRAL:
    for o in SPIRAL[t]['openings'][1:]:
        width = 5.5 if o['y'] == CROWN_Y else RING_WIDTH
        r_in = trunk_r(t, o['y']) + WELL
        g = Point(TREES[t]['c']).buffer(r_in + width, 64).difference(Point(TREES[t]['c']).buffer(r_in, 64).union(sector(TREES[t]['c'], o['r0'] - 0.05, o['r1'], o['a0'], o['a1'])))
        RING_POLYS.append(dict(tree=t, y=o['y'], ext=[list(q) for q in g.exterior.coords], holes=[[list(q) for q in i.coords] for i in g.interiors]))

## ---- structure: what carries every deck (layout sections 10 and 11)
## Every deck is carried by its trees; nothing stands on the ground. The commons, at 11.4 m, is below
## the trees' first crown limbs. It bears on a bracket collar round each trunk: timber bearers, knee-
## braced to the bark, out to a curved ring beam, with joists beyond. Its middle hangs: each tree grows
## two limbs at about 20 m toward the commons' middle, and their tips carry a hung ring beam round the
## gathering circle. The inn's lobe sits on three saddle limbs the East Tree grows just under the deck.
## The rings and the crown deck sit on the same collars: a living limb under every pavilion and every
## bridge landing, timber bearers between. No bearer or limb crosses the trunk spiral within a
## walker's headroom.
BEARER_TOP, BEARER_BOTTOM = 0.35, 1.3   # a bearer fills y - 1.3 .. y - 0.35 under its deck
BEARER_REACH = 6.0            # with its knee brace a bearer carries the deck this far beyond the well
POST_REACH = 6.0              # beams from a post's head
HANG_REACH = 4.5              # joists between hung beams
MAX_BAY = 12.0                # each deck's edges are curved ring beams (laminated bamboo), carried at
                              # points no more than this apart; the joists between lie hidden under the planks
LIMB_MAX = 11.5               # nature_props.gd EMERGENT_BOUGH_LENGTH_MAX
COMMONS_LIMB_SPREAD = 30.0    # each tree's two commons limbs, either side of the line to the middle
def walk_heights(t, b):
    """Heights of the climbers' and the public spiral's walking surfaces at bearing b round tree t."""
    hs = []
    for st in SPIRAL[t]['steps']:
        d = (b - st['a0']) % 360
        if d <= st['a1'] - st['a0']: hs.append(st['y0'] + (st['y1'] - st['y0']) * d / (st['a1'] - st['a0']))
        elif d <= st['a2'] - st['a0']: hs.append(st['y1'])
    return hs
def clear_of_walks(t, b, y_lo, y_hi):
    return all(y_hi < h - 0.3 or y_lo > h + HEADROOM for h in walk_heights(t, b))
def nearest_clear(t, b, y_lo, y_hi, within):
    for d in sorted(range(-int(within), int(within) + 1), key=abs):
        if clear_of_walks(t, (b + d) % 360, y_lo, y_hi): return (b + d) % 360
    return None
def fill_bearers(t, y, r_out, fixed, hung=None):
    """Timber bearers between the fixed ones, so no bay at the outer edge exceeds MAX_BAY. Where the
    spirals rise under a deck no bearer can cross them, and that bay is hung from above instead
    (listed in `hung`); with no `hung` list, such a bay is left to the coverage check."""
    bs = sorted(b % 360 for b in fixed); out = []; settled = set()
    cands = [b for b in range(0, 360, 2) if clear_of_walks(t, b, y - BEARER_BOTTOM, y - BEARER_TOP)]
    if not bs and cands: out.append(cands[0])
    changed = True
    while changed:
        changed = False
        allb = sorted(set(bs + out))
        for i, b0 in enumerate(allb):
            b1 = allb[(i + 1) % len(allb)] + (360 if i + 1 == len(allb) else 0)
            if math.radians(b1 - b0) * r_out <= MAX_BAY + 1e-6 or (b0, b1 % 360) in settled: continue
            reach = b0 + math.degrees(MAX_BAY / r_out)       # as far round as one span reaches
            pick = sorted(c if c > b0 else c + 360 for c in cands if b0 < c < b1 or b0 < c + 360 < b1)
            if not pick:
                settled.add((b0, b1 % 360))
                if hung is not None: hung.append((b0, b1 % 360))
                continue
            within = [c for c in pick if c <= reach]
            out.append((within[-1] if within else pick[0]) % 360); changed = True; break
    return out
SUPPORT = dict(bearers=[], limbs=[], commons_limbs=[], hung=[])
# the commons: timber bearers round each well
for t in TREES:
    r_out = trunk_r(t, COMMONS_Y) + WELL + COLLAR
    for b in fill_bearers(t, COMMONS_Y, r_out, [], []):
        # a bearer runs from its bracket on the bark to the collar's ring beam; the deck beyond is joisted off that ring
        SUPPORT['bearers'].append(dict(tree=t, y=COMMONS_Y, b=b, r0=trunk_r(t, COMMONS_Y), r1=round(trunk_r(t, COMMONS_Y) + WELL + COLLAR - 0.3, 2)))
    SUPPORT.setdefault('ring_beams', []).append(dict(tree=t, y=COMMONS_Y, r=[round(trunk_r(t, COMMONS_Y) + WELL + 0.15, 2), round(trunk_r(t, COMMONS_Y) + WELL + COLLAR - 0.3, 2)]))
# the commons limbs and their hung ring
for t, tr in TREES.items():
    for sgn in (-1, 1):
        b = (bearing(tr['c'], CEN) + sgn * COMMONS_LIMB_SPREAD) % 360
        y = next((y for y in [round(18.5 + 0.1 * i, 1) for i in range(31)] if clear_of_walks(t, b, y - 0.6, y + 0.6)), None)
        if y is None: problems.append((t, 'no height for a commons limb at %.0f' % b)); continue
        r0 = trunk_r(t, y); tip = pol(tr['c'], r0 + LIMB_MAX, b)
        SUPPORT['commons_limbs'].append(dict(tree=t, b=b, y=y, r0=r0, length=LIMB_MAX, tip=tip))
tips = sorted((l['tip'] for l in SUPPORT['commons_limbs']), key=lambda q: math.atan2(q[1] - CEN[1], q[0] - CEN[0]))
SUPPORT['hung'] = tips
HUNG = Polygon(tips)
carried = [HUNG.buffer(HANG_REACH)]
carried += [Point(t['c']).buffer(trunk_r(k, COMMONS_Y) + WELL + COLLAR - 0.3 + HANG_REACH) for k, t in TREES.items()]
# the inn's saddle limbs: three living limbs just under the deck, the lobe joisted across them
for b in INN['saddle']:
    t = 'east'; r0 = trunk_r(t, COMMONS_Y - 0.8)
    # to a metre short of the house's far wall along the limb
    far = (INN['house_c'][0] + INN['house'][1] / 2 - TREES[t]['c'][0]) / math.cos(rad(b))
    reach = far - 1.0 - r0 * 0.8
    if not clear_of_walks(t, b, COMMONS_Y - 1.6, COMMONS_Y - 0.3): problems.append(('the inn\'s saddle limb at %.0f crosses the spiral' % b,))
    SUPPORT['limbs'].append(dict(tree=t, y=COMMONS_Y, b=b, r0=r0, length=round(min(LIMB_MAX, reach), 2), carries='the inn'))
    carried.append(LineString([TREES[t]['c'], pol(TREES[t]['c'], r0 * 0.8 + min(LIMB_MAX, reach), b)]).buffer(HANG_REACH))
    if reach > LIMB_MAX: problems.append(('the inn needs a %.1f m saddle limb' % reach,))
for l in SUPPORT['commons_limbs']:
    c = TREES[l['tree']]['c']
    carried.append(LineString([pol(c, l['r0'] + WELL + 1.0, l['b']), l['tip']]).buffer(HANG_REACH))
UNCARRIED = DECK.difference(unary_union(carried))
if UNCARRIED.area > 0.5: problems.append(('%.1f m2 of the commons has nothing under or over it' % UNCARRIED.area, [tuple(round(v, 1) for v in g.centroid.coords[0]) for g in getattr(UNCARRIED, 'geoms', [UNCARRIED]) if g.area > 0.2]))
if any(HUNG.buffer(0.1).contains(Point(p)) for p in POSTS): problems.append(('a post stands under the hung ring',))
# rings and the crown: a living limb under every pavilion and bridge landing, timber bearers between
for t in TREES:
    for y in DECKS[t][1:]:
        width = 5.5 if y == CROWN_Y else RING_WIDTH
        r_in = trunk_r(t, y) + WELL; r_out = r_in + width; fixed = []
        loads = [(pb, PAV_SIZE[k][0], PAV_SIZE[k][1], who) for tt, yy, pb, k, who in PAVILIONS if tt == t and yy == y]
        if y == BRIDGE_Y:
            for a_, b_ in BRIDGES:
                if t in (a_, b_): loads.append((bearing(TREES[t]['c'], TREES[b_ if t == a_ else a_]['c']), 3.0, 0.0, 'bridge'))
        for pb, w, d, who in loads:
            half = math.degrees((w / 2 - 0.5) / r_out)
            b = nearest_clear(t, pb, y - BEARER_BOTTOM, y - BEARER_TOP, half)
            if b is None: problems.append((t, y, who, 'no clear bearing for the limb under it')); continue
            reach = r_out + max(0.0, d - 0.6) - 1.0 - trunk_r(t, y)     # to a metre short of the pavilion's outer edge
            if reach > LIMB_MAX: problems.append((t, y, who, 'needs a %.1f m limb' % reach))
            SUPPORT['limbs'].append(dict(tree=t, y=y, b=b, r0=trunk_r(t, y), length=round(min(reach, LIMB_MAX), 2), carries=who)); fixed.append(b)
        hung = []
        SUPPORT.setdefault('ring_beams', []).append(dict(tree=t, y=y, r=[round(r_in + 0.15, 2), round(r_out - 0.15, 2)]))
        for b in fill_bearers(t, y, r_out, fixed, hung):
            SUPPORT['bearers'].append(dict(tree=t, y=y, b=b, r0=trunk_r(t, y), r1=r_out))
        for b0, b1 in hung:
            # a hung bay: hangers at its inner and outer edges, outside the public spiral's 1.5 m, from a
            # hanger limb grown 3.5 to 7 m above the deck over the bay's middle
            mid = (b0 + ((b1 - b0) % 360) / 2) % 360
            yh = next((yy for yy in [round(y + 3.5 + 0.1 * i, 1) for i in range(36)]
                       if clear_of_walks(t, mid, yy - 0.6, yy + 0.6) and all(abs(yy - dy) > 1.6 for dy in DECKS[t])), None)
            if yh is None: problems.append((t, y, 'no hanger limb over the bay %.0f-%.0f' % (b0, b1))); continue
            SUPPORT.setdefault('hangers', []).append(dict(tree=t, y=y, b0=b0, b1=b1, limb_y=yh, b=mid, r0=trunk_r(t, yh),
                                                         length=round(r_out + 0.5 - trunk_r(t, yh), 2), r_in=r_in + SPIRAL_W_UP + 0.1, r_out=r_out))
# the rest of each crown: limbs as nature_props.gd grows them (from 0.4 of the trunk, every 6.2 m, by
# the golden angle), skipped near a deck and wherever they would cross a walk
## ---- the crowns: every limb as the model draws it, with its side branches and leaves.
## A limb's path (as the 3D model draws it): from 0.8 of the trunk's radius out along its bearing,
## rising by its pitch, arched by `arch` (it leaves the trunk climbing, then levels).
GOLDEN_B = 360 * 0.6180339887498949
def limb_path(t, y, b, r0, length, pitch, arch, n=8, wander=0.0):
    """wander bends the limb sideways as it goes (metres at the tip), so no two limbs are the same."""
    c = TREES[t]['c']; d = (math.cos(rad(b)), math.sin(rad(b))); sd = (-d[1], d[0]); out = []
    for i in range(n + 1):
        u = i / n; s_ = length * u
        rise = length * math.sin(pitch) * u + arch * (math.sin(math.pi * min(1, u * 1.6) / 2) - 0.5)
        lat = wander * u * u
        out.append((c[0] + d[0] * (r0 * 0.8 + s_) + sd[0] * lat, y + rise, c[1] + d[1] * (r0 * 0.8 + s_) + sd[1] * lat))
    return out
# what a branch or a leaf may not pass through: every deck with the room people stand in over it
# (pavilion roofs included), the bridges, and the spirals' headroom
## the shared leaf roof (plant_kingdom_village_buildings.md 1, revised 2026-10-14): atap thatch on bamboo rafters from a
## lashed wall plate on the posts to the head of the central pillar; one pitch band and one eave for the whole village
ROOF_PITCH = 40.0             # degrees, inside the charter's 35 to 45
ROOF_EAVE = 1.0               # eave projection past the wall plate, horizontal
ROOF_PLATE = 3.3              # wall plate above the deck: the eave's underside then clears 2.4 m
ROOF_THATCH = 0.3
def roof_of(w, d):
    run = min(w, d) / 2; ridge = max(w, d) - min(w, d)
    return dict(plate=ROOF_PLATE, eave=ROOF_EAVE, pitch=ROOF_PITCH, ridge=round(ridge, 2), thatch=ROOF_THATCH,
                eave_y=round(ROOF_PLATE - ROOF_EAVE * math.tan(rad(ROOF_PITCH)), 2), apex=round(ROOF_PLATE + run * math.tan(rad(ROOF_PITCH)) + ROOF_THATCH, 2))
if roof_of(4, 4)['eave_y'] < HEADROOM: problems.append(('the leaf roof\'s eave is under %.1f m' % HEADROOM,))
SLABS = [(COMMONS_Y, DECK.buffer(0.5))]
ROOFS = []        # (floor, apex, plan): every roofed building's whole volume, eaves included
for t in TREES:
    for y in DECKS[t][1:]:
        width = 5.5 if y == CROWN_Y else RING_WIDTH
        r_in = trunk_r(t, y) + WELL; r_out = r_in + width
        shp = Point(TREES[t]['c']).buffer(r_out + 0.5).difference(Point(TREES[t]['c']).buffer(max(0.1, r_in - 0.5)))
        for tt, yy, pb, k, who in PAVILIONS:
            if tt == t and yy == y:
                w_, d_ = PAV_SIZE[k]; pc = pol(TREES[t]['c'], r_out + d_ / 2 - 0.6, pb)
                shp = shp.union(Polygon(rect(pc, d_ + 1.5, w_ + 1.5, pb)))
        SLABS.append((y, shp))
        for tt, yy, pb, k, who in PAVILIONS:
            if tt == t and yy == y:
                w_, d_ = PAV_SIZE[k]; pc = pol(TREES[t]['c'], r_out + d_ / 2 - 0.6, pb); rf = roof_of(w_, d_)
                ROOFS.append((y, y + rf['apex'] + 0.5, Polygon(rect(pc, d_ + 2 * rf['eave'] + 0.6, w_ + 2 * rf['eave'] + 0.6, pb))))
for br in BR:
    a_, b_ = TREES[br['a']]['c'], TREES[br['b']]['c']
    SLABS.append((BRIDGE_Y, LineString([a_, b_]).buffer(2.0)))
for k_, n_, w__, c_, w_, d_, y_, r_ in AMENITIES + [PRIVY]:
    if k_ == 'circle': continue
    rf = roof_of(w_, d_); ROOFS.append((COMMONS_Y, COMMONS_Y + rf['apex'] + (1.2 if k_ == 'store' else 0) + 0.5, Polygon(rect(c_, w_ + 2 * rf['eave'] + 0.6, d_ + 2 * rf['eave'] + 0.6, y_))))
_ir = roof_of(INN['house'][0], INN['house'][1] + INN['veranda'])
ROOFS.append((COMMONS_Y, COMMONS_Y + _ir['apex'] + 0.5, box(INN['house_c'][0] - INN['house'][1] / 2 - INN['veranda'] - 1.3, INN['house_c'][1] - INN['house'][0] / 2 - 1.3, INN['house_c'][0] + INN['house'][1] / 2 + 1.3, INN['house_c'][1] + INN['house'][0] / 2 + 1.3)))
def blocked(p, rad_=0.0):
    x, y, z = p; q = Point(x, z).buffer(rad_) if rad_ else Point(x, z)
    for y0, y1, shp in ROOFS:
        if y0 - rad_ < y < y1 + rad_ and shp.intersects(q): return True
    for yd, shp in SLABS:
        if yd - 1.5 - rad_ < y < yd + 4.2 + rad_ and shp.intersects(q): return True
    for t, tr in TREES.items():
        d = dist((x, z), tr['c'])
        if d < trunk_r(t, y) - 0.2 + 0.0: return False          # inside the trunk itself: the branch's root
        if d < trunk_r(t, y) + WELL + SPIRAL_W_LOW + 0.4 + rad_ and not clear_of_walks(t, bearing(tr['c'], (x, z)), y - 0.6 - rad_, y + 0.6 + rad_): return True
    return False
def rng_(seed):
    st = [seed]
    def r():
        st[0] = (st[0] * 16807) % 2147483647; return st[0] / 2147483647
    return r
BRANCHES = []      # dict(pts, r0, r1, kind)
LEAVES = []        # (x, y, z, radius)
def grow_side_branches(path, thick, length, kind, rnd, outer_from=0.45, n_try=6, droop=False, cap=99):
    """Side branches off the outer part of a limb, at irregular places and on either side as they fall,
    each forking once or not, every tip in leaf. A side branch that would pass through a deck, a bridge
    or a walk's headroom is not grown. Returns the leaf clusters grown."""
    leaves = 0
    for k in range(n_try):
        if leaves >= cap: break
        u = outer_from + (1 - outer_from) * rnd(); i = u * (len(path) - 1); i0 = int(min(len(path) - 2, i)); f = i - i0
        base = tuple(path[i0][j] + (path[i0 + 1][j] - path[i0][j]) * f for j in range(3))
        dx, dz = path[-1][0] - path[0][0], path[-1][2] - path[0][2]
        side = 1 if rnd() < 0.5 else -1
        yaw = math.atan2(dz, dx) + side * rad(25 + 50 * rnd())
        hang = droop and rnd() < 0.5           # between decks, foliage hangs below the limb or reaches out level
        up = rad(-(35 + 15 * rnd()) if hang else (-5 + 25 * rnd()) if droop else (18 + 34 * rnd())); sl = max(1.4, length * (0.2 + 0.2 * rnd())) * (1.4 if hang else 1)
        tip = (base[0] + math.cos(yaw) * math.cos(up) * sl, base[1] + math.sin(up) * sl, base[2] + math.sin(yaw) * math.cos(up) * sl)
        mid = tuple((base[j] + tip[j]) / 2 + (0.3 if j == 1 else 0) for j in range(3))
        leaf_r = (0.8 + 0.4 * rnd()) if hang or droop else 1.2 + 1.2 * rnd(); lift = -0.5 if hang else 0.2 if droop else 0.4
        if any(blocked(q) for q in (mid, tip)) or blocked((tip[0], tip[1] + lift, tip[2]), leaf_r): continue
        BRANCHES.append(dict(pts=[base, mid, tip], r0=round(thick * (1 - 0.6 * u) * 0.55, 3), r1=0.08, kind='twig'))
        LEAVES.append((tip[0], tip[1] + lift, tip[2], round(leaf_r, 2))); leaves += 1
        if not hang and rnd() < 0.6:          # a fork off some side branches, with its own leaves
            fy = yaw - side * rad(25 + 30 * rnd()); fl = sl * (0.4 + 0.3 * rnd())
            ftip = (mid[0] + math.cos(fy) * fl * 0.8, mid[1] + fl * 0.6, mid[2] + math.sin(fy) * fl * 0.8)
            if not blocked(ftip) and not blocked((ftip[0], ftip[1] + 0.3, ftip[2]), leaf_r * 0.7):
                BRANCHES.append(dict(pts=[mid, ftip], r0=round(thick * 0.22, 3), r1=0.06, kind='twig'))
                LEAVES.append((ftip[0], ftip[1] + 0.3, ftip[2], round(leaf_r * 0.7, 2))); leaves += 1
    return leaves
def tip_leaf(p_, rnd, r=None):
    lr = r or (1.6 + 1.2 * rnd()); q = (p_[-1][0], p_[-1][1] + 0.7, p_[-1][2])
    if blocked(q, lr * 0.8): return 0
    LEAVES.append(q + (round(lr, 2),)); return 1
BALD = []
def force_leaf(path, thick, want=2):
    """Search every direction off the limb's outer part for room to put out a leafy twig."""
    got = 0; L = len(path) - 1
    dx, dz = path[-1][0] - path[0][0], path[-1][2] - path[0][2]; base_yaw = math.atan2(dz, dx)
    for u in (0.95, 0.8, 0.65, 0.5, 0.35):
        i = u * L; i0 = int(min(L - 1, i)); f = i - i0; base = tuple(path[i0][j] + (path[i0 + 1][j] - path[i0][j]) * f for j in range(3))
        for dyaw in (40, -40, 70, -70, 100, -100, 15, -15, 130, -130, 0):
            for up in (20, 5, -15, 40, -35, -50, 60):
                for sl in (3.0, 2.2, 4.0):
                    yaw = base_yaw + rad(dyaw); a = rad(up)
                    tip = (base[0] + math.cos(yaw) * math.cos(a) * sl, base[1] + math.sin(a) * sl, base[2] + math.sin(yaw) * math.cos(a) * sl)
                    mid = tuple((base[j] + tip[j]) / 2 for j in range(3)); lr = 1.0; lift = -0.4 if up < 0 else 0.3
                    if any(blocked(q) for q in (mid, tip)) or blocked((tip[0], tip[1] + lift, tip[2]), lr): continue
                    BRANCHES.append(dict(pts=[base, mid, tip], r0=round(thick * 0.3, 3), r1=0.07, kind='twig')); LEAVES.append((tip[0], tip[1] + lift, tip[2], lr))
                    got += 1; break
                else: continue
                break
            if got: break
        if got >= want: break
    return got
# the structural limbs: their working length carries a deck, so they leaf beyond it, and below where
# the deck's underside leaves room; a limb that cannot be put in leaf is reported, never left bald
def leaf_structural(p_, thick, length, kind, rnd, outer_from, tries, have=0):
    n = have + grow_side_branches(p_, thick, length, kind, rnd, outer_from, tries)
    if n == 0: n = grow_side_branches(p_, thick, length, kind, rnd, max(0.3, outer_from - 0.3), tries * 6, droop=True, cap=2)
    if n == 0: n = force_leaf(p_, thick)
    if n == 0: BALD.append(kind)
    return n
## ---- the trees' forms (plant_kingdom_village_layout.md 12, 2026-10-14). A tualang grows a plumb, smooth,
## branch-free bole half its height and more, on plank buttresses, and breaks into a crown of a few huge ascending limbs.
## That straight bole is why the monkeys built on these three, and it keeps every deck, spiral and bridge true. Each tree
## is its own in its buttresses, the fluting of its bark, where its bole breaks, and how its crown spreads; each crown
## reaches away from its neighbours toward the open sky. Every limb and branch tapers from its parent, grows out and up
## (never down), and ends in a tuft of leaves that hides the twigs inside it.
FORM = {
    'elder': dict(break_y=50.5, leaders=5, lead_el=(38, 52), lead_len=(16.0, 19.0), lead_bend=-20, spread=150,
                  sec_from=0.45, sec_n=(3, 4), sec_len=(0.45, 0.6), fins=5, fin_h=5.2, fin_reach=3.6, flutes=7,
                  note='the oldest: a massive bole breaking high, over its crown deck, into five ascending limbs that spread like an umbrella'),
    'east':  dict(break_y=39.5, leaders=4, lead_el=(20, 32), lead_len=(16.0, 20.0), lead_bend=-12, spread=125,
                  sec_from=0.35, sec_n=(3, 4), sec_len=(0.45, 0.6), fins=3, fin_h=4.0, fin_reach=3.0, flutes=5,
                  note='the shortest: it breaks low into four broad, low-angled limbs, a wide flat crown'),
    'north': dict(break_y=39.5, leaders=2, lead_el=(66, 72), lead_len=(11.0, 13.0), lead_bend=-25, spread=40,
                  sec_from=0.75, sec_n=(3, 4), sec_len=(0.7, 0.85), fins=4, fin_h=4.6, fin_reach=3.2, flutes=6,
                  note='forked: the bole divides into twin leaders that climb side by side and spread only at the top'),
}
def taper(n, rb, rt, k=1.3):
    return [round(rt + (rb - rt) * (1 - i / n) ** k, 3) for i in range(n + 1)]
def curve(p0, az, el, L, d_el=0.0, d_az=0.0, n=10, min_el=-3.0):
    """A limb from p0 heading az (bearing, deg) at elevation el, its elevation changing by d_el and its heading by
    d_az over its length; never pointing down more than min_el."""
    pts = [tuple(p0)]
    for i in range(n):
        a = rad(az + d_az * (i + 0.5) / n); e = rad(max(min_el, el + d_el * (i + 0.5) / n)); st = L / n; x, y, z = pts[-1]
        pts.append((x + math.cos(a) * math.cos(e) * st, y + math.sin(e) * st, z + math.sin(a) * math.cos(e) * st))
    return pts
def at_u(pts, u):
    i = u * (len(pts) - 1); i0 = int(min(len(pts) - 2, i)); f = i - i0
    return tuple(pts[i0][j] + (pts[i0 + 1][j] - pts[i0][j]) * f for j in range(3)), i0
def heading(pts, i0):
    a, b = pts[i0], pts[min(len(pts) - 1, i0 + 1)]; h = math.hypot(b[0] - a[0], b[2] - a[2])
    return math.degrees(math.atan2(b[2] - a[2], b[0] - a[0])), math.degrees(math.atan2(b[1] - a[1], h or 1e-6))
def clear(pts, tuft=None):
    if any(blocked(q) for q in pts[1:]): return False
    return tuft is None or not blocked(tuft[:3], tuft[3] * 0.8)
def tuft_at(p_, r): return (p_[0], p_[1] + r * 0.25, p_[2], round(r, 2))
def twigs(parent, rs, kind, rnd, u0, n_, len_rng, r_tuft, el_rng=(18, 50), nested=0):
    """Side branches off the outer part of `parent`, alternating sides, each tapering from half its parent's
    thickness there, rising, and ending in a tuft; with `nested`, each carries its own smaller twigs."""
    got = 0; side = 1 if rnd() < 0.5 else -1
    for k in range(n_ * 3):
        if got >= n_: break
        u = u0 + (1 - u0) * (k + 0.5 + 0.4 * (rnd() - 0.5)) / (n_ * 3) if n_ > 1 else u0 + (1 - u0) * rnd()
        base, i0 = at_u(parent, u); paz, pel = heading(parent, i0)
        az = paz + side * (25 + 40 * rnd()); el = max(el_rng[0], min(el_rng[1], pel + (rnd() - 0.3) * 30)); L = len_rng[0] + (len_rng[1] - len_rng[0]) * rnd()
        pts = curve(base, az, el, L, d_el=8 * rnd(), d_az=side * 10 * rnd(), n=5)
        tf = tuft_at(pts[-1], r_tuft * (0.85 + 0.3 * rnd()))
        if not clear(pts, tf): side = -side; continue
        rb = max(0.06, rs[min(len(rs) - 1, int(u * (len(rs) - 1)))] * 0.5)
        my_rs = taper(len(pts) - 1, rb, 0.05)
        BRANCHES.append(dict(pts=pts, rs=my_rs, kind=kind)); LEAVES.append(tf); got += 1; side = -side
        if nested: twigs(pts, my_rs, kind, rnd, 0.5, nested, (L * 0.3, L * 0.45), r_tuft * 0.7, (20, 55), 0)
    return got
def limb_on(path, rb, kind, rnd, r_tuft):
    """A structural limb: its working length under the deck, then on past the deck's edge, turning up into leaf.
    If no way past the deck fits, it turns aside; the limb is never left bald."""
    e0 = path[-1]; az0, _ = heading(path, len(path) - 2)
    for daz in (0, 30, -30, 60, -60, 90, -90, 120, -120):
        # level, a little rising, until it is out from under the deck and the room over it; then up
        run = [e0]; a = rad(az0 + daz)
        for k_ in range(16):
            q = run[-1]; nq = (q[0] + math.cos(a) * 0.6, q[1] + 0.03, q[2] + math.sin(a) * 0.6); run.append(nq)
            if k_ >= 1 and not blocked(nq, 0.3): break
        else: continue
        for L in (4.5, 3.5, 2.5, 1.6):
            up = curve(run[-1], az0 + daz, 12, L, d_el=48, n=5); ext = run[:-1] + up
            tf = tuft_at(ext[-1], r_tuft)
            if clear(up, tf):
                pts = path + ext[1:]; rs = taper(len(pts) - 1, rb, 0.1, 0.9)
                BRANCHES.append(dict(pts=pts, rs=rs, kind=kind)); LEAVES.append(tf)
                twigs(pts, rs, 'twig', rnd, 0.62, 2, (2.0, 3.5), r_tuft * 0.75)
                return True
    BRANCHES.append(dict(pts=path, rs=taper(len(path) - 1, rb, rb * 0.5, 0.9), kind=kind)); BALD.append(kind); return False
BALD = []
rnd = rng_(20261014)
for l in SUPPORT['limbs']:
    p_ = limb_path(l['tree'], l['y'] - 0.8, l['b'], l['r0'], l['length'], 0.0, 0.3 + 0.3 * rnd(), wander=(rnd() - 0.5) * 1.2)
    limb_on(p_, 0.62 if l.get('carries') == 'the inn' else 0.55, 'deck limb', rnd, 1.8)
for h in SUPPORT['hangers']:
    p_ = limb_path(h['tree'], h['limb_y'], h['b'], h['r0'], h['length'], 0.05 * rnd(), 0.6 + 0.8 * rnd(), wander=(rnd() - 0.5) * 2.0)
    h['path'] = p_; limb_on(p_, 0.5, 'hanger limb', rnd, 1.8)
for l in SUPPORT['commons_limbs']:
    p_ = limb_path(l['tree'], l['y'], l['b'], l['r0'], l['length'], 0.0, 0.6 + 0.8 * rnd(), wander=(rnd() - 0.5) * 2.0)
    l['path'] = p_; limb_on(p_, 0.78, 'commons limb', rnd, 2.2)
# the crowns
CROWN = {}
for t, tr in TREES.items():
    F = FORM[t]; rt = rng_({'east': 7101, 'elder': 3307, 'north': 5519}[t]); R = trunk_r(t, F['break_y']) * 1.15
    out_b = bearing(CEN, tr['c']); n = F['leaders']; top = (tr['c'][0], F['break_y'], tr['c'][1]); leaders = []
    for i in range(n):
        az = out_b + (-F['spread'] / 2 + F['spread'] * (i + 0.5) / n if n > 1 else 0) + (rt() - 0.5) * 18
        if n == 2: az = out_b + (-1 if i == 0 else 1) * (F['spread'] / 2 + 8 * rt())
        el = F['lead_el'][0] + (F['lead_el'][1] - F['lead_el'][0]) * rt(); L = F['lead_len'][0] + (F['lead_len'][1] - F['lead_len'][0]) * rt()
        for trial in range(10):
            pts = curve(top, az + (trial // 2) * 9 * (1 if trial % 2 else -1), el + (trial // 2) * 3, L * (1 - 0.04 * trial), d_el=F['lead_bend'], d_az=(rt() - 0.5) * 16, n=12)
            if clear(pts): break
        else:
            problems.append((t, 'crown leader %d finds no clear air' % i)); continue
        rs = taper(len(pts) - 1, R / math.sqrt(n) * 1.1, 0.16, 1.1)
        BRANCHES.append(dict(pts=pts, rs=rs, kind='crown limb')); leaders.append(pts)
        tf = tuft_at(pts[-1], 3.4 + 0.8 * rt())
        if not blocked(tf[:3], tf[3] * 0.8): LEAVES.append(tf)
        ns = F['sec_n'][0] + int((F['sec_n'][1] - F['sec_n'][0] + 1) * rt())
        got = twigs(pts, rs, 'crown branch', rt, F['sec_from'], ns, (L * F['sec_len'][0], L * F['sec_len'][1]), 3.0, (14, 48), nested=3)
        if got == 0: problems.append((t, 'crown leader %d has no branches' % i))
    CROWN[t] = dict(break_y=F['break_y'], leaders=len(leaders), note=F['note'])
# the bole: plumb, its radius from the plan's trunk_r, flared at the foot into the buttresses, and running on a
# little above the break where the leaders leave it; plank buttresses wherever the spiral's foot leaves room
SPINES = {}; FINS = {}
for t, tr in TREES.items():
    F = FORM[t]; ys = [0, 2.5, 5, 7.5] + [round(y, 1) for y in frange(12, F['break_y'], 3.0)] + [F['break_y'], F['break_y'] + 1.2]
    SPINES[t] = [[y, round(trunk_r(t, min(y, F['break_y'])) * (0.8 if y > F['break_y'] else 1), 3)] for y in ys]     # no flare: the buttresses flare the foot, clear of the ramp
    foot = SPIRAL[t]['steps'][0]['a0'] if SPIRAL.get(t) else 0; rf = rng_({'east': 91, 'elder': 37, 'north': 63}[t]); fins = []
    for b in sorted(range(0, 360, 5), key=lambda _: rf()):
        if len(fins) >= F['fins']: break
        if -60 <= ((b - foot + 180) % 360 - 180) <= 15 or any(abs((b - f[0] + 180) % 360 - 180) < 360 / F['fins'] * 0.5 for f in fins): continue
        h = F['fin_h'] * (0.75 + 0.35 * rf())
        if clear_of_walks(t, b, 0.0, h + 0.3): fins.append([b, round(h, 2), round(F['fin_reach'] * (0.75 + 0.4 * rf()), 2)])
    if len(fins) < F['fins']: problems.append((t, 'room for only %d of %d buttresses' % (len(fins), F['fins'])))
    FINS[t] = fins
for t in TREES:
    for st in SPIRAL[t]['steps']:
        if trunk_r(t, st['y0']) + WELL - 1e-6 > st['r'] - st['w'] / 2: problems.append((t, 'the bole reaches the ramp at %.1f m' % st['y0']))
    foot = SPIRAL[t]['steps'][0]; fb = foot['a0']
    for b, h, reach in FINS[t]:
        if -60 <= ((b - fb + 180) % 360 - 180) <= 15: problems.append((t, 'a buttress at %d stands on the way to the ramp foot' % b))
for (x, y, z, r) in LEAVES:
    if blocked((x, y, z), r * 0.8): problems.append(('a leaf tuft at (%.1f, %.1f, %.1f) stands in a deck or a walk' % (x, y, z),))
for br_ in BRANCHES:
    for a_, b_ in zip(br_['pts'], br_['pts'][1:]):
        h_ = math.hypot(b_[0] - a_[0], b_[2] - a_[2])
        if math.degrees(math.atan2(b_[1] - a_[1], h_ or 1e-6)) < -6: problems.append(('a %s points down' % br_['kind'],)); break
if BALD: problems.append(('%d structural limbs could not be put in leaf: %s' % (len(BALD), ', '.join(BALD)),))
BOUGHS = [b_ for b_ in BRANCHES if b_['kind'] == 'crown limb']

## lianas: the canopy households are climbers, and climb the bark and the lianas left hanging from each
## ring's outer edge to the floor. They are the monkeys' own way down, not a built route.
LIANAS = []
for t, tr in TREES.items():
    for db in (-55, 55):
        b = (bearing(CEN, tr['c']) + db) % 360
        LIANAS.append(dict(tree=t, top=list(pol(tr['c'], trunk_r(t, RING_YS[0]) + WELL + RING_WIDTH - 0.2, b)), y=RING_YS[0]))
## the commons hoist: a basket on a pulley over the deck's edge beside the food store, so food, water
## and firewood come up from the floor without being carried up the ramps
STORE = next(a for a in AMENITIES if a[0] == 'store')
HOIST = on_edge('NE', 0.245, 0.0, -0.6)[0]
if dist(HOIST, GATE) < PLAZA_CLEAR: problems.append(('the hoist lowers into the gate plaza',))

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
    deck=[dict(ext=list(map(list, d_.exterior.coords)), holes=[list(map(list, i.coords)) for i in d_.interiors]) for d_ in DECK_POLYS],
    spiral=SPIRAL, ring_decks=RING_POLYS, lianas=LIANAS, well=WELL, hoist=HOIST, commons_net=round(A_NET),
    trees={k: dict(v, spine=SPINES[k], fins=FINS[k], flutes=FORM[k]['flutes'], crown=CROWN[k], base_r=0.045 * v['h'], top_r=0.02 * v['h'], trunk_top=0.86 * v['h'], canopy_r=0.34 * v['h'],
                   chain=branch_chain(k, {'east': 30, 'elder': 200, 'north': 290}[k])) for k, v in TREES.items()},
    gate=GATE, plaza=PLAZA_CLEAR, commons=COMMONS, commons_y=COMMONS_Y, commons_area=round(A), centroid=CEN,
    amenities=[dict(key=k, name=n, who=w_, c=c, w=w, d=d, yaw=y, roof=r) for k, n, w_, c, w, d, y, r in AMENITIES + [PRIVY]],
    inn=INN, inn_lobe=inn_poly, posts=POSTS, support=SUPPORT, branches=[dict(b_, pts=[[round(v, 2) for v in q] for q in b_['pts']]) for b_ in BRANCHES], leaves=[[round(v, 2) for v in q] for q in LEAVES], sbpoly=SBPOLY, lobes=LOBES, inn_house=house_poly,
    roof=dict(pitch=ROOF_PITCH, eave=ROOF_EAVE, plate=ROOF_PLATE, thatch=ROOF_THATCH),
    rings=dict(ys=RING_YS, crown=CROWN_Y, width=RING_WIDTH, bay=BAY_WIDTH),
    pavilions=[dict(tree=t, y=y, b=b, kind=k, who=w_, size=PAV_SIZE[k]) for t, y, b, k, w_ in PAVILIONS],
    decks=DECKS,
    bridges=BR, bridge_y=BRIDGE_Y,
    ground=[dict(key=k, name=n, who=w_, c=c, w=w, d=d, yaw=y, kind=kd) for k, n, w_, c, w, d, y, kd in GROUND],
    landmarks=LANDMARKS, flat=FLAT_RADIUS, safe=SAFE_RADIUS, foliage_clear=FOLIAGE_CLEAR,
    trunk_r_fn='0.045h at the base to 0.02h at 0.86h', problems=[list(map(str, p)) for p in problems])
if '--json' in sys.argv:
    json.dump(data, open(sys.argv[sys.argv.index('--json') + 1], 'w'))
import sys as _s, os as _o; _s.path.insert(0, _o.path.dirname(_o.path.abspath(__file__))); from gd_plan import write_plan
if not problems:
    write_plan('PlantVillagePlan', 'plant_village_plan.gd', [
        "The Plant Kingdom primate village's single plan (docs/architecture/plant_kingdom_village*.md):",
        'the three trees and their forms (bole, buttresses, every limb and branch with its radii, every leaf tuft),',
        'the commons deck and the inn lobe, the rings and the crown deck, the trunk spirals, the bridges, every',
        'pavilion and amenity, the structure that carries each deck, and the shared leaf roof. Backlog P6 and P7:',
        'the village builder, NatureProps.build_emergent_tree and the village validator read only this.',
        '',
        'Local metres from the village centre (the kingdom origin): x and z follow the world axes, +z toward the',
        'river (south), y up from the clearing floor. Points are [x, z] in plan or [x, y, z] in space.'],
        {k.upper(): v for k, v in data.items() if k != 'problems'}, 'tools/plant_village_layout.py')
    print('wrote scripts/plant_village_plan.gd')
print('trees: %s; %d limbs and branches (%d crown limbs), %d leaf tufts' % (', '.join('%s breaks at %.1f m into %d, %d buttresses' % (t, CROWN[t]['break_y'], CROWN[t]['leaders'], len(FINS[t])) for t in TREES), len(BRANCHES), len(BOUGHS), len(LEAVES)))
print('commons %.0f m2 gross, %.0f net of trunks and spirals, deck %.0f m2 with the inn lobe; %d trunk spirals, %.0f m of ramp; %d bearers, %d deck limbs, %d commons limbs, %d hung bays, %d posts; bridges %s; %d problems' % (
    A, A_NET, DECK.area, len(SPIRAL), sum(math.radians(st['a1'] - st['a0']) * st['r'] / math.cos(rad(RAMP_ANGLE)) for v in SPIRAL.values() for st in v['steps']), len(SUPPORT['bearers']), len(SUPPORT['limbs']), len(SUPPORT['commons_limbs']), len(SUPPORT.get('hangers', [])), len(POSTS), ', '.join('%s-%s %.1f m' % (b['a'], b['b'], b['span']) for b in BR), len(problems)))
if problems: sys.exit(1)
